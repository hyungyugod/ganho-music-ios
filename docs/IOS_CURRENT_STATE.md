# 현재 iOS 인게임 상태 분석 (Sprint 9 사전 분석)

> 작성: 2026-05-21
> 분석 대상: `/Users/hg/Desktop/ganho-music-ios/GanhoMusic/GanhoMusic Shared/`
> 비교 기준: `/Users/hg/Desktop/ganho-music-ios/docs/ORIGINAL_GAME_ANALYSIS.md`
> 사용자 결정: 인게임은 원본과 **1:1 픽셀 게임으로 재현**, 메뉴/선택창은 **보존**, 조작은 **dpad 유지**.

---

## 0. 요약

- **보존**: 27 파일 (메뉴 씬 6 + 메뉴 노드 12 + 모델 9개)
- **재작성**: 13 파일 (인게임 노드/시스템 — 시각/AI/스폰/맵)
- **신규**: 8 파일 추정 (Map/Tile / Stethoscope-orbit / A 투사체 분리 / Bomb 폭탄 / Cutscene 5종 / Audio sine / Particles)
- **영향 LOC**: 약 ~3,200 (재작성 2,400 + 신규 800), 보존 ~6,000

핵심 충돌점:
1. **맵 크기 불일치** — iOS: `48×24` 타일 (960×480pt), 원본: `32×20` 타일 (640×400pt). 원본 1:1을 따르려면 *맵 절반으로 줄이거나* worldNode 좌표계를 1.5배 스케일링.
2. **수간호사 AI 완전 상이** — iOS는 **직선 추적 + F 자동 발사 루프** (SpawnSystem.fireProjectile), 원본은 **사각 패트롤만 + 텔레그래프 0.4s → F 투척** (추격 안 함). 완전 다른 AI 모델.
3. **F 텔레그래프 없음** — iOS는 `projectileFireInterval` 타이머만, 원본은 빨강 `!` 마커 깜빡임 후 발사.
4. **A 투사체 분리** — iOS는 ProjectileNode.isEnchanted 플래그로 같은 노드 색만 바꿈, 원본은 type='A' 별도 스프라이트.
5. **카메라 follow** — iOS는 worldNode 위 카메라 follow, 원본은 640×400 고정 캔버스 (월드 = 화면). 픽셀 1:1 재현하려면 follow 폐기.
6. **CharacterFullBodyNode가 카툰 SVG-스타일** — Sprint 8/9에서 만든 SKShapeNode 풀바디. PixelSprite 16×20 매트릭스가 이미 PixelSprite.swift에 byte-equal 이식되어 있는데 PlayerNode가 `color = .clear`로 차단 후 카툰 풀바디를 자식으로 부착하고 있어 **픽셀 캐릭터가 화면에 표시 안 됨**.

---

## 1. 메뉴 / 선택창 — 보존 영역 (Shield)

### 1.1 Scenes — 6개

| 파일 | LOC | 역할 | 보존 이유 | 인게임 호출 인터페이스 |
|---|---|---|---|---|
| `Scenes/StartScene.swift` | 325 | 첫 진입 — NurseAvatarNode 큰 그림 + 시작 버튼 + 음표 emitter | 사용자 명시: 메뉴 보존 | `CharacterSelectScene.newCharacterSelectScene()`만 호출 |
| `Scenes/CharacterSelectScene.swift` | 738 | 5명 캐릭터 스와이프 페이지 | 사용자 명시 | `SkillExplanationScene(characterID:)` 또는 `DifficultySelectScene(characterID:.kim)` 호출 |
| `Scenes/SkillExplanationScene.swift` | 618 | 4명(kim 제외) 스킬 설명 카드 | 사용자 명시 | `DifficultySelectScene(characterID:)` 호출 |
| `Scenes/DifficultySelectScene.swift` | 495 | 3 난이도 카드 + 시작 버튼 | 사용자 명시 | **`GameScene.newGameScene(characterID:difficulty:)` 호출 — 인게임 진입점, 인터페이스 보존 필수** |
| `Scenes/ResultScene.swift` | 817 | 점수/등급/통계/졸업장 표시 | 사용자 명시 | GameScene이 `presentScene(resultScene)`으로 진입 |
| `Scenes/ScoreboardScene.swift` | 510 | 캐릭터×난이도 매트릭스 표 | 사용자 명시 | ResultScene/StartScene이 진입 |

### 1.2 메뉴 전용 Node — 18개

| 파일 | LOC | 역할 |
|---|---|---|
| `Nodes/NurseAvatarNode.swift` | 374 | 메인 화면 김간호 큰 그림 (SKShapeNode SVG path 변환) |
| `Nodes/CharacterFaceNode.swift` | 1107 | 5명 × 4방향 얼굴 — 카드/선택 화면 전용 |
| `Nodes/CharacterCardNode.swift` | 483 | 카드 본체 (NIKKE 스타일) |
| `Nodes/DifficultyCardNode.swift` | 337 | 난이도 카드 |
| `Nodes/MusicNoteEmitterNode.swift` | 117 | 메뉴 장식 음표 파티클 (인게임 음표와 무관) |
| `Nodes/GradientBackgroundNode.swift` | 133 | 메뉴 그라데이션 배경 |
| `Nodes/AccentLineNode.swift` | 47 | 메뉴 헤더 액센트 라인 |
| `Nodes/GlassPillNode.swift` | 78 | 메뉴 버튼 (BEST/PLAYS/뒤로) |
| `Nodes/DarkContextChipNode.swift` | 112 | 메뉴 컨텍스트 칩 |
| `Nodes/PrimaryButtonNode.swift` | 124 | 메뉴 주요 버튼 |
| `Nodes/BackButtonNode.swift` | 70 | 뒤로 버튼 |
| `Nodes/GlowingTitleNode.swift` | 78 | 메뉴 타이틀 |
| `Nodes/StoryBoxNode.swift` | 69 | 메뉴 스토리 박스 |
| `Nodes/DiplomaOverlayNode.swift` | 374 | 졸업장 오버레이 (ResultScene) |
| `Nodes/CutsceneOverlayNode.swift` | 172 | 컷씬 카드 (재사용 가능 — 인게임에도 사용) |
| `Nodes/ToastLabelNode.swift` | 89 | 토스트 라벨 (재사용 가능) |
| `Nodes/SparkleEffectNode.swift` | 67 | 수집 sparkle (재사용 — 시각 폴리싱 보존) |
| `Nodes/HitFlashNode.swift` | 46 | 피격 플래시 (재사용 — 시각 폴리싱 보존) |

### 1.3 Models / Repositories — 13개

다음은 비-시각 도메인 — 전부 보존:

