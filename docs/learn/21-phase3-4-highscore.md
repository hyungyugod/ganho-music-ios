# 21 · Phase 3-4 · 최고 점수 영구 저장 — UserDefaults + Repository 🏆

> **이번 작업 한 줄**: 게임을 끄고 다시 켜도 *내가 도달한 최고 점수*가 기억되도록 한다. iOS의 가장 가벼운 저장소(UserDefaults)에 한 줄(키-값)만 저장하고, **Repository 클래스**로 감싸서 호출 부분이 깨끗하게 한다.

---

## 1. 왜?

지금까지 게임은 **앱을 끄면 점수가 다 사라진다.** 5번을 해서 12점이 최고였어도, 다음에 켜면 다시 0부터. "내 최고 기록"이라는 *자기 발자국*이 없으면 동기 부여가 약해진다. 이번 작업으로 *최고 점수*가 영구 기억되고, **결과 화면**과 **타이틀 화면** 양쪽에 표시된다.

> Spring으로 치면: 지금까지는 "메모리에서만 사는 데이터" → 이번엔 "DB에 저장되는 데이터"의 첫 등장. 단, DB가 아니라 **iOS 내장 키-값 저장소(UserDefaults)** 를 쓴다. 가벼운 설정/숫자/문자열 한두 개에 적합.

---

## 2. Spring 비유 ⭐

| iOS / SpriteKit | Spring | 한 줄 설명 |
|---|---|---|
| `UserDefaults.standard` | `@Value("${some.property}")` 또는 가벼운 KV 저장소 | 앱 종료 후에도 살아남는 키-값 저장소 |
| `defaults.set(20, forKey: "highScore")` | `repository.save(highScore)` | 저장 |
| `defaults.integer(forKey: "highScore")` | `repository.find()` | 조회 (없으면 `0`) |
| `final class HighScoreRepository` | `@Repository public class HighScoreRepository` | 저장소 패턴 — 도메인 로직과 영속 분리 |
| `init(defaults: UserDefaults = .standard)` | 생성자 주입(DI) — 기본값으로 prod, 테스트는 mock 주입 | 의존 주입 가능하게 설계 |

**핵심**: UserDefaults는 *직접* 호출해도 동작은 하지만, **Repository로 감싸 두면**:
1. 호출부에 `forKey: "highScore"` 같은 *문자열 키*가 노출되지 않음 → 오타·중복 위험 ↓
2. 저장 정책이 한 곳에 모임 → 향후 "최고 점수 + 플레이 횟수"로 확장할 때 *Repository 한 파일*만 고치면 됨
3. **Spring `@Repository` 멘탈 모델 그대로** 적용 가능

> "iOS는 Spring처럼 `@Autowired` 빈 주입이 자동은 아니지만, Repository를 *직접 인스턴스화*해서 쓰면 된다." 이게 Swift/iOS의 관용구.

---

## 3. 새로 배운 것 (Swift/iOS) ⭐

### 3-1. **`UserDefaults` — iOS의 가벼운 키-값 저장소**

```swift
let defaults = UserDefaults.standard
defaults.set(20, forKey: "highScore")            // 저장
let best = defaults.integer(forKey: "highScore") // 조회 (없으면 0)
```

- **앱 종료 / 재실행 / 기기 재부팅에도 살아남음.**
- 작은 값(`Int`, `String`, `Bool`, `Date`, `Data`, 또는 이들의 배열/딕셔너리) 전용. 큰 데이터(이미지·다수 객체)는 부적합.
- 저장 시점에 *디스크 기록은 비동기*. 앱이 잠시 후 종료돼도 데이터는 보존됨 (iOS가 내부적으로 보장).

> Spring으로 치면 "프로덕션 등급은 아니지만 application.properties 또는 가벼운 설정 저장소" 정도. 또는 SQLite보다도 가벼운 KV.

### 3-2. **Repository 패턴 — 영속을 캡슐화**

```swift
final class HighScoreRepository {
    private let key = "highScore"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var current: Int {
        return defaults.integer(forKey: key)   // 키가 없으면 0 반환
    }

    /// 새 점수를 기록한다. 신기록이면 true.
    @discardableResult
    func record(_ score: Int) -> Bool {
        guard score > current else { return false }
        defaults.set(score, forKey: key)
        return true
    }
}
```

