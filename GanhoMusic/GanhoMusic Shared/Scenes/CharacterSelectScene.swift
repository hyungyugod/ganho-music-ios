//
//  CharacterSelectScene.swift
//  GanhoMusic Shared
//
//  Phase 10-1b · 시작 시퀀스 2단계 — 캐릭터 5장 + 태그 라벨 + 뒤로/시작 버튼 2개
//  Sprint 2 · 메뉴 v2 리스킨 — 3-stop warm gradient + AccentLine 헤더 + GlassPill 뒤로 +
//               DarkContextChip 난이도 + 5장 글래스 외곽 컨테이너 + 색 점 + DarkContextChip 스킬 정보 +
//               PrimaryButton confirm. overlay 패널 제거. backButton 인스턴스 → backPill 교체.
//
//  StartScene → 본 씬 → SkillExplanationScene(or GameScene .kim 스킵).
//  difficulty는 init 인자로 받아 *불변 상태*로 보관. Swift 컴파일 타임 강제.
//  CharacterCardNode 내부 변경 0건 — 카드 *외부*에 글래스 컨테이너/색 점/태그 라벨을 별도 자식으로 부착.
//

import SpriteKit

/// 캐릭터 선택 단일 결정 씬. v2 리스킨: 그라데이션 + AccentLine 헤더 + GlassPill 뒤로 + DarkContextChip 난이도 +
/// 5장 글래스 외곽 컨테이너(카드 위) + 우상단 색 점 + 하단 DarkContextChip 스킬 정보 + 가운데 confirm 버튼.
/// difficulty는 *불변 입력* — init 주입 후 그대로 다음 씬으로 전달.
final class CharacterSelectScene: SKScene {

    // MARK: - Properties
    /// init 주입된 난이도. 불변. 다음 씬(SkillExplanation 또는 GameScene)으로 그대로 전달.
    private let difficulty: Difficulty
    /// 씬 전환 가드.
    private var isTransitioning = false
    /// Sprint 2 — 헤더 라벨(Jua, navyDeep).
    private let headerLabel = SKLabelNode(text: GameConfig.characterSelectHeaderText)
    /// Sprint 2 — 헤더 위 AccentLine.
    private let accentLine = AccentLineNode()
    /// Sprint 2 — 헤더 아래 Gowun Dodum 부제.
    private let headerSubLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    /// 현재 선택된 캐릭터. 기본 .kim. didMove에서 repo.current로 복원.
    private var selectedCharacterID: CharacterID = .kim
    /// 5 카드 인스턴스 보관. setup/layout/hit test에 재사용.
    private var characterCards: [CharacterCardNode] = []
    /// 5 태그 라벨 — 카드 *외부*. CharacterCardNode 내부 변경 0건 정책.
    private var tagLabels: [CharacterID: SKLabelNode] = [:]
    /// Sprint 2 — 5장 카드 외곽 글래스 컨테이너. 카드와 동일 좌표, zPos 90(카드 100보다 뒤).
    private var cardContainers: [CharacterID: SKShapeNode] = [:]
    /// Sprint 2 — 5장 카드 우상단 색 점.
    private var cardColorDots: [CharacterID: SKShapeNode] = [:]
    /// Sprint 2 — 좌상단 뒤로 GlassPill.
    private var backPill: GlassPillNode?
    /// Sprint 2 — 우상단 난이도 DarkContextChip.
    private var difficultyChip: DarkContextChipNode?
    /// Sprint 2 — 하단 스킬 정보 DarkContextChip(선택 변경 시 rebuild).
    private var skillInfoChip: DarkContextChipNode?
    private let confirmButton = PrimaryButtonNode(text: "이 친구로 시작")
    private let preferenceRepo = CharacterPreferenceRepository()
    /// Sprint 2 — 그라데이션 배경 노드. didChangeSize 시 재생성을 위해 참조 보관.
    private var gradientBackground: GradientBackgroundNode?

    // MARK: - Factory
    /// difficulty 인자를 받아 인스턴스 생성. StartScene이 유일 호출자.
    class func newCharacterSelectScene(difficulty: Difficulty) -> CharacterSelectScene {
        let scene = CharacterSelectScene(
            size: CGSize(width: 1024, height: 768),
            difficulty: difficulty
        )
        scene.scaleMode = .resizeFill
        return scene
    }