- `Models/CharacterID.swift` (123) — 5명 enum + skill / displayName / 카드 시각 메타
- `Models/Difficulty.swift` (112) — 3난이도 enum + 카드 색
- `Models/PlayerSkill.swift` (131) — 4스킬 enum + 쿨다운/지속시간
- `Models/Direction.swift` (37) — front/back/left/right (메뉴 캐릭터용)
- `Models/GameStats.swift` (16) — 누적 통계
- `Models/PixelPalette.swift` (141) — **원본 팔레트 byte-equal 이식, 보존**
- `Models/PixelSprite.swift` (467) — **원본 16×20 매트릭스 byte-equal 이식, 보존** ✅
- `Repositories/*` (5개, 336) — UserDefaults 영속 계층, 전부 보존
- `Config/PhysicsCategory.swift` (22) — 보존 (단, stoneGuard/bonus/stethoscope 카테고리 *확장* 필요)
- `Config/GameState.swift` (20) — 상태 머신, 보존

### 1.4 메뉴 입장 시 인게임에 넘어오는 데이터 (인터페이스)

**DifficultySelectScene → GameScene:**
```swift
GameScene.newGameScene(characterID: CharacterID, difficulty: Difficulty)
```
이 시그니처는 **절대 변경 금지**. Sprint 9에서 GameScene을 완전히 갈아엎어도 이 factory 메서드 시그니처는 보존해야 메뉴 회귀 0.

**GameScene → ResultScene:**
```swift
ResultScene.newResultScene(score, bestScore, isNewBest, stats, characterName, difficulty, isNewGraduation, graduatedAt)
```
이 시그니처도 보존. 점수/등급/졸업 데이터 모델은 그대로 사용.

---

## 2. 인게임 — 재작성 / 교체 대상 (Burn)

### 2.1 핵심 시스템 — `GameScene` 본체 (858 LOC) + `GameScene+Setup` (544 LOC)

| 항목 | 현재 구현 | 재작성 규모 | 원본 매핑 |
|---|---|---|---|
| **씬 진입점 (`didMove`)** | 카메라 follow + worldNode 자식 트리 | 부분 — 카메라 follow 폐기 (원본은 고정 캔버스). `setupBackground` `setupCamera` `setupDPad` `setupHUD` `setupSkillButton` 보존 | 원본 §0 캔버스 640×400 고정 |
| **컷씬 분기** (showIntroCutscene/showStoneGuardWarningCutscene/showProfessorWarningCutscene) | CutsceneOverlayNode 1종 재사용, 텍스트만 분기 | 부분 — 5종 컷씬(`intro`/`mid1`/`mid2`/`introStoneGuard`/`introProfessor`)으로 확장 | 원본 §7.6 |
| **카운트다운** (showCountdown) | dim 오버레이 + CountdownNode + onTick/onGo | **보존** — 원본은 직접적 카운트다운 없음, 250ms 후 intro 컷씬만. iOS는 게임 시작 톤으로 유지 권장 | (원본 무관) |
| **update 루프** | 6 시스템 (시간/스킬/입력/플레이어/적/HUD/콤보) | 부분 — 적/스킬은 보존, *적 직선 추적*은 **폐기**. 텔레그래프 상태 머신 신규 | 원본 §3.1.9 |
| **수간호사 추적** (enemy.update with target=player.position) | 직선 추적 AI | **폐기** — 원본은 패트롤만 (4지점 사각/Z패턴) | 원본 §3.1.5 |
| **AIRFORCE 이스터에그** | airforceTriggered 1회 가드 + AirforceOverlayNode + AirplaneNode + 수간호사 도주 5초 | **보존 가능, but 흐름 재정렬 필요** — 원본은 *오버레이 → 사용자 클릭 → 비행기 등장 → 폭탄* 3단계, iOS는 *접촉 즉시 모든 게 자동 진행* | 원본 §3.4 |
| **콤보 마일스톤 폴링** | 6-10/6-11/6-12 (3/5/10/20) | **보존** — iOS 고유 시각 폴리싱, 원본에 없지만 유지 | (iOS only) |
| **5초 긴박감** (tensionWindow) | BGM rate 1.0→1.15 보간 + HUD 깜빡임 + 매초 햅틱 | **보존** — iOS 고유 시각 폴리싱 | (iOS only) |
| **endGame** | scoreSystem/statsRepo/perDiffRepo/graduationRepo 흐름 → ResultScene | **보존** — 영속 계층 인터페이스 그대로 | (도메인 보존) |
| **맵 빌더 (`setupMap`)** | `addOuterWalls` + `addCheckerboardFloor` + 난이도별 (`addCentralPillar`/`addNormalMap`/`addHardMap`) | **재작성** — 맵 크기 48×24 → 32×20 + 외곽 1타일 벽 + 원본 §1.2 빌더 3종 byte-equal 이식 | 원본 §1 |
| **`addNormalMap`/`addHardMap` 좌표** | iOS는 48×24 거울 대칭 옵션 C 좌표 | **재작성** — 원본 32×20 좌표 그대로 (좌상/우상/좌하/우하 4방 + 문 + 중앙 기둥) | 원본 §1.2.2 / §1.2.3 |

**보존 vs 폐기 라인 결정:**

iOS에서 **보존**할 수 있는 것:
- 메뉴 진입 인터페이스 (newGameScene factory)
- `gameState` 머신 (.cutscene/.countdown/.playing/.gameOver)
- ResultScene 진입 흐름
- HighScoreRepository / StatisticsRepository / PerDifficultyScoreRepository / GraduationRepository
- HapticsManager / AudioManager / BGMPlayer 인터페이스 (사운드는 원본 사인파로 교체 권장)
- 콤보 폴링 폴리싱 (3/5/10/20)
- 5초 긴박감 (선택사항)

**폐기**할 것:
- 카메라 follow (worldNode 큰 맵 + 카메라 = 폐기, 원본은 캔버스 = 화면)
- EnemyNode 직선 추적
- SpawnSystem.fireProjectile (텔레그래프 없는 자동 발사)
- CharacterFullBodyNode (카툰 SVG, 픽셀과 안 맞음)
- 외곽 라운드 보더 (Sprint 3 시각)
- 체크보드 바닥 (원본은 단색 floorA/floorB 체크 — 사실상 같지만 색 토큰 교체 필요)

### 2.2 PlayerNode (318 LOC) — 재작성 (부분)

**현재 구현 방식:**
- `SKSpriteNode` 상속, `physicsBody` 16×20 dynamic
- `texture = PixelSprite.data(...)` (PNG 우선, fallback 픽셀) — 첫 텍스처는 down/idle
- `updatePixelDirection(velocity)` + `tickWalkFrame(deltaTime:isMoving:)` 매 프레임 호출
- **`color = .clear` 본체 시각 차단** + `CharacterFullBodyNode` 자식 부착 (카툰 SVG)
- D-Pad → currentDirection → physicsBody.velocity 변환
- 무적/동결 플래그

**원본 차이:**
- 원본은 `state.player.x/y` + `isWallAt(map, ...)` 픽셀 AABB 충돌. SKPhysicsBody 아님.
- 원본은 walk 프레임 0.15s마다 교차 + 1픽셀 보빙. iOS는 `pixelWalkFrameInterval` 보유 — 값만 맞추면 OK.
- 원본은 oy = y - 24 (스프라이트 머리 중앙을 player 좌표에). iOS는 SKSpriteNode 중심.

