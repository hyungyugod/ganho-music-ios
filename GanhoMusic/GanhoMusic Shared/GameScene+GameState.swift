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
        player.isRunning = false
        player.physicsBody?.velocity = .zero
        pauseStoredDPadInteractionEnabled = dpad.isUserInteractionEnabled
        pauseStoredSkillInteractionEnabled = skillButton.isUserInteractionEnabled
        pauseStoredRunInteractionEnabled = runButton.isUserInteractionEnabled
        dpad.resetDirection()
        resetMovementInput()
        runButton.resetPressedState()
        dpad.isUserInteractionEnabled = false
        skillButton.isUserInteractionEnabled = false
        runButton.isUserInteractionEnabled = false
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

        let title = SKLabelNode(fontNamed: Typography.fontDisplay)
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
        resetMovementInput()
        runButton.resetPressedState()
        dpad.isUserInteractionEnabled = pauseStoredDPadInteractionEnabled
        skillButton.isUserInteractionEnabled = pauseStoredSkillInteractionEnabled
        runButton.isUserInteractionEnabled = pauseStoredRunInteractionEnabled
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
        professor?.stopThrowing()
        // R1 — 잔존 청진기 velocity 0: 구 stopThrowing 내부 enumerate의 registry 대체.
        // easy/normal은 청진기 0개 → 빈 배열 순회 자연 noop (professor=nil 시맨틱과 동일).
        for stethoscope in registry.stethoscopes {
            stethoscope.physicsBody?.velocity = .zero
        }
        dpad.resetDirection()
        resetMovementInput()
        runButton.resetPressedState()
        dpad.isUserInteractionEnabled = pauseStoredDPadInteractionEnabled
        skillButton.isUserInteractionEnabled = pauseStoredSkillInteractionEnabled
        runButton.isUserInteractionEnabled = pauseStoredRunInteractionEnabled
        player.currentDirection = .zero
        player.isRunning = false
        player.physicsBody?.velocity = .zero
        enemy.physicsBody?.velocity = .zero

        guard let view = self.view else { return }
        let scene = CharacterSelectScene.newCharacterSelectScene()
        view.presentScene(scene, transition: .fade(withDuration: FeelTuning.sceneTransitionDuration))
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
        professor?.stopThrowing()
        // R1 — 잔존 청진기 velocity 0: 구 stopThrowing 내부 enumerate의 registry 대체.
        for stethoscope in registry.stethoscopes {
            stethoscope.physicsBody?.velocity = .zero
        }
        player.currentDirection = .zero
        player.isRunning = false
        resetMovementInput()
        runButton.resetPressedState()
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
        let cloudRecord = CloudScoreRecord(
            localID: UUID().uuidString,
            characterID: characterID.rawValue,
            difficulty: difficulty.rawValue,
            score: score,
            maxCombo: maxComboThisRun,
            airforceTriggered: airforceTriggered,
            playedAt: Date()
        )
        let cloudProgress = CloudProgressSnapshot.make(
            highScore: bestScore,
            stats: stats,
            perDifficultyScores: perDiffRepo.current,
            graduations: graduationRepo.current
        )
        Task {
            await CloudSaveCoordinator.shared.saveGameResult(
                record: cloudRecord,
                progress: cloudProgress
            )
        }
        let resultScene = ResultScene.newResultScene(
            score: score, bestScore: bestScore, isNewBest: isNewBest, stats: stats,
            characterName: characterID.displayName,
            difficulty: difficulty,
            isNewGraduation: isNewGraduation,
            graduatedAt: graduatedAt
        )
        view.presentScene(resultScene, transition: .fade(withDuration: FeelTuning.sceneTransitionDuration))
    }

    private static func isGraduated(characterID: CharacterID,
                                    scores repo: PerDifficultyScoreRepository) -> Bool {
        let targets = GameplayTuning.targetScoreByDifficulty
        for difficulty in Difficulty.allCases {
            let target = targets[difficulty] ?? Int.max
            if repo.best(characterID: characterID, difficulty: difficulty) < target {
                return false
            }
        }
        return true
    }
}
