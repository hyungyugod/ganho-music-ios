# 29 · Phase 4-6 · 수간호사 5초 도주 모드 — *방향만 반대로* 🏃

> **이번 작업 한 줄**: 폭탄이 터지자 수간호사가 *겁먹고* 5초간 플레이어 반대 방향으로 도망간다. EnemyNode에 *도주 상태*를 추가해 추적 방향만 반전. 4-2~4-5 동안 *호출 측 변경 0*이었던 정책이 *처음으로 깨지는* sprint — **EnemyNode 변경 불가피**.

---

## 1. 왜?

GDD §7-7 AIRFORCE 이스터에그 시퀀스:
1. ✅ 오버레이 (4-4)
2. ✅ 비행기 (4-3)
3. ✅ 폭탄 (4-5)
4. ⬜ **수간호사 5초 공포 도주** ← 본 sprint
5. ⬜ 수간호사 복귀 후 F 재스폰 (4-7)

폭탄이 터진 *직후* 수간호사가 *5초간* 플레이어 반대 방향으로 도망. *게임 로직에 영향을 주는 첫 이스터에그 효과* — 그동안 시각만이었으나 본 sprint부터는 *적의 행동*이 바뀐다.

> Spring 비유: 4-3~4-5가 *로깅/알림*이었다면, 4-6은 *서비스 메서드의 상태 변경*. 부가 작용이 도메인 객체로 *전파*되는 단계.

---

## 2. Spring 비유 ⭐

| SpriteKit | Spring | 한 줄 설명 |
|---|---|---|
| `EnemyNode.isFleeing: Bool` | `@State boolean fleeing` | "도주 상태 플래그" |
| `EnemyNode.startFleeing(duration:)` | `@Async cooldown(duration)` | "일정 시간 후 자동 복귀" |
| `SKAction.sequence([run {fleeing=true}, wait, run {fleeing=false}])` | scheduled task chain | "켜고 → 대기 → 끄고" |
| `update`에서 방향 반전 | strategy pattern (1줄 분기) | "플래그에 따라 행동 변경" |
| `GameScene.triggerAirforceEasterEgg() → enemy.startFleeing(...)` | facade 호출 | "외부는 메서드만 호출, 내부는 알아서" |

**핵심**: GameScene은 EnemyNode *내부 상태*에 직접 접근하지 않는다. `startFleeing(duration:)` 메서드만 부른다. *책임 분리*.

---

## 3. 새로 배운 것 (Swift/SpriteKit) ⭐

### 3-1. **상태 머신 패턴 — `Bool` flag로 시작**

```swift
final class EnemyNode: SKSpriteNode {
    var isFleeing: Bool = false
    
    func update(...) {
        let direction: CGFloat = isFleeing ? -1 : 1
        physicsBody?.velocity = CGVector(dx: unitX * speed * direction,
                                          dy: unitY * speed * direction)
    }
}
```

**의도**: *현재* 모드가 2가지뿐 — *추적 / 도주*. Bool로 충분. 모드가 3개 이상이 되면 `enum AIState { case chase, flee, stunned }`로 승격.

> "Rule of three" — 모드 2개까지는 Bool, 3개 등장 시 enum. *추상화는 두 번 본 후*.

### 3-2. **방향 반전 = 단위 벡터에 -1 곱하기**

`update`의 기존 추적:
```swift
let unitX = dx / magnitude   // player 방향 단위 벡터
let unitY = dy / magnitude
velocity = CGVector(dx: unitX * speed, dy: unitY * speed)
```

도주 추가:
```swift
let direction: CGFloat = isFleeing ? -1 : 1
velocity = CGVector(dx: unitX * speed * direction,
                     dy: unitY * speed * direction)
```

**중학교 수학**: 같은 벡터에 *-1*을 곱하면 반대 방향. 길이는 같음(속도 그대로).

> Spring 비유: 같은 컨트롤러가 *response status*만 200/500 분기. 같은 로직, 결과만 반전.

### 3-3. **`SKAction.run { closure }` — 시간 흐름 안에 *코드 실행* 삽입**

```swift
let start = SKAction.run { [weak self] in self?.isFleeing = true }
let wait  = SKAction.wait(forDuration: 5.0)
let end   = SKAction.run { [weak self] in self?.isFleeing = false }
run(.sequence([start, wait, end]))
```

`SKAction.run`은 *지정한 시점*에 *Swift 코드 한 줄*을 실행. SKAction 시퀀스 안에서 *상태 변경*을 자연스럽게 끼움.

**시각 동작 없는** SKAction이라는 점이 핵심. *시간 마디*만 만들어줌.

