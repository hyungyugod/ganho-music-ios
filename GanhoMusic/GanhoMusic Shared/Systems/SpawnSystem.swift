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

    // MARK: - Tunable (Phase 7-1 / Sprint 10 Phase I)
    /// 동시 음표 최대 수. default = GameConfig.noteMaxConcurrent → apply 누락 시 easy 동작 자연 fallback.
    var noteMaxConcurrent: Int = GameConfig.noteMaxConcurrent
    /// 음표 TTL (초). easy = .infinity → NoteNode.applyLifetime이 가드로 noop → 무한 TTL 유지.
    var noteLifetime: TimeInterval = .infinity
    /// Sprint 10 Phase I — 음표 spawn 주기 (초). default = GameConfig.noteSpawnInterval(1.5, easy)
    /// → apply 누락 시 easy 동작 자연 fallback. apply(difficulty)가 dict에서 set.
    /// startNoteSpawnLoop가 self.noteSpawnInterval 참조 → 난이도별 차등 적용.
    var noteSpawnInterval: TimeInterval = GameConfig.noteSpawnInterval

    // MARK: Dead (Phase D 이후 미사용, Sprint 10 Phase I 보류 — OQ-B)
    // 호출처: currentObstaclesTarget getter(아래)만 projectileMaxConcurrent 사용 → 보존 필수.
    // burst/fireIntervalStart/End 3개는 호출처 0이지만 즉시 삭제 X — 후속 정리 sprint에서.
    /// F 동시 최대 수. AIRFORCE 도주 종료 후 F 재시딩 목표치(currentObstaclesTarget)에서 사용 — *살아있음*.
    var projectileMaxConcurrent: Int = GameConfig.projectileMaxConcurrent
    /// F 동시 burst 발사 수. Phase D 이후 호출처 0 (EnemyNode가 GameConfig dict 직접 참조).
    var projectileBurstCount: Int = 1
    /// F 발사 주기 시작값. Phase D 이후 호출처 0.
    var projectileFireIntervalStart: TimeInterval = GameConfig.projectileFireInterval
    /// F 발사 주기 끝값. Phase D 이후 호출처 0.
    var projectileFireIntervalEnd: TimeInterval = GameConfig.projectileFireIntervalEnd

    // MARK: - Apply (Phase 7-1)
    /// 난이도 정체성 단일 진입점. GameScene.startGameProperly에서 spawnSystem.start 직전 1줄 호출.
    /// 모든 dict lookup에 fallback 필수 — 강제 언래핑 금지(주의사항 5).
    func apply(_ difficulty: Difficulty) {
        noteMaxConcurrent          = GameConfig.noteMaxConcurrentByDifficulty[difficulty]          ?? GameConfig.noteMaxConcurrent
        noteLifetime               = GameConfig.noteLifetimeByDifficulty[difficulty]               ?? .infinity
        projectileMaxConcurrent    = GameConfig.projectileMaxConcurrentByDifficulty[difficulty]    ?? GameConfig.projectileMaxConcurrent
        projectileBurstCount       = GameConfig.projectileBurstCountByDifficulty[difficulty]       ?? 1
        projectileFireIntervalStart = GameConfig.projectileFireIntervalStartByDifficulty[difficulty] ?? GameConfig.projectileFireInterval
        projectileFireIntervalEnd   = GameConfig.projectileFireIntervalEndByDifficulty[difficulty]   ?? GameConfig.projectileFireIntervalEnd
        // Sprint 10 Phase I — 음표 spawn 주기 난이도 차등 (원본 game.js L101~L105 1:1).
        // easy=1.5(기존값 = 회귀 0) / normal=0.4 / hard=0.3. fallback은 기존 단일값 noteSpawnInterval.
        noteSpawnInterval = GameConfig.noteSpawnIntervalByDifficulty[difficulty] ?? GameConfig.noteSpawnInterval
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
        worldNode?.enumerateChildNodes(withName: "projectile") { node, _ in
            node.physicsBody?.velocity = .zero
        }
        // Sprint 10 Phase D — 매혹 잔존 A 노드 정지.
        worldNode?.enumerateChildNodes(withName: "aItem") { node, _ in
            node.physicsBody?.velocity = .zero
        }
    }

    // MARK: - Note Spawn (Phase 2-3 / Sprint 10 Phase I)
    /// 음표 자동 spawn 루프 시작. SKAction.repeatForever — Timer 금지.
    /// Sprint 10 Phase I — GameConfig.noteSpawnInterval(static) → self.noteSpawnInterval(인스턴스).
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
        if noteSpawnTick % GameConfig.notePatternEverySpawn == 0,
           trySpawnNotePattern(in: world) {
            return
        }
        guard currentNoteCount() < noteMaxConcurrent else { return }
        guard let position = randomNotePosition() else { return }
        spawnNote(at: position, in: world)
    }

    /// worldNode 안 음표 ("note" 이름) 개수.
    private func currentNoteCount() -> Int {
        guard let world = worldNode else { return 0 }
        var count = 0
        world.enumerateChildNodes(withName: "note") { _, _ in count += 1 }
        return count
    }

    /// 외곽 벽과 수집 hitbox가 겹치지 않는 열린 위치. 중앙 기둥/벽 내부 후보는 제한 횟수 안에서 재시도한다.
    private func randomNotePosition() -> CGPoint? {
        return randomOpenMapPosition(halfExtent: GameConfig.spawnCollectibleHalfExtent)
    }

    private func randomOpenMapPosition(halfExtent: CGFloat) -> CGPoint? {
        let margin = GameConfig.tileSize + halfExtent
        let minX = margin
        let maxX = GameConfig.mapWidth - margin
        let minY = margin
        let maxY = GameConfig.mapHeight - margin
        guard maxX >= minX, maxY >= minY else { return nil }

        for _ in 0..<GameConfig.spawnPositionMaxAttempts {
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
        let cx = GameConfig.mapWidth / 2
        let cy = GameConfig.mapHeight / 2
        return abs(point.x - cx) + abs(point.y - cy) >= GameConfig.tileSize * 3
    }

    private func isOpenSpawnPoint(_ point: CGPoint, halfExtent: CGFloat) -> Bool {
        let margin = GameConfig.tileSize + halfExtent
        guard point.x >= margin, point.x <= GameConfig.mapWidth - margin else { return false }
        guard point.y >= margin, point.y <= GameConfig.mapHeight - margin else { return false }

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
        guard currentNoteCount() <= noteMaxConcurrent - GameConfig.notePatternSize else { return false }
        guard let origin = randomNotePosition() else { return false }
        let spacing = GameConfig.notePatternSpacing
        let rawOffsets: [CGPoint]
        switch (noteSpawnTick / GameConfig.notePatternEverySpawn) % 3 {
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
            guard isOpenSpawnPoint(position, halfExtent: GameConfig.spawnCollectibleHalfExtent) else { continue }
            spawnNote(at: position, in: world)
        }
        return true
    }

    private func spawnNote(at position: CGPoint, in world: SKNode) {
        let note = NoteNode()
        note.position = position
        world.addChild(note)
        note.applyLifetime(noteLifetime)
    }

    private func clampedNotePosition(_ point: CGPoint) -> CGPoint {
        let margin = GameConfig.tileSize + GameConfig.spawnCollectibleHalfExtent
        return CGPoint(
            x: min(max(point.x, margin), GameConfig.mapWidth - margin),
            y: min(max(point.y, margin), GameConfig.mapHeight - margin)
        )
    }

    // MARK: - Projectile Fire (Sprint 10 Phase E)
    // Phase D OQ-6 — 발사 책임이 EnemyNode 내부 텔레그래프 상태 머신으로 완전 이전.
    // dead code 5 메서드(startProjectileFireLoop / scheduleNextFire / currentFireInterval /
    //   fireProjectile / currentProjectileCount) 제거. 호출처 0.
    // stop()의 "fireProjectiles" removeAction은 유지 — noop 안전망.
    // dead 프로퍼티(projectileMaxConcurrent / projectileBurstCount / projectileFireIntervalStart /
    //   projectileFireIntervalEnd)는 Phase I로 미룸.

    /// Phase 4-7 — 외부 호출용. AIRFORCE 이스터에그 수간호사 복귀 시 F 1발 즉시 발사.
    /// Sprint 10 Phase D — 발사 책임이 EnemyNode로 이동 → enemy.fireFOnce() 1줄 위임.
    /// 텔레그래프를 우회하는 즉시 발사 — burst/F-A 분기는 EnemyNode.fireF가 단일 진실 원천.
    func fireImmediately() {
        guard let enemy = enemy else { return }
        enemy.fireFOnce()
    }

    // MARK: - Sprint 10 Phase G · F 전멸 + obstacles target getter

    /// AIRFORCE 이스터에그 폭탄 섬광 동기 호출. 화면 위 모든 F(name="projectile")를 즉시 제거.
    /// A(name="aItem", 매혹 변환)는 보존 — 원본 game.js L3419~L3447 'type==F 전부 삭제' byte-equal.
    /// SKAction.removeFromParent 사용 — didBegin/물리 콜백 진행 중 즉시 removeFromParent 회피
    /// (주의사항 1: 물리 충돌 노드 즉시 삭제 금지).
    /// FProjectileNode가 name="projectile"로 등록됨 (ContactRouter 콜백과 정합).
    /// 매혹된 F(isEnchanted=true)는 SkillSystem이 시각만 분홍으로 토글 — name="projectile" 그대로 유지.
    /// 발사 시점에 매혹 만료된 F는 AItemNode(name="aItem")로 별도 분기되어 본 enumerate에 잡히지 않음.
    func purgeAllF() {
        guard let world = worldNode else { return }
        world.enumerateChildNodes(withName: "projectile") { node, _ in
            // 다음 프레임 안전 제거 — SKAction.removeFromParent는 물리 콜백 진행 중 즉시 제거 회피.
            node.run(.removeFromParent())
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
        let wait = SKAction.wait(forDuration: GameConfig.toiletSpawnInterval)
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
        guard currentToiletCount() < GameConfig.toiletMaxConcurrent else { return }
        guard CGFloat.random(in: 0..<1) < GameConfig.toiletSpawnProbability else { return }
        guard let position = randomToiletPosition() else { return }
        let toilet = ToiletNode()
        toilet.position = position
        world.addChild(toilet)
        toilet.applyLifetime()
    }

    /// worldNode 안 변기 ("toilet" 이름) 개수.
    /// currentNoteCount / currentProjectileCount 패턴 답습 — DRY 유지.
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
        return randomOpenMapPosition(halfExtent: GameConfig.spawnCollectibleHalfExtent)
    }
}
