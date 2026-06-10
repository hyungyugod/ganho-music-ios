//
//  CharacterSelectScene.swift
//  GanhoMusic Shared
//
//  R4 §F-2 — 스와이프 캐러셀 캐릭터 선택 (03_UI §6-2). 좌 풀바디 프리뷰 + 우 카드 캐러셀.
//  배치는 +Layout, 계정·클라우드는 +Account(로직 0 변경), 오버레이 라우팅은 +Overlays 분리.
//

import SpriteKit

/// 로그인 이후 진입하는 캐릭터 선택 씬. 출발은 전 캐릭터 DifficultySelect 직행 (§C-9).
final class CharacterSelectScene: BaseMenuScene {

    // MARK: - State (Account 확장이 공유 — internal)
    var isTransitioning = false
    var selectedCharacterID: CharacterID = .kim
    var currentIndex: Int = 0
    let characters: [CharacterID] = CharacterID.allCases

    // MARK: - Repositories (Account 확장이 소유 로직 담당)
    let authProfileRepo = AuthProfileRepository()
    let statisticsRepo = StatisticsRepository()
    let highScoreRepo = HighScoreRepository()
    var accountScope = AccountProgressScopeProvider.current(authProfile: nil)
    var perDifficultyScoreRepo = PerDifficultyScoreRepository()
    var graduationRepo = GraduationRepository()
    var preferenceRepo = CharacterPreferenceRepository()
    var profileAvatarRepo = ProfileAvatarRepository.scoped(
        scope: AccountProgressScopeProvider.current(authProfile: nil)
    )
    var profileAvatarSnapshot = ProfileAvatarSnapshot.defaultKim
    var unlockStates: [CharacterID: CharacterUnlockState] = [:]
    var homeSnapshot = CharacterHomeSnapshot.empty
    var accountMenuOverlay: AccountMenuOverlayNode?
    var profileDetailOverlay: ProfileDetailOverlayNode?
    var profileDetailMode: ProfileDetailMode = .detail
    var profileAvatarDidChangeObserver: NSObjectProtocol?
    var profileNameEditDidFinishObserver: NSObjectProtocol?
    var authProfileDidChangeObserver: NSObjectProtocol?
    var shouldOpenProfileOnEntry = false
    var didShowInitialNicknamePrompt = false
    var isAccountRequestInFlight = false

    var isSelectedCharacterUnlocked: Bool {
        return unlockStates[selectedCharacterID]?.isUnlocked ?? false
    }

    // MARK: - UI (좌측 프리뷰)
    var previewSprite: SKSpriteNode?
    var previewGlow: SKSpriteNode?
    let previewNameLabel = SKLabelNode(fontNamed: Typography.V3.h1.fontName)
    let previewTagLabel = SKLabelNode(fontNamed: Typography.V3.caption.fontName)
    /// walk 2프레임 텍스처 — didMove 1회 생성·보관 (스와이프 시 재생성 금지 — 주의사항 5).
    var previewTextures: [CharacterID: [SKTexture]] = [:]

    // MARK: - UI (우측 캐러셀 — SKCropNode 클립)
    let carouselCrop = SKCropNode()
    let carouselContainer = SKNode()
    var carouselCards: [PixelCharacterCardNode] = []
    var portraitTextures: [CharacterID: SKTexture] = [:]

    // MARK: - UI (상단·하단)
    var backButton: PixelButtonNode?
    var profileChip: PixelChipNode?
    let footerLabel = SKLabelNode(fontNamed: Typography.V3.body.fontName)
    var startButton: PixelButtonNode?
    var briefingButton: PixelButtonNode?

    // MARK: - Touch (스와이프)
    private var swipeStartX: CGFloat = 0
    private var didSwipeInCurrentTouch = false

    static let previewWalkActionKey = "r4PreviewWalk"
    static let carouselSlideActionKey = "r4CarouselSlide"
    private static let footerFeedbackActionKey = "r4FooterFeedback"

