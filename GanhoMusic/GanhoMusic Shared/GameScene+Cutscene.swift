//
//  GameScene+Cutscene.swift
//  GanhoMusic Shared
//
//  Intro and mid-game cutscene flow for GameScene.
//  R11 U8 — 박병장 발견 컷씬 공용 동결/복원 헬퍼 쌍 (+GameState 281줄 → 300줄 위험 회피로 본 파일에).
//

import SpriteKit

// MARK: - Discovery Cutscene Freeze/Resume (R11 U8)
extension GameScene {
    /// 발견 컷씬 동결 — presentPauseMenu(+GameState L25-47) 레시피와 항목·순서 1:1 대응
    /// (다이얼로그·uiTap SFX/햅틱만 제외). pauseStored* 트리오 *재사용* — presentPauseMenu는
    /// `.playing` 한정 가드라 `.cutscene` 중 경합이 구조적으로 불가, 신규 var 0.
    /// `.cutscene` 중 자동 보장(코드 추가 불요): 45초 타이머·AI·스폰 폴링·near-miss·effects는
    /// update() `.playing` 가드에서 동결 / 자동 일시정지(R9)·일시정지 버튼은 `.playing` 가드로
    /// 자연 차단 / 컷씬 오버레이는 cameraNode 부착이라 worldNode.isPaused 무관하게 애니 정상.
    func freezeForDiscoveryCutscene() {
        // 순서 계약(주의사항 3) — hitstop.cancel()이 isPaused/speed 소유권을 먼저 인수(원복).
        // cancel *이전*에 isPaused를 세팅하면 cancel의 원복이 덮어쓴다 — presentPauseMenu 전례 순서.
        hitstop.cancel()
        gameState = .cutscene
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
    }

    /// 발견 컷씬 복원 — dismissPauseMenu(+GameState L92-108) 레시피 *정확히 역순* (다이얼로그 제외).
    func resumeFromDiscoveryCutscene() {
        worldNode.isPaused = false
        physicsWorld.speed = 1
        dpad.resetDirection()
        resetMovementInput()
        runButton.resetPressedState()
        dpad.isUserInteractionEnabled = pauseStoredDPadInteractionEnabled
        skillButton.isUserInteractionEnabled = pauseStoredSkillInteractionEnabled
        runButton.isUserInteractionEnabled = pauseStoredRunInteractionEnabled
        lastUpdateTime = 0   // dt 폭주 방지 — dismissPauseMenu L106 전례
        gameState = .playing
    }
}

// MARK: - Cutscene
extension GameScene {
    func resetCutsceneStateAndShowIntro() {
        // Sprint 10 Phase H — UserDefaults 영구 스킵 제거. 원본 game.js처럼 매 판 Set을 리셋한다.
        cutscenesShown.removeAll()
        #if DEBUG
        // R8 — T6 일시정지 스크린샷용 자동 일시정지 (simctl 터치 주입 불가 우회 —
        // GANHO_SKIP_CUTSCENE 전례 동형, 릴리즈 경로 0). GANHO_SKIP_CUTSCENE=1 조합 필수 —
        // 컷씬 경로면 3초 시점이 .cutscene이라 presentPauseMenu의 .playing 가드가 무시(안전망).
        // 지연 노드는 cameraNode — worldNode 비소속이라 게임 동결과 무관하게 발화.
        if ProcessInfo.processInfo.environment["GANHO_AUTO_PAUSE"] == "1" {
            let wait = SKAction.wait(forDuration: FeelTuning.R8.debugAutoPauseDelay)
            let pause = SKAction.run { [weak self] in self?.presentPauseMenu() }
            cameraNode.run(.sequence([wait, pause]))
        }
        // R6 — 성능 게이트 자동 측정용 컷씬 스킵 (simctl 탭 주입 불가 우회 — GANHO_BOOT_SCENE 전례).
        // 릴리즈 경로 0 영향 (#if DEBUG + env 게이트 이중 격리).
        if ProcessInfo.processInfo.environment["GANHO_SKIP_CUTSCENE"] == "1" {
            gameState = .countdown
            showCountdown()
            return
        }
        #endif
        gameState = .cutscene
        showIntroCutscene()
    }

    func triggerMidCutsceneIfNeeded() -> Bool {
        // Sprint 4 — 플레이 중단형 mid 컷씬은 feature flag로 비활성화한다.
        guard FeelTuning.enableMidGameCutscenes else { return false }

        // 원본 game.js L2417/L2469와 같은 임계값 및 1회 가드.
        if !cutscenesShown.contains("mid1"),
           remainingTime <= FeelTuning.cutsceneMid1Threshold {
            cutscenesShown.insert("mid1")
            gameState = .cutscene
            MidCutsceneNode.presentMid1(scene: self, character: characterID) { [weak self] in
                self?.gameState = .playing
            }
            return true
        }

        if !cutscenesShown.contains("mid2"),
           remainingTime <= FeelTuning.cutsceneMid2Threshold {
            cutscenesShown.insert("mid2")
            gameState = .cutscene
            MidCutsceneNode.presentMid2(scene: self) { [weak self] in
                self?.gameState = .playing
            }
            return true
        }

        return false
    }

    func showIntroCutscene() {
        IntroCutsceneNode.present(
            scene: self,
            character: characterID,
            difficulty: difficulty,
            onDismiss: { [weak self] in
                guard let self = self else { return }
                self.cutscenesShown.insert("intro")
                IntroVillainCutsceneNode.present(
                    scene: self,
                    difficulty: self.difficulty,
                    onDismiss: { [weak self] in
                        guard let self = self else { return }
                        switch self.difficulty {
                        case .easy, .normal:
                            self.cutscenesShown.insert("introStoneGuard")
                        case .hard:
                            self.cutscenesShown.insert("introProfessor")
                        }
                        self.gameState = .countdown
                        self.showCountdown()
                    }
                )
            }
        )
    }
}
