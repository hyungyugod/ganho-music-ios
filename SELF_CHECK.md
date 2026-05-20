# 자체 점검 — Sprint 9 Phase D · 결과창 V4 spacing

전략: Case A — 1회차 신규 구현. SPEC §"핵심 코드 구조" 그대로 따랐고, V3/V2 상수 값·init·발화 시점·터치 정책 byte-identical 보존.

## SPEC 기능 체크

### 기능 1: GameConfig V4 상수 7건 신설
- [x] `resultHeaderChipOffsetYV4 = 145` (V3 +115 → +30)
- [x] `resultAccentLineOffsetYV4 = 178` (V3 +148 → +30)
- [x] `resultTitleOffsetYV4 = 100` (V3 +85 → +15) — alpha=0 레거시 라벨용
- [x] `resultSubtitleOffsetYV4 = 64` (V3 +58 → +6)
- [x] `resultScoreOffsetYV4 = 6` (V2 -2 → +8)
- [x] `resultDividerOffsetYV4 = -68` (V3 -78 → +10)
- [x] `resultStatGapFromDividerV9 = 28` (divider→stat 거리)
- [x] V3 상수 7건 모두 *값 보존* (회귀 안전망)
- [x] 위치: Phase C V9 직후 `// MARK: - Sprint 9 Phase D · Result V4 Spacing`

### 기능 2: ResultScene `layoutLabels()` V3/V2 → V4 치환 9건

| # | 라벨 | AS-IS | TO-BE |
|---|---|---|---|
| 1 | scoreLabel.position.y | `resultScoreOffsetYV2` (-2) | `resultScoreOffsetYV4` (+6) |
| 2 | accentLine.position.y | `resultAccentLineOffsetYV3` (148) | `resultAccentLineOffsetYV4` (178) |
| 3 | headerChip?.position.y | `resultHeaderChipOffsetYV3` (115) | `resultHeaderChipOffsetYV4` (145) |
| 4 | subtitleLabel.position.y | `resultSubtitleOffsetYV3` (58) | `resultSubtitleOffsetYV4` (64) |
| 5 | divider.position.y | `resultDividerOffsetYV3` (-78) | `resultDividerOffsetYV4` (-68) |
| 6 | playsValueLabel.position.y | `resultStatValueOffsetYV3` (-98) | `statValueY` (= -68 - 28 = -96) |
| 6' | totalValueLabel.position.y | 동일 | 동일 |
| 7 | playsTitleLabel.position.y | `resultStatTitleOffsetYV3` (-112) | `statTitleY` (= -96 - 14 = -110) |
| 7' | totalTitleLabel.position.y | 동일 | 동일 |
| 8 | scoreNoteIconLabel.position.y | `resultScoreRowOffsetYV3` (-2) | `resultScoreOffsetYV4` (+6) — score row 동기화 |
| 9 | bestPill?.position.y | `resultScoreRowOffsetYV3` (-2) | `resultScoreOffsetYV4` (+6) — score row 동기화 |

(stat은 plays/total 2쌍이라 1줄 표시 1건, 실제 코드는 4 라인 + 2 local let)

### V4 미적용 라인 (의도)
- [x] titleLabel — V2 그대로 유지(alpha=0 라벨, headerChip이 시각 담당)
- [x] bestLabel — V2 그대로(alpha=0 정책 보존)
- [x] statsLabel / characterLabel / difficultyLabel / promptLabel / newBestLabel — 기존 그대로
- [x] scoreSubLabel — V3 `-44` 그대로
- [x] buttonY — safeArea 기준 그대로 (V4 영향 0)

## 호흡 검증 (산술 — V4 시각 gap)

| 위 행 | 아래 행 | y 차이 | 합격 ≥ 24pt? |
|---|---|---|---|
| accentLine (+178) | headerChip (+145) | 33pt | ✓ (≥ 28pt) |
| headerChip (+145) | titleLabel via header (+100) | 45pt | ✓ |
| subtitle area (+64) | subtitleLabel (+64) | — | — |
| subtitle (+64) | scoreLabel (+6) | 58pt | ✓ (≥ 24pt) |
| **scoreLabel (+6)** | **divider (-68)** | **74pt** | ✓ **≥ 60pt — 위/아래 묶음 분리 확보** |
| divider (-68) | statValue (-96) | 28pt | (statGap V9) |
| statValue (-96) | statTitle (-110) | 14pt | (V3 pitch 보존) |

scoreLabel ↔ divider gap **74pt ≥ 60pt** → SPEC §4-D-4 합격 기준 충족.

## 보호 영역 — git diff "ResultScene.swift" 스코프 grep (모두 빈 출력)

```
init( / finalScore: Int / bestScore: Int        → 빈
class func newResultScene                       → 빈
scoreLabel.text =                               → 빈
bestLabel.alpha = 0                             → 빈
DiplomaOverlayNode.present                      → 빈
haptics.heavy / comboMilestoneStrong / emitSparkleBurst → 빈
touchesBegan / isTransitioning / scoreboardButton → 빈
```

검증 명령:
```bash
git diff "GanhoMusic/GanhoMusic Shared/Scenes/ResultScene.swift" | \
  grep -E "init\(|finalScore: Int|bestScore: Int|newResultScene|scoreLabel\.text\s*=|bestLabel\.alpha\s*=\s*0|DiplomaOverlayNode\.present|haptics\.heavy|comboMilestoneStrong|emitSparkleBurst|touchesBegan|isTransitioning|scoreboardButton"
# 출력 0줄
```

## Swift 패턴 준수
- 강제 언래핑 미사용: 준수 (기존 `headerChip?` / `bestPill?` optional chaining 그대로)
- guard let 옵셔널 처리: 해당 없음 (이번 Phase는 좌표 치환만)
- MARK 섹션 구분: 준수 (`// MARK: - Sprint 9 Phase D · Result V4 Spacing`)
- GameConfig 상수 사용: 준수 (V4 7건 신규 + 매직 넘버 1개 `-14`는 V3 pitch 보존 의도 주석 명시)
- weak self 캡처: 해당 없음

## SpriteKit 패턴 준수
- didMove(to:)에서 초기화: 해당 없음 (layoutLabels는 willMove + didChangeSize 양쪽에서 호출되는 기존 패턴 보존)
- dt 기반 이동: 해당 없음
- SKAction 스폰 패턴: 해당 없음
- 충돌 후 노드 즉시 삭제 없음: 해당 없음
- HUD 노드 분리: 해당 없음 (좌표 치환만)

## 빌드 상태
- xcodebuild SUCCEEDED (iPhone 17 Pro, iOS 16.6 Simulator, Debug)
- 예상 빌드 에러: 없음
- 주의 필요 경고: 없음

## 범위 외 미구현 항목
- 없음 — SPEC §4-D-4 합격 기준 6항목 모두 충족.

## 산출물
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift` — +18 라인 (Phase D V4 7건 + sub-MARK + 4줄 의도 주석)
- `GanhoMusic/GanhoMusic Shared/Scenes/ResultScene.swift` — layoutLabels() 안 9건 치환 + 2 local let + 2 comment update. 총 변경 행 ~21줄. **layoutLabels 외 본문 0줄 변경**.
- `docs/learn/sprint-9-phase-d-result-spacing.md` — 학습 노트(중학생 수준).
