//
//  FeelTuning.swift
//  GanhoMusic Shared
//
//  R0 — 구 god-config(분할 전 단일 Config) 분해: 셰이크·플래시·팝업·페이드·카운트다운·텐션 등 연출 수치 + 연출 문구·SKAction 키.
//  값은 분할 전과 byte-equal — R0는 위치 이동만 (행동 불변).
//

import Foundation
import CoreGraphics

/// 게임필(연출) 튜닝 상수 네임스페이스 — 화면 연출 타이밍·강도·문구·SKAction 키.
/// case 없는 enum: 인스턴스화 차단 (왜: R2 게임필 튜닝의 단일 진입점 확보).
enum FeelTuning {
    // MARK: - Scene Transition (Phase 3-1+2)
    /// 씬 전환 fade 길이 (초). TitleScene ↔ GameScene 양방향 공용.
    static let sceneTransitionDuration: TimeInterval = 0.4

    // MARK: - Airforce Easter Egg (Phase 4-3)
    /// 비행기 좌→우 가로지르기 duration (초). 너무 빠르면 못 보고, 너무 느리면 게임 방해.
    static let airplaneCrossDuration: TimeInterval = 2.0
    /// 화면 상단에서 비행기 y 위치까지의 거리 (pt). cameraNode 자식 좌표계: y = +(halfH - 60).
    static let airplaneTopOffset: CGFloat = 60
    /// "나와라 박병장!" 오버레이 폰트 크기 (pt). HUD(18)보다 크고 화면 중앙 가독성 우선.
    static let airforceOverlayFontSize: CGFloat = 28
    static let airforceStoryTitle: String = "박병장 호출"
    static let airforceStoryBody: String = "사실 박병장은 석조무사의 오랜 친구입니다.\n석조무사가 조용히 신호를 보내자, 박병장이 나타나 잠시 수간호사를 물리쳐 줍니다."
    /// "나와라 박병장!" 오버레이 표시 시간 (초). 페이드아웃 시작 전 또렷이 떠 있는 구간.
    /// Phase 9-8 — 사용자 요청 시퀀스 "오버레이 2.4초 유지" 정합화: 1.5 → 2.1.
    /// 총 수명 = displayDuration(2.1) + fadeOutDuration(0.3) = 2.4초.
    static let airforceOverlayDisplayDuration: TimeInterval = 2.1
    /// "나와라 박병장!" 오버레이 페이드아웃 길이 (초). alpha 1 → 0 보간 시간.
    /// 총 수명 = displayDuration(2.1) + fadeOutDuration(0.3) = 2.4초.
    static let airforceOverlayFadeOutDuration: TimeInterval = 0.3
    /// Phase 9-8 — 비행기 등장 지연(trigger 시점 t=0 기준).
    /// 오버레이 완전 소멸 = displayDuration(2.1) + fadeOutDuration(0.3) = 2.4초.
    /// 이 시점에 비행기가 화면 좌측에서 등장 → 우측까지 airplaneCrossDuration(2.0)초 가로지름.
    static let airplaneDelayAfterOverlay: TimeInterval = 2.4
    /// 폭탄 화면 플래시 시작 지연 (초). trigger 시점 t=0 기준.
    /// Phase 9-8 — 사용자 요청 시퀀스 정합화: 2.1 → 3.4.
    /// 비행기 중앙 도달 시점 = airplaneDelayAfterOverlay(2.4) + airplaneCrossDuration(2.0)/2 = 3.4초.
    static let bombFlashDelay: TimeInterval = 3.4
    /// 폭탄 화면 플래시 fadeIn 길이 (초). alpha 0 → 1 빠른 보간 — *번쩍* 임팩트.
    static let bombFlashFadeInDuration: TimeInterval = 0.07
    /// 폭탄 화면 플래시 fadeOut 길이 (초). alpha 1 → 0 느린 보간 — *잔상* 효과.
    /// 총 표시 길이 = fadeIn(0.07) + fadeOut(0.35) = 0.42초.
    static let bombFlashFadeOutDuration: TimeInterval = 0.35

    // MARK: - BGM Fade (Phase 6-5)
    /// Phase 6-5 — BGM 페이드 인 길이 (초). play() 호출 시 volume 0 → 1.0 보간.
    /// 첫 음표 스폰 주기(1.5)와 자연 동기화되도록 1.5초 채택.
    static let bgmFadeInDuration: TimeInterval = 1.5
    /// Phase 6-5 — BGM 페이드 아웃 길이 (초). stop() 호출 시 현재 volume → 0 보간.
    /// ResultScene 전환 페이드(0.4)보다 길어 두 페이드가 겹치며 끝나도록 1.0초.
    static let bgmFadeOutDuration: TimeInterval = 1.0

