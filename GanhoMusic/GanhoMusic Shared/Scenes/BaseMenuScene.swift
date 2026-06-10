//
//  BaseMenuScene.swift
//  GanhoMusic Shared
//
//  메뉴 씬 공용 베이스. 6개 씬(Start/CharacterSelect/SkillBriefing/DifficultySelect/
//  Result/Scoreboard)이 공유하는 v3 야간 병동 배경(NightShiftBackdropNode) +
//  staggered 등장 모션 + safe area helper. (Result/Scoreboard는 R5에서 상속 합류.)
//  R4 — v2 단색(ganhoPaper) 배경 폐기 → ink900 + 스타필드 + 심전도 (03_UI §4).
//

import SpriteKit
import UIKit

/// 4개 메뉴 씬의 공용 베이스. v3 공통 배경과 safe area layout helper를 제공.
class BaseMenuScene: SKScene {

    /// 공통 배경 — 씬 중앙 1개, didChangeSize에서 재생성 (§E-1).
    private var nightShiftBackdrop: NightShiftBackdropNode?
    /// staggered 등장 대상 추적 — didChangeSize 재배치 전 정리용.
    private var appearingNodes: [SKNode] = []
    /// 등장 액션 키 — withKey 멱등.
    private static let appearActionKey = "r4StaggeredAppear"

    // MARK: - Backdrop (§E-1)
    /// v3 공통 배경 설치. backgroundColor는 1프레임 fallback (백드롭 생성 전 다크 플래시 회피).
    func setupNightShiftBackdrop() {
        backgroundColor = Palette.ink900
        nightShiftBackdrop?.removeFromParent()
        let backdrop = NightShiftBackdropNode(size: size)
        backdrop.position = CGPoint(x: frame.midX, y: frame.midY)
        nightShiftBackdrop = backdrop
        addChild(backdrop)
    }

    /// 사이즈 변경 시 재생성 — 백드롭 내부 노드들이 size 의존 (스타필드 분포·심전도 폭).
    func rebuildNightShiftBackdrop() {
        setupNightShiftBackdrop()
    }

    // MARK: - Staggered Appear (§E-3 — Motion.appear 0.22s easeOutCubic + 60ms stagger)
    /// 주요 요소를 아래 12pt에서 떠오르며 페이드 인. 정적 출현 금지 (03_UI §1 원칙 4).
    /// 호출 시점: didMove에서 레이아웃 확정 *후* 1회.
    func runStaggeredAppear(_ nodes: [SKNode]) {
        cancelStaggeredAppear()
        appearingNodes = nodes
        for (index, node) in nodes.enumerated() {
            node.alpha = 0
            node.position.y -= UILayout.R4.appearRise
            let rise = Tween.curved(
                SKAction.moveBy(x: 0, y: UILayout.R4.appearRise,
                                duration: FeelTuning.Motion.appear),
                .easeOutCubic
            )
            let fade = SKAction.fadeIn(withDuration: FeelTuning.Motion.appear)
            node.run(
                SKAction.sequence([
                    SKAction.wait(forDuration: FeelTuning.Motion.appearStagger
                                  * TimeInterval(index)),
                    SKAction.group([rise, fade])
                ]),
                withKey: Self.appearActionKey
            )
        }
    }

    /// 등장 중 재배치(didChangeSize) 충돌 방지 — 액션 제거 + alpha 복원.
    /// 위치는 직후 호출되는 각 씬의 layout이 절대좌표로 재확정한다.
    func cancelStaggeredAppear() {
        for node in appearingNodes where node.action(forKey: Self.appearActionKey) != nil {
            node.removeAction(forKey: Self.appearActionKey)
            node.alpha = 1
        }
        appearingNodes = []
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
