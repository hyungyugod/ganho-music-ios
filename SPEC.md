# Sprint 5 — ResultScene 3분기 v2 리스킨 + DiplomaOverlayNode 우드컷

## 개요
ResultScene과 DiplomaOverlayNode를 `mockups/result-screen-v2.html` 시각에 맞춰 리스킨한다. 점수·저장·햅틱·사운드·전환 로직은 한 줄도 건드리지 않으며, **세 분기(A 일반 / B 신기록 / C 졸업장)** 의 시각 차이만 토큰·폰트·파편·우드컷 패턴으로 표현한다.

## 변경 유형
**비주얼** — ResultScene 시각 갱신 + DiplomaOverlayNode 종이 패턴/명조 폰트 갱신. 게임 로직 / 저장소 5개 / 햅틱·사운드 발화 조건 0 변경.

## 게임 경험 의도
플레이어가 결과 화면에서 *세 가지 감정*을 명확히 구분되게 한다 — (A) 일반: "괜찮았어, 한 번 더 해볼까?"의 따뜻한 위로, (B) 신기록: "내가 해냈다!"의 황금 폭발과 별 파편의 환호, (C) 졸업장: "긴 실습을 마쳤다"의 종이 증서가 주는 의례적 무게감. 게임 종료가 "벌"이 아니라 "보상"으로 느껴지도록 부정 단어("GAME OVER")를 따뜻한 카피("실습 종료")로 교체한다.

## Sprint 범위 계약

### IN — 이번 Sprint에서 변경
- `Scenes/ResultScene.swift` — 시각 레이아웃·색·폰트·신규 자식 노드(부제, 글래스 stat, 공유/다시시작 버튼, sparkle 5발). `setupOverlayPanel()` 색 토큰 갈아 끼움. `setupLabels()` 가지치기 + 신규 라벨/노드 부착. `revealNewBest()`에 sparkle 5발 호출 추가.
- `Nodes/DiplomaOverlayNode.swift` — `configureBackground()`에 우드컷 패턴 SKShape 자식 + double-border 자식 추가. 라벨 fontName을 명조(`fontSerif`)로 교체. 라벨 색·도장 자식 추가.
- `Config/GameConfig.swift` — Sprint 5 신규 상수만 **추가**. 폰트 이름 상수 `fontSerif` 1개 추가(파일 없어도 시스템 fallback로 안전). 기존 상수 변경 0.
- `Config/ColorTokens.swift` — Diploma 전용 토큰 4개 추가 (`ganhoDiplomaPaper`, `ganhoDiplomaBorder`, `ganhoDiplomaTextDeep`, `ganhoDiplomaTextMuted`). 기존 토큰 변경 0.

### OUT — 절대 변경 금지
- **`ResultScene.init` 9개 인자 시그니처** (`size`, `score`, `bestScore`, `isNewBest`, `stats`, `characterName`, `difficulty`, `isNewGraduation`, `graduatedAt`) — 순서·이름·타입 한 글자도 변경 금지. `newResultScene` 정적 팩토리 시그니처도 동일.
- `HighScoreRepository` / `StatisticsRepository` / `PerDifficultyScoreRepository` / `GraduationRepository` / `CharacterPreferenceRepository` 저장 키·로직.
- `haptics.heavy()` / `audio.play(.comboMilestoneStrong)` 발화 *조건*과 *타이밍*.
- DiplomaOverlayNode 본문 텍스트("다사다난한 실습을 마치고 {NAME}는 드디어 졸업하였다." 및 본문 2). `SelfDismissingNode` 자가 소멸 패턴. private init + `present(...)` 정적 팩토리.
- 2단계 탭 정책: 졸업장 1탭 → 졸업장 닫힘 → ResultScene 노출 → ResultScene 1탭 → StartScene fade.
- `touchesBegan`의 `diplomaOverlay` 가드, `transitionToStart` 경로(`StartScene.newStartScene()` + `SKTransition.fade`).
- GameScene.swift의 `ResultScene.newResultScene(...)` 호출부.
- Sprint 1~3 결과물: ColorTokens v2 16토큰, GameConfig 폰트 3, GlassPillNode / AccentLineNode / DarkContextChipNode / PrimaryButtonNode / BackButtonNode / GradientBackgroundNode.threeStop / PauseButtonNode / SparkleEffectNode 내부 0건.

