# Sprint 6 작업지시서 — 흐름 재편 + 캐릭터 얼굴 + 메인 캐릭터

> **트리거**: `Sprint 6 진행해줘` (CLAUDE.md 디자인 리뉴얼 모드 자동 호출)
> **DESIGN_RENEWAL_REQUEST.md 연장**. Sprint 1-5(완료)와 동일 합격 기준 + 디자인 토큰 사용.
> **단일 진실 원천** — Planner/Generator/Evaluator 모두 이 파일을 기준으로.

---

## 0. 한 줄 요약

**현재 메인화면이 mockup과 정반대(난이도 있고 캐릭터 없음)인 상태를 바로잡고, 사용자 요구대로 "스킬 다음에 난이도" 단계를 신설한다. 캐릭터 5명 얼굴은 mockup SVG path를 SKShapeNode로 코드화하여 PNG 자산 없이도 제대로 보이게 한다.**

---

## 1. 흐름 변경 (Before → After)

### Before (현재 코드)

```
StartScene (난이도 카드 3장 + 시작)
  ↓
CharacterSelectScene (캐릭터 5장, 난이도 칩 표시)
  ↓ .kim → GameScene
  ↓ 그 외
SkillExplanationScene (스킬 설명)
  ↓
GameScene
```

### After (Sprint 6 목표)

```
StartScene (캐릭터 SVG + 타이틀 + 시작) ← 난이도 카드 제거, 김간호 그림 추가
  ↓
CharacterSelectScene (5장 + 얼굴 SVG, 난이도 칩 제거)
  ↓ .kim → DifficultySelectScene  ← 스킬만 스킵
  ↓ 그 외
SkillExplanationScene (스킬 설명, 다음 버튼)
  ↓
DifficultySelectScene (신규) ← 캐릭터 요약 + 스킬 요약 + 난이도 3장 + 시작
  ↓
GameScene
```

### 라우팅 인자 변경표

| 전이 | Before | After |
|---|---|---|
| Start → CharacterSelect | `(difficulty:)` | `()` |
| CharacterSelect → SkillExplanation | `(characterID:, difficulty:)` | `(characterID:)` |
| CharacterSelect → GameScene (.kim) | `(characterID:, difficulty:)` | **사라짐** (대신 DifficultySelect) |
| CharacterSelect → DifficultySelect (.kim) | — | `(characterID:)` **신규** |
| SkillExplanation → GameScene | `(characterID:, difficulty:)` | **사라짐** (대신 DifficultySelect) |
| SkillExplanation → DifficultySelect | — | `(characterID:)` **신규** |
| DifficultySelect → GameScene | — | `(characterID:, difficulty:)` **신규** |

---

## 2. 작업 A — Mockup 손보기

`mockups/` 폴더 안의 HTML을 직접 편집하거나 신규 생성. **브라우저로 시각 확인 가능해야 한다** (CSS 깨짐 0건).

### A-1. `mockups/character-select-v2.html` 수정

| 위치 | Before | After |
|---|---|---|
| 우상단 | `<div class="diff-pill">현재 난이도 <span class="badge">중</span></div>` | **삭제** (난이도가 이 시점에 결정되지 않음) |
| 좌상단 | `← 난이도 다시` | `← 메인` |
| 5장 카드 SVG | 그대로 유지 | 그대로 유지 |
| 하단 스킬 패널 | 그대로 유지 | 그대로 유지 |
| confirm 버튼 | `이 친구로 시작` | `다음` (또는 유지 — 사용자 의도상 "스킬 보러 가기" 뉘앙스가 더 정확) |

`top-bar` 좌측 정렬 형태로 변경. annotation 섹션의 "🏷️ 난이도 칩" 항목도 제거하고 대신 "↩️ Back = 메인으로" 한 줄 추가.

### A-2. `mockups/skill-explanation-v2.html` 수정

| 위치 | Before | After |
|---|---|---|
| 브레드크럼 | `난이도 · 캐릭터 · [스킬]` | `캐릭터 · [스킬] · 난이도` |
| 좌상단 백버튼 | `← 캐릭터 다시` | `← 캐릭터 다시` (유지) |
| 우측 primary 버튼 | `시작 ▶` | `다음 ▶` |

annotation 섹션의 "🧭 브레드크럼" 항목도 새 순서 반영하여 텍스트 수정.

### A-3. `mockups/difficulty-select-v2.html` 신규 생성

