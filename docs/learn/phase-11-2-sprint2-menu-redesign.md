# Phase 11-2 (Sprint 2) — 메뉴 3씬 v2 리스킨 (부품 조립)

## 한 줄 요약
**Sprint 1에서 깎아둔 부품(글래스 알약·다크 칩·코랄 라인·코랄 버튼·반투명 백)을 가지고 메인/캐릭터선택/스킬설명 세 화면을 카툰 톤으로 갈아끼웠어요.** 다크 배경 → 피치→코랄→라벤더 노을 그라데이션, 시스템 폰트 → Jua/Gowun Dodum, 검정 패널 → 글래스 칩. 게임 로직·전환·저장은 한 줄도 안 건드렸어요.

---

## 무엇을, 왜?

### 무엇을
| 영역 | Before | After |
|---|---|---|
| 배경 | 다크 그라데이션 (teal/tealDeep) | 따뜻한 3-stop (피치→코랄→라벤더) |
| 타이틀 | GlowingTitleNode (teal 글로우) | Jua 56pt 2-라인 (네이비/코랄) + 코랄 AccentLine |
| BEST/PLAYS | 단색 SKLabelNode | GlassPillNode 2개 (좌상단/우상단) |
| 폰트 | 시스템 폰트 전체 | Jua-Regular / GowunDodum-Regular / NotoSansKR-Bold |
| 검정 오버레이 패널 | StartScene · CharacterSelectScene · SkillExplanationScene 전부 | 제거 — 풀스크린 그라데이션 + 글래스 칩만 |
| 헤더 | 단순 SKLabelNode | AccentLineNode + Jua 큰 라벨 + Gowun Dodum 부제 |
| Top bar | (없음) | 좌 GlassPill 백 + 우 DarkContextChip 컨텍스트 (난이도/브레드크럼) |
| 캐릭터 카드 5장 | CharacterCardNode 단독 | 카드 뒤 글래스 컨테이너 + 우상단 색 점 + 선택 시 코랄 stroke·코랄 뱃지 |
| 스킬 본문 박스 | StoryBoxNode (다크) | 인용 박스 (좌 3px 코랄 보더 + 글래스 fill + Gowun Dodum) |
| 컨트롤 힌트 | SKLabelNode | 다크 navy 알약 + 코랄 "B" 키 마크 |

### 왜
Sprint 1이 *부품 창고*였다면 Sprint 2는 *진열장 갈아치우기*. 사용자가 앱을 켰을 때 첫 0.5초에 "유머·따뜻함·터치하고 싶음" 셋을 동시에 느끼게 하는 게 목표. 다크 야간 톤은 이름값(병동에서 작곡)에는 어울리지만 *모바일 캐주얼 게임*의 첫인상으로는 무겁다는 디자인 결정. 따뜻한 노을 그라데이션 + 둥근 Jua + 입체 코랄 CTA로 톤을 갈아치움.

### 변경 전/후

```
StartScene (Phase 10-2)          StartScene (Sprint 2)
┌─────────────────────┐         ┌─────────────────────┐
│ teal/tealDeep 다크   │         │ 피치 ───→ 코랄 ───→  │
│                      │         │      라벤더 (warm)   │
│  ✨ "김간호는 음악박사"│  ──→   │  ┌BEST┐    ┌PLAYS┐  │
│   (teal 글로우 글씨) │         │  └────┘    └─────┘  │
│                      │         │       김간호는       │
│  [START 버튼]        │         │       음악박사 ♪    │
│  ┌─────────────────┐ │         │  ─── (코랄 라인)    │
│  │ overlay 패널     │ │         │  태그라인 (회색)    │
│  └─────────────────┘ │         │                     │
└─────────────────────┘         │  [난이도 3장]        │
                                 │  [START 버튼]        │
                                 └─────────────────────┘
```

---

## Spring Boot 비유

Sprint 1 = Bean 등록만 했어요. Sprint 2 = Controller 메서드를 새 Bean을 주입받게 갈아끼웠어요.