### 판단 기준
"이 변경이 없으면 SPEC 시각이 안 나오는가?" YES면 허용, NO면 금지.

---

## 불변 계약 표

| 항목 | 출처 / 위치 | 보존 요구 |
|---|---|---|
| ResultScene init 시그니처 | `ResultScene.swift` factory + init | 9개 인자 순서·이름·타입 한 글자도 동일 |
| ResultScene 호출부 | `GameScene.swift` endGame() | 한 줄도 변경 금지 |
| HighScoreRepository / StatisticsRepository / PerDifficultyScoreRepository / GraduationRepository | GameScene.endGame() 내부 | ResultScene 진입 *전*에 record가 완료된다는 전제. ResultScene은 *결과 데이터만* 받음 |
| heavy 햅틱 발화 | `revealNewBest()` 첫 줄 `haptics.heavy()` | `isNewBest=true` → `scheduleNewBestReveal()` → `wait 0.3s` → `revealNewBest()` 시퀀스 보존 |
| NewMail 사운드 발화 | `revealNewBest()` 두 번째 줄 `audio.play(.comboMilestoneStrong)` | 동일 시퀀스 |
| DiplomaOverlayNode 본문 텍스트 | `DiplomaOverlayNode.swift` body1/body2 | 글자 그대로. {NAME} 치환 로직 보존 |
| SelfDismissingNode 패턴 | `DiplomaOverlayNode.swift` `dismiss()` | `isUserInteractionEnabled=false` + `onDismiss=nil` + `fadeOut → removeFromParent → notify` 시퀀스 |
| 2단계 탭 정책 | ResultScene touchesBegan + `presentDiploma`의 `onDismiss: {}` | `children.contains(where: { $0.name == "diplomaOverlay" })` 가드 유지 |
| 1탭 → StartScene fade | ResultScene transitionToStart | `StartScene.newStartScene()` + `SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)` |

---

## 3 분기별 시각 명세

### 분기 A: 일반 결과 (기본)
- **트리거**: `isNewBest=false && isNewGraduation=false`
- **배경**: 3-stop warm 그라데이션 — `GradientBackgroundNode.threeStop(...)`. zPosition 매우 낮음 (기존 검정 반투명 사각형 *교체*).
- **카드**: 기존 `setupOverlayPanel()` SKShapeNode 활용. `fillColor`를 `UIColor.white.withAlphaComponent(0.88)` (신규 토큰 `ganhoResultCardFillV2`). cornerRadius 22.
- **AccentLine**: 카드 상단 내부 `AccentLineNode()`, y 오프셋 +130.
- **헤더 칩**: `DarkContextChipNode(label: "\(difficulty.shortName) 난이도 · \(characterName)", badge: nil)` 한 줄 통합.
- **타이틀**: "실습 종료" — Jua 30pt, navyDeep.
- **부제(신규)**: "수고했어요! 한 번 더 해볼까요?" — Gowun Dodum 12pt, navyMuted.
- **점수**: "♪ \(finalScore)" — Jua 64pt, **ganhoCoralPrimary**.
- **점수 라벨(신규)**: "SCORE" — Gowun Dodum 11pt, navyMuted.
- **BEST 칩**: "🏆 BEST \(bestScore)" — 골드 톤 알약.
- **divider(신규)**: 가로 60% navyDeep α=0.18 라인.
- **통계 stats**: PLAYS·TOTAL 두 그룹. 숫자 Jua 14, 라벨 Gowun Dodum 11.
- **버튼 2개**: `GlassPillNode("📤 공유")` + `PrimaryButtonNode("다시 시작")`.
- **sparkle**: 없음.

