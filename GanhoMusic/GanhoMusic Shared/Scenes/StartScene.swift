//
//  StartScene.swift
//  GanhoMusic Shared
//
//  앱 첫 진입 화면. 타이틀, NurseAvatar, 시작 버튼을 배치하고
//  시작 탭 이후 로그인 선택을 거쳐 CharacterSelectScene으로 넘긴다.
//

import FirebaseAuth
import SpriteKit

/// 앱 첫 진입 씬. v2 리스킨: 그라데이션 + AccentLine + 2-라인 Jua 타이틀 + 태그라인 +
/// 좌측 NurseAvatarNode + 시작 버튼.
/// Sprint 6 — 난이도 카드/repo/select 로직 모두 삭제. characterRepo만 유지(다음 씬이 자기 repo로 다시 읽음).
final class StartScene: BaseMenuScene {

    // MARK: - Properties
    /// 씬 전환이 시작됐는지 여부. true가 되면 추가 탭은 무시 — 더블 enter 방지.
    private var isTransitioning = false
    /// Sprint 2 — Jua 2-라인 타이틀. line1 "김간호는"(navyDeep 44pt), line2 "음악박사 ♪"(coral 56pt).
    private let titleLine1 = SKLabelNode(fontNamed: Typography.fontDisplay)
    private let titleLine2 = SKLabelNode(fontNamed: Typography.fontDisplay)
    /// Sprint 2 — 타이틀 위 AccentLine(32×3 코랄).
    private let accentLine = AccentLineNode()
    /// Sprint 2 — Gowun Dodum 태그라인(2줄 자동 줄바꿈).
    private let taglineLabel = SKLabelNode(fontNamed: Typography.fontBody)
    /// 시작 버튼 — 명시 탭만 다음 단계로 진행.
    private let startButton = PrimaryButtonNode(text: "시작")
    /// 캐릭터 선택 영속 계층. didMove에서 .current로 복원 — 10-1a는 GameScene 직진 시점에 사용.
    /// 10-1b 이후는 CharacterSelectScene이 자기 repo로 다시 읽는다(불변 흐름).
    private let characterRepo = CharacterPreferenceRepository()
    /// Phase 10-2 — 음표 파티클 컨테이너. 씬 사이즈 의존 — didChangeSize 시 재생성.
    private var musicNoteEmitter: MusicNoteEmitterNode?
    /// Sprint 6 — 좌측 김간호 큰 그림. SKShapeNode 컨테이너. didChangeSize에서 재배치.
    private var nurseAvatar: NurseAvatarNode?
    /// Sprint 11 — "Apple 연동됨" 상태 표시. 우상단 테두리 pill(GlassPillNode) → 시작 버튼 바로 아래
    /// plain 텍스트 라벨로 교체. 표시/숨김은 isHidden(게이트 = canUseAppleLinkedSession)으로 통제.
    private let authCaptionLabel = SKLabelNode(fontNamed: Typography.fontBody)
    private var currentAuthProfile: AuthProfileSnapshot?
    private var authStateReady = false
    private var shouldOpenLoginChoiceOnEntry = false
    private var loginChoiceOverlay: LoginChoiceOverlayNode?
    private var isLoginRequestInFlight = false