**재작성 범위:**
- `color = .clear` + `attachFullBody` **삭제** → PixelSprite 텍스처 직접 노출 (그리고 size 32×40 시각).
- physicsBody 정책은 보존 (수정사항 적음).
- Sprint 4 PNG fallback은 폐기, 항상 픽셀 텍스처 사용.
- `loadTexture`의 PNG 우선 분기 → 폐기.
- speedMultiplier 폐기 (원본 §2.7: 캐릭터별 능력치 동일).

### 2.3 EnemyNode (수간호사, 278 LOC) — **전면 재작성**

**현재 구현 방식:**
- `SKSpriteNode` + 픽셀 텍스처 `nurseChiefData` (이미 원본 byte-equal)
- **직선 추적 AI** — `update(deltaTime:, targetPosition:, speedT:)`이 player 위치 단위벡터 × 보간속도
- 도주 모드 5초 (AIRFORCE 이스터에그)
- `startFleeing(duration:, onEnd:)` 콜백
- `setupVisualOverlay`: SKShapeNode 헬로/차트/클립 자식 (Sprint 7-F 시각 보강)
- **`color = .clear` 본체 PixelSprite 차단** (Sprint 8-G) — 시각 자식만 보임 = 픽셀이 안 보임
- Sprint 9-C 시각 자식 1.4배 확대

**원본 차이 (정정 필요한 큰 항목들):**

| 항목 | iOS | 원본 |
|---|---|---|
| AI 모델 | 직선 추적 | 4지점 사각 패트롤만 (추격 0) |
| F 발사 위치 | SpawnSystem.fireProjectile에서 enemy.position | 본인 메서드에서, 텔레그래프 0.4s 후 |
| F 발사 텔레그래프 | 없음 | 빨강 ! 마커 깜빡임 |
| 매혹 시 시각 | 자식 노드 없음 | 안경 렌즈 위 3×3 핑크 하트 |
| 본체 시각 차단 | color=.clear | 픽셀 직접 노출 |
| 시각 자식 보강 | SKShape 헬로/차트/클립 (Sprint 7-F) | 없음 |
| 패트롤 속도 | 60~110 (easy), 170~290 (normal), 200~340 (hard) | **40 (easy), 60 (normal), 100 (hard)** — 시간 보간 없음 |

**재작성 규모:** 전면 (라인 ~90%). PixelSprite 시각만 보존. 시각 보강 자식 + 추적 AI + 도주 5초는 폐기.

### 2.4 ProfessorNode (이교수, 282 LOC) — **부분 재작성**

**현재 구현 방식:**
- SKAction.move 기반 4 waypoint 무한 순환 (원본과 일치, 좌표만 다름)
- `throwStethoscope` — player 위치 향한 단위벡터 × 220px/s
- 동시 4발 가드, 발사 주기 보간 (2.5→1.4)
- `setupVisualOverlay` (SKShape 청진기 disc/tube 자식, Sprint 7-F)
- **`color = .clear` PixelSprite 차단** (Sprint 8-G)

**원본 차이:**
- 원본 waypoint: `(120,100) → (520,280) → (520,100) → (120,280)` 8자(figure-8). iOS의 `professorWaypoints`는 다른 좌표.
- 원본은 텔레그래프 0.4s — iOS는 즉시 발사.
- Sprint 7-F 시각 보강 자식 폐기 (원본에 없음).
- color=.clear → 픽셀 노출.

**재작성 규모:** 중간. 패트롤 좌표/속도/텔레그래프만 정정 + 시각 차단 해제.

### 2.5 StoneGuardNode (석조무사, 131 LOC) — **부분 재작성**

**현재 구현 방식:**
- SKAction.move 4 waypoint (시계방향)
- **PixelSprite 없음** — `color = .ganhoStoneGuardLight` 단색 + SKShape 갑옷/일자눈 자식
- Sprint 8-G에서 `color = .clear`로 본체 시각 차단

**원본 차이:**
- 원본은 PixelSprite 16×20 매트릭스 보유 (game.js L3120-3169) — **iOS PixelSprite에 미이식**.
- 원본 waypoint: `leftX=80 (TILE*4), rightX=540, topY=80, bottomY=300`. iOS는 `(200,100)/(760,100)/(760,380)/(200,380)` (48×24 맵 좌표).
- 속도: iOS 55 (원본과 일치) ✅
- 원본은 벽 타일이면 BFS 없이 인접 빈 셀 클램프. iOS는 직접 waypoint.

**재작성 규모:** 중간. PixelSprite.stoneGuardData(...) **신규 함수 추가** + 시각 자식 폐기 + waypoint 좌표 정정.

### 2.6 SergeantParkNode (박병장, 160 LOC) — **재작성**

**현재 구현 방식:**
- SKShape 6종 자식 (얼굴/캡/선글라스/계급장/그림자/몸통) — Sprint 7-F 작품
- `makeIntroCloseup()` 정적 메서드 (Sprint 8-G 컷씬용)
- physicsBody 없음

**원본 차이:**
- 원본은 박병장 *비행기*만 있고 박병장 캐릭터 노드는 없음. iOS의 박병장 노드는 Sprint 7/8 창작.
- **사용자 결정**: 원본 그대로 = 박병장 캐릭터 노드 폐기, 비행기 + 폭탄만 사용.

**재작성 규모:** 전면 폐기 OR 보존 (사용자 컷씬 정체성 우선). §8 리스크에 적음.

### 2.7 AirplaneNode (190 LOC) — **재작성**

**현재 구현 방식:**
- SKSpriteNode + SKShape 6 자식 (Sprint 8-G — fuselage/wings/tail/cockpit/propeller/contrail)
- 좌→우 가로지르기 SKAction.sequence (2.0초, 자가 소멸)

**원본 차이:**
- 원본 비행기 스프라이트: 16×5 픽셀 도트, SCALE=3 → 48×15 화면 (원본 §3.4.2)
- 색: A(동체/날개) 회색 `#aab3c7`, W(창문) `#e2e7ef`
- 좌→우 320px/s × 2.4초 가로지름

**재작성 규모:** 부분. SKShape 자식 폐기, PixelSprite.airplaneData 신규 추가, 속도/지속 시간 정정.

### 2.8 ProjectileNode (F 투사체, 103 LOC) — **부분 재작성**

**현재 구현 방식:**
- 22×22pt 시각 자식 (라운드 사각형 + "F" 라벨 + -12° 회전, Sprint 3 v2)
- physicsBody 16×16 보존
- `applyEnchanted()` 색만 .ganhoPinkNote로 갈아 끼움

**원본 차이:**
- 원본 F 스프라이트: 12×12 픽셀 도트 (외곽 섀도 + 흰 테두리 + 빨간 F)
- A는 별도 스프라이트 (외곽 + 흰 테두리 + 분홍 A 다리/머리)
- iOS는 텍스트 라벨 "F" — 원본은 픽셀로 그린 F.

**재작성 규모:** 부분. 시각 자식 폐기, PixelSprite.fData / aData 신규 추가, fillColor → texture 교체.

### 2.9 StethoscopeNode (52 LOC) — **재작성**

**현재 구현 방식:**
- SKSpriteNode 단색 `.ganhoPixelChiefShoes`
- SKAction.repeatForever rotate

