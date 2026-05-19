# 디자인 리뉴얼 Sprint 2 — 메뉴 3씬 v2 리스킨 (StartScene · CharacterSelectScene · SkillExplanationScene)

## 개요
Sprint 1에서 깔린 v2 디자인 시스템(ColorTokens v2 16토큰 / Jua·Gowun Dodum·NotoSansKR 폰트 상수 / GlassPillNode·AccentLineNode·DarkContextChipNode 신규 노드 3종 / 코랄 PrimaryButtonNode / GlassPill 톤 BackButtonNode / GradientBackgroundNode.threeStop) 인프라를 사용해, 메뉴 3씬(StartScene / CharacterSelectScene / SkillExplanationScene)을 `mockups/main-screen-v2.html` · `character-select-v2.html` · `skill-explanation-v2.html`과 시각 매칭시킨다. 게임 로직·전환 로직·저장소 호출은 *한 줄도* 변경하지 않는다. 캐릭터 일러스트 자리는 Sprint 4 대기용 placeholder로 비워두되 기존 PixelSprite 아바타는 SkillExplanationScene에서 그대로 유지(시각 회귀 0건).

## 변경 유형
**비주얼** — 메뉴 3씬 시각 갱신 (게임플레이 회귀 0).

## 게임 경험 의도
사용자가 앱을 켠 순간 첫 0.5초 안에 *유머·따뜻함·터치하고 싶음* 셋을 동시에 느끼게 한다. 다크한 야간 병동 톤에서 떠나, 피치→코랄→라벤더로 흐르는 노을 그라데이션과 둥근 Jua 타이틀, 입체 코랄 CTA로 "이건 카툰 게임이고, 시작 버튼을 누르면 좋은 일이 일어난다"가 즉시 읽혀야 한다. 캐릭터 선택과 스킬 설명까지 같은 디자인 시스템을 공유해 *시각 톤 단절 0*.

## Sprint 2 범위 계약

### IN — 본 Sprint에서 수정/추가
- `Scenes/StartScene.swift` — 배경·타이틀·BEST/PLAYS·태그라인·시작 버튼 v2 재구성
- `Scenes/CharacterSelectScene.swift` — 배경·헤더+AccentLine·top bar(GlassPill 백 + DarkContextChip 난이도)·5장 글래스 카드 외곽 + 색 점·하단 스킬 정보 패널·confirm 버튼
- `Scenes/SkillExplanationScene.swift` — 배경·헤더+AccentLine·top bar(GlassPill 백 + DarkContextChip 브레드크럼)·좌측 큰 아바타 글래스 카드·우측 코랄 라벨/Jua 36pt 스킬명/인용 박스/메타 칩 3개·컨트롤 힌트·하단 버튼 2개
- `Config/GameConfig.swift` — Sprint 2 전용 신규 레이아웃/스타일 상수만 *추가* (기존 값 변경 0). 명명은 `characterSelectColorDotSize`처럼 씬 prefix 일관성.
- `Models/Difficulty.swift` — `shortName` computed property *추가만* (게임 로직 분기 0)
- `Models/PlayerSkill.swift` — `rangeText`, `castText` computed property *추가만* (게임 로직 분기 0)
- `Models/CharacterID.swift` (또는 동등 위치) — `dotColor` computed property *추가만*

### OUT — 본 Sprint에서 절대 손대지 않음
- **게임 수치/로직 전체** (`scorePerNote`, `comboWindow`, `projectileSpeed`, `tileSize`, 45초, `PhysicsCategory`, `ContactRouter`, `PlayerSkill` 메타데이터, `Difficulty` 분기, `EnemyNode`/`ProfessorNode`/`StoneGuardNode` AI)
- **저장소**: `HighScoreRepository`, `StatisticsRepository`, `PerDifficultyScoreRepository`, `GraduationRepository`, `CharacterPreferenceRepository`, `DifficultyPreferenceRepository` 호출 패턴·저장 키·current 복원 시점 — *현재 위치에서 그대로*
- **씬 전환 시그니처**: `StartScene → CharacterSelectScene(difficulty:)`, `CharacterSelectScene → GameScene(characterID:difficulty:) | SkillExplanationScene(characterID:difficulty:)` (.kim 스킵 분기 보존), `SkillExplanationScene → GameScene(characterID:difficulty:) | CharacterSelectScene(difficulty:)` — init 인자 0건 추가/삭제
- **GameScene / GameScene+Setup / ResultScene** 파일은 본 Sprint에서 *0건 수정*
- **Sprint 1 결과물 내부 변경 금지**: `GlassPillNode`, `AccentLineNode`, `DarkContextChipNode`, `GradientBackgroundNode`, `PrimaryButtonNode`, `BackButtonNode`의 init 시그니처·내부 구조·name·zPosition — 본 Sprint는 *호출만*
- **ColorTokens 토큰 삭제 금지** — Phase 10-2의 `ganhoAccentTeal`/`ganhoAccentTealDeep`/`ganhoAccentCoral`은 사용처에서 v2 토큰으로 교체되더라도 토큰 자체는 *유지*
- **BGM / 효과음 트리거** (현재 메뉴 3씬은 BGM 호출이 없으면 그대로, 있으면 그대로)
- **씬 전환 transition 종류·duration**(`SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)`) — 변경 0

