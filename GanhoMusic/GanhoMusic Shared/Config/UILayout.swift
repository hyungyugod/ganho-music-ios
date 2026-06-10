//
//  UILayout.swift
//  GanhoMusic Shared
//
//  R0 — 구 god-config(분할 전 단일 Config) 분해: 패널·카드·버튼·여백·오버레이 레이아웃 + 컴포넌트 국소 폰트크기·UI 문구.
//  값은 분할 전과 byte-equal — R0는 위치 이동만 (행동 불변).
//  300줄 초과는 Config 상수 파일 예외(SPEC §12-7) — 로직 0, 순수 매핑 함수(hospitalPropSize)만 동행.
//

import Foundation
import CoreGraphics

/// UI 레이아웃 상수 네임스페이스 — 씬·컴포넌트 배치 수치와 UI 문구.
/// case 없는 enum: 인스턴스화 차단 (왜: R3 디자인 시스템 교체 시 단일 수정점 확보).
enum UILayout {
    // MARK: - Sprint 1 Design Foundation
    static let menuHorizontalSafePadding: CGFloat = 32
    static let menuTopSafePadding: CGFloat = 24
    static let menuBottomSafePadding: CGFloat = 24
    static let regularLayoutScale: CGFloat = 1.0
    static let compactLandscapeMinHeight: CGFloat = 390
    static let compactLayoutScale: CGFloat = 0.88
    static let compactNarrowWidth: CGFloat = 760
    static let compactNarrowLayoutScale: CGFloat = 0.92
    static let ipadMenuLayoutScale: CGFloat = 1.08
    static let ipadMenuMaxContentWidth: CGFloat = 1060
    static let ipadResultMaxContentWidth: CGFloat = 980
    static let ipadScoreboardMaxContentWidth: CGFloat = 1060
    static let ipadIngameHUDScale: CGFloat = 1.08
    static let ipadIngameControlScale: CGFloat = 1.15
    static let ipadIngameTopButtonScale: CGFloat = 1.12
    static let ipadCameraScaleFloor: CGFloat = 0.62
    static let ipadCameraScaleCeiling: CGFloat = 1.0
    static let ingameHUDReadableAlpha: CGFloat = 0.92
    static let ingameControlReadableAlpha: CGFloat = 0.78
    static let ingameSafeControlPadding: CGFloat = 18
    static let resultPanelHorizontalPadding: CGFloat = 48
    static let resultPanelCompactScale: CGFloat = 0.86
    static let primaryButtonTextHorizontalPadding: CGFloat = 36
    static let primaryButtonArrowReservedWidth: CGFloat = 48
    static let resultPanelVerticalSafePadding: CGFloat = 40
    static let resultRewardPulseDelay: TimeInterval = 0.3
    static let resultButtonCompactScale: CGFloat = 0.82
    static let resultButtonMinimumGap: CGFloat = 8
    static let resultButtonCompactGap: CGFloat = 10
    static let resultLegacyStatTitleGap: CGFloat = 14

    // MARK: - Sprint V7 — ResultScene Wide Layout
    static let resultWidePanelMaxWidth: CGFloat = 760
    static let resultWidePanelMinWidth: CGFloat = 560
    static let resultWidePanelHeight: CGFloat = 360
    static let resultWidePanelHorizontalPadding: CGFloat = 36
    static let resultWidePanelVerticalPadding: CGFloat = 28
    static let resultWidePanelSafeGap: CGFloat = 18
    static let resultWideColumnInset: CGFloat = 42
    static let resultWideColumnGap: CGFloat = 44
    static let resultWideScoreColumnRatio: CGFloat = 0.48
    static let resultWideGoalColumnRatio: CGFloat = 0.52
    static let resultWideTopInset: CGFloat = 42
    static let resultWideTitleBelowTop: CGFloat = 32
    static let resultWideScoreBelowTop: CGFloat = 122
    static let resultWideStatsBottomInset: CGFloat = 36
    static let resultWideStatSpacingX: CGFloat = 58
    static let resultWideGoalDividerWidth: CGFloat = 220
    static let resultWideScoreNoteGap: CGFloat = 18
    static let resultWideButtonBottomInset: CGFloat = 30
    static let resultWideButtonGap: CGFloat = 18
    static let resultWideCompactScale: CGFloat = 0.82
    static let resultWideNarrowScale: CGFloat = 0.9

    // MARK: - HUD (Phase 2-4)
    /// HUD 알파 (반투명, 가독성 우선). D-Pad 0.3보다 큼.
    static let hudAlpha: CGFloat = 0.85

    // MARK: - Result Scene (Phase 3-3)
    /// ResultScene "GAME OVER" 라벨 폰트 크기 (pt).
    static let resultTitleFontSize: CGFloat = 32
    /// ResultScene 점수 라벨 폰트 크기 (pt).
    static let resultScoreFontSize: CGFloat = 24
    /// ResultScene "TAP TO RETURN" 라벨 폰트 크기 (pt).
    static let resultPromptFontSize: CGFloat = 16
    /// ResultScene 안내 라벨 y 오프셋. frame.midY 기준 아래쪽.
    /// Phase 3-4 — bestLabel(-20)과 간격 확보 위해 -50 → -60.
    /// Phase 3-5 — statsLabel(-40)과 간격 확보 위해 -60 → -80.
    static let resultPromptOffsetY: CGFloat = -80

    // MARK: - High Score (Phase 3-4)
    /// ResultScene BEST 라벨 폰트 크기 (pt). 점수 라벨(24)보다 작고 안내 라벨(16)보다 큼.
    static let resultBestFontSize: CGFloat = 22
    /// ResultScene BEST 라벨 y 오프셋. score(+20)와 prompt(-60) 사이 가운데.
    /// Phase 3-5 — score(+40)/statsLabel(-40) 사이 가운데로 -20 → 0.
    static let resultBestOffsetY: CGFloat = 0

    // MARK: - Statistics (Phase 3-5)
    /// ResultScene PLAYS/TOTAL 라벨 폰트 크기 (pt). prompt(16)와 동급으로 보조 정보 톤.
    static let resultStatsFontSize: CGFloat = 16
    /// ResultScene PLAYS/TOTAL 라벨 y 오프셋. best(0)와 prompt(-80) 사이 균등 배치(-40).
    static let resultStatsOffsetY: CGFloat = -40

    // MARK: - Result Character (Phase 5-7)
    /// Phase 5-7 — ResultScene 캐릭터 이름 라벨 폰트 크기 (pt). best(22)와 동급.
    /// title(32) > character(22) = best(22) > score(24)... 위계 — title 강조 유지.
    static let resultCharacterFontSize: CGFloat = 22
    /// Phase 5-7 — ResultScene 캐릭터 라벨 y 오프셋. title(+80) 위쪽에 배치.
    /// 5라벨 균등 40 간격(+80/+40/0/-40/-80) 깨지 않게 *위로* 35pt 추가.
    /// "정간호 / GAME OVER / 🎵 N / BEST / PLAYS / TAP" 위→아래 흐름.
    static let resultCharacterOffsetY: CGFloat = 115

    // MARK: - Sprint 10 Phase I — 원본 수치 봉인 (game.js L101~L105 1:1)
    /// ResultScene 난이도 라벨 y 오프셋 (pt). characterLabel(115) 더 위쪽 — "난이도: 상" / "🎮 김간호" / "GAME OVER" 톤.
    static let resultDifficultyOffsetY: CGFloat = 155
    /// ResultScene 난이도 라벨 폰트 크기 (pt). resultStats(16)와 동급 — 보조 정보 톤.
    static let resultDifficultyFontSize: CGFloat = 18

    // MARK: - Diploma (Phase 7-4)
    /// Sprint 2 — 결과 목표 판정 라벨 폰트 크기.
    static let resultGoalLabelFontSize: CGFloat = 15
    /// Sprint 2 — 결과 목표 보조 요약 라벨 폰트 크기.
    static let resultGoalSummaryFontSize: CGFloat = 12
    /// Sprint 2 — 결과 목표 판정 y 오프셋. 큰 점수 아래, divider 위 영역.
    static let resultGoalJudgementOffsetY: CGFloat = -30
    /// Sprint 2 — 이번 판 요약 y 오프셋.
    static let resultGoalSummaryOffsetY: CGFloat = -52
    static let resultGoalAchievedTitle: String = "목표 달성"
    static let resultGoalNearTitle: String = "거의 왔다"
    static let resultGoalRetryTitle: String = "다시 박자 잡기"
    static let resultGoalNextComboText: String = "다음 판은 콤보 20까지"
    static let resultGoalGapPrefix: String = "다음 목표까지"
    static let resultGoalPointSuffix: String = "점"
    static let resultGoalTargetPrefix: String = "목표"
    static let resultGoalRoundPrefix: String = "이번 판"
    static let resultGoalDifficultySuffix: String = "난이도"

    // MARK: - Result Verdict (성공/실패 큰 판정)
    /// 결과 verdict 성공 텍스트. finalScore >= target일 때 우측 컬럼 머리글.
    static let resultVerdictSuccessText: String = "성공"
    /// 결과 verdict 실패 텍스트. finalScore < target일 때 우측 컬럼 머리글.
    static let resultVerdictFailureText: String = "실패"
    /// 성공 시 verdict 아래 한 줄 격려 문구. gap 점수 대신 보여 다음 도전을 권한다.
    static let resultVerdictSuccessSubText: String = "좋아요! 더 높이 가볼까요?"
    /// 실패 gap 문구 접미. "{gap}점" + 이 접미 = "{gap}점 더 모아야 해요".
    static let resultVerdictFailureGapSuffix: String = " 더 모아야 해요"
    /// 큰 verdict 폰트 크기. 기존 보조 라벨(15pt) 대비 약 3배로 "성공/실패"를 즉각 전달.
    static let resultVerdictFontSize: CGFloat = 44
    /// V1 — verdict 머리글 y(우측 컬럼 topY 기준 아래). 큰 폰트를 topY 가까이 두고 아래로 펼친다.
    static let resultVerdictBelowTop: CGFloat = 56
    /// V1 — verdict ↓ summary 세로 간격. verdict 큰 폰트 높이 + 여백 이상으로 겹침 0 보장.
    static let resultVerdictSummaryGap: CGFloat = 60
    /// V1 — verdict ↓ nextGoal 세로 간격. summary 아래로 한 줄 더 내린다.
    static let resultVerdictNextGoalGap: CGFloat = 88
    /// V1 — verdict ↓ divider 세로 간격. nextGoal 아래에서 우측 컬럼을 마무리한다.
    static let resultVerdictDividerGap: CGFloat = 114

