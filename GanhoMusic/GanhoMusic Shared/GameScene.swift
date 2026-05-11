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
//  Phase 2-12 · score / combo / lastCollectAt + 콤보 갱신 로직을 ScoreSystem으로 분리 (순수 리팩터)
//  Phase 3-1+2 · GameOverOverlay 부착 + endGame 멱등 가드 + touchesBegan으로 TitleScene 복귀
//  Phase 3-3 · 결과 표시를 ResultScene으로 분리 — 오버레이/터치/가드 폐기, endGame은 presentScene만
//  Phase 3-4 · HighScoreRepository 주입 + endGame에서 record → bestScore/isNewBest를 ResultScene에 전달
//  Phase 3-5 · StatisticsRepository 주입 + endGame에서 recordPlay → stats를 ResultScene에 전달
//  Phase 3 종결 후 리팩터 — setup/add 9개 메서드를 GameScene+Setup.swift로 분리
//  Phase 4-1 · StoneGuardNode 1마리 추가 (시계방향 4 waypoint 패트롤, PhysicsBody 없음 — 시각만)
//  Phase 4-2 · StoneGuardNode PhysicsBody 부착 + ContactRouter onStoneGuardContact stub
//  Phase 4-3 · AIRFORCE 이스터에그 — Player ↔ StoneGuard 첫 접촉 시 비행기 가로지르기 1회
//

import SpriteKit

/// 게임 메인 씬. Phase 1-3 시점에는 PlayerNode(worldNode 자식)와
/// DPadNode(cameraNode 자식)로 사용자 입력 → 캐릭터 이동 → 카메라 추종 골격을 완성한다.
/// 맵 경계/물리/HUD/스폰은 후속 Phase에서 추가.
/// Phase 2-11 — 충돌 분기는 ContactRouter가 담당. GameScene은 콜백 등록만.
class GameScene: SKScene {

    // MARK: - Properties
    // Phase 3 종결 후 리팩터 — GameScene+Setup.swift extension 접근 위해 private 해제 (필수 연동 변경).
    var gameState: GameState = .waiting
    var lastUpdateTime: TimeInterval = 0
    let hud = HUDNode()                                         // Phase 2-4 — cameraNode 자식
    var remainingTime: TimeInterval = GameConfig.gameDuration   // Phase 2-4 — 45초 카운트다운

    // 노드 트리
    let worldNode  = SKNode()
    let cameraNode = SKCameraNode()
    let player     = PlayerNode()    // worldNode 자식 (이동함)
    let enemy      = EnemyNode()     // worldNode 자식 (player 추적, Phase 2-6)
    let stoneGuard = StoneGuardNode()  // worldNode 자식 (4 waypoint 시계방향 패트롤, Phase 4-1)
    let dpad       = DPadNode()      // cameraNode 자식 (화면 고정)

    // 시스템
    let spawnSystem = SpawnSystem()       // Phase 2-10 — spawn 책임 분리
    let contactRouter = ContactRouter()   // Phase 2-11 — 충돌 분기 책임 분리
    let scoreSystem = ScoreSystem()       // Phase 2-12 — 점수 / 콤보 책임 분리
    let highScoreRepo = HighScoreRepository()   // Phase 3-4 — 최고 점수 영구 저장소
    let statsRepo = StatisticsRepository()      // Phase 3-5 — 누적 통계 영구 저장소

    // Phase 4-3 — AIRFORCE 이스터에그 1회 한정 가드. true가 되면 재발동 안 함.
    // 새 GameScene 인스턴스에서 자동 false로 리셋됨.
    private var airforceTriggered: Bool = false

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
        setupStoneGuard()    // Phase 4-1 신설 — StoneGuardNode를 worldNode 자식으로 (4 waypoint 시계방향)
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

    /// scene.size 변경 시(viewport 회전·resize)에 위치만 재계산. addChild 0건 — 멱등 보장.
    /// cameraNode 자식 좌표계: (0,0) = 화면 중앙, +x 우, +y 상. 우하단 = (+x, -y).
    func layoutDPad() {
        let halfW = size.width  / 2
        let halfH = size.height / 2
        dpad.position = CGPoint(
            x: +(halfW - GameConfig.dpadMarginX),
            y: -(halfH - GameConfig.dpadMarginY)
        )
    }

