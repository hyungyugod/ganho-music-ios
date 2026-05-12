# Phase 6-3 — AVAudioPlayer 폴백 인프라

## 한 줄 요약
지금은 그대로 "틱!" "두웅~"이 나지만, 나중에 직접 만든 `note.wav` 파일을 폴더에 넣기만 하면 **자동으로** 내 소리가 흘러나오게 준비해 뒀어요.

---

## 무엇을 했나요?

게임 소리가 바뀐 건 **하나도 없어요**. 진짜로요.
대신 **"준비실"** 을 하나 차렸어요.

- 소리를 트는 도구를 **두 개** 준비해 뒀어요.
  1. **고급 도구**: `AVAudioPlayer` — 내가 만든 음원 파일을 트는 친구
  2. **기본 도구**: `AudioServicesPlaySystemSound` — 6-2에서 쓰던 Apple 기본 소리
- 평소엔 고급 도구를 먼저 찾아봐요.
- 고급 도구가 쓸 음원 파일(`note.wav`)이 **없으면** 자동으로 기본 도구로 넘어가요.

지금은 `note.wav`가 없으니까 결국 기본 도구(Tink/Boop)가 울려요. **변화 0.**
나중에 FL Studio로 음원을 만들어서 폴더에 넣으면 그 순간부터 내 소리가 울려요. **변화 100.**

---

## 왜 지금 만들었을까? — "준비실"의 의미

음원 파일을 만드는 건 시간이 오래 걸려요(FL Studio 학습, 작곡, 믹싱).
근데 **인프라(준비실)**는 코드 작업이라 지금 끝낼 수 있어요.

이렇게 분리해두면:
- 사용자: "오늘은 작곡할 시간이 1시간 생겼다!" → 파일 만들어서 폴더에 떨궈요. 끝.
- 코드: **건드릴 게 없음.**

> Spring으로 비유하면 `@Configuration`으로 빈만 미리 등록해놓고, 실제 데이터는 나중에 채우는 느낌이에요.

---

## Spring 비유 — 세 가지 패턴이 한꺼번에 등장했어요

### 1. `@Resource` — 클래스패스에서 파일 찾기

Java/Spring에서 자원 파일을 찾을 때 이렇게 써요:

```java
@Value("classpath:sounds/note.wav")
Resource noteSound;
```

iOS Swift에서는:

```swift
Bundle.main.url(forResource: "note", withExtension: "wav")
```

`Bundle.main` = "내 앱이 들고 있는 자원 보따리". `classpath`와 똑같은 역할이에요.
파일이 있으면 `URL`을 돌려주고, 없으면 `nil`. **`Optional`이라 안전해요.**

### 2. `@Cacheable` — eager 워밍업 캐시

음원 파일을 매번 디스크에서 불러오면 느려요. 그래서 **앱 시작 시 한 번 미리 다 읽어둬요**.

```swift
private var players: [SFX: AVAudioPlayer] = [:]   // 캐시 (Map<Key, Value>)

init() {
    for sfx in allCases {
        // 파일 → 디코딩 → 메모리에 보관
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()       // ← 추가 워밍 (디코딩 끝내놓기)
        players[sfx] = player
    }
}
```

이거 Spring에 정확히 매핑되는 패턴이 있어요:

```java
@PostConstruct
public void warmUp() {
    cache.put("note", load("note.wav"));
    cache.put("gameover", load("gameover.wav"));
}
```

**`@PostConstruct` + `@Cacheable` 조합**이에요.

#### 왜 lazy(첫 호출 시 로드)가 아닌 eager(미리 다 로드)?

| 전략 | 첫 호출 | 이후 호출 |
|---|---|---|
| **lazy** (그때그때) | 디코딩 16ms → **끊김!** | 빠름 |
| **eager** (미리 다) | 빠름 | 빠름 |

게임은 **첫 음표를 먹는 그 순간**이 가장 중요해요.
거기서 한 프레임 끊기면 (`60fps`에서 16ms 예산 깨짐) 전체 인상이 나빠져요.
그래서 **앱 시작할 때 미리 다 익혀놓기** 전략을 골랐어요.

