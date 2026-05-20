# Sprint 7 Phase D — 결과창 정리 + 하이스코어 화면 신설

## 개요
ResultScene 시각 정보 5요소(♪·점수·SCORE 라벨·BEST 칩·캐릭터/난이도)가 같은 좌표 근처에 몰려 시각 우선순위가 모호한 상태를 해소한다. 점수가 시각 주인공이 되도록 ♪를 24pt로 줄여 점수 좌측에 부속시키고, SCORE 라벨을 점수 아래로, BEST를 점수 우측 GlassPill로 분리하며, 캐릭터·난이도 헤더 칩을 타이틀 위로 끌어올린다. "📊 기록 보기" GlassPill 신규 추가 → 1탭 ScoreboardScene 진입.

ScoreboardScene은 5(캐릭터)×3(난이도) = 15셀 매트릭스를 `PerDifficultyScoreRepository` 기반으로 그리고, 직전 게임 셀에 ★ 마커 부착. 좌상단 "← 결과로" GlassPill 탭 시 ResultScene 새 인스턴스 fade 복귀(졸업장 재표시 차단).

## 변경 유형
**비주얼 + 신규 씬** (저장·갱신 0, 읽기 전용)

## 게임 경험 의도
- 결과 화면에서 점수가 시각 주인공이 되어 0.3초 안에 "내가 몇 점 받았는가" 인지
- "내 다른 캐릭터·난이도 기록은?" 호기심을 한 번의 탭으로 해소
- 매트릭스에서 직전 게임이 갱신한 셀에 ★이 박혀 진척 시각 보상

## Sprint 7 Phase D 범위 계약

### 허용
1. ResultScene 내부 레이아웃·라벨 텍스트 재배치 (GameConfig V3 상수 신규 추가만)
2. ResultScene에 "기록 보기" GlassPill 신규 자식 1개 + touchesBegan 분기
3. 신규 파일 `Scenes/ScoreboardScene.swift` 작성
4. `CharacterFaceNode`에 mini 32pt 팩토리 1개 추가
5. `GameConfig` Phase D V3 상수 신규 추가
6. 신규 mockup 2개: `result-screen-v3.html`, `highscore-board-v1.html`

### 금지 (0줄 변경)
1. `ResultScene.newResultScene(...)` 9개 인자 시그니처
2. `ResultScene.init(...)` 시그니처
3. ResultScene → StartScene 1탭 전이 정책 (탭 분기만 추가 — Scoreboard 탭은 ScoreboardScene으로, 그 외는 그대로 StartScene)
4. HighScoreRepository / StatisticsRepository / PerDifficultyScoreRepository / GraduationRepository 모든 저장·갱신 로직 (읽기 전용)
5. 졸업장 분기 `DiplomaOverlayNode` 시각·텍스트·자가 소멸 패턴
6. 신기록 분기 sparkle 5발 / heavy 햅틱 / NewMail 사운드 발화 조건
7. Phase A·B·C 결과물 0줄
8. GameScene / GameState / PhysicsCategory / Managers / Systems 0줄
9. 게임 로직 일체

## 변경 범위

### 수정 파일

| 파일 | 변경 |
|---|---|
| `Scenes/ResultScene.swift` | 레이아웃 재배치(♪ 24pt 좌측, SCORE 아래, BEST 우측 GlassPill, headerChip 타이틀 위) + "📊 기록 보기" GlassPill 신규 자식 + touchesBegan 탭 분기 |
| `Nodes/CharacterFaceNode.swift` | `static func mini(id: CharacterID) -> CharacterFaceNode` 팩토리 추가 (setScale 0.47) |
| `Config/GameConfig.swift` | Phase D V3 상수 ~40개 신규 추가 |

### 추가 파일

| 파일 | 역할 |
|---|---|
| `Scenes/ScoreboardScene.swift` | 신규 씬 — 15셀 매트릭스 + 미니 얼굴 + ★ + 하단 stat + 백 버튼. ~340 LOC |
| `mockups/result-screen-v3.html` | v2 카피 + §5.2 표 매칭 |
| `mockups/highscore-board-v1.html` | 신규 매트릭스 시각 사양 |

## 기능 상세

### 기능 1: ResultScene 결과창 레이아웃 재배치

**Before → After 좌표 변경표 (midY 기준)**