    // MARK: - Sparkle Effect (Phase 6-8)
    /// 음표 수집 시 방사되는 sparkle 파편 개수. 8방향 균등 방사 — 정팔각형.
    /// 4면 너무 빈약, 16면 시각 노이즈. 8이 균형점. GDD: 음악=별 미학.
    static let sparkleParticleCount: Int = 8
    /// sparkle 파편 1개의 반지름 (pt). 음표 한 변(16)의 1/8 = 2.0pt. 작은 별빛 입자 톤.
    static let sparkleParticleRadius: CGFloat = 2.0
    /// sparkle 방사 거리 (pt). 노트 중심에서 파편이 도달하는 최대 거리.
    /// 음표 한 변(16)의 ~1.5배 = 24pt. 너무 멀면 인접 음표와 겹침, 가까우면 임팩트 약함.
    static let sparkleSpawnDistance: CGFloat = 24
    /// sparkle 페이드/이동 액션 총 길이 (초). group 액션 묶음의 duration.
    /// 너무 길면 다음 음표 수집과 겹쳐 시각 노이즈. 0.5초가 *반짝*의 적정선.
    static let sparkleFadeDuration: TimeInterval = 0.5
    /// sparkle 파편의 끝 스케일. 0.0이면 한 점으로 수렴(별빛 꺼짐), 1.0이면 동일 크기 유지.
    /// 0.2면 페이드아웃 + 살짝 축소 — 별이 멀어지는 느낌.
    static let sparkleEndScale: CGFloat = 0.2

    // MARK: - Hit Feedback (Phase 6-9)
    // R2 — 구 cameraShakeAmplitude/StepCount/StepDuration 3종은 구 셰이크 SKAction 빌더 삭제와 함께 제거.
    // 셰이크 v2(soft/medium/strong 감쇠형)는 FeelTuning+R2.swift가 단일 진실 원천.
    /// 피격 플래시 alpha 피크 (0~1). 0.55 = 반투명 빨강 — 시야 차단 방지, *맞았다* 명확.
    static let hitFlashPeakAlpha: CGFloat = 0.55
    /// 피격 플래시 fadeIn 길이 (초). 빠르게 등장 — *번쩍* 임팩트.
    static let hitFlashFadeInDuration: TimeInterval = 0.05
    /// 피격 플래시 fadeOut 길이 (초). 천천히 사라짐 — *잔상* 효과.
    /// 총 노출 = fadeIn(0.05) + fadeOut(0.25) = 0.30초 ≈ 셰이크(0.28) 동기.
    static let hitFlashFadeOutDuration: TimeInterval = 0.25

    // MARK: - Combo Popup (Phase 6-10)
    /// 콤보 마일스톤 발화 임계값 목록. 한 판 내 같은 마일스톤은 1회만 발화(멱등).
    /// 7 = 최고 가산점 진입. 20 = 클라이맥스.
    static let comboMilestones: [Int] = [3, 5, 7, 10, 20]
    /// 콤보 팝업이 위로 떠오르는 거리 (pt). 별이 하늘로 올라가는 톤.
    static let comboPopupFlyUpDistance: CGFloat = 80
    /// 팝업 1회 표시 총 길이 (초). group 액션(move + fade + scale) 묶음 duration.
    /// sparkle(0.5)보다 길고 airforceOverlay(1.5)보다 짧음 — 마일스톤 강조와 게임플레이 방해의 균형점.
    static let comboPopupDuration: TimeInterval = 1.0
    /// 팝업 끝 스케일. 1.0 시작 → 1.4 끝 = 페이드아웃과 동시에 *별이 터지듯* 확대.
    /// SparkleEndScale(0.2 축소)과 반대 — 마일스톤은 *확산*되는 느낌, sparkle은 *수렴*되는 입자.
    static let comboPopupEndScale: CGFloat = 1.4

    // MARK: - Combo Break (Phase 6-12)
    /// 콤보 끊김 시 BREAK 시각 발화 임계값. 이 값 이상의 콤보에서 0으로 떨어졌을 때만 발화.
    /// 7 = 최고 가산점 구간 손실을 체감시키는 지점.
    static let comboBreakThreshold: Int = 7
    /// BREAK가 아래로 떨어지는 거리 (pt). comboPopupFlyUpDistance(80)보다 짧음 — *떨어짐*은 짧고 단호.
    static let comboBreakFallDistance: CGFloat = 60
    /// BREAK 1회 표시 총 길이 (초). comboPopupDuration(1.0)과 동일 — 환호/실망 시간축 대칭.
    static let comboBreakDuration: TimeInterval = 1.0
    /// BREAK 끝 스케일. 1.0 시작 → 0.7 끝. comboPopupEndScale(1.4 확대)와 반대 — 실망은 *축소*(수축의 톤).
    static let comboBreakEndScale: CGFloat = 0.7

    // MARK: - Milestone Banner (Score Progress)
    /// 절반(A) 마일스톤 안내 접미사. 호출부에서 "\(remaining)" + 이 접미사로 조립한다.
    /// 남은 개수는 발화 시점 실제값(target-score)이라 난이도별로 자동 반응
    /// (하드 target 40 → 절반 score≥20 → remaining≈20 → "20개만 더 모아봐요!").
    static let milestoneHalfSuffix: String = "개만 더 모아봐요!"
    /// 목표 임박(B) 마일스톤 안내 문구. 점수가 목표-10점 이상에 도달했을 때 1회 표시.
    static let milestoneNearText: String = "10점만 더!"
    /// B 마일스톤 임계 = 졸업 목표 - 이 값(점). 10점 남았을 때 발화.
    static let milestoneNearTargetRemaining: Int = 10
    /// 마일스톤 배너 글자 크기 (pt). comboPopupFontSize(48)보다 작게 — 흐름을 가리지 않는 조용한 격려.
    static let milestoneBannerFontSize: CGFloat = 26
    /// 배너 fadeIn / fadeOut 각각의 길이 (초). 부드럽게 등장·퇴장.
    static let milestoneBannerFadeDuration: TimeInterval = 0.3
    /// 배너 hold 길이 (초). 총 노출 ≈ fadeIn(0.3) + hold(0.9) + fadeOut(0.3) = 1.5초.
    static let milestoneBannerHoldDuration: TimeInterval = 0.9
    /// 배너 화면 상단 중앙 y 오프셋 (pt). cameraNode 자식 기준 (0,0)=화면 중앙, +y=위.
    /// HUD 슬롯 행(화면 최상단)보다 충분히 아래(상단 1/4 부근)에 둬 슬롯과 시각적으로 겹치지 않게 한다.
    static let milestoneBannerOffsetY: CGFloat = 120

