# Phase 6-6 — AVAudioSession Interruption 처리

## 한 줄 요약
게임 도중 **전화/Siri/타이머 알람** 같은 시스템 인터럽션이 와도 BGM이 영영 끊긴 채 사라지지 않게 했어요. 인터럽션이 시작되면 즉시 일시정지, 끝나면 6-5의 페이드 인을 타고 자연스럽게 되살아나요. **외부 코드는 한 글자도 안 바꿨고** — BGMPlayer 내부에서만 매너 있게 처리해요.

---

## 무엇을 했나요?

BGMPlayer 안에 네 가지 새 식구가 들어왔어요.

1. **옵저버 등록**: init 끝에서 `NotificationCenter`에 "전화 오면/끝나면 알려줘"라고 신청.
2. **deinit 신설**: BGMPlayer가 죽을 때 옵저버를 깔끔하게 정리.
3. **`handleInterruption`**: 시스템이 알려주는 인터럽션 이벤트를 받아 began/ended로 분기.
4. **private `pause()` / `resume()`**: 실제 동작을 처리하는 *내부 손잡이* (외부 노출 X).

`GameScene.swift` / `AudioManager.swift` / `HapticsManager.swift` / `GameConfig.swift` — **0줄 변경**. 좁은 인터페이스의 보상이에요.

---

## 왜 이게 필요했을까? — "전화는 인생의 주인공"

게임 BGM이 깔린 채 게임을 즐기다가 전화가 왔다고 해봐요.

**나쁜 앱**: BGM이 계속 깔린 채 통화. 상대방 목소리 안 들리고, 끊고 나면 BGM은 모르게 잠시 끊긴 뒤 영원히 안 돌아옴.

**좋은 앱**: 전화 시작과 동시에 BGM 즉시 멈춤. 통화 끝나고 게임 화면 돌아오면 BGM이 자연스럽게 페이드 인으로 살아남.

> **이번 sprint의 한 줄 정리**: *BGM은 게임의 주인공이지만, 전화는 인생의 주인공이다. 우리는 잠시 빠져 준다.*

iOS는 이런 일을 위해 표준 방식을 제공해요 — `AVAudioSession.interruptionNotification`. 우리는 그걸 받기만 하면 돼요.

---

## NotificationCenter 옵저버 — iOS의 이벤트 버스

스프링 출신이라면 이렇게 비유할 수 있어요.

```java
// Spring
@EventListener
public void onAudioInterruption(InterruptionEvent event) {
    if (event.getType() == BEGAN) pause();
    else if (event.getType() == ENDED && event.shouldResume()) resume();
}
```

iOS에서는 이렇게 써요.

```swift
// iOS — addObserver로 명시 등록
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleInterruption(_:)),
    name: AVAudioSession.interruptionNotification,
    object: AVAudioSession.sharedInstance()
)
```

**같은 패턴, 다른 마법 수준**:
- Spring은 컨테이너가 메서드 시그니처만 보고 자동 연결 (마법 ↑)
- iOS는 직접 등록/해제 챙겨야 함 (마법 ↓, 제어 ↑)

`NotificationCenter`가 곧 iOS의 `ApplicationEventPublisher`예요. 전화/Siri/화면 회전/키보드 등장 등 시스템 이벤트가 모두 여기로 흘러요.

---

## 어려웠던 점 1 — "옵저버를 어디서 등록할까?"

답: **`player = p` *이후*에**.

이유: 음원 파일(`bgm.m4a`)이 없으면 `player`가 `nil`이 되고 play/stop 모두 noop이에요. 그런 환경에서 옵저버를 등록하면? **불필요한 등록이 NotificationCenter에 쌓여요**. 전화 와도 응답할 일이 없는데 알림은 계속 받음 — 자원 낭비.

```swift
init() {
    guard let url = ...        // 음원 없음? 여기서 끝.
    guard let p = try? ...     // 디코딩 실패? 여기서 끝.

    try? AVAudioSession...      // 카테고리 설정
    p.numberOfLoops = -1
    p.volume = 0
    p.prepareToPlay()
    player = p                  // ← 여기서 player가 채워짐

    // ↓ 이 자리가 핵심 — 두 guard를 모두 통과한 *이후*에만 옵저버 등록
    NotificationCenter.default.addObserver(...)
}
```

이게 **"실패 빠르게(fail fast)"** 패턴이에요. 일찍 끝낼 수 있으면 일찍 끝낸다.

> **Spring 비유**: `@PostConstruct` 안에서 외부 자원(DB 연결, 파일 핸들) 가져오기 전에 설정값을 먼저 검증하는 것과 똑같아요. 검증 실패면 빈 등록 자체를 포기.

---

## 어려웠던 점 2 — "옵저버는 언제 풀어야 할까?"