| 노드 | Before | After |
|---|---|---|
| `headerChip` | +100 | **+115** |
| `titleLabel` "실습 종료" | +70 | **+85** |
| `subtitleLabel` | +44 | **+58** |
| `accentLine` | +130 | **+148** |
| `scoreLabel` "♪ N" | -2 | **-2** (텍스트 ♪ 제거 → "\(finalScore)"만) |
| **신규 `scoreNoteIconLabel` "♪"** | — | **scoreLabel.x - 60, y -2** Jua 24pt |
| `scoreSubLabel` SCORE | -32 | **-44** |
| `bestLabel` → **신규 `bestPill`** | -60 중앙 | **scoreLabel.x + 120, y -2** GlassPill "🏆 BEST N" / "★ NEW BEST!" |
| `divider` | -90 | **-78** |
| `playsValueLabel` / `playsTitleLabel` | -110 / -124 | **-98 / -112** |
| `restartButton` / `shareButton` | bottom 56 | 그대로 |
| **신규 `scoreboardButton`** | — | **shareButton.x - 110, y = buttonY** GlassPill "📊 기록 보기" 110×36 |

**신규 프로퍼티 3종**
```swift
/// Sprint 7 Phase D — scoreLabel("0") 좌측 작은 ♪ 아이콘. scoreLabel에서 ♪ 분리.
private let scoreNoteIconLabel = SKLabelNode(text: "♪")
/// Sprint 7 Phase D — "📊 기록 보기" GlassPill. 탭 → ScoreboardScene 전이.
private var scoreboardButton: GlassPillNode?
/// Sprint 7 Phase D — bestLabel 시각 대체 GlassPill (bestLabel.alpha = 0 차단).
private var bestPill: GlassPillNode?
```

**touchesBegan 분기 추가**
```swift
override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard !isTransitioning else { return }
    if children.contains(where: { $0.name == "diplomaOverlay" }) { return }
    guard let view = self.view, let touch = touches.first else { return }
    let location = touch.location(in: self)

    // Sprint 7 Phase D — 기록 보기 칩 분기
    if let pill = scoreboardButton, pill.contains(location) {
        isTransitioning = true
        let lastUpdatedKey: (CharacterID, Difficulty)? = {
            guard isNewBest, let charID = inferredCharacterID else { return nil }
            return (charID, difficulty)
        }()
        let ctx = ResultReturnContext(
            finalScore: finalScore, bestScore: bestScore, isNewBest: isNewBest,
            stats: stats, characterName: characterName, difficulty: difficulty,
            isNewGraduation: isNewGraduation, graduatedAt: graduatedAt
        )
        let scoreboard = ScoreboardScene.newScoreboardScene(
            lastUpdatedKey: lastUpdatedKey, returnContext: ctx
        )
        let transition = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
        view.presentScene(scoreboard, transition: transition)
        return
    }

    // 기존 — StartScene 전이
    isTransitioning = true
    let startScene = StartScene.newStartScene()
    view.presentScene(startScene, transition: SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration))
}

/// Sprint 7 Phase D — characterName → CharacterID 역변환 헬퍼.
/// allCases에 5명 displayName 모두 유일 → 안전.
private var inferredCharacterID: CharacterID? {
    CharacterID.allCases.first { $0.displayName == characterName }
}
```

### 기능 2: CharacterFaceNode.mini 32pt 팩토리

```swift
// MARK: - Mini Factory (Sprint 7 Phase D)
/// Sprint 7 Phase D — Scoreboard 좌측 행 헤더용 32pt 미니 얼굴.
/// 기존 init(id:) 결과를 0.47x로 축소(32/68 ≈ 0.47). 신규 시각 자식 0건.
static func mini(id: CharacterID) -> CharacterFaceNode {
    let face = CharacterFaceNode(id: id)
    face.setScale(GameConfig.scoreboardMiniFaceScale)
    face.name = "miniFace_\(id.rawValue)"
    return face
}
```

### 기능 3: ScoreboardScene 신규 씬

**파일**: `Scenes/ScoreboardScene.swift` (신규 ~340 LOC)

**노드 트리**
```
ScoreboardScene
├── gradientBg (GradientBackgroundNode.threeStop, zPos -20)
├── backButton (GlassPillNode "← 결과로", zPos 100, top-left)
├── breadcrumbChip (DarkContextChipNode "캐릭터별 기록", zPos 100, top-right)
├── accentLine (AccentLineNode, zPos 5, midY+130)
├── titleLabel ("기록 보기", Jua 30pt, midY+95)
├── subtitleLabel ("캐릭터·난이도별 최고점수", Gowun 12pt, midY+72)
├── matrixContainer (SKNode, midY+10)
│   ├── 열 헤더 3개 (하·중·상 SKLabel + Phase C 색)
│   ├── 행 헤더 5개 (mini face + 약칭)
│   ├── 15 셀 (Jua 18pt navy / "—" Gowun 14pt 회색 alpha 0.4)
│   └── ★ 마커 (lastUpdatedKey 셀, gold)
└── statLabel ("총 플레이 N회 · 졸업장 N장 보유", midY-150)
```

