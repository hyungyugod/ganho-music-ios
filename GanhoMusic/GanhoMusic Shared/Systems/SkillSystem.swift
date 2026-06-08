//
//  SkillSystem.swift
//  GanhoMusic Shared
//
//  Phase 9-5 · 캐릭터별 스킬 시스템 컨트롤러
//
//  활성 스킬 1개 보유 + update(dt:)로 쿨다운/지속시간 진행.
//  GameScene 단방향 참조(weak) — Player/worldNode/cameraNode를 직접 만진다.
//  switch default 미사용 — 5 case exhaustive(미래 신규 케이스 추가 시 자연 컴파일 에러).
//

import SpriteKit

/// 캐릭터별 능동 스킬을 *단일 활성 슬롯*으로 통일 관리.
/// GameScene이 매 프레임 `update(dt:)` 호출 + 사용자 1탭 시 `tryActivate()` 호출.
/// HUD는 `progress` 프로퍼티를 폴링해 진행률 0.0~1.0 시각화.
final class SkillSystem {

    // MARK: - State (read-only 외부 노출)
    /// 현재 활성 스킬. `configure(scene:skill:)`이 1회 set.
    /// 김간호(.none)는 tryActivate 호출 자체가 noop.
    private(set) var activeSkill: PlayerSkill = .none

    /// 쿨다운 잔여 시간(초). 0이면 발동 가능.
    /// update(dt:)가 매 프레임 max(0, -dt) 감산.
    private(set) var cooldownRemaining: TimeInterval = 0

    /// 지속 시간 잔여(초). 0이면 효과 종료 상태.
    /// 매혹/돌진/텔레포트의 지속 효과 만료를 update에서 감지.
    private(set) var durationRemaining: TimeInterval = 0

    /// 게임당 1회 스킬(.charmStudent)의 사용 여부.
    /// true가 되면 progress=0 영구 + tryActivate 차단.
    private(set) var usedThisGame: Bool = false

    /// 외부(GameScene) 참조 — weak. SKAction 클로저 [weak self] 함께 메모리 누수 방지.
    private weak var scene: GameScene?

    /// 정간호 돌진 직전 마지막 이동 방향. DPad.currentDirection이 .zero일 때 이걸 사용.
    /// .zero면 기본 우측(1, 0). 발동 시점에만 캡처되므로 매 프레임 갱신은 GameScene이 담당.
    private var lastDirection: CGVector = CGVector(dx: 1, dy: 0)

    // MARK: - Configuration
    /// GameScene이 didMove/startGameProperly에서 1회 호출.
    /// scene = 본체, skill = characterID.skill.
    /// 이미 활성 스킬이 있어도 덮어쓰기 안전 — 재시작 시점에 자연 재설정.
    func configure(scene: GameScene, skill: PlayerSkill) {
        self.scene = scene
        self.activeSkill = skill
        self.cooldownRemaining = 0
        self.durationRemaining = 0
        self.usedThisGame = false
    }

    // MARK: - Update Loop
    /// GameScene.update가 매 프레임 호출. 쿨다운/지속시간 감산 + 만료 콜백.
    /// dt가 음수일 수 없으나 max(0, ...) 가드로 안전.
    func update(dt: TimeInterval) {
        if cooldownRemaining > 0 {
            cooldownRemaining = max(0, cooldownRemaining - dt)
        }
        if durationRemaining > 0 {
            let next = max(0, durationRemaining - dt)
            durationRemaining = next
            // 0에 *방금 도달한* 프레임에 만료 처리.
            // charmStudent는 새 발사체 변환 창만 닫고, 이미 매혹된 F/A는 보상으로 유지한다.
            if next == 0 {
                onDurationExpired()
            }
        }

        // 현재 D-Pad 방향이 .zero가 아니면 마지막 방향으로 저장 — 돌진 발동 시 사용.
        // GameScene.update에서 매 프레임 호출하므로 self-contained.
        if let dpadDir = scene?.dpad.currentDirection,
           let normalized = normalizedDirection(dpadDir) {
            lastDirection = normalized
        }
    }

