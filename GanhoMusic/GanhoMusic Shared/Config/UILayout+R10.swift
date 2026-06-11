//
//  UILayout+R10.swift
//  GanhoMusic Shared
//
//  R10 D — 프로필 다이얼로그 리디자인: [계정 관리] 진입 행 + accountManagement 서브 모드
//  레이아웃·카피 토큰 (매직 넘버 0 원칙). R4~R9 nested enum 전례 답습.
//

import UIKit

extension UILayout {
    /// R10 레이아웃·카피 토큰 네임스페이스. case 없는 enum — 인스턴스화 차단.
    enum R10 {
        // MARK: D-2 detail 3행 — [계정 관리] 진입 카피 (⚠️ 행 명칭 사용자 검수 권장 포인트)
        static let profileAccountEntryText: String = "계정 관리"

        // MARK: D-3 accountManagement 서브 모드 (640×372 패널 좌표)
        /// 헤더 타이틀 — 모드 전환 시 titleLabel 텍스트만 교체 (공유 헤더 구조 유지).
        static let accountManagementTitleText: String = "계정 관리"
        /// 신중 안내 1줄 (caption · maxWidth 360 내 단일 행).
        static let accountManagementBodyText: String = "로그아웃과 계정 삭제는 신중히 진행해 주세요."
        /// 액션 행([로그아웃/Apple 연동]+[계정 삭제]) 중심 y. 44pt 터치 띠 [-82, -38].
        static let accountManagementActionRowY: CGFloat = -60
        /// [뒤로] 행 중심 y. 터치 띠 [-152, -108] — 액션 행과 26pt 분리·패널(-186) 수납.
        static let accountManagementBackRowY: CGFloat = -130
        /// [뒤로] 카피 (.backToProfileDetail — detail 복귀).
        static let profileBackButtonText: String = "뒤로"
    }
}
