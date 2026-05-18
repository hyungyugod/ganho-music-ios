//
//  EnemyNode.swift
//  GanhoMusic Shared
//
//  Phase 2-6 · 수간호사 적 NPC (직선 추적 AI + 접촉 시 게임오버)
//  Phase 4-6 · 5초 도주 모드 추가 (isFleeing + startFleeing + update 방향 분기)
//  Phase 4-7 · startFleeing 시그니처에 onEnd 콜백 매개변수 추가 (default = {})
//  Phase 7-1 · 난이도별 base/max 속도 인스턴스 프로퍼티 외부화 + apply(_:Difficulty)
//  Phase 8-2 · 단색 SKSpriteNode(.ganhoBloodAccent) → 픽셀 텍스처 모드. 백발 + 안경 + 캡 + 흰 간호사복.
//             PlayerNode(Phase 8-1) 패턴 동형 — pixelDirection/pixelFrame/frameAccumulator + refreshTexture.
//             physicsBody 정책(크기/카테고리/충돌) *완전 보존* — 게임 hitbox 회귀 0.
//

import SpriteKit

/// 수간호사 적 NPC. GameScene이 매 프레임 update(deltaTime:targetPosition:)을 호출하면
/// player를 향해 정규화 벡터 × enemyBaseSpeed로 velocity 갱신. 직선 추적.
/// PlayerNode 패턴(2-2) 정확 일치 — dynamic body, gravity/friction/damping 0.
final class EnemyNode: SKSpriteNode {

    // MARK: - State
    /// Phase 4-6 — 도주 모드 플래그. true면 update에서 velocity 방향이 반전된다.
    /// startFleeing(duration:) 메서드만 토글한다 (외부 직접 쓰기 금지 정책).
    var isFleeing: Bool = false

    /// Phase 7-1 — 난이도별 시작 속도 (pt/s). default = GameConfig.enemyBaseSpeed → apply 누락 시 graceful fallback(easy 동작).
    /// update(deltaTime:targetPosition:speedT:)에서 base + (end - base) × speedT 보간식의 base.
    var baseSpeedStart: CGFloat = GameConfig.enemyBaseSpeed
    /// Phase 7-1 — 난이도별 끝 속도 (pt/s). default = GameConfig.enemyMaxSpeed → easy 동일 회귀 0.
    var baseSpeedEnd: CGFloat = GameConfig.enemyMaxSpeed

    // MARK: - Pixel Sprite State (Phase 8-2)
    /// 현재 픽셀 텍스처가 표현하는 방향. velocity 부호 변화 시 갱신 후 refreshTexture 호출.
    /// 정지(.zero) 시 마지막 방향 유지 — 갑작스러운 down 복귀 없음(자연 톤).
    private var pixelDirection: PixelDirection = .down
    /// 현재 픽셀 텍스처가 표현하는 프레임. 이동 중 step1↔step2 교차, 정지 시 idle.
    private var pixelFrame: PixelFrame = .idle
    /// step1↔step2 교차 누적 시간 (초). GameConfig.pixelWalkFrameInterval 도달 시 토글 + 0 리셋.
    private var frameAccumulator: TimeInterval = 0

