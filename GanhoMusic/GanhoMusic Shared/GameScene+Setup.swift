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
    /// R6 §F7 거울 병동 — 빌드 직후 *데이터 레벨 x 반전* (노드 음수 xScale 금지 — 물리 신뢰 불가).
    func setupMap() {
        mapNode.buildWalls(difficulty: difficulty)
        if dailyModifier == .mirrorWard {
            applyMirrorWardToMap()
        }
    }

    /// 거울 병동 — mapNode 자식(벽 타일·병원 소품) 전부의 x를 맵 폭 기준 반전.
    /// physicsBody는 노드 position을 따라가므로 *부착 직후 위치 이동* = 데이터 레벨 반전과 등가.
    /// 셀 중심((col+0.5)×tile)의 반전은 정확히 (31-col+0.5)×tile — 격자 정합 유지.
    /// 외곽 벽은 자기 대칭이라 무변화, 내부 비대칭 장애물만 좌우가 바뀐다.
    /// 적 패트롤 waypoint는 미반전 — nurse 세트는 x-대칭(3.5↔28.5 스왑 = 동일 집합)이고,
    /// 반전 대상 내부 장애물은 패트롤 라인(행 3·16 / 열 3·28)과 비교차 실측 (플레이 불능 회귀 0).
    /// 석조무사·이교수는 SKAction.move 구동 — 벽 비충돌이라 경로 영향 0.
    private func applyMirrorWardToMap() {
        for child in mapNode.children {
            child.position.x = GameplayTuning.mapWidth - child.position.x
        }
    }

    /// Phase 9-4 체크보드 바닥 — R1: 640개(32×20) SKSpriteNode 루프 폐기 →
    /// **사전 렌더 텍스처 1장 + SKSpriteNode 1개** (설계서 01 §9 권장안).
    /// 시각 동일: ganhoIngameFloorA/B 2색, (c+r) 홀짝 교차, 셀 25pt, 맵 800×500 전체 —
    /// 32×20px 이미지(1픽셀=1타일)를 TextureAtlasStore가 1회 렌더, .nearest로 800×500pt 확대.
    /// anchorPoint .zero + position .zero → 구 타일들(0~800, 0~500 커버)과 같은 영역.
    /// physicsBody 0 부착(시각 전용), zPosition = checkerboardZPosition(-100),
    /// name = checkerboardContainerName 유지(외부 참조는 본 생성부뿐 — 컨테이너 SKNode 제거, sprite에 직접 부여).
    /// 호출은 setupWorld()에서 1회만 — update() 안 호출 금지(성능 핵심).
    private func addCheckerboardFloor() {
        let floor = SKSpriteNode(texture: TextureAtlasStore.checkerboardFloorTexture())
        floor.name = GameplayTuning.checkerboardContainerName
        floor.zPosition = ZOrder.checkerboardZPosition
        floor.anchorPoint = .zero
        floor.position = .zero
        floor.size = CGSize(width: GameplayTuning.mapWidth, height: GameplayTuning.mapHeight)
        worldNode.addChild(floor)
    }

    // MARK: - Directors (R2)
    /// 게임필 director/controller 3종 배선 + 걷기 먼지 풀 예열. didMove에서 1회 호출 (setupCamera 이후 —
    /// CameraDirector가 cameraNode의 초기 위치(맵 중앙)를 basePosition으로 캡처).
    func setupDirectors() {
        hitstop.configure(worldNode: worldNode, physicsWorld: physicsWorld)
        cameraDirector.configure(
            cameraNode: cameraNode,
            targetProvider: { [weak self] in self?.player.position ?? .zero },
            viewportProvider: { [weak self] in self?.size ?? .zero }
        )
        effectDirector.configure(
            worldNode: worldNode,
            cameraNode: cameraNode,
            viewportProvider: { [weak self] in self?.size ?? .zero },
            skill: characterID.skill,
            signatureColor: Palette.character(characterID)
        )
        walkDustPool.preheat(count: FeelTuning.walkDustPoolPreheatCount)
    }

    // MARK: - Entity Pools + Registry (R1)
    /// 풀 4종 예열 + SpawnSystem 풀·레지스트리 배선. didMove에서 1회 호출.
    /// 예열 수치는 GameplayTuning 상수(12/16/6/8 — 설계서 01 §8 그대로).
    func setupEntityPools() {
        projectilePool.preheat(count: GameplayTuning.projectilePoolPreheatCount)
        notePool.preheat(count: GameplayTuning.notePoolPreheatCount)
        stethoscopePool.preheat(count: GameplayTuning.stethoscopePoolPreheatCount)
        scorePopupPool.preheat(count: GameplayTuning.scorePopupPoolPreheatCount)
        spawnSystem.configurePooling(
            registry: registry,
            noteProvider: { [weak self] in
                guard let self = self else { return NoteNode() }
                return self.obtainPooledNote()
            }
        )
    }

    /// 풀+레지스트리 원자 쌍의 obtain 절반: obtain → recycleHandler 주입 → register.
    /// addChild는 호출 시설(SpawnSystem)이 위치 확정 직후 수행 — provider 호출 직후라 사실상 원자.
    func obtainPooledNote() -> NoteNode {
        let note = notePool.obtain()
        note.recycleHandler = { [weak self] node in self?.recycleDynamicNode(node) }
        registry.register(note)
        return note
    }

    /// F 투사체 obtain 절반 — EnemyNode.projectileProvider가 호출.
    func obtainPooledProjectile() -> FProjectileNode {
        let projectile = projectilePool.obtain()
        projectile.recycleHandler = { [weak self] node in self?.recycleDynamicNode(node) }
        registry.register(projectile)
        return projectile
    }

    /// 청진기 obtain 절반 — ProfessorNode.stethoscopeProvider가 호출.
    func obtainPooledStethoscope() -> StethoscopeNode {
        let stethoscope = stethoscopePool.obtain()
        stethoscope.recycleHandler = { [weak self] node in self?.recycleDynamicNode(node) }
        registry.register(stethoscope)
        return stethoscope
    }

    /// 풀 대상 4종의 회수 단일 진입점: unregister → pool.recycle(removeFromParent+reset+보관).
    /// 비풀 노드(AItem/Toilet 등)는 기존 removeFromParent 동작 유지(fallback).
    /// 이중 회수 안전 — unregister/recycle 모두 idempotent.
    func recycleDynamicNode(_ node: SKNode) {
        if let note = node as? NoteNode {
            registry.unregister(note)
            notePool.recycle(note)
        } else if let projectile = node as? FProjectileNode {
            registry.unregister(projectile)
            projectilePool.recycle(projectile)
        } else if let stethoscope = node as? StethoscopeNode {
            registry.unregister(stethoscope)
            stethoscopePool.recycle(stethoscope)
        } else if let popup = node as? ScorePopupNode {
            scorePopupPool.recycle(popup)
        } else {
            node.removeFromParent()
        }
    }

    #if DEBUG
    // MARK: - Frame Stats (R1 · DEBUG 전용)
    /// 좌상단 프레임/노드 진단 라벨 부착. FrameStats.isEnabled=false면 attach 0 (코드 1줄 토글).
    func setupFrameStats() {
        guard FrameStats.isEnabled else { return }
        let stats = FrameStats()
        stats.place(in: size)
        cameraNode.addChild(stats)
        frameStats = stats
    }
    #endif

    // Sprint 10 Phase C — 옛 빌더 함수 7개 본문 + 외곽 라운드 보더 SKShapeNode 삭제.
    // 제거된 함수: addHorizontalWall / addVerticalWall / addRectPillar / addOuterWalls /
    //             addCentralPillar / addHardMap / addNormalMap.
    // 호출자 0건 검증(grep 결과 SELF_CHECK §5) → setupMap의 단일 위임으로 책임 이동.
    // outerWallBorder* 상수도 호출자 0건 — UILayout에 정의만 남되 본 Phase는 시각 사용 중단.

    func setupPlayer() {
        // Phase 2-6 hotfix 2 — 중앙 기둥(맵 정중앙)과 분리된 좌측 1/4 지점.
        // 기둥과 같은 좌표에서 시작 시 dynamic body 분리 force로 튕기는 잠재 버그 회피.
        player.position = CGPoint(
            x: GameplayTuning.mapWidth  / 4,
            y: GameplayTuning.mapHeight / 2
        )
        // R6 §F7 거울 병동 — 스폰 좌표도 데이터 레벨 반전 (좌측 1/4 → 우측 3/4, 동일 열린 지점).
        // setupEnemy/setupStoneGuard/setupProfessor가 이 위치를 읽어 farthest-first/점대칭을
        // 계산하므로 *여기서* 반전해야 등장 배치 전체가 자연 미러링된다 (호출 순서 계약).
        if dailyModifier == .mirrorWard {
            player.position.x = GameplayTuning.mapWidth - player.position.x
        }
        player.apply(characterID)   // Phase 5-R — 5-2(color) + 5-3(speedMultiplier) 단일 진입점으로 통합
        player.apply(difficulty)    // Phase 7-1 — 난이도별 baseSpeedStart/End set. character 먼저 → difficulty 나중(주의사항 1).
        player.wallCollisionProvider = { [weak self] rect in
            return self?.containsWall(in: rect) ?? false
        }
        player.wallRectProvider = { [weak self] rect in
            return self?.wallRects(intersecting: rect) ?? []
        }
        // R2 — 속도 곡선 progress 주입 (spawnSystem progressProvider 패턴 답습 —
        // PlayerNode가 gameDuration을 직접 알 필요 없음).
        player.progressProvider = { [weak self] in
            guard let self = self else { return 0 }
            return CGFloat(1.0 - self.remainingTime / GameplayTuning.gameDuration)
        }
        // R2 — 걷기 먼지: 4걸음마다 풀 경유 WalkDustNode attach (update 내 신규 할당 0).
        player.onWalkStepDust = { [weak self] feetPosition in
            guard let self = self else { return }
            let dust = self.walkDustPool.obtain()
            dust.recycleHandler = { [weak self] node in self?.walkDustPool.recycle(node) }
            dust.position = feetPosition
            self.worldNode.addChild(dust)
            dust.play()
        }
        worldNode.addChild(player)
    }

    func setupCamera() {
        cameraNode.position = CGPoint(
            x: GameplayTuning.mapWidth  / 2,
            y: GameplayTuning.mapHeight / 2
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
            return Double(1.0 - self.remainingTime / GameplayTuning.gameDuration)
        }
        enemy.charmActiveProvider = { [weak self] in
            return self?.skillSystem.isCharmActive ?? false
        }
        // R1 — F 실체화/카운트 provider. 실체화는 풀+레지스트리 경유(obtain→register),
        // 카운트는 registry 캐시(구 update 경로 enumerate 대체). 기존 provider 컨벤션 동형.
        enemy.projectileProvider = { [weak self] in
            guard let self = self else { return FProjectileNode() }
            return self.obtainPooledProjectile()
        }
        enemy.projectileCountProvider = { [weak self] in
            return self?.registry.projectiles.count ?? 0
        }
        // R2 — 발사 시점 콜백: soft 셰이크 + 근거리 텔레그래프 햅틱 (02 §3·§6 매핑).
        enemy.onFired = { [weak self] origin in
            self?.playTelegraphFireFeedback(from: origin)
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

    // R8 §B③ — Professor/SkillButton/RunButton/HUDSkillSlot/PauseButton 셋업은
    // GameScene+SetupActors.swift, 일일 모디파이어·박병장 데뷔는
    // GameScene+DailyModifiers.swift로 분리 (코드 이동만 — 로직 0 변경).
}
