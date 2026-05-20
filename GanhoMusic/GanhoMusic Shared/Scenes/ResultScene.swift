//
//  ResultScene.swift
//  GanhoMusic Shared
//
//  Phase 3-3 · 결과 화면 — GameScene의 GameOverOverlayNode 모달을 폐기하고 별도 씬으로 분리
//  Phase 3-4 · bestScore / isNewBest 주입 + bestLabel 신설 (라벨 4개 재배치)
//  Phase 3-5 · GameStats 주입 + statsLabel 신설 (라벨 5개 재배치, "PLAYS N / TOTAL N")
//  Phase 5-7 · 캐릭터 이름 라벨 추가 (init 6번째 인자 characterName)
//  Phase 6-15 · 신기록 시 "NEW BEST!" 황금 라벨 + heavy 햅틱 + NewMail 사운드 + bestLabel 황금 깜빡임
//  Phase 7-1 · 난이도 라벨 1줄 추가 (init 7번째 인자 difficulty)
//  Phase 8-4 · 원본 #overlayEnd 종료 패널 시각 동일화 — 반투명 배경 + 380 카드 패널 + 라벨 색·크기 토큰 갈아 끼움
//  Sprint 5 · 3분기 v2 리스킨 — 따뜻한 그라데이션 + 80% 화이트 카드 + 분기별 시각(일반/신기록/졸업장) + 신기록 sparkle 5발
//

import SpriteKit

/// 게임 종료 후 결과를 보여주는 독립 씬.
/// `finalScore`/`bestScore`/`isNewBest`는 init 주입으로 박혀(`let`) 변조 불가.
/// 신기록이면 "✨ NEW BEST! ✨", 아니면 "실습 종료"으로 분기 표시 (Sprint 5 v2).
/// 표시 후 탭 1회 → StartScene fade.
/// TitleScene과 동일한 라벨/팩토리/터치 패턴을 답습.
final class ResultScene: SKScene {

    // MARK: - Properties
    /// init 주입된 최종 점수. 불변.
    private let finalScore: Int
    /// init 주입된 최고 점수(record 후 기준). 불변.
    private let bestScore: Int
    /// 이번 점수가 신기록을 갱신했는지. 불변.
    private let isNewBest: Bool
    /// Phase 3-5 — init 주입된 누적 통계(이번 판 반영 후 값). 불변.
    private let stats: GameStats
    /// Phase 5-7 — init 주입된 캐릭터 한국어 이름. 불변. characterLabel.text 합성에만 사용.
    /// String만 받음 — CharacterID enum 결합도 차단(HUDNode 5-4와 동형).
    private let characterName: String
    /// Phase 7-1 — init 주입된 난이도. 불변. difficultyLabel.text 합성에만 사용.
    /// String이 아닌 Difficulty enum을 직접 받음 — displayName 매핑이 단일 진실 원천(Difficulty enum).
    private let difficulty: Difficulty
    /// Phase 7-4 — 이번 판에서 *최초* 졸업이 성사됐는지(GraduationRepository.record 반환값).
    /// true일 때만 setupLabels 끝에서 졸업장 자동 표시. default false로 기존 호출부 회귀 0.
    private let isNewGraduation: Bool
    /// Phase 7-4 — 졸업 일시(Optional). 졸업 안 한 캐릭터는 nil. presentDiploma의 `if let` 가드와 짝.
    private let graduatedAt: Date?
    /// StartScene 복귀 중복 진입 가드.
    private var isTransitioning = false

    // 기존 라벨 6개(Phase 3-3 ~ Phase 7-1) — Sprint 5에서도 *생성*하되 일부는 alpha=0으로 비활성화.
    private let titleLabel  = SKLabelNode(text: "GAME OVER")
    private let scoreLabel  = SKLabelNode(text: "♪ 0")
    private let bestLabel   = SKLabelNode(text: "BEST 🏆 0")
    private let statsLabel  = SKLabelNode(text: "PLAYS 0  /  TOTAL 0")
    /// Phase 5-7 — title(+80) 위쪽에 표시되는 캐릭터 라벨. Sprint 5에서 alpha=0(headerChip이 대체).
    private let characterLabel = SKLabelNode(text: "")
    /// Phase 7-1 — characterLabel(+115) 위쪽에 표시되는 난이도 라벨. Sprint 5에서 alpha=0(headerChip이 대체).
    private let difficultyLabel = SKLabelNode(text: "")
    private let promptLabel = SKLabelNode(text: "TAP TO RETURN")
    /// Phase 6-15 — 신기록 시 화면 정중앙에 등장하는 황금 라벨. isNewBest일 때만 addChild.
    private let newBestLabel = SKLabelNode(text: "NEW BEST!")