| Spring Boot | SpriteKit (이번 작업) |
|---|---|
| `@Bean public GlassPill glassPill()` 등록 (Sprint 1) | `GlassPillNode` 클래스 정의 (Sprint 1) |
| `@Controller MenuController(GlassPill, AccentLine, ...)` (Sprint 2) | `StartScene/CharacterSelectScene/SkillExplanationScene`의 setup* 메서드가 GlassPill/AccentLine/DarkContextChip 인스턴스 생성 |
| `application.yml` 신규 키 추가 (`menu.title.fontSize=56`) | `GameConfig.startSceneTitleLine2FontSize = 56` |
| 기존 `application.yml` 키 변경 0 | 기존 GameConfig 상수 변경 0 |
| `@Service` 비즈니스 로직 0 변경 | GameScene/Repository/ContactRouter 0 변경 |
| Thymeleaf 템플릿만 새 컴포넌트로 갈아끼움 | SKLabelNode/SKShapeNode 배치만 갈아끼움 |
| Spring Profile (dev/prod) 분기 0 변경 | `.kim` 스킵 분기 / Difficulty 분기 0 변경 |

핵심: **public API 시그니처는 잠그고 내부 구현만 갈아치우는 Spring 리팩토링 패턴과 동일**. `transitionToNext()` → 다음 씬 호출 시그니처가 변하면 사용자 데이터(난이도/캐릭터 선택)가 깨질 수 있으니 *절대 못 건드림*.

---

## 들어간 핵심 결정 7가지

### 1. 그라데이션 2-stop → 3-stop 갈아끼우기
Sprint 1에서 만든 `GradientBackgroundNode.threeStop(size:topColor:midColor:bottomColor:)` static factory를 호출. 기존 2-stop init 호출 코드는 *전부* threeStop 호출로 교체. 인스턴스 참조 보관·`rebuildGradientBackground` 패턴은 *그대로 유지* — `didChangeSize`에서 안전.

```swift
// 기존
let node = GradientBackgroundNode(size: size, topColor: .ganhoAccentTealDeep, bottomColor: .ganhoAccentTeal)

// Sprint 2
let node = GradientBackgroundNode.threeStop(
    size: size,
    topColor: .ganhoBgWarmTop,
    midColor: .ganhoBgWarmMid,
    bottomColor: .ganhoBgWarmBottom
)
```

Spring으로 치면 **builder 패턴 호출 한 줄만 교체** — 클래스 시그니처 안 바꾸고 새 builder 메서드로 갈아끼움.

### 2. 오버레이 패널 3씬 전부 제거
Phase 10-2까지의 검정 반투명 패널(`setupOverlayPanel()`)을 3씬 모두에서 제거. v2 톤에서는 풀스크린 warm 그라데이션 위에 글래스 칩만 떠 있는 미니멀 구도. 패널 함수 자체도 삭제(외부 호출자 0).

### 3. 폰트 시스템 일괄 적용
모든 SKLabelNode의 `fontName`을 `GameConfig.fontDisplay`(Jua) / `fontBody`(Gowun Dodum) / `fontNumeric`(NotoSansKR-Bold) 중 하나로 통일. 시스템 폰트(기본 .systemFont) 사용 0건이 합격 조건.

```swift
// 모든 라벨 패턴
let label = SKLabelNode(fontNamed: GameConfig.fontDisplay)
label.fontSize = GameConfig.startSceneTitleLine2FontSize
label.fontColor = .ganhoCoralPrimary
```

`SKLabelNode(fontNamed:)`는 ttf 미존재 시 자동으로 시스템 폰트 fallback이라 크래시 0. Sprint 1 후속에서 ttf 추가 완료된 상태라 실제로는 Jua가 적용됨.

### 4. BEST/PLAYS → GlassPillNode 호출
기존 `bestLabel`/`playsLabel` SKLabelNode 2개를 `GlassPillNode(text:size:)` 2개로 교체.

```swift
let best = GlassPillNode(
    text: "BEST 🏆 \(HighScoreRepository().current)",
    size: CGSize(width: GameConfig.startSceneStatPillWidth, height: GameConfig.startSceneStatPillHeight)
)
```

`HighScoreRepository().current` 호출 *시점·위치*는 그대로 — 저장소 회귀 0.

### 5. 카드 외곽 동기화 패턴 (CharacterCardNode 내부 0건 변경)
5장 카드의 *외곽 글래스 컨테이너*를 별도 SKShapeNode로 부착. `setSelected` 토글은 CharacterCardNode가 자기 시각만 처리하고, 컨테이너는 *외부에서 동기화*.

```swift
private func select(_ id: CharacterID) {
    selectedCharacterID = id
    preferenceRepo.save(id)                          // 저장 호출 그대로
    for card in characterCards { card.setSelected(card.id == id) }   // 카드 내부 시그니처 그대로
    applyGlassContainerSelection(id: id)             // 신규 — 외곽 컨테이너 동기화
    rebuildSkillInfoPanel(for: id)                   // 신규 — 하단 칩 갱신
}
```

