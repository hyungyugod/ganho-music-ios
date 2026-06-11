//
//  FeelTuning+R2.swift
//  GanhoMusic Shared
//
//  R2 "게임필 (juice)" — 히트스톱·카메라 v2·파티클 6종·마이크로 모션·칩튠 SFX·햅틱 v2 상수.
//  수치 원칙: refactor/02_GAME_FEEL.md 명세가 기본값 (±20% 내 튜닝만 Generator 재량).
//

import Foundation
import CoreGraphics

// MARK: - R2 게임필 상수 (02_GAME_FEEL §2~§6)
extension FeelTuning {

    // MARK: Hitstop (02 §2)
    /// 콤보 마일스톤(5·7·10·20) 정지 시간 (초).
    static let hitstopComboMilestone: TimeInterval = 0.045
    /// F 피격(게임오버)·청진기 피격(동결) 정지 시간 (초).
    static let hitstopFatalFreeze: TimeInterval = 0.10
    /// F 피격 후 physicsWorld.speed 0→1 복귀 램프 길이 (초).
    static let hitstopFatalRamp: TimeInterval = 0.25
    /// 박병장 폭탄 섬광 정지 시간 (초).
    static let hitstopBombFlash: TimeInterval = 0.12
    /// 변기(+2) 수집 정지 시간 (초).
    static let hitstopToiletCollect: TimeInterval = 0.03
    /// R10 #8 — 일반 음표 수집 미니 정지 시간 (초). 약 1프레임 — 수집 "딱" 체감만 더하고
    /// 흐름은 유지. 02 §2 "일반 수집 히트스톱 없음" 조항은 R10에서 동반 갱신 (명세 충돌 해소).
    /// longer-wins 합성은 기존 HitstopController 그대로 — 변기(0.03)·마일스톤(0.045)과 겹치면 긴 쪽.
    static let hitstopNoteCollect: TimeInterval = 0.015
    /// 히트스톱·줌 펄스가 발화되는 콤보 마일스톤. 마일스톤 3은 기존 팝업/사운드만
    /// (SPEC §문서-코드 불일치 1 — comboMilestones [3,5,7,10,20] 중 3 제외).
    static let comboHitstopMilestones: [Int] = [5, 7, 10, 20]

    // MARK: Camera v2 (02 §3)
    /// 지수 보간 추적 계수 — lerp(cam, player, 1 - exp(-8.5 × dt)).
    static let cameraFollowLerpRate: Double = 8.5
    /// 셰이크 soft 진폭 (±pt) / 길이 (초).
    static let cameraShakeSoftAmplitude: CGFloat = 3
    static let cameraShakeSoftDuration: TimeInterval = 0.15
    /// 셰이크 medium 진폭 (±pt) / 길이 (초).
    static let cameraShakeMediumAmplitude: CGFloat = 6
    static let cameraShakeMediumDuration: TimeInterval = 0.22
    /// 셰이크 strong 진폭 (±pt) / 길이 (초).
    static let cameraShakeStrongAmplitude: CGFloat = 10
    static let cameraShakeStrongDuration: TimeInterval = 0.32
    /// 매 스텝 진폭 감쇠 배율 (02 §3 — 0.82).
    static let cameraShakeDecayPerStep: CGFloat = 0.82
    /// 감쇠 1스텝의 기준 길이 (초). 프레임레이트와 무관하게 pow(0.82, dt/step)로 적용.
    static let cameraShakeDecayReferenceStep: TimeInterval = 1.0 / 60.0
    /// 셰이크 종료 판정 진폭 하한 (pt). 이 밑으로 감쇠하면 오프셋 0 고정.
    static let cameraShakeMinAmplitude: CGFloat = 0.1
    /// 방향성 킥 거리 (pt) / 왕복 길이 (초).
    static let cameraKickDistance: CGFloat = 4
    static let cameraKickDuration: TimeInterval = 0.12
    /// 콤보 마일스톤 줌 펄스 — scale 1.0→1.015→1.0 (0.18s).
    static let cameraZoomPulseScale: CGFloat = 1.015
    static let cameraZoomPulseDuration: TimeInterval = 0.18
    /// 박병장 등장 줌 펄스 — scale 1.0→0.97→1.0 (0.5s).
    static let sergeantZoomPulseScale: CGFloat = 0.97
    static let sergeantZoomPulseDuration: TimeInterval = 0.5
    /// 줌 펄스 SKAction 키 — withKey 멱등(같은 키 재호출 시 자동 교체).
    static let cameraZoomPulseActionKey: String = "cameraZoomPulse"