    // Sprint 5 신규 자식 노드
    /// 부제 라벨. 분기 A: "수고했어요! 한 번 더 해볼까요?" / 분기 B: "최고 기록을 갱신했어요!"
    private let subtitleLabel = SKLabelNode(text: "")
    /// 점수 부제. 분기 A: "SCORE" / 분기 B: "NEW SCORE"
    private let scoreSubLabel = SKLabelNode(text: "SCORE")
    /// divider 라인 (가로 카드 폭 60% navy 알파 0.18).
    private let divider = SKShapeNode()
    /// PLAYS 숫자.
    private let playsValueLabel = SKLabelNode(text: "")
    /// "PLAYS" 라벨.
    private let playsTitleLabel = SKLabelNode(text: "PLAYS")
    /// TOTAL 숫자.
    private let totalValueLabel = SKLabelNode(text: "")
    /// "TOTAL" 라벨.
    private let totalTitleLabel = SKLabelNode(text: "TOTAL")
    /// 공유 GlassPill. 분기별 텍스트 분기.
    private var shareButton: GlassPillNode?
    /// 다시 시작 PrimaryButton.
    private let restartButton = PrimaryButtonNode(text: "다시 시작")
    /// Sprint 7 Phase D — scoreLabel("0") 좌측에 떨어진 작은 ♪ 아이콘(24pt).
    /// V2에서 scoreLabel.text가 "♪ \(finalScore)"였지만, V3에서 ♪는 *분리된 노드*가 담당해
    /// 점수 숫자만 거대하게 보이게 한다. scoreLabel.text는 "\(finalScore)"로 갱신.
    private let scoreNoteIconLabel = SKLabelNode(text: "♪")
    /// Sprint 7 Phase D — "📊 기록 보기" GlassPill. 탭 → ScoreboardScene 전이.
    /// shareButton 좌측에 배치. 옵셔널 — didMove 전엔 nil.
    private var scoreboardButton: GlassPillNode?
    /// Sprint 7 Phase D — bestLabel 시각 대체 GlassPill. scoreLabel 우측 +120pt 위치.
    /// bestLabel은 `.alpha = 0`으로 시각 차단(노드 트리 보존) + bestPill이 시각 담당.
    /// 옵셔널 — didMove 전엔 nil.
    private var bestPill: GlassPillNode?
    /// 헤더 DarkContextChip — "중 난이도 · 건간호" 한 줄 통합.
    private var headerChip: DarkContextChipNode?
    /// AccentLine 카드 상단 액센트.
    private let accentLine = AccentLineNode()
    /// 따뜻한 3-stop 그라데이션 배경 (배경 검정 사각형 *교체*).
    private var gradientBg: GradientBackgroundNode?

    /// Phase 6-15 — 신기록 진입 시 heavy 햅틱 발화 (도달의 무게감).
    private let haptics = HapticsManager()
    /// Phase 6-15 — 신기록 진입 시 NewMail 사운드 발화 (긍정·묵직).
    private let audio = AudioManager()

    // MARK: - Factory
    /// 점수/최고 점수/신기록 여부/누적 통계를 주입받아 ResultScene 인스턴스 생성. .resizeFill로 view 크기에 자동 맞춤.
    /// 외부에서는 반드시 이 팩토리만 사용 — `private init` 으로 직접 호출 차단.
    /// Phase 3-5 — `stats: GameStats` 인자 추가.
    /// Phase 5-7 — `characterName: String` 인자 추가.
    /// Phase 7-1 — `difficulty: Difficulty` 인자 추가.
    /// Phase 7-4 — `isNewGraduation` / `graduatedAt` default 인자 2개 추가.
    /// 두 인자 모두 default(false, nil) — 기존 호출부 회귀 0. 졸업장 자동 표시는 두 인자 모두 명시될 때만.
    class func newResultScene(
        score: Int,
        bestScore: Int,
        isNewBest: Bool,
        stats: GameStats,
        characterName: String,
        difficulty: Difficulty,
        isNewGraduation: Bool = false,
        graduatedAt: Date? = nil
    ) -> ResultScene {
        let scene = ResultScene(
            size: CGSize(width: 1024, height: 768),
            score: score,
            bestScore: bestScore,
            isNewBest: isNewBest,
            stats: stats,
            characterName: characterName,
            difficulty: difficulty,
            isNewGraduation: isNewGraduation,
            graduatedAt: graduatedAt
        )
        scene.scaleMode = .resizeFill
        return scene
    }

    // MARK: - Init
    /// 9개 인자 모두 `let` 이므로 `super.init` 전에 저장.
    /// Phase 5-7 — `characterName` 6번째 인자.
    /// Phase 7-1 — `difficulty` 7번째 인자.
    /// Phase 7-4 — `isNewGraduation` 8번째, `graduatedAt` 9번째 인자.
    private init(
        size: CGSize,
        score: Int,
        bestScore: Int,
        isNewBest: Bool,
        stats: GameStats,
        characterName: String,
        difficulty: Difficulty,
        isNewGraduation: Bool,
        graduatedAt: Date?
    ) {
        self.finalScore = score
        self.bestScore = bestScore
        self.isNewBest = isNewBest
        self.stats = stats
        self.characterName = characterName
        self.difficulty = difficulty
        self.isNewGraduation = isNewGraduation
        self.graduatedAt = graduatedAt
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        // Sprint 5 — 그라데이션 배경이 담당. 기존 backgroundColor는 fallback으로 clear.
        backgroundColor = .clear
        setupBackgroundGradient()                       // Sprint 5 — 3-stop 따뜻한 그라데이션
        setupOverlayPanel()                             // Phase 8-4 — 카드 패널 (Sprint 5에서 v2 토큰으로 갈아 끼움)
        setupLabels()
    }

