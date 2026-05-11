# QA 검수 보고서 — Phase 4-2 (A) 석조무사 접촉 감지 골격

## SPEC 기능 검증

- **[PASS] 기능 1 — PhysicsCategory.stoneGuard 비트 신설**
  `Config/PhysicsCategory.swift:19` 에 `static let stoneGuard: UInt32 = 0b100000 // 32  ← Phase 4-2 신설` 1줄 추가. projectile 다음 줄. 기존 none/player/note/enemy/wall/projectile 6개 비트 모두 미변경. 2의 거듭제곱(32) 규칙 준수.
- **[PASS] 기능 2 — StoneGuardNode PhysicsBody 부착 (통과형)**
  `Nodes/StoneGuardNode.swift:29-40` 에 PhysicsBody 부착 블록 삽입. `rectangleOf: size` / `isDynamic=false` / `allowsRotation=false` / `friction=0` / `restitution=0` / `linearDamping=0` / `categoryBitMask=.stoneGuard` / `collisionBitMask=0` / `contactTestBitMask=.player`. 위치도 SPEC 그대로 `super.init` 다음·`startPatrol()` 직전. 헤더에 Phase 4-2 주석 1줄 추가(`StoneGuardNode.swift:7`). 기존 `physicsBody = nil` 주석 적절히 대체됨.
- **[PASS] 기능 3 — ContactRouter 분기 + 콜백 변수 추가**
  `Systems/ContactRouter.swift:19` 에 `var onStoneGuardContact: () -> Void = {}` 콜백 변수 추가(`onEnemyHit` 바로 다음). `didBegin(_:)` 분기 순서가 `enemy → stoneGuard → projectile → note`로 SPEC 명세와 일치(`ContactRouter.swift:31-45`). 기존 enemy/projectile/note 분기 본문 한 줄도 변경 없음.
- **[PASS] 기능 4 — GameScene stub 콜백 등록**
  `GameScene.swift:23` 헤더 MARK 주석 1줄 추가. `configureContactRouter()` 본문 끝(`GameScene.swift:180-182`)에 stub 클로저 등록 — `[weak self]` 캡처 생략(self 미사용), TODO 주석 1줄만 본문에 존재. SPEC의 "효과 0 정책" 충족.

## 빌드 검증

- **결과**: BUILD SUCCEEDED
- **명령**: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- **destination 비고**: 환경에 iPhone 15 시뮬레이터가 없어 iPhone 17(iOS 26.4.1)로 대체. 평가 기준 §4-2의 "시뮬레이터 없음" SKIP 케이스가 아닌, 사용 가능한 다른 시뮬레이터로 빌드 성공시킨 케이스 — 통과로 처리.
- **Swift 컴파일 경고**: 0건 (`grep -E " warning:| error:" | grep -v AppIntents` 결과 빈 출력)
- **Swift 컴파일 에러**: 0건

## 회귀 검증 — OoS 위반 점검

| 항목 | 결과 | 근거 |
|---|---|---|
| `GameScene+Setup.swift` 0줄 변경 | PASS | `git diff HEAD -- "...GameScene+Setup.swift"` 출력 0줄 |
| `Config/GameConfig.swift` 0줄 변경 | PASS | `git diff HEAD -- "...GameConfig.swift"` 출력 0줄 (stoneGuard 4개 상수 모두 그대로) |
| `Scenes/TitleScene.swift` 0줄 변경 | PASS | git diff 0줄 |
| `Scenes/ResultScene.swift` 0줄 변경 | PASS | git diff 0줄 |
| `*.pbxproj` 0줄 변경 | PASS | `git diff HEAD -- "*.pbxproj"` 출력 0줄, 신규 파일 0건 |
| 다른 노드(Player/Enemy/Note/Projectile/HUD/DPad) `collisionBitMask`에 `stoneGuard` 미포함 | PASS | grep 결과 Player=`.wall`, Enemy=`.wall`, Note=0, Projectile=0, StoneGuard=0. 어디에도 `.stoneGuard` 미포함 → 양방향 통과 정책 안전 |
| 다른 시스템(SpawnSystem/ScoreSystem) 0줄 변경 | PASS | `git status` 변경 목록에 없음 |

## 검증 시나리오 (a)~(h) 정적 검증

