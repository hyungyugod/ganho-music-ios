//
//  AudioManager.swift
//  GanhoMusic Shared
//
//  Phase 6-2 · 시스템 사운드 효과음 캡슐화 (Manager 패턴 두 번째 적용)
//

import AudioToolbox

/// iOS 시스템 사운드를 캡슐화한 매니저. AVAudioPlayer / 외부 음원 도입 전 임시 보강.
/// Phase 5-3 CharacterID.playerSpeedMultiplier의 enum + computed property 전략을 재사용.
/// Spring 비유: HapticsManager와 동급 @Service 빈. 둘 다 side-effect 책임을 가진다.
final class AudioManager {

    // MARK: - SFX
    /// 게임 내 효과음 종류. 향후 콤보/이스터에그 등 케이스 추가 시 systemSoundID switch만 늘리면 됨(OCP).
    enum SFX {
        case noteCollected   // 노트 수집 — 짧고 밝은 톤
        case gameOver        // 게임 종료 — 묵직한 종료감

        /// Apple 내장 시스템 사운드 ID. 1000~1500 범위가 안전.
        /// GameConfig로 분리하지 않는 이유: Apple 시스템 상수라는 외부 도메인 값이며,
        /// SFX 케이스와 1:1 매핑이므로 enum 내부에 두는 게 응집도 높음.
        var systemSoundID: SystemSoundID {
            switch self {
            case .noteCollected: return 1057   // Tink — 짧고 밝은 메탈릭
            case .gameOver:      return 1073   // Boop — 묵직한 종료감
            }
            // exhaustive switch — default 없음. 케이스 추가 시 컴파일러가 강제로 매핑 추가 요구.
        }
    }

    // MARK: - Play
    /// 시스템 사운드는 즉시 발화 — HapticsManager의 prepare() 워밍 불필요.
    /// AudioServicesPlaySystemSound는 thread-safe하며 비동기로 사운드 큐에 push.
    func play(_ sfx: SFX) {
        AudioServicesPlaySystemSound(sfx.systemSoundID)
    }
}
