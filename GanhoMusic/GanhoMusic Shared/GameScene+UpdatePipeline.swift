//
//  GameScene+UpdatePipeline.swift
//  GanhoMusic Shared
//
//  R8 §B③ — GameScene.swift(502줄) 분할: update() 파이프라인 단계 함수(input/player/AI/
//  effects/HUD)·Tension 폴링·점수 마일스톤 배너. update() 본체·프로퍼티는 본체 잔존
//  (override 본체 잔존 원칙 — 주의사항 5). 코드 이동만 — 로직/시그니처 0 변경.
//  접근 완화: private → internal — 단계 함수 6종(update()가 호출)·소비 stored property
//  3종(lastComboValue/lastRemainingTimeSecond/lastSentTensionRate — 본체 선언 유지).
//

import SpriteKit

#if DEBUG
/// R10 — env GANHO_FORCE_SERGEANT=1 (스크린샷 증빙 전용 — 릴리즈 미포함, DemoAutopilot 전례).
/// hard: 데뷔 트리거 시간 30s → 2s 단축 / easy·normal: 이스터에그 강제 발화 (우정 인사 캡처).
/// env 1회 평가 캐시 — update 경로 매 프레임 environment dict 생성 방지.
private enum ForcedSergeantDebut {
    static let isEnabled =
        ProcessInfo.processInfo.environment["GANHO_FORCE_SERGEANT"] == "1"
    /// 단축 트리거 시간 (초). 카운트다운 직후 빠른 발화 — 컷씬·연출 캡처 대기 최소화.
    static let debutTime: Double = 2.0
}
#endif

extension GameScene {

    // MARK: - Pipeline Phases (R1)

    /// input 단계 — 입력 처리 전 게임 상태(콤보 만료·스킬 쿨다운)를 확정하고 D-Pad 입력을 위임.
    /// skillSystem.update가 입력 가드(isDashing)보다 먼저여야 기존 프레임 순서와 동일(행동 불변).
    func updateInputPhase(dt: TimeInterval, currentTime: TimeInterval) {
        // Phase 2-5 — 콤보 윈도우 만료 검사 (Phase 2-12: ScoreSystem에 위임)
        scoreSystem.tickComboExpiry(currentTime: currentTime)

        // Phase 9-5 — SkillSystem 매 프레임 진행 (쿨다운/지속시간 감산).
        skillSystem.update(dt: dt)

        // D-Pad 입력을 PlayerNode로 위임 (DPadNode → PlayerNode 직접 참조 금지 → GameScene 경유)
        // Phase 9-5 — 정간호 돌진 중에는 D-Pad 입력 무시(SKAction.move가 위치 제어). 가드 1줄.
        // Phase 9-7 — 청진기 동결 중에도 D-Pad 입력 무시. AND 가드로 두 조건 결합 — 스킬 가드 회귀 0.
        // 동결 시 currentDirection = .zero로 즉시 set → PlayerNode.update 가드 도달 전에도
        // *마지막 방향 잔존*으로 인한 미세 이동 방지.
        if !skillSystem.isDashing && !player.isFrozen {
            updateMovementInput(dt: dt)   // R10 U4 — 방향 급변 스무딩에 dt 전달 (필수 연동 1줄)
        } else if skillSystem.isDashing {
            resetMovementInput()
        } else if player.isFrozen {
            resetMovementInput()
        }

        #if DEBUG
        // R7 시각 증빙 — env GANHO_DEMO_AUTOPILOT=1 한정 자동 주행 (콤보 게이지/near-miss 캡처).
        // simctl 터치 주입 불가 우회 — GANHO_SKIP_CUTSCENE·FrameStats 전례. 릴리즈 코드 0.
        applyDemoAutopilotIfEnabled()
        #endif
    }

