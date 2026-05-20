//
//  DifficultyCardNode.swift
//  GanhoMusic Shared
//
//  Phase 7-1 · 난이도 선택 카드 — 색 사각형 + 이름 라벨 + 부제 라벨 + 선택 알파/scale 토글
//  Phase 8-3 · 캡슐 형태 SKShapeNode로 전환 — 원본 .game-difficulty__btn border-radius:999 재현
//  Phase 10-2 · 선택 시 spring overshoot + 살구 링 글로우 추가 (시그니처 불변)
//  Sprint 7 · 잘림 해소 + 카드 시인성 강화
//             - 카드 폭/높이 1.4배 확장 (V3 상수)
//             - 미선택 알파 0.5 → 0.78, 미선택 fill id.color α 0.08, stroke id.color α 0.4
//             - descriptionLabel(SKLabelNode) 신규 — 한 줄 풀이(2줄 wrap 허용)
//             - 라벨 색 토큰 .ganhoNavyDeep / .ganhoNavyMuted로 갱신
//  Sprint 7 Phase C · 색 위계 + 글로우 + 상승
//             - id.color(.ganhoMint/.ganhoYellowF/.ganhoBloodAccent) → id.cardFillTop/cardStrokeColor
//               분기. 카드별 색 위계(하=민트, 중=골드, 상=코랄) 부여.
//             - ringGlow.strokeColor → id.cardGlowColor (카드별 강조색).
//             - nameLabel 폰트 22pt → 30pt + nameLabelStroke 베이스 라벨로 stroke 외곽선 표현.
//             - 선택 시 position.y +8 lift 액션 — liftCurrentOffset 증분 추적(중복 호출 안전).
//             - setSelected / init 시그니처 byte-identical.
//  Sprint 8 Phase D · 카드 크기/여백 V4 (130×200 + line height 1.4)
//             - V3 카드(112×82) 좁아 한글 텍스트 2~3줄 줄바꿈 답답 → V4 130×200으로 확대.
//             - 내부 padding 14pt / headerGap 12pt / subtitleGap 10pt로 호흡 확보.
//             - subtitleLabel을 NSAttributedString + lineHeightMultiple 1.4로 재구성
//               (numberOfLines=0, preferredMaxLayoutWidth = cardWidth - padding*2 = 102pt).
//             - 색 위계(EasyMint/MidGold/HardCoral) 및 시그니처 byte-identical 보존.
//

import SpriteKit

/// TitleScene / DifficultySelectScene 하단 난이도 선택 카드.
/// PhysicsBody 0 — 순수 시각 + hit test 대상.
/// Sprint 7 — 자식 SKShapeNode(카드 배경) + SKLabelNode(이름) + SKLabelNode(부제) + SKLabelNode(설명)
/// + SKShapeNode(ringGlow, zPos -1) 컨테이너.
/// CharacterCardNode(5-1)와 동형 패턴 — 라벨이 1개 더(설명) 늘었을 뿐 호출부 시그니처 불변.
/// 본 sprint 정책: 코드 중복 허용. 공통 부모 추출(BaseCardNode)은 별도 sprint.
final class DifficultyCardNode: SKNode {

    // MARK: - Properties
    let id: Difficulty
    /// Sprint 7 — 카드 배경. cornerRadius는 difficultyCardCornerRadiusV3(=20) — 캡슐이 아닌 둥근 사각형.
    private let background: SKShapeNode
    private let nameLabel: SKLabelNode
    /// Sprint 7 Phase C — nameLabel 뒤에 살짝 큰 폰트(30 + stroke×2 = 32pt)로 깔리는 베이스 라벨.
    /// fontColor = id.cardStrokeColor 정색. nameLabel(navy)이 위에서 덮으며 외곽선 효과 근사.
    /// SKLabelNode는 stroke 직접 미지원이라 2-라벨 겹침 기법 사용.
    private let nameLabelStroke = SKLabelNode()
    private let subtitleLabel: SKLabelNode
    /// Sprint 7 — 한 줄(필요 시 2줄) 풀이 라벨. id.description을 사용.
    private let descriptionLabel: SKLabelNode
    /// Phase 10-2 — 선택 시 띄우는 살구색 링 글로우. 평소 alpha 0, 선택 시 fade-in.
    /// 카드 배경보다 *살짝 큰* 캡슐로 외곽에서 빛나는 톤.
    /// Sprint 7 Phase C — strokeColor를 id.cardGlowColor로 카드별 분기.
    private let ringGlow: SKShapeNode
    /// Sprint 7 Phase C — 누적된 lift 오프셋(현재 y 위치가 base 대비 얼마나 올라가 있는지).
    /// setSelected 중복 호출 시 position.y 누적 방지 — 증분 액션으로 변경.
    private var liftCurrentOffset: CGFloat = 0

