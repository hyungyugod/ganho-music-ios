# 02 · Phase 1-2 · 월드 + 카메라 골격

> **이번 작업의 한 줄**: 화면(viewport)보다 큰 게임 월드를 만들고, 카메라가 임시 박스를 따라다니게 한다.
> 비유: Spring으로 치면 컨트롤러는 그대로 두고 **비즈니스 데이터가 들어갈 컨테이너(`worldNode`)와 그걸 비추는 렌즈(`cameraNode`)를 끼워 넣는 단계**.

---

## 1. 한눈 요약

```
Phase 1-1 (지금)                       Phase 1-2 (이번 작업)
┌──────────────────────┐              ┌──────────────────────┐
│                      │              │  ┌─ map 640×400 ─┐   │  ← 화면(가로 시뮬)보다
│     GanhoMusic       │     ──→      │  │  ▣          ▣ │   │     맵이 큼
│                      │              │  │     □→        │   │  ← 임시 박스 자동 이동
│   (검은 빈 씬)        │              │  │  ▣          ▣ │   │  ← 카메라가 박스 따라감
└──────────────────────┘              │  └───────────────┘   │     (corner 마커가
                                      │                      │      뷰포트 안팎으로
                                      └──────────────────────┘      들어왔다 나갔다 함)
```

**보이지 않는 곳에서**: `GameScene` 안에 노드 계층이 처음으로 둘로 나뉜다.
```
GameScene
├── worldNode (SKNode)        ← 카메라가 보는 게임 세계 (이번에 신설)
│   ├── 4개 corner 마커        ← 카메라 follow 시각 확인용
│   └── playerBox (placeholder) ← 임시 박스 (Phase 1-3에서 PlayerNode로 교체)
└── cameraNode (SKCameraNode) ← scene.camera 로 등록 (이번에 신설)
```

**핵심 변화**: 좌표계가 두 개가 된다 — *월드 좌표계*(`worldNode` 안)와 *카메라 좌표계*(`cameraNode` 자식이 가지는 화면 고정 좌표계). 1-2에서는 후자에 노드를 거의 넣지 않지만, 구조를 미리 잡아두는 게 본 작업의 본질.

---

## 2. 무엇을, 왜?

### 무엇을 만드나
| 만드는 것 | 한 줄 설명 | 비유 |
|---|---|---|
| `worldNode: SKNode` | 게임 월드(맵·캐릭터·음표·적)를 모두 담을 컨테이너 | "비즈니스 도메인 컨테이너" |
| `cameraNode: SKCameraNode` | 화면을 비추는 카메라. 매 프레임 박스를 따라감 | "관찰자 / 뷰포트" |
| 4개 corner 마커 (임시) | 맵의 4 모서리에 색깔 사각형. 카메라 이동을 눈으로 검증 | "디버그 가이드 라인" |
| `playerBox` (임시 박스) | `SKSpriteNode(color:size:)` — Phase 1-3에서 정식 `PlayerNode`로 교체 | "스텁 객체" |
| `GameConfig`에 상수 추가 | `mapWidth`/`mapHeight` 파생값, 박스 크기, 자동 이동 속도 | "yml 설정 추가" |

### 왜 지금?
1. **카메라 follow는 게임 정체성이다.** 사용자(개발자)가 풀스크린 + 카메라 follow 모델을 핵심 메커닉으로 확정함(2026-05-04). PlayerNode/D-Pad/입력보다 **먼저** 골격을 잡아야 이후 모든 노드가 처음부터 올바른 좌표계에 놓인다.
2. **PlayerNode를 만들기 전 단계**다. 정식 PlayerNode는 입력 시스템(D-Pad)에 의존한다. 그런데 카메라가 따라갈 *대상*이 있어야 하는데 PlayerNode를 먼저 만들면 너무 많은 게 한 번에 들어가서 Evaluator 피드백이 무뎌진다. → **임시 박스 + 자동 이동**으로 카메라 follow만 단독 검증.
3. **스코프를 작게 유지하려면** 입력·물리·HUD·맵 충돌 전부 다음 작업 단위(1-3, 1-4)로 미뤄야 한다.

