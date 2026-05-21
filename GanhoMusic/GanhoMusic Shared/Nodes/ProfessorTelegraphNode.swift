//
//  ProfessorTelegraphNode.swift
//  GanhoMusic Shared
//
//  Sprint 10 Phase F · 이교수 머리 위 "!" 텔레그래프
//
//  원본 game.js L3084~L3106 byte-equal — 0.4s 동안 ".ganhoCoralPrimary" 색 SKLabel
//  120ms 주기 on/off 깜빡임. EnemyTelegraphNode 패턴 동형 — 색만 코럴(이교수 시각 일관성).
//
//  ProfessorNode가 throwStethoscope() 진입 시 부착 → professorTelegraphDuration(0.4s) 후
//  자기 자신 removeFromParent + fireStethoscope 발화.
//

import SpriteKit

/// 이교수가 청진기를 던지기 직전 머리 위에 떠오르는 "!" 경고 마크.
/// EnemyTelegraphNode와 동일 구조 — 색만 .ganhoCoralPrimary로 분리(이교수 코럴 시각 일관성).
/// 0.4초 동안 SKLabel이 120ms 주기로 on/off 깜빡임 (SKAction.repeatForever).
/// 부착 시점: ProfessorNode.throwStethoscope() — 텔레그래프 시퀀스 진입 시 1회 부착.
/// 제거 시점: 0.4s wait 종료 직후 fireStethoscope 호출 전 removeFromParent.
final class ProfessorTelegraphNode: SKNode {

    // MARK: - State
    /// 깜빡일 라벨. zPos 1 → 부모(ProfessorNode) 픽셀 텍스처 위에 또렷이 노출.
    private let label: SKLabelNode

    // MARK: - Init
    override init() {
        // EnemyTelegraphNode와 동형 — 32pt fontDisplay 강조 폰트.
        label = SKLabelNode(fontNamed: GameConfig.fontDisplay)
        super.init()
        label.text = "!"
        label.fontSize = 32
        // SPEC §8.3 — 색만 .ganhoCoralPrimary(코럴) — 수간호사(다크 #ff3b4e)와 시각 분리.
        label.fontColor = .ganhoCoralPrimary
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
    /// Timer 금지(주의사항) — SKAction 경유.
    /// startBlinking 호출 직후 0.4s 대기 시퀀스가 끝나면 호출부가 removeFromParent → 액션도 정리.
    /// EnemyTelegraphNode.startBlinking 패턴 정확 답습 — interval 토큰도 nurseChief와 공유.
    func startBlinking() {
        let on = SKAction.fadeAlpha(to: 1.0, duration: 0)
        let off = SKAction.fadeAlpha(to: 0.0, duration: 0)
        let wait = SKAction.wait(forDuration: GameConfig.nurseChiefTelegraphBlinkInterval)
        let blink = SKAction.repeatForever(.sequence([on, wait, off, wait]))
        run(blink, withKey: "blink")
    }
}
