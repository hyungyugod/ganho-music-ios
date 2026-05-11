# Phase 5-2 — 선택 캐릭터 색을 PlayerNode에 적용 (Constructor Injection)

## 개요
Phase 5-1에서 만든 TitleScene 캐릭터 선택(`selectedCharacterID`)을 GameScene에 init 주입으로 전달하고, `setupPlayer()`에서 `player.color = characterID.color` 1줄로 PlayerNode 몸체 색을 즉시 반영한다.

## 변경 유형
**혼합** — Swift constructor injection + PlayerNode 색 1줄.

## 게임 경험 의도
TitleScene에서 5명 카드 중 하나를 고르고 화면 외 영역을 탭하면 GameScene 진입 시 김간호(PlayerNode)의 *몸 색*이 선택한 캐릭터 색으로 *즉시* 바뀐다. 기본 `.kim`(`.ganhoPaper`). 게임 로직(이동·물리·스폰·충돌·스킬·적 AI)은 5-1과 완전 동일.

## Sprint 범위 계약

### In Scope (모두 필수)
- `GameScene`에 `let characterID: CharacterID` 프로퍼티 추가
- `init(size:characterID:)` 신설 + `required init?(coder:) fatalError`
- `newGameScene(characterID:)` factory 시그니처 확장 (default `= .kim`)
- `GameScene+Setup.setupPlayer()` 본문에 `player.color = characterID.color` 1줄
- `TitleScene.touchesBegan` 안 `newGameScene()` 호출에 `characterID: selectedCharacterID` 인자 전달

### Out of Scope (위반 시 P0)
- `PlayerNode.swift` 본문 변경 (`color`는 SKSpriteNode 표준 property)
- 기타 모든 노드(Enemy/StoneGuard/Note/Projectile/HUD/DPad/Airplane/AirforceOverlay/BombFlash/CharacterCard) 변경
- `CharacterID` enum 변경 (5-1 그대로)
- `GameConfig` 새 상수
- `ColorTokens` 새 토큰
- `ResultScene` 변경
- 시스템(`ContactRouter`/`SpawnSystem`/`ScoreSystem`) 변경
- 영구 저장 (UserDefaults/Repository 신설)
- 스킬 시스템 / 캐릭터별 게임 로직 (속도·충돌 차등)
- 외형 디테일 (가운/머리 등)
- 카드 시각 강화
- `TitleScene`의 다른 부분 변경 (5-1 카드 setup/layout/hit test 그대로)
- `GameScene+Setup`의 다른 setup 메서드 변경
- `GameScene`의 다른 메서드 변경 (`didMove`/`update`/`endGame`/`configureContactRouter`/`triggerAirforceEasterEgg` 0줄)
- `pbxproj` 변경
- macOS / tvOS Sources phase
- Test 코드

### 판단 기준
"이 변경이 없으면 'TitleScene에서 선택한 캐릭터 색이 게임 시작 시 PlayerNode 몸체에 반영됨'이 동작하는가?" → NO만 In Scope.

## 변경 범위
- 수정: `GameScene.swift` (~10줄: 헤더 1 + 프로퍼티 1 + init 4 + required init 3 + factory 시그니처)
- 수정: `GameScene+Setup.swift` (+1줄)
- 수정: `Scenes/TitleScene.swift` (+1줄, -1줄)
- pbxproj 변경 0

## 기능 상세

### 기능 1: GameScene 헤더 / 프로퍼티 / init / factory

- **헤더 1줄 추가** (`Phase 4-7` 라인 다음):
```swift
//  Phase 5-2 · 선택 캐릭터 init 주입 + PlayerNode 색 적용 (constructor injection)
```

- **Properties 추가** (기존 시스템 섹션 다음, `airforceTriggered` 위 또는 적절히):
```swift
/// Phase 5-2 — TitleScene이 init으로 주입한 선택 캐릭터.
/// PlayerNode 색 등 캐릭터별 시각/로직 적용에 사용. 한 판 안에서 불변(`let`).
let characterID: CharacterID
```

