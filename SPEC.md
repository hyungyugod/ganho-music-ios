# Phase 6-16 — +1 / +2 점수 플로팅 텍스트

## 개요
음표를 수집하는 *바로 그 자리*에 짧은 "+1" 또는 "+2" 텍스트를 띄우고 위로 부드럽게 떠오르며 페이드아웃시킨다. 콤보 3 이상에서 점수가 2배가 되는 규칙(GameConfig.comboBonusThreshold)을 *황금색 "+2"* 시각 신호 하나로 학습하게 만드는 마이크로 폴리싱.

## 변경 유형
**비주얼** (시각 폴리싱) — Evaluator는 시각 폴리싱 기준으로 채점한다. 게임 로직(ScoreSystem)은 미접촉, 신규 의존성 0건.

## 게임 경험 의도
플레이어는 "콤보 3부터 2배"라는 텍스트 설명 없이도 *황금색 +2*가 떠오르는 순간 "방금 점수가 2배 들어왔다"는 사실을 시각만으로 인지한다. +1(흰빛)과 +2(황금) 두 색상의 *대비* 그 자체가 룰북이 된다. 노트가 사라진 자리에서 텍스트가 위로 떠오르며 사라지는 마이크로 모션은 *내가 방금 무엇을 얻었는가*를 부드럽게 강조해 짧은 만족감을 만든다.

## Sprint 범위 계약
- **허용**:
  - `Nodes/ScorePopupNode.swift` 신규 파일 1개 추가 (자가 소멸 노드 9호)
  - `GameScene.swift` `onNoteCollected` 클로저 안에 ScorePopupNode 스폰 라인 추가 (sparkle 직후 위치, 4~5줄)
  - `GameConfig.swift`에 `// MARK: - Score Popup (Phase 6-16)` 섹션 신설 + 신규 상수 7개
  - pbxproj는 신규 .swift 파일 등록을 위해 1건 변경 (불가피)
- **금지**:
  - ScoreSystem 시그니처/내부 로직 변경 (recordNoteHit return value 변경 등)
  - sparkle / 콤보 마일스톤 / 콤보 BREAK / 카메라 셰이크 / HUD / BGM / Haptics / Audio API 신규 호출 또는 수정
  - 신규 사운드 case / 신규 햅틱 호출 / 신규 ColorTokens 색상 추가
  - SPEC에 없는 별개 시각 효과 (파티클, 진동 추가 등)
  - .xcassets, Info.plist, Asset Catalog 신규 항목
- **판단 기준**: "이 변경이 없으면 +1/+2 텍스트가 노트 수집 자리에 안 뜨는가?" → YES만 허용

## 변경 범위

### 수정할 파일
- `GanhoMusic Shared/GameScene.swift`: `onNoteCollected` 클로저 안에 ScorePopupNode 스폰 라인 4~5줄 추가 (sparkle 발화 직후, 콤보 마일스톤 가드 *전* 위치). 다른 라인 미접촉.
- `GanhoMusic Shared/Config/GameConfig.swift`: 파일 맨 아래 `// MARK: - Score Popup (Phase 6-16)` 섹션 신설 + 신규 상수 7개 추가. 기존 상수 미접촉.
- `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj`: 신규 .swift 파일 1건 등록 (Xcode 프로젝트가 새 파일을 인식하게 하기 위한 *유일한 불가피한 변경*)

### 추가할 파일
- `GanhoMusic Shared/Nodes/ScorePopupNode.swift`: 자가 소멸 노드 9호. SelfDismissingNode 채택. 정적 팩토리 메서드 1개 노출. 약 60~80줄.

## 기능 상세

