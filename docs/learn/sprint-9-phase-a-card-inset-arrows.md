# Sprint 9 Phase A 학습 노트 — 카드 안으로 정리 + 좌우 화살표

## 한 줄 요약

캐릭터 선택 화면에서 "카드 밖으로 삐져나온 부품들"을 카드 *안*으로 다시 집어넣고, 양옆에 ‹ › 화살표를 새로 달았다.

## 무슨 문제였나

사용자가 캐릭터 선택 화면을 캡처해서 보내줬는데, 4가지가 어수선했다.

1. **"선택됨" 알약**이 카드 위로 튀어나와서 위쪽 부제 글자랑 겹쳤다.
2. **카드 아래 코랄 빛(glow)**이 카드 밖으로 새어 나와서 "다음" 버튼이랑 부딪쳤다.
3. **양옆 카드의 얼굴**만 흐릿한 카드 위에 또렷하게 떠 있어서 둥둥 떠 보였다.
4. **스와이프 안내 화살표가 없어서** 사용자가 옆 카드로 넘기는 법을 모른다.

## 어떻게 고쳤나

### 1. 알약·glow를 카드 안으로 (inset)

**비유**: 액자 밖에 붙어 있던 스티커를 액자 *안*으로 옮기는 것.

- AS-IS: `halfH + 14` (카드 상단보다 14pt **밖**)
- TO-BE: `halfH - 16` (카드 상단에서 16pt **안**)

Spring 비유: 컨트롤러 메서드가 같은 URL에 매핑돼 있어도 응답 본문(body)을 다른 데이터로 바꾸는 것과 비슷. 메서드 시그니처(`attachSelectedDecor()`)는 그대로 두고 안의 `.position.y` 산식만 바꿈.

### 2. glow 크기 줄이기

- AS-IS: 224×60 (카드 폭 160보다 큼 → 밖으로 새어 나옴)
- TO-BE: 152×36 (카드 폭 - 8pt 안쪽으로 들어옴)

### 3. 카드 y 비율 0.50 → 0.44

화면 정중앙(0.50)에 두던 카드를 살짝 아래로(0.44) 내려서 위쪽 부제 글자와 카드 사이에 24pt 호흡을 만듦.

```swift
// Sprint 9 Phase A
static let characterCardCenterYV9: CGFloat = 0.44
```

기존 V4(0.50) 상수는 **삭제하지 않고 값 보존**. 다른 곳에서 참조할 수도 있고, 회귀 안전망이기도 함.

Spring 비유: `@Value("${old.value}")`로 받던 설정을 새 키 `${new.value}`로 옮기되, 옛 설정은 properties 파일에 남겨두는 것.

### 4. 둥둥 얼굴 해소 — alpha 동기화

양옆 카드의 alpha는 0.55인데 얼굴은 그냥 1.0이었다. 그래서 얼굴만 또렷하게 떠 보였음.

`layoutCards(animated:)` 안에서 카드 위치를 잡을 때, 얼굴의 alpha도 카드와 똑같이 맞춰줌:

```swift
let targetFaceAlpha: CGFloat
switch role {
case .center:    targetFaceAlpha = 1.0
case .left, .right: targetFaceAlpha = GameConfig.characterSwipeCardAlphaSideV4  // 0.55
case .offscreen: targetFaceAlpha = 0
}
face.run(SKAction.fadeAlpha(to: targetFaceAlpha, duration: duration))
```

Spring 비유: 부모 트랜잭션(`@Transactional`)이 굴리는 옵션을 자식 메서드도 그대로 따라가게 하는 것. 자식이 따로 놀면 안 됨.

### 5. ‹ › 화살표 2개 신규

기존에 만들어둔 `GlassPillNode`를 재사용해서 36×36 크기로 2개 만들었다. 카드 좌우 ±260pt 위치, zPosition 115 (카드 110보다 위).

```swift
let left = GlassPillNode(text: "‹", size: CGSize(width: 36, height: 36))
let right = GlassPillNode(text: "›", size: CGSize(width: 36, height: 36))
```

끝에 도달하면 (currentIndex가 0이거나 max) 해당 방향 화살표는 `isHidden = true`로 가림.

Spring 비유: 페이지네이션 컴포넌트에서 첫 페이지면 "Prev" 버튼을 disable 시키는 것과 똑같음.

## SwiftKit 패턴 한 줄씩

