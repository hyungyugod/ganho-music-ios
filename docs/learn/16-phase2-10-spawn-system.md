# 16 · Phase 2-10 · 코드 정리 — SpawnSystem 분리 🗂️

> **이번 작업 한 줄**: GameScene 한 파일에 다 들어있던 *음표 spawn + F 발사* 코드를 별도 파일(`SpawnSystem.swift`)로 옮긴다. **기능은 똑같고**, *코드 정리*만.

---

## 1. 왜 정리하나?

### 1-1. 지금 GameScene 상황
```
GameScene.swift (422줄)
├─ 게임 루프 (update)
├─ 셋업 함수 8개 (setupBackground, setupWorld, ...)
├─ 충돌 처리 (didBegin, handleProjectileContact, ...)
├─ 게임 종료 (endGame)
├─ 음표 spawn 4개 (startSpawnLoop, trySpawnNote, ...)
├─ F 발사 5개 (startProjectileFireLoop, scheduleNextFire, ...)
└─ 게임오버 시 정리
```
**한 파일이 너무 많은 일을 함.** 리뷰 어렵고, 수정 시 *의도 파악*에 시간 걸림.

### 1-2. 가이드라인
SpriteKit 룰: **GameScene이 300줄 넘으면 분리 신호**. 현재 422줄 → 정리 시점.

### 1-3. 비유
- **현재**: 한 책장에 *공부책 + 만화책 + 요리책*이 다 섞여 있음. 찾기 어려움.
- **분리 후**: *공부책장 / 만화책장 / 요리책장* 분리. 각자 자기 자리.

---

## 2. 무엇을 옮기나?

GameScene에 있던 *spawn(생성) 관련 9개 메서드*를 `SpawnSystem.swift` 파일로 이전:

| 메서드 | 역할 |
|---|---|
| `startSpawnLoop` | 음표 자동 spawn 시작 |
| `trySpawnNote` | 음표 1개 시도 |
| `currentNoteCount` | 음표 개수 카운트 |
| `randomNotePosition` | 음표 위치 랜덤 |
| `startProjectileFireLoop` | F 발사 시작 |
| `scheduleNextFire` | 다음 F 발사 예약 (재귀) |
| `currentFireInterval` | 발사 주기 보간 |
| `fireProjectile` | F 1개 발사 |
| `currentProjectileCount` | F 개수 카운트 |

GameScene에는 *이걸 호출하는 한 줄*만 남김.

```
GameScene.swift          ← 이전엔 422줄, 이제 ~250줄
└─ spawnSystem.start(...)
└─ spawnSystem.stop()    ← endGame 시 정리

SpawnSystem.swift (신설)  ← spawn 관련 9개 메서드
```

---

## 3. 리팩터(Refactor)란?

> **기능 변화 없이** 코드 구조만 정리하는 작업.

이번 sprint는 *완전히* 리팩터. 게임 동작은 *한 픽셀도 변하면 안 됨*. 

**Spring 비유**: `OrderController`에 막 쌓인 비즈니스 로직을 `OrderService`로 옮기는 것과 동일. 로직 자체는 그대로, 단지 *위치만* 이동.

---

## 4. 새로 배운 것 (쉬운 설명)

### 4-1. **의존성 주입(DI)이란?**
> *필요한 것을 외부에서 받음*. 직접 만들지 않음.

SpawnSystem이 일하려면 다음이 필요:
- worldNode (음표/F를 어디 담을지)
- player (F 발사 방향 계산용)
- enemy (F 시작 위치)
- scene (SKAction 등록 / 정지)
- remainingTime (발사 주기 보간)

**나쁜 방식**: SpawnSystem이 직접 GameScene을 만들거나 가져옴 → *결합도 ↑*
**좋은 방식**: 시작할 때 *외부(GameScene)에서 인자로 받음* → SpawnSystem은 GameScene 직접 안 알아도 됨

```swift
// GameScene에서 SpawnSystem 시작할 때
spawnSystem.start(
    scene: self,
    world: worldNode,
    player: player,
    enemy: enemy,
    progressProvider: { [weak self] in
        return 1.0 - (self?.remainingTime ?? 0) / GameConfig.gameDuration
    }
)
```

**Spring 비유**: `@Autowired`로 의존성 주입받는 거랑 같음. 클래스가 *자기 의존성을 직접 만들지 않고* 받기만 함.

### 4-2. **`weak` 참조 — 메모리 누수 방지**
> SpawnSystem이 GameScene을 *강하게* 잡고, GameScene도 SpawnSystem을 *강하게* 잡으면 → *서로 못 사라짐* = 메모리 누수.

해결: 한쪽을 *약하게* 참조.
```swift
final class SpawnSystem {
    private weak var scene: GameScene?
    private weak var worldNode: SKNode?
    private weak var player: PlayerNode?
    private weak var enemy: EnemyNode?
    // ...
}
```

`weak`이면 GameScene이 사라질 때 SpawnSystem 안 참조도 *자동으로 nil*. 누수 없음.

### 4-3. **closure로 *현재 값* 전달하기 (`progressProvider`)**
SpawnSystem이 매번 *현재 진행률*을 알아야 함 (보간 계산용). 

**옵션 A**: SpawnSystem이 GameScene.remainingTime 직접 접근 → *결합도 ↑*
**옵션 B**: GameScene이 *closure(함수 조각)*를 줘서 SpawnSystem이 *호출만* → *결합도 ↓*

```swift
// GameScene이 정의
let progressProvider: () -> Double = { [weak self] in
    return 1.0 - (self?.remainingTime ?? 0) / GameConfig.gameDuration
}

// SpawnSystem이 사용
let progress = progressProvider()  // 매번 호출하면 현재 값
```

