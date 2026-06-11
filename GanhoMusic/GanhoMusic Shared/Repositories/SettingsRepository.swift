//
//  SettingsRepository.swift
//  GanhoMusic Shared
//
//  R9 #1 · 효과음/햅틱 on/off 영구 저장 (UserDefaults 캡슐화).
//  디바이스 레벨 — 계정 스코프(.scoped) 무관 (소리·진동은 기기 환경 설정).
//  ⚠️ 기본값 함정: bool(forKey:)는 키 미존재 시 false — "키 없음 = 켬"을 보장하기 위해
//  object(forKey:) as? Bool ?? true 패턴만 사용한다 (출시 후 전 유저가 키 미보유 상태로
//  업데이트를 수신 — 기존 경험 보존의 핵심).
//

import Foundation

/// 사운드/햅틱 설정 저장소. 패턴: DifficultyPreferenceRepository와 동형 (DI 허용 init).
/// 조회는 이벤트 시점(수집·탭)만 — update() 매 프레임 경로 비사용 (성능 계약).
final class SettingsRepository {

    // MARK: - Properties
    private let defaults: UserDefaults

    // MARK: - Init
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Read (키 없음 = 켬)
    /// 효과음 활성 여부. 키 미존재(첫 실행·업데이트 직후) = true.
    var isSFXEnabled: Bool {
        return (defaults.object(forKey: StorageKeys.settingsSFXEnabledUserDefaultsKey)
                as? Bool) ?? true
    }

    /// 햅틱(진동) 활성 여부. 키 미존재 = true.
    var isHapticsEnabled: Bool {
        return (defaults.object(forKey: StorageKeys.settingsHapticsEnabledUserDefaultsKey)
                as? Bool) ?? true
    }

    // MARK: - Write
    func setSFXEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: StorageKeys.settingsSFXEnabledUserDefaultsKey)
    }

    func setHapticsEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: StorageKeys.settingsHapticsEnabledUserDefaultsKey)
    }
}