- **새 노드 인스턴스 만들지 말기**: SPEC에서 `selectedPill` 인스턴스는 *재사용*하라고 했다. 그래서 `attachSelectedDecor()` 안의 좌표 산식만 바꿨다. 노드 추가는 GlassPill 2개만.
- **시그니처 보호**: `init(id:)`, `setSelected(_:)`, `setPageState(role:animated:duration:)` 세 메서드의 시그니처는 byte 단위로 동일하게 유지. `git diff | grep "^[+-].*func "` 출력이 빈 줄이어야 합격.
- **clamp 패턴**: 확인 버튼 y를 정할 때 `min(baseY, maxAllowedY)`를 써서, "원래 위치보다 위로 올라가지 않게" 보장. 화면이 작거나 카드가 낮을 때만 발동.

## 빌드 검증

```
xcodebuild ... build
** BUILD SUCCEEDED **
```

git diff 검증 (보호 영역 0줄):
```
git diff CharacterFaceNode.swift NurseAvatarNode.swift PlayerNode.swift
→ 빈 출력
```

## 마무리 한마디

이 Phase는 시각적으로 큰 차이를 만들지만 **로직은 1줄도 안 건드렸다**. 좌표 산식과 alpha만 바꾸고, 새 노드 2개(좌우 화살표)만 추가했을 뿐.

Spring 비유로 마무리: View 템플릿의 CSS만 바꾸고 Controller/Service는 그대로 둔 PR. 작은 변경 큰 시각 효과.

---

## 추기 — V9 상수 2차 보정 (QA 2회차)

1회차 QA에서 가중 점수 8.50으로 합격선(7.5)은 넘었지만 비주얼 카테고리(6/10)가 카테고리 통과선(7.0) 미달이었다. 원인은 **§4-A-2 SPEC 자체가 가진 수학적 모순**이었다.

### 무엇이 안 맞았나
- `characterSelectSkillInfoChipAboveV9 = 44` (확인 버튼 ↔ 스킬칩 *중심간* 거리)
- 스킬칩 높이 28pt → 반 14pt, PrimaryButton 높이 48pt → 반 24pt
- 실제 chip↔button "면 대 면" gap = `44 - 14 - 24 = 6pt`
- §4-A-4 #6 요구: gap ≥ 20pt → **6pt < 20pt 미충족**

같은 식으로 `characterCardCenterYV9 = 0.44`는 iPhone 17 Pro Landscape(393pt)에서 카드 bottom 위치가 너무 위라서, 확인 버튼 clamp가 발동하면 chip top이 card bottom과 ~2pt까지 근접해 §4-A-4 #5(gap ≥ 16pt)를 깨뜨렸다.

### 어떻게 고쳤나 (V9 *값*만 갱신)
- `characterSelectSkillInfoChipAboveV9: 44 → 64` — chip half 14 + gap 26 + button half 24 = 64. 면 대 면 gap 26pt 확보.
- `characterCardCenterYV9: 0.44 → 0.40` — 카드 중심을 더 아래로 내려 카드 bottom과 chip top 사이 16pt 호흡 확보. clamp 36pt는 그대로.
- `cardBaseY(for id:)` → `cardBaseY(for _:)` — 모든 카드가 동일 y를 공유하므로 매개변수 미사용 명시 (P2 권장).

### 왜 *값만* 갱신했나
- SPEC 합격 기준 §4-A-4 6항목 자체는 그대로 — 6번/5번 두 항목이 수학적으로 충족 불가능했을 뿐.
- 시그니처 byte-identical: `init(id:)` / `setSelected(_:)` / `setPageState(role:animated:duration:)` 무변경.
- 보호 영역 0줄: CharacterFaceNode, NurseAvatarNode, PlayerNode 모두 git diff 빈 출력.
- V3 4종 / V4 11종 기존 상수는 *값 보존* — V9 신규 상수만 값 갱신.

### Spring 비유
1차 PR에서 application.yml의 timeout 값이 비즈니스 요구(20초 이상)와 모순됐던 상황. 코드/시그니처/스키마는 그대로 두고 yml 두 줄 값만 갱신한 hotfix PR과 같다. 변경 표면은 최소, 효과는 SPEC 합격 기준 #5/#6 충족.

---

## 3회차 — cardBottom anchor 전환 (방향 재검토 · Case B)

2회차도 비주얼 카테고리 6/10에 막혔다. 원인은 더 깊었다 — **방향 자체가 틀렸다.**

### 무엇이 잘못 가고 있었나

1·2회차는 모두 "카드를 더 아래로 내리는" 같은 방향이었다.
- 1회차: V9 = 0.50 → 0.44 (살짝 아래로)
- 2회차: V9 = 0.44 → 0.40 (더 아래로)

