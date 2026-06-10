//
//  SkillBriefingScene.swift
//  GanhoMusic Shared
//
//  R4 §F-3 — "작전 브리핑" (03_UI §6-3, 구 SkillExplanationScene 리네임·재구축).
//  좌: PixelCharacterCardNode(캐러셀과 동일 조립) — 등장 시 카드 뒤집힘 0.3s.
//  우: PixelPanelNode — 스킬명(h1 시그니처색) + 인용문(prose + lineHeightMultiplier) + 칩 3개.
//  진입 경로는 CharacterSelect의 [브리핑 보기] 버튼뿐 — 김간호 도달 불가 (.none 방어 처리 유지).
//

import SpriteKit
import UIKit

/// 스킬 브리핑 씬. characterID는 init 불변 입력 — 수정 불가, 뒤로 가서 다시 선택.
final class SkillBriefingScene: BaseMenuScene {

    // MARK: - Properties
    private let characterID: CharacterID
    private var isTransitioning = false
    private var characterCard: PixelCharacterCardNode?
    private var briefingPanel: PixelPanelNode?
    private var backButton: PixelButtonNode?
    private var nextButton: PixelButtonNode?

    /// 패널 내부 콘텐츠 z — PixelPanelNode 내부 적층(섀도 0 < 면 1 < 헤더 2) 위.
    /// ignoresSiblingOrder=true 환경 — 면(z1)과 동급이면 콘텐츠가 면 뒤에 묻힌다 (PixelDialogNode 동형).
    private enum PanelInnerZ {
        static let content: CGFloat = 3
    }

    private static let flipActionKey = "r4CardFlipIn"

    // MARK: - Factory
    /// CharacterSelectScene이 유일 호출자 (§C-9 — 브리핑은 선택 사항).
    class func newSkillBriefingScene(characterID: CharacterID) -> SkillBriefingScene {
        let scene = SkillBriefingScene(
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

    @available(*, unavailable, message: "Use newSkillBriefingScene(characterID:) instead.")
    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        setupNightShiftBackdrop()
        setupCharacterCard()
        setupBriefingPanel()
        setupButtons()
        layoutScene()
        runStaggeredAppear([briefingPanel, backButton, nextButton].compactMap { $0 })
        runCardFlipIn()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard characterCard != nil else { return }   // didMove 이전 호출 가드
        cancelStaggeredAppear()
        rebuildNightShiftBackdrop()
        layoutScene()
    }

    // MARK: - Left Card (§F-3 — 캐러셀과 동일 조립 + 뒤집힘 등장)
    private func setupCharacterCard() {
        // 본 씬 도달 = 해금 캐릭터 (CharacterSelect가 잠금 차단) — unlocked 상태로 조립.
        let card = PixelCharacterCardNode(
            characterID: characterID,
            portraitTexture: PixelPortraitSprite.texture(for: characterID),
            unlockState: .unlocked(characterID)
        )
        card.setSelected(true, animated: false)   // 시그니처 액센트 보더 + 글로우
        card.zPosition = ZOrder.Layer.characters
        characterCard = card
        addChild(card)
    }

    /// 카드 뒤집힘 — xScale 0→1, 0.3s (FeelTuning.R4.cardFlipIn — §6-3).
    private func runCardFlipIn() {
        guard let card = characterCard else { return }
        let targetXScale = card.xScale   // setSelected(1.04) 반영값 보존
        card.xScale = 0
        let flip = Tween.curved(
            SKAction.scaleX(to: targetXScale, duration: FeelTuning.R4.cardFlipIn),
            .easeOutCubic
        )
        card.run(flip, withKey: Self.flipActionKey)
    }

    // MARK: - Right Panel (§F-3 — 스킬명 + 인용문 + 칩 3개)
    private func setupBriefingPanel() {
        let signature = Palette.character(characterID)
        let panel = PixelPanelNode(size: UILayout.R4.briefingPanelSize,
                                   title: UILayout.R4.briefingPanelTitleText,
                                   accent: signature)
        panel.zPosition = ZOrder.Layer.hud
        briefingPanel = panel
        addChild(panel)

        // 스킬명 (h1, 시그니처색). 김간호 도달 불가 — .none이면 "—" (방어적 graceful).
        let skillName = SKLabelNode(fontNamed: Typography.V3.h1.fontName)
        skillName.text = characterID.skill.displayName
        skillName.fontSize = Typography.V3.h1.size
        skillName.fontColor = signature
        skillName.horizontalAlignmentMode = .center
        skillName.verticalAlignmentMode = .center
        skillName.position = CGPoint(x: 0, y: UILayout.R4.briefingSkillNameOffsetY)
        skillName.zPosition = PanelInnerZ.content
        panel.addChild(skillName)

        let quoteBlock = makeQuoteBlock(signature: signature)
        quoteBlock.zPosition = PanelInnerZ.content
        panel.addChild(quoteBlock)
        layoutChips(in: panel)
    }

    /// 인용문 블록 — 좌측 3px 액센트 바 + prose 줄간 1.45 (P2 ② lineHeightMultiplier 실사용 배선).
    private func makeQuoteBlock(signature: UIColor) -> SKNode {
        let block = SKNode()
        block.position = CGPoint(x: 0, y: UILayout.R4.briefingQuoteOffsetY)

        let quote = SKLabelNode()
        quote.attributedText = Self.quoteAttributedText(
            characterID.skill.fullDescription
        )
        quote.numberOfLines = 0
        quote.preferredMaxLayoutWidth = UILayout.R4.briefingQuoteMaxWidth
        quote.horizontalAlignmentMode = .left
        quote.verticalAlignmentMode = .center
        quote.position = CGPoint(
            x: -UILayout.R4.briefingQuoteMaxWidth / 2 + UILayout.Space.s12,
            y: 0
        )
        block.addChild(quote)

        // 좌측 3px 액센트 바 — 인용문 실측 높이에 맞춤 (§6-3 수치).
        let quoteHeight = max(quote.frame.height, UILayout.Space.s24)
        let bar = SKSpriteNode(
            color: signature,
            size: CGSize(width: UILayout.R4.briefingQuoteBarWidth, height: quoteHeight)
        )
        bar.position = CGPoint(
            x: -UILayout.R4.briefingQuoteMaxWidth / 2
                - UILayout.R4.briefingQuoteBarWidth,
            y: 0
        )
        block.addChild(bar)
        return block
    }

