# 22 · Phase 3-5 · 누적 통계 — Codable + JSON으로 구조체 저장 📊

> **이번 작업 한 줄**: 게임을 몇 번 했는지(`playCount`)와 점수를 다 합치면 얼마인지(`totalScore`)를 영구 저장한다. 단일 숫자가 아니라 **두 값이 든 구조체**를 *Codable + JSON*으로 통째 저장하는 첫 사례.

---

## 1. 왜?

지난 sprint(3-4)에서는 *최고 점수* 1개를 UserDefaults에 직접 저장했다. 이번에는 항목이 *둘 이상*이다 — `playCount` + `totalScore`. 단순한 방법은 두 키(`playCount`, `totalScore`)로 따로 저장하는 것이지만:

- 키가 늘어날수록 **이름 짓기·오타·동기화 깨짐** 위험이 커진다
- "한 번의 게임 끝"에서 *둘 다 같이 갱신*되어야 하는데, 두 키가 따로 저장되면 *중간에 앱이 죽으면 한쪽만 갱신*되어 정합성이 깨질 수 있다
- 향후 항목이 더 늘어나면(예: 콤보 최대치, 누적 시간) Repository 코드가 폭발한다

해결책: **두 값을 한 구조체에 넣고, 그 구조체를 통째로 저장**한다. Swift는 `Codable`이라는 이름의 **자동 직렬화 마법**을 기본 제공한다. 한 줄(`struct GameStats: Codable { ... }`)이면 JSON으로 인코딩/디코딩이 모두 자동.

> Spring으로 치면: 지금까지는 `String` `Integer` 단일 값을 캐시에 넣었다면, 이번부터는 **DTO 객체를 JSON으로 직렬화해서 통째 저장**하는 단계로 진화. Jackson `ObjectMapper.writeValueAsString` + `readValue`와 동일한 사고.

---

## 2. Spring 비유 ⭐

| Swift / iOS | Spring | 한 줄 설명 |
|---|---|---|
| `struct GameStats: Codable` | `class GameStatsDto implements Serializable` | 직렬화 가능한 값 객체 |
| `JSONEncoder().encode(stats)` | `objectMapper.writeValueAsString(dto)` | 객체 → JSON 문자열(Data) |
| `JSONDecoder().decode(GameStats.self, from: data)` | `objectMapper.readValue(json, GameStatsDto.class)` | JSON → 객체 복원 |
| `defaults.set(data, forKey: ...)` | `cache.put(key, json)` | 키-값 저장소에 JSON 넣기 |
| `defaults.data(forKey: ...)` | `cache.get(key)` | 꺼내기 |
| `final class StatisticsRepository` | `@Repository public class StatisticsRepository` | 영속 캡슐화 |

**핵심**: *두 가지 변환을 합친 패턴*이 핵심.
1. **객체 ↔ JSON Data**: `JSONEncoder` / `JSONDecoder`
2. **JSON Data ↔ UserDefaults**: `defaults.set(data:)` / `defaults.data(forKey:)`

이 두 단계를 Repository가 *합쳐서 감춘다*. 호출부는 `repo.current`(GameStats 객체)와 `repo.recordPlay(score:)`만 본다.

---

## 3. 새로 배운 것 (Swift/iOS) ⭐

### 3-1. **`Codable` — Swift의 자동 직렬화**

```swift
struct GameStats: Codable {
    var playCount: Int = 0
    var totalScore: Int = 0
}
```

**`Codable`만 붙이면**:
- 컴파일러가 *자동으로* `init(from decoder:)` / `encode(to encoder:)` 메서드를 생성
- `JSONEncoder` / `JSONDecoder`와 결합하면 **객체 ↔ JSON 변환 무료**
- 필드 이름이 그대로 JSON 키가 됨 (`{"playCount": 5, "totalScore": 47}`)

> Spring으로 치면: Lombok `@Getter @Setter` + Jackson 어노테이션이 *언어 차원에서 기본 제공*. 별도 라이브러리/어노테이션 불필요.

