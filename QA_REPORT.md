# QA 검수 보고서 — Sprint 9 Phase D · Result V4 Spacing

## SPEC 기능 검증

- **[PASS] 기능 1**: GameConfig V4 상수 7건 신설 (`GameConfig.swift:2501-2513`)
  - `resultHeaderChipOffsetYV4 = 145`, `resultAccentLineOffsetYV4 = 178`, `resultTitleOffsetYV4 = 100`, `resultSubtitleOffsetYV4 = 64`, `resultScoreOffsetYV4 = 6`, `resultDividerOffsetYV4 = -68`, `resultStatGapFromDividerV9 = 28`
  - 위치: Phase C V9 직후 sub-MARK 적합. 의도 주석 명시.

- **[PASS] 기능 2**: `layoutLabels()` V3/V2 → V4 치환 9건 (`ResultScene.swift:540-629`)
  - scoreLabel/accentLine/headerChip/subtitle/divider/playsValue/playsTitle/totalValue/totalTitle/scoreNoteIcon/bestPill 모두 정확 치환
  - stat 좌표 상대식: `let statValueY = resultDividerOffsetYV4 - resultStatGapFromDividerV9` 패턴 도입

- **[PASS] V4 미적용 라인 보존**: titleLabel(V2)/bestLabel(V2)/scoreSubLabel(V3 -44)/newBestLabel/buttonY/3 버튼 좌표 모두 그대로

## 빌드 검증
- **BUILD SUCCEEDED** (iPhone 17 Pro Simulator)
- Swift 컴파일 에러 0건, 신규 경고 0건

## 호흡 산술 검증 (V4 시각 gap)
| 위 행 | 아래 행 | y 차이 | 합격 |
|---|---|---|---|
| accentLine(+178) | headerChip(+145) | **33pt** | ✓ |
| headerChip(+145) | title via header(+100) | **45pt** | ✓ |
| (effective title) | subtitleLabel(+64) | **36pt** | ✓ |
| subtitleLabel(+64) | scoreLabel(+6) | **58pt** | ✓ ≥ 24pt |
| **scoreLabel(+6)** | **divider(-68)** | **74pt** | ✓ **≥ 60pt 위/아래 묶음 분리** |
| divider(-68) | statValue(-96) | 28pt | (statGap V9) |
| statValue(-96) | statTitle(-110) | 14pt | (V3 pitch 보존) |

§4-D-4 합격 기준 6항목 모두 충족.

## 보호 영역 검증 (§6 변경 금지 — grep 0줄)
| 패턴 | 결과 |
|---|---|
| init( / finalScore: Int / bestScore: Int (ResultScene) | 0줄 ✓ |
| class func newResultScene | 0줄 ✓ |
| scoreLabel.text = | 0줄 ✓ |
| bestLabel.alpha = 0 | 0줄 ✓ |
| DiplomaOverlayNode.present | 0줄 ✓ |
| haptics.heavy / comboMilestoneStrong / emitSparkleBurst | 0줄 ✓ |
| touchesBegan / isTransitioning / scoreboardButton | 0줄 ✓ |

Phase A/B/C V9 30종 회귀 0, V3/V2 상수 값 전부 보존.

## 검수 결과 요약
| 등급 | 건수 |
|---|---|
| P0 치명 | 0 |
| P1 중요 | 0 |
| P2 권장 | 0 |

## 통과 항목
- 빌드 클린
- 9건 치환 정밀도 1:1 일치
- 상대식 도입(`divider V4 - statGap V9`) — 의도 코드화 모범
- comment hygiene — score row 코멘트 동기화
- 사이드이펙트 차단 — scoreLabel/scoreNoteIcon/bestPill 동일 V4 row
- Swift 패턴: 강제 언래핑 0, optional chaining 보존, MARK 섹션 추가

## 채점
| 카테고리 | 가중치 | 점수 | 통과선 |
|---|---|---|---|
| 게임 로직 회귀 0 | 40% | **10.0** | 9.0 ✓ |
| Swift 패턴 | 20% | **9.5** | 7.0 ✓ |
| 비주얼 일관성 | 25% | **10.0** | 7.0 ✓ |
| 가독성 & UX | 15% | **9.5** | 7.0 ✓ |

**가중 평균**: 10.0×0.40 + 9.5×0.20 + 10.0×0.25 + 9.5×0.15 = 4.00 + 1.90 + 2.50 + 1.425 = **9.83/10**

## 최종 판정: ✅ 합격

Sprint 9 Phase D는 SPEC 9건 치환 정밀 적용 + V4 7건 신설 + 위/아래 묶음 분리(score↔divider 74pt) + 보호 영역 전부 byte-identical. 빌드 클린. 1회 합격.
