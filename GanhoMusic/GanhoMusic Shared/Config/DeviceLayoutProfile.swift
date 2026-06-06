//
//  DeviceLayoutProfile.swift
//  GanhoMusic Shared
//
//  iPhone / iPad landscape layout profile resolver.
//

import SpriteKit
import UIKit

enum DeviceLayoutProfile {
    case phoneCompact
    case phoneRegular
    case padLandscape

    // MARK: - Resolution

    static func resolve(for scene: SKScene) -> DeviceLayoutProfile {
        let idiom = scene.view?.traitCollection.userInterfaceIdiom ?? .phone
        if idiom == .pad {
            return .padLandscape
        }
        if scene.size.height < GameConfig.compactLandscapeMinHeight {
            return .phoneCompact
        }
        return .phoneRegular
    }

    // MARK: - Menu Layout

    var menuScale: CGFloat {
        switch self {
        case .phoneCompact:
            return GameConfig.compactLayoutScale
        case .phoneRegular:
            return GameConfig.regularLayoutScale
        case .padLandscape:
            return GameConfig.ipadMenuLayoutScale
        }
    }

    var menuMaxContentWidth: CGFloat {
        switch self {
        case .phoneCompact, .phoneRegular:
            return .greatestFiniteMagnitude
        case .padLandscape:
            return GameConfig.ipadMenuMaxContentWidth
        }
    }

    var resultMaxContentWidth: CGFloat {
        switch self {
        case .phoneCompact, .phoneRegular:
            return .greatestFiniteMagnitude
        case .padLandscape:
            return GameConfig.ipadResultMaxContentWidth
        }
    }

    var scoreboardMaxContentWidth: CGFloat {
        switch self {
        case .phoneCompact, .phoneRegular:
            return .greatestFiniteMagnitude
        case .padLandscape:
            return GameConfig.ipadScoreboardMaxContentWidth
        }
    }

    // MARK: - Ingame Layout

    var ingameHUDScale: CGFloat {
        switch self {
        case .phoneCompact, .phoneRegular:
            return GameConfig.regularLayoutScale
        case .padLandscape:
            return GameConfig.ipadIngameHUDScale
        }
    }

    var ingameControlScale: CGFloat {
        switch self {
        case .phoneCompact, .phoneRegular:
            return GameConfig.regularLayoutScale
        case .padLandscape:
            return GameConfig.ipadIngameControlScale
        }
    }

    var ingameTopButtonScale: CGFloat {
        switch self {
        case .phoneCompact, .phoneRegular:
            return GameConfig.regularLayoutScale
        case .padLandscape:
            return GameConfig.ipadIngameTopButtonScale
        }
    }

    func cameraScale(for size: CGSize) -> CGFloat {
        switch self {
        case .phoneCompact, .phoneRegular:
            return GameConfig.regularLayoutScale
        case .padLandscape:
            guard size.width > 0, size.height > 0 else {
                return GameConfig.regularLayoutScale
            }
            let fitWidth = GameConfig.mapWidth / size.width
            let fitHeight = GameConfig.mapHeight / size.height
            let fitScale = min(fitWidth, fitHeight)
            return max(
                GameConfig.ipadCameraScaleFloor,
                min(GameConfig.ipadCameraScaleCeiling, fitScale)
            )
        }
    }
}