    // MARK: - Factory
    class func newCharacterSelectScene(openProfileOnEntry: Bool = false) -> CharacterSelectScene {
        let scene = CharacterSelectScene(size: CGSize(width: 1024, height: 768))
        scene.scaleMode = .resizeFill
        scene.shouldOpenProfileOnEntry = openProfileOnEntry
        return scene
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        setupNightShiftBackdrop()

        configureScopedRepositories()
        selectedCharacterID = correctedSavedCharacter(preferenceRepo.current)
        currentIndex = characters.firstIndex(of: selectedCharacterID) ?? 0
        homeSnapshot = makeHomeSnapshot(for: selectedCharacterID)

        buildTextureCaches()
        setupPreview()
        setupCarousel()
        setupTopBar()
        setupFooter()
        layoutScene()
        refreshSelectionContent(animated: false)
        runStaggeredAppear(
            [previewGlow, previewSprite, previewNameLabel, previewTagLabel,
             carouselCrop, footerLabel].compactMap { $0 }
        )

        observeProfileAvatarChanges()
        observeProfileNameEditResults()
        observeAuthProfileChanges()
        if shouldOpenProfileOnEntry {
            showProfileDetailOverlay(mode: profileEntryMode())
            didShowInitialNicknamePrompt = homeSnapshot.authProfile?.needsNicknameSetup == true
        } else {
            showInitialProfilePromptIfNeeded()
        }
        syncCloudProgressIfNeeded()
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        removeAccountObservers()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard previewSprite != nil else { return }   // didMove 이전 호출 가드
        cancelStaggeredAppear()
        rebuildNightShiftBackdrop()
        layoutScene()
        accountMenuOverlay?.update(sceneSize: size, isAppleLinked: homeSnapshot.isAppleLinked)
        updateProfileDetailOverlay()
    }

    // MARK: - Texture Cache (didMove 1회 — 주의사항 5)
    private func buildTextureCaches() {
        for id in characters {
            portraitTextures[id] = PixelPortraitSprite.texture(for: id)
            let palette = PixelPalette.palette(for: id)
            previewTextures[id] = [PixelFrame.step1, PixelFrame.step2].map { frame in
                PixelSpriteRenderer.texture(
                    from: PixelSprite.data(for: id, direction: .down, frame: frame),
                    palette: palette
                )
            }
        }
    }

    // MARK: - Selection
    func selectCharacter(at index: Int, animated: Bool) {
        let clamped = max(0, min(characters.count - 1, index))
        guard clamped != currentIndex else { return }
        currentIndex = clamped
        selectedCharacterID = characters[clamped]
        if unlockStates[selectedCharacterID]?.isUnlocked == true {
            preferenceRepo.save(selectedCharacterID)
        }
        homeSnapshot = makeHomeSnapshot(for: selectedCharacterID)
        refreshSelectionContent(animated: animated)
    }

    /// 선택 변화 반영 — 프리뷰 텍스처/글로우/라벨 + 캐러셀 위치/선택 + 하단.
    func refreshSelectionContent(animated: Bool) {
        updatePreviewContent()
        updateCarousel(animated: animated)
        updateFooterContent()
        updateBriefingButton()
        updateProfileDetailOverlay()
    }

    func updateCarousel(animated: Bool) {
        for (index, card) in carouselCards.enumerated() {
            card.setSelected(index == currentIndex, animated: animated)
            card.alpha = index == currentIndex ? 1.0 : FeelTuning.R4.carouselDimAlpha
        }
        positionCarouselCards(animated: animated)
    }

    // MARK: - Feedback (잠금 출발 차단 + 계정 피드백 공용 — footer 일시 교체)
    func showFooterFeedback(_ text: String) {
        let restoredText = footerLabel.text
        footerLabel.text = text
        footerLabel.removeAction(forKey: Self.footerFeedbackActionKey)
        let wait = SKAction.wait(forDuration: UILayout.authStatusMessageDuration)
        let restore = SKAction.run { [weak self] in
            self?.footerLabel.text = restoredText
            self?.updateFooterContent()
        }
        footerLabel.run(SKAction.sequence([wait, restore]),
                        withKey: Self.footerFeedbackActionKey)
    }

