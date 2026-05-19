//
//  SkillExplanationScene.swift
//  GanhoMusic Shared
//
//  Phase 10-1c · 시작 시퀀스 3단계 — 큰 아바타 + 스킬명 + 설명 + 조작 안내 + 뒤로/시작 버튼
//  Sprint 2 · 메뉴 v2 리스킨 — 3-stop warm gradient + AccentLine 헤더 + GlassPill 뒤로 +
//               DarkContextChip 브레드크럼 + 좌측 글래스 아바타 카드 + 우측 코랄 메타 + Jua 36pt 스킬명 +
//               인용 박스(좌 3px 코랄 보더) + 메타 칩 3개 + 컨트롤 힌트 "B" 키 마크 + 하단 버튼 2개.
//
//  characterID + difficulty 둘 다 init 인자로 *불변 입력*. 김간호는 이 씬을 *스킵*하므로
//  실제 도달하는 캐릭터는 .jung/.geon/.im/.lee 4명. (방어적으로 .none 분기도 빈 문자열 처리.)
//  큰 아바타는 PixelSpriteRenderer + PixelSprite.data + PixelPalette.palette 재사용 —
//  PlayerNode 시각 자산을 *그대로 활용* (인프라 재사용 0건 변경).
//

import SpriteKit

/// 스킬 설명 단일 결정 씬. v2 리스킨 — 좌측 글래스 아바타 카드 + 우측 코랄 메타/Jua 스킬명/인용 박스/메타 칩 3개.
/// characterID/difficulty는 모두 *불변 입력*. 사용자는 *수정 불가* — 뒤로 가서 캐릭터 다시 선택.
final class SkillExplanationScene: SKScene {

