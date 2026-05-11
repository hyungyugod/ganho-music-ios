# Phase 4-6 (E) — 수간호사 5초 도주 모드

## 개요
폭탄 직후(같은 trigger 호출 안) `EnemyNode`가 *플레이어 반대 방향*으로 5초간 움직였다가 자동 복귀(추적 재개). EnemyNode 내부에 *isFleeing* 상태 머신 1단계 도입(Bool flag), 호출 측은 `enemy.startFleeing(duration:)` 한 줄만 호출. GameScene·기타 노드의 충돌·점수·F·게임오버 로직은 *0줄 변경*.

## 변경 유형
**게임플레이** — EnemyNode AI 행동 분기(상태 머신 1차) + GameScene 트리거 1줄.

## 게임 경험 의도
폭탄이 터진 *직후*, 수간호사가 *겁먹은 듯* 플레이어와 반대 방향으로 5초간 도망간다. 속도는 평소와 동일(`enemyBaseSpeed`/`enemyMaxSpeed` 시간 보간 그대로). 5초가 지나면 자연스럽게 추적이 재개되어 게임의 위협 시계가 *되돌아간* 듯한 *작은 보상*을 준다. F 발사·점수·HUD·게임오버 메커니즘은 정상.

## Sprint 범위 계약

### In Scope (모두 필수)

1. **`Nodes/EnemyNode.swift`** (+~10줄)
   - 헤더 주석에 Phase 4-6 라인 1줄
   - `// MARK: - State` 섹션 신설 + `var isFleeing: Bool = false`
   - `// MARK: - Flee` 섹션 신설 + `func startFleeing(duration:)` 메서드
   - `update` 본문에 `direction` 분기 + 최종 `velocity = ... * direction`

2. **`Config/GameConfig.swift`** (+1 상수)
   - Airforce Easter Egg 섹션 *끝*(`bombFlashFadeOutDuration` 다음)에 `enemyFleeDuration: TimeInterval = 5.0` + doc 2줄

3. **`GameScene.swift`** (+~3줄)
   - 헤더 MARK 1줄
   - `triggerAirforceEasterEgg()` doc 1줄
   - 본문 마지막에 `enemy.startFleeing(duration: GameConfig.enemyFleeDuration)` 1줄

### Out of Scope (모두 금지, 위반 시 P0)
- AirplaneNode / AirforceOverlayNode / BombFlashNode 변경
- ContactRouter / PhysicsCategory / StoneGuardNode / GameScene+Setup 변경
- 기존 GameConfig 상수 값 변경
- Player / Note / Projectile / HUD / DPad 노드 변경
- TitleScene / ResultScene 변경
- ColorTokens 새 토큰 신설
- update() 게임 루프 / endGame() / airforceTriggered 가드 위치 변경
- F 재스폰 효과 (다음 sprint 4-7)
- 도주 중 contactBitMask / collisionBitMask 변경
- 도주 속도 별도 상수 (기존 enemyBaseSpeed/MaxSpeed 그대로)
- `DispatchQueue.main.asyncAfter` / `Timer` 사용
- 사운드 / 햅틱 / 진동
- 도주 시각 효과 (수간호사 색 변화 등)
- pbxproj 변경
- macOS / tvOS 변경
- Test 코드 추가
- 기존 trigger 본문 10줄 변경

### 판단 기준
"이 변경이 없으면 'Player가 StoneGuard 첫 통과 시 trigger 직후 수간호사가 5초간 반대 방향 → 추적 재개'가 동작하는가?" → NO만 In Scope.

## 변경 범위
- 수정: `Nodes/EnemyNode.swift` (~10줄)
- 수정: `Config/GameConfig.swift` (~3줄)
- 수정: `GameScene.swift` (~3줄)
- pbxproj 변경 0

## 기능 상세

