//
//  CharacterSelectScene+Overlays.swift
//  GanhoMusic Shared
//
//  R4 §F-2 — ProfileDetail/AccountMenu 오버레이 라우팅 + Apple 연동/로그아웃/탈퇴 액션 분리
//  (1파일 300줄 규칙 대응). 오버레이 내부 변경 0 — 재배선만 (SPEC §범위 계약).
//

import SpriteKit

extension CharacterSelectScene {

    // MARK: - Profile Detail Overlay (보존 컴포넌트 재배선 — 내부 변경 0)
    func showProfileDetailOverlay(mode: ProfileDetailMode) {
        profileDetailMode = mode
        if profileDetailOverlay == nil {
            let overlay = ProfileDetailOverlayNode(sceneSize: size)
            profileDetailOverlay = overlay
            addChild(overlay)
            setMenuControlsEnabled(false)
        }
        updateProfileDetailOverlay()
    }

    func hideProfileDetailOverlay() {
        profileDetailOverlay?.removeAllActions()
        profileDetailOverlay?.removeFromParent()
        profileDetailOverlay = nil
        profileDetailMode = .detail
        if accountMenuOverlay == nil {
            setMenuControlsEnabled(true)
        }
    }

    func updateProfileDetailOverlay() {
        guard let overlay = profileDetailOverlay else { return }
        overlay.update(
            sceneSize: size,
            snapshot: homeSnapshot,
            avatar: profileAvatarSnapshot,
            repository: profileAvatarRepo,
            unlockedCharacters: unlockedAvatarCharacters(),
            mode: profileDetailMode
        )
    }

    func handleProfileDetailAction(_ action: ProfileDetailAction?) {
        guard let action = action else { return }

        switch action {
        case .editProfileName:
            requestProfileNameEdit(
                required: profileDetailMode == .nicknamePrompt
                    || homeSnapshot.authProfile?.needsNicknameSetup == true
            )
        case .chooseAvatar:
            showProfileDetailOverlay(mode: .avatarPicker)
        case .selectAvatar(let characterID):
            profileAvatarRepo.save(characterID: characterID)
            profileAvatarSnapshot = correctedProfileAvatar(profileAvatarRepo.current)
            refreshSelectionContent(animated: true)
            showProfileDetailOverlay(mode: .detail)
        case .choosePhoto:
            requestProfilePhotoPicker()
        case .openRecords:
            transitionToScoreboard(initialTab: .records)
        case .openAchievements:
            transitionToScoreboard(initialTab: .achievements)
        case .linkApple:
            hideProfileDetailOverlay()
            handleAccountAppleLinkTap()
        case .signOut:
            hideProfileDetailOverlay()
            handleAccountSignOutTap()
        case .requestDeleteConfirmation:
            hideProfileDetailOverlay()
            showAccountMenuOverlay(mode: .confirmDelete)
        case .close:
            hideProfileDetailOverlay()
        }
    }

    func profileEntryMode() -> ProfileDetailMode {
        return homeSnapshot.authProfile?.needsNicknameSetup == true ? .nicknamePrompt : .detail
    }

    func showInitialProfilePromptIfNeeded() {
        guard didShowInitialNicknamePrompt == false else { return }
        guard homeSnapshot.authProfile?.needsNicknameSetup == true else { return }
        didShowInitialNicknamePrompt = true
        showProfileDetailOverlay(mode: .nicknamePrompt)
    }

    private func requestProfileNameEdit(required: Bool) {
        let request = ProfileNameEditRequest(
            displayName: homeSnapshot.authProfile?.displayName,
            nickname: homeSnapshot.authProfile?.nickname,
            isNicknameRequired: required
        )
        NotificationCenter.default.post(
            name: .ganhoProfileNameEditRequested,
            object: nil,
            userInfo: request.userInfo
        )
    }

    private func requestProfilePhotoPicker() {
        showFooterFeedback(UILayout.profileDetailPhotoPickerRequestText)
        NotificationCenter.default.post(
            name: .ganhoProfilePhotoPickerRequested,
            object: nil,
            userInfo: [UILayout.profileAvatarScopeUserInfoKey: accountScope]
        )
    }

    /// R9 U2 — 프로필 [기록]/[업적] → Scoreboard 해당 탭 직행. 복귀 라우트 플래그로
    /// 뒤로 = CharacterSelect 프로필 재오픈 (동선 복원). 오버레이는 떠나기 전 정리 —
    /// 옵저버 해제는 기존 willMove(removeAccountObservers)가 담당 (주의사항 7).
    private func transitionToScoreboard(initialTab: ScoreboardScene.Tab) {
        guard !isTransitioning, let view = self.view else { return }
        isTransitioning = true
        hideProfileDetailOverlay()
        let scene = ScoreboardScene.newScoreboardScene(
            initialTab: initialTab,
            returnsToCharacterSelectProfile: true
        )
        SceneRouter.present(scene, on: view, route: .forward)
    }

    // MARK: - Account Menu Overlay (보존 컴포넌트 재배선 — 내부 변경 0)
    func showAccountMenuOverlay(mode: AccountMenuOverlayMode = .menu) {
        if let overlay = accountMenuOverlay {
            overlay.update(sceneSize: size, isAppleLinked: homeSnapshot.isAppleLinked, mode: mode)
            return
        }
        let overlay = AccountMenuOverlayNode(
            sceneSize: size,
            isAppleLinked: homeSnapshot.isAppleLinked,
            mode: mode
        )
        accountMenuOverlay = overlay
        addChild(overlay)
        setMenuControlsEnabled(false)
    }

