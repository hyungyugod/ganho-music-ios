# 00 · 큰 그림 — GanhoMusic iOS

> **이 문서 하나만 읽으면 "내가 무엇을, 어떻게, 왜 만드는지" 그림이 그려진다.**
> Spring Boot만 해본 사람을 위한 입문 가이드.

---

## 1. 우리가 만드는 것은? 🎮

**김간호는 음악박사 — 모바일 에디션.** iPhone을 가로로 눕혀서 하는 45초짜리 픽셀 게임이다.

### 1-1. 자전적 배경 (이게 이 게임의 정체성)
사용자(개발자 본인)가 **간호학과 학생 시절 병동 실습 중 몰래 노트에 작곡을 해서 음반을 낸 경험**을 게임화한 작품. 그래서:
- "수간호사의 호통(F)을 피하며 음표를 모은다" = 감시자의 눈을 피해 자기만의 창작을 이어가는 메타포
- "음악박사" = 간호 실습생이지만 진짜 학위는 음악에서 따고 싶었다는 자조 섞인 자기 표현
- 의료/간호직 비하 농담은 **금지** — 본인의 농담이지 외부 패러디가 아님

### 1-2. 화면 모델 (확정)
```
┌──────────────────────────────────────────────────────┐
│        ♪                                             │
│                       👵 ← 수간호사                  │
│                        F↓                            │
│  ⏱ 00:42  🎵 12  🔥 3   ← HUD (반투명 오버레이)    │
│                                                      │
│                  🧑‍⚕️ ← 김간호 (항상 화면 중앙)       │
│                                                      │
│                     ♪                                │
│  [SKILL]                            [▲]              │
│  (반투명)                       [◀][●][▶]  ← D-Pad   │
│                                     [▼]   (반투명)   │
└──────────────────────────────────────────────────────┘
        └─ 게임 월드는 화면 풀스크린 ─┘
        └─ 맵은 화면보다 큼. 카메라가 캐릭터 따라감 ─┘
```

**핵심 원칙**:
- **풀스크린**: 게임 월드가 화면 전부를 차지. HUD/D-Pad가 게임 영역을 잘라내지 않음.
- **반투명 오버레이**: D-Pad·Skill·HUD는 알파 0.3 정도로 게임 위에 떠 있음. 시야를 가리지 않게.
- **카메라 follow**: 캐릭터는 **항상 화면 중앙**. 맵이 캐릭터 주변으로 보임. 맵 자체는 화면보다 크다(웹 버전 32×20 타일 = 640×400).

### 1-3. 한 판 흐름
김간호(나)는 D-Pad로 움직이며 ♪를 모은다 → 수간호사(👵)가 따라오며 F를 던진다 → 45초 버티며 점수 최대화.

**왜 "음악"박사?** 음표 수집이 BPM(메트로놈)과 동기화되어 있어, 박자에 맞춰 모으면 보너스. 단순 회피·수집 게임이 아니라 **리듬 한 스푼**이 들어간다.

> 자세한 게임 명세는 [docs/GDD.md](../GDD.md), 디자인 결정 이유는 [docs/game-design.md](../game-design.md).
> ⚠️ 위 두 문서는 아직 풀스크린/카메라 follow 모델 반영 전 — 다음 정리 사이클에서 갱신 예정.

---

## 2. 처음 보는 단어들 (Spring → iOS 사전) 📖

| 처음 보는 단어 | 한 줄 설명 | Spring으로 치면 |
|---|---|---|
| **Swift** | 애플이 만든 프로그래밍 언어 | Java/Kotlin 자리 |
| **Xcode** | 애플 공식 IDE | IntelliJ IDEA 자리 |
| **iOS** | iPhone OS | Spring Boot 런타임이 JVM이듯, iPhone 앱이 도는 운영체제 |
| **SwiftUI** | 선언형 UI 프레임워크 | React/Vue 같은 느낌 (이번 게임에선 거의 안 씀) |
| **SpriteKit** | 2D 게임 프레임워크 | Spring에 비유 어려움. **게임 전용 프레임워크** |
| **SKScene** | 한 "화면" = 한 씬 | 페이지/화면. 타이틀씬·게임씬·종료씬 등 |
| **SKNode** | 씬 안의 모든 요소(캐릭터/벽/HUD)의 부모 클래스 | DOM의 Element 같은 위치 |
| **SKSpriteNode** | 이미지(또는 색깔)를 가진 노드 | `<img>` 또는 `<div style="background">` |
| **SKAction** | 노드에게 시키는 동작(이동·회전·반복 등)을 담은 객체 | RxJava의 Observable 비슷 (시간 기반 동작) |
| **SKPhysicsBody** | 노드의 충돌·물리 정보 | 직접 대응 없음. 게임 전용 |
| **simulator** | 시뮬레이터 — Mac 위에서 도는 가상 iPhone | 로컬 톰캣처럼 가상 환경에서 앱 실행 |

