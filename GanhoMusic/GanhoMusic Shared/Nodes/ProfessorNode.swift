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
/// R0 — 방향+프레임 통합(updatePixelAnimation)은 PixelPositionDeltaAnimating 기본 구현 사용 (사본 제거).
final class ProfessorNode: SKSpriteNode, PixelPositionDeltaAnimating {

    // MARK: - Pixel Sprite State (Phase 9-7 · 보존)
    /// 현재 픽셀 텍스처가 표현하는 방향. SKAction.move의 진행 방향에 따라 갱신.
    var pixelDirection: PixelDirection = .down
    /// 현재 픽셀 텍스처가 표현하는 프레임. 이동 중 step1↔step2 교차, 정지 시 idle.
    var pixelFrame: PixelFrame = .idle
    /// B형(position-delta) 이동 판정 임계값 0.01 — 기존 리터럴의 상수화 (값 변경 0).
    var movementThreshold: CGFloat { GameplayTuning.pixelDirectionPositionDeltaThreshold }
    /// step1↔step2 교차 누적 시간 (초). GameplayTuning.pixelWalkFrameInterval 도달 시 토글 + 0 리셋.
    var frameAccumulator: TimeInterval = 0
    /// updatePixelAnimation에서 *이전 프레임 위치*와 비교하여 진행 방향 산출.
    var lastPosition: CGPoint = .zero
    /// lastPosition 첫 초기화 여부. 첫 update에서 자기 자신과 비교 → 거짓 정지 신호 방지.
    var hasLastPosition: Bool = false

    // MARK: - Throwing State (Phase 9-7 · 보존)
    /// 청진기 발사 루프가 사용하는 worldNode 약참조.
    private weak var worldRef: SKNode?
    /// player 위치를 매 발사 시점에 *현재 값*으로 캡처하는 클로저.
    private var targetProvider: () -> CGPoint? = { nil }
    /// 게임 진행률(0..1) 공급자. 발사 주기 보간에 사용.
    private var progressProvider: () -> Double = { 0 }
    /// 난이도별 경고 표시량. 실제 발사 주기/속도에는 관여하지 않는다.
    var warningProfile = GameplayTuning.warningProfileFallback
    private let proximityWarning = EnemyProximityWarningNode(color: .ganhoCoralPrimary)

    // MARK: - Init
    init() {
        // EnemyNode/PlayerNode 패턴 동형 — 시각은 pixelSpriteScale(2)배, physicsBody는 미부착.
        let visualSize = CGSize(
            width:  GameplayTuning.professorWidth  * GameplayTuning.pixelSpriteScale,
            height: GameplayTuning.professorHeight * GameplayTuning.pixelSpriteScale
        )
        // 출시 전 최적화 — 초기 텍스처도 캐시 경유. applyPixelTexture()와 같은 캐시를 워밍 →
        // down/idle 텍스처 단일 인스턴스 공유 (PlayerNode L101 패턴 동형).
        let initialTexture = Self.cachedTexture(direction: .down, frame: .idle)
        super.init(texture: initialTexture, color: .clear, size: visualSize)
        name = "professor"
        zPosition = 5

        // physicsBody 미부착 — *통과형* NPC. 위협은 청진기가 담당.
        addChild(proximityWarning)

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
        let wps = GameplayTuning.professorWaypoints
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
        removeAction(forKey: GameplayTuning.professorPatrolActionKey)
        position = wps[maxIndex]
        startPatrolFrom(index: maxIndex)
    }

    /// 플레이어 스폰의 점대칭(맵 중심 기준 정반대)에서 시작(요청4). 등장 직후 즉사성 피격 완화.
    /// 좌표는 점대칭점 그대로 두되, patrol은 그 점에서 최근접 waypoint부터 시작해 8자 연속성 유지.
    /// selectInitialWaypoint(farthest-first)과 병존 — setupProfessor 호출부만 이쪽으로 교체.
    func spawnOpposite(of playerPosition: CGPoint, mapSize: CGSize) {
        let wps = GameplayTuning.professorWaypoints
        guard !wps.isEmpty else { return }
        let opposite = CGPoint(
            x: mapSize.width  - playerPosition.x,
            y: mapSize.height - playerPosition.y
        )
        var minDist: CGFloat = .greatestFiniteMagnitude
        var nearestIndex = 0
        for (i, wp) in wps.enumerated() {
            let d = hypot(wp.x - opposite.x, wp.y - opposite.y)
            if d < minDist {
                minDist = d
                nearestIndex = i
            }
        }
        // 이전 패트롤 액션 정지(있다면) — 멱등 호출 안전(selectInitialWaypoint과 동일 정책).
        removeAction(forKey: GameplayTuning.professorPatrolActionKey)
        position = opposite
        startPatrolFrom(index: nearestIndex)
    }

