//
//  GameScene+SetupActors.swift
//  GanhoMusic Shared
//
//  R8 §B③ — GameScene+Setup.swift(625줄) 분할 ②: 이교수·스킬/달리기 버튼·HUD 스킬 슬롯·
//  일시정지 버튼 셋업/레이아웃. 코드 이동만 — 로직/시그니처 0 변경.
//

import SpriteKit

// MARK: - Actor & Control Setup (R8 분할)
extension GameScene {

    // MARK: - Professor (Phase 9-7)
    /// 이교수(ProfessorNode) — 상 난이도 전용. easy/normal에서는 가드 통과 후 early return.
    /// 1) difficulty == .hard 가드 — easy/normal에선 professor=nil 유지(주의사항 1: easy/normal 회귀 0).
    /// 2) 첫 waypoint(좌하)에 위치 부여. ProfessorNode.init에서 patrol이 이미 시작됐으므로
    ///    첫 .move 액션은 (320, 200) → (640, 200) 우향으로 자동 진행.
    /// 3) startThrowingStethoscopes — targetProvider/progressProvider [weak self] 캡처 필수.
    func setupProfessor() {
        guard difficulty == .hard else { return }
        let node = ProfessorNode()
        node.warningProfile = GameplayTuning.warningProfileByDifficulty[difficulty] ?? GameplayTuning.warningProfileFallback
        worldNode.addChild(node)
        professor = node
        // 요청4 — 점대칭 스폰 정책. worldNode 부착 직후 spawnOpposite이 플레이어 스폰의
        // 점대칭(맵 중심 기준 정반대)을 시작 위치로 두고, 그 점 최근접 waypoint부터 8자 패트롤을 시작한다.
        // farthest-first(selectInitialWaypoint) 대비 정확히 정반대 → 등장 직후 즉사성 피격 완화.
        node.spawnOpposite(
            of: player.position,
            mapSize: CGSize(width: GameplayTuning.mapWidth, height: GameplayTuning.mapHeight)
        )
        // R1 — 청진기 실체화/카운트 provider. EnemyNode provider 컨벤션 동형.
        node.stethoscopeProvider = { [weak self] in
            guard let self = self else { return StethoscopeNode() }
            return self.obtainPooledStethoscope()
        }
        node.stethoscopeCountProvider = { [weak self] in
            return self?.registry.stethoscopes.count ?? 0
        }
        // R2 — 투척 시점 콜백: soft 셰이크 + 근거리 텔레그래프 햅틱 (EnemyNode.onFired 동형).
        node.onFired = { [weak self] origin in
            self?.playTelegraphFireFeedback(from: origin)
        }
        // [weak self] 캡처 — 발사 루프 진행 중 씬 전환 가능성 대비.
        // self 해제 시 player.position nil → nil 반환 → throwStethoscope의 guard로 자연 noop.
        node.startThrowingStethoscopes(
            targetProvider: { [weak self] in self?.player.position },
            worldNode: worldNode,
            progressProvider: { [weak self] in
                guard let self = self else { return 0 }
                return Double(1.0 - self.remainingTime / GameplayTuning.gameDuration)
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
        skillButton.zPosition = ZOrder.skillButtonZPosition
    }

    // MARK: - Run Button (Sprint 11)
    /// 우하단 SkillButtonNode 왼쪽에 쿨타임 없는 hold-to-run 버튼을 부착한다.
    func setupRunButton() {
        cameraNode.addChild(runButton)
        runButton.onPressedChanged = { [weak self] pressed in
            self?.player.isRunning = pressed
        }
        layoutRunButton()
        runButton.zPosition = ZOrder.skillButtonZPosition
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
        let radius = max(UILayout.skillButtonVisualRadius, GameplayTuning.skillButtonRadius)
        let marginX = controlMargin(
            base: GameplayTuning.skillButtonMarginX,
            radius: radius,
            scale: scale
        )
        let marginY = controlMargin(
            base: GameplayTuning.skillButtonMarginY,
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
            x: skillButton.position.x - UILayout.runButtonGapFromSkill * scale,
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
            y: skillButton.position.y + GameplayTuning.hudSkillSlotOffsetY * scale
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
        let radius = UILayout.pauseButtonSize / 2
        let marginX = controlMargin(
            base: UILayout.pauseButtonMarginX,
            radius: radius,
            scale: scale
        )
        let marginY = controlMargin(
            base: UILayout.pauseButtonMarginY,
            radius: radius,
            scale: scale
        )
        pauseButton.position = CGPoint(
            x: +(halfW - safe.right - marginX),
            y: +(halfH - safe.top - marginY)
        )
    }
}
