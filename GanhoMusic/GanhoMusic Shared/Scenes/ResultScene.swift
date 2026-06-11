//
//  ResultScene.swift
//  GanhoMusic Shared
//
//  R5 제로 재작성 — "보상의 무대" (03_UI §7). BaseMenuScene 상속 + NightShiftBackdrop.
//  노드 구성은 +Build, 연출 시퀀스(도장→카운트업→별→XP→기록 칩→버튼)는 +Reveal 분리.
//  결과 데이터 10종은 init 주입 `let` — 변조 불가. 전환은 SceneRouter 단일 경로 + isTransitioning 가드.
//

import SpriteKit

/// 게임 종료 후 결과 씬. 판이 끝나는 순간이 가장 보상감 있는 ~2.4초가 되도록 연출한다.
final class ResultScene: BaseMenuScene {

    // MARK: - Injected Data (불변 — R5: characterID 직접 주입 + maxCombo/notesCollected 추가)
    let finalScore: Int
    let bestScore: Int
    let isNewBest: Bool
    let stats: GameStats
    let characterID: CharacterID
    let difficulty: Difficulty
    let maxCombo: Int
    let notesCollected: Int
    let isNewGraduation: Bool
    let graduatedAt: Date?
    /// R6 §F6 — 메타 기록 결과. nil = 기존과 byte-동일 동작 (verdict 기준 = 라이브 목표).
    let runMeta: RunMetaOutcome?

    // MARK: - Derived (init 1회 — 성공 = score >= 실효 목표(경계 포함) / 별 = MetaProgression)
    /// 이번 판 실효 목표 — runMeta 있으면 그 값(음표 러시 ×1.3 포함), 없으면 라이브 목표.
    let effectiveTarget: Int
    let isSuccess: Bool
    let earnedStars: Int

    // MARK: - Nodes (Reveal 확장이 시퀀스 단계별로 부착 — alpha=0 대기 좀비 0)
    /// verdict 셰이크 대상 콘텐츠 컨테이너 (버튼·백드롭 제외).
    let contentNode = SKNode()
    let verdictLabel = SKLabelNode(fontNamed: Typography.V3.verdict.fontName)
    let scoreLabel = SKLabelNode(fontNamed: Typography.V3.hudScore.fontName)
    let starContainer = SKNode()
    let levelLabel = SKLabelNode(fontNamed: Typography.V3.caption.fontName)
    let xpBar = PixelProgressBarNode(size: UILayout.R5.resultXPBarSize, fillColor: Palette.gold)
    var contextChip: PixelChipNode?
    var comboChip: PixelChipNode?
    var notesChip: PixelChipNode?
    // R12 #9 — 통계 칩 2종 (runMeta 있을 때만 생성 — nil = 노드 미생성, 좀비 금지).
    var breaksChip: PixelChipNode?
    var toiletsChip: PixelChipNode?
    var recordChip: PixelChipNode?
    var levelUpChip: PixelChipNode?
    // R6 §F6 — 시퀀스 완료 후 정적 칩 2종 (해당 없으면 노드 미생성 — 좀비 금지).
    var dailyClearChip: PixelChipNode?
    var achievementChip: PixelChipNode?
    var retryButton: PixelButtonNode?
    var characterButton: PixelButtonNode?
    var recordsButton: PixelButtonNode?

    // MARK: - State — 시퀀스 완료(완료 후에만 버튼 동작 §7) / 졸업장 1회 가드 /
    // 카운트업 틱 단계 추적(매 프레임 발화 금지) / 전환 중복 가드(R4 P1 — 이중 present 차단)
    var revealCompleted = false
    var didPresentDiploma = false
    var lastScoreTickStep = -1
    private var isTransitioning = false

    let haptics = HapticsManager()
    let synth = ChiptuneSynth.shared

    // MARK: - Factory
    /// 외부 진입 단일 경로 — `private init`으로 직접 호출 차단. .resizeFill로 view 크기 자동 맞춤.
    class func newResultScene(
        score: Int, bestScore: Int, isNewBest: Bool, stats: GameStats,
        characterID: CharacterID, difficulty: Difficulty,
        maxCombo: Int, notesCollected: Int,
        isNewGraduation: Bool = false, graduatedAt: Date? = nil,
        runMeta: RunMetaOutcome? = nil
    ) -> ResultScene {
        let scene = ResultScene(
            size: CGSize(width: 1024, height: 768),
            score: score, bestScore: bestScore, isNewBest: isNewBest, stats: stats,
            characterID: characterID, difficulty: difficulty,
            maxCombo: maxCombo, notesCollected: notesCollected,
            isNewGraduation: isNewGraduation, graduatedAt: graduatedAt,
            runMeta: runMeta
        )
        scene.scaleMode = .resizeFill
        return scene
    }

