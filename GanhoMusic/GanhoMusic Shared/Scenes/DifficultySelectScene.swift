//
//  DifficultySelectScene.swift
//  GanhoMusic Shared
//
//  캐릭터와 스킬 요약을 보여준 뒤 마지막으로 난이도를 선택하는 화면.
//  난이도 저장 포맷과 GameScene 진입 시그니처는 변경하지 않는다.
//

import SpriteKit

/// 5단계 흐름의 마지막 결정 씬. characterID 불변 + 난이도만 골라서 GameScene으로 진입.
final class DifficultySelectScene: BaseMenuScene {

    // MARK: - Properties
    /// init 주입된 캐릭터 ID. 불변.
    private let characterID: CharacterID
    /// 현재 선택된 난이도. 기본 .easy → didMove에서 repo.current로 복원.
    private var selectedDifficulty: Difficulty = .easy
    /// 난이도 저장소. didMove에서 1회 읽기, select 시 save.
    private let difficultyRepo = DifficultyPreferenceRepository()
    /// 씬 전환 가드.
    private var isTransitioning = false

    // 헤더/배경.
    private let headerLabel = SKLabelNode(fontNamed: Typography.fontDisplay)
    private let headerSubLabel = SKLabelNode(fontNamed: Typography.fontBody)
    private let accentLine = AccentLineNode()
    private var musicNoteEmitter: MusicNoteEmitterNode?

    // 상단 바.
    private var backPill: GlassPillNode?
    private var breadcrumbChip: DarkContextChipNode?

    // 좌측 캐릭터 요약 카드.
    private var summaryContainer: SKShapeNode?
    private var summaryNameBadge: SKShapeNode?
    private let summaryNameLabel = SKLabelNode(fontNamed: Typography.fontDisplay)
    /// V5 — 좌측 카드 풀바디 픽셀 스프라이트(SkillExplanationScene와 동일 패턴).
    /// CharacterFaceNode 본체는 다른 화면(CharacterSelectScene 등)이 사용 중이므로
    /// 본체 변경 0줄 + 본 씬 내 타입만 SKSpriteNode로 교체.
    private var summaryFace: SKSpriteNode?
    private let summarySkillLabel = SKLabelNode(fontNamed: Typography.fontDisplay)
    private var summarySpeedChip: SKShapeNode?
    private let summarySpeedLabel = SKLabelNode(fontNamed: Typography.fontDisplay)

    // 우측 난이도 3장.
    private var difficultyCards: [DifficultyCardNode] = []

    // 하단 시작 버튼.
    private let startButton = PrimaryButtonNode(
        text: UILayout.difficultySelectStartButtonText
    )

    // MARK: - Factory
    /// CharacterSelectScene(.kim 분기) 또는 SkillExplanationScene(그 외)이 호출.
    class func newDifficultySelectScene(
        characterID: CharacterID
    ) -> DifficultySelectScene {
        let scene = DifficultySelectScene(
            size: CGSize(width: 1024, height: 768),
            characterID: characterID
        )
        scene.scaleMode = .resizeFill
        return scene
    }

    // MARK: - Init
    /// characterID는 `let` — super.init 전 저장.
    private init(size: CGSize, characterID: CharacterID) {
        self.characterID = characterID
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        setupSolidMenuBackground()
        setupMusicNoteEmitter()
        setupHeader()
        setupTopBar()
        // 난이도 복원 — 1회.
        selectedDifficulty = difficultyRepo.current
        setupSummaryCard()
        setupDifficultyCards()
        setupStartButton()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        rebuildSolidMenuBackground()
        rebuildMusicNoteEmitter()
        layoutHeader()
        layoutTopBar()
        layoutSummaryCard()
        layoutDifficultyCards()
        layoutStartButton()
    }

    private func setupMusicNoteEmitter() {
        guard UILayout.menuAmbientNotesEnabled else { return }
        let emitter = MusicNoteEmitterNode(sceneSize: size)
        emitter.position = .zero
        musicNoteEmitter = emitter
        addChild(emitter)
    }

    private func rebuildMusicNoteEmitter() {
        musicNoteEmitter?.stopEmitting()
        musicNoteEmitter?.removeAllChildren()
        musicNoteEmitter?.removeFromParent()
        musicNoteEmitter = nil
        setupMusicNoteEmitter()
    }

