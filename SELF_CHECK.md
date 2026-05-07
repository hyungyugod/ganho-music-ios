# 자체 점검 — Phase 2-8 수간호사 속도 시간 보간

전략: 1회차 (최초 구현) — Case A/B/C 판정 대상 아님.

---

## 빌드 상태

- **BUILD SUCCEEDED** — `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' build`
- 컴파일 경고: 없음
- 컴파일 에러: 없음

---

## SPEC §"준수 룰" 9개 항목

| # | 룰 | 검증 방법 | 결과 |
|---|---|---|---|
| 1 | `enemyMaxSpeed` 상수 1건 정의, GameConfig | `grep -rn "enemyMaxSpeed"` → `Config/GameConfig.swift:89: static let enemyMaxSpeed: CGFloat = 110` (정의 1건) + `EnemyNode.swift:66`(사용 1건) | **PASS** |
| 2 | EnemyNode.update 시그니처에 `speedT: CGFloat` 추가 | `EnemyNode.swift:54: func update(deltaTime: TimeInterval, targetPosition: CGPoint, speedT: CGFloat)` | **PASS** |
| 3 | EnemyNode 본문 보간 공식 (base + (max - base) * t) | `EnemyNode.swift:65-66: let speed = GameConfig.enemyBaseSpeed + (GameConfig.enemyMaxSpeed - GameConfig.enemyBaseSpeed) * speedT` | **PASS** |
| 4 | GameScene curveT 계산 1건 + enemy.update 호출 1건 | `GameScene.swift:262: let curveT = CGFloat(1.0 - remainingTime / GameConfig.gameDuration)` + `:263: enemy.update(... speedT: curveT)` | **PASS** |
| 5 | 매직 넘버 0건 (60/110/45 모두 GameConfig.*) | grep 결과 60/110/45 출현 위치는 모두 (a) GameConfig 정의 자체, (b) 주석, (c) HUD placeholder text "00:45", (d) `private var remainingTime = GameConfig.gameDuration` 주석 — **본 sprint에서 추가한 코드에 raw 매직 넘버 0건** | **PASS** |
| 6 | hypot + magnitude > 0 가드 보존 | `EnemyNode.swift:57: let magnitude = hypot(dx, dy)` + `:58: guard magnitude > 0 else { ...; return }` (보간 적용 *이전*에 동작) | **PASS** |
| 7 | 강제 언래핑 / Timer / print / as! 0건 | `grep -rn "Timer\."` → 0, `grep -rn "print("` → 0, `grep -rn "as!"` → 0, force-unwrap `!` → 0 (수정 코드 한정) | **PASS** |
| 8 | dx/dy 계산 / 단위 벡터 정규화 보존 | `EnemyNode.swift:55-56` (dx/dy 계산), `:62-63` (unitX/unitY 정규화) — diff상 변경 0줄, 위치만 그대로 유지 | **PASS** |
| 9 | BUILD SUCCEEDED | xcodebuild 출력 마지막 줄 `** BUILD SUCCEEDED **` | **PASS** |

---

## SPEC §"회귀 보존" 표 변경 0줄 확인

| 영역 | SPEC 요구 | 실제 |
|---|---|---|
| `Config/PhysicsCategory.swift` / `GameState.swift` / `ColorTokens.swift` | 0 | **0** (git diff에 미포함) |
| `Nodes/HUDNode.swift` / `DPadNode.swift` / `NoteNode.swift` / `PlayerNode.swift` / `ProjectileNode.swift` | 0 | **0** (git diff에 미포함) |
| iOS 3 파일 (AppDelegate / GameViewController / SceneDelegate) / pbxproj | 0 | **0** (git diff에 미포함) |
| GameScene 의 다른 함수 (setup* / didBegin / endGame / startSpawnLoop / startProjectileFireLoop / fireProjectile 등) | 0 | **0** — 변경은 `update(_:)` 안 한 곳(L260 → L261-263)뿐. 다른 함수 시그니처/본문 모두 무손상 |
| HUDNode `update(score:remainingTime:combo:)` 시그니처 | 0 | **0** — GameScene L263 `hud.update(score: score, remainingTime: remainingTime, combo: combo)` 그대로 |
| GameConfig 기존 8 섹션 + enemyBaseSpeed/enemyWidth/enemyHeight 등 | 0 | **0** — `enemyMaxSpeed` 1상수 *추가*만 발생, 기존 상수 한 줄도 변경 안 됨 |
| EnemyNode init / required init | 0 (update 시그니처만 확장) | **0** — init / required init 본문 무손상. update 시그니처만 `speedT: CGFloat` 추가 |

`git diff --stat` 검증:
```
GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift |  3 +++
GanhoMusic/GanhoMusic Shared/GameScene.swift         |  5 ++++-
GanhoMusic/GanhoMusic Shared/Nodes/EnemyNode.swift   | 14 +++++++++-----
3 files changed, 16 insertions(+), 6 deletions(-)
```
변경 파일 정확히 3개. 다른 파일 변경 0.

