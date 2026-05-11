# 자체 점검 — Phase 5-2 (선택 캐릭터 색을 PlayerNode에 적용)

## 파일별 변경 줄 수

| 파일 | 추가 | 삭제 | 비고 |
|---|---|---|---|
| `GanhoMusic Shared/GameScene.swift` | +18 (헤더 1 + 프로퍼티 4 + Init 11 + factory 시그니처 변경) | -2 (기존 factory 2줄 교체) | 헤더 1 + characterID 프로퍼티 + init(size:characterID:) + required init?(coder:) + newGameScene(characterID:) |
| `GanhoMusic Shared/GameScene+Setup.swift` | +1 | 0 | `setupPlayer()` 안 `player.color = characterID.color` 1줄 |
| `GanhoMusic Shared/Scenes/TitleScene.swift` | +1 | -1 | `newGameScene()` → `newGameScene(characterID: selectedCharacterID)` |
| **합계** | **+20** | **-3** | 신설 파일 0, pbxproj 0 |

## SPEC 기능 체크
- [x] **기능 1 (GameScene 헤더/프로퍼티/init/factory)**:
  - 헤더 1줄 추가 (`Phase 4-7` 다음 줄)
  - `let characterID: CharacterID` 프로퍼티 추가 (불변)
  - `// MARK: - Init` 섹션 신설 + `init(size:characterID:)` (stored property 먼저 → super 다음, Swift 규칙 준수)
  - `required init?(coder aDecoder: NSCoder) { fatalError(...) }` 의무 충족
  - `newGameScene(characterID: CharacterID = .kim)` factory로 시그니처 확장 (default value로 소스 호환 유지)
- [x] **기능 2 (setupPlayer 1줄)**:
  - `player.position = ...` 다음, `worldNode.addChild(player)` 이전에 `player.color = characterID.color` 1줄 정확히 삽입
- [x] **기능 3 (TitleScene 1줄 교체)**:
  - `touchesBegan` "그 외 영역" 블록의 `GameScene.newGameScene()` → `GameScene.newGameScene(characterID: selectedCharacterID)`

## OoS 미위반 검증
- [x] `PlayerNode.swift` 본문: 변경 0줄 (color는 SKSpriteNode 표준 setter로만 외부 set)
- [x] 다른 Node (Enemy/StoneGuard/Note/Projectile/HUD/DPad/Airplane/AirforceOverlay/BombFlash/CharacterCard): 변경 0
- [x] `CharacterID` enum: 변경 0 (5-1 그대로)
- [x] `GameConfig` 새 상수: 0
- [x] `ColorTokens` 새 토큰: 0
- [x] `ResultScene`: 변경 0
- [x] 시스템 (ContactRouter/SpawnSystem/ScoreSystem): 변경 0
- [x] Repository (HighScore/Statistics): 변경 0
- [x] `GameScene`의 다른 메서드 (`didMove`/`update`/`endGame`/`configureContactRouter`/`triggerAirforceEasterEgg`/`didChangeSize`/`layoutDPad`/`layoutHUD`): 0줄 변경
- [x] `GameScene+Setup`의 다른 setup 메서드 (setupBackground/setupWorld/addOuterWalls/addCentralPillar/setupCamera/setupDPad/setupHUD/setupEnemy/setupStoneGuard): 0줄 변경
- [x] `TitleScene`의 다른 부분 (`selectedCharacterID` 프로퍼티, 카드 setup/layout/select/hit test, isTransitioning 가드 등): 0줄 변경
- [x] `pbxproj`: 변경 0
- [x] macOS / tvOS Sources phase: 변경 0 (default `.kim` 덕분에 `GameScene.newGameScene()` 무인자 호출 그대로 컴파일)
- [x] Test 코드: 변경 0

## Swift 패턴 준수
- **강제 언래핑 미사용**: 준수 (신규 코드에 `!` 0건)
- **guard let 옵셔널 처리**: N/A (신규 코드에 옵셔널 unwrap 없음)
- **MARK 섹션 구분**: 준수 (`// MARK: - Init` 신설, Factory 위에 배치)
- **GameConfig 상수 사용**: 준수 (새 매직 넘버 0)
- **weak self 캡처**: N/A (신규 코드에 클로저 없음)
- **타입 명명 (`CharacterID`)**: UpperCamelCase 준수 (기존 enum 재사용)
- **프로퍼티 명명 (`characterID`)**: lowerCamelCase + ID 약어 대문자 준수
- **`let` 불변 stored property**: 준수 (한 판 안에서 캐릭터 변경 불가)
- **stored property 초기화 → super.init 순서**: 준수 (Swift Designated Initializer 규칙)

