//
//  GameScene+Setup.swift
//  GanhoMusic Shared
//
//  GameScene의 노드 부착과 화면 고정 UI 레이아웃을 분리한다.
//  setup은 didMove(to:)에서 1회, layout은 size 변경 때마다 멱등으로 재계산한다.
//

import SpriteKit

// MARK: - Setup
extension GameScene {
    func setupBackground() {
        // Sprint 3 — v2 디자인 시스템(웜 피치) 인게임 통합.
        // GradientBackgroundNode 미사용 — 인게임은 카메라 follow가 있어 worldNode 자식 그라데이션이
        // 어색하게 따라 움직임. 단색 backgroundColor가 안정 (SPEC §4.4 / §2.1).
        backgroundColor = .ganhoBgWarmTop
    }

    func setupWorld() {
        worldNode.position = .zero
        addChild(worldNode)
        // Phase 9-4 — 체크보드 바닥. setupMap()보다 *먼저* 호출해서
        // 외곽 벽/기둥(z=0)이 자연스럽게 바닥(z=-100) 위에 얹히도록 한다.
        addCheckerboardFloor()
        // Sprint 10 Phase B — runtime compact 좌표 그릇 MapNode 부착. zPos -50(체크보드 위, 외곽벽 아래).
        // buildWalls(difficulty:)가 runtime tile helper로 벽을 채운다.
        worldNode.addChild(mapNode)
        setupMap()
    }

    /// Sprint 10 Phase C — 맵 구성 단일 진입점이 MapNode로 이동.
    /// MapNode.buildWalls(difficulty:)가 외곽 + easy 중앙 기둥 + hard 4 방·중앙 기둥을 일괄 부착.
    /// 옛 addOuterWalls/addCentralPillar/addHardMap/addNormalMap/addRectPillar/addHorizontalWall/
    /// addVerticalWall 7개 함수는 본 Phase에서 *함수 자체* 삭제(호출자 0건 검증 후).
    /// 외곽 라운드 보더 SKShapeNode도 함께 제거(OQ-1 — 원본 1:1 픽셀 톤 우선).
    func setupMap() {
        mapNode.buildWalls(difficulty: difficulty)
    }

    /// Phase 9-4 — 체크보드 바닥. 640개(mapColumns × mapRows = 32×20) SKSpriteNode를
    /// *컨테이너 한 개*에 자식으로 묶어 worldNode에 부착한다.
    /// physicsBody 0 부착(시각 전용), zPosition = checkerboardZPosition(-100).
    /// 호출은 setupWorld()에서 1회만 — update() 안 호출 금지(성능 핵심).
    private func addCheckerboardFloor() {
        let container = SKNode()
        container.name = GameConfig.checkerboardContainerName
        container.zPosition = GameConfig.checkerboardZPosition

        let t = GameConfig.tileSize
        let half = t / 2
        let floorA = UIColor.ganhoIngameFloorA
        let floorB = UIColor.ganhoIngameFloorB
        let tileSize = CGSize(width: t, height: t)

        for c in 0..<GameConfig.mapColumns {
            for r in 0..<GameConfig.mapRows {
                // 시장 패턴(market check): (c + r)의 홀짝성으로 두 색 교차.
                let color = ((c + r) % 2 == 0) ? floorA : floorB
                let tile = SKSpriteNode(color: color, size: tileSize)
                tile.position = CGPoint(
                    x: CGFloat(c) * t + half,
                    y: CGFloat(r) * t + half
                )
                // 시각 전용 — physicsBody 미부착. 640개 노드가 물리 시뮬에 들어가면 60fps 위협.
                container.addChild(tile)
            }
        }

        worldNode.addChild(container)
    }

    // Sprint 10 Phase C — 옛 빌더 함수 7개 본문 + 외곽 라운드 보더 SKShapeNode 삭제.
    // 제거된 함수: addHorizontalWall / addVerticalWall / addRectPillar / addOuterWalls /
    //             addCentralPillar / addHardMap / addNormalMap.
    // 호출자 0건 검증(grep 결과 SELF_CHECK §5) → setupMap의 단일 위임으로 책임 이동.
    // outerWallBorder* 상수도 호출자 0건 — GameConfig에 정의만 남되 본 Phase는 시각 사용 중단.

