# 05 · Phase 1-5 · 카메라 정책 재설계 + 맵 확장

> **이번 작업의 한 줄**: 1-4의 카메라 클램핑을 풀고 player를 *항상 화면 정중앙*에 두기 (드론 follow). 맵도 더 넓게 (48×24).
> 비유: 운동장 끝에 박혀 있던 카메라맨을 → **학생 머리 위 드론**으로 바꾸는 것.

---

## 1. 한눈 요약

```
1-4 (지금)                              1-5 (이번 작업)
┌────────────────────┐                 ┌────────────────────┐
│ 박스가 맵 끝 가면   │                 │ 박스가 어디 가든   │
│ 화면 가장자리로     │       ──→       │ 늘 화면 정중앙     │
│ 미끄러져 보임       │                 │ (카메라가 드론처럼)│
│   ┌──map──┐  □    │                 │   ┌──map──┐        │
│   │       │       │                 │   │  [□]  │ ← 가운데
│   └───────┘       │                 │   └───────┘        │
│   카메라 멈춤       │                 │ + 맵도 더 넓어짐    │
│ (게임 끝 신호)      │                 │   32×20 → 48×24    │
└────────────────────┘                 └────────────────────┘
       횡스크롤 카메라                        탑다운 드론 카메라
       (마리오, 메트로이드)                    (디아블로, 회피 게임)
```

**핵심**: 회피 게임은 **사방이 위협**이라 시야가 균등해야 한다. player가 화면 가장자리에 있으면 한쪽이 안 보임 → 답답함. 1-4의 클램핑은 횡스크롤 게임에 맞고, GanhoMusic 같은 탑다운 회피엔 부적합. **사용자 직감이 정답**.

---

## 2. 무엇을, 왜?

### 무엇을 만드나
| 변경 | 한 줄 설명 |
|---|---|
| 카메라 클램프 제거 | `cameraNode.position = player.position` 한 줄로 회귀 (1-2 패턴) |
| `clampedCameraPosition(forPlayerAt:)` 헬퍼 삭제 | 1-4에서 만든 분기 로직 통째로 제거 |
| 맵 가로/세로 키우기 | `mapColumns: 32 → 48`, `mapRows: 20 → 24` (mapWidth/Height는 파생값이라 자동) |
| GDD §6 명세 갱신 | "32×20 = 640×400" → "48×24 = 960×480 (Phase 1-5 재설계)" |

### 왜 지금?
1. **사용자 직감이 맞았다.** 게임 디자이너(개발자 본인)의 첫 멘탈 모델은 "player가 늘 중앙 + 카메라가 따라옴". GDD도 이걸 *기본*으로 명시 ("필요 시 클램핑"). 1-4에서 너무 일찍 클램핑을 도입했음.
2. **GanhoMusic은 탑다운 회피 게임**. 사방에서 수간호사 + F투사체가 오고 음표가 사방에서 스폰됨. *시야 균등*이 본질.
3. **Phase 2 진입 전 정리 필수.** 음표/적 스폰을 시작하면 카메라 정책에 의존성이 생기기 시작. 정책을 먼저 확정해야 후속 Phase가 흔들리지 않음.
4. **맵 크기**: 가로 viewport(852)보다 맵(640)이 작아서 가로에 검은 띠가 항상 보였음. 맵 가로를 960으로 키우면 평소엔 검은 띠 없음, 맵 가장자리 갔을 때만 살짝 보여 *시각 경계 신호* 역할.

### 무엇을 하지 않나
| 안 하는 것 | 미루는 곳 |
|---|---|
| PlayerNode 자체 클램프 제거 | **유지** — 박스는 여전히 맵 안에 갇힘 (검은 영역으로 나가면 안 됨) |
| 카메라 lerp 보간 | Phase 2 이후 — 직접 추종 유지 |
| 맵 외곽 벽 시각화 | Phase 2 (맵 타일 도입과 함께) |
| corner 마커 정리 | Phase 2 (맵 타일이 들어오면 자연 폐기) |
| 맵 비율을 viewport에 자동 맞춤 | 안 함 — 고정 비율이 게임 디자인 일관성 유지 |

---

## 3. Spring 비유 🌱

### 3-1. 1-4 클램핑 = "조기 최적화" 패턴
Spring으로 치면, 1-4의 카메라 클램핑은 **너무 일찍 도입한 캐싱 전략**과 비슷:
- 처음엔 단순한 follow(`cameraNode.position = player.position`)로 시작
- "맵 끝에서 검은 영역 보이는 게 싫다" 가정으로 1-4에서 분기 클램핑 도입
- 막상 *실제 플레이*해보니 회피 게임에선 player 시야 비대칭이 더 큰 문제
- **사용자가 *플레이 후 진단*하고 정책을 뒤집음** — 디자인 회귀

