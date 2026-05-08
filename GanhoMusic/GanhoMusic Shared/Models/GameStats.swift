//
//  GameStats.swift
//  GanhoMusic Shared
//
//  Phase 3-5 · 누적 통계 값 객체 (Codable)
//

import Foundation

/// 누적 통계 값 객체. UserDefaults에 JSON으로 직렬화되어 저장된다.
/// `Codable` 채택으로 init(from:)/encode(to:)는 컴파일러 자동 합성.
/// 모든 필드 var + 기본값 → 인자 없는 GameStats() 생성 가능 → 첫 실행/디코드 실패 시 폴백.
struct GameStats: Codable {
    var playCount: Int = 0
    var totalScore: Int = 0
}
