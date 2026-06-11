//
//  UILayout+R9.swift
//  GanhoMusic Shared
//
//  R9 — 계정·시스템 기본기: U1 인증 실패 전용 카피·U3 프로필 버튼 3행·설정 다이얼로그·
//  온보딩 힌트·정책/크레딧 토큰 (매직 넘버 0 원칙). R4~R8 nested enum 전례 답습.
//

import UIKit

extension UILayout {
    /// R9 레이아웃·카피 토큰 네임스페이스. case 없는 enum — 인스턴스화 차단.
    enum R9 {
        // MARK: U1 인증 실패 전용 카피 (appleFailureStatusText 2곳 공용 — 사용자 검수 포인트)
        /// missingOrInvalidNonce(17094) — 서버가 이미 소비한 credential. 재시도로 해결됨.
        static let authAppleCredentialConsumedText: String = "인증이 만료됐어요. 한 번 더 시도해 주세요"
        /// networkError(17020) — 네트워크 단절 전용.
        static let authNetworkUnavailableText: String = "네트워크 연결을 확인해 주세요"

        // MARK: U2·U3 프로필 다이얼로그 버튼 3행 (640×372 패널 좌표)
        /// 3행([계정 관리] 진입 — R10 D-2에서 로그아웃/탈퇴 격리) 중심 y.
        /// R10 — -170 → -164: 44pt 터치 띠 [-186, -142]가 패널 하단(-186)과 정확히 일치 —
        /// R9 P2 "하단 6pt 돌출" 해소. 2행은 -126으로 동반 상향(UILayout+R5) — 시각 겹침 0.
        static let profileThirdButtonRowY: CGFloat = -164
        /// 3행 compact 버튼 시각 크기 (높이 26 ≤ 32 — 위계 강등). 터치는 44pt 자동 확장.
        static let profileCompactButtonSize = CGSize(width: 132, height: 26)

        // MARK: #1 설정 다이얼로그 (SettingsDialogNode — 440×372 패널 좌표)
        /// R12 [A④] — BGM 토글 +1행: 높이 320→372 (+52 = 기존 행간 유지). BGM 행 y는
        /// UILayout.R12.settingsBGMRowY (신규 수치는 R12 네임스페이스 — G2 게이트).
        static let settingsPanelSize = CGSize(width: 440, height: 372)
        static let settingsTitleText: String = "설정"
        static let settingsCreditsTitleText: String = "크레딧"
        /// 모드별 자체 헤더 y — PixelPanelNode 헤더 식(높이/2 − s16 − s8)과 동일 (372/2 − 24).
        static let settingsHeaderY: CGFloat = 162
        /// 토글/링크/닫기 행 중심 y — 행간 52pt ≥ 44pt 터치라 행 간 터치 겹침 0.
        /// R12 [A④] — BGM 행(+90) 삽입에 따른 일괄 −26 하향 (행간·터치 분리 불변).
        static let settingsSFXRowY: CGFloat = 38
        static let settingsHapticsRowY: CGFloat = -14
        static let settingsLinkRowY: CGFloat = -66
        static let settingsCloseRowY: CGFloat = -118
        static let settingsToggleButtonSize = CGSize(width: 240, height: 36)
        static let settingsPrivacyButtonSize = CGSize(width: 220, height: 36)
        static let settingsCreditsButtonSize = CGSize(width: 132, height: 36)
        static let settingsCloseButtonSize = CGSize(width: 112, height: 36)
        /// 토글 상태 카피 — ON=secondary / OFF=ghost 재생성 (ScoreboardScene 탭 전례 동형).
        static let settingsSFXOnText: String = "효과음 켬"
        static let settingsSFXOffText: String = "효과음 끔"
        static let settingsHapticsOnText: String = "진동 켬"
        static let settingsHapticsOffText: String = "진동 끔"
        static let settingsPrivacyButtonText: String = "개인정보처리방침"
        static let settingsCreditsButtonText: String = "크레딧"
        static let settingsBackButtonText: String = "뒤로"

        // MARK: #4 크레딧 본문 (인앱 텍스트 — 사용자 검수 포인트: 자전적 톤 보존은 사용자 몫)
        static let creditsBodyText: String = """
        글꼴 — Galmuri (Quiple) · Gowun Dodum
        Jua (우아한형제들) · Noto Sans KR (Google)
        전부 SIL Open Font License 1.1

        서비스 — Firebase (Google)
        기획·개발 — 성현규
        """
        static let creditsBodyMaxWidth: CGFloat = 392
        /// 본문 상단 y (verticalAlignmentMode .top 기준) — 헤더 아래 · [뒤로] 행 위.
        static let creditsBodyTopY: CGFloat = 96

        // MARK: #1 진입점 ① — Start 우상단 설정 버튼 (프로필 칩 아래 적층)
        /// ghost compact 시각 크기. 터치는 44pt 자동 확장 (PixelButtonNode).
        static let startSettingsButtonSize = CGSize(width: 76, height: 28)
        /// 버튼 중심의 상단(safe top) inset — 프로필 칩(중심 -36·하단 -48) 아래 + 칩 히트
        /// 패딩(-58)과 시각 비겹침 (버튼 시각 상단 -62).
        static let startSettingsButtonTopInset: CGFloat = 76

        // MARK: #1 진입점 ② — 일시정지 메뉴 [설정] (pausePanelSize 320×200 불변)
        /// ghost 와이드 — 제목(헤더 +76) 아래 ~ 버튼 행(-48, 터치 상단 -26) 위 빈 공간.
        /// 터치 스팬 [-14, +30] — 헤더·기존 행과 겹침 0.
        static let pauseSettingsButtonSize = CGSize(width: 272, height: 36)
        static let pauseSettingsRowY: CGFloat = 8

        // MARK: #4 정책 링크
        /// ⚠️ 정책 호스팅 URL 미확정 — 빈 문자열이면 SettingsDialogNode가 정책 행 자체를
        /// 생성하지 않는다 (graceful 조건부 미생성 — 좀비 아님).
        /// App Store 심사 전 실제 URL 기입 필수 — 출시 체크리스트 항목.
        static let privacyPolicyURLString: String = ""
        /// .ganhoExternalLinkRequested userInfo 키 (값: URL).
        static let externalLinkURLUserInfoKey: String = "ganhoExternalLinkURL"

        // MARK: #3 첫 판 조작 온보딩 힌트 (ControlsHintNode)
        static let controlsHintMoveCaptionText: String = "드래그로 이동"
        static let controlsHintSkillCaptionText: String = "탭하면 스킬 발동"
        /// 캡션 중심 y — D-Pad 링/스킬 버튼 상단 엣지에서 위로 띄우는 간격.
        static let controlsHintCaptionGap: CGFloat = 26
    }
}
