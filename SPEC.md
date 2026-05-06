# Phase 2-5 — 콤보 시스템 + 점수 ×2

## 개요
음표 수집 시 2.5초 윈도우 안 연속 수집을 추적하는 `combo` 카운터를 도입하고, 콤보 ≥ 3에서 수집한 음표는 +2점, 그 외는 +1점으로 분기한다. HUDNode에 콤보 라벨(`🔥 N`)을 추가하여 콤보 ≥ 2일 때만 표시한다. GDD §8(점수/콤보) 명세를 정확히 구현한다.

## 변경 유형
**게임플레이 + 비주얼 (혼합)** — 콤보 로직(게임플레이) + 콤보 라벨 시각화(비주얼).

## 게임 경험 의도
음표를 2.5초 안에 연속으로 모으면 콤보가 쌓이고, 3콤보부터 점수가 +2(2배)로 가산된다. 콤보 ≥ 2일 때 좌상단에 `🔥 N` 라벨이 등장한다 — 그 전엔 alpha 0으로 숨김. 게임이 단순 수집에서 *연속 압박이 보상*인 구조로 진화한다.

## Sprint 범위 계약

### IN (허용)

#### 1) `Config/GameConfig.swift` — 상수 4개 추가
- 새 MARK 섹션 `// MARK: - Combo (Phase 2-5)`를 파일 마지막 섹션(`// MARK: - HUD (Phase 2-4)`) 뒤에 추가.
- 상수 4개:
  - `static let comboWindow: TimeInterval = 2.5`
  - `static let comboBonusThreshold: Int = 3`
  - `static let scorePerNote: Int = 1`
  - `static let scorePerNoteCombo: Int = 2`
- 기존 다른 상수/섹션 0건 변경.

#### 2) `Nodes/HUDNode.swift` — 콤보 라벨 추가 + update 시그니처 확장

(a) **Properties**: `private let timeLabel: SKLabelNode` 다음 줄에 추가:
```swift
private let comboLabel: SKLabelNode
```

(b) **init**: `timeLabel = SKLabelNode(text: "⏱ 00:45")` 다음 줄에 추가:
```swift
comboLabel = SKLabelNode(text: "🔥 0")
```
`super.init()` 다음의 기존 `configure(scoreLabel)` / `configure(timeLabel)` 다음 줄에 추가:
```swift
configure(comboLabel)
```
위치 설정 — 기존 `timeLabel.position = CGPoint(x: 0, y: -GameConfig.hudFontSize * 1.4)` 다음 줄:
```swift
comboLabel.position = CGPoint(x: 0, y: -GameConfig.hudFontSize * 1.4 * 2)
```
`addChild(timeLabel)` 다음 줄:
```swift
addChild(comboLabel)
```

(c) **update 시그니처 확장**:
```swift
func update(score: Int, remainingTime: TimeInterval, combo: Int) {
    scoreLabel.text = "🎵 \(score)"
    let seconds = max(0, Int(ceil(remainingTime)))
    timeLabel.text = String(format: "⏱ 00:%02d", seconds)
    comboLabel.text = "🔥 \(combo)"
    comboLabel.alpha = combo >= 2 ? GameConfig.hudAlpha : 0
}
```
- 기존 두 줄(scoreLabel.text, timeLabel.text)은 그대로 유지.
- 추가 두 줄(comboLabel.text, comboLabel.alpha)만 신설.

(d) **`configure(_:)` 헬퍼**: 본문 0 변경. 콤보 라벨도 동일 스타일(`.ganhoPaper`, `hudFontSize`, `hudAlpha`, `.left`/`.top`, zPosition 100) 자동 적용.

#### 3) `GanhoMusic Shared/GameScene.swift` — 콤보 로직

(a) **Properties** (MARK: - Properties 안): `private var score: Int = 0` 다음, `private let hud = HUDNode()` 다음 위치에 두 줄 추가:
```swift
private var combo: Int = 0
private var lastCollectAt: TimeInterval = 0   // 0 = "아직 수집 0건". combo > 0 가드와 함께 사용.
```