기존 mockup 6종과 동일한 phone-frame · 그라데이션 BG · 음표 데코 · 폰트 시스템 적용. 구조:

```
┌──────────────────────────────────────────────┐
│ [← 스킬 다시]            [캐릭터·스킬·[난이도]] │  ← top-bar
│                                              │
│              ─── (accent-line)              │
│           난이도를 골라요                     │  ← header
│        한 번만 정해두면 충분해요              │
│                                              │
│  ┌─────────┐    ┌────┐ ┌────┐ ┌────┐        │
│  │ 미니     │    │쉬움│ │보통│ │어렵│        │  ← content
│  │ 아바타   │    │ 50s│ │ 45s│ │ 35s│        │
│  │ 건간호   │    └────┘ └────┘ └────┘        │
│  │ 북클럽   │                                │
│  │ ×1.0    │                                │
│  └─────────┘                                │
│                                              │
│              [   시작 ▶   ]                 │  ← bottom
└──────────────────────────────────────────────┘
```

상세 사양:
- **Top bar**: 좌측 글래스 백버튼(`← 스킬 다시` — .kim일 땐 `← 캐릭터 다시`), 우측 브레드크럼 다크칩 `캐릭터 · 스킬 · [난이도]` (난이도만 코랄 뱃지)
- **Header**: AccentLine 32×3 코랄 + Jua 26pt `난이도를 골라요` + Gowun Dodum 12pt 부제
- **Content (좌측 미니 카드)**: width 200px 글래스 카드 — 상단에 캐릭터 이름 코랄 뱃지, 중앙 60×60 아바타(SVG path 재활용 — character-select와 동일), 그 아래 스킬명 13pt Jua + 속도 ×배율 칩 (`9BE0CC` 민트 톤)
- **Content (우측 난이도 3장)**: 기존 main-screen mockup의 난이도 카드 패턴(코드의 `DifficultyCardNode`가 이미 존재) — width 88px × 3장 가로 + spacing 12. 각 카드는 코랄/골드/네이비 색 점 + 이름(쉬움/보통/어려움) + 제한시간(50s/45s/35s) + 장벽 N개
- **Bottom**: PrimaryButton `시작 ▶` 정가운데, 코랄 + 0/6px 입체 그림자 (메인 mockup과 동일 패턴)
- **음표 데코 3개**: 기존 mockup 패턴 그대로 (n1/n2/n3 위치만 살짝 다르게)
- **하단 annotation 그리드**: 6칸 — 각각 "왜 이 화면이 마지막인가", "캐릭터 요약 카드", "난이도 3장 카드", "브레드크럼 [난이도] 강조", "시작 버튼만 = 명확한 마무리", "백 = 분기별 다른 텍스트(.kim)"

**.kim 특수 케이스 메모**: 화면 하단 annotation에 한 줄 "김간호 선택 시 좌측 카드의 스킬 자리에 `스킬 없음` 표시 + 백버튼 텍스트 `← 캐릭터 다시`"라고 명시.

### A-4. `main-screen-v2.html`은 변경 없음

이미 mockup은 캐릭터 좌측 + 난이도 없음 + 시작 버튼만으로 정확. 코드를 mockup에 맞추는 게 본질.

---

## 3. 작업 B — Swift 코드 변경

### B-1. `StartScene.swift` 재구성

**삭제할 것**:
- `selectedDifficulty: Difficulty` 필드와 관련 모든 로직
- `difficultyCards: [DifficultyCardNode]` 배열
- `difficultyRepo: DifficultyPreferenceRepository` 필드
- `setupDifficultyCards()`, `layoutDifficultyCards()`, `selectDifficulty(_:)` 메서드
- `touchesBegan` 안의 카드 hit test 분기
- `transitionToNext()` 안의 슬라이드 exit 액션 중 `difficultyCards` 루프

**추가할 것**:
- 좌측 `NurseAvatarNode` (신규, B-3 참고) 부착 — 위치는 mockup 좌측 6% + bottom -10px
- `transitionToNext()`에서 `CharacterSelectScene.newCharacterSelectScene()` — difficulty 인자 제거

**유지할 것**:
- gradient bg, 음표 emitter, BEST/PLAYS GlassPill, 타이틀 블록(AccentLine + Jua 2-라인 + 태그라인), 시작 버튼 pulse + slideUp exit
- `characterRepo` 참조 (다음 씬이 자기 repo로 다시 읽음)

### B-2. `CharacterSelectScene.swift` 수정