### 무엇을 하지 않나 (작업 단위 분리)
| 안 하는 것 | 미루는 곳 |
|---|---|
| `PlayerNode` 정식 클래스 | Phase 1-3 |
| D-Pad 오버레이·터치 입력 | Phase 1-3 |
| 월드 경계 충돌 (박스가 벽에 막히기) | Phase 1-4 |
| 카메라 클램핑 (양 끝에서 카메라가 안 나감) | Phase 1-4 |
| HUD (점수/타이머 라벨) | Phase 2 |
| `SKPhysicsBody` 부착 | Phase 1-4 |
| 카메라 lerp(부드러운 추종) | 필요 시 Phase 1-3 이후 결정 |

---

## 3. Spring 비유 🌱

### 3-1. `worldNode` ≈ 도메인 컨테이너 / `cameraNode` ≈ View 어댑터

Spring(clonebose)로 비유하면 이렇게 매핑된다:

| SpriteKit | Spring |
|---|---|
| `GameScene` | `@RestController` |
| `worldNode` (게임 월드) | `Service`가 다루는 **도메인 객체 그래프** (Order, OrderItem, Customer …) |
| `cameraNode` (관찰자) | **DTO / View** — 도메인의 일부를 잘라 클라이언트에게 노출 |
| `cameraNode.position = player.position` (매 프레임) | View가 매 요청마다 도메인의 특정 슬라이스를 골라 보여주는 것 |

핵심은: **도메인(worldNode)은 화면 크기를 모른다**. 화면이 어디를 비추는지는 카메라(View)의 책임이다. 이 분리가 게임을 **확장 가능**하게 만든다(맵이 1024×1024로 커져도 worldNode 안 노드는 그대로).

### 3-2. 좌표계 = 두 개의 컨텍스트
Spring에서 같은 `User` 객체를 **DB 컬럼 좌표**(JPA Entity)와 **응답 JSON 좌표**(DTO)로 다르게 보는 것과 비슷.
- 월드 좌표: 박스가 (320, 200)에 있다 = 맵 정중앙
- 카메라 좌표: 박스는 항상 (화면 중앙)에 보인다 — 카메라가 (320,200)을 비추고 있으니까

이번엔 카메라 좌표계 자식이 거의 없지만, 1-3부터 D-Pad가, 2부터 HUD가 카메라 자식으로 들어간다.

---

## 4. Swift / SpriteKit 학습 포인트 📘

### 4-1. `SKNode`는 좌표 변환 + 자식 묶기 그 자체
```swift
let worldNode = SKNode()                     // 시각 표현 없음. 좌표 컨테이너.
worldNode.position = CGPoint(x: 0, y: 0)
addChild(worldNode)
worldNode.addChild(playerBox)                // playerBox는 worldNode 좌표계 안
```

`SKNode`는 그릴 게 없다(`SKSpriteNode`의 부모 클래스). 좌표 변환·자식 묶음·visibility(`isHidden`)·alpha 등 **노드 트리의 공통 메타데이터**만 들고 있다. Spring으로 치면 **`@Service`가 자식 `@Repository` / `@Component`를 들고 있는 것**과 비슷.

> **Java로 치면**: `Container<Component>` 같은 패턴. 자체 렌더는 없고 자식 위치/표시 상태만 통제.

### 4-2. `SKCameraNode` = 씬을 비추는 카메라
```swift
let cameraNode = SKCameraNode()
addChild(cameraNode)                  // 씬의 자식으로 등록
self.camera = cameraNode              // 씬에 "이게 메인 카메라" 통보 (필수)

cameraNode.position = CGPoint(x: 320, y: 200)   // 카메라가 (320,200)을 비춤
```

