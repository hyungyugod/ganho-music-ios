# Sprint 7 작업지시서 — 카드 리뉴얼 + 카운트다운 + 빌런/방향 + 하이스코어

> **트리거**: `Sprint 7 진행해줘` (CLAUDE.md 디자인 리뉴얼 모드 자동 호출)
> **DESIGN_RENEWAL_REQUEST.md / SPRINT_6_REQUEST.md 연장**. Sprint 1-6과 동일 합격 기준 + 디자인 토큰 사용.
> **단일 진실 원천** — Planner/Generator/Evaluator 모두 이 파일 기준.
> **사용자 의사결정 (2026-05-19 사전 확인)**:
> 1) 캐릭터 카드: NIKKE는 **구조만 차용** (세로 카드/등급 배지/속성 아이콘/푸바디 일러), 톤은 현재 따뜻한 피치·코랄 유지
> 2) 신규 빌런 박병장: **공군 병장 + 선글라스** 컨셉 (다른 빌런과 차별화)
> 3) 하이스코어 진입점: **결과창의 "기록 보기" 버튼**만 (메인·미니칩 진입은 후속 작업 후보)

---

## 0. 한 줄 요약

**캐릭터 선택·스킬 설명·난이도 선택 3개 메뉴 화면의 "겹침·단조로움"을 NIKKE 식 구조와 명확한 위계로 재정비하고, 결과창에서 "기록 보기" 진입점 + 신규 ScoreboardScene을 신설한다. 게임 시작 시 카운트다운 오버레이로 멈춤감을 해소하고, 빌런 4종(수간호사·이교수·석조무사·박병장 신규)과 플레이어 5명의 4방향 스프라이트 시안을 함께 정비한다.**

---

## 1. Phase 구조 (7개)

Sprint 7은 단일 사이클이 아니라 **Phase 단위 순차 실행**이다. 각 Phase가 자체 SPEC/SELF_CHECK/QA_REPORT 사이클을 가진다.

| Phase | 이름 | 화면/노드 | 신규 mockup | 평균 변경 LOC |
|---|---|---|---|---|
| **A** | 캐릭터 선택 리뉴얼 | CharacterSelectScene + CharacterCardNode | character-select-v3.html | ~300 |
| **B** | 스킬 설명 겹침 해소 | SkillExplanationScene | skill-explanation-v3.html | ~150 |
| **C** | 난이도 선택 세련화 | DifficultySelectScene + DifficultyCardNode | difficulty-select-v3.html | ~200 |
| **D** | 결과창 정리 + 기록 진입 | ResultScene + 신규 ScoreboardScene | result-screen-v3.html (수정) + highscore-board-v1.html (신규) | ~400 |
| **E** | 카운트다운 오버레이 | GameScene 시작 시퀀스 + CountdownNode 보강 | countdown-overlay-v1.html | ~100 |
| **F** | 빌런 4종 시각 리뉴얼 + 박병장 신규 | EnemyNode/ProfessorNode/StoneGuardNode + 신규 SergeantParkNode | villains-and-player-directions-v1.html (전반부) | ~500 |
| **G** | 플레이어 4방향 스프라이트 | PlayerNode + DPad 연동 | villains-and-player-directions-v1.html (후반부) | ~300 |

**총 7 Phase · 신규 mockup 6개 (+ 결과창 수정 1개) · 예상 변경 LOC 1900**

> Phase A~E는 시각/UX 변경. Phase F~G는 신규 노드 추가 — 게임 로직 회귀 0 원칙은 동일.

---

## 2. Phase A — 캐릭터 선택 리뉴얼 (NIKKE 구조)

**Mockup**: `mockups/character-select-v3.html`
**Scene**: `Scenes/CharacterSelectScene.swift`
**관련 노드**: `Nodes/CharacterCardNode.swift`, `Nodes/CharacterFaceNode.swift`

### 2.1 Before → After

