//
//  CharacterSelectScene.swift
//  GanhoMusic Shared
//
//  Sprint 2 - Character account home.
//

import SpriteKit

/// 로그인 이후 진입하는 캐릭터 계정 홈 씬.
/// 캐릭터 전신 프리뷰, 계정 요약, 업적/기록 요약, 시작 흐름을 한 화면에 묶는다.
final class CharacterSelectScene: BaseMenuScene {

    // MARK: - Properties
    private var isTransitioning = false
    private var activeSection: CharacterHomeSection = .characterSelect
    private var selectedCharacterID: CharacterID = .kim
    private var currentIndex: Int = UILayout.characterHomeDefaultIndex
    private let characters: [CharacterID] = CharacterID.allCases

    private let authProfileRepo = AuthProfileRepository()
    private let statisticsRepo = StatisticsRepository()
    private let highScoreRepo = HighScoreRepository()
    private var accountScope = AccountProgressScopeProvider.current(authProfile: nil)
    private var perDifficultyScoreRepo = PerDifficultyScoreRepository()
    private var graduationRepo = GraduationRepository()
    private var preferenceRepo = CharacterPreferenceRepository()
    private var profileAvatarRepo = ProfileAvatarRepository.scoped(
        scope: AccountProgressScopeProvider.current(authProfile: nil)
    )
    private var profileAvatarSnapshot = ProfileAvatarSnapshot.defaultKim
    private var unlockStates: [CharacterID: CharacterUnlockState] = [:]
    private var homeSnapshot = CharacterHomeSnapshot.empty
    private var accountMenuOverlay: AccountMenuOverlayNode?
    private var profileDetailOverlay: ProfileDetailOverlayNode?
    private var profileDetailMode: ProfileDetailMode = .detail
    private var profileAvatarDidChangeObserver: NSObjectProtocol?
    private var profileNameEditDidFinishObserver: NSObjectProtocol?
    private var authProfileDidChangeObserver: NSObjectProtocol?
    private var shouldOpenProfileOnEntry = false
    private var didShowInitialNicknamePrompt = false
    private var isAccountRequestInFlight = false

    private var isSelectedCharacterUnlocked: Bool {
        return unlockStates[selectedCharacterID]?.isUnlocked ?? false
    }

    private let headerLabel = SKLabelNode(fontNamed: Typography.fontDisplay)
    private let headerSubLabel = SKLabelNode(fontNamed: Typography.fontBody)
    private let accentLine = AccentLineNode()
    private var backPill: GlassPillNode?

    private let profileSummary = ProfileSummaryPanelNode()
    private let stagePanel = SKShapeNode()
    private let stageShadow = SKShapeNode()
    private var portraitNode: CharacterPortraitNode?
    private let characterNameLabel = SKLabelNode(fontNamed: Typography.fontDisplay)
    private let characterSkillLabel = SKLabelNode(fontNamed: Typography.fontBody)
    private let speedChip = SKShapeNode()
    private let speedChipLabel = SKLabelNode(fontNamed: Typography.fontDisplay)
    private let homeMenu = CharacterHomeMenuNode()
    private let achievementStrip = AchievementStripNode()
    private let recordPanel = RecordSummaryPanelNode()
    private let startButton = PrimaryButtonNode(text: UILayout.characterHomeStartButtonText)

    private var railButtons: [CharacterID: SKShapeNode] = [:]
    private var railLabels: [CharacterID: SKLabelNode] = [:]
    private var leftArrowChip: GlassPillNode?
    private var rightArrowChip: GlassPillNode?

    private var swipeStartX: CGFloat = 0
    private var didSwipeInCurrentTouch = false
    private var didStartInCharacterStage = false
    private var characterStageFrame: CGRect = .zero
    private var railLayoutScale: CGFloat = 1.0

    // MARK: - Factory
    class func newCharacterSelectScene(openProfileOnEntry: Bool = false) -> CharacterSelectScene {
        let scene = CharacterSelectScene(size: CGSize(width: 1024, height: 768))
        scene.scaleMode = .resizeFill
        scene.shouldOpenProfileOnEntry = openProfileOnEntry
        return scene
    }

