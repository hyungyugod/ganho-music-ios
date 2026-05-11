# QA 검수 보고서 — Phase 5-2 (선택 캐릭터 색 → PlayerNode 몸체)

## SPEC 기능 검증

- [PASS] **기능 1 (GameScene 헤더/프로퍼티/init/factory)** — `GameScene.swift:29` 헤더 1줄, `:66~68` `let characterID: CharacterID`, `:70~80` `// MARK: - Init` + `init(size:characterID:)` (self → super 순서) + `required init?(coder:) fatalError`, `:83` factory `newGameScene(characterID: CharacterID = .kim)`.
- [PASS] **기능 2 (setupPlayer 1줄)** — `GameScene+Setup.swift:113` `player.color = characterID.color`가 `player.position` 다음, `worldNode.addChild(player)` *이전*에 정확히 삽입됨.
- [PASS] **기능 3 (TitleScene newGameScene 호출 1줄 교체)** — `TitleScene.swift:169` `GameScene.newGameScene(characterID: selectedCharacterID)`. "그 외 영역" 블록 안, `isTransitioning` 가드 다음에 위치.

## 빌드 검증

- **결과**: `** BUILD SUCCEEDED **`
- **scheme**: `GanhoMusic iOS`
- **destination**: `generic/platform=iOS Simulator` (iPhone Simulator SDK 26.4)
- **경고**: 0건 (필터 `grep -E "warning:|error:"` 결과 0줄)
- **에러**: 0건
- **비고**: macOS/tvOS `GameViewController`의 `GameScene.newGameScene()` 무인자 호출은 default `= .kim` 덕분에 소스 호환 — 빌드 통과.

## 회귀 검증 (변경 0줄 확인)

`git diff --name-only` 출력: 정확히 3개 파일만 수정됨 — `GameScene.swift`, `GameScene+Setup.swift`, `Scenes/TitleScene.swift`. 다음은 모두 0줄 변경 확인:

| 영역 | 결과 |
|---|---|
| `PlayerNode` / `EnemyNode` / `StoneGuardNode` / `NoteNode` / `ProjectileNode` / `HUDNode` / `DPadNode` / `AirplaneNode` / `AirforceOverlayNode` / `BombFlashNode` / `CharacterCardNode` | 0줄 |
| `CharacterID.swift` / `Models/*` | 0줄 |
| `Config/GameConfig.swift` / `ColorTokens.swift` / `PhysicsCategory.swift` / `GameState.swift` | 0줄 |
| `Protocols/SelfDismissingNode.swift` | 0줄 |
| `Scenes/ResultScene.swift` | 0줄 |
| `Systems/ContactRouter.swift` / `SpawnSystem.swift` / `ScoreSystem.swift` | 0줄 |
| `Repositories/*` | 0줄 |
| `pbxproj` / macOS / tvOS Sources phase | 0줄 |
| `GameScene` 기존 메서드 (`didMove` / `update` / `endGame` / `configureContactRouter` / `triggerAirforceEasterEgg` / `didChangeSize` / `layoutDPad` / `layoutHUD`) | 본문 0줄 (재읽기로 시각 비교 완료) |
| `TitleScene` (`selectedCharacterID` 선언 / 카드 setup / layout / hit test / `isTransitioning` 가드) | 본문 0줄 (1줄 교체만, `newGameScene()` → `newGameScene(characterID:)`) |
| `GameScene+Setup` 다른 setup 메서드 (`setupBackground` / `setupWorld` / `addOuterWalls` / `addCentralPillar` / `setupCamera` / `setupDPad` / `setupHUD` / `setupEnemy` / `setupStoneGuard`) | 0줄 |

`git diff` 라인 합계: +25 / -3 (헤더 1 + characterID 프로퍼티 4 + Init 섹션 11 + factory 시그니처 교체 2/-2 + setupPlayer 1 + TitleScene 1/-1 = SPEC 예상치와 일치).

## 검증 시나리오 (a)~(h) 정적 검증