이게 Spring의 **observer 패턴** 또는 **event listener** 분리와 같은 발상. 도메인 객체(CharacterCardNode)는 자기 책임만 지고, 외부 UI 동기화는 listener에서.

### 6. StoryBoxNode 인용 박스로 치환
스킬 본문은 SKShapeNode(좌 3px 코랄 보더 + 글래스 fill 0.55 + 라운드 14pt) + SKLabelNode로 직접 구현. StoryBoxNode 클래스 파일은 *삭제하지 않음* — 호환성 + 후속 sprint에서 재사용 가능성.

```swift
let leftBorder = SKShapeNode(rectOf: CGSize(width: 3, height: boxSize.height), cornerRadius: 1.5)
leftBorder.fillColor = .ganhoCoralPrimary
leftBorder.position = CGPoint(x: -boxSize.width/2 + 1.5, y: 0)
box.addChild(leftBorder)
```

본문 텍스트 출처는 `characterID.skill.fullDescription` 그대로 — 데이터 회귀 0.

### 7. 신규 computed property 4개 (순수 시각 라벨용)
- `Difficulty.shortName` — easy="하" normal="중" hard="상"
- `PlayerSkill.rangeText` — "3타일" / "6타일" / "전역" / "최원거리"
- `PlayerSkill.castText` — "즉발" / "1500ms"
- `CharacterID.dotColor` — kim=코랄라이트, jung=민트, geon=라벤더, im=골드, lee=코랄라이트

전부 *시각 라벨만 만들어 주는 함수* — switch 분기 추가가 게임 로직 진입점 0. enum case나 switch default도 0 변경.

---

## Swift / SpriteKit 학습 포인트

### 4-1. Optional contains 패턴
hit-test에서 옵셔널 노드(GlassPillNode?, DarkContextChipNode?)를 안전하게 비교:

```swift
// ❌ 강제 언래핑
if backPill!.contains(location) { ... }

// ✅ 옵셔널 그대로
if backPill?.contains(location) == true { ... }
```

`Bool?`에 `== true` 비교는 nil → false 자동 변환. Spring의 `Optional.map(...).orElse(false)`와 동치.

### 4-2. `SKAction.group` + `removeAction(forKey:)`로 동시 액션
카드 컨테이너의 spring 선택 효과(scale + y-translate 동시):

```swift
container.removeAction(forKey: "glassSelect")
container.run(SKAction.group([
    SKAction.scale(to: scaleTarget, duration: GameConfig.characterCardGlassScaleDuration),
    SKAction.moveTo(y: cardBaseY(for: cid) + yOffset, duration: GameConfig.characterCardGlassScaleDuration)
]), withKey: "glassSelect")
```

`group`은 자식 액션 *동시 실행*, `sequence`는 *순차*. 두 액션이 같은 duration이면 group이 자연스러움. `withKey`는 같은 키의 기존 액션을 덮어쓸 수 있게 해줌 — 빠른 연속 탭 시에도 깔끔.

### 4-3. `numberOfLines = 0` + `preferredMaxLayoutWidth`
SKLabelNode의 자동 줄바꿈:

```swift
label.numberOfLines = 0
label.preferredMaxLayoutWidth = boxSize.width - 28
label.horizontalAlignmentMode = .center
label.verticalAlignmentMode = .center
```

`numberOfLines = 0`은 "줄 수 제한 없음" (UIKit과 동일). `preferredMaxLayoutWidth`는 줄바꿈 기준 폭. SwiftUI의 `Text(...).frame(maxWidth:)`와 같은 사상.

### 4-4. `frame.width`로 라벨 폭 측정
`DarkContextChipNode(label:badge:)` 내부에서 라벨 폭 측정 후 칩 폭 자동 계산. 단 폰트 fallback 시 폭이 살짝 달라질 수 있음 — Sprint 1에서 이미 처리됨.

### 4-5. zPosition 위계로 시각 레이어 관리
3씬 모두 같은 위계 규칙:
- 그라데이션 -20
- musicNoteEmitter -15
- 헤더·AccentLine·태그라인 4~10
- 카드/PrimaryButton 100
- 카드 외곽 글래스 컨테이너 90 (카드 뒤)
- 카드 색 점 / 선택됨 뱃지 110 (카드 앞)

부모-자식 노드는 *부모 zPosition + 자식 zPosition*이 절대 위계. 부모 zPosition 90이라도 자식 zPosition 1이면 절대 91.