**핵심 구조**
```swift
final class ScoreboardScene: SKScene {
    private let lastUpdatedKey: (CharacterID, Difficulty)?
    private let returnContext: ResultReturnContext?
    private var isTransitioning = false

    private let perDiffRepo = PerDifficultyScoreRepository()
    private let statsRepo = StatisticsRepository()
    private let graduationRepo = GraduationRepository()

    // 자식 노드들...
    private let matrixContainer = SKNode()

    class func newScoreboardScene(
        lastUpdatedKey: (CharacterID, Difficulty)? = nil,
        returnContext: ResultReturnContext? = nil
    ) -> ScoreboardScene {
        let scene = ScoreboardScene(
            size: CGSize(width: 1024, height: 768),
            lastUpdatedKey: lastUpdatedKey,
            returnContext: returnContext
        )
        scene.scaleMode = .resizeFill
        return scene
    }

    private init(size: CGSize, lastUpdatedKey: (CharacterID, Difficulty)?, returnContext: ResultReturnContext?) {
        self.lastUpdatedKey = lastUpdatedKey
        self.returnContext = returnContext
        super.init(size: size)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        setupBackgroundGradient()
        setupHeader()
        setupBackButton()
        setupBreadcrumbChip()
        setupMatrix()
        setupStatLabel()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutAll()
    }

    // 매트릭스 셀 좌표 계산
    private func cellPosition(row: Int, col: Int) -> CGPoint {
        let totalWidth = GameConfig.scoreboardRowHeaderWidth
            + CGFloat(GameConfig.scoreboardMatrixColumnCount) * GameConfig.scoreboardCellWidth
            + CGFloat(GameConfig.scoreboardMatrixColumnCount - 1) * GameConfig.scoreboardCellGap
        let originX = frame.midX - totalWidth / 2
        let cellX = originX + GameConfig.scoreboardRowHeaderWidth
            + CGFloat(col) * (GameConfig.scoreboardCellWidth + GameConfig.scoreboardCellGap)
            + GameConfig.scoreboardCellWidth / 2

        let matrixHeight = CGFloat(GameConfig.scoreboardMatrixRowCount) * GameConfig.scoreboardCellHeight
            + CGFloat(GameConfig.scoreboardMatrixRowCount - 1) * GameConfig.scoreboardCellGap
        let originY = frame.midY + GameConfig.scoreboardMatrixOffsetY + matrixHeight / 2
        let cellY = originY - GameConfig.scoreboardCellHeight / 2
            - CGFloat(row) * (GameConfig.scoreboardCellHeight + GameConfig.scoreboardCellGap)

        return CGPoint(x: cellX, y: cellY)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning, let view = self.view, let touch = touches.first else { return }
        let location = touch.location(in: self)
        if let back = backButton, back.contains(location) {
            isTransitioning = true
            returnToResultOrStart(view: view)
        }
    }

    private func returnToResultOrStart(view: SKView) {
        let nextScene: SKScene
        if let ctx = returnContext {
            nextScene = ResultScene.newResultScene(
                score: ctx.finalScore, bestScore: ctx.bestScore, isNewBest: ctx.isNewBest,
                stats: ctx.stats, characterName: ctx.characterName, difficulty: ctx.difficulty,
                isNewGraduation: false,    // 졸업장 재표시 차단
                graduatedAt: nil
            )
        } else {
            nextScene = StartScene.newStartScene()
        }
        view.presentScene(nextScene, transition: SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration))
    }
}

/// ResultScene → ScoreboardScene → ResultScene 라운드트립용 9-인자 컨텍스트.
struct ResultReturnContext {
    let finalScore: Int
    let bestScore: Int
    let isNewBest: Bool
    let stats: GameStats
    let characterName: String
    let difficulty: Difficulty
    let isNewGraduation: Bool
    let graduatedAt: Date?
}
```

> **주의**: `ResultScene.newResultScene` 실제 시그니처는 Generator가 코드에서 grep으로 확인 후 정확한 인자 순서·이름 매핑.

### 기능 4: GameConfig Phase D V3 상수 신규

**위치**: `Config/GameConfig.swift` 파일 끝, `// MARK: - Sprint 7 Phase D · ResultScene v3 + ScoreboardScene` 새 섹션