    // MARK: - Init
    init() {
        // Phase 8-2 — physicsBody 크기는 그대로 16×20 (게임 hitbox 회귀 0).
        // 시각 크기는 pixelSpriteScale(2)배 — 32×40pt 화면 픽셀 (PlayerNode 패턴 동형).
        let physicsSize = CGSize(
            width:  GameConfig.enemyWidth,
            height: GameConfig.enemyHeight
        )
        let visualSize = CGSize(
            width:  GameConfig.enemyWidth  * GameConfig.pixelSpriteScale,
            height: GameConfig.enemyHeight * GameConfig.pixelSpriteScale
        )
        // 초기 텍스처는 down/idle. update가 velocity 기반으로 즉시 갱신.
        let initialTexture = PixelSpriteRenderer.texture(
            from: PixelSprite.nurseChiefData(direction: .down, frame: .idle),
            palette: PixelPalette.chiefPalette
        )
        super.init(texture: initialTexture, color: .clear, size: visualSize)
        name = "enemy"

        // PhysicsBody 부착 — PlayerNode와 동일 정책(dynamic, 회전/마찰/탄성/감쇠 0).
        // collision은 wall만(외곽 벽/중앙 기둥에 막힘), contactTest는 player(닿으면 알림).
        // Phase 8-2 — body 크기는 *시각 크기와 무관하게* physicsSize 사용 → 기존 hitbox 보존.
        let body = SKPhysicsBody(rectangleOf: physicsSize)
        body.isDynamic           = true
        body.allowsRotation      = false
        body.friction            = 0
        body.restitution         = 0
        body.linearDamping       = 0
        body.categoryBitMask     = PhysicsCategory.enemy
        body.collisionBitMask    = PhysicsCategory.wall    // 벽/기둥에 막힘
        body.contactTestBitMask  = PhysicsCategory.player  // player와 닿으면 알림
        physicsBody = body

        // Phase 2-6 hotfix 1 — 다른 노드(벽/음표/기둥) 위에 항상 그려지도록 zPosition 명시.
        // HUD(100)/D-Pad(기본 0이지만 cameraNode 자식이라 별도 트리)보다 낮음 — UI를 가리지 않음.
        zPosition = 5
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Apply
    /// Phase 7-1 — 난이도 정체성 단일 진입점.
    /// dict lookup에 fallback 필수 — 강제 언래핑 금지(주의사항 5).
    /// GameScene+Setup.setupEnemy에서 1줄 호출.
    func apply(_ difficulty: Difficulty) {
        baseSpeedStart = GameConfig.enemySpeedStartByDifficulty[difficulty] ?? GameConfig.enemyBaseSpeed
        baseSpeedEnd   = GameConfig.enemySpeedEndByDifficulty[difficulty]   ?? GameConfig.enemyMaxSpeed
    }

    // MARK: - Flee
    /// 외부 호출 시 duration초간 도주 모드 진입. 만료 시 자동 복귀.
    /// 이미 도주 중이면 무시(재호출 가드). [weak self]로 순환 참조 방지.
    /// Phase 4-6 — DispatchQueue/Timer 금지. SKAction.sequence로 시간 흐름 표현.
    /// Phase 4-7 — duration 종료 직후 onEnd 콜백 발화. 기본값 {}로 4-6 호출 사이트 호환.
    func startFleeing(duration: TimeInterval, onEnd: @escaping () -> Void = {}) {
        if isFleeing { return }
        let start = SKAction.run { [weak self] in self?.isFleeing = true }
        let wait  = SKAction.wait(forDuration: duration)
        let end   = SKAction.run { [weak self] in
            self?.isFleeing = false
            onEnd()
        }
        run(.sequence([start, wait, end]))
    }

    // MARK: - Update
    /// 외부에서 매 프레임 호출. player 위치를 향한 단위 벡터 × 보간 속도 → velocity.
    /// magnitude == 0 가드(NaN 방지).
    /// - Parameters:
    ///   - deltaTime: dt — 본 sprint에서는 미사용 (velocity 기반, 엔진이 dt 처리).
    ///   - targetPosition: 추적 대상 좌표(worldNode 좌표계). 보통 player.position.
    ///   - speedT: 게임 진행률 (0 ~ 1). 0 = 시작 속도(base), 1 = 최대 속도(max).
    ///             GameScene이 매 프레임 1 - remainingTime / gameDuration 으로 계산.
    func update(deltaTime: TimeInterval, targetPosition: CGPoint, speedT: CGFloat) {
        let dx = targetPosition.x - position.x
        let dy = targetPosition.y - position.y
        let magnitude = hypot(dx, dy)
        guard magnitude > 0 else {
            physicsBody?.velocity = .zero
            // Phase 8-2 — 추적 대상과 정확히 겹친 극히 드문 경우. 픽셀은 idle 프레임으로 정착.
            tickWalkFrame(deltaTime: deltaTime, isMoving: false)
            return
        }
        let unitX = dx / magnitude
        let unitY = dy / magnitude
        // Phase 2-8 — 선형 보간: speedT 0 = base, 1 = max.
        // Phase 7-1 — GameConfig 상수 → 인스턴스 프로퍼티 참조(난이도별 차등).
        // easy의 baseSpeedStart/End는 GameConfig.enemyBaseSpeed/MaxSpeed와 정확히 일치 → 회귀 0.
        let speed = baseSpeedStart
            + (baseSpeedEnd - baseSpeedStart) * speedT
        // Phase 4-6 — 도주 모드면 player 반대 방향(-1). 추적이면 +1. 한 줄 분기.
        let direction: CGFloat = isFleeing ? -1 : 1
        let newVelocity = CGVector(
            dx: unitX * speed * direction,
            dy: unitY * speed * direction
        )
        physicsBody?.velocity = newVelocity

        // Phase 8-2 — 픽셀 텍스처 자기 갱신 (PlayerNode 패턴 동형, GameScene 변경 0).
        // velocity가 set된 *직후* 같은 벡터로 방향/프레임 갱신 — 이번 프레임 의도 즉시 반영.
        // 도주 시 velocity 부호가 반전되므로 픽셀 방향도 자동으로 반대를 향함(자연 톤).
        updatePixelDirection(newVelocity)
        let isMoving = abs(newVelocity.dx) > 1.0 || abs(newVelocity.dy) > 1.0
        tickWalkFrame(deltaTime: deltaTime, isMoving: isMoving)
    }

    // MARK: - Pixel Sprite (Phase 8-2)
    /// velocity 부호로 4방향 산출. 정지(임계값 미만) 시 마지막 방향 유지.
    /// 텍스처 재생성은 *방향이 실제로 바뀐 프레임에만* — 매 프레임 호출이라도 정지 시 비용 0.
    /// PlayerNode.updatePixelDirection과 정확히 동일 패턴 (Phase 8-1).
    private func updatePixelDirection(_ velocity: CGVector) {
        let absDx = abs(velocity.dx)
        let absDy = abs(velocity.dy)
        // 거의 정지(임계값 0.1 미만) — 방향 유지. 미세 잔존 velocity가 흔들림으로 보이지 않도록 가드.
        guard absDx > 0.1 || absDy > 0.1 else { return }
        let newDir: PixelDirection
        if absDx > absDy {
            newDir = velocity.dx >= 0 ? .right : .left
        } else {
            // SpriteKit 좌표계: +y는 위쪽 → dy > 0이면 up.
            newDir = velocity.dy >= 0 ? .up : .down
        }
        if newDir != pixelDirection {
            pixelDirection = newDir
            refreshTexture()
        }
    }

    /// 걷는 중일 때 step1↔step2 교차, 정지 시 idle.
    /// 텍스처 재생성은 *변경 순간에만* — 매 프레임 호출이라도 변화 없으면 비용 0.
    /// PlayerNode.tickWalkFrame과 정확히 동일 패턴 (Phase 8-1).
    private func tickWalkFrame(deltaTime: TimeInterval, isMoving: Bool) {
        guard isMoving else {
            if pixelFrame != .idle {
                pixelFrame = .idle
                frameAccumulator = 0
                refreshTexture()
            }
            return
        }
        frameAccumulator += deltaTime
        if frameAccumulator >= GameConfig.pixelWalkFrameInterval {
            frameAccumulator = 0
            pixelFrame = (pixelFrame == .step1) ? .step2 : .step1
            refreshTexture()
        }
    }

    /// 현재 방향/프레임 조합으로 텍스처 재생성 후 set. SKTexture는 ARC 자동 정리 — 메모리 누수 0.
    /// PlayerNode.refreshTexture와 정확히 동일 패턴 (Phase 8-1). 팔레트만 chief로 분기.
    private func refreshTexture() {
        texture = PixelSpriteRenderer.texture(
            from: PixelSprite.nurseChiefData(direction: pixelDirection,
                                              frame: pixelFrame),
            palette: PixelPalette.chiefPalette
        )
    }
}
