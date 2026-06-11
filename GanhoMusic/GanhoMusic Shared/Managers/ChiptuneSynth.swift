//
//  ChiptuneSynth.swift
//  GanhoMusic Shared
//
//  R2 · 프로시저럴 8비트 SFX — AVAudioEngine + 초기화 시점 전체 사전 렌더 PCM 버퍼 캐시
//  (02_GAME_FEEL §6). 런타임 합성 금지 — play()는 캐시 버퍼 스케줄만.
//  엔진 시작 실패는 graceful 무음 (try?/guard — 크래시 금지).
//  콤보 피치 상승(+반음, 최대 +12)이 음악 게임 정체성의 최우선 voice.
//

import AVFoundation

/// 칩튠 SFX 신스. 공유 인스턴스 — AVAudioEngine·사전 렌더 버퍼(21벌)는 기기 단위 자원이라
/// 씬마다 재생성하지 않는다 (CloudSaveCoordinator.shared와 동일 Manager 컨벤션).
final class ChiptuneSynth {

    static let shared = ChiptuneSynth()

    // MARK: - Voice (02 §6 표)
    enum Voice: Hashable {
        /// 음표 수집 — square, C5 시작 + 반음 오프셋(0...12), 60ms.
        case noteCollect(semitoneOffset: Int)
        /// 변기 수집 — square 2음 E5→G5, 110ms.
        case toiletCollect
        /// 콤보 마일스톤 — triangle 아르페지오 C5-E5-G5, 180ms.
        case comboMilestone
        /// 콤보 끊김 — saw 하강 G4→C4, 150ms.
        case comboBreak
        /// 피격/게임오버 — noise+square 하강, 400ms.
        case hit
        /// UI 탭 — square A5, 35ms.
        case uiTap
        /// 별 획득 (결과창 — R5 배선용 제공) — triangle C6/E6/G6, 120ms.
        case starReveal(index: Int)
        /// 카운트다운 틱 — square A4, 50ms.
        case countdownTick
        /// 카운트다운 GO — square A5, 200ms.
        case countdownGo
        /// 씬 전환 — square 상행 스윕 A4→A5, 120ms.
        /// 02_GAME_FEEL §6 표 외 신규 — 03_UI §9 전환 SFX 요구 (R3 SceneRouter 전용).
        case sceneTransition
        /// 결과 verdict 도장 — square+noise 하강 180→55Hz, 250ms (R5 — 03_UI §7 시퀀스 0.0s).
        case resultStamp
        /// 점수 카운트업 틱 — square C5 + step×2반음(0...7단), 30ms (R5 — §7 0.4s, 단계 발화 전용).
        case scoreTick(step: Int)
    }

    private enum Waveform {
        case square, triangle, saw, noise
    }

    // MARK: - Engine
    private let engine = AVAudioEngine()
    private var playerNodes: [AVAudioPlayerNode] = []
    private var nextPlayerIndex = 0
    private var buffers: [Voice: AVAudioPCMBuffer] = [:]
    private let format: AVAudioFormat?
    private var isAvailable = false
    /// R9 #1 — 설정 게이트 (이벤트 시점 조회만 — update 매 프레임 경로 아님).
    private let settings = SettingsRepository()

    // MARK: - Init (전체 사전 렌더 — 시작 시 1회)
    private init() {
        // AudioSession .ambient — 무음 스위치 준수, 타 앱 사운드 미중단 (기존 정책 유지).
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [])
        format = AVAudioFormat(standardFormatWithSampleRate: FeelTuning.sfxSampleRate, channels: 1)
        guard let format = format else { return }

