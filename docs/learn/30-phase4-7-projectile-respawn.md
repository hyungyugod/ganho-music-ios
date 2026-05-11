# 30 · Phase 4-7 · 수간호사 복귀 직후 F 재스폰 — *돌아왔다, 다시 던진다* 🎯

> **이번 작업 한 줄**: 도주가 끝난 *바로 그 순간* 수간호사가 F 한 발을 *즉시* 던진다. "내가 돌아왔다"를 강조하는 마지막 시각/게임플레이 신호. AIRFORCE 이스터에그 시퀀스 **5/5 완성** sprint.

---

## 1. 왜?

GDD §7-7 AIRFORCE 이스터에그 시퀀스 *마지막*:
1. ✅ 오버레이 (4-4)
2. ✅ 비행기 (4-3)
3. ✅ 폭탄 (4-5)
4. ✅ 수간호사 5초 도주 (4-6)
5. ⬜ **수간호사 복귀 후 F 재스폰** ← 본 sprint

4-6 도주가 끝나는 *바로 그 시점*에 F 1발이 *즉시* 발사된다. 평소엔 *주기적*으로 발사되지만 본 sprint의 *재스폰* F는 *예외적*인 추가 발사. "도주 끝 = 위협 재개" 신호를 게임플레이 안에서 *명확히* 표현.

> Spring 비유: cooldown 만료 핸들러에서 *즉시 1회* 추가 트리거. 정기 스케줄 외 *이벤트성* 발화.

---

## 2. Spring 비유 ⭐

| SpriteKit | Spring | 한 줄 설명 |
|---|---|---|
| `EnemyNode.startFleeing(duration: onEnd:)` | `@Async public void cooldown(duration, Runnable onComplete)` | "cooldown 끝나면 콜백 실행" |
| `@escaping () -> Void` closure parameter | `Runnable` 또는 `Consumer<Void>` | "함수를 *값*으로 받음" |
| `SpawnSystem.fireImmediately()` | `@Service`의 public 메서드 | "private 비즈니스 로직의 외부 진입점" |
| `[weak self]` in closure | 약한 참조 | "콜백 수신자가 사라지면 무시" |
| Default closure parameter `= {}` | Optional callback | "호출자가 안 주면 noop" |

**핵심**: SpawnSystem 내부의 `fireProjectile()` private은 *그대로*, *public wrapper* 1개만 추가. *호출 측 변경 0*에 가깝지만 SpawnSystem 변경은 *불가피*.

---

## 3. 새로 배운 것 (Swift/SpriteKit) ⭐

### 3-1. **함수가 *값* — Closure Parameter**

```swift
func startFleeing(duration: TimeInterval, onEnd: @escaping () -> Void = {}) {
    ...
}
```

- `onEnd: () -> Void` — *인자 0개, 반환 없는 함수*를 매개변수로 받음
- 호출자가 *직접 코드 블록*을 전달

호출 시:
```swift
enemy.startFleeing(duration: 5.0) { [weak self] in
    self?.spawnSystem.fireImmediately()
}
```

마지막 *블록*({ ... })이 `onEnd` 인자.

> Spring 비유: Java 8 lambda `Runnable r = () -> service.doSomething();`. Swift는 closure가 *일급 시민*이라 더 자연.

### 3-2. **`@escaping` — 메서드 종료 후에도 호출되는 클로저**

```swift
onEnd: @escaping () -> Void = {}
```

`@escaping` 의미:
- 메서드(`startFleeing`)가 *return한 후*에도 클로저가 *호출될 수 있다*
- 본 sprint에서 클로저는 *SKAction 안에 보관*되어 5초 후 호출 → escaping 필요

비교: `@escaping` 없는 클로저(non-escaping, 기본)는 *메서드 종료 전에만* 호출 가능. 컴파일러가 보장.

> Spring 비유: Java의 `final` 캡처는 항상 escape. Swift는 *명시적*이라 메모리 추론 명확.

### 3-3. **Default Closure Parameter `= {}`**

