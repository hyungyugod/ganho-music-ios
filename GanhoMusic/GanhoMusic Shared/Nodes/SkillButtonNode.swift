//
//  SkillButtonNode.swift
//  GanhoMusic Shared
//
//  Phase 9-5 · 좌하단 스킬 버튼 (1탭 발동)
//
//  cameraNode 자식 — 화면 고정. D-Pad(우하단)와 대칭 위치(좌하단).
//  김간호 선택 시 isUserInteractionEnabled=false + alpha 0.3 + 라벨 "—".
//

import SpriteKit

/// 4 캐릭터 능동 스킬 1탭 발동 버튼. 32pt 반지름 원형.
/// 외부(GameScene)가 onTap 콜백 등록 → 탭 시 SkillSystem.tryActivate() 호출.
/// setEnabled(false)로 김간호 모드 진입 — 시각/터치 모두 비활성.
final class SkillButtonNode: SKNode {

    // MARK: - Properties
    /// 1탭 시 호출되는 콜백. GameScene이 `[weak self] in self?.skillSystem.tryActivate()` 등록.
    /// default = {} → 등록 누락 시에도 안전(noop).
    var onTap: () -> Void = {}

    private let backgroundNode: SKShapeNode
    private let labelNode: SKLabelNode

    /// 활성/비활성 상태. setEnabled가 단일 진입점.
    private(set) var isEnabled: Bool = true

    // MARK: - Init
    override init() {
        backgroundNode = SKShapeNode(circleOfRadius: GameConfig.skillButtonRadius)
        labelNode = SKLabelNode(text: "SKILL")
        super.init()

        // 배경 원 — 코럴 반투명 채움 + 코럴 1pt 외곽선.
        backgroundNode.fillColor = .ganhoUIBrand20
        backgroundNode.strokeColor = .ganhoUIBrand
        backgroundNode.lineWidth = 1
        backgroundNode.position = .zero
        backgroundNode.zPosition = 100

        // 중앙 라벨 — 12pt brand color.
        labelNode.fontSize = GameConfig.uiCardNameFontSize
        labelNode.fontColor = .ganhoUIBrandLight
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.position = .zero
        labelNode.zPosition = 101

        addChild(backgroundNode)
        addChild(labelNode)

        alpha = GameConfig.skillButtonActiveAlpha
        isUserInteractionEnabled = true   // SKNode는 default false — 명시 필수.
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    /// GameScene이 스킬 확정 시 라벨 갱신 + 김간호 빈 슬롯 처리.
    /// activeSkill == .none → isEnabled=false 자동 set.
    func configure(skill: PlayerSkill) {
        labelNode.text = skill.displayName
        setEnabled(skill != .none)
    }

    // MARK: - Enable / Disable
    /// 외부에서 호출. 시각(alpha) + 터치(isUserInteractionEnabled) 동시 갱신.
    /// 김간호 모드 진입 시 false. 일반 캐릭터는 항상 true.
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        alpha = enabled ? GameConfig.skillButtonActiveAlpha : GameConfig.skillButtonInactiveAlpha
        isUserInteractionEnabled = enabled
    }

    // MARK: - Touch
    /// 1탭 시 onTap 발화. touchesBegan만 사용 — touchesEnded 미사용(즉발 톤).
    /// 비활성 상태에선 isUserInteractionEnabled=false라 호출 자체가 안 옴(이중 가드 불필요).
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        onTap()
    }
}
