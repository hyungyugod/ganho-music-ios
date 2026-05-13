# Phase 6-7 — 앱 백그라운드/포그라운드 라이프사이클

## 한 줄 요약
게임 중 **홈 버튼을 누르거나 카톡 알림을 보러 잠깐 나갔다가 돌아오면** BGM이 함께 숨을 죽였다가 다시 살아나요. 6-6의 *전화/Siri* 처리와는 다른 이벤트(사용자 의도 vs 시스템 강제)지만 같은 처치(pause/resume)가 정답. 6-6의 `pause()` / `resume()`을 한 글자도 안 건드리고 **소비만** 했어요.

---

## 무엇을 했나요?

BGMPlayer에 작은 식구 다섯이 더 들어왔어요.

1. **`import UIKit`** — `UIApplication.*Notification`을 쓰려고.
2. **`shouldResumeOnForeground`** 플래그 — "백그라운드 들어가기 직전에 음악이 켜져 있었나?"를 기억하는 메모지.
3. **didEnterBackground 옵저버** — 홈 버튼 등으로 백그라운드 진입 시 호출.
4. **willEnterForeground 옵저버** — 다시 앱으로 돌아올 때 호출.
5. **`handleDidEnterBackground` / `handleWillEnterForeground`** — 두 콜백 처리.

**한 줄도 안 바뀐 것들**: GameScene, AudioManager, HapticsManager, GameConfig, 6-6의 handleInterruption/pause/resume, deinit.

---

## 왜 이게 필요했을까? — "게임은 멈췄는데 BGM만 흐르면 이상해요"

iOS는 앱이 백그라운드로 가면 SpriteKit을 **자동으로 일시정지**해줘요. 게임 캐릭터도, 음표 스폰도, 적의 F 투사체도 모두 동결.

근데 6-4에서 BGM 카테고리를 `.playback`으로 설정했어요 — 무음모드 무시 + 백그라운드 재생 허용. 그래서 게임은 멈췄는데 **BGM만 혼자 계속 흘러요**.

이상해요. 화면이 멈췄는데 음악이 흐르면:
- 카톡 보는 동안 BGM이 깔린 채로 메시지 읽음 (불편)
- 그러다 잠깐 나갔다 오니 한 박자 어긋남
- 게임 일시정지 = BGM 일시정지여야 한 호흡

이번 sprint는 **게임의 일시정지와 BGM의 일시정지를 한 호흡으로 묶기**.

> **Spring 비유**: `@Async` 작업이 `ApplicationContext.close()` 됐을 때 같이 정리되어야 하는 것과 비슷. 컨테이너가 셧다운되는데 비동기 작업이 계속 굴러가면 안 되잖아요. 6-7은 그 *동기화*를 BGMPlayer가 자체적으로 처리하도록 만드는 거예요.

---

## 6-6과 6-7은 뭐가 다를까? — "강제 vs 자발"

같은 pause/resume이지만 발화 이유가 완전 달라요.

| 축 | 6-6 (Interruption) | 6-7 (Lifecycle) |
|---|---|---|
| 누가 발행? | AVAudioSession | UIApplication |
| 트리거 | 전화, Siri, 알람 — **시스템이 오디오를 빼앗을 때** | 홈 버튼, 앱 스위처 — **사용자가 앱을 떠날 때** |
| 의도성 | **강제** (사용자가 원치 않아도 발생) | **자발** (사용자가 능동적으로 선택) |
| 복귀 신호 | `.ended` 노티피케이션 + `shouldResume` 비트 | `willEnterForeground` 노티피케이션 |
| 복귀 결정 | 시스템이 "shouldResume" 플래그로 알려줌 | **우리가 직접 기억**해야 함 |

### 결정적 차이 — "복귀 시 깨울지 누가 결정?"

**6-6**: 시스템이 `.ended` 노티피케이션에 `shouldResume` 플래그를 같이 줘요. 우리는 그걸 보고 깨울지 말지 결정.

**6-7**: 그런 플래그 없음. 우리가 **백그라운드 들어가는 시점에** "지금 음악 켜져 있었나?"를 기억해놨다가, 돌아올 때 그 메모를 보고 결정해야 해요.

이 차이가 `shouldResumeOnForeground` 플래그를 만든 이유.

> **Spring 비유**:
> - 6-6은 `@TransactionalEventListener` — 트랜잭션의 commit/rollback 이벤트에 시스템이 신호를 줘요.
> - 6-7은 `@ServletRequestListener` — HTTP request 시작과 끝을 받지만 *내가 무슨 작업을 했는지*는 내가 기억해야 해요.

---

## "메모지 패턴" — `shouldResumeOnForeground`

