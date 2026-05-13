# 자체 점검 — Phase 6-10 콤보 마일스톤 텍스트 팝업

전략: 1회차 — SPEC 그대로 옵션 B(폴링) + SelfDismissingNode 6호 + 멱등 Set 가드. 신규 SPEC이라 케이스 분류 무관.

---

## 1. SPEC 기능 5개 구현 확인 표

| # | SPEC 항목 | 구현 위치 | 확인 |
|---|---|---|---|
| 1 | ComboPopupNode 신설 (SelfDismissingNode 6호) | `Nodes/ComboPopupNode.swift` 신설 (77줄) | OK |
| 2 | GameConfig Combo Popup 상수 6개 | `Config/GameConfig.swift` §Combo Popup (+18줄) | OK |
| 3 | GameScene `triggeredComboMilestones: Set<Int>` 프로퍼티 1개 | `GameScene.swift` Properties (airforceTriggered 아래) | OK |
| 4 | `onNoteCollected` 클로저에 마일스톤 검사 5+ 줄 (sparkle.emit() 이후, note.removeFromParent() 이전) | `GameScene.swift` configureContactRouter() 내부 | OK |
| 5 | pbxproj 4지점 등록 (UUID 0031) | PBXBuildFile / PBXFileReference / Nodes group / Sources phase | OK |

추가 미세항목:
- 헤더 주석 Phase 6-10 1줄 추가 — OK
- `Set<Int>` 기본값 `[]` (한 판 = 1 인스턴스, reset 미필요) — OK

---

## 2. 빌드 결과

- **결과**: `** BUILD SUCCEEDED **`
- **에러**: 0건
- **경고**: 0건 (warning/error grep 결과 빈 출력 — appintentsmetadataprocessor 제외)
- **명령어**: `xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" -scheme "GanhoMusic iOS" -destination 'generic/platform=iOS Simulator' -configuration Debug build`

---

## 3. 회귀 0줄 강제 항목 git diff 확인

```
modified:   GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift    +18 -0
modified:   GanhoMusic/GanhoMusic Shared/GameScene.swift            +16 -0
modified:   GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj         +4  -0
new file:   GanhoMusic/GanhoMusic Shared/Nodes/ComboPopupNode.swift +77
```

회귀 0줄 강제 항목 모두 **변경 0**:

| 영역 | 변경 줄 |
|---|---|
| `Systems/ScoreSystem.swift` | 0 |
| `Nodes/HUDNode.swift` | 0 |
| `Managers/AudioManager.swift` | 0 |
| `Managers/HapticsManager.swift` | 0 |
| `Managers/BGMPlayer.swift` | 0 |
| `Nodes/SparkleEffectNode.swift` | 0 |
| `Nodes/HitFlashNode.swift` | 0 |
| `Nodes/BombFlashNode.swift` | 0 |
| `Systems/CameraShakeAction.swift` | 0 |
| `Systems/ContactRouter.swift` | 0 |
| `Systems/SpawnSystem.swift` | 0 |
| `Scenes/TitleScene.swift` | 0 |
| `Scenes/ResultScene.swift` | 0 |
| `Repositories/*` | 0 |
| `Models/*` | 0 |
| `Protocols/SelfDismissingNode.swift` | 0 (재사용만) |
| `Config/ColorTokens.swift` | 0 (재사용만) |
| `Nodes/PlayerNode/EnemyNode/NoteNode/ProjectileNode/AirplaneNode/AirforceOverlayNode/CharacterCardNode/DPadNode/StoneGuardNode` | 0 |
| GameScene `update()` / `endGame()` | 0 |
| `Config/GameConfig.swift` 기존 상수 | 0 (추가만) |
| `Config/PhysicsCategory.swift` | 0 |
| `Errors/*` | 0 |

GameScene.swift도 `update()` / `endGame()` / `didMove()` / `triggerAirforceEasterEgg()` / 다른 콜백 모두 **무손**. `onNoteCollected` 단일 클로저 안 +10줄과 헤더 1줄 + 프로퍼티 4줄만 추가.

---

## 4. 특별 검증

### 4-1. 강제 언래핑 0
- ComboPopupNode: `!` 없음. `init(coder:)`만 표준 fatalError(다른 자가 소멸 노드 패턴 동일).
- GameScene 추가 코드: `self.scoreSystem.combo` 정상 접근, `?` / `!` 없음.

### 4-2. 매직 넘버 0
- ComboPopupNode 모든 수치는 GameConfig 경유:
  - `GameConfig.comboPopupZPosition` / `comboPopupFontSize` / `comboPopupFlyUpDistance` / `comboPopupDuration` / `comboPopupEndScale`
