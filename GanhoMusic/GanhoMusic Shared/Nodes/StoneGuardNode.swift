//
//  StoneGuardNode.swift
//  GanhoMusic Shared
//
//  Phase 4-1 · 석조무사 NPC — 4 waypoint 시계방향 패트롤 (SKAction)
//  Phase 4-2 · PhysicsBody 부착 (collision=0 통과형, contactTest=.player)
//  Sprint 10 Phase F · 픽셀 텍스처 + selectInitialWaypoint(farthest-first) + 좌표 정합.
//                       자식 시각(armor/일자눈)/applyVisualScaleV9 본체 삭제 — 본체 16×20 픽셀만 노출.
//
//  단일 진실 원천: SPEC.md §7.3/§9 + docs/ORIGINAL_GAME_ANALYSIS.md L119~L122/L3120~L3192/L3221~L3274.
//

import SpriteKit

/// 석조무사 NPC. 4 waypoint 시계방향 무한 순환 패트롤 (원본 game.js L3221~L3274 byte-equal).
/// Sprint 10 Phase F 변경:
///  - super.init(color: .ganhoStoneGuardLight) 폐기 → 픽셀 텍스처(stoneGuardData + stoneGuardPalette) 부착
///  - 자식 시각(armor + 일자눈)/applyVisualScaleV9 본체 삭제 — 본체 픽셀 텍스처만 노출
///  - color clear / colorBlendFactor 1.0 정책 제거 (super.init color:.clear이라 자연 투명)
///  - startPatrol → startPatrolFrom(index:) 리팩터 + selectInitialWaypoint(from:) 신설(farthest-first)
///  - 좌표 정합: 옛 200/760·100/380 폐기 → 원본 80/540·80/300 4점 직접 사용 (GameplayTuning)
///  - PixelDirection/Frame 갱신 (PlayerNode/EnemyNode/ProfessorNode 패턴 동형)
/// R0 — 방향+프레임 통합(updatePixelAnimation)은 PixelPositionDeltaAnimating 기본 구현 사용 (사본 제거).
final class StoneGuardNode: SKSpriteNode, PixelPositionDeltaAnimating {

    // MARK: - Pixel Sprite State (Sprint 10 Phase F)
    /// 현재 픽셀 텍스처가 표현하는 방향. SKAction.move의 진행 방향에 따라 갱신.
    var pixelDirection: PixelDirection = .down
    /// 현재 픽셀 텍스처가 표현하는 프레임. 이동 중 step1↔step2 교차, 정지 시 idle.
    var pixelFrame: PixelFrame = .idle
    /// B형(position-delta) 이동 판정 임계값 0.01 — 기존 리터럴의 상수화 (값 변경 0).
    var movementThreshold: CGFloat { GameplayTuning.pixelDirectionPositionDeltaThreshold }
    /// step1↔step2 교차 누적 시간 (초). 0.22초 도달 시 토글 + 0 리셋.
    var frameAccumulator: TimeInterval = 0
    /// updatePixelAnimation에서 *이전 프레임 위치*와 비교하여 진행 방향 산출.
    var lastPosition: CGPoint = .zero
    /// lastPosition 첫 초기화 여부. 첫 update에서 자기 자신과 비교 → 거짓 정지 신호 방지.
    var hasLastPosition: Bool = false
    private let proximityWarning = EnemyProximityWarningNode(color: .ganhoIngameDanger)

