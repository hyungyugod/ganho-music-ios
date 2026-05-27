//
//  EnemyNode.swift
//  GanhoMusic Shared
//
//  Phase 2-6 · 수간호사 적 NPC (직선 추적 AI + 접촉 시 게임오버)  ← 폐기 (Sprint 10 Phase D)
//  Phase 4-6 · 5초 도주 모드 (isFleeing + startFleeing)
//  Phase 7-1 · 난이도별 base/max 속도 (Sprint 10 Phase D에서 폐기 — 패트롤로 대체)
//  Phase 8-2 · 픽셀 텍스처 모드 (PlayerNode 패턴 동형)
//  Sprint 10 Phase D · 4지점 사각 순환 패트롤 + 텔레그래프 상태 머신 + F/A burst 발사 (원본 1:1)
//
//  단일 진실 원천: SPEC.md §6 + docs/ORIGINAL_GAME_ANALYSIS.md L443~L500 + game.js L2584~L2791.
//
//  변경 사항(Sprint 10 Phase D):
//   - update(deltaTime:targetPosition:speedT:) → update(deltaTime:)
//   - 직선 추적(player 향한 단위벡터 × 보간속도) → updatePatrol(4지점 사각 순환)
//   - F 발사는 SpawnSystem 외부 루프 → EnemyNode 내부 텔레그래프 상태 머신
//   - 매혹(charm) 활성 시 F 대신 AItemNode 인스턴스 생성 (발사 시점 1회 검사)
//   - baseSpeedStart/baseSpeedEnd 폐기 (인스턴스 프로퍼티 + 사용처 0건 → 함께 삭제)
//

import SpriteKit

/// 수간호사 적 NPC. Sprint 10 Phase D부터 player 추적 폐기 → 4지점 사각 순환 패트롤.
/// telegraphDuration(0.4초) 동안 머리 위 "!" 깜빡 후 burst 발사 — 매혹 시 F→A 변환.
/// PlayerNode 패턴(2-2) 정확 일치 — dynamic body, gravity/friction/damping 0.
final class EnemyNode: SKSpriteNode {

    // MARK: - State (Phase 4-6 — Flee)
    /// Phase 4-6 — 도주 모드 플래그. Sprint 10 Phase D부터 update 본체에서 직접 분기 0
    /// (패트롤 정책이 도주 톤과 분리 — startFleeing은 Phase G 결합 예정).
    /// 인터페이스만 보존 — 외부 호출(AIRFORCE 이스터에그) 사이트와의 ABI 회귀 0.
    var isFleeing: Bool = false

    // MARK: - State (Sprint 10 Phase D — Patrol + Throw)
    /// 난이도별 패트롤 4지점 (혹은 easy 2지점). apply에서 set. 빈 배열이면 정지.
    private var patrolWaypoints: [CGPoint] = []
    /// 난이도별 패트롤 속도 (pt/s). apply에서 set. default 80(easy).
    private var patrolSpeed: CGFloat = GameConfig.nurseChiefPatrolSpeedDefault
    /// 현재 향하는 waypoint 인덱스. selectInitialWaypoint가 시작 인덱스를 결정.
    private var currentWaypointIndex: Int = 0

    /// 텔레그래프 상태 머신. idle → telegraph → (firing → idle). firing은 transient 1프레임.
    private enum ThrowState { case idle, telegraph, firing }
    private var throwState: ThrowState = .idle
    /// idle 상태에서 매 프레임 dt 차감 → ≤0 도달 시 enterTelegraph.
    private var throwTimer: TimeInterval = 0
    /// telegraph 상태에서 매 프레임 dt 차감 → ≤0 도달 시 fireF + enterIdle.
    private var telegraphRemaining: TimeInterval = 0
    /// 현재 부착된 텔레그래프 노드 (있을 때만). enterIdle에서 removeFromParent.
    private weak var telegraphNode: EnemyTelegraphNode?