(b) **`update(_:)` 본문 변경** — 카운트다운 블록 (`if remainingTime <= 0 { endGame(); return }`) 직후, `// 1) D-Pad 입력` 직전에 콤보 만료 검사 블록 삽입:
```swift
// Phase 2-5 — 콤보 윈도우 만료 검사
if combo > 0, currentTime - lastCollectAt > GameConfig.comboWindow {
    combo = 0
}
```
그리고 기존 마지막 줄 `hud.update(score: score, remainingTime: remainingTime)`를 다음으로 교체:
```swift
hud.update(score: score, remainingTime: remainingTime, combo: combo)
```

(c) **`didBegin(_:)` 본문 변경** — 기존 `guard let note = noteBody?.node else { return }` 다음, 기존 `score += 1` 줄을 다음 6줄로 교체 (`note.run(.removeFromParent())`는 마지막에 그대로 유지):
```swift
let now = lastUpdateTime
let isInWindow = combo > 0 && now - lastCollectAt < GameConfig.comboWindow
combo = isInWindow ? combo + 1 : 1
score += combo >= GameConfig.comboBonusThreshold
    ? GameConfig.scorePerNoteCombo
    : GameConfig.scorePerNote
lastCollectAt = now
note.run(.removeFromParent())
```

(d) **`endGame()` 본문 변경** — 기존 마지막 줄 `hud.update(score: score, remainingTime: 0)`을 다음으로 교체:
```swift
hud.update(score: score, remainingTime: 0, combo: 0)
```
- `combo` 변수 자체는 0으로 리셋 안 해도 됨 — gameState != .playing 가드라 update 만료 검사 진입 안 함. 라벨 표시만 0 강제.
- 기존 4줄(`gameState = .gameOver`, `removeAction(forKey: "spawnNotes")`, `player.currentDirection = .zero`, `player.physicsBody?.velocity = .zero`)은 그대로 유지.

### OUT (금지)
- 사운드 (콤보 단계별 음계 C4→A5)
- 콤보 시각 강조 (펄스/색 변화/페이드아웃)
- Best 콤보 / UserDefaults
- 화캉스 보너스 (변기, 콤보 +2)
- 임간호 스킬 A 수집 점수 ×2
- 적 NPC, F 투사체, 청진기
- `Systems/` 폴더 신규 진입 (ScoreSystem 등)
- `ColorTokens` / `PhysicsCategory` / `GameState` / `PlayerNode` / `DPadNode` / `NoteNode` 변경 0바이트
- iOS 3 파일 변경 0바이트
- `project.pbxproj` 변경 0바이트 (신설 파일 0건)
- HUDNode `configure(_:)` 헬퍼 본문 변경 0
- HUDNode 기존 두 라벨(`scoreLabel`, `timeLabel`)의 위치/스타일/text 형식 0 변경

### 판단 기준
"이 변경이 없으면 SPEC 기능이 제대로 동작하지 않는가?" → YES면 허용, NO면 금지.

## 변경 범위

### 수정할 파일
- `GanhoMusic Shared/Config/GameConfig.swift`: 새 MARK + 상수 4개 추가.
- `GanhoMusic Shared/Nodes/HUDNode.swift`: comboLabel property + init 콤보 라벨 초기화/configure/위치/addChild + update 시그니처 확장 + 콤보 라벨 갱신 2줄.
- `GanhoMusic Shared/GameScene.swift`: combo / lastCollectAt 프로퍼티 + update 만료 검사 블록 + hud.update 인자 확장 + didBegin 콤보 갱신 6줄(score += 1 교체) + endGame hud.update 인자 확장.

### 추가할 파일
**없음.** Xcode `project.pbxproj` 변경 0건.

## 기능 상세