    // MARK: - Init
    private init(
        size: CGSize,
        score: Int, bestScore: Int, isNewBest: Bool, stats: GameStats,
        characterID: CharacterID, difficulty: Difficulty,
        maxCombo: Int, notesCollected: Int,
        isNewGraduation: Bool, graduatedAt: Date?,
        runMeta: RunMetaOutcome?
    ) {
        self.finalScore = score
        self.bestScore = bestScore
        self.isNewBest = isNewBest
        self.stats = stats
        self.characterID = characterID
        self.difficulty = difficulty
        self.maxCombo = maxCombo
        self.notesCollected = notesCollected
        self.isNewGraduation = isNewGraduation
        self.graduatedAt = graduatedAt
        self.runMeta = runMeta
        // R6 §F6 — verdict/★/부족 칩 전부 실효 목표 단일 기준 (nil = 라이브 목표 = 기존 byte-동일).
        let effectiveTarget = runMeta?.effectiveTarget ?? difficulty.targetScore
        self.effectiveTarget = effectiveTarget
        self.isSuccess = score >= effectiveTarget
        self.earnedStars = MetaProgression.stars(score: score, target: effectiveTarget)
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        setupNightShiftBackdrop()
        addChild(contentNode)
        buildRevealNodes()
        layoutAll()
        #if DEBUG
        MetaProgression.debugAuditAlignment()
        print("[ResultScene] didMove 직계 자식: \(children.count)")
        #endif
        startRevealSequence()
    }

