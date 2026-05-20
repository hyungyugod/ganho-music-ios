# Sprint 8 작업지시서 — 겹침 해소 + 카운트다운 가시화 + 빌런/비행기/플레이어 인게임 완성

> **트리거**: `Sprint 8 진행해줘` (CLAUDE.md 디자인 리뉴얼 모드 자동 호출)
> **SPRINT_7_REQUEST.md 연장**. Sprint 1~7과 동일 4-카테고리 합격 기준 + 디자인 토큰 사용.
> **단일 진실 원천** — Planner/Generator/Evaluator 모두 이 파일 기준.
> **사용자 의사결정 (2026-05-20 사전 확인)**:
> 1) 캐릭터 선택: **카드 5장 가로 페이지 스와이프**(한 번에 1~2장만 보임) — 화면 폭 초과 잘림 해소
> 2) 캐릭터 시각의 **2계층 분리**: **선택 화면 = 얼굴만**(CharacterFaceNode 현행 유지) · **인게임 = 풀바디**(어깨/팔/다리 모두 있는 새 노드) — 두 컨텍스트가 다른 비주얼 자산을 사용
> 3) 풀바디 마스터 레퍼런스: **NurseAvatarNode**(김간호 메인화면용, 이미 SKShapeNode로 shoulders/collar/neck/head/bangs/cap/headphones/arm 풀바디 구현). 이 패턴을 5명 캐릭터 × 4방향(front/back/left/right)으로 확장
> 4) 박병장 데뷔: **GameScene 등장 + 등장 컷씬**(얼굴 클로즈업 + "박병장 등장!" 토스트)
> 5) 빌런 3종(수간호사/이교수/석조무사)은 **PixelSprite를 숨기고 Phase F 시각 자식을 주 비주얼로**(현재 PixelSprite가 시각 자식을 덮음)

---

## 0. 한 줄 요약

**Sprint 7 합격 후에도 실기에서 드러난 7건의 UI/인게임 결함(스코어보드 겹침·캐릭터 카드 잘림·스킬 힌트·시작 버튼 붙음·난이도 카드 좁음·카운트다운 미표시·HUD 좌하단 충돌·빌런 픽셀 잔존·박병장 미등장·비행기 퀄리티·플레이어 팔다리 부재·좌우 동일)을 7개 Phase에 1:1 매핑해 한 번에 정리한다. 게임 로직 회귀 0 원칙 유지.**

---

## 1. Phase 구조 (7개)

Sprint 8은 Sprint 7과 동일한 **Phase 단위 순차 실행**. 각 Phase가 자체 SPEC/SELF_CHECK/QA_REPORT 사이클을 가진다.

| Phase | 이름 | 화면/노드 | 신규 mockup | 평균 변경 LOC |
|---|---|---|---|---|
| **A** | 스코어보드 겹침 해소 | ScoreboardScene | scoreboard-v2.html | ~200 |
| **B** | 캐릭터 선택 스와이프 페이지 | CharacterSelectScene + CharacterCardNode | character-select-v4.html | ~350 |
| **C** | 스킬 설명 하단 힌트 ↔ 시작 버튼 분리 | SkillExplanationScene | skill-explanation-v4.html | ~100 |
| **D** | 난이도 카드 크기·여백 확대 | DifficultySelectScene + DifficultyCardNode | difficulty-select-v4.html | ~150 |
| **E** | 카운트다운 표시 버그 수정 | GameScene 시작 시퀀스 + CountdownNode | (mockup 없음 — Phase 7-E 재사용) | ~80 |
| **F** | 인게임 HUD/스킬 영역 zPos·레이아웃 정리 | GameScene+Setup + HUDNode + SkillButtonNode + HUDSkillSlotNode | hud-zorder-v1.html | ~250 |
| **G** | 빌런 가시화 + 박병장 데뷔 + 비행기 퀄리티 + 플레이어 팔다리·좌우 | EnemyNode/ProfessorNode/StoneGuardNode/SergeantParkNode + AirplaneNode + PlayerNode + GameScene+Setup | villains-and-player-v2.html | ~600 |

**총 7 Phase · 신규 mockup 6개 · 예상 변경 LOC 1730**

> Phase A~D는 시각/UX 정리. Phase E는 가시성 버그 fix. Phase F는 인게임 레이어 정리. Phase G는 인게임 시각 4종 통합 — 게임 로직 회귀 0 원칙은 동일.

---

## 2. Phase A — 스코어보드 겹침 해소

**Mockup**: `mockups/scoreboard-v2.html` (신규)
**Scene**: `Scenes/ScoreboardScene.swift`

### 2.1 현재 문제 (스크린샷 1 기반)

- **"기록 보기" 타이틀**과 그 위에 있는 **"하/중/상" 열 헤더**가 세로로 겹침
- 우측 **"캐릭터별 기록"** GlassPill이 매트릭스 첫 행과 가로로 겹침
- 행 헤더(캐릭터 얼굴)는 잘 보이지만 점수 셀이 헤더와 너무 가까움
- 정보 위계가 모호 (제목 ↔ 헤더 ↔ 본문 매트릭스가 한 덩어리로 뭉침)

### 2.2 Before → After

| 항목 | Before | After |
|---|---|---|
| 타이틀 "기록 보기" Y | 매트릭스 상단과 충돌 | **타이틀 zone Y +40pt 상향** (matrix top - 80pt 이상 여백 확보) |
| 우상단 GlassPill "캐릭터별 기록" | 매트릭스 첫 행과 가로 충돌 | **타이틀 영역과 같은 행 Y로 정렬** (matrix Y bound 위로 분리) |
| 열 헤더(하/중/상) | 타이틀 바로 아래 옴 | **AccentLine 위에 분리** + 헤더 자체 fontSize 14 → 16 |
| AccentLine 위치 | 타이틀 바로 아래 | **타이틀과 헤더 사이**로 이동 (시각적 구분선 역할 회복) |
| 매트릭스 첫 행 Y | 헤더 직하 | **헤더 - 18pt gap** (현재 추정 6~8pt) |
| 셀 간 vertical pitch | 30pt | **38pt** (행 사이 호흡) |
| 하단 stat "총 플레이 N회" | 매트릭스 마지막 행에 너무 가까움 | **매트릭스 bottom + 24pt gap** |

### 2.3 변경 안 할 것