### 기능 1: ScorePopupNode (자가 소멸 노드 9호)
- **설명**: 노트 수집 좌표 + (0, +12) 위치에서 발생, 위로 +40pt 부드럽게 이동 + scale 0.8→1.0 + alpha 1→0 동시 진행, 0.6초 후 자가 제거되는 텍스트 노드.
- **구현 위치**: `Nodes/ScorePopupNode.swift` (신규 파일).
- **부착 부모**: `worldNode` 자식 — sparkle과 동일 부모. 이유: 노트 수집 좌표는 *worldNode 좌표계* 값이므로 worldNode에 부착해야 카메라 follow와 자연 동기. 콤보 마일스톤(cameraNode 자식, 화면 중앙 고정)과는 의도적으로 *다른 부모* — 마일스톤은 *글로벌* 시그널, 점수 팝업은 *지역* 시그널.
- **시각 사양**:
  - 폰트: SKLabelNode 기본 폰트 (fontName 미지정 — 다른 자가 소멸 노드와 동일 정책). SF Mono Bold는 시스템 폰트 패밀리 의존이 환경별로 다를 수 있어 *fontName 미지정*으로 안전. 굵기는 fontSize 28pt 자체의 가시성으로 확보.
  - 크기: 28pt (HUD 18pt보다 크고 ComboPopup 48pt보단 작음 — *지역* 강조 톤)
  - 색: +1 → `.ganhoPaper` (기존 흰빛/페이퍼 톤, 새 ColorTokens 추가 0건), +2 → `.ganhoYellowF` (기존 황금 토큰, F 투사체와 동일 색이지만 *콤보 황금기*와 의미 공유)
  - 시작 위치: (0, +12) — ScorePopupNode 자체의 노드 position이 worldNote 좌표 + (0, +12)로 세팅됨
  - 종료 위치: 시작점 + (0, +40)
  - 스케일: 0.8 → 1.0 (살짝 *부풀어 오르는* 톤. ComboPopup의 1.0→1.4 확대보다 약하고, SparkleEffect의 1.0→0.2 수축과 반대)
  - 알파: 1.0 → 0.0
  - 지속 시간: 0.6초 (sparkle 0.5초보다 약간 길어 사라지는 시점이 동기되지 않음 — 시각 노이즈 분리)
  - zPosition: sparkle(30) 위, HUD(100) 아래 → 50 권장
- **정적 팩토리 시그니처**:
  ```swift
  /// 노트 수집 좌표에서 +1 또는 +2를 띄우는 자가 소멸 텍스트.
  /// 점수 1은 흰빛(.ganhoPaper), 점수 2는 황금(.ganhoYellowF)으로 콤보 배수 시각화.
  /// gainedPoints 외의 값은 graceful fallback (+1 흰빛) — 미래 점수 시스템 확장 안전망.
  static func spawn(at position: CGPoint, gainedPoints: Int, parent: SKNode)
  ```
- **핵심 코드 구조**:
  ```swift
  final class ScorePopupNode: SKNode, SelfDismissingNode {
      private let label: SKLabelNode

      private init(gainedPoints: Int) {
          self.label = SKLabelNode(text: "+\(gainedPoints)")
          super.init()
          name = "scorePopup"
          zPosition = GameConfig.scorePopupZPosition
          configureLabel(color: Self.color(for: gainedPoints))
          setScale(GameConfig.scorePopupStartScale)
          addChild(label)
      }

      required init?(coder: NSCoder) { fatalError(...) }

      // MARK: - Spawn (static factory)
      static func spawn(at position: CGPoint, gainedPoints: Int, parent: SKNode) {
          let node = ScorePopupNode(gainedPoints: gainedPoints)
          node.position = CGPoint(x: position.x,
                                  y: position.y + GameConfig.scorePopupStartOffsetY)
          parent.addChild(node)
          node.animate()
      }

      // MARK: - Animate (private — spawn에서만 호출)
      private func animate() {
          let moveUp = SKAction.moveBy(x: 0,
                                        y: GameConfig.scorePopupFlyUpDistance,
                                        duration: GameConfig.scorePopupDuration)
          let fadeOut = SKAction.fadeOut(withDuration: GameConfig.scorePopupDuration)
          let scaleUp = SKAction.scale(to: GameConfig.scorePopupEndScale,
                                        duration: GameConfig.scorePopupDuration)
          let group = SKAction.group([moveUp, fadeOut, scaleUp])
          let cleanup = SKAction.removeFromParent()
          run(.sequence([group, cleanup]))
      }

      // MARK: - Configure
      private func configureLabel(color: UIColor) {
          label.fontSize = GameConfig.scorePopupFontSize
          label.fontColor = color
          label.verticalAlignmentMode = .center
          label.horizontalAlignmentMode = .center
          label.position = .zero
      }

      // MARK: - Color Mapping (pure function, fallback +1 흰빛)
      private static func color(for gainedPoints: Int) -> UIColor {
          switch gainedPoints {
          case GameConfig.scorePerNote:      return .ganhoPaper
          case GameConfig.scorePerNoteCombo: return .ganhoYellowF
          default:                            return .ganhoPaper
          }
      }
  }
  ```