    // MARK: Particles (02 §4)
    /// 동시 활성 이미터 상한 (02 §1 예산). 초과 시 우선순위 낮은 것부터 스킵.
    static let maxConcurrentEmitters: Int = 8
    /// 입자 텍셀 한 변 (px). 2×2~4×4 단색 사각 (픽셀 톤).
    static let particleTexelSide: CGFloat = 3
    /// burst 이미터의 전량 방출 시간창 (초). birthRate = count / window.
    static let particleBurstEmitWindow: TimeInterval = 0.05
    /// collectBurst — 10개(명세 8~12), 속도 40~90 px/s(65±25), 0.35s, gold.
    static let collectBurstCount: Int = 10
    static let collectBurstSpeed: CGFloat = 65
    static let collectBurstSpeedRange: CGFloat = 50
    static let collectBurstLifetime: TimeInterval = 0.35
    /// collectBurst 풀 크기 — 연속 수집(콤보 윈도우 2.5s 내 다발) 흡수.
    static let collectBurstPoolCount: Int = 3
    /// comboAura — 콤보 ≥5 동안 플레이어 발밑 4개/s 상승.
    static let comboAuraActiveThreshold: Int = 5
    static let comboAuraBirthRate: CGFloat = 4
    static let comboAuraLifetime: TimeInterval = 0.8
    static let comboAuraRiseSpeed: CGFloat = 22
    /// comboAura 단계 색 임계 — 5=gold / 7=coral / 10+=violet.
    static let comboAuraTierCoral: Int = 7
    static let comboAuraTierViolet: Int = 10
    /// comboAura 발밑 y 오프셋 (pt). 플레이어 시각 높이 40pt의 절반 근처.
    static let comboAuraFootOffsetY: CGFloat = 18
    /// deathBurst — 24개, 0.6s, coral+white 혼합, 중력 -60.
    static let deathBurstCount: Int = 24
    static let deathBurstLifetime: TimeInterval = 0.6
    static let deathBurstGravityY: CGFloat = -60
    static let deathBurstSpeed: CGFloat = 80
    static let deathBurstSpeedRange: CGFloat = 60
    /// toiletSplash — 10개, mint, 0.3s. 위로 튀는 물보라 부채꼴 + 약한 낙하.
    static let toiletSplashCount: Int = 10
    static let toiletSplashLifetime: TimeInterval = 0.3
    static let toiletSplashSpeed: CGFloat = 75
    static let toiletSplashSpeedRange: CGFloat = 40
    static let toiletSplashSpreadRadians: CGFloat = 1.6
    static let toiletSplashGravityY: CGFloat = -80
    /// milestoneConfetti — 화면 상단에서 16개 낙하, 1.0s, 3색 혼합.
    static let milestoneConfettiCount: Int = 16
    static let milestoneConfettiLifetime: TimeInterval = 1.0
    static let milestoneConfettiFallSpeed: CGFloat = 150
    static let milestoneConfettiSpeedRange: CGFloat = 60
    static let milestoneConfettiSpinSpeed: CGFloat = 6
    /// confetti 가로 분산 폭 비율 (화면 폭 ×).
    static let milestoneConfettiWidthRatio: CGFloat = 0.8
    /// confetti 시작점이 화면 상단에서 안쪽으로 들어오는 거리 (pt).
    static let milestoneConfettiTopInset: CGFloat = 10
    /// skillSignature — 돌진 후방 트레일 입자 수/수명.
    static let skillTrailCount: Int = 20
    static let skillTrailLifetime: TimeInterval = 0.3
    static let skillTrailSpeed: CGFloat = 50
    /// skillSignature — 워프 출발·도착 쌍둥이 burst 입자 수/수명.
    static let skillWarpBurstCount: Int = 12
    static let skillWarpBurstLifetime: TimeInterval = 0.3
    static let skillWarpBurstSpeed: CGFloat = 70
    static let skillWarpBurstSpeedRange: CGFloat = 40
    /// skillSignature — 소집 수렴(근사: 반경 분산 스폰 + 수축 스케일) 입자 수/수명/분산 반경 비율.
    static let skillRallyCount: Int = 14
    static let skillRallyLifetime: TimeInterval = 0.4
    static let skillRallyDriftSpeed: CGFloat = 25
    static let skillRallyScaleSpeed: CGFloat = -2.2
    static let skillRallySpawnRadiusRatio: CGFloat = 0.5
    /// skillSignature — 모범생 상승 하트 6개 (단순 입자 갈음 — 픽셀 톤 유지).
    static let skillHeartCount: Int = 6
    static let skillHeartLifetime: TimeInterval = 0.8
    static let skillHeartRiseSpeed: CGFloat = 45
    static let skillHeartRiseAcceleration: CGFloat = 20
    static let skillHeartSpreadRadians: CGFloat = 0.5
    static let skillHeartScale: CGFloat = 1.5
    /// 입자 공통 — 수명 끝 알파 소멸 비율 가속(알파 속도 = -1/lifetime × 이 배율).
    static let particleAlphaDecayMultiplier: CGFloat = 1.0