    // MARK: - Properties
    private let characterID: CharacterID
    private let difficulty: Difficulty
    private var isTransitioning = false
    /// Sprint 2 — 헤더 라벨(Jua, navyDeep).
    private let headerLabel = SKLabelNode(text: GameConfig.skillExplanationHeaderText)
    /// Sprint 2 — 헤더 AccentLine + Gowun Dodum 부제.
    private let accentLine = AccentLineNode()
    private let headerSubLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    /// Sprint 2 — 상단 좌우 GlassPill 뒤로 + DarkContextChip 브레드크럼.
    private var topBackPill: GlassPillNode?
    private var breadcrumbChip: DarkContextChipNode?
    /// 큰 아바타 — PixelSpriteRenderer 텍스처. SKSpriteNode 1개. 보존.
    private let avatarSprite: SKSpriteNode
    /// Sprint 2 — 좌측 아바타 글래스 카드(반투명 흰색 + 코랄 0.3 stroke).
    private var avatarCard: SKShapeNode?
    /// Sprint 2 — 아바타 카드 안 상단 코랄 이름 뱃지.
    private var avatarNameBadge: SKShapeNode?
    private let avatarNameLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    /// Sprint 2 — 아바타 카드 아래 role 라벨(Gowun Dodum) + 속도 칩.
    private let avatarRoleLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    private var avatarSpeedChip: DarkContextChipNode?
    /// Sprint 2 — 우측 메타 라벨(코랄, Gowun Dodum 11pt).
    private let metaLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    /// Sprint 2 — 우측 Jua 36pt 스킬명.
    private let skillNameLabel = SKLabelNode(text: "")
    /// Sprint 2 — 우측 인용 박스(좌 3px 코랄 보더 + 글래스 fill).
    private var skillQuoteBox: SKShapeNode?
    private let skillQuoteLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    /// Sprint 2 — 우측 메타 칩 3개(CD / 범위 / 즉발).
    private var statChips: [DarkContextChipNode] = []
    /// Sprint 2 — 컨트롤 힌트 다크 컨테이너 + "B" 키 원 + 라벨.
    private var controlHintContainer: SKShapeNode?
    private let controlHintKeyCircle = SKShapeNode(circleOfRadius: GameConfig.skillExplanationControlHintKeyCircleRadius)
    private let controlHintKeyLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    private let controlHintLabel = SKLabelNode(text: GameConfig.skillExplanationControlHintText)
    /// 하단 BackButtonNode "← 캐릭터 다시" — 기능 K6 — 기존 좌우 배치 유지.
    private let backButton = BackButtonNode(text: "← 캐릭터 다시")
    private let startButton = PrimaryButtonNode(text: "시작")
    /// Sprint 2 — 그라데이션 배경 노드.
    private var gradientBackground: GradientBackgroundNode?

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
    /// Sprint 4 (walk 미적용 버전) — PNG 우선·픽셀 fallback 패턴. PlayerNode.loadTexture와 동형.
    private init(size: CGSize, characterID: CharacterID, difficulty: Difficulty) {
        self.characterID = characterID
        self.difficulty = difficulty
        // Sprint 4 — v6 PNG 자산(Assets.xcassets/Characters/) 우선 사용, 미보유 캐릭터는 픽셀 fallback.
        let texture: SKTexture = {
            let pngName = "\(characterID.rawValue)_down_idle_1"
            if UIImage(named: pngName) != nil {
                let tex = SKTexture(imageNamed: pngName)
                tex.filteringMode = .linear  // 부드러운 스케일링
                return tex
            }
            // Fallback — 픽셀 렌더링 (.nearest 자동 설정 → 7.5배 확대 시에도 픽셀 perfect)
            let frame = PixelSprite.data(for: characterID, direction: .down, frame: .idle)
            let palette = PixelPalette.palette(for: characterID)
            return PixelSpriteRenderer.texture(from: frame, palette: palette)
        }()
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
        backgroundColor = .ganhoBgWarmTop
        setupGradientBackground()
        setupHeader()
        setupTopBar()
        setupAvatarCard()
        setupAvatar()
        setupAvatarNameBadge()
        setupAvatarRoleAndSpeed()
        setupMetaLabel()
        setupSkillName()
        setupSkillQuoteBox()
        setupStatChips()
        setupControlHint()
        setupButtons()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        rebuildGradientBackground()
        layoutHeader()
        layoutTopBar()
        layoutAvatarCard()
        layoutAvatar()
        layoutAvatarNameBadge()
        layoutAvatarRoleAndSpeed()
        layoutMetaLabel()
        layoutSkillName()
        layoutSkillQuoteBox()
        layoutStatChips()
        layoutControlHint()
        layoutButtons()
    }

    // MARK: - Setup (Sprint 2 · Background)
    private func setupGradientBackground() {
        let node = GradientBackgroundNode.threeStop(
            size: size,
            topColor: .ganhoBgWarmTop,
            midColor: .ganhoBgWarmMid,
            bottomColor: .ganhoBgWarmBottom
        )
        node.position = CGPoint(x: frame.midX, y: frame.midY)
        gradientBackground = node
        addChild(node)
    }

    private func rebuildGradientBackground() {
        gradientBackground?.removeFromParent()
        gradientBackground = nil
        setupGradientBackground()
    }

    // MARK: - Setup (Sprint 2 · Header)
    private func setupHeader() {
        headerLabel.fontName = GameConfig.fontDisplay
        headerLabel.fontSize = GameConfig.skillExplanationHeaderFontSize
        headerLabel.fontColor = .ganhoNavyDeep
        headerLabel.horizontalAlignmentMode = .center
        headerLabel.verticalAlignmentMode = .center
        addChild(headerLabel)

        headerSubLabel.text = GameConfig.skillExplanationHeaderSubText
        headerSubLabel.fontSize = GameConfig.skillExplanationHeaderSubFontSize
        headerSubLabel.fontColor = .ganhoNavyMuted
        headerSubLabel.horizontalAlignmentMode = .center
        headerSubLabel.verticalAlignmentMode = .center
        addChild(headerSubLabel)

        addChild(accentLine)
        layoutHeader()
    }

