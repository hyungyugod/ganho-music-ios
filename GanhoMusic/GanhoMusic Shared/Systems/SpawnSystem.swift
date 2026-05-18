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

    // MARK: - Tunable (Phase 7-1)
    /// 동시 음표 최대 수. default = GameConfig.noteMaxConcurrent → apply 누락 시 easy 동작 자연 fallback.
    var noteMaxConcurrent: Int = GameConfig.noteMaxConcurrent
    /// 음표 TTL (초). easy = .infinity → NoteNode.applyLifetime이 가드로 noop → 무한 TTL 유지.
    var noteLifetime: TimeInterval = .infinity
    /// F 동시 최대 수. default = GameConfig.projectileMaxConcurrent → easy 동작 자연 fallback.
    var projectileMaxConcurrent: Int = GameConfig.projectileMaxConcurrent
    /// F 동시 burst 발사 수. easy=1 → 기존 1발 루프와 정확 동일(회귀 0, 주의사항 4).
    var projectileBurstCount: Int = 1
    /// F 발사 주기 시작값. default = GameConfig.projectileFireInterval → easy 동작 자연 fallback.
    var projectileFireIntervalStart: TimeInterval = GameConfig.projectileFireInterval
    /// F 발사 주기 끝값. default = GameConfig.projectileFireIntervalEnd → easy 동작 자연 fallback.
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
        startProjectileFireLoop()
    }

    /// 게임 종료 시 GameScene이 호출. 모든 액션 정지 + 활성 projectile 정지.
    func stop() {
        scene?.removeAction(forKey: "spawnNotes")
        scene?.removeAction(forKey: "fireProjectiles")
        worldNode?.enumerateChildNodes(withName: "projectile") { node, _ in
            node.physicsBody?.velocity = .zero
        }
    }

    // MARK: - Note Spawn (Phase 2-3)
    /// 음표 자동 spawn 루프 시작. SKAction.repeatForever — Timer 금지.
    private func startNoteSpawnLoop() {
        let wait  = SKAction.wait(forDuration: GameConfig.noteSpawnInterval)
        let spawn = SKAction.run { [weak self] in self?.trySpawnNote() }
        let loop  = SKAction.repeatForever(.sequence([wait, spawn]))
        scene?.run(loop, withKey: "spawnNotes")
    }

    /// 한 사이클당 1회 호출. 동시 음표 수 미만일 때만 1개 spawn.
    /// Phase 7-1 — 인스턴스 프로퍼티 noteMaxConcurrent 참조 + addChild 직후 applyLifetime 호출.
    /// easy(.infinity)는 applyLifetime 가드로 noop → 기존 동작 정확 보존.
    private func trySpawnNote() {
        guard let world = worldNode else { return }
        guard currentNoteCount() < noteMaxConcurrent else { return }
        guard let position = randomNotePosition() else { return }
        let note = NoteNode()
        note.position = position
        world.addChild(note)
        note.applyLifetime(noteLifetime)
    }

    /// worldNode 안 음표 ("note" 이름) 개수.
    private func currentNoteCount() -> Int {
        guard let world = worldNode else { return 0 }
        var count = 0
        world.enumerateChildNodes(withName: "note") { _, _ in count += 1 }
        return count
    }

    /// 외곽 1tile 마진 안쪽 균등 랜덤. 중앙 기둥 manhattan 회피 (3 tile 이내면 nil).
    private func randomNotePosition() -> CGPoint? {
        let margin = GameConfig.tileSize
        let x = CGFloat.random(in: margin ... GameConfig.mapWidth  - margin)
        let y = CGFloat.random(in: margin ... GameConfig.mapHeight - margin)
        let cx = GameConfig.mapWidth  / 2
        let cy = GameConfig.mapHeight / 2
        if abs(x - cx) + abs(y - cy) < GameConfig.tileSize * 3 {
            return nil
        }
        return CGPoint(x: x, y: y)
    }

    // MARK: - Projectile Fire (Phase 2-7 + 2-9)
    /// F 발사 루프 시작 (재귀 SKAction).
    private func startProjectileFireLoop() {
        scheduleNextFire()
    }

    /// 현재 보간 주기 후 1회 발사 + 재귀로 자기 자신 다시 호출.
    /// withKey: "fireProjectiles" 동일 — stop()의 removeAction이 즉시 정지 가능.
    private func scheduleNextFire() {
        let interval = currentFireInterval()
        let wait = SKAction.wait(forDuration: interval)
        let fire = SKAction.run { [weak self] in
            self?.fireProjectile()
            self?.scheduleNextFire()
        }
        scene?.run(.sequence([wait, fire]), withKey: "fireProjectiles")
    }

    /// 현재 게임 진행률에 따른 F 발사 주기 (보간).
    /// Phase 7-1 — GameConfig 상수 → 인스턴스 프로퍼티 참조(난이도 차등). easy는 GameConfig 값과 정확 일치 → 회귀 0.
    private func currentFireInterval() -> TimeInterval {
        let progress = progressProvider()
        return projectileFireIntervalStart
            + (projectileFireIntervalEnd - projectileFireIntervalStart) * progress
    }

    /// F burstCount 만큼 발사. 각 발마다 max 가드 매 발 검사 (주의사항 4).
    /// easy=1 → 루프 1회 = 기존과 정확 동일 (회귀 0). normal=3 / hard=4.
    /// burst 안에서도 player 위치는 *한 번* 캡처 → 같은 방향 동시 발사(연사 톤).
    private func fireProjectile() {
        guard let world = worldNode else { return }
        guard let player = player else { return }
        guard let enemy = enemy else { return }
        let dx = player.position.x - enemy.position.x
        let dy = player.position.y - enemy.position.y
        let magnitude = hypot(dx, dy)
        guard magnitude > 0 else { return }
        let unitX = dx / magnitude
        let unitY = dy / magnitude

        // Phase 9-5 — 임간호 매혹 활성 시 새로 발사되는 F도 출생 즉시 enchanted.
        // SpawnSystem.start 시그니처는 *그대로* — 여기서 scene 캐스팅으로 GameScene/SkillSystem 조회.
        // weak scene이 nil이면 isCharmActive=false 자연 fallback(주의사항 2).
        let isCharmed = (scene as? GameScene)?.skillSystem.isCharmActive ?? false
        for _ in 0..<projectileBurstCount {
            // 각 발마다 max 가드 — 동시 max 초과 시 중단.
            guard currentProjectileCount() < projectileMaxConcurrent else { return }
            let projectile = ProjectileNode()
            projectile.position = enemy.position
            projectile.physicsBody?.velocity = CGVector(
                dx: unitX * GameConfig.projectileSpeed,
                dy: unitY * GameConfig.projectileSpeed
            )
            // Phase 9-5 — 매혹 활성 중 출생 시 즉시 enchanted set.
            if isCharmed {
                projectile.applyEnchanted()
            }
            world.addChild(projectile)
        }
    }

    /// worldNode 안 projectile ("projectile" 이름) 개수.
    private func currentProjectileCount() -> Int {
        guard let world = worldNode else { return 0 }
        var count = 0
        world.enumerateChildNodes(withName: "projectile") { _, _ in count += 1 }
        return count
    }

    /// Phase 4-7 — 외부 호출용. private fireProjectile()의 외부 진입점.
    /// AIRFORCE 이스터에그 수간호사 복귀 시 F 1발 즉시 발사.
    /// projectileMaxConcurrent 가드는 그대로(균형 유지).
    func fireImmediately() {
        fireProjectile()
    }
}
