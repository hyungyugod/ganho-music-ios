//
//  SpawnSystem.swift
//  GanhoMusic Shared
//
//  Phase 2-10 · spawn(음표) + fire(F 투사체) 시스템 분리
//  Phase 4-7 · 외부 호출용 fireImmediately() public wrapper 신설 (AIRFORCE 이스터에그 5/5)
//  Phase 7-1 · 난이도별 인스턴스 프로퍼티 외부화 (noteMaxConcurrent/noteLifetime/projectileMax/burstCount/fireInterval start/end)
//             + apply(_:Difficulty) + fireProjectile burst 루프 (easy=1 → 회귀 0)
//

import SpriteKit

/// 음표 자동 spawn + F 투사체 발사 책임을 GameScene에서 분리한 시스템.
/// GameScene으로부터 의존성(scene/world/player/enemy/progressProvider)을 주입받아 동작.
/// 모든 외부 참조는 weak — 메모리 누수 방지.
final class SpawnSystem {

    // MARK: - Dependencies (weak)
    // R8 분할 — scene/worldNode/progressProvider/comboProvider/noteSpawnTick은 +Notes
    // (음표 스폰 체인)가 소비: private → internal (이동 필수분). player/enemy는 본체 전용 유지.
    weak var scene: SKScene?
    weak var worldNode: SKNode?
    private weak var player: PlayerNode?
    private weak var enemy: EnemyNode?
    /// 게임 진행률 (0 ~ 1) 공급자. F 발사 주기 보간 + R7 중반 피크(25s) 판정에 사용.
    var progressProvider: () -> Double = { 0 }
    /// R7 §F4 — 현재 콤보 공급자. 리스크 가속(combo ≥ 7 동안 스폰 간격 ×0.85) 판정 전용.
    /// progressProvider 동형 — GameScene이 [weak self] 클로저 주입. 미주입 0 = 가속 없음 (안전).
    var comboProvider: () -> Int = { 0 }
    var noteSpawnTick: Int = 0

    // MARK: - R1 Pool/Registry 배선
    /// 동적 엔티티 카운트/순회 캐시. GameScene이 configurePooling으로 주입 — weak(기존 의존성 컨벤션).
    /// R8 분할 — +Notes(currentNoteCount)가 소비: private → internal (이동 필수분).
    weak var registry: EntityRegistry?
    /// 음표 실체화 provider — 풀+레지스트리 경유(obtain→register) 클로저.
    /// 미주입 fallback은 직접 생성(풀 미경유) — 단독 사용 안전망, 본 게임 경로에선 항상 주입됨.
    /// R8 분할 — +Notes(spawnNote)가 소비: private → internal (이동 필수분).
    var noteProvider: () -> NoteNode = { NoteNode() }

    /// R1 — 풀·레지스트리 배선 단일 진입점. GameScene didMove(setupEntityPools)에서 1회 호출.
    func configurePooling(registry: EntityRegistry, noteProvider: @escaping () -> NoteNode) {
        self.registry = registry
        self.noteProvider = noteProvider
    }

    // MARK: - Tunable (Phase 7-1 / Sprint 10 Phase I)
    /// 동시 음표 최대 수. default = GameplayTuning.noteMaxConcurrent → apply 누락 시 easy 동작 자연 fallback.
    var noteMaxConcurrent: Int = GameplayTuning.noteMaxConcurrent
    /// 음표 TTL (초). easy = .infinity → NoteNode.applyLifetime이 가드로 noop → 무한 TTL 유지.
    var noteLifetime: TimeInterval = .infinity
    /// Sprint 10 Phase I — 음표 spawn 주기 (초). default = GameplayTuning.noteSpawnInterval(1.5, easy)
    /// → apply 누락 시 easy 동작 자연 fallback. apply(difficulty)가 dict에서 set.
    /// startNoteSpawnLoop가 self.noteSpawnInterval 참조 → 난이도별 차등 적용.
    var noteSpawnInterval: TimeInterval = GameplayTuning.noteSpawnInterval

