# QA 검수 보고서 — Phase 6-13 게임 시작 카운트다운 (3→2→1→GO!) · 자가 소멸 노드 8호

## SPEC 기능 검증

- **[PASS] 기능 1 — GameState `.countdown` case 추가**
  - `Config/GameState.swift:14` — `case countdown` 추가. 위치는 `.waiting` 다음, `.playing` 직전 (의미 순서 자연).
  - 주석으로 "update의 모든 시스템 정지" 의도 명시. 헤더에 Phase 6-13 표기.
- **[PASS] 기능 2 — GameConfig 카운트다운 상수 8개**
  - `Config/GameConfig.swift:339-356` — `// MARK: - Countdown (Phase 6-13)` 섹션 신설.
  - 8개 상수: `countdownFontSize(96)` / `FadeInDuration(0.1)` / `HoldDuration(0.7)` / `FadeOutDuration(0.2)` / `GoEndScale(1.3)` / `GoFadeOutDuration(0.4)` / `GoHoldDuration(0.5)` / `ZPosition(250)` 전부 존재. SPEC 명시 값과 일치.
- **[PASS] 기능 3 — CountdownNode 신규 (자가 소멸 노드 8호)**
  - `Nodes/CountdownNode.swift:20` — `final class CountdownNode: SKNode, SelfDismissingNode` 채택.
  - `start(onTick:onGo:onComplete:)` 진입점 1개 (line 50–62).
  - SKAction.sequence 6단계: `[step3, step2, step1, stepGo, cleanup, notify]` (cleanup = removeFromParent, notify = onComplete).
  - **onComplete가 removeFromParent 다음 위치** — 노드가 이미 트리에서 빠진 상태에서 GameScene 시동 보장 (SPEC 명시 시각 잔상 0 의도 반영).
  - 일반 단계 `stepAction`은 fadeIn(0.1) → hold(0.7) → fadeOut(0.2) — 1.0초/단계.
  - GO! 단계 `goAction`은 fadeIn(0.1) → group(hold(0.5) + scaleUp(0.5)) → fadeOut(0.4) — 1.0초.
- **[PASS] 기능 4 — GameScene 흐름 재구성**
  - `GameScene.swift:127-133` — didMove 끝부분에 `gameState = .countdown` + `showCountdown()` 2줄.
  - `GameScene.swift:166-180` — `startGameProperly()` 신규. **기존 didMove 끝 14줄(spawnSystem.start 인자 5개 + gameState=.playing + bgm.play)을 byte-identical 이동.**
  - git diff 확인: 인자 이름·순서·내용·`[weak self]` 캡처 전부 동일.
  - `showCountdown` 콜백 3개 모두 `[weak self]` 캡처. `onGo`만 `guard let self` 패턴 (두 줄 호출 일관성), 단발 콜백은 옵셔널 체이닝.

## 빌드 검증