> Spring 비유: `@Scheduled` 작업 내부에 `setFleeing(true)` 호출, `sleep(5000)`, `setFleeing(false)`. 그러나 SpriteKit은 *스레드 블록 없이* 게임 루프 친화적.

### 3-4. **`[weak self]` 캡처 — 메서드 내부 SKAction에서 의무**

```swift
let start = SKAction.run { [weak self] in self?.isFleeing = true }
```

self를 *클로저 안*에서 직접 참조하면 *강한 캡처*. SKAction이 노드를 유지하고 노드가 SKAction을 유지 → 순환 참조 가능성. `[weak self]`로 방지.

본 sprint에서 `[weak self]`가 *처음 의미 있게 도입*. 4-2~4-5는 *외부 클로저*에서만 사용, 4-6은 *노드 *자체* SKAction.run 클로저* 안.

### 3-5. **EnemyNode 책임 — *자기 상태는 자기가 관리***

```swift
// EnemyNode
func startFleeing(duration: TimeInterval) {
    // 이미 도주 중이면 무시 (재호출 방지)
    if isFleeing { return }
    let start = SKAction.run { [weak self] in self?.isFleeing = true }
    let wait  = SKAction.wait(forDuration: duration)
    let end   = SKAction.run { [weak self] in self?.isFleeing = false }
    run(.sequence([start, wait, end]))
}

// GameScene
enemy.startFleeing(duration: GameConfig.enemyFleeDuration)
```

GameScene은 *호출만*, EnemyNode는 *상태 토글 + 타이머 + 복구* 전부 담당.

**나쁜 패턴 (피해야 할)**:
```swift
// GameScene이 EnemyNode 내부에 직접 접근
enemy.isFleeing = true
DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
    enemy.isFleeing = false
}
```

**문제**:
- EnemyNode 내부 변경 시 GameScene도 수정해야 함 (결합도 ↑)
- `DispatchQueue.main.asyncAfter`는 *게임 일시정지 무관*하게 실행 (게임 멈춰도 5초 후 켜짐)
- `[weak self]` 누락 시 메모리 누수

> Spring 비유: 도메인 객체가 *자기 일생*(invariant)을 책임짐. 컨트롤러가 *외과수술*하지 않음.

### 3-6. ***호출 측 변경 0* 정책이 깨지는 첫 sprint**

4-2 → 4-3 → 4-4 → 4-5 4 sprint 동안 *ContactRouter / PhysicsCategory / StoneGuardNode / GameScene+Setup / 다른 노드*가 0줄 변경이었다. 본 sprint는 **EnemyNode 변경 불가피** — 도주 상태가 EnemyNode 내부 행동.

**그러나 *최소한*으로 변경**:
- `update` 본문에 *1줄 분기* (direction 곱셈)
- `isFleeing` 프로퍼티 1줄
- `startFleeing(duration:)` 메서드 1개

EnemyNode 외 다른 노드는 여전히 0줄. GameScene도 *1줄 호출만* 추가.

> 정책이 *깨지는* 게 아니라 *해당 도메인에 한정해 *최소* 변경* — 정책의 *제한된 위반*.

### 3-7. **재호출 방지 가드**

```swift
func startFleeing(duration: TimeInterval) {
    if isFleeing { return }   // 이미 도주 중이면 무시
    ...
}
```

본 게임 로직상 *이스터에그가 1회 한정*이라 재호출 가능성 0이지만, *방어 코드*로 가드를 둠. 미래에 다른 곳에서 호출해도 안전.

> AirplaneNode·AirforceOverlayNode·BombFlashNode는 *매번 새 인스턴스*라 가드 불필요. EnemyNode는 *씬에 1개 영구*라 가드 필요.

---

## 4. 무엇을 만드나?

### 새 파일
**없음**.

### 고치는 파일 (3개)
| 파일 | 변경 |
|---|---|
| `Nodes/EnemyNode.swift` | `isFleeing: Bool` 프로퍼티 + `startFleeing(duration:)` 메서드 + `update`에 direction 분기 |
| `Config/GameConfig.swift` | Airforce 섹션에 `enemyFleeDuration` 1상수 추가 |
| `GameScene.swift` | 헤더 MARK 1줄 + `triggerAirforceEasterEgg()` 본문 끝에 도주 호출 1줄 + doc 1줄 |

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
        └── 수간호사 도주 (4-6)  ← 새로 추가
              ↓
        enemy.startFleeing(duration: 5.0)
              ↓
        EnemyNode 자체 SKAction.sequence:
          run { isFleeing = true } → wait(5.0) → run { isFleeing = false }
              ↓
        그동안 EnemyNode.update의 velocity가 player 반대 방향으로
              ↓
        5초 후 자동 복귀 (다시 player 추적)
