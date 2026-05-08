//
//  HighScoreRepository.swift
//  GanhoMusic Shared
//
//  Phase 3-4 · 최고 점수 영구 저장 (UserDefaults 캡슐화)
//

import Foundation

/// 최고 점수를 UserDefaults에 영구 저장하는 영속 계층.
/// 키 문자열은 호출부에 노출되지 않고 `GameConfig.highScoreUserDefaultsKey`로 단일화.
/// init에 `defaults`/`key`를 기본값으로 받아 DI를 허용 — prod는 `HighScoreRepository()`,
/// 테스트는 별도 suite를 주입할 수 있다.
/// 단일 스레드(메인) 호출 가정 → 락/큐 없음.
final class HighScoreRepository {

    // MARK: - Properties
    private let key: String
    private let defaults: UserDefaults

    // MARK: - Init
    init(defaults: UserDefaults = .standard,
         key: String = GameConfig.highScoreUserDefaultsKey) {
        self.defaults = defaults
        self.key = key
    }

    // MARK: - Read
    /// 저장된 최고 점수. 키가 없으면 UserDefaults 규약대로 0을 반환한다(Apple 보장). 캐싱 없음.
    var current: Int { defaults.integer(forKey: key) }

    // MARK: - Write
    /// 점수가 기존 최고를 갱신하면 디스크에 저장하고 true를 반환. 아니면 false.
    @discardableResult
    func record(_ score: Int) -> Bool {
        guard score > current else { return false }
        defaults.set(score, forKey: key)
        return true
    }
}