    // MARK: - Firebase Auth / Cloud Save
    static let profileNameEditDisplayNameUserInfoKey: String = "profileNameEditDisplayName"
    static let profileNameEditNicknameUserInfoKey: String = "profileNameEditNickname"
    static let profileNameEditRequiredUserInfoKey: String = "profileNameEditRequired"
    static let profileNameEditSucceededUserInfoKey: String = "profileNameEditSucceeded"
    static let profileNameEditTitleText: String = "프로필 이름"
    static let profileNameEditRequiredTitleText: String = "닉네임 설정"
    static let profileNameEditMessageText: String = "게임 안에서 불릴 이름을 정해 주세요."
    static let profileNameEditRequiredMessageText: String = "Apple 계정 기록에 붙일 닉네임이 필요해요."
    static let profileNameEditDisplayPlaceholderText: String = "이름"
    static let profileNameEditNicknamePlaceholderText: String = "닉네임"
    static let profileNameEditSaveText: String = "저장"
    static let profileNameEditCancelText: String = "취소"
    static let profileNameEditSavingText: String = "저장 중"
    static let profileNameEditNicknameEmptyText: String = "닉네임을 입력해 주세요."
    static let profileNameEditNicknameTooShortText: String = "닉네임을 조금 더 적어 주세요."
    static let profileNameEditNicknameTooLongText: String = "닉네임이 너무 길어요."
    static let profileNameEditSavedText: String = "프로필 이름 저장"
    static let profileNameEditFailedText: String = "이름 저장 실패"
    static let profileNameEditDimAlpha: CGFloat = 0.42
    static let profileNameEditPanelMaxWidth: CGFloat = 420
    static let profileNameEditPanelMinWidth: CGFloat = 320
    static let profileNameEditPanelHorizontalSafeInset: CGFloat = 28
    static let profileNameEditPanelVerticalSafeInset: CGFloat = 18
    static let profileNameEditPanelCornerRadius: CGFloat = 18
    static let profileNameEditPanelBorderWidth: CGFloat = 1
    static let profileNameEditPanelBorderAlpha: CGFloat = 0.24
    static let profileNameEditPanelShadowAlpha: Float = 0.14
    static let profileNameEditPanelShadowRadius: CGFloat = 14
    static let profileNameEditPanelShadowOffsetY: CGFloat = 5
    static let profileNameEditContentInset: CGFloat = 22
    static let profileNameEditStackSpacing: CGFloat = 12
    static let profileNameEditFieldHeight: CGFloat = 40
    static let profileNameEditButtonHeight: CGFloat = 38
    static let profileNameEditButtonGap: CGFloat = 10
    static let profileNameEditTitleFontSize: CGFloat = 22
    static let profileNameEditMessageFontSize: CGFloat = 13
    static let profileNameEditFieldFontSize: CGFloat = 15
    static let profileNameEditButtonFontSize: CGFloat = 15
    static let profileNameEditFieldCornerRadius: CGFloat = 10
    static let profileNameEditFieldBorderWidth: CGFloat = 1
    static let profileNameEditFieldBorderAlpha: CGFloat = 0.22
    static let profileNameEditFieldHorizontalInset: CGFloat = 12
    static let profileNameEditPanelMinimumWidthPriority: Float = 750
    static let profileNameEditPanelPreferredWidthPriority: Float = 760

    // MARK: - Profile Name Editor — Keyboard Avoidance (신규)
    /// 키보드 상단과 패널 하단 사이 최소 여유(pt). 저장 버튼이 키보드에 닿지 않게.
    static let profileNameEditKeyboardClearance: CGFloat = 16
    /// 키보드 회피 애니메이션 길이 fallback(초). 노티에 duration 없을 때만 사용.
    static let profileNameEditKeyboardAnimationDuration: TimeInterval = 0.25

    // MARK: - Game UI Tokens (Phase 8-3)
    /// 원본 game.css 패널/카드 layout 상수 1:1 매핑.
    /// 디자인 단일 진실 원천 = style.css(L3-46) + game.css(L335-740).

    /// --radius 10px — 일반 카드/패널 코너
    static let uiRadius: CGFloat = 10
    /// --radius-sm 6px — 작은 카드 코너
    static let uiRadiusSm: CGFloat = 6
    /// 패널/카드 보더 line-width 1px
    static let uiPanelLineWidth: CGFloat = 1

    // MARK: - Result Scene UI (Phase 8-4)
    /// 원본 #overlayEnd .game-overlay__panel--end (game.css L877-906) 1:1 매핑.
    /// 반투명 검정 배경(.ganhoUIOverlayBg) + 가운데 380 너비 카드 패널(.ganhoUIBgCard) + 점수 40pt 코럴 serif.
    /// 라벨 위치는 *기존 유지*, 시각 토큰만 갈아 끼움(Phase 8-4 SPEC).

    /// 카드 패널 max-width — 원본 380px
    static let resultPanelMaxWidth: CGFloat = 380
    /// 카드 패널 height (pt) — 모바일 풀스크린 비율에 맞춰. 라벨 6개(+155 ~ -80)가 패널 안에 들어가도록 560.
    static let resultPanelHeight: CGFloat = 560
    /// 점수 라벨 font-size — 원본 14px text-muted (.game-overlay__score)
    static let resultScoreLabelFontSize: CGFloat = 14
    /// 베스트 record font-size — 원본 12px brand (.game-overlay__record)
    static let resultRecordFontSize: CGFloat = 12
    /// 통계 라벨 font-size — 원본 11px upper case (.game-overlay__stats li label)
    static let resultStatsLabelFontSize: CGFloat = 11
    /// 통계 값 font-size — 원본 16px tabular (.game-overlay__stats li b, end-scope 15)
    static let resultStatsValueFontSize: CGFloat = 16

    // MARK: - HUD Layout (Phase 8-5)
    /// 원본 .game-hud (game.css L232-289) 상단 가로 슬롯 배치 1:1 매핑.
    /// 좌상단 세로 스택 → 상단 중앙 가로 4슬롯(TIME / SCORE / COMBO / PLAYER) 재구성.
    static let hudTopMargin: CGFloat = 28           // 화면 상단에서 hud anchor 거리
    static let hudSlotSpacing: CGFloat = 80         // 슬롯 4개 간격 (수평)
    static let hudValueFontSize: CGFloat = 22       // 원본 .game-hud__value 22px
    static let hudLabelFontSize: CGFloat = 10       // 원본 .game-hud__label 10px
    static let hudSlotInnerGap: CGFloat = 4         // 라벨 ↔ 값 세로 간격
    static let hudLabelLetterSpacing: CGFloat = 2   // 원본 letter-spacing 2px (SKLabelNode 미지원, 기록만)

    // MARK: - Skill (Phase 9-5)

    // HUDSkillSlotNode
    /// 쿨다운 진행 링의 반지름 (pt). 작은 인디케이터.
    static let hudSkillSlotRingRadius: CGFloat = 12
    /// 링의 라인 두께 (pt).
    static let hudSkillSlotRingLineWidth: CGFloat = 2

    // MARK: - Start Scene (Phase 10-1a)

    /// 스토리 박스 가로 (pt). uiPanelCharacterMaxWidth(480)보다 살짝 좁아 패널 안 내부 여백 확보.
    static let storyBoxWidth: CGFloat = 440
    /// 스토리 박스 세로 (pt). 한국어 본문 2~3줄 자동 줄바꿈에 충분한 높이.
    static let storyBoxHeight: CGFloat = 80
    /// 스토리 박스 본문 폰트 크기 (pt). cutsceneBodyFontSize(20)보다 작음 — 박스 안 톤.
    static let storyBoxFontSize: CGFloat = 14
    /// 스토리 박스 좌우 패딩 (pt). preferredMaxLayoutWidth = boxWidth - padding×2.
    static let storyBoxHorizontalPadding: CGFloat = 16

    /// 주요 버튼 가로 (pt). 한국어 2~5자 + 여백.
    static let primaryButtonWidth: CGFloat = 160
    /// 주요 버튼 세로 (pt). cornerRadius = height/2로 캡슐.
    static let primaryButtonHeight: CGFloat = 48
    /// 주요 버튼 폰트 크기 (pt).
    static let primaryButtonFontSize: CGFloat = 18
    /// 보조(뒤로) 버튼 가로 (pt). 주요 버튼보다 살짝 좁음 — 시각 위계.
    static let backButtonWidth: CGFloat = 140
    /// 보조 버튼 세로 (pt).
    static let backButtonHeight: CGFloat = 40
    /// 보조 버튼 폰트 크기 (pt). 주요(18)보다 작음.
    static let backButtonFontSize: CGFloat = 14

    // MARK: - Start Scene Visual (Phase 10-2 · 병동의 새벽 톤)


    /// 제목 글로우 SKEffectNode CIGaussianBlur 반경 (pt).
    static let titleGlowBlurRadius: CGFloat = 8.0


    // MARK: - v2 Components (Sprint 1)

