//
//  UILayout+R4.swift
//  GanhoMusic Shared
//
//  R4 메뉴 씬 재구축 — 4씬 레이아웃 토큰 (SPEC §D 신규, 매직 넘버 0 원칙).
//  공통 형태 메트릭(v3*)·간격(Space)은 UILayout.swift R3 섹션을 그대로 소비하고,
//  R4 씬 고유 수치만 여기에 둔다. 4pt 그리드·정수 좌표 스냅 (03_UI §1 원칙 2).
//

import UIKit

extension UILayout {
    /// R4 메뉴 씬 레이아웃 토큰 네임스페이스. case 없는 enum — 인스턴스화 차단.
    enum R4 {
        // MARK: 공통 (§E)
        /// staggered 등장 시 아래→위 상승 거리 (pt).
        static let appearRise: CGFloat = 12
        /// 좌상단 뒤로 ghost 버튼 시각 크기.
        static let backButtonSize = CGSize(width: 104, height: 40)
        /// 하단 주 CTA(primary) 버튼 시각 크기.
        static let ctaButtonSize = CGSize(width: 180, height: 52)
        /// 하단 보조(ghost) 버튼 시각 크기.
        static let secondaryCTAButtonSize = CGSize(width: 148, height: 44)
        /// 칩 탭 히트 패딩 — 칩 높이 24 → 44pt 터치 보장 inset.
        static let chipHitPadding: CGFloat = 10
        /// 하단 CTA 행의 화면 하단(safe 포함)으로부터의 버튼 중심 y 오프셋.
        static let ctaBottomInset: CGFloat = 40

        // MARK: StartScene (§F-1)
        /// 로고타입 텍스트 — v2 2-라인 타이틀 폐기 후 1줄 로고 (03_UI §6-1).
        static let startLogoText: String = "♪ 김간호는 음악박사 ♪"
        /// 로고 중심의 상단(safe 포함)으로부터의 y 오프셋.
        static let startLogoTopInset: CGFloat = 64
        /// 김간호 대형 픽셀 표시 배율 — 48×64px → 144×192pt (정수 배율, .nearest 픽셀 보존).
        static let startHeroPixelScale: CGFloat = 3
        /// 히어로 중심의 midY 기준 y 오프셋 (음수 = 아래).
        static let startHeroCenterYOffset: CGFloat = -20
        /// "▶ 탭하여 시작" 라벨 텍스트.
        static let startTapToStartText: String = "▶ 탭하여 시작"
        /// 탭 라벨 중심의 하단(safe 포함)으로부터의 y 오프셋.
        static let startTapLabelBottomInset: CGFloat = 44
        /// 로그인 다이얼로그 패널 크기 (PixelDialogNode panelSize).
        static let loginDialogPanelSize = CGSize(width: 480, height: 248)
        /// 로그인 다이얼로그 본문 줄바꿈 최대 폭.
        static let loginDialogBodyMaxWidth: CGFloat = 416
        /// 로그인 다이얼로그 본문 중심 y (패널 좌표).
        static let loginDialogBodyOffsetY: CGFloat = 24
        /// 로그인 다이얼로그 버튼 행 중심 y (패널 좌표).
        static let loginDialogButtonRowY: CGFloat = -40
        /// 로그인 다이얼로그 버튼 크기 (게스트/Apple).
        static let loginDialogButtonSize = CGSize(width: 148, height: 44)
        /// 로그인 다이얼로그 취소 버튼 크기.
        static let loginDialogCancelButtonSize = CGSize(width: 88, height: 44)
        /// 로그인 다이얼로그 상태 텍스트 중심 y (패널 좌표).
        static let loginDialogStatusOffsetY: CGFloat = -92