> Spring으로 치면: 캐시를 쓰다 데이터 일관성 문제로 결국 직접 DB 조회로 회귀하는 패턴. 처음에 단순하게 가는 게 답인 경우가 많음.

### 3-2. 도메인-View 분리는 그대로
- **PlayerNode** (도메인): 자기 위치를 맵 안으로 강제 (1-4 §기능 1 유지)
- **GameScene** (View): 카메라가 player를 따라감 (1-2 패턴 회귀, 1-4 클램프 제거)

PlayerNode와 GameScene의 책임 분리는 그대로. *씬의 카메라 정책만 바뀌었음.* 도메인 코드는 변경 0건.

---

## 4. Swift / SpriteKit 학습 포인트 📘

### 4-1. 코드 *덜어내기*가 더 어렵다
1-4에서 추가한 헬퍼 함수 + 분기 로직을 통째로 삭제:
```swift
// 삭제 대상 (1-4 §기능 2)
private func clampedCameraPosition(forPlayerAt playerPosition: CGPoint) -> CGPoint {
    let halfW = size.width  / 2
    let halfH = size.height / 2

    let cameraX: CGFloat
    if GameConfig.mapWidth >= size.width {
        cameraX = max(halfW, min(GameConfig.mapWidth - halfW, playerPosition.x))
    } else {
        cameraX = GameConfig.mapWidth / 2
    }
    // ... y 동일 ...
    return CGPoint(x: cameraX, y: cameraY)
}
```

대체:
```swift
// update(_:) 끝에서
cameraNode.position = player.position   // 1-2 패턴으로 회귀
```

20줄 → 1줄. **코드는 줄어들지만 의미는 그대로.** Spring으로 치면 `Service` 메서드를 빼고 `Repository`를 직접 호출로 회귀.

### 4-2. `static let` 파생값의 마법
```swift
static let mapColumns: Int = 48          // 32 → 48
static let mapRows:    Int = 24          // 20 → 24
static let mapWidth:  CGFloat = tileSize * CGFloat(mapColumns)   // 자동 960
static let mapHeight: CGFloat = tileSize * CGFloat(mapRows)      // 자동 480
```

`mapWidth`/`mapHeight`는 *파생값*이라 mapColumns/mapRows만 바꾸면 **자동으로 새 값** 됨. 호출부(`PlayerNode` 자체 클램프, corner 마커 위치, setupPlayer 초기 위치, setupCamera 초기 위치)는 코드 변경 없이 새 맵에 적응.

> Spring으로 치면 `@Value("${app.map.width}")` 한 곳만 바꾸면 모든 의존 빈이 새 값 받는 패턴.

### 4-3. GDD 같은 명세 문서도 코드와 함께 갱신
GDD §6에 "32열 × 20행 = 640×400pt"가 명시되어 있음 → **코드 변경 시 GDD도 같이 갱신**. 안 그러면 다음 Phase에서 "GDD엔 32×20인데 코드는 48×24네?" 충돌 발생.

→ SPEC §변경 범위에 `docs/GDD.md` 명시 추가.

### 4-4. 디자인 결정의 *번복 가능성*
1-4 → 1-5 카메라 정책 번복은 **정상**. 게임 디자인은 *플레이 후* 정책이 바뀌는 게 흔함. 회고를 잘 남겨두면 미래의 자신/Claude가 "왜 1-5에서 1-4를 뒤집었지?"를 이해 가능.

### 4-5. 회귀 보존 vs 디자인 변경
- 1-3 합격 자산 (DPadNode, GameConfig 1-3 추가분, scaleMode .resizeFill 핫픽스) — **보존**
- 1-2 합격 자산 (worldNode, cameraNode, addCornerMarkers) — **보존**
- 1-1 합격 자산 (Config 4 파일 mtime) — **보존**
- 1-4 §기능 1 (PlayerNode 자체 클램프) — **보존**
- 1-4 §기능 2 (GameScene 카메라 클램프 헬퍼) — **삭제** (이게 이번 작업의 본질)

회귀 보존과 디자인 변경의 경계를 SPEC에 명확히 그어야 Generator가 헷갈리지 않음.

---

## 5. 산출물 (예정)

### 새로 만드는 파일
**없음.**

