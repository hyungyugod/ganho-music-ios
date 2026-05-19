# 디자인 리뉴얼 요청서

**프로젝트**: GanhoMusic iOS · 김간호는 음악박사
**버전**: v1.0 (2026-05-19)
**변경 유형**: 비주얼 리팩토링 (게임플레이 0 회귀)
**대상 Sprint**: 4단계로 분해 (아래 §9)

---

## 0. 이 문서의 사용법

이 문서는 `.claude/agents/planner.md` 에이전트가 `SPEC.md`를 만들 때 참고하는 **자급자족 컨텍스트**다. Planner는 이 문서를 읽고:

1. 화면별 변경 사양을 SPEC.md로 정리
2. Sprint 범위 계약을 명시
3. 게임플레이 동작 불변 조건을 SPEC에 그대로 복사

Generator는 SPEC.md + 이 문서 + `mockups/` 폴더의 HTML 4개를 보고 Swift 코드를 수정한다.
Evaluator는 §11의 합격 기준으로 채점한다.

**필수 사전 작업** (Planner 호출 전):
```bash
rm -f SPEC.md SELF_CHECK.md QA_REPORT.md
```

---

## 1. 전체 컨셉

### 현재 상태 (Before)
- **비주얼 톤**: 다크 배경 (#0f0e15) + 픽셀 아트 캐릭터 (PixelSpriteRenderer)
- **UI**: 시스템 폰트, 시각 위계 약함, CTA 색 약함
- **문제**: 게임의 *유머·캐주얼* 정체성이 비주얼에서 안 드러남

### 목표 상태 (After)
- **비주얼 톤**: 따뜻한 피치-라벤더 그라데이션 + 코랄 액센트 + 일러스트 카툰
- **UI**: Jua/Gowun Dodum 폰트, 명확한 위계, 입체 코랄 CTA
- **컨셉 키워드**: "유머 + 미감 + 일관성" (브롤스타즈 카툰 톤 참고, 픽셀 아님)
- **결과**: 메인·캐릭터선택·스킬·인게임 4개 화면이 같은 디자인 시스템 공유

### 게임 경험 의도
사용자가 메인 화면을 보는 첫 0.5초에 *유머·따뜻함·터치하고 싶음* 셋을 동시에 느끼게 한다. 인게임에선 *가독성 + 폴폴폴 뛰는 캐주얼함*이 핵심.

---

## 2. 비주얼 레퍼런스 (필독)

작업 전 다음 4개 HTML 목업을 **반드시** 브라우저에서 직접 열어 시각 확인:

| 파일 | 화면 |
|---|---|
| `mockups/main-screen-v2.html` | StartScene (메인 화면) |
| `mockups/character-select-v2.html` | CharacterSelectScene (캐릭터 선택) |
| `mockups/skill-explanation-v2.html` | SkillExplanationScene (스킬 설명) |
| `mockups/game-map-v2.html` | GameScene (인게임 맵 + HUD + 컨트롤) |
| `mockups/result-screen-v2.html` | ResultScene (결과 화면 3분기: 일반·신기록·졸업장) |
| `mockups/character-concepts-v2.html` | 5명 캐릭터 사진 기반 시안 (Sprint 4 PNG 제작 베이스) |

각 목업 하단 annotation 박스에 "왜 이 결정을 했는가"가 정리돼 있다 — SPEC 작성 시 참고.

---

## 3. 디자인 시스템 (Design Tokens)

### 3.1 컬러 토큰 — `ColorTokens.swift`에 추가

`UIColor(hex:)` 헬퍼는 이미 존재. 새 토큰 15개를 기존 `extension UIColor` 안에 추가한다.

```swift
// MARK: - v2 Design System (Warm Pastel)
// 배경 그라데이션 (3-stop)
static let ganhoBgWarmTop    = UIColor(hex: "#FFE5D0")  // 피치 (상단)
static let ganhoBgWarmMid    = UIColor(hex: "#FFC8B5")  // 코랄 (중간)
static let ganhoBgWarmBottom = UIColor(hex: "#DCC9E8")  // 라벤더 (하단)
static let ganhoBgAccent1    = UIColor(hex: "#FFD9B8")  // BG 액센트 (radial)
static let ganhoBgAccent2    = UIColor(hex: "#E5C8E8")  // BG 액센트 (radial)

// Primary 액션 (코랄 패밀리)
static let ganhoCoralPrimary = UIColor(hex: "#FF6B5B")  // 메인 CTA 색
static let ganhoCoralLight   = UIColor(hex: "#FF8E80")  // 호버/포커스
static let ganhoCoralShadow  = UIColor(hex: "#C44A3D")  // 입체 그림자 베이스

// 텍스트 & 위계
static let ganhoNavyDeep     = UIColor(hex: "#2D2A4A")  // 메인 텍스트
static let ganhoNavyMuted    = UIColor(hex: "#5A5670")  // 보조 텍스트
static let ganhoMusicGold    = UIColor(hex: "#FFB347")  // 음표·HUD 라벨

// 그래픽 디테일
static let ganhoLavenderSoft = UIColor(hex: "#B89DD9")  // 라벤더 액센트 (3번째 음표 등)
static let ganhoScrubMint    = UIColor(hex: "#9BE0CC")  // 정간호 / 일부 카드
static let ganhoSkinTone     = UIColor(hex: "#FFE2C6")  // 캐릭터 피부 톤

// 체크보드 (Game floor) — 기존 다크 hex 교체
static let ganhoFloorPeachA  = UIColor(hex: "#FFEFE0")  // 체크보드 밝은 칸
static let ganhoFloorPeachB  = UIColor(hex: "#FFDFC8")  // 체크보드 어두운 칸
```

### 3.2 폰트 시스템

| 역할 | 폰트 | 사용처 |
|---|---|---|
| Display (타이틀·UI 강조) | **Jua** | 모든 타이틀, 버튼 텍스트, HUD 값 |
| Body (본문·설명) | **Gowun Dodum** | 태그라인, 스킬 설명, 카드 부제 |
| Numeric (수치 표시) | **Noto Sans KR** Bold | 점수·시간 등 정렬 필요한 숫자 |

**통합 절차** (Sprint 1에 포함):
1. Google Fonts에서 ttf 다운로드:
   - https://fonts.google.com/specimen/Jua
   - https://fonts.google.com/specimen/Gowun+Dodum
   - https://fonts.google.com/specimen/Noto+Sans+KR
2. `GanhoMusic/Resources/Fonts/` 폴더 생성 후 ttf 파일 추가
3. Xcode 프로젝트에 add to target
4. `Info.plist`에 `UIAppFonts` 배열 추가:
   ```xml
   <key>UIAppFonts</key>
   <array>
     <string>Jua-Regular.ttf</string>
     <string>GowunDodum-Regular.ttf</string>
     <string>NotoSansKR-Bold.ttf</string>
   </array>
   ```
5. `GameConfig.swift`에 폰트 이름 상수 추가:
   ```swift
   static let fontDisplay = "Jua-Regular"
   static let fontBody    = "GowunDodum-Regular"
   static let fontNumeric = "NotoSansKR-Bold"
   ```
6. 전체 `SKLabelNode`의 `fontName`을 시스템 폰트에서 위 토큰으로 교체

### 3.3 컴포넌트 패턴 (재사용 노드)

다음 4개를 새로 만들거나 기존 노드를 리스타일링:

#### A. PrimaryButtonNode (기존 리스타일링)
- 배경: `ganhoCoralPrimary`
- 외곽: 라운드 알약 (cornerRadius = height/2)
- 그림자: 6px 아래 `ganhoCoralShadow` + 12px 24px blur `ganhoCoralPrimary.40%`
- 폰트: Jua, 흰색
- 우측 끝: 작은 화살표 아이콘 (반투명 화이트 원)
- 누름 상태: translateY(+5px), 그림자 1px로 축소

#### B. GlassPillNode (새로 생성, BackButtonNode 호환)
- 배경: `UIColor.white.withAlphaComponent(0.55)`
- SKEffectNode + CIGaussianBlur radius 12 (시뮬레이터 성능 주의: iOS 13+)
- 외곽: 라운드 알약
- 폰트: Jua, `ganhoNavyDeep`
- 사용처: BackButton, 통계 칩, D-Pad 키, 난이도 칩

#### C. AccentLineNode (새로 생성)
- 길이 32 × 두께 3 SKShapeNode
- 색: `ganhoCoralPrimary`
- 라운드 끝 (cap)
- 사용처: 모든 헤더 위 시각적 강조

#### D. DarkContextChipNode (새로 생성)
- 배경: `ganhoNavyDeep.withAlphaComponent(0.92)`
- 라벨: Jua + `ganhoMusicGold`
- 옵션 뱃지: `ganhoCoralPrimary` 작은 알약
- 사용처: 난이도 표시, 브레드크럼, HUD 슬롯, 스킬명 칩

---

## 4. 화면별 변경 사양

### 4.1 StartScene (메인 화면)
**참고**: `mockups/main-screen-v2.html`

**변경 항목**:
- 배경: `ganhoBgDeep` 단색 → 3-stop 그라데이션 (`GradientBackgroundNode` 색 토큰 교체)
- 타이틀 "김간호는 음악박사": Jua 56pt + "음악박사"만 코랄
- "어느 한적한 병동의 오후" 부제 → "수간호사 몰래, 떠오른 멜로디를 45초 안에 모아 보세요" 단일 태그라인
- BEST/PLAYS 라벨 → GlassPillNode 2개 (상단 좌·우 코너)
- 시작 버튼: 신규 PrimaryButtonNode 스타일
- 캐릭터 (김간호 일러스트, "쉿" 제스처) — 화면 좌측 하단 PNG 임포트 자리 ⚠️ Sprint 4

**변경 안 할 것**:
- 시작 버튼 탭 → CharacterSelectScene 전환 로직
- BEST·PLAYS 수치 계산
- 난이도 카드 선택 로직 (StartScene에 difficulty card가 있다면)
- StoryBoxNode 사용 여부 (지금 있으면 유지하되 색·폰트만 갱신)

### 4.2 CharacterSelectScene
**참고**: `mockups/character-select-v2.html`

**변경 항목**:
- 배경: 동일 그라데이션
- 헤더: "함께할 친구를 골라요" + AccentLineNode
- 좌상단: GlassPillNode "← 난이도 다시"
- 우상단: DarkContextChipNode "현재 난이도 [중]"
- 5장 카드: 모두 글래스 카드(반투명 화이트) + 우상단 색 점 8px (캐릭터별 ColorTokens)
- 선택 상태: scale 1.08 + y-translate -12 + 코랄 stroke + 상단 "선택됨" 코랄 뱃지
- 카드 안: 캐릭터 PNG 자리 (Sprint 4) + Jua 이름 + Gowun Dodum 태그
- 하단: 스킬 정보 패널 (DarkContextChipNode 확장)
- Confirm 버튼: PrimaryButtonNode "이 친구로 시작 ▶"

**변경 안 할 것**:
- CharacterCardNode 내부 로직 (선택 상태 setter)
- preferenceRepo.current 복원/저장
- 카드 5장 가로 정렬 좌표 (시각 일관성 유지)
- transitionToNext/transitionToStart 로직

### 4.3 SkillExplanationScene
**참고**: `mockups/skill-explanation-v2.html`

**변경 항목**:
- 헤더: "스킬을 익혀요" + AccentLineNode
- 우상단: 브레드크럼 (난이도 · 캐릭터 · **스킬**) — DarkContextChipNode 다단계
- 좌측 아바타: 큰 카드 (글래스 + 코랄 보더) + 캐릭터 PNG 자리 (Sprint 4) + 속도배율 mint 칩
- 우측 스킬 영역:
  - 작은 코랄 라벨 + 스킬 메타 라벨 (예: "건간호의 스킬")
  - 큰 스킬명 (Jua 36pt, navy)
  - 인용 박스: 좌 3px 코랄 보더 + 글래스 배경 + 본문 설명
  - 메타 칩 3개: CD / 범위 / 즉발
- 하단 컨트롤 힌트: "B 좌하단 스킬 버튼을 1번 탭하면 발동" (B 키 마크)
- 하단 버튼 2개: GlassPillNode 백 + PrimaryButtonNode "시작"

**변경 안 할 것**:
- characterID·difficulty init 인자 전달
- StoryBoxNode 본문 텍스트 (`fullDescription` 사용)
- `.kim` 스킵 분기 (CharacterSelectScene에서 .kim이면 이 씬 안 거치고 GameScene 직진)

### 4.5 ResultScene (결과 화면)
**참고**: `mockups/result-screen-v2.html` — 3가지 분기 (Variant A/B/C) 한 페이지 비교

**3가지 분기 (코드의 isNewBest / isNewGraduation 플래그로 결정)**:

| 분기 | 조건 | 핵심 시각 변화 |
|---|---|---|
| A. 일반 | 기본 | 카드 + 점수 코랄 + BEST 골드 칩 |
| B. 신기록 | `isNewBest = true` | 타이틀 황금 그라데이션 + 점수 골드 + BEST shimmer 애니 + 별 파편 5개 + heavy 햅틱 + NewMail 사운드 |
| C. 졸업장 | `isNewGraduation = true` | DiplomaOverlayNode 우드컷 패턴 종이 + 한글 명조(Gowun Batang) + double-border + 도장 + 2단계 탭 |

**변경 항목**:
- 배경: 동일 그라데이션
- 중앙 카드: setupOverlayPanel() 그대로 — 색·radius만 v2 토큰 교체
- 타이틀 "GAME OVER" → **"실습 종료"** (부정 단어 회피, 따뜻한 톤)
- 점수 64pt Jua + 코랄 (`ganhoCoralPrimary`)
- BEST 라벨: 골드 칩 (정적) / shimmer (신기록 시)
- 캐릭터·난이도: DarkContextChipNode 한 줄에 통합
- 통계: PLAYS / TOTAL을 작은 stat 2개로 (Gowun Dodum 11pt)
- 분기별 부제 카피 (subtitle 라벨 신규):
  - A: "수고했어요! 한 번 더 해볼까요?"
  - B: "최고 기록을 갱신했어요!"
  - C: 본문 2줄 (DiplomaOverlayNode 코드 그대로 — `body1Label`/`body2Label` 유지)
- 버튼: 공유/자랑하기 (글래스) + 다시 시작 (코랄 primary)
- NEW BEST 시 SparkleEffectNode 5개 동시 발화
- 졸업장: DiplomaOverlayNode background를 SKShapeNode + SKShader(우드컷 패턴) 또는 PNG 텍스처 1장으로 교체. 한글 명조 폰트 적용.

**변경 안 할 것**:
- ResultScene init 9개 인자 시그니처 (`finalScore`, `bestScore`, `isNewBest`, `stats`, `characterName`, `difficulty`, `isNewGraduation`, `graduatedAt`)
- `HighScoreRepository` / `StatisticsRepository` / `PerDifficultyScoreRepository` / `GraduationRepository` 저장 로직
- heavy 햅틱 / NewMail 사운드 발화 조건
- DiplomaOverlayNode 본문 텍스트 (`"다사다난한 실습을 마치고 {NAME}는 드디어 졸업하였다."` 등)
- 졸업장 자가 소멸 패턴 (`SelfDismissingNode`)
- 2단계 탭 정책 (졸업장 닫기 → ResultScene 탭 → StartScene)
- 1탭 → StartScene fade transition (transitionToStart)

### 4.4 GameScene (인게임)
**참고**: `mockups/game-map-v2.html`

**변경 항목**:
- 배경: 동일 그라데이션 (단, 채도 살짝 낮춰 가독성 우선)
- 체크보드 hex 토큰 교체:
  - `GameConfig.checkerboardFloorAHex`: `"#1a1722"` → `"#FFEFE0"`
  - `GameConfig.checkerboardFloorBHex`: `"#13111a"` → `"#FFDFC8"`
- 외곽 벽: navy 라운드 보더 (3px stroke)
- 장식 기둥/분리벽: `ganhoNavyDeep` 라운드 사각형 + 인쇄 효과 (inset shadow)
- HUDNode:
  - 슬롯 배경 `ganhoNavyDeep.alpha(0.78)` + 라운드 14px
  - 라벨 Jua 10pt, `ganhoMusicGold`
  - 값 Jua 18pt, 흰색
  - TIME 슬롯: 12초 이하 → 슬롯 배경 `ganhoCoralShadow.alpha(0.85)`로 전환 + 진행바 추가
  - COMBO 슬롯: 콤보 ≥ 3 → 값 색 골드로 전환 (기존 로직 유지)
- 음표 (NoteNode): 골드 원 + 화이트 링 2px + 외곽 글로우 (`ganhoMusicGold.alpha(0.5)`) + 1.4s 펄스 SKAction
- F 투사체 (ProjectileNode): 코랄 라운드 사각형 22×22 + 흰 "F" 라벨 + 살짝 회전 (-12°)
- ComboPopupNode: Jua 32pt 골드 + navy 외곽선 + 살짝 회전
- D-Pad (DPadNode):
  - **위치: 우하단** ← (`mockups/game-map-v2.html` 기준 — 사용자 오른손 엄지)
  - GlassPillNode 4방향 + 중앙 데드존 다크 사각형
- 스킬 버튼 (HUDSkillSlotNode 또는 SkillButtonNode):
  - **위치: 좌하단** (`GameConfig.skillExplanationControlHintText`의 "좌하단 스킬 버튼"과 정확히 일치)
  - 큰 코랄 원형 72×72 + 우상단 "B" 키 라벨 (DarkContextChip 미니) + 아래 스킬명 칩
  - 쿨다운 중: 원형 진행 표시 (기존 cooldown logic)
- 일시정지 버튼: 우상단 작은 다크 라운드 32×32 + 흰색 ||

**변경 안 할 것** (절대 건드림 금지):
- 점수 계산 (`scorePerNote`, `scorePerNoteCombo`)
- 콤보 로직 (`comboWindow`, `comboMilestones`, `comboBreakThreshold`)
- 충돌 판정 (`PhysicsCategory`, `ContactRouter`)
- 적·투사체 행동 (EnemyNode, ProjectileNode, ProfessorNode, StoneGuardNode)
- 스킬 효과 (PlayerSkill 메타데이터 전부)
- 난이도 분기 (Difficulty enum, addNormalMap/addHardMap)
- 좌표계 (48×24 타일, tileSize=20pt, 원점 좌하단)
- 카메라 워크
- BGM/효과음 트리거

---

## 5. 파일별 변경 범위

| 파일 | 변경 유형 | 변경 안 할 것 |
|---|---|---|
| `Config/ColorTokens.swift` | 토큰 15개 **추가** (기존 토큰은 유지 — `ganhoBgDeep` 등은 호환성 위해 보존) | 기존 토큰 hex 값 |
| `Config/GameConfig.swift` | 폰트 이름 상수 3개 추가, 체크보드 hex 2개 교체 | 게임 로직 상수 (시간·점수·물리) |
| `Scenes/StartScene.swift` | 레이아웃 + 색 + 폰트 | 시작 버튼 액션, BEST/PLAYS 계산 |
| `Scenes/CharacterSelectScene.swift` | 레이아웃 + 색 + 폰트 | preferenceRepo, transition 로직 |
| `Scenes/SkillExplanationScene.swift` | 레이아웃 + 색 + 폰트 | StoryBoxNode 본문, .kim 스킵 |
| `Scenes/ResultScene.swift` | 레이아웃 + 색 + 폰트 + 분기별 부제 카피 (Sprint 5에서 작업) | 9개 init 인자, transitionToStart, 햅틱·사운드 발화 조건 |
| `Nodes/DiplomaOverlayNode.swift` | 배경 우드컷 패턴 + 한글 명조 폰트 (Sprint 5) | 본문 텍스트, 자가 소멸 패턴, 2단계 탭 정책 |
| `GameScene.swift` | HUD 위치, 컨트롤 위치 | 게임 루프, 충돌, 점수 |
| `GameScene+Setup.swift` | 체크보드 색, 벽 색 | addOuterWalls/addNormalMap/addHardMap 좌표 |
| `Nodes/HUDNode.swift` + HUDSlotNode | 슬롯 스타일 (배경·폰트·진행바) | update() 시그니처, 슬롯 4개 가로 정렬 좌표 |
| `Nodes/PrimaryButtonNode.swift` | 전체 리스타일링 | init 시그니처, 탭 콜백 |
| `Nodes/BackButtonNode.swift` | 전체 리스타일링 (GlassPillNode 패턴) | init 시그니처 |
| `Nodes/DPadNode.swift` | 위치 우하단 이동, GlassPill 4방향 스타일 | 입력 이벤트 처리 |
| `Nodes/HUDSkillSlotNode.swift` 또는 `SkillButtonNode.swift` | 좌하단 코랄 원형 스타일 + B 키 라벨 + 스킬명 칩 | 쿨다운 진행 로직, 탭 이벤트 |
| `Nodes/NoteNode.swift` | 골드 원 + 글로우 + 펄스 SKAction | 노트 자체 동작·위치 계산 |
| `Nodes/ProjectileNode.swift` | 코랄 사각형 + "F" 라벨 | 투사체 속도·각도·궤적 |
| `Nodes/ComboPopupNode.swift` + ComboBreakNode | 폰트 + 색 | 떠오름·떨어짐 거리·시간 |
| `Nodes/GradientBackgroundNode.swift` | 3-stop 그라데이션으로 갱신 | 노드 구조 |
| `Nodes/PrimaryButtonNode.swift`, `StoryBoxNode.swift`, `CharacterCardNode.swift` | 시각 갱신 | 외부 인터페이스 |
| **신규** `Nodes/GlassPillNode.swift` | 신규 생성 | — |
| **신규** `Nodes/AccentLineNode.swift` | 신규 생성 | — |
| **신규** `Nodes/DarkContextChipNode.swift` | 신규 생성 | — |
| `Nodes/PixelSpriteRenderer.swift` 등 픽셀 관련 | **Sprint 4까지 그대로** | 전체 (PNG 마이그레이션 시 별도 작업) |

---

## 6. 절대 건드리지 말 것 (Game Logic Invariants)

다음을 한 줄이라도 바꾸면 회귀 — Evaluator가 즉시 불합격 처리한다.

### 6.1 게임 수치
- `scorePerNote`, `scorePerNoteCombo`
- `comboWindow`, `comboBonusThreshold`, `comboMilestones`, `comboBreakThreshold`
- `projectileSpeed`, `projectileSize`, F 투사체 발사 주기 difficulty별 값
- `tileSize`, `mapColumns`, `mapRows`, `mapWidth`, `mapHeight`
- 게임 시간(45초), 카운트다운 시간

### 6.2 게임 로직
- `ContactRouter` 충돌 분기
- `PhysicsCategory` bitmask
- `PlayerSkill` 4 종 효과·쿨다운·duration·oncePerGame
- `Difficulty` 분기 (easy/normal/hard)
- `EnemyNode`, `ProfessorNode`, `StoneGuardNode` AI/이동 알고리즘
- `HighScoreRepository`, `StatisticsRepository`, `PerDifficultyScoreRepository`, `GraduationRepository`, `CharacterPreferenceRepository` 저장 키·구조
- 씬 전환 로직 (presentScene transitions)

### 6.3 코딩 컨벤션 (docs/swift-rules.md 준수)
- private/internal/public 가시성
- final class, struct 선택
- switch default 미사용 (exhaustive 컴파일러 검증)
- // MARK: 주석 구조

---

## 7. PNG 캐릭터 자산 통합 (Sprint 4 — 후속 작업)

이번 Sprint(1~3)에서는 PNG 캐릭터 통합을 **하지 않는다**. 다음과 같이 자리만 비워둔다:

### 7.1 임시 대응
- 픽셀 캐릭터는 그대로 사용 (PixelSpriteRenderer 유지)
- StartScene 좌측 "쉿" 김간호 일러스트 위치 → 빈 SKNode placeholder + `// TODO: PNG-MIGRATION-SPRINT-4` 주석
- CharacterSelectScene 카드 안 캐릭터 → 기존 픽셀 아바타 유지하되 카드 스타일만 갱신
- SkillExplanationScene 큰 아바타 → 기존 픽셀 7.5배 확대 유지

### 7.2 Sprint 4 들어올 때 변경할 것 (지금은 손대지 말 것)
- `PixelSprite.swift`, `PixelSpriteRenderer.swift`, `PixelPalette.swift` → deprecated 마킹 후 제거
- `Assets.xcassets`에 5명 × 16프레임 PNG 추가
- `SKTextureAtlas` 도입
- `SKAction.animate(with:timePerFrame:)` 워크/아이들 애니
- 폴폴폴 효과: `SKAction.scaleY` repeat 동시 적용
- 발 그림자: 별도 SKShapeNode

---

## 8. PNG 자산 스펙 (Sprint 4용 — 미리 캐릭터 작성자에게 전달)

| 항목 | 값 |
|---|---|
| 해상도 | 캐릭터 정면 96×144px (@1x), @2x = 192×288px, @3x = 288×432px |
| 포맷 | PNG-24 + 알파 (투명 배경) |
| 앵커 | 발 끝이 캔버스 하단 중앙, anchorPoint=(0.5, 0) |
| 프레임 | 표준 옵션: 4방향(up/down/left/right) × idle 2 + walk 2 = 16장 / 캐릭터 |
| 5명 총 | 16 × 5 = 80장 (좌우 미러로 절반 절감 시 60장) |
| 명명 | `<characterID>_<direction>_<state>_<frame>.png` 예: `kim_down_idle_1.png` |

---

## 9. Sprint 분해

### Sprint 1: 디자인 토큰 + 노드 컴포넌트 (이번 작업 1차)
**범위**: 인프라만, 시각 변화 0
- `ColorTokens.swift` 토큰 15개 추가
- 폰트 ttf 추가 + `Info.plist` + `GameConfig` 폰트 상수
- 신규 노드: `GlassPillNode`, `AccentLineNode`, `DarkContextChipNode`
- `PrimaryButtonNode`, `BackButtonNode` 리스타일링
- `GradientBackgroundNode` 3-stop 그라데이션 옵션 추가 (기존 호환)

**합격 기준**: 컴파일 + 기존 화면 시각 변화 0 + 새 노드 미리보기 가능

### Sprint 2: 메뉴 씬 3개 (이번 작업 2차)
**범위**: StartScene + CharacterSelectScene + SkillExplanationScene
- 각 씬 레이아웃을 mockup HTML에 맞춰 재구성
- 캐릭터 자리는 placeholder (Sprint 4 대기)

**합격 기준**: 4 mockup 중 3개 (메뉴) 시각 매칭 + 씬 전환 로직 0 회귀

### Sprint 3: 인게임 화면 (이번 작업 3차)
**범위**: GameScene + HUDNode + DPadNode + 스킬 버튼 + 음표/투사체/팝업
- 체크보드 hex 교체
- HUD 슬롯 새 스타일 + TIME 경고 전환 로직 추가 (12초 이하)
- D-Pad 우하단 / 스킬 버튼 좌하단 (현재 위치와 다르면 변경)
- 음표·F·콤보팝업 스타일링

**합격 기준**: `mockups/game-map-v2.html` 시각 매칭 + 게임플레이 0 회귀 (점수·콤보·충돌 단위테스트 통과)

### Sprint 4: PNG 캐릭터 마이그레이션 (이번 Sprint 범위 외)
**범위**: PixelSpriteRenderer → PNG/SKTextureAtlas
- 별도 SPEC.md로 분리
- 자산 5명 × 16 PNG 도착 후 시작

### Sprint 5: ResultScene (목업 완료 → 준비됨)
**범위**: ResultScene + DiplomaOverlayNode 3분기 v2 적용
- 참고: `mockups/result-screen-v2.html`
- ResultScene 카드·점수·BEST 시각 (Variant A/B 분기)
- DiplomaOverlayNode 우드컷 패턴 + 명조 폰트 (Variant C)
- 분기별 부제 카피 추가 (신규 SKLabelNode subtitle)
- SparkleEffectNode 5개 동시 발화 (신기록)

**합격 기준**:
- `mockups/result-screen-v2.html` 3변종 시각 매칭
- 9개 init 인자 시그니처 0 변경
- 햅틱/사운드/저장 로직 0 회귀
- 2단계 탭 정책 유지 (졸업장 → ResultScene → StartScene)

---

## 10. 하네스 실행 방법

두 가지 실행 방법이 있음.

### 10.1 자동 모드 (⭐ 추천)

Claude Code 세션에서 한 마디만 입력:

```
디자인 리뉴얼 진행해줘
```

자동으로:
1. `DESIGN_RENEWAL_STATE.md` 읽어 다음 Sprint 식별
2. 하네스 파이프라인 실행 (Planner → Generator → Evaluator)
3. 합격 시 상태 파일 자동 갱신
4. 사용자에게 결과 보고

특정 Sprint를 명시하고 싶으면:
```
Sprint 2 진행해줘
```

자세한 동작은 `CLAUDE.md` § "디자인 리뉴얼 모드" 참고.

### 10.2 수동 모드 (Sprint별 직접 호출)

자동 모드가 안 먹거나 단계별 디버깅이 필요할 때 사용. CLAUDE.md의 기본 하네스 절차를 따름.

```bash
# 단계 0: 산출물 초기화
rm -f SPEC.md SELF_CHECK.md QA_REPORT.md
```

**Planner 호출 프롬프트 템플릿** (Sprint N에 맞춰 채워서 사용):

```
.claude/agents/evaluation_criteria.md, docs/swift-rules.md,
docs/spritekit-rules.md, docs/components.md를 읽어라.

DESIGN_RENEWAL_REQUEST.md §3 (디자인 시스템) + §9 Sprint {N} 범위를 읽어라.
mockups/{관련 화면}.html을 시각 참고로 한다.
mockups/svg-exports/*.svg를 캐릭터 시안 참고로 한다.

Sprint {N} 작업 범위:
{DESIGN_RENEWAL_REQUEST.md §9 Sprint N 항목 그대로 복사}

변경 금지:
{DESIGN_RENEWAL_REQUEST.md §6 항목 그대로 복사}

SPEC.md에 반드시 포함:
1. 변경 유형: 비주얼
2. 게임 경험 의도 (2~3문장)
3. Sprint {N} 범위 계약 — 어떤 파일을 어떻게, 어떤 파일은 절대 안 건드림

결과를 SPEC.md로 저장하라.
```

**Sprint별 화면 매핑**:
- Sprint 1: 인프라만 (시각 mockup 없음)
- Sprint 2: `main-screen-v2.html` + `character-select-v2.html` + `skill-explanation-v2.html`
- Sprint 3: `game-map-v2.html`
- Sprint 4: `svg-exports/*.svg` + 사용자 제작 PNG (Assets.xcassets)
- Sprint 5: `result-screen-v2.html`

Generator·Evaluator 호출은 CLAUDE.md의 단계 2~3 그대로.

수동 모드 사용 후에는 **`DESIGN_RENEWAL_STATE.md`를 직접 갱신**해야 다음 자동 모드 실행 시 충돌이 없음.

---

## 11. 합격 기준 (Evaluator 채점)

### 11.1 게임 로직 회귀 (40%)
- §6.1, §6.2 모든 항목 0 변화 확인
- 점수·콤보·충돌 단위테스트 (있다면) 통과
- 5 캐릭터 × 3 난이도 = 15 조합 시작 가능

### 11.2 Swift 패턴 (20%)
- docs/swift-rules.md 준수
- private/internal/public 일관성
- switch default 미사용
- // MARK: 구조

### 11.3 비주얼 일관성 (25%)
- 4 mockup HTML과 시각 매칭 (캐릭터 PNG 자리 제외)
- 색 토큰 사용 (하드코딩된 hex 0)
- 폰트 시스템 적용 (시스템 폰트 사용 부분 0)
- 컴포넌트 재사용 (PrimaryButton·GlassPill 등 일관 사용)

### 11.4 가독성 & UX (15%)
- HUD가 게임플레이 가독성 방해 0
- D-Pad·스킬 버튼 터치 영역 44pt 이상
- TIME 경고 색 전환 (12초 이하)
- 화면 전환 시 깜빡임 0

---

## 12. 진행 순서 요약 (TL;DR)

1. ✅ `DESIGN_RENEWAL_REQUEST.md` (이 문서) 확인
2. ✅ `mockups/*.html` 6개 브라우저에서 시각 확인 (main / character-select / skill-explanation / game-map / result-screen / character-concepts)
3. ⏭️ **Sprint 1 하네스 시작** (위 §10 프롬프트로 Planner 호출)
4. ⏭️ Sprint 1 합격 → Sprint 2 시작
5. ⏭️ Sprint 2 합격 → Sprint 3 시작
6. ⏭️ Sprint 3 합격 → **Sprint 5 시작** (ResultScene은 PNG 의존 없음 — Sprint 4와 병렬 진행 가능)
7. ⏸️ Sprint 4 (PNG): 캐릭터 자산 80장 도착 후 (CHARACTER_SPRITE_PROMPT.md 따라 AI 외주)
8. 🎉 모든 Sprint 합격 → 배포

---

**문서 작성**: Claude (Cowork mode)
**문서 버전 관리**: 변경 시 v1.x로 patch up
**질문 발생 시**: SPEC.md에 "OPEN_QUESTION" 섹션 추가, Planner가 사용자에게 콜백