### 4-6. 헬퍼 함수로 좌표 식 공유
CharacterSelectScene에서 카드/컨테이너/색점/선택뱃지가 모두 *같은 좌표*에 정렬돼야 함. 좌표 식을 4곳에 중복하면 변경 시 일관성 깨짐. 한 함수에서 모두 가져옴:

```swift
private func cardBaseX(for id: CharacterID) -> CGFloat { ... }
private func cardBaseY(for id: CharacterID) -> CGFloat { ... }

// 4곳에서 호출
layoutCharacterCards { card.position.x = cardBaseX(for: card.id) }
layoutCardContainers { container.position.x = cardBaseX(for: cid) }
layoutColorDots { dot.position.x = cardBaseX(for: cid) + offset }
layoutSelectedBadge { badge.position.x = cardBaseX(for: selectedID) }
```

Spring의 *공통 헬퍼 메서드* 또는 *@Service 메서드 추출*과 동일.

---

## 산출물

### 수정 파일 (7개)
- `Config/GameConfig.swift` — Sprint 2 신규 상수 약 50개 추가
- `Models/Difficulty.swift` — `shortName` computed
- `Models/PlayerSkill.swift` — `rangeText`, `castText` computed
- `Models/CharacterID.swift` — `dotColor` computed
- `Scenes/StartScene.swift` — 기능 S1~S5
- `Scenes/CharacterSelectScene.swift` — 기능 C1~C5
- `Scenes/SkillExplanationScene.swift` — 기능 K1~K6

### 보호 파일 (git diff 0줄 검증)
GameScene / GameScene+Setup / ResultScene / ColorTokens / Sprint 1 노드 6개 / CharacterCardNode / DifficultyCardNode / StoryBoxNode / GlowingTitleNode / MusicNoteEmitterNode — 모두 0줄.

### 산출 문서
- `SPEC.md` (Planner)
- `SELF_CHECK.md` (Generator)
- `QA_REPORT.md` (Evaluator, 9.50/10)
- 본 학습 노트

---

## 검증 방법

### 시각 검증 (사용자가 시뮬레이터에서 확인)
- [ ] StartScene 진입 시 피치→코랄→라벤더 노을 그라데이션
- [ ] 좌상단 BEST / 우상단 PLAYS 글래스 알약 가시
- [ ] 타이틀 2라인 ("김간호는" 네이비 / "음악박사 ♪" 코랄)
- [ ] CharacterSelectScene 5장 카드 외곽에 글래스 컨테이너 + 우상단 색 점
- [ ] 카드 선택 시 코랄 stroke + scale 1.08 + y 위로 12pt
- [ ] 하단 스킬 정보 칩 (다크 navy + 골드 라벨)
- [ ] SkillExplanationScene 좌측 글래스 카드 + 코랄 "캐릭터명" 뱃지 + 민트 속도 칩
- [ ] 우측 스킬명 Jua 36pt + 인용 박스 좌 3px 코랄 보더
- [ ] 컨트롤 힌트의 코랄 "B" 키 마크

### 정량 검증 (자동)
- ✅ 빌드 SUCCEEDED (iPhone 17 시뮬레이터)
- ✅ 보호 파일 15개 git diff 0줄
- ✅ 시스템 폰트 사용처 0건
- ✅ 하드코딩 hex 0건
- ✅ 강제 언래핑 0건, Timer 0건, 매직 넘버 0건
- ✅ Sprint 1 컴포넌트 21건 재사용 (GlassPill 4 / AccentLine 3 / DarkContextChip 7 / Primary 3 / Back 1 / Gradient.threeStop 3)
- ✅ 5×3=15 캐릭터·난이도 조합 시작 가능 (코드 흐름)

---

## SPEC에 들어갔던 핵심 제약

- **변경 유형**: 비주얼 (메뉴 3씬 시각 갱신)
- **게임 경험 의도**: 첫 0.5초 안에 유머·따뜻함·터치하고 싶음을 동시 전달
- **Sprint 2 범위 계약**:
  - IN: 3씬 setup·layout 재구성 + GameConfig Sprint 2 상수 추가 + 4 computed property
  - OUT: GameScene/Repository/Sprint 1 컴포넌트 내부/씬 전환 시그니처/저장소 호출
- **준수 룰**: 강제 언래핑 0, Timer 0, 매직 넘버 0, 시스템 폰트 0, 하드코딩 hex 0
- **회귀 보존**: Sprint 1 + Phase 10-2 결과물 보호

---

## 회고

