//
//  SkillExplanationScene.swift
//  GanhoMusic Shared
//
//  Phase 10-1c · 시작 시퀀스 3단계 — 큰 아바타 + 스킬명 + 설명 + 뒤로/시작 버튼
//  Sprint 2 · 메뉴 v2 리스킨 — 3-stop warm gradient + AccentLine 헤더 + GlassPill 뒤로 +
//               DarkContextChip 브레드크럼 + 좌측 글래스 아바타 카드 + Jua 36pt 스킬명 +
//               인용 박스(좌 3px 코랄 보더) + 메타 칩 3개 + 중앙 다음 버튼.
//
//  characterID + difficulty 둘 다 init 인자로 *불변 입력*. 김간호는 이 씬을 *스킵*하므로
//  실제 도달하는 캐릭터는 .jung/.geon/.im/.lee 4명. (방어적으로 .none 분기도 빈 문자열 처리.)
//  큰 아바타는 PixelSpriteRenderer + PixelSprite.data + PixelPalette.palette 재사용 —
//  PlayerNode 시각 자산을 *그대로 활용* (인프라 재사용 0건 변경).
//

import SpriteKit

/// 스킬 설명 단일 결정 씬. v2 리스킨 — 좌측 글래스 아바타 카드 + 우측 스킬명/인용 박스/메타 칩 3개.
/// characterID/difficulty는 모두 *불변 입력*. 사용자는 *수정 불가* — 뒤로 가서 캐릭터 다시 선택.
final class SkillExplanationScene: BaseMenuScene {

    // MARK: - Properties
    private let characterID: CharacterID
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
    /// Sprint 10.9 — 우측 스킬 정보를 하나의 브리핑 패널로 묶어 밀집감을 낮춘다.
    private var briefingPanel: SKShapeNode?
    /// Sprint 2 — 우측 Jua 36pt 스킬명.
    private let skillNameLabel = SKLabelNode(text: "")
    /// Sprint 2 — 우측 인용 박스(좌 3px 코랄 보더 + 글래스 fill).
    private var skillQuoteBox: SKShapeNode?
    private let skillQuoteLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    /// Sprint 2 — 우측 메타 칩 3개(CD / 범위 / 즉발).
    private var statChips: [DarkContextChipNode] = []
    /// Sprint 6 — "시작"이 아니라 "다음" — 다음 단계가 DifficultySelectScene이므로.
    private let startButton = PrimaryButtonNode(text: "다음")

    // MARK: - Factory
    /// Sprint 6 — difficulty 인자 제거. 난이도 결정은 흐름의 *마지막*(DifficultySelectScene)으로 이동.
    /// CharacterSelectScene이 유일 호출자.
    class func newSkillExplanationScene(
        characterID: CharacterID
    ) -> SkillExplanationScene {
        let scene = SkillExplanationScene(
            size: CGSize(width: 1024, height: 768),
            characterID: characterID
        )
        scene.scaleMode = .resizeFill
        return scene
    }

    // MARK: - Init
    /// Sprint 4 (walk 미적용 버전) — PNG 우선·픽셀 fallback 패턴. PlayerNode.loadTexture와 동형.
    /// Sprint 6 — difficulty 입력 제거.
    private init(size: CGSize, characterID: CharacterID) {
        self.characterID = characterID
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
        setupWarmGradientBackground()
        setupHeader()
        setupTopBar()
        setupAvatarCard()
        setupAvatar()
        setupAvatarNameBadge()
        setupAvatarRoleAndSpeed()
        setupBriefingPanel()
        setupSkillName()
        setupSkillQuoteBox()
        setupStatChips()
        setupButtons()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        rebuildWarmGradientBackground()
        layoutHeader()
        layoutTopBar()
        layoutAvatarCard()
        layoutAvatar()
        layoutAvatarNameBadge()
        layoutAvatarRoleAndSpeed()
        layoutBriefingPanel()
        layoutSkillName()
        layoutSkillQuoteBox()
        layoutStatChips()
        layoutButtons()
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
        headerSubLabel.isHidden = true
        addChild(headerSubLabel)

        addChild(accentLine)
        layoutHeader()
    }

