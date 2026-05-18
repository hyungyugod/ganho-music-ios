//
//  SkillExplanationScene.swift
//  GanhoMusic Shared
//
//  Phase 10-1c · 시작 시퀀스 3단계 — 큰 아바타 + 스킬명 + 설명 + 조작 안내 + 뒤로/시작 버튼
//
//  characterID + difficulty 둘 다 init 인자로 *불변 입력*. 김간호는 이 씬을 *스킵*하므로
//  실제 도달하는 캐릭터는 .jung/.geon/.im/.lee 4명. (방어적으로 .none 분기도 빈 문자열 처리.)
//  큰 아바타는 PixelSpriteRenderer + PixelSprite.data + PixelPalette.palette 재사용 —
//  PlayerNode 시각 자산을 *7.5배 확대*로 그대로 활용 (인프라 재사용 0건 변경).
//

import SpriteKit

/// 스킬 설명 단일 결정 씬. 화면 구성은 헤더 + 큰 아바타(좌) + 스킬명/설명/조작 안내(우) + 뒤로/시작 2 버튼.
/// characterID/difficulty는 모두 *불변 입력*. 사용자는 *수정 불가* — 뒤로 가서 캐릭터 다시 선택.
final class SkillExplanationScene: SKScene {

    // MARK: - Properties
    private let characterID: CharacterID
    private let difficulty: Difficulty
    private var isTransitioning = false
    private let headerLabel = SKLabelNode(text: GameConfig.skillExplanationHeaderText)
    /// 큰 아바타 — PixelSpriteRenderer 텍스처를 7.5배 확대 표시. SKSpriteNode 1개.
    private let avatarSprite: SKSpriteNode
    private let skillNameLabel = SKLabelNode(text: "")
    /// 스킬 설명 본문 박스 — StoryBoxNode 재사용. lazy 초기화 — characterID 의존.
    private lazy var skillStoryBox: StoryBoxNode =
        StoryBoxNode(body: characterID.skill.fullDescription)
    private let controlHintLabel = SKLabelNode(text: GameConfig.skillExplanationControlHintText)
    private let backButton = BackButtonNode(text: "← 캐릭터 다시")
    private let startButton = PrimaryButtonNode(text: "시작")

    // MARK: - Factory
    /// characterID + difficulty 둘 다 *명시 주입*. CharacterSelectScene이 유일 호출자.
    class func newSkillExplanationScene(
        characterID: CharacterID,
        difficulty: Difficulty
    ) -> SkillExplanationScene {
        let scene = SkillExplanationScene(
            size: CGSize(width: 1024, height: 768),
            characterID: characterID,
            difficulty: difficulty
        )
        scene.scaleMode = .resizeFill
        return scene
    }

    // MARK: - Init
    /// 두 인자 모두 `let` 이므로 super.init 전에 저장. 아바타 텍스처도 init 시점에 빌드.
    /// 픽셀 텍스처는 PixelSpriteRenderer.texture가 .nearest 필터를 자동 설정 → 7.5배 확대 시에도 픽셀 perfect.
    private init(size: CGSize, characterID: CharacterID, difficulty: Difficulty) {
        self.characterID = characterID
        self.difficulty = difficulty
        // 아바타 텍스처 — down 방향 idle 프레임 (정면). PlayerNode.update와 무관한 *정지* 표현.
        let frame = PixelSprite.data(
            for: characterID,
            direction: .down,
            frame: .idle
        )
        let palette = PixelPalette.palette(for: characterID)
        let texture = PixelSpriteRenderer.texture(from: frame, palette: palette)
        self.avatarSprite = SKSpriteNode(texture: texture)
        self.avatarSprite.size = CGSize(
            width: GameConfig.skillExplanationAvatarWidth,
            height: GameConfig.skillExplanationAvatarHeight
        )
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
        setupAvatar()
        setupSkillName()
        setupSkillBox()
        setupControlHint()
        setupButtons()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutHeader()
        layoutAvatar()
        layoutSkillName()
        layoutSkillBox()
        layoutControlHint()
        layoutButtons()
    }

    // MARK: - Setup
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
        headerLabel.fontSize = GameConfig.skillExplanationHeaderFontSize
        headerLabel.fontColor = .ganhoPaper
        headerLabel.horizontalAlignmentMode = .center
        headerLabel.verticalAlignmentMode = .center
        addChild(headerLabel)
        layoutHeader()
    }

    private func layoutHeader() {
        headerLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.skillExplanationHeaderOffsetY
        )
    }

    private func setupAvatar() {
        addChild(avatarSprite)
        layoutAvatar()
    }

    private func layoutAvatar() {
        avatarSprite.position = CGPoint(
            x: frame.midX + GameConfig.skillExplanationAvatarOffsetX,
            y: frame.midY + GameConfig.skillExplanationAvatarOffsetY
        )
    }

    private func setupSkillName() {
        skillNameLabel.text = characterID.skill.displayName
        skillNameLabel.fontSize = GameConfig.skillExplanationSkillNameFontSize
        skillNameLabel.fontColor = .ganhoUIBrandLight
        skillNameLabel.horizontalAlignmentMode = .center
        skillNameLabel.verticalAlignmentMode = .center
        addChild(skillNameLabel)
        layoutSkillName()
    }

    private func layoutSkillName() {
        skillNameLabel.position = CGPoint(
            x: frame.midX + GameConfig.skillExplanationSkillNameOffsetX,
            y: frame.midY + GameConfig.skillExplanationSkillNameOffsetY
        )
    }

    private func setupSkillBox() {
        addChild(skillStoryBox)
        layoutSkillBox()
    }

    private func layoutSkillBox() {
        skillStoryBox.position = CGPoint(
            x: frame.midX + GameConfig.skillExplanationStoryBoxOffsetX,
            y: frame.midY + GameConfig.skillExplanationStoryBoxOffsetY
        )
    }

    private func setupControlHint() {
        controlHintLabel.fontSize = GameConfig.skillExplanationControlHintFontSize
        controlHintLabel.fontColor = .ganhoUITextMuted
        controlHintLabel.horizontalAlignmentMode = .center
        controlHintLabel.verticalAlignmentMode = .center
        addChild(controlHintLabel)
        layoutControlHint()
    }

    private func layoutControlHint() {
        controlHintLabel.position = CGPoint(
            x: frame.midX + GameConfig.skillExplanationStoryBoxOffsetX,
            y: frame.midY + GameConfig.skillExplanationControlHintOffsetY
        )
    }

    private func setupButtons() {
        addChild(backButton)
        addChild(startButton)
        layoutButtons()
    }

    private func layoutButtons() {
        let y = frame.midY + GameConfig.skillExplanationButtonRowOffsetY
        let half = GameConfig.characterSelectButtonSpacing / 2  // 같은 spacing 재사용 — 시각 일관성.
        backButton.position = CGPoint(x: frame.midX - half, y: y)
        startButton.position = CGPoint(x: frame.midX + half, y: y)
    }

    // MARK: - Touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if backButton.contains(location) {
            transitionToCharacterSelect()
            return
        }
        if startButton.contains(location) {
            transitionToGame()
        }
    }

    private func transitionToCharacterSelect() {
        guard let view = self.view else { return }
        isTransitioning = true
        let scene = CharacterSelectScene.newCharacterSelectScene(difficulty: difficulty)
        let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
        view.presentScene(scene, transition: fade)
    }

    private func transitionToGame() {
        guard let view = self.view else { return }
        isTransitioning = true
        let gameScene = GameScene.newGameScene(
            characterID: characterID,
            difficulty: difficulty
        )
        let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
        view.presentScene(gameScene, transition: fade)
    }
}