### 판단 기준
"이 변경이 없으면 Sprint 2 시각 매칭이 깨지는가?" → YES면 IN, NO면 OUT. 본 Sprint는 *시각만*.

## 불변 계약 표 (보존 필수)

### StartScene
| 항목 | 보존 항목 |
|---|---|
| Factory | `class func newStartScene() -> StartScene`, `scaleMode = .resizeFill` |
| 초기화 | `didMove(to:)` 진입점, `selectedDifficulty = difficultyRepo.current` 복원 |
| 입력 | `touchesBegan` 우선순위: 난이도 카드 → 시작 버튼 (외 영역 무동작) |
| 저장 | `selectDifficulty(_:)` 내 `difficultyRepo.save(id)` |
| 전환 | `transitionToNext` → `CharacterSelectScene.newCharacterSelectScene(difficulty: self.selectedDifficulty)` + `SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)` |
| isTransitioning | guard 패턴 그대로 |
| BEST/PLAYS 계산 | `HighScoreRepository().current`, `StatisticsRepository().current.playCount` 호출 위치·시점 |
| 난이도 카드 | `DifficultyCardNode(id:)` × 3, `setSelected` 토글, spring/링 글로우(Phase 10-2 내부 효과) — **보존** |
| `_ = characterRepo` 정적 의존 회피 | 보존 |

### CharacterSelectScene
| 항목 | 보존 항목 |
|---|---|
| Factory | `class func newCharacterSelectScene(difficulty:) -> CharacterSelectScene`, `private init(size:difficulty:)`, `required init?(coder:)` |
| 초기화 | `selectedCharacterID = preferenceRepo.current` 복원 |
| 입력 | `touchesBegan` 우선순위: 카드 → 뒤로 → confirm |
| 저장 | `select(_:)` 내 `preferenceRepo.save(id)` |
| 카드 | `CharacterCardNode(id:)` × 5 인스턴스, `setSelected` 호출 패턴 **내부 변경 0** (시각은 카드 *외곽 컨테이너*에서만 처리) |
| 카드 5장 가로 정렬 좌표식 | `startX = frame.midX - totalWidth/2 + width/2`, `(width + spacing) * index` — *그대로* |
| 전환 (뒤로) | `transitionToStart` → `StartScene.newStartScene()` |
| 전환 (confirm) | `.kim` → `GameScene.newGameScene(characterID:difficulty:)`, 그 외 → `SkillExplanationScene.newSkillExplanationScene(characterID:difficulty:)` |
| `difficulty: let` 불변 | 보존 |

### SkillExplanationScene
| 항목 | 보존 항목 |
|---|---|
| Factory | `class func newSkillExplanationScene(characterID:difficulty:) -> SkillExplanationScene`, `private init(size:characterID:difficulty:)`, `required init?(coder:)` |
| 큰 아바타 | `PixelSprite.data(for:direction:.down,frame:.idle)` + `PixelPalette.palette(for:)` + `PixelSpriteRenderer.texture(from:palette:)` 호출 흐름 — *보존* (Sprint 4에서 PNG 마이그레이션) |
| 스킬 본문 텍스트 출처 | `characterID.skill.fullDescription` 호출 — **보존** (StoryBoxNode는 인용 박스로 *치환*, 텍스트 출처는 그대로) |
| 입력 | `touchesBegan` 우선순위: 뒤로 → 시작 |
| 전환 (뒤로) | `transitionToCharacterSelect` → `CharacterSelectScene.newCharacterSelectScene(difficulty: difficulty)` |
| 전환 (시작) | `transitionToGame` → `GameScene.newGameScene(characterID: characterID, difficulty: difficulty)` |

## Phase 10-2 자산 보존/교체 결정

| 자산 | Sprint 2 처리 |
|---|---|
| `GradientBackgroundNode` 2-stop (teal/tealDeep) | **교체** — `GradientBackgroundNode.threeStop(size:topColor:.ganhoBgWarmTop, midColor:.ganhoBgWarmMid, bottomColor:.ganhoBgWarmBottom)` 호출로 갈아끼움. 인스턴스 참조 보관·`rebuildGradientBackground` 패턴은 *그대로 유지* (didChangeSize 안전성) |
| `MusicNoteEmitterNode` | **StartScene에서 보존**(색 톤 변경 0건). CharacterSelectScene/SkillExplanationScene에는 *추가하지 않음*(OPEN_QUESTION Q4 참조) |
| `GlowingTitleNode` | **StartScene에서 제거** — v2 mockup은 그라데이션 BG 위 *flat* Jua 56pt 코랄/네이비 타이틀(글로우 0). 클래스 파일 자체는 삭제하지 않음 |
| 난이도 카드 spring + 링 글로우 (`DifficultyCardNode` 내부 효과) | **보존** — 인스턴스 생성·setSelected 호출 패턴 그대로 |
| `ganhoAccentTeal`/`ganhoAccentTealDeep`/`ganhoAccentCoral` 토큰 | **ColorTokens에서 삭제 금지**. 단 StartScene 호출처는 v2 토큰으로 교체 |

## 변경 범위