- ScoreboardScene `init(returnContext:)` 시그니처
- `PerDifficultyScoreRepository` / `StatisticsRepository` / `GraduationRepository` 읽기 호출 시그니처
- 좌상단 "← 결과로" GlassPill 시그니처
- 매트릭스 15셀 데이터 매핑 알고리즘 (Y 좌표만 갱신)
- `lastUpdatedScoreCellKey` ★ 마커 판정 로직

### 2.4 합격 기준

- 시뮬레이터에서 **타이틀·열헤더·우상단 칩·매트릭스 첫 행**이 서로 0px 겹침
- AccentLine이 타이틀과 헤더 사이에서 시각적 구분선으로 작동
- "총 플레이" stat이 매트릭스와 24pt 이상 떨어짐

---

## 3. Phase B — 캐릭터 선택 스와이프 페이지

**Mockup**: `mockups/character-select-v4.html` (신규)
**Scene**: `Scenes/CharacterSelectScene.swift`
**관련 노드**: `Nodes/CharacterCardNode.swift`

### 3.1 현재 문제 (스크린샷 2 기반, Phase 7-A 잔존 P2 #2 인용)

- 카드 5장 합산 폭 912pt가 iPhone 12 Pro 가로 844pt 초과 → **양 끝 카드가 화면 밖으로 잘림**
- 카드가 뒤 헤더 문구("함께할 친구를 골라요" / "친구마다 다른 스킬과 이동속도를 가져요")와 시각적으로 겹침
- Phase 7-A에서 카드 사이즈가 커진 부작용 — *모든 카드를 동시에 보여주는 패턴* 자체가 한계

### 3.2 새 패턴 — 가로 스와이프 페이지

```
화면 가로 = 100%
[ ←   prev   ]  ┃  [   CENTER 카드   ]  ┃  [   next   → ]
                ↑              ↑              ↑
            좌측 25% prev      중앙 50%        우측 25% next
            (반쯤 보임)         (선택 후보)       (반쯤 보임)
```

- 한 번에 **중앙 1장 + 양옆 반쯤 보이는 2장 = 시각 3장** 노출
- 좌우 스와이프 또는 좌우 탭으로 다음/이전 카드로 이동
- 중앙 카드가 자동 "선택 후보" 상태 (Phase 7-A의 selected 비주얼 재사용 — glow + 알약 + scale 1.08)
- 양옆 카드는 opacity 0.55 + scale 0.85 (시선 분산 차단)
- **"다음" 버튼은 현재 중앙 카드 = 선택 캐릭터로 확정**

### 3.3 입력 처리

```swift
// CharacterSelectScene에 추가
private var currentIndex: Int = 2  // 5명 기본 중앙 = 김간호 인덱스
private let characters: [CharacterID] = CharacterID.allCases  // 기존 순서 보존

override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    // 기존 ← 메인 / 다음 버튼 처리 보존
    // 추가: 양옆 카드 탭 → swipeTo(index:)
}

override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    // dx 누적 → 40pt 이상이면 swipeTo(index ± 1) 트리거
}

private func swipeTo(index: Int) {
    let clamped = max(0, min(characters.count - 1, index))
    currentIndex = clamped
    layoutCards()  // 5장의 위치/스케일/alpha 재계산
    preferenceRepo.current = characters[clamped]
}
```

### 3.4 헤더 분리 강제

- 헤더 영역 Y bound = scene.height × 0.80 ~ 0.95 (상단 20%)
- 카드 영역 Y bound = scene.height × 0.30 ~ 0.78 (중간)
- 헤더 ↔ 카드 사이에 최소 **40pt safe gap** — 어떤 카드도 침범 금지
- 카드 중앙 정렬 Y = scene.height × 0.50 (Phase 7-A보다 살짝 아래)

### 3.5 변경 안 할 것

- `CharacterSelectScene.init(size:)` 시그니처
- `preferenceRepo.current` 저장/복원 로직 (현재 인덱스에서 byte-identical)
- 카드 5장 시각 컴포넌트 (헥사 / 등급 / CD / **얼굴** / 이름 / 속도 칩 — Phase 7-A 결과물)
- **CharacterFaceNode "얼굴만" 정체성** — 캐릭터 선택은 *얼굴 표정·헤어로 식별*이 목적이라 풀바디 불필요. **카드에 팔다리 추가하지 말 것** (Phase G에서 인게임 풀바디 노드를 별도로 신설)
- `.kim → DifficultySelectScene` / `그 외 → SkillExplanationScene` "다음" 분기 콜백
- CharacterCardNode 내부 attach* 메서드 시그니처

### 3.6 합격 기준

- iPhone 12 Pro / 17 Pro 가로에서 **어느 카드도 화면 밖으로 잘리지 않음**
- 어느 카드도 헤더 문구와 0px 겹침
- 스와이프 또는 양옆 탭으로 5장 순환 가능
- "다음" 탭 시 현재 중앙 카드의 ID가 다음 씬에 그대로 전달됨 (preferenceRepo 회귀 0)

---

## 4. Phase C — 스킬 설명 하단 힌트 ↔ 시작 버튼 분리

**Mockup**: `mockups/skill-explanation-v4.html` (신규)
**Scene**: `Scenes/SkillExplanationScene.swift`

### 4.1 현재 문제 (스크린샷 3 기반)

- 우측 본문 하단 DarkContextChip "좌하단 스킬 버튼을 1번 탭하면 발동"이 **PrimaryButton "다음 ▶" 위에 거의 붙어 있음**
- 시각적으로 두 요소가 한 덩어리로 인식 → 사용자가 "다음"이 어디부터 어디까지인지 모호

### 4.2 Before → After

| 항목 | Before (v3) | After (v4) |
|---|---|---|
| Hint chip → Next button 세로 gap | ~12pt (`bottomButtonGapV3=18`이지만 실측 좁음) | **28pt** (`bottomButtonGapV4=28`) |
| Hint chip Y 위치 | 다음 버튼 바로 위 | **다음 버튼 - 28pt 위로 상향** |
| 다음 버튼 자체 위치 | 화면 하단 -56pt | **유지** (힌트만 위로 옴) |
| 힌트 chip vertical padding | 6pt | **8pt** (탭 영역 확장) |

### 4.3 변경 안 할 것

- SkillExplanationScene `init(characterID:)` 시그니처
- `StoryBoxNode` 본문 텍스트
- "다음" 탭 → DifficultySelectScene 전이 로직
- characterID별 스킬 메타데이터 표시 로직
- Phase 7-B에서 제거된 secondary 백버튼/우상단 라벨은 **계속 제거 상태 유지**

