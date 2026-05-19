# 디바이스 잘림 해소 + 캐릭터·난이도 카드 시인성 강화

## 개요

iPhone 17 Pro (iOS 26.4) landscape 시뮬레이터에서 4개 메뉴 씬(Start / CharacterSelect / DifficultySelect / Result)의 가장자리 콘텐츠가 Dynamic Island와 홈 인디케이터 영역에 침범해 잘려 보이는 문제를 해결한다. 동시에 (a) CharacterSelectScene 5장 카드가 너무 빽빽한 문제를 *여백·미세 y 오프셋*으로 풀고, (b) DifficultySelectScene 3장 카드의 *흐림·작음·설명 부족* 문제를 *크기 확장 + 미선택 알파 상향 + 난이도별 설명 라벨 추가*로 풀어낸다. 게임플레이·저장 포맷·사운드·햅틱은 한 줄도 손대지 않는 **순수 비주얼** 변경이다.

## 변경 유형

**비주얼**. 게임 로직 영향 0. GameScene·Repository·AudioManager·HapticsManager 미접촉.

## 게임 경험 의도

스크린샷에서 발생한 *주변시야 결손*(타이틀이 노치에 잘리고 BEST 알약이 노치 좌측에서 겹치는 현상)을 제거해, "잘림 없이 한눈에 들어온다"는 첫인상을 회복한다. 캐릭터 선택 화면은 5명이 빽빽이 줄 서 있던 인상에서 *숨 쉬는 여백과 자연스러운 흩어짐*으로 바뀌어 캐릭터 한 명 한 명에게 시선이 머물게 한다. 난이도 선택 화면은 흐릿하게 떠 있던 3개 캡슐이 *또렷한 카드*가 되어 손가락이 어디를 눌러야 할지, 각 난이도가 *어떤 경험*을 주는지 한 줄 설명으로 즉시 이해되도록 한다.

## Sprint 범위 계약

- **허용**: 본 SPEC의 기능 정상 동작에 필수적인 최소 연동 변경
  - `GameViewController.swift` — SKView를 safe area에 맞춰 마운트
  - 4개 메뉴 씬 중 잘림 해소·여백 개선이 필요한 곳의 layout 미세 조정
  - `DifficultyCardNode.swift` — 카드 크기·시인성·설명 라벨 강화
  - `Difficulty.swift` — `description: String` *신규 프로퍼티만* 추가
  - `GameConfig.swift` — 본 SPEC 전용 상수 신설(접미사 `*V3` / `*Description*`)
  - `CharacterSelectScene.swift` — 카드 간 여백 증가 + 미세 지그재그 y 오프셋
  - `DifficultySelectScene.swift` — 좌측 summary 카드와 우측 3장 카드의 시각 균형 재조정
- **금지** (SPEC에 없는 독립 기능 추가 금지)
  - `GameScene.swift` 게임 루프 / 충돌 / 점수 / 스폰
  - `Repositories/*` 직렬화 포맷 (DifficultyPreferenceRepository, CharacterPreferenceRepository, HighScoreRepository, StatisticsRepository, GraduationRepository)
  - `AudioManager`, `HapticsManager`
  - `Difficulty` enum의 *case 추가/삭제* (raw value "easy"/"normal"/"hard" 불변)
  - `StartScene` / `ResultScene`의 `transitionToNext` / `presentScene` 시그니처 / SKAction 시퀀스
  - `CharacterID` enum / `CharacterCardNode` 내부 구조
  - `GameScene.newGameScene(characterID:difficulty:)` 시그니처
  - `ResultScene.newResultScene(...)` 시그니처
  - GlassPillNode / PrimaryButtonNode / DarkContextChipNode 내부 구조
  - 음표 emitter / 그라데이션 배경 / NurseAvatarNode 시각
  - StartScene의 타이틀·태그라인 *문구*
  - 사운드 발화 시퀀스 (newBest reveal, sparkle 5발, diploma)
- **판단 기준**: "이 변경이 없으면 SPEC 기능이 제대로 동작하지 않는가?" → YES면 허용. NO면 금지.

---

## 근본 원인 분석

### A. 가장자리 잘림 (4개 씬 공통)

모든 씬은 다음 패턴으로 가장자리 콘텐츠를 배치한다.

```swift
// StartScene.layoutStatPills()
best.position = CGPoint(
    x: frame.minX + GameConfig.startSceneStatPillSideMargin,
    y: y
)
plays.position = CGPoint(
    x: frame.maxX - GameConfig.startSceneStatPillSideMargin,
    y: y
)
```

`frame.minX` / `frame.maxX` / `frame.minY` / `frame.maxY`는 **SKView의 bounds 전체**다. SKView가 view의 전체 영역을 차지하는 한, SKView는 자동으로 safe area를 보정하지 않는다. iPhone 17 Pro landscape에서 시스템 safe area inset은 대략

- left ≈ 59pt (Dynamic Island 쪽)
- right ≈ 0pt
- top ≈ 0pt
- bottom ≈ 21pt (home indicator)

이 inset 안에 BEST GlassPill(side margin 60pt) 같은 콘텐츠가 들어가도, **inset 자체의 시작 픽셀이 노치/홈 인디케이터 영역과 겹치므로** 시각적으로 잘려 보인다.

해결책 두 가지:

**(A) GameViewController에서 SKView를 safe area에 맞춰 마운트.**
- `viewDidLoad`에서 SKView를 storyboard 풀화면 자식으로 두지 말고, `view.safeAreaLayoutGuide` 영역에만 mount.
- 한 곳 수정으로 4개 씬이 자동으로 안전.
- 트레이드오프: 그라데이션 배경이 safe area 바깥(노치 영역)에서는 비게 되므로, **view.backgroundColor에 `.ganhoBgWarmTop` fallback**을 깔아 시각 연속성 유지.
- 음표 emitter 좌표계도 자연스럽게 따라옴 — 별도 처리 불필요.