### 기능 1: 콤보 카운터 + 윈도우 만료
- 설명: 음표를 마지막으로 수집한 시각(`lastCollectAt`)으로부터 2.5초(`comboWindow`) 이내 다시 수집하면 `combo += 1`. 윈도우 만료되면 `combo = 0`. update 매 프레임 검사.
- 구현 위치: `GameScene.swift` MARK: - Properties (변수 2개), MARK: - Game Loop (만료 검사 블록).
- 핵심 코드 구조:
  ```swift
  // Properties
  private var combo: Int = 0
  private var lastCollectAt: TimeInterval = 0   // 0 = "아직 수집 0건"

  // update(_:) 안 — 카운트다운 다음, player 갱신 전
  if combo > 0, currentTime - lastCollectAt > GameConfig.comboWindow {
      combo = 0
  }
  ```
- `lastCollectAt: TimeInterval = 0` + `combo > 0` 가드 → Optional 회피. 첫 수집 전(combo == 0)엔 만료 검사 자체를 건너뜀.

### 기능 2: didBegin 콤보 갱신 + 점수 분기
- 설명: 음표 수집 시 윈도우 안이면 `combo += 1`, 아니면 `combo = 1`로 시작. 콤보 ≥ 3이면 +2점, 아니면 +1점. 시점 비교는 `lastUpdateTime` 재활용 (didBegin은 update의 currentTime을 직접 받지 않음).
- 구현 위치: `GameScene.swift` MARK: - Contact, `didBegin(_:)` 안 기존 `score += 1` 자리.
- 핵심 코드 구조:
  ```swift
  guard let note = noteBody?.node else { return }
  let now = lastUpdateTime
  let isInWindow = combo > 0 && now - lastCollectAt < GameConfig.comboWindow
  combo = isInWindow ? combo + 1 : 1
  score += combo >= GameConfig.comboBonusThreshold
      ? GameConfig.scorePerNoteCombo
      : GameConfig.scorePerNote
  lastCollectAt = now
  note.run(.removeFromParent())
  ```

### 기능 3: HUDNode 콤보 라벨 (조건부 표시)
- 설명: 좌상단 3번째 줄에 `🔥 N` 라벨. 콤보 ≥ 2일 때만 alpha = `hudAlpha`(0.85), 그 외엔 alpha 0 (숨김). 1콤보는 단순 수집과 같으니 노이즈 회피, 2부터 등장 → 3 도달 시 ×2 발동 학습.
- 구현 위치: `Nodes/HUDNode.swift` MARK: - Properties / MARK: - Init / MARK: - Update.
- 핵심 코드 구조:
  ```swift
  // Properties (timeLabel 다음)
  private let comboLabel: SKLabelNode

  // init (timeLabel 초기화/configure/position/addChild 다음)
  comboLabel = SKLabelNode(text: "🔥 0")
  // super.init() 후
  configure(comboLabel)
  comboLabel.position = CGPoint(x: 0, y: -GameConfig.hudFontSize * 1.4 * 2)
  addChild(comboLabel)

  // update — 시그니처 확장 + 마지막 두 줄 추가
  func update(score: Int, remainingTime: TimeInterval, combo: Int) {
      scoreLabel.text = "🎵 \(score)"
      let seconds = max(0, Int(ceil(remainingTime)))
      timeLabel.text = String(format: "⏱ 00:%02d", seconds)
      comboLabel.text = "🔥 \(combo)"
      comboLabel.alpha = combo >= 2 ? GameConfig.hudAlpha : 0
  }
  ```
- `configure(_:)` 헬퍼 본문 0 변경 — 폰트/색/정렬/zPosition 모두 콤보 라벨에도 자동 적용.