    // MARK: - Countdown (Phase 6-13)
    /// 카운트다운 숫자/GO! 폰트 크기 (pt). comboPopup(48)의 2배 — 화면 중앙 단독 강조.
    static let countdownFontSize: CGFloat = 96
    /// 한 단계(3/2/1/GO!) fadeIn 길이 (초). 빠르게 등장.
    static let countdownFadeInDuration: TimeInterval = 0.1
    /// 한 단계 *holding* 길이 (초). 또렷이 보이는 구간.
    static let countdownHoldDuration: TimeInterval = 0.7
    /// 한 단계 fadeOut 길이 (초). 다음 단계 등장 전 사라짐.
    static let countdownFadeOutDuration: TimeInterval = 0.2
    /// GO! 단계 fadeOut 길이 (초). 일반 단계보다 살짝 길게 — 시작의 잔향.
    static let countdownGoFadeOutDuration: TimeInterval = 0.4
    /// GO! holding 길이 (초). 일반(0.7)보다 짧게 — 스케일 펄스 + 빠른 페이드아웃이 시간 채움.
    static let countdownGoHoldDuration: TimeInterval = 0.5

    // MARK: - Countdown V3 (Sprint 7 Phase E)
    /// V3 카운트다운 숫자(3·2·1) 폰트 크기 (pt). V2 96 → 120 — 화면 중앙 단독 강조 + v3 위계 강화.
    static let countdownNumberFontSize: CGFloat = 120
    /// V3 GO! 폰트 크기 (pt). 숫자(120)보다 큼 — "출발의 폭발" 톤, 마지막 단계 임팩트.
    static let countdownGoFontSize: CGFloat = 140
    /// V3 GO! scale 시작값. V2 1.0 → 1.2 — 등장부터 임팩트.
    static let countdownGoStartScale: CGFloat = 1.2
    /// V3 GO! scale 끝값. V2 1.3 → 1.8 — 더 큰 펄스 (시작의 잔향).
    static let countdownGoEndScale: CGFloat = 1.8
    /// V3 dim 페이드인 길이 (초). 카운트다운 등장과 동기 — 0.2s 자연 어두워짐.
    static let countdownDimFadeInDuration: TimeInterval = 0.2
    /// V3 dim 페이드아웃 길이 (초). GO! 종료 직후 0.2s 자연 밝아짐 → startGameProperly 진입.
    static let countdownDimFadeOutDuration: TimeInterval = 0.2
    /// V3 dim 노드 name — 디버그/회귀 검증/명시적 lookup용.
    static let countdownDimNodeName: String = "countdownDim"

    // MARK: - Tension (Phase 6-14)
    /// 5초 긴박감 발화 시작 임계값 (초). remainingTime이 이 값 이하로 떨어지면 폴링 진입.
    /// 6-13 카운트다운(출발의 개봉감)과 시간 대칭 — 시작·끝의 톤이 짝을 이룬다.
    static let tensionWindow: TimeInterval = 5.0
    /// BGM rate 시작값 (1.0 = 원본). AVAudioPlayer.rate 타입에 맞춰 Float.
    static let tensionRateBase: Float = 1.0
    /// BGM rate 최대값 (1.15 = 영상 빨리감기 톤, 피치 포함). 0.5~2.0 권장 범위 중 안전.
    /// 1.15는 *체감되지만 곡 식별성 유지* 균형점 — Float 타입(AVAudioPlayer.rate 일치).
    static let tensionRateMax: Float = 1.15
    /// R1 — tension rate 전송 양자화 스텝. 보간값이 매 프레임 연속이라 단순 "값 변화 가드"가
    /// 무효 → 0.01 단위 반올림 양자화 후 직전 전송값과 다를 때만 setRate 호출.
    /// 1.0→1.15 구간 전송 최대 16회(구 매 프레임 ≈300회). 스텝이 전체 변화폭의 1/15 — 청감 차이 0.
    /// 반올림(.rounded()) 채택 — 내림이면 Float 정밀도로 종료 근방 1.15 도달이 1.14에 머무는 사고 방지.
    static let tensionRateQuantizeStep: Float = 0.01
    /// 깜빡임 한 색 머무는 길이 (초). 총 1초 주기 = 빨강 0.5 + 원색 0.5.
    /// 매초 정수 변화(5→4→3→2→1)와 *심박* 톤이 자연 동기.
    static let tensionBlinkHalfPeriod: TimeInterval = 0.5
    /// HUDNode timeLabel 깜빡임 SKAction 키. 중복 호출 시 자동 교체(멱등) 보장.
    /// withKey로 부착하면 SpriteKit이 같은 키의 이전 액션을 자동 제거 → 자연 멱등.
    static let tensionBlinkActionKey: String = "tensionBlink"

