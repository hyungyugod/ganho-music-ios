# Phase 2-8 — 수간호사 속도 시간 보간 (60 → 110 선형)

## 개요
게임 진행률에 따라 enemy 속도가 *60(시작)에서 110(끝)으로 선형 증가*.
공식: `curveT = 1 - remainingTime / gameDuration`. 매 프레임 GameScene이 계산해서 EnemyNode.update에 전달.

## 변경 유형
**게임플레이** — 속도 보간으로 시간 압박 추가.

## 게임 경험 의도
> "시간이 흐를수록 수간호사가 점점 빨라짐. 시작은 여유롭게(60), 끝은 거의 2배 속도(110).
> 게임에 *난이도 곡선*이 생김 — 학습 → 압박 → 도전."

## Sprint 범위 계약

### 허용 (IN)
- 수정 3 파일:
  - `Config/GameConfig.swift` — `enemyMaxSpeed = 110` 1줄 + 주석
  - `Nodes/EnemyNode.swift` — `update` 시그니처 확장 + 보간 계산
  - `GanhoMusic Shared/GameScene.swift` — update 안 curveT 계산 + enemy.update 호출 인자 추가

### 금지 (OUT)
- F 발사 주기 보간 → Phase 2-9
- 동시 수 변화 / 청진기 / 무적 → 후속 phase
- 사운드 / 시각 효과 → Phase 6
- Systems 분리 → 별도 sprint
- player 속도 보간 → Phase 5+ (난이도 시스템과 함께)

## 변경 범위

### 수정할 파일

| 파일 | 변경 |
|---|---|
| `Config/GameConfig.swift` | `enemyBaseSpeed` 정의 다음 줄에 `enemyMaxSpeed: CGFloat = 110` 1상수 추가 |
| `Nodes/EnemyNode.swift` | `update(deltaTime:targetPosition:)` → `update(deltaTime:targetPosition:speedT:)`. 본문에서 `speed`를 `enemyBaseSpeed + (enemyMaxSpeed - enemyBaseSpeed) * speedT`로 계산 |
| `GanhoMusic Shared/GameScene.swift` | `update(_:)` 안에서 `let curveT = 1.0 - remainingTime / GameConfig.gameDuration` 계산 후 `enemy.update(deltaTime: dt, targetPosition: player.position, speedT: curveT)` 호출 |

### 추가할 파일
**없음.**

### Xcode 멤버십
**필요 없음** (신설 파일 0).

## 기능 상세

### 기능 1: GameConfig.enemyMaxSpeed 상수
```swift
// MARK: - Enemy (Phase 2-6) 섹션 안, enemyBaseSpeed 다음 줄에 추가
/// 적 최대 속도 (pt/s). 게임 종료 시점 도달값. GDD §5 obsMaxSpeed.
/// Phase 2-8 — 시간 보간으로 enemyBaseSpeed(60)에서 이 값(110)까지 선형 증가.
static let enemyMaxSpeed: CGFloat = 110
```
- 위치: `enemyBaseSpeed` 정의 *바로 다음 줄*. 기존 enemyWidth/enemyHeight 위.
- 기존 상수 변경 0.

### 기능 2: EnemyNode.update 시그니처 확장 + 보간
```swift
/// 외부에서 매 프레임 호출. player 위치를 향한 단위 벡터 × 보간 속도 → velocity.
/// magnitude == 0 가드(NaN 방지).
/// - Parameters:
///   - deltaTime: dt — 본 sprint에서는 미사용.
///   - targetPosition: 추적 대상 좌표(worldNode 좌표계). 보통 player.position.
///   - speedT: 게임 진행률 (0 ~ 1). 0 = 시작 속도, 1 = 최대 속도. GameScene이 매 프레임 계산.
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
    // Phase 2-8 — 선형 보간: speedT 0 = base, 1 = max.
    let speed = GameConfig.enemyBaseSpeed
        + (GameConfig.enemyMaxSpeed - GameConfig.enemyBaseSpeed) * speedT
    physicsBody?.velocity = CGVector(
        dx: unitX * speed,
        dy: unitY * speed
    )
}
```
- 시그니처에 `speedT: CGFloat` 인자 추가.
- 본문에서 `speed` 변수 도입, velocity 곱셈에 사용.
- hypot, magnitude > 0 가드, dx/dy 계산 그대로 보존.

