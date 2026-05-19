# SPEC.md — Sprint 6: 흐름 재편 + 캐릭터 얼굴 + 메인 캐릭터

## 개요
현재 메인화면이 mockup과 정반대(난이도 카드는 있는데 김간호 캐릭터 SVG 그림이 없음)인 상태를 바로잡고, 사용자 의도대로 "스킬 다음에 난이도"가 오는 5단계 흐름(Start → Character → Skill → Difficulty → Game)을 신설한다. 캐릭터 5명의 얼굴은 mockup HTML의 SVG path를 SKShapeNode 조합으로 코드화하여 PNG 자산 없이도 카드에서 식별 가능하게 한다.

## 변경 유형
**혼합 (비주얼 + UX 흐름 재편)** — Evaluator는 비주얼 일관성(25%) + 가독성/UX(15%) 항목에 SPRINT_6_REQUEST.md §5의 추가 체크 7건을 적용한다. 단, 게임 로직 회귀 0(40%)·Swift 패턴(20%) 절대 기준은 그대로.

## 게임 경험 의도
1. **첫인상의 정체성 회복** — 메인화면을 켰을 때 가장 먼저 보이는 것은 "이 게임의 주인공"이어야 한다. 현재는 추상적인 난이도 카드만 보여 사용자가 "누구의 이야기"인지 인지하기 전에 시스템 선택을 강요당한다. 김간호 SVG를 좌측에 두면 그림이 곧 약속(promise)이 된다.
2. **결정 비용을 흐름 뒤로 미루기** — 캐릭터를 모르고 난이도부터 정하는 것은 "RPG에서 직업도 모르고 난이도부터 정하는" 부자연스러움. 캐릭터 → 스킬 학습 → "그래서 이 친구로 얼마나 도전할래?"가 인지 순서다. 난이도 화면이 마지막에 와야 캐릭터·스킬 정보를 정리해서 보여줄 수 있다.
3. **김간호 분기의 차별점 보존** — 김간호는 스킬이 없는 정공법 캐릭터이므로 스킬 화면은 스킵하되, 난이도는 똑같이 거쳐야 한다. 이 4단계 분기가 "정공법 = 빠른 시작"이라는 캐릭터 정체성을 동작으로 드러낸다.

## Sprint 범위 계약

### 허용 (SPEC 기능의 정상 동작에 필수적인 최소 연동 변경)
- **mockup 작업 3건**:
  - A-1: `mockups/character-select-v2.html` 수정 (난이도 칩 제거, 백버튼 텍스트 변경)
  - A-2: `mockups/skill-explanation-v2.html` 수정 (브레드크럼 순서 + 시작 → 다음)
  - A-3: `mockups/difficulty-select-v2.html` 신규 생성 (캐릭터·스킬 요약 + 난이도 3장)
- **Swift 코드 작업 7건**:
  - B-1: `Scenes/StartScene.swift` 재구성 (난이도 카드 제거 + NurseAvatarNode 부착)
  - B-2: `Scenes/CharacterSelectScene.swift` 수정 (init 시그니처 변경 + 난이도 칩 제거 + CharacterFaceNode 부착)
  - B-3: `Nodes/CharacterFaceNode.swift` 신규 (5캐릭터 얼굴 SVG → SKShapeNode 코드화)
  - B-4: `Nodes/NurseAvatarNode.swift` 신규 (메인화면 김간호 큰 그림 SVG → SKShapeNode 코드화)
  - B-5: `Scenes/SkillExplanationScene.swift` 수정 (init 시그니처 difficulty 제거 + 시작 → 다음 + 다음 씬 변경)
  - B-6: `Scenes/DifficultySelectScene.swift` 신규 (캐릭터 요약 + 난이도 3장 + 시작)
  - B-7: `Config/GameConfig.swift` 상수 추가 (difficultySelect*, characterFace*, nurseAvatar*)
