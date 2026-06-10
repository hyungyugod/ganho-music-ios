//
//  EffectDirector.swift
//  GanhoMusic Shared
//
//  R2 · SKEmitterNode 파티클 6종 — 코드 생성(.sks 0)·사전 생성 풀링·동시 8개 캡·우선순위 스킵
//  (02_GAME_FEEL §4). 입자 텍스처는 TextureAtlasStore 단색 텍셀(3×3) + particleColor 틴트.
//  worldNode 소속 이미터는 히트스톱 시 자연 일시정지(의도). milestoneConfetti만 cameraNode 소속.
//

import SpriteKit

/// 인게임 파티클 단일 제어기. GameScene 인스턴스 소유 (static 금지 — R1 패턴 동일).
/// 전 이미터는 configure 시점 사전 생성 — 트리거는 attach/detach만 (update 내 신규 할당 0).
final class EffectDirector {

    // MARK: - Priority (높을수록 보존 — 캡 초과 시 낮은 것부터 스킵/퇴거)
    private enum Priority: Int {
        case comboAura = 0, collectBurst = 1, milestoneConfetti = 2,
             toiletSplash = 3, skillSignature = 4, deathBurst = 5
    }

    // MARK: - State
    private weak var worldNode: SKNode?
    private weak var cameraNode: SKNode?
    private var viewportProvider: () -> CGSize = { .zero }

    private var collectBurstPool: [SKEmitterNode] = []
    private var collectBurstNextIndex = 0
    private var toiletSplashEmitter: SKEmitterNode?
    private var deathBurstEmitter: SKEmitterNode?
    private var confettiEmitter: SKEmitterNode?
    private var comboAuraEmitter: SKEmitterNode?
    /// 활성 스킬 전용 이미터 — configure(skill:)이 해당 스킬 것만 생성 (워프는 출발·도착 2개).
    private var skillEmitters: [SKEmitterNode] = []
    private var skillSignatureColor: UIColor = .white
    private var comboAuraCurrentColor: UIColor?

    /// 활성 이미터 추적 — 캡/우선순위 판단. detach가 즉시 제거(스테일은 attach 시점 청소).
    private var activeEntries: [(emitter: SKEmitterNode, priority: Int)] = []

    // MARK: - Configure
    func configure(worldNode: SKNode, cameraNode: SKNode,
                   viewportProvider: @escaping () -> CGSize,
                   skill: PlayerSkill, signatureColor: UIColor) {
        self.worldNode = worldNode
        self.cameraNode = cameraNode
        self.viewportProvider = viewportProvider
        self.skillSignatureColor = signatureColor
        buildPools(skill: skill)
    }

    // MARK: - Triggers (02 §4 표)
    /// 음표 수집 — 8~12개 방사, gold, 0.35s.
    func collectBurst(at position: CGPoint) {
        guard !collectBurstPool.isEmpty, let world = worldNode else { return }
        let emitter = collectBurstPool[collectBurstNextIndex]
        collectBurstNextIndex = (collectBurstNextIndex + 1) % collectBurstPool.count
        emitter.position = position
        attachBurst(emitter, to: world, priority: .collectBurst, lifetime: FeelTuning.collectBurstLifetime)
    }

    /// 변기 수집 — 10개, mint, 0.3s 물보라.
    func toiletSplash(at position: CGPoint) {
        guard let emitter = toiletSplashEmitter, let world = worldNode else { return }
        emitter.position = position
        attachBurst(emitter, to: world, priority: .toiletSplash, lifetime: FeelTuning.toiletSplashLifetime)
    }

    /// 게임오버 — 24개, coral→white, 중력 -60, 0.6s.
    func deathBurst(at position: CGPoint) {
        guard let emitter = deathBurstEmitter, let world = worldNode else { return }
        emitter.position = position
        attachBurst(emitter, to: world, priority: .deathBurst, lifetime: FeelTuning.deathBurstLifetime)
    }