비유: 엄마가 잠깐 마트 갔다 와요. 외출 직전에 거실 TV가 켜져 있었어요. 돌아왔을 때 그 TV를 다시 켜줄지 말지 결정하려면 **외출 직전 상태**를 알아야 해요.

```
외출 직전: TV ON  →  메모지: "TV는 ON이었음"
외출 후 돌아옴 → 메모지 확인 → ON이었으니 다시 켜기
```

```
외출 직전: TV OFF →  메모지: 안 적어 (false 유지)
외출 후 돌아옴 → 메모지 확인 → OFF였으니 그대로 두기
```

BGMPlayer도 똑같아요.

```swift
@objc private func handleDidEnterBackground(_ notification: Notification) {
    guard let player = player else { return }
    if player.isPlaying {                          // ← 외출 직전 상태 체크
        shouldResumeOnForeground = true            // ← 메모지에 적기
        pause()
    }
    // isPlaying false면? 메모지에 안 적음 (false 유지)
}

@objc private func handleWillEnterForeground(_ notification: Notification) {
    guard shouldResumeOnForeground else { return } // ← 메모지 확인
    shouldResumeOnForeground = false               // ← 메모지 찢어버림
    resume()
}
```

**왜 false로 리셋?** 다음번 백그라운드 진입 → 복귀 사이클을 깨끗하게 시작하려고. 옛 메모가 남아 있으면 다음번에 잘못된 결정.

> **Spring 비유**: HTTP request scope 빈에 임시 상태를 담아두고 request 끝나면 자동 청소. 우리는 자동 청소가 없으니 수동으로 리셋.

---

## DRY의 진짜 깊이 — 6-6 코드를 한 글자도 안 건드림

이번 sprint의 가장 인상적인 부분.

신규 추가 메서드 `handleDidEnterBackground`는 6-6의 `pause()`를 부르고, `handleWillEnterForeground`는 6-6의 `resume()`을 부르기만 해요.

```swift
private func handleDidEnterBackground(...) {
    if player.isPlaying {
        shouldResumeOnForeground = true
        pause()                          // ← 6-6 메서드
    }
}

private func handleWillEnterForeground(...) {
    guard shouldResumeOnForeground else { return }
    shouldResumeOnForeground = false
    resume()                             // ← 6-6 메서드
}
```

6-6에서 잘 만들어 둔 `pause()` (isFadingOut 가드 포함) / `resume()` (`play()` 호출, isPlaying 가드 + stopWorkItem 정리) 이 그대로 6-7의 *부품*이 돼요.

이게 **DRY 원칙의 진짜 의미**예요. "코드를 두 번 안 쓴다"가 다가 아니에요. **잘 만든 빌딩 블록을 위에서 그냥 호출**할 수 있는 구조가 진짜 DRY.

> **Spring 비유**: 컨트롤러 A가 `userService.register(...)`를 호출하는데, 컨트롤러 B도 같은 메서드를 호출. 컨트롤러 A 코드를 바꿔도 B는 안 건드림. 그게 좋은 추상화.

8단계 sprint 누적 결과로 BGMPlayer는 **5중 가드 매트릭스**를 갖췄어요:

| 가드 | Phase | 무엇을 막나? |
|---|---|---|
| `isFadingOut` | 6-5 | 페이드 아웃 중 중복 stop |
| `stopWorkItem.cancel()` | 6-5 | 페이드 아웃 중 play 들어오면 예약 stop 취소 |
| `pause()` 내 `isFadingOut` 가드 | 6-6 | 페이드 아웃 중 인터럽션 pause 충돌 방어 |
| `play()` 내 `isPlaying` 가드 | 6-4 | 중복 재생 차단 |
| `shouldResumeOnForeground` | **6-7** | **의도 없던 백그라운드 → 복귀 시 깨우지 않음** |

각 가드 하나하나는 사소해 보이지만, **다섯이 함께 작동하면 어떤 순서로 어떤 이벤트가 와도 안전**해요.

---

## 교차 시나리오 — 전화 + 백그라운드 동시에 오면?

전화 받으러 통화 화면 보면 둘 다 발생해요.

```
1. 전화 옴
   → AVAudioSession.interruption .began 발행
   → handleInterruption(.began) → pause() → isPlaying false
2. 사용자 통화 받기 탭 → 앱 백그라운드
   → UIApplication.didEnterBackgroundNotification 발행
   → handleDidEnterBackground 호출
   → 근데 isPlaying이 이미 false (1번에서 멈춤)
   → if 분기 안 들어감 → 메모지에 안 적음 (false 유지)
3. 통화 끝, 앱 복귀
   → willEnterForeground 발행
   → handleWillEnterForeground → 메모지 false → noop
4. interruption .ended 발행 (shouldResume=true)
   → handleInterruption(.ended) → resume()  ← 6-6 단독 책임
```