    /// GlassPillNode 배경 크림(ganhoPaper) α. 묶음 A 어포던스 강화 — 0.55 → 0.82로 불투명 상향.
    /// "버튼인지 글자인지" 헷갈리던 흰 알약을 또렷한 크림 표면으로.
    static let glassPillFillAlpha: CGFloat = 0.94
    /// GlassPillNode stroke α — 살짝의 외곽선. (코랄 테두리 전환 후에도 다른 참조 보호 위해 유지.)
    static let glassPillStrokeAlpha: CGFloat = 0.20
    /// GlassPillNode 가우시안 블러 반경. §3.3.B = radius 12.
    static let glassPillBlurRadius: CGFloat = 0
    /// GlassPillNode 라벨 폰트 크기.
    static let glassPillFontSize: CGFloat = 14

    // GlassPill 어포던스 강화 (묶음 A) — Secondary 버튼 3계층 입체화.
    /// 코랄 테두리 두께(pt). 흰·크림 알약에도 "버튼임"을 전달하는 또렷한 경계.
    static let glassPillBorderWidth: CGFloat = 1
    /// 입체 그림자 노드 y 오프셋(pt). 음수 = 아래로 떨궈 떠 있는 느낌.
    static let glassPillShadowOffsetY: CGFloat = 0
    /// 입체 그림자 노드 알파. ganhoCoralShadow 위에 곱해 은은한 그림자.
    static let glassPillShadowAlpha: CGFloat = 0
    /// destructive 톤(계정 삭제) fill 불투명. 딥코랄을 거의 꽉 차게.
    static let glassPillDestructiveFillAlpha: CGFloat = 0.92

    /// AccentLineNode 가로 길이(pt). §3.3.C = 32.
    static let accentLineWidth: CGFloat = 32
    /// AccentLineNode 두께(pt). §3.3.C = 3.
    static let accentLineHeight: CGFloat = 3

    /// DarkContextChipNode 배경 navy α. §3.3.D = 0.92.
    static let darkContextChipBgAlpha: CGFloat = 0.92
    /// DarkContextChipNode 라벨 폰트 크기.
    static let darkContextChipLabelFontSize: CGFloat = 13
    /// DarkContextChipNode 뱃지 폰트 크기. 더 작음.
    static let darkContextChipBadgeFontSize: CGFloat = 11
    /// DarkContextChipNode 가로 패딩(pt) — 라벨 양옆 여백.
    static let darkContextChipHorizontalPadding: CGFloat = 14
    /// DarkContextChipNode 세로 높이(pt).
    static let darkContextChipHeight: CGFloat = 28
    /// DarkContextChipNode 라벨-뱃지 간 가로 간격(pt).
    static let darkContextChipBadgeSpacing: CGFloat = 8
    /// DarkContextChipNode 뱃지 내부 가로 패딩(pt) — 뱃지 라벨 양옆 여백.
    static let darkContextChipBadgeHorizontalPadding: CGFloat = 12
    /// DarkContextChipNode 뱃지 세로 inset(pt) — 칩 높이 - inset = 뱃지 높이.
    static let darkContextChipBadgeVerticalInset: CGFloat = 8

    /// PrimaryButtonNode v2 그림자 y 오프셋(pt) — 음수면 아래쪽. §3.3.A = 6 → -6.
    static let primaryButtonShadowOffsetY: CGFloat = 0
    /// PrimaryButtonNode v2 그림자 blur(pt).
    static let primaryButtonShadowBlurRadius: CGFloat = 0
    /// PrimaryButtonNode v2 우측 화살표 원 반경(pt).
    static let primaryButtonArrowRadius: CGFloat = 12
    /// PrimaryButtonNode v2 우측 화살표 우측 마진(pt) — 배경 우측 끝에서 안쪽 거리.
    static let primaryButtonArrowInsetX: CGFloat = 22
    /// PrimaryButtonNode v2 우측 화살표 원 화이트 α — 살짝 반투명한 동그라미.
    static let primaryButtonArrowCircleAlpha: CGFloat = 0.12
    /// PrimaryButtonNode v2 우측 화살표 라벨 폰트 크기(pt).
    static let primaryButtonArrowLabelFontSize: CGFloat = 14

    // MARK: - Tone Down Controls
    static let menuControlFillAlpha: CGFloat = 0.94
    static let menuControlStrokeAlpha: CGFloat = 0.20
    static let menuControlLineWidth: CGFloat = 1
    static let menuControlShadowAlpha: CGFloat = 0
    static let menuControlArrowAlpha: CGFloat = 0.12
    static let menuControlEnabledAlpha: CGFloat = 1.0

    // MARK: - Sprint 2 · StartScene v2 Layout
    // DESIGN_RENEWAL_REQUEST.md §4.1 + mockups/main-screen-v2.html.
    // 본 섹션은 *추가만* — 기존 startScene* 상수(Phase 10-1a/10-2)는 미사용 상태가 되어도 *유지*.


    static let authGuestStatusText: String = "게스트 기록"
    static let authLinkedStatusText: String = "Apple 연동됨"
    static let authLocalFallbackStatusText: String = "로컬 플레이 가능"
    static let authAppleButtonText: String = "Apple로 연동"
    static let authAppleButtonBusyText: String = "연동 중"
    static let authManageButtonText: String = "계정"
    static let authManageButtonBusyText: String = "처리 중"
    static let authSignOutSuccessText: String = "게스트로 돌아왔어요"
    static let authAccountDeleteSuccessText: String = "계정 삭제 완료"
    static let authActionCancelledText: String = "취소했어요"
    static let authActionFailedText: String = "잠시 후 다시 시도"
    static let authStatusMessageDuration: TimeInterval = 1.6

    // MARK: - Login Choice Overlay
    static let loginChoiceTitleText: String = "계정 접속"
    static let loginChoiceBodyText: String = "Apple 계정으로 기록을 붙잡거나, 게스트 기록으로 바로 병동에 들어갑니다."
    static let loginChoiceGuestButtonText: String = "게스트로 시작"
    static let loginChoiceAppleButtonText: String = "Apple로 연동"
    static let loginChoiceCancelButtonText: String = "취소"
    static let loginChoiceCheckingAccountText: String = "계정 상태 확인 중"
    static let loginChoiceGuestBusyText: String = "게스트 준비 중"
    static let loginChoiceAppleBusyText: String = "Apple 로그인 중"
    static let loginChoiceCancelledText: String = "취소했어요"
    static let loginChoiceFailureText: String = "잠시 후 다시 시도"
    static let loginChoiceAppleTimeoutText: String = "Apple 로그인이 지연돼요"
    static let loginChoiceAppleConfigurationText: String = "Apple 로그인 설정을 확인해 주세요"
    static let loginChoiceAppleCredentialText: String = "Apple 인증 정보를 다시 확인해 주세요"

    // MARK: - Overlay Action Button
    static let overlayButtonShadowOffsetY: CGFloat = 0
    static let overlayButtonPressedOffsetY: CGFloat = 0
    static let overlayButtonPressDuration: TimeInterval = 0.08
    static let overlayButtonPressActionKey: String = "overlayButtonPress"
    /// 오버레이 버튼 테두리 두께(pt). 묶음 A — secondary 코랄 2px 테두리 가시성 위해 1 → 2.
    /// primary는 stroke가 clear라 영향 없음, destructive는 코랄딥 테두리라 OK.
    static let overlayButtonLineWidth: CGFloat = 1
    static let overlayButtonDisabledAlpha: CGFloat = 0.48
    static let overlayButtonTitleFontSize: CGFloat = 16
    static let overlayButtonSubtitleFontSize: CGFloat = 11
    static let overlayButtonSingleTitleFontSize: CGFloat = 15
    static let overlayButtonTextLeftInset: CGFloat = 46
    static let overlayButtonTextRightInset: CGFloat = 14
    static let overlayButtonIconRadius: CGFloat = 13
    static let overlayButtonIconOffsetX: CGFloat = 20
    static let overlayButtonTitleOffsetY: CGFloat = 8
    static let overlayButtonSubtitleOffsetY: CGFloat = -11
    static let overlayButtonSingleTitleOffsetY: CGFloat = 0
    static let overlayButtonHighlightHeight: CGFloat = 3
    static let overlayButtonHighlightAlpha: CGFloat = 0
    static let overlayButtonCornerRadius: CGFloat = 12
    static let overlayButtonDefaultIconText: String = "♪"
    static let overlayButtonSecondaryIconText: String = "·"
    static let overlayButtonDestructiveIconText: String = "!"

    // MARK: - Account Menu Overlay
    static let accountMenuDimAlpha: CGFloat = 0.48
    static let accountMenuPanelFillAlpha: CGFloat = 0.88
    static let accountMenuPanelStrokeAlpha: CGFloat = 0.35
    static let accountMenuPanelWidth: CGFloat = 420
    static let accountMenuPanelHeight: CGFloat = 226
    static let accountMenuPanelCompactWidth: CGFloat = 360
    static let accountMenuPanelCornerRadius: CGFloat = 20
    static let accountMenuPanelLineWidth: CGFloat = 1
    static let accountMenuTitleFontSize: CGFloat = 22
    static let accountMenuBodyFontSize: CGFloat = 15
    static let accountMenuBodyWidth: CGFloat = 340
    static let accountMenuTitleOffsetY: CGFloat = 76
    static let accountMenuBodyOffsetY: CGFloat = 22
    static let accountMenuButtonOffsetY: CGFloat = -72
    static let accountMenuButtonHeight: CGFloat = 30
    static let accountMenuButtonWidth: CGFloat = 98
    static let accountMenuCancelButtonWidth: CGFloat = 82
    static let accountMenuButtonGap: CGFloat = 10
    static let accountMenuMenuTitleText: String = "계정 관리"
    static let accountMenuLinkedBodyText: String = "Apple 계정으로 기록을 동기화 중입니다.\n로그아웃해도 기기 기록은 남습니다."
    static let accountMenuGuestBodyText: String = "현재 게스트 기록으로 플레이 중입니다.\n삭제해도 기기 최고점과 통계는 남습니다."
    static let accountMenuConfirmTitleText: String = "계정 삭제"
    static let accountMenuConfirmBodyText: String = "Firebase 계정과 클라우드 기록을 삭제합니다.\n기기 최고점, 통계, 캐릭터 선택은 유지됩니다."
    static let accountMenuBusyTitleText: String = "처리 중"
    static let accountMenuBusyBodyText: String = "계정 상태를 정리하고 있습니다.\n잠시만 기다려 주세요."
    static let accountMenuSignOutText: String = "로그아웃"
    static let accountMenuDeleteText: String = "계정 삭제"
    static let accountMenuConfirmDeleteText: String = "삭제"
    static let accountMenuCancelText: String = "취소"