    // MARK: - Init
    init() {
        // PhysicsBody는 옛 16×20 size 그대로 유지 — hitbox 회귀 0.
        let physicsSize = CGSize(
            width:  GameplayTuning.stoneGuardWidth,
            height: GameplayTuning.stoneGuardHeight
        )
        // 시각은 pixelSpriteScale(2)배 — EnemyNode/ProfessorNode 패턴 동형 (32×40pt).
        let visualSize = CGSize(
            width:  GameplayTuning.stoneGuardWidth  * GameplayTuning.pixelSpriteScale,
            height: GameplayTuning.stoneGuardHeight * GameplayTuning.pixelSpriteScale
        )
        // 초기 텍스처도 TextureAtlasStore 캐시 경유 — applyPixelTexture()와 같은 캐시 워밍 →
        // down/idle 텍스처 단일 인스턴스 공유 (R1: 노드 static 캐시 → Store 위임).
        let initialTexture = TextureAtlasStore.stoneGuardTexture(direction: .down, frame: .idle)
        // Sprint 10 Phase F — color:.ganhoStoneGuardLight 폐기. 본체는 텍스처 노출, color:.clear.
        super.init(texture: initialTexture, color: .clear, size: visualSize)
        name = "stoneGuard"
        zPosition = 5

        // Phase 4-2 — PhysicsBody 부착. collision=0(통과형), contactTest=.player.
        // physicsSize는 기존 16×20 그대로 — hitbox 회귀 0.
        let body = SKPhysicsBody(rectangleOf: physicsSize)
        body.isDynamic           = false
        body.allowsRotation      = false
        body.friction            = 0
        body.restitution         = 0
        body.linearDamping       = 0
        body.categoryBitMask     = PhysicsCategory.stoneGuard
        body.collisionBitMask    = 0
        body.contactTestBitMask  = PhysicsCategory.player
        physicsBody = body
        addChild(proximityWarning)

        // Sprint 10 Phase F — 자식 시각(armor + 일자눈) 부착 폐기 + color clear 제거.
        // setupVisualOverlay 호출 제거 → 본체 픽셀 텍스처만 노출.
        // super.init(color: .clear)로 이미 투명 — colorBlendFactor 강제 1.0 정책 제거.

        // 초기 패트롤은 selectInitialWaypoint(from:)가 외부 호출 시 시작 —
        // init 자동 시작 금지(외부에서 farthest-first index 결정 후 startPatrolFrom 호출).
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Initial Waypoint (Sprint 10 Phase F)
    /// 플레이어 위치에서 가장 먼 waypoint를 시작 위치로 결정. 원본 farthest-first 정책 byte-equal.
    /// GameScene+Setup.setupStoneGuard에서 worldNode addChild 직후 1회 호출.
    /// 호출 직후 startPatrolFrom(index:)로 패트롤 시퀀스 자동 시작.
    func selectInitialWaypoint(from playerPosition: CGPoint) {
        let wps = GameplayTuning.stoneGuardWaypoints
        guard !wps.isEmpty else { return }
        var maxDist: CGFloat = -1
        var maxIndex: Int = 0
        for (i, wp) in wps.enumerated() {
            let d = hypot(wp.x - playerPosition.x, wp.y - playerPosition.y)
            if d > maxDist {
                maxDist = d
                maxIndex = i
            }
        }
        removeAction(forKey: GameplayTuning.stoneGuardPatrolActionKey)
        position = wps[maxIndex]
        startPatrolFrom(index: maxIndex)
    }

    // MARK: - Patrol (Sprint 10 Phase F · 4지점 순환)
    /// 4 waypoint 시계방향 무한 순환 SKAction. 시작 인덱스부터 시퀀스를 구성.
    /// run 직전 위치는 waypoints[startIndex]에 있어야 함(selectInitialWaypoint이 보장).
    private func startPatrolFrom(index startIndex: Int) {
        let waypoints = GameplayTuning.stoneGuardWaypoints
        guard !waypoints.isEmpty else { return }
        let count = waypoints.count
        var moves: [SKAction] = []
        for offset in 0..<count {
            let fromIdx = (startIndex + offset) % count
            let toIdx   = (startIndex + offset + 1) % count
            let from = waypoints[fromIdx]
            let to   = waypoints[toIdx]
            let dist = hypot(to.x - from.x, to.y - from.y)
            let dur  = TimeInterval(dist / GameplayTuning.stoneGuardSpeed)
            moves.append(.move(to: to, duration: dur))
        }
        let loop = SKAction.repeatForever(.sequence(moves))
        run(loop, withKey: GameplayTuning.stoneGuardPatrolActionKey)
    }

    // MARK: - Pixel Animation (Sprint 10 Phase F)
    // R0 — updatePixelAnimation 본문은 PixelPositionDeltaAnimating 기본 구현이 단일 진실 원천.
    // (방향+프레임 병합 후 텍스처 갱신 1회 — needsRefresh 시맨틱 보존.)

    func updateProximityWarning(distanceToPlayer distance: CGFloat, profile: DangerWarningProfile) {
        proximityWarning.update(distanceToPlayer: distance, profile: profile)
    }

    /// 현재 방향/프레임 조합으로 텍스처 갱신 — TextureAtlasStore 캐시 경유.
    /// 호출 빈도·시점·인자(pixelDirection/pixelFrame)는 전혀 변경하지 않음 — 결과 텍스처 byte-equal.
    /// R1 — 노드 보유 static textureCache 삭제, Store가 단일 캐시 지점(석조무사 전용 캐시 분리 유지).
    func applyPixelTexture() {
        texture = TextureAtlasStore.stoneGuardTexture(direction: pixelDirection, frame: pixelFrame)
    }

    // MARK: - Visual Overlay (Sprint 10 Phase F · 본문 삭제)
    // 원본 game.js는 16×20 픽셀 본체만 노출 — 자식 시각(armor + 일자눈) 부착 폐기.
    // R0 — 자연 deprecate 상태였던 stoneGuard 시각 전용 상수도 호출자 0건 확인 후 삭제 완료.
}