### 3. `@CircuitBreaker(fallbackMethod = ...)` — graceful degradation

Spring에서 외부 API가 죽었을 때 "대체 경로"로 흐르게 하는 패턴이에요:

```java
@CircuitBreaker(name = "audio", fallbackMethod = "playFallback")
public void play(SFX sfx) {
    avAudioPlayer.play();        // 이상적 경로
}

public void playFallback(SFX sfx, Throwable e) {
    systemSound.play();          // 안전한 폴백
}
```

Swift에서는 이렇게 생겼어요:

```swift
func play(_ sfx: SFX) {
    if let player = players[sfx] {
        player.currentTime = 0
        player.play()             // 이상적 경로 (AVAudioPlayer)
        return
    }
    AudioServicesPlaySystemSound(sfx.systemSoundID)   // 폴백 경로
}
```

**구조가 완전히 똑같아요.** 다만 트리거가 *예외*가 아니라 *부재(nil)* 일 뿐이에요.

---

## graceful degradation — 두 단계 안전망

이번에 만든 코드에는 **두 군데** 안전망이 있어요.

### 단계 1: AudioSession 설정 실패

```swift
try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [])
```

`try?` = "실패하면 그냥 `nil` 받고 넘어가". 시뮬레이터나 특정 디바이스에서 가끔 실패하는데, 게임이 죽을 일은 아니잖아요. **계속 진행해요.**

### 단계 2: 파일 로딩 실패 → 폴백

```swift
guard let name = sfx.fileName,                                    // (a) fileName이 nil이면
      let url = Bundle.main.url(forResource: name, withExtension: "wav") else { continue }   // (b) 파일이 없으면
guard let player = try? AVAudioPlayer(contentsOf: url) else { continue }                     // (c) 파일이 깨졌으면
```

세 가지 모두 실패해도 `continue` 해서 **다음 SFX로 넘어가요**. 끝까지 못 채운 SFX는 `players` 딕셔너리에 키가 없는 상태로 남아요.

그러면 `play()`에서:

```swift
if let player = players[sfx] {  // ← 키가 없으면 nil
    ...
}
AudioServicesPlaySystemSound(...)  // ← 자연스럽게 폴백 경로로
```

**"이상적 경로가 실패해도 보장 경로가 항상 살아있다"** — 이게 graceful degradation의 정신이에요.

---

## `.ambient` vs `.playback` — 오디오 정책의 분기

`AVAudioSession.setCategory`는 "내 앱이 소리를 다루는 정책"을 시스템에 알리는 거예요.

| 카테고리 | 무음 모드 | 다른 앱 사운드 | 용도 |
|---|---|---|---|
| **`.ambient`** | 따름 (조용) | 안 끊음 | **효과음** (이번에 채택!) |
| `.playback` | 무시 (들림) | 끊음 | BGM, 음악앱 |

지금은 효과음만 있으니 **`.ambient`가 맞아요**:
- 사용자가 무음 모드면 게임도 조용히 → 매너 굿
- 다른 앱 사운드(예: 스포티파이) 안 끊음 → 매너 굿

나중에 BGM 도입할 때는 `.playback`으로 바꿔야 해요. 그건 다음 sprint.

> `setActive(true)`를 안 부른 것도 같은 이유예요. `.ambient`는 시스템이 알아서 활성화해줘요. 굳이 명시할 필요 없음.

---

## `try?` — Swift의 한 줄 폴백

Java에선 이렇게 쓰잖아요:

```java
try {
    setCategory(.ambient);
} catch (Exception ignored) {
    // 무시하고 계속
}
```

Swift에서는 **`try?`** 한 글자로 같은 일을 해요:

```swift
try? AVAudioSession.sharedInstance().setCategory(.ambient, ...)
```

`try?`의 의미: "실패하면 그냥 `nil`로 받고 진행". **로그도 안 남겨요.** 의도적으로 무시.

