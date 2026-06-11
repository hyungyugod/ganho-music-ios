//
//  ResultScene+Reveal.swift
//  GanhoMusic Shared
//
//  R5 — "보상의 무대" 연출 시퀀스 (03_UI §7 표 1:1): 0.0s 도장 → 0.4s 카운트업 → 1.2s 별 팝
//  → 1.7s XP 바 → 2.1s 기록 칩 → ~2.4s 버튼. 각 단계는 발화 시점 addChild(대기 좀비 0) + 멱등.
//

import SpriteKit

extension ResultScene {

    /// 시퀀스 액션 키 — withKey 멱등 (스킵 시 제거).
    private static let revealSequenceKey = "r5RevealSequence"
    private static let countUpActionKey = "r5ScoreCountUp"
    private static let shakeActionKey = "r5StampShake"
    private static let starPopActionKey = "r5StarPop"
    private static let recordBlinkActionKey = "r5RecordBlink"

    // MARK: - Sequence (씬 소유 SKAction — Timer/asyncAfter 금지, run 클로저 전부 [weak self])
    func startRevealSequence() {
        revealVerdict(animated: true)   // 0.0s — 즉시
        let steps: [(at: TimeInterval, fire: (ResultScene) -> Void)] = [
            (FeelTuning.R5.revealCountUpAt, { $0.revealScore(animated: true) }),
            (FeelTuning.R5.revealStarsAt, { $0.revealStars(animated: true) }),
            (FeelTuning.R5.revealXPAt, { $0.revealXP(animated: true) }),
            (FeelTuning.R5.revealRecordChipAt, { $0.revealRecordChip(animated: true) }),
            (FeelTuning.R5.revealButtonsAt, { $0.revealButtons(animated: true) })
        ]
        var actions: [SKAction] = []
        var previous: TimeInterval = 0
        for step in steps {
            actions.append(SKAction.wait(forDuration: step.at - previous))
            actions.append(SKAction.run { [weak self] in
                guard let self = self else { return }
                step.fire(self)
            })
            previous = step.at
        }
        run(SKAction.sequence(actions), withKey: Self.revealSequenceKey)
    }

    /// 탭 1회 스킵 — 전 단계 즉시 최종 상태 (멱등: 각 reveal이 부착·액션 정리를 자체 가드).
    func finishRevealImmediately() {
        guard !revealCompleted else { return }
        removeAction(forKey: Self.revealSequenceKey)
        revealVerdict(animated: false)
        revealScore(animated: false)
        revealStars(animated: false)
        revealXP(animated: false)
        revealRecordChip(animated: false)
        revealButtons(animated: false)
    }

    // MARK: - Step 0.0s — verdict 도장 (56pt, scale 1.6→1.0 easeOutBack + 셰이크 + 도장 SFX)
    private func revealVerdict(animated: Bool) {
        if verdictLabel.parent == nil {
            contentNode.addChild(verdictLabel)
            if animated {
                synth.play(.resultStamp)
                // 도장 순간 1회 heavy — 도달의 무게감 (성공/신기록 시, v2 신기록 heavy 의미 계승).
                if isSuccess || isNewBest {
                    haptics.heavy()
                }
                verdictLabel.setScale(FeelTuning.R5.stampStartScale)
                verdictLabel.run(Tween.curved(
                    SKAction.scale(to: 1.0, duration: FeelTuning.R5.stampDuration),
                    .easeOutBack
                ))
                runStampShake()
                return
            }
        }
        verdictLabel.removeAllActions()
        verdictLabel.setScale(1.0)
        contentNode.removeAction(forKey: Self.shakeActionKey)
    }

    private func runStampShake() {   // 컨테이너 소프트 셰이크 — 감쇠 4스텝 합 0, 원점 복귀
        let amp = FeelTuning.R5.stampShakeAmplitude
        let stepDuration = FeelTuning.R5.stampShakeDuration / 4
        let offsets: [CGFloat] = [-amp, amp * 2, -amp * 1.5, amp * 0.5]
        let shake = SKAction.sequence(offsets.map {
            SKAction.moveBy(x: $0, y: 0, duration: stepDuration)
        })
        contentNode.run(shake, withKey: Self.shakeActionKey)
    }