3가지가 중요:
1. `addChild`로 노드 트리에 넣어야 함 (안 넣으면 동작 안 함)
2. `scene.camera = cameraNode`로 등록해야 SpriteKit이 인식
3. 카메라의 `position`이 **화면 중앙**이 보는 월드 좌표가 됨

> **착각 주의**: 카메라가 움직인다고 다른 노드 좌표가 바뀌지 않는다. 다른 노드는 월드 좌표 그대로, **렌더링되는 영역만** 바뀐다. → 이 분리 덕분에 충돌 계산은 카메라와 무관.

### 4-3. 매 프레임 추종 (`update(_:)` 안에서)
```swift
override func update(_ currentTime: TimeInterval) {
    // ... dt 계산 ...
    guard gameState == .playing else { return }
    cameraNode.position = playerBox.position    // 직접 추종
}
```

`update(_:)`는 **매 프레임(보통 60fps)** 호출된다. Spring의 스케줄러보다 훨씬 자주 도는 루프. dt(직전 프레임과의 시간차)를 곱해서 모든 이동/타이머를 보간해야 fps가 흔들려도 게임 속도가 일정하다.

### 4-4. dt 기반 이동 (Timer 금지의 이유)
```swift
// ❌ 나쁜 패턴 — 프레임률 의존
playerBox.position.x += 1                       // fps 60이면 60pt/s, 30이면 30pt/s

// ✅ 좋은 패턴 — dt 보간
let speed: CGFloat = 60                         // pt/s
playerBox.position.x += CGFloat(dt) * speed     // fps와 무관하게 60pt/s
```

Spring `@Scheduled(fixedRate=...)`는 절대 시간 기반이지만, 게임 루프는 **렌더 프레임에 맞춰** 도는 가변 주기다. 그래서 dt를 곱하는 게 표준.

### 4-5. `SKAction` vs `update(_:)` — 둘 다 가능, 언제 무엇?
박스 자동 이동 방식 두 가지:
```swift
// (a) SKAction — 선언형, 짧고 안전
let moveRight = SKAction.moveBy(x: 200, y: 0, duration: 2)
let moveLeft  = moveRight.reversed()
playerBox.run(.repeatForever(.sequence([moveRight, moveLeft])))

// (b) update(_:) — 명령형, dt 직접 다룸 (학습 목적)
playerBox.position.x += CGFloat(dt) * speed * direction
if playerBox.position.x > maxX || playerBox.position.x < minX { direction *= -1 }
```

이번엔 **(b)를 추천**. 이유: Phase 1-3에서 어차피 `update(_:)` 안에서 입력 → 이동을 직접 짤 텐데, 그 패턴을 미리 손에 익히는 게 학습 가치가 크다. 또 dt 보간이 실제로 동작하는지 눈으로 확인 가능.

### 4-6. SKSpriteNode 색상 박스 = `init(color:size:)`
```swift
let box = SKSpriteNode(color: .ganhoMint, size: CGSize(width: 20, height: 20))
box.position = CGPoint(x: 320, y: 200)   // 월드 중앙
```

이미지 없이도 색깔 사각형 노드를 만들 수 있다 (디버그/플레이스홀더 용). 픽셀 아트 스프라이트는 Phase 4.

### 4-7. 좌표계 다시 — 좌하단 (0,0)
1-1에서 본 건데 한 번 더. 월드 정중앙은 `(mapWidth/2, mapHeight/2) = (320, 200)`. iPhone 가로 시뮬(예: 16세대 ~852×393pt)에서는 화면이 맵보다 가로로 길고 세로로는 거의 비슷. 실제 비율은 시뮬 직접 확인.

---

## 5. 산출물 (예정)

### 새로 만드는 파일
**없음.** Phase 1-2의 변경은 모두 기존 파일에 들어간다 — 1 SPEC = 1 sub-feature 원칙을 지키기 위해 *구조 분리*는 1-3에서 하기로 한다.