    // MARK: - Dependencies (Sprint 10 Phase D — GameScene+Setup이 주입)
    /// 발사 baseAngle 계산에 사용. GameScene+Setup이 [weak scene] 캡처로 주입.
    /// 미주입 시 .zero → fireF의 magnitude=0 가드로 자연 noop.
    var targetProvider: () -> CGPoint = { .zero }
    /// 발사된 F/A를 부착할 worldNode. nil이면 fireF가 early return → noop.
    var worldProvider: () -> SKNode? = { nil }
    /// 게임 진행률 (0~1) — F/A 속도 + 다음 throwTimer 보간에 사용.
    var progressProvider: () -> Double = { 0 }
    /// 발사 시점 매혹 활성 여부 검사. true면 F 대신 A 생성. 발사 시점 1회만 검사 (SPEC §5).
    var charmActiveProvider: () -> Bool = { false }

    /// 난이도별 burst 카운트. apply에서 set. easy=1, normal=3, hard=4.
    var burstCount: Int = 1
    /// F/A obs 시작 속도 (pt/s). apply에서 set.
    var obsBaseSpeed: CGFloat = 120
    /// F/A obs 끝 속도 (pt/s). apply에서 set.
    var obsMaxSpeed: CGFloat = 220
    /// 다음 발사 간격 시작값 (초). apply에서 set. enterIdle이 lerp(start, end, t)로 계산.
    var fireIntervalStart: TimeInterval = 3.5
    /// 다음 발사 간격 끝값 (초). apply에서 set.
    var fireIntervalEnd: TimeInterval = 2.0
    /// 난이도별 위험 경고 표시량. 실제 발사 수치가 아니라 시각 정보량만 제어한다.
    private var warningProfile = GameConfig.warningProfileFallback
    /// 텔레그래프 시작 시점에 확정한 실제 발사 각도. 경고선과 발사 방향 정합에 사용.
    private var pendingShotAngles: [CGFloat] = []
    private var pendingShotBaseAngle: CGFloat?
    private let proximityWarning = EnemyProximityWarningNode(color: .ganhoIngameDanger)
    private let charmAura = SKShapeNode(circleOfRadius: GameConfig.enemyDangerRingRadius)
    private let charmHeartEyes = SKNode()
    private var isCharmVisualActive = false

    // MARK: - Pixel Sprite State (Phase 8-2 · 보존)
    private var pixelDirection: PixelDirection = .down
    private var pixelFrame: PixelFrame = .idle
    private var frameAccumulator: TimeInterval = 0

