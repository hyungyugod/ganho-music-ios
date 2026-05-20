# SPEC.md — Sprint 9 Phase D · 결과창 V4 spacing (위 묶음 분리 + 전체 위로)

## 개요
Sprint 7 Phase D ResultScene V3 좌표는 위쪽 5단(headerChip/accentLine/title/subtitle/score)을 압축해 시각 호흡이 6~28pt에 그쳤다. 본 Phase D는 GameConfig V4 offset 7건 신설 + ResultScene `layoutLabels()`의 V3 참조만 V4로 1:1 치환해 위 묶음을 +20~30pt 상향, 위·아래 묶음(score↔divider) gap ≥ 60pt 분리.

## 변경 유형
**비주얼 (결과창 spacing)** — 좌표 상수 7건 + `layoutLabels()` 위치식 9건 치환만. 라벨 텍스트/폰트/색/액션/init 인자/터치 정책 전부 byte-identical 보존.

## 게임 경험 의도
플레이어가 게임 종료 후 결과창에서 각 정보 행을 또렷이 읽도록. V3에서 헤더칩↔타이틀↔부제가 압축돼 있던 답답함을 풀어 "수고했어요"의 따뜻한 호흡 회복. 위쪽 정체성 정보(난이도·캐릭터/타이틀/부제/점수)와 아래쪽 통계(divider/PLAYS·TOTAL)를 시각적으로 두 묶음으로 분리.

## Sprint 범위 계약 (Phase D 한정)
- **허용**:
  - `GameConfig.swift` Phase D V4 sub-MARK에 신규 상수 7건 추가
  - `ResultScene.swift` `layoutLabels()` 안에서 V3 참조를 V4로 1:1 치환 (9건)
  - 신규 V4 상수 주석(시각 호흡 의도)
- **금지**:
  - SPEC에 없는 신규 노드/효과/Phase 추가
  - V3 상수 값 변경 (전부 *값 보존* — 다른 곳 참조 가능 + 회귀 안전망)
  - V2 상수 값 변경
  - ResultScene init 9개 인자 시그니처 변경
  - scoreLabel.text 합성 정책 변경(`"\(finalScore)"` 그대로)
  - bestLabel.alpha = 0 정책 변경
  - DiplomaOverlayNode / sparkle / heavy 햅틱 / NewMail 사운드 발화 시점 변경
  - 2단계 탭 정책 변경
  - 3 버튼(scoreboard/share/restart) hit-test 좌표 변경
- **판단 기준**: "이 변경이 없으면 V4 spacing이 제대로 동작하지 않는가?" → YES면 허용.

## V4 상수 (7건)
```swift
// MARK: - Sprint 9 Phase D · Result V4 Spacing
static let resultHeaderChipOffsetYV4: CGFloat = 145   // V3 +115 → +30
static let resultAccentLineOffsetYV4: CGFloat = 178   // V3 +148 → +30
static let resultTitleOffsetYV4: CGFloat = 100        // V3 +85 → +15
static let resultSubtitleOffsetYV4: CGFloat = 64      // V3 +58 → +6
static let resultScoreOffsetYV4: CGFloat = 6          // V3 -2 → +8
static let resultDividerOffsetYV4: CGFloat = -68      // V3 -78 → +10
static let resultStatGapFromDividerV9: CGFloat = 28   // divider→stat 거리
```

## 기능 상세

### 기능 1: GameConfig V4 상수 7건 신설
- 위치: `Config/GameConfig.swift` 끝(Phase C V9 직후) `// MARK: - Sprint 9 Phase D · Result V4 Spacing`
- V3 상수 *값 보존*

### 기능 2: ResultScene `layoutLabels()` V3→V4 치환 9건
- 위치: `Scenes/ResultScene.swift` `layoutLabels()` 메서드
- 치환 9곳:
  1. headerChip.position.y → V4
  2. accentLine.position.y → V4
  3. subtitleLabel.position.y → V4
  4. scoreLabel.position.y → V4
  5. scoreNoteIconLabel.position.y → V4 (score row 동기화)
  6. bestPill.position.y → V4 (score row 동기화)
  7. divider.position.y → V4
  8. stat value 좌표 → `divider V4 - statGap V9` 상대식 (playsValue/totalValue)
  9. stat title 좌표 → `statValueY - 14` (playsTitle/totalTitle)

**V4 미적용 라인**:
- titleLabel (V2 그대로, alpha=0이라 시각 영향 없음)
- bestLabel / statsLabel / characterLabel / difficultyLabel / promptLabel / newBestLabel
- scoreSubLabel (V3 `-44` 그대로)
- buttonY 계산 (safeArea 기준)
- gradientBg / overlayPanel (frame.midX/midY)

**핵심 코드 구조**:
```swift
headerChip?.position = CGPoint(x: frame.midX,
    y: frame.midY + GameConfig.resultHeaderChipOffsetYV4)
accentLine.position = CGPoint(x: frame.midX,
    y: frame.midY + GameConfig.resultAccentLineOffsetYV4)
subtitleLabel.position = CGPoint(x: frame.midX,
    y: frame.midY + GameConfig.resultSubtitleOffsetYV4)
scoreLabel.position = CGPoint(x: frame.midX,
    y: frame.midY + GameConfig.resultScoreOffsetYV4)
scoreNoteIconLabel.position = CGPoint(
    x: frame.midX + GameConfig.resultScoreNoteIconOffsetXV3,
    y: frame.midY + GameConfig.resultScoreOffsetYV4)
bestPill?.position = CGPoint(
    x: frame.midX + GameConfig.resultBestPillOffsetXV3,
    y: frame.midY + GameConfig.resultScoreOffsetYV4)
divider.position = CGPoint(x: frame.midX,
    y: frame.midY + GameConfig.resultDividerOffsetYV4)

let statValueY = GameConfig.resultDividerOffsetYV4 - GameConfig.resultStatGapFromDividerV9
let statTitleY = statValueY - 14
playsValueLabel.position = CGPoint(
    x: frame.midX - GameConfig.resultStatGroupSpacingXV2, y: frame.midY + statValueY)
playsTitleLabel.position = CGPoint(
    x: frame.midX - GameConfig.resultStatGroupSpacingXV2, y: frame.midY + statTitleY)
totalValueLabel.position = CGPoint(
    x: frame.midX + GameConfig.resultStatGroupSpacingXV2, y: frame.midY + statValueY)
totalTitleLabel.position = CGPoint(
    x: frame.midX + GameConfig.resultStatGroupSpacingXV2, y: frame.midY + statTitleY)
```