        // MARK: CharacterSelectScene (§F-2)
        /// 좌측 풀바디 프리뷰 영역 중심 x — 화면 폭 비율 (~40% 영역의 중앙).
        static let selectPreviewCenterXRatio: CGFloat = 0.21
        /// 풀바디 프리뷰 표시 크기 — 16×20px ×9 = 144×180pt (SPEC §F-2, 정수 배율 .nearest).
        static let selectPreviewSpriteSize = CGSize(width: 144, height: 180)
        /// 프리뷰 중심의 midY 기준 y 오프셋.
        static let selectPreviewCenterYOffset: CGFloat = 24
        /// 프리뷰 이름(h1) 라벨 — 프리뷰 하단으로부터의 간격.
        static let selectPreviewNameGap: CGFloat = 20
        /// 프리뷰 칭호(tag) 라벨 — 이름 아래 간격.
        static let selectPreviewTagGap: CGFloat = 26
        /// 캐러셀 클립(SKCropNode) 좌측 경계 — 화면 폭 비율. 우측 끝까지가 캐러셀 영역.
        static let selectCarouselClipLeftRatio: CGFloat = 0.42
        /// 캐러셀 중심 x — 클립 영역의 중앙 ((0.42+1)/2).
        static let selectCarouselCenterXRatio: CGFloat = 0.71
        /// 캐러셀 카드 스텝 — 화면 폭 비율. 양옆 카드가 클립 경계에 반쯤 걸친다 (§6-2).
        static let selectCarouselStepRatio: CGFloat = 0.29
        /// 캐러셀 중심의 midY 기준 y 오프셋.
        static let selectCarouselCenterYOffset: CGFloat = 36
        /// 캐릭터 카드 면 크기 (PixelCardNode size).
        static let characterCardSize = CGSize(width: 148, height: 196)
        /// 캐러셀 스와이프 임계값 (pt) — v2 characterHomeSwipeThreshold(44) 계승.
        static let selectSwipeThreshold: CGFloat = 44
        /// 하단 스킬 요약 라벨 중심 y — 하단(safe 포함) 기준.
        static let selectFooterLabelBottomInset: CGFloat = 96
        /// 하단 스킬 요약 1줄 접두 ("스킬 · 암벽등반 돌진 · 범위 4타일" 조립).
        static let selectFooterSkillPrefix: String = "스킬 · "
        /// 하단 버튼 행 — 두 버튼이 있을 때 사이 간격.
        static let selectFooterButtonGap: CGFloat = 24
        /// 상단·하단 버튼 텍스트.
        static let selectBackButtonText: String = "← 뒤로"
        static let selectStartButtonText: String = "출발"
        static let selectBriefingButtonText: String = "브리핑 보기"
        /// 김간호(스킬 없음) 하단 요약 텍스트 — 정공법 정체성 (GDD §4).
        static let selectFooterNoSkillText: String = "스킬 없음 — 정공법으로 승부합니다"
        /// 프로필 칩 폴백 텍스트 (닉네임·표시 이름 부재 시).
        static let profileChipFallbackText: String = "프로필"

        // MARK: PixelCharacterCardNode (§D 신규 컴포넌트)
        // R8 — 구 24×24 포트레이트 표시 토큰(cardPortraitSide 72/cardPortraitOffsetY 40)은
        // 일러스트 교체(UILayout.R8.cardIllustration*)로 참조 0 실증 후 삭제.
        /// 이름 라벨 중심 y (카드 좌표).
        static let cardNameOffsetY: CGFloat = -28
        /// 칩 중심 y (카드 좌표).
        static let cardChipOffsetY: CGFloat = -64
        /// 김간호(스킬 없음) 카드 칩 텍스트.
        static let cardNoSkillChipText: String = "정공법"

