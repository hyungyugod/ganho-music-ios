//
//  FeelTuning+R5.swift
//  GanhoMusic Shared
//
//  R5 결과 화면 "보상의 무대" — 연출 타이밍·SFX 토큰 (03_UI §7 시퀀스 표 그대로).
//  시퀀스 시점(0.0/0.4/1.2/1.7/2.1/~2.4s)·카운트업 0.8s·별 간격 0.15s는 설계서 수치 고정 —
//  임의 변경 금지. 표 외 보조 수치(스탬프 길이·셰이크 진폭 등)는 generator 재량 범위.
//

import Foundation
import CoreGraphics

extension FeelTuning {
    /// R5 결과 연출 토큰 네임스페이스. case 없는 enum — 인스턴스화 차단.
    enum R5 {
        // MARK: 시퀀스 시점 (03_UI §7 표 — 0.0s는 즉시 발화라 토큰 불필요)
        /// 점수 카운트업 시작 시점.
        static let revealCountUpAt: TimeInterval = 0.4
        /// 별 3개 순차 팝 시작 시점.
        static let revealStarsAt: TimeInterval = 1.2
        /// XP 바 증가 시작 시점.
        static let revealXPAt: TimeInterval = 1.7
        /// 기록 칩 시점.
        static let revealRecordChipAt: TimeInterval = 2.1
        /// 버튼 등장 시점 (총 ~2.4s 마무리).
        static let revealButtonsAt: TimeInterval = 2.4

        // MARK: verdict 스탬프 (0.0s)
        /// 스탬프 scale 1.6→1.0 길이 (easeOutBack).
        static let stampDuration: TimeInterval = 0.25
        /// 스탬프 시작 스케일.
        static let stampStartScale: CGFloat = 1.6
        /// 콘텐츠 컨테이너 소프트 셰이크 — 진폭(pt)/전체 길이.
        static let stampShakeAmplitude: CGFloat = 4
        static let stampShakeDuration: TimeInterval = 0.18

        // MARK: 점수 카운트업 (0.4s~)
        /// 카운트업 길이 — 0→finalScore (customAction elapsed 기반).
        static let countUpDuration: TimeInterval = 0.8

        // MARK: 별 순차 팝 (1.2s~)
        /// 별 간 간격 (§7 표 0.15s).
        static let starInterval: TimeInterval = 0.15
        /// 별 1개 팝 길이 (scale 0→1 easeOutBack).
        static let starPopDuration: TimeInterval = 0.18

        // MARK: XP·레벨업 (1.7s~ — 채움 0.5s는 기존 FeelTuning.v3ProgressFillDuration)
        /// 레벨업 칭호 배지 슬라이드인 길이/이동 거리 (easeOutCubic).
        static let levelUpChipSlideDuration: TimeInterval = 0.25
        static let levelUpChipSlideDistance: CGFloat = 24

        // MARK: 기록 칩 블링크 (2.1s~ — 시각 펄스, 소멸 아님: 하한 alpha > 0)
        /// 블링크 한 사이클 길이 / 하한 alpha (R4 tapToStart 블링크 컨벤션 동형).
        static let recordChipBlinkCycle: TimeInterval = 1.0
        static let recordChipBlinkLowAlpha: CGFloat = 0.55

        // MARK: SFX (기능 8 — ChiptuneSynth 신규 voice 2종, 사전 렌더 전용)
        /// `.resultStamp` — square+noise 하강 글라이드, 저음 임팩트 단발 (02 §6 표 형식).
        /// | 도장 (결과창) | square+noise | 180→55Hz 글라이드 | 250ms |
        static let sfxResultStampDuration: TimeInterval = 0.250
        static let sfxResultStampStartFrequency: Double = 180
        static let sfxResultStampEndFrequency: Double = 55
        static let sfxResultStampNoiseMix: Float = 0.2
        /// `.scoreTick(step:)` — square 단발, 피치 단계 상승 (02 §6 표 형식).
        /// | 카운트업 틱 (결과창) | square | C5 + step×2반음 (0...7단) | 30ms |
        /// 단계 수 8 근거: 카운트업 0.8s ÷ 8단 = 100ms 간격 — 틱이 또렷이 분리되는 최소 간격
        /// (매 프레임 발화 금지). 사전 렌더 버퍼 8벌만 추가 — init 비용 미미.
        static let sfxScoreTickStepCount: Int = 8
        static let sfxScoreTickDuration: TimeInterval = 0.030
        /// 단계당 피치 상승 (반음 ×2 = 온음) — 8단계에 걸쳐 C5 → D6 상행.
        static let sfxScoreTickSemitonePerStep: Int = 2
    }
}