- **라우팅 인자 변경** (SPRINT_6_REQUEST.md §1 변경표 그대로):
  - Start → CharacterSelect: `(difficulty:)` → `()`
  - CharacterSelect → SkillExplanation: `(characterID:, difficulty:)` → `(characterID:)`
  - CharacterSelect → DifficultySelect (.kim): `(characterID:)` **신규**
  - SkillExplanation → DifficultySelect: `(characterID:)` **신규**
  - DifficultySelect → GameScene: `(characterID:, difficulty:)` **신규**

### 금지 (SPEC에 없는 독립적인 새 기능/효과)
- SPRINT_6_REQUEST.md §7 후속 작업(호흡 애니메이션, 사운드 cue, PNG swap) — 명시적으로 "Sprint 6 통과 후 추가해도 됨" 이라 표기됨. 이번 SPEC에서는 미포함.
- 새 캐릭터·새 스킬·새 난이도 등 게임 콘텐츠 확장.
- 인게임(GameScene·HUD·D-Pad) 시각 변경.
- 사용자 입력 응답 방식 변경(드래그/제스처).

### 판단 기준
"이 변경이 없으면 SPEC 기능이 제대로 동작하지 않는가?" → YES면 허용, NO면 금지.
예: GameConfig 상수 추가 → 동작 필수 → 허용. NurseAvatarNode 호흡 애니메이션 → 정적 시각만으로도 §5 체크 3 통과 가능 → 금지.

## 변경 범위

### 수정할 파일
- `GanhoMusic Shared/Scenes/StartScene.swift`: 난이도 관련 모든 멤버/메서드 삭제, NurseAvatarNode 부착, transitionToNext 인자 없는 newCharacterSelectScene 호출로 변경
- `GanhoMusic Shared/Scenes/CharacterSelectScene.swift`: init 시그니처 `init(size:)`로 단순화, difficulty/difficultyChip 필드 제거, 백버튼 텍스트 변경, 5장 카드에 CharacterFaceNode 부착, transitionToNext의 .kim 분기를 DifficultySelectScene으로
- `GanhoMusic Shared/Scenes/SkillExplanationScene.swift`: init 시그니처 difficulty 제거, 브레드크럼 라벨 변경, 시작 버튼 텍스트 "다음"으로, transitionToGame → transitionToDifficulty
- `GanhoMusic Shared/Config/GameConfig.swift`: §B-7 상수 추가 (난이도 선택 씬 + 얼굴 노드 + 김간호 큰 그림 + 백버튼 텍스트 갱신)
- `mockups/character-select-v2.html`: A-1 사양 그대로
- `mockups/skill-explanation-v2.html`: A-2 사양 그대로

### 추가할 파일
- `GanhoMusic Shared/Scenes/DifficultySelectScene.swift`: 5단계 흐름의 마지막 단계. 좌측 캐릭터 요약 카드 + 우측 난이도 3장 + 하단 시작 버튼
- `GanhoMusic Shared/Nodes/CharacterFaceNode.swift`: CharacterID 별 얼굴 SVG를 SKShapeNode 조합으로 그리는 컨테이너. PNG swap 호환 구조(SKNode 서브클래스)
- `GanhoMusic Shared/Nodes/NurseAvatarNode.swift`: 메인화면 김간호 큰 그림(머리/모자/헤드폰/팔/쉿 손가락) SKShapeNode 컨테이너
- `mockups/difficulty-select-v2.html`: A-3 사양 그대로

---

## 기능 상세