답: **`deinit`에서**.

iOS의 NotificationCenter는 **`addObserver(_:selector:name:object:)` 형식이 옵저버를 약참조**해요. 즉 self가 ARC로 해제되면 알아서 옵저버 등록도 사라지긴 합니다.

근데 *명시적으로* `removeObserver(self)`를 부르는 게 **표준 안전 패턴**이에요. 이유:
1. **명료성**: 코드를 읽는 사람한테 "init에서 등록한 거 deinit에서 풀고 있다"는 의도가 보임.
2. **마이그레이션 안전**: 만약 나중에 block 기반 `addObserver(forName:queue:using:)`으로 바꾸면 그건 강참조라 명시 해제 필수. 미리 패턴을 들여놓음.

```swift
deinit {
    NotificationCenter.default.removeObserver(self)
}
```

> **Spring 비유**: `@PostConstruct`로 잡은 자원을 `@PreDestroy`에서 닫는 패턴. **등록한 횟수만큼 정확히 해제** — 라이프사이클 매칭의 절대 원칙.

**학생 비유**: 도서관에서 책 빌렸으면 반납해야 해요. 안 하면 다음에 빌리려는 사람도 곤란하고, 책 자체가 사라져도 도서관 시스템엔 "아직 빌려준 상태"로 남아요.

---

## 어려웠던 점 3 — "`@objc`는 왜 필요해?"

`#selector(...)`를 쓰려면 메서드가 **Objective-C 런타임**에 노출되어야 해요. Swift는 기본적으로 Obj-C 런타임에 노출되지 않으니 `@objc` 어노테이션으로 명시.

```swift
@objc private func handleInterruption(_ notification: Notification) { ... }
//   ↑ 이게 빠지면 #selector(...) 시 런타임 크래시
```

왜 NotificationCenter는 Obj-C 런타임을 쓰나요? iOS 자체가 Obj-C 기반으로 시작했고, selector 디스패치 메커니즘이 거기 있어요. Swift는 그 위에 얹은 거라 옛 메커니즘을 쓸 때마다 `@objc`로 "이건 옛 시스템과 호환되게 해줘"라고 알려야 해요.

> **Spring 비유**: 자바 8 이전 코드와 호환을 위해 람다를 익명 클래스로 변환하는 패턴과 비슷. 신구 런타임 사이의 다리.

**대안**: 블록 기반 옵저버 (`addObserver(forName:object:queue:using:)`)를 쓰면 `@objc` 안 써도 돼요. 다만 그건 반환된 토큰을 보관해야 하고 강참조 처리도 다른 차원의 일. 본 sprint는 selector 방식이 더 단순.

---

## 어려웠던 점 4 — "began은 즉시, ended는 페이드 인 — 왜 비대칭?"

이번 sprint의 핵심 미학.

**began (인터럽션 시작)**: `pause()`로 *즉시* 멈춤. 페이드 0.5초 같은 거 없음.
- 이유: 전화 벨소리가 울리는데 BGM이 0.5초 동안 천천히 사라지면 두 소리가 겹쳐서 어색해요. 전화는 즉시 무대 주인공.

**ended (인터럽션 종료)**: `resume()` → `play()` → 6-5의 페이드 인 1.5초.
- 이유: 통화 끝내고 게임 화면에 돌아왔을 때 BGM이 *부드럽게* 살아나는 게 자연스러워요. 갑자기 1.0 볼륨으로 튀어나오면 놀람.

**한 줄로**: *나갈 때는 빠르게, 돌아올 때는 천천히.* 사람의 감정선도 비슷하잖아요.

---

## DRY의 우아함 — `resume()`이 한 일

`resume()` 함수를 봐보세요.

```swift
private func resume() {
    play()
}
```

**한 줄.** 끝.

왜 이렇게 짧을까요? 6-5에서 이미 `play()`를 잘 만들어 뒀거든요:
- volume = 0으로 리셋 ✓
- player.play() ✓
- setVolume(1.0, fadeDuration:) ✓
- isPlaying 가드 ✓
- stopWorkItem 취소 ✓

`resume()`이 하고 싶은 일이 **정확히 `play()`가 하는 일**이에요. 그럼 한 번 더 안 쓰고 그냥 부르면 돼요.