### 수정하는 파일
| 파일 | 변경 |
|---|---|
| `Config/GameConfig.swift` | `mapColumns: 32 → 48`, `mapRows: 20 → 24`. 다른 상수 0바이트 변경 |
| `GanhoMusic Shared/GameScene.swift` | `update(_:)` 끝의 `cameraNode.position = clampedCameraPosition(...)` → `cameraNode.position = player.position` 한 줄. `// MARK: - Camera Clamp (Phase 1-4)` 섹션 + `clampedCameraPosition(forPlayerAt:)` 헬퍼 통째로 삭제 |
| `docs/GDD.md` | §6 맵 시스템 명세 갱신 (32×20 → 48×24, "Phase 1-5 재설계" 메모) |

### 절대 손대지 않는 파일
- `Nodes/PlayerNode.swift` — 1-4 자체 클램프 식 그대로
- `Nodes/DPadNode.swift` — 0바이트
- `Config/GameState.swift`, `Config/PhysicsCategory.swift`, `Config/ColorTokens.swift` — 0바이트
- `iOS/AppDelegate.swift`, `SceneDelegate.swift`, `GameViewController.swift` — 0바이트
- `project.pbxproj` — 0바이트

### Xcode 멤버십
**필요 없음.** 새 .swift 파일 0건.

---

## 6. 검증 방법 ✅

### 6-1. 정량 검증
```bash
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
  -scheme "GanhoMusic iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```
- 빌드 에러 0, 경고 0
- `clampedCameraPosition` 식별자 GameScene에서 0건 (삭제 검증)
- `GameConfig.mapColumns == 48`, `mapRows == 24`
- mapWidth/mapHeight는 파생값 그대로 (코드 변경 0줄, 값만 자동 변경)

### 6-2. 시각 검증 (사용자 시뮬레이터)
`⌘R` 후:
- (a) 박스가 어디로 가든 **항상 화면 정중앙 부근** 유지 (드론 follow)
- (b) corner 마커(분홍 4개)가 박스 이동에 따라 화면 안팎으로 흐름 — 1-2와 동일한 패턴 회귀
- (c) 박스가 맵 가장자리(x=0 또는 mapWidth=960)에 닿으면 **여전히 멈춤** (PlayerNode 자체 클램프 1-4 유지)
- (d) 박스가 맵 가장자리 가까이 가면 화면 한쪽에 검은 영역이 살짝 보임 — *맵 끝* 시각 신호로 활용
- (e) 맵이 더 넓어졌으니 박스가 한 끝에서 반대 끝까지 이동하는 데 시간 더 걸림 (탐험감)
- (f) D-Pad 우하단 고정 (1-3 그대로)
- (g) 가로 모드 강제 (Phase 0 그대로)

### 6-3. 회귀 (1-4 합격 자산 + 핫픽스 보존)
- PlayerNode 자체 클램프 4줄 보존 (1-4 §기능 1)
- DPadNode 0바이트 변경
- GameConfig 다른 상수 (`gameDuration`, `tileSize`, `playerBaseSpeed`, `playerWidth/Height`, `dpadButtonSize/Alpha/MarginX/Y`, `cornerMarkerSize`) 0바이트
- scaleMode `.resizeFill` 핫픽스 그대로
- 노드 트리 4 인스턴스(`worldNode`/`cameraNode`/`player`/`dpad`) 그대로
- setup 함수들 본문 그대로

---

## 7. 사용자 결정 (이미 OK 받음)

| # | 결정 | 선택 |
|---|---|---|
| ① | 카메라 정책 | **B (드론 follow — 항상 player 중앙)** ✅ |
| ② | 맵 크기 | **48×24 = 960×480pt** ✅ |
| ③ | PlayerNode 자체 클램프 | **유지** (박스는 맵 안에 갇힘) ✅ |

---

## 8. SPEC에 들어갈 핵심 제약 (Planner에게 전달)

- **변경 유형**: 게임플레이 + 비주얼 (카메라 정책 + 맵 크기 변경)
- **게임 경험 의도**:
  > "박스가 어디로 움직이든 늘 화면 정중앙에 있다 — 카메라가 드론처럼 따라온다. 맵이 더 넓어져 탐험감이 생긴다. 맵 가장자리에 가까워지면 화면 한쪽에 검은 영역이 보여 자연스럽게 '벽이 가깝다'를 알린다."