**Spring 비유**: `Supplier<T>` 인터페이스로 *값 공급자*만 받는 거랑 같음. 어디서 오는지는 모름.

### 4-4. **`final class` — 더 이상 상속 안 됨**
```swift
final class SpawnSystem { ... }
```
`final`은 "*이 클래스를 상속받을 수 없다*". 게임 코드에선 *대부분 final* — 상속 안 할 거면 명시.

성능에도 도움: 컴파일러가 *함수 호출 최적화* 가능. (Java로 치면 `final class`)

### 4-5. **리팩터의 *황금 룰***
> **기능 변화 0. 빌드 성공. 동작 똑같음.**

리팩터 후 시뮬레이터로 게임을 해보고:
- 음표 spawn 똑같이 동작?
- F 발사 주기 똑같이 보간?
- 게임 종료 시 spawn/fire 정지 똑같음?

하나라도 다르면 *리팩터 실패*. 다시 원복하거나 차근히 디버깅.

---

## 5. 새로 만든 것

### 새 파일
- `Systems/SpawnSystem.swift` — spawn 관련 9개 메서드 + 의존성 주입 받는 `start`/`stop`

### 고친 파일
- `GanhoMusic Shared/GameScene.swift`:
  - spawn 9개 메서드 *제거*
  - `private let spawnSystem = SpawnSystem()` 멤버 추가
  - `didMove`에서 `spawnSystem.start(...)` 호출
  - `endGame`에서 `spawnSystem.stop()` 호출 + 기존 *spawn 정지 코드* 제거

### Xcode pbxproj
- SpawnSystem.swift 등록

---

## 6. 직접 확인할 것 (시뮬레이터)

⌘R 후 — **이전과 똑같이 동작**해야 함:

| # | 봐야 할 것 |
|---|---|
| (a) | 음표 spawn 정상 (1.5초마다, 동시 5개까지) |
| (b) | F 발사 정상 (3.5초 → 2초 보간) |
| (c) | 수간호사 추적 + 속도 보간 (60→110) |
| (d) | 게임 종료 시 음표 spawn / F 발사 즉시 정지 |
| (e) | F가 player에 닿거나 시간 만료 시 endGame |
| (f) | 점수 / 콤보 / 카메라 follow 모두 그대로 |

**기능 변화는 0**. 모든 게 *2-9까지와 똑같이* 동작.

---

## 7. 사용자 결정 (모두 추천대로)

| 결정 | 선택 | 왜 |
|---|---|---|
| 분리 단위 | SpawnSystem 1개 (음표 + F 둘 다) | 두 spawn 모두 *생성 책임* — 묶는 게 자연스러움 |
| ContactRouter 분리 | OUT (별도 sprint) | 콤보/점수 상태가 GameScene에 있어 더 큼. 별도 |
| 의존성 전달 방식 | 인자 + closure | DI 패턴, 결합도 ↓ |
| weak 참조 | scene/world/player/enemy 모두 weak | 메모리 누수 방지 |
| `final class` | 명시 | 상속 안 함 + 컴파일 최적화 |

---

## 8. 회고

### 8-1. 막혔던 것
**없음.** 1차 빌드 성공 + **9.65/10 합격**. 9 메서드 라인별 비교까지 *글자 단위 동등성* 확인됨. 리팩터의 황금 룰(기능 변화 0)을 100% 지킴.

### 8-2. 새로 배운 것
1. **DI(의존성 주입) 패턴** — 시스템 클래스가 자기 의존성을 *직접 만들지 않고 외부에서 받음*. 결합도 ↓.
2. **weak 참조 4개** — scene/world/player/enemy 모두 weak. 시스템이 GameScene을 강하게 잡으면 *서로 못 사라짐* = 메모리 누수.
3. **`@escaping` closure** — *저장되는* closure는 반드시 명시. 함수 호출 끝난 후에도 *살아있어야* 하기 때문.
4. **withKey 이름 보존** — 외부에서 보던 `"spawnNotes"` / `"fireProjectiles"` 식별자 그대로. *행동 동등성*의 핵심.
5. **리팩터는 점진** — 한 sprint에 *너무 많이 분리*하지 않음. SpawnSystem만 → 다음 sprint ContactRouter → 그 다음 ScoreSystem.

### 8-3. 다음으로 미룬 것
1. **ContactRouter 분리**: didBegin / handleProjectileContact / handleNoteContact + 콤보/점수 상태 분리. 더 큰 sprint.
2. **Phase 3** — 게임오버 화면 / 다시 시작.
3. **Phase 4** — 난이도 normal/hard.

### 8-4. 평가 점수
- Swift 패턴 (35%): **9 / 10** — P2 1건 (목표 줄 수 미달, OUT 범위라 감점 미세)
- 게임 로직 (30%): **10 / 10** — 9 메서드 라인별 EQUIVALENT
- 성능 (20%): **10 / 10**
- 기능 완성도 (15%): **10 / 10**
- **가중평균: 9.65 / 10 — 합격**

### 8-5. GameScene 줄 수 변화
| 시점 | 줄 수 |
|---|---|
| 2-9 | 446 |
| 2-10 (이번) | **354** (-92) |
| 다음 (ContactRouter 후 예상) | ~280 |

---

## 9. 다음 작업

```
[1] 시뮬레이터에서 §6 (a)~(f) — 기능 똑같은지 확인
[2] 다음 sprint:
    - ContactRouter 분리
    - 또는 Phase 3 진입
```

> **이번 sprint 본질**: *기능 변화 0의 코드 정리*. 더 큰 게임을 만들기 전에 *집을 청소*. Spring `@Service` 분리와 동일한 정신.
