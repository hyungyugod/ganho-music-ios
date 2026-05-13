# Phase 6-5 — BGM 페이드 인/아웃

## 한 줄 요약
6-4에서 만든 BGM 재생 장치에 **부드럽게 켜지고 부드럽게 꺼지는** 기능을 더했어요. 게임이 시작되면 음악이 1.5초에 걸쳐 천천히 차오르고, 게임이 끝나면 1초에 걸쳐 사그라들어요. **`bgm.play()` / `bgm.stop()` 호출하는 쪽 코드는 한 글자도 안 바꿨어요** — 마법은 BGMPlayer 안에서만 일어나요.

---

## 무엇을 했나요?

세 가지 변화가 있었어요.

1. **시작 부분 부드럽게**: `play()`를 부르면 음악이 0% 볼륨에서 시작해서 1.5초 동안 천천히 100%까지 차올라요.
2. **끝 부분 부드럽게**: `stop()`을 부르면 음악이 1초 동안 천천히 0%까지 줄어든 다음에야 실제로 멈춰요.
3. **GameConfig에 시간 두 개 추가**: `bgmFadeInDuration = 1.5`, `bgmFadeOutDuration = 1.0`. 매직 넘버 금지 정책을 지키려고요.

---

## 왜 이게 필요했을까? — 음악의 예의

이 게임의 BGM은 사용자(개발자 자신)가 간호 실습 중 새벽에 작곡한 곡이에요. 그 곡이 갑자기 "**퍽!**" 켜지고 갑자기 "**툭!**" 끊기면 어떨까요?

라디오 다이얼을 거칠게 돌리는 것 같아요. 작곡자가 자기 곡한테 그러면 안 되잖아요.

영화에서 OST가 처음 들어올 때는 멀리서 다가오듯 페이드 인 되고, 한 장면이 끝날 때는 사그라들면서 페이드 아웃 돼요. 이유가 있어요 — **음악은 시작과 끝의 모양으로 분위기가 결정**되거든요. 갑자기 켜면 자극적이고, 천천히 차오르면 따뜻해요.

6-5는 코드 변경량으로는 작지만 (BGMPlayer 본문 ~20줄 + GameConfig 4줄), **게임의 정체성을 담은 BGM에 인격을 돌려주는** 작업이에요.

---

## 디클러레이티브 API의 마법 — "내가 안 해도 알아서 해줘"

핵심 API 한 줄을 봐 봐요.

```swift
player.setVolume(1.0, fadeDuration: GameConfig.bgmFadeInDuration)
```

이 한 줄이 무슨 일을 하냐면:
- 지금 시점의 볼륨에서 시작해서
- 1.5초에 걸쳐
- 선형(linear)으로 1.0까지 부드럽게 올려줘요

근데 **우리는 매 프레임 볼륨을 계산하지 않아요**. "1.5초 뒤에 1.0이 되어야 한다"고 한 번만 말하면 끝. 실제로 매 프레임 볼륨을 0.01씩 올리는 작업은 iOS의 오디오 엔진이 백그라운드에서 알아서 해줘요.

이게 **선언형(declarative) API**예요. "이렇게 해라"가 아니라 "이게 되어야 한다"고 말하면 시스템이 알아서.

> **Spring 비유**: `@Async` 메서드 호출이랑 똑같아요.
>
> ```java
> @Async
> public void sendEmail(String to) { /* ... */ }
> ```
>
> 호출하면 즉시 리턴되고, 실제 작업은 `TaskScheduler`가 백그라운드에서 처리해요. 우리는 send 호출만 하지 send 도중에 SMTP 상태를 폴링하지 않아요.
>
> 또는 `@Scheduled`처럼 "이 시간 후에 이걸 해 줘"라고 선언만 하고 신경 끄는 것과 같아요. iOS의 AVFoundation이 `TaskScheduler` 역할이에요.

명령형(imperative)으로 직접 짠다면 매 프레임 `volume += 0.01`을 돌리는 게임 루프 코드가 필요한데, **선언형은 그 자리에 버그가 들어갈 자리 자체가 없어져요**. 그게 진짜 가치예요.

---

## 어려웠던 점 1 — "stop은 언제 부르지?"

`setVolume(0, fadeDuration: 1.0)`만 부르면 볼륨은 1초 동안 천천히 0이 되는데, **음악 자체는 안 멈춰요**. 0% 볼륨으로 무한 루프를 계속 돌고 있어요. 자원 낭비.

그렇다고 `setVolume(0, ...)` 직후에 바로 `player.stop()`을 부르면? stop이 페이드를 잘라먹어서 또 갑자기 끊겨요. 페이드 의미가 없어져요.

답은: **페이드가 끝난 *후*에 stop을 부른다**. 그러면 1초 동안 천천히 사그라들고, 정확히 1.0초 뒤에 player가 진짜로 멈춰요.