    // MARK: - New Best (Phase 6-15)
    /// 화면 중앙 신기록 보상 라벨 폰트 크기 (pt). resultScoreFontSize(24)보다 큼, countdownFontSize(96)보단 작음.
    static let newBestFontSize: CGFloat = 56
    /// frame.midY 기준 신기록 보상 라벨 Y 오프셋. 0 = 정중앙.
    static let newBestOffsetY: CGFloat = 0
    /// ResultScene 진입 후 신기록 보상 발화까지 지연 (초). fade transition(0.4s) 끝나고 score 인지 후 등장.
    static let newBestRevealDelay: TimeInterval = 0.3
    /// 신기록 보상 라벨 fade-in 길이 (초).
    static let newBestFadeInDuration: TimeInterval = 0.3
    /// 신기록 보상 라벨 scale pulse 한 사이클 총 길이 (초). up(0.4) + down(0.4) = 0.8.
    static let newBestScalePulseDuration: TimeInterval = 0.8
    /// 신기록 보상 라벨 scale pulse 정점 스케일 (1.0 → 1.2 → 1.0).
    static let newBestEndScalePeak: CGFloat = 1.2
    /// bestLabel 황금 깜빡임 최소 alpha. 1.0 ↔ 0.5 사이 보간.
    static let newBestBlinkMinAlpha: CGFloat = 0.5
    /// bestLabel 황금 깜빡임 한 색 머무는 시간 (초). tensionBlinkHalfPeriod(0.5)와 동일.
    static let newBestBlinkHalfPeriod: TimeInterval = 0.5
    /// bestLabel 황금 깜빡임 SKAction 키. 같은 키 재호출 시 자동 교체로 자연 멱등.
    static let newBestBlinkActionKey: String = "newBestBlink"

    // MARK: - Score Popup (Phase 6-16)
    /// 노트 수집 자리에 뜨는 "+1"/"+2" 라벨 폰트 크기 (pt).
    /// HUD(18)보다 크고 ComboPopup(48)보다 작음 — *지역* 강조 톤.
    static let scorePopupFontSize: CGFloat = 28
    /// 노트 수집 좌표에서 시작 y 오프셋 (pt). 노트 본체(16pt) 위쪽 살짝 —
    /// 노트가 사라지는 픽셀과 텍스트 첫 프레임이 겹치지 않게 12pt 위에서 시작.
    static let scorePopupStartOffsetY: CGFloat = 12
    /// "+1"/"+2"가 위로 떠오르는 총 거리 (pt). ComboPopup(80)의 절반 — *지역* 시그널은 작게.
    /// sparkleSpawnDistance(24)보다 길어 sparkle 입자와 텍스트가 시각 분리.
    static let scorePopupFlyUpDistance: CGFloat = 40
    /// 1회 표시 총 길이 (초). sparkle(0.5)보다 살짝 길어 사라지는 시점 비동기 —
    /// 시각 노이즈 분리. comboPopup(1.0)보다 짧음 — *지역* 톤.
    static let scorePopupDuration: TimeInterval = 0.6
    /// 시작 scale. 1.0보다 작게 시작해 *부풀어 오르는* 톤. ComboPopup(1.0 시작)과 차별화.
    static let scorePopupStartScale: CGFloat = 0.8
    /// 끝 scale. ComboPopup(1.4 확대)보다 약함 — *지역* 시그널 절제 톤.
    static let scorePopupEndScale: CGFloat = 1.0
    /// 수집 직후 팝업이 튀어나오는 정점 scale. 점수 산식은 건드리지 않고 시각 반응만 강화.
    static let scorePopupPopScale: CGFloat = 1.18
    /// pop-in 상승 시간. 즉각성을 위해 0.1초 미만.
    static let scorePopupPopDuration: TimeInterval = 0.08
    /// pop 이후 안정 scale로 돌아오는 시간.
    static let scorePopupSettleDuration: TimeInterval = 0.10
    /// 최고 가산점(+4) 팝업 전용 좌우 흔들림 거리.
    static let scorePopupTierHighShakeX: CGFloat = 3
    /// 최고 가산점(+4) 팝업 전용 흔들림 1스텝 시간.
    static let scorePopupTierHighShakeDuration: TimeInterval = 0.04

    // MARK: - Collect Feedback Sprint
    /// HUD combo 값 라벨 펄스 액션 키. 연속 수집 시 이전 펄스 제거 후 재시작.
    static let hudComboPulseActionKey: String = "hudComboPulse"
    /// HUD combo 값 라벨 펄스 정점 scale.
    static let hudComboPulseScale: CGFloat = 1.18
    /// HUD combo 값 라벨이 커지는 시간.
    static let hudComboPulseUpDuration: TimeInterval = 0.06
    /// HUD combo 값 라벨이 원래 scale로 돌아오는 시간.
    static let hudComboPulseDownDuration: TimeInterval = 0.12
    /// 콤보 마일스톤 팝업 시작 y 오프셋. HUD와 덜 겹치도록 화면 중앙보다 살짝 아래.
    static let comboPopupStartOffsetY: CGFloat = -24
    /// 콤보 마일스톤 팝업 첫 박자 scale.
    static let comboPopupBeatPopScale: CGFloat = 1.12
    /// 콤보 마일스톤 팝업 첫 박자 시간.
    static let comboPopupBeatPopDuration: TimeInterval = 0.08

