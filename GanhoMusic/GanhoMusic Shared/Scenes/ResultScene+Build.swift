//
//  ResultScene+Build.swift
//  GanhoMusic Shared
//
//  R5 — 결과 노드 구성 (didMove 1회, 부착은 +Reveal의 시퀀스 단계가 담당).
//

import SpriteKit

extension ResultScene {
    // MARK: - Build
    func buildRevealNodes() {
        configureCentered(verdictLabel, size: Typography.V3.verdict.size,
                          color: isSuccess ? Palette.mint : Palette.coral)
        verdictLabel.text = isSuccess
            ? UILayout.R5.resultVerdictSuccessText
            : UILayout.R5.resultVerdictFailText
        configureCentered(scoreLabel, size: Typography.V3.hudScore.size, color: Palette.textHi)
        scoreLabel.text = "0"
        buildStars()

        let context = PixelChipNode(
            text: "\(difficulty.shortName)\(UILayout.R5.resultContextChipJoiner)\(characterID.displayName)",
            style: .accent(Palette.difficulty(difficulty))
        )
        context.zPosition = ZOrder.Layer.hud
        contextChip = context
        contentNode.addChild(context)   // 정적 컨텍스트 — 시퀀스 비대상, didMove부터 노출

        comboChip = PixelChipNode(text: "\(UILayout.R5.resultComboChipPrefix)\(maxCombo)",
                                  style: .info)
        notesChip = PixelChipNode(text: "\(UILayout.R5.resultNotesChipPrefix)\(notesCollected)",
                                  style: .info)
        configureCentered(levelLabel, size: Typography.V3.caption.size, color: Palette.textLo)
        let xp = xpSnapshot()
        // 레벨업이면 칭호는 슬라이드인 배지가 담당 — 캡션은 "Lv.{n}"만 (중복 표기 회피).
        levelLabel.text = xp.didLevelUp
            ? "\(UILayout.R5.resultLevelLabelPrefix)\(xp.levelAfter)"
            : "\(UILayout.R5.resultLevelLabelPrefix)\(xp.levelAfter) \(MetaProgression.title(forLevel: xp.levelAfter))"
        xpBar.zPosition = ZOrder.Layer.hud
        buildButtons()
    }

    private func configureCentered(_ label: SKLabelNode, size: CGFloat, color: UIColor) {
        label.fontSize = size
        label.fontColor = color
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = ZOrder.Layer.hud
    }

    private func buildStars() {
        starContainer.zPosition = ZOrder.Layer.hud
        for index in 0..<MetaProgression.maxStarsPerCell {
            let earned = index < earnedStars
            // 미달 별 = 빈 윤곽(textLo ☆) — "몇 개를 놓쳤나" 시각 정보 (좀비 아님).
            let star = SKLabelNode(fontNamed: Typography.V3.display.fontName)
            star.text = earned ? UILayout.R5.starFilledText : UILayout.R5.starEmptyText
            configureCentered(star, size: UILayout.R5.resultStarFontSize,
                              color: earned ? Palette.gold : Palette.textLo)
            star.position = CGPoint(x: (CGFloat(index) - 1) * UILayout.R5.resultStarSpacing, y: 0)
            starContainer.addChild(star)
        }
    }

    private func buildButtons() {
        let retry = PixelButtonNode(title: UILayout.R5.resultRetryButtonText, variant: .primary,
                                    size: UILayout.R4.ctaButtonSize, haptics: haptics)
        retry.onTap = { [weak self] in self?.transitionToRetry() }
        let character = PixelButtonNode(title: UILayout.R5.resultCharacterButtonText,
                                        variant: .secondary,
                                        size: UILayout.R4.secondaryCTAButtonSize, haptics: haptics)
        character.onTap = { [weak self] in self?.transitionToCharacterSelect() }
        let records = PixelButtonNode(title: UILayout.R5.resultRecordsButtonText, variant: .ghost,
                                      size: UILayout.R5.resultGhostButtonSize, haptics: haptics)
        records.onTap = { [weak self] in self?.transitionToScoreboard() }
        [retry, character, records].forEach { $0.zPosition = ZOrder.Layer.hud }
        retryButton = retry
        characterButton = character
        recordsButton = records
    }
}