**삭제할 것**:
- `init(difficulty:)` → `init(size:)`만
- `difficulty: Difficulty` 필드
- `difficultyChip: DarkContextChipNode?` 필드와 관련 setup/layout
- `newCharacterSelectScene(difficulty:)` → `newCharacterSelectScene()`

**변경할 것**:
- `backPill` 텍스트: `← 메인` (GameConfig 상수로 추가)
- `transitionToNext()`의 .kim 분기: `GameScene.newGameScene(...)` 대신 `DifficultySelectScene.newDifficultySelectScene(characterID: .kim)`
- `transitionToNext()`의 그 외 분기: `SkillExplanationScene.newSkillExplanationScene(characterID:)` — difficulty 인자 제거

**추가할 것**:
- 각 카드 위치(cardBaseX/cardBaseY)에 `CharacterFaceNode` (신규, B-3 참고) 5개 부착. zPosition 105 (카드 100과 색점 110 사이).

### B-3. (신규) `Nodes/CharacterFaceNode.swift` 추가

5명 각자의 얼굴 SVG path를 SKShapeNode 조합으로 코드화. `mockups/character-select-v2.html` 의 5개 `<svg class="avatar">` 안의 path를 그대로 변환.

```swift
final class CharacterFaceNode: SKNode {
    init(id: CharacterID) {
        super.init()
        switch id {
        case .kim:  buildKimFace()    // 번머리+모자+헤드폰
        case .jung: buildJungFace()   // 스파이크+헤어밴드+곡괭이 미니
        case .geon: buildGeonFace()   // 안경+책 미니
        case .im:   buildImFace()     // 고양이귀+긴머리+수염
        case .lee:  buildLeeFace()    // 강아지귀+단발+혀
        }
    }
    // 각 build 함수는 SKShapeNode를 fillColor/strokeColor/path 조합으로 layer 별 부착
}
```

**구현 디테일**:
- 머리/얼굴 베이스: `SKShapeNode(ellipseOf: CGSize(width: 64, height: 68))`, fill `#FFE2C6`, stroke `#2D2A4A`
- 머리카락: `CGMutablePath`로 mockup의 `<path d="...">` 좌표를 그대로 옮김 (SVG 좌표계 y축 반전 주의 — SVG는 y down, SKScene은 y up이므로 부호 반전)
- 디테일(눈/입/볼/안경 등): SKShapeNode 작은 원/path 조합
- 전체 크기: mockup의 viewBox `-50 -55 100 110` 기준 64×64 → `xScale/yScale`로 카드 안에 들어가도록 0.5 정도로
- `zPositionInside`: 머리(0) < 헤드폰 밴드(5) < 헤어 베이스(10) < 모자(20) < 얼굴 디테일(30) < 액세서리(40)
- **PNG swap 호환성**: `CharacterFaceNode`가 `SKNode` 서브클래스로, 향후 `SKSpriteNode(imageNamed:)`로 교체 가능한 구조 유지. CharacterCardNode 내부 변경 0건 정책 — 외부에서 부착.

### B-4. (신규) `Nodes/NurseAvatarNode.swift` 추가

`mockups/main-screen-v2.html`의 `<svg class="character">` 전체를 코드화. 김간호 큰 그림(수술복 + 목 + 얼굴 + 모자 + 헤드폰 + 팔 + 손가락 쉿 제스처).

```swift
final class NurseAvatarNode: SKNode {
    init() {
        super.init()
        buildShoulders()       // mint scrub top
        buildCollar()          // V neck + cute button
        buildNeck()
        buildHead()            // base ellipse
        buildSideHair()        // 좌우 sidehair
        buildBangs()
        buildNurseCap()        // white cap + red cross
        buildHeadphones()      // band + cups
        buildEyebrows()
        buildEyes()            // closed happy smile
        buildBlush()
        buildShhMouth()        // small O
        buildArmAndFinger()    // shh gesture
    }
}
```

크기: mockup viewBox `-150 -160 300 360` 기준 width 240px. 화면 좌측 6% 위치에 부착.

선택 사항(여유 있으면): 살짝 호흡 애니메이션 — `SKAction.scale(to: 1.02 ↔ 0.98)` 3초 주기.

### B-5. `SkillExplanationScene.swift` 수정

