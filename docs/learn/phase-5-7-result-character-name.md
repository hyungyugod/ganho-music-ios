# Phase 5-7 — 결과 화면에 어떤 캐릭터로 놀았는지 표시하기

## 한 줄로 말하면

게임이 끝나고 나오는 결과 화면 위쪽에 "🎮 정간호" 같은 한 줄을 새로 띄워서, 방금 누구로 30점을 냈는지 알려준다.

## 왜 만드는 거야?

지금까지 Phase 5에서 5단계를 거쳤어:

1. **5-1**: 타이틀에 5명 카드 보여주기
2. **5-2**: 고른 캐릭터로 게임 시작 (색 다름)
3. **5-3**: 캐릭터마다 속도 다름
4. **5-4**: 게임 중 화면 위에 이름 보여주기
5. **5-5**: 고른 카드 약간 커지기
6. **5-6**: 마지막에 고른 캐릭터 기억하기

근데 **결과 화면**(GAME OVER 화면)에서는 누구로 했는지 표시가 없었어. 그래서 "내가 김간호로 했는데 30점이었나? 정간호로 했나?" 헷갈리는 구멍이 있었어.

이번 5-7이 그 구멍을 메꿔서 **Phase 5를 완전히 끝낸다**.

## 뭘 바꿨어?

### 파일 3개만 손댐

1. **`ResultScene.swift`** (결과 화면 코드)
   - 헤더 주석에 한 줄 추가
   - `characterName: String` 변수 1개 추가
   - 라벨(글자 표시) 1개 추가: `characterLabel`
   - `newResultScene(...)` 함수에 6번째 인자 추가
   - `init(...)` 함수에 6번째 인자 추가
   - `setupLabels()`에서 라벨 꾸미고 글자 넣고 화면에 붙이기
   - `layoutLabels()`에서 라벨 위치 정하기

2. **`GameConfig.swift`** (게임 상수 모음)
   - 새 섹션 `// MARK: - Result Character (Phase 5-7)`
   - 폰트 크기: 22pt
   - 위치 오프셋: +115 (화면 가운데보다 115pt 위쪽)

3. **`GameScene.swift`** (게임 본체)
   - `endGame()` 안에서 결과 화면 만드는 줄에 인자 1개 추가
   - **딱 그 1줄만** — 다른 부분 안 건드림

## 핵심 개념 — Spring 비유

### 1. DTO 인자 확장 (Constructor 늘리기)

Spring 백엔드에서 이런 DTO 본 적 있지?

```java
// 처음에는
public ResultDTO(int score, int bestScore, boolean isNewBest, GameStats stats) { ... }

// 정보가 더 필요해지면 인자 1개 추가
public ResultDTO(int score, int bestScore, boolean isNewBest, GameStats stats, String characterName) { ... }
```

이번에 한 게 **딱 이거**야. Swift `init`도 똑같이 인자 1개 늘렸어:

```swift
// Before
private init(size: CGSize, score: Int, bestScore: Int, isNewBest: Bool, stats: GameStats)

// After
private init(size: CGSize, score: Int, bestScore: Int, isNewBest: Bool, stats: GameStats, characterName: String)
```

그리고 **호출하는 쪽**(GameScene.endGame)도 같은 sprint에서 같이 고쳐야 컴파일이 됨. Spring에서 `new ResultDTO(...)` 호출부 찾아서 바꾸는 거랑 똑같아.

### 2. String만 받기 (동형성)

여기 중요한 결정 하나 있어:

> "`CharacterID` enum을 통째로 넘길까, 아니면 `String`만 넘길까?"

**String만 넘기기로 정했어**. 왜?

Spring 비유로:
- `OrderEntity` 통째로 넘기면 → 화면이 Order의 모든 필드를 알게 됨. Order에 컬럼 추가하면 화면도 영향받음.
- `String orderNumber`만 넘기면 → 화면은 주문번호만 알면 됨. Order가 어떻게 바뀌든 무관.

결과 화면(ResultScene)은 "캐릭터 이름 문자열"만 알면 충분해. CharacterID enum 안에 색·속도·표시이름이 다 들어있는데, 결과 화면은 이름만 필요하니까 **이름만 떼서 String으로 줘**. 그러면 나중에 CharacterID에 스킬이나 다른 정보 추가해도 ResultScene은 안 건드려도 됨.

**Phase 5-4 (HUD에 이름 표시)**도 똑같이 String만 받았어. 그래서 "**5-4와 동형성**"이라고 했어 — 같은 패턴 반복.

### 3. configureLabel — 공통 스타일 함수

ResultScene에는 라벨이 6개 있어 (title, score, best, stats, character, prompt). 6개 다 같은 색·정렬·투명도를 써야 하잖아?

Spring의 `@Component` 공통 빈처럼, Swift에서는 그냥 **함수 하나로 묶어**:

```swift
private func configureLabel(_ label: SKLabelNode, fontSize: CGFloat) {
    label.fontSize = fontSize
    label.fontColor = .ganhoPaper       // 모든 라벨 같은 색
    label.horizontalAlignmentMode = .center
    label.verticalAlignmentMode = .center
    label.alpha = GameConfig.hudAlpha   // 모든 라벨 같은 투명도
}
```

새 라벨(characterLabel) 만들고 이 함수 호출 한 줄만 추가하면, 자동으로 같은 스타일이 적용돼. **"캐릭터별로 색 다르게 하지 마"** 규칙이 여기서 자연스럽게 지켜져 — 색을 직접 안 만지고 공통 함수만 부르니까.

### 4. 매직 넘버 금지

폰트 크기 22, 위치 +115를 **코드에 직접 안 적었어**. 대신 `GameConfig`에 상수로 정의:

```swift
static let resultCharacterFontSize: CGFloat = 22
static let resultCharacterOffsetY: CGFloat = 115
```

Spring에서 `application.yml`에 `result.character.font-size: 22` 두는 거랑 똑같아. 나중에 디자이너가 "22 말고 24로 키워봐" 그러면 `GameConfig.swift` 한 줄만 고치면 됨.

## 검증해본 것

### (a) 5명 다 잘 나오나
- 김간호 → "🎮 김간호"
- 정간호 → "🎮 정간호"
- 건간호 → "🎮 건간호"
- 임간호 → "🎮 임간호"
- 이간호 → "🎮 이간호"

### (b) 빌드
- BUILD SUCCEEDED
- 경고/에러 0줄 (AppIntents 잡음 제외)

### (g) Graceful — 빈 문자열
- 만약 `""` 넘기면? → "🎮 " (이모지만 보임). 크래시 안 남.

## Phase 5 종결

| Phase | 핵심 |
|---|---|
| 5-1 | 타이틀 UI |
| 5-2 | 캐릭터 색 적용 |
| 5-3 | 캐릭터 속도 |
| 5-4 | HUD 이름 |
| 5-5 | 카드 확대 |
| 5-6 | 선택 저장 |
| **5-7** | **결과 화면 이름** ← 지금 여기 |

이걸로 캐릭터 선택의 한 판 흐름이 **타이틀 → 게임 중 → 결과**까지 3지점에서 일관되게 표시돼. Phase 5 끝.

## 한 줄 정리

> **인자 1개, 라벨 1개, 상수 2개, 호출부 1줄.** 이게 끝.
> 진짜 핵심은 "정보 흘리는 통로(constructor injection)에 String만 흘려서 결합도를 막는다"는 패턴이야.