### 수정할 파일
- `GanhoMusic Shared/Scenes/StartScene.swift`
- `GanhoMusic Shared/Scenes/CharacterSelectScene.swift`
- `GanhoMusic Shared/Scenes/SkillExplanationScene.swift`
- `GanhoMusic Shared/Config/GameConfig.swift`
- `GanhoMusic Shared/Models/Difficulty.swift` (또는 정의 위치)
- `GanhoMusic Shared/Models/PlayerSkill.swift` (또는 정의 위치)
- `GanhoMusic Shared/Models/CharacterID.swift` (또는 정의 위치)

### 추가할 파일 (없음)
신규 노드 0건. Sprint 1 인프라(GlassPill/AccentLine/DarkContextChip/PrimaryButton/BackButton/GradientBackgroundNode.threeStop) + 기존 노드(CharacterCardNode·DifficultyCardNode·MusicNoteEmitterNode·PixelSpriteRenderer)만으로 구성.

## 기능 상세

### 기능 S1: StartScene 배경 — 3-stop warm gradient
- 설명: tealDeep/teal 2-stop → ganhoBgWarmTop/Mid/Bottom 3-stop으로 교체.
- 위치: `StartScene.setupGradientBackground` / `rebuildGradientBackground` 함수 본문.
- 핵심 구조:
  ```swift
  let node = GradientBackgroundNode.threeStop(
      size: size,
      topColor: .ganhoBgWarmTop,
      midColor: .ganhoBgWarmMid,
      bottomColor: .ganhoBgWarmBottom
  )
  node.position = CGPoint(x: frame.midX, y: frame.midY)
  gradientBackground = node
  addChild(node)
  ```
- 부수: `backgroundColor = .ganhoBgDeep` 1프레임 fallback도 `.ganhoBgWarmTop`으로 교체(다크 플래시 회피).

### 기능 S2: StartScene Overlay 패널 제거
- 설명: 기존 `setupOverlayPanel`이 검정 반투명 BG + 카드 패널을 깔지만 v2는 풀스크린 그라데이션 + 글래스 칩으로만 톤 분리. 패널 제거.
- 위치: `StartScene.didMove`에서 `setupOverlayPanel()` 호출 *제거*. 함수 자체는 삭제 가능 (외부 호출자 0).

### 기능 S3: StartScene 타이틀 v2 — Jua 56pt + 코랄 강조 + AccentLine + 태그라인
- 설명: `GlowingTitleNode` 제거. 2-라인 타이틀(L1 "김간호는" 네이비 / L2 "음악박사 ♪" 코랄) + 위쪽 AccentLineNode + Gowun Dodum 태그라인.
- 위치: `setupLabels` / `layoutLabels`.
- 핵심 구조:
  ```swift
  private let accentLine = AccentLineNode()
  private let titleLine1 = SKLabelNode(fontNamed: GameConfig.fontDisplay)
  private let titleLine2 = SKLabelNode(fontNamed: GameConfig.fontDisplay)
  private let taglineLabel = SKLabelNode(fontNamed: GameConfig.fontBody)

  titleLine1.text = "김간호는"
  titleLine1.fontSize = GameConfig.startSceneTitleLine1FontSize
  titleLine1.fontColor = .ganhoNavyDeep
  titleLine2.text = "음악박사 ♪"
  titleLine2.fontSize = GameConfig.startSceneTitleLine2FontSize
  titleLine2.fontColor = .ganhoCoralPrimary
  taglineLabel.text = "수간호사 몰래, 떠오른 멜로디를\n45초 안에 모아 보세요"
  taglineLabel.fontSize = GameConfig.startSceneTaglineFontSize
  taglineLabel.fontColor = .ganhoNavyMuted
  taglineLabel.numberOfLines = 0
  taglineLabel.preferredMaxLayoutWidth = GameConfig.startSceneTaglineMaxWidth
  ```
- 정렬: 우측 정렬(타이틀 블록이 우측, 캐릭터 placeholder가 좌측). 단 *난이도 카드 3장은 가운데 정렬 유지*. 타이틀과 카드가 시각적으로 겹치지 않게 y 오프셋만 조정.
- 신규 GameConfig 상수: `startSceneTitleLine1FontSize`(44) / `startSceneTitleLine2FontSize`(56) / `startSceneTaglineFontSize`(13) / `startSceneTaglineMaxWidth`(240) / `startSceneTitleBlockRightMargin`(64) / `startSceneTitleBlockOffsetY`(60).

### 기능 S4: StartScene BEST/PLAYS → GlassPillNode 2개
- 설명: 기존 `bestLabel`/`playsLabel` SKLabelNode 제거. 좌상단 BEST GlassPill / 우상단 PLAYS GlassPill.
- 핵심 구조:
  ```swift
  private var bestPill: GlassPillNode?
  private var playsPill: GlassPillNode?

  let bestText = "BEST 🏆 \(HighScoreRepository().current)"
  let playsText = "PLAYS \(StatisticsRepository().current.playCount)"
  let pillSize = CGSize(
      width: GameConfig.startSceneStatPillWidth,
      height: GameConfig.startSceneStatPillHeight
  )
  let best = GlassPillNode(text: bestText, size: pillSize)
  let plays = GlassPillNode(text: playsText, size: pillSize)
  bestPill = best
  playsPill = plays
  addChild(best)
  addChild(plays)
  best.position = CGPoint(x: frame.minX + GameConfig.startSceneStatPillSideMargin, y: frame.maxY - GameConfig.startSceneStatPillTopMargin)
  plays.position = CGPoint(x: frame.maxX - GameConfig.startSceneStatPillSideMargin, y: frame.maxY - GameConfig.startSceneStatPillTopMargin)
  ```