    // MARK: - Setup (Header)
    private func setupHeader() {
        headerLabel.text = UILayout.difficultySelectHeaderText
        headerLabel.fontSize = UILayout.difficultySelectHeaderFontSize
        headerLabel.fontColor = .ganhoNavyDeep
        headerLabel.horizontalAlignmentMode = .center
        headerLabel.verticalAlignmentMode = .center
        addChild(headerLabel)

        headerSubLabel.text = UILayout.difficultySelectHeaderSubText
        headerSubLabel.fontSize = UILayout.difficultySelectHeaderSubFontSize
        headerSubLabel.fontColor = .ganhoNavyMuted
        headerSubLabel.horizontalAlignmentMode = .center
        headerSubLabel.verticalAlignmentMode = .center
        addChild(headerSubLabel)

        addChild(accentLine)
        layoutHeader()
    }

    private func layoutHeader() {
        let centerX = frame.midX
        let scale = menuCompactScale()
        headerLabel.setScale(scale)
        headerSubLabel.setScale(scale)
        accentLine.setScale(scale)
        let baseY = min(
            frame.midY + UILayout.difficultySelectHeaderOffsetY * scale,
            topBarY(extraInset: UILayout.difficultySelectBackPillHeight)
        )
        headerLabel.position = CGPoint(x: centerX, y: baseY)
        headerSubLabel.position = CGPoint(
            x: centerX,
            y: baseY + UILayout.difficultySelectHeaderSubOffsetY * scale
        )
        accentLine.position = CGPoint(
            x: centerX,
            y: baseY + UILayout.difficultySelectAccentLineOffsetY * scale
        )
    }

    // MARK: - Setup (Top Bar — 분기 백버튼 + 브레드크럼)
    /// 백버튼 텍스트는 characterID에 따라 분기:
    ///  - .kim → "← 캐릭터 다시" (스킬 화면 스킵)
    ///  - 그 외 → "← 스킬 다시"
    private func setupTopBar() {
        let backText: String = (characterID == .kim)
            ? UILayout.difficultySelectBackPillTextCharacter
            : UILayout.difficultySelectBackPillTextSkill
        let back = GlassPillNode(
            text: backText,
            size: CGSize(
                width: UILayout.difficultySelectBackPillWidth,
                height: UILayout.difficultySelectBackPillHeight
            )
        )
        backPill = back
        addChild(back)

        let chip = DarkContextChipNode(
            label: UILayout.difficultySelectBreadcrumbLabel,
            badge: UILayout.difficultySelectBreadcrumbBadge
        )
        breadcrumbChip = chip
        addChild(chip)
        layoutTopBar()
    }

    private func layoutTopBar() {
        let safe = menuSafeInsets()
        let scale = menuCompactScale()
        let y = topBarY(
            extraInset: max(
                0,
                UILayout.difficultySelectTopBarMarginY - UILayout.menuTopSafePadding
            )
        )
        backPill?.setScale(scale)
        breadcrumbChip?.setScale(scale)
        backPill?.position = CGPoint(
            x: frame.minX + safe.left + UILayout.difficultySelectTopBarMarginX * scale
                + UILayout.difficultySelectBackPillWidth * scale / 2,
            y: y
        )
        if let chip = breadcrumbChip {
            let halfWidth = chip.calculateAccumulatedFrame().width / 2
            chip.position = CGPoint(
                x: frame.maxX - safe.right - UILayout.difficultySelectTopBarMarginX * scale - halfWidth,
                y: y
            )
        }
    }