    // MARK: - Step 0.4s — 점수 카운트업 (0.8s, elapsed 기반 매 프레임 갱신 + 틱 SFX 단계 발화)
    private func revealScore(animated: Bool) {
        if scoreLabel.parent == nil {
            contentNode.addChild(scoreLabel)
            revealMetaChips(animated: animated)
            if animated {
                lastScoreTickStep = -1
                let duration = FeelTuning.R5.countUpDuration
                let tickSteps = FeelTuning.R5.sfxScoreTickStepCount
                let target = finalScore
                let countUp = SKAction.customAction(withDuration: duration) {
                    [weak self] _, elapsed in
                    guard let self = self else { return }
                    let progress = min(max(Double(elapsed) / duration, 0), 1)
                    self.scoreLabel.text = "\(Int(progress * Double(target)))"
                    // 틱 — 진행률을 단계로 양자화해 경계 통과 시에만 발화 (매 프레임 발화 금지).
                    let step = min(Int(progress * Double(tickSteps)), tickSteps - 1)
                    if step > self.lastScoreTickStep {
                        self.lastScoreTickStep = step
                        self.synth.play(.scoreTick(step: step))
                    }
                }
                let settle = SKAction.run { [weak self] in
                    guard let self = self else { return }
                    self.scoreLabel.text = "\(self.finalScore)"
                }
                scoreLabel.run(SKAction.sequence([countUp, settle]),
                               withKey: Self.countUpActionKey)
                return
            }
        }
        scoreLabel.removeAction(forKey: Self.countUpActionKey)
        scoreLabel.text = "\(finalScore)"
    }

    private func revealMetaChips(animated: Bool) {   // 콤보·수집 칩 — 점수와 함께 fade-in 등장
        guard let combo = comboChip, let notes = notesChip, combo.parent == nil else { return }
        for chip in [combo, notes] {
            contentNode.addChild(chip)
            if animated {
                chip.alpha = 0
                chip.run(SKAction.fadeIn(withDuration: FeelTuning.Motion.appear))
            }
        }
    }

    // MARK: - Step 1.2s — 별 3개 순차 팝 (0.15s 간격, easeOutBack, 별당 starReveal SFX)
    private func revealStars(animated: Bool) {
        if starContainer.parent == nil {
            contentNode.addChild(starContainer)
            if animated {
                for (index, star) in starContainer.children.enumerated() {
                    let earned = index < earnedStars
                    star.setScale(0)
                    let pop = Tween.curved(
                        SKAction.scale(to: 1.0, duration: FeelTuning.R5.starPopDuration),
                        .easeOutBack
                    )
                    let voice = SKAction.run { [weak self] in
                        guard let self = self, earned else { return }
                        self.synth.play(.starReveal(index: index))   // R2 기존 보이스 배선
                        self.haptics.starPop()
                    }
                    star.run(SKAction.sequence([
                        SKAction.wait(forDuration: FeelTuning.R5.starInterval * TimeInterval(index)),
                        SKAction.group([pop, voice])
                    ]), withKey: Self.starPopActionKey)
                }
                return
            }
        }
        starContainer.children.forEach {
            $0.removeAction(forKey: Self.starPopActionKey)
            $0.setScale(1.0)
        }
    }

    // MARK: - Step 1.7s — XP 바 증가 (0.5s — FeelTuning.v3ProgressFillDuration) + 레벨업 배지
    private func revealXP(animated: Bool) {
        let xp = xpSnapshot()
        if xpBar.parent == nil {
            contentNode.addChild(xpBar)
            contentNode.addChild(levelLabel)
            xpBar.setProgress(xp.progressStart, animated: false)
            xpBar.setProgress(xp.progressEnd, animated: animated)
            if xp.didLevelUp {
                revealLevelUpChip(level: xp.levelAfter, animated: animated)
            }
            if animated { return }
        }
        xpBar.setProgress(xp.progressEnd, animated: false)
        levelUpChip?.removeAllActions()
        levelUpChip?.alpha = 1
    }

    /// 레벨업 칭호 배지 슬라이드인 — 다중 레벨업도 최종 레벨 1회 표시 (guard nil).
    private func revealLevelUpChip(level: Int, animated: Bool) {
        guard levelUpChip == nil else { return }
        let chip = PixelChipNode(text: MetaProgression.title(forLevel: level),
                                 style: .accent(Palette.gold))
        chip.zPosition = ZOrder.Layer.hud
        levelUpChip = chip
        contentNode.addChild(chip)
        let target = CGPoint(x: UILayout.R5.resultLevelUpChipOffsetX,
                             y: UILayout.R5.resultLevelLabelOffsetY)
        chip.position = target
        guard animated else { return }
        chip.alpha = 0   // 등장 애니 시작값 — 즉시 fade-in (좀비 아님)
        chip.position.x = target.x + FeelTuning.R5.levelUpChipSlideDistance
        let duration = FeelTuning.R5.levelUpChipSlideDuration
        chip.run(SKAction.group([
            Tween.curved(SKAction.moveTo(x: target.x, duration: duration), .easeOutCubic),
            SKAction.fadeIn(withDuration: duration)
        ]))
    }