**원본 차이:**
- 원본 청진기 스프라이트: 14×8 도트, SCALE=2 → 28×16 화면 (원본 §3.2.6)
- 자체 회전 `now/100 % 2π` (시간 기반)
- 튜브/벨/림 3색

**재작성 규모:** 전면. PixelSprite.stethoscopeData 신규 + 회전 보존.

### 2.10 NoteNode (82 LOC) — **재작성**

**현재 구현 방식:**
- 16×16 본체 .clear
- 자식 3개: 글로우(SKShape blendMode add) + 코어(원, 골드) + 펄스 SKAction (Sprint 3 v2)

**원본 차이:**
- 원본 음표: 12×12, **8분 음표** (머리 + 기둥 + 깃발 3단)
- bob 애니메이션 `sin((now/220) + bobSeed) * 1.2`
- TTL 만료 시 마지막 1초 120ms 깜빡임

**재작성 규모:** 전면. PixelSprite.noteData 신규 + 픽셀로 8분 음표 그림 + bob 추가.

### 2.11 ToiletNode (60 LOC) — **부분 재작성** (가까움)

**현재 구현 방식:**
- PixelSprite.toiletData() 이미 16×16 (의미 영역) + transparent padding으로 16×20
- PhysicsBody bonus 카테고리
- applyLifetime 8초 fadeOut

**원본 차이:**
- 원본은 SCALE=2 32×32 화면. iOS는 PixelSprite renderer 출력 32×40 (16×20 매트릭스 × 2배)
- 원본 변기 색: 흰/연회색/옅은파랑/검정 — iOS는 ganhoCoralAccent 코랄 물(다르게 그림)

**재작성 규모:** 작음. 픽셀 데이터 그대로 + 팔레트 정정.

### 2.12 HUDNode (255 LOC) + HUDSkillSlotNode (141) — **부분 재작성**

**현재 구현 방식:**
- 4슬롯 (TIME/SCORE/COMBO/PLAYER), navy 알약 + Jua 골드 라벨 (Sprint 3 v2)
- TIME 진행바 + 5초 경고 색 swap
- HUDSkillSlot (좌하단 스킬 진행률)

**원본 차이:**
- 원본 HUD: 상단 가로 5칸 (Time / Score / Combo / Best / Skill with conic-gradient 쿨다운 링)
- 원본은 BEST 라벨 보유, iOS는 PLAYER (캐릭터 이름)로 대체
- 원본은 Skill 슬롯이 HUD에 통합, iOS는 좌하단 별도

**재작성 규모:** 부분. v2 시각 톤 유지하되 PLAYER → BEST 라벨 추가 후보 (§8 리스크).

### 2.13 DPadNode (136 LOC) — **보존**

원본 §11.4: iOS 포팅 시 D-pad만 사용. 보존 완료. 단, 화면 좌하단 SkillButton과 위치 정합 필요.

### 2.14 SkillButtonNode (122) + HUDSkillSlotNode (141) + SkillSystem (334) — **보존**

스킬 4종 (dashClimb/bookClubRally/charmStudent/taiwanTrip)은 원본 §2.8과 정확히 매핑됨. 능력치/지속시간/쿨다운만 GameConfig 값을 원본 표(원본 §2.8)와 정확히 일치시키면 됨.

| iOS skill | 원본 chr | 원본 duration | 원본 cooldown | 원본 효과 |
|---|---|---|---|---|
| dashClimb | jung | 260ms | 22000ms | 3타일 돌진 + 앞 벽 1칸 분쇄 |
| bookClubRally | geon | 즉발(0) | 20000ms | 주변 6타일 음표 일괄 수집 |
| charmStudent | im | 1500ms | 게임당 1회 | F→A 전환 + 점수 2배 |
| taiwanTrip | lee | 500ms 무적 | 22000ms | 가장 먼 빈 타일 워프 |

iOS GameConfig 값이 위와 정확 일치하는지 확인 필요 (§4에 표).

### 2.15 ContactRouter (137) + ScoreSystem (68) — **보존**

물리 충돌 라우터 + 점수 계산 — 도메인 로직. 인터페이스 변화 0.

### 2.16 보조 시각 (재사용 가능) — **보존**

- `Nodes/SparkleEffectNode.swift` (67) — 수집 sparkle
- `Nodes/HitFlashNode.swift` (46) — 피격 플래시
- `Nodes/CountdownNode.swift` (129) — 3-2-1-GO
- `Nodes/ToastLabelNode.swift` (89) — 토스트
- `Nodes/CutsceneOverlayNode.swift` (172) — 컷씬 카드 (5종 분기 시 재사용)
- `Nodes/ScorePopupNode.swift` (111) — +1/+2
- `Nodes/ComboPopupNode.swift` (110) — x3/x5/x10/x20
- `Nodes/ComboBreakNode.swift` (93) — BREAK
- `Nodes/AirforceOverlayNode.swift` (55) — "나와라 박병장!" 오버레이
- `Nodes/BombFlashNode.swift` (42) — 폭탄 섬광
- `Nodes/PauseButtonNode.swift` (66) — 일시정지 placeholder

### 2.17 PixelSpriteRenderer (45) + PixelSprite (467) + PixelPalette (141) — **보존 + 확장**

이미 원본 byte-equal 이식. **추가 신규 데이터**만 필요:
- `stoneGuardData(direction:, frame:)` — 원본 §3.3.2
- `airplaneData()` — 원본 §3.4.2 (16×5 도트)
- `stethoscopeData()` — 원본 §3.2.6 (14×8 도트)
- `noteData()` — 원본 §4.1 (12×12 8분 음표)
- `fData()` / `aData()` — 원본 §5.1 / §5.2 (12×12)

renderer는 16×20 고정이라 위 비-표준 크기 데이터는 **renderer를 가변 크기 지원으로 확장**하거나 별도 helper 추가 필요.

---

## 3. 신규로 만들어야 할 노드

| 신규 파일 | 역할 | 원본 매핑 |
|---|---|---|
| `Nodes/MapTileNode.swift` 또는 `Systems/MapBuilder.swift` | 32×20 타일 맵 데이터 모델 + 벽 빌더 (easy/normal/hard 3종) | 원본 §1 buildMap |
| `Nodes/EnemyTelegraphNode.swift` | 수간호사 머리 위 빨강 `!` 텔레그래프 (120ms 깜빡임) | 원본 §3.1.11 |
| `Nodes/ProfessorTelegraphNode.swift` | 이교수 머리 위 코랄핑크 `!` 텔레그래프 | 원본 §3.2.9 |
| `Nodes/BombNode.swift` 또는 BombFlashNode 확장 | 폭탄 5초 카운트 + 폭발 22 파티클 + 셰이크 500ms | 원본 §3.4.3 dropBomb |
| `Nodes/CharmHeartNode.swift` | 매혹 시 수간호사 안경 렌즈 위 핑크 하트 오버레이 | 원본 §3.1.4 |
| `Systems/CutsceneSystem.swift` | 5종 컷씬(intro/mid1/mid2/introStoneGuard/introProfessor) 상태 머신 + 1회 표시 가드 (Set 추적) | 원본 §7.6 |
| `Systems/PatrolSystem.swift` 또는 EnemyNode 내부 | 수간호사 4지점 패트롤 (난이도별 점 개수 다름: easy 2점, normal 4점 Z, hard 4점 외곽) | 원본 §3.1.5 |
| `Managers/SineWaveAudio.swift` 또는 AudioManager 확장 | 사인파 효과음 (110/82, 220, 180, 120/90, 80/55, SCALE_FREQS 10음) | 원본 §9.5 |