| # | 시나리오 | 결과 | 근거 |
|---|---|---|---|
| (a) | `startPatrol/setupStoneGuard/stoneGuardWaypoints` 미변경 | PASS | `StoneGuardNode.swift:53-65` (startPatrol 본문) 미변경. `GameScene+Setup.swift:147` (setupStoneGuard) 0줄 diff. `GameConfig.swift:186` (stoneGuardWaypoints) 0줄 diff |
| (b) | collision=0, isDynamic=false, 다른 노드 collisionBitMask에 stoneGuard 미포함 | PASS | `StoneGuardNode.swift:32` `isDynamic=false`, `:38` `collisionBitMask=0`. 다른 노드 collisionBitMask grep 결과(상기 표) 어디에도 `.stoneGuard` 미포함 |
| (c) | `onStoneGuardContact` stub 본문에 scoreSystem/hud/endGame 호출 0건 | PASS | `GameScene.swift:180-182` 본문은 TODO 주석 1줄만, 코드 0줄. scoreSystem/hud/endGame 호출 없음 |
| (d) | 4개 변경 파일에 print/NSLog/debugPrint 0건 | PASS | `grep -nE "print\(\|NSLog\|debugPrint"` 결과 `NO MATCHES` |
| (e) | `didBegin` enemy/projectile/note 분기 본문 미변경 | PASS | `ContactRouter.swift:31-34, 39-42, 43-45` — 기존 분기 본문(onEnemyHit/handleProjectileContact/handleNoteContact 호출) 한 줄도 변경 없음. `handleProjectileContact`/`handleNoteContact` private 함수도 미변경 |
| (f) | `endGame()` 본문 미변경 | PASS | `GameScene.swift:190-215` — 멱등 가드, spawnSystem.stop, ResultScene presentation, highScoreRepo/statsRepo 순서 모두 그대로 |
| (g) | TitleScene/ResultScene 0줄 변경 | PASS | `git diff HEAD -- "Scenes/"` 0줄 |
| (h) | 빌드 SUCCEEDED + 경고 0건 | PASS | 빌드 성공, Swift 컴파일 경고/에러 0건 (상기 빌드 검증 섹션) |

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## P0 — 치명적 이슈
**해당 없음.**

## P1 — 중요 이슈
**해당 없음.**

## P2 — 권장 사항
**해당 없음.**

본 sprint는 *시그니처만 확정하고 효과는 0인* "그릇만 먼저" 패턴 — 변경 줄 수가 +25/-1로 극히 작고 SPEC의 In Scope 4건과 1:1 매핑이 정확. 자체 점검(SELF_CHECK.md)의 모든 체크박스가 실제로 코드에서 검증됨. AI 슬롭 패턴(강제 언래핑, Timer, 매직 넘버, update() 내 addChild, 고정값 이동, 강한 self 캡처) 0건. 빌드 경고 0건.

## 통과 항목

- **Swift 패턴 일관성**
  - 강제 언래핑(`!`) 0건 — 추가 4개 파일 어디에도 없음 (grep 결과 빈 출력)
  - 매직 넘버 0건 — PhysicsBody size는 `GameConfig.stoneGuardWidth/Height`, 카테고리는 `PhysicsCategory.stoneGuard/.player` 상수로만 표현
  - `MARK:` 섹션 구분 — ContactRouter `// MARK: - Callbacks` 섹션 내부에 새 콜백 변수 삽입, StoneGuardNode `// MARK: - Init`/`// MARK: - Patrol` 그대로
  - 함수 단일 책임 — `configureContactRouter()`에 콜백 등록 1건만 추가, `didBegin`에 분기 1개만 추가
  - 네이밍 — `onStoneGuardContact` lowerCamelCase, `.stoneGuard` UpperCamelCase 정합