| 항목 | Before (v2) | After (v3) |
|---|---|---|
| 카드 폭 | 130pt, gap 14pt → 겹침 시각 | **160pt, gap 22pt → 겹침 0** |
| 카드 비율 | 정사각 + 텍스트 | **세로 4:5 카드 (NIKKE식)** |
| 카드 안 정보 | 얼굴 + 이름 + 한 줄 태그 | 얼굴 + 이름 + **속성 헥사 아이콘** + **등급 로마숫자 배지** + **CD 미니칩** |
| 선택 상태 | scale 1.08 + translateY -12 + 코랄 stroke | 동일 + **카드 하단 코랄 글로우(radial)** + **카드 상단 "선택됨" 코랄 알약** |
| 하단 스킬 패널 | 카드 5장과 BG 충돌 | **카드 아래 명확한 여백 + 패널 자체 폭 좁히기** |
| confirm 버튼 | `이 친구로 시작` | `다음` 유지 (Sprint 6 결정) |

### 2.2 NIKKE 구조 차용 항목 (톤은 차용 X)

- 세로 카드(폭 < 높이) — 정사각이 아닌 4:5
- 카드 좌상단: **속성 헥사 아이콘**(번개·물·바람·꽃·달 — 캐릭터별 색 토큰)
- 카드 좌하단: **등급 로마숫자**(I·II·III — `CharacterID.rarity` 신규 computed)
- 카드 우상단: **CD 미니칩**(스킬 쿨다운 1회/2회/∞ — `PlayerSkill.cooldownText` 사용 가능)
- 카드 중앙 ~ 하단 70%: **얼굴 SVG 또는 PNG 자리** (Sprint 4 PNG 도착 시 교체)
- 카드 하단: **이름 라벨** + **속도배율 미니 칩**

### 2.3 변경 안 할 것

- `CharacterSelectScene.init(size:)` 시그니처 (Sprint 6에서 단순화 완료, 유지)
- `preferenceRepo.current` 복원/저장 로직
- 5장 가로 정렬 좌표 계산 함수명·시그니처 (좌표 수치만 새 폭/gap에 맞춰 갱신 OK)
- `.kim → DifficultySelectScene` / `그 외 → SkillExplanationScene` 분기
- `transitionToNext/transitionToStart` 콜백 시그니처
- 캐릭터 색 점 토큰(`CharacterID.dotColor`)

### 2.4 신규 추가 (괜찮음)

- `CharacterID.rarity: Int` (1·2·3 — 김간호=II, 이간호=I, 정간호=III 등 시각용)
- `CharacterID.elementSymbol: String` (이모지 또는 단문자 — "⚡"·"💧"·"🌿" 등) **또는** SKShapeNode 헥사 헬퍼
- `CharacterCardNode`에 `attachElementBadge()`, `attachRarityBadge()`, `attachCDChip()` 메서드
- `GameConfig`에 카드 크기 상수 4종: `characterCardWidthV3`, `characterCardHeightV3`, `characterCardGapV3`, `characterCardCornerRadiusV3`

### 2.5 합격 기준

- 시뮬레이터에서 5장 카드 시각적으로 0px 겹침
- 헥사 아이콘 5종이 캐릭터 색과 일치
- 선택 → 해제 → 다른 선택 시 시각 전환이 매끄러움 (액션 시간 0.18s 유지)
- preferenceRepo 저장값이 v2와 byte-identical (회귀 0)

---

## 3. Phase B — 스킬 설명 겹침 해소

**Mockup**: `mockups/skill-explanation-v3.html`
**Scene**: `Scenes/SkillExplanationScene.swift`

### 3.1 현재 문제 (스크린샷 기반)

- **좌상단 "← 캐릭터 다시"** GlassPill 백 버튼이 있는데, **좌측 캐릭터 카드 하단**에도 같은 라벨의 secondary 버튼이 또 있다 → 시각 충돌·중복
- 우상단 브레드크럼 칩이 본문 좌측 라벨("임간호의 스킬") 영역과 줄 충돌

### 3.2 Before → After

