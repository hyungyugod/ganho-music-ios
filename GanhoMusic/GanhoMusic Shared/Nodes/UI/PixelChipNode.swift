//
//  PixelChipNode.swift
//  GanhoMusic Shared
//
//  R3 디자인 시스템 v3 컴포넌트 (03_UI §5) — 칩.
//  caption 타이포 + 좌측 아이콘 슬롯. 변형 3: 정보(ink700 면) / 액센트(액센트색 보더 + textHi)
//  / 잠금(ink700 면 + textLo 글자). 패딩·높이는 토큰 (UILayout v3Chip*).
//

import SpriteKit
import UIKit

/// v3 칩. 보조 정보 축약 표시 (03_UI §1 원칙 5).
final class PixelChipNode: SKNode {

    /// 3변형 — switch exhaustive, default 금지.
    enum Style {
        /// 정보 — ink700 면 + textHi.
        case info
        /// 액센트 — 액센트색 보더 + textHi (면 ink800).
        case accent(UIColor)
        /// 잠금 — ink700 면 + textLo.
        case locked
    }

    /// 칩 전체 크기 (배치 계산용).
    let chipSize: CGSize

    /// 내부 적층 — 면(0) < 보더(1) < 아이콘/라벨(2).
    private enum InnerZ {
        static let face: CGFloat = 0
        static let border: CGFloat = 1
        static let content: CGFloat = 2
    }

    // MARK: - Init
    /// - Parameters:
    ///   - text: 칩 글자 (caption 토큰).
    ///   - style: 3변형.
    ///   - icon: 옵션 좌측 아이콘 슬롯 (호출측이 크기 ≤ 칩 높이로 준비).
    init(text: String, style: Style, icon: SKNode? = nil) {
        let label = SKLabelNode(fontNamed: Typography.V3.caption.fontName)
        label.text = text
        label.fontSize = Typography.V3.caption.size
        label.fontColor = Self.textColor(style: style)
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center

        // 폭 = 좌패딩 + (아이콘 + 간격) + 라벨 + 우패딩 — 정수 스냅 (03_UI §1 원칙 2).
        let iconWidth = icon.map { $0.calculateAccumulatedFrame().width + UILayout.v3ChipIconGap } ?? 0
        let width = (UILayout.v3ChipPaddingX + iconWidth
                     + label.frame.width + UILayout.v3ChipPaddingX).rounded(.up)
        chipSize = CGSize(width: width, height: UILayout.v3ChipHeight)
        super.init()

        let face = SKSpriteNode(color: Self.faceColor(style: style), size: chipSize)
        face.zPosition = InnerZ.face
        addChild(face)

        if let borderColor = Self.borderColor(style: style) {
            let rect = CGRect(x: -chipSize.width / 2, y: -chipSize.height / 2,
                              width: chipSize.width, height: chipSize.height)
            let border = SKShapeNode(rect: rect)   // 직각 — 패널만 라운드 허용 (03_UI §4)
            border.fillColor = .clear
            border.strokeColor = borderColor
            border.lineWidth = UILayout.v3BorderWidth
            border.zPosition = InnerZ.border
            addChild(border)
        }

        var cursorX = (-chipSize.width / 2 + UILayout.v3ChipPaddingX).rounded()
        if let icon = icon {
            let iconFrame = icon.calculateAccumulatedFrame()
            icon.position = CGPoint(x: cursorX + iconFrame.width / 2, y: 0)
            icon.zPosition = InnerZ.content
            addChild(icon)
            cursorX += (iconFrame.width + UILayout.v3ChipIconGap).rounded()
        }
        label.position = CGPoint(x: cursorX, y: 0)
        label.zPosition = InnerZ.content
        addChild(label)
    }

    @available(*, unavailable, message: "Use init(text:style:icon:) instead.")
    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Style Colors (토큰 경유)
    private static func faceColor(style: Style) -> UIColor {
        switch style {
        case .info:   return Palette.ink700
        case .accent: return Palette.ink800
        case .locked: return Palette.ink700
        }
    }

    private static func borderColor(style: Style) -> UIColor? {
        switch style {
        case .info:                return nil
        case .accent(let accent):  return accent
        case .locked:              return nil
        }
    }

    private static func textColor(style: Style) -> UIColor {
        switch style {
        case .info, .accent: return Palette.textHi
        case .locked:        return Palette.textLo
        }
    }
}