> 모든 게임 코드는 결국 **"여러 SKNode를 SKScene 위에 놓고 SKAction으로 움직이고 SKPhysicsBody로 부딪히게 한다"** — 이 한 줄이 SpriteKit의 전부다.

---

## 3. 일은 어떻게 흘러가나? 🔁

이 프로젝트의 **두 번째 학습 목표**가 바로 이 협업 모델이다. (첫 번째는 Swift 자체)

```
   ┌────────────┐                                    ┌─────────────────┐
   │   사용자    │  "이 기능 만들어줘"                │     Claude      │
   │ (Spring 출신)│ ──────────────────────────────→  │   (메인 에이전트)│
   └────────────┘                                    └────────┬────────┘
         ▲                                                    │
         │                                                    │ 작업 설명서
         │                                                    │ docs/learn/NN-*.md
         │                                                    ▼
         │                                          ┌─────────────────┐
         │                                          │  학습 노트 작성   │  ← 사용자가 공부할 자료
         │                                          └────────┬────────┘
         │                                                    │ 동의?
         │                                                    ▼
         │   QA 리포트 (점수)                       ┌─────────────────┐
         └──────────────────────────────────────────│  3-Agent 하네스  │
                                                   │  ① Planner       │  설계서 작성
                                                   │  ② Generator     │  Swift 코드 작성
                                                   │  ③ Evaluator     │  채점
                                                   └─────────────────┘
```

**사용자 역할**: 무엇을 만들지 결정. 학습 노트 보고 공부. 모호하면 질문.
**Claude 역할**: 학습 노트 → 하네스 사이클 → 결과 보고.

> Spring으로 비유하면: 사용자가 PR 요청, Claude가 PR 작성·자동 리뷰·머지까지 대행.

---

## 4. 게임 완성 스토리 (6 Phase) 🎬

각 Phase가 **"플레이어 입장에서 어떻게 보이는지"** 기준으로:

| Phase | 한 문장 스토리 | 시뮬레이터에서 보이는 것 | 학습 포커스(Swift/iOS) |
|---|---|---|---|
| **0** ✅ | "앱은 켜진다" | 빈 화면, 가로 모드 | Xcode 프로젝트 구조, 타겟 |
| **1** ✅ | "내 캐릭터가 움직인다" | 사각형 캐릭터 + 반투명 D-Pad로 이동, 카메라가 따라옴 | enum 네임스페이스, struct/class, optional, dt 기반 게임 루프, **`SKCameraNode`(카메라 follow)** |
| **2** ✅ | "음표 모으고 적 피한다" (게임 다움) | 음표·수간호사·F투사체·점수·45초 타이머 | SKAction.repeatForever, SKPhysicsContactDelegate |
| **3** ✅ | "한 판 끝나면 결과화면 + 최고기록" | 타이틀→게임→결과 화면 전환, BEST + PLAYS/TOTAL | Scene 전환, UserDefaults, Codable + Repository |
| **4** ⬜ | "추가 NPC와 깜짝 이벤트" | 석조무사·이교수·박병장 비행기 | AI 패트롤, 이벤트 트리거 |
| **5** ⬜ | "캐릭터 5명, 각자 스킬" | 캐릭터 선택 + 능동 스킬 | protocol 다형성, 쿨다운 |
| **6** ⬜ | "그림·소리·진동 다 입혔다" | 픽셀 아트 + BGM/SFX + 햅틱 | SKTextureAtlas, AVAudioEngine, UIFeedbackGenerator |

