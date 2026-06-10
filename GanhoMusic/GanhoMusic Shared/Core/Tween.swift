//
//  Tween.swift
//  GanhoMusic Shared
//
//  R2 · SKAction.timingFunction 래퍼 — 트윈 곡선 4종 (02_GAME_FEEL §5).
//  R2 이후 신규/수정 연출은 linear 금지(페이드 제외) — 본 파일이 곡선의 단일 진실 원천.
//

import SpriteKit

/// 트윈 곡선 네임스페이스. case 없는 enum — 인스턴스화 차단.
/// 사용: `Tween.curved(SKAction.scale(to: 1.2, duration: 0.18), .easeOutBack)`.
enum Tween {

    /// 지원 곡선 4종 (02 §5 명세 그대로).
    enum Curve {
        case easeOutBack
        case easeOutCubic
        case easeInOutQuad
        case easeOutElastic
    }

    // MARK: - 곡선 수학 상수 (easing 함수 정의의 일부 — 표준 계수)
    /// easeOutBack 오버슈트 계수 c1 (표준 1.70158 — 약 10% 오버슈트).
    private static let backOvershoot: Float = 1.70158
    /// easeOutElastic 진동 주기 계수 c4 = 2π/3.
    private static let elasticPeriod: Float = (2 * Float.pi) / 3
    /// easeOutElastic 지수 감쇠 밑/지수 (표준 2^(-10t)).
    private static let elasticDecayBase: Float = 2
    private static let elasticDecayExponent: Float = -10
    /// elastic 위상 오프셋 (표준 0.75).
    private static let elasticPhaseOffset: Float = 0.75

    // MARK: - Timing Functions
    /// 곡선에 해당하는 SKActionTimingFunction 반환. t ∈ [0,1] → [0,1].
    static func function(for curve: Curve) -> SKActionTimingFunction {
        switch curve {
        case .easeOutBack:
            return { t in
                let c1 = backOvershoot
                let c3 = c1 + 1
                let shifted = t - 1
                return 1 + c3 * shifted * shifted * shifted + c1 * shifted * shifted
            }
        case .easeOutCubic:
            return { t in
                let inverted = 1 - t
                return 1 - inverted * inverted * inverted
            }
        case .easeInOutQuad:
            return { t in
                if t < 0.5 { return 2 * t * t }
                let shifted = -2 * t + 2
                return 1 - shifted * shifted / 2
            }
        case .easeOutElastic:
            return { t in
                if t <= 0 { return 0 }
                if t >= 1 { return 1 }
                let decay = pow(elasticDecayBase, elasticDecayExponent * t)
                return decay * sin((t * 10 - elasticPhaseOffset) * elasticPeriod) + 1
            }
        }
    }

    // MARK: - Apply
    /// 기존 SKAction에 곡선을 입혀 반환. duration 0 액션은 timingFunction 무의미 — 그대로 통과.
    static func curved(_ action: SKAction, _ curve: Curve) -> SKAction {
        action.timingFunction = function(for: curve)
        return action
    }
}
