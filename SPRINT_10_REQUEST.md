# SPRINT 10 — 원본 웹게임 1:1 픽셀 이식

> **목적**: iOS 인게임을 원본 웹게임(hyungyugod.github.io/pages/game.html)과 **시각·게임플레이·수치 1:1** 로 맞춘다. 메뉴/선택창은 보존, 인게임만 픽셀 게임으로 전면 재구성.
>
> **선행 Sprint**: 1~9는 메뉴·선택창·HUD 디자인 리뉴얼 완료. Sprint 10은 **인게임 본체 원본 일치화** (메뉴는 보존).

---

## 단일 진실 원천 (SoT)

| 문서 | 역할 |
|---|---|
| `docs/ORIGINAL_GAME_ANALYSIS.md` (1391줄) | 원본 모든 좌표·수치·픽셀·AI 패턴의 단일 진실 원천 |
| `docs/IOS_CURRENT_STATE.md` (~600줄) | iOS 현재 상태 (보존/재작성/신규 분류) |
| 본 문서 (`SPRINT_10_REQUEST.md`) | Phase별 작업 범위·변경 금지·합격 기준 |

각 Phase Planner는 위 3개 문서를 **반드시 함께 읽고** SPEC.md 작성한다.

---

## 1. Phase 구조 (10개)

| Phase | 이름 | 핵심 변경 | 의존성 | LOC 추정 |
|---|---|---|---|---|
| A | 픽셀 시각 노출 | PlayerNode 카툰 자식 제거 → PixelSprite 표시 | — | ~150 |
| B | 맵 크기·카메라 정합 | 48×24 → 32×20 타일, SCALE=2 정합 | A | ~200 |
| C | 맵 빌더 3종 (벽) | easy/normal/hard 맵 데이터 + 벽 노드 | B | ~400 |
| D | 수간호사 패트롤 + F 투척 | 4지점 사각 순환 + 텔레그래프 0.4s + ±15° 스프레드 | A | ~350 |
| E | 음표·F·A·변기·청진기 픽셀 + 스폰 | 픽셀 좌표 1:1 + 스폰 인터벌·TTL 원본 표 | C | ~500 |
| F | 이교수·석조무사 픽셀 + AI | 8자 패트롤 / 4지점 순환, 자식 시각 제거 | A, E | ~350 |
| G | 박병장 이스터에그 3단계 | iOS 컷씬 유지 + 비행기·폭탄·수간호사 도주 5초 | A, D, F | ~400 |
| H | 컷씬 5종 | intro / mid1 / mid2 / introStoneGuard / introProfessor | A | ~300 |
| I | 난이도·점수·콤보 수치 | 원본 표 그대로, 5명 스킬 수치 1:1 | C, D, E, F | ~250 |
| J | HUD·iOS 이펙트 픽셀 톤 변환 | 콤보 팝업/sparkle/5초 긴박감 → 8-bit | I | ~300 |

**총 추정**: 약 3,200 LOC 변경/신규. **권장 순서**: A → B → C/D 병렬 가능 → E → F → G → H → I → J.

---

## 2. 전 Phase 공통 사항

### 2.1 보존 영역 🛡️ (Sprint 10 동안 절대 건드리지 말 것)

**메뉴/선택창 씬 (6개)**
- `GanhoMusic Shared/Scenes/StartScene.swift`
- `GanhoMusic Shared/Scenes/CharacterSelectScene.swift`
- `GanhoMusic Shared/Scenes/DifficultySelectScene.swift`
- `GanhoMusic Shared/Scenes/SkillExplanationScene.swift`
- `GanhoMusic Shared/Scenes/ResultScene.swift`
- `GanhoMusic Shared/Scenes/ScoreboardScene.swift`

**메뉴 전용 노드 (변경 금지)**
- `CharacterFaceNode.swift` (선택창 얼굴)
- `CharacterCardNode.swift` (캐릭터 카드)
- `DifficultyCardNode.swift`
- `NurseAvatarNode.swift` 의 SVG path 부분 (메뉴에서 사용)
- `ProfessorNode.swift` 의 SVG path 부분 (메뉴/카드에서 사용)
- `PrimaryButtonNode.swift`, `BackButtonNode.swift`, `GlassPillNode.swift`, `AccentLineNode.swift`, `DarkContextChipNode.swift`, `ToastLabelNode.swift`, `DiplomaOverlayNode.swift`, `SparkleEffectNode.swift` (메뉴 컨텍스트에서 호출되는 부분)

