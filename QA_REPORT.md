# QA 검수 보고서 — Phase 4-6 (E) 수간호사 5초 도주 모드

## SPEC 기능 검증

- [PASS] **기능 1** `var isFleeing: Bool = false` — `EnemyNode.swift:19`, `// MARK: - State` 섹션 신설 (Init 위)
- [PASS] **기능 2** `func startFleeing(duration:)` — `EnemyNode.swift:56~62`, `// MARK: - Flee` 섹션 신설, 첫 줄 `if isFleeing { return }` 재호출 가드, 두 `SKAction.run` 모두 `[weak self]`
- [PASS] **기능 3** `update` 방향 분기 — `EnemyNode.swift:86` `let direction: CGFloat = isFleeing ? -1 : 1`, `:88` `dx: unitX * speed * direction`, `:89` `dy: unitY * speed * direction`. `magnitude == 0` 가드 *바깥*, `let speed = ...` *다음* — SPEC §기능 3 위치 정확 일치.
- [PASS] **기능 4** EnemyNode 헤더 — `:6` "Phase 4-6 · 5초 도주 모드 추가 (isFleeing + startFleeing + update 방향 분기)" 1줄 추가, 기존 Phase 2-6 헤더(line 5) 보존.
- [PASS] **기능 5** `enemyFleeDuration` — `GameConfig.swift:219`, Airforce Easter Egg 섹션 *끝*(`bombFlashFadeOutDuration` 다음), doc 2줄(:217-218) 포함.
- [PASS] **기능 6** trigger 1줄 — `GameScene.swift:214` 본문 *마지막*, `enemy.startFleeing(duration: GameConfig.enemyFleeDuration)`. 기존 본문 10줄(BombFlashNode 발화까지)은 한 줄도 변경 없음.
- [PASS] **기능 7** GameScene 헤더/doc — `:27` 헤더 MARK 1줄, `:200` trigger doc 1줄.

## 빌드 검증

- **결과**: BUILD SUCCEEDED
- **destination**: `platform=iOS Simulator,name=iPhone 17` (iPhone 15 환경 부재 — iPhone 17로 대체, OS 26.4.1, arm64)
- **컴파일 에러**: 0
- **경고**: 0 (`grep -iE "warning:|error:"` 결과 비어 있음; appintentsmetadataprocessor의 SDK 노트만 출력, 본 변경 무관)

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## 회귀 검증 (모든 OoS 0줄 변경)

| 대상 | git diff | 결과 |
|---|---|---|
| `Nodes/AirplaneNode.swift` | 0 | PASS |
| `Nodes/AirforceOverlayNode.swift` | 0 | PASS |
| `Nodes/BombFlashNode.swift` | 0 | PASS |
| `Systems/ContactRouter.swift` | 0 | PASS |
| `Config/PhysicsCategory.swift` | 0 | PASS |
| `Nodes/StoneGuardNode.swift` | 0 | PASS |
| `GameScene+Setup.swift` | 0 | PASS |
| 기존 `GameConfig` 상수 (airplane 4 + airforceOverlay 3 + bombFlash 3) | 0 | PASS (1줄 추가 *만*) |
| 기존 `triggerAirforceEasterEgg` 본문 10줄 | 0 | PASS (마지막에 1줄 *추가*) |
| `Nodes/PlayerNode.swift` | 0 | PASS |
| `Nodes/NoteNode.swift` | 0 | PASS |
| `Nodes/ProjectileNode.swift` | 0 | PASS |
| `Nodes/HUDNode.swift` | 0 | PASS |
| `Nodes/DPadNode.swift` | 0 | PASS |
| `Scenes/TitleScene.swift` | 0 | PASS |
| `Scenes/ResultScene.swift` | 0 | PASS |
| `Config/ColorTokens.swift` | 0 | PASS |
| `GanhoMusic macOS/*` | 0 | PASS |
| `GanhoMusic tvOS/*` | 0 | PASS |
| `GanhoMusic.xcodeproj/project.pbxproj` | 0 | PASS |

## 검증 시나리오 (a)~(i) 정적 검증 결과