    /// 점수 마일스톤 배너 — 화면 상단 16개 낙하, 3색, 1.0s. cameraNode 소속(화면 고정).
    func milestoneConfetti() {
        guard let emitter = confettiEmitter, let camera = cameraNode else { return }
        let viewport = viewportProvider()
        emitter.position = CGPoint(x: 0, y: viewport.height / 2 - FeelTuning.milestoneConfettiTopInset)
        emitter.particlePositionRange = CGVector(
            dx: viewport.width * FeelTuning.milestoneConfettiWidthRatio, dy: 0)
        attachBurst(emitter, to: camera, priority: .milestoneConfetti,
                    lifetime: FeelTuning.milestoneConfettiLifetime)
    }

    /// 스킬 발동 시그니처 — 형태는 스킬별 (돌진=트레일/워프=쌍둥이 burst/소집=수렴 근사/모범생=상승 하트).
    func skillSignature(_ skill: PlayerSkill, from start: CGPoint, to end: CGPoint) {
        guard let world = worldNode else { return }
        switch skill {
        case .none:
            return
        case .dashClimb:
            guard let trail = skillEmitters.first else { return }
            trail.position = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
            trail.particlePositionRange = CGVector(dx: abs(end.x - start.x), dy: abs(end.y - start.y))
            trail.emissionAngle = atan2(start.y - end.y, start.x - end.x)   // 후방 트레일
            attachBurst(trail, to: world, priority: .skillSignature, lifetime: FeelTuning.skillTrailLifetime)
        case .taiwanTrip:
            for (index, emitter) in skillEmitters.enumerated() {
                emitter.position = index == 0 ? start : end
                attachBurst(emitter, to: world, priority: .skillSignature,
                            lifetime: FeelTuning.skillWarpBurstLifetime)
            }
        case .bookClubRally, .charmStudent:
            guard let emitter = skillEmitters.first else { return }
            emitter.position = start
            let lifetime = skill == .bookClubRally
                ? FeelTuning.skillRallyLifetime : FeelTuning.skillHeartLifetime
            attachBurst(emitter, to: world, priority: .skillSignature, lifetime: lifetime)
        }
    }

    /// 콤보 ≥5 동안 플레이어 발밑 상승 입자 — effects 단계가 매 프레임 폴링.
    /// 콤보 <5 복귀·끊김 시 즉시 detach (좀비 금지 — alpha 0 잔존 불가).
    func updateComboAura(combo: Int, playerPosition: CGPoint) {
        guard let emitter = comboAuraEmitter, let world = worldNode else { return }
        guard combo >= FeelTuning.comboAuraActiveThreshold else {
            if emitter.parent != nil { detach(emitter) }
            return
        }
        let color = comboAuraColor(for: combo)
        if color !== comboAuraCurrentColor {
            comboAuraCurrentColor = color
            emitter.particleColor = color
        }
        if emitter.parent == nil {
            // 캡 초과로 거절되면 다음 프레임 자연 재시도 (지속형 — lifetime 회수 없음).
            guard attach(emitter, to: world, priority: .comboAura) else { return }
        }
        emitter.position = CGPoint(x: playerPosition.x,
                                   y: playerPosition.y - FeelTuning.comboAuraFootOffsetY)
    }

    // MARK: - Attach / Detach (풀링 + 캡 + 우선순위)
    /// burst형 attach — resetSimulation 후 부착, lifetime + 방출창 경과 시 자가 detach.
    private func attachBurst(_ emitter: SKEmitterNode, to parent: SKNode,
                             priority: Priority, lifetime: TimeInterval) {
        if emitter.parent != nil { detach(emitter) }   // 재트리거 — 이전 입자 정리 후 재시작
        guard attach(emitter, to: parent, priority: priority) else { return }
        let wait = SKAction.wait(forDuration: lifetime + FeelTuning.particleBurstEmitWindow)
        let recycle = SKAction.run { [weak self, weak emitter] in
            guard let emitter = emitter else { return }
            self?.detach(emitter)
        }
        emitter.run(.sequence([wait, recycle]))
    }

