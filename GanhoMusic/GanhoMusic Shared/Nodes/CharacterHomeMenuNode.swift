//
//  CharacterHomeMenuNode.swift
//  GanhoMusic Shared
//
//  Sprint 2 - Character account home section menu.
//

import SpriteKit

/// 캐릭터 홈의 섹션 메뉴. 세로/가로 배치와 hit test를 담당한다.
final class CharacterHomeMenuNode: SKNode {

    // MARK: - Properties
    private var buttonNodes: [CharacterHomeSection: SKNode] = [:]
    private var backgroundNodes: [CharacterHomeSection: SKShapeNode] = [:]
    private var labelNodes: [CharacterHomeSection: SKLabelNode] = [:]
    private var activeSection: CharacterHomeSection = .characterSelect

    // MARK: - Init
    override init() {
        super.init()
        zPosition = GameConfig.characterHomeMenuZPosition
        setupButtons()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupButtons() {
        for section in CharacterHomeSection.allCases {
            let container = SKNode()
            container.name = "characterHomeMenu_\(section.rawValue)"

            let size = CGSize(
                width: GameConfig.characterHomeMenuButtonWidth,
                height: GameConfig.characterHomeMenuButtonHeight
            )
            let background = SKShapeNode(
                rectOf: size,
                cornerRadius: GameConfig.characterHomeMenuButtonHeight / 2
            )
            background.fillColor = UIColor.ganhoPaper.withAlphaComponent(GameConfig.characterHomePanelFillAlpha)
            background.strokeColor = UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.characterHomePanelStrokeAlpha)
            background.lineWidth = GameConfig.characterHomePanelLineWidth
            container.addChild(background)

            let label = SKLabelNode(fontNamed: GameConfig.fontDisplay)
            label.text = section.title
            label.fontSize = GameConfig.characterHomeMenuFontSize
            label.fontColor = .ganhoNavyDeep
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.position = .zero
            label.zPosition = 1
            container.addChild(label)

            buttonNodes[section] = container
            backgroundNodes[section] = background
            labelNodes[section] = label
            addChild(container)
        }
        setActiveSection(.characterSelect, animated: false)
    }

    // MARK: - Layout
    func layout(bottomMode: Bool) {
        if bottomMode {
            layoutHorizontal()
        } else {
            layoutVertical()
        }
    }

    func contentSize(bottomMode: Bool) -> CGSize {
        if bottomMode {
            let count = CGFloat(CharacterHomeSection.allCases.count)
            let width = GameConfig.characterHomeMenuButtonWidth * count
                + GameConfig.characterHomeMenuGap * max(0, count - 1)
            return CGSize(width: width, height: GameConfig.characterHomeMenuButtonHeight)
        }

        let count = CGFloat(CharacterHomeSection.allCases.count)
        let height = GameConfig.characterHomeMenuButtonHeight * count
            + GameConfig.characterHomeMenuGap * max(0, count - 1)
        return CGSize(width: GameConfig.characterHomeMenuButtonWidth, height: height)
    }

    private func layoutVertical() {
        let sections = CharacterHomeSection.allCases
        let totalHeight = contentSize(bottomMode: false).height
        let startY = totalHeight / 2 - GameConfig.characterHomeMenuButtonHeight / 2
        for (index, section) in sections.enumerated() {
            let y = startY - CGFloat(index) * (
                GameConfig.characterHomeMenuButtonHeight + GameConfig.characterHomeMenuGap
            )
            buttonNodes[section]?.position = CGPoint(x: 0, y: y)
        }
    }

    private func layoutHorizontal() {
        let sections = CharacterHomeSection.allCases
        let totalWidth = contentSize(bottomMode: true).width
        let startX = -totalWidth / 2 + GameConfig.characterHomeMenuButtonWidth / 2
        for (index, section) in sections.enumerated() {
            let x = startX + CGFloat(index) * (
                GameConfig.characterHomeMenuButtonWidth + GameConfig.characterHomeMenuGap
            )
            buttonNodes[section]?.position = CGPoint(x: x, y: 0)
        }
    }

    // MARK: - State
    func setActiveSection(_ section: CharacterHomeSection, animated: Bool) {
        activeSection = section
        for candidate in CharacterHomeSection.allCases {
            let isActive = candidate == section
            backgroundNodes[candidate]?.fillColor = isActive
                ? .ganhoCoralPrimary
                : UIColor.ganhoPaper.withAlphaComponent(GameConfig.characterHomePanelFillAlpha)
            backgroundNodes[candidate]?.strokeColor = isActive
                ? .ganhoCoralShadow
                : UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.characterHomePanelStrokeAlpha)
            labelNodes[candidate]?.fontColor = isActive ? .ganhoPaper : .ganhoNavyDeep
            guard let button = buttonNodes[candidate] else { continue }
            button.removeAction(forKey: GameConfig.characterHomeSectionFocusActionKey)
            let targetScale = isActive ? GameConfig.characterHomeFocusedScale : 1.0
            if animated {
                let action = SKAction.scale(
                    to: targetScale,
                    duration: GameConfig.characterHomeFocusAnimationDuration
                )
                action.timingMode = .easeInEaseOut
                button.run(action, withKey: GameConfig.characterHomeSectionFocusActionKey)
            } else {
                button.setScale(targetScale)
            }
        }
    }

    // MARK: - Hit Test
    func section(at scenePoint: CGPoint, in scene: SKScene) -> CharacterHomeSection? {
        let localPoint = scene.convert(scenePoint, to: self)
        for section in CharacterHomeSection.allCases {
            guard let button = buttonNodes[section] else { continue }
            if button.contains(localPoint) {
                return section
            }
        }
        return nil
    }
}
