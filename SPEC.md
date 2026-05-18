# Phase 10-1 — 시작 시퀀스 4단계 오버레이 분리

## 개요
현재 단일 TitleScene에 빽빽이 모여 있는 [제목 + 통계 + 캐릭터 5장 + 난이도 3장 + 시작 안내]를 GDD §3의 4단계 화면 흐름으로 분리한다. 모바일 가로 화면에서 카드 8장이 동시에 깔리는 좁은 레이아웃을 해소하고 각 단계가 *한 가지 결정*에만 집중하도록 한다. GDD §10에 명시되어 있으나 미구현인 **석조무사 경고 컷씬**(easy/normal)도 추가한다.

## 변경 유형
**혼합 (게임플레이 + 비주얼)** — UI 흐름은 플레이어가 게임에 진입하기 전 의식적으로 선택하게 만드는 게임플레이 일부이며, 동시에 카드 배치·타이포그래피·색의 시각 재배열이다.

## 게임 경험 의도
플레이어가 단계마다 한 가지 결정만 내리도록 흐름을 끊어주어 *준비된 마음*으로 게임에 진입. 김간호 선택자는 스킬 화면을 자동 스킵하여 "스킬 없음 = 정공법 정체성"이라는 GDD §4 결정을 흐름에서도 일관 표현.

## Sprint 범위 계약

### 허용
- 새 씬 3개: `StartScene` / `CharacterSelectScene` / `SkillExplanationScene`
- 새 노드 3개: `StoryBoxNode` / `PrimaryButtonNode` / `BackButtonNode`
- 새 컷씬: 석조무사 경고 — **신규 노드 신설 0건**. `CutsceneOverlayNode.present` 재사용 + GameConfig 텍스트 상수 2개만 추가
- `TitleScene` 삭제 (10-1c 완료 후)
- `GameViewController.swift` 1줄 변경
- `GameConfig.swift` 새 상수 ~25개
- `GameScene.swift` 인트로 컷씬 onDismiss 분기에 easy/normal용 석조무사 경고 호출 추가 (~10줄)
- `CharacterID.tag: String` / `PlayerSkill.fullDescription: String` computed property 신설

### 금지
- `GameScene`의 게임플레이 로직 (update/contact/skill/setup) 변경 **0줄**
- `ResultScene.swift` 변경 **0줄**
- Repositories 시그니처 변경 금지
- 새 사운드/햅틱/BGM 도입 금지
- 캐릭터 카드/난이도 카드 *내부 시각* 변경 금지 (위치만 재배치)
- 신규 컷씬 노드 클래스 신설 금지

### 판단 기준
"이 변경이 없으면 4단계 흐름이 동작하지 않는가?" → YES면 허용, NO면 금지.

## 씬 구조 결정: 옵션 A — 새 SKScene 3개

```
[StartScene] (앱 진입점)
  - 제목 "김간호는 음악박사"
  - 부제 "어느 한적한 병동의 오후"
  - BEST / PLAYS (상단)
  - 스토리 설명 박스
  - 난이도 카드 3장
  - "시작" 버튼
        ↓ SKTransition.fade
[CharacterSelectScene]
  - 헤더 "함께할 친구를 골라요"
  - 캐릭터 카드 5장 + 태그 라벨
  - "← 난이도 다시" / "이 친구로 시작"
        ↓ SKTransition.fade (김간호는 스킬 씬 스킵)
[SkillExplanationScene]
  - 헤더 "스킬을 익혀요"
  - 큰 캐릭터 아바타
  - 스킬명 + 설명 + 조작 안내
  - "← 캐릭터 다시" / "시작"
        ↓ presentScene
[GameScene]
  - showIntroCutscene → (easy/normal: showStoneGuardWarning) / (hard: showProfessorWarning) → countdown → playing
```

### 선택 사유
1. **상태 격리**: 각 씬은 init 인자로 불변 상태 보유
2. **SpriteKit 자연성**: 기존 SKTransition.fade 패턴 정착
3. **메모리 관리**: ARC 자동 해제 — 다음 화면에선 노드 사라짐
4. **상태 전달 비용 0**: 컴파일 타임 강제
5. **회귀 차단**: 각 씬 touchesBegan이 자기 카드/버튼만 안다

## 단계 분할 (4 sub-sprint, 한 PR 안)

### Phase 10-1a: StartScene 신설
- 새 `StartScene.swift` 생성. 앱 진입점 변경
- 난이도 3장만 이동 (캐릭터 5장은 다음 단계)
- TitleScene은 *삭제하지 말고* 임시 보존
- 빌드 검증: StartScene → 난이도 선택 → 시작 → GameScene 직진

