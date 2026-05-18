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
            // charmStudent만 만료 시 활성 F의 enchanted를 일괄 해제.
            if next == 0 {
                onDurationExpired()
            }
        }

        // 현재 D-Pad 방향이 .zero가 아니면 마지막 방향으로 저장 — 돌진 발동 시 사용.
        // GameScene.update에서 매 프레임 호출하므로 self-contained.
        if let dpadDir = scene?.dpad.currentDirection,
           dpadDir != .zero {
            lastDirection = dpadDir
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
            // 매혹 만료 — 활성 F의 enchanted 일괄 해제(아직 살아있는 F만).
            guard let world = scene?.worldNode else { return }
            world.enumerateChildNodes(withName: "projectile") { node, _ in
                if let projectile = node as? ProjectileNode {
                    projectile.clearEnchanted()
                }
            }
        }
    }

    // MARK: - 1. Dash Climb (정간호)
    /// 3 tile 거리 돌진 + 무적 + 경로상 breakableWall 1칸 파괴.
    /// 방향: DPad.currentDirection → lastDirection → 기본 우측 fallback.
    private func performDashClimb() {
        guard let scene = scene else { return }
        let player = scene.player
        let direction = currentDashDirection()

        // 시작/끝 좌표 계산.
        let start = player.position
        let end = CGPoint(
            x: start.x + direction.dx * GameConfig.dashClimbDistance,
            y: start.y + direction.dy * GameConfig.dashClimbDistance
        )

        // 경로 위 breakableWall 1칸 식별 및 파괴.
        // enumerate는 발동 시 1회만 — 매 프레임 호출 아님(성능 핵심).
        breakFirstBreakableWall(from: start, to: end)

        // 무적 + 이동.
        player.isInvulnerable = true
        let move = SKAction.move(to: end, duration: GameConfig.dashClimbDuration)
        let endAction = SKAction.run { [weak player] in
            player?.isInvulnerable = false
        }
        player.run(.sequence([move, endAction]))
    }

    /// DPad → lastDirection → 기본 우측 순서로 방향 벡터 결정.
    private func currentDashDirection() -> CGVector {
        guard let scene = scene else {
            return CGVector(dx: 1, dy: 0)
        }
        let dpadDir = scene.dpad.currentDirection
        if dpadDir != .zero {
            return dpadDir
        }
        if lastDirection != .zero {
            return lastDirection
        }
        return CGVector(dx: 1, dy: 0)
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
    /// 반경 120pt 안 노트를 player 위치로 끌어오기.
    /// 도착 시점 자연 contact → onNoteCollected 정상 발화 → 점수/콤보 자동.
    /// F는 끌어오지 않음(이름 분기 "note"만).
    private func performBookClubRally() {
        guard let scene = scene else { return }
        let world = scene.worldNode
        let center = scene.player.position
        let radius = GameConfig.bookClubRallyRadius
        let radiusSquared = radius * radius

        // enumerate는 발동 시 1회만 — 매 프레임 호출 아님.
        world.enumerateChildNodes(withName: "note") { node, _ in
            let dx = node.position.x - center.x
            let dy = node.position.y - center.y
            // 거리^2 비교 — sqrt 회피(성능).
            guard dx * dx + dy * dy < radiusSquared else { return }
            let move = SKAction.move(to: center, duration: GameConfig.bookClubRallyMoveDuration)
            move.timingMode = .easeIn
            node.run(move)
        }
    }

    // MARK: - 3. Charm Student (임간호)
    /// 모든 활성 F를 enchanted로 전환. 새로 발사되는 F는 SpawnSystem 가드가 처리.
    /// 1.5초 후 update의 onDurationExpired가 일괄 해제.
    private func performCharmStudent() {
        guard let world = scene?.worldNode else { return }
        world.enumerateChildNodes(withName: "projectile") { node, _ in
            if let projectile = node as? ProjectileNode {
                projectile.applyEnchanted()
            }
        }
    }

    // MARK: - 4. Taiwan Trip (이간호)
    /// 4방향 후보 셔플 → 맵 경계 + 벽 미겹침 첫 후보로 텔레포트.
    /// 0.5초 무적 + 깜빡임 액션.
    private func performTaiwanTrip() {
        guard let scene = scene else { return }
        let player = scene.player
        let candidates: [CGVector] = [
            CGVector(dx:  1, dy:  0),
            CGVector(dx: -1, dy:  0),
            CGVector(dx:  0, dy:  1),
            CGVector(dx:  0, dy: -1)
        ].shuffled()

        let distance = GameConfig.taiwanTripJumpDistance
        let start = player.position
        var targetPosition = start  // fallback — 후보 모두 실패 시 *제자리* 무적만.

        for direction in candidates {
            let candidate = CGPoint(
                x: start.x + direction.dx * distance,
                y: start.y + direction.dy * distance
            )
            if isValidTeleportTarget(candidate) {
                targetPosition = candidate
                break
            }
        }

        // 즉시 위치 이동.
        player.position = targetPosition

        // 무적 + 깜빡임. 동시에 set/clear.
        player.isInvulnerable = true

        // 깜빡임 액션: alpha 1.0 ↔ taiwanTripFlashAlpha 반복.
        let half = GameConfig.taiwanTripFlashHalfPeriod
        let fadeOut = SKAction.fadeAlpha(to: GameConfig.taiwanTripFlashAlpha, duration: half)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: half)
        let cycle = SKAction.sequence([fadeOut, fadeIn])
        // 0.5초 / 한 사이클 0.2초 → 2.5사이클 반복.
        let totalDuration = GameConfig.taiwanTripInvulnerableDuration
        let cycleCount = max(1, Int(totalDuration / (half * 2)))
        let blink = SKAction.repeat(cycle, count: cycleCount)
        let restore = SKAction.run { [weak player] in
            player?.isInvulnerable = false
            player?.alpha = 1.0
        }
        player.run(.sequence([blink, restore]))
    }

    /// 텔레포트 후보가 맵 안 + 벽 미겹침인지 검사.
    /// 맵 경계: 외곽 벽 안쪽 1tile 여유. 벽 검사: physicsWorld.body(at:) 사용.
    private func isValidTeleportTarget(_ point: CGPoint) -> Bool {
        let margin = GameConfig.tileSize
        guard point.x >= margin, point.x <= GameConfig.mapWidth - margin else { return false }
        guard point.y >= margin, point.y <= GameConfig.mapHeight - margin else { return false }
        // 벽 노드와 겹치는지 — physicsWorld 조회.
        guard let scene = scene else { return true }
        if let body = scene.physicsWorld.body(at: point),
           body.categoryBitMask == PhysicsCategory.wall {
            return false
        }
        return true
    }
}