| 위치 | Before | After |
|---|---|---|
| 좌상단 백 버튼 | "← 캐릭터 다시" GlassPill | **유지** |
| 좌측 카드 하단 secondary 백 버튼 | "← 캐릭터 다시" | **제거** (중복) |
| 우상단 브레드크럼 | "캐릭터 · 스킬 · 난이도" 한 줄 칩 (스킬 강조) | DarkContextChipNode 3-segment 칩 — segment 사이 dot separator(•) 가독성 강화 |
| 우측 상단 라벨 "임간호 · 스킬 · 난이도 [스킬]" | 우상단 칩과 충돌 | **삭제** (브레드크럼이 이미 동일 정보 표시) |
| 우측 본문 가로폭 | 47% | **52%** (좀 더 호흡) |
| 인용 박스 좌측 코랄 보더 | 3px | **4px** (현재 너무 얇게 보임) |
| 메타 칩 3개 (CD·범위·발동) | 한 줄 가로 정렬 | 유지하되 칩 간 gap 8 → 10 |
| 하단 컨트롤 힌트 | 회색 배경에 작은 문구 | DarkContextChip으로 통일 (현재와 동일하면 유지) |
| 하단 버튼 정렬 | 백 + Primary "다음" | **유지 + 두 버튼 사이 gap 12 → 18 (탭 영역 분리)** |

### 3.3 변경 안 할 것

- `SkillExplanationScene.init(characterID:)` 시그니처 (Sprint 6 단순화 유지)
- `StoryBoxNode` `fullDescription` 본문 텍스트
- "다음" 탭 → DifficultySelectScene 전이 로직
- characterID별 스킬 메타데이터 표시 로직

### 3.4 합격 기준

- 시뮬레이터에서 "← 캐릭터 다시" 라벨이 화면에 **1개**만 보임
- 우상단 브레드크럼과 본문 라벨이 겹치지 않음
- 모든 텍스트 가독성 (라벨 vs 배경 대비비 ≥ 4.5:1)

---

## 4. Phase C — 난이도 선택 세련화

**Mockup**: `mockups/difficulty-select-v3.html`
**Scene**: `Scenes/DifficultySelectScene.swift`
**관련 노드**: `Nodes/DifficultyCardNode.swift`

### 4.1 Before → After

| 항목 | Before (v2) | After (v3) |
|---|---|---|
| 카드 3장 배경 | 모두 동일 (피치 톤) | **하=민트 그라데이션 / 중=골드 그라데이션 / 상=코랄 그라데이션** (배경 자체에 위계) |
| 카드 헤더 (하/중/상) | Jua 24pt navy | Jua **30pt** + **카드별 강조색 stroke** |
| 카드 부제 | "여유로운 실습 / 긴장의 병동 / 이교수의 청진기" | 유지 |
| 카드 보조 라벨 | "느린 템포로 패턴을 천천히 익혀요" | Gowun Dodum 11pt, 줄간격 1.4 |
| 선택 상태 | 코랄 stroke | **카드별 색 stroke + 카드 뒤 라디얼 글로우 80% blur** + 살짝 상승 -8pt |
| 미선택 카드 | 동일 명도 | **opacity 0.78** (시선이 자연스럽게 선택 카드로) |
| 좌측 미니 캐릭터+속도배율 영역 | 평범한 카드 | **글래스 카드 + 미니 얼굴 SVG + 강조된 ⚡ 속도배율 칩** |
| 시작 버튼 | PrimaryButton "시작 ▶" | **유지 + 입체 그림자 6 → 8px + glow halo 추가 (선택 시)** |

### 4.2 카드별 색 토큰 (ColorTokens에 추가)

```swift
// MARK: - Sprint 7 — Difficulty hierarchy
static let ganhoDifficultyEasyMint   = UIColor(hex: "#9BE0CC")  // 하: 민트 (기존 scrubMint 재사용 OK)
static let ganhoDifficultyEasyDeep   = UIColor(hex: "#5EBFA3")  // 하: 민트 stroke
static let ganhoDifficultyMidGold    = UIColor(hex: "#FFD27A")  // 중: 골드
static let ganhoDifficultyMidDeep    = UIColor(hex: "#E5A647")  // 중: 골드 stroke
static let ganhoDifficultyHardCoral  = UIColor(hex: "#FF6B5B")  // 상: 코랄 (기존 재사용)
static let ganhoDifficultyHardDeep   = UIColor(hex: "#C44A3D")  // 상: 코랄 stroke
```

### 4.3 변경 안 할 것

- `DifficultySelectScene.init(characterID:)` 시그니처
- 시작 탭 → GameScene(characterID:difficulty:) 전이 로직
- Difficulty enum 값/이름/시간 상수
- `preferenceRepo.lastDifficulty` 저장/복원