**Config (변경 금지 또는 추가만 허용)**
- `ColorTokens.swift` — 메뉴 색은 보존, 픽셀 팔레트는 추가만 가능
- `PhysicsCategory.swift` — 추가만 가능, 기존 카테고리 비트 변경 금지

### 2.2 재작성 / 교체 대상 🔥

| 파일 | 처리 |
|---|---|
| `GameScene+Setup.swift` | 게임 루프·스폰·충돌 전면 재작성 |
| `PlayerNode.swift` | SVG 풀바디 자식 제거 → PixelSprite 표시 |
| `CharacterFullBodyNode.swift` | **폐기** (Sprint 8 산물, 픽셀로 대체) |
| `MusicNoteEmitterNode.swift` | 스폰 로직 원본 1:1 재작성 |
| `NoteNode.swift` | 픽셀 음표 좌표로 재작성 |
| `EnemyNode.swift` (이교수) | 자식 시각 제거, 픽셀만 |
| `ProfessorNode.swift` (인게임 사용분) | 픽셀 패트롤 AI 재작성 |
| `StoneGuardNode.swift` | 픽셀 + 4지점 순환 AI 재작성 |
| `SergeantParkNode.swift` | 컷씬 부분 보존, 인게임 등장 흐름은 원본 박병장 이스터에그 결합 |
| `AirplaneNode.swift` | 픽셀 마리오 스타일 + 폭탄 투하 |
| `BombFlashNode.swift` | 픽셀 폭발 |
| `StethoscopeNode.swift` | 픽셀 청진기 14×8 매트릭스 |
| `HUDNode.swift`, `HUDSkillSlotNode.swift` | 픽셀 톤 폰트로 변환 |
| `ComboPopupNode.swift`, `ComboBreakNode.swift`, `ScorePopupNode.swift` | 8-bit 픽셀 폰트 |
| `CountdownNode.swift` | 픽셀 톤 변환 |
| `HitFlashNode.swift` | 픽셀 톤 변환 |

### 2.3 신규 생성 대상

- `Nodes/MapNode.swift` — 32×20 타일 컨테이너
- `Nodes/WallTileNode.swift` — 픽셀 벽 타일
- `Nodes/FProjectileNode.swift` — F 투척물 픽셀
- `Nodes/AItemNode.swift` — A 매혹 아이템 픽셀
- `Nodes/ToiletNode.swift` — 변기 픽셀
- `Nodes/IntroCutsceneNode.swift` — intro
- `Nodes/MidCutsceneNode.swift` — mid1/mid2
- `Nodes/IntroVillainCutsceneNode.swift` — introStoneGuard/introProfessor

### 2.4 절대 위반 금지

- **메뉴 씬에서 인게임 픽셀 노드를 import하지 말 것** — 시각 톤 충돌 방지
- **인게임에서 SVG path 캐릭터 사용 금지** — 픽셀만
- **수치는 추정 금지** — 모두 `ORIGINAL_GAME_ANALYSIS.md`의 라인 번호 명시
- **카메라 follow는 유지** (사용자 결정 — 2026-05-21)

---

## 3. 사용자 의사결정 (사전 확정 — 2026-05-21)

각 Phase Planner는 SPEC.md에 다음 결정사항을 그대로 복사한다.

| # | 항목 | 결정 |
|---|---|---|
| 1 | 카메라 | **카메라 follow 유지** (원본은 고정 640×400이지만, iOS는 1024×768 + 플레이어 추적 유지). 단, 맵 자체 크기는 32×20 원본 동일 |
| 2 | 박병장 SergeantParkNode | **유지** (Sprint 7 산물 보존) + 원본 박병장 이스터에그(비행기/폭탄/수간호사 5초 도주) 흐름 결합. iOS 고유 컷씬 후 원본 단계 진행 |
| 3 | EnemyNode(이교수) 자식 시각 | **제거** — 성적표/Hello PPT/클립 자식 노드 모두 삭제. 16×20 픽셀 + 청진기 투척만 |
| 4 | iOS 고유 이펙트 (콤보 팝업/마일스톤/5초 긴박감/sparkle/카운트다운) | **픽셀 톤으로 변환해서 유지**. 콤보 팝업 → 8-bit 폰트, sparkle → 픽셀 입자, 마일스톤 → 픽셀 배너 |
| 5 | BGM/SE | **유지** (Sprint 8까지 산물 보존). 단 픽셀 톤과 어색하지 않은 범위 내 |
| 6 | dpad 조작 | **유지** — 원본 키보드 ↔ iOS dpad 매핑은 `DPadNode`가 그대로 |
| 7 | 캐릭터 5명 매핑 | 원본 jung/geon/im/lee/kim 5종을 iOS 5명 캐릭터 ID와 동일 정렬. Phase A Planner가 정확한 매핑표 확정 |

