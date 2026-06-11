//
//  GameScene+EasterEgg.swift
//  GanhoMusic Shared
//
//  AIRFORCE easter egg sequence for GameScene.
//

import SpriteKit

// MARK: - Easter Egg
extension GameScene {
    /// R11 U8-A — 정지형 스토리 컷씬 재구조: 발견 즉시 동결 → 휴면 카피(airforceStoryTitle/Body —
    /// 참조 0건 → 부활) 풀 서사 + 클로즈업/카메오 → 탭 dismiss 후 복원 + 공습 시퀀스 개시.
    /// 인트로 빌런 컷씬의 "절대 만나지 마세요" 거짓 경고가 "사실 오랜 친구"로 반전되는 서사를
    /// 45초 타이머 동결(플레이 시간 손실 0)로 읽게 한다. 공습 시퀀스 *내부 본문 무변경* —
    /// 호출 위치만 dismiss 콜백으로 이동 (함정: cameraNode 자식 SKAction은 동결 무시 —
    /// 트리거 직후에 두면 컷씬을 읽는 동안 비행기·폭탄이 뒤에서 지나가 버림 → dismiss 후 시작 필수).
    func triggerAirforceEasterEgg() {
        if airforceTriggered { return }
        if difficulty == .hard { return }
        airforceTriggered = true

        // 동결 — 물리 contact 콜백 내 발화 가능: 같은 didBegin 배치의 후속 콜백은 requestHitstop
        // `.cutscene` 가드가 점화를 차단, 수집 연출(SKAction)은 worldNode.isPaused로 정지 후
        // 복원 시 재개 — 일시정지 메뉴와 동일 시맨틱. 동결 내 노드 제거 없음.
        freezeForDiscoveryCutscene()

        let cutscene = CutsceneOverlayNode.present(
            title: FeelTuning.airforceStoryTitle,
            body: FeelTuning.airforceStoryBody,
            parent: cameraNode,
            sceneSize: size,
            fontName: Typography.pixelCutsceneFontName,
            onDismiss: { [weak self] in
                guard let self = self else { return }
                self.resumeFromDiscoveryCutscene()
                // 공습 시퀀스 — dismiss 시점을 t=0으로 상대 타이밍 그대로 보존
                // (오버레이 2.4s → 비행기 2.4s 지연 → 폭탄 3.4s).
                let overlay = AirforceOverlayNode()
                overlay.position = .zero
                self.cameraNode.addChild(overlay)
                overlay.showAndDismiss()
                self.startAirforceRescueSequence()
            }
        )

        // 시각 동승 — 박병장 클로즈업 + 석조무사 카메오 (hard 데뷔 컷씬과 시각 어휘 통일).
        // overlay *자식* 부착(택1 a) — fadeIn/fadeOut/removeFromParent 자동 동승: 컷씬 종료 후
        // 잔존 노드 0 (좀비 0). 본문 텍스트(중앙)와 비겹침 상단 측면 배치 — FeelTuning 상수.
        let closeup = SergeantParkNode.makeIntroCloseup()
        closeup.position = CGPoint(x: FeelTuning.airforceCutsceneCloseupOffsetX,
                                   y: FeelTuning.airforceCutsceneCloseupOffsetY)
        closeup.zPosition = FeelTuning.airforceCutsceneDecorationZPosition
        cutscene.addChild(closeup)

        let cameo = StoneGuardNode()
        cameo.physicsBody = nil   // 시각 전용 — 충돌/이동 비대상 (R10 데뷔 컷씬 카메오 동형)
        cameo.setScale(FeelTuning.R10.sergeantIntroCameoScale)
        cameo.position = CGPoint(x: FeelTuning.airforceCutsceneCameoOffsetX,
                                 y: FeelTuning.airforceCutsceneCameoOffsetY)
        cameo.zPosition = FeelTuning.airforceCutsceneDecorationZPosition
        cutscene.addChild(cameo)
    }

