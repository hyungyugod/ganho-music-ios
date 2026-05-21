# SPEC.md — Im/Lee 간호사 모자 추가 + 다음 버튼 offsetY 상향

## 개요
캐릭터 선택창에서 5명 중 이간호(lee)·임간호(im) 2명만 nurse cap이 누락되어 시각 일관성이 깨진다. 두 캐릭터의 `buildImFace()` / `buildLeeFace()`에 `buildNurseCap()` 호출 한 줄씩 추가해 5명 모두 동일한 흰 모자 + 적십자 마크를 갖춘다. 동시에 "다음" 버튼이 화면 하단 가장자리에 너무 붙어 답답하므로 `characterSelectConfirmButtonBottomInset` 값을 키워 시각적으로 약 24pt 위로 끌어올린다.

## 변경 유형
**비주얼** (캐릭터 시각 + 레이아웃 미세 조정 — 게임플레이/로직 영향 0)

## 게임 경험 의도
3명만 모자를 쓰고 있던 부조화(김간호/정간호는 의도된 다른 헤드기어, 건간호만 모자) → 5명 모두 nurse cap을 공유하는 "간호사 게임" 정체성 강화. 동시에 "다음" 버튼이 safe area 바닥에 거의 닿아있던 갑갑함이 호흡 있는 하단 마진으로 바뀌어 캐릭터 선택의 시각적 마무리가 자연스러워진다.

## Sprint 범위 계약

### 허용
- `CharacterFaceNode.swift` 내 `buildImFace()` / `buildLeeFace()` 본문에 **각각 `buildNurseCap()` 1줄 호출 추가만** 허용
- `GameConfig.swift` 내 `characterSelectConfirmButtonBottomInset` 값 단일 변경 (40 → 64)
- 위 변경만으로 maxAllowedY 클램프가 발동되어 시각적 상승이 부족할 경우 보조 조정: `characterCardConfirmButtonBelowChipV9` 24 → 16 (조건부, 필요 시에만)