    /// 공통 attach — 동시 8개 캡. 초과 시 새 효과가 최저 우선순위보다 높으면 그것을 퇴거, 아니면 스킵.
    private func attach(_ emitter: SKEmitterNode, to parent: SKNode, priority: Priority) -> Bool {
        activeEntries.removeAll { $0.emitter.parent == nil }   // 스테일 청소 (안전망)
        if activeEntries.count >= FeelTuning.maxConcurrentEmitters {
            guard let lowestIndex = activeEntries.indices.min(by: {
                activeEntries[$0].priority < activeEntries[$1].priority
            }), activeEntries[lowestIndex].priority < priority.rawValue else {
                return false   // 우선순위 낮은 신규 효과 스킵
            }
            detach(activeEntries[lowestIndex].emitter)
        }
        emitter.removeAllActions()
        emitter.resetSimulation()
        parent.addChild(emitter)
        activeEntries.append((emitter, priority.rawValue))
        return true
    }

    private func detach(_ emitter: SKEmitterNode) {
        emitter.removeAllActions()
        emitter.removeFromParent()
        activeEntries.removeAll { $0.emitter === emitter }
    }

    private func comboAuraColor(for combo: Int) -> UIColor {
        if combo >= FeelTuning.comboAuraTierViolet { return Palette.comboAuraViolet }
        if combo >= FeelTuning.comboAuraTierCoral { return .ganhoIngameDanger }   // coral #D8315B
        return .ganhoIngameReward                                                 // gold #FFD23F
    }

    // MARK: - Emitter Factory (configure 1회 — 코드 생성, .sks 금지)
    private func buildPools(skill: PlayerSkill) {
        collectBurstPool = (0..<FeelTuning.collectBurstPoolCount).map { _ in
            makeBurstEmitter(count: FeelTuning.collectBurstCount, lifetime: FeelTuning.collectBurstLifetime,
                             speed: FeelTuning.collectBurstSpeed,
                             speedRange: FeelTuning.collectBurstSpeedRange, color: .ganhoIngameReward)
        }
        let splash = makeBurstEmitter(count: FeelTuning.toiletSplashCount,
                                      lifetime: FeelTuning.toiletSplashLifetime,
                                      speed: FeelTuning.toiletSplashSpeed,
                                      speedRange: FeelTuning.toiletSplashSpeedRange,
                                      color: .ganhoIngameRewardMint)
        splash.emissionAngle = .pi / 2
        splash.emissionAngleRange = FeelTuning.toiletSplashSpreadRadians
        splash.yAcceleration = FeelTuning.toiletSplashGravityY
        toiletSplashEmitter = splash

        let death = makeBurstEmitter(count: FeelTuning.deathBurstCount,
                                     lifetime: FeelTuning.deathBurstLifetime,
                                     speed: FeelTuning.deathBurstSpeed,
                                     speedRange: FeelTuning.deathBurstSpeedRange, color: .ganhoIngameDanger)
        death.yAcceleration = FeelTuning.deathBurstGravityY
        // coral+white 혼합 — 수명에 걸쳐 coral→white 보간 (입자 나이별로 두 색이 공존).
        death.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [UIColor.ganhoIngameDanger, UIColor.ganhoPixelHudWhite], times: [0.0, 1.0])
        deathBurstEmitter = death