**상수 ~40개** (값 일부 발췌):
```swift
// ResultScene V3
static let resultScoreNoteIconFontSizeV3: CGFloat = 24
static let resultScoreNoteIconOffsetXV3: CGFloat = -60
static let resultScoreRowOffsetYV3: CGFloat = -2
static let resultBestPillWidthV3: CGFloat = 120
static let resultBestPillHeightV3: CGFloat = 28
static let resultBestPillOffsetXV3: CGFloat = 120
static let resultHeaderChipOffsetYV3: CGFloat = 115
static let resultTitleOffsetYV3: CGFloat = 85
static let resultSubtitleOffsetYV3: CGFloat = 58
static let resultAccentLineOffsetYV3: CGFloat = 148
static let resultScoreSubOffsetYV3: CGFloat = -44
static let resultDividerOffsetYV3: CGFloat = -78
static let resultStatValueOffsetYV3: CGFloat = -98
static let resultStatTitleOffsetYV3: CGFloat = -112
static let resultScoreboardButtonWidthV3: CGFloat = 110
static let resultScoreboardButtonOffsetXFromShareV3: CGFloat = -110
static let resultScoreboardButtonText: String = "📊 기록 보기"
static let resultBestPillTextNormalV3: String = "🏆 BEST"
static let resultBestPillTextNewV3: String = "★ NEW BEST!"

// ScoreboardScene 매트릭스
static let scoreboardMatrixColumnCount: Int = 3
static let scoreboardMatrixRowCount: Int = 5
static let scoreboardCellWidth: CGFloat = 80
static let scoreboardCellHeight: CGFloat = 36
static let scoreboardCellGap: CGFloat = 4
static let scoreboardRowHeaderWidth: CGFloat = 60
static let scoreboardMatrixOffsetY: CGFloat = 10
static let scoreboardMiniFaceScale: CGFloat = 0.47
static let scoreboardCellScoreFontSize: CGFloat = 18
static let scoreboardCellEmptyFontSize: CGFloat = 14
static let scoreboardCellEmptyText: String = "—"
static let scoreboardCellEmptyAlpha: CGFloat = 0.4
static let scoreboardColumnHeaderFontSize: CGFloat = 15
static let scoreboardRowHeaderShortNameFontSize: CGFloat = 13
static let scoreboardRowHeaderShortNameOffsetX: CGFloat = 22
static let scoreboardStarMarkerText: String = "★"
static let scoreboardStarMarkerFontSize: CGFloat = 12
static let scoreboardStarMarkerOffsetX: CGFloat = 28
static let scoreboardStarMarkerOffsetY: CGFloat = 12

// ScoreboardScene 헤더 + stat + 백 버튼
static let scoreboardTitleOffsetY: CGFloat = 95
static let scoreboardTitleFontSize: CGFloat = 30
static let scoreboardSubtitleOffsetY: CGFloat = 72
static let scoreboardSubtitleFontSize: CGFloat = 12
static let scoreboardSubtitleText: String = "캐릭터·난이도별 최고점수"
static let scoreboardTitleText: String = "기록 보기"
static let scoreboardAccentLineOffsetY: CGFloat = 130
static let scoreboardBackButtonWidth: CGFloat = 110
static let scoreboardBackButtonHeight: CGFloat = 36
static let scoreboardBackButtonText: String = "← 결과로"
static let scoreboardBackButtonInsetX: CGFloat = 20
static let scoreboardBackButtonInsetY: CGFloat = 32
static let scoreboardBreadcrumbInsetX: CGFloat = 20
static let scoreboardBreadcrumbInsetY: CGFloat = 32
static let scoreboardBreadcrumbText: String = "캐릭터별 기록"
static let scoreboardStatOffsetY: CGFloat = -150
static let scoreboardStatFontSize: CGFloat = 12
```

### 기능 5: 신규 mockup HTML 2개

**파일 1**: `mockups/result-screen-v3.html`
- v2 카피 → "♪" 분리(별도 .score-note-icon 24pt 좌측 absolute) / BEST GlassPill 우측 +120px / headerChip top +15 / 새 .btn-scoreboard 좌측 추가
- annotation: "Sprint 7 Phase D — SPRINT_7_REQUEST.md §5.2 매칭"

