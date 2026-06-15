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

    /// 종횡비 인식 메뉴 스케일 (Guideline 4 대응 — A안).
    /// iPhone 경로(phoneCompact/phoneRegular)는 종횡비를 보지 않고 기존 `menuScale`을 그대로 반환 —
    /// 무인자 `menuScale`과 byte-equal (무회귀). iPad(padLandscape)에서만 안전영역 세로에 비례해
    /// 스케일을 키워 콘텐츠가 화면 세로를 균형 있게 채우도록 한다 (floor=현 1.08, ceiling 상한 클램프).
    /// - size: scene.size (가로 전용 — width/height = aspect).
    /// - safeInsets: 콘텐츠 밴드 세로 산출용 안전영역(상/하). 미주입 시 .zero(폴백).
    func menuScale(for size: CGSize, safeInsets: UIEdgeInsets) -> CGFloat {
        switch self {
        case .phoneCompact, .phoneRegular:
            return menuScale
        case .padLandscape:
            guard size.height > 0 else { return UILayout.ipadMenuScaleFloor }
            let safeHeight = max(0, size.height - safeInsets.top - safeInsets.bottom)
            let raw = UILayout.ipadMenuScaleFloor
                * (safeHeight / UILayout.referenceContentHeight)
            return max(
                UILayout.ipadMenuScaleFloor,
                min(UILayout.ipadMenuScaleCeiling, raw)
            )
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

    /// 콘텐츠 밴드 세로 최대 높이. iPhone은 무제한(.greatestFiniteMagnitude = 클램프 무효 = 기존 동작),
    /// iPad만 유한값으로 남는 세로를 상하 균등 분배해 콘텐츠 밴드를 화면 세로 중앙에 둔다 (S3).
    var menuMaxContentHeight: CGFloat {
        switch self {
        case .phoneCompact, .phoneRegular:
            return .greatestFiniteMagnitude
        case .padLandscape:
            return UILayout.ipadMenuMaxContentHeight
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