    /// F 동시 최대 수. AIRFORCE 도주 종료 후 F 재시딩 목표치(currentObstaclesTarget)에서 사용 — *살아있음*.
    /// R0 — dead 3종(burst/fireIntervalStart/End)은 호출처 0 확인 후 삭제. 발사 책임은 EnemyNode가 전담.
    var projectileMaxConcurrent: Int = GameplayTuning.projectileMaxConcurrent

    // MARK: - R6 일일 모디파이어 (§F7 — 음표 러시·황금 변기 훅)
    /// 이번 판 모디파이어. nil = 일반 판(기존 동작 byte-동일). apply() 이전 1회 set —
    /// GameScene.setupDailyModifier가 didMove에서 주입 (startGameProperly의 apply가 소비).
    private var dailyModifier: DailyModifier?

    /// 모디파이어 주입 단일 진입점. apply(difficulty)보다 먼저 호출돼야 한다 (didMove ≺ countdown 종료).
    func configureDailyModifier(_ modifier: DailyModifier?) {
        self.dailyModifier = modifier
    }

    // MARK: - Apply (Phase 7-1)
    /// 난이도 정체성 단일 진입점. GameScene.startGameProperly에서 spawnSystem.start 직전 1줄 호출.
    /// 모든 dict lookup에 fallback 필수 — 강제 언래핑 금지(주의사항 5).
    func apply(_ difficulty: Difficulty) {
        noteMaxConcurrent          = GameplayTuning.noteMaxConcurrentByDifficulty[difficulty]          ?? GameplayTuning.noteMaxConcurrent
        noteLifetime               = GameplayTuning.noteLifetimeByDifficulty[difficulty]               ?? .infinity
        projectileMaxConcurrent    = GameplayTuning.projectileMaxConcurrentByDifficulty[difficulty]    ?? GameplayTuning.projectileMaxConcurrent
        // Sprint 10 Phase I — 음표 spawn 주기 난이도 차등 (원본 game.js L101~L105 1:1).
        // easy=1.5(기존값 = 회귀 0) / normal=0.4 / hard=0.3. fallback은 기존 단일값 noteSpawnInterval.
        noteSpawnInterval = GameplayTuning.noteSpawnIntervalByDifficulty[difficulty] ?? GameplayTuning.noteSpawnInterval
        // R6 §F7 음표 러시 — 스폰 간격 ÷1.5 (단일 적용 지점: 난이도 값 확정 직후 배율 1회).
        if dailyModifier == .noteRush {
            noteSpawnInterval = noteSpawnInterval / MetaTuning.noteRushSpawnIntervalDivisor
        }
    }

    // MARK: - Lifecycle
    /// 외부에서 의존성 주입 후 spawn / fire 두 루프 시작.
    /// R7 §F4 — comboProvider 추가 (기본 { 0 } = 가속 없음 — 미주입 호출부 행동 불변).
    func start(
        scene: SKScene,
        world: SKNode,
        player: PlayerNode,
        enemy: EnemyNode,
        progressProvider: @escaping () -> Double,
        comboProvider: @escaping () -> Int = { 0 }
    ) {
        self.scene = scene
        self.worldNode = world
        self.player = player
        self.enemy = enemy
        self.progressProvider = progressProvider
        self.comboProvider = comboProvider
        startNoteSpawnLoop()
        // Sprint 10 Phase D — F 발사 루프 폐기. EnemyNode 내부 텔레그래프 상태 머신이 전담.
        // startProjectileFireLoop() 호출 제거 — 옛 함수 본문은 dead code(향후 정리, OQ-6).
        startToiletSpawnLoop()   // Phase 9-6 — 변기 보너스 12초/15% Bernoulli 루프
        // R6 §F7 황금 변기 — 스폰 기대치 +1: 확정 1회 추가 스폰 (기존 Bernoulli 루프 무변경).
        // 확률 미세조정 대신 결정적 +1 — 황금 변기 날에 변기 0개인 빈 체험 방지 (MetaTuning 주석).
        if dailyModifier == .goldenToilet {
            scheduleGuaranteedToiletSpawn()
        }
    }