    // MARK: - Activation Entry Point
    /// 사용자 1탭 시 SkillButtonNode가 호출. 가드 통과 시 스킬별 본체로 분기.
    /// 3중 가드: (1) .none 차단 / (2) 쿨다운 잔여 시 차단 / (3) usedThisGame 차단.
    func tryActivate() {
        guard activeSkill != .none else { return }
        guard cooldownRemaining <= 0 else { return }
        guard !(activeSkill.oncePerGame && usedThisGame) else { return }

        switch activeSkill {
        case .none:
            return  // 위 가드에서 차단됨 — 도달 불가지만 exhaustive 위해 명시.
        case .dashClimb:
            performDashClimb()
        case .bookClubRally:
            performBookClubRally()
        case .charmStudent:
            performCharmStudent()
        case .taiwanTrip:
            performTaiwanTrip()
        }

        // 발동 직후 쿨다운/지속시간 set. oncePerGame은 usedThisGame로 영구 차단.
        cooldownRemaining = activeSkill.cooldown
        durationRemaining = activeSkill.duration
        if activeSkill.oncePerGame {
            usedThisGame = true
        }
    }

    // MARK: - Progress (HUD 폴링용)
    /// 0.0(쿨다운 시작 직후) ~ 1.0(사용 가능). 김간호는 항상 1.0(빈 슬롯).
    /// charmStudent + usedThisGame=true는 영구 0.0.
    /// HUDSkillSlotNode.update(progress:)에 매 프레임 1줄로 전달.
    var progress: CGFloat {
        switch activeSkill {
        case .none:
            // 김간호: 항상 *사용 가능* 슬롯이지만 시각적으로는 별도 처리(빈 슬롯).
            return 1.0
        case .charmStudent:
            // 1회 소진 시 영구 0. 미사용 시 1.0(쿨다운 무관).
            return usedThisGame ? 0 : 1.0
        case .dashClimb, .bookClubRally, .taiwanTrip:
            if cooldownRemaining <= 0 { return 1.0 }
            let total = activeSkill.cooldown
            // total이 양수임은 cooldownRemaining > 0인 시점에서 보장됨.
            let p = 1.0 - cooldownRemaining / total
            // CGFloat 변환 + clamp(0~1).
            return CGFloat(max(0, min(1, p)))
        }
    }

    /// 정간호 돌진 중인지. GameScene.update가 player.currentDirection 갱신을 *건너뛰는* 가드.
    /// dashClimb의 durationRemaining이 양수인 동안만 true.
    var isDashing: Bool {
        return activeSkill == .dashClimb && durationRemaining > 0
    }

    /// 임간호 매혹 활성 중인지. SpawnSystem.fireProjectile가 *출생 시점 enchanted* 분기 가드.
    /// charmStudent의 durationRemaining이 양수인 동안만 true.
    var isCharmActive: Bool {
        return activeSkill == .charmStudent && durationRemaining > 0
    }

    // MARK: - Duration Expiry
    /// durationRemaining이 0으로 떨어진 *순간* 호출. 활성 스킬별 정리.
    private func onDurationExpired() {
        switch activeSkill {
        case .none, .dashClimb, .bookClubRally, .taiwanTrip:
            // 각자 자체 SKAction 콜백에서 정리 — 여기선 noop.
            return
        case .charmStudent:
            return
        }
    }

