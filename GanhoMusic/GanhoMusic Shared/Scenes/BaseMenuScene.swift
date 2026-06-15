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
        // iPhone: menuMaxContentHeight = .greatestFiniteMagnitude → extraV=0 → 기존 동작 byte-equal.
        // iPad: 유한값 → 남는 세로 상하 균등 분배(콘텐츠 밴드 세로 중앙 — Guideline 4 A안 S3).
        return SceneSafeArea.contentInsets(
            for: self,
            maxContentWidth: profile.menuMaxContentWidth,
            maxContentHeight: profile.menuMaxContentHeight
        )
    }

    func menuCompactScale() -> CGFloat {
        let profile = DeviceLayoutProfile.resolve(for: self)
        if profile == .padLandscape {
            // iPad 종횡비 인식 스케일 — 안전영역 세로에 비례(floor=현 1.08, ceiling 클램프).
            // safeInsets는 노치 회피값(.greatestFiniteMagnitude 세로 클램프는 미적용 — 콘텐츠
            // 가용 세로의 원본 기준으로 스케일을 정해야 밴드 클램프와 이중 축소가 안 일어남).
            let base = SceneSafeArea.insets(for: self)
            return profile.menuScale(for: size, safeInsets: base)
        }
        if size.height < UILayout.compactLandscapeMinHeight {
            return UILayout.compactLayoutScale
        }
        if size.width < UILayout.compactNarrowWidth {
            return UILayout.compactNarrowLayoutScale
        }
        return profile.menuScale
    }

    /// 2컬럼 씬(CharacterSelect/SkillBriefing)의 컬럼 중심 x를 콘텐츠 폭 기준으로 재유도한다 (S4).
    /// iPhone 경로: `ratio`를 `frame` 전체 폭에 그대로 적용 — 기존 `frame.minX + frame.width*ratio`와
    /// **항등**(byte-equal 무회귀). iPad 경로: 좌우 컬럼이 콘텐츠 폭(safe-center) 중앙 기준으로
    /// 대칭이 되도록, 화면폭 비율(ratio−0.5)를 콘텐츠 가용 폭에 매핑해 safe-center에서 재산출.
    /// - ratio: 기존 화면폭 비율 상수(예: selectPreviewCenterXRatio 0.21). 0.5 = 정중앙.
    func contentColumnX(ratio: CGFloat) -> CGFloat {
        let profile = DeviceLayoutProfile.resolve(for: self)
        if profile != .padLandscape {
            // 항등 경로 — 기존 산식 그대로 (.rounded()는 호출부가 적용, 여기선 raw 값 보존).
            return frame.minX + frame.width * ratio
        }
        let safe = menuSafeInsets()
        let contentWidth = max(0, size.width - safe.left - safe.right)
        let safeCenterX = frame.minX + safe.left + contentWidth / 2
        // (ratio − contentCenterRatio): 화면폭 비율 기준 중앙으로부터의 부호 있는 정규화 오프셋(±0.5).
        // 콘텐츠 가용 폭에 매핑 → 좌/우 컬럼이 콘텐츠 중앙 기준 대칭으로 모인다.
        return safeCenterX + (ratio - UILayout.contentCenterRatio) * contentWidth
    }

    /// 좌·우 2컬럼 중심 x를 동시에 재유도하되, **두 컬럼 중심의 중점이 콘텐츠 폭 정중앙에 오도록**
    /// 보정한다 (S4 핵심 요구). 컬럼 간 간격(gap)은 보존하고 페어 전체를 평행 이동해 중앙화 —
    /// 비대칭 원본 비율(예: SkillBriefing 0.24/0.65 → 중점 0.445)도 콘텐츠 중앙 정렬.
    /// iPhone: 각 컬럼이 `contentColumnX` 항등 경로 → 기존 좌표 byte-equal (보정 0).
    /// - returns: (left, right) 컬럼 중심 x.
    func contentColumnPair(leftRatio: CGFloat, rightRatio: CGFloat) -> (left: CGFloat, right: CGFloat) {
        let rawLeft = contentColumnX(ratio: leftRatio)
        let rawRight = contentColumnX(ratio: rightRatio)
        guard DeviceLayoutProfile.resolve(for: self) == .padLandscape else {
            return (rawLeft, rawRight)   // iPhone — 보정 없이 항등 (byte-equal)
        }
        let safe = menuSafeInsets()
        let contentWidth = max(0, size.width - safe.left - safe.right)
        let safeCenterX = frame.minX + safe.left + contentWidth / 2
        let midpoint = (rawLeft + rawRight) / 2
        let correction = safeCenterX - midpoint   // 페어 중점을 콘텐츠 중앙으로 끌어오는 평행 이동
        return (rawLeft + correction, rawRight + correction)
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
