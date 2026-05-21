//
//  ProfessorNode.swift
//  GanhoMusic Shared
//
//  Phase 9-7 · 이교수 — 상 난이도 전용 두 번째 적 NPC.
//  Sprint 10 Phase F · 8자 패트롤 + 텔레그래프(0.4s) + 시작 오프셋(+12px) + farthest-first.
//  자식 시각(disc/tube) 제거 + color clear 제거 — 본체 16×20 픽셀만 노출.
//
//  단일 진실 원천: SPEC.md §7.2/§8 + docs/ORIGINAL_GAME_ANALYSIS.md L109~L115/L2983~L3019/L3084~L3106.
//

import SpriteKit

/// 이교수 NPC. 수간호사(EnemyNode 패트롤 AI)와 석조무사(StoneGuardNode 4지점 순환) 사이의
/// 중간형 — *8자 패트롤 + 원거리 공격*. PhysicsBody 미부착이라 player/벽 통과 가능.
/// 위협은 청진기(StethoscopeNode)가 담당 — 명중 시 토스트 1s → freeze 2s 직렬화.
///
/// Sprint 10 Phase F 변경:
///  - startPatrol → startPatrolFrom(index:) 리팩터 + selectInitialWaypoint(from:) 신설(farthest-first)
///  - 좌표 정합: 시계방향 직사각형 폐기 → 원본 8자(figure-8) 4점 순환
///  - 청진기 발사 직전 0.4s 텔레그래프 노출(ProfessorTelegraphNode)
///  - 발사 시작점 = 본체 + unitVec × 12px (자기 위치 충돌로 즉시 소멸 방지)
///  - 자식 시각(disc/tube)/applyVisualScaleV9 본체 삭제 — 픽셀 본체만 노출
final class ProfessorNode: SKSpriteNode {

    // MARK: - Pixel Sprite State (Phase 9-7 · 보존)
    /// 현재 픽셀 텍스처가 표현하는 방향. SKAction.move의 진행 방향에 따라 갱신.
    private var pixelDirection: PixelDirection = .down
    /// 현재 픽셀 텍스처가 표현하는 프레임. 이동 중 step1↔step2 교차, 정지 시 idle.
    private var pixelFrame: PixelFrame = .idle
    /// step1↔step2 교차 누적 시간 (초). GameConfig.pixelWalkFrameInterval 도달 시 토글 + 0 리셋.
    private var frameAccumulator: TimeInterval = 0
    /// updatePixelAnimation에서 *이전 프레임 위치*와 비교하여 진행 방향 산출.
    private var lastPosition: CGPoint = .zero
    /// lastPosition 첫 초기화 여부. 첫 update에서 자기 자신과 비교 → 거짓 정지 신호 방지.
    private var hasLastPosition: Bool = false

    // MARK: - Throwing State (Phase 9-7 · 보존)
    /// 청진기 발사 루프가 사용하는 worldNode 약참조.
    private weak var worldRef: SKNode?
    /// player 위치를 매 발사 시점에 *현재 값*으로 캡처하는 클로저.
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
        zPosition = 5

        // physicsBody 미부착 — *통과형* NPC. 위협은 청진기가 담당.

        // Sprint 10 Phase F — 자식 시각(disc/tube) 부착 폐기 + color clear 제거.
        // setupVisualOverlay 호출 제거 → 본체 픽셀 텍스처만 노출.
        // super.init(color: .clear)로 이미 투명 — colorBlendFactor 강제 1.0 정책 제거.

        // 초기 패트롤은 selectInitialWaypoint(from:)가 외부 호출 시 시작 — 본 Phase에서
        // init 자동 시작 금지(외부에서 farthest-first index 결정 후 startPatrolFrom 호출).
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Initial Waypoint (Sprint 10 Phase F)
    /// 플레이어 위치에서 가장 먼 waypoint를 시작 위치로 결정. 원본 farthest-first 정책 byte-equal.
    /// GameScene+Setup.setupProfessor에서 worldNode addChild 직후 1회 호출.
    /// 호출 직후 startPatrolFrom(index:)로 패트롤 시퀀스 자동 시작.
    func selectInitialWaypoint(from playerPosition: CGPoint) {
        let wps = GameConfig.professorWaypoints
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
        // 이전 패트롤 액션 정지(있다면) — 멱등 호출 안전.
        removeAction(forKey: GameConfig.professorPatrolActionKey)
        position = wps[maxIndex]
        startPatrolFrom(index: maxIndex)
    }

