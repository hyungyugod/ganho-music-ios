//
//  HUDNode.swift
//  GanhoMusic Shared
//
//  Phase 2-4 · 점수/시간 라벨 컨테이너 (cameraNode 자식 — 화면 고정)
//  Phase 5-4 · HUD 우상단 캐릭터 이름 라벨 (단일 setter 주입)
//  Phase 8-5 · 원본 .game-hud (game.css L232-289) 상단 가로 4슬롯 + 2단 구조 이식
//  Sprint 3 · v2 디자인 시스템 — navy 알약 + Jua 골드 라벨 + 흰 값 + TIME 경고 + 진행바
//

import SpriteKit

/// HUD 컨테이너 — 상단 가로 4슬롯(TIME / SCORE / COMBO / PLAYER).
/// 각 슬롯은 SKNode 컨테이너 + 라벨(위 10pt 골드) + 값(아래 18pt 흰) + navy 알약 배경.
/// 원본 web .game-hud (game.css L232-289) 시각 이식 + Sprint 3 v2 디자인 시스템.
/// 외부 인터페이스(update/setCharacterName/startTensionBlink/stopTensionBlink) 시그니처는 *완전 보존*.
final class HUDNode: SKNode {

    // MARK: - Properties
    /// 4개 가로 슬롯. 각 슬롯이 SKNode 컨테이너 + 라벨/값 자식.
    /// timeSlot만 `showTimeBar: true` — 하단 진행바 자식 2개 추가.
    private let timeSlot: HUDSlotNode
    private let scoreSlot: HUDSlotNode
    private let comboSlot: HUDSlotNode
    private let nameSlot: HUDSlotNode

    // MARK: - Display Cache (출시 전 최적화 — 라벨 지오메트리 재빌드 절감)
    /// 직전 표시한 점수. nil = 첫 호출(무조건 적용). 같으면 setValue 생략 → 지오메트리 재빌드 0.
    /// ⚠️ 옵셔널 sentinel — 0 초기화 시 첫 프레임 score=0이 "변화 없음"으로 skip되어 라벨 누락 위험.
    private var lastDisplayedScore: Int?
    /// 직전 표시한 정수 초(ceil 결과). seconds가 바뀔 때만 String(format:) + setValue (포맷 비용도 절감).
    private var lastDisplayedSeconds: Int?
    /// 직전 표시한 콤보. 값/색 둘 다 이 캐시로 가드. pulseCombo도 이 값을 갱신해 정합(잔상 0).
    private var lastDisplayedCombo: Int?