    // MARK: - Profile Avatar
    static let profileAvatarPhotoDirectoryName: String = "ProfileAvatars"
    static let profileAvatarScopeUserInfoKey: String = "profileAvatarScope"
    static let profileAvatarPhotoSelectionLimit: Int = 1
    static let profileAvatarPhotoMaxPixelDimension: CGFloat = 512
    static let profileAvatarPhotoJPEGCompression: CGFloat = 0.86
    static let profileAvatarPhotoFilePrefix: String = "avatar_"
    static let profileAvatarPhotoFileExtension: String = ".jpg"
    static let profileAvatarFileNameSeparator: Character = "_"
    static let profileAvatarFrameCornerRadius: CGFloat = 14
    static let profileAvatarFrameLineWidth: CGFloat = 2
    static let profileAvatarFrameFillAlpha: CGFloat = 0.82
    static let profileAvatarFrameStrokeAlpha: CGFloat = 0.9
    static let profileAvatarContentInset: CGFloat = 8
    static let profileAvatarSummarySize = CGSize(width: 58, height: 58)

    // MARK: - Profile Detail Overlay
    static let profileDetailDimAlpha: CGFloat = 0.50
    static let profileDetailPanelFillAlpha: CGFloat = 0.94
    static let profileDetailPanelStrokeAlpha: CGFloat = 0.35
    static let profileDetailPanelWidth: CGFloat = 560
    static let profileDetailPanelCompactWidth: CGFloat = 480
    static let profileDetailPanelHeight: CGFloat = 326
    static let profileDetailPanelCornerRadius: CGFloat = 18
    static let profileDetailPanelLineWidth: CGFloat = 1
    static let profileDetailPanelHorizontalInset: CGFloat = 26
    static let profileDetailPanelTopInset: CGFloat = 26
    static let profileDetailAvatarSize = CGSize(width: 74, height: 74)
    static let profileDetailHeaderTextGap: CGFloat = 22
    static let profileDetailTitleOffsetY: CGFloat = 18
    static let profileDetailBodyBelowTitleGap: CGFloat = 28
    static let profileDetailTitleFontSize: CGFloat = 22
    static let profileDetailBodyFontSize: CGFloat = 12
    static let profileDetailBodyWidth: CGFloat = 300
    static let profileDetailMetricWidth: CGFloat = 104
    static let profileDetailMetricGap: CGFloat = 14
    static let profileDetailMetricTitleOffsetY: CGFloat = 48
    static let profileDetailMetricValueOffsetY: CGFloat = 20
    static let profileDetailMetricTitleFontSize: CGFloat = 12
    static let profileDetailMetricValueFontSize: CGFloat = 20
    static let profileDetailButtonWidth: CGFloat = 98
    static let profileDetailWideButtonWidth: CGFloat = 126
    static let profileDetailButtonHeight: CGFloat = 30
    static let profileDetailButtonGap: CGFloat = 12
    static let profileDetailFirstButtonRowOffsetY: CGFloat = -72
    static let profileDetailSecondButtonRowOffsetY: CGFloat = -118
    static let profileDetailBottomButtonOffsetY: CGFloat = -118
    static let profileDetailAvatarOptionSize = CGSize(width: 74, height: 98)
    static let profileDetailAvatarOptionPortraitSize = CGSize(width: 50, height: 62)
    static let profileDetailAvatarOptionGap: CGFloat = 8
    static let profileDetailAvatarOptionCornerRadius: CGFloat = 12
    static let profileDetailAvatarOptionFillAlpha: CGFloat = 0.82
    static let profileDetailAvatarOptionSelectedFillAlpha: CGFloat = 0.88
    static let profileDetailAvatarOptionSelectedLineWidth: CGFloat = 2
    static let profileDetailAvatarOptionPortraitOffsetY: CGFloat = 2
    static let profileDetailAvatarOptionLabelOffsetY: CGFloat = 36
    static let profileDetailAvatarOptionLabelFontSize: CGFloat = 12
    static let profileDetailAvatarOptionsOffsetY: CGFloat = -18
    static let profileDetailTitleText: String = "개인프로필"
    static let profileDetailChooseAvatarText: String = "초상화 변경"
    static let profileDetailChoosePhotoText: String = "사진 선택"
    static let profileDetailCloseText: String = "닫기"
    static let profileDetailAvatarPickerTitleText: String = "대표 초상화 선택"
    static let profileDetailAvatarPickerBodyText: String = "해금된 캐릭터만 대표 초상화로 쓸 수 있어요. 김간호는 항상 기본값입니다."
    static let profileDetailBusyTitleText: String = "처리 중"
    static let profileDetailBusyBodyText: String = "계정과 프로필 상태를 정리하고 있습니다."
    static let profileDetailPhotoPickerRequestText: String = "사진 선택을 열게요"
    static let profileDetailEditNameText: String = "이름/닉네임"
    static let profileDetailNicknamePrefixText: String = "닉네임:"
    static let profileDetailDisplayNamePrefixText: String = "이름:"
    static let profileNicknamePromptTitleText: String = "닉네임을 정해요"
    static let profileNicknamePromptBodyText: String = "Apple 계정으로 기록을 이어가려면 게임 안에서 부를 닉네임이 필요해요."
    static let profileNicknamePromptButtonText: String = "닉네임 설정"

    // MARK: - Bundle B · Profile v2 Hierarchy
    // 프로필 3종(Summary/Detail/Avatar)을 묶음 A v2 톤으로 통일하기 위한 위계 표현 상수.
    // 순수 시각·위계용 — 좌표/크기 상수의 값은 건드리지 않고 *추가* 노드(그룹 박스·구분선)만 그린다.

    /// ProfileSummary 메트릭 그룹 박스(라벤더 패드) 채움 투명도.
    static let summaryMetricGroupFillAlpha: CGFloat = 0.18
    /// 메트릭 그룹 박스 모서리 반경.
    static let summaryMetricGroupCornerRadius: CGFloat = 12
    /// 메트릭 그룹 박스 좌우 안쪽 여백(leftX 기준 바깥쪽 패딩).
    static let summaryMetricGroupPadding: CGFloat = 8
    /// 메트릭 그룹 박스 상/하 세로 패딩(첫 제목 위·마지막 값 아래).
    static let summaryMetricGroupVerticalPadding: CGFloat = 8
    /// 메트릭 행 구분선 색 투명도(navyMuted 기반).
    static let summaryMetricDividerAlpha: CGFloat = 0.22
    /// 메트릭 행 구분선 두께.
    static let summaryMetricDividerLineWidth: CGFloat = 0.8
    /// statusChip 코랄 채움 투명도(v2 톤).
    static let summaryStatusChipFillAlpha: CGFloat = 0.92
    /// ProfileDetail 아바타 옵션 선택 코랄 패드 투명도(v2 톤 — 부드러운 코랄 배경).
    /// 기존 `profileDetailAvatarOptionSelectedFillAlpha`(0.88)는 레거시 크림슨용 값이라 보존하고,
    /// 코랄 v2 선택 패드는 더 가벼운 별도 투명도로 분리한다.
    static let profileDetailAvatarOptionSelectedCoralFillAlpha: CGFloat = 0.22

    // MARK: - Sprint 3 · v2 Game Visual
    // DESIGN_RENEWAL_REQUEST.md §4.4 + mockups/game-map-v2.html.
    // 본 섹션은 *추가만* — 기존 hudValueFontSize / comboPopupFontSize / hudLabelFontSize 등
    // Phase 8-5 / 6-10 / 6-12 상수는 *유지*. v2 상수가 별도 이름으로 공존.

    // HUD 슬롯 칩 (Sprint 3)
    /// HUD 슬롯 navy 알약 배경 알파.
    static let hudSlotBgAlpha: CGFloat = 0.78
    /// HUD 슬롯 알약 cornerRadius(pt).
    static let hudSlotCornerRadius: CGFloat = 14
    /// HUD 슬롯 폭(pt).
    static let hudSlotWidth: CGFloat = 78
    /// HUD 슬롯 높이(pt).
    static let hudSlotHeight: CGFloat = 44
    /// HUD 슬롯 v2 라벨 폰트 크기(pt). 기존 hudLabelFontSize(10)와 동일 수치이지만 분리.
    static let hudSlotLabelFontSize: CGFloat = 10
    /// HUD 슬롯 v2 값 폰트 크기(pt). 기존 hudValueFontSize(22)에서 18로 축소(v2 톤).
    static let hudSlotValueFontSize: CGFloat = 18
    /// TIME 슬롯 12초(또는 tensionWindow) 이하 진입 시 코랄 경고 배경 알파.
    static let hudSlotWarnBgAlpha: CGFloat = 0.85
    /// TIME 슬롯 진행바 두께(pt).
    static let hudTimeBarHeight: CGFloat = 3
    /// TIME 슬롯 진행바와 값 사이 세로 간격(pt).
    static let hudTimeBarTopGap: CGFloat = 3
    /// TIME 슬롯 진행바 배경 알파(흰색 위).
    static let hudTimeBarBgAlpha: CGFloat = 0.18

