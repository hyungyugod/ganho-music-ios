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
    private weak var scene: SKScene?
    private weak var worldNode: SKNode?
    private weak var player: PlayerNode?
    private weak var enemy: EnemyNode?
    /// 게임 진행률 (0 ~ 1) 공급자. F 발사 주기 보간에 사용.
    private var progressProvider: () -> Double = { 0 }
    private var noteSpawnTick: Int = 0

    // MARK: - R1 Pool/Registry 배선
    /// 동적 엔티티 카운트/순회 캐시. GameScene이 configurePooling으로 주입 — weak(기존 의존성 컨벤션).
    private weak var registry: EntityRegistry?
    /// 음표 실체화 provider — 풀+레지스트리 경유(obtain→register) 클로저.
    /// 미주입 fallback은 직접 생성(풀 미경유) — 단독 사용 안전망, 본 게임 경로에선 항상 주입됨.
    private var noteProvider: () -> NoteNode = { NoteNode() }

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
    }

    // MARK: - Lifecycle
    /// 외부에서 의존성 주입 후 spawn / fire 두 루프 시작.
    func start(
        scene: SKScene,
        world: SKNode,
        player: PlayerNode,
        enemy: EnemyNode,
        progressProvider: @escaping () -> Double
    ) {
        self.scene = scene
        self.worldNode = world
        self.player = player
        self.enemy = enemy
        self.progressProvider = progressProvider
        startNoteSpawnLoop()
        // Sprint 10 Phase D — F 발사 루프 폐기. EnemyNode 내부 텔레그래프 상태 머신이 전담.
        // startProjectileFireLoop() 호출 제거 — 옛 함수 본문은 dead code(향후 정리, OQ-6).
        startToiletSpawnLoop()   // Phase 9-6 — 변기 보너스 12초/15% Bernoulli 루프
    }

    /// 게임 종료 시 GameScene이 호출. 모든 액션 정지 + 활성 projectile/aItem 정지.
    /// Sprint 10 Phase D — F 발사 루프는 폐기됐지만 EnemyNode 내부 상태 머신은 scene.isPaused로
    /// 자연 정지(SKAction wait는 isPaused면 멈춤). 안전망으로 "fireProjectiles" key 제거는 그대로 유지.
    /// aItem 노드(매혹 잔존 A)도 함께 velocity=.zero — 게임 종료 후 화면 흐름 정지.
    func stop() {
        scene?.removeAction(forKey: "spawnNotes")
        scene?.removeAction(forKey: "fireProjectiles")
        scene?.removeAction(forKey: "spawnToilets")   // Phase 9-6 — 변기 스폰 루프 정지
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

    // MARK: - Note Spawn (Phase 2-3 / Sprint 10 Phase I)
    /// 음표 자동 spawn 루프 시작. SKAction.repeatForever — Timer 금지.
    /// Sprint 10 Phase I — GameplayTuning.noteSpawnInterval(static) → self.noteSpawnInterval(인스턴스).
    /// apply(difficulty)가 set한 난이도별 dict 값을 그대로 반영 — easy=1.5(회귀 0)/normal=0.4/hard=0.3.
    private func startNoteSpawnLoop() {
        let wait  = SKAction.wait(forDuration: self.noteSpawnInterval)
        let spawn = SKAction.run { [weak self] in self?.trySpawnNote() }
        let loop  = SKAction.repeatForever(.sequence([wait, spawn]))
        scene?.run(loop, withKey: "spawnNotes")
    }

    /// 한 사이클당 1회 호출. 동시 음표 수 미만일 때만 1개 spawn.
    /// Phase 7-1 — 인스턴스 프로퍼티 noteMaxConcurrent 참조 + addChild 직후 applyLifetime 호출.
    /// easy(.infinity)는 applyLifetime 가드로 noop → 기존 동작 정확 보존.
    private func trySpawnNote() {
        guard let world = worldNode else { return }
        noteSpawnTick += 1
        if noteSpawnTick % GameplayTuning.notePatternEverySpawn == 0,
           trySpawnNotePattern(in: world) {
            return
        }
        guard currentNoteCount() < noteMaxConcurrent else { return }
        guard let position = randomNotePosition() else { return }
        spawnNote(at: position, in: world)
    }

    /// 활성 음표 수 — R1: registry 캐시 조회 (구 worldNode enumerate 카운트 대체).
    private func currentNoteCount() -> Int {
        return registry?.notes.count ?? 0
    }

    /// 외곽 벽과 수집 hitbox가 겹치지 않는 열린 위치. 중앙 기둥/벽 내부 후보는 제한 횟수 안에서 재시도한다.
    private func randomNotePosition() -> CGPoint? {
        return randomOpenMapPosition(halfExtent: GameplayTuning.spawnCollectibleHalfExtent)
    }

    private func randomOpenMapPosition(halfExtent: CGFloat) -> CGPoint? {
        let margin = GameplayTuning.tileSize + halfExtent
        let minX = margin
        let maxX = GameplayTuning.mapWidth - margin
        let minY = margin
        let maxY = GameplayTuning.mapHeight - margin
        guard maxX >= minX, maxY >= minY else { return nil }

        for _ in 0..<GameplayTuning.spawnPositionMaxAttempts {
            let point = CGPoint(
                x: CGFloat.random(in: minX ... maxX),
                y: CGFloat.random(in: minY ... maxY)
            )
            guard isAwayFromCenterPillar(point) else { continue }
            guard isOpenSpawnPoint(point, halfExtent: halfExtent) else { continue }
            return point
        }

        return nil
    }

    private func isAwayFromCenterPillar(_ point: CGPoint) -> Bool {
        let cx = GameplayTuning.mapWidth / 2
        let cy = GameplayTuning.mapHeight / 2
        return abs(point.x - cx) + abs(point.y - cy) >= GameplayTuning.tileSize * 3
    }

    private func isOpenSpawnPoint(_ point: CGPoint, halfExtent: CGFloat) -> Bool {
        let margin = GameplayTuning.tileSize + halfExtent
        guard point.x >= margin, point.x <= GameplayTuning.mapWidth - margin else { return false }
        guard point.y >= margin, point.y <= GameplayTuning.mapHeight - margin else { return false }

        for sample in spawnCollisionSamples(center: point, halfExtent: halfExtent) {
            if hasWallBody(at: sample) {
                return false
            }
        }
        return true
    }

    private func spawnCollisionSamples(center: CGPoint, halfExtent: CGFloat) -> [CGPoint] {
        return [
            center,
            CGPoint(x: center.x - halfExtent, y: center.y - halfExtent),
            CGPoint(x: center.x + halfExtent, y: center.y - halfExtent),
            CGPoint(x: center.x - halfExtent, y: center.y + halfExtent),
            CGPoint(x: center.x + halfExtent, y: center.y + halfExtent)
        ]
    }

    private func hasWallBody(at point: CGPoint) -> Bool {
        guard let scene = scene else { return false }
        if let body = scene.physicsWorld.body(at: point),
           (body.categoryBitMask & PhysicsCategory.wall) != 0 {
            return true
        }
        return false
    }

    private func trySpawnNotePattern(in world: SKNode) -> Bool {
        guard currentNoteCount() <= noteMaxConcurrent - GameplayTuning.notePatternSize else { return false }
        guard let origin = randomNotePosition() else { return false }
        let spacing = GameplayTuning.notePatternSpacing
        let rawOffsets: [CGPoint]
        switch (noteSpawnTick / GameplayTuning.notePatternEverySpawn) % 3 {
        case 0:
            rawOffsets = [-1.5, -0.5, 0.5, 1.5].map { CGPoint(x: $0 * spacing, y: 0) }
        case 1:
            rawOffsets = [-1.5, -0.5, 0.5, 1.5].map { CGPoint(x: $0 * spacing, y: $0 * spacing * 0.55) }
        default:
            rawOffsets = [
                CGPoint(x: -spacing, y: 0),
                CGPoint(x: 0, y: spacing * 0.72),
                CGPoint(x: spacing, y: 0),
                CGPoint(x: 0, y: -spacing * 0.72)
            ]
        }
        for offset in rawOffsets {
            let position = clampedNotePosition(CGPoint(x: origin.x + offset.x, y: origin.y + offset.y))
            guard isOpenSpawnPoint(position, halfExtent: GameplayTuning.spawnCollectibleHalfExtent) else { continue }
            spawnNote(at: position, in: world)
        }
        return true
    }

    /// R1 — 풀+레지스트리 경유 실체화: provider가 obtain→register, 본 시설이 addChild.
    /// TTL은 addChild 직후 매 spawn마다 재부착 — 재사용 노드도 신품과 동일 수명 정책.
    private func spawnNote(at position: CGPoint, in world: SKNode) {
        let note = noteProvider()
        note.position = position
        world.addChild(note)
        note.applyLifetime(noteLifetime)
    }

    private func clampedNotePosition(_ point: CGPoint) -> CGPoint {
        let margin = GameplayTuning.tileSize + GameplayTuning.spawnCollectibleHalfExtent
        return CGPoint(
            x: min(max(point.x, margin), GameplayTuning.mapWidth - margin),
            y: min(max(point.y, margin), GameplayTuning.mapHeight - margin)
        )
    }

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