---

## 4. Phase 상세

### Phase A — 픽셀 시각 노출

**범위**
- `PlayerNode.swift`에서 SVG 풀바디 자식(`CharacterFullBodyNode`) 부착 제거
- 대신 `PixelSpriteRenderer`로 만든 SKSpriteNode 자식 부착
- 캐릭터 ID → PixelSprite 매트릭스 매핑 (원본 §2 분석 표 그대로)
- 4방향(상하좌우) 텍스처 캐싱

**변경 파일**
- `PlayerNode.swift` (수정)
- `CharacterFullBodyNode.swift` (사용처 제거)

**변경 금지**
- `PixelSprite.swift`, `PixelPalette.swift`, `PixelSpriteRenderer.swift` 본체 (이미 byte-equal 이식 완료)
- 메뉴 모든 씬·노드

**합격 기준**
- 인게임 진입 시 5명 캐릭터 모두 16×20 픽셀 스프라이트로 표시됨
- 메뉴 카드는 카툰 그대로 (시각 분리 유지)
- dpad 4방향 입력 시 해당 방향 텍스처 전환 확인
- 가중 평균 7.5 이상

---

### Phase B — 맵 크기·카메라 정합

**범위**
- 현재 iOS 48×24 타일(960×480pt) → 원본 32×20 타일로 축소
- TILE=20pt × SCALE=2 = 40pt 표시 (Planner가 시뮬레이터 캡처로 최종 확정)
- `MapNode.swift` 신규 생성 (32×20 컨테이너)
- worldNode 크기 = TILE × SCALE × MAP_W/H 일관 산식
- 카메라 follow 로직은 유지하되 맵 가장자리 클램프

**변경 파일**
- `GameScene+Setup.swift` (월드 크기·카메라 클램프)
- `MapNode.swift` (신규)
- `GameConfig.swift` (TILE/MAP_W/MAP_H/SCALE 상수)

**변경 금지**
- 메뉴 씬, PlayerNode 시각

**합격 기준**
- 맵이 32×20 그리드로 보임 (Planner가 시뮬레이터 캡처 첨부)
- 카메라가 플레이어를 추적하되 맵 밖으로 나가지 않음
- 가중 평균 7.5 이상

---

### Phase C — 맵 빌더 3종 (벽)

**범위**
- 원본 `buildMap`(game.js L261~) 의 easy/hard 두 맵 데이터를 그대로 추출
- normal 난이도는 원본대로 hard 맵 공유
- `WallTileNode.swift` 신규 — 벽 픽셀 타일(20×20)
- 충돌 카테고리 추가 (`PhysicsCategory.wall`)
- 플레이어/빌런/투척물이 벽에 막히도록

**변경 파일**
- `MapNode.swift` (맵 빌드 메서드)
- `WallTileNode.swift` (신규)
- `PhysicsCategory.swift` (wall 카테고리 추가)
- `GameScene+Setup.swift` (난이도별 맵 호출)

**변경 금지**
- Phase A·B 산물

**합격 기준**
- easy/normal/hard 3종 맵이 원본 좌표대로 빌드됨
- 플레이어가 벽 통과 불가
- F 투척물이 벽에서 막힘 (또는 사라짐 — 원본 거동 추종)
- 가중 평균 7.5 이상

---

### Phase D — 수간호사 패트롤 + F 투척

**범위**
- 현재 iOS 직선 추적 + 자동 발사 loop → **4지점 사각 순환 패트롤**로 재작성
- 텔레그래프: 빨강 ! 마커 0.4초 깜빡임 → F 투척
- F 스프레드: ±15° (원본 정확 수치)
- F 속도: 난이도별 표 적용 (easy/normal/hard 40/60/100 px/s)
- 매혹 상태(`isImCharmed`) 체크 — 매혹 시 F가 A로 변환

**변경 파일**
- `NurseAvatarNode.swift` (인게임 부분만 — 메뉴 SVG path는 보존)
- `FProjectileNode.swift` (신규)
- `AItemNode.swift` (신규)
- `GameScene+Setup.swift` (스폰·충돌)