    // D-Pad v2 (Sprint 3)
    /// 중앙 데드존 SKShapeNode 한 변 길이(pt).
    static let dpadCenterDeadzoneSize: CGFloat = 32
    /// 중앙 데드존 navy 알파.
    static let dpadCenterDeadzoneAlpha: CGFloat = 0.4
    /// 중앙 데드존 cornerRadius(pt).
    static let dpadCenterDeadzoneCornerRadius: CGFloat = 6
    /// D-Pad 4 버튼 white 채움 알파.
    static let dpadButtonFillAlpha: CGFloat = 0.75
    /// D-Pad 4 버튼 navy 외곽선 알파.
    static let dpadButtonStrokeAlpha: CGFloat = 0.25
    /// D-Pad 4 버튼 cornerRadius(pt).
    static let dpadButtonCornerRadius: CGFloat = 10
    /// D-Pad 4 버튼 외곽선 두께(pt).
    static let dpadButtonStrokeLineWidth: CGFloat = 2

    // Skill Button v2 (Sprint 3)
    /// 스킬 버튼 v2 반지름(pt). 기존 skillButtonRadius(32)에서 36으로 확대.
    static let skillButtonVisualRadius: CGFloat = 36
    /// 스킬 버튼 v2 외곽선 두께(pt).
    static let skillButtonStrokeWidth: CGFloat = 3
    /// 스킬 버튼 우상단 "B" 키 칩 본체로부터의 offset(pt).
    static let skillButtonKeyLabelOffset: CGFloat = 28
    /// 스킬 버튼 아래 스킬명 칩 y 오프셋(pt). 본체 아래쪽.
    static let skillButtonNameChipOffsetY: CGFloat = -52
    /// 스킬 버튼 키 라벨 텍스트.
    static let skillButtonKeyText: String = "B"
    /// 달리기 버튼 반지름. 스킬 버튼보다 살짝 작게 둬 보조 조작임을 드러낸다.
    static let runButtonRadius: CGFloat = 30
    /// 스킬 버튼 중심에서 달리기 버튼 중심까지의 가로 거리.
    static let runButtonGapFromSkill: CGFloat = 78
    /// 달리기 버튼 터치 반경. 원형 시각보다 조금 넓게 잡아 hold 입력을 안정화한다.
    static let runButtonTouchRadius: CGFloat = 42
    /// 달리기 버튼 중앙 텍스트.
    static let runButtonText: String = "RUN"
    /// 달리기 버튼 키 칩 텍스트.
    static let runButtonKeyText: String = "R"
    /// 달리기 버튼 외곽선 두께.
    static let runButtonStrokeWidth: CGFloat = 3
    /// 달리기 버튼 눌림 알파.
    static let runButtonPressedAlpha: CGFloat = 0.95
    /// 달리기 버튼 기본 알파.
    static let runButtonReleasedAlpha: CGFloat = 0.82

    // Pause Button v2 (Sprint 3 — 시각 placeholder)
    /// 일시정지 버튼 본체 한 변(pt).
    static let pauseButtonSize: CGFloat = 32
    /// 일시정지 버튼 cornerRadius(pt).
    static let pauseButtonCornerRadius: CGFloat = 10
    /// 일시정지 버튼 navy 배경 알파.
    static let pauseButtonBgAlpha: CGFloat = 0.78
    /// 일시정지 버튼 흰 || 두 줄 폭(pt).
    static let pauseButtonBarWidth: CGFloat = 4
    /// 일시정지 버튼 흰 || 두 줄 높이(pt).
    static let pauseButtonBarHeight: CGFloat = 14
    /// 일시정지 버튼 두 줄 사이 간격(pt).
    static let pauseButtonBarGap: CGFloat = 2
    /// 일시정지 버튼 우상단 우측 마진(pt). cameraNode 자식 좌표계 기준.
    static let pauseButtonMarginX: CGFloat = 28
    /// 일시정지 버튼 상단 마진(pt).
    static let pauseButtonMarginY: CGFloat = 18

    // Note v2 (Sprint 3)

    // Projectile v2 (Sprint 3)

    // ComboPopup / ComboBreak v2 (Sprint 3)
    /// ComboPopup v2 라벨 폰트 크기(pt). 기존 comboPopupFontSize(48)와 분리 — *새 상수 추가*만.
    static let comboPopupFontSize: CGFloat = 32
    /// ComboBreak v2 라벨 폰트 크기(pt). 기존 comboBreakFontSize(48)와 분리.
    static let comboBreakFontSize: CGFloat = 28
    /// ComboPopup/ComboBreak navy 외곽선 1pt 오프셋 두께(pt). 4방향 자식 4개로 시뮬레이션.
    static let comboPopupOutlineWidth: CGFloat = 1
    /// ComboPopup v2 회전 각도(degree).
    static let comboPopupRotationDegrees: CGFloat = -8

    // Outer Wall Border (Sprint 3)
    /// 외곽 보더 SKShapeNode 외곽선 두께(pt).
    static let outerWallBorderLineWidth: CGFloat = 3
    /// 외곽 보더 SKShapeNode cornerRadius(pt).
    static let outerWallBorderCornerRadius: CGFloat = 18

    // MARK: - Sprint 5 · ResultScene v2 Layout

    // ResultScene v2 카드 패널
    /// 결과 카드 v2 cornerRadius(pt). mockup border-radius: 22.
    static let resultCardCornerRadius: CGFloat = 22

    // ResultScene v2 라벨 오프셋
    /// 타이틀 폰트 크기(pt). mockup .title-game-over = 30.
    static let resultCardTitleFontSize: CGFloat = 30
    /// 점수 숫자 폰트 크기(pt). mockup .score-num = 64.
    static let resultScoreNumFontSize: CGFloat = 64
    /// divider 폭 비율(카드 폭 대비). mockup width: 60%.
    static let resultDividerWidthRatio: CGFloat = 0.6
    /// stat 값(PLAYS/TOTAL 숫자) 폰트 크기(pt). mockup .stat-num = 14.
    static let resultStatValueFontSize: CGFloat = 14
    /// stat 타이틀("PLAYS"/"TOTAL") 폰트 크기(pt). mockup .stats-row = 11.
    static let resultStatTitleFontSize: CGFloat = 11
    /// 공유 GlassPill 폭(pt).
    static let resultShareButtonWidth: CGFloat = 100
    /// 공유 GlassPill 높이(pt).
    static let resultShareButtonHeight: CGFloat = 36
    /// 공유 presenter 탐색 실패 시 ResultScene에 표시할 scene-local 토스트 문구.
    static let resultShareFailureToastText: String = "공유 시트를 열 수 없어요"
    /// 공유 실패 토스트 폰트 크기(pt).
    static let resultShareToastFontSize: CGFloat = 16
    /// 공유 실패 토스트의 공유 버튼 기준 y 오프셋(pt).
    static let resultShareToastOffsetY: CGFloat = 46
    /// 공유 실패 토스트 유지 시간(초).
    static let resultShareToastDuration: TimeInterval = 1.1
    /// 공유 실패 토스트 fade in/out 길이(초).
    static let resultShareToastFadeDuration: TimeInterval = 0.18
    /// iPad popover anchor non-zero rect 한 변 길이(pt).
    static let resultSharePopoverAnchorSize: CGFloat = 2
    /// 공유 이미지 캡처를 시도할 최소 view 한 변 길이(pt).
    static let resultShareImageMinimumSide: CGFloat = 1

    // ResultScene v2 sparkle 5발 좌표
    /// 신기록 시 카드 주변에 emit되는 SparkleEffectNode 5개의 (frame.midX, frame.midY) 기준 오프셋.
    /// mockup VARIANT B의 sparkle s1~s5 위치를 카드 중심 기준으로 환산.
    static let resultSparklePositions: [CGPoint] = [
        CGPoint(x: -150, y:  60),
        CGPoint(x:  130, y:  40),
        CGPoint(x: -110, y: -40),
        CGPoint(x:  140, y: -60),
        CGPoint(x: -180, y:   0)
    ]

    // MARK: - Adaptive Layout (Sprint 7+ · 디바이스 대응 · iPhone SE ~ Pro Max)
    /// 화면 하단 안전 마진 — safeArea.bottom 위에 추가로 띄울 여백.
    /// SceneSafeArea.insets(for:).bottom + adaptiveBottomMargin = 노드 y 최소값.
    static let adaptiveBottomMargin: CGFloat = 24
    /// 화면 상단 안전 마진 — safeArea.top 아래에 추가로 띄울 여백.
    static let adaptiveTopMargin: CGFloat = 16
    /// 화면 좌우 안전 마진(노치/Dynamic Island 영역 회피).
    /// Landscape에서 노치가 한쪽(또는 양쪽)을 침범 — 카드 spacing 계산의 입력값.
    static let adaptiveHorizontalMargin: CGFloat = 20
    /// ResultScene 두 버튼(공유/다시시작) — 화면 하단(safeArea.bottom) 기준 안쪽 거리.
    /// frame.minY + safe.bottom + resultButtonBottomInset = button.y.
    static let resultButtonBottomInset: CGFloat = 56

    // MARK: - Sprint 7 Phase D · ResultScene v3 + ScoreboardScene
    //
    // 결과창 시각 정보 5요소(♪·점수·SCORE 라벨·BEST 칩·캐릭터/난이도)가 같은 좌표 근처에
    // 몰리던 V2 문제를 해소. V3는 점수가 시각 주인공이 되도록 ♪를 24pt로 줄이고,
    // SCORE 라벨을 점수 아래로, BEST를 점수 우측 GlassPill로 분리하며, headerChip은
    // 타이틀 위로 끌어올린다. "📊 기록 보기" GlassPill 신규로 ScoreboardScene 진입.
    //
    // V2 상수는 *모두 보존* — bestLabel/scoreSubLabel/divider/playsValueLabel 등 노드 트리는
    // alpha=0 차단으로 살아 있고, 좌표 시프트만 V3 상수로 한다.

    // ResultScene V3 — 점수 좌측 ♪ 아이콘 (scoreLabel과 분리)
    /// scoreLabel("♪ 0")의 ♪를 제거 → 좌측 별도 라벨 24pt 부착. 점수가 시각 주인공.
    static let resultScoreNoteIconFontSize: CGFloat = 24
    /// scoreLabel.position.x 기준 ♪ 라벨 x 오프셋(좌측 -60). 점수 중심에서 살짝 좌측.
    static let resultScoreNoteIconOffsetX: CGFloat = -60

