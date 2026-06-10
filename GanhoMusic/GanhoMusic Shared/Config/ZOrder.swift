//
//  ZOrder.swift
//  GanhoMusic Shared
//
//  R0 — 구 god-config(분할 전 단일 Config) 분해: zPosition 상수 전부. 시각 적층 순서의 단일 진실 원천.
//

import CoreGraphics

/// zPosition 적층 토큰 — 씬·노드 시각 우선순위.
/// case 없는 enum: 인스턴스화 차단 (왜: z 충돌 디버깅 시 한 파일만 보면 되도록).
enum ZOrder {
    // MARK: - Original Map (Sprint 10 Phase B — 원본 1:1 정합)
    /// MapNode z-position. 체크보드(-100) 위, 외곽 벽(0) 아래 — 좌표 그릇 시각 적층.
    static let mapNodeZPosition: CGFloat = -50

    // MARK: - Sparkle Effect (Phase 6-8)
    /// sparkle 파편 zPosition. HUD(100) 아래, Player/Note(0~5) 위 — 노트가 사라진 자리에서 위로 떠오르는 느낌.
    static let sparkleZPosition: CGFloat = 30

    // MARK: - Hit Feedback (Phase 6-9)
    /// 피격 플래시 zPosition. HUD(100) 위, BombFlash(250) 아래.
    /// 점수 라벨을 잠깐 덮어 임팩트 강조 — 0.3초만 가려지므로 게임플레이 무방해.
    static let hitFlashZPosition: CGFloat = 200

    // MARK: - Combo Popup (Phase 6-10)
    /// 팝업 zPosition. HUD(100) 위 — 라벨을 잠깐 덮어 임팩트.
    /// HitFlash(200) 아래 — 피격 플래시는 더 우선(생존 직결).
    static let comboPopupZPosition: CGFloat = 150

    // MARK: - Combo Break (Phase 6-12)
    /// BREAK zPosition. comboPopupZPosition(150) 아래 — 환호 위에 끊김이 덮이지 않도록.
    /// HUD(100) 위는 유지 — 임팩트 강조. HitFlash(200) 아래.
    static let comboBreakZPosition: CGFloat = 140

    // MARK: - Milestone Banner (Score Progress)
    /// 배너 zPosition. comboPopupZPosition(150)과 동급 — HUD(100) 위, HitFlash(200) 아래.
    static let milestoneBannerZPosition: CGFloat = 150

    // MARK: - Countdown (Phase 6-13)
    /// CountdownNode zPosition. HitFlash(200) 위, BombFlash(250)와 동급/이하.
    /// 카운트다운 동안 어떤 UI도 덮는다 — 게임이 아직 시작 안 했으므로.
    static let countdownZPosition: CGFloat = 250

    // MARK: - New Best (Phase 6-15)
    /// 신기록 보상 라벨 zPosition. comboPopupZPosition(150)과 동급 — ResultScene 기본 z=0 위.
    static let newBestZPosition: CGFloat = 150

    // MARK: - Score Popup (Phase 6-16)
    /// "+1"/"+2" 라벨 zPosition. sparkle(30) 위, HUD(100) 아래 —
    /// 노트 사라진 픽셀 위에 떠 있되 HUD 점수/타이머는 안 가림.
    static let scorePopupZPosition: CGFloat = 50

    // MARK: - Danger Warning Sprint
    static let projectileWarningLineZPosition: CGFloat = 4
    static let enemyDangerRingZPosition: CGFloat = -0.5
    static let playerNearMissRingZPosition: CGFloat = -0.25

    // MARK: - Wall Tile (Runtime Compact)
    /// 벽 셀 zPosition. MapNode 자식 좌표계 기준 — MapNode 자체 zPos(-50) 위 적층.
    static let wallTileZPosition: CGFloat = 0

    // MARK: - Cutscene (Phase 7-3)
    /// 컷씬 노드 zPosition. countdownZPosition(250)·bombFlashZPosition 위 — 컷씬 동안 어떤 UI도 덮는다.
    /// 게임이 아직 시작 안 했으므로 그 어떤 게임 노드보다 우선.
    static let cutsceneZPosition: CGFloat = 300

