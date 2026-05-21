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
///  - 좌표 정합: 옛 200/760·100/380 폐기 → 원본 80/540·80/300 4점 직접 사용 (GameConfig)
///  - PixelDirection/Frame 갱신 (PlayerNode/EnemyNode/ProfessorNode 패턴 동형)
final class StoneGuardNode: SKSpriteNode {

    // MARK: - Pixel Sprite State (Sprint 10 Phase F)
    /// 현재 픽셀 텍스처가 표현하는 방향. SKAction.move의 진행 방향에 따라 갱신.
    private var pixelDirection: PixelDirection = .down
    /// 현재 픽셀 텍스처가 표현하는 프레임. 이동 중 step1↔step2 교차, 정지 시 idle.
    private var pixelFrame: PixelFrame = .idle
    /// step1↔step2 교차 누적 시간 (초). 0.22초 도달 시 토글 + 0 리셋.
    private var frameAccumulator: TimeInterval = 0
    /// updatePixelAnimation에서 *이전 프레임 위치*와 비교하여 진행 방향 산출.
    private var lastPosition: CGPoint = .zero
    /// lastPosition 첫 초기화 여부. 첫 update에서 자기 자신과 비교 → 거짓 정지 신호 방지.
    private var hasLastPosition: Bool = false

    // MARK: - Init
    init() {
        // PhysicsBody는 옛 16×20 size 그대로 유지 — hitbox 회귀 0.
        let physicsSize = CGSize(
            width:  GameConfig.stoneGuardWidth,
            height: GameConfig.stoneGuardHeight
        )
        // 시각은 pixelSpriteScale(2)배 — EnemyNode/ProfessorNode 패턴 동형 (32×40pt).
        let visualSize = CGSize(
            width:  GameConfig.stoneGuardWidth  * GameConfig.pixelSpriteScale,
            height: GameConfig.stoneGuardHeight * GameConfig.pixelSpriteScale
        )
        let initialTexture = PixelSpriteRenderer.texture(
            from: PixelSprite.stoneGuardData(direction: .down, frame: .idle),
            palette: PixelPalette.stoneGuardPalette
        )
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
        let wps = GameConfig.stoneGuardWaypoints
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
        removeAction(forKey: GameConfig.stoneGuardPatrolActionKey)
        position = wps[maxIndex]
        startPatrolFrom(index: maxIndex)
    }

    // MARK: - Patrol (Sprint 10 Phase F · 4지점 순환)
    /// 4 waypoint 시계방향 무한 순환 SKAction. 시작 인덱스부터 시퀀스를 구성.
    /// run 직전 위치는 waypoints[startIndex]에 있어야 함(selectInitialWaypoint이 보장).
    private func startPatrolFrom(index startIndex: Int) {
        let waypoints = GameConfig.stoneGuardWaypoints
        guard !waypoints.isEmpty else { return }
        let count = waypoints.count
        var moves: [SKAction] = []
        for offset in 0..<count {
            let fromIdx = (startIndex + offset) % count
            let toIdx   = (startIndex + offset + 1) % count
            let from = waypoints[fromIdx]
            let to   = waypoints[toIdx]
            let dist = hypot(to.x - from.x, to.y - from.y)
            let dur  = TimeInterval(dist / GameConfig.stoneGuardSpeed)
            moves.append(.move(to: to, duration: dur))
        }
        let loop = SKAction.repeatForever(.sequence(moves))
        run(loop, withKey: GameConfig.stoneGuardPatrolActionKey)
    }

    // MARK: - Pixel Animation (Sprint 10 Phase F)
    /// GameScene.update가 매 프레임 호출. position 변화량으로 방향/걷기 프레임 갱신.
    /// ProfessorNode.updatePixelAnimation 패턴 정확 답습 — SKAction.move 기반이라 position 변화량 추적.
    func updatePixelAnimation(deltaTime: TimeInterval) {
        guard hasLastPosition else {
            lastPosition = position
            hasLastPosition = true
            return
        }
        let dx = position.x - lastPosition.x
        let dy = position.y - lastPosition.y
        lastPosition = position

        let absDx = abs(dx)
        let absDy = abs(dy)
        guard absDx > 0.01 || absDy > 0.01 else {
            if pixelFrame != .idle {
                pixelFrame = .idle
                frameAccumulator = 0
                refreshTexture()
            }
            return
        }
        let newDir: PixelDirection
        if absDx > absDy {
            newDir = dx >= 0 ? .right : .left
        } else {
            newDir = dy >= 0 ? .up : .down
        }
        var needsRefresh = false
        if newDir != pixelDirection {
            pixelDirection = newDir
            needsRefresh = true
        }
        frameAccumulator += deltaTime
        if frameAccumulator >= GameConfig.pixelWalkFrameInterval {
            frameAccumulator = 0
            pixelFrame = (pixelFrame == .step1) ? .step2 : .step1
            needsRefresh = true
        }
        if needsRefresh {
            refreshTexture()
        }
    }

    /// 현재 방향/프레임 조합으로 텍스처 재생성.
    private func refreshTexture() {
        texture = PixelSpriteRenderer.texture(
            from: PixelSprite.stoneGuardData(direction: pixelDirection, frame: pixelFrame),
            palette: PixelPalette.stoneGuardPalette
        )
    }

    // MARK: - Visual Overlay (Sprint 10 Phase F · 본문 삭제)
    // setupVisualOverlay / attachArmor / attachEyes / applyVisualScaleV9 4개 메서드 본문 삭제.
    // 원본 game.js는 16×20 픽셀 본체만 노출 — 자식 시각(armor + 일자눈) 부착 폐기.
    // GameConfig.stoneGuardEyeOffsetX/Y/stoneGuardVisualScaleV9 상수는 변경 금지 우회 위해 보존
    // (호출자 0건이 되어 자연 deprecate).
}