> **MVP = Phase 1+2** — 여기까지만 해도 "플레이 가능한 게임"이 된다. 나머지는 살붙이기.

---

## 5. 폴더 구조 한눈에 (Spring 그대로 옮긴 의도) 📂

폴더 이름을 일부러 Spring(clonebose) 와 비슷하게 가져갔다. 멘탈 모델 절반은 그대로, 나머지 절반(Swift 문법)에 학습을 집중하기 위함.

```
GanhoMusic/GanhoMusic/GanhoMusic Shared/      ← 게임 로직이 사는 곳
├── Scenes/         ← controllers/  : 화면(=요청) 받는 곳. 입력→로직 위임
├── Nodes/          ← (게임 고유)   : 화면 위 살아있는 시각 객체 (캐릭터/적/음표)
├── Systems/        ← services/     : 게임 도메인 로직 (스폰/점수/입력)
├── Repositories/   ← mappers/      : 외부 데이터 (UserDefaults, Supabase)
├── Models/         ← models/       : 값 객체 (struct 우선)
├── Managers/       ← managers/     : 공통 보조 (오디오·햅틱 싱글톤)
├── Config/         ← config/       : 상수·설정 (의존성 안 나감)
├── Errors/         ← exceptions/   : enum: Error
└── Resources/      ← resources/    : .sks·이미지·사운드
```

**의존성 방향 (지킬 것)**:
```
Scenes → Systems → Repositories → (외부)
   │       │
   ├→ Nodes ┘
   ├→ Managers
   └→ Config (어디서나 OK)
```

> 더 자세한 매핑은 [docs/architecture-mapping.md](../architecture-mapping.md).

---

## 6. 이 폴더(`docs/learn/`)는 무슨 폴더? 📚

코드만 보면 "무슨 일이 일어났는지"는 알지만 **"왜 그렇게 했는지"**, **"Spring으로 치면 뭔지"**는 안 보인다. 이 폴더의 문서가 다리 역할을 한다.

**작업 한 사이클의 흐름**:
```
[1] 작업 시작 전:  docs/learn/NN-*.md  를 새로 작성  ← 사용자 학습 자료
[2] 사용자 동의
[3] rm -f SPEC.md SELF_CHECK.md QA_REPORT.md     ← 이전 산출물 청소
[4] Planner      → SPEC.md       (설계)
[5] Generator    → Swift 코드 + SELF_CHECK.md
[6] Evaluator    → QA_REPORT.md  (채점)
[7] 합격 시: 학습 노트 §회고 채우고 다음 작업
   불합격 시: Generator 재호출 (최대 3회)
```

**파일명 규칙**: `NN-phase-X-Y-슬러그.md` (예: `01-phase1-1-config-bootstrap.md`)

**모든 학습 노트는 다음 6 섹션을 포함**:
1. 작업 목적 (한 문장)
2. **Spring 비유** ⭐
3. **Swift 학습 포인트** ⭐
4. 산출물
5. 검증 방법
6. 회고 (작업 후 채움)

---

## 7. Phase 1을 잘게 쪼갠 작업 단위 🔬

큰 Phase는 1 SPEC = 1 sub-feature 원칙으로 쪼갠다. Evaluator 피드백이 의미 있으려면 변경이 작아야 한다.