- GameScene 추가 코드: `GameConfig.comboMilestones` 경유.
- 텍스트 `"x\(milestone)"`은 SPEC 명시 포맷 (Int 변수 보간만, 매직 넘버 아님).

### 4-3. Timer 0, SKAction만
- ComboPopupNode.animate(): `SKAction.group([moveBy, fadeOut, scale])` → `SKAction.sequence([group, removeFromParent])`. Timer/DispatchQueue/CADisplayLink 0.

### 4-4. SelfDismissingNode 채택 (6호)
- 선언: `final class ComboPopupNode: SKNode, SelfDismissingNode`
- 자가 제거: `sequence`의 마지막 단계 `SKAction.removeFromParent()` — 호출자(GameScene)는 cleanup 0줄.
- 6호 누적: Airplane(1) → AirforceOverlay(2) → BombFlash(3) → Sparkle(4) → HitFlash(5) → **ComboPopup(6)**.

### 4-5. [weak self] + guard let self 유지
- GameScene `onNoteCollected` 클로저 기존 `[weak self]` + `guard let self = self else { return }` 무손.
- 추가 코드는 모두 `self.` 명시 접근(이미 unwrap된 self 사용).
- ComboPopupNode.animate() 내부는 self 미사용 — [weak self] 캡처 불필요(BombFlash/HitFlash 패턴 동형).

### 4-6. 색 토큰 정확한 이름 사용 (ColorTokens.swift 실제 정의 확인)
ColorTokens.swift grep 결과 — SPEC 명시 4개 토큰 모두 실재:

| SPEC 명시 | ColorTokens.swift 실제 | 일치 |
|---|---|---|
| `.ganhoPaper` | `static let ganhoPaper` (line 22) | OK |
| `.ganhoPinkNote` | `static let ganhoPinkNote` (line 31) | OK |
| `.ganhoYellowF` | `static let ganhoYellowF` (line 46) | OK |
| `.ganhoBloodAccent` | `static let ganhoBloodAccent` (line 41) | OK |

ColorTokens.swift 변경 0건. 모두 기존 토큰 재사용. fallback은 `.ganhoPaper` (graceful — 미래 마일스톤 추가 대비).

### 4-7. 멱등성 가드 (triggeredComboMilestones Set)
- 프로퍼티: `private var triggeredComboMilestones: Set<Int> = []`
- 가드 패턴:
  ```swift
  if GameConfig.comboMilestones.contains(currentCombo),
     !self.triggeredComboMilestones.contains(currentCombo) {
      self.triggeredComboMilestones.insert(currentCombo)
      ...
  }
  ```
- 검사 순서: `contains(milestones)` AND `!contains(triggered)` → 둘 다 충족 시에만 insert + popup.
- 멱등 효과: 콤보 3 도달 후 콤보 윈도우 만료(0)로 떨어졌다 다시 3 도달해도 재발화 X (Set에 3이 이미 있음).
- 인스턴스 단위 리셋: GameScene은 한 판당 새 인스턴스 → Set는 자동 빈 상태로 시작.

### 4-8. 마일스톤 검사 위치 정확성
GameScene `onNoteCollected` 클로저 시퀀스 (원문 + 추가):

```
self.scoreSystem.recordNoteHit(at:)
self.haptics.light()
self.audio.play(.noteCollected)
let sparkleOrigin = note.position
let sparkle = SparkleEffectNode()
sparkle.position = sparkleOrigin
self.worldNode.addChild(sparkle)
sparkle.emit()                                           ← (A) 이 라인 이후
// Phase 6-10 — 콤보 마일스톤 도달 시 화면 중앙 텍스트 팝업 1회 발화 (멱등성).
let currentCombo = self.scoreSystem.combo
if GameConfig.comboMilestones.contains(currentCombo),
   !self.triggeredComboMilestones.contains(currentCombo) {
    self.triggeredComboMilestones.insert(currentCombo)
    let popup = ComboPopupNode(milestone: currentCombo)
    self.cameraNode.addChild(popup)
    popup.animate()
}
note.run(.removeFromParent())                            ← (B) 이 라인 이전
```

(A) sparkle.emit() **이후**, (B) note.removeFromParent() **이전** 정확 위치. SPEC 명시 위치 일치.

### 4-9. ColorTokens 변경 0건
git diff 출력에 `Config/ColorTokens.swift` 미등장. 모든 색은 기존 토큰 재사용.

### 4-10. 새 효과음/햅틱/PhysicsCategory 0
- AudioManager/HapticsManager 호출 0건 — *시각 only* SPEC 준수.
- PhysicsCategory.swift 변경 0건 — ComboPopupNode는 PhysicsBody 미부착(순수 시각).