### 기능 1: StartScene 재구성 (난이도 카드 제거 + 김간호 큰 그림 부착)
- **설명**: 메인화면을 mockup main-screen-v2.html과 100% 일치시킨다. 난이도 결정 시점을 후반으로 미루는 것이 핵심.
- **삭제 항목**: selectedDifficulty 필드, difficultyCards 배열, difficultyRepo 필드, setupDifficultyCards/layoutDifficultyCards/selectDifficulty 메서드, touchesBegan 카드 hit test 분기, transitionToNext 안 카드 exit slide 루프, didChangeSize 안 layoutDifficultyCards 호출, didMove 안 difficultyRepo.current 라인
- **추가 항목**: `private var nurseAvatar: NurseAvatarNode?` 필드, `setupNurseAvatar()`, `layoutNurseAvatar()`
- **변경 항목**: `CharacterSelectScene.newCharacterSelectScene(difficulty:)` → `CharacterSelectScene.newCharacterSelectScene()`, transitionToNext exit 액션에 nurseAvatar 포함

### 기능 2: CharacterSelectScene 수정 (init 단순화 + 5장 얼굴 + 난이도 칩 제거)
- **삭제**: `difficulty: Difficulty` 필드, `difficultyChip: DarkContextChipNode?` 필드, `init(size:difficulty:)` → `init(size:)`, `newCharacterSelectScene(difficulty:)` → `newCharacterSelectScene()`
- **추가**: `characterFaces: [CharacterID: CharacterFaceNode]` 필드, `setupCharacterFaces()`, `layoutCharacterFaces()`
- **변경**:
  - `GameConfig.characterSelectBackPillText` 값 `"← 난이도 다시"` → `"← 메인"`
  - .kim 분기: `GameScene.newGameScene(...)` → `DifficultySelectScene.newDifficultySelectScene(characterID: .kim)`
  - 그 외 분기: `SkillExplanationScene.newSkillExplanationScene(characterID:, difficulty:)` → `SkillExplanationScene.newSkillExplanationScene(characterID:)`

### 기능 3: CharacterFaceNode 신규
- mockup character-select-v2.html의 5개 `<svg class="avatar" viewBox="-50 -55 100 110">` 내부 path/circle/ellipse/rect를 SKShapeNode 조합으로 충실 재현
- 공통 베이스: 머리 타원 64×68 fill #FFE2C6 stroke #2D2A4A
- SVG y-down → SpriteKit y-up 변환 시 y 부호 반전 필수
- zPosition 내부 순서: 머리(0) < 헤드폰 밴드(5) < 헤어 베이스(10) < 모자(20) < 얼굴 디테일(30) < 액세서리(40)
- PNG swap 호환 — `SKNode` 서브클래스로 향후 `SKSpriteNode(texture:)` 교체 가능

### 기능 4: NurseAvatarNode 신규
- mockup main-screen-v2.html의 `<svg class="character" viewBox="-150 -160 300 360">` 전체를 코드화
- 빌드: shoulders → collar → neck → head → bangs → cap → headphones → eyebrows → eyes → blush → shh mouth → arm + finger
- 크기: `GameConfig.nurseAvatarRenderWidth: 240` 정도
- zPosition 내부 순서: 어깨(-5) < 사이드헤어 뒤(-3) < 머리/목(0) < 앞머리(5) < 모자(10) < 헤드폰 밴드(15) < 헤드폰 컵(20) < 얼굴 디테일(25) < 팔(30) < 손가락 끝(35)

### 기능 5: SkillExplanationScene 수정
- 삭제: `difficulty: Difficulty` 필드, init/factory의 difficulty 파라미터, 기존 DarkContextChipNode difficulty 라벨 패턴
- 변경:
  - 브레드크럼 라벨: `"\(characterID.displayName) · 스킬 · 난이도"`
  - 시작 버튼: `PrimaryButtonNode(text: "시작")` → `PrimaryButtonNode(text: "다음")`
  - `transitionToCharacterSelect` 안 `newCharacterSelectScene(difficulty:)` → `newCharacterSelectScene()`
  - `transitionToGame()` → `transitionToDifficulty()`: GameScene 대신 DifficultySelectScene 전이

