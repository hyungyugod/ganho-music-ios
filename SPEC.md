# Phase 4-7 (F) — 수간호사 복귀 후 F 재스폰

## 개요
AIRFORCE 이스터에그 시퀀스의 마지막(5/5) 조각. 수간호사가 5초 도주를 끝내고 *추적을 재개하는 바로 그 순간* F 1발이 즉시 player 위치를 향해 발사된다. EnemyNode.startFleeing 시그니처에 `@escaping () -> Void = {}` 콜백 매개변수를 추가하고, SpawnSystem에 public wrapper `fireImmediately()`를 신설, GameScene이 두 변경을 trailing closure로 연결한다.

## 변경 유형
**게임플레이** — EnemyNode startFleeing 시그니처 확장(콜백), SpawnSystem public wrapper, GameScene 콜백 등록.

## 게임 경험 의도
수간호사가 5초 도주를 끝내고 *추적을 재개하는 바로 그 순간* F 한 발이 즉시 player 위치를 향해 날아간다. AIRFORCE 이스터에그의 *마침표* — "내가 돌아왔다, 다시 던진다" 신호. 게임 균형은 그대로 (projectileMaxConcurrent 가드 통과 필요, 통과 못 하면 발사 0).

## Sprint 범위 계약

### In Scope (모두 필수)

1. **`Systems/SpawnSystem.swift`** (+~5줄)
   - 헤더 주석 Phase 4-7 라인 1줄
   - `// MARK: - Projectile Fire` 섹션 안 public wrapper `fireImmediately()` 메서드 신설
   - 기존 private `fireProjectile()` 본문/시그니처 변경 0

2. **`Nodes/EnemyNode.swift`** (+~3줄)
   - 헤더 주석 Phase 4-7 라인 1줄
   - `startFleeing(duration:)` 시그니처에 `onEnd: @escaping () -> Void = {}` 매개변수 추가
   - sequence 마지막 `SKAction.run`(end) 본문에 `onEnd()` 호출 추가 (isFleeing=false 다음)
   - doc 코멘트 1줄
   - `isFleeing`/`update`/init 본문은 변경 0

3. **`GameScene.swift`** (+~5줄)
   - 헤더 MARK 1줄: `//  Phase 4-7 · 수간호사 복귀 후 F 재스폰 — startFleeing onEnd 콜백으로 fireImmediately`
   - `triggerAirforceEasterEgg()` doc 코멘트 1줄
   - 본문 마지막 `enemy.startFleeing(...)` 1줄을 trailing closure 형태 3줄로 확장
   - 기존 trigger 본문 *그 외 10줄* 한 줄도 변경 금지
   - 가드 2줄 한 줄도 변경 금지

### Out of Scope (모두 금지, 위반 시 P0)
- AirplaneNode / AirforceOverlayNode / BombFlashNode 변경
- ContactRouter / PhysicsCategory / StoneGuardNode / GameScene+Setup 변경
- GameConfig 변경 (기존 상수 변경 + 신규 상수 추가 모두 금지)
- Player / Note / Projectile / HUD / DPad 노드 변경
- TitleScene / ResultScene 변경
- ColorTokens 새 토큰 신설
- update() 게임 루프 / endGame() / airforceTriggered 가드 위치 변경
- F 발사 주기 변경 / projectileMaxConcurrent 변경
- 재스폰 시 F 개수 변경 (1발만)
- 재스폰 시 발사 위치/속도/방향 변경 (기존 fireProjectile 그대로)
- 도주 시 발사 일시 정지
- pbxproj 변경
- macOS / tvOS 변경
- Test 코드 추가
- `protocol SelfDismissingNode` 추출 (별도 sprint)
- 기존 EnemyNode `isFleeing`/`update` 본문 변경 (4-6 그대로)

### 판단 기준
"이 변경이 없으면 '수간호사 도주 종료 시점에 F 1발 즉시 발사'가 동작하는가?" → NO만 In Scope.

## 변경 범위
- 수정: `Systems/SpawnSystem.swift` (+~5줄)
- 수정: `Nodes/EnemyNode.swift` (+~3줄)
- 수정: `GameScene.swift` (+~5줄)
- pbxproj 변경 0 / GameConfig 변경 0

## 기능 상세

### 기능 1: SpawnSystem.fireImmediately() public wrapper

- **구현 위치**: `Systems/SpawnSystem.swift`, `// MARK: - Projectile Fire` 섹션 안. `fireProjectile()` 다음 또는 `startProjectileFireLoop()` 위.
- **헤더 주석 1줄 추가** (`Phase 2-10` 다음):
```swift
//  Phase 4-7 · 외부 호출용 fireImmediately() public wrapper 신설 (AIRFORCE 이스터에그 5/5)
```
- **메서드**:
```swift
/// Phase 4-7 — 외부 호출용. private fireProjectile()의 외부 진입점.
/// AIRFORCE 이스터에그 수간호사 복귀 시 F 1발 즉시 발사.
/// projectileMaxConcurrent 가드는 그대로(균형 유지).
func fireImmediately() {
    fireProjectile()
}
```
- **주의**: 기존 private `fireProjectile()`는 한 글자도 손대지 않는다.

### 기능 2: EnemyNode.startFleeing 시그니처 확장 (onEnd 콜백)