> 규모가 큰 것 같으면 SPEC 단계에서 다음을 제안할 수 있다:
> - `Nodes/PlaceholderBox.swift` (임시) — 1-3에서 폐기
> 다만 *임시* 파일은 만드는 비용 대비 가치가 적어 1-2는 GameScene 본문 안에 두는 쪽이 깔끔.

### 수정하는 파일
| 파일 | 변경 |
|---|---|
| `GanhoMusic Shared/GameScene.swift` | `worldNode` / `cameraNode` / `playerBox` 프로퍼티 추가, `didMove(to:)`에서 setup, `update(_:)`에서 박스 dt 이동 + 카메라 follow |
| `GanhoMusic Shared/Config/GameConfig.swift` | `mapWidth`(파생), `mapHeight`(파생), `placeholderBoxSize`, `placeholderBoxAutoSpeed` 추가 |

### 절대 손대지 않는 파일
- `Config/GameState.swift`, `Config/PhysicsCategory.swift`, `Config/ColorTokens.swift` (1-1 합격분)
- `GanhoMusic iOS/AppDelegate.swift`, `SceneDelegate.swift`, `GameViewController.swift`
- `GanhoMusic tvOS/`, `GanhoMusic macOS/` 폴더 전체

### Xcode 멤버십
**필요 없음.** 새 .swift 파일을 만들지 않으므로 `project.pbxproj`를 건드리지 않는다. 1-1에서 골치아팠던 `PBXFileSystemSynchronizedRootGroup` 이슈는 이번엔 비껴 간다. (다음에 새 파일 추가하는 단계인 1-3에서 다시 등장 예정)

---

## 6. 검증 방법 ✅

### 6-1. 정량 검증 (xcodebuild)
```bash
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
  -scheme "GanhoMusic iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```
- 빌드 에러 0개, 경고 최소
- 강제 언래핑 `!` 0개, `Timer` 0개, `print()` 0개, `as!` 0개
- `update()` 안에서 `addChild()` 호출 0건

### 6-2. 시각 검증 (사용자가 직접 시뮬레이터에서)
`⌘R`로 시뮬레이터 켜고 **모두** 만족하는지:
- (a) 화면 중앙에 작은 박스(20×20pt, 민트색) 1개가 좌우로 자동 왕복
- (b) 박스를 따라 배경(corner 마커)이 화면 안팎으로 흐른다 = 카메라가 따라가는 시각 증거
- (c) 박스는 **항상 화면 중앙** 근처에 머문다 (카메라가 박스 위치 = 화면 중앙)
- (d) 4개 corner 마커가 박스가 양 끝으로 갈 때마다 화면에 들어왔다 나갔다 함
- (e) 가로 모드 강제 (Phase 0 설정 유지)
- (f) 1-1의 "GanhoMusic" placeholder 라벨이 **사라졌거나, 월드 중앙(320,200)에 고정**되어 카메라가 멀어지면 화면 밖으로 나감

### 6-3. 회귀 (1-1 합격 자산이 깨지지 않았는지)
- `GameConfig.gameDuration == 45`, `tileSize == 20`, `mapColumns == 32`, `mapRows == 20` 그대로
- `GameState` 4 case 그대로
- `PhysicsCategory`, `ColorTokens` 그대로 (수정 0건)

---

## 7. SPEC에 들어갈 핵심 제약 (Planner에게 전달)

- **변경 유형**: 비주얼 + 게임플레이 (카메라 골격은 게임 메커닉의 시작)
- **게임 경험 의도**:
  > "맵이 화면보다 크다는 것이 보인다. 박스가 움직이면 카메라가 따라간다. 즉, 게임 월드가 살아있다."
  > 인터랙션은 없다 — 박스는 자동 왕복.
- **Sprint 범위 계약**:
  - 산출물: GameScene.swift 수정 + GameConfig.swift 상수 추가 — 2개 파일만
  - 새 .swift 파일 생성 0건
  - 다른 폴더(Nodes/Systems/Scenes 등) 진입 0건
  - PlayerNode·D-Pad·HUD·SKPhysicsBody·맵 경계 충돌·카메라 클램핑·맵 타일·BPM 전부 **out-of-scope**
