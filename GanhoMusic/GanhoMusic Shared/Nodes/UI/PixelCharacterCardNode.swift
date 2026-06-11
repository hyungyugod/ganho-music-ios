//
//  PixelCharacterCardNode.swift
//  GanhoMusic Shared
//
//  R4 §D — 캐릭터 카드 조립 공용 컴포넌트 (03_UI §6-2·§6-3).
//  R8 P0-2 — 24×24 픽셀 포트레이트 → 카툰 일러스트 5종(96×144 자산) 교체 + 조화 이펙트
//  (시그니처 백드롭·선택 시 idle 부유). PixelCardNode 베이스 + 일러스트 + 이름 + 스킬/잠금 칩.
//  CharacterSelect 캐러셀과 SkillBriefing 좌측 카드가 *공유* (중복 0 — SPEC §D).
//  터치 판정은 호출측(씬) 책임 — PixelCardNode 컨벤션 동형.
//

import SpriteKit
import UIKit

/// v3 캐릭터 카드. 일러스트 텍스처는 호출측이 didMove 1회 생성해 주입 (재생성 금지 — 주의사항 5).
final class PixelCharacterCardNode: SKNode {

    /// 카드가 표현하는 캐릭터 (캐러셀 탭 판정용).
    let characterID: CharacterID
    /// 카드 면 크기 (배치 계산용).
    var cardSize: CGSize { card.cardSize }

    private let card: PixelCardNode
    /// R8 — 일러스트 스프라이트 (부유 모션 시작/정지 대상). 잠금 카드도 실루엣으로 보유.
    private let illustration: SKSpriteNode
    /// R8 — 부유 적용 가능 여부 (해금 카드만). 잠금 카드는 setSelected에서도 부유 미적용.
    private let isUnlocked: Bool

    /// contentNode 내부 적층 — 백드롭(0) < 일러스트(1) < 이름/칩(2).
    /// ignoresSiblingOrder=true 환경 — 동일 z 의존 금지, 전부 명시 분리 (PixelDialogNode 동형).
    private enum ContentZ {
        static let backdrop: CGFloat = 0
        static let illustration: CGFloat = 1
        static let text: CGFloat = 2
    }