---

## 변경 파일별 정확한 변경 줄 수 + before/after diff

### 1. `Config/GameConfig.swift` — +3 줄, -0 줄

**Before** (lines 86-87):
```swift
    static let enemyBaseSpeed: CGFloat = 60
    /// 수간호사 박스 가로 (pt). GDD §7-4 16×20.
```

**After** (lines 86-90):
```swift
    static let enemyBaseSpeed: CGFloat = 60
    /// 적 최대 속도 (pt/s). 게임 종료 시점 도달값. GDD §5 obsMaxSpeed.
    /// Phase 2-8 — 시간 보간으로 enemyBaseSpeed(60)에서 이 값(110)까지 선형 증가.
    static let enemyMaxSpeed: CGFloat = 110
    /// 수간호사 박스 가로 (pt). GDD §7-4 16×20.
```

추가: 주석 2줄 + 상수 정의 1줄 = **3줄**. 기존 줄 변경 0.

---

### 2. `Nodes/EnemyNode.swift` — +9 줄, -5 줄 (실 변경 시그니처 1줄 + 본문 보간 도입 + 주석 갱신)

**Before** (lines 47-67, update 함수 전체):
```swift
    /// 외부에서 매 프레임 호출. player 위치를 향한 단위 벡터 × enemyBaseSpeed → velocity.
    /// magnitude == 0 가드(NaN 방지).
    /// - Parameters:
    ///   - deltaTime: dt — 본 sprint에서는 미사용 (velocity 기반, 엔진이 dt 처리).
    ///                Phase 2-8 시간 보간 도입 시 시그니처 추가 변경 없이 사용 가능.
    ///   - targetPosition: 추적 대상 좌표(worldNode 좌표계). 보통 player.position.
    func update(deltaTime: TimeInterval, targetPosition: CGPoint) {
        let dx = targetPosition.x - position.x
        let dy = targetPosition.y - position.y
        let magnitude = hypot(dx, dy)
        guard magnitude > 0 else {
            physicsBody?.velocity = .zero
            return
        }
        let unitX = dx / magnitude
        let unitY = dy / magnitude
        physicsBody?.velocity = CGVector(
            dx: unitX * GameConfig.enemyBaseSpeed,
            dy: unitY * GameConfig.enemyBaseSpeed
        )
    }
```

**After** (lines 47-72):
```swift
    /// 외부에서 매 프레임 호출. player 위치를 향한 단위 벡터 × 보간 속도 → velocity.
    /// magnitude == 0 가드(NaN 방지).
    /// - Parameters:
    ///   - deltaTime: dt — 본 sprint에서는 미사용 (velocity 기반, 엔진이 dt 처리).
    ///   - targetPosition: 추적 대상 좌표(worldNode 좌표계). 보통 player.position.
    ///   - speedT: 게임 진행률 (0 ~ 1). 0 = 시작 속도(base), 1 = 최대 속도(max).
    ///             GameScene이 매 프레임 1 - remainingTime / gameDuration 으로 계산.
    func update(deltaTime: TimeInterval, targetPosition: CGPoint, speedT: CGFloat) {
        let dx = targetPosition.x - position.x
        let dy = targetPosition.y - position.y
        let magnitude = hypot(dx, dy)
        guard magnitude > 0 else {
            physicsBody?.velocity = .zero
            return
        }
        let unitX = dx / magnitude
        let unitY = dy / magnitude
        // Phase 2-8 — 선형 보간: speedT 0 = base(60), 1 = max(110).
        let speed = GameConfig.enemyBaseSpeed
            + (GameConfig.enemyMaxSpeed - GameConfig.enemyBaseSpeed) * speedT
        physicsBody?.velocity = CGVector(
            dx: unitX * speed,
            dy: unitY * speed
        )
    }
```

핵심 변경:
- 시그니처: `targetPosition: CGPoint)` → `targetPosition: CGPoint, speedT: CGFloat)` — 1 인자 추가
- velocity dx/dy: `* GameConfig.enemyBaseSpeed` → `* speed` (지역 보간 변수)
- 보간 공식 도입: 2줄 (`let speed = base + (max - base) * speedT`)
- 주석: 첫 줄 "× enemyBaseSpeed" → "× 보간 속도", `speedT` Param doc 신규 2줄 추가, 구식 "Phase 2-8 시그니처 변경 없이" 주석 1줄 제거

dx/dy 계산 / hypot / magnitude 가드 / unitX·unitY 정규화: **무손상** (5줄 그대로).

---

### 3. `GanhoMusic Shared/GameScene.swift` — +4 줄, -1 줄

**Before** (line 260):
```swift
        // 4) Phase 2-6 — 적 직선 추적 (player 위치를 향해 velocity 갱신)
        enemy.update(deltaTime: dt, targetPosition: player.position)
```