### 4.4 합격 기준

- 3장 카드의 시각 위계가 명확히 구분됨
- 선택 카드 vs 미선택 카드의 대비가 즉시 인지 가능 (opacity + glow 조합)
- 시작 버튼이 화면 중앙 하단에서 시선을 강하게 끌어옴

---

## 5. Phase D — 결과창 정리 + 하이스코어 화면 신설

**Mockup**: `mockups/result-screen-v3.html` (v2 수정) + `mockups/highscore-board-v1.html` (신규)
**Scene**: `Scenes/ResultScene.swift` (수정) + `Scenes/ScoreboardScene.swift` (**신규**)
**관련 노드**: 없음 (ScoreboardScene 내부에서 SKShape/SKLabel 직접 구성)

### 5.1 결과창 현재 문제 (스크린샷 기반)

- 큰 음표(♪) 아이콘 위에 "0 SCORE" + "BEST 0" 라벨이 겹쳐 보임 (시각 우선순위 모호)
- "2 공유" 칩과 "다시 시작" 버튼 사이 정보 밀도 낮음
- **하이스코어 진입점 부재** — 캐릭터·난이도별 최고기록을 볼 수 없음

### 5.2 결과창 Before → After

| 항목 | Before | After |
|---|---|---|
| ♪ 아이콘 위치 | 점수 라벨과 겹침 | **♪ 아이콘은 점수 좌측 옆에 작게** (32pt → 24pt) — 시각적으로 점수가 주인공 |
| SCORE 라벨 | 점수 우측 작게 | 점수 **아래** Gowun Dodum 11pt — 라벨이 점수를 가리지 않음 |
| BEST 칩 | 점수 아래 작게 | **점수 우측 옆** GlassPill `🏆 BEST 0` — 명확히 독립된 정보 |
| 캐릭터·난이도 라벨 | 우상단 작게 | **타이틀 "실습 종료" 위쪽** — 컨텍스트가 결과 위에 올라옴 |
| 좌측 "공유" 칩 + 카운트 | 분리됨 | 유지 |
| 우측 "다시 시작" 버튼 | 코랄 PrimaryButton | 유지 |
| **신규: "기록 보기" 칩** | — | **공유 칩 위 또는 우측에 secondary 칩**(GlassPill `📊 기록 보기`) — 탭 시 ScoreboardScene 전이 |

### 5.3 신규 ScoreboardScene 사양

```
┌───────────────────────────────────────────────┐
│ [← 결과로]                  [캐릭터별 기록] │
│                                              │
│              ─── (accent-line)              │
│            기록 보기                          │
│       캐릭터·난이도별 최고점수                │
│                                              │
│  ┌─────┬───────┬───────┬───────┐             │
│  │     │  하   │  중   │  상   │ ← 헤더 행   │
│  ├─────┼───────┼───────┼───────┤             │
│  │ 김  │  142  │  98   │   —   │             │
│  │ 이  │   —   │  76   │  120  │             │
│  │ 정  │  88   │   —   │   —   │             │
│  │ 건  │ 200★  │  150  │  60   │ ← ★=신기록  │
│  │ 임  │  120  │  95   │   —   │             │
│  └─────┴───────┴───────┴───────┘             │
│                                              │
│        총 플레이 N회 · 졸업장 N장 보유         │
└───────────────────────────────────────────────┘
```

- 좌측 행 헤더: 캐릭터별 미니 얼굴 SVG 32px (CharacterFaceNode mini factory) + 한 글자 약칭
- 상단 열 헤더: 난이도 칩 3개 (하·중·상) — Phase C와 동일 색 토큰
- 셀: Jua 18pt navy / 빈 셀 "—" Gowun Dodum 14pt 회색
- ★ 마커: 직전 게임에서 신기록 갱신한 셀에만 표시 (sessionStorage 대신 GameState `lastUpdatedScoreCellKey` 키 1회만 유지)
- 하단 stat: `StatisticsRepository.totalPlays` + `GraduationRepository.totalDiplomas`
- 좌상단 백 버튼 "← 결과로" GlassPill — ResultScene으로 복귀

