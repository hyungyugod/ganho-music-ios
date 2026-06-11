//
//  UILayout+R5.swift
//  GanhoMusic Shared
//
//  R5 결과·기록·프로필 재구축 — 레이아웃·카피 토큰 (SPEC 신규, 매직 넘버 0 원칙).
//  공통 형태 메트릭(v3*)·간격(Space)·R4 공용(backButtonSize·ctaButtonSize)은 그대로 소비하고,
//  R5 화면 고유 수치만 여기에 둔다. 4pt 그리드·정수 좌표 스냅 (03_UI §1 원칙 2).
//

import UIKit

extension UILayout {
    /// R5 레이아웃 토큰 네임스페이스. case 없는 enum — 인스턴스화 차단.
    enum R5 {
        // MARK: ResultScene — "보상의 무대" (03_UI §7)
        /// verdict 스탬프 텍스트 — 성공/실패 (§7 카피 그대로).
        static let resultVerdictSuccessText: String = "졸업!"
        static let resultVerdictFailText: String = "유급…"
        /// 콘텐츠 컨테이너 기준 y 오프셋 — verdict / 점수 / 별 행 / 보조 칩 행 / XP 바 / 레벨 캡션.
        /// 세로 예산: iPhone 랜드스케이프 ~402pt에서 위 +160(칩 상단)~아래 -127(레벨 캡션 하단)이
        /// 버튼 행(top ≈ 97pt)과 겹치지 않도록 컨테이너를 +36 올린다 (스크린샷 실측 보정).
        static let resultVerdictOffsetY: CGFloat = 100
        static let resultScoreOffsetY: CGFloat = 40
        static let resultStarRowOffsetY: CGFloat = -16
        static let resultMetaChipRowOffsetY: CGFloat = -60
        static let resultXPBarOffsetY: CGFloat = -96
        static let resultLevelLabelOffsetY: CGFloat = -120
        /// 컨텍스트 칩(난이도·캐릭터) 중심 y — verdict 위.
        static let resultContextChipOffsetY: CGFloat = 148
        /// 콘텐츠 컨테이너 중심의 midY 기준 y 오프셋 — 하단 버튼 행 회피 상향.
        static let resultContentCenterYOffset: CGFloat = 36
        /// 별 라벨 폰트 크기 (Typography.V3.display.fontName 사용 — 크기만 별도).
        static let resultStarFontSize: CGFloat = 34
        /// 별 간 가로 간격.
        static let resultStarSpacing: CGFloat = 52
        /// 신기록/부족 칩 중심 — 점수 우측 (x 오프셋, y는 점수 행과 동일).
        static let resultRecordChipOffsetX: CGFloat = 168
        /// 보조 칩(콤보·수집) 사이 가로 간격.
        static let resultMetaChipGap: CGFloat = 12
        /// XP 바 크기 (PixelProgressBarNode size — 8px 세그먼트 단위로 자동 분할).
        static let resultXPBarSize = CGSize(width: 288, height: 10)
        /// 레벨업 칭호 배지 — 레벨 캡션 우측 슬라이드인 목적지 x 오프셋.
        static let resultLevelUpChipOffsetX: CGFloat = 132
        /// 하단 버튼 텍스트 3종 (§7 — 다시 도전 primary / 캐릭터 변경 secondary / 기록 ghost).
        static let resultRetryButtonText: String = "다시 도전"
        static let resultCharacterButtonText: String = "캐릭터 변경"
        static let resultRecordsButtonText: String = "기록"
        /// 기록 ghost 버튼 시각 크기 (primary=R4.ctaButtonSize / secondary=R4.secondaryCTAButtonSize 재사용).
        static let resultGhostButtonSize = CGSize(width: 104, height: 44)
        /// 하단 버튼 행 — 버튼 사이 가로 간격.
        static let resultButtonGap: CGFloat = 24
        /// 컨텍스트 칩 텍스트 결합자 — "상 난이도 · 김간호".
        static let resultContextChipJoiner: String = " 난이도 · "
        /// 신기록 칩 텍스트.
        static let resultNewRecordChipText: String = "NEW RECORD"
        /// 실패 부족 칩 접미 — "{gap}" + 접미 = "{gap}점 부족".
        static let resultGapChipSuffix: String = "점 부족"
        /// 콤보 칩 접두 — "x{maxCombo}".
        static let resultComboChipPrefix: String = "x"
        /// 수집 칩 접두 — "♪{notesCollected}".
        static let resultNotesChipPrefix: String = "♪"
        /// 레벨 캡션 접두/구분 — "Lv.{n} {칭호}".
        static let resultLevelLabelPrefix: String = "Lv."
        /// 별 채움/윤곽 문자 (gold ★ / textLo ☆ — 윤곽도 시각 정보, 좀비 아님).
        static let starFilledText: String = "★"
        static let starEmptyText: String = "☆"

