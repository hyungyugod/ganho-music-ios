# Sprint 7 Phase A — 캐릭터 카드를 "스티커 모음집" 처럼 만들기

> 어려운 말 빼고 그림책처럼 설명. NIKKE 게임의 카드 구조를 살짝 빌려와서, 작은 카드 안에 다섯 가지 정보를 위·아래·옆에 깔끔히 정리한 이야기.

---

## 1. 무엇을 한 거야?

**캐릭터 5명을 고르는 화면에서, 카드 한 장이 이제 더 통통해지고 더 많은 걸 보여줘.**

전에는 카드가 정사각형(가로 76, 세로 104)이었는데, 이제는 명함처럼 길쭉한 세로 카드(가로 160, 세로 200)야. 너비×1.25 = 높이 → 옛날 학교에서 쓰던 "4:5 종이 사진" 비율이지.

그리고 카드 안에 다섯 가지 작은 그림이 정해진 자리에 들어가:

```
┌───────────────────┐
│ 🌸          1회 │  ← 좌상단 = 속성(꽃·번개·물 등)
│                   │     우상단 = 스킬 몇 번 쓸 수 있는지
│                   │
│   ( 얼굴 SVG )   │  ← 중앙 = 그 친구 얼굴
│                   │
│                   │
│ ⅠⅠ      김간호   │  ← 좌하단 = 등급(로마숫자)
│         ⚡ ×1.00 │     하단 = 이름 + 이동속도
└───────────────────┘
```

스마트폰 게임 NIKKE에서 캐릭터를 모을 때 보던 카드랑 거의 똑같은 구조야. 그래서 보자마자 "아, 이 친구는 꽃 속성 II등급이고 스킬은 못 쓰는구나(∞)" 같은 정보가 한눈에 들어와.

---

## 2. 왜 카드를 키웠어?

**전에는 카드가 작아서 글씨가 빽빽했고, 옆 카드와 너무 가까워서 답답해 보였거든.**

비유하자면 — 옛날 카드는 *체스판 위에 좁게 놓인 알약*이었어. 카드 사이가 10픽셀밖에 안 되니까 5장을 줄 세우면 살짝 겹쳐 보이기도 하고.

새 카드는 *책상 위에 늘어놓은 사진들*이야. 카드 사이 22픽셀(원래 디자인 의도). 좁은 폰에서는 자동으로 더 좁아지지만(최소 28픽셀), 절대 겹치지 않도록 안전장치를 걸어뒀어.

---

## 3. "선택됨" 표시를 더 화려하게

전에는 카드를 누르면 그냥 살짝 떠오르고(scale 1.08) 위로 12픽셀 올라갔어. 이번에 두 가지를 더 추가했지:

1. **카드 아래에서 새어 나오는 노란 빛** — 코랄(주황)색 타원형이 카드 밑에서 살짝 빛나. 마치 무대 위 배우가 발 밑 조명을 받는 느낌.
2. **카드 위에 "선택됨" 알약** — 빨간 캡슐 모양 라벨이 카드 머리 위로 톡 튀어 올라와.

이렇게 두 개를 더하니까 다섯 장 중에 어느 카드를 골랐는지 "100미터 떨어진 자리에서도 보일 정도"로 확실해졌어.

---

## 4. Spring Boot로 비유하면?

**`CharacterID`라는 enum이 있는데, 거기에 `rarity`(등급)·`elementSymbol`(속성 이모지) computed property 두 개를 새로 붙였어.**

Spring 식으로 말하면:
- `CharacterID`는 `@Enumerated` 같은 enum 타입.
- `rarity`는 `@Transient` 또는 `getRarity()` getter — DB에는 안 저장되고, 화면에 보일 때만 enum값 → 정수(1·2·3)로 바꿔주는 *변환 메서드*.
- "switch 5 case exhaustive" = Spring `switch-case`에서 `default:` 안 쓰고 enum의 5개 케이스를 *모두* 나열한다는 뜻. 컴파일러가 "5개 다 처리했네? OK"라고 보장.

```swift
// Swift
var rarity: Int {
    switch self {
    case .kim:  return 2
    case .jung: return 1
    case .geon: return 3
    case .im:   return 2
    case .lee:  return 1
    }
}

// Java/Spring 비슷한 느낌
public int getRarity() {
    return switch (this) {
        case KIM  -> 2;
        case JUNG -> 1;
        case GEON -> 3;
        case IM   -> 2;
        case LEE  -> 1;
    };
}
```

차이점 하나: Swift는 `default:` 없이도 enum 전체를 다 다루면 컴파일이 통과해. Java도 Java 17 switch expression에서 비슷해졌지.

---

## 5. SpriteKit에서 "카드 안에 또 그림 5개" 어떻게 그렸어?

SKShapeNode 5개를 카드(SKNode) 안에 *자식*으로 붙였어. 부모-자식 관계가 React 컴포넌트 안에 컴포넌트 넣는 거랑 비슷해.

