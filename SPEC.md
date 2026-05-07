# Phase 2-10 — SpawnSystem 분리 (리팩터)

## 개요
GameScene에서 spawn(음표 자동 생성) + fire(F 투사체 발사) 관련 9개 메서드를 **SpawnSystem.swift** 신설 파일로 이전.
**기능 변화 0**. 순수 리팩터.

## 변경 유형
**리팩터** — 코드 구조 정리, 게임 동작 변화 0.

## 게임 경험 의도
> "GameScene이 422줄 → ~250줄로 정리. 기능은 *완전히 똑같음*.
> 향후 시스템 추가(ContactRouter 등)가 깔끔하게 들어올 토대 마련."

## Sprint 범위 계약

### 허용 (IN)
- 신설 1 파일: `Systems/SpawnSystem.swift`
- 수정 1 파일: `GanhoMusic Shared/GameScene.swift`
- pbxproj 1건: SpawnSystem.swift 등록

### 금지 (OUT)
- 기능 변화 0 — *어떤 동작도 다르면 실패*
- ContactRouter 분리 → 별도 sprint
- ScoreSystem / 콤보 분리 → 별도 sprint
- 다른 노드 파일 / Config / iOS 3 파일 / 다른 GameScene 함수 변경 0

### 판단 기준
"리팩터 후 시뮬레이터에서 *동일하게* 동작하는가?" → YES만 허용.

## 변경 범위

### 신설 파일
| 파일 | 역할 |
|---|---|
| `GanhoMusic Shared/Systems/SpawnSystem.swift` | spawn 책임 분리 — final class. weak 의존성 + closure progressProvider |

### 수정 파일
| 파일 | 변경 |
|---|---|
| `GanhoMusic Shared/GameScene.swift` | (1) 9 메서드 제거, (2) `private let spawnSystem = SpawnSystem()` 멤버, (3) `didMove`에서 `spawnSystem.start(...)` 호출 (기존 startSpawnLoop / startProjectileFireLoop 호출 자리 대체), (4) `endGame`에서 `spawnSystem.stop()` 호출 (기존 removeAction 2개 + projectile velocity 0 enumerate 대체) |

### Xcode 멤버십
**필요함.** SpawnSystem.swift 등록 (NoteNode/EnemyNode/ProjectileNode 패턴).

## 기능 상세

### 기능 1: SpawnSystem.swift 신설

```swift
//
//  SpawnSystem.swift
//  GanhoMusic Shared
//
//  Phase 2-10 · spawn(음표) + fire(F 투사체) 시스템 분리
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
}
```

### 기능 2: GameScene.swift 수정

#### 멤버 추가
```swift
// 노드 트리 섹션 다음
private let spawnSystem = SpawnSystem()   // Phase 2-10 — spawn 책임 분리
```

#### didMove 변경
```swift
// 기존 (2-9):
startSpawnLoop()                      // Phase 2-3
startProjectileFireLoop()             // Phase 2-7

// 변경 후 (2-10):
spawnSystem.start(
    scene: self,
    world: worldNode,
    player: player,
    enemy: enemy,
    progressProvider: { [weak self] in
        guard let self = self else { return 0 }
        return Double(1.0 - self.remainingTime / GameConfig.gameDuration)
    }
)
```

#### endGame 변경
```swift
// 기존 (2-9):
private func endGame() {
    gameState = .gameOver
    removeAction(forKey: "spawnNotes")
    removeAction(forKey: "fireProjectiles")
    player.currentDirection = .zero
    player.physicsBody?.velocity = .zero
    enemy.physicsBody?.velocity = .zero
    worldNode.enumerateChildNodes(withName: "projectile") { node, _ in
        node.physicsBody?.velocity = .zero
    }
    hud.update(score: score, remainingTime: 0, combo: 0)
}

// 변경 후 (2-10):
private func endGame() {
    gameState = .gameOver
    spawnSystem.stop()
    player.currentDirection = .zero
    player.physicsBody?.velocity = .zero
    enemy.physicsBody?.velocity = .zero
    hud.update(score: score, remainingTime: 0, combo: 0)
}
```