`try!`는 절대 금지(`!`는 강제 언래핑 = 크래시 가능).
`do-catch`도 이번엔 안 어울려요. 실패가 정상 시나리오(시뮬레이터 등)라 굳이 처리할 게 없음.

---

## `CaseIterable`을 일부러 안 썼어요

Swift에는 enum의 모든 케이스를 자동으로 배열로 만들어주는 `CaseIterable`이 있어요:

```swift
enum SFX: CaseIterable {       // ← 이렇게 하면
    case noteCollected, gameOver
}
// SFX.allCases 자동 생성됨!
```

근데 이번엔 **일부러 안 썼어요**. 왜?

> Phase 6-3의 Sprint 약속: **enum 본체는 건드리지 않는다.** `fileName` 프로퍼티만 추가.

대신 명시 배열로:

```swift
let allCases: [SFX] = [.noteCollected, .gameOver]
```

장점: 코드를 읽는 사람이 **"아, 지금 다 순회하는 거구나"** 를 한눈에 봐요.
단점: 케이스 추가 시 여기도 같이 늘려야 함. 근데 6-3에선 케이스 추가가 금지라 OK.

> Spring으로 치면 `@Component` 자동 스캔 대신, `@Bean`으로 명시 등록한 느낌이에요. **명시가 의도를 더 잘 드러내요.**

---

## 변경 없음의 미학 — `audio.play(...)` 두 줄

이번 sprint에서 **가장 자랑스러운 부분**이에요.

`GameScene.swift`의 음표 수집 / 게임오버 처리 코드:

```swift
audio.play(.noteCollected)
audio.play(.gameOver)
```

이 두 줄이 **단 한 글자도 안 바뀌었어요.**

6-2에서 시스템 사운드를 호출하던 코드가, 6-3에서 AVAudioPlayer로 분기하는 코드가 됐는데, **호출하는 쪽은 모르게** 만들었어요.

> Spring으로 치면 `@Service` 인터페이스를 안 바꾸고 구현체만 갈아끼운 셈이에요.
> 호출자(Controller = GameScene)는 영향을 안 받아요.

이런 걸 **추상화 경계의 안정성**이라고 해요. 6-2에서 시그니처를 신중히 정해둔 덕에 6-3에서 큰 변화가 가능했어요.

---

## 파일 vs Xcode 그룹 — 왜 README만 만들고 끝?

`Resources/Sounds/` 폴더를 만들고 그 안에 `README.md`를 두는 걸로 끝냈어요.
`note.wav`나 `gameover.wav`는 **안 만들었어요**.

이유:
- 음원 파일은 사용자가 FL Studio로 직접 작곡할 예정 → 자동 생성 금물
- Xcode 프로젝트 파일(`pbxproj`)을 직접 손대지 않음 → 사용자가 Xcode UI에서 drag-drop하면 자동으로 추가됨
- 폴더만 있으면 Xcode가 자동으로 그룹을 만들어줘요

README는 **"여기에 뭘 떨궈야 하는지"** 알려주는 안내판이에요. 비어있는 폴더의 정체성을 명시하는 역할.

---

## 한 줄로 정리하면

> 게임 소리는 그대로지만, **나중에 내가 만든 음원을 폴더에 떨구기만 하면 자동으로 활성화**되는 준비실을 차려뒀어요.
> Spring의 `@Resource` + `@Cacheable` + `@CircuitBreaker(fallbackMethod)` 세 가지 패턴이
> Swift에서 `Bundle.main.url` + eager 캐시 + `if let ... else { fallback }` 으로 그대로 펼쳐졌어요.
> **"이상적 경로가 실패해도 보장 경로가 살아있다"** 는 graceful degradation의 정신을 처음 체득.
> 가장 자랑스러운 건: GameScene의 `audio.play(...)` 두 줄이 **한 글자도 안 바뀐 것**. 추상화 경계가 잘 잡혀있다는 증거예요.

다음에 사용자가 시간이 날 때 작곡 한 곡 해서 폴더에 떨구면 — 그날 게임의 톤이 "한 사람이 만든 것"으로 격상돼요. 그날을 기다리는 인프라가 오늘 완성됐어요.
