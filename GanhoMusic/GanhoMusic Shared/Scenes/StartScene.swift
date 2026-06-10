//
//  StartScene.swift
//  GanhoMusic Shared
//
//  R4 §F-1 — "야간 병동 로비". 로고타입 1줄 + 김간호 대형 픽셀 idle + "▶ 탭하여 시작".
//  시작 버튼 노드 폐기 — 칩·다이얼로그가 소비하지 않은 화면 탭이 resolveStartButtonTap() 호출.
//  인증 상태 머신(Firebase 플로우)은 v2에서 무변경 이식 — waitForInitialAuthState /
//  signInWithApple / ensureAnonymousSession / signOutToGuestSession.
//

import FirebaseAuth
import SpriteKit

/// 앱 첫 진입 씬. v3 — 다크 잉크 + 네온 골드 로고 + 픽셀 히어로.
final class StartScene: BaseMenuScene {

    // MARK: - Properties
    /// 씬 전환이 시작됐는지 여부. true가 되면 추가 탭은 무시 — 더블 enter 방지.
    var isTransitioning = false
    /// 로고타입 1줄 (Typography.V3.logo 52pt, gold).
    private let logoLabel = SKLabelNode(fontNamed: Typography.V3.logo.fontName)
    /// 김간호 대형 픽셀 — 48×64 ×3 (144×192pt). 텍스처는 didMove 1회 생성 후 보관.
    private var heroSprite: SKSpriteNode?
    /// "▶ 탭하여 시작" — 1.2s 블링크 (시각 펄스 — 소멸 아님, §F-1 허용).
    private let tapToStartLabel = SKLabelNode(fontNamed: Typography.V3.body.fontName)
    /// 연동 시에만 add되는 프로필 칩 — 미연동 시 노드 자체 미생성/제거 (isHidden 게이트 금지).
    private var profileChip: PixelChipNode?
    /// 로그인 다이얼로그 — 표시 중에만 존재 (PixelDialogNode 딤이 배후 터치 흡수).
    var loginDialog: LoginChoiceDialogNode?

    // MARK: Auth State (v2 무변경 이식)
    var currentAuthProfile: AuthProfileSnapshot?
    var authStateReady = false
    var shouldOpenLoginChoiceOnEntry = false
    var isLoginRequestInFlight = false

    /// 블링크 액션 키.
    private static let blinkActionKey = "r4TapToStartBlink"
    /// 히어로 bob 액션 키.
    private static let heroBobActionKey = "r4HeroBob"

    // MARK: - Factory
    /// .resizeFill로 view 크기에 자동 맞춤 (v2 패턴 보존).
    class func newStartScene(openLoginChoiceOnEntry: Bool = false) -> StartScene {
        let scene = StartScene(size: CGSize(width: 1024, height: 768))
        scene.scaleMode = .resizeFill
        scene.shouldOpenLoginChoiceOnEntry = openLoginChoiceOnEntry
        return scene
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        setupNightShiftBackdrop()
        setupLogo()
        setupHero()
        setupTapToStart()
        layoutAll()
        runStaggeredAppear([logoLabel, heroSprite, tapToStartLabel].compactMap { $0 })
        loadInitialAuthState()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard heroSprite != nil else { return }   // didMove 이전 호출 가드
        cancelStaggeredAppear()
        rebuildNightShiftBackdrop()
        layoutAll()
        loginDialog?.updateLayout(in: self)
    }

    private func layoutAll() {
        layoutLogo()
        layoutHero()
        layoutTapToStart()
        layoutProfileChip()
    }

    // MARK: - Logo (§F-1 — v2 2-라인 타이틀·태그라인·AccentLine 폐기)
    private func setupLogo() {
        logoLabel.text = UILayout.R4.startLogoText
        logoLabel.fontSize = Typography.V3.logo.size
        logoLabel.fontColor = Palette.gold
        logoLabel.horizontalAlignmentMode = .center
        logoLabel.verticalAlignmentMode = .center
        logoLabel.zPosition = ZOrder.Layer.hud
        addChild(logoLabel)
    }

    private func layoutLogo() {
        let safe = menuSafeInsets()
        let scale = menuCompactScale()
        logoLabel.setScale(scale)
        logoLabel.position = CGPoint(
            x: frame.midX.rounded(),
            y: (frame.maxY - safe.top - UILayout.R4.startLogoTopInset * scale).rounded()
        )
    }