- **패턴 답습 확인**:
  - SelfDismissingNode 채택 ✓ (ComboPopupNode, ComboBreakNode, CountdownNode와 동일)
  - 정적 팩토리 1개 진입점 ✓ (`spawn(at:gainedPoints:parent:)`)
  - SKAction.group([move, fade, scale]) 동시 → SKAction.sequence([group, removeFromParent]) ✓ (ComboPopupNode 완전 답습)
  - `self` 미사용 → `[weak self]` 캡처 불필요 ✓
  - PhysicsBody 0건 ✓

### 기능 2: GameScene onNoteCollected 1줄 호출 추가
- **설명**: ScoreSystem이 점수를 갱신한 *직후*, sparkle 발화 *직후*, 콤보 마일스톤 가드 *전*에 ScorePopupNode를 worldNode에 스폰. 정확한 점수(1 또는 2)는 *recordNoteHit 호출 후* `scoreSystem.combo`로 분기 결정.
- **구현 위치**: `GameScene.swift` `configureContactRouter()` 안의 `contactRouter.onNoteCollected = { ... }` 클로저. 정확히 sparkle 발화 라인(`sparkle.emit()`) **직후**, `// Phase 6-10 — 콤보 마일스톤 도달 시...` 주석 **직전**.
- **호출 지점 컨텍스트** (현재 GameScene.swift 라인 337~342 직후):
  ```swift
  // ... 기존 코드 ...
  let sparkleOrigin = note.position
  let sparkle = SparkleEffectNode()
  sparkle.position = sparkleOrigin
  self.worldNode.addChild(sparkle)
  sparkle.emit()

  // === Phase 6-16 신규 (sparkle.emit() 직후, 콤보 마일스톤 가드 직전) ===
  // Phase 6-16 — 노트 수집 자리에 "+1" 또는 "+2" 텍스트 1회 발화 (시각 채널만).
  // recordNoteHit 직후의 combo로 점수 분기 — ScoreSystem 시그니처 미접촉(옵션 B 폴링).
  // worldNode 부모: sparkle과 동일 좌표계 → 카메라 follow와 자연 동기.
  let gainedPoints = self.scoreSystem.combo >= GameConfig.comboBonusThreshold
      ? GameConfig.scorePerNoteCombo
      : GameConfig.scorePerNote
  ScorePopupNode.spawn(at: sparkleOrigin, gainedPoints: gainedPoints, parent: self.worldNode)
  // === Phase 6-16 끝 ===

  // Phase 6-10 — 콤보 마일스톤 도달 시 화면 중앙 텍스트 팝업 1회 발화 (멱등성).
  // ... 기존 코드 계속 ...
  ```
- **`sparkleOrigin` 재사용 이유**: 이미 캡처된 좌표(노트 제거 안전). 추가 좌표 계산/노드 참조 0건.
- **`gainedPoints` 산출 로직 정당성**: ScoreSystem.recordNoteHit은 `combo >= GameConfig.comboBonusThreshold` 시 `scorePerNoteCombo` 점수를, 아니면 `scorePerNote` 점수를 가산한다 (ScoreSystem.swift 라인 28~30). 호출부에서 *완전히 동일한 조건식*을 평가하면 *같은 결과*가 보장된다. 두 조건은 동일 GameConfig 상수를 참조 → 미래 임계값 변경 시 한 곳만 바뀌어도 두 분기가 동기.

## ScoreSystem 반환값 확인 (필수 분석)

**현 ScoreSystem.recordNoteHit 시그니처** (ScoreSystem.swift 라인 25~32):
```swift
func recordNoteHit(at now: TimeInterval) {
    let isInWindow = combo > 0 && now - lastCollectAt < GameConfig.comboWindow
    combo = isInWindow ? combo + 1 : 1
    score += combo >= GameConfig.comboBonusThreshold
        ? GameConfig.scorePerNoteCombo
        : GameConfig.scorePerNote
    lastCollectAt = now
}
```

