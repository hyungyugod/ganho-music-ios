//
//  StorageKeys.swift
//  GanhoMusic Shared
//
//  R0 — 구 god-config(분할 전 단일 Config) 분해: UserDefaults 키 + Firestore 컬렉션명 + Auth 정책 수치.
//  ⚠️ 키 문자열은 절대 불변 — 사용자 데이터 무손실 (00_MASTER_PLAN §5-2).
//

import Foundation

/// 저장소 키 네임스페이스 — UserDefaults·Firestore 키와 인증 정책 수치.
/// case 없는 enum: 인스턴스화 차단 (왜: 키 리터럴 중복을 원천 차단, 단 1회만 정의).
enum StorageKeys {
    // MARK: - High Score (Phase 3-4)
    /// UserDefaults에 최고 점수를 저장할 키. 호출부에 리터럴 노출 금지 — 단 1회만 정의.
    static let highScoreUserDefaultsKey: String = "highScore"

    // MARK: - Statistics (Phase 3-5)
    /// UserDefaults에 누적 통계(GameStats)를 JSON Data로 저장할 키. 호출부에 리터럴 노출 금지.
    static let statisticsUserDefaultsKey: String = "statistics"

    // MARK: - Character Preference (Phase 5-6)
    /// Phase 5-6 — UserDefaults에 마지막 캐릭터 선택을 raw String으로 저장할 키.
    /// 호출부에 리터럴 노출 금지 — CharacterPreferenceRepository만 사용.
    static let characterPreferenceUserDefaultsKey: String = "selectedCharacterID"
    static let accountProgressLocalFallbackUID: String = "local"
    static let accountProgressLocalFallbackMigrationKey: String = "accountProgress.localFallbackMigrated"

    // MARK: - Sprint 10 Phase I — 원본 수치 봉인 (game.js L101~L105 1:1)

    /// UserDefaults에 마지막 난이도 선택을 raw String으로 저장할 키.
    /// 호출부에 리터럴 노출 금지 — DifficultyPreferenceRepository만 사용.
    static let difficultyPreferenceUserDefaultsKey: String = "selectedDifficulty"

    // MARK: - Result Verdict (성공/실패 큰 판정)
    /// PerDifficultyScoreRepository가 사용하는 UserDefaults 키.
    /// `highScoreUserDefaultsKey`(단일 최고점)와 분리 — 두 저장소 병행 운영.
    static let perDifficultyScoreUserDefaultsKey: String = "perDifficultyScores"
    /// GraduationRepository가 사용하는 UserDefaults 키. 캐릭터별 최초 졸업 일시 저장.
    /// 신규 키 — 기존 키와 충돌 0.
    static let graduationUserDefaultsKey: String = "graduations"

    // MARK: - Firebase Auth / Cloud Save
    static let authProfileUserDefaultsKey: String = "firebaseAuthProfile"
    static let cloudPendingScoreUserDefaultsKey: String = "pendingCloudScores"
    static let cloudPendingScoreLimit: Int = 20
    static let cloudUsersCollectionName: String = "users"
    static let cloudScoresCollectionName: String = "scores"
    static let cloudProgressCollectionName: String = "progress"
    static let cloudProgressSummaryDocumentName: String = "summary"
    static let cloudDeleteBatchLimit: Int = 200
    static let authNonceLength: Int = 32
    static let authNonceCharacterSet: String = "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
    static let authAppleProviderID: String = "apple.com"
    static let authAppleRequestTimeout: TimeInterval = 12.0
    static let nanosecondsPerSecond: UInt64 = 1_000_000_000
    static let profileNicknameMinLength: Int = 1
    static let profileNicknameMaxLength: Int = 12

    // MARK: - Profile Avatar
    static let profileAvatarUserDefaultsKeyPrefix: String = "profileAvatar"
}
