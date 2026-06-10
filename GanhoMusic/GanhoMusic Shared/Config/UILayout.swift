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
    static let startSceneAvatarCompactScale: CGFloat = 0.82
    static let difficultyCompactWidthThreshold: CGFloat = 860
    static let difficultyCompactScale: CGFloat = 0.82
    static let resultPanelHorizontalPadding: CGFloat = 48
    static let resultPanelCompactScale: CGFloat = 0.86
    static let primaryButtonTextHorizontalPadding: CGFloat = 36
    static let primaryButtonArrowReservedWidth: CGFloat = 48
    static let startSceneAvatarReservedWidth: CGFloat = 300
    static let startSceneCompactTitleOffsetY: CGFloat = 36
    static let startSceneMinTitleAvatarGap: CGFloat = 28
    static let difficultySelectColumnMinGap: CGFloat = 24
    static let difficultySelectMinimumLayoutScale: CGFloat = 0.72
    static let skillExplanationMinimumLayoutScale: CGFloat = 0.74
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

    // MARK: - Character Card (Phase 5-1)
    /// 선택되지 않은 카드 알파. 선택 카드(1.0)와 시각 대비.
    static let characterCardDeselectedAlpha: CGFloat = 0.5
    /// Phase 5-5 — 선택된 카드 확대 배율. 1.0 기본에서 1.08배. 인접 카드 spacing(10pt)와 검증:
    /// 48 × 1.08 = 51.84 → 측면 +1.92 → 갭 8.08pt 유지(겹침 없음).
    static let characterCardSelectedScale: CGFloat = 1.08
    /// Phase 5-5 — 선택/해제 시 scale 보간 시간 (초). 탭 응답성 고려 짧게.
    /// promptLabel 깜빡임(0.6)과 달리 1회 트랜지션 — repeatForever 아님.
    static let characterCardScaleDuration: TimeInterval = 0.10

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
    /// 게임 톤 소개 본문 — 스토리 박스 본문. GDD §1·§3 정착 텍스트.
    /// 호출부 리터럴 노출 금지 — 단일 진실 원천.
    static let startSceneStoryText: String =
        "실습 중 마음에 떠오른 멜로디를 45초 안에 모아 보세요. 수간호사 눈을 피하는 게 핵심."
    /// 부제 라벨 폰트 크기 (pt). titleFontSize(36)과 titlePromptFontSize(18) 사이.
    static let startSceneSubtitleFontSize: CGFloat = 16
    /// 부제 라벨 y 오프셋. titleLabelOffsetY(120) 바로 아래에 위치.
    static let startSceneSubtitleOffsetY: CGFloat = 80
    /// 상단 BEST/PLAYS 라인 y 오프셋. 패널 위쪽 상단 라인.
    static let startSceneBestPlaysTopMargin: CGFloat = 180
    /// BEST/PLAYS 라벨 좌우 간격 (pt). frame.midX 기준 ±값으로 가로 2개 배치.
    static let startSceneBestPlaysSpacing: CGFloat = 80
    /// 스토리 박스 y 오프셋. 패널 정중앙(부제 아래/난이도 위).
    static let startSceneStoryBoxOffsetY: CGFloat = 0
    /// 시작 버튼 y 오프셋. 패널 하단(난이도 카드 +80 아래쪽으로 충분히 떨어진 위치).
    static let startSceneStartButtonOffsetY: CGFloat = -180

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

    // MARK: - Character Select Scene (Phase 10-1b)
    /// 화면 헤더 텍스트 — "함께할 친구를 골라요". 호출부 리터럴 노출 금지.
    static let characterSelectHeaderText: String = "함께할 친구를 골라요"
    /// 헤더 폰트 크기 (pt). titleFontSize(36)보다 작음 — 부분 화면 헤더 톤.
    static let characterSelectHeaderFontSize: CGFloat = 22
    /// 헤더 y 오프셋. 패널 상단 부근.
    /// Sprint 10.6 — V10 도입으로 본 씬 미사용. 회귀 안전망으로 값 보존(170).
    static let characterSelectHeaderOffsetY: CGFloat = 170
    /// 캐릭터 카드 행 y 오프셋. 헤더 아래 적당한 간격.
    static let characterSelectCardOffsetY: CGFloat = 30
    /// 태그 라벨 폰트 크기 (pt). characterCardWidth(48) 안에 1~5자 작은 태그.
    static let characterSelectTagFontSize: CGFloat = 10
    /// 태그 라벨 y 오프셋 (카드 *외부*, 카드 위치 기준). 카드 아래쪽 -45pt.
    static let characterSelectTagOffsetY: CGFloat = -60
    /// 버튼 행 y 오프셋. 카드 아래 충분한 간격.
    static let characterSelectButtonRowOffsetY: CGFloat = -160
    /// 두 버튼 좌우 간격 (pt). frame.midX 기준 ±(spacing/2).
    static let characterSelectButtonSpacing: CGFloat = 200

    // MARK: - Skill Explanation Scene (Phase 10-1c)
    /// 화면 헤더 텍스트 — "스킬을 익혀요". 호출부 리터럴 노출 금지.
    static let skillExplanationHeaderText: String = "스킬을 익혀요"
    /// 헤더 폰트 크기 (pt). characterSelectHeaderFontSize(22)와 동급 — 시각 일관성.
    static let skillExplanationHeaderFontSize: CGFloat = 22
    /// 헤더 y 오프셋.
    static let skillExplanationHeaderOffsetY: CGFloat = 140
    /// 큰 아바타 가로 (pt). PixelSpriteRenderer 16×20 픽셀 텍스처를 7.5배 확대 표현.
    static let skillExplanationAvatarWidth: CGFloat = 120
    /// 큰 아바타 세로 (pt). 픽셀 비율 유지(16:20 ≈ 4:5).
    static let skillExplanationAvatarHeight: CGFloat = 150
    /// 아바타 x 오프셋. frame.midX 기준 왼쪽.
    static let skillExplanationAvatarOffsetX: CGFloat = -160
    /// 아바타 y 오프셋. 화면 중앙 살짝 위.
    static let skillExplanationAvatarOffsetY: CGFloat = 20
    /// 스킬명 라벨 폰트 크기 (pt). 큰 강조 — *주인공* 정보.
    static let skillExplanationSkillNameFontSize: CGFloat = 28
    /// 스킬명 x 오프셋. 아바타 옆 오른쪽 영역.
    static let skillExplanationSkillNameOffsetX: CGFloat = 80
    /// 스킬 설명 박스 x 오프셋. 스킬명과 동일 — 우측 정렬.
    static let skillExplanationStoryBoxOffsetX: CGFloat = 80
    /// 스킬 설명 박스 y 오프셋. 스킬명 아래.
    static let skillExplanationStoryBoxOffsetY: CGFloat = 0
    /// 버튼 행 y 오프셋. 패널 하단.
    static let skillExplanationButtonRowOffsetY: CGFloat = -160

    // MARK: - Start Scene Visual (Phase 10-2 · 병동의 새벽 톤)

    /// 음표 파티클 동시 표시 상한. 성능 가드.
    static let musicNoteEmitterMaxConcurrent: Int = 15
    /// 음표 스폰 주기 (초). 너무 잦으면 산만, 너무 적으면 휑함.
    static let musicNoteEmitterSpawnInterval: TimeInterval = 0.5
    /// 음표 글리프 폰트 크기 (pt). 살짝 큰 18pt — 시각 인지성 + 우아함.
    static let musicNoteEmitterFontSize: CGFloat = 18
    /// 음표 한 개가 화면 하단 → 상단 통과까지 걸리는 시간 (초). 8s — 느릿한 부유감.
    static let musicNoteEmitterRiseDuration: TimeInterval = 8.0
    /// 음표 fade-in 시간 (초).
    static let musicNoteEmitterFadeInDuration: TimeInterval = 0.5
    /// 음표 fade-out 시간 (초). 상승 종료 직전.
    static let musicNoteEmitterFadeOutDuration: TimeInterval = 1.0
    /// 음표 최대 알파. 0.7 — 배경 위에 *떠 있는* 톤.
    static let musicNoteEmitterMaxAlpha: CGFloat = 0.7
    /// 음표 초기 y 위치 (씬 하단 기준 offset, pt). 화면 아래에서 시작해 자연스럽게 등장.
    static let musicNoteEmitterStartYOffset: CGFloat = -20
    /// 음표 상승 종료 y 마진 (씬 상단 위로 추가 이동량, pt).
    static let musicNoteEmitterRiseEndYMargin: CGFloat = 40
    /// 음표 좌우 흔들림 범위 (절대값, pt). 자연스러운 부유 표현.
    static let musicNoteEmitterDriftRange: CGFloat = 30

    /// 제목 글로우 SKEffectNode CIGaussianBlur 반경 (pt).
    static let titleGlowBlurRadius: CGFloat = 8.0

    /// 난이도 카드 선택 시 spring overshoot scale. 1.12 → settle 1.08.
    static let difficultyCardSpringOvershootScale: CGFloat = 1.12
    /// spring phase 1 (overshoot)까지 걸리는 시간 (초). easeOut.
    static let difficultyCardSpringPhase1Duration: TimeInterval = 0.18
    /// spring phase 2 (settle)까지 걸리는 시간 (초). easeInEaseOut.
    static let difficultyCardSpringPhase2Duration: TimeInterval = 0.12

    /// 난이도 카드 살구 링 글로우 패딩 (pt). 카드 외곽보다 살짝 큰 capsule.
    static let difficultyCardRingGlowPadding: CGFloat = 10
    /// 링 글로우 stroke 두께 (pt).
    static let difficultyCardRingGlowLineWidth: CGFloat = 2
    /// 링 글로우 glow 폭 (pt). SKShapeNode glowWidth.
    static let difficultyCardRingGlowWidth: CGFloat = 6
    /// 링 글로우 fade-in 시간 (초). 선택 시 자연스러운 빛 띄움.
    static let difficultyCardRingGlowFadeInDuration: TimeInterval = 0.2
    /// 링 글로우 fade-out 시간 (초). 해제 시 빠른 정리.
    static let difficultyCardRingGlowFadeOutDuration: TimeInterval = 0.1

    /// 시작 버튼 pulse 최소 scale. 호흡 들이마시는 톤.
    static let startButtonPulseScaleMin: CGFloat = 0.98
    /// 시작 버튼 pulse 최대 scale. 호흡 내쉬는 톤.
    static let startButtonPulseScaleMax: CGFloat = 1.02
    /// 시작 버튼 pulse 반주기 (초). 1.0초 × 2 = 2초 1주기 — 심호흡 리듬.
    static let startButtonPulseHalfDuration: TimeInterval = 1.0

    /// 씬 전환 시 카드/스토리/버튼 슬라이드업 거리 (pt). 살짝만 — 연결감 위주.
    static let startSceneExitSlideDistance: CGFloat = 30
    /// 슬라이드업 + fadeOut 지속시간 (초). presentScene 전 prelude.
    static let startSceneExitSlideDuration: TimeInterval = 0.2

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
    static let menuAmbientNotesEnabled: Bool = false
    static let menuControlFillAlpha: CGFloat = 0.94
    static let menuControlStrokeAlpha: CGFloat = 0.20
    static let menuControlLineWidth: CGFloat = 1
    static let menuControlShadowAlpha: CGFloat = 0
    static let menuControlArrowAlpha: CGFloat = 0.12
    static let menuControlEnabledAlpha: CGFloat = 1.0

    // MARK: - Sprint 2 · StartScene v2 Layout
    // DESIGN_RENEWAL_REQUEST.md §4.1 + mockups/main-screen-v2.html.
    // 본 섹션은 *추가만* — 기존 startScene* 상수(Phase 10-1a/10-2)는 미사용 상태가 되어도 *유지*.

    /// StartScene 타이틀 1행("김간호는") 폰트 크기(pt). §4.1 = 44pt navyDeep.
    static let startSceneTitleLine1FontSize: CGFloat = 44
    /// StartScene 타이틀 2행("음악박사 ♪") 폰트 크기(pt). §4.1 = 56pt coralPrimary.
    static let startSceneTitleLine2FontSize: CGFloat = 56
    /// StartScene 태그라인 폰트 크기(pt). Gowun Dodum body 톤.
    static let startSceneTaglineFontSize: CGFloat = 13
    /// StartScene 태그라인 자동 줄바꿈 폭(pt). preferredMaxLayoutWidth.
    static let startSceneTaglineMaxWidth: CGFloat = 240
    /// StartScene 타이틀 블록 우측 마진(pt). frame.maxX - margin이 우측 정렬 기준.
    static let startSceneTitleBlockRightMargin: CGFloat = 64
    /// StartScene 타이틀 블록 y 오프셋(pt). frame.midY + offset.
    static let startSceneTitleBlockOffsetY: CGFloat = 60
    /// StartScene 2행 사이 줄간 y 간격(pt). titleLine1 → titleLine2.
    static let startSceneTitleLineSpacing: CGFloat = 58
    /// StartScene AccentLine 타이틀 블록 위 y 오프셋(pt). 타이틀1 위 +24.
    static let startSceneAccentLineAboveTitleOffset: CGFloat = 36
    /// StartScene 태그라인 타이틀2 아래 y 오프셋(pt).
    static let startSceneTaglineBelowTitleOffset: CGFloat = -48

    /// StartScene BEST/PLAYS 알약 폭(pt). §4.1 = 96.
    static let startSceneStatPillWidth: CGFloat = 96
    /// StartScene BEST/PLAYS 알약 높이(pt).
    static let startSceneStatPillHeight: CGFloat = 28
    /// StartScene 알약 좌우 마진(pt). frame.minX/maxX 기준 안쪽 거리.
    static let startSceneStatPillSideMargin: CGFloat = 60
    /// StartScene 알약 상단 마진(pt). frame.maxY 기준 아래쪽 거리.
    static let startSceneStatPillTopMargin: CGFloat = 30
    static let startSceneAuthStatusPillWidth: CGFloat = 138
    static let startSceneAuthButtonPillWidth: CGFloat = 118
    static let startSceneAuthPillHeight: CGFloat = 28
    static let startSceneAuthPillGap: CGFloat = 10
    static let startSceneAuthAboveStartButton: CGFloat = 60
    static let startSceneAuthManagePillWidth: CGFloat = 70
    static let startSceneAccountChipWidth: CGFloat = 144
    static let startSceneAccountChipHeight: CGFloat = 30
    static let startSceneAccountChipRightInset: CGFloat = 36
    static let startSceneAccountChipTopInset: CGFloat = 34
    /// 시작 버튼을 기존 하단 안전영역 앵커에서 위로 올리는 양(pt). 아래에 들어갈 연동 caption(높이+gap)을 흡수한다.
    /// caption("Apple 연동됨")에 더 가깝게 붙도록 축소.
    static let startSceneStartButtonLift: CGFloat = 18
    /// "Apple 연동됨" plain 텍스트 폰트 크기(pt). 기존 pill 대비 작게 — 조용한 상태 표시.
    static let startSceneAuthCaptionFontSize: CGFloat = 13
    /// 시작 버튼 하단 ~ 연동 caption 중심 간격(pt). menuCompactScale 적용.
    static let startSceneAuthCaptionGap: CGFloat = 12
    /// 연동 caption 탭 히트 영역 패딩(pt). 작은 글자라 텍스트 bbox만으로는 탭이 좁아 inset으로 확장.
    static let startSceneAuthCaptionHitPadding: CGFloat = 10
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
    static let authStatusMessageActionKey: String = "authStatusMessage"

    // MARK: - Login Choice Overlay
    static let loginChoiceDimAlpha: CGFloat = 0.48
    static let loginChoicePanelFillAlpha: CGFloat = 0.92
    static let loginChoicePanelStrokeAlpha: CGFloat = 0.55
    static let loginChoicePanelWidth: CGFloat = 580
    static let loginChoicePanelCompactWidth: CGFloat = 492
    static let loginChoicePanelHeight: CGFloat = 338
    static let loginChoicePanelCornerRadius: CGFloat = 20
    static let loginChoicePanelLineWidth: CGFloat = 1
    static let loginChoiceTitleFontSize: CGFloat = 28
    static let loginChoiceBodyFontSize: CGFloat = 15
    static let loginChoiceStatusFontSize: CGFloat = 13
    static let loginChoiceBodyWidth: CGFloat = 292
    static let loginChoiceButtonWidth: CGFloat = 140
    static let loginChoiceCancelButtonWidth: CGFloat = 82
    static let loginChoiceButtonHeight: CGFloat = 32
    static let loginChoiceButtonGap: CGFloat = 12
    static let loginChoiceHeroFrameWidth: CGFloat = 164
    static let loginChoiceHeroFrameHeight: CGFloat = 204
    static let loginChoiceHeroFrameCornerRadius: CGFloat = 18
    static let loginChoiceHeroFrameOffsetX: CGFloat = -172
    static let loginChoiceHeroPortraitMaxSize = CGSize(width: 118, height: 172)
    static let loginChoiceHeroCaptionOffsetY: CGFloat = -124
    static let loginChoiceHeroCaptionFontSize: CGFloat = 13
    static let loginChoiceContentOffsetX: CGFloat = 94
    static let loginChoiceTitleOffsetY: CGFloat = 112
    static let loginChoiceBodyOffsetY: CGFloat = 72
    static let loginChoiceCardWidth: CGFloat = 286
    static let loginChoiceCardHeight: CGFloat = 58
    static let loginChoiceCardGap: CGFloat = 14
    static let loginChoiceCardCornerRadius: CGFloat = 14
    static let loginChoiceCardLineWidth: CGFloat = 1
    static let loginChoiceCardTitleFontSize: CGFloat = 17
    static let loginChoiceCardSubtitleFontSize: CGFloat = 12
    static let loginChoiceCardFirstOffsetY: CGFloat = 16
    static let loginChoiceCardTitleOffsetY: CGFloat = 10
    static let loginChoiceCardSubtitleOffsetY: CGFloat = -12
    static let loginChoiceCancelButtonOffsetY: CGFloat = -124
    static let loginChoiceStatusOffsetY: CGFloat = -150
    static let loginChoiceTitleText: String = "계정 접속"
    static let loginChoiceBodyText: String = "Apple 계정으로 기록을 붙잡거나, 게스트 기록으로 바로 병동에 들어갑니다."
    static let loginChoiceHeroCaptionText: String = "김간호 기본 프로필"
    static let loginChoiceGuestCardTitleText: String = "게스트 기록"
    static let loginChoiceGuestCardSubtitleText: String = "이 기기 안에서 바로 시작"
    static let loginChoiceAppleCardTitleText: String = "Apple 계정"
    static let loginChoiceAppleCardSubtitleText: String = "재실행해도 내 기록 유지"
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
    static let loginChoiceStatusMessageDuration: TimeInterval = 1.6
    static let loginChoiceStatusMessageActionKey: String = "loginChoiceStatusMessage"

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

    // MARK: - Sprint 2 · CharacterSelectScene v2 Layout
    // DESIGN_RENEWAL_REQUEST.md §4.2 + mockups/character-select-v2.html.

    /// 헤더 부제(Gowun Dodum) 폰트 크기(pt). §4.2 = 12pt navyMuted.
    static let characterSelectHeaderSubFontSize: CGFloat = 12
    /// 헤더 부제 텍스트.
    static let characterSelectHeaderSubText: String = "친구마다 다른 스킬과 이동속도를 가져요"
    /// 헤더 부제 y 오프셋(pt). headerLabel 아래 -22.
    /// Sprint 10.6 — V10 도입으로 본 씬 미사용. 회귀 안전망으로 값 보존(-22).
    static let characterSelectHeaderSubOffsetY: CGFloat = -22
    /// 헤더 AccentLine y 오프셋(pt). headerLabel 위 +24.
    /// Sprint 10.6 — V10 도입으로 본 씬 미사용. 회귀 안전망으로 값 보존(24).
    static let characterSelectAccentLineOffsetY: CGFloat = 24

    /// 뒤로 GlassPill 텍스트.
    /// Sprint 6 — 흐름 재편: 캐릭터 선택의 직전 단계가 StartScene(메인)으로 바뀜.
    /// 난이도 결정은 5단계 흐름의 *마지막*(DifficultySelectScene)으로 이동했으므로
    /// "← 난이도 다시"가 의미적으로 깨진다 — 텍스트만 "← 메인"으로 교체. 상수 이름 보존.
    static let characterSelectBackPillText: String = "← 메인"
    /// 뒤로 GlassPill 폭(pt).
    static let characterSelectBackPillWidth: CGFloat = 120
    /// 뒤로 GlassPill 높이(pt).
    static let characterSelectBackPillHeight: CGFloat = 28
    /// 난이도 칩 본 라벨 텍스트.
    static let characterSelectDifficultyChipLabel: String = "현재 난이도"
    /// Top bar 좌우 마진(pt). frame.minX/maxX 기준.
    static let characterSelectTopBarMarginX: CGFloat = 40
    /// Top bar 상단 마진(pt). frame.maxY 기준 아래쪽 거리.
    static let characterSelectTopBarMarginY: CGFloat = 30

    /// 카드 외곽 글래스 컨테이너 폭(pt). Sprint 7+ — 110 → 156 (카드 확대에 동기).
    /// characterCardWidth(76) + 좌우 inset 40 = 156. 카드 위 글래스 띠 두께 보존.
    static let characterCardGlassWidth: CGFloat = 156
    /// 카드 외곽 글래스 컨테이너 높이(pt). Sprint 7+ — 140 → 204 (카드 확대에 동기).
    /// characterCardHeight(104) + 상하 inset 100 = 204. 라벨/태그 공간 확보.
    static let characterCardGlassHeight: CGFloat = 204
    /// 카드 외곽 글래스 cornerRadius(pt).
    static let characterCardGlassCornerRadius: CGFloat = 18
    /// 카드 외곽 글래스 fill 알파(흰색).
    static let characterCardGlassFillAlpha: CGFloat = 0.65
    /// 카드 우상단 색 점 반지름(pt). §4.2 = 4 (지름 8).
    static let characterCardColorDotRadius: CGFloat = 4
    /// 카드 색 점 카드 외곽으로부터 우측 inset(pt).
    static let characterCardColorDotInsetX: CGFloat = 14
    /// 카드 색 점 카드 외곽으로부터 상단 inset(pt).
    static let characterCardColorDotInsetY: CGFloat = 14
    /// 카드 외곽 글래스 선택 시 scale.
    static let characterCardGlassSelectedScale: CGFloat = 1.08
    /// 카드 외곽 글래스 선택 시 y 오프셋(pt). 살짝 위로 떠오름.
    static let characterCardGlassSelectedYOffset: CGFloat = 12
    /// 카드 외곽 글래스 선택 시 stroke 두께(pt).
    static let characterCardGlassSelectedStrokeWidth: CGFloat = 2
    /// 카드 외곽 글래스 scale 액션 duration(초).
    static let characterCardGlassScaleDuration: TimeInterval = 0.18

    /// 하단 스킬 정보 칩 y 오프셋(pt). frame.midY 기준.
    static let characterSelectSkillInfoOffsetY: CGFloat = -100
    /// confirm 버튼 y 오프셋(pt). frame.midY 기준.
    static let characterSelectConfirmButtonOffsetY: CGFloat = -180

    // MARK: - Sprint 2 · SkillExplanationScene v2 Layout
    // DESIGN_RENEWAL_REQUEST.md §4.3 + mockups/skill-explanation-v2.html.

    /// 헤더 부제 텍스트.
    static let skillExplanationHeaderSubText: String = "한 번만 익히면 충분해요. 바로 시작할 수 있어요"
    /// 헤더 부제 폰트 크기(pt).
    static let skillExplanationHeaderSubFontSize: CGFloat = 12
    /// 헤더 AccentLine y 오프셋(pt). headerLabel 위 +24.
    static let skillExplanationAccentLineOffsetY: CGFloat = 24
    /// 헤더 부제 y 오프셋(pt). headerLabel 아래 -22.
    static let skillExplanationHeaderSubOffsetY: CGFloat = -22

    /// Top bar 뒤로 GlassPill 텍스트.
    static let skillExplanationBackPillText: String = "← 캐릭터 다시"
    /// Top bar 뒤로 GlassPill 폭(pt).
    static let skillExplanationBackPillWidth: CGFloat = 130
    /// Top bar 뒤로 GlassPill 높이(pt).
    static let skillExplanationBackPillHeight: CGFloat = 28
    /// Top bar 브레드크럼 칩 뱃지 텍스트("스킬").
    static let skillExplanationBreadcrumbBadge: String = "스킬"
    /// Top bar 좌우 마진(pt).
    static let skillExplanationTopBarMarginX: CGFloat = 40
    /// Top bar 상단 마진(pt).
    static let skillExplanationTopBarMarginY: CGFloat = 30

    /// 좌측 아바타 글래스 카드 폭(pt). §4.3 = 180.
    static let skillExplanationAvatarCardWidth: CGFloat = 180
    /// 좌측 아바타 글래스 카드 높이(pt).
    static let skillExplanationAvatarCardHeight: CGFloat = 200
    /// 좌측 아바타 글래스 카드 cornerRadius(pt).
    static let skillExplanationAvatarCardCornerRadius: CGFloat = 24
    /// 아바타 카드 fill 알파.
    static let skillExplanationAvatarCardFillAlpha: CGFloat = 0.85
    /// 아바타 카드 stroke 알파(코랄).
    static let skillExplanationAvatarCardStrokeAlpha: CGFloat = 0.3
    /// 아바타 카드 stroke 두께(pt).
    static let skillExplanationAvatarCardStrokeWidth: CGFloat = 2
    /// 아바타 카드 y 오프셋(pt). frame.midY 기준.
    static let skillExplanationAvatarCardOffsetY: CGFloat = 0
    /// 아바타 이름 뱃지(코랄 알약) y 오프셋(pt). 카드 안 상단.
    static let skillExplanationAvatarNameBadgeOffsetY: CGFloat = 90
    /// 아바타 이름 뱃지 폰트 크기(pt).
    static let skillExplanationAvatarNameBadgeFontSize: CGFloat = 12
    /// 아바타 이름 뱃지 폭(pt).
    static let skillExplanationAvatarNameBadgeWidth: CGFloat = 80
    /// 아바타 이름 뱃지 높이(pt).
    static let skillExplanationAvatarNameBadgeHeight: CGFloat = 24
    /// 아바타 role 라벨 y 오프셋(pt). 카드 아래.
    static let skillExplanationAvatarRoleOffsetY: CGFloat = -110
    /// 아바타 role 라벨 폰트 크기(pt).
    static let skillExplanationAvatarRoleFontSize: CGFloat = 11
    /// 아바타 속도 칩 y 오프셋(pt). role 아래.
    static let skillExplanationAvatarSpeedChipOffsetY: CGFloat = -130

    /// 우측 스킬명/스탯 칩 영역 x 오프셋(pt). frame.midX 기준 우측.
    static let skillExplanationMetaLabelOffsetX: CGFloat = 80

    /// 인용 박스 cornerRadius(pt).
    static let skillExplanationQuoteBoxCornerRadius: CGFloat = 14
    /// 인용 박스 fill 알파(흰색).
    static let skillExplanationQuoteBoxFillAlpha: CGFloat = 0.55
    /// 인용 박스 본문 폰트 크기(pt).
    static let skillExplanationQuoteBoxFontSize: CGFloat = 14
    /// 인용 박스 본문 좌우 패딩(pt). preferredMaxLayoutWidth = boxWidth - padding*2.
    static let skillExplanationQuoteBoxHorizontalPadding: CGFloat = 28

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

    // MARK: - Sprint 6 · 흐름 재편 + 캐릭터 얼굴 + 메인 캐릭터
    // SPRINT_6_REQUEST.md §2~3 + SPEC.md "기능 상세" 1~7.
    // 본 섹션은 *추가만* — 기존 상수 hex/값 0건 변경 (characterSelectBackPillText 1줄만 위에서 값 교체).
    // 흐름: Start → Character → (Skill) → Difficulty → Game. .kim은 Skill 스킵.

    // MARK: - NurseAvatarNode (StartScene 좌측 김간호 큰 그림)
    /// 김간호 큰 그림 전체 scale. mockup viewBox(-150 -160 300 360) 기준 width 240px 정도.
    /// 본 노드 내부 좌표는 SVG에서 그대로 코드화 → 외부에서 xScale/yScale로 최종 크기 미세 조정.
    static let nurseAvatarScale: CGFloat = 0.7
    /// StartScene에서 NurseAvatarNode 좌측 6% 위치 — frame.minX 기준 +offset.
    static let nurseAvatarOffsetX: CGFloat = 180
    /// StartScene에서 NurseAvatarNode 바닥 정렬 — frame.midY 기준 +offset(음수: 아래로).
    static let nurseAvatarOffsetY: CGFloat = -40
    /// 외곽선(stroke) 라인 두께. SVG `stroke-width="4"`를 그대로 옮긴 값.
    static let nurseAvatarOutlineWidth: CGFloat = 4
    /// 헤드폰 밴드 라인 두께. SVG `stroke-width="10"`.
    static let nurseAvatarHeadphoneBandWidth: CGFloat = 10
    /// 팔 라인 두께(피부톤). SVG `stroke-width="20"`.
    static let nurseAvatarArmWidth: CGFloat = 20

    // MARK: - CharacterFaceNode (CharacterSelectScene 5장 카드 위 얼굴)
    /// 카드 안에서 얼굴 차지 비율 — Sprint 7+ — 0.55 → 0.82 (카드 확대에 동기).
    /// 카드(76×104)와 글래스(156×204) 확대에 맞춰 얼굴도 키워 시인성 강화.
    static let characterFaceScale: CGFloat = 0.82
    /// 카드 중심에서 얼굴 y 오프셋 — 라벨(이름·태그)과 겹치지 않도록 +6~+10. (OPEN_QUESTION OQ-1)
    static let characterFaceOffsetYWithinCard: CGFloat = 8
    /// 얼굴 베이스 머리 타원 가로 반지름.
    static let characterFaceHeadRadiusX: CGFloat = 32
    /// 얼굴 베이스 머리 타원 세로 반지름.
    static let characterFaceHeadRadiusY: CGFloat = 34
    /// 얼굴 외곽선 두께. mockup `stroke-width="2.5"`.
    static let characterFaceOutlineWidth: CGFloat = 2.5
    /// 얼굴 부속(눈/입/볼) stroke 두께. mockup `stroke-width="2"~"3"` 평균.
    static let characterFaceDetailLineWidth: CGFloat = 2.5

    // MARK: - DifficultySelectScene (신규 5단계 흐름 마지막)
    /// 헤더 텍스트.
    static let difficultySelectHeaderText: String = "난이도를 골라요"
    /// 헤더 폰트 크기(pt). characterSelect/skillExplanation 헤더(22)와 동급 톤.
    static let difficultySelectHeaderFontSize: CGFloat = 26
    /// 헤더 y offset — frame.midY 기준.
    static let difficultySelectHeaderOffsetY: CGFloat = 140
    /// 헤더 부제 텍스트.
    static let difficultySelectHeaderSubText: String = "한 번만 정해두면 충분해요"
    /// 헤더 부제 폰트 크기(pt).
    static let difficultySelectHeaderSubFontSize: CGFloat = 12
    /// 헤더 부제 y offset — 헤더 라벨 기준.
    static let difficultySelectHeaderSubOffsetY: CGFloat = -22
    /// 헤더 위 AccentLine y offset.
    static let difficultySelectAccentLineOffsetY: CGFloat = 24

    // 백버튼 (스킬 다시 또는 캐릭터 다시 — characterID에 따라 분기)
    /// 스킬 보유 캐릭터(.jung/.geon/.im/.lee) 백버튼 텍스트.
    static let difficultySelectBackPillTextSkill: String = "← 스킬 다시"
    /// 김간호(.kim) 백버튼 텍스트 — 스킬 화면을 스킵했으므로 직전이 캐릭터 선택.
    static let difficultySelectBackPillTextCharacter: String = "← 캐릭터 다시"
    /// 백 GlassPill 폭.
    static let difficultySelectBackPillWidth: CGFloat = 130
    /// 백 GlassPill 높이.
    static let difficultySelectBackPillHeight: CGFloat = 28

    // 브레드크럼 칩
    /// 브레드크럼 칩 라벨 — 캐릭터 · 스킬 + [난이도] 뱃지.
    /// 김간호는 스킬 화면을 스킵했지만 시각 일관성을 위해 라벨 텍스트 그대로 유지.
    static let difficultySelectBreadcrumbLabel: String = "캐릭터 · 스킬"
    /// 브레드크럼 칩 뱃지 — 코랄 뱃지에 표시되는 "현재 위치".
    static let difficultySelectBreadcrumbBadge: String = "난이도"

    // 상단 바 margin
    static let difficultySelectTopBarMarginX: CGFloat = 40
    static let difficultySelectTopBarMarginY: CGFloat = 30

    // 좌측 캐릭터 요약 카드
    /// 좌측 요약 카드 폭(pt).
    static let difficultySelectSummaryCardWidth: CGFloat = 200
    /// 좌측 요약 카드 높이(pt).
    static let difficultySelectSummaryCardHeight: CGFloat = 260
    /// 좌측 요약 카드 cornerRadius(pt).
    static let difficultySelectSummaryCardCornerRadius: CGFloat = 22
    /// 좌측 요약 카드 배경 fill alpha(흰색).
    static let difficultySelectSummaryCardFillAlpha: CGFloat = 0.85
    /// 좌측 요약 카드 stroke alpha(코랄).
    static let difficultySelectSummaryCardStrokeAlpha: CGFloat = 0.3
    /// 좌측 요약 카드 stroke 두께.
    static let difficultySelectSummaryCardStrokeWidth: CGFloat = 2

    /// 요약 카드 안 이름 뱃지 폭(pt).
    static let difficultySelectSummaryNameBadgeWidth: CGFloat = 90
    /// 요약 카드 안 이름 뱃지 높이(pt).
    static let difficultySelectSummaryNameBadgeHeight: CGFloat = 24
    /// 요약 카드 안 이름 뱃지 폰트 크기(pt).
    static let difficultySelectSummaryNameBadgeFontSize: CGFloat = 12
    /// 요약 카드 중심에서 이름 뱃지 y offset(상단으로 +).
    static let difficultySelectSummaryNameBadgeOffsetY: CGFloat = 110
    /// 요약 카드 안 미니 아바타(CharacterFaceNode) scale.
    static let difficultySelectSummaryFaceScale: CGFloat = 0.65
    /// 요약 카드 중심에서 미니 아바타 y offset.
    static let difficultySelectSummaryFaceOffsetY: CGFloat = 30
    /// 요약 카드 안 스킬명 라벨 폰트 크기(pt).
    static let difficultySelectSummarySkillFontSize: CGFloat = 14
    /// 요약 카드 중심에서 스킬명 라벨 y offset(하단으로 -).
    static let difficultySelectSummarySkillOffsetY: CGFloat = -50
    /// 요약 카드 "스킬 없음" 라벨(김간호용).
    static let difficultySelectSummarySkillNoneText: String = "스킬 없음"
    /// 요약 카드 안 속도 칩 폭(pt).
    static let difficultySelectSummarySpeedChipWidth: CGFloat = 100
    /// 요약 카드 안 속도 칩 높이(pt).
    static let difficultySelectSummarySpeedChipHeight: CGFloat = 22
    /// 요약 카드 안 속도 칩 폰트 크기(pt).
    static let difficultySelectSummarySpeedChipFontSize: CGFloat = 11
    /// 요약 카드 안 속도 칩 fill alpha(민트 톤).
    static let difficultySelectSummarySpeedChipFillAlpha: CGFloat = 0.4
    /// 요약 카드 중심에서 속도 칩 y offset.
    static let difficultySelectSummarySpeedChipOffsetY: CGFloat = -80

    // 우측 난이도 3장
    /// 우측 난이도 3장 그룹의 중심 x offset(frame.midX 기준).
    static let difficultySelectDifficultyRowOffsetX: CGFloat = 110
    /// 우측 난이도 3장 그룹의 중심 y offset(frame.midY 기준).
    static let difficultySelectDifficultyRowOffsetY: CGFloat = -10

    // 시작 버튼
    /// 시작 버튼 텍스트.
    static let difficultySelectStartButtonText: String = "시작"

    // MARK: - Sprint 7 · 잘림 해소 + 카드 시인성 강화 (Visual-3)
    //
    // SafeArea 마운트(GameViewController)로 4개 메뉴 씬 가장자리 잘림 해소 +
    // DifficultyCardNode 1.4배 확장 + descriptionLabel 추가 + 미선택 시각 강화 +
    // CharacterSelectScene 카드 여백 확대 + 지그재그 y 오프셋.
    //
    // 모든 신규 상수는 `*V3` 접미사. 기존 상수는 값 변경 없음(다른 사용처 회귀 방지).

    // --- DifficultyCardNode v3 ---
    /// Sprint 7 — v3 카드 코너 반경(20pt). 캡슐 → 둥근 사각형 톤. height/2(41)보다 작아 카드 인상.
    static let difficultyCardCornerRadius: CGFloat = 20
    /// Sprint 7 — v3 카드 stroke 두께(1.5pt).
    static let difficultyCardStrokeLineWidth: CGFloat = 1.5

    /// Sprint 7 — v3 미선택 카드 알파(0.78). 기존 characterCardDeselectedAlpha(0.5) 대비 +0.28
    /// — 흐림 해소 핵심 수치.
    static let difficultyCardDeselectedAlpha: CGFloat = 0.78
    /// Sprint 7 — v3 미선택 fill alpha — id.color × 0.08. 살짝 깔리는 톤.
    static let difficultyCardDeselectedFillAlpha: CGFloat = 0.08
    /// Sprint 7 — v3 미선택 stroke alpha — id.color × 0.4. 미선택도 색 대비 명확.
    static let difficultyCardDeselectedStrokeAlpha: CGFloat = 0.4
    /// Sprint 7 — v3 선택 fill alpha — id.color × 0.2. 기존 Phase 8-3 값 유지.
    static let difficultyCardSelectedFillAlpha: CGFloat = 0.2

    /// Sprint 7 — v3 descriptionLabel 폰트 크기(10pt). 한 줄 풀이.
    static let difficultyCardDescriptionFontSize: CGFloat = 10

    // --- DifficultySelectScene v3 ---
    /// Sprint 7 — v3 좌측 summary 카드 offsetX(-260). 기존 -220 대비 -40 좌측 추가 이동
    /// — 우측 3장 카드가 112×3+22×2=380pt로 커지면서 시각 균형 보정.
    static let difficultySelectSummaryCardOffsetX: CGFloat = -260

    // --- CharacterSelectScene v3 ---

    // MARK: - Adaptive Layout (Sprint 7+ · 디바이스 대응 · iPhone SE ~ Pro Max)
    /// 화면 하단 안전 마진 — safeArea.bottom 위에 추가로 띄울 여백.
    /// SceneSafeArea.insets(for:).bottom + adaptiveBottomMargin = 노드 y 최소값.
    static let adaptiveBottomMargin: CGFloat = 24
    /// 화면 상단 안전 마진 — safeArea.top 아래에 추가로 띄울 여백.
    static let adaptiveTopMargin: CGFloat = 16
    /// 화면 좌우 안전 마진(노치/Dynamic Island 영역 회피).
    /// Landscape에서 노치가 한쪽(또는 양쪽)을 침범 — 카드 spacing 계산의 입력값.
    static let adaptiveHorizontalMargin: CGFloat = 20
    /// StartScene 시작 버튼 — 화면 하단(safeArea.bottom) 기준 안쪽 거리.
    /// frame.minY + safe.bottom + startButtonBottomInset = startButton.y.
    static let startButtonBottomInset: CGFloat = 64
    /// ResultScene 두 버튼(공유/다시시작) — 화면 하단(safeArea.bottom) 기준 안쪽 거리.
    /// frame.minY + safe.bottom + resultButtonBottomInset = button.y.
    static let resultButtonBottomInset: CGFloat = 56
    /// CharacterSelect 카드 spacing 최소값(28pt) — 가장 좁은 디바이스(iPhone SE) 보장.
    /// 카드 76 × 5장 + 28 × 4 spacing = 492pt — SE 가로(667pt safeArea 후) 안에 안전 수용.
    static let characterSelectMinCardSpacing: CGFloat = 28
    /// CharacterSelect 카드 spacing 최대값(56pt) — Pro Max에서 과도하게 벌어지지 않도록 clamp.
    /// 카드 76 × 5장 + 56 × 4 spacing = 604pt — Pro Max 가로(900+pt)에서 자연 균형.
    static let characterSelectMaxCardSpacing: CGFloat = 56
    /// CharacterSelect 확인 버튼 — adaptiveBottomMargin 위에 추가로 띄울 버튼 자체 높이 보정.
    /// PrimaryButton의 시각적 중앙을 카드 줄과 충분히 분리하기 위한 미세 inset.
    /// Sprint 10 — 40 → 64 (+24). 버튼이 safeArea 가장자리에 너무 붙어 답답하던 시각 결함 해소.
    static let characterSelectConfirmButtonBottomInset: CGFloat = 64
    /// CharacterSelect 스킬 정보 칩 — 확인 버튼 위쪽 상대 간격.
    static let characterSelectSkillInfoChipAbove: CGFloat = 36

    // MARK: - Sprint 7 Phase A · CharacterCard v3 (NIKKE 4:5)
    //
    // 카드 폭 160 / 높이 200 / cornerRadius 22 / gap 22 — NIKKE 식 세로 4:5 카드.
    // 카드 내부에 5요소(속성 헥사·등급 배지·CD 미니칩·얼굴·이름+속도)를 위계 있게 배치.
    // 선택 상태는 v2 scale 1.08 + 코랄 stroke에 *하단 코랄 radial glow + 상단 "선택됨" 알약* 추가.
    //
    // 모든 신규 상수는 `*V3` 접미사 또는 v3 의도값. 기존 v2 상수(characterCardWidth 76,
    // characterCardHeight 104, characterCardGlassWidth 156, characterCardGlassHeight 204,
    // characterCardSelectedScale 1.08, characterCardScaleDuration 0.10)는 값 변경 0.

    /// v3 카드 폭(160pt). 기존 characterCardWidth(76) 대비 +84. 4:5 세로 비율 carrier.
    static let characterCardWidth: CGFloat = 160
    /// v3 카드 높이(200pt). 폭 160 × 1.25 = 200 → 4:5 비율.
    static let characterCardHeight: CGFloat = 200
    /// v3 카드 cornerRadius(22pt). NIKKE 식 부드러운 둥금.
    static let characterCardCornerRadius: CGFloat = 22

    // --- 속성 헥사 아이콘 (좌상단) ---
    /// 헥사 outer radius(원에 외접) — 14pt → 28pt 헥사 폭.
    static let characterCardElementHexRadius: CGFloat = 14
    /// 헥사 stroke(흰색 1.5pt) — 카드 배경(반투명 화이트)과 분리.
    static let characterCardElementHexStrokeWidth: CGFloat = 1.5
    /// 카드 좌상단 코너 inset (x, y) — 헥사 중심 좌표 계산에 사용.
    static let characterCardElementHexInsetX: CGFloat = 18
    static let characterCardElementHexInsetY: CGFloat = 18
    /// 헥사 안 이모지 폰트 크기(pt). 헥사 폭 28의 약 57% — 시각 균형.
    static let characterCardElementSymbolFontSize: CGFloat = 16

    // --- 등급 로마숫자 배지 (좌하단) ---
    /// 배지 크기(26×18pt) — Jua 11pt 한 자리 로마숫자 수용.
    static let characterCardRarityBadgeWidth: CGFloat = 26
    static let characterCardRarityBadgeHeight: CGFloat = 18
    /// 배지 cornerRadius(8pt) — 부드럽지만 사각.
    static let characterCardRarityBadgeCornerRadius: CGFloat = 8
    /// 배지 fill alpha — navyDeep × 0.85.
    static let characterCardRarityBadgeFillAlpha: CGFloat = 0.85
    /// 카드 좌하단 코너 inset (x, y) — 배지 중심 좌표.
    static let characterCardRarityBadgeInsetX: CGFloat = 22
    static let characterCardRarityBadgeInsetY: CGFloat = 22
    /// 배지 라벨 폰트 크기(pt).
    static let characterCardRarityBadgeFontSize: CGFloat = 11

    // --- CD 미니칩 (우상단) ---
    /// 칩 높이(16pt) — 자동 폭(라벨 너비 + padding).
    static let characterCardCDChipHeight: CGFloat = 16
    /// 칩 좌우 패딩(8pt).
    static let characterCardCDChipHorizontalPadding: CGFloat = 8
    /// 칩 fill — coralLight × 0.85.
    static let characterCardCDChipFillAlpha: CGFloat = 0.85
    /// 칩 라벨 폰트 크기(pt).
    static let characterCardCDChipFontSize: CGFloat = 9
    /// 카드 우상단 코너 inset (x, y).
    static let characterCardCDChipInsetX: CGFloat = 16
    static let characterCardCDChipInsetY: CGFloat = 18

    // --- 이름 + 속도 (하단) ---
    /// 이름 라벨 폰트 크기(pt). Jua, navyDeep.
    static let characterCardNameFontSize: CGFloat = 15
    /// 이름 라벨 y offset (카드 하단 기준 + 28).
    static let characterCardNameOffsetY: CGFloat = 28
    /// 속도 칩 라벨 폰트 크기(pt). Gowun Dodum, scrubMint.
    static let characterCardSpeedFontSize: CGFloat = 10
    /// 속도 칩 y offset (카드 하단 기준 + 12 — 이름 아래).
    static let characterCardSpeedOffsetY: CGFloat = 12

    // --- 선택 상태 강화 (Phase A) ---
    /// 코랄 glow y offset (카드 하단 기준 -12 — 카드 아래로 살짝 새어 나옴).
    static let characterCardSelectedGlowOffsetY: CGFloat = -12
    /// 코랄 glow 알파(0.45).
    static let characterCardSelectedGlowAlpha: CGFloat = 0.45

    /// "선택됨" 알약 폭(60pt) / 높이(20pt). Jua 10pt 흰색 "선택됨" 수용.
    static let characterCardSelectedPillWidth: CGFloat = 60
    static let characterCardSelectedPillHeight: CGFloat = 20
    /// 알약 라벨 폰트 크기(pt).
    static let characterCardSelectedPillFontSize: CGFloat = 10
    /// 알약 텍스트.
    static let characterCardSelectedPillText: String = "선택됨"
    /// 알약 y offset (카드 상단 기준 +14 — 카드 위로 솟음).
    static let characterCardSelectedPillOffsetY: CGFloat = 14

    // --- 스킬 패널 폭 축소 (Phase A) ---
    /// 하단 스킬 정보 칩 최대 폭(320pt). v2 무한 → v3 320 clamp.
    /// 5장 카드 총 폭(160×5 + 22×4 = 888pt)과 시각적 분리.
    static let characterSelectSkillInfoMaxWidth: CGFloat = 320

    // MARK: - Sprint 7 Phase B · Skill Explanation v3 (겹침 해소 + 호흡)
    // SPRINT_7_REQUEST.md §3.2 — 본문 폭 47%→52%, 인용 보더 3px→4px,
    // 메타칩 gap 8→10, 버튼 gap 12→18. 기존 v2 상수는 값 유지(회귀 0).

    /// 인용 박스 좌측 코랄 보더 굵기(pt) — v2 3 → v3 4.
    static let skillExplanationQuoteBoxBorderWidth: CGFloat = 4

    /// 메타 칩 3개(CD/범위/발동) 사이 간격(pt) — v2 8 → v3 10.
    static let skillExplanationStatChipSpacing: CGFloat = 10

    // MARK: - Sprint 10.9 · Skill Explanation Modern Briefing V4
    /// 우측 스킬 정보를 하나의 브리핑 패널로 묶어 요소 밀집감을 낮춘다.
    static let skillExplanationBriefingPanelWidth: CGFloat = 410
    static let skillExplanationBriefingPanelHeight: CGFloat = 218
    static let skillExplanationBriefingPanelCornerRadius: CGFloat = 26
    static let skillExplanationBriefingPanelFillAlpha: CGFloat = 0.74
    static let skillExplanationBriefingPanelStrokeAlpha: CGFloat = 0.18
    static let skillExplanationBriefingPanelTextInsetX: CGFloat = 30
    static let skillExplanationBriefingPanelOffsetY: CGFloat = -4
    static let skillExplanationSkillNameOffsetY: CGFloat = 72
    static let skillExplanationQuoteBoxWidth: CGFloat = 350
    static let skillExplanationQuoteBoxHeight: CGFloat = 88
    static let skillExplanationQuoteBoxOffsetY: CGFloat = 4
    static let skillExplanationStatChipRowOffsetY: CGFloat = -78
    static let skillExplanationButtonRightPanelGap: CGFloat = 34
    static let skillExplanationAvatarCardOffsetX: CGFloat = -230
    static let skillExplanationBriefingPanelOffsetX: CGFloat = 128

    // MARK: - Sprint 7 Phase C · Difficulty hierarchy v3
    //
    // 난이도 3장 카드에 *색 위계*를 부여하고 선택 카드를 시선 자석으로 만든다.
    // 카드 헤더 22pt → 30pt + 카드별 stroke 외곽선 / 선택 시 +8pt 상승 + radial glow /
    // 시작 버튼 뒤 halo SKShape 부착.
    //
    // 모든 신규 상수는 `*PhaseC` 또는 명시적 의도값 접미사. 기존 V3 상수
    // (difficultyCardDeselectedAlpha, DeselectedFillAlphaV3, DeselectedStrokeAlphaV3,
    // SelectedFillAlphaV3, StrokeLineWidthV3, NameFontSizeV3 등)는 값 변경 0.

    /// Phase C — 카드 헤더(이름 라벨) 폰트 크기(30pt). 기존 V3 22pt → +8.
    /// nameLabelStroke / nameLabel 2개 라벨로 stroke 외곽선 표현.
    static let difficultyCardNameFontSizePhaseC: CGFloat = 30
    /// Phase C — 카드 헤더 stroke 굵기(1pt). nameLabelStroke 폰트 = 30 + 1×2 = 32pt
    /// 베이스 라벨로 stroke 효과 근사. SKLabelNode는 stroke 직접 미지원.
    static let difficultyCardNameStrokeWidthPhaseC: CGFloat = 1.0

    /// Phase C — 선택 카드 상승 거리(+8pt). mockup `transform: translateY(-8px)` 대응.
    /// 미세 상승 — *시선 자석* 효과의 핵심 수치. liftCurrentOffset 증분 추적으로 누적 방지.
    static let difficultyCardSelectedLiftY: CGFloat = 8
    /// Phase C — 선택 카드 상승 액션 지속 시간(0.18s). spring overshoot phase1과 동일 톤.
    static let difficultyCardSelectedLiftDuration: TimeInterval = 0.18

    /// Phase C — 선택 카드 뒤 radial glow 폭(158pt). 카드 폭 112 대비 ×1.41.
    /// mockup .diff-card::before 158 × 116.
    static let difficultyCardSelectedGlowWidthPhaseC: CGFloat = 158
    /// Phase C — 선택 카드 뒤 radial glow 높이(116pt). 카드 높이 82 대비 ×1.41.
    static let difficultyCardSelectedGlowHeightPhaseC: CGFloat = 116
    /// Phase C — 선택 카드 뒤 radial glow alpha(0.80). 시선 자석 강도.
    static let difficultyCardSelectedGlowAlphaPhaseC: CGFloat = 0.80
    /// Phase C — 선택 카드 뒤 radial glow spread(12pt). SKShapeNode.glowWidth로 근사 —
    /// 진정한 Gaussian blur는 SpriteKit 미지원, mockup `filter: blur(20px)` 근사 보정.
    static let difficultyCardSelectedGlowSpreadPhaseC: CGFloat = 12

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

    // ScoreboardScene — 미니 얼굴 (CharacterFaceNode.mini)
    /// 행 헤더 미니 얼굴 setScale 배율(0.47 ≈ 32/68 — CharacterFaceNode 기본 ~68 → ~32pt).
    static let scoreboardMiniFaceScale: CGFloat = 0.47

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

    // MARK: - Sprint 8 Phase B · Character Select 스와이프 페이지 V4
    //
    // 5장 카드 동시 노출(폭 912pt > 화면 844pt) → 중앙 1장 + 양옆 반쯤 보이는 2장으로 전환.
    // V3 카드 폭(160) / 높이(200) / cornerRadius(22) 등 시각 토큰은 byte-identical 보존.
    // 본 V4 상수는 *위치/scale/alpha 산출식*에만 사용.

    // MARK: - Sprint 8 Phase D · Difficulty Card V4
    //
    // V3 카드(112×82) 좁아 한글 텍스트 2~3줄 줄바꿈 답답 → V4 130×200 + line height 1.4.
    // V3 색 위계(EasyMint/MidGold/HardCoral)는 byte-identical 보존.
    // 적용 위치: DifficultyCardNode(카드 본체 size + 내부 layout) + DifficultySelectScene.layoutDifficultyCards
    // (width/spacing 교체). V3 상수(difficultyCardWidthV3=112, HeightV3=82, SpacingV3=22,
    //  SubtitleFontSizeV3=12, SubtitleOffsetYV3=4, StrokeLineWidthV3=1.5)는 byte-identical 보존 —
    // 사용처만 V4로 교체.

    /// Phase D 카드 폭(130pt). V3=112.
    static let difficultyCardWidth: CGFloat = 130
    /// Phase D 카드 높이(200pt). V3=82.
    static let difficultyCardHeight: CGFloat = 200
    /// Phase D 카드 사이 spacing(22pt). V3 SpacingV3와 동일 — V4 알리아스.
    static let difficultyCardGap: CGFloat = 22
    /// Phase D 카드 내부 top/bottom padding(14pt). V3는 명시 상수 없음(8pt 추정).
    static let difficultyCardPadding: CGFloat = 14
    /// Phase D 부제 ↔ 보조 라벨 사이 vertical gap(10pt). V3=4pt(SubtitleOffsetYV3).
    static let difficultyCardSubtitleGap: CGFloat = 10
    /// Phase D 헤더(하/중/상) ↔ 부제 사이 gap(12pt). V3=6pt 추정.
    static let difficultyCardHeaderGap: CGFloat = 12
    /// Phase D 보조 라벨 line height multiplier(1.4). V3=1.15. attributedString paragraphStyle 사용.
    static let difficultyCardSubtitleLineHeight: CGFloat = 1.4
    /// Phase D 보조 라벨 fontSize(12pt). V3=12pt와 동일 — V4 알리아스(명시화).
    static let difficultyCardSubtitleFontSize: CGFloat = 12

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

    // MARK: - Sprint 7 Phase G · Player Facing (4방향 child)
    //
    // PlayerNode가 4 CharacterFaceNode child를 미리 부착해두고 isHidden 토글로 즉시 전환.
    // CharacterFaceNode 본래 좌표계(±50)와 PlayerNode 시각 크기(32×40)의 정합용.

    /// PlayerNode 4 CharacterFaceNode child의 scale (0.5).
    /// CharacterFaceNode head ellipse는 ±32~±34 좌표계 → 0.5 → ±16~±17pt 폭, player visual 32×40과 자연 정합.
    static let playerFaceChildScale: CGFloat = 0.5

    // MARK: - Sprint 9 Phase A · Character Select V9
    //
    // 카드 외부에 부착되던 알약/글로우/얼굴을 카드 내부 inset 좌표로 재배치.
    // 좌우 GlassPill 화살표 2개 신규. 카드 y 비율을 0.50 → 0.44로 살짝 낮춰 헤더↔카드 24pt 호흡 확보.
    // V3/V4 기존 상수는 모두 *값 보존*(다른 사용처 참조 가능성 + 회귀 안전망) — V9 신규만 추가.

    /// "선택됨" 알약 — 카드 상단 *내부* inset(top 기준 16pt 안쪽). AS-IS: halfH + 14 (외부).
    static let characterCardSelectedPillInsetTop: CGFloat = 16
    /// 코랄 glow — 카드 하단 *내부* inset(bottom 기준 22pt 안쪽). AS-IS: -halfH + (-12) (외부).
    static let characterCardSelectedGlowInsetBottom: CGFloat = 22
    /// 코랄 glow 폭 — 카드 폭에 맞춤(cardWidthV3 - 8 = 152pt). AS-IS: 224 (카드 폭 1.4배 외부).
    static let characterCardSelectedGlowWidth: CGFloat = 152
    /// 코랄 glow 높이 — 36pt. AS-IS: 60.
    static let characterCardSelectedGlowHeight: CGFloat = 36

    // MARK: - Sprint 9 Phase B · Player FullBody V9
    //
    // 인게임 풀바디 캐릭터를 "2칸(64pt)" 안에 들이기 위한 path 자체 축소 + scale 보정.
    // V4 상수(playerFullBodyScaleV4 = 0.35)는 *값 보존* — 다른 사용처 참조 가능성 + 회귀 안전망.
    // PixelSprite 본체는 PlayerNode.attachFullBody 끝에서 color=.clear + colorBlendFactor=1.0 패턴으로 시각 차단.
    // physicsBody / velocity / 이동 로직 0줄 변경 — 순수 시각 layer.

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
    static let characterHomeHeaderText: String = "캐릭터 홈"
    static let characterHomeHeaderSubText: String = "계정 기록을 보고 바로 시작해요"
    static let characterHomeStartButtonText: String = "시작"
    static let characterHomeBackButtonText: String = "← 첫 화면"
    static let characterHomeMenuCharacterText: String = "캐릭터 선택"
    static let characterHomeMenuProfileText: String = "개인프로필"
    static let characterHomeMenuAchievementsText: String = "업적"
    static let characterHomeMenuRecordsText: String = "기록"
    static let characterHomeAppleFallbackNameText: String = "Apple 플레이어"
    static let characterHomeGuestNameText: String = "게스트 플레이어"
    static let characterHomeLocalNameText: String = "로컬 플레이어"
    static let characterHomeAppleProfileSubText: String = "Apple 계정으로 기록을 이어가요"
    static let characterHomeGuestProfileSubText: String = "이 기기 안에 기록이 저장돼요"
    static let characterHomeLocalProfileSubText: String = "로컬 기록으로 바로 플레이 가능"
    static let characterHomeNoRecordText: String = "기록 없음"
    static let characterHomeAchievedText: String = "달성"
    static let characterHomeLockedText: String = "잠김"
    static let characterHomeUnlockedText: String = "해금됨"
    static let characterHomeUnlockRequirementSuffix: String = "25점 달성 후 해금"
    static let characterHomeLockedStartFeedbackText: String = "아직 시작할 수 없어요"
    static let characterHomeProfileTitleText: String = "개인프로필"
    static let characterHomeAchievementTitleText: String = "업적"
    static let characterHomeRecordTitleText: String = "난이도별 기록"
    static let characterHomeGraduationLabelText: String = "졸업장"
    static let characterHomeSelectedGraduateText: String = "선택 캐릭터 수료"
    static let characterHomeSelectedLockedText: String = "선택 캐릭터 미수료"
    static let characterHomePlayCountLabelText: String = "플레이"
    static let characterHomeBestScoreLabelText: String = "최고점"
    static let characterHomeTotalScoreLabelText: String = "누적점수"
    static let characterHomePointSuffixText: String = "점"
    static let characterHomePlaySuffixText: String = "회"
    static let characterHomeTargetPrefixText: String = "목표"
    static let characterHomeSkillPrefixText: String = "스킬"
    static let characterHomeSkillNoneText: String = "스킬 없음"
    static let characterHomeSpeedPrefixText: String = "속도"
    static let characterHomeMultiplierSeparatorText: String = "×"
    static let characterHomeSkillSeparatorText: String = "·"
    static let characterHomeTextJoinSeparator: String = " "
    static let characterHomeSingleDecimalFormat: String = "%.1f"
    static let characterHomeDoubleDecimalFormat: String = "%.2f"
    static let characterHomeLeftArrowText: String = "‹"
    static let characterHomeRightArrowText: String = "›"

    static let characterHomeHeaderFontSize: CGFloat = 24
    static let characterHomeHeaderSubFontSize: CGFloat = 12
    static let characterHomeTopBarInsetX: CGFloat = 34
    static let characterHomeTopBarInsetY: CGFloat = 28
    static let characterHomeHeaderLeftGap: CGFloat = 22
    static let characterHomeHeaderSubOffsetY: CGFloat = -21
    static let characterHomeAccentLineOffsetY: CGFloat = 19
    static let characterHomeBackButtonWidth: CGFloat = 106
    static let characterHomeBackButtonHeight: CGFloat = 30
    static let characterHomeArrowPillWidth: CGFloat = 54
    static let characterHomeAccountChipWidth: CGFloat = 150

    static let characterHomeProfilePanelWidth: CGFloat = 210
    static let characterHomeProfilePanelHeight: CGFloat = 268
    static let characterHomeProfilePanelLeftInset: CGFloat = 30
    static let characterHomeProfilePanelTopInset: CGFloat = 84
    static let characterHomeStageWidth: CGFloat = 420
    static let characterHomeStageMinimumWidth: CGFloat = 326
    static let characterHomeStageHeight: CGFloat = 352
    static let characterHomeStageCenterOffsetX: CGFloat = -106
    static let characterHomeStageCenterYRatio: CGFloat = 0.52
    static let characterHomeCompactStageCenterOffsetX: CGFloat = -6
    static let characterHomeCompactStageCenterYRatio: CGFloat = 0.56
    static let characterHomePortraitMaxWidth: CGFloat = 174
    static let characterHomePortraitMaxHeight: CGFloat = 232
    static let characterHomePortraitBottomInset: CGFloat = 66
    static let characterHomePortraitColumnOffsetX: CGFloat = 88
    static let characterHomeInfoColumnOffsetX: CGFloat = 28
    static let characterHomeStageInfoMaxWidth: CGFloat = 162
    static let characterHomeInfoNameOffsetY: CGFloat = 104
    static let characterHomeInfoSkillOffsetY: CGFloat = 58
    static let characterHomeInfoSpeedOffsetY: CGFloat = -42
    static let characterHomeArrowOutsideGap: CGFloat = 12
    static let characterHomeDetailPanelWidth: CGFloat = 230
    static let characterHomeDetailPanelHeight: CGFloat = 204
    static let characterHomeAchievementPanelHeight: CGFloat = 134
    static let characterHomeDetailPanelGap: CGFloat = 14
    static let characterHomeMenuButtonWidth: CGFloat = 150
    static let characterHomeMenuButtonHeight: CGFloat = 34
    static let characterHomeMenuGap: CGFloat = 10
    static let characterHomeMenuRightInset: CGFloat = 28
    static let characterHomeMenuBottomInset: CGFloat = 20
    static let characterHomeMenuCenterYOffset: CGFloat = 10
    static let characterHomeRailButtonSize: CGFloat = 44
    static let characterHomeRailGap: CGFloat = 10
    static let characterHomeRailBottomInset: CGFloat = 18
    static let characterHomeArrowButtonSize: CGFloat = 60
    static let characterHomeArrowInsetX: CGFloat = 28
    static let characterHomeStartButtonBottomInset: CGFloat = 22
    static let characterHomeBottomStartButtonAboveMenu: CGFloat = 12
    static let characterHomeBottomReservedAreaGap: CGFloat = 12
    static let characterHomePanelHorizontalInset: CGFloat = 16
    static let characterHomePanelVerticalInset: CGFloat = 16
    static let characterHomePanelTitleFontSize: CGFloat = 16
    static let characterHomePanelBodyFontSize: CGFloat = 12
    static let characterHomePanelSmallFontSize: CGFloat = 10
    static let characterHomePanelMetricFontSize: CGFloat = 11
    static let characterHomePanelValueFontSize: CGFloat = 19
    static let characterHomeProfileStatusChipWidth: CGFloat = 122
    static let characterHomeProfileStatusChipHeight: CGFloat = 24
    static let characterHomeProfileMetricGap: CGFloat = 46
    static let characterHomeStageNameFontSize: CGFloat = 30
    static let characterHomeStageSkillFontSize: CGFloat = 14
    static let characterHomeStageSpeedFontSize: CGFloat = 11
    static let characterHomeStageNameTopInset: CGFloat = 40
    static let characterHomeStageSkillGap: CGFloat = 30
    static let characterHomeStageSpeedChipWidth: CGFloat = 112
    static let characterHomeStageSpeedChipHeight: CGFloat = 24
    static let characterHomeMenuFontSize: CGFloat = 13
    static let characterHomeRailFontSize: CGFloat = 11
    static let characterHomeRecordRowHeight: CGFloat = 42
    static let characterHomeAchievementBadgeHeight: CGFloat = 24
    static let characterHomeAchievementBadgeGap: CGFloat = 8

    static let characterHomePanelCornerRadius: CGFloat = 18
    static let characterHomePanelLineWidth: CGFloat = 1.2
    static let characterHomePanelFillAlpha: CGFloat = 0.74
    static let characterHomePanelStrokeAlpha: CGFloat = 0.34
    static let characterHomePanelFocusedStrokeAlpha: CGFloat = 0.42
    static let characterHomeFocusedScale: CGFloat = 1.0
    static let characterHomeUnfocusedAlpha: CGFloat = 0.72
    static let characterHomeStageShadowWidth: CGFloat = 260
    static let characterHomeStageShadowHeight: CGFloat = 38
    static let characterHomeStageShadowAlpha: CGFloat = 0.12
    static let characterHomePortraitBreathScale: CGFloat = 1.025
    static let characterHomePortraitBreathDuration: TimeInterval = 1.2
    static let characterHomeFocusAnimationDuration: TimeInterval = 0.16
    static let characterHomeRailSelectedScale: CGFloat = 1.1
    static let characterHomeRailDeselectedAlpha: CGFloat = 0.58
    static let characterHomeLockedPortraitAlpha: CGFloat = 0.48
    static let characterHomeLockedStartButtonAlpha: CGFloat = 0.52
    static let characterHomeRoughTapZoneRatio: CGFloat = 0.35
    static let characterHomeLockedFeedbackDuration: TimeInterval = 1.2
    static let characterHomePortraitBreathActionKey: String = "characterHomePortraitBreath"
    static let characterHomeSectionFocusActionKey: String = "characterHomeSectionFocus"
    static let characterHomeRailFocusActionKey: String = "characterHomeRailFocus"

    static let characterHomeSwipeThreshold: CGFloat = 44
    static let characterHomeBottomMenuWidthThreshold: CGFloat = 900
    static let characterHomeCompactHeightThreshold: CGFloat = 460
    static let characterHomeDefaultIndex: Int = 0
    static let characterHomeCompactScale: CGFloat = 0.74
    static let characterHomeBottomMenuScale: CGFloat = 0.86
    static let characterHomeSingleDecimalScale: CGFloat = 10
    static let characterHomeSpeedFormatEpsilon: CGFloat = 0.001

    // MARK: - DifficultySelect V5 (좌측 카드 풀바디 픽셀화 + 헤더↔카드 호흡 확보)
    //
    // SkillExplanationScene와 동일한 풀바디 픽셀 스프라이트(PixelSpriteRenderer + PNG fallback)로
    // 좌측 미니 카드 아바타를 통일하고, 헤더(난이도를 골라요)와 카드 윗선이 거의 맞붙어 보이는 답답함을
    // 해소하기 위해 카드 전체를 30pt 하방 이동. 시작 버튼도 좌측 카드 bottom과의 충돌 + 화면 하단
    // 클램프를 추가해 안전 배치한다.
    //
    // 기존 V3/V4 토큰(difficultySelectSummaryCardOffsetY=-10, difficultySelectStartButtonOffsetY=-160,
    // difficultyCardWidth/HeightV4/GapV4 등)은 *byte-identical 보존* — 다른 사용처 회귀 위험 0.

    /// V5 좌측 요약 카드 y offset (-40pt). 기존 V3(-10) 대비 -30pt 하방 이동 →
    /// 카드 top = midY+90 ↔ 헤더 baseY(midY+140)와 50pt 호흡 확보(사용자 답답함 해소).
    /// 카드 내부 4개 노드(NameBadge/Face/Skill/SpeedChip)는 baseY 기준 상대 OffsetY라
    /// 자동으로 30pt 함께 하방 이동 — 추가 수정 0줄.
    static let difficultySelectSummaryCardOffsetY: CGFloat = -40

    /// V5 시작 버튼 y offset (-200pt). 기존 V3(-160) 대비 -40pt 하방 — "살짝" 톤 유지하되
    /// 좌측 카드 bottom(midY-170)과 36pt 호흡 보장. layoutStartButton()에서 V3/V4/V5 산식 중
    /// 가장 작은 y(가장 아래) 채택 → V5 좌측 카드 산식 결과(-230)가 dominant.
    /// 그 후 화면 하단 safe margin 클램프 적용.
    static let difficultySelectStartButtonOffsetY: CGFloat = -200

    /// V5 시작 버튼 ↔ 카드 bottom 호흡 거리(36pt). V4와 동값이나 *V5 의미 단위 분리* —
    /// 좌측 카드 bottom 산식에서도 이 값을 동일하게 사용해 좌/우 카드 모두 36pt 호흡 보장.
    static let difficultySelectStartButtonBreathingGap: CGFloat = 36

    // MARK: - DifficultySelect V6 (캐릭터 프리뷰 aspect-fit)
    /// V6 좌측 요약 카드 안 풀바디 픽셀/PNG 프리뷰 최대 가로. 원본 texture 비율 유지용 max bounds.
    static let difficultySelectSummaryFullBodyMaxWidth: CGFloat = 92

    /// V6 좌측 요약 카드 안 풀바디 픽셀/PNG 프리뷰 최대 세로. 정사각 강제 size 대신 aspect-fit에 사용.
    static let difficultySelectSummaryFullBodyMaxHeight: CGFloat = 118

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