- 저장소 호출은 *현재 위치 그대로*(setup 시점, 1회).
- 기존 `startSceneBestPlaysSpacing`/`startSceneBestPlaysTopMargin` GameConfig 상수는 사용처 0이 되지만 *삭제 금지*.
- 신규 GameConfig 상수: `startSceneStatPillWidth`(96) / `Height`(28) / `SideMargin`(60) / `TopMargin`(30).

### 기능 S5: StartScene 시작 버튼 그대로 + 캐릭터 placeholder
- 설명: PrimaryButtonNode position 그대로(가운데). 캐릭터 PNG 자리는 *손대지 않음*(빈 영역).
- 권장: 현재 가운데 위치 유지(난이도 카드와 정렬 일관성). 우하단 정렬은 OPEN_QUESTION Q1.

### 기능 C1: CharacterSelectScene 배경 + AccentLine 헤더
- 설명: overlay 패널 제거 / 3-stop 그라데이션 추가 / 헤더에 AccentLineNode + Jua 큰 라벨 + Gowun Dodum 부제.
- 핵심 구조:
  ```swift
  private var gradientBackground: GradientBackgroundNode?
  private let accentLine = AccentLineNode()
  private let headerSubLabel = SKLabelNode(fontNamed: GameConfig.fontBody)

  let node = GradientBackgroundNode.threeStop(size: size, topColor: .ganhoBgWarmTop, midColor: .ganhoBgWarmMid, bottomColor: .ganhoBgWarmBottom)
  node.position = CGPoint(x: frame.midX, y: frame.midY)
  gradientBackground = node
  addChild(node)

  headerLabel.fontName = GameConfig.fontDisplay
  headerLabel.fontColor = .ganhoNavyDeep
  headerSubLabel.text = "친구마다 다른 스킬과 이동속도를 가져요"
  headerSubLabel.fontSize = GameConfig.characterSelectHeaderSubFontSize
  headerSubLabel.fontColor = .ganhoNavyMuted
  addChild(accentLine)
  addChild(headerSubLabel)
  ```
- 신규 GameConfig 상수: `characterSelectHeaderSubFontSize`(12), `characterSelectHeaderSubOffsetY`(-22), `characterSelectAccentLineOffsetY`(+24).

### 기능 C2: CharacterSelectScene Top Bar — GlassPill 뒤로 + DarkContextChip 난이도
- 설명: 좌상단 "← 난이도 다시" GlassPill / 우상단 "현재 난이도 [중]" DarkContextChip + 코랄 뱃지.
- 핵심 구조:
  ```swift
  private var backPill: GlassPillNode?
  private var difficultyChip: DarkContextChipNode?

  private func setupTopBar() {
      let back = GlassPillNode(
          text: GameConfig.characterSelectBackPillText,
          size: CGSize(
              width: GameConfig.characterSelectBackPillWidth,
              height: GameConfig.characterSelectBackPillHeight
          )
      )
      backPill = back
      addChild(back)

      let chip = DarkContextChipNode(
          label: GameConfig.characterSelectDifficultyChipLabel,
          badge: difficulty.shortName
      )
      difficultyChip = chip
      addChild(chip)
  }
  ```
- 입력: `touchesBegan`에서 `backButton.contains(location)` → `backPill?.contains(location) == true`로 교체.
- **기존 `backButton` 프로퍼티(BackButtonNode 클래스) 제거**. 입력 분기·setupButtons·layoutButtons에서 backButton 참조 *전부* backPill로 교체.
- 신규 `Difficulty.shortName` computed property (easy="하" normal="중" hard="상").
- 신규 GameConfig 상수: `characterSelectBackPillText`("← 난이도 다시"), `characterSelectBackPillWidth`(120), `characterSelectBackPillHeight`(28), `characterSelectDifficultyChipLabel`("현재 난이도"), `characterSelectTopBarMarginX`(40), `characterSelectTopBarMarginY`(30).

### 기능 C3: CharacterSelectScene 5장 카드 — 글래스 컨테이너 + 색 점
- 설명: CharacterCardNode 5장 *그대로* 사용. 카드 *외곽*에 글래스 컨테이너(반투명 흰색 라운드 박스) + 우상단 색 점 8px SKShapeNode를 *별도 자식*으로 부착.
- 핵심 구조:
  ```swift
  private var cardContainers: [CharacterID: SKShapeNode] = [:]
  private var cardColorDots: [CharacterID: SKShapeNode] = [:]

  for id in CharacterID.allCases {
      let containerSize = CGSize(
          width: GameConfig.characterCardGlassWidth,
          height: GameConfig.characterCardGlassHeight
      )
      let container = SKShapeNode(rectOf: containerSize, cornerRadius: GameConfig.characterCardGlassCornerRadius)
      container.fillColor = UIColor.white.withAlphaComponent(GameConfig.characterCardGlassFillAlpha)
      container.strokeColor = .clear
      container.zPosition = 90
      container.name = "characterCardGlass_\(id.rawValue)"
      cardContainers[id] = container
      addChild(container)

      let dot = SKShapeNode(circleOfRadius: GameConfig.characterCardColorDotRadius)
      dot.fillColor = id.dotColor
      dot.strokeColor = .clear
      dot.zPosition = 110
      cardColorDots[id] = dot
      addChild(dot)
  }
  ```
