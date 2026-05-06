//
//  NoteNode.swift
//  GanhoMusic Shared
//
//  Phase 2-3 · 분홍 음표 노드 (PhysicsCategory.note + .ganhoPinkNote 첫 활성화)
//

import SpriteKit

/// 분홍 16×16 음표 ♪. 맵에 떠 있고, 박스(PlayerNode)가 닿으면 사라짐.
/// PhysicsBody는 static — player와 *contact 알림*만 받고 *collision*은 0 (통과).
/// 본 단계가 collision↔contact 분리의 첫 사례.
final class NoteNode: SKSpriteNode {

    // MARK: - Init
    init() {
        let size = CGSize(width: GameConfig.noteSize, height: GameConfig.noteSize)
        super.init(texture: nil, color: .ganhoPinkNote, size: size)
        name = "note"

        // PhysicsBody 부착 — static, player에게는 통과(collision=0), 알림만(contactTest)
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic           = false
        body.categoryBitMask     = PhysicsCategory.note
        body.collisionBitMask    = 0                          // player를 막지 않음
        body.contactTestBitMask  = PhysicsCategory.player     // 닿으면 알림
        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
