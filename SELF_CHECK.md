# 자체 점검 — Sprint 7 Phase B (스킬 설명 겹침 해소)

전략: Case A (1회차 — 신규 작업)

## SPEC 기능 체크

- [x] **변경 1**: `setupButtons()`에서 `addChild(backButton)` 호출 제거 — SkillExplanationScene.swift L545-548
- [x] **변경 2**: `layoutButtons()` startButton 단독 중앙 배치로 단순화 — L550-554 (`half` 변수 제거)
- [x] **변경 3**: `setupMetaLabel()` 끝에서 `addChild(metaLabel) + layoutMetaLabel()` 호출 제거 — L348-360
- [x] **변경 4**: `setupSkillQuoteBox()` 폭/보더 V3 상수 참조 — L389(Width V3), L406(BorderWidth V3)
- [x] **변경 5**: `layoutStatChips()` spacing V3 상수 참조 — L471
- [x] **변경 6**: `didChangeSize(_:)` 안 `layoutMetaLabel()` 호출 제거 — L134
- [x] **GameConfig V3 상수 5종 추가** — GameConfig.swift L1915-1932 (MARK 섹션 `Sprint 7 Phase B · Skill Explanation v3`)
  - `skillExplanationQuoteBoxWidthV3 = 332`
  - `skillExplanationContentWidthRatioV3 = 0.52`
  - `skillExplanationQuoteBoxBorderWidthV3 = 4`
  - `skillExplanationStatChipSpacingV3 = 10`
  - `skillExplanationBottomButtonGapV3 = 18`
- [x] **신규 mockup**: `mockups/skill-explanation-v3.html` 작성 완료
  - v2 베이스 카피 + 4개 차이만 반영
  - ① 좌측 카드 하단 secondary 백 버튼 제거 ✅
  - ② 우측 본문 "임간호의 스킬" 라벨 영역 삭제 ✅
  - ③ 본문 폭 `flex 1 1 52%`, 인용 보더 `4px`, 메타칩 `gap 10px` ✅
  - ④ 하단 PrimaryButton "다음 ▶" 중앙 단독 배치 (justify-content: center) ✅
  - annotation 박스 3개 (🧹 중복 제거 / 🫁 본문 호흡 +5%p / 🎯 위계 명확) ✅

## 변경 파일 목록 + 라인 수

| 파일 | 상태 | 변경 LOC |
|---|---|---|
| `GanhoMusic/GanhoMusic Shared/Scenes/SkillExplanationScene.swift` | 수정 | +20 / -15 |
| `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift` | 수정 | +21 / -0 |
| `mockups/skill-explanation-v3.html` | 신규 | +280 |
| **합계** | | **+321 / -15** |

## 보호 영역 0줄 확인

`git status --short` 결과:
```
 M GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift
 M GanhoMusic/GanhoMusic Shared/Scenes/SkillExplanationScene.swift
?? mockups/skill-explanation-v3.html
```

(QA_REPORT.md, SELF_CHECK.md, SPEC.md는 하네스 산출물 — 평가 대상 외)

- [x] Phase A 파일 0줄: `CharacterCardNode.swift`, `CharacterSelectScene.swift`, `CharacterID.swift`, `PlayerSkill.swift` — 모두 변경 없음
- [x] 게임 로직 디렉토리 0줄: `ResultScene`, `GameScene`, `GameState`, `PhysicsCategory`, `Managers/`, `Repositories/`, `Systems/` — 모두 변경 없음
- [x] 보호 노드 0줄: `PlayerSkill`, `StoryBoxNode`, `DarkContextChipNode`, `GlassPillNode`, `BackButtonNode`, `PrimaryButtonNode` — 모두 변경 없음
- [x] 변경 파일이 정확히 3개: SkillExplanationScene.swift + GameConfig.swift + skill-explanation-v3.html(신규)

## 시그니처 byte-identical 확인

