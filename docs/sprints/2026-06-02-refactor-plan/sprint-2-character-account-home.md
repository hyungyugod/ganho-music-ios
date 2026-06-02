# Sprint 2 - Character Select -> Account Character Home

## 목표

현재 `CharacterSelectScene`을 단순 캐릭터 선택 화면에서 계정 홈/로비 화면으로 전면 재설계한다. 첨부 이미지처럼 사용자가 "내 계정과 캐릭터 상태를 보고 있다"는 느낌을 받게 하되, 모바일 landscape에서는 과밀한 아이콘 나열 대신 핵심 정보만 크게 보여준다.

## 현재 상태 요약

- `CharacterSelectScene.swift`는 중앙 카드 캐러셀, 우측 프로필 패널, 화살표, 페이지 점, 하단 다음 버튼으로 구성되어 있다.
- 캐릭터는 `CharacterFaceNode` 얼굴 중심으로 보여서 사용자가 말한 "얼굴만 있고 휑함" 문제가 있다.
- `DifficultySelectScene`과 `SkillExplanationScene`은 현재 흐름에 의존한다.
- 기록/통계 저장소는 이미 있다:
  - `StatisticsRepository`
  - `HighScoreRepository`
  - `PerDifficultyScoreRepository`
  - `GraduationRepository`
  - `AuthProfileRepository`

## 디자인 의도

캐릭터 선택 화면을 "캐릭터를 고르는 곳"에서 "내 캐릭터/계정 상태를 둘러보는 홈"으로 바꾼다. 전신 캐릭터가 첫 시선의 중심이 되고, 주변에는 프로필/업적/기록이 역할별 패널로 붙는다. 첨부 이미지의 밀도감은 참고하되, 모바일에서는 버튼과 정보가 너무 작아지지 않게 4개 영역으로 압축한다.

## 정보 구조

화면은 4개 영역으로 나눈다.

### 1. Character Stage

- 위치: 좌측 또는 중앙 좌측.
- 역할: 선택 캐릭터의 전신 프리뷰.
- 표시:
  - 전신 캐릭터
  - 캐릭터 이름
  - 스킬 이름
  - 속도 배율
  - 좌우 전환 버튼 또는 하단 캐릭터 rail

전신 이미지는 얼굴 노드가 아니라 `Characters/{id}_down_idle_1` 텍스처 또는 `PixelSpriteRenderer` fallback으로 구성한다. 정사각형 강제 스케일을 피하고 원본 비율을 유지한다.

### 2. Personal Profile

- 위치: 우측 상단 패널.
- 역할: 계정 상태와 현재 플레이어 요약.
- 표시:
  - 게스트/Apple 연동 상태
  - 총 플레이 수
  - 전체 최고 점수
  - 선택 캐릭터 최고 점수
  - 계정 관리 진입 버튼은 작게 배치하거나 Sprint 2 범위에서는 보류

Apple 로그인 계정이면 "Apple 연동됨"을 명확히 표시한다. 게스트면 "게스트 플레이"와 "Apple 연동 가능" 힌트만 짧게 표시한다.

### 3. Achievements

- 위치: 우측 중단 또는 하단의 작은 배지 영역.
- 역할: 업적/졸업장 보유 상황.
- 표시:
  - 졸업장 보유 개수
  - 캐릭터별 졸업 상태
  - 난이도 목표 달성 여부

초기 구현은 로컬 저장소 기반으로 충분하다. 서버 업적 시스템은 이 Sprint에 넣지 않는다.

### 4. Records

- 위치: 우측 하단 또는 탭 전환 패널.
- 역할: 선택 캐릭터의 난이도별 기록.
- 표시:
  - 하/중/상 최고 점수
  - 목표 점수
  - 달성/미달성 표시
  - 최근 플레이가 없으면 빈 상태 문구

## 레이아웃 제안

권장 1차 레이아웃:

```text
┌────────────────────────────────────────────────────────────┐
│  뒤로                         캐릭터 홈 / 계정 상태         │
│                                                            │
│   [전신 캐릭터 스테이지]      [개인 프로필 패널]             │
│   이름 / 스킬 / 속도          [업적 배지 3~5개]              │
│                                                            │
│   ◀ 캐릭터 rail ▶             [기록: 하/중/상 rows]          │
│                                                            │
│                         [다음]                              │
└────────────────────────────────────────────────────────────┘
```

좁은 landscape에서는 우측 패널을 세로 3단으로 작게 쌓고, 전신 캐릭터는 화면 중앙보다 약간 왼쪽에 둔다.

## UX 세부 규칙