    /// scene.size 변경 시 위치만 재계산. addChild 0건 — 멱등.
    /// cameraNode 자식 좌표계: (0,0) = 화면 중앙. 좌상단 = (-x, +y). D-Pad와 부호만 반전.
    func layoutHUD() {
        let halfW = size.width  / 2
        let halfH = size.height / 2
        hud.position = CGPoint(
            x: -(halfW - GameConfig.hudMarginX),
            y: +(halfH - GameConfig.hudMarginY)
        )
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

        // Phase 2-5 — 콤보 윈도우 만료 검사 (Phase 2-12: ScoreSystem에 위임)
        scoreSystem.tickComboExpiry(currentTime: currentTime)

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

        // 5) HUD 라벨 갱신 (Phase 2-4) — Phase 2-12: ScoreSystem에서 값 조회
        hud.update(score: scoreSystem.score, remainingTime: remainingTime, combo: scoreSystem.combo)
    }

    // MARK: - Contact Router
    /// ContactRouter의 4개 콜백을 등록. didMove 안에서 1회 호출.
    /// Phase 2-12 — onNoteCollected의 콤보/점수 로직은 ScoreSystem.recordNoteHit으로 위임.
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
            self.scoreSystem.recordNoteHit(at: self.lastUpdateTime)
            note.run(.removeFromParent())
        }
        contactRouter.onStoneGuardContact = { [weak self] in
            self?.triggerAirforceEasterEgg()
        }
    }

    // MARK: - Easter Egg
    /// Player ↔ StoneGuard 첫 접촉 시 호출. 1회 한정 가드 후 비행기 1마리를 cameraNode에 부착,
    /// 좌→우 가로지르기 SKAction 실행. AirplaneNode가 자가 소멸하므로 GameScene은 후속 정리 0건.
    /// 점수/HUD/적/게임오버 로직 일체 미접촉 — 순수 시각 이스터에그.
    private func triggerAirforceEasterEgg() {
        if airforceTriggered { return }
        airforceTriggered = true
        let plane = AirplaneNode()
        cameraNode.addChild(plane)
        let y = +(size.height / 2 - GameConfig.airplaneTopOffset)
        plane.crossScreen(sceneWidth: size.width, atY: y)
    }

    // MARK: - Game State
    /// 시간 만료 / enemy 접촉 / F 피격 시 호출. gameState 전환 + 모든 액션·velocity 정지.
    /// Phase 2-10 — spawn / fire 정지 + projectile velocity 정지를 SpawnSystem.stop()으로 위임.
    /// Phase 3-1+2 — 멱등 가드 추가 (적/F/시간 동시 발생 시 1회만 실행).
    /// Phase 3-3 — 오버레이/가드 패턴 폐기. 정지 작업 후 ResultScene으로 fade transition.
    private func endGame() {
        // 멱등 가드 — 이미 종료됐으면 아무 것도 안 함.
        if gameState == .gameOver { return }
        gameState = .gameOver
        spawnSystem.stop()
        player.currentDirection = .zero
        player.physicsBody?.velocity = .zero
        enemy.physicsBody?.velocity = .zero   // Phase 2-6 — 관성 정지
        hud.update(score: scoreSystem.score, remainingTime: 0, combo: 0)

        // Phase 3-3 — 결과 표시는 ResultScene이 담당. presentScene 직후 GameScene 자식은 ARC로 해제됨.
        // Phase 3-4 — record → current 순서가 핵심. record가 디스크를 갱신한 *직후* current를 읽으면
        // 신기록일 때 bestScore가 *이번 점수*가 된다(자기 일관성).
        // Phase 3-5 — recordPlay → current도 같은 record/current 패턴.
        // 순서: record(highScore) → current(best) → recordPlay(stats) → current(stats).
        guard let view = self.view else { return }
        let score = scoreSystem.score
        let isNewBest = highScoreRepo.record(score)
        let bestScore = highScoreRepo.current
        statsRepo.recordPlay(score: score)
        let stats = statsRepo.current
        let resultScene = ResultScene.newResultScene(
            score: score, bestScore: bestScore, isNewBest: isNewBest, stats: stats
        )
        view.presentScene(resultScene, transition: .fade(withDuration: GameConfig.sceneTransitionDuration))
    }
}