    func hideAccountMenuOverlay() {
        accountMenuOverlay?.removeAllActions()
        accountMenuOverlay?.removeFromParent()
        accountMenuOverlay = nil
        if profileDetailOverlay == nil {
            setMenuControlsEnabled(true)
        }
    }

    func handleAccountMenuAction(_ action: AccountMenuAction?) {
        guard let action = action else { return }
        switch action {
        case .linkApple:
            handleAccountAppleLinkTap()
        case .signOut:
            handleAccountSignOutTap()
        case .requestDeleteConfirmation:
            showAccountMenuOverlay(mode: .confirmDelete)
        case .confirmDelete:
            handleAccountDeleteTap()
        case .cancel:
            hideAccountMenuOverlay()
        }
    }

    // MARK: - Account Actions (Firebase 호출부 — v2 무변경 이식)
    private func handleAccountAppleLinkTap() {
        guard !isAccountRequestInFlight else { return }
        guard let window = view?.window else {
            showFooterFeedback(UILayout.authActionFailedText)
            return
        }

        let previousScope = accountScope
        isAccountRequestInFlight = true
        showAccountMenuOverlay(mode: .busy)

        Task { [weak self] in
            let result = await FirebaseAuthManager.shared.signInWithApple(presentationAnchor: window)
            await MainActor.run {
                guard let self = self else { return }
                self.isAccountRequestInFlight = false
                switch result {
                case .success:
                    self.refreshAfterAccountChange(migratingFrom: previousScope)
                    self.hideAccountMenuOverlay()
                    self.showFooterFeedback(UILayout.authLinkedStatusText)
                    self.showInitialProfilePromptIfNeeded()
                    self.syncCloudProgressIfNeeded()
                    Task {
                        _ = await CloudSaveCoordinator.shared.flushPendingIfPossible()
                    }
                case .cancelled:
                    self.showAccountMenuOverlay(mode: .menu)
                    self.showFooterFeedback(UILayout.authActionCancelledText)
                case .failure(let error):
                    self.showAccountMenuOverlay(mode: .menu)
                    self.showFooterFeedback(self.appleFailureStatusText(for: error))
                }
            }
        }
    }

    private func handleAccountSignOutTap() {
        guard !isAccountRequestInFlight else { return }
        isAccountRequestInFlight = true
        showAccountMenuOverlay(mode: .busy)

        Task { [weak self] in
            let result = await FirebaseAuthManager.shared.signOutToGuestSession()
            await MainActor.run {
                guard let self = self else { return }
                self.isAccountRequestInFlight = false
                switch result {
                case .success:
                    self.transitionToStart(openLoginChoiceOnEntry: true)
                case .cancelled:
                    self.showAccountMenuOverlay(mode: .menu)
                    self.showFooterFeedback(UILayout.authActionCancelledText)
                case .failure:
                    self.showAccountMenuOverlay(mode: .menu)
                    self.showFooterFeedback(UILayout.authActionFailedText)
                }
            }
        }
    }

    private func handleAccountDeleteTap() {
        guard !isAccountRequestInFlight else { return }
        guard let window = view?.window else {
            showFooterFeedback(UILayout.authActionFailedText)
            return
        }

        isAccountRequestInFlight = true
        showAccountMenuOverlay(mode: .busy)

        Task { [weak self] in
            let result = await FirebaseAuthManager.shared.deleteCurrentAccount(presentationAnchor: window)
            await MainActor.run {
                guard let self = self else { return }
                self.isAccountRequestInFlight = false
                switch result {
                case .success:
                    self.transitionToStart(openLoginChoiceOnEntry: true)
                case .cancelled:
                    self.showAccountMenuOverlay(mode: .menu)
                    self.showFooterFeedback(UILayout.authActionCancelledText)
                case .failure:
                    self.showAccountMenuOverlay(mode: .menu)
                    self.showFooterFeedback(UILayout.authActionFailedText)
                }
            }
        }
    }

    /// Apple 실패 사유 → 카피. Optional 패턴 매칭 exhaustive — default 금지 (v2의 default 분기 해소).
    private func appleFailureStatusText(for error: AuthError?) -> String {
        switch error {
        case .appleAuthorizationTimedOut:
            return UILayout.loginChoiceAppleTimeoutText
        case .appleConfigurationFailed:
            return UILayout.loginChoiceAppleConfigurationText
        case .appleCredentialRejected:
            return UILayout.loginChoiceAppleCredentialText
        // R9 U1 — 신규 매핑 2종 전용 카피 (StartScene+Auth 중복본과 동기 수정).
        case .appleCredentialAlreadyConsumed:
            return UILayout.R9.authAppleCredentialConsumedText
        case .networkUnavailable:
            return UILayout.R9.authNetworkUnavailableText
        case .nonceGenerationFailed, .appleAuthorizationAlreadyInProgress,
             .appleCredentialMissing, .appleIdentityTokenMissing,
             .appleIdentityTokenInvalid, .appleAuthorizationCodeMissing,
             .presentationAnchorMissing, .accountDeleteFailed,
             .accountReauthenticationFailed, .none:
            return UILayout.authActionFailedText
        }
    }
}
