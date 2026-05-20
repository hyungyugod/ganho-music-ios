//
//  CharacterCardNode.swift
//  GanhoMusic Shared
//
//  Phase 5-1 · 캐릭터 선택 카드 — 색 사각형 + 이름 라벨 + 선택 알파 토글
//  Phase 5-5 · 카드 선택 시 scale 강조 (SKAction.scale 0.10s 보간)
//  Phase 8-3 · 시각 토큰 원본화 — ganhoUIBgCard 배경 + border SKShapeNode + brand 강조
//  Sprint 7 Phase A · NIKKE 4:5 카드 — 카드 폭/높이 v3(160×200) + 5요소 흡수
//                     (속성 헥사·등급 배지·CD 미니칩·이름·속도) + 선택 시 코랄 글로우 + "선택됨" 알약
//

import SpriteKit

/// 캐릭터 선택 카드. PhysicsBody 0 — 순수 시각 + hit test 대상.
/// Sprint 7 Phase A — NIKKE 식 세로 4:5 카드. 카드 내부에 5요소를 위계 있게 배치.
///
/// 카드 자식 zPos 순서:
///   selectedGlow(-1) < background(0) < border(1) < 헥사/배지/칩/이름/속도(5~6) < 알약(10~11)
///
/// 외부 시그니처 byte-identical: `init(id:)`, `setSelected(_:)`, `let id: CharacterID`.
final class CharacterCardNode: SKNode {

    // MARK: - Properties
    let id: CharacterID
    private let background: SKSpriteNode
    private let border: SKShapeNode

    // Phase 8-3 — 이름 라벨(카드 하단 내부로 흡수).
    private let nameLabel: SKLabelNode

    // Sprint 7 Phase A — NIKKE 5요소 추가
    /// 속도 라벨 — 카드 하단 이름 아래(Gowun Dodum 10pt scrubMint).
    private let speedLabel: SKLabelNode
    /// 좌상단 속성 헥사 SKShapeNode.
    private let elementHex: SKShapeNode
    /// 헥사 안 이모지 라벨.
    private let elementSymbolLabel: SKLabelNode
    /// 좌하단 등급 로마숫자 배지 SKShapeNode.
    private let rarityBadge: SKShapeNode
    /// 배지 안 로마숫자(I/II/III) 라벨.
    private let rarityLabel: SKLabelNode
    /// 우상단 CD 미니칩 SKShapeNode.
    private let cdChip: SKShapeNode
    /// CD 칩 안 라벨("1회"/"∞").
    private let cdLabel: SKLabelNode
    /// 선택 시 하단 코랄 radial glow(타원).
    private let selectedGlow: SKShapeNode
    /// 선택 시 상단 "선택됨" 코랄 알약.
    private let selectedPill: SKShapeNode
    /// 알약 안 텍스트 라벨.
    private let selectedPillLabel: SKLabelNode

