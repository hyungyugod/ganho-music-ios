//
//  BGMPlayer.swift
//  GanhoMusic Shared
//
//  Phase 6-4 · 자작 BGM 무한 루프 재생 인프라 (graceful fallback)
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
        p.prepareToPlay()
        player = p
    }

    // MARK: - Control
    /// player가 있고 재생 중이 아니면 play. 이미 재생 중이면 noop(중복 호출 안전).
    func play() {
        guard let player = player else { return }
        if player.isPlaying { return }
        player.play()
    }

    /// player가 있으면 stop. 없으면 noop. stop은 재생 위치를 0으로 리셋.
    func stop() {
        guard let player = player else { return }
        player.stop()
    }
}