    func setupPlayer() {
        // Phase 2-6 hotfix 2 — 중앙 기둥(맵 정중앙)과 분리된 좌측 1/4 지점.
        // 기둥과 같은 좌표에서 시작 시 dynamic body 분리 force로 튕기는 잠재 버그 회피.
        player.position = CGPoint(
            x: GameConfig.mapWidth  / 4,
            y: GameConfig.mapHeight / 2
        )
        player.apply(characterID)   // Phase 5-R — 5-2(color) + 5-3(speedMultiplier) 단일 진입점으로 통합
        player.apply(difficulty)    // Phase 7-1 — 난이도별 baseSpeedStart/End set. character 먼저 → difficulty 나중(주의사항 1).
        player.wallCollisionProvider = { [weak self] rect in
            return self?.containsWall(in: rect) ?? false
        }
        player.wallRectProvider = { [weak self] rect in
            return self?.wallRects(intersecting: rect) ?? []
        }
        worldNode.addChild(player)
    }

    func setupCamera() {
        cameraNode.position = CGPoint(
            x: GameConfig.mapWidth  / 2,
            y: GameConfig.mapHeight / 2
        )
        addChild(cameraNode)
        camera = cameraNode   // 씬에 메인 카메라 통보 (필수)
        layoutCameraZoom()
    }

    func setupDPad() {
        // 1-3 신설 — DPadNode를 cameraNode 자식으로 추가. 위치는 layoutDPad가 담당.
        cameraNode.addChild(dpad)
        // Sprint 7 Phase G — DPad 입력 방향 → PlayerNode.facing(_:) 위임.
        // [weak self] 캡처 — 콜백 진행 중 씬 전환 가능성 대비(주의사항 5).
        dpad.onDirectionChanged = { [weak self] direction in
            self?.player.facing(direction)
        }
        layoutDPad()
    }

    func setupHUD() {
        cameraNode.addChild(hud)
        hud.applyReadableStyle()
        hud.setCharacterName(characterID.displayName)   // Phase 5-4 — TitleScene 선택 캐릭터 이름을 HUD 우상단에 1회 주입
        layoutHUD()
    }

    func setupEnemy() {
        // Sprint 10 Phase D — 추적 폐기 → 4지점 사각 순환 패트롤.
        //  · apply(difficulty)가 patrolWaypoints / patrolSpeed / burst / obs 속도 / fireInterval lerp 일괄 set.
        //  · 초기 위치는 selectInitialWaypoint(from:player.position)이 결정 — 플레이어로부터 가장 먼 waypoint.
        //    (옛 *맵 우상단* 하드코딩 폐기. 원본 game.js L2618~L2628 byte-equal.)
        //  · provider 4종 [weak self] 캡처 — 발사 시점에 player.position / 진행률 / charmActive를 실시간 조회.
        //    EnemyNode 인스턴스는 GameScene이 strong하게 보유하므로 메모리 누수 0.
        enemy.apply(difficulty)
        enemy.selectInitialWaypoint(from: player.position)
        enemy.targetProvider = { [weak self] in
            return self?.player.position ?? .zero
        }
        enemy.worldProvider = { [weak self] in
            return self?.worldNode
        }
        enemy.progressProvider = { [weak self] in
            guard let self = self else { return 0 }
            return Double(1.0 - self.remainingTime / GameConfig.gameDuration)
        }
        enemy.charmActiveProvider = { [weak self] in
            return self?.skillSystem.isCharmActive ?? false
        }
        worldNode.addChild(enemy)
    }

    func setupStoneGuard() {
        // Phase 9-8 — hard 난이도는 이교수 톤 집중. 석조무사 미등장 (GDD §7-6 "하/중 전용").
        // worldNode에 stoneGuard를 추가하지 않으므로 충돌 자체가 발생 0건 → 이스터에그 진입 0.
        guard difficulty != .hard else { return }
        // Sprint 10 Phase F — farthest-first 시작 정책. worldNode 부착 직후 selectInitialWaypoint이
        // 플레이어로부터 가장 먼 waypoint를 시작 위치로 결정 + startPatrolFrom으로 시퀀스 자동 시작.
        // 옛 *첫 waypoint(좌하단) 하드코딩* 폐기. 원본 game.js L3236~L3274 byte-equal.
        worldNode.addChild(stoneGuard)
        stoneGuard.selectInitialWaypoint(from: player.position)
    }