## 변경 금지 영역 (§6 Phase D 관련)
| 영역 | 이유 |
|---|---|
| PlayerNode/SpawnSystem/ScoreSystem/SkillSystem/ContactRouter | 게임 로직 |
| Models/ Repositories/ | 의미·저장 보존 |
| CharacterFaceNode / NurseAvatarNode 전체 | 보호 노드 |
| Sprint 8 Phase F V4 zPos 적층 80<100<110 | Phase F 결과 |
| Sprint 8 Phase G 빌런 3종 2줄 | 의사결정 #6 |
| **ResultScene init 9개 인자 + scoreLabel "\(finalScore)" + bestLabel.alpha=0** | **분기별 발화 보존 — 본 Phase 최우선** |
| DiplomaOverlayNode 본체 | Sprint 5 결과 |
| Phase A/B/C V9 30종 + 산출물 | 직전 합격분 회귀 0 |

**국지적 보호**:
- ResultScene touchesBegan 전체 (scoreboardButton 분기 + StartScene 전이 + isTransitioning)
- revealNewBest / scheduleNewBestReveal / startBestLabelGoldBlink / emitSparkleBurst / presentDiploma 본문
- configureNewBestLabel newBestLabel.position
- buttonY 계산식 (safeArea)
- scoreboardButton / shareButton / restartButton position
- scoreSubLabel position (V3 -44 그대로)

## 합격 기준

### §4-D-4 Phase D 기능 기준
- 위 묶음 5단 각 행간 ≥ 24pt 시각 호흡
- 위 묶음 마지막(score) ↔ 아래 묶음 첫(divider) gap ≥ 60pt
- ResultScene init 시그니처 byte-identical
- DiplomaOverlayNode / sparkle 5발 / heavy 햅틱 / NewMail 사운드 발화 시점 byte-identical
- 2단계 탭 정책 byte-identical
- "기록 보기" / "공유" / "다시 시작" 3 버튼 hit-test 회귀 0

### §9 가중 (≥ 7.5)
| 카테고리 | 가중치 | 통과선 |
|---|---|---|
| 게임 로직 회귀 0 | 40% | 9.0 |
| Swift 패턴 | 20% | 7.0 |
| 비주얼 일관성 | 25% | 7.0 |
| 가독성 & UX | 15% | 7.0 |

### Verify grep
```bash
git diff ResultScene.swift | grep -E "init\(|finalScore: Int|bestScore: Int"     # 빈
git diff | grep -E "class func newResultScene"                                   # 빈
git diff | grep -E 'scoreLabel\.text\s*=\s*"\\\('                                # 빈
git diff | grep -E "bestLabel\.alpha\s*=\s*0"                                    # 빈
git diff | grep -E "DiplomaOverlayNode\.present"                                 # 빈
git diff | grep -E "haptics\.heavy|comboMilestoneStrong|emitSparkleBurst"        # 빈
git diff | grep -E "touchesBegan|isTransitioning|scoreboardButton"               # 빈
```

## 호흡 검증 (V4 시각 gap)
| 위 행 | 아래 행 | y 차이 |
|---|---|---|
| accentLine(+178) | headerChip(+145) | 33pt ≥ 28pt ✓ |
| headerChip(+145) | title via headerChip(+100) | 45pt ✓ |
| (effective title) | subtitleLabel(+64) | 36pt ≥ 32pt ✓ |
| subtitleLabel(+64) | scoreLabel(+6) | 58pt - 폰트반 ≈ 26pt ≥ 24pt ✓ |
| **scoreLabel(+6)** | **divider(-68)** | **74pt ≥ 60pt** ✓ (위/아래 묶음 분리) |
| divider(-68) | statValue(-96) | 28pt |
| statValue(-96) | statTitle(-110) | 14pt (V3 pitch 보존) |

## 주의사항

1. **scoreLabel 부작용 차단**: scoreLabel을 V4(+6)로 옮길 때 scoreNoteIcon/bestPill도 *같은 row*로 동시 이동. 안 그러면 score row가 깨짐.
2. **stat 좌표 상대식**: `divider V4 - statGap V9` 패턴으로 의도 명시. V3 절대값(-98)은 보존.
3. **titleLabel은 V4 미적용**: alpha=0 라벨, headerChip이 시각 담당. V2 그대로.
4. **buttonY 보존**: safeArea 기준이라 V4 영향 0. 3 버튼 라인 0줄.
5. **DiplomaOverlay/sparkle/heavy/NewMail 발화 시점**: 본문 0줄 변경. layoutLabels 외 코드는 byte-identical.
6. **시뮬레이터 실측 우선** (§10): 위 묶음 ≥ 24pt + score↔divider ≥ 60pt 직접 측정.
7. **회귀 위험 최소화**: GameConfig +12줄 / ResultScene ~9줄, 총 ~21줄.
