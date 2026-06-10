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
    private let titleLabel = SKLabelNode(fontNamed: Typography.fontDisplay)
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
        zPosition = ZOrder.characterHomePanelZPosition
        setupPanel()
        setupRows()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupPanel() {
        background.fillColor = UIColor.ganhoPaper.withAlphaComponent(UILayout.characterHomePanelFillAlpha)
        background.strokeColor = UIColor.ganhoNavyDeep.withAlphaComponent(UILayout.characterHomePanelStrokeAlpha)
        background.lineWidth = UILayout.characterHomePanelLineWidth
        addChild(background)

        titleLabel.text = UILayout.characterHomeRecordTitleText
        titleLabel.fontSize = UILayout.characterHomePanelTitleFontSize
        titleLabel.fontColor = .ganhoNavyDeep
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.zPosition = 2
        addChild(titleLabel)
    }

    private func setupRows() {
        for difficulty in Difficulty.allCases {
            let row = SKShapeNode()
            row.lineWidth = UILayout.characterHomePanelLineWidth
            row.zPosition = 1
            rowBackgrounds[difficulty] = row
            addChild(row)

            let difficultyLabel = makeLabel(fontName: Typography.fontDisplay)
            difficultyLabel.text = difficulty.displayName
            difficultyLabels[difficulty] = difficultyLabel
            addChild(difficultyLabel)

            let bestLabel = makeLabel(fontName: Typography.fontNumeric)
            bestLabels[difficulty] = bestLabel
            addChild(bestLabel)

            let targetLabel = makeLabel(fontName: Typography.fontBody)
            targetLabels[difficulty] = targetLabel
            addChild(targetLabel)

            let statusLabel = makeLabel(fontName: Typography.fontDisplay)
            statusLabel.horizontalAlignmentMode = .right
            statusLabels[difficulty] = statusLabel
            addChild(statusLabel)
        }
    }

    private func makeLabel(fontName: String) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: fontName)
        label.fontSize = UILayout.characterHomePanelBodyFontSize
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
                ? "\(bestScore)\(UILayout.characterHomePointSuffixText)"
                : UILayout.characterHomeNoRecordText
            targetLabels[difficulty]?.text = "\(UILayout.characterHomeTargetPrefixText) \(targetScore)\(UILayout.characterHomePointSuffixText)"
            statusLabels[difficulty]?.text = achieved
                ? UILayout.characterHomeAchievedText
                : UILayout.characterHomeLockedText
            statusLabels[difficulty]?.fontColor = achieved ? .ganhoCoralPrimary : .ganhoNavyMuted
            rowBackgrounds[difficulty]?.fillColor = achieved
                ? difficulty.color.withAlphaComponent(UILayout.characterHomePanelFillAlpha)
                : UIColor.ganhoPaper.withAlphaComponent(UILayout.characterHomePanelFillAlpha)
            rowBackgrounds[difficulty]?.strokeColor = achieved
                ? difficulty.color
                : UIColor.ganhoNavyDeep.withAlphaComponent(UILayout.characterHomePanelStrokeAlpha)
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
            cornerWidth: UILayout.characterHomePanelCornerRadius,
            cornerHeight: UILayout.characterHomePanelCornerRadius,
            transform: nil
        )
        let leftX = -size.width / 2 + UILayout.characterHomePanelHorizontalInset
        let rightX = size.width / 2 - UILayout.characterHomePanelHorizontalInset
        let topY = size.height / 2 - UILayout.characterHomePanelVerticalInset
        titleLabel.position = CGPoint(x: leftX, y: topY)

        let rowWidth = size.width - UILayout.characterHomePanelHorizontalInset * 2
        let firstRowY = topY
            - UILayout.characterHomePanelTitleFontSize
            - UILayout.characterHomeDetailPanelGap
            - UILayout.characterHomeRecordRowHeight / 2
        for (index, difficulty) in Difficulty.allCases.enumerated() {
            let y = firstRowY - CGFloat(index) * (
                UILayout.characterHomeRecordRowHeight + UILayout.characterHomeAchievementBadgeGap
            )
            rowBackgrounds[difficulty]?.path = CGPath(
                roundedRect: CGRect(
                    x: -rowWidth / 2,
                    y: -UILayout.characterHomeRecordRowHeight / 2,
                    width: rowWidth,
                    height: UILayout.characterHomeRecordRowHeight
                ),
                cornerWidth: UILayout.characterHomePanelCornerRadius / 2,
                cornerHeight: UILayout.characterHomePanelCornerRadius / 2,
                transform: nil
            )
            rowBackgrounds[difficulty]?.position = CGPoint(x: 0, y: y)
            difficultyLabels[difficulty]?.position = CGPoint(
                x: leftX + UILayout.characterHomeAchievementBadgeGap,
                y: y + UILayout.characterHomePanelSmallFontSize
            )
            bestLabels[difficulty]?.position = CGPoint(
                x: leftX + UILayout.characterHomeAchievementBadgeGap,
                y: y - UILayout.characterHomePanelSmallFontSize
            )
            targetLabels[difficulty]?.position = CGPoint(
                x: leftX + rowWidth / 2,
                y: y - UILayout.characterHomePanelSmallFontSize
            )
            statusLabels[difficulty]?.position = CGPoint(
                x: rightX - UILayout.characterHomeAchievementBadgeGap,
                y: y + UILayout.characterHomePanelSmallFontSize
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
        alpha = isFocused ? 1.0 : UILayout.characterHomeUnfocusedAlpha
        background.strokeColor = isFocused
            ? UIColor.ganhoCoralPrimary.withAlphaComponent(UILayout.characterHomePanelFocusedStrokeAlpha)
            : UIColor.ganhoNavyDeep.withAlphaComponent(UILayout.characterHomePanelStrokeAlpha)
        let targetScale = layoutScale * (isFocused ? UILayout.characterHomeFocusedScale : 1.0)
        removeAction(forKey: UILayout.characterHomeSectionFocusActionKey)
        if animated {
            let action = SKAction.scale(
                to: targetScale,
                duration: UILayout.characterHomeFocusAnimationDuration
            )
            action.timingMode = .easeInEaseOut
            run(action, withKey: UILayout.characterHomeSectionFocusActionKey)
        } else {
            setScale(targetScale)
        }
    }
}
