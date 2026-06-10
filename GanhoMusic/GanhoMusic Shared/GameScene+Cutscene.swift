//
//  GameScene+Cutscene.swift
//  GanhoMusic Shared
//
//  Intro and mid-game cutscene flow for GameScene.
//

import SpriteKit

// MARK: - Cutscene
extension GameScene {
    func resetCutsceneStateAndShowIntro() {
        // Sprint 10 Phase H — UserDefaults 영구 스킵 제거. 원본 game.js처럼 매 판 Set을 리셋한다.
        cutscenesShown.removeAll()
        #if DEBUG
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