- **Sprint 범위 계약**:
  - **IN**:
    - `Config/GameConfig.swift`: `mapColumns 32 → 48`, `mapRows 20 → 24` (정확히 2개 값 변경)
    - `GanhoMusic Shared/GameScene.swift`: `update(_:)` 끝의 `cameraNode.position = clampedCameraPosition(...)` → `cameraNode.position = player.position`. `// MARK: - Camera Clamp (Phase 1-4)` 섹션 + `clampedCameraPosition(forPlayerAt:)` 헬퍼 함수 통째로 삭제.
    - `docs/GDD.md`: §6 맵 시스템 명세 갱신
  - **OUT**:
    - PlayerNode 자체 클램프 변경 (1-4 §기능 1 보존)
    - `mapWidth`/`mapHeight` 파생값 직접 수정 (mapColumns/mapRows 변경으로 자동 갱신되어야 함)
    - `tileSize` 변경
    - 카메라 lerp 도입
    - SKPhysicsBody, HUD, 음표/적, 맵 타일
    - 새 .swift 파일, project.pbxproj 변경
    - scaleMode 변경 (1-3 핫픽스 보존)
- **준수 룰**:
  - `!` 강제 언래핑 0건 (`fatalError` 면제)
  - `Timer` / `print()` / `as!` / `fileprivate` / SKAction / SKPhysicsBody / physicsWorld 0건
  - `update()` 안 `addChild()` 0건
  - 매직 넘버 0건 — 모든 수치는 GameConfig 또는 자명한 산술
  - GameScene update가 4단계가 아닌 **3단계**로 줄어듦 (input → playerUpdate → cameraFollow). 깔끔하게 정돈
- **회귀 보존 (1-4 §기능 1 + 1-3 + 1-2 + 1-1 + 핫픽스)**:
  - PlayerNode 자체 클램프 4줄 (1-4 §기능 1) 보존
  - PlayerNode `init`/`required init?(coder:)`/`name` 보존
  - DPadNode 전체 보존 (0바이트)
  - GameConfig 다른 상수 보존 (mapColumns/mapRows 외 0바이트)
  - 1-3 핫픽스 `scaleMode = .resizeFill` 보존
  - worldNode/cameraNode/player/dpad 4 인스턴스 보존
  - `setupBackground/setupWorld/setupPlayer/setupCamera/setupDPad/addCornerMarkers` 본문 보존
  - `didMove(to:)` 호출 순서 보존
  - 1-1 자산 4 파일 + iOS 3 파일 + project.pbxproj 0바이트

---

## 9. 회고 (작업 후 채움) 📝

### 9-1. 막혔던 것
**없었음.** 모든 변경이 *덜어내기* 위주(헬퍼 함수 24줄 삭제 + 1줄 교체 + 2 값 변경) — 빌드 1차 통과, 회귀 9개 파일 mtime + size 모두 0바이트, P0 위반 0. 가장 빠르게 끝난 Phase 1 작업.

> **인사이트**: 코드를 *덧붙이는* 작업보다 *덜어내는* 작업이 위험도 낮음. 추가는 새 의존/사이드이펙트가 생기지만, 삭제는 기존 호출부가 깔끔히 따라옴.

### 9-2. Spring과 다르네 싶었던 것
1. **`static let` 파생값의 자동 갱신**: `mapColumns: 32 → 48` 한 곳만 바꿨는데 `mapWidth`(파생식 `tileSize * CGFloat(mapColumns)`)가 자동으로 `640 → 960`이 됨. 호출부 코드 변경 0건. Spring `@Value("${app.map.cols}")`와 비슷하지만 더 *컴파일 타임*에 결정.
2. **디자인 정책의 번복은 정상**: 1-4에서 카메라 클램핑이 GanhoMusic 본질에 안 맞음을 시뮬 플레이 후 확인 → 1-5에서 회귀. **회고가 잘 남으면 미래의 자신/Claude가 "왜 1-5에서 1-4를 뒤집었지?"를 이해 가능**.
3. **MARK 섹션 통째 삭제 시 dangling brace 주의**: SPEC §주의사항에서 "MARK 헤더부터 함수 닫는 `}`까지 *통째로 한 번에* 삭제"를 강조. 부분 삭제 시 빌드 실패. SwiftKit/Java 모두 같은 함정인데 Swift는 closure 중첩이 많아 더 헷갈리기 쉬움.
4. **GDD 같은 명세 문서 동기화의 중요성**: 코드만 바꾸고 GDD를 안 바꾸면 다음 Phase에서 "GDD엔 32×20인데 코드는 48×24네?" 충돌. SPEC §기능 3에 GDD 갱신을 명시적으로 포함시킨 게 핵심.
5. **회피 게임 vs 횡스크롤 게임 카메라 패턴**: 게임 장르가 카메라 정책을 결정. 슈퍼마리오는 클램핑이 정답이지만 디아블로/회피 게임은 드론 follow가 정답. **게임 정체성 분석이 코딩보다 먼저**.
6. **회귀 보존의 *수동* 강제**: SPEC에 "PlayerNode 0바이트", "DPadNode 0바이트" 명시 + Evaluator가 mtime/size로 검증. 자동 도구가 없어도 *룰* 명시만으로 회귀를 막을 수 있음.