    // MARK: - Cutscene (Phase 7-3)
    /// 컷씬 배경 SKSpriteNode 알파(반투명 검정). 0.85 = 게임 월드를 *흐릿하게* 보여주며 텍스트 가독성 확보.
    /// 1.0(완전 차단)이면 *전환*의 시각 연속성이 끊기고, 0.5 이하면 본문 라벨 가독성 ↓.
    static let cutsceneBackgroundAlpha: CGFloat = 0.85
    /// 컷씬 제목 라벨 폰트 크기 (pt). resultScoreFontSize(24)보다 살짝 큼 — *장*의 톤.
    /// countdownFontSize(96)·comboPopupFontSize(48)보단 작음 — 본문이 주인공인 컷씬에서 제목은 헤더 정도.
    static let cutsceneTitleFontSize: CGFloat = 26
    /// 컷씬 본문 라벨 폰트 크기 (pt). 한국어 가독성 + 화면 가로 70% 폭에 2~3줄 줄바꿈 균형.
    /// HUD(18)와 제목(26) 중간 — 본문은 *말하는 목소리*의 톤.
    static let cutsceneBodyFontSize: CGFloat = 20
    /// 컷씬 TAP 라벨 폰트 크기 (pt). titlePromptFontSize(18)보다 살짝 작아 *부속 안내*임을 시각 위계로 전달.
    static let cutsceneTapFontSize: CGFloat = 16
    /// 컷씬 제목 라벨 y 오프셋 (pt). cameraNode 자식 좌표계 (0,0) = 화면 중앙 기준 위쪽.
    /// 본문(0)·TAP(-120)과 시각 위계 + 본문 줄바꿈 공간 확보.
    static let cutsceneTitleOffsetY: CGFloat = 100
    /// 컷씬 TAP 라벨 y 오프셋 (pt). 화면 중앙 기준 아래쪽 — 본문(0)과 안전 간격 확보.
    static let cutsceneTapOffsetY: CGFloat = -120
    /// 컷씬 본문 자동 줄바꿈 최대 폭 비율 (scene.width × ratio). 0.7 = 양 가장자리 15% 여백 확보.
    /// 너무 좁으면 줄 수 ↑(스크롤 느낌), 너무 넓으면 가독성 ↓(끝까지 시선 이동 부담).
    static let cutsceneBodyWidthRatio: CGFloat = 0.7
    /// 컷씬 fadeIn 길이 (초). present 직후 alpha 0 → 1 보간.
    /// 너무 짧으면 *팝업* 느낌, 너무 길면 답답함. countdownFadeInDuration(0.1)보다 길어 *문이 열리는* 톤.
    static let cutsceneFadeInDuration: TimeInterval = 0.25
    /// 컷씬 fadeOut 길이 (초). dismiss 시 alpha 1 → 0 보간 + 트리 제거.
    /// fadeIn(0.25)보다 살짝 길어 *떠나가는 잔향* 톤. sceneTransitionDuration(0.4)과 동급.
    static let cutsceneFadeOutDuration: TimeInterval = 0.3
    /// 컷씬 TAP 라벨 alpha. 0.7 = 본문·제목(1.0)과 시각 위계 + *깜빡임 없이도* 부속 안내임이 전달.
    /// dpadAlpha(0.7)와 동급 — *조작 안내 톤*과 일관.
    static let cutsceneTapLabelAlpha: CGFloat = 0.7

    // MARK: - Diploma (Phase 7-4)
    /// Sprint 2 — 다음 목표 문구 y 오프셋.
    static let resultNextGoalOffsetY: CGFloat = -72

    // MARK: - Result Verdict (성공/실패 큰 판정)
    static let comboPopupTextMilestone3: String = "x3 +2"
    static let comboPopupTextMilestone5: String = "x5 +3"
    static let comboPopupTextMilestone7: String = "x7 +4"
    static let comboPopupTextMilestone10: String = "x10 KEEP"
    static let comboPopupTextMilestone20: String = "x20 MAX"
    static let scorePopupTextComboSuffix: String = "COMBO"

    // MARK: - Profile Name Editor — Keyboard Avoidance (신규)
    /// 사용자 요청에 따라 BGM은 번들에 있어도 재생하지 않는다.
    static let isBGMEnabled: Bool = false

