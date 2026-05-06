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
//

import SpriteKit

/// 게임 메인 씬. Phase 1-3 시점에는 PlayerNode(worldNode 자식)와
/// DPadNode(cameraNode 자식)로 사용자 입력 → 캐릭터 이동 → 카메라 추종 골격을 완성한다.
/// 맵 경계/물리/HUD/스폰은 후속 Phase에서 추가.
/// Phase 2-3 — SKPhysicsContactDelegate 채택 (player↔note contact 알림 수신).
class GameScene: SKScene, SKPhysicsContactDelegate {

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
    private let dpad       = DPadNode()      // cameraNode 자식 (화면 고정)

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
        physicsWorld.gravity = .zero   // Phase 2-2 — 탑다운 게임이라 중력 없음
        physicsWorld.contactDelegate = self   // Phase 2-3 — didBegin 알림 수신
        startSpawnLoop()                      // Phase 2-3 — 음표 자동 스폰 시작
        gameState = .playing // playing 전환 후에야 update가 동작
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
        player.position = CGPoint(
            x: GameConfig.mapWidth  / 2,
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
        // cameraNode 자식 좌표계: (0,0) = 화면 중앙, +x 우, +y 상.
        // scene.size = 1024×768. 우하단 = (+x, -y).
        let halfW = size.width  / 2
        let halfH = size.height / 2
        dpad.position = CGPoint(
            x: +(halfW - GameConfig.dpadMarginX),
            y: -(halfH - GameConfig.dpadMarginY)
        )
        cameraNode.addChild(dpad)
    }

    private func setupHUD() {
        // cameraNode 자식 좌표계: (0,0) = 화면 중앙. 좌상단 = (-x, +y).
        // D-Pad(우하단)와 부호만 반전 — 1-3 패턴 재활용.
        let halfW = size.width  / 2
        let halfH = size.height / 2
        hud.position = CGPoint(
            x: -(halfW - GameConfig.hudMarginX),
            y: +(halfH - GameConfig.hudMarginY)
        )
        cameraNode.addChild(hud)
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

        // 4) HUD 라벨 갱신 (Phase 2-4)
        hud.update(score: score, remainingTime: remainingTime, combo: combo)
    }

    // MARK: - Spawn
    /// 음표 자동 스폰 루프 시작. SKAction.repeatForever — Timer 금지 룰 준수.
    /// withKey: "spawnNotes"로 등록해 추후 stop/replace 가능하게.
    private func startSpawnLoop() {
        let wait  = SKAction.wait(forDuration: GameConfig.noteSpawnInterval)
        // 지역 변수명 spawn — `run` 이라 쓰면 self.run(_:withKey:)와 모호 충돌.
        let spawn = SKAction.run { [weak self] in self?.trySpawnNote() }
        let loop  = SKAction.repeatForever(.sequence([wait, spawn]))
        self.run(loop, withKey: "spawnNotes")
    }

    /// 한 사이클당 1회 호출. 동시 음표 수 5 미만일 때만 1개 스폰.
    /// 위치 후보가 중앙 기둥 충돌 시 nil — 다음 1.5초에 재시도 (skip).
    private func trySpawnNote() {
        guard currentNoteCount() < GameConfig.noteMaxConcurrent else { return }
        guard let position = randomNotePosition() else { return }
        let note = NoteNode()
        note.position = position
        worldNode.addChild(note)
    }

    /// worldNode 안 음표 ("note" 이름) 개수 카운트. 1.5초마다 1회라 비용 무시 가능.
    private func currentNoteCount() -> Int {
        var count = 0
        worldNode.enumerateChildNodes(withName: "note") { _, _ in count += 1 }
        return count
    }

    /// 외곽 1tile 마진 안쪽 균등 랜덤. 중앙 기둥 manhattan 회피 (3 tile 이내면 nil).
    private func randomNotePosition() -> CGPoint? {
        let margin = GameConfig.tileSize
        let x = CGFloat.random(in: margin ... GameConfig.mapWidth  - margin)
        let y = CGFloat.random(in: margin ... GameConfig.mapHeight - margin)
        let cx = GameConfig.mapWidth  / 2
        let cy = GameConfig.mapHeight / 2
        // 60pt 매직 넘버 회피: tileSize * 3 (= 20 × 3, 자명한 산수)
        if abs(x - cx) + abs(y - cy) < GameConfig.tileSize * 3 {
            return nil
        }
        return CGPoint(x: x, y: y)
    }

    // MARK: - Contact
    /// player↔note contact 발생 시 호출. note만 식별 (contactTest가 player↔note 둘만 활성).
    /// 노드 즉시 제거 금지 룰 — `note.run(.removeFromParent())`로 액션 위임.
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        let noteBody: SKPhysicsBody?
        if bodyA.categoryBitMask == PhysicsCategory.note {
            noteBody = bodyA
        } else if bodyB.categoryBitMask == PhysicsCategory.note {
            noteBody = bodyB
        } else {
            noteBody = nil
        }
        guard let note = noteBody?.node else { return }
        let now = lastUpdateTime
        let isInWindow = combo > 0 && now - lastCollectAt < GameConfig.comboWindow
        combo = isInWindow ? combo + 1 : 1
        score += combo >= GameConfig.comboBonusThreshold
            ? GameConfig.scorePerNoteCombo
            : GameConfig.scorePerNote
        lastCollectAt = now
        note.run(.removeFromParent())
    }

    // MARK: - End
    /// 시간 만료 시 호출. gameState 전환 + spawn 정지 + player 정지(둘 다).
    /// HUD는 0초 표시로 마무리. 게임오버 화면/페이드는 Phase 3.
    private func endGame() {
        gameState = .gameOver
        removeAction(forKey: "spawnNotes")
        player.currentDirection = .zero
        player.physicsBody?.velocity = .zero
        hud.update(score: score, remainingTime: 0, combo: 0)
    }
}
