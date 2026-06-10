//
//  UILayout+R6.swift
//  GanhoMusic Shared
//
//  R6 메타 시스템 — 레이아웃 토큰·카피 문자열 (SPEC §F3·F5·F6·F7, 매직 넘버 0 원칙).
//  R4/R5 nested enum 전례 답습 — R6 화면 고유 수치·카피만 여기에 둔다.
//

import UIKit

extension UILayout {
    /// R6 레이아웃·카피 토큰 네임스페이스. case 없는 enum — 인스턴스화 차단.
    enum R6 {
        // MARK: 캐릭터 언락 잠금 문구 (§F3 — "★{요구} 필요 (현재 ★{보유})")
        static let unlockStarPrefix: String = "★"
        static let unlockStarRequiredSuffix: String = " 필요"
        static let unlockStarCurrentPrefix: String = " (현재 ★"
        static let unlockStarCurrentSuffix: String = ")"

        // MARK: StartScene 일일 도전 칩 (§F7 — 좌상단, 진입 시 1회 계산)
        /// 칩 중심의 상단 inset — 로고 라인(top 64 ± 폰트 26) 아래 12pt 클리어런스 (겹침 0).
        static let startDailyChipTopInset: CGFloat = 114
        /// 칩 카피 — "오늘의 도전 · {이름}" / 남은 시간 "~{h}시간" / 클리어 "✓" / armed "▶".
        static let dailyChipTitlePrefix: String = "오늘의 도전 · "
        static let dailyChipRemainJoiner: String = " · ~"
        static let dailyChipRemainSuffix: String = "시간"
        static let dailyChipClearedPrefix: String = "✓ "
        static let dailyChipArmedPrefix: String = "▶ "

        // MARK: 인게임 HUD 도전 표식 (§F7 — 작은 칩 1요소, 노드 +1)
        /// 화면 상단 중앙에서 칩 중심까지의 top inset — HUD 슬롯 행(~56pt) 아래 (겹침 0 실측 보정).
        static let ingameDailyChipTopInset: CGFloat = 72
        /// 인게임 도전 칩 zPosition — HUD 라벨(100) 아래, 월드 위.
        static let ingameDailyChipZPosition: CGFloat = 90
        /// 소등 비네트 zPosition — tension 비네트(110)와 분리·동시 존재 허용 (아래층).
        static let lightsOutVignetteZPosition: CGFloat = 105

        // MARK: ResultScene 정적 칩 2종 (§F6 — 시퀀스 완료 후, 기존 요소·버튼 행과 겹침 0)
        /// 일일 도전 최초 클리어 칩 카피 (02 §7-4 전용 배지).
        static let resultDailyClearChipText: String = "오늘의 도전 클리어! ★×2"
        /// 신규 업적 칩 카피 — "업적 +{n}" (n ≥ 1일 때만 생성).
        static let resultAchievementChipPrefix: String = "업적 +"
        /// 정적 칩 x 오프셋 — 점수 좌측 (recordChip +168의 좌우 대칭측, 콘텐츠 좌표).
        static let resultMetaOutcomeChipOffsetX: CGFloat = -236
        /// 정적 칩 y — 일일 칩 = 점수 행(+40) / 업적 칩 = 별 행(-16) 좌측.
        static let resultDailyClearChipOffsetY: CGFloat = 40
        static let resultAchievementChipOffsetY: CGFloat = -16

        // MARK: Scoreboard 탭 + 총 별 칩 (§F5)
        /// 탭 버튼 2종 텍스트.
        static let scoreboardRecordsTabText: String = "기록"
        static let scoreboardAchievementsTabText: String = "업적"
        /// 탭 버튼 크기·간격 — top bar 행 중앙 (뒤로 버튼·stat 칩과 비겹침).
        static let scoreboardTabButtonSize = CGSize(width: 88, height: 36)
        static let scoreboardTabButtonGap: CGFloat = 12
        /// 총 별 칩 카피 — "★ {n}/45".
        static let scoreboardTotalStarsPrefix: String = "★ "
        static let scoreboardTotalStarsJoiner: String = "/"
        /// 총 별 칩 — stat 칩 행에서 왼쪽 끝 추가 배치 간격.
        static let scoreboardTotalStarsChipGap: CGFloat = 16

        // MARK: Scoreboard 업적 탭 (§F5 — 16셀 2열×8행, 노드 ≤250)
        /// 업적 패널 크기 (기록 패널과 동일 폭 — 화면 예산 동일).
        static let achievementPanelSize = CGSize(width: 656, height: 336)
        /// 패널 상단에서 첫 행 중심까지 inset / 행 높이 / 2열 컬럼 폭.
        static let achievementGridTopInset: CGFloat = 52
        static let achievementRowHeight: CGFloat = 34
        static let achievementColumnWidth: CGFloat = 312
        /// 셀 내부 — 별 아이콘 x(셀 좌측 기준) / 이름 x / 보조(달성일·조건) 우측 정렬 x.
        static let achievementIconInsetX: CGFloat = 16
        static let achievementNameInsetX: CGFloat = 36
        static let achievementSubInsetX: CGFloat = 296
        /// 달성일 표기 포맷 (DateFormatter — 빌드 시 1회 생성).
        static let achievementDateFormat: String = "yy.MM.dd"
    }
}