```swift
onEnd: @escaping () -> Void = {}
```

기본값이 *빈 클로저* `{ }`라 호출자가 *생략 가능*:
- 콜백 필요: `enemy.startFleeing(duration: 5.0) { ... }`
- 콜백 불필요: `enemy.startFleeing(duration: 5.0)` ← 4-6 호환

**호환성**: 4-6 sprint에서 만든 호출 사이트(콜백 없음)도 *그대로 동작*. 시그니처가 *확장*됐지만 *깨지지 않음*.

> Spring 비유: `service.cooldown(duration)` overload 2개 — 콜백 있는 것과 없는 것. Swift는 *기본값* 하나로 처리.

### 3-4. **Public Wrapper 패턴**

```swift
// SpawnSystem
private func fireProjectile() { ... }  // 자동 발사 루프용

/// Phase 4-7 — 외부 호출용 wrapper. private fireProjectile()을 노출.
func fireImmediately() {
    fireProjectile()
}
```

**왜 wrapper?**:
- `fireProjectile`을 `public`으로 직접 바꾸면 *모든 호출자가 접근* — 의도와 다른 호출 가능성
- wrapper는 *의도 명시* (이름 `fireImmediately`로 *예외적 발사*임을 표현)
- 미래에 wrapper 본문에 *추가 로직*(예: 통계 카운터 +1) 끼우기 쉬움

> Spring 비유: `private void fireInternal()` + `public void fireImmediately() { fireInternal(); }`. 캡슐화 + 의도 노출.

### 3-5. **콜백 등록 vs 직접 호출 비교**

| 패턴 | 코드 | 결합도 |
|---|---|---|
| 직접 호출 | `enemy.startFleeing(...)`; 별도 SKAction sequence 5초 후 spawn 호출 | 낮음 (EnemyNode 변경 0) — 그러나 *타이머 중복* |
| 콜백 등록 | `enemy.startFleeing(duration: 5) { spawn.fire... }` | 중간 (EnemyNode 시그니처 확장 필요) — 타이머 1개 |

본 sprint는 **콜백 등록**. 이유:
- 타이머 중복 시 *어긋남* 위험 (도주 5초와 재스폰 5초가 *별도* 카운트)
- 콜백 = *EnemyNode 도주 종료 시점*에 *정확히* 발화 보장

> Spring 비유: 두 `@Scheduled` 작업을 *별도 5초*로 두기 vs `onComplete` 핸들러 1개. 후자가 *동기화* 측면에서 안전.

### 3-6. **AIRFORCE 이스터에그 *완성*** 🎉

| 단계 | sprint | 효과 |
|---|---|---|
| 1 | 4-4 | 오버레이 "나와라 박병장!" |
| 2 | 4-3 | 비행기 좌→우 |
| 3 | 4-5 | 폭탄 화면 플래시 |
| 4 | 4-6 | 수간호사 5초 도주 |
| 5 | **4-7** | **수간호사 복귀 후 F 즉시 발사** |

6 sprint(4-2~4-7) 누적, **GDD §7-7 완전 구현**. 각 sprint가 *1 sub-feature*로 분리돼 *외과 수술적*으로 추가됨.

### 3-7. **호출 측 변경 0 정책 *6 sprint* 종합**

| sprint | 새로 *건드린* 영역 |
|---|---|
| 4-2 | PhysicsCategory, StoneGuardNode, ContactRouter, GameScene |
| 4-3 | AirplaneNode (신규), GameConfig, GameScene, pbxproj |
| 4-4 | AirforceOverlayNode (신규), GameConfig, GameScene, pbxproj |
| 4-5 | BombFlashNode (신규), GameConfig, GameScene, pbxproj |
| 4-6 | **EnemyNode**(최소 변경), GameConfig, GameScene |
| 4-7 | **SpawnSystem**(wrapper 1개), EnemyNode(시그니처 확장), GameScene |