    // MARK: - Factory
    /// TitleScene.newTitleScene과 동일 패턴. .resizeFill로 view 크기에 자동 맞춤.
    class func newStartScene(openLoginChoiceOnEntry: Bool = false) -> StartScene {
        let scene = StartScene(size: CGSize(width: 1024, height: 768))
        scene.scaleMode = .resizeFill
        scene.shouldOpenLoginChoiceOnEntry = openLoginChoiceOnEntry
        return scene
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        // Sprint 2 — 1프레임 fallback도 warm top으로 (다크 플래시 회피).
        setupSolidMenuBackground()
        setupMusicNoteEmitter()               // Phase 10-2 — 보존. zPos -15.
        setupTitleBlock()                     // Sprint 2 — AccentLine + Jua 2-라인 + Gowun Dodum 태그.
        setupNurseAvatar()                    // Sprint 6 — 좌측 김간호 큰 그림.
        setupStartButton()
        setupAuthCaption()                    // Sprint 11 — caption 바닥을 아바타 몸 아래선에 정렬
        // Sprint 11+ — 종속 방향 역전: 아바타 → caption → 버튼. setup 내부 layout은 각자 1회 호출되나
        // setupStartButton이 setupAuthCaption보다 먼저라 버튼 첫 layout 시 caption이 옛 값이다.
        // 모든 setup(addChild) 완료 후 정해진 순서로 일괄 재배치해 최종 정합을 보장한다.
        layoutNurseAvatar()
        layoutAuthCaption()
        layoutStartButton()
        attachStartButtonPulse()              // Phase 10-2 — 시작 버튼 호흡 pulse
        loadInitialAuthState()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // Phase 10-2 — 그라데이션/음표 emitter는 sceneSize 의존 → 사이즈 변경 시 재생성.
        rebuildSolidMenuBackground()
        rebuildMusicNoteEmitter()
        loginChoiceOverlay?.update(sceneSize: size)
        layoutTitleBlock()
        // Sprint 11+ — 종속 방향 역전: 아바타 몸 아래선 → caption 바닥 → 시작 버튼.
        // 반드시 avatar → caption → button 순서로 호출(caption이 avatar 프레임을, button이 caption을 읽음).
        layoutNurseAvatar()                   // Sprint 6. setScale/position 확정 → accumulatedFrame 유효.
        layoutAuthCaption()                   // caption 바닥을 아바타 몸 아래선에 정렬
        layoutStartButton()                   // 버튼은 caption 위로 동반(둘이 함께 이동)
    }

    /// Phase 10-2 — 음표 파티클 컨테이너 부착. SKAction.repeatForever로 자동 스폰 시작.
    private func setupMusicNoteEmitter() {
        guard UILayout.menuAmbientNotesEnabled else { return }
        let emitter = MusicNoteEmitterNode(sceneSize: size)
        // 원점은 씬 좌측 하단 (0,0) — emitter 내부 좌표계가 sceneSize 범위에 그대로 매핑.
        emitter.position = .zero
        musicNoteEmitter = emitter
        addChild(emitter)
    }

    /// Phase 10-2 — 사이즈 변경 시 emitter 재생성. 떠 있는 음표는 자가 정리됨.
    private func rebuildMusicNoteEmitter() {
        musicNoteEmitter?.stopEmitting()
        musicNoteEmitter?.removeAllChildren()
        musicNoteEmitter?.removeFromParent()
        musicNoteEmitter = nil
        setupMusicNoteEmitter()
    }

    // MARK: - Setup (Sprint 2 · Title Block)
    /// Sprint 2 — AccentLine + Jua 2-라인 타이틀 + Gowun Dodum 태그라인.
    /// 우측 정렬 — 타이틀 블록이 우측, 좌측은 NurseAvatarNode 영역.
    private func setupTitleBlock() {
        // 라인 1 — "김간호는" navyDeep.
        titleLine1.text = "김간호는"
        titleLine1.fontSize = UILayout.startSceneTitleLine1FontSize
        titleLine1.fontColor = .ganhoNavyDeep
        titleLine1.horizontalAlignmentMode = .right
        titleLine1.verticalAlignmentMode = .center

        // 라인 2 — "음악박사 ♪" coral.
        titleLine2.text = "음악박사 ♪"
        titleLine2.fontSize = UILayout.startSceneTitleLine2FontSize
        titleLine2.fontColor = .ganhoCoralPrimary
        titleLine2.horizontalAlignmentMode = .right
        titleLine2.verticalAlignmentMode = .center

        // 태그라인 — Gowun Dodum body.
        taglineLabel.text = "수간호사 몰래, 떠오른 멜로디를\n45초 안에 모아 보세요"
        taglineLabel.fontSize = UILayout.startSceneTaglineFontSize
        taglineLabel.fontColor = .ganhoNavyMuted
        taglineLabel.horizontalAlignmentMode = .right
        taglineLabel.verticalAlignmentMode = .center
        taglineLabel.numberOfLines = 0
        taglineLabel.preferredMaxLayoutWidth = UILayout.startSceneTaglineMaxWidth

        addChild(accentLine)
        addChild(titleLine1)
        addChild(titleLine2)
        addChild(taglineLabel)
        layoutTitleBlock()
    }

