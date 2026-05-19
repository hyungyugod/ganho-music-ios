# Sprint 3 — 인게임 화면(GameScene + HUD + 컨트롤 + 게임 오브젝트) 디자인 리뉴얼

## 개요

`mockups/game-map-v2.html` 시각 매칭. 인게임 화면의 체크보드 바닥/외곽 벽/장식 기둥, HUD 4슬롯, D-Pad(우하단), 스킬 버튼(좌하단), 음표, F 투사체, 콤보 팝업, 일시정지 버튼을 v2 디자인 시스템(웜 피치·코랄·골드·navy)으로 재스타일링한다. 게임 로직/물리/저장/AI/스폰/충돌은 단 한 줄도 건드리지 않는다. 본 Sprint는 회귀 위험이 가장 큰 단계이므로 OUT 섹션을 광범위하게 명시한다.

## 변경 유형

**비주얼 (인게임 시각 갱신, 게임 로직 회귀 0)**

DESIGN_RENEWAL_REQUEST.md §11 채점표 기준: 게임 로직 회귀(40%) · Swift 패턴(20%) · 비주얼 일관성(25%) · 가독성·UX(15%).

## 게임 경험 의도

이전엔 다크 배경 + 픽셀 톤이 인게임에서도 차갑게 떨어졌다. 이번 Sprint는 메뉴 화면(Sprint 2)의 따뜻한 웜 피치-라벤더 톤이 인게임에서도 그대로 이어져 *한 게임의 한 톤*을 완성한다. 음표는 골드 글로우로 시선을 자석처럼 끌고, HUD 4슬롯은 navy 칩 위 골드 라벨로 가독성을 살리며 TIME 12초 이하부터 코랄로 전환되어 *시간이 줄어든다*를 즉각 인지시킨다. D-Pad는 우하단(엄지)·스킬 버튼은 좌하단(검지)로 두 손 자연 위치를 확립한다.

## Sprint 3 범위 계약

### IN (Sprint 3에서 하는 것 — 시각 변경만)

1. **`GameConfig.swift`**: 체크보드 hex 2개 교체 + Sprint 3 시각 신규 상수 약 30개 추가.
2. **`GameScene+Setup.swift`**:
   - `setupBackground()`: `.ganhoBgDeep` → 단색 `.ganhoBgWarmTop` (카메라 follow와 그라데이션 노드 충돌 회피).
   - `addCheckerboardFloor()` 내부: floor hex 토큰을 ColorTokens의 `ganhoFloorPeachA/B` 직접 참조 또는 GameConfig 교체된 hex 그대로.
   - `addOuterWalls()`: `.ganhoPaper` → `.ganhoNavyDeep` 색 교체 + 외곽 라운드 보더 SKShapeNode 1개 추가 (physicsBody 0).
   - `addRectPillar()` / `addCentralPillar()`: 색 `.ganhoNavyDeep`로 교체. PhysicsBody/policy 0건 변경.
3. **`GameScene.swift`**:
   - 신규 `pauseButton: PauseButtonNode` 프로퍼티.
   - `setupPauseButton()` + `layoutPauseButton()` 신설. cameraNode 자식 우상단.
   - **OUT 명시**: 실제 일시정지 로직 미구현. 시각 placeholder만.
   - `didMove(to:)`에 `setupPauseButton()` 한 줄 추가, `didChangeSize(_:)`에 `layoutPauseButton()` 한 줄 추가.
4. **`HUDNode.swift`** + `HUDSlotNode`:
   - 슬롯 navy 0.78 알약 배경 (rectOf cornerRadius 14).
   - 라벨 Jua 10pt 골드.
   - 값 Jua 18pt 흰색.
   - TIME 슬롯 12초 이하: 배경 색 `ganhoCoralShadow.alpha(0.85)`로 swap.
   - TIME 슬롯 하단 진행바 (xScale 갱신).
   - 외부 인터페이스 시그니처 **절대 변경 금지**.
   - HUDSlotNode init에 `showTimeBar: Bool = false` default 파라미터 추가 (호환성 100%).
5. **`DPadNode.swift`**:
   - 4방향 버튼 SKSpriteNode → SKShapeNode 교체 (white 0.75 fill + navy α 0.25 stroke + cornerRadius).
   - 중앙 데드존 SKShapeNode 추가 (navy α 0.4 cornerRadius 6).
   - **touch 이벤트와 `updateDirection(forTouchLocation:)` 알고리즘은 한 줄도 변경 금지**.