### 4.4 합격 기준

- 힌트 chip과 시작 버튼 사이 **28pt 이상 빈 공간**
- 탭 영역이 서로 안 겹침 (탭 정확도)
- 우상단 브레드크럼·좌상단 백버튼·인용 박스 모두 Phase 7-B 합격 상태 유지 (회귀 0)

---

## 5. Phase D — 난이도 카드 크기·여백 확대

**Mockup**: `mockups/difficulty-select-v4.html` (신규)
**Scene**: `Scenes/DifficultySelectScene.swift`
**관련 노드**: `Nodes/DifficultyCardNode.swift`

### 5.1 현재 문제 (스크린샷 4 기반)

- 하/중/상 카드 폭이 너무 좁음 → 카드 안 한글 텍스트 ("여유로운 실습", "긴장의 병동" 등)이 2~3줄로 줄바꿈되며 답답
- 줄 간격(line height)이 좁아 시각적으로 한 덩어리
- Phase 7-C는 색 위계는 통과했으나 사이즈 자체는 v2 상속

### 5.2 Before → After

| 항목 | Before (v3) | After (v4) |
|---|---|---|
| 카드 폭 | 100pt | **130pt** (`difficultyCardWidthV4=130`) |
| 카드 높이 | 160pt | **200pt** (`difficultyCardHeightV4=200`) |
| 카드 사이 gap | 16pt | **22pt** (`difficultyCardGapV4=22`) |
| 카드 안 패딩 (top/bottom) | 8pt | **14pt** (`difficultyCardPaddingV4=14`) |
| 부제 ↔ 보조라벨 사이 vertical gap | 4pt | **10pt** (`difficultyCardSubtitleGapV4=10`) |
| 보조라벨 line height | 1.15 | **1.4** (Gowun Dodum, SKLabel attributedText 사용) |
| 헤더(하/중/상) ↔ 부제 사이 gap | 6pt | **12pt** (`difficultyCardHeaderGapV4=12`) |
| 보조라벨 fontSize | 11pt | **12pt** |

### 5.3 좌측 미니 캐릭터 카드 보호

- 좌측 글래스 카드(미니 얼굴 + 속도 칩)는 Phase 7-C 합격 상태 그대로 유지
- 카드 3장의 합산 폭이 화면 폭 초과 안 하도록 미니 카드 영역 폭은 -10pt 정도 축소 허용

### 5.4 변경 안 할 것

- DifficultySelectScene `init(characterID:)` 시그니처
- 시작 → GameScene(characterID:difficulty:) 전이 로직
- Difficulty enum 값/이름/시간 상수
- `preferenceRepo.lastDifficulty` 저장/복원
- Phase 7-C의 색 토큰 (하=민트/중=골드/상=코랄) byte-identical

### 5.5 합격 기준

- 카드 3장이 화면 폭 안에 모두 들어옴 (잘림 0)
- 카드 안 텍스트가 2줄 이하로 자연 줄바꿈
- 보조라벨 line height가 시각적으로 1.4 이상 (글자가 답답하지 않음)
- 시작 버튼이 카드 아래에서 충분한 호흡(36pt+) 확보

---

## 6. Phase E — 카운트다운 표시 버그 수정

**Mockup**: 없음 (Phase 7-E `mockups/countdown-overlay-v1.html` 재사용)
**Scene**: `GameScene.swift` (showCountdown 함수)
**노드**: `Nodes/CountdownNode.swift` (조건부 수정)

### 6.1 현재 문제 (스크린샷 5 기반)

- 게임 진입 직후 화면에 **3·2·1·GO! 카운트다운이 보이지 않음**
- Phase 7-E는 합격(9.76/10)했으나 실기 검증에서 미표시 → **가시성 버그**
- 가능 원인 후보:
  - (a) CountdownNode가 cameraNode가 아닌 worldNode에 부착되어 카메라 추적 안 됨
  - (b) zPosition 250이 다른 풀스크린 오버레이(예: dim 자체)에 가려짐
  - (c) showCountdown 호출 시점이 비주얼 setup 전이라 즉시 cleanup
  - (d) dim 노드가 CountdownNode 위에 올라와 라벨을 덮음
- Generator가 우선 **현재 GameScene.didMove → showCountdown 호출 경로**를 추적해 실제 원인 식별

### 6.2 진단 체크리스트 (Generator 필수 수행)

1. `GameScene.showCountdown()` 본문에서 attach 부모 노드 확인 (`cameraNode` 권장)
2. `CountdownNode.zPosition` vs `dim.zPosition` 비교 (CountdownNode > dim 보장)
3. `dim` SKSpriteNode의 size가 scene.size 기준인지 cameraNode 좌표 기준인지 검증
4. `start(onTick:onGo:onComplete:)` 콜백이 실제로 발화되는지 print 디버그 1회
5. 시뮬레이터 빌드 후 0~4초 사이 라벨이 보이는지 시각 확인

### 6.3 합격 후 보장 사양

```
GameScene.didMove(to:) 직후 :
  - dim alpha 0 → 0.32 (0.2s) — 부모: cameraNode, zPosition 240
  - CountdownNode attach — 부모: cameraNode, zPosition 250 (dim보다 +10)
  - 0.0s ~ 3.0s : "3 → 2 → 1" Jua 120pt navy (V3 상수 보존)
  - 3.0s ~ 3.8s : "GO!" Jua 140pt 코랄 scale 1.2 → 1.8
  - 3.8s ~ 4.0s : dim alpha 0.32 → 0 (0.2s) + cleanup
  - 4.0s : 입력 활성화 + spawnSystem.start()
```

### 6.4 변경 안 할 것

- 게임 루프(`update(_:)`) · 물리 · 점수 계산
- spawnSystem.start() 호출 시점 (카운트다운 완료 콜백 안에서만)
- CountdownNode `init()` / `start(onTick:onGo:onComplete:)` 시그니처
- Phase 7-E의 V3 상수 9종 (값 byte-identical)
- 입력 비활성화 시간 (이미 4초로 보장되어 있어야 함)

### 6.5 합격 기준

- 시뮬레이터에서 게임 시작 후 **4초 안에 "3 → 2 → 1 → GO!" 4단계가 모두 시각적으로 보임**
- GO! 종료 후 음표 첫 발생 시점이 카운트다운 종료와 정확히 일치
- 카운트다운 도중 D-pad 탭 무시 (입력 게이트 보존)
- dim이 라벨을 덮지 않음 (zPos 검증)