### 기능 4: GameConfig 콤보 상수 4개
- 설명: 매직 넘버 0건 룰 — 2.5/3/1/2 모두 GameConfig 상수로 추출.
- 구현 위치: `Config/GameConfig.swift` 마지막 섹션(`// MARK: - HUD (Phase 2-4)`) 뒤.
- 핵심 코드 구조:
  ```swift
  // MARK: - Combo (Phase 2-5)
  /// 콤보 윈도우 (초). 마지막 수집 후 이 시간 이내 재수집 안 하면 콤보 0. GDD §8.
  static let comboWindow: TimeInterval = 2.5
  /// 콤보 점수 보너스 임계. 이 값 이상부터 점수 ×2. GDD §8.
  static let comboBonusThreshold: Int = 3
  /// 음표 1개 수집 시 가산 점수 (기본). GDD §8.
  static let scorePerNote: Int = 1
  /// 콤보 보너스 발동 시 음표 1개당 가산 점수. GDD §8.
  static let scorePerNoteCombo: Int = 2
  ```

### 기능 5: endGame HUD 인자 확장 + 콤보 라벨 비활성화
- 설명: 시간 만료 시 콤보 라벨도 숨겨야 함. `combo: 0`을 hud.update에 전달 → HUDNode 안 alpha 0 분기로 자동 숨김.
- 구현 위치: `GameScene.swift` MARK: - End, `endGame()` 마지막 줄.
- 핵심 코드 구조:
  ```swift
  hud.update(score: score, remainingTime: 0, combo: 0)
  ```

## 준수 룰 (P0)

- 강제 언래핑 `!` 0건 추가 (`fatalError` 면제, `as!` 별도 0건)
- `Timer` / `print()` / `as!` / `fileprivate` / `DispatchQueue.main.asyncAfter` 0건
- `update(_:)` 안 `addChild()` 0건 — 콤보 라벨 추가는 HUDNode init 안에서만
- 매직 넘버 0건 — 2.5/3/1/2 모두 GameConfig 상수. 라벨 위치 `1.4 * 2`(3번째 줄)는 자명한 산수
- `lastCollectAt: TimeInterval = 0` 초기값 + `combo > 0` 가드 (Optional 회피)
- 콤보 만료 검사 위치: `update(_:)` 안 카운트다운 *다음*, player 갱신 *전*
- didBegin 콤보 시점은 `lastUpdateTime` 재활용 (새 시점 변수 0)
- 콤보 라벨 alpha = `combo >= 2 ? GameConfig.hudAlpha : 0`
- HUDNode `update(score:remainingTime:combo:)` 시그니처 확장 — 모든 호출처(GameScene update + endGame) 명시
- `configure(_:)` 헬퍼는 콤보 라벨에도 1회 호출 (헬퍼 본문 0 변경)
- `combo` 등장 ≥ 6건 (Properties 1, update 만료 검사 2, hud.update 인자 1, didBegin 갱신 4, endGame 인자 1, HUDNode update 시그니처 1, HUDNode 라벨 갱신 2)
- `comboWindow` 등장 ≥ 2건 (update 만료 검사 1, didBegin isInWindow 1)
- `comboBonusThreshold` 등장 1건 (didBegin 점수 분기)
- `scorePerNote` 등장 1건, `scorePerNoteCombo` 등장 1건
- 함수 단위 MARK 주석 변경 0 (기존 섹션 그대로)

## 회귀 보존 (1-3 핫픽스 + 1-5 + 2-1 + 2-2 + 2-3 + 2-4)

