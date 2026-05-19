//
//  ProjectileNode.swift
//  GanhoMusic Shared
//
//  Phase 2-7 · F 투사체 (수간호사가 player 방향으로 발사)
//  Phase 9-5 · 매혹(enchanted) 상태 추가 — 임간호 .charmStudent 스킬 발동 시 색·플래그 변경
//  Sprint 3 · v2 디자인 시스템 — 본체 .clear + 코랄 22pt 라운드 사각형 자식 + 흰 "F" 라벨 + -12° 회전
//

import SpriteKit

/// F 투사체. 발사 시점 player 위치 향한 단위 벡터 × projectileSpeed velocity.
/// 벽/player와 contact 알림. collision=0(통과). GDD §7-5.
/// Phase 9-5 — 매혹 시 isEnchanted=true + body 색을 분홍 노트와 동일색으로 갈아 끼움.
/// ContactRouter.onProjectileHitPlayer 가드에서 enchanted 분기 → 수집 점수 가산 후 제거.
/// Sprint 3 — SKSpriteNode 본체는 .clear, 시각은 자식 SKShape(22×22 라운드)와 "F" 라벨로 위임.
/// **PhysicsBody size = projectileSize(16) 절대 보존. 시각 자식 22pt와 분리.**
/// **applyEnchanted/clearEnchanted 시그니처 0 변경 — body.fillColor 교체로 시각 옮김.**
final class ProjectileNode: SKSpriteNode {

    // MARK: - State (Phase 9-5)
    /// 매혹(enchanted) 상태. true면 F가 *수집 가능한 A*로 분류 — 닿으면 점수 가산 + 제거.
    /// SkillSystem이 활성/만료 시점에 일괄 토글. ContactRouter 콜백이 이 플래그 가드.
    private(set) var isEnchanted: Bool = false

    // MARK: - Sprint 3 v2 시각 자식
    /// 코랄 22×22 라운드 사각형. applyEnchanted/clearEnchanted가 이 노드의 fillColor를 갈아 끼움.
    private let visualBody: SKShapeNode

    // MARK: - Init
    init() {
        let size = CGSize(width: GameConfig.projectileSize, height: GameConfig.projectileSize)

        // Sprint 3 — 시각 자식 SKShape 22pt 라운드 사각형 (PhysicsBody와 분리).
        let visualSize = CGSize(
            width: GameConfig.projectileV2VisualSize,
            height: GameConfig.projectileV2VisualSize
        )
        visualBody = SKShapeNode(
            rectOf: visualSize,
            cornerRadius: GameConfig.projectileV2CornerRadius
        )

        // Sprint 3 — 본체 색은 .clear. 시각은 자식 SKShape + SKLabel로 위임.
        super.init(texture: nil, color: .clear, size: size)
        name = "projectile"
        zPosition = 5

        // PhysicsBody 부착. **size = projectileSize²(16) 절대 보존**.
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic           = true
        body.allowsRotation      = false
        body.friction            = 0
        body.restitution         = 0
        body.linearDamping       = 0
        body.categoryBitMask     = PhysicsCategory.projectile
        body.collisionBitMask    = 0   // 통과 (벽에 막혀서 그 자리에 멈추는 버그 회피)
        body.contactTestBitMask  = PhysicsCategory.player | PhysicsCategory.wall
        physicsBody = body

        // 시각 자식 설정.
        visualBody.fillColor = .ganhoCoralShadow
        visualBody.strokeColor = .clear
        visualBody.zPosition = 0
        addChild(visualBody)

        // 흰 "F" 라벨 — 22pt 자식 중앙.
        let fLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
        fLabel.text = GameConfig.projectileV2LabelText
        fLabel.fontSize = GameConfig.projectileV2LabelFontSize
        fLabel.fontColor = .white
        fLabel.verticalAlignmentMode = .center
        fLabel.horizontalAlignmentMode = .center
        fLabel.zPosition = 1
        addChild(fLabel)

        // 살짝 비스듬한 회전 — *시각 자식에만* 적용해서 PhysicsBody hitbox는
        // 축정렬 16×16 그대로 보존.
        let rot = GameConfig.projectileV2RotationDegrees * .pi / 180
        visualBody.zRotation = rot
        fLabel.zRotation = rot
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Enchanted (Phase 9-5 · Sprint 3 v2)
    /// 매혹 상태 진입. 자식 SKShape의 fillColor를 분홍 노트와 동일색(.ganhoPinkNote)으로 갈아 끼움 —
    /// *F가 A로 변신*. Sprint 3 — 본체 color → 자식 visualBody.fillColor로 시각만 이전. 시그니처/타이밍 0 변경.
    /// 이미 enchanted여도 안전(멱등) — 단순 재대입.
    func applyEnchanted() {
        isEnchanted = true
        visualBody.fillColor = .ganhoPinkNote
    }

    /// 매혹 상태 해제. fillColor 원복(.ganhoCoralShadow v2).
    /// 매혹 만료 후에도 화면에 남은 F가 정상 적으로 복귀.
    func clearEnchanted() {
        isEnchanted = false
        visualBody.fillColor = .ganhoCoralShadow
    }
}
