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

    /// 기존 그라데이션 노드가 남아 있을 경우 단색 배경 전환 때 제거하기 위한 참조.
    private var gradientBackground: GradientBackgroundNode?

    /// 톤 다운 sprint 기본 배경. 그라데이션 노드를 제거하고 단색 배경만 유지한다.
    func setupSolidMenuBackground() {
        gradientBackground?.removeFromParent()
        gradientBackground = nil
        backgroundColor = GameConfig.menuSolidBackgroundColor
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
        if size.height < GameConfig.compactLandscapeMinHeight {
            return GameConfig.compactLayoutScale
        }
        if size.width < GameConfig.compactNarrowWidth {
            return GameConfig.compactNarrowLayoutScale
        }
        return profile.menuScale
    }

    func topBarY(extraInset: CGFloat = 0) -> CGFloat {
        let safe = menuSafeInsets()
        return frame.maxY - safe.top - GameConfig.menuTopSafePadding - extraInset
    }

    func bottomCTAAnchorY(buttonHalfHeight: CGFloat) -> CGFloat {
        let safe = menuSafeInsets()
        return frame.minY
            + safe.bottom
            + GameConfig.menuBottomSafePadding
            + buttonHalfHeight
    }
}