#### 3-2-1. `private let key = "highScore"`
키 문자열을 **한 곳에만** 둔다. 호출부에서 절대 `"highScore"`를 직접 안 씀.

#### 3-2-2. `init(defaults: UserDefaults = .standard)` — 기본값 매개변수
prod에서는 `HighScoreRepository()`로 호출 → `.standard` 자동 주입.
테스트에서는 `HighScoreRepository(defaults: UserDefaults(suiteName: "test")!)` 식으로 *별도 인스턴스 주입*. **DI(의존성 주입)** 가 한 줄로.

#### 3-2-3. `var current: Int { defaults.integer(forKey: key) }` — 계산 프로퍼티
"읽을 때마다 디폴츠에서 즉시 조회". 캐싱하지 않으니 다른 화면에서 갱신해도 자동 반영.

#### 3-2-4. `@discardableResult` — 반환값을 안 받아도 경고 안 남
```swift
highScoreRepo.record(score)         // 반환값 무시해도 OK
let isNewBest = highScoreRepo.record(score)  // 받아 써도 OK
```
없으면 컴파일러가 "반환값을 안 쓰는데?" 경고를 띄움. 명시적으로 *둘 다 허용*한다는 표시.

> Spring으로 치면 `void` 또는 `boolean` 반환을 자유롭게 — 자바는 컴파일러 경고가 없지만, Swift는 디폴트로 경고를 띄우므로 명시 어노테이션이 필요.

### 3-3. **씬 init 주입 패턴이 그대로 확장됨**

3-3에서 `ResultScene.newResultScene(score:)`을 만들었다. 이번엔 **인자 두 개 추가**:

```swift
class func newResultScene(
    score: Int,
    bestScore: Int,
    isNewBest: Bool
) -> ResultScene
```

- `bestScore`: 현재 최고 점수 (저장 후 조회)
- `isNewBest`: 이번 판이 신기록이면 true → 라벨 분기

**3-3에서 닦아둔 init 주입 패턴이 *변경 없이* 확장된다.** 좋은 패턴은 자라기 좋다는 증거.

### 3-4. **GameScene이 Repository를 직접 보유 vs 매번 새로 만들기**

```swift
// 옵션 A — 프로퍼티로 한 번만
private let highScoreRepo = HighScoreRepository()

// 옵션 B — 매번 새로 (필요할 때만)
let isNewBest = HighScoreRepository().record(score)
```

옵션 A가 표준. *상태가 없는 도구*라도 한 인스턴스를 가지면 의도가 더 명확하고, 향후 의존 주입(테스트용 mock)이 쉬워짐.

> Spring으로 치면 "필드 주입(@Autowired)" vs "메서드 안에서 new". A가 표준 패턴.

### 3-5. **두 화면이 같은 키를 *읽기*만 하면 자동 동기화**

- **GameScene**: 게임 끝나면 `record(score)` → 디스크에 저장
- **ResultScene**: 받은 `bestScore`를 표시 (이미 GameScene이 저장한 값)
- **TitleScene**: `didMove`에서 `HighScoreRepository().current` 조회 → "BEST 🏆 N" 표시

세 화면이 *공유 변수*를 갖는 게 아니라, 각자 디폴츠에서 *그때그때 읽는다.* 이게 영속성의 본질 — **데이터가 코드 바깥(=디스크)에 있다.**

> Spring으로 치면 "DB가 진실의 원천(Single Source of Truth) — 컨트롤러는 매 요청마다 DB에서 읽는다"와 동일.

### 3-6. **신기록 분기 — `isNewBest`로 표시 가르기**

```swift
// ResultScene
let bestText = isNewBest ? "★ NEW BEST! ★" : "BEST 🏆 \(bestScore)"
bestLabel.text = bestText
```

같은 라벨이지만 *상황에 따라 다른 메시지*. 이건 게임 디자인의 작은 보상 시스템 — "오, 신기록이네!" 라는 즉각 피드백.

---

## 4. 무엇을 만드나?