    /// 회전/리사이즈 — 백드롭 재생성 + 좌표 재확정. 연출 진행 중이면 시퀀스를 즉시 최종 상태로
    /// 확정 후 재배치 (SPEC §주의사항 4 — 진행 중 좌표 재확정의 단순·견고한 해법).
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard contentNode.parent != nil else { return }   // didMove 이전 호출 가드
        cancelStaggeredAppear()
        rebuildNightShiftBackdrop()
        if !revealCompleted { finishRevealImmediately() }
        layoutAll()
    }

    // MARK: - Layout
    func layoutAll() {
        let scale = menuCompactScale()
        contentNode.setScale(scale)
        contentNode.position = CGPoint(
            x: resultSafeCenterX().rounded(),
            y: (frame.midY + UILayout.R5.resultContentCenterYOffset * scale).rounded()
        )
        layoutContent()
        layoutButtons(scale: scale)
    }

    /// 콘텐츠 컨테이너 내부 좌표 — R5 토큰 오프셋 (컨테이너 스케일이 compact 흡수).
    private func layoutContent() {
        contextChip?.position = CGPoint(x: 0, y: UILayout.R5.resultContextChipOffsetY)
        verdictLabel.position = CGPoint(x: 0, y: UILayout.R5.resultVerdictOffsetY)
        scoreLabel.position = CGPoint(x: 0, y: UILayout.R5.resultScoreOffsetY)
        recordChip?.position = CGPoint(x: UILayout.R5.resultRecordChipOffsetX,
                                       y: UILayout.R5.resultScoreOffsetY)
        starContainer.position = CGPoint(x: 0, y: UILayout.R5.resultStarRowOffsetY)
        layoutMetaChips()
        xpBar.position = CGPoint(x: 0, y: UILayout.R5.resultXPBarOffsetY)
        levelLabel.position = CGPoint(x: 0, y: UILayout.R5.resultLevelLabelOffsetY)
        levelUpChip?.position = CGPoint(x: UILayout.R5.resultLevelUpChipOffsetX,
                                        y: UILayout.R5.resultLevelLabelOffsetY)
        // R6 §F6 — 정적 칩 2종: 점수 좌측 열 (recordChip +168의 좌측 대칭 — 기존 요소·버튼 겹침 0).
        dailyClearChip?.position = CGPoint(x: UILayout.R6.resultMetaOutcomeChipOffsetX,
                                           y: UILayout.R6.resultDailyClearChipOffsetY)
        achievementChip?.position = CGPoint(x: UILayout.R6.resultMetaOutcomeChipOffsetX,
                                            y: UILayout.R6.resultAchievementChipOffsetY)
    }

    private func layoutMetaChips() {   // 콤보·수집(+R12 끊김·변기) 칩 행 중앙 정렬 — 최대 4칩
        // R12 #9 — 2칩 고정 산식 → 가변 행 일반화 (runMeta nil이면 기존 2칩과 좌표 동일).
        let chips = [comboChip, notesChip, breaksChip, toiletsChip].compactMap { $0 }
        guard !chips.isEmpty else { return }
        let gap = UILayout.R5.resultMetaChipGap
        let total = chips.reduce(0) { $0 + $1.chipSize.width } + gap * CGFloat(chips.count - 1)
        let rowY = UILayout.R5.resultMetaChipRowOffsetY
        var cursorX = -total / 2
        for chip in chips {
            chip.position = CGPoint(x: (cursorX + chip.chipSize.width / 2).rounded(), y: rowY)
            cursorX += chip.chipSize.width + gap
        }
    }

    private func layoutButtons(scale: CGFloat) {   // 하단 버튼 행 — R4 bottomCTAAnchorY 패턴
        guard let retry = retryButton, let character = characterButton,
              let records = recordsButton else { return }
        [retry, character, records].forEach { $0.setScale(scale) }
        let widths = [UILayout.R4.ctaButtonSize.width,
                      UILayout.R4.secondaryCTAButtonSize.width,
                      UILayout.R5.resultGhostButtonSize.width].map { $0 * scale }
        let gap = UILayout.R5.resultButtonGap * scale
        let total = widths.reduce(0, +) + gap * CGFloat(widths.count - 1)
        let rowY = bottomCTAAnchorY(buttonHalfHeight: UILayout.R4.ctaButtonSize.height * scale / 2)
        var cursorX = resultSafeCenterX() - total / 2
        for (index, button) in [retry, character, records].enumerated() {
            button.position = CGPoint(x: (cursorX + widths[index] / 2).rounded(),
                                      y: rowY.rounded())
            cursorX += widths[index] + gap
        }
    }

    private func resultSafeCenterX() -> CGFloat {
        let safe = menuSafeInsets()
        let availableWidth = size.width - safe.left - safe.right
        return frame.minX + safe.left + availableWidth / 2
    }

    // MARK: - Touch (시퀀스 스킵 전용 — 완료 후 버튼은 PixelButtonNode 자체 처리)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        // 졸업장 노출 중 — 졸업장 자체가 터치를 흡수하지만 edge case 안전망 (v2 정책 유지).
        if children.contains(where: { $0.name == "diplomaOverlay" }) { return }
        guard !revealCompleted else { return }
        finishRevealImmediately()
    }

    // MARK: - Transitions (SceneRouter 단일 경로 — 전환 객체 직접 생성 금지)
    func transitionToRetry() {
        guard !isTransitioning, let view = self.view else { return }
        isTransitioning = true
        let gameScene = GameScene.newGameScene(characterID: characterID, difficulty: difficulty)
        SceneRouter.present(gameScene, on: view, route: .intoGame)
    }

    func transitionToCharacterSelect() {
        guard !isTransitioning, let view = self.view else { return }
        isTransitioning = true
        let scene = CharacterSelectScene.newCharacterSelectScene()
        SceneRouter.present(scene, on: view, route: .backward)
    }

    func transitionToScoreboard() {
        guard !isTransitioning, let view = self.view else { return }
        isTransitioning = true
        // ★ 직전 신기록 마커 키 — 신기록일 때만 (characterID 직접 주입 — 역추론 우회 소멸).
        let lastUpdatedKey: (CharacterID, Difficulty)? = isNewBest ? (characterID, difficulty) : nil
        let ctx = ResultReturnContext(
            finalScore: finalScore, bestScore: bestScore, isNewBest: isNewBest, stats: stats,
            characterID: characterID, difficulty: difficulty,
            maxCombo: maxCombo, notesCollected: notesCollected,
            isNewGraduation: isNewGraduation, graduatedAt: graduatedAt,
            runMeta: runMeta   // R6 — 복귀 재생성 verdict 정합 (음표 러시 판 필수 — nil 처리 금지)
        )
        let scoreboard = ScoreboardScene.newScoreboardScene(
            lastUpdatedKey: lastUpdatedKey,
            returnContext: ctx
        )
        SceneRouter.present(scoreboard, on: view, route: .forward)
    }

    // MARK: - Diploma (기존 동작 보존 — 시퀀스 완료 후 1회, 내부 무변경)
    func presentDiplomaIfNeeded() {
        guard isNewGraduation, let graduatedAt = graduatedAt, !didPresentDiploma else { return }
        didPresentDiploma = true
        DiplomaOverlayNode.present(
            characterName: characterID.displayName,
            graduatedAt: graduatedAt,
            parent: self,
            sceneSize: size,
            anchor: CGPoint(x: size.width / 2, y: size.height / 2),
            onDismiss: {}
        )
    }
}