- 첫 시선은 전신 캐릭터가 가져간다.
- 캐릭터 변경은 명확해야 한다. 좌우 화살표와 하단 작은 캐릭터 rail 중 하나를 유지한다.
- `다음` 버튼은 항상 같은 위치에 있어야 한다.
- 탭 이름은 화면에 노출할 수 있다: `캐릭터 선택`, `개인프로필`, `업적`, `기록`.
- 다만 사용법 설명 문구는 길게 넣지 않는다.
- 빈 데이터도 "휑함"으로 보이지 않게 기본 badge/row를 둔다.

## 시각 설계 상세

### 화면 위계

1. 전신 캐릭터: 가장 큰 요소. 카드 안에 가두지 않고 무대처럼 배치한다.
2. 선택/진행 버튼: 캐릭터 바로 아래 또는 하단 중앙.
3. 계정/기록 패널: 우측에 밀도 있게 배치하되, 텍스트 크기는 12pt 미만으로 내리지 않는다.
4. 보조 장식: 글래스/라인/배지 정도만 사용한다. 배경 장식은 최소화한다.

### 컬러와 톤

- 기존 warm gradient와 coral/navy 토큰은 유지한다.
- 첨부 이미지의 SF/로비 밀도감은 `패널 구조`로만 참고한다.
- 16개 이상의 작은 메뉴 아이콘을 그대로 복제하지 않는다. iPhone landscape에서는 터치가 어렵다.
- 캐릭터별 색은 `CharacterID.dotColor`, 카드/배지 stroke, record row accent에만 제한적으로 쓴다.

### 추천 노드 계층

```text
CharacterSelectScene
├── gradient background
├── top bar
│   ├── back pill
│   └── account status chip
├── character stage
│   ├── stage shadow
│   ├── CharacterPortraitNode
│   ├── selected name label
│   └── skill/speed chips
├── character rail
│   ├── left arrow
│   ├── 5 mini character buttons
│   └── right arrow
├── profile panel
├── achievement strip
├── record panel
└── confirm button
```

### Panel별 데이터 산식

| 영역 | 데이터 원천 | 산식/표시 |
|---|---|---|
| 계정 상태 | `AuthProfileRepository().current` | nil = 로컬, `isAnonymous` = 게스트, Apple provider 포함 = Apple 연동 |
| 총 플레이 | `StatisticsRepository().current.playCount` | `PLAYS n` |
| 누적 점수 | `StatisticsRepository().current.totalScore` | 프로필 보조 수치 |
| 전체 최고 | `HighScoreRepository().current` | `BEST n` |
| 선택 캐릭터 기록 | `PerDifficultyScoreRepository().best(characterID:difficulty:)` | 하/중/상 row |
| 졸업 상태 | `GraduationRepository().graduatedAt(characterID:)` | 날짜 있으면 졸업 badge |

## 구현 전략

### Phase A - 구조 정리

- `CharacterSelectScene` 내부의 기존 카드 캐러셀 중심 구조를 줄인다.
- 현재 선택 상태(`selectedCharacterID`, `currentIndex`, `preferenceRepo`)는 보존한다.
- `.kim -> DifficultySelectScene`, 그 외 `SkillExplanationScene` 분기는 보존한다.

### Phase B - 전신 프리뷰 도입

신규 노드 후보:

- `CharacterPortraitNode`
  - `CharacterID`를 받아 전신 텍스처 표시.
  - `UIImage(named: "\(id.rawValue)_down_idle_1")` 우선.
  - 없으면 `PixelSpriteRenderer` fallback.
  - `aspectFit(maxSize:)` 성격의 메서드로 비율 유지.

기존 `CharacterFullBodyNode`는 현재 "사용처 제거됨" 주석이 있고 인게임용 SKShapeNode 성격이라, 메뉴 전신 프리뷰에는 새 노드가 더 적합하다.

### Phase C - 계정/프로필 패널

신규 또는 내부 helper:

- `ProfileSummaryPanelNode`
- `AchievementStripNode`
- `RecordSummaryPanelNode`

복잡도가 커지면 한 파일에 몰아넣지 말고 Node 파일로 분리한다. 단, Sprint 2 첫 구현에서는 2~3개 노드까지만 만든다.

데이터 매핑:

- 게스트/Apple 상태: `AuthProfileRepository().current`
- 전체 플레이: `StatisticsRepository().current.playCount`
- 누적 점수: `StatisticsRepository().current.totalScore`
- 전체 최고: `HighScoreRepository().current`
- 캐릭터 x 난이도 기록: `PerDifficultyScoreRepository().best(characterID:difficulty:)`
- 졸업 상태: `GraduationRepository().graduatedAt(characterID:)`