**6 sprint 동안 *건드린 적 없는* 영역**:
- PlayerNode / NoteNode / ProjectileNode / HUDNode / DPadNode
- ContactRouter (4-2 이후) / PhysicsCategory (4-2 이후) / StoneGuardNode (4-2 이후)
- GameScene+Setup
- TitleScene / ResultScene
- ColorTokens (`.ganhoYellowF` / `.ganhoPaper` 재사용)
- macOS / tvOS Sources phase

**6 sprint에 도입된 *새 영역***:
- 4-2: PhysicsCategory.stoneGuard, ContactRouter 분기
- 4-3~4-5: 3개 신규 노드 (자가 소멸 패턴)
- 4-6: EnemyNode 상태 머신 1차
- 4-7: closure parameter, public wrapper

*분리해서 작게* 만드는 정책이 *습관*으로 굳어진 단계.

---

## 4. 무엇을 만드나?

### 새 파일
**없음**.

### 고치는 파일 (4개)
| 파일 | 변경 |
|---|---|
| `Systems/SpawnSystem.swift` | `func fireImmediately()` public wrapper 1개 추가 (+~5줄) |
| `Nodes/EnemyNode.swift` | `startFleeing` 시그니처에 `onEnd: @escaping () -> Void = {}` 매개변수 추가 + sequence 마지막 run에 `onEnd()` 호출 (+~3줄) |
| `Config/GameConfig.swift` | (선택) 없음 — 추가 상수 불필요 (재스폰은 즉시 1회) |
| `GameScene.swift` | 헤더 MARK 1줄 + `enemy.startFleeing(...)` 호출에 콜백 추가 (3줄로 확장) + doc 1줄 (+~5줄) |

### Xcode pbxproj
- **변경 없음** — 신규 파일 0건.

### 한 그림으로

```
[Player가 StoneGuard 첫 통과]
        ↓
triggerAirforceEasterEgg()
        ├── 비행기 (4-3)
        ├── 오버레이 (4-4)
        ├── 폭탄 (4-5)
        └── enemy.startFleeing(5.0) { [weak self] in
                self?.spawnSystem.fireImmediately()   ← 4-7 신규
            }
              ↓
        EnemyNode 자체 SKAction.sequence:
          run { isFleeing=true } → wait(5) → run {
              isFleeing=false
              onEnd()    ← 4-7: 콜백 발화
          }
              ↓
        GameScene 콜백 안에서 spawnSystem.fireImmediately()
              ↓
        SpawnSystem.fireImmediately() → fireProjectile() (private wrapper 호출)
              ↓
        F 1발 즉시 발사 (player 위치 향해)
```

### 시간선 (밀리초)

| 시점 | 이벤트 |
|---|---|
| 0 | trigger 시작 (비행기 + 오버레이 + 폭탄 + 도주) |
| 5000 | 수간호사 isFleeing=false (추적 재개) + **F 1발 즉시 발사** ← 4-7 |
| 5000+ | 평소 fire 루프 정상 진행 |

---

## 5. 직접 확인할 것

⌘R 후:

| # | 시나리오 | 봐야 할 것 |
|---|---|---|
| (a) | 게임 시작, 석조무사 미접촉 | 평소대로 F 주기 발사 (4-6과 동일) |
| (b) | Player가 석조무사 첫 통과 | 비행기/오버레이/폭탄/도주(4-3~4-6 그대로) |
| (c) | 도주 중 (~3초) | 평소대로 F 자동 발사 루프 진행 (도주 영향 없음) |
| (d) | 도주 종료 시점 (~5초) | **수간호사 추적 재개 + F 1발 즉시 발사** (player 위치 향해) |
| (e) | 도주 종료 직후 | 평소 fire 루프 정상 진행 (재스폰 1발 외 추가 변경 없음) |
| (f) | 재통과 시 | 이스터에그 0 (airforceTriggered 가드) |
| (g) | 게임오버 시 도주 진행 중 | ResultScene 전환 시 ARC 자동 해제 + 콜백 실행 안 됨 (weak self) |
| (h) | F 동시 최대 도달 시 재스폰 | `currentProjectileCount() < projectileMaxConcurrent` 가드로 *무발사* (정상 — 게임 균형) |
| (i) | 빌드 SUCCEEDED + 경고 0 | 강제 언래핑 0, 매직 넘버 0, `@escaping` + 기본값 정확 |