### 새 파일 (1개)
| 파일 | 역할 |
|---|---|
| `Repositories/HighScoreRepository.swift` | UserDefaults 캡슐화. `current` 조회 + `record(_:)` 저장 |

### 고치는 파일 (3개)
| 파일 | 변경 |
|---|---|
| `Scenes/ResultScene.swift` | `newResultScene(score:bestScore:isNewBest:)`로 인자 2개 추가 + bestLabel 추가 + 분기 표시 |
| `Scenes/TitleScene.swift` | `didMove`에서 BEST 라벨 추가, `HighScoreRepository().current` 조회 |
| `GameScene.swift` | `private let highScoreRepo = HighScoreRepository()` 프로퍼티 + `endGame()`에서 `record(score)` → ResultScene init 주입 |

### Xcode pbxproj
- `HighScoreRepository.swift`를 Repositories 그룹·iOS 타겟 Sources phase에 등록 (Phase 3-1+2 패턴 그대로)

### 한 그림으로

```
[GameScene.endGame]
    score = scoreSystem.score
    isNewBest = highScoreRepo.record(score)   ── UserDefaults 디스크 기록
    bestScore = highScoreRepo.current
    presentScene(ResultScene(score, bestScore, isNewBest), fade)

[ResultScene]
    GAME OVER
    🎵 12
    ★ NEW BEST! ★    또는    BEST 🏆 20
    TAP TO RETURN

[TitleScene]
    김간호는 음악박사
    BEST 🏆 20        ← didMove에서 매번 새로 조회
    TAP TO START
```

---

## 5. 직접 확인할 것

⌘R 후:

| # | 시나리오 | 봐야 할 것 |
|---|---|---|
| (a) | 첫 실행 (UserDefaults에 키 없음) | 타이틀 BEST 🏆 0 표시. 정상 |
| (b) | 한 판 플레이 후 종료 (점수 5) | ResultScene "★ NEW BEST! ★" + 5점 표시 (첫 기록은 항상 신기록) |
| (c) | 타이틀 복귀 | "BEST 🏆 5" |
| (d) | 한 판 더 플레이, 점수 3 | ResultScene "BEST 🏆 5" (신기록 아님) + 3점 |
| (e) | 한 판 더, 점수 8 | ResultScene "★ NEW BEST! ★" + 8점 |
| (f) | 타이틀 복귀 | "BEST 🏆 8" |
| (g) | 시뮬레이터 앱 강제 종료 후 재실행 | 타이틀 "BEST 🏆 8" 유지 (영속 확인) |
| (h) | 시뮬레이터에서 앱 삭제 후 재설치 | 타이틀 "BEST 🏆 0" (디폴츠는 앱 데이터에 묶임) |

> 시뮬레이터에서 디폴츠 초기화: 앱 길게 눌러 *Remove App* → *Delete*. 또는 *Device → Erase All Content and Settings*.

---

## 6. 사용자 결정 (이미 합의)

| 결정 | 선택 | 왜 |
|---|---|---|
| 표시 위치 | **B안 — ResultScene + TitleScene 양쪽** | UserDefaults가 *여러 화면에서 같은 키 공유* 학습에 적합 |
| 저장소 | **Repository 클래스** (`Repositories/HighScoreRepository.swift`) | Spring `@Repository` 패턴 그대로 |
| 데이터 모델 | **단일 `Int`** | 가장 단순. Codable 모델은 Phase 3-5에서 통계와 함께 |
| 인계 흐름 | **GameScene이 record → ResultScene init 주입** | 단방향, 3-3 패턴 자연 확장 |
| 신기록 표시 | `★ NEW BEST! ★` vs `BEST 🏆 N` | 즉각 피드백 |

---

## 7. 회고

### 7-1. 막혔던 것

**없음.** 한 사이클(QA 1회)에 **만점 합격 (10.0/10.0)**. P0/P1/P2 모두 0건.

지난 세 sprint(3-1+2, 3-3, 본 작업)에서 *씬 init 주입 패턴*을 차근차근 닦아둔 덕에, "최고 점수"라는 새 데이터 한 가지를 더 흘려보내는 일이 자연스러운 확장으로 끝남. 도메인이 바뀌어도(영속 계층 신설) 패턴이 그대로 자라는 것을 체감.

