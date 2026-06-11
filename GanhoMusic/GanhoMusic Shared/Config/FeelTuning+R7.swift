//
//  FeelTuning+R7.swift
//  GanhoMusic Shared
//
//  R7 페이싱·콘텐츠 튜닝 (02_GAME_FEEL §8) — 웨이브 마커 3종·near-miss 보너스·콤보 게이지·
//  리스크 가속 + 메타 보상 연출(F5/F6 토스트) 타이밍. R5 네임스페이스 컨벤션 답습.
//

import Foundation
import CoreGraphics

extension FeelTuning {
    /// R7 페이싱 튜닝 토큰 네임스페이스. case 없는 enum — 인스턴스화 차단.
    enum R7 {
        // MARK: 웨이브 마커 3종 (02 §8 — 10s / 25s / 38s)
        /// ① 10s 첫 압박 — 발사 간격 보간 가속 시작점 (elapsed 초).
        static let waveFirstPressureElapsed: TimeInterval = 10
        /// ② 25s 중반 피크 — 동시 음표 *실효 캡* +1 시작점 (elapsed 초).
        /// 스폰 틱당 발수 증가 아님 — SPEC §문서-코드 불일치 #3 해석 확정.
        static let waveMidPeakElapsed: TimeInterval = 25
        /// ② 실효 캡 보너스 — noteMaxConcurrent + 1.
        static let midPeakNoteCapBonus: Int = 1
        /// ③ 38s 라스트 스퍼트 시작점 (elapsed 초). 구현은 FeelTuning.tensionWindow = 7.0
        /// (= gameDuration 45 − 38) — 본 상수는 산정 근거 봉인용 (tensionWindow 주석이 참조).
        static let waveLastSpurtElapsed: TimeInterval = 38

        /// ① 발사 간격 보간 *전용* pacing — elapsed < 10s 동안 0, 10s→45s 구간 0→1 선형.
        /// `clamp((elapsed − 10) / (45 − 10))` 동치 — gameDuration 상수 참조 (하드코딩 45 금지).
        /// 적용처는 EnemyNode(F)·ProfessorNode(청진기) *간격 산식 2곳뿐* — 투사체 속도 곡선
        /// (EnemyNode.fireF의 obs lerp)·플레이어 속도 곡선은 raw 진행률 유지
        /// (SPEC §F1 적용 제외 + 주의 3: progressProvider 공유 함정 — provider 자체 변형 금지).
        static func pacedFireProgress(_ raw: Double) -> Double {
            let duration = GameplayTuning.gameDuration
            let start = waveFirstPressureElapsed
            guard duration > start else { return raw }   // 방어 — 비정상 상수 조합 시 raw 유지
            let elapsed = raw * duration
            let paced = (elapsed - start) / (duration - start)
            return min(1, max(0, paced))
        }

        // MARK: near-miss 보너스 (02 §8 — R7 합격 게이트 "판정 동작")
        /// 판정 반경 (플레이어 중심 거리, pt). 기존 시각 펄스 반경(40/48/58)과 별개 공존 —
        /// 시각 레이어 무변경 (SPEC §문서-코드 불일치 #5).
        static let nearMissBonusRadius: CGFloat = 22
        /// "아슬!" 팝업·햅틱 쿨다운 (초). 부채꼴 5발 동시 통과 스팸 가드 —
        /// 콤보 연장(extendComboWindow)은 쿨다운 비대상, 이벤트마다 적용.
        static let nearMissFeedbackCooldown: TimeInterval = 0.25
        /// near-miss 햅틱 강도 — transient 0.3 ×1 (telegraphWarning 강도의 단발판).
        static let hapticNearMissIntensity: Float = 0.3

        // MARK: 콤보 게이지 (02 §8 — 60×4px, 잔여 0.7s 이하 코랄 점멸)
        /// 점멸 진입 임계 — 콤보 윈도우(2.5s) 잔여 ≤ 이 값.
        static let comboGaugeBlinkWindow: TimeInterval = 0.7
        /// 점멸 반주기 (초). 0.7s 윈도우 안에 ~3회 점멸 — "한 개만 더"의 긴박 시그널.
        static let comboGaugeBlinkHalfPeriod: TimeInterval = 0.12
        /// 점멸 알파 하한 (0 아님 — 소멸 아닌 시각 펄스, R4 §F-1 허용 전례).
        static let comboGaugeBlinkMinAlpha: CGFloat = 0.35
        /// 게이지 채움 기본 알파 — HUDSlotNode timeBarFill(0.95)과 동일 톤.
        static let comboGaugeFillAlpha: CGFloat = 0.95
        /// 점멸 SKAction 키 — 상태 전환 시 1회 부착 (매 프레임 재부착 금지), withKey 멱등.
        static let comboGaugeBlinkActionKey: String = "r7ComboGaugeBlink"

        // MARK: 리스크 가속 (02 §8 — combo ≥ 7 동안 음표 스폰 간격 ×0.85)
        /// 음표 스폰 간격 배율. 임계는 GameplayTuning.comboBonusThresholdHigh(7) 재사용 —
        /// 신규 임계 상수 금지 (SPEC §F4). 콤보 하락 시 다음 스폰 사이클부터 자연 복귀.
        static let comboRushSpawnIntervalScale: Double = 0.85

        // MARK: 메타 보상 연출 (F5/F6 — revealCompleted 합류점 이후 순차 토스트)
        /// 첫 토스트까지 지연 (초). 버튼 staggered 등장과 시각 분리.
        static let metaToastFirstDelay: TimeInterval = 0.45
        /// 토스트 간 간격 (초). 장당 총 수명(1.5s)보다 길게 — 동시 1장 보장.
        static let metaToastInterval: TimeInterval = 1.6
        /// 등장(슬라이드+페이드) 길이 (초). Tween 곡선 적용 — linear 금지 (SPEC §F5).
        static let metaToastAppearDuration: TimeInterval = 0.25
        /// 유지 길이 (초). 총 수명 = 0.25 + 0.9 + 0.35 = 1.5s — SPEC 1.2~1.8s 범위 내.
        static let metaToastHoldDuration: TimeInterval = 0.9
        /// 퇴장 길이 (초). 종료 시 removeFromParent — 좀비 0.
        static let metaToastExitDuration: TimeInterval = 0.35
        /// 등장/퇴장 수직 슬라이드 거리 (pt).
        static let metaToastSlideDistance: CGFloat = 18
        /// 해금 배너 보이스 — 기존 starReveal 3단 중 최고음 인덱스 재사용 (신규 Voice 금지).
        static let metaToastUnlockVoiceIndex: Int = 2
    }
}