```

### 시간선 (밀리초)

| 시점 | 이벤트 |
|---|---|
| 0 | trigger 시작 (비행기 + 오버레이 + 폭탄 + 도주 동시) |
| 2520 | 폭탄 fadeOut 끝 (이스터에그 시각 종료) |
| 5000 | 수간호사 도주 종료 → 재추적 시작 |

> 폭탄 시각 효과(2.52s)와 도주(5.0s)는 서로 *독립적*. 폭탄 끝나도 도주는 계속. 게임플레이상 *적이 약 5초 뒤*에 다시 위협. 사용자에게 *짧은 안전 구간*.

---

## 5. 직접 확인할 것

⌘R 후:

| # | 시나리오 | 봐야 할 것 |
|---|---|---|
| (a) | 게임 시작, 석조무사 미접촉 | 수간호사 정상 추적 (4-5와 동일) |
| (b) | Player가 석조무사 첫 통과 | 비행기/오버레이/폭탄(4-3~4-5) + **수간호사가 *플레이어 반대* 방향으로 움직임** |
| (c) | 도주 중 (~2초) | 수간호사가 player에서 *멀어짐*. 외곽 벽에 닿으면 *벽 따라 이동* (충돌 박스로 막힘) |
| (d) | 도주 중 (~4초) | 여전히 도주 중. 속도는 평소와 동일 (시간 보간 그대로 — 빠르지도 느리지도 X) |
| (e) | 5초 경과 후 | **수간호사가 다시 player 추적 시작**. 매끄러운 전환 |
| (f) | 도주 중 player가 적극 추격 | 수간호사가 도망가다 *부딪히면* 게임오버 — 정상 (contactBitMask 그대로) |
| (g) | 재통과 시 | 이스터에그 0 (airforceTriggered 가드 그대로). 도주 0 |
| (h) | 게임오버 시 도주 진행 중 | ResultScene 전환 시 EnemyNode 트리 ARC 자동 해제 |
| (i) | F 투사체 | F 발사는 SpawnSystem 책임 — 도주 중에도 정상 발사 (다음 sprint 4-7에서 *재스폰* 효과 추가) |

> **핵심**: 도주는 *적 행동 변화*만. 점수/HUD/F/게임오버는 정상 진행.

---

## 6. 사용자 결정 (이미 합의)

| 결정 | 선택 | 왜 |
|---|---|---|
| 본 sprint 범위 | 수간호사 5초 도주만 | F 재스폰은 다음 sprint(4-7) |
| 상태 표현 | `Bool isFleeing` | 모드가 2개뿐 — Bool 충분. 3개 시 enum 승격 |
| 도주 속도 | enemyBaseSpeed/MaxSpeed 시간 보간 *그대로* | GDD 명시 없음. 일관성 위해 평소와 동일 |
| 방향 반전 | unitX/Y * -1 (전체 -1 곱) | 중학교 벡터 수학 |
| 타이머 메커니즘 | EnemyNode 자기 SKAction | DispatchQueue 금지 (게임 일시정지 친화) |
| 책임 분리 | EnemyNode가 자기 상태 관리, GameScene은 호출만 | 결합도 ↓ |
| 도주 중 collision | 정상 (게임오버 가능) | GDD 명시 없음 — 단순함 우선 |
| 재호출 가드 | `if isFleeing { return }` | 방어 코드 |
| OoS — F 재스폰 | 금지 | 4-7 |
| OoS — Player/Note/Projectile/Stone 노드 변경 | 금지 | 본 sprint는 EnemyNode + GameScene + GameConfig만 |

---

## 7. 회고

### 7-1. 막혔던 것

**없음.** 한 사이클 만점 합격(10.0/10).

### 7-2. 새로 배운 것

1. **`SKAction.run { closure }` — 시간 흐름에 *Swift 코드 한 줄* 끼우기** — 시각 효과 없는 SKAction. *시간 마디*만 만들고 그 시점에 클로저 실행. `start (run) → wait → end (run)` 3단 토글 패턴.
2. **`[weak self]` 캡처 — 노드 자체 SKAction에서 *의무*** — SKAction이 노드를 유지하고 노드가 SKAction을 유지 → 순환 참조 가능. 본 sprint가 `[weak self]`가 처음 *의미 있게* 도입된 sprint.
3. **상태 머신 시작 — `Bool` flag 단계** — 모드 2개(추적/도주)는 Bool로 충분. 3개 등장 시 `enum AIState` 승격. Rule of three.
4. **방향 반전 = 단위 벡터 × -1** — 속도(magnitude)는 그대로, 방향만 반전. 중학교 벡터 수학.
5. **재호출 가드 패턴** — 영구 노드(EnemyNode)는 `if isFleeing { return }` 가드 필요, 일회성 인스턴스(Airplane/Overlay/BombFlash)는 *매번 새 인스턴스*라 불필요.
6. **DispatchQueue/Timer 금지 → SKAction 의무** — *게임 일시정지 친화*. SKAction은 `scene.isPaused` 시 자동 멈춤, DispatchQueue는 *실시간*으로 흐름.
7. **direction 위치는 *최종 velocity 한 곳*에서만** — `unitX = (dx/magnitude) * direction` 같은 식으로 *분기를 여러 줄*에 흩뜨리면 디버깅 어려움. 한 줄에 집중.
8. **호출 측 변경 0 정책의 *제한된 위반*** — 4-2~4-5 4 sprint 동안 정책 유지. 본 sprint는 EnemyNode 변경 불가피 — *그러나 최소화*. 정책의 *완전한 깨짐*이 아닌 *해당 도메인 한정 외과수술*.
9. **책임 분리 — 도메인 객체가 자기 일생 관리** — GameScene은 `enemy.startFleeing(duration:)` 한 줄만 호출. EnemyNode 내부에서 *상태 + 타이머 + 복귀*까지 캡슐화.

> Spring 비유: `@Service` 메서드가 *내부 cooldown*까지 책임짐. 컨트롤러는 외과수술 X. 도메인 invariant 보호.

### 7-3. 다음으로 미룬 것

- **4-7: 수간호사 복귀 후 F 재스폰** — SpawnSystem 확장. AIRFORCE 이스터에그 5/5단계 완성.
- **`protocol SelfDismissingNode` 추출** — 3 노드 공통 인터페이스 (별도 리팩터 sprint).
- **EnemyNode 상태 머신 enum 승격** — *세 번째 모드*(stunned 등) 등장 시.
- **사운드 효과** — Phase 6.

### 7-4. 평가 점수

- **가중평균: 10.0 / 10 — 만점 합격** 🎉
- 항목별: Swift 10 / 게임 로직 10 / 성능·안정성 10 / 기능 완성도 10
- P0/P1/P2 0건
- 빌드: BUILD SUCCEEDED, 경고 0건
- diff: 3 파일 +22줄 (EnemyNode +16 / GameConfig +3 / GameScene +3)

### 7-5. 핵심 가치 — *제한된 정책 위반의 최소화*

| 보존된 것 | 변경 0건 |
|---|---|
| AirplaneNode / AirforceOverlayNode / BombFlashNode | ✅ |
| ContactRouter / PhysicsCategory / StoneGuardNode | ✅ |
| GameScene+Setup | ✅ |
| 기존 GameConfig 상수 (airplane 4 + airforceOverlay 3 + bombFlash 3 + 그 외) | ✅ |
| 기존 trigger 본문 10줄 (가드 2 + 비행기 4 + 오버레이 3 + 폭탄 3) | ✅ |
| Player/Note/Projectile/HUD/DPad | ✅ |
| TitleScene/ResultScene/ColorTokens | ✅ |
| `update()` 게임 루프 / `endGame()` / `airforceTriggered` 가드 | ✅ |
| `contactBitMask` / `collisionBitMask` | ✅ |
| macOS/tvOS Sources phase / pbxproj | ✅ |

**EnemyNode 한정 변경 + GameScene 1줄 추가 + GameConfig 1상수**. 정책이 *깨졌다*기보다는 *해당 도메인에만 외과 수술적으로* 적용. 5 sprint 만에 처음으로 EnemyNode를 건드렸지만 *최소한*. 다음 sprint(4-7)는 SpawnSystem 변경이 불가피 — 또 다른 도메인이 *최소한*으로 열림.

---

## 8. 다음 작업

```
[1] 시뮬레이터에서 §5 (a)~(i) 확인 (특히 (b) 도주 시작, (e) 5초 후 재추적)
[2] 다음 sprint: Phase 4-7 (수간호사 복귀 후 F 재스폰)
```

> **이번 sprint 본질**: *호출 측 변경 0* 정책이 *EnemyNode 한정*으로 깨지는 첫 sprint. 그러나 변경을 *최소화*(프로퍼티 1줄 + 메서드 1개 + update 분기 1줄)해 외과 수술적 변경을 *최대한* 유지. *책임 분리*가 EnemyNode 내부에 *상태 머신*을 도입하는 첫 단계.