### Phase D - 터치/상태 전환

- 좌우 화살표 탭 또는 캐릭터 rail 탭 -> `swipeTo(index:)`와 같은 단일 선택 함수로 모은다.
- 선택 변경 시:
  - preference 저장
  - 전신 프리뷰 교체
  - 프로필/업적/기록 패널 refresh
  - 다음 버튼 분기 대상 유지

터치 우선순위:

1. overlay가 있다면 overlay action.
2. back pill.
3. character rail / arrow.
4. tab 또는 profile/action chip.
5. confirm button.

### Phase E - 반응형/안전영역

- `didChangeSize`에서 모든 패널과 프리뷰를 재배치한다.
- iPhone 12/13/14/15/17 landscape 계열에서 버튼 하단 잘림이 없도록 `SceneSafeArea`를 사용한다.
- 텍스트는 패널 폭에 맞춰 줄이거나 `minimumScaleFactor`에 준하는 수동 scale을 적용한다.

### Phase F - 화면 상태

- 기본 상태: 캐릭터 선택 + 프로필/업적/기록 요약이 모두 보이는 홈.
- 데이터 없음 상태:
  - 기록 row는 `0점` 또는 `아직 기록 없음` 중 하나로 통일한다.
  - 업적은 잠긴 badge를 보여준다.
- Apple 연동 상태:
  - Apple 표시를 프로필 패널에 작게 둔다.
  - Sprint 2에서는 클라우드 sync 결과를 별도 표시하지 않는다.

## 예상 수정 파일

- `GanhoMusic/GanhoMusic Shared/Scenes/CharacterSelectScene.swift`
- `GanhoMusic/GanhoMusic Shared/Nodes/CharacterPortraitNode.swift` 신규
- `GanhoMusic/GanhoMusic Shared/Nodes/ProfileSummaryPanelNode.swift` 신규 후보
- `GanhoMusic/GanhoMusic Shared/Nodes/AchievementStripNode.swift` 신규 후보
- `GanhoMusic/GanhoMusic Shared/Nodes/RecordSummaryPanelNode.swift` 신규 후보
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`
- `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj`

## 보존해야 할 흐름

- `CharacterSelectScene.newCharacterSelectScene()` 시그니처.
- `CharacterPreferenceRepository` 저장 포맷.
- `.kim`은 스킬 설명을 스킵하고 난이도 선택으로 이동.
- 나머지 캐릭터는 스킬 설명으로 이동.
- `DifficultySelectScene.newDifficultySelectScene(characterID:)` 호출.

## 수용 기준

- 캐릭터 선택 화면에서 전신 캐릭터가 명확히 보인다.
- 화면에 `캐릭터 선택`, `개인프로필`, `업적`, `기록` 성격의 정보가 모두 있다.
- 게스트와 Apple 연동 상태가 다르게 표시된다.
- 난이도별 기록이 선택 캐릭터 기준으로 바뀐다.
- 캐릭터 변경 후 다음 화면으로 가도 선택값이 유지된다.
- 기존 스킬 설명/난이도/게임 진입 플로우가 깨지지 않는다.
- 화면이 비어 보이지 않고, 텍스트/노드 겹침이 없다.

## 리스크와 대응

- 리스크: `CharacterSelectScene.swift`가 이미 큰 파일이라 더 비대해질 수 있다.
  - 대응: 패널 노드를 별도 파일로 분리한다.
- 리스크: 첨부 이미지처럼 UI를 너무 많이 넣으면 iPhone landscape에서 작은 버튼 지옥이 된다.
  - 대응: 4개 정보 영역으로 압축하고, 탭/패널을 명확히 한다.
- 리스크: 클라우드 프로필 데이터가 아직 완성되지 않았을 수 있다.
  - 대응: Sprint 2는 로컬 저장소와 Auth snapshot 기반으로만 구현한다.
- 리스크: 전신 캐릭터 자산이 캐릭터별로 품질/비율이 다를 수 있다.
  - 대응: `aspectFit`과 fallback texture를 반드시 둔다.

## 검토 포인트

- `개인프로필/업적/기록`을 항상 동시에 보여줄지, 탭으로 전환할지 결정이 필요하다.
- 첨부 이미지의 우측 아이콘 메뉴처럼 빽빽한 느낌을 줄지, 모바일용으로 정보 패널형을 택할지 결정이 필요하다.
- 계정 관리 버튼을 Sprint 2에 포함할지, Sprint 1의 로그인 오버레이와 분리해서 후속으로 둘지 결정이 필요하다.