    // MARK: - Hero (§F-1 — PixelHeroSprite 48×64 2프레임 bob 0.6s)
    private func setupHero() {
        let palette = PixelPalette.palette(for: .kim)
        // 텍스처 2장 — didMove 1회 생성 후 SKAction.animate가 보관 (매 프레임 생성 0).
        let textures = PixelHeroSprite.idleFrames.map { frame in
            PixelSpriteRenderer.texture(rows: frame, palette: palette, scale: 1)
        }
        guard let first = textures.first else { return }
        let hero = SKSpriteNode(texture: first)
        hero.size = CGSize(
            width: CGFloat(PixelHeroSprite.gridWidth) * UILayout.R4.startHeroPixelScale,
            height: CGFloat(PixelHeroSprite.gridHeight) * UILayout.R4.startHeroPixelScale
        )
        hero.zPosition = ZOrder.Layer.characters
        // bob — 2프레임 교차, 한 사이클 0.6s (Timer 금지 — SKAction.animate).
        let bob = SKAction.animate(with: textures,
                                   timePerFrame: FeelTuning.R4.heroBobCycle / 2,
                                   resize: false,
                                   restore: false)
        hero.run(SKAction.repeatForever(bob), withKey: Self.heroBobActionKey)
        heroSprite = hero
        addChild(hero)
    }

    private func layoutHero() {
        let scale = menuCompactScale()
        heroSprite?.setScale(scale)
        heroSprite?.position = CGPoint(
            x: frame.midX.rounded(),
            y: (frame.midY + UILayout.R4.startHeroCenterYOffset * scale).rounded()
        )
    }

    // MARK: - Tap To Start (§F-1 — 1.2s 블링크 시각 펄스)
    private func setupTapToStart() {
        tapToStartLabel.text = UILayout.R4.startTapToStartText
        tapToStartLabel.fontSize = Typography.V3.body.size
        tapToStartLabel.fontColor = Palette.textHi
        tapToStartLabel.horizontalAlignmentMode = .center
        tapToStartLabel.verticalAlignmentMode = .center
        tapToStartLabel.zPosition = ZOrder.Layer.hud
        let half = FeelTuning.R4.tapToStartBlinkCycle / 2
        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: FeelTuning.R4.tapToStartBlinkLowAlpha, duration: half),
            SKAction.fadeAlpha(to: 1.0, duration: half)
        ])
        tapToStartLabel.run(SKAction.repeatForever(blink), withKey: Self.blinkActionKey)
        addChild(tapToStartLabel)
    }

    private func layoutTapToStart() {
        let safe = menuSafeInsets()
        let scale = menuCompactScale()
        tapToStartLabel.setScale(scale)
        tapToStartLabel.position = CGPoint(
            x: frame.midX.rounded(),
            y: (frame.minY + safe.bottom + UILayout.R4.startTapLabelBottomInset * scale).rounded()
        )
    }

    // MARK: - Profile Chip (§F-1 — 연동 시에만 add, 탭 → 프로필 진입 보존)
    func refreshProfileChip() {
        if canUseAppleLinkedSession {
            guard profileChip == nil else { return }
            let chip = PixelChipNode(text: UILayout.authLinkedStatusText,
                                     style: .accent(Palette.gold))
            chip.zPosition = ZOrder.Layer.hud
            profileChip = chip
            addChild(chip)
            layoutProfileChip()
        } else {
            profileChip?.removeFromParent()
            profileChip = nil
        }
    }

    private func layoutProfileChip() {
        guard let chip = profileChip else { return }
        let safe = menuSafeInsets()
        let scale = menuCompactScale()
        chip.setScale(scale)
        chip.position = CGPoint(
            x: (frame.maxX - safe.right - UILayout.v3ScreenEdgeInset
                - chip.chipSize.width * scale / 2).rounded(),
            y: (frame.maxY - safe.top - UILayout.v3ScreenEdgeInset
                - chip.chipSize.height * scale / 2).rounded()
        )
    }

    /// 칩 히트 영역 — 칩 높이 24 → 44pt 터치 보장 패딩.
    private func profileChipHitFrame() -> CGRect? {
        guard let chip = profileChip else { return nil }
        return chip.calculateAccumulatedFrame().insetBy(
            dx: -UILayout.R4.chipHitPadding,
            dy: -UILayout.R4.chipHitPadding
        )
    }

    // MARK: - Touch (§F-1 — 시작 버튼 폐기: 소비되지 않은 화면 탭 = 시작)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        // 다이얼로그 노출 중에는 딤(PixelDialogNode)이 터치를 흡수 — 방어적 이중 가드.
        guard loginDialog == nil else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if canUseAppleLinkedSession,
           let chipFrame = profileChipHitFrame(),
           chipFrame.contains(location) {
            transitionToCharacterSelect(openProfileOnEntry: true)
            return
        }
        resolveStartButtonTap()
    }
}