그럼 "1초 뒤에 이걸 해 줘"는 어떻게 하나요? 옵션을 봐요:

| 방법 | 결과 |
|---|---|
| `SKAction.wait(1.0)` | ❌ BGMPlayer는 SKNode가 아니라 SKAction 사용 불가 |
| `Timer.scheduledTimer(...)` | ❌ swift-rules.md에서 금지 (한국어 댓글에 명시) |
| `DispatchQueue.main.asyncAfter` | ✅ 허용 (게임 루프 외부 매니저라 OK) |

그래서 `DispatchQueue.main.asyncAfter`를 골랐어요. 단, 그냥 쓰면 위험해요 — 게임이 끝났는데 BGMPlayer가 해제되기 *전*에 예약된 작업이 살아남아서 nil이 된 player를 건드릴 수 있거든요.

해결: **`DispatchWorkItem` + `[weak self]` 캡처**.

```swift
let work = DispatchWorkItem { [weak self] in
    guard let self = self else { return }   // BGMPlayer가 사라졌으면 noop
    self.player?.stop()
    self.isFadingOut = false
    self.stopWorkItem = nil
}
stopWorkItem = work
DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
```

세 겹의 안전망이에요:
1. `[weak self]` — BGMPlayer가 사라지면 self가 nil
2. `guard let self = self` — nil이면 즉시 return
3. `self.player?` — player도 옵셔널이라 nil이면 자동 skip

> **Spring 비유**: `ScheduledFuture`를 받아서 나중에 cancel할 수 있게 보관하는 패턴과 비슷해요. `TaskScheduler.schedule()`이 반환하는 future를 인스턴스 변수로 들고 있다가, 필요하면 `future.cancel(false)`로 취소.

---

## 어려웠던 점 2 — "stop이 두 번 들어오면?"

게임이 끝나는 경로가 두 개예요:
- 45초 타이머 만료
- 적의 F 투사체에 맞음

이 두 개가 *같은 프레임*에 동시에 발생하면 `endGame()`이 두 번 불릴 수 있어요. `endGame()` 자체는 멱등 가드가 있지만, 그 안의 `bgm.stop()`이 두 번 호출되면?

만약 가드 없이 두 번 호출되면:
1. 첫 호출: 페이드 아웃 시작 + 1.0초 뒤 stop 예약
2. 두 번째 호출 (같은 프레임): 또 페이드 아웃 시작 + 1.0초 뒤 stop 또 예약
3. 결과: stop이 두 번 실행되고, 이전 stopWorkItem은 메모리에 남는 누수

해결: **`isFadingOut` flag로 가드**.

```swift
func stop() {
    guard let player = player else { return }
    if isFadingOut { return }   // 이미 페이드 아웃 중이면 두 번째 호출 무시
    isFadingOut = true
    // ...
}
```

이게 **멱등성(idempotency)**이에요. 같은 호출이 몇 번 들어와도 결과가 똑같아야 해요.

> **Spring 비유**: `@Transactional`이 걸린 메서드가 같은 ID로 두 번 호출돼도 DB가 한 번만 변경되게 하는 패턴. 또는 결제 API에서 같은 `idempotency-key`로 요청이 두 번 와도 한 번만 결제되는 패턴.

이중 가드 구조도 예쁘게 떨어졌어요:
- 6-4의 `isPlaying` 가드: 중복 `play()` 차단
- 6-5의 `isFadingOut` 가드: 중복 `stop()` 차단

각자 책임이 분명해요.

---

## 어려웠던 점 3 — "init에서 volume=0을 안 해두면?"

`setVolume(1.0, fadeDuration: 1.5)`는 **현재 볼륨에서 1.0까지 보간**이에요. 즉 현재 볼륨이 1.0이면 변화 없음.

AVAudioPlayer는 만든 직후 기본 볼륨이 1.0이에요. 그래서 `init()`에서 미리 0으로 깎아두지 않으면 첫 `play()` 호출 시 페이드 인이 "1.0에서 1.0으로 보간" — 즉 페이드 의미 없음.

```swift
init() {
    // ...
    p.numberOfLoops = -1
    p.volume = 0          // ← 이게 없으면 첫 페이드 인이 의미 없어짐
    p.prepareToPlay()
}
```

그리고 `play()` 안에서도 한 번 더 `player.volume = 0`을 해줘요. 왜? 한 번 페이드 인이 끝나면 volume이 1.0이 됐기 때문에, 두 번째로 play()가 불릴 가능성이 있다면 다시 0으로 깎아야 페이드 인이 작동해요.

본 sprint에선 두 번째 play 시나리오가 없지만 (새 게임은 새 BGMPlayer 인스턴스), 방어적으로 한 줄 더. **"방어적 프로그래밍"은 비용이 거의 0인데 안전성은 크게 올라가는 패턴**이에요.