        for _ in 0..<FeelTuning.sfxPlayerNodeCount {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            playerNodes.append(node)
        }
        prerenderAllVoices()
        engine.prepare()
        do {
            try engine.start()
            isAvailable = true
        } catch {
            isAvailable = false   // graceful 무음
        }
    }

    // MARK: - Play
    func play(_ voice: Voice) {
        // R9 #1 — 효과음 off면 무음 return (사전 렌더·엔진은 불변 — 재토글 즉시 복귀).
        // 부수 효과 인지: PixelButtonNode 내장 uiTap도 무음 — 의도된 동작.
        guard settings.isSFXEnabled else { return }
        guard let buffer = buffers[voice] else { return }
        if !engine.isRunning {
            // 인터럽션 등으로 정지된 엔진 재시동 시도 — 실패 시 무음 noop.
            try? engine.start()
        }
        guard engine.isRunning, isAvailable, !playerNodes.isEmpty else { return }
        let node = playerNodes[nextPlayerIndex]
        nextPlayerIndex = (nextPlayerIndex + 1) % playerNodes.count
        node.stop()
        node.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        node.play()
    }

    // MARK: - Pre-render (콤보 피치 13단 포함 전 변형)
    private func prerenderAllVoices() {
        var voices: [Voice] = [.toiletCollect, .comboMilestone, .comboBreak,
                               .hit, .uiTap, .countdownTick, .countdownGo,
                               .sceneTransition,
                               .resultStamp]   // R5 — 사전 렌더 누락 시 무음 (R3 컨벤션 동일)
        for semitone in 0...FeelTuning.sfxCollectPitchMaxSemitone {
            voices.append(.noteCollect(semitoneOffset: semitone))
        }
        for index in 0..<3 {
            voices.append(.starReveal(index: index))
        }
        // R5 — 카운트업 틱 8단 (FeelTuning.R5.sfxScoreTickStepCount — 0.8s ÷ 8 = 100ms 간격 근거).
        for step in 0..<FeelTuning.R5.sfxScoreTickStepCount {
            voices.append(.scoreTick(step: step))
        }
        for voice in voices {
            buffers[voice] = renderBuffer(for: voice)
        }
    }

    /// MIDI 노트 → 주파수 (Hz). 440 × 2^((midi-69)/12).
    private func frequency(midi: Int) -> Double {
        return 440 * pow(2, Double(midi - FeelTuning.sfxMidiA4) / 12)
    }

    private func renderBuffer(for voice: Voice) -> AVAudioPCMBuffer? {
        switch voice {
        case .noteCollect(let semitoneOffset):
            let clamped = min(max(semitoneOffset, 0), FeelTuning.sfxCollectPitchMaxSemitone)
            return renderTones([(frequency(midi: FeelTuning.sfxMidiC5 + clamped),
                                 FeelTuning.sfxCollectDuration)], waveform: .square)
        case .toiletCollect:
            let half = FeelTuning.sfxToiletDuration / 2
            return renderTones([(frequency(midi: FeelTuning.sfxMidiE5), half),
                                (frequency(midi: FeelTuning.sfxMidiG5), half)], waveform: .square)
        case .comboMilestone:
            let third = FeelTuning.sfxMilestoneDuration / 3
            return renderTones([(frequency(midi: FeelTuning.sfxMidiC5), third),
                                (frequency(midi: FeelTuning.sfxMidiE5), third),
                                (frequency(midi: FeelTuning.sfxMidiG5), third)], waveform: .triangle)
        case .comboBreak:
            return renderGlide(from: frequency(midi: FeelTuning.sfxMidiG4),
                               to: frequency(midi: FeelTuning.sfxMidiC4),
                               duration: FeelTuning.sfxComboBreakDuration,
                               waveform: .saw, noiseMix: 0)
        case .hit:
            return renderGlide(from: FeelTuning.sfxHitStartFrequency,
                               to: FeelTuning.sfxHitEndFrequency,
                               duration: FeelTuning.sfxHitDuration,
                               waveform: .square, noiseMix: FeelTuning.sfxHitNoiseMix)
        case .uiTap:
            return renderTones([(frequency(midi: FeelTuning.sfxMidiA5),
                                 FeelTuning.sfxUITapDuration)], waveform: .square)
        case .starReveal(let index):
            let midis = [FeelTuning.sfxMidiC6, FeelTuning.sfxMidiE6, FeelTuning.sfxMidiG6]
            let midi = midis[min(max(index, 0), midis.count - 1)]
            return renderTones([(frequency(midi: midi), FeelTuning.sfxStarDuration)],
                               waveform: .triangle)
        case .countdownTick:
            return renderTones([(frequency(midi: FeelTuning.sfxMidiA4),
                                 FeelTuning.sfxCountdownTickDuration)], waveform: .square)
        case .countdownGo:
            return renderTones([(frequency(midi: FeelTuning.sfxMidiA5),
                                 FeelTuning.sfxCountdownGoDuration)], waveform: .square)
        case .sceneTransition:
            // R3 — 02 §6 표 외 신규 (03_UI §9 전환 SFX). square 상행 글라이드 A4→A5 — "앞으로 나아가는" 톤.
            return renderGlide(from: frequency(midi: FeelTuning.sfxMidiA4),
                               to: frequency(midi: FeelTuning.sfxMidiA5),
                               duration: FeelTuning.sfxSceneTransitionDuration,
                               waveform: .square, noiseMix: 0)
        case .resultStamp:
            // R5 — verdict 도장 (03_UI §7 0.0s). square+noise 저음 하강 — "쾅" 임팩트 단발.
            return renderGlide(from: FeelTuning.R5.sfxResultStampStartFrequency,
                               to: FeelTuning.R5.sfxResultStampEndFrequency,
                               duration: FeelTuning.R5.sfxResultStampDuration,
                               waveform: .square,
                               noiseMix: FeelTuning.R5.sfxResultStampNoiseMix)
        case .scoreTick(let step):
            // R5 — 카운트업 틱 (03_UI §7 0.4s). C5에서 단계당 온음(2반음) 상행 — 피치 점진 상승.
            let clamped = min(max(step, 0), FeelTuning.R5.sfxScoreTickStepCount - 1)
            let midi = FeelTuning.sfxMidiC5 + clamped * FeelTuning.R5.sfxScoreTickSemitonePerStep
            return renderTones([(frequency(midi: midi), FeelTuning.R5.sfxScoreTickDuration)],
                               waveform: .square)
        }
    }

    // MARK: - Synthesis (init 1회 경로 전용 — 런타임 호출 금지)
    /// (주파수, 길이) 시퀀스를 단일 버퍼로 렌더 — 2음/아르페지오 공용.
    private func renderTones(_ tones: [(frequency: Double, duration: TimeInterval)],
                             waveform: Waveform) -> AVAudioPCMBuffer? {
        let totalDuration = tones.reduce(0) { $0 + $1.duration }
        return makeBuffer(duration: totalDuration) { sampleIndex, sampleRate in
            var elapsed = Double(sampleIndex) / sampleRate
            for tone in tones {
                if elapsed < tone.duration {
                    let phase = elapsed * tone.frequency
                    return sample(waveform: waveform, phase: phase)
                }
                elapsed -= tone.duration
            }
            return 0
        }
    }

    /// 주파수 글라이드(하강) 렌더 — 위상 적분으로 클릭 없는 연속 피치 변화. noiseMix > 0이면 혼합.
    private func renderGlide(from startFrequency: Double, to endFrequency: Double,
                             duration: TimeInterval, waveform: Waveform,
                             noiseMix: Float) -> AVAudioPCMBuffer? {
        var phase: Double = 0
        return makeBuffer(duration: duration) { sampleIndex, sampleRate in
            let progress = Double(sampleIndex) / (duration * sampleRate)
            let currentFrequency = startFrequency + (endFrequency - startFrequency) * progress
            phase += currentFrequency / sampleRate
            let tone = sample(waveform: waveform, phase: phase)
            guard noiseMix > 0 else { return tone }
            let noise = sample(waveform: .noise, phase: phase)
            return tone * (1 - noiseMix) + noise * noiseMix
        }
    }

    /// 공통 버퍼 생성 + 진폭 엔벨로프(어택/릴리즈 — 클릭 방지) + 마스터 게인.
    private func makeBuffer(duration: TimeInterval,
                            sampleAt: (Int, Double) -> Float) -> AVAudioPCMBuffer? {
        guard let format = format else { return nil }
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData else { return nil }
        buffer.frameLength = frameCount

        let attackFrames = max(1, Int(FeelTuning.sfxAttackDuration * sampleRate))
        let releaseFrames = max(1, Int(Double(frameCount) * FeelTuning.sfxReleaseRatio))
        let releaseStart = Int(frameCount) - releaseFrames
        for frame in 0..<Int(frameCount) {
            var envelope: Float = 1
            if frame < attackFrames {
                envelope = Float(frame) / Float(attackFrames)
            } else if frame >= releaseStart {
                envelope = Float(Int(frameCount) - frame) / Float(releaseFrames)
            }
            channel[0][frame] = sampleAt(frame, sampleRate) * envelope * FeelTuning.sfxMasterGain
        }
        return buffer
    }

    /// 파형 샘플 — phase는 사이클 단위 (1.0 = 1주기).
    private func sample(waveform: Waveform, phase: Double) -> Float {
        let t = phase - floor(phase)   // [0, 1)
        switch waveform {
        case .square:
            return t < 0.5 ? 1 : -1
        case .triangle:
            return Float(abs(t * 4 - 2) - 1)
        case .saw:
            return Float(t * 2 - 1)
        case .noise:
            return Float.random(in: -1...1)
        }
    }
}