    /// scene.size 변경 시(회전·resize) 라벨 위치 재계산. 자식 추가는 setupLabels에서만.
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutLabels()
    }

    // MARK: - Setup

    /// Sprint 5 — 3-stop 따뜻한 그라데이션 배경. 기존 검정 반투명 사각형(zPosition=-10) *교체*.
    /// `GradientBackgroundNode.threeStop` 정적 팩토리 호출 — Sprint 1 인프라 재사용, 신규 노드 0건.
    private func setupBackgroundGradient() {
        let gradient = GradientBackgroundNode.threeStop(
            size: size,
            topColor: .ganhoBgWarmTop,
            midColor: .ganhoBgWarmMid,
            bottomColor: .ganhoBgWarmBottom
        )
        gradient.position = CGPoint(x: frame.midX, y: frame.midY)
        gradient.zPosition = -20    // setupOverlayPanel의 bg(zPosition=-10) 아래
        gradient.name = "resultGradientBg"
        gradientBg = gradient
        addChild(gradient)
    }

    /// Phase 8-4 — 원본 웹게임 `#overlayEnd .game-overlay__panel--end` 톤 재현.
    /// Sprint 5 — bg(어두운 반투명) alpha=0 (그라데이션이 배경 담당) + panel 색 토큰 v2로 교체.
    /// 라벨 layout은 *미접촉* — Phase 7-1(+155) ~ Phase 3-3(-80) 모두 패널 안에 자연 배치.
    private func setupOverlayPanel() {
        // 1) 화면 전체 반투명 검정 배경 — Sprint 5에서 alpha=0 (그라데이션이 대신 배경 담당).
        let bg = SKSpriteNode(color: .ganhoUIOverlayBg, size: size)
        bg.position = CGPoint(x: frame.midX, y: frame.midY)
        bg.zPosition = -10
        bg.alpha = 0
        bg.name = "overlayBackground"
        addChild(bg)

        // 2) 가운데 카드 패널 — Sprint 5 v2 토큰. 화이트 0.88 + cornerRadius 22 + stroke clear.
        let panel = SKShapeNode(
            rectOf: CGSize(
                width: GameConfig.resultPanelMaxWidth,
                height: GameConfig.resultPanelHeight
            ),
            cornerRadius: GameConfig.resultCardCornerRadiusV2
        )
        panel.fillColor = UIColor.white.withAlphaComponent(0.88)
        panel.strokeColor = .clear
        panel.lineWidth = 0
        panel.position = CGPoint(x: frame.midX, y: frame.midY)
        panel.zPosition = -5
        panel.name = "overlayPanel"
        addChild(panel)
    }

    private func setupLabels() {
        // Phase 3-3 ~ Phase 8-4 — 기존 6개 라벨 *부착 자체*는 유지(노드 트리 구조 보존).
        // Sprint 5: 일부 라벨은 alpha=0 비활성, 일부는 v2 토큰으로 시각 교체.
        configureLabel(titleLabel,      fontSize: GameConfig.resultTitleFontSize)
        configureLabel(scoreLabel,      fontSize: GameConfig.resultScoreFontSize)
        configureLabel(bestLabel,       fontSize: GameConfig.resultBestFontSize)
        configureLabel(statsLabel,      fontSize: GameConfig.resultStatsFontSize)
        configureLabel(characterLabel,  fontSize: GameConfig.resultCharacterFontSize)
        configureLabel(difficultyLabel, fontSize: GameConfig.resultDifficultyFontSize)
        configureLabel(promptLabel,     fontSize: GameConfig.resultPromptFontSize)

        // Sprint 5 — characterLabel·difficultyLabel·statsLabel·promptLabel은 *headerChip + stat group + 카드 톤*이 대체.
        // alpha=0으로 자식 트리 구조는 유지(addChild 후속 보존), 시각만 차단.
        characterLabel.alpha = 0
        difficultyLabel.alpha = 0
        statsLabel.alpha = 0
        promptLabel.alpha = 0

        // Sprint 7 Phase D — bestLabel은 *V3 bestPill*이 시각 대체. alpha=0으로 차단(노드 트리 보존).
        // startBestLabelGoldBlink 액션이 0.5↔1.0 깜빡여도 bestLabel 위치(-60)는 V3에서 *비어 있는* 자리라
        // 우상단 bestPill의 명확성에 영향 0. NewBest sparkle/heavy/사운드는 byte-identical 유지.
        bestLabel.alpha = 0

        // 분기별 시각 토큰 — titleLabel / scoreLabel / bestLabel은 분기 결과 *덮어쓰기* 한 줄로 정리.
        configureTitleLabelV2()
        configureScoreLabelV2()
        configureBestLabelV2()
        configureScoreSubLabelV2()
        configureSubtitleLabelV2()
        configureDivider()

        // 데이터 합성.
        // Sprint 7 Phase D — scoreLabel은 *숫자만*. ♪는 scoreNoteIconLabel(24pt)이 좌측에서 담당.
        // configureScoreLabelV2()에서 "♪ \(finalScore)"로 세팅했지만 V3에서는 *숫자만* 덮어쓴다.
        scoreLabel.text = "\(finalScore)"
        bestLabel.text = isNewBest ? "★ NEW BEST! ★" : "🏆 BEST \(bestScore)"
        statsLabel.text = "PLAYS \(stats.playCount)  /  TOTAL \(stats.totalScore)"
        characterLabel.text = "🎮 \(characterName)"
        difficultyLabel.text = "난이도: \(difficulty.displayName)"

        // 자식 부착 — *Phase 8-4 시점 6 라벨 부착 순서 유지*. 신규 자식은 그 뒤에 추가.
        addChild(titleLabel)
        addChild(scoreLabel)
        addChild(bestLabel)
        addChild(statsLabel)
        addChild(characterLabel)
        addChild(difficultyLabel)
        addChild(promptLabel)

        // Sprint 5 신규 자식 부착 — headerChip + AccentLine + 부제 + 스코어 부제 + divider + stat 4라벨 + 버튼 2개.
        accentLine.zPosition = 5
        addChild(accentLine)

        let chip = DarkContextChipNode(
            label: "\(difficulty.shortName) 난이도 · \(characterName)",
            badge: nil
        )
        chip.zPosition = 6
        headerChip = chip
        addChild(chip)

        addChild(subtitleLabel)
        addChild(scoreSubLabel)
        addChild(divider)
        setupStats()
        setupButtons()

        // Sprint 7 Phase D — V3 신규 자식 3개 (♪ 좌측 아이콘 / BEST GlassPill / 기록 보기 GlassPill).
        setupScoreNoteIcon()
        setupBestPill()
        setupScoreboardButton()

        layoutLabels()

        // Phase 6-15 — 신기록일 때만 NewBest 시퀀스 시작. 기존 호출 위치/순서 그대로.
        if isNewBest {
            configureNewBestLabel()
            scheduleNewBestReveal()
        }
        // Phase 7-4 — 최초 졸업 시 졸업장 자동 표시. 기존 가드/호출 시퀀스 그대로.
        if isNewGraduation, let graduatedAt = graduatedAt {
            presentDiploma(at: graduatedAt)
        }
    }

    /// 6개 라벨 공통 스타일(기존). 부착 자체는 유지하고 v2 토큰은 별도 configureLabelV2에서 덮어쓴다.
    private func configureLabel(_ label: SKLabelNode, fontSize: CGFloat) {
        label.fontSize = fontSize
        label.fontColor = .ganhoPaper
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.alpha = GameConfig.hudAlpha
    }

    /// Sprint 5 — v2 라벨 공통 스타일 헬퍼. fontName/fontSize/fontColor/alignment 동시 적용.
    private func configureLabelV2(
        _ label: SKLabelNode,
        text: String,
        fontName: String,
        fontSize: CGFloat,
        fontColor: UIColor
    ) {
        label.text = text
        label.fontName = fontName
        label.fontSize = fontSize
        label.fontColor = fontColor
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.alpha = 1
    }

    /// Sprint 5 — titleLabel v2 토큰. 분기 A(navyDeep "실습 종료") / B(gold "✨ NEW BEST! ✨").
    /// 분기 B에서는 *fontColor만* 골드로 — 기존 fontColor 분기와 동거.
    private func configureTitleLabelV2() {
        let titleText: String
        let titleColor: UIColor
        if isNewBest {
            titleText = "✨ NEW BEST! ✨"
            titleColor = .ganhoMusicGold
        } else {
            titleText = "실습 종료"
            titleColor = .ganhoNavyDeep
        }
        configureLabelV2(
            titleLabel,
            text: titleText,
            fontName: GameConfig.fontDisplay,
            fontSize: GameConfig.resultTitleFontSizeV2,
            fontColor: titleColor
        )
    }

    /// Sprint 5 — scoreLabel v2 토큰. 분기 A(coralPrimary) / B(gold).
    private func configureScoreLabelV2() {
        let color: UIColor = isNewBest ? .ganhoMusicGold : .ganhoCoralPrimary
        configureLabelV2(
            scoreLabel,
            text: "♪ \(finalScore)",
            fontName: GameConfig.fontDisplay,
            fontSize: GameConfig.resultScoreNumFontSizeV2,
            fontColor: color
        )
    }

    /// Sprint 5 — bestLabel v2 토큰. 폰트 13 골드 톤. revealNewBest에서 깜빡임 시작(분기 B 시).
    private func configureBestLabelV2() {
        configureLabelV2(
            bestLabel,
            text: isNewBest ? "★ NEW BEST! ★" : "🏆 BEST \(bestScore)",
            fontName: GameConfig.fontDisplay,
            fontSize: GameConfig.resultBestFontSizeV2,
            fontColor: .ganhoMusicGold
        )
    }

    /// Sprint 5 — scoreSubLabel v2 토큰. 분기 A("SCORE") / B("NEW SCORE") navyMuted.
    private func configureScoreSubLabelV2() {
        configureLabelV2(
            scoreSubLabel,
            text: isNewBest ? "NEW SCORE" : "SCORE",
            fontName: GameConfig.fontBody,
            fontSize: GameConfig.resultStatTitleFontSizeV2,
            fontColor: .ganhoNavyMuted
        )
    }

    /// Sprint 5 — subtitleLabel v2 토큰. 분기 A("수고했어요! 한 번 더 해볼까요?") / B("최고 기록을 갱신했어요!").
    private func configureSubtitleLabelV2() {
        let subtitle = isNewBest
            ? "최고 기록을 갱신했어요!"
            : "수고했어요! 한 번 더 해볼까요?"
        configureLabelV2(
            subtitleLabel,
            text: subtitle,
            fontName: GameConfig.fontBody,
            fontSize: GameConfig.resultSubtitleFontSizeV2,
            fontColor: .ganhoNavyMuted
        )
    }

    /// divider — 가로 선 SKShapeNode. 카드 폭 60% navyDeep α=0.18.
    private func configureDivider() {
        let dividerWidth = GameConfig.resultPanelMaxWidth * GameConfig.resultDividerWidthRatioV2
        let dividerHeight: CGFloat = 1
        divider.path = CGPath(
            rect: CGRect(
                x: -dividerWidth / 2,
                y: -dividerHeight / 2,
                width: dividerWidth,
                height: dividerHeight
            ),
            transform: nil
        )
        divider.fillColor = UIColor.ganhoNavyDeep.withAlphaComponent(0.18)
        divider.strokeColor = .clear
        divider.lineWidth = 0
        divider.name = "resultDivider"
        divider.zPosition = 4
    }

    /// Sprint 5 — stat 4라벨(PLAYS 숫자/제목 · TOTAL 숫자/제목) 부착.
    private func setupStats() {
        configureLabelV2(
            playsValueLabel,
            text: "\(stats.playCount)",
            fontName: GameConfig.fontDisplay,
            fontSize: GameConfig.resultStatValueFontSizeV2,
            fontColor: .ganhoNavyDeep
        )
        configureLabelV2(
            playsTitleLabel,
            text: "PLAYS",
            fontName: GameConfig.fontBody,
            fontSize: GameConfig.resultStatTitleFontSizeV2,
            fontColor: .ganhoNavyMuted
        )
        configureLabelV2(
            totalValueLabel,
            text: "\(stats.totalScore)",
            fontName: GameConfig.fontDisplay,
            fontSize: GameConfig.resultStatValueFontSizeV2,
            fontColor: .ganhoNavyDeep
        )
        configureLabelV2(
            totalTitleLabel,
            text: "TOTAL",
            fontName: GameConfig.fontBody,
            fontSize: GameConfig.resultStatTitleFontSizeV2,
            fontColor: .ganhoNavyMuted
        )
        addChild(playsValueLabel)
        addChild(playsTitleLabel)
        addChild(totalValueLabel)
        addChild(totalTitleLabel)
    }

    /// Sprint 5 — 공유 GlassPill + 다시시작 PrimaryButton 부착.
    /// shareButton 텍스트는 분기 A("📤 공유") / B("📤 자랑하기")로 분기.
    private func setupButtons() {
        let shareText = isNewBest ? "📤 자랑하기" : "📤 공유"
        let share = GlassPillNode(
            text: shareText,
            size: CGSize(
                width: GameConfig.resultShareButtonWidthV2,
                height: GameConfig.resultShareButtonHeightV2
            )
        )
        share.zPosition = 10
        share.name = "shareButton"
        shareButton = share
        addChild(share)

        restartButton.zPosition = 10
        restartButton.name = "restartButton"
        addChild(restartButton)
    }

    // MARK: - Setup (Sprint 7 Phase D · V3 신규 자식 3개)

    /// V3 — scoreLabel 좌측에 분리된 ♪ 24pt 아이콘. fontColor는 분기 A 코랄 / 분기 B 골드(scoreLabel과 톤 동기화).
    /// 라벨 자체 위치는 layoutLabels()에서 scoreLabel.position + offset으로 계산.
    private func setupScoreNoteIcon() {
        scoreNoteIconLabel.fontName = GameConfig.fontDisplay
        scoreNoteIconLabel.fontSize = GameConfig.resultScoreNoteIconFontSizeV3
        scoreNoteIconLabel.fontColor = isNewBest ? .ganhoMusicGold : .ganhoCoralPrimary
        scoreNoteIconLabel.horizontalAlignmentMode = .center
        scoreNoteIconLabel.verticalAlignmentMode = .center
        scoreNoteIconLabel.zPosition = 6
        scoreNoteIconLabel.name = "scoreNoteIcon"
        addChild(scoreNoteIconLabel)
    }

    /// V3 — bestLabel 시각 대체 GlassPill. 점수 우측 +120pt 위치에 nestled.
    /// 텍스트는 분기 A("🏆 BEST 24") / 분기 B("★ NEW BEST!"). GlassPill 자체 fontColor는 navyDeep(기본) 유지.
    private func setupBestPill() {
        let text: String
        if isNewBest {
            text = GameConfig.resultBestPillTextNewV3
        } else {
            text = "\(GameConfig.resultBestPillTextNormalV3) \(bestScore)"
        }
        let pill = GlassPillNode(
            text: text,
            size: CGSize(
                width: GameConfig.resultBestPillWidthV3,
                height: GameConfig.resultBestPillHeightV3
            )
        )
        pill.zPosition = 11
        pill.name = "bestPill"
        bestPill = pill
        addChild(pill)
    }

    /// V3 — "📊 기록 보기" GlassPill. shareButton 좌측에 배치. 탭 시 ScoreboardScene 전이.
    /// touchesBegan에서 contains(location) hit-test.
    private func setupScoreboardButton() {
        let pill = GlassPillNode(
            text: GameConfig.resultScoreboardButtonText,
            size: CGSize(
                width: GameConfig.resultScoreboardButtonWidthV3,
                height: GameConfig.resultShareButtonHeightV2
            )
        )
        pill.zPosition = 10
        pill.name = "scoreboardButton"
        scoreboardButton = pill
        addChild(pill)
    }

    /// scene.size 기준 위치 재계산. didMove와 didChangeSize에서 공용.
    /// Sprint 5 — 신규 v2 자식 위치 추가. 기존 라벨은 alpha=0이지만 layout은 유지(보호 가드).
    private func layoutLabels() {
        // 기존 라벨 위치(레거시) — alpha=0이어도 노드 트리 보존.
        titleLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultTitleOffsetYV2
        )
        scoreLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultScoreOffsetYV4
        )
        bestLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultBestOffsetYV2
        )
        statsLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultStatsOffsetY
        )
        characterLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultCharacterOffsetY
        )
        difficultyLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultDifficultyOffsetY
        )
        promptLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultPromptOffsetY
        )
        // Phase 6-15 — newBestLabel은 isNewBest일 때만 addChild되지만, 위치 set은 부착 여부 무관하게 안전.
        newBestLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.newBestOffsetY
        )

        // Sprint 7 Phase D — V3 신규 좌표. 기존 V2 라벨/divider 위치를 V3 offset으로 *시프트*만 한다.
        // V2 상수는 보존 — bestLabel은 alpha=0이라 위치 표시 안 되지만 노드 트리는 유지.
        accentLine.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultAccentLineOffsetYV4
        )
        headerChip?.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultHeaderChipOffsetYV4
        )
        subtitleLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultSubtitleOffsetYV4
        )
        scoreSubLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultScoreSubOffsetYV3
        )
        divider.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultDividerOffsetYV4
        )
        // Sprint 9 Phase D — stat 좌표는 divider V4 - statGap V9 상대식으로 의도 명시(위/아래 묶음 분리).
        // V3 statValueY(-98) 대비 -96 → -2pt 미세 차이, V3 statTitle pitch(-14)는 보존.
        let statValueY = GameConfig.resultDividerOffsetYV4 - GameConfig.resultStatGapFromDividerV9
        let statTitleY = statValueY - 14
        playsValueLabel.position = CGPoint(
            x: frame.midX - GameConfig.resultStatGroupSpacingXV2,
            y: frame.midY + statValueY
        )
        playsTitleLabel.position = CGPoint(
            x: frame.midX - GameConfig.resultStatGroupSpacingXV2,
            y: frame.midY + statTitleY
        )
        totalValueLabel.position = CGPoint(
            x: frame.midX + GameConfig.resultStatGroupSpacingXV2,
            y: frame.midY + statValueY
        )
        totalTitleLabel.position = CGPoint(
            x: frame.midX + GameConfig.resultStatGroupSpacingXV2,
            y: frame.midY + statTitleY
        )

        // Sprint 7 Phase D — V3 신규 자식 3개 좌표.
        // (1) scoreNoteIconLabel — scoreLabel.position 기준 -60 좌측 / y는 score row V4(+6)와 정렬.
        scoreNoteIconLabel.position = CGPoint(
            x: frame.midX + GameConfig.resultScoreNoteIconOffsetXV3,
            y: frame.midY + GameConfig.resultScoreOffsetYV4
        )
        // (2) bestPill — scoreLabel.position 기준 +120 우측 / y는 score row V4(+6)와 정렬.
        bestPill?.position = CGPoint(
            x: frame.midX + GameConfig.resultBestPillOffsetXV3,
            y: frame.midY + GameConfig.resultScoreOffsetYV4
        )
        // Sprint 7+ — safeArea.bottom 회피로 교체.
        // 기존 resultButtonOffsetYV2(-180)는 값 보존 — 다른 곳 참조 가능성.
        // frame.midY + offset 식은 디바이스에 따라 두 버튼이 잘렸다.
        let safe = SceneSafeArea.insets(for: self)
        let buttonY = frame.minY + safe.bottom + GameConfig.resultButtonBottomInset
        let shareX = frame.midX + GameConfig.resultShareButtonXOffsetV2
        shareButton?.position = CGPoint(
            x: shareX,
            y: buttonY
        )
        restartButton.position = CGPoint(
            x: frame.midX + GameConfig.resultRestartButtonXOffsetV2,
            y: buttonY
        )
        // Sprint 7 Phase D — V3 신규 "📊 기록 보기" GlassPill — shareButton 좌측 -110pt.
        scoreboardButton?.position = CGPoint(
            x: shareX + GameConfig.resultScoreboardButtonOffsetXFromShareV3,
            y: buttonY
        )

        // gradient 배경 위치 — frame.midY 기준 정중앙. size 변화 시에도 안전.
        gradientBg?.position = CGPoint(x: frame.midX, y: frame.midY)
    }

    // MARK: - Touch
    /// 화면 탭 1회 → 기록 보기 칩이면 ScoreboardScene, 그 외는 StartScene 전환.
    /// 중복 탭은 isTransitioning으로 차단. view 옵셔널은 guard let으로 안전 추출.
    /// Sprint 7 Phase D — scoreboardButton 탭 분기 추가(1탭 정책 유지 — 한 화면 안에서 한 번만 탭).
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        // Phase 7-5 — 졸업장 표시 중이면 StartScene 전환 차단. 졸업장 자체가 isUserInteractionEnabled=true로
        // 자기 터치를 흡수하므로 이 경로 도달 가능성은 낮지만 edge case 안전망.
        if children.contains(where: { $0.name == "diplomaOverlay" }) { return }
        guard let view = self.view, let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Sprint 7 Phase D — 기록 보기 GlassPill 탭 분기 → ScoreboardScene 0.4s fade.
        // ★ 마커 키: 신기록이고 캐릭터 역변환 성공한 경우만. 그 외 nil → 매트릭스에 ★ 미표시.
        // ResultReturnContext에 9-인자 전달 — 졸업장 재진입 차단을 위해 isNewGraduation은 SPEC §주의사항 3에 따라
        // ScoreboardScene.returnToResult* 단계에서 `false`로 강제 — 이 단계에서는 원본값 그대로 전달.
        if let pill = scoreboardButton, pill.contains(location) {
            isTransitioning = true
            let lastUpdatedKey: (CharacterID, Difficulty)? = {
                guard isNewBest, let charID = inferredCharacterID else { return nil }
                return (charID, difficulty)
            }()
            let ctx = ResultReturnContext(
                finalScore: finalScore,
                bestScore: bestScore,
                isNewBest: isNewBest,
                stats: stats,
                characterName: characterName,
                difficulty: difficulty,
                isNewGraduation: isNewGraduation,
                graduatedAt: graduatedAt
            )
            let scoreboard = ScoreboardScene.newScoreboardScene(
                lastUpdatedKey: lastUpdatedKey,
                returnContext: ctx
            )
            let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
            view.presentScene(scoreboard, transition: fade)
            return
        }

        isTransitioning = true
        // Phase 10-1c — TitleScene 삭제 + StartScene 신설 따른 *필수 연동 변경* (1줄).
        // SPEC.md "ResultScene 0줄 변경" 정책은 *내부 로직* 보존 의도 — 외부 신호(타이틀 씬 진입점) 갱신은 회귀 0.
        let startScene = StartScene.newStartScene()
        let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
        view.presentScene(startScene, transition: fade)
    }

    // MARK: - Helpers (Sprint 7 Phase D)

    /// characterName(한글) → CharacterID 역변환. allCases.first {$0.displayName == characterName}.
    /// 5명의 displayName이 모두 유일하므로 안전. 매칭 실패 시 nil 반환 — ★ 마커 미표시.
    /// ResultScene.init 9-인자 시그니처를 *그대로 보존*하기 위한 우회 — characterID는 인자가 아니므로
    /// characterName으로부터 역추론한다(SPEC §OQ-3).
    private var inferredCharacterID: CharacterID? {
        return CharacterID.allCases.first { $0.displayName == characterName }
    }

    // MARK: - New Best (Phase 6-15)

    /// 신기록 진입 시점에만 발화. setupLabels() 끝에서 isNewBest 분기로 호출됨.
    /// 라벨 스타일(font/color/alpha=0)을 미리 설정만 하고, 등장은 scheduleNewBestReveal이 담당.
    private func configureNewBestLabel() {
        newBestLabel.fontSize = GameConfig.newBestFontSize
        newBestLabel.fontColor = .ganhoYellowF      // 황금 — ComboPopup x10 황금기와 동일 톤
        newBestLabel.horizontalAlignmentMode = .center
        newBestLabel.verticalAlignmentMode = .center
        newBestLabel.alpha = 0                      // fade-in 시작점
        newBestLabel.zPosition = GameConfig.newBestZPosition  // bestLabel 위로 겹침
        newBestLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.newBestOffsetY
        )
        addChild(newBestLabel)
    }

    /// SKScene 자체에 SKAction 부착 — Timer/DispatchQueue 사용 금지(Swift 규칙 9).
    /// [weak self] 캡처 — 씬 해제 가능성 대비.
    private func scheduleNewBestReveal() {
        let wait = SKAction.wait(forDuration: GameConfig.newBestRevealDelay)
        let reveal = SKAction.run { [weak self] in
            self?.revealNewBest()
        }
        run(.sequence([wait, reveal]))
    }

    /// 0.3초 지연 후 호출. 시각 등장 + 햅틱 + 사운드 + bestLabel 황금 전환을 한 묶음으로 발화.
    /// newBestLabel은 ResultScene 자체와 함께 정리됨 — 씬 해제 시 ARC가 처리(자가 소멸 노드와 달리 명시적 cleanup 불필요).
    private func revealNewBest() {
        // 1) 촉각: heavy = 도달의 무게감. ResultScene 새 인스턴스라 endGame heavy와 톤 충돌 없음.
        haptics.heavy()
        // 2) 청각: NewMail 1025 — 긍정·묵직. 6-11/6-13 재사용으로 신규 SFX 0건.
        audio.play(.comboMilestoneStrong)
        // 3) 시각: fade-in + scale pulse. group으로 동시 실행.
        let fadeIn = SKAction.fadeIn(withDuration: GameConfig.newBestFadeInDuration)
        let scaleUp = SKAction.scale(
            to: GameConfig.newBestEndScalePeak,
            duration: GameConfig.newBestScalePulseDuration / 2
        )
        let scaleDown = SKAction.scale(
            to: 1.0,
            duration: GameConfig.newBestScalePulseDuration / 2
        )
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        newBestLabel.run(SKAction.group([fadeIn, pulse]))
        // 4) bestLabel 황금 전환 + 깜빡임 시작
        startBestLabelGoldBlink()
        // 5) Sprint 5 — sparkle 5발 부착 (마지막 라인 추가). 기존 시퀀스 보존.
        emitSparkleBurst()
    }

    /// bestLabel을 황금으로 전환 + alpha 깜빡임 무한 반복.
    /// withKey 패턴(6-14 tensionBlink 답습) — 같은 키 재호출 시 자동 교체로 자연 멱등.
    /// 씬 해제 시 ARC가 액션 정리하므로 명시적 stop 불필요.
    private func startBestLabelGoldBlink() {
        bestLabel.fontColor = .ganhoYellowF   // 황금 색 즉시 전환 (fontColor 직접 교체)
        let fadeOut = SKAction.fadeAlpha(
            to: GameConfig.newBestBlinkMinAlpha,
            duration: GameConfig.newBestBlinkHalfPeriod
        )
        let fadeIn = SKAction.fadeAlpha(
            to: 1.0,
            duration: GameConfig.newBestBlinkHalfPeriod
        )
        let cycle = SKAction.sequence([fadeOut, fadeIn])
        bestLabel.run(.repeatForever(cycle), withKey: GameConfig.newBestBlinkActionKey)
    }

    /// Sprint 5 — 신기록 시 카드 주변 5개 좌표에 SparkleEffectNode 부착 + emit().
    /// 기존 SparkleEffectNode(자가 소멸 4호) 그대로 재활용 — 내부 0건 변경. addChild 좌표/zPosition만 다름.
    /// 5개 자식은 각자 0.5초 후 자가 소멸 → ResultScene은 후속 정리 0건.
    private func emitSparkleBurst() {
        for offset in GameConfig.resultSparklePositionsV2 {
            let sparkle = SparkleEffectNode()
            sparkle.position = CGPoint(
                x: frame.midX + offset.x,
                y: frame.midY + offset.y
            )
            sparkle.zPosition = GameConfig.newBestZPosition + 1
            addChild(sparkle)
            sparkle.emit()
        }
    }

    // MARK: - Diploma (Phase 7-4)
    /// 최초 졸업 시점에만 호출 (setupLabels 끝 가드 통과). DiplomaOverlayNode 정적 팩토리로 부착.
    /// parent = self (ResultScene), anchor = `(frame.midX, frame.midY)` — cameraNode 없는 ResultScene에 맞춤.
    /// onDismiss = 빈 클로저 — 졸업장 닫기 후 ResultScene 그대로 노출(*두 단계 탭* 정책: 졸업장 1탭 + StartScene 1탭).
    /// DiplomaOverlayNode가 자가 소멸하므로 ResultScene은 후속 정리 0건.
    private func presentDiploma(at graduatedAt: Date) {
        // Phase 7-5 — anchor를 sceneSize 기준으로 변경. ResultScene은 .resizeFill + size 1024x768 고정.
        // frame은 view 크기에 따라 동적이라 sceneSize와 불일치 → 작은 화면에서 졸업장 좌표 어긋남.
        // background가 sceneSize 크기이므로 anchor도 *같은 기준*이어야 정렬.
        DiplomaOverlayNode.present(
            characterName: characterName,
            graduatedAt: graduatedAt,
            parent: self,
            sceneSize: size,
            anchor: CGPoint(x: size.width / 2, y: size.height / 2),
            onDismiss: {}
        )
    }
}