### 기능 6: DifficultySelectScene 신규
- 5단계 흐름의 마지막 결정 씬
- 레이아웃:
  - **상단 좌측 GlassPill 백버튼**: `← 스킬 다시` (kim이면 `← 캐릭터 다시`)
  - **상단 우측 DarkContextChip 브레드크럼**: `캐릭터 · 스킬 · 난이도`
  - **중앙 헤더**: AccentLine 32×3 코랄 + Jua 26pt "난이도를 골라요" + Gowun Dodum 12pt 부제
  - **좌측 미니 카드** (width 200 글래스): 코랄 이름 뱃지 + CharacterFaceNode (scale 0.65) + 스킬명(또는 "스킬 없음") + 민트 톤 속도 칩
  - **우측 난이도 3장**: `DifficultyCardNode` 그대로 재사용
  - **하단 PrimaryButton "시작"**
- 백버튼 분기: `characterID == .kim ? "← 캐릭터 다시" + CharacterSelectScene : "← 스킬 다시" + SkillExplanationScene`
- 저장: `difficultyRepo.save(id)` (저장 포맷 회귀 0)

### 기능 7: GameConfig 상수 추가
- 신규 상수 약 30~40개 (`difficultySelect*`, `characterFace*`, `nurseAvatar*`)
- 기존 1줄 값 교체: `characterSelectBackPillText` `"← 난이도 다시"` → `"← 메인"` (이름 유지)

---

## Mockup 작업 세부 사양

### A-1. mockups/character-select-v2.html 수정
- 삭제: 우상단 `<div class="diff-pill">현재 난이도 <span class="badge">중</span></div>`
- 변경: 좌상단 `← 난이도 다시` → `← 메인`
- 변경: 우측 confirm 버튼 `이 친구로 시작 ▶` → `다음 ▶`
- top-bar `justify-content`는 백버튼 좌측 정렬 유지
- annotation: "🏷️ 난이도 칩" 제거, "↩️ Back = 메인으로" 추가

### A-2. mockups/skill-explanation-v2.html 수정
- 브레드크럼 칩: `난이도 · 캐릭터 · [스킬]` → `캐릭터 · [스킬] · 난이도`
- 우측 primary 버튼: `시작 ▶` → `다음 ▶`
- 백버튼 `← 캐릭터 다시` 유지
- annotation 🧭 브레드크럼 항목 새 순서 반영

### A-3. mockups/difficulty-select-v2.html 신규 생성
- 기존 mockup 6종과 동일한 phone-frame + 그라데이션 + 음표 + 폰트 시스템
- 좌측 캐릭터 요약 카드 + 우측 난이도 3장 + 하단 시작 버튼
- annotation 6칸: "왜 이 화면이 마지막인가" / "캐릭터 요약 카드" / "난이도 3장 카드" / "브레드크럼 [난이도] 강조" / "시작 버튼만 = 명확한 마무리" / "백 = 분기별 다른 텍스트(.kim)"
- .kim 특수 케이스 명시 1줄

---

## 수용 기준 (Accept Criteria)

| 작업 | git diff 예상 형태 | 시각 확인 |
|---|---|---|
| A-1 | diff-pill HTML 5~10줄 삭제 + back-btn 텍스트 변경 1줄 | 브라우저: 난이도 칩 없음, 좌상단 "← 메인" |
| A-2 | 브레드크럼 1줄 + 버튼 1줄 변경 | 브라우저: "캐릭터 · 스킬 · 난이도" + "다음 ▶" |
| A-3 | 신규 파일 1개 추가 (~300~400줄) | 브라우저: 좌 카드 + 우 3장 + 6칸 annotation |
| B-1 | 난이도 관련 70~100줄 삭제 + NurseAvatar setup 20줄 추가 | 시뮬레이터: 좌측 김간호 그림, 난이도 카드 없음 |
| B-2 | init 변경 + difficultyChip 30줄 삭제 + face setup 20줄 추가 | 시뮬레이터: 난이도 칩 없음, 5얼굴 식별, "← 메인" |
| B-3 신규 | 신규 파일 1개 (~250~400줄) | 5캐릭터 얼굴 시각 차별화 |
| B-4 신규 | 신규 파일 1개 (~150~250줄) | 메인 좌측 김간호 그림 4영역 분간 |
| B-5 | init 시그니처 -1 + 버튼 "다음" + 다음 씬 변경 | 시뮬레이터: 다음 버튼 → 난이도 화면 |
| B-6 신규 | 신규 파일 1개 (~350~500줄) | 시뮬레이터: 좌 요약 + 우 3장 + 시작 |
| B-7 | 신규 상수 40~60줄 + 1줄 값 변경 | 빌드 SUCCEEDED |