---

## 4. Config / GameState — 수치 동기화

### 4.1 동기화 필요한 GameConfig 항목

| iOS 현재 | iOS 값 | 원본 값 | 동기화 필요? |
|---|---|---|---|
| `gameDuration` | 45 | 45 | ✅ 동일 |
| `tileSize` | 20 | 20 | ✅ 동일 |
| `mapColumns` × `mapRows` | **48 × 24** | **32 × 20** | ❌ **수정 필수** |
| `mapWidth` × `mapHeight` | 960 × 480 | 640 × 400 | ❌ |
| `playerWidth/Height` | 16 × 20 | 16 × 20 | ✅ |
| `playerBaseSpeed` (easy) | 140 | 140 | ✅ |
| `playerSpeedEnd[easy/normal/hard]` | 210/250/250 | 210/250/250 | ✅ |
| `enemySpeedStart[easy/normal/hard]` | 60/170/200 | (수간호사는 패트롤 속도 별도) | ❌ — 적이 추적 안 함, 패트롤 속도 별도 매핑 필요 |
| 수간호사 패트롤 속도 | (없음) | easy=40 / normal=60 / hard=100 | ❌ 신규 |
| 수간호사 4지점 패트롤 | (없음) | easy 2점 / normal Z / hard 시계방향 | ❌ 신규 |
| `enemySpeedEnd[easy/normal/hard]` | 110/290/340 | (적용 안 됨, 패트롤 일정 속도) | ❌ 폐기 |
| `noteMaxConcurrent[easy/normal/hard]` | 5/4/4 | 5/4/4 | ✅ |
| `noteLifetime[easy/normal/hard]` | ∞/3.5/2.8 | ∞/3500/2800 ms | ✅ (단위만 다름) |
| `projectileMax[easy/normal/hard]` | 2/10/14 | 2/10/14 | ✅ |
| `projectileFireInterval Start[easy/normal/hard]` | 3.5/1.0/0.8 | 3.5/1.0/0.8 | ✅ |
| `projectileFireInterval End[easy/normal/hard]` | 2.0/0.35/0.25 | 2.0/0.35/0.25 | ✅ |
| `projectileBurstCount[easy/normal/hard]` | 1/3/4 | 1/3/4 | ✅ |
| `projectileSpeed` | 160 | (원본은 시작 60→max 110 보간) | ❌ 보간 적용 필요 |
| `obsBaseSpeed/obsMaxSpeed` | (없음, projectileSpeed만) | easy 60→110 / normal 170→290 / hard 200→340 | ❌ 신규 |
| `stoneGuardSpeed` | 55 | 55 | ✅ |
| `stoneGuardWaypoints` | (200,100)/(760,100)/(760,380)/(200,380) (48×24 좌표) | (80,80)/(540,80)/(540,300)/(80,300) (32×20 좌표) | ❌ |
| `professorSpeed` | 70 | 70 | ✅ |
| `professorWaypoints` | (다른 좌표) | (120,100)/(520,280)/(520,100)/(120,280) figure-8 | ❌ |
| `stethoscopeSpeed` | 220 | 220 | ✅ |
| `stethoscopeMaxConcurrent` | 4 | 4 | ✅ |
| `stethoscopeThrowInterval Start/End` | 2.5/1.4 | 2.5/1.4 | ✅ |
| `playerFreezeDuration` (청진기 정지) | (확인 필요) | 2000ms (toast 1000 + freeze 2000 직렬) | 확인 |
| `airforce.fleeDuration` | (확인 필요) | 5000ms | 확인 |
| `airforce.flyDuration` | 2.0 | 2.4 | ❌ |
| `airforce.planeSpeed` | (move duration 기반) | 320 px/s | 매칭 필요 |
| `airforce.bombDropDelay` | (확인 필요) | 300ms (오버레이 닫힌 후) | 확인 |
| `toiletSpawnInterval` | 12 | 12 | ✅ |
| `toiletSpawnProbability` | 0.15 | 0.15 | ✅ |
| `toiletLifetime` | 8 | 8 | ✅ |
| `toiletBonusMultiplier` | (점수 ×2) | 2 | ✅ |
| `comboWindow` | 2.5 | (원본 없음, 콤보는 가시적 제한 없음) | iOS 고유, 보존 가능 |
| `scorePerNote` / `scorePerNoteCombo` | 1 / 2 | 원본은 콤보 3+ +2 / 5+ +3 / 7+ +4 / 그 외 +1 | ❌ ScoreSystem 공식 정정 |
| `comboBonusThreshold` | 3 | 3 (콤보 3부터 보너스 시작) | ✅ |
| `targetScoreByDifficulty` | easy 30, normal 50, hard 30 (확인) | easy 60, normal 50, hard 30 | ❌ 확인 |
| `dashClimbCooldown/Duration` | (확인 필요) | 22000ms / 260ms | 확인 |
| `bookClubRallyCooldown` | (확인 필요) | 20000ms (즉발) | 확인 |
| `charmStudentDuration` | (확인 필요) | 1500ms (게임당 1회) | 확인 |
| `taiwanTripCooldown/Invuln` | (확인 필요) | 22000ms / 500ms | 확인 |

### 4.2 캐릭터 ID 매핑 (iOS ↔ 원본)

iOS는 `CharacterID.kim/jung/geon/im/lee` raw value 그대로 원본 charId와 1:1 일치 — **변환 불필요**.

| iOS | 원본 | 스킬 매핑 |
|---|---|---|
| .kim | kim | 스킬 없음 |
| .jung | jung | dashClimb (암벽등반 돌진) |
| .geon | geon | bookClubRally (북클럽 소집) |
| .im | im | charmStudent (나는야 모범생) |
| .lee | lee | taiwanTrip (대만여행) |

### 4.3 캐릭터 능력 수치 (원본 §2.7 / §2.8)

**원본**: "능력치는 모두 동일합니다." (이동 속도 캐릭터별 차이 0, 스킬만 다름).

**iOS 현재**: `CharacterID.playerSpeedMultiplier` (1.10/1.05/1.0/0.95/0.90) — **폐기 필요**. 원본 1:1을 따르면 모든 캐릭터 = playerBaseSpeed.

---

## 5. 의존성 그래프 — 보존해야 할 인터페이스