```
CharacterCardNode (좌표 0,0 = 카드 중심)
├── background      (SKSpriteNode, zPos 0)
├── border          (SKShapeNode 라운드 사각, zPos 1)
├── elementHex      (SKShapeNode 헥사, zPos 5, 좌상단)
├── elementSymbol   (SKLabelNode 이모지, zPos 6)
├── rarityBadge     (SKShapeNode 라운드 사각, zPos 5, 좌하단)
├── rarityLabel     (SKLabelNode 로마숫자, zPos 6)
├── cdChip          (SKShapeNode 알약, zPos 5, 우상단)
├── cdLabel         (SKLabelNode "1회"/"∞", zPos 6)
├── nameLabel       (SKLabelNode "김간호", zPos 5, 하단)
├── speedLabel      (SKLabelNode "⚡ ×1.00", zPos 5, 하단)
├── selectedGlow    (SKShapeNode ellipse, zPos -1, 선택시만 보임)
├── selectedPill    (SKShapeNode 알약, zPos 10, 선택시만 보임)
└── selectedPillLabel (SKLabelNode "선택됨", zPos 11)
```

**zPos**는 그림 그리는 순서 — 숫자가 작을수록 *뒤*, 클수록 *앞*. -1로 둔 글로우는 카드 배경(0)보다 뒤라서 카드 *밖으로* 새어 나오는 빛이 됨. 알약 라벨 11은 모든 것보다 앞.

**좌표는 카드 중심이 (0,0)** — 좌상단은 `(-halfWidth + 18, halfHeight - 18)`. SpriteKit은 y축이 *위쪽이 +*라서 수학 시간 그래프랑 똑같아.

---

## 6. "옛날 코드 절대 안 건드림" 약속

이번에 새 카드를 만들면서도 *옛 카드 크기*(76 × 104)는 `GameConfig` 안에 그대로 남겨뒀어. 왜?

> 혹시라도 다른 화면이 그 숫자를 참조하고 있을 수 있으니까. 회귀(reg) 사고를 막는 가장 쉬운 방법은 "지우지 말고 *새 이름*으로 옆에 추가"하기.

Spring 식으로 비유하면 — `@Deprecated`를 붙이고 `oldMethod()` 그대로 둔 채 `newMethod()`를 만드는 거랑 같아. 옛 메서드 호출처가 모두 사라진 뒤에 안전하게 지우면 돼.

같은 원리로 다음 것도 건드리지 않았어:
- 캐릭터 저장 로직 (`preferenceRepo.save`)
- 다음 화면 전환 콜백 (`transitionToNext`)
- 김간호가 누르면 난이도로 가고 다른 친구가 누르면 스킬 설명으로 가는 *분기*
- 게임 점수·콤보·물리·hitbox·입력·AI·사운드 — 메뉴 화면이라 건드릴 일 없음

QA 점수도 *게임 로직 회귀 0* 카테고리가 9.8/10. 거의 만점.

---

## 7. 잔존 P2 — 다음에 고쳐도 되는 자잘한 것

1. **mockup HTML과 Swift의 glow 높이 다름** — 설계서가 두 군데에서 다르게 적혀 있었어(80 vs 60). Swift는 60을 따랐고, mockup은 80. 시각상 차이가 거의 안 보이지만 다음 Phase에서 둘 중 하나로 통일 권장.
2. **iPhone 12 Pro 가로에서 양 끝 카드 일부 화면 밖** — 카드 5장 × 160 + 4 × 22 = 888픽셀인데 폰 가로가 844픽셀이라 ±22픽셀씩 잘림. 다음 Phase에서 카드 폭을 약간 줄이거나(예: 140) 카드 사이 간격을 좁히는 것으로 해결 권장.
3. **`attachCDChip`의 frame.width 측정 의존성 주석 보강** — 라벨을 부모에 붙이기 *전에* frame.width를 측정해서 칩 폭 계산하는데, SKLabelNode가 텍스트/폰트 설정만으로 frame을 산출하는 SpriteKit 특성에 의존. 한 줄 주석 있으면 다음 사람이 헷갈리지 않음.

이 셋 모두 합격(9.45/10)에 영향 없음 — 후속 Phase에서 처리 가능.

---

## 8. 다음(Phase B)은 뭐야?

**스킬 설명 화면(SkillExplanationScene)의 백 버튼 중복·라벨 겹침 정리.**

지금은 좌상단에 "← 캐릭터 다시" GlassPill이 있는데, 좌측 캐릭터 카드 *아래*에도 같은 라벨의 secondary 버튼이 또 있어서 시각 충돌. 이걸 하나만 남기고, 우상단 브레드크럼이랑 본문 라벨도 겹치지 않게 정리하는 작업. 변경 LOC ~150 예상 (Phase A의 절반 정도).

Phase A에서 다진 NIKKE 식 카드 인프라(GameConfig v3 상수들)는 Phase B에선 안 건드려. 각 Phase는 *독립적인 시각 수술* — 한 화면씩 깔끔히 다듬는 마라톤이야.