### 3-2. **`JSONEncoder` / `JSONDecoder` — 객체 ↔ Data**

```swift
// 저장 (객체 → Data)
let stats = GameStats(playCount: 5, totalScore: 47)
let data = try JSONEncoder().encode(stats)
// data 는 Foundation.Data 타입. 내용은 {"playCount":5,"totalScore":47} 의 바이트.

// 복원 (Data → 객체)
let restored = try JSONDecoder().decode(GameStats.self, from: data)
// restored.playCount == 5, restored.totalScore == 47
```

**왜 try?**
- 인코딩은 거의 실패하지 않지만, *디코딩은 실패할 수 있음*. 예: 다른 앱 버전에서 저장한 JSON 형식이 바뀌었거나, 데이터가 손상되었거나.
- Swift는 `try` 키워드로 *실패 가능성*을 *문법 차원에서 강제*. 실패 시 catch로 처리하거나, 기본값으로 폴백.

> Spring으로 치면 `throws JsonProcessingException`을 메서드 시그니처에 적어서 컴파일러가 "예외 처리 강제"하는 것과 동일. 단 Swift는 `try?`로 옵셔널 변환도 가능.

### 3-3. **`try?` — 실패 시 nil로 안전 폴백**

```swift
let stats = (try? JSONDecoder().decode(GameStats.self, from: data)) ?? GameStats()
```

- `try?`는 실패 시 `throw` 대신 **`nil`** 반환 → 옵셔널.
- `?? GameStats()`로 nil이면 *기본값 인스턴스*로 폴백 → 첫 실행, 손상 데이터 모두 자동 복구.

> Spring으로 치면 `try { ... } catch (Exception e) { return new Dto(); }` 한 줄에 압축. **읽기 실패는 자동 기본값**이라는 명확한 정책.

### 3-4. **저장소 패턴이 그대로 자라난다**

```swift
final class StatisticsRepository {
    private let key: String
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard,
         key: String = GameConfig.statisticsUserDefaultsKey) {
        self.defaults = defaults
        self.key = key
    }

    var current: GameStats {
        guard let data = defaults.data(forKey: key) else { return GameStats() }
        return (try? JSONDecoder().decode(GameStats.self, from: data)) ?? GameStats()
    }

    func recordPlay(score: Int) {
        var stats = current
        stats.playCount += 1
        stats.totalScore += score
        guard let data = try? JSONEncoder().encode(stats) else { return }
        defaults.set(data, forKey: key)
    }
}
```

3-4의 `HighScoreRepository`와 **구조가 거의 동일**. 차이는:
- 저장 단위가 `Int` → `Data`(JSON으로 직렬화된 구조체)
- `current`가 계산 프로퍼티 + 디코딩 1회
- `record(_:)`가 `recordPlay(score:)`로 의도 명확화 — *플레이 1회의 흔적을 남긴다*는 동사

> 좋은 패턴은 자라기 좋다(2탄). Repository는 동일, 안에 든 데이터 모양만 진화.

### 3-5. **불변 vs 가변 구조체**

```swift
struct GameStats: Codable {
    var playCount: Int = 0    // var — 변경 가능
    var totalScore: Int = 0
}
```

`HighScoreRepository`의 키/디폴츠는 `let` 불변이었다. `GameStats`의 필드는 왜 `var`?
- **저장 시점에 누적 갱신이 필요하기 때문**. `stats.playCount += 1`을 해야 함.
- 단, ResultScene이 받는 `GameStats` 인스턴스는 *그 자체로 불변* — Swift의 *struct 값 의미*(value semantics) 때문에 ResultScene 안에서 `stats.playCount = 999`로 바꿔도 *원본은 변하지 않음*. 복사된 자기 사본만 바뀜.

> Spring으로 치면 "Java 객체는 reference 의미라 가변이 위험 → final 필드 선호". Swift struct는 *기본이 value 의미*라 var 필드여도 안전.

### 3-6. **저장 시점 정합성**

지난 sprint(3-4)는 `record → current` 순서가 핵심이었다. 이번은:

