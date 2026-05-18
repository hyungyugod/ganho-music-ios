//
//  DifficultyPreferenceRepository.swift
//  GanhoMusic Shared
//
//  Phase 7-1 · 난이도 선택 영구 저장 (UserDefaults 캡슐화)
//

import Foundation

/// 마지막으로 선택한 난이도(Difficulty)를 UserDefaults에 raw String으로 영구 저장.
/// 키 문자열은 GameConfig.difficultyPreferenceUserDefaultsKey로 단일화.
/// init에 defaults/key를 기본값으로 받아 DI를 허용 — prod는 DifficultyPreferenceRepository(),
/// 테스트는 별도 suite 주입 가능. 단일 스레드(메인) 호출 가정 → 락/큐 없음.
/// 패턴: CharacterPreferenceRepository(5-6)와 완전 동형.
final class DifficultyPreferenceRepository {

    // MARK: - Properties
    private let key: String
    private let defaults: UserDefaults

    // MARK: - Init
    init(defaults: UserDefaults = .standard,
         key: String = GameConfig.difficultyPreferenceUserDefaultsKey) {
        self.defaults = defaults
        self.key = key
    }

    // MARK: - Read
    /// 저장된 난이도 선택. 키가 없거나(첫 실행) 잘못된 raw value면 .easy 폴백.
    var current: Difficulty {
        guard let raw = defaults.string(forKey: key) else { return .easy }
        return Difficulty(rawValue: raw) ?? .easy
    }

    // MARK: - Write
    /// 난이도 선택을 저장. rawValue(String)로 직렬화.
    /// 호출부는 select(_:) 단일 진입점 — Spring @Transactional 단위와 동일.
    func save(_ id: Difficulty) {
        defaults.set(id.rawValue, forKey: key)
    }
}