    /// player 단계 — PlayerNode 자체 dt 보간 이동(wall-slide 포함) + 픽셀 걷기 프레임 + 수집 자석.
    func updatePlayerPhase(dt: TimeInterval) {
        // PlayerNode 자체 dt 보간 이동 (도메인이 자기 갱신)
        // 돌진 중에는 currentDirection이 zero로 유지되어 velocity 0 — SKAction.move만 위치 변경.
        player.update(deltaTime: dt)

        // Phase 8-1 — PlayerNode 픽셀 걷기 프레임 갱신 (시각만 — 게임 로직 무관).
        // wall-slide 수동 이동이 적용된 직후의 실제 이동 벡터를 읽어 이번 프레임 시각에 반영한다.
        // Sprint 11 — 방향(facing)은 D-Pad onDirectionChanged 콜백(GameScene+Setup)이 입력 즉시 단독 담당.
        //   tickWalkFrame은 isMoving(velocity 기반)으로 다리 교차 여부만 판단 — 방향과 책임 분리.
        let velocity = player.movementVelocity
        let isMoving = abs(velocity.dx) > 0.1 || abs(velocity.dy) > 0.1
        player.tickWalkFrame(deltaTime: dt, isMoving: isMoving)

        // R2 — 수집 자석 (player 단계 말미): 32px 내 음표를 0.08s 흡인 곡선으로 끌어당김.
        // **판정 불변** — 수집은 여전히 physics contact가 결정 (자석은 위치만 이동, 02 §5).
        updateNoteMagnet(dt: dt)
    }

    /// R2 — 수집 자석. registry.notes 순회(동시 캡 ≤10 — R1 인프라)로 매 프레임 거리 검사.
    /// 스킬 끌어오기(bookClubRallyPull) 진행 중인 음표는 제외 — 두 위치 제어의 경합 차단.
    /// update 내 힙 할당 0 — 배열 스냅샷 없이 직접 순회(위치만 변경, 등록 변형 없음).
    func updateNoteMagnet(dt: TimeInterval) {
        let radius = FeelTuning.noteMagnetRadius
        let radiusSquared = radius * radius
        let pull = CGFloat(min(1, dt / FeelTuning.noteMagnetDuration))
        let playerPosition = player.position
        for note in registry.notes {
            let dx = playerPosition.x - note.position.x
            let dy = playerPosition.y - note.position.y
            guard dx * dx + dy * dy <= radiusSquared else { continue }
            guard note.action(forKey: GameplayTuning.bookClubRallyPullActionKey) == nil else { continue }
            note.position.x += dx * pull
            note.position.y += dy * pull
        }
    }

    /// AI 단계 — 적 NPC 갱신 + hard 박병장 데뷔 폴링(적 등장 = AI 책임).
    func updateAIPhase(dt: TimeInterval) {
        // Sprint 8 Phase G — 박병장 hard 난이도 데뷔. 30s 또는 50점 중 더 빠른 쪽 1회.
        if difficulty == .hard && !sergeantParkDebuted {
            let elapsed = GameplayTuning.gameDuration - remainingTime
            var debutTime = GameplayTuning.sergeantParkDebutTime
            #if DEBUG
            // R10 — env GANHO_FORCE_SERGEANT=1 한정 데뷔 시간 단축 (스크린샷 증빙 전용,
            // GANHO_AUTO_PAUSE 전례 동형). 릴리즈 경로는 위 30s OR 50점 조건 그대로.
            if ForcedSergeantDebut.isEnabled { debutTime = ForcedSergeantDebut.debutTime }
            #endif
            if elapsed >= debutTime
                || scoreSystem.score >= GameplayTuning.sergeantParkDebutScore {
                sergeantParkDebuted = true
                spawnSergeantPark()
            }
        }
        #if DEBUG
        // R10 — 같은 env로 easy/normal 이스터에그 강제 발화 (C-2 인사 연출 증빙 — SPEC "B의
        // env에 통합 가능"). triggerAirforceEasterEgg 내부 가드(airforceTriggered·hard 제외) 그대로.
        if ForcedSergeantDebut.isEnabled, difficulty != .hard, !airforceTriggered,
           GameplayTuning.gameDuration - remainingTime >= ForcedSergeantDebut.debutTime {
            triggerAirforceEasterEgg()
        }
        #endif

        // Sprint 10 Phase D — 수간호사 패트롤 + 텔레그래프 상태 머신.
        //    player.position / 진행률 / charmActive는 provider 캡처(GameScene+Setup에서 1회 주입).
        //    F 발사는 EnemyNode 내부 상태 머신이 전담 (R1: 실체화만 풀 provider 경유).
        enemy.update(deltaTime: dt)

        // Phase 4-1 — 석조무사 SKAction 패트롤의 시각 프레임 갱신.
        if stoneGuard.parent != nil {
            stoneGuard.updatePixelAnimation(deltaTime: dt)
        }

        // Phase 9-7 — 이교수 픽셀 애니메이션 갱신 (hard만). easy/normal에선 professor=nil → optional chain 자연 noop.
        professor?.updatePixelAnimation(deltaTime: dt)
    }

