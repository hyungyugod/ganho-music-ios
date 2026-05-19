# Sprint 7 Phase B — "같은 말 두 번" 안 하는 화면 만들기

> 스킬 설명 화면에서 똑같은 정보가 두 군데에 나오던 걸 한 군데로 모은 이야기.

---

## 1. 무엇이 문제였어?

스크린샷을 보면 같은 정보가 *두 번* 나오고 있었어:

1. **"← 캐릭터 다시" 버튼**이 좌상단(둥근 알약)에 한 개, 좌측 캐릭터 카드 *아래*에도 한 개 — 둘 다 똑같이 캐릭터 선택으로 돌려보내는 버튼인데 *어느 쪽을 눌러야 할지* 헷갈렸어.
2. **"임간호의 스킬"** 같은 라벨이 우측 본문 위에 큼지막하게 떠 있었는데, 우상단의 작은 브레드크럼(`임간호 · 스킬 · 난이도`)에도 같은 정보가 들어 있었지.

마트에서 같은 상품 가격표가 두 군데 붙어 있는 느낌. 손님이 *어느 가격이 진짜냐* 0.3초간 망설이게 돼.

---

## 2. 어떻게 고쳤어?

**"각 영역 책임 한 가지씩"** 원칙으로 정리:

| 화면 영역 | 책임 |
|---|---|
| 좌상단 | **뒤로 가기** (GlassPill `← 캐릭터 다시` 1개만) |
| 우상단 | **현재 위치** (DarkContextChip 브레드크럼 1개만) |
| 본문 | **스킬 정보** (이름·인용·메타칩) |
| 하단 | **다음으로 가기** (PrimaryButton `다음 ▶` 1개만) |

각 영역에 *한 종류의 정보*만 두니까 시선이 갈팡질팡하지 않아.

---

## 3. 코드는 어떻게 안전하게 지웠어?

가장 큰 고민: **노드를 완전히 삭제하면 다른 데서 참조하다가 깨질 위험**이 있어. 그래서 *두 단계 옵션*이 있었지:

- **옵션 A**: `addChild(backButton)` 호출만 빼기 — 노드는 메모리에 살아있되 *씬 그래프(눈에 보이는 트리)*엔 안 붙음. 화면에 안 나옴.
- **옵션 B**: `backButton.isHidden = true` — 노드는 씬에 붙어 있지만 보이지 않음.

**옵션 A를 골랐어.** 왜?

- `touchesBegan`(터치 감지 함수)이 `backButton.contains(location)`로 탭 판정을 하는데, *씬에 없는 노드*는 hit-test가 자동으로 false가 돼. 따로 가드 코드 추가할 필요가 없음.
- 옵션 B는 isHidden 노드도 contains는 true 반환할 수 있어서 `!backButton.isHidden` 가드를 추가해야 함 — 코드 한 줄 더, 회귀 위험 +1.

Spring 비유: `@Component` 빈을 `@ConditionalOnProperty`로 *등록 자체*를 막는 것 vs `@Component`는 등록되지만 `enabled = false` 플래그로 무효화하는 것. 전자가 더 깔끔.

```swift
// 변경 전
private func setupButtons() {
    addChild(backButton)   // ← 이 줄을 지움
    addChild(startButton)
    layoutButtons()
}

// 변경 후
private func setupButtons() {
    // Sprint 7 Phase B — backButton은 좌상단 topBackPill이 단독 책임.
    //                    하단에서 제거(addChild 호출 안 함). 인스턴스는 보존.
    addChild(startButton)
    layoutButtons()
}
```

`backButton` 변수 자체는 *클래스 프로퍼티에 그대로* 남겨놓았어. 시그니처(클래스 외부에서 보이는 인터페이스)가 그대로라 *외부 호출자가 깨지지 않음*.

---

## 4. v2/v3 상수 패턴은 왜 또 만들었어?

Phase A에서 `characterCardWidthV3`처럼 *V3 접미사*를 붙여 신규 상수를 별도로 만들었듯, Phase B에서도 같은 패턴:

```swift
// 기존 v2 상수 — 값 그대로 보존 (혹시 다른 곳에서 참조할까봐)
static let skillExplanationQuoteBoxWidth: CGFloat = 300
static let skillExplanationQuoteBoxBorderWidth: CGFloat = 3
static let skillExplanationStatChipSpacing: CGFloat = 8

// 신규 V3 상수 — Phase B용
static let skillExplanationQuoteBoxWidthV3: CGFloat = 332   // +32 (47%→52%)
static let skillExplanationQuoteBoxBorderWidthV3: CGFloat = 4    // +1 (3→4)
static let skillExplanationStatChipSpacingV3: CGFloat = 10  // +2 (8→10)
```

