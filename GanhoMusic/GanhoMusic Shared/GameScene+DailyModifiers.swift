//
//  GameScene+DailyModifiers.swift
//  GanhoMusic Shared
//
//  R8 §B③ — GameScene+Setup.swift(625줄) 분할 ③: R6 일일 모디파이어 배선(R6 이관
//  "모디파이어 배선 extension 분리" 이행) + Sprint 8 박병장 데뷔 연출 흐름.
//  코드 이동만 — 로직/시그니처 0 변경.
//

import SpriteKit

// MARK: - Daily Modifier & Sergeant Park Debut (R8 분할)
extension GameScene {

    // MARK: - Daily Modifier (R6 §F7)
    /// 일일 모디파이어 배선 단일 진입점 — didMove에서 setupEnemy/setupStoneGuard/setupProfessor
    /// *이후* 1회 호출 (speed_night가 apply(difficulty) 완료된 patrolSpeed에 배율을 곱는 계약).
    /// 거울 병동의 맵·스폰 반전은 setupMap/setupPlayer가 자체 처리 (등장 배치 순서 계약).
    /// nil(일반 판)이면 HUD 표식 포함 노드 0 생성 — 기존 동작 byte-동일 (좀비 금지).
    func setupDailyModifier() {
        guard let modifier = dailyModifier else { return }
        // 공통 — SpawnSystem 주입 (음표 러시·황금 변기는 내부에서만 반응. apply보다 선행 계약).
        spawnSystem.configureDailyModifier(modifier)
        switch modifier {
        case .speedNight:
            // 적 *이동* 속도 ×1.2 — 수간호사(physics velocity)는 전용 훅, 석조무사는 순수
            // SKAction move 구동이라 node.speed 배율이 정확히 이동 ×1.2 (다른 액션 없음).
            // 이교수는 제외 — 청진기 투척 루프가 같은 노드 SKAction이라 node.speed가
            // 공격 빈도까지 가속(SPEC "이동 속도" 범위 초과). SELF_CHECK 기재.
            enemy.applyDailySpeedScale(MetaTuning.speedNightEnemySpeedScale)
            stoneGuard.speed = MetaTuning.speedNightEnemySpeedScale
        case .noteRush, .mirrorWard:
            break   // 각각 SpawnSystem.apply / setupMap·setupPlayer에서 적용 완료.
        case .lightsOut:
            attachLightsOutVignette()
        case .goldenToilet:
            scoreSystem.toiletScoreScale = MetaTuning.goldenToiletScoreScale
        case .fullSpirit:
            skillSystem.cooldownScale = MetaTuning.fullSpiritCooldownScale
        }
        attachDailyModifierHUDChip(modifier)
    }

    /// 소등 — 시야 축소 비네트 (cameraNode 부착 1노드, TensionVignetteNode 패턴 답습).
    /// 중앙 시야 창(화면 최소 변 × 0.58)만 남기고 4면을 어둡게 — tension 비네트(z=110)와
    /// zPos 분리(105)·동시 존재 허용. 정적 가림막 — 깜빡임 없음 ("소등"의 항상성).
    private func attachLightsOutVignette() {
        let container = SKNode()
        container.name = "lightsOutVignette"
        container.zPosition = UILayout.R6.lightsOutVignetteZPosition
        let window = min(size.width, size.height) * MetaTuning.lightsOutWindowRatio
        let alpha = MetaTuning.lightsOutShroudAlpha
        let sideWidth = max(0, (size.width - window) / 2)
        let bandHeight = max(0, (size.height - window) / 2)
        // 상/하 가로 막대 (전체 폭) + 좌/우 세로 막대 (중앙 창 높이만큼) — L자 겹침 없는 액자.
        let top = SKSpriteNode(color: .black, size: CGSize(width: size.width, height: bandHeight))
        top.position = CGPoint(x: 0, y: (size.height - bandHeight) / 2)
        let bottom = SKSpriteNode(color: .black, size: CGSize(width: size.width, height: bandHeight))
        bottom.position = CGPoint(x: 0, y: -(size.height - bandHeight) / 2)
        let left = SKSpriteNode(color: .black, size: CGSize(width: sideWidth, height: window))
        left.position = CGPoint(x: -(size.width - sideWidth) / 2, y: 0)
        let right = SKSpriteNode(color: .black, size: CGSize(width: sideWidth, height: window))
        right.position = CGPoint(x: (size.width - sideWidth) / 2, y: 0)
        for shroud in [top, bottom, left, right] {
            shroud.alpha = alpha
            container.addChild(shroud)
        }
        cameraNode.addChild(container)
    }