    // MARK: - Setup (Summary Card — 좌측 캐릭터+스킬 요약)
    /// OQ-3: summaryContainer는 SKShapeNode 직접. CharacterCardNode 재사용 금지(내부 변경 위반).
    private func setupSummaryCard() {
        // 본 카드.
        let cardSize = CGSize(
            width: UILayout.difficultySelectSummaryCardWidth,
            height: UILayout.difficultySelectSummaryCardHeight
        )
        let card = SKShapeNode(
            rectOf: cardSize,
            cornerRadius: UILayout.difficultySelectSummaryCardCornerRadius
        )
        card.fillColor = UIColor.white
            .withAlphaComponent(UILayout.difficultySelectSummaryCardFillAlpha)
        card.strokeColor = UIColor.ganhoCoralPrimary
            .withAlphaComponent(UILayout.difficultySelectSummaryCardStrokeAlpha)
        card.lineWidth = UILayout.difficultySelectSummaryCardStrokeWidth
        card.zPosition = 80
        card.name = "difficultySelectSummaryCard"
        summaryContainer = card
        addChild(card)

        // 이름 뱃지(코랄). OQ-7 — `.ganhoCoralPrimary` 통일.
        let badgeSize = CGSize(
            width: UILayout.difficultySelectSummaryNameBadgeWidth,
            height: UILayout.difficultySelectSummaryNameBadgeHeight
        )
        let badge = SKShapeNode(
            rectOf: badgeSize,
            cornerRadius: badgeSize.height / 2
        )
        badge.fillColor = .ganhoCoralPrimary
        badge.strokeColor = .clear
        badge.zPosition = 110
        summaryNameBadge = badge
        addChild(badge)

        summaryNameLabel.text = characterID.displayName
        summaryNameLabel.fontSize = UILayout.difficultySelectSummaryNameBadgeFontSize
        summaryNameLabel.fontColor = .white
        summaryNameLabel.horizontalAlignmentMode = .center
        summaryNameLabel.verticalAlignmentMode = .center
        summaryNameLabel.zPosition = 111
        addChild(summaryNameLabel)

        let texture = summaryTexture(for: characterID)
        let face = makeSummaryFace(texture: texture)
        summaryFace = face
        addChild(face)

        // 스킬명 — 김간호는 "스킬 없음" 그 외는 displayName.
        let skillText: String = (characterID.skill == .none)
            ? UILayout.difficultySelectSummarySkillNoneText
            : characterID.skill.displayName
        summarySkillLabel.text = skillText
        summarySkillLabel.fontSize = UILayout.difficultySelectSummarySkillFontSize
        summarySkillLabel.fontColor = .ganhoNavyDeep
        summarySkillLabel.horizontalAlignmentMode = .center
        summarySkillLabel.verticalAlignmentMode = .center
        summarySkillLabel.zPosition = 110
        addChild(summarySkillLabel)

        // 속도 칩 — 민트 톤(ganhoScrubMint α 0.4).
        let chipSize = CGSize(
            width: UILayout.difficultySelectSummarySpeedChipWidth,
            height: UILayout.difficultySelectSummarySpeedChipHeight
        )
        let chip = SKShapeNode(
            rectOf: chipSize,
            cornerRadius: chipSize.height / 2
        )
        chip.fillColor = UIColor.ganhoScrubMint
            .withAlphaComponent(UILayout.difficultySelectSummarySpeedChipFillAlpha)
        // Sprint 7 Phase C — 속도 칩 stroke 1pt 보강(.ganhoDifficultyEasyDeep #5EBFA3).
        // mockup `box-shadow + stroke 1pt` 톤을 SpriteKit에서 stroke만으로 근사.
        chip.strokeColor = .ganhoDifficultyEasyDeep
        chip.lineWidth = 1
        chip.zPosition = 110
        summarySpeedChip = chip
        addChild(chip)

        let speedText = formatted(characterID.playerSpeedMultiplier)
        summarySpeedLabel.text = "⚡ 속도 ×\(speedText)"
        summarySpeedLabel.fontSize = UILayout.difficultySelectSummarySpeedChipFontSize
        summarySpeedLabel.fontColor = .ganhoNavyDeep
        summarySpeedLabel.horizontalAlignmentMode = .center
        summarySpeedLabel.verticalAlignmentMode = .center
        summarySpeedLabel.zPosition = 111
        addChild(summarySpeedLabel)

        layoutSummaryCard()
    }