    /// effects 단계 — 점수 배너/5초 긴박감/위험 경고/콤보 오라. 전부 게임 수치 무변경 시각·청각 레이어.
    func updateEffectsPhase() {
        // 점수 마일스톤 안내 배너 — 게임을 멈추지 않는 순수 시각 격려.
        // 점수는 콤보당 +1~+4로 *비연속* 증가하므로 정확값에 안 멈춰도 누락되지 않게 '>=' 교차로 판정.
        updateScoreMilestoneBanners()

        // Phase 6-14 — 5초 긴박감 폴링 (BGM rate + 비네트 + 초당 햅틱).
        updateTensionPolling()

        // 위험 경고는 밸런스 수치를 바꾸지 않는 시각 레이어다. 생성은 setup/발사 시점,
        // 여기서는 거리 기반 alpha/펄스만 갱신해 노드 churn을 막는다. (R1: registry 순회)
        updateDangerWarnings()

        // R2 — comboAura 폴링: 콤보 ≥5 동안 플레이어 발밑 상승 입자, <5 복귀·끊김 시 즉시 회수.
        effectDirector.updateComboAura(combo: scoreSystem.combo, playerPosition: player.position)
    }

    /// HUD 단계 — 점수/시간 확정 이후 표시 + 콤보 끊김 폴링(tickComboExpiry 이후 상대 순서 보존).
    func updateHUDPhase() {
        // HUD 라벨 갱신 (Phase 2-4) — Phase 2-12: ScoreSystem에서 값 조회
        hud.update(score: scoreSystem.score, remainingTime: remainingTime, combo: scoreSystem.combo)

        // R7 §F3 — 콤보 윈도우 잔여 게이지 (combo 0 = nil → 비표시). near-miss 연장(F2)은
        // ScoreSystem 파생값이라 자동 즉시 반영 — 점수/시간과 같은 "확정 이후 표시" 단계.
        hud.updateComboGauge(fraction: scoreSystem.comboWindowRemainingFraction(at: lastUpdateTime))

        // Phase 6-12 — 콤보 끊김 폴링. tickComboExpiry(input 단계)가 같은 프레임에
        // 콤보를 0으로 떨어뜨린 직후를 캡처. F 피격 경로는 별도 분기(configureContactRouter).
        // ScoreSystem 시그니처 미변경(옵션 B 폴링) — 6-10 환호 폴링과 같은 패턴.
        let currentCombo = scoreSystem.combo
        maxComboThisRun = max(maxComboThisRun, currentCombo)
        if lastComboValue >= FeelTuning.comboBreakThreshold, currentCombo == 0 {
            triggerComboBreak(brokenAt: lastComboValue)
        }
        lastComboValue = currentCombo

        // Phase 9-5 — HUDSkillSlot 진행률 시각화. SkillSystem.progress는 4 상태 분기 후 반환.
        hudSkillSlot.update(progress: skillSystem.progress)
    }