### Phase 10-1b: CharacterSelectScene 신설
- 캐릭터 5장 카드 이전
- StartScene "시작" → CharacterSelectScene
- "← 난이도 다시" → StartScene
- "이 친구로 시작" → SkillExplanationScene (다음 단계, 임시: 김간호도 동일 경로)

### Phase 10-1c: SkillExplanationScene 신설 + 김간호 스킵
- 새 스킬 설명 씬
- 김간호 스킵: CharacterSelectScene의 "이 친구로 시작" 핸들러에서 .kim이면 GameScene 직진
- "← 캐릭터 다시" / "시작" 동작
- `TitleScene.swift` 완전 삭제

### Phase 10-1d: 석조무사 경고 컷씬 (easy/normal)
- `GameScene.showIntroCutscene` onDismiss 분기에 호출 추가
- 새 메서드 `showStoneGuardWarningCutscene()` (showProfessorWarningCutscene 미러)
- `GameConfig` 상수 2개 (title + body, GDD §10 원문)
- `hasSeenIntro=true` 분기에서도 경고 컷씬 표시 (매 판 환기)

## 변경 범위

### 추가할 파일
- `Scenes/StartScene.swift`
- `Scenes/CharacterSelectScene.swift`
- `Scenes/SkillExplanationScene.swift`
- `Nodes/StoryBoxNode.swift`
- `Nodes/PrimaryButtonNode.swift`
- `Nodes/BackButtonNode.swift`

### 수정할 파일
- `GanhoMusic iOS/GameViewController.swift` — 1줄 (TitleScene → StartScene)
- `GanhoMusic Shared/GameScene.swift` — 인트로 컷씬 onDismiss + 새 메서드 (~10줄)
- `GanhoMusic Shared/Config/GameConfig.swift` — 상수 ~25개
- `GanhoMusic Shared/Models/CharacterID.swift` — `tag` computed
- `GanhoMusic Shared/Models/PlayerSkill.swift` — `fullDescription` computed

### 삭제할 파일
- `GanhoMusic Shared/Scenes/TitleScene.swift` (10-1c 완료 후)

## 기능 상세

### 기능 1: StartScene
- 패턴 답습: TitleScene 구조
- 화면 구성: 상단 BEST/PLAYS, 중앙 제목+부제+스토리 박스+난이도 3장, 하단 시작 버튼
- "어디든 탭" 패턴 제거 — 시작 버튼 명시 탭만 진행
- 카드/스토리 박스/버튼 모두 setupOverlayPanel(반투명 + 카드 패널) 안

### 기능 2: CharacterSelectScene
- 헤더 + 5명 카드 가로 1줄 + 카드 아래 태그 라벨 + 뒤로/시작 버튼 2개
- CharacterCardNode *외부*에 태그 SKLabelNode 별도 생성 (카드 내부 변경 금지)
- `CharacterID.tag` computed property로 텍스트 결정

### 기능 3: SkillExplanationScene
- 헤더 + 큰 아바타(좌, 120×150) + 스킬명/설명/조작 안내(우) + 뒤로/시작
- 아바타: PixelSpriteRenderer + PixelSprite.data(for:direction:frame:) + PixelPalette.palette(for:) 재사용
- StoryBoxNode 재사용 (스킬 설명 본문)
- `PlayerSkill.fullDescription` computed property로 설명 결정

### 기능 4: 석조무사 경고 컷씬
```swift
// GameScene.swift — showIntroCutscene onDismiss 안
onDismiss: { [weak self] in
    guard let self = self else { return }
    UserDefaults.standard.set(true, forKey: GameConfig.hasSeenIntroCutsceneUserDefaultsKey)
    switch self.difficulty {
    case .easy, .normal: self.showStoneGuardWarningCutscene()
    case .hard:          self.showProfessorWarningCutscene()
    }
}

// 새 메서드
private func showStoneGuardWarningCutscene() {
    CutsceneOverlayNode.present(
        title: GameConfig.stoneGuardWarningTitle,
        body: GameConfig.stoneGuardWarningBody,
        parent: cameraNode,
        sceneSize: size,
        onDismiss: { [weak self] in
            guard let self = self else { return }
            self.gameState = .countdown
            self.showCountdown()
        }
    )
}

// didMove의 hasSeenIntro=true 분기도 수정
if hasSeenIntro {
    gameState = .cutscene
    switch difficulty {
    case .easy, .normal: showStoneGuardWarningCutscene()
    case .hard:          showProfessorWarningCutscene()
    }
} else {
    gameState = .cutscene
    showIntroCutscene()
}
```

