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
        // R8 P0-1 버그 픽스 (커밋 7275e720 기인) — 캐시만 갱신하고 setValue를 생략하면
        // 이후 update()의 `combo != lastDisplayedCombo` 가드가 항상 실패해 칩 텍스트가
        // "0"에 고정(stuck)된다. 캐시 동기화는 "값을 실제로 표시한 뒤"에만 유효 —
        // 색과 동일하게 텍스트도 여기서 직접 set해 캐시와 화면을 정합시킨다.
        lastDisplayedCombo = combo
        comboSlot.setValue("\(combo)")
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

// R8 §B③ — HUDSlotNode(구 동일 파일 2클래스)는 Nodes/HUDSlotNode.swift(+Display)로 분리.