    private func layoutTitleBlock() {
        let safe = menuSafeInsets()
        let scale = menuCompactScale()
        titleLine1.setScale(scale)
        titleLine2.setScale(scale)
        taglineLabel.setScale(scale)
        accentLine.setScale(scale)
        taglineLabel.preferredMaxLayoutWidth = UILayout.startSceneTaglineMaxWidth * scale
        let avatarReservedWidth = UILayout.startSceneAvatarReservedWidth * avatarScale()
        let leftLimit = frame.minX
            + safe.left
            + avatarReservedWidth
            + UILayout.startSceneMinTitleAvatarGap * scale
        let rightLimit = frame.maxX - safe.right - UILayout.menuHorizontalSafePadding
        let anchorX = min(
            frame.maxX - UILayout.startSceneTitleBlockRightMargin * scale,
            rightLimit
        )
        let compactOffsetY = size.height < UILayout.compactLandscapeMinHeight
            ? UILayout.startSceneCompactTitleOffsetY
            : UILayout.startSceneTitleBlockOffsetY
        let titleHeight = (
            UILayout.startSceneAccentLineAboveTitleOffset
            + UILayout.startSceneTitleLineSpacing
            - UILayout.startSceneTaglineBelowTitleOffset
        ) * scale
        let maxCenterY = frame.maxY
            - safe.top
            - UILayout.menuTopSafePadding
            - titleHeight / 2
        let minCenterY = bottomCTAAnchorY(
            buttonHalfHeight: UILayout.primaryButtonHeight * scale / 2
        ) + UILayout.primaryButtonHeight * scale
        let preferredCenterY = frame.midY + compactOffsetY * scale
        let centerY = min(max(preferredCenterY, minCenterY), maxCenterY)
        let resolvedAnchorX = min(max(anchorX, leftLimit), rightLimit)
        // 타이틀 1행은 위, 타이틀 2행은 아래 — 줄간 lineSpacing.
        let line1Y = centerY + UILayout.startSceneTitleLineSpacing * scale / 2
        let line2Y = centerY - UILayout.startSceneTitleLineSpacing * scale / 2
        titleLine1.position = CGPoint(x: resolvedAnchorX, y: line1Y)
        titleLine2.position = CGPoint(x: resolvedAnchorX, y: line2Y)
        // AccentLine은 타이틀1 위로 +offset, 우측 정렬에 맞춰 우측 끝을 anchorX에 맞춤.
        accentLine.position = CGPoint(
            x: resolvedAnchorX - UILayout.accentLineWidth * scale / 2,
            y: line1Y + UILayout.startSceneAccentLineAboveTitleOffset * scale
        )
        // 태그라인은 타이틀2 아래.
        taglineLabel.position = CGPoint(
            x: resolvedAnchorX,
            y: line2Y + UILayout.startSceneTaglineBelowTitleOffset * scale
        )
    }

    // MARK: - Setup (Sprint 6 · Nurse Avatar)
    /// Sprint 6 — 좌측 김간호 큰 그림. mockup main-screen-v2.html 좌측 6% 정렬.
    /// PNG swap 호환 — SKNode 서브클래스라 향후 SKSpriteNode(texture:)로 교체 가능.
    private func setupNurseAvatar() {
        let avatar = NurseAvatarNode()
        avatar.setScale(UILayout.nurseAvatarScale)
        avatar.zPosition = ZOrder.nurseAvatarZPosition
        nurseAvatar = avatar
        addChild(avatar)
        layoutNurseAvatar()
    }

    private func layoutNurseAvatar() {
        let safe = menuSafeInsets()
        let scale = UILayout.nurseAvatarScale * menuCompactScale() * avatarScale()
        nurseAvatar?.setScale(scale)
        nurseAvatar?.position = CGPoint(
            x: frame.minX + safe.left + UILayout.nurseAvatarOffsetX * avatarScale(),
            y: frame.midY + UILayout.nurseAvatarOffsetY * menuCompactScale()
        )
    }

    // MARK: - Start Button
    /// 시작 버튼 — 명시 탭만 진행. addChild + layout 분리.
    private func setupStartButton() {
        addChild(startButton)
        layoutStartButton()
    }