- **명령**: `xcodebuild -project GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- **결과**: `** BUILD SUCCEEDED **`
- **에러**: 0건
- **경고**: 0건
- **소요**: 정상 완료

## 추가 안전성 검증

### 1. GameState exhaustive switch 안전성
- `grep -rn "switch.*gameState\|switch gameState"` → **0 hits**. exhaustive switch 부재.
- `gameState ==` / `gameState !=` 동등성 비교만 사용 — `.countdown` 추가는 모든 비교가 false 반환하는 안전 확장.
- 자동 차단 의도 그대로 적용됨: `.countdown` 상태에서 `gameState == .playing` → false → update 본문 7개 시스템(타이머/콤보만료/플레이어이동/카메라follow/적추적/HUD갱신/콤보끊김폴링) 동시 정지.

### 2. update() 본문 미수정 확인
- `GameScene.swift:221` — `guard gameState == .playing else { return }` 한 줄 변경 0.
- update 본문 어디도 새 가드/분기 추가 0줄.

### 3. CountdownNode 패턴 검증
- `[weak self]` 캡처: `stepAction` setup (line 72) + `goAction` setup (line 91) 모두 `guard let self = self else { return }` 패턴.
- 외부 콜백(`onTick`/`onGo`/`onComplete`)은 그대로 호출만 — 외부에서 capture 책임. 적절한 책임 분리.
- 강제 언래핑 0건. 매직 넘버 0건 (모두 GameConfig 참조).
- MARK 섹션 5개: Properties / Init / Start / Step Actions / Configure.

### 4. pbxproj UUID 0033 4지점 등록
- `PBXBuildFile`: line 44 — `A1C0F1B00000000000000033`
- `PBXFileReference`: line 82 — `A1C0F1A00000000000000033`
- `PBXGroup` (Nodes): line 226
- `PBXSourcesBuildPhase`: line 498
- UUID 0032(ComboBreakNode) 패턴 일관 답습.

### 5. 회귀 0 영역 미접촉
- git status diff 확인 결과 변경 파일은 정확히 5개: `CountdownNode.swift`(신규) + `GameState.swift` + `GameConfig.swift` + `GameScene.swift` + `project.pbxproj`.
- AudioManager.swift / ColorTokens.swift / SelfDismissingNode.swift / ComboBreakNode.swift / ComboPopupNode.swift / BGMPlayer / SpawnSystem / HapticsManager / 나머지 Nodes 전부 미수정 — diff 0줄.
- AudioManager.SFX 신규 케이스 0건 — `comboMilestoneStrong` 재사용 (line 153).
- ColorTokens 신규 색 0건 — 4색(`.ganhoBloodAccent`/`.ganhoYellowF`/`.ganhoPinkNote`/`.ganhoMint`) 재사용.

### 6. ColorTokens 4색 존재 확인
- `.ganhoBloodAccent` (line 40) ✓
- `.ganhoYellowF` (line 45) ✓
- `.ganhoPinkNote` (line 30) ✓
- `.ganhoMint` (line 26) ✓
- 대체 발생 0건. SPEC §"핵심 결정 4" 의도 그대로 적용.

### 7. Timer / DispatchQueue / 강제 언래핑 검사
- `Timer.` / `DispatchQueue.` 사용 — 변경 4개 파일에서 0건.
- 강제 언래핑(`x!.y` 패턴) — CountdownNode / GameScene 변경부에서 0건. (검색 hits는 모두 `GO!` 문자열 또는 한국어 주석.)

---

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | **0건** |
| P1 중요 | **0건** |
| P2 권장 | 1건 |

## P0 — 치명적 이슈

없음.

## P1 — 중요 이슈

없음.

## P2 — 권장 사항

### 1. GameScene.swift 파일 길이 444줄
- **파일**: `GanhoMusic Shared/GameScene.swift` (444줄)
- **위반 규칙**: spritekit-rules.md §11 — 단일 씬 파일은 300줄 미만 권장.
- **현재 상황**: Phase 6-13 변경 자체는 +37줄로 *최소*. 본 누적은 6-1 ~ 6-12 sprint들이 GameScene에 누적시킨 결과 (이미 6-12 종료 시점 ~407줄). SPEC §"변경 범위"에서 +25줄 예상한 대로 진행.
- **수정 제안**: 본 sprint에서 처리할 사항 아님 — 별도 리팩터 sprint(예: 7-R)에서 Countdown 로직을 `Systems/CountdownCoordinator.swift`로 추출, 또는 콤보 마일스톤/콤보 끊김 피드백을 `Systems/ComboFeedbackSystem.swift`로 분리하는 방향. 본 sprint 범위 계약에 *허용*되지 않은 변경이므로 *권장만*.
- **점수 영향**: Swift 패턴 -0.3점 정도. 본 sprint 책임 아니므로 가벼운 P2.

## 통과 항목 (요약)

- **빌드**: BUILD SUCCEEDED, 경고/에러 0건.
- **SPEC 4개 기능**: 모두 PASS.
- **회귀 0 영역**: AudioManager / ColorTokens / 자가 소멸 노드 7개 / BGMPlayer / SpawnSystem / ScoreSystem / ContactRouter / HUDNode / PlayerNode / EnemyNode / DPadNode / TitleScene / ResultScene / HapticsManager 전부 미접촉 확인 (diff 0).
- **`update()` 자동 차단 안전망**: `guard gameState == .playing` 한 줄로 7개 시스템 자동 정지 — 추가 가드 코드 0줄로 SPEC §"핵심 통찰" 그대로 구현.
- **CountdownNode 멱등성**: 단일 SKAction.sequence가 4단계 + cleanup + notify 직렬 진행. removeFromParent → onComplete 순서로 시각 잔상 0 보장.
- **시그니처 그대로 이동**: `spawnSystem.start(scene:world:player:enemy:progressProvider:)` 인자 5개 + `progressProvider` 클로저 `[weak self]` 캡처까지 byte-identical 이동.
- **GameState 안전한 enum 확장**: exhaustive switch 0건 → `.countdown` 추가로 break되는 컴파일 지점 0건.
- **콜백 캡처 일관성**: showCountdown 클로저 3개 모두 `[weak self]`. `onGo`는 두 줄 호출이라 `guard let self`, 단발은 옵셔널 체이닝 — Swift 관용구 자연.

---

## 채점

**항목별 점수**:
- Swift 패턴 일관성: **9.7/10** → CountdownNode/GameScene 신규 코드 강제 언래핑 0, 매직 넘버 0, MARK 5개 구분, `[weak self]` 캡처 일관. 444줄 GameScene 누적은 본 sprint 외 부담 (-0.3).
- 게임 로직 완성도: **10/10** → `.countdown` enum 추가만으로 7개 시스템 자동 차단. update 본문 0줄 수정. byte-identical 이동으로 회귀 0. 자가 소멸 노드 8호 패턴 정확히 답습.
- 성능 & 안정성: **10/10** → 빌드 클린(0 warning), 강제 언래핑 0, `[weak self]` 캡처 일관, Timer 0, fire-and-forget 패턴 그대로. SKAction.sequence 직렬 보장.
- 기능 완성도: **10/10** → SPEC 4개 기능 모두 명시한 위치·값·구조 그대로 구현. 금지 항목(스킵/다국어/ColorTokens 추가/SFX 추가) 미구현.

**가중 점수**: `(9.7 × 0.35) + (10 × 0.30) + (10 × 0.20) + (10 × 0.15)` = `3.395 + 3.0 + 2.0 + 1.5` = **9.895 / 10.0** ≈ **9.9/10**

## 최종 판정: **합격**

**구체적 개선 지시**: 없음 (P0/P1 0건). P2의 GameScene 파일 길이는 본 sprint 범위 외 누적 부담이므로 별도 리팩터 sprint에서 처리 권장.

**총평**: SPEC §"핵심 통찰"의 "`guard gameState == .playing` 한 줄이 자동으로 7개 시스템을 차단한다 — 추가 가드 코드 한 줄도 안 쓴다"를 *문자 그대로* 구현했다. enum case 1개 + 신규 노드 1개 + GameScene 47줄 추가(중 14줄은 *기존 코드 이동*)로 게임 시작 흐름 재설계를 달성했고, 회귀 0 영역 14개 카테고리 모두 미접촉. 빌드 통과 + 경고 0건. 자가 소멸 노드 패턴 8회차 답습 정확. 본 sprint는 *완성도 높은 합격*.