```swift
// GameScene.endGame
let isNewBest = highScoreRepo.record(score)
let bestScore = highScoreRepo.current
statsRepo.recordPlay(score: score)        // 추가 — 둘 다 같은 frame에서 갱신
let stats = statsRepo.current             // 갱신된 통계 조회
let resultScene = ResultScene.newResultScene(
    score: score, bestScore: bestScore, isNewBest: isNewBest, stats: stats
)
```

**둘 다 동일 endGame 호출 안에서 갱신** → 중간에 앱이 죽어도 *한 쪽만 갱신*되는 일은 거의 없음(메모리 set 후 OS가 디스크 flush 보장). 단, 두 키가 *동일 트랜잭션은 아님* — 진짜 중요하면 한 Repository로 통합해야 함(향후 옵션 C 마이그레이션).

### 3-7. **표시 변경 = 라벨 1개 추가**

라벨 한 줄 추가해서 두 값을 한 줄에 표시:
```swift
statsLabel.text = "PLAYS \(stats.playCount)  /  TOTAL \(stats.totalScore)"
```

ResultScene은 기존 4 라벨 → 5 라벨, TitleScene은 3 → 4 라벨. 좌표만 GameConfig에서 살짝 재조정.

---

## 4. 무엇을 만드나?

### 새 파일 (2개)
| 파일 | 역할 |
|---|---|
| `Models/GameStats.swift` | `Codable` 값 객체. `playCount`, `totalScore` 두 필드. 기본값 모두 0 |
| `Repositories/StatisticsRepository.swift` | UserDefaults에 GameStats를 JSON으로 저장. `current` 조회 + `recordPlay(score:)` 갱신 |

### 고치는 파일 (4개)
| 파일 | 변경 |
|---|---|
| `Scenes/ResultScene.swift` | `newResultScene` 시그니처에 `stats: GameStats` 추가 + `statsLabel` 5번째 라벨 추가 |
| `Scenes/TitleScene.swift` | `playsLabel` 4번째 라벨 추가, `setupLabels`에서 `StatisticsRepository().current.playCount` 조회 |
| `GameScene.swift` | `private let statsRepo = StatisticsRepository()` + endGame에서 `recordPlay(score:)` + ResultScene init에 stats 주입 |
| `Config/GameConfig.swift` | `statisticsUserDefaultsKey` + `resultStatsOffsetY` + `resultStatsFontSize` + `titlePlaysOffsetY` + `titlePlaysFontSize` 등 상수 + 기존 offset 라벨 수 증가에 따른 미세 조정 |

### Xcode pbxproj
- `GameStats.swift`, `StatisticsRepository.swift` 2파일 등록 (Models 그룹 신설 + Repositories 그룹 children에 추가, iOS Sources phase 2개 추가)

### 한 그림으로

```
[GameScene.endGame]
    highScoreRepo.record(score)            ← 기존 (3-4)
    statsRepo.recordPlay(score: score)     ← 추가 (3-5)
    presentScene(ResultScene(score, bestScore, isNewBest, stats), fade)

[ResultScene]
    GAME OVER
    🎵 12
    ★ NEW BEST! ★    또는    BEST 🏆 20
    PLAYS 5  /  TOTAL 47    ← 추가
    TAP TO RETURN

[TitleScene]
    김간호는 음악박사
    BEST 🏆 20
    PLAYS 5                  ← 추가
    TAP TO START
```

---

## 5. 직접 확인할 것

⌘R 후:

| # | 시나리오 | 봐야 할 것 |
|---|---|---|
| (a) | 앱 삭제 후 첫 실행 | 타이틀 BEST 🏆 0 / PLAYS 0 |
| (b) | 한 판 (점수 5) | ResultScene "PLAYS 1 / TOTAL 5" |
| (c) | 타이틀 복귀 | "PLAYS 1" |
| (d) | 한 판 (점수 3) | ResultScene "PLAYS 2 / TOTAL 8" (5+3) |
| (e) | 한 판 (점수 8) | ResultScene "PLAYS 3 / TOTAL 16" (8+3+5) |
| (f) | 타이틀 복귀 | "PLAYS 3" / "BEST 🏆 8" |
| (g) | 앱 강제 종료 후 재실행 | "PLAYS 3 / BEST 🏆 8" 유지 |
| (h) | (선택) UserDefaults 키 직접 손상 | 기본값 GameStats()로 폴백 (앱 안 죽음) |

