//
//  CharacterSelectScene.swift
//  GanhoMusic Shared
//
//  Phase 10-1b · 시작 시퀀스 2단계 — 캐릭터 5장 + 태그 라벨 + 뒤로/시작 버튼 2개
//
//  StartScene → 본 씬 → SkillExplanationScene(or GameScene .kim 스킵).
//  difficulty는 init 인자로 받아 *불변 상태*로 보관. Swift 컴파일 타임 강제.
//  CharacterCardNode 내부 변경 0건 — 카드 *외부*에 태그 SKLabelNode를 별도 생성하여 카드 아래에 배치.
//

import SpriteKit

/// 캐릭터 선택 단일 결정 씬. 화면 구성은 헤더 + 5 카드 가로 1줄 + 5 태그 라벨 + 뒤로/시작 2 버튼.
/// difficulty는 *불변 입력* — init 주입 후 그대로 다음 씬으로 전달.
/// 선택된 캐릭터는 즉시 CharacterPreferenceRepository에 save하여 다음 진입 시 복원.
final class CharacterSelectScene: SKScene {

    // MARK: - Properties
    /// init 주입된 난이도. 불변. 다음 씬(SkillExplanation 또는 GameScene)으로 그대로 전달.
    private let difficulty: Difficulty
    /// 씬 전환 가드.
    private var isTransitioning = false
    private let headerLabel = SKLabelNode(text: GameConfig.characterSelectHeaderText)
    /// 현재 선택된 캐릭터. 기본 .kim. didMove에서 repo.current로 복원.
    private var selectedCharacterID: CharacterID = .kim
    /// 5 카드 인스턴스 보관. setup/layout/hit test에 재사용.
    private var characterCards: [CharacterCardNode] = []
    /// 5 태그 라벨 — 카드 *외부*. CharacterCardNode 내부 변경 0건 정책.
    private var tagLabels: [CharacterID: SKLabelNode] = [:]
    private let backButton = BackButtonNode(text: "← 난이도 다시")
    private let confirmButton = PrimaryButtonNode(text: "이 친구로 시작")
    private let preferenceRepo = CharacterPreferenceRepository()

    // MARK: - Factory
    /// difficulty 인자를 받아 인스턴스 생성. StartScene이 유일 호출자.
    class func newCharacterSelectScene(difficulty: Difficulty) -> CharacterSelectScene {
        let scene = CharacterSelectScene(
            size: CGSize(width: 1024, height: 768),
            difficulty: difficulty
        )
        scene.scaleMode = .resizeFill
        return scene
    }

    // MARK: - Init
    /// difficulty는 `let` 이므로 super.init 전에 저장. ResultScene 동형 패턴.
    private init(size: CGSize, difficulty: Difficulty) {
        self.difficulty = difficulty
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .ganhoBgDeep
        setupOverlayPanel()
        setupHeader()
        selectedCharacterID = preferenceRepo.current
        setupCharacterCards()
        setupTagLabels()
        setupButtons()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutHeader()
        layoutCharacterCards()
        layoutTagLabels()
        layoutButtons()
    }

    // MARK: - Setup
    /// StartScene과 동형 overlay 패널. *재사용 노드 없음* — 같은 SKShapeNode 패턴 답습.
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

    private func setupHeader() {
        headerLabel.fontSize = GameConfig.characterSelectHeaderFontSize
        headerLabel.fontColor = .ganhoPaper
        headerLabel.horizontalAlignmentMode = .center
        headerLabel.verticalAlignmentMode = .center
        addChild(headerLabel)
        layoutHeader()
    }

