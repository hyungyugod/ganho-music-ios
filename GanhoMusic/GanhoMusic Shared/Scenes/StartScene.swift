//
//  StartScene.swift
//  GanhoMusic Shared
//
//  Phase 10-1a · 시작 시퀀스 1단계 — 제목 + BEST/PLAYS + 스토리 박스 + 난이도 3장 + 시작 버튼
//  Phase 10-2 · 모던 리스킨 (병동의 새벽 톤) — 그라데이션 배경 + 음표 파티클 + 제목 글로우 +
//               카드 spring/링 글로우 + 시작 버튼 pulse + 전환 잔향. *게임플레이 변경 0건*.
//
//  TitleScene의 구조를 답습하되 *난이도 선택*에만 집중. 캐릭터 카드는 다음 단계(CharacterSelectScene)로 이전.
//  "어디든 탭" 패턴을 제거 — 시작 버튼 명시 탭만 진행.
//  10-1b 완성 시점부터 "시작" → CharacterSelectScene 전환.
//

import SpriteKit

/// 앱 첫 진입 씬. 제목 + BEST/PLAYS + 부제 + 스토리 박스 + 난이도 3장 + 시작 버튼.
/// 카메라/월드 개념 없음 — 라벨은 frame.midX/midY 기준 직접 배치.
/// Phase 10-2 — 비주얼 5채널(그라데이션 / 음표 / 글로우 제목 / 카드 spring / 버튼 pulse) 추가.
final class StartScene: SKScene {

    // MARK: - Properties
    /// 씬 전환이 시작됐는지 여부. true가 되면 추가 탭은 무시 — 더블 enter 방지.
    private var isTransitioning = false
    /// Phase 10-2 — 기존 titleLabel을 GlowingTitleNode로 *래핑*. 라벨 자체는 유지(글로우 컨테이너 내부).
    /// 위치 계산은 GlowingTitleNode 인스턴스에 대해 — layoutLabels 좌표식 *불변*.
    private let titleNode = GlowingTitleNode(
        text: "김간호는 음악박사",
        fontSize: GameConfig.titleFontSize,
        glowColor: .ganhoAccentTeal
    )
    private let subtitleLabel = SKLabelNode(text: "어느 한적한 병동의 오후")
    private let bestLabel     = SKLabelNode(text: "BEST 🏆 0")
    private let playsLabel    = SKLabelNode(text: "PLAYS 0")
    /// 스토리 박스 — 게임 톤 안내. lazy 초기화 — GameConfig 텍스트 의존.
    private lazy var storyBox: StoryBoxNode = StoryBoxNode(body: GameConfig.startSceneStoryText)
    /// 시작 버튼 — 명시 탭만 다음 단계로 진행.
    private let startButton = PrimaryButtonNode(text: "시작")
    /// 현재 선택된 난이도. 기본 .easy. 다음 씬으로 전달.
    private var selectedDifficulty: Difficulty = .easy
    /// 3 난이도 카드 인스턴스 보관. setupDifficultyCards에서 생성, layout/hit test에 재사용.
    private var difficultyCards: [DifficultyCardNode] = []
    /// 난이도 선택 영속 계층. didMove에서 .current로 복원, selectDifficulty(_:)에서 save 호출.
    private let difficultyRepo = DifficultyPreferenceRepository()
    /// 캐릭터 선택 영속 계층. didMove에서 .current로 복원 — 10-1a는 GameScene 직진 시점에 사용.
    /// 10-1b 이후는 CharacterSelectScene이 자기 repo로 다시 읽는다(불변 흐름).
    private let characterRepo = CharacterPreferenceRepository()
    /// Phase 10-2 — 그라데이션 배경 노드. didChangeSize 시 재생성을 위해 *참조 보관*.
    /// 옵셔널 — didMove 전엔 nil.
    private var gradientBackground: GradientBackgroundNode?
    /// Phase 10-2 — 음표 파티클 컨테이너. 씬 사이즈 의존 — didChangeSize 시 재생성.
    private var musicNoteEmitter: MusicNoteEmitterNode?

