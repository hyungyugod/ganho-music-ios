//
//  RecordSummaryPanelNode.swift
//  GanhoMusic Shared
//
//  Sprint 2 - Character home record summary panel.
//

import SpriteKit

/// 선택 캐릭터의 난이도별 최고 기록 패널. Repository 대신 CharacterHomeSnapshot만 표시한다.
final class RecordSummaryPanelNode: SKNode {

    // MARK: - Properties
    private let background = SKShapeNode()
    private let titleLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    private var rowBackgrounds: [Difficulty: SKShapeNode] = [:]
    private var difficultyLabels: [Difficulty: SKLabelNode] = [:]
    private var bestLabels: [Difficulty: SKLabelNode] = [:]
    private var targetLabels: [Difficulty: SKLabelNode] = [:]
    private var statusLabels: [Difficulty: SKLabelNode] = [:]
    private var layoutScale: CGFloat = 1.0
    private var isFocused = false

    // MARK: - Init
    override init() {
        super.init()
        zPosition = GameConfig.characterHomePanelZPosition
        setupPanel()
        setupRows()
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

        titleLabel.text = GameConfig.characterHomeRecordTitleText
        titleLabel.fontSize = GameConfig.characterHomePanelTitleFontSize
        titleLabel.fontColor = .ganhoNavyDeep
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.zPosition = 2
        addChild(titleLabel)
    }

    private func setupRows() {
        for difficulty in Difficulty.allCases {
            let row = SKShapeNode()
            row.lineWidth = GameConfig.characterHomePanelLineWidth
            row.zPosition = 1
            rowBackgrounds[difficulty] = row
            addChild(row)

            let difficultyLabel = makeLabel(fontName: GameConfig.fontDisplay)
            difficultyLabel.text = difficulty.displayName
            difficultyLabels[difficulty] = difficultyLabel
            addChild(difficultyLabel)

            let bestLabel = makeLabel(fontName: GameConfig.fontNumeric)
            bestLabels[difficulty] = bestLabel
            addChild(bestLabel)

            let targetLabel = makeLabel(fontName: GameConfig.fontBody)
            targetLabels[difficulty] = targetLabel
            addChild(targetLabel)

            let statusLabel = makeLabel(fontName: GameConfig.fontDisplay)
            statusLabel.horizontalAlignmentMode = .right
            statusLabels[difficulty] = statusLabel
            addChild(statusLabel)
        }
    }

    private func makeLabel(fontName: String) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: fontName)
        label.fontSize = GameConfig.characterHomePanelBodyFontSize
        label.fontColor = .ganhoNavyDeep
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.zPosition = 2
        return label
    }

    // MARK: - Update
    func update(snapshot: CharacterHomeSnapshot) {
        for difficulty in Difficulty.allCases {
            let record = snapshot.record(for: difficulty)
            let bestScore = record?.bestScore ?? 0
            let targetScore = record?.targetScore ?? difficulty.targetScore
            let achieved = record?.isAchieved ?? false

            bestLabels[difficulty]?.text = bestScore > 0
                ? "\(bestScore)\(GameConfig.characterHomePointSuffixText)"
                : GameConfig.characterHomeNoRecordText
            targetLabels[difficulty]?.text = "\(GameConfig.characterHomeTargetPrefixText) \(targetScore)\(GameConfig.characterHomePointSuffixText)"
            statusLabels[difficulty]?.text = achieved
                ? GameConfig.characterHomeAchievedText
                : GameConfig.characterHomeLockedText
            statusLabels[difficulty]?.fontColor = achieved ? .ganhoCoralPrimary : .ganhoNavyMuted
            rowBackgrounds[difficulty]?.fillColor = achieved
                ? difficulty.color.withAlphaComponent(GameConfig.characterHomePanelFillAlpha)
                : UIColor.ganhoPaper.withAlphaComponent(GameConfig.characterHomePanelFillAlpha)
            rowBackgrounds[difficulty]?.strokeColor = achieved
                ? difficulty.color
                : UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.characterHomePanelStrokeAlpha)
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
        let leftX = -size.width / 2 + GameConfig.characterHomePanelHorizontalInset
        let rightX = size.width / 2 - GameConfig.characterHomePanelHorizontalInset
        let topY = size.height / 2 - GameConfig.characterHomePanelVerticalInset
        titleLabel.position = CGPoint(x: leftX, y: topY)

        let rowWidth = size.width - GameConfig.characterHomePanelHorizontalInset * 2
        let firstRowY = topY
            - GameConfig.characterHomePanelTitleFontSize
            - GameConfig.characterHomeDetailPanelGap
            - GameConfig.characterHomeRecordRowHeight / 2
        for (index, difficulty) in Difficulty.allCases.enumerated() {
            let y = firstRowY - CGFloat(index) * (
                GameConfig.characterHomeRecordRowHeight + GameConfig.characterHomeAchievementBadgeGap
            )
            rowBackgrounds[difficulty]?.path = CGPath(
                roundedRect: CGRect(
                    x: -rowWidth / 2,
                    y: -GameConfig.characterHomeRecordRowHeight / 2,
                    width: rowWidth,
                    height: GameConfig.characterHomeRecordRowHeight
                ),
                cornerWidth: GameConfig.characterHomePanelCornerRadius / 2,
                cornerHeight: GameConfig.characterHomePanelCornerRadius / 2,
                transform: nil
            )
            rowBackgrounds[difficulty]?.position = CGPoint(x: 0, y: y)
            difficultyLabels[difficulty]?.position = CGPoint(
                x: leftX + GameConfig.characterHomeAchievementBadgeGap,
                y: y + GameConfig.characterHomePanelSmallFontSize
            )
            bestLabels[difficulty]?.position = CGPoint(
                x: leftX + GameConfig.characterHomeAchievementBadgeGap,
                y: y - GameConfig.characterHomePanelSmallFontSize
            )
            targetLabels[difficulty]?.position = CGPoint(
                x: leftX + rowWidth / 2,
                y: y - GameConfig.characterHomePanelSmallFontSize
            )
            statusLabels[difficulty]?.position = CGPoint(
                x: rightX - GameConfig.characterHomeAchievementBadgeGap,
                y: y + GameConfig.characterHomePanelSmallFontSize
            )
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
