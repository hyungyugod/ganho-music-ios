//
//  CharacterSelectScene.swift
//  GanhoMusic Shared
//
//  Phase 10-1b · 시작 시퀀스 2단계 — 캐릭터 5장 + 태그 라벨 + 뒤로/시작 버튼 2개
//  Sprint 2 · 메뉴 v2 리스킨 — 3-stop warm gradient + AccentLine 헤더 + GlassPill 뒤로 +
//               DarkContextChip 난이도 + 5장 글래스 외곽 컨테이너 + 색 점 + DarkContextChip 스킬 정보 +
//               PrimaryButton confirm.
//  Sprint 6 · 흐름 재편 — init(difficulty:) 제거, difficulty/difficultyChip 모두 삭제.
//               5장 카드 위에 CharacterFaceNode 부착(zPos 105). 백버튼 텍스트 "← 메인".
//               .kim 분기는 DifficultySelectScene으로, 그 외는 SkillExplanationScene(characterID:)으로.
//
//  StartScene → 본 씬 → SkillExplanationScene(or DifficultySelectScene .kim 분기).
//  CharacterCardNode 내부 변경 0건 — 카드 *외부*에 글래스 컨테이너/색 점/태그 라벨/얼굴 노드를 별도 자식으로 부착.
//

import SpriteKit

/// 캐릭터 선택 단일 결정 씬. v2 리스킨 + Sprint 6 흐름 재편.
/// Sprint 6 — difficulty 필드 제거. 캐릭터 ID만 결정해서 다음 씬으로 넘김.
final class CharacterSelectScene: BaseMenuScene {

    // MARK: - Properties
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
    /// Sprint 6 — 5장 카드 위 얼굴 노드. PNG swap 호환 — `CharacterFaceNode`는 SKNode 서브클래스.
    private var characterFaces: [CharacterID: CharacterFaceNode] = [:]
    /// Sprint 2 — 좌상단 뒤로 GlassPill.
    private var backPill: GlassPillNode?
    /// Sprint 2 — 하단 스킬 정보 DarkContextChip(선택 변경 시 rebuild).
    private var skillInfoChip: DarkContextChipNode?
    private let confirmButton = PrimaryButtonNode(text: "다음")
    private let preferenceRepo = CharacterPreferenceRepository()

    // Sprint 8 Phase B — 스와이프 페이지 상태 (4 properties).
    /// 5장 카드 중 현재 중앙 카드 인덱스. didMove에서 selectedCharacterID 기준으로 초기화.
    private var currentIndex: Int = 0
    /// 카드 순서 고정. CharacterID.allCases 그대로(.kim/.jung/.geon/.im/.lee).
    private let characters: [CharacterID] = CharacterID.allCases
    /// 스와이프 시작 x 좌표. touchesBegan에서 기록.
    private var swipeStartX: CGFloat = 0
    /// 한 터치 사이클당 1회만 스와이프 트리거 — 중복 swipeTo 방지.
    private var didSwipeInCurrentTouch: Bool = false

    // Sprint 9 Phase A — 좌우 화살표 GlassPill 2개.
    /// 왼쪽 화살표("‹") — currentIndex-1로 스와이프. 끝(index 0)에서 isHidden=true.
    private var leftArrowChip: GlassPillNode?
    /// 오른쪽 화살표("›") — currentIndex+1로 스와이프. 끝(index max)에서 isHidden=true.
    private var rightArrowChip: GlassPillNode?

    // MARK: - Factory
    /// Sprint 6 — 인자 제거. StartScene이 유일 호출자.
    class func newCharacterSelectScene() -> CharacterSelectScene {
        let scene = CharacterSelectScene(size: CGSize(width: 1024, height: 768))
        scene.scaleMode = .resizeFill
        return scene
    }

