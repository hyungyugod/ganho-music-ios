//
//  AudioManager.swift
//  GanhoMusic Shared
//
//  Phase 6-2 · 시스템 사운드 효과음 캡슐화 (Manager 패턴 두 번째 적용)
//  Phase 6-3 · AVAudioPlayer 폴백 인프라 (자작 음원 추가 시 자동 활성화)
//  Phase 6-11 · 콤보 마일스톤 사운드 케이스 2종 추가 (3감각 완성 sprint 1/2)
//

import AVFoundation
import AudioToolbox

/// iOS 시스템 사운드를 캡슐화한 매니저. AVAudioPlayer / 외부 음원 도입 전 임시 보강.
/// Phase 5-3 CharacterID.playerSpeedMultiplier의 enum + computed property 전략을 재사용.
/// Spring 비유: HapticsManager와 동급 @Service 빈. 둘 다 side-effect 책임을 가진다.
final class AudioManager {

    // MARK: - SFX
    /// 게임 내 효과음 종류. 향후 콤보/이스터에그 등 케이스 추가 시 systemSoundID switch만 늘리면 됨(OCP).
    enum SFX {
        case noteCollected          // 노트 수집 — 짧고 밝은 톤
        case gameOver               // 게임 종료 — 묵직한 종료감
        case comboMilestoneSoft     // Phase 6-11 — 콤보 마일스톤 x3 / x5 (가벼운 환호)
        case comboMilestoneStrong   // Phase 6-11 — 콤보 마일스톤 x10 / x20 (묵직한 환호)

        /// Bundle에 실제 음원 파일이 있을 때만 AVAudioPlayer 경로로 재생.
        /// nil이면 systemSoundID 폴백만 사용. 확장자는 .wav로 고정.
        var fileName: String? {
            switch self {
            case .noteCollected:        return "note"
            case .gameOver:             return "gameover"
            case .comboMilestoneSoft:   return nil   // Phase 6-11 — 음원 부재. systemSoundID 폴백 경로로 자연 처리.
            case .comboMilestoneStrong: return nil   // Phase 6-11 — 음원 부재. 이후 sprint에서 fileName만 갈아끼우면 됨(OCP).
            }
            // exhaustive switch — default 없음. 케이스 추가 시 컴파일러가 강제로 매핑 추가 요구.
        }

        /// Apple 내장 시스템 사운드 ID. 1000~1500 범위가 안전.
        /// GameConfig로 분리하지 않는 이유: Apple 시스템 상수라는 외부 도메인 값이며,
        /// SFX 케이스와 1:1 매핑이므로 enum 내부에 두는 게 응집도 높음.
        var systemSoundID: SystemSoundID {
            switch self {
            case .noteCollected:        return 1057   // Tink — 짧고 밝은 메탈릭
            case .gameOver:             return 1073   // Boop — 묵직한 종료감
            case .comboMilestoneSoft:   return 1057   // Phase 6-11 — Tink. 노트 수집과 동일 톤(연장선의 환호).
            case .comboMilestoneStrong: return 1025   // Phase 6-11 — NewMail. 묵직하지만 긍정(gameOver 1073과 차별).
            }
            // exhaustive switch — default 없음. 케이스 추가 시 컴파일러가 강제로 매핑 추가 요구.
        }
    }

    // MARK: - Players Cache
    /// init 시점에 1회 채워지는 AVAudioPlayer 캐시. play 시 O(1) 조회.
    /// Bundle에 음원 파일이 없는 SFX 케이스는 키 자체가 없음 → play에서 폴백 분기.
    private var players: [SFX: AVAudioPlayer] = [:]

    // MARK: - Init
    /// AVAudioSession을 .ambient로 1회 설정하고, SFX 전 케이스에 대해 Bundle 음원 로딩을 시도한다.
    /// 실패는 전부 graceful — 어떤 단계가 실패해도 systemSoundID 폴백 경로는 항상 살아 있다.
    init() {
        // 1) AudioSession 카테고리 — .ambient: 무음모드 따름, 다른 앱 사운드 안 끊음 (효과음 정책).
        //    setActive(true)는 호출 안 함 — .ambient는 시스템이 자동 활성화. try?로 graceful.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [])

        // 2) SFX 전 케이스 순회 — fileName이 있고 Bundle에 실제 .wav가 있을 때만 캐시 채움.
        //    파일이 없으면 폴백 경로로 자연 전환 (예외 무시).
        //    CaseIterable 미채택 이유: enum 본체 변경을 회피하고, 명시 배열로 의도를 노출.
        // Phase 6-11 — 콤보 마일스톤 케이스 2종 추가. fileName이 nil이라 for 루프에서 자동 continue → 회귀 0.
        let allCases: [SFX] = [.noteCollected, .gameOver, .comboMilestoneSoft, .comboMilestoneStrong]
        for sfx in allCases {
            guard let name = sfx.fileName,
                  let url = Bundle.main.url(forResource: name, withExtension: "wav") else { continue }
            guard let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.prepareToPlay()
            players[sfx] = player
        }
    }

    // MARK: - Play
    /// 캐시 히트 → AVAudioPlayer (자작 음원). 미스 → AudioServicesPlaySystemSound (Phase 6-2 폴백).
    /// 동일 SFX의 1프레임 내 연속 호출은 currentTime=0 리셋 후 재시작.
    /// 시스템 사운드는 즉시 발화 — HapticsManager의 prepare() 워밍 불필요.
    /// AudioServicesPlaySystemSound는 thread-safe하며 비동기로 사운드 큐에 push.
    func play(_ sfx: SFX) {
        if let player = players[sfx] {
            player.currentTime = 0
            player.play()
            return
        }
        AudioServicesPlaySystemSound(sfx.systemSoundID)
    }
}
