//
//  PixelPanelNode.swift
//  GanhoMusic Shared
//
//  R3 디자인 시스템 v3 컴포넌트 (03_UI §5) — 패널.
//  ink800 면 + 2px line500 보더(패널만 4pt 라운드 허용) + 하드섀도(블러 0, 오프셋 (0,-3)).
//  옵션 헤더 슬롯: h2 라벨 + 좌측 4px 액센트 바. 씬 비의존 — addChild만으로 동작.
//

import SpriteKit
import UIKit

/// v3 패널. 면·보더·하드섀도 + 옵션 헤더(제목 + 액센트 바).
final class PixelPanelNode: SKNode {

    /// 패널 면 크기 (섀도·헤더 제외 본체).
    let panelSize: CGSize

    /// 내부 적층 — 섀도(0) < 면(1) < 헤더(2). 외부 적층은 호출측이 ZOrder.Layer로.
    private enum InnerZ {
        static let shadow: CGFloat = 0
        static let face: CGFloat = 1
        static let header: CGFloat = 2
    }

    // MARK: - Init
    /// - Parameters:
    ///   - size: 패널 면 크기.
    ///   - title: 옵션 헤더 제목 (h2). nil이면 헤더 없음.
    ///   - accent: 헤더 좌측 4px 액센트 바 색. nil이면 textHi 바.
    ///   - shadowColor: 하드섀도 단색 (기본 ink900 — Deep 계열 파라미터화 가능).
    init(size: CGSize,
         title: String? = nil,
         accent: UIColor? = nil,
         shadowColor: UIColor = Palette.ink900) {
        panelSize = size
        super.init()

        addChild(Self.makePlate(size: size,
                                fill: shadowColor,
                                stroke: nil,
                                offset: UILayout.v3HardShadowOffset,
                                z: InnerZ.shadow))
        addChild(Self.makePlate(size: size,
                                fill: Palette.ink800,
                                stroke: Palette.line500,
                                offset: CGVector(dx: 0, dy: 0),
                                z: InnerZ.face))
        if let title = title {
            addChild(makeHeader(title: title, accent: accent ?? Palette.textHi))
        }
    }

    @available(*, unavailable, message: "Use init(size:title:accent:shadowColor:) instead.")
    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Build
    /// 4pt 라운드 판 — 면/섀도 공용. 정수 좌표 스냅 (03_UI §1 원칙 2).
    private static func makePlate(size: CGSize,
                                  fill: UIColor,
                                  stroke: UIColor?,
                                  offset: CGVector,
                                  z: CGFloat) -> SKShapeNode {
        let rect = CGRect(x: (-size.width / 2).rounded(),
                          y: (-size.height / 2).rounded(),
                          width: size.width.rounded(),
                          height: size.height.rounded())
        let plate = SKShapeNode(rect: rect, cornerRadius: UILayout.v3PanelCornerRadius)
        plate.fillColor = fill
        plate.position = CGPoint(x: offset.dx, y: offset.dy)
        plate.zPosition = z
        if let stroke = stroke {
            plate.strokeColor = stroke
            plate.lineWidth = UILayout.v3BorderWidth
        } else {
            plate.strokeColor = .clear
            plate.lineWidth = 0
        }
        return plate
    }

    /// 헤더 — 좌상단 4px 액센트 바 + h2 제목.
    private func makeHeader(title: String, accent: UIColor) -> SKNode {
        let header = SKNode()
        header.zPosition = InnerZ.header

        let headerY = (panelSize.height / 2 - UILayout.Space.s16 - UILayout.Space.s8).rounded()
        let leftX = (-panelSize.width / 2 + UILayout.Space.s16).rounded()

        let bar = SKSpriteNode(
            color: accent,
            size: CGSize(width: UILayout.Space.s4, height: UILayout.Space.s16)
        )
        bar.position = CGPoint(x: leftX + UILayout.Space.s4 / 2, y: headerY)
        header.addChild(bar)

        let label = SKLabelNode(fontNamed: Typography.V3.h2.fontName)
        label.text = title
        label.fontSize = Typography.V3.h2.size
        label.fontColor = Palette.textHi
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: (leftX + UILayout.Space.s4 + UILayout.Space.s8).rounded(),
                                 y: headerY)
        header.addChild(label)
        return header
    }
}
