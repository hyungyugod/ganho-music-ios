# QA 검수 보고서 — Phase 2-12 ScoreSystem 분리

## SPEC 기능 검증

### 신설 / 수정 / 등록
- [PASS] **신설** `Systems/ScoreSystem.swift` (48줄, `final class`, `import Foundation`)
- [PASS] **수정** `GanhoMusic Shared/GameScene.swift` (315줄, SELF_CHECK 보고치와 일치)
- [PASS] **등록** `project.pbxproj` 4지점 — PBXBuildFile(L22) / PBXFileReference(L38) / Systems group children(L180) / Sources build phase(L362) 모두 확인

### SPEC §"준수 룰" 15개 검증

| # | 룰 | 결과 | 근거 |
|---|---|---|---|
| 1 | ScoreSystem.swift 신설 + final class | PASS | `ScoreSystem.swift:12` `final class ScoreSystem` |
| 2 | private(set) score / combo + private lastCollectAt | PASS | `:16` `private(set) var score`, `:18` `private(set) var combo`, `:20` `private var lastCollectAt` |
| 3 | recordNoteHit(at:) 메서드 | PASS | `:25` `func recordNoteHit(at now: TimeInterval)` |
| 4 | tickComboExpiry(currentTime:) 메서드 | PASS | `:36` `func tickComboExpiry(currentTime: TimeInterval)` |
| 5 | reset() 메서드 | PASS | `:43` `func reset()` |
| 6 | GameScene 멤버 3개 제거 | PASS | `grep -E "private var (score\|combo\|lastCollectAt)"` → 0건 |
| 7 | `private let scoreSystem = ScoreSystem()` 추가 | PASS | `GameScene.swift:43` |
| 8 | update에서 tickComboExpiry 호출 1건 | PASS | `:261` 정확히 1건 |
| 9 | onNoteCollected 콜백이 3줄로 단순화 | PASS | `:296~300` `[weak self]` + `guard let self` + `recordNoteHit(at:)` + `note.run(.removeFromParent())` (본문 3실행 라인) |
| 10 | hud.update에 scoreSystem.score / scoreSystem.combo 사용 | PASS | `:279` (update 루프), `:313` (endGame) |
| 11 | endGame의 hud.update에 `combo: 0` 인자 그대로 | PASS | `:313` `hud.update(score: scoreSystem.score, remainingTime: 0, combo: 0)` 시각 강제 0 유지 |
| 12 | 매직 넘버 0건 | PASS | ScoreSystem 산식 상수 모두 GameConfig 참조 (`comboWindow`, `comboBonusThreshold`, `scorePerNote`, `scorePerNoteCombo`); `0`/`1` 리터럴은 콤보 가드/증가 sentinel — 원본 산식과 동일 |
| 13 | 강제 언래핑 / Timer / print / as! / fileprivate / DispatchQueue 0건 | PASS | grep 0건 (ScoreSystem.swift 및 GameScene.swift 변경부) |
| 14 | pbxproj ScoreSystem 등록 4지점 | PASS | grep 정확히 4건 |
| 15 | BUILD SUCCEEDED | PASS | 아래 §빌드 검증 참조 |

### 핵심 동등성 검증 (Line-by-line)

#### 콤보 산식 (recordNoteHit vs 기존 onNoteCollected)
원본 (`HEAD:GameScene.swift:300-308`):
```
guard let self = self else { return }
let now = self.lastUpdateTime
let isInWindow = self.combo > 0 && now - self.lastCollectAt < GameConfig.comboWindow
self.combo = isInWindow ? self.combo + 1 : 1
self.score += self.combo >= GameConfig.comboBonusThreshold
    ? GameConfig.scorePerNoteCombo
    : GameConfig.scorePerNote
self.lastCollectAt = now
```
신규 `ScoreSystem.recordNoteHit(at: now)` (`:25-32`):
```
let isInWindow = combo > 0 && now - lastCollectAt < GameConfig.comboWindow
combo = isInWindow ? combo + 1 : 1
score += combo >= GameConfig.comboBonusThreshold
    ? GameConfig.scorePerNoteCombo
    : GameConfig.scorePerNote
lastCollectAt = now
```
**판정**: `self.` 프리픽스 제거 외 *완전 동일*. `now`는 호출처에서 `self.lastUpdateTime` 그대로 주입 (`GameScene.swift:298`).

#### 콤보 만료 (tickComboExpiry vs 기존 update 가드)
원본 (`HEAD:GameScene.swift:262-264`):
```
if combo > 0, currentTime - lastCollectAt > GameConfig.comboWindow {
    combo = 0
}
```
신규 `ScoreSystem.tickComboExpiry(currentTime:)` (`:37-39`):
```
if combo > 0, currentTime - lastCollectAt > GameConfig.comboWindow {
    combo = 0
}
```
**판정**: 라인별 *완전 동일*.

#### endGame `combo: 0` 시각 강제 0 유지
- `GameScene.swift:313` `hud.update(score: scoreSystem.score, remainingTime: 0, combo: 0)` — combo 인자 리터럴 0 유지. 실제 scoreSystem.combo는 보존, 표시만 0. SPEC §"기능 동등성" 요구 충족.