    // MARK: - Profile Name Editor — Keyboard Avoidance (신규)
    /// 졸업장 zPosition. cutsceneZPosition(300)과 동급 — newBestZPosition(150) 위로 자연 겹침.
    /// 그 어떤 게임 UI도 덮음(이미 게임 종료 후 ResultScene 위라 충돌 없음).
    static let diplomaZPosition: CGFloat = 300

    // MARK: - Checkerboard Floor (Phase 9-4)
    /// 체크보드 컨테이너 zPosition. 외곽 벽/기둥(0)·Player/Enemy/StoneGuard(5) 아래.
    /// 음수 zPosition도 SpriteKit 정상 동작 — 시각 깊이 분리.
    static let checkerboardZPosition: CGFloat = -100

    // MARK: - Skill (Phase 9-5)

    // 스킬 공통 이펙트
    static let skillEffectZPosition: CGFloat = 35

    // MARK: - Toilet Bonus (Phase 9-6)
    /// 변기 zPosition. note(0) 위, player/enemy/stoneGuard(5) 아래 — 4. SPEC.md §노드 트리 부착.
    static let toiletZPosition: CGFloat = 4

    // MARK: - Toast Label (Phase 9-6)
    /// 토스트 zPosition. scorePopupZPosition(50)과 동급 — *지역* 시그널 군집 통일.
    static let toastZPosition: CGFloat = 50

    // MARK: - Start Scene Visual (Phase 10-2 · 병동의 새벽 톤)
    /// StartScene 비주얼 리스킨. 그라데이션 배경 + 음표 파티클 + 제목 글로우 + 카드 spring + 버튼 pulse + 전환 잔향.
    /// 본 섹션은 *추가만* — 기존 상수 변경 0건.

    /// 그라데이션 배경 zPosition. overlayBackground(-10)보다 아래.
    static let startSceneGradientZPosition: CGFloat = -20
    /// 음표 파티클 zPosition. overlayBackground(-10)보다 위, overlayPanel(-5)보다 아래.
    /// 패널 위로 음표가 *튀어나오지 않게* 의도적 후방 배치.
    static let startSceneMusicNoteZPosition: CGFloat = -15

    // MARK: - Login Choice Overlay
    static let loginChoiceOverlayZPosition: CGFloat = 520
    static let loginChoiceDimZPosition: CGFloat = -1
    static let loginChoicePanelZPosition: CGFloat = 0
    static let loginChoiceLabelZPosition: CGFloat = 1
    static let loginChoiceButtonZPosition: CGFloat = 2

    // MARK: - Account Menu Overlay
    static let accountMenuOverlayZPosition: CGFloat = 500
    static let accountMenuDimZPosition: CGFloat = -1
    static let accountMenuPanelZPosition: CGFloat = 0
    static let accountMenuLabelZPosition: CGFloat = 1
    static let accountMenuButtonZPosition: CGFloat = 2

    // MARK: - Profile Avatar
    static let profileAvatarFrameZPosition: CGFloat = 0
    static let profileAvatarContentZPosition: CGFloat = 1

    // MARK: - Profile Detail Overlay
    static let profileDetailOverlayZPosition: CGFloat = 540
    static let profileDetailDimZPosition: CGFloat = -1
    static let profileDetailPanelZPosition: CGFloat = 0
    static let profileDetailLabelZPosition: CGFloat = 2
    static let profileDetailButtonZPosition: CGFloat = 4

    // MARK: - Sprint 5 · ResultScene v2 Layout
    /// 공유 실패 토스트 zPosition. 결과 버튼보다 위에 표시한다.
    static let resultShareToastZPosition: CGFloat = 120
    /// 종이 카드 zPosition(노드 좌표계 내부). background(0) 위 + 도트 패턴(0.7) 아래.
    static let diplomaPaperZPosition: CGFloat = 0.5
    /// 도트 패턴 zPosition. paperCard(0.5) 위 + 라벨(1) 아래.
    static let diplomaDotsZPosition: CGFloat = 0.7
    /// 코너 데코 zPosition. 도트 패턴(0.7) 위 + 라벨(1) 아래.
    static let diplomaCornerDecoZPosition: CGFloat = 0.8
    /// 도장 zPosition. 라벨(1) 위.
    static let diplomaStampZPosition: CGFloat = 1.2

    // MARK: - NurseAvatarNode (StartScene 좌측 김간호 큰 그림)
    /// zPosition — 배경(-20/-15)·타이틀(0~5)·시작버튼(100) 사이의 8 — 시작버튼과 음표보다 아래.
    static let nurseAvatarZPosition: CGFloat = 8