### 금지
- `NurseAvatarNode` 본체 git diff 0줄 유지 (메모리 의사결정 #10 — Sprint 8)
- `buildHeadBase()` · `buildBlush()` · `buildNurseCap()` 공통 함수 **본문 내부** 수정 (호출만 추가 허용)
- 다른 캐릭터 분기 `buildKimFace()` · `buildJungFace()` · `buildGeonFace()` 본문 변경
- 모든 side / back face 빌더 (`buildBackFace`, `buildSideFace`) 본문 변경
- `CharacterCardNode` 내부 변경
- `CharacterSelectScene.swift`의 `layoutConfirmButton()` 산식 자체 변경 (값 조정만 GameConfig에서)
- 모자 모양/색상 변형 (`buildNurseCap` 공통 함수 그대로 사용 — 별도 path / 색 / 위치 조정 금지)

### 판단 기준
"이 변경이 없으면 SPEC 기능이 제대로 동작하지 않는가?" → YES면 허용, NO면 금지.

## 변경 범위

### 수정할 파일
- `GanhoMusic Shared/Nodes/CharacterFaceNode.swift`:
  - `buildImFace()` 본문에 `buildNurseCap()` 호출 1줄 추가 (`buildBlush(...)` 직전 권장)
  - `buildLeeFace()` 본문에 `buildNurseCap()` 호출 1줄 추가 (`buildBlush(...)` 직전 권장)
- `GanhoMusic Shared/Config/GameConfig.swift`:
  - `characterSelectConfirmButtonBottomInset` 값: **40 → 64** (+24)
  - (조건부) `characterCardConfirmButtonBelowChipV9` 값: 24 → 16 (QA 시 클램프 발동 확인된 경우만)

### 추가할 파일
없음.

## 기능 상세

### 기능 1: Im 캐릭터 nurse cap 추가
- 설명: `buildImFace()`에서 nurse cap이 빠져있던 누락 결함을 해소. `buildNurseCap()` 공통 함수를 호출하여 흰 모자 본체(zPosition 20) + 적십자 v바/h바(zPosition 21)를 추가.
- 구현 위치: `CharacterFaceNode.swift` · `// MARK: - 4. Im` · `buildImFace()` 함수 마지막
- 호출 순서 근거 (중요):
  - Im의 기존 zPosition 분포: 긴머리(zPos=-1) → buildHeadBase(zPos=0) → 가르마 앞머리(zPos=10) → 고양이귀(zPos=20) → 귀 안쪽(zPos=21) → 눈/입(zPos=30)
  - **nurse cap은 cap path(zPos=20) + 적십자(zPos=21)** — 고양이귀와 동일 zPosition.
  - SpriteKit은 동일 zPosition일 때 **addChild 순서가 곧 렌더 순서**(나중에 add된 것이 위에 그려짐). 따라서 cap을 귀 호출 *뒤*에 두면 모자가 귀를 자연스럽게 덮어 머리 정수리 부근에 안정적으로 안착.
  - 단, 눈/입(zPos=30)은 cap zPos=20보다 위 → 얼굴 디테일은 모자에 가려지지 않음(정상).
  - **삽입 위치**: `buildBlush(...)` 호출 *직전*. (buildGeonFace 패턴과 일관)

핵심 코드 구조:
```swift
private func buildImFace() {
    // (기존 코드 그대로 — 긴머리, head base, 가르마, 고양이귀, 눈, 미소, 코)
    ...
    nose.zPosition = 30
    addChild(nose)

    buildNurseCap()  // Sprint 10 — 5명 시각 일관성. 귀(zPos 20) 뒤에 add → cap이 위에 렌더.

    buildBlush(radiusX: 5, radiusY: 3, cy: 10, alpha: 0.65)
}
```

### 기능 2: Lee 캐릭터 nurse cap 추가
- 설명: `buildLeeFace()`에서 nurse cap이 빠져있던 누락 결함을 해소. 동일하게 `buildNurseCap()` 공통 함수 호출.
- 구현 위치: `CharacterFaceNode.swift` · `// MARK: - 5. Lee` · `buildLeeFace()` 함수 마지막
- 호출 순서 근거:
  - Lee의 기존 zPosition 분포: side curls(zPos=-1) → curl dots(zPos=1) → buildHeadBase(zPos=0) → 앞머리 bangs(zPos=10) → fringe 점(zPos=11) → 닫힌 눈/입(zPos=30)
  - Lee에는 zPos=20 노드가 없음 → cap(zPos=20)이 fringe(zPos=11)와 bangs(zPos=10) 위에 깔끔히 안착. 닫힌 눈 미소(zPos=30)는 cap 위에 그대로 노출(정상).
  - **삽입 위치**: `buildBlush(...)` 호출 *직전*.

핵심 코드 구조:
```swift
private func buildLeeFace() {
    // (기존 코드 그대로 — side curls, curl dots, head base, bangs, fringe, 눈, 미소)
    ...
    mouthNode.zPosition = 30
    addChild(mouthNode)

    buildNurseCap()  // Sprint 10 — 5명 시각 일관성. bangs(zPos 10)·fringe(zPos 11) 위에 cap zPos 20.

    buildBlush(radiusX: 7, radiusY: 4, cy: 10, alpha: 0.75)
}
```

### 기능 3: "다음" 버튼 offsetY 상향
- 설명: `characterSelectConfirmButtonBottomInset` 값을 키워 buttonY 계산의 baseY를 끌어올림 → 버튼이 시각적으로 약 24pt 위로 이동.
- 구현 위치: `GameConfig.swift`의 `characterSelectConfirmButtonBottomInset` 상수 값 변경.
- 산술 분석:
  - **현재값들** (Planner 검증):
    - `primaryButtonHeight = 48`
    - `darkContextChipHeight = 28`
    - `adaptiveBottomMargin = 24`
    - `characterSelectConfirmButtonBottomInset = 40` ← 변경 대상
    - `characterCardHeightV3 = 200`
    - `characterCardSkillChipBelowCardV9 = 20`
    - `characterCardConfirmButtonBelowChipV9 = 24`
  - **현재 buttonY 산식** (`layoutConfirmButton()`):
    ```
    baseY        = frame.minY + safe.bottom + 24 + 40  = frame.minY + safe.bottom + 64
    chipY        = cardBottom − 20 − 14(chipHalf)      = cardBottom − 34
    chipBottom   = chipY − 14                          = cardBottom − 48
    maxAllowedY  = chipBottom − 24 − 24(btnHalf)       = cardBottom − 96
    buttonY      = min(baseY, maxAllowedY)
    ```
  - **권장값**: `characterSelectConfirmButtonBottomInset: 40 → 64` (+24)
    - 결과: `baseY = frame.minY + safe.bottom + 24 + 64 = frame.minY + safe.bottom + 88`
    - 시각적으로 약 24pt 위로 상승.
  - **클램프 검토**: 1차 변경만으로 대부분 디바이스에서 baseY가 maxAllowedY보다 작아 clamp 발동하지 않을 가능성이 높음 (산술 검증 시).
  - **조건부 보조 변경**: 만약 클램프가 발동하여 시각 상승이 부족하다면 `characterCardConfirmButtonBelowChipV9: 24 → 16` (-8) 으로 chip-button 호흡을 좁히면서 16pt 이상 유지.

핵심 코드 구조:
```swift
/// CharacterSelect 확인 버튼 — adaptiveBottomMargin 위에 추가로 띄울 버튼 자체 높이 보정.
/// Sprint 10 — 40 → 64. 버튼이 safeArea 가장자리에 너무 붙어 답답하던 시각 결함 해소.
static let characterSelectConfirmButtonBottomInset: CGFloat = 64
```

## 합격 기준 (Evaluator용)

가중 평균 ≥ 9.0 + 항목별 9.0+:

- **Swift 패턴 9.0+**: 기존 코드 스타일 유지 (한국어 주석, MARK 섹션, 매직넘버 없음 — 모든 변경은 GameConfig 상수 또는 공통 함수 호출). 강제 언래핑 0건.
- **게임 로직 9.0+**: 5명 모두 nurse cap이 머리 위에 가시. addChild 순서를 통한 동일 zPosition 렌더 우선순위가 정확. "다음" 버튼이 시각적으로 더 올라옴.
- **성능 & 안정성 9.0+**: 추가 노드 증가 미미 (캐릭터당 +3 노드 — cap path + v바 + h바). buildNurseCap 공통 함수 재사용 → 코드 중복 0. 빌드 에러 없음.
- **기능 완성도 9.0+**:
  - CharacterSelectScene 실행 시 5장 카드 모두 nurse cap 표시 (김/정/건은 기존 보존, 임/이는 신규 표시)
  - "다음" 버튼이 이전보다 약 24pt 위로 이동 (육안 시각 확인)
  - 결과창(`ScoreboardScene`의 mini face) · 인게임(`CharacterFullBodyNode`) · side/back face에 영향 없음

## 사용자 의사결정 (사전 확정)

1. **모자 모양/색상**: `buildNurseCap()` 공통 함수 그대로 사용. 별도 변형 / 위치 미세조정 / 색 변경 금지.
2. **offsetY 조정량**: 시각적으로 ~24pt 위로. `characterSelectConfirmButtonBottomInset` 40 → **64** (+24).
3. **클램프 발동 시 대비책**: `characterCardConfirmButtonBelowChipV9` 24 → 16 (-8) 까지만 허용. 16pt 미만 금지.
4. **호출 순서**: Im은 귀(zPos=20) *뒤*에 cap 호출하여 동일 zPos 내 cap이 위로 렌더. Lee는 fringe 점(zPos=11) 뒤 어디든 무방. 양쪽 모두 `buildBlush(...)` *직전*을 권장.

## 주의사항

- **SpriteKit zPosition 동률 처리**: Im의 고양이귀와 nurse cap이 모두 zPosition=20. `addChild()` 호출 순서가 곧 그리기 순서이므로 cap을 귀 *뒤*에 호출해야 cap이 위에 그려진다. 만약 순서가 뒤바뀌면 모자 일부가 귀에 가려지는 시각 결함 발생.
- **buildNurseCap 본문 보호**: 5명 공통 함수이므로 본문 변경 시 김/정/건도 영향 받음. 본문은 절대 손대지 않고 **호출만 추가**.
- **convenience init·side·back face 불변**: `init(id: CharacterID, facing: Direction)`의 `.front` 분기만이 buildImFace/buildLeeFace를 호출. side / back는 별도 빌더이므로 본 SPEC 변경의 영향 없음.
- **GameConfig 단일 사용처**: `characterSelectConfirmButtonBottomInset`는 `CharacterSelectScene.layoutConfirmButton()` 단일 사용 확인됨.
- **빌드 검증**: 변경 후 시뮬레이터(iPhone Landscape)에서 CharacterSelectScene 진입 → 5장 카드 모두 모자 표시 + 버튼 위치 상승 육안 확인.
- **mini face 부수효과 (의도된 개선)**: `CharacterFaceNode.mini(id:)` 호출(ScoreboardScene 사용)도 동일 `init(id:)` 경로이므로 mini face 5명도 모자 갖춤. 본 SPEC 의도("5명 시각 일관성")는 mini face 일관성도 함의 → **정상**.

---

## 참고 파일 경로 (절대 경로)

- `/Users/hg/Desktop/ganho-music-ios/GanhoMusic/GanhoMusic Shared/Nodes/CharacterFaceNode.swift` (수정 — buildImFace line ~521, buildLeeFace line ~642)
- `/Users/hg/Desktop/ganho-music-ios/GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift` (수정 — characterSelectConfirmButtonBottomInset)
- `/Users/hg/Desktop/ganho-music-ios/GanhoMusic/GanhoMusic Shared/Scenes/CharacterSelectScene.swift` (참조만 — 산식 검증용 layoutConfirmButton)