    // MARK: - Patrol (Sprint 10 Phase F · 8자 순환)
    /// 4 waypoint 8자 무한 순환 SKAction. 시작 인덱스부터 반대로 재구성하여
    /// run하기 직전 위치는 waypoints[startIndex]에 있어야 함(selectInitialWaypoint이 보장).
    /// 좌표 순서는 GameplayTuning.professorWaypoints가 8자(figure-8) 형태로 정의 —
    /// (120,100)→(520,280)→(520,100)→(120,280) → 두 번 교차하며 한 바퀴.
    private func startPatrolFrom(index startIndex: Int) {
        let waypoints = GameplayTuning.professorWaypoints
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
            let dur  = TimeInterval(dist / GameplayTuning.professorSpeed)
            moves.append(.move(to: to, duration: dur))
        }
        let loop = SKAction.repeatForever(.sequence(moves))
        run(loop, withKey: GameplayTuning.professorPatrolActionKey)
    }

    // MARK: - Throwing
    /// 외부(GameScene+Setup.setupProfessor)가 1회 호출. 의존성 주입 후 첫 발사 스케줄.
    /// 첫 발사 전 GameplayTuning.professorInitialThrowDelay(3.0s) 대기 — 플레이어 학습 시간.
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
        let initialWait = SKAction.wait(forDuration: GameplayTuning.professorInitialThrowDelay)
        let kickoff = SKAction.run { [weak self] in
            self?.throwStethoscope()
            self?.scheduleNextThrow()
        }
        run(.sequence([initialWait, kickoff]), withKey: GameplayTuning.professorThrowActionKey)
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
        run(.sequence([wait, throwAction]), withKey: GameplayTuning.professorThrowActionKey)
    }

    /// 현재 게임 진행률에 따른 청진기 발사 주기 (보간). 시작 2.5초 → 끝 1.4초.
    private func currentThrowInterval() -> TimeInterval {
        let progress = progressProvider()
        let start = GameplayTuning.stethoscopeThrowIntervalStart
        let end   = GameplayTuning.stethoscopeThrowIntervalEnd
        return start + (end - start) * progress
    }

    /// 청진기 발사 1사이클 — 텔레그래프 0.4s 후 다발(fan) fireStethoscope.
    /// 1) worldRef nil 가드 — 발사 불가 시 자연 noop.
    /// 2) targetProvider() nil 가드 — player 위치 미공급 시 noop.
    /// 3) max concurrent 가드 — 동시 한도 초과 시 noop(텔레그래프도 부착 안 함).
    ///    한도(stethoscopeMaxConcurrent)는 fanCount 이상으로 설정돼 다발 1사이클을 막지 않는다.
    /// 4) ProfessorTelegraphNode 부착 → 다각도 경고선(fan) → 0.4s 후 fireStethoscope + 텔레그래프 제거.
    /// 단발이 아니라 플레이어 향 1개 + radial 분산 fanAngles를 한 번에 흩뿌린다(요청3).
    private func throwStethoscope() {
        guard let world = worldRef else { return }
        guard let target = targetProvider() else { return }
        guard currentStethoscopeCount(in: world) < GameplayTuning.stethoscopeMaxConcurrent else { return }
        let telegraph = ProfessorTelegraphNode()
        telegraph.position = CGPoint(x: 0, y: GameplayTuning.professorTelegraphOffsetY)
        addChild(telegraph)
        let fanAngles = stethoscopeFanAngles(towards: target)
        telegraph.attachWarningLine(
            angles: fanAngles,
            profile: warningProfile,
            originOffsetY: -GameplayTuning.professorTelegraphOffsetY
        )
        telegraph.startBlinking()
        let wait = SKAction.wait(forDuration: GameplayTuning.professorTelegraphDuration)
        let fire = SKAction.run { [weak self, weak telegraph, weak world] in
            telegraph?.removeFromParent()
            guard let self = self, let world = world else { return }
            self.fireStethoscope(angles: fanAngles, world: world)
        }
        run(.sequence([wait, fire]))
    }

    /// 다발 발사 방향 배열 산출. 0번은 플레이어 향(base) 보장 → 나머지는 spread/count 간격으로 분산.
    /// spread=2π면 base 기준 전방위 균등 radial, spread<2π면 base 중심 부채꼴(같은 코드).
    private func stethoscopeFanAngles(towards target: CGPoint) -> [CGFloat] {
        let base = atan2(target.y - position.y, target.x - position.x)
        let count = max(1, GameplayTuning.stethoscopeFanCount)
        let step = GameplayTuning.stethoscopeFanSpreadRadians / CGFloat(count)
        return (0..<count).map { base + step * CGFloat($0) }
    }

    /// 실제 청진기 다발 발사. 텔레그래프 종료 직후 호출.
    /// 각 방향마다 spawnPoint = 본체 위치 + unitVec × stethoscopeFireStartOffset — 자기 충돌로 즉시 소멸 방지.
    /// velocity = unitVec × stethoscopeSpeed. 속도/offset 수치는 단발 시절과 동일(요청3 범위 = 개수/방향만).
    private func fireStethoscope(angles: [CGFloat], world: SKNode) {
        for angle in angles {
            let unitX = cos(angle)
            let unitY = sin(angle)
            let steth = StethoscopeNode()
            steth.position = CGPoint(
                x: position.x + unitX * GameplayTuning.stethoscopeFireStartOffset,
                y: position.y + unitY * GameplayTuning.stethoscopeFireStartOffset
            )
            steth.physicsBody?.velocity = CGVector(
                dx: unitX * GameplayTuning.stethoscopeSpeed,
                dy: unitY * GameplayTuning.stethoscopeSpeed
            )
            world.addChild(steth)
        }
    }

    /// worldNode 안 청진기("stethoscope" 이름) 개수. SpawnSystem.currentProjectileCount 패턴 답습.
    private func currentStethoscopeCount(in world: SKNode) -> Int {
        var count = 0
        world.enumerateChildNodes(withName: "stethoscope") { _, _ in count += 1 }
        return count
    }

    /// 게임 종료 시 GameScene.endGame이 호출. 발사 루프 정지 + 활성 청진기 velocity 0.
    func stopThrowing(worldNode: SKNode) {
        removeAction(forKey: GameplayTuning.professorThrowActionKey)
        worldNode.enumerateChildNodes(withName: "stethoscope") { node, _ in
            node.physicsBody?.velocity = .zero
        }
    }

    // MARK: - Pixel Animation (Phase 9-7 · 보존)
    // R0 — updatePixelAnimation 본문은 PixelPositionDeltaAnimating 기본 구현이 단일 진실 원천.
    // (방향+프레임 병합 후 텍스처 갱신 1회 — needsRefresh 시맨틱 보존.)

    func updateProximityWarning(distanceToPlayer distance: CGFloat, profile: DangerWarningProfile) {
        proximityWarning.update(
            distanceToPlayer: distance,
            profile: profile,
            alphaMultiplier: profile.professorRingAlphaMultiplier
        )
    }

    /// 현재 방향/프레임 조합으로 텍스처 재생성 — (direction, frame) 정적 캐시 경유.
    /// 호출 빈도·시점·인자(pixelDirection/pixelFrame)는 전혀 변경하지 않음 — 결과 텍스처 byte-equal.
    func applyPixelTexture() {
        texture = Self.cachedTexture(direction: pixelDirection, frame: pixelFrame)
    }

    // MARK: - Texture Cache (출시 전 최적화 — PlayerNode L80-83 패턴 동형)
    /// (방향 × 프레임) SKTexture 정적 캐시. 첫 호출 시 lazy 채움 → 이후 dict lookup O(1).
    /// static — 인스턴스 재생성(재시작)에도 1회 워밍 유지. 4방향 × 3프레임 = 최대 12종.
    /// SKTexture는 GPU 텍스처라 다중 인스턴스 공유 안전(PlayerNode L82 근거).
    /// ⚠️ 클래스별 별도 캐시 — professorPalette/professorData가 다른 노드와 달라 공유 절대 금지.
    private static var textureCache: [PixelDirection: [PixelFrame: SKTexture]] = [:]

    /// 캐시 헬퍼. 미스 시 PixelSpriteRenderer로 1회 렌더 후 저장.
    /// 결과 픽셀은 직접 렌더와 byte-equal(같은 입력 → 같은 image → `.nearest` 동일).
    private static func cachedTexture(direction: PixelDirection,
                                      frame: PixelFrame) -> SKTexture {
        if let cached = textureCache[direction]?[frame] { return cached }
        let texture = PixelSpriteRenderer.texture(
            from: PixelSprite.professorData(direction: direction, frame: frame),
            palette: PixelPalette.professorPalette
        )
        if textureCache[direction] == nil { textureCache[direction] = [:] }
        textureCache[direction]?[frame] = texture
        return texture
    }

    // MARK: - Visual Overlay (Sprint 10 Phase F · 본문 삭제)
    // 원본 game.js는 16×20 픽셀 본체만 노출 — 자식 시각(disc/tube) 부착 폐기.
    // R0 — 자연 deprecate 상태였던 professorStetho* 전용 상수도 호출자 0건 확인 후 삭제 완료.
}