---

## 5. 검증 시나리오 정적 추적

| # | 시나리오 | 정적 추적 | 결과 |
|---|---|---|---|
| a | 콤보 2 (음표 2개) | `currentCombo=2`. `comboMilestones=[3,5,10,20]`에 2 미포함 → 가드 통과 X | 팝업 미발화 ✓ |
| b | 콤보 3 도달 | `currentCombo=3`, milestones 포함, triggered 미포함 → insert {3}, `ComboPopupNode(milestone:3)`, color=.ganhoPaper, "x3" 1초 fly-up + fadeOut + scale 1.4 → removeFromParent | `.ganhoPaper` "x3" 1초 후 소멸 ✓ |
| c | 콤보 5 도달 (x3 발화 후) | `currentCombo=5`, milestones 포함, triggered={3}에 5 미포함 → insert {3,5}, "x5" `.ganhoPinkNote`. 콤보 5는 이미 3을 거쳐서 발화했지만 x3 재발화는 안 됨(이 시점 currentCombo=5라 `contains(5)`만 검사) | "x5" 분홍 팝업 ✓, "x3" 재발화 X ✓ |
| d | 콤보 10 → 윈도우 만료 → 다시 3 | 10 발화 시 triggered={3,5,10}. ScoreSystem.tickComboExpiry로 combo=0. 새 음표 3개 수집 → combo=3 → milestones 포함, *triggered={3,5,10}에 3 포함* → 가드 false | "x3" 재발화 X ✓ |
| e | 마일스톤 + 피격 동시 | onNoteCollected는 NoteNode 충돌만 처리(분기 독립). 같은 프레임에 onProjectileHitPlayer 별도 호출 → HitFlash + 셰이크 + endGame. ComboPopup은 cameraNode 자식 — endGame() 후 presentScene 시 cameraNode 트리째 ARC 해제(자동 정리). 명시적 cleanup 호출 0 | 팝업 + HitFlash + 셰이크 모두 작동, ResultScene 전환 시 자동 정리 ✓ |
| f | 새 게임 시작 | `GameScene.newGameScene(characterID:)`가 새 인스턴스 생성 → `triggeredComboMilestones: Set<Int> = []` 초기값 — 모든 마일스톤 재발화 가능 | 빈 Set, 다시 처음부터 발화 ✓ |
| g | 콤보 50 도달 | combo 1→2→...→50. milestones는 3,5,10,20만. 콤보 갱신마다 `contains(currentCombo)` 검사 — 3,5,10,20 도달 시점에만 true. 각각 1회씩 insert. 4,6,11,21 등은 milestones 미포함이라 false | 마일스톤 4단계 모두 1회씩 발화 후 추가 발화 0 ✓ |
| h | 빌드 | BUILD SUCCEEDED, 경고 0 (위 §2) | OK ✓ |

---

## 6. Swift 패턴 준수

- 강제 언래핑 미사용: 준수
- guard let 옵셔널 처리: 준수 (`guard let self = self else { return }` 기존 패턴 유지)
- MARK 섹션 구분: 준수 (Properties / Init / Animate / Configure / Color Mapping)
- GameConfig 상수 사용: 준수 (모든 수치)
- weak self 캡처: 준수 (onNoteCollected 클로저 기존 패턴, ComboPopupNode 내부 self 미사용)

## 7. SpriteKit 패턴 준수

- didMove(to:)에서 초기화: 준수 (변경 없음)
- dt 기반 이동: 해당 없음 (정적 팝업, SKAction.moveBy 사용)
- SKAction 스폰 패턴: 준수 (group + sequence + removeFromParent)
- 충돌 후 노드 즉시 삭제 없음: 준수 (note.run(.removeFromParent())로 액션 큐 경유, ComboPopupNode 자체는 자가 제거)
- HUD 노드 분리: 준수 (ComboPopupNode는 cameraNode 자식, HUDNode와 독립)

## 8. 범위 외 미구현 항목

없음. SPEC "허용" 항목 100% 구현, "금지" 항목 0건 침범.

- ScoreSystem 시그니처 미변경 (옵션 B 폴링) ✓
- HUDNode 미변경 ✓
- ContactRouter 시그니처 미변경 ✓
- AudioManager/HapticsManager/BGMPlayer 호출 0 ✓ (시각 only)
- Sparkle/HitFlash/BombFlash 미변경 ✓
- 마일스톤 [3,5,10,20] 외 분기 0 ✓
- 멱등 가드(triggered Set)로 재발화 차단 ✓
- "콤보!" "GREAT!" 등 SPEC 외 텍스트 0 ✓