    // ResultScene V3 — BEST GlassPill (bestLabel 시각 대체)
    /// BEST GlassPill 폭(120pt). "🏆 BEST 999" / "★ NEW BEST!" 두 텍스트 모두 수용.
    static let resultBestPillWidth: CGFloat = 120
    /// BEST GlassPill 높이(28pt). 점수 옆에 nestled.
    static let resultBestPillHeight: CGFloat = 28
    static let resultBestPillTopGap: CGFloat = 48
    static let resultBestPillBottomGap: CGFloat = 18

    // ResultScene BEST pill 수직 리듬 (신규 / V11)

    // ResultScene BEST pill 우상단 재배치 (신규 / V12)
    /// BEST pill 중심 x를 rightColumnX에서 우측으로 미는 보정량(pt). 좌상단 headerChip과 대칭.
    /// accentLine(panelCenter.x 가로선)·goal 라벨(rightColumnX 정렬)과 시각 여유를 확보한다.
    static let resultBestPillTopOffsetX: CGFloat = 34
    /// BEST pill 중심 y를 topY에서 아래로 내리는 보정량(pt). accentLine 가로선과 시각 겹침을 피한다.
    /// 헤더 행과 거의 같은 높이이되 미세하게 아래로 떨어뜨려 가로선 위에 pill이 또렷이 얹힌다.
    static let resultBestPillTopBelowTop: CGFloat = 4

    // ResultScene V3 — headerChip · title · subtitle · accentLine 위로 올림

    // ResultScene V3 — SCORE 라벨 점수 아래로

    // ResultScene V3 — divider · stat 라벨 위로 끌어올림 (bestLabel V2 자리 채움)

    // ResultScene V3 — Scoreboard 진입 GlassPill ("📊 기록 보기")
    /// 기록 보기 GlassPill 폭(110pt). shareButton(100) + 미세 여유 — 본문 4글자.
    static let resultScoreboardButtonWidth: CGFloat = 110
    /// 기록 보기 GlassPill 텍스트. 이모지 + 한글 4자.
    static let resultScoreboardButtonText: String = "📊 기록 보기"
    static let resultMainButtonWidth: CGFloat = 96
    static let resultMainButtonText: String = "캐릭터 홈"

    // ResultScene V3 — BEST GlassPill 텍스트 분기
    /// 일반 분기 BEST 칩 텍스트 prefix("🏆 BEST"). 뒤에 ` \(bestScore)` 합성.
    static let resultBestPillTextNormal: String = "🏆 BEST"
    /// 신기록 분기 BEST 칩 텍스트("★ NEW BEST!").
    static let resultBestPillTextNew: String = "★ NEW BEST!"

    // ScoreboardScene — 15셀 매트릭스 기본
    /// 매트릭스 가로 셀 수(3 = 하/중/상).
    static let scoreboardMatrixColumnCount: Int = 3
    /// 매트릭스 세로 셀 수(5 = 5 캐릭터).
    static let scoreboardMatrixRowCount: Int = 5
    /// 셀 폭(80pt). 3자리 숫자 + 미세 여유.
    static let scoreboardCellWidth: CGFloat = 80
    /// 셀 높이(36pt). Jua 18pt + 패딩.
    static let scoreboardCellHeight: CGFloat = 36
    /// 셀 사이 가로/세로 간격(4pt). mockup grid-gap.
    static let scoreboardCellGap: CGFloat = 4
    /// 행 헤더 폭(60pt). mini face(32px) + 약칭(1자).
    static let scoreboardRowHeaderWidth: CGFloat = 60

    // ScoreboardScene — 셀 라벨 폰트
    /// 셀 점수 폰트 크기(Jua 18pt navy).
    static let scoreboardCellScoreFontSize: CGFloat = 18
    /// 빈 셀 "—" 폰트 크기(Gowun Dodum 14pt 회색).
    static let scoreboardCellEmptyFontSize: CGFloat = 14
    /// 빈 셀 텍스트("—" em dash).
    static let scoreboardCellEmptyText: String = "—"
    /// 빈 셀 alpha(0.4 — 회색 톤).
    static let scoreboardCellEmptyAlpha: CGFloat = 0.4

    // ScoreboardScene — 헤더 라벨
    /// 행 헤더 약칭(1자) 폰트 크기.
    static let scoreboardRowHeaderShortNameFontSize: CGFloat = 13

    // ScoreboardScene — ★ 마커
    /// ★ 텍스트.
    static let scoreboardStarMarkerText: String = "★"
    /// ★ 폰트 크기(12pt).
    static let scoreboardStarMarkerFontSize: CGFloat = 12
    /// ★ 셀 중심 기준 x 오프셋(+28pt — 셀 우상단).
    static let scoreboardStarMarkerOffsetX: CGFloat = 28
    /// ★ 셀 중심 기준 y 오프셋(+12pt — 셀 우상단).
    static let scoreboardStarMarkerOffsetY: CGFloat = 12

    // ScoreboardScene — 헤더 + stat + 백 버튼
    /// 타이틀 y 오프셋(+95pt — frame.midY 기준 위쪽).
    static let scoreboardTitleOffsetY: CGFloat = 95
    /// 타이틀 폰트 크기(Jua 30pt — 결과창 타이틀과 동급).
    static let scoreboardTitleFontSize: CGFloat = 30
    /// 부제 y 오프셋(+72pt).
    static let scoreboardSubtitleOffsetY: CGFloat = 72
    /// 부제 폰트 크기(Gowun Dodum 12pt).
    static let scoreboardSubtitleFontSize: CGFloat = 12
    /// 부제 텍스트.
    static let scoreboardSubtitleText: String = "캐릭터·난이도별 최고점수"
    /// 타이틀 텍스트.
    static let scoreboardTitleText: String = "기록 보기"
    /// AccentLine y 오프셋(+130pt — 타이틀 위쪽 강조).
    static let scoreboardAccentLineOffsetY: CGFloat = 130

    /// 백 버튼 GlassPill 폭(110pt).
    static let scoreboardBackButtonWidth: CGFloat = 110
    /// 백 버튼 GlassPill 높이(36pt).
    static let scoreboardBackButtonHeight: CGFloat = 36
    /// 백 버튼 텍스트("← 결과로").
    static let scoreboardBackButtonText: String = "← 결과로"
    /// 백 버튼 좌측 inset(safeArea 추가 +20pt).
    static let scoreboardBackButtonInsetX: CGFloat = 20
    /// 백 버튼 상단 inset(safeArea 추가 +32pt — 화면 상단에서 떨어뜨림).
    static let scoreboardBackButtonInsetY: CGFloat = 32

    /// 브레드크럼 DarkContextChip 우측 inset.
    static let scoreboardBreadcrumbInsetX: CGFloat = 20
    /// 브레드크럼 상단 inset.
    static let scoreboardBreadcrumbInsetY: CGFloat = 32
    /// 브레드크럼 라벨 텍스트.
    static let scoreboardBreadcrumbText: String = "캐릭터별 기록"

    /// stat 라벨 frame.midY 기준 y 오프셋(-150pt — 매트릭스 아래).
    static let scoreboardStatOffsetY: CGFloat = -150
    /// stat 라벨 폰트 크기(Gowun Dodum 12pt).
    static let scoreboardStatFontSize: CGFloat = 12

    // MARK: - Sprint 8 — Layout V4 (겹침 해소 + 카드 확대)
    //
    // Phase A — Scoreboard zone 분리(타이틀 zone / 매트릭스 zone / stat zone).
    // V3 상수(~40개)는 byte-identical 보존. V4 상수는 *덧셈/교체* 형태로만 사용.

    // Phase A — Scoreboard
    /// 타이틀 zone을 매트릭스 zone과 분리하기 위한 추가 상향 오프셋(+40pt).
    /// 타이틀·부제 y 좌표에 더해, 우상단 GlassPill·매트릭스 첫 행과의 0px 겹침 보장.
    static let scoreboardTitleYOffset: CGFloat = 40

    /// 열 헤더(하/중/상) ↔ 매트릭스 첫 데이터 행 사이 추가 gap(18pt).
    /// V3의 scoreboardCellGap(4pt)이 너무 좁아 헤더와 본문이 한 덩어리로 보이던 문제 해소.
    static let scoreboardHeaderRowGap: CGFloat = 18

    /// 데이터 행 사이 vertical pitch(38pt). 행 사이 호흡 확보.
    /// V3의 (cellHeight 36 + cellGap 4) = 40pt 대비 -2pt — 행 간격을 조금 좁혀 매트릭스 총 높이 감소.
    static let scoreboardCellPitchY: CGFloat = 38

    /// 열 헤더(하/중/상) 폰트 크기 V4(16pt). V3(15pt)에서 1pt 상향.
    /// 매트릭스 zone 헤더 시각 무게를 데이터 셀(18pt)과 균형화. cellWidth(80) 안에 안전.
    static let scoreboardColumnHeaderFontSize: CGFloat = 16

    // MARK: - Sprint 7 Phase F · Villain Visual V3
    //
    // 4종 빌런 시각 강화 V3 상수 묶음. **모든 좌표/크기는 부모 SKSpriteNode 중심(0,0) 기준**이며
    // zPosition은 부모 zPosition 5 기준의 *상대 오프셋*(0.1~0.4)이다.
    // 매직 넘버 0 원칙: setupVisualOverlay 함수 안에서는 본 상수만 참조.
    //
    // **Hitbox 보존 계약**: 본 상수는 *시각 자식 노드*에만 쓰인다.
    // physicsBody.size 인자는 기존 GameplayTuning.enemyWidth/Height 등을 그대로 사용 — *0줄 변경*.

    // ── EnemyNode (수간호사) — 외곽 헬로 + 차트 + 클립 ──────────────

    // ── ProfessorNode (이교수) — 청진기 mini disc + 튜브 ──────────

