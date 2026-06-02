//
//  AchievementStripNode.swift
//  GanhoMusic Shared
//
//  Sprint 2 - Character home achievement summary.
//

import SpriteKit

/// 졸업장/난이도 목표 달성 요약 패널. Repository 대신 CharacterHomeSnapshot만 표시한다.
final class AchievementStripNode: SKNode {

    // MARK: - Properties
    private let background = SKShapeNode()
    private let titleLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    private let countLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    private let selectedBadge = SKShapeNode()
    private let selectedBadgeLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    private var badgeNodes: [Difficulty: SKShapeNode] = [:]
    private var badgeLabels: [Difficulty: SKLabelNode] = [:]
    private var layoutScale: CGFloat = 1.0
    private var isFocused = false

    // MARK: - Init
    override init() {
        super.init()
        zPosition = GameConfig.characterHomePanelZPosition
        setupPanel()
        setupLabels()
        setupDifficultyBadges()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupPanel() {
        background.fillColor = UIColor.ganhoPaper.withAlphaComponent(GameConfig.characterHomePanelFillAlpha)
        background.strokeColor = UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.characterHomePanelStrokeAlpha)
        background.lineWidth = GameConfig.characterHomePanelLineWidth
        addChild(background)

        selectedBadge.strokeColor = .clear
        selectedBadge.zPosition = 1
        addChild(selectedBadge)
    }

    private func setupLabels() {
        titleLabel.text = GameConfig.characterHomeAchievementTitleText
        titleLabel.fontSize = GameConfig.characterHomePanelTitleFontSize
        titleLabel.fontColor = .ganhoNavyDeep
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.zPosition = 2
        addChild(titleLabel)

        countLabel.fontSize = GameConfig.characterHomePanelBodyFontSize
        countLabel.fontColor = .ganhoNavyMuted
        countLabel.horizontalAlignmentMode = .right
        countLabel.verticalAlignmentMode = .center
        countLabel.zPosition = 2
        addChild(countLabel)

        selectedBadgeLabel.fontSize = GameConfig.characterHomePanelSmallFontSize
        selectedBadgeLabel.fontColor = .ganhoPaper
        selectedBadgeLabel.horizontalAlignmentMode = .center
        selectedBadgeLabel.verticalAlignmentMode = .center
        selectedBadgeLabel.zPosition = 2
        addChild(selectedBadgeLabel)
    }

    private func setupDifficultyBadges() {
        for difficulty in Difficulty.allCases {
            let node = SKShapeNode()
            node.lineWidth = GameConfig.characterHomePanelLineWidth
            node.zPosition = 1
            let label = SKLabelNode(fontNamed: GameConfig.fontDisplay)
            label.fontSize = GameConfig.characterHomePanelSmallFontSize
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.zPosition = 2
            badgeNodes[difficulty] = node
            badgeLabels[difficulty] = label
            addChild(node)
            addChild(label)
        }
    }