    private func layoutHeader() {
        let centerX = frame.midX
        let baseY = frame.midY + GameConfig.skillExplanationHeaderOffsetY
        headerLabel.position = CGPoint(x: centerX, y: baseY)
        headerSubLabel.position = CGPoint(
            x: centerX,
            y: baseY + GameConfig.skillExplanationHeaderSubOffsetY
        )
        accentLine.position = CGPoint(
            x: centerX,
            y: baseY + GameConfig.skillExplanationAccentLineOffsetY
        )
    }

    // MARK: - Setup (Sprint 2 · Top Bar)
    private func setupTopBar() {
        let back = GlassPillNode(
            text: GameConfig.skillExplanationBackPillText,
            size: CGSize(
                width: GameConfig.skillExplanationBackPillWidth,
                height: GameConfig.skillExplanationBackPillHeight
            )
        )
        topBackPill = back
        addChild(back)

        let chip = DarkContextChipNode(
            label: "\(difficulty.shortName) · \(characterID.displayName)",
            badge: GameConfig.skillExplanationBreadcrumbBadge
        )
        breadcrumbChip = chip
        addChild(chip)
        layoutTopBar()
    }

    private func layoutTopBar() {
        let y = frame.maxY - GameConfig.skillExplanationTopBarMarginY
        topBackPill?.position = CGPoint(
            x: frame.minX + GameConfig.skillExplanationTopBarMarginX
                + GameConfig.skillExplanationBackPillWidth / 2,
            y: y
        )
        if let chip = breadcrumbChip {
            let halfWidth = chip.calculateAccumulatedFrame().width / 2
            chip.position = CGPoint(
                x: frame.maxX - GameConfig.skillExplanationTopBarMarginX - halfWidth,
                y: y
            )
        }
    }

    // MARK: - Setup (Sprint 2 · Avatar Card)
    private func setupAvatarCard() {
        let cardSize = CGSize(
            width: GameConfig.skillExplanationAvatarCardWidth,
            height: GameConfig.skillExplanationAvatarCardHeight
        )
        let card = SKShapeNode(
            rectOf: cardSize,
            cornerRadius: GameConfig.skillExplanationAvatarCardCornerRadius
        )
        card.fillColor = UIColor.white
            .withAlphaComponent(GameConfig.skillExplanationAvatarCardFillAlpha)
        card.strokeColor = UIColor.ganhoCoralPrimary
            .withAlphaComponent(GameConfig.skillExplanationAvatarCardStrokeAlpha)
        card.lineWidth = GameConfig.skillExplanationAvatarCardStrokeWidth
        card.zPosition = 80
        card.name = "avatarCard"
        avatarCard = card
        addChild(card)
        layoutAvatarCard()
    }

    private func layoutAvatarCard() {
        avatarCard?.position = CGPoint(
            x: frame.midX + GameConfig.skillExplanationAvatarCardOffsetX,
            y: frame.midY + GameConfig.skillExplanationAvatarCardOffsetY
        )
    }

    private func setupAvatar() {
        avatarSprite.zPosition = 100  // 카드 위.
        addChild(avatarSprite)
        layoutAvatar()
    }

    private func layoutAvatar() {
        avatarSprite.position = CGPoint(
            x: frame.midX + GameConfig.skillExplanationAvatarCardOffsetX,
            y: frame.midY + GameConfig.skillExplanationAvatarCardOffsetY
        )
    }

    // MARK: - Setup (Sprint 2 · Avatar Name Badge)
    private func setupAvatarNameBadge() {
        let badgeSize = CGSize(
            width: GameConfig.skillExplanationAvatarNameBadgeWidth,
            height: GameConfig.skillExplanationAvatarNameBadgeHeight
        )
        let badge = SKShapeNode(
            rectOf: badgeSize,
            cornerRadius: badgeSize.height / 2
        )
        badge.fillColor = .ganhoCoralPrimary
        badge.strokeColor = .clear
        badge.lineWidth = 0
        badge.zPosition = 110
        badge.name = "avatarNameBadge"
        avatarNameBadge = badge
        addChild(badge)

        avatarNameLabel.text = characterID.displayName
        avatarNameLabel.fontSize = GameConfig.skillExplanationAvatarNameBadgeFontSize
        avatarNameLabel.fontColor = .white
        avatarNameLabel.horizontalAlignmentMode = .center
        avatarNameLabel.verticalAlignmentMode = .center
        avatarNameLabel.zPosition = 111
        addChild(avatarNameLabel)
        layoutAvatarNameBadge()
    }