- [x] `class func newSkillExplanationScene(characterID: CharacterID) -> SkillExplanationScene` — L67-76, 변경 없음
- [x] `private init(size: CGSize, characterID: CharacterID)` — L81-102, 변경 없음
- [x] `private func transitionToCharacterSelect()` — L581-587, 변경 없음
- [x] `private func transitionToDifficulty()` — L591-597, 변경 없음
- [x] `characterID`별 스킬 메타데이터 표시 로직 (cooldown / range / cast) — L443-461, 변경 없음
- [x] `touchesBegan` 안 `backButton.contains(location)` 가드 보존 — L569-572 (씬 그래프에 없으므로 hit-test false 반환, 회귀 0)
- [x] `metaLabel` 인스턴스 보존 — L44, addChild만 제거

## 기존 v2 상수 값 변경 0 확인

GameConfig.swift grep 결과:
- L1325: `skillExplanationQuoteBoxWidth: CGFloat = 300` (v2 유지)
- L1333: `skillExplanationQuoteBoxBorderWidth: CGFloat = 3` (v2 유지)
- L1342: `skillExplanationStatChipSpacing: CGFloat = 8` (v2 유지)
- L1920: `skillExplanationQuoteBoxWidthV3: CGFloat = 332` (V3 신규)
- L1926: `skillExplanationQuoteBoxBorderWidthV3: CGFloat = 4` (V3 신규)
- L1929: `skillExplanationStatChipSpacingV3: CGFloat = 10` (V3 신규)

✅ v2 상수 hex/값 0줄 변경, V3 신규 상수만 추가.

## Swift / SpriteKit 패턴 준수

- 강제 언래핑 미사용: **0건** — grep 결과 `guard !statChips.isEmpty`, `guard !isTransitioning` 2건은 Bool negation(`!`)이지 강제 언래핑이 아님
- guard let 옵셔널 처리: 준수 (`guard let touch = touches.first`, `guard let view = self.view`)
- MARK 섹션 구분: 준수 — 변경 위치 4곳에 `// MARK: - Sprint 7 Phase B` 일관 적용
  - `// MARK: - Sprint 7 Phase B · Bottom Buttons`
  - `// MARK: - Sprint 7 Phase B · Right Side Meta + Skill Name (metaLabel 미부착)`
  - `// MARK: - Sprint 7 Phase B · Quote Box (V3 폭 332pt + 좌측 코랄 보더 4px)`
  - `// MARK: - Sprint 7 Phase B · Skill Explanation v3 (겹침 해소 + 호흡)` (GameConfig)
- GameConfig 상수 사용: 준수 — 332/4/10/18 모든 수치는 V3 상수로 캡슐화, 매직 넘버 0건
- Timer 사용: **0건**
- update() 안 addChild: **0건**
- weak self 캡처: 해당 없음 (SKAction 추가 0건)
- didMove(to:) 초기화: 준수 (변경 없음)

## 빌드 결과

```
xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" -scheme "GanhoMusic iOS" \
  -destination "generic/platform=iOS Simulator" build
```

- **결과: ** SUCCEEDED
- 신규 워닝: **0건**
- 기존 폰트 duplicate 워닝 3건은 Phase B와 무관 (이전 Sprint부터 존재)
- 컴파일 에러: **0건**

## OPEN_QUESTION 처리 상태 (모두 SPEC에서 결정됨)

- [x] **OQ-1**: BackButtonNode 처리 → 옵션 A 채택 = `addChild(backButton)` 호출 제거. 인스턴스/시그니처/touchesBegan 가드 모두 보존. **반영 완료**
- [x] **OQ-2**: metaLabel 처리 → 옵션 A 채택 = `addChild(metaLabel)` 호출 제거. **반영 완료** (`layoutMetaLabel()` 호출도 함께 제거 — `didChangeSize` 및 `setupMetaLabel` 양쪽 모두)
- [x] **OQ-3**: 우상단 브레드크럼 dot separator → 추가 변경 없음 (이미 `"\(characterID.displayName) · 스킬 · 난이도"` 패턴 사용 중). **변경 0**
- [x] **OQ-4**: "우측 상단 라벨 [임간호 · 스킬 · 난이도 [스킬]]"은 metaLabel 가리킨 표현으로 해석. **metaLabel 삭제로 처리 완료**

## 범위 외 미구현 항목

없음. SPEC §변경 1~6 + GameConfig V3 상수 5종 + 신규 mockup 1개 모두 구현. 보호 영역 0줄 변경.
