//
//  FeelTuning+R9.swift
//  GanhoMusic Shared
//
//  R9 — 첫 판 조작 온보딩 힌트 타이밍 (ControlsHintNode). 전부 SKAction 구동 —
//  Timer/asyncAfter 0. R5/R7/R8 네임스페이스 컨벤션 답습.
//

import Foundation
import CoreGraphics

extension FeelTuning {
    /// R9 연출 튜닝 토큰 네임스페이스. case 없는 enum — 인스턴스화 차단.
    enum R9 {
        // MARK: 온보딩 힌트 수명 (총 0.3+2.4+0.3 = 3.0s — easy 첫 발사 3.5s 이전 안전 창)
        /// 등장/퇴장 페이드 길이 (초).
        static let controlsHintFadeDuration: TimeInterval = 0.3
        /// 완전 노출 유지 길이 (초).
        static let controlsHintHoldDuration: TimeInterval = 2.4

        // MARK: 펄스 (D-Pad 화살표 스케일/알파 + 스킬 글로우 알파 — repeatForever 왕복)
        /// 펄스 반주기 (초) — 0.9s 주기 호흡 (R8 카드 부유와 동일 감각).
        static let controlsHintPulseHalfPeriod: TimeInterval = 0.45
        /// 화살표 펄스 최대 스케일.
        static let controlsHintPulseScale: CGFloat = 1.2
        /// 펄스 저점 알파.
        static let controlsHintPulseLowAlpha: CGFloat = 0.4
    }
}