    private func layoutAvatarNameBadge() {
        let baseX = frame.midX + GameConfig.skillExplanationAvatarCardOffsetX
        let baseY = frame.midY + GameConfig.skillExplanationAvatarCardOffsetY
        let badgeY = baseY + GameConfig.skillExplanationAvatarNameBadgeOffsetY
        avatarNameBadge?.position = CGPoint(x: baseX, y: badgeY)
        avatarNameLabel.position = CGPoint(x: baseX, y: badgeY)
    }

    // MARK: - Setup (Sprint 2 · Role + Speed Chip)
    private func setupAvatarRoleAndSpeed() {
        avatarRoleLabel.text = characterID.tag
        avatarRoleLabel.fontSize = GameConfig.skillExplanationAvatarRoleFontSize
        avatarRoleLabel.fontColor = .ganhoNavyMuted
        avatarRoleLabel.horizontalAlignmentMode = .center
        avatarRoleLabel.verticalAlignmentMode = .center
        avatarRoleLabel.zPosition = 110
        addChild(avatarRoleLabel)

        let speedText = String(format: "×%.2f", Double(characterID.playerSpeedMultiplier))
        let chip = DarkContextChipNode(label: "속도", badge: speedText)
        avatarSpeedChip = chip
        addChild(chip)
        layoutAvatarRoleAndSpeed()
    }

    private func layoutAvatarRoleAndSpeed() {
        let baseX = frame.midX + GameConfig.skillExplanationAvatarCardOffsetX
        let baseY = frame.midY + GameConfig.skillExplanationAvatarCardOffsetY
        avatarRoleLabel.position = CGPoint(
            x: baseX,
            y: baseY + GameConfig.skillExplanationAvatarRoleOffsetY
        )
        avatarSpeedChip?.position = CGPoint(
            x: baseX,
            y: baseY + GameConfig.skillExplanationAvatarSpeedChipOffsetY
        )
    }

    // MARK: - Setup (Sprint 2 · Right Side Meta + Skill Name)
    private func setupMetaLabel() {
        metaLabel.text = "\(characterID.displayName)의 스킬"
        metaLabel.fontSize = GameConfig.skillExplanationMetaLabelFontSize
        metaLabel.fontColor = .ganhoCoralPrimary
        metaLabel.horizontalAlignmentMode = .center
        metaLabel.verticalAlignmentMode = .center
        metaLabel.zPosition = 100
        addChild(metaLabel)
        layoutMetaLabel()
    }

    private func layoutMetaLabel() {
        metaLabel.position = CGPoint(
            x: frame.midX + GameConfig.skillExplanationMetaLabelOffsetX,
            y: frame.midY + GameConfig.skillExplanationMetaLabelOffsetY
        )
    }

    private func setupSkillName() {
        skillNameLabel.text = characterID.skill.displayName
        skillNameLabel.fontName = GameConfig.fontDisplay
        skillNameLabel.fontSize = GameConfig.skillExplanationSkillNameFontSize
        skillNameLabel.fontColor = .ganhoNavyDeep
        skillNameLabel.horizontalAlignmentMode = .center
        skillNameLabel.verticalAlignmentMode = .center
        skillNameLabel.zPosition = 100
        addChild(skillNameLabel)
        layoutSkillName()
    }

    private func layoutSkillName() {
        skillNameLabel.position = CGPoint(
            x: frame.midX + GameConfig.skillExplanationSkillNameOffsetX,
            y: frame.midY + GameConfig.skillExplanationSkillNameOffsetY
        )
    }