    /// 졸업장 배경(.ganhoYellowF) 반투명 alpha. 0.92 = 거의 불투명이지만 살짝 비침으로 *증서 종이* 톤.
    /// cutsceneBackgroundAlpha(어두운 톤)와 의도적으로 다른 값 — 증서의 *밝고 견고한* 인상.
    static let diplomaBackgroundAlpha: CGFloat = 0.92
    /// 졸업장 fadeIn 길이 (초). 0.4 = sceneTransitionDuration과 동급 — *문이 열리는* 톤.
    /// cutsceneFadeInDuration(0.25)보다 살짝 길어 *증서가 천천히 펼쳐지는* 인상.
    static let diplomaFadeInDuration: TimeInterval = 0.4
    /// 졸업장 fadeOut 길이 (초). 0.35 = fadeIn(0.4)과 거의 같지만 살짝 빨라 *잔향 짧게*.
    static let diplomaFadeOutDuration: TimeInterval = 0.35
    /// 영문 제목 "CERTIFICATE OF GRADUATION" 폰트 크기. 한글(30)보다 살짝 작아 *부제* 느낌.
    static let diplomaTitleEnFontSize: CGFloat = 26
    /// 한글 제목 "실습 수료 증서" 폰트 크기. 30 — *주인공*. 본문(18)보다 명확히 큼.
    static let diplomaTitleKoFontSize: CGFloat = 30
    /// 본문 라벨(2줄) 폰트 크기. 18 — HUD(18)와 동급. 자동 줄바꿈으로 폭에 맞춤.
    static let diplomaBodyFontSize: CGFloat = 18
    /// 발급자 라벨("hgfolio · 김간호는 음악박사") 폰트 크기. 작은 부속 정보.
    static let diplomaIssuerFontSize: CGFloat = 14
    /// 일시 라벨("yyyy-MM-dd") 폰트 크기. issuer(14)와 동급 — 한 줄에 좌우 배치.
    static let diplomaDateFontSize: CGFloat = 14
    /// "TAP TO CONTINUE" 안내 라벨 폰트 크기. 14 — diplomaTapFontSize 별도(작은 안내문 톤).
    /// cutsceneTapFontSize(16)와 다른 값 — 졸업장 톤에 맞춰 더 차분.
    static let diplomaTapFontSize: CGFloat = 14
    /// 영문 제목 y 오프셋. +150 — 화면 중앙 기준 위쪽. 한글(110)과 40 간격.
    static let diplomaTitleEnOffsetY: CGFloat = 150
    /// 한글 제목 y 오프셋. +110. 영문(150)과 본문(30) 사이.
    static let diplomaTitleKoOffsetY: CGFloat = 110
    /// 본문 1 y 오프셋. +30 — 화면 중앙 약간 위.
    static let diplomaBody1OffsetY: CGFloat = 30
    /// 본문 2 y 오프셋. -10 — 화면 중앙 약간 아래. 본문1(30)과 40 간격으로 2줄 자연 배치.
    static let diplomaBody2OffsetY: CGFloat = -10
    /// 발급자 라벨 y 오프셋. -110 — 본문 아래 충분한 간격. 우측 정렬.
    static let diplomaIssuerOffsetY: CGFloat = -110
    /// 일시 라벨 y 오프셋. -110 — 발급자와 같은 y, 좌측 정렬. 한 줄에 좌우 배치.
    static let diplomaDateOffsetY: CGFloat = -110
    /// TAP 라벨 alpha. 0.7 = cutsceneTapLabelAlpha와 동급 — *조작 안내 톤* 일관.
    static let diplomaTapLabelAlpha: CGFloat = 0.7
    /// TAP 라벨 y 오프셋. -160 — 발급자/일시(-110) 아래 충분한 간격.
    static let diplomaTapOffsetY: CGFloat = -160
    /// 본문 자동 줄바꿈 최대 폭 비율 (scene.width × ratio). 0.7 = cutsceneBodyWidthRatio와 동급.
    /// 양 가장자리 15% 여백 — 한국어 본문이 폭 안에 자연 줄바꿈.
    static let diplomaBodyWidthRatio: CGFloat = 0.7

    // MARK: - Skill (Phase 9-5)
    // R2 — skillEffectLineWidth(트레일 선폭)는 spawnSkillTrail 삭제(이미터 대체)와 함께 제거.
    static let skillEffectRingLineWidth: CGFloat = 3
    static let skillEffectStrokeAlpha: CGFloat = 0.85
    static let skillEffectFillAlpha: CGFloat = 0.12
    static let skillEffectFadeDuration: TimeInterval = 0.32
    static let skillEffectRingStartScale: CGFloat = 0.25
    static let skillEffectRingEndScale: CGFloat = 1.25
    static let skillSparkleRadius: CGFloat = 4
    static let skillSparkleTravelDistance: CGFloat = 18
    static let skillSparkleDuration: TimeInterval = 0.35
    static let skillSparkleLineWidth: CGFloat = 2

    // MARK: - Toast Label (Phase 9-6)
    /// "화캉스 보너스!" 0.9초 토스트 — ScorePopupNode 패턴 답습 + 텍스트 길이만 다름.

    /// 변기 수집 시 표시 텍스트. 호출부 리터럴 노출 금지 — 단일 진실 원천.
    static let toiletToastText: String = "화캉스 보너스!"
    /// 토스트 1회 표시 총 길이 (초). group(move+fade+scale) duration. GDD §7-3.
    /// scorePopupDuration(0.6)보다 길고 comboPopupDuration(1.0)보다 짧음 — *임팩트 강조* 톤.
    static let toastDuration: TimeInterval = 0.9
    /// 토스트 텍스트 폰트 크기 (pt). scorePopupFontSize(28)과 comboPopupFontSize(48)의 중간 —
    /// *국지 시그널보다 강하고 글로벌 마일스톤보단 약함*.
    static let toastFontSize: CGFloat = 24
    /// 토스트 시작 y 오프셋 (pt). 변기 중심에서 위쪽 +16pt — 변기 본체와 텍스트 픽셀 겹침 방지.
    static let toastStartOffsetY: CGFloat = 16
    /// 토스트가 위로 떠오르는 총 거리 (pt). scorePopupFlyUpDistance(40)와 동일 — *지역* 시그널 톤 통일.
    static let toastFlyUpDistance: CGFloat = 40
    /// 토스트 시작 scale. scorePopupStartScale(0.8)과 동일 — *부풀어 오르는* 톤 디자인 통일.
    static let toastStartScale: CGFloat = 0.8
    /// 토스트 끝 scale. scorePopupEndScale(1.0)보다 살짝 큰 1.1 — *임팩트 강조* (확산 톤).
    static let toastEndScale: CGFloat = 1.1

