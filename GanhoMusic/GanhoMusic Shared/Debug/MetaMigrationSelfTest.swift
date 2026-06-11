//
//  MetaMigrationSelfTest.swift
//  GanhoMusic Shared
//
//  R6 §F8 — DEBUG 전용 런타임 자가검증 (마이그레이션 테스트 1파일 — 00 §리스크 완화 이행).
//  구동: env GANHO_META_SELFTEST=1 → GameViewController DEBUG 분기. XCTest 타겟 미신설 결정 —
//  본 pbxproj는 명시 등록 방식이라 타겟 수술 위험 > 효용 (SPEC §F8 명시 기각).
//  격리 UserDefaults(suiteName:)만 사용 — 실 데이터 무접촉, 시작·시나리오 간·종료 시 도메인 정리.
//  전 시나리오 통과 시 "[MetaMigrationSelfTest] PASS 8/8" 1줄, 실패 시 시나리오명 + assertionFailure.
//

#if DEBUG
import Foundation

/// T1~T8 자가검증 러너. case 없는 enum — 인스턴스화 차단.
/// @MainActor — GameViewController.viewDidLoad(메인)에서만 호출. 내부가 만지는 repo들이
/// 메인 격리 추론 대상이라 명시 격리로 경고 0 (실행 컨텍스트는 기존과 동일).
@MainActor
enum MetaMigrationSelfTest {

    private static let suiteName = "ganho.meta.selftest"
    /// 격리 suite 안의 픽스처 계정 스코프 (suffix "guest.local" — 라이브 패턴과 동형).
    private static let scope = AccountProgressScope(
        uid: StorageKeys.accountProgressLocalFallbackUID, isAnonymous: true
    )