- **게임 로직 / SpriteKit 패턴**
  - PhysicsBody 3비트마스크 패턴 — `category`(.stoneGuard) / `collision`(0, 통과) / `contactTest`(.player, 알림) 셋 독립 명시. 학습 노트 §3-1/§3-3/§3-4 핵심 패턴 정확히 구현
  - `isDynamic=false` 선택 근거 명확 — patrol이 SKAction.move 기반(velocity 미사용)이라 dynamic body와 충돌. SPEC 주의사항 §4 SpriteKit static-dynamic contact 보장 규칙(둘 중 하나만 dynamic이면 OK) 적용
  - 분기 순서 — `enemy → stoneGuard → projectile → note`. enemy 우선 보장(게임오버 누락 방지). enemy/projectile/note 카테고리 배타성 덕에 부작용 없음
  - 통과형 양방향 정책 — 다른 노드 collisionBitMask에 `.stoneGuard` 미포함 → 한쪽만 0으로 설정해도 양방향 통과 보장 (SpriteKit collision은 양방향 AND 매칭)
- **성능 & 안정성**
  - 강제 언래핑 0건, 클로저 self 강한 캡처 0건 (stub은 self 미사용, 등록측 4개 콜백은 모두 `[weak self]`)
  - 빌드 클린(BUILD SUCCEEDED, 경고/에러 0건)
  - 노드 즉시 삭제 패턴 없음 (stub 본문 비어있음)
  - stub 콜백에 `[weak self]` 의도적 생략 — 빈 캡처 시 *unused capture* 경고 회피. 4-3에서 self 사용 시 추가하면 됨. SPEC §주의사항 §7 "경고 0건" 충족
- **기능 완성도**
  - SPEC In Scope 4건 모두 구현 (PhysicsCategory / StoneGuardNode / ContactRouter / GameScene)
  - SPEC Out of Scope 14건 모두 미위반 (GameScene+Setup / GameConfig / pbxproj / 다른 노드/시스템 / Scenes / ColorTokens / update / endGame / 이스터에그 효과 / print / macOS-tvOS / Test / waypoint·patrol)
  - 변경 줄 수 +25/-1로 SPEC 예상 범위(+~22줄)와 일치
  - 학습 노트(`docs/learn/25-phase4-2-stoneguard-contact.md`) 추가로 사용자 학습 노트 정책 충족

---

## 채점

| 항목 | 점수 | 가중 | 가중점수 | 코멘트 |
|---|---|---|---|---|
| Swift 패턴 일관성 | 10 / 10 | 0.35 | 3.50 | 강제 언래핑 0건, 매직 넘버 0건, MARK 구분, 상수 분리. P2 수준 불일치도 0건 |
| 게임 로직 완성도 | 10 / 10 | 0.30 | 3.00 | PhysicsBody 3비트마스크 패턴 정확, 분기 순서 근거 명확, static-dynamic contact 보장 규칙 활용. SpriteKit 패턴 모범 |
| 성능 & 안정성 | 10 / 10 | 0.20 | 2.00 | 크래시 원인 0건, weak self 정책 정확(stub 미사용=생략, 등록측 4개=`[weak self]`). 빌드 클린·경고 0건 |
| 기능 완성도 | 10 / 10 | 0.15 | 1.50 | SPEC In Scope 4건 모두 구현. OoS 14건 모두 미위반. 본 sprint의 "stub 시그니처 확정" 의도 정확 반영 |
| **가중 합계** | — | **1.00** | **10.00 / 10.0** | — |

## 최종 판정: 합격

본 sprint는 *효과 0 / 시그니처 확정* 분리 패턴의 모범 사례. SPEC의 In Scope·Out of Scope 경계가 코드 레벨에서 정확히 지켜졌고, 검증 시나리오 (a)~(h) 8개 모두 정적 검증 + 빌드 검증 통과. 자체 점검의 모든 주장이 실제 코드에서 재검증됨. 

엄격성 재검토(만점 자동 의심):
- 4개 파일 +25/-1줄로 변경량이 작아 검수 표면적이 좁음 — 모든 grep 결과·diff 결과·빌드 결과를 직접 확인했고 위반 0건 확인
- 본 sprint는 "그릇만 만들기"가 명시 목표이므로 *효과 부재*가 흠이 아닌 *의도된 산출*. SPEC 자체가 "stub 본문 코드 0줄" 규정 → 코드량 부족으로 인한 감점 사유 없음
- 다음 sprint(4-3)에서 본체를 채울 때 호출 측 시그니처 변경 0이 보장됨 (`onStoneGuardContact: () -> Void` 시그니처 확정 + `configureContactRouter` 등록 자리 확정)

**구체적 개선 지시**: 없음. 4-3 sprint 진입 가능.