### 회귀 보존 (git diff --stat 검증)

```
GanhoMusic Shared/GameScene.swift     | 27 +--
GanhoMusic.xcodeproj/project.pbxproj  |  4 +
SELF_CHECK.md / SPEC.md / QA_REPORT.md (산출물)
```

- [PASS] **Config 4 파일** 변경 0
- [PASS] **Nodes 6 파일** 변경 0 (HUDNode 시그니처 `update(score:remainingTime:combo:)` 그대로)
- [PASS] **Systems/SpawnSystem.swift, ContactRouter.swift** 변경 0
- [PASS] **iOS 3 파일** 변경 0
- [PASS] **GameScene setup* / didChangeSize / endGame** (HUD 라인 외) 그대로

---

## 빌드 검증

- **명령**: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' build`
- **결과**: ✅ **BUILD SUCCEEDED**
- **에러**: 0건
- **경고**: 0건 (`grep -E "warning:|error:"` → 무출력)
- **비고**: SDK iPhoneSimulator26.4, Xcode 26.4 환경에서 클린 빌드 통과

---

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

리팩터 sprint로 SPEC 외 사항을 *건드리지 않은* 점이 명확. 추가 트집을 만들기 어려움.

---

## P0 — 치명적 이슈
없음.

## P1 — 중요 이슈
없음.

## P2 — 권장 사항
없음.

(엄격 모드로 재검토했으나 본 sprint는 *순수 리팩터*로 라인별 동등성이 검증됐고, 신규 `ScoreSystem`의 코드 품질/네이밍/주석/`MARK` 분리/`private(set)` 캡슐화 모두 표준 패턴 준수. 임의 트집은 무의미.)

---

## 통과 항목 (강조)

1. **순수 리팩터 원칙 엄수** — IN 항목(신설 1 / 수정 1 / pbxproj 1) 정확히 일치. OUT 항목 (다른 파일) 0 변경.
2. **기능 동등성** — 콤보 산식 / 만료 가드 모두 라인별 동일. 결과값 동일 보장.
3. **캡슐화 향상** — `private(set)` score / combo, `private` lastCollectAt. 외부 mutate 경로 차단.
4. **시간 출처 분리** — `recordNoteHit(at:)`이 시각을 인자로 받음 → 향후 테스트 용이.
5. **명료한 의도 표현** — `recordNoteHit` / `tickComboExpiry` 동사형 메서드명으로 책임 명시.
6. **MARK 섹션** — `// MARK: - State`, `// MARK: - Mutations` 적절.
7. **비활성 reset() 함수 사전 도입** — Phase 3 재시작 대비. dead code가 아닌 *예약된 진입점*.
8. **빌드 클린** — 경고 0건.
9. **줄 수 감소** — GameScene 324 → 315 (-9). 책임 분산 효과 정량 확인.

---

## 채점

리팩터 sprint이며 SPEC §"준수 룰" 15개 PASS, 라인별 동등성 검증, BUILD SUCCEEDED + 경고 0. 관대 점검을 한 번 더 의심했으나 이 결과는 정당.

| 항목 | 점수 | 코멘트 |
|---|---|---|
| Swift 패턴 일관성 (35%) | **9.5/10** | `final class`, `private(set)`, `MARK`, GameConfig 상수만 사용. Foundation only 임포트로 표면적 최소화. 네이밍·주석·캡슐화 표준. |
| 게임 로직 완성도 (30%) | **9.5/10** | 콤보 산식·만료 가드 라인별 동일. SpriteKit 패턴 (`SKAction`, dt 기반 update, didMove 초기화) 변경 없음. endGame `combo: 0` 시각 강제 의도 보존. |
| 성능 & 안정성 (20%) | **10/10** | 강제 언래핑 0, Timer 0, DispatchQueue 0, fileprivate 0, [weak self] 캡처 유지, ScoreSystem은 외부 참조 0 → 누수 없음. 빌드 경고 0. |
| 기능 완성도 (15%) | **10/10** | SPEC IN 정확 일치, OUT 변경 0, 회귀 영역 보존. `reset()`은 Phase 3 예약 — SPEC §주의사항 명시된 의도된 미호출. |

**가중 점수**: (9.5 × 0.35) + (9.5 × 0.30) + (10 × 0.20) + (10 × 0.15) = 3.325 + 2.85 + 2.00 + 1.50 = **9.675 / 10.0**

## 최종 판정: **합격**

순수 리팩터 sprint로서 *기능 동등성*이 결정적이며, 라인별 동등성 검증 + BUILD SUCCEEDED + 회귀 0 + P0/P1/P2 0건 요건을 모두 충족.

**구체적 개선 지시**: 없음. 다음 Phase(2-13 또는 Phase 3 재시작)로 진행 가능.

(부수적 메모 — 향후 sprint에서 활용 가능한 *선택지*, 본 sprint 감점 사유 아님:
- Phase 3에서 reset()을 실제 사용하는 시점에 단위테스트 도입을 고려할 수 있음. ScoreSystem이 시간 의존성을 매개변수로 분리해둔 덕에 테스트가 매우 쉬움.)