    // MARK: - Texture
    private func summaryTexture(for characterID: CharacterID) -> SKTexture {
        let rawName = "\(characterID.rawValue)_down_idle_1"
        let candidateNames = [
            "Characters/\(rawName)",
            rawName
        ]

        for assetName in candidateNames {
            if UIImage(named: assetName) != nil {
                let texture = SKTexture(imageNamed: assetName)
                texture.filteringMode = .linear
                return texture
            }
        }

        let frame = PixelSprite.data(for: characterID, direction: .down, frame: .idle)
        let palette = PixelPalette.palette(for: characterID)
        return PixelSpriteRenderer.texture(from: frame, palette: palette)
    }

    private func makeSummaryFace(texture: SKTexture) -> SKSpriteNode {
        let face = SKSpriteNode(texture: texture)
        face.size = aspectFitSize(
            textureSize: texture.size(),
            maxSize: CGSize(
                width: UILayout.difficultySelectSummaryFullBodyMaxWidth,
                height: UILayout.difficultySelectSummaryFullBodyMaxHeight
            )
        )
        face.zPosition = 105
        return face
    }

    // MARK: - Layout
    private func aspectFitSize(textureSize: CGSize, maxSize: CGSize) -> CGSize {
        guard textureSize.width > 0, textureSize.height > 0 else { return maxSize }
        let widthScale = maxSize.width / textureSize.width
        let heightScale = maxSize.height / textureSize.height
        let scale = min(widthScale, heightScale)
        return CGSize(
            width: textureSize.width * scale,
            height: textureSize.height * scale
        )
    }

    private func layoutSummaryCard() {
        // Sprint 7 — 우측 3장 카드가 1.4배 커지면서 시각 균형을 위해 좌측 summary를 V3 offset(-260)으로 추가 좌측 이동.
        let scale = difficultyLayoutScale()
        summaryContainer?.setScale(scale)
        summaryNameBadge?.setScale(scale)
        summaryNameLabel.setScale(scale)
        summaryFace?.setScale(scale)
        summarySkillLabel.setScale(scale)
        summarySpeedChip?.setScale(scale)
        summarySpeedLabel.setScale(scale)
        let safe = menuSafeInsets()
        let halfWidth = UILayout.difficultySelectSummaryCardWidth * scale / 2
        let preferredX = frame.midX + UILayout.difficultySelectSummaryCardOffsetX * scale
        let minX = frame.minX
            + safe.left
            + UILayout.menuHorizontalSafePadding
            + halfWidth
        let cardsLeftEdge = difficultyCardsLeftEdge(scale: scale)
        let maxX = cardsLeftEdge
            - UILayout.difficultySelectColumnMinGap * scale
            - halfWidth
        let baseX = maxX > minX
            ? min(max(preferredX, minX), maxX)
            : minX
        // V5 — 헤더(midY+140)와 카드 top 호흡 50pt 확보 위해 OffsetY V5(-40) 채택.
        // 기존 V3(-10)는 byte-identical 보존 — 다른 사용처 회귀 위험 0.
        let baseY = frame.midY + UILayout.difficultySelectSummaryCardOffsetY * scale
        summaryContainer?.position = CGPoint(x: baseX, y: baseY)
        let badgeY = baseY + UILayout.difficultySelectSummaryNameBadgeOffsetY
        summaryNameBadge?.position = CGPoint(x: baseX, y: badgeY)
        summaryNameLabel.position = CGPoint(x: baseX, y: badgeY)
        summaryFace?.position = CGPoint(
            x: baseX,
            y: baseY + UILayout.difficultySelectSummaryFaceOffsetY
        )
        summarySkillLabel.position = CGPoint(
            x: baseX,
            y: baseY + UILayout.difficultySelectSummarySkillOffsetY
        )
        let speedChipY = baseY + UILayout.difficultySelectSummarySpeedChipOffsetY
        summarySpeedChip?.position = CGPoint(x: baseX, y: speedChipY)
        summarySpeedLabel.position = CGPoint(x: baseX, y: speedChipY)
    }

    /// 1.10 → "1.1", 0.95 → "0.95"처럼 소수점 한 자리 우선.
    private func formatted(_ value: CGFloat) -> String {
        let rounded1 = (value * 10).rounded() / 10
        if abs(value - rounded1) < 0.001 {
            return String(format: "%.1f", Double(value))
        }
        return String(format: "%.2f", Double(value))
    }