## SpriteKit 패턴 준수
- **didMove(to:)에서 초기화**: 준수 (변경 없음, 기존 패턴 유지 — setupPlayer가 색까지 책임)
- **dt 기반 이동**: N/A (이번 sprint 무관)
- **SKAction 스폰 패턴**: N/A
- **충돌 후 노드 즉시 삭제 없음**: N/A (변경 없음)
- **HUD 노드 분리**: 준수 (변경 없음)
- **`required init?(coder:)`**: 준수 (override init 추가 시 NSCoding init 의무 충족)
- **SKSpriteNode.color setter**: 준수 (PlayerNode가 SKSpriteNode 상속 — color setter는 표준)

## 빌드 상태
- **xcodebuild 결과**: `** BUILD SUCCEEDED **`
- **scheme**: `GanhoMusic iOS`
- **destination**: `generic/platform=iOS Simulator`
- **경고**: 0건 (필터 `grep -E "warning:|error:"` 결과 0줄, `AppIntents.framework dependency` 시스템 경고만 존재 — 본 변경 무관)
- **에러**: 0건
- **호환성**: macOS/tvOS GameViewController의 `GameScene.newGameScene()` 무인자 호출은 default `= .kim` 덕분에 소스 호환 (수정 불필요)

## 검증 시나리오 (a)~(h) 정적 검증

| # | 시나리오 | 정적 검증 결과 | 상태 |
|---|---|---|---|
| (a) | 기본 kim 진입 | TitleScene init: `selectedCharacterID = .kim` (default). 탭 → `newGameScene(characterID: .kim)` → GameScene init: `self.characterID = .kim` → setupPlayer: `player.color = .kim.color = .ganhoPaper` | ✅ |
| (b) | 이간호 → 시작 | `select(.lee)` → `selectedCharacterID = .lee` → `newGameScene(characterID: .lee)` → `player.color = .lee.color = .ganhoBloodAccent` (빨강) | ✅ |
| (c) | 정간호 → 시작 | `select(.jung)` → `player.color = .jung.color = .ganhoMint` (민트) | ✅ |
| (d) | 임간호 → 시작 | `select(.im)` → `player.color = .im.color = .ganhoYellowF` (노랑) | ✅ |
| (e) | 건간호 → 시작 | `select(.geon)` → `player.color = .geon.color = .ganhoPinkNote` (분홍) | ✅ |
| (f) | 종료 → 재시작 kim 리셋 | endGame → ResultScene → TitleScene 새 인스턴스 → `private var selectedCharacterID: CharacterID = .kim` 기본값으로 매번 재초기화 (`let`/`var` stored property 새 인스턴스마다 init) | ✅ |
| (g) | AIRFORCE 이스터에그 | `triggerAirforceEasterEgg` 본문 0줄 변경. `airforceTriggered` 가드/Airplane/AirforceOverlay/BombFlash/enemy.startFleeing 모두 캐릭터 무관 — 5 캐릭터 어느 쪽이든 정상 발화 | ✅ |
| (h) | 빌드 | `required init?(coder:)` 의무 충족 (Compiler 만족). `init(size:CGSize,characterID:CharacterID)`는 designated init — stored property `characterID` 초기화 후 super.init 호출 순서 준수. `** BUILD SUCCEEDED **` + 경고 0건 | ✅ |

## 학습 가치 메모
- **Constructor Injection (Spring DI 비유)**: TitleScene이 GameScene을 만들 때 생성자 인자로 데이터를 "주입"한다. Spring의 `@Autowired`가 컴파일러 보장 버전.
- **Default parameter value (`= .kim`)**: factory 시그니처에 기본값을 둬서 기존 무인자 호출자(macOS/tvOS)는 손 안 대도 됨. "메서드 오버로딩 없이 선택적 인자".
- **`let` immutable property**: 한 판 안에서 캐릭터를 바꿀 수 없게 컴파일러가 강제. Java의 `final`과 동일 효과.
- **`required init?(coder:) fatalError` 의무**: override init을 추가하면 NSCoding init도 의무. SKS 파일 로드에 미사용이지만 컴파일러 요구.
- **SKSpriteNode.color setter 즉시 재드로우**: PlayerNode를 따로 손대지 않고도 외부에서 색만 바꾸면 다음 프레임에 SpriteKit이 자동으로 텍스처 색을 갱신.

## 범위 외 미구현 항목
- 없음. SPEC In Scope 5항목 모두 구현, OoS 28항목 모두 0줄 변경.