    // MARK: - CharacterFaceNode (CharacterSelectScene 5장 카드 위 얼굴)
    /// 5장 카드 위 얼굴 노드의 zPosition. 글래스 컨테이너(90) < 카드(100) < CharacterFaceNode(105) < 색 점/태그(110).
    static let characterFaceZPosition: CGFloat = 105

    // MARK: - Sprint 7 Phase G · Player Facing (4방향 child)
    /// PlayerNode 자체 텍스처(zPos 0) 위에 face child를 얹기 위한 작은 양수 zPosition.
    static let playerFaceChildZPosition: CGFloat = 1

    // MARK: - Sprint 8 Phase F · HUD zPos V4
    //
    // 좌하단 영역 시각 적층 명확화: HUDSkillSlotNode 라벨 > HUD 일반 라벨 > SkillButton 본체.
    // 슬롯 라벨이 가장 위(110) — 스킬 이름·CD 단일 진실 원천.
    // HUD 일반 라벨(100) — 점수/타이머/콤보 등.
    // SkillButton 본체(80) — 좌하단 큰 코랄 원, "B" 칩만 노출.

    /// HUD 일반 라벨 zPosition(100). HUDNode 점수/타이머/콤보 라벨에 적용.
    static let hudLabelZPosition: CGFloat = 100
    /// SkillButtonNode 본체 zPosition(80). HUDSkillSlotNode(110)·HUD 라벨(100) 아래.
    static let skillButtonZPosition: CGFloat = 80
    /// HUDSkillSlotNode 슬롯 라벨 zPosition(110). 스킬 이름/CD 단일 진실 원천 — 가장 위.
    static let hudSkillSlotLabelZPosition: CGFloat = 110

    // MARK: - Sprint 8 Phase G · 인게임 시각 통합 V4
    /// 컷씬 등장 플래시 zPosition(301). overlay(300) 위. HitFlash 본체(200) 미간섭.
    static let sergeantParkIntroFlashZPosition: CGFloat = 301

    // MARK: - Sprint 9 Phase C · Enemy Visual & Countdown V9
    // 빌런 3종 시각 자식(halo/chart/clip/stethoDisc/tube/armor/eye)을 일괄 1.4배 확대해
    // 시뮬레이터 화면에서 24pt 이상 식별 면적 확보. physicsBody는 본체 size 기준이라 회귀 0.
    // 카운트다운 zPos 250→300, dim alpha 0.32→0.22, dim zPos 240→290 — 항상 정중앙에 또렷이 표시.
    /// CountdownNode zPosition V9(300). 기존 250보다 위 — HitFlash(200) 위 보장 + UI 잔존 노드와 충돌 회피.
    static let countdownNodeZPosition: CGFloat = 300
    /// 카운트다운 dim zPosition V9(290). CountdownNode(300) 바로 아래 — 숫자가 dim 위에 또렷이 표시.
    static let countdownDimZPosition: CGFloat = 290

    // MARK: - Design Sprint 1 Ingame Readability
    static let hospitalPropZPosition: CGFloat = -1

    // MARK: - Sprint 10 Phase G · Airforce Easter Egg Pixel Tone
    /// 박병장 클로즈업 노드 zPosition. AirforceOverlayNode(200) 위, BombFlashNode(250) 아래.
    /// 컷씬 t≤2.4 fadeOut 완료 후 비행기/폭탄 등장 — 겹침 0.
    static let sergeantCloseupZPosition: CGFloat = 210

    // MARK: - Sprint 10 Phase J · Pixel HUD/Effect Tokens (마지막 Phase)
    /// 비네트 zPosition. HUD(100~101) 위 + countdownZPosition(250 ~ 300) 아래 → 인게임 중 HUD를
    /// 살짝 덮되 카운트다운/플래시는 안 가림.
    static let tensionVignetteZPosition: CGFloat = 110

    // MARK: - Sprint 2 Character Account Home

    static let characterHomeBackgroundZPosition: CGFloat = -20
    static let characterHomePanelZPosition: CGFloat = 90
    static let characterHomeCharacterZPosition: CGFloat = 130
    static let characterHomeMenuZPosition: CGFloat = 160
    static let characterHomeButtonZPosition: CGFloat = 170
}