    // MARK: - Init
    init(id: CharacterID) {
        self.id = id
        let cardSize = CGSize(
            width: GameConfig.characterCardWidthV3,
            height: GameConfig.characterCardHeightV3
        )
        // 반투명 화이트 카드 배경(ganhoUIBgCard 톤은 다크 — v3는 흰 톤이지만 setSelected에서 교체).
        background = SKSpriteNode(color: .ganhoUIBgCard, size: cardSize)
        // v3 cornerRadius 22 — NIKKE 식 둥근 사각.
        border = SKShapeNode(
            rectOf: cardSize,
            cornerRadius: GameConfig.characterCardCornerRadiusV3
        )
        nameLabel = SKLabelNode(text: id.displayName)

        // Phase A 인스턴스 빈 초기화 — 본문에서 path/text/position 설정.
        speedLabel = SKLabelNode()
        elementHex = SKShapeNode()
        elementSymbolLabel = SKLabelNode()
        rarityBadge = SKShapeNode()
        rarityLabel = SKLabelNode()
        cdChip = SKShapeNode()
        cdLabel = SKLabelNode()
        selectedGlow = SKShapeNode()
        selectedPill = SKShapeNode()
        selectedPillLabel = SKLabelNode()

        super.init()
        name = "characterCard_\(id.rawValue)"
        zPosition = 100

        // 배경 + 보더(zPos 0/1).
        background.position = .zero
        background.zPosition = 0
        border.fillColor = .clear
        border.strokeColor = .ganhoUIBorder
        border.lineWidth = GameConfig.uiPanelLineWidth
        border.position = .zero
        border.zPosition = 1
        addChild(background)
        addChild(border)

        // Phase A 5요소 부착.
        attachElementBadge()
        attachRarityBadge()
        attachCDChip()
        attachNameAndSpeed()
        attachSelectedDecor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Phase A · 좌상단 속성 헥사 아이콘
    /// 6각형 path(꼭짓점이 위) + 흰색 stroke + 캐릭터별 dotColor fill.
    /// 안에 이모지(⚡/💧/🌿/🌙/🌸)를 16pt로 배치.
    private func attachElementBadge() {
        // 6각형 path — outer radius 14, 시작 각도 .pi/2 (꼭짓점이 위).
        let r = GameConfig.characterCardElementHexRadius
        let path = CGMutablePath()
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 + .pi / 2
            let x = r * cos(angle)
            let y = r * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        elementHex.path = path
        elementHex.fillColor = id.dotColor
        elementHex.strokeColor = .white
        elementHex.lineWidth = GameConfig.characterCardElementHexStrokeWidth

        let halfW = GameConfig.characterCardWidthV3 / 2
        let halfH = GameConfig.characterCardHeightV3 / 2
        elementHex.position = CGPoint(
            x: -halfW + GameConfig.characterCardElementHexInsetX,
            y:  halfH - GameConfig.characterCardElementHexInsetY
        )
        elementHex.zPosition = 5
        addChild(elementHex)

        elementSymbolLabel.text = id.elementSymbol
        elementSymbolLabel.fontName = GameConfig.fontDisplay
        elementSymbolLabel.fontSize = GameConfig.characterCardElementSymbolFontSize
        elementSymbolLabel.horizontalAlignmentMode = .center
        elementSymbolLabel.verticalAlignmentMode = .center
        elementSymbolLabel.position = elementHex.position
        elementSymbolLabel.zPosition = 6
        addChild(elementSymbolLabel)
    }

    // MARK: - Phase A · 좌하단 등급 로마숫자 배지
    /// navyDeep × 0.85 fill + 골드 로마숫자(I/II/III).
    private func attachRarityBadge() {
        let badgeSize = CGSize(
            width: GameConfig.characterCardRarityBadgeWidth,
            height: GameConfig.characterCardRarityBadgeHeight
        )
        rarityBadge.path = CGPath(
            roundedRect: CGRect(
                x: -badgeSize.width / 2,
                y: -badgeSize.height / 2,
                width: badgeSize.width,
                height: badgeSize.height
            ),
            cornerWidth: GameConfig.characterCardRarityBadgeCornerRadius,
            cornerHeight: GameConfig.characterCardRarityBadgeCornerRadius,
            transform: nil
        )
        rarityBadge.fillColor = UIColor.ganhoNavyDeep
            .withAlphaComponent(GameConfig.characterCardRarityBadgeFillAlpha)
        rarityBadge.strokeColor = .clear
        rarityBadge.lineWidth = 0

        let halfW = GameConfig.characterCardWidthV3 / 2
        let halfH = GameConfig.characterCardHeightV3 / 2
        rarityBadge.position = CGPoint(
            x: -halfW + GameConfig.characterCardRarityBadgeInsetX,
            y: -halfH + GameConfig.characterCardRarityBadgeInsetY
        )
        rarityBadge.zPosition = 5
        addChild(rarityBadge)

        let roman: String
        switch id.rarity {
        case 1: roman = "I"
        case 2: roman = "II"
        case 3: roman = "III"
        default: roman = "I"  // 안전 fallback (현재 값은 1·2·3만, Int 전체 case 망라 불가)
        }
        rarityLabel.text = roman
        rarityLabel.fontName = GameConfig.fontDisplay
        rarityLabel.fontSize = GameConfig.characterCardRarityBadgeFontSize
        rarityLabel.fontColor = .ganhoMusicGold
        rarityLabel.horizontalAlignmentMode = .center
        rarityLabel.verticalAlignmentMode = .center
        rarityLabel.position = rarityBadge.position
        rarityLabel.zPosition = 6
        addChild(rarityLabel)
    }

    // MARK: - Phase A · 우상단 CD 미니칩
    /// coralLight × 0.85 fill + 흰색 "1회"/"∞" 라벨. 자동 폭(라벨 너비 + padding).
    private func attachCDChip() {
        cdLabel.text = id.skill.cooldownText
        cdLabel.fontName = GameConfig.fontDisplay
        cdLabel.fontSize = GameConfig.characterCardCDChipFontSize
        cdLabel.fontColor = .white
        cdLabel.horizontalAlignmentMode = .center
        cdLabel.verticalAlignmentMode = .center

        // 라벨 너비 + padding으로 자동 폭 계산.
        let labelW = cdLabel.frame.width
        let chipW = labelW + GameConfig.characterCardCDChipHorizontalPadding * 2
        let chipH = GameConfig.characterCardCDChipHeight
        cdChip.path = CGPath(
            roundedRect: CGRect(
                x: -chipW / 2,
                y: -chipH / 2,
                width: chipW,
                height: chipH
            ),
            cornerWidth: chipH / 2,
            cornerHeight: chipH / 2,
            transform: nil
        )
        cdChip.fillColor = UIColor.ganhoCoralLight
            .withAlphaComponent(GameConfig.characterCardCDChipFillAlpha)
        cdChip.strokeColor = .clear
        cdChip.lineWidth = 0

        let halfW = GameConfig.characterCardWidthV3 / 2
        let halfH = GameConfig.characterCardHeightV3 / 2
        cdChip.position = CGPoint(
            x: halfW - GameConfig.characterCardCDChipInsetX - chipW / 2,
            y: halfH - GameConfig.characterCardCDChipInsetY
        )
        cdChip.zPosition = 5
        addChild(cdChip)

        cdLabel.position = cdChip.position
        cdLabel.zPosition = 6
        addChild(cdLabel)
    }

    // MARK: - Phase A · 카드 하단 이름 + 속도
    /// Jua 15pt navyDeep "김간호" + Gowun Dodum 10pt scrubMint "⚡ ×1.00".
    private func attachNameAndSpeed() {
        configureNameLabel()
        addChild(nameLabel)

        speedLabel.text = "⚡ ×\(formattedSpeed(id.playerSpeedMultiplier))"
        speedLabel.fontName = GameConfig.fontBody
        speedLabel.fontSize = GameConfig.characterCardSpeedFontSizeV3
        speedLabel.fontColor = .ganhoScrubMint
        speedLabel.horizontalAlignmentMode = .center
        speedLabel.verticalAlignmentMode = .center
        let halfH = GameConfig.characterCardHeightV3 / 2
        speedLabel.position = CGPoint(
            x: 0,
            y: -halfH + GameConfig.characterCardSpeedOffsetYV3
        )
        speedLabel.zPosition = 5
        addChild(speedLabel)
    }

    // MARK: - Phase A · 선택 데코(글로우 + 알약, 기본 isHidden)
    /// 하단 코랄 radial glow + 상단 "선택됨" 알약. 기본 isHidden — setSelected에서 토글.
    /// Sprint 9 Phase A — 카드 *외부* 부착 → 카드 *내부* inset으로 재배치.
    ///   · 알약: halfH + 14 (외부 상단) → halfH - 16 (내부 상단 inset)
    ///   · 글로우: -halfH + (-12) (외부 하단) → -halfH + 22 (내부 하단 inset)
    ///   · 글로우 크기: 224×60 → 152×36 (카드 폭 - 8 / 카드 외부 침범 0)
    /// 인스턴스(selectedGlow / selectedPill / selectedPillLabel)는 *재사용* — path/position만 V9로 교체.
    private func attachSelectedDecor() {
        // 하단 코랄 radial glow (타원). Sprint 9 Phase A — 카드 내부 하단 inset + 폭 축소.
        let glowSize = CGSize(
            width: GameConfig.characterCardSelectedGlowWidthV9,
            height: GameConfig.characterCardSelectedGlowHeightV9
        )
        selectedGlow.path = CGPath(
            ellipseIn: CGRect(
                x: -glowSize.width / 2,
                y: -glowSize.height / 2,
                width: glowSize.width,
                height: glowSize.height
            ),
            transform: nil
        )
        selectedGlow.fillColor = UIColor.ganhoCoralPrimary
            .withAlphaComponent(GameConfig.characterCardSelectedGlowAlpha)
        selectedGlow.strokeColor = .clear
        selectedGlow.lineWidth = 0
        let halfH = GameConfig.characterCardHeightV3 / 2
        // Sprint 9 Phase A — 카드 내부 하단 inset(22pt 안쪽). AS-IS: -halfH + (-12) (외부).
        selectedGlow.position = CGPoint(
            x: 0,
            y: -halfH + GameConfig.characterCardSelectedGlowInsetBottomV9
        )
        // background(zPos 0) 뒤로 — 카드 내부에서 잔잔하게 비치는 느낌.
        selectedGlow.zPosition = -1
        selectedGlow.isHidden = true
        addChild(selectedGlow)

        // 상단 "선택됨" 코랄 알약.
        let pillSize = CGSize(
            width: GameConfig.characterCardSelectedPillWidth,
            height: GameConfig.characterCardSelectedPillHeight
        )
        selectedPill.path = CGPath(
            roundedRect: CGRect(
                x: -pillSize.width / 2,
                y: -pillSize.height / 2,
                width: pillSize.width,
                height: pillSize.height
            ),
            cornerWidth: pillSize.height / 2,
            cornerHeight: pillSize.height / 2,
            transform: nil
        )
        selectedPill.fillColor = .ganhoCoralPrimary
        selectedPill.strokeColor = .clear
        selectedPill.lineWidth = 0
        // Sprint 9 Phase A — 카드 내부 상단 inset(16pt 안쪽). AS-IS: halfH + 14 (외부).
        selectedPill.position = CGPoint(
            x: 0,
            y: halfH - GameConfig.characterCardSelectedPillInsetTopV9
        )
        selectedPill.zPosition = 10
        selectedPill.isHidden = true
        addChild(selectedPill)

        selectedPillLabel.text = GameConfig.characterCardSelectedPillText
        selectedPillLabel.fontName = GameConfig.fontDisplay
        selectedPillLabel.fontSize = GameConfig.characterCardSelectedPillFontSize
        selectedPillLabel.fontColor = .white
        selectedPillLabel.horizontalAlignmentMode = .center
        selectedPillLabel.verticalAlignmentMode = .center
        // 라벨은 알약과 동일 좌표 — 알약 V9 inset에 자동 추적.
        selectedPillLabel.position = selectedPill.position
        selectedPillLabel.zPosition = 11
        selectedPillLabel.isHidden = true
        addChild(selectedPillLabel)
    }

    // MARK: - Selection
    /// 선택 상태 시각 토글. 시그니처 byte-identical.
    /// true → alpha 1.0 + scale 1.08(액션 0.10s) + background/border/nameLabel 토큰 교체
    ///        + 글로우/알약 표시.
    /// false → alpha 0.5 + scale 1.0 + 기본 토큰 + 글로우/알약 숨김.
    func setSelected(_ selected: Bool) {
        alpha = selected ? 1.0 : GameConfig.characterCardDeselectedAlpha
        let targetScale: CGFloat = selected ? GameConfig.characterCardSelectedScale : 1.0
        removeAction(forKey: "cardScale")
        run(
            SKAction.scale(to: targetScale, duration: GameConfig.characterCardScaleDuration),
            withKey: "cardScale"
        )
        // 시각 토큰 교체:
        // 선택: 코럴 12% 배경 + 코럴 60% 보더 + navyDeep 텍스트(NIKKE 톤 — 흰 카드)
        // 해제: 카드 기본 배경 + 흰색 7% 보더 + muted 텍스트
        background.color = selected ? .ganhoUIBrand12 : .ganhoUIBgCard
        border.strokeColor = selected ? .ganhoCoralPrimary : .ganhoUIBorder
        nameLabel.fontColor = selected ? .ganhoNavyDeep : .ganhoNavyMuted

        // Phase A — 선택 데코 토글.
        selectedGlow.isHidden = !selected
        selectedPill.isHidden = !selected
        selectedPillLabel.isHidden = !selected
    }

    // MARK: - Configure
    /// 이름 라벨 — 카드 하단 내부(Jua 15pt). Phase A에서 fontSize/offset v3로 갱신.
    private func configureNameLabel() {
        nameLabel.fontName = GameConfig.fontDisplay
        nameLabel.fontSize = GameConfig.characterCardNameFontSizeV3
        nameLabel.fontColor = .ganhoNavyMuted
        nameLabel.horizontalAlignmentMode = .center
        nameLabel.verticalAlignmentMode = .center
        let halfH = GameConfig.characterCardHeightV3 / 2
        nameLabel.position = CGPoint(
            x: 0,
            y: -halfH + GameConfig.characterCardNameOffsetYV3
        )
        nameLabel.zPosition = 5
    }

    // MARK: - Helpers
    /// 1.10 → "1.1", 1.00 → "1.0", 0.95 → "0.95" 톤. CharacterSelectScene.formatted와 동일 패턴.
    private func formattedSpeed(_ value: CGFloat) -> String {
        let rounded1 = (value * 10).rounded() / 10
        if abs(value - rounded1) < 0.001 {
            return String(format: "%.1f", Double(value))
        }
        return String(format: "%.2f", Double(value))
    }
}

// MARK: - Sprint 8 Phase B · Page Role
//
// 스와이프 페이지에서 카드의 *역할*을 표현. center=중앙(scale 1.08 + alpha 1.0 + glow/알약),
// left/right=±1 위치(scale 0.85 + alpha 0.55, 데코 숨김), offscreen=화면 밖(alpha 0).
//
// setPageState(role:animated:duration:)는 setSelected와 *대체* 관계 — 스와이프 모드에서는
// setPageState가 단일 진실 원천. CharacterSelectScene이 setSelected를 직접 호출하지 않으므로
// alpha/scale 충돌은 발생하지 않는다.
//
// **기존 init/setSelected/attach* 시그니처는 byte-identical** — 본 enum/extension은 *추가*만.

/// 카드 페이지 역할.
enum CharacterCardPageRole {
    /// 중앙 카드 — scale 1.08 + alpha 1.0 + glow/알약 표시.
    case center
    /// 좌측 ±1 카드 — scale 0.85 + alpha 0.55, 데코 숨김.
    case left
    /// 우측 ±1 카드 — scale 0.85 + alpha 0.55, 데코 숨김.
    case right
    /// 화면 밖 카드 — scale 0.85 + alpha 0, 데코 숨김.
    case offscreen
}

extension CharacterCardNode {