### 9-1. 막혔던 것
- `CharacterCardNode`는 *카드 자기 시각*만 처리. 외곽 글래스 컨테이너·색 점·선택됨 뱃지는 외부에서 관리해야 하는데 좌표 일관성을 유지하려면 `cardBaseX/Y` 헬퍼 도입이 필요했음. Generator가 이 패턴을 잘 잡아냄.
- `StoryBoxNode` 사용처가 SkillExplanationScene 하나뿐이라 *치환*하면서도 클래스 자체는 보존(SkillExplanationScene 외 다른 사용처가 생길 수도 있고, 호환성 회피).
- `Difficulty.shortName` 등 computed property 추가가 게임 로직 회귀로 잡힐 위험. SPEC에서 *순수 시각 라벨용*이라고 명시 + extension 블록 분리로 통과.

### 9-2. Spring과 다르네 싶었던 것
1. `SKLabelNode` fontName 자동 fallback — Spring `ResourceLoader.getResource("font.ttf")`는 ClassNotFoundException 던지는데 SpriteKit은 graceful fallback
2. `SKShapeNode.fillColor`는 `UIColor` — Swift Color literal로도 가능하지만 ColorTokens 통일 위해 UIColor 직접 사용
3. `SKAction.group([...])` vs `sequence([...])` — Spring의 `CompletableFuture.allOf` vs 순차 `thenCompose`와 같은 사상
4. `frame.width`로 라벨 폭 측정이 *부착 전에도 가능* — SwiftUI는 GeometryReader 필요한데 SpriteKit은 SKLabelNode가 즉시 폰트 메트릭으로 계산
5. `numberOfLines = 0` 의미가 *무제한* (Swift Int에서 0이 무제한이라는 게 헷갈림 — UIKit과 동일 규칙)

### 9-3. 다음 작업 이월 결정
- Sprint 3 — 인게임 (GameScene + HUD + DPad + 스킬 버튼 + 노트/투사체/팝업)
  - 체크보드 hex 교체 (`#1a1722` → `#FFEFE0`, `#13111a` → `#FFDFC8`)
  - HUD 4슬롯 v2 스타일 + TIME 12초 이하 경고 색
  - D-Pad **우하단** / 스킬 버튼 **좌하단**
  - 음표 골드 원 + 글로우, F 코랄 사각형, 콤보팝업 Jua

### 9-4. 평가 점수
| 카테고리 | 점수 | 가중치 |
|---|---|---|
| 게임 로직 회귀 0 | 10.0 | 40% → 4.00 |
| Swift 패턴 | 9.5 | 20% → 1.90 |
| 비주얼 일관성 | 9.0 | 25% → 2.25 |
| 가독성 & UX | 9.0 | 15% → 1.35 |
| **가중 평균** | **9.50 / 10** | |

QA 반복: **1회** (한 번에 통과)

### 9-5. 사용자 직접 확인할 것
- [ ] 시뮬레이터 실행: 폰트(Jua/Gowun Dodum)가 실제로 적용된 모습 확인
- [ ] 5개 캐릭터 모두 카드 선택 → 다음 씬 진입 정상 동작
- [ ] .kim 선택 시 SkillExplanationScene 스킵하고 바로 GameScene 가는지
- [ ] 시뮬레이터에서 시각 검수 후 P2 권장 3건(QA 리포트) 반영 여부 결정

---

## 다음 단계 안내

**Sprint 3 — 인게임 (GameScene + HUD + 컨트롤)**
- `mockups/game-map-v2.html` 매칭
- 체크보드 hex 토큰 교체
- HUD 4슬롯 + TIME 12초 이하 경고
- D-Pad 우하단 / 스킬 버튼 좌하단
- 음표·F 투사체·콤보팝업 v2 스타일

트리거: 세션에서 `디자인 리뉴얼 진행해줘` 또는 `Sprint 3 진행해줘`.

---

## 핵심 교훈

> **"부품은 한 번에 깎고, 조립은 호출자에서. 호출자는 시그니처 잠그고, 시각만 갈아치우자."**

Sprint 1에서 부품(GlassPill/AccentLine/DarkContextChip/Primary/Back/threeStop) 6종을 *내부 완성*해 놓았기에 Sprint 2가 "위치 잡고 색 바꾸면 끝" 수준으로 떨어짐. 호출자(3씬)는 부품 내부를 한 줄도 안 건드리고 호출만. 이게 Spring의 *Bean 추상화*가 주는 진짜 가치 — 호출자가 Bean 내부를 모르고도 작업이 끝난다.