    // MARK: - Setup (Sprint 2 · Quote Box)
    /// 인용 박스 — 좌 3px 코랄 보더 + 글래스 fill 0.55 + 라운드 14pt + Gowun Dodum 14pt navyDeep 본문.
    /// StoryBoxNode 인스턴스 제거됨 — 텍스트 출처(`characterID.skill.fullDescription`) 그대로.
    private func setupSkillQuoteBox() {
        let boxSize = CGSize(
            width: GameConfig.skillExplanationQuoteBoxWidth,
            height: GameConfig.skillExplanationQuoteBoxHeight
        )
        let box = SKShapeNode(
            rectOf: boxSize,
            cornerRadius: GameConfig.skillExplanationQuoteBoxCornerRadius
        )
        box.fillColor = UIColor.white
            .withAlphaComponent(GameConfig.skillExplanationQuoteBoxFillAlpha)
        box.strokeColor = .clear
        box.lineWidth = 0
        box.zPosition = 90
        box.name = "skillQuoteBox"
        skillQuoteBox = box
        addChild(box)

        // 좌 3px 코랄 라운드 보더.
        let borderWidth = GameConfig.skillExplanationQuoteBoxBorderWidth
        let leftBorder = SKShapeNode(
            rectOf: CGSize(width: borderWidth, height: boxSize.height),
            cornerRadius: borderWidth / 2
        )
        leftBorder.fillColor = .ganhoCoralPrimary
        leftBorder.strokeColor = .clear
        leftBorder.lineWidth = 0
        leftBorder.position = CGPoint(x: -boxSize.width / 2 + borderWidth / 2, y: 0)
        leftBorder.zPosition = 91
        box.addChild(leftBorder)

        skillQuoteLabel.text = characterID.skill.fullDescription
        skillQuoteLabel.fontSize = GameConfig.skillExplanationQuoteBoxFontSize
        skillQuoteLabel.fontColor = .ganhoNavyDeep
        skillQuoteLabel.horizontalAlignmentMode = .center
        skillQuoteLabel.verticalAlignmentMode = .center
        skillQuoteLabel.numberOfLines = 0
        skillQuoteLabel.preferredMaxLayoutWidth =
            boxSize.width - GameConfig.skillExplanationQuoteBoxHorizontalPadding * 2
        skillQuoteLabel.position = .zero
        skillQuoteLabel.zPosition = 92
        box.addChild(skillQuoteLabel)
        layoutSkillQuoteBox()
    }

    private func layoutSkillQuoteBox() {
        skillQuoteBox?.position = CGPoint(
            x: frame.midX + GameConfig.skillExplanationStoryBoxOffsetX,
            y: frame.midY + GameConfig.skillExplanationQuoteBoxOffsetY
        )
    }

    // MARK: - Setup (Sprint 2 · Stat Chips — CD / Range / Cast)
    private func setupStatChips() {
        // CD — once-per-game이면 "1회".
        let cdText: String
        if characterID.skill.oncePerGame {
            cdText = "1회"
        } else if characterID.skill == .none {
            cdText = "—"
        } else {
            let seconds = Int(characterID.skill.cooldown.rounded())
            cdText = "\(seconds)초"
        }
        let cdChip = DarkContextChipNode(label: "CD", badge: cdText)
        let rangeChip = DarkContextChipNode(
            label: "범위",
            badge: characterID.skill.rangeText
        )
        let castChip = DarkContextChipNode(
            label: "발동",
            badge: characterID.skill.castText
        )
        statChips = [cdChip, rangeChip, castChip]
        for chip in statChips {
            addChild(chip)
        }
        layoutStatChips()
    }

    private func layoutStatChips() {
        guard !statChips.isEmpty else { return }
        // 가로 정렬 — 누적 폭 계산 후 우측 영역 중앙(MetaLabelOffsetX) 기준 정렬.
        let widths = statChips.map { $0.calculateAccumulatedFrame().width }
        let spacing = GameConfig.skillExplanationStatChipSpacing
        let total = widths.reduce(0, +) + spacing * CGFloat(statChips.count - 1)
        let centerX = frame.midX + GameConfig.skillExplanationMetaLabelOffsetX
        let y = frame.midY + GameConfig.skillExplanationStatChipRowOffsetY
        var cursorX = centerX - total / 2
        for (index, chip) in statChips.enumerated() {
            let w = widths[index]
            chip.position = CGPoint(x: cursorX + w / 2, y: y)
            cursorX += w + spacing
        }
    }