> **Spring 비유**: `@PostConstruct`에서 기본값을 초기화하는 것과 비슷해요. "이걸 안 해놓으면 메서드 첫 호출이 의도와 다르게 동작한다"는 invariant를 init에서 보장.

---

## 매직 넘버 회피 — GameConfig의 역할

페이드 시간 1.5와 1.0을 BGMPlayer.swift에 직접 박지 않고 GameConfig.swift에 따로 뺐어요.

```swift
// GameConfig.swift
static let bgmFadeInDuration: TimeInterval = 1.5
static let bgmFadeOutDuration: TimeInterval = 1.0
```

왜?

1. **매직 넘버 금지 (swift-rules.md §7)**: `1.5`가 코드 어딘가에 그냥 박혀 있으면 6개월 뒤 "이게 뭐였더라?" 됨.
2. **튜닝 한 곳**: 1.5가 너무 길다 싶으면 GameConfig 한 줄만 고치면 끝. BGMPlayer 안 봐도 됨.
3. **일관성**: 이미 `gameDuration`, `sceneTransitionDuration` 같은 시간들이 모두 GameConfig에 모여 있어요. 새 시간도 같은 동네에.

> **Spring 비유**: `application.yml`에 `bgm.fade-in-duration: 1.5`로 빼는 것과 똑같아요. 코드는 `@Value("${bgm.fade-in-duration}")`로 주입받기. 운영 중 튜닝이 쉬워져요.

---

## 사용하는 쪽 코드 0줄 변경 — 인터페이스의 가치

이번 sprint에서 가장 인상적인 사실:

**GameScene.swift는 한 글자도 안 바꿨어요.**

`bgm.play()`와 `bgm.stop()`을 부르는 줄이 120번 줄과 258번 줄에 그대로 있어요. 그 메서드 안의 동작은 완전히 달라졌는데, 부르는 쪽은 그대로.

이게 **인터페이스 추상화의 힘**이에요.

6-4에서 일부러 `play()` / `stop()` 이름을 좁게 잡아둔 게 6-5에서 보상이 됐어요. 만약 6-4에서 `playInstantly()` / `stopInstantly()`로 이름 지었으면, 6-5에서는 새 메서드 `fadeIn()` / `fadeOut()`을 만들고 GameScene 호출부를 바꿨어야 했어요.

이름을 "동사 그대로" 지은 덕에:
- 6-4에서는 `play = 즉시 재생`
- 6-5에서는 `play = 페이드 인으로 재생`

같은 추상화, 다른 구현. **OCP(Open/Closed Principle) — 확장에는 열려 있고 수정에는 닫혀 있다**.

> **Spring 비유**: `interface UserRepository { User findById(Long id); }`에서 `findById` 시그니처는 그대로 두고 구현체를 JPA → MyBatis → Redis 캐시로 바꿔도 호출하는 서비스 코드는 한 줄도 안 바뀌는 것과 똑같아요.

---

## graceful fallback의 회귀 0 보장

6-4의 핵심 가치였던 **"음원 파일이 없으면 모든 메서드가 noop"** 은 6-5에서도 그대로 살아 있어요.

`bgm.m4a`가 Bundle에 없으면:
1. `init()`의 첫 `guard let url` 실패 → `player = nil`
2. `play()` 첫 줄 `guard let player = player else { return }` → 즉시 return
3. `stop()` 첫 줄 `guard let player = player else { return }` → 즉시 return
4. 페이드 로직, DispatchWorkItem, isFadingOut 가드 — **하나도 실행 안 됨**

즉 음원이 없을 때는 6-3/6-4/6-5가 **완전히 동일하게 동작**해요. 그게 회귀 0 보장이에요.

> **Spring 비유**: `@ConditionalOnResource("classpath:bgm.m4a")` — 클래스패스에 파일이 있을 때만 빈 등록, 없으면 빈 자체가 안 생김. 6-5의 페이드 로직도 결국 "빈이 있을 때만 실행"이에요.

---

## 이번 sprint의 한 줄 교훈

**작은 인터페이스(`play`/`stop`)를 좁게 잘 지으면, 같은 자리에서 동작을 점점 풍부하게 확장할 수 있다.**

6-4: BGM 재생 인프라
6-5: 페이드 추가 (호출부 0줄 변경)
6-6 가능?: 일시정지/재개 → `pause()` / `resume()` 추가 (호출부에 1줄씩 추가)
6-7 가능?: 볼륨 조절 → `setMasterVolume()` 추가 (BGMPlayer만 변경)

각 sprint가 **이전 sprint를 깨지 않고 자기 자리에서 자기 일만 한다**. 그게 좋은 시스템.

> **Spring 비유**: 좋은 서비스 인터페이스를 잘 지어두면, 그 뒤에서 구현체를 바꾸거나 기능을 추가해도 컨트롤러 코드는 안정적. 인터페이스가 시스템의 *허리*예요.
