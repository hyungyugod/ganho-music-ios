# QA 검수 보고서 — Phase 2-5 (콤보 시스템 + 점수 ×2)

**대상 작업물**: 수정 3 파일 (GameConfig 콤보 상수 4개, HUDNode 콤보 라벨 + update 시그니처 확장, GameScene combo/lastCollectAt + update 만료 검사 + didBegin 점수 분기 + endGame 인자 확장)
**검수 일시**: 2026-05-06
**검수 범위**: Sprint 2-5 (SPEC.md), 회귀 보존 10 파일

---

## 1. SPEC 기능 검증 (1~5)

| # | 기능 | 위치 | 결과 |
|---|---|---|---|
| 1 | 콤보 카운터 + 윈도우 만료 | `GameScene.swift:28-29` (Properties), `:209-212` (만료 검사) | **PASS** — `combo > 0` 가드로 `lastCollectAt = 0` 안전. 위치도 카운트다운(L204-207) 다음, player 갱신(L215) 전 — SPEC 명세 정확 |
| 2 | didBegin 콤보 갱신 + 점수 분기 | `GameScene.swift:284-291` | **PASS** — `let now = lastUpdateTime` 재활용(신규 시점 변수 0건), 6줄 갱신 + `note.run(.removeFromParent())` 마지막. 삼항 들여쓰기 정렬 정확 |
| 3 | HUDNode 콤보 라벨 (조건부 표시) | `HUDNode.swift:19, 25, 29, 33, 36, 50-51` | **PASS** — comboLabel 추가 5지점 + update 갱신 2줄. `alpha = combo >= 2 ? GameConfig.hudAlpha : 0` 정확. `configure(_:)` 헬퍼 본문 0 변경 |
| 4 | GameConfig 콤보 상수 4개 | `GameConfig.swift:72-80` | **PASS** — 새 MARK 섹션 + 4 상수(2.5/3/1/2). 기존 다른 섹션 0 변경 |
| 5 | endGame HUD 인자 확장 + 콤보 라벨 비활성화 | `GameScene.swift:302` | **PASS** — `hud.update(score: score, remainingTime: 0, combo: 0)`. 다른 4줄(L298-301) 그대로 유지 |

**판정**: 5/5 모두 충족.

---

## 2. 빌드 검증

```
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
           -scheme "GanhoMusic iOS" \
           -destination 'platform=iOS Simulator,name=iPhone 17' \
           -configuration Debug build
→ ** BUILD SUCCEEDED **
```

- 컴파일 에러 0건, 변경 영역 경고 0건

---

## 3. P0 룰 검증 (모두 0건 위반)

| 룰 | 결과 | 비고 |
|---|---|---|
| 강제 언래핑 `!` (fatalError 면제) | **0건** | grep 결과 비어 있음. `init?(coder:)` 의 `fatalError`만 면제 |
| `Timer.` / `DispatchQueue.` / `print(` / `as!` / `fileprivate` | **0건** | 3 파일 grep |
| `update(_:)` 안 `addChild()` | **0건** | 콤보 라벨 addChild는 `HUDNode.swift:36` (init 안) |
| 매직 넘버 (2.5/3/1/2) | **0건** | 모두 `GameConfig.{comboWindow, comboBonusThreshold, scorePerNote, scorePerNoteCombo}` |
| Optional 회피 (`lastCollectAt: TimeInterval = 0` + `combo > 0` 가드) | **준수** | `GameScene.swift:29` 초기값, L210/L285 가드 |
| 콤보 만료 검사 위치 (카운트다운 다음, player 갱신 전) | **준수** | L209-212 (카운트다운 L204-207 직후, player 위임 L215 직전) |
| `lastUpdateTime` 재활용 (didBegin 새 시점 변수 0) | **준수** | `let now = lastUpdateTime` (L284) |
| 콤보 라벨 alpha 분기 (`combo >= 2 ? hudAlpha : 0`) | **준수** | `HUDNode.swift:51` |
| `hud.update` 시그니처 확장 호출처 2곳 (`combo:` 인자) | **준수** | `GameScene.swift:224` (update), `:302` (endGame) |
| `configure(_:)` 헬퍼 본문 0 변경 | **준수** | `HUDNode.swift:56-63` 본문 그대로 |

---

## 4. 식별자 등장 횟수 검증

| 식별자 | 합계 | SPEC 요구 | 결과 |
|---|---|---|---|
| `combo` | 19 (GameConfig 2 + HUDNode 8 + GameScene 9) | ≥ 6 | ✅ PASS |
| `comboWindow` | 3 (정의 1 + 사용 2) | ≥ 2 | ✅ PASS |
| `comboBonusThreshold` | 2 (정의 1 + 사용 1) | 1 | ✅ PASS |
| `scorePerNote` | 2 (정의 1 + 사용 1) | 1 | ✅ PASS |
| `scorePerNoteCombo` | 2 (정의 1 + 사용 1) | 1 | ✅ PASS |

---

## 5. HUDNode 회귀 보존 (기존 두 라벨 0 변경)

