//
//  HUDSlotNode.swift
//  GanhoMusic Shared
//
//  R8 §B③ — HUDNode.swift(1파일 2클래스 474줄)에서 분리. 코드 이동만 — 로직 0 변경.
//  Phase 8-5 · 원본 .game-hud__entry 1:1 / Sprint 3 · v2 알약 + 진행바 / R7 §F3 · 콤보 게이지.
//  값/색/진행바/게이지 setter는 HUDSlotNode+Display.swift (단독 300줄 초과 회피 분할).
//

import SpriteKit

/// HUD 단일 슬롯 — navy 알약 + 라벨(위 10pt 골드) + 값(아래 18pt 흰).
/// 원본 .game-hud__entry > .game-hud__label + .game-hud__value 1:1 매핑.
/// Sprint 3 — 알약 배경, fontDisplay, v2 색 토큰, TIME 슬롯 진행바.
final class HUDSlotNode: SKNode {

    // MARK: - Properties
    /// navy 0.78 알약 배경. setWarn(true) 진입 시 코랄로 swap.
    /// R8 분할 — +Display(setWarn)가 접근: private → internal (이동 필수분).
    let backgroundChip: SKShapeNode
    /// 알약 그림자 — init 전용 부착물 (외부 접근 없음).
    private let shadowNode: SKShapeNode
    /// 위쪽 캡션 라벨 — init 전용 구성 (외부 접근 없음).
    private let labelNode: SKLabelNode
    /// 값 라벨. R8 분할 — +Display(setValue/색/펄스/블링크)가 접근: private → internal.
    let valueNode: SKLabelNode
    /// TIME 슬롯 전용 진행바 배경(흰 α). showTimeBar=true일 때만 자식 (init 전용).
    private let timeBarBg: SKSpriteNode?
    /// TIME 슬롯 전용 진행바 채움(흰). xScale로 진행률 시각화.
    /// R8 분할 — +Display(setTimeBar)가 접근: private → internal (이동 필수분).
    let timeBarFill: SKSpriteNode?
    /// R7 §F3 — COMBO 슬롯 전용 콤보 윈도우 게이지(60×4). showComboGauge=true일 때만 자식.
    /// timeBar 패턴 재사용 — SKSpriteNode 2장, xScale 갱신만 (매 프레임 텍스처/노드 생성 0).
    /// R8 분할 — +Display(setComboGauge)가 접근: private → internal (이동 필수분).
    let comboGaugeBg: SKSpriteNode?
    let comboGaugeFill: SKSpriteNode?
    /// R7 §F3 — 코랄 점멸 상태. 상태 전환 시 1회 부착/제거 (매 프레임 SKAction 재부착 금지).
    /// R8 분할 — +Display(점멸 시작/정지)가 기록: private → internal (이동 필수분).
    var isComboGaugeBlinking = false

