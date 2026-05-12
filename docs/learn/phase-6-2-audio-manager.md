# Phase 6-2 — 사운드 매니저 (AudioManager)

## 한 줄 요약
음표를 먹으면 "틱!" 소리, 게임이 끝나면 "두웅~" 소리가 나도록 만들었어요.

---

## 무엇을 했나요?

지난 시간(6-1)에는 **진동**(햅틱)을 게임에 붙였잖아요.
이번 시간(6-2)에는 **소리**도 같이 붙였어요.

- 음표를 먹으면 → 짧고 밝은 "틱!" (시스템 사운드 1057번 = Tink)
- 게임이 끝나면 → 묵직한 "두웅~" (시스템 사운드 1073번 = Boop)

그리고 이 사운드 일을 담당하는 새 상자를 만들었어요. 이름이 `AudioManager`예요.

---

## 왜 또 상자를 만들었을까? (Manager 패턴 두 번째)

지난 6-1에서 우리는 **"side-effect는 Manager에 맡긴다"** 라는 약속을 했어요.

> side-effect = 게임 데이터(점수, 위치 등)는 안 건드리고, 바깥 세상(휴대폰 부품)에 영향을 주는 일

진동도 side-effect, 소리도 side-effect. 그래서 둘 다 **Manager 상자**에 넣어요.

```
GameScene
  ├── haptics: HapticsManager  ← 진동 상자 (6-1)
  └── audio:   AudioManager    ← 소리 상자 (6-2) ← 이번에 추가!
```

같은 자리에 같은 모양으로 들어가요. **패턴이 굳어지는 순간이에요.**

---

## Spring 비유 — @Service 빈이 둘로 늘었어요

Spring으로 비유하면 이런 느낌이에요.

```java
@Service
class EmailService { ... }     // 6-1처럼: 첫 번째 Service

@Service
class SmsService { ... }       // 6-2처럼: 두 번째 Service. 같은 자리에 같은 모양
```

Controller(= GameScene)는 둘 다 똑같이 주입받아서 똑같이 호출해요:

```java
emailService.send(...);
smsService.send(...);
```

Swift에서는:

```swift
haptics.light()              // 6-1
audio.play(.noteCollected)   // 6-2
```

**똑같은 자리에, 똑같은 모양으로**. 패턴이 반복되면 머리에 새겨져요.

---

## enum + computed property — 또 등장한 친구

이전에 Phase 5-3에서 캐릭터 속도를 만들 때 이런 모양을 봤어요.

```swift
enum CharacterID {
    case kim, na, gu
    var playerSpeedMultiplier: CGFloat {
        switch self {
        case .kim: return 1.0
        case .na:  return 1.2
        case .gu:  return 0.85
        }
    }
}
```

이번에도 **똑같은 모양**이에요.

```swift
enum SFX {
    case noteCollected, gameOver
    var systemSoundID: SystemSoundID {
        switch self {
        case .noteCollected: return 1057   // Tink
        case .gameOver:      return 1073   // Boop
        }
    }
}
```

**Java sealed class와 같은 안전망**이에요.

만약 나중에 `.combo` 케이스를 추가하면, Xcode가 **빨간 줄을 그어서 "야! 1057, 1073 옆에 1234도 적어!"** 라고 강제해요.

> `default:` 절을 쓰면 이 안전망이 사라져요. 새 케이스를 까먹어도 컴파일러가 안 잡아요.
> 그래서 **SPEC에 "default 절대 금지"** 라고 못 박은 거예요.

---

## 매직 넘버 정책의 미묘함 — 1057은 왜 GameConfig에 안 넣었을까?

평소 규칙은 이래요:

> 숫자(매직 넘버)는 GameConfig에 모은다. 예: `playerSpeed = 400`, `gameDuration = 45`

그런데 이번에 1057, 1073은 GameConfig에 **안** 넣었어요. 왜요?

**이건 게임 튜닝 숫자가 아니라, Apple이 정해놓은 시스템 사운드 ID예요.**

| 종류 | 예시 | 어디에 둘까? |
|---|---|---|
| 게임 튜닝 숫자 | 점수, 속도, 시간 | **GameConfig** (자주 조정함) |
| 외부 시스템 ID | Apple 사운드 ID, HTTP 상태 코드, URL | **자기 도메인 타입 내부** (절대 안 바뀜) |

Spring으로 치면:
- application.yml → 게임 튜닝 숫자 (GameConfig 같은 거)
- HTTP `200`, `404` → 그냥 코드 안에 — `application.yml`에 안 적잖아요?

1057, 1073은 후자예요. **Apple 도메인 안에서만 의미가 있는 숫자**라 SFX enum 안에 두는 게 맞아요.

---

## 멀티모달 피드백 동기화 — 한 사건, 두 감각

이 작업의 가장 멋진 부분이에요.

음표를 1개 먹는 **한 순간**에 두 가지가 동시에 일어나요.

```swift
self.haptics.light()              // 손가락 → 진동 톡
self.audio.play(.noteCollected)   // 귀 → 소리 틱
```

플레이어 입장에서는 **"내가 음표를 먹었다"** 라는 사실을
- 눈으로 보고 (음표 사라짐)
- 손으로 느끼고 (진동)
- 귀로 듣고 (사운드)

**한 사건 → 세 감각**으로 도착해요. 뇌가 "이거 확실히 일어났구나" 하고 강하게 인식해요.

게임이 살아있다고 느껴지는 첫 번째 비결이에요.

---

## 코드 순서: 햅틱 → 사운드 (의미상)

```swift
haptics.light()              // 1번
audio.play(.noteCollected)   // 2번
```

실제로는 한 프레임(1/60초) 안이라 사람은 차이를 못 느껴요.
그래도 **순서를 약속**해 두면:
- 촉각(즉각·물리적) → 청각(논리적·살짝 지연)
- 가까운 감각 → 먼 감각

코드 읽을 때도 흐름이 자연스러워요. **약속을 정해두는 게 미래의 나를 돕는 거예요.**

---

## 빌드 시스템에 새 파일 알리기 (pbxproj 4지점)

Xcode 프로젝트에 새 파일을 추가할 때마다 `project.pbxproj`에 **정확히 4곳**을 손봐야 해요.

지난번 HapticsManager가 ID `...0025`였으니, AudioManager는 `...0026`을 썼어요.

| 지점 | 역할 |
|---|---|
| PBXBuildFile | "이 파일을 빌드 대상에 포함시켜" |
| PBXFileReference | "이 파일이 디스크에 있어" |
| Managers PBXGroup children | "이 파일은 Managers 그룹 안에 있어" |
| iOS Sources phase | "iOS 빌드할 때 컴파일해" |

`grep "AudioManager" project.pbxproj` 했을 때 정확히 **4건**이어야 해요. 그래야 성공.

---

## 한 줄로 정리하면

> **6-1에서 만든 Manager 패턴을 한 번 더 반복**해서 패턴을 내면화했고,
> **enum + computed property** 전략도 한 번 더 써서 굳혔고,
> **외부 도메인 숫자는 GameConfig 밖**이라는 미묘한 정책도 배웠어요.
> 그 결과 게임이 손가락·눈·귀 **세 감각**으로 동시에 말을 걸게 되었어요.

이제 게임은 진짜 "살아있는" 느낌이에요. BGM은 다음 sprint!
