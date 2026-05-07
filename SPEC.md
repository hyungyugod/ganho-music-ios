# Phase 2-9 — F 발사 주기 시간 보간 (3.5초 → 2.0초 선형)

## 개요
F 발사 주기가 *3.5초(시작)에서 2.0초(끝)으로 선형 감소*.
구현: SKAction.repeatForever를 *재귀 SKAction*으로 교체. 매 발사 후 다음 wait duration을 *현재 진행률 기반*으로 동적 계산.

## 변경 유형
**게임플레이** — 시간 압박 강화 (속도 + 주기 둘 다 빨라짐).

## 게임 경험 의도
> "F 발사 주기가 점점 짧아짐. 시작 3.5초마다 → 끝 2초마다.
> 수간호사 속도(2-8)와 함께 게임이 *후반 가속*. 끝까지 버티면 진짜 성취감."

## Sprint 범위 계약

### 허용 (IN)
- 수정 2 파일:
  - `Config/GameConfig.swift` — `projectileFireIntervalEnd: TimeInterval = 2.0` 1상수 + 기존 `projectileFireInterval` 주석 갱신
  - `GanhoMusic Shared/GameScene.swift` — `startProjectileFireLoop` 본문 교체 + `scheduleNextFire` / `currentFireInterval` 헬퍼 신설

### 금지 (OUT)
- F 동시 수 변화 (2 → 3 → 4) → Phase 4 (normal/hard 난이도)
- 청진기 (이교수) → Phase 4
- 무적 시간 → Phase 5
- F 사운드 / 시각 효과 → Phase 6
- Systems 폴더 분리 → 별도 sprint
- player 속도 보간 → Phase 5+
- enemy 속도 보간 (이미 2-8) → 변경 0

## 변경 범위

### 수정할 파일

| 파일 | 변경 |
|---|---|
| `Config/GameConfig.swift` | (1) 기존 `projectileFireInterval = 3.5` 주석에 *시작값* 명시 (Phase 2-9에서 보간 시작값으로 사용), (2) `projectileFireIntervalEnd: TimeInterval = 2.0` 1줄 추가 |
| `GanhoMusic Shared/GameScene.swift` | (1) `startProjectileFireLoop` 본문을 `scheduleNextFire()` 단일 호출로 교체, (2) `scheduleNextFire()` 신설 — wait + run 시퀀스 등록, run 클로저 안에서 fireProjectile + 재귀 호출, (3) `currentFireInterval()` 신설 — 보간 계산. `fireProjectile` / `currentProjectileCount` 본체는 *그대로*. `endGame`의 `removeAction(forKey: "fireProjectiles")` 호출은 그대로 유효 (재귀 패턴도 같은 키 사용) |

### 추가할 파일
**없음.**

### Xcode 멤버십
**필요 없음** (신설 파일 0).

## 기능 상세

### 기능 1: GameConfig — `projectileFireIntervalEnd` 추가
```swift
// 기존 주석 갱신:
/// F 발사 주기 시작값 (초). GDD §5 easy 시작값. Phase 2-9에서 IntervalEnd(2.0)까지 선형 보간.
static let projectileFireInterval: TimeInterval = 3.5
/// F 발사 주기 끝값 (초). 게임 종료 시점 도달값. GDD §5 easy.
/// Phase 2-9 — 시간 보간으로 projectileFireInterval(3.5)에서 이 값(2.0)까지 선형 감소.
static let projectileFireIntervalEnd: TimeInterval = 2.0
```
- 위치: `projectileFireInterval` 정의 *바로 다음 줄*. 기존 `projectileMaxConcurrent` 위.
- 기존 상수 *값* 변경 0 (주석만 갱신).

### 기능 2: GameScene — `startProjectileFireLoop` 본문 교체
```swift
// 기존 (2-7)
private func startProjectileFireLoop() {
    let wait = SKAction.wait(forDuration: GameConfig.projectileFireInterval)
    let fire = SKAction.run { [weak self] in self?.fireProjectile() }
    let loop = SKAction.repeatForever(.sequence([wait, fire]))
    self.run(loop, withKey: "fireProjectiles")
}

// 변경 후 (2-9)
private func startProjectileFireLoop() {
    scheduleNextFire()
}
```
- 함수 시그니처 / 호출 위치 (`didMove`에서) 변경 0.
- 본문이 단순화 — *재귀 시작*만 트리거.

### 기능 3: GameScene — `scheduleNextFire` 신설
```swift
/// F 발사를 *현재 보간 주기* 후에 1회 실행하고, 끝나면 자기 자신을 다시 호출 (재귀).
/// `repeatForever` 대신 재귀를 쓰는 이유: 매 발사마다 *다음 wait 시간*이 다름 (보간).
/// withKey: "fireProjectiles" 동일 — endGame의 removeAction이 즉시 정지 가능.
private func scheduleNextFire() {
    let interval = currentFireInterval()
    let wait = SKAction.wait(forDuration: interval)
    let fire = SKAction.run { [weak self] in
        self?.fireProjectile()
        self?.scheduleNextFire()
    }
    self.run(.sequence([wait, fire]), withKey: "fireProjectiles")
}
```
- `[weak self]` 캡처로 메모리 누수 방어.
- self가 nil이면 fireProjectile + 재귀 호출 모두 스킵 (안전).
- withKey 동일 → endGame의 `removeAction(forKey: "fireProjectiles")`가 *현재 등록된 시퀀스*를 정지. 재귀 클로저는 *액션 끝나야* 호출되니 정지 후엔 추가 호출 없음.