- `CharacterID.dotColor` 신규 computed property:
  - kim → `.ganhoCoralLight`
  - jung → `.ganhoScrubMint`
  - geon → `.ganhoLavenderSoft`
  - im → `.ganhoMusicGold`
  - lee → `.ganhoCoralLight` (또는 신규 토큰 `ganhoBlushPink` 추가 — 1건 허용)
- **CharacterCardNode 내부 변경 0건** — 컨테이너는 *외부에서 동기화*:
  ```swift
  private func select(_ id: CharacterID) {
      selectedCharacterID = id
      preferenceRepo.save(id)
      for card in characterCards { card.setSelected(card.id == id) }
      applyGlassContainerSelection(id: id)
      rebuildSkillInfoPanel(for: id)
  }

  private func applyGlassContainerSelection(id: CharacterID) {
      for (cid, container) in cardContainers {
          let selected = cid == id
          container.strokeColor = selected ? .ganhoCoralPrimary : .clear
          container.lineWidth = selected ? GameConfig.characterCardGlassSelectedStrokeWidth : 0
          let scaleTarget: CGFloat = selected ? GameConfig.characterCardGlassSelectedScale : 1.0
          let yOffset: CGFloat = selected ? GameConfig.characterCardGlassSelectedYOffset : 0
          container.removeAction(forKey: "glassSelect")
          container.run(SKAction.group([
              SKAction.scale(to: scaleTarget, duration: GameConfig.characterCardGlassScaleDuration),
              SKAction.moveTo(y: cardBaseY(for: cid) + yOffset, duration: GameConfig.characterCardGlassScaleDuration)
          ]), withKey: "glassSelect")
      }
  }
  ```
- 헬퍼: `cardBaseX(for:)` / `cardBaseY(for:)`를 도입해 카드/컨테이너/색 점 좌표를 한 함수에서 가져옴 (OPEN_QUESTION Q5).
- 신규 GameConfig 상수: `characterCardGlassWidth`(110), `Height`(140), `CornerRadius`(18), `FillAlpha`(0.65), `characterCardColorDotRadius`(4), `characterCardGlassSelectedScale`(1.08), `characterCardGlassSelectedYOffset`(12), `characterCardGlassSelectedStrokeWidth`(2), `characterCardGlassScaleDuration`(0.18).

### 기능 C4: CharacterSelectScene 하단 스킬 정보 패널
- 설명: 선택된 캐릭터의 스킬명 + 속도 배율을 하단 가운데 DarkContextChipNode로 표시.
- 핵심 구조:
  ```swift
  private var skillInfoChip: DarkContextChipNode?

  private func rebuildSkillInfoPanel(for id: CharacterID) {
      skillInfoChip?.removeFromParent()
      let label: String
      if id.skill == .none {
          label = "스킬 없음  •  속도 ×\(formatted(id.playerSpeedMultiplier))"
      } else {
          label = "스킬: \(id.skill.displayName)  •  속도 ×\(formatted(id.playerSpeedMultiplier))"
      }
      let chip = DarkContextChipNode(label: label, badge: nil)
      chip.position = CGPoint(x: frame.midX, y: frame.midY + GameConfig.characterSelectSkillInfoOffsetY)
      skillInfoChip = chip
      addChild(chip)
  }
  ```
- `select(_:)`와 `didMove` 끝에 호출.
- 신규 GameConfig 상수: `characterSelectSkillInfoOffsetY`(-100).

### 기능 C5: CharacterSelectScene Confirm 버튼 — 가운데 정렬
- 설명: PrimaryButtonNode("이 친구로 시작"). position은 가운데. backButton 인스턴스 제거됐으므로 layoutButtons에서 confirm만 처리.
- 핵심 구조:
  ```swift
  private func layoutButtons() {
      confirmButton.position = CGPoint(
          x: frame.midX,
          y: frame.midY + GameConfig.characterSelectConfirmButtonOffsetY
      )
  }
  ```
- 기존 `characterSelectButtonRowOffsetY`/`characterSelectButtonSpacing` 사용처 0이 되지만 *삭제 금지*.
- 신규 GameConfig 상수: `characterSelectConfirmButtonOffsetY`(-180).

### 기능 K1: SkillExplanationScene 배경 + 헤더 (C1과 동형)
- 설명: overlay 패널 제거 / 3-stop 그라데이션 추가 / 헤더에 AccentLine + Jua + Gowun Dodum 부제 "한 번만 익히면 충분해요. 바로 시작할 수 있어요".
- 패턴: 기능 C1과 동일.
- 신규 GameConfig 상수: `skillExplanationHeaderSubText`, `skillExplanationHeaderSubFontSize`(12), `skillExplanationAccentLineOffsetY`(+24), `skillExplanationHeaderSubOffsetY`(-22).