```
StartScene
   ↓ (newCharacterSelectScene())
CharacterSelectScene
   ↓ (스와이프 5명 + 카드 탭)
   ↓ if .kim: DifficultySelectScene(characterID: .kim)
   ↓ else: SkillExplanationScene(characterID: ...)
SkillExplanationScene
   ↓ (DifficultySelectScene(characterID: ...))
DifficultySelectScene
   ↓ (3난이도 카드 + 시작 탭)
   ↓ GameScene.newGameScene(characterID:difficulty:)     ← 인터페이스 #1 (보존 필수)
GameScene (인게임)
   ↓ (45초 진행 후 endGame)
   ↓ ResultScene.newResultScene(score, bestScore, isNewBest, stats, characterName, difficulty, isNewGraduation, graduatedAt)     ← 인터페이스 #2 (보존 필수)
ResultScene
   ↓ 재시작 → CharacterSelectScene
   ↓ 메인 → StartScene
   ↓ 기록 보기 → ScoreboardScene
```

**보존해야 할 데이터 인터페이스:**
- `GameScene.init(size:, characterID:, difficulty:)` — 두 enum 그대로 전달
- `ResultScene.newResultScene(score:bestScore:isNewBest:stats:characterName:difficulty:isNewGraduation:graduatedAt:)` — 8개 인자 그대로
- Repository 4종: HighScoreRepository, StatisticsRepository, PerDifficultyScoreRepository, GraduationRepository
- UserDefaults 키 5종

---

## 6. Sprint 9 Phase 후보 (제안)

원본의 픽셀 1:1 재현 + 사용자 "Phase 많이 쪼개" 결정을 반영해 **10개 Phase**로 분할 제안:

| Phase | 작업 | 무게 | 의존 |
|---|---|---|---|
| **A** | **맵 크기·좌표계 정렬** — mapColumns 48→32, mapRows 24→20, 카메라 follow 폐기 → 고정 화면. 외곽 1타일 벽 + 단순 단색 배경. `addCheckerboardFloor`/외곽 라운드 보더 폐기. PlayerNode/EnemyNode/모든 NPC `position` 좌표 1.5배 축소. | 중 (LOC ~250) | 없음 — 가장 먼저 |
| **B** | **PixelSprite 픽셀 노출 + Sprint 7-F~9-C 시각 자식 제거** — PlayerNode/EnemyNode/ProfessorNode `color=.clear`+`colorBlendFactor=1.0` 폐기 → PixelSprite texture 직접 노출. CharacterFullBodyNode/setupVisualOverlay/applyVisualScaleV9 호출 폐기. PlayerNode의 PNG fallback도 폐기. | 중 (LOC ~200) | A |
| **C** | **맵 빌더 3종 (easy/normal/hard) byte-equal 이식** — 원본 §1.2.1/§1.2.2/§1.2.3 좌표 그대로. 중앙 기둥(easy 2×4), normal/hard 4모서리 방 + 문 + 중앙 기둥. 벽 색 `floorA/floorB/wall/wallHi` 토큰 추가(원본 §1.3). 체크보드 패턴은 원본 그대로. | 중 (LOC ~200) | A, B |
| **D** | **수간호사 AI 재작성** — EnemyNode 직선 추적 폐기 + 4지점 패트롤 신규 (난이도별 점/속도 차등). farthest-first 시작 점 선택. throwTimer 상태 머신 (대기/텔레그래프/투척) 신규. EnemyTelegraphNode(빨강 !) 신규. F 발사 시 burst 가드 유지. | 대 (LOC ~400) | A |
| **E** | **F/A 픽셀화 + StoneGuard PixelSprite + 수치 동기화** — PixelSprite.fData/aData/stoneGuardData/airplaneData/stethoscopeData/noteData 추가. PixelSpriteRenderer를 가변 크기 지원(12×12, 14×8, 16×5, 16×20 모두). NoteNode/ProjectileNode/StoneGuardNode/AirplaneNode/StethoscopeNode 시각 자식 폐기 + texture 도입. StoneGuard waypoint 좌표 정정. | 대 (LOC ~350) | A, B, C |
| **F** | **이교수 텔레그래프 + 매혹 하트 + 청진기 회전 동기화** — ProfessorTelegraphNode(코랄핑크 !) + EnemyNode 매혹 시 CharmHeartNode 부착. 청진기 자체 회전을 시간 기반 (`now/100 % 2π`)으로 변경. ProfessorNode waypoint 좌표 원본과 정합 (figure-8). | 중 (LOC ~250) | D, E |
| **G** | **AIRFORCE 이스터에그 원본 3단계 흐름** — 접촉 → 오버레이(사용자 확인 클릭) → 비행기 등장 + 수간호사 5초 도주 + F 전멸 + 폭탄 섬광. AirforceOverlayNode 클릭 인터랙션 추가 (현재는 자동 dismiss). dropBomb 신규: F 전멸 + 22 파티클 + 셰이크 500ms + 사운드 80→55Hz. 박병장 캐릭터 노드(SergeantParkNode)는 §8 리스크 판단에 따라 폐기 OR 컷씬 전용 보존. | 대 (LOC ~350) | A, D, E |
| **H** | **5종 컷씬 시스템 + 1회 표시 가드** — CutsceneSystem 신규 (Set 추적). intro(난이도 분기) / mid1(15초 경과, 캐릭터 분기) / mid2(30초 경과) / introStoneGuard(easy/normal) / introProfessor(hard). 기존 showIntro/Warning 함수 분기를 통합. 캐릭터별 속마음 분기 텍스트 데이터. | 중 (LOC ~250) | 독립 (가장 마지막 추천) |
| **I** | **난이도 밸런싱 + 점수 공식 + 사운드** — ScoreSystem 점수 공식 정정 (콤보 3+/5+/7+ 분기 = +2/+3/+4). targetScoreByDifficulty 원본 표 일치 (easy 60 / normal 50 / hard 30). C장조 스케일 10음 사인파 SCALE_FREQS 사운드 추가. SkillSystem 능력 수치 원본 표 일치. CharacterID.playerSpeedMultiplier 폐기. AudioManager 사인파 효과음 12종 추가 (110/82, 220, 180, 120/90, 80/55, SCALE_FREQS×10). | 대 (LOC ~300) | A, D, E, F, G |
| **J** | **HUD/UI 픽셀 톤 정합 + 시각 폴리싱 보존 결정** — HUD 5슬롯(원본 매핑 — TIME/SCORE/COMBO/BEST/SKILL with conic-gradient)으로 부분 정정. SkillButton/HUDSkillSlot 합치기 OR 분리 유지 결정. 콤보 마일스톤(3/5/10/20)·5초 긴박감·sparkle·hit flash 같은 iOS 고유 폴리싱은 보존 결정 (§7 변경 금지에 명시). | 중 (LOC ~200) | A~I 전부 |

**Phase 의존성**:
- 가장 먼저 A (맵 크기/카메라) → 모든 좌표 계산의 전제
- 그 다음 B (시각 차단 해제) → 픽셀 노출 보장
- C, D, E는 부분 병렬 가능 (단, D는 A 의존, E는 B 의존)
- F, G는 D/E 의존
- H는 독립 (가장 마지막 추천 — 다른 Phase 합격 후)
- I는 A~G 의존
- J는 A~I 의존

**예상 총 LOC 영향**: 약 2,750 (재작성 1,950 + 신규 800)

---

## 7. 변경 금지 항목 (Sprint 9 동안 절대 건드리지 말 것)

### 7.1 메뉴 씬 6개 — 본문 변경 0