    // MARK: - Factory
    /// TitleScene.newTitleScene과 동일 패턴. .resizeFill로 view 크기에 자동 맞춤.
    class func newStartScene() -> StartScene {
        let scene = StartScene(size: CGSize(width: 1024, height: 768))
        scene.scaleMode = .resizeFill
        return scene
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .ganhoBgDeep        // 1프레임 fallback 톤. 그라데이션이 위에 덮음.
        setupGradientBackground()             // Phase 10-2 — zPos -20 (가장 뒤)
        setupOverlayPanel()                   // 반투명 검정 배경 + 카드 패널 (라벨/카드 *뒤*에 배치)
        setupMusicNoteEmitter()               // Phase 10-2 — zPos -15 (overlay 위, 패널 뒤)
        setupLabels()
        selectedDifficulty = difficultyRepo.current
        setupDifficultyCards()
        setupStoryBox()
        setupStartButton()
        attachStartButtonPulse()              // Phase 10-2 — 시작 버튼 호흡 pulse
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // Phase 10-2 — 그라데이션/음표 emitter는 sceneSize 의존 → 사이즈 변경 시 재생성.
        rebuildGradientBackground()
        rebuildMusicNoteEmitter()
        layoutLabels()
        layoutDifficultyCards()
        layoutStoryBox()
        layoutStartButton()
    }

    // MARK: - Setup (Phase 10-2 비주얼)
    /// Phase 10-2 — 세로 그라데이션 배경. tealDeep(상단) → teal(하단). zPos -20.
    /// didChangeSize에서 재생성하기 위해 인스턴스 참조 보관.
    private func setupGradientBackground() {
        let node = GradientBackgroundNode(
            size: size,
            topColor: .ganhoAccentTealDeep,
            bottomColor: .ganhoAccentTeal
        )
        node.position = CGPoint(x: frame.midX, y: frame.midY)
        gradientBackground = node
        addChild(node)
    }

    /// Phase 10-2 — 사이즈 변경 시 그라데이션 재생성. 기존 노드는 removeFromParent.
    private func rebuildGradientBackground() {
        gradientBackground?.removeFromParent()
        gradientBackground = nil
        setupGradientBackground()
    }

    /// Phase 10-2 — 음표 파티클 컨테이너 부착. SKAction.repeatForever로 자동 스폰 시작.
    private func setupMusicNoteEmitter() {
        let emitter = MusicNoteEmitterNode(sceneSize: size)
        // 원점은 씬 좌측 하단 (0,0) — emitter 내부 좌표계가 sceneSize 범위에 그대로 매핑.
        emitter.position = .zero
        musicNoteEmitter = emitter
        addChild(emitter)
    }

    /// Phase 10-2 — 사이즈 변경 시 emitter 재생성. 떠 있는 음표는 자가 정리됨.
    private func rebuildMusicNoteEmitter() {
        musicNoteEmitter?.stopEmitting()
        musicNoteEmitter?.removeAllChildren()
        musicNoteEmitter?.removeFromParent()
        musicNoteEmitter = nil
        setupMusicNoteEmitter()
    }

