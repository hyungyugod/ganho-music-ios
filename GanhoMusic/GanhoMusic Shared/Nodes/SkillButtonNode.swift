//
//  SkillButtonNode.swift
//  GanhoMusic Shared
//
//  Phase 9-5 · 좌하단 스킬 버튼 (1탭 발동)
//  Sprint 3 · v2 디자인 시스템 — 코랄 원 36 + 흰 stroke + "B" 칩 + 스킬명 칩
//
//  cameraNode 자식 — 화면 고정. D-Pad(우하단)와 대칭 위치(좌하단).
//  김간호 선택 시 isUserInteractionEnabled=false + alpha 0.3 + 라벨 "—".
//

import SpriteKit

/// 4 캐릭터 능동 스킬 1탭 발동 버튼. v2: 36pt 반지름 코랄 원형 + B 키 칩 + 스킬명 칩.
/// 외부(GameScene)가 onTap 콜백 등록 → 탭 시 SkillSystem.tryActivate() 호출.
/// setEnabled(false)로 김간호 모드 진입 — 시각/터치 모두 비활성.
/// Sprint 3 — 외부 시그니처 (`onTap`/`isEnabled`/`configure(skill:)`/`setEnabled(_:)`/`touchesBegan`) 완전 보존.
final class SkillButtonNode: SKNode {

    // MARK: - Properties
    /// 1탭 시 호출되는 콜백. GameScene이 `[weak self] in self?.skillSystem.tryActivate()` 등록.
    /// default = {} → 등록 누락 시에도 안전(noop).
    var onTap: () -> Void = {}

    private let backgroundNode: SKShapeNode
    private let labelNode: SKLabelNode
    /// Sprint 3 — 우상단 "B" 키 칩 (DarkContextChipNode).
    /// configure에서 1회 부착(스킬 무관). nil 가능성 0 → non-optional.
    private let keyLabelChip: DarkContextChipNode
    /// Sprint 3 — 본체 아래 스킬명 칩. configure에서 매번 교체(스킬 따라 텍스트 변경).
    /// 첫 생성 후엔 nil 아님. configure가 호출되지 않는 케이스 0 (GameScene이 setup 시 1회 호출).
    private var nameTagChip: DarkContextChipNode?

    /// 활성/비활성 상태. setEnabled가 단일 진입점.
    private(set) var isEnabled: Bool = true

    // MARK: - Init
    override init() {
        // Sprint 3 — v2 디자인 시스템 36pt 반지름 코랄 원.
        backgroundNode = SKShapeNode(circleOfRadius: GameConfig.skillButtonV2Radius)
        labelNode = SKLabelNode(fontNamed: GameConfig.fontDisplay)
        labelNode.text = "SKILL"
        // "B" 키 칩 — 우상단. 본체와 같이 회전/scale 영향 받음(자식이므로 자연).
        keyLabelChip = DarkContextChipNode(label: GameConfig.skillButtonKeyText)
        super.init()

        // 배경 원 — 코랄 fill + 흰 α 0.8 stroke. v2 톤.
        backgroundNode.fillColor = .ganhoCoralPrimary
        backgroundNode.strokeColor = UIColor.white.withAlphaComponent(0.8)
        backgroundNode.lineWidth = GameConfig.skillButtonV2StrokeWidth
        backgroundNode.position = .zero
        backgroundNode.zPosition = 100

        // 중앙 라벨 — 18pt Jua 흰색.
        labelNode.fontSize = 18
        labelNode.fontColor = .white
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.position = .zero
        labelNode.zPosition = 101

        // "B" 키 칩 — 우상단. 본체로부터 (+offset, +offset) 위치.
        keyLabelChip.position = CGPoint(
            x: +GameConfig.skillButtonV2KeyLabelOffset,
            y: +GameConfig.skillButtonV2KeyLabelOffset
        )
        keyLabelChip.zPosition = 102

        addChild(backgroundNode)
        addChild(labelNode)
        addChild(keyLabelChip)

        // Sprint 8 Phase F — 본체 스킬 이름 라벨 시각 차단. HUDSkillSlotNode가 단일 진실 원천.
        // 노드 트리 보존 (Sprint 4 PNG 통합 대비 — 의사결정 #6 패턴) — isHidden만 토글.
        // labelNode는 isUserInteractionEnabled = false default → hit-test 영향 0.
        labelNode.isHidden = true

        alpha = GameConfig.skillButtonActiveAlpha
        isUserInteractionEnabled = true   // SKNode는 default false — 명시 필수.
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    /// GameScene이 스킬 확정 시 라벨 갱신 + 김간호 빈 슬롯 처리.
    /// activeSkill == .none → isEnabled=false 자동 set.
    /// Sprint 3 — 스킬명 칩 텍스트도 매번 새로 생성/교체 (DarkContextChipNode는 라벨 변경 메서드 미제공).
    func configure(skill: PlayerSkill) {
        labelNode.text = skill.displayName
        setEnabled(skill != .none)

        // 기존 nameTagChip 제거 후 새 텍스트로 재생성.
        nameTagChip?.removeFromParent()
        let chipLabel = skill.displayName
        let chip = DarkContextChipNode(label: chipLabel)
        chip.position = CGPoint(x: 0, y: GameConfig.skillButtonNameChipOffsetY)
        chip.zPosition = 102
        // Sprint 8 Phase F — 본체 아래 스킬 이름 칩 시각 차단. HUDSkillSlotNode가 단일 진실 원천.
        // 노드 트리 보존(addChild 유지) + isHidden=true로 시각만 차단.
        chip.isHidden = true
        addChild(chip)
        nameTagChip = chip
    }

    // MARK: - Enable / Disable
    /// 외부에서 호출. 시각(alpha) + 터치(isUserInteractionEnabled) 동시 갱신.
    /// 김간호 모드 진입 시 false. 일반 캐릭터는 항상 true.
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        alpha = enabled ? GameConfig.skillButtonActiveAlpha : GameConfig.skillButtonInactiveAlpha
        backgroundNode.fillColor = enabled ? .ganhoCoralPrimary : .ganhoIngameControlDisabled
        backgroundNode.strokeColor = enabled
            ? UIColor.ganhoPixelHudYellow
            : UIColor.ganhoPixelHudWhite.withAlphaComponent(GameConfig.skillButtonInactiveStrokeAlpha)
        labelNode.fontColor = enabled ? .ganhoPixelHudWhite : .ganhoPixelHudWhite.withAlphaComponent(0.5)
        isUserInteractionEnabled = enabled
    }

    // MARK: - Touch
    /// 1탭 시 onTap 발화. touchesBegan만 사용 — touchesEnded 미사용(즉발 톤).
    /// 비활성 상태에선 isUserInteractionEnabled=false라 호출 자체가 안 옴(이중 가드 불필요).
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        onTap()
    }
}
