# Sprint 7 Phase B — 스킬 설명 겹침 해소

## 개요
SkillExplanationScene의 시각 충돌(좌상단 GlassPill 백 버튼과 하단 BackButtonNode 라벨 중복, 우상단 브레드크럼 칩과 우측 본문 라벨 영역 겹침)을 해소하고, 본문 호흡 폭을 47%→52%로 늘려 가독성을 강화한다. 인용 박스 좌측 코랄 보더 3px→4px, 메타 칩 gap 8→10, 하단 버튼 gap 12→18 등 세밀한 시각 위계 다듬기를 함께 적용한다.

## 변경 유형
**비주얼** — 단일 카테고리. 게임 로직·전이 로직·모델·저장소 0줄 변경.

## 게임 경험 의도
사용자가 SkillExplanationScene을 0.5초 안에 훑었을 때 "내가 어떤 스킬을 갖고 있는지" 한 화면에서 명확히 보인다. 라벨이 중복되거나 본문 위에 다른 칩이 떠 있어 "어느 정보가 진짜인지"를 망설이는 0.3초의 인지 비용을 0으로 만든다. 우상단 브레드크럼이 위치 정보를 단독으로 담당하고, 좌상단 GlassPill이 백 버튼을 단독으로 담당한다.

## Sprint 7 Phase B 범위 계약

### 허용 (수정 가능)
- `Scenes/SkillExplanationScene.swift` — 4가지 변경:
  1. 하단 `BackButtonNode backButton` 인스턴스를 **씬 그래프에 추가하지 않음** (`addChild(backButton)` 호출 제거)
  2. `metaLabel` 인스턴스를 **씬 그래프에 추가하지 않음** (`addChild(metaLabel)` 호출 제거)
  3. 우상단 브레드크럼 라벨은 이미 dot separator `· ` 사용 중 — 텍스트 변경 불필요
  4. 상수 참조 4곳 갱신 (quoteBox width/borderWidth, statChipSpacing, button layout 단순화)
- `Config/GameConfig.swift` — **신규 V3 상수 5개 추가** (기존 v2 상수는 값 유지)
- `mockups/skill-explanation-v3.html` — 신규 mockup 1개 작성

### 금지 (0줄 변경)
- `SkillExplanationScene.init(characterID:)` 시그니처 (Sprint 6 단순화 유지)
- `StoryBoxNode` `fullDescription` 본문 텍스트
- `transitionToCharacterSelect()` / `transitionToDifficulty()` 전이 로직
- characterID별 스킬 메타데이터 표시 로직 (cooldown / range / cast 계산)
- `PlayerSkill.rangeText` / `castText` / `displayName` / `fullDescription` 모델 값
- `DarkContextChipNode` / `GlassPillNode` / `BackButtonNode` / `PrimaryButtonNode` / `StoryBoxNode` 내부 시각 코드 (재사용만)
- 게임 로직 일체 (점수·콤보·물리·hitbox·input·AI·저장·사운드)
- `ResultScene` / `GameScene` / `GameState` / `PhysicsCategory` / Managers / Repositories / Systems / 기타 Models — 모든 파일 **0줄**
- Phase A에서 정착된 `CharacterCardNode` / `CharacterSelectScene` / `CharacterID` / `GameConfig` v3 카드 상수 — **0줄**
- 기존 `skillExplanation*` v2 상수의 hex/값 — **0줄** (신규 V3 상수만 추가)

## 신규 mockup 시각 사양 — `mockups/skill-explanation-v3.html`

Generator가 다음 사양으로 신규 HTML을 작성한다. 기존 `skill-explanation-v2.html`을 베이스 카피 후 다음 차이만 반영.

### 페이지 컨테이너
- 폰 프레임: 19.5:9 aspect-ratio, max-width 920px (v2 동일)
- 배경 3-stop 그라데이션 (v2 동일)

### 헤더 영역 (top 14%, center)
- AccentLine `32 × 3` 코랄
- 헤더 타이틀 "스킬을 익혀요" Jua 26pt navyDeep
- 헤더 부제 "한 번만 익히면 충분해요" Gowun Dodum 12pt navyMuted

### Top bar (top 22px)
- 좌상단: **GlassPill 백 버튼 1개만** — "← 캐릭터 다시" Jua 13pt navyDeep
- 우상단: **DarkContextChip 브레드크럼** 한 줄
  - 배경 navyDeep × 0.92
  - 텍스트: `김간호 · 스킬 · 난이도` Jua 12pt 골드
  - "스킬" 단어 영역에 코랄 작은 알약 뱃지 부착 (현재 위치 강조)

