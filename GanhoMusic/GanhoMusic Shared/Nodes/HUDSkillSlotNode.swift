//
//  HUDSkillSlotNode.swift
//  GanhoMusic Shared
//
//  Phase 9-5 · 스킬 쿨다운 시각화 (좌하단 SkillButtonNode 위에 부착)
//
//  HUDNode(상단 4슬롯)와 *완전 분리* — 좌하단 cameraNode 자식.
//  라벨(스킬 이름) + 값(쿨다운 텍스트) + 진행 링 1개 구조.
//

import SpriteKit

/// 단일 스킬 슬롯. SkillSystem.progress(0.0~1.0)를 매 프레임 받아 시각화.
/// 4 상태: (1) 사용 가능 / (2) 쿨다운 중 / (3) 1회 소진 / (4) 김간호(빈 슬롯).
final class HUDSkillSlotNode: SKNode {

    // MARK: - Properties
    private let labelNode: SKLabelNode   // 위쪽 스킬 이름 (10pt dim)
    private let valueNode: SKLabelNode   // 아래쪽 진행률/상태 텍스트
    private let ringNode: SKShapeNode    // 진행 링 (배경)
    private let ringFillNode: SKShapeNode  // 진행 링 (채움)

    /// configure에서 set. progress 시각 분기에 사용.
    private var currentSkill: PlayerSkill = .none

    // MARK: - Init
    override init() {
        labelNode = SKLabelNode(text: "—")
        valueNode = SKLabelNode(text: "—")
        ringNode = SKShapeNode(circleOfRadius: GameConfig.hudSkillSlotRingRadius)
        ringFillNode = SKShapeNode(circleOfRadius: GameConfig.hudSkillSlotRingRadius)
        super.init()

        // 상단 라벨 — 10pt dim, 가운데 정렬. 링 위쪽으로 배치.
        labelNode.fontSize = GameConfig.hudLabelFontSize
        labelNode.fontColor = .ganhoUITextDim
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.zPosition = 100
        labelNode.position = CGPoint(
            x: 0,
            y: GameConfig.hudSkillSlotRingRadius + 10
        )

        // 진행 링 (배경) — 옅은 윤곽선.
        ringNode.lineWidth = GameConfig.hudSkillSlotRingLineWidth
        ringNode.strokeColor = .ganhoUIBrand20
        ringNode.fillColor = .clear
        ringNode.position = .zero
        ringNode.zPosition = 100

        // 진행 링 (채움) — progress=1.0일 때 완전 표시. progress=0.0일 때 alpha 0.
        ringFillNode.lineWidth = GameConfig.hudSkillSlotRingLineWidth
        ringFillNode.strokeColor = .ganhoUIBrandLight
        ringFillNode.fillColor = .ganhoUIBrand20
        ringFillNode.position = .zero
        ringFillNode.zPosition = 101

        // 하단 값 — 작은 보조 텍스트(상태 표시).
        valueNode.fontSize = GameConfig.hudLabelFontSize
        valueNode.fontColor = .ganhoUITextMuted
        valueNode.horizontalAlignmentMode = .center
        valueNode.verticalAlignmentMode = .center
        valueNode.zPosition = 100
        valueNode.position = CGPoint(
            x: 0,
            y: -GameConfig.hudSkillSlotRingRadius - 10
        )

        addChild(ringNode)
        addChild(ringFillNode)
        addChild(labelNode)
        addChild(valueNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    /// SkillSystem.configure 직후 GameScene이 1회 호출.
    /// 스킬 이름 라벨 갱신 + 김간호 빈 슬롯 시각 처리.
    func configure(skill: PlayerSkill) {
        currentSkill = skill
        labelNode.text = skill.displayName
        if skill == .none {
            // 김간호: 링 안 보임, value "—" dim. 라벨도 "—".
            ringNode.alpha = 0
            ringFillNode.alpha = 0
            valueNode.text = "—"
            valueNode.fontColor = .ganhoUITextDim
        } else {
            ringNode.alpha = 1
            ringFillNode.alpha = 1
            valueNode.text = "READY"
            valueNode.fontColor = .ganhoUITextMuted
        }
    }

    // MARK: - Update
    /// SkillSystem.progress(0.0~1.0)를 매 프레임 받아 4 상태 시각 분기.
    /// 김간호는 항상 빈 슬롯(progress 무시).
    func update(progress: CGFloat) {
        if currentSkill == .none {
            return  // 김간호: 항상 빈 슬롯 — configure에서 set한 상태 유지.
        }

        // charmStudent + usedThisGame: SkillSystem이 progress=0.0 반환 → 1회 소진 시각.
        if currentSkill.oncePerGame, progress <= 0 {
            // 1회 소진: ring 채움 0, value dim "USED".
            ringFillNode.alpha = 0
            valueNode.text = "USED"
            valueNode.fontColor = .ganhoUITextDim
            return
        }

        // 사용 가능 상태(progress ≈ 1.0).
        if progress >= 1.0 {
            ringFillNode.alpha = 1.0
            ringFillNode.strokeColor = .ganhoUIBrandLight
            ringFillNode.fillColor = .ganhoUIBrand20
            valueNode.text = "READY"
            valueNode.fontColor = .ganhoUIBrandLight
            return
        }

        // 쿨다운 중(0 < progress < 1.0): 채움 비율 = progress.
        // 단순화: 채움 노드의 alpha = progress (강한 시각 차이는 alpha + color로).
        ringFillNode.alpha = progress
        ringFillNode.strokeColor = .ganhoUIBrand40
        ringFillNode.fillColor = .clear
        valueNode.text = "..."
        valueNode.fontColor = .ganhoUITextMuted
    }
}