    // ── StoneGuardNode (석조무사) — 사각 갑옷 + 일자눈 ────────────

    // ── SergeantParkNode (박병장) — 신규 빌런 시각 시안 ───────────
    /// 박병장 시각 크기 기본 가로(16pt). EnemyNode/PlayerNode 패턴 동형 — pixelSpriteScale로 2배 확대.
    static let sergeantParkWidth: CGFloat  = 16
    /// 박병장 시각 크기 기본 세로(20pt).
    static let sergeantParkHeight: CGFloat = 20

    /// 발 밑 ellipse 그림자 크기(18×4pt).
    static let sergeantShadowSize = CGSize(width: 18, height: 4)
    /// 그림자 y 오프셋(-18pt) — 발 밑.
    static let sergeantShadowOffsetY: CGFloat = -18

    /// 군복 몸통 사각형 크기(18×14pt).
    static let sergeantBodySize = CGSize(width: 18, height: 14)
    /// 군복 몸통 y 오프셋(-6pt) — 머리 아래.
    static let sergeantBodyOffsetY: CGFloat = -6

    /// 살구색 얼굴 반지름(6pt).
    static let sergeantHeadRadius: CGFloat   = 6
    /// 얼굴 y 오프셋(+6pt) — 몸통 위.
    static let sergeantHeadOffsetY: CGFloat  = 6

    /// 항공 캡 크라운(둥근 모자 윗부분) 크기(16×6pt).
    static let sergeantCapCrownSize = CGSize(width: 16, height: 6)
    /// 캡 크라운 y 오프셋(+13pt) — 머리 위.
    static let sergeantCapCrownOffsetY: CGFloat = 13
    /// 캡 차양(앞창) 크기(18×2pt).
    static let sergeantCapVisorSize = CGSize(width: 18, height: 2)
    /// 캡 차양 y 오프셋(+9pt) — 크라운 아래, 얼굴 위.
    static let sergeantCapVisorOffsetY: CGFloat = 9

    /// 선글라스 가로 직사각형 크기(11×3pt) — 눈 영역 전체 덮음.
    static let sergeantSunglassesSize = CGSize(width: 11, height: 3)
    /// 선글라스 y 오프셋(+5pt) — 얼굴 중심 약간 위.
    static let sergeantSunglassesOffsetY: CGFloat = 5

    /// 우측 어깨 v자 chevron 개수(2개 — 병장 계급장).
    static let sergeantRankChevronCount: Int = 2
    /// chevron x 오프셋(+6pt) — 우측 어깨.
    static let sergeantRankOffsetX: CGFloat  = 6
    /// chevron y 오프셋(-1pt) — 몸통 위쪽 어깨 위치.
    static let sergeantRankOffsetY: CGFloat  = -1
    /// chevron 사이 y 간격(+3pt) — 2개가 위아래로 살짝 띄움.
    static let sergeantRankChevronGap: CGFloat = 3
    /// 단일 chevron(v자) 폭(5pt).
    static let sergeantChevronWidth: CGFloat = 5
    /// 단일 chevron 높이(2.5pt) — v자 꼭짓점 깊이.
    static let sergeantChevronHeight: CGFloat = 2.5
    /// chevron 선 굵기(1.0pt) — 골드 stroke.
    static let sergeantChevronLineWidth: CGFloat = 1.0

    // MARK: - Sprint 9 Phase D · Result V4 Spacing
    // V3 좌표(headerChip+115 / accentLine+148 / title+85 / subtitle+58 / score-2 / divider-78)는 위쪽 5단의
    // 시각 호흡이 6~28pt에 그쳐 답답했다. V4는 위 묶음 전체를 +20~30pt 끌어올려 각 행 사이 호흡 ≥ 24pt를 확보,
    // 동시에 score(+6) ↔ divider(-68) gap을 74pt로 키워 "정체성 정보(위)"와 "통계(아래)"를 두 묶음으로 분리한다.
    // V3 상수는 값 보존 — 다른 곳 참조 가능성 + 회귀 안전망.
    /// SCORE 라벨 y 오프셋 V4(+6). V3 -2 대비 +8pt 위 — divider와 74pt 이격해 위/아래 묶음 분리.
    static let resultScoreOffsetY: CGFloat = 6

    // MARK: - Design Sprint 1 Ingame Readability
    static let ingameObjectHaloAlpha: CGFloat = 0.28
    static let ingameObjectHaloLineWidth: CGFloat = 2
    static let ingamePressScale: CGFloat = 1.08
    static let ingamePressDuration: TimeInterval = 0.08
    static let ingamePressActionKey: String = "ingamePress"
    static let ingameHaloPulseActionKey: String = "ingameHaloPulse"
    static let hudSlotStrokeWidth: CGFloat = 2
    static let hudSlotStrokeAlpha: CGFloat = 0.7
    static let hudSlotShadowAlpha: CGFloat = 0.28
    static let hudSlotShadowOffsetX: CGFloat = 3
    static let hudSlotShadowOffsetY: CGFloat = -3
    static let dpadIconFontSize: CGFloat = 18
    static let dpadPressedFillAlpha: CGFloat = 0.95
    static let dpadReleasedScale: CGFloat = 1.0
    static let skillButtonInactiveStrokeAlpha: CGFloat = 0.35
    static let hudSkillSlotCooldownMinAlpha: CGFloat = 0.35
    static let hudSkillSlotUsedAlpha: CGFloat = 0.2
    static let wallTileHighlightHeight: CGFloat = 5
    static let wallTileShadowHeight: CGFloat = 4
    static let ingameWallStrokeWidth: CGFloat = 2
    static let hospitalPropLineWidth: CGFloat = 1.2
    static let hospitalPropCornerRadius: CGFloat = 4
    static let hospitalPropSoftAlpha: CGFloat = 0.82
    static let hospitalBedWidth: CGFloat = 72
    static let hospitalBedHeight: CGFloat = 42
    static let hospitalCurtainWidth: CGFloat = 58
    static let hospitalCurtainHeight: CGFloat = 48
    static let hospitalCabinetWidth: CGFloat = 38
    static let hospitalCabinetHeight: CGFloat = 46
    static let hospitalCartWidth: CGFloat = 44
    static let hospitalCartHeight: CGFloat = 36
    static let hospitalPropPlacements: [(kind: HospitalPropKind, col: Int, row: Int)] = [
        (.bed, 4, 16),
        (.curtain, 7, 16),
        (.cabinet, 27, 16),
        (.cart, 24, 16),
        (.bed, 4, 3),
        (.curtain, 7, 3),
        (.cabinet, 27, 3),
        (.cart, 24, 3)
    ]
    static func hospitalPropSize(for kind: HospitalPropKind) -> CGSize {
        switch kind {
        case .bed:
            return CGSize(width: hospitalBedWidth, height: hospitalBedHeight)
        case .curtain:
            return CGSize(width: hospitalCurtainWidth, height: hospitalCurtainHeight)
        case .cabinet:
            return CGSize(width: hospitalCabinetWidth, height: hospitalCabinetHeight)
        case .cart:
            return CGSize(width: hospitalCartWidth, height: hospitalCartHeight)
        }
    }
    static let hospitalBedPillowWidthRatio: CGFloat = 0.34
    static let hospitalBedPillowHeightRatio: CGFloat = 0.38
    static let hospitalBedPillowOffsetXRatio: CGFloat = 0.24
    static let hospitalBedPillowOffsetYRatio: CGFloat = 0.16
    static let hospitalBedBlanketWidthRatio: CGFloat = 0.52
    static let hospitalBedBlanketHeightRatio: CGFloat = 0.72
    static let hospitalBedBlanketOffsetXRatio: CGFloat = 0.16
    static let hospitalBedBlanketOffsetYRatio: CGFloat = 0.04
    static let hospitalCurtainRailHeight: CGFloat = 4
    static let hospitalCurtainStripeCount: Int = 4
    static let hospitalCabinetDrawerCount: Int = 2
    static let hospitalCabinetDrawerWidthRatio: CGFloat = 0.74
    static let hospitalCabinetDrawerHeightRatio: CGFloat = 0.62
    static let hospitalCartTrayHeightRatio: CGFloat = 0.42
    static let hospitalCartTrayOffsetYRatio: CGFloat = 0.18
    static let hospitalCartLegHeightRatio: CGFloat = 0.44
    static let hospitalCartLegWidth: CGFloat = 3
    static let hospitalCartLegOffsetXRatio: CGFloat = 0.28
    static let hospitalCartLegOffsetYRatio: CGFloat = 0.16
    static let hospitalCartWheelRadius: CGFloat = 3
    static let noteReadableHaloRadius: CGFloat = 18
    static let noteReadableHaloAlpha: CGFloat = 0.32
    static let noteReadableSparkleRadius: CGFloat = 2
    static let noteReadableSparkleOffsetRatio: CGFloat = 0.45
    static let noteBobActionKey: String = "noteBob"
    static let noteLifetimeActionKey: String = "noteLifetime"
    /// R2 — 수집 팝(1.15배 후 소멸) SKAction 키. withKey 멱등.
    static let noteCollectPopActionKey: String = "noteCollectPop"
    static let projectileDangerHaloRadius: CGFloat = 18
    static let projectileDangerHaloAlpha: CGFloat = 0.32
    static let projectileOutlineWidth: CGFloat = 2
    static let stethoscopeReadableHaloRadius: CGFloat = 19
    static let stethoscopeReadableHaloAlpha: CGFloat = 0.26
    static let toiletBonusRingRadius: CGFloat = 16
    static let toiletBonusRingLineWidth: CGFloat = 2
    static let toiletBonusPulseAlpha: CGFloat = 0.45
    static let toiletBonusPulseHalfDuration: TimeInterval = 0.45
    static let toiletBonusPulseActionKey: String = "toiletBonusPulse"
    static let toiletLifetimeActionKey: String = "GameplayTuning.toiletLifetime"
    static let ingameHalfAlphaMultiplier: CGFloat = 0.5
    static let dpadUpIconText: String = "^"
    static let dpadDownIconText: String = "v"
    static let dpadLeftIconText: String = "<"
    static let dpadRightIconText: String = ">"