    // MARK: Micro Motion (02 §5)
    /// 플레이어 이동 시작 스쿼시 (0.92x, 1.08y) 0.08s → 복원. 정지 시 반대.
    static let squashMoveScaleX: CGFloat = 0.92
    static let squashMoveScaleY: CGFloat = 1.08
    static let squashDuration: TimeInterval = 0.08
    static let squashActionKey: String = "playerMoveSquash"
    /// 음표 수집 직전 팝 배율/길이 (1.15배 후 소멸).
    static let noteCollectPopScale: CGFloat = 1.15
    static let noteCollectPopDuration: TimeInterval = 0.10
    /// 수집 자석 — 32px(중심 간) 내 진입 시 0.08s 동안 흡인. 판정은 physics contact 불변.
    static let noteMagnetRadius: CGFloat = 32
    static let noteMagnetDuration: TimeInterval = 0.08
    /// 걷기 먼지 — 4걸음(walk frame 토글 4회)마다 발밑 2px 사각 2개 0.25s 페이드.
    static let walkDustStepInterval: Int = 4
    static let walkDustSquareSide: CGFloat = 2
    static let walkDustFadeDuration: TimeInterval = 0.25
    /// 먼지 사각 2개의 좌우 간격 절반 (pt).
    static let walkDustHalfGap: CGFloat = 3
    static let walkDustStartAlpha: CGFloat = 0.5
    /// 먼지 풀 예열 수 — 보행 주기상 동시 잔존 최대 2~3개의 여유분.
    static let walkDustPoolPreheatCount: Int = 6
    /// 먼지 y 오프셋 — 플레이어 시각 바닥에서 살짝 위 (pt).
    static let walkDustFootOffsetY: CGFloat = 2

    // MARK: Game Over 연출 (SPEC §문서-코드 불일치 7)
    /// endGame → ResultScene presentScene 지연 (초). deathBurst(0.6s)·히트스톱 램프(0.35s) 가시화.
    /// 저장/클라우드 로직은 즉시 수행 — presentScene만 SKAction.wait 경유.
    static let gameOverTransitionDelay: TimeInterval = 0.9

    // MARK: Haptics v2 (02 §6)
    /// 텔레그래프 경고 햅틱 발화 거리 — 발사원-플레이어 ≤ 이 값일 때 1회 (pt).
    static let telegraphHapticDistance: CGFloat = 180
    static let hapticNoteIntensity: Float = 0.45
    static let hapticNoteSharpness: Float = 0.7
    static let hapticToiletIntensity: Float = 0.7
    static let hapticMilestoneIntensity: Float = 0.9
    static let hapticTelegraphIntensity: Float = 0.3
    /// "심장 박동" — transient 0.3 ×2의 간격 (초). 패턴 내 relativeTime으로 구현.
    static let hapticTelegraphGap: TimeInterval = 0.08
    static let hapticGameOverTransientIntensity: Float = 1.0
    static let hapticGameOverContinuousIntensity: Float = 0.5
    static let hapticGameOverContinuousDuration: TimeInterval = 0.3
    static let hapticSkillIntensity: Float = 0.8
    static let hapticSkillSharpness: Float = 1.0
    static let hapticUITapIntensity: Float = 0.35
    static let hapticStarPopIntensity: Float = 0.6
    /// 표에 sharpness 명시가 없는 이벤트의 기본 sharpness.
    static let hapticDefaultSharpness: Float = 0.5

    // MARK: ChiptuneSynth (02 §6)
    static let sfxSampleRate: Double = 44_100
    /// 전 voice 공통 마스터 게인 (0~1). 8비트 톤이 BGM/햅틱을 압도하지 않는 수준.
    static let sfxMasterGain: Float = 0.22
    /// 클릭 노이즈 방지 어택 (초) / 테일 페이드 비율 (voice 길이 대비).
    static let sfxAttackDuration: TimeInterval = 0.004
    static let sfxReleaseRatio: Double = 0.25
    /// voice 길이 (초) — 02 §6 표 그대로.
    static let sfxCollectDuration: TimeInterval = 0.060
    static let sfxToiletDuration: TimeInterval = 0.110
    static let sfxMilestoneDuration: TimeInterval = 0.180
    static let sfxComboBreakDuration: TimeInterval = 0.150
    static let sfxHitDuration: TimeInterval = 0.400
    static let sfxUITapDuration: TimeInterval = 0.035
    static let sfxStarDuration: TimeInterval = 0.120
    static let sfxCountdownTickDuration: TimeInterval = 0.050
    static let sfxCountdownGoDuration: TimeInterval = 0.200
    /// 콤보 피치 상승 상한 (+반음). C5 시작, 콤보 1단계당 +반음, 최대 +12.
    static let sfxCollectPitchMaxSemitone: Int = 12
    /// MIDI 노트 번호 — 주파수 = 440 × 2^((midi-69)/12).
    static let sfxMidiC4: Int = 60
    static let sfxMidiG4: Int = 67
    static let sfxMidiA4: Int = 69
    static let sfxMidiC5: Int = 72
    static let sfxMidiE5: Int = 76
    static let sfxMidiG5: Int = 79
    static let sfxMidiA5: Int = 81
    static let sfxMidiC6: Int = 84
    static let sfxMidiE6: Int = 88
    static let sfxMidiG6: Int = 91
    /// 피격 voice — square 하강 글라이드 시작/끝 주파수 (Hz) + noise 혼합비.
    static let sfxHitStartFrequency: Double = 220
    static let sfxHitEndFrequency: Double = 70
    static let sfxHitNoiseMix: Float = 0.5
    /// 동시 발음용 AVAudioPlayerNode 라운드로빈 풀 크기.
    static let sfxPlayerNodeCount: Int = 4
}