| # | 시나리오 | 정적 추적 결과 | 상태 |
|---|---|---|---|
| (a) | 기본 kim 진입 | `TitleScene.swift:27` `selectedCharacterID: CharacterID = .kim` → `:169` `newGameScene(characterID: .kim)` → `GameScene.swift:73~76` `self.characterID = .kim` → `GameScene+Setup.swift:113` `player.color = .kim.color = .ganhoPaper` | PASS |
| (b) | 이간호 → 시작 | `TitleScene.swift:145~150` `select(.lee)` → `selectedCharacterID = .lee` → `newGameScene(characterID: .lee)` → `player.color = .ganhoBloodAccent` (HEX #D8315B 빨강) | PASS |
| (c) | 정간호 → 시작 | `select(.jung)` → `player.color = .ganhoMint` (HEX #7DCFB6 민트) | PASS |
| (d) | 임간호 → 시작 | `select(.im)` → `player.color = .ganhoYellowF` (HEX #FFD23F 노랑) | PASS |
| (e) | 건간호 → 시작 | `select(.geon)` → `player.color = .ganhoPinkNote` (HEX #F6A6B2 분홍) | PASS |
| (f) | 종료 → 재시작 시 kim 리셋 | `endGame()` → `ResultScene` → 사용자 탭으로 `TitleScene` 새 인스턴스 → `private var selectedCharacterID: CharacterID = .kim` 기본값으로 매 init 시 재초기화 (stored property의 default initializer는 인스턴스 단위 — Spring `@Scope("prototype")` 패턴) | PASS |
| (g) | AIRFORCE 이스터에그 | `GameScene.swift:220~236` `triggerAirforceEasterEgg` 본문 0줄 변경. `airforceTriggered` 가드 / `AirplaneNode` / `AirforceOverlayNode` / `BombFlashNode` / `enemy.startFleeing` / `spawnSystem.fireImmediately` 모두 `characterID`/`player.color`에 의존하지 않음 — 5 캐릭터 어느 쪽이든 정상 발화 | PASS |
| (h) | 빌드 SUCCEEDED + 경고 0 | xcodebuild iPhone Simulator 26.4 destination, `** BUILD SUCCEEDED **`, 사용자/프로젝트 warning 0건 | PASS |

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## P0 — 치명적 이슈
없음.

## P1 — 중요 이슈
없음.

## P2 — 권장 사항
없음. 본 sprint 변경분 자체에는 개선 여지 없음. (기존 코드의 macOS/tvOS `GameViewController`가 `self.view as! SKView` 강제 캐스트를 사용 중이나, **본 sprint 범위 외**이며 default `= .kim` 덕분에 그쪽은 0줄 변경이라 회귀 위험 없음.)

## 통과 항목 (Swift / SpriteKit 패턴 체크리스트)

### Swift 패턴
- [x] **강제 언래핑(`!`) 0건** — 신규/변경 라인 grep 결과 0. `TitleScene.swift:166`의 `!isTransitioning`은 논리 NOT.
- [x] **`guard let` 옵셔널 처리** — 신규 코드에 옵셔널 unwrap 없음 (N/A).
- [x] **MARK 섹션 구분** — `// MARK: - Init` 신설 (Factory 위, swift-rules.md §5 권장 순서 준수: Properties → Init → Factory → Lifecycle).
- [x] **매직 넘버 0건** — `CGSize(width: 1024, height: 768)`은 기존 factory 시그니처 그대로 (이번 sprint OoS), 새 매직 넘버 추가 0.
- [x] **타입 명명** — `CharacterID` UpperCamelCase + 약어 대문자(`ID`) (swift-rules.md §1).
- [x] **프로퍼티 명명** — `characterID` lowerCamelCase + 약어 대문자(`ID`).
- [x] **`let` 불변 stored property** — `let characterID: CharacterID` — 한 판 안에서 캐릭터 변경 불가 (Java `final` 효과).
- [x] **Designated initializer 규칙** — `self.characterID = characterID` (stored property 먼저) → `super.init(size: size)` 순서 정확. Swift Phase 1 init 규칙 준수.
- [x] **`required init?(coder:)` 의무** — override init 추가 시 NSCoding init도 정의해야 하는 컴파일러 요구 충족. `fatalError`로 의도 명시.
- [x] **default parameter value** — `newGameScene(characterID: CharacterID = .kim)` — 호출자 호환성 보존(Spring 메서드 오버로딩 회피 패턴).
- [x] **함수 단일 책임** — `init` 2줄, `setupPlayer` 본문 1줄 증가뿐 (이전 책임 변화 없음).

### SpriteKit 패턴
- [x] **didMove(to:)에서 초기화** — 변경 없음, 기존 패턴 유지. `setupPlayer()`가 색까지 책임 (응집).
- [x] **dt 기반 이동** — N/A (변경 없음).
- [x] **SKAction 스폰** — N/A (변경 없음).
- [x] **충돌 델리게이트 내 즉시 삭제** — N/A (변경 없음).
- [x] **HUD 분리** — N/A (변경 없음).
- [x] **SKSpriteNode.color setter** — `PlayerNode`가 `SKSpriteNode` 상속 — `color`는 표준 setter, 호출 즉시 다음 프레임에 SpriteKit이 자동 재드로우. `PlayerNode.swift` 본문 0줄 변경 (OoS 준수).
- [x] **카메라/world 노드 계층** — N/A.

### 안정성
- [x] **클로저 강한 캡처 0** — `triggerAirforceEasterEgg`의 `[weak self]` 패턴은 기존 코드 그대로 (변경 없음).
- [x] **노드 정리** — N/A (이번 변경은 setter 1줄).
- [x] **빌드 클린** — `** BUILD SUCCEEDED **`, warning 0, error 0.

### 기능 완성도
- [x] **SPEC In Scope 5항목 모두 구현** — 헤더 / 프로퍼티 / init / factory / setupPlayer / TitleScene 1줄.
- [x] **OoS 28항목 모두 0줄 변경** — `git diff --name-only` 출력 3개 파일만.
- [x] **검증 시나리오 (a)~(h) 모두 PASS**.
- [x] **macOS/tvOS 소스 호환성** — default `.kim` 덕분에 무수정 빌드.

---

## 채점

| 항목 | 비중 | 점수 | 근거 |
|---|---|---|---|
| Swift 패턴 일관성 | 35% | **9.5** / 10 | `init` self→super 순서, `required init?(coder:)` 의무, `let` 불변, `MARK` 섹션, default value, UpperCamelCase/약어 대문자 — 모든 swift-rules.md 항목 충족. 신규 매직 넘버 0, 강제 언래핑 0. 트집 잡을 곳이 거의 없음. 1점 만점은 신규 기능 함수 자체가 워낙 작아 "완벽" 입증 표면적이 제한적인 보수적 감점. |
| 게임 로직 완성도 | 30% | **9.5** / 10 | SpriteKit `SKSpriteNode.color` 표준 setter 활용으로 PlayerNode 본문 0줄 (캡슐화 트레이드오프 정합). 5 캐릭터 각자 ColorTokens 매핑 정확. AIRFORCE 이스터에그 회귀 0건. Constructor injection으로 TitleScene→GameScene 데이터 전달이 SpriteKit `view.presentScene` 흐름에 자연스럽게 안착. |
| 성능 & 안정성 | 20% | **10** / 10 | 빌드 SUCCEEDED + 경고 0. 강제 언래핑 0, weak 캡처 회귀 없음. 한 판 안에서 `characterID`는 `let`이라 race condition 원천 차단. `required init?(coder:) fatalError`는 NSCoding 경로 미사용 명시 — 의도된 패턴. |
| 기능 완성도 | 15% | **10** / 10 | SPEC In Scope 5/5 완전 구현. OoS 28/28 모두 0줄. 시나리오 (a)~(h) 모두 정적 PASS. macOS/tvOS 호환성 default value로 우아하게 해결. |

**가중 점수** = 9.5 × 0.35 + 9.5 × 0.30 + 10 × 0.20 + 10 × 0.15
            = 3.325 + 2.850 + 2.000 + 1.500
            = **9.675 / 10.0** → **9.7 / 10.0**

## 최종 판정: **합격**

본 sprint는 SPEC을 한 글자도 어기지 않고, 의도한 "TitleScene에서 선택한 캐릭터 색이 GameScene 진입 시 PlayerNode 몸체에 즉시 반영" 동작을 정확히 달성했다. Constructor injection의 모범 사례 — `let` 불변 / default value / `required init?(coder:)` / self→super 순서 — 가 모두 적용됐고, OoS 28항목 0줄 변경으로 회귀 위험 0. 빌드 클린(경고 0).

엄격하게 한 번 더 본 결과:
- "이 점수, 관대한가?" → P0/P1/P2 0건은 변경 범위가 +25/-3줄로 극히 작고 각 줄이 SPEC 요구에 1:1 대응하기 때문이다. 관대함이 아니라 변경 면적이 작아 실수 여지가 적은 것.
- 신기능 자체가 작아 9.7은 "변경분 자체로는 거의 만점"의 의미.

**구체적 개선 지시**: 없음. 본 sprint는 추가 작업 없이 머지 가능.

### 다음 sprint 권장 (Phase 5-3 이후, 본 sprint 범위 외)
참고용 — 채점에 무관.
1. macOS/tvOS `GameViewController`의 `self.view as! SKView` 강제 캐스트를 iOS와 동일한 `guard let ... else { assertionFailure }` 패턴으로 통일 (swift-rules.md §3 위반). 본 sprint OoS이므로 점수 영향 없음.
2. 캐릭터별 스킬/속도 차등 (5-3 이후 SPEC 시점에 추가).