| # | 시나리오 | 검증 결과 |
|---|---|---|
| **(a)** | `startFleeing` 호출 trigger 1곳 한정 | `grep -rn "startFleeing"`: 호출처는 `GameScene.swift:214` 1곳뿐. 그 외(:27, :200)는 헤더/doc 주석, EnemyNode 내부(:6, :18, :56)는 자체 정의/주석 — **PASS** |
| **(b)** | trigger 마지막 줄 정확 호출 | `GameScene.swift:214` = `enemy.startFleeing(duration: GameConfig.enemyFleeDuration)` (BombFlashNode 발화 :213 *다음*, 닫는 중괄호 :215 *직전*) — **PASS** |
| **(c)** | x축 velocity 반전 | `EnemyNode.swift:86` `let direction: CGFloat = isFleeing ? -1 : 1`, `:88` `dx: unitX * speed * direction` — **PASS** |
| **(d)** | y축 velocity 반전 | `EnemyNode.swift:89` `dy: unitY * speed * direction` — **PASS** |
| **(e)** | 5초 후 isFleeing = false | `EnemyNode.swift:60` `let end = SKAction.run { [weak self] in self?.isFleeing = false }` — sequence([start, wait, end])의 *마지막* 액션. SPEC §기능 2와 정확 일치 — **PASS** |
| **(f)** | 도주 중 충돌 시 게임오버 유지 | `EnemyNode.swift:39` `body.collisionBitMask = PhysicsCategory.wall`, `:40` `body.contactTestBitMask = PhysicsCategory.player` — Init 본문 변경 0건. ContactRouter도 0줄 diff → 도주 모드에서도 player 접촉 시 `onEnemyHit → endGame()` 정상 동작 — **PASS** |
| **(g)** | 재통과 시 도주 발동 0 | 이중 가드 확인: `GameScene.swift:202` `if airforceTriggered { return }` (Phase 4-3 가드 보존) + `EnemyNode.swift:57` `if isFleeing { return }` (Phase 4-6 신설 재호출 가드) — **PASS** |
| **(h)** | ARC 안전 캡처 | `EnemyNode.swift:58` `SKAction.run { [weak self] in self?.isFleeing = true }`, `:60` `SKAction.run { [weak self] in self?.isFleeing = false }` — 두 클로저 모두 `[weak self]` — **PASS** |
| **(i)** | 빌드 + 정적 품질 | BUILD SUCCEEDED, 경고 0, 강제 언래핑 0 (`grep "!" ... | grep -v "!=" | grep -v "//"` 결과 비어 있음), 매직 넘버 0 (`5.0`은 `GameConfig.enemyFleeDuration` 단일 정의·외부 *상수 참조만*; `direction = ? -1 : 1`은 sign multiplier 의미 상수 — 상수화 대상 아님), Timer/DispatchQueue 호출 0 — **PASS** |

## 통과 항목 — Swift 패턴

- **강제 언래핑 미사용**: `EnemyNode.swift` 신규 본문 (state/flee/update 분기) 어디에도 `!` 없음. `physicsBody?.velocity` 옵셔널 체이닝 보존.
- **`guard` / 옵셔널 처리**: `update`의 `guard magnitude > 0 else { ... }` 보존. 신규 코드 옵셔널 부재.
- **MARK 섹션**: `// MARK: - State`, `// MARK: - Flee` 신설. 기존 `// MARK: - Init` / `// MARK: - Update` 보존.
- **GameConfig 상수**: `enemyFleeDuration = 5.0` 단일 정의, 호출부는 `GameConfig.enemyFleeDuration` 참조. 매직 넘버 0.
- **`[weak self]` 캡처**: `startFleeing` 내부 두 클로저 의무 적용.
- **함수 단일 책임**: `startFleeing`은 *도주 진입 + 만료 예약*만, `update`는 *velocity 갱신*만. 책임 분리 명확.
- **네이밍**: `isFleeing` (lowerCamelCase, Bool prefix `is`), `startFleeing(duration:)` (lowerCamelCase, 동사+명사), `enemyFleeDuration` (lowerCamelCase) — swift-rules.md §1 준수.

## 통과 항목 — SpriteKit 패턴

- **SKAction.sequence 시간 흐름**: `Timer.scheduledTimer` / `DispatchQueue.main.asyncAfter` 대신 `SKAction.sequence([run, wait, run])`로 5초 만료 표현. swift-rules.md §9, spritekit-rules.md §10 준수.
- **velocity 기반 이동 보존**: 기존 EnemyNode 패턴(엔진이 dt 처리) 변경 없음. dt 무관 일관 속도.
- **PhysicsBody 설정 보존**: collisionBitMask / contactTestBitMask / categoryBitMask 변경 0건. 충돌 분기 회귀 없음.
- **즉시 노드 삭제 없음**: 충돌 핸들러 변경 0건. 도주 모드는 충돌 처리와 무관한 *상태 머신*.
- **HUD 분리 보존**: HUDNode 변경 0건.

## 통과 항목 — 게임 디자인 정합성