6. **`SkillButtonNode.swift`**:
   - 본체 SKShapeNode(circleOfRadius: 36) — 코랄 fill + white α 0.8 stroke.
   - 라벨 Jua 18pt 흰색.
   - 우상단 `DarkContextChipNode(label: "B")` 자식.
   - 본체 아래 `DarkContextChipNode(label: skill 이름 + CD 텍스트)` 자식.
   - `onTap`/`isEnabled`/`configure(skill:)`/`setEnabled(_:)` 시그니처 **절대 변경 금지**.
7. **`HUDSkillSlotNode.swift`**:
   - 폰트 fontName 명시 (`fontDisplay`).
   - 진행 링 색을 ColorTokens v2(`ganhoCoralPrimary`/`ganhoMusicGold`)로 매핑.
   - `configure/update(progress:)` 시그니처/분기 보존.
8. **`NoteNode.swift`**:
   - 시각 자식 3개 추가: 글로우(z=-1) + 본체 골드 원 + 흰 링 (lineWidth=2).
   - 본체 `SKSpriteNode.color = .clear`.
   - 펄스 SKAction `repeatForever` 부착 (withKey 멱등).
   - **PhysicsBody size/category/contact/dynamic 절대 보존**.
9. **`ProjectileNode.swift`**:
   - 시각 자식 2개 추가: 코랄 22×22 라운드 사각형 + 흰 "F" Jua 14pt 라벨.
   - `zRotation = -12°` 회전.
   - **PhysicsBody size = projectileSize 절대 보존** (시각 자식 22pt와 분리).
   - `applyEnchanted/clearEnchanted` 동작: 자식 SKShape.fillColor 교체로 시각만 옮김. 시그니처/타이밍 0건 변경.
10. **`ComboPopupNode.swift`**:
    - fontName = `fontDisplay`, fontSize = 32 (신규 상수, 기존 48 상수는 보존).
    - color 4단계 분기 v2 토큰 매핑.
    - navy 외곽선 4방향 1pt 오프셋 자식 4개.
    - `zRotation = -8°`.
    - `animate()` SKAction 본문 0건 변경.
11. **`ComboBreakNode.swift`**:
    - fontName = `fontDisplay`, fontSize = 28 (신규 상수).
    - color → `ganhoCoralShadow`.
    - 동일 navy 외곽선 시뮬레이션.
    - `animate()` 본문 0건 변경.
12. **`PauseButtonNode.swift`** (신규):
    - final class : SKNode.
    - SKShapeNode 32×32 navy α 0.78 + 흰 || 두 줄.
    - `isUserInteractionEnabled = false` (Sprint 3 시각만).

### OUT (Sprint 3에서 절대 하지 않는 것)

#### 게임 수치 (DESIGN_RENEWAL_REQUEST.md §6.1 — 한 줄도 무변)
- `scorePerNote`, `scorePerNoteCombo`
- `comboWindow`, `comboBonusThreshold`, `comboMilestones`, `comboBreakThreshold`
- `projectileSpeed`, `projectileSize` (16 그대로 — PhysicsBody size)
- F 투사체 발사 주기 difficulty별
- `tileSize`(20), `mapColumns/Rows` (48/24), `mapWidth/Height`
- `gameDuration`(45), 카운트다운
- `noteSize`(16), `tensionWindow`(12), `tensionRate*`

#### 게임 로직 (§6.2)
- `ContactRouter` 충돌 분기, `PhysicsCategory` bitmask
- `PlayerSkill` 4종 효과/쿨다운/duration/oncePerGame
- `Difficulty` 분기 (easy/normal/hard)
- `EnemyNode/ProfessorNode/StoneGuardNode` AI/이동/patrol
- 저장소 5개 (HighScore/Statistics/PerDifficultyScore/Graduation/CharacterPreference) 저장 키/구조
- `SpawnSystem` 내부, `ScoreSystem` 내부, `SkillSystem` 내부
- 씬 전환 로직
- 컷씬 본문/onDismiss 흐름