**(B) 각 씬에서 `view.safeAreaInsets`를 읽어 가장자리 마진을 합산.**
- 4개 씬 모두 `didMove(to:)` / `didChangeSize`에서 inset 읽어 GameConfig 상수와 더하기.
- 코드 변경이 분산되고 회귀 리스크 4배.
- 장점: 그라데이션 배경이 풀스크린 유지.

→ **결정: (A) 채택.** 한 곳 수정으로 4개 씬 모두 해결. 그라데이션 fallback은 view.backgroundColor 1줄로 처리. NurseAvatarNode·MusicNoteEmitterNode·헤더 정렬 모두 *상대 좌표 기반*이라 회귀 없음.

### B. CharacterSelectScene 빽빽함

현재 상수:
- `characterCardGlassWidth = 110`
- `characterCardGlassHeight = 140`
- `characterCardSpacing = 10`

5장 카드의 합계 가로 폭 = `110 × 5 + 10 × 4 = 590pt`. iPhone landscape `view.safeAreaLayoutGuide` 가로(약 800pt)에 비해 spacing 10pt가 너무 짧아 글래스 컨테이너 가장자리가 거의 맞닿는다. 사용자 요청 "흩어지고 예쁘게"는 (1) spacing 확대 + (2) 각 카드별 y 미세 오프셋(지그재그)으로 *정렬되지 않은 자연스러움*을 추가하는 방향이 적합.

### C. DifficultySelectScene 흐림·작음·설명 부재

현재 상수:
- `difficultyCardWidth = 80`
- `difficultyCardHeight = 56`
- `difficultyCardSpacing = 16`
- `difficultyCardFontSize = 20`
- `difficultyCardSubtitleFontSize = 10`

문제:
1. **흐림**: `DifficultyCardNode.setSelected(false)`에서 `alpha = GameConfig.characterCardDeselectedAlpha (= 0.5)` + `background.fillColor = .clear` + `background.strokeColor = .ganhoUIBorder` (흰색 7% 보더). 미선택 상태가 거의 안 보임.
2. **작음**: 80×56 캡슐은 글래스 톤 + 흰색 보더 + 글자가 다 들어가야 해서 정보 밀도가 낮음. 부제 라벨이 10pt라 거의 안 읽힘.
3. **설명 부재**: `Difficulty.subtitle`("여유로운 실습" / "긴장의 병동" / "이교수의 청진기")만 있고, 한 줄 더 풀어쓴 description이 없음.

해결책:
- `Difficulty`에 `description: String` *신규* computed property 추가. 한 줄 풀이.
- `DifficultyCardNode`에 descriptionLabel(SKLabelNode) 추가. nameLabel + subtitleLabel + descriptionLabel 3행.
- 카드 폭/높이 약 1.4배 확장.
- 미선택 알파 0.5 → 0.78 상향. 미선택 fill 살짝 색 깔기(`id.color α 0.08`). 미선택 stroke도 진하게(`id.color α 0.4`).
- 부제 라벨 색 `.ganhoUITextDim` → `.ganhoNavyMuted`로 가독성 향상.
- 카드가 커지면 `difficultyCardSpacing`도 비례 확대, summary 카드 위치(`difficultySelectSummaryCardOffsetX`)도 좌측으로 조금 더 밀어 시각 균형 유지.

---

## 변경 범위

### 수정할 파일

- `GanhoMusic iOS/GameViewController.swift` — SKView mount를 safe area에 묶음.
- `GanhoMusic Shared/Models/Difficulty.swift` — `description: String` computed property 추가.
- `GanhoMusic Shared/Nodes/DifficultyCardNode.swift` — 카드 크기 확장 + descriptionLabel 추가 + 미선택 시각 강화.
- `GanhoMusic Shared/Scenes/CharacterSelectScene.swift` — 카드 spacing v3 적용 + 카드별 y 미세 오프셋.
- `GanhoMusic Shared/Scenes/DifficultySelectScene.swift` — summary 카드 offset 조정 + 3장 카드 layout 비례 갱신.
- `GanhoMusic Shared/Config/GameConfig.swift` — 신규 상수 추가 (`*V3`, `*Description*`).

### 추가할 파일

없음.

---

## 기능 상세

### 기능 1: SKView Safe Area Mount (GameViewController)

- **설명**: SKView를 view 전체에 깔지 않고, `view.safeAreaLayoutGuide` 영역에만 마운트한다. view.backgroundColor에 그라데이션 top 색을 fallback으로 깔아 노치 영역 비주얼 연속성을 유지.
- **구현 위치**: `GameViewController.swift` — `viewDidLoad()` + 새 `viewSafeAreaInsetsDidChange()` + `viewDidLayoutSubviews()` + private `relayoutSKView()`.
- **핵심 코드 구조** (의사코드):

  ```swift
  // GameViewController.viewDidLoad
  override func viewDidLoad() {
      super.viewDidLoad()

      // 1) 시스템 보장 fallback — safe area 바깥(노치 영역)에서도 warm 톤 유지
      view.backgroundColor = .ganhoBgWarmTop

      // 2) Storyboard의 SKView 자식을 safeAreaLayoutGuide에 묶음
      guard let skView = self.view as? SKView else {
          assertionFailure("Root view must be SKView. Check Main.storyboard.")
          return
      }

      // Storyboard 제약으로는 풀스크린이 박혀 있으므로 코드에서 frame을 safe area로 갱신.
      skView.translatesAutoresizingMaskIntoConstraints = true
      skView.frame = view.safeAreaLayoutGuide.layoutFrame
      skView.autoresizingMask = []  // 자동 리사이즈는 끄고 우리가 직접 조정

      let scene = StartScene.newStartScene()
      skView.presentScene(scene)

      skView.ignoresSiblingOrder = true
      #if DEBUG
      skView.showsFPS = true
      skView.showsNodeCount = true
      #endif
  }

  // 회전 / multitasking으로 inset이 바뀔 때 SKView도 따라간다
  override func viewSafeAreaInsetsDidChange() {
      super.viewSafeAreaInsetsDidChange()
      relayoutSKView()
  }

  override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      relayoutSKView()
  }

  private func relayoutSKView() {
      guard let skView = self.view as? SKView else { return }
      let target = view.safeAreaLayoutGuide.layoutFrame
      // frame 갱신이 실제로 바뀐 경우에만 — SKScene의 didChangeSize 폭주 방지
      if skView.frame != target {
          skView.frame = target
      }
  }
  ```