    // MARK: - Step 2.1s — 기록 칩 (신기록 NEW RECORD 블링크 / 실패 "{gap}점 부족")
    private func revealRecordChip(animated: Bool) {
        guard recordChip == nil else {
            recordChip?.setScale(1.0)
            return
        }
        let chip: PixelChipNode
        if isNewBest {
            chip = PixelChipNode(text: UILayout.R5.resultNewRecordChipText,
                                 style: .accent(Palette.gold))
        } else if !isSuccess {
            // R6 — 부족 칩도 실효 목표 기준 (verdict와 같은 단일 기준 — 음표 러시 판 정합).
            let gap = max(0, effectiveTarget - finalScore)
            chip = PixelChipNode(text: "\(gap)\(UILayout.R5.resultGapChipSuffix)",
                                 style: .accent(Palette.coral))
        } else {
            return   // 성공 + 기록 미갱신 — 칩 없음 (§7 표)
        }
        chip.zPosition = ZOrder.Layer.hud
        recordChip = chip
        contentNode.addChild(chip)
        chip.position = CGPoint(x: UILayout.R5.resultRecordChipOffsetX,
                                y: UILayout.R5.resultScoreOffsetY)
        if animated {
            chip.setScale(0)
            chip.run(Tween.curved(
                SKAction.scale(to: 1.0, duration: FeelTuning.Motion.cardSelect), .easeOutBack
            ))
        }
        // 블링크 = 시각 펄스 (하한 alpha 0.55 — 소멸 아님, R4 §F-1 허용 전례).
        if isNewBest {
            let half = FeelTuning.R5.recordChipBlinkCycle / 2
            chip.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: FeelTuning.R5.recordChipBlinkLowAlpha, duration: half),
                SKAction.fadeAlpha(to: 1.0, duration: half)
            ])), withKey: Self.recordBlinkActionKey)
        }
    }

    // MARK: - Step ~2.4s — 버튼 3종 staggered 등장 + 시퀀스 완료 확정
    private func revealButtons(animated: Bool) {
        guard !revealCompleted else { return }
        revealCompleted = true
        if let retry = retryButton, let character = characterButton,
           let records = recordsButton, retry.parent == nil {
            [retry, character, records].forEach { addChild($0) }
            layoutAll()   // 부착 직후 절대좌표 확정
            if animated {
                runStaggeredAppear([retry, character, records])
            }
        }
        // R6 §F6 — 시퀀스 완료 시점 *이후* 정적 칩만 추가 (6단계 타이밍·순서 무변경).
        revealMetaOutcomeChips()
        // R7 §F5/F6 — 해금 배너 → 업적 토스트 순차 연출. revealCompleted 합류점 *이후* 추가만 —
        // 정상 완료·스킵(finishRevealImmediately) 어느 경로든 본 가드 1회 통과로 자동 일관.
        startMetaCelebrationSequence()
        #if DEBUG
        print("[ResultScene] 시퀀스 완료 직계 자식: \(children.count)")
        #endif
        presentDiplomaIfNeeded()
    }

    /// R6 §F6 — 일일 최초 클리어 배지 + 신규 업적 칩. 해당 없으면 노드 미생성 (좀비 금지).
    /// revealCompleted 가드 내 1회 실행 — 스킵·정상 완료 어느 경로든 멱등.
    private func revealMetaOutcomeChips() {
        guard let runMeta = runMeta else { return }
        if runMeta.isDailyFirstClear, dailyClearChip == nil {
            let chip = PixelChipNode(text: UILayout.R6.resultDailyClearChipText,
                                     style: .accent(Palette.gold))
            chip.zPosition = ZOrder.Layer.hud
            dailyClearChip = chip
            contentNode.addChild(chip)
        }
        if !runMeta.newAchievements.isEmpty, achievementChip == nil {
            let chip = PixelChipNode(
                text: "\(UILayout.R6.resultAchievementChipPrefix)\(runMeta.newAchievements.count)",
                style: .accent(Palette.mint)
            )
            chip.zPosition = ZOrder.Layer.hud
            achievementChip = chip
            contentNode.addChild(chip)
        }
        layoutAll()   // 부착 직후 좌표 확정 (layoutContent가 칩 위치 소유)
    }

    // R8 §B③ — xpSnapshot()(XP 파생 — +Build도 호출)은 ResultScene+Build.swift로 이동
    // (300줄 위생 — 코드 이동만, 로직 0 변경. 소비처 응집: buildRevealNodes/revealXP 공용).
}
