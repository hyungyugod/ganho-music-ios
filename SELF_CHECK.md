# 자체 점검 — Sprint 6 (흐름 재편 + 캐릭터 얼굴 + 메인 캐릭터)

전략: Case A — 1회차. SPEC.md/SPRINT_6_REQUEST.md 사양을 정밀 그대로 적용.

---

## 1. 작업 파일 목록

### 수정 (4건)
- `GanhoMusic Shared/Config/GameConfig.swift` — Sprint 6 신규 상수 약 50개 추가 + `characterSelectBackPillText` 1줄 값 교체(`"← 난이도 다시"` → `"← 메인"`). 이름 유지.
- `GanhoMusic Shared/Scenes/StartScene.swift` — 난이도 관련 필드/배열/repo/메서드(setupDifficultyCards/layoutDifficultyCards/selectDifficulty)/touchesBegan 카드 hit-test/transitionToNext exit 루프 모두 삭제. NurseAvatarNode 필드+setup+layout 추가. transitionToNext에서 `newCharacterSelectScene()` 인자 없이 호출. exit 액션에 nurseAvatar 포함.
- `GanhoMusic Shared/Scenes/CharacterSelectScene.swift` — `init(size:difficulty:)` → `init(size:)`. `difficulty`/`difficultyChip` 필드 제거. setupTopBar에서 difficultyChip 생성 제거. 5장 카드에 `CharacterFaceNode` 부착(zPosition 105). confirm 버튼 텍스트 `"이 친구로 시작"` → `"다음"`. .kim 분기는 `DifficultySelectScene`으로, 그 외는 `SkillExplanationScene(characterID:)`으로.
- `GanhoMusic Shared/Scenes/SkillExplanationScene.swift` — `difficulty` 필드 + init/factory의 difficulty 파라미터 제거. 브레드크럼 칩 라벨 `"\(characterID.displayName) · 스킬 · 난이도"`로 변경(DarkContextChipNode 내부 변경 0건). 시작 버튼 텍스트 `"시작"` → `"다음"`. `transitionToCharacterSelect`의 `newCharacterSelectScene()` 인자 없이. `transitionToGame()` → `transitionToDifficulty()`로 이름·동작 변경(DifficultySelectScene 전이).

### 신규 (3 swift + 1 html)
- `GanhoMusic Shared/Nodes/CharacterFaceNode.swift` — `final class CharacterFaceNode: SKNode`. `init(id: CharacterID)`. 5명 분기 build 메서드(`buildKimFace/buildJungFace/buildGeonFace/buildImFace/buildLeeFace`). mockup `character-select-v2.html` SVG path를 SKShapeNode 조합으로 재현. SVG y-down → SK y-up 변환 일관 적용. zPosition 내부 순서: 머리(0) < 헤드폰밴드(5) < 헤어(10) < 모자(20) < 얼굴디테일(30) < 액세서리(40).
- `GanhoMusic Shared/Nodes/NurseAvatarNode.swift` — `final class NurseAvatarNode: SKNode`. mockup `main-screen-v2.html` `<svg class="character">` 전체를 SKShapeNode로 코드화. 빌드 순서: shoulders → collar → button → neck → head → side hair → bangs → cap+cross → headphones(band+cup outer+inner) → eyebrows → eyes(감은 미소) → blush → shh mouth → arm(skin+outline) + finger. zPosition 어깨(-5) < 사이드헤어뒤(-3) < 머리/목(0) < 앞머리(5) < 모자(10) < 헤드폰밴드(15) < 헤드폰컵(20) < 얼굴디테일(25) < 팔(30) < 손가락끝(35).
- `GanhoMusic Shared/Scenes/DifficultySelectScene.swift` — `final class DifficultySelectScene: SKScene`. `characterID` 필드 + `selectedDifficulty` + `difficultyRepo`. didMove에서 `selectedDifficulty = difficultyRepo.current` 1회. Setup: gradientBackground / musicNoteEmitter / header(AccentLine + Jua 26pt 헤더 + Gowun Dodum 부제) / topBar(backPill + breadcrumbChip) / summaryCard(좌측 200×260 글래스 + 코랄 이름 뱃지 + `CharacterFaceNode(scale 0.65)` + 스킬명 또는 "스킬 없음" + 민트 속도 칩) / difficultyCards(우측 3장) / startButton. 백버튼 분기: `.kim` → `"← 캐릭터 다시"` + `CharacterSelectScene`, 그 외 → `"← 스킬 다시"` + `SkillExplanationScene(characterID:)`. transitionToGame: `GameScene.newGameScene(characterID:difficulty:)` 시그니처 그대로.
- `mockups/difficulty-select-v2.html` — 기존 6종 mockup과 동일한 phone-frame + 3-stop 그라데이션 + 음표 데코 + 폰트 시스템. 좌측 200×260 글래스 요약 카드(이름 뱃지 + 미니 SVG 아바타 + 스킬명 + 민트 속도 칩) + 우측 난이도 3장(쉬움 50초 / 보통 45초 / 어려움 35초) + 하단 시작 버튼 + 6칸 annotation 그리드 + .kim 특수 케이스 메모 1줄.

