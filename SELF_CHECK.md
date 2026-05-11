# 자체 점검 — Phase 4-3 AIRFORCE 이스터에그

## 변경 요약

| 파일 | 신설/수정 | 변경 라인 수 |
|---|---|---|
| `Nodes/AirplaneNode.swift` | 신설 | +49 (전체) |
| `Config/GameConfig.swift` | 수정 | +10 (Stone Guard 섹션 다음, Airforce Easter Egg 섹션 + 4 상수) |
| `GameScene.swift` | 수정 | +18 (헤더 1줄 + 프로퍼티 3줄 + onStoneGuardContact 본체 교체 -2/+2 + 새 메서드 + MARK 11줄) |
| `GanhoMusic.xcodeproj/project.pbxproj` | 수정 | +4 (식별자 0018 4곳) |

총 4개 파일.

## SPEC 기능 체크

- [x] 기능 1: `AirplaneNode.swift` 신설 — SPEC 그대로. final class, init+required init?(coder:)+crossScreen 3개 멤버. PhysicsBody 0건. `.ganhoYellowF` 사용. zPosition=50. 크기 `GameConfig.airplaneWidth × airplaneHeight`. name="airplane".
- [x] 기능 2: `GameConfig` Airforce Easter Egg 섹션 4상수 — `airplaneWidth=32`, `airplaneHeight=16`, `airplaneCrossDuration=2.0`, `airplaneTopOffset=60`. Stone Guard 섹션 바로 다음.
- [x] 기능 3: GameScene 헤더 MARK 라인 추가 — Phase 4-2 헤더 다음 줄 (라인 23).
- [x] 기능 4: `airforceTriggered: Bool = false` private var — `statsRepo` 다음, `// MARK: - Factory` 위.
- [x] 기능 5: `triggerAirforceEasterEgg()` private func — `configureContactRouter()` 직후, `// MARK: - Easter Egg` 섹션. SPEC 본문 5단계 정확: ① 가드 ② 플래그 ③ AirplaneNode 인스턴스화 ④ cameraNode.addChild ⑤ crossScreen.
- [x] 기능 6: `onStoneGuardContact` stub 본체 교체 — `{ [weak self] in self?.triggerAirforceEasterEgg() }`. 4-2 stub 주석 제거 완료.
- [x] 기능 7: pbxproj 4곳 0018 등록 — PBXBuildFile, PBXFileReference, Nodes 그룹 children, iOS Sources phase. StoneGuardNode 0017 *바로 다음 줄*에 동일 패턴.

## Swift 패턴 준수

