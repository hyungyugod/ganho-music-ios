# QA 검수 보고서 — Phase 4-3 AIRFORCE 이스터에그

## SPEC 기능 검증

- **PASS** 기능 1 — `Nodes/AirplaneNode.swift` 신설: 49줄. `final class AirplaneNode: SKSpriteNode`, `init()` + `required init?(coder:)` + `crossScreen(sceneWidth:atY:)` 3개 멤버. `name = "airplane"`, `zPosition = 50`. PhysicsBody 0건. `.ganhoYellowF` 재사용.
- **PASS** 기능 2 — `GameConfig` Airforce Easter Egg 섹션: Stone Guard 섹션 *바로 다음* (라인 193~201). 4상수 (`airplaneWidth=32`, `airplaneHeight=16`, `airplaneCrossDuration=2.0`, `airplaneTopOffset=60`). 기존 상수 0줄 변경.
- **PASS** 기능 3 — GameScene 헤더 MARK: 라인 24에 Phase 4-3 라인 1줄 추가.
- **PASS** 기능 4 — `private var airforceTriggered: Bool = false`: 라인 59. `statsRepo`(55) 다음, `// MARK: - Factory`(61) 위.
- **PASS** 기능 5 — `triggerAirforceEasterEgg()` (라인 194~201): 5단계 정확 — ① 가드 ② 플래그 ③ 인스턴스화 ④ `cameraNode.addChild` ⑤ crossScreen. `// MARK: - Easter Egg` 섹션 신설.
- **PASS** 기능 6 — `onStoneGuardContact = { [weak self] in self?.triggerAirforceEasterEgg() }` (라인 185~187). 4-2 stub 주석 제거 완료.
- **PASS** 기능 7 — pbxproj 4곳 0018 등록 확인:
  - 라인 29 `PBXBuildFile`: `A1C0F1B00000000000000018`
  - 라인 52 `PBXFileReference`: `A1C0F1A00000000000000018`
  - 라인 188 Nodes 그룹 children: `A1C0F1A00000000000000018`
  - 라인 420 iOS Sources phase: `A1C0F1B00000000000000018`
  - tvOS / macOS Sources phase: files = (); 0건 — 정책 준수.

## 빌드 검증

- 명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- 결과: **BUILD SUCCEEDED**
- warning / error grep: **0건**

## 회귀 검증 (OoS 위반 점검)

`git diff HEAD --name-only` 변경 파일 = `GameConfig.swift`, `GameScene.swift`, `project.pbxproj` 3개 + 신규 `AirplaneNode.swift` 1개. 나머지 모두 **0줄 변경 확인**:

| 파일 | 변경 라인 | 확인 |
|---|---|---|
| `Systems/ContactRouter.swift` | 0 | 콜백 시그니처 `() -> Void` 그대로 |
| `Config/PhysicsCategory.swift` | 0 | `.airplane` 등 새 비트 0 |
| `Nodes/StoneGuardNode.swift` | 0 | |
| `GameScene+Setup.swift` | 0 | `setupStoneGuard` 그대로 |
| `Nodes/Enemy/Player/Note/Projectile/HUD/DPad` | 0 | |
| `Scenes/TitleScene.swift` `ResultScene.swift` | 0 | |
| `Config/ColorTokens.swift` | 0 | `.ganhoYellowF` 재사용 |
| macOS / tvOS Sources phase | 0 | iOS Sources phase에만 0018 추가 |
| `GameScene.endGame()` | 0 | diff 컨텍스트 라인만 표시, 본문 unchanged |

## 검증 시나리오 (a)~(i) 정적 검증 결과