**6-7은 가만히 있고, 6-6 혼자 깨움**. 이중 재생 0.

만약 6-7이 isPlaying 체크 없이 무조건 `shouldResumeOnForeground = true` 했다면? 복귀 시 6-7이 먼저 resume → 6-6도 resume → BGM이 두 번 출발 시도. 그래서 `if player.isPlaying`이 핵심.

> **Spring 비유**: 두 개의 `@EventListener`가 같은 빈에 있을 때 서로 협력하도록 *공유 상태로 조율*하는 패턴. 한 쪽이 작업을 끝내고 false로 만들면 다른 쪽이 책임 안 짐.

---

## 옵저버 매트릭스 — 단일에서 다중으로

6-6 후: 옵저버 1개 (interruption)
6-7 후: 옵저버 +2 → 총 3개

```swift
// init 안에서
NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), ...)
NotificationCenter.default.addObserver(self, selector: #selector(handleDidEnterBackground), ...)
NotificationCenter.default.addObserver(self, selector: #selector(handleWillEnterForeground), ...)

// deinit
deinit {
    NotificationCenter.default.removeObserver(self)  // ← 한 줄로 3개 다 해제
}
```

**deinit 본문은 0줄도 안 바뀜.** `removeObserver(self)`가 self가 등록한 모든 옵저버를 일괄 해제하는 벌크 API라서.

옵저버를 더 추가해도 deinit은 그대로. **선언적 자원 관리**.

> **Spring 비유**: 빈에 `@EventListener` 메서드를 10개 만들어도 `@PreDestroy`는 한 줄. 컨테이너가 알아서 정리.

학생 비유: "도서관 카드 한 장으로 책 10권 빌리고, 한 번에 다 반납. 한 권씩 반납 처리하는 게 아니라 카드 단위로."

---

## 검증 시뮬레이션 — 시뮬레이터에서 어떻게 확인하나?

음원(`bgm.m4a`)이 있다면:

1. 게임 진입 → BGM 재생 시작 (1.5초 페이드 인)
2. **Cmd+Shift+H** (시뮬레이터 홈 버튼)
3. → BGM이 즉시 멈춤 (pause)
4. 시뮬레이터에서 앱 다시 탭
5. → BGM이 페이드 인하며 살아남 (resume = play 호출 → 1.5초 페이드 인)

음원이 없으면:
- init의 첫 guard에서 player = nil
- 옵저버 등록 자체가 안 일어남
- 회귀 0 (6-3/6-4/6-5/6-6과 동일 noop)

> **Spring 비유**: `@ConditionalOnResource("classpath:bgm.m4a")`가 false면 빈 등록 자체 안 됨. 6-7도 같은 발상 — 음원 없으면 옵저버 등록 안 함.

---

## 이번 sprint의 한 줄 교훈

**"좋은 추상화는 새 기능을 추가할 때 옛 코드를 한 줄도 안 건드리게 한다."**

- 6-4에서 좁게 잡은 `play`/`stop` → 6-5에서 페이드 추가 시 호출부 0줄 변경
- 6-5에서 만든 `play`/`stop` → 6-6에서 인터럽션 처리 시 그대로 재사용
- 6-6에서 만든 `pause`/`resume` → 6-7에서 라이프사이클 처리 시 그대로 재사용

각 sprint가 **이전 sprint를 깨지 않고 자기 자리에서 자기 일만** 한다.

> **Spring 비유**: 좋은 인터페이스 위에 새 구현을 얹는 것과 같아요. UserService를 처음 만들 때 잘 추상화해두면, 그 위에 캐싱 데코레이터를 얹어도, 로깅 데코레이터를 얹어도, 메트릭 데코레이터를 얹어도, *원본 UserService는 한 줄도 안 바뀜*. 데코레이터 패턴의 진짜 가치.

Phase 6 시리즈는 이제 7단계까지 와서, BGMPlayer가 **자족적인 시스템 시민(good citizen)**이 됐어요:
- 6-1, 6-2: 감각 채널 (촉각, 청각)
- 6-3: 인프라
- 6-4: BGM 재생
- 6-5: 부드러운 시작/끝 (페이드)
- 6-6: 시스템 인터럽션 매너 (전화 양보)
- 6-7: 앱 라이프사이클 매너 (홈 버튼 양보)

이제 BGMPlayer는 **시스템에도, 사용자에도, 자기 자신에도** 친절해요. 그게 좋은 도구의 정의예요.