### 5.4 ScoreboardScene 데이터 소스

이미 존재하는 repository를 그대로 사용 (DB·저장 변경 0):

```swift
PerDifficultyScoreRepository.shared.bestScore(for: CharacterID, difficulty: Difficulty) -> Int?
StatisticsRepository.shared.totalPlays -> Int
GraduationRepository.shared.totalDiplomas -> Int  // 만약 없으면 graduationCount 같은 이름의 기존 함수 사용
```

### 5.5 변경 안 할 것

- ResultScene 9개 init 인자 시그니처
- ResultScene → StartScene 1탭 전이 로직 (단 "기록 보기" 탭은 ScoreboardScene으로 분기 — 1탭 정책 유지)
- HighScoreRepository / StatisticsRepository / PerDifficultyScoreRepository / GraduationRepository **모든 저장·갱신 로직**
- 졸업장 분기(DiplomaOverlayNode) 시각·텍스트·자가 소멸 패턴
- 신기록 분기 sparkle 5발 / heavy 햅틱 / NewMail 사운드 발화 조건

### 5.6 합격 기준

- 결과창에서 ♪·점수·BEST·캐릭터·난이도 5개 정보 요소가 **서로 0px 겹침**
- "기록 보기" 탭 시 ScoreboardScene 0.25s fade transition
- ScoreboardScene 15셀 매트릭스의 값이 repository와 일치 (수동 unit test 1건)
- "← 결과로" 탭 시 ResultScene 원래 상태로 복귀 (재계산 0)

---

## 6. Phase E — 카운트다운 오버레이

**Mockup**: `mockups/countdown-overlay-v1.html`
**Scene**: `GameScene.swift` (시작 시퀀스만 수정)
**노드**: `Nodes/CountdownNode.swift` (이미 존재 — 보강)

### 6.1 현재 문제

- 게임 시작 시 약 1~2초간 입력이 막혀 있는데 시각 피드백 없음 → "멈춘 줄 알았다" 느낌

### 6.2 카운트다운 사양

```
GameScene.didMove(to:) 호출 후 0.0s :
  - 모든 게임 입력 비활성화 (이미 그럴 가능성 있음 — 확인 후 동일 유지)
  - CountdownNode 화면 중앙에 attach
  - dim 오버레이 (ganhoNavyDeep alpha 0.32) 전체 덮기

0.0s ~ 1.0s : "3" 표시 — scale 1.0 → 1.4 fade 0.85 → 0.0
1.0s ~ 2.0s : "2" 표시 — 동일 패턴
2.0s ~ 3.0s : "1" 표시 — 동일 패턴
3.0s ~ 3.8s : "GO!" 표시 — 코랄 색, scale 1.2 → 1.8 fade 1.0 → 0.0
3.8s ~ 4.0s : dim 페이드 아웃, 입력 활성화

총 4.0s — 너무 길면 1.0s/숫자가 아닌 0.7s/숫자로 축소 가능 (사용자 피드백 후 조정)
```

### 6.3 CountdownNode 보강 사항

- 현재 파일이 어떤 상태인지 Generator가 확인 후, 아래 메서드 추가/수정:
  - `static func bigCenter(in size: CGSize) -> CountdownNode`
  - `func start(completion: @escaping () -> Void)` — 4초 완료 시 콜백
  - dim 오버레이는 GameScene이 직접 관리 (CountdownNode는 숫자만 책임)
- 폰트: Jua 120pt navy, GO!는 Jua 140pt 코랄
- 음향: 1·2·3은 short tick, GO!는 melodic chime — 기존 AudioManager에 등록 가능한지 확인 후, 없으면 시각만 적용 (사운드 추가는 후속 작업)

### 6.4 변경 안 할 것

- 게임 루프(`update(_:)`)·물리·점수 계산
- 입력 비활성화 시간이 이미 1~2초라면 그 시간 안에 카운트다운이 완료되도록 조정 (실제 게임 시작은 카운트다운 종료 시점과 정확히 일치)

### 6.5 합격 기준

- 시뮬레이터에서 게임 시작 후 4초 안에 "3 → 2 → 1 → GO!" 4단계가 모두 보임
- GO! 종료 즉시 음표 첫 발생 (시각적으로 자연스러운 연속감)
- 카운트다운 도중 D-pad 탭은 무시됨 (입력 게이트)

