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
        // Sprint 10 Phase J — fontDisplay(Jua-Regular) → fontPixel(Menlo-Bold). 인게임 픽셀 톤 통일.
        labelNode = SKLabelNode(fontNamed: GameConfig.fontPixel)
        labelNode.text = "—"
        valueNode = SKLabelNode(fontNamed: GameConfig.fontPixel)
        valueNode.text = "—"
        ringNode = SKShapeNode(circleOfRadius: GameConfig.hudSkillSlotRingRadius)
        ringFillNode = SKShapeNode(circleOfRadius: GameConfig.hudSkillSlotRingRadius)
        super.init()

        // 상단 라벨 — 10pt 픽셀 옐로, 가운데 정렬. 링 위쪽으로 배치.
        // Sprint 10 Phase J — ganhoMusicGold → ganhoPixelHudYellow swap.
        labelNode.fontSize = GameConfig.hudLabelFontSize
        labelNode.fontColor = .ganhoPixelHudYellow
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        // Sprint 8 Phase F — 스킬 이름 단일 진실 원천. 110(컨테이너 99~101 위에 표시).
        labelNode.zPosition = GameConfig.hudSkillSlotLabelZPositionV4
        labelNode.position = CGPoint(
            x: 0,
            y: GameConfig.hudSkillSlotRingRadius + 10
        )

        // 진행 링 (배경) — 옅은 픽셀 옐로 윤곽선.
        // Sprint 10 Phase J — ganhoMusicGold → ganhoPixelHudYellow swap.
        ringNode.lineWidth = GameConfig.hudSkillSlotRingLineWidth
        ringNode.strokeColor = UIColor.ganhoPixelHudYellow.withAlphaComponent(0.3)
        ringNode.fillColor = .clear
        ringNode.position = .zero
        ringNode.zPosition = 100

        // 진행 링 (채움) — progress=1.0일 때 완전 표시. progress=0.0일 때 alpha 0.
        // Sprint 10 Phase J — READY 픽셀 옐로, 쿨다운 픽셀 코랄. update에서 분기 set.
        ringFillNode.lineWidth = GameConfig.hudSkillSlotRingLineWidth
        ringFillNode.strokeColor = .ganhoPixelHudYellow
        ringFillNode.fillColor = UIColor.ganhoPixelHudYellow.withAlphaComponent(0.15)
        ringFillNode.position = .zero
        ringFillNode.zPosition = 101

        // 하단 값 — 작은 보조 텍스트(상태 표시). Sprint 10 Phase J — .white → ganhoPixelHudWhite.
        valueNode.fontSize = GameConfig.hudLabelFontSize
        valueNode.fontColor = .ganhoPixelHudWhite
        valueNode.horizontalAlignmentMode = .center
        valueNode.verticalAlignmentMode = .center
        // Sprint 8 Phase F — CD/상태 텍스트 단일 진실 원천. 110(컨테이너 99~101 위에 표시).
        valueNode.zPosition = GameConfig.hudSkillSlotLabelZPositionV4
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
            // Sprint 10 Phase J — dim 픽셀 화이트 0.4. .white → ganhoPixelHudWhite swap.
            ringNode.alpha = 0
            ringFillNode.alpha = 0
            valueNode.text = "—"
            valueNode.fontColor = UIColor.ganhoPixelHudWhite.withAlphaComponent(0.4)
        } else {
            ringNode.alpha = 1
            ringFillNode.alpha = 1
            valueNode.text = "READY"
            // Sprint 10 Phase J — READY 텍스트 색 픽셀 옐로(SPEC §9 "valueNode READY 색도 픽셀 옐로").
            valueNode.fontColor = .ganhoPixelHudYellow
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
        // Sprint 10 Phase J — dim 텍스트 .white → ganhoPixelHudWhite swap.
        if currentSkill.oncePerGame, progress <= 0 {
            // 1회 소진: ring 채움 0, value dim "USED".
            ringFillNode.alpha = 0
            valueNode.text = "USED"
            valueNode.fontColor = UIColor.ganhoPixelHudWhite.withAlphaComponent(0.4)
            return
        }

        // 사용 가능 상태(progress ≈ 1.0). Sprint 10 Phase J — 픽셀 옐로 톤.
        if progress >= 1.0 {
            ringFillNode.alpha = 1.0
            ringFillNode.strokeColor = .ganhoPixelHudYellow
            ringFillNode.fillColor = UIColor.ganhoPixelHudYellow.withAlphaComponent(0.15)
            valueNode.text = "READY"
            valueNode.fontColor = .ganhoPixelHudYellow
            return
        }

        // 쿨다운 중(0 < progress < 1.0): 채움 비율 = progress.
        // Sprint 10 Phase J — 쿨다운 ganhoCoralPrimary → ganhoPixelHudCoral. fillColor=clear, alpha=progress.
        ringFillNode.alpha = progress
        ringFillNode.strokeColor = .ganhoPixelHudCoral
        ringFillNode.fillColor = .clear
        valueNode.text = "..."
        valueNode.fontColor = .ganhoPixelHudWhite
    }
}
