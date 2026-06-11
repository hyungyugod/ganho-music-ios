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
    /// Apple 인증 시트 타임아웃 (초) — UserDefaults 키가 아니라 Auth 정책 수치 상수.
    /// R9 U1: 12→60 — 최초 연동 동선(이메일 선택·암호 입력)이 12s를 쉽게 초과해
    /// "인증 완료했는데 튕김"을 유발하던 구조 해소 (타임아웃 발화 시 시트 동반 철회).
    static let authAppleRequestTimeout: TimeInterval = 60.0
    static let nanosecondsPerSecond: UInt64 = 1_000_000_000
    static let profileNicknameMinLength: Int = 1
    static let profileNicknameMaxLength: Int = 12

    // MARK: - Profile Avatar
    static let profileAvatarUserDefaultsKeyPrefix: String = "profileAvatar"

    // MARK: - R6 Meta System (SPEC §F2 — 신규 5키, 기존 키 diff 0. 키별 독립 저장 — 단일 blob 금지)
    /// 별 15셀 ratchet 기록 — `[String(CharacterID.rawValue): [String(Difficulty.rawValue): Int]]`.
    static let metaStarCellsUserDefaultsKey: String = "meta.starCells"
    /// 업적 달성 — `[String(AchievementID.rawValue): Date]` (달성일 보존).
    static let metaAchievementsUserDefaultsKey: String = "meta.achievements"
    /// 일일 도전 클리어 dayKey 집합 — `[String]`.
    static let metaDailyChallengeUserDefaultsKey: String = "meta.dailyChallenge"
    /// 누적 카운터(누적 음표·캐릭터별 스킬 발동) — `[String: Int]`.
    static let metaCountersUserDefaultsKey: String = "meta.counters"
    /// 마이그레이션 멱등 가드 — Int (최초 1).
    static let metaMigrationVersionUserDefaultsKey: String = "meta.migrationVersion"

    // MARK: - R9 Settings (신규 3키) + R12 BGM 1키 (기존 키 diff 0. 디바이스 레벨 — 계정 스코프 무관)
    /// 효과음 on/off — Bool. ⚠️ "키 없음 = 켬": bool(forKey:) 미존재 시 false 함정 회피를 위해
    /// SettingsRepository가 object(forKey:) as? Bool ?? true 패턴으로만 읽는다.
    static let settingsSFXEnabledUserDefaultsKey: String = "settings.sfxEnabled"
    /// 진동(햅틱) on/off — Bool. 읽기 규약은 settingsSFXEnabledUserDefaultsKey와 동일.
    static let settingsHapticsEnabledUserDefaultsKey: String = "settings.hapticsEnabled"
    /// R12 [A④] — 배경음악 on/off — Bool. 읽기 규약 동일 ("키 없음 = 켬" — 신규 1키, 추가만).
    static let settingsBGMEnabledUserDefaultsKey: String = "settings.bgmEnabled"
    /// 첫 판 조작 온보딩 힌트 1회 표시 플래그 — Bool (조작 지식은 기기 단위).
    static let onboardingControlsHintShownUserDefaultsKey: String = "onboarding.controlsHintShown"
}
