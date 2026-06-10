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
        // R2 — 히트스톱 즉시 cancel (원복 책임 단일화): 아래 worldNode.isPaused/physicsWorld.speed
        // 소유권을 일시정지가 인수. 일시정지 중 신규 요청은 requestHitstop 가드가 무시.
        hitstop.cancel()
        synth.play(.uiTap)
        haptics.uiTap()
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
        synth.play(.uiTap)
        haptics.uiTap()
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
        synth.play(.uiTap)
        haptics.uiTap()
        // R2 — 잔존 히트스톱 원복 (일시정지 경유라 실질 idle이지만 소유권 정리 일관성).
        hitstop.cancel()
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
        SceneRouter.present(scene, on: view, route: .backward)
    }

    func endGame() {
        if gameState == .gameOver { return }
        gameState = .gameOver
        // R2 — 게임오버 햅틱 v2(transient 1.0 + continuous 0.5/0.3s) + 피격 voice(noise+square 하강).
        // 피격 연출(히트스톱 램프/strong 셰이크/킥/deathBurst)은 호출 직전의 피격 피드백 함수가 담당.
        haptics.gameOver()
        synth.play(.hit)
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
        // 게임오버 후 update가 gameOver 분기로 빠져 comboAura 폴링이 중단됨 —
        // 콤보 ≥5 사망 시 오라가 0.9s 지연 동안 잔존 방출하지 않도록 즉시 회수(combo 0 = detach).
        effectDirector.updateComboAura(combo: 0, playerPosition: player.position)

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
        // R5 — characterID 직접 전달(역추론 우회 소멸) + maxCombo/notesCollected 추가 (§7 칩 2개).
        let resultScene = ResultScene.newResultScene(
            score: score, bestScore: bestScore, isNewBest: isNewBest, stats: stats,
            characterID: characterID,
            difficulty: difficulty,
            maxCombo: maxComboThisRun,
            notesCollected: scoreSystem.notesCollected,
            isNewGraduation: isNewGraduation,
            graduatedAt: graduatedAt
        )
        // R2 — 게임오버 연출 지연 전환 (SPEC §문서-코드 불일치 7): 저장/클라우드/Result 파라미터
        // 로직은 위에서 전부 즉시 수행(0줄 변경) — presentScene만 0.9s 지연.
        // 지연 노드는 cameraNode — worldNode 비소속이라 히트스톱 일시정지 영향 0 (asyncAfter 금지).
        let wait = SKAction.wait(forDuration: FeelTuning.gameOverTransitionDelay)
        let present = SKAction.run { [weak view] in
            guard let view = view else { return }
            SceneRouter.present(resultScene, on: view, route: .forward)
        }
        cameraNode.run(.sequence([wait, present]))
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
