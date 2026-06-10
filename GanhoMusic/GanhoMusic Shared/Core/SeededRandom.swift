//
//  SeededRandom.swift
//  GanhoMusic Shared
//
//  R6 — 결정적 RNG (SPEC §F7). 같은 seed → 항상 같은 수열 (일일 도전 "하루 동일" 계약).
//  알고리즘: splitmix64 (SPEC 권장) — 작고 빠르며 통계 품질 충분, 외부 의존 0.
//  시스템 RandomNumberGenerator 채택 → Collection.randomElement(using:) 등에 그대로 주입.
//

import Foundation

/// splitmix64 기반 결정적 난수 생성기.
/// `Calendar` 로컬 dayKey(yyyyMMdd)를 seed로 받아 일일 모디파이어 추첨에 사용한다 (T7).
struct SeededRandom: RandomNumberGenerator {

    // MARK: - State
    private var state: UInt64

    // MARK: - Init
    init(seed: UInt64) {
        self.state = seed
    }

    // MARK: - RandomNumberGenerator
    /// splitmix64 1스텝. 상수는 알고리즘 정의 자체(황금비 증분·믹싱 시프트) — 도메인 수치 아님.
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