- **연쇄 효과**:
  - 4개 씬의 `frame.minX` / `maxX` / `minY` / `maxY`가 자동으로 safe area 내부 좌표가 되므로, 각 씬 layout 코드는 *그대로* 작동.
  - `didChangeSize(_:)`가 호출되면서 모든 layoutXxx()가 새 frame 기준으로 재계산.
  - 그라데이션 배경 노드가 safe area 크기에 맞춰 재생성됨(`rebuildGradientBackground()`). 노치 영역은 view.backgroundColor의 warm top 색이 자연스럽게 차지.

- **주의사항**:
  - SKView의 storyboard 제약을 코드에서 override하므로 `translatesAutoresizingMaskIntoConstraints = true`로 명시.
  - `view.safeAreaLayoutGuide.layoutFrame`은 viewDidLoad 시점에 `.zero`일 수 있음 → `viewDidLayoutSubviews` / `viewSafeAreaInsetsDidChange`에서 재호출하는 게 안전.
  - `relayoutSKView`에서 frame 동일성 체크로 무한 didChangeSize 루프 방지.

### 기능 2: Difficulty enum에 description 프로퍼티 추가

- **설명**: `Difficulty` enum에 한 줄 풀이를 반환하는 computed property를 *신규* 추가. 기존 `displayName`/`subtitle`/`color`/`shortName`은 그대로.
- **구현 위치**: `Models/Difficulty.swift` — 마지막 `}` 직전.
- **핵심 코드 구조**:

  ```swift
  /// 카드에 부착되는 한 줄 풀이. subtitle보다 길고 *경험의 톤*을 전달.
  /// 게임 로직 분기 0 — 순수 시각 라벨용.
  var description: String {
      switch self {
      case .easy:   return "느린 템포로 천천히 익혀요"
      case .normal: return "적당한 도전, 손에 익는 속도"
      case .hard:   return "진땀 흐르는 청진기 모드"
      }
  }
  ```

- **주의사항**:
  - case는 *추가/삭제 금지* — raw value 직렬화 호환 유지(DifficultyPreferenceRepository).
  - `description`이라는 이름은 `CustomStringConvertible`과 시그니처가 같지만, `Difficulty`는 해당 프로토콜을 *채택하지 않는다*. Generator는 enum 선언부에 `: CustomStringConvertible` 추가 금지 — 채택하면 `String(describing:)` 동작이 변하여 회귀 가능. 만약 충돌 우려가 강하면 이름을 `tagline`/`oneLineCopy`로 바꿔도 SPEC 기능 동등.

### 기능 3: DifficultyCardNode 크기 확장 + descriptionLabel 추가 + 시인성 강화

- **설명**:
  1. 카드 폭/높이를 v3 상수로 확장 (`difficultyCardWidthV3`, `difficultyCardHeightV3`).
  2. 카드 안에 nameLabel(상단) + subtitleLabel(중단) + descriptionLabel(하단) 3행 구조로 라벨 재배치.
  3. 미선택 상태도 또렷이 — alpha 0.78, fillColor `id.color α 0.08`, strokeColor `id.color α 0.4`.
  4. 선택 시 v2 효과는 그대로 (fill `id.color α 0.2`, stroke `id.color`).