| 번호 | 작업 한 줄 | 학습 노트 | 상태 |
|---|---|---|---|
| **1-1** | 게임 만들기 전 작업장 정리 (상수·상태·물리 카테고리·색상 + 빈 씬) | [01-phase1-1-config-bootstrap.md](01-phase1-1-config-bootstrap.md) | ✅ 합격 (9.6/10) |
| **1-2** | **월드 + 카메라 골격** (`worldNode`, `SKCameraNode`, 임시 박스 캐릭터, 카메라가 박스 따라감) | [02-phase1-2-world-camera.md](02-phase1-2-world-camera.md) | ✅ 합격 (9.65/10) |
| **1-3** | `PlayerNode` 정식 구현 + 반투명 D-Pad 오버레이 + dt 기반 이동 | [03-phase1-3-player-dpad.md](03-phase1-3-player-dpad.md) | ✅ 합격 (9.6/10) |
| **1-4** | 월드(맵) 경계 충돌 + 카메라 클램핑 | [04-phase1-4-bounds-clamp.md](04-phase1-4-bounds-clamp.md) | ✅ 합격 (9.6/10) |
| **1-5** | 카메라 정책 재설계 (드론 follow) + 맵 확장 (48×24) | [05-phase1-5-camera-redesign.md](05-phase1-5-camera-redesign.md) | ✅ 합격 (9.7/10) — 🎉 **Phase 1 종결** |
| **2-1** | 맵 외곽 벽 시각화 + corner 마커 폐기 | [06-phase2-1-outer-walls.md](06-phase2-1-outer-walls.md) | ✅ 합격 (9.83/10) |
| **2-2** | 중앙 기둥 + SKPhysicsBody 첫 도입 (velocity 전환) | [07-phase2-2-physics-pillar.md](07-phase2-2-physics-pillar.md) | ✅ 합격 (9.85/10) |
| **2-3** | 음표 NoteNode + 자동 스폰 + contact 알림 + score 내부 카운트 | [08-phase2-3-note-spawn.md](08-phase2-3-note-spawn.md) | ✅ 합격 (9.18/10) |
| **2-4** | HUD: 점수 라벨 + 45초 타이머 + 시간 만료 게임오버 전환 | [09-phase2-4-hud.md](09-phase2-4-hud.md) | ✅ 합격 (9.6/10) |
| **2-5** | 콤보 시스템 + 점수 ×2 (2.5초 윈도우 / 3콤보 임계 / 🔥 라벨) | [10-phase2-5-combo.md](10-phase2-5-combo.md) | ✅ 합격 (9.6/10) |
| **2-6** | 수간호사 적 NPC 1마리 + 직선 추적 AI + 접촉 시 즉시 게임오버 | [11-phase2-6-enemy-spawn.md](11-phase2-6-enemy-spawn.md) | ✅ 합격 (10.0/10) |
| **2-6 hotfix2** | viewport 재설계 (didChangeSize) + player 시작 위치 + enemy 가시성 | [12-phase2-6-hotfix2-viewport.md](12-phase2-6-hotfix2-viewport.md) | ✅ 합격 (9.575/10) |
| **2-7** | F 투사체 + 발사 주기 + F 피격 시 게임오버 + 벽 닿으면 소멸 | [13-phase2-7-projectile.md](13-phase2-7-projectile.md) | ✅ 합격 (9.65/10) |
| **2-8** | 수간호사 속도 시간 보간 (60→110 선형) | [14-phase2-8-enemy-speed-curve.md](14-phase2-8-enemy-speed-curve.md) | ✅ 합격 (10.0/10) |
| **2-9** | F 발사 주기 시간 보간 (3.5→2.0초 재귀 SKAction) | [15-phase2-9-fire-interval-curve.md](15-phase2-9-fire-interval-curve.md) | ✅ 합격 (10.0/10) |
| **2-10** | SpawnSystem 분리 (리팩터, GameScene 446→354줄) | [16-phase2-10-spawn-system.md](16-phase2-10-spawn-system.md) | ✅ 합격 (9.65/10) |
| **2-11** | ContactRouter 분리 (콜백 패턴, GameScene 354→324줄) | [17-phase2-11-contact-router.md](17-phase2-11-contact-router.md) | ✅ 합격 (10.0/10) |
| **2-12** | ScoreSystem 분리 (private(set), GameScene 324→315줄) — 🎉 **리팩터 종결** | [18-phase2-12-score-system.md](18-phase2-12-score-system.md) | ✅ 합격 (9.675/10) |
| **3-1+2** | TitleScene 신설 + GameOver 오버레이 + 씬 페이드 전환 사이클 | [19-phase3-1-2-title-result.md](19-phase3-1-2-title-result.md) | ✅ 합격 (9.675/10) |
| **3-3** | ResultScene 분리 + init(score:) 주입 + GameOverOverlayNode 폐기 | [20-phase3-3-result-scene.md](20-phase3-3-result-scene.md) | ✅ 합격 (9.83/10) |
| **3-4** | 최고 점수 영구 저장 (UserDefaults + HighScoreRepository) + Title/Result 양쪽 표시 | [21-phase3-4-highscore.md](21-phase3-4-highscore.md) | ✅ 합격 (**10.0/10**) 🎉 |
| **3-5** | Codable 통계 (GameStats + StatisticsRepository) + PLAYS/TOTAL 양쪽 표시 — 🎉 **Phase 3 종결** | [22-phase3-5-statistics.md](22-phase3-5-statistics.md) | ✅ 합격 (9.825/10) |
| **리팩터** | GameScene Setup 분리 (`extension GameScene` 도입, 340→209줄) — Swift 접근 제어 5단계 학습 | [23-gamescene-setup-extension.md](23-gamescene-setup-extension.md) | ✅ 합격 (9.65/10) |
| **4-1** | 석조무사 NPC + 4 waypoint 시계방향 패트롤 (`SKAction.repeatForever(.sequence)`) — 두 번째 AI 패턴 | [24-phase4-1-stoneguard-patrol.md](24-phase4-1-stoneguard-patrol.md) | ✅ 합격 (**10.0/10**) 🎉 |
| **4-2** | 석조무사 PhysicsBody 부착 (`collision=0` 통과형) + `PhysicsCategory.stoneGuard` 비트 + ContactRouter `onStoneGuardContact` stub — *그릇만 먼저* | [25-phase4-2-stoneguard-contact.md](25-phase4-2-stoneguard-contact.md) | ✅ 합격 (**10.0/10**) 🎉 |
| **4-3** | AIRFORCE 이스터에그 — Player ↔ StoneGuard 첫 접촉 시 비행기(`AirplaneNode`) 1회 화면 가로지르기 + 자가 소멸 (cameraNode 자식, `SKAction.sequence([move, removeFromParent])`) | [26-phase4-3-airforce-easter-egg.md](26-phase4-3-airforce-easter-egg.md) | ✅ 합격 (**10.0/10**) 🎉 |
| **4-4** | "나와라 박병장!" AIRFORCE 오버레이 — `AirforceOverlayNode`(SKNode + SKLabelNode), `SKAction.sequence([wait, fadeOut, removeFromParent])` 자가 소멸. 비행기와 동시 등장. *호출 측 변경 0 정책 3 sprint 연속* | [27-phase4-4-airforce-overlay.md](27-phase4-4-airforce-overlay.md) | ✅ 합격 (**10.0/10**) 🎉 |