### 기능 4: GameScene — `currentFireInterval` 신설
```swift
/// 현재 게임 진행률에 따른 F 발사 주기 (보간).
/// 진행률 0 (시작) → projectileFireInterval (3.5초)
/// 진행률 1 (종료) → projectileFireIntervalEnd (2.0초)
private func currentFireInterval() -> TimeInterval {
    let progress = 1.0 - remainingTime / GameConfig.gameDuration
    return GameConfig.projectileFireInterval
        + (GameConfig.projectileFireIntervalEnd - GameConfig.projectileFireInterval) * progress
}
```
- 보간 패턴은 EnemyNode.update의 speed 보간과 *동일*.
- 끝값(2.0)이 시작값(3.5)보다 작아 *감소* — 보간 부호 자동 처리.
- `remainingTime`은 GameScene 멤버 — 직접 접근.

## 준수 룰

| # | 룰 | 검증 |
|---|---|---|
| 1 | `projectileFireIntervalEnd` 1상수 정의 | grep |
| 2 | `scheduleNextFire` 함수 정의 1건 + 호출 ≥ 2건 (startProjectileFireLoop + 자기 자신 재귀) | grep |
| 3 | `currentFireInterval` 함수 정의 1건 + 호출 1건 (scheduleNextFire 안) | grep |
| 4 | 재귀 클로저 `[weak self]` 캡처 | grep |
| 5 | 재귀 클로저 안 `self?.fireProjectile()` + `self?.scheduleNextFire()` 2 줄 | grep |
| 6 | withKey "fireProjectiles" 1건 (scheduleNextFire 안) | grep |
| 7 | 매직 넘버 0건 (3.5/2.0/45 모두 GameConfig.*) | grep |
| 8 | `SKAction.repeatForever`가 *fireProjectile 영역*에서 0건 (spawn은 그대로) | grep |
| 9 | 강제 언래핑 / Timer / print / as! / fileprivate 0건 | grep |
| 10 | endGame의 `removeAction(forKey: "fireProjectiles")` 보존 | diff |
| 11 | `fireProjectile` / `currentProjectileCount` 본체 변경 0 | diff |
| 12 | BUILD SUCCEEDED | xcodebuild |

## 회귀 보존

| 영역 | 변경 |
|---|---|
| `Config/PhysicsCategory.swift` / `GameState.swift` / `ColorTokens.swift` | 0 |
| `Nodes/HUDNode.swift` / `DPadNode.swift` / `NoteNode.swift` / `PlayerNode.swift` / `EnemyNode.swift` / `ProjectileNode.swift` | 0 |
| iOS 3 파일 / pbxproj | 0 |
| GameScene 다른 함수 (setupBackground / setupWorld / setupPlayer / setupCamera / setupDPad / layoutDPad / setupHUD / layoutHUD / setupEnemy / didChangeSize / update / didBegin / handleProjectileContact / handleNoteContact / endGame / startSpawnLoop / trySpawnNote / currentNoteCount / randomNotePosition / fireProjectile / currentProjectileCount) | 0 |
| HUDNode `update(score:remainingTime:combo:)` 시그니처 | 0 |
| 음표 spawn loop (`startSpawnLoop` + `SKAction.repeatForever` 패턴) | 0 — F 발사만 재귀로 변경 |
| GameConfig 기존 상수 *값* | 0 (`projectileFireInterval` 값 3.5 그대로, 주석만) |
| EnemyNode update 시그니처 | 0 (2-8 그대로) |

## 검증 시뮬레이션

- (a) 시작 직후 첫 F 발사: *3.5초 후* (시작값)
- (b) 게임 중반 (남은시간 22.5초): F 발사 주기 *2.75초* (중간값)
- (c) 게임 끝 직전 (남은시간 5초): F 발사 주기 *~2.17초* (끝값에 가까움)
- (d) 게임 종료 시점 (남은시간 0초): 주기 *2.0초* — 다만 endGame 호출되어 다음 발사 안 됨
- (e) enemy 속도 보간 (2-8) 동시 동작
- (f) F 동시 최대 2개 (변경 0)
- (g) endGame 시 fire 시퀀스 즉시 정지 (removeAction)

## 주의사항

- 재귀 SKAction의 *withKey 동일 등록* — SpriteKit이 같은 키로 액션 등록 시 *기존 액션 교체*. 시퀀스 끝난 후 재등록이라 충돌 없음.
- `[weak self]` 누락 시 GameScene이 *영원히 살아있음* — 메모리 누수. 반드시 명시.
- `endGame`에서 `removeAction(forKey: "fireProjectiles")` 호출 → *현재 진행 중인 wait* 즉시 취소 → run 클로저 미실행 → 재귀 종료. 정상 동작.
- 재귀 호출이 *액션 클로저 안*이라 콜 스택 누적 없음. SpriteKit이 *비동기* 처리.
