//
//  BGMPlayer.swift
//  GanhoMusic Shared
//
//  Phase 6-4 · 자작 BGM 무한 루프 재생 인프라 (graceful fallback)
//  Phase 6-5 · play/stop에 페이드 인(1.5s) / 아웃(1.0s) 적용
//  Phase 6-6 · Interruption 처리 — 전화/Siri/타이머 등 시스템 인터럽션 시 BGM 자동 일시정지/복귀
//

import AVFoundation

/// 배경음악 재생을 캡슐화한 매니저. Bundle에 bgm.m4a가 있을 때만 활성화.
/// 없으면 player = nil, 모든 메서드 noop. AudioManager(.ambient)와의 카테고리 분리도
/// 음원 존재 여부를 트리거로 함 — 음원 없으면 .ambient 유지(회귀 0).
/// Spring 비유: AudioManager / HapticsManager와 동급의 @Service 빈.
final class BGMPlayer {

    // MARK: - Properties
    /// Bundle에 음원이 있을 때만 채워짐. nil이면 play/stop 모두 noop.
    private var player: AVAudioPlayer?
    /// Phase 6-5 — 페이드 아웃 진행 여부. 중복 stop 호출 멱등성 가드.
    /// true 동안 stop()이 다시 들어와도 noop. 예약된 stop 완료 시 false로 리셋.
    private var isFadingOut: Bool = false
    /// Phase 6-5 — 페이드 아웃 완료 후 player.stop()을 호출할 예약 작업.
    /// 새 stop/play 진입 시 cancel 후 재예약/해제. [weak self] 캡처로 인스턴스 해제 안전.
    private var stopWorkItem: DispatchWorkItem?

    // MARK: - Init
    /// bgm.m4a 로딩 시도 → 성공 시 카테고리 .playback + .mixWithOthers로 덮어쓰기 + 무한 루프 설정.
    /// 실패는 전부 graceful (try?) — 어떤 단계가 실패해도 6-3 .ambient 정책이 살아 회귀 0.
    init() {
        // 1) Bundle 음원 탐색. 없으면 player = nil로 끝 — 카테고리 변경 안 함.
        guard let url = Bundle.main.url(forResource: "bgm", withExtension: "m4a") else { return }

        // 2) AVAudioPlayer 생성 시도. 디코딩 실패도 graceful.
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return }

        // 3) 음원 로딩 성공한 *이후에만* 카테고리를 BGM 정책으로 덮어쓴다.
        //    - .playback: 무음모드 무시, 백그라운드 가능
        //    - .mixWithOthers: Apple Music 등 다른 앱 사운드와 동시 재생 허용
        //    - setActive(true) 명시 호출 안 함 — 시스템 자동 처리
        try? AVAudioSession.sharedInstance().setCategory(
            .playback, mode: .default, options: [.mixWithOthers]
        )

        // 4) 무한 루프 + prepareToPlay로 첫 play 지연 최소화.
        p.numberOfLoops = -1
        // Phase 6-5 — 첫 play()에서 페이드 인을 위해 0에서 시작. setVolume(1.0, fadeDuration:)이
        // 호출 시점의 volume에서 보간 시작하므로 이 초기화가 없으면 페이드 인이 의미를 잃는다.
        p.volume = 0
        p.prepareToPlay()
        player = p

        // Phase 6-6 — 음원 로딩 성공한 *이후에만* 인터럽션 구독.
        // player == nil인 환경(시뮬레이터/리소스 누락)에서는 어차피 play/stop이 noop이므로
        // 옵저버 등록 자체를 건너뛰어 NotificationCenter에 불필요한 등록을 남기지 않는다.
        // selector 방식은 옵저버를 약참조하지만 명시적 removeObserver(self)가 안전 패턴.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    // MARK: - Deinit
    /// Phase 6-6 — init에서 addObserver를 한 만큼 정확히 한 번 해제.
    /// Spring `@PreDestroy`와 동일 발상 — 빈 소멸 시점에 등록한 자원 회수.
    /// removeObserver(self)는 self가 등록한 모든 옵저버를 한 번에 해제하므로
    /// 본 sprint의 단일 옵저버에 대해 안전하다.
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Control
    /// player가 있고 재생 중이 아니면 페이드 인으로 시작. 이미 재생 중이면 noop(중복 호출 안전).
    /// Phase 6-5 — volume 0에서 시작해 GameConfig.bgmFadeInDuration(1.5s)에 걸쳐 1.0까지 보간.
    func play() {
        guard let player = player else { return }
        if player.isPlaying { return }              // 6-4 중복 재생 가드 유지

        // 페이드 아웃 도중이었다면 예약된 stop 취소 (재진입 안전).
        // 본 sprint에서 직접 발생하는 시나리오는 없지만 방어적으로 처리.
        stopWorkItem?.cancel()
        stopWorkItem = nil
        isFadingOut = false

        // 페이드 인: volume 0에서 시작 → 1.0까지 fadeInDuration 보간.
        // setVolume(_:fadeDuration:)은 비동기로 시스템이 처리 (Spring @Async와 동일 발상).
        player.volume = 0
        player.play()
        player.setVolume(1.0, fadeDuration: GameConfig.bgmFadeInDuration)
    }

