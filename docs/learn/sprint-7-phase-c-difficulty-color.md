# Sprint 7 Phase C — "쉬움·보통·어려움 색깔로 구분하기"

> 난이도 카드 3장이 모두 같은 톤이라 *어느 게 쉽고 어느 게 어려운지* 색만으론 모르던 문제를 고친 이야기.

---

## 1. 무엇이 문제였어?

전에는 난이도 카드 3장(쉬움/보통/어려움)이 모두 *같은 피치 톤*이었어. 라벨을 읽어야만 어느 카드가 어떤 난이도인지 알 수 있었지.

게임에서는 *0.5초 안에 보이는 것*이 중요해. 신호등을 생각해봐 — 빨강·노랑·초록 색만 봐도 "멈춰·조심·가" 의미를 즉시 알지. 글자를 읽지 않아도 돼.

---

## 2. 어떻게 고쳤어?

신호등 원리를 그대로 빌려왔어:

| 난이도 | 색 그라데이션 | 의미 |
|---|---|---|
| **하 (.easy)** | 민트 (#9BE0CC → #5EBFA3) | "여유롭게, 천천히" |
| **중 (.normal)** | 골드 (#FFD27A → #E5A647) | "주의해서, 표준 템포" |
| **상 (.hard)** | 코랄 (#FF8E80 → #FF6B5B) | "긴장, 도전" |

카드 배경 자체가 색 그라데이션이라 라벨을 읽기 *전*에 강도가 느껴져.

---

## 3. Swift enum에 "색 lookup" 4개 메서드 추가

`Difficulty`라는 enum이 이미 있었어. 거기에 *시각용 색 조회* 메서드 4개를 새로 붙였지:

```swift
// Models/Difficulty.swift
// MARK: - Sprint 7 Phase C · Card hierarchy colors

var cardFillTop: UIColor {
    switch self {
    case .easy:   return .ganhoDifficultyEasyMint    // #9BE0CC
    case .normal: return .ganhoDifficultyMidGold     // #FFD27A
    case .hard:   return .ganhoDifficultyHardCoral   // #FF6B5B
    }
}

var cardFillBottom: UIColor   { /* 그라데이션 하단 색 */ }
var cardStrokeColor: UIColor  { /* 카드 테두리 색 (선택 시) */ }
var cardGlowColor: UIColor    { /* 선택 시 카드 뒤 빛 색 */ }
```

**switch default 안 씀.** 왜?

- `default:`를 쓰면 *enum에 새 케이스를 추가했을 때 컴파일러가 알려주지 않아*. 예를 들어 누군가 `case extreme`을 추가했다고 치자. default가 있으면 `.extreme`도 default로 처리되어 *조용히* 잘못된 색이 나옴.
- exhaustive switch (모든 case 나열)면 컴파일러가 *경고*를 내. "어, .extreme case를 빠뜨렸어요!" 안전망.

Spring 식 비유: `@Enumerated` 처리 메서드에서 `switch` + `default:`로 안전 fallback을 두는 것 vs Java 17 `switch expression`에서 모든 case를 다 나열해 컴파일러가 빠진 case를 잡아주는 것. 후자가 안전.

---

## 4. SKLabelNode는 stroke를 직접 지원 안 해. 어떻게 외곽선?

CSS에서는 `text-stroke: 1px coral`로 텍스트 외곽선을 그릴 수 있지만, SpriteKit `SKLabelNode`는 stroke 속성이 *없어*. 그래서 *라벨 2개를 겹쳐* 표현했어:

```
┌─────────────────────────────┐
│        김간호 ← 30pt navy   │  앞쪽 (nameLabel, zPos 5.0)
│       김간호 ← 32pt cardStroke│ 뒤쪽 (nameLabelStroke, zPos 4.9)
└─────────────────────────────┘
```

베이스(뒤) 라벨은 폰트 *32pt*에 카드별 강조색(민트 deep / 골드 deep / 코랄 deep). 그 위에 *30pt navy* nameLabel을 얹어. 베이스 라벨이 1pt씩 양쪽으로 *삐져나와* 외곽선처럼 보임.

웹의 `text-shadow`로 흉내내는 outline 효과와 똑같은 원리야. SpriteKit에는 stroke가 없으니까 *물리적으로 두 노드*를 겹쳐서 만들어야 해.

---

## 5. 선택 카드 -8pt 위로 띄우기 — "증분 패턴"

선택한 카드는 *8픽셀 위*로 살짝 떠야 해. 그런데 액션을 잘못 쓰면 *누적*돼서 클릭할 때마다 8, 16, 24... 위로 계속 올라가는 버그가 생겨.

해결: **현재 떠있는 정도를 인스턴스 변수로 추적**하고, 그 차이만큼만 이동.

```swift
private var liftCurrentOffset: CGFloat = 0  // 지금 떠있는 정도

func setSelected(_ selected: Bool) {
    let targetY: CGFloat = selected ? 8 : 0   // 목표
    let delta = targetY - liftCurrentOffset   // 차이만큼만 이동
    let lift = SKAction.moveBy(x: 0, y: delta, duration: 0.18)
    run(lift, withKey: "cardLift")
    liftCurrentOffset = targetY               // 새 위치 기록
}
```

이 패턴을 *증분 패턴* 또는 *idempotent state*라고 불러. 함수를 여러 번 호출해도 결과가 같아.

Spring 비유: 잔액 업데이트할 때 `balance += amount` 같은 *증분 SQL*은 동시성 위험. 대신 `balance = newBalance` *절대값 set*. 위 코드도 비슷한 안전 원칙.

---

## 6. 시작 버튼 halo — PrimaryButtonNode를 *건드리지 않고* 빛 추가

시작 버튼 뒤에 큰 라디얼 글로우(`halo`)를 더하고 싶었어. 마치 *마지막 결정*을 시각으로 약속하는 듯한 효과.

**선택지 A**: `PrimaryButtonNode` 클래스 자체를 수정해 halo 기능 추가.
- 단점: PrimaryButtonNode는 시작 화면·캐릭터 선택·스킬 설명·난이도 선택 *모든 곳*에서 쓰임. halo가 강제로 켜져서 다른 화면이 깨질 수 있음.

**선택지 B**: `DifficultySelectScene`에서만 별도 `SKShapeNode`를 시작 버튼 *뒤*에 부착.
- 장점: PrimaryButtonNode 0줄 변경. 다른 화면 영향 0.
- 선택!

```swift
// DifficultySelectScene에서
private var startButtonHalo: SKShapeNode?

private func setupStartButton() {
    let halo = SKShapeNode(ellipseOf: CGSize(width: 240, height: 90))
    halo.fillColor = UIColor.ganhoCoralPrimary.withAlphaComponent(0.35)
    halo.strokeColor = .clear
    halo.glowWidth = 24            // SpriteKit의 부드러움 효과
    halo.alpha = 0                 // 처음엔 안 보임
    halo.zPosition = startButton.zPosition - 1   // 버튼보다 뒤
    addChild(halo)
    halo.run(SKAction.fadeAlpha(to: 1.0, duration: 0.25))  // 0.25초 페이드 인

    addChild(startButton)
}
```

Spring 비유: 공통 라이브러리 코드를 *직접 수정*해 모든 호출자에 영향 vs *Wrapper/Decorator*로 특정 호출자만 기능 추가. 후자가 안전.

---

## 7. SpriteKit의 `glowWidth`는 진짜 blur가 아냐

CSS에서는 `filter: blur(24px)`로 가우시안 블러를 줄 수 있어. 부드러운 후광 효과. SpriteKit의 `SKShapeNode.glowWidth`는 *진짜* 블러가 아니라 *stroke를 부드럽게 바깥으로 확장*하는 효과야.

mockup의 CSS 블러와 100% 동일한 결과는 안 나오지만, *근사*는 가능. 카드 뒤 글로우는 `id.cardGlowColor` ellipse + glowWidth 12pt 패턴으로 *유사한* 빛이 새어 나오는 느낌을 줘.

진짜 가우시안 블러가 필요하면 `SKEffectNode`로 `CIFilter`(Core Image 필터) 적용 가능하지만 *성능 비용*이 큼. 이 게임 정도 규모에서는 glowWidth 근사로 충분.

---

## 8. 색 토큰을 ColorTokens에 분리한 이유

```swift
// ColorTokens.swift
static let ganhoDifficultyEasyMint   = UIColor(hex: "#9BE0CC")
static let ganhoDifficultyEasyDeep   = UIColor(hex: "#5EBFA3")
// ... 4 more
```

기존에 비슷한 hex 값을 가진 토큰이 있어:
- `ganhoScrubMint` = `#9BE0CC` (캐릭터 속도 칩에 쓰던 민트)
- `ganhoCoralPrimary` = `#FF6B5B` (코랄 강조색)

같은 hex라도 *의도*가 다르면 **별도 토큰명**으로 분리해. 왜?

- 나중에 "민트 톤을 살짝 더 진하게 바꾸자"는 결정이 나왔을 때, `ganhoScrubMint`(캐릭터용)만 바꾸면 *캐릭터 색은 변하지만 난이도 카드는 그대로*. 의도 분리.
- 코드를 읽는 사람이 "왜 여기서 scrubMint를 쓰지?" 의문 갖지 않음. `ganhoDifficultyEasyMint`라고 적혀 있으면 *난이도 카드 쉬움 색*이라는 의도가 즉시 보임.

Spring 비유: `@Value("${app.color.scrub-mint}")` vs `@Value("${app.color.difficulty.easy}")`. 값이 같아도 *이름*으로 의도를 분리하면 변경 시 영향 범위가 명확.

---

## 9. 보호 영역 13파일 + PrimaryButtonNode 모두 0줄

이번에도 자랑할 만한 결과:

- **PrimaryButtonNode**: 0줄 (halo는 Scene 책임이라 컴포넌트 자체는 건드림 0)
- **Phase A·B 결과물 6개** (CharacterCardNode/CharacterFaceNode/CharacterSelectScene/SkillExplanationScene/CharacterID/PlayerSkill): 0줄
- **게임 로직 4파일** (ResultScene/GameScene/GameState/PhysicsCategory): 0줄
- **Managers/Repositories/Systems 디렉토리**: 0줄

총 보호 파일 ~14개 *모두* 손대지 않으면서 새 색 위계만 더한 거.

---

## 10. 잔존 P2 — 작은 정리 1건

`DifficultySelectScene.swift`에 속도 칩 stroke를 1pt로 설정하는 곳이 있어:

```swift
chip.lineWidth = 1   // ← 매직 넘버
```

엄격히 보면 1도 GameConfig 상수로 옮기는 게 일관성. 차기 정리 Sprint에서 `difficultySelectSummarySpeedChipStrokeWidth = 1`로 옮길 후보. 합격엔 영향 없음.

---

## 11. 다음(Phase D)은 뭐야?

**결과창 정리 + 신규 ScoreboardScene 신설.**

지금 결과창에는:
- 큰 음표(♪) 아이콘 위에 "0 SCORE" + "BEST 0" 라벨이 *겹쳐* 보임 — 시각 우선순위 모호
- 하이스코어 진입점이 *없음* — 캐릭터·난이도별 최고기록을 볼 수 없음

Phase D에서:
- ♪ 아이콘을 점수 *옆에 작게*, 점수가 시각의 주인공
- "기록 보기" 칩을 새로 추가 → 탭하면 **ScoreboardScene** (5×3 매트릭스: 5캐릭터 × 3난이도) 으로 이동
- ScoreboardScene은 신규 파일 ~400 LOC 예상

Phase A·B·C 패턴(V3 신규 상수 + 기존 보존 + 회귀 0)을 그대로 이어가. 데이터 소스(`PerDifficultyScoreRepository`/`StatisticsRepository`/`GraduationRepository`)는 0 건드림 — 읽기만.