    // MARK: - Setup (Difficulty Cards — 우측 3장)
    /// DifficultyCardNode 기존 컴포넌트 그대로 재사용. setSelected 동작 일관.
    private func setupDifficultyCards() {
        for id in Difficulty.allCases {
            let card = DifficultyCardNode(id: id)
            card.setSelected(id == selectedDifficulty)
            difficultyCards.append(card)
            addChild(card)
        }
        layoutDifficultyCards()
    }

    /// 3 카드 가로 일렬 — 화면 우측 영역 중앙(midX + offset).
    /// Sprint 8 Phase D — width/spacing 모두 V4 상수(130 / 22) 참조. V3 상수는 byte-identical 보존
    /// (다른 사용처 회귀 방지 + Config 토큰 그대로 유지).
    /// 합산 폭 = 130×3 + 22×2 = 434pt < 화면 폭 844pt(landscape) → 잘림 0 보장.
    private func layoutDifficultyCards() {
        let count = difficultyCards.count
        guard count > 0 else { return }
        let safe = menuSafeInsets()
        let availableWidth = size.width
            - safe.left
            - safe.right
            - UILayout.menuHorizontalSafePadding * 2
        let scale = min(
            difficultyLayoutScale(),
            availableWidth < UILayout.difficultyCompactWidthThreshold
                ? UILayout.difficultyCompactScale
                : menuCompactScale()
        )
        let width = UILayout.difficultyCardWidth
        let spacing = UILayout.difficultyCardGap
        let totalWidth = (width * CGFloat(count) + spacing * CGFloat(count - 1)) * scale
        let centerX = frame.midX + UILayout.difficultySelectDifficultyRowOffsetX * scale
        let rightLimit = frame.maxX - safe.right - UILayout.menuHorizontalSafePadding
        let clampedCenterX = min(centerX, rightLimit - totalWidth / 2)
        let startX = clampedCenterX - totalWidth / 2 + width * scale / 2
        let y = frame.midY + UILayout.difficultySelectDifficultyRowOffsetY * scale
        for (index, card) in difficultyCards.enumerated() {
            card.setLayoutScale(scale)
            card.position = CGPoint(
                x: startX + CGFloat(index) * (width + spacing) * scale,
                y: y
            )
        }
    }

    /// 선택 난이도 변경 + 3 카드 일괄 갱신 + 디스크 저장.
    /// 저장 포맷 회귀 0건 — `difficultyRepo.save(id)` 그대로.
    private func selectDifficulty(_ id: Difficulty) {
        selectedDifficulty = id
        difficultyRepo.save(id)
        for card in difficultyCards {
            card.setSelected(card.id == id)
        }
    }

    // MARK: - Setup (Start Button)
    private func setupStartButton() {
        addChild(startButton)
        layoutStartButton()
    }

    /// Sprint 10.5+ V5 — 좌측 카드도 V5로 30pt 하방 이동(midY-170 bottom)되어
    /// V3/V4 산식만으론 좌측 카드 bottom과 시작 버튼 top이 충돌. V5 산식 추가 +
    /// 화면 하단 safe margin 클램프로 좁은 디바이스에서도 버튼 잘림 0 보장.
    ///
    /// 산식 위계(가장 아래 y 채택):
    ///  - v3Y       = midY + V5 offset(-200)
    ///  - v4RightY  = 우측 카드 bottom - 36 - 24
    ///  - v5LeftY   = 좌측 카드 bottom(midY-170) - 36 - 24 = midY-230
    /// → min(v3, v4Right, v5Left) → 마지막에 frame.minY 기준 safe margin으로 max 클램프.
    private func layoutStartButton() {
        // V3/V5 — 기존 V3 산식은 byte-identical 보존, 본 호출은 V5 offset(-200) 사용.
        let scale = difficultyLayoutScale()
        startButton.setScale(scale)
        let v3Y = frame.midY + UILayout.difficultySelectStartButtonOffsetY * scale

        let buttonHalfHeight = UILayout.primaryButtonHeight * scale / 2
        let breathingGap = UILayout.difficultySelectStartButtonBreathingGap * scale

        // V4 — 우측 난이도 3장 카드 bottom 호흡 산식(기존 톤 유지).
        let rightCardCenterY = frame.midY + UILayout.difficultySelectDifficultyRowOffsetY * scale
        let rightCardBottomY = rightCardCenterY - UILayout.difficultyCardHeight * scale / 2
        let v4RightY = rightCardBottomY - breathingGap - buttonHalfHeight

        // V5 신규 — 좌측 요약 카드 bottom 호흡 산식.
        let leftCardCenterY = frame.midY + UILayout.difficultySelectSummaryCardOffsetY * scale
        let leftCardBottomY = leftCardCenterY
            - UILayout.difficultySelectSummaryCardHeight * scale / 2
        let v5LeftY = leftCardBottomY - breathingGap - buttonHalfHeight

        // 가장 아래(작은 y) 채택 — 어떤 카드와도 36pt+ 호흡 보장.
        let dynamicY = min(v3Y, min(v4RightY, v5LeftY))

        // 화면 하단 safe margin 클램프 — 좁은 디바이스에서 버튼이 화면 밖으로 나가지 않도록.
        let minAllowedY = bottomCTAAnchorY(buttonHalfHeight: buttonHalfHeight)
        let buttonY = max(dynamicY, minAllowedY)

        let pos = CGPoint(x: frame.midX, y: buttonY)
        startButton.position = pos
    }