---

## 7. Phase F — 빌런 4종 시각 리뉴얼 + 박병장 신규

**Mockup**: `mockups/villains-and-player-directions-v1.html` (전반부 절반)
**노드 신규**: `Nodes/SergeantParkNode.swift` (공군 병장 + 선글라스)
**노드 수정**: `Nodes/EnemyNode.swift` (수간호사) / `Nodes/ProfessorNode.swift` (이교수) / `Nodes/StoneGuardNode.swift` (석조무사)

### 7.1 4명의 빌런 시각 컨셉

| 빌런 | 컨셉 | 핵심 시각 요소 | 색 키 |
|---|---|---|---|
| 수간호사 (EnemyNode) | 김간호 등 막는 권위자 | 흰 가운 + 둥근 안경 + 짙은 머리 + 손에 차트 | `ganhoNavyDeep` 가운 stroke + 옅은 회색 BG |
| 이교수 (ProfessorNode) | 청진기 휘두르는 교수 | 흰 가운 + 갈색 머리 + 안경 + **청진기 액세서리** | 청진기 강조색 — 코랄 |
| 석조무사 (StoneGuardNode) | 돌상 — 묵직한 방패병 | 회색 돌 텍스처 + 무뚝뚝한 일자눈 + 사각 갑옷 | 무채색 그라데이션 `#A0A0A8` → `#5A5670` |
| **박병장 (SergeantParkNode 신규)** | **공군 병장 + 선글라스** | **공군 청록 군복** + **항공모자(차양)** + **검은 선글라스** + **베레모 대신 항공 캡** + 하사 계급장 (대각선 v자) | **공군 청록 `#3A6F7F`** + 선글라스 검은색 + 계급장 골드 |

### 7.2 박병장 신규 노드 사양

```swift
// Nodes/SergeantParkNode.swift
final class SergeantParkNode: SKShapeNode {
    init() {
        super.init()
        attachBody()       // 공군 청록 군복 사각 몸통
        attachHead()       // 살구색 얼굴 둥근
        attachCap()        // 항공 캡 (앞창이 있는 모자) 청록
        attachSunglasses() // 가로로 긴 검은 선글라스 (눈 영역 전체 덮음)
        attachRank()       // 우측 어깨에 골드 v자 2개 (병장)
        attachShadow()     // 발 밑 타원 그림자
    }
    // 게임 행동은 ProfessorNode 패턴 참고 — Phase F는 시각만, 행동은 후속 Phase 후보
}
```

박병장은 **Phase F 단계에서는 시각만** 정비. 게임 안 등장 로직 추가는 **이번 Sprint 7에서 제외** — 시각 시안 + 노드 클래스 자체만 준비. 추후 Sprint 8에서 GameScene addHardMap에 spawn 로직 추가 가능.

### 7.3 변경 안 할 것

- EnemyNode/ProfessorNode/StoneGuardNode의 **모든 동작 로직** (AI, 이동, 충돌)
- `PhysicsCategory` 비트마스크
- 적 spawn 로직 (`addNormalMap`/`addHardMap`)

### 7.4 합격 기준

- 4명 빌런이 시각적으로 즉시 식별 가능 (5초 안에 누가 누군지 인지)
- 박병장 노드가 컴파일 OK + 단독 mockup 화면에서 그려짐
- 기존 3종 빌런의 hitbox·이동 패턴이 byte-identical

---

## 8. Phase G — 플레이어 4방향 스프라이트

**Mockup**: `mockups/villains-and-player-directions-v1.html` (후반부 절반)
**노드**: `Nodes/PlayerNode.swift` (수정) + `Nodes/CharacterFaceNode.swift` (참고)
**관련**: `Nodes/DPadNode.swift` (입력 방향 → 스프라이트 전환 트리거)

### 8.1 현재 상태

- PlayerNode가 정면 1방향만 렌더링 (CharacterFaceNode SVG 정면 path 사용 추정)

### 8.2 After 사양

