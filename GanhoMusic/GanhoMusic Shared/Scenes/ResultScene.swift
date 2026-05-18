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
//

import SpriteKit

/// 게임 종료 후 결과를 보여주는 독립 씬.
/// `finalScore`/`bestScore`/`isNewBest`는 init 주입으로 박혀(`let`) 변조 불가.
/// 신기록이면 "★ NEW BEST! ★", 아니면 "BEST 🏆 N"으로 분기 표시.
/// 표시 후 탭 1회 → TitleScene fade.
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
    /// TitleScene 복귀 중복 진입 가드.
    private var isTransitioning = false
    private let titleLabel  = SKLabelNode(text: "GAME OVER")
    private let scoreLabel  = SKLabelNode(text: "🎵 0")
    private let bestLabel   = SKLabelNode(text: "BEST 🏆 0")
    private let statsLabel  = SKLabelNode(text: "PLAYS 0  /  TOTAL 0")
    /// Phase 5-7 — title(+80) 위쪽에 표시되는 캐릭터 라벨. 텍스트는 setupLabels에서 합성.
    private let characterLabel = SKLabelNode(text: "")
    /// Phase 7-1 — characterLabel(+115) 위쪽에 표시되는 난이도 라벨. 텍스트는 setupLabels에서 합성.
    private let difficultyLabel = SKLabelNode(text: "")
    private let promptLabel = SKLabelNode(text: "TAP TO RETURN")
    /// Phase 6-15 — 신기록 시 화면 정중앙에 등장하는 황금 라벨. isNewBest일 때만 addChild.
    private let newBestLabel = SKLabelNode(text: "NEW BEST!")
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
        backgroundColor = .ganhoBgDeep
        setupOverlayPanel()                             // Phase 8-4 — 원본 #overlayEnd 배경 + 380 카드 패널 (라벨 *뒤*에 배치)
        setupLabels()
    }

    /// scene.size 변경 시(회전·resize) 라벨 위치 재계산. 자식 추가는 setupLabels에서만.
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutLabels()
    }

    // MARK: - Setup
    /// Phase 8-4 — 원본 웹게임 `#overlayEnd .game-overlay__panel--end` 톤 재현.
    /// TitleScene.setupOverlayPanel 패턴 완전 답습 — 신규 파일 0건, 동형 구조.
    /// 1) 화면 전체 반투명 검정 사각형(zPosition -10) — 게임 영역 차단 톤.
    /// 2) 가운데 카드 패널 SKShapeNode(zPosition -5) — 원본 max-width 380px 재현.
    /// 라벨 layout은 *미접촉* — Phase 7-1(+155) ~ Phase 3-3(-80) 모두 패널(560 height) 안에 자연 배치.
    private func setupOverlayPanel() {
        // 1) 화면 전체 반투명 검정 배경 — 원본 .game-overlay 배경
        let bg = SKSpriteNode(color: .ganhoUIOverlayBg, size: size)
        bg.position = CGPoint(x: frame.midX, y: frame.midY)
        bg.zPosition = -10
        bg.name = "overlayBackground"
        addChild(bg)

        // 2) 가운데 카드 패널 — 원본 #overlayEnd .game-overlay__panel--end (max-width 380px)
        let panel = SKShapeNode(
            rectOf: CGSize(
                width: GameConfig.resultPanelMaxWidth,
                height: GameConfig.resultPanelHeight
            ),
            cornerRadius: GameConfig.uiRadius
        )
        panel.fillColor = .ganhoUIBgCard
        panel.strokeColor = .ganhoUIBorder
        panel.lineWidth = GameConfig.uiPanelLineWidth
        panel.position = CGPoint(x: frame.midX, y: frame.midY)
        panel.zPosition = -5
        panel.name = "overlayPanel"
        addChild(panel)
    }

    private func setupLabels() {
        configureLabel(titleLabel,      fontSize: GameConfig.resultTitleFontSize)
        configureLabel(scoreLabel,      fontSize: GameConfig.resultScoreFontSize)
        configureLabel(bestLabel,       fontSize: GameConfig.resultBestFontSize)
        configureLabel(statsLabel,      fontSize: GameConfig.resultStatsFontSize)
        configureLabel(characterLabel,  fontSize: GameConfig.resultCharacterFontSize)
        configureLabel(difficultyLabel, fontSize: GameConfig.resultDifficultyFontSize)   // Phase 7-1
        configureLabel(promptLabel,     fontSize: GameConfig.resultPromptFontSize)
        // Phase 8-4 — 원본 #overlayEnd 시각 토큰 갈아 끼움. configureLabel 후 *오버라이드*로 라벨 위치/구조는 미접촉.
        // 점수 숫자: 40pt 코럴 강조 (.score-num) — 단, NEW BEST 시퀀스가 황금색으로 덮어쓰므로 isNewBest=true 시
        //          revealNewBest → startBestLabelGoldBlink가 *bestLabel*만 황금 처리. scoreLabel은 brand-light 유지.
        scoreLabel.fontSize = GameConfig.resultScoreNumFontSize
        scoreLabel.fontColor = .ganhoUIBrandLight
        // 베스트 기록: 12pt brand (.game-overlay__record) — NEW BEST 시퀀스가 황금색으로 *덮어씀* (보존).
        bestLabel.fontSize = GameConfig.resultRecordFontSize
        bestLabel.fontColor = .ganhoUIBrand
        // 통계: 14pt text-muted (.game-overlay__score 톤) — 보조 정보 회색.
        statsLabel.fontColor = .ganhoUITextMuted
        statsLabel.fontSize = GameConfig.resultScoreLabelFontSize
        // 캐릭터 이름: 14pt text-muted (보조 정보 회색).
        characterLabel.fontColor = .ganhoUITextMuted
        characterLabel.fontSize = GameConfig.resultScoreLabelFontSize
        // 난이도: text-muted (.white → 보조 정보 회색). fontSize는 기존 값(18) 유지.
        difficultyLabel.fontColor = .ganhoUITextMuted
        scoreLabel.text = "🎵 \(finalScore)"
        // Phase 3-4 — 신기록이면 강조 문구, 아니면 기존 최고치 표시.
        bestLabel.text = isNewBest ? "★ NEW BEST! ★" : "BEST 🏆 \(bestScore)"
        // Phase 3-5 — 누적 통계 표시. record 후 주입되므로 이번 판이 이미 반영된 값.
        statsLabel.text = "PLAYS \(stats.playCount)  /  TOTAL \(stats.totalScore)"
        // Phase 5-7 — 사용한 캐릭터 이름. 빈 문자열이어도 "🎮 "만 — 크래시 없음(graceful).
        characterLabel.text = "🎮 \(characterName)"
        // Phase 7-1 — 사용한 난이도. Difficulty.displayName이 단일 진실 원천("하"/"중"/"상").
        difficultyLabel.text = "난이도: \(difficulty.displayName)"
        addChild(titleLabel)
        addChild(scoreLabel)
        addChild(bestLabel)
        addChild(statsLabel)
        addChild(characterLabel)
        addChild(difficultyLabel)   // Phase 7-1
        addChild(promptLabel)
        layoutLabels()
        // Phase 6-15 — 신기록일 때만 NewBest 시퀀스 시작. false면 0건 발화로 자연 차단.
        if isNewBest {
            configureNewBestLabel()
            scheduleNewBestReveal()
        }
        // Phase 7-4 — 최초 졸업 시 졸업장 자동 표시. 두 가드(`isNewGraduation` true AND `graduatedAt` non-nil)
        // 모두 통과해야 발화 — default 인자만 사용한 기존 호출부는 자연 차단(회귀 0).
        if isNewGraduation, let graduatedAt = graduatedAt {
            presentDiploma(at: graduatedAt)
        }
    }

    /// 6개 라벨 공통 스타일. TitleScene과 동일 패턴.
    private func configureLabel(_ label: SKLabelNode, fontSize: CGFloat) {
        label.fontSize = fontSize
        label.fontColor = .ganhoPaper
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.alpha = GameConfig.hudAlpha
    }

    /// scene.size 기준 위치 재계산. didMove와 didChangeSize에서 공용.
    private func layoutLabels() {
        titleLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultTitleOffsetY
        )
        scoreLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultScoreOffsetY
        )
        bestLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultBestOffsetY
        )
        statsLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultStatsOffsetY
        )
        characterLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultCharacterOffsetY
        )
        // Phase 7-1 — characterLabel(+115) 위쪽(+155)에 표시.
        difficultyLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultDifficultyOffsetY
        )
        promptLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultPromptOffsetY
        )
        // Phase 6-15 — newBestLabel은 isNewBest일 때만 addChild되지만, 위치 set은 부착 여부 무관하게 안전(SKNode 기본 동작).
        newBestLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.newBestOffsetY
        )
    }

    // MARK: - Touch
    /// 화면 어디든 탭 1회 → TitleScene 전환. 중복 탭은 isTransitioning으로 차단.
    /// view 옵셔널은 강제 언래핑 금지 — guard let으로 안전 추출.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        // Phase 7-5 — 졸업장 표시 중이면 TitleScene 전환 차단. 졸업장 자체가 isUserInteractionEnabled=true로
        // 자기 터치를 흡수하므로 이 경로 도달 가능성은 낮지만 edge case 안전망.
        if children.contains(where: { $0.name == "diplomaOverlay" }) { return }
        guard let view = self.view else { return }
        isTransitioning = true
        let titleScene = TitleScene.newTitleScene()
        let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
        view.presentScene(titleScene, transition: fade)
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

    // MARK: - Diploma (Phase 7-4)
    /// 최초 졸업 시점에만 호출 (setupLabels 끝 가드 통과). DiplomaOverlayNode 정적 팩토리로 부착.
    /// parent = self (ResultScene), anchor = `(frame.midX, frame.midY)` — cameraNode 없는 ResultScene에 맞춤.
    /// onDismiss = 빈 클로저 — 졸업장 닫기 후 ResultScene 그대로 노출(*두 단계 탭* 정책: 졸업장 1탭 + TitleScene 1탭).
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
