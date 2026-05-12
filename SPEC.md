# Phase 5-7 — ResultScene에 사용한 캐릭터 이름 표시 (Phase 5 종결)

## 개요
Phase 5-4에서 HUDNode에 캐릭터 이름이 들어갔지만, 게임 종료 후 ResultScene에는 어떤 캐릭터로 플레이했는지 표시되지 않아 "한 판 흐름의 일관성 구멍"이 있다. Phase 5-7은 ResultScene에 캐릭터 이름 라벨 1개를 추가하여 "🎮 정간호 / GAME OVER / 🎵 30" 같은 마무리 표시를 만든다. 이로써 Phase 5의 5명 캐릭터 흐름이 타이틀 선택 → HUD 표시 → 결과 표시까지 완결된다.

## 변경 유형
**비주얼 + 데이터 전달 확장 (Phase 5 종결 마무리)** — 라벨 1개 추가(비주얼) + ResultScene의 init/factory에 `characterName: String` 인자 확장(데이터 전달). 게임플레이 로직(점수/속도/충돌)은 0줄 변경.

## 게임 경험 의도
1. 게임 종료 직후 "내가 어떤 캐릭터로 30점을 냈는지" 한눈에 보인다 — 캐릭터별 플레이 기억이 점수와 결합되어 다음 판 캐릭터 선택을 자연스럽게 유도.
2. 타이틀 카드 선택 → HUD 우상단 이름 → 결과 화면 이름까지 *3개 지점*에서 동일 캐릭터 이름이 노출.
3. Phase 5의 마무리 — 5-1(UI) → 5-2(주입) → 5-3(속도) → 5-4(HUD) → 5-5(scale) → 5-6(저장) → **5-7(결과 표시)** 종결.

## Sprint 범위 계약

### 허용
- `ResultScene.swift`의 init/factory 시그니처 확장 + 라벨 1개 추가 + setup/layout 갱신
- `GameConfig.swift`에 라벨 폰트/오프셋 상수 2개 추가
- `GameScene.swift`의 `endGame()` 안 `ResultScene.newResultScene(...)` 호출에 `characterName:` 인자 1줄 추가

### 금지 (위반 시 P0)
- `CharacterID.swift` 변경
- `HUDNode.swift` / `PlayerNode.swift` / `CharacterCardNode.swift` 변경
- `TitleScene.swift` 변경
- `GameScene.swift`의 endGame 외 다른 메서드/프로퍼티 변경 (init / factory / didMove / update / configureContactRouter / triggerAirforceEasterEgg / layout* / characterID 프로퍼티) 0줄
- `GameScene+Setup.swift` 변경
- `ColorTokens.swift` 변경
- 시스템(`ContactRouter`/`SpawnSystem`/`ScoreSystem`) 변경
- Repository (`HighScore`/`Statistics`/`CharacterPreference`) 변경
- `Models/GameStats.swift` 변경
- `Protocols/` 변경
- 라벨 색 차등 (캐릭터별 색 적용 금지 — 일관 색 .ganhoPaper)
- 폰트 굵기 / outline / shadow 시각 강화
- `characterID` 자체를 ResultScene에 주입 (String만 — HUDNode 5-4 패턴과 일관)
- 새 노드(border, decoration) 추가
- 영구 저장 / Repository 신설
- macOS / tvOS / pbxproj / Test 코드
- 5라벨 균등 40 간격 변경

### 판단 기준
"이 변경이 없으면 'ResultScene에 사용한 캐릭터 이름이 게임 종료 후 표시됨'이 동작하는가?" → NO만 In Scope.

## 4 핵심 결정 포인트

### 1. 라벨 위치 — title(+80) 위쪽 +115

기존 5라벨 y-offset (frame.midY 기준):