**Return type은 Void**. 가산된 점수는 외부로 반환되지 않는다.

**채택 fallback (옵션 B 폴링) — recordNoteHit *후* `scoreSystem.combo` 읽기**:
- `recordNoteHit` 호출 직후 `combo` 값이 이미 갱신되어 있음 (`combo = isInWindow ? combo + 1 : 1` 후).
- 호출부에서 *동일한* `combo >= GameConfig.comboBonusThreshold` 식을 평가하면 *동일한 분기*를 얻는다.
- Phase 6-10이 이미 같은 패턴 사용 (`let currentCombo = self.scoreSystem.combo` 직후 마일스톤 검사) → **검증된 패턴**.
- **ScoreSystem 시그니처/구현 미접촉** ✓
- **회귀 0** ✓

대안(불채택): ScoreSystem.recordNoteHit이 Int(가산 점수)를 return하도록 변경 — 시그니처 변경 + 기존 호출부 1개 변경 + 사이드이펙트 코딩 컨벤션 변경. **본 sprint는 회귀 0이 핵심이라 불채택**.

## GameConfig 신규 상수 목록

`// MARK: - Score Popup (Phase 6-16)` 섹션 신설. 파일 맨 아래에 추가.

| 상수명 | 타입 | 권장 초기값 | 의미 |
|---|---|---|---|
| `scorePopupFontSize` | `CGFloat` | `28` | "+1"/"+2" 라벨 폰트 크기 (pt). HUD(18)보다 크고 ComboPopup(48)보다 작음 — *지역* 강조. |
| `scorePopupStartOffsetY` | `CGFloat` | `12` | 노트 수집 좌표에서 시작 y 오프셋 (pt). 노트 본체(16pt) 위쪽 살짝 — 노트와 텍스트가 같은 픽셀 안에서 겹치지 않게. |
| `scorePopupFlyUpDistance` | `CGFloat` | `40` | 위로 떠오르는 총 거리 (pt). ComboPopup(80)의 절반 — *지역* 시그널은 작게. sparkleSpawnDistance(24)보다 길어 sparkle과 시각 분리. |
| `scorePopupDuration` | `TimeInterval` | `0.6` | 1회 표시 총 길이 (초). sparkle(0.5)보다 살짝 길어 사라지는 시점 비동기. comboPopup(1.0)보다 짧음 — *지역* 톤. |
| `scorePopupStartScale` | `CGFloat` | `0.8` | 시작 scale. 1.0(원래 크기)보다 작게 시작해 *부풀어 오르는* 톤. |
| `scorePopupEndScale` | `CGFloat` | `1.0` | 끝 scale. ComboPopup(1.4 확대)보다 약함 — *지역* 시그널 절제. |
| `scorePopupZPosition` | `CGFloat` | `50` | zPosition. sparkle(30) 위, HUD(100) 아래. 자식이 노트가 사라진 *바로 그 픽셀* 위에 있으되 HUD 점수/타이머는 안 가림. |

**모든 매직 넘버 0 — GameConfig 상수화 ✓**

## 회귀 0 자연 차단 메커니즘

Phase 6-15(NEW BEST!)가 `isNewBest` 분기로 회귀를 자연 차단했듯, 본 sprint는 **`onNoteCollected` 진입 시에만 ScorePopupNode가 생성됨**으로 자연 차단된다.

**차단 메커니즘 다층**:
1. **호출 지점 단일** — ScorePopupNode 스폰은 `onNoteCollected` 클로저 안 1지점에서만 발생. 다른 경로(F 피격, enemy 접촉, 시간 만료, 콤보 끊김, 게임오버) 어디서도 호출 0.
2. **gameState 가드 간접 의존** — `onNoteCollected`는 SpriteKit physics callback이지만, `gameState != .playing`일 때는 player가 정지되고 player.physicsBody?.velocity = .zero 처리되어 노트와 새로 충돌할 일이 없음 (이미 endGame 안에서 정지 처리). gameOver 후 잔존 노트 접촉 가능성은 기존 sparkle/마일스톤도 동일한 위험을 가지지만 한 판 내 1회만 endGame 호출되므로 무시 가능.
3. **자가 소멸** — ScorePopupNode 자체가 0.6초 후 removeFromParent. update loop 미접촉, 메모리 누적 0.
4. **시그니처 미접촉** — ScoreSystem.recordNoteHit, ContactRouter.onNoteCollected, GameConfig 기존 상수, ColorTokens 모두 *읽기만*. 쓰기는 신규 상수와 신규 노드 파일에 한정.
5. **새 의존성 0** — AudioManager / HapticsManager / BGMPlayer / Repository 모두 미호출. 신규 enum case 0.
6. **부모 노드 worldNode 선택의 안전성** — sparkle(이미 worldNode 자식)과 동일 부모 → 카메라 follow / 좌표계 / cleanup 정책 모두 검증된 경로. cameraNode를 쓰지 않으므로 HUD/CountDown/ComboPopup의 화면 고정 z-stack과 간섭 0.