---

## 6. 사용자 결정 (이미 합의)

| 결정 | 선택 | 왜 |
|---|---|---|
| 통계 항목 | `playCount`, `totalScore` (2개만) | 가장 기본적, 본 sprint 작게 유지 |
| 저장소 | **B안** — `StatisticsRepository` 신설 (`HighScoreRepository`는 그대로) | 검증된 패턴 보존 + 새 패턴 학습 |
| 통합/마이그레이션 | 안 함 (Phase 4 이후 검토) | 회귀 위험 ↓, 본 sprint 명확성 ↑ |
| 표시 위치 | 양쪽 (ResultScene + TitleScene) | UserDefaults 다중 화면 read 패턴 일관 |
| 데이터 모델 | `struct GameStats: Codable` | 값 의미, 자동 직렬화 |

---

## 7. 회고

### 7-1. 막혔던 것

**없음.** 한 사이클(QA 1회)에 9.825/10 합격. P0/P1 0건, P2 1건(GameScene.swift 340줄 — 본 sprint 범위 외 기존 부채).

지난 두 sprint(3-3 ResultScene 분리, 3-4 HighScoreRepository)에서 닦아둔 패턴이 **그대로 자라서** 이번 작업이 매끄럽게 끝남. Repository 패턴은 두 인스턴스(`HighScoreRepository`, `StatisticsRepository`)가 공존, init 주입 패턴은 1→3→4 인자로 자연 확장.

### 7-2. 새로 배운 것

1. **`Codable`만 붙이면 직렬화 무료** — `struct GameStats: Codable`은 컴파일러가 init/encode/decode를 자동 합성. **별도 init 작성 금지** — Lombok + Jackson을 *언어 차원에서 기본 제공*하는 셈.
2. **`JSONEncoder` / `JSONDecoder` — 객체 ↔ Data** — `try JSONEncoder().encode(stats)`는 `Foundation.Data` 반환. `defaults.set(data, forKey:)`로 UserDefaults에 통째 저장. 두 단계 변환을 Repository가 합쳐서 감춤.
3. **`try?` + `??` 두 단계 폴백** — `(try? decode(...)) ?? GameStats()`. 디코딩 실패는 nil로 받고, nil이면 기본값 인스턴스. 손상된 JSON에서도 *앱이 죽지 않는다*. 첫 실행도 같은 경로(`data == nil`)로 자연 처리.
4. **`var` 필드의 안전성 — struct value semantics** — `GameStats`는 var 필드를 가지지만, *값 의미*라 ResultScene이 받은 인스턴스를 수정해도 *원본은 변경되지 않음*. 복사된 자기 사본만 변경. Java reference 의미와 정반대.
5. **Repository 패턴의 자연 확장** — HighScoreRepository(Int) → StatisticsRepository(Codable struct). 골격(MARK 4섹션, DI init 두 기본값 인자, 단일 메인 스레드 가정, 락/큐 없음)은 동일, 데이터 모양만 진화.
6. **저장 시점 정합성 — 두 Repository가 한 frame에서 갱신** — `record → current(best) → recordPlay → current(stats)` 4단 호출. 둘 다 메인 스레드 + 같은 endGame 안에서 → "한쪽만 갱신" 위험 거의 0. 진짜 단일 트랜잭션이 필요하면 두 Repository를 합쳐야 함(향후 옵션 C 마이그레이션).
7. **5/4 라벨 균형 = +80/+40/0/-40/-80 패턴** — 라벨 수가 늘어날 때 인접 간격 ≥ 30pt 보장이 가독성의 절대 조건. 본 sprint는 40 간격으로 안전. 향후 6 라벨이면 +75/+45/+15/-15/-45/-75 같은 변형.
8. **인코딩 실패 폴백 = 조용히 무시** — `guard let data = try? encode(...) else { return }`. 다음 호출에서 다시 시도. 사용자에게 알람 안 띄움. UI 피드백이 필요한 영역(파일 업로드 등)과 다른 *백그라운드 영속*의 정책.