| # | 시나리오 | 결과 | 근거 |
|---|---|---|---|
| (a) | StoneGuard 미접촉 시 비행기 0건 | PASS | `AirplaneNode()` 호출 유일 위치: `GameScene.swift:197`. didMove/update/endGame/configureContactRouter 본문 0건. |
| (b) | 통과 시 비행기 1회 등장 | PASS | trigger 본문 5단계 순서 정확. AirplaneNode.crossScreen: `SKAction.sequence([move, cleanup])`. |
| (c) | 재통과 시 비행기 0건 | PASS | `airforceTriggered = true`가 본문 2번째 실행 줄. |
| (d) | HUD / 점수 변화 0 | PASS | trigger·AirplaneNode 양쪽 모두 scoreSystem/hud/remainingTime/gameState/endGame 참조 0건. |
| (e) | player / enemy / F 영향 0 | PASS | AirplaneNode.swift 전체에 physicsBody/SKPhysicsBody/categoryBitMask/contactTestBitMask/collisionBitMask/PhysicsCategory 참조 0건. |
| (f) | cameraNode 자식 부착 | PASS | `cameraNode.addChild(plane)` 1건만. worldNode/self.addChild 0건. |
| (g) | 게임오버 시 비행기 잔존 → ARC 자동 해제 | PASS | `endGame()` 본문 0줄 변경. presentScene 시 GameScene 트리 ARC 해제. |
| (h) | 재시작 시 리셋 | PASS | `private var airforceTriggered: Bool = false` 기본값 명시. |
| (i) | 빌드 SUCCEEDED + 경고 0건 | PASS | `xcodebuild build` 결과 `** BUILD SUCCEEDED **`, warning/error 0건. |

## 추가 검증

- **pbxproj 0018 식별자 4곳**: PBXBuildFile(라인 29) / PBXFileReference(라인 52) / Nodes 그룹(라인 188) / iOS Sources phase(라인 420). 모두 StoneGuardNode 0017 바로 다음 줄 패턴 답습.
- **tvOS / macOS Sources phase**: 0018 식별자 0건 — iOS 정책 준수.
- **`final class AirplaneNode: SKSpriteNode`**: 확인 (라인 14).
- **`required init?(coder:) fatalError`**: 확인.
- **MARK 주석**: `// MARK: - Init`, `// MARK: - Cross` 두 섹션.
- **zPosition = 50**: 확인 (HUD 100 아래, 일반 노드 5 위).
- **`SKAction.sequence([move, removeFromParent])`**: 확인.

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | **0건** |
| P1 중요 | **0건** |
| P2 권장 | **0건** |

## 통과 항목

- **Swift 패턴**: 강제 언래핑 0건(`required init?(coder:) fatalError`는 표준 패턴), MARK 섹션, 매직 넘버 0건(`GameConfig.airplane*` 참조), `[weak self]` 캡처, 함수 단일 책임.
- **SpriteKit 패턴**: 콜백 시점 생성, `SKAction.sequence([move, removeFromParent])` 자가 소멸, HUD/일반 노드 zPosition 분리.
- **성능 & 안정성**: 빌드 클린(경고 0건), update() 0줄 변경, `[weak self]` 캡처로 순환 참조 차단.
- **기능 완성도**: SPEC In Scope 1~7 모두 구현, OoS 22개 항목 모두 미위반, 검증 시나리오 (a)~(i) 9개 모두 PASS.

## 채점

**항목별 점수**:
- **Swift 패턴 일관성: 10/10**
- **게임 로직 완성도: 10/10**
- **성능 & 안정성: 10/10**
- **기능 완성도: 10/10**

**가중 점수**: (10×0.35) + (10×0.30) + (10×0.20) + (10×0.15) = **10.0 / 10.0**

## 최종 판정: **합격**

**핵심 가치**: 4-2의 *그릇 분리*가 본 sprint의 *작업량 최소화*를 정확히 실현. 호출 측(ContactRouter / PhysicsCategory / StoneGuardNode / GameScene+Setup) 0줄 변경, 신규 노드 1개 + GameScene 12줄 + GameConfig 8줄 + pbxproj 4줄로 완성. 한 번의 분리가 다음 sprint를 *수술실*로 만든다.

**다음 sprint 준비**: Phase 4-4 (박병장 / 이교주 등 추가 NPC)로 진행 가능.