---

## 7. Phase F — 인게임 HUD/스킬 영역 zPos·레이아웃 정리

**Mockup**: `mockups/hud-zorder-v1.html` (신규)
**파일**: `GameScene+Setup.swift` + `Nodes/HUDNode.swift` + `Nodes/SkillButtonNode.swift` + `Nodes/HUDSkillSlotNode.swift`

### 7.1 현재 문제 (스크린샷 6 기반)

좌하단 영역에서 다음 4개 요소가 시각적으로 한 덩어리로 겹침:

1. SkillButtonNode 큰 코랄 원("북클럽" 라벨)
2. SkillButtonNode 내부 "B" 칩
3. HUDSkillSlotNode 상단 "북클럽" 라벨 (skill name pill)
4. "READ" 또는 비슷한 보조 라벨 (정확히 어떤 노드인지 Generator가 식별 필요)

같은 라벨("북클럽")이 **2번 표시**되고 있어 시각적 노이즈 발생.

### 7.2 정리 방향

| 위치 | 표시 책임 | 정리 후 |
|---|---|---|
| SkillButtonNode 본체 (좌하단 큰 원) | 아이콘/B 칩만 | **스킬 이름 라벨 제거** (이미 HUD 슬롯에 있음) |
| HUDSkillSlotNode (좌상단 또는 슬롯) | 스킬 이름 + CD 칩 | **유지** — 단일 진실 원천 |
| "READ"/보조 라벨 | (식별 후 처리) | **Generator가 식별 후 zPos 조정 또는 제거** |
| B 칩 (키보드 안내) | SkillButton 내부 | **유지** (필요한 정보) |
| 라벨 zPosition | 혼재 | **HUD=100 / 스킬버튼=80 / 슬롯내라벨=110**으로 명확히 분리 |

### 7.3 시각 가독성 보강

- 모든 HUD/스킬 영역 라벨에 1px navy outline (이미 일부 있음 — 전체 통일)
- 스킬 버튼 본체와 HUD 슬롯이 시각적으로 다른 zone임을 확인 (위치만 충분히 떨어져 있다면 zPos 조정으로 충분)

### 7.4 변경 안 할 것

- SkillButtonNode 탭 → SkillSystem.activateSkill() 호출 시그니처
- HUDNode init(scene size:) 시그니처
- HUDSkillSlotNode 4슬롯 데이터 채움 알고리즘
- PhysicsCategory / 입력 매핑 (DPad/SkillButton 모두 byte-identical)

### 7.5 합격 기준

- 시뮬레이터 가로 화면 좌하단 ~ 좌상단 어디에도 **같은 라벨이 2번 등장하지 않음**
- 어떤 시각 요소도 다른 요소를 0px 침범하지 않음
- 모든 텍스트 가독성 ≥ 4.5:1 대비
- 인게임 입력 응답성 회귀 0 (모든 탭 hitbox 보존)

---

## 8. Phase G — 빌런 가시화 + 박병장 데뷔 + 비행기 퀄리티 + 플레이어 팔다리·좌우

**Mockup**: `mockups/villains-and-player-v2.html` (신규)
**파일**: `Nodes/EnemyNode.swift` / `ProfessorNode.swift` / `StoneGuardNode.swift` / `SergeantParkNode.swift` / `AirplaneNode.swift` / `PlayerNode.swift` + `GameScene+Setup.swift` (박병장 spawn 추가)

### 8.1 현재 문제 (스크린샷 7 기반)

| # | 문제 | 원인 추정 |
|---|---|---|
| 1 | 빌런 3종이 인게임에서 **여전히 픽셀 그대로** 보임 | Phase 7-F가 시각 자식(SKShapeNode 6~8개)을 부착했지만 **PixelSprite가 그 위를 덮음** → PixelSprite isHidden 또는 alpha 0 필요 |
| 2 | **박병장이 GameScene에 등장하지 않음** | Phase 7-F가 노드 클래스만 준비, spawn 로직 미추가 (잔존 작업) |
| 3 | **박병장 등장 시 컷씬·토스트 없음** | 사용자 요구 — 등장 임팩트 |
| 4 | 비행기(AirplaneNode)가 **노란 사각형 1개** — 비행기로 보이지 않음 | 현재 `super.init(texture: nil, color: .ganhoYellowF, size: size)`만 — 시각 자식 0 |
| 5 | PlayerNode에 **팔다리가 없음** | Phase 7-G가 4방향 face child만 부착, 몸통/팔다리 시각 부재 |
| 6 | PlayerNode 좌우(left/right) 시각이 **동일** | Phase 7-G가 xScale=-1 mirroring 처리 — 사용자는 좌우 차이를 원함 |

### 8.2 빌런 3종 가시화 (수간호사·이교수·석조무사)

```swift
// EnemyNode/ProfessorNode/StoneGuardNode 모두 동일 패턴
init(...) {
    super.init(...)
    // ... 기존 physicsBody / properties ...
    setupVisualOverlay()  // Phase 7-F 메서드 — 이미 있음

    // Phase 8-G 추가: 기존 PixelSprite 가시 차단
    hidePixelSpriteIfPresent()
}

private func hidePixelSpriteIfPresent() {
    // PixelSprite 자식(name == "pixelSprite" 등) 탐색 후 alpha = 0
    // 또는 SKSpriteNode 본체의 texture를 nil로
    children
        .filter { $0.name?.contains("pixel") == true }
        .forEach { $0.alpha = 0 }
}
```

- **PixelSprite 노드는 제거하지 말 것** — Sprint 4 PNG 통합 대비 트리 구조 보존
- alpha 0으로 시각만 차단

### 8.3 박병장 GameScene 데뷔

#### 8.3.1 spawn 로직 (GameScene+Setup.swift)

```swift
// addHardMap() 또는 GameScene 진입 N초 후 1회 spawn
private func spawnSergeantPark() {
    let park = SergeantParkNode()
    park.position = CGPoint(x: scene.size.width + 100, y: scene.size.height * 0.5)
    park.zPosition = 5
    worldNode.addChild(park)

    // 등장 컷씬 트리거 (먼저)
    presentSergeantParkIntro(then: {
        // 컷씬 종료 후 본격 등장
        park.run(SKAction.moveTo(x: scene.size.width * 0.5, duration: 1.2))
        // AI는 이번 sprint에서 추가 X — 화면에 가만히 있다 사라지는 패턴 OK
        park.run(.sequence([
            .wait(forDuration: 8.0),
            .moveTo(x: -100, duration: 1.5),
            .removeFromParent()
        ]))
    })
}
```