**변경할 것**:
- `init(characterID:difficulty:)` → `init(characterID:)`
- `newSkillExplanationScene(characterID:difficulty:)` → `newSkillExplanationScene(characterID:)`
- 시작 버튼 텍스트: `시작` → `다음`
- `transitionToNext()` 안의 `GameScene.newGameScene(...)` → `DifficultySelectScene.newDifficultySelectScene(characterID:)`

**추가할 것**:
- 브레드크럼 칩 — DarkContextChipNode 활용 (우상단). 텍스트 `캐릭터 · 스킬 · 난이도` + `스킬` 코랄 강조(이건 단일 텍스트 라벨로 처리)

**유지할 것**:
- 좌측 아바타 카드, 우측 스킬 정보(이름·인용박스·CD/범위/즉발 칩), 컨트롤 힌트, 백버튼

### B-6. (신규) `Scenes/DifficultySelectScene.swift` 생성

```swift
final class DifficultySelectScene: SKScene {
    private let characterID: CharacterID
    private var selectedDifficulty: Difficulty = .easy
    private let difficultyRepo = DifficultyPreferenceRepository()
    
    private var characterRepo = CharacterPreferenceRepository()
    private var gradientBackground: GradientBackgroundNode?
    private var musicNoteEmitter: MusicNoteEmitterNode?
    
    private let headerLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    private let headerSubLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    private let accentLine = AccentLineNode()
    
    private var backPill: GlassPillNode?
    private var breadcrumbChip: DarkContextChipNode?
    
    // 좌측 캐릭터 요약 카드
    private var summaryContainer: SKShapeNode?
    private var summaryNameBadge: SKShapeNode?     // 코랄 이름 뱃지
    private var summaryNameLabel: SKLabelNode?
    private var summaryFace: CharacterFaceNode?
    private var summarySkillLabel: SKLabelNode?
    private var summarySpeedChip: SKShapeNode?
    private var summarySpeedLabel: SKLabelNode?
    
    // 우측 난이도 3장 (StartScene에서 옮겨온 컴포넌트)
    private var difficultyCards: [DifficultyCardNode] = []
    
    private let startButton = PrimaryButtonNode(text: "시작")
    private var isTransitioning = false
    
    class func newDifficultySelectScene(characterID: CharacterID) -> DifficultySelectScene {
        let scene = DifficultySelectScene(size: CGSize(width: 1024, height: 768), characterID: characterID)
        scene.scaleMode = .resizeFill
        return scene
    }
    
    private init(size: CGSize, characterID: CharacterID) {
        self.characterID = characterID
        super.init(size: size)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func didMove(to view: SKView) {
        backgroundColor = .ganhoBgWarmTop
        setupGradientBackground()
        setupMusicNoteEmitter()
        setupHeader()
        setupTopBar()       // backPill + breadcrumbChip
        selectedDifficulty = difficultyRepo.current
        setupSummaryCard()  // 좌측 캐릭터+스킬 요약
        setupDifficultyCards()  // 우측 3장
        setupStartButton()
    }
    // ... 이하 layout/select/transition 메서드
    
    private func transitionToStart() { /* SkillExplanation 또는 CharacterSelect로 (분기) */ }
    private func transitionToGame() {
        let game = GameScene.newGameScene(characterID: characterID, difficulty: selectedDifficulty)
        view?.presentScene(game, transition: SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration))
    }
}
```

**분기 백버튼**: `characterID == .kim`이면 `← 캐릭터 다시` + `CharacterSelectScene`으로, 그 외엔 `← 스킬 다시` + `SkillExplanationScene(characterID: characterID)`로.

### B-7. `Config/GameConfig.swift` 상수 추가

추가할 상수 (이름 컨벤션은 기존 패턴 따름 — `sceneNameDescription`):

```swift
// MARK: - DifficultySelectScene
static let difficultySelectHeaderText = "난이도를 골라요"
static let difficultySelectHeaderSubText = "한 번만 정해두면 충분해요"
static let difficultySelectHeaderFontSize: CGFloat = 26
// ... AccentLine offset, summary card 크기/위치, 난이도 카드 가로 위치 등

// MARK: - CharacterFaceNode
static let characterFaceScale: CGFloat = 0.5
static let characterFaceZPosition: CGFloat = 105

// MARK: - NurseAvatarNode (StartScene)
static let nurseAvatarScale: CGFloat = 1.0
static let nurseAvatarOffsetX: CGFloat = -300   // 좌측 6%
static let nurseAvatarOffsetY: CGFloat = -120   // bottom -10

// MARK: - CharacterSelectScene · 백버튼 텍스트 변경
// 기존 characterSelectBackPillText "← 난이도 다시" → "← 메인"
```