**변경 금지**
- 메뉴 카드의 수간호사 시각
- Phase A·B·C 산물

**합격 기준**
- 수간호사가 4지점 사각 순환만 함 (추격 0)
- 텔레그래프 0.4초 후 정확히 F 투척
- 매혹 시 F → A로 시각 전환
- 가중 평균 7.5 이상

---

### Phase E — 음표·F·A·변기·청진기 픽셀 + 스폰

**범위**
- `NoteNode.swift` 픽셀 8 fillRect 좌표 1:1 (원본 §5 drawNote)
- 변기 픽셀(원본 drawToilet)
- 청진기 14×8 픽셀
- 스폰 인터벌·TTL·최대 개수 모두 원본 표 (난이도별)
- 콤보 가산 (≥3 +2, ≥5 +3, ≥7 +4)
- A 수집 ×2, 변기 ×2

**변경 파일**
- `MusicNoteEmitterNode.swift` (전면 재작성)
- `NoteNode.swift` (픽셀 좌표)
- `ToiletNode.swift` (신규)
- `StethoscopeNode.swift` (픽셀 매트릭스)
- `GameScene+Setup.swift` (점수 공식)

**변경 금지**
- Phase A·B·C·D 산물

**합격 기준**
- 음표/변기/청진기가 모두 원본 픽셀로 보임
- 난이도별 스폰 수·TTL 원본 표 일치 (Planner가 표 첨부)
- 콤보 가산 공식 정확
- 가중 평균 7.5 이상

---

### Phase F — 이교수·석조무사 픽셀 + AI

**범위**
- 이교수: 8자 패트롤 70 px/s, 청진기 freezeDuration 2000ms, 상 난이도만
- 석조무사: 4지점 순환 55 px/s, 하/중 난이도만
- `EnemyNode.swift` 의 자식 시각(성적표/Hello PPT/클립) **모두 제거** (사용자 결정 3번)
- 이교수 청진기 투척: 토스트 1초 → 회전 투사체 → 정지 2초

**변경 파일**
- `EnemyNode.swift` (자식 제거, 픽셀만)
- `ProfessorNode.swift` (인게임 사용분 — 픽셀 + 8자 패트롤)
- `StoneGuardNode.swift` (픽셀 + 4지점 순환)
- `StethoscopeNode.swift` (회전 액션)
- `GameScene+Setup.swift` (난이도별 활성 매트릭스)

**변경 금지**
- 메뉴 카드의 이교수/석조무사 SVG
- Phase A~E 산물

**합격 기준**
- 이교수가 8자 패트롤, 청진기 정확히 투척
- 석조무사가 4지점 순환만, 자식 시각 0개
- 난이도별 활성 매트릭스 원본 표 일치
- 가중 평균 7.5 이상

---

### Phase G — 박병장 이스터에그 3단계

**범위**
- 트리거: 석조무사 접촉 (easy/normal)
- 1단계: 게임 루프 정지 + iOS 박병장 컷씬(SergeantParkNode 활용)
- 2단계: 컷씬 완료 후 비행기 출동 + 폭탄 투하
- 3단계: F 전멸 + 수간호사 도주 5초 (`startChiefFlee`)
- 폭탄 섬광 420ms (`BombFlashNode`)

**변경 파일**
- `SergeantParkNode.swift` (트리거 조건 + 다음 단계 연결)
- `AirplaneNode.swift` (픽셀 + 폭탄 투하 액션)
- `BombFlashNode.swift` (픽셀 톤 변환)
- `NurseAvatarNode.swift` (도주 5초 상태)
- `GameScene+Setup.swift` (전체 시퀀스)
- `AirforceOverlayNode.swift` (있다면 — 픽셀 톤 정합)

**변경 금지**
- 메뉴 모든 시각
- Phase A~F 산물

**합격 기준**
- 석조무사 접촉 시 정확히 3단계 시퀀스 실행
- 폭탄 후 F 전멸 + 수간호사 5초 도주
- iOS 컷씬 → 원본 단계 자연스럽게 이어짐
- 가중 평균 7.5 이상

---

### Phase H — 컷씬 5종

**범위**
- intro: 시작 250ms (캐릭터별 대사)
- mid1: timeLeft ≤ 30 (캐릭터별)
- mid2: timeLeft ≤ 15
- introStoneGuard: intro 후 easy/normal (석조무사 등장 예고)
- introProfessor: intro 후 hard (이교수 등장 예고)

