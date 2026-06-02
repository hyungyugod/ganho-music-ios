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
        zPosition = GameConfig.hospitalPropZPosition
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
            width: size.width * GameConfig.hospitalBedPillowWidthRatio,
            height: size.height * GameConfig.hospitalBedPillowHeightRatio
        )
        let pillow = roundedRect(
            size: pillowSize,
            fillColor: .ganhoIngameRewardMint,
            strokeColor: .ganhoIngameWallHighlight
        )
        pillow.position = CGPoint(
            x: -size.width * GameConfig.hospitalBedPillowOffsetXRatio,
            y: size.height * GameConfig.hospitalBedPillowOffsetYRatio
        )
        addChild(pillow)

        let blanketSize = CGSize(
            width: size.width * GameConfig.hospitalBedBlanketWidthRatio,
            height: size.height * GameConfig.hospitalBedBlanketHeightRatio
        )
        let blanket = roundedRect(
            size: blanketSize,
            fillColor: .ganhoIngameFloorB,
            strokeColor: .ganhoIngameWallHighlight
        )
        blanket.position = CGPoint(
            x: size.width * GameConfig.hospitalBedBlanketOffsetXRatio,
            y: -size.height * GameConfig.hospitalBedBlanketOffsetYRatio
        )
        addChild(blanket)
    }

    private func buildCurtain(size: CGSize) {
        let rail = SKSpriteNode(
            color: .ganhoIngameWallShadow,
            size: CGSize(width: size.width, height: GameConfig.hospitalCurtainRailHeight)
        )
        rail.position = CGPoint(
            x: 0,
            y: size.height / 2 - GameConfig.hospitalCurtainRailHeight / 2
        )
        addChild(rail)

        let stripeWidth = size.width / CGFloat(GameConfig.hospitalCurtainStripeCount)
        for index in 0..<GameConfig.hospitalCurtainStripeCount {
            let stripe = SKSpriteNode(
                color: index % 2 == 0 ? .ganhoIngameWallHighlight : .ganhoIngameRewardMint,
                size: CGSize(width: stripeWidth, height: size.height - GameConfig.hospitalCurtainRailHeight)
            )
            stripe.position = CGPoint(
                x: -size.width / 2 + stripeWidth / 2 + CGFloat(index) * stripeWidth,
                y: -GameConfig.hospitalCurtainRailHeight / 2
            )
            stripe.alpha = GameConfig.hospitalPropSoftAlpha
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

        let drawerHeight = size.height / CGFloat(GameConfig.hospitalCabinetDrawerCount)
        for index in 0..<GameConfig.hospitalCabinetDrawerCount {
            let drawer = roundedRect(
                size: CGSize(
                    width: size.width * GameConfig.hospitalCabinetDrawerWidthRatio,
                    height: drawerHeight * GameConfig.hospitalCabinetDrawerHeightRatio
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
            size: CGSize(width: size.width, height: size.height * GameConfig.hospitalCartTrayHeightRatio),
            fillColor: .ganhoPaper,
            strokeColor: .ganhoIngameWallShadow
        )
        tray.position = CGPoint(x: 0, y: size.height * GameConfig.hospitalCartTrayOffsetYRatio)
        addChild(tray)

        let legHeight = size.height * GameConfig.hospitalCartLegHeightRatio
        let legWidth = GameConfig.hospitalCartLegWidth
        for xOffset in [
            -size.width * GameConfig.hospitalCartLegOffsetXRatio,
            size.width * GameConfig.hospitalCartLegOffsetXRatio
        ] {
            let leg = SKSpriteNode(
                color: .ganhoIngameWallShadow,
                size: CGSize(width: legWidth, height: legHeight)
            )
            leg.position = CGPoint(x: xOffset, y: -size.height * GameConfig.hospitalCartLegOffsetYRatio)
            addChild(leg)

            let wheel = SKShapeNode(circleOfRadius: GameConfig.hospitalCartWheelRadius)
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
            cornerRadius: GameConfig.hospitalPropCornerRadius
        )
        node.fillColor = fillColor
        node.strokeColor = strokeColor
        node.lineWidth = GameConfig.hospitalPropLineWidth
        return node
    }
}