### 기능 K2: SkillExplanationScene Top Bar — GlassPill 뒤로 + DarkContextChip 브레드크럼
- 설명: 좌상단 "← 캐릭터 다시" GlassPill / 우상단 브레드크럼 DarkContextChip(난이도 · 캐릭터 · **스킬** 뱃지).
- 핵심 구조:
  ```swift
  private var backPill: GlassPillNode?
  private var breadcrumbChip: DarkContextChipNode?

  private func setupTopBar() {
      let back = GlassPillNode(text: "← 캐릭터 다시", size: CGSize(width: 130, height: 28))
      backPill = back
      addChild(back)

      let chip = DarkContextChipNode(label: "\(difficulty.shortName) · \(characterID.displayName)", badge: "스킬")
      breadcrumbChip = chip
      addChild(chip)
  }
  ```
- 입력: 기존 `backButton.contains` → `backPill?.contains == true`로 교체.
- 하단 BackButtonNode 인스턴스는 *유지* — mockup의 하단 좌측 백 버튼도 별도로 표시(기능 K6).

### 기능 K3: SkillExplanationScene 좌측 아바타 글래스 카드
- 설명: 기존 `avatarSprite`(PixelSprite 7.5배 확대)를 글래스 카드 컨테이너로 감쌈. 컨테이너 상단에 "캐릭터명" 코랄 알약 뱃지. 컨테이너 아래에 role tag(Gowun Dodum) + mint 속도배율 칩.
- 핵심 구조:
  ```swift
  private var avatarCard: SKShapeNode?
  private var avatarNameBadge: SKShapeNode?
  private var avatarNameLabel: SKLabelNode?
  private var avatarRoleLabel: SKLabelNode?
  private var avatarSpeedChip: SKShapeNode?
  private var avatarSpeedLabel: SKLabelNode?

  let cardSize = CGSize(width: GameConfig.skillExplanationAvatarCardWidth, height: GameConfig.skillExplanationAvatarCardHeight)
  let card = SKShapeNode(rectOf: cardSize, cornerRadius: GameConfig.skillExplanationAvatarCardCornerRadius)
  card.fillColor = UIColor.white.withAlphaComponent(0.85)
  card.strokeColor = UIColor.ganhoCoralPrimary.withAlphaComponent(0.3)
  card.lineWidth = 2
  card.zPosition = 80
  avatarCard = card
  addChild(card)

  // avatarSprite.zPosition = 100 (카드 위)
  // 이름 뱃지·role·속도 칩 자식 노드들 z=110
  ```
- **avatarSprite 자체는 보존** — `PixelSprite.data(...)` + `PixelPalette.palette(...)` + `PixelSpriteRenderer.texture(...)` 호출 흐름 그대로.
- 신규 GameConfig 상수: `skillExplanationAvatarCardWidth`(180), `Height`(200), `CornerRadius`(24), `AvatarCardOffsetX`(-180), `AvatarCardOffsetY`(0), `AvatarNameBadgeOffsetY`(+90), `AvatarRoleOffsetY`(-110), `AvatarSpeedChipOffsetY`(-130).

### 기능 K4: SkillExplanationScene 우측 스킬 영역
- 설명:
  1. 코랄 메타 라벨 — 동적: `\(characterID.displayName)의 스킬` (Gowun Dodum 11pt 코랄)
  2. Jua 36pt 스킬명 — 기존 `skillNameLabel` 그대로(폰트만 fontDisplay로 교체, 색 navy)
  3. 인용 박스 — StoryBoxNode를 *대체*. 신규 SKShapeNode(좌 3px 코랄 보더 + 글래스 fill 0.55 + 라운드 14pt) + SKLabelNode(Gowun Dodum 14pt navy, 자동 줄바꿈).
  4. 메타 칩 3개 가로 — CD / 범위 / 즉발. DarkContextChipNode 3개.
- 핵심 구조 (인용 박스):
  ```swift
  private var skillQuoteBox: SKShapeNode?
  private let skillQuoteLabel = SKLabelNode(fontNamed: GameConfig.fontBody)

  private func setupSkillQuoteBox() {
      let boxSize = CGSize(width: GameConfig.skillExplanationQuoteBoxWidth, height: GameConfig.skillExplanationQuoteBoxHeight)
      let box = SKShapeNode(rectOf: boxSize, cornerRadius: GameConfig.skillExplanationQuoteBoxCornerRadius)
      box.fillColor = UIColor.white.withAlphaComponent(GameConfig.skillExplanationQuoteBoxFillAlpha)
      box.strokeColor = .clear
      skillQuoteBox = box
      addChild(box)

      let leftBorder = SKShapeNode(rectOf: CGSize(width: 3, height: boxSize.height), cornerRadius: 1.5)
      leftBorder.fillColor = .ganhoCoralPrimary
      leftBorder.strokeColor = .clear
      leftBorder.position = CGPoint(x: -boxSize.width/2 + 1.5, y: 0)
      box.addChild(leftBorder)

      skillQuoteLabel.text = characterID.skill.fullDescription
      skillQuoteLabel.fontSize = 14
      skillQuoteLabel.fontColor = .ganhoNavyDeep
      skillQuoteLabel.numberOfLines = 0
      skillQuoteLabel.preferredMaxLayoutWidth = boxSize.width - 28
      skillQuoteLabel.horizontalAlignmentMode = .center
      skillQuoteLabel.verticalAlignmentMode = .center
      box.addChild(skillQuoteLabel)
  }
  ```
