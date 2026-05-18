# Phase 9-8 학습 노트 — 박병장 비행기 이스터에그 타이밍 맞추기

## 한 줄 요약

이미 만들어둔 "박병장이 비행기 부르는 코미디 연출"의 박자가 살짝 안 맞아서, **3개 숫자**를 바꾸고 **2줄짜리 안전망**을 깔았어요. 새 파일은 1개도 안 만들었습니다.

---

## 우리가 한 일 (그림으로 보면)

### Before (예전)

```
t=0.0   [트리거! 석조무사 닿음!]
        ┌─ "나와라 박병장!" 글씨 뜸 (1.8초 떠 있음)
        ├─ 수간호사 도망 시작 (5초)
        └─ 비행기 즉시 등장 (2초 동안 화면 가로지름)
t=1.0   비행기 가운데에서 폭탄 떨어짐 (섬광!)
t=1.8   글씨 사라짐
t=2.0   비행기 화면 밖으로 사라짐
t=5.0   수간호사 정상 모드 + F 1발
```

문제: **글씨가 있는데 비행기가 동시에 날아옴**. 시선이 분산돼서 코미디 박자가 깨졌어요.

### After (개선)

```
t=0.0   [트리거! 석조무사 닿음!]
        ┌─ "나와라 박병장!" 글씨 뜸 (2.4초 떠 있음)
        └─ 수간호사 도망 시작 (5초)
t=2.4   글씨 사라지자마자 → 비행기 좌측에서 등장
t=3.4   비행기 가운데 도달 → 폭탄 섬광!
t=4.4   비행기 우측으로 빠져나감
t=5.0   수간호사 정상 모드 + F 1발
```

좋아진 점: **글씨 다 사라진 뒤** 비행기가 등장 → 시선 집중 → "어? 진짜 부르네?" 코미디 비트 살아남.

---

## Spring Boot 출신 시선으로 보면

이건 정확히 **`@Value("${app.timing.overlay}")` 값을 application.yml에서 1.5 → 2.1로 바꾼 것**과 같아요.

| Spring Boot | 우리 게임 |
|---|---|
| `application.yml` | `GameConfig.swift` |
| `@Value("${...}")` | `GameConfig.airforceOverlayDisplayDuration` |
| 비즈니스 로직 안 건드림 | AirforceOverlayNode 등 노드 코드 0줄 변경 |

설정값만 외부 yml에서 바꾸면 서비스 코드는 그대로인 것처럼, 본 sprint도 **상수 3개 + 메서드 2개** 외에는 한 줄도 건드리지 않았습니다.

---

## "안전망" 2중 가드는 왜?

상 난이도(`.hard`)에서는 석조무사가 등장하면 안 됩니다. 이걸 **2겹**으로 막았어요.

### 1겹: setupStoneGuard 입구

```swift
func setupStoneGuard() {
    guard difficulty != .hard else { return }   // 여기!
    // ... worldNode.addChild(stoneGuard) ...
}
```

→ 그냥 worldNode에 안 넣음 → 충돌 자체가 발생 안 함.

### 2겹: triggerAirforceEasterEgg 입구

```swift
private func triggerAirforceEasterEgg() {
    if airforceTriggered { return }
    if difficulty == .hard { return }   // 여기!
    // ...
}
```

→ 혹시라도 미래에 누가 디버그 코드로 이 메서드를 직접 호출해도 안전.

### Spring Boot 비유

Spring에서 `@PreAuthorize("hasRole('ADMIN')")`를 컨트롤러에 붙이면서도, **서비스 메서드 안에서도** 권한을 한 번 더 검사하는 패턴이에요. "방어선 두 겹"이라고 부릅니다.

```java
// Spring
@PreAuthorize("hasRole('ADMIN')")           // ← 1겹 (Controller)
public void deleteUser(Long id) {
    securityService.checkAdmin();           // ← 2겹 (Service 안에서 또)
    userRepository.deleteById(id);
}
```

```swift
// 우리 게임 (똑같은 사고방식)
func setupStoneGuard() {
    guard difficulty != .hard else { return }   // ← 1겹 (등록 자체 안 함)
    ...
}
private func triggerAirforceEasterEgg() {
    if difficulty == .hard { return }            // ← 2겹 (호출돼도 안 발화)
    ...
}
```

미래에 누가 코드를 잘못 건드려도 이스터에그가 hard에서 발화되는 회귀 버그는 안 생깁니다.

---

## SKAction.sequence — "조금 있다가 해줘" 패턴

기존엔 비행기를 **즉시** cameraNode에 붙였어요:

```swift
// Before
let plane = AirplaneNode()
cameraNode.addChild(plane)                            // 즉시 부착
plane.crossScreen(sceneWidth: size.width, atY: y)     // 즉시 출발
```

이제는 **2.4초 기다린 뒤** 부착합니다:

```swift
// After
let plane = AirplaneNode()
let y = +(size.height / 2 - GameConfig.airplaneTopOffset)
let wait = SKAction.wait(forDuration: GameConfig.airplaneDelayAfterOverlay)
let attach = SKAction.run { [weak self] in
    guard let self = self else { return }
    self.cameraNode.addChild(plane)
    plane.crossScreen(sceneWidth: self.size.width, atY: y)
}
cameraNode.run(.sequence([wait, attach]))
```