    /// Sprint 7+ — safeArea.bottom 회피로 교체.
    /// frame.midY + offset 식은 디바이스에 따라 시작 버튼이 잘렸다(iPhone 17 Pro Landscape 사고).
    /// 새 식: frame.minY + safeArea.bottom + startButtonBottomInset → 모든 디바이스 보장.
    /// 기존 UILayout.startSceneStartButtonOffsetY(-180)는 값만 보존(다른 곳 참조 가능성).
    private func layoutStartButton() {
        let scale = menuCompactScale()
        startButton.setScale(scale)
        let buttonHalf = UILayout.primaryButtonHeight * scale / 2
        // Sprint 11+ — 버튼은 caption 위로 동반(둘이 함께 이동). caption은 .bottom 정렬이라
        // position.y가 곧 caption 바닥 → 그 위로 글자높이(fontSize)만큼 더하면 caption 상단.
        // caption은 isHidden이어도 position은 유효하므로 게이트 상태와 무관하게 기준이 깨지지 않는다.
        let captionTopY = authCaptionLabel.position.y
            + UILayout.startSceneAuthCaptionFontSize * scale
        // startSceneStartButtonLift를 caption↔버튼 간격으로 재활용(새 매직넘버 도입 금지).
        startButton.position = CGPoint(
            x: frame.midX,
            y: captionTopY + UILayout.startSceneStartButtonLift * scale + buttonHalf
        )
        attachStartButtonPulse()
    }

    private func avatarScale() -> CGFloat {
        return size.height < UILayout.compactLandscapeMinHeight
            ? UILayout.startSceneAvatarCompactScale
            : 1.0
    }

    /// Phase 10-2 — 시작 버튼에 호흡 pulse. 0.98 ↔ 1.02, 한 주기 2초.
    /// 외부에서 부착 — PrimaryButtonNode 내부 구조 변경 0.
    /// 씬 전환 시 transitionToNext에서 액션 키로 정리.
    private func attachStartButtonPulse() {
        let baseScale = menuCompactScale()
        let down = SKAction.scale(
            to: baseScale * UILayout.startButtonPulseScaleMin,
            duration: UILayout.startButtonPulseHalfDuration
        )
        down.timingMode = .easeInEaseOut
        let up = SKAction.scale(
            to: baseScale * UILayout.startButtonPulseScaleMax,
            duration: UILayout.startButtonPulseHalfDuration
        )
        up.timingMode = .easeInEaseOut
        let pulse = SKAction.sequence([down, up])
        startButton.removeAction(forKey: "startButtonPulse")
        startButton.run(
            SKAction.repeatForever(pulse),
            withKey: "startButtonPulse"
        )
    }