`DifficultyCardNode`는 기존 컴포넌트 그대로 재사용. 가로 폭 88·간격 12 그대로.

---

## 4. 보호 영역 (변경 금지)

다음 파일/영역은 git diff 0줄을 유지해야 한다 — Evaluator 회귀 0 채점 대상:

- `GanhoMusic Shared/GameScene.swift`
- `GanhoMusic Shared/GameScene+Setup.swift`
- `GanhoMusic Shared/Nodes/PlayerNode.swift`, `EnemyNode.swift`, `StoneGuardNode.swift`, `NoteNode.swift`, `ProjectileNode.swift`, `MusicNoteEmitterNode.swift`, `HUDNode.swift`, `DPadNode.swift`, `SkillButtonNode.swift`, `HUDSkillSlotNode.swift`, `ComboPopupNode.swift`, `ComboBreakNode.swift`, `PauseButtonNode.swift`, `PixelSpriteRenderer.swift`, `DiplomaOverlayNode.swift`, `SparkleEffectNode.swift`
- `GanhoMusic Shared/Scenes/ResultScene.swift`
- `Managers/`, `Repositories/`, `Config/GameState.swift`, `Config/PhysicsCategory.swift`
- 게임 수치(시간/HP/속도/점수/콤보), 물리, 입력 응답, AI, 저장 포맷, 사운드 시퀀스, 햅틱

다음은 변경 가능 (Sprint 6 작업 대상):
- `Scenes/StartScene.swift`, `CharacterSelectScene.swift`, `SkillExplanationScene.swift`
- `Scenes/DifficultySelectScene.swift` (신규)
- `Nodes/CharacterFaceNode.swift` (신규), `NurseAvatarNode.swift` (신규)
- `Nodes/CharacterCardNode.swift`, `DifficultyCardNode.swift` (외부 부착만 — 내부 git diff 0건 유지)
- `Config/ColorTokens.swift`, `Config/GameConfig.swift` (상수 추가만)
- `mockups/*.html` (수정 2종, 신규 1종)

---

## 5. 합격 기준 (Evaluator 채점)

DESIGN_RENEWAL_REQUEST.md §11 4개 카테고리 가중 평균 **7.5 이상**:

| 카테고리 | 가중치 | 통과선 | Sprint 6 추가 체크 |
|---|---|---|---|
| 게임 로직 회귀 0 | 40% | 9.0+ (절대) | GameScene/GameScene+Setup git diff 0줄 |
| Swift 패턴 | 20% | 7.0+ | `swift-rules.md`, `spritekit-rules.md` 준수 |
| 비주얼 일관성 | 25% | 7.0+ | mockup 3종(수정 2 + 신규 1) 매칭, ColorTokens v2 토큰 사용 |
| 가독성 & UX | 15% | 7.0+ | 5단계 흐름 명확, .kim 4단계 분기 동작 |

**Sprint 6 전용 추가 체크**:
1. 새 흐름 5단계 시뮬레이터 실기 통과 (Start → Character → Skill → Difficulty → Game)
2. .kim 4단계 시뮬레이터 실기 통과 (Start → Character → Difficulty → Game, 스킬 스킵)
3. 메인화면 좌측에 NurseAvatarNode 가시 (얼굴/모자/헤드폰/팔 4개 영역 분간 가능)
4. CharacterSelectScene 5장 모두 얼굴 식별 가능 (번머리/스파이크/안경/고양이/강아지)
5. DifficultySelectScene 좌측 캐릭터 요약 카드에 미니 아바타·이름·스킬·속도 4개 정보 표시
6. 빌드 SUCCEEDED (Xcode warning 신규 추가 0건 권장, 오류 0건 필수)
7. 보호 영역 17개 파일 git diff 0줄 (Evaluator가 `git diff` 직접 실행 후 확인)

---

## 6. 하네스 진행 순서

CLAUDE.md "디자인 리뉴얼 모드" 절차 그대로:

### 단계 0: 산출물 초기화
```bash
rm -f SPEC.md SELF_CHECK.md QA_REPORT.md
```

### 단계 1: Planner 호출

