//
//  ProfessorNode.swift
//  GanhoMusic Shared
//
//  Phase 9-7 · 이교수 — 상 난이도 전용 두 번째 적 NPC.
//  4 waypoint 시계방향 순찰 + 청진기(StethoscopeNode) 투척 루프.
//  physicsBody 미부착 — *통과형* NPC. 위협은 청진기가 담당.
//  EnemyNode/StoneGuardNode 패턴 답습 — pixelDirection/pixelFrame + SKAction.move 순환.
//

import SpriteKit

/// 이교수 NPC. 수간호사(EnemyNode 추적 AI)와 석조무사(StoneGuardNode 패트롤) 사이의
/// 중간형 — *직선 순찰 + 원거리 공격*. PhysicsBody 미부착이라 player/벽 통과 가능.
/// 위협은 청진기(StethoscopeNode)가 담당 — 명중 시 player.freeze(duration:) 2초 발화.
final class ProfessorNode: SKSpriteNode {

    // MARK: - Pixel Sprite State (Phase 9-7)
    /// 현재 픽셀 텍스처가 표현하는 방향. SKAction.move의 진행 방향에 따라 갱신.
    /// EnemyNode 패턴 답습.
    private var pixelDirection: PixelDirection = .down
    /// 현재 픽셀 텍스처가 표현하는 프레임. 이동 중 step1↔step2 교차, 정지 시 idle.
    private var pixelFrame: PixelFrame = .idle
    /// step1↔step2 교차 누적 시간 (초). GameConfig.pixelWalkFrameInterval 도달 시 토글 + 0 리셋.
    private var frameAccumulator: TimeInterval = 0
    /// updatePixelAnimation에서 *이전 프레임 위치*와 비교하여 진행 방향 산출.
    /// SKAction.move는 velocity를 set하지 않으므로 position 변화량을 직접 추적.
    private var lastPosition: CGPoint = .zero
    /// lastPosition 첫 초기화 여부. didMove → setupProfessor 흐름에서 position이 set된 후
    /// 첫 update에서 자기 자신과 비교 → 거짓 정지 신호 방지.
    private var hasLastPosition: Bool = false

    // MARK: - Throwing State (Phase 9-7)
    /// 청진기 발사 루프가 사용하는 worldNode 약참조. SkillSystem.scene 패턴 답습.
    private weak var worldRef: SKNode?
    /// player 위치를 매 발사 시점에 *현재 값*으로 캡처하는 클로저. weak self 캡처는 호출부 책임.
    private var targetProvider: () -> CGPoint? = { nil }
    /// 게임 진행률(0..1) 공급자. 발사 주기 보간에 사용.
    private var progressProvider: () -> Double = { 0 }