    private func difficultyLayoutScale() -> CGFloat {
        let safe = menuSafeInsets()
        let availableWidth = size.width
            - safe.left
            - safe.right
            - UILayout.menuHorizontalSafePadding * 2
        let summaryWidth = UILayout.difficultySelectSummaryCardWidth
        let cardsWidth = UILayout.difficultyCardWidth * CGFloat(Difficulty.allCases.count)
            + UILayout.difficultyCardGap * CGFloat(Difficulty.allCases.count - 1)
        let requiredWidth = summaryWidth
            + UILayout.difficultySelectColumnMinGap
            + cardsWidth
        let widthScale = availableWidth / requiredWidth
        return max(
            UILayout.difficultySelectMinimumLayoutScale,
            min(menuCompactScale(), widthScale)
        )
    }

    private func difficultyCardsLeftEdge(scale: CGFloat) -> CGFloat {
        let safe = menuSafeInsets()
        let count = CGFloat(max(difficultyCards.count, Difficulty.allCases.count))
        let totalWidth = (
            UILayout.difficultyCardWidth * count
            + UILayout.difficultyCardGap * (count - 1)
        ) * scale
        let preferredCenterX = frame.midX
            + UILayout.difficultySelectDifficultyRowOffsetX * scale
        let rightLimit = frame.maxX - safe.right - UILayout.menuHorizontalSafePadding
        let centerX = min(preferredCenterX, rightLimit - totalWidth / 2)
        return centerX - totalWidth / 2
    }

    // MARK: - Touch
    /// 우선순위: 백 GlassPill → 난이도 카드 → 시작 버튼.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if backPill?.contains(location) == true {
            transitionBack()
            return
        }
        for card in difficultyCards {
            if card.contains(location) {
                selectDifficulty(card.id)
                return
            }
        }
        if startButton.contains(location) {
            transitionToGame()
        }
    }

    /// 백 — characterID에 따라 분기. .kim은 CharacterSelectScene, 그 외는 SkillExplanationScene.
    private func transitionBack() {
        guard let view = self.view else { return }
        isTransitioning = true
        switch characterID {
        case .kim:
            let scene = CharacterSelectScene.newCharacterSelectScene()
            SceneRouter.present(scene, on: view, route: .backward)
        case .jung, .geon, .im, .lee:
            let scene = SkillExplanationScene.newSkillExplanationScene(
                characterID: characterID
            )
            SceneRouter.present(scene, on: view, route: .backward)
        }
    }

    /// 시작 — GameScene 진입. 보호 영역인 `GameScene.newGameScene(characterID:difficulty:)`
    /// 시그니처를 그대로 호출.
    private func transitionToGame() {
        guard let view = self.view else { return }
        isTransitioning = true
        let gameScene = GameScene.newGameScene(
            characterID: characterID,
            difficulty: selectedDifficulty
        )
        SceneRouter.present(gameScene, on: view, route: .intoGame)
    }
}