    // MARK: - 1. Dash Climb (정간호)
    /// 4 tile 거리 돌진 + 무적 + 경로상 F 제거 + 착지 충격파(유지).
    /// 추가: (점수) 돌진 경로 음표 흡수, (생존) 착지 주변 F 원형 정화 + 착지 후 무적 연장,
    ///       (타격감) 착지 순간 카메라 진동 + 헤비 햅틱.
    /// 방향: DPad.currentDirection → lastDirection → 기본 우측 fallback.
    private func performDashClimb() {
        guard let scene = scene else { return }
        let player = scene.player
        let direction = currentDashDirection()

        // 시작/끝 좌표 계산.
        let start = player.position
        let rawEnd = CGPoint(
            x: start.x + direction.dx * GameConfig.dashClimbDistance,
            y: start.y + direction.dy * GameConfig.dashClimbDistance
        )
        let end = dashLandingTarget(from: start, rawEnd: rawEnd)

        clearProjectilesInCorridor(
            from: start,
            to: end,
            halfWidth: GameConfig.dashClimbProjectileClearHalfWidth
        )
        // (점수) 돌진 경로 corridor 안 음표 흡수 — F 제거보다 약간 넓은 폭으로 "지나가며 빨아들임".
        pullCollectiblesInCorridor(from: start, to: end,
                                   halfWidth: GameConfig.dashClimbCollectHalfWidth,
                                   color: .ganhoBloodAccent)
        // (생존) 착지 주변 F 원형 정화 — corridor 밖까지.
        clearProjectiles(near: end, radius: GameConfig.dashClimbLandingPurgeRadius)
        spawnSkillTrail(from: start, to: end, color: .ganhoBloodAccent, parent: scene.worldNode)

        // 무적 + 이동.
        player.currentDirection = .zero
        player.physicsBody?.velocity = .zero
        player.isInvulnerable = true
        player.removeAction(forKey: GameConfig.dashClimbActionKey)
        let move = SKAction.move(to: end, duration: GameConfig.dashClimbDuration)
        let impact = SKAction.run { [weak self] in
            guard let self = self, let scene = self.scene else { return }
            self.spawnSkillRing(
                at: end,
                radius: GameConfig.dashClimbImpactRadius,
                color: .ganhoBloodAccent,
                parent: scene.worldNode
            )
            scene.cameraNode.run(CameraShakeAction.make())   // 타격감: 화면 진동
            scene.haptics.heavy()                              // 타격감: 헤비 햅틱
        }
        // (생존) 무적 연장: 착지 후 바로 끄지 않고 dashClimbLandingInvulnerableExtra초 더 유지 후 해제.
        let extendInvuln = SKAction.wait(forDuration: GameConfig.dashClimbLandingInvulnerableExtra)
        let endAction = SKAction.run { [weak player] in
            player?.isInvulnerable = false
            player?.physicsBody?.velocity = .zero
        }
        player.run(.sequence([move, impact, extendInvuln, endAction]),
                   withKey: GameConfig.dashClimbActionKey)
    }

    /// DPad → lastDirection → 기본 우측 순서로 방향 벡터 결정.
    private func currentDashDirection() -> CGVector {
        guard let scene = scene else {
            return CGVector(dx: 1, dy: 0)
        }
        let dpadDir = scene.dpad.currentDirection
        if let normalized = normalizedDirection(dpadDir) {
            return normalized
        }
        if let normalized = normalizedDirection(lastDirection) {
            return normalized
        }
        return CGVector(dx: 1, dy: 0)
    }

    private func normalizedDirection(_ vector: CGVector) -> CGVector? {
        let length = hypot(vector.dx, vector.dy)
        guard length >= GameConfig.dpadInputSnapEpsilon else { return nil }
        return CGVector(dx: vector.dx / length, dy: vector.dy / length)
    }

    /// start→end 선분에 가장 가까운 *첫* breakableWall 1개를 fadeOut + 제거.
    /// breakableWall name으로 enumerate — name 없는 외곽 벽/장식 기둥/hard 맵 벽은 미선택.
    /// 두 점 사이 manhattan 거리 < dashClimbDistance 가드로 *지나가는* 벽만 대상.
    private func breakFirstBreakableWall(from start: CGPoint, to end: CGPoint) {
        guard let world = scene?.worldNode else { return }
        var found: SKNode?
        var bestDistance: CGFloat = .greatestFiniteMagnitude
        world.enumerateChildNodes(withName: GameConfig.breakableWallName) { node, _ in
            // 시작점에서 벽까지 manhattan 거리.
            let dx = node.position.x - start.x
            let dy = node.position.y - start.y
            let distance = abs(dx) + abs(dy)
            // 돌진 거리 + 1 tile 여유 안쪽 + 시작점보다 *진행 방향*인 노드만.
            // 방향 dot product가 양수 = 진행 방향(역행 벽 무시).
            let forward = dx * (end.x - start.x) + dy * (end.y - start.y)
            guard forward > 0 else { return }
            guard distance < GameConfig.dashClimbDistance + GameConfig.tileSize else { return }
            if distance < bestDistance {
                bestDistance = distance
                found = node
            }
        }
        guard let wall = found else { return }
        // 즉시 removeFromParent 대신 fadeOut + 제거 — 시각적 자연 톤.
        // physics 콜백 안이 아니므로 즉시 제거도 안전하지만 fadeOut으로 *부서지는* 느낌.
        wall.run(.sequence([
            .fadeOut(withDuration: 0.15),
            .removeFromParent()
        ]))
    }