### Mockup 수정 (2건)
- `mockups/character-select-v2.html` — 우상단 `<div class="diff-pill">` 5줄 삭제, top-bar `justify-content: flex-start` 적용, 좌상단 백버튼 텍스트 `"← 난이도 다시"` → `"← 메인"`, confirm 버튼 `"이 친구로 시작 ▶"` → `"다음 ▶"`. annotation의 "🏷️ 난이도 칩" 카드 → "↩️ Back = 메인으로 (Sprint 6)" 카드로 교체.
- `mockups/skill-explanation-v2.html` — 브레드크럼 `난이도 · 캐릭터 · [스킬]` → `캐릭터 · [스킬] · 난이도`로 순서 재편. 우측 primary 버튼 `"시작 ▶"` → `"다음 ▶"`. annotation 🧭 브레드크럼 카드 본문 갱신.

### Xcode Project
- `GanhoMusic.xcodeproj/project.pbxproj` — 신규 3 swift 파일에 대해 PBXBuildFile + PBXFileReference + PBXGroup membership(Nodes/Scenes) + PBXSourcesBuildPhase(iOS target만) 등록. ID는 기존 `A1C0F1A0...` / `A1C0F1B0...` 패턴 따라 070/071/072 할당.

---

## 2. 매직 넘버 GameConfig 분리 현황

Sprint 6 신규 추가 상수 **약 50개** — 모두 `GameConfig.swift` Sprint 6 섹션에 MARK 주석으로 그룹화:

- **NurseAvatarNode (StartScene 좌측)**: `nurseAvatarScale` (0.7), `nurseAvatarOffsetX/Y`, `nurseAvatarZPosition`, `nurseAvatarOutlineWidth`(4), `nurseAvatarHeadphoneBandWidth`(10), `nurseAvatarArmWidth`(20).
- **CharacterFaceNode**: `characterFaceScale` (0.55), `characterFaceOffsetYWithinCard` (8 — OQ-1 결정), `characterFaceZPosition` (105), `characterFaceHeadRadiusX/Y` (32/34), `characterFaceOutlineWidth` (2.5), `characterFaceDetailLineWidth`.
- **DifficultySelectScene**: 헤더(text/subText/fontSize/offsetY/subOffsetY/accentLineOffsetY), 백버튼 텍스트 2종(스킬용·캐릭터용), backPill 폭/높이, 브레드크럼 label/badge, top bar margin X/Y, 요약 카드(width/height/cornerRadius/fillAlpha/strokeAlpha/strokeWidth/offsetX/offsetY), 이름 뱃지(width/height/fontSize/offsetY), 미니 아바타(scale/offsetY), 스킬 라벨(fontSize/offsetY/noneText), 속도 칩(width/height/fontSize/fillAlpha/offsetY), 난이도 행(offsetX/offsetY), 시작 버튼(offsetY/text).