    // MARK: - Init
    init(id: Difficulty) {
        self.id = id
        // Sprint 8 Phase D — V4 카드 크기(130 × 200) + V3 코너 반경(20pt) 보존.
        // V3 size 상수(difficultyCardWidthV3=112, HeightV3=82)는 GameConfig에 byte-identical 보존.
        let cardSize = CGSize(
            width: GameConfig.difficultyCardWidthV4,
            height: GameConfig.difficultyCardHeightV4
        )
        background = SKShapeNode(
            rectOf: cardSize,
            cornerRadius: GameConfig.difficultyCardCornerRadiusV3
        )
        // Sprint 7 Phase C — 미선택 기본 톤: id.cardFillTop α 0.08 fill + id.cardStrokeColor α 0.4 stroke.
        // setSelected가 호출되면서 초기 상태에서도 다시 설정되지만 안전을 위해 init에서 채움.
        background.fillColor = id.cardFillTop.withAlphaComponent(
            GameConfig.difficultyCardDeselectedFillAlphaV3
        )
        background.strokeColor = id.cardStrokeColor.withAlphaComponent(
            GameConfig.difficultyCardDeselectedStrokeAlphaV3
        )
        background.lineWidth = GameConfig.difficultyCardStrokeLineWidthV3

        nameLabel = SKLabelNode(text: id.displayName)
        subtitleLabel = SKLabelNode(text: id.subtitle)
        // Sprint 7 — 신규 description 라벨.
        descriptionLabel = SKLabelNode(text: id.description)

        // Phase 10-2 — 링 글로우. 카드보다 padding만큼 큰 캡슐(외곽 형태 유지).
        // Sprint 7 Phase C — strokeColor를 id.cardGlowColor(카드별 강조색)로 분기.
        let ringSize = CGSize(
            width: cardSize.width + GameConfig.difficultyCardRingGlowPadding,
            height: cardSize.height + GameConfig.difficultyCardRingGlowPadding
        )
        ringGlow = SKShapeNode(
            rectOf: ringSize,
            cornerRadius: GameConfig.difficultyCardCornerRadiusV3
        )
        ringGlow.fillColor = .clear
        ringGlow.strokeColor = id.cardGlowColor
        ringGlow.lineWidth = GameConfig.difficultyCardRingGlowLineWidth
        ringGlow.glowWidth = GameConfig.difficultyCardSelectedGlowSpreadPhaseC
        ringGlow.alpha = 0

        super.init()
        name = "difficultyCard_\(id.rawValue)"
        zPosition = 100
        background.position = .zero
        // 링 글로우는 *배경보다 뒤*에 배치 — 외곽에서 빛나는 톤.
        ringGlow.position = .zero
        ringGlow.zPosition = -1
        addChild(ringGlow)
        addChild(background)
        configureLabels()
        // Sprint 7 Phase C — strokeLabel을 nameLabel 뒤(zPos -0.1)에 먼저 add.
        addChild(nameLabelStroke)
        addChild(nameLabel)
        addChild(subtitleLabel)
        addChild(descriptionLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Selection
    /// 선택 상태 시각 토글. 호출 시그니처 불변 — DifficultySelectScene이 그대로 호출.
    /// Sprint 7 — 미선택 alpha 0.78(기존 0.5에서 상향, V3 상수), fill α 0.08, stroke α 0.4.
    /// 선택 시 fill α 0.2(=Phase 8-3 톤), stroke id.cardStrokeColor 정색.
    /// Sprint 7 Phase C — id.color → id.cardFillTop/cardStrokeColor 분기로 카드별 색 위계.
    /// ringGlow.strokeColor = id.cardGlowColor 매번 재설정(가독성 보장).
    /// position.y +8pt lift 액션 — liftCurrentOffset 증분 추적으로 중복 호출 안전.
    /// nameLabel / nameLabelStroke / subtitleLabel / descriptionLabel 모두 색 동기화.
    func setSelected(_ selected: Bool) {
        alpha = selected ? 1.0 : GameConfig.difficultyCardDeselectedAlphaV3
        removeAction(forKey: "cardScale")
        if selected {
            // Phase 10-2 — spring: overshoot 1.12 → settle 1.08.
            let overshoot = SKAction.scale(
                to: GameConfig.difficultyCardSpringOvershootScale,
                duration: GameConfig.difficultyCardSpringPhase1Duration
            )
            overshoot.timingMode = .easeOut
            let settle = SKAction.scale(
                to: GameConfig.characterCardSelectedScale,
                duration: GameConfig.difficultyCardSpringPhase2Duration
            )
            settle.timingMode = .easeInEaseOut
            run(
                SKAction.sequence([overshoot, settle]),
                withKey: "cardScale"
            )
        } else {
            run(
                SKAction.scale(to: 1.0, duration: GameConfig.characterCardScaleDuration),
                withKey: "cardScale"
            )
        }
        // Sprint 7 Phase C — fill / stroke를 카드별 색(id.cardFillTop / id.cardStrokeColor)으로 분기.
        background.fillColor = selected
            ? id.cardFillTop.withAlphaComponent(GameConfig.difficultyCardSelectedFillAlphaV3)
            : id.cardFillTop.withAlphaComponent(GameConfig.difficultyCardDeselectedFillAlphaV3)
        background.strokeColor = selected
            ? id.cardStrokeColor
            : id.cardStrokeColor.withAlphaComponent(GameConfig.difficultyCardDeselectedStrokeAlphaV3)

        // Sprint 7 — 라벨 색 동기화. 선택 시 진한 네이비, 미선택 시 muted 네이비.
        nameLabel.fontColor = selected ? .ganhoNavyDeep : .ganhoNavyMuted
        // Sprint 8 Phase D — subtitleLabel/descriptionLabel은 attributedText로 line height 1.4를
        // 적용하기 때문에 fontColor 직접 설정이 무시됨. 색 변경은 attributedText 재구성으로 처리.
        subtitleLabel.attributedText = makeSubtitleAttributedText(
            text: id.subtitle,
            alignment: .center
        )
        descriptionLabel.attributedText = makeDescriptionAttributedText(
            text: id.description,
            color: selected ? .ganhoNavyDeep : .ganhoNavyMuted,
            alignment: .center
        )
        // Sprint 7 Phase C — strokeLabel 색은 항상 id.cardStrokeColor(외곽선 정색 유지).
        nameLabelStroke.fontColor = id.cardStrokeColor

        // Phase 10-2 + Sprint 7 Phase C — 링 글로우 fade in/out + 카드별 강조색 재설정.
        // 카드 인스턴스 id는 고정이라 init에서 1회로 충분하지만 가독성 위해 명시 갱신.
        ringGlow.strokeColor = id.cardGlowColor
        ringGlow.removeAction(forKey: "ringFade")
        let targetAlpha: CGFloat = selected
            ? GameConfig.difficultyCardSelectedGlowAlphaPhaseC
            : 0.0
        let duration: TimeInterval = selected
            ? GameConfig.difficultyCardRingGlowFadeInDuration
            : GameConfig.difficultyCardRingGlowFadeOutDuration
        ringGlow.run(
            SKAction.fadeAlpha(to: targetAlpha, duration: duration),
            withKey: "ringFade"
        )

        // Sprint 7 Phase C — lift 액션. 증분 패턴(targetY - liftCurrentOffset)으로
        // setSelected 중복 호출 시 누적 방지. moveBy는 *현재 위치에서 상대 이동*.
        removeAction(forKey: "cardLift")
        let targetY: CGFloat = selected ? GameConfig.difficultyCardSelectedLiftY : 0
        let lift = SKAction.moveBy(
            x: 0,
            y: targetY - liftCurrentOffset,
            duration: GameConfig.difficultyCardSelectedLiftDuration
        )
        lift.timingMode = .easeOut
        run(lift, withKey: "cardLift")
        liftCurrentOffset = targetY
    }

    // MARK: - Configure
    /// 이름(상단) + 부제(중단) + 설명(하단) 3행 스타일.
    /// 카드 내부 *상대 좌표*(background 중심 기준)로 배치 — Sprint 8 Phase D V4 layout.
    ///
    /// V4 산식 (카드 200pt 높이, 위/아래 padding 14pt):
    ///   - cardTop = +100, innerTop = +100 - 14 = +86
    ///   - nameLabel.y = +86 - nameFontSize/2(15) = +71 (verticalAlignmentMode=.center)
    ///   - nameBottom = +71 - 15 = +56
    ///   - subtitleLabel.y = nameBottom - headerGap(12) - subtitleFontSize/2(6) = +38 (center anchor)
    ///   - subtitleBottom = +38 - 6 = +32
    ///   - descriptionLabel top.y = subtitleBottom - subtitleGap(10) = +22 (top anchor)
    ///
    /// Sprint 8 Phase D — subtitleLabel과 descriptionLabel은 NSAttributedString +
    ///   lineHeightMultiple 1.4 적용. preferredMaxLayoutWidth = cardWidthV4(130) - padding*2(28) = 102pt.
    /// Sprint 7 Phase C — nameLabel 30pt + nameLabelStroke(폰트 = 30 + 1×2 = 32pt) 2-라벨 stroke.
    private func configureLabels() {
        // V4 layout 산출 — 카드 내부 상대 좌표.
        let cardTopY: CGFloat = GameConfig.difficultyCardHeightV4 / 2
        let innerTopY: CGFloat = cardTopY - GameConfig.difficultyCardPaddingV4
        let nameHalfHeight: CGFloat = GameConfig.difficultyCardNameFontSizePhaseC / 2
        let nameCenterY: CGFloat = innerTopY - nameHalfHeight
        let nameBottomY: CGFloat = nameCenterY - nameHalfHeight
        let subtitleHalfHeight: CGFloat = GameConfig.difficultyCardSubtitleFontSizeV4 / 2
        let subtitleCenterY: CGFloat = nameBottomY
            - GameConfig.difficultyCardHeaderGapV4
            - subtitleHalfHeight
        let subtitleBottomY: CGFloat = subtitleCenterY - subtitleHalfHeight
        let descriptionTopY: CGFloat = subtitleBottomY - GameConfig.difficultyCardSubtitleGapV4
        // V4 wrap 폭 = cardWidth(130) - padding(14) × 2 = 102pt.
        let wrapWidth: CGFloat = GameConfig.difficultyCardWidthV4
            - GameConfig.difficultyCardPaddingV4 * 2

        // 이름 라벨 — 카드 상단. Sprint 7 Phase C: 22 → 30pt + navyDeep fill.
        nameLabel.fontName = GameConfig.fontDisplay
        nameLabel.fontSize = GameConfig.difficultyCardNameFontSizePhaseC
        nameLabel.fontColor = .ganhoNavyDeep
        nameLabel.horizontalAlignmentMode = .center
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: 0, y: nameCenterY)
        nameLabel.zPosition = 5

        // Sprint 7 Phase C — stroke 라벨. nameLabel과 같은 텍스트, 폰트는 nameFontSize + stroke×2,
        // fontColor는 id.cardStrokeColor — 위에 nameLabel(navy)이 덮으며 외곽선 효과 근사.
        // SKLabelNode는 stroke 직접 미지원이라 2-라벨 겹침 기법 사용.
        nameLabelStroke.text = id.displayName
        nameLabelStroke.fontName = GameConfig.fontDisplay
        nameLabelStroke.fontSize = GameConfig.difficultyCardNameFontSizePhaseC
            + GameConfig.difficultyCardNameStrokeWidthPhaseC * 2
        nameLabelStroke.fontColor = id.cardStrokeColor
        nameLabelStroke.horizontalAlignmentMode = .center
        nameLabelStroke.verticalAlignmentMode = .center
        nameLabelStroke.position = CGPoint(x: 0, y: nameCenterY)
        nameLabelStroke.zPosition = nameLabel.zPosition - 0.1

        // 부제 — 중단. Sprint 8 Phase D — attributedText + lineHeightMultiple 1.4.
        subtitleLabel.fontName = GameConfig.fontBody
        subtitleLabel.fontSize = GameConfig.difficultyCardSubtitleFontSizeV4
        subtitleLabel.fontColor = .ganhoNavyMuted
        subtitleLabel.horizontalAlignmentMode = .center
        subtitleLabel.verticalAlignmentMode = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.preferredMaxLayoutWidth = wrapWidth
        subtitleLabel.position = CGPoint(x: 0, y: subtitleCenterY)
        subtitleLabel.attributedText = makeSubtitleAttributedText(
            text: id.subtitle,
            alignment: .center
        )

        // 설명 — 하단(Sprint 7 신규). Sprint 8 Phase D — attributedText + line height 1.4 + .top anchor.
        descriptionLabel.fontName = GameConfig.fontBody
        descriptionLabel.fontSize = GameConfig.difficultyCardDescriptionFontSizeV3
        descriptionLabel.fontColor = .ganhoNavyMuted
        descriptionLabel.horizontalAlignmentMode = .center
        descriptionLabel.verticalAlignmentMode = .top
        descriptionLabel.numberOfLines = 0
        descriptionLabel.preferredMaxLayoutWidth = wrapWidth
        descriptionLabel.position = CGPoint(x: 0, y: descriptionTopY)
        // 초기 미선택 색은 navyMuted — setSelected가 init 직후 호출되어 다시 갱신됨.
        descriptionLabel.attributedText = makeDescriptionAttributedText(
            text: id.description,
            color: .ganhoNavyMuted,
            alignment: .center
        )
    }

    // MARK: - Attributed Text (Sprint 8 Phase D — line height 1.4)
    /// 부제 라벨용 attributedString. lineHeightMultiple = 1.4 적용.
    /// UIFont 옵셔널은 nil-coalescing으로 systemFont fallback.
    private func makeSubtitleAttributedText(
        text: String,
        alignment: NSTextAlignment
    ) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = GameConfig.difficultyCardSubtitleLineHeightV4
        style.alignment = alignment
        let font: UIFont = UIFont(
            name: GameConfig.fontBody,
            size: GameConfig.difficultyCardSubtitleFontSizeV4
        ) ?? UIFont.systemFont(ofSize: GameConfig.difficultyCardSubtitleFontSizeV4)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ganhoNavyMuted,
            .paragraphStyle: style
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }

    /// 설명 라벨용 attributedString. lineHeightMultiple = 1.4 + V3 descriptionFontSize(10pt).
    /// setSelected에 따라 색이 navyDeep / navyMuted로 토글되므로 color를 외부 주입.
    private func makeDescriptionAttributedText(
        text: String,
        color: UIColor,
        alignment: NSTextAlignment
    ) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = GameConfig.difficultyCardSubtitleLineHeightV4
        style.alignment = alignment
        let font: UIFont = UIFont(
            name: GameConfig.fontBody,
            size: GameConfig.difficultyCardDescriptionFontSizeV3
        ) ?? UIFont.systemFont(ofSize: GameConfig.difficultyCardDescriptionFontSizeV3)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }
}
