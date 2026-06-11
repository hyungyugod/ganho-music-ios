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

        // R8 — 다이얼로그 노출 중 씬 레벨 입력 차단 (딤이 배후 흡수 — StartScene loginDialog
        // 가드 동형). 버튼은 PixelButtonNode onTap 자체 처리라 contains 분기 불요.
        guard pauseDialog == nil else { return }

        if gameState == .playing, pauseButton.contains(location) {
            presentPauseMenu()
        }
    }

    func presentPauseMenu() {
        guard pauseDialog == nil, gameState == .playing else { return }
        gameState = .paused
        // R2 — 히트스톱 즉시 cancel (원복 책임 단일화): 아래 worldNode.isPaused/physicsWorld.speed
        // 소유권을 일시정지가 인수. 일시정지 중 신규 요청은 requestHitstop 가드가 무시.
        hitstop.cancel()
        // 일시정지 버튼 탭(씬 레벨 contains 판정)의 피드백 — PixelButtonNode 비경유라 수동 발화 유지.
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

        // R8 — v3 다이얼로그 (LoginChoiceDialogNode 조립 전례 동형). cameraNode 부착 —
        // worldNode 비소속이라 일시정지(isPaused) 중에도 등장 애니 정상 구동.
        // PixelDialogNode 딤이 배후 터치 흡수 + 위 인터랙션 차단과 이중 방어 (주의사항 2 —
        // 기존 저장/복원 로직 제거 금지, 행동 보존).
        let dialog = PixelDialogNode(panelSize: UILayout.R8.pausePanelSize,
                                     title: UILayout.R8.pauseTitleText,
                                     accent: Palette.gold)
        dialog.zPosition = ZOrder.pauseDialogZPosition

        let resume = PixelButtonNode(title: UILayout.R8.pauseResumeText,
                                     variant: .primary,
                                     size: UILayout.R8.pauseButtonSize,
                                     haptics: haptics)
        // 연타 안전 — 첫 발화에서 pauseDialog가 nil이 되어 이중 resume 불가
        // (dismissPauseMenu의 .paused 가드와 이중 방어).
        resume.onTap = { [weak self] in self?.dismissPauseMenu() }
        resume.position = CGPoint(x: -UILayout.R8.pauseButtonOffsetX,
                                  y: UILayout.R8.pauseButtonRowY)
        dialog.contentNode.addChild(resume)

        let exit = PixelButtonNode(title: UILayout.R8.pauseExitText,
                                   variant: .ghost,
                                   size: UILayout.R8.pauseButtonSize,
                                   haptics: haptics)
        exit.onTap = { [weak self] in self?.exitToMainMenu() }
        exit.position = CGPoint(x: UILayout.R8.pauseButtonOffsetX,
                                y: UILayout.R8.pauseButtonRowY)
        dialog.contentNode.addChild(exit)

        // R9 #1 진입점 ② — [설정] ghost 와이드 1개, 패널 중앙부 빈 공간 (제목 아래~버튼 행 위).
        // 기존 pausePanelSize·pauseButtonRowY 불변. 제시는 +AppLifecycle 소유.
        let settings = PixelButtonNode(title: UILayout.R9.settingsTitleText,
                                       variant: .ghost,
                                       size: UILayout.R9.pauseSettingsButtonSize,
                                       haptics: haptics)
        settings.onTap = { [weak self] in self?.presentInGameSettingsDialog() }
        settings.position = CGPoint(x: 0, y: UILayout.R9.pauseSettingsRowY)
        dialog.contentNode.addChild(settings)

        pauseDialog = dialog
        dialog.present(in: cameraNode, screenSize: size)
    }

    func dismissPauseMenu() {
        guard gameState == .paused else { return }
        // R8 — uiTap SFX/햅틱은 PixelButtonNode가 자체 발화 — 수동 발화 제거 (이중 발화 0).
        // 게임 상태는 즉시 복원(기존 시맨틱 보존), dialog.dismiss 0.22s 페이드는 cosmetic.
        pauseDialog?.dismiss()
        pauseDialog = nil
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
        // R8 — uiTap SFX/햅틱은 PixelButtonNode가 자체 발화 — 수동 발화 제거 (이중 발화 0).
        // R2 — 잔존 히트스톱 원복 (일시정지 경유라 실질 idle이지만 소유권 정리 일관성).
        hitstop.cancel()
        // 씬 전환 직전 — dismiss 애니 불요, 즉시 제거 (좀비 0).
        pauseDialog?.removeFromParent()
        pauseDialog = nil
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
        // R7 §F3 — 콤보 게이지도 확실히 소거 (combo 0 표기와 동기 — 점멸 잔존 0).
        hud.updateComboGauge(fraction: nil)
        // 게임오버 후 update가 gameOver 분기로 빠져 comboAura 폴링이 중단됨 —
        // 콤보 ≥5 사망 시 오라가 0.9s 지연 동안 잔존 방출하지 않도록 즉시 회수(combo 0 = detach).
        effectDirector.updateComboAura(combo: 0, playerPosition: player.position)

        guard let view = self.view else { return }
        let score = scoreSystem.score
        // R7 §F6 — 캐릭터 해금 사전 스냅샷: 저장 5종 *이전*의 라이브 OR 판정 (잠금→해금 전이
        // 기준점). 영속 0 — 라이브 OR 원칙(R6 §F3) 그대로, 해금 상태 저장 금지.
        let unlockedBefore = CharacterID.allCases.filter {
            CharacterUnlockRules.isUnlocked($0,
                                            graduations: graduationRepo.current,
                                            scores: perDiffRepo.current,
                                            totalStars: metaRepo.totalStars)
        }
        let isNewBest = highScoreRepo.record(score)
        let bestScore = highScoreRepo.current
        statsRepo.recordPlay(score: score)
        let stats = statsRepo.current

        perDiffRepo.record(characterID: characterID, difficulty: difficulty, score: score)
        var isNewGraduation = false
        // R7 §F8-a — 졸업 판정 분리: *기록*은 base 목표 전용(즉시 — noteRush 판 score ∈ [base, eff)
        // 에서도 그 판에 기록, 이연 없음), *졸업장 연출*은 실효 목표 성공 판 한정 AND 게이트 —
        // "유급 verdict + 졸업장 연출 동시 표시"가 구조적으로 불가능 (R6 QA P2-1 봉인).
        // 기록됐으나 연출이 억제된 셀은 이후 재연출 없음(정적 graduatedAt 표시는 기존대로) —
        // 의도된 트레이드오프 (연출·보상 언어는 성공 판 원칙).
        if GameScene.isGraduated(characterID: characterID, scores: perDiffRepo) {
            let isFirstRecord = graduationRepo.record(characterID: characterID, date: Date())
            isNewGraduation = isFirstRecord && score >= effectiveTargetScore
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
            graduations: graduationRepo.current,
            meta: metaRepo.cloudMeta()   // R6 §F4 — 이번 판 메타는 다음 flush/sync가 운반 (SPEC 순서 계약)
        )
        Task {
            await CloudSaveCoordinator.shared.saveGameResult(
                record: cloudRecord,
                progress: cloudProgress
            )
        }
        // R6 §F9 — 기존 저장 5종(highScore→stats→perDiff→graduation→cloud) *직후* 메타 기록 1회.
        // 즉시 실행 구간 — 0.9s 지연 블록 밖 (앱 강제 종료 시 유실 방지, SPEC §주의사항 3).
        let runSummary = RunSummary(
            characterID: characterID,
            difficulty: difficulty,
            score: score,
            maxCombo: maxComboThisRun,
            comboBreaks: scoreSystem.comboBreaks,
            notesCollected: scoreSystem.notesCollected,
            toiletsCollected: scoreSystem.toiletsCollected,
            skillActivations: skillSystem.activationCount,
            sergeantParkAppeared: sergeantParkDebuted || airforceTriggered,
            dailyModifier: dailyModifier,
            effectiveTarget: effectiveTargetScore,
            playedDayKey: DailyChallenge.todayKey(),
            unlockedCharactersBefore: unlockedBefore   // R7 §F6 — 저장 5종 이전 스냅샷
        )
        let runMeta = metaRepo.recordRun(runSummary)
        // R5 — characterID 직접 전달(역추론 우회 소멸) + maxCombo/notesCollected 추가 (§7 칩 2개).
        let resultScene = ResultScene.newResultScene(
            score: score, bestScore: bestScore, isNewBest: isNewBest, stats: stats,
            characterID: characterID,
            difficulty: difficulty,
            maxCombo: maxComboThisRun,
            notesCollected: scoreSystem.notesCollected,
            isNewGraduation: isNewGraduation,
            graduatedAt: graduatedAt,
            runMeta: runMeta
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

    /// R7 §F8-a — base 목표 *전용* 회귀 (R6의 played-difficulty max(base, eff) 분기 제거,
    /// 인자 단순화). noteRush 판에서 score ∈ [base, eff)여도 base 충족은 인정 — 졸업 기록이
    /// 다음 일반 판으로 이연되지 않으므로 "다음 판 유급 + 졸업장 동시 표시" 엣지 자체가 소멸.
    /// 실효 목표는 *연출 게이트*(endGame의 isNewGraduation AND 조건)만 담당.
    private static func isGraduated(characterID: CharacterID,
                                    scores repo: PerDifficultyScoreRepository) -> Bool {
        for difficulty in Difficulty.allCases {
            let target = GameplayTuning.targetScoreByDifficulty[difficulty] ?? Int.max
            if repo.best(characterID: characterID, difficulty: difficulty) < target {
                return false
            }
        }
        return true
    }
}
