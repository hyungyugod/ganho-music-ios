//
//  GameScene.swift
//  GanhoMusic Shared
//
//  Phase 1-1 · 빈 씬 골격 (Hello World 템플릿 제거)
//  Phase 1-2 · 월드 컨테이너 + 카메라 follow + 임시 박스 자동 왕복
//  Phase 1-3 · PlayerNode 정식 + 반투명 D-Pad + dt 입력 이동
//  Phase 2-1 · 맵 외곽 벽 시각화 + corner 마커 폐기
//  Phase 2-2 · SKPhysicsBody 첫 도입 + 중앙 기둥 신설
//  Phase 2-3 · 음표 스폰 루프 + contact 알림 + score 내부 카운트
//  Phase 2-4 · HUD 라벨 부착 + 45초 카운트다운 + 시간 만료 시 endGame()
//  Phase 2-6 · 수간호사 적 NPC 1마리 + 직선 추적 AI + 접촉 시 즉시 게임오버
//  Phase 2-7 · F 투사체 발사 루프 + F 피격 시 게임오버 + 벽 닿으면 소멸
//  Phase 2-10 · spawn / fire 9 메서드를 SpawnSystem으로 분리 (순수 리팩터, 기능 변화 0)
//  Phase 2-11 · didBegin / handleProjectileContact / handleNoteContact를 ContactRouter로 분리 (순수 리팩터)
//

import SpriteKit

/// 게임 메인 씬. Phase 1-3 시점에는 PlayerNode(worldNode 자식)와
/// DPadNode(cameraNode 자식)로 사용자 입력 → 캐릭터 이동 → 카메라 추종 골격을 완성한다.
/// 맵 경계/물리/HUD/스폰은 후속 Phase에서 추가.
/// Phase 2-11 — 충돌 분기는 ContactRouter가 담당. GameScene은 콜백 등록만.
class GameScene: SKScene {

    // MARK: - Properties
    private var gameState: GameState = .waiting
    private var lastUpdateTime: TimeInterval = 0
    private var score: Int = 0   // Phase 2-3 — 내부 카운트, Phase 2-4부터 HUD에 표시
    private let hud = HUDNode()                                         // Phase 2-4 — cameraNode 자식
    private var remainingTime: TimeInterval = GameConfig.gameDuration   // Phase 2-4 — 45초 카운트다운
    private var combo: Int = 0
    private var lastCollectAt: TimeInterval = 0   // 0 = "아직 수집 0건". combo > 0 가드와 함께 사용.

    // 노드 트리
    private let worldNode  = SKNode()
    private let cameraNode = SKCameraNode()
    private let player     = PlayerNode()    // worldNode 자식 (이동함)
    private let enemy      = EnemyNode()     // worldNode 자식 (player 추적, Phase 2-6)
    private let dpad       = DPadNode()      // cameraNode 자식 (화면 고정)

    // 시스템
    private let spawnSystem = SpawnSystem()       // Phase 2-10 — spawn 책임 분리
    private let contactRouter = ContactRouter()   // Phase 2-11 — 충돌 분기 책임 분리