- 캐릭터 5명 각각 4방향(front/back/left/right) SVG path 시안 → SKShapeNode child 4종을 미리 부착 + isHidden으로 전환
- DPadNode가 방향 입력을 PlayerNode에 전달할 때 `PlayerNode.facing(_ direction: Direction)` 메서드 호출
- 방향별 차이는 **머리 회전 + 헤어 흐름 + 청진기/뱃지 위치**만 다르게 (몸통 코드는 공유)
- left/right는 mirroring(scaleX = -1)로 한 쪽만 작성 후 반전

### 8.3 Direction enum

```swift
enum Direction: String {
    case front, back, left, right
}

extension PlayerNode {
    func facing(_ direction: Direction) {
        // 4개 child 노드 isHidden 토글
    }
}
```

### 8.4 변경 안 할 것

- PlayerNode 이동 로직 (`update(_:)` 안의 velocity·position 계산)
- 충돌 hitbox 좌표·크기
- 캐릭터별 스킬 발동 로직
- DPad → velocity 입력 매핑 (Direction 변환은 추가 layer일 뿐)

### 8.5 합격 기준

- D-pad 방향 입력 시 0.05s 안에 스프라이트가 해당 방향으로 전환
- 4방향 시각이 서로 명확히 구분됨
- 정지 상태에서는 최근 방향 유지 (front 강제 X)

---

## 9. 파일별 변경 범위 종합

| 파일 | Phase | 변경 유형 |
|---|---|---|
| `Config/ColorTokens.swift` | C, F | 토큰 6개 추가 (난이도 색 6 + 박병장 청록 1) |
| `Config/GameConfig.swift` | A, C, E | 카드/카운트다운 상수 ~15개 추가 |
| `Scenes/CharacterSelectScene.swift` | A | 카드 폭/gap/속성 배지 부착 호출 |
| `Scenes/SkillExplanationScene.swift` | B | 중복 백 버튼 제거 + 우상단 라벨 삭제 + 본문 폭 조정 |
| `Scenes/DifficultySelectScene.swift` | C | 카드별 색 분기 + 글로우 + opacity 처리 |
| `Scenes/ResultScene.swift` | D | 레이아웃 재정렬 + "기록 보기" 칩 추가 + 탭 시 ScoreboardScene 전이 |
| `Scenes/ScoreboardScene.swift` | D | **신규 파일** (~400 LOC 추정) |
| `GameScene.swift` | E | 시작 시퀀스에 CountdownNode attach + 콜백으로 입력 활성화 |
| `Nodes/CharacterCardNode.swift` | A | 카드 폭/높이/속성 배지/등급/CD 칩 부착 |
| `Nodes/CharacterFaceNode.swift` | A, G | mini factory (Scoreboard용 32px) + 4방향 path child |
| `Nodes/DifficultyCardNode.swift` | C | 색 토큰 분기 + 글로우 |
| `Nodes/CountdownNode.swift` | E | bigCenter factory + start(completion:) 보강 |
| `Nodes/EnemyNode.swift` | F | 수간호사 시각 리뉴얼 |
| `Nodes/ProfessorNode.swift` | F | 이교수 시각 리뉴얼 |
| `Nodes/StoneGuardNode.swift` | F | 석조무사 시각 리뉴얼 |
| `Nodes/SergeantParkNode.swift` | F | **신규 파일** (박병장 — 공군 + 선글라스) |
| `Nodes/PlayerNode.swift` | G | 4방향 child + facing(_:) 메서드 |
| `Nodes/DPadNode.swift` | G | 방향 입력 시 player.facing(_:) 호출 (입력 로직은 byte-identical) |

---

## 10. 디자인 토큰 추가 (ColorTokens.swift)

```swift
// MARK: - Sprint 7 — Difficulty hierarchy & new villain
static let ganhoDifficultyEasyMint   = UIColor(hex: "#9BE0CC")  // 하: 민트
static let ganhoDifficultyEasyDeep   = UIColor(hex: "#5EBFA3")  // 하: 민트 stroke
static let ganhoDifficultyMidGold    = UIColor(hex: "#FFD27A")  // 중: 골드
static let ganhoDifficultyMidDeep    = UIColor(hex: "#E5A647")  // 중: 골드 stroke
static let ganhoDifficultyHardCoral  = UIColor(hex: "#FF6B5B")  // 상: 코랄
static let ganhoDifficultyHardDeep   = UIColor(hex: "#C44A3D")  // 상: 코랄 stroke
static let ganhoAirforceTeal         = UIColor(hex: "#3A6F7F")  // 박병장 공군 청록
static let ganhoAirforceTealLight    = UIColor(hex: "#5A8F9F")  // 박병장 모자 하이라이트
static let ganhoSunglassesBlack      = UIColor(hex: "#1A1A1A")  // 박병장 선글라스
```