    // MARK: - Stone Guard Warning Cutscene (Phase 10-1d)
    /// easy/normal 난이도 인트로 컷씬 직후 발화되는 *석조무사 경고* 컷씬 제목.
    /// hard의 professorWarningTitle과 시그니처 동형 — CutsceneOverlayNode 재사용.
    static let stoneGuardWarningTitle: String = "경고 · 석조무사 출현"
    /// 석조무사 경고 본문. GDD §10 + 사용자 요청 결합.
    /// 호출부 리터럴 노출 금지 — 단일 진실 원천.
    static let stoneGuardWarningBody: String =
        "수간호사의 충실한 부하 석조무사가 출현합니다! 마주치면 잡혀갑니다. 절대 만나지 마세요."

    // MARK: - Sprint 5 · ResultScene v2 Layout

    // Diploma v2 (우드컷)
    /// 종이 카드 폭(pt). mockup .diploma width: 520.
    static let diplomaPaperWidth: CGFloat = 520
    /// 종이 카드 높이(pt).
    static let diplomaPaperHeight: CGFloat = 320
    /// 종이 카드 cornerRadius(pt).
    static let diplomaPaperCornerRadius: CGFloat = 8
    /// 종이 카드 더블 보더 두께(pt). mockup border: 4px double.
    static let diplomaPaperBorderLineWidth: CGFloat = 4
    /// 종이 카드 회전 각도(degree). mockup transform: rotate(-2deg).
    static let diplomaPaperRotationDegrees: CGFloat = -2
    /// 우드컷 도트 격자 간격(pt). 12pt 간격 = 약 1100개 도트 누적.
    static let diplomaDotStep: CGFloat = 12
    /// 우드컷 도트 반지름(pt).
    static let diplomaDotRadius: CGFloat = 1.0
    /// 우드컷 도트 색 alpha. mockup repeating-linear-gradient 톤 모사.
    static let diplomaDotAlpha: CGFloat = 0.4
    /// 코너 데코 ㄱ자 한 변 길이(pt). mockup ::before/::after width: 30.
    static let diplomaCornerDecoSize: CGFloat = 30
    /// 코너 데코 종이 가장자리로부터 안쪽 inset(pt). mockup top/left: 6.
    static let diplomaCornerDecoInset: CGFloat = 6
    /// 코너 데코 strokeColor 두께(pt). mockup border: 3px double.
    static let diplomaCornerDecoLineWidth: CGFloat = 3
    /// 도장 원 반지름(pt). mockup .diploma-stamp width/height 56 → r=28.
    static let diplomaStampRadius: CGFloat = 28
    /// 도장 strokeColor 두께(pt). mockup border: 2px.
    static let diplomaStampLineWidth: CGFloat = 2
    /// 도장 회전 각도(degree). mockup transform: rotate(-12deg).
    static let diplomaStampRotationDegrees: CGFloat = -12
    /// 도장 라벨 텍스트.
    static let diplomaStampLabelText: String = "김간호\n음악대학"
    /// 도장 라벨 폰트 크기(pt). mockup font-size: 9.
    static let diplomaStampLabelFontSize: CGFloat = 9
    /// 도장 fill 반투명 alpha. mockup background: rgba(255,232,232,0.4).
    static let diplomaStampFillAlpha: CGFloat = 0.4
    /// 도장 종이 카드 우하단 x 오프셋(pt). 종이 중심 기준 + 거리.
    static let diplomaStampOffsetX: CGFloat = 180
    /// 도장 종이 카드 우하단 y 오프셋(pt). 종이 중심 기준 - 거리.
    static let diplomaStampOffsetY: CGFloat = -100

    // MARK: - Sprint 8 Phase G · 인게임 시각 통합 V4

    // 박병장 컷씬 멘트 + 이펙트 (요청 2)
    /// 박병장 등장 컷씬 토스트 멘트. AS-IS 하드코딩 "박병장 등장!"(GameScene+Setup) 대체.
    /// 긴 문장이라 numberOfLines=0 + preferredMaxLayoutWidth로 줄바꿈해 화면 폭 초과 방지.
    static let sergeantParkIntroToastText: String = "석조무사가 친구인 박병장을 불러 유저를 도와줍니다!"
    /// 컷씬 토스트 폰트(24pt). 긴 멘트가 화면 폭 안에 들어오도록 36→24 축소.
    static let sergeantParkIntroToastFontSize: CGFloat = 24
    /// 컷씬 토스트 줄바꿈 최대 폭(pt). 멀티라인 wrap 기준. landscape 가시영역 내.
    static let sergeantParkIntroToastMaxWidth: CGFloat = 420
    /// 컷씬 시작 시 heavy 햅틱 2회 사이 간격(초). Timer 금지 — SKAction.wait 경유.
    static let sergeantParkIntroHapticGap: Double = 0.12