        // MARK: ScoreboardScene — 픽셀 테이블 (03_UI §8)
        /// 테이블 골격 PixelPanelNode 크기 (헤더 슬롯 포함).
        /// 높이 336 — iPhone 랜드스케이프 ~402pt에서 상단 뒤로 버튼(top bar)과 겹치지 않는 한계
        /// (스크린샷 실측 보정: 392는 화면을 거의 채워 stat 칩이 화면 밖으로 밀렸다).
        static let scoreboardPanelSize = CGSize(width: 656, height: 336)
        /// 패널 중심의 midY 기준 y 오프셋 — top bar 회피 하향.
        static let scoreboardPanelCenterYOffset: CGFloat = -16
        /// 행 헤더(포트레이트+이름) 열 폭 / 데이터 열 폭 / 행 높이 (패널 좌표 그리드).
        static let scoreboardRowHeaderWidth: CGFloat = 128
        static let scoreboardColumnWidth: CGFloat = 160
        static let scoreboardRowHeight: CGFloat = 44
        /// 패널 상단에서 열 헤더 행 중심까지의 거리 (패널 헤더 슬롯 아래).
        static let scoreboardGridTopInset: CGFloat = 56
        /// 행 헤더 포트레이트 한 변 (24×24 ×1 = 24pt — 정수 배율 .nearest) + 이름과의 간격.
        static let scoreboardPortraitSide: CGFloat = 24
        static let scoreboardPortraitNameGap: CGFloat = 8
        /// 셀 내부 — 점수 라벨 y / 별 행 y (행 중심 기준).
        static let scoreboardCellScoreOffsetY: CGFloat = 9
        static let scoreboardCellStarOffsetY: CGFloat = -12
        /// 직전 신기록 마커(gold ★) — 셀 중심 기준 오프셋.
        static let scoreboardMarkerOffset = CGPoint(x: 56, y: 12)
        /// 미기록 셀 텍스트.
        static let scoreboardEmptyCellText: String = "—"
        /// stat 칩 2개 — 우상단 top bar 행(뒤로 버튼 반대편), 칩 사이 간격.
        /// (패널 아래 배치는 402pt 화면에서 화면 밖 — 스크린샷 실측 보정.)
        static let scoreboardStatChipGap: CGFloat = 16
        /// stat 칩 카피 — "총 플레이 N회" / "졸업장 N장".
        static let scoreboardPlaysPrefix: String = "총 플레이 "
        static let scoreboardPlaysSuffix: String = "회"
        static let scoreboardDiplomaPrefix: String = "졸업장 "
        static let scoreboardDiplomaSuffix: String = "장"

        // MARK: 계정/프로필 오버레이 (기능 5·6 — 카피는 기존 UILayout 상수 재사용, 수치만 신규)
        /// 계정 메뉴 다이얼로그 패널 크기.
        static let accountDialogPanelSize = CGSize(width: 480, height: 256)
        /// 계정 메뉴 — 제목/본문 중심 y (패널 좌표).
        static let accountDialogTitleOffsetY: CGFloat = 84
        static let accountDialogBodyOffsetY: CGFloat = 28
        /// 계정 메뉴 — 버튼 행 중심 y + 버튼 크기 + 간격.
        static let accountDialogButtonRowY: CGFloat = -76
        static let accountDialogButtonSize = CGSize(width: 132, height: 44)
        static let accountDialogCancelButtonSize = CGSize(width: 88, height: 44)
        static let accountDialogButtonGap: CGFloat = 12
        /// 본문 줄바꿈 최대 폭.
        static let accountDialogBodyMaxWidth: CGFloat = 416

        /// 프로필 상세 다이얼로그 패널 크기.
        static let profileDialogPanelSize = CGSize(width: 640, height: 372)
        /// 헤더 — 아바타 프레임 한 변(72 = 24×3 정수 배율 수용) + 좌상단 inset + 텍스트 간격.
        static let profileAvatarFrameSide: CGFloat = 72
        static let profileHeaderInset: CGFloat = 28
        static let profileHeaderTextGap: CGFloat = 20
        static let profileTitleOffsetY: CGFloat = 18
        static let profileBodyBelowTitleGap: CGFloat = 26
        /// 본문 줄바꿈 최대 폭.
        static let profileBodyMaxWidth: CGFloat = 360
        /// 지표 3종 행 — 칸 폭/간격/제목·값 y (패널 좌표).
        static let profileMetricWidth: CGFloat = 128
        static let profileMetricGap: CGFloat = 16
        static let profileMetricTitleOffsetY: CGFloat = 52
        static let profileMetricValueOffsetY: CGFloat = 24
        /// 버튼 행 2개 y + 버튼 크기 + 간격.
        static let profileFirstButtonRowY: CGFloat = -76
        /// R10 D-2 — -132 → -126: 3행(-164, 시각 상단 -151)과의 시각 겹침 해소(2행 시각 하단
        /// -148 — 3pt 분리). 1행 터치 띠 [-98, -54]와 2행 터치 띠 [-148, -104]도 6pt 분리 유지.
        static let profileSecondButtonRowY: CGFloat = -126
        static let profileWideButtonSize = CGSize(width: 152, height: 44)
        static let profileButtonSize = CGSize(width: 112, height: 44)
        static let profileButtonGap: CGFloat = 12
        /// 아바타 피커 — 옵션 카드 크기/간격/행 y + 포트레이트 한 변(48 = 24×2 정수 배율).
        static let profileAvatarOptionSize = CGSize(width: 84, height: 108)
        static let profileAvatarOptionGap: CGFloat = 12
        static let profileAvatarOptionRowY: CGFloat = -10
        static let profileAvatarOptionPortraitSide: CGFloat = 48
        static let profileAvatarOptionPortraitOffsetY: CGFloat = 10
        static let profileAvatarOptionLabelOffsetY: CGFloat = -38
        /// 아바타 뷰 — 프레임 내 포트레이트 한 변(48 = 24×2 정수 배율 — 프레임 72 안 12pt 여백).
        static let profileAvatarContentSide: CGFloat = 48

        // MARK: StartScene (기능 7 — 프로필 칩 확장·히어로 정수 스냅)
        /// 프로필 칩 아이콘 슬롯 한 변 (칩 높이 24 이내 — R4.difficultyContextChipIconSide와 동치 의미 분리).
        static let startProfileChipIconSide: CGFloat = 18
        /// 히어로 실효 픽셀 셀 하한 (pt) — 정수 스냅 후 최소 2pt 보장.
        static let startHeroMinPixelCell: CGFloat = 2
    }
}