    // MARK: - Update
    func update(snapshot: CharacterHomeSnapshot) {
        countLabel.text = "\(GameConfig.characterHomeGraduationLabelText) \(snapshot.totalGraduationCount)/\(CharacterID.allCases.count)"
        selectedBadge.fillColor = snapshot.isSelectedCharacterGraduated
            ? .ganhoCoralPrimary
            : .ganhoNavyMuted
        selectedBadgeLabel.text = snapshot.isSelectedCharacterGraduated
            ? GameConfig.characterHomeSelectedGraduateText
            : GameConfig.characterHomeSelectedLockedText

        for difficulty in Difficulty.allCases {
            let record = snapshot.record(for: difficulty)
            let achieved = record?.isAchieved ?? false
            badgeNodes[difficulty]?.fillColor = achieved
                ? difficulty.color.withAlphaComponent(GameConfig.characterHomePanelFillAlpha)
                : UIColor.ganhoNavyMuted.withAlphaComponent(GameConfig.characterHomePanelStrokeAlpha)
            badgeNodes[difficulty]?.strokeColor = achieved
                ? difficulty.color
                : UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.characterHomePanelStrokeAlpha)
            badgeLabels[difficulty]?.fontColor = achieved ? .ganhoNavyDeep : .ganhoNavyMuted
            badgeLabels[difficulty]?.text = "\(difficulty.shortName) \(achieved ? GameConfig.characterHomeAchievedText : GameConfig.characterHomeLockedText)"
        }
    }

    // MARK: - Layout
    func layout(size: CGSize) {
        background.path = CGPath(
            roundedRect: CGRect(
                x: -size.width / 2,
                y: -size.height / 2,
                width: size.width,
                height: size.height
            ),
            cornerWidth: GameConfig.characterHomePanelCornerRadius,
            cornerHeight: GameConfig.characterHomePanelCornerRadius,
            transform: nil
        )
        selectedBadge.path = CGPath(
            roundedRect: CGRect(
                x: -size.width / 2 + GameConfig.characterHomePanelHorizontalInset,
                y: -GameConfig.characterHomeAchievementBadgeHeight / 2,
                width: size.width - GameConfig.characterHomePanelHorizontalInset * 2,
                height: GameConfig.characterHomeAchievementBadgeHeight
            ),
            cornerWidth: GameConfig.characterHomeAchievementBadgeHeight / 2,
            cornerHeight: GameConfig.characterHomeAchievementBadgeHeight / 2,
            transform: nil
        )

        let leftX = -size.width / 2 + GameConfig.characterHomePanelHorizontalInset
        let rightX = size.width / 2 - GameConfig.characterHomePanelHorizontalInset
        let topY = size.height / 2 - GameConfig.characterHomePanelVerticalInset
        titleLabel.position = CGPoint(x: leftX, y: topY)
        countLabel.position = CGPoint(x: rightX, y: topY)

        let badgeCenterY = topY
            - GameConfig.characterHomePanelTitleFontSize
            - GameConfig.characterHomeDetailPanelGap
        selectedBadge.position = CGPoint(x: 0, y: badgeCenterY)
        selectedBadgeLabel.position = CGPoint(x: 0, y: badgeCenterY)

        let difficultyWidth = (
            size.width
            - GameConfig.characterHomePanelHorizontalInset * 2
            - GameConfig.characterHomeAchievementBadgeGap * CGFloat(Difficulty.allCases.count - 1)
        ) / CGFloat(Difficulty.allCases.count)
        let startX = leftX + difficultyWidth / 2
        let difficultyY = -size.height / 2
            + GameConfig.characterHomePanelVerticalInset
            + GameConfig.characterHomeAchievementBadgeHeight / 2
        for (index, difficulty) in Difficulty.allCases.enumerated() {
            badgeNodes[difficulty]?.path = CGPath(
                roundedRect: CGRect(
                    x: -difficultyWidth / 2,
                    y: -GameConfig.characterHomeAchievementBadgeHeight / 2,
                    width: difficultyWidth,
                    height: GameConfig.characterHomeAchievementBadgeHeight
                ),
                cornerWidth: GameConfig.characterHomeAchievementBadgeHeight / 2,
                cornerHeight: GameConfig.characterHomeAchievementBadgeHeight / 2,
                transform: nil
            )
            let x = startX + CGFloat(index) * (
                difficultyWidth + GameConfig.characterHomeAchievementBadgeGap
            )
            badgeNodes[difficulty]?.position = CGPoint(x: x, y: difficultyY)
            badgeLabels[difficulty]?.position = CGPoint(x: x, y: difficultyY)
        }
    }

    // MARK: - Focus
    func setLayoutScale(_ scale: CGFloat) {
        layoutScale = scale
        applyFocus(animated: false)
    }

    func setFocused(_ focused: Bool, animated: Bool) {
        isFocused = focused
        applyFocus(animated: animated)
    }

    private func applyFocus(animated: Bool) {
        alpha = isFocused ? 1.0 : GameConfig.characterHomeUnfocusedAlpha
        background.strokeColor = isFocused
            ? UIColor.ganhoCoralPrimary.withAlphaComponent(GameConfig.characterHomePanelFocusedStrokeAlpha)
            : UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.characterHomePanelStrokeAlpha)
        let targetScale = layoutScale * (isFocused ? GameConfig.characterHomeFocusedScale : 1.0)
        removeAction(forKey: GameConfig.characterHomeSectionFocusActionKey)
        if animated {
            let action = SKAction.scale(
                to: targetScale,
                duration: GameConfig.characterHomeFocusAnimationDuration
            )
            action.timingMode = .easeInEaseOut
            run(action, withKey: GameConfig.characterHomeSectionFocusActionKey)
        } else {
            setScale(targetScale)
        }
    }
}
