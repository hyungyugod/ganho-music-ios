//
//  GameScene+Setup.swift
//  GanhoMusic Shared
//
//  Phase 3 종결 후 리팩터 — setup/add 9개 메서드를 GameScene 본체에서 분리.
//  Swift `private`은 *같은 파일+같은 타입* 한정 → 다른 파일 extension에선 접근 불가.
//  본체 멤버를 internal(기본)으로 1단계 완화하고, 본체 호출자(didMove)에서 사용한다.
//  기능 변화 0 — 코드 결과는 한 줄도 바뀌지 않는다.
//  Phase 9-8 — setupStoneGuard에 hard 난이도 가드 추가(stoneGuard 미등록 → 이스터에그 진입 0).
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
        setupMap()
    }

    /// Phase 7-2 — 맵 구성 단일 진입점. 외곽 벽 + difficulty 분기.
    /// Phase 9-4 — .normal 케이스가 .hard에서 떨어져 addNormalMap()으로 연결.
    /// switch default 미사용: Difficulty 신규 case 추가 시 컴파일러 경고로 자연 검출.
    func setupMap() {
        addOuterWalls()
        switch difficulty {
        case .easy:   addCentralPillar()
        case .normal: addNormalMap()
        case .hard:   addHardMap()
        }
    }

    /// Phase 7-2 — hard 맵(normal·hard 공용). 옵션 C 좌표 — 원본 game.js L289-309의
    /// *맵 가장자리 절대 거리* 보존 + *중앙 빈 공간만 확장*. 거울 대칭 (mirroredC=47-c, mirroredR=23-r).
    func addHardMap() {
        // 코너 방 4개 — 가로벽 + 세로벽(doorR 한 칸 분기)

        // 좌상 방
        addHorizontalWall(cStart: GameConfig.hardMapTopLeftRoomHWallCStart,
                          cEnd:   GameConfig.hardMapTopLeftRoomHWallCEnd,
                          r:      GameConfig.hardMapTopLeftRoomHWallR)
        addVerticalWall(c:       GameConfig.hardMapTopLeftRoomVWallC,
                        rStart:  GameConfig.hardMapTopLeftRoomVWallRStart,
                        rEnd:    GameConfig.hardMapTopLeftRoomVWallREnd,
                        doorR:   GameConfig.hardMapTopLeftRoomDoorR)

        // 우상 방
        addHorizontalWall(cStart: GameConfig.hardMapTopRightRoomHWallCStart,
                          cEnd:   GameConfig.hardMapTopRightRoomHWallCEnd,
                          r:      GameConfig.hardMapTopRightRoomHWallR)
        addVerticalWall(c:       GameConfig.hardMapTopRightRoomVWallC,
                        rStart:  GameConfig.hardMapTopRightRoomVWallRStart,
                        rEnd:    GameConfig.hardMapTopRightRoomVWallREnd,
                        doorR:   GameConfig.hardMapTopRightRoomDoorR)

        // 좌하 방
        addHorizontalWall(cStart: GameConfig.hardMapBottomLeftRoomHWallCStart,
                          cEnd:   GameConfig.hardMapBottomLeftRoomHWallCEnd,
                          r:      GameConfig.hardMapBottomLeftRoomHWallR)
        addVerticalWall(c:       GameConfig.hardMapBottomLeftRoomVWallC,
                        rStart:  GameConfig.hardMapBottomLeftRoomVWallRStart,
                        rEnd:    GameConfig.hardMapBottomLeftRoomVWallREnd,
                        doorR:   GameConfig.hardMapBottomLeftRoomDoorR)

        // 우하 방
        addHorizontalWall(cStart: GameConfig.hardMapBottomRightRoomHWallCStart,
                          cEnd:   GameConfig.hardMapBottomRightRoomHWallCEnd,
                          r:      GameConfig.hardMapBottomRightRoomHWallR)
        addVerticalWall(c:       GameConfig.hardMapBottomRightRoomVWallC,
                        rStart:  GameConfig.hardMapBottomRightRoomVWallRStart,
                        rEnd:    GameConfig.hardMapBottomRightRoomVWallREnd,
                        doorR:   GameConfig.hardMapBottomRightRoomDoorR)

        // 중앙 기둥 4개 — 대칭의 댄스플로어
        // 중앙-좌 (1×2 세로형)
        addRectPillar(cStart: GameConfig.hardMapCenterLeftPillarC,
                      cEnd:   GameConfig.hardMapCenterLeftPillarC,
                      rStart: GameConfig.hardMapCenterLeftPillarRStart,
                      rEnd:   GameConfig.hardMapCenterLeftPillarREnd)
        // 중앙-우 (1×2 세로형)
        addRectPillar(cStart: GameConfig.hardMapCenterRightPillarC,
                      cEnd:   GameConfig.hardMapCenterRightPillarC,
                      rStart: GameConfig.hardMapCenterRightPillarRStart,
                      rEnd:   GameConfig.hardMapCenterRightPillarREnd)
        // 중앙-상 (2×1 가로형)
        addRectPillar(cStart: GameConfig.hardMapCenterTopPillarCStart,
                      cEnd:   GameConfig.hardMapCenterTopPillarCEnd,
                      rStart: GameConfig.hardMapCenterTopPillarR,
                      rEnd:   GameConfig.hardMapCenterTopPillarR)
        // 중앙-하 (2×1 가로형)
        addRectPillar(cStart: GameConfig.hardMapCenterBottomPillarCStart,
                      cEnd:   GameConfig.hardMapCenterBottomPillarCEnd,
                      rStart: GameConfig.hardMapCenterBottomPillarR,
                      rEnd:   GameConfig.hardMapCenterBottomPillarR)
    }

    /// Phase 9-4 — normal 맵. 좌·우 두 방을 가르는 중앙 세로 분리벽(c=23) + 가운데 r=11~12 두 칸 문 +
    /// 좌방/우방 안 2×2 장식 기둥. addVerticalWall은 private(같은 파일 한정)이라
    /// 본 메서드는 *반드시* 같은 extension 블록 안에 있어야 한다.
    /// Phase 9-5 — 중앙 세로 분리벽만 breakable: true (정간호 돌진으로 파괴 가능).
    /// 장식 기둥(좌방/우방)은 breakable: false 유지 — 게임 균형 회귀 0.
    func addNormalMap() {
        // 중앙 세로 분리벽 — 윗 절반 (r=2..10). doorR=-1 sentinel → 모든 r에서 벽 채워짐.
        // Phase 9-5 — 분리벽만 breakable: true. 정간호 돌진 시 1칸 파괴 가능.
        addVerticalWall(c:      GameConfig.normalMapDividerC,
                        rStart: GameConfig.normalMapDividerUpperRStart,
                        rEnd:   GameConfig.normalMapDividerUpperREnd,
                        doorR:  GameConfig.normalMapNoDoorSentinel,
                        breakable: true)
        // 중앙 세로 분리벽 — 아랫 절반 (r=13..21). 가운데 r=11,12는 두 빌더 모두 건드리지 않아
        // 자연스럽게 *통과 가능한 2칸 문*이 형성된다.
        addVerticalWall(c:      GameConfig.normalMapDividerC,
                        rStart: GameConfig.normalMapDividerLowerRStart,
                        rEnd:   GameConfig.normalMapDividerLowerREnd,
                        doorR:  GameConfig.normalMapNoDoorSentinel,
                        breakable: true)
        // 좌방 장식 기둥 — 2×2 타일. breakable: false (장식이라 파괴 비대상).
        addRectPillar(cStart: GameConfig.normalMapLeftPillarCStart,
                      cEnd:   GameConfig.normalMapLeftPillarCEnd,
                      rStart: GameConfig.normalMapLeftPillarRStart,
                      rEnd:   GameConfig.normalMapLeftPillarREnd)
        // 우방 장식 기둥 — 2×2 타일, 좌우 거울 대칭. breakable: false.
        addRectPillar(cStart: GameConfig.normalMapRightPillarCStart,
                      cEnd:   GameConfig.normalMapRightPillarCEnd,
                      rStart: GameConfig.normalMapRightPillarRStart,
                      rEnd:   GameConfig.normalMapRightPillarREnd)
    }

    /// Phase 9-4 — 체크보드 바닥. 1152개(mapColumns × mapRows = 48×24) SKSpriteNode를
    /// *컨테이너 한 개*에 자식으로 묶어 worldNode에 부착한다.
    /// physicsBody 0 부착(시각 전용), zPosition = checkerboardZPosition(-100).
    /// 호출은 setupWorld()에서 1회만 — update() 안 호출 금지(성능 핵심).
    private func addCheckerboardFloor() {
        let container = SKNode()
        container.name = GameConfig.checkerboardContainerName
        container.zPosition = GameConfig.checkerboardZPosition

        let t = GameConfig.tileSize
        let half = t / 2
        let floorA = UIColor(hex: GameConfig.checkerboardFloorAHex)
        let floorB = UIColor(hex: GameConfig.checkerboardFloorBHex)
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
                // 시각 전용 — physicsBody 미부착. 1152개 노드가 물리 시뮬에 들어가면 60fps 위협.
                container.addChild(tile)
            }
        }

        worldNode.addChild(container)
    }

    /// Phase 7-2 — 가로벽 헬퍼. 단일 행 r에 cStart..cEnd 길이 만큼 1행 직사각형 1개.
    /// Phase 9-5 — breakable 파라미터 추가 (default false → 회귀 0).
    private func addHorizontalWall(cStart: Int, cEnd: Int, r: Int, breakable: Bool = false) {
        addRectPillar(cStart: cStart, cEnd: cEnd, rStart: r, rEnd: r, breakable: breakable)
    }

    /// Phase 7-2 — 세로벽 헬퍼. doorR 한 칸을 *건너뛰며* 1×1 직사각형 여러 개 생성.
    /// 통짜로 만들면 PhysicsBody가 문을 막아 플레이어 입장 불가 — SKSpriteNode 분리 필수(주의사항 7).
    /// Phase 9-5 — breakable 파라미터 추가 (default false → hard 맵 호출자 회귀 0).
    /// breakable=true 호출 시 각 칸 SKSpriteNode가 name="breakableWall"을 부여받아
    /// SkillSystem.dashClimb의 enumerate가 식별 가능.
    private func addVerticalWall(c: Int, rStart: Int, rEnd: Int, doorR: Int, breakable: Bool = false) {
        for r in rStart...rEnd where r != doorR {
            addRectPillar(cStart: c, cEnd: c, rStart: r, rEnd: r, breakable: breakable)
        }
    }

    /// Phase 7-2 — 직사각형 벽 1개 생성. anchorPoint 기본값 .center 가정 —
    /// 중심 = ((cStart + widthTiles/2) × tileSize, (rStart + heightTiles/2) × tileSize).
    /// PhysicsBody 정책은 addCentralPillar와 byte-equal(주의사항 1).
    /// Phase 9-5 — breakable 파라미터 추가 (default false → 외곽/장식/hard 맵 호출자 회귀 0).
    /// breakable=true면 노드에 name="breakableWall" 부여 — SkillSystem.dashClimb 발동 시
    /// worldNode.enumerateChildNodes(withName: breakableWallName)이 식별 가능.
    private func addRectPillar(cStart: Int, cEnd: Int, rStart: Int, rEnd: Int, breakable: Bool = false) {
        let t = GameConfig.tileSize
        let widthTiles  = CGFloat(cEnd - cStart + 1)
        let heightTiles = CGFloat(rEnd - rStart + 1)
        let pillarSize = CGSize(width: widthTiles * t, height: heightTiles * t)
        // Sprint 3 — v2 디자인 시스템 navy 톤 통합. PhysicsBody/breakable name/위치 0건 변경.
        let pillar = SKSpriteNode(color: .ganhoNavyDeep, size: pillarSize)
        pillar.position = CGPoint(
            x: (CGFloat(cStart) + widthTiles  / 2) * t,
            y: (CGFloat(rStart) + heightTiles / 2) * t
        )
        if breakable {
            pillar.name = GameConfig.breakableWallName
        }
        let body = SKPhysicsBody(rectangleOf: pillarSize)
        body.isDynamic           = false
        body.friction            = 0
        body.restitution         = 0
        body.categoryBitMask     = PhysicsCategory.wall
        body.collisionBitMask    = 0
        body.contactTestBitMask  = 0
        pillar.physicsBody = body
        worldNode.addChild(pillar)
    }

    func addOuterWalls() {
        // 4 외곽 벽: 두께 1 tile (20pt), 맵 바깥쪽에 배치.
        // Phase 2-2 — 각 벽에 static PhysicsBody 부착하여 박스가 진짜로 부딪히게 함.
        // (1-4 자체 클램프 제거 후 외곽 벽 PhysicsBody가 그 책임을 이어받음.)
        let mapW = GameConfig.mapWidth
        let mapH = GameConfig.mapHeight
        let t    = GameConfig.tileSize
        let halfT = t / 2

        struct WallSpec {
            let size: CGSize
            let position: CGPoint
        }
        let walls: [WallSpec] = [
            // top
            WallSpec(
                size: CGSize(width: mapW + t * 2, height: t),    // 좌우 모서리까지 덮음
                position: CGPoint(x: mapW / 2, y: mapH + halfT)
            ),
            // bottom
            WallSpec(
                size: CGSize(width: mapW + t * 2, height: t),
                position: CGPoint(x: mapW / 2, y: -halfT)
            ),
            // left
            WallSpec(
                size: CGSize(width: t, height: mapH),
                position: CGPoint(x: -halfT, y: mapH / 2)
            ),
            // right
            WallSpec(
                size: CGSize(width: t, height: mapH),
                position: CGPoint(x: mapW + halfT, y: mapH / 2)
            )
        ]

        for spec in walls {
            // Sprint 3 — v2 디자인 시스템 navy 톤 통합. PhysicsBody/size/position 0건 변경.
            let wall = SKSpriteNode(color: .ganhoNavyDeep, size: spec.size)
            wall.position = spec.position

            // Phase 2-2 — PhysicsBody 부착 (static, 박스가 부딪힘)
            let body = SKPhysicsBody(rectangleOf: spec.size)
            body.isDynamic           = false
            body.friction            = 0
            body.restitution         = 0
            body.categoryBitMask     = PhysicsCategory.wall
            body.collisionBitMask    = 0   // 벽은 다른 객체에 의해 안 움직임 (static)
            body.contactTestBitMask  = 0   // 충돌 알림은 player가 받음 (대칭)
            wall.physicsBody = body

            worldNode.addChild(wall)
        }

        // Sprint 3 — 외곽 라운드 보더 SKShapeNode 1개 (시각만, physicsBody 미부착).
        // zPosition -50 — 체크보드(-100) 위, 외곽 벽(0) 아래에 자연스럽게 깔린다.
        let borderRect = CGRect(
            x: 0, y: 0,
            width: GameConfig.mapWidth,
            height: GameConfig.mapHeight
        )
        let border = SKShapeNode(
            rect: borderRect,
            cornerRadius: GameConfig.outerWallBorderCornerRadius
        )
        border.strokeColor = .ganhoNavyDeep
        border.lineWidth = GameConfig.outerWallBorderLineWidth
        border.fillColor = .clear
        border.zPosition = -50
        worldNode.addChild(border)
    }

    func addCentralPillar() {
        // GDD §6 easy 맵 — 중앙 기둥 1개 (2×4 tile = 40×80pt), 맵 정중앙.
        let pillarSize = CGSize(
            width:  GameConfig.tileSize * 2,    // 40pt
            height: GameConfig.tileSize * 4     // 80pt
        )
        // Sprint 3 — v2 디자인 시스템 navy 톤 통합. PhysicsBody/위치 0건 변경.
        let pillar = SKSpriteNode(color: .ganhoNavyDeep, size: pillarSize)
        pillar.position = CGPoint(
            x: GameConfig.mapWidth  / 2,        // 맵 가로 정중앙
            y: GameConfig.mapHeight / 2         // 맵 세로 정중앙
        )

        // PhysicsBody 부착 (외곽 벽과 동일 정책)
        let body = SKPhysicsBody(rectangleOf: pillarSize)
        body.isDynamic           = false
        body.friction            = 0
        body.restitution         = 0
        body.categoryBitMask     = PhysicsCategory.wall
        body.collisionBitMask    = 0
        body.contactTestBitMask  = 0
        pillar.physicsBody = body

        worldNode.addChild(pillar)
    }

    func setupPlayer() {
        // Phase 2-6 hotfix 2 — 중앙 기둥(맵 정중앙)과 분리된 좌측 1/4 지점.
        // 기둥과 같은 좌표에서 시작 시 dynamic body 분리 force로 튕기는 잠재 버그 회피.
        player.position = CGPoint(
            x: GameConfig.mapWidth  / 4,
            y: GameConfig.mapHeight / 2
        )
        player.apply(characterID)   // Phase 5-R — 5-2(color) + 5-3(speedMultiplier) 단일 진입점으로 통합
        player.apply(difficulty)    // Phase 7-1 — 난이도별 baseSpeedStart/End set. character 먼저 → difficulty 나중(주의사항 1).
        worldNode.addChild(player)
    }

    func setupCamera() {
        cameraNode.position = CGPoint(
            x: GameConfig.mapWidth  / 2,
            y: GameConfig.mapHeight / 2
        )
        addChild(cameraNode)
        camera = cameraNode   // 씬에 메인 카메라 통보 (필수)
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
        hud.setCharacterName(characterID.displayName)   // Phase 5-4 — TitleScene 선택 캐릭터 이름을 HUD 우상단에 1회 주입
        layoutHUD()
    }

    func setupEnemy() {
        // Phase 2-7 hotfix — player가 좌측 1/4(240, 240)에 있으니 enemy를 *맵 우상단*에 배치.
        // 좌표 (mapW * 3/4, mapH * 3/4) = (720, 360). player와 거리 √(480² + 120²) ≈ 495pt.
        // 60pt/s 속도로 ~8초 후 도달 → 사용자가 D-Pad 익히고 회피 학습할 시간 확보.
        enemy.position = CGPoint(
            x: GameConfig.mapWidth  * 3 / 4,
            y: GameConfig.mapHeight * 3 / 4
        )
        enemy.apply(difficulty)   // Phase 7-1 — 난이도별 baseSpeedStart/End set.
        worldNode.addChild(enemy)
    }

    func setupStoneGuard() {
        // Phase 9-8 — hard 난이도는 이교수 톤 집중. 석조무사 미등장 (GDD §7-6 "하/중 전용").
        // worldNode에 stoneGuard를 추가하지 않으므로 충돌 자체가 발생 0건 → 이스터에그 진입 0.
        guard difficulty != .hard else { return }
        // Phase 4-1 — 첫 waypoint(좌하단)에 위치 부여. StoneGuardNode.init에서 patrol이 이미 시작됐으므로
        // 첫 .move 액션은 (200, 100) → (760, 100) 우향으로 자동 진행된다.
        let first = GameConfig.stoneGuardWaypoints[0]
        stoneGuard.position = CGPoint(x: first.x, y: first.y)
        worldNode.addChild(stoneGuard)
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
        let first = GameConfig.professorWaypoints[0]
        node.position = first
        worldNode.addChild(node)
        professor = node
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
    /// 좌하단 SkillButtonNode를 cameraNode 자식으로 추가. D-Pad(우하단)와 대칭.
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

    // MARK: - HUD Skill Slot (Phase 9-5)
    /// 좌하단 SkillButtonNode 위에 HUDSkillSlotNode 부착(cameraNode 자식).
    /// configure(skill:)로 라벨 + 김간호 빈 슬롯 자동 set.
    func setupHUDSkillSlot() {
        cameraNode.addChild(hudSkillSlot)
        hudSkillSlot.configure(skill: characterID.skill)
        layoutHUDSkillSlot()
    }

    /// scene.size 변경 시 SkillButtonNode 위치 재계산. addChild 0건 — 멱등.
    /// cameraNode 자식 좌표계: (0,0) = 화면 중앙. 좌하단 = (-x, -y).
    func layoutSkillButton() {
        let halfW = size.width  / 2
        let halfH = size.height / 2
        skillButton.position = CGPoint(
            x: -(halfW - GameConfig.skillButtonMarginX),
            y: -(halfH - GameConfig.skillButtonMarginY)
        )
    }

    /// scene.size 변경 시 HUDSkillSlotNode 위치 재계산. addChild 0건 — 멱등.
    /// SkillButtonNode 바로 위(hudSkillSlotOffsetY = 50pt 위).
    func layoutHUDSkillSlot() {
        let halfW = size.width  / 2
        let halfH = size.height / 2
        hudSkillSlot.position = CGPoint(
            x: -(halfW - GameConfig.skillButtonMarginX),
            y: -(halfH - GameConfig.skillButtonMarginY) + GameConfig.hudSkillSlotOffsetY
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
        pauseButton.position = CGPoint(
            x: +(halfW - GameConfig.pauseButtonMarginX),
            y: +(halfH - GameConfig.pauseButtonMarginY)
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

        // 토스트 "박병장 등장!" — fontDisplay 36pt, coralPrimary.
        let toast = SKLabelNode(fontNamed: GameConfig.fontDisplay)
        toast.text = "박병장 등장!"
        toast.fontSize = 36
        toast.fontColor = .ganhoCoralPrimary
        toast.position = CGPoint(x: 0, y: -120)
        toast.alpha = 0
        overlay.addChild(toast)

        cameraNode.addChild(overlay)

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