### 9-3. 다음 작업으로 이월된 결정 (Phase 2 진입 시)
1. **GDD line 45 텍스트 다이어그램**: `└─ 맵(32×20타일=640×400)은 화면보다 큼 ─┘` 한 줄이 1-5 SPEC 범위 밖이라 보존됨. Phase 2 맵 타일 도입 시 함께 정리. (P2 — 빌드/동작 무관)
2. **음표 스폰 패턴**: 맵이 48×24=960×480으로 넓어졌으니 음표 동시 5개도 *공간적 분산*이 더 잘 됨. Phase 2에서 SpawnSystem이 `mapWidth - margin`/`mapHeight - margin` 영역에서 랜덤 좌표 산출.
3. **맵 외곽 벽 시각화**: 현재 PlayerNode가 맵 가장자리에서 *멈추긴 하지만* 벽이 시각적으로 안 보임 → 검은 영역으로만 인지. Phase 2에서 외곽 벽 타일(예: ganhoPaper 또는 어두운 색) 도입 시 명확해짐.
4. **카메라 lerp 보간 시점**: 1-5도 직접 추종 유지. 음표/적이 추가되어 player가 빠르게 가속할 때 멀미 체감되면 그때 lerp 도입.
5. **corner 마커 폐기**: Phase 2 맵 타일 도입 시 자연 폐기. 현재는 카메라 follow 시각 검증용으로 유지.
6. **GameConfig 새 섹션**: Phase 2에서 음표/적 관련 상수가 추가됨 — `// MARK: - Notes`, `// MARK: - Enemy` 신설 예상.

### 9-4. 평가 점수 (QA_REPORT.md 기준)
- Swift 패턴 (35%): **10 / 10** — 코드 덜어내기 깔끔, 헤더 보존, MARK 5섹션 정돈
- 게임 로직 (30%): **10 / 10** — SPEC §기능 1~3 1바이트 단위 일치, update 3단계로 줄어듦
- 성능 (20%): **10 / 10** — `update()` 안 노드 생성 0, weak 캡처 N/A, 빌드 클린
- 기능 완성도 (15%): **9 / 10** — `BUILD SUCCEEDED`, P0 위반 0. P2 1건(GDD line 45 다이어그램 미갱신은 SPEC 범위 밖이라 의도된 보존)
- **가중평균: 9.7 / 10 — 합격**

### 9-5. 사용자가 직접 확인할 것 ✅
시뮬레이터 `⌘R` 후 7가지:
- (a) 박스가 어디로 가든 **항상 화면 정중앙 부근** 유지 (드론 follow)
- (b) corner 마커 4개가 박스 이동에 따라 화면 안팎으로 흐름 (1-2 패턴 회귀)
- (c) 박스가 맵 가장자리(x=0/960, y=0/480)에 닿으면 **여전히 멈춤** (PlayerNode 자체 클램프 1-4 유지)
- (d) 박스가 맵 가장자리 가까이 가면 화면 한쪽에 **검은 영역이 살짝 보임** — 자연스러운 *벽 가까움* 신호
- (e) 맵이 더 넓어 박스가 한 끝에서 반대 끝까지 가는 데 **시간이 더 걸림** (탐험감)
- (f) D-Pad 우하단 고정 (1-3 그대로)
- (g) 가로 모드 강제 (Phase 0 그대로)

---

## 10. 다 읽었다면 다음은?

```
[1] (사용자 §7 결정 이미 OK)
[2] rm -f SPEC.md SELF_CHECK.md QA_REPORT.md
[3] Planner   → SPEC.md     (위 §8을 입력으로)
[4] Generator → GameConfig 2값 + GameScene 헬퍼 삭제 + GDD §6 갱신 + SELF_CHECK.md
[5] Evaluator → QA_REPORT.md
[6] 합격 시 §9 회고 채우고 → 🎉 Phase 1 진짜 종결, Phase 2(음표+적+HUD)로
   불합격 시 Generator 재호출 (최대 3회)
```

> **Phase 1-5는 1-4의 *디자인 회귀*다.** 게임 디자인은 한 번에 정답이 안 나오고, 플레이 후 뒤집히는 게 자연스럽다. 회고에 *왜 뒤집었는지*를 잘 남겨두면 미래의 자신/Claude가 같은 실수를 안 반복.
