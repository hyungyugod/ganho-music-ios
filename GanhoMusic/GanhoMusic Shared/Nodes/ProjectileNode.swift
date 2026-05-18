//
//  ProjectileNode.swift
//  GanhoMusic Shared
//
//  Phase 2-7 · F 투사체 (수간호사가 player 방향으로 발사)
//  Phase 9-5 · 매혹(enchanted) 상태 추가 — 임간호 .charmStudent 스킬 발동 시 색·플래그 변경
//

import SpriteKit

/// F 투사체. 발사 시점 player 위치 향한 단위 벡터 × projectileSpeed velocity.
/// 벽/player와 contact 알림. collision=0(통과). GDD §7-5.
/// Phase 9-5 — 매혹 시 isEnchanted=true + color=.ganhoPinkNote.
/// ContactRouter.onProjectileHitPlayer 가드에서 enchanted 분기 → 수집 점수 가산 후 제거.
final class ProjectileNode: SKSpriteNode {

    // MARK: - State (Phase 9-5)
    /// 매혹(enchanted) 상태. true면 F가 *수집 가능한 A*로 분류 — 닿으면 점수 가산 + 제거.
    /// SkillSystem이 활성/만료 시점에 일괄 토글. ContactRouter 콜백이 이 플래그 가드.
    private(set) var isEnchanted: Bool = false

    // MARK: - Init
    init() {
        let size = CGSize(width: GameConfig.projectileSize, height: GameConfig.projectileSize)
        super.init(texture: nil, color: .ganhoYellowF, size: size)
        name = "projectile"
        zPosition = 5

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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Enchanted (Phase 9-5)
    /// 매혹 상태 진입. color를 분홍 노트와 동일색으로 갈아 끼움 — *F가 A로 변신*.
    /// 이미 enchanted여도 안전(멱등) — 단순 재대입.
    func applyEnchanted() {
        isEnchanted = true
        color = .ganhoPinkNote
    }

    /// 매혹 상태 해제. color 원복(.ganhoYellowF).
    /// 매혹 만료 후에도 화면에 남은 F가 정상 적으로 복귀.
    func clearEnchanted() {
        isEnchanted = false
        color = .ganhoYellowF
    }
}
