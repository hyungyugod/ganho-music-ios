# Phase 6-1 — 진동 매니저 (HapticsManager)

## 한 줄 요약
음표를 먹으면 "톡!", 게임이 끝나면 "툭!" 하고 휴대폰이 진동하게 만들었어요.

---

## 무엇을 했나요?

iPhone에는 작은 모터가 들어있어서 **진동**을 만들 수 있어요.
이번에 한 일은 두 가지 진동을 게임에 붙인 거예요.

1. **음표를 먹을 때** → 가벼운 진동 (light)
2. **게임이 끝날 때** → 묵직한 진동 (heavy)

그리고 이걸 깔끔하게 정리해 두는 **상자**를 만들었어요. 이 상자 이름이 `HapticsManager`예요.

---

## 왜 따로 상자를 만들었을까?

게임 코드 곳곳에 진동 명령을 막 흩어놓으면 나중에 정신없어져요.
그래서 **진동에 관한 일은 전부 이 상자한테 맡기자**고 약속한 거예요.

```
[게임] → "야, 진동 좀 해줘" → [HapticsManager] → iPhone 모터 부르릉
```

게임은 진동이 어떻게 작동하는지 몰라도 돼요. 그냥 `haptics.light()` 한 줄만 외치면 끝이에요.

---

## Spring 비유 — @Service 빈의 첫 등장

Spring 쓰셨을 때 기억하시죠?

| Spring | Swift (이번 작업) |
|---|---|
| `@Service` 빈 | `HapticsManager` 클래스 |
| `@Repository` 빈 | `HighScoreRepository`, `StatisticsRepository` 등 |

지금까지 Phase 5 동안 만든 게 다 **Repository**였어요 (점수 저장, 통계 저장, 캐릭터 선택 저장…). Repository는 **데이터를 어디에 적어두는** 일을 해요.

이번에 처음 등장한 게 **Manager (= Service)**예요. Manager는 **데이터가 아니라 행동**을 해요.

| 비교 | Repository (적기) | Manager (행동) |
|---|---|---|
| 무엇을 하나? | UserDefaults에 점수 저장 | 진동 발생 |
| 결과물 | 저장된 값 | 사용자가 느끼는 느낌 |
| 호출 후 뭐가 남나? | 디스크에 데이터 | 아무것도 안 남음 (부수효과만) |

Spring으로 치면 — `UserRepository.save(user)`는 DB에 한 줄 추가하고, `EmailService.sendWelcome(user)`는 메일 보내고 끝이죠. HapticsManager는 후자예요.

---

## prepare()는 뭐고 왜 두 번 부르나?

진동 모터는 켜자마자 바로 부릉~ 하지 않아요. **준비 시간**이 살짝 필요해요.
그래서 `prepare()`로 "이제 곧 부를 거니까 미리 시동 걸어둬"라고 말해줘요.

코드에서 `prepare()`를 **두 번** 부르고 있어요:

1. **init에서 1번** — 게임 시작할 때 미리 시동
   → 첫 음표 수집 때 지연 없이 바로 진동

2. **impactOccurred() 직후마다** — 진동 끝나자마자 다음 시동
   → 음표를 연달아 먹어도 끊김 없이 톡톡톡

### Spring 비유 — 캐시 워밍 (Cache Warming)

Spring에서 자주 쓰는 패턴 있죠?
- 서버 뜨자마자 **자주 쓸 데이터를 미리 캐시에 올려두기**
- 응답할 때 0.1초라도 빠르게

`prepare()`도 똑같아요. **진동의 캐시 워밍**이에요.

---

## light()와 heavy() — 다형성처럼

```swift
func light() { lightGenerator.impactOccurred(); lightGenerator.prepare() }
func heavy() { heavyGenerator.impactOccurred(); heavyGenerator.prepare() }
```

UIImpactFeedbackGenerator는 만들 때 **스타일**을 정해요 (`.light`, `.medium`, `.heavy`, `.rigid`, `.soft`).
같은 함수(`impactOccurred`)인데 스타일에 따라 다른 진동이 나와요.