**After** (lines 259-263):
```swift
        // 4) Phase 2-6 — 적 직선 추적 (player 위치를 향해 velocity 갱신)
        // Phase 2-8 — 게임 진행률 0 ~ 1 (시작 0, 끝 1). remainingTime은 max(0, ...)으로 음수 방지.
        // speedT는 CGFloat (EnemyNode.update 시그니처 일치) — TimeInterval(Double) → CGFloat 변환.
        let curveT = CGFloat(1.0 - remainingTime / GameConfig.gameDuration)
        enemy.update(deltaTime: dt, targetPosition: player.position, speedT: curveT)
```

핵심 변경:
- enemy.update 호출에 `speedT: curveT` 인자 추가 — 1줄 교체
- 그 직전에 `let curveT = CGFloat(...)` 1줄 추가 + 주석 2줄
- `CGFloat(...)` 캐스트 이유: `remainingTime`(TimeInterval/Double) ÷ `gameDuration`(TimeInterval/Double) → Double 결과를 EnemyNode.update의 `speedT: CGFloat`에 맞춤. 매직 넘버 0건 (`1.0`은 산술 항등 리터럴, 60/110/45 어느 값도 등장 안 함)
- `update(_:)` 함수의 다른 영역(첫 프레임 처리, dt, 가드, 콤보 검사, player 입력, player.update, 카메라 follow, hud.update) 모두 무손상

---

## SPEC §"검증 시뮬레이션" 매핑

| 검증 케이스 | 본 구현이 만족하는 근거 |
|---|---|
| (a) 시작 직후 enemy 속도 60 | `remainingTime == 45.0` → `curveT = 1 - 45/45 = 0` → `speed = 60 + 50*0 = 60` |
| (b) 22.5초 시점 enemy 속도 85 | `remainingTime == 22.5` → `curveT = 1 - 22.5/45 = 0.5` → `speed = 60 + 50*0.5 = 85` |
| (c) 종료 직전(0초) enemy 속도 110 | `remainingTime == 0` → `curveT = 1 - 0/45 = 1.0` → `speed = 60 + 50*1 = 110` |
| (d) F 발사 주기 3.5초 그대로 | `projectileFireInterval` 미변경 — `startProjectileFireLoop` 무손상 |
| (e) 음표 spawn / 콤보 / HUD / D-Pad / 카메라 follow 그대로 | `startSpawnLoop` / `handleNoteContact` / `hud.update` 호출 / `dpad`-`player` 결선 / `cameraNode.position = player.position` 모두 무손상 |
| (f) enemy↔player 접촉 / 시간 만료 / F 피격 모두 endGame 그대로 | `didBegin` 분기 / `remainingTime <= 0 → endGame()` / `handleProjectileContact` 모두 무손상 |

---

## Swift 패턴 준수

- **강제 언래핑 미사용**: PASS — `physicsBody?.velocity` 등 옵셔널 체이닝 그대로. 신규 코드에 `!` 0건.
- **guard let 옵셔널 처리**: PASS — `guard magnitude > 0` 가드 보존.
- **MARK 섹션 구분**: PASS — `MARK: - Update` 그대로.
- **GameConfig 상수 사용**: PASS — `enemyBaseSpeed` / `enemyMaxSpeed` / `gameDuration` 모두 namespace 통과 사용.
- **weak self 캡처**: 해당 사항 없음 (본 sprint 클로저 신설 0).

## SpriteKit 패턴 준수

- **didMove(to:)에서 초기화**: 변경 없음 (기존 그대로).
- **dt 기반 이동**: PASS — `update(_:)` 안 dt 계산 무손상. `enemy.velocity` 곱셈 항이 `speed`로 일관 — 엔진이 dt 처리.
- **SKAction 스폰 패턴**: 변경 없음 (`startSpawnLoop` / `startProjectileFireLoop` 무손상).
- **충돌 후 노드 즉시 삭제 없음**: 변경 없음 (`handleNoteContact` / `handleProjectileContact` 의 `.run(.removeFromParent())` 그대로).
- **HUD 노드 분리**: 변경 없음 (`hud`는 cameraNode 자식 그대로).

---

## 범위 외 미구현 항목

- F 발사 주기 보간 → SPEC OUT (Phase 2-9 위임).
- 동시 수 변화 / 청진기 / 무적 → SPEC OUT.
- 사운드 / 시각 효과 (속도 증가 시 enemy 깜빡임 등) → Phase 6 OUT.
- Systems 분리 (BeatSystem 등) → 별도 sprint OUT.
- player 속도 보간 → Phase 5+ OUT.
- `speedT` clamp(0, 1) 가드 미추가 — SPEC §주의사항 "remainingTime이 max(0, ...)로 제한되어 있어 안전" 명시. clamp 추가 시 SPEC 외 변경 — 미구현 의도적.