    // MARK: - 2. Book Club Rally (건간호)
    /// 반경 8타일 안 노트(+A아이템)를 player 위치로 끌어오기 + 같은 반경 F 일괄 정화("안전지대 폭발").
    /// 도착 시점 자연 contact → onNoteCollected/onAItemCollected 정상 발화 → 점수/콤보 자동.
    /// "이펙트가 안 와닿는다" 대응: 2겹 충격파 링 + 헤비 햅틱 + 카메라 펄스로 시각/촉각 가중치 최우선.
    private func performBookClubRally() {
        guard let scene = scene else { return }
        let world = scene.worldNode
        let center = scene.player.position
        let radius = GameConfig.bookClubRallyRadius

        // (생존) 같은 반경 F 일괄 정화 — "안전지대 폭발".
        clearProjectiles(near: center, radius: radius)

        // (타격감) 2겹 충격파 링 — 바깥 1겹 + 안쪽 1겹(반경/색 살짝 다르게).
        spawnSkillRing(at: center, radius: radius, color: .ganhoMint, parent: world)
        spawnSkillRing(at: center,
                       radius: radius * GameConfig.bookClubRallyOuterRingRatio,
                       color: .ganhoCyanBeat,
                       parent: world)
        scene.haptics.heavy()
        // (선택) 카메라 펄스 — 발동당 1회만(변위 누적 방지).
        scene.cameraNode.run(CameraShakeAction.make())

        // (점수+시각) 음표 흡수 + A아이템 흡수는 pullCollectibles로 일원화 + 반짝이 다수.
        pullCollectibles(near: center, radius: radius, includeAItems: true, color: .ganhoMint)
    }

    /// 반경/corridor 흡수 헬퍼가 공유하는 *중립* 끌어오기 액션 생성기(DRY — dash/rally/taiwanTrip 공용).
    /// 고정 좌표가 아니라 현재 player 위치를 계속 참조(customAction)해 player가 이동 중이어도 누락을 줄인다.
    /// 점수는 직접 건드리지 않고 player-note / player-aItem contact 경로만 사용한다.
    /// (구 bookClubRallyPullAction을 중립 이름으로 일반화 — 동작/액션 키 보존.)
    private func pullCollectible(for targetNode: SKNode,
                                from startPosition: CGPoint,
                                scene: GameScene) -> SKAction {
        let duration = GameConfig.bookClubRallyMoveDuration
        guard duration > 0 else {
            return SKAction.run { [weak scene, weak targetNode] in
                guard let scene = scene, let targetNode = targetNode else { return }
                targetNode.position = scene.player.position
            }
        }

        let durationCGFloat = CGFloat(duration)
        let pull = SKAction.customAction(withDuration: duration) { [weak scene] actionNode, elapsed in
            guard let scene = scene else { return }
            let target = scene.player.position
            let rawProgress = min(1, max(0, elapsed / durationCGFloat))
            let easedProgress = rawProgress * rawProgress
            actionNode.position = CGPoint(
                x: startPosition.x + (target.x - startPosition.x) * easedProgress,
                y: startPosition.y + (target.y - startPosition.y) * easedProgress
            )
        }
        let settleOnPlayer = SKAction.run { [weak scene, weak targetNode] in
            guard let scene = scene, let targetNode = targetNode else { return }
            targetNode.position = scene.player.position
        }
        return SKAction.sequence([pull, settleOnPlayer])
    }

