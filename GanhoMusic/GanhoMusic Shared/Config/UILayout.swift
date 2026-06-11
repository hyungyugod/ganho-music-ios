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
    static let ipadIngameHUDScale: CGFloat = 1.08
    static let ipadIngameControlScale: CGFloat = 1.15
    static let ipadIngameTopButtonScale: CGFloat = 1.12
    static let ipadCameraScaleFloor: CGFloat = 0.62
    static let ipadCameraScaleCeiling: CGFloat = 1.0
    static let ingameHUDReadableAlpha: CGFloat = 0.92
    static let ingameControlReadableAlpha: CGFloat = 0.78
    static let ingameSafeControlPadding: CGFloat = 18
    // R8 — primaryButtonTextHorizontalPadding/ArrowReservedWidth: PrimaryButtonNode 삭제와
    // 함께 참조 0 실증 후 삭제 (일시정지 v3 재구축 — §C-1).

    // MARK: - HUD (Phase 2-4)
    /// HUD 알파 (반투명, 가독성 우선). D-Pad 0.3보다 큼.
    static let hudAlpha: CGFloat = 0.85

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

    // R8 — primaryButtonWidth/Height/FontSize(v2 캡슐 버튼)·최상위 backButtonWidth/Height/
    // FontSize(R4.backButtonSize와 별개 구 토큰): 참조 0 실증 후 삭제 (§C-1·§C-2-마).

    // MARK: - Start Scene Visual (Phase 10-2 · 병동의 새벽 톤)


    /// 제목 글로우 SKEffectNode CIGaussianBlur 반경 (pt).
    static let titleGlowBlurRadius: CGFloat = 8.0


    // MARK: - v2 Components (Sprint 1)
    // R5 — v2 알약/액션 버튼 계열 상수는 참조 0 실증 후 삭제. 아래 한 개만 잔존.
    /// R8 리네임 — 구 glassPillFillAlpha (값 byte-불변 0.94). ProfileNameEditor(UIKit 모달)의
    /// 필드/버튼 배경 α 현역 사용 — 실사용처 기준 명명 (GameViewController 3곳).
    static let profileNameEditFieldFillAlpha: CGFloat = 0.94

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

    // R8 — PrimaryButtonNode v2 시각 상수 6종(primaryButtonShadowOffsetY/ShadowBlurRadius/
    // ArrowRadius/ArrowInsetX/ArrowCircleAlpha/ArrowLabelFontSize): 컴포넌트 삭제와 함께
    // 참조 0 실증 후 삭제 (§C-1 — 일시정지 v3가 PixelDialog/PixelButton으로 대체).

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
    // R8 — authManageButtonText/BusyText 2종: 참조 0 실증 후 삭제 (§C-2-마 — v2 계정
    // 버튼 잔여 카피, R5 AccountMenuOverlay v3 카피로 대체 완료).
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
    /// R8 리네임 — 구 overlayButtonDisabledAlpha (값 byte-불변 0.48). ProfileNameEditor
    /// 저장 버튼 비활성 α 현역 사용 — 실사용처 기준 명명 (GameViewController 1곳).
    static let profileNameEditDisabledAlpha: CGFloat = 0.48

    // MARK: - Account Menu Overlay
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
    // R8 — profileAvatarFrame* 4종(CornerRadius/LineWidth/FillAlpha/StrokeAlpha):
    // 참조 0 실증 후 삭제 (§C-2-마 — R5 프로필 v3 재구축의 잔여 토큰).
    static let profileAvatarContentInset: CGFloat = 8
    static let profileAvatarSummarySize = CGSize(width: 58, height: 58)

    // MARK: - Profile Detail Overlay
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

    // MARK: - Adaptive Layout (Sprint 7+ · 디바이스 대응)
    // R8 — adaptiveBottomMargin/TopMargin/HorizontalMargin 3종: 참조 0 실증 후 삭제
    // (§C-2-마 — safeArea 회피는 SceneSafeArea + 각 씬 layout이 v3ScreenEdgeInset으로 담당).

    // MARK: - Scoreboard 카피 (R5 — v2 레이아웃 수치 전부 삭제, 재사용 카피 텍스트만 잔존)
    /// 테이블 패널 헤더 제목 텍스트.
    static let scoreboardTitleText: String = "기록 보기"

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
