//
//  HUDSlotNode+Display.swift
//  GanhoMusic Shared
//
//  R8 §B③ — HUDSlotNode 표시 갱신 계열(값/색/펄스/경고/진행바/콤보 게이지/블링크) 분리.
//  본체 단독 300줄 초과 회피 — 코드 이동만, 로직/시그니처 0 변경.
//

import SpriteKit

extension HUDSlotNode {

    // MARK: - Setters
    /// 값 라벨 텍스트 갱신. HUDNode.update가 매 프레임 호출.
    func setValue(_ s: String) {
        valueNode.text = s
    }

    func setValue(_ s: String, fitToWidth: Bool) {
        valueNode.text = s
        guard fitToWidth else { return }
        fitValueLabel()
    }

    /// 값 라벨 색 갱신. 콤보 hot 색 갈아 끼움(3+ 골드, 그 외 흰).
    func setValueColor(_ c: UIColor) {
        valueNode.fontColor = c
    }

    func pulseValue(scale: CGFloat, upDuration: TimeInterval, downDuration: TimeInterval) {
        valueNode.removeAction(forKey: FeelTuning.hudComboPulseActionKey)
        valueNode.setScale(1.0)
        let grow = SKAction.scale(to: scale, duration: upDuration)
        let shrink = SKAction.scale(to: 1.0, duration: downDuration)
        valueNode.run(.sequence([grow, shrink]), withKey: FeelTuning.hudComboPulseActionKey)
    }

    // MARK: - Sprint 3 v2 · Warn / TimeBar
    /// 경고 모드 toggle. on=true → 픽셀 코랄 배경, on=false → navy 기본 배경.
    /// SetWarn은 fillColor 교체 1줄로 멱등 — 중복 호출 안전.
    /// Sprint 10 Phase J — 경고 색 ganhoCoralShadow → ganhoPixelHudCoral. 기본 navy는 메뉴 잔상 0
    /// (HUDNode는 인게임 전용 호출).
    func setWarn(_ on: Bool) {
        backgroundChip.fillColor = on
            ? UIColor.ganhoPixelHudCoral.withAlphaComponent(UILayout.hudSlotWarnBgAlpha)
            : UIColor.ganhoNavyDeep.withAlphaComponent(UILayout.hudSlotBgAlpha)
        backgroundChip.strokeColor = on
            ? UIColor.ganhoPixelTensionEdge
            : UIColor.ganhoPixelHudYellow.withAlphaComponent(UILayout.hudSlotStrokeAlpha)
    }

    /// TIME 슬롯 진행바 갱신. progress 1.0 = 가득, 0.0 = 비움.
    /// showTimeBar=false 슬롯에서 호출하면 자연 noop (timeBarFill=nil).
    func setTimeBar(progress: CGFloat) {
        timeBarFill?.xScale = max(0, min(1, progress))
    }

    // MARK: - R7 §F3 · Combo Window Gauge
    /// 콤보 윈도우 잔여 게이지 갱신 — xScale 1줄 + 점멸 상태 전환만 (timeBar와 동일 비용 등급).
    /// fraction nil(combo 0) = 비표시 + 점멸 정지. showComboGauge=false 슬롯은 자연 noop.
    func setComboGauge(fraction: CGFloat?) {
        guard let bg = comboGaugeBg, let fill = comboGaugeFill else { return }
        guard let fraction = fraction else {
            if !bg.isHidden {
                bg.isHidden = true
                fill.isHidden = true
            }
            stopComboGaugeBlink()
            return
        }
        if bg.isHidden {
            bg.isHidden = false
            fill.isHidden = false
        }
        fill.xScale = max(0, min(1, fraction))
        // 잔여 초 환산 — 점멸 진입/이탈 판정 (2.5s × fraction).
        let remaining = TimeInterval(fraction) * GameplayTuning.comboWindow
        if remaining <= FeelTuning.R7.comboGaugeBlinkWindow {
            startComboGaugeBlinkIfNeeded()
        } else {
            stopComboGaugeBlink()
        }
    }

    /// 코랄 점멸 1회 부착 — 기존 픽셀 코랄 토큰 재사용 (신규 색 정의 금지).
    /// FProjectileNode.startNearMissPulseIfNeeded 상태 가드 패턴 동형 — withKey 멱등.
    private func startComboGaugeBlinkIfNeeded() {
        guard !isComboGaugeBlinking, let fill = comboGaugeFill else { return }
        isComboGaugeBlinking = true
        fill.color = .ganhoPixelHudCoral
        let half = FeelTuning.R7.comboGaugeBlinkHalfPeriod
        let blink = SKAction.sequence([
            .fadeAlpha(to: FeelTuning.R7.comboGaugeBlinkMinAlpha, duration: half),
            .fadeAlpha(to: FeelTuning.R7.comboGaugeFillAlpha, duration: half)
        ])
        fill.run(.repeatForever(blink), withKey: FeelTuning.R7.comboGaugeBlinkActionKey)
    }

    private func stopComboGaugeBlink() {
        guard isComboGaugeBlinking, let fill = comboGaugeFill else { return }
        isComboGaugeBlinking = false
        fill.removeAction(forKey: FeelTuning.R7.comboGaugeBlinkActionKey)
        fill.color = .white   // timeBarFill과 동일 기본 흰색 복원 (잔상 0)
        fill.alpha = FeelTuning.R7.comboGaugeFillAlpha
    }

    // MARK: - Tension Blink (Phase 6-14 · Sprint 3 v2)
    /// 값 라벨을 지정 색 ↔ 기본 색(.white) 1초 주기로 깜빡인다.
    /// SKLabelNode의 `colorize` 액션은 `colorBlendFactor` 이슈로 일관성 ↓ → fontColor 직접 교체 패턴 채택.
    /// 콜백은 [weak self] 캡처 — 씬 전환 시 액션 잔존 시 안전.
    func startBlink(color: UIColor) {
        // Sprint 10 Phase J — toBase .white → ganhoPixelHudWhite swap. accent 색은 호출자 주입 그대로.
        let toAccent = SKAction.run { [weak self] in self?.valueNode.fontColor = color }
        let toBase = SKAction.run { [weak self] in self?.valueNode.fontColor = .ganhoPixelHudWhite }
        let wait = SKAction.wait(forDuration: FeelTuning.tensionBlinkHalfPeriod)
        let cycle = SKAction.sequence([toAccent, wait, toBase, wait])
        valueNode.run(.repeatForever(cycle), withKey: FeelTuning.tensionBlinkActionKey)
    }

    /// 깜빡임 액션 제거 + 색 즉시 복원 (잔상 0).
    /// removeAction은 키가 없어도 안전(noop).
    func stopBlink(restoreColor: UIColor) {
        valueNode.removeAction(forKey: FeelTuning.tensionBlinkActionKey)
        valueNode.fontColor = restoreColor
    }

    private func fitValueLabel() {
        valueNode.setScale(1.0)
        let maxWidth = UILayout.hudSlotWidth - UILayout.hudSlotInnerGap * 2
        let width = valueNode.calculateAccumulatedFrame().width
        guard width > maxWidth, width > 0 else { return }
        valueNode.setScale(max(Typography.labelMinimumScale, maxWidth / width))
    }
}