    // MARK: - Factory
    class func newGameScene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 1024, height: 768))
        scene.scaleMode = .resizeFill   // Phase 1-3 핫픽스: scene size를 view 크기에 자동 맞춤 — D-Pad가 viewport 안에 들어오게 함
        return scene
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        setupBackground()    // 1-2 그대로 (.ganhoBgDeep)
        setupWorld()         // worldNode + 외곽 벽 4개 (2-1) + 중앙 기둥 (2-2)
        setupPlayer()        // PlayerNode를 worldNode 자식으로
        setupCamera()        // cameraNode (1-2 그대로)
        setupDPad()          // 1-3 신설 — DPadNode를 cameraNode 자식으로
        setupHUD()           // Phase 2-4 신설 — HUDNode를 cameraNode 좌상단에
        setupEnemy()         // Phase 2-6 신설 — EnemyNode를 worldNode 자식으로
        physicsWorld.gravity = .zero   // Phase 2-2 — 탑다운 게임이라 중력 없음
        configureContactRouter()                       // Phase 2-11 — 콜백 4개 등록
        physicsWorld.contactDelegate = contactRouter   // Phase 2-11 — 분기는 ContactRouter가 담당
        // Phase 2-10 — spawn / fire 두 루프를 SpawnSystem으로 위임. 진행률 closure로 공급.
        spawnSystem.start(
            scene: self,
            world: worldNode,
            player: player,
            enemy: enemy,
            progressProvider: { [weak self] in
                guard let self = self else { return 0 }
                return Double(1.0 - self.remainingTime / GameConfig.gameDuration)
            }
        )
        gameState = .playing // playing 전환 후에야 update가 동작
    }

    /// scene.size 변경 시 SpriteKit이 호출 (.resizeFill 모드에서 view bounds 변경 시 자동 트리거).
    /// cameraNode 자식의 화면 고정 위치(D-Pad / HUD)를 재계산해서 viewport에 맞춤.
    /// 첫 attach 시점에도 scene이 1024×768 → view 크기로 갱신되며 호출됨.
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutDPad()
        layoutHUD()
    }

    // MARK: - Setup
    private func setupBackground() {
        backgroundColor = .ganhoBgDeep
    }

    private func setupWorld() {
        worldNode.position = .zero
        addChild(worldNode)

        addOuterWalls()
        addCentralPillar()   // Phase 2-2 신설 — GDD §6 easy 맵 명세
    }

    private func addOuterWalls() {
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

    private func addCentralPillar() {
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

    private func setupPlayer() {
        // Phase 2-6 hotfix 2 — 중앙 기둥(맵 정중앙)과 분리된 좌측 1/4 지점.
        // 기둥과 같은 좌표에서 시작 시 dynamic body 분리 force로 튕기는 잠재 버그 회피.
        player.position = CGPoint(
            x: GameConfig.mapWidth  / 4,
            y: GameConfig.mapHeight / 2
        )
        worldNode.addChild(player)
    }

    private func setupCamera() {
        cameraNode.position = CGPoint(
            x: GameConfig.mapWidth  / 2,
            y: GameConfig.mapHeight / 2
        )
        addChild(cameraNode)
        camera = cameraNode   // 씬에 메인 카메라 통보 (필수)
    }

    private func setupDPad() {
        // 1-3 신설 — DPadNode를 cameraNode 자식으로 추가. 위치는 layoutDPad가 담당.
        cameraNode.addChild(dpad)
        layoutDPad()
    }

    /// scene.size 변경 시(viewport 회전·resize)에 위치만 재계산. addChild 0건 — 멱등 보장.
    /// cameraNode 자식 좌표계: (0,0) = 화면 중앙, +x 우, +y 상. 우하단 = (+x, -y).
    private func layoutDPad() {
        let halfW = size.width  / 2
        let halfH = size.height / 2
        dpad.position = CGPoint(
            x: +(halfW - GameConfig.dpadMarginX),
            y: -(halfH - GameConfig.dpadMarginY)
        )
    }

    private func setupHUD() {
        cameraNode.addChild(hud)
        layoutHUD()
    }

    /// scene.size 변경 시 위치만 재계산. addChild 0건 — 멱등.
    /// cameraNode 자식 좌표계: (0,0) = 화면 중앙. 좌상단 = (-x, +y). D-Pad와 부호만 반전.
    private func layoutHUD() {
        let halfW = size.width  / 2
        let halfH = size.height / 2
        hud.position = CGPoint(
            x: -(halfW - GameConfig.hudMarginX),
            y: +(halfH - GameConfig.hudMarginY)
        )
    }

    private func setupEnemy() {
        // Phase 2-7 hotfix — player가 좌측 1/4(240, 240)에 있으니 enemy를 *맵 우상단*에 배치.
        // 좌표 (mapW * 3/4, mapH * 3/4) = (720, 360). player와 거리 √(480² + 120²) ≈ 495pt.
        // 60pt/s 속도로 ~8초 후 도달 → 사용자가 D-Pad 익히고 회피 학습할 시간 확보.
        enemy.position = CGPoint(
            x: GameConfig.mapWidth  * 3 / 4,
            y: GameConfig.mapHeight * 3 / 4
        )
        worldNode.addChild(enemy)
    }

    // MARK: - Game Loop
    override func update(_ currentTime: TimeInterval) {
        // 첫 프레임 처리
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        // 상태 가드 — playing이 아니면 입력/이동/카메라 모두 정지
        guard gameState == .playing else { return }

        // Phase 2-4 — 45초 카운트다운. 0 도달 시 즉시 종료(early return)으로
        // 이번 프레임의 player/카메라/HUD 갱신은 건너뛴다.
        remainingTime = max(0, remainingTime - dt)
        if remainingTime <= 0 {
            endGame()
            return
        }

        // Phase 2-5 — 콤보 윈도우 만료 검사
        if combo > 0, currentTime - lastCollectAt > GameConfig.comboWindow {
            combo = 0
        }

        // 1) D-Pad 입력을 PlayerNode로 위임 (DPadNode → PlayerNode 직접 참조 금지 → GameScene 경유)
        player.currentDirection = dpad.currentDirection

        // 2) PlayerNode 자체 dt 보간 이동 (도메인이 자기 갱신)
        player.update(deltaTime: dt)

        // 3) 카메라 follow — Phase 1-5: 드론 follow. player가 늘 화면 정중앙. 클램프 없음 (회피 게임 본질)
        cameraNode.position = player.position

        // 4) Phase 2-6 — 적 직선 추적 (player 위치를 향해 velocity 갱신)
        // Phase 2-8 — 게임 진행률 0 ~ 1 (시작 0, 끝 1). remainingTime은 max(0, ...)으로 음수 방지.
        // speedT는 CGFloat (EnemyNode.update 시그니처 일치) — TimeInterval(Double) → CGFloat 변환.
        let curveT = CGFloat(1.0 - remainingTime / GameConfig.gameDuration)
        enemy.update(deltaTime: dt, targetPosition: player.position, speedT: curveT)

        // 5) HUD 라벨 갱신 (Phase 2-4)
        hud.update(score: score, remainingTime: remainingTime, combo: combo)
    }

    // MARK: - Contact Router
    /// ContactRouter의 4개 콜백을 등록. didMove 안에서 1회 호출.
    /// 콤보/점수 로직은 onNoteCollected 콜백 안에 *그대로 인라인* — Phase 2-12에서 ScoreSystem으로 분리 예정.
    /// onProjectileHitWall은 self 미사용 — [weak self] 불필요.
    private func configureContactRouter() {
        contactRouter.onEnemyHit = { [weak self] in
            self?.endGame()
        }
        contactRouter.onProjectileHitPlayer = { [weak self] in
            self?.endGame()
        }
        contactRouter.onProjectileHitWall = { node in
            node.run(.removeFromParent())
        }
        contactRouter.onNoteCollected = { [weak self] note in
            guard let self = self else { return }
            let now = self.lastUpdateTime
            let isInWindow = self.combo > 0 && now - self.lastCollectAt < GameConfig.comboWindow
            self.combo = isInWindow ? self.combo + 1 : 1
            self.score += self.combo >= GameConfig.comboBonusThreshold
                ? GameConfig.scorePerNoteCombo
                : GameConfig.scorePerNote
            self.lastCollectAt = now
            note.run(.removeFromParent())
        }
    }

    // MARK: - End
    /// 시간 만료 / enemy 접촉 / F 피격 시 호출. gameState 전환 + 모든 액션·velocity 정지.
    /// HUD는 0초 표시로 마무리. 게임오버 화면/페이드는 Phase 3.
    /// Phase 2-10 — spawn / fire 정지 + projectile velocity 정지를 SpawnSystem.stop()으로 위임.
    private func endGame() {
        gameState = .gameOver
        spawnSystem.stop()
        player.currentDirection = .zero
        player.physicsBody?.velocity = .zero
        enemy.physicsBody?.velocity = .zero   // Phase 2-6 — 관성 정지
        hud.update(score: score, remainingTime: 0, combo: 0)
    }
}
