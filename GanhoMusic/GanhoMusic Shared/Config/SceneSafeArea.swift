//
//  SceneSafeArea.swift
//  GanhoMusic Shared
//
//  Sprint 7+ · 디바이스 안전영역(SafeArea) 회피 공용 헬퍼
//
//  iPhone Landscape에서 노치/Dynamic Island가 화면 좌우(또는 한쪽)를 침범한다.
//  GameViewController는 SKView frame을 절대 만지지 않는다(2026-05 무한재귀 사고).
//  대신 각 SKScene이 노드 배치 시점에 view.safeAreaInsets를 읽어 회피한다.
//
//  view가 아직 부착되지 않은 경우(.zero) — 강제 언래핑 0건. guard let 또는 ?? .zero로 폴백.
//

import SpriteKit
import UIKit

/// SKScene에서 view.safeAreaInsets를 안전하게 읽는 헬퍼.
/// Landscape 전용 게임 — left/right 노치 회피가 가장 중요.
/// GameViewController는 SKView frame을 절대 만지지 않는다(2026-05 무한재귀 사고 기록).
/// 노드 배치 측에서 이 헬퍼를 호출해 좌표를 보정한다.
enum SceneSafeArea {
    /// 현재 SKView의 safe area insets. view 미부착 시 .zero(안전 폴백).
    /// 호출 시점: 각 씬의 `layoutXxx()` 내부 — `didChangeSize`/`didMove`에서 재호출되며 자동 회전 흡수.
    static func insets(for scene: SKScene) -> UIEdgeInsets {
        return scene.view?.safeAreaInsets ?? .zero
    }

    /// 실제 safe area에 가상 콘텐츠 폭 제한을 더한다.
    /// iPad 넓은 화면에서 메뉴/결과/기록 화면 요소가 좌우 끝으로 흩어지지 않도록 한다.
    static func contentInsets(for scene: SKScene, maxContentWidth: CGFloat) -> UIEdgeInsets {
        let base = insets(for: scene)
        guard maxContentWidth > 0 else { return base }

        let safeContentWidth = max(0, scene.size.width - base.left - base.right)
        let extraHorizontal = max(0, (safeContentWidth - maxContentWidth) / 2)
        return UIEdgeInsets(
            top: base.top,
            left: base.left + extraHorizontal,
            bottom: base.bottom,
            right: base.right + extraHorizontal
        )
    }
}
