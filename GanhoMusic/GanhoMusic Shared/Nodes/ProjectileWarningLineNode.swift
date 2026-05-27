//
//  ProjectileWarningLineNode.swift
//  GanhoMusic Shared
//
//  Pre-shot trajectory warning lines for F projectiles and stethoscopes.
//

import SpriteKit

final class ProjectileWarningLineNode: SKNode {

    init(angles: [CGFloat], length: CGFloat, color: UIColor, alpha: CGFloat) {
        super.init()
        name = "projectileWarningLine"
        zPosition = GameConfig.projectileWarningLineZPosition
        self.alpha = alpha
        for angle in angles {
            addLine(angle: angle, length: length, color: color)
        }
        runPulse()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addLine(angle: CGFloat, length: CGFloat, color: UIColor) {
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: cos(angle) * length, y: sin(angle) * length))

        let line = SKShapeNode(path: path)
        line.strokeColor = color
        line.lineWidth = GameConfig.projectileWarningLineWidth
        line.lineCap = .round
        line.fillColor = .clear
        line.zPosition = 0
        addChild(line)
    }

    private func runPulse() {
        let fadeDown = SKAction.fadeAlpha(to: alpha * GameConfig.projectileWarningLinePulseMinRatio,
                                          duration: GameConfig.projectileWarningLinePulseHalfDuration)
        let fadeUp = SKAction.fadeAlpha(to: alpha,
                                        duration: GameConfig.projectileWarningLinePulseHalfDuration)
        run(.repeatForever(.sequence([fadeDown, fadeUp])),
            withKey: GameConfig.projectileWarningLinePulseActionKey)
    }
}