---

## 11. 합격 기준 (Sprint 7 전체)

기존 Sprint 1~6과 동일 4-카테고리 가중 평균 7.5 이상.

| 카테고리 | 가중치 | Sprint 7 추가 통과선 |
|---|---|---|
| 게임 로직 회귀 0 | 40% | 9.0 이상 (절대 회귀 0) — 7개 Phase 모두 |
| Swift 패턴 (rules 준수) | 20% | 7.0 이상 — 신규 노드 2종(SergeantPark, ScoreboardScene)도 동일 |
| 비주얼 일관성 (mockup 매칭) | 25% | 7.0 이상 — 7개 mockup 매칭률 ≥ 85% |
| 가독성 & UX | 15% | 7.0 이상 — 겹침 항목(캐릭터 카드/스킬 백버튼/결과창 정보)이 시각적으로 0px 충돌 |

**Phase 단위 점수**가 모두 7.5 이상이어야 Sprint 7 합격. 한 Phase라도 미달 시 해당 Phase만 재실행 (최대 3회).

---

## 12. 신규 mockup 파일 목록

작업 전 모두 브라우저에서 시각 확인 가능해야 한다.

| 파일 | Phase | 용도 |
|---|---|---|
| `mockups/character-select-v3.html` | A | NIKKE 구조 5장 카드 |
| `mockups/skill-explanation-v3.html` | B | 백버튼·라벨 정리 |
| `mockups/difficulty-select-v3.html` | C | 카드별 색 위계 |
| `mockups/result-screen-v3.html` | D | 정보 분리 + 기록 진입 칩 |
| `mockups/highscore-board-v1.html` | D | 5×3 매트릭스 |
| `mockups/countdown-overlay-v1.html` | E | 3·2·1·GO! 시퀀스 |
| `mockups/villains-and-player-directions-v1.html` | F + G | 빌런 4명 + 플레이어 5명 4방향 |

---

## 13. Phase 실행 순서 (의존성)

```
A → B → C  (메뉴 3씬 — 독립)
        ↓
        D  (결과창은 메뉴 톤 확정 후)
        ↓
        E  (카운트다운은 GameScene 진입 직후 시점)
        ↓
        F → G  (빌런·플레이어 — 게임 로직 안 건드리므로 후순위)
```

Phase A·B·C는 병렬 실행 가능하지만, 하네스 안정성을 위해 순차 실행 권장.

---

## 14. 사용자 후속 작업 (Sprint 7 종료 후)

- 박병장을 실제 GameScene에 spawn (Sprint 8 후보)
- 카운트다운 사운드 등록 (`AudioManager` 신규 키 2종)
- ScoreboardScene 진입 패턴 확장 — 메인 화면 트로피 아이콘에서도 진입 가능하게? (사용자 결정 필요)
- 캐릭터 4방향 시안을 실제 PNG로 (Sprint 4 PNG 자산 도착 시 — 16프레임 × 5명 × 4방향)

---

## 15. 실행 트리거

```
Sprint 7 진행해줘
```

하네스가:
1. DESIGN_RENEWAL_STATE.md 읽어 현재 Phase 확인
2. Phase A부터 (또는 이전 합격 Phase 다음부터) Planner 호출
3. SPEC.md 작성 → Generator → Evaluator (최대 3회)
4. Phase 합격 시 DESIGN_RENEWAL_STATE.md 갱신 → 다음 Phase로
5. Phase G까지 완료 시 Sprint 7 전체 합격

특정 Phase만 실행:
```
Sprint 7 Phase A 진행해줘
```

---

**작성일**: 2026-05-19
**작성자**: 디자인 리뉴얼 하네스 사전 준비 (사용자 의사결정 3개 반영 완료)
