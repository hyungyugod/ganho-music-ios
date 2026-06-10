//
//  CloudSaveCoordinator.swift
//  GanhoMusic Shared
//
//  게임 종료 cloud save와 pending queue flush를 조율한다.
//

import Foundation

enum CloudSaveResult {
    case saved
    case queued
    case skipped
}

enum CloudProgressSyncResult {
    case merged
    case skipped
    case failed
}

final class CloudSaveCoordinator {

    // MARK: - Properties
    static let shared = CloudSaveCoordinator()

    private let cloudRepository: CloudProgressRepository
    private let pendingRepository: PendingCloudScoreRepository
    private let authProfileRepository: AuthProfileRepository

    // MARK: - Init
    init(cloudRepository: CloudProgressRepository = CloudProgressRepository(),
         pendingRepository: PendingCloudScoreRepository = PendingCloudScoreRepository(),
         authProfileRepository: AuthProfileRepository = AuthProfileRepository()) {
        self.cloudRepository = cloudRepository
        self.pendingRepository = pendingRepository
        self.authProfileRepository = authProfileRepository
    }

    // MARK: - Save
    @discardableResult
    func saveGameResult(record: CloudScoreRecord,
                        progress: CloudProgressSnapshot) async -> CloudSaveResult {
        guard let user = await FirebaseAuthManager.shared.ensureAnonymousSession() else {
            pendingRepository.enqueue(record)
            return .queued
        }

        let profile = profileSnapshot(user: user)
        authProfileRepository.save(snapshot: profile)

        do {
            try await cloudRepository.save(profile: profile, record: record, progress: progress)
            await flushPendingIfPossible()
            return .saved
        } catch {
            pendingRepository.enqueue(record)
            return .queued
        }
    }

    @discardableResult
    func flushPendingIfPossible() async -> CloudSaveResult {
        let pendingRecords = pendingRepository.current
        guard !pendingRecords.isEmpty else { return .skipped }
        guard let user = await FirebaseAuthManager.shared.ensureAnonymousSession() else {
            return .queued
        }

        let profile = profileSnapshot(user: user)
        let progress = currentProgressSnapshot()

        do {
            try await cloudRepository.save(profile: profile, records: pendingRecords, progress: progress)
            pendingRepository.remove(localIDs: Set(pendingRecords.map { $0.localID }))
            authProfileRepository.save(snapshot: profile)
            return .saved
        } catch {
            return .queued
        }
    }

    @discardableResult
    func syncProgressForCurrentUser(scope: AccountProgressScope) async -> CloudProgressSyncResult {
        guard let profile = authProfileRepository.current,
              !profile.uid.isEmpty else {
            return .skipped
        }

        do {
            guard let progress = try await cloudRepository.fetchProgress(uid: profile.uid) else {
                return .skipped
            }
            let scoreRepository = PerDifficultyScoreRepository.scoped(scope: scope)
            let graduationRepository = GraduationRepository.scoped(scope: scope)
            let didMergeScores = scoreRepository.mergeMax(progress.typedPerDifficultyScores)
            let didMergeGraduations = graduationRepository.mergeEarliest(progress.typedGraduations)
            // R6 §F4 — 메타 머지: 별 셀 max / 업적 합집합(이른 날짜) / 일일 합집합 / 카운터 max.
            // 실패해도 로컬 우선 — meta 부재(구버전 문서)는 nil 분기로 자연 skip.
            let metaRepository = MetaProgressRepository.scoped(scope: scope)
            metaRepository.ensureMigrated()
            var didMergeMeta = false
            if let cloudMeta = progress.meta {
                didMergeMeta = metaRepository.merge(cloudMeta: cloudMeta)
            }
            // 머지 후 점수 기반 별 재파생 max 1회 (§F2 갱신 지점 ② — 클라우드 신점수 → 별 동기).
            let didReapplyStars = metaRepository.reapplyStarRatchet(scores: scoreRepository.current)
            return didMergeScores || didMergeGraduations || didMergeMeta || didReapplyStars
                ? .merged : .skipped
        } catch {
            return .failed
        }
    }

    // MARK: - Snapshot
    private func profileSnapshot(user: FirebaseAuthUserProviding) -> AuthProfileSnapshot {
        let existing = authProfileRepository.current
        let isSameUser = existing?.uid == user.uid
        let displayName = isSameUser
            ? sanitizedOptionalText(existing?.displayName)
            : sanitizedOptionalText(user.displayName)
        let nickname = isSameUser
            ? sanitizedOptionalText(existing?.nickname)
            : nil
        return AuthProfileSnapshot(
            uid: user.uid,
            isAnonymous: user.isAnonymous,
            displayName: displayName,
            nickname: nickname,
            providerIDs: user.providerIDs,
            updatedAt: Date()
        )
    }

    private func sanitizedOptionalText(_ text: String?) -> String? {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed = trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private func currentProgressSnapshot() -> CloudProgressSnapshot {
        let scope = AccountProgressScopeProvider.current(authProfile: authProfileRepository.current)
        return CloudProgressSnapshot.make(
            highScore: HighScoreRepository().current,
            stats: StatisticsRepository().current,
            perDifficultyScores: PerDifficultyScoreRepository.scoped(scope: scope).current,
            graduations: GraduationRepository.scoped(scope: scope).current,
            meta: MetaProgressRepository.scoped(scope: scope).cloudMeta()   // R6 §F4
        )
    }
}

protocol FirebaseAuthUserProviding {
    var uid: String { get }
    var isAnonymous: Bool { get }
    var displayName: String? { get }
    var providerIDs: [String] { get }
}