- **준수 룰**:
  - `!` 0개, `Timer` 0개, `print()` 0개, `as!` 0개, `fileprivate` 0개
  - `MARK: -` 섹션 사용
  - `update()` 안 `addChild()` 0건 (셋업은 모두 `didMove(to:)` 또는 `setupXxx()`에서)
  - 박스 자동 이동은 `update(_:)` + dt 보간 방식 (학습 목적)
  - `cameraNode.position = playerBox.position` 직접 대입 (lerp 미적용, 클램핑 없음 — 1-3/1-4)
- **의존성 방향**:
  - GameScene → GameConfig (OK), GameScene → ColorTokens (OK)
  - GameConfig는 누구도 import하지 않음 (가장 안쪽 레이어 유지)
- **out-of-scope 위반 0건 강제**

---

## 8. 회고 (작업 후 채움) 📝

### 8-1. 막혔던 것
**없었음.** 1-1에서 가장 골치아팠던 `PBXFileSystemSynchronizedRootGroup`(Xcode 동기화 그룹) 이슈는 이번엔 비껴 갔다. 새 .swift 파일을 0건 만들기로 SPEC에서 못 박은 덕분 — 모든 변경이 기존 파일 2개(GameScene.swift, GameConfig.swift) 안에서 끝났고 `project.pbxproj`는 1바이트도 안 건드림.

> Phase 1-3에서 `Nodes/PlayerNode.swift`를 신설할 때 다시 등장 예정. 이번 작업의 깔끔함은 새 파일 0건이라는 스코프 결정이 만들어낸 결과지, 이슈가 사라진 게 아님을 명심.

### 8-2. Spring과 다르네 싶었던 것
1. **카메라가 "노드"다** — `SKCameraNode`도 결국 `SKNode`의 일종. `addChild`로 트리에 넣고 `scene.camera = ...`로 등록하는 두 단계가 필요. Spring으로 치면 `View`도 `Bean`이라서 컨텍스트에 등록(`@Component`) 후 `@RequestMapping`에 연결하는 두 단계 같은 느낌.
2. **좌표계가 두 개 살아 있다** — 월드 좌표(worldNode 안)와 화면/카메라 좌표(scene root). `placeholder` 라벨이 worldNode 자식이라 카메라가 멀어지면 화면 밖으로 흐르고, 카메라 자식이 되면 화면 고정(HUD). 같은 노드라도 부모가 누구냐로 운명이 갈림. JPA Entity vs DTO 같은 두 컨텍스트 분리.
3. **`update(_:)`가 1초에 60번 도는 무한 루프** — Spring `@Scheduled(fixedRate=...)`가 비유로 가장 가깝지만, 정확도와 빈도 모두 비교 안 됨. 그래서 Timer 같은 절대시간 도구 대신 **dt 보간**이 표준.
4. **`static let` 사이 의존이 합법** — `GameConfig.mapWidth = tileSize * CGFloat(mapColumns)` 처럼 정적 상수가 다른 정적 상수를 참조해도 컴파일 OK. Java `static final` 같은 자리에 가깝지만 더 자연스러움.
5. **dt가 큰 프레임에서 경계 떨림 방지 패턴** — `position.x = maxX` 로 *고정*시키고 방향 반전. 안 그러면 한 프레임에 경계를 살짝 넘은 박스가 다음 프레임에 또 넘어가는 떨림 발생. Spring 도메인 코드엔 거의 없는 *프레임 단위* 사고방식.
6. **`!` 정밀 grep 표현식** — Bool 부정 `!isReady` 와 강제 언래핑 `value!` 가 같은 문자라서 카운팅이 까다로움. Evaluator가 `'\![^=]'` 와 함수 본문 `awk` 추출로 정밀하게 잡아냄.