- `Scenes/StartScene.swift`
- `Scenes/CharacterSelectScene.swift`
- `Scenes/SkillExplanationScene.swift`
- `Scenes/DifficultySelectScene.swift`
- `Scenes/ResultScene.swift`
- `Scenes/ScoreboardScene.swift`

(단, `GameScene.newGameScene(characterID:difficulty:)` 시그니처가 호환되는지 호출부만 확인 — 시그니처는 보존되므로 본문 0 변경.)

### 7.2 메뉴 전용 노드 — 본문 변경 0

- `Nodes/NurseAvatarNode.swift`
- `Nodes/CharacterFaceNode.swift`
- `Nodes/CharacterCardNode.swift`
- `Nodes/DifficultyCardNode.swift`
- `Nodes/MusicNoteEmitterNode.swift`
- `Nodes/GradientBackgroundNode.swift`
- `Nodes/AccentLineNode.swift`
- `Nodes/GlassPillNode.swift`
- `Nodes/DarkContextChipNode.swift`
- `Nodes/PrimaryButtonNode.swift`
- `Nodes/BackButtonNode.swift`
- `Nodes/GlowingTitleNode.swift`
- `Nodes/StoryBoxNode.swift`
- `Nodes/DiplomaOverlayNode.swift`

### 7.3 도메인/영속 계층 — 본문 변경 0

- `Models/CharacterID.swift` (단, `playerSpeedMultiplier` 만 폐기 — Phase I)
- `Models/Difficulty.swift`
- `Models/PlayerSkill.swift` (메타데이터 원본 일치 확인 — Phase I)
- `Models/GameStats.swift`
- `Models/Direction.swift`
- `Repositories/*` 5개 전부
- `Config/GameState.swift`
- `Managers/HapticsManager.swift` (인터페이스만 보존, 사용처는 시각 폴리싱 채널에서 호출 유지)
- `Systems/ScoreSystem.swift` (단, 점수 공식만 정정 — Phase I)
- `Systems/ContactRouter.swift` (콜백 분기 인터페이스 보존)

### 7.4 시각 폴리싱 (iOS 고유, 원본에 없지만 유지)

- `Nodes/SparkleEffectNode.swift` — 음표 수집 sparkle
- `Nodes/HitFlashNode.swift` — 피격 빨강 플래시
- `Nodes/ComboPopupNode.swift` — x3/x5/x10/x20 팝업
- `Nodes/ComboBreakNode.swift` — BREAK 팝업
- `Nodes/ScorePopupNode.swift` — +1/+2 팝업
- `Nodes/CountdownNode.swift` — 3-2-1-GO! (원본은 즉시 시작이지만 iOS 고유로 보존 결정)
- `Systems/CameraShakeAction.swift` — 셰이크 액션

---

## 8. 리스크 / 알려진 어려움

### 8.1 픽셀 아트 SpriteKit 렌더링 전략 — **이미 해결됨**

iOS 코드는 이미 `PixelSpriteRenderer.swift`로 UIGraphicsImageRenderer + SKTexture(filteringMode=.nearest) 패턴 채택. 원본 분석 §12.3 권장과 일치. 캐싱은 SKTexture가 ARC로 자동 정리 — 추가 atlas 도입은 성능 측정 후 결정.

**부분 확장만 필요**: PixelSpriteRenderer가 현재 16×20 고정 — 가변 크기 지원(12×12, 14×8, 16×5 등) 추가 필요. spriteWidth/Height를 함수 인자로 노출하면 됨 (~30 LOC).

### 8.2 메뉴 카툰 톤 ↔ 인게임 픽셀 톤의 시각적 불연속

