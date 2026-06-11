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
    private var profileNameEditorController: ProfileNameEditorViewController?
    private var activeProfileNameEditRequest: ProfileNameEditRequest?
    private var pendingProfileNameEditRequests: [ProfileNameEditRequest] = []
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
        // R3 — DEBUG 한정 PixelKit 갤러리 부팅 분기. R4 §F-8 — GANHO_BOOT_SCENE 씬 직행 분기
        // (스크린샷 자동화용). 환경변수만 사용 — UserDefaults 미사용(키 불변 조건 회피).
        // 릴리즈 빌드 동작 영향 0 (#if DEBUG 격리 — 릴리즈 경로는 StartScene 단일).
        #if DEBUG
        // R6 §F8 — env 구동 메타 자가검증 (PIXELKIT_GALLERY 전례). 격리 suite만 사용 —
        // 실행 후 평소 부팅 계속 (콘솔 "[MetaMigrationSelfTest] PASS 8/8"가 게이트 증거).
        if ProcessInfo.processInfo.environment["GANHO_META_SELFTEST"] == "1" {
            MetaMigrationSelfTest.runAll()
        }
        if ProcessInfo.processInfo.environment["PIXELKIT_GALLERY"] == "1" {
            skView.presentScene(PixelKitGalleryScene.newGalleryScene())
        } else if let bootName = ProcessInfo.processInfo.environment["GANHO_BOOT_SCENE"],
                  let bootScene = Self.debugBootScene(named: bootName) {
            skView.presentScene(bootScene)
        } else {
            skView.presentScene(StartScene.newStartScene())
        }
        #else
        let scene = StartScene.newStartScene()
        skView.presentScene(scene)
        #endif

        skView.ignoresSiblingOrder = true
        skView.isMultipleTouchEnabled = true

        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        #endif
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentPendingProfileNameEditorIfPossible()
    }

    deinit {
        if let observer = profilePhotoPickerObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = profileNameEditObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - DEBUG Boot Scene (R4 §F-8 — 스크린샷 자동화 전용)
    #if DEBUG
    /// GANHO_BOOT_SCENE 환경변수 → 씬 직행. 미해당 문자열은 nil → 기본 StartScene 폴백.
    /// String 분기는 if-나열 — switch default 금지 규칙 준수 (SPEC §F-8).
    private static func debugBootScene(named name: String) -> SKScene? {
        if name == "characterSelect" {
            return CharacterSelectScene.newCharacterSelectScene()
        }
        if name == "skillBriefing" {
            return SkillBriefingScene.newSkillBriefingScene(characterID: .jung)
        }
        if name == "difficultySelect" {
            return DifficultySelectScene.newDifficultySelectScene(characterID: .kim)
        }
        if name == "startLogin" {
            return StartScene.newStartScene(openLoginChoiceOnEntry: true)
        }
        // R5 — ResultScene은 파라미터 주입 씬: 스크린샷용 샘플 파라미터 직행 (기능 10).
        // 수치는 DEBUG 전용 표본 픽스처 — 릴리즈 경로 0 변화 (#if DEBUG 격리).
        if name == "resultSuccess" {
            return ResultScene.newResultScene(
                score: 87, bestScore: 87, isNewBest: true,
                stats: GameStats(playCount: 12, totalScore: 1_843),
                characterID: .kim, difficulty: .normal,
                maxCombo: 12, notesCollected: 34
            )
        }
        if name == "resultFail" {
            return ResultScene.newResultScene(
                score: 41, bestScore: 62, isNewBest: false,
                stats: GameStats(playCount: 5, totalScore: 412),
                characterID: .jung, difficulty: .normal,
                maxCombo: 6, notesCollected: 21
            )
        }
        if name == "scoreboard" {
            return ScoreboardScene.newScoreboardScene()
        }
        // R6 §F5 — 업적 탭 직행 (simctl 터치 주입 불가 우회 — characterSelectProfile 전례).
        if name == "scoreboardAchievements" {
            return ScoreboardScene.newScoreboardScene(initialTab: .achievements)
        }
        // R6 성능 게이트 — 음표 러시 hard 인게임 노드 측정용 직행 (FrameStats 판독).
        if name == "gameHardRush" {
            return GameScene.newGameScene(characterID: .kim, difficulty: .hard,
                                          dailyModifier: .noteRush)
        }
        // R6 — 소등(시야 비네트) 시각 확인용 직행.
        if name == "gameLightsOut" {
            return GameScene.newGameScene(characterID: .kim, difficulty: .normal,
                                          dailyModifier: .lightsOut)
        }
        // R6 §F6 — 일일 클리어 칩 + 업적 칩 스크린샷용 픽스처 (GANHO_BOOT_SCENE 확장 — SPEC 게이트 ④).
        if name == "resultDaily" {
            let runMeta = RunMetaOutcome(
                effectiveTarget: 50, earnedStars: 2, creditedStars: 3,
                dailyModifier: .goldenToilet, isDailyFirstClear: true,
                newAchievements: [.firstGraduation, .combo10],
                newlyUnlockedCharacters: [],   // R7 — 본 픽스처는 칩 전용 (배너 픽스처는 resultUnlock)
                totalStars: 7
            )
            return ResultScene.newResultScene(
                score: 66, bestScore: 66, isNewBest: true,
                stats: GameStats(playCount: 9, totalScore: 1_204),
                characterID: .kim, difficulty: .normal,
                maxCombo: 11, notesCollected: 41,
                runMeta: runMeta
            )
        }
        // R7 §F5/F6 — 해금 배너 + 업적 토스트 스크린샷용 픽스처 (시각 증빙 게이트 ③④).
        if name == "resultUnlock" {
            let runMeta = RunMetaOutcome(
                effectiveTarget: 50, earnedStars: 3, creditedStars: 3,
                dailyModifier: nil, isDailyFirstClear: false,
                newAchievements: [.combo10, .firstGraduation],
                newlyUnlockedCharacters: [.geon],
                totalStars: 9
            )
            return ResultScene.newResultScene(
                score: 84, bestScore: 84, isNewBest: true,
                stats: GameStats(playCount: 14, totalScore: 1_530),
                characterID: .jung, difficulty: .normal,
                maxCombo: 13, notesCollected: 38,
                runMeta: runMeta
            )
        }
        // R7 — 인게임 콤보 게이지/near-miss 시각 증빙용 일반 판 직행
        // (GANHO_DEMO_AUTOPILOT=1·GANHO_SKIP_CUTSCENE=1과 조합).
        if name == "gameEasy" {
            return GameScene.newGameScene(characterID: .kim, difficulty: .easy,
                                          dailyModifier: nil)
        }
        // R5 — 프로필 다이얼로그 직행 (openProfileOnEntry — simctl 터치 주입 불가 우회).
        if name == "characterSelectProfile" {
            return CharacterSelectScene.newCharacterSelectScene(openProfileOnEntry: true)
        }
        return nil
    }
    #endif

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
        guard let request = ProfileNameEditRequest(notification: notification) else { return }
        if let activeRequest = activeProfileNameEditRequest,
           profileNameEditorController != nil,
           profileNameEditRequest(activeRequest, matches: request) {
            return
        }
        guard profileNameEditorController == nil,
              presentedViewController == nil else {
            enqueuePendingProfileNameEditRequest(request)
            return
        }
        presentProfileNameEditor(
            request: request,
            message: request.isNicknameRequired
                ? UILayout.profileNameEditRequiredMessageText
                : UILayout.profileNameEditMessageText,
            displayName: request.displayName,
            nickname: request.nickname
        )
    }

    private func enqueuePendingProfileNameEditRequest(_ request: ProfileNameEditRequest) {
        guard !pendingProfileNameEditRequests.contains(where: { profileNameEditRequest($0, matches: request) }) else {
            return
        }
        pendingProfileNameEditRequests.append(request)
    }

    private func presentPendingProfileNameEditorIfPossible() {
        guard profileNameEditorController == nil,
              presentedViewController == nil,
              !pendingProfileNameEditRequests.isEmpty else {
            return
        }
        let request = pendingProfileNameEditRequests.removeFirst()
        presentProfileNameEditor(
            request: request,
            message: request.isNicknameRequired
                ? UILayout.profileNameEditRequiredMessageText
                : UILayout.profileNameEditMessageText,
            displayName: request.displayName,
            nickname: request.nickname
        )
    }

    private func profileNameEditRequest(_ lhs: ProfileNameEditRequest,
                                        matches rhs: ProfileNameEditRequest) -> Bool {
        return lhs.displayName == rhs.displayName
            && lhs.nickname == rhs.nickname
            && lhs.isNicknameRequired == rhs.isNicknameRequired
    }

    private func presentProfileNameEditor(request: ProfileNameEditRequest,
                                          message: String,
                                          displayName: String?,
                                          nickname: String?) {
        let editor = ProfileNameEditorViewController(
            titleText: request.isNicknameRequired
                ? UILayout.profileNameEditRequiredTitleText
                : UILayout.profileNameEditTitleText,
            messageText: message,
            displayName: displayName,
            nickname: nickname,
            isNicknameRequired: request.isNicknameRequired,
            validationProvider: { [weak self] nickname, isRequired in
                self?.nicknameValidationMessage(for: nickname, isRequired: isRequired)
            }
        )
        editor.modalPresentationStyle = .overFullScreen
        editor.modalTransitionStyle = .crossDissolve
        editor.onSave = { [weak self, weak editor] displayName, nickname in
            self?.saveProfileNameFromEditor(
                editor,
                request: request,
                displayName: displayName,
                nickname: nickname
            )
        }
        editor.onCancel = { [weak self, weak editor] in
            self?.cancelProfileNameEditor(editor, request: request)
        }
        activeProfileNameEditRequest = request
        profileNameEditorController = editor
        present(editor, animated: true)
    }

    private func saveProfileNameFromEditor(_ editor: ProfileNameEditorViewController?,
                                           request: ProfileNameEditRequest,
                                           displayName: String?,
                                           nickname: String?) {
        guard let editor = editor,
              editor === profileNameEditorController else {
            return
        }
        editor.setSaving(true)
        Task { [weak self, weak editor] in
            guard let self = self else { return }
            let result = await FirebaseAuthManager.shared.updateProfileName(
                displayName: self.trimmedOptionalText(displayName),
                nickname: self.trimmedOptionalText(nickname),
                isNicknameRequired: request.isNicknameRequired
            )
            await MainActor.run { [weak self, weak editor] in
                self?.finishProfileNameSave(
                    result: result,
                    editor: editor,
                    request: request
                )
            }
        }
    }

    private func finishProfileNameSave(result: AccountActionResult,
                                       editor: ProfileNameEditorViewController?,
                                       request: ProfileNameEditRequest) {
        guard let editor = editor,
              editor === profileNameEditorController else {
            return
        }

        switch result {
        case .success:
            editor.dismiss(animated: true) { [weak self, weak editor] in
                guard let self = self,
                      editor === self.profileNameEditorController else {
                    return
                }
                self.profileNameEditorController = nil
                self.activeProfileNameEditRequest = nil
                self.postProfileNameEditResult(
                    didSave: true,
                    wasNicknameRequired: request.isNicknameRequired
                )
                self.presentPendingProfileNameEditorIfPossible()
            }
        case .cancelled, .failure:
            editor.setSaving(false)
            editor.showMessage(UILayout.profileNameEditFailedText)
        }
    }

    private func cancelProfileNameEditor(_ editor: ProfileNameEditorViewController?,
                                         request: ProfileNameEditRequest) {
        guard let editor = editor,
              editor === profileNameEditorController else {
            return
        }
        editor.dismiss(animated: true) { [weak self, weak editor] in
            guard let self = self,
                  editor === self.profileNameEditorController else {
                return
            }
            self.profileNameEditorController = nil
            self.activeProfileNameEditRequest = nil
            self.postProfileNameEditResult(
                didSave: false,
                wasNicknameRequired: request.isNicknameRequired
            )
            self.presentPendingProfileNameEditorIfPossible()
        }
    }

    private func nicknameValidationMessage(for nickname: String?,
                                           isRequired: Bool) -> String? {
        guard let trimmed = trimmedOptionalText(nickname) else {
            return isRequired ? UILayout.profileNameEditNicknameEmptyText : nil
        }
        if trimmed.count < StorageKeys.profileNicknameMinLength {
            return UILayout.profileNameEditNicknameTooShortText
        }
        if trimmed.count > StorageKeys.profileNicknameMaxLength {
            return UILayout.profileNameEditNicknameTooLongText
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

private final class ProfileNameEditorViewController: UIViewController {

    // MARK: - Properties
    private let titleText: String
    private let defaultMessageText: String
    private let initialDisplayName: String?
    private let initialNickname: String?
    private let isNicknameRequired: Bool
    private let validationProvider: (String?, Bool) -> String?

    private let dimView = UIView()
    private let panelView = UIView()
    private let contentStack = UIStackView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let nicknameField = ProfileNameTextField()
    private let buttonStack = UIStackView()
    private let cancelButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private var isSaving = false

    /// 패널 수직 중심 제약. 키보드 회피 시 constant만 음수로 갱신해 패널을 위로 올린다.
    private var panelCenterYConstraint: NSLayoutConstraint?

    var onSave: ((String?, String?) -> Void)?
    var onCancel: (() -> Void)?

    // MARK: - Init
    init(titleText: String,
         messageText: String,
         displayName: String?,
         nickname: String?,
         isNicknameRequired: Bool,
         validationProvider: @escaping (String?, Bool) -> String?) {
        self.titleText = titleText
        defaultMessageText = messageText
        initialDisplayName = displayName
        initialNickname = nickname
        self.isNicknameRequired = isNicknameRequired
        self.validationProvider = validationProvider
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable, message: "Use init(titleText:messageText:displayName:nickname:isNicknameRequired:validationProvider:) instead.")
    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupDimView()
        setupPanel()
        setupContent()
        setupConstraints()
        observeKeyboard()
        updateValidationState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nicknameField.becomeFirstResponder()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Update
    func setSaving(_ saving: Bool) {
        isSaving = saving
        saveButton.isEnabled = !saving
        cancelButton.isEnabled = !saving
        saveButton.setTitle(
            saving ? UILayout.profileNameEditSavingText : UILayout.profileNameEditSaveText,
            for: .normal
        )
    }

    func showMessage(_ text: String) {
        setMessage(text, isError: true)
    }

    // MARK: - Setup
    private func setupDimView() {
        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.backgroundColor = UIColor.black.withAlphaComponent(UILayout.profileNameEditDimAlpha)
        view.addSubview(dimView)
    }

    private func setupPanel() {
        panelView.translatesAutoresizingMaskIntoConstraints = false
        panelView.backgroundColor = .ganhoPaper
        panelView.layer.cornerRadius = UILayout.profileNameEditPanelCornerRadius
        panelView.layer.borderWidth = UILayout.profileNameEditPanelBorderWidth
        panelView.layer.borderColor = UIColor.ganhoNavyDeep
            .withAlphaComponent(UILayout.profileNameEditPanelBorderAlpha)
            .cgColor
        panelView.layer.shadowColor = UIColor.ganhoNavyDeep.cgColor
        panelView.layer.shadowOpacity = UILayout.profileNameEditPanelShadowAlpha
        panelView.layer.shadowRadius = UILayout.profileNameEditPanelShadowRadius
        panelView.layer.shadowOffset = CGSize(
            width: .zero,
            height: UILayout.profileNameEditPanelShadowOffsetY
        )
        view.addSubview(panelView)
    }

    private func setupContent() {
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = UILayout.profileNameEditStackSpacing
        panelView.addSubview(contentStack)

        configureLabels()
        configureFields()
        configureButtons()

        // 모달 제목이 "닉네임 설정"이므로 표시이름 칸은 노출하지 않는다.
        // initialDisplayName은 saveTapped()에서 그대로 통과시켜 데이터 유실을 막는다.
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(messageLabel)
        contentStack.addArrangedSubview(nicknameField)
        contentStack.addArrangedSubview(buttonStack)
    }

    private func configureLabels() {
        titleLabel.text = titleText
        titleLabel.font = UIFont(name: Typography.fontDisplay, size: UILayout.profileNameEditTitleFontSize)
            ?? .boldSystemFont(ofSize: UILayout.profileNameEditTitleFontSize)
        titleLabel.textColor = .ganhoNavyDeep
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1

        messageLabel.text = defaultMessageText
        messageLabel.font = UIFont(name: Typography.fontBody, size: UILayout.profileNameEditMessageFontSize)
            ?? .systemFont(ofSize: UILayout.profileNameEditMessageFontSize)
        messageLabel.textColor = .ganhoNavyMuted
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
    }

    private func configureFields() {
        configure(textField: nicknameField, placeholder: UILayout.profileNameEditNicknamePlaceholderText)
        nicknameField.text = initialNickname
        nicknameField.autocapitalizationType = .none
        nicknameField.textContentType = .nickname
        // 단일 칸이므로 키보드 done(✓) = 저장. textFieldShouldReturn에서 saveTapped() 호출.
        nicknameField.delegate = self
    }

    private func configure(textField: UITextField, placeholder: String) {
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = placeholder
        textField.font = UIFont(name: Typography.fontBody, size: UILayout.profileNameEditFieldFontSize)
            ?? .systemFont(ofSize: UILayout.profileNameEditFieldFontSize)
        textField.textColor = .ganhoNavyDeep
        textField.tintColor = .ganhoCoralPrimary
        textField.backgroundColor = UIColor.white.withAlphaComponent(UILayout.profileNameEditFieldFillAlpha)
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.layer.cornerRadius = UILayout.profileNameEditFieldCornerRadius
        textField.layer.borderWidth = UILayout.profileNameEditFieldBorderWidth
        textField.layer.borderColor = UIColor.ganhoNavyDeep
            .withAlphaComponent(UILayout.profileNameEditFieldBorderAlpha)
            .cgColor
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        NSLayoutConstraint.activate([
            textField.heightAnchor.constraint(equalToConstant: UILayout.profileNameEditFieldHeight)
        ])
    }

    private func configureButtons() {
        buttonStack.axis = .horizontal
        buttonStack.alignment = .fill
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = UILayout.profileNameEditButtonGap

        configure(button: cancelButton, title: UILayout.profileNameEditCancelText, isPrimary: false)
        configure(button: saveButton, title: UILayout.profileNameEditSaveText, isPrimary: true)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(saveButton)
    }

    private func configure(button: UIButton, title: String, isPrimary: Bool) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont(name: Typography.fontDisplay, size: UILayout.profileNameEditButtonFontSize)
            ?? .boldSystemFont(ofSize: UILayout.profileNameEditButtonFontSize)
        button.layer.cornerRadius = UILayout.profileNameEditFieldCornerRadius
        button.layer.borderWidth = UILayout.menuControlLineWidth
        button.layer.borderColor = UIColor.ganhoNavyDeep
            .withAlphaComponent(UILayout.menuControlStrokeAlpha)
            .cgColor
        button.backgroundColor = isPrimary ? .ganhoCoralPrimary : UIColor.white.withAlphaComponent(UILayout.profileNameEditFieldFillAlpha)
        button.setTitleColor(isPrimary ? .ganhoPaper : .ganhoNavyDeep, for: .normal)
        button.heightAnchor.constraint(equalToConstant: UILayout.profileNameEditButtonHeight).isActive = true
    }

    private func setupConstraints() {
        let safe = view.safeAreaLayoutGuide
        let minimumWidth = panelView.widthAnchor.constraint(
            greaterThanOrEqualToConstant: UILayout.profileNameEditPanelMinWidth
        )
        minimumWidth.priority = UILayoutPriority(UILayout.profileNameEditPanelMinimumWidthPriority)
        let preferredWidth = panelView.widthAnchor.constraint(
            equalToConstant: UILayout.profileNameEditPanelMaxWidth
        )
        preferredWidth.priority = UILayoutPriority(UILayout.profileNameEditPanelPreferredWidthPriority)

        // 키보드 회피 시 constant만 갱신할 수 있도록 centerY 제약을 프로퍼티에 보관한다.
        let centerY = panelView.centerYAnchor.constraint(equalTo: safe.centerYAnchor)
        panelCenterYConstraint = centerY

        NSLayoutConstraint.activate([
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            panelView.centerXAnchor.constraint(equalTo: safe.centerXAnchor),
            centerY,
            panelView.widthAnchor.constraint(lessThanOrEqualToConstant: UILayout.profileNameEditPanelMaxWidth),
            preferredWidth,
            panelView.leadingAnchor.constraint(
                greaterThanOrEqualTo: safe.leadingAnchor,
                constant: UILayout.profileNameEditPanelHorizontalSafeInset
            ),
            panelView.trailingAnchor.constraint(
                lessThanOrEqualTo: safe.trailingAnchor,
                constant: -UILayout.profileNameEditPanelHorizontalSafeInset
            ),
            panelView.topAnchor.constraint(
                greaterThanOrEqualTo: safe.topAnchor,
                constant: UILayout.profileNameEditPanelVerticalSafeInset
            ),
            panelView.bottomAnchor.constraint(
                lessThanOrEqualTo: safe.bottomAnchor,
                constant: -UILayout.profileNameEditPanelVerticalSafeInset
            ),
            minimumWidth,

            contentStack.leadingAnchor.constraint(
                equalTo: panelView.leadingAnchor,
                constant: UILayout.profileNameEditContentInset
            ),
            contentStack.trailingAnchor.constraint(
                equalTo: panelView.trailingAnchor,
                constant: -UILayout.profileNameEditContentInset
            ),
            contentStack.topAnchor.constraint(
                equalTo: panelView.topAnchor,
                constant: UILayout.profileNameEditContentInset
            ),
            contentStack.bottomAnchor.constraint(
                equalTo: panelView.bottomAnchor,
                constant: -UILayout.profileNameEditContentInset
            )
        ])
    }

    // MARK: - Actions
    @objc private func textFieldDidChange() {
        updateValidationState()
    }

    @objc private func cancelTapped() {
        guard !isSaving else { return }
        view.endEditing(true)
        onCancel?()
    }

    @objc private func saveTapped() {
        guard !isSaving else { return }
        if let message = validationProvider(nicknameField.text, isNicknameRequired) {
            setMessage(message, isError: true)
            updateSaveButton(enabled: false)
            return
        }
        view.endEditing(true)
        // 표시이름 칸을 없앴으므로 보존한 initialDisplayName을 그대로 통과시킨다(데이터 유실 방지).
        // onSave 시그니처 ((String?, String?) -> Void)?는 불변 — 상위 호출부 회귀 0.
        onSave?(initialDisplayName, nicknameField.text)
    }

    // MARK: - Keyboard
    private func observeKeyboard() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillChange(_:)),
                       name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillChange(_:)),
                       name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                       name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillChange(_ note: Notification) {
        guard let frameValue = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        // 현재 레이아웃을 확정한 뒤 패널 하단과 키보드 상단의 겹침을 계산한다.
        view.layoutIfNeeded()
        let kbFrameInView = view.convert(frameValue.cgRectValue, from: nil)
        // 이미 적용된 이동량(constant)을 빼서 패널의 *원위치* 하단을 구한다.
        // 이렇게 해야 키보드 이벤트가 연달아 와도(초기 willShow+willChangeFrame, 한글 후보바 등)
        // 계산이 멱등(idempotent)해져 패널이 도로 떨어지며 가려지는 일이 없다.
        let appliedShift = panelCenterYConstraint?.constant ?? 0
        let naturalPanelBottom = panelView.frame.maxY - appliedShift
        let kbTop = kbFrameInView.minY
        let overlap = naturalPanelBottom - kbTop + UILayout.profileNameEditKeyboardClearance
        // UIKit 좌표계(좌상단 원점) — 위로 올리려면 constant는 음수. 겹치지 않으면 0.
        let shift = max(0, overlap)
        panelCenterYConstraint?.constant = -shift
        animateAlongsideKeyboard(note)
    }

    @objc private func keyboardWillHide(_ note: Notification) {
        panelCenterYConstraint?.constant = 0
        animateAlongsideKeyboard(note)
    }

    private func animateAlongsideKeyboard(_ note: Notification) {
        let duration = (note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double)
            ?? UILayout.profileNameEditKeyboardAnimationDuration
        UIView.animate(withDuration: duration) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }

    // MARK: - Validation
    private func updateValidationState() {
        guard !isSaving else { return }
        if let message = validationProvider(nicknameField.text, isNicknameRequired) {
            setMessage(message, isError: true)
            updateSaveButton(enabled: false)
            return
        }
        setMessage(defaultMessageText, isError: false)
        updateSaveButton(enabled: true)
    }

    private func setMessage(_ text: String, isError: Bool) {
        messageLabel.text = text
        messageLabel.textColor = isError ? .ganhoCoralShadow : .ganhoNavyMuted
    }

    private func updateSaveButton(enabled: Bool) {
        saveButton.isEnabled = enabled
        saveButton.alpha = enabled
            ? UILayout.menuControlEnabledAlpha
            : UILayout.profileNameEditDisabledAlpha
    }
}

// MARK: - UITextFieldDelegate
extension ProfileNameEditorViewController: UITextFieldDelegate {
    /// 단일 닉네임 칸이므로 done(✓) = 저장. 검증 통과 시 saveTapped()가
    /// endEditing(true) + onSave까지 처리하고, 검증 실패 시 메시지만 띄우고 키보드 유지.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveTapped()
        return false
    }
}

private final class ProfileNameTextField: UITextField {

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable, message: "Use init(frame:) instead.")
    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Insets
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return inset(bounds)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return inset(bounds)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return inset(bounds)
    }

    private func inset(_ bounds: CGRect) -> CGRect {
        return bounds.insetBy(
            dx: UILayout.profileNameEditFieldHorizontalInset,
            dy: .zero
        )
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
        guard let scope = notification.userInfo?[UILayout.profileAvatarScopeUserInfoKey] as? AccountProgressScope else {
            return
        }

        pendingProfileAvatarScope = scope
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = UILayout.profileAvatarPhotoSelectionLimit

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true) { [weak self] in
            self?.presentPendingProfileNameEditorIfPossible()
        }
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
                    userInfo: [UILayout.profileAvatarScopeUserInfoKey: scope]
                )
            }
        }
    }
}