- `Nodes/PlayerNode.swift` / `Nodes/DPadNode.swift` / `Nodes/NoteNode.swift` 0바이트 변경
- `Config/PhysicsCategory.swift` / `Config/GameState.swift` / `Config/ColorTokens.swift` 0바이트 변경
- iOS 3 파일 (`AppDelegate.swift` / `GameViewController.swift` / `Main.storyboard`) 0바이트 변경
- `project.pbxproj` 0바이트 변경 (신설 파일 0건 → Xcode 멤버십 trigger 안 됨)
- 1-3 핫픽스 `scaleMode = .resizeFill` 유지 (`newGameScene()`)
- 1-5 카메라 드론 follow `cameraNode.position = player.position` 유지
- 2-1 외곽 벽 4개 그대로 (`addOuterWalls()`)
- 2-2 중앙 기둥 + `physicsWorld.gravity = .zero` 그대로 (`addCentralPillar()`, `didMove`)
- 2-3 spawn loop + didBegin의 bodyA/B/noteBody 식별 로직 그대로 (`startSpawnLoop`, `trySpawnNote`, `currentNoteCount`, `randomNotePosition`, `didBegin` 식별 부분)
- 2-4 HUDNode 기존 두 라벨(`scoreLabel`, `timeLabel`) 위치/스타일/text 형식 그대로 + setupHUD 좌표 그대로 + endGame 5줄 중 4줄(`gameState = .gameOver`, `removeAction`, `player.currentDirection = .zero`, `player.physicsBody?.velocity = .zero`) 그대로 — `hud.update` 인자만 확장

## 주의사항

### Swift / SpriteKit 함정
- `lastCollectAt = 0` 초기값은 시점 비교상 의미 부정확하지만 `combo > 0` 가드로 안전. 주석 명시 필수 (`// 0 = "아직 수집 0건". combo > 0 가드와 함께 사용.`).
- didBegin은 update의 `currentTime`을 직접 받지 않음 — `lastUpdateTime` 재활용. 1프레임(16ms) 지연은 콤보 윈도우 2500ms 대비 무시 가능.
- update 안에서는 `currentTime` 매개변수를 직접 사용 (만료 검사). didBegin에서는 `lastUpdateTime` 사용. 의도 차이 — update는 *지금*, didBegin은 *마지막 update 시점*.
- 콤보 라벨 `alpha` 변경(셰이더 단계)은 매 프레임 비용 0. `isHidden` 토글은 SpriteKit 트리 갱신 비용 발생 → alpha 분기 선택.
- 삼항 연산자 줄바꿈 시 들여쓰기 정렬 필수 (`? scorePerNoteCombo` / `: scorePerNote` 동일 들여쓰기).

### 빌드 / 시그니처 호출처
- `hud.update(score:remainingTime:)` 호출처는 GameScene 내 2곳: `update(_:)` 마지막 줄 + `endGame()` 마지막 줄. 두 곳 모두 `combo:` 인자 추가 — 빠뜨리면 컴파일 에러.
- HUDNode `init`에서 `comboLabel` 초기화 누락 시 stored property 미초기화 컴파일 에러. `super.init()` 전에 반드시 할당 (Swift 초기화 규칙).

### 게임 경험
- 콤보 0→1 전환에선 라벨 등장 안 함 (alpha 0 유지) → 자연스러움. 1→2 전환 시점에 라벨 등장.
- gameOver 진입 시 `combo` 변수 자체 리셋은 안 함 — `gameState != .playing` 가드로 update 만료 검사 진입 안 함. 라벨 표시만 `combo: 0` 인자로 강제 숨김.
- 시간 만료(00:00) 직후 콤보 라벨도 함께 사라져야 자연스러움 — endGame `combo: 0` 전달로 처리.

### 결정 6건 확정 (학습 노트 §7 추천대로)
- ① 콤보 윈도우/임계/가산: GDD §8 명세 그대로 (2.5 / 3 / +1 / +2) ⭐
- ② 콤보 라벨 표시: ≥ 2부터 보임 ⭐
- ③ 콤보 시점 변수: `lastUpdateTime` 재활용 + `lastCollectAt` 신규 ⭐
- ④ 콤보 라벨 위치: 시간 라벨 다음(3번째 줄, `-hudFontSize * 1.4 * 2`) ⭐
- ⑤ 콤보 시각 강조: 단순 등장만 (펄스/색/페이드 없음) ⭐
- ⑥ 콤보 라벨 폰트/색: 점수/시간과 동일 (configure 헬퍼 그대로) ⭐
