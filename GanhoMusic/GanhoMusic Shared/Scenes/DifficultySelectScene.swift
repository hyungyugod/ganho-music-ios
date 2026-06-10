//
//  DifficultySelectScene.swift
//  GanhoMusic Shared
//
//  R4 §F-4 — 난이도 선택 (03_UI §6-4). PixelCardNode 3장 가로 + 빌런 아이콘 + 최고 기록 칩.
//  난이도 저장 포맷(difficultyRepo.save)과 GameScene 진입 시그니처는 변경하지 않는다.
//  뒤로 = CharacterSelect 일원화 (§C-9 — 브리핑이 선택 사항이 되어 .kim 분기 제거).
//

import SpriteKit

/// 흐름의 마지막 결정 씬. characterID 불변 + 난이도만 골라서 GameScene으로 진입.
final class DifficultySelectScene: BaseMenuScene {

    // MARK: - Properties
    /// init 주입된 캐릭터 ID. 불변.
    private let characterID: CharacterID
    /// 현재 선택된 난이도. didMove에서 repo.current로 복원.
    private var selectedDifficulty: Difficulty = .easy
    /// 난이도 저장소. didMove에서 1회 읽기, select 시 save (저장 포맷 불변).
    private let difficultyRepo = DifficultyPreferenceRepository()
    /// 씬 전환 가드.
    private var isTransitioning = false

    private let titleLabel = SKLabelNode(fontNamed: Typography.V3.h2.fontName)
    private var backButton: PixelButtonNode?
    private var contextChip: PixelChipNode?
    private var difficultyCards: [Difficulty: PixelCardNode] = [:]
    /// 카드 래퍼 — 컴팩트 배율은 래퍼가, 선택 scale(1.04)은 PixelCardNode가 소유 (충돌 분리).
    private var difficultyCardHolders: [Difficulty: SKNode] = [:]
    private var startButton: PixelButtonNode?

    // MARK: - Factory
    /// CharacterSelectScene(출발) 또는 SkillBriefingScene(난이도 선택)이 호출.
    class func newDifficultySelectScene(characterID: CharacterID) -> DifficultySelectScene {
        let scene = DifficultySelectScene(
            size: CGSize(width: 1024, height: 768),
            characterID: characterID
        )
        scene.scaleMode = .resizeFill
        return scene
    }

    // MARK: - Init
    private init(size: CGSize, characterID: CharacterID) {
        self.characterID = characterID
        super.init(size: size)
    }

