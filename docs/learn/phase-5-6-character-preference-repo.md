# Phase 5-6 — 내가 고른 캐릭터를 앱이 기억하기

## 이번에 만든 것

지금까지는 앱을 끄고 다시 켜면 **항상 김간호로 되돌아왔어요**. 김 말고 정간호를 좋아하는 사람도 매번 카드를 다시 눌러야 했죠. 매번 같은 동작을 반복해야 하면 짜증나잖아요.

이제는 **마지막에 고른 캐릭터가 자동으로 기억돼요**. 한 번 정간호를 고르고 앱을 꺼도, 다음에 켰을 때 정간호가 이미 선택돼 있어요.

```
[전]
앱 켜기 → 김간호 ✓ (기본)
정간호 누르기
앱 끄고 다시 켜기 → 김간호 ✓ (?! 내가 고른 건 정간호인데...)

[후]
앱 켜기 → 김간호 ✓ (첫 실행만 기본)
정간호 누르기 → 디스크에 저장 💾
앱 끄고 다시 켜기 → 정간호 ✓ (앱이 기억해줌)
```

이걸 위해 새로운 **저장소(Repository)** 클래스를 하나 만들었어요. 이름은 `CharacterPreferenceRepository`. "캐릭터 선호도 저장소"라는 뜻이에요.

---

## 핵심 5가지 (Spring 비유)

### 1. `@Repository`가 세 번째로 또 등장

이 프로젝트에는 이미 두 개의 Repository가 있었어요.

| Phase | Repository | 저장하는 것 |
|---|---|---|
| 3-4 | `HighScoreRepository` | 최고 점수 (숫자 하나) |
| 3-5 | `StatisticsRepository` | 누적 플레이 통계 (객체) |
| **5-6** | **`CharacterPreferenceRepository`** | **선택한 캐릭터 (enum 하나)** |

세 클래스 모두 **똑같은 구조**예요.

```java
// Spring 비유
@Repository
class XxxRepository {
    @Value("${storage.key:default}")
    private String key;

    public final XxxRepository(UserDefaults defaults, String key) { ... }
    public Xxx getCurrent() { ... }     // 읽기
    public void save(Xxx value) { ... } // 쓰기
}
```

이게 바로 **Repository 패턴**의 힘이에요. 한 번 패턴을 익히면, 새로운 데이터를 저장하고 싶을 때 **그대로 복붙해서 타입만 바꾸면** 돼요. 세 번째 만들 때는 *생각할 게 거의 없어요*.

### 2. `@Value("${key:default}")`의 default 부분 = `?? .kim`

저장된 게 없을 때 어떻게 할 건가요? Spring에서는 이렇게 써요.

```java
@Value("${selected.character:kim}")
private String selectedCharacter;
// → 프로퍼티 파일에 없으면 "kim"을 기본값으로
```

Swift에서는 `??` 연산자가 똑같은 일을 해요.

```swift
var current: CharacterID {
    guard let raw = defaults.string(forKey: key) else { return .kim }
    return CharacterID(rawValue: raw) ?? .kim
}
```

여기서 `?? .kim`은 **"앞이 nil이면 .kim 써라"**라는 뜻이에요. 두 가지 상황을 모두 다뤄요.

- `defaults.string(forKey:)`이 `nil` → 키가 아예 없음 (첫 실행)
- `CharacterID(rawValue: raw)`가 `nil` → 키는 있는데 값이 망가짐 (예: 누가 "ganho"라는 이상한 값을 넣음)

**graceful degradation** — 망가져도 크래시 안 나고 김간호로 살아남기.

### 3. `@Transactional` 단위 = `select(_:)` 함수 1개

`select(_:)` 함수는 **카드 선택을 바꾸는 유일한 통로**예요. 카드를 탭하든, 어디서 호출되든, 모든 선택 변경은 이 함수를 거쳐요.