    /// 반경 안 "note"(필요 시 "aItem")를 player로 끌어와 contact→자동 수집(DRY — dash/rally/taiwanTrip 공용).
    /// 점수/콤보 직접 set 금지 — 끌어오기→contact 경로만(ScoreSystem 회귀 0).
    /// note는 onNoteCollected → recordNoteHit, aItem은 onAItemCollected → recordCharmedNoteHit(×2)로 자동 가산.
    /// enumerate는 발동 시 1회만 — 매 프레임 호출 아님. player 이동 중이어도 pullCollectible이 실시간 참조.
    private func pullCollectibles(near center: CGPoint,
                                 radius: CGFloat,
                                 includeAItems: Bool,
                                 color: UIColor) {
        guard let scene = scene else { return }
        let world = scene.worldNode
        let radiusSquared = radius * radius
        world.enumerateChildNodes(withName: "note") { [weak self] node, _ in
            guard let self = self else { return }
            let dx = node.position.x - center.x
            let dy = node.position.y - center.y
            // 거리^2 비교 — sqrt 회피(성능).
            guard dx * dx + dy * dy < radiusSquared else { return }
            node.removeAction(forKey: GameConfig.noteBobActionKey)
            let start = node.position
            self.spawnSkillSparkle(at: start, color: color, parent: world)
            node.run(self.pullCollectible(for: node, from: start, scene: scene),
                     withKey: GameConfig.bookClubRallyPullActionKey)
        }
        guard includeAItems else { return }
        world.enumerateChildNodes(withName: "aItem") { [weak self] node, _ in
            guard let self = self else { return }
            let dx = node.position.x - center.x
            let dy = node.position.y - center.y
            guard dx * dx + dy * dy < radiusSquared else { return }
            // A아이템은 bob 액션이 없고 physicsBody.velocity로 이동 → 끌어오기 전 정지 필수(떨림 방지).
            node.physicsBody?.velocity = .zero
            let start = node.position
            self.spawnSkillSparkle(at: start, color: color, parent: world)
            node.run(self.pullCollectible(for: node, from: start, scene: scene),
                     withKey: GameConfig.bookClubRallyPullActionKey)
        }
    }

    /// start→end 선분(corridor) 안 "note"를 player로 끌어와 contact→자동 수집(돌진 "지나가며 빨아들임").
    /// clearProjectilesInCorridor의 enumerate + squaredDistanceFromPointToSegment 패턴을 음표용으로 미러링.
    /// 점수/콤보 직접 set 금지 — 끌어오기→contact 경로만(ScoreSystem 회귀 0).
    private func pullCollectiblesInCorridor(from start: CGPoint,
                                           to end: CGPoint,
                                           halfWidth: CGFloat,
                                           color: UIColor) {
        guard let scene = scene else { return }
        let world = scene.worldNode
        let limitSquared = halfWidth * halfWidth
        world.enumerateChildNodes(withName: "note") { [weak self] node, _ in
            guard let self = self else { return }
            let distanceSquared = self.squaredDistanceFromPointToSegment(
                point: node.position,
                start: start,
                end: end
            )
            guard distanceSquared <= limitSquared else { return }
            node.removeAction(forKey: GameConfig.noteBobActionKey)
            let startPosition = node.position
            self.spawnSkillSparkle(at: startPosition, color: color, parent: world)
            node.run(self.pullCollectible(for: node, from: startPosition, scene: scene),
                     withKey: GameConfig.bookClubRallyPullActionKey)
        }
    }

    // MARK: - 3. Charm Student (임간호)
    /// 모든 활성 F를 enchanted로 전환. 새로 발사되는 F는 EnemyNode의 charmActiveProvider가 A로 바꾼다.
    /// 매혹된 F/A는 지속시간이 끝나도 보상 상태를 유지해 사용자가 효과를 명확히 체감하게 한다.
    private func performCharmStudent() {
        guard let scene = scene else { return }
        let world = scene.worldNode
        // ── 기존 게임성 100% 유지 (절대 변경 금지) ──
        ToastLabelNode.spawn(text: GameConfig.charmStudentToastText,
                             at: scene.enemy.position,
                             parent: world)
        world.enumerateChildNodes(withName: "projectile") { node, _ in
            if let projectile = node as? FProjectileNode {
                projectile.applyEnchanted()
            }
        }
        // ── 신규: 시각·햅틱만 추가 (게임 수치 0 변경) ──
        // 매혹 테마색은 코랄·피치 톤. ColorTokens에 ganhoPeachAccent 미존재 → 실재 토큰 ganhoCoralPrimary 사용.
        let center = scene.player.position
        spawnSkillRing(at: center,
                       radius: GameConfig.charmStudentRingRadius,
                       color: .ganhoCoralPrimary,
                       parent: world)
        spawnSkillRing(at: center,
                       radius: GameConfig.charmStudentRingRadius * GameConfig.charmStudentOuterRingRatio,
                       color: .ganhoCoralPrimary,
                       parent: world)                              // 하트펄스 톤 2겹
        scene.cameraNode.run(CameraShakeAction.make())             // 화면 전체 진동
        scene.haptics.medium()
    }