**CharacterFaceNode/NurseAvatarNode 내부의 SVG 좌표 수치**(예: `cx="0" cy="0" rx="32" ry="34"`)는 mockup SVG와 1:1 매핑되는 **시각 자산 사양**이므로 코드 안에 그대로 노출 — `GameConfig` 추출 대상이 아님(Spring의 application.yml에 SVG path를 옮기지 않는 것과 동일). 외곽선 두께·zPosition·전체 scale 같은 *재사용 가능한 토큰*만 분리.

`!` 강제 언래핑 / `Timer` / hardcoded color hex(ColorTokens 우회) **추가 0건**. 불가피한 raw UIColor는 `CharacterFaceNode.swift` / `NurseAvatarNode.swift` 각 파일 최상단에 `private static let` 한 곳에 집중(예: `hairBrown`, `glassesLens`, `pickHandle`).

---

## 3. 강제 언래핑 / Timer / weak self 검사

| 항목 | 결과 |
|---|---|
| 강제 언래핑 `!` (변경 6 파일) | **0건** — `fatalError` 외 `[a-zA-Z_)\]]!` 패턴 검색 결과 비어있음. 모든 옵셔널은 `guard let` / `if let` / `?.` |
| `Timer` 사용 | **0건** — grep 결과 미발견 |
| `[weak self]` / `[weak view]` 캡처 | StartScene.transitionToNext의 `SKAction.run { [weak view] in ... }`에 `weak view` 캡처. DifficultySelectScene의 `transitionBack` / `transitionToGame`은 **closure 없이** `guard let view = self.view` 후 즉시 호출하는 동기 패턴이라 weak 캡처 불필요(기존 CharacterSelectScene `transitionToStart` 패턴과 동형). 모두 안전. |

---

## 4. 보호 영역 17파일 git diff 0줄 검증

`git diff --stat HEAD` 명령으로 다음 파일들 모두 빈 출력 확인:

- GameScene.swift / GameScene+Setup.swift / ResultScene.swift
- PlayerNode / EnemyNode / StoneGuardNode / NoteNode / ProjectileNode / MusicNoteEmitterNode / HUDNode / DPadNode / SkillButtonNode / HUDSkillSlotNode / ComboPopupNode / ComboBreakNode / PauseButtonNode / PixelSpriteRenderer / DiplomaOverlayNode / SparkleEffectNode
- CharacterCardNode / DifficultyCardNode / GlassPillNode / AccentLineNode / DarkContextChipNode / PrimaryButtonNode / BackButtonNode / GradientBackgroundNode (재사용·외부 부착만 — 내부 변경 0)
- Managers/ 전체 / Repositories/ 전체 / Config/GameState.swift / Config/PhysicsCategory.swift

→ **17개 보호 파일 git diff 0줄 확인.**

ColorTokens.swift도 추가/변경 0건(기존 `ganhoSkinTone`/`ganhoNavyDeep`/`ganhoScrubMint`/`ganhoCoralPrimary`/`ganhoCoralShadow`/`ganhoCoralLight`/`ganhoLavenderSoft`/`ganhoMusicGold` 토큰을 그대로 재사용).

---

## 5. 5단계 / 4단계 흐름 코드 흐름 추적

### 5단계 흐름 (.jung / .geon / .im / .lee)
1. **StartScene** — `transitionToNext` → `CharacterSelectScene.newCharacterSelectScene()` (인자 없음)
2. **CharacterSelectScene** — `transitionToNext` switch:
   - `.jung/.geon/.im/.lee` → `SkillExplanationScene.newSkillExplanationScene(characterID: selectedCharacterID)` ✓