#### 좌표·물리·카메라
- 48×24 타일, tileSize=20pt, 원점 좌하단
- `worldNode`/`cameraNode` 구조와 카메라 follow
- 모든 PhysicsBody size/category/contact/collision/isDynamic/friction/restitution/linearDamping
- `setupCamera()` 위치

#### 사운드·햅틱
- `BGMPlayer` 호출, `AudioManager.play`, `HapticsManager.*` 모든 호출 지점

#### Sprint 1/2 보호 자산
- `ColorTokens` 16개 토큰 hex
- `GameConfig` 폰트 3개 + Sprint 1/2 상수 약 70개 (참조만)
- Sprint 1 컴포넌트 6개 내부
- StartScene / CharacterSelectScene / SkillExplanationScene git diff 0줄
- ResultScene / DiplomaOverlayNode git diff 0줄

#### 입력 시스템
- `DPadNode.touchesBegan/Moved/Ended/Cancelled`, `updateDirection`, `currentDirection`
- `SkillButtonNode.touchesBegan(_:with:)` 본문, `onTap` 발화 시점
- `GameScene.update`의 입력 가드 블록 (`if !skillSystem.isDashing && !player.isFrozen`)

---

## 불변 계약 표 (Evaluator 회귀 검증용)

### 게임 수치 보존
| 항목 | 검증 |
|---|---|
| scorePerNote / scorePerNoteCombo / comboWindow / comboMilestones / comboBreakThreshold / projectileSpeed / projectileSize / tileSize / mapColumns / mapRows / gameDuration / noteSize / tensionWindow | grep 후 미변경 |
| checkerboardFloorAHex/BHex | 두 줄만 v2로 hex 교체 (#FFEFE0 / #FFDFC8) |

### 물리/로직 보존
| 노드 | 검증 |
|---|---|
| NoteNode | PhysicsBody rectangleOf(noteSize²), isDynamic=false, category=note, collision=0, contactTest=player, name="note", `applyLifetime` 보존 |
| ProjectileNode | PhysicsBody rectangleOf(projectileSize²)=16, isDynamic=true, allowsRotation=false, category=projectile, collision=0, contactTest=player\|wall, name="projectile", `applyEnchanted/clearEnchanted/isEnchanted` 보존 |
| Walls/Pillars | PhysicsBody size/policy 보존 |
| DPadNode | 4 touch 메서드 본문/`updateDirection` 알고리즘/`currentDirection` 타입 정확 보존 |
| HUDNode | `update(score:remainingTime:combo:)`/`setCharacterName`/`startTensionBlink`/`stopTensionBlink` 시그니처 보존 |
| SkillButtonNode | `configure(skill:)`/`setEnabled(_:)`/`onTap`/`isUserInteractionEnabled` 보존 |
| HUDSkillSlotNode | `configure(skill:)`/`update(progress:)` 4상태 분기 보존 |
| ComboPopupNode/ComboBreakNode | `animate()` SKAction 본문 보존 |

### 호출자 보존 (GameScene 본체)
| 위치 | 보존 |
|---|---|
| `update(_:)` | 0줄 변경 |
| `endGame()` | 0줄 변경 |
| `configureContactRouter()` | 0줄 변경 |
| `setupWorld/setupMap/setupPlayer/setupEnemy/setupStoneGuard/setupProfessor/setupCamera/setupDPad/setupHUD/setupSkillButton/setupHUDSkillSlot` | 호출 흐름 0건 변경 |
| `setupBackground` | 색 한 줄 교체만 허용 |
| `addNormalMap/addHardMap/addCentralPillar` | 좌표 0건 변경 |
| `didMove(to:)` | setupPauseButton 한 줄 추가만 허용 |
| `didChangeSize(_:)` | layoutPauseButton 한 줄 추가만 허용 |

---

## 파일별 변경 명세

### 1. `Config/GameConfig.swift`

#### 1.1 체크보드 hex 교체
```swift
static let checkerboardFloorAHex: String = "#FFEFE0"  // (was #1a1722)
static let checkerboardFloorBHex: String = "#FFDFC8"  // (was #13111a)
```

#### 1.2 Sprint 3 신규 상수
```swift
// MARK: - Sprint 3 · v2 Game Visual

// HUD 슬롯 칩
static let hudSlotBgAlpha: CGFloat = 0.78
static let hudSlotCornerRadius: CGFloat = 14
static let hudSlotWidth: CGFloat = 78
static let hudSlotHeight: CGFloat = 44
static let hudSlotV2LabelFontSize: CGFloat = 10
static let hudSlotV2ValueFontSize: CGFloat = 18
static let hudSlotV2LabelColor: UIColor = .ganhoMusicGold
static let hudSlotV2ValueColor: UIColor = .white
static let hudSlotWarnBgAlpha: CGFloat = 0.85
static let hudTimeBarHeight: CGFloat = 3
static let hudTimeBarTopGap: CGFloat = 3
static let hudTimeBarBgAlpha: CGFloat = 0.18

// D-Pad v2
static let dpadCenterDeadzoneSize: CGFloat = 32
static let dpadCenterDeadzoneAlpha: CGFloat = 0.4
static let dpadCenterDeadzoneCornerRadius: CGFloat = 6
static let dpadButtonFillAlpha: CGFloat = 0.75
static let dpadButtonStrokeAlpha: CGFloat = 0.25
static let dpadButtonCornerRadius: CGFloat = 10
static let dpadButtonStrokeLineWidth: CGFloat = 2

// Skill Button v2
static let skillButtonV2Radius: CGFloat = 36
static let skillButtonV2StrokeWidth: CGFloat = 3
static let skillButtonV2KeyLabelOffset: CGFloat = 28
static let skillButtonNameChipOffsetY: CGFloat = -52
static let skillButtonKeyText: String = "B"

// Pause Button v2
static let pauseButtonSize: CGFloat = 32
static let pauseButtonCornerRadius: CGFloat = 10
static let pauseButtonBgAlpha: CGFloat = 0.78
static let pauseButtonBarWidth: CGFloat = 4
static let pauseButtonBarHeight: CGFloat = 14
static let pauseButtonBarGap: CGFloat = 2
static let pauseButtonMarginX: CGFloat = 28
static let pauseButtonMarginY: CGFloat = 18

// Note v2
static let noteV2GlowRadius: CGFloat = 16
static let noteV2GlowAlpha: CGFloat = 0.5
static let noteV2RingLineWidth: CGFloat = 2
static let noteV2PulseDuration: TimeInterval = 1.4
static let noteV2PulseScale: CGFloat = 1.08
static let noteV2PulseActionKey: String = "noteV2Pulse"

// Projectile v2
static let projectileV2VisualSize: CGFloat = 22
static let projectileV2CornerRadius: CGFloat = 6
static let projectileV2RotationDegrees: CGFloat = -12
static let projectileV2LabelText: String = "F"
static let projectileV2LabelFontSize: CGFloat = 14

// ComboPopup v2 / ComboBreak v2
static let comboPopupV2FontSize: CGFloat = 32
static let comboBreakV2FontSize: CGFloat = 28
static let comboPopupV2OutlineWidth: CGFloat = 1
static let comboPopupV2RotationDegrees: CGFloat = -8

// Outer wall border
static let outerWallBorderLineWidth: CGFloat = 3
static let outerWallBorderCornerRadius: CGFloat = 18
```

> **금지**: 기존 `hudValueFontSize`, `hudLabelFontSize`, `comboPopupFontSize` 등 *기존 상수의 값* 변경. 새 v2 상수 추가만. (체크보드 hex 2개만 예외 — DESIGN_RENEWAL_REQUEST §4.4 명시)

### 2. `GameScene+Setup.swift`

#### 2.1 `setupBackground()`
```swift
backgroundColor = .ganhoBgWarmTop
```
> 인게임은 카메라 follow가 있어서 GradientBackgroundNode를 worldNode 자식으로 두면 카메라 따라 움직임이 어색. 단색 backgroundColor가 안정.

#### 2.2 `addCheckerboardFloor()` — 색만 교체
- 1152개 노드 생성 루프 / zPosition / physicsBody 미부착 정책 **0건 변경**.
- floor 색은 ColorTokens의 `ganhoFloorPeachA/B` 또는 GameConfig 교체된 hex 그대로 참조.

#### 2.3 `addOuterWalls()`
- 4개 `SKSpriteNode.color = .ganhoNavyDeep` 교체.
- PhysicsBody, size, position 0건 변경.
- 함수 끝에 외곽 라운드 보더 SKShapeNode 1개 부착(physicsBody 0, zPosition -50):
  ```swift
  let borderRect = CGRect(x: 0, y: 0, width: GameConfig.mapWidth, height: GameConfig.mapHeight)
  let border = SKShapeNode(rect: borderRect, cornerRadius: GameConfig.outerWallBorderCornerRadius)
  border.strokeColor = .ganhoNavyDeep
  border.lineWidth = GameConfig.outerWallBorderLineWidth
  border.fillColor = .clear
  border.zPosition = -50
  worldNode.addChild(border)
  ```

#### 2.4 `addRectPillar()` / `addCentralPillar()`
- `SKSpriteNode.color = .ganhoNavyDeep`로 교체.
- PhysicsBody/breakable name 0건 변경.

#### 2.5 `setupPauseButton()` / `layoutPauseButton()` 신설
```swift
func setupPauseButton() {
    cameraNode.addChild(pauseButton)
    layoutPauseButton()
}

func layoutPauseButton() {
    let halfW = size.width / 2
    let halfH = size.height / 2
    pauseButton.position = CGPoint(
        x: +(halfW - GameConfig.pauseButtonMarginX),
        y: +(halfH - GameConfig.pauseButtonMarginY)
    )
}
```

### 3. `GameScene.swift`

#### 3.1 신규 프로퍼티 1개
```swift
let pauseButton = PauseButtonNode()
```

#### 3.2 `didMove(to:)` 끝에 한 줄 추가
```swift
setupPauseButton()
```

#### 3.3 `didChangeSize(_:)` 한 줄 추가
```swift
layoutPauseButton()
```

> `update(_:)`, `endGame()`, `configureContactRouter()`, 컷씬 메서드, `triggerComboBreak`, `playComboMilestoneFeedback` 등 **한 줄도 안 건드린다**.

### 4. `Nodes/HUDNode.swift` (+ `HUDSlotNode`)

#### 4.1 HUDSlotNode init 시그니처 변경
```swift
init(label: String, initialValue: String, showTimeBar: Bool = false)
```
호환성 100%. 기존 호출(HUDNode init 4개) 중 timeSlot만 `showTimeBar: true` 변경.

#### 4.2 HUDSlotNode 자식 추가
- `backgroundChip: SKShapeNode` — navy 0.78 알약 (zPosition 99)
- 라벨/값 fontName = `GameConfig.fontDisplay`, fontColor 매핑
- 라벨 fontSize = `hudSlotV2LabelFontSize` (10)
- 값 fontSize = `hudSlotV2ValueFontSize` (18)
- showTimeBar=true 시 timeBarBg + timeBarFill SKSpriteNode 2개 자식 추가

#### 4.3 신규 메서드 2개
```swift
func setWarn(_ on: Bool) {
    backgroundChip.fillColor = on
        ? UIColor.ganhoCoralShadow.withAlphaComponent(GameConfig.hudSlotWarnBgAlpha)
        : UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.hudSlotBgAlpha)
}

func setTimeBar(progress: CGFloat) {
    timeBarFill?.xScale = max(0, min(1, progress))
}
```

#### 4.4 HUDNode.update — 끝에 블록 추가
```swift
let warn = remainingTime <= GameConfig.tensionWindow
timeSlot.setWarn(warn)
let progress = CGFloat(remainingTime / GameConfig.gameDuration)
timeSlot.setTimeBar(progress: progress)
```

콤보 hot 색 매핑 / tensionBlink 색을 v2 토큰(`ganhoMusicGold` ↔ `white`)로 교체. 시그니처 0 변경.

### 5. `Nodes/DPadNode.swift`

- 4 SKSpriteNode → 4 SKShapeNode 교체 (rectOf cornerRadius).
- fillColor white α 0.75, strokeColor navy α 0.25, lineWidth 2.
- 중앙 데드존 SKShapeNode 1개 추가 (z=0, navy α 0.4).
- 각 버튼 내 작은 화살표 SKLabelNode 자식(선택, fontDisplay 14pt navy).
- `name` ("dpadUp/Down/Left/Right") 유지.
- position offset 산출 그대로.
- `alpha`, `isUserInteractionEnabled` 그대로.
- **touch 메서드 4개 본문 + `updateDirection(forTouchLocation:)` 0건 변경**.

### 6. `Nodes/SkillButtonNode.swift`

- 본체 `backgroundNode: SKShapeNode(circleOfRadius: skillButtonV2Radius)`.
- fillColor `.ganhoCoralPrimary`, strokeColor white α 0.8, lineWidth 3.
- 중앙 `labelNode`: fontName = fontDisplay, fontColor white, fontSize 18. 텍스트는 짧게 (skill displayName 첫 글자 또는 "🎵").
- 신규 자식 `keyLabelChip: DarkContextChipNode(label: "B")` 우상단 (skillButtonV2KeyLabelOffset).
- 신규 자식 `nameTagChip: DarkContextChipNode(label: skill.displayName + " · CD …초")` 본체 아래 (skillButtonNameChipOffsetY).
- `configure(skill:)` 호출 시 keyLabelChip/nameTagChip 업데이트.
- `setEnabled(_:)`/`onTap`/`isUserInteractionEnabled`/`touchesBegan` 시그니처 정확 보존.

### 7. `Nodes/HUDSkillSlotNode.swift`

- labelNode/valueNode 둘 다 fontName = fontDisplay 명시.
- ringFillNode 분기 색을 v2 토큰으로:
  - READY: `ganhoMusicGold` stroke + α 0.15 fill
  - 쿨다운 중: `ganhoCoralPrimary` stroke + clear fill
  - USED: alpha 0
- `configure/update(progress:)` 시그니처/4상태 분기 본문 그대로.

### 8. `Nodes/NoteNode.swift`

```swift
// init() 끝에 자식 3개 추가 (physicsBody 부착 이후)

let glow = SKShapeNode(circleOfRadius: GameConfig.noteV2GlowRadius)
glow.fillColor = UIColor.ganhoMusicGold.withAlphaComponent(GameConfig.noteV2GlowAlpha)
glow.strokeColor = .clear
glow.zPosition = -1
glow.blendMode = .add
addChild(glow)

let core = SKShapeNode(circleOfRadius: GameConfig.noteSize / 2)
core.fillColor = .ganhoMusicGold
core.strokeColor = .white
core.lineWidth = GameConfig.noteV2RingLineWidth
core.zPosition = 0
addChild(core)

let scaleUp = SKAction.scale(to: GameConfig.noteV2PulseScale,
                              duration: GameConfig.noteV2PulseDuration / 2)
let scaleDown = SKAction.scale(to: 1.0,
                                duration: GameConfig.noteV2PulseDuration / 2)
let pulse = SKAction.sequence([scaleUp, scaleDown])
run(.repeatForever(pulse), withKey: GameConfig.noteV2PulseActionKey)
```

- 본체 `SKSpriteNode.color = .clear`로 변경 (시각 위임).
- **PhysicsBody size = noteSize²**, isDynamic=false, category=note, name="note" 정확 보존.
- `applyLifetime(_:)` 시그니처/본문 정확 보존.

### 9. `Nodes/ProjectileNode.swift`

```swift
// init() 끝에 자식 2개 + zRotation 추가

let body = SKShapeNode(
    rectOf: CGSize(width: GameConfig.projectileV2VisualSize,
                   height: GameConfig.projectileV2VisualSize),
    cornerRadius: GameConfig.projectileV2CornerRadius
)
body.fillColor = .ganhoCoralShadow
body.strokeColor = .clear
body.zPosition = 0
addChild(body)

let fLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
fLabel.text = GameConfig.projectileV2LabelText
fLabel.fontSize = GameConfig.projectileV2LabelFontSize
fLabel.fontColor = .white
fLabel.verticalAlignmentMode = .center
fLabel.horizontalAlignmentMode = .center
fLabel.zPosition = 1
addChild(fLabel)

zRotation = GameConfig.projectileV2RotationDegrees * .pi / 180
```

- 본체 `SKSpriteNode.color = .clear`.
- **PhysicsBody size = projectileSize²** (16) 정확 보존. 시각 자식 22pt와 분리.
- `applyEnchanted()`/`clearEnchanted()` 동작: `body.fillColor` 교체로 시각 옮김. 시그니처/타이밍 0건 변경.

### 10. `Nodes/ComboPopupNode.swift`

- `label.fontName = GameConfig.fontDisplay`, `label.fontSize = comboPopupV2FontSize` (32).
- color(for:) 매핑 v2 토큰:
  - case 3: `.ganhoMusicGold`
  - case 5: `.ganhoCoralPrimary`
  - case 10: `.ganhoMusicGold`
  - case 20: `.ganhoCoralShadow`
  - default: `.ganhoMusicGold`
- 외곽선 navy 4방향 1pt 자식 4개 (zPosition -1).
- `zRotation = comboPopupV2RotationDegrees * .pi / 180`.
- `animate()` SKAction 본문 0건 변경.

### 11. `Nodes/ComboBreakNode.swift`

- `label.fontName = GameConfig.fontDisplay`, `label.fontSize = comboBreakV2FontSize` (28).
- `label.fontColor = .ganhoCoralShadow` (기존 색 → v2 토큰).
- 외곽선 navy 4방향 시뮬레이션.
- `animate()` 본문 0건 변경.

### 12. `Nodes/PauseButtonNode.swift` (신규)

```swift
import SpriteKit

final class PauseButtonNode: SKNode {

    // MARK: - Properties
    private let background: SKShapeNode
    private let bar1: SKSpriteNode
    private let bar2: SKSpriteNode

    // MARK: - Init
    override init() {
        let size = CGSize(width: GameConfig.pauseButtonSize, height: GameConfig.pauseButtonSize)
        background = SKShapeNode(rectOf: size, cornerRadius: GameConfig.pauseButtonCornerRadius)
        let barSize = CGSize(width: GameConfig.pauseButtonBarWidth, height: GameConfig.pauseButtonBarHeight)
        bar1 = SKSpriteNode(color: .white, size: barSize)
        bar2 = SKSpriteNode(color: .white, size: barSize)
        super.init()
        name = "pauseButton"
        zPosition = 200

        background.fillColor = UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.pauseButtonBgAlpha)
        background.strokeColor = .clear
        addChild(background)

        let barOffset = (GameConfig.pauseButtonBarWidth + GameConfig.pauseButtonBarGap) / 2
        bar1.position = CGPoint(x: -barOffset, y: 0)
        bar2.position = CGPoint(x: +barOffset, y: 0)
        addChild(bar1)
        addChild(bar2)

        isUserInteractionEnabled = false  // Sprint 3: 시각 placeholder만
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
```

---

## 검증 체크리스트 (Evaluator용)

### A. 게임 수치 / 로직 회귀 0 (40%)
- [ ] `GameConfig` 기존 게임 수치 상수 git diff 0줄 (체크보드 hex 2개만 예외)
- [ ] `GameScene.update(_:)` 본문 0줄 변경
- [ ] `GameScene.endGame()` 본문 0줄 변경
- [ ] `GameScene.configureContactRouter()` 본문 0줄 변경
- [ ] `SpawnSystem/ScoreSystem/SkillSystem/ContactRouter/PhysicsCategory` 한 줄도 무변
- [ ] `EnemyNode/ProfessorNode/StoneGuardNode/PlayerNode/ToiletNode/StethoscopeNode/ToastLabelNode/ScorePopupNode/SparkleEffectNode/HitFlashNode/AirplaneNode/AirforceOverlayNode/BombFlashNode/CountdownNode/CutsceneOverlayNode/MusicNoteEmitterNode/PixelSpriteRenderer/CharacterCardNode/DifficultyCardNode/StoryBoxNode/GlowingTitleNode/DiplomaOverlayNode` 한 줄도 무변
- [ ] Repositories 5개 한 줄도 무변
- [ ] `BGMPlayer/AudioManager/HapticsManager` 한 줄도 무변
- [ ] 5×3=15 캐릭터·난이도 조합 시작 가능

### B. 물리 / PhysicsBody 보존
- [ ] NoteNode PhysicsBody rectangleOf(noteSize²) 그대로
- [ ] ProjectileNode PhysicsBody rectangleOf(projectileSize²) 그대로 (시각 자식 22pt와 분리)
- [ ] 외곽 벽 4개 + 기둥 PhysicsBody 정책 그대로
- [ ] 체크보드 1152개 tile PhysicsBody 미부착 그대로

### C. 입력 / 터치 (회귀 핵심)
- [ ] `DPadNode.touchesBegan/Moved/Ended/Cancelled` 본문 0줄
- [ ] `DPadNode.updateDirection(forTouchLocation:)` 알고리즘 0줄
- [ ] `DPadNode.currentDirection` CGVector 타입 그대로
- [ ] `SkillButtonNode.touchesBegan` → onTap() 호출 그대로
- [ ] `SkillButtonNode.configure/setEnabled` 시그니처 보존
- [ ] `PauseButtonNode.isUserInteractionEnabled = false`
- [ ] `GameScene.update`의 입력 가드 블록 그대로

### D. 비주얼 일관성 (25%)
- [ ] 체크보드 색 #FFEFE0 / #FFDFC8
- [ ] 외곽 벽 / 기둥 navy
- [ ] HUD 슬롯 navy 0.78 + 라운드 14
- [ ] HUD 라벨 Jua 10pt 골드, 값 Jua 18pt 흰색
- [ ] TIME 12초 이하 코랄 배경 + 진행바
- [ ] 음표 골드 원 + 흰 링 + 글로우 + 1.4s 펄스
- [ ] F 투사체 코랄 22 라운드 사각형 + 흰 F + -12° 회전
- [ ] ComboPopup Jua 32pt + navy 외곽선 + -8° 회전
- [ ] ComboBreak Jua 28pt + 코랄 색 + navy 외곽선
- [ ] D-Pad 4 버튼 + 중앙 데드존
- [ ] 스킬 버튼 코랄 원 72 + B 키 칩 + 스킬명 칩
- [ ] 일시정지 버튼 우상단 navy 라운드 32 + 흰 ||

### E. Swift 패턴 (20%)
- [ ] PauseButtonNode final class + MARK + GameConfig 상수
- [ ] 강제 언래핑 ! 신규 0건
- [ ] Timer 신규 0건
- [ ] 매직 넘버 신규 0건 (모두 GameConfig 참조)
- [ ] [weak self] 캡처 (신규 클로저)
- [ ] private/internal 일관

### F. 가독성 / UX (15%)
- [ ] HUD 텍스트 대비 충분
- [ ] D-Pad 터치 영역 44pt 이상
- [ ] 스킬 버튼 72pt
- [ ] 음표 펄스 1.4s 시야 방해 0
- [ ] 회전 텍스트 가독성 유지

### G. Sprint 1/2 보호
- [ ] `ColorTokens.swift` 한 줄도 무변
- [ ] Sprint 1 컴포넌트 6개 한 줄도 무변
- [ ] StartScene / CharacterSelectScene / SkillExplanationScene git diff 0줄
- [ ] ResultScene / DiplomaOverlayNode git diff 0줄

---

## 주의사항

1. **D-Pad 위치 / 스킬 버튼 위치**: 본 SPEC + DESIGN_RENEWAL_REQUEST.md §4.4 — D-Pad **우하단**, 스킬 버튼 **좌하단**. 현재 코드도 일치. 시각만 v2 적용.

2. **시각 자식과 PhysicsBody 분리**: NoteNode/ProjectileNode의 시각은 자식 SKShape/SKLabel로 위임하되 PhysicsBody는 본체에 그대로 (size 변경 = §6.1 회귀).

3. **ProjectileNode -12° 회전과 충돌**: zRotation은 PhysicsBody도 따라 회전하지만 `allowsRotation=false` + `collision=0` + 사각형이라 contact normal 영향 없음.

4. **ComboPopupNode 32pt**: 기존 `comboPopupFontSize=48` 상수는 그대로 두고 새 상수 `comboPopupV2FontSize=32` 추가 → 기존 git diff 0.

5. **HUDSlotNode init 시그니처**: `showTimeBar: Bool = false` default 파라미터 추가 = Swift 호환성 100%.

6. **DPadNode 프로퍼티 타입 변경(SKSpriteNode → SKShapeNode)**: 4개 모두 `private`. 외부 노출 `currentDirection`만 → 영향 없음.

7. **`applyEnchanted/clearEnchanted` 변경**: `body.fillColor` 교체로 옮김 — 자식 SKShape의 fillColor 교체 (시각만, 시그니처 0 변경).

---

**SPEC 작성 완료** — Generator는 이 SPEC + mockup HTML + 기존 코드만으로 구현 가능.