    // MARK: - Professor (Phase 9-7)
    /// 이교수(ProfessorNode) — 상 난이도 전용. easy/normal에서는 가드 통과 후 early return.
    /// 1) difficulty == .hard 가드 — easy/normal에선 professor=nil 유지(주의사항 1: easy/normal 회귀 0).
    /// 2) 첫 waypoint(좌하)에 위치 부여. ProfessorNode.init에서 patrol이 이미 시작됐으므로
    ///    첫 .move 액션은 (320, 200) → (640, 200) 우향으로 자동 진행.
    /// 3) startThrowingStethoscopes — targetProvider/progressProvider [weak self] 캡처 필수.
    func setupProfessor() {
        guard difficulty == .hard else { return }
        let node = ProfessorNode()
        node.warningProfile = GameConfig.warningProfileByDifficulty[difficulty] ?? GameConfig.warningProfileFallback
        worldNode.addChild(node)
        professor = node
        // 요청4 — 점대칭 스폰 정책. worldNode 부착 직후 spawnOpposite이 플레이어 스폰의
        // 점대칭(맵 중심 기준 정반대)을 시작 위치로 두고, 그 점 최근접 waypoint부터 8자 패트롤을 시작한다.
        // farthest-first(selectInitialWaypoint) 대비 정확히 정반대 → 등장 직후 즉사성 피격 완화.
        node.spawnOpposite(
            of: player.position,
            mapSize: CGSize(width: GameConfig.mapWidth, height: GameConfig.mapHeight)
        )
        // [weak self] 캡처 — 발사 루프 진행 중 씬 전환 가능성 대비.
        // self 해제 시 player.position nil → nil 반환 → throwStethoscope의 guard로 자연 noop.
        node.startThrowingStethoscopes(
            targetProvider: { [weak self] in self?.player.position },
            worldNode: worldNode,
            progressProvider: { [weak self] in
                guard let self = self else { return 0 }
                return Double(1.0 - self.remainingTime / GameConfig.gameDuration)
            }
        )
    }

    // MARK: - Skill Button (Phase 9-5)
    /// 우하단 SkillButtonNode를 cameraNode 자식으로 추가. D-Pad(좌하단)와 대칭.
    /// configure(skill:)로 라벨 + 김간호 비활성 상태 자동 set.
    /// onTap 콜백은 [weak self] 캡처 — SkillSystem.tryActivate 위임.
    func setupSkillButton() {
        cameraNode.addChild(skillButton)
        skillButton.configure(skill: characterID.skill)
        skillButton.onTap = { [weak self] in
            self?.skillSystem.tryActivate()
        }
        layoutSkillButton()
        // Sprint 8 Phase F — 본체 zPos 80 명시. HUD 라벨(100)·슬롯 라벨(110) 아래에 적층.
        skillButton.zPosition = GameConfig.skillButtonZPositionV4
    }

    // MARK: - Run Button (Sprint 11)
    /// 우하단 SkillButtonNode 왼쪽에 쿨타임 없는 hold-to-run 버튼을 부착한다.
    func setupRunButton() {
        cameraNode.addChild(runButton)
        runButton.onPressedChanged = { [weak self] pressed in
            self?.player.isRunning = pressed
        }
        layoutRunButton()
        runButton.zPosition = GameConfig.skillButtonZPositionV4
    }

    // MARK: - HUD Skill Slot (Phase 9-5)
    /// 우하단 SkillButtonNode 위에 HUDSkillSlotNode 부착(cameraNode 자식).
    /// configure(skill:)로 라벨 + 김간호 빈 슬롯 자동 set.
    func setupHUDSkillSlot() {
        cameraNode.addChild(hudSkillSlot)
        hudSkillSlot.configure(skill: characterID.skill)
        layoutHUDSkillSlot()
    }

    /// scene.size 변경 시 SkillButtonNode 위치 재계산. addChild 0건 — 멱등.
    /// cameraNode 자식 좌표계: (0,0) = 화면 중앙. 우하단 = (+x, -y).
    func layoutSkillButton() {
        let halfW = size.width  / 2
        let halfH = size.height / 2
        let safe = SceneSafeArea.insets(for: self)
        let scale = DeviceLayoutProfile.resolve(for: self).ingameControlScale
        skillButton.setScale(scale)
        let radius = max(GameConfig.skillButtonV2Radius, GameConfig.skillButtonRadius)
        let marginX = controlMargin(
            base: GameConfig.skillButtonMarginX,
            radius: radius,
            scale: scale
        )
        let marginY = controlMargin(
            base: GameConfig.skillButtonMarginY,
            radius: radius,
            scale: scale
        )
        skillButton.position = CGPoint(
            x: +(halfW - safe.right - marginX),
            y: -(halfH - safe.bottom - marginY)
        )
    }

    /// scene.size 변경 시 RunButtonNode 위치 재계산. SkillButton 왼쪽에 고정한다.
    func layoutRunButton() {
        let scale = DeviceLayoutProfile.resolve(for: self).ingameControlScale
        runButton.setScale(scale)
        runButton.position = CGPoint(
            x: skillButton.position.x - GameConfig.runButtonGapFromSkill * scale,
            y: skillButton.position.y
        )
    }