### 7-2. 새로 배운 것

1. **`UserDefaults` — iOS의 가장 가벼운 영속** — `set/integer(forKey:)` 두 메서드가 전부. 키 없으면 0 반환을 *Apple이 보장*하므로 옵셔널 처리 불필요.
2. **Repository 패턴 = `@Repository` 멘탈 모델 그대로** — 키 문자열 캡슐화, 호출부에 영속 디테일 비노출. iOS도 Spring과 똑같이 깨끗한 분리 가능.
3. **`init(defaults: UserDefaults = .standard, key: String = ...)` 기본값 매개변수 = DI** — prod는 `HighScoreRepository()`, 테스트는 별 suite 주입. 한 줄로 의존 주입.
4. **`@discardableResult`** — 반환값을 안 받아도 컴파일 경고 안 남. 동일 메서드를 *결과 필요한 호출*과 *결과 무시 호출* 양쪽에서 쓸 수 있음.
5. **`record → current` 순서가 자기 일관성의 키** — 신기록 시 record 후 current를 읽으면 "방금 set한 새 최고치"가 반환됨. 역순이면 *이전* 최고치가 표시되어 모순. **연산 순서가 데이터 정합성을 결정**하는 사례.
6. **계산 프로퍼티(`var current: Int { ... }`)** — 매번 디스크에서 읽으니 캐싱 무효화 걱정 0. 다른 화면에서 갱신해도 자동 반영. **Spring의 "@Transactional 안에서 매 요청마다 DB read"** 와 같은 멘탈 모델.
7. **씬 init 주입의 자연 확장** — `score: Int` 1개에서 `score:bestScore:isNewBest:` 3개로. 패턴은 그대로, 인자만 늘었음. **좋은 패턴은 자라기 좋다**는 증거.
8. **단일 진실 원천(SoT)** — 키 `"highScore"`는 GameConfig에 한 줄. Repository는 init 기본값으로 받음. 이 규칙 덕에 *오타 위험 0*.

### 7-3. 다음으로 미룬 것

- **3-5**: 전적 통계 (플레이 횟수/누적 점수). `HighScoreRepository` → `StatisticsRepository`로 확장하거나 별도 Codable 모델 도입.
- **Phase 4**: 추가 NPC와 깜짝 이벤트 (석조무사·이교수·박병장 비행기).

### 7-4. 평가 점수

- **가중평균: 10.0 / 10 — 만점 합격** 🎉
- 항목별: Swift 패턴 10 / 게임 로직 10 / 성능·안정성 10 / 기능 완성도 10
- P0 치명 0건, P1 중요 0건, P2 권장 0건
- 빌드: BUILD SUCCEEDED, 경고 0건 (iPhone 17 Simulator)

### 7-5. 코드 라인 변화

| 파일 | 변화 |
|---|---|
| `Repositories/HighScoreRepository.swift` (신설) | 0 → 40줄 |
| `Scenes/ResultScene.swift` | 약 +10줄 (bestLabel + 분기) |
| `Scenes/TitleScene.swift` | 약 +5줄 (bestLabel) |
| `GameScene.swift` | +2 ~ +4줄 (highScoreRepo + endGame 4줄 교체) |
| `Config/GameConfig.swift` | +5상수 + 5상수 값 재조정 |

**핵심 가치**: 이 게임이 처음으로 *외부(=디스크)에 데이터를 남긴다*. 다음 sprint(3-5 통계)에서 **같은 Repository 패턴을 그대로 확장**하여 누적 점수·플레이 횟수도 똑같이 흐를 수 있는 토대 완성.

---

## 8. 다음 작업

```
[1] 시뮬레이터에서 §5 (a)~(g) 확인 (h는 선택)
[2] 다음 sprint: Phase 3-5 (Codable 통계) 또는 Phase 4 진입
```

> **이번 sprint 본질**: *영속성의 첫 등장*. 게임이 더 이상 "켤 때마다 처음"이 아니다. 그리고 **Repository 패턴**으로 영속 책임을 캡슐화 — Spring `@Repository`와 같은 방식으로 iOS에서도 깨끗하게 분리된다.