### 메인 콘텐츠 영역 (top 38%, bottom 26%)
- 좌측 아바타 카드: flex 0 0 200px, 4:5 비율, 글래스 카드 (v2 동일, **하단 secondary 백 버튼은 제거**)
- 우측 본문 영역: **flex 1 1 52%** (v2의 47%에서 5%p 증가)
  - **우측 본문 상단 "임간호의 스킬" 코랄 라벨은 표시하지 않음** (브레드크럼이 동일 정보를 담당)
  - 스킬명: Jua 36pt navyDeep 한 줄
  - 인용 박스: 글래스 화이트 × 0.55 라운드 14pt, **좌측 코랄 보더 4px** (v2는 3px), 본문 Gowun Dodum 14pt navyDeep
  - 메타 칩 3개 (CD / 범위 / 발동): DarkContextChip 가로 정렬, **gap 10px** (v2는 8px)

### 컨트롤 힌트 (bottom 16%)
- DarkContextChip 컨테이너 navyDeep × 0.92 라운드 알약
- "B" 키 코랄 원 11pt radius + Jua 12pt 흰색
- 라벨 "좌하단 스킬 버튼을 1번 탭하면 발동" Gowun Dodum 12pt 웜라이트

### 하단 버튼 행 (bottom 4%)
- **단독 PrimaryButton "다음 ▶"** 화면 중앙 배치 (v2의 좌측 secondary 백 버튼 제거)
- 백 버튼 책임은 좌상단 GlassPill이 단독으로 가져감

### annotation 박스 (페이지 하단 필수)
1. **🧹 중복 제거** — "하단 secondary 백 버튼 + 우측 'XX의 스킬' 라벨 제거. 좌상단 GlassPill과 우상단 브레드크럼이 단독 책임."
2. **🫁 본문 호흡 +5%p** — "우측 본문 47%→52%. 인용 보더 3→4px, 메타칩 gap 8→10."
3. **🎯 위계 명확** — "좌상단=뒤로, 우상단=위치, 본문=정보, 하단=다음 — 영역마다 정보 종류 1개씩."

## 신규/수정 함수·메서드 시그니처 명세

### `Scenes/SkillExplanationScene.swift` 변경

**1. `setupButtons()` (line ~540)**
```swift
// 변경 전:
private func setupButtons() {
    addChild(backButton)
    addChild(startButton)
    layoutButtons()
}

// 변경 후 (Sprint 7 Phase B):
private func setupButtons() {
    // Sprint 7 Phase B — backButton은 좌상단 topBackPill이 단독 책임.
    //                    하단에서 제거(addChild 호출 안 함). 인스턴스는 보존.
    addChild(startButton)
    layoutButtons()
}
```

**2. `layoutButtons()` (line ~548-553)** — startButton 단독 중앙 정렬
```swift
private func layoutButtons() {
    let y = frame.midY + GameConfig.skillExplanationButtonRowOffsetY
    // Sprint 7 Phase B — startButton 단독 중앙 배치.
    startButton.position = CGPoint(x: frame.midX, y: y)
}
```

**3. `setupMetaLabel()` (line ~340-355)** — addChild 제거
```swift
// 변경 전 마지막 줄:
//   addChild(metaLabel)
//   layoutMetaLabel()
// 변경 후:
// Sprint 7 Phase B — metaLabel은 우상단 브레드크럼이 단독 책임.
//                    화면에서 제거(addChild 호출 안 함). 인스턴스는 보존.
// (layoutMetaLabel 호출도 제거 — 씬 그래프 외부 노드의 좌표 계산 불필요)
```

**4. `setupSkillQuoteBox()` (line ~389)** — V3 폭 + 보더
```swift
let boxSize = CGSize(
    width: GameConfig.skillExplanationQuoteBoxWidthV3,    // Phase B V3
    height: GameConfig.skillExplanationQuoteBoxHeight     // 유지
)
// borderWidth 참조도 V3로:
quoteBoxBorder.lineWidth = GameConfig.skillExplanationQuoteBoxBorderWidthV3
```

**5. `layoutStatChips()` (line ~470)** — V3 spacing
```swift
let spacing = GameConfig.skillExplanationStatChipSpacingV3  // Phase B V3
```

**6. `didChangeSize(_:)` 안에서 `layoutMetaLabel()` 호출이 있다면 제거** — 씬 그래프 외부 노드 layout 불필요.

## GameConfig 신규 상수 (Phase B 전용)

`Config/GameConfig.swift` 파일 끝(또는 Sprint 7 Phase A 섹션 직후)에 새 MARK 섹션 추가:

```swift
// MARK: - Sprint 7 Phase B · Skill Explanation v3 (겹침 해소 + 호흡)
// SPRINT_7_REQUEST.md §3.2 — 본문 폭 47%→52%, 인용 보더 3px→4px,
// 메타칩 gap 8→10, 버튼 gap 12→18. 기존 v2 상수는 값 유지(회귀 0).

/// 우측 본문(인용 박스) 가로폭(pt) — v2 300pt(≈47%) → v3 332pt(≈52%).
static let skillExplanationQuoteBoxWidthV3: CGFloat = 332

/// 콘텐츠 영역 비율 (참조용) — 우측 본문 폭 계산 근거.
static let skillExplanationContentWidthRatioV3: CGFloat = 0.52

/// 인용 박스 좌측 코랄 보더 굵기(pt) — v2 3 → v3 4.
static let skillExplanationQuoteBoxBorderWidthV3: CGFloat = 4

/// 메타 칩 3개(CD/범위/발동) 사이 간격(pt) — v2 8 → v3 10.
static let skillExplanationStatChipSpacingV3: CGFloat = 10

/// 하단 백·시작 버튼 사이 간격(pt) — v2 12 → v3 18.
/// Phase B에서 백 버튼이 화면에서 제거되므로 실제 사용 빈도는 낮으나
/// 향후 정책 변경 시 참조용으로 보존.
static let skillExplanationBottomButtonGapV3: CGFloat = 18
```

기존 v2 상수(`skillExplanationQuoteBoxWidth`, `skillExplanationQuoteBoxBorderWidth`, `skillExplanationStatChipSpacing`) **값 변경 0**. Generator는 그대로 두고 V3 신규 상수만 추가, 참조 라인을 V3로 교체.

## 합격 기준 (Sprint 7 Phase B 한정)

### 시각 합격 기준 (SPRINT_7_REQUEST.md §3.4)
- [ ] 시뮬레이터에서 "← 캐릭터 다시" 라벨이 화면에 **1개만** 보임 (우상단 GlassPill만)
- [ ] 우상단 브레드크럼 칩과 우측 본문 라벨이 시각적으로 **겹치지 않음** (metaLabel 미표시로 0px 충돌)
- [ ] 우측 인용 박스 좌측 코랄 보더가 **4px** 폭으로 또렷이 보임
- [ ] 우측 본문 영역이 v2 대비 **약 5%p 넓어 보임** (300pt → 332pt)
- [ ] 메타 칩 3개 사이 간격이 v2 대비 살짝 호흡 (8 → 10)
- [ ] 모든 텍스트 가독성 (대비비 ≥ 4.5:1) 유지

### 코드 합격 기준
- [ ] `SkillExplanationScene.init(characterID:)` 시그니처 0줄 변경
- [ ] `transitionToCharacterSelect()` / `transitionToDifficulty()` 0줄 변경
- [ ] PlayerSkill / StoryBoxNode / DarkContextChipNode / GlassPillNode / BackButtonNode / PrimaryButtonNode **0줄 변경**
- [ ] ResultScene / GameScene / Models / Managers / Repositories / Systems **0줄 변경**
- [ ] CharacterCardNode / CharacterSelectScene / CharacterID **0줄 변경** (Phase A 보호)
- [ ] 강제 언래핑(`!`) 0건, Timer 0건, update()-내-addChild 0건
- [ ] 매직 넘버 0건 — 모든 신규 수치는 V3 상수 참조
- [ ] `// MARK: - Sprint 7 Phase B` 섹션으로 변경 위치 표시

### 평가 4-카테고리 통과선 (SPRINT_7_REQUEST.md §11)
| 카테고리 | 가중치 | 통과선 |
|---|---|---|
| 게임 로직 회귀 0 | 40% | 9.0 이상 (회귀 0 절대 조건) |
| Swift 패턴 | 20% | 7.0 이상 |
| 비주얼 일관성 (mockup) | 25% | 7.0 이상 (skill-explanation-v3.html 매칭 ≥ 85%) |
| 가독성 & UX | 15% | 7.0 이상 (1개 백 버튼·0px 겹침·52% 호흡) |

가중 평균 **7.5 이상**이면 ✅ 합격.

## 변경 LOC 추정치

| 파일 | 추가 | 제거 | 순변경 |
|---|---|---|---|
| `Scenes/SkillExplanationScene.swift` | ~10 | ~5 | ~+5 |
| `Config/GameConfig.swift` | ~20 | 0 | +20 |
| `mockups/skill-explanation-v3.html` | ~280 | 0 | +280 |
| **합계** | **~310** | **~5** | **~+305** |

코드 변경 순수치 ~25 LOC, mockup 포함 ~305 LOC. SPRINT_7_REQUEST.md §1 "Phase B ~150 LOC" 안에 충분히 들어감.

## 주의사항