### 기능 3: GameScene update 안 curveT 계산
```swift
// 기존 (2-7)
enemy.update(deltaTime: dt, targetPosition: player.position)

// 변경 후 (2-8)
let curveT = 1.0 - remainingTime / GameConfig.gameDuration
enemy.update(deltaTime: dt, targetPosition: player.position, speedT: curveT)
```
- 위치: `cameraNode.position = player.position` 다음 줄(또는 enemy.update 호출 직전).
- `curveT`는 0 ~ 1 사이 값 (시작 0, 끝 1).
- `remainingTime`은 이미 GameScene 멤버.
- `GameConfig.gameDuration` = 45.

## 준수 룰

| # | 룰 | 검증 |
|---|---|---|
| 1 | `enemyMaxSpeed` 상수 1건 정의, GameConfig | grep |
| 2 | EnemyNode.update 시그니처에 `speedT: CGFloat` 추가 | grep |
| 3 | EnemyNode 본문 보간 공식 (base + (max - base) * t) | grep |
| 4 | GameScene curveT 계산 1건 + enemy.update 호출 1건 | grep |
| 5 | 매직 넘버 0건 (60/110/45 모두 GameConfig.*) | grep |
| 6 | hypot + magnitude > 0 가드 보존 | grep |
| 7 | 강제 언래핑 / Timer / print / as! 0건 | grep |
| 8 | dx/dy 계산 / 단위 벡터 정규화 보존 | diff |
| 9 | BUILD SUCCEEDED | xcodebuild |

## 회귀 보존

| 영역 | 변경 |
|---|---|
| `Config/PhysicsCategory.swift` / `GameState.swift` / `ColorTokens.swift` | 0 |
| `Nodes/HUDNode.swift` / `DPadNode.swift` / `NoteNode.swift` / `PlayerNode.swift` / `ProjectileNode.swift` | 0 |
| iOS 3 파일 / pbxproj | 0 |
| GameScene 의 다른 함수 (setup* / didBegin / endGame / startSpawnLoop / startProjectileFireLoop / fireProjectile 등) | 0 |
| HUDNode `update(score:remainingTime:combo:)` 시그니처 | 0 |
| GameConfig 기존 8 섹션 + enemyBaseSpeed/enemyWidth/enemyHeight 등 | 0 |
| EnemyNode init / required init | 0 (update 시그니처만 확장) |

## 검증 시뮬레이션

- (a) 시작 직후 enemy 속도 *60* (천천히)
- (b) 22.5초 시점 enemy 속도 *85* (중간 보간)
- (c) 종료 직전(0초) enemy 속도 *110* (최대)
- (d) F 발사 주기 *3.5초 그대로* (보간 OUT)
- (e) 음표 spawn / 콤보 / HUD / D-Pad / 카메라 follow 그대로
- (f) enemy↔player 접촉 / 시간 만료 / F 피격 모두 endGame 그대로

## 주의사항

- `update(deltaTime:targetPosition:)` → `update(deltaTime:targetPosition:speedT:)` 시그니처 변경.
  호출처 **GameScene 1곳**만 변경됨. 컴파일 에러로 자동 식별 — 누락 없게 처리.
- `speedT`가 `0 ~ 1` 범위 가정. clamp 안 함 (remainingTime이 max(0, ...)으로 제한되어 있어 안전).
- 기존 EnemyNode.update의 *NaN 가드 (magnitude > 0)*가 보간 적용 *이전*에 동작 — 0 division 위험 없음.