    // MARK: - Patrol (Sprint 10 Phase F · 8자 순환)
    /// 4 waypoint 8자 무한 순환 SKAction. 시작 인덱스부터 반대로 재구성하여
    /// run하기 직전 위치는 waypoints[startIndex]에 있어야 함(selectInitialWaypoint이 보장).
    /// 좌표 순서는 GameConfig.professorWaypoints가 8자(figure-8) 형태로 정의 —
    /// (120,100)→(520,280)→(520,100)→(120,280) → 두 번 교차하며 한 바퀴.
    private func startPatrolFrom(index startIndex: Int) {
        let waypoints = GameConfig.professorWaypoints
        guard !waypoints.isEmpty else { return }
        let count = waypoints.count
        var moves: [SKAction] = []
        // 시작 인덱스부터 시계 순서대로 next waypoint를 잇는 .move 액션을 순환 길이만큼 생성.
        for offset in 0..<count {
            let fromIdx = (startIndex + offset) % count
            let toIdx   = (startIndex + offset + 1) % count
            let from = waypoints[fromIdx]
            let to   = waypoints[toIdx]
            let dist = hypot(to.x - from.x, to.y - from.y)
            let dur  = TimeInterval(dist / GameConfig.professorSpeed)
            moves.append(.move(to: to, duration: dur))
        }
        let loop = SKAction.repeatForever(.sequence(moves))
        run(loop, withKey: GameConfig.professorPatrolActionKey)
    }

    // MARK: - Throwing
    /// 외부(GameScene+Setup.setupProfessor)가 1회 호출. 의존성 주입 후 첫 발사 스케줄.
    /// 첫 발사 전 GameConfig.professorInitialThrowDelay(3.0s) 대기 — 플레이어 학습 시간.
    func startThrowingStethoscopes(targetProvider: @escaping () -> CGPoint?,
                                    worldNode: SKNode,
                                    progressProvider: @escaping () -> Double) {
        self.targetProvider = targetProvider
        self.worldRef = worldNode
        self.progressProvider = progressProvider
        scheduleFirstThrow()
    }

    /// 첫 발사를 professorInitialThrowDelay(3.0s) 후 발화. 이후엔 scheduleNextThrow의
    /// progress 보간(2.5 → 1.4)으로 자연 진행.
    private func scheduleFirstThrow() {
        let initialWait = SKAction.wait(forDuration: GameConfig.professorInitialThrowDelay)
        let kickoff = SKAction.run { [weak self] in
            self?.throwStethoscope()
            self?.scheduleNextThrow()
        }
        run(.sequence([initialWait, kickoff]), withKey: GameConfig.professorThrowActionKey)
    }

    /// 다음 발사를 SKAction 재귀로 예약. 매 사이클마다 currentThrowInterval() 호출 →
    /// 진행률 보간으로 *점점 빨라지는* 톤.
    private func scheduleNextThrow() {
        let interval = currentThrowInterval()
        let wait = SKAction.wait(forDuration: interval)
        let throwAction = SKAction.run { [weak self] in
            self?.throwStethoscope()
            self?.scheduleNextThrow()
        }
        run(.sequence([wait, throwAction]), withKey: GameConfig.professorThrowActionKey)
    }

    /// 현재 게임 진행률에 따른 청진기 발사 주기 (보간). 시작 2.5초 → 끝 1.4초.
    private func currentThrowInterval() -> TimeInterval {
        let progress = progressProvider()
        let start = GameConfig.stethoscopeThrowIntervalStart
        let end   = GameConfig.stethoscopeThrowIntervalEnd
        return start + (end - start) * progress
    }