| 항목 | 결과 |
|---|---|
| `scoreLabel` 위치 (`x: 0, y: 0`) | `HUDNode.swift:31` — 그대로 |
| `timeLabel` 위치 (`y: -hudFontSize * 1.4`) | `HUDNode.swift:32` — 그대로 |
| `scoreLabel.text = "🎵 \(score)"` | `HUDNode.swift:47` — 그대로 |
| `timeLabel.text = String(format: "⏱ 00:%02d", seconds)` | `HUDNode.swift:49` — 그대로 |
| `configure(_:)` 헬퍼 본문 (fontSize/fontColor/alpha/alignment/zPosition) | `HUDNode.swift:56-63` — 6줄 0 변경 |

---

## 6. 회귀 보존 — 10 파일 mtime (변경 0건)

| 파일 | mtime | 결과 |
|---|---|---|
| `Nodes/PlayerNode.swift` | 1778048094 | ✅ 보존 |
| `Nodes/DPadNode.swift` | 1778033228 | ✅ 보존 |
| `Nodes/NoteNode.swift` | 1778048078 | ✅ 보존 |
| `Config/PhysicsCategory.swift` | 1777879822 | ✅ 보존 |
| `Config/GameState.swift` | 1777879818 | ✅ 보존 |
| `Config/ColorTokens.swift` | 1777879830 | ✅ 보존 |
| `iOS/AppDelegate.swift` | 1777725506 | ✅ 보존 |
| `iOS/SceneDelegate.swift` | 1777863711 | ✅ 보존 |
| `iOS/GameViewController.swift` | 1777798214 | ✅ 보존 |
| `xcodeproj/project.pbxproj` | 1778050863 | ✅ 보존 |

**회귀 보존 결과: 10 / 10**

---

## 7. 신설 파일 0 정책 준수

- 신설 Swift/리소스 파일: 0건 (Generator가 신설 안 함)
- `project.pbxproj` mtime 변경: 0 (1778050863 그대로)
- Xcode 멤버십 trigger: 발생 안 함
- **판정**: 정책 준수 (가장 *작은 변경 단위*로 큰 게임플레이 진화)

---

## 8. P1/P2 감점 사항

**없음.** 변경 영역 모든 패턴 (네이밍, MARK, 옵셔널 처리, 매직 넘버, 함수 단일 책임, dt 기반 이동, weak self, 충돌 후 즉시 삭제 회피) 룰북 정합.

---

## 9. 통과 항목 요약

- 강제 언래핑 / Timer / print / as! / fileprivate / DispatchQueue 모두 0건
- `update(_:)` 안 `addChild()` 0건
- `guard let note = noteBody?.node else { return }` 유지
- MARK 섹션 일관성 (`// MARK: - Combo (Phase 2-5)` 신규 섹션 + 기존 함수 단위 MARK 0 변경)
- GameConfig 상수 추출 (2.5/3/1/2 매직 넘버 0건)
- weak self 캡처 (`startSpawnLoop` 의 `[weak self]` 그대로)
- SKAction 패턴 (Timer 미사용, `repeatForever` 그대로)
- HUD 노드 분리 (cameraNode 자식 구조 유지)
- 콤보 라벨 alpha 분기 (isHidden 토글 회피로 트리 갱신 비용 0)
- ganhoPaper / ganhoBgDeep 팔레트 그대로 — 톤·카피 변경 0

---

## 10. 채점

| 항목 | 점수 | 코멘트 |
|---|---|---|
| Swift 패턴 일관성 (35%) | **9.5 / 10** | 강제 언래핑 0, 매직 넘버 0, MARK 일관성, guard let 유지, GameConfig 상수 4개 모두 추출. P2 수준 결함도 부재 |
| 게임 로직 완성도 (30%) | **9.5 / 10** | 콤보 만료 검사 위치 정확, didBegin 6줄 갱신 + 노드 즉시 삭제 회피, `lastUpdateTime` 재활용으로 신규 시점 변수 0. SKAction/dt/GameState 가드 모두 유지 |
| 성능 & 안정성 (20%) | **9.5 / 10** | BUILD SUCCEEDED, 컴파일 에러/경고 0. weak self 그대로. alpha 분기로 isHidden 트리 갱신 비용 회피. Optional 회피 패턴 안전 |
| 기능 완성도 (15%) | **10 / 10** | SPEC §기능 1~5 모두 구현. OUT 영역(사운드/시각 강조/Best 콤보/화캉스 보너스 등) 0건 침범. 회귀 10/10 + project.pbxproj 변경 0 |

**가중 점수 계산**:
- 0.35 × 9.5 = 3.325
- 0.30 × 9.5 = 2.850
- 0.20 × 9.5 = 1.900
- 0.15 × 10.0 = 1.500
- **합계: 9.575 / 10.0 → 9.6**

---

## 11. 최종 판정: **합격**

- 기준선 8.0 이상 통과 (**9.6**)
- P0 위반 0건, P1/P2 감점 0건, BUILD SUCCEEDED
- SPEC 5 기능 모두 구현, 회귀 10/10, 신설 파일 0 정책 준수

**개선 지시**: 없음 — Phase 2-5 SPEC을 정확히 따랐고, 별도 후속 수정 없이 머지 가능.

**다음 단계 권장**:
- Phase 2-6 (수간호사 적 + F 투사체 + endGame 재호출 패턴)
- 또는 시간 ≤10초 빨간색 강조 (작은 폴리싱 sub-feature)