**파일 2**: `mockups/highscore-board-v1.html`
- 1024×768 .phone-frame, 3-stop warm gradient
- 좌상단 GlassPill "← 결과로", 우상단 DarkContextChip "캐릭터별 기록"
- 중앙 accentLine + Jua 30pt "기록 보기" + 부제
- 매트릭스 5×3: 헤더 행(하/중/상 Phase C 색) + 5행(mini SVG 32px + 약칭 + 3 셀)
- 4행(건간호) 1열(하)에 ★ + 큰 점수 200
- 빈 셀 "—" 회색
- 하단 "총 플레이 N회 · 졸업장 N장 보유"

## 합격 기준 (SPRINT_7_REQUEST.md §5.6)

- 결과창 5개 정보 요소 시뮬레이터 0px 겹침
- 기록 보기 칩 탭 → ScoreboardScene 0.25s fade
- 15셀 매트릭스 값 PerDifficultyScoreRepository.best와 일치
- "← 결과로" 탭 → 새 ResultScene 인스턴스, 졸업장 재표시 0, sparkle 재발화 0
- ★ 마커 직전 게임 (캐릭터,난이도) 셀에 1개만
- 빈 셀 "—" 회색

| 카테고리 | 가중치 | 통과선 |
|---|---|---|
| 게임 로직 회귀 0 | 40% | 9.0 |
| Swift 패턴 | 20% | 7.0 |
| 비주얼 일관성 | 25% | 7.0 |
| 가독성 & UX | 15% | 7.0 |

가중 평균 7.5 이상 합격.

## 변경 LOC 추정치

| 파일 | LOC |
|---|---|
| `Scenes/ResultScene.swift` | +60 |
| `Scenes/ScoreboardScene.swift` (신규) | +340 |
| `Nodes/CharacterFaceNode.swift` | +12 |
| `Config/GameConfig.swift` | +95 |
| `mockups/result-screen-v3.html` (신규) | +250 |
| `mockups/highscore-board-v1.html` (신규) | +220 |
| **합계** | **~975 LOC** (Swift만 ~500) |

## OPEN_QUESTION

**OQ-1 (결정됨)**: ScoreboardScene → ResultScene 복귀는 옵션 A (새 인스턴스 생성, `ResultReturnContext` struct로 9-인자 전달, `isNewGraduation: false` 강제로 졸업장 재표시 차단). 1탭 정책은 각 화면 안에서 유지.

**OQ-2 (결정됨)**: GraduationRepository API는 `graduationRepo.current.count` (`current: [CharacterID: Date]`의 keys 개수). `totalPlays`도 `statsRepo.current.playCount`.

**OQ-3 (결정됨)**: ★ 마커는 ResultScene이 `isNewBest + inferredCharacterID + difficulty`로 lastUpdatedKey 산출. 전역 isNewBest와 perDiff isNewBest 미세 차이는 근사 허용 (init 시그니처 변경 금지).

**OQ-4 (결정됨)**: CharacterFaceNode.mini 팩토리는 기존 `init(id:)` + `setScale(0.47)`. 신규 시각 자식 0.

## 주의사항

1. **bestLabel 충돌**: 기존 `bestLabel`은 노드 트리 보존, `.alpha = 0`으로 시각만 차단. `startBestLabelGoldBlink()` fadeAlpha 액션은 0↔0.3 깜빡여도 시각 안 보임 (괜찮음).
2. **isNewBest sparkle 5발**: `resultSparklePositionsV2` 좌표는 카드 주변이라 점수 위치 변경 영향 0.
3. **졸업장 재진입 차단**: 복귀 시 `isNewGraduation: false` 명시.
4. **CharacterID 역변환 안전**: 5 displayName 유일.
5. **SceneSafeArea 적용**: ScoreboardScene도 백 버튼/브레드크럼 top inset 안전.
6. **Repository 인스턴스**: 매번 new (기존 코드 패턴 동일, UserDefaults 기반).
7. **★ zPosition**: 셀(2)보다 위(3).
8. **`ResultReturnContext` struct**: ScoreboardScene.swift 같은 파일 내 정의 (Foundation 의존만).

## 관련 파일 (절대 경로)

- 수정: `GanhoMusic/GanhoMusic Shared/Scenes/ResultScene.swift`, `Nodes/CharacterFaceNode.swift`, `Config/GameConfig.swift`
- 신규: `Scenes/ScoreboardScene.swift`, `mockups/result-screen-v3.html`, `mockups/highscore-board-v1.html`
- 참조: `Repositories/PerDifficultyScoreRepository.swift`, `StatisticsRepository.swift`, `GraduationRepository.swift`, `Models/CharacterID.swift`, `Models/Difficulty.swift`, `mockups/result-screen-v2.html`
