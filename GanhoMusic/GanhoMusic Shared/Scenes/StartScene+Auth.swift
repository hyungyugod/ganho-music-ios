//
//  StartScene+Auth.swift
//  GanhoMusic Shared
//
//  R4 §F-1 — 인증 상태 머신 + 로그인 다이얼로그 플로우 분리 (1파일 300줄 규칙 대응).
//  Firebase 플로우는 v2 StartScene에서 무변경 이식 — waitForInitialAuthState /
//  signInWithApple / ensureAnonymousSession / signOutToGuestSession + isLoginRequestInFlight 가드.
//

import FirebaseAuth
import SpriteKit

extension StartScene {

    // MARK: - Auth Session (v2 무변경 이식)
    var canUseAppleLinkedSession: Bool {
        return authStateReady && currentAuthProfile?.isAppleLinked == true
    }

    func loadInitialAuthState() {
        currentAuthProfile = nil
        authStateReady = false
        refreshProfileChip()
        if shouldOpenLoginChoiceOnEntry {
            showLoginDialog(
                mode: .busy,
                statusText: UILayout.loginChoiceCheckingAccountText
            )
        }

        Task { [weak self] in
            let profile = await FirebaseAuthManager.shared.waitForInitialAuthState()
            await MainActor.run {
                guard let self = self, !self.isTransitioning else { return }
                self.authStateReady = true
                self.currentAuthProfile = profile
                // R6 §F2 — 인증 상태 확정 직후 메타 마이그레이션 (멱등 — 기존 키 읽기 전용).
                let scope = AccountProgressScopeProvider.current(authProfile: profile)
                MetaProgressRepository.scoped(scope: scope).ensureMigrated()
                self.refreshProfileChip()
                self.refreshDailyChallengeChip()   // 스코프 확정 후 클리어 표시 재계산
                self.resolveLoginChoiceOnEntryIfNeeded()
            }
        }
    }

    /// R6 §F7 — 게스트 프로필 칩 탭 → 로그인 선택 다이얼로그 (기존 LoginChoiceDialogNode 재사용).
    func presentLoginDialogForGuestProfileTap() {
        showLoginDialog()
    }

    func resolveStartButtonTap() {
        guard authStateReady else {
            showLoginDialog(
                mode: .busy,
                statusText: UILayout.loginChoiceCheckingAccountText
            )
            waitForAuthStateThenResolveStart()
            return
        }

        if currentAuthProfile?.isAppleLinked == true {
            transitionToCharacterSelect(
                openProfileOnEntry: currentAuthProfile?.needsNicknameSetup == true
            )
            return
        }

        showLoginDialog()
    }

    private func waitForAuthStateThenResolveStart() {
        Task { [weak self] in
            let profile = await FirebaseAuthManager.shared.waitForInitialAuthState()
            await MainActor.run {
                guard let self = self, !self.isTransitioning else { return }
                self.authStateReady = true
                self.currentAuthProfile = profile
                self.refreshProfileChip()
                if self.canUseAppleLinkedSession {
                    self.transitionToCharacterSelect(
                        openProfileOnEntry: profile?.needsNicknameSetup == true
                    )
                } else {
                    self.loginDialog?.setMode(.idle, statusText: "")
                }
            }
        }
    }

    private func resolveLoginChoiceOnEntryIfNeeded() {
        guard shouldOpenLoginChoiceOnEntry else { return }
        shouldOpenLoginChoiceOnEntry = false
        showLoginDialog()
    }

    // MARK: - Login Dialog (§F-1 — LoginChoiceDialogNode, Firebase 플로우 무변경)
    private func showLoginDialog(mode: LoginChoiceDialogNode.Mode = .idle,
                                 statusText: String = "") {
        if let dialog = loginDialog {
            dialog.setMode(mode, statusText: statusText)
            return
        }
        let dialog = LoginChoiceDialogNode()
        dialog.onGuest = { [weak self] in self?.handleGuestStartTap() }
        dialog.onApple = { [weak self] in self?.handleAppleStartTap() }
        dialog.onCancel = { [weak self] in self?.hideLoginDialog() }
        dialog.setMode(mode, statusText: statusText)
        loginDialog = dialog
        dialog.present(in: self)
    }

    private func hideLoginDialog() {
        loginDialog?.removeImmediately()
        loginDialog = nil
    }

    private func handleGuestStartTap() {
        guard !isLoginRequestInFlight else { return }
        isLoginRequestInFlight = true
        loginDialog?.setMode(.busy, statusText: UILayout.loginChoiceGuestBusyText)
        let needsGuestReset = Auth.auth().currentUser?.isAnonymous == false

        Task { [weak self] in
            let result: AccountActionResult
            if needsGuestReset {
                result = await FirebaseAuthManager.shared.signOutToGuestSession()
            } else {
                let user = await FirebaseAuthManager.shared.ensureAnonymousSession()
                result = user?.isAnonymous == true ? .success : .failure(nil)
            }

            await MainActor.run {
                guard let self = self else { return }
                self.isLoginRequestInFlight = false
                switch result {
                case .success:
                    self.transitionToCharacterSelect(openProfileOnEntry: false)
                case .cancelled, .failure(_):
                    self.loginDialog?.setMode(
                        .idle,
                        statusText: UILayout.loginChoiceFailureText
                    )
                }
            }
        }
    }

    private func handleAppleStartTap() {
        guard !isLoginRequestInFlight else { return }
        guard let window = view?.window else {
            loginDialog?.setMode(.idle, statusText: UILayout.loginChoiceFailureText)
            return
        }

        isLoginRequestInFlight = true
        loginDialog?.setMode(.busy, statusText: UILayout.loginChoiceAppleBusyText)

        Task { [weak self] in
            let result = await FirebaseAuthManager.shared.signInWithApple(presentationAnchor: window)
            await MainActor.run {
                guard let self = self else { return }
                self.isLoginRequestInFlight = false
                switch result {
                case .success:
                    self.currentAuthProfile = AuthProfileRepository().current
                    self.transitionToCharacterSelect(
                        openProfileOnEntry: self.currentAuthProfile?.needsNicknameSetup == true
                    )
                case .cancelled:
                    self.loginDialog?.setMode(
                        .idle,
                        statusText: UILayout.loginChoiceCancelledText
                    )
                case .failure(let error):
                    self.loginDialog?.setMode(
                        .idle,
                        statusText: self.appleFailureStatusText(for: error)
                    )
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
        case .nonceGenerationFailed, .appleAuthorizationAlreadyInProgress,
             .appleCredentialMissing, .appleIdentityTokenMissing,
             .appleIdentityTokenInvalid, .appleAuthorizationCodeMissing,
             .presentationAnchorMissing, .accountDeleteFailed,
             .accountReauthenticationFailed, .none:
            return UILayout.loginChoiceFailureText
        }
    }

    // MARK: - Transition (§F-1 — 커스텀 exit 프렐류드 제거, SceneRouter push 단일 전환)
    func transitionToCharacterSelect(openProfileOnEntry: Bool) {
        guard let view = self.view else { return }
        isTransitioning = true
        hideLoginDialog()
        let nextScene = CharacterSelectScene.newCharacterSelectScene(
            openProfileOnEntry: openProfileOnEntry
        )
        SceneRouter.present(nextScene, on: view, route: .forward)
    }
}