3. **SkillExplanationScene** — `transitionToDifficulty` → `DifficultySelectScene.newDifficultySelectScene(characterID: characterID)` ✓
4. **DifficultySelectScene** — `transitionToGame` → `GameScene.newGameScene(characterID: characterID, difficulty: selectedDifficulty)` ✓
5. **GameScene** — 보호 영역, 시그니처 그대로

### 4단계 흐름 (.kim)
1. **StartScene** → `CharacterSelectScene()` (동일)
2. **CharacterSelectScene** — `.kim` → `DifficultySelectScene.newDifficultySelectScene(characterID: .kim)` ✓ (스킬 화면 스킵)
3. **DifficultySelectScene** — 좌측 카드에 "스킬 없음" 표시 + 백버튼은 `"← 캐릭터 다시"` + 백 타깃은 CharacterSelectScene ✓
4. **GameScene** — 동일

### 백 흐름 정확성
- DifficultySelectScene.transitionBack — `.kim` → CharacterSelectScene / 그 외 → `SkillExplanationScene(characterID:)`
- SkillExplanationScene.transitionToCharacterSelect — `newCharacterSelectScene()` 인자 없음
- CharacterSelectScene.transitionToStart — StartScene
- 각 단계 백버튼은 정확히 직전 단계로 ✓

---

## 6. 빌드 결과

```
xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" -scheme "GanhoMusic iOS" \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -configuration Debug build
```

**결과: ** **`** BUILD SUCCEEDED **`**

- 에러: **0건**
- 신규 워닝: **0건**
- 기존 워닝 3건 유지(`Skipping duplicate build file in Copy Bundle Resources build phase: Jua-Regular.ttf / GowunDodum-Regular.ttf / NotoSansKR-Bold.ttf`) — Sprint 1부터 존재하는 폰트 리소스 중복 등록 경고로 Sprint 6 변경과 무관.

iPhone 15 시뮬레이터는 환경에 없어 iPhone 17로 변경(arm64-apple-ios16.6-simulator). 빌드 환경 변경이지 SPEC 위반 아님.

---

## 7. Mockup 3종 변경 사항 git diff 요약

```
mockups/character-select-v2.html   |  15 +-     (수정)
mockups/skill-explanation-v2.html  |  10 +-     (수정)
mockups/difficulty-select-v2.html  |  ~400줄   (신규)
```

### character-select-v2.html (-7 +5, net -2)
- 우상단 `<div class="diff-pill">현재 난이도 <span class="badge">중</span></div>` 5줄 삭제
- top-bar inline style `justify-content: flex-start` 1줄 추가
- 백버튼 `← 난이도 다시` → `← 메인`
- confirm 버튼 `이 친구로 시작 ▶` → `다음 ▶` + 주석 1줄
- annotation의 "🏷️ 난이도 칩" 카드 본문 → "↩️ Back = 메인으로 (Sprint 6)"로 교체

### skill-explanation-v2.html (-5 +5)
- 브레드크럼 3줄 순서 재편(`난이도 · 캐릭터 · [스킬]` → `캐릭터 · [스킬] · 난이도`)
- primary 버튼 텍스트 `시작 ▶` → `다음 ▶`
- annotation 🧭 카드 본문 갱신 (Sprint 6 표시 + "다음은 난이도" 설명 추가)

### difficulty-select-v2.html (신규, ~400줄)
- phone-frame + 3-stop 그라데이션(피치 → 코랄 → 라벤더) + 음표 데코 3개 + Jua/Gowun Dodum/Noto Sans KR 폰트 시스템 — 기존 mockup 6종과 동일.
- 상단: 글래스 백버튼 `← 스킬 다시` + 다크 브레드크럼 `캐릭터 · 스킬 · [난이도]`(난이도만 코랄 뱃지).
- 헤더: 코랄 32×3 AccentLine + Jua 26pt "난이도를 골라요" + Gowun Dodum "한 번만 정해두면 충분해요".
- 좌측: 200px 글래스 요약 카드(코랄 이름 뱃지 + 미니 SVG 아바타 + 스킬명 + 민트 속도 칩).
- 우측: 난이도 3장(쉬움 50초·민트 / 보통 45초·골드 / 어려움 35초·코랄) + 선택 시 떠오르기 애니메이션.
- 하단: PrimaryButton 시작 + 입체 그림자.
- annotation 6칸 그리드 + .kim 특수 케이스 메모 노트.