    /// scene.size 변경 시 HUDSkillSlotNode 위치 재계산. addChild 0건 — 멱등.
    /// SkillButtonNode 바로 위(hudSkillSlotOffsetY = 50pt 위).
    func layoutHUDSkillSlot() {
        let scale = DeviceLayoutProfile.resolve(for: self).ingameControlScale
        hudSkillSlot.setScale(scale)
        hudSkillSlot.position = CGPoint(
            x: skillButton.position.x,
            y: skillButton.position.y + GameConfig.hudSkillSlotOffsetY * scale
        )
    }

    // MARK: - Pause Button (Sprint 3 · 시각 placeholder)
    /// 우상단 PauseButtonNode를 cameraNode 자식으로 1회 부착.
    /// Sprint 3는 *시각 placeholder*만 — 실제 일시정지 로직 미구현(SPEC §1.IN.3 OUT 명시).
    /// PauseButtonNode.isUserInteractionEnabled = false → 터치 흡수 0 / D-Pad/스킬 버튼과 영향 0.
    func setupPauseButton() {
        cameraNode.addChild(pauseButton)
        layoutPauseButton()
    }

    /// scene.size 변경 시 PauseButtonNode 위치 재계산. addChild 0건 — 멱등.
    /// cameraNode 자식 좌표계: (0,0) = 화면 중앙. 우상단 = (+x, +y).
    func layoutPauseButton() {
        let halfW = size.width  / 2
        let halfH = size.height / 2
        let safe = SceneSafeArea.insets(for: self)
        let scale = DeviceLayoutProfile.resolve(for: self).ingameTopButtonScale
        pauseButton.setScale(scale)
        let radius = GameConfig.pauseButtonSize / 2
        let marginX = controlMargin(
            base: GameConfig.pauseButtonMarginX,
            radius: radius,
            scale: scale
        )
        let marginY = controlMargin(
            base: GameConfig.pauseButtonMarginY,
            radius: radius,
            scale: scale
        )
        pauseButton.position = CGPoint(
            x: +(halfW - safe.right - marginX),
            y: +(halfH - safe.top - marginY)
        )
    }

    // MARK: - Sergeant Park Debut (Sprint 8 Phase G)
    /// 박병장 hard 난이도 데뷔 흐름.
    /// GameScene.update에서 조건(30s OR 50점) 만족 시 1회 호출.
    /// 1) 컷씬 2.2초(얼굴 클로즈업 + "박병장 등장!" 토스트) 발화
    /// 2) 컷씬 종료 콜백에서 실제 SergeantParkNode를 worldNode에 부착
    /// 3) 화면 우측에서 들어와 중앙에서 8초 머무름 → 좌측으로 퇴장 → 자가 소멸
    /// gameState 전환 없음 — 컷씬 노드는 cameraNode 자식(zPos 300) 위에 깔리고 게임은 계속 진행.
    func spawnSergeantPark() {
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
            let stay  = SKAction.wait(forDuration: GameConfig.sergeantParkOnStageDurationV4)
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
        let toast = SKLabelNode(fontNamed: GameConfig.fontDisplay)
        toast.text = GameConfig.sergeantParkIntroToastText            // 하드코딩 제거 → 상수
        toast.fontSize = GameConfig.sergeantParkIntroToastFontSize    // 36 → 24 (긴 문장)
        toast.fontColor = .ganhoCoralPrimary
        // 긴 문장 줄바꿈 — 한 줄 폭 초과 방지(numberOfLines/lineBreakMode/maxWidth 3종 필수).
        toast.numberOfLines = 0
        toast.lineBreakMode = .byWordWrapping
        toast.preferredMaxLayoutWidth = GameConfig.sergeantParkIntroToastMaxWidth
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
        let hapticGap = SKAction.wait(forDuration: GameConfig.sergeantParkIntroHapticGap)
        overlay.run(.sequence([haptic1, hapticGap, haptic2]))

        // (2) 카메라 쉐이크 — cameraNode에 직접 run(자가 원위치 복귀).
        cameraNode.run(CameraShakeAction.make())

        // (3) 등장 플래시 — HitFlashNode 재사용(붉은 풀스크린, 자가 소멸). 컷씬 전용 zPos로 overlay 위에.
        let flash = HitFlashNode()
        flash.zPosition = GameConfig.sergeantParkIntroFlashZPosition
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