### 7-3. 다음으로 미룬 것

- **Phase 4 진입**: 추가 NPC와 깜짝 이벤트 (석조무사·이교수·박병장 비행기) — AI 패트롤, 이벤트 트리거
- **저장소 통합 (옵션 C)**: HighScore + Stats를 단일 `GameStats` 안으로 흡수 + 마이그레이션. 본 sprint 종결 후 별도
- **GameScene 분리** (P2 권고): 340줄 → `GameScene+Setup` extension으로 9개 setup 메서드 분리. spritekit-rules §11 가이드 회복
- **3-5 확장**: 콤보 최대치, 누적 시간 등 추가 통계 항목

### 7-4. 평가 점수

- **가중평균: 9.825 / 10 — 합격** 🎉 **Phase 3 완전 종결**
- 항목별: Swift 패턴 9.5 / 게임 로직 10 / 성능·안정성 10 / 기능 완성도 10
- P0 0건, P1 0건, P2 1건 (GameScene 340줄 기존 부채 — SPEC 범위 외)
- 빌드: BUILD SUCCEEDED, 경고 0건 (iPhone 17 Simulator)

### 7-5. Phase 3 종결 종합

| Sprint | 한 줄 | 점수 | GameScene 줄 수 |
|---|---|---|---|
| 2-12 | (Phase 2 종결 시점) | 9.675 | 315 |
| **3-1+2** | TitleScene + GameOver 오버레이 + 씬 전환 | 9.675 | 354 |
| **3-3** | ResultScene 분리 (오버레이 폐기) | 9.83 | 325 |
| **3-4** | UserDefaults 최고 점수 (HighScoreRepository) | **10.0** | 334 |
| **3-5** | Codable 통계 (StatisticsRepository) | 9.825 | 340 |

**Phase 3 핵심 가치**:
- **씬 전환 사이클 완성**: 타이틀 → 게임 → 결과 → 타이틀 (단방향 루프)
- **영속 계층 정착**: UserDefaults 단일 Int(3-4) → Codable struct(3-5)로 진화
- **Repository 패턴**: Spring `@Repository` 멘탈 모델 그대로 적용. DI 친화 init 두 기본값 인자
- **씬 init 주입 패턴 확장**: 0인자 → 1인자 → 3인자 → 4인자, 패턴은 동일
- **MVP를 넘어 "한 사이클 완결 + 영속 발자국"으로 진화**

> 이번 sprint 본질: *영속의 진화*. 단일 숫자에서 → 구조체로. **Codable + JSON**이라는 Swift 핵심 개념을 한 줄(`: Codable`)에 도입. Repository 패턴은 그대로 자라나 두 번째 인스턴스로 확장. 다음 단계(Phase 4)에서 게임플레이 자체로 돌아가기 전에, *데이터 계층의 토대*가 한 단계 단단해졌다.

---

## 8. 다음 작업

```
[1] 시뮬레이터에서 §5 (a)~(g) 확인
[2] Phase 3 종결 🎉
[3] 다음 sprint: Phase 4 진입 (추가 NPC) 또는 저장소 통합 리팩터
```

> **이번 sprint 본질**: *영속의 진화*. 단일 숫자(3-4)에서 → 구조체(3-5)로. **Codable + JSON**이라는 Swift 핵심 개념을 한 줄(`: Codable`)에 도입. Repository 패턴은 그대로 자라나 두 번째 인스턴스(`StatisticsRepository`)로 확장. 다음 단계(Phase 4)에서 게임플레이 자체로 돌아가기 전에, *데이터 계층의 토대*가 한 단계 단단해진다.
