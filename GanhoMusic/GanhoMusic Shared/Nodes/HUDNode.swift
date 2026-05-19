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

    // MARK: - Init
    override init() {
        timeSlot  = HUDSlotNode(label: "TIME",   initialValue: "00:45", showTimeBar: true)
        scoreSlot = HUDSlotNode(label: "SCORE",  initialValue: "0")
        comboSlot = HUDSlotNode(label: "COMBO",  initialValue: "0")
        nameSlot  = HUDSlotNode(label: "PLAYER", initialValue: "")
        super.init()

        // 가로 4 슬롯 중앙 정렬 — 슬롯 간격 80, 총 폭 240, 양옆 -120 / +120.
        // anchor (0,0) = 상단 중앙 (GameScene.layoutHUD가 (0, +halfH-margin)로 배치).
        let spacing = GameConfig.hudSlotSpacing
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
        scoreSlot.setValue("\(score)")
        let seconds = max(0, Int(ceil(remainingTime)))
        timeSlot.setValue(String(format: "00:%02d", seconds))
        comboSlot.setValue("\(combo)")
        comboSlot.setValueColor(combo >= 3 ? .ganhoMusicGold : .white)

        // Sprint 3 — TIME 경고 색 swap + 진행바 갱신.
        // tensionWindow 이하 진입 시 코랄 경고 배경. 그 외엔 navy 기본.
        let warn = remainingTime <= GameConfig.tensionWindow
        timeSlot.setWarn(warn)
        // 진행바 xScale 비율 — 시작 1.0 → 0초 0.0.
        let progress = CGFloat(remainingTime / GameConfig.gameDuration)
        timeSlot.setTimeBar(progress: progress)
    }

    // MARK: - Character Name
    /// Phase 5-4 — 선택 캐릭터 이름을 HUD nameSlot 값 라벨에 1회 주입.
    /// 한 판 안에서 호출은 1회만 권장 (런타임 변경 미지원).
    /// 빈 문자열을 넘기면 값 라벨이 비어 보이지 않는다(텍스트만 사라짐).
    func setCharacterName(_ name: String) {
        nameSlot.setValue(name)
    }

    // MARK: - Tension (Phase 6-14)
    /// timeSlot의 값 라벨을 골드 ↔ 흰 1초 주기로 깜빡이게 한다.
    /// Sprint 3 — v2 토큰(ganhoMusicGold ↔ .white)으로 색 교체. 시그니처 0 변경.
    /// 같은 key(`tensionBlinkActionKey`)로 중복 호출 시 SpriteKit이 이전 액션을 자동 교체(자연 멱등).
    func startTensionBlink() {
        timeSlot.startBlink(color: .ganhoMusicGold)
    }

    /// 깜빡임 액션 제거 + 색 즉시 기본 색(.white)으로 복원 (잔상 0).
    /// removeAction은 키가 없어도 안전(noop).
    func stopTensionBlink() {
        timeSlot.stopBlink(restoreColor: .white)
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
    private let backgroundChip: SKShapeNode
    private let labelNode: SKLabelNode
    private let valueNode: SKLabelNode
    /// TIME 슬롯 전용 진행바 배경(흰 α). showTimeBar=true일 때만 자식.
    private let timeBarBg: SKSpriteNode?
    /// TIME 슬롯 전용 진행바 채움(흰). xScale로 진행률 시각화.
    private let timeBarFill: SKSpriteNode?

    // MARK: - Init
    /// - Parameters:
    ///   - label: 위쪽 캡션 텍스트 ("TIME"/"SCORE"/"COMBO"/"PLAYER").
    ///   - initialValue: 아래쪽 값 텍스트 초기값.
    ///   - showTimeBar: TIME 슬롯 전용 진행바 자식 생성 여부 (default false → 호환성 100%).
    init(label: String, initialValue: String, showTimeBar: Bool = false) {
        // (1) 배경 알약 — navy 0.78. setWarn으로 코랄 교체 가능.
        let chipSize = CGSize(
            width: GameConfig.hudSlotWidth,
            height: GameConfig.hudSlotHeight
        )
        backgroundChip = SKShapeNode(
            rectOf: chipSize,
            cornerRadius: GameConfig.hudSlotCornerRadius
        )
        backgroundChip.fillColor = UIColor.ganhoNavyDeep
            .withAlphaComponent(GameConfig.hudSlotBgAlpha)
        backgroundChip.strokeColor = .clear
        backgroundChip.zPosition = 99

        // (2) 라벨/값 SKLabelNode. fontName = Jua-Regular(fontDisplay) — v2 시스템.
        labelNode = SKLabelNode(fontNamed: GameConfig.fontDisplay)
        labelNode.text = label
        valueNode = SKLabelNode(fontNamed: GameConfig.fontDisplay)
        valueNode.text = initialValue

        // (3) 진행바 자식 — TIME 슬롯만. xScale 갱신을 위해 anchorPoint 좌측 정렬.
        if showTimeBar {
            let barSize = CGSize(
                width: chipSize.width - 8,
                height: GameConfig.hudTimeBarHeight
            )
            let bg = SKSpriteNode(color: .white, size: barSize)
            bg.alpha = GameConfig.hudTimeBarBgAlpha
            bg.anchorPoint = CGPoint(x: 0, y: 0.5)
            // 알약 안 하단. -chipHeight/2 + bar 높이/2 + gap.
            bg.position = CGPoint(
                x: -barSize.width / 2,
                y: -chipSize.height / 2 + GameConfig.hudTimeBarHeight / 2 + GameConfig.hudTimeBarTopGap
            )
            bg.zPosition = 100
            timeBarBg = bg

            let fill = SKSpriteNode(color: .white, size: barSize)
            fill.alpha = 0.95
            fill.anchorPoint = CGPoint(x: 0, y: 0.5)
            fill.position = bg.position
            fill.zPosition = 101
            // 시작 시 가득 찬 상태. setTimeBar(progress:)로 매 프레임 갱신.
            fill.xScale = 1.0
            timeBarFill = fill
        } else {
            timeBarBg = nil
            timeBarFill = nil
        }

        super.init()

        // (4) 위쪽 라벨 — 10pt 골드. labelNode.position을 super.init 후 set.
        labelNode.fontSize = GameConfig.hudSlotV2LabelFontSize
        labelNode.fontColor = .ganhoMusicGold
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.zPosition = 100
        labelNode.position = CGPoint(
            x: 0,
            y: GameConfig.hudSlotV2ValueFontSize / 2 + GameConfig.hudSlotInnerGap
        )

        // (5) 아래쪽 값 — 18pt 흰색.
        valueNode.fontSize = GameConfig.hudSlotV2ValueFontSize
        valueNode.fontColor = .white
        valueNode.horizontalAlignmentMode = .center
        valueNode.verticalAlignmentMode = .center
        valueNode.zPosition = 100
        valueNode.position = CGPoint(
            x: 0,
            y: -GameConfig.hudSlotV2LabelFontSize / 2 - GameConfig.hudSlotInnerGap
        )

        // (6) 자식 부착 — 배경(99) → 진행바(100/101, TIME만) → 라벨/값(100).
        addChild(backgroundChip)
        if let bg = timeBarBg { addChild(bg) }
        if let fill = timeBarFill { addChild(fill) }
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

    /// 값 라벨 색 갱신. 콤보 hot 색 갈아 끼움(3+ 골드, 그 외 흰).
    func setValueColor(_ c: UIColor) {
        valueNode.fontColor = c
    }

    // MARK: - Sprint 3 v2 · Warn / TimeBar
    /// 경고 모드 toggle. on=true → 코랄 배경, on=false → navy 기본 배경.
    /// SetWarn은 fillColor 교체 1줄로 멱등 — 중복 호출 안전.
    func setWarn(_ on: Bool) {
        backgroundChip.fillColor = on
            ? UIColor.ganhoCoralShadow.withAlphaComponent(GameConfig.hudSlotWarnBgAlpha)
            : UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.hudSlotBgAlpha)
    }

    /// TIME 슬롯 진행바 갱신. progress 1.0 = 가득, 0.0 = 비움.
    /// showTimeBar=false 슬롯에서 호출하면 자연 noop (timeBarFill=nil).
    func setTimeBar(progress: CGFloat) {
        timeBarFill?.xScale = max(0, min(1, progress))
    }

    // MARK: - Tension Blink (Phase 6-14 · Sprint 3 v2)
    /// 값 라벨을 지정 색 ↔ 기본 색(.white) 1초 주기로 깜빡인다.
    /// SKLabelNode의 `colorize` 액션은 `colorBlendFactor` 이슈로 일관성 ↓ → fontColor 직접 교체 패턴 채택.
    /// 콜백은 [weak self] 캡처 — 씬 전환 시 액션 잔존 시 안전.
    func startBlink(color: UIColor) {
        let toAccent = SKAction.run { [weak self] in self?.valueNode.fontColor = color }
        let toBase = SKAction.run { [weak self] in self?.valueNode.fontColor = .white }
        let wait = SKAction.wait(forDuration: GameConfig.tensionBlinkHalfPeriod)
        let cycle = SKAction.sequence([toAccent, wait, toBase, wait])
        valueNode.run(.repeatForever(cycle), withKey: GameConfig.tensionBlinkActionKey)
    }

    /// 깜빡임 액션 제거 + 색 즉시 복원 (잔상 0).
    /// removeAction은 키가 없어도 안전(noop).
    func stopBlink(restoreColor: UIColor) {
        valueNode.removeAction(forKey: GameConfig.tensionBlinkActionKey)
        valueNode.fontColor = restoreColor
    }
}