- **GDD §7-7 정확 일치**: SPEC.md / GameConfig doc 모두 "5초" 명시, `enemyFleeDuration = 5.0`.
- ***겁먹은 듯* 게임 경험**: SKAction.sequence가 *지연 없는 즉시 도주 진입 → 5초 후 자연스러운 복귀* 보장. 호출 측은 1줄 단순 호출.
- **트리거 위치**: Player ↔ StoneGuard 첫 접촉 시 trigger 본문 마지막에서 발동. 폭탄(BombFlash) 직후 *논리적 흐름* 일치.
- **속도 정책 보존**: 도주 속도 별도 상수 신설 0건. `enemyBaseSpeed`(60) → `enemyMaxSpeed`(110) 시간 보간 그대로 적용되며 방향만 반전. SPEC "속도는 평소와 동일" 약속 준수.

## 채점

**항목별 점수**:

- **Swift 패턴 일관성**: **10/10** → 강제 언래핑 0, MARK 섹션 신설, GameConfig 상수화, `[weak self]` 의무 캡처, 함수 단일 책임, 네이밍 규칙 완전 준수. 사소한 불일치 없음. P2 이슈 0건.
- **게임 로직 완성도**: **10/10** → SKAction.sequence로 시간 흐름 표현(Timer/DispatchQueue 0), velocity 기반 이동 보존, 충돌 분기 무손상, 상태 머신 1-bit (`isFleeing` Bool) 명료. SPEC 검증 시나리오 (a)~(i) 9개 전부 PASS.
- **성능 & 안정성**: **10/10** → 빌드 SUCCEEDED + 경고 0. `[weak self]` 두 클로저 모두 적용 — 순환 참조 0. 재호출 가드(`if isFleeing { return }`) + 1회 한정 가드(`airforceTriggered`) 이중 방어. `physicsBody?.velocity` 옵셔널 체이닝 보존.
- **기능 완성도**: **10/10** → SPEC 기능 1~7 모두 구현, 회귀 대상 18개 파일 0줄 변경(OoS 미위반), 검증 시나리오 (a)~(i) 모두 PASS, pbxproj 변경 0(신규 파일 없음).

**가중 점수 계산**:
- Swift: 10 × 0.35 = 3.50
- 게임로직: 10 × 0.30 = 3.00
- 성능안정성: 10 × 0.20 = 2.00
- 기능완성도: 10 × 0.15 = 1.50
- **합계: 10.0 / 10.0**

## 최종 판정: **합격**

**전체 판정**: 합격
**가중 점수**: 10.0 / 10.0

**자체 엄격성 재검토** (8.0 이상 도달 시 의무):
- "내가 관대하게 본 것은 아닌가?" → 4개 영역 각각 의도적으로 P2 후보 탐색했음:
  - Swift 패턴: `direction = isFleeing ? -1 : 1` 의 `-1, 1`이 매직 넘버인가? → 아님. 방향 *부호*는 수학적 의미 상수(unit vector × ±1)이며, "도주 속도 별도 상수 신설 금지"는 SPEC OoS 명시 항목. 상수화 시 오히려 SPEC 위반.
  - 게임 로직: SKAction이 노드 자체에 `run`됨 → 노드가 부모에서 떨어지면(removeFromParent) sequence가 자동 정지하므로 `endGame()` 시점 별도 정리 불필요. 게다가 `[weak self]`로 ARC 안전. 결함 없음.
  - 성능: 5초 wait 동안 EnemyNode가 ARC 해제될 수 있는가? → `let enemy = EnemyNode()`는 GameScene 강한 참조 보유. GameScene이 살아있는 동안 enemy도 산다. `[weak self]`는 *과방어*이지 결함 아님.
  - 기능: SPEC 7개 기능 + 검증 9개 시나리오 + 회귀 18개 파일 모두 통과. 미구현 항목 0건.
- 결과: 감점 사유를 *의도적으로 찾으려 해도* 발견되지 않음. 만점 유지 정당화됨.

**구체적 개선 지시**: 없음.

**추가 코멘트**:
- 본 sprint는 *행동 추가가 아니라 행동 분기*라는 상태 머신 1차 도입의 모범 사례. Generator는 SPEC을 ±1줄 정밀도로 구현했음.
- 다음 sprint(4-7 F 재스폰 효과 등)에서 도주 모드가 3개 이상 행동으로 늘어나면 `Bool isFleeing` → `enum EnemyAIState { case chasing, fleeing, ... }`로 승격(Rule of three)할 시점. SPEC 학습 가치 §1 이미 명시되어 있음.