    /// 청진기 발사 1사이클 — 텔레그래프 0.4s 후 fireStethoscope.
    /// 1) worldRef nil 가드 — 발사 불가 시 자연 noop.
    /// 2) targetProvider() nil 가드 — player 위치 미공급 시 noop.
    /// 3) max concurrent 가드 — 동시 4발 초과 시 noop(텔레그래프도 부착 안 함).
    /// 4) ProfessorTelegraphNode 부착 → 0.4s 후 fireStethoscope + 텔레그래프 제거.
    /// 원본 game.js L3084~L3106 byte-equal — telegraph 사이에 chase/throw 추가 X.
    private func throwStethoscope() {
        guard let world = worldRef else { return }
        guard let target = targetProvider() else { return }
        guard currentStethoscopeCount(in: world) < GameConfig.stethoscopeMaxConcurrent else { return }
        let telegraph = ProfessorTelegraphNode()
        telegraph.position = CGPoint(x: 0, y: GameConfig.professorTelegraphOffsetY)
        addChild(telegraph)
        telegraph.startBlinking()
        let wait = SKAction.wait(forDuration: GameConfig.professorTelegraphDuration)
        let fire = SKAction.run { [weak self, weak telegraph, weak world] in
            telegraph?.removeFromParent()
            guard let self = self, let world = world else { return }
            self.fireStethoscope(target: target, world: world)
        }
        run(.sequence([wait, fire]))
    }

    /// 실제 청진기 발사. 텔레그래프 종료 직후 호출.
    /// spawnPoint = 본체 위치 + unitVec × 12px — 자기와 충돌해 즉시 사라지는 버그 방지.
    /// velocity = unitVec × stethoscopeSpeed(220).
    /// 원본 game.js L3094 byte-equal.
    private func fireStethoscope(target: CGPoint, world: SKNode) {
        let dx = target.x - position.x
        let dy = target.y - position.y
        let magnitude = hypot(dx, dy)
        guard magnitude > 0 else { return }
        let unitX = dx / magnitude
        let unitY = dy / magnitude
        let steth = StethoscopeNode()
        steth.position = CGPoint(
            x: position.x + unitX * GameConfig.stethoscopeFireStartOffset,
            y: position.y + unitY * GameConfig.stethoscopeFireStartOffset
        )
        steth.physicsBody?.velocity = CGVector(
            dx: unitX * GameConfig.stethoscopeSpeed,
            dy: unitY * GameConfig.stethoscopeSpeed
        )
        world.addChild(steth)
    }

    /// worldNode 안 청진기("stethoscope" 이름) 개수. SpawnSystem.currentProjectileCount 패턴 답습.
    private func currentStethoscopeCount(in world: SKNode) -> Int {
        var count = 0
        world.enumerateChildNodes(withName: "stethoscope") { _, _ in count += 1 }
        return count
    }

    /// 게임 종료 시 GameScene.endGame이 호출. 발사 루프 정지 + 활성 청진기 velocity 0.
    func stopThrowing(worldNode: SKNode) {
        removeAction(forKey: GameConfig.professorThrowActionKey)
        worldNode.enumerateChildNodes(withName: "stethoscope") { node, _ in
            node.physicsBody?.velocity = .zero
        }
    }

    // MARK: - Pixel Animation (Phase 9-7 · 보존)
    /// GameScene.update가 매 프레임 호출. position 변화량으로 방향/걷기 프레임 갱신.
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
            from: PixelSprite.professorData(direction: pixelDirection, frame: pixelFrame),
            palette: PixelPalette.professorPalette
        )
    }

    // MARK: - Visual Overlay (Sprint 10 Phase F · 본문 삭제)
    // setupVisualOverlay / attachStethoscopeDisc / attachStethoscopeTube / applyVisualScaleV9
    // 본문 삭제. 원본 game.js는 16×20 픽셀 본체만 노출 — 자식 시각(disc/tube) 부착 폐기.
    // 관련 GameConfig 상수(professorStethoIconRadius/Offset/Tube*/professorVisualScaleV9)는
    // 본 Phase 변경 금지 우회 위해 보존 — 호출자 0건이 되어 자연 deprecate.
}