- **구현 위치**: `Nodes/EnemyNode.swift`, `// MARK: - Flee` 섹션의 `startFleeing(duration:)`.
- **헤더 주석 1줄 추가** (`Phase 4-6` 다음):
```swift
//  Phase 4-7 · startFleeing 시그니처에 onEnd 콜백 매개변수 추가 (default = {})
```
- **메서드 최종 형태**:
```swift
/// 외부 호출 시 duration초간 도주 모드 진입. 만료 시 자동 복귀.
/// 이미 도주 중이면 무시(재호출 가드). [weak self]로 순환 참조 방지.
/// Phase 4-6 — DispatchQueue/Timer 금지. SKAction.sequence로 시간 흐름 표현.
/// Phase 4-7 — duration 종료 직후 onEnd 콜백 발화. 기본값 {}로 4-6 호출 사이트 호환.
func startFleeing(duration: TimeInterval, onEnd: @escaping () -> Void = {}) {
    if isFleeing { return }
    let start = SKAction.run { [weak self] in self?.isFleeing = true }
    let wait  = SKAction.wait(forDuration: duration)
    let end   = SKAction.run { [weak self] in
        self?.isFleeing = false
        onEnd()
    }
    run(.sequence([start, wait, end]))
}
```
- **주의**:
  - `@escaping` 필수
  - default `= {}` 필수 (4-6 호환)
  - `onEnd()` 호출은 self가 nil이어도 정상 호출 (onEnd는 self와 별개 closure 변수)

### 기능 3: GameScene.triggerAirforceEasterEgg — startFleeing 호출에 콜백 등록

- **구현 위치**: `GameScene.swift`, `// MARK: - Easter Egg` 섹션 마지막 줄.
- **헤더 MARK 1줄 추가** (`Phase 4-6` 다음):
```swift
//  Phase 4-7 · 수간호사 복귀 후 F 재스폰 — startFleeing onEnd 콜백으로 fireImmediately
```
- **doc 코멘트 1줄 추가** (`Phase 4-6` doc 다음):
```swift
/// Phase 4-7 — startFleeing onEnd 콜백 등록 — 도주 종료 시 spawnSystem.fireImmediately() 발화.
```
- **본문 마지막 줄 확장**:
```swift
// 기존(1줄):
// enemy.startFleeing(duration: GameConfig.enemyFleeDuration)

// 신규(3줄):
enemy.startFleeing(duration: GameConfig.enemyFleeDuration) { [weak self] in
    self?.spawnSystem.fireImmediately()
}
```
- **주의**:
  - `[weak self]` 의무 — ResultScene 전환 시 GameScene 해제 가능
  - trailing closure 형태 사용 (`onEnd:` 라벨 X — Swift 관용)
  - 그 외 10줄 + 가드 2줄 *한 글자도* 변경 금지

## 검증 시나리오 (a)~(i)

| # | 시나리오 | 정적 검증 방법 |
|---|---|---|
| (a) | 미접촉 시 fireImmediately 호출 0 | Grep `fireImmediately` 호출 사이트 GameScene 1곳뿐 |
| (b) | trigger 본문에 trailing closure 정확 | `enemy.startFleeing(duration: GameConfig.enemyFleeDuration) { [weak self] in` 확인 |
| (c) | onEnd default `= {}` 정확 | `onEnd: @escaping () -> Void = {}` 일치 |
| (d) | sequence 마지막 run 본문 onEnd() | `self?.isFleeing = false` 다음 줄 `onEnd()` |
| (e) | [weak self] 두 곳 | GameScene 콜백 + EnemyNode end run |
| (f) | projectileMaxConcurrent 가드 그대로 | fireProjectile 본문 변경 0 |
| (g) | airforceTriggered 가드 그대로 | trigger 첫 2줄 변경 0 |
| (h) | ARC 안전 | `[weak self]` 캡처 → self?.spawnSystem 옵셔널 체이닝 |
| (i) | 빌드 SUCCEEDED + 경고 0 | 강제 언래핑 0, 매직 넘버 0, `@escaping` + default 정확 |

## 학습 가치
- Closure parameter — 함수가 *값*
- `@escaping` — 메서드 종료 후 호출되는 클로저
- Default closure parameter `= {}` — 4-6 호환성
- Public wrapper 패턴 — private 외부 진입점
- 콜백 등록 vs 별도 SKAction — 타이머 동기화 안전
- AIRFORCE 이스터에그 완성 (6 sprint 누적, GDD §7-7 5단계 모두)
- 호출 측 변경 0 정책 6 sprint 종합

## 주의사항
- `@escaping` 키워드 필수 — SKAction 안 보관, 메서드 종료 후 호출
- default `= {}` 필수 — 4-6 호환
- GameScene 콜백 `[weak self]` 의무
- EnemyNode end run의 `[weak self]`는 4-6에서 이미 있음 — onEnd() 호출은 self와 무관
- `fireImmediately`는 SpawnSystem 메서드 — `spawnSystem.fireImmediately()` 호출
- F 동시 최대 가드 통과 못 하면 발사 0 — 정상
- pbxproj 미변경 — 신규 파일 0
- AIRFORCE 이스터에그 완성 (GDD §7-7 5단계 모두 구현)