### 흐름 전체 검증
1. 5단계 흐름 (.jung/.geon/.im/.lee): Start → Character → Skill → Difficulty → Game
2. 4단계 흐름 (.kim): Start → Character → Difficulty → Game
3. 백버튼 회귀 정확 (각 단계에서 직전으로)
4. 저장 동작 보존 (difficultyRepo/characterRepo 호출 시점 유지)

---

## 보호 영역 (변경 금지 — git diff 0줄)

**Scenes/Core**:
- `GanhoMusic Shared/GameScene.swift`
- `GanhoMusic Shared/GameScene+Setup.swift`
- `Scenes/ResultScene.swift`

**Nodes (게임플레이)**:
- PlayerNode, EnemyNode, StoneGuardNode, NoteNode, ProjectileNode, MusicNoteEmitterNode, HUDNode, DPadNode, SkillButtonNode, HUDSkillSlotNode, ComboPopupNode, ComboBreakNode, PauseButtonNode, PixelSpriteRenderer, DiplomaOverlayNode, SparkleEffectNode

**도메인 로직**:
- `Managers/` 전체
- `Repositories/` 전체 (사용만, 수정 안 함)
- `Config/GameState.swift`
- `Config/PhysicsCategory.swift`
- 게임 수치, 물리, 입력, AI, 저장, 사운드, 햅틱