        // MARK: SkillBriefingScene (§F-3)
        /// 좌측 카드 중심 x — 화면 폭 비율.
        static let briefingCardCenterXRatio: CGFloat = 0.24
        /// 콘텐츠(카드·패널) 중심의 midY 기준 y 오프셋.
        static let briefingContentCenterYOffset: CGFloat = 28
        /// 우측 브리핑 패널 크기 (PixelPanelNode size).
        /// R12 #11 — 높이 264→288 (+9%, ±20% 내 허용): near-miss 팁 1줄(-124) 하단 수납.
        static let briefingPanelSize = CGSize(width: 432, height: 288)
        /// 우측 패널 중심 x — 화면 폭 비율.
        static let briefingPanelCenterXRatio: CGFloat = 0.65
        /// 패널 헤더 제목 텍스트 (03_UI §6-3 "작전 브리핑").
        static let briefingPanelTitleText: String = "작전 브리핑"
        /// 하단 primary 버튼 텍스트 — 다음 단계 = 난이도 선택 (§6-3).
        static let briefingNextButtonText: String = "난이도 선택"
        /// 스킬명(h1) 중심 y (패널 좌표).
        static let briefingSkillNameOffsetY: CGFloat = 56
        /// 인용문 좌측 액센트 바 두께 — §6-3 수치 3px.
        static let briefingQuoteBarWidth: CGFloat = 3
        /// 인용문 블록 중심 y (패널 좌표).
        static let briefingQuoteOffsetY: CGFloat = -4
        /// 인용문 줄바꿈 최대 폭 (액센트 바·패딩 제외).
        static let briefingQuoteMaxWidth: CGFloat = 360
        /// 칩 행 중심 y (패널 좌표).
        static let briefingChipRowOffsetY: CGFloat = -100
        /// 칩 간 가로 간격.
        static let briefingChipGap: CGFloat = 12
        /// 브리핑 칩 라벨 — 쿨다운/범위/발동 접두.
        static let briefingChipCDPrefix: String = "CD "
        static let briefingChipRangePrefix: String = "범위 "
        static let briefingChipCastPrefix: String = "발동 "
        /// 쿨다운 표기 — 게임당 1회/없음/N초 (기존 분기 보존).
        static let briefingOnceText: String = "1회"
        static let briefingNoneText: String = "—"
        static let briefingSecondsSuffix: String = "초"

        // MARK: DifficultySelectScene (§F-4)
        /// 화면 제목 텍스트.
        static let difficultyTitleText: String = "난이도 선택"
        /// 제목 중심의 상단(safe 포함)으로부터의 y 오프셋.
        static let difficultyTitleTopInset: CGFloat = 36
        /// 난이도 카드 면 크기.
        static let difficultyCardSize = CGSize(width: 176, height: 204)
        /// 카드 행 중심 간 가로 스텝.
        static let difficultyCardStep: CGFloat = 200
        /// 카드 행 중심의 midY 기준 y 오프셋.
        static let difficultyCardRowYOffset: CGFloat = 24
        /// 카드 내 난이도명(h2) 중심 y (카드 좌표).
        static let difficultyNameOffsetY: CGFloat = 72
        /// 카드 내 목표 점수(h1) 중심 y (카드 좌표).
        static let difficultyTargetOffsetY: CGFloat = 28
        /// 목표 점수 캡션 텍스트 + 점 접미.
        static let difficultyTargetCaptionText: String = "목표"
        static let difficultyTargetCaptionOffsetY: CGFloat = 52
        /// 빌런 아이콘 행 중심 y (카드 좌표).
        static let difficultyVillainRowOffsetY: CGFloat = -28
        /// 빌런 아이콘 표시 크기 — 16×20px 데이터 ×2 = 32×40pt.
        static let difficultyVillainIconSize = CGSize(width: 32, height: 40)
        /// 빌런 아이콘 간 가로 간격.
        static let difficultyVillainIconGap: CGFloat = 12
        /// 내 최고 기록 칩 중심 y (카드 좌표).
        static let difficultyBestChipOffsetY: CGFloat = -76
        /// 최고 기록 칩 텍스트 접두/접미.
        static let difficultyBestChipPrefix: String = "최고 "
        static let difficultyBestChipSuffix: String = "점"
        /// 상단 캐릭터 컨텍스트 칩 아이콘 한 변 (칩 높이 24 이내).
        static let difficultyContextChipIconSide: CGFloat = 18
        /// 시작 버튼 텍스트 (v2 카피 계승).
        static let difficultyStartButtonText: String = "시작"

        // MARK: ScoreboardScene 최소 교체 (§F-7)
        /// 행 헤더 포트레이트 표시 한 변 — 기존 mini 표시 폭 ~32pt 유지.
        static let scoreboardPortraitSide: CGFloat = 32

        // MARK: §C-11 빌런 난이도 구성 (시각 전용 고정 상수 — GameScene+Setup 실측 근거)
        /// easy·normal = [수간호사·석조무사·박병장] / hard = [수간호사·이교수·박병장].
        /// switch exhaustive — default 금지.
        static func difficultyVillains(_ d: Difficulty) -> [DifficultyVillainIcon] {
            switch d {
            case .easy:   return [.nurseChief, .stoneGuard, .sergeantPark]
            case .normal: return [.nurseChief, .stoneGuard, .sergeantPark]
            case .hard:   return [.nurseChief, .professor, .sergeantPark]
            }
        }
    }
}