    /// 게임 종료 시 GameScene이 호출. 모든 액션 정지 + 활성 projectile/aItem 정지.
    /// Sprint 10 Phase D — F 발사 루프는 폐기됐지만 EnemyNode 내부 상태 머신은 scene.isPaused로
    /// 자연 정지(SKAction wait는 isPaused면 멈춤). 안전망으로 "fireProjectiles" key 제거는 그대로 유지.
    /// aItem 노드(매혹 잔존 A)도 함께 velocity=.zero — 게임 종료 후 화면 흐름 정지.
    func stop() {
        scene?.removeAction(forKey: "spawnNotes")
        scene?.removeAction(forKey: "fireProjectiles")
        scene?.removeAction(forKey: "spawnToilets")   // Phase 9-6 — 변기 스폰 루프 정지
        scene?.removeAction(forKey: "spawnGoldenToilet")   // R6 — 황금 변기 확정 스폰 정지
        // R1 — 활성 F 정지: 구 name="projectile" enumerate → registry 배열 순회 (동일 대상).
        if let registry = registry {
            for projectile in registry.projectiles {
                projectile.physicsBody?.velocity = .zero
            }
        }
        // Sprint 10 Phase D — 매혹 잔존 A 노드 정지. (aItem은 registry 비대상 — 저빈도
        // 이벤트 경로라 enumerate 유지 허용, R1 SPEC 명시.)
        worldNode?.enumerateChildNodes(withName: "aItem") { node, _ in
            node.physicsBody?.velocity = .zero
        }
    }

    // R8 §B③ — Note Spawn 섹션(자기 재예약 체인·실효 캡·패턴·열린 위치 산출)은
    // Systems/SpawnSystem+Notes.swift로 분리 (코드 이동만 — 로직 0 변경).

    // MARK: - Projectile Fire (Sprint 10 Phase E)
    // Phase D OQ-6 — 발사 책임이 EnemyNode 내부 텔레그래프 상태 머신으로 완전 이전.
    // stop()의 "fireProjectiles" removeAction은 유지 — noop 안전망.
    // R0 — dead 프로퍼티 3종(burst/fireIntervalStart/End) 삭제 완료. projectileMaxConcurrent만 생존.

    /// Phase 4-7 — 외부 호출용. AIRFORCE 이스터에그 수간호사 복귀 시 F 1발 즉시 발사.
    /// Sprint 10 Phase D — 발사 책임이 EnemyNode로 이동 → enemy.fireFOnce() 1줄 위임.
    /// 텔레그래프를 우회하는 즉시 발사 — burst/F-A 분기는 EnemyNode.fireF가 단일 진실 원천.
    func fireImmediately() {
        guard let enemy = enemy else { return }
        enemy.fireFOnce()
    }

    // MARK: - Sprint 10 Phase G · F 전멸 + obstacles target getter

    /// AIRFORCE 이스터에그 폭탄 섬광 동기 호출. 화면 위 모든 F를 지연 회수.
    /// A(매혹 변환 AItemNode)는 보존 — 원본 game.js L3419~L3447 'type==F 전부 삭제' byte-equal.
    /// R1 — 구 name="projectile" enumerate → registry.projectiles *스냅샷* 순회 (순회 중 회수로
    /// 배열이 변형돼도 안전). 매혹된 F는 FProjectileNode 타입 그대로라 registry에 있어 동일 포함,
    /// AItemNode는 별도 타입이라 자연 비포함 — 구 enumerate와 대상 동일.
    /// 지연 회수(.wait 0) — didBegin/물리 콜백 진행 중 즉시 removeFromParent 회피 규칙을 회수에도 적용.
    func purgeAllF() {
        guard let registry = registry else { return }
        let snapshot = registry.projectiles
        for projectile in snapshot {
            let recycle = SKAction.run { [weak projectile] in projectile?.requestRecycle() }
            projectile.run(.sequence([.wait(forDuration: 0), recycle]))
        }
    }