#### 8.3.2 등장 컷씬 (CutsceneOverlayNode 재사용 또는 신규)

- 화면 중앙에 박병장 얼굴 클로즈업 (SergeantParkNode 큰 사이즈 단독 렌더)
- 상단 또는 하단에 **"박병장 등장!"** 토스트 (Jua 36pt 코랄)
- 0.0s ~ 0.4s : 화면 dim + 박병장 얼굴 fade-in + 토스트 슬라이드
- 0.4s ~ 1.8s : 박병장 얼굴 + 토스트 유지 (사용자 인지 시간)
- 1.8s ~ 2.2s : 모두 fade-out + cleanup
- 총 2.2s — 너무 길지 않게

#### 8.3.3 발동 시점

- 게임 시작 후 **30초 시점** 또는 **score 50점 도달 시** (둘 중 더 빠른 쪽) — 1회만
- DifficultyId == .hard일 때만 발동 (난이도 중·하는 미발동)
- 1회만 보장 (GameState에 `sergeantParkDebuted: Bool` 플래그 추가)

### 8.4 비행기 퀄리티 향상 (AirplaneNode)

#### 8.4.1 Before → After

```swift
// Before
super.init(texture: nil, color: .ganhoYellowF, size: size)

// After — SKSpriteNode 그대로지만 color: .clear + 시각 자식 6개
super.init(texture: nil, color: .clear, size: size)
attachFuselage()  // 본체 (직사각형 + 둥근 모서리)
attachWings()     // 양 날개 (사다리꼴 2개)
attachTail()      // 꼬리 날개 (작은 사각형)
attachCockpit()   // 조종석 (작은 타원, 푸른색)
attachPropeller() // 프로펠러 (회전 액션)
attachContrail()  // 비행운 (꼬리 뒤 흰 줄 - SKEmitter 또는 SKShape sequence)
```

#### 8.4.2 시각 사양

- 본체: ganhoYellowF (기존 색 유지) + 4pt cornerRadius
- 날개: 본체보다 살짝 어둡게 (ganhoYellowF × 0.92) 사다리꼴 path
- 조종석: ganhoNavyDeep × 0.6 타원
- 프로펠러: 회색 + `SKAction.rotate(byAngle: .pi * 2, duration: 0.15).repeatForever()`
- 비행운: 본체 뒤 흰색 alpha 0.6 작은 원 4~5개 (옵션 — LOC 부담 시 생략)

### 8.5 PlayerNode 풀바디 + 4방향 (NurseAvatarNode 패턴 5명 확장)

#### 8.5.1 마스터 레퍼런스 — NurseAvatarNode

`Nodes/NurseAvatarNode.swift` 가 이미 김간호 풀바디 SVG → SKShapeNode 코드화 완료:
- **빌드 순서**: shoulders → collar → neck → head → bangs → cap+cross → headphones → eyebrows → eyes → blush → mouth → arm + finger
- **zPosition 내부 순서**: 어깨(-5) < 사이드헤어 뒤(-3) < 머리/목(0) < 앞머리(5) < 모자(10) < 헤드폰 밴드(15) < 헤드폰 컵(20) < 얼굴 디테일(25) < 팔(30) < 손가락 끝(35)
- **좌표계**: SVG y-down → SpriteKit y-up 변환 (`-1` 곱)
- **PNG swap 호환**: SKNode 서브클래스, 향후 SKSpriteNode(texture:) 교체 시 좌표·zPosition 보존

이 NurseAvatarNode 패턴을 **5명 캐릭터 × 4방향 = 20개 풀바디 path**로 확장한다.

#### 8.5.2 신규 노드 — CharacterFullBodyNode (인게임 전용)

```swift
// Nodes/CharacterFullBodyNode.swift (신규)
final class CharacterFullBodyNode: SKNode {
    let id: CharacterID
    private var directionContainers: [Direction: SKNode] = [:]
    private(set) var currentFacing: Direction = .front

    init(id: CharacterID) {
        self.id = id
        super.init()
        buildAllDirections()  // 4방향 각각 별도 SKNode 컨테이너에 build
        facing(.front)        // 초기 방향
    }

    func facing(_ direction: Direction) {
        guard direction != currentFacing else { return }
        directionContainers.values.forEach { $0.isHidden = true }
        directionContainers[direction]?.isHidden = false
        currentFacing = direction
    }

    // MARK: - Build (5명 × 4방향 = 20 method)
    private func buildAllDirections() {
        for direction in [Direction.front, .back, .left, .right] {
            let container = SKNode()
            switch id {
            case .kim:  buildKimBody(in: container, direction: direction)
            case .jung: buildJungBody(in: container, direction: direction)
            case .geon: buildGeonBody(in: container, direction: direction)
            case .im:   buildImBody(in: container, direction: direction)
            case .lee:  buildLeeBody(in: container, direction: direction)
            }
            container.isHidden = true
            directionContainers[direction] = container
            addChild(container)
        }
    }
}
```

#### 8.5.3 4방향별 시각 사양

| 방향 | 핵심 변경 (front 기준) | NurseAvatarNode 재사용 비율 |
|---|---|---|
| **front** | 마스터 그대로 (NurseAvatarNode 김간호 풀바디 패턴) | 100% (NurseAvatarNode SVG path 그대로 복사) |
| **back** | 머리 뒤통수(앞머리·눈·코·입 X) + 뒷머리 헤어 path + 가운 등판 단추선 제거 | shoulders/neck 100% + 헤어/등판 신규 path |
| **left** | 어깨·머리 ¾ 측면 + **왼팔 앞, 오른팔 뒤** + 청진기 좌측 어깨 + 안경 좌측 림 강조 | shoulders 측면 path + 별도 leftArm/rightArm path |
| **right** | left를 mirror가 아닌 **별도 path** + **오른팔 앞, 왼팔 뒤** + 청진기 우측 어깨 + 안경 우측 림 강조 | left와 같은 구조에서 정반대 path |