```swift
private func select(_ id: CharacterID) {
    selectedCharacterID = id          // 1) 메모리 업데이트
    preferenceRepo.save(id)           // 2) 디스크 저장 ← Phase 5-6 신규
    for card in characterCards {      // 3) UI 갱신
        card.setSelected(card.id == id)
    }
}
```

Spring의 `@Transactional` 메서드와 같아요. **세 가지가 한 묶음으로 일어나야 안전해요.**

```java
// Spring 비유
@Transactional
public void select(CharacterID id) {
    this.selected = id;        // 메모리
    repository.save(id);       // 디스크
    notifyCards(id);           // UI
}
```

만약 디스크 저장만 따로, UI 갱신만 따로 하려고 했다면, 누군가 한 단계를 빼먹는 순간 **상태가 어긋나서** 메모리에는 정간호인데 화면에는 김간호가 선택된 채로 보일 수도 있어요. **단일 진입점**을 두면 그런 사고가 원천 차단돼요.

### 4. enum의 rawValue ↔ Spring `@Enumerated(EnumType.STRING)`

`CharacterID`는 enum이에요.

```swift
enum CharacterID: String, CaseIterable {
    case kim, jung, geon, im, lee
}
```

`: String`이라고 써놓으면 **각 case가 String 이름과 자동으로 짝이 맞춰져요**.
- `.kim` ↔ `"kim"`
- `.jung` ↔ `"jung"`

이게 바로 Spring JPA에서 `@Enumerated(EnumType.STRING)`로 enum을 DB에 String으로 저장하는 거랑 똑같아요.

```java
// Spring JPA 비유
@Enumerated(EnumType.STRING)
private CharacterID id;
// → DB에 "kim", "jung" 같은 String으로 저장
```

저장할 때: `id.rawValue` → `"jung"` (String)
읽을 때: `CharacterID(rawValue: "jung")` → `.jung`

**enum과 String의 자동 변환** — 이건 SwiftPL의 매우 좋은 기능이에요.

### 5. 직렬화 전략 비교 (3 Repository가 어떻게 다른가)

세 Repository는 똑같은 *구조*지만, **저장하는 방식은 데이터 형태에 맞게 달라요**.

| Repository | 데이터 타입 | 어떻게 저장하나 | 망가졌을 때 |
|---|---|---|---|
| HighScore | `Int` (숫자 하나) | `defaults.integer(forKey:)` 한 줄 | 0 (Apple 보장) |
| Statistics | `struct: Codable` (여러 필드) | JSON Data로 인코딩 | `GameStats()` 기본값 |
| **CharacterPreference** | **`enum: String`** | **rawValue String 한 줄** | **`.kim` 폴백** |

**원칙**: *데이터 형태에 가장 단순한 직렬화를 골라라*. 숫자 하나면 UserDefaults가 직접 지원하니 그걸 쓰고, 복잡한 객체면 JSON, enum이면 rawValue. **억지로 JSON으로 통일할 필요 없음**. 단순한 게 좋은 거예요.

```swift
// 저장 (1줄)
defaults.set(id.rawValue, forKey: key)

// 읽기 (3줄)
guard let raw = defaults.string(forKey: key) else { return .kim }
return CharacterID(rawValue: raw) ?? .kim
```

JSON 인코딩/디코딩 코드가 한 줄도 없어요. 이게 enum + rawValue의 진가예요.

---

## 한 줄 요약

이번 작업은 **이미 두 번 만들어본 패턴(Repository)을 세 번째 그대로 적용한 sprint**예요. 새 타입(enum CharacterID)에 맞게 직렬화 방법(rawValue String)만 살짝 다르게 했을 뿐, 큰 그림은 그대로. 그리고 **단일 진입점(`select(_:)`)에 저장 호출을 묶어두면** 상태가 어긋날 일이 사라져요. 사용자가 보기엔 그저 *"한 번 고른 캐릭터를 앱이 기억해준다"*는 작은 친절함이지만, 그 뒤에는 영속 계층의 명료한 책임 분리가 있어요.