> **핵심**: 도주가 *조용히 끝나는* 게 아니라 *F 1발*로 *위협 재개 신호*. AIRFORCE 시퀀스의 *마침표*.

---

## 6. 사용자 결정 (이미 합의)

| 결정 | 선택 | 왜 |
|---|---|---|
| 본 sprint 범위 | F 1회 즉시 발사만 | "초기 수 × 1.0 비율"의 GDD 문구 단순 해석 — 1회 발사 |
| 트리거 방식 | onEnd 콜백 매개변수 | 별도 SKAction 타이머보다 동기화 안전 |
| 콜백 매개변수 | `@escaping () -> Void = {}` default | 4-6 호출 사이트 *호환성 유지* |
| public wrapper | `fireImmediately()` 신설 | private fireProjectile 직접 노출 회피 |
| F 동시 최대 가드 | 그대로 (maxConcurrent 가드 통과 필요) | 게임 균형 유지 |
| OoS — 발사 주기 리셋 / F 개수 변경 | 금지 | "초기 수" 해석 모호 → 단순화 |
| OoS — 새 GameConfig 상수 | 금지 | 즉시 1회 발사라 상수 불필요 |

---

## 7. 회고

### 7-1. 막혔던 것

**없음.** 한 사이클 만점 합격(10.0/10).

### 7-2. 새로 배운 것

1. **Closure parameter — 함수가 *값*** — `onEnd: () -> Void`로 받아 매개변수처럼 전달.
2. **`@escaping` 키워드 의무** — 메서드 종료 후 SKAction 안에서 호출되므로 *반드시* `@escaping`. 누락 시 컴파일 에러.
3. **Default closure parameter `= {}`** — 4-6 호출 사이트(콜백 없음)와 시그니처 호환성 유지. *기존 호출자를 깨지 않으면서* 기능 확장.
4. **Trailing closure 문법** — `enemy.startFleeing(duration: 5) { ... }` 형태. 마지막 인자가 closure면 괄호 밖으로 빼냄. Swift 관용.
5. **Public wrapper 패턴** — `private fireProjectile()` + `public fireImmediately()`. 캡슐화 유지 + 의도 노출. private 직접 노출보다 *호출자가 의도를 명시*.
6. **콜백 등록 vs 별도 SKAction 타이머 비교** — 두 타이머 동기화 위험을 *콜백 1개*로 해소. Spring의 `onComplete` 핸들러와 동일.
7. **onEnd() 호출은 self 무관** — EnemyNode end run의 `[weak self]` 안에서 호출되지만, `onEnd` 자체는 closure 변수라 self가 nil이어도 호출됨. GameScene 측 `[weak self]`로 *콜백 본체에서* self 가드.
8. **AIRFORCE 이스터에그 *6 sprint 완성*** — 4-2(접촉 감지 골격) → 4-3(비행기) → 4-4(오버레이) → 4-5(폭탄) → 4-6(도주) → 4-7(F 재스폰). GDD §7-7 5단계 모두 구현.
9. **호출 측 변경 0 정책 6 sprint 종합** — 6 sprint 동안 *건드린 적 없는* 영역: PlayerNode/NoteNode/ProjectileNode/HUDNode/DPadNode/TitleScene/ResultScene/ColorTokens/macOS·tvOS/GameScene+Setup. *분리해서 작게* 만드는 정책이 *습관*으로 굳어진 단계.

> Spring 비유: 6개월간 한 도메인 기능을 *7번에 나눠* 출시. 각 PR이 *호출자 변경 0~최소*. 마이크로 PR 정책의 정착.

### 7-3. 다음으로 미룬 것