이게 **DRY (Don't Repeat Yourself)** 원칙이에요. 같은 로직 두 번 안 쓴다.

> **Spring 비유**: 컨트롤러에서 "신규 등록"과 "재등록" 둘 다 결국 `userService.register(user)`만 부르면 되는 상황. 굳이 `reregister`라는 별도 메서드를 안 만들고 같은 `register`를 부르는 게 깔끔.

만약 `resume()`에서 페이드 인 로직을 또 작성했다면? 6-5의 페이드 인 시간을 바꿀 때 *두 곳을 동시에* 고쳐야 해요. 그러다 한 곳을 잊으면 버그.

**한 줄짜리 함수가 정말 많은 일을 한다** — 이게 좋은 설계의 흔적이에요.

---

## 좁은 인터페이스의 보상 — 외부 코드 0줄 변경

신규 추가된 메서드 4개:
- `deinit` — 시스템이 자동 호출
- `handleInterruption(_:)` — `@objc private` (NotificationCenter만 호출)
- `pause()` — `private`
- `resume()` — `private`

**전부 private 또는 deinit**. 즉 외부에서 호출할 수 있는 메서드는 6-5와 동일하게 `play()` / `stop()` 두 개.

이게 **Narrow Interface (좁은 인터페이스)** 원칙이에요. 외부에 *최소한*만 노출.

> **Spring 비유**: 컨트롤러는 서비스의 `public` 메서드만 알면 돼요. 트랜잭션 매니징, 이벤트 발행, 캐시 무효화 같은 내부 일은 모름. 만약 그게 다 public이었으면 외부에서 잘못 부를 위험.

결과: **GameScene에서 6-4/6-5/6-6 모두 같은 `bgm.play()` / `bgm.stop()` 호출만으로 사용**. BGMPlayer 내부 진화는 외부에 0의 충격.

학생 비유: "식당에서 손님은 '주문/계산'만 알면 된다. 주방에서 불을 잠깐 줄였다가 다시 켜는 건 셰프 몫."

---

## 페이드 아웃 도중 인터럽션 — `isFadingOut` 가드의 통찰

희귀한 시나리오 하나:

1. 게임이 막 끝나서 `stop()` 호출됨
2. BGM이 1초 페이드 아웃 진행 중 (`isFadingOut = true`, `stopWorkItem` 예약됨)
3. 그 순간 전화가 옴 → `handleInterruption(.began)` 호출됨
4. `pause()` 부르려 함

여기서 `pause()`가 그냥 `player.pause()`를 부르면 어떻게 될까요?

- `player.pause()`로 멈춤 → 0.5초 뒤 `stopWorkItem`이 `player.stop()` 호출
- pause된 player에 stop이 들어가서 의미적 충돌 (멈춰 있는데 또 멈추라고)
- 더 큰 문제: 통화 끝나고 ended가 와도 우리는 페이드 아웃 마무리 중이었으므로 *resume이 의미 없음*

해결: **`isFadingOut`이 true면 pause() 자체를 noop**.

```swift
private func pause() {
    guard let player = player else { return }
    if isFadingOut { return }   // ← 이 한 줄이 본 sprint의 가장 똑똑한 가드
    player.pause()
}
```

정책: **"이미 끝나는 중인 음악은 그냥 끝나게 둔다."** 어차피 게임이 끝났으니까 BGM도 끝나는 게 맞아요. 도중에 통화가 와도 페이드 아웃은 그대로 흘러서 자연 종료.

---

## `@unknown default` — 미래에 대한 예의

```swift
switch type {
case .began: pause()
case .ended: ...
@unknown default: break
}
```

`@unknown default`는 Apple이 향후 InterruptionType에 새 case를 추가할 때 **컴파일러가 경고로 알려주는** 패턴이에요. 평범한 `default:`로만 두면 새 case가 묻혀 들어와도 모름.

> **Spring 비유**: `enum` switch 시 향후 enum이 확장될 수 있다는 가정 하에 마지막에 `IllegalStateException`을 던지는 패턴과 비슷. forward-compat 안전망.

작은 사고예방이지만 **API 디자이너로서 미래 자신에게 친절한** 디테일.

---

## 이번 sprint의 한 줄 교훈

**"시스템과 협상하는 매너가 곧 좋은 앱이다."**

- 라이프사이클 매칭 (`init↔deinit`) — 빌린 자원은 반납
- 즉시 응답 vs 부드러운 응답의 미학 — 인생의 주인공에게 양보
- 좁은 인터페이스 — 외부는 모르게, 안에서만 진화
- DRY — 좋은 빌딩 블록(6-5 play)은 위에서 그냥 호출만

Phase 6 시리즈의 흐름:
- 6-1: HapticsManager (감각 1)
- 6-2: AudioManager (감각 2)
- 6-3: 인프라
- 6-4: BGMPlayer (감각 3)
- 6-5: 페이드 (감각의 결)
- 6-6: 인터럽션 (시스템과의 매너) ← 지금 여기

이제 **BGMPlayer는 게임 전용 매니저로서 자족적**이에요. 인스턴스 한 번 만들고 play/stop만 부르면, 페이드/멱등성/인터럽션/메모리 정리까지 다 알아서.

그게 좋은 추상화예요.