    // MARK: - Touch
    /// Sprint 6 — 카드 hit test 분기 삭제. 시작 버튼 hit test만.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if let overlay = loginChoiceOverlay {
            handleLoginChoiceAction(overlay.action(at: location))
            return
        }
        // Sprint 11 — 연동 caption 탭 → 프로필 진입(기능 경로 보존). 작은 글자라 텍스트 bbox에
        //   hit 패딩을 inset으로 더해 탭 영역을 넓힌다. isHidden 게이트로 비연동 시 자동 차단.
        if canUseAppleLinkedSession, !authCaptionLabel.isHidden, authCaptionHitFrame().contains(location) {
            transitionToCharacterSelect(openProfileOnEntry: true)
            return
        }
        if startButton.contains(location) {
            resolveStartButtonTap()
        }
    }

    // MARK: - Auth Session
    private var canUseAppleLinkedSession: Bool {
        return authStateReady && currentAuthProfile?.isAppleLinked == true
    }

    private func loadInitialAuthState() {
        currentAuthProfile = nil
        authStateReady = false
        refreshAuthCaption()
        if shouldOpenLoginChoiceOnEntry {
            showLoginChoiceOverlay(
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
                self.refreshAuthCaption()
                self.resolveLoginChoiceOnEntryIfNeeded()
            }
        }
    }

    private func resolveStartButtonTap() {
        guard authStateReady else {
            showLoginChoiceOverlay(
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

        showLoginChoiceOverlay()
    }

    private func waitForAuthStateThenResolveStart() {
        Task { [weak self] in
            let profile = await FirebaseAuthManager.shared.waitForInitialAuthState()
            await MainActor.run {
                guard let self = self, !self.isTransitioning else { return }
                self.authStateReady = true
                self.currentAuthProfile = profile
                self.refreshAuthCaption()
                if self.canUseAppleLinkedSession {
                    self.transitionToCharacterSelect(
                        openProfileOnEntry: profile?.needsNicknameSetup == true
                    )
                } else {
                    self.loginChoiceOverlay?.setMode(.idle, statusText: "")
                }
            }
        }
    }

    private func resolveLoginChoiceOnEntryIfNeeded() {
        guard shouldOpenLoginChoiceOnEntry else { return }
        shouldOpenLoginChoiceOnEntry = false
        showLoginChoiceOverlay()
    }

    // MARK: - Auth Caption
    /// Sprint 11 — "Apple 연동됨"을 테두리/배경 없는 plain 텍스트로. GlassPillNode·필 스타일 제거.
    /// 표시/숨김 게이트(canUseAppleLinkedSession)는 refreshAuthCaption이 단일 진실 원천으로 유지.
    private func setupAuthCaption() {
        authCaptionLabel.text = UILayout.authLinkedStatusText   // 상수 그대로 재사용
        authCaptionLabel.fontSize = UILayout.startSceneAuthCaptionFontSize
        authCaptionLabel.fontColor = .ganhoNavyMuted             // plain·저채도(테두리/배경 없음)
        authCaptionLabel.horizontalAlignmentMode = .center
        authCaptionLabel.verticalAlignmentMode = .center
        authCaptionLabel.zPosition = ZOrder.characterHomeButtonZPosition
        authCaptionLabel.isHidden = true                         // 기존 게이트 동작 보존
        addChild(authCaptionLabel)
        layoutAuthCaption()
    }

    /// caption 바닥을 옆 NurseAvatar의 몸 아래선과 같은 높이에 정렬한다(가로는 화면 중앙).
    /// 종속 방향: 아바타 몸 아래선 → caption 바닥. 반드시 layoutNurseAvatar() *이후*,
    /// layoutStartButton() *이전*에 호출(아바타 프레임을 읽고, 버튼이 이 caption을 다시 읽음).
    /// 아바타가 nil이거나 프레임이 비정상일 때를 대비해 기존 화면 하단 기준 식으로 안전 fallback.
    private func layoutAuthCaption() {
        let scale = menuCompactScale()
        authCaptionLabel.setScale(scale)
        // 바닥 기준 정렬 — position.y가 곧 caption 바닥(폰트 높이 계산 불필요).
        authCaptionLabel.verticalAlignmentMode = .bottom
        authCaptionLabel.horizontalAlignmentMode = .center
        guard let avatar = nurseAvatar else {
            // fallback — 아바타 부재 시 화면 하단 앵커 기준(회귀 안전).
            authCaptionLabel.position = CGPoint(
                x: frame.midX,
                y: bottomCTAAnchorY(
                    buttonHalfHeight: UILayout.primaryButtonHeight * scale / 2
                )
            )
            return
        }
        // 아바타는 scene 직속 자식 → accumulatedFrame.minY가 곧 씬 좌표 몸 아래선(별도 convert 불필요).
        let avatarBottomY = avatar.calculateAccumulatedFrame().minY
        authCaptionLabel.position = CGPoint(x: frame.midX, y: avatarBottomY)
    }

    private func refreshAuthCaption() {
        if canUseAppleLinkedSession {
            authCaptionLabel.text = UILayout.authLinkedStatusText
            authCaptionLabel.isHidden = false
        } else {
            authCaptionLabel.isHidden = true
        }
    }

    /// 연동 caption 탭 히트 영역. 작은 글자라 텍스트 bbox만으로는 좁아 hit 패딩만큼 inset으로 확장.
    private func authCaptionHitFrame() -> CGRect {
        return authCaptionLabel.calculateAccumulatedFrame().insetBy(
            dx: -UILayout.startSceneAuthCaptionHitPadding,
            dy: -UILayout.startSceneAuthCaptionHitPadding
        )
    }

    // MARK: - Login Choice
    private func showLoginChoiceOverlay(mode: LoginChoiceOverlayMode = .idle,
                                        statusText: String = "") {
        if let overlay = loginChoiceOverlay {
            overlay.setMode(mode, statusText: statusText)
            return
        }
        let overlay = LoginChoiceOverlayNode(sceneSize: size, mode: mode)
        if !statusText.isEmpty {
            overlay.setMode(mode, statusText: statusText)
        }
        loginChoiceOverlay = overlay
        addChild(overlay)
    }

    private func hideLoginChoiceOverlay() {
        loginChoiceOverlay?.removeAllActions()
        loginChoiceOverlay?.removeFromParent()
        loginChoiceOverlay = nil
    }

    private func handleLoginChoiceAction(_ action: LoginChoiceAction?) {
        guard let action = action else { return }

        switch action {
        case .guest:
            handleGuestStartTap()
        case .apple:
            handleAppleStartTap()
        case .cancel:
            hideLoginChoiceOverlay()
        }
    }

    private func handleGuestStartTap() {
        guard !isLoginRequestInFlight else { return }
        isLoginRequestInFlight = true
        loginChoiceOverlay?.setMode(.busy, statusText: UILayout.loginChoiceGuestBusyText)
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
                    self.loginChoiceOverlay?.setMode(
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
            loginChoiceOverlay?.setMode(.idle, statusText: UILayout.loginChoiceFailureText)
            return
        }

        isLoginRequestInFlight = true
        loginChoiceOverlay?.setMode(.busy, statusText: UILayout.loginChoiceAppleBusyText)

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
                    self.loginChoiceOverlay?.setMode(
                        .idle,
                        statusText: UILayout.loginChoiceCancelledText
                    )
                case .failure(let error):
                    self.loginChoiceOverlay?.setMode(
                        .idle,
                        statusText: self.appleFailureStatusText(for: error)
                    )
                }
            }
        }
    }

    private func appleFailureStatusText(for error: AuthError?) -> String {
        switch error {
        case .some(.appleAuthorizationTimedOut):
            return UILayout.loginChoiceAppleTimeoutText
        case .some(.appleConfigurationFailed):
            return UILayout.loginChoiceAppleConfigurationText
        case .some(.appleCredentialRejected):
            return UILayout.loginChoiceAppleCredentialText
        default:
            return UILayout.loginChoiceFailureText
        }
    }

    /// 인증 선택 성공 시 다음 단계(CharacterSelect)로 전환.
    /// Sprint 6 — 난이도 인자 전달 제거. CharacterSelectScene.newCharacterSelectScene()을 *인자 없이* 호출.
    /// Phase 10-2 — *게임플레이 동작 불변* — presentScene 대상, sceneTransitionDuration 모두 그대로.
    /// 타이틀/시작버튼/NurseAvatar/연동 caption 슬라이드업 + fade-out *prelude*만 추가.
    private func transitionToCharacterSelect(openProfileOnEntry: Bool) {
        guard let view = self.view else { return }
        isTransitioning = true
        hideLoginChoiceOverlay()

        // Phase 10-2 — 시작 버튼 pulse 정리.
        startButton.removeAction(forKey: "startButtonPulse")
        // Phase 10-2 — 음표 emitter 정지(추가 스폰 중단). 떠 있는 음표는 자가 정리.
        musicNoteEmitter?.stopEmitting()

        // Phase 10-2 — 타이틀/시작 버튼/NurseAvatar *살짝 위로* 슬라이드 + fadeOut.
        let slideUp = SKAction.moveBy(
            x: 0,
            y: UILayout.startSceneExitSlideDistance,
            duration: UILayout.startSceneExitSlideDuration
        )
        slideUp.timingMode = .easeIn
        let fadeOut = SKAction.fadeOut(
            withDuration: UILayout.startSceneExitSlideDuration
        )
        // 같은 액션 인스턴스를 여러 노드에 run하면 SpriteKit이 내부적으로 복사 — 안전.
        let exit = SKAction.group([slideUp, fadeOut])
        startButton.run(exit)
        titleLine1.run(exit)
        titleLine2.run(exit)
        taglineLabel.run(exit)
        nurseAvatar?.run(exit)
        authCaptionLabel.run(exit)            // Sprint 11 — 시작 버튼과 함께 슬라이드/페이드(일관성)

        // Phase 10-2 — 슬라이드 완료 후 presentScene.
        // Sprint 6 — newCharacterSelectScene을 *인자 없이* 호출(difficulty 제거).
        let wait = SKAction.wait(forDuration: UILayout.startSceneExitSlideDuration)
        let present = SKAction.run { [weak view] in
            guard let view = view else { return }
            let nextScene = CharacterSelectScene.newCharacterSelectScene(
                openProfileOnEntry: openProfileOnEntry
            )
            let fade = SKTransition.fade(withDuration: FeelTuning.sceneTransitionDuration)
            view.presentScene(nextScene, transition: fade)
        }
        run(SKAction.sequence([wait, present]))

        // characterRepo는 다음 씬이 다시 .current로 읽으므로 본 씬에서 별도 전달 불필요.
        // 정적 의존 회피 — Swift 컴파일러 unused warning 방지를 위해 명시 참조.
        _ = characterRepo
    }
}
