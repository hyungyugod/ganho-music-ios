//
//  BaseMenuScene.swift
//  GanhoMusic Shared
//
//  메뉴 씬 공용 베이스. 4개 씬(Start/CharacterSelect/DifficultySelect/SkillExplanation)이
//  공유하던 그라데이션 배경 setup/rebuild 보일러플레이트를 한 곳에 모음.
//  ResultScene/ScoreboardScene은 다른 변수명·인라인 구조라 대상 외.
//

import SpriteKit

/// 4개 메뉴 씬의 공용 베이스. 따뜻한 3-stop 그라데이션 배경만 제공.
/// 자식 씬은 `didMove`에서 `setupWarmGradientBackground()`, `didChangeSize`에서
/// `rebuildWarmGradientBackground()`를 호출하면 끝. 결과 픽셀은 기존 4개 씬 동일.
class BaseMenuScene: SKScene {

    /// 그라데이션 노드 참조 — didChangeSize 재생성에서 removeFromParent용.
    private var gradientBackground: GradientBackgroundNode?

    /// 3-stop warm gradient(피치 → 코랄 → 라벤더) 배경 부착.
    /// didMove에서 1회 호출. 자식 씬이 직접 색을 바꾸고 싶으면 이 메소드를 호출하지 않고 직접 노드 생성.
    func setupWarmGradientBackground() {
        let node = GradientBackgroundNode.threeStop(
            size: size,
            topColor: .ganhoBgWarmTop,
            midColor: .ganhoBgWarmMid,
            bottomColor: .ganhoBgWarmBottom
        )
        node.position = CGPoint(x: frame.midX, y: frame.midY)
        gradientBackground = node
        addChild(node)
    }

    /// 사이즈 변경 시 그라데이션 재생성. 기존 노드 removeFromParent 후 새로 부착.
    func rebuildWarmGradientBackground() {
        gradientBackground?.removeFromParent()
        gradientBackground = nil
        setupWarmGradientBackground()
    }

    // MARK: - Layout

    func menuSafeInsets() -> UIEdgeInsets {
        return SceneSafeArea.insets(for: self)
    }

    func menuCompactScale() -> CGFloat {
        if size.height < GameConfig.compactLandscapeMinHeight {
            return GameConfig.compactLayoutScale
        }
        if size.width < GameConfig.compactNarrowWidth {
            return GameConfig.compactNarrowLayoutScale
        }
        return 1.0
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