    // MARK: - Init
    /// Sprint 6 — difficulty 입력 제거.
    override init(size: CGSize) {
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .ganhoBgWarmTop  // Sprint 2 — 1프레임 fallback도 warm.
        setupWarmGradientBackground()       // Sprint 2 — 3-stop warm gradient.
        setupHeader()                       // Sprint 2 — AccentLine + Jua + Gowun Dodum 부제.
        setupTopBar()                       // Sprint 6 — GlassPill 뒤로만 (난이도 칩 제거).
        selectedCharacterID = preferenceRepo.current
        // Sprint 8 Phase B — 복원된 캐릭터의 인덱스로 currentIndex 동기화.
        currentIndex = characters.firstIndex(of: selectedCharacterID) ?? 0
        setupCardContainers()               // Sprint 2 — 카드 외곽 글래스 5개.
        setupCharacterCards()
        setupCharacterFaces()               // Sprint 6 — 얼굴 노드 5개.
        setupCardColorDots()                // Sprint 2 — 카드 우상단 색 점 5개.
        setupTagLabels()
        applyGlassContainerSelection(id: selectedCharacterID)
        setupConfirmButton()
        rebuildSkillInfoPanel(for: selectedCharacterID)
        setupArrowChips()                   // Sprint 9 Phase A — 좌우 ‹/› 화살표 2개.
        // Sprint 8 Phase B — 스와이프 페이지 초기 배치(애니메이션 없이).
        layoutCards(animated: false)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        rebuildWarmGradientBackground()
        layoutHeader()
        layoutTopBar()
        layoutCardContainers()
        layoutCharacterCards()
        layoutCharacterFaces()              // Sprint 6.
        layoutCardColorDots()
        layoutTagLabels()
        // Sprint 9 Phase A QA 3차 — 의존성 역전 후 호출 순서: chip 먼저(cardBottom 기준 식),
        // 그 다음 button(chip 기준 clamp). 산식이 chip 노드 없이도 동작하므로 순서 자체는 무관하나
        // 의존 방향 명확성을 위해 chip → button 순으로 변경.
        layoutSkillInfoChip()
        layoutConfirmButton()
        layoutArrowChips()                  // Sprint 9 Phase A.
        // Sprint 8 Phase B — 회전/사이즈 변경 시 카드 즉시 재배치(애니메이션 없이).
        layoutCards(animated: false)
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
        // 4-Bug Fix Sprint — 부제 "친구마다 다른 스킬과 이동속도를 가져요"를 완전 숨김.
        // removeFromParent() 금지(노드 트리 보존). isHidden=true로 시각만 차단.
        headerSubLabel.isHidden = true
        addChild(headerSubLabel)

        addChild(accentLine)
        layoutHeader()
    }

    private func layoutHeader() {
        // 4-Bug Fix Sprint — 헤더 묶음 V11 좌표.
        // V10(145)에서 +15pt 더 올려 카드 영역과 여백 확보.
        let centerX = frame.midX
        let baseY = frame.midY + GameConfig.characterSelectHeaderOffsetYV11
        headerLabel.position = CGPoint(x: centerX, y: baseY)
        headerSubLabel.position = CGPoint(
            x: centerX,
            y: baseY + GameConfig.characterSelectHeaderSubOffsetYV10
        )
        accentLine.position = CGPoint(
            x: centerX,
            y: baseY + GameConfig.characterSelectAccentLineOffsetYV10
        )
    }