    /// AIRFORCE 이스터에그 도주 종료 시 F 재시딩 목표치. 원본 game.js L2678~L2687
    /// `Math.round(obstacles × 1.0) - 현재 F` byte-equal — iOS는 difficulty별 projectileMaxConcurrent 사용.
    /// (SpawnSystem.apply에서 set된 인스턴스 프로퍼티 그대로 노출.)
    /// 호출부: GameScene.triggerAirforceEasterEgg onEnd 콜백 — 목표치 - 현재 F = deficit만큼 fireImmediately.
    var currentObstaclesTarget: Int {
        return projectileMaxConcurrent
    }

    // MARK: - Toilet Spawn (Phase 9-6)
    /// 변기 보너스 자동 스폰 루프 시작. SKAction.repeatForever — Timer 금지.
    /// 매 12초 사이클마다 1회 확률 판정(Bernoulli). 첫 12초는 wait → 변기 0개 (의도된 톤).
    /// 게임 일시정지(scene.isPaused=true) 시 SKAction 자체 멈춤 → 자연 차단.
    private func startToiletSpawnLoop() {
        let wait = SKAction.wait(forDuration: GameplayTuning.toiletSpawnInterval)
        let roll = SKAction.run { [weak self] in self?.tryRollAndSpawnToilet() }
        let loop = SKAction.repeatForever(.sequence([wait, roll]))
        scene?.run(loop, withKey: "spawnToilets")
    }

    /// 한 사이클당 1회 호출.
    /// 1) 단일성 가드: 화면에 변기 1개 이미 존재 시 *확률 판정 전*에 차단.
    ///    (체감 확률 정확 유지 — 확률 판정 후 단일성 차단하면 *놓친 기회* 발생.)
    /// 2) Bernoulli 단일 시도 — 확률 누적 없음.
    /// 3) 위치 산출(중앙 기둥 회피) 실패 시 noop (다음 사이클 재시도).
    private func tryRollAndSpawnToilet() {
        guard let world = worldNode else { return }
        guard currentToiletCount() < GameplayTuning.toiletMaxConcurrent else { return }
        guard CGFloat.random(in: 0..<1) < GameplayTuning.toiletSpawnProbability else { return }
        guard let position = randomToiletPosition() else { return }
        let toilet = ToiletNode()
        toilet.position = position
        world.addChild(toilet)
        toilet.applyLifetime()
    }

    /// R6 §F7 황금 변기 — 확정 1회 스폰 예약. SKAction.wait 경유 (Timer 금지).
    /// 단일성 가드·위치 산출은 일반 스폰과 동일 — 확률 판정만 건너뛴다 (기대치 정확 +1).
    private func scheduleGuaranteedToiletSpawn() {
        let wait = SKAction.wait(forDuration: MetaTuning.goldenToiletGuaranteedSpawnDelay)
        let spawn = SKAction.run { [weak self] in
            guard let self = self, let world = self.worldNode else { return }
            guard self.currentToiletCount() < GameplayTuning.toiletMaxConcurrent else { return }
            guard let position = self.randomToiletPosition() else { return }
            let toilet = ToiletNode()
            toilet.position = position
            world.addChild(toilet)
            toilet.applyLifetime()
        }
        // 기존 "spawnToilets" 루프와 별개 키 — stop()이 함께 제거 (아래 stop 참조).
        scene?.run(.sequence([wait, spawn]), withKey: "spawnGoldenToilet")
    }

    /// worldNode 안 변기 ("toilet" 이름) 개수.
    /// toilet은 registry 비대상(저빈도 12초 주기 경로) — enumerate 유지 허용(R1 SPEC 명시).
    private func currentToiletCount() -> Int {
        guard let world = worldNode else { return 0 }
        var count = 0
        world.enumerateChildNodes(withName: "toilet") { _, _ in count += 1 }
        return count
    }

    /// 변기 스폰 위치 — 외곽벽 1타일 + 수집 hitbox half extent margin을 두고
    /// 중심+네 모서리 wall 검사까지 통과한 randomNotePosition 정책을 재사용한다.
    /// nil 반환 시 호출부(`tryRollAndSpawnToilet`)가 noop → 다음 사이클 재시도.
    private func randomToiletPosition() -> CGPoint? {
        return randomOpenMapPosition(halfExtent: GameplayTuning.spawnCollectibleHalfExtent)
    }
}