### Swift / SpriteKit 패턴
- **강제 언래핑 0건**: 새 코드는 V3 상수 참조와 addChild 제거뿐 — 옵셔널 다룰 일 없음
- **GameConfig 상수만 사용**: 332/4/10/18은 모두 V3 상수에 캡슐화
- **MARK 섹션**: 새 코드에 `// MARK: - Sprint 7 Phase B` 일관 적용
- **클로저 self 캡처**: Phase B는 SKAction 추가 0건 — 캡처 패턴 미사용

### 회귀 위험
- `backButton` 인스턴스는 보존(시그니처 0 변경). `touchesBegan`의 `backButton.contains(location)` 가드는 부모(씬)가 없어 hit-test가 false 반환 — 탭 무시되어 안전
- `metaLabel` 동일 패턴. layout 호출(`layoutMetaLabel()`)이 남아있어도 무해(좌표 계산만, 화면 영향 0)
- `didChangeSize(_:)`에서 `layoutButtons()`, `layoutMetaLabel()` 호출이 있다면 layoutMetaLabel만 호출 제거(또는 함수 본문 안에서 isHidden 가드 추가)

### OPEN_QUESTION

**OQ-1 (결정됨)**: BackButtonNode 처리 → **옵션 A 채택** = `addChild(backButton)` 호출 제거. 인스턴스/시그니처/touchesBegan 가드 모두 보존. 부모(씬) 없는 노드의 hit-test는 false라 회귀 0.

**OQ-2 (결정됨)**: metaLabel 처리 → **옵션 A 채택** = `addChild(metaLabel)` 호출 제거. layout 호출은 무해 — 별도 정리 불필요.

**OQ-3 (결정됨)**: 우상단 브레드크럼 dot separator → **추가 변경 없음**. 현재 라벨 `"\(characterID.displayName) · 스킬 · 난이도"`가 이미 가운뎃점 + 양옆 공백 패턴 사용 중. 한국어 관례 dot separator.

**OQ-4 (결정됨)**: SPRINT_7_REQUEST.md §3.2의 "우측 상단 라벨 [임간호 · 스킬 · 난이도 [스킬]]"은 실제 코드의 `metaLabel`("XX의 스킬")을 가리킨 표현으로 해석. metaLabel 삭제로 처리.

---

## 변경 위치 정확 라인 참조 (Generator 인계용)

| 파일 | 라인 (approximate) | 현재 코드 | 변경 |
|---|---|---|---|
| SkillExplanationScene.swift | ~543 | `addChild(backButton)` | **제거** |
| SkillExplanationScene.swift | ~548-553 | `layoutButtons()` 좌우 분리 | **startButton 단독 중앙 배치**로 단순화 |
| SkillExplanationScene.swift | ~353 | `addChild(metaLabel)` | **제거** |
| SkillExplanationScene.swift | ~354 | `layoutMetaLabel()` 호출 | **제거** (무해하지만 정리) |
| SkillExplanationScene.swift | ~389 | `width: skillExplanationQuoteBoxWidth` | `skillExplanationQuoteBoxWidthV3` |
| SkillExplanationScene.swift | ~405 | `skillExplanationQuoteBoxBorderWidth` | `skillExplanationQuoteBoxBorderWidthV3` |
| SkillExplanationScene.swift | ~470 | `skillExplanationStatChipSpacing` | `skillExplanationStatChipSpacingV3` |
| SkillExplanationScene.swift | `didChangeSize(_:)` | `layoutMetaLabel()` 호출 있다면 | **제거** |
| GameConfig.swift | 파일 끝 새 MARK | — | **V3 상수 5개 추가** |
| mockups/skill-explanation-v3.html | (신규) | — | **신규 작성** |

라인 번호는 approximate — Generator는 실제 코드에서 grep으로 확정 후 변경.

---

**Generator 인계 체크**:
- SkillExplanationScene + GameConfig 외 **절대 수정 금지**
- Phase A 결과물(`CharacterCardNode`, `CharacterSelectScene`, `CharacterID`, GameConfig Phase A 상수) **0줄**
- 기존 `skillExplanation*` v2 상수 **0줄 변경**, V3 상수만 신규 추가
- mockup v3 HTML은 v2 베이스 카피 + 4개 항목만 차이 반영 + annotation 박스 3개

---

## 관련 파일 (절대 경로)

- 수정 대상:
  - `GanhoMusic/GanhoMusic Shared/Scenes/SkillExplanationScene.swift`
  - `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`
- 신규:
  - `mockups/skill-explanation-v3.html`
- 시각 레퍼런스 (읽기):
  - `mockups/skill-explanation-v2.html`
  - `mockups/character-select-v3.html` (Phase A 톤 참고)
