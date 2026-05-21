//
//  EnemyTelegraphNode.swift
//  GanhoMusic Shared
//
//  Sprint 10 Phase D · 수간호사 머리 위 "!" 텔레그래프
//
//  원본 game.js L960~L974 byte-equal — 다크 #ff3b4e, 120ms on/off 깜빡임.
//  EnemyNode가 enterTelegraph()에서 부착 → telegraphDuration(0.4s) 후 enterIdle에서 제거.
//

import SpriteKit

/// 수간호사가 F를 던지기 직전 머리 위에 떠오르는 "!" 경고 마크.
/// 0.4초 동안 다크 #ff3b4e 색 SKLabel이 120ms 주기로 on/off 깜빡임 (SKAction.repeatForever).
/// 부착 시점: EnemyNode.enterTelegraph() — telegraphRemaining = 0 도달 후 enterIdle에서 removeFromParent.
final class EnemyTelegraphNode: SKNode {

    // MARK: - State
    /// 깜빡일 라벨. zPos 1 → 부모(EnemyNode) 픽셀 텍스처 위에 또렷이 노출.
    private let label: SKLabelNode

    // MARK: - Init
    override init() {
        // PlayerSkill 등 본체 패턴(GameConfig.fontDisplay)과 동형. 32pt 강조 폰트.
        label = SKLabelNode(fontNamed: GameConfig.fontDisplay)
        super.init()
        label.text = "!"
        label.fontSize = 32
        label.fontColor = GameConfig.nurseChiefTelegraphColor
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Blink
    /// 120ms on/off 깜빡임 시작. SKAction.repeatForever → 노드 제거 시 자동 정리.
    /// Timer 금지 (주의사항 — 매직 넘버 0/GameConfig 경유).
    /// enterTelegraph 호출 직후 1회 호출. enterIdle에서 노드 자체 removeFromParent로 액션도 정리.
    func startBlinking() {
        let on = SKAction.fadeAlpha(to: 1.0, duration: 0)
        let off = SKAction.fadeAlpha(to: 0.0, duration: 0)
        let wait = SKAction.wait(forDuration: GameConfig.nurseChiefTelegraphBlinkInterval)
        let blink = SKAction.repeatForever(.sequence([on, wait, off, wait]))
        run(blink, withKey: "blink")
    }
}