    // MARK: - Tension Polling (Phase 6-14 / R1 — BGM setRate 양자화 가드)
    /// 5초 긴박감 폴링. .playing 가드·0도달 early return 이후에만 호출됨 — remainingTime > 0 보장.
    /// 카운트다운(.countdown) 중에는 update 상단 가드에서 이미 차단 → BGM 미재생 상태와 시간 비교차 0.
    func updateTensionPolling() {
        guard remainingTime <= FeelTuning.tensionWindow else { return }
        // 첫 진입 1회 setup — HUD 깜빡임 시작.
        if !tensionStarted {
            tensionStarted = true
            hud.startTensionBlink()
            // Sprint 10 Phase J — 픽셀 비네트 attach (cameraNode 자식). HUD 깜빡임과 같은 박자 동기.
            let vignette = TensionVignetteNode(sceneSize: size)
            cameraNode.addChild(vignette)
            tensionVignette = vignette
        }
        // rate 보간: 1.0 + 0.15 × (5 - remainingTime) / 5. TimeInterval(Double) → Float 캐스팅.
        let progress = Float((FeelTuning.tensionWindow - remainingTime) / FeelTuning.tensionWindow)
        let clamped = max(Float(0), min(Float(1), progress))
        let rate = FeelTuning.tensionRateBase + (FeelTuning.tensionRateMax - FeelTuning.tensionRateBase) * clamped
        // R1 — 양자화 가드: 연속 보간값을 스텝 단위로 반올림 후 직전 전송값과 다를 때만 setRate.
        // 입력(rate)이 단조 증가이므로 양자화 결과도 단조 비감소 — 1.0 시작 → 종료 근방 1.15 도달 보존.
        let step = FeelTuning.tensionRateQuantizeStep
        let quantizedRate = (rate / step).rounded() * step
        if quantizedRate != lastSentTensionRate {
            lastSentTensionRate = quantizedRate
            bgm.setRate(quantizedRate)
        }
        // 매초 정수 변화 시 light 햅틱 (5→4, 4→3, 3→2, 2→1 = 4회).
        // HUD timeLabel이 보여주는 ceil 식과 동일 — *눈에 보이는 숫자가 바뀐 순간* 발화.
        // 0초 도달은 update 상단 early return에서 처리되어 여기로 안 옴 (4회 발화 정확 보장).
        let now = max(0, Int(ceil(remainingTime)))
        if now != lastRemainingTimeSecond {
            lastRemainingTimeSecond = now
            if now >= 1 && now <= 4 {
                haptics.light()
            }
        }
    }

    // MARK: - Milestone Banner
    /// 점수 마일스톤 안내 배너 폴링. `update(_:)`의 `.playing` 가드·0도달 early return 이후에만 호출됨.
    /// 점수는 콤보당 +1~+4로 비연속 증가 → '>=' 교차로 판정해 정확값에 안 멈춰도 누락 0.
    /// 각 마일스톤은 멱등 Bool로 한 판 1회만 spawn(가드 통과 시에만 addChild → 매 프레임 생성 0).
    /// A/B는 독립 `if`라 같은 프레임 동시 충족 시에도 둘 다 안전하게 발화(겹쳐도 자가 소멸).
    func updateScoreMilestoneBanners() {
        // R6 — 음표 러시 판은 실효 목표(×1.3) 경유 — 배너 문구와 verdict 기준 일치 (단일 공급점).
        let target = effectiveTargetScore
        let score = scoreSystem.score
        // A(절반): ceil(target/2). target ≥ 40이라 항상 절반 < (target-10) → A가 먼저.
        let halfThreshold = Int((Double(target) / 2.0).rounded(.up))
        if !halfScoreMilestoneShown, score >= halfThreshold {
            halfScoreMilestoneShown = true
            // 발화 시점 실제 남은 개수. 점수는 비연속 증가(+1~+4)라 발화 시 score>=halfThreshold →
            // remaining은 절반 근처 양수. max(0,...)으로 음수 방어(이론상 미발생이나 안전).
            let remaining = max(0, target - score)
            let text = "\(remaining)" + FeelTuning.milestoneHalfSuffix
            MilestoneBannerNode.spawn(text: text, parent: cameraNode)
            effectDirector.milestoneConfetti()
        }
        // B(10점 남음): target - milestoneNearTargetRemaining.
        if !nearTargetMilestoneShown, score >= target - FeelTuning.milestoneNearTargetRemaining {
            nearTargetMilestoneShown = true
            MilestoneBannerNode.spawn(text: FeelTuning.milestoneNearText, parent: cameraNode)
            effectDirector.milestoneConfetti()
        }
    }
}
