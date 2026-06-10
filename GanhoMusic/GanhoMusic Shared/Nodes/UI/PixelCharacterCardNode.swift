//
//  PixelCharacterCardNode.swift
//  GanhoMusic Shared
//
//  R4 §D — 캐릭터 카드 조립 공용 컴포넌트 (03_UI §6-2·§6-3).
//  PixelCardNode 베이스 + 24×24 포트레이트 + 이름 + 스킬/잠금 칩.
//  CharacterSelect 캐러셀과 SkillBriefing 좌측 카드가 *공유* (중복 0 — SPEC §D).
//  터치 판정은 호출측(씬) 책임 — PixelCardNode 컨벤션 동형.
//

import SpriteKit
import UIKit

/// v3 캐릭터 카드. 포트레이트 텍스처는 호출측이 didMove 1회 생성해 주입 (재생성 금지 — 주의사항 5).
final class PixelCharacterCardNode: SKNode {

    /// 카드가 표현하는 캐릭터 (캐러셀 탭 판정용).
    let characterID: CharacterID
    /// 카드 면 크기 (배치 계산용).
    var cardSize: CGSize { card.cardSize }

    private let card: PixelCardNode

    // MARK: - Init
    /// - Parameters:
    ///   - characterID: 캐릭터.
    ///   - portraitTexture: 24×24 포트레이트 (PixelPortraitSprite.texture(for:) — 호출측 1회 생성).
    ///   - unlockState: 잠금 상태 — 잠금 시 실루엣(ink600 colorBlend) + 잠금 칩(requirementText).
    init(characterID: CharacterID,
         portraitTexture: SKTexture,
         unlockState: CharacterUnlockState) {
        self.characterID = characterID
        card = PixelCardNode(size: UILayout.R4.characterCardSize,
                             accent: Palette.character(characterID))
        super.init()
        addChild(card)

        let isUnlocked = unlockState.isUnlocked

        // 포트레이트 — 24×24 → 72pt (정수 ×3 배율, .nearest 픽셀 보존).
        let portrait = SKSpriteNode(texture: portraitTexture)
        portrait.size = CGSize(width: UILayout.R4.cardPortraitSide,
                               height: UILayout.R4.cardPortraitSide)
        portrait.position = CGPoint(x: 0, y: UILayout.R4.cardPortraitOffsetY)
        if !isUnlocked {
            // 잠금 실루엣 — ink600 단색 처리 (§F-2, colorBlend).
            portrait.color = Palette.ink600
            portrait.colorBlendFactor = 1.0
        }
        card.contentNode.addChild(portrait)

        // 이름 (h2) — 잠금 시 textLo.
        let name = SKLabelNode(fontNamed: Typography.V3.h2.fontName)
        name.text = characterID.displayName
        name.fontSize = Typography.V3.h2.size
        name.fontColor = isUnlocked ? Palette.textHi : Palette.textLo
        name.horizontalAlignmentMode = .center
        name.verticalAlignmentMode = .center
        name.position = CGPoint(x: 0, y: UILayout.R4.cardNameOffsetY)
        card.contentNode.addChild(name)

        // 칩 — 해금: 스킬명(김간호는 "정공법") / 잠금: 해금 조건.
        let chip: PixelChipNode
        if isUnlocked {
            let skillText = characterID.skill == .none
                ? UILayout.R4.cardNoSkillChipText
                : characterID.skill.displayName
            chip = PixelChipNode(text: skillText, style: .info)
        } else {
            chip = PixelChipNode(text: unlockState.requirementText, style: .locked)
        }
        chip.position = CGPoint(x: 0, y: UILayout.R4.cardChipOffsetY)
        card.contentNode.addChild(chip)
    }

    @available(*, unavailable, message: "Use init(characterID:portraitTexture:unlockState:) instead.")
    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Selection (PixelCardNode 위임 — 액센트 보더 + 글로우 + scale 1.04)
    func setSelected(_ selected: Bool, animated: Bool) {
        card.setSelected(selected, animated: animated)
    }
}