    /// 페이지 역할 적용 — scale/alpha + 카드 톤(배경/보더/이름색) + 글로우/알약 표시 일괄 토글.
    /// - Parameters:
    ///   - role: 카드 역할(center/left/right/offscreen).
    ///   - animated: true → SKAction 보간 / false → 즉시 적용.
    ///   - duration: animated=true일 때 SKAction 지속 시간(초). 권장: 0.22s.
    ///
    /// setSelected와 코드 중복 허용(SPEC §284). 스와이프 모드에서는 setSelected를 *호출하지 않음* —
    /// 본 메서드가 단일 진실 원천. 같은 파일 안 extension이므로 private property 접근 가능.
    func setPageState(role: CharacterCardPageRole,
                      animated: Bool,
                      duration: TimeInterval) {
        let targetScale: CGFloat
        let targetAlpha: CGFloat
        let isCenter: Bool
        switch role {
        case .center:
            targetScale = GameConfig.characterSwipeCardScaleCenterV4
            targetAlpha = 1.0
            isCenter = true
        case .left, .right:
            targetScale = GameConfig.characterSwipeCardScaleSideV4
            targetAlpha = GameConfig.characterSwipeCardAlphaSideV4
            isCenter = false
        case .offscreen:
            targetScale = GameConfig.characterSwipeCardScaleSideV4
            targetAlpha = 0
            isCenter = false
        }

        removeAction(forKey: "pageScale")
        removeAction(forKey: "pageAlpha")
        // 기존 setSelected가 사용하던 cardScale 액션과 충돌 방지 — 스와이프 모드에서는 우리가 단일 소유.
        removeAction(forKey: "cardScale")

        if animated {
            let scaleAct = SKAction.scale(to: targetScale, duration: duration)
            let alphaAct = SKAction.fadeAlpha(to: targetAlpha, duration: duration)
            scaleAct.timingMode = .easeInEaseOut
            alphaAct.timingMode = .easeInEaseOut
            run(scaleAct, withKey: "pageScale")
            run(alphaAct, withKey: "pageAlpha")
        } else {
            setScale(targetScale)
            alpha = targetAlpha
        }

        applyCenterDecor(isCenter)
    }

    /// 중앙 카드 데코(글로우/알약/이름 톤/배경 톤) 토글.
    /// setSelected(true/false)와 동일한 토큰 — 코드 중복 허용(setSelected byte-identical 보존).
    private func applyCenterDecor(_ isCenter: Bool) {
        // 배경/보더/이름 톤 — setSelected와 동일 매핑.
        background.color = isCenter ? .ganhoUIBrand12 : .ganhoUIBgCard
        border.strokeColor = isCenter ? .ganhoCoralPrimary : .ganhoUIBorder
        nameLabel.fontColor = isCenter ? .ganhoNavyDeep : .ganhoNavyMuted

        // 선택 데코 표시/숨김.
        selectedGlow.isHidden = !isCenter
        selectedPill.isHidden = !isCenter
        selectedPillLabel.isHidden = !isCenter
    }
}