    // 비행기 시각

    // 플레이어 풀바디

    // MARK: - Sprint 9 Phase C · Enemy Visual & Countdown V9
    /// 카운트다운 dim 도달 alpha V9(0.22). 기존 0.32보다 약화 — coralPrimary/navyDeep 숫자 가독성 회복.
    static let countdownDimAlpha: CGFloat = 0.22

    // MARK: - Sprint 10 Phase G · Airforce Easter Egg Pixel Tone
    // 원본 game.js L127~L144 / L3328~L3336 byte-equal 수치 + 픽셀 톤 통일.
    // SPEC §10 신규 상수 9개 + §11 픽셀 톤 4색(Palette inline).

    /// 비행기 16×5 도트 매트릭스 픽셀 확대 배수. 원본 SCALE=3 byte-equal → 48×15 px.
    /// 호출부: AirplaneNode.init — PixelSpriteRenderer.texture(rows:palette:scale:)에 전달.
    static let airplanePixelScale: Int = 3
    /// 박병장 클로즈업 cameraNode 자식 좌표계 y 오프셋(pt). 화면 중앙 위 살짝 — 토스트/하단 HUD 여백 확보.
    static let sergeantCloseupOffsetY: CGFloat = 40
    /// 박병장 클로즈업 fadeIn 길이 (초). 매우 짧은 부드러운 진입.
    static let sergeantCloseupFadeInDuration: TimeInterval = 0.1
    /// 박병장 클로즈업 머무름 길이 (초). t=0.1 ~ t=1.7 — 비행기 등장(t=2.4) 전 충분히 인식.
    static let sergeantCloseupStayDuration: TimeInterval = 1.6
    /// 박병장 클로즈업 fadeOut 길이 (초). t=1.7 ~ t=2.2 — 비행기 등장(t=2.4) 직전 완전 사라짐.
    static let sergeantCloseupFadeOutDuration: TimeInterval = 0.5
    /// 폭탄 화면 플래시 정점 알파(0~1). 원본 brightness 1→2.4 톤을 alpha 0.92로 환산.
    /// 풀스크린 fadeAlpha(to:) 목표값. 1.0 완전 흰 화면 대비 살짝 절제 — 시각 부담 ↓.
    static let bombFlashPeakAlpha: CGFloat = 0.92

    // MARK: - Cutscene (Sprint 10 Phase H — 원본 1:1 5종 컷씬 시스템)
    static let enableMidGameCutscenes: Bool = false
    /// 인트로 컷씬 진입 지연 (초). 원본 game.js L2268 — startGame 직후 250ms 후 표시.
    /// 카운트다운/액션 직전 *짧은 호흡*으로 캐릭터 정체성 환기.
    static let cutsceneIntroDelay: TimeInterval = 0.25
    /// mid1 컷씬 트리거 임계 — 남은 시간 30초 이하(경과 ~15초)에서 1회 발화.
    /// 원본 game.js L2417/L2469 — `state.timeLeft <= 30 && !cutscenesShown.has('mid1')` byte-equal.
    /// 캐릭터별 속마음 본문 → 정체성·정서 재진입 신호.
    static let cutsceneMid1Threshold: TimeInterval = 30
    /// mid2 컷씬 트리거 임계 — 남은 시간 15초 이하(경과 ~30초)에서 1회 발화.
    /// "수간호사의 눈초리" 공통 본문 → 최종 압박감 주입.
    static let cutsceneMid2Threshold: TimeInterval = 15

    // MARK: - Sprint 10 Phase J · Pixel HUD/Effect Tokens (마지막 Phase)
    /// SparkleEffectNode .ingame 컨텍스트 입자 한 변 크기 (pt). 8개 × 3pt 정사각 픽셀 — 음표 한 변(16)의
    /// 약 1/5. 둥근 원(sparkleParticleRadius=2 → 지름 4)과 비슷한 시각 무게이나 *각진 픽셀 톤*.
    static let sparklePixelSize: CGFloat = 3
    /// 5초 긴박감 비네트 가장자리 두께 (pt). 8pt — HUD(상단 4슬롯)와 dpad(하단)를 가리지 않는 *얇은 액자*.
    static let tensionVignetteThickness: CGFloat = 8
    /// 비네트 가장자리 기본 알파(0~1). 0.6 — *알아채되 시야 차단 0.3에 가깝지 않음*.
    static let tensionVignetteEdgeAlpha: CGFloat = 0.6
    /// 비네트 깜빡임 한 색 머무는 시간 (초). 0.5 — tensionBlinkHalfPeriod(0.5)와 동기 → HUD TIME 슬롯
    /// 깜빡임과 *같은 박자*.
    static let tensionVignetteBlinkHalfPeriod: TimeInterval = 0.5
    /// 비네트 깜빡임 알파 진폭 하한(어두운 톤). 0.3 — edgeAlpha(0.6)의 절반.
    static let tensionVignetteBlinkAlphaMin: CGFloat = 0.3
    /// 비네트 깜빡임 알파 진폭 상한(밝은 톤). 0.7 — edgeAlpha(0.6)의 ~117%.
    static let tensionVignetteBlinkAlphaMax: CGFloat = 0.7
}