    private func layoutHeader() {
        let centerX = frame.midX
        let scale = skillLayoutScale()
        headerLabel.setScale(scale)
        headerSubLabel.setScale(scale)
        accentLine.setScale(scale)
        let baseY = min(
            frame.midY + GameConfig.skillExplanationHeaderOffsetY * scale,
            topBarY(extraInset: GameConfig.skillExplanationBackPillHeight)
        )
        headerLabel.position = CGPoint(x: centerX, y: baseY)
        headerSubLabel.position = CGPoint(
            x: centerX,
            y: baseY + GameConfig.skillExplanationHeaderSubOffsetY * scale
        )
        accentLine.position = CGPoint(
            x: centerX,
            y: baseY + GameConfig.skillExplanationAccentLineOffsetY * scale
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

        // Sprint 6 — 브레드크럼 순서 재편: 캐릭터 · [스킬] · 난이도.
        // 시각상 "현재 위치 = 스킬"이 코랄 뱃지로 강조됨(DarkContextChipNode 내부 변경 0).
        // 라벨 "\(characterID.displayName) · 스킬 · 난이도" 패턴 — 김간호는 이 화면을 스킵하므로
        // 실제 표시 대상은 .jung/.geon/.im/.lee 4명. 그 외 캐릭터도 displayName 조합 안전.
        let chip = DarkContextChipNode(
            label: "\(characterID.displayName) · 스킬 · 난이도",
            badge: GameConfig.skillExplanationBreadcrumbBadge
        )
        breadcrumbChip = chip
        addChild(chip)
        layoutTopBar()
    }

    private func layoutTopBar() {
        let safe = menuSafeInsets()
        let scale = skillLayoutScale()
        let y = topBarY(
            extraInset: max(
                0,
                GameConfig.skillExplanationTopBarMarginY - GameConfig.menuTopSafePadding
            )
        )
        topBackPill?.setScale(scale)
        breadcrumbChip?.setScale(scale)
        topBackPill?.position = CGPoint(
            x: frame.minX + safe.left + GameConfig.skillExplanationTopBarMarginX * scale
                + GameConfig.skillExplanationBackPillWidth * scale / 2,
            y: y
        )
        if let chip = breadcrumbChip {
            let halfWidth = chip.calculateAccumulatedFrame().width / 2
            chip.position = CGPoint(
                x: frame.maxX - safe.right - GameConfig.skillExplanationTopBarMarginX * scale - halfWidth,
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
        let scale = skillLayoutScale()
        avatarCard?.setScale(scale)
        avatarCard?.position = CGPoint(
            x: contentLeftX(scale: scale),
            y: contentCenterY(scale: scale)
        )
    }

    private func setupAvatar() {
        avatarSprite.zPosition = 100  // 카드 위.
        addChild(avatarSprite)
        layoutAvatar()
    }

    private func layoutAvatar() {
        let scale = skillLayoutScale()
        avatarSprite.setScale(scale)
        avatarSprite.position = CGPoint(
            x: contentLeftX(scale: scale),
            y: contentCenterY(scale: scale)
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
        let scale = skillLayoutScale()
        avatarNameBadge?.setScale(scale)
        avatarNameLabel.setScale(scale)
        let baseX = contentLeftX(scale: scale)
        let baseY = contentCenterY(scale: scale)
        let badgeY = baseY + GameConfig.skillExplanationAvatarNameBadgeOffsetY * scale
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
        let scale = skillLayoutScale()
        avatarRoleLabel.setScale(scale)
        avatarSpeedChip?.setScale(scale)
        let baseX = contentLeftX(scale: scale)
        let baseY = contentCenterY(scale: scale)
        avatarRoleLabel.position = CGPoint(
            x: baseX,
            y: baseY + GameConfig.skillExplanationAvatarRoleOffsetY * scale
        )
        avatarSpeedChip?.position = CGPoint(
            x: baseX,
            y: baseY + GameConfig.skillExplanationAvatarSpeedChipOffsetY * scale
        )
    }

    // MARK: - Sprint 10.9 · Right Briefing Panel
    private func setupBriefingPanel() {
        let panelSize = CGSize(
            width: GameConfig.skillExplanationBriefingPanelWidthV4,
            height: GameConfig.skillExplanationBriefingPanelHeightV4
        )
        let panel = SKShapeNode(
            rectOf: panelSize,
            cornerRadius: GameConfig.skillExplanationBriefingPanelCornerRadiusV4
        )
        panel.fillColor = UIColor.white
            .withAlphaComponent(GameConfig.skillExplanationBriefingPanelFillAlphaV4)
        panel.strokeColor = UIColor.ganhoNavyDeep
            .withAlphaComponent(GameConfig.skillExplanationBriefingPanelStrokeAlphaV4)
        panel.lineWidth = 1.2
        panel.zPosition = 84
        panel.name = "skillBriefingPanel"
        briefingPanel = panel
        addChild(panel)
        layoutBriefingPanel()
    }

    private func layoutBriefingPanel() {
        let scale = skillLayoutScale()
        briefingPanel?.setScale(scale)
        briefingPanel?.position = CGPoint(
            x: contentRightX(scale: scale),
            y: contentCenterY(scale: scale)
                + GameConfig.skillExplanationBriefingPanelOffsetYV4 * scale
        )
    }

    // MARK: - Sprint 7 Phase B · Right Side Skill Name
    private func setupSkillName() {
        skillNameLabel.text = characterID.skill.displayName
        skillNameLabel.fontName = GameConfig.fontDisplay
        skillNameLabel.fontSize = GameConfig.skillExplanationSkillNameFontSize
        skillNameLabel.fontColor = .ganhoNavyDeep
        skillNameLabel.horizontalAlignmentMode = .left
        skillNameLabel.verticalAlignmentMode = .center
        skillNameLabel.zPosition = 100
        addChild(skillNameLabel)
        layoutSkillName()
    }

    private func layoutSkillName() {
        let scale = skillLayoutScale()
        skillNameLabel.setScale(scale)
        skillNameLabel.position = CGPoint(
            x: briefingPanelLeftTextX(scale: scale),
            y: contentCenterY(scale: scale)
                + GameConfig.skillExplanationSkillNameOffsetYV4 * scale
        )
    }

    // MARK: - Sprint 7 Phase B · Quote Box (V3 폭 332pt + 좌측 코랄 보더 4px)
    /// 인용 박스 — 좌 4px 코랄 보더(V3) + 글래스 fill 0.55 + 라운드 14pt + Gowun Dodum 14pt navyDeep 본문.
    /// StoryBoxNode 인스턴스 제거됨 — 텍스트 출처(`characterID.skill.fullDescription`) 그대로.
    /// Sprint 7 Phase B — 폭 300→332(≈52%), 보더 3→4px. V3 상수만 참조, v2 상수 값 변경 0.
    private func setupSkillQuoteBox() {
        let boxSize = CGSize(
            width: GameConfig.skillExplanationQuoteBoxWidthV4,
            height: GameConfig.skillExplanationQuoteBoxHeightV4
        )
        let box = SKShapeNode(
            rectOf: boxSize,
            cornerRadius: GameConfig.skillExplanationQuoteBoxCornerRadius
        )
        box.fillColor = UIColor.white
            .withAlphaComponent(0.92)
        box.strokeColor = .clear
        box.lineWidth = 0
        box.zPosition = 90
        box.name = "skillQuoteBox"
        skillQuoteBox = box
        addChild(box)

        // Sprint 7 Phase B — 좌측 코랄 라운드 보더 4px (v2 3px → v3 4px).
        let borderWidth = GameConfig.skillExplanationQuoteBoxBorderWidthV3
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
        let scale = skillLayoutScale()
        skillQuoteBox?.setScale(scale)
        // Label width is parent-local: the quote box itself receives the compact scale.
        skillQuoteLabel.preferredMaxLayoutWidth =
            GameConfig.skillExplanationQuoteBoxWidthV4
            - GameConfig.skillExplanationQuoteBoxHorizontalPadding * 2
        skillQuoteBox?.position = CGPoint(
            x: contentRightX(scale: scale),
            y: contentCenterY(scale: scale)
                + GameConfig.skillExplanationQuoteBoxOffsetYV4 * scale
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
        let scale = skillLayoutScale()
        for chip in statChips {
            chip.setScale(scale)
        }
        // 가로 정렬 — 누적 폭 계산 후 우측 영역 중앙(MetaLabelOffsetX) 기준 정렬.
        let widths = statChips.map { $0.calculateAccumulatedFrame().width }
        // Sprint 7 Phase B — V3 spacing 10pt (v2 8pt → v3 10pt). 메타 칩 호흡 +2pt.
        let spacing = GameConfig.skillExplanationStatChipSpacingV3 * scale
        let total = widths.reduce(0, +) + spacing * CGFloat(statChips.count - 1)
        let centerX = contentRightX(scale: scale)
        let y = contentCenterY(scale: scale)
            + GameConfig.skillExplanationStatChipRowOffsetYV4 * scale
        var cursorX = centerX - total / 2
        for (index, chip) in statChips.enumerated() {
            let w = widths[index]
            chip.position = CGPoint(x: cursorX + w / 2, y: y)
            cursorX += w + spacing
        }
    }

    // MARK: - Sprint 7 Phase B · Bottom Buttons (startButton 단독 중앙)
    private func setupButtons() {
        addChild(startButton)
        layoutButtons()
    }

    private func layoutButtons() {
        let scale = skillLayoutScale()
        startButton.setScale(scale)
        let panelBottom = contentCenterY(scale: scale)
            + GameConfig.skillExplanationBriefingPanelOffsetYV4 * scale
            - GameConfig.skillExplanationBriefingPanelHeightV4 * scale / 2
        let targetY = panelBottom
            - GameConfig.skillExplanationButtonRightPanelGapV4 * scale
            - GameConfig.primaryButtonHeight * scale / 2
        let minY = bottomCTAAnchorY(buttonHalfHeight: GameConfig.primaryButtonHeight * scale / 2)
        startButton.position = CGPoint(
            x: contentRightX(scale: scale),
            y: max(targetY, minY)
        )
    }

    // MARK: - Layout

    private func skillLayoutScale() -> CGFloat {
        let safe = menuSafeInsets()
        let availableWidth = size.width
            - safe.left
            - safe.right
            - GameConfig.menuHorizontalSafePadding * 2
        let requiredWidth = GameConfig.skillExplanationAvatarCardWidth
            + GameConfig.difficultySelectColumnMinGap
            + GameConfig.skillExplanationBriefingPanelWidthV4
        let widthScale = availableWidth / requiredWidth
        return max(
            GameConfig.skillExplanationMinimumLayoutScale,
            min(menuCompactScale(), widthScale)
        )
    }

    private func contentCenterY(scale: CGFloat) -> CGFloat {
        let buttonY = bottomCTAAnchorY(buttonHalfHeight: GameConfig.primaryButtonHeight * scale / 2)
        let topLimit = topBarY(extraInset: GameConfig.skillExplanationBackPillHeight)
            - GameConfig.skillExplanationHeaderFontSize * scale
        let preferred = frame.midY + GameConfig.skillExplanationAvatarCardOffsetY * scale
        let cardHalfHeight = GameConfig.skillExplanationAvatarCardHeight * scale / 2
        let minY = buttonY
            + GameConfig.primaryButtonHeight * scale / 2
            + GameConfig.menuBottomSafePadding
            + cardHalfHeight
        let maxY = topLimit - cardHalfHeight
        return maxY > minY ? min(max(preferred, minY), maxY) : preferred
    }

    private func contentLeftX(scale: CGFloat) -> CGFloat {
        let safe = menuSafeInsets()
        let halfWidth = GameConfig.skillExplanationAvatarCardWidth * scale / 2
        let preferred = frame.midX + GameConfig.skillExplanationAvatarCardOffsetXV4 * scale
        let minX = frame.minX
            + safe.left
            + GameConfig.menuHorizontalSafePadding
            + halfWidth
        return max(preferred, minX)
    }

    private func contentRightX(scale: CGFloat) -> CGFloat {
        let safe = menuSafeInsets()
        let halfWidth = GameConfig.skillExplanationBriefingPanelWidthV4 * scale / 2
        let preferred = frame.midX + GameConfig.skillExplanationBriefingPanelOffsetXV4 * scale
        let maxX = frame.maxX
            - safe.right
            - GameConfig.menuHorizontalSafePadding
            - halfWidth
        return min(preferred, maxX)
    }

    private func briefingPanelLeftTextX(scale: CGFloat) -> CGFloat {
        contentRightX(scale: scale)
            - GameConfig.skillExplanationBriefingPanelWidthV4 * scale / 2
            + GameConfig.skillExplanationBriefingPanelTextInsetXV4 * scale
    }

    // MARK: - Touch
    /// 우선순위: top GlassPill 뒤로 → startButton.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if topBackPill?.contains(location) == true {
            transitionToCharacterSelect()
            return
        }
        if startButton.contains(location) {
            transitionToDifficulty()
        }
    }

    /// Sprint 6 — newCharacterSelectScene을 인자 없이 호출.
    private func transitionToCharacterSelect() {
        guard let view = self.view else { return }
        isTransitioning = true
        let scene = CharacterSelectScene.newCharacterSelectScene()
        let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
        view.presentScene(scene, transition: fade)
    }

    /// Sprint 6 — 다음 단계는 GameScene이 아니라 DifficultySelectScene.
    /// 난이도 결정이 흐름의 *마지막*으로 이동했다.
    private func transitionToDifficulty() {
        guard let view = self.view else { return }
        isTransitioning = true
        let scene = DifficultySelectScene.newDifficultySelectScene(
            characterID: characterID
        )
        let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
        view.presentScene(scene, transition: fade)
    }
}