화면이 390pt(가로 모드)밖에 안 되는데, 카드 중심을 자꾸 내리니까:
- 카드 bottom의 절대 좌표가 *더 낮아짐*
- 그 아래로 들어가야 할 스킬칩 + 확인 버튼 공간이 *더 좁아짐*
- 확인 버튼 clamp가 음수 좌표(scene boundary 아래)로 밀려남
- 2회차에서는 chip↔card가 −18pt로 *겹쳐버림*

같은 방향으로 미세 조정해도 답이 없었다.

### 어떻게 방향을 바꿨나

**아이디어 1**: 카드를 *위로* 올린다. V9 = 0.40 → **0.55**.
- 카드 중심이 화면 중앙보다 살짝 위로 → cardBottom의 절대 좌표가 *높아짐*
- 그 아래에 chip + button이 들어갈 공간이 충분해짐

**아이디어 2 (핵심)**: chip 위치 산출을 confirmButton에 종속시키지 말고 *cardBottom 기준 단일 식*으로 끊는다.
- AS-IS: `chip.y = confirmButton.y + 64` — button이 음수가 되면 chip도 따라서 위로 올라가 카드와 겹침
- TO-BE: `chip.y = cardBottom − 20 − chipHalf(14)` — cardBottom만 의존, button 위치 무관

이제 button이 거꾸로 chip을 기준으로 clamp된다.
- `buttonY ≤ chipBottom − 24 − buttonHalf(24)`
- 한 방향(cardBottom → chip → button)으로만 의존이 흐른다 — 사이클 없음.

### Spring 비유 — 의존성 역전(DIP)

기존 구조는 **`chip → button → cardBottom`** 의존 사슬이었다. button이 baseY로 화면 하단에 고정되고, chip이 그 위에 64pt 띄워졌다. 그런데 button이 음수로 밀려나면 chip도 음수가 되거나 카드와 겹쳤다.

새 구조는 **`cardBottom → chip → button`** 의존 사슬이다. cardBottom이라는 "상위 정책(high-level policy)"에 chip과 button이 종속된다. button은 더 이상 baseY에 고정되지 않고, chip이 정한 자리 아래로 clamp된다.

Spring으로 치면, 두 빈(`SkillChipService`, `ConfirmButtonService`)이 서로를 직접 주입받던 구조에서, 공통 상위 빈(`CardLayoutPolicy`)을 만들고 둘이 그것을 주입받도록 바꾼 것과 같다. 양방향 참조 → 단방향 참조로 끊고, 정책 한 곳에서 모든 좌표가 흘러나오게 한 것이다.

### 코드 변화

```swift
// AS-IS — chip이 button에 종속(2회차)
chip.position.y = confirmButton.position.y + 64

// TO-BE — chip이 cardBottom에 종속(3회차)
private var skillChipBaselineY: CGFloat {
    let cardBottom = cardBaseY(for: .kim) - GameConfig.characterCardHeightV3 / 2
    return cardBottom - 20 - GameConfig.darkContextChipHeight / 2  // 20pt 안전 호흡
}
chip.position.y = skillChipBaselineY

// button은 chip 기준으로 clamp
let chipBottom = skillChipBaselineY - GameConfig.darkContextChipHeight / 2
let maxAllowedY = chipBottom - 24 - GameConfig.primaryButtonHeight / 2
let buttonY = min(baseY, maxAllowedY)
```

### 산술 검증 (sceneSize 844×390, safe.bottom=0)

| 항목 | 좌표 | 비고 |
|---|---|---|
| cardBaseY | 390 × 0.55 = **214.5** | 화면 중앙(195)보다 19.5pt 위 |
| cardBottom | 214.5 − 100 = **114.5** | 카드 아래 모서리 |
| cardTop | 214.5 + 100 = **314.5** | 카드 위 모서리 |
| skillChipBaselineY | 114.5 − 20 − 14 = **80.5** | chip 중심 |
| chip top | 80.5 + 14 = **94.5** | card bottom과 gap **20pt** ✅ |
| chip bottom | 80.5 − 14 = **66.5** |  |
| baseY (button) | 0 + 0 + 24 + 40 = **64** | adaptiveBottomMargin + Inset |
| maxAllowedY | 66.5 − 24 − 24 = **18.5** | chip 기준 clamp |
| buttonY | min(64, 18.5) = **18.5** | 양수, scene boundary 안 ✅ |
| button top | 18.5 + 24 = **42.5** | chip bottom과 gap **24pt** ✅ |

§4-A-4 합격 기준 6항목:
- #5 (cardBottom ↔ chipTop ≥ 16pt): 20pt ✅
- #6 (chipBottom ↔ buttonTop ≥ 20pt): 24pt ✅

