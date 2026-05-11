//
//  GameScene+Setup.swift
//  GanhoMusic Shared
//
//  Phase 3 종결 후 리팩터 — setup/add 9개 메서드를 GameScene 본체에서 분리.
//  Swift `private`은 *같은 파일+같은 타입* 한정 → 다른 파일 extension에선 접근 불가.
//  본체 멤버를 internal(기본)으로 1단계 완화하고, 본체 호출자(didMove)에서 사용한다.
//  기능 변화 0 — 코드 결과는 한 줄도 바뀌지 않는다.
//

import SpriteKit

// MARK: - Setup
extension GameScene {
    func setupBackground() {
        backgroundColor = .ganhoBgDeep
    }

    func setupWorld() {
        worldNode.position = .zero
        addChild(worldNode)

        addOuterWalls()
        addCentralPillar()   // Phase 2-2 신설 — GDD §6 easy 맵 명세
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
            let wall = SKSpriteNode(color: .ganhoPaper, size: spec.size)
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
    }

    func addCentralPillar() {
        // GDD §6 easy 맵 — 중앙 기둥 1개 (2×4 tile = 40×80pt), 맵 정중앙.
        let pillarSize = CGSize(
            width:  GameConfig.tileSize * 2,    // 40pt
            height: GameConfig.tileSize * 4     // 80pt
        )
        let pillar = SKSpriteNode(color: .ganhoPaper, size: pillarSize)
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
        player.color = characterID.color   // Phase 5-2 — TitleScene 선택 캐릭터 색을 PlayerNode 몸체에 즉시 반영
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
        layoutDPad()
    }

    func setupHUD() {
        cameraNode.addChild(hud)
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
        worldNode.addChild(enemy)
    }

    func setupStoneGuard() {
        // Phase 4-1 — 첫 waypoint(좌하단)에 위치 부여. StoneGuardNode.init에서 patrol이 이미 시작됐으므로
        // 첫 .move 액션은 (200, 100) → (760, 100) 우향으로 자동 진행된다.
        let first = GameConfig.stoneGuardWaypoints[0]
        stoneGuard.position = CGPoint(x: first.x, y: first.y)
        worldNode.addChild(stoneGuard)
    }
}