- **구현 위치**: `Nodes/DifficultyCardNode.swift` — `init(id:)` + `setSelected(_:)` + `configureLabels()`.
- **핵심 코드 구조**:

  ```swift
  final class DifficultyCardNode: SKNode {

      let id: Difficulty
      private let background: SKShapeNode
      private let nameLabel: SKLabelNode
      private let subtitleLabel: SKLabelNode
      private let descriptionLabel: SKLabelNode      // 신규
      private let ringGlow: SKShapeNode

      init(id: Difficulty) {
          self.id = id
          let cardSize = CGSize(
              width: GameConfig.difficultyCardWidthV3,    // 신규 v3 상수
              height: GameConfig.difficultyCardHeightV3
          )
          background = SKShapeNode(
              rectOf: cardSize,
              cornerRadius: GameConfig.difficultyCardCornerRadiusV3
          )
          // 미선택 기본 — id.color α 0.08 fill + id.color α 0.4 stroke
          background.fillColor = id.color.withAlphaComponent(
              GameConfig.difficultyCardDeselectedFillAlphaV3
          )
          background.strokeColor = id.color.withAlphaComponent(
              GameConfig.difficultyCardDeselectedStrokeAlphaV3
          )
          background.lineWidth = GameConfig.difficultyCardStrokeLineWidthV3

          nameLabel = SKLabelNode(text: id.displayName)
          subtitleLabel = SKLabelNode(text: id.subtitle)
          descriptionLabel = SKLabelNode(text: id.description)   // 신규

          // ringGlow는 기존 그대로 — 단 padding/lineWidth 등은 v3 카드 크기에 맞춰 사용
          let ringSize = CGSize(
              width: cardSize.width + GameConfig.difficultyCardRingGlowPadding,
              height: cardSize.height + GameConfig.difficultyCardRingGlowPadding
          )
          ringGlow = SKShapeNode(rectOf: ringSize, cornerRadius: ringSize.height / 2)
          ringGlow.fillColor = .clear
          ringGlow.strokeColor = .ganhoAccentCoral
          ringGlow.lineWidth = GameConfig.difficultyCardRingGlowLineWidth
          ringGlow.glowWidth = GameConfig.difficultyCardRingGlowWidth
          ringGlow.alpha = 0

          super.init()
          name = "difficultyCard_\(id.rawValue)"
          zPosition = 100

          background.position = .zero
          ringGlow.position = .zero
          ringGlow.zPosition = -1

          addChild(ringGlow)
          addChild(background)
          configureLabels()
          addChild(nameLabel)
          addChild(subtitleLabel)
          addChild(descriptionLabel)
      }

      func setSelected(_ selected: Bool) {
          alpha = selected ? 1.0 : GameConfig.difficultyCardDeselectedAlphaV3
          // ↑ characterCardDeselectedAlpha(0.5) 대신 v3 상수(0.78) 사용

          // 기존 spring overshoot 시퀀스는 그대로 유지
          removeAction(forKey: "cardScale")
          if selected {
              let overshoot = SKAction.scale(
                  to: GameConfig.difficultyCardSpringOvershootScale,
                  duration: GameConfig.difficultyCardSpringPhase1Duration
              )
              overshoot.timingMode = .easeOut
              let settle = SKAction.scale(
                  to: GameConfig.characterCardSelectedScale,
                  duration: GameConfig.difficultyCardSpringPhase2Duration
              )
              settle.timingMode = .easeInEaseOut
              run(SKAction.sequence([overshoot, settle]), withKey: "cardScale")
          } else {
              run(
                  SKAction.scale(to: 1.0, duration: GameConfig.characterCardScaleDuration),
                  withKey: "cardScale"
              )
          }

          // v3 — 미선택도 색을 깔되 옅게(α 0.08), 선택 시 진한 fill(α 0.2)
          background.fillColor = selected
              ? id.color.withAlphaComponent(GameConfig.difficultyCardSelectedFillAlphaV3)
              : id.color.withAlphaComponent(GameConfig.difficultyCardDeselectedFillAlphaV3)
          background.strokeColor = selected
              ? id.color
              : id.color.withAlphaComponent(GameConfig.difficultyCardDeselectedStrokeAlphaV3)

          nameLabel.fontColor = selected ? .ganhoNavyDeep : .ganhoNavyMuted
          subtitleLabel.fontColor = .ganhoNavyMuted
          descriptionLabel.fontColor = selected ? .ganhoNavyDeep : .ganhoNavyMuted

          // ringGlow는 기존 그대로
          ringGlow.removeAction(forKey: "ringFade")
          let targetAlpha: CGFloat = selected ? 1.0 : 0.0
          let duration: TimeInterval = selected
              ? GameConfig.difficultyCardRingGlowFadeInDuration
              : GameConfig.difficultyCardRingGlowFadeOutDuration
          ringGlow.run(
              SKAction.fadeAlpha(to: targetAlpha, duration: duration),
              withKey: "ringFade"
          )
      }

      private func configureLabels() {
          // 이름 라벨 — 카드 상단
          nameLabel.fontName = GameConfig.fontDisplay
          nameLabel.fontSize = GameConfig.difficultyCardFontSizeV3   // 24pt
          nameLabel.fontColor = .ganhoNavyMuted
          nameLabel.horizontalAlignmentMode = .center
          nameLabel.verticalAlignmentMode = .center
          nameLabel.position = CGPoint(x: 0, y: GameConfig.difficultyCardNameOffsetYV3)

          // 부제 — 중단
          subtitleLabel.fontName = GameConfig.fontBody
          subtitleLabel.fontSize = GameConfig.difficultyCardSubtitleFontSizeV3   // 12pt
          subtitleLabel.fontColor = .ganhoNavyMuted
          subtitleLabel.horizontalAlignmentMode = .center
          subtitleLabel.verticalAlignmentMode = .center
          subtitleLabel.position = CGPoint(x: 0, y: GameConfig.difficultyCardSubtitleOffsetYV3)

          // 설명 — 하단 (신규)
          descriptionLabel.fontName = GameConfig.fontBody
          descriptionLabel.fontSize = GameConfig.difficultyCardDescriptionFontSizeV3   // 10pt
          descriptionLabel.fontColor = .ganhoNavyMuted
          descriptionLabel.horizontalAlignmentMode = .center
          descriptionLabel.verticalAlignmentMode = .center
          descriptionLabel.numberOfLines = 0
          descriptionLabel.preferredMaxLayoutWidth = GameConfig.difficultyCardDescriptionMaxWidthV3
          descriptionLabel.position = CGPoint(x: 0, y: GameConfig.difficultyCardDescriptionOffsetYV3)
      }
  }
  ```

- **주의사항**:
  - `setSelected`의 호출 시그니처는 *불변* — DifficultySelectScene이 그대로 호출.
  - `removeAction(forKey:)` 패턴 유지(spring 액션 중복 방지).
  - ringGlow는 v2 그대로 살림(시각 일관성). lineWidth/glowWidth 상수는 기존 값 재사용.
  - 라벨 fontName을 `GameConfig.fontDisplay` / `fontBody`로 명시 — Jua/Gowun Dodum 톤 유지.

### 기능 4: CharacterSelectScene 카드 여백 + 지그재그 오프셋