| 라벨 | offsetY 상수 | 값 |
|---|---|---|
| titleLabel ("GAME OVER") | resultTitleOffsetY | **+80** |
| scoreLabel ("🎵 N") | resultScoreOffsetY | **+40** |
| bestLabel ("BEST 🏆 N") | resultBestOffsetY | **0** |
| statsLabel ("PLAYS / TOTAL") | resultStatsOffsetY | **-40** |
| promptLabel ("TAP TO RETURN") | resultPromptOffsetY | **-80** |

균등 40pt 간격 — 사이에 끼우면 기존 간격 깨짐.

**결정**: title(+80) *위쪽* +115에 배치. "🎮 정간호 / GAME OVER / 🎵 N / BEST / PLAYS / TAP" 위→아래 흐름.

- `resultCharacterOffsetY: CGFloat = 115`
- title(+80)과 +35pt 떨어짐, 폰트(22, 32) 절반의 합 27pt → 8pt 시각적 갭, 겹침 없음
- 1024×768에서 상단 = 384 + 115 + 11 = 510pt → 화면 상단(768)까지 258pt 여유

### 2. 라벨 텍스트 포맷 — `"🎮 \(characterName)"`
- HUDNode 톤("🎵 0", "⏱ 00:45", "🔥 0")과 결을 맞춤
- 게임패드 이모지(🎮) = "이 캐릭터로 플레이함"의 직관적 의미

### 3. 폰트 크기 — `resultCharacterFontSize: CGFloat = 22`
- 기존 폰트: title 32 / score 24 / best 22 / stats 16 / prompt 16
- 22pt(best 동급): 강조 정보지만 score보다 보조적. title보다 위에 있지만 폰트는 작아 시선이 GAME OVER로 자연 유도.

### 4. Graceful — 빈 문자열 처리
- 본 sprint에선 endGame이 항상 non-empty(`characterID.displayName`) 전달이라 실제 미발생
- 강제 `characterName: ""` 시 → 라벨 text = "🎮 " (이모지만), 크래시 없음. HUDNode 5-4와 동형 graceful

## 변경 범위

### 수정할 파일
- `GanhoMusic/GanhoMusic Shared/Scenes/ResultScene.swift` — 라벨 1개 + init/factory 6-인자 확장
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift` — 상수 2개 추가
- `GanhoMusic/GanhoMusic Shared/GameScene.swift` — endGame 내 1줄

### 추가할 파일
없음.

## 기능 상세

### 기능 1: ResultScene 라벨 + 6-인자 init 확장

**핵심 코드 구조**:

```swift
// MARK: - Properties
private let characterName: String       // 5-7: init 주입된 캐릭터 한국어 이름. 불변.
private let titleLabel  = SKLabelNode(text: "GAME OVER")
// ... 기존 라벨 4개 그대로 ...
private let characterLabel = SKLabelNode(text: "")   // 5-7: title 위에 표시될 캐릭터 라벨
private let promptLabel = SKLabelNode(text: "TAP TO RETURN")

// MARK: - Factory
class func newResultScene(
    score: Int,
    bestScore: Int,
    isNewBest: Bool,
    stats: GameStats,
    characterName: String     // 5-7 신규 인자
) -> ResultScene {
    let scene = ResultScene(
        size: CGSize(width: 1024, height: 768),
        score: score,
        bestScore: bestScore,
        isNewBest: isNewBest,
        stats: stats,
        characterName: characterName
    )
    scene.scaleMode = .resizeFill
    return scene
}

// MARK: - Init
private init(
    size: CGSize,
    score: Int,
    bestScore: Int,
    isNewBest: Bool,
    stats: GameStats,
    characterName: String     // 5-7 신규 인자, super.init 전에 저장
) {
    self.finalScore = score
    self.bestScore = bestScore
    self.isNewBest = isNewBest
    self.stats = stats
    self.characterName = characterName
    super.init(size: size)
}