#### 9개 메서드 *제거*
다음 메서드를 GameScene.swift에서 *완전 제거* (SpawnSystem으로 이전됨):
- `startSpawnLoop()`
- `trySpawnNote()`
- `currentNoteCount()`
- `randomNotePosition()`
- `startProjectileFireLoop()`
- `scheduleNextFire()`
- `currentFireInterval()`
- `fireProjectile()`
- `currentProjectileCount()`

`// MARK: - Spawn` 섹션 자체도 제거 (또는 빈 채로 남기지 말 것).

## 준수 룰

| # | 룰 | 검증 |
|---|---|---|
| 1 | SpawnSystem.swift 신설 + final class | grep |
| 2 | weak 의존성 4개 (scene, worldNode, player, enemy) | grep |
| 3 | progressProvider closure 1건 | grep |
| 4 | 9 메서드 모두 SpawnSystem 안 (private) | grep |
| 5 | GameScene에서 9 메서드 *제거 완료* (검색 0건) | grep |
| 6 | spawnSystem.start(...) 1건 (didMove) | grep |
| 7 | spawnSystem.stop() 1건 (endGame) | grep |
| 8 | endGame에서 removeAction 직접 호출 0건 | grep |
| 9 | endGame에서 enumerateChildNodes 직접 호출 0건 | grep |
| 10 | 매직 넘버 0건 (모두 GameConfig.*) | grep |
| 11 | 강제 언래핑 / Timer / print / as! / fileprivate / DispatchQueue 0건 | grep |
| 12 | [weak self] 클로저 캡처 (재귀 fire + spawn) | grep |
| 13 | pbxproj SpawnSystem 등록 4지점 | grep |
| 14 | BUILD SUCCEEDED | xcodebuild |
| 15 | 시뮬레이터 동작 *2-9와 동일* (음표 spawn / F 발사 / endGame 정지) | 시뮬 검증 |

## 회귀 보존

| 영역 | 변경 |
|---|---|
| `Config/PhysicsCategory.swift` / `GameState.swift` / `ColorTokens.swift` / `GameConfig.swift` | 0 |
| `Nodes/HUDNode.swift` / `DPadNode.swift` / `NoteNode.swift` / `PlayerNode.swift` / `EnemyNode.swift` / `ProjectileNode.swift` | 0 |
| iOS 3 파일 | 0 |
| GameScene 의 setup 함수들 / didChangeSize / update / didBegin / handleProjectileContact / handleNoteContact | 0 (didMove + endGame만 변경) |
| HUDNode `update(score:remainingTime:combo:)` 시그니처 | 0 |
| 콤보 / 점수 / lastCollectAt / remainingTime 멤버 | 0 (모두 GameScene 그대로) |

## 기능 동등성 검증 (시뮬레이터 §15)

리팩터 전(2-9) vs 후(2-10) **완전히 같은 동작** 보장:

- (a) 음표 spawn: 1.5초 주기, 동시 5개, 중앙 기둥 회피, 외곽 1tile 마진 안쪽 — 그대로
- (b) F 발사 주기 보간: 시작 3.5초 → 끝 2.0초 — 그대로
- (c) F 발사 시점 player 좌표 캡처 — 그대로
- (d) F 동시 최대 2개 — 그대로
- (e) F가 player에 닿으면 endGame, 벽에 닿으면 소멸 — 그대로
- (f) endGame 시 spawn / fire 즉시 정지, 모든 projectile velocity 0 — 그대로
- (g) 수간호사 추적 + 속도 보간 (2-8) — 그대로
- (h) 콤보 / 점수 / HUD / 카메라 follow — 그대로

## 주의사항

- **기능 변화 0** 룰 — Generator가 *논리 변경*하면 즉시 실패.
- weak 의존성 — `scene?` `worldNode?` 등 *옵셔널 chaining* 일관 사용.
- closure progressProvider는 `@escaping` 명시 필수 (저장됨).
- pbxproj 등록 누락 시 `Cannot find type 'SpawnSystem' in scope` — 자동 등록 시도, 실패 시 SELF_CHECK 명시.
- SpawnSystem은 `Systems/` 폴더 신설. Xcode 그룹도 같이 생성.
