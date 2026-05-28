//
//  LoginOverlayView.swift
//  GanhoMusic iOS
//
//  앱스토어 출시용 첫 진입 로그인 페이지.
//

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import UIKit

final class LoginOverlayView: UIView, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    var onFinished: (() -> Void)?

    private let repository = FirebaseAccountRepository()
    private let heroPanel = UIView()
    private let heroEyebrowLabel = UILabel()
    private let heroTitleLabel = UILabel()
    private let heroSubtitleLabel = UILabel()
    private let heroStatsLabel = UILabel()
    private let panel = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let nicknameField = UITextField()
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let primaryButton = UIButton(type: .system)
    private let signInButton = UIButton(type: .system)
    private let appleButton = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
    private let guestButton = UIButton(type: .system)
    private let consentButton = UIButton(type: .system)
    private let privacyButton = UIButton(type: .system)
    private let termsButton = UIButton(type: .system)
    private let statusLabel = UILabel()

    private var currentNonce: String?
    private var hasAcceptedConsent = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .ganhoBgWarmTop

        heroPanel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(heroPanel)

        heroEyebrowLabel.text = "GANHO MUSIC"
        heroEyebrowLabel.font = UIFont(name: GameConfig.fontBody, size: 12) ?? .systemFont(ofSize: 12, weight: .semibold)
        heroEyebrowLabel.textColor = .ganhoCoralPrimary

        heroTitleLabel.text = "김간호는\n음악박사 ♪"
        heroTitleLabel.font = UIFont(name: GameConfig.fontDisplay, size: 42) ?? .boldSystemFont(ofSize: 42)
        heroTitleLabel.textColor = .ganhoNavyDeep
        heroTitleLabel.numberOfLines = 2

        heroSubtitleLabel.text = "로그인하고 나만의 간호학생을 키워보세요."
        heroSubtitleLabel.font = UIFont(name: GameConfig.fontBody, size: 16) ?? .systemFont(ofSize: 16)
        heroSubtitleLabel.textColor = .ganhoNavyMuted
        heroSubtitleLabel.numberOfLines = 0

        let best = HighScoreRepository().current
        let plays = StatisticsRepository().current.playCount
        heroStatsLabel.text = "BEST \(best)   PLAYS \(plays)"
        heroStatsLabel.font = UIFont(name: GameConfig.fontDisplay, size: 17) ?? .boldSystemFont(ofSize: 17)
        heroStatsLabel.textColor = .ganhoNavyDeep

        let heroStack = UIStackView(arrangedSubviews: [
            heroEyebrowLabel,
            heroTitleLabel,
            heroSubtitleLabel,
            heroStatsLabel
        ])
        heroStack.axis = .vertical
        heroStack.spacing = 10
        heroStack.translatesAutoresizingMaskIntoConstraints = false
        heroPanel.addSubview(heroStack)

        panel.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        panel.layer.cornerRadius = 20
        panel.layer.borderWidth = 1
        panel.layer.borderColor = UIColor.ganhoNavyDeep.withAlphaComponent(0.18).cgColor
        panel.layer.shadowColor = UIColor.ganhoNavyDeep.cgColor
        panel.layer.shadowOpacity = 0.10
        panel.layer.shadowRadius = 14
        panel.layer.shadowOffset = CGSize(width: 0, height: 8)
        panel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(panel)

        titleLabel.text = "계정으로 시작"
        titleLabel.font = UIFont(name: GameConfig.fontDisplay, size: 22) ?? .boldSystemFont(ofSize: 22)
        titleLabel.textColor = .ganhoNavyDeep
        titleLabel.textAlignment = .center

        subtitleLabel.text = "처음이면 회원가입, 이미 있다면 로그인"
        subtitleLabel.font = UIFont(name: GameConfig.fontBody, size: 11) ?? .systemFont(ofSize: 11)
        subtitleLabel.textColor = .ganhoNavyMuted
        subtitleLabel.textAlignment = .center

        configure(field: nicknameField, placeholder: "닉네임")
        nicknameField.text = UserProfileRepository().current.nickname

        configure(field: emailField, placeholder: "이메일")
        emailField.keyboardType = .emailAddress
        emailField.textContentType = .username
        emailField.autocapitalizationType = .none

        configure(field: passwordField, placeholder: "비밀번호 6자 이상")
        passwordField.isSecureTextEntry = true
        passwordField.textContentType = .password

        configure(button: primaryButton, title: "회원가입하고 시작", filled: true)
        primaryButton.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)

        configure(button: signInButton, title: "이미 계정이 있어요", filled: false)
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)

        appleButton.cornerRadius = 10
        appleButton.heightAnchor.constraint(equalToConstant: 34).isActive = true
        appleButton.addTarget(self, action: #selector(signInWithAppleTapped), for: .touchUpInside)

        configure(button: guestButton, title: "일단 게스트로 시작", filled: false)
        guestButton.addTarget(self, action: #selector(guestTapped), for: .touchUpInside)

        consentButton.setTitle("□ 개인정보 처리방침 및 이용약관에 동의", for: .normal)
        consentButton.setTitleColor(.ganhoNavyDeep, for: .normal)
        consentButton.titleLabel?.font = UIFont(name: GameConfig.fontBody, size: 11) ?? .systemFont(ofSize: 11)
        consentButton.contentHorizontalAlignment = .left
        consentButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        consentButton.addTarget(self, action: #selector(consentTapped), for: .touchUpInside)

        configureLinkButton(privacyButton, title: "개인정보 처리방침 보기")
        privacyButton.addTarget(self, action: #selector(privacyTapped), for: .touchUpInside)

        configureLinkButton(termsButton, title: "이용약관 보기")
        termsButton.addTarget(self, action: #selector(termsTapped), for: .touchUpInside)

        statusLabel.font = UIFont(name: GameConfig.fontBody, size: 11) ?? .systemFont(ofSize: 11)
        statusLabel.textColor = .ganhoNavyMuted
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2

        let secondaryStack = UIStackView(arrangedSubviews: [
            signInButton,
            guestButton
        ])
        secondaryStack.axis = .horizontal
        secondaryStack.spacing = 8
        secondaryStack.distribution = .fillEqually

        let legalStack = UIStackView(arrangedSubviews: [
            privacyButton,
            termsButton
        ])
        legalStack.axis = .horizontal
        legalStack.spacing = 8
        legalStack.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            nicknameField,
            emailField,
            passwordField,
            consentButton,
            legalStack,
            primaryButton,
            appleButton,
            secondaryStack,
            statusLabel
        ])
        stack.axis = .vertical
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(stack)

        NSLayoutConstraint.activate([
            heroPanel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 70),
            heroPanel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 32),
            heroPanel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -32),
            heroPanel.trailingAnchor.constraint(equalTo: panel.leadingAnchor, constant: -44),
            heroStack.leadingAnchor.constraint(equalTo: heroPanel.leadingAnchor),
            heroStack.trailingAnchor.constraint(lessThanOrEqualTo: heroPanel.trailingAnchor),
            heroStack.centerYAnchor.constraint(equalTo: heroPanel.centerYAnchor),
            panel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -82),
            panel.centerYAnchor.constraint(equalTo: centerYAnchor),
            panel.widthAnchor.constraint(equalToConstant: 350),
            stack.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -22),
            stack.topAnchor.constraint(equalTo: panel.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -12)
        ])
    }

    private func configure(field: UITextField, placeholder: String) {
        field.placeholder = placeholder
        field.borderStyle = .none
        field.backgroundColor = UIColor.ganhoPaper.withAlphaComponent(0.85)
        field.layer.cornerRadius = 10
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.leftViewMode = .always
        field.font = UIFont(name: GameConfig.fontBody, size: 13) ?? .systemFont(ofSize: 13)
        field.heightAnchor.constraint(equalToConstant: 32).isActive = true
    }

    private func configure(button: UIButton, title: String, filled: Bool) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont(name: GameConfig.fontBody, size: 13) ?? .systemFont(ofSize: 13, weight: .semibold)
        button.layer.cornerRadius = 10
        if filled {
            button.heightAnchor.constraint(equalToConstant: 34).isActive = true
            button.backgroundColor = .ganhoCoralPrimary
            button.setTitleColor(.white, for: .normal)
        } else {
            button.heightAnchor.constraint(equalToConstant: 28).isActive = true
            button.backgroundColor = .clear
            button.setTitleColor(.ganhoNavyDeep, for: .normal)
        }
    }

    private func configureLinkButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.ganhoCoralPrimary, for: .normal)
        button.titleLabel?.font = UIFont(name: GameConfig.fontBody, size: 10) ?? .systemFont(ofSize: 10)
        button.heightAnchor.constraint(equalToConstant: 17).isActive = true
    }

    @objc private func signUpTapped() {
        endEditing(true)
        guard validateConsent() else { return }
        guard validateEmailAndPassword() else { return }
        setBusy(true, message: "계정을 만들고 있어요")
        Task { @MainActor in
            let result = await repository.signUpOrLinkEmail(
                email: emailField.text ?? "",
                password: passwordField.text ?? "",
                nickname: nicknameField.text ?? ""
            )
            handle(result: result, fallbackMessage: "회원가입에 실패했어요. 이메일/비밀번호를 확인해 주세요.")
        }
    }

    @objc private func signInTapped() {
        endEditing(true)
        guard validateEmailAndPassword() else { return }
        setBusy(true, message: "로그인 중이에요")
        Task { @MainActor in
            let result = await repository.signInEmail(
                email: emailField.text ?? "",
                password: passwordField.text ?? ""
            )
            handle(result: result, fallbackMessage: "로그인에 실패했어요. 이메일/비밀번호를 확인해 주세요.")
        }
    }

    @objc private func guestTapped() {
        setBusy(true, message: "게스트 기록을 준비하고 있어요")
        Task { @MainActor in
            _ = await repository.bootstrapProfile()
            finish()
        }
    }

    @objc private func signInWithAppleTapped() {
        guard validateConsent() else { return }
        guard let nonce = randomNonceString() else {
            statusLabel.text = "Apple 로그인 준비에 실패했어요. 다시 시도해 주세요."
            return
        }
        currentNonce = nonce
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        setBusy(true, message: "Apple로 로그인 중이에요")
        controller.performRequests()
    }

    @objc private func consentTapped() {
        hasAcceptedConsent.toggle()
        let mark = hasAcceptedConsent ? "✓" : "□"
        consentButton.setTitle("\(mark) 개인정보 처리방침 및 이용약관에 동의", for: .normal)
        statusLabel.text = nil
    }

    @objc private func privacyTapped() {
        presentLegalDocument(
            title: "개인정보 처리방침",
            message: """
            김간호는 음악박사는 계정 생성과 기록 저장을 위해 이메일 주소, Apple 로그인 식별자, 닉네임, 프로필 사진, 플레이 기록, 점수, 선택 캐릭터 정보를 수집할 수 있습니다.

            수집된 정보는 로그인, 기록 동기화, 프로필 표시, 서비스 운영 목적으로만 사용되며 Firebase Authentication, Cloud Firestore, Firebase Storage에 저장됩니다.

            사용자는 앱 내 로그아웃 및 향후 제공되는 계정 삭제 기능을 통해 계정 처리를 요청할 수 있습니다. 정식 출시 전 공개 개인정보 처리방침 URL을 App Store Connect와 앱 안에 연결해야 합니다.
            """
        )
    }

    @objc private func termsTapped() {
        presentLegalDocument(
            title: "이용약관",
            message: """
            김간호는 음악박사는 개인 학습과 재미를 위한 게임 서비스입니다. 사용자는 계정을 안전하게 관리해야 하며, 타인의 정보를 사용하거나 서비스 운영을 방해해서는 안 됩니다.

            게임 기록과 프로필 정보는 서비스 개선과 사용자 경험 제공을 위해 저장될 수 있습니다. 비정상적인 이용이 확인되면 서비스 이용이 제한될 수 있습니다.

            정식 출시 전 최종 이용약관 URL을 App Store Connect 및 앱 안에 연결해야 합니다.
            """
        )
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            setBusy(false, message: "Apple 로그인 정보를 읽지 못했어요.")
            return
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: token,
            rawNonce: nonce,
            fullName: credential.fullName
        )

        Task { @MainActor in
            do {
                let result: AuthDataResult
                if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
                    do {
                        result = try await currentUser.link(with: firebaseCredential)
                    } catch {
                        FirebaseDiagnostics.error("Anonymous Apple link failed. Falling back to Apple sign-in.", error: error)
                        result = try await Auth.auth().signIn(with: firebaseCredential)
                    }
                } else {
                    result = try await Auth.auth().signIn(with: firebaseCredential)
                }
                let name = [credential.fullName?.familyName, credential.fullName?.givenName]
                    .compactMap { $0 }
                    .joined()
                let nickname = name.isEmpty ? UserProfileRepository().current.nickname : name
                let sync = await repository.syncSignedInPersonalProfile(
                    nickname: nickname,
                    email: result.user.email
                )
                handle(result: sync, fallbackMessage: "Apple 로그인 후 프로필 저장에 실패했어요.")
            } catch {
                FirebaseDiagnostics.error("Apple sign-in failed.", error: error)
                setBusy(false, message: "Apple 로그인에 실패했어요.")
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        FirebaseDiagnostics.error("Apple authorization failed.", error: error)
        setBusy(false, message: "Apple 로그인이 취소되었어요.")
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return window ?? UIWindow()
    }

    private func handle(result: FirebaseAccountSyncResult, fallbackMessage: String) {
        setBusy(false, message: nil)
        if case .synced = result {
            finish()
        } else if case let .failed(message) = result {
            statusLabel.text = message
        } else {
            statusLabel.text = fallbackMessage
        }
    }

    private func validateEmailAndPassword() -> Bool {
        let email = (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordField.text ?? ""
        guard email.contains("@"), email.contains(".") else {
            statusLabel.text = "이메일 주소를 입력해 주세요."
            return false
        }
        guard password.count >= 6 else {
            statusLabel.text = "비밀번호는 6자 이상 입력해 주세요."
            return false
        }
        return true
    }

    private func validateConsent() -> Bool {
        guard hasAcceptedConsent else {
            statusLabel.text = "회원가입과 Apple 로그인에는 약관 동의가 필요해요."
            return false
        }
        return true
    }

    private func presentLegalDocument(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        window?.rootViewController?.present(alert, animated: true)
    }

    private func finish() {
        UIView.animate(withDuration: 0.22, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
            self.onFinished?()
        })
    }

    private func setBusy(_ busy: Bool, message: String?) {
        [primaryButton, signInButton, appleButton, guestButton].forEach { $0.isEnabled = !busy }
        statusLabel.text = message
    }

    private func randomNonceString(length: Int = 32) -> String? {
        guard length > 0 else { return nil }
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess {
                FirebaseDiagnostics.error("Unable to generate Apple sign-in nonce.")
                return nil
            }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
}
