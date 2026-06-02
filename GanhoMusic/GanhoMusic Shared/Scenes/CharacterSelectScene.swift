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
    private var currentIndex: Int = GameConfig.characterHomeDefaultIndex
    private let characters: [CharacterID] = CharacterID.allCases

    private let authProfileRepo = AuthProfileRepository()
    private let statisticsRepo = StatisticsRepository()
    private let highScoreRepo = HighScoreRepository()
    private let perDifficultyScoreRepo = PerDifficultyScoreRepository()
    private let graduationRepo = GraduationRepository()
    private let preferenceRepo = CharacterPreferenceRepository()
    private var homeSnapshot = CharacterHomeSnapshot.empty

    private let headerLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    private let headerSubLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    private let accentLine = AccentLineNode()
    private var backPill: GlassPillNode?

    private let profileSummary = ProfileSummaryPanelNode()
    private let stagePanel = SKShapeNode()
    private let stageShadow = SKShapeNode()
    private var portraitNode: CharacterPortraitNode?
    private let characterNameLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    private let characterSkillLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    private let speedChip = SKShapeNode()
    private let speedChipLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    private let homeMenu = CharacterHomeMenuNode()
    private let achievementStrip = AchievementStripNode()
    private let recordPanel = RecordSummaryPanelNode()
    private let startButton = PrimaryButtonNode(text: GameConfig.characterHomeStartButtonText)

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
    class func newCharacterSelectScene() -> CharacterSelectScene {
        let scene = CharacterSelectScene(size: CGSize(width: 1024, height: 768))
        scene.scaleMode = .resizeFill
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
        backgroundColor = .ganhoBgWarmTop
        setupWarmGradientBackground()

        selectedCharacterID = preferenceRepo.current
        currentIndex = characters.firstIndex(of: selectedCharacterID)
            ?? GameConfig.characterHomeDefaultIndex
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
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        rebuildWarmGradientBackground()
        layoutHome(animated: false)
    }

    // MARK: - Setup
    private func setupHeader() {
        headerLabel.text = GameConfig.characterHomeHeaderText
        headerLabel.fontSize = GameConfig.characterHomeHeaderFontSize
        headerLabel.fontColor = .ganhoNavyDeep
        headerLabel.horizontalAlignmentMode = .left
        headerLabel.verticalAlignmentMode = .center
        headerLabel.zPosition = GameConfig.characterHomeButtonZPosition
        addChild(headerLabel)

        headerSubLabel.text = GameConfig.characterHomeHeaderSubText
        headerSubLabel.fontSize = GameConfig.characterHomeHeaderSubFontSize
        headerSubLabel.fontColor = .ganhoNavyMuted
        headerSubLabel.horizontalAlignmentMode = .left
        headerSubLabel.verticalAlignmentMode = .center
        headerSubLabel.zPosition = GameConfig.characterHomeButtonZPosition
        addChild(headerSubLabel)

        accentLine.zPosition = GameConfig.characterHomeButtonZPosition
        addChild(accentLine)
    }

    private func setupTopBar() {
        let back = GlassPillNode(
            text: GameConfig.characterHomeBackButtonText,
            size: CGSize(
                width: GameConfig.characterHomeBackButtonWidth,
                height: GameConfig.characterHomeBackButtonHeight
            )
        )
        back.zPosition = GameConfig.characterHomeButtonZPosition
        backPill = back
        addChild(back)
    }

    private func setupProfileSummary() {
        addChild(profileSummary)
    }

    private func setupCharacterStage() {
        stageShadow.fillColor = UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.characterHomeStageShadowAlpha)
        stageShadow.strokeColor = .clear
        stageShadow.lineWidth = 0
        stageShadow.zPosition = GameConfig.characterHomePanelZPosition - 1
        addChild(stageShadow)

        stagePanel.fillColor = UIColor.ganhoPaper.withAlphaComponent(GameConfig.characterHomePanelFillAlpha)
        stagePanel.strokeColor = UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.characterHomePanelStrokeAlpha)
        stagePanel.lineWidth = GameConfig.characterHomePanelLineWidth
        stagePanel.zPosition = GameConfig.characterHomePanelZPosition
        addChild(stagePanel)

        let portrait = CharacterPortraitNode(
            characterID: selectedCharacterID,
            maxSize: CGSize(
                width: GameConfig.characterHomePortraitMaxWidth,
                height: GameConfig.characterHomePortraitMaxHeight
            )
        )
        portrait.zPosition = GameConfig.characterHomeCharacterZPosition
        portraitNode = portrait
        addChild(portrait)

        characterNameLabel.fontSize = GameConfig.characterHomeStageNameFontSize
        characterNameLabel.fontColor = .ganhoNavyDeep
        characterNameLabel.horizontalAlignmentMode = .center
        characterNameLabel.verticalAlignmentMode = .center
        characterNameLabel.zPosition = GameConfig.characterHomeCharacterZPosition + 2
        addChild(characterNameLabel)

        characterSkillLabel.fontSize = GameConfig.characterHomeStageSkillFontSize
        characterSkillLabel.fontColor = .ganhoNavyMuted
        characterSkillLabel.horizontalAlignmentMode = .center
        characterSkillLabel.verticalAlignmentMode = .center
        characterSkillLabel.zPosition = GameConfig.characterHomeCharacterZPosition + 2
        addChild(characterSkillLabel)

        speedChip.fillColor = UIColor.ganhoScrubMint.withAlphaComponent(GameConfig.characterHomePanelFillAlpha)
        speedChip.strokeColor = .ganhoDifficultyEasyDeep
        speedChip.lineWidth = GameConfig.characterHomePanelLineWidth
        speedChip.zPosition = GameConfig.characterHomeCharacterZPosition + 1
        addChild(speedChip)

        speedChipLabel.fontSize = GameConfig.characterHomeStageSpeedFontSize
        speedChipLabel.fontColor = .ganhoNavyDeep
        speedChipLabel.horizontalAlignmentMode = .center
        speedChipLabel.verticalAlignmentMode = .center
        speedChipLabel.zPosition = GameConfig.characterHomeCharacterZPosition + 2
        addChild(speedChipLabel)

        setupArrowChips()
    }

    private func setupArrowChips() {
        let size = CGSize(
            width: GameConfig.characterHomeArrowButtonSize,
            height: GameConfig.characterHomeArrowButtonSize
        )
        let left = GlassPillNode(text: GameConfig.characterHomeLeftArrowText, size: size)
        left.zPosition = GameConfig.characterHomeButtonZPosition
        leftArrowChip = left
        addChild(left)

        let right = GlassPillNode(text: GameConfig.characterHomeRightArrowText, size: size)
        right.zPosition = GameConfig.characterHomeButtonZPosition
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
        startButton.zPosition = GameConfig.characterHomeButtonZPosition
        addChild(startButton)
    }

    private func setupCharacterRail() {
        for id in characters {
            let size = CGSize(
                width: GameConfig.characterHomeRailButtonSize,
                height: GameConfig.characterHomeRailButtonSize
            )
            let button = SKShapeNode(
                rectOf: size,
                cornerRadius: GameConfig.characterHomePanelCornerRadius / 2
            )
            button.fillColor = UIColor.ganhoPaper.withAlphaComponent(GameConfig.characterHomePanelFillAlpha)
            button.strokeColor = UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.characterHomePanelStrokeAlpha)
            button.lineWidth = GameConfig.characterHomePanelLineWidth
            button.zPosition = GameConfig.characterHomeButtonZPosition - 1
            button.name = "characterHomeRail_\(id.rawValue)"
            railButtons[id] = button
            addChild(button)

            let label = SKLabelNode(fontNamed: GameConfig.fontDisplay)
            label.text = id.displayName
            label.fontSize = GameConfig.characterHomeRailFontSize
            label.fontColor = .ganhoNavyDeep
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.zPosition = GameConfig.characterHomeButtonZPosition
            railLabels[id] = label
            addChild(label)
        }
    }

    // MARK: - Layout
    private var usesBottomMenu: Bool {
        return size.width < GameConfig.characterHomeBottomMenuWidthThreshold
            || size.height < GameConfig.characterHomeCompactHeightThreshold
    }

    private func homeLayoutScale() -> CGFloat {
        if size.height < GameConfig.characterHomeCompactHeightThreshold {
            return GameConfig.characterHomeCompactScale
        }
        if usesBottomMenu {
            return GameConfig.characterHomeBottomMenuScale
        }
        return 1.0
    }

    private func layoutHome(animated: Bool) {
        let safe = SceneSafeArea.insets(for: self)
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
        let y = frame.maxY - safe.top - GameConfig.characterHomeTopBarInsetY * scale
        backPill?.setScale(scale)
        backPill?.position = CGPoint(
            x: frame.minX + safe.left
                + GameConfig.characterHomeTopBarInsetX * scale
                + GameConfig.characterHomeBackButtonWidth * scale / 2,
            y: y
        )

        let headerX = frame.minX + safe.left
            + GameConfig.characterHomeTopBarInsetX * scale
            + GameConfig.characterHomeBackButtonWidth * scale
            + GameConfig.characterHomeHeaderLeftGap * scale
        headerLabel.setScale(scale)
        headerSubLabel.setScale(scale)
        accentLine.setScale(scale)
        headerLabel.position = CGPoint(x: headerX, y: y)
        headerSubLabel.position = CGPoint(
            x: headerX,
            y: y + GameConfig.characterHomeHeaderSubOffsetY * scale
        )
        accentLine.position = CGPoint(
            x: headerX + GameConfig.accentLineWidth * scale / 2,
            y: y + GameConfig.characterHomeAccentLineOffsetY * scale
        )
    }

    private func layoutProfileSummary(safe: UIEdgeInsets, scale: CGFloat) {
        let panelSize = CGSize(
            width: GameConfig.characterHomeProfilePanelWidth,
            height: GameConfig.characterHomeProfilePanelHeight
        )
        profileSummary.layout(size: panelSize)
        profileSummary.setLayoutScale(scale)
        profileSummary.position = CGPoint(
            x: frame.minX + safe.left
                + GameConfig.characterHomeProfilePanelLeftInset * scale
                + panelSize.width * scale / 2,
            y: frame.maxY - safe.top
                - GameConfig.characterHomeProfilePanelTopInset * scale
                - panelSize.height * scale / 2
        )
    }

    private func layoutCharacterStage(safe: UIEdgeInsets,
                                      scale: CGFloat,
                                      bottomMode: Bool) {
        let stageSize = CGSize(
            width: GameConfig.characterHomeStageWidth,
            height: GameConfig.characterHomeStageHeight
        )
        stagePanel.path = CGPath(
            roundedRect: CGRect(
                x: -stageSize.width / 2,
                y: -stageSize.height / 2,
                width: stageSize.width,
                height: stageSize.height
            ),
            cornerWidth: GameConfig.characterHomePanelCornerRadius,
            cornerHeight: GameConfig.characterHomePanelCornerRadius,
            transform: nil
        )
        stagePanel.setScale(scale)

        stageShadow.path = CGPath(
            ellipseIn: CGRect(
                x: -GameConfig.characterHomeStageShadowWidth / 2,
                y: -GameConfig.characterHomeStageShadowHeight / 2,
                width: GameConfig.characterHomeStageShadowWidth,
                height: GameConfig.characterHomeStageShadowHeight
            ),
            transform: nil
        )
        stageShadow.setScale(scale)

        let centerX = frame.midX + (
            bottomMode
                ? GameConfig.characterHomeCompactStageCenterOffsetX
                : GameConfig.characterHomeStageCenterOffsetX
        ) * scale
        let centerYRatio = bottomMode
            ? GameConfig.characterHomeCompactStageCenterYRatio
            : GameConfig.characterHomeStageCenterYRatio
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
            y: characterStageFrame.minY + GameConfig.characterHomeStageShadowHeight * scale / 2
        )

        portraitNode?.setMaxSize(
            CGSize(
                width: GameConfig.characterHomePortraitMaxWidth,
                height: GameConfig.characterHomePortraitMaxHeight
            )
        )
        portraitNode?.setScale(scale)
        portraitNode?.position = CGPoint(
            x: center.x,
            y: characterStageFrame.minY + GameConfig.characterHomePortraitBottomInset * scale
        )

        characterNameLabel.setScale(scale)
        characterSkillLabel.setScale(scale)
        speedChip.setScale(scale)
        speedChipLabel.setScale(scale)
        characterNameLabel.position = CGPoint(
            x: center.x,
            y: characterStageFrame.maxY - GameConfig.characterHomeStageNameTopInset * scale
        )
        characterSkillLabel.position = CGPoint(
            x: center.x,
            y: characterNameLabel.position.y - GameConfig.characterHomeStageSkillGap * scale
        )
        speedChip.path = CGPath(
            roundedRect: CGRect(
                x: -GameConfig.characterHomeStageSpeedChipWidth / 2,
                y: -GameConfig.characterHomeStageSpeedChipHeight / 2,
                width: GameConfig.characterHomeStageSpeedChipWidth,
                height: GameConfig.characterHomeStageSpeedChipHeight
            ),
            cornerWidth: GameConfig.characterHomeStageSpeedChipHeight / 2,
            cornerHeight: GameConfig.characterHomeStageSpeedChipHeight / 2,
            transform: nil
        )
        speedChip.position = CGPoint(
            x: center.x,
            y: characterSkillLabel.position.y - GameConfig.characterHomeStageSkillGap * scale
        )
        speedChipLabel.position = speedChip.position

        leftArrowChip?.setScale(scale)
        rightArrowChip?.setScale(scale)
        leftArrowChip?.position = CGPoint(
            x: characterStageFrame.minX + GameConfig.characterHomeArrowInsetX * scale,
            y: characterStageFrame.midY
        )
        rightArrowChip?.position = CGPoint(
            x: characterStageFrame.maxX - GameConfig.characterHomeArrowInsetX * scale,
            y: characterStageFrame.midY
        )
    }

    private func layoutHomeMenu(safe: UIEdgeInsets, scale: CGFloat, bottomMode: Bool) {
        homeMenu.layout(bottomMode: bottomMode)
        homeMenu.setScale(scale)
        if bottomMode {
            homeMenu.position = CGPoint(
                x: frame.midX,
                y: frame.minY + safe.bottom
                    + GameConfig.characterHomeMenuBottomInset * scale
                    + GameConfig.characterHomeMenuButtonHeight * scale / 2
            )
        } else {
            homeMenu.position = CGPoint(
                x: frame.maxX - safe.right
                    - GameConfig.characterHomeMenuRightInset * scale
                    - GameConfig.characterHomeMenuButtonWidth * scale / 2,
                y: frame.midY + GameConfig.characterHomeMenuCenterYOffset * scale
            )
        }
    }

    private func layoutDetailPanels(safe: UIEdgeInsets, scale: CGFloat, bottomMode: Bool) {
        let achievementSize = CGSize(
            width: GameConfig.characterHomeDetailPanelWidth,
            height: GameConfig.characterHomeAchievementPanelHeight
        )
        let recordSize = CGSize(
            width: GameConfig.characterHomeDetailPanelWidth,
            height: GameConfig.characterHomeDetailPanelHeight
        )
        achievementStrip.layout(size: achievementSize)
        achievementStrip.setLayoutScale(scale)
        recordPanel.layout(size: recordSize)
        recordPanel.setLayoutScale(scale)

        let detailX: CGFloat
        if bottomMode {
            detailX = frame.maxX - safe.right
                - GameConfig.characterHomeMenuRightInset * scale
                - GameConfig.characterHomeDetailPanelWidth * scale / 2
        } else {
            detailX = frame.maxX - safe.right
                - GameConfig.characterHomeMenuRightInset * scale
                - GameConfig.characterHomeMenuButtonWidth * scale
                - GameConfig.characterHomeDetailPanelGap * scale
                - GameConfig.characterHomeDetailPanelWidth * scale / 2
        }

        let gap = GameConfig.characterHomeDetailPanelGap * scale
        let achievementHalfHeight = GameConfig.characterHomeAchievementPanelHeight * scale / 2
        let recordHalfHeight = GameConfig.characterHomeDetailPanelHeight * scale / 2
        let topAchievementY = frame.maxY - safe.top
            - GameConfig.characterHomeProfilePanelTopInset * scale
            - achievementHalfHeight
        var achievementY = topAchievementY
        var recordY = achievementY
            - achievementHalfHeight
            - gap
            - recordHalfHeight

        if bottomMode {
            let reservedTopY = startButton.position.y
                + GameConfig.primaryButtonHeight * scale / 2
                + GameConfig.characterHomeBottomReservedAreaGap * scale
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
                - GameConfig.characterHomeMenuRightInset * scale
                - GameConfig.primaryButtonWidth * scale / 2
            y = homeMenu.position.y
                + GameConfig.characterHomeMenuButtonHeight * scale / 2
                + GameConfig.characterHomeBottomStartButtonAboveMenu * scale
                + GameConfig.primaryButtonHeight * scale / 2
        } else {
            let detailX = recordPanel.position.x
            x = detailX
            y = frame.minY + safe.bottom
                + GameConfig.characterHomeStartButtonBottomInset * scale
                + GameConfig.primaryButtonHeight * scale / 2
        }
        startButton.position = CGPoint(x: x, y: y)
    }

    private func layoutCharacterRail(animated: Bool, scale: CGFloat) {
        railLayoutScale = scale
        let count = CGFloat(characters.count)
        let totalWidth = GameConfig.characterHomeRailButtonSize * count
            + GameConfig.characterHomeRailGap * max(0, count - 1)
        let startX = characterStageFrame.midX - totalWidth * scale / 2
            + GameConfig.characterHomeRailButtonSize * scale / 2
        let y = characterStageFrame.minY
            + GameConfig.characterHomeRailBottomInset * scale
            + GameConfig.characterHomeRailButtonSize * scale / 2

        for (index, id) in characters.enumerated() {
            let x = startX + CGFloat(index) * (
                GameConfig.characterHomeRailButtonSize + GameConfig.characterHomeRailGap
            ) * scale
            railLabels[id]?.setScale(scale)
            railButtons[id]?.position = CGPoint(x: x, y: y)
            railLabels[id]?.position = CGPoint(x: x, y: y)
        }
        updateCharacterRail(animated: animated)
    }

    // MARK: - Snapshot
    private func makeHomeSnapshot(for characterID: CharacterID) -> CharacterHomeSnapshot {
        let auth = authProfileRepo.current
        let stats = statisticsRepo.current
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
            records: records,
            graduatedAt: graduationRepo.graduatedAt(characterID: characterID),
            totalGraduationCount: graduationRepo.current.count
        )
    }

    // MARK: - State
    private func refreshHomeContent(animated: Bool) {
        portraitNode?.update(characterID: selectedCharacterID)
        characterNameLabel.text = selectedCharacterID.displayName
        characterSkillLabel.text = skillText(for: selectedCharacterID)
        speedChipLabel.text = [
            GameConfig.characterHomeSpeedPrefixText,
            "\(GameConfig.characterHomeMultiplierSeparatorText)\(formatted(selectedCharacterID.playerSpeedMultiplier))"
        ].joined(separator: GameConfig.characterHomeTextJoinSeparator)
        profileSummary.update(snapshot: homeSnapshot)
        achievementStrip.update(snapshot: homeSnapshot)
        recordPanel.update(snapshot: homeSnapshot)
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
            ? UIColor.ganhoCoralPrimary.withAlphaComponent(GameConfig.characterHomePanelFocusedStrokeAlpha)
            : UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.characterHomePanelStrokeAlpha)
        stagePanel.lineWidth = focused
            ? GameConfig.characterHomePanelLineWidth * GameConfig.characterHomeFocusedScale
            : GameConfig.characterHomePanelLineWidth
    }

    private func selectCharacter(at index: Int, animated: Bool) {
        let clamped = max(
            GameConfig.characterHomeDefaultIndex,
            min(characters.count - 1, index)
        )
        guard clamped != currentIndex else { return }
        currentIndex = clamped
        let characterID = characters[clamped]
        selectedCharacterID = characterID
        preferenceRepo.save(characterID)
        homeSnapshot = makeHomeSnapshot(for: characterID)
        refreshHomeContent(animated: animated)
    }

    private func updateCharacterRail(animated: Bool) {
        let sectionAlpha = activeSection == .characterSelect
            ? 1.0
            : GameConfig.characterHomeUnfocusedAlpha
        for id in characters {
            let selected = id == selectedCharacterID
            railButtons[id]?.fillColor = selected
                ? .ganhoCoralPrimary
                : UIColor.ganhoPaper.withAlphaComponent(GameConfig.characterHomePanelFillAlpha)
            railButtons[id]?.strokeColor = selected
                ? .ganhoCoralShadow
                : UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.characterHomePanelStrokeAlpha)
            railLabels[id]?.fontColor = selected ? .ganhoPaper : .ganhoNavyDeep
            railButtons[id]?.alpha = selected
                ? sectionAlpha
                : GameConfig.characterHomeRailDeselectedAlpha * sectionAlpha
            railLabels[id]?.alpha = railButtons[id]?.alpha ?? sectionAlpha
            guard let button = railButtons[id] else { continue }
            button.removeAction(forKey: GameConfig.characterHomeRailFocusActionKey)
            let targetScale = railLayoutScale
                * (selected ? GameConfig.characterHomeRailSelectedScale : 1.0)
            if animated {
                let action = SKAction.scale(
                    to: targetScale,
                    duration: GameConfig.characterHomeFocusAnimationDuration
                )
                action.timingMode = .easeInEaseOut
                button.run(action, withKey: GameConfig.characterHomeRailFocusActionKey)
            } else {
                button.setScale(targetScale)
            }
        }
        leftArrowChip?.isHidden = currentIndex <= GameConfig.characterHomeDefaultIndex
        rightArrowChip?.isHidden = currentIndex >= characters.count - 1
    }

    private func skillText(for characterID: CharacterID) -> String {
        if characterID.skill == .none {
            return [
                GameConfig.characterHomeSkillPrefixText,
                GameConfig.characterHomeSkillSeparatorText,
                GameConfig.characterHomeSkillNoneText
            ].joined(separator: GameConfig.characterHomeTextJoinSeparator)
        }
        return [
            GameConfig.characterHomeSkillPrefixText,
            GameConfig.characterHomeSkillSeparatorText,
            characterID.skill.displayName
        ].joined(separator: GameConfig.characterHomeTextJoinSeparator)
    }

    /// 속도 배율은 한 자리 표시가 가능한 값이면 한 자리, 아니면 두 자리로 표시한다.
    private func formatted(_ value: CGFloat) -> String {
        let rounded1 = (
            value * GameConfig.characterHomeSingleDecimalScale
        ).rounded() / GameConfig.characterHomeSingleDecimalScale
        if abs(value - rounded1) < GameConfig.characterHomeSpeedFormatEpsilon {
            return String(format: GameConfig.characterHomeSingleDecimalFormat, Double(value))
        }
        return String(format: GameConfig.characterHomeDoubleDecimalFormat, Double(value))
    }

    // MARK: - Touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        swipeStartX = location.x
        didSwipeInCurrentTouch = false
        didStartInCharacterStage = characterStageFrame.contains(location)

        if backPill?.contains(location) == true {
            transitionToStart()
            return
        }

        if let section = homeMenu.section(at: location, in: self) {
            setActiveSection(section, animated: true)
            return
        }

        if handleCharacterRailTap(at: location) {
            return
        }

        if startButton.contains(location) {
            transitionToNext()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning, !didSwipeInCurrentTouch else { return }
        guard activeSection == .characterSelect || didStartInCharacterStage else { return }
        guard let touch = touches.first else { return }

        let dx = touch.location(in: self).x - swipeStartX
        if dx > GameConfig.characterHomeSwipeThreshold {
            didSwipeInCurrentTouch = true
            selectCharacter(at: currentIndex - 1, animated: true)
        } else if dx < -GameConfig.characterHomeSwipeThreshold {
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

    // MARK: - Transition
    private func transitionToStart() {
        guard let view = self.view else { return }
        isTransitioning = true
        let scene = StartScene.newStartScene()
        let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
        view.presentScene(scene, transition: fade)
    }

    private func transitionToNext() {
        guard let view = self.view else { return }
        isTransitioning = true
        preferenceRepo.save(selectedCharacterID)
        let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
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
}