### Spring Boot로 치면?

Spring에서 `@Scheduled(fixedDelay = 2400)` 같은 거예요. "지금 말고 2.4초 뒤에 실행해줘"라는 약속. 단, SpriteKit은 **씬에 묶여서** 동작하므로 씬이 사라지면 자동 취소됩니다 (메모리 누수 0).

### 왜 `[weak self]` 필수?

2.4초 뒤에 실행되는 클로저인데, 그 사이에 게임이 끝나서 `GameScene`이 메모리에서 해제될 수 있어요. `self`를 strong으로 잡으면 씬이 못 사라집니다 (메모리 누수). `weak self`로 잡고 `guard let self = self else { return }`로 살아있는지 확인.

Spring에서 `WeakReference<UserCache>` 쓰는 거랑 똑같은 사고방식이에요.

### 왜 `Timer.scheduledTimer` 안 썼나?

Swift에는 `Timer.scheduledTimer`도 있지만 SpriteKit에서는 금기예요. 이유:

1. 씬 일시정지(pause) 시 Timer는 계속 돌아감 → 잘못된 시점에 발화
2. 씬 종료 시 자동 정리 안 됨 → 명시적 `invalidate()` 필요 → 깜빡하면 메모리 누수
3. SKAction은 씬의 시간 흐름에 묶여 있어서 자동으로 일시정지/정리됨

**규칙: SpriteKit 안에서는 무조건 `SKAction.wait`.**

---

## 매직 넘버를 GameConfig로 모은 이유

본 sprint에서 **GameScene 본문에 숫자 리터럴이 1개도 안 생겼어요**. 모든 값이 `GameConfig.xxx` 형태입니다.

```swift
// 좋음 (우리 코드)
let wait = SKAction.wait(forDuration: GameConfig.airplaneDelayAfterOverlay)

// 나쁨 (만약 매직 넘버 썼다면)
let wait = SKAction.wait(forDuration: 2.4)
```

만약 매직 넘버였다면, 나중에 디자이너가 "2.4초가 너무 길어요, 2.0으로 줄여주세요"라고 했을 때:
- GameScene.swift에서도 찾아 바꿔야 하고
- 다른 파일에 같은 숫자 또 있을지 검색해야 하고
- 의미 모르는 후임자가 "이 2.4가 뭐지?" 헷갈림

상수로 모아두면 **이름**이 의미를 말해줍니다(`airplaneDelayAfterOverlay`).

Spring Boot의 `@ConfigurationProperties`로 모든 설정 한 곳에 모으는 거랑 똑같아요.

---

## 바뀐 파일 / 줄 수

| 파일 | 변경량 | 신규 추가 |
|---|---|---|
| `Config/GameConfig.swift` | 상수 2개 값 변경 + 1개 신규 + 주석 갱신 | `airplaneDelayAfterOverlay = 2.4` |
| `GameScene.swift` | `triggerAirforceEasterEgg` 본문만 재배치 | hard 가드 1줄 + 비행기 지연 attach 7줄 |
| `GameScene+Setup.swift` | `setupStoneGuard` 첫 줄 가드 | hard 가드 1줄 |
| **신규 파일** | **0개** | - |

**원칙 준수**:
- 강제 언래핑 0 (`!` 없음)
- Timer 0 (전부 SKAction)
- weak self 캡처 (지연 클로저 안)
- 매직 넘버 0 (모두 GameConfig 경유)

---

## 시뮬레이터에서 직접 확인하는 법

1. 빌드 후 시뮬레이터 실행
2. **easy 난이도** 선택
3. 김간호로 좌하단의 **석조무사**(돌무사)에 닿기
4. 다음 순서를 확인:
   - `t=0`: "나와라 박병장!" 글씨 화면 중앙에 큼지막하게 뜸
   - `t=0`: 수간호사가 갑자기 도망가기 시작
   - `t=2.4`: 글씨 다 사라진 직후 → 좌측에서 비행기 등장
   - `t=3.4`: 비행기 중앙 도달 → 화면 누런 섬광!
   - `t=4.4`: 비행기 우측으로 빠짐
   - `t=5.0`: 수간호사 정상 추격 + F 1발 발사
5. **다시 석조무사에 닿기** → 아무 일 안 일어남 (1회 한정 가드)
6. **재시작 후 hard 난이도** 선택 → 석조무사 자체가 없음 (이교수만 활동)
7. **재시작 후 easy** → 다시 1회 발화 가능

---

## 정리

이번 sprint는 "**이미 만든 기능을 사용자가 원하는 박자로 정밀 보정**"이었습니다.
새 노드/픽셀 아트/액션 없이, **상수 3개 + 가드 2줄 + SKAction.sequence 1개**로 끝.

이렇게 작은 변경으로 큰 효과를 낼 수 있는 건, Phase 4-3 ~ 4-7에서 **시그니처를 안 바꿔도 되게** 잘 설계해 둔 덕분이에요. 좋은 설계의 보상.