**변경 파일**
- `IntroCutsceneNode.swift` (신규)
- `MidCutsceneNode.swift` (신규)
- `IntroVillainCutsceneNode.swift` (신규)
- `GameScene+Setup.swift` (트리거 시점)
- `CutsceneOverlayNode.swift` (이미 있음 — 픽셀 톤 정합)

**변경 금지**
- Phase A~G 산물

**합격 기준**
- 5종 컷씬이 정확히 트리거되고 텍스트 원본 일치
- 픽셀 톤 일관성 유지
- 가중 평균 7.5 이상

---

### Phase I — 난이도·점수·콤보 수치 정합

**범위**
- `GameConfig.swift`에 원본 §6 난이도 표 그대로:
  - baseSpeed / maxSpeed / notes / noteTtl / obstacles / obsBaseSpeed / obsMaxSpeed / stun / spawnInterval / maxObstacles / throwBurst
- 빌런 활성 매트릭스 (수간호사/이교수/석조무사/박병장)
- 목표점수: easy 30 / normal 50 / hard 60
- 점수 공식: combo ≥3 +2, ≥5 +3, ≥7 +4
- 5명 스킬 수치: jung 22초 쿨다운 3타일 / geon 20초 6타일 반경 / im 1회 1500ms 매혹 / lee 22초 워프 500ms 무적

**변경 파일**
- `GameConfig.swift` (수치 상수)
- `GameState.swift` (콤보 공식)
- `GameScene+Setup.swift` (스폰 인터벌 적용)
- 5명 SkillSystem (이미 1:1이라 수치만 정합)

**변경 금지**
- Phase A~H 산물

**합격 기준**
- 모든 수치가 원본 표 일치 (Planner가 표 첨부)
- 5명 스킬 쿨다운/지속시간 정확
- 목표점수 도달 시 승리 조건 발동
- 가중 평균 7.5 이상

---

### Phase J — HUD·iOS 이펙트 픽셀 톤 변환

**범위**
- HUD: 점수/시간/콤보 라벨을 8-bit 폰트로
- `HUDSkillSlotNode`: 픽셀 톤 배지
- `ComboPopupNode`, `ComboBreakNode`, `ScorePopupNode`: 8-bit 폰트
- `SparkleEffectNode`: 픽셀 입자
- 5초 긴박감 비네트: 픽셀 톤 inset
- `CountdownNode`: 픽셀 숫자

**변경 파일**
- `HUDNode.swift`
- `HUDSkillSlotNode.swift`
- `ComboPopupNode.swift`, `ComboBreakNode.swift`, `ScorePopupNode.swift`
- `SparkleEffectNode.swift` (인게임 사용분)
- `CountdownNode.swift`
- `HitFlashNode.swift`
- `BombFlashNode.swift` (Phase G에서 일부 처리됨)

**변경 금지**
- 메뉴 사용 SparkleEffectNode·CountdownNode (메뉴 컨텍스트는 카툰 유지)
- Phase A~I 산물

**합격 기준**
- 인게임 모든 UI가 8-bit 픽셀 톤
- 메뉴 UI는 카툰 톤 유지 (시각 분리)
- 가중 평균 7.5 이상

---

## 5. 평가 기준 (모든 Phase 공통)

각 Phase Evaluator는 다음 5축으로 채점하고 가중 평균을 낸다:

| 축 | 가중치 | 합격선 |
|---|---|---|
| Swift/SpriteKit 패턴 | 20% | 7.0 |
| 원본 1:1 일치도 (좌표·수치·AI) | 30% | 7.5 |
| 성능 (60fps, 메모리) | 15% | 7.0 |
| 시각 일관성 (픽셀 톤) | 20% | 7.5 |
| 기능 완성도 (합격 기준 충족) | 15% | 8.0 |

**가중 평균 7.5 이상 → Phase 합격**.

---

## 6. 진행 로그 위치

각 Phase 합격 시 `DESIGN_RENEWAL_STATE.md`의 "Sprint 10 — 진행 로그" 섹션에 한 줄 추가:

```
- Phase X ✅ 합격 (점수 X.X/10, 시도 X회, YYYY-MM-DD)
```

---

## 7. 트리거 명령

- `Sprint 10 진행해줘` → 다음 미합격 Phase 자동 진행
- `Sprint 10 Phase X 진행해줘` → 특정 Phase 강제 실행

자세한 자동 실행 절차는 `CLAUDE.md`의 "Sprint 10 Phase 모드" 섹션 참고.
