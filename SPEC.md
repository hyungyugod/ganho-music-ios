# Phase 8-4 — ResultScene 디자인 동일화

## 개요
원본 웹게임 종료 오버레이(`#overlayEnd .game-overlay__panel--end`)의 시각 시스템을 ResultScene에 이식. 반투명 검정 배경 + 가운데 380 너비 카드 패널 + 점수 숫자 40pt 코럴 serif + 베스트 12pt brand 톤. 라벨 위치는 기존 유지, *시각 토큰만* 갈아 끼움.

## 변경 유형
**비주얼**

## Sprint 범위 계약

### 허용
1. `Config/GameConfig.swift` — ResultScene 시각 상수 추가 (panel max-width 380, score-num 40, score-label 14, record 12, stats-label 11, stats-value 16)
2. `Scenes/ResultScene.swift` — setupOverlayPanel 신설(TitleScene 답습) + 라벨 색·크기 토큰 갈아 끼움. 라벨 *위치/구조 보존*.

### 금지
1. ResultScene 라벨 *위치* 변경 — 회귀 0
2. 졸업장 시각 변경 — 다음 sprint
3. GameOver 흐름 변경
4. TitleScene / GameScene 미접촉

## 변경 범위
- 수정: GameConfig.swift, ResultScene.swift
- 신규 파일 0개, pbxproj 변경 0건.

## 기능 1: GameConfig 신규 상수

```swift
// MARK: - Result Scene UI (Phase 8-4)
static let resultPanelMaxWidth: CGFloat = 380       // 원본 #overlayEnd .game-overlay__panel--end
static let resultPanelHeight: CGFloat = 560         // 모바일 풀스크린에 맞춰
static let resultPanelPadding: CGFloat = 18          // 원본 padding 16 18
static let resultScoreNumFontSize: CGFloat = 40      // 원본 40px serif (모바일 32)
static let resultScoreLabelFontSize: CGFloat = 14    // 원본 14px text-muted
static let resultRecordFontSize: CGFloat = 12        // 원본 12px brand
static let resultStatsLabelFontSize: CGFloat = 11    // 원본 11px upper case
static let resultStatsValueFontSize: CGFloat = 16    // 원본 16px tabular
```

## 기능 2: ResultScene setupOverlayPanel

TitleScene과 동일 패턴. didMove 또는 init 진입 직후 호출:

```swift
private func setupOverlayPanel() {
    let bg = SKSpriteNode(color: .ganhoUIOverlayBg, size: size)
    bg.position = CGPoint(x: frame.midX, y: frame.midY)
    bg.zPosition = -10
    addChild(bg)

    let panel = SKShapeNode(rectOf: CGSize(width: GameConfig.resultPanelMaxWidth,
                                            height: GameConfig.resultPanelHeight),
                            cornerRadius: GameConfig.uiRadius)
    panel.fillColor = .ganhoUIBgCard
    panel.strokeColor = .ganhoUIBorder
    panel.lineWidth = GameConfig.uiPanelLineWidth
    panel.position = CGPoint(x: frame.midX, y: frame.midY)
    panel.zPosition = -5
    addChild(panel)
}
```

## 기능 3: 라벨 색·크기 토큰 갈아 끼움

ResultScene의 각 라벨 색·크기를 원본 토큰으로 변경. *위치는 미접촉*.

```swift
// 점수 숫자 (큰 점수 라벨)
scoreLabel.fontSize = GameConfig.resultScoreNumFontSize  // 40
scoreLabel.fontColor = .ganhoUIBrandLight                // 코럴 강조

// 베스트 기록
bestLabel.fontSize = GameConfig.resultRecordFontSize     // 12
bestLabel.fontColor = .ganhoUIBrand                       // 코럴

// 캐릭터 이름 / 난이도 등 부수 라벨
characterLabel.fontColor = .ganhoUITextMuted             // 회색
characterLabel.fontSize = GameConfig.resultScoreLabelFontSize  // 14

// 통계 라벨 (있다면)
// statsLabel.fontSize = ...
```

## 회귀 0 자연 차단

1. **라벨 위치 보존** — Phase 6-15 NEW BEST 위치 / Phase 7-1 난이도 라벨 위치 미변경
2. **DiplomaOverlayNode 미접촉** — 졸업장 자기 디자인 유지
3. **GameScene endGame 미접촉** — factory 호출 그대로
4. **TitleScene 미접촉** — Phase 8-3 결과 보존
5. **isNewGraduation 플로우 보존** — setupLabels 끝 졸업장 자동 표시 그대로

## 주의사항

1. **zPosition 위계** — 패널 -5보다 라벨 zPosition 0~150 위에 자연 표시
2. **panel height 560** — 매직 넘버지만 모바일 풀스크린 비율에 맞춰. resultPanelHeight 상수로 분리
3. **scoreLabel 폰트 색** — Phase 6-15 NEW BEST 시퀀스 후 황금색으로 변할 때 *NEW BEST 시퀀스가 마지막 색을 결정*. setupLabels에서 기본 brand-light, isNewBest 시 황금색은 NEW BEST 시퀀스가 덮어씀. 충돌 없음.
4. **`difficultyLabel.fontColor`** — 현재 .white. text-muted로 변경.
5. **시뮬레이터에서 *패널 안에 라벨이 다 들어가는지* 시각 검증 필요** — 380 너비 / 560 높이. 라벨이 패널 밖으로 튀어나오면 SPEC 위반.