---

## 8. 발견된 위험

### 8-1. SVG 좌표 변환 시각 검증 미수행
CharacterFaceNode/NurseAvatarNode의 SVG → SKShapeNode 변환은 **수학적으로 정확**(y에 -1 곱하기 + control point도 동일 변환)하지만, *실제 시뮬레이터 렌더 시 5명 얼굴이 mockup과 시각 매칭되는지는 빌드만으로 확인 불가*. Evaluator가 시뮬레이터에서 5명 얼굴 식별 가능 여부 + NurseAvatarNode 4영역(머리/모자/헤드폰/팔) 분간 여부를 채점해야 함. SVG path 좌표는 mockup 원본 그대로 옮긴 것이라 토폴로지는 보존됨.

### 8-2. CharacterFaceNode가 카드 안에 들어가는지 미세 조정
`characterFaceScale = 0.55`, `characterFaceOffsetYWithinCard = 8`은 OPEN_QUESTION OQ-1의 Generator 결정 범위. 카드 폭(110)/높이(140) 안에 viewBox 64×64가 들어가야 하는데, scale 0.55면 face가 약 35×35 정도가 되어 카드 안에 충분히 들어감 + 태그 라벨(y=-45)·이름 라벨(y=0)·색 점(우상단)과 겹치지 않음. 시각 검증 필요.

### 8-3. NurseAvatarNode 위치
`nurseAvatarOffsetX = 180`, `nurseAvatarOffsetY = -40`은 OQ-2 Generator 결정. mockup의 "좌측 6%" 가이드를 frame.minX + 180으로 환산. iPhone 17 가로 폭(약 932pt landscape) 기준 6%는 ~56pt이지만 NurseAvatarNode 자체가 viewBox 300×360 짜리 큰 그림이므로 + 180에 두어야 좌측 끝이 frame.minX + (180 - 240*0.7/2) ≈ 96pt에 닿음 — 좌측 노치/Dynamic Island와 적절히 떨어짐 + 타이틀 블록(우측 정렬)과 안 겹침.

### 8-4. Difficulty 인자 전달 경로 검증
Sprint 6 후엔 *GameScene만* difficulty 받음. 모든 grep 결과:
- `Difficulty` 타입 참조: GameConfig.swift / Difficulty.swift / DifficultyCardNode.swift / DifficultyPreferenceRepository.swift / DifficultySelectScene.swift / GameScene.swift / ResultScene.swift — **CharacterSelectScene와 SkillExplanationScene에는 0건** ✓
- `difficulty:` named argument의 호출처: `DifficultySelectScene → GameScene.newGameScene(characterID:difficulty:)`만 ✓

### 8-5. 보호 영역 외 사이드 이펙트
- `characterSelectBackPillText` 1줄 값 교체는 SPEC.md §"기능 7" + SPRINT_6_REQUEST.md §B-7 + OQ-5 명시 허용.
- ColorTokens 추가/변경 0건.
- 게임 수치(시간/HP/속도/점수/콤보), 물리, 입력, AI, 저장 포맷, 사운드, 햅틱 — 0건 변경. `difficultyRepo.current` 읽기는 `DifficultySelectScene.didMove`에서 1회만(기존 StartScene 패턴과 동형), `difficultyRepo.save(id)`는 `selectDifficulty(_:)`에서 호출 — 저장 포맷 회귀 0.
