//
//  UILayout+R7.swift
//  GanhoMusic Shared
//
//  R7 — "아슬!" 팝업 카피·HUD 콤보 게이지 좌표·메타 보상 토스트 카피 (매직 넘버 0 원칙).
//  R4/R5/R6 nested enum 전례 답습 — R7 화면 고유 수치·카피만 여기에 둔다.
//

import UIKit

extension UILayout {
    /// R7 레이아웃·카피 토큰 네임스페이스. case 없는 enum — 인스턴스화 차단.
    enum R7 {
        // MARK: near-miss "아슬!" 팝업 (F2)
        /// 팝업 텍스트 — 호출부 리터럴 노출 금지.
        static let nearMissPopupText: String = "아슬!"
        /// 플레이어 중심 → 팝업 시작점 추가 y 오프셋 (pt). ToastLabelNode 내장 +16과 합산 —
        /// 플레이어 픽셀 본체(높이 40, 절반 20) 상단 위에서 시작해 캐릭터와 겹침 0.
        static let nearMissPopupOffsetY: CGFloat = 20

        // MARK: HUD 콤보 게이지 (F3 — 02 §8 "60×4px")
        /// 게이지 크기. 콤보 칩(78×44) 하단 내측 — HUDSlotNode timeBar 패턴 동형.
        static let hudComboGaugeSize = CGSize(width: 60, height: 4)
        /// 칩 하단 가장자리 → 게이지 간격 (pt). hudTimeBarTopGap(3)과 동일 톤.
        static let hudComboGaugeBottomGap: CGFloat = 3

        // MARK: 결과창 메타 보상 토스트/배너 (F5/F6)
        /// 캐릭터 해금 배너 카피 접미사 — "{displayName} 해금!".
        static let resultUnlockBannerSuffix: String = " 해금!"
        /// 업적 토스트 카피 접두사 — "업적 달성! {displayName}".
        static let resultAchievementToastPrefix: String = "업적 달성! "
        /// 화면 상단 가장자리 → 토스트 중심 inset (pt). 좌상단 코너 앵커 — 중앙 정렬은
        /// 컨텍스트 칩·verdict 행과 겹침 실측(시각 증빙 1차 캡처) → 좌측 정렬로 회피.
        static let resultMetaToastTopInset: CGFloat = 44
    }
}