    private func showLockedStartFeedback() {
        let requirement = unlockStates[selectedCharacterID]?.requirementText
            ?? UILayout.characterHomeLockedStartFeedbackText
        showFooterFeedback(
            "\(UILayout.characterHomeLockedStartFeedbackText) · \(requirement)"
        )
    }

    /// 오버레이 노출 중 배후 PixelButtonNode 자체 터치 차단 (§E-5 터치 규율).
    func setMenuControlsEnabled(_ enabled: Bool) {
        backButton?.isUserInteractionEnabled = enabled
        startButton?.isUserInteractionEnabled = enabled
        briefingButton?.isUserInteractionEnabled = enabled
    }

    // MARK: - Touch (씬 레벨 — 스와이프·카드 탭·칩 탭만. 버튼은 자체 처리 — §E-5)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if let overlay = accountMenuOverlay {
            handleAccountMenuAction(overlay.action(at: location))
            return
        }
        if let overlay = profileDetailOverlay {
            handleProfileDetailAction(overlay.action(at: location))
            return
        }

        swipeStartX = location.x
        didSwipeInCurrentTouch = false

        if let chip = profileChip,
           chip.calculateAccumulatedFrame()
               .insetBy(dx: -UILayout.R4.chipHitPadding, dy: -UILayout.R4.chipHitPadding)
               .contains(location) {
            showProfileDetailOverlay(mode: .detail)
            return
        }

        // 양옆 카드 탭 — 클립으로 숨은 카드(|offset| ≥ 2) 오탭 차단.
        // 카드는 carouselContainer 자식 — accumulatedFrame이 컨테이너 좌표라 터치도 동일 좌표계로.
        let carouselLocation = touch.location(in: carouselContainer)
        for (index, card) in carouselCards.enumerated()
        where abs(index - currentIndex) == 1 {
            if card.calculateAccumulatedFrame().contains(carouselLocation) {
                selectCharacter(at: index, animated: true)
                return
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning, !didSwipeInCurrentTouch else { return }
        guard accountMenuOverlay == nil, profileDetailOverlay == nil else { return }
        guard let touch = touches.first else { return }
        let dx = touch.location(in: self).x - swipeStartX
        if dx > UILayout.R4.selectSwipeThreshold {
            didSwipeInCurrentTouch = true
            selectCharacter(at: currentIndex - 1, animated: true)
        } else if dx < -UILayout.R4.selectSwipeThreshold {
            didSwipeInCurrentTouch = true
            selectCharacter(at: currentIndex + 1, animated: true)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        didSwipeInCurrentTouch = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        didSwipeInCurrentTouch = false
    }

    // MARK: - Transition
    func transitionToStart(openLoginChoiceOnEntry: Bool = false) {
        guard !isTransitioning, let view = self.view else { return }
        isTransitioning = true
        let scene = StartScene.newStartScene(openLoginChoiceOnEntry: openLoginChoiceOnEntry)
        SceneRouter.present(scene, on: view, route: .backward)
    }

    /// 출발 — 전 캐릭터 DifficultySelect 직행 (§C-9, 브리핑 강제 경유 폐지).
    func transitionToNext() {
        guard !isTransitioning, let view = self.view else { return }
        guard isSelectedCharacterUnlocked else {
            showLockedStartFeedback()
            return
        }
        isTransitioning = true
        preferenceRepo.save(selectedCharacterID)
        let scene = DifficultySelectScene.newDifficultySelectScene(
            characterID: selectedCharacterID
        )
        SceneRouter.present(scene, on: view, route: .forward)
    }

    /// 브리핑 보기 — 스킬 보유 캐릭터 선택 사항 (§F-2).
    func transitionToBriefing() {
        guard !isTransitioning, let view = self.view else { return }
        guard isSelectedCharacterUnlocked, selectedCharacterID.skill != .none else { return }
        isTransitioning = true
        preferenceRepo.save(selectedCharacterID)
        let scene = SkillBriefingScene.newSkillBriefingScene(
            characterID: selectedCharacterID
        )
        SceneRouter.present(scene, on: view, route: .forward)
    }
}
