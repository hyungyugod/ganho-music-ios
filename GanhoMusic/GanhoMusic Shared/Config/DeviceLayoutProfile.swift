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
        if scene.size.height < UILayout.compactLandscapeMinHeight {
            return .phoneCompact
        }
        return .phoneRegular
    }

    // MARK: - Menu Layout

    var menuScale: CGFloat {
        switch self {
        case .phoneCompact:
            return UILayout.compactLayoutScale
        case .phoneRegular:
            return UILayout.regularLayoutScale
        case .padLandscape:
            return UILayout.ipadMenuLayoutScale
        }
    }

    var menuMaxContentWidth: CGFloat {
        switch self {
        case .phoneCompact, .phoneRegular:
            return .greatestFiniteMagnitude
        case .padLandscape:
            return UILayout.ipadMenuMaxContentWidth
        }
    }

    // R5 — result/scoreboard 전용 콘텐츠 폭 lookup 2종 삭제 (참조 0 실증 — 기능 9).
    // 두 씬은 BaseMenuScene.menuSafeInsets()(menuMaxContentWidth)로 통일.

    // MARK: - Ingame Layout

    var ingameHUDScale: CGFloat {
        switch self {
        case .phoneCompact, .phoneRegular:
            return UILayout.regularLayoutScale
        case .padLandscape:
            return UILayout.ipadIngameHUDScale
        }
    }

    var ingameControlScale: CGFloat {
        switch self {
        case .phoneCompact, .phoneRegular:
            return UILayout.regularLayoutScale
        case .padLandscape:
            return UILayout.ipadIngameControlScale
        }
    }

    var ingameTopButtonScale: CGFloat {
        switch self {
        case .phoneCompact, .phoneRegular:
            return UILayout.regularLayoutScale
        case .padLandscape:
            return UILayout.ipadIngameTopButtonScale
        }
    }

    func cameraScale(for size: CGSize) -> CGFloat {
        switch self {
        case .phoneCompact, .phoneRegular:
            return UILayout.regularLayoutScale
        case .padLandscape:
            guard size.width > 0, size.height > 0 else {
                return UILayout.regularLayoutScale
            }
            let fitWidth = GameplayTuning.mapWidth / size.width
            let fitHeight = GameplayTuning.mapHeight / size.height
            let fitScale = min(fitWidth, fitHeight)
            return max(
                UILayout.ipadCameraScaleFloor,
                min(UILayout.ipadCameraScaleCeiling, fitScale)
            )
        }
    }
}