- 강제 언래핑 미사용: 준수 (`required init?(coder:)` 표준 `fatalError`는 강제 언래핑 아님)
- guard let 옵셔널 처리: N/A (이번 sprint 옵셔널 0건)
- MARK 섹션 구분: 준수 (Init / Cross / Easter Egg / Factory / Game State 모두 // MARK: - 사용)
- GameConfig 상수 사용: 준수 (32, 16, 2.0, 60 모두 `GameConfig.airplane*` 참조)
- weak self 캡처: 준수 (`onStoneGuardContact = { [weak self] in self?.triggerAirforceEasterEgg() }`)

## SpriteKit 패턴 준수

- didMove(to:)에서 초기화: 준수 (configureContactRouter는 기존 호출 그대로, AirplaneNode는 콜백 시점 생성)
- dt 기반 이동: N/A (비행기는 SKAction.move duration 기반)
- SKAction 스폰 패턴: 준수 (`SKAction.sequence([move, removeFromParent])`)
- 충돌 후 노드 즉시 삭제 없음: 준수 (비행기는 충돌 무관, 자가 소멸 SKAction)
- HUD 노드 분리: 준수 (HUD 0건 변경)
- 물리 델리게이트 0건 손댐: 준수 (PhysicsCategory / ContactRouter 0줄 변경)

## OoS 미위반 체크리스트

| 항목 | 변경 여부 | 비고 |
|---|---|---|
| ContactRouter.swift | 0줄 변경 | 콜백 시그니처 `() -> Void` 그대로 |
| PhysicsCategory.swift | 0줄 변경 | .airplane 신설 0건 |
| StoneGuardNode.swift | 0줄 변경 | PhysicsBody / startPatrol 그대로 |
| GameScene+Setup.swift | 0줄 변경 | setupStoneGuard 그대로 |
| 기존 GameConfig 상수 | 0줄 변경 | 새 섹션만 추가 |
| ColorTokens.swift | 0줄 변경 | `.ganhoYellowF` 재사용 |
| EnemyNode/PlayerNode/NoteNode/ProjectileNode/HUDNode/DPadNode | 0줄 변경 | |
| TitleScene/ResultScene | 0줄 변경 | |
| update() | 0줄 변경 | |
| endGame() | 0줄 변경 | |
| macOS/tvOS Sources phase | 0줄 변경 | iOS Sources phase에만 0018 추가 |
| 새 Manager/Repository/System | 0건 신설 | |
| Test 코드 | 0건 추가 | |

## 검증 시나리오 정적 검증 결과

| # | 시나리오 | 결과 |
|---|---|---|
| (a) | StoneGuard 미접촉 시 비행기 0건 | PASS — `AirplaneNode()` 호출 1곳(GameScene.swift:197, `triggerAirforceEasterEgg()` 본문). didMove / update / endGame에 직접 호출 0건. |
| (b) | 통과 시 비행기 1회 등장 | PASS — `triggerAirforceEasterEgg()` 본문 5단계: ① `if airforceTriggered { return }` ② `airforceTriggered = true` ③ `let plane = AirplaneNode()` ④ `cameraNode.addChild(plane)` ⑤ `plane.crossScreen(sceneWidth: size.width, atY: y)`. AirplaneNode.crossScreen는 `SKAction.sequence([move, cleanup])` 정확. |
| (c) | 재통과 시 비행기 0건 | PASS — `airforceTriggered = true` 가 본문 2번째 줄(가드 직후). 두 번째 호출은 `if airforceTriggered { return }`로 즉시 종료. |
| (d) | HUD / 점수 변화 0 | PASS — `triggerAirforceEasterEgg()` 본문에 `scoreSystem`, `hud`, `remainingTime`, `gameState`, `endGame` 참조 0건. AirplaneNode.swift 전체에 `scoreSystem`, `hud` 참조 0건. |
| (e) | player / enemy / F 영향 0 | PASS — AirplaneNode.swift 전체에 `physicsBody`, `SKPhysicsBody`, `categoryBitMask`, `contactTestBitMask`, `collisionBitMask`, `PhysicsCategory` 참조 0건 (grep 확인). |
| (f) | cameraNode 자식 부착 | PASS — `cameraNode.addChild(plane)` 명시 (GameScene.swift:198). `worldNode.addChild(plane)` / `self.addChild(plane)` 0건. |
| (g) | 게임오버 시 비행기 잔존 → ARC 자동 해제 | PASS — `endGame()` 본문 0줄 변경. cameraNode 자식이라 GameScene 트리에 종속, `presentScene(ResultScene)` 시 ARC로 자동 해제. 별도 cleanup 0건. |
| (h) | 재시작 시 리셋 | PASS — `private var airforceTriggered: Bool = false` 기본값 명시. 새 GameScene 인스턴스 생성 시 false로 시작. |
| (i) | 빌드 SUCCEEDED + 경고 0건 | PASS — `xcodebuild build` 결과 ** BUILD SUCCEEDED **. warning/error grep 결과 0건. pbxproj 0018 4곳 모두 등록 확인. `final class AirplaneNode: SKSpriteNode` + `required init?(coder:)` + `import SpriteKit` 시그니처 정확. |

## 빌드 상태

- 명령: `xcodebuild -project GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' build`
- 결과: **BUILD SUCCEEDED**
- 경고: 0건 (AppIntents Metadata 스킵은 환경 메시지 — 본 sprint 무관)
- 에러: 0건

## 범위 외 미구현 항목

- 없음 — SPEC In Scope 1~4 모두 구현. Out of Scope 항목 0건 변경 (위 OoS 체크리스트 참조).

## 전략 노트

- 1회차 작업이므로 Case A/B/C 판단 불필요.
- SPEC.md의 핵심 코드 구조를 *글자 단위로* 답습. 자율 판단 0건.
- pbxproj 0018 식별자가 StoneGuardNode 0017 다음 자유 슬롯임을 확인(0018 grep 결과 사전 0건 → 사후 정확히 4건).
