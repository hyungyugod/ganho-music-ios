//
//  GameViewController.swift
//  GanhoMusic iOS
//

import UIKit
import SpriteKit
import GameplayKit
import PhotosUI

class GameViewController: UIViewController {

    // MARK: - Properties
    private var profilePhotoPickerObserver: NSObjectProtocol?
    private var profileNameEditObserver: NSObjectProtocol?
    private var pendingProfileAvatarScope: AccountProgressScope?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        observeProfilePhotoPickerRequests()
        observeProfileNameEditRequests()

        // self.view 가 SKView 가 아니면 즉시 알리고 안전하게 종료한다.
        // (강제 언래핑 `as!` 는 swift-rules.md §3 위반이라 사용하지 않음)
        guard let skView = self.view as? SKView else {
            assertionFailure("Root view must be SKView. Check Main.storyboard.")
            return
        }

        // root view(SKView)는 iOS가 윈도우 전체에 자동 mount한다. frame을 직접 만지면
        // safeAreaInsets 재계산 → viewSafeAreaInsetsDidChange 재호출 → frame 재설정의
        // 무한 재귀가 발생한다(2026-05 사고). 잘림 해소가 필요하면 SKScene 측에서
        // view.safeAreaInsets를 받아 노드 배치 시 회피해야 한다.

        // Phase 10-1a — 첫 진입은 StartScene (구 TitleScene → 4단계 분리 시작점).
        let scene = StartScene.newStartScene()
        skView.presentScene(scene)

        skView.ignoresSiblingOrder = true
        skView.isMultipleTouchEnabled = true

        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        #endif
    }

    deinit {
        if let observer = profilePhotoPickerObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = profileNameEditObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Orientation

    /// iPhone / iPad Landscape 전용 게임. 회전을 가로로만 허용한다.
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    // MARK: - Status Bar / Home Indicator

    override var prefersStatusBarHidden: Bool {
        return true
    }

    /// 풀스크린 게임 경험을 위해 홈 인디케이터를 자동 숨김.
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    /// 화면 가장자리에서 시스템 제스처(스와이프 업 등) 인식을 한 번 늦춰
    /// 게임 입력과 충돌하지 않도록 한다.
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.bottom, .top]
    }

    // MARK: - SafeArea Policy
    /// SKView frame은 직접 만지지 않는다(2026-05 무한재귀 사고 기록).
    /// safeArea 회피는 각 SKScene이 view.safeAreaInsets를 읽어 노드 좌표에 가산하는 방식만 허용.
    /// 본 메서드는 정책을 코드에 명시하기 위해 존재 — 본문은 super 호출만.
    /// 실제 회피 로직은 `SceneSafeArea.insets(for:)`를 거쳐 각 씬의 `layoutXxx()`가 담당.
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // 의도적 no-op. SKScene가 SceneSafeArea.insets(for:)로 직접 읽는다.
    }
}

// MARK: - Profile Name Edit
extension GameViewController {
    private func observeProfileNameEditRequests() {
        guard profileNameEditObserver == nil else { return }
        profileNameEditObserver = NotificationCenter.default.addObserver(
            forName: .ganhoProfileNameEditRequested,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleProfileNameEditRequested(notification)
        }
    }

    private func handleProfileNameEditRequested(_ notification: Notification) {
        guard presentedViewController == nil else { return }
        guard let request = ProfileNameEditRequest(notification: notification) else { return }
        presentProfileNameEditor(
            request: request,
            message: request.isNicknameRequired
                ? GameConfig.profileNameEditRequiredMessageText
                : GameConfig.profileNameEditMessageText,
            displayName: request.displayName,
            nickname: request.nickname
        )
    }

    private func presentProfileNameEditor(request: ProfileNameEditRequest,
                                          message: String,
                                          displayName: String?,
                                          nickname: String?) {
        let alert = UIAlertController(
            title: request.isNicknameRequired
                ? GameConfig.profileNameEditRequiredTitleText
                : GameConfig.profileNameEditTitleText,
            message: message,
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = GameConfig.profileNameEditDisplayPlaceholderText
            textField.text = displayName
            textField.autocapitalizationType = .words
            textField.clearButtonMode = .whileEditing
        }
        alert.addTextField { textField in
            textField.placeholder = GameConfig.profileNameEditNicknamePlaceholderText
            textField.text = nickname
            textField.autocapitalizationType = .none
            textField.clearButtonMode = .whileEditing
        }

        alert.addAction(
            UIAlertAction(title: GameConfig.profileNameEditCancelText, style: .cancel)
        )
        let saveAction = UIAlertAction(
            title: GameConfig.profileNameEditSaveText,
            style: .default
        ) { [weak self, weak alert] _ in
            guard let self = self else { return }
            let fields = alert?.textFields ?? []
            let displayText = self.textFieldText(at: GameConfig.profileNameEditDisplayFieldIndex, in: fields)
            let nicknameText = self.textFieldText(at: GameConfig.profileNameEditNicknameFieldIndex, in: fields)
            if let validationMessage = self.nicknameValidationMessage(
                for: nicknameText,
                isRequired: request.isNicknameRequired
            ) {
                self.reopenProfileNameEditor(
                    request: request,
                    message: validationMessage,
                    displayName: displayText,
                    nickname: nicknameText
                )
                return
            }

            Task { [weak self] in
                guard let self = self else { return }
                let result = await FirebaseAuthManager.shared.updateProfileName(
                    displayName: self.trimmedOptionalText(displayText),
                    nickname: self.trimmedOptionalText(nicknameText),
                    isNicknameRequired: request.isNicknameRequired
                )
                await MainActor.run {
                    self.postProfileNameEditResult(
                        didSave: result.isSuccess,
                        wasNicknameRequired: request.isNicknameRequired
                    )
                }
            }
        }
        alert.addAction(saveAction)
        configureProfileNameValidation(
            for: alert,
            saveAction: saveAction,
            isNicknameRequired: request.isNicknameRequired,
            defaultMessage: message
        )
        present(alert, animated: true)
    }