- **`protocol SelfDismissingNode` 추출 리팩터** — 3 노드(Airplane/Overlay/BombFlash) 공통 인터페이스 (별도 리팩터 sprint).
- **EnemyNode 상태 머신 enum 승격** — 세 번째 모드(stunned 등) 등장 시.
- **Phase 4-Z: 이교주 NPC** — 난이도 시스템 도입 후. GDD §7-8.
- **Phase 5: 캐릭터 선택 + 능동 스킬** — GDD §1 다음 페이즈.
- **사운드 효과** — Phase 6 (assets).

### 7-4. 평가 점수

- **가중평균: 10.0 / 10 — 만점 합격** 🎉
- 항목별: Swift 10 / 게임 로직 10 / 성능·안정성 10 / 기능 완성도 10
- P0/P1/P2 0건
- 빌드: BUILD SUCCEEDED, 경고 0건
- diff: 3 파일 (SpawnSystem ~6 / EnemyNode ~3 / GameScene ~5)

### 7-5. 핵심 가치 — *AIRFORCE 이스터에그 완성* 🎉

| sprint | 효과 | QA |
|---|---|---|
| 4-2 | 접촉 감지 골격 (PhysicsBody, ContactRouter stub) | 10.0 |
| 4-3 | 비행기 좌→우 | 10.0 |
| 4-4 | "나와라 박병장!" 오버레이 | 10.0 |
| 4-5 | 폭탄 화면 플래시 | 10.0 |
| 4-6 | 수간호사 5초 도주 | 10.0 |
| **4-7** | **F 재스폰 (복귀 시점)** | **10.0** |

**6 sprint × 10.0 = AIRFORCE 시퀀스의 완성**. *분리해서 작게* 만든 결과:
- 각 sprint diff 평균 *50~80줄*
- 호출 측 변경 평균 *3줄 이하*
- 기능 완성도 누적 100%

**보존된 영역 (6 sprint 종합 무변경)**:
- Player/Note/Projectile/HUD/DPad 노드
- TitleScene/ResultScene
- ColorTokens (`.ganhoYellowF` / `.ganhoPaper` / `.ganhoBloodAccent` 등 기존만)
- GameScene+Setup
- ContactRouter (4-2 신설 분기 외 본문 그대로)
- PhysicsCategory (4-2 비트 1개 추가 외)
- StoneGuardNode (4-1 그대로)
- macOS/tvOS Sources phase

**열린 영역 (각 sprint *최소* 변경)**:
- 4-2: PhysicsCategory +1비트, ContactRouter +1분기/콜백, StoneGuardNode PhysicsBody, GameScene +stub
- 4-3~4-5: 3개 신규 노드 (자가 소멸 패턴 × 3)
- 4-6: EnemyNode +10줄 (상태 머신 1차)
- 4-7: SpawnSystem +1메서드, EnemyNode +시그니처 확장, GameScene +2줄

**다음 단계 자연스러운 후보** — Rule of three 도달한 *자가 소멸 노드 패턴 protocol 추출* 또는 *enemy 상태 머신 enum 승격*. 둘 다 *리팩터 sprint*로 분리.

---

## 8. 다음 작업

```
[1] 시뮬레이터에서 §5 (a)~(i) 확인 (특히 (d): 5초 후 "팡!" F 발사)
[2] AIRFORCE 이스터에그 완성 🎉 — GDD §7-7 5단계 모두 구현
[3] 다음 sprint 후보:
    - `protocol SelfDismissingNode` 추출 리팩터 (Rule of three)
    - Phase 4-Z: 이교주 NPC (난이도 시스템 도입 후)
    - Phase 5: 캐릭터 선택 + 능동 스킬 (GDD §1)
```

> **이번 sprint 본질**: AIRFORCE 이스터에그 *마지막 조각*. 6 sprint 누적의 *완결*. `@escaping` closure parameter는 Swift의 *함수형 표현*이 처음 의미 있게 등장한 sprint — 미래의 protocol/delegate 패턴으로 가는 다리.