```
.claude/agents/evaluation_criteria.md를 읽어라.
docs/swift-rules.md, docs/spritekit-rules.md, docs/components.md를 읽어라.
SPRINT_6_REQUEST.md를 읽어라 (이 파일이 단일 진실 원천).
mockups/character-select-v2.html, mockups/skill-explanation-v2.html를 브라우저에서 시각 확인하라.
mockups/main-screen-v2.html의 김간호 SVG path를 NurseAvatarNode 코드화 기준으로 삼아라.
GanhoMusic Shared/Scenes/{StartScene, CharacterSelectScene, SkillExplanationScene}.swift를 읽어 현재 구조 파악하라.

현재 Sprint: 6 (흐름 재편 + 캐릭터 얼굴 + 메인 캐릭터)
변경 유형: 혼합(비주얼 + UX 흐름)
범위: SPRINT_6_REQUEST.md §2~3 그대로.
변경 금지: §4 보호 영역 17개 파일.
합격 기준: §5.

SPEC.md에 반드시 포함:
1. 변경 유형 분류
2. 게임 경험 의도 (왜 이 흐름이 더 자연스러운가)
3. Sprint 범위 계약 (mockup 3종 작업 + 코드 7건 작업)
4. 각 작업의 수용 기준
5. 보호 영역 명시
```

### 단계 2: Generator 호출

최초:
```
SPEC.md를 읽고 SPRINT_6_REQUEST.md §3 코드 작업 B-1 ~ B-7을 모두 구현하라.
mockup 작업 A-1, A-2, A-3도 직접 편집/생성하라.
완료 후 SELF_CHECK.md 작성.
```

재실행:
```
SPEC.md와 QA_REPORT.md를 읽어라.
QA 피드백의 "구체적 개선 지시"를 모두 반영하라.
완료 후 SELF_CHECK.md 업데이트.
```

### 단계 3: Evaluator 호출

```
SPEC.md, SELF_CHECK.md, SPRINT_6_REQUEST.md §5 합격 기준을 읽어라.
docs/swift-rules.md, docs/spritekit-rules.md, evaluation_criteria.md 읽어라.
수정된 Swift 파일들과 mockups 3종을 읽고 채점하라.
mockup 시각 매칭은 브라우저로 확인 필수.
보호 영역 17개 파일은 `git diff` 실행 후 0줄 확인.
QA_REPORT.md로 저장.
```

### 단계 4: 판정
- 가중 평균 7.5+ → Sprint 6 합격, DESIGN_RENEWAL_STATE.md에 행 추가
- 미달 → Generator 재호출 (최대 3회)

### 단계 5: 상태 갱신

`DESIGN_RENEWAL_STATE.md` 진행 현황 표에 Sprint 6 행 추가:

```
| **6** | 흐름 재편 + 캐릭터 얼굴 + 메인 캐릭터 | ✅ 합격 | X.XX/10 | N/3 |
```

진행 로그 섹션에 한 줄 요약.

---

## 7. 사용자 후속 작업 (선택)

Sprint 6은 PNG 자산 없이도 완결되지만, 향후 시각 품질 ↑ 옵션:

1. **Sprint 4와 합치기**: 향후 캐릭터 PNG 16프레임 도착 시, `CharacterFaceNode`를 `SKSpriteNode(texture:)`로 swap. 동일 좌표·크기·zPosition 유지하면 시각만 교체됨 — DifficultySelectScene 좌측 미니 카드도 동일하게.
2. **NurseAvatarNode 호흡 애니메이션**: 메인화면 캐릭터에 `SKAction.scale(to: 1.02 ↔ 0.98)` 3초 주기 추가 — 살아있는 느낌. Sprint 6 통과 후 추가해도 됨.
3. **사운드**: 캐릭터 선택 → 스킬 → 난이도 각 전이에 짧은 chime. 기존 `AudioManager`에 cue 1~2개 추가.

---

## 8. 한 줄 요약 (재기재)

> **"메인화면을 mockup대로 (캐릭터 있고 난이도 없게) 바로잡고, 스킬 다음에 캐릭터·스킬 요약을 동반한 난이도 선택창을 신설한다. 캐릭터 5명의 얼굴은 mockup SVG를 SKShapeNode로 코드화해서 PNG 자산을 기다리지 않고 바로 보이게 한다."**

---

**작성 일자**: 2026-05-19
**작성자**: 현규 + Claude (Cowork mode)
**다음 단계**: 사용자가 `Sprint 6 진행해줘` 입력 → CLAUDE.md 디자인 리뉴얼 모드 자동 호출 → 위 §6 절차대로 하네스 실행.