- **설명**:
  1. `characterCardSpacing` 10pt → v3 상수로 28pt 정도 확대.
  2. 카드별 y 미세 오프셋(–6 / +8 / –4 / +6 / –6 같은 패턴)으로 정렬되지 않은 부유감 부여.
- **구현 위치**: `Scenes/CharacterSelectScene.swift` — `cardBaseX(for:)` / `cardBaseY(for:)` 메서드.
- **핵심 코드 구조**:

  ```swift
  // cardBaseX는 spacing만 v3로 교체
  private func cardBaseX(for id: CharacterID) -> CGFloat {
      let allCases = CharacterID.allCases
      let count = allCases.count
      let width = GameConfig.characterCardGlassWidth
      let spacing = GameConfig.characterCardSpacingV3   // v3 — 기존 characterCardSpacing 미사용
      let totalWidth = width * CGFloat(count) + spacing * CGFloat(count - 1)
      let startX = frame.midX - totalWidth / 2 + width / 2
      guard let index = allCases.firstIndex(of: id) else { return startX }
      return startX + CGFloat(index) * (width + spacing)
  }

  /// 카드별 y 미세 오프셋. 5장 지그재그 패턴.
  private func cardBaseY(for id: CharacterID) -> CGFloat {
      let baseY = frame.midY + GameConfig.characterSelectCardOffsetY
      let allCases = CharacterID.allCases
      guard let index = allCases.firstIndex(of: id) else { return baseY }
      let offsets = GameConfig.characterSelectCardYOffsetsV3  // [CGFloat] — 5개
      let safe = index < offsets.count ? offsets[index] : 0
      return baseY + safe
  }
  ```

- **연쇄 효과**:
  - `setupCharacterCards` / `layoutCharacterCards` / `setupCardContainers` / `layoutCardContainers` / `setupCardColorDots` / `layoutCardColorDots` / `setupCharacterFaces` / `layoutCharacterFaces` / `setupTagLabels` / `layoutTagLabels`는 모두 `cardBaseX(for:)` / `cardBaseY(for:)`를 통해 좌표를 얻으므로 자동 동기화. 추가 코드 변경 0.
  - 선택 시 `applyGlassContainerSelection`이 `let baseY = cardBaseY(for: cid)`를 호출 → 지그재그가 선택 애니메이션의 기준점에도 자연 반영됨. 시각 모순 없음.
- **주의사항**:
  - 기존 `characterCardSpacing` 상수는 *유지*(다른 곳 참조 가능성). 본 화면만 v3 상수로 분기.
  - 지그재그 오프셋 배열은 컴파일타임 고정(`static let` 5개 원소). 인덱스 안전 체크 포함.
  - 카드별 z-rotation은 본 sprint 범위에서 *제외* — Generator가 욕심내지 않도록 명시. y 오프셋만으로 충분히 흩어진 인상. rotation은 hit test와 글래스 컨테이너 외곽 형상에 영향을 줘 회귀 리스크 증가.

### 기능 5: DifficultySelectScene 좌측 summary 카드와 우측 3장 카드 시각 균형

- **설명**: 카드가 1.4배 커지면(80→112, 56→80), spacing도 16→22로 비례 확대. 가로 총 폭이 늘어나므로 `difficultySelectSummaryCardOffsetX`(-220 → -260 정도)를 좌측으로 추가로 밀어 양쪽 시각 균형 유지.
- **구현 위치**: `Scenes/DifficultySelectScene.swift` — `layoutDifficultyCards` / `layoutSummaryCard`.
- **핵심 코드 구조**:

  ```swift
  // layoutDifficultyCards는 GameConfig 상수만 v3로 교체
  private func layoutDifficultyCards() {
      let count = difficultyCards.count
      guard count > 0 else { return }
      let width = GameConfig.difficultyCardWidthV3
      let spacing = GameConfig.difficultyCardSpacingV3
      let totalWidth = width * CGFloat(count) + spacing * CGFloat(count - 1)
      let centerX = frame.midX + GameConfig.difficultySelectDifficultyRowOffsetXV3
      let startX = centerX - totalWidth / 2 + width / 2
      let y = frame.midY + GameConfig.difficultySelectDifficultyRowOffsetYV3
      for (index, card) in difficultyCards.enumerated() {
          card.position = CGPoint(
              x: startX + CGFloat(index) * (width + spacing),
              y: y
          )
      }
  }

  // layoutSummaryCard는 offsetX만 V3로 교체 — 다른 baseY 의존 자식들은 그대로
  private func layoutSummaryCard() {
      let baseX = frame.midX + GameConfig.difficultySelectSummaryCardOffsetXV3
      let baseY = frame.midY + GameConfig.difficultySelectSummaryCardOffsetY
      // ... 이하 기존과 동일
  }
  ```

- **주의사항**:
  - 기존 `difficultyCardWidth/Height/Spacing` 상수는 *유지*. 본 화면만 v3로 분기.
  - `layoutDifficultyCards`의 `centerX` 기준점은 frame.midX + offset → safe area에 자동으로 따라옴.
  - 시작 버튼(`difficultySelectStartButtonOffsetY = -160`)은 카드 row offset이 -10이므로 카드 row가 가운데, 시작 버튼이 그 아래. 카드 높이가 56→80으로 +24pt 늘어도 시작 버튼과의 간격이 -150 → -126 정도여서 충돌 없음. Generator가 실제 빌드에서 확인 후 필요 시 시작 버튼 offsetY를 -10~-20 추가 하향 가능 (v3 상수 분기 권장).
  - 좌측 summary 카드는 width 200, 우측 3장 카드 합계 폭(112×3 + 22×2 = 380). 좌측 summary 중심이 midX-260, 우측 3장 중심이 midX+110 → 시각 균형 적절. Generator가 실제 화면에서 미세 조정 가능.