## 주의사항

- **부모 선택**: ScorePopupNode는 반드시 **worldNode**에 부착한다. cameraNode(화면 중앙 고정)에 부착하면 *노트가 사라진 자리*가 아니라 *화면 중앙 부근*에 뜨게 됨 → SPEC 위반. sparkle과 동일 부모 선택이 자연스럽다.
- **좌표 캡처 순서**: `sparkleOrigin`은 이미 `note.position`을 안전하게 캡처한 변수. ScorePopupNode 스폰에 *재사용* — note.removeFromParent() 후에도 안전. 새로 `note.position`을 읽으면 *위험* (note가 트리에서 이미 빠진 후일 수 있음).
- **gainedPoints 산출 시점**: 반드시 `self.scoreSystem.recordNoteHit(at:)` **호출 후** 평가. 호출 전에는 직전 콤보값이라 부정확. 현재 GameScene 코드 흐름은 recordNoteHit이 onNoteCollected 클로저 첫 줄에서 이미 호출되므로, sparkle 발화 후 시점은 자동으로 *post-recordNoteHit* 상태.
- **새 ColorTokens 0**: SPEC에서 ".ganhoWhite"를 언급했으나 현 ColorTokens에는 `ganhoWhite` 토큰이 *없다*. 가장 가까운 흰빛 토큰은 **`.ganhoPaper`** (HEX #F4F1DE — paperWhite). 새 색 추가 0건 정책에 따라 `.ganhoPaper`로 매핑. +2 황금색은 `.ganhoYellowF`(HEX #FFD23F) 그대로 사용.
- **SKLabelNode fontName 미지정**: SPEC가 "SF Mono Bold ~28pt"를 권장했으나, 본 프로젝트의 다른 자가 소멸 텍스트 노드(ComboPopupNode, ComboBreakNode, CountdownNode)는 모두 *fontName 미지정* (시스템 폰트 기본 굵기 의존). 일관성과 환경 안전성을 위해 ScorePopupNode도 fontName 미지정 유지. fontSize 28pt로 가시성 확보. 미래 폰트 통합 sprint에서 일괄 처리.
- **빌드 에러 가능성**: 신규 .swift 파일을 추가하면 Xcode가 *Target Membership*을 자동 부여하지 못할 수 있음. Generator는 `Nodes/` 폴더에 파일을 추가한 후, pbxproj의 PBXBuildFile / PBXFileReference / PBXGroup / PBXSourcesBuildPhase 4지점에 `ScorePopupNode.swift` 항목을 추가하고 *iOS 타겟에만* 등록한다 (`GanhoMusic iOS` target). macOS / tvOS는 미지원 정책(components.md).
- **`spawn` static factory 내부에서 `private init` 호출**: ScorePopupNode는 외부에서 `init`을 직접 호출하지 못하게 init을 private으로 두고 spawn factory 하나만 노출. 이렇게 하면 외부 호출자가 spawn 한 경로로만 노드를 만들 수 있어 *position 설정 누락* 같은 사용자 실수가 차단된다.
- **animate를 private으로**: spawn 외에서 호출될 일이 없으므로 private. ComboPopupNode는 외부에서 `popup.animate()`로 호출하는 패턴이지만, 본 노드는 *정적 팩토리 일체형*이므로 한 단계 더 캡슐화. 패턴 진화 — 9호 노드에서 정적 팩토리 + private animate의 깔끔한 형태로 발전.