    // MARK: - 4. Taiwan Trip (이간호)
    /// 현재 위치의 반대 대각선 코너 쪽 안전 지점으로 멀리 텔레포트(유지).
    /// 추가: (점수) 착지 주변 음표 흡수, (생존) 출발 지점 F 정화 + 무적 1.0→1.6초 연장,
    ///       (타격감) 헤비 햅틱(카메라 진동은 기존 유지).
    private func performTaiwanTrip() {
        guard let scene = scene else { return }
        let player = scene.player
        let start = player.position
        let targetPosition = taiwanTripTarget(from: start)

        spawnSkillRing(
            at: start,
            radius: GameConfig.taiwanTripDepartureRingRadius,
            color: .ganhoCyanBeat,
            parent: scene.worldNode
        )
        // (생존) 출발 지점 F도 제거 — 텔레포트 전 발밑 정리.
        clearProjectiles(near: start, radius: GameConfig.taiwanTripDeparturePurgeRadius)

        // 즉시 위치 이동.
        player.position = targetPosition

        spawnSkillRing(
            at: targetPosition,
            radius: GameConfig.taiwanTripLandingPurgeRadius,
            color: .ganhoCyanBeat,
            parent: scene.worldNode
        )
        // (점수) 착지 주변 음표 흡수.
        pullCollectibles(near: targetPosition,
                         radius: GameConfig.taiwanTripCollectRadius,
                         includeAItems: false,
                         color: .ganhoCyanBeat)
        clearProjectiles(near: targetPosition, radius: GameConfig.taiwanTripLandingPurgeRadius)
        scene.cameraNode.run(CameraShakeAction.make())   // 기존 유지
        scene.haptics.heavy()                              // 타격감 추가

        // 무적 + 깜빡임. 동시에 set/clear.
        player.isInvulnerable = true
        player.removeAction(forKey: GameConfig.taiwanTripBlinkActionKey)
        player.removeAction(forKey: GameConfig.taiwanTripInvulnerableActionKey)
        applyTaiwanTripBlink(to: player)
    }

    /// 텔레포트 후보가 맵 안 + 벽 미겹침인지 검사.
    /// 맵 경계: 외곽 벽 안쪽 1tile 여유. 벽 검사: physicsWorld.body(at:) 사용.
    private func isValidTeleportTarget(_ point: CGPoint) -> Bool {
        let margin = GameConfig.tileSize
        guard point.x >= margin, point.x <= GameConfig.mapWidth - margin else { return false }
        guard point.y >= margin, point.y <= GameConfig.mapHeight - margin else { return false }
        return isValidPlayerTarget(point)
    }

    private func clampedToMap(_ point: CGPoint) -> CGPoint {
        let margin = GameConfig.tileSize
        return CGPoint(
            x: min(max(point.x, margin), GameConfig.mapWidth - margin),
            y: min(max(point.y, margin), GameConfig.mapHeight - margin)
        )
    }

    private func taiwanTripTarget(from start: CGPoint) -> CGPoint {
        let margin = GameConfig.tileSize
        let center = CGPoint(x: GameConfig.mapWidth / 2, y: GameConfig.mapHeight / 2)
        let oppositeCorner = CGPoint(
            x: start.x < center.x ? GameConfig.mapWidth - margin : margin,
            y: start.y < center.y ? GameConfig.mapHeight - margin : margin
        )
        if isValidTeleportTarget(oppositeCorner) {
            return oppositeCorner
        }

        let step = GameConfig.tileSize
        let maxRing = GameConfig.taiwanTripFallbackSearchRings
        var best: CGPoint?
        var bestDistanceToCorner = CGFloat.greatestFiniteMagnitude
        for ring in 1...maxRing {
            for dx in -ring...ring {
                for dy in -ring...ring {
                    guard abs(dx) == ring || abs(dy) == ring else { continue }
                    let candidate = CGPoint(
                        x: oppositeCorner.x + CGFloat(dx) * step,
                        y: oppositeCorner.y + CGFloat(dy) * step
                    )
                    let clamped = clampedToMap(candidate)
                    guard isValidTeleportTarget(clamped) else { continue }
                    let distanceToCorner = hypot(
                        clamped.x - oppositeCorner.x,
                        clamped.y - oppositeCorner.y
                    )
                    if distanceToCorner < bestDistanceToCorner {
                        bestDistanceToCorner = distanceToCorner
                        best = clamped
                    }
                }
            }
            if let best = best {
                return best
            }
        }

        return start
    }