### 기능 6: GameConfig 신규 상수 일람

새 상수는 **모두 `*V3` 또는 `*Description*` 접미사**로 추가. 기존 상수는 한 줄도 *값 변경하지 않는다*(다른 사용처 회귀 방지).

```swift
// MARK: - Sprint Visual-3 · Safe Area + Cards V3

// --- DifficultyCardNode v3 ---
/// v3 카드 폭(112pt). 기존 difficultyCardWidth(80) 대비 1.4배.
static let difficultyCardWidthV3: CGFloat = 112
/// v3 카드 높이(80pt). description 라벨 추가에 따른 세로 공간 확장.
static let difficultyCardHeightV3: CGFloat = 80
/// v3 카드 코너 반경(20pt). 캡슐 → 둥근 사각형 톤. height/2=40보다 작아 카드 인상.
static let difficultyCardCornerRadiusV3: CGFloat = 20
/// v3 카드 spacing(22pt). 기존 16 대비 +6.
static let difficultyCardSpacingV3: CGFloat = 22
/// v3 카드 stroke 두께(1.5pt).
static let difficultyCardStrokeLineWidthV3: CGFloat = 1.5

/// v3 미선택 카드 알파(0.78). 기존 characterCardDeselectedAlpha(0.5) 대비 +0.28 — 흐림 해소.
static let difficultyCardDeselectedAlphaV3: CGFloat = 0.78
/// v3 미선택 fill alpha — id.color × 0.08. 살짝 깔리는 톤.
static let difficultyCardDeselectedFillAlphaV3: CGFloat = 0.08
/// v3 미선택 stroke alpha — id.color × 0.4. 미선택도 색 대비 명확.
static let difficultyCardDeselectedStrokeAlphaV3: CGFloat = 0.4
/// v3 선택 fill alpha — id.color × 0.2. 기존 Phase 8-3 값 유지.
static let difficultyCardSelectedFillAlphaV3: CGFloat = 0.2

/// v3 nameLabel 폰트 크기(24pt). 기존 20 대비 +4.
static let difficultyCardFontSizeV3: CGFloat = 24
/// v3 subtitleLabel 폰트 크기(12pt). 기존 10 대비 +2.
static let difficultyCardSubtitleFontSizeV3: CGFloat = 12
/// v3 descriptionLabel 폰트 크기(10pt). 한 줄 풀이.
static let difficultyCardDescriptionFontSizeV3: CGFloat = 10
/// v3 description 라벨 최대 폭(카드 폭 - 좌우 16pt 패딩 = 96pt).
static let difficultyCardDescriptionMaxWidthV3: CGFloat = 96

/// v3 nameLabel y offset (+22 — 카드 상단).
static let difficultyCardNameOffsetYV3: CGFloat = 22
/// v3 subtitleLabel y offset (+2 — 카드 중간 살짝 위).
static let difficultyCardSubtitleOffsetYV3: CGFloat = 2
/// v3 descriptionLabel y offset (-22 — 카드 하단).
static let difficultyCardDescriptionOffsetYV3: CGFloat = -22

// --- DifficultySelectScene v3 ---
/// v3 우측 3장 카드 행의 centerX 오프셋(+110). 기존 동일 — 우측 영역 중앙.
static let difficultySelectDifficultyRowOffsetXV3: CGFloat = 110
/// v3 우측 3장 카드 행의 y 오프셋(-10). 기존 동일 — summary와 같은 baseline.
static let difficultySelectDifficultyRowOffsetYV3: CGFloat = -10
/// v3 좌측 summary 카드 offsetX(-260). 기존 -220 대비 좌측으로 -40 추가 — 우측 카드 폭 확장에 대한 균형.
static let difficultySelectSummaryCardOffsetXV3: CGFloat = -260

// --- CharacterSelectScene v3 ---
/// v3 캐릭터 카드 간 spacing(28pt). 기존 characterCardSpacing(10) 대비 +18 — 흩어진 인상.
static let characterCardSpacingV3: CGFloat = 28
/// v3 카드별 y 미세 오프셋(지그재그 패턴). [좌→우 5개]. 인덱스 안전 체크는 호출부.
static let characterSelectCardYOffsetsV3: [CGFloat] = [-6, 8, -4, 6, -6]
```

- **주의사항**:
  - GameConfig.swift는 거대 파일 — 새 섹션은 파일 끝 `// MARK: - Sprint Visual-3 · ...`로 명확히 분리.
  - 매직 넘버 0 — 모든 값은 한국어 주석으로 의미 한 줄 설명.
  - `characterSelectCardYOffsetsV3`는 `[CGFloat]` 배열 — `static let`으로 컴파일타임 고정. 인덱스 안전 체크는 호출부에서 한다.

### 기능 7: ResultScene — 추가 변경 없음 (Safe Area로 자동 해결)

- ResultScene은 좌우 가장자리 콘텐츠가 거의 없고(공유 버튼과 다시시작 버튼은 frame.midX 기준 ±70~80pt 오프셋), panel은 가운데 380pt 폭. SKView가 safe area에 맞춰 mount되면 panel과 버튼이 자동으로 안전 영역 안에 자리잡음.
- 변경 0. 회귀 0.

### 기능 8: StartScene — 추가 변경 없음 (Safe Area로 자동 해결)

- StartScene의 BEST/PLAYS GlassPill은 `frame.minX + 60` / `frame.maxX - 60`을 사용. SKView가 safe area에 맞춰지면 frame.minX 자체가 노치 안쪽 픽셀 → BEST 알약이 노치를 침범하지 않음.
- 타이틀 블록(`frame.maxX - 64`)도 동일하게 안전 영역 내부로 들어옴.
- 변경 0.

---

## 화면별 적용 결과 요약 (사용자가 체감할 변화)