### 기능 5: StoryBoxNode
- SKShapeNode 패널 + SKLabelNode 본문(자동 줄바꿈)
- numberOfLines = 0, preferredMaxLayoutWidth (CutsceneOverlayNode 패턴 답습)

### 기능 6: PrimaryButtonNode / BackButtonNode
- 캡슐 모양 + 라벨, contains(_:) hit-test (CharacterCardNode 패턴)
- PrimaryButton: 코럴 fill + brand stroke + ganhoPaper 텍스트
- BackButton: 투명 fill + 흰색 7% stroke + ganhoUITextMuted 텍스트

## 상태 전달

| 단계 | 입력 | 출력 | 영속 |
|---|---|---|---|
| StartScene | (없음) | difficulty, characterID(repo current) | DifficultyPreferenceRepository.save 즉시 |
| CharacterSelectScene | difficulty, characterID | difficulty, selectedCharacterID | CharacterPreferenceRepository.save 즉시 |
| SkillExplanationScene | difficulty, characterID | (수정 불가) | 없음 |
| GameScene | difficulty, characterID | (기존) | 기존 그대로 |

## 뒤로 가기 매트릭스

| 버튼 | From | To |
|---|---|---|
| Start "시작" | Start | CharacterSelect |
| CharacterSelect "← 난이도 다시" | CharacterSelect | Start |
| CharacterSelect "이 친구로 시작" (.kim) | CharacterSelect | GameScene 직진 |
| CharacterSelect "이 친구로 시작" (그 외) | CharacterSelect | SkillExplanation |
| SkillExplanation "← 캐릭터 다시" | SkillExplanation | CharacterSelect |
| SkillExplanation "시작" | SkillExplanation | GameScene |

## 회귀 방지

| 영역 | 변경 |
|---|---|
| GameScene 게임플레이 (update/contact/skill/setup) | 0줄 |
| ResultScene | 0줄 |
| CharacterCardNode / DifficultyCardNode | 0줄 |
| CutsceneOverlayNode | 0줄 |
| PlayerNode / PixelSpriteRenderer | 0줄 |
| Repositories | 0줄 |

GameScene 유일 변경: didMove 분기 + 새 메서드 (~10줄). 게임 루프/상태/시스템 미접촉.

## 매직 넘버 정책 (GameConfig 상수 ~25개)

### 10-1a (StartScene)
```swift
static let startSceneStoryText: String = "실습 중 마음에 떠오른 멜로디를 45초 안에 모아 보세요. 수간호사 눈을 피하는 게 핵심."
static let startSceneSubtitleFontSize: CGFloat = 16
static let startSceneSubtitleOffsetY: CGFloat = 80
static let startSceneBestPlaysTopMargin: CGFloat = 40
static let startSceneStoryBoxOffsetY: CGFloat = 0
static let startSceneStartButtonOffsetY: CGFloat = -180

static let storyBoxWidth: CGFloat = 440
static let storyBoxHeight: CGFloat = 80
static let storyBoxFontSize: CGFloat = 14
static let storyBoxHorizontalPadding: CGFloat = 16

static let primaryButtonWidth: CGFloat = 160
static let primaryButtonHeight: CGFloat = 48
static let primaryButtonFontSize: CGFloat = 18
static let backButtonWidth: CGFloat = 140
static let backButtonHeight: CGFloat = 40
static let backButtonFontSize: CGFloat = 14
```

### 10-1b (CharacterSelectScene)
```swift
static let characterSelectHeaderText: String = "함께할 친구를 골라요"
static let characterSelectHeaderFontSize: CGFloat = 22
static let characterSelectHeaderOffsetY: CGFloat = 140
static let characterSelectCardOffsetY: CGFloat = 30
static let characterSelectTagFontSize: CGFloat = 10
static let characterSelectTagOffsetY: CGFloat = -45
static let characterSelectButtonRowOffsetY: CGFloat = -160
static let characterSelectButtonSpacing: CGFloat = 40
```

