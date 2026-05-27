//
//  GameScene+GameState.swift
//  GanhoMusic Shared
//
//  Game over transition and graduation checks for GameScene.
//

import SpriteKit

// MARK: - Game State
extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: cameraNode)

        if pauseOverlay != nil {
            if pauseResumeButton?.contains(location) == true {
                dismissPauseMenu()
                return
            }
            if pauseMenuButton?.contains(location) == true {
                exitToMainMenu()
                return
            }
            return
        }

        if gameState == .playing, pauseButton.contains(location) {
            presentPauseMenu()
        }
    }

    func presentPauseMenu() {
        guard pauseOverlay == nil, gameState == .playing else { return }
        gameState = .paused
        player.currentDirection = .zero
        player.physicsBody?.velocity = .zero
        pauseStoredDPadInteractionEnabled = dpad.isUserInteractionEnabled
        pauseStoredSkillInteractionEnabled = skillButton.isUserInteractionEnabled
        dpad.resetDirection()
        dpad.isUserInteractionEnabled = false
        skillButton.isUserInteractionEnabled = false
        worldNode.isPaused = true
        physicsWorld.speed = 0

        let overlay = SKNode()
        overlay.zPosition = 420
        overlay.name = "pauseOverlay"

        let dim = SKSpriteNode(color: .ganhoNavyDeep, size: size)
        dim.alpha = 0.42
        dim.zPosition = 0
        overlay.addChild(dim)

        let panelSize = CGSize(width: 300, height: 176)
        let panel = SKShapeNode(rectOf: panelSize, cornerRadius: 24)
        panel.fillColor = UIColor.white.withAlphaComponent(0.92)
        panel.strokeColor = UIColor.ganhoCoralPrimary.withAlphaComponent(0.28)
        panel.lineWidth = 1.5
        panel.zPosition = 1
        overlay.addChild(panel)

        let title = SKLabelNode(fontNamed: GameConfig.fontDisplay)
        title.text = "일시정지"
        title.fontSize = 28
        title.fontColor = .ganhoNavyDeep
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: 52)
        title.zPosition = 2
        overlay.addChild(title)

        let resume = PrimaryButtonNode(text: "계속")
        resume.position = CGPoint(x: -78, y: -34)
        resume.setScale(0.72)
        resume.zPosition = 3
        overlay.addChild(resume)

        let menu = PrimaryButtonNode(text: "메인")
        menu.position = CGPoint(x: 78, y: -34)
        menu.setScale(0.72)
        menu.zPosition = 3
        overlay.addChild(menu)

        pauseOverlay = overlay
        pauseResumeButton = resume
        pauseMenuButton = menu
        cameraNode.addChild(overlay)
    }

    func dismissPauseMenu() {
        guard gameState == .paused else { return }
        pauseOverlay?.removeFromParent()
        pauseOverlay = nil
        pauseResumeButton = nil
        pauseMenuButton = nil
        worldNode.isPaused = false
        physicsWorld.speed = 1
        dpad.resetDirection()
        dpad.isUserInteractionEnabled = pauseStoredDPadInteractionEnabled
        skillButton.isUserInteractionEnabled = pauseStoredSkillInteractionEnabled
        lastUpdateTime = 0
        gameState = .playing
    }

    func exitToMainMenu() {
        gameState = .gameOver
        pauseOverlay?.removeFromParent()
        pauseOverlay = nil
        pauseResumeButton = nil
        pauseMenuButton = nil
        worldNode.isPaused = false
        physicsWorld.speed = 1
        bgm.stop()
        hud.stopTensionBlink()
        tensionVignette?.removeFromParent()
        tensionVignette = nil
        spawnSystem.stop()
        professor?.stopThrowing(worldNode: worldNode)
        dpad.resetDirection()
        dpad.isUserInteractionEnabled = pauseStoredDPadInteractionEnabled
        skillButton.isUserInteractionEnabled = pauseStoredSkillInteractionEnabled
        player.currentDirection = .zero
        player.physicsBody?.velocity = .zero
        enemy.physicsBody?.velocity = .zero

        guard let view = self.view else { return }
        let scene = StartScene.newStartScene()
        view.presentScene(scene, transition: .fade(withDuration: GameConfig.sceneTransitionDuration))
    }

    func endGame() {
        if gameState == .gameOver { return }
        gameState = .gameOver
        haptics.heavy()
        audio.play(.gameOver)
        bgm.stop()
        hud.stopTensionBlink()
        tensionVignette?.removeFromParent()
        tensionVignette = nil
        spawnSystem.stop()
        professor?.stopThrowing(worldNode: worldNode)
        player.currentDirection = .zero
        player.physicsBody?.velocity = .zero
        enemy.physicsBody?.velocity = .zero
        hud.update(score: scoreSystem.score, remainingTime: 0, combo: 0)

        guard let view = self.view else { return }
        let score = scoreSystem.score
        let isNewBest = highScoreRepo.record(score)
        let bestScore = highScoreRepo.current
        statsRepo.recordPlay(score: score)
        let stats = statsRepo.current

        perDiffRepo.record(characterID: characterID, difficulty: difficulty, score: score)
        var isNewGraduation = false
        if GameScene.isGraduated(characterID: characterID, scores: perDiffRepo) {
            isNewGraduation = graduationRepo.record(characterID: characterID, date: Date())
        }
        let graduatedAt = graduationRepo.graduatedAt(characterID: characterID)
        let resultScene = ResultScene.newResultScene(
            score: score, bestScore: bestScore, isNewBest: isNewBest, stats: stats,
            characterName: characterID.displayName,
            difficulty: difficulty,
            isNewGraduation: isNewGraduation,
            graduatedAt: graduatedAt
        )
        view.presentScene(resultScene, transition: .fade(withDuration: GameConfig.sceneTransitionDuration))
    }

    private static func isGraduated(characterID: CharacterID,
                                    scores repo: PerDifficultyScoreRepository) -> Bool {
        let targets = GameConfig.targetScoreByDifficulty
        for difficulty in Difficulty.allCases {
            let target = targets[difficulty] ?? Int.max
            if repo.best(characterID: characterID, difficulty: difficulty) < target {
                return false
            }
        }
        return true
    }
}