    // MARK: - Sprint 10.6 · Result Visual Hierarchy V10
    /// divider alpha V10(0.7). stat 묶음 시각 일관성 — fillColor가 navyDeep*0.18이라 0.7 곱하면 ≈0.126.
    static let resultDividerAlpha: CGFloat = 0.7

    // MARK: - 4-Bug Fix Sprint · V11 Layout Constants
    // 기존 상수(V4/V9/V10) 보존 — 호출부 교체만.

    /// ResultScene titleLabel y 오프셋 V11(+90pt). V4=100 → -10pt 내려 scoreLabel 상단과 간격 확보.
    /// 기존 resultTitleOffsetYV4(100)는 값 보존.
    static let resultTitleOffsetY: CGFloat = 90

    // MARK: - Sprint 10.7 · CharacterSelect Hero Carousel V12
    static let characterSwipeCardScaleCenter: CGFloat = 1.14
    static let characterSwipeCardScaleSide: CGFloat = 0.72
    static let characterSwipeCardAlphaSide: CGFloat = 0.24

    // MARK: - Sprint 2 Character Account Home
    static let characterHomeAppleFallbackNameText: String = "Apple 플레이어"
    static let characterHomeGuestNameText: String = "게스트 플레이어"
    static let characterHomeLocalNameText: String = "로컬 플레이어"
    static let characterHomeAppleProfileSubText: String = "Apple 계정으로 기록을 이어가요"
    static let characterHomeGuestProfileSubText: String = "이 기기 안에 기록이 저장돼요"
    static let characterHomeLocalProfileSubText: String = "로컬 기록으로 바로 플레이 가능"
    static let characterHomeAchievedText: String = "달성"
    static let characterHomeLockedText: String = "잠김"
    static let characterHomeUnlockedText: String = "해금됨"
    static let characterHomeUnlockRequirementSuffix: String = "25점 달성 후 해금"
    static let characterHomeLockedStartFeedbackText: String = "아직 시작할 수 없어요"
    static let characterHomePlayCountLabelText: String = "플레이"
    static let characterHomeBestScoreLabelText: String = "최고점"
    static let characterHomeTotalScoreLabelText: String = "누적점수"
    static let characterHomePointSuffixText: String = "점"
    static let characterHomePlaySuffixText: String = "회"


    static let characterHomePanelBodyFontSize: CGFloat = 12
    static let characterHomeMenuFontSize: CGFloat = 13

    static let characterHomePanelLineWidth: CGFloat = 1.2
    static let characterHomePanelFillAlpha: CGFloat = 0.74
    static let characterHomePanelStrokeAlpha: CGFloat = 0.34
    static let characterHomePanelFocusedStrokeAlpha: CGFloat = 0.42
    static let characterHomePortraitBreathScale: CGFloat = 1.025
    static let characterHomePortraitBreathDuration: TimeInterval = 1.2
    static let characterHomeLockedPortraitAlpha: CGFloat = 0.48
    static let characterHomePortraitBreathActionKey: String = "characterHomePortraitBreath"

    static let characterHomeSwipeThreshold: CGFloat = 44
    static let characterHomeDefaultIndex: Int = 0

    // MARK: - Sprint V6 — ResultScene + ScoreboardScene 호흡 정리
    //
    // ScoreboardScene: 부제(midY+112)와 매트릭스 열 헤더(midY+110) 겹침 해소를 위해
    //   매트릭스 zone을 -30pt 시프트하고, 행 헤더 미니 얼굴↔약칭 간격(22→32pt) 및
    //   매트릭스↔stat gap(24→40pt)을 확대해 빽빽함을 해소한다.
    // ResultScene: "SCORE" 캡션(scoreSubLabel) 시각 차단 + PLAYS/TOTAL 4라벨 alpha 회복(0.45→0.75)
    //   + divider y 추가 하강(-68→-80) + 하단 3버튼 X 간격 확대로 군더더기 정리.
    // 기존 V3/V4/V10/V11 토큰은 *값 byte-identical 보존* — 사용처(scene 본문)만 V6 토큰 참조로 교체.

    // --- ScoreboardScene V6 ---
    /// V6 — 매트릭스 zone -30pt 시프트. 부제(midY+112)와 열 헤더(midY+110) 겹침 해소.
    /// V3 scoreboardMatrixOffsetY(+10)는 byte-identical 보존.
    static let scoreboardMatrixOffsetY: CGFloat = -20

    /// V6 — 행 헤더 미니 얼굴↔약칭 X 거리. V3 22pt → 32pt. face=-16, name=+16.
    /// V3 scoreboardRowHeaderShortNameOffsetX(22pt) byte-identical 보존.
    static let scoreboardRowHeaderShortNameOffsetX: CGFloat = 32

    /// V6 — 매트릭스 마지막 행 ↔ stat 라벨 거리. V4 24pt → 40pt.
    /// V4 scoreboardStatBottomGapV4(24pt) byte-identical 보존.
    static let scoreboardStatBottomGap: CGFloat = 40

    // --- ResultScene V6 ---
    /// V6 — PLAYS/TOTAL stat 4라벨 alpha. V10(0.45) → V6(0.75) 명료성 회복.
    /// V10 resultStatAlphaV10(0.45) byte-identical 보존.
    static let resultStatAlpha: CGFloat = 0.75
}

// MARK: - R3 디자인 시스템 v3 "Night Shift" (03_UI §4·§5)
//
// 간격 스케일 + 형태 메트릭. 기존 v2 상수 무변경 — v3 토큰은 *추가만* (R3 합격 게이트).
// 신규 Pixel 컴포넌트(Nodes/UI/)는 이 토큰만 사용 — 매직 넘버 0.
extension UILayout {
    /// 간격 스케일 7단 — 4pt 그리드 (03_UI §4).
    enum Space {
        static let s4: CGFloat = 4
        static let s8: CGFloat = 8
        static let s12: CGFloat = 12
        static let s16: CGFloat = 16
        static let s24: CGFloat = 24
        static let s32: CGFloat = 32
        static let s48: CGFloat = 48
    }

    // MARK: v3 형태 메트릭 (03_UI §4)
    /// 기본 보더 두께 (line500). 강조 시 액센트색 — 두께는 동일.
    static let v3BorderWidth: CGFloat = 2
    /// 하드섀도 오프셋 — 우하단 (x+0, y-3) 단색 Deep 계열, 블러 0.
    static let v3HardShadowOffset: CGVector = CGVector(dx: 0, dy: -3)
    /// 패널 코너 반경 — 픽셀 컨셉 직각 기본, *패널만* 4pt 라운드 허용.
    static let v3PanelCornerRadius: CGFloat = 4
    /// 최소 터치 영역 한 변 (시각 높이가 작아도 히트 영역 확장).
    static let v3MinTouchSide: CGFloat = 44
    /// 화면 가장자리 여백 (+safe area).
    static let v3ScreenEdgeInset: CGFloat = 24
    /// 요소 간 최소 간격.
    static let v3MinElementGap: CGFloat = 12

    // MARK: v3 버튼 (03_UI §5 PixelButtonNode)
    /// 눌림 시 콘텐츠 y 하강 거리 (pt). 섀도는 고정 — 시각 오프셋 3→1 자동 성립.
    static let v3ButtonPressOffsetY: CGFloat = 2
    /// 눌림 시 섀도 시각 오프셋 (pt) = |하드섀도 y(-3)| − 눌림 하강(2).
    static let v3ButtonPressedShadowGap: CGFloat = 1

    // MARK: v3 진행바 (03_UI §5 PixelProgressBarNode)
    /// 세그먼트 블록 폭 (px).
    static let v3ProgressSegmentWidth: CGFloat = 8
    /// 세그먼트 간격 (px).
    static let v3ProgressSegmentGap: CGFloat = 1

    // MARK: v3 카드 (03_UI §5 PixelCardNode)
    /// 선택 시 카드 확대 배율 (easeOutBack 0.18s — FeelTuning.Motion.cardSelect).
    static let v3CardSelectedScale: CGFloat = 1.04

    // MARK: v3 다이얼로그 (03_UI §5 PixelDialogNode)
    /// 풀스크린 딤 alpha (ink900).
    static let v3DialogDimAlpha: CGFloat = 0.6

    // MARK: v3 칩 (설계서 외 보조 수치 — SPEC 주의사항 9 재량)
    /// 칩 높이 (caption 13pt + 상하 여백).
    static let v3ChipHeight: CGFloat = 24
    /// 칩 좌우 패딩 (Space.s8과 동치 — 의미 분리 토큰).
    static let v3ChipPaddingX: CGFloat = 8
    /// 칩 아이콘 슬롯 ↔ 텍스트 간격.
    static let v3ChipIconGap: CGFloat = 4

    // MARK: v3 픽셀 디졸브 (03_UI §9 — SceneRouter intoGame)
    /// 디졸브 체커 블록 한 변 (pt) — "8px 블록 체커 페이드".
    static let v3DissolveBlockSide: CGFloat = 8

    // MARK: v3 공통 배경 (03_UI §4 NightShiftBackdropNode)
    /// 스타필드 점 개수.
    static let v3BackdropStarCount: Int = 40
    /// 스타필드 점 한 변 (px).
    static let v3BackdropStarSide: CGFloat = 2
    /// 하단 심전도 라인 alpha (mint).
    static let v3BackdropEKGAlpha: CGFloat = 0.12
    /// 심전도 라인의 화면 하단으로부터의 y 오프셋 (pt) — 보조 수치 재량.
    static let v3BackdropEKGBottomOffset: CGFloat = 56
    /// 심전도 라인 두께 (px) — 픽셀 톤 2px 통일.
    static let v3BackdropEKGLineWidth: CGFloat = 2
}