    // MARK: - Init
    /// difficulty는 `let` 이므로 super.init 전에 저장. ResultScene 동형 패턴.
    private init(size: CGSize, difficulty: Difficulty) {
        self.difficulty = difficulty
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .ganhoBgWarmTop  // Sprint 2 — 1프레임 fallback도 warm.
        setupGradientBackground()           // Sprint 2 — 3-stop warm gradient.
        setupHeader()                       // Sprint 2 — AccentLine + Jua + Gowun Dodum 부제.
        setupTopBar()                       // Sprint 2 — GlassPill 뒤로 + DarkContextChip 난이도.
        selectedCharacterID = preferenceRepo.current
        setupCardContainers()               // Sprint 2 — 카드 외곽 글래스 5개.
        setupCharacterCards()
        setupCardColorDots()                // Sprint 2 — 카드 우상단 색 점 5개.
        setupTagLabels()
        applyGlassContainerSelection(id: selectedCharacterID)
        setupConfirmButton()
        rebuildSkillInfoPanel(for: selectedCharacterID)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        rebuildGradientBackground()
        layoutHeader()
        layoutTopBar()
        layoutCardContainers()
        layoutCharacterCards()
        layoutCardColorDots()
        layoutTagLabels()
        layoutConfirmButton()
        layoutSkillInfoChip()
    }

    // MARK: - Setup (Sprint 2 · Background)
    private func setupGradientBackground() {
        let node = GradientBackgroundNode.threeStop(
            size: size,
            topColor: .ganhoBgWarmTop,
            midColor: .ganhoBgWarmMid,
            bottomColor: .ganhoBgWarmBottom
        )
        node.position = CGPoint(x: frame.midX, y: frame.midY)
        gradientBackground = node
        addChild(node)
    }

    private func rebuildGradientBackground() {
        gradientBackground?.removeFromParent()
        gradientBackground = nil
        setupGradientBackground()
    }

    // MARK: - Setup (Sprint 2 · Header)
    private func setupHeader() {
        headerLabel.fontName = GameConfig.fontDisplay
        headerLabel.fontSize = GameConfig.characterSelectHeaderFontSize
        headerLabel.fontColor = .ganhoNavyDeep
        headerLabel.horizontalAlignmentMode = .center
        headerLabel.verticalAlignmentMode = .center
        addChild(headerLabel)

        headerSubLabel.text = GameConfig.characterSelectHeaderSubText
        headerSubLabel.fontSize = GameConfig.characterSelectHeaderSubFontSize
        headerSubLabel.fontColor = .ganhoNavyMuted
        headerSubLabel.horizontalAlignmentMode = .center
        headerSubLabel.verticalAlignmentMode = .center
        addChild(headerSubLabel)

        addChild(accentLine)
        layoutHeader()
    }

    private func layoutHeader() {
        let centerX = frame.midX
        let baseY = frame.midY + GameConfig.characterSelectHeaderOffsetY
        headerLabel.position = CGPoint(x: centerX, y: baseY)
        headerSubLabel.position = CGPoint(
            x: centerX,
            y: baseY + GameConfig.characterSelectHeaderSubOffsetY
        )
        accentLine.position = CGPoint(
            x: centerX,
            y: baseY + GameConfig.characterSelectAccentLineOffsetY
        )
    }

    // MARK: - Setup (Sprint 2 · Top Bar)
    private func setupTopBar() {
        let back = GlassPillNode(
            text: GameConfig.characterSelectBackPillText,
            size: CGSize(
                width: GameConfig.characterSelectBackPillWidth,
                height: GameConfig.characterSelectBackPillHeight
            )
        )
        backPill = back
        addChild(back)

        let chip = DarkContextChipNode(
            label: GameConfig.characterSelectDifficultyChipLabel,
            badge: difficulty.shortName
        )
        difficultyChip = chip
        addChild(chip)
        layoutTopBar()
    }

    private func layoutTopBar() {
        let y = frame.maxY - GameConfig.characterSelectTopBarMarginY
        backPill?.position = CGPoint(
            x: frame.minX + GameConfig.characterSelectTopBarMarginX
                + GameConfig.characterSelectBackPillWidth / 2,
            y: y
        )
        if let chip = difficultyChip {
            let chipHalfWidth = chip.calculateAccumulatedFrame().width / 2
            chip.position = CGPoint(
                x: frame.maxX - GameConfig.characterSelectTopBarMarginX - chipHalfWidth,
                y: y
            )
        }
    }

    // MARK: - Setup (Sprint 2 · Card Containers · Glass Outer)
    /// 5 카드 외곽 글래스 컨테이너. *카드보다 뒤*(zPos 90)에 배치되어 카드 위 시각만 강조.
    private func setupCardContainers() {
        for id in CharacterID.allCases {
            let size = CGSize(
                width: GameConfig.characterCardGlassWidth,
                height: GameConfig.characterCardGlassHeight
            )
            let container = SKShapeNode(
                rectOf: size,
                cornerRadius: GameConfig.characterCardGlassCornerRadius
            )
            container.fillColor = UIColor.white
                .withAlphaComponent(GameConfig.characterCardGlassFillAlpha)
            container.strokeColor = .clear
            container.lineWidth = 0
            container.zPosition = 90
            container.name = "characterCardGlass_\(id.rawValue)"
            cardContainers[id] = container
            addChild(container)
        }
        layoutCardContainers()
    }

