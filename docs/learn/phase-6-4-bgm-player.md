# Phase 6-4 — BGMPlayer (배경음악 인프라)

## 한 줄 요약
게임할 때 **배경음악(BGM)**이 깔리도록 준비실을 또 하나 차렸어요. 지금은 음악 파일이 없어서 조용하지만, 나중에 FL Studio로 만든 `bgm.m4a` 한 개만 폴더에 넣으면 그때부터 게임 내내 음악이 무한 반복으로 흘러요.

---

## 무엇을 했나요?

`BGMPlayer`라는 도우미를 새로 만들었어요. 하는 일은 딱 세 가지예요.

1. 게임이 시작될 때 폴더에 `bgm.m4a` 파일이 있는지 살펴봐요.
2. 있으면 **무한 반복** 재생 준비를 해요.
3. 게임이 시작되면 음악을 틀고, 게임이 끝나면 음악을 멈춰요.

지금은 파일이 없으니까 아무 일도 안 일어나요(noop = no operation, "아무것도 안 함"). 게임은 6-3 그대로 굴러가요. **변화 0.**

---

## 왜 만들었을까? — 게임의 "정체성"

이 게임은 김간호가 병동에서 작곡하던 새벽을 담은 자전적 게임이에요.
효과음(틱! 두웅!)만으로는 그 분위기가 안 살아요. 새벽에 작곡하면서 듣던 그 **배경음악**이 필요했어요.

근데 음악 파일을 만드는 건 시간이 오래 걸려요(FL Studio로 작곡, 믹싱, 마스터링...).
그래서 6-4에서는 **준비실**만 차려요. 음악을 트는 장치를 미리 다 만들어 두고, 사용자가 나중에 시간 날 때 파일 하나만 떨어뜨리면 다음 빌드부터 음악이 깔리도록.

이게 **graceful fallback**(우아한 폴백) 패턴이에요. 파일 없으면 조용히 noop, 파일 있으면 즉시 활성화.

> **Spring 비유**: `@ConditionalOnResource("classpath:bgm.m4a")`. 클래스패스에 파일이 있을 때만 자동으로 빈을 만들어 등록하는 어노테이션이랑 정확히 같은 발상이에요.

---

## Manager 3연타 — 6-1, 6-2, 6-4

Phase 6에 들어서면서 **Manager 패턴**이 세 번째 등장했어요.

| Manager | 역할 | Spring 비유 |
|---|---|---|
| `HapticsManager` (6-1) | 진동 (손맛) | `@Service NotificationService` |
| `AudioManager` (6-2/6-3) | 효과음 | `@Service AlarmService` |
| `BGMPlayer` (6-4) | 배경음악 | `@Service MusicPlayerService` |

셋 다 똑같은 패턴이에요.
- `final class`로 선언 (상속 차단)
- side-effect(외부 시스템 호출)만 담당
- GameScene은 `let haptics = HapticsManager()`처럼 **인스턴스를 가지고만 있다가** 필요할 때 호출만 해요.

> **Spring 비유**: GameScene은 `@Controller`고 Manager 3개는 `@Service`예요. Controller는 Service를 필드로 주입받아 두고 비즈니스 로직 안에서 호출만 해요. 새로운 side-effect가 생기면 Service만 추가하고 Controller는 한 줄만 더 적으면 끝(OCP — Open/Closed Principle).

```swift
// GameScene 시스템 섹션 — 인스턴스 3개를 let으로 보유
let haptics = HapticsManager()   // 6-1
let audio   = AudioManager()     // 6-2
let bgm     = BGMPlayer()        // 6-4  ← 새로 추가된 한 줄
```

이게 OCP의 진수예요. 새 Manager가 와도 기존 코드는 **추가만 일어나고 변경은 안 일어나요**.

---

## AVAudioSession 카테고리 정책 — 시스템과의 약속

iOS에는 시스템 단위 오디오 정책이라는 게 있어요. "내 앱이 소리를 어떻게 다룰 건지" iOS에게 미리 알려주는 거예요. 이걸 **AVAudioSession 카테고리**라고 해요.

### 종류 (이 게임에 등장한 것만)

| 카테고리 | 무음모드 | 다른 앱 음악 | 용도 |
|---|---|---|---|
| `.ambient` | 따름 (조용히) | 안 끊음 | 6-3 효과음 |
| `.playback` | 무시 (그래도 울림) | 옵션에 따라 | 6-4 BGM |