    // MARK: - Entry
    static func runAll() {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            assertionFailure("[MetaMigrationSelfTest] 격리 suite 생성 실패")
            return
        }
        let scenarios: [(name: String, run: (UserDefaults) -> Bool)] = [
            ("T1 시드 정확성", testSeedAccuracy),
            ("T2 기존 키 byte-보존", testLegacyKeyPreservation),
            ("T3 멱등성", testIdempotency),
            ("T4 레거시 언락 보존", testLegacyUnlockPreserved),
            ("T5 모순 0", testNoVerdictStarContradiction),
            ("T6 클라우드 스키마 호환", testCloudSchemaCompatibility),
            ("T7 일일 결정성", testDailyDeterminism),
            ("T8 일일 2배", testDailyDoubleCredit)
        ]
        var passed = 0
        for scenario in scenarios {
            defaults.removePersistentDomain(forName: suiteName)
            if scenario.run(defaults) {
                passed += 1
            } else {
                assertionFailure("[MetaMigrationSelfTest] FAIL — \(scenario.name)")
            }
        }
        defaults.removePersistentDomain(forName: suiteName)
        if passed == scenarios.count {
            print("[MetaMigrationSelfTest] PASS \(passed)/\(scenarios.count)")
        }
    }

    // MARK: - Fixture (기존 repo로 레거시 데이터 작성 — 직렬화 포맷 실물과 동일)
    private static func seedLegacyFixture(_ defaults: UserDefaults) {
        let perDiff = PerDifficultyScoreRepository.scoped(scope: scope, defaults: defaults)
        // 경계 포함 7셀: ★1/★2/★3 경계와 직전 값 (§F1 표 — easy 70/91/112, normal 50/65/80, hard 40/52/64).
        perDiff.record(characterID: .kim, difficulty: .easy, score: 70)     // = ★1 경계
        perDiff.record(characterID: .jung, difficulty: .easy, score: 90)    // ★2 직전 → ★1
        perDiff.record(characterID: .geon, difficulty: .easy, score: 91)    // = ★2 경계
        perDiff.record(characterID: .im, difficulty: .easy, score: 112)     // = ★3 경계
        perDiff.record(characterID: .kim, difficulty: .normal, score: 79)   // ★3 직전 → ★2
        perDiff.record(characterID: .kim, difficulty: .hard, score: 64)     // = ★3 경계
        perDiff.record(characterID: .lee, difficulty: .hard, score: 39)     // ★1 직전 → 0 (셀 없음)
        GraduationRepository.scoped(scope: scope, defaults: defaults)
            .record(characterID: .jung, date: Date())
        StatisticsRepository(defaults: defaults).recordPlay(score: 545)
        HighScoreRepository(defaults: defaults).record(112)
    }

    private static func makeMetaRepo(_ defaults: UserDefaults) -> MetaProgressRepository {
        return MetaProgressRepository(defaults: defaults, scope: scope)
    }

    // MARK: - T1 시드 정확성 (경계 포함 스폿 ≥ 5셀)
    private static func testSeedAccuracy(_ defaults: UserDefaults) -> Bool {
        seedLegacyFixture(defaults)
        let repo = makeMetaRepo(defaults)
        repo.ensureMigrated()
        let cells = repo.starCells
        let expectations: [(CharacterID, Difficulty, Int)] = [
            (.kim, .easy, 1), (.jung, .easy, 1), (.geon, .easy, 2),
            (.im, .easy, 3), (.kim, .normal, 2), (.kim, .hard, 3)
        ]
        for (charID, diff, expected) in expectations
        where (cells[charID]?[diff] ?? 0) != expected {
            return false
        }
        // 미달 점수(39)는 셀 자체가 없어야 한다 (0 별 저장 0).
        return cells[.lee]?[.hard] == nil
    }

    // MARK: - T2 기존 키 byte-보존 (P0 게이트 직결 — 마이그레이션은 기존 키 읽기만)
    private static func testLegacyKeyPreservation(_ defaults: UserDefaults) -> Bool {
        seedLegacyFixture(defaults)
        let legacyKeys = [
            StorageKeys.highScoreUserDefaultsKey,
            StorageKeys.statisticsUserDefaultsKey,
            "\(StorageKeys.perDifficultyScoreUserDefaultsKey).\(scope.storageSuffix)",
            "\(StorageKeys.graduationUserDefaultsKey).\(scope.storageSuffix)"
        ]
        let before = legacyKeys.map { defaults.object(forKey: $0) as? NSObject }
        makeMetaRepo(defaults).ensureMigrated()
        let after = legacyKeys.map { defaults.object(forKey: $0) as? NSObject }
        for (lhs, rhs) in zip(before, after) {
            guard let lhs = lhs, let rhs = rhs, lhs.isEqual(rhs) else { return false }
        }
        return true
    }

    // MARK: - T3 멱등성 (ensureMigrated 2회 → 상태 불변)
    private static func testIdempotency(_ defaults: UserDefaults) -> Bool {
        seedLegacyFixture(defaults)
        let repo = makeMetaRepo(defaults)
        repo.ensureMigrated()
        let firstCells = repo.starCells
        let firstAchievements = repo.achievements
        repo.ensureMigrated()
        return repo.starCells == firstCells && repo.achievements == firstAchievements
    }

    // MARK: - T4 레거시 언락 보존 (구 규칙 해금 fixture → 신 판정 OR에서도 전원 해금)
    private static func testLegacyUnlockPreserved(_ defaults: UserDefaults) -> Bool {
        // 구 규칙: jung = kim 25점 / geon = jung 졸업. 총 별 0으로도 OR이 보존해야 한다.
        let scores: [CharacterID: [Difficulty: Int]] = [.kim: [.easy: 25]]
        let graduations: [CharacterID: Date] = [.jung: Date()]
        let jungUnlocked = CharacterUnlockRules.isUnlocked(
            .jung, graduations: graduations, scores: scores, totalStars: 0
        )
        let geonUnlocked = CharacterUnlockRules.isUnlocked(
            .geon, graduations: graduations, scores: scores, totalStars: 0
        )
        // 신 규칙 단독 경로도 검증: 총 별 24면 lee까지 전원 해금.
        let leeByStars = CharacterUnlockRules.isUnlocked(
            .lee, graduations: [:], scores: [:], totalStars: 24
        )
        let leeLockedAtZero = !CharacterUnlockRules.isUnlocked(
            .lee, graduations: [:], scores: [:], totalStars: 0
        )
        return jungUnlocked && geonUnlocked && leeByStars && leeLockedAtZero
    }

    // MARK: - T5 모순 0 (전 난이도 — ★1=목표 동치, 성공 ⟺ ★≥1)
    private static func testNoVerdictStarContradiction(_ defaults: UserDefaults) -> Bool {
        for difficulty in Difficulty.allCases {
            let target = difficulty.targetScore
            guard MetaProgression.stars(score: target - 1, difficulty: difficulty) == 0 else {
                return false
            }
            guard MetaProgression.stars(score: target, difficulty: difficulty) >= 1 else {
                return false
            }
            // 성공(score ≥ target) ⟺ ★ ≥ 1 동치 — 경계 양측 + 고득점 표본.
            for score in [0, target - 1, target, target + 100] {
                let isSuccess = score >= target
                let hasStar = MetaProgression.stars(score: score, difficulty: difficulty) >= 1
                guard isSuccess == hasStar else { return false }
            }
        }
        return true
    }

    // MARK: - T6 클라우드 스키마 호환 (meta 부재 구버전 JSON 디코드 + 신버전 round-trip)
    private static func testCloudSchemaCompatibility(_ defaults: UserDefaults) -> Bool {
        // 구버전 문서 — meta 필드 없음. Date는 Codable 기본(referenceDate 초) 표현.
        let legacyJSON = """
        {"highScore":70,"stats":{"playCount":3,"totalScore":150},
        "perDifficultyScores":{"kim":{"easy":70}},
        "graduations":{"kim":700000000.0},"updatedAt":700000000.0}
        """
        guard let legacyData = legacyJSON.data(using: .utf8),
              let legacy = try? JSONDecoder().decode(CloudProgressSnapshot.self, from: legacyData),
              legacy.meta == nil, legacy.highScore == 70 else {
            return false
        }
        // 신버전 round-trip — meta 포함 인코드 → 디코드 → 값 보존.
        let meta = CloudMetaProgress(
            starCells: [CharacterID.kim.rawValue: [Difficulty.easy.rawValue: 2]],
            achievements: [AchievementID.firstGraduation.rawValue: Date()],
            dailyClearedDayKeys: ["20260610"],
            counters: ["notes.total": 42]
        )
        let snapshot = CloudProgressSnapshot.make(
            highScore: 70, stats: GameStats(playCount: 3, totalScore: 150),
            perDifficultyScores: [.kim: [.easy: 70]], graduations: [:], meta: meta
        )
        guard let encoded = try? JSONEncoder().encode(snapshot),
              let decoded = try? JSONDecoder().decode(CloudProgressSnapshot.self, from: encoded),
              let decodedMeta = decoded.meta else {
            return false
        }
        return decodedMeta.starCells == meta.starCells
            && decodedMeta.dailyClearedDayKeys == meta.dailyClearedDayKeys
            && decodedMeta.counters == meta.counters
    }

    // MARK: - T7 일일 결정성 (동일 dayKey → 동일 모디파이어, 연속 100일에 6종 전부 등장)
    private static func testDailyDeterminism(_ defaults: UserDefaults) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        guard let baseDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) else {
            return false
        }
        var seen = Set<DailyModifier>()
        for offset in 0..<100 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: baseDate) else {
                return false
            }
            let key = DailyChallenge.todayKey(now: day, calendar: calendar)
            let first = DailyChallenge.modifier(forDayKey: key)
            let second = DailyChallenge.modifier(forDayKey: key)
            guard first == second else { return false }
            seen.insert(first)
        }
        return seen.count == DailyModifier.allCases.count
    }

    // MARK: - T8 일일 2배 (최초 클리어 = min(3, earned×2), 같은 dayKey 재클리어 = 일반 적립)
    private static func testDailyDoubleCredit(_ defaults: UserDefaults) -> Bool {
        let repo = makeMetaRepo(defaults)
        repo.ensureMigrated()
        let dayKey = "20260610"
        let target = Difficulty.normal.targetScore
        // 1판 — 정확히 목표(★1) 성공: 최초 클리어 → 셀 적립 2 (min(3, 1×2)).
        let first = repo.recordRun(makeRun(score: target, target: target, dayKey: dayKey))
        guard first.isDailyFirstClear, first.earnedStars == 1, first.creditedStars == 2,
              repo.starCells[.kim]?[.normal] == 2 else {
            return false
        }
        // 2판 — 같은 dayKey 재클리어 (★3 점수): 일반 적립 3 (2배 없음) → ratchet 3.
        let second = repo.recordRun(makeRun(score: target * 2, target: target, dayKey: dayKey))
        return !second.isDailyFirstClear && second.creditedStars == 3
            && repo.starCells[.kim]?[.normal] == 3
    }

    private static func makeRun(score: Int, target: Int, dayKey: String) -> RunSummary {
        return RunSummary(
            characterID: .kim, difficulty: .normal, score: score,
            maxCombo: 5, comboBreaks: 1, notesCollected: score,
            toiletsCollected: 0, skillActivations: 0, sergeantParkAppeared: false,
            dailyModifier: .speedNight, effectiveTarget: target, playedDayKey: dayKey,
            unlockedCharactersBefore: []   // R7 §F6 — 중립값 (T8 단언은 별·일일 필드만 검사)
        )
    }
}
#endif