    /// prose 토큰 + NSAttributedString 줄간 — SKLabelNode.attributedText는 폰트·색 attribute 필수
    /// (fontNamed 무시 — 주의사항 4). GowunDodum은 번들 보장 폰트 — 시스템 폰트 폴백은 컴파일 안전망.
    private static func quoteAttributedText(_ text: String) -> NSAttributedString {
        let prose = Typography.V3.prose
        let font = UIFont(name: prose.fontName, size: prose.size)
            ?? UIFont(name: Typography.V3.body.fontName, size: prose.size)
            ?? UIFont.systemFont(ofSize: prose.size)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = Typography.V3.lineHeightMultiplier
        return NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: Palette.textHi,
                .paragraphStyle: paragraph
            ]
        )
    }

    /// 칩 3개 — 쿨다운(oncePerGame→"1회" 분기 보존) / 범위(rangeText) / 발동(castText).
    private func layoutChips(in panel: PixelPanelNode) {
        let skill = characterID.skill
        let cdText: String
        if skill.oncePerGame {
            cdText = UILayout.R4.briefingOnceText
        } else if skill == .none {
            cdText = UILayout.R4.briefingNoneText
        } else {
            let seconds = Int(skill.cooldown.rounded())
            cdText = "\(seconds)\(UILayout.R4.briefingSecondsSuffix)"
        }
        let chips = [
            PixelChipNode(text: "\(UILayout.R4.briefingChipCDPrefix)\(cdText)", style: .info),
            PixelChipNode(text: "\(UILayout.R4.briefingChipRangePrefix)\(skill.rangeText)",
                          style: .info),
            PixelChipNode(text: "\(UILayout.R4.briefingChipCastPrefix)\(skill.castText)",
                          style: .info)
        ]
        let widths = chips.map { $0.chipSize.width }
        let total = widths.reduce(0, +)
            + UILayout.R4.briefingChipGap * CGFloat(chips.count - 1)
        var cursorX = -total / 2
        for (index, chip) in chips.enumerated() {
            chip.position = CGPoint(
                x: (cursorX + widths[index] / 2).rounded(),
                y: UILayout.R4.briefingChipRowOffsetY
            )
            chip.zPosition = PanelInnerZ.content
            cursorX += widths[index] + UILayout.R4.briefingChipGap
            panel.addChild(chip)
        }
    }

    // MARK: - Buttons (§F-3 — 뒤로 ghost / 난이도 선택 primary)
    private func setupButtons() {
        let back = PixelButtonNode(title: UILayout.R4.selectBackButtonText,
                                   variant: .ghost,
                                   size: UILayout.R4.backButtonSize)
        back.onTap = { [weak self] in self?.transitionToCharacterSelect() }
        back.zPosition = ZOrder.Layer.hud
        backButton = back
        addChild(back)

        let next = PixelButtonNode(title: UILayout.R4.briefingNextButtonText,
                                   variant: .primary,
                                   size: UILayout.R4.ctaButtonSize)
        next.onTap = { [weak self] in self?.transitionToDifficulty() }
        next.zPosition = ZOrder.Layer.hud
        nextButton = next
        addChild(next)
    }

    // MARK: - Layout
    private func layoutScene() {
        let safe = menuSafeInsets()
        let scale = menuCompactScale()
        let contentY = (frame.midY + UILayout.R4.briefingContentCenterYOffset * scale).rounded()

        characterCard?.setScale(scale)
        characterCard?.position = CGPoint(
            x: (frame.minX + frame.width * UILayout.R4.briefingCardCenterXRatio).rounded(),
            y: contentY
        )

        briefingPanel?.setScale(scale)
        briefingPanel?.position = CGPoint(
            x: (frame.minX + frame.width * UILayout.R4.briefingPanelCenterXRatio).rounded(),
            y: contentY
        )

        backButton?.setScale(scale)
        backButton?.position = CGPoint(
            x: (frame.minX + safe.left + UILayout.v3ScreenEdgeInset
                + UILayout.R4.backButtonSize.width * scale / 2).rounded(),
            y: (frame.maxY - safe.top - UILayout.v3ScreenEdgeInset
                - UILayout.R4.backButtonSize.height * scale / 2).rounded()
        )

        nextButton?.setScale(scale)
        nextButton?.position = CGPoint(
            x: (frame.minX + frame.width * UILayout.R4.briefingPanelCenterXRatio).rounded(),
            y: (frame.minY + safe.bottom + UILayout.R4.ctaBottomInset * scale).rounded()
        )
    }

    // MARK: - Transition
    private func transitionToCharacterSelect() {
        guard !isTransitioning, let view = self.view else { return }
        isTransitioning = true
        let scene = CharacterSelectScene.newCharacterSelectScene()
        SceneRouter.present(scene, on: view, route: .backward)
    }

    private func transitionToDifficulty() {
        guard let view = self.view else { return }
        guard !isTransitioning else { return }
        isTransitioning = true
        let scene = DifficultySelectScene.newDifficultySelectScene(
            characterID: characterID
        )
        SceneRouter.present(scene, on: view, route: .forward)
    }
}
