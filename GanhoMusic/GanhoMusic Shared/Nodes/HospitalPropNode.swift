//
//  HospitalPropNode.swift
//  GanhoMusic Shared
//
//  Sprint 6 - Visual-only hospital props.
//

import SpriteKit
import UIKit

enum HospitalPropKind {
    case bed
    case curtain
    case cabinet
    case cart
}

/// 병실 분위기를 보강하는 충돌 없는 시각 전용 소품.
final class HospitalPropNode: SKNode {

    // MARK: - Init
    init(kind: HospitalPropKind, size: CGSize) {
        super.init()
        name = "hospitalProp"
        zPosition = ZOrder.hospitalPropZPosition
        switch kind {
        case .bed:
            buildBed(size: size)
        case .curtain:
            buildCurtain(size: size)
        case .cabinet:
            buildCabinet(size: size)
        case .cart:
            buildCart(size: size)
        }
    }

    @available(*, unavailable, message: "Use init(kind:size:) instead.")
    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    // MARK: - Builders
    private func buildBed(size: CGSize) {
        let base = roundedRect(
            size: size,
            fillColor: .ganhoPaper,
            strokeColor: .ganhoIngameWallShadow
        )
        addChild(base)

        let pillowSize = CGSize(
            width: size.width * UILayout.hospitalBedPillowWidthRatio,
            height: size.height * UILayout.hospitalBedPillowHeightRatio
        )
        let pillow = roundedRect(
            size: pillowSize,
            fillColor: .ganhoIngameRewardMint,
            strokeColor: .ganhoIngameWallHighlight
        )
        pillow.position = CGPoint(
            x: -size.width * UILayout.hospitalBedPillowOffsetXRatio,
            y: size.height * UILayout.hospitalBedPillowOffsetYRatio
        )
        addChild(pillow)

        let blanketSize = CGSize(
            width: size.width * UILayout.hospitalBedBlanketWidthRatio,
            height: size.height * UILayout.hospitalBedBlanketHeightRatio
        )
        let blanket = roundedRect(
            size: blanketSize,
            fillColor: .ganhoIngameFloorB,
            strokeColor: .ganhoIngameWallHighlight
        )
        blanket.position = CGPoint(
            x: size.width * UILayout.hospitalBedBlanketOffsetXRatio,
            y: -size.height * UILayout.hospitalBedBlanketOffsetYRatio
        )
        addChild(blanket)
    }

    private func buildCurtain(size: CGSize) {
        let rail = SKSpriteNode(
            color: .ganhoIngameWallShadow,
            size: CGSize(width: size.width, height: UILayout.hospitalCurtainRailHeight)
        )
        rail.position = CGPoint(
            x: 0,
            y: size.height / 2 - UILayout.hospitalCurtainRailHeight / 2
        )
        addChild(rail)

        let stripeWidth = size.width / CGFloat(UILayout.hospitalCurtainStripeCount)
        for index in 0..<UILayout.hospitalCurtainStripeCount {
            let stripe = SKSpriteNode(
                color: index % 2 == 0 ? .ganhoIngameWallHighlight : .ganhoIngameRewardMint,
                size: CGSize(width: stripeWidth, height: size.height - UILayout.hospitalCurtainRailHeight)
            )
            stripe.position = CGPoint(
                x: -size.width / 2 + stripeWidth / 2 + CGFloat(index) * stripeWidth,
                y: -UILayout.hospitalCurtainRailHeight / 2
            )
            stripe.alpha = UILayout.hospitalPropSoftAlpha
            addChild(stripe)
        }
    }

    private func buildCabinet(size: CGSize) {
        let base = roundedRect(
            size: size,
            fillColor: .ganhoIngameWallHighlight,
            strokeColor: .ganhoIngameWallShadow
        )
        addChild(base)

        let drawerHeight = size.height / CGFloat(UILayout.hospitalCabinetDrawerCount)
        for index in 0..<UILayout.hospitalCabinetDrawerCount {
            let drawer = roundedRect(
                size: CGSize(
                    width: size.width * UILayout.hospitalCabinetDrawerWidthRatio,
                    height: drawerHeight * UILayout.hospitalCabinetDrawerHeightRatio
                ),
                fillColor: .ganhoIngameFloorA,
                strokeColor: .ganhoIngameWallShadow
            )
            drawer.position = CGPoint(
                x: 0,
                y: -size.height / 2 + drawerHeight / 2 + CGFloat(index) * drawerHeight
            )
            addChild(drawer)
        }
    }

    private func buildCart(size: CGSize) {
        let tray = roundedRect(
            size: CGSize(width: size.width, height: size.height * UILayout.hospitalCartTrayHeightRatio),
            fillColor: .ganhoPaper,
            strokeColor: .ganhoIngameWallShadow
        )
        tray.position = CGPoint(x: 0, y: size.height * UILayout.hospitalCartTrayOffsetYRatio)
        addChild(tray)

        let legHeight = size.height * UILayout.hospitalCartLegHeightRatio
        let legWidth = UILayout.hospitalCartLegWidth
        for xOffset in [
            -size.width * UILayout.hospitalCartLegOffsetXRatio,
            size.width * UILayout.hospitalCartLegOffsetXRatio
        ] {
            let leg = SKSpriteNode(
                color: .ganhoIngameWallShadow,
                size: CGSize(width: legWidth, height: legHeight)
            )
            leg.position = CGPoint(x: xOffset, y: -size.height * UILayout.hospitalCartLegOffsetYRatio)
            addChild(leg)

            let wheel = SKShapeNode(circleOfRadius: UILayout.hospitalCartWheelRadius)
            wheel.fillColor = .ganhoIngameWallShadow
            wheel.strokeColor = .clear
            wheel.position = CGPoint(x: xOffset, y: -size.height / 2)
            addChild(wheel)
        }
    }

    // MARK: - Helpers
    private func roundedRect(size: CGSize,
                             fillColor: UIColor,
                             strokeColor: UIColor) -> SKShapeNode {
        let node = SKShapeNode(
            rectOf: size,
            cornerRadius: UILayout.hospitalPropCornerRadius
        )
        node.fillColor = fillColor
        node.strokeColor = strokeColor
        node.lineWidth = UILayout.hospitalPropLineWidth
        return node
    }
}