    /// 인게임 도전 표식 — 화면 상단 중앙 작은 칩 1요소 (노드 +1, 도전 중 상시 인지).
    private func attachDailyModifierHUDChip(_ modifier: DailyModifier) {
        let chip = PixelChipNode(text: modifier.displayName, style: .accent(Palette.gold))
        chip.zPosition = UILayout.R6.ingameDailyChipZPosition
        let safe = SceneSafeArea.insets(for: self)
        chip.position = CGPoint(
            x: 0,
            y: (size.height / 2 - safe.top - UILayout.R6.ingameDailyChipTopInset
                - chip.chipSize.height / 2).rounded()
        )
        cameraNode.addChild(chip)
    }

    // MARK: - Sergeant Park Debut (Sprint 8 Phase G)
    /// 박병장 hard 난이도 데뷔 흐름.
    /// GameScene.update에서 조건(30s OR 50점) 만족 시 1회 호출.
    /// 1) 컷씬 2.2초(얼굴 클로즈업 + "박병장 등장!" 토스트) 발화
    /// 2) 컷씬 종료 콜백에서 실제 SergeantParkNode를 worldNode에 부착
    /// 3) 화면 우측에서 들어와 중앙에서 8초 머무름 → 좌측으로 퇴장 → 자가 소멸
    /// gameState 전환 없음 — 컷씬 노드는 cameraNode 자식(zPos 300) 위에 깔리고 게임은 계속 진행.
    func spawnSergeantPark() {
        // R2 — 박병장 등장 줌 펄스 1.0→0.97→1.0 (0.5s, 02 §3) — *거물 등장*의 무게감.
        cameraDirector.zoomPulse(to: FeelTuning.sergeantZoomPulseScale,
                                 duration: FeelTuning.sergeantZoomPulseDuration)
        // 컷씬 먼저 → 콜백에서 본 노드 부착. [weak self] 캡처 — 컷씬 진행 중 씬 전환 가능성 대비.
        presentSergeantParkIntro { [weak self] in
            guard let self = self else { return }
            let park = SergeantParkNode()
            // 화면 우측 바깥에서 출발 → 좌로 진입.
            park.position = CGPoint(
                x: self.size.width + 100,
                y: self.size.height * 0.5
            )
            park.zPosition = 5
            self.worldNode.addChild(park)

            // 등장(1.2s) → 머무름(8.0s) → 퇴장(1.5s) → 자가 소멸.
            // SKAction.sequence 5단계 — DispatchQueue/Timer 금지(주의사항).
            let enter = SKAction.moveTo(x: self.size.width * 0.5,
                                        duration: 1.2)
            let stay  = SKAction.wait(forDuration: GameplayTuning.sergeantParkOnStageDuration)
            let exit  = SKAction.moveTo(x: -100, duration: 1.5)
            let cleanup = SKAction.removeFromParent()
            park.run(.sequence([enter, stay, exit, cleanup]))
        }
    }