그리고 `SkillExplanationScene` 안에서 V3 상수를 *참조 라인 3곳*만 교체하면 끝.

이 패턴의 장점:
- 옛 값과 새 값이 *동시에 존재* — 빌드 안 깨짐
- 다른 화면이 옛 상수를 참조한다 해도 그대로 작동
- 시각 검증 후 옛 상수를 안전하게 삭제 가능 (충분히 시간이 지나면)

DB 마이그레이션의 *blue-green deployment* 같은 거야 — 신·구 버전이 잠시 공존하다가 안전 확인 후 구버전을 폐기.

---

## 5. mockup HTML은 무엇이 다른가?

`mockups/skill-explanation-v2.html`을 베이스로 복사하고 *4가지만* 바꿨어:

1. **좌측 캐릭터 카드 하단의 secondary 백 버튼 제거** — HTML 주석으로 `<!-- v3: 하단 secondary 백 버튼 제거 -->` 표시
2. **우측 본문 상단 "임간호의 스킬" 코랄 라벨 제거** — 동일 패턴
3. **우측 본문 영역 `flex 1 1 47%` → `52%`** + 인용 박스 `border-left: 3px` → `4px` + 메타칩 `gap: 8px` → `10px`
4. **하단 버튼 행**: 백 버튼 + Primary 두 개 → Primary 단독 중앙

HTML 하단 `annotation` 박스 3개에:
- 🧹 중복 제거 (각 정보 책임 1개씩)
- 🫁 본문 호흡 +5%p (52% 폭, 보더 4px, gap 10)
- 🎯 위계 명확 (영역별 한 종류 정보만)

---

## 6. 보호 영역 13개 파일 모두 0줄

이번 작업의 가장 큰 자랑: 건드린 파일이 *정확히 2개 Swift + 1개 HTML*뿐.

13개 보호 파일 그룹 모두 `git diff` 결과 0줄:

- **Phase A 결과물 4개** (CharacterCardNode / CharacterSelectScene / CharacterID / PlayerSkill)
- **게임 로직 4개** (ResultScene / GameScene / GameState / PhysicsCategory)
- **보호 노드 5개** (StoryBoxNode / DarkContextChipNode / GlassPillNode / BackButtonNode / PrimaryButtonNode)

이게 *디자인 리뉴얼 모드* 하네스의 핵심 가치야 — 시각 정비를 하면서 게임 로직과 다른 화면을 1픽셀도 건드리지 않음.

---

## 7. 잔존 P2 — 차기 정리 Sprint 후보

`setupMetaLabel()` / `layoutMetaLabel()` 두 함수가 *비활성 상태*로 남아 있어. metaLabel 인스턴스는 살아 있고, 함수도 호출되지만 결과가 화면에 안 보임. 마치 *전원은 켜져 있지만 모니터 케이블이 빠진 PC* 같은 상태.

SPEC OQ-2가 "인스턴스 보존" 원칙으로 결정했기 때문에 의도적 잔류. 차기 정리 Sprint(예: Sprint 7-G 이후 또는 Sprint 8 시작 전)에서:
- `metaLabel` 프로퍼티 자체 삭제
- `setupMetaLabel()` / `layoutMetaLabel()` 함수 삭제
- `didChangeSize(_:)`에서 호출되던 자리 정리

이 정리는 회귀 위험 0 — 외부 호출자 없음.

---

## 8. 다음(Phase C)은 뭐야?

**난이도 선택 카드(쉬움/보통/어려움)의 색 위계 강화.**

현재는 3장 카드가 모두 같은 피치 톤이라 *어느 게 쉽고 어느 게 어려운지* 색만으론 모름. Phase C에서:
- 하 = 민트(부드러움)
- 중 = 골드(주의)
- 상 = 코랄(긴장)

3-stop 그라데이션을 각 카드에 적용하고, 선택 시 해당 색의 radial 글로우 + 미선택 카드 opacity 0.78로 떨어뜨려 시선 집중. ColorTokens에 새 토큰 6개 추가. 변경 LOC ~200 예상.

Phase A·B 패턴(V3 신규 상수 + 기존 보존 + 회귀 0)을 그대로 이어가.