    private func configureProfileNameValidation(for alert: UIAlertController,
                                                saveAction: UIAlertAction,
                                                isNicknameRequired: Bool,
                                                defaultMessage: String) {
        let updateValidationState: () -> Void = { [weak self, weak alert, weak saveAction] in
            guard let self = self,
                  let alert = alert else {
                return
            }
            let fields = alert.textFields ?? []
            let nicknameText = self.textFieldText(
                at: GameConfig.profileNameEditNicknameFieldIndex,
                in: fields
            )
            if let validationMessage = self.nicknameValidationMessage(
                for: nicknameText,
                isRequired: isNicknameRequired
            ) {
                alert.message = validationMessage
            } else {
                alert.message = defaultMessage
            }
            saveAction?.isEnabled = true
        }

        alert.textFields?.forEach { textField in
            textField.addAction(
                UIAction { _ in
                    updateValidationState()
                },
                for: .editingChanged
            )
        }
        updateValidationState()
    }

    private func reopenProfileNameEditor(request: ProfileNameEditRequest,
                                         message: String,
                                         displayName: String?,
                                         nickname: String?) {
        Task { @MainActor [weak self] in
            for _ in 0..<5 {
                guard self?.presentedViewController != nil else { break }
                try? await Task.sleep(nanoseconds: GameConfig.nanosecondsPerSecond / 20)
            }
            guard let self = self, self.presentedViewController == nil else { return }
            self.presentProfileNameEditor(
                request: request,
                message: message,
                displayName: displayName,
                nickname: nickname
            )
        }
    }

    private func textFieldText(at index: Int, in fields: [UITextField]) -> String? {
        guard fields.indices.contains(index) else { return nil }
        return fields[index].text
    }

    private func nicknameValidationMessage(for nickname: String?,
                                           isRequired: Bool) -> String? {
        guard let trimmed = trimmedOptionalText(nickname) else {
            return isRequired ? GameConfig.profileNameEditNicknameEmptyText : nil
        }
        if trimmed.count < GameConfig.profileNicknameMinLength {
            return GameConfig.profileNameEditNicknameTooShortText
        }
        if trimmed.count > GameConfig.profileNicknameMaxLength {
            return GameConfig.profileNameEditNicknameTooLongText
        }
        return nil
    }

    private func trimmedOptionalText(_ text: String?) -> String? {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed = trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private func postProfileNameEditResult(didSave: Bool,
                                           wasNicknameRequired: Bool) {
        let result = ProfileNameEditResult(
            didSave: didSave,
            wasNicknameRequired: wasNicknameRequired
        )
        NotificationCenter.default.post(
            name: .ganhoProfileNameEditDidFinish,
            object: nil,
            userInfo: result.userInfo
        )
    }
}

private extension AccountActionResult {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .cancelled, .failure:
            return false
        }
    }
}

// MARK: - Profile Photo Picker
extension GameViewController: PHPickerViewControllerDelegate {
    private func observeProfilePhotoPickerRequests() {
        guard profilePhotoPickerObserver == nil else { return }
        profilePhotoPickerObserver = NotificationCenter.default.addObserver(
            forName: .ganhoProfilePhotoPickerRequested,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleProfilePhotoPickerRequested(notification)
        }
    }

    private func handleProfilePhotoPickerRequested(_ notification: Notification) {
        guard presentedViewController == nil else { return }
        guard let scope = notification.userInfo?[GameConfig.profileAvatarScopeUserInfoKey] as? AccountProgressScope else {
            return
        }

        pendingProfileAvatarScope = scope
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = GameConfig.profileAvatarPhotoSelectionLimit

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let scope = pendingProfileAvatarScope,
              let result = results.first else {
            pendingProfileAvatarScope = nil
            return
        }

        let provider = result.itemProvider
        guard provider.canLoadObject(ofClass: UIImage.self) else {
            pendingProfileAvatarScope = nil
            return
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                defer {
                    self.pendingProfileAvatarScope = nil
                }
                guard let image = object as? UIImage else { return }
                let repository = ProfileAvatarRepository.scoped(scope: scope)
                guard repository.saveCustomPhoto(image) else { return }
                NotificationCenter.default.post(
                    name: .ganhoProfileAvatarDidChange,
                    object: nil,
                    userInfo: [GameConfig.profileAvatarScopeUserInfoKey: scope]
                )
            }
        }
    }
}
