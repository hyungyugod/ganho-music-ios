//
//  DarkContextChipNode.swift
//  GanhoMusic Shared
//
//  Sprint 1 · v2 Design System
//
//  navy 0.92 배경 + 골드 라벨 + 옵션 코랄 뱃지.
//  난이도 표시, 브레드크럼, HUD 슬롯, 스킬명 칩에 재사용.
//  DESIGN_RENEWAL_REQUEST.md §3.3.D.
//

import SpriteKit

/// 다크 navy 칩(α=0.92) + Jua 골드 라벨 + 옵션 코랄 뱃지.
/// 폭은 라벨 너비 기반 자동.
final class DarkContextChipNode: SKNode {

    // MARK: - Properties
    /// navy 0.92 알약 배경. fillColor = navyDeep.withAlpha(0.92), strokeColor = clear.
    private let background: SKShapeNode
    /// 본 라벨. fontName = Jua-Regular, fontColor = ganhoMusicGold.
    private let labelNode: SKLabelNode
    /// 옵션 뱃지 배경(코랄 알약). badge:nil이면 미생성.
    private let badgeNode: SKShapeNode?
    /// 옵션 뱃지 라벨(흰색). badge:nil이면 미생성.
    private let badgeLabel: SKLabelNode?

    // MARK: - Init
    /// - Parameters:
    ///   - label: 본 라벨 텍스트(Jua + 골드).
    ///   - badge: 옵션 뱃지 텍스트(코랄 알약 안 흰색). nil이면 미생성.
    init(label: String, badge: String? = nil) {
        // (1) 본 라벨 먼저 생성 — 라벨 frame.width로 칩 총 폭 계산.
        labelNode = SKLabelNode(fontNamed: GameConfig.fontDisplay)
        labelNode.text = label
        labelNode.fontSize = GameConfig.darkContextChipLabelFontSize
        labelNode.fontColor = .ganhoMusicGold
        labelNode.horizontalAlignmentMode = .left
        labelNode.verticalAlignmentMode = .center

        // (2) 옵션 뱃지 생성. badge가 있을 때만 SKShapeNode + SKLabelNode 페어를 만든다.
        let labelWidth = labelNode.frame.width
        let chipHeight = GameConfig.darkContextChipHeight
        let badgeHeight = chipHeight - GameConfig.darkContextChipBadgeVerticalInset

        if let badgeText = badge {
            let bLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
            bLabel.text = badgeText
            bLabel.fontSize = GameConfig.darkContextChipBadgeFontSize
            bLabel.fontColor = .white
            bLabel.horizontalAlignmentMode = .center
            bLabel.verticalAlignmentMode = .center
            let bgSize = CGSize(
                width: bLabel.frame.width + GameConfig.darkContextChipBadgeHorizontalPadding,
                height: badgeHeight
            )
            let bShape = SKShapeNode(
                rectOf: bgSize,
                cornerRadius: bgSize.height / 2
            )
            bShape.fillColor = .ganhoCoralPrimary
            bShape.strokeColor = .clear
            badgeLabel = bLabel
            badgeNode = bShape
        } else {
            badgeLabel = nil
            badgeNode = nil
        }

        // (3) 칩 총 폭 산출 — 좌패딩 + 라벨 + (간격 + 뱃지)? + 우패딩.
        let badgeWidth = badgeNode?.frame.width ?? 0
        let totalWidth = GameConfig.darkContextChipHorizontalPadding * 2
            + labelWidth
            + (badgeNode != nil ? GameConfig.darkContextChipBadgeSpacing + badgeWidth : 0)
        let bgSize = CGSize(
            width: totalWidth,
            height: chipHeight
        )
        background = SKShapeNode(
            rectOf: bgSize,
            cornerRadius: bgSize.height / 2
        )
        background.fillColor = UIColor.ganhoNavyDeep
            .withAlphaComponent(GameConfig.darkContextChipBgAlpha)
        background.strokeColor = .clear

        super.init()
        name = "darkContextChip"
        zPosition = 100

        // (4) 자식 부착. background → labelNode → (옵션) badgeNode/badgeLabel.
        addChild(background)
        labelNode.position = CGPoint(
            x: -bgSize.width / 2 + GameConfig.darkContextChipHorizontalPadding,
            y: 0
        )
        addChild(labelNode)
        if let bShape = badgeNode, let bLabel = badgeLabel {
            let badgeCenterX = bgSize.width / 2
                - GameConfig.darkContextChipHorizontalPadding
                - badgeWidth / 2
            bShape.position = CGPoint(x: badgeCenterX, y: 0)
            bLabel.position = CGPoint(x: badgeCenterX, y: 0)
            addChild(bShape)
            addChild(bLabel)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