        let confetti = makeBurstEmitter(count: FeelTuning.milestoneConfettiCount,
                                        lifetime: FeelTuning.milestoneConfettiLifetime,
                                        speed: FeelTuning.milestoneConfettiFallSpeed,
                                        speedRange: FeelTuning.milestoneConfettiSpeedRange,
                                        color: .ganhoIngameReward)
        confetti.emissionAngle = -.pi / 2   // 하강
        confetti.emissionAngleRange = 0
        confetti.particleRotationSpeed = FeelTuning.milestoneConfettiSpinSpeed
        confetti.zPosition = ZOrder.milestoneConfettiZPosition
        confetti.targetNode = nil   // cameraNode 소속 — 화면 고정 (월드 잔류 변환 불필요)
        // 3색 혼합 — gold/coral/mint 키프레임 (입자 나이별 색 분산).
        confetti.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [UIColor.ganhoIngameReward, UIColor.ganhoIngameDanger,
                             UIColor.ganhoIngameRewardMint], times: [0.0, 0.5, 1.0])
        confettiEmitter = confetti

        let aura = makeBaseEmitter(color: .ganhoIngameReward)
        aura.particleBirthRate = FeelTuning.comboAuraBirthRate
        aura.numParticlesToEmit = 0   // 지속형
        aura.particleLifetime = CGFloat(FeelTuning.comboAuraLifetime)
        aura.particleSpeed = FeelTuning.comboAuraRiseSpeed
        aura.emissionAngle = .pi / 2
        aura.emissionAngleRange = FeelTuning.skillHeartSpreadRadians
        aura.particleAlphaSpeed = -1 / CGFloat(FeelTuning.comboAuraLifetime)
        comboAuraEmitter = aura

        skillEmitters = makeSkillEmitters(skill: skill)
    }

    private func makeSkillEmitters(skill: PlayerSkill) -> [SKEmitterNode] {
        switch skill {
        case .none:
            return []
        case .dashClimb:
            let trail = makeBurstEmitter(count: FeelTuning.skillTrailCount,
                                         lifetime: FeelTuning.skillTrailLifetime,
                                         speed: FeelTuning.skillTrailSpeed,
                                         speedRange: 0, color: skillSignatureColor)
            trail.emissionAngleRange = FeelTuning.skillHeartSpreadRadians
            return [trail]
        case .taiwanTrip:
            return (0..<2).map { _ in
                makeBurstEmitter(count: FeelTuning.skillWarpBurstCount,
                                 lifetime: FeelTuning.skillWarpBurstLifetime,
                                 speed: FeelTuning.skillWarpBurstSpeed,
                                 speedRange: FeelTuning.skillWarpBurstSpeedRange,
                                 color: skillSignatureColor)
            }
        case .bookClubRally:
            // "수렴 방향" 근사 — 반경 분산 스폰 + 수축 스케일 (입자가 모이는 인상, 픽셀 톤 유지).
            let rally = makeBurstEmitter(count: FeelTuning.skillRallyCount,
                                         lifetime: FeelTuning.skillRallyLifetime,
                                         speed: FeelTuning.skillRallyDriftSpeed,
                                         speedRange: 0, color: skillSignatureColor)
            let radius = GameplayTuning.bookClubRallyRadius * FeelTuning.skillRallySpawnRadiusRatio
            rally.particlePositionRange = CGVector(dx: radius, dy: radius)
            rally.particleScaleSpeed = FeelTuning.skillRallyScaleSpeed
            return [rally]
        case .charmStudent:
            let hearts = makeBurstEmitter(count: FeelTuning.skillHeartCount,
                                          lifetime: FeelTuning.skillHeartLifetime,
                                          speed: FeelTuning.skillHeartRiseSpeed,
                                          speedRange: 0, color: skillSignatureColor)
            hearts.emissionAngle = .pi / 2
            hearts.emissionAngleRange = FeelTuning.skillHeartSpreadRadians
            hearts.yAcceleration = FeelTuning.skillHeartRiseAcceleration
            hearts.particleScale = FeelTuning.skillHeartScale
            return [hearts]
        }
    }

    /// burst형 공통 이미터 — count개를 방출창 안에 전량 방출 후 자연 종료.
    private func makeBurstEmitter(count: Int, lifetime: TimeInterval, speed: CGFloat,
                                  speedRange: CGFloat, color: UIColor) -> SKEmitterNode {
        let emitter = makeBaseEmitter(color: color)
        emitter.numParticlesToEmit = count
        emitter.particleBirthRate = CGFloat(count) / CGFloat(FeelTuning.particleBurstEmitWindow)
        emitter.particleLifetime = CGFloat(lifetime)
        emitter.particleSpeed = speed
        emitter.particleSpeedRange = speedRange
        emitter.particleAlphaSpeed = -FeelTuning.particleAlphaDecayMultiplier / CGFloat(lifetime)
        return emitter
    }

    private func makeBaseEmitter(color: UIColor) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = TextureAtlasStore.particleTexelTexture()
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.emissionAngleRange = .pi * 2
        emitter.zPosition = ZOrder.ingameParticleZPosition
        emitter.targetNode = worldNode   // 이미터 이동(콤보 오라 등)에도 입자는 월드에 잔류
        return emitter
    }
}