    private func startAirforceRescueSequence() {
        let sergeant = SergeantParkNode.makeIntroCloseup()
        sergeant.zPosition = ZOrder.sergeantCloseupZPosition
        sergeant.alpha = 0
        sergeant.position = CGPoint(x: 0, y: FeelTuning.sergeantCloseupOffsetY)
        cameraNode.addChild(sergeant)
        let sergeantFadeIn = SKAction.fadeIn(withDuration: FeelTuning.sergeantCloseupFadeInDuration)
        let sergeantStay = SKAction.wait(forDuration: FeelTuning.sergeantCloseupStayDuration)
        let sergeantFadeOut = SKAction.fadeOut(withDuration: FeelTuning.sergeantCloseupFadeOutDuration)
        let sergeantCleanup = SKAction.removeFromParent()
        sergeant.run(.sequence([sergeantFadeIn, sergeantStay, sergeantFadeOut, sergeantCleanup]))

        // R10 U6 C-2 — 우정 상호 인사 (*추가만* — 기존 구조 시퀀스 타이밍·로직 0 변경).
        // 두 캐릭터가 실제로 만나는 유일한 순간: 석조무사(월드) ↔ 박병장 클로즈업(카메라).
        // 1회 발화는 airforceTriggered(판당 1회 가드)가 이미 보장 — 신규 플래그·UserDefaults 키 0.
        if stoneGuard.parent != nil {
            FriendGreetingNode.spawn(
                text: FeelTuning.R10.friendGreetingStoneGuardText,
                accent: .ganhoStoneGuardLight,
                at: CGPoint(x: 0, y: FeelTuning.R10.friendGreetingStoneGuardOffsetY),
                zPosition: FeelTuning.R10.friendGreetingLocalZPosition,
                parent: stoneGuard,   // 본체 자식 — 패트롤 이동을 자동 추종 ("머리 위" 유지)
                delay: 0
            )
        }
        FriendGreetingNode.spawn(
            text: FeelTuning.R10.friendGreetingSergeantText,
            accent: .ganhoAirforceTeal,
            at: CGPoint(x: FeelTuning.R10.friendGreetingSergeantOffsetX,
                        y: FeelTuning.sergeantCloseupOffsetY
                            + FeelTuning.R10.friendGreetingSergeantOffsetY),
            zPosition: FeelTuning.R10.friendGreetingOverlayZPosition,
            parent: cameraNode,
            delay: FeelTuning.R10.friendGreetingSecondDelay
        )
        // 스파크 1회 — 박병장 답인사 시점, 클로즈업 위치에서 방사 (SparkleEffectNode 자가 소멸).
        let waitGreetSpark = SKAction.wait(forDuration: FeelTuning.R10.friendGreetingSecondDelay)
        let attachGreetSpark = SKAction.run { [weak self] in
            guard let self = self else { return }
            let spark = SparkleEffectNode()
            spark.position = CGPoint(x: 0, y: FeelTuning.sergeantCloseupOffsetY)
            spark.zPosition = ZOrder.sergeantCloseupZPosition
            self.cameraNode.addChild(spark)
            spark.emit()
        }
        cameraNode.run(.sequence([waitGreetSpark, attachGreetSpark]))

        enemy.startFleeing(duration: GameplayTuning.enemyFleeDuration) { [weak self] in
            guard let self = self else { return }
            let target = self.spawnSystem.currentObstaclesTarget
            // R1 — 구 enumerateChildNodes("projectile") 카운트 → registry 캐시 조회 (대상 동일).
            let currentF = self.registry.projectiles.count
            let deficit = max(0, target - currentF)
            for _ in 0..<deficit {
                self.spawnSystem.fireImmediately()
            }
        }

        let plane = AirplaneNode()
        let planeY = +(size.height / 2 - FeelTuning.airplaneTopOffset)
        let waitPlane = SKAction.wait(forDuration: FeelTuning.airplaneDelayAfterOverlay)
        let attachPlane = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.cameraNode.addChild(plane)
            plane.crossScreen(sceneWidth: self.size.width, atY: planeY)
        }
        cameraNode.run(.sequence([waitPlane, attachPlane]))

        let bomb = BombFlashNode()
        cameraNode.addChild(bomb)
        bomb.flash(sceneSize: size)

        let waitPurge = SKAction.wait(forDuration: FeelTuning.bombFlashDelay)
        let attachPurge = SKAction.run { [weak self] in
            self?.spawnSystem.purgeAllF()
            // R2 — 폭탄 섬광 시점(bombFlashDelay 도달 = fadeIn 시작) 히트스톱 0.12s (02 §2).
            // 일시정지 중이면 requestHitstop 가드가 무시 (cameraNode 액션은 일시정지에도 진행됨).
            self?.requestHitstop(freeze: FeelTuning.hitstopBombFlash)
        }
        cameraNode.run(.sequence([waitPurge, attachPurge]))
    }
}