    // MARK: - Init
    override init(size: CGSize) {
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        setupSolidMenuBackground()

        configureScopedRepositories()
        selectedCharacterID = correctedSavedCharacter(preferenceRepo.current)
        currentIndex = characters.firstIndex(of: selectedCharacterID)
            ?? UILayout.characterHomeDefaultIndex
        homeSnapshot = makeHomeSnapshot(for: selectedCharacterID)

        setupHeader()
        setupTopBar()
        setupProfileSummary()
        setupCharacterStage()
        setupHomeMenu()
        setupAchievementStrip()
        setupRecordPanel()
        setupStartButton()
        setupCharacterRail()

        layoutHome(animated: false)
        refreshHomeContent(animated: false)
        setActiveSection(.characterSelect, animated: false, force: true)
        observeProfileAvatarChanges()
        observeProfileNameEditResults()
        observeAuthProfileChanges()
        if shouldOpenProfileOnEntry {
            setActiveSection(.profile, animated: false, force: true)
            showProfileDetailOverlay(mode: profileEntryMode())
            didShowInitialNicknamePrompt = homeSnapshot.authProfile?.needsNicknameSetup == true
        } else {
            showInitialProfilePromptIfNeeded()
        }
        syncCloudProgressIfNeeded()
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        if let observer = profileAvatarDidChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            profileAvatarDidChangeObserver = nil
        }
        if let observer = profileNameEditDidFinishObserver {
            NotificationCenter.default.removeObserver(observer)
            profileNameEditDidFinishObserver = nil
        }
        if let observer = authProfileDidChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            authProfileDidChangeObserver = nil
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        rebuildSolidMenuBackground()
        accountMenuOverlay?.update(sceneSize: size, isAppleLinked: homeSnapshot.isAppleLinked)
        updateProfileDetailOverlay()
        layoutHome(animated: false)
    }

    // MARK: - Setup
    private func setupHeader() {
        headerLabel.text = UILayout.characterHomeHeaderText
        headerLabel.fontSize = UILayout.characterHomeHeaderFontSize
        headerLabel.fontColor = .ganhoNavyDeep
        headerLabel.horizontalAlignmentMode = .left
        headerLabel.verticalAlignmentMode = .center
        headerLabel.zPosition = ZOrder.characterHomeButtonZPosition
        addChild(headerLabel)

        headerSubLabel.text = UILayout.characterHomeHeaderSubText
        headerSubLabel.fontSize = UILayout.characterHomeHeaderSubFontSize
        headerSubLabel.fontColor = .ganhoNavyMuted
        headerSubLabel.horizontalAlignmentMode = .left
        headerSubLabel.verticalAlignmentMode = .center
        headerSubLabel.zPosition = ZOrder.characterHomeButtonZPosition
        addChild(headerSubLabel)

        accentLine.zPosition = ZOrder.characterHomeButtonZPosition
        addChild(accentLine)
    }

    private func setupTopBar() {
        let back = GlassPillNode(
            text: UILayout.characterHomeBackButtonText,
            size: CGSize(
                width: UILayout.characterHomeBackButtonWidth,
                height: UILayout.characterHomeMenuButtonHeight
            )
        )
        back.applyCharacterHomeMenuStyle()
        back.zPosition = ZOrder.characterHomeButtonZPosition
        backPill = back
        addChild(back)
    }

    private func setupProfileSummary() {
        addChild(profileSummary)
    }

    private func setupCharacterStage() {
        stageShadow.fillColor = UIColor.ganhoNavyDeep.withAlphaComponent(UILayout.characterHomeStageShadowAlpha)
        stageShadow.strokeColor = .clear
        stageShadow.lineWidth = 0
        stageShadow.zPosition = ZOrder.characterHomePanelZPosition - 1
        addChild(stageShadow)

        stagePanel.fillColor = UIColor.ganhoPaper.withAlphaComponent(UILayout.characterHomePanelFillAlpha)
        stagePanel.strokeColor = UIColor.ganhoNavyDeep.withAlphaComponent(UILayout.characterHomePanelStrokeAlpha)
        stagePanel.lineWidth = UILayout.characterHomePanelLineWidth
        stagePanel.zPosition = ZOrder.characterHomePanelZPosition
        addChild(stagePanel)

        let portrait = CharacterPortraitNode(
            characterID: selectedCharacterID,
            maxSize: CGSize(
                width: UILayout.characterHomePortraitMaxWidth,
                height: UILayout.characterHomePortraitMaxHeight
            )
        )
        portrait.zPosition = ZOrder.characterHomeCharacterZPosition
        portraitNode = portrait
        addChild(portrait)

        characterNameLabel.fontSize = UILayout.characterHomeStageNameFontSize
        characterNameLabel.fontColor = .ganhoNavyDeep
        characterNameLabel.horizontalAlignmentMode = .left
        characterNameLabel.verticalAlignmentMode = .center
        characterNameLabel.zPosition = ZOrder.characterHomeCharacterZPosition + 2
        addChild(characterNameLabel)

        characterSkillLabel.fontSize = UILayout.characterHomeStageSkillFontSize
        characterSkillLabel.fontColor = .ganhoNavyMuted
        characterSkillLabel.horizontalAlignmentMode = .left
        characterSkillLabel.verticalAlignmentMode = .top
        characterSkillLabel.numberOfLines = 0
        characterSkillLabel.preferredMaxLayoutWidth = UILayout.characterHomeStageInfoMaxWidth
        characterSkillLabel.zPosition = ZOrder.characterHomeCharacterZPosition + 2
        addChild(characterSkillLabel)

        speedChip.fillColor = UIColor.ganhoScrubMint.withAlphaComponent(UILayout.characterHomePanelFillAlpha)
        speedChip.strokeColor = .ganhoDifficultyEasyDeep
        speedChip.lineWidth = UILayout.characterHomePanelLineWidth
        speedChip.zPosition = ZOrder.characterHomeCharacterZPosition + 1
        addChild(speedChip)

        speedChipLabel.fontSize = UILayout.characterHomeStageSpeedFontSize
        speedChipLabel.fontColor = .ganhoNavyDeep
        speedChipLabel.horizontalAlignmentMode = .center
        speedChipLabel.verticalAlignmentMode = .center
        speedChipLabel.zPosition = ZOrder.characterHomeCharacterZPosition + 2
        addChild(speedChipLabel)

        setupArrowChips()
    }

    private func setupArrowChips() {
        let arrowSize = CGSize(
            width: UILayout.characterHomeArrowPillWidth,
            height: UILayout.characterHomeMenuButtonHeight
        )
        let left = GlassPillNode(text: UILayout.characterHomeLeftArrowText, size: arrowSize)
        left.applyCharacterHomeMenuStyle()
        left.zPosition = ZOrder.characterHomeButtonZPosition
        leftArrowChip = left
        addChild(left)

        let right = GlassPillNode(text: UILayout.characterHomeRightArrowText, size: arrowSize)
        right.applyCharacterHomeMenuStyle()
        right.zPosition = ZOrder.characterHomeButtonZPosition
        rightArrowChip = right
        addChild(right)
    }

    private func setupHomeMenu() {
        addChild(homeMenu)
    }

    private func setupAchievementStrip() {
        addChild(achievementStrip)
    }

    private func setupRecordPanel() {
        addChild(recordPanel)
    }

    private func setupStartButton() {
        startButton.zPosition = ZOrder.characterHomeButtonZPosition
        addChild(startButton)
    }

    private func setupCharacterRail() {
        for id in characters {
            let size = CGSize(
                width: UILayout.characterHomeRailButtonSize,
                height: UILayout.characterHomeRailButtonSize
            )
            let button = SKShapeNode(
                rectOf: size,
                cornerRadius: UILayout.characterHomePanelCornerRadius / 2
            )
            button.fillColor = UIColor.ganhoPaper.withAlphaComponent(UILayout.characterHomePanelFillAlpha)
            button.strokeColor = UIColor.ganhoNavyDeep.withAlphaComponent(UILayout.characterHomePanelStrokeAlpha)
            button.lineWidth = UILayout.characterHomePanelLineWidth
            button.zPosition = ZOrder.characterHomeButtonZPosition - 1
            button.name = "characterHomeRail_\(id.rawValue)"
            railButtons[id] = button
            addChild(button)

            let label = SKLabelNode(fontNamed: Typography.fontDisplay)
            label.text = id.displayName
            label.fontSize = UILayout.characterHomeRailFontSize
            label.fontColor = .ganhoNavyDeep
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.zPosition = ZOrder.characterHomeButtonZPosition
            railLabels[id] = label
            addChild(label)
        }
    }

    // MARK: - Layout
    private var usesBottomMenu: Bool {
        return size.width < UILayout.characterHomeBottomMenuWidthThreshold
            || size.height < UILayout.characterHomeCompactHeightThreshold
    }

    private func homeLayoutScale() -> CGFloat {
        let profile = DeviceLayoutProfile.resolve(for: self)
        if profile == .padLandscape {
            return profile.menuScale
        }
        if size.height < UILayout.characterHomeCompactHeightThreshold {
            return UILayout.characterHomeCompactScale
        }
        if usesBottomMenu {
            return UILayout.characterHomeBottomMenuScale
        }
        return profile.menuScale
    }

    private func layoutHome(animated: Bool) {
        let safe = menuSafeInsets()
        let bottomMode = usesBottomMenu
        let scale = homeLayoutScale()
        layoutTopBar(safe: safe, scale: scale)
        layoutProfileSummary(safe: safe, scale: scale)
        layoutCharacterStage(safe: safe, scale: scale, bottomMode: bottomMode)
        layoutHomeMenu(safe: safe, scale: scale, bottomMode: bottomMode)
        if bottomMode {
            layoutStartButton(safe: safe, scale: scale, bottomMode: bottomMode)
            layoutDetailPanels(safe: safe, scale: scale, bottomMode: bottomMode)
        } else {
            layoutDetailPanels(safe: safe, scale: scale, bottomMode: bottomMode)
            layoutStartButton(safe: safe, scale: scale, bottomMode: bottomMode)
        }
        layoutCharacterRail(animated: animated, scale: scale)
    }

    private func layoutTopBar(safe: UIEdgeInsets, scale: CGFloat) {
        let y = frame.maxY - safe.top - UILayout.characterHomeTopBarInsetY * scale
        backPill?.setScale(scale)
        backPill?.position = CGPoint(
            x: frame.minX + safe.left
                + UILayout.characterHomeTopBarInsetX * scale
                + UILayout.characterHomeBackButtonWidth * scale / 2,
            y: y
        )

        let headerX = frame.minX + safe.left
            + UILayout.characterHomeTopBarInsetX * scale
            + UILayout.characterHomeBackButtonWidth * scale
            + UILayout.characterHomeHeaderLeftGap * scale
        headerLabel.setScale(scale)
        headerSubLabel.setScale(scale)
        accentLine.setScale(scale)
        headerLabel.position = CGPoint(x: headerX, y: y)
        headerSubLabel.position = CGPoint(
            x: headerX,
            y: y + UILayout.characterHomeHeaderSubOffsetY * scale
        )
        accentLine.position = CGPoint(
            x: headerX + UILayout.accentLineWidth * scale / 2,
            y: y + UILayout.characterHomeAccentLineOffsetY * scale
        )
    }

    private func layoutProfileSummary(safe: UIEdgeInsets, scale: CGFloat) {
        let panelSize = CGSize(
            width: UILayout.characterHomeProfilePanelWidth,
            height: UILayout.characterHomeProfilePanelHeight
        )
        profileSummary.layout(size: panelSize)
        profileSummary.setLayoutScale(scale)
        profileSummary.position = CGPoint(
            x: frame.minX + safe.left
                + UILayout.characterHomeProfilePanelLeftInset * scale
                + panelSize.width * scale / 2,
            y: frame.maxY - safe.top
                - UILayout.characterHomeProfilePanelTopInset * scale
                - panelSize.height * scale / 2
        )
    }

    private func layoutCharacterStage(safe: UIEdgeInsets,
                                      scale: CGFloat,
                                      bottomMode: Bool) {
        let stageSize = resolvedCharacterStageSize(safe: safe, scale: scale, bottomMode: bottomMode)
        let stageContentRatio = min(1, stageSize.width / UILayout.characterHomeStageWidth)
        let contentScale = scale * stageContentRatio
        stagePanel.path = CGPath(
            roundedRect: CGRect(
                x: -stageSize.width / 2,
                y: -stageSize.height / 2,
                width: stageSize.width,
                height: stageSize.height
            ),
            cornerWidth: UILayout.characterHomePanelCornerRadius,
            cornerHeight: UILayout.characterHomePanelCornerRadius,
            transform: nil
        )
        stagePanel.setScale(scale)

        stageShadow.path = CGPath(
            ellipseIn: CGRect(
                x: -UILayout.characterHomeStageShadowWidth / 2,
                y: -UILayout.characterHomeStageShadowHeight / 2,
                width: UILayout.characterHomeStageShadowWidth,
                height: UILayout.characterHomeStageShadowHeight
            ),
            transform: nil
        )
        stageShadow.setScale(contentScale)

        let preferredCenterX = frame.midX + (
            bottomMode
                ? UILayout.characterHomeCompactStageCenterOffsetX
                : UILayout.characterHomeStageCenterOffsetX
        ) * scale
        let centerYRatio = bottomMode
            ? UILayout.characterHomeCompactStageCenterYRatio
            : UILayout.characterHomeStageCenterYRatio
        let centerX = resolvedCharacterStageCenterX(
            preferredCenterX: preferredCenterX,
            stageWidth: stageSize.width,
            safe: safe,
            scale: scale,
            bottomMode: bottomMode
        )
        let center = CGPoint(x: centerX, y: frame.minY + frame.height * centerYRatio)
        let scaledSize = CGSize(width: stageSize.width * scale, height: stageSize.height * scale)
        characterStageFrame = CGRect(
            x: center.x - scaledSize.width / 2,
            y: center.y - scaledSize.height / 2,
            width: scaledSize.width,
            height: scaledSize.height
        )
        stagePanel.position = center
        stageShadow.position = CGPoint(
            x: center.x,
            y: characterStageFrame.minY + UILayout.characterHomeStageShadowHeight * contentScale / 2
        )

        portraitNode?.setMaxSize(
            CGSize(
                width: UILayout.characterHomePortraitMaxWidth,
                height: UILayout.characterHomePortraitMaxHeight
            )
        )
        portraitNode?.setScale(contentScale)
        let portraitX = center.x - UILayout.characterHomePortraitColumnOffsetX * contentScale
        let infoX = center.x + UILayout.characterHomeInfoColumnOffsetX * contentScale
        portraitNode?.position = CGPoint(
            x: portraitX,
            y: characterStageFrame.minY + UILayout.characterHomePortraitBottomInset * contentScale
        )

        characterNameLabel.setScale(contentScale)
        characterSkillLabel.setScale(contentScale)
        characterSkillLabel.preferredMaxLayoutWidth = UILayout.characterHomeStageInfoMaxWidth
        speedChip.setScale(contentScale)
        speedChipLabel.setScale(contentScale)
        characterNameLabel.position = CGPoint(
            x: infoX,
            y: center.y + UILayout.characterHomeInfoNameOffsetY * contentScale
        )
        characterSkillLabel.position = CGPoint(
            x: infoX,
            y: center.y + UILayout.characterHomeInfoSkillOffsetY * contentScale
        )
        speedChip.path = CGPath(
            roundedRect: CGRect(
                x: -UILayout.characterHomeStageSpeedChipWidth / 2,
                y: -UILayout.characterHomeStageSpeedChipHeight / 2,
                width: UILayout.characterHomeStageSpeedChipWidth,
                height: UILayout.characterHomeStageSpeedChipHeight
            ),
            cornerWidth: UILayout.characterHomeStageSpeedChipHeight / 2,
            cornerHeight: UILayout.characterHomeStageSpeedChipHeight / 2,
            transform: nil
        )
        speedChip.position = CGPoint(
            x: infoX + UILayout.characterHomeStageSpeedChipWidth * contentScale / 2,
            y: center.y + UILayout.characterHomeInfoSpeedOffsetY * contentScale
        )
        speedChipLabel.position = speedChip.position

        leftArrowChip?.setScale(scale)
        rightArrowChip?.setScale(scale)
        let buttonHalf = UILayout.characterHomeArrowPillWidth * scale / 2
        let arrowGap = UILayout.characterHomeArrowOutsideGap * scale
        leftArrowChip?.position = CGPoint(
            x: max(
                frame.minX + safe.left + buttonHalf,
                characterStageFrame.minX - arrowGap - buttonHalf
            ),
            y: characterStageFrame.midY
        )
        rightArrowChip?.position = CGPoint(
            x: min(
                frame.maxX - safe.right - buttonHalf,
                characterStageFrame.maxX + arrowGap + buttonHalf
            ),
            y: characterStageFrame.midY
        )
    }

    private func resolvedCharacterStageSize(safe: UIEdgeInsets,
                                            scale: CGFloat,
                                            bottomMode: Bool) -> CGSize {
        let bounds = characterStageHorizontalBounds(safe: safe, scale: scale, bottomMode: bottomMode)
        let availableWidth = max(0, bounds.maxX - bounds.minX)
        let desiredWidth = UILayout.characterHomeStageWidth * scale
        let resolvedWidth = min(desiredWidth, availableWidth)
        return CGSize(
            width: resolvedWidth / scale,
            height: UILayout.characterHomeStageHeight
        )
    }

    private func resolvedCharacterStageCenterX(preferredCenterX: CGFloat,
                                               stageWidth: CGFloat,
                                               safe: UIEdgeInsets,
                                               scale: CGFloat,
                                               bottomMode: Bool) -> CGFloat {
        let bounds = characterStageHorizontalBounds(safe: safe, scale: scale, bottomMode: bottomMode)
        let halfWidth = stageWidth * scale / 2
        let minCenterX = bounds.minX + halfWidth
        let maxCenterX = bounds.maxX - halfWidth
        guard minCenterX <= maxCenterX else { return preferredCenterX }
        return min(max(preferredCenterX, minCenterX), maxCenterX)
    }

    private func characterStageHorizontalBounds(safe: UIEdgeInsets,
                                                scale: CGFloat,
                                                bottomMode: Bool) -> (minX: CGFloat, maxX: CGFloat) {
        let profileRight = frame.minX
            + safe.left
            + UILayout.characterHomeProfilePanelLeftInset * scale
            + UILayout.characterHomeProfilePanelWidth * scale
        let detailLeft: CGFloat
        if bottomMode {
            detailLeft = frame.maxX
                - safe.right
                - UILayout.characterHomeMenuRightInset * scale
                - UILayout.characterHomeDetailPanelWidth * scale
        } else {
            detailLeft = frame.maxX
                - safe.right
                - UILayout.characterHomeMenuRightInset * scale
                - UILayout.characterHomeMenuButtonWidth * scale
                - UILayout.characterHomeDetailPanelGap * scale
                - UILayout.characterHomeDetailPanelWidth * scale
        }
        let inset = UILayout.characterHomeDetailPanelGap * scale
        let minX = profileRight + inset
        let maxX = detailLeft - inset
        guard maxX > minX else {
            return (
                frame.minX + safe.left + UILayout.characterHomePanelHorizontalInset * scale,
                frame.maxX - safe.right - UILayout.characterHomePanelHorizontalInset * scale
            )
        }
        return (minX, maxX)
    }

    private func layoutHomeMenu(safe: UIEdgeInsets, scale: CGFloat, bottomMode: Bool) {
        homeMenu.layout(bottomMode: bottomMode)
        homeMenu.setScale(scale)
        if bottomMode {
            homeMenu.position = CGPoint(
                x: frame.midX,
                y: frame.minY + safe.bottom
                    + UILayout.characterHomeMenuBottomInset * scale
                    + UILayout.characterHomeMenuButtonHeight * scale / 2
            )
        } else {
            homeMenu.position = CGPoint(
                x: frame.maxX - safe.right
                    - UILayout.characterHomeMenuRightInset * scale
                    - UILayout.characterHomeMenuButtonWidth * scale / 2,
                y: frame.midY + UILayout.characterHomeMenuCenterYOffset * scale
            )
        }
    }

    private func layoutDetailPanels(safe: UIEdgeInsets, scale: CGFloat, bottomMode: Bool) {
        let achievementSize = CGSize(
            width: UILayout.characterHomeDetailPanelWidth,
            height: UILayout.characterHomeAchievementPanelHeight
        )
        let recordSize = CGSize(
            width: UILayout.characterHomeDetailPanelWidth,
            height: UILayout.characterHomeDetailPanelHeight
        )
        achievementStrip.layout(size: achievementSize)
        achievementStrip.setLayoutScale(scale)
        recordPanel.layout(size: recordSize)
        recordPanel.setLayoutScale(scale)

        let detailX: CGFloat
        if bottomMode {
            detailX = frame.maxX - safe.right
                - UILayout.characterHomeMenuRightInset * scale
                - UILayout.characterHomeDetailPanelWidth * scale / 2
        } else {
            detailX = frame.maxX - safe.right
                - UILayout.characterHomeMenuRightInset * scale
                - UILayout.characterHomeMenuButtonWidth * scale
                - UILayout.characterHomeDetailPanelGap * scale
                - UILayout.characterHomeDetailPanelWidth * scale / 2
        }

        let gap = UILayout.characterHomeDetailPanelGap * scale
        let achievementHalfHeight = UILayout.characterHomeAchievementPanelHeight * scale / 2
        let recordHalfHeight = UILayout.characterHomeDetailPanelHeight * scale / 2
        let topAchievementY = frame.maxY - safe.top
            - UILayout.characterHomeProfilePanelTopInset * scale
            - achievementHalfHeight
        var achievementY = topAchievementY
        var recordY = achievementY
            - achievementHalfHeight
            - gap
            - recordHalfHeight

        if bottomMode {
            let reservedTopY = startButton.position.y
                + UILayout.primaryButtonHeight * scale / 2
                + UILayout.characterHomeBottomReservedAreaGap * scale
            let minimumRecordY = reservedTopY + recordHalfHeight
            if recordY < minimumRecordY {
                recordY = minimumRecordY
                achievementY = recordY
                    + recordHalfHeight
                    + gap
                    + achievementHalfHeight
            }
            if achievementY > topAchievementY {
                achievementY = topAchievementY
                recordY = achievementY
                    - achievementHalfHeight
                    - gap
                    - recordHalfHeight
            }
            if recordY < minimumRecordY {
                recordY = minimumRecordY
                achievementY = recordY
                    + recordHalfHeight
                    + gap
                    + achievementHalfHeight
            }
        }

        achievementStrip.position = CGPoint(x: detailX, y: achievementY)
        recordPanel.position = CGPoint(x: detailX, y: recordY)
    }

    private func layoutStartButton(safe: UIEdgeInsets, scale: CGFloat, bottomMode: Bool) {
        startButton.setScale(scale)
        let x: CGFloat
        let y: CGFloat
        if bottomMode {
            x = frame.maxX - safe.right
                - UILayout.characterHomeMenuRightInset * scale
                - UILayout.primaryButtonWidth * scale / 2
            y = homeMenu.position.y
                + UILayout.characterHomeMenuButtonHeight * scale / 2
                + UILayout.characterHomeBottomStartButtonAboveMenu * scale
                + UILayout.primaryButtonHeight * scale / 2
        } else {
            let detailX = recordPanel.position.x
            x = detailX
            y = frame.minY + safe.bottom
                + UILayout.characterHomeStartButtonBottomInset * scale
                + UILayout.primaryButtonHeight * scale / 2
        }
        startButton.position = CGPoint(x: x, y: y)
    }

    private func layoutCharacterRail(animated: Bool, scale: CGFloat) {
        railLayoutScale = scale
        let count = CGFloat(characters.count)
        let totalWidth = UILayout.characterHomeRailButtonSize * count
            + UILayout.characterHomeRailGap * max(0, count - 1)
        let startX = characterStageFrame.midX - totalWidth * scale / 2
            + UILayout.characterHomeRailButtonSize * scale / 2
        let y = characterStageFrame.minY
            + UILayout.characterHomeRailBottomInset * scale
            + UILayout.characterHomeRailButtonSize * scale / 2

        for (index, id) in characters.enumerated() {
            let x = startX + CGFloat(index) * (
                UILayout.characterHomeRailButtonSize + UILayout.characterHomeRailGap
            ) * scale
            railLabels[id]?.setScale(scale)
            railButtons[id]?.position = CGPoint(x: x, y: y)
            railLabels[id]?.position = CGPoint(x: x, y: y)
        }
        updateCharacterRail(animated: animated)
    }

    // MARK: - Account Scope
    private func configureScopedRepositories() {
        let authProfile = authProfileRepo.current
        let scope = AccountProgressScopeProvider.current(authProfile: authProfile)
        accountScope = scope
        perDifficultyScoreRepo = .scoped(scope: scope)
        graduationRepo = .scoped(scope: scope)
        preferenceRepo = .scoped(scope: scope)
        profileAvatarRepo = .scoped(scope: scope)
        mergeGlobalProgressIntoLocalFallbackIfNeeded(scope: scope, authProfile: authProfile)
        rebuildUnlockStates()
        profileAvatarSnapshot = correctedProfileAvatar(profileAvatarRepo.current)
    }

    private func mergeGlobalProgressIntoLocalFallbackIfNeeded(scope: AccountProgressScope,
                                                              authProfile: AuthProfileSnapshot?) {
        guard authProfile == nil && scope.isLocalFallback else { return }
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: scope.migrationStorageKey) else { return }

        let globalScoreRepo = PerDifficultyScoreRepository()
        let globalGraduationRepo = GraduationRepository()
        let globalPreferenceRepo = CharacterPreferenceRepository()

        _ = perDifficultyScoreRepo.mergeMax(globalScoreRepo.current)
        _ = graduationRepo.mergeEarliest(globalGraduationRepo.current)
        if !preferenceRepo.hasSavedPreference && globalPreferenceRepo.hasSavedPreference {
            preferenceRepo.save(globalPreferenceRepo.current)
        }

        defaults.set(true, forKey: scope.migrationStorageKey)
    }

    private func rebuildUnlockStates() {
        unlockStates = CharacterUnlockRules.states(
            graduations: graduationRepo.current,
            scores: perDifficultyScoreRepo.current
        )
    }

    private func correctedSavedCharacter(_ characterID: CharacterID) -> CharacterID {
        if unlockStates[characterID]?.isUnlocked == true {
            return characterID
        }
        let fallback = CharacterUnlockRules.firstUnlockedCharacter(
            graduations: graduationRepo.current,
            scores: perDifficultyScoreRepo.current
        )
        preferenceRepo.save(fallback)
        return fallback
    }

    private func correctedProfileAvatar(_ snapshot: ProfileAvatarSnapshot) -> ProfileAvatarSnapshot {
        guard let characterID = snapshot.selectedID.characterID else {
            return snapshot
        }
        guard unlockStates[characterID]?.isUnlocked == true else {
            profileAvatarRepo.save(characterID: .kim)
            return profileAvatarRepo.current
        }
        return snapshot
    }

    private func unlockedAvatarCharacters() -> [CharacterID] {
        let unlocked = CharacterID.allCases.filter { characterID in
            unlockStates[characterID]?.isUnlocked == true
        }
        guard !unlocked.isEmpty else { return [.kim] }
        if unlocked.contains(.kim) {
            return unlocked
        }
        return [.kim] + unlocked
    }

    private func syncCloudProgressIfNeeded() {
        let scope = accountScope
        Task { [weak self] in
            let result = await CloudSaveCoordinator.shared.syncProgressForCurrentUser(scope: scope)
            await MainActor.run {
                guard let self = self else { return }
                guard case .merged = result else { return }
                self.configureScopedRepositories()
                if !self.isSelectedCharacterUnlocked {
                    self.selectedCharacterID = self.correctedSavedCharacter(self.selectedCharacterID)
                    self.currentIndex = self.characters.firstIndex(of: self.selectedCharacterID)
                        ?? UILayout.characterHomeDefaultIndex
                } else {
                    self.preferenceRepo.save(self.selectedCharacterID)
                }
                self.homeSnapshot = self.makeHomeSnapshot(for: self.selectedCharacterID)
                self.layoutHome(animated: false)
                self.refreshHomeContent(animated: true)
            }
        }
    }

    // MARK: - Snapshot
    private func makeHomeSnapshot(for characterID: CharacterID) -> CharacterHomeSnapshot {
        let auth = authProfileRepo.current
        let stats = statisticsRepo.current
        let unlockState = unlockStates[characterID]
            ?? CharacterUnlockRules.state(
                for: characterID,
                graduations: graduationRepo.current,
                scores: perDifficultyScoreRepo.current
            )
        let records = Difficulty.allCases.map { difficulty in
            CharacterHomeSnapshot.Record(
                difficulty: difficulty,
                bestScore: perDifficultyScoreRepo.best(
                    characterID: characterID,
                    difficulty: difficulty
                ),
                targetScore: difficulty.targetScore
            )
        }
        return CharacterHomeSnapshot(
            authProfile: auth,
            playCount: stats.playCount,
            totalScore: stats.totalScore,
            highScore: highScoreRepo.current,
            selectedCharacterID: characterID,
            unlockState: unlockState,
            records: records,
            graduatedAt: graduationRepo.graduatedAt(characterID: characterID),
            totalGraduationCount: graduationRepo.current.count
        )
    }

    // MARK: - State
    private func refreshHomeContent(animated: Bool) {
        let unlockState = unlockStates[selectedCharacterID]
            ?? CharacterUnlockRules.state(
                for: selectedCharacterID,
                graduations: graduationRepo.current,
                scores: perDifficultyScoreRepo.current
            )
        portraitNode?.update(
            characterID: selectedCharacterID,
            isLocked: !unlockState.isUnlocked
        )
        characterNameLabel.text = unlockState.isUnlocked
            ? selectedCharacterID.displayName
            : "\(selectedCharacterID.displayName) · \(UILayout.characterHomeLockedText)"
        characterSkillLabel.text = unlockState.isUnlocked
            ? skillText(for: selectedCharacterID)
            : unlockState.requirementText
        speedChipLabel.text = [
            UILayout.characterHomeSpeedPrefixText,
            "\(UILayout.characterHomeMultiplierSeparatorText)\(formatted(selectedCharacterID.playerSpeedMultiplier))"
        ].joined(separator: UILayout.characterHomeTextJoinSeparator)
        startButton.alpha = unlockState.isUnlocked
            ? 1.0
            : UILayout.characterHomeLockedStartButtonAlpha
        profileSummary.update(
            snapshot: homeSnapshot,
            avatar: profileAvatarSnapshot,
            repository: profileAvatarRepo
        )
        achievementStrip.update(snapshot: homeSnapshot)
        recordPanel.update(snapshot: homeSnapshot)
        updateProfileDetailOverlay()
        updateCharacterRail(animated: animated)
    }

    private func setActiveSection(_ section: CharacterHomeSection,
                                  animated: Bool,
                                  force: Bool = false) {
        guard force || activeSection != section else { return }
        activeSection = section
        homeMenu.setActiveSection(section, animated: animated)
        profileSummary.setFocused(section == .profile, animated: animated)
        achievementStrip.setFocused(section == .achievements, animated: animated)
        recordPanel.setFocused(section == .records, animated: animated)
        applyStageFocus()
        layoutHome(animated: animated)
    }

    private func applyStageFocus() {
        let focused = activeSection == .characterSelect
        stagePanel.strokeColor = focused
            ? UIColor.ganhoCoralPrimary.withAlphaComponent(UILayout.characterHomePanelFocusedStrokeAlpha)
            : UIColor.ganhoNavyDeep.withAlphaComponent(UILayout.characterHomePanelStrokeAlpha)
        stagePanel.lineWidth = focused
            ? UILayout.characterHomePanelLineWidth * UILayout.characterHomeFocusedScale
            : UILayout.characterHomePanelLineWidth
    }

    private func selectCharacter(at index: Int, animated: Bool) {
        let clamped = max(
            UILayout.characterHomeDefaultIndex,
            min(characters.count - 1, index)
        )
        guard clamped != currentIndex else { return }
        currentIndex = clamped
        let characterID = characters[clamped]
        selectedCharacterID = characterID
        if unlockStates[characterID]?.isUnlocked == true {
            preferenceRepo.save(characterID)
        }
        homeSnapshot = makeHomeSnapshot(for: characterID)
        refreshHomeContent(animated: animated)
    }

    private func updateCharacterRail(animated: Bool) {
        let sectionAlpha = activeSection == .characterSelect
            ? 1.0
            : UILayout.characterHomeUnfocusedAlpha
        for id in characters {
            let selected = id == selectedCharacterID
            let locked = unlockStates[id]?.isUnlocked == false
            railButtons[id]?.fillColor = selected
                ? .ganhoCoralPrimary
                : railFillColor(isLocked: locked)
            railButtons[id]?.strokeColor = selected
                ? .ganhoCoralShadow
                : UIColor.ganhoNavyDeep.withAlphaComponent(UILayout.characterHomePanelStrokeAlpha)
            railLabels[id]?.fontColor = selected
                ? .ganhoPaper
                : (locked ? .ganhoNavyMuted : .ganhoNavyDeep)
            railButtons[id]?.alpha = selected
                ? sectionAlpha
                : railAlpha(isLocked: locked, sectionAlpha: sectionAlpha)
            railLabels[id]?.alpha = railButtons[id]?.alpha ?? sectionAlpha
            guard let button = railButtons[id] else { continue }
            button.removeAction(forKey: UILayout.characterHomeRailFocusActionKey)
            let targetScale = railLayoutScale
                * (selected ? UILayout.characterHomeRailSelectedScale : 1.0)
            if animated {
                let action = SKAction.scale(
                    to: targetScale,
                    duration: UILayout.characterHomeFocusAnimationDuration
                )
                action.timingMode = .easeInEaseOut
                button.run(action, withKey: UILayout.characterHomeRailFocusActionKey)
            } else {
                button.setScale(targetScale)
            }
        }
        leftArrowChip?.isHidden = currentIndex <= UILayout.characterHomeDefaultIndex
        rightArrowChip?.isHidden = currentIndex >= characters.count - 1
    }

    private func railFillColor(isLocked: Bool) -> UIColor {
        if isLocked {
            return UIColor.ganhoNavyMuted.withAlphaComponent(UILayout.characterHomePanelStrokeAlpha)
        }
        return UIColor.ganhoPaper.withAlphaComponent(UILayout.characterHomePanelFillAlpha)
    }

    private func railAlpha(isLocked: Bool, sectionAlpha: CGFloat) -> CGFloat {
        let baseAlpha = isLocked
            ? UILayout.characterHomeLockedPortraitAlpha
            : UILayout.characterHomeRailDeselectedAlpha
        return baseAlpha * sectionAlpha
    }

    private func skillText(for characterID: CharacterID) -> String {
        if characterID.skill == .none {
            return [
                UILayout.characterHomeSkillPrefixText,
                UILayout.characterHomeSkillSeparatorText,
                UILayout.characterHomeSkillNoneText
            ].joined(separator: UILayout.characterHomeTextJoinSeparator)
        }
        return [
            UILayout.characterHomeSkillPrefixText,
            UILayout.characterHomeSkillSeparatorText,
            characterID.skill.displayName
        ].joined(separator: UILayout.characterHomeTextJoinSeparator)
    }

    /// 속도 배율은 한 자리 표시가 가능한 값이면 한 자리, 아니면 두 자리로 표시한다.
    private func formatted(_ value: CGFloat) -> String {
        let rounded1 = (
            value * UILayout.characterHomeSingleDecimalScale
        ).rounded() / UILayout.characterHomeSingleDecimalScale
        if abs(value - rounded1) < UILayout.characterHomeSpeedFormatEpsilon {
            return String(format: UILayout.characterHomeSingleDecimalFormat, Double(value))
        }
        return String(format: UILayout.characterHomeDoubleDecimalFormat, Double(value))
    }

    // MARK: - Touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if let overlay = accountMenuOverlay {
            handleAccountMenuAction(overlay.action(at: location))
            return
        }

        if let overlay = profileDetailOverlay {
            handleProfileDetailAction(overlay.action(at: location))
            return
        }

        swipeStartX = location.x
        didSwipeInCurrentTouch = false
        didStartInCharacterStage = characterStageFrame.contains(location)

        if backPill?.contains(location) == true {
            transitionToStart()
            return
        }

        if let section = homeMenu.section(at: location, in: self) {
            setActiveSection(section, animated: true)
            if section == .profile {
                showProfileDetailOverlay(mode: .detail)
            }
            return
        }

        if handleProfileSummaryTap(at: location) {
            return
        }

        if handleCharacterRailTap(at: location) {
            return
        }

        if startButton.contains(location) {
            transitionToNext()
            return
        }

        if handleRoughCharacterSideTap(at: location) {
            return
        }
    }

    private func handleProfileSummaryTap(at location: CGPoint) -> Bool {
        guard profileSummary.calculateAccumulatedFrame().contains(location) else { return false }
        setActiveSection(.profile, animated: true)
        showProfileDetailOverlay(mode: .detail)
        return true
    }

    // MARK: - Profile Detail
    private func showProfileDetailOverlay(mode: ProfileDetailMode) {
        profileDetailMode = mode
        if profileDetailOverlay == nil {
            let overlay = ProfileDetailOverlayNode(sceneSize: size)
            profileDetailOverlay = overlay
            addChild(overlay)
        }
        updateProfileDetailOverlay()
    }

    private func hideProfileDetailOverlay() {
        profileDetailOverlay?.removeAllActions()
        profileDetailOverlay?.removeFromParent()
        profileDetailOverlay = nil
        profileDetailMode = .detail
    }

    private func updateProfileDetailOverlay() {
        guard let overlay = profileDetailOverlay else { return }
        overlay.update(
            sceneSize: size,
            snapshot: homeSnapshot,
            avatar: profileAvatarSnapshot,
            repository: profileAvatarRepo,
            unlockedCharacters: unlockedAvatarCharacters(),
            mode: profileDetailMode
        )
    }

    private func handleProfileDetailAction(_ action: ProfileDetailAction?) {
        guard let action = action else { return }

        switch action {
        case .editProfileName:
            requestProfileNameEdit(
                required: profileDetailMode == .nicknamePrompt
                    || homeSnapshot.authProfile?.needsNicknameSetup == true
            )
        case .chooseAvatar:
            showProfileDetailOverlay(mode: .avatarPicker)
        case .selectAvatar(let characterID):
            profileAvatarRepo.save(characterID: characterID)
            profileAvatarSnapshot = correctedProfileAvatar(profileAvatarRepo.current)
            refreshHomeContent(animated: true)
            showProfileDetailOverlay(mode: .detail)
        case .choosePhoto:
            requestProfilePhotoPicker()
        case .linkApple:
            hideProfileDetailOverlay()
            handleAccountAppleLinkTap()
        case .signOut:
            hideProfileDetailOverlay()
            handleAccountSignOutTap()
        case .requestDeleteConfirmation:
            hideProfileDetailOverlay()
            showAccountMenuOverlay(mode: .confirmDelete)
        case .close:
            hideProfileDetailOverlay()
        }
    }

    private func profileEntryMode() -> ProfileDetailMode {
        return homeSnapshot.authProfile?.needsNicknameSetup == true ? .nicknamePrompt : .detail
    }

    private func showInitialProfilePromptIfNeeded() {
        guard didShowInitialNicknamePrompt == false else { return }
        guard homeSnapshot.authProfile?.needsNicknameSetup == true else { return }
        didShowInitialNicknamePrompt = true
        setActiveSection(.profile, animated: false, force: true)
        showProfileDetailOverlay(mode: .nicknamePrompt)
    }

    private func requestProfileNameEdit(required: Bool) {
        let request = ProfileNameEditRequest(
            displayName: homeSnapshot.authProfile?.displayName,
            nickname: homeSnapshot.authProfile?.nickname,
            isNicknameRequired: required
        )
        NotificationCenter.default.post(
            name: .ganhoProfileNameEditRequested,
            object: nil,
            userInfo: request.userInfo
        )
    }

    private func requestProfilePhotoPicker() {
        showAccountFeedback(UILayout.profileDetailPhotoPickerRequestText)
        NotificationCenter.default.post(
            name: .ganhoProfilePhotoPickerRequested,
            object: nil,
            userInfo: [UILayout.profileAvatarScopeUserInfoKey: accountScope]
        )
    }

    private func observeProfileAvatarChanges() {
        guard profileAvatarDidChangeObserver == nil else { return }
        profileAvatarDidChangeObserver = NotificationCenter.default.addObserver(
            forName: .ganhoProfileAvatarDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleProfileAvatarDidChange(notification)
        }
    }

    private func handleProfileAvatarDidChange(_ notification: Notification) {
        if let changedScope = notification.userInfo?[UILayout.profileAvatarScopeUserInfoKey] as? AccountProgressScope,
           changedScope.storageSuffix != accountScope.storageSuffix {
            return
        }
        profileAvatarSnapshot = correctedProfileAvatar(profileAvatarRepo.current)
        refreshHomeContent(animated: true)
        showProfileDetailOverlay(mode: .detail)
    }

    private func observeProfileNameEditResults() {
        guard profileNameEditDidFinishObserver == nil else { return }
        profileNameEditDidFinishObserver = NotificationCenter.default.addObserver(
            forName: .ganhoProfileNameEditDidFinish,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleProfileNameEditDidFinish(notification)
        }
    }

    private func handleProfileNameEditDidFinish(_ notification: Notification) {
        guard let result = ProfileNameEditResult(notification: notification) else { return }
        refreshAfterAccountChange()
        if result.didSave {
            didShowInitialNicknamePrompt = true
            showAccountFeedback(UILayout.profileNameEditSavedText)
            showProfileDetailOverlay(mode: .detail)
        } else {
            showAccountFeedback(UILayout.profileNameEditFailedText)
            if result.wasNicknameRequired || homeSnapshot.authProfile?.needsNicknameSetup == true {
                showProfileDetailOverlay(mode: .nicknamePrompt)
            }
        }
    }

    private func observeAuthProfileChanges() {
        guard authProfileDidChangeObserver == nil else { return }
        authProfileDidChangeObserver = NotificationCenter.default.addObserver(
            forName: .ganhoAuthProfileDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAuthProfileDidChange()
        }
    }

    private func handleAuthProfileDidChange() {
        guard !isAccountRequestInFlight else { return }
        refreshAfterAccountChange()
        showInitialProfilePromptIfNeeded()
    }

    // MARK: - Account Menu
    private func showAccountMenuOverlay(mode: AccountMenuOverlayMode = .menu) {
        if let overlay = accountMenuOverlay {
            overlay.update(sceneSize: size, isAppleLinked: homeSnapshot.isAppleLinked, mode: mode)
            return
        }
        let overlay = AccountMenuOverlayNode(
            sceneSize: size,
            isAppleLinked: homeSnapshot.isAppleLinked,
            mode: mode
        )
        accountMenuOverlay = overlay
        addChild(overlay)
    }

    private func hideAccountMenuOverlay() {
        accountMenuOverlay?.removeAllActions()
        accountMenuOverlay?.removeFromParent()
        accountMenuOverlay = nil
    }

    private func handleAccountMenuAction(_ action: AccountMenuAction?) {
        guard let action = action else { return }
        switch action {
        case .linkApple:
            handleAccountAppleLinkTap()
        case .signOut:
            handleAccountSignOutTap()
        case .requestDeleteConfirmation:
            showAccountMenuOverlay(mode: .confirmDelete)
        case .confirmDelete:
            handleAccountDeleteTap()
        case .cancel:
            hideAccountMenuOverlay()
        }
    }

    private func handleAccountAppleLinkTap() {
        guard !isAccountRequestInFlight else { return }
        guard let window = view?.window else {
            showAccountFeedback(UILayout.authActionFailedText)
            return
        }

        let previousScope = accountScope
        isAccountRequestInFlight = true
        showAccountMenuOverlay(mode: .busy)

        Task { [weak self] in
            let result = await FirebaseAuthManager.shared.signInWithApple(presentationAnchor: window)
            await MainActor.run {
                guard let self = self else { return }
                self.isAccountRequestInFlight = false
                switch result {
                case .success:
                    self.refreshAfterAccountChange(migratingFrom: previousScope)
                    self.hideAccountMenuOverlay()
                    self.showAccountFeedback(UILayout.authLinkedStatusText)
                    self.showInitialProfilePromptIfNeeded()
                    self.syncCloudProgressIfNeeded()
                    Task {
                        _ = await CloudSaveCoordinator.shared.flushPendingIfPossible()
                    }
                case .cancelled:
                    self.showAccountMenuOverlay(mode: .menu)
                    self.showAccountFeedback(UILayout.authActionCancelledText)
                case .failure(let error):
                    self.showAccountMenuOverlay(mode: .menu)
                    self.showAccountFeedback(self.appleFailureStatusText(for: error))
                }
            }
        }
    }

    private func handleAccountSignOutTap() {
        guard !isAccountRequestInFlight else { return }
        isAccountRequestInFlight = true
        showAccountMenuOverlay(mode: .busy)

        Task { [weak self] in
            let result = await FirebaseAuthManager.shared.signOutToGuestSession()
            await MainActor.run {
                guard let self = self else { return }
                self.isAccountRequestInFlight = false
                switch result {
                case .success:
                    self.transitionToStart(openLoginChoiceOnEntry: true)
                case .cancelled:
                    self.showAccountMenuOverlay(mode: .menu)
                    self.showAccountFeedback(UILayout.authActionCancelledText)
                case .failure:
                    self.showAccountMenuOverlay(mode: .menu)
                    self.showAccountFeedback(UILayout.authActionFailedText)
                }
            }
        }
    }

    private func handleAccountDeleteTap() {
        guard !isAccountRequestInFlight else { return }
        guard let window = view?.window else {
            showAccountFeedback(UILayout.authActionFailedText)
            return
        }

        isAccountRequestInFlight = true
        showAccountMenuOverlay(mode: .busy)

        Task { [weak self] in
            let result = await FirebaseAuthManager.shared.deleteCurrentAccount(presentationAnchor: window)
            await MainActor.run {
                guard let self = self else { return }
                self.isAccountRequestInFlight = false
                switch result {
                case .success:
                    self.transitionToStart(openLoginChoiceOnEntry: true)
                case .cancelled:
                    self.showAccountMenuOverlay(mode: .menu)
                    self.showAccountFeedback(UILayout.authActionCancelledText)
                case .failure:
                    self.showAccountMenuOverlay(mode: .menu)
                    self.showAccountFeedback(UILayout.authActionFailedText)
                }
            }
        }
    }

    private func refreshAfterAccountChange(migratingFrom previousScope: AccountProgressScope? = nil) {
        let previousSelection = selectedCharacterID
        configureScopedRepositories()
        if let previousScope = previousScope {
            migrateProgressIfNeeded(from: previousScope, to: accountScope)
            rebuildUnlockStates()
            profileAvatarSnapshot = correctedProfileAvatar(profileAvatarRepo.current)
        }
        selectedCharacterID = correctedSavedCharacter(previousSelection)
        currentIndex = characters.firstIndex(of: selectedCharacterID)
            ?? UILayout.characterHomeDefaultIndex
        homeSnapshot = makeHomeSnapshot(for: selectedCharacterID)
        layoutHome(animated: false)
        refreshHomeContent(animated: true)
    }

    private func migrateProgressIfNeeded(from oldScope: AccountProgressScope,
                                         to newScope: AccountProgressScope) {
        guard oldScope.storageSuffix != newScope.storageSuffix else { return }

        let oldScoreRepo = PerDifficultyScoreRepository.scoped(scope: oldScope)
        let oldGraduationRepo = GraduationRepository.scoped(scope: oldScope)
        let oldPreferenceRepo = CharacterPreferenceRepository.scoped(scope: oldScope)
        let oldAvatarRepo = ProfileAvatarRepository.scoped(scope: oldScope)

        _ = perDifficultyScoreRepo.mergeMax(oldScoreRepo.current)
        _ = graduationRepo.mergeEarliest(oldGraduationRepo.current)
        if !preferenceRepo.hasSavedPreference && oldPreferenceRepo.hasSavedPreference {
            preferenceRepo.save(oldPreferenceRepo.current)
        }
        profileAvatarRepo.copyAvatarIfMissing(from: oldAvatarRepo)
    }

    private func appleFailureStatusText(for error: AuthError?) -> String {
        switch error {
        case .some(.appleAuthorizationTimedOut):
            return UILayout.loginChoiceAppleTimeoutText
        case .some(.appleConfigurationFailed):
            return UILayout.loginChoiceAppleConfigurationText
        case .some(.appleCredentialRejected):
            return UILayout.loginChoiceAppleCredentialText
        default:
            return UILayout.authActionFailedText
        }
    }

    private func showAccountFeedback(_ text: String) {
        let originalText = headerSubLabel.text
        headerSubLabel.text = text
        headerSubLabel.removeAction(forKey: UILayout.authStatusMessageActionKey)
        let wait = SKAction.wait(forDuration: UILayout.authStatusMessageDuration)
        let restore = SKAction.run { [weak self] in
            self?.headerSubLabel.text = originalText
        }
        headerSubLabel.run(
            SKAction.sequence([wait, restore]),
            withKey: UILayout.authStatusMessageActionKey
        )
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning, !didSwipeInCurrentTouch else { return }
        guard activeSection == .characterSelect || didStartInCharacterStage else { return }
        guard let touch = touches.first else { return }

        let dx = touch.location(in: self).x - swipeStartX
        if dx > UILayout.characterHomeSwipeThreshold {
            didSwipeInCurrentTouch = true
            selectCharacter(at: currentIndex - 1, animated: true)
        } else if dx < -UILayout.characterHomeSwipeThreshold {
            didSwipeInCurrentTouch = true
            selectCharacter(at: currentIndex + 1, animated: true)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        didSwipeInCurrentTouch = false
        didStartInCharacterStage = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        didSwipeInCurrentTouch = false
        didStartInCharacterStage = false
    }

    private func handleCharacterRailTap(at location: CGPoint) -> Bool {
        if let left = leftArrowChip, !left.isHidden, left.contains(location) {
            selectCharacter(at: currentIndex - 1, animated: true)
            return true
        }
        if let right = rightArrowChip, !right.isHidden, right.contains(location) {
            selectCharacter(at: currentIndex + 1, animated: true)
            return true
        }
        for (index, id) in characters.enumerated() {
            guard let button = railButtons[id] else { continue }
            if button.contains(location) {
                selectCharacter(at: index, animated: true)
                return true
            }
        }
        return false
    }

    private func handleRoughCharacterSideTap(at location: CGPoint) -> Bool {
        guard characterStageFrame.contains(location) else { return false }
        let zoneWidth = characterStageFrame.width * UILayout.characterHomeRoughTapZoneRatio
        let leftZone = CGRect(
            x: characterStageFrame.minX,
            y: characterStageFrame.minY,
            width: zoneWidth,
            height: characterStageFrame.height
        )
        if leftZone.contains(location) {
            selectCharacter(at: currentIndex - 1, animated: true)
            return true
        }

        let rightZone = CGRect(
            x: characterStageFrame.maxX - zoneWidth,
            y: characterStageFrame.minY,
            width: zoneWidth,
            height: characterStageFrame.height
        )
        if rightZone.contains(location) {
            selectCharacter(at: currentIndex + 1, animated: true)
            return true
        }

        return false
    }

    // MARK: - Transition
    private func transitionToStart(openLoginChoiceOnEntry: Bool = false) {
        guard let view = self.view else { return }
        isTransitioning = true
        let scene = StartScene.newStartScene(openLoginChoiceOnEntry: openLoginChoiceOnEntry)
        let fade = SKTransition.fade(withDuration: FeelTuning.sceneTransitionDuration)
        view.presentScene(scene, transition: fade)
    }

    private func transitionToNext() {
        guard let view = self.view else { return }
        guard isSelectedCharacterUnlocked else {
            showLockedStartFeedback()
            return
        }
        isTransitioning = true
        preferenceRepo.save(selectedCharacterID)
        let fade = SKTransition.fade(withDuration: FeelTuning.sceneTransitionDuration)
        switch selectedCharacterID {
        case .kim:
            let scene = DifficultySelectScene.newDifficultySelectScene(
                characterID: selectedCharacterID
            )
            view.presentScene(scene, transition: fade)
        case .jung, .geon, .im, .lee:
            let scene = SkillExplanationScene.newSkillExplanationScene(
                characterID: selectedCharacterID
            )
            view.presentScene(scene, transition: fade)
        }
    }

    private func showLockedStartFeedback() {
        let originalText = characterSkillLabel.text
        let requirement = unlockStates[selectedCharacterID]?.requirementText
            ?? UILayout.characterHomeLockedStartFeedbackText
        characterSkillLabel.text = "\(UILayout.characterHomeLockedStartFeedbackText) · \(requirement)"

        stagePanel.removeAction(forKey: "lockedStartFeedback")
        let wait = SKAction.wait(forDuration: UILayout.characterHomeLockedFeedbackDuration)
        let restore = SKAction.run { [weak self] in
            guard let self = self else { return }
            if self.characterSkillLabel.text?.contains(UILayout.characterHomeLockedStartFeedbackText) == true {
                self.characterSkillLabel.text = originalText
            }
        }
        stagePanel.run(SKAction.sequence([wait, restore]), withKey: "lockedStartFeedback")
    }
}