    // MARK: - Init
    init() {
        // EnemyNode/PlayerNode 패턴 동형 — 시각은 pixelSpriteScale(2)배, physicsBody는 미부착.
        let visualSize = CGSize(
            width:  GameConfig.professorWidth  * GameConfig.pixelSpriteScale,
            height: GameConfig.professorHeight * GameConfig.pixelSpriteScale
        )
        let initialTexture = PixelSpriteRenderer.texture(
            from: PixelSprite.professorData(direction: .down, frame: .idle),
            palette: PixelPalette.professorPalette
        )
        super.init(texture: initialTexture, color: .clear, size: visualSize)
        name = "professor"
        // EnemyNode(5)와 동급 — 음표/벽(0) 위, HUD(100) 아래.
        zPosition = 5

        // physicsBody 미부착 — *통과형* NPC. 위협은 청진기가 담당(SPEC.md §주의사항).
        // collision/contact 모두 0 = physicsBody 자체를 안 만드는 게 가장 단순/안전.

        startPatrol()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Patrol
    /// 4 waypoint 시계방향 무한 순환 SKAction. StoneGuardNode.startPatrol 패턴 답습.
    /// init 시점 호출 — 외부에서 position을 첫 waypoint에 set한 직후 자동 진행.
    private func startPatrol() {
        let waypoints = GameConfig.professorWaypoints
        var moves: [SKAction] = []
        for i in 0..<waypoints.count {
            let from = waypoints[i]
            let to   = waypoints[(i + 1) % waypoints.count]
            let dist = hypot(to.x - from.x, to.y - from.y)
            let dur  = TimeInterval(dist / GameConfig.professorSpeed)
            moves.append(.move(to: to, duration: dur))
        }
        let loop = SKAction.repeatForever(.sequence(moves))
        run(loop)
    }

    // MARK: - Throwing
    /// 외부(GameScene+Setup.setupProfessor)가 1회 호출. 의존성 주입 후 첫 발사 스케줄.
    /// [weak self] 캡처는 외부 클로저 책임 — targetProvider/progressProvider는 외부 클로저 그대로 보관.
    /// - Parameters:
    ///   - targetProvider: 현재 player 위치 공급자. nil이면 이 사이클 noop(다음 사이클 재시도).
    ///   - worldNode: 청진기 노드를 부착할 부모. weak 보관.
    ///   - progressProvider: 게임 진행률(0..1). 발사 주기 보간에 사용.
    func startThrowingStethoscopes(targetProvider: @escaping () -> CGPoint?,
                                    worldNode: SKNode,
                                    progressProvider: @escaping () -> Double) {
        self.targetProvider = targetProvider
        self.worldRef = worldNode
        self.progressProvider = progressProvider
        scheduleNextThrow()
    }

    /// 다음 발사를 SKAction 재귀로 예약. SpawnSystem.scheduleNextFire 패턴 답습.
    /// withKey: professorThrowActionKey 동일 — stopThrowing의 removeAction이 즉시 정지 가능.
    /// 매 사이클마다 currentThrowInterval() 호출 → 진행률 보간으로 *점점 빨라지는* 톤.
    private func scheduleNextThrow() {
        let interval = currentThrowInterval()
        let wait = SKAction.wait(forDuration: interval)
        let throwAction = SKAction.run { [weak self] in
            self?.throwStethoscope()
            self?.scheduleNextThrow()
        }
        run(.sequence([wait, throwAction]), withKey: GameConfig.professorThrowActionKey)
    }

    /// 현재 게임 진행률에 따른 청진기 발사 주기 (보간).
    /// 시작 2.5초 → 끝 1.4초. 게임 후반 *점점 빨라지는* 톤.
    private func currentThrowInterval() -> TimeInterval {
        let progress = progressProvider()
        let start = GameConfig.stethoscopeThrowIntervalStart
        let end   = GameConfig.stethoscopeThrowIntervalEnd
        return start + (end - start) * progress
    }

    /// 청진기 1발 발사. SpawnSystem.fireProjectile 패턴 답습.
    /// 1) worldRef nil 가드 — 발사 불가 시 자연 noop.
    /// 2) targetProvider() nil 가드 — player 위치 미공급 시 noop.
    /// 3) max concurrent 가드 — 동시 4발 초과 시 noop.
    /// 4) magnitude=0 가드 — player와 정확히 겹친 경우 NaN 방지.
    /// 5) 단위 벡터 × stethoscopeSpeed → velocity set.
    private func throwStethoscope() {
        guard let world = worldRef else { return }
        guard let target = targetProvider() else { return }
        guard currentStethoscopeCount(in: world) < GameConfig.stethoscopeMaxConcurrent else { return }
        let dx = target.x - position.x
        let dy = target.y - position.y
        let magnitude = hypot(dx, dy)
        guard magnitude > 0 else { return }
        let unitX = dx / magnitude
        let unitY = dy / magnitude
        let stethoscope = StethoscopeNode()
        stethoscope.position = position
        stethoscope.physicsBody?.velocity = CGVector(
            dx: unitX * GameConfig.stethoscopeSpeed,
            dy: unitY * GameConfig.stethoscopeSpeed
        )
        world.addChild(stethoscope)
    }

    /// worldNode 안 청진기 ("stethoscope" 이름) 개수.
    /// SpawnSystem.currentProjectileCount 패턴 답습 — DRY 유지.
    private func currentStethoscopeCount(in world: SKNode) -> Int {
        var count = 0
        world.enumerateChildNodes(withName: "stethoscope") { _, _ in count += 1 }
        return count
    }

    /// 게임 종료 시 GameScene.endGame이 호출. 발사 루프 정지 + 활성 청진기 velocity 0.
    /// SpawnSystem.stop 패턴 답습. removeAction(forKey:)는 멱등 — 이미 정지 상태에서 호출해도 안전.
    /// - Parameter worldNode: 활성 청진기 enumerate 대상.
    func stopThrowing(worldNode: SKNode) {
        removeAction(forKey: GameConfig.professorThrowActionKey)
        worldNode.enumerateChildNodes(withName: "stethoscope") { node, _ in
            node.physicsBody?.velocity = .zero
        }
    }

    // MARK: - Pixel Animation (Phase 9-7)
    /// GameScene.update가 매 프레임 호출. position 변화량으로 방향/걷기 프레임 갱신.
    /// EnemyNode.updatePixelDirection/tickWalkFrame 패턴 답습 — 단, EnemyNode는 velocity 기반이지만
    /// 본 노드는 SKAction.move 기반이라 *position 변화량*을 자체 추적.
    /// 정지(거의 미동) 시 idle 프레임 유지.
    func updatePixelAnimation(deltaTime: TimeInterval) {
        // 첫 호출 — lastPosition 초기화 후 이번 프레임 변화량 비교 스킵.
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
        // 거의 정지 — idle 프레임으로 정착(이미 idle이면 noop).
        guard absDx > 0.01 || absDy > 0.01 else {
            if pixelFrame != .idle {
                pixelFrame = .idle
                frameAccumulator = 0
                refreshTexture()
            }
            return
        }
        // 방향 산출 — EnemyNode 패턴 동형.
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
        // 걷기 프레임 토글 — EnemyNode.tickWalkFrame 패턴 동형.
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

    /// 현재 방향/프레임 조합으로 텍스처 재생성. EnemyNode.refreshTexture 패턴 답습.
    private func refreshTexture() {
        texture = PixelSpriteRenderer.texture(
            from: PixelSprite.professorData(direction: pixelDirection, frame: pixelFrame),
            palette: PixelPalette.professorPalette
        )
    }
}