**문제**: 메뉴는 NurseAvatarNode/CharacterFaceNode 모두 SKShapeNode SVG-스타일 카툰 (피부 #FFE2C6, navy stroke #2D2A4A). 인게임은 픽셀 도트 16×20.

**완화 방안** (사용자 §1 보존 결정에 따라 §8 리스크로만 기록):
1. **인트로 컷씬에서 자연 전환** — CutsceneOverlayNode가 *카툰 → 픽셀 전환의 톤 다리* 역할. 본문에 "병동의 픽셀 세상으로..." 같은 문구로 자연 시각 변환 정당화.
2. **HUD 톤은 인게임 픽셀에 맞춰 정렬** — HUD가 두 화면 사이 시각 다리. 코랄/navy 톤은 양쪽 공통.

### 8.3 박병장 SergeantParkNode 처리

**현재 상태**: Sprint 7/8에서 만든 풀바디 박병장 캐릭터 노드. 컷씬 entry intro도 보유.

**원본**: 박병장은 비행기 + 폭탄만 (캐릭터 노드 없음).

**옵션**:
- **A. 폐기** (원본 1:1) — 비행기·폭탄만 + 오버레이 텍스트 "나와라 박병장!".
- **B. 컷씬 전용으로만 보존** — `makeIntroCloseup()` 컷씬에만 등장, 인게임에는 부재. 사용자 의사결정 #2(Sprint 7 박병장 디자인)와 인게임 일치성의 트레이드오프.

§14 사용자 결정 필요. 본 분석은 옵션 A 권장 (사용자 명시: "원본 그대로").

### 8.4 카메라 follow 폐기 시 화면 종횡비

**문제**: 현재 iOS는 1024×768 (4:3) `.resizeFill` + worldNode 960×480 (2:1) + 카메라 follow. 카메라를 폐기하고 원본 640×400 (16:10) 화면을 그대로 표시하려면:

**옵션**:
- **A. scene size = 640×400 + scaleMode .aspectFit** — 양옆 검은 띠. 가장 정직한 원본 재현.
- **B. scene size = 640×400 + scaleMode .resizeFill** — 종횡비 보존 가능. iPhone 가로(약 16:9) → 위아래 살짝 잘림.
- **C. 카메라 정중앙 고정 (cameraNode.position = 맵 중앙)** — worldNode/cameraNode는 유지하되 follow만 폐기. 위 변환이 최소.

§14 사용자 결정 필요. 본 분석은 옵션 C 권장 (Sprint 9 LOC 최소화).

### 8.5 EnemyNode 패트롤 vs Sprint 7-F 시각 자식 보강

**문제**: Sprint 7-F에서 수간호사에 차트(클립보드)/헬로/클립 SKShape 자식을 추가했음. 픽셀 톤 1:1 재현 시 폐기해야 하는데, 이 시각 자식들이 *수간호사 권위 인지*에 기여.

**옵션**:
- **A. 폐기** (원본 1:1).
- **B. 보존** — 시각 자식만 유지하고 PixelSprite도 노출 (시각 충돌 가능).

§14 사용자 결정 필요. 옵션 A 권장.

### 8.6 CharacterFullBodyNode 폐기 vs 보존

**문제**: Sprint 8에서 만든 인게임 풀바디 노드. PlayerNode `color=.clear`로 PixelSprite 차단 후 풀바디만 표시. 원본 1:1 = PixelSprite 노출.

**결정**: 폐기. CharacterFaceNode(메뉴용)는 보존, CharacterFullBodyNode(인게임용)은 Sprint 9 Phase B에서 제거.

### 8.7 5초 긴박감 + 콤보 마일스톤 + 카운트다운

iOS 고유 시각 폴리싱 (원본에 없음). 폐기 vs 보존 — 사용자 명시적 결정 없음.

**결정**: 보존 (§7.4에 명시). 사용자가 "원본 1:1"이라 했지만 시각 폴리싱은 모바일 UX 향상으로 봐서 유지. 단, §14에 명시적 확인 받기.

### 8.8 ToastLabelNode "청진기 명중!" 토스트

원본은 1초 토스트 후 2초 freeze 직렬화 (총 3초). iOS는 toast 0.9~1초 + freeze 2초 동시 발화. 1:1로 직렬화하려면 freeze 시작 타이밍을 toast 종료 직후로 미뤄야 함 — 청진기 명중 콜백 1줄 수정.

### 8.9 졸업장 시스템

원본 §7.4: 3난이도 모두 목표 점수 달성 시 캐릭터별 졸업장. iOS는 이미 완전 구현됨 (GraduationRepository + DiplomaOverlayNode + isGraduated 헬퍼). **변경 0**.

### 8.10 HG 작곡 트랙 링크

원본 §7.5: 성공 엔딩 시 "🎵 HG가 실습때 만든 노래 듣기" 버튼 → YouTube. iOS ResultScene이 이 링크를 노출하는지 확인 필요. 만약 없다면 §J(HUD/UI 정합)에서 추가 검토.

### 8.11 BGM 처리

원본 §9.5: **BGM 없음**. iOS는 BGMPlayer로 자작 BGM 무한 루프 (음원 부재 시 noop). 원본 1:1 = BGM 폐기. 단, iOS UX로는 BGM 유지가 자연. §14 사용자 결정.

### 8.12 dpad 위치와 화면 종횡비

원본은 키보드, iOS는 dpad 좌하단 + 스킬 버튼 좌하단. **모바일 가로(landscape) 화면에서 두 영역이 겹치지 않는지** Phase A 진행 후 확인 필요 (현재는 dpad 우하단 + 스킬 좌하단이므로 OK).

---

## 부록: 파일 분류 빠른 표

### 보존 (no change, 27 파일)

```
Scenes/StartScene.swift (325)
Scenes/CharacterSelectScene.swift (738)
Scenes/SkillExplanationScene.swift (618)
Scenes/DifficultySelectScene.swift (495)
Scenes/ResultScene.swift (817)
Scenes/ScoreboardScene.swift (510)
Nodes/NurseAvatarNode.swift (374)
Nodes/CharacterFaceNode.swift (1107)
Nodes/CharacterCardNode.swift (483)
Nodes/DifficultyCardNode.swift (337)
Nodes/MusicNoteEmitterNode.swift (117)
Nodes/GradientBackgroundNode.swift (133)
Nodes/AccentLineNode.swift (47)
Nodes/GlassPillNode.swift (78)
Nodes/DarkContextChipNode.swift (112)
Nodes/PrimaryButtonNode.swift (124)
Nodes/BackButtonNode.swift (70)
Nodes/GlowingTitleNode.swift (78)
Nodes/StoryBoxNode.swift (69)
Nodes/DiplomaOverlayNode.swift (374)
Nodes/SparkleEffectNode.swift (67) — 시각 폴리싱
Nodes/HitFlashNode.swift (46) — 시각 폴리싱
Nodes/ComboPopupNode.swift (110) — 시각 폴리싱
Nodes/ComboBreakNode.swift (93) — 시각 폴리싱
Nodes/ScorePopupNode.swift (111) — 시각 폴리싱
Nodes/CountdownNode.swift (129) — 시각 폴리싱
Nodes/CutsceneOverlayNode.swift (172) — Phase H에서 재사용
Nodes/ToastLabelNode.swift (89)
Nodes/PauseButtonNode.swift (66)
Nodes/AirforceOverlayNode.swift (55) — Phase G에서 클릭 인터랙션 확장
Nodes/BombFlashNode.swift (42) — Phase G에서 확장
Nodes/DPadNode.swift (136)
Nodes/SkillButtonNode.swift (122)
Nodes/HUDSkillSlotNode.swift (141)
Nodes/PixelSpriteRenderer.swift (45) — Phase E에서 가변 크기 확장
Models/* 6개
Repositories/* 5개
Managers/HapticsManager.swift (54)
Managers/AudioManager.swift (92) — Phase I에서 사운드 추가
Managers/BGMPlayer.swift (242) — §8.11 보류
Config/GameState.swift (20)
Config/PhysicsCategory.swift (22)
Config/SceneSafeArea.swift (27)
Config/ColorTokens.swift (344) — Phase C에서 floorA/B/wall/wallHi 토큰 추가
Systems/ContactRouter.swift (137)
Systems/ScoreSystem.swift (68) — Phase I에서 공식 정정
Systems/CameraShakeAction.swift (48)
Protocols/SelfDismissingNode.swift (20)
```

### 재작성 (13 파일)

```
GameScene.swift (858) — Phase A/B/D/G
GameScene+Setup.swift (544) — Phase A/B/C
Nodes/PlayerNode.swift (318) — Phase B
Nodes/EnemyNode.swift (278) — Phase B/D (전면)
Nodes/ProfessorNode.swift (282) — Phase B/F
Nodes/StoneGuardNode.swift (131) — Phase B/E
Nodes/SergeantParkNode.swift (160) — Phase G (폐기 결정 시) 또는 컷씬 보존
Nodes/AirplaneNode.swift (190) — Phase E (픽셀화)
Nodes/ProjectileNode.swift (103) — Phase E
Nodes/StethoscopeNode.swift (52) — Phase E
Nodes/NoteNode.swift (82) — Phase E
Nodes/ToiletNode.swift (60) — Phase E (가벼움)
Nodes/HUDNode.swift (255) — Phase J
Nodes/CharacterFullBodyNode.swift (496) — Phase B (전체 삭제 또는 인게임 호출 제거)
Models/PixelSprite.swift (467) — Phase E (신규 데이터 추가)
Models/PixelPalette.swift (141) — Phase E (신규 팔레트 추가)
Config/GameConfig.swift (2515) — Phase A/C/D/E/F/G/I (수치 동기화)
Systems/SpawnSystem.swift (249) — Phase D (수간호사 발사 → 본인이 발사로 이전)
Systems/SkillSystem.swift (334) — Phase I (수치 정합)
```

### 신규 (8 파일 추정)

```
Systems/MapBuilder.swift 또는 Nodes/MapTileNode.swift — Phase C (32×20 맵)
Systems/CutsceneSystem.swift — Phase H
Systems/PatrolSystem.swift 또는 EnemyNode 내부 — Phase D
Nodes/EnemyTelegraphNode.swift — Phase D
Nodes/ProfessorTelegraphNode.swift — Phase F
Nodes/BombNode.swift 또는 BombFlashNode 확장 — Phase G
Nodes/CharmHeartNode.swift — Phase F
Managers/SineWaveAudio.swift 또는 AudioManager 확장 — Phase I
```

---

문서 끝. 본 분석은 SPEC.md(Phase 별)의 시작점으로 사용 권장.