    private func layoutHeader() {
        headerLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.characterSelectHeaderOffsetY
        )
    }

    /// 5 카드 setup + 초기 선택 상태 적용. TitleScene 5-1 패턴 답습.
    private func setupCharacterCards() {
        for id in CharacterID.allCases {
            let card = CharacterCardNode(id: id)
            card.setSelected(id == selectedCharacterID)
            characterCards.append(card)
            addChild(card)
        }
        layoutCharacterCards()
    }

    private func layoutCharacterCards() {
        let count = characterCards.count
        guard count > 0 else { return }
        let width = GameConfig.characterCardWidth
        let spacing = GameConfig.characterCardSpacing
        let totalWidth = width * CGFloat(count) + spacing * CGFloat(count - 1)
        let startX = frame.midX - totalWidth / 2 + width / 2
        let y = frame.midY + GameConfig.characterSelectCardOffsetY
        for (index, card) in characterCards.enumerated() {
            card.position = CGPoint(
                x: startX + CGFloat(index) * (width + spacing),
                y: y
            )
        }
    }

    /// 5 태그 라벨 — 카드 *외부*. CharacterCardNode 내부 변경 0건 정책.
    /// 각 카드와 같은 x 좌표 + characterSelectTagOffsetY만큼 아래 위치.
    private func setupTagLabels() {
        for id in CharacterID.allCases {
            let label = SKLabelNode(text: id.tag)
            label.fontSize = GameConfig.characterSelectTagFontSize
            label.fontColor = .ganhoUITextMuted
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.name = "characterTag_\(id.rawValue)"
            tagLabels[id] = label
            addChild(label)
        }
        layoutTagLabels()
    }

    /// 태그 라벨 위치 — 각 카드 위치 기준 아래쪽. 카드 layout과 같은 startX 계산.
    private func layoutTagLabels() {
        let count = characterCards.count
        guard count > 0 else { return }
        let width = GameConfig.characterCardWidth
        let spacing = GameConfig.characterCardSpacing
        let totalWidth = width * CGFloat(count) + spacing * CGFloat(count - 1)
        let startX = frame.midX - totalWidth / 2 + width / 2
        let cardY = frame.midY + GameConfig.characterSelectCardOffsetY
        let tagY = cardY + GameConfig.characterSelectTagOffsetY
        for (index, card) in characterCards.enumerated() {
            guard let label = tagLabels[card.id] else { continue }
            label.position = CGPoint(
                x: startX + CGFloat(index) * (width + spacing),
                y: tagY
            )
        }
    }

    private func setupButtons() {
        addChild(backButton)
        addChild(confirmButton)
        layoutButtons()
    }

    /// 2 버튼 가로 일렬, frame.midX 기준 ± spacing/2.
    private func layoutButtons() {
        let y = frame.midY + GameConfig.characterSelectButtonRowOffsetY
        let half = GameConfig.characterSelectButtonSpacing / 2
        backButton.position = CGPoint(x: frame.midX - half, y: y)
        confirmButton.position = CGPoint(x: frame.midX + half, y: y)
    }

    // MARK: - Selection
    /// 선택 캐릭터 변경 + 5 카드 알파/scale 일괄 갱신 + 디스크 저장.
    private func select(_ id: CharacterID) {
        selectedCharacterID = id
        preferenceRepo.save(id)
        for card in characterCards {
            card.setSelected(card.id == id)
        }
    }

    // MARK: - Touch
    /// 우선순위: 캐릭터 카드 → 뒤로 버튼 → 시작 버튼.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        // 1) 카드 hit test.
        for card in characterCards {
            if card.contains(location) {
                select(card.id)
                return
            }
        }
        // 2) 뒤로 버튼.
        if backButton.contains(location) {
            transitionToStart()
            return
        }
        // 3) 시작 버튼 — .kim이면 GameScene 직진, 그 외는 SkillExplanation.
        if confirmButton.contains(location) {
            transitionToNext()
        }
    }

    /// 뒤로 가기 — StartScene으로.
    private func transitionToStart() {
        guard let view = self.view else { return }
        isTransitioning = true
        let scene = StartScene.newStartScene()
        let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
        view.presentScene(scene, transition: fade)
    }

    /// 시작 — .kim은 GameScene 직진(스킬 없음 = 스킬 화면 스킵), 그 외는 SkillExplanation.
    /// SPEC §3 4단계 흐름 + §"기능 3" 김간호 스킵 정책 일관 표현.
    private func transitionToNext() {
        guard let view = self.view else { return }
        isTransitioning = true
        let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
        switch selectedCharacterID {
        case .kim:
            // 김간호 — 스킬 화면 스킵 → GameScene 직진.
            let gameScene = GameScene.newGameScene(
                characterID: selectedCharacterID,
                difficulty: difficulty
            )
            view.presentScene(gameScene, transition: fade)
        case .jung, .geon, .im, .lee:
            // 스킬 보유 캐릭터 — SkillExplanationScene으로.
            let scene = SkillExplanationScene.newSkillExplanationScene(
                characterID: selectedCharacterID,
                difficulty: difficulty
            )
            view.presentScene(scene, transition: fade)
        }
    }
}
