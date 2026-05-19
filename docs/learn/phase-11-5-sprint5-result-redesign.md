# Phase 11-5 (Sprint 5) — 결과 화면 3분기 v2 + 졸업장 우드컷

## 한 줄 요약
**게임이 끝났을 때 보는 화면(ResultScene)을 3가지로 분기해서 갈아치웠어요.** 평소엔 따뜻한 위로, 신기록일 땐 황금 폭발과 별 파편, 졸업장 받을 땐 오래된 종이 증서. 9개 init 인자, 본문 텍스트, 햅틱·사운드·저장 한 줄도 안 건드림. 보호 파일 24개 git diff 0줄. QA 9.70/10 한 번에 통과.

---

## 무엇을, 왜?

### 무엇을
| 분기 | 조건 | 시각 변화 |
|---|---|---|
| **A. 일반** | 기본 | 카드 + 점수 코랄 + BEST 골드 칩 + 부제 "수고했어요! 한 번 더 해볼까요?" |
| **B. 신기록** | isNewBest=true | 타이틀 ✨NEW BEST✨ 골드 + 점수 골드 + BEST shimmer + **별 파편 5발** + heavy 햅틱 + NewMail 사운드 + 부제 "최고 기록을 갱신했어요!" |
| **C. 졸업장** | isNewGraduation=true | DiplomaOverlayNode 우드컷 종이(#FFF9EA) + 황토 보더 + 도트 패턴 + ㄱ자 코너 데코 + 도장(김간호 음악대학) + 명조 폰트(Gowun Batang) |

### 왜
플레이어가 게임이 끝났을 때 보는 *마지막 인상*. 일반 결과·신기록·졸업이 모두 같은 톤이면 감정 위계가 무너짐. 

- **일반**: "괜찮았어, 한 번 더?"의 따뜻한 위로 (코랄 점수)
- **신기록**: "내가 해냈다!"의 황금 폭발과 환호 (별 파편 + heavy 햅틱)
- **졸업장**: "긴 실습을 마쳤다"의 의례적 무게감 (오래된 종이 증서)

부정 단어 "GAME OVER"를 "실습 종료"로 교체 — 게임 종료가 *벌*이 아니라 *보상*으로 느껴지게.

### 변경 전/후

```
Before (v1)                       After Sprint 5 (v2)
┌─────────────────┐               ┌─────────────────┐
│ GAME OVER       │               │ 실습 종료        │ ← 타이틀 톤 교체
│                 │               │ ─── (코랄 줄)   │ ← AccentLine
│ ♪ 42           │      ──→      │ [중 · 김간호]    │ ← DarkContextChip
│ BEST 50        │               │ 수고했어요! 한…   │ ← 부제 (Gowun Dodum)
│                 │               │                  │
│ 다시            │               │ ♪ 42 (코랄)     │ ← 점수 Jua 64pt
└─────────────────┘               │ SCORE           │
                                  │ ─────────────── │ ← divider
                                  │ PLAYS  TOTAL    │ ← stats 2개
                                  │ [공유][다시 시작]│ ← 글래스+코랄
                                  └─────────────────┘

신기록 분기:                     졸업장 분기:
✨ NEW BEST ✨ (골드)              [오래된 종이 카드]
✨   ✨   ✨   ✨   ✨ (5발)        ◢━━━━━━━━━━━━◣
NEW SCORE                       ┃ Certificate of  ┃
[자랑하기][다시 시작]              ┃ Graduation     ┃
                                ┃ 실습 수료 증서  ┃
                                ┃ ...본문...      ┃
                                ┃          [도장] ┃
                                ◣━━━━━━━━━━━━◢
```

---

## Spring Boot 비유

Sprint 5는 Spring으로 치면 **"같은 Controller 메서드가 3가지 ViewName을 반환하는 패턴"** 이에요.

| Spring Boot | SpriteKit (이번 작업) |
|---|---|
| `@GetMapping("/result") public String result(@RequestParam isNewBest, @RequestParam isNewGraduation, Model model)` | `ResultScene.init(score:bestScore:isNewBest:isNewGraduation:...)` |
| `if (isNewGraduation) return "diploma";` | `if isNewGraduation { presentDiploma() }` |
| `else if (isNewBest) return "result-newbest";` | `else if isNewBest { configureNewBestLabel + scheduleNewBestReveal }` |
| `else return "result-default";` | `else { 분기 A 시각만 }` |
| Thymeleaf 3개 템플릿 (`diploma.html`, `result-newbest.html`, `result-default.html`) | 분기별 라벨 텍스트/색/sparkle 분기 |
| 9개 `@RequestParam` 시그니처 | 9개 init 인자 시그니처 |
| `@Service GraduationService.recordGraduation()` 호출 시점 | `GraduationRepository.recordGraduation()` GameScene에서 호출 (Sprint 5는 안 건드림) |
| `Model.addAttribute("name", student.getName())` | DiplomaOverlayNode body1 `{NAME}` 치환 |

핵심: **Controller 시그니처와 Service 호출 *시점*은 그대로, View 템플릿만 3개로 분기**. Sprint 5가 어렵지 않은 이유는 Sprint 1~3에서 부품 창고가 완성됐기 때문 — 새 화면을 깎는 게 아니라 기존 부품 조립 + 분기 시각만 추가.

---

## 들어간 핵심 결정 8가지

### 1. 9개 init 인자 시그니처 byte-identical
ResultScene의 init은 `size`, `score`, `bestScore`, `isNewBest`, `stats`, `characterName`, `difficulty`, `isNewGraduation`, `graduatedAt` 9개. **순서·이름·타입·default 값 한 글자도 못 바꿈**.

이유: GameScene.endGame()에서 호출하는 코드 한 줄 — `ResultScene.newResultScene(size:..., score:..., bestScore:..., ...)`. 시그니처 바뀌면 GameScene 컴파일 깨짐 = 게임 진입 불가.

Spring 비유: `@PostMapping` 메서드의 `@RequestBody DTO` 필드를 바꾸면 프론트가 보내는 JSON과 매칭 안 됨. 시그니처는 *접점*이라 *절대* 못 건드림.

### 2. 분기별 시각 변화는 *조건문*으로
같은 노드에 텍스트/색만 분기:

```swift
configureLabelV2(titleLabel,
                 text: isNewBest ? "✨ NEW BEST! ✨" : "실습 종료",
                 fontName: GameConfig.fontDisplay,
                 fontSize: GameConfig.resultTitleFontSizeV2,
                 fontColor: isNewBest ? .ganhoMusicGold : .ganhoNavyDeep)
```

분기마다 *다른 노드*를 만들지 않음 — 같은 `titleLabel` 인스턴스를 분기 조건으로 갈아끼움. 메모리/렌더 비용 0.

### 3. SparkleEffectNode 재활용 (5발 동시 발화)
SparkleEffectNode는 이미 음표 수집 시 8방 방사용으로 사용 중. **노드 내부 0건 변경**. `emit()` 호출만 5번 — 좌표는 GameConfig 상수 배열 `resultSparklePositionsV2: [CGPoint]`로.

```swift
private func emitSparkleBurst() {
    for offset in GameConfig.resultSparklePositionsV2 {
        let sparkle = SparkleEffectNode()
        sparkle.position = CGPoint(x: frame.midX + offset.x, y: frame.midY + offset.y)
        sparkle.zPosition = GameConfig.newBestZPosition + 1
        addChild(sparkle)
        sparkle.emit()
    }
}
```

SparkleEffectNode가 *자가 소멸*(emit 끝나면 removeFromParent)이라 cleanup 불필요. Spring 비유: 외부 라이브러리(Spark.emit())를 호출만 하고 라이브러리 코드는 안 건드림.

### 4. 도트 패턴 — 단일 SKShapeNode + CGMutablePath 통합
DiplomaOverlayNode 우드컷 종이 질감을 도트 1100개로 표현. 처음엔 SKShapeNode 1100개 자식으로 만들 뻔했는데 — SpriteKit이 *매 프레임 1100개 노드를 렌더*해서 FPS 60 → 30 위협.

해결: **CGMutablePath에 addEllipse를 1100회 누적**해서 *단일 SKShapeNode* 1개로 통합.

```swift
let path = CGMutablePath()
var x = -cardW/2 + step
while x < cardW/2 {
    var y = -cardH/2 + step
    while y < cardH/2 {
        path.addEllipse(in: CGRect(x: x - radius, y: y - radius,
                                    width: radius * 2, height: radius * 2))
        y += step
    }
    x += step
}
dotsPattern.path = path
```

노드 수: 1100 → 1. SpriteKit이 path를 *한 번에* GPU에 보냄. 성능 무리 0.

Spring 비유: **N+1 쿼리 문제를 1번 쿼리로 합치는 batch 패턴**. 1100번 INSERT 대신 1번 batch INSERT.

### 5. 본문 텍스트 한 글자도 변경 금지
DiplomaOverlayNode 본문:
- body1: "다사다난한 실습을 마치고 {NAME}는 드디어 졸업하였다."
- body2: "이제 세상이라는 악보 위에 마음껏 노래를 부르며 자유롭게 살 것이다."

이 텍스트는 사용자 자전적 경험(메모리 `[Game origin]`)의 핵심. 톤을 "축하 멘트"식으로 바꾸면 게임 정체성이 깨짐. 폰트만 명조(Gowun Batang)로, 색만 황토 톤으로 — **글자는 한 글자도 안 바꿈**.

`{NAME}` 치환 로직도 그대로 (`body1Template.replacingOccurrences(of: "{NAME}", with: characterName)`).

### 6. 햅틱·사운드 시퀀스 정확 보존
신기록 시 `revealNewBest()` 흐름:
1. `haptics.heavy()` ← 발화
2. `audio.play(.comboMilestoneStrong)` ← NewMail 사운드 발화
3. fade-in + scale pulse + startBestLabelGoldBlink
4. **신규: emitSparkleBurst()** ← 마지막 라인 추가

타이밍이 어긋나면 *햅틱이 시각보다 늦게* 또는 *사운드가 sparkle보다 늦게* 발화. 사용자 인지에 *반응성 저하*로 느껴짐. 따라서 sparkle은 **마지막 라인에만** 추가 — 기존 시퀀스 한 줄도 안 건드림.

### 7. fontSerif (Gowun Batang) — graceful fallback
졸업장은 명조 폰트가 분위기를 만듦. 하지만 ttf 추가는 사용자 후속 작업.

해결: `GameConfig.fontSerif = "GowunBatang-Regular"` 상수만 추가. SKLabelNode(fontNamed:)는 ttf 미존재 시 *시스템 폰트로 자동 fallback*. 크래시 0.

사용자가 후속으로:
1. https://fonts.google.com/specimen/Gowun+Batang ttf 다운로드
2. `Resources/Fonts/GowunBatang-Regular.ttf` 추가
3. Xcode add to target + Info.plist UIAppFonts 배열에 추가

Sprint 5 자체는 ttf 없이도 합격 — 시각만 시스템 폰트로 표시되지만 텍스트는 정상.

### 8. 2단계 탭 정책 정확 보존
졸업장은 *덮개*. 1번 탭하면 졸업장이 fadeOut되며 사라지고, ResultScene 카드가 노출됨. 그 카드를 다시 탭하면 StartScene으로 fade transition.

```swift
// ResultScene.touchesBegan
if children.contains(where: { $0.name == "diplomaOverlay" }) {
    return   // 졸업장이 떠 있으면 ResultScene 자신은 탭 무시
}
transitionToStart()  // 졸업장 없을 때만 1탭 → StartScene
```

이 가드를 안 두면 졸업장 + ResultScene이 *동시에 탭 이벤트*를 받아서 졸업장 dismiss + StartScene 전환이 동시에 발생 — 사용자 멘붕.

Spring 비유: **WebSecurityConfigurer의 `.antMatchers("/admin/**").authenticated()` 가드 패턴**. 특정 조건에서만 다음 처리로 넘어감.

---

## Swift / SpriteKit 학습 포인트

### 4-1. CGMutablePath addEllipse 누적
```swift
let path = CGMutablePath()
for x in 0..<rows {
    for y in 0..<cols {
        path.addEllipse(in: CGRect(x: x*step, y: y*step, width: r*2, height: r*2))
    }
}
dotsShape.path = path
```

`path.addEllipse(in:)`는 *새 sub-path*를 path에 추가. 같은 path 안에서 N개의 원형이 동시에 그려짐. SKShapeNode는 *path 자체*를 GPU에 보내므로 N개 sub-path도 1 노드 비용.

### 4-2. SKShapeNode.fillColor + strokeColor 둘 다 사용
```swift
paperCard.fillColor = .ganhoDiplomaPaper       // 채움
paperCard.strokeColor = .ganhoDiplomaBorder    // 외곽선
paperCard.lineWidth = 4                        // 외곽선 두께
```

CSS의 `background-color` + `border`와 동치. lineWidth=0이면 stroke 미표시.

### 4-3. zRotation으로 -2°/-12° 살짝 기울이기
```swift
paperCard.zRotation = -CGFloat.pi / 90   // -2° (의례적 종이의 미세한 기울임)
stamp.zRotation = -CGFloat.pi * 12 / 180 // -12° (도장의 거친 손맛)
```

`zRotation`은 라디안 단위. CGFloat.pi가 180°. -2° = -π/90. CSS의 `transform: rotate(-2deg)`와 동치.

### 4-4. `replacingOccurrences(of:with:)` 템플릿 치환
```swift
let body1 = "다사다난한 실습을 마치고 {NAME}는 드디어 졸업하였다."
    .replacingOccurrences(of: "{NAME}", with: characterName)
```

Swift String 메서드. Spring의 `MessageFormat.format` 또는 Mustache 템플릿 치환과 동치. 단순 1:1 문자열 치환.

### 4-5. SKLabelNode `preferredMaxLayoutWidth` + `numberOfLines = 0`
도장 라벨 "김간호\n음악대학"이 50pt 폭 안에서 자동 줄바꿈:
```swift
stampLabel.text = "김간호\n음악대학"
stampLabel.numberOfLines = 0
stampLabel.preferredMaxLayoutWidth = 50
```

`\n`은 명시적 줄바꿈. `numberOfLines = 0`은 무제한. `preferredMaxLayoutWidth`는 자동 줄바꿈 폭. 세 조건 다 만족해야 다줄 표시.

### 4-6. SparkleEffectNode 재활용 패턴
이미 있는 노드를 새 위치에서 instantiate + emit:
```swift
let sparkle = SparkleEffectNode()
sparkle.position = CGPoint(x: ..., y: ...)
sparkle.zPosition = ...
addChild(sparkle)
sparkle.emit()   // 내부에서 SKAction 시퀀스 → 자가 removeFromParent
```

자가 소멸 노드 패턴(`SelfDismissingNode` 변종). Spring의 *prototype scope* 빈처럼 호출할 때마다 새 인스턴스 + 작업 끝나면 GC.

---

## 산출물

### 수정 파일 (4개)
- `Config/ColorTokens.swift` — Diploma 토큰 4개 추가 (ganhoDiplomaPaper, ganhoDiplomaBorder, ganhoDiplomaTextDeep, ganhoDiplomaTextMuted)
- `Config/GameConfig.swift` — Sprint 5 신규 상수 약 25개 + fontSerif 1개
- `Scenes/ResultScene.swift` — 분기 A/B/C 시각, sparkle 5발, configureLabelV2 헬퍼
- `Nodes/DiplomaOverlayNode.swift` — 우드컷 종이 카드 + 도트 패턴 + 코너 데코 + 도장 + 명조 폰트

### 보호 파일 (24개 git diff 0줄)
GameScene / GameScene+Setup / 메뉴 3씬 / Systems / Repositories / Managers / Sprint 1 컴포넌트 6 / PauseButtonNode / SparkleEffectNode / HUDNode / DPadNode / SkillButtonNode / HUDSkillSlotNode / NoteNode / ProjectileNode / ComboPopupNode / ComboBreakNode

### 산출 문서
- `SPEC.md`, `SELF_CHECK.md`, `QA_REPORT.md` (9.70/10)
- 본 학습 노트

---

## 검증 방법

### 시각 검증 (사용자가 시뮬레이터에서)
- [ ] 분기 A — 일반 결과: 카드 + 코랄 점수 + BEST 골드 칩 + "수고했어요! 한 번 더 해볼까요?" 부제
- [ ] 분기 B — 신기록: ✨NEW BEST✨ 타이틀 + 골드 점수 + sparkle 5발 동시 + heavy 햅틱 + NewMail 사운드
- [ ] 분기 C — 졸업장: 오래된 종이 카드 + 도트 패턴 + ㄱ자 코너 + 도장 + "다사다난한 실습을 마치고…" 본문
- [ ] 2단계 탭: 졸업장 1탭 → 사라짐 → ResultScene 1탭 → StartScene
- [ ] 본문 텍스트가 한 글자도 안 바뀜
- [ ] 5×3=15 캐릭터·난이도 조합 모두 결과 화면 진입 가능

### 정량 검증 (자동)
- ✅ 빌드 SUCCEEDED
- ✅ 보호 파일 24개 git diff 0줄
- ✅ ResultScene init 9개 인자 byte-identical
- ✅ DiplomaOverlayNode 본문 텍스트 byte-identical
- ✅ haptics.heavy() / audio.play(.comboMilestoneStrong) 시퀀스 보존
- ✅ Repositories 5개 호출 위치/순서 그대로
- ✅ 강제 언래핑 0, Timer 0, 매직 넘버 0(P2 알파 리터럴 2건만), 하드코딩 hex 0(신규 4토큰만)
- ✅ 도트 패턴 단일 SKShapeNode + CGMutablePath 통합 (노드 수 1)

---

## SPEC에 들어갔던 핵심 제약

- **변경 유형**: 비주얼 (ResultScene 시각 갱신, 저장/햅틱/사운드/본문 텍스트 0 변경)
- **게임 경험 의도**: 3가지 감정(일반/신기록/졸업)을 명확히 구분되게 시각 위계 분리
- **Sprint 5 범위 계약**:
  - IN: ResultScene 분기 시각 + DiplomaOverlayNode 우드컷 + ColorTokens 토큰 4개 + GameConfig 신규 상수
  - OUT: 9개 init 인자 / 본문 텍스트 / 햅틱·사운드 시퀀스 / 2단계 탭 / Repositories / Sprint 1~3 보호 자산
- **준수 룰**: 강제 언래핑 0, Timer 0, 매직 넘버 0, 하드코딩 hex 0
- **회귀 보존**: 보호 파일 24개 git diff 0줄

---

## 회고

### 9-1. 막혔던 것
- 도트 패턴 1100개를 *어떻게 성능 안전하게 표현할지*. 처음엔 SKShapeNode 1100개 자식 생각 → 위험. 단일 SKShapeNode + CGMutablePath addEllipse로 통합.
- 분기 B `titleLabel` vs `newBestLabel` 시각 충돌. 두 라벨이 같은 위치면 가독성 깨짐. y 분리(titleLabel +70, newBestLabel +0)로 자연 분리.
- fontSerif 후속 작업 분리. Sprint 1처럼 ttf 추가는 사용자에게 안내하고, 코드 측은 상수만 + graceful fallback.

### 9-2. Spring과 다르네 싶었던 것
1. CGMutablePath addEllipse 누적 — Spring JPA에는 path 개념 없음. 그래픽 API의 *path = 여러 sub-path 묶음* 발상이 신선
2. SKShapeNode가 *path 하나만* GPU에 보내서 N개 sub-path도 1 노드 비용 — DB의 batch INSERT와 비슷한 발상
3. zRotation 라디안 단위 — CSS는 deg이라 단위 변환 필요 (CGFloat.pi / 180 * 도)
4. SparkleEffectNode 자가 소멸 패턴 — Spring의 prototype scope 빈과 다른 *호출 후 자기 자신 cleanup* 패턴
5. `replacingOccurrences(of:with:)` — String 메서드 한 줄로 템플릿 치환 가능. Spring의 MessageFormat.format보다 단순

### 9-3. 다음 작업 이월 결정
- **Sprint 4 — PNG 캐릭터 통합**: 사용자 자산 80장(5캐릭터 × 16프레임) 도착 후 시작. CHARACTER_SPRITE_PROMPT.md에 가이드 있음.
- **잔존 P2**: ResultScene 알파 리터럴 2건(0.88, 0.18) GameConfig 상수화 권장. 마이크로 폴리싱.
- **잔존 사용자 후속**: GowunBatang-Regular.ttf 추가 (졸업장 명조 폰트). 미추가 시 시스템 폰트 fallback.

### 9-4. 평가 점수
| 카테고리 | 점수 | 가중치 |
|---|---|---|
| 게임 로직 회귀 0 | 10.0 | 40% → 4.00 |
| Swift 패턴 | 9.5 | 20% → 1.90 |
| 비주얼 일관성 | 9.5 | 25% → 2.38 |
| 가독성 & UX | 9.5 | 15% → 1.43 |
| **가중 평균** | **9.70 / 10** | |

QA 반복: **1회** (한 번에 통과)

### 9-5. 사용자 직접 확인할 것
- [ ] 시뮬레이터: 일반 결과 → 분기 A 시각 정상
- [ ] 신기록 갱신 → 분기 B sparkle 5발 + heavy 햅틱 + NewMail 사운드
- [ ] 한 캐릭터로 3난이도 모두 목표 점수 달성 → 분기 C 졸업장 등장
- [ ] 졸업장 본문 텍스트 정확 (한 글자도 안 바뀜)
- [ ] 졸업장 1탭 → 사라짐, ResultScene 1탭 → StartScene
- [ ] (선택) GowunBatang-Regular.ttf 추가 후 명조 폰트 시각 확인

---

## 다음 단계 안내

**디자인 리뉴얼 전체 진행 상황**:
- Sprint 1 ✅ (9.83) — 디자인 토큰 + 노드 컴포넌트 인프라
- Sprint 2 ✅ (9.50) — 메뉴 3씬 (Start/Character/Skill)
- Sprint 3 ✅ (9.22) — 인게임 (GameScene + HUD + 컨트롤)
- Sprint 4 ⏸️ — PNG 캐릭터 통합 (자산 80장 대기 중)
- **Sprint 5 ✅ (9.70) — ResultScene 3분기 + 졸업장 우드컷** ← 본 phase

**전체 코드 작업은 완료**. Sprint 4는 사용자 외주 자산 도착 후 별도 작업.

---

## 핵심 교훈

> **"시그니처는 잠그고, 시각만 갈아치우자. 본문 텍스트는 게임 정체성이니 한 글자도 못 건드린다."**

Sprint 5의 핵심은 두 가지:
1. **9개 init 인자 + 본문 텍스트의 *byte-level 동일성***: 한 글자 차이가 게임 진입 실패 또는 정체성 훼손
2. **분기 시각은 *조건문*으로**: 같은 노드의 텍스트/색만 분기 — 새 노드 안 만듦

Spring으로 치면 **Controller 메서드는 그대로, 같은 메서드가 isNew/isGraduation 분기로 다른 View 템플릿을 반환하는 패턴**. Service/Repository는 한 줄도 안 건드리고 View만 3개로 분기. 이게 Sprint 5가 1회 통과한 이유 — *공개 API 잠그고 시각만 변경*의 정수.