    // MARK: - Illustration Loader (R8)
    /// 선택 카드 일러스트. UIImage 경유 존재 검증 + 부재 시 픽셀 포트레이트 폴백 (강제 언래핑 0).
    /// filteringMode = .linear 명시 — 벡터풍 일러스트는 smooth, 픽셀 자산(.nearest)과 명시 구분
    /// (주의사항 3: .nearest를 걸면 일러스트가 계단화).
    static func illustrationTexture(for id: CharacterID) -> SKTexture {
        let name = "\(id.rawValue)\(UILayout.R8.characterIllustrationSuffix)"
        guard let image = UIImage(named: name) else {
            return PixelPortraitSprite.texture(for: id)   // graceful 폴백 (24×24 픽셀)
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    // MARK: - Init
    /// - Parameters:
    ///   - characterID: 캐릭터.
    ///   - illustrationTexture: 카툰 일러스트 (illustrationTexture(for:) — 호출측 1회 생성).
    ///   - unlockState: 잠금 상태 — 잠금 시 실루엣(ink600 colorBlend) + 잠금 칩(requirementText).
    init(characterID: CharacterID,
         illustrationTexture: SKTexture,
         unlockState: CharacterUnlockState) {
        self.characterID = characterID
        card = PixelCardNode(size: UILayout.R4.characterCardSize,
                             accent: Palette.character(characterID))
        illustration = SKSpriteNode(texture: illustrationTexture)
        isUnlocked = unlockState.isUnlocked
        super.init()
        addChild(card)

        // R8 — 시그니처 백드롭 (해금 카드 한정). 시그니처색 단색 1장 — 상시 정체성 표현.
        // 선택 글로우(PixelCardNode 보더+1.4배 글로우)와 역할 분리: 상시 정체성 vs 선택 강조.
        if isUnlocked {
            let backdrop = SKSpriteNode(color: Palette.character(characterID),
                                        size: UILayout.R8.cardIllustrationBackdropSize)
            backdrop.alpha = FeelTuning.R8.cardIllustrationBackdropAlpha
            backdrop.position = CGPoint(x: 0, y: UILayout.R8.cardIllustrationBackdropOffsetY)
            backdrop.zPosition = ContentZ.backdrop
            card.contentNode.addChild(backdrop)
        }

        // 일러스트 — 96×144 자산을 2:3 비율 유지 축소(72×108).
        illustration.size = UILayout.R8.cardIllustrationSize
        illustration.position = CGPoint(x: 0, y: UILayout.R8.cardIllustrationOffsetY)
        illustration.zPosition = ContentZ.illustration
        if !isUnlocked {
            // 잠금 실루엣 — ink600 단색 처리 (§F-2 유지, 일러스트 alpha 윤곽 실루엣).
            // 잠금 카드는 백드롭 미부착·부유 미적용 — 잠금 시각 언어 명료 유지.
            illustration.color = Palette.ink600
            illustration.colorBlendFactor = 1.0
        }
        card.contentNode.addChild(illustration)

        // 이름 (h2) — 잠금 시 textLo.
        let name = SKLabelNode(fontNamed: Typography.V3.h2.fontName)
        name.text = characterID.displayName
        name.fontSize = Typography.V3.h2.size
        name.fontColor = isUnlocked ? Palette.textHi : Palette.textLo
        name.horizontalAlignmentMode = .center
        name.verticalAlignmentMode = .center
        name.position = CGPoint(x: 0, y: UILayout.R4.cardNameOffsetY)
        name.zPosition = ContentZ.text
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
        chip.zPosition = ContentZ.text
        card.contentNode.addChild(chip)
    }

    @available(*, unavailable, message: "Use init(characterID:illustrationTexture:unlockState:) instead.")
    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Selection (PixelCardNode 위임 — 액센트 보더 + 글로우 + scale 1.04)
    /// R8 — 선택+해금 카드의 일러스트만 idle 부유 시작, 해제 시 정지+원위치 (잔여 오프셋 0).
    /// SkillBriefing 카드는 setSelected(true) 경로로 자동 부유.
    func setSelected(_ selected: Bool, animated: Bool) {
        card.setSelected(selected, animated: animated)
        if selected && isUnlocked {
            startIllustrationFloat()
        } else {
            stopIllustrationFloat()
        }
    }

    // MARK: - Idle Float (R8 — SKAction만, Timer/asyncAfter 금지)
    private func startIllustrationFloat() {
        guard illustration.action(forKey: FeelTuning.R8.cardIllustrationFloatActionKey) == nil
        else { return }   // withKey 멱등 + 진행 중 재시작 방지 (위상 점프 0)
        let half = FeelTuning.R8.cardIllustrationFloatHalfPeriod
        let up = SKAction.moveBy(x: 0, y: FeelTuning.R8.cardIllustrationFloatDistance,
                                 duration: half)
        up.timingMode = .easeInEaseOut
        let down = SKAction.moveBy(x: 0, y: -FeelTuning.R8.cardIllustrationFloatDistance,
                                   duration: half)
        down.timingMode = .easeInEaseOut
        illustration.run(.repeatForever(.sequence([up, down])),
                         withKey: FeelTuning.R8.cardIllustrationFloatActionKey)
    }

    private func stopIllustrationFloat() {
        illustration.removeAction(forKey: FeelTuning.R8.cardIllustrationFloatActionKey)
        // 원위치 직접 복귀 — 반주기 도중 정지의 잔여 오프셋 0.
        illustration.position = CGPoint(x: 0, y: UILayout.R8.cardIllustrationOffsetY)
    }
}