    // MARK: - Setup (Sprint 6 · Top Bar — 백버튼만)
    /// Sprint 6 — 난이도 칩 삭제. 백 GlassPill만 좌상단에 배치.
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
        layoutTopBar()
    }

    private func layoutTopBar() {
        let y = frame.maxY - GameConfig.characterSelectTopBarMarginY
        backPill?.position = CGPoint(
            x: frame.minX + GameConfig.characterSelectTopBarMarginX
                + GameConfig.characterSelectBackPillWidth / 2,
            y: y
        )
    }

    // MARK: - Setup (Sprint 2 · Card Containers · Glass Outer)
    /// 5 카드 외곽 글래스 컨테이너. *카드보다 뒤*(zPos 90)에 배치되어 카드 위 시각만 강조.
    /// Sprint 7 Phase A — 크기를 v3(160×200, cornerRadius 22)로 갱신. alpha 0 — NIKKE 카드 자체가 충분히 강조,
    /// 글래스 외곽은 시각상 제거(코드/구조 변경 최소 — applyGlassContainerSelection은 계속 작동).
    private func setupCardContainers() {
        for id in CharacterID.allCases {
            let size = CGSize(
                width: GameConfig.characterCardWidthV3,
                height: GameConfig.characterCardHeightV3
            )
            let container = SKShapeNode(
                rectOf: size,
                cornerRadius: GameConfig.characterCardCornerRadiusV3
            )
            // Sprint 7 Phase A — alpha 0(시각 0). 노드는 남아 위치/scale 계산 보존.
            container.fillColor = UIColor.white
                .withAlphaComponent(GameConfig.characterCardGlassFillAlpha)
            container.strokeColor = .clear
            container.lineWidth = 0
            container.alpha = 0.0
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

    /// 5 카드 setup. Sprint 8 Phase B — 초기 선택 상태는 setPageState로 일괄 적용(layoutCards).
    /// setSelected는 byte-identical 보존되어 있지만 *호출하지 않음* (alpha/scale 충돌 방지).
    private func setupCharacterCards() {
        for id in CharacterID.allCases {
            let card = CharacterCardNode(id: id)
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

    // MARK: - Setup (Sprint 6 · Character Faces)
    /// Sprint 6 — 5장 카드 위에 CharacterFaceNode 부착. zPos 105(카드 100, 색점 110 사이).
    /// PNG swap 호환 — SKNode 서브클래스이므로 향후 SKSpriteNode(texture:) 교체 시 좌표·zPos 보존.
    private func setupCharacterFaces() {
        for id in CharacterID.allCases {
            let face = CharacterFaceNode(id: id)
            face.setScale(GameConfig.characterFaceScale)
            face.zPosition = GameConfig.characterFaceZPosition
            characterFaces[id] = face
            addChild(face)
        }
        layoutCharacterFaces()
    }

    private func layoutCharacterFaces() {
        // Sprint 9 Phase A — 얼굴 y offset V9(12pt). AS-IS: V4(8pt). 카드 중심에서 살짝 위로.
        for (id, face) in characterFaces {
            face.position = CGPoint(
                x: cardBaseX(for: id),
                y: cardBaseY(for: id) + GameConfig.characterFaceOffsetYWithinCardV9
            )
        }
    }

    // MARK: - Setup (Sprint 2 · Color Dots)
    /// 각 카드 우상단의 작은 색 점(반지름 4). 글래스 컨테이너 위(zPos 110).
    /// Sprint 7 Phase A — 카드 내부 elementHex로 흡수 → isHidden = true. 노드/위치 계산은 유지(회귀 안전).
    private func setupCardColorDots() {
        for id in CharacterID.allCases {
            let dot = SKShapeNode(circleOfRadius: GameConfig.characterCardColorDotRadius)
            dot.fillColor = id.dotColor
            dot.strokeColor = .clear
            dot.lineWidth = 0
            dot.zPosition = 110
            dot.name = "characterCardDot_\(id.rawValue)"
            // Sprint 7 Phase A — 카드 내부 elementHex로 흡수.
            dot.isHidden = true
            cardColorDots[id] = dot
            addChild(dot)
        }
        layoutCardColorDots()
    }

    /// Sprint 7 Phase A — 색점 isHidden이지만 위치 계산은 v3 폭(160×200)에 맞춰 일관성 유지.
    /// 기존 characterCardGlassWidth(156)/Height(204) 상수는 값 보존(다른 사용처 가능성).
    private func layoutCardColorDots() {
        for (id, dot) in cardColorDots {
            let baseX = cardBaseX(for: id)
            let baseY = cardBaseY(for: id)
            dot.position = CGPoint(
                x: baseX + GameConfig.characterCardWidthV3 / 2
                    - GameConfig.characterCardColorDotInsetX,
                y: baseY + GameConfig.characterCardHeightV3 / 2
                    - GameConfig.characterCardColorDotInsetY
            )
        }
    }

    /// 5 태그 라벨 — 카드 *외부*. CharacterCardNode 내부 변경 0건 정책.
    /// 각 카드와 같은 x 좌표 + characterSelectTagOffsetY만큼 아래 위치.
    /// Sprint 7 Phase A — 카드 내부 nameLabel + speedLabel로 흡수 → isHidden = true.
    /// 노드/위치 계산은 유지(회귀 안전 — id.tag 값은 보존).
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
            // Sprint 7 Phase A — 카드 내부로 흡수됨.
            label.isHidden = true
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
    /// Sprint 7+ — safeArea.bottom 회피. 카드 하단(cardBaseY + characterCardHeight/2)보다 충분히 아래.
    /// Sprint 9 Phase A QA 3차 (Case B) — **cardBottom anchor 단일 식으로 의존성 역전**.
    ///   AS-IS: chip이 button.y에 종속(chip = button.y + 64). cardCenterY를 낮추면 button이 음수 → chip도 충돌.
    ///   TO-BE: chip이 cardBottom에 종속(chip = cardBottom − 20 − chipHalf). button이 chip.y에 종속.
    ///     단방향 의존성: cardBottom → chip → button. Spring 비유: 의존성 역전(DIP)으로 button 산출이
    ///     "chip을 모르는" 식에서 "chip을 기반으로 clamp되는" 식으로 바뀜.
    /// 호출 순서: chip 먼저, button 나중 — didMove/didChangeSize에서 순서 보장.
    /// 기존 characterSelectConfirmButtonOffsetY(-180)는 값 보존(다른 곳 참조 가능성).
    private func layoutConfirmButton() {
        let safe = SceneSafeArea.insets(for: self)
        let baseY = frame.minY + safe.bottom + GameConfig.adaptiveBottomMargin
            + GameConfig.characterSelectConfirmButtonBottomInset
        // Sprint 9 Phase A QA 3차 — chip 위치를 산식으로 직접 산출(chip 노드 의존성 0).
        // chip 노드가 아직 생성되지 않은 시점(setupConfirmButton 단계)에서도 안전.
        let chipY = skillChipBaselineY
        let chipBottom = chipY - GameConfig.darkContextChipHeight / 2
        // button top(buttonY + halfHeight) ≤ chipBottom − characterCardConfirmButtonBelowChipV9.
        // 즉, buttonY ≤ chipBottom − 24 − primaryButtonHeight/2.
        let maxAllowedY = chipBottom
            - GameConfig.characterCardConfirmButtonBelowChipV9
            - GameConfig.primaryButtonHeight / 2
        let buttonY = min(baseY, maxAllowedY)
        confirmButton.position = CGPoint(x: frame.midX, y: buttonY)
    }

    /// Sprint 9 Phase A QA 3차 — chip y baseline의 단일 진실 원천(cardBottom anchor).
    /// layoutSkillInfoChip / layoutConfirmButton 양쪽이 이 값을 참조 — 두 식이 갈라질 위험 0.
    /// 산식: cardBottom − characterCardSkillChipBelowCardV9(20) − chipHalfHeight(14).
    /// 이 식 하나로 §4-A-4 #5(cardBottom ↔ chipTop ≥ 16pt)가 *산술적으로 보장*된다 — chipTop = cardBottom − 20.
    private var skillChipBaselineY: CGFloat {
        let cardBottom = cardBaseY(for: .kim) - GameConfig.characterCardHeightV3 / 2
        return cardBottom
            - GameConfig.characterCardSkillChipBelowCardV9
            - GameConfig.darkContextChipHeight / 2
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

    /// Sprint 7+ — confirm 버튼 위쪽 상대 간격(`characterSelectSkillInfoChipAbove`). frame.midY 기반 식은 폐기.
    /// QA 2차 — confirmButton.position.y 직접 참조로 DRY 회복.
    /// **Sprint 9 Phase A QA 3차 (Case B) — 의존성 역전**: chip이 더 이상 confirmButton에 종속되지 않는다.
    ///   chip.y = `skillChipBaselineY` (cardBottom anchor 단일 식). button이 거꾸로 chip을 참조하여 clamp.
    ///   호출 순서가 chip 먼저 → button 나중으로 바뀜(didMove / didChangeSize).
    /// 기존 characterSelectSkillInfoOffsetY(-100), characterSelectSkillInfoChipAboveV9(64)는 값 보존.
    private func layoutSkillInfoChip() {
        guard let chip = skillInfoChip else { return }
        // Sprint 9 Phase A QA 3차 — cardBottom anchor 단일 식. confirmButton 위치에 종속되지 않음.
        chip.position = CGPoint(x: frame.midX, y: skillChipBaselineY)
        // Sprint 7 Phase A — 폭 clamp. 5장 카드 총 폭(160×5 + 22×4 = 888pt)과 시각적 분리.
        // 칩 자체는 라벨 너비 기반 자동 폭이므로 setScale(maxW / currentW)로 축소.
        let maxW = GameConfig.characterSelectSkillInfoMaxWidth
        // setScale 직전에 1.0으로 리셋 — 누적 scale 방지(didChangeSize 반복 시).
        chip.setScale(1.0)
        let currentW = chip.calculateAccumulatedFrame().width
        if currentW > maxW {
            chip.setScale(maxW / currentW)
        }
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

    // MARK: - Setup (Sprint 9 Phase A · Left/Right Arrow Chips)
    /// 카드 좌우 ±260pt 위치에 ‹ / › GlassPill 2개 신규.
    /// zPos 115(카드 110·105·100보다 위). 끝 index에서는 isHidden=true.
    /// touchesBegan에서 hit-test → swipeTo(currentIndex ±1) 분기.
    private func setupArrowChips() {
        let size = CGSize(
            width: GameConfig.characterSelectArrowChipWidthV9,
            height: GameConfig.characterSelectArrowChipHeightV9
        )
        let left = GlassPillNode(text: "‹", size: size)
        left.name = "characterSelectArrowLeft"
        left.zPosition = GameConfig.characterSelectArrowChipZPositionV9
        leftArrowChip = left
        addChild(left)

        let right = GlassPillNode(text: "›", size: size)
        right.name = "characterSelectArrowRight"
        right.zPosition = GameConfig.characterSelectArrowChipZPositionV9
        rightArrowChip = right
        addChild(right)

        layoutArrowChips()
        updateArrowVisibility()
    }

    /// 좌우 화살표 위치 갱신 — 카드 y(cardBaseY)와 같은 높이, 화면 중앙에서 ±260pt.
    private func layoutArrowChips() {
        let offsetX = GameConfig.characterSelectArrowChipOffsetXV9
        // 카드 y와 동일(어느 캐릭터를 넣어도 같은 y). 임의 .kim 기준.
        let y = cardBaseY(for: .kim)
        leftArrowChip?.position = CGPoint(x: frame.midX - offsetX, y: y)
        rightArrowChip?.position = CGPoint(x: frame.midX + offsetX, y: y)
    }

    /// 끝 index 도달 시 해당 방향 화살표 isHidden=true. 그 외는 false.
    /// currentIndex=0 → left isHidden. currentIndex=count-1 → right isHidden.
    private func updateArrowVisibility() {
        leftArrowChip?.isHidden = (currentIndex <= 0)
        rightArrowChip?.isHidden = (currentIndex >= characters.count - 1)
    }

    // MARK: - Card Geometry Helpers (Sprint 8 Phase B · 스와이프 페이지)
    /// 카드 x 좌표 — currentIndex 기준 ±N offset. 중앙(diff=0)은 frame.midX,
    /// 좌측(diff=-1)은 -180, 우측(diff=+1)은 +180. offscreen은 ±360 이상.
    /// 헬퍼로 분리되어 카드/컨테이너/색 점/태그 라벨/얼굴이 모두 같은 좌표를 공유한다.
    /// 기존 동적 spacing/zigzag 식은 폐기 — 스와이프 페이지에서는 *중앙 1장 단일 시선*이 단일 진실 원천.
    /// (characterSelectCardSpacingV3 / characterSelectCardZigzagOffsetV3 등 상수는 값 보존)
    private func cardBaseX(for id: CharacterID) -> CGFloat {
        guard let index = characters.firstIndex(of: id) else { return frame.midX }
        let offset = CGFloat(index - currentIndex) * GameConfig.characterSwipeOffsetXV4
        return frame.midX + offset
    }

    /// 카드 y 좌표 — 모든 카드가 동일한 y. zigzag 폐기.
    /// Sprint 9 Phase A — 비율을 V9(0.40)로 변경. AS-IS: V4(0.50, 화면 정중앙).
    /// 카드 중심이 약 23pt 아래로 내려가 헤더 sub bottom ↔ 카드 top ≥ 24pt 호흡 확보.
    /// V4 상수(0.50)는 값 보존 — 다른 사용처 참조 가능성.
    /// 매개변수 `_`: 모든 카드가 동일 y를 공유하므로 id는 사용하지 않음 — 호출부 시그니처 호환을 위해 인자만 유지.
    private func cardBaseY(for _: CharacterID) -> CGFloat {
        return frame.minY + frame.height * GameConfig.characterCardCenterYV9
    }

    // MARK: - Sprint 8 Phase B · 스와이프 페이지 layout
    /// 5장 카드의 위치/scale/alpha/zPosition을 currentIndex 기준 일괄 산출.
    /// 카드/컨테이너/얼굴 모두 같은 좌표로 동기화 — 안 하면 시각 잔존.
    /// - Parameter animated: true → SKAction 0.22s easeInEaseOut / false → 즉시 적용.
    private func layoutCards(animated: Bool) {
        let duration = GameConfig.characterSwipeAnimationDurationV4
        for (index, id) in characters.enumerated() {
            let diff = index - currentIndex
            let role: CharacterCardPageRole
            switch diff {
            case 0:  role = .center
            case -1: role = .left
            case 1:  role = .right
            default: role = .offscreen
            }
            guard let card = characterCards.first(where: { $0.id == id }) else { continue }
            card.setPageState(role: role, animated: animated, duration: duration)

            let targetPos = CGPoint(x: cardBaseX(for: id), y: cardBaseY(for: id))
            card.removeAction(forKey: "swipeMove")
            if animated {
                let move = SKAction.move(to: targetPos, duration: duration)
                move.timingMode = .easeInEaseOut
                card.run(move, withKey: "swipeMove")
            } else {
                card.position = targetPos
            }
            // 컨테이너 / 얼굴도 같은 좌표로 동기화(시각 잔존 방지).
            cardContainers[id]?.position = targetPos
            // Sprint 9 Phase A — 얼굴 y offset V9(12pt). AS-IS: V4(8pt).
            characterFaces[id]?.position = CGPoint(
                x: targetPos.x,
                y: targetPos.y + GameConfig.characterFaceOffsetYWithinCardV9
            )
            // Sprint 9 Phase A — 둥둥 얼굴 해소: face alpha를 카드 alpha와 동기화.
            // center=1.0 / left,right=0.55(characterSwipeCardAlphaSideV4) / offscreen=0.
            // 얼굴 zPos(105)는 그대로 유지.
            let targetFaceAlpha: CGFloat
            switch role {
            case .center:    targetFaceAlpha = 1.0
            case .left, .right: targetFaceAlpha = GameConfig.characterSwipeCardAlphaSideV4
            case .offscreen: targetFaceAlpha = 0
            }
            if let face = characterFaces[id] {
                face.removeAction(forKey: "faceAlpha")
                if animated {
                    let alphaAct = SKAction.fadeAlpha(to: targetFaceAlpha, duration: duration)
                    alphaAct.timingMode = .easeInEaseOut
                    face.run(alphaAct, withKey: "faceAlpha")
                } else {
                    face.alpha = targetFaceAlpha
                }
            }
            // 색점 / 태그 라벨도 카드 좌표 따라 같이 이동(isHidden=true이지만 회귀 안전).
            cardColorDots[id]?.position = CGPoint(
                x: targetPos.x + GameConfig.characterCardWidthV3 / 2
                    - GameConfig.characterCardColorDotInsetX,
                y: targetPos.y + GameConfig.characterCardHeightV3 / 2
                    - GameConfig.characterCardColorDotInsetY
            )
            tagLabels[id]?.position = CGPoint(
                x: targetPos.x,
                y: targetPos.y + GameConfig.characterSelectTagOffsetY
            )
        }
        // zPosition 적층: center=110 / side(±1)=105 / offscreen=100.
        for card in characterCards {
            guard let index = characters.firstIndex(of: card.id) else { continue }
            let diff = index - currentIndex
            card.zPosition = (diff == 0) ? 110 : (abs(diff) == 1 ? 105 : 100)
        }
        // Sprint 9 Phase A — 끝 index 도달 시 좌/우 화살표 isHidden 갱신.
        updateArrowVisibility()
    }

    /// 스와이프(또는 양옆 카드 탭)로 중앙 카드 변경.
    /// clamp(0...characters.count-1) — 끝에서는 더 이상 안 넘어감.
    /// currentIndex/selectedCharacterID/preferenceRepo 갱신 + layoutCards(animated: true) + 스킬 패널 갱신.
    private func swipeTo(index: Int) {
        let clamped = max(0, min(characters.count - 1, index))
        guard clamped != currentIndex else { return }
        currentIndex = clamped
        let newID = characters[clamped]
        selectedCharacterID = newID
        preferenceRepo.save(newID)
        layoutCards(animated: true)
        rebuildSkillInfoPanel(for: newID)
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

    // MARK: - Touch (Sprint 8 Phase B · 스와이프 페이지)
    /// 우선순위(Sprint 9 Phase A 갱신):
    ///   1) 좌/우 화살표 GlassPill → 해당 방향 스와이프 (양옆 카드 탭보다 먼저, 백/확인보다 먼저).
    ///   2) 양옆(±1) 카드 탭 → 해당 인덱스로 스와이프.
    ///   3) 뒤로 GlassPill.
    ///   4) confirm 버튼.
    /// (중앙 카드/외 영역 무동작 — 스와이프는 touchesMoved)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        swipeStartX = location.x
        didSwipeInCurrentTouch = false

        // 1) Sprint 9 Phase A — 좌/우 화살표 GlassPill 우선 분기. isHidden=true면 hit 제외.
        if let left = leftArrowChip, !left.isHidden, left.contains(location) {
            swipeTo(index: currentIndex - 1)
            return
        }
        if let right = rightArrowChip, !right.isHidden, right.contains(location) {
            swipeTo(index: currentIndex + 1)
            return
        }
        // 2) 양옆(±1) 카드 탭 → 해당 인덱스로 스와이프.
        for (index, id) in characters.enumerated() {
            let diff = index - currentIndex
            guard abs(diff) == 1 else { continue }
            guard let card = characterCards.first(where: { $0.id == id }) else { continue }
            if card.contains(location) {
                swipeTo(index: currentIndex + diff)
                return
            }
        }
        // 3) 뒤로 GlassPill.
        if backPill?.contains(location) == true {
            transitionToStart()
            return
        }
        // 4) confirm 버튼.
        if confirmButton.contains(location) {
            transitionToNext()
        }
    }

    /// 드래그 누적 dx — 40pt 임계 초과 시 currentIndex ±1 스와이프(터치 사이클당 1회).
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning, !didSwipeInCurrentTouch else { return }
        guard let touch = touches.first else { return }
        let dx = touch.location(in: self).x - swipeStartX
        let threshold: CGFloat = 40
        if dx > threshold {
            didSwipeInCurrentTouch = true
            swipeTo(index: currentIndex - 1)
        } else if dx < -threshold {
            didSwipeInCurrentTouch = true
            swipeTo(index: currentIndex + 1)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        didSwipeInCurrentTouch = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        didSwipeInCurrentTouch = false
    }

    /// 뒤로 가기 — StartScene으로.
    private func transitionToStart() {
        guard let view = self.view else { return }
        isTransitioning = true
        let scene = StartScene.newStartScene()
        let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
        view.presentScene(scene, transition: fade)
    }

    /// Sprint 6 — 다음 — .kim은 DifficultySelect 직진(스킬 화면 스킵),
    /// 그 외(스킬 보유 4명)는 SkillExplanation으로.
    private func transitionToNext() {
        guard let view = self.view else { return }
        isTransitioning = true
        let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
        switch selectedCharacterID {
        case .kim:
            // Sprint 6 — 김간호: 스킬 화면 스킵 → 난이도 선택으로.
            let scene = DifficultySelectScene.newDifficultySelectScene(
                characterID: selectedCharacterID
            )
            view.presentScene(scene, transition: fade)
        case .jung, .geon, .im, .lee:
            // 스킬 보유 캐릭터 — SkillExplanationScene으로.
            let scene = SkillExplanationScene.newSkillExplanationScene(
                characterID: selectedCharacterID
            )
            view.presentScene(scene, transition: fade)
        }
    }
}