### 10-1c (SkillExplanationScene)
```swift
static let skillExplanationHeaderText: String = "스킬을 익혀요"
static let skillExplanationHeaderFontSize: CGFloat = 22
static let skillExplanationHeaderOffsetY: CGFloat = 140
static let skillExplanationAvatarWidth: CGFloat = 120
static let skillExplanationAvatarHeight: CGFloat = 150
static let skillExplanationAvatarOffsetX: CGFloat = -180
static let skillExplanationAvatarOffsetY: CGFloat = 20
static let skillExplanationSkillNameFontSize: CGFloat = 28
static let skillExplanationSkillNameOffsetX: CGFloat = 80
static let skillExplanationSkillNameOffsetY: CGFloat = 80
static let skillExplanationStoryBoxOffsetX: CGFloat = 80
static let skillExplanationStoryBoxOffsetY: CGFloat = 0
static let skillExplanationControlHintFontSize: CGFloat = 12
static let skillExplanationControlHintText: String = "좌하단 스킬 버튼을 1번 탭하면 발동"
static let skillExplanationButtonRowOffsetY: CGFloat = -160
```

### 10-1d (석조무사 경고)
```swift
static let stoneGuardWarningTitle: String = "경고 · 석조무사 출현"
static let stoneGuardWarningBody: String = "수간호사의 충실한 부하 석조무사가 출현합니다! 마주치면 잡혀갑니다. 절대 만나지 마세요."
```

## CharacterID/PlayerSkill 신규 computed property

### CharacterID.tag
```swift
var tag: String {
    switch self {
    case .kim:  return "번머리 실습생"
    case .jung: return "곡괭이 근육"
    case .geon: return "안경과 책"
    case .im:   return "긴머리 냥"
    case .lee:  return "단발 댕댕"
    }
}
```

### PlayerSkill.fullDescription
```swift
var fullDescription: String {
    switch self {
    case .none:           return ""
    case .dashClimb:      return "바라보는 방향으로 3타일 돌진. 벽 1칸 파괴. 쿨다운 22초."
    case .bookClubRally:  return "주변 6타일 안 음표를 한 번에 끌어와 수집. 쿨다운 20초."
    case .charmStudent:   return "수간호사를 매혹. F 대신 A 투척(수집 시 점수 2배). 게임당 1회."
    case .taiwanTrip:     return "가장 먼 빈 타일로 순간이동. 착지 후 0.5초 무적. 쿨다운 22초."
    }
}
```

## 평가 가중치 (본 sprint 조정)

| 항목 | 본 sprint |
|---|---|
| Swift 패턴 일관성 | 30% |
| 게임 로직 완성도 | 25% |
| 성능 & 안정성 | 20% |
| 기능 완성도 | 25% |

기능 비중 상향 — UI 흐름 재설계가 본질.

## 주의사항

1. 모든 씬 `isTransitioning: Bool` 가드
2. `guard let view = self.view` 옵셔널 가드 (강제 언래핑 금지)
3. SKAction.run / present onDismiss 모두 `[weak self]`
4. 카드 외부 태그 라벨 — 카드 내부 변경 금지
5. PixelSpriteRenderer 픽셀 텍스처 7.5배 확대 — `.nearest` filter로 픽셀 perfect 보존
6. TitleScene 삭제는 10-1c 완료 *후*에만
7. hasSeenIntro=true 분기에 경고 컷씬 표시 — 의도된 회귀(GDD §3)
8. 컷씬 중첩 금지 — onDismiss 안에서 다음 컷씬 present (자가 소멸 후)
9. SKLabelNode 자동 줄바꿈: numberOfLines=0 + preferredMaxLayoutWidth 둘 다
10. switch default 미사용 (Difficulty/CharacterID 신규 case 컴파일 에러로 자연 검출)

## Generator 빌드 단계별 검증

### 10-1a 완료
- [ ] StartScene 표시, TitleScene 미표시
- [ ] 난이도 카드 3장 동작
- [ ] "시작" → GameScene (임시: 캐릭터=repo current)
- [ ] BEST/PLAYS 라벨 갱신

### 10-1b 완료
- [ ] StartScene "시작" → CharacterSelectScene
- [ ] 캐릭터 카드 5장 동작
- [ ] 태그 라벨 5개 표시
- [ ] "← 난이도 다시" → StartScene
- [ ] "이 친구로 시작" .kim → GameScene 직진
- [ ] 그 외 → SkillExplanationScene

### 10-1c 완료
- [ ] 큰 픽셀 아바타 정확 렌더
- [ ] 스킬명/설명/조작 안내 표시
- [ ] "← 캐릭터 다시" → CharacterSelectScene
- [ ] "시작" → GameScene
- [ ] TitleScene.swift 삭제 후 빌드 클린

### 10-1d 완료
- [ ] easy/normal: 인트로 → 석조무사 경고 → countdown
- [ ] hard: 인트로 → 이교수 경고 → countdown (기존)
- [ ] 2회차 easy: 인트로 스킵 → 석조무사 경고 → countdown
- [ ] GameScene 게임 루프 회귀 0