**변경 가능**:
- StartScene, CharacterSelectScene, SkillExplanationScene
- DifficultySelectScene (신규), CharacterFaceNode (신규), NurseAvatarNode (신규)
- CharacterCardNode, DifficultyCardNode — **외부 부착만**, 내부 git diff 0
- GlassPillNode, DarkContextChipNode, AccentLineNode, PrimaryButtonNode, BackButtonNode, GradientBackgroundNode — 재사용만, 내부 0
- ColorTokens.swift — 추가만
- GameConfig.swift — 추가만, 1줄(`characterSelectBackPillText`) 값 교체 허용
- mockups/*.html (수정 2 + 신규 1)

---

## 주의사항 (Generator 빌드 함정)

1. **SVG y축 부호 반전 필수**: SVG y-down → SpriteKit y-up. mockup path `(x, y)` 그대로 옮기면 얼굴이 뒤집힌다. y에 -1 곱하기.
2. **CharacterCardNode/DifficultyCardNode 내부 변경 0건**: 외부에서 *씬이* 별도 자식으로 부착. 카드 addChild 추가 금지.
3. **zPosition 충돌 주의**: CharacterSelectScene에서 글래스 컨테이너(90) < 카드(100) < CharacterFaceNode(105) < 색 점/태그(110)
4. **Repository 호출 시점 보존**: `difficultyRepo.current` 읽기는 DifficultySelectScene didMove에서 1회. 저장 포맷 회귀 0.
5. **Difficulty 인자 전달 경로 끊기**: Sprint 6 후엔 **GameScene만** difficulty 받음. CharacterSelect/SkillExplanation에서 difficulty 필드/참조/factory 인자 모두 제거.
6. **GameScene.newGameScene 시그니처 보존**: 보호 영역. `(characterID:difficulty:)` 시그니처를 DifficultySelectScene이 정확히 호출.
7. **didChangeSize 일관성**: 신규/수정 씬 모두 sceneSize 의존 자식을 didChangeSize에서 재배치/재생성.
8. **`!` 0건, `Timer` 0건, weak self 사용**: Swift 규칙. 1건도 자동 -1점.
9. **UIColor raw 최소화**: 가능한 한 ColorTokens 매핑. 불가피한 경우 한 곳에 private static let.
10. **SKShapeNode 성능**: 정적 시각이라 매 프레임 그릴 일 없음. stroke 필요한 외곽선만 stroke.

---

## OPEN_QUESTION

### OQ-1: CharacterFaceNode 카드 내부 위치
- Generator 결정 권한: `characterFaceOffsetYWithinCard` 상수로 미세 조정. 기본 +6~+10. 라벨과 겹치지 않으면 통과.

### OQ-2: NurseAvatarNode X 위치
- Generator 결정 권한: `nurseAvatarOffsetX: 180`(frame.minX + 180) 기본. 시뮬레이터 시각 확인 후 조정. 타이틀 블록과 겹치지 않으면 통과.

### OQ-3: DifficultySelectScene 좌측 카드 — 직접 SKShapeNode
- Generator 결정: `summaryContainer: SKShapeNode`로 직접. CharacterCardNode 재사용 금지(내부 변경 위반).

### OQ-4: NurseAvatarNode 사용 범위
- Generator 결정: StartScene 전용. DifficultySelectScene 미니 카드는 CharacterFaceNode 작게 스케일.

### OQ-5: `characterSelectBackPillText` 상수
- Generator 결정: 이름 유지, 값만 `"← 메인"`으로. 주석에 "Sprint 6 — 흐름 재편" 명시.

### OQ-6: SkillExplanationScene 백버튼 두 개
- 둘 다 `transitionToCharacterSelect()`. 유지. 내부 newCharacterSelectScene 인자만 `()`로.

### OQ-7: 이름 뱃지 색
- Generator 결정: `.ganhoCoralPrimary` 통일. dotColor는 카드 점 전용.

---

## 합격 기준 요약

| 카테고리 | 가중치 | 통과선 | Sprint 6 추가 체크 |
|---|---|---|---|
| 게임 로직 회귀 0 | 40% | 9.0+ (절대) | 보호 영역 17파일 git diff 0줄 |
| Swift 패턴 | 20% | 7.0+ | `!` 0건, `Timer` 0건, 매직 넘버 0건 |
| 비주얼 일관성 | 25% | 7.0+ | mockup 3종 시각 매칭, ColorTokens v2 토큰 우선 |
| 가독성 & UX | 15% | 7.0+ | 5단계 + 4단계 흐름 작동, 백버튼 정확 |

**가중 평균 7.5 이상** → Sprint 6 합격.

**P0 자동 불합격**:
- 빌드 에러 1건 이상
- 보호 영역 git diff 1줄 이상
- 흐름 단계 1개라도 끊김
- 강제 언래핑 `!` 1건 이상

---

**핵심 파일 경로**:
- 단일 진실 원천: `SPRINT_6_REQUEST.md`
- 보호 영역 시작점: `GanhoMusic/GanhoMusic Shared/GameScene.swift`
- 수정 대상: `GanhoMusic Shared/Scenes/{StartScene,CharacterSelectScene,SkillExplanationScene}.swift`
- 신규: `GanhoMusic Shared/Scenes/DifficultySelectScene.swift`, `GanhoMusic Shared/Nodes/{CharacterFaceNode,NurseAvatarNode}.swift`
- 상수: `GanhoMusic Shared/Config/GameConfig.swift`
- Mockup: `mockups/character-select-v2.html` (수정), `mockups/skill-explanation-v2.html` (수정), `mockups/difficulty-select-v2.html` (신규)
