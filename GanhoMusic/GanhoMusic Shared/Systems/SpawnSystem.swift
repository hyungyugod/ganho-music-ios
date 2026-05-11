//
//  SpawnSystem.swift
//  GanhoMusic Shared
//
//  Phase 2-10 · spawn(음표) + fire(F 투사체) 시스템 분리
//  Phase 4-7 · 외부 호출용 fireImmediately() public wrapper 신설 (AIRFORCE 이스터에그 5/5)
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
    private func trySpawnNote() {
        guard let world = worldNode else { return }
        guard currentNoteCount() < GameConfig.noteMaxConcurrent else { return }
        guard let position = randomNotePosition() else { return }
        let note = NoteNode()
        note.position = position
        world.addChild(note)
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
    private func currentFireInterval() -> TimeInterval {
        let progress = progressProvider()
        return GameConfig.projectileFireInterval
            + (GameConfig.projectileFireIntervalEnd - GameConfig.projectileFireInterval) * progress
    }

    /// F 1개 발사. 발사 시점 player 위치 향한 단위 벡터 × projectileSpeed.
    private func fireProjectile() {
        guard let world = worldNode else { return }
        guard let player = player else { return }
        guard let enemy = enemy else { return }
        guard currentProjectileCount() < GameConfig.projectileMaxConcurrent else { return }
        let dx = player.position.x - enemy.position.x
        let dy = player.position.y - enemy.position.y
        let magnitude = hypot(dx, dy)
        guard magnitude > 0 else { return }
        let unitX = dx / magnitude
        let unitY = dy / magnitude

        let projectile = ProjectileNode()
        projectile.position = enemy.position
        projectile.physicsBody?.velocity = CGVector(
            dx: unitX * GameConfig.projectileSpeed,
            dy: unitY * GameConfig.projectileSpeed
        )
        world.addChild(projectile)
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