    // MARK: - Init
    init() {
        let physicsSize = CGSize(
            width:  GameConfig.enemyWidth,
            height: GameConfig.enemyHeight
        )
        let visualSize = CGSize(
            width:  GameConfig.enemyWidth  * GameConfig.pixelSpriteScale,
            height: GameConfig.enemyHeight * GameConfig.pixelSpriteScale
        )
        let initialTexture = PixelSpriteRenderer.texture(
            from: PixelSprite.nurseChiefData(direction: .down, frame: .idle),
            palette: PixelPalette.chiefPalette
        )
        super.init(texture: initialTexture, color: .clear, size: visualSize)
        name = "enemy"

        // PhysicsBody 부착 — PlayerNode와 동일 정책. (Sprint 10 Phase D 회귀 0 — body 코드 0줄 변경)
        let body = SKPhysicsBody(rectangleOf: physicsSize)
        body.isDynamic           = true
        body.allowsRotation      = false
        body.friction            = 0
        body.restitution         = 0
        body.linearDamping       = 0
        body.categoryBitMask     = PhysicsCategory.enemy
        // 원본 game.js 1:1 — 수간호사는 벽 물리 반응 없음. waypoint 도달 판정이 무한 불충족되지 않도록.
        // contactTestBitMask(감지)는 절대 변경 금지 — collision(물리 반응)과 독립 비트마스크.
        body.collisionBitMask    = 0
        body.contactTestBitMask  = PhysicsCategory.player
        physicsBody = body

        zPosition = 5
        addChild(proximityWarning)
        setupCharmAura()
        setupCharmHeartEyes()

        // Sprint 10 Phase F — 자식 시각(헬로/차트/클립) 부착 폐기.
        // 원본 game.js는 16×20 픽셀 본체만 노출 — setupVisualOverlay 호출 제거.
        // Sprint 8 Phase G의 color clear / colorBlendFactor 1.0도 함께 제거 →
        // super.init(color: .clear)로 이미 투명 처리되어 본체 픽셀 텍스처가 정상 노출됨.
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Apply (Sprint 10 Phase D — 본문 교체)
    /// 난이도 정체성 단일 진입점. GameScene+Setup.setupEnemy에서 1회 호출.
    /// 패트롤 좌표/속도 + burst 카운트 + obs 속도 + 발사 간격 lerp 범위를 일괄 set.
    /// 모든 dict lookup에 fallback 필수 — 강제 언래핑 금지(주의사항 5).
    /// throwTimer는 fireIntervalStart로 초기화 — 첫 발사까지 충분한 학습 시간 제공.
    func apply(_ difficulty: Difficulty) {
        patrolWaypoints   = GameConfig.nurseChiefWaypointsByDifficulty[difficulty] ?? []
        patrolSpeed       = GameConfig.nurseChiefPatrolSpeedByDifficulty[difficulty]
            ?? GameConfig.nurseChiefPatrolSpeedDefault
        burstCount        = GameConfig.projectileBurstCountByDifficulty[difficulty] ?? 1
        obsBaseSpeed      = GameConfig.obsBaseSpeedByDifficulty[difficulty] ?? 120
        obsMaxSpeed       = GameConfig.obsMaxSpeedByDifficulty[difficulty] ?? 220
        fireIntervalStart = GameConfig.projectileFireIntervalStartByDifficulty[difficulty] ?? 3.5
        fireIntervalEnd   = GameConfig.projectileFireIntervalEndByDifficulty[difficulty] ?? 2.0
        warningProfile    = GameConfig.warningProfileByDifficulty[difficulty] ?? GameConfig.warningProfileFallback
        throwTimer = fireIntervalStart
    }

    // MARK: - Initial Waypoint (Sprint 10 Phase D)
    /// 플레이어 위치에서 가장 먼 waypoint를 시작 위치로 결정.
    /// 원본 game.js L2618~L2628 byte-equal — hypot 기반 최댓값 인덱스 탐색.
    /// GameScene+Setup.setupEnemy에서 enemy.apply 직후 1회 호출.
    func selectInitialWaypoint(from playerPosition: CGPoint) {
        guard !patrolWaypoints.isEmpty else { return }
        var maxDist: CGFloat = -1
        var maxIndex: Int = 0
        for (i, wp) in patrolWaypoints.enumerated() {
            let d = hypot(wp.x - playerPosition.x, wp.y - playerPosition.y)
            if d > maxDist {
                maxDist = d
                maxIndex = i
            }
        }
        currentWaypointIndex = maxIndex
        position = patrolWaypoints[maxIndex]
    }

    // MARK: - Flee (Phase 4-6 · Sprint 10 Phase G 본문 강화)
    /// AIRFORCE 이스터에그용 — 외부 호출 사이트(GameScene.triggerAirforceEasterEgg) ABI 회귀 0.
    /// 원본 game.js L3454~L3470 byte-equal 도주 단위벡터.
    /// 1) 단위벡터: dirX = (x >= 맵중앙 ? 1 : -1) / √2 — 맵 중앙 *반대 방향* 후퇴.
    /// 2) velocity = 단위벡터 × fleeSpeed(180 pt/s).
    /// 3) throwTimer = 99 — telegraph/firing 무력화(updateThrowStateMachine은 isFleeing 가드로 즉시 차단).
    /// 4) duration(5.0s) 후 isFleeing=false + velocity=.zero + onEnd 콜백 — F 재시딩 사이트.
    /// isFleeing 다회 진입 가드(이미 도주 중이면 noop) 그대로 유지(OQ-7).
    func startFleeing(duration: TimeInterval, onEnd: @escaping () -> Void = {}) {
        if isFleeing { return }
        let halfMapX = GameConfig.originalMapWorldWidth / 2
        let halfMapY = GameConfig.originalMapWorldHeight / 2
        let inv = 1.0 / sqrt(2.0)
        let dirX: CGFloat = (position.x >= halfMapX ? 1 : -1) * inv
        let dirY: CGFloat = (position.y >= halfMapY ? 1 : -1) * inv
        let fleeSpeed = GameConfig.enemyFleeSpeed
        let start = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.isFleeing = true
            // throwTimer 무력화 — 원본 game.js fleeUntil 동안 throwTimer=99 톤.
            self.throwTimer = 99
            self.physicsBody?.velocity = CGVector(dx: dirX * fleeSpeed, dy: dirY * fleeSpeed)
        }
        let wait = SKAction.wait(forDuration: duration)
        let end  = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.isFleeing = false
            self.physicsBody?.velocity = .zero
            // throwTimer 복원 — 도주 중 99로 무력화한 값을 fireIntervalStart로 되돌려
            // patrol/throw 정상 복귀. 진행률 lerp는 다음 enterIdle에서 갱신 — 본 시점은 학습 grace.
            // (SPEC §13 합격 기준 #3 patrol/throw 정상 복귀를 위한 필수 연동 변경.)
            self.throwTimer = self.fireIntervalStart
            onEnd()
        }
        run(.sequence([start, wait, end]))
    }

    // MARK: - Update (Sprint 10 Phase D — 시그니처 변경)
    /// 매 프레임 GameScene.update가 호출. dt 1개만 받음 (player.position/speedT는 provider 경유로 캡처).
    /// 1) updatePatrol — 4지점 사각 순환 velocity 갱신.
    /// 2) updateThrowStateMachine — idle/telegraph/firing 상태 전이.
    /// 3) updatePixelDirection + tickWalkFrame — 시각 텍스처 자기 갱신(PlayerNode 패턴 동형).
    func update(deltaTime dt: TimeInterval) {
        updateCharmVisual(isActive: charmActiveProvider())
        updatePatrol(dt: dt)
        updateThrowStateMachine(dt: dt)
        let v = physicsBody?.velocity ?? .zero
        updatePixelDirection(v)
        let isMoving = abs(v.dx) > 1.0 || abs(v.dy) > 1.0
        tickWalkFrame(deltaTime: dt, isMoving: isMoving)
    }

    func updateProximityWarning(distanceToPlayer distance: CGFloat, profile: DangerWarningProfile) {
        proximityWarning.update(distanceToPlayer: distance, profile: profile)
    }

    private func setupCharmAura() {
        charmAura.name = "charmAura"
        charmAura.zPosition = 24
        charmAura.alpha = 0
        charmAura.lineWidth = 2
        charmAura.strokeColor = GameConfig.aItemColor.withAlphaComponent(0.88)
        charmAura.fillColor = GameConfig.aItemColor.withAlphaComponent(0.12)
        addChild(charmAura)
    }

    private func setupCharmHeartEyes() {
        charmHeartEyes.name = "charmHeartEyes"
        charmHeartEyes.zPosition = 30
        charmHeartEyes.alpha = 0
        addChild(charmHeartEyes)

        let eyeY = GameConfig.enemyHeight * GameConfig.pixelSpriteScale * 0.08
        let eyeGap = GameConfig.enemyWidth * GameConfig.pixelSpriteScale * 0.18
        for x in [-eyeGap, eyeGap] {
            let heart = SKLabelNode(fontNamed: GameConfig.fontDisplay)
            heart.text = "♥"
            heart.fontSize = 16
            heart.fontColor = GameConfig.aItemColor
            heart.horizontalAlignmentMode = .center
            heart.verticalAlignmentMode = .center
            heart.position = CGPoint(x: x, y: eyeY)
            charmHeartEyes.addChild(heart)
        }
    }

    private func updateCharmVisual(isActive: Bool) {
        guard isActive != isCharmVisualActive else { return }
        isCharmVisualActive = isActive
        charmAura.removeAllActions()
        charmHeartEyes.removeAllActions()
        if isActive {
            charmAura.alpha = 1
            charmHeartEyes.alpha = 1
            let heartPulse = SKAction.sequence([
                .scale(to: 1.16, duration: 0.18),
                .scale(to: 0.96, duration: 0.18)
            ])
            let auraPulse = SKAction.sequence([
                .group([
                    .scale(to: 1.18, duration: 0.28),
                    .fadeAlpha(to: 0.52, duration: 0.28)
                ]),
                .group([
                    .scale(to: 0.96, duration: 0.28),
                    .fadeAlpha(to: 1.0, duration: 0.28)
                ])
            ])
            charmAura.run(.repeatForever(auraPulse), withKey: "charmAuraPulse")
            charmHeartEyes.run(.repeatForever(heartPulse), withKey: "charmHeartPulse")
        } else {
            charmAura.setScale(1.0)
            charmAura.run(.fadeOut(withDuration: 0.12))
            charmHeartEyes.setScale(1.0)
            charmHeartEyes.run(.fadeOut(withDuration: 0.12))
        }
    }

    // MARK: - Patrol (Sprint 10 Phase D)
    /// 현재 waypoint를 향해 patrolSpeed로 이동. 도달 시(dist <= step) snap + 다음 waypoint로 진행.
    /// 빈 배열(apply 누락) → velocity=.zero 정지 (graceful fallback).
    /// 4지점 사각 순환 — currentWaypointIndex = (idx + 1) % count → 무한 루프.
    /// Sprint 10 Phase G — isFleeing 진입 가드. AIRFORCE 이스터에그 도주 중에는 patrol velocity 덮어쓰기 0
    /// (startFleeing이 부여한 단위벡터 × fleeSpeed velocity 유지).
    private func updatePatrol(dt: TimeInterval) {
        if isFleeing { return }
        guard !patrolWaypoints.isEmpty else {
            physicsBody?.velocity = .zero
            return
        }
        let target = patrolWaypoints[currentWaypointIndex]
        let dx = target.x - position.x
        let dy = target.y - position.y
        let dist = hypot(dx, dy)
        let step = patrolSpeed * CGFloat(dt)
        if dist <= step {
            // 도달 — 정확히 snap 후 정지, 다음 waypoint 인덱스 진행.
            position = target
            physicsBody?.velocity = .zero
            currentWaypointIndex = (currentWaypointIndex + 1) % patrolWaypoints.count
        } else {
            let unitX = dx / dist
            let unitY = dy / dist
            physicsBody?.velocity = CGVector(dx: unitX * patrolSpeed, dy: unitY * patrolSpeed)
        }
    }

    // MARK: - Throw State Machine (Sprint 10 Phase D)
    /// idle: throwTimer 차감 → 0 이하 도달 시 enterTelegraph (! 부착 + 깜빡임).
    /// telegraph: telegraphRemaining 차감 → 0 이하 도달 시 fireF + enterIdle.
    /// firing: transient 1프레임 (현재 정책은 fireF 직후 즉시 enterIdle이라 도달 0건이지만 안전망).
    /// switch default 금지(주의사항) — 3 case 명시.
    /// Sprint 10 Phase G — isFleeing 진입 가드. AIRFORCE 이스터에그 도주 중에는 telegraph/firing 정지
    /// (startFleeing이 throwTimer=99로 idle 시간 무력화했고, 본 가드로 dt 차감 자체 0).
    private func updateThrowStateMachine(dt: TimeInterval) {
        if isFleeing { return }
        switch throwState {
        case .idle:
            throwTimer -= dt
            if throwTimer <= 0 {
                enterTelegraph()
            }
        case .telegraph:
            telegraphRemaining -= dt
            if telegraphRemaining <= 0 {
                fireF()
                enterIdle()
            }
        case .firing:
            enterIdle()
        }
    }

    /// idle → telegraph 전이. EnemyTelegraphNode 부착 + 깜빡임 시작.
    /// telegraphRemaining을 GameConfig 상수로 초기화 (0.4초).
    private func enterTelegraph() {
        throwState = .telegraph
        telegraphRemaining = GameConfig.nurseChiefTelegraphDuration
        let shotPlan = makeShotPlan()
        pendingShotBaseAngle = shotPlan.baseAngle
        pendingShotAngles = shotPlan.angles
        let node = EnemyTelegraphNode()
        node.position = CGPoint(x: 0, y: GameConfig.nurseChiefTelegraphOffsetY)
        addChild(node)
        telegraphNode = node
        node.attachWarningLines(
            angles: visibleWarningAngles(from: pendingShotAngles),
            profile: warningProfile,
            originOffsetY: -GameConfig.nurseChiefTelegraphOffsetY
        )
        node.startBlinking()
    }

    /// telegraph/firing → idle 전이. 텔레그래프 노드 제거 + 다음 throwTimer lerp 계산.
    /// progressProvider() 호출 — 게임 진행률 ↑ 시 throwTimer ↓ (긴박감 증가).
    private func enterIdle() {
        throwState = .idle
        telegraphNode?.removeFromParent()
        telegraphNode = nil
        let t = progressProvider()
        throwTimer = fireIntervalStart + (fireIntervalEnd - fireIntervalStart) * t
    }

    // MARK: - Fire (Sprint 10 Phase D · 원본 1:1 burst)
    /// burst 카운트만큼 F(또는 A) 동시 발사. 원본 game.js L2746~L2791 byte-equal 알고리즘.
    /// 1) baseAngle = atan2(player - chief) — provider 경유.
    /// 2) spreadStep = π/12, jitter = ±0.025 — 각 발마다 미세한 각도 변화.
    /// 3) spawnPoint = chief.position + unitVec(baseAngle) × 24pt (분산 시작점 1점 공통).
    /// 4) speed = obsBase + (obsMax - obsBase) × curveT() — 진행률 ↑ 시 속도 ↑.
    /// 5) isCharmed ? AItemNode : FProjectileNode — 발사 시점 1회 검사(SPEC §5).
    private func fireF() {
        guard let world = worldProvider() else { return }
        let shotPlan: (baseAngle: CGFloat, angles: [CGFloat])
        if let baseAngle = pendingShotBaseAngle, !pendingShotAngles.isEmpty {
            shotPlan = (baseAngle, pendingShotAngles)
        } else {
            shotPlan = makeShotPlan()
        }
        guard !shotPlan.angles.isEmpty else { return }
        let isCharmed = charmActiveProvider()
        let t = progressProvider()
        let speed = obsBaseSpeed + (obsMaxSpeed - obsBaseSpeed) * CGFloat(t)
        let startOffset = GameConfig.nurseChiefFireStartOffset
        let spawnPoint = CGPoint(
            x: position.x + cos(shotPlan.baseAngle) * startOffset,
            y: position.y + sin(shotPlan.baseAngle) * startOffset
        )

        for finalAngle in shotPlan.angles {
            let unitX = cos(finalAngle)
            let unitY = sin(finalAngle)
            let velocity = CGVector(dx: unitX * speed, dy: unitY * speed)
            if isCharmed {
                let a = AItemNode()
                a.position = spawnPoint
                a.physicsBody?.velocity = velocity
                world.addChild(a)
            } else {
                let f = FProjectileNode()
                f.position = spawnPoint
                f.physicsBody?.velocity = velocity
                world.addChild(f)
            }
        }
        pendingShotAngles.removeAll()
        pendingShotBaseAngle = nil
    }

    private func makeShotPlan() -> (baseAngle: CGFloat, angles: [CGFloat]) {
        let playerPos = targetProvider()
        let dx = playerPos.x - position.x
        let dy = playerPos.y - position.y
        let magnitude = hypot(dx, dy)
        guard magnitude > 0 else { return (0, []) }
        let baseAngle = atan2(dy, dx)
        let spreadStep = GameConfig.nurseChiefSpreadRadians
        var angles: [CGFloat] = []
        for i in 0..<burstCount {
            let centerOffset = CGFloat(i) - CGFloat(burstCount - 1) / 2.0
            let angle = baseAngle + centerOffset * spreadStep
            let jitter = CGFloat.random(
                in: -GameConfig.nurseChiefSpreadJitter ... GameConfig.nurseChiefSpreadJitter
            )
            angles.append(angle + jitter)
        }
        return (baseAngle, angles)
    }

    private func visibleWarningAngles(from angles: [CGFloat]) -> [CGFloat] {
        guard !warningProfile.showAllBurstLines, angles.count > 3 else { return angles }
        guard let first = angles.first, let last = angles.last else { return angles }
        let middle = angles[angles.count / 2]
        return [first, middle, last]
    }

    /// SpawnSystem.fireImmediately 호환 — 텔레그래프 우회 즉시 발사.
    /// AIRFORCE 이스터에그 수간호사 복귀 직후 1발 발사(레거시 동작 보존).
    /// 본문은 fireF() 한 줄 위임 — burst/F-A 분기 단일 진실 원천 유지.
    func fireFOnce() {
        fireF()
    }

    // MARK: - Pixel Sprite (Phase 8-2 · 보존)
    /// velocity 부호로 4방향 산출. 정지(임계값 미만) 시 마지막 방향 유지.
    /// PlayerNode.updatePixelDirection과 정확히 동일 패턴.
    private func updatePixelDirection(_ velocity: CGVector) {
        let absDx = abs(velocity.dx)
        let absDy = abs(velocity.dy)
        guard absDx > 0.1 || absDy > 0.1 else { return }
        let newDir: PixelDirection
        if absDx > absDy {
            newDir = velocity.dx >= 0 ? .right : .left
        } else {
            newDir = velocity.dy >= 0 ? .up : .down
        }
        if newDir != pixelDirection {
            pixelDirection = newDir
            refreshTexture()
        }
    }

    /// 걷는 중일 때 step1↔step2 교차, 정지 시 idle.
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

    /// 현재 방향/프레임 조합으로 텍스처 재생성.
    private func refreshTexture() {
        texture = PixelSpriteRenderer.texture(
            from: PixelSprite.nurseChiefData(direction: pixelDirection,
                                              frame: pixelFrame),
            palette: PixelPalette.chiefPalette
        )
    }

    // MARK: - Visual Overlay (Sprint 10 Phase F — 본문 삭제)
    // setupVisualOverlay / attachHalo / attachChart / attachClip / applyVisualScaleV9 5개 메서드
    // 본문 삭제. 원본 game.js는 16×20 픽셀 본체만 노출 — 자식 시각(헬로/차트/클립) 부착 정책 폐기.
    // GameConfig.enemyVisualHaloWidth/Height/Alpha/ChartSize/ChartOffset/enemyVisualScaleV9 상수도
    // 호출자 0건이 되었으나 본 Phase 변경 금지 우회 위해 GameConfig 본체 보존 — deprecate 주석 형태로 처리.
}