- 메타 칩 3개 — 캐릭터별 메타데이터:
  - CD: `\(Int(skill.cooldown))초` 또는 `.charmStudent`(once-per-game) → "1회"
  - 범위: `PlayerSkill.rangeText` 신규 computed — `.dashClimb`="3타일", `.bookClubRally`="6타일", `.charmStudent`="전역", `.taiwanTrip`="최원거리"
  - 즉발: `PlayerSkill.castText` 신규 computed — duration 0 → "즉발", 그 외 → `\(duration)초`
- DarkContextChipNode 3개 가로 정렬.
- 신규 GameConfig 상수: `skillExplanationQuoteBoxWidth`(300), `Height`(80), `CornerRadius`(14), `FillAlpha`(0.55), `MetaLabelFontSize`(11), `StatChipSpacing`(8).
- StoryBoxNode 인스턴스(`skillStoryBox` 등) 제거. 클래스 파일 자체는 *삭제하지 않음*.

### 기능 K5: SkillExplanationScene 컨트롤 힌트 (B 키 마크)
- 설명: `controlHintLabel`을 다크 navy 알약 컨테이너 + 코랄 원 "B" + 라벨로 교체.
- 핵심 구조:
  ```swift
  private var controlHintContainer: SKShapeNode?
  private let controlHintKeyCircle = SKShapeNode(circleOfRadius: 11)
  private let controlHintKeyLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)

  let containerSize = CGSize(width: GameConfig.skillExplanationControlHintContainerWidth, height: GameConfig.skillExplanationControlHintContainerHeight)
  let container = SKShapeNode(rectOf: containerSize, cornerRadius: containerSize.height / 2)
  container.fillColor = UIColor.ganhoNavyDeep.withAlphaComponent(0.92)
  container.strokeColor = .clear
  controlHintContainer = container

  controlHintKeyCircle.fillColor = .ganhoCoralPrimary
  controlHintKeyCircle.strokeColor = .clear

  controlHintKeyLabel.text = "B"
  controlHintKeyLabel.fontSize = 12
  controlHintKeyLabel.fontColor = .white

  controlHintLabel.fontName = GameConfig.fontBody
  controlHintLabel.fontSize = 12
  controlHintLabel.fontColor = .ganhoBgWarmTop  // 따뜻한 베이지
  // text는 GameConfig.skillExplanationControlHintText 그대로
  ```
- `controlHintLabel` 프로퍼티는 유지. 컨테이너 자식으로 재배치.
- 신규 GameConfig 상수: `skillExplanationControlHintContainerWidth`(280), `Height`(32), `KeyCircleRadius`(11).

### 기능 K6: SkillExplanationScene 하단 버튼 2개
- 설명: BackButtonNode "← 캐릭터 다시" + PrimaryButtonNode "시작". 기존 좌우 배치 그대로. y 오프셋만 mockup 톤으로 조정.
- 변경 0건 권장. 기존 BackButtonNode가 Sprint 1 GlassPill 톤이라 mockup 매칭.

## 폰트 적용 일괄 규칙

| 라벨 | 폰트 | 색 | 비고 |
|---|---|---|---|
| 모든 타이틀/헤더 (Jua) | `GameConfig.fontDisplay` | `.ganhoNavyDeep` 또는 `.ganhoCoralPrimary` | mockup 강조 부분만 코랄 |
| 본문/태그라인 (Gowun Dodum) | `GameConfig.fontBody` | `.ganhoNavyMuted` | 태그라인·부제·인용 박스 |
| 수치 (NotoSansKR) | `GameConfig.fontNumeric` | 컨텍스트별 | 속도배율, CD 초 |
| 버튼 텍스트 | Sprint 1 PrimaryButton/BackButton 내부 폰트 그대로 | — | 호출자는 텍스트만 |
| GlassPillNode 라벨 | Sprint 1 GlassPill 내부 fontDisplay 그대로 | — | 호출자는 텍스트만 |
| DarkContextChipNode 라벨 | Sprint 1 chip 내부 fontDisplay 그대로 | — | 호출자는 label/badge만 |

**기존 시스템 폰트(SKLabelNode 기본) 사용처 0**이 합격 기준.

## 주의사항

### 빌드 안정성
- `SKLabelNode(fontNamed:)` — 폰트 ttf 미등록 시 시스템 폰트로 graceful fallback → 크래시 없음. Sprint 1 후속 작업으로 ttf 추가 완료된 상태.
- `SKEffectNode(CIGaussianBlur)` — Sprint 1 GlassPillNode 내부에서 처리됨. 본 Sprint는 호출만.
- `numberOfLines = 0` + `preferredMaxLayoutWidth` — 자동 줄바꿈 패턴. 폭은 *컨테이너 폭 - 패딩 × 2*.

### Swift 패턴
- 강제 언래핑 `!` 0건. `GlassPillNode?`/`DarkContextChipNode?` 옵셔널 프로퍼티 사용. hit-test는 `pill?.contains(location) == true` 패턴.
- `Timer` 0건.
- 매직 넘버 0건.
- `[weak self]` — 클로저 진입 시 적용.
- `// MARK:` 섹션 구분 보존.

### SpriteKit 패턴
- `didMove(to:)` 안에서 setup 호출. `didChangeSize(_:)`에서 layout + rebuild 호출.
- `addChild` 누적 회피 — rebuild 패턴.
- zPosition 위계:
  - 그라데이션: -20
  - musicNoteEmitter: -15
  - 헤더·AccentLine·태그라인: 4~10
  - 카드/PrimaryButton: 100
  - 카드 외곽 글래스 컨테이너: 90
  - 카드 색 점 / "선택됨" 뱃지: 110

