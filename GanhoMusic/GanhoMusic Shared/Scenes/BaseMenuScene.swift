//
//  BaseMenuScene.swift
//  GanhoMusic Shared
//
//  메뉴 씬 공용 베이스. 4개 씬(Start/CharacterSelect/DifficultySelect/SkillExplanation)이
//  공유하는 단색 배경 setup/rebuild 보일러플레이트를 한 곳에 모음.
//  ResultScene/ScoreboardScene은 다른 변수명·인라인 구조라 대상 외.
//

import SpriteKit
import UIKit

/// 4개 메뉴 씬의 공용 베이스. 메뉴 단색 배경과 safe area layout helper를 제공.
class BaseMenuScene: SKScene {

    /// 톤 다운 sprint 기본 배경. 단색 배경만 유지한다.
    func setupSolidMenuBackground() {
        backgroundColor = Palette.menuSolidBackgroundColor
    }

    func rebuildSolidMenuBackground() {
        setupSolidMenuBackground()
    }

    // MARK: - Layout

    func menuSafeInsets() -> UIEdgeInsets {
        let profile = DeviceLayoutProfile.resolve(for: self)
        return SceneSafeArea.contentInsets(
            for: self,
            maxContentWidth: profile.menuMaxContentWidth
        )
    }

    func menuCompactScale() -> CGFloat {
        let profile = DeviceLayoutProfile.resolve(for: self)
        if profile == .padLandscape {
            return profile.menuScale
        }
        if size.height < UILayout.compactLandscapeMinHeight {
            return UILayout.compactLayoutScale
        }
        if size.width < UILayout.compactNarrowWidth {
            return UILayout.compactNarrowLayoutScale
        }
        return profile.menuScale
    }

    func topBarY(extraInset: CGFloat = 0) -> CGFloat {
        let safe = menuSafeInsets()
        return frame.maxY - safe.top - UILayout.menuTopSafePadding - extraInset
    }

    func bottomCTAAnchorY(buttonHalfHeight: CGFloat) -> CGFloat {
        let safe = menuSafeInsets()
        return frame.minY
            + safe.bottom
            + UILayout.menuBottomSafePadding
            + buttonHalfHeight
    }
}