    /// 페이드 아웃으로 정지. 페이드 완료 후 실제 player.stop() 호출. 멱등(중복 호출 안전).
    /// Phase 6-5 — GameConfig.bgmFadeOutDuration(1.0s)에 걸쳐 현재 volume → 0 보간 후 stop.
    func stop() {
        guard let player = player else { return }
        if isFadingOut { return }                   // 페이드 아웃 중 중복 stop 차단 (멱등)
        isFadingOut = true

        // 1) 시스템에게 페이드 아웃 위임 (비동기 보간).
        player.setVolume(0, fadeDuration: GameConfig.bgmFadeOutDuration)

        // 2) 페이드 완료 *후* 실제 stop. weak self 캡처로 인스턴스 해제 시 안전.
        //    SKAction 사용 불가(BGMPlayer는 SKNode 아님), Timer 금지 → 취소 가능한 DispatchWorkItem.
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.player?.stop()
            self.isFadingOut = false                // 다음 인스턴스 사이클을 위한 리셋
            self.stopWorkItem = nil
        }
        stopWorkItem = work
        DispatchQueue.main.asyncAfter(
            deadline: .now() + GameConfig.bgmFadeOutDuration,
            execute: work
        )
    }

    // MARK: - Interruption
    /// Phase 6-6 — AVAudioSession.interruptionNotification 콜백.
    /// @objc 필수 — Objective-C 런타임 selector 디스패치 대상.
    /// userInfo 파싱은 전부 옵셔널 가드 — 강제 언래핑 0.
    /// Spring `@EventListener` 비유: 시스템이 발행한 인터럽션 이벤트를 받아 디스패치.
    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            // 인터럽션 진입 — 즉시 응답이 미덕. 페이드 없음.
            pause()
        case .ended:
            // 시스템이 재개 허락한 경우에만 다시 켠다. shouldResume 비트 비활성 = noop.
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                resume()
            }
        @unknown default:
            // Apple이 향후 새 case 추가 시 컴파일러 경고로 알려주는 forward-compat 패턴.
            break
        }
    }

    /// 인터럽션 진입 시 즉시 멈춤 (페이드 없음).
    /// stop()과의 차이:
    ///   - stop()은 의도적 게임 종료 → 페이드 아웃으로 끝
    ///   - pause()는 시스템 강요 → 즉시 멈추고 player 내부 재생 위치 보존
    /// player.pause()는 currentTime을 유지하므로 ended에서 play()를 다시 부르면
    /// numberOfLoops=-1 설정과 함께 자연스럽게 이어진다.
    ///
    /// isFadingOut 가드 이유: 게임이 막 끝나 stop()이 호출된 직후(=페이드 아웃 진행 중)
    /// 인터럽션이 들어오는 경우, 어차피 곧 player.stop()이 실행될 예정.
    /// 여기서 pause()를 추가로 부르면 stopWorkItem의 player.stop()과 충돌 가능.
    /// "이미 끝나는 중인 음악은 그냥 끝나게 둔다"는 정책.
    private func pause() {
        guard let player = player else { return }
        if isFadingOut { return }
        player.pause()
    }

    /// 인터럽션 종료(.ended + shouldResume) 시 6-5의 play() 그대로 재호출.
    /// play() 내부의 isPlaying 가드 + stopWorkItem.cancel() + isFadingOut=false 초기화가
    /// 인터럽션 후 재진입 시나리오를 그대로 흡수.
    /// 별도 페이드 인 코드 작성 안 함 — 6-5의 페이드 인을 *재사용*하는 게 6-6의 우아함(DRY).
    private func resume() {
        play()
    }
}