    // MARK: - Init
    override init() {
        timeSlot  = HUDSlotNode(label: "TIME",   initialValue: "00:45", showTimeBar: true)
        scoreSlot = HUDSlotNode(label: "SCORE",  initialValue: "0")
        // R7 §F3 — 콤보 칩 하단 60×4 게이지 (콤보 윈도우 잔여 가시화).
        comboSlot = HUDSlotNode(label: "COMBO",  initialValue: "0", showComboGauge: true)
        nameSlot  = HUDSlotNode(label: "PLAYER", initialValue: "")
        super.init()

        // 가로 4 슬롯 중앙 정렬 — 슬롯 간격 80, 총 폭 240, 양옆 -120 / +120.
        // anchor (0,0) = 상단 중앙 (GameScene.layoutHUD가 (0, +halfH-margin)로 배치).
        let spacing = UILayout.hudSlotSpacing
        timeSlot.position  = CGPoint(x: -spacing * 1.5, y: 0)
        scoreSlot.position = CGPoint(x: -spacing * 0.5, y: 0)
        comboSlot.position = CGPoint(x: +spacing * 0.5, y: 0)
        nameSlot.position  = CGPoint(x: +spacing * 1.5, y: 0)

        addChild(timeSlot)
        addChild(scoreSlot)
        addChild(comboSlot)
        addChild(nameSlot)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Update
    /// 외부에서 매 프레임 호출. 점수 + 남은 시간 + 콤보를 슬롯 값에 반영.
    /// remainingTime은 ceil로 올림 — 사용자가 시작 직후 "45"를 1초간 보도록.
    /// 콤보 hot: 3 이상 골드(v2), 그 외 흰색.
    /// Sprint 3 — TIME 슬롯 끝에 경고 색 swap + 진행바 갱신 블록 추가.
    func update(score: Int, remainingTime: TimeInterval, combo: Int) {
        // 출시 전 최적화 — 직전 표시값과 다른 슬롯만 갱신(SKLabelNode 지오메트리 재빌드 절감).
        // 표시 결과는 100% 동일 — 같은 값일 때 setValue 호출만 생략한다.
        // 점수 — 바뀐 경우만 setValue.
        if score != lastDisplayedScore {
            lastDisplayedScore = score
            scoreSlot.setValue("\(score)")
        }
        // 시간 — 정수 초가 바뀐 경우만 String(format:) + setValue (포맷 비용도 절감).
        let seconds = max(0, Int(ceil(remainingTime)))
        if seconds != lastDisplayedSeconds {
            lastDisplayedSeconds = seconds
            timeSlot.setValue(String(format: "00:%02d", seconds))
        }
        // 콤보 — 값/색 둘 다 콤보 캐시로 가드. pulse 색과 동일 함수(colorForCombo) → 잔상 0.
        if combo != lastDisplayedCombo {
            lastDisplayedCombo = combo
            comboSlot.setValue("\(combo)")
            comboSlot.setValueColor(colorForCombo(combo))
        }

        // Sprint 3 — TIME 경고 색 swap + 진행바 갱신.
        // setWarn(fillColor 1줄 멱등)·setTimeBar(xScale 1줄)는 연속값이라 매 프레임 현행 유지 —
        // 버킷팅 시 시각 회귀 위험이 있어 SPEC 안전 기본값(현행 유지) 채택. 비용은 지오메트리 재빌드가 아님.
        // tensionWindow 이하 진입 시 코랄 경고 배경. 그 외엔 navy 기본.
        let warn = remainingTime <= FeelTuning.tensionWindow
        timeSlot.setWarn(warn)
        // 진행바 xScale 비율 — 시작 1.0 → 0초 0.0.
        let progress = CGFloat(remainingTime / GameplayTuning.gameDuration)
        timeSlot.setTimeBar(progress: progress)
    }

    // MARK: - Style
    func applyReadableStyle() {
        alpha = UILayout.ingameHUDReadableAlpha
    }

    // MARK: - Collect Feedback
    func pulseCombo(combo: Int) {
        // 출시 전 최적화 — 캐시 동기화. 이후 update가 같은 combo로 들어와도 색을 덮어쓰지 않게 정합.
        // pulse가 건 색(colorForCombo(combo)) == update가 걸 색 → 시각 결과 동일, 재set만 절감.
        lastDisplayedCombo = combo
        comboSlot.setValueColor(colorForCombo(combo))
        comboSlot.pulseValue(
            scale: FeelTuning.hudComboPulseScale,
            upDuration: FeelTuning.hudComboPulseUpDuration,
            downDuration: FeelTuning.hudComboPulseDownDuration
        )
    }

    private func colorForCombo(_ combo: Int) -> UIColor {
        if combo >= GameplayTuning.comboBonusThresholdHigh { return .ganhoPixelComboRed }
        if combo >= GameplayTuning.comboBonusThresholdMid { return .ganhoPixelComboGold }
        if combo >= GameplayTuning.comboBonusThreshold { return .ganhoPixelHudYellow }
        return .ganhoPixelHudWhite
    }

    // MARK: - Combo Gauge (R7 §F3)
    /// 콤보 윈도우(2.5s) 잔여 게이지 갱신 — GameScene.updateHUDPhase가 매 프레임 호출.
    /// fraction nil = combo 0 → 게이지 비표시 + 점멸 정지. endGame 경로도 nil로 확실히 소거.
    /// near-miss 연장(F2)은 ScoreSystem 파생값(comboWindowRemainingFraction)이라 자동 반영.
    func updateComboGauge(fraction: CGFloat?) {
        comboSlot.setComboGauge(fraction: fraction)
    }

    // MARK: - Character Name
    /// Phase 5-4 — 선택 캐릭터 이름을 HUD nameSlot 값 라벨에 1회 주입.
    /// 한 판 안에서 호출은 1회만 권장 (런타임 변경 미지원).
    /// 빈 문자열을 넘기면 값 라벨이 비어 보이지 않는다(텍스트만 사라짐).
    func setCharacterName(_ name: String) {
        nameSlot.setValue(name, fitToWidth: true)
    }

    // MARK: - Tension (Phase 6-14)
    /// timeSlot의 값 라벨을 픽셀 옐로 ↔ 픽셀 화이트 1초 주기로 깜빡이게 한다.
    /// Sprint 10 Phase J — v2 토큰(ganhoMusicGold/.white) → 픽셀 토큰
    /// (ganhoPixelHudYellow/ganhoPixelHudWhite) swap. 시그니처 0 변경.
    /// 같은 key(`tensionBlinkActionKey`)로 중복 호출 시 SpriteKit이 이전 액션을 자동 교체(자연 멱등).
    func startTensionBlink() {
        timeSlot.startBlink(color: .ganhoPixelHudYellow)
    }

    /// 깜빡임 액션 제거 + 색 즉시 기본 색(픽셀 화이트)으로 복원 (잔상 0).
    /// removeAction은 키가 없어도 안전(noop).
    /// Sprint 10 Phase J — .white → ganhoPixelHudWhite swap.
    func stopTensionBlink() {
        timeSlot.stopBlink(restoreColor: .ganhoPixelHudWhite)
    }
}

// MARK: - HUD Slot Node (Phase 8-5 · Sprint 3 v2)

/// HUD 단일 슬롯 — navy 알약 + 라벨(위 10pt 골드) + 값(아래 18pt 흰).
/// HUDNode 내부 구현 디테일이라 같은 파일에 둠 (외부 노출 X).
/// 원본 .game-hud__entry > .game-hud__label + .game-hud__value 1:1 매핑.
/// Sprint 3 — 알약 배경, fontDisplay, v2 색 토큰, TIME 슬롯 진행바.
final class HUDSlotNode: SKNode {