### 8-3. 다음 작업으로 이월된 결정
1. **`playerBox` 프로퍼티 폐기** — Phase 1-3에서 `Nodes/PlayerNode.swift` 신설 후 `playerBox`/`boxDirection` 두 프로퍼티 삭제. 새 파일 추가 시 `project.pbxproj` 멤버십 갱신(1-1 패턴) 필요할 가능성 매우 높음.
2. **`update(_:)` 4단계 패턴 재사용** — dt 계산 → gameState 가드 → 이동 → 카메라 follow. 1-3에선 이동의 입력 소스가 `boxDirection` → D-Pad에서 읽은 `inputDirection`(vector2)로 바뀌고, x뿐 아니라 y도 갱신.
3. **카메라 클램핑은 1-4** — 박스가 D-Pad로 자유롭게 움직이기 시작하면 카메라가 맵 바깥(검은 영역)을 비출 수 있음. 사용자 체감으로 "어색함" 확인되면 `min/max` 클램프 도입.
4. **lerp follow 적용 시점** — 현재 60pt/s에서는 부작용 없음. 1-3 PlayerNode 도입 후 박스가 빠르게 가속할 때 멀미 느껴지면 그때 도입.
5. **placeholder 라벨 거취** — Phase 2에서 HUD를 cameraNode 자식으로 추가하기 시작하면 시작 화면(StartScene)으로 분리하거나 제거. 현재 worldNode 자식으로 안전하게 잔존.
6. **왕복 비율 0.25/0.75** — SPEC §준수 룰 8에서 "비율은 매직 넘버 예외"로 합의. 1-3 입력으로 풀리는 시점에 자연스럽게 사라짐.

### 8-4. 평가 점수 (QA_REPORT.md 기준)
- Swift 패턴 (35%): **9.5 / 10** — 강제 언래핑·Timer·print·SKAction·DispatchQueue 모두 0건. P2 권고 1건(라벨 fontName 주석 보강은 룰 위반 아님)
- 게임 로직 / 의도 충실도 (30%): **10 / 10** — SPEC §기능 1~6 라인 단위 일치, 경계 떨림 방지 정석 구현
- 성능 / 메모리 안전성 (20%): **10 / 10** — `update()` 안 노드 생성 0건, 누수 위험 0
- 기능 완성도 / 빌드 (15%): **9 / 10** — `BUILD SUCCEEDED`, 시각 검증 (a)~(f) 모두 코드상 보장. 시뮬레이터 직접 확인은 사용자 몫
- **가중평균: 9.65 / 10 — 합격**

### 8-5. 사용자가 직접 확인할 것 ✅
시뮬레이터(`⌘R`)에서 6가지:
- (a) 화면 중앙에 작은 민트색 박스(20×20pt)가 좌우로 자동 왕복
- (b) 박스를 따라 분홍 corner 마커(16pt) 4개가 화면 안팎으로 흐름 — 카메라 follow의 시각 증거
- (c) 박스가 항상 화면 중앙 근처에 머무름
- (d) 박스가 양 끝(minX=160, maxX=480)에 도달할 때 corner 마커가 화면 가장자리로 들어왔다 나갔다 함
- (e) 가로 모드 강제 (Phase 0 설정 유지)
- (f) "GanhoMusic" 라벨이 월드 중앙(320, 200)에 고정 — 박스가 중앙을 지날 때 라벨 위에 박스가 겹침

---

## 9. 다 읽었다면 다음은?

```
[1] 사용자 OK
[2] rm -f SPEC.md SELF_CHECK.md QA_REPORT.md
[3] Planner    → SPEC.md      (위 §7을 입력으로)
[4] Generator  → GameScene/GameConfig 수정 + SELF_CHECK.md
[5] Evaluator  → QA_REPORT.md
[6] 합격 시 §8 회고 채우고 → 1-3(PlayerNode + D-Pad)으로
   불합격 시 Generator 재호출 (최대 3회)
```