    // MARK: - Skill Collision / Cleanup Helpers
    private func dashLandingTarget(from start: CGPoint, rawEnd: CGPoint) -> CGPoint {
        let end = clampedToMap(rawEnd)
        if isValidPlayerTarget(end) {
            return end
        }

        let steps = max(1, GameConfig.dashClimbLandingSearchSteps)
        for step in 1...steps {
            let t = 1 - CGFloat(step) / CGFloat(steps)
            let candidate = CGPoint(
                x: start.x + (end.x - start.x) * t,
                y: start.y + (end.y - start.y) * t
            )
            if isValidPlayerTarget(candidate) {
                return candidate
            }
        }
        return start
    }

    private func isValidPlayerTarget(_ point: CGPoint) -> Bool {
        guard let scene = scene else { return true }
        let halfWidth = GameConfig.playerWidth / 2
        let halfHeight = GameConfig.playerHeight / 2
        guard point.x >= halfWidth, point.x <= GameConfig.mapWidth - halfWidth else { return false }
        guard point.y >= halfHeight, point.y <= GameConfig.mapHeight - halfHeight else { return false }
        return scene.containsWall(in: playerWallQueryRect(centeredAt: point)) == false
    }

    private func playerWallQueryRect(centeredAt point: CGPoint) -> CGRect {
        let rect = CGRect(
            x: point.x - GameConfig.playerWidth / 2,
            y: point.y - GameConfig.playerHeight / 2,
            width: GameConfig.playerWidth,
            height: GameConfig.playerHeight
        )
        return rect.insetBy(
            dx: GameConfig.playerWallQueryInset,
            dy: GameConfig.playerWallQueryInset
        )
    }

    private func clearProjectilesInCorridor(from start: CGPoint, to end: CGPoint, halfWidth: CGFloat) {
        guard let world = scene?.worldNode else { return }
        let limitSquared = halfWidth * halfWidth
        world.enumerateChildNodes(withName: "projectile") { [weak self] node, _ in
            guard let self = self else { return }
            let distanceSquared = self.squaredDistanceFromPointToSegment(
                point: node.position,
                start: start,
                end: end
            )
            guard distanceSquared <= limitSquared else { return }
            self.removeProjectileNode(node)
        }
    }

    private func clearProjectiles(near center: CGPoint, radius: CGFloat) {
        guard let world = scene?.worldNode else { return }
        let radiusSquared = radius * radius
        world.enumerateChildNodes(withName: "projectile") { [weak self] node, _ in
            guard let self = self else { return }
            let dx = node.position.x - center.x
            let dy = node.position.y - center.y
            guard dx * dx + dy * dy <= radiusSquared else { return }
            self.removeProjectileNode(node)
        }
    }

    private func removeProjectileNode(_ node: SKNode) {
        node.physicsBody?.velocity = .zero
        node.removeAllActions()
        node.run(.sequence([
            .fadeOut(withDuration: GameConfig.skillEffectFadeDuration),
            .removeFromParent()
        ]))
    }

    private func squaredDistanceFromPointToSegment(point: CGPoint,
                                                   start: CGPoint,
                                                   end: CGPoint) -> CGFloat {
        let vx = end.x - start.x
        let vy = end.y - start.y
        let wx = point.x - start.x
        let wy = point.y - start.y
        let lengthSquared = vx * vx + vy * vy
        guard lengthSquared >= GameConfig.dpadInputSnapEpsilon else {
            return wx * wx + wy * wy
        }
        let rawT = (wx * vx + wy * vy) / lengthSquared
        let t = max(0, min(1, rawT))
        let projection = CGPoint(x: start.x + vx * t, y: start.y + vy * t)
        let dx = point.x - projection.x
        let dy = point.y - projection.y
        return dx * dx + dy * dy
    }