    @available(*, unavailable, message: "Use newDifficultySelectScene(characterID:) instead.")
    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        setupNightShiftBackdrop()
        selectedDifficulty = difficultyRepo.current   // 1회 복원
        setupTitle()
        setupTopBar()
        setupDifficultyCards()
        setupStartButton()
        layoutScene()
        applySelection(animated: false)
        runStaggeredAppear(
            [titleLabel, contextChip,
             difficultyCards[.easy], difficultyCards[.normal], difficultyCards[.hard],
             startButton].compactMap { $0 }
        )
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard startButton != nil else { return }   // didMove 이전 호출 가드
        cancelStaggeredAppear()
        rebuildNightShiftBackdrop()
        layoutScene()
    }

    // MARK: - Setup
    private func setupTitle() {
        titleLabel.text = UILayout.R4.difficultyTitleText
        titleLabel.fontSize = Typography.V3.h2.size
        titleLabel.fontColor = Palette.textHi
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.zPosition = ZOrder.Layer.hud
        addChild(titleLabel)
    }

    private func setupTopBar() {
        let back = PixelButtonNode(title: UILayout.R4.selectBackButtonText,
                                   variant: .ghost,
                                   size: UILayout.R4.backButtonSize)
        back.onTap = { [weak self] in self?.transitionBack() }
        back.zPosition = ZOrder.Layer.hud
        backButton = back
        addChild(back)

        // 캐릭터 컨텍스트 칩 — 이름 + 포트레이트 아이콘 (§F-4, v2 좌측 요약 카드 축약).
        let icon = SKSpriteNode(texture: PixelPortraitSprite.texture(for: characterID))
        icon.size = CGSize(width: UILayout.R4.difficultyContextChipIconSide,
                           height: UILayout.R4.difficultyContextChipIconSide)
        let chip = PixelChipNode(text: characterID.displayName,
                                 style: .accent(Palette.character(characterID)),
                                 icon: icon)
        chip.zPosition = ZOrder.Layer.hud
        contextChip = chip
        addChild(chip)
    }

    /// 난이도 카드 3장 — 콘텐츠는 init 1회 조립 (텍스처·칩 재생성 없음).
    private func setupDifficultyCards() {
        // 최고 기록 — CharacterSelect와 동일 scope 해석 (§F-4).
        let scope = AccountProgressScopeProvider.current(authProfile: AuthProfileRepository().current)
        let scoreRepo = PerDifficultyScoreRepository.scoped(scope: scope)

        for difficulty in Difficulty.allCases {
            let card = PixelCardNode(size: UILayout.R4.difficultyCardSize,
                                     accent: Palette.difficulty(difficulty))
            buildCardContent(card, difficulty: difficulty, scoreRepo: scoreRepo)
            let holder = SKNode()
            holder.zPosition = ZOrder.Layer.characters
            holder.addChild(card)
            difficultyCards[difficulty] = card
            difficultyCardHolders[difficulty] = holder
            addChild(holder)
        }
    }

    private func buildCardContent(_ card: PixelCardNode,
                                  difficulty: Difficulty,
                                  scoreRepo: PerDifficultyScoreRepository) {
        let accent = Palette.difficulty(difficulty)

        let name = SKLabelNode(fontNamed: Typography.V3.h2.fontName)
        name.text = difficulty.displayName
        name.fontSize = Typography.V3.h2.size
        name.fontColor = accent
        name.horizontalAlignmentMode = .center
        name.verticalAlignmentMode = .center
        name.position = CGPoint(x: 0, y: UILayout.R4.difficultyNameOffsetY)
        card.contentNode.addChild(name)

        let caption = SKLabelNode(fontNamed: Typography.V3.caption.fontName)
        caption.text = UILayout.R4.difficultyTargetCaptionText
        caption.fontSize = Typography.V3.caption.size
        caption.fontColor = Palette.textLo
        caption.horizontalAlignmentMode = .center
        caption.verticalAlignmentMode = .center
        caption.position = CGPoint(x: 0, y: UILayout.R4.difficultyTargetCaptionOffsetY)
        card.contentNode.addChild(caption)

        // 목표 점수 — difficulty.targetScore (수치 하드코딩 금지 — §F-4).
        let target = SKLabelNode(fontNamed: Typography.V3.h1.fontName)
        target.text = "\(difficulty.targetScore)"
        target.fontSize = Typography.V3.h1.size
        target.fontColor = Palette.textHi
        target.horizontalAlignmentMode = .center
        target.verticalAlignmentMode = .center
        target.position = CGPoint(x: 0, y: UILayout.R4.difficultyTargetOffsetY)
        card.contentNode.addChild(target)

        // 등장 빌런 아이콘 행 (§C-11 매핑 — 기존 빌런 픽셀 데이터 재사용).
        let villains = UILayout.R4.difficultyVillains(difficulty)
        let iconSize = UILayout.R4.difficultyVillainIconSize
        let totalWidth = iconSize.width * CGFloat(villains.count)
            + UILayout.R4.difficultyVillainIconGap * CGFloat(villains.count - 1)
        var cursorX = -totalWidth / 2 + iconSize.width / 2
        for villain in villains {
            let icon = SKSpriteNode(texture: PixelPortraitSprite.villainTexture(villain))
            icon.size = iconSize
            icon.position = CGPoint(x: cursorX.rounded(),
                                    y: UILayout.R4.difficultyVillainRowOffsetY)
            card.contentNode.addChild(icon)
            cursorX += iconSize.width + UILayout.R4.difficultyVillainIconGap
        }

        // 내 최고 기록 칩 — 0점이면 칩 미생성 (§F-4, isHidden 게이트 금지).
        let best = scoreRepo.best(characterID: characterID, difficulty: difficulty)
        if best > 0 {
            let chip = PixelChipNode(
                text: "\(UILayout.R4.difficultyBestChipPrefix)\(best)\(UILayout.R4.difficultyBestChipSuffix)",
                style: .accent(Palette.gold)
            )
            chip.position = CGPoint(x: 0, y: UILayout.R4.difficultyBestChipOffsetY)
            card.contentNode.addChild(chip)
        }
    }

    private func setupStartButton() {
        let start = PixelButtonNode(title: UILayout.R4.difficultyStartButtonText,
                                    variant: .primary,
                                    size: UILayout.R4.ctaButtonSize)
        start.onTap = { [weak self] in self?.transitionToGame() }
        start.zPosition = ZOrder.Layer.hud
        startButton = start
        addChild(start)
    }

    // MARK: - Layout
    private func layoutScene() {
        let safe = menuSafeInsets()
        let scale = menuCompactScale()
        let topY = (frame.maxY - safe.top - UILayout.v3ScreenEdgeInset
                    - UILayout.R4.backButtonSize.height * scale / 2).rounded()

        titleLabel.setScale(scale)
        titleLabel.position = CGPoint(
            x: frame.midX.rounded(),
            y: (frame.maxY - safe.top - UILayout.R4.difficultyTitleTopInset * scale).rounded()
        )

        backButton?.setScale(scale)
        backButton?.position = CGPoint(
            x: (frame.minX + safe.left + UILayout.v3ScreenEdgeInset
                + UILayout.R4.backButtonSize.width * scale / 2).rounded(),
            y: topY
        )

        if let chip = contextChip {
            chip.setScale(scale)
            chip.position = CGPoint(
                x: (frame.maxX - safe.right - UILayout.v3ScreenEdgeInset
                    - chip.chipSize.width * scale / 2).rounded(),
                y: topY
            )
        }

        let rowY = (frame.midY + UILayout.R4.difficultyCardRowYOffset * scale).rounded()
        let step = UILayout.R4.difficultyCardStep * scale
        for (index, difficulty) in Difficulty.allCases.enumerated() {
            guard let holder = difficultyCardHolders[difficulty] else { continue }
            let offset = CGFloat(index) - CGFloat(Difficulty.allCases.count - 1) / 2
            holder.setScale(scale)
            holder.position = CGPoint(x: (frame.midX + offset * step).rounded(), y: rowY)
        }

        startButton?.setScale(scale)
        startButton?.position = CGPoint(
            x: frame.midX.rounded(),
            y: (frame.minY + safe.bottom + UILayout.R4.ctaBottomInset * scale).rounded()
        )
    }

    // MARK: - Selection (§F-4 — 저장 포맷 불변)
    private func selectDifficulty(_ id: Difficulty) {
        selectedDifficulty = id
        difficultyRepo.save(id)
        applySelection(animated: true)
    }

    /// 선택 카드 강조 + 나머지 dim + 시작 버튼 액센트 동기화 (Palette.difficulty/difficultyDeep).
    private func applySelection(animated: Bool) {
        for (difficulty, card) in difficultyCards {
            let selected = difficulty == selectedDifficulty
            card.setSelected(selected, animated: animated)
            card.alpha = selected ? 1.0 : FeelTuning.R4.difficultyDimAlpha
        }
        startButton?.setPrimaryAccent(
            face: Palette.difficulty(selectedDifficulty),
            shadow: Palette.difficultyDeep(selectedDifficulty)
        )
    }

    // MARK: - Touch (씬 레벨 — 카드 탭만. 버튼은 자체 처리 — §E-5)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        // holder는 씬 직속 — accumulatedFrame이 씬 좌표 (카드 직접 검사 시 좌표계 불일치 주의).
        for (difficulty, holder) in difficultyCardHolders {
            if holder.calculateAccumulatedFrame().contains(location) {
                selectDifficulty(difficulty)
                return
            }
        }
    }

    // MARK: - Transition
    /// 뒤로 — CharacterSelect 일원화 (§C-9, 기존 .kim 분기 제거).
    private func transitionBack() {
        guard !isTransitioning, let view = self.view else { return }
        isTransitioning = true
        let scene = CharacterSelectScene.newCharacterSelectScene()
        SceneRouter.present(scene, on: view, route: .backward)
    }

    /// 시작 — `GameScene.newGameScene(characterID:difficulty:)` 시그니처·라우트 불변.
    private func transitionToGame() {
        guard let view = self.view else { return }
        guard !isTransitioning else { return }
        isTransitioning = true
        let gameScene = GameScene.newGameScene(
            characterID: characterID,
            difficulty: selectedDifficulty
        )
        SceneRouter.present(gameScene, on: view, route: .intoGame)
    }
}