### 분기 B: 신기록 (isNewBest=true)
A와 동일하되:
- **타이틀**: "✨ NEW BEST! ✨" — 골드 톤 (titleLabel.text 분기로 교체 + fontColor=ganhoMusicGold). 기존 `newBestLabel`은 화면 정 가운데 큰 라벨로 유지(y 분리).
- **부제**: "최고 기록을 갱신했어요!" — Gowun Dodum 12pt navyMuted.
- **점수 색**: `scoreLabel.fontColor = .ganhoMusicGold`.
- **점수 부제**: "NEW SCORE".
- **BEST 칩**: 기존 `startBestLabelGoldBlink()` 패턴 그대로 (shimmer 알파 펄스).
- **별 파편**: `revealNewBest()` 내부에서 `SparkleEffectNode()` 5개를 카드 주변 5개 좌표에 부착 + `emit()` 호출.
- **shareButton 텍스트**: "📤 자랑하기".
- **햅틱·사운드**: `revealNewBest()` 기존 `haptics.heavy()` / `audio.play(.comboMilestoneStrong)` 그대로.

### 분기 C: 졸업장 (isNewGraduation=true && graduatedAt != nil)
A 분기 카드 위에 `DiplomaOverlayNode`가 덮음 (기존 `presentDiploma` 호출 유지).
- **DiplomaOverlayNode 시각**:
  - **배경**: 기존 `background: SKSpriteNode(color: .ganhoYellowF α=0.92)` 유지.
  - **종이 카드**: SKShapeNode 520×320 cornerRadius 8, fillColor `ganhoDiplomaPaper`(#FFF9EA), strokeColor `ganhoDiplomaBorder`(#C76F00), lineWidth 4, zRotation -2°.
  - **우드컷 도트 패턴**: **단일 SKShapeNode + CGMutablePath** (도트 1100개를 path에 누적 — 노드 1개로 통합 = 성능 안전).
  - **double-border**: ㄱ자 코너 데코 2개(좌상·우하), strokeColor `ganhoDiplomaBorder` lineWidth 3.
  - **명조 폰트**: 라벨 7개 모두 `fontName = GameConfig.fontSerif` ("GowunBatang-Regular"). ttf 미존재 시 시스템 fallback (안전).
  - **라벨 색**: titleEn/issuer/date/tap = `ganhoDiplomaTextMuted`(#8B5A0E), titleKo/body1/body2 = `ganhoDiplomaTextDeep`(#5A3A0E).
  - **도장**: SKShapeNode 원 r=28 우하단 + "김간호\n음악대학" 라벨(Jua 9pt, coralShadow). -12° 회전.
  - **TAP 안내**: 기존 `tapLabel` 보존.
- **탭 동작**: 기존 `dismiss()` → `onDismiss = {}` → ResultScene 노출 → 1탭 → StartScene. **2단계 탭 정책 보존**.

---

## 파일별 변경 명세

### 1) `Scenes/ResultScene.swift`

#### MARK: - Properties (신규 추가)
```swift
private let subtitleLabel = SKLabelNode(text: "")
private let scoreSubLabel = SKLabelNode(text: "SCORE")
private let bestChipBg = SKShapeNode()
private let divider = SKShapeNode()
private let playsValueLabel = SKLabelNode(text: "")
private let playsTitleLabel = SKLabelNode(text: "PLAYS")
private let totalValueLabel = SKLabelNode(text: "")
private let totalTitleLabel = SKLabelNode(text: "TOTAL")
private let shareButton: GlassPillNode  // init에서 정식 생성 (text/size 분기)
private let restartButton = PrimaryButtonNode(text: "다시 시작")
private var headerChip: DarkContextChipNode?
private var gradientBg: GradientBackgroundNode?
private let accentLine = AccentLineNode()
```

#### MARK: - Lifecycle
`didMove(to:)`:
1. `setupBackgroundGradient()` (신규) — 기존 `backgroundColor` 라인 제거 또는 `.clear`. `GradientBackgroundNode.threeStop(...)`를 zPosition=-20에 부착.
2. `setupOverlayPanel()` — 보존하되 색 토큰 갈아 끼움.
3. `setupLabels()` — 가지치기.

#### MARK: - setupOverlayPanel (수정)
- `bg`(전체 반투명 검정) alpha=0 (그라데이션이 배경 담당).
- `panel.fillColor = UIColor.white.withAlphaComponent(0.88)`.
- `panel.strokeColor = .clear`.
- cornerRadius `resultCardCornerRadiusV2 = 22`.

#### MARK: - setupLabels (확장)
순서:
1. 기존 6개 라벨 fontName/fontSize/fontColor를 v2 토큰으로 교체 (분기별).
2. characterLabel·difficultyLabel·statsLabel alpha=0 (headerChip + stat 그룹이 대체).
3. headerChip 부착 (`DarkContextChipNode`).
4. AccentLine 부착.
5. subtitleLabel 부착 (분기별 텍스트).
6. scoreSubLabel 부착 ("SCORE" / "NEW SCORE").
7. divider 부착.
8. setupStats() — PLAYS/TOTAL 4 라벨.
9. setupButtons() — shareButton/restartButton.
10. layoutLabels().
11. **기존 분기 2개**(isNewBest → configureNewBestLabel + scheduleNewBestReveal / isNewGraduation → presentDiploma) **한 글자도 변경 금지**.

#### MARK: - setupStats (신규)
4 라벨 init + addChild.

#### MARK: - setupButtons (신규)
shareButton(분기별 텍스트 "📤 공유" / "📤 자랑하기") + restartButton addChild.

#### MARK: - layoutLabels (확장)
신규 자식 위치를 frame.midY 기준 offset 배치:
| 자식 | y 오프셋 |
|---|---|
| accentLine | +130 |
| headerChip | +100 |
| titleLabel | +70 |
| subtitleLabel | +44 |
| scoreLabel | -2 |
| scoreSubLabel | -32 |
| bestLabel | -60 |
| divider | -90 |
| stats values | -110 (midX ± 50) |
| stats titles | -124 (midX ± 50) |
| shareButton | -180 (midX-70) |
| restartButton | -180 (midX+80) |

#### MARK: - revealNewBest (수정)
```swift
private func revealNewBest() {
    haptics.heavy()                    // 보존 — 발화 조건/타이밍 동일
    audio.play(.comboMilestoneStrong)  // 보존
    // ... 기존 fadeIn / scale pulse / startBestLabelGoldBlink 보존
    emitSparkleBurst()                 // 신규 — 마지막 라인 추가
}

private func emitSparkleBurst() {
    for offset in GameConfig.resultSparklePositionsV2 {
        let sparkle = SparkleEffectNode()
        sparkle.position = CGPoint(x: frame.midX + offset.x, y: frame.midY + offset.y)
        sparkle.zPosition = GameConfig.newBestZPosition + 1
        addChild(sparkle)
        sparkle.emit()
    }
}
```

#### MARK: - configureLabelV2 (신규 헬퍼)
```swift
private func configureLabelV2(_ label: SKLabelNode,
                               text: String,
                               fontName: String,
                               fontSize: CGFloat,
                               fontColor: UIColor) {
    label.text = text
    label.fontName = fontName
    label.fontSize = fontSize
    label.fontColor = fontColor
    label.horizontalAlignmentMode = .center
    label.verticalAlignmentMode = .center
}
```

#### MARK: - touchesBegan (보존)
한 줄도 변경 없음. shareButton/restartButton 시각만 — 탭은 기존 1탭 → StartScene 경로 그대로.

### 2) `Nodes/DiplomaOverlayNode.swift`

#### MARK: - Properties (신규)
```swift
private let paperCard: SKShapeNode
private let topLeftBorder: SKShapeNode
private let bottomRightBorder: SKShapeNode
private let stamp: SKShapeNode
private let stampLabel: SKLabelNode
private let dotsPattern: SKShapeNode   // 단일 노드, CGMutablePath
```

#### MARK: - Init (수정 — 시각만 추가)
- 기존 background SKSpriteNode + 라벨 7개 그대로.
- `configureBackground()`에서 paperCard / dotsPattern / 코너 데코 / 도장 부착.
- 라벨 7개 fontName을 `GameConfig.fontSerif`로 교체.
- 라벨 색을 명조 톤으로 분기 (titleEn/issuer/date/tap = TextMuted, titleKo/body1/body2 = TextDeep).
- **본문 텍스트 한 글자도 변경 금지**. `{NAME}` 치환 로직 그대로.

#### MARK: - configureBackground (확장)
```swift
private func configureBackground() {
    background.position = .zero
    background.zPosition = 0

    paperCard.path = CGPath(roundedRect: CGRect(
        x: -GameConfig.diplomaPaperWidthV2/2,
        y: -GameConfig.diplomaPaperHeightV2/2,
        width: GameConfig.diplomaPaperWidthV2,
        height: GameConfig.diplomaPaperHeightV2
    ), cornerWidth: 8, cornerHeight: 8, transform: nil)
    paperCard.fillColor = .ganhoDiplomaPaper
    paperCard.strokeColor = .ganhoDiplomaBorder
    paperCard.lineWidth = 4
    paperCard.zRotation = -CGFloat.pi / 90  // -2°
    paperCard.zPosition = 0.5
    addChild(paperCard)

    buildDotsPattern()
    configureCornerDeco()
    configureStamp()
}

private func buildDotsPattern() {
    // 단일 SKShapeNode + CGMutablePath addEllipse N회 누적
    let cardW = GameConfig.diplomaPaperWidthV2
    let cardH = GameConfig.diplomaPaperHeightV2
    let step = GameConfig.diplomaDotStepV2
    let radius = GameConfig.diplomaDotRadiusV2

    let path = CGMutablePath()
    var x = -cardW/2 + step
    while x < cardW/2 {
        var y = -cardH/2 + step
        while y < cardH/2 {
            path.addEllipse(in: CGRect(x: x - radius, y: y - radius,
                                        width: radius * 2, height: radius * 2))
            y += step
        }
        x += step
    }
    dotsPattern.path = path
    dotsPattern.fillColor = UIColor(hex: "#FFEDC6").withAlphaComponent(0.4)
    dotsPattern.strokeColor = .clear
    dotsPattern.zPosition = 0.7
    dotsPattern.zRotation = -CGFloat.pi / 90
    addChild(dotsPattern)
}
```

#### MARK: - configureCornerDeco (신규)
ㄱ자 path 2개(좌상·우하), strokeColor `ganhoDiplomaBorder` lineWidth 3, zRotation -2°.

#### MARK: - configureStamp (신규)
원 r=28 + 라벨 "김간호\n음악대학" Jua 9pt coralShadow. -12° 회전. 우하단.

#### MARK: - dismiss / touchesBegan / present (보존)
한 글자도 변경 없음.

### 3) `Config/GameConfig.swift`

#### MARK: - Sprint 5 · ResultScene v2 Layout (신규)
```swift
// 폰트
static let fontSerif: String = "GowunBatang-Regular"

// ResultScene v2
static let resultCardCornerRadiusV2: CGFloat = 22
static let resultAccentLineOffsetYV2: CGFloat = 130
static let resultHeaderChipOffsetYV2: CGFloat = 100
static let resultTitleOffsetYV2: CGFloat = 70
static let resultTitleFontSizeV2: CGFloat = 30
static let resultSubtitleOffsetYV2: CGFloat = 44
static let resultSubtitleFontSizeV2: CGFloat = 12
static let resultScoreOffsetYV2: CGFloat = -2
static let resultScoreNumFontSizeV2: CGFloat = 64
static let resultScoreSubOffsetYV2: CGFloat = -32
static let resultBestOffsetYV2: CGFloat = -60
static let resultBestFontSizeV2: CGFloat = 13
static let resultDividerOffsetYV2: CGFloat = -90
static let resultDividerWidthRatioV2: CGFloat = 0.6
static let resultStatValueFontSizeV2: CGFloat = 14
static let resultStatTitleFontSizeV2: CGFloat = 11
static let resultStatValueOffsetYV2: CGFloat = -110
static let resultStatTitleOffsetYV2: CGFloat = -124
static let resultStatGroupSpacingXV2: CGFloat = 50
static let resultButtonOffsetYV2: CGFloat = -180
static let resultShareButtonWidthV2: CGFloat = 100
static let resultShareButtonHeightV2: CGFloat = 36
static let resultShareButtonXOffsetV2: CGFloat = -70
static let resultRestartButtonXOffsetV2: CGFloat = 80

// Sparkle 5발 좌표
static let resultSparklePositionsV2: [CGPoint] = [
    CGPoint(x: -150, y:  60),
    CGPoint(x:  130, y:  40),
    CGPoint(x: -110, y: -40),
    CGPoint(x:  140, y: -60),
    CGPoint(x: -180, y:   0)
]

// Diploma v2
static let diplomaPaperWidthV2: CGFloat = 520
static let diplomaPaperHeightV2: CGFloat = 320
static let diplomaDotStepV2: CGFloat = 12
static let diplomaDotRadiusV2: CGFloat = 1.0
static let diplomaCornerDecoSizeV2: CGFloat = 30
static let diplomaCornerDecoInsetV2: CGFloat = 6
```

### 4) `Config/ColorTokens.swift`

#### MARK: - v2 Diploma Tokens (Sprint 5, 신규)
```swift
static let ganhoDiplomaPaper      = UIColor(hex: "#FFF9EA")
static let ganhoDiplomaBorder     = UIColor(hex: "#C76F00")
static let ganhoDiplomaTextDeep   = UIColor(hex: "#5A3A0E")
static let ganhoDiplomaTextMuted  = UIColor(hex: "#8B5A0E")
```

**기존 토큰 한 줄도 변경 0**.

---

## 검증 체크리스트 (Evaluator용)

### P0 — 즉시 불합격
- [ ] `ResultScene.init` 9개 인자 시그니처 한 글자라도 변경
- [ ] `ResultScene.newResultScene(...)` 정적 팩토리 시그니처 변경
- [ ] `GameScene.swift` ResultScene 호출부 한 줄이라도 변경
- [ ] `DiplomaOverlayNode` private init / present 정적 팩토리 시그니처 변경
- [ ] `dismiss()` 메서드의 nil 토글 / removeFromParent / fadeOut SKAction 시퀀스 변경
- [ ] `touchesBegan`의 `diplomaOverlay` name 가드 변경
- [ ] `transitionToStart` 경로 변경
- [ ] `haptics.heavy()` / `audio.play(.comboMilestoneStrong)` 호출 *조건* 변경
- [ ] DiplomaOverlayNode 본문 텍스트 한 글자라도 변경
- [ ] Repositories 5개 호출 위치/순서 변경

### P1 — Swift 패턴 (20%)
- [ ] 강제 언래핑 `!` 0건
- [ ] Timer 사용 0건
- [ ] 매직 넘버 0건 (모든 수치 GameConfig 상수)
- [ ] hex 하드코딩 0건 (ColorTokens 사용 — Sprint 5 신규 토큰 4개만 추가)
- [ ] `// MARK:` 섹션 구분
- [ ] private / final / let 일관성

### P2 — 분기별 시각 (25%)
- [ ] 분기 A: 타이틀 "실습 종료" navyDeep / 점수 코랄 / 부제 "수고했어요! 한 번 더 해볼까요?" / sparkle 0개 / shareButton "📤 공유"
- [ ] 분기 B: 타이틀 "✨ NEW BEST! ✨" 골드 / 점수 골드 / 부제 "최고 기록을 갱신했어요!" / sparkle 5개 동시 / shareButton "📤 자랑하기" / heavy 햅틱 / NewMail 사운드
- [ ] 분기 C: A 카드 위에 DiplomaOverlayNode 오버레이 / 우드컷 종이 + 도트 패턴 + 코너 데코 + 도장 / 본문 텍스트 보존
- [ ] 2단계 탭 정책 유지

### P3 — 빌드 & 호환 (15%)
- [ ] `xcodebuild` SUCCEEDED
- [ ] `fontSerif` ttf 부재 시에도 크래시 0 (시스템 fallback)
- [ ] 5×3=15 캐릭터·난이도 조합 + 신기록 + 졸업장 분기 진입 가능

### P4 — Sprint 1~3 보호 (40%, 회귀 0)
- [ ] GameScene / GameScene+Setup git diff 0줄
- [ ] StartScene / CharacterSelectScene / SkillExplanationScene git diff 0줄
- [ ] Sprint 1 컴포넌트 6개 + PauseButtonNode 0줄
- [ ] SparkleEffectNode 한 줄도 무변
- [ ] Repositories 5개 / Managers 3개 / Systems / Models 0줄
- [ ] EnemyNode/ProfessorNode/StoneGuardNode/PlayerNode 등 인게임 노드 0줄

---

## 주의사항

1. **`scheduleNewBestReveal` 시퀀스 보존**: `wait 0.3s → revealNewBest()` 흐름 한 줄도 변경 금지. sparkle 5발은 *`revealNewBest()` 내부 마지막 라인 추가*로만 부착.

2. **`SparkleEffectNode` 재활용**: 이미 음표 수집 시 사용 중. ResultScene 부착 좌표/zPosition만 다르고 내부 0건 변경. `emit()` 마지막에 `removeFromParent()` 자가 소멸.

3. **도트 패턴 단일 노드 통합**: 12pt 격자 약 1100개 도트를 *단일 SKShapeNode + CGMutablePath addEllipse 누적*으로 통합. 노드 수 1개 = SpriteKit 렌더 부담 최소.

4. **`fontSerif` graceful fallback**: SKLabelNode(fontNamed:)는 fontName 미존재 시 시스템 폰트 fallback. 크래시 0. 사용자 후속으로 GowunBatang-Regular.ttf를 Resources/Fonts + Info.plist UIAppFonts에 추가 가능.

5. **`titleLabel` vs `newBestLabel` 시각 분리**: 분기 B에서 `titleLabel`을 카드 헤더로(+70 y), `newBestLabel`을 화면 정 가운데(+0 y)로 명확 분리. 두 라벨 다 살림.

6. **`statsLabel` / `characterLabel` / `difficultyLabel` deprecated**: alpha=0 비활성, addChild 보존(노드 트리 구조 유지).

7. **`presentDiploma` 카드 위 덮음**: 졸업장 zPosition 300으로 카드(-5)보다 위. 분기 C에서 카드 라벨 분기 불필요 — 어차피 안 보임.

---

## OPEN_QUESTION

### Q1. 우드컷 패턴 구현 방식
**선택**: (A) ✅ **단일 SKShapeNode + CGMutablePath 도트 1100개 누적** (디폴트). 시뮬레이터 안전, 학습 난이도 낮음, 노드 수 1.

대안 (B) SKShader, (C) PNG 텍스처는 자산/학습 난이도 이슈로 보류. 사용자가 시각 만족 안 되면 후속 작업 가능.

### Q2. GowunBatang-Regular.ttf 임포트
**Sprint 5 코드 측 대응**: `GameConfig.fontSerif = "GowunBatang-Regular"` 상수만 추가. SKLabelNode fallback 안전.

**사용자 후속 작업**:
1. https://fonts.google.com/specimen/Gowun+Batang ttf 다운로드
2. `Resources/Fonts/GowunBatang-Regular.ttf` 추가
3. Xcode add to target + Info.plist UIAppFonts 배열에 추가

Sprint 5 평가 시 ttf 부재여도 합격 가능.

### Q3. 분기 B `titleLabel` vs `newBestLabel`
**선택**: (A) ✅ **두 라벨 다 살림** — y 분리. `titleLabel` 카드 헤더(+70 골드), `newBestLabel` 화면 정 가운데(+0 큰 황금). 기존 `revealNewBest` 시퀀스 보존.

---

**SPEC 작성 완료**. Generator는 이 SPEC을 그대로 구현하면 분기 3개 시각이 mockup과 일치하면서 9개 init 인자/햅틱/사운드/저장/본문 텍스트/2단계 탭 한 글자도 회귀 없이 통과한다.
