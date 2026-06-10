//
//  CharacterSelectScene+Account.swift
//  GanhoMusic Shared
//
//  R4 §F-2 — 계정·프로필·클라우드 로직 분리 (1파일 300줄 규칙 대응, SPEC §D 재량).
//  v2 CharacterSelectScene의 계정 계층을 *로직 0 변경*으로 이식 — 재배선만:
//  scoped repo 4종 + 마이그레이션 + 클라우드 sync + 옵저버 3종(+해제) + 닉네임 프롬프트 +
//  ProfileDetail/AccountMenu 오버레이 라우팅 + Apple 연동/로그아웃/탈퇴.
//

import SpriteKit

extension CharacterSelectScene {

    // MARK: - Account Scope (v2 무변경 이식)
    func configureScopedRepositories() {
        let authProfile = authProfileRepo.current
        let scope = AccountProgressScopeProvider.current(authProfile: authProfile)
        accountScope = scope
        perDifficultyScoreRepo = .scoped(scope: scope)
        graduationRepo = .scoped(scope: scope)
        preferenceRepo = .scoped(scope: scope)
        profileAvatarRepo = .scoped(scope: scope)
        mergeGlobalProgressIntoLocalFallbackIfNeeded(scope: scope, authProfile: authProfile)
        rebuildUnlockStates()
        profileAvatarSnapshot = correctedProfileAvatar(profileAvatarRepo.current)
    }

    private func mergeGlobalProgressIntoLocalFallbackIfNeeded(scope: AccountProgressScope,
                                                              authProfile: AuthProfileSnapshot?) {
        guard authProfile == nil && scope.isLocalFallback else { return }
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: scope.migrationStorageKey) else { return }

        let globalScoreRepo = PerDifficultyScoreRepository()
        let globalGraduationRepo = GraduationRepository()
        let globalPreferenceRepo = CharacterPreferenceRepository()

        _ = perDifficultyScoreRepo.mergeMax(globalScoreRepo.current)
        _ = graduationRepo.mergeEarliest(globalGraduationRepo.current)
        if !preferenceRepo.hasSavedPreference && globalPreferenceRepo.hasSavedPreference {
            preferenceRepo.save(globalPreferenceRepo.current)
        }