> **변경 이력**: 사용자 요청(2026-05-04)으로 카메라 follow가 핵심 메커닉으로 확정 → Phase 1 작업 단위에 1-2(월드/카메라 셋업) 추가, 기존 1-2(PlayerNode 단순 배치)는 1-3과 통합.

> 이 표는 작업이 끝날 때마다 갱신된다.

---

## 8. 어디로 가야 더 알 수 있나 🗺️

| 알고 싶은 것 | 가야 할 문서 |
|---|---|
| 게임 명세 (전체 기능 정의) | [docs/GDD.md](../GDD.md) |
| 왜 이런 게임을 만드는가 (디자인 결정) | [docs/game-design.md](../game-design.md) |
| Spring → SpriteKit 변환 룰 (코드 예시 포함) | [docs/architecture-mapping.md](../architecture-mapping.md) ⭐ |
| Swift 코딩 컨벤션 (강제 언래핑 금지 등) | [docs/swift-rules.md](../swift-rules.md) |
| SpriteKit 패턴 (씬 생명주기, 물리, 액션) | [docs/spritekit-rules.md](../spritekit-rules.md) |
| 컬러 팔레트 / 폰트 / 사운드 정책 | [docs/assets.md](../assets.md) |
| AI 하네스 운영 룰 (Claude용) | [CLAUDE.md](../../CLAUDE.md) |
| 디스크 파일을 Xcode 그룹에 등록하는 법 | [docs/xcode-import-guide.md](../xcode-import-guide.md) |
| **지금 진행 중인 작업의 Spring 비유 + Swift 포인트** | **이 폴더의 `NN-*.md`** ⭐ |

---

## 한 줄 요약

> **iPhone 가로 게임을 만든다. 6단계로 쪼개서, 각 단계마다 작업 설명서를 먼저 만들고(공부용), AI 하네스(Planner→Generator→Evaluator)가 코드 작성·채점을 대행한다. 사용자는 결정·학습·검증만 한다.**