    private func layoutCardContainers() {
        for (id, container) in cardContainers {
            container.position = CGPoint(
                x: cardBaseX(for: id),
                y: cardBaseY(for: id)
            )
        }
    }

    /// 5 카드 setup + 초기 선택 상태 적용. TitleScene 5-1 패턴 답습.
    private func setupCharacterCards() {
        for id in CharacterID.allCases {
            let card = CharacterCardNode(id: id)
            card.setSelected(id == selectedCharacterID)
            characterCards.append(card)
            addChild(card)
        }
        layoutCharacterCards()
    }

    private func layoutCharacterCards() {
        for card in characterCards {
            card.position = CGPoint(
                x: cardBaseX(for: card.id),
                y: cardBaseY(for: card.id)
            )
        }
    }

    // MARK: - Setup (Sprint 2 · Color Dots)
    /// 각 카드 우상단의 작은 색 점(반지름 4). 글래스 컨테이너 위(zPos 110).
    private func setupCardColorDots() {
        for id in CharacterID.allCases {
            let dot = SKShapeNode(circleOfRadius: GameConfig.characterCardColorDotRadius)
            dot.fillColor = id.dotColor
            dot.strokeColor = .clear
            dot.lineWidth = 0
            dot.zPosition = 110
            dot.name = "characterCardDot_\(id.rawValue)"
            cardColorDots[id] = dot
            addChild(dot)
        }
        layoutCardColorDots()
    }

    private func layoutCardColorDots() {
        for (id, dot) in cardColorDots {
            let baseX = cardBaseX(for: id)
            let baseY = cardBaseY(for: id)
            dot.position = CGPoint(
                x: baseX + GameConfig.characterCardGlassWidth / 2
                    - GameConfig.characterCardColorDotInsetX,
                y: baseY + GameConfig.characterCardGlassHeight / 2
                    - GameConfig.characterCardColorDotInsetY
            )
        }
    }

    /// 5 태그 라벨 — 카드 *외부*. CharacterCardNode 내부 변경 0건 정책.
    /// 각 카드와 같은 x 좌표 + characterSelectTagOffsetY만큼 아래 위치.
    private func setupTagLabels() {
        for id in CharacterID.allCases {
            let label = SKLabelNode(fontNamed: GameConfig.fontBody)
            label.text = id.tag
            label.fontSize = GameConfig.characterSelectTagFontSize
            label.fontColor = .ganhoNavyMuted
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.zPosition = 110
            label.name = "characterTag_\(id.rawValue)"
            tagLabels[id] = label
            addChild(label)
        }
        layoutTagLabels()
    }

    private func layoutTagLabels() {
        for id in CharacterID.allCases {
            guard let label = tagLabels[id] else { continue }
            label.position = CGPoint(
                x: cardBaseX(for: id),
                y: cardBaseY(for: id) + GameConfig.characterSelectTagOffsetY
            )
        }
    }

    // MARK: - Setup (Sprint 2 · Confirm Button)
    private func setupConfirmButton() {
        addChild(confirmButton)
        layoutConfirmButton()
    }