| 화면 | 변경 전 | 변경 후 |
|---|---|---|
| StartScene | BEST 알약 노치 좌측에서 겹침. 타이틀이 우측 끝에서 잘려 보임. | 모든 콘텐츠 safe area 안. 그라데이션 배경은 노치 영역도 warm top 색 fallback으로 연속. |
| CharacterSelectScene | 5장 카드가 가운데에서 거의 맞닿음. 평평한 한 줄. | 카드 간 28pt 여백 + 지그재그 y 오프셋으로 자연스럽게 흩어진 인상. |
| DifficultySelectScene | 우측 3장 카드 흐릿(α 0.5). 부제 거의 안 보임. 설명 없음. 카드 작음. | 카드 1.4배 확장(112×80). 미선택도 α 0.78로 또렷. 미선택 fill `id.color α 0.08`로 톤 깔림. 한 줄 description 라벨 신규 (예: "느린 템포로 천천히 익혀요"). |
| ResultScene | 화면 가장자리 콘텐츠가 잘려 보일 위험. | Safe area mount로 panel 가운데 자동 정렬. 공유/다시시작 버튼 안전. |

---

## 합격 기준 (Evaluator가 채점할 항목)

### Swift 패턴 일관성 (35%)
- [ ] 강제 언래핑(`!`) 신규 0건. `guard let view = self.view as? SKView else { return }` 패턴 유지.
- [ ] `Timer.scheduledTimer` 신규 0건. SKView frame 재조정은 `viewSafeAreaInsetsDidChange` / `viewDidLayoutSubviews` 활용.
- [ ] 매직 넘버 신규 0건. 모든 새 수치는 `GameConfig.*V3` 상수로 분리.
- [ ] `[weak self]` 클로저 캡처 — 본 SPEC은 신규 클로저 없으므로 N/A. 기존 클로저 회귀 없음.
- [ ] MARK 섹션 구분 유지. 신규 코드는 `// MARK: - Sprint Visual-3 ...` 라벨로 묶음.

### 게임 로직 완성도 (30%)
- [ ] `didMove(to:)` 초기화 패턴 회귀 0건.
- [ ] `didChangeSize(_:)`에서 layout 재호출 패턴 유지.
- [ ] SKAction 키(`cardScale`, `ringFade`, `glassSelect`) 그대로.
- [ ] `DifficultyCardNode.setSelected(_:)` 시그니처 불변.
- [ ] `Difficulty` enum의 case / rawValue 불변.
- [ ] `GameScene.newGameScene(characterID:difficulty:)` 호출 시그니처 불변.

### 성능 & 안정성 (20%)
- [ ] 빌드 경고 신규 0건.
- [ ] 4개 씬 모두 60fps 유지 — 노드 증가량 미미 (DifficultyCardNode당 SKLabelNode 1개 추가, 5장도 아니고 3장).
- [ ] `viewSafeAreaInsetsDidChange` / `viewDidLayoutSubviews`에서 SKView frame 동일성 체크로 무한 재호출 방지 (`if skView.frame != target`).
- [ ] `view.backgroundColor = .ganhoBgWarmTop` — UIColor extension(`ColorTokens`)에 이미 정의된 토큰만 사용. 하드코딩 색상 0건.

### 기능 완성도 (15%)
- [ ] iPhone 17 Pro landscape 시뮬레이터에서 4개 화면 가장자리 잘림 0건.
- [ ] CharacterSelectScene 5장 카드 간 시각적 여백 명확.
- [ ] DifficultyCard 미선택 상태가 또렷이 보임 (사용자 "흐리다" 불만 해소).
- [ ] DifficultyCard에 한 줄 description 라벨 표시 (3개 난이도 각각 다른 문구).
- [ ] DifficultyCard 크기 1.4배 이상 확장.
- [ ] 게임플레이/저장/사운드 회귀 0건 — Repository 메서드, AudioManager.play, HapticsManager 호출부 변경 0.

---

## 디자인 토큰 (변경 없음 — 참고)

기존 `ColorTokens.swift`에 정의된 토큰만 사용. 신규 색상 0건.

- `.ganhoBgWarmTop` / `.ganhoBgWarmMid` / `.ganhoBgWarmBottom` — 그라데이션 3-stop
- `.ganhoNavyDeep` / `.ganhoNavyMuted` — 텍스트
- `.ganhoCoralPrimary` / `.ganhoAccentCoral` — 액센트
- `.ganhoMint` / `.ganhoYellowF` / `.ganhoBloodAccent` — Difficulty.color 매핑 (각각 easy/normal/hard)
- `.ganhoUIBorder` — 기존 흰색 7% 보더 (v3에서는 미사용)
- `.ganhoMusicGold` — NEW BEST 황금 (Result, 변경 없음)
- `.ganhoScrubMint` — Summary 속도 칩 (변경 없음)

폰트:
- `GameConfig.fontDisplay` — Jua
- `GameConfig.fontBody` — Gowun Dodum

---

## 주의사항 (Generator를 위한 함정 목록)

1. **GameViewController 변경은 단 한 곳**. Storyboard를 건드리지 말 것. `translatesAutoresizingMaskIntoConstraints = true`로 명시하고 `frame`만 코드에서 갱신.

2. **`relayoutSKView`의 무한 루프 방지**. `if skView.frame != target` 조건 빠뜨리면 `viewDidLayoutSubviews` → `frame` 변경 → 다시 layout → 무한 호출 가능. 반드시 동일성 체크.

3. **DifficultyCardNode의 `setSelected(_:)` 시그니처 불변**. DifficultySelectScene.setupDifficultyCards / selectDifficulty가 그대로 호출하고 있음.

