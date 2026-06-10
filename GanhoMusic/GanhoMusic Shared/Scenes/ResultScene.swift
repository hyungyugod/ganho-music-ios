//
//  ResultScene.swift
//  GanhoMusic Shared
//
//  게임 종료 후 점수, 최고 기록, 누적 기록, 재시작/기록 버튼을 보여주는 결과 화면.
//  저장·졸업장 분기 값은 init으로 주입받고, 화면 탭으로 다음 씬을 결정한다.
//

import SpriteKit
#if os(iOS)
import UIKit
#endif

private enum GoalJudgement {
    case achieved
    case near
    case retry

    static func make(score: Int, target: Int) -> GoalJudgement {
        if score >= target { return .achieved }
        let nearScore = Int(Double(target) * GameplayTuning.goalNearRatio)
        if score >= nearScore { return .near }
        return .retry
    }

    var title: String {
        switch self {
        case .achieved: return UILayout.resultGoalAchievedTitle
        case .near:     return UILayout.resultGoalNearTitle
        case .retry:    return UILayout.resultGoalRetryTitle
        }
    }

    var color: UIColor {
        switch self {
        case .achieved: return .ganhoMusicGold
        case .near:     return .ganhoCoralPrimary
        case .retry:    return .ganhoNavyMuted
        }
    }
}

private struct GoalLabelContent {
    /// 큰 verdict 텍스트 — "성공" / "실패". 우측 컬럼 머리글로 격상.
    let verdictText: String
    /// verdict 색 — 성공=gold / 실패=coral.
    let verdictColor: UIColor
    /// 이진 판정 결과(finalScore >= target). nextText 분기의 단일 진실 원천.
    let isSuccess: Bool
    let summaryText: String
    /// verdict 아래 한 줄. 실패=gap 문구 / 성공=격려 문구.
    let nextText: String
}

private struct ResultLayoutMetrics {
    let panelSize: CGSize
    let panelCenter: CGPoint
    let leftColumnX: CGFloat
    let rightColumnX: CGFloat
    let topY: CGFloat
    let scoreY: CGFloat
    /// V12 — BEST pill 우상단 전용 중심 x. rightColumnX에서 우측으로 보정 — 점수 컬럼과 구조적 분리.
    let bestPillX: CGFloat
    /// V12 — BEST pill 우상단 전용 중심 y. topY 바로 아래(헤더 행) — 점수(scoreY)와 겹칠 수 없음.
    let bestPillTopY: CGFloat
    /// V1 — 큰 verdict("성공"/"실패") 머리글 y. 기존 goalY 슬롯을 verdict 전용으로 재정의.
    let verdictY: CGFloat
    let summaryY: CGFloat
    let nextGoalY: CGFloat
    let statsY: CGFloat
    let scale: CGFloat
}