- **`// MARK: - Init` 섹션 신설** (Factory 섹션 *위*):
```swift
// MARK: - Init
/// Phase 5-2 — characterID 주입형 init. newGameScene factory가 호출.
/// Swift 규칙: stored property(`self.characterID`) 초기화 → 그 다음 `super.init`.
init(size: CGSize, characterID: CharacterID) {
    self.characterID = characterID
    super.init(size: size)
}

required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
}
```

- **`newGameScene` factory 시그니처 교체**:
```swift
// Before:
class func newGameScene() -> GameScene {
    let scene = GameScene(size: CGSize(width: 1024, height: 768))
    scene.scaleMode = .resizeFill
    return scene
}

// After:
class func newGameScene(characterID: CharacterID = .kim) -> GameScene {
    let scene = GameScene(size: CGSize(width: 1024, height: 768), characterID: characterID)
    scene.scaleMode = .resizeFill
    return scene
}
```

### 기능 2: GameScene+Setup.setupPlayer 본문 1줄

- **구현 위치**: `setupPlayer()` 안, `player.position = ...` 다음, `worldNode.addChild(player)` *이전*
- **최종 형태**:
```swift
func setupPlayer() {
    player.position = CGPoint(
        x: GameConfig.mapWidth  / 4,
        y: GameConfig.mapHeight / 2
    )
    player.color = characterID.color   // ← Phase 5-2 추가 (1줄)
    worldNode.addChild(player)
}
```
- 다른 setup 메서드(setupBackground/setupWorld/addOuterWalls/addCentralPillar/setupCamera/setupDPad/setupHUD/setupEnemy/setupStoneGuard) 0줄 변경

### 기능 3: TitleScene — newGameScene 호출 1줄 교체

- **구현 위치**: `touchesBegan(_:with:)` 안 "그 외 영역 — 기존 동작" 블록
- **변경**:
```swift
// Before:
let gameScene = GameScene.newGameScene()
// After:
let gameScene = GameScene.newGameScene(characterID: selectedCharacterID)
```
- TitleScene 다른 부분(`selectedCharacterID` 프로퍼티, 카드 setup/layout/select/hit test, isTransitioning 가드 등) 0줄 변경

## 검증 시나리오 (a)~(h)

| # | 시나리오 | 정적 검증 | 시뮬 기대값 |
|---|---|---|---|
| (a) | 기본 kim 진입 | `selectedCharacterID = .kim`(default) → `newGameScene(characterID: .kim)` → `player.color = .ganhoPaper` | PlayerNode 가운 흰색 |
| (b) | 이간호 → 시작 | `select(.lee)` → `player.color = .ganhoBloodAccent` | 빨강 |
| (c) | 정간호 → 시작 | `select(.jung)` → `player.color = .ganhoMint` | 민트 |
| (d) | 임간호 → 시작 | `select(.im)` → `player.color = .ganhoYellowF` | 노랑 |
| (e) | 건간호 → 시작 | `select(.geon)` → `player.color = .ganhoPinkNote` | 분홍 |
| (f) | 종료 → 재시작 kim 리셋 | TitleScene 새 인스턴스 → `selectedCharacterID` 기본 `.kim` | 매 진입 kim |
| (g) | AIRFORCE 이스터에그 | `triggerAirforceEasterEgg` 0줄 변경, 캐릭터 무관 | 모든 캐릭터 정상 |
| (h) | 빌드 | required init?(coder:) 의무 충족 | SUCCEEDED + 경고 0 |

## 학습 가치
- Constructor injection (`init(size:characterID:)`)
- Default parameter value (`= .kim`)
- `let` immutable property
- `required init?(coder:) fatalError` 의무 (override init 추가 시)
- SKSpriteNode.color setter 즉시 재드로우
- 캡슐화 트레이드오프 (직접 set vs 메서드)

## 주의사항
- **init 본문 순서**: `self.characterID = characterID` 먼저, `super.init(size: size)` 다음 (Swift 규칙)
- **`required init?(coder:)` 의무**: override init 추가 시 NSCoding init도 정의해야 컴파일
- **factory default `.kim`**: 호환성 유지
- **player.color setter 위치**: position 다음, addChild *이전*
- **PlayerNode 본문 0줄**: `color`는 SKSpriteNode 표준
- **호출자 최소 변경**: TitleScene 1줄 외 0
- **강제 언래핑 / Timer / 매직 넘버**: 0건