        defaults.set(true, forKey: scope.migrationStorageKey)
    }

    /// R6 §F3 — 언락 판정용 총 별 (보유 별 0~45). 호출 시점 1회 읽기 — setup 경로 전용.
    func currentTotalStarsForUnlock() -> Int {
        return MetaProgressRepository.scoped(scope: accountScope).totalStars
    }

    func rebuildUnlockStates() {
        unlockStates = CharacterUnlockRules.states(
            graduations: graduationRepo.current,
            scores: perDifficultyScoreRepo.current,
            totalStars: currentTotalStarsForUnlock()   // R6 — 별 기반 OR 합류
        )
    }

    func correctedSavedCharacter(_ characterID: CharacterID) -> CharacterID {
        if unlockStates[characterID]?.isUnlocked == true {
            return characterID
        }
        let fallback = CharacterUnlockRules.firstUnlockedCharacter(
            graduations: graduationRepo.current,
            scores: perDifficultyScoreRepo.current,
            totalStars: currentTotalStarsForUnlock()
        )
        preferenceRepo.save(fallback)
        return fallback
    }

    func correctedProfileAvatar(_ snapshot: ProfileAvatarSnapshot) -> ProfileAvatarSnapshot {
        guard let characterID = snapshot.selectedID.characterID else {
            return snapshot
        }
        guard unlockStates[characterID]?.isUnlocked == true else {
            profileAvatarRepo.save(characterID: .kim)
            return profileAvatarRepo.current
        }
        return snapshot
    }

    func unlockedAvatarCharacters() -> [CharacterID] {
        let unlocked = CharacterID.allCases.filter { characterID in
            unlockStates[characterID]?.isUnlocked == true
        }
        guard !unlocked.isEmpty else { return [.kim] }
        if unlocked.contains(.kim) {
            return unlocked
        }
        return [.kim] + unlocked
    }

    func syncCloudProgressIfNeeded() {
        let scope = accountScope
        Task { [weak self] in
            let result = await CloudSaveCoordinator.shared.syncProgressForCurrentUser(scope: scope)
            await MainActor.run {
                guard let self = self else { return }
                guard case .merged = result else { return }
                self.configureScopedRepositories()
                if !self.isSelectedCharacterUnlocked {
                    self.selectedCharacterID = self.correctedSavedCharacter(self.selectedCharacterID)
                    self.currentIndex = self.characters.firstIndex(of: self.selectedCharacterID) ?? 0
                } else {
                    self.preferenceRepo.save(self.selectedCharacterID)
                }
                self.homeSnapshot = self.makeHomeSnapshot(for: self.selectedCharacterID)
                self.rebuildCarousel()
                self.layoutScene()
                self.refreshSelectionContent(animated: true)
            }
        }
    }

    // MARK: - Snapshot (v2 무변경 이식 — ProfileDetailOverlayNode 입력 모델)
    func makeHomeSnapshot(for characterID: CharacterID) -> CharacterHomeSnapshot {
        let auth = authProfileRepo.current
        let stats = statisticsRepo.current
        let unlockState = unlockStates[characterID]
            ?? CharacterUnlockRules.state(
                for: characterID,
                graduations: graduationRepo.current,
                scores: perDifficultyScoreRepo.current,
                totalStars: currentTotalStarsForUnlock()
            )
        let records = Difficulty.allCases.map { difficulty in
            CharacterHomeSnapshot.Record(
                difficulty: difficulty,
                bestScore: perDifficultyScoreRepo.best(
                    characterID: characterID,
                    difficulty: difficulty
                ),
                targetScore: difficulty.targetScore
            )
        }
        return CharacterHomeSnapshot(
            authProfile: auth,
            playCount: stats.playCount,
            totalScore: stats.totalScore,
            highScore: highScoreRepo.current,
            selectedCharacterID: characterID,
            unlockState: unlockState,
            records: records,
            graduatedAt: graduationRepo.graduatedAt(characterID: characterID),
            totalGraduationCount: graduationRepo.current.count
        )
    }

    // MARK: - Observers (3종 — willMove에서 해제)
    func observeProfileAvatarChanges() {
        guard profileAvatarDidChangeObserver == nil else { return }
        profileAvatarDidChangeObserver = NotificationCenter.default.addObserver(
            forName: .ganhoProfileAvatarDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleProfileAvatarDidChange(notification)
        }
    }

    private func handleProfileAvatarDidChange(_ notification: Notification) {
        if let changedScope = notification.userInfo?[UILayout.profileAvatarScopeUserInfoKey] as? AccountProgressScope,
           changedScope.storageSuffix != accountScope.storageSuffix {
            return
        }
        profileAvatarSnapshot = correctedProfileAvatar(profileAvatarRepo.current)
        refreshSelectionContent(animated: true)
        showProfileDetailOverlay(mode: .detail)
    }

    func observeProfileNameEditResults() {
        guard profileNameEditDidFinishObserver == nil else { return }
        profileNameEditDidFinishObserver = NotificationCenter.default.addObserver(
            forName: .ganhoProfileNameEditDidFinish,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleProfileNameEditDidFinish(notification)
        }
    }

    private func handleProfileNameEditDidFinish(_ notification: Notification) {
        guard let result = ProfileNameEditResult(notification: notification) else { return }
        refreshAfterAccountChange()
        if result.didSave {
            didShowInitialNicknamePrompt = true
            showFooterFeedback(UILayout.profileNameEditSavedText)
            showProfileDetailOverlay(mode: .detail)
        } else {
            showFooterFeedback(UILayout.profileNameEditFailedText)
            if result.wasNicknameRequired || homeSnapshot.authProfile?.needsNicknameSetup == true {
                showProfileDetailOverlay(mode: .nicknamePrompt)
            }
        }
    }

    func observeAuthProfileChanges() {
        guard authProfileDidChangeObserver == nil else { return }
        authProfileDidChangeObserver = NotificationCenter.default.addObserver(
            forName: .ganhoAuthProfileDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAuthProfileDidChange()
        }
    }

    private func handleAuthProfileDidChange() {
        guard !isAccountRequestInFlight else { return }
        refreshAfterAccountChange()
        showInitialProfilePromptIfNeeded()
    }

    func removeAccountObservers() {
        if let observer = profileAvatarDidChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            profileAvatarDidChangeObserver = nil
        }
        if let observer = profileNameEditDidFinishObserver {
            NotificationCenter.default.removeObserver(observer)
            profileNameEditDidFinishObserver = nil
        }
        if let observer = authProfileDidChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            authProfileDidChangeObserver = nil
        }
    }

    // MARK: - Account Change (scope 이행 + 마이그레이션)
    func refreshAfterAccountChange(migratingFrom previousScope: AccountProgressScope? = nil) {
        let previousSelection = selectedCharacterID
        configureScopedRepositories()
        if let previousScope = previousScope {
            migrateProgressIfNeeded(from: previousScope, to: accountScope)
            rebuildUnlockStates()
            profileAvatarSnapshot = correctedProfileAvatar(profileAvatarRepo.current)
        }
        selectedCharacterID = correctedSavedCharacter(previousSelection)
        currentIndex = characters.firstIndex(of: selectedCharacterID) ?? 0
        homeSnapshot = makeHomeSnapshot(for: selectedCharacterID)
        rebuildCarousel()
        rebuildProfileChip()
        layoutScene()
        refreshSelectionContent(animated: true)
    }

    private func migrateProgressIfNeeded(from oldScope: AccountProgressScope,
                                         to newScope: AccountProgressScope) {
        guard oldScope.storageSuffix != newScope.storageSuffix else { return }

        let oldScoreRepo = PerDifficultyScoreRepository.scoped(scope: oldScope)
        let oldGraduationRepo = GraduationRepository.scoped(scope: oldScope)
        let oldPreferenceRepo = CharacterPreferenceRepository.scoped(scope: oldScope)
        let oldAvatarRepo = ProfileAvatarRepository.scoped(scope: oldScope)

        _ = perDifficultyScoreRepo.mergeMax(oldScoreRepo.current)
        _ = graduationRepo.mergeEarliest(oldGraduationRepo.current)
        if !preferenceRepo.hasSavedPreference && oldPreferenceRepo.hasSavedPreference {
            preferenceRepo.save(oldPreferenceRepo.current)
        }
        profileAvatarRepo.copyAvatarIfMissing(from: oldAvatarRepo)
    }
}