    // MARK: - Init
    /// - Parameters:
    ///   - label: 위쪽 캡션 텍스트 ("TIME"/"SCORE"/"COMBO"/"PLAYER").
    ///   - initialValue: 아래쪽 값 텍스트 초기값.
    ///   - showTimeBar: TIME 슬롯 전용 진행바 자식 생성 여부 (default false → 호환성 100%).
    ///   - showComboGauge: COMBO 슬롯 전용 콤보 윈도우 게이지 생성 여부 (R7 §F3, default false).
    init(label: String, initialValue: String, showTimeBar: Bool = false,
         showComboGauge: Bool = false) {
        // (1) 배경 알약 — navy 0.78. setWarn으로 코랄 교체 가능.
        let chipSize = CGSize(
            width: UILayout.hudSlotWidth,
            height: UILayout.hudSlotHeight
        )
        shadowNode = SKShapeNode(
            rectOf: chipSize,
            cornerRadius: UILayout.hudSlotCornerRadius
        )
        backgroundChip = SKShapeNode(
            rectOf: chipSize,
            cornerRadius: UILayout.hudSlotCornerRadius
        )
        shadowNode.fillColor = UIColor.ganhoPixelOutlineBlack
            .withAlphaComponent(UILayout.hudSlotShadowAlpha)
        shadowNode.strokeColor = .clear
        shadowNode.position = CGPoint(
            x: UILayout.hudSlotShadowOffsetX,
            y: UILayout.hudSlotShadowOffsetY
        )
        shadowNode.zPosition = 98
        backgroundChip.fillColor = UIColor.ganhoNavyDeep
            .withAlphaComponent(UILayout.hudSlotBgAlpha)
        backgroundChip.strokeColor = UIColor.ganhoPixelHudYellow
            .withAlphaComponent(UILayout.hudSlotStrokeAlpha)
        backgroundChip.lineWidth = UILayout.hudSlotStrokeWidth
        backgroundChip.zPosition = 99

        // (2) 라벨/값 SKLabelNode. Sprint 10 Phase J — fontDisplay(Jua-Regular) → fontPixel(Menlo-Bold).
        labelNode = SKLabelNode(fontNamed: Typography.fontPixel)
        labelNode.text = label
        valueNode = SKLabelNode(fontNamed: Typography.fontPixel)
        valueNode.text = initialValue

        // (3) 진행바 자식 — TIME 슬롯만. xScale 갱신을 위해 anchorPoint 좌측 정렬.
        if showTimeBar {
            let barSize = CGSize(
                width: chipSize.width - 8,
                height: UILayout.hudTimeBarHeight
            )
            let bg = SKSpriteNode(color: .white, size: barSize)
            bg.alpha = UILayout.hudTimeBarBgAlpha
            bg.anchorPoint = CGPoint(x: 0, y: 0.5)
            // 알약 안 하단. -chipHeight/2 + bar 높이/2 + gap.
            bg.position = CGPoint(
                x: -barSize.width / 2,
                y: -chipSize.height / 2 + UILayout.hudTimeBarHeight / 2 + UILayout.hudTimeBarTopGap
            )
            // Sprint 8 Phase F — V4 zPos 명시화(값 100 보존).
            bg.zPosition = ZOrder.hudLabelZPosition
            timeBarBg = bg

            let fill = SKSpriteNode(color: .white, size: barSize)
            fill.alpha = 0.95
            fill.anchorPoint = CGPoint(x: 0, y: 0.5)
            fill.position = bg.position
            // Sprint 8 Phase F — V4 zPos +1 (값 101 보존, fill이 bg 위).
            fill.zPosition = ZOrder.hudLabelZPosition + 1
            // 시작 시 가득 찬 상태. setTimeBar(progress:)로 매 프레임 갱신.
            fill.xScale = 1.0
            timeBarFill = fill
        } else {
            timeBarBg = nil
            timeBarFill = nil
        }

        // (3-b) R7 §F3 — 콤보 윈도우 게이지 — COMBO 슬롯만. timeBar(3)와 동일 anchor/배치 패턴.
        // 시작 isHidden=true: combo 0 동안 비표시. 상태형 HUD 요소의 표시/비표시 토글은 좀비 패턴
        // 아님 — 매 판 재사용되는 살아있는 상태 표시기의 OFF 시각이지, 불용 노드 잔존이 아니다.
        if showComboGauge {
            let gaugeSize = UILayout.R7.hudComboGaugeSize
            let gaugeY = -chipSize.height / 2 + gaugeSize.height / 2
                + UILayout.R7.hudComboGaugeBottomGap
            let bg = SKSpriteNode(color: .white, size: gaugeSize)
            bg.alpha = UILayout.hudTimeBarBgAlpha
            bg.anchorPoint = CGPoint(x: 0, y: 0.5)
            bg.position = CGPoint(x: -gaugeSize.width / 2, y: gaugeY)
            bg.zPosition = ZOrder.hudLabelZPosition
            bg.isHidden = true
            comboGaugeBg = bg

            let fill = SKSpriteNode(color: .white, size: gaugeSize)
            fill.alpha = FeelTuning.R7.comboGaugeFillAlpha
            fill.anchorPoint = CGPoint(x: 0, y: 0.5)
            fill.position = bg.position
            fill.zPosition = ZOrder.hudLabelZPosition + 1
            fill.isHidden = true
            comboGaugeFill = fill
        } else {
            comboGaugeBg = nil
            comboGaugeFill = nil
        }

        super.init()

        // (4) 위쪽 라벨 — 10pt 픽셀 옐로. labelNode.position을 super.init 후 set.
        // Sprint 10 Phase J — ganhoMusicGold → ganhoPixelHudYellow swap.
        labelNode.fontSize = UILayout.hudSlotLabelFontSize
        labelNode.fontColor = .ganhoPixelHudYellow
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        // Sprint 8 Phase F — V4 zPos 명시화(값 100 보존).
        labelNode.zPosition = ZOrder.hudLabelZPosition
        labelNode.position = CGPoint(
            x: 0,
            y: UILayout.hudSlotValueFontSize / 2 + UILayout.hudSlotInnerGap
        )

        // (5) 아래쪽 값 — 18pt 픽셀 화이트(페이퍼 화이트 톤). Sprint 10 Phase J — .white → ganhoPixelHudWhite.
        valueNode.fontSize = UILayout.hudSlotValueFontSize
        valueNode.fontColor = .ganhoPixelHudWhite
        valueNode.horizontalAlignmentMode = .center
        valueNode.verticalAlignmentMode = .center
        // Sprint 8 Phase F — V4 zPos 명시화(값 100 보존).
        valueNode.zPosition = ZOrder.hudLabelZPosition
        valueNode.position = CGPoint(
            x: 0,
            y: -UILayout.hudSlotLabelFontSize / 2 - UILayout.hudSlotInnerGap
        )

        // (6) 자식 부착 — 그림자(98) → 배경(99) → 진행바/게이지(100/101) → 라벨/값(100).
        addChild(shadowNode)
        addChild(backgroundChip)
        if let bg = timeBarBg { addChild(bg) }
        if let fill = timeBarFill { addChild(fill) }
        if let bg = comboGaugeBg { addChild(bg) }
        if let fill = comboGaugeFill { addChild(fill) }
        addChild(labelNode)
        addChild(valueNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