### `.mixWithOthers` 옵션

`.playback`만 쓰면 기본적으로 다른 앱 음악을 끊어버려요. 하지만 우리 게임은 "음악박사" 게임이라 사용자가 Apple Music 들으면서 게임할 수도 있어요. 그걸 강제로 끊으면 무례하잖아요.

그래서 `.playback + .mixWithOthers`를 같이 써요. "내 음악도 틀 거지만 다른 앱 음악도 같이 쓸 게요." 이런 약속이에요.

> **Spring 비유**: `@Transactional(propagation = REQUIRES_NEW)` vs `SUPPORTS` 같은 외부 시스템 협상 정책이에요. 트랜잭션을 새로 열지(독점), 기존 거에 얹어 갈지(공존). 카테고리도 똑같이 "iOS 오디오 세션을 독점할지, 공존할지" 협상하는 거예요.

### 핵심 트릭 — "음원이 있을 때만 카테고리 덮어쓰기"

```swift
init() {
    guard let url = Bundle.main.url(forResource: "bgm", withExtension: "m4a") else { return }
    guard let p = try? AVAudioPlayer(contentsOf: url) else { return }

    // 음원 로딩 성공한 *이후에만* 카테고리를 덮어쓴다
    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
    ...
}
```

이게 왜 중요하냐면, 음원 파일이 *없을* 때까지 카테고리를 바꿔버리면 6-3의 `.ambient` 정책이 깨지거든요. 그러면 효과음 동작이 망가져요(회귀).

그래서 **두 guard를 통과한 다음에야** 카테고리를 덮어써요. 음원이 없으면 카테고리 변경 0. 6-3 정책이 그대로 살아 있어요.

---

## BGM vs 효과음 — 라이프사이클이 정반대

같은 "소리"인데 BGM과 효과음은 완전히 다른 생명을 살아요.

### 효과음 — 짧고 단발성
- 노트 수집 → 틱! (200ms)
- 게임오버 → 두웅! (500ms)
- `play()` 한 번 호출하면 자기가 알아서 끝나요.

> **Spring 비유**: `@EventListener`. 이벤트가 오면 한 번 처리하고 끝나는 핸들러예요.

### BGM — 길고 장기적
- 게임 시작 → 무한 반복 재생
- 게임 종료 → 명시적으로 `stop()` 호출해야 멈춰요.
- 멈추지 않으면 ResultScene으로 넘어가도 계속 울려요.

> **Spring 비유**: `@Scheduled(fixedDelay = ...)`. 한 번 켜면 데몬처럼 계속 도는 장기 빈이에요.

이 차이 때문에 BGM은 **명시적 stop**이 필수예요. `endGame()`에서 `bgm.stop()`을 빼먹으면 게임은 끝났는데 음악만 계속 흘러요(누수).

```swift
// endGame() — 끝낼 때 명시적으로 멈춤
audio.play(.gameOver)
bgm.stop()           // ← 이거 없으면 ResultScene에서도 BGM 계속 울림
spawnSystem.stop()
```

### 멱등 가드 안쪽에 둔 이유

`bgm.stop()`은 **멱등 가드 안쪽**에 있어요.

```swift
private func endGame() {
    if gameState == .gameOver { return }   // ← 가드
    gameState = .gameOver
    ...
    bgm.stop()   // ← 이 안쪽이라 1회만 실행 보장
}
```

게임 끝나는 순간이 동시에 여러 개 있을 수 있어요(시간만료 + F 피격이 같은 프레임에 발생 같은 거). 가드 안쪽에 있으면 첫 호출에서만 stop이 실행되고, 둘째 호출은 가드에서 return으로 막혀요. 결과적으로 stop이 1회만 호출되는 게 보장돼요.

---

## 매 진입마다 새 인스턴스 — ARC가 청소

재시작할 때 신경 쓸 게 없어요.

```swift
class func newGameScene(characterID: CharacterID = .kim) -> GameScene {
    let scene = GameScene(...)   // 새 인스턴스
    ...
}

class GameScene: SKScene {
    let bgm = BGMPlayer()   // 새 GameScene이 만들어지면 새 BGMPlayer
}
```