// MARK: - Setup
private func setupLabels() {
    configureLabel(titleLabel,     fontSize: GameConfig.resultTitleFontSize)
    configureLabel(scoreLabel,     fontSize: GameConfig.resultScoreFontSize)
    configureLabel(bestLabel,      fontSize: GameConfig.resultBestFontSize)
    configureLabel(statsLabel,     fontSize: GameConfig.resultStatsFontSize)
    configureLabel(characterLabel, fontSize: GameConfig.resultCharacterFontSize)   // 5-7
    configureLabel(promptLabel,    fontSize: GameConfig.resultPromptFontSize)

    scoreLabel.text = "🎵 \(finalScore)"
    bestLabel.text  = isNewBest ? "★ NEW BEST! ★" : "BEST 🏆 \(bestScore)"
    statsLabel.text = "PLAYS \(stats.playCount)  /  TOTAL \(stats.totalScore)"
    characterLabel.text = "🎮 \(characterName)"   // 5-7

    addChild(titleLabel)
    addChild(scoreLabel)
    addChild(bestLabel)
    addChild(statsLabel)
    addChild(characterLabel)   // 5-7
    addChild(promptLabel)
    layoutLabels()
}

// MARK: - Layout
private func layoutLabels() {
    titleLabel.position     = CGPoint(x: frame.midX, y: frame.midY + GameConfig.resultTitleOffsetY)
    scoreLabel.position     = CGPoint(x: frame.midX, y: frame.midY + GameConfig.resultScoreOffsetY)
    bestLabel.position      = CGPoint(x: frame.midX, y: frame.midY + GameConfig.resultBestOffsetY)
    statsLabel.position     = CGPoint(x: frame.midX, y: frame.midY + GameConfig.resultStatsOffsetY)
    characterLabel.position = CGPoint(x: frame.midX, y: frame.midY + GameConfig.resultCharacterOffsetY)   // 5-7
    promptLabel.position    = CGPoint(x: frame.midX, y: frame.midY + GameConfig.resultPromptOffsetY)
}
```

**주의**: `configureLabel`이 5라벨 공통 스타일(`.ganhoPaper`, `hudAlpha`, .center/.center)을 모두 적용 — characterLabel도 동일 색·동일 정렬. **캐릭터별 색 차등 금지**(Out of Scope).

### 기능 2: GameConfig 상수 2개 추가

**위치**: `Config/GameConfig.swift` — 기존 result* 상수 그룹 뒤 또는 Character Preference 다음에 신설 섹션.

**핵심 코드 구조**:

```swift
// MARK: - Result Character (Phase 5-7)
/// Phase 5-7 — ResultScene 캐릭터 이름 라벨 폰트 크기 (pt). best(22)와 동급.
/// title(32) > character(22) = best(22) > score(24)... 위계 — title 강조 유지.
static let resultCharacterFontSize: CGFloat = 22
/// Phase 5-7 — ResultScene 캐릭터 라벨 y 오프셋. title(+80) 위쪽에 배치.
/// 5라벨 균등 40 간격(+80/+40/0/-40/-80) 깨지 않게 *위로* 35pt 추가.
/// "정간호 / GAME OVER / 🎵 N / BEST / PLAYS / TAP" 위→아래 흐름.
static let resultCharacterOffsetY: CGFloat = 115
```

### 기능 3: GameScene.endGame()에 1줄 인자 추가

**핵심 코드 구조**:

```swift
private func endGame() {
    // ... 기존 로직 동일 ...
    let resultScene = ResultScene.newResultScene(
        score: score,
        bestScore: bestScore,
        isNewBest: isNewBest,
        stats: stats,
        characterName: characterID.displayName   // 5-7 — String만 주입 (HUDNode setCharacterName과 동형)
    )
    view.presentScene(resultScene, transition: .fade(withDuration: GameConfig.sceneTransitionDuration))
}
```

**금지(0줄)**: `init`, `class func newGameScene`, `didMove`, `update`, `configureContactRouter`, `triggerAirforceEasterEgg`, `layout*`, `characterID` 프로퍼티 선언. endGame 내에서도 위 1줄 외 0줄.

## 검증 시나리오 (a)~(h)

### (a) 5 캐릭터 전체 표시 정확성
- TitleScene 5장 각각 선택 → 게임 시작 → ResultScene 진입
- 5번 모두: kim→"🎮 김간호" / jung→"🎮 정간호" / geon→"🎮 건간호" / im→"🎮 임간호" / lee→"🎮 이간호"

### (b) 빌드 클린
- Xcode 빌드 0 error, 0 warning(신규)
- ResultScene 시그니처 변경 → GameScene.swift 호출부 1곳 갱신 필수, 누락 시 즉시 컴파일 에러

### (c) 5-2 회귀 (constructor injection)
- `GameScene.init(size:characterID:)` 0줄 변경 → TitleScene.didMove 무영향

### (d) 5-3 회귀 (캐릭터별 속도)
- PlayerNode.update의 speedMultiplier 0줄 변경 → 5캐릭터 속도 정상

### (e) 5-4 회귀 (HUD 캐릭터 이름)
- HUDNode `setCharacterName` 호출/시그니처 0줄 → 게임 중 HUD 우상단 이름 정상

### (f) 라벨 위치 겹침 / 화면 클리핑
- 1024×768: character(+115) 폰트 22 → 상단 510pt (화면 상단 768까지 258pt 여유)
- character(+115)와 title(+80) 사이 35pt → 폰트 절반 합 27pt → 8pt 시각적 갭

### (g) Graceful — characterName 빈 문자열
- 강제 `""` 주입 시 → text = "🎮 ", 크래시 없음

### (h) didChangeSize 회전/리사이즈
- `layoutLabels()` 호출 → 6라벨 동시 재배치 정상

## 학습 가치 — Phase 5 종결을 통한 패턴 내면화

1. **Constructor injection 두 번째 확장**:
   - 5-2: GameScene 첫 init 주입 (`init(size:characterID:)`)
   - 5-7: ResultScene 같은 패턴으로 6번째 인자 추가
   - Spring 비유: 5-2가 `GameService(playerColor)` 단일 의존성 주입이라면, 5-7은 `ResultDTO(...)` 데이터 컨테이너 확장 패턴

2. **String-only 동형성 (5-4와 일관)**:
   - HUDNode가 `setCharacterName(_ name: String)`으로 enum이 아닌 String만 받았던 결정을 ResultScene도 답습
   - **이유**: 자식 노드/씬이 CharacterID enum에 의존하면, 미래에 캐릭터 시스템을 리팩터할 때 모든 자식이 영향받음. 최소 정보(이름 String)만 흘려 결합도 차단

3. **6-인자 init의 가독성**:
   - 6인자는 일반적으로 "리팩터 신호"지만, ResultScene은 순수 데이터 표시 컨테이너 — 인자 = 라벨 1:1 대응으로 의미 모호성 0
   - 다음 단계에서 8개 넘으면 `ResultData` struct로 묶을 신호

4. **Phase 5 7-step 회고**:
   - 5-1(UI) → 5-2(주입) → 5-3(속도) → 5-4(HUD) → 5-5(scale) → 5-6(저장) → **5-7(결과)**. 캐릭터 분기의 한 판 흐름이 완결.

## 주의사항

- **endGame 외 0줄**: characterID 프로퍼티 추가 등 5-2가 한 작업을 또 건드리지 않는다. 인자 1줄만.
- **라벨 색 차등 금지**: `configureLabel`로 자동 `.ganhoPaper` 적용 — 동일 색. characterID.color를 ResultScene이 알면 안 됨.
- **빌드 에러 가능성**: ResultScene 시그니처 변경 → GameScene.swift endGame 호출부 *반드시* 같은 sprint에서 갱신.
- **5라벨 균등 40 간격 유지**: title(+80)과 character(+115) 사이는 의도적으로 35로 좁힌 것. 다른 라벨 간격은 절대 변경 금지.
