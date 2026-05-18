//
//  EnemyNode.swift
//  GanhoMusic Shared
//
//  Phase 2-6 · 수간호사 적 NPC (직선 추적 AI + 접촉 시 게임오버)
//  Phase 4-6 · 5초 도주 모드 추가 (isFleeing + startFleeing + update 방향 분기)
//  Phase 4-7 · startFleeing 시그니처에 onEnd 콜백 매개변수 추가 (default = {})
//  Phase 7-1 · 난이도별 base/max 속도 인스턴스 프로퍼티 외부화 + apply(_:Difficulty)
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

    // MARK: - Init
    init() {
        let size = CGSize(
            width:  GameConfig.enemyWidth,
            height: GameConfig.enemyHeight
        )
        super.init(texture: nil, color: .ganhoBloodAccent, size: size)
        name = "enemy"

        // PhysicsBody 부착 — PlayerNode와 동일 정책(dynamic, 회전/마찰/탄성/감쇠 0).
        // collision은 wall만(외곽 벽/중앙 기둥에 막힘), contactTest는 player(닿으면 알림).
        let body = SKPhysicsBody(rectangleOf: size)
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
        physicsBody?.velocity = CGVector(
            dx: unitX * speed * direction,
            dy: unitY * speed * direction
        )
    }
}
