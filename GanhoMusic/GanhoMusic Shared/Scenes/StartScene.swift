//
//  StartScene.swift
//  GanhoMusic Shared
//
//  Phase 10-1a · 시작 시퀀스 1단계 — 제목 + BEST/PLAYS + 스토리 박스 + 난이도 3장 + 시작 버튼
//
//  TitleScene의 구조를 답습하되 *난이도 선택*에만 집중. 캐릭터 카드는 다음 단계(CharacterSelectScene)로 이전.
//  "어디든 탭" 패턴을 제거 — 시작 버튼 명시 탭만 진행.
//  10-1b 완성 시점부터 "시작" → CharacterSelectScene 전환. 10-1a 임시: GameScene 직진(repo current).
//

import SpriteKit

/// 앱 첫 진입 씬. 제목 + BEST/PLAYS + 부제 + 스토리 박스 + 난이도 3장 + 시작 버튼.
/// 카메라/월드 개념 없음 — 라벨은 frame.midX/midY 기준 직접 배치.
/// TitleScene과 동형 구조 — overlay 패널, prompt blink 등 패턴 답습.
final class StartScene: SKScene {

    // MARK: - Properties
    /// 씬 전환이 시작됐는지 여부. true가 되면 추가 탭은 무시 — 더블 enter 방지.
    private var isTransitioning = false
    private let titleLabel    = SKLabelNode(text: "김간호는 음악박사")
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

    // MARK: - Factory
    /// TitleScene.newTitleScene과 동일 패턴. .resizeFill로 view 크기에 자동 맞춤.
    class func newStartScene() -> StartScene {
        let scene = StartScene(size: CGSize(width: 1024, height: 768))
        scene.scaleMode = .resizeFill
        return scene
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .ganhoBgDeep
        setupOverlayPanel()              // 반투명 검정 배경 + 카드 패널 (라벨/카드 *뒤*에 배치)
        setupLabels()
        selectedDifficulty = difficultyRepo.current
        setupDifficultyCards()
        setupStoryBox()
        setupStartButton()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutLabels()
        layoutDifficultyCards()
        layoutStoryBox()
        layoutStartButton()
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
        configureLabel(titleLabel,    fontSize: GameConfig.titleFontSize)
        configureLabel(subtitleLabel, fontSize: GameConfig.startSceneSubtitleFontSize)
        configureLabel(bestLabel,     fontSize: GameConfig.titleBestFontSize)
        configureLabel(playsLabel,    fontSize: GameConfig.titlePlaysFontSize)
        subtitleLabel.fontColor = .ganhoUITextMuted   // 부제는 *조용한* 보조 톤
        let best = HighScoreRepository().current
        bestLabel.text = "BEST 🏆 \(best)"
        let plays = StatisticsRepository().current.playCount
        playsLabel.text = "PLAYS \(plays)"
        addChild(titleLabel)
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
        titleLabel.position = CGPoint(
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
    /// 10-1a 시점: 임시로 GameScene 직진. 10-1b 완성 시점에 CharacterSelectScene으로 교체.
    private func transitionToNext() {
        guard let view = self.view else { return }
        isTransitioning = true
        let nextScene = CharacterSelectScene.newCharacterSelectScene(
            difficulty: selectedDifficulty
        )
        let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
        view.presentScene(nextScene, transition: fade)
        // characterRepo는 다음 씬이 다시 .current로 읽으므로 본 씬에서 별도 전달 불필요.
        // 정적 의존 회피 — Swift 컴파일러 unused warning 방지를 위해 명시 참조.
        _ = characterRepo
    }
}