### 기능 1: EnemyNode 상태 머신 — `isFleeing` 프로퍼티
- 설명: 수간호사가 *추적*/*도주* 모드인지 1-bit. 외부 *읽기*만 허용 (internal/기본 가시성).
- 구현 위치: `Nodes/EnemyNode.swift` `// MARK: - State` 섹션 신설 (Init 위)
- 코드:
```swift
// MARK: - State
/// Phase 4-6 — 도주 모드 플래그. true면 update에서 velocity 방향이 반전된다.
/// startFleeing(duration:) 메서드만 토글한다 (외부 직접 쓰기 금지 정책).
var isFleeing: Bool = false
```

### 기능 2: EnemyNode `startFleeing(duration:)` 메서드
- 설명: 외부 호출 시 duration초 도주 진입 → 만료 시 자동 복귀. 재호출 가드 + `[weak self]` 캡처.
- 구현 위치: `Nodes/EnemyNode.swift` `// MARK: - Flee` 섹션 신설 (Update 위)
- 코드:
```swift
// MARK: - Flee
/// 외부 호출 시 duration초간 도주 모드 진입. 만료 시 자동 복귀.
/// 이미 도주 중이면 무시(재호출 가드). [weak self]로 순환 참조 방지.
/// Phase 4-6 — DispatchQueue/Timer 금지. SKAction.sequence로 시간 흐름 표현.
func startFleeing(duration: TimeInterval) {
    if isFleeing { return }
    let start = SKAction.run { [weak self] in self?.isFleeing = true }
    let wait  = SKAction.wait(forDuration: duration)
    let end   = SKAction.run { [weak self] in self?.isFleeing = false }
    run(.sequence([start, wait, end]))
}
```

### 기능 3: EnemyNode `update` 방향 분기
- 설명: 최종 velocity 한 곳에 direction 곱셈. 속도는 그대로, 방향만 반전.
- 구현 위치: `update` 본문의 `let speed = ...` 다음, `physicsBody?.velocity = ...` 직전 1줄 + velocity 표현식에 `* direction` 2회 추가
- 코드 (변경 후):
```swift
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
    let speed = GameConfig.enemyBaseSpeed
        + (GameConfig.enemyMaxSpeed - GameConfig.enemyBaseSpeed) * speedT
    // Phase 4-6 — 도주 모드면 player 반대 방향(-1). 추적이면 +1. 한 줄 분기.
    let direction: CGFloat = isFleeing ? -1 : 1
    physicsBody?.velocity = CGVector(
        dx: unitX * speed * direction,
        dy: unitY * speed * direction
    )
}
```

### 기능 4: EnemyNode 헤더 주석
- 코드:
```swift
//  Phase 2-6 · 수간호사 적 NPC (직선 추적 AI + 접촉 시 게임오버)
//  Phase 4-6 · 5초 도주 모드 추가 (isFleeing + startFleeing + update 방향 분기)
```

### 기능 5: GameConfig `enemyFleeDuration`
- 구현 위치: Airforce Easter Egg 섹션 *끝*(`bombFlashFadeOutDuration` 다음)
- 코드:
```swift
    /// Phase 4-6 — 수간호사 도주 모드 지속 시간 (초). GDD §7-7 명시 5초.
    /// trigger 시점에 enemy.startFleeing(duration:)에 전달. 만료 후 자동 추적 재개.
    static let enemyFleeDuration: TimeInterval = 5.0
```

### 기능 6: GameScene 트리거 호출 1줄 추가
- 구현 위치: `triggerAirforceEasterEgg()` 본문 *마지막*(폭탄 3줄 뒤)
- 코드 (최종 본문):
```swift
private func triggerAirforceEasterEgg() {
    if airforceTriggered { return }
    airforceTriggered = true
    let plane = AirplaneNode()
    cameraNode.addChild(plane)
    let y = +(size.height / 2 - GameConfig.airplaneTopOffset)
    plane.crossScreen(sceneWidth: size.width, atY: y)
    let overlay = AirforceOverlayNode()
    cameraNode.addChild(overlay)
    overlay.showAndDismiss()
    let bomb = BombFlashNode()
    cameraNode.addChild(bomb)
    bomb.flash(sceneSize: size)
    enemy.startFleeing(duration: GameConfig.enemyFleeDuration)
}
```

### 기능 7: GameScene 헤더 + doc
- 헤더(Phase 4-5 다음):
```swift
//  Phase 4-6 · 수간호사 5초 도주 — 트리거 시 enemy.startFleeing 호출
```
- doc(Phase 4-5 doc 다음):
```swift
    /// Phase 4-6 — 동일 가드 안쪽에 enemy.startFleeing(...) 호출로 수간호사 5초 도주 모드 진입.
```

## 검증 시나리오 (a)~(i)

| # | 시나리오 | 정적 검증 방법 |
|---|---|---|
| (a) | 미접촉 시 도주 0 | `startFleeing` 호출 grep → trigger 본문 1곳뿐 |
| (b) | trigger 시 호출 정확 | trigger 마지막 줄 `enemy.startFleeing(duration: GameConfig.enemyFleeDuration)` |
| (c) | x축 velocity 반전 | `let direction: CGFloat = isFleeing ? -1 : 1` + `dx: unitX * speed * direction` |
| (d) | y축 velocity 반전 | `dy: unitY * speed * direction` |
| (e) | 5초 후 false | sequence 마지막 run 본문 `self?.isFleeing = false` |
| (f) | 도주 중 충돌 게임오버 | EnemyNode contactTestBitMask/.player & collisionBitMask/.wall 그대로 |
| (g) | 재통과 시 도주 0 | airforceTriggered 가드 + `if isFleeing { return }` 이중 가드 |
| (h) | ARC 해제 | `SKAction.run` 두 곳 모두 `[weak self]` 캡처 |
| (i) | 빌드 SUCCEEDED + 경고 0 | 강제 언래핑 0, 매직 넘버 0, Timer/DispatchQueue 0 |

## 학습 가치
- EnemyNode 상태 머신 — Bool flag (Rule of three — 3개 등장 시 enum 승격)
- `SKAction.run { closure }` — 시간 흐름 내 코드 실행
- `[weak self]` 캡처 — 노드 자체 SKAction에서 의무
- 방향 반전 = 단위 벡터 * -1
- 책임 분리 — 도메인 객체가 자기 상태 관리
- *호출 측 변경 0* 정책의 *제한된 위반* (EnemyNode 한정 최소 변경)
- 재호출 가드 패턴

## 주의사항
- **`[weak self]` 캡처 의무** — `startFleeing` 내부 두 `SKAction.run` 클로저 *둘 다*
- **`if isFleeing { return }` 가드** — `startFleeing` 진입부 첫 줄
- **도주 속도 별도 상수 신설 금지** — 기존 enemyBaseSpeed/MaxSpeed 그대로
- **direction 곱셈은 *최종 velocity 한 곳*에서만**
- **`DispatchQueue.main.asyncAfter` / `Timer` 절대 금지** — 반드시 SKAction
- **기존 trigger 본문 10줄 한 줄도 변경 금지**
- **`isFleeing`은 internal(기본)** — `private` 강제 X
- **pbxproj 변경 0** — 신규 파일 없음
- **direction 위치** — `magnitude == 0` 가드 안쪽이 아닌 `let speed = ...` 다음