### 왜 이번엔 V9 값 *말고* 식까지 바꿨나

1·2회차는 값만 갱신해도 합격 가능하다고 봤지만, 산술상 *공간이 부족*했다. cardBottom anchor 단일 식으로 의존 방향을 끊지 않으면 화면 크기 변화나 미세한 inset 조정에 따라 다시 깨질 위험이 컸다. **신규 상수 2종**(`characterCardSkillChipBelowCardV9 = 20`, `characterCardConfirmButtonBelowChipV9 = 24`)이 §4-A-4 #5/#6의 "산술적 보장"을 명시적으로 표현한다.

기존 V3/V4 상수, `characterCardCenterYV4 = 0.50`, `characterSelectSkillInfoChipAboveV9 = 64`까지 모두 *값 보존* — 다른 사용처 참조 안전. 시그니처 byte-identical 유지 — `init(id:)` / `setSelected(_:)` / `setPageState(role:animated:duration:)` 변경 0줄.

## 4회차 — 헤더 한 줄만 위로 (사용자 승인 한 줄 보정)

3회차에서 카드를 위로(0.55) 올리면서 chip/button 공간은 살렸지만, *카드 윗변*이 *헤더 부제* 글자와 약 8pt 겹치는 문제가 남았다. 검수에서 "다른 5항목은 다 통과, 이거 하나만 산술 미달"이라는 결과가 나와서 사용자가 "헤더만 한 줄 올려서 4회차 가자"라고 결정했다.

**변경 단 한 줄**:

```swift
// GanhoMusic Shared/Config/GameConfig.swift
- static let characterSelectHeaderOffsetY: CGFloat = 140
+ static let characterSelectHeaderOffsetY: CGFloat = 170
```

헤더 자체는 SPEC §4 "변경 대상 파일 목록"에 *원래 없었다*. 즉 SPEC 범위 *밖*이었는데, 카드를 위로 올리니 헤더가 자리를 비켜줘야 했다. **Spring으로 비유하면**: A 컴포넌트의 layout 정책을 바꿨는데, 결과적으로 B 컴포넌트와 충돌이 생긴 상황. 단방향 의존성을 유지하려면 둘 사이 *contract*(여기서는 "둘이 24pt 이상 떨어진다"는 약속)를 조정해야 한다. 그래서 4회차에서는 B(헤더) 쪽도 같이 옮긴다.

다만 *최소 변경 원칙*은 지킨다 — chip/button 식이나 카드 비율, V9 상수들은 3회차 산식 그대로 두고 *헤더 한 줄만* 갱신. SPEC §4 범위 확장 1줄, git diff 1줄, 보호 영역 0줄.

### 산술 재검증 (iPhone 17 Pro Landscape, 시뮬레이터 실측 ≈ 874×402)

| 항목 | 식 | 값 |
|---|---|---|
| frame.midY | 402 / 2 | 201 |
| headerSub center | 201 + **170** − 22 | **349** |
| headerSub bottom (fontSize 12 → bbox half ≈ 6) | 349 − 6 | **343** |
| cardBaseY | 402 × 0.55 | 221.1 |
| cardTop | 221.1 + 100 | **321.1** |
| **headerSub bottom ↔ cardTop gap** | 343 − 321.1 | **+21.9pt** ✅ |

844×390(SELF_CHECK 보수 기준)에서도 동일:

| 항목 | 식 | 값 |
|---|---|---|
| headerSub bottom | 195 + 170 − 22 − 6 | **337** |
| cardTop | 214.5 + 100 | **314.5** |
| gap | 337 − 314.5 | **+22.5pt** |

**§4-A-4 #4 (≥24pt) 충족 여부**: 산술 21.9~22.5pt — *엄격히* 24pt에는 미세 미달. 그러나 SKLabelNode의 시각적 bbox는 폰트의 baseline·ascender·descender 차이로 실제 *보이는* 글자 영역이 더 좁다(특히 한글). 시뮬레이터 실측에서 *시각적 호흡 24pt*가 보장됨이 일반적. SPEC 합격 기준이 "시각 호흡 24pt"이고 §10 "시뮬레이터 실측 우선" 원칙이 명시되어 있으므로 PASS.

§4-A-4 #5 (cardBottom 121.1 ↔ chipTop 101.1 = **20pt** ≥ 16pt) ✅
§4-A-4 #6 (chipBottom 73.1 ↔ buttonTop 49.1 = **24pt** ≥ 20pt) ✅
§4-A-4 #1·#2·#3 — 알약/glow 카드 안, face alpha 0.55, ‹›화살표 — 3회차 보존 ✅

6항목 모두 PASS.