게임 → 결과 → 타이틀 → 다시 게임 흐름에서 `GameScene`이 새로 만들어지면 `BGMPlayer`도 새 인스턴스가 생겨요. 그러면 안에 있는 `AVAudioPlayer`도 새로 로딩돼서 0초부터 재생.

이전 인스턴스는? Swift의 **ARC**(Automatic Reference Counting)가 알아서 정리해요. 참조하는 사람이 사라지면 메모리에서 자동 해제. 우리가 명시적으로 dealloc 호출할 필요 없어요.

> **Spring 비유**: 매 요청마다 새 컨트롤러를 만드는 `@RequestScope` 같은 거예요(엄밀히는 GC가 아닌 ARC지만, 자동 청소라는 점은 비슷).

---

## 파일 4개 + pbxproj 4지점

### 변경 파일

| 파일 | 변경 |
|---|---|
| `Managers/BGMPlayer.swift` (신규) | 58줄 |
| `GameScene.swift` (수정) | 4줄 추가 (헤더 1 + 시스템 1 + didMove 1 + endGame 1) |
| `Resources/README.md` (수정) | BGM 단락 H2 1개 추가 |
| `project.pbxproj` (수정) | 4줄 추가 |

### pbxproj 4지점이란?

Xcode 프로젝트 설정 파일에 새 .swift 파일을 등록하려면 **4곳**에 추가해야 해요.

1. **PBXBuildFile**: "이 파일을 빌드 단계에 포함시킨다" 선언
2. **PBXFileReference**: "이런 파일이 프로젝트에 있다" 선언
3. **PBXGroup children**: 좌측 네비게이터 어느 폴더에 보여줄지
4. **iOS Sources phase**: 어느 타겟의 컴파일 대상인지

> **Spring 비유**: Maven `pom.xml`에 새 의존성 추가할 때 `<dependency>` 한 곳에만 적으면 끝나지만, Xcode는 4곳에 분산돼 있어요. 더 복잡하지만 그만큼 세밀한 제어가 가능한 구조예요.

이 4지점 중 하나라도 빠지면 **"Cannot find 'BGMPlayer' in scope"** 같은 컴파일 에러가 나요. 우리는 grep으로 미리 충돌 검사하고, AudioManager가 등록된 줄 바로 뒤에 정확히 추가했어요.

---

## 빌드 검증 결과

```
** BUILD SUCCEEDED **
warning/error 0줄 (AppIntents 무관 경고 제외)
```

음원 파일이 없는 지금 상태에서:
- `BGMPlayer.init()`의 첫 guard가 실패 → `player = nil`
- 카테고리 변경 0 → `.ambient` 유지
- `play()/stop()` 호출돼도 noop
- 효과음(시스템 사운드 Tink/Boop) 정상 동작
- 결국 사용자 체감은 6-3과 **완전히 동일**

음원 파일(`bgm.m4a`)을 추가하는 순간:
- `BGMPlayer.init()`의 두 guard 통과 → `player` 활성화
- 카테고리 `.playback + .mixWithOthers`로 자동 전환
- 게임 시작 시 무한 루프 BGM 재생
- 게임 종료 시 멈춤
- 코드 변경 0줄로 즉시 활성화

---

## 핵심 학습

1. **Manager 3연타 (6-1/6-2/6-4)**: side-effect는 `final class` Manager로 분리, GameScene은 오케스트레이터로서 호출만. OCP의 살아있는 예시.
2. **AVAudioSession 카테고리**: iOS와의 "오디오 협상 정책". 효과음은 `.ambient`, BGM은 `.playback + .mixWithOthers`. 음원 존재 여부를 트리거로 전환해야 회귀 0.
3. **BGM vs 효과음 라이프사이클**: 효과음은 단발(@EventListener), BGM은 장기(@Scheduled). 명시적 stop 필수.
4. **graceful fallback**: "파일 있으면 활성화, 없으면 noop". 비기술적 워크플로(작곡)와 기술적 빌드(코드)를 깔끔히 분리. Spring `@ConditionalOnResource` 패턴.
5. **멱등 가드 안쪽 배치**: 동시 종료 이벤트가 와도 `stop()` 1회 보장. `audio.play(.gameOver)` 옆에 `bgm.stop()`을 둔 이유.