**중요**: left/right는 `xScale = -1` mirroring 금지 (사용자 의사결정 #5). 각각 별도 path 작성. 청진기 위치·안경 림·머리 기울기·팔 앞뒤가 명시적으로 다름.

#### 8.5.4 캐릭터별 풀바디 시안 (5명 × 4방향 = 20셀)

| 캐릭터 | 정체성 시각 요소 (4방향 공통) | 풀바디 추가 요소 |
|---|---|---|
| **김간호** (kim) | 곱슬 번머리 + 코랄 헤드폰 + 간호사 모자 + 코랄 십자 | 민트 스크럽 + V-collar + 손가락 "쉿" (이미 NurseAvatarNode에 있음) |
| **정간호** (jung) | 검은 단발 + 둥근 안경 + 차분한 표정 | 흰 가운 + 청록 스크럽 안 + 한 손에 차트 |
| **건간호** (geon) | 짧은 흑발 + 빨간 캡 + 활기찬 표정 | 페일 블루 스크럽 + 양손 주먹 가볍게 |
| **임간호** (im) | 갈색 사이드테일 + 살짝 미소 | 라벤더 스크럽 + 청진기 목에 |
| **이간호** (lee) | 검은 단발 + 정중한 표정 + 안경 X | 흰 가운 + 흰 모자 + 양손 가지런 |

mockup `villains-and-player-v2.html` 에서 5명 × 4방향 = 20셀 그리드를 SVG로 시각화. 각 셀은 96×120pt 정도 미니 카드.

#### 8.5.5 PlayerNode 교체 패턴

```swift
// Nodes/PlayerNode.swift 수정 (시그니처 byte-identical)
final class PlayerNode: SKSpriteNode {
    private var fullBody: CharacterFullBodyNode?
    // ... 기존 properties ...

    func apply(characterID: CharacterID) {
        // 기존 face child 4개(Phase 7-G) → 모두 제거하고 CharacterFullBodyNode 1개로 교체
        children.filter { $0.name?.hasPrefix("faceChild") == true }
                .forEach { $0.removeFromParent() }

        let body = CharacterFullBodyNode(id: characterID)
        body.name = "fullBody"
        body.setScale(GameConfig.playerFullBodyScaleV4)  // ~0.35 — hitbox 보존
        body.zPosition = 1
        addChild(body)
        self.fullBody = body
    }

    func facing(_ direction: Direction) {
        fullBody?.facing(direction)
    }
}
```

#### 8.5.6 걷기 호흡 애니메이션

- D-pad 입력 중에는 다리 SKAction (scale Y 1.0 ↔ 0.95) 0.2s 주기로 반복
- 정지 시 호흡 (몸통 scale Y 1.0 ↔ 1.02 1.5s 주기)
- update() 내부 addChild 0건, SKAction은 attach 시 1회만 부착

#### 8.5.7 변경 안 할 것 (Phase 7-G 정체성 보호)

- **CharacterFaceNode 본체는 건드리지 말 것** — 캐릭터 선택·ScoreboardScene mini factory가 계속 사용 (얼굴만 정체성 유지)
- 단, Phase 7-G가 PlayerNode에 직접 부착했던 face child 4개는 CharacterFullBodyNode로 대체 (PlayerNode 시그니처는 byte-identical)
- DPadNode → PlayerNode.facing(_:) 연결은 byte-identical (Direction enum 그대로)
- physicsBody hitbox 좌표/크기 byte-identical (시각 노드 scale은 hitbox와 무관)

#### 8.5.8 NurseAvatarNode 자체는 보호 영역

- NurseAvatarNode는 **StartScene 메인화면 김간호 큰 그림** 전용으로 계속 사용
- CharacterFullBodyNode가 NurseAvatarNode의 *패턴*만 차용 (path 코드 복붙 OK)
- NurseAvatarNode 본체 git diff = 0줄

### 8.6 변경 안 할 것

- 3종 빌런 (EnemyNode/ProfessorNode/StoneGuardNode) 모든 AI/이동/충돌 시그니처 + physicsBody.size/categoryBitMask
- PlayerNode 이동 로직 + physicsBody hitbox 좌표/크기
- 충돌 hitbox 좌표·크기 (시각만 변경)
- DPad → velocity 입력 매핑
- AirplaneNode `crossScreen(sceneWidth:atY:)` 시그니처
- SergeantParkNode 시각 자식 6개 (Phase 7-F 결과물 byte-identical)

### 8.7 합격 기준

- 시뮬레이터 인게임에서 3종 빌런이 **픽셀이 아닌 Phase 7-F 시각 자식**으로 보임
- 박병장이 hard 난이도에서 **30초 또는 50점 시점에 1회 등장 + 컷씬 + 토스트** 발화
- 비행기가 노란 사각형이 아닌 **비행기로 인식 가능한 형상** (날개·꼬리·조종석 식별)
- PlayerNode가 **팔다리를 가지고** D-pad 입력 시 보임
- left/right 방향이 **시각적으로 다른 시안** (mirroring만이 아닌 명시적 path 차이)
- 게임 로직(점수/물리/AI/충돌) 회귀 0

---

## 9. 파일별 변경 범위 종합

| 파일 | Phase | 변경 유형 |
|---|---|---|
| `Config/GameConfig.swift` | A~G | V4 상수 ~50개 추가 (V3 값 보존) |
| `Config/GameState.swift` | G | `sergeantParkDebuted: Bool` 플래그 1줄 추가 |
| `Config/ColorTokens.swift` | G | 비행기 시각 자식용 보조 색 2~3종 (필요 시) |
| `Scenes/ScoreboardScene.swift` | A | 타이틀/헤더/매트릭스 Y 재배치 + accent line 위치 |
| `Scenes/CharacterSelectScene.swift` | B | 5장 → 1+2(중앙+양옆) 스와이프 페이지 + currentIndex 상태 + touchesMoved |
| `Scenes/SkillExplanationScene.swift` | C | bottomButtonGapV4=28 적용 + hint chip Y 상향 |
| `Scenes/DifficultySelectScene.swift` | D | 카드 폭/높이/gap/padding V4 적용 |
| `GameScene.swift` | E | showCountdown 가시화 버그 fix (attach parent + zPos 검증) |
| `GameScene+Setup.swift` | F, G | HUD/스킬 zPos 정리 + 박병장 spawn 호출 1회 |
| `Nodes/CharacterCardNode.swift` | B | 스와이프 페이지 모드용 setPagePosition(:focused:) 메서드 추가 |
| `Nodes/CountdownNode.swift` | E | (필요 시) attach 위치/zPos 디버그 보강 |
| `Nodes/HUDNode.swift` | F | 라벨 zPos 정리 |
| `Nodes/HUDSkillSlotNode.swift` | F | 슬롯 라벨 단일 진실 원천 유지 |
| `Nodes/SkillButtonNode.swift` | F | **본체 스킬 이름 라벨 제거** (HUD 슬롯에 단일 표시) |
| `Nodes/DifficultyCardNode.swift` | D | 폭/높이/내부 padding/lineHeight V4 적용 |
| `Nodes/EnemyNode.swift` | G | PixelSprite alpha 0 처리 1줄 추가 |
| `Nodes/ProfessorNode.swift` | G | PixelSprite alpha 0 처리 1줄 추가 |
| `Nodes/StoneGuardNode.swift` | G | PixelSprite alpha 0 처리 1줄 추가 |
| `Nodes/SergeantParkNode.swift` | G | (시각만 — Phase 7-F 그대로) + spawn entry-point용 클로즈업 factory 1개 추가 |
| `Nodes/AirplaneNode.swift` | G | color: clear + 시각 자식 6개 (fuselage/wings/tail/cockpit/propeller/contrail) |
| `Nodes/PlayerNode.swift` | G | Phase 7-G face child 4개 제거 → **CharacterFullBodyNode 1개로 교체** + 걷기/호흡 SKAction |
| `Nodes/CharacterFullBodyNode.swift` | G | **신규 파일** — 5명 × 4방향 = 20 풀바디 path (NurseAvatarNode 패턴 차용). 예상 LOC ~1400 |
| `Nodes/CharacterFaceNode.swift` | G | **변경 0줄** — 캐릭터 선택·ScoreboardScene mini factory 정체성 유지 |
| `Nodes/NurseAvatarNode.swift` | G | **변경 0줄** — StartScene 메인 김간호 큰 그림 전용. CharacterFullBodyNode가 *패턴*만 차용 |
| `Nodes/CutsceneOverlayNode.swift` 또는 신규 `SergeantIntroOverlayNode.swift` | G | 박병장 등장 컷씬 2.2s 발화 |

---

## 10. 디자인 토큰 추가 (GameConfig.swift)

```swift
// MARK: - Sprint 8 — Layout V4 (겹침 해소 + 카드 확대)

// Phase A — Scoreboard
static let scoreboardTitleYOffsetV4: CGFloat       = 40   // 타이틀 상향
static let scoreboardHeaderRowGapV4: CGFloat       = 18
static let scoreboardCellPitchYV4: CGFloat         = 38
static let scoreboardStatBottomGapV4: CGFloat      = 24

// Phase B — Character Select 스와이프
static let characterSwipeCardScaleCenterV4: CGFloat = 1.08
static let characterSwipeCardScaleSideV4: CGFloat   = 0.85
static let characterSwipeCardAlphaSideV4: CGFloat   = 0.55
static let characterSwipeOffsetXV4: CGFloat         = 180
static let characterSwipeAnimationDurationV4: Double = 0.22
static let characterHeaderBottomYBoundV4: CGFloat   = 0.80  // scene.height ratio
static let characterCardCenterYV4: CGFloat          = 0.50

// Phase C — Skill Explanation
static let skillExplanationBottomButtonGapV4: CGFloat = 28
static let skillExplanationHintChipPaddingYV4: CGFloat = 8

// Phase D — Difficulty Card V4
static let difficultyCardWidthV4: CGFloat         = 130
static let difficultyCardHeightV4: CGFloat        = 200
static let difficultyCardGapV4: CGFloat           = 22
static let difficultyCardPaddingV4: CGFloat       = 14
static let difficultyCardSubtitleGapV4: CGFloat   = 10
static let difficultyCardHeaderGapV4: CGFloat     = 12
static let difficultyCardSubtitleLineHeightV4: CGFloat = 1.4
static let difficultyCardSubtitleFontSizeV4: CGFloat   = 12

// Phase F — HUD zPos
static let hudLabelZPositionV4: CGFloat           = 100
static let skillButtonZPositionV4: CGFloat        = 80
static let hudSkillSlotLabelZPositionV4: CGFloat  = 110

// Phase G — 박병장 데뷔 / 비행기 / 플레이어
static let sergeantParkDebutTimeV4: Double            = 30.0
static let sergeantParkDebutScoreV4: Int              = 50
static let sergeantParkIntroDurationV4: Double        = 2.2
static let sergeantParkOnStageDurationV4: Double      = 8.0
static let airplaneCockpitColorAlphaV4: CGFloat       = 0.6
static let airplanePropellerRotateDurationV4: Double  = 0.15
static let playerArmWidthV4: CGFloat                  = 4
static let playerLegWidthV4: CGFloat                  = 5
static let playerWalkCycleDurationV4: Double          = 0.20
static let playerIdleBreathDurationV4: Double         = 1.50
static let playerFullBodyScaleV4: CGFloat             = 0.35   // CharacterFullBodyNode → PlayerNode hitbox fit
static let characterFullBodyMockupCellWidthV4: CGFloat  = 96   // mockup 5×4 그리드 한 셀
static let characterFullBodyMockupCellHeightV4: CGFloat = 120
```

---

## 11. 합격 기준 (Sprint 8 전체)

기존 Sprint 1~7과 동일 4-카테고리 가중 평균 7.5 이상.

| 카테고리 | 가중치 | Sprint 8 추가 통과선 |
|---|---|---|
| 게임 로직 회귀 0 | 40% | 9.0 이상 — 7개 Phase 모두 |
| Swift 패턴 (rules 준수) | 20% | 7.0 이상 |
| 비주얼 일관성 (mockup 매칭) | 25% | 7.0 이상 — 6개 mockup 매칭률 ≥ 85% |
| 가독성 & UX | 15% | **8.0 이상** (이번 sprint는 겹침/가시성이 핵심 — UX 통과선 +1.0 상향) |

**Phase 단위 점수**가 모두 7.5 이상이어야 Sprint 8 합격. 한 Phase라도 미달 시 해당 Phase만 재실행 (최대 3회).

---

## 12. 신규 mockup 파일 목록

작업 전 모두 브라우저에서 시각 확인 가능해야 한다.

| 파일 | Phase | 용도 |
|---|---|---|
| `mockups/scoreboard-v2.html` | A | 타이틀/헤더/매트릭스 분리 |
| `mockups/character-select-v4.html` | B | 1+2 스와이프 페이지 |
| `mockups/skill-explanation-v4.html` | C | 힌트 ↔ 시작 버튼 분리 |
| `mockups/difficulty-select-v4.html` | D | 카드 130×200 + line height 1.4 |
| `mockups/hud-zorder-v1.html` | F | 좌하단 zPos 레이어 다이어그램 |
| `mockups/villains-and-player-v2.html` | G | 빌런 4종 인게임 적용 + 비행기 신규 + 플레이어 팔다리 + 좌우 비대칭 5×2 |

---

## 13. Phase 실행 순서 (의존성)

```
A → B → C → D  (메뉴 4씬 — 독립, 순차 권장)
              ↓
              E  (인게임 시작 시퀀스 — 메뉴 정리 후)
              ↓
              F  (HUD/스킬 영역 zPos)
              ↓
              G  (빌런·박병장·비행기·플레이어 — 인게임 시각 통합)
```

Phase A~D는 독립적이지만 하네스 안정성을 위해 순차 실행 권장. Phase G가 가장 무거우므로(LOC ~600) 마지막에 배치.

---

## 14. 사용자 의사결정 (사전 확정 — 2026-05-20)

Sprint 8 Planner는 다음 결정을 SPEC.md에 그대로 반영해야 한다:

1. **캐릭터 선택 스와이프 vs 작은 카드 5장**: **스와이프 페이지** (한 번에 중앙 1장 + 양옆 반쯤 보이는 2장)
2. **캐릭터 시각의 2계층 분리**: 선택 화면 = **얼굴만**(CharacterFaceNode 현행 유지, 풀바디 추가 금지). 인게임 = **풀바디**(CharacterFullBodyNode 신규)
3. **풀바디 마스터 레퍼런스**: **NurseAvatarNode**(김간호 메인화면 풀바디, 이미 SKShapeNode로 shoulders/collar/neck/head/bangs/cap/headphones/arm/finger 완성)의 SVG path와 zPosition 순서를 그대로 차용 → 5명 × 4방향 = 20셀 확장
4. **박병장 등장 트리거**: hard 난이도에서 **30초 도달 또는 50점 도달 중 더 빠른 쪽 1회**
5. **박병장 컷씬 길이**: **2.2초** (얼굴 클로즈업 + "박병장 등장!" 토스트)
6. **빌런 PixelSprite 처리**: 노드는 보존 + **alpha 0**으로 시각만 차단 (Sprint 4 PNG 통합 대비 트리 구조 유지)
7. **PlayerNode 좌우 비대칭**: 단순 mirroring(xScale=-1) 금지. CharacterFullBodyNode 안에서 **left/right 각각 별도 path 작성** (청진기 위치/안경 면/머리 기울기/팔 앞뒤 차이)
8. **비행기 신규 자식**: fuselage / wings / tail / cockpit / propeller / contrail 6개 (contrail은 LOC 부담 시 생략 허용)
9. **HUD 좌하단 중복 라벨 처리**: SkillButtonNode 본체의 스킬 이름 라벨 **제거**, HUDSkillSlotNode가 단일 진실 원천
10. **CharacterFaceNode·NurseAvatarNode 본체 보호**: 두 노드 모두 git diff 0줄 유지. CharacterFullBodyNode는 NurseAvatarNode의 *패턴*만 차용하고 path 코드는 독립

---

## 15. 실행 트리거

```
Sprint 8 진행해줘
```

하네스가:
1. DESIGN_RENEWAL_STATE.md 읽어 현재 Phase 확인
2. Phase A부터 (또는 이전 합격 Phase 다음부터) Planner 호출
3. SPEC.md 작성 → Generator → Evaluator (최대 3회)
4. Phase 합격 시 DESIGN_RENEWAL_STATE.md 갱신 → 다음 Phase로
5. Phase G까지 완료 시 Sprint 8 전체 합격

특정 Phase만 실행:
```
Sprint 8 Phase A 진행해줘
```

---

## 16. 사용자가 지적한 7개 이슈 → Phase 매핑 체크리스트

| # | 사용자 지적 (스크린샷) | 매핑 Phase | 확인 항목 |
|---|---|---|---|
| 1 | 스크린샷1: 기록보기 문구와 표가 겹침 | **A** | 타이틀/헤더/매트릭스/우상단 칩 0px 겹침 |
| 2 | 스크린샷2: 캐릭터 카드 잘림 + 헤더 충돌 → 스와이프로 | **B** | 양 끝 잘림 0 + 헤더 0px 겹침 + 스와이프 작동 |
| 3 | 스크린샷3: "스킬 발동" 글자와 "시작" 버튼이 너무 붙음 | **C** | 두 요소 28pt 이상 간격 |
| 4 | 스크린샷4: 하중상 카드 더 크고 line spacing 더 넉넉히 | **D** | 카드 130×200 + line height 1.4 |
| 5 | 스크린샷5: 카운트다운이 표시되지 않음 | **E** | 0~4초 사이 3·2·1·GO! 시각 확인 |
| 6 | 스크린샷6: HUD/스킬 영역 글자 다 겹침 | **F** | 같은 라벨 2번 등장 0 + 모든 요소 0px 침범 |
| 7 | 스크린샷7: 빌런 픽셀 그대로 + 박병장 등장 부재 + 비행기 사각형 + 플레이어 팔다리 없음 + 좌우 동일 | **G** | 5건 모두 가시 확인 |
| 7-a | (추가 명세) 캐릭터 선택은 얼굴만 OK, **인게임만 풀바디 필요** | **G** (Phase B는 얼굴 유지) | CharacterFullBodyNode 신규 + CharacterFaceNode/카드 git diff 0 |
| 7-b | (추가 명세) **기존 팔다리 SVG(NurseAvatarNode) 활용** | **G** | NurseAvatarNode 패턴 차용 + 본체 git diff 0 |
| 7-c | (추가 명세) **옆모습·뒤모습도 만들기** | **G** | 5명 × 4방향(front/back/left/right) 모두 별도 path 존재 |

**위 7건 + 추가 3건(7-a/b/c) 중 한 건이라도 합격 검증에서 통과 못 하면 Sprint 8 전체 불합격 처리.**

---

**작성일**: 2026-05-20
**작성자**: Sprint 7 완료 후 실기 검증에서 드러난 7건 결함 통합 작업지시서