    // MARK: - Properties
    /// navy 0.78 알약 배경. setWarn(true) 진입 시 코랄로 swap.
    private let shadowNode: SKShapeNode
    private let backgroundChip: SKShapeNode
    private let labelNode: SKLabelNode
    private let valueNode: SKLabelNode
    /// TIME 슬롯 전용 진행바 배경(흰 α). showTimeBar=true일 때만 자식.
    private let timeBarBg: SKSpriteNode?
    /// TIME 슬롯 전용 진행바 채움(흰). xScale로 진행률 시각화.
    private let timeBarFill: SKSpriteNode?
    /// R7 §F3 — COMBO 슬롯 전용 콤보 윈도우 게이지(60×4). showComboGauge=true일 때만 자식.
    /// timeBar 패턴 재사용 — SKSpriteNode 2장, xScale 갱신만 (매 프레임 텍스처/노드 생성 0).
    private let comboGaugeBg: SKSpriteNode?
    private let comboGaugeFill: SKSpriteNode?
    /// R7 §F3 — 코랄 점멸 상태. 상태 전환 시 1회 부착/제거 (매 프레임 SKAction 재부착 금지).
    private var isComboGaugeBlinking = false

    // MARK: - Init
    /// - Parameters:
    ///   - label: 위쪽 캡션 텍스트 ("TIME"/"SCORE"/"COMBO"/"PLAYER").
    ///   - initialValue: 아래쪽 값 텍스트 초기값.
    ///   - showTimeBar: TIME 슬롯 전용 진행바 자식 생성 여부 (default false → 호환성 100%).
    ///   - showComboGauge: COMBO 슬롯 전용 콤보 윈도우 게이지 생성 여부 (R7 §F3, default false).
    init(label: String, initialValue: String, showTimeBar: Bool = false,
         showComboGauge: Bool = false) {
        // (1) 배경 알약 — navy 0.78. setWarn으로 코랄 교체 가능.
        let chipSize = CGSize(
            width: UILayout.hudSlotWidth,
            height: UILayout.hudSlotHeight
        )
        shadowNode = SKShapeNode(
            rectOf: chipSize,
            cornerRadius: UILayout.hudSlotCornerRadius
        )
        backgroundChip = SKShapeNode(
            rectOf: chipSize,
            cornerRadius: UILayout.hudSlotCornerRadius
        )
        shadowNode.fillColor = UIColor.ganhoPixelOutlineBlack
            .withAlphaComponent(UILayout.hudSlotShadowAlpha)
        shadowNode.strokeColor = .clear
        shadowNode.position = CGPoint(
            x: UILayout.hudSlotShadowOffsetX,
            y: UILayout.hudSlotShadowOffsetY
        )
        shadowNode.zPosition = 98
        backgroundChip.fillColor = UIColor.ganhoNavyDeep
            .withAlphaComponent(UILayout.hudSlotBgAlpha)
        backgroundChip.strokeColor = UIColor.ganhoPixelHudYellow
            .withAlphaComponent(UILayout.hudSlotStrokeAlpha)
        backgroundChip.lineWidth = UILayout.hudSlotStrokeWidth
        backgroundChip.zPosition = 99

        // (2) 라벨/값 SKLabelNode. Sprint 10 Phase J — fontDisplay(Jua-Regular) → fontPixel(Menlo-Bold).
        labelNode = SKLabelNode(fontNamed: Typography.fontPixel)
        labelNode.text = label
        valueNode = SKLabelNode(fontNamed: Typography.fontPixel)
        valueNode.text = initialValue

        // (3) 진행바 자식 — TIME 슬롯만. xScale 갱신을 위해 anchorPoint 좌측 정렬.
        if showTimeBar {
            let barSize = CGSize(
                width: chipSize.width - 8,
                height: UILayout.hudTimeBarHeight
            )
            let bg = SKSpriteNode(color: .white, size: barSize)
            bg.alpha = UILayout.hudTimeBarBgAlpha
            bg.anchorPoint = CGPoint(x: 0, y: 0.5)
            // 알약 안 하단. -chipHeight/2 + bar 높이/2 + gap.
            bg.position = CGPoint(
                x: -barSize.width / 2,
                y: -chipSize.height / 2 + UILayout.hudTimeBarHeight / 2 + UILayout.hudTimeBarTopGap
            )
            // Sprint 8 Phase F — V4 zPos 명시화(값 100 보존).
            bg.zPosition = ZOrder.hudLabelZPosition
            timeBarBg = bg

            let fill = SKSpriteNode(color: .white, size: barSize)
            fill.alpha = 0.95
            fill.anchorPoint = CGPoint(x: 0, y: 0.5)
            fill.position = bg.position
            // Sprint 8 Phase F — V4 zPos +1 (값 101 보존, fill이 bg 위).
            fill.zPosition = ZOrder.hudLabelZPosition + 1
            // 시작 시 가득 찬 상태. setTimeBar(progress:)로 매 프레임 갱신.
            fill.xScale = 1.0
            timeBarFill = fill
        } else {
            timeBarBg = nil
            timeBarFill = nil
        }

        // (3-b) R7 §F3 — 콤보 윈도우 게이지 — COMBO 슬롯만. timeBar(3)와 동일 anchor/배치 패턴.
        // 시작 isHidden=true: combo 0 동안 비표시. 상태형 HUD 요소의 표시/비표시 토글은 좀비 패턴
        // 아님 — 매 판 재사용되는 살아있는 상태 표시기의 OFF 시각이지, 불용 노드 잔존이 아니다.
        if showComboGauge {
            let gaugeSize = UILayout.R7.hudComboGaugeSize
            let gaugeY = -chipSize.height / 2 + gaugeSize.height / 2
                + UILayout.R7.hudComboGaugeBottomGap
            let bg = SKSpriteNode(color: .white, size: gaugeSize)
            bg.alpha = UILayout.hudTimeBarBgAlpha
            bg.anchorPoint = CGPoint(x: 0, y: 0.5)
            bg.position = CGPoint(x: -gaugeSize.width / 2, y: gaugeY)
            bg.zPosition = ZOrder.hudLabelZPosition
            bg.isHidden = true
            comboGaugeBg = bg

            let fill = SKSpriteNode(color: .white, size: gaugeSize)
            fill.alpha = FeelTuning.R7.comboGaugeFillAlpha
            fill.anchorPoint = CGPoint(x: 0, y: 0.5)
            fill.position = bg.position
            fill.zPosition = ZOrder.hudLabelZPosition + 1
            fill.isHidden = true
            comboGaugeFill = fill
        } else {
            comboGaugeBg = nil
            comboGaugeFill = nil
        }

        super.init()

        // (4) 위쪽 라벨 — 10pt 픽셀 옐로. labelNode.position을 super.init 후 set.
        // Sprint 10 Phase J — ganhoMusicGold → ganhoPixelHudYellow swap.
        labelNode.fontSize = UILayout.hudSlotLabelFontSize
        labelNode.fontColor = .ganhoPixelHudYellow
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        // Sprint 8 Phase F — V4 zPos 명시화(값 100 보존).
        labelNode.zPosition = ZOrder.hudLabelZPosition
        labelNode.position = CGPoint(
            x: 0,
            y: UILayout.hudSlotValueFontSize / 2 + UILayout.hudSlotInnerGap
        )

        // (5) 아래쪽 값 — 18pt 픽셀 화이트(페이퍼 화이트 톤). Sprint 10 Phase J — .white → ganhoPixelHudWhite.
        valueNode.fontSize = UILayout.hudSlotValueFontSize
        valueNode.fontColor = .ganhoPixelHudWhite
        valueNode.horizontalAlignmentMode = .center
        valueNode.verticalAlignmentMode = .center
        // Sprint 8 Phase F — V4 zPos 명시화(값 100 보존).
        valueNode.zPosition = ZOrder.hudLabelZPosition
        valueNode.position = CGPoint(
            x: 0,
            y: -UILayout.hudSlotLabelFontSize / 2 - UILayout.hudSlotInnerGap
        )

        // (6) 자식 부착 — 그림자(98) → 배경(99) → 진행바/게이지(100/101) → 라벨/값(100).
        addChild(shadowNode)
        addChild(backgroundChip)
        if let bg = timeBarBg { addChild(bg) }
        if let fill = timeBarFill { addChild(fill) }
        if let bg = comboGaugeBg { addChild(bg) }
        if let fill = comboGaugeFill { addChild(fill) }
        addChild(labelNode)
        addChild(valueNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