    // MARK: - Skill Visual Helpers
    private func spawnSkillTrail(from start: CGPoint, to end: CGPoint, color: UIColor, parent: SKNode) {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)
        let trail = SKShapeNode(path: path)
        trail.name = "skillTrail"
        trail.strokeColor = color.withAlphaComponent(GameConfig.skillEffectStrokeAlpha)
        trail.lineWidth = GameConfig.skillEffectLineWidth
        trail.fillColor = .clear
        trail.zPosition = GameConfig.skillEffectZPosition
        parent.addChild(trail)
        trail.run(.sequence([
            .fadeOut(withDuration: GameConfig.skillEffectFadeDuration),
            .removeFromParent()
        ]))
    }

    private func spawnSkillRing(at position: CGPoint,
                                radius: CGFloat,
                                color: UIColor,
                                parent: SKNode) {
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.name = "skillRing"
        ring.position = position
        ring.strokeColor = color.withAlphaComponent(GameConfig.skillEffectStrokeAlpha)
        ring.fillColor = color.withAlphaComponent(GameConfig.skillEffectFillAlpha)
        ring.lineWidth = GameConfig.skillEffectRingLineWidth
        ring.zPosition = GameConfig.skillEffectZPosition
        ring.setScale(GameConfig.skillEffectRingStartScale)
        parent.addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: GameConfig.skillEffectRingEndScale,
                       duration: GameConfig.skillEffectFadeDuration),
                .fadeOut(withDuration: GameConfig.skillEffectFadeDuration)
            ]),
            .removeFromParent()
        ]))
    }

    private func spawnSkillSparkle(at position: CGPoint, color: UIColor, parent: SKNode) {
        let sparkle = SKShapeNode(circleOfRadius: GameConfig.skillSparkleRadius)
        sparkle.name = "skillSparkle"
        sparkle.position = position
        sparkle.strokeColor = color.withAlphaComponent(GameConfig.skillEffectStrokeAlpha)
        sparkle.fillColor = .clear
        sparkle.lineWidth = GameConfig.skillSparkleLineWidth
        sparkle.zPosition = GameConfig.skillEffectZPosition
        parent.addChild(sparkle)

        let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
        let distance = GameConfig.skillSparkleTravelDistance
        let move = SKAction.moveBy(
            x: cos(angle) * distance,
            y: sin(angle) * distance,
            duration: GameConfig.skillSparkleDuration
        )
        sparkle.run(.sequence([
            .group([
                move,
                .fadeOut(withDuration: GameConfig.skillSparkleDuration)
            ]),
            .removeFromParent()
        ]), withKey: GameConfig.bookClubRallySparkleActionKey)
    }

    private func applyTaiwanTripBlink(to player: PlayerNode) {
        // 깜빡임 액션: alpha 1.0 ↔ taiwanTripFlashAlpha 반복.
        let half = GameConfig.taiwanTripFlashHalfPeriod
        let fadeOut = SKAction.fadeAlpha(to: GameConfig.taiwanTripFlashAlpha, duration: half)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: half)
        let cycle = SKAction.sequence([fadeOut, fadeIn])
        // V2 무적/깜빡임 길이(1.6초). PlayerSkill.duration(.taiwanTrip)도 같은 상수를 참조 — 종료 정합.
        let totalDuration = GameConfig.taiwanTripInvulnerableDurationV2
        player.run(SKAction.repeatForever(cycle), withKey: GameConfig.taiwanTripBlinkActionKey)
        let restore = SKAction.run { [weak player] in
            player?.removeAction(forKey: GameConfig.taiwanTripBlinkActionKey)
            player?.isInvulnerable = false
            player?.alpha = 1.0
        }
        player.run(.sequence([
            .wait(forDuration: totalDuration),
            restore
        ]), withKey: GameConfig.taiwanTripInvulnerableActionKey)
    }
}