### 기존 코드와의 충돌
- **CharacterSelectScene**의 `backButton` 인스턴스(BackButtonNode) 제거 시: 프로퍼티·setupButtons·layoutButtons·touchesBegan 내 참조 *전부* `backPill`로 교체.
- **StartScene**의 `subtitleLabel`/`bestLabel`/`playsLabel`/`titleNode` 4개 인스턴스 제거 시: setupLabels/layoutLabels에서 *전부* 제거. 신규 인스턴스로 교체. 기존 GameConfig 상수 미사용 상태가 되어도 *삭제 금지*.
- **SkillExplanationScene**의 `skillStoryBox` 인스턴스(StoryBoxNode) 제거 시: setupSkillBox/layoutSkillBox 함수 *전부* 제거 + 신규 `skillQuoteBox`로 교체.

## 검증 체크리스트 (Evaluator용)

### 게임 로직 회귀 0 (40%)
- [ ] 5 캐릭터 × 3 난이도 = 15 조합 시작 가능
- [ ] `selectedDifficulty`/`selectedCharacterID`/`difficulty`/`characterID` 전달 시그니처 0 변경
- [ ] `HighScoreRepository().current` / `StatisticsRepository().current.playCount` / `preferenceRepo.current/save` / `difficultyRepo.current/save` 호출 위치·시점 그대로
- [ ] `.kim` 스킵 분기 그대로
- [ ] `presentScene(_, transition:)` 그대로
- [ ] `GameScene+Setup` / `ResultScene` / `GameScene` 파일 git diff 0줄
- [ ] `PhysicsCategory` / `ContactRouter` / `PlayerSkill` 메타데이터 / `Difficulty` enum 분기 / `EnemyNode`/`ProfessorNode`/`StoneGuardNode` 0건 수정

### Swift 패턴 (20%)
- [ ] 강제 언래핑 `!` 0건
- [ ] `Timer` 0건
- [ ] 매직 넘버 0건
- [ ] `// MARK:` 섹션 구분
- [ ] private/internal 가시성 일관

### 비주얼 일관성 (25%)
- [ ] 3 mockup HTML과 시각 매칭 (캐릭터 placeholder 제외)
- [ ] 모든 SKLabelNode `fontName`이 `GameConfig.fontDisplay/Body/Numeric` 중 하나
- [ ] 하드코딩된 hex 0건 — 모든 색은 ColorTokens
- [ ] Sprint 1 컴포넌트 재사용 (GlassPill/AccentLine/DarkContextChip/PrimaryButton/BackButton/GradientBackgroundNode.threeStop)
- [ ] StartScene 그라데이션이 warm 3-stop
- [ ] CharacterSelectScene 5장 카드 외곽 글래스 + 색 점 가시
- [ ] SkillExplanationScene 인용 박스 좌 3px 코랄 보더 가시

### 가독성 & UX (15%)
- [ ] 글래스 칩/카드의 텍스트 대비 충분
- [ ] 컨트롤 힌트의 "B" 키 마크 가시
- [ ] AccentLine이 헤더 위 ±24pt 범위 내 정확히 배치
- [ ] 씬 전환 시 깜빡임 0
- [ ] didChangeSize 시 그라데이션 rebuild 정상

## OPEN_QUESTION

### Q1. StartScene 시작 버튼 위치
- 옵션 A (권장): 현재 가운데 위치 유지. 우측 타이틀과 시각 불일치는 *생산성 우선*.
- 옵션 B: 우하단 정렬. 사용자 우손 엄지 도달 영역. Sprint 4에서 재평가.

Planner 결정: **옵션 A**.

### Q2. 캐릭터 PNG 자리 placeholder
- StartScene 좌측 하단 김간호 자리: 비워둠.
- CharacterSelectScene 카드 안: CharacterCardNode 내부 시각 그대로.
- SkillExplanationScene 큰 아바타: PixelSprite 7.5배 확대 그대로.

### Q3. 신규 computed property 도입
`Difficulty.shortName` / `PlayerSkill.rangeText` / `PlayerSkill.castText` / `CharacterID.dotColor` 4개. 모두 순수 시각 라벨용 — 게임 로직 분기 0 영향. **허용**.

### Q4. MusicNoteEmitterNode 사용처
StartScene만 유지. CharacterSelectScene/SkillExplanationScene은 emitter 없음.

### Q5. CharacterSelectScene 카드 좌표 동기화
헬퍼 `cardBaseX(for:)` / `cardBaseY(for:)` 도입. layoutCharacterCards / layoutCardContainers / layoutColorDots / layoutSelectedBadge 모두 헬퍼 호출.

---

**SPEC 작성**: Planner Agent (Sprint 2)
**문서 의존**: DESIGN_RENEWAL_REQUEST.md §3 / §4.1~§4.3 / §6 / §9 / §11, mockups/main-screen-v2.html, mockups/character-select-v2.html, mockups/skill-explanation-v2.html
**다음 단계**: Generator가 본 SPEC을 구현 → Evaluator가 위 §검증 체크리스트로 채점