Java로 치면:
```java
interface Feedback { void trigger(); }
class LightFeedback implements Feedback { ... }
class HeavyFeedback implements Feedback { ... }
```
이런 다형성과 비슷해요. 우리는 그냥 enum case 두 개로 표현했을 뿐.

---

## 게임 안 트리거 2곳

### 1. 음표 수집 — light()
```swift
contactRouter.onNoteCollected = { [weak self] note in
    guard let self = self else { return }
    self.scoreSystem.recordNoteHit(at: self.lastUpdateTime)
    self.haptics.light()   // ← 여기!
    note.run(.removeFromParent())
}
```

순서가 중요해요:
1. 점수 먼저 기록 (`recordNoteHit`)
2. **그 다음 진동** (`haptics.light()`)
3. 마지막에 음표 제거 (`removeFromParent`)

진동을 점수 기록 *바로 뒤*에 넣은 이유 — 사용자가 점수가 화면에 뜨기 *전*에 손끝으로 먼저 느끼게 하려고.

### 2. 게임오버 — heavy()
```swift
private func endGame() {
    if gameState == .gameOver { return }   // 멱등 가드
    gameState = .gameOver
    haptics.heavy()   // ← 여기!
    spawnSystem.stop()
    ...
}
```

**멱등 가드 직후**가 핵심이에요. 멱등 가드란?
- 게임오버가 두 번 호출돼도 한 번만 실행되게 막는 자물쇠
- 적이랑 부딪치는 동시에 F도 맞으면 endGame()이 두 번 호출될 수 있어요

가드 뒤에 진동을 넣었으니 **진동도 무조건 1번만** 발생해요. 두 번 부르르 떨리는 일 없어요.

---

## 시뮬레이터에서 시험하면?

시뮬레이터(컴퓨터 안의 가짜 iPhone)에는 진동 모터가 없어요.
근데 코드는 그대로 둬도 괜찮아요. UIKit이 알아서 **무시(noop)** 해줘요.
크래시 안 나고, 에러도 안 떠요. 그냥 조용히 넘어가요.

실기기(진짜 iPhone)에 올려서 빌드하면 그때 진동이 느껴져요.

---

## 폴더 구조 — Managers/ 신설

이번에 처음으로 `GanhoMusic Shared/Managers/` 폴더가 등장했어요.

```
GanhoMusic Shared/
├── Config/         ← 상수 (gameDuration 등)
├── Models/         ← 데이터 (GameStats, CharacterID)
├── Nodes/          ← 화면에 보이는 것 (PlayerNode 등)
├── Scenes/         ← 화면 단위 (TitleScene, GameScene, ResultScene)
├── Systems/        ← 게임 로직 (SpawnSystem, ScoreSystem)
├── Repositories/   ← 데이터 저장 (HighScoreRepository)
├── Protocols/      ← 약속 (SelfDismissingNode)
└── Managers/       ← 부수효과 (HapticsManager) ← 신규!
```

Spring과 거의 1:1 대응이에요:
- `Scenes/` ↔ `controllers/`
- `Systems/` ↔ `services/`
- `Repositories/` ↔ `mappers/`
- `Managers/` ↔ Spring의 `@Service` 빈 중에서도 **외부 효과 전담** (이메일 발송, 푸시 알림 같은 것)

앞으로 AudioManager(소리), AnalyticsManager(로그 보내기) 같은 게 같은 폴더에 추가될 거예요.

---

## 정리

| 배운 것 | 한 마디로 |
|---|---|
| Manager 패턴 | 부수효과 전담 서비스 빈 |
| Repository vs Manager | 데이터 저장 vs 행동 발생 |
| prepare() | 첫 호출 지연 줄이는 캐시 워밍 |
| Light vs Heavy | enum case로 표현하는 다형성 |
| 멱등 가드 | 두 번 호출돼도 한 번만 실행 |

다음 단계는 AudioManager(효과음) 추가 — 같은 Manager 폴더에 형제가 생길 거예요.
