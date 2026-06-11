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
    // R8 — newBestZPosition: 참조 0 실증 후 삭제 (R5 ResultScene v3가 칩 연출로 대체).

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
    /// 졸업장 zPosition. cutsceneZPosition(300)과 동급 — 결과 칩 연출(150 계열) 위로 자연 겹침.
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

    // MARK: - Account Menu Overlay
    // R8 — accountMenuDim/Panel/Label/Button 4종: 참조 0 실증 후 삭제 (R5 오버레이 v3
    // 재구축의 잔여 내부 적층 토큰 — AccountMenuOverlayNode가 내부 enum으로 자체 관리).
    static let accountMenuOverlayZPosition: CGFloat = 500

    // MARK: - Profile Avatar
    // R8 — profileAvatarFrame/Content 2종: 참조 0 실증 후 삭제 (R5 프로필 v3 잔여).

    // MARK: - Profile Detail Overlay
    // R8 — profileDetailDim/Panel/Label/Button 4종: 참조 0 실증 후 삭제 (동상).
    static let profileDetailOverlayZPosition: CGFloat = 540

    // MARK: - Sprint 5 · ResultScene v2 Layout
    // R8 — resultShareToastZPosition: 참조 0 실증 후 삭제 (v2 공유 토스트 폐기 잔여).
    /// 종이 카드 zPosition(노드 좌표계 내부). background(0) 위 + 도트 패턴(0.7) 아래.
    static let diplomaPaperZPosition: CGFloat = 0.5
    /// 도트 패턴 zPosition. paperCard(0.5) 위 + 라벨(1) 아래.
    static let diplomaDotsZPosition: CGFloat = 0.7
    /// 코너 데코 zPosition. 도트 패턴(0.7) 위 + 라벨(1) 아래.
    static let diplomaCornerDecoZPosition: CGFloat = 0.8
    /// 도장 zPosition. 라벨(1) 위.
    static let diplomaStampZPosition: CGFloat = 1.2

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

    // MARK: - R8 일시정지 다이얼로그
    /// 일시정지 PixelDialogNode zPosition. 구 v2 오버레이 z(420) 의미 보존 —
    /// HitFlash(200)·컷씬(300) 위. 기본 Layer.overlay(200)를 오버라이드.
    static let pauseDialogZPosition: CGFloat = 420

    // MARK: - R9 인게임 설정 다이얼로그
    /// 일시정지 [설정] 경유 SettingsDialogNode zPosition.
    /// pauseDialog(420) 초과 — 일시정지 딤/버튼 위 + profileDetailOverlay(540) 미만.
    static let settingsDialogZPosition: CGFloat = 430

    // MARK: - R2 게임필 (juice)
    /// 인게임 파티클 이미터 zPosition (worldNode 소속 — collectBurst/comboAura/deathBurst/
    /// toiletSplash/skillSignature). sparkle(30)과 동급 — Player/Enemy(5) 위, HUD(100) 아래.
    static let ingameParticleZPosition: CGFloat = 30
    /// milestoneConfetti zPosition (cameraNode 소속 — 화면 고정). HUD(100) 위, BREAK(140) 아래.
    static let milestoneConfettiZPosition: CGFloat = 130
    /// 걷기 먼지 zPosition (worldNode 소속). 바닥(-100)·벽(-50 계층) 위, Player(0) 아래.
    static let walkDustZPosition: CGFloat = -1

    // MARK: - Sprint 2 Character Account Home
    // R8 — characterHomeCharacterZPosition: 참조 0 실증 후 삭제 (v2 캐릭터 홈 폐기 잔여).
}

// MARK: - R3 디자인 시스템 v3 "Night Shift" Layer (03_UI §4)
//
// R3 신설 — 신규 v3 컴포넌트 전용. 기존 노드 마이그레이션은 R4·R5(씬 재구축)·R8(감사).
// 기존 상수(오버레이 z 500~540 등)는 무변경 — v3 토큰은 *추가만* (R3 합격 게이트).
extension ZOrder {
    /// v3 적층 11층 — 전 v3 컴포넌트가 이 토큰만 사용.
    /// R8 감사 — collectibles는 현재 0참조이나 *보존*: 03_UI §4 적층 11층 설계 계약의
    /// 구성 요소 (부분 삭제 시 층 의미 붕괴 — 인게임 노드의 v3 층 이행 시 소비 예정).
    enum Layer {
        static let bg: CGFloat = 0
        static let floor: CGFloat = 10
        static let props: CGFloat = 20
        static let collectibles: CGFloat = 30
        static let characters: CGFloat = 40
        static let projectiles: CGFloat = 50
        static let effects: CGFloat = 60
        static let vignette: CGFloat = 80
        static let hud: CGFloat = 100
        static let overlay: CGFloat = 200
        static let transition: CGFloat = 300
    }
}