4. **`Difficulty.description` 이름 충돌 가능성**. Swift 표준 `CustomStringConvertible` 프로토콜의 `var description: String { get }`과 시그니처가 동일하지만, `Difficulty`가 해당 프로토콜을 채택하지 않는다면 충돌 없음. Generator는 enum 선언부에서 `: CustomStringConvertible` 추가하지 말 것 — 채택하면 `String(describing:)` 동작이 변하여 회귀 가능. 또는 이름을 `tagline`/`oneLineCopy`로 바꿔도 SPEC 기능 동등.

5. **`characterCardSpacing` 상수 자체는 유지**. 다른 화면에서 참조 가능성. 본 SPEC은 *값 변경 금지, 새 상수 추가만*.

6. **`Difficulty` enum의 raw value("easy"/"normal"/"hard") 절대 변경 금지**. `DifficultyPreferenceRepository`가 UserDefaults에 raw string으로 저장 — case 이름이나 raw value가 바뀌면 기존 사용자 설정이 무효화.

7. **그라데이션 배경 fallback**. `view.backgroundColor = .ganhoBgWarmTop` 한 줄로 노치 영역 자연 톤 유지. 더 정교한 그라데이션은 본 sprint 범위 밖.

8. **NurseAvatarNode 위치**. StartScene의 `nurseAvatarOffsetX = 180`은 `frame.minX + 180` 기준. safe area 적용 후 frame.minX가 노치 안쪽으로 들어오므로 NurseAvatar가 화면 가장자리에서 *살짝 멀어진다*. 의도된 변경이며 추가 조정 불필요.

9. **DifficultySelectScene의 summary 카드 offsetX 변경**. -220 → -260으로 좌측 이동 시, summary 카드 폭이 200pt라 좌측 경계가 `centerX - 260 - 100 = midX - 360`. iPhone 17 Pro landscape safe area 가로 ~800pt 기준 midX가 400pt 근처, 따라서 좌측 경계 40pt 근처 — 안전. Generator는 실제 빌드에서 한 번 확인.

10. **DifficultyCardNode의 ringGlow padding 상수 재사용**. `difficultyCardRingGlowPadding = 10`은 카드 크기가 80→112로 커져도 동일하게 +10pt만 외곽으로 빛남. 시각적으로 충분 — 별도 v3 padding 불필요.

11. **SKLabelNode `numberOfLines = 0` + `preferredMaxLayoutWidth`**. description 라벨이 카드 폭(112pt - 좌우 패딩 16pt = 96pt)을 넘으면 자동 줄바꿈. 9~13자 한글 한 줄이 96pt에 들어가도록 description 문구 길이를 조절했음.

12. **테스트 시뮬레이터**. iPhone 17 Pro 외에 iPhone SE(노치 없음), iPhone 15(노치 있음) 등에서도 잘림이 없어야 함. Safe area 기반이므로 모든 기기에서 자동 작동.

13. **`background.lineWidth` 상수 분리**. 기존 코드는 `GameConfig.uiPanelLineWidth`를 사용했음. v3는 `difficultyCardStrokeLineWidthV3 = 1.5`로 분기. 카드 강조에 적절한 두께.

---

## 변경 후 파일 라인 수 예측 (참고)

| 파일 | 변경 전 | 변경 후 예상 | 증가 |
|---|---|---|---|
| GameViewController.swift | 63 | ~95 | +32 |
| Difficulty.swift | 54 | ~70 | +16 |
| DifficultyCardNode.swift | 145 | ~195 | +50 |
| CharacterSelectScene.swift | 479 | ~485 | +6 |
| DifficultySelectScene.swift | 448 | ~450 | +2 |
| GameConfig.swift | ~1730 | ~1790 | +60 (신규 상수) |

총 +166 라인. 새 파일 0.

---

## 최종 체크리스트 (Generator가 완료 시 자가 확인)

- [ ] GameViewController.viewDidLoad에서 view.backgroundColor와 SKView.frame 갱신.
- [ ] viewSafeAreaInsetsDidChange + viewDidLayoutSubviews에서 relayoutSKView 호출.
- [ ] relayoutSKView 내부에 `if skView.frame != target` 가드.
- [ ] Difficulty.description 추가 (3 case 모두).
- [ ] DifficultyCardNode에 descriptionLabel(SKLabelNode) property 추가.
- [ ] DifficultyCardNode.init에서 v3 상수 사용 (Width/Height/CornerRadius/StrokeLineWidth).
- [ ] DifficultyCardNode.setSelected에서 v3 alpha 사용 (deselected 0.78).
- [ ] DifficultyCardNode.setSelected에서 fillColor: id.color × 0.08 (deselected) / × 0.2 (selected).
- [ ] DifficultyCardNode.setSelected에서 strokeColor: id.color × 0.4 (deselected) / id.color (selected).
- [ ] DifficultyCardNode의 3 라벨 fontColor가 .ganhoNavyDeep / .ganhoNavyMuted 토큰.
- [ ] CharacterSelectScene.cardBaseX에서 characterCardSpacingV3 사용.
- [ ] CharacterSelectScene.cardBaseY에서 characterSelectCardYOffsetsV3 적용.
- [ ] DifficultySelectScene.layoutDifficultyCards에서 v3 상수 사용.
- [ ] DifficultySelectScene.layoutSummaryCard에서 difficultySelectSummaryCardOffsetXV3 사용.
- [ ] GameConfig에 신규 V3 상수 모두 정의 + 한국어 주석 부여.
- [ ] 기존 GameConfig 상수의 값 변경 0건 (새 상수 추가만).
- [ ] 빌드 에러 0, 신규 경고 0.
- [ ] iPhone 17 Pro landscape 시뮬레이터에서 4개 화면 잘림 없음 (Generator가 직접 빌드 후 확인).