    // MARK: - Setup (Sprint 2 · Control Hint with "B" Key)
    private func setupControlHint() {
        let containerSize = CGSize(
            width: GameConfig.skillExplanationControlHintContainerWidth,
            height: GameConfig.skillExplanationControlHintContainerHeight
        )
        let container = SKShapeNode(
            rectOf: containerSize,
            cornerRadius: containerSize.height / 2
        )
        container.fillColor = UIColor.ganhoNavyDeep
            .withAlphaComponent(GameConfig.skillExplanationControlHintContainerFillAlpha)
        container.strokeColor = .clear
        container.lineWidth = 0
        container.zPosition = 100
        container.name = "controlHintContainer"
        controlHintContainer = container
        addChild(container)

        controlHintKeyCircle.fillColor = .ganhoCoralPrimary
        controlHintKeyCircle.strokeColor = .clear
        controlHintKeyCircle.lineWidth = 0
        controlHintKeyCircle.zPosition = 101
        container.addChild(controlHintKeyCircle)

        controlHintKeyLabel.text = "B"
        controlHintKeyLabel.fontSize = GameConfig.skillExplanationControlHintKeyFontSize
        controlHintKeyLabel.fontColor = .white
        controlHintKeyLabel.horizontalAlignmentMode = .center
        controlHintKeyLabel.verticalAlignmentMode = .center
        controlHintKeyLabel.zPosition = 102
        container.addChild(controlHintKeyLabel)

        controlHintLabel.fontName = GameConfig.fontBody
        controlHintLabel.fontSize = GameConfig.skillExplanationControlHintLabelFontSize
        controlHintLabel.fontColor = .ganhoBgWarmTop
        controlHintLabel.horizontalAlignmentMode = .left
        controlHintLabel.verticalAlignmentMode = .center
        controlHintLabel.zPosition = 102
        container.addChild(controlHintLabel)
        layoutControlHint()
    }

    private func layoutControlHint() {
        let container = controlHintContainer
        container?.position = CGPoint(
            x: frame.midX + GameConfig.skillExplanationStoryBoxOffsetX,
            y: frame.midY + GameConfig.skillExplanationControlHintContainerOffsetY
        )
        let containerWidth = GameConfig.skillExplanationControlHintContainerWidth
        let padding = GameConfig.skillExplanationControlHintHorizontalPadding
        let keyRadius = GameConfig.skillExplanationControlHintKeyCircleRadius
        let keyX = -containerWidth / 2 + padding + keyRadius
        controlHintKeyCircle.position = CGPoint(x: keyX, y: 0)
        controlHintKeyLabel.position = CGPoint(x: keyX, y: 0)
        let labelX = keyX + keyRadius + GameConfig.skillExplanationControlHintKeySpacing
        controlHintLabel.position = CGPoint(x: labelX, y: 0)
    }

    // MARK: - Setup (Sprint 2 · Bottom Buttons)
    private func setupButtons() {
        addChild(backButton)
        addChild(startButton)
        layoutButtons()
    }

    private func layoutButtons() {
        let y = frame.midY + GameConfig.skillExplanationButtonRowOffsetY
        let half = GameConfig.characterSelectButtonSpacing / 2  // 시각 일관성.
        backButton.position = CGPoint(x: frame.midX - half, y: y)
        startButton.position = CGPoint(x: frame.midX + half, y: y)
    }

    // MARK: - Touch
    /// 우선순위: top GlassPill 뒤로 → 하단 backButton → startButton.
    /// 두 뒤로 입력은 동일 전환을 트리거 — 사용자가 어느 쪽을 탭하든 동일 결과.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if topBackPill?.contains(location) == true {
            transitionToCharacterSelect()
            return
        }
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
