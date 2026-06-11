//
//  UILayout+R12.swift
//  GanhoMusic Shared
//
//  R12 — 게임필 2차 + 오디오·아이덴티티: 목표 달성 배너 카피(#7)·결과창 통계 칩 2종(#9)·
//  브리핑 near-miss 팁(#11)·BGM 설정 토글([A]) 토큰 (매직 넘버 0 원칙).
//  R4~R10 nested enum 전례 답습.
//

import UIKit

extension UILayout {
    /// R12 레이아웃·카피 토큰 네임스페이스. case 없는 enum — 인스턴스화 차단.
    enum R12 {
        // MARK: #7 목표 달성 마일스톤 배너 (게이트 C)
        /// 배너 카피 — 호출부 리터럴 노출 금지.
        static let goalAchievedText: String = "목표 달성!"

        // MARK: #9 결과창 통계 칩 2종 — "끊김 n회" / "변기 n개" (R5 칩 prefix 컨벤션)
        static let resultBreaksChipPrefix: String = "끊김 "
        static let resultBreaksChipSuffix: String = "회"
        static let resultToiletChipPrefix: String = "변기 "
        static let resultToiletChipSuffix: String = "개"

        // MARK: #11 브리핑 near-miss 팁 (칩 행 아래 caption 1줄)
        /// near-miss 실효과 = 콤보 타이머 연장 → "콤보가 이어집니다" 표현 ("점수" 표현 금지).
        static let briefingTipText: String = "팁: F를 아슬하게 스치면 콤보가 이어집니다!"
        /// 팁 중심 y (패널 좌표). 칩 행(-100) 아래 — 확장된 패널(높이 288, 하단 -144) 안 수납.
        static let briefingTipOffsetY: CGFloat = -124

        // MARK: [A④] BGM 설정 토글 (SettingsDialogNode — R9 토글 행 동형)
        /// BGM 토글 행 중심 y — 확장 패널(440×372) 최상단 행. 행간 52pt 유지.
        static let settingsBGMRowY: CGFloat = 90
        /// 토글 상태 카피 — ON=secondary / OFF=ghost 재생성 (R9 효과음/진동 동형).
        static let settingsBGMOnText: String = "배경음악 켬"
        static let settingsBGMOffText: String = "배경음악 끔"
    }
}