    /// 박병장 컷씬 2.2초 (얼굴 클로즈업 + "박병장 등장!" 토스트).
    /// CutsceneOverlayNode 재사용 안 함 — 본 컷씬은 짧고 시각 단일하므로 inline overlay.
    /// 0.0~0.4s fadeIn → 0.4~1.8s hold → 1.8~2.2s fadeOut → completion 호출.
    /// [weak self] 캡처는 호출자(spawnSergeantPark)가 이미 처리.
    private func presentSergeantParkIntro(then completion: @escaping () -> Void) {
        let overlay = SKNode()
        overlay.zPosition = 300

        // dim — 화면 전체 어두운 반투명 layer (코드 가독성 위해 size 명시).
        let dim = SKSpriteNode(color: .ganhoNavyDeep, size: size)
        dim.alpha = 0
        overlay.addChild(dim)

        // 박병장 큰 얼굴 — physicsBody nil, scale 2.0배 클로즈업.
        let closeup = SergeantParkNode.makeIntroCloseup()
        closeup.alpha = 0
        overlay.addChild(closeup)

        // 토스트 — 긴 서사 멘트 상수화 + 멀티라인 줄바꿈(36→24pt). coralPrimary.
        let toast = SKLabelNode(fontNamed: Typography.fontDisplay)
        toast.text = FeelTuning.sergeantParkIntroToastText            // 하드코딩 제거 → 상수
        toast.fontSize = FeelTuning.sergeantParkIntroToastFontSize    // 36 → 24 (긴 문장)
        toast.fontColor = .ganhoCoralPrimary
        // 긴 문장 줄바꿈 — 한 줄 폭 초과 방지(numberOfLines/lineBreakMode/maxWidth 3종 필수).
        toast.numberOfLines = 0
        toast.lineBreakMode = .byWordWrapping
        toast.preferredMaxLayoutWidth = FeelTuning.sergeantParkIntroToastMaxWidth
        toast.horizontalAlignmentMode = .center
        toast.verticalAlignmentMode = .center                        // 다줄 수직 중심 안정
        toast.position = CGPoint(x: 0, y: -120)
        toast.alpha = 0
        overlay.addChild(toast)

        cameraNode.addChild(overlay)

        // 컷씬 등장 임팩트 강화 (요청 2) — 햅틱 + 이펙트 3종. 모두 overlay/cameraNode에 *추가*만.
        // 기존 dim/closeup/toast fade 시퀀스(0.4/1.4/0.4=2.2s)·completion 콜백은 0줄 변경.
        // (1) 묵직한 진동 heavy 2회 — Timer/DispatchQueue 금지, SKAction.sequence 경유. [weak self] 필수.
        let haptic1 = SKAction.run { [weak self] in self?.haptics.heavy() }
        let haptic2 = SKAction.run { [weak self] in self?.haptics.heavy() }
        let hapticGap = SKAction.wait(forDuration: FeelTuning.sergeantParkIntroHapticGap)
        overlay.run(.sequence([haptic1, hapticGap, haptic2]))

        // (2) 카메라 쉐이크 — R2: CameraDirector 감쇠 셰이크 (구 SKAction 셰이크 빌더 삭제).
        cameraDirector.shake(.medium)

        // (3) 등장 플래시 — HitFlashNode 재사용(붉은 풀스크린, 자가 소멸). 컷씬 전용 zPos로 overlay 위에.
        let flash = HitFlashNode()
        flash.zPosition = ZOrder.sergeantParkIntroFlashZPosition
        cameraNode.addChild(flash)
        flash.flash(sceneSize: size)

        // (4) closeup 주변 반짝임 — SparkleEffectNode 8방향 방사(자가 소멸). 얼굴 중심에서 방사.
        let sparkle = SparkleEffectNode()
        sparkle.position = closeup.position
        overlay.addChild(sparkle)
        sparkle.emit()

        // 0.4s fadeIn / 1.4s hold / 0.4s fadeOut = 2.2s 총 길이.
        // sergeantParkIntroDurationV4(2.2s)와 정확히 일치.
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.4)
        let hold = SKAction.wait(forDuration: 1.4)
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.4)
        let dimFadeIn = SKAction.fadeAlpha(to: 0.5, duration: 0.4)

        dim.run(.sequence([dimFadeIn, hold, fadeOut]))
        closeup.run(.sequence([fadeIn, hold, fadeOut]))
        toast.run(.sequence([fadeIn, hold, fadeOut, .run {
            overlay.removeFromParent()
            completion()
        }]))
    }
}