    /// Sprint 2 — confirm 버튼은 가운데. backButton 인스턴스 제거됨.
    private func layoutConfirmButton() {
        confirmButton.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.characterSelectConfirmButtonOffsetY
        )
    }

    // MARK: - Setup (Sprint 2 · Skill Info Panel)
    /// 선택 캐릭터의 스킬명 + 속도 배율을 가운데 하단 DarkContextChip로 표시.
    /// 선택 변경 시 호출 — 기존 인스턴스 제거 후 재생성.
    private func rebuildSkillInfoPanel(for id: CharacterID) {
        skillInfoChip?.removeFromParent()
        let speedText = formatted(id.playerSpeedMultiplier)
        let label: String
        if id.skill == .none {
            label = "스킬 없음  •  속도 ×\(speedText)"
        } else {
            label = "스킬: \(id.skill.displayName)  •  속도 ×\(speedText)"
        }
        let chip = DarkContextChipNode(label: label, badge: nil)
        skillInfoChip = chip
        addChild(chip)
        layoutSkillInfoChip()
    }

    private func layoutSkillInfoChip() {
        skillInfoChip?.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.characterSelectSkillInfoOffsetY
        )
    }

    /// 1.10 → "1.1", 1.00 → "1.0", 0.95 → "0.95"처럼 소수점 한 자리 우선.
    /// 한국어 톤 + 시각 균형 — 소수 둘째자리는 .95처럼 의미 있을 때만 노출.
    private func formatted(_ value: CGFloat) -> String {
        let rounded1 = (value * 10).rounded() / 10
        if abs(value - rounded1) < 0.001 {
            return String(format: "%.1f", Double(value))
        }
        return String(format: "%.2f", Double(value))
    }

    // MARK: - Card Geometry Helpers (Sprint 2 · §Q5)
    /// 카드 5장 가로 정렬 — 기존 layoutCharacterCards 좌표식과 동일.
    /// 헬퍼로 분리 — 카드/컨테이너/색 점/태그 라벨이 모두 같은 헬퍼를 호출하여 좌표 동기화.
    private func cardBaseX(for id: CharacterID) -> CGFloat {
        let allCases = CharacterID.allCases
        let count = allCases.count
        let width = GameConfig.characterCardWidth
        let spacing = GameConfig.characterCardSpacing
        let totalWidth = width * CGFloat(count) + spacing * CGFloat(count - 1)
        let startX = frame.midX - totalWidth / 2 + width / 2
        guard let index = allCases.firstIndex(of: id) else { return startX }
        return startX + CGFloat(index) * (width + spacing)
    }

    private func cardBaseY(for id: CharacterID) -> CGFloat {
        _ = id  // 향후 캐릭터별 y 미세 조정 여지. 현재는 모두 동일 y.
        return frame.midY + GameConfig.characterSelectCardOffsetY
    }

    // MARK: - Selection
    /// 선택 캐릭터 변경 + 5 카드 알파/scale 일괄 갱신 + 디스크 저장 + 외곽/스킬 패널 동기화.
    private func select(_ id: CharacterID) {
        selectedCharacterID = id
        preferenceRepo.save(id)
        for card in characterCards {
            card.setSelected(card.id == id)
        }
        applyGlassContainerSelection(id: id)
        rebuildSkillInfoPanel(for: id)
    }

    /// Sprint 2 — 외곽 글래스 컨테이너 선택 상태 시각 동기화.
    /// 선택된 컨테이너: 코랄 stroke + scale 1.08 + y +12 (살짝 위로 뜸).
    /// 해제된 컨테이너: stroke clear + scale 1.0 + y 원위치.
    private func applyGlassContainerSelection(id: CharacterID) {
        for (cid, container) in cardContainers {
            let selected = cid == id
            container.strokeColor = selected ? .ganhoCoralPrimary : .clear
            container.lineWidth = selected
                ? GameConfig.characterCardGlassSelectedStrokeWidth
                : 0
            let scaleTarget: CGFloat = selected
                ? GameConfig.characterCardGlassSelectedScale
                : 1.0
            let yOffset: CGFloat = selected
                ? GameConfig.characterCardGlassSelectedYOffset
                : 0
            container.removeAction(forKey: "glassSelect")
            let baseY = cardBaseY(for: cid)
            let scaleAction = SKAction.scale(
                to: scaleTarget,
                duration: GameConfig.characterCardGlassScaleDuration
            )
            let moveAction = SKAction.moveTo(
                y: baseY + yOffset,
                duration: GameConfig.characterCardGlassScaleDuration
            )
            container.run(
                SKAction.group([scaleAction, moveAction]),
                withKey: "glassSelect"
            )
        }
    }

    // MARK: - Touch
    /// 우선순위: 캐릭터 카드 → 뒤로 → confirm. (외 영역 무동작)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        // 1) 카드 hit test.
        for card in characterCards {
            if card.contains(location) {
                select(card.id)
                return
            }
        }
        // 2) 뒤로 GlassPill.
        if backPill?.contains(location) == true {
            transitionToStart()
            return
        }
        // 3) confirm 버튼 — .kim이면 GameScene 직진, 그 외는 SkillExplanation.
        if confirmButton.contains(location) {
            transitionToNext()
        }
    }

    /// 뒤로 가기 — StartScene으로.
    private func transitionToStart() {
        guard let view = self.view else { return }
        isTransitioning = true
        let scene = StartScene.newStartScene()
        let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
        view.presentScene(scene, transition: fade)
    }

    /// 시작 — .kim은 GameScene 직진(스킬 없음 = 스킬 화면 스킵), 그 외는 SkillExplanation.
    /// SPEC §3 4단계 흐름 + §"기능 3" 김간호 스킵 정책 일관 표현.
    private func transitionToNext() {
        guard let view = self.view else { return }
        isTransitioning = true
        let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
        switch selectedCharacterID {
        case .kim:
            // 김간호 — 스킬 화면 스킵 → GameScene 직진.
            let gameScene = GameScene.newGameScene(
                characterID: selectedCharacterID,
                difficulty: difficulty
            )
            view.presentScene(gameScene, transition: fade)
        case .jung, .geon, .im, .lee:
            // 스킬 보유 캐릭터 — SkillExplanationScene으로.
            let scene = SkillExplanationScene.newSkillExplanationScene(
                characterID: selectedCharacterID,
                difficulty: difficulty
            )
            view.presentScene(scene, transition: fade)
        }
    }
}