    // MARK: - Setup
    /// 원본 .game-overlay 톤 — 반투명 검정 배경 + 가운데 카드 패널. TitleScene과 동형.
    private func setupOverlayPanel() {
        let bg = SKSpriteNode(color: .ganhoUIOverlayBg, size: size)
        bg.position = CGPoint(x: frame.midX, y: frame.midY)
        bg.zPosition = -10
        bg.name = "overlayBackground"
        addChild(bg)

        let panelWidth = GameConfig.uiPanelCharacterMaxWidth
        let panelHeight: CGFloat = 480
        let panel = SKShapeNode(
            rectOf: CGSize(width: panelWidth, height: panelHeight),
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
        configureLabel(subtitleLabel, fontSize: GameConfig.startSceneSubtitleFontSize)
        configureLabel(bestLabel,     fontSize: GameConfig.titleBestFontSize)
        configureLabel(playsLabel,    fontSize: GameConfig.titlePlaysFontSize)
        subtitleLabel.fontColor = .ganhoUITextMuted   // 부제는 *조용한* 보조 톤
        // Phase 10-2 — BEST/PLAYS는 살구색 액센트. 부제는 muted 유지.
        bestLabel.fontColor = .ganhoAccentCoral
        playsLabel.fontColor = .ganhoAccentCoral
        let best = HighScoreRepository().current
        bestLabel.text = "BEST 🏆 \(best)"
        let plays = StatisticsRepository().current.playCount
        playsLabel.text = "PLAYS \(plays)"
        // Phase 10-2 — titleLabel 단독 addChild → GlowingTitleNode로 래핑한 노드 addChild.
        addChild(titleNode)
        addChild(subtitleLabel)
        addChild(bestLabel)
        addChild(playsLabel)
        layoutLabels()
    }

    /// 라벨 공통 스타일. TitleScene 패턴 동일.
    private func configureLabel(_ label: SKLabelNode, fontSize: CGFloat) {
        label.fontSize = fontSize
        label.fontColor = .ganhoPaper
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
    }

    private func layoutLabels() {
        // Phase 10-2 — 좌표 계산식은 *불변*. 적용 대상만 titleLabel → titleNode로 교체.
        titleNode.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.titleLabelOffsetY
        )
        subtitleLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.startSceneSubtitleOffsetY
        )
        // BEST/PLAYS는 상단 — 패널 위쪽 영역에 가로 2개.
        bestLabel.position = CGPoint(
            x: frame.midX - GameConfig.startSceneBestPlaysSpacing,
            y: frame.midY + GameConfig.startSceneBestPlaysTopMargin
        )
        playsLabel.position = CGPoint(
            x: frame.midX + GameConfig.startSceneBestPlaysSpacing,
            y: frame.midY + GameConfig.startSceneBestPlaysTopMargin
        )
    }

    // MARK: - Difficulty Cards
    /// 3 난이도 카드 생성 + addChild + 초기 선택 상태 적용. TitleScene 7-1 패턴 답습.
    private func setupDifficultyCards() {
        for id in Difficulty.allCases {
            let card = DifficultyCardNode(id: id)
            card.setSelected(id == selectedDifficulty)
            difficultyCards.append(card)
            addChild(card)
        }
        layoutDifficultyCards()
    }

    /// 3 카드 가로 일렬, frame.midX 기준 중앙 정렬.
    private func layoutDifficultyCards() {
        let count = difficultyCards.count
        guard count > 0 else { return }
        let width = GameConfig.difficultyCardWidth
        let spacing = GameConfig.difficultyCardSpacing
        let totalWidth = width * CGFloat(count) + spacing * CGFloat(count - 1)
        let startX = frame.midX - totalWidth / 2 + width / 2
        let y = frame.midY + GameConfig.difficultyCardOffsetY
        for (index, card) in difficultyCards.enumerated() {
            card.position = CGPoint(
                x: startX + CGFloat(index) * (width + spacing),
                y: y
            )
        }
    }

    /// 선택 난이도 변경 + 3 카드 일괄 갱신 + 디스크 저장.
    private func selectDifficulty(_ id: Difficulty) {
        selectedDifficulty = id
        difficultyRepo.save(id)
        for card in difficultyCards {
            card.setSelected(card.id == id)
        }
    }

    // MARK: - Story Box
    /// 스토리 박스 — 게임 소개 톤. addChild + layout 분리(다른 노드와 동일 패턴).
    private func setupStoryBox() {
        addChild(storyBox)
        layoutStoryBox()
    }

    private func layoutStoryBox() {
        storyBox.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.startSceneStoryBoxOffsetY
        )
    }

    // MARK: - Start Button
    /// 시작 버튼 — 명시 탭만 진행. addChild + layout 분리.
    private func setupStartButton() {
        addChild(startButton)
        layoutStartButton()
    }

    private func layoutStartButton() {
        startButton.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.startSceneStartButtonOffsetY
        )
    }

    /// Phase 10-2 — 시작 버튼에 호흡 pulse. 0.98 ↔ 1.02, 한 주기 2초.
    /// 외부에서 부착 — PrimaryButtonNode 내부 구조 변경 0.
    /// 씬 전환 시 transitionToNext에서 액션 키로 정리.
    private func attachStartButtonPulse() {
        let down = SKAction.scale(
            to: GameConfig.startButtonPulseScaleMin,
            duration: GameConfig.startButtonPulseHalfDuration
        )
        down.timingMode = .easeInEaseOut
        let up = SKAction.scale(
            to: GameConfig.startButtonPulseScaleMax,
            duration: GameConfig.startButtonPulseHalfDuration
        )
        up.timingMode = .easeInEaseOut
        let pulse = SKAction.sequence([down, up])
        startButton.run(
            SKAction.repeatForever(pulse),
            withKey: "startButtonPulse"
        )
    }

    // MARK: - Touch
    /// 우선순위: 난이도 카드 → 시작 버튼.
    /// 카드 외 영역 탭은 무동작 — "어디든 탭" 패턴 의도적 제거.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        // 1) 난이도 카드 hit test — 매치 시 select + 저장 + return.
        for card in difficultyCards {
            if card.contains(location) {
                selectDifficulty(card.id)
                return
            }
        }
        // 2) 시작 버튼 hit test — 매치 시 다음 단계로.
        if startButton.contains(location) {
            transitionToNext()
        }
    }

    /// 시작 버튼 탭 시 다음 단계로 전환.
    /// Phase 10-2 — *게임플레이 동작 불변* — selectedDifficulty 전달, presentScene 대상,
    /// sceneTransitionDuration 모두 그대로. 카드/스토리/버튼 슬라이드업 + fade-out *prelude*만 추가.
    private func transitionToNext() {
        guard let view = self.view else { return }
        isTransitioning = true

        // Phase 10-2 — 시작 버튼 pulse 정리.
        startButton.removeAction(forKey: "startButtonPulse")
        // Phase 10-2 — 음표 emitter 정지(추가 스폰 중단). 떠 있는 음표는 자가 정리.
        musicNoteEmitter?.stopEmitting()

        // Phase 10-2 — 카드/스토리/시작 버튼 *살짝 위로* 슬라이드 + fadeOut.
        let slideUp = SKAction.moveBy(
            x: 0,
            y: GameConfig.startSceneExitSlideDistance,
            duration: GameConfig.startSceneExitSlideDuration
        )
        slideUp.timingMode = .easeIn
        let fadeOut = SKAction.fadeOut(
            withDuration: GameConfig.startSceneExitSlideDuration
        )
        // 같은 액션 인스턴스를 여러 노드에 run하면 SpriteKit이 내부적으로 복사 — 안전.
        let exit = SKAction.group([slideUp, fadeOut])
        for card in difficultyCards { card.run(exit) }
        storyBox.run(exit)
        startButton.run(exit)

        // Phase 10-2 — 슬라이드 완료 후 presentScene. *씬 전환 대상/난이도 전달 불변*.
        let wait = SKAction.wait(forDuration: GameConfig.startSceneExitSlideDuration)
        let present = SKAction.run { [weak self, weak view] in
            guard let self = self, let view = view else { return }
            let nextScene = CharacterSelectScene.newCharacterSelectScene(
                difficulty: self.selectedDifficulty
            )
            let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
            view.presentScene(nextScene, transition: fade)
        }
        run(SKAction.sequence([wait, present]))

        // characterRepo는 다음 씬이 다시 .current로 읽으므로 본 씬에서 별도 전달 불필요.
        // 정적 의존 회피 — Swift 컴파일러 unused warning 방지를 위해 명시 참조.
        _ = characterRepo
    }
}