/// 게임 종료 후 결과를 보여주는 독립 씬.
/// `finalScore`/`bestScore`/`isNewBest`는 init 주입으로 박혀(`let`) 변조 불가.
/// 신기록이면 BEST 문구 없는 축하 title, 아니면 "실습 종료"으로 분기 표시 (Sprint 5 v2).
/// 표시 후 명시 버튼 탭으로 다음 씬 전환.
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
    /// Phase 5-7 — init 주입된 캐릭터 한국어 이름. 불변. headerChip 라벨 합성에 사용.
    /// String만 받음 — CharacterID enum 결합도 차단(HUDNode 5-4와 동형).
    private let characterName: String
    /// Phase 7-1 — init 주입된 난이도. 불변. headerChip 라벨 합성에 사용.
    /// String이 아닌 Difficulty enum을 직접 받음 — displayName 매핑이 단일 진실 원천(Difficulty enum).
    private let difficulty: Difficulty
    /// Phase 7-4 — 이번 판에서 *최초* 졸업이 성사됐는지(GraduationRepository.record 반환값).
    /// true일 때만 setupLabels 끝에서 졸업장 자동 표시. default false로 기존 호출부 회귀 0.
    private let isNewGraduation: Bool
    /// Phase 7-4 — 졸업 일시(Optional). 졸업 안 한 캐릭터는 nil. presentDiploma의 `if let` 가드와 짝.
    private let graduatedAt: Date?
    /// StartScene 복귀 중복 진입 가드.
    private var isTransitioning = false

    // live 라벨 2개 — R0에서 좀비(alpha=0 차단) 라벨 7종 삭제, titleLabel·scoreLabel만 생존.
    private let titleLabel  = SKLabelNode(text: "GAME OVER")
    private let scoreLabel  = SKLabelNode(text: "♪ 0")
    /// Phase 6-15 — 신기록 시 화면 정중앙에 등장할 수 있는 황금 보상 라벨.
    /// BEST/NEW BEST 문구는 bestPill 한 곳만 담당하므로 중앙 라벨은 별도 축하 문구만 사용한다.
    private let newBestLabel = SKLabelNode(text: "기록 갱신!")

    /// Sprint 2 — 목표 달성/근접/재도전 판정 라벨.
    private let goalJudgementLabel = SKLabelNode(text: "")
    /// Sprint 2 — 이번 판 점수와 난이도 요약 라벨.
    private let goalSummaryLabel = SKLabelNode(text: "")
    /// Sprint 2 — 다음 플레이 목표 라벨.
    private let nextGoalLabel = SKLabelNode(text: "")
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
    /// Sprint 1 — 명시적인 메인 복귀 버튼. 빈 공간 탭은 noop이다.
    private var mainButton: GlassPillNode?
    /// Sprint 7 Phase D — BEST 표시 GlassPill. 카드 우상단 위치 (V12).
    /// 옵셔널 — didMove 전엔 nil.
    private var bestPill: GlassPillNode?
    /// Sprint 4 — 공유 시트 중복 표시 방지. 시트 닫힘 completion에서만 해제한다.
    private var isShareSheetPresenting = false
    /// Sprint 4 — presenter 탐색 실패 시 ResultScene 안에서만 보여주는 실패 토스트.
    private var shareFailureToast: SKLabelNode?
    /// 헤더 DarkContextChip — "중 난이도 · 건간호" 한 줄 통합.
    private var headerChip: DarkContextChipNode?
    /// AccentLine 카드 상단 액센트.
    private let accentLine = AccentLineNode()
    private var overlayBackground: SKSpriteNode?
    private var overlayPanel: SKShapeNode?

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
        setupSolidBackground()
        setupOverlayPanel()                             // Phase 8-4 — 카드 패널 (Sprint 5에서 v2 토큰으로 갈아 끼움)
        setupLabels()
    }

    /// scene.size 변경 시(회전·resize) 라벨 위치 재계산. 자식 추가는 setupLabels에서만.
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        rebuildSolidBackground()
        layoutLabels()
    }

    // MARK: - Setup

    private func setupSolidBackground() {
        backgroundColor = Palette.menuSolidBackgroundColor
    }

    private func rebuildSolidBackground() {
        setupSolidBackground()
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
        overlayBackground = bg
        addChild(bg)

        // 2) 가운데 카드 패널 — Sprint 5 v2 토큰. 화이트 0.88 + cornerRadius 22 + stroke clear.
        let panelSize = resultPanelSize()
        let panel = SKShapeNode(
            rectOf: panelSize,
            cornerRadius: UILayout.resultCardCornerRadius
        )
        panel.fillColor = UIColor.white.withAlphaComponent(0.88)
        panel.strokeColor = .clear
        panel.lineWidth = 0
        panel.position = resultPanelCenter(panelHeight: panelSize.height)
        panel.zPosition = -5
        panel.name = "overlayPanel"
        overlayPanel = panel
        addChild(panel)
    }

    private func setupLabels() {
        configureLegacyLabels()
        configurePrimaryResultLabels()
        applyResultDataTexts()
        addLegacyLabels()
        addResultChromeNodes()
        addResultStatNodes()
        setupButtons()
        setupScoreNoteIcon()
        setupBestPill()
        setupScoreboardButton()
        setupMainButton()
        layoutLabels()
        triggerEntryEffectsIfNeeded()
    }

    private func configureLegacyLabels() {
        // R0 — live 라벨 2개(titleLabel·scoreLabel)만 구성. 좀비 5종(best/stats/character/difficulty/prompt) 삭제.
        configureLabel(titleLabel, fontSize: UILayout.resultTitleFontSize)
        configureLabel(scoreLabel, fontSize: UILayout.resultScoreFontSize)
    }

    private func configurePrimaryResultLabels() {
        // 분기별 시각 토큰 — titleLabel / scoreLabel은 분기 결과 *덮어쓰기* 한 줄로 정리.
        configureTitleLabelV2()
        configureScoreLabelV2()
        configureGoalLabels()
        configureDivider()
    }

    private func applyResultDataTexts() {
        // 데이터 합성.
        // Sprint 7 Phase D — scoreLabel은 *숫자만*. ♪는 scoreNoteIconLabel(24pt)이 좌측에서 담당.
        // configureScoreLabelV2()에서 "♪ \(finalScore)"로 세팅했지만 V3에서는 *숫자만* 덮어쓴다.
        scoreLabel.text = "\(finalScore)"
    }

    private func addLegacyLabels() {
        // 자식 부착 — live 라벨 2개만. 신규 자식은 그 뒤에 추가.
        addChild(titleLabel)
        addChild(scoreLabel)
    }

    private func addResultChromeNodes() {
        // Sprint 5 신규 자식 부착 — headerChip + AccentLine + 목표 라벨 + divider + stat 4라벨 + 버튼 2개.
        accentLine.zPosition = 5
        addChild(accentLine)

        let chip = DarkContextChipNode(
            label: "\(difficulty.shortName) 난이도 · \(characterName)",
            badge: nil
        )
        chip.zPosition = 6
        headerChip = chip
        addChild(chip)

        addChild(goalJudgementLabel)
        addChild(goalSummaryLabel)
        addChild(nextGoalLabel)
        addChild(divider)
    }

    private func addResultStatNodes() {
        setupStats()
    }

    private func triggerEntryEffectsIfNeeded() {
        // Phase 6-15 — 신기록일 때만 NewBest 시퀀스 시작. 기존 호출 위치/순서 그대로.
        if isNewBest {
            configureNewBestLabel()
            scheduleNewBestRewardPulse()
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
        label.alpha = UILayout.hudAlpha
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

    /// Sprint 5 — titleLabel v2 토큰. BEST 문구는 bestPill만 담당한다.
    /// 분기 B에서는 *fontColor만* 골드로 — 기존 fontColor 분기와 동거.
    private func configureTitleLabelV2() {
        let titleText: String
        let titleColor: UIColor
        if isNewBest {
            titleText = "신기록 달성"
            titleColor = .ganhoMusicGold
        } else {
            titleText = "실습 종료"
            titleColor = .ganhoNavyDeep
        }
        configureLabelV2(
            titleLabel,
            text: titleText,
            fontName: Typography.fontDisplay,
            fontSize: UILayout.resultCardTitleFontSize,
            fontColor: titleColor
        )
    }

    /// Sprint 5 — scoreLabel v2 토큰. 분기 A(coralPrimary) / B(gold).
    private func configureScoreLabelV2() {
        let color: UIColor = isNewBest ? .ganhoMusicGold : .ganhoCoralPrimary
        configureLabelV2(
            scoreLabel,
            text: "♪ \(finalScore)",
            fontName: Typography.fontDisplay,
            fontSize: UILayout.resultScoreNumFontSize,
            fontColor: color
        )
    }

    /// Sprint 2 — 저장 없이 현재 점수와 난이도 목표만으로 결과 판정/요약/다음 목표를 구성한다.
    /// Verdict 격상 — goalJudgementLabel을 큰 "성공/실패"(display 폰트, resultVerdictFontSize)로 표시한다.
    private func configureGoalLabels() {
        let content = makeGoalLabelContent()
        // 큰 verdict — display 폰트 + resultVerdictFontSize. 색은 성공=gold / 실패=coral.
        configureLabelV2(
            goalJudgementLabel,
            text: content.verdictText,
            fontName: Typography.fontDisplay,
            fontSize: UILayout.resultVerdictFontSize,
            fontColor: content.verdictColor
        )
        configureLabelV2(
            goalSummaryLabel,
            text: content.summaryText,
            fontName: Typography.fontBody,
            fontSize: UILayout.resultGoalSummaryFontSize,
            fontColor: .ganhoNavyMuted
        )
        configureLabelV2(
            nextGoalLabel,
            text: content.nextText,
            fontName: Typography.fontBody,
            fontSize: UILayout.resultGoalSummaryFontSize,
            fontColor: .ganhoNavyMuted
        )
    }

    private func makeGoalLabelContent() -> GoalLabelContent {
        let target = difficulty.targetScore
        // 이진 판정 — verdict의 단일 진실 원천. 경계값(==)은 성공. 기존 GoalJudgement는 보존(미사용).
        let isSuccess = finalScore >= target
        let gap = max(0, target - finalScore)
        let verdictText = isSuccess
            ? UILayout.resultVerdictSuccessText
            : UILayout.resultVerdictFailureText
        let verdictColor: UIColor = isSuccess
            ? .ganhoMusicGold
            : .ganhoCoralPrimary
        // 성공=격려 문구 / 실패=부족 점수 안내.
        let nextText = isSuccess
            ? UILayout.resultVerdictSuccessSubText
            : makeFailureGapText(gap: gap)
        return GoalLabelContent(
            verdictText: verdictText,
            verdictColor: verdictColor,
            isSuccess: isSuccess,
            summaryText: "\(UILayout.resultGoalRoundPrefix) \(finalScore)\(UILayout.resultGoalPointSuffix) · \(UILayout.resultGoalTargetPrefix) \(target)\(UILayout.resultGoalPointSuffix)",
            nextText: nextText
        )
    }

    /// 실패 시 부족 점수 안내 — "{gap}점 더 모아야 해요". gap 0(이론상 성공)일 땐 isSuccess 분기로 호출되지 않는다.
    private func makeFailureGapText(gap: Int) -> String {
        return "\(gap)\(UILayout.resultGoalPointSuffix)\(UILayout.resultVerdictFailureGapSuffix)"
    }

    /// 다음 목표까지 남은 점수 안내(기존 의미 보존 — verdict 경로와 분리). 회귀 방지를 위해 그대로 둔다.
    private func makeNextGoalText(gap: Int) -> String {
        if gap == 0 {
            return UILayout.resultGoalNextComboText
        }
        return "\(UILayout.resultGoalGapPrefix) \(gap)\(UILayout.resultGoalPointSuffix)"
    }

    /// divider — 가로 선 SKShapeNode. 카드 폭 60% navyDeep α=0.18.
    private func configureDivider() {
        let scale = resultCompactScale()
        let dividerWidth = min(
            UILayout.resultWideGoalDividerWidth * scale,
            resultPanelSize().width * UILayout.resultDividerWidthRatio
        )
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
            fontName: Typography.fontDisplay,
            fontSize: UILayout.resultStatValueFontSize,
            fontColor: .ganhoNavyDeep
        )
        configureLabelV2(
            playsTitleLabel,
            text: "PLAYS",
            fontName: Typography.fontBody,
            fontSize: UILayout.resultStatTitleFontSize,
            fontColor: .ganhoNavyMuted
        )
        configureLabelV2(
            totalValueLabel,
            text: "\(stats.totalScore)",
            fontName: Typography.fontDisplay,
            fontSize: UILayout.resultStatValueFontSize,
            fontColor: .ganhoNavyDeep
        )
        configureLabelV2(
            totalTitleLabel,
            text: "TOTAL",
            fontName: Typography.fontBody,
            fontSize: UILayout.resultStatTitleFontSize,
            fontColor: .ganhoNavyMuted
        )
        // Sprint V6 — PLAYS/TOTAL 4라벨 alpha 회복(V10 0.45 → V6 0.75). "조용한 보조" → "명료한 보조" 위계.
        // configureLabelV2가 alpha=1 강제 세팅 후 *뒤*에 약화 — 단일 진실 원천.
        // divider alpha는 V10(0.7) 유지 — stat 라벨과 시각 가중치 분리.
        // V10 토큰(resultStatAlphaV10=0.45 / resultDividerAlphaV10=0.7)은 *값 byte-identical 보존*.
        playsValueLabel.alpha = UILayout.resultStatAlpha
        playsTitleLabel.alpha = UILayout.resultStatAlpha
        totalValueLabel.alpha = UILayout.resultStatAlpha
        totalTitleLabel.alpha = UILayout.resultStatAlpha
        divider.alpha = UILayout.resultDividerAlpha
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
                width: UILayout.resultShareButtonWidth,
                height: UILayout.resultShareButtonHeight
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
        scoreNoteIconLabel.fontName = Typography.fontDisplay
        scoreNoteIconLabel.fontSize = UILayout.resultScoreNoteIconFontSize
        scoreNoteIconLabel.fontColor = isNewBest ? .ganhoMusicGold : .ganhoCoralPrimary
        scoreNoteIconLabel.horizontalAlignmentMode = .center
        scoreNoteIconLabel.verticalAlignmentMode = .center
        scoreNoteIconLabel.zPosition = 6
        scoreNoteIconLabel.name = "scoreNoteIcon"
        addChild(scoreNoteIconLabel)
    }

    /// V3 — BEST 표시 GlassPill. 카드 우상단에 nestled.
    /// 텍스트는 분기 A("🏆 BEST 24") / 분기 B("★ NEW BEST!"). GlassPill 자체 fontColor는 navyDeep(기본) 유지.
    private func setupBestPill() {
        let text: String
        if isNewBest {
            text = UILayout.resultBestPillTextNew
        } else {
            text = "\(UILayout.resultBestPillTextNormal) \(bestScore)"
        }
        let pill = GlassPillNode(
            text: text,
            size: CGSize(
                width: UILayout.resultBestPillWidth,
                height: UILayout.resultBestPillHeight
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
            text: UILayout.resultScoreboardButtonText,
            size: CGSize(
                width: UILayout.resultScoreboardButtonWidth,
                height: UILayout.resultShareButtonHeight
            )
        )
        pill.zPosition = 10
        pill.name = "scoreboardButton"
        scoreboardButton = pill
        addChild(pill)
    }

    private func setupMainButton() {
        let pill = GlassPillNode(
            text: UILayout.resultMainButtonText,
            size: CGSize(
                width: UILayout.resultMainButtonWidth,
                height: UILayout.resultShareButtonHeight
            )
        )
        pill.zPosition = 10
        pill.name = "mainButton"
        mainButton = pill
        addChild(pill)
    }

    /// scene.size 기준 위치 재계산. didMove와 didChangeSize에서 공용.
    /// Sprint 5 — 신규 v2 자식 위치 추가. 기존 라벨은 alpha=0이지만 layout은 유지(보호 가드).
    private func layoutLabels() {
        let panelSize = resultPanelSize()
        let metrics = makeResultLayoutMetrics(panelSize: panelSize)
        applyResultContentScale(metrics.scale)
        configureDivider()
        layoutBackgroundAndPanel(panelSize: panelSize)
        layoutLegacyLabels()
        layoutPrimaryResultLabels(metrics: metrics)
        layoutGoalLabels(metrics: metrics)
        layoutStats(metrics: metrics)
        layoutButtons()
    }

    private func layoutBackgroundAndPanel(panelSize: CGSize) {
        overlayBackground?.size = size
        overlayBackground?.position = CGPoint(x: frame.midX, y: frame.midY)
        overlayPanel?.path = CGPath(
            roundedRect: CGRect(
                x: -panelSize.width / 2,
                y: -panelSize.height / 2,
                width: panelSize.width,
                height: panelSize.height
            ),
            cornerWidth: UILayout.resultCardCornerRadius,
            cornerHeight: UILayout.resultCardCornerRadius,
            transform: nil
        )
        overlayPanel?.position = resultPanelCenter(panelHeight: panelSize.height)
    }

    private func layoutLegacyLabels() {
        // live 라벨 2개 기본 좌표 — layoutPrimaryResultLabels가 wide surface 좌표로 재배치.
        titleLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + UILayout.resultTitleOffsetY
        )
        scoreLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + UILayout.resultScoreOffsetY
        )
        // Phase 6-15 — newBestLabel은 isNewBest일 때만 addChild되지만, 위치 set은 부착 여부 무관하게 안전.
        newBestLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + FeelTuning.newBestOffsetY
        )
    }

    private func applyResultContentScale(_ scale: CGFloat) {
        titleLabel.setScale(scale)
        scoreLabel.setScale(scale)
        scoreNoteIconLabel.setScale(scale)
        bestPill?.setScale(scale)
        headerChip?.setScale(scale)
        goalJudgementLabel.setScale(scale)
        goalSummaryLabel.setScale(scale)
        nextGoalLabel.setScale(scale)
        playsValueLabel.setScale(scale)
        playsTitleLabel.setScale(scale)
        totalValueLabel.setScale(scale)
        totalTitleLabel.setScale(scale)
    }

    private func makeResultLayoutMetrics(panelSize: CGSize) -> ResultLayoutMetrics {
        let scale = resultCompactScale()
        let center = resultPanelCenter(panelHeight: panelSize.height)
        let columnInset = UILayout.resultWideColumnInset * scale
        let columnGap = UILayout.resultWideColumnGap * scale
        let contentWidth = max(0, panelSize.width - columnInset * 2 - columnGap)
        let leftWidth = contentWidth * UILayout.resultWideScoreColumnRatio
        let rightWidth = contentWidth * UILayout.resultWideGoalColumnRatio
        let leftEdge = center.x - panelSize.width / 2 + columnInset
        let leftColumnX = leftEdge + leftWidth / 2
        let rightColumnX = leftEdge + leftWidth + columnGap + rightWidth / 2
        let topY = center.y + panelSize.height / 2 - UILayout.resultWideTopInset * scale
        let scoreY = topY - UILayout.resultWideScoreBelowTop * scale
        // V1 — verdict 큰 폰트 전용 슬롯. 기존 goalY를 verdict y로 재정의하고 아래 요소를 verdict 기준으로 내린다.
        let verdictY = topY - UILayout.resultVerdictBelowTop * scale
        let summaryY = verdictY - UILayout.resultVerdictSummaryGap * scale
        let nextGoalY = verdictY - UILayout.resultVerdictNextGoalGap * scale
        let statsY = center.y - panelSize.height / 2 + UILayout.resultWideStatsBottomInset * scale
        // V12 — BEST pill 우상단 전용 좌표. 클램프와 무관 → 점수(leftColumnX, scoreY)와 구조적으로 겹칠 수 없다.
        // 좌상단 headerChip(leftColumnX, topY)과 대칭. x는 우측 컬럼에서 더 우측으로, y는 topY 바로 아래(헤더 행).
        let bestPillX = rightColumnX + UILayout.resultBestPillTopOffsetX * scale
        let bestPillTopY = topY - UILayout.resultBestPillTopBelowTop * scale
        return ResultLayoutMetrics(
            panelSize: panelSize,
            panelCenter: center,
            leftColumnX: leftColumnX,
            rightColumnX: rightColumnX,
            topY: topY,
            scoreY: scoreY,
            bestPillX: bestPillX,
            bestPillTopY: bestPillTopY,
            verdictY: verdictY,
            summaryY: summaryY,
            nextGoalY: nextGoalY,
            statsY: statsY,
            scale: scale
        )
    }

    private func layoutPrimaryResultLabels(metrics: ResultLayoutMetrics) {
        // Sprint V7 — 왼쪽 점수 히어로 컬럼. 기존 노드는 보존하고 좌표만 wide surface에 맞춘다.
        accentLine.position = CGPoint(
            x: metrics.panelCenter.x,
            y: metrics.topY
        )
        headerChip?.position = CGPoint(
            x: metrics.leftColumnX,
            y: metrics.topY
        )
        titleLabel.position = CGPoint(
            x: metrics.leftColumnX,
            y: metrics.topY - UILayout.resultWideTitleBelowTop * metrics.scale
        )
        scoreLabel.position = CGPoint(
            x: metrics.leftColumnX,
            y: metrics.scoreY
        )
        let scoreIconOffsetX = scoreNoteIconOffsetX(scale: metrics.scale)
        scoreNoteIconLabel.position = CGPoint(
            x: metrics.leftColumnX - scoreIconOffsetX,
            y: metrics.scoreY
        )
        // V12 — BEST pill을 점수 컬럼(leftColumnX)에서 빼내 카드 우상단으로 이동.
        // 좌상단 headerChip과 대칭이며 점수(leftColumnX, scoreY)와 구조적으로 겹칠 수 없다.
        bestPill?.position = CGPoint(
            x: metrics.bestPillX,
            y: metrics.bestPillTopY
        )
    }

    private func layoutGoalLabels(metrics: ResultLayoutMetrics) {
        // 큰 verdict를 verdict 슬롯에. summary/nextGoal/divider는 verdict 아래로 충분히 내려 겹침 0.
        goalJudgementLabel.position = CGPoint(
            x: metrics.rightColumnX,
            y: metrics.verdictY
        )
        goalSummaryLabel.position = CGPoint(
            x: metrics.rightColumnX,
            y: metrics.summaryY
        )
        nextGoalLabel.position = CGPoint(
            x: metrics.rightColumnX,
            y: metrics.nextGoalY
        )
        divider.position = CGPoint(
            x: metrics.rightColumnX,
            y: metrics.verdictY - UILayout.resultVerdictDividerGap * metrics.scale
        )
    }

    private func layoutStats(metrics: ResultLayoutMetrics) {
        let statTitleY = metrics.statsY - UILayout.resultLegacyStatTitleGap * metrics.scale
        playsValueLabel.position = CGPoint(
            x: metrics.panelCenter.x - UILayout.resultWideStatSpacingX * metrics.scale,
            y: metrics.statsY
        )
        playsTitleLabel.position = CGPoint(
            x: metrics.panelCenter.x - UILayout.resultWideStatSpacingX * metrics.scale,
            y: statTitleY
        )
        totalValueLabel.position = CGPoint(
            x: metrics.panelCenter.x + UILayout.resultWideStatSpacingX * metrics.scale,
            y: metrics.statsY
        )
        totalTitleLabel.position = CGPoint(
            x: metrics.panelCenter.x + UILayout.resultWideStatSpacingX * metrics.scale,
            y: statTitleY
        )
    }

    private func layoutButtons() {
        // Sprint 7+ — safeArea.bottom 회피로 교체.
        // 기존 resultButtonOffsetYV2(-180)는 값 보존 — 다른 곳 참조 가능성.
        // frame.midY + offset 식은 디바이스에 따라 두 버튼이 잘렸다.
        let safe = resultSafeInsets()
        let scale = resultButtonScale()
        shareButton?.setScale(scale)
        scoreboardButton?.setScale(scale)
        restartButton.setScale(scale)
        mainButton?.setScale(scale)
        let buttonY = frame.minY
            + safe.bottom
            + UILayout.resultWideButtonBottomInset
            + UILayout.primaryButtonHeight * scale / 2
        // Sprint V6 — 하단 3버튼 X 간격 확대: share(-70→-60), restart(+80→+95),
        //   scoreboard(share-110→share-130). 빽빽함 해소. V2/V3 토큰 값은 byte-identical 보존.
        let totalWidth = resultButtonTotalWidth(scale: scale)
        let leftEdge = resultSafeCenterX() - totalWidth / 2
        let scoreboardWidth = UILayout.resultScoreboardButtonWidth * scale
        let shareWidth = UILayout.resultShareButtonWidth * scale
        let restartWidth = UILayout.primaryButtonWidth * scale
        let mainWidth = UILayout.resultMainButtonWidth * scale
        let gap = resultButtonGap(scale: scale)
        let scoreboardX = leftEdge + scoreboardWidth / 2
        let shareX = scoreboardX + scoreboardWidth / 2 + gap + shareWidth / 2
        let restartX = shareX + shareWidth / 2 + gap + restartWidth / 2
        let mainX = restartX + restartWidth / 2 + gap + mainWidth / 2
        shareButton?.position = CGPoint(
            x: shareX,
            y: buttonY
        )
        restartButton.position = CGPoint(
            x: restartX,
            y: buttonY
        )
        // Sprint 7 Phase D → V6 — "📊 기록 보기" GlassPill을 shareButton 좌측 -130pt(V3 -110에서 -20pt 확대).
        scoreboardButton?.position = CGPoint(
            x: scoreboardX,
            y: buttonY
        )
        mainButton?.position = CGPoint(
            x: mainX,
            y: buttonY
        )
    }

    private func resultPanelSize() -> CGSize {
        let safe = resultSafeInsets()
        let scale = resultCompactScale()
        let availableWidth = size.width
            - safe.left
            - safe.right
            - UILayout.resultWidePanelHorizontalPadding * 2
        let minimumWidth = min(
            UILayout.resultWidePanelMinWidth * scale,
            availableWidth
        )
        let width = max(
            minimumWidth,
            min(UILayout.resultWidePanelMaxWidth, availableWidth)
        )
        let availableHeight = size.height
            - safe.top
            - safe.bottom
            - UILayout.resultWidePanelVerticalPadding * 2
        let verticalBandHeight = resultPanelTopBound() - resultPanelBottomBound()
        let height = min(
            UILayout.resultWidePanelHeight,
            availableHeight,
            verticalBandHeight
        )
        return CGSize(
            width: max(0, width),
            height: max(0, height)
        )
    }

    private func resultPanelCenter(panelHeight: CGFloat) -> CGPoint {
        let bottomY = resultPanelBottomBound()
        let topY = resultPanelTopBound()
        let centerY = bottomY + min(panelHeight, max(0, topY - bottomY)) / 2
        return CGPoint(x: resultSafeCenterX(), y: centerY)
    }

    private func resultPanelBottomBound() -> CGFloat {
        let safe = resultSafeInsets()
        let buttonScale = resultButtonScale()
        let buttonTopY = frame.minY
            + safe.bottom
            + UILayout.resultWideButtonBottomInset
            + UILayout.primaryButtonHeight * buttonScale
        return buttonTopY + UILayout.resultWidePanelSafeGap
    }

    private func resultPanelTopBound() -> CGFloat {
        let safe = resultSafeInsets()
        return frame.maxY - safe.top - UILayout.resultWidePanelVerticalPadding
    }

    private func resultSafeCenterX() -> CGFloat {
        let safe = resultSafeInsets()
        let availableWidth = size.width - safe.left - safe.right
        return frame.minX + safe.left + availableWidth / 2
    }

    private func scoreNoteIconOffsetX(scale: CGFloat) -> CGFloat {
        let fixedOffset = abs(UILayout.resultScoreNoteIconOffsetX) * scale
        let widthAwareOffset = scoreLabel.calculateAccumulatedFrame().width / 2
            + UILayout.resultWideScoreNoteGap * scale
        return max(fixedOffset, widthAwareOffset)
    }

    private func resultCompactScale() -> CGFloat {
        if size.height < UILayout.compactLandscapeMinHeight {
            return UILayout.resultWideCompactScale
        }
        if size.width < UILayout.compactNarrowWidth {
            return UILayout.resultWideNarrowScale
        }
        return 1.0
    }

    private func resultButtonScale() -> CGFloat {
        let safe = resultSafeInsets()
        let availableWidth = size.width
            - safe.left
            - safe.right
            - UILayout.menuHorizontalSafePadding * 2
        let normalScale = resultCompactScale()
        let requiredWidth = resultButtonTotalWidth(scale: normalScale)
        guard requiredWidth > availableWidth, requiredWidth > 0 else {
            return normalScale
        }
        let compactWidth = resultButtonTotalWidth(scale: UILayout.resultButtonCompactScale)
        if compactWidth <= availableWidth {
            return UILayout.resultButtonCompactScale
        }
        return max(Typography.labelMinimumScale, availableWidth / resultButtonTotalWidth(scale: 1.0))
    }

    private func resultButtonTotalWidth(scale: CGFloat) -> CGFloat {
        return UILayout.resultScoreboardButtonWidth * scale
            + UILayout.resultShareButtonWidth * scale
            + UILayout.primaryButtonWidth * scale
            + UILayout.resultMainButtonWidth * scale
            + resultButtonGap(scale: scale) * 3
    }

    private func resultButtonGap(scale: CGFloat) -> CGFloat {
        return UILayout.resultWideButtonGap * scale
    }

    private func resultSafeInsets() -> UIEdgeInsets {
        let profile = DeviceLayoutProfile.resolve(for: self)
        return SceneSafeArea.contentInsets(
            for: self,
            maxContentWidth: profile.resultMaxContentWidth
        )
    }

    // MARK: - Touch
    /// 화면 탭 1회 → 버튼만 동작한다. 빈 공간 탭은 아무 일도 하지 않는다.
    /// 중복 탭은 isTransitioning으로 차단. view 옵셔널은 guard let으로 안전 추출.
    /// Sprint 7 Phase D — scoreboardButton 탭 분기 추가(1탭 정책 유지 — 한 화면 안에서 한 번만 탭).
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        // Phase 7-5 — 졸업장 표시 중이면 StartScene 전환 차단. 졸업장 자체가 isUserInteractionEnabled=true로
        // 자기 터치를 흡수하므로 이 경로 도달 가능성은 낮지만 edge case 안전망.
        if children.contains(where: { $0.name == "diplomaOverlay" }) { return }
        guard let view = self.view, let touch = touches.first else { return }
        let location = touch.location(in: self)

        if let pill = shareButton, pill.contains(location) {
            presentShareSheet()
            return
        }

        guard !isShareSheetPresenting else { return }

        if restartButton.contains(location) {
            transitionToRetryGame(in: view)
            return
        }

        // Sprint 7 Phase D — 기록 보기 GlassPill 탭 분기 → ScoreboardScene 0.4s fade.
        // ★ 마커 키: 신기록이고 캐릭터 역변환 성공한 경우만. 그 외 nil → 매트릭스에 ★ 미표시.
        // ResultReturnContext에 9-인자 전달 — 졸업장 재진입 차단을 위해 isNewGraduation은 SPEC §주의사항 3에 따라
        // ScoreboardScene.returnToResult* 단계에서 `false`로 강제 — 이 단계에서는 원본값 그대로 전달.
        if let pill = scoreboardButton, pill.contains(location) {
            transitionToScoreboard(in: view)
            return
        }

        if let pill = mainButton, pill.contains(location) {
            transitionToCharacterHome(in: view)
            return
        }

        return
    }

    private func transitionToCharacterHome(in view: SKView) {
        isTransitioning = true
        let characterHome = CharacterSelectScene.newCharacterSelectScene()
        let fade = SKTransition.fade(withDuration: FeelTuning.sceneTransitionDuration)
        view.presentScene(characterHome, transition: fade)
    }

    private func transitionToScoreboard(in view: SKView) {
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
        let fade = SKTransition.fade(withDuration: FeelTuning.sceneTransitionDuration)
        view.presentScene(scoreboard, transition: fade)
    }

    private func transitionToRetryGame(in view: SKView) {
        isTransitioning = true
        let scope = AccountProgressScopeProvider.current(
            authProfile: AuthProfileRepository().current
        )
        let characterID = inferredCharacterID
            ?? CharacterPreferenceRepository.scoped(scope: scope).current
        let gameScene = GameScene.newGameScene(characterID: characterID, difficulty: difficulty)
        let fade = SKTransition.fade(withDuration: FeelTuning.sceneTransitionDuration)
        view.presentScene(gameScene, transition: fade)
    }

    private func presentShareSheet() {
        #if os(iOS)
        guard !isShareSheetPresenting else { return }
        isShareSheetPresenting = true

        guard let view = self.view,
              let presenter = presentationController(from: view) else {
            isShareSheetPresenting = false
            showShareFailureToast()
            return
        }

        guard !(presenter is UIActivityViewController) else {
            isShareSheetPresenting = false
            return
        }

        var items: [Any] = [shareMessage()]
        if let image = resultShareImage(from: view) {
            items.append(image)
        }

        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        configurePopover(for: activity, in: view)
        activity.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.isShareSheetPresenting = false
        }
        presenter.present(activity, animated: true)
        #endif
    }

    #if os(iOS)
    private func presentationController(from view: SKView) -> UIViewController? {
        let root = view.window?.rootViewController ?? owningViewController(from: view)
        return topMostViewController(from: root)
    }

    private func owningViewController(from view: UIView) -> UIViewController? {
        var responder: UIResponder? = view
        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController
            }
            responder = current.next
        }
        return nil
    }

    private func topMostViewController(from controller: UIViewController?) -> UIViewController? {
        guard let controller = controller else { return nil }

        if let presented = controller.presentedViewController {
            return topMostViewController(from: presented)
        }
        if let navigation = controller as? UINavigationController {
            return topMostViewController(from: navigation.visibleViewController) ?? navigation
        }
        if let tab = controller as? UITabBarController {
            return topMostViewController(from: tab.selectedViewController) ?? tab
        }
        return controller
    }

    private func resultShareImage(from view: SKView) -> UIImage? {
        let bounds = view.bounds
        guard bounds.width >= UILayout.resultShareImageMinimumSide,
              bounds.height >= UILayout.resultShareImageMinimumSide else {
            return nil
        }

        var didDraw = false
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let image = renderer.image { _ in
            didDraw = view.drawHierarchy(in: bounds, afterScreenUpdates: false)
        }
        guard didDraw else { return nil }
        return image
    }

    private func configurePopover(for activity: UIActivityViewController, in view: SKView) {
        guard let popover = activity.popoverPresentationController else { return }
        popover.sourceView = view
        popover.sourceRect = sharePopoverSourceRect(in: view)
        popover.permittedArrowDirections = []
    }

    private func sharePopoverSourceRect(in view: SKView) -> CGRect {
        let anchorSize = UILayout.resultSharePopoverAnchorSize
        let fallback = CGRect(
            x: view.bounds.midX - anchorSize / 2,
            y: view.bounds.midY - anchorSize / 2,
            width: anchorSize,
            height: anchorSize
        )

        guard let shareButton = shareButton else { return fallback }
        let point = convertPoint(toView: shareButton.position)
        guard view.bounds.contains(point) else { return fallback }

        return CGRect(
            x: point.x - anchorSize / 2,
            y: point.y - anchorSize / 2,
            width: anchorSize,
            height: anchorSize
        )
    }
    #endif

    private func shareMessage() -> String {
        let bestPrefix = isNewBest ? "신기록! " : ""
        let target = GameplayTuning.targetScoreByDifficulty[difficulty] ?? 0
        return "\(bestPrefix)김간호는 음악박사에서 \(characterName) · \(difficulty.displayName) 난이도 \(finalScore)점 달성! 최고기록 \(bestScore)점, 목표 \(target)점."
    }

    // MARK: - Share Feedback

    private func showShareFailureToast() {
        shareFailureToast?.removeAllActions()
        shareFailureToast?.removeFromParent()

        let label = SKLabelNode(fontNamed: Typography.fontDisplay)
        label.text = UILayout.resultShareFailureToastText
        label.fontSize = UILayout.resultShareToastFontSize
        label.fontColor = .ganhoNavyDeep
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = ZOrder.resultShareToastZPosition
        label.position = shareToastPosition()
        label.alpha = .zero
        shareFailureToast = label
        addChild(label)

        let fadeIn = SKAction.fadeIn(withDuration: UILayout.resultShareToastFadeDuration)
        let wait = SKAction.wait(forDuration: UILayout.resultShareToastDuration)
        let fadeOut = SKAction.fadeOut(withDuration: UILayout.resultShareToastFadeDuration)
        let clearReference = SKAction.run { [weak self, weak label] in
            guard let self = self,
                  let label = label,
                  let current = self.shareFailureToast,
                  current === label else {
                return
            }
            self.shareFailureToast = nil
        }
        let remove = SKAction.removeFromParent()
        label.run(.sequence([fadeIn, wait, fadeOut, clearReference, remove]))
    }

    private func shareToastPosition() -> CGPoint {
        if let shareButton = shareButton {
            return CGPoint(
                x: shareButton.position.x,
                y: shareButton.position.y + UILayout.resultShareToastOffsetY
            )
        }
        return CGPoint(
            x: frame.midX,
            y: frame.minY + UILayout.resultShareToastOffsetY
        )
    }

    // MARK: - Helpers (Sprint 7 Phase D)

    /// characterName(한글) → CharacterID 역변환. allCases.first {$0.displayName == characterName}.
    /// 5명의 displayName이 모두 유일하므로 안전. 매칭 실패 시 nil 반환 — ★ 마커 미표시.
    /// ResultScene.init 9-인자 시그니처를 *그대로 보존*하기 위한 우회 — characterID는 인자가 아니므로
    /// characterName으로부터 역추론한다(SPEC §OQ-3).
    private var inferredCharacterID: CharacterID? {
        return CharacterID.allCases.first { $0.displayName == characterName }
    }

    // MARK: - Record Reward (Phase 6-15)

    /// 신기록 진입 시점에만 발화. BEST/NEW BEST 문구는 bestPill에만 남기고
    /// 중앙 보상 라벨은 별도 축하 문구로만 표시한다.
    /// 햅틱/사운드/sparkle/bestPill pulse는 revealNewBest()에서 그대로 유지한다.
    private func configureNewBestLabel() {
        newBestLabel.fontSize = FeelTuning.newBestFontSize
        newBestLabel.fontColor = .ganhoYellowF      // 황금 — ComboPopup x10 황금기와 동일 톤
        newBestLabel.horizontalAlignmentMode = .center
        newBestLabel.verticalAlignmentMode = .center
        newBestLabel.alpha = 0                      // fade-in 시작점
        newBestLabel.zPosition = ZOrder.newBestZPosition
        newBestLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + FeelTuning.newBestOffsetY
        )
    }

    /// SKScene 자체에 SKAction 부착 — Timer/DispatchQueue 사용 금지(Swift 규칙 9).
    /// [weak self] 캡처 — 씬 해제 가능성 대비.
    private func scheduleNewBestRewardPulse() {
        let wait = SKAction.wait(forDuration: UILayout.resultRewardPulseDelay)
        let reveal = SKAction.run { [weak self] in
            self?.revealNewBest()
        }
        run(.sequence([wait, reveal]))
    }

    /// 0.3초 지연 후 호출. 중앙 보상 라벨 + 햅틱 + 사운드 + BEST pill pulse를 한 묶음으로 발화.
    /// newBestLabel은 ResultScene 자체와 함께 정리됨 — 씬 해제 시 ARC가 처리(자가 소멸 노드와 달리 명시적 cleanup 불필요).
    private func revealNewBest() {
        // 1) 촉각: heavy = 도달의 무게감. ResultScene 새 인스턴스라 endGame heavy와 톤 충돌 없음.
        haptics.heavy()
        // 2) 청각: NewMail 1025 — 긍정·묵직. 6-11/6-13 재사용으로 신규 SFX 0건.
        audio.play(.comboMilestoneStrong)
        // 3) 시각: fade-in + scale pulse. group으로 동시 실행.
        let fadeIn = SKAction.fadeIn(withDuration: FeelTuning.newBestFadeInDuration)
        let scaleUp = SKAction.scale(
            to: FeelTuning.newBestEndScalePeak,
            duration: FeelTuning.newBestScalePulseDuration / 2
        )
        let scaleDown = SKAction.scale(
            to: 1.0,
            duration: FeelTuning.newBestScalePulseDuration / 2
        )
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        if newBestLabel.parent != nil {
            newBestLabel.run(SKAction.group([fadeIn, pulse]))
        }
        // 4) BEST pill 깜빡임 시작.
        startBestLabelGoldBlink()
        // 5) Sprint 5 — sparkle 5발 부착 (마지막 라인 추가). 기존 시퀀스 보존.
        emitSparkleBurst()
    }

    /// 실제 표시되는 BEST pill에 alpha 깜빡임을 적용한다. (legacy bestLabel은 R0에서 삭제.)
    /// withKey 패턴(6-14 tensionBlink 답습) — 같은 키 재호출 시 자동 교체로 자연 멱등.
    /// 씬 해제 시 ARC가 액션 정리하므로 명시적 stop 불필요.
    private func startBestLabelGoldBlink() {
        let fadeOut = SKAction.fadeAlpha(
            to: FeelTuning.newBestBlinkMinAlpha,
            duration: FeelTuning.newBestBlinkHalfPeriod
        )
        let fadeIn = SKAction.fadeAlpha(
            to: UILayout.menuControlEnabledAlpha,
            duration: FeelTuning.newBestBlinkHalfPeriod
        )
        let cycle = SKAction.sequence([fadeOut, fadeIn])
        bestPill?.run(.repeatForever(cycle), withKey: FeelTuning.newBestBlinkActionKey)
    }

    /// Sprint 5 — 신기록 시 카드 주변 5개 좌표에 SparkleEffectNode 부착 + emit().
    /// 기존 SparkleEffectNode(자가 소멸 4호) 그대로 재활용 — 내부 0건 변경. addChild 좌표/zPosition만 다름.
    /// 5개 자식은 각자 0.5초 후 자가 소멸 → ResultScene은 후속 정리 0건.
    private func emitSparkleBurst() {
        for offset in UILayout.resultSparklePositions {
            // Sprint 10 Phase J — .menu 명시. 메뉴 v2 카툰 톤(원형 순백) 유지 — 인게임 픽셀 톤과 분리.
            let sparkle = SparkleEffectNode(context: .menu)
            sparkle.position = CGPoint(
                x: frame.midX + offset.x,
                y: frame.midY + offset.y
            )
            sparkle.zPosition = ZOrder.newBestZPosition + 1
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
