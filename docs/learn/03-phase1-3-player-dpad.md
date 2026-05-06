# 03 · Phase 1-3 · PlayerNode 정식 + 반투명 D-Pad + dt 입력 이동

> **이번 작업의 한 줄**: 1-2의 자동으로 왕복하던 임시 박스를 진짜 캐릭터(`PlayerNode`)로 교체하고, **사용자가 손가락으로 D-Pad를 눌러 움직이게** 만든다.
> 비유: Spring으로 치면, 자동 batch job이 도메인을 굴리던 걸 → **사용자 요청(REST API)을 받아 도메인을 굴리는 단계**로 바꾸는 것.

---

## 1. 한눈 요약

```
Phase 1-2 (지금)                           Phase 1-3 (이번 작업)
┌──────────────────────┐                  ┌──────────────────────┐
│  ┌─ map ─┐           │                  │  ┌─ map ─┐           │
│  │ ▣  ▣ │ (corner)  │                  │  │ ▣  ▣ │           │
│  │  □→  │ ← 자동왕복  │       ──→        │  │  □   │ ← PlayerNode│
│  │ ▣  ▣ │ (박스)     │                  │  │ ▣  ▣ │   (16×20)  │
│  └──────┘            │                  │  └──────┘   [▲]      │
│                      │                  │           [◀ ▶]   ← D-Pad
│                      │                  │            [▼]    (반투명)
└──────────────────────┘                  └──────────────────────┘
        손 댈 수 없음                         사용자가 직접 조종 가능
```

**보이지 않는 곳에서**: 노드 트리에 처음으로 두 개의 좌표계가 *모두* 사용된다.
```
GameScene
├── worldNode (1-2부터 있음)
│   ├── corner 마커 4개 (1-2 잔존 / 제거 결정 필요)
│   ├── (1-1) "GanhoMusic" 라벨 — 제거 결정 필요
│   └── PlayerNode (NEW)              ← 월드 좌표계 (이동함)
└── cameraNode (1-2부터 있음)
    └── DPadNode (NEW)                ← 카메라 좌표계 (화면 고정)
        ├── 위 버튼 (▲)
        ├── 좌 버튼 (◀)
        ├── 우 버튼 (▶)
        └── 아래 버튼 (▼)
```

**핵심 변화**: 이번이 게임을 처음 "게임답게" 만드는 작업. 1-1은 작업장 정리, 1-2는 무대 설치, 1-3은 **드디어 배우 등장 + 사용자가 리모컨을 잡음**.

---

## 2. 무엇을, 왜?

### 무엇을 만드나
| 만드는 것 | 한 줄 설명 | 비유 |
|---|---|---|
| `Nodes/PlayerNode.swift` | 김간호 캐릭터 클래스 (`SKSpriteNode` 상속). 입력 방향 받아 dt 보간으로 자기 자신을 이동 | 도메인 객체 (Order, Member 같은) |
| `Nodes/DPadNode.swift` | 화면에 떠 있는 4방향 버튼. 자기 자신의 touch 이벤트를 받아 "지금 어느 방향을 누르는 중인지" 외부에 노출 | UI 컨트롤러 (한 화면에서 입력 받는 클래스) |
| `GameConfig` 상수 추가 | 플레이어 크기, D-Pad 위치/크기/투명도 | application.yml 추가 |
| `GameScene` 수정 | 1-2의 임시 박스/`boxDirection` 제거. PlayerNode + DPadNode 배치, update에서 D-Pad 입력 → Player 이동 → 카메라 follow 연결 | 컨트롤러에 새 의존성 주입 |

### 왜 지금?
1. **1-2까지 완성된 카메라 follow가 진짜 의미를 가지려면 캐릭터가 사용자 입력으로 움직여야 한다.** 자동 왕복은 골격 검증용일 뿐, 게임으로서의 즐거움이 0.
2. **PlayerNode를 한 번 만들어두면 후속 Phase가 모두 여기 의존**한다. 음표 수집(2), 적과의 충돌(2), 결과 화면(3), 캐릭터 선택(5) — 전부 PlayerNode를 가져다 쓴다.
3. **D-Pad를 분리된 노드 클래스로 만들어두면**, 추후 스킬 버튼(5)·HUD(2)·일시정지 버튼(3) 등 모든 UI 오버레이가 같은 패턴(카메라 자식 + 자체 touch 처리)을 따라가게 된다.

### 무엇을 하지 않나 (작업 단위 분리)
| 안 하는 것 | 미루는 곳 | 이유 |
|---|---|---|
| 맵 경계 충돌 (벽에 막히기) | Phase 1-4 | 1-3은 입력+이동만으로도 이미 큼 |
| 카메라 클램핑 (양 끝에서 카메라 정지) | Phase 1-4 | 위와 같음 |
| `SKPhysicsBody` 부착 | Phase 2 | 충돌 대상(음표/적/벽) 자체가 아직 없음 |
| 픽셀 아트 스프라이트 | Phase 4 | 현재는 색깔 박스 (`ganhoMint`) |
| 햅틱 피드백 / 사운드 | Phase 4 | 폴리싱 단계 |
| 스킬 버튼 (좌하단) | Phase 5 | 캐릭터 선택과 한 묶음 |
| 음표/수간호사/F투사체/HUD/타이머 | Phase 2 | 별개의 큰 작업 단위 |
| 8방향 (대각선) 동시 입력 | (필요 시 1-3 이후) | 4방향만 — 마지막 누른 키 우선 정책 |
| 1-2 corner 마커 / "GanhoMusic" 라벨 | 본 학습 노트 §결정 사항 참고 | 사용자 결정 필요 |

---

## 3. Spring 비유 🌱

| 이번에 만드는 것 | Spring/Java 세계 |
|---|---|
| `PlayerNode` (도메인 객체 + 자기 갱신 메서드 `update(deltaTime:)`) | `Order`처럼 도메인 + `recalculateTotal()` 같은 도메인 메서드 들고 다님 |
| `DPadNode` (자체 touch 처리, 입력 방향 노출) | 한 화면의 입력을 받는 `@RestController`. 외부엔 "지금 사용자 의도가 뭐냐"만 노출 |
| `GameScene.update(_:)`에서 `player.currentDirection = dpad.currentDirection` 한 줄 | `Service.handleRequest(dto)` — 컨트롤러 입력을 도메인에 위임하는 핵심 한 줄 |
| `cameraNode.position = player.position` (1-2 그대로) | 응답 직전 DTO 변환 — "도메인 상태를 화면에 어떻게 노출할지" |

**의존성 방향 (지킬 것)**:
```
GameScene  →  PlayerNode (월드 자식)
GameScene  →  DPadNode  (카메라 자식)
DPadNode   →  (외부 의존 없음 — 입력 방향만 노출)
PlayerNode →  GameConfig (속도/크기)
```

DPadNode는 **PlayerNode를 모른다**. GameScene이 매 프레임 D-Pad 방향을 읽어 Player에 전달한다 — 이게 가장 단순하고, Phase 5에서 캐릭터별로 PlayerNode가 바뀌어도 D-Pad는 그대로다(낮은 결합도).

> Spring 비유: `OrderController`가 `OrderService`만 알고, `Order` 도메인은 모르는 것. 의존성은 한 방향으로만.

---

## 4. Swift / SpriteKit 학습 포인트 📘

### 4-1. `SKSpriteNode` 상속 = 도메인 클래스 만들기
```swift
final class PlayerNode: SKSpriteNode {

    /// 현재 입력 방향 (정규화된 단위 벡터). 매 프레임 외부에서 갱신.
    var currentDirection: CGVector = .zero

    /// 외부에서 호출. dt만큼 입력 방향으로 자기 자신 이동.
    func update(deltaTime: TimeInterval) {
        let dx = currentDirection.dx * GameConfig.playerBaseSpeed * CGFloat(deltaTime)
        let dy = currentDirection.dy * GameConfig.playerBaseSpeed * CGFloat(deltaTime)
        position.x += dx
        position.y += dy
    }
}
```

`SKSpriteNode`(이미지/색상 가진 노드)를 상속하여 **자기 자신의 행동(이동)을 자기가 담당**하는 캡슐화 패턴. Java/Spring으로 치면 `Order extends BaseEntity` + 도메인 메서드. Generator는 `final` 키워드를 강제 — 더 이상 상속 안 함을 명시.

> **왜 `final`?** Swift는 `class` 기본이 상속 가능. 상속 안 할 거면 `final`로 컴파일러에 통보 → 가상 디스패치 비용 제거 + 의도 명확. SpriteKit 노드 클래스는 거의 항상 `final`.

### 4-2. `init(color:size:)` 호출 후 추가 초기화 패턴
```swift
final class PlayerNode: SKSpriteNode {
    init() {
        let size = CGSize(width: GameConfig.playerWidth, height: GameConfig.playerHeight)
        super.init(texture: nil, color: .ganhoMint, size: size)
        name = "player"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
```

두 줄이 항상 따라온다:
1. `super.init(texture:color:size:)` — 부모 designated initializer
2. `required init?(coder:)` — `NSCoding` 호환 (sks 파일 또는 Storyboard에서 로드될 가능성). 실제 안 쓰면 `fatalError` (이건 강제 언래핑이 아니라 unreachable 표시 — 룰 위반 아님)

> **`fatalError`는 룰 위반이 아닌가?** 표면상 비슷해 보이지만, `fatalError`는 "이 코드는 실행되지 않는다"는 *의도 표명*. 강제 언래핑(`!`)은 옵셔널을 깐다(런타임에 값이 있다고 *주장*). 다른 카테고리. 룰북 §metric에서도 `fatalError`는 카운트하지 않는다. 단, 본 SPEC 코드 골격에서 `init?(coder:)`는 어쩔 수 없이 등장 — 이건 면제.

### 4-3. `SKNode` 직접 상속 = 자식들의 묶음
```swift
final class DPadNode: SKNode {
    private let upButton:    SKSpriteNode
    private let downButton:  SKSpriteNode
    private let leftButton:  SKSpriteNode
    private let rightButton: SKSpriteNode

    /// 외부 노출 — 지금 사용자가 누르고 있는 방향. 안 누르면 .zero.
    private(set) var currentDirection: CGVector = .zero

    override init() {
        upButton    = SKSpriteNode(color: .ganhoPaper, size: ...)
        downButton  = SKSpriteNode(color: .ganhoPaper, size: ...)
        leftButton  = SKSpriteNode(color: .ganhoPaper, size: ...)
        rightButton = SKSpriteNode(color: .ganhoPaper, size: ...)
        super.init()
        ...
        isUserInteractionEnabled = true   // ← 핵심! touch 받으려면 명시
    }

    required init?(coder: NSCoder) { fatalError(...) }
}
```

핵심 한 줄: **`isUserInteractionEnabled = true`**. 기본값이 `false`라 안 켜면 touch 이벤트가 부모로 흘러간다. `SKNode`는 그릴 게 없으니 size가 없는데, 자식 버튼들이 hit-test 영역을 제공한다.

### 4-4. `private(set) var` — 외부엔 read-only, 내부엔 수정 가능
```swift
private(set) var currentDirection: CGVector = .zero
```

DPadNode 외부에서:
- `dpad.currentDirection`  ✅ 읽기 가능
- `dpad.currentDirection = ...`  ❌ 컴파일 에러

**이게 캡슐화의 정석**. Java로 치면 getter는 public, setter는 private인 패턴. Swift는 한 줄에 표현.

### 4-5. `touchesBegan` / `touchesMoved` / `touchesEnded` — 손가락 시작/이동/끝
```swift
override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let location = touch.location(in: self)   // self(=DPadNode) 좌표계 기준
    updateDirection(forTouchLocation: location)
}
override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { ... }
override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    currentDirection = .zero
}
override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    currentDirection = .zero
}
```

4개를 다 override해야 안전:
- `touchesBegan`: 손가락 닿음
- `touchesMoved`: 손가락 끌림 (D-Pad에서 ▲ → ▶로 슬라이드)
- `touchesEnded`: 손가락 뗌 — 정지
- `touchesCancelled`: 시스템 인터럽트(전화 옴 등) — 정지

`touch.location(in: self)`로 **자기 자신 좌표계**의 touch 위치를 얻는다. 그 위치가 어느 버튼 영역인지로 방향 결정.

> **GDD 규칙**: "누르고 있는 동안 이동" — `touchesEnded`에서 방향을 `.zero`로 리셋해야 정확히 이 동작이 나온다.

### 4-6. 4방향 단일 입력 (마지막 우선) 정책
화면에 한 손가락이 ▲ 위에 있다가 → ▶로 슬라이드하면, `touchesMoved`가 새 위치를 보고 `currentDirection`을 갱신. 두 방향 동시 입력은 `touch.first`로 한 손가락만 보므로 자연 회피.

대각선(▲▶ 동시)이 안 되는 게 단점이지만 **1-3에선 단순함이 우선**. 후속 Phase에서 필요해지면 8방향으로 확장 가능 (영역 분할).

### 4-7. 카메라 자식 = 화면 고정 (HUD 패턴)
```swift
let dpad = DPadNode()
dpad.position = CGPoint(x: +320, y: -200)   // cameraNode 중심 기준 상대 좌표 — 우하단
cameraNode.addChild(dpad)
```

`cameraNode`의 자식은 **카메라가 어디로 가든 화면의 같은 자리**에 그려진다. (0,0)이 화면 중앙이고, +x가 우, +y가 상. 우하단 = (positive x, negative y).

> **scene size = 1024×768**: 1-2의 `newGameScene()` 그대로. cameraNode 자식의 좌표 한계도 ±size/2 = (±512, ±384) 안. 마진 고려해 (+400, -300) 정도가 우하단.

### 4-8. `CGVector` — 2D 벡터
```swift
let direction = CGVector(dx: 1, dy: 0)   // 오른쪽 단위 벡터
let direction = CGVector(dx: 0, dy: 1)   // 위
let direction = CGVector(dx: 0, dy: -1)  // 아래
let direction = CGVector(dx: -1, dy: 0)  // 왼쪽
let direction = CGVector.zero            // 안 누르고 있음
```

`CGPoint`(좌표 — "어디 있냐")와 `CGVector`(벡터 — "어느 방향 얼마")는 별개 타입. 의미를 코드 레벨에서 분리하는 게 Swift 표준. 1-1의 `boxDirection: CGFloat`(±1)은 1차원이라 Float로 충분했지만, 이제 2D라 CGVector.

---

## 5. 산출물 (예정)

### 새로 만드는 파일
| 파일 | 책임 |
|---|---|
| `GanhoMusic Shared/Nodes/PlayerNode.swift` | 김간호 캐릭터 클래스. `currentDirection` 외부 입력 받아 dt 이동 |
| `GanhoMusic Shared/Nodes/DPadNode.swift` | 4방향 버튼 묶음. 자체 touch 처리, `currentDirection` 외부 노출 |

> ⚠️ **Xcode 동기화 그룹 함정 재등장**: 1-1 §8-1에서 겪은 `PBXFileSystemSynchronizedRootGroup`이 `Nodes/` 하위 첫 .swift 파일 인식 못하는 이슈. Generator가 `project.pbxproj`에 `PBXBuildFile`/`PBXFileReference`/`PBXGroup`/`PBXSourcesBuildPhase` 4개 항목을 직접 편집해야 함. iOS 타겟에만 등록.

### 수정하는 파일
| 파일 | 변경 |
|---|---|
| `GanhoMusic Shared/GameScene.swift` | (1) 1-2의 `playerBox`/`boxDirection`/`addCornerMarkers`/`addPlaceholderLabel` 제거 또는 정리, (2) `player: PlayerNode` / `dpad: DPadNode` 프로퍼티, (3) `setupPlayer()` / `setupDPad()`, (4) `update(_:)`에서 `player.currentDirection = dpad.currentDirection` → `player.update(deltaTime:)` → `cameraNode.position = player.position` |
| `GanhoMusic Shared/Config/GameConfig.swift` | 플레이어 크기(`playerWidth=16`, `playerHeight=20`), D-Pad 관련(`dpadButtonSize`, `dpadAlpha=0.3`, `dpadMarginX`, `dpadMarginY`) 추가. 1-2의 `placeholder*` 상수는 **정리/제거 결정** |

### 절대 손대지 않는 파일
- `Config/GameState.swift`, `Config/PhysicsCategory.swift`, `Config/ColorTokens.swift` (1-1 합격분, mtime 보존)
- `GanhoMusic iOS/AppDelegate.swift`, `SceneDelegate.swift`, `GameViewController.swift`
- `GanhoMusic tvOS/`, `GanhoMusic macOS/`

### Xcode 멤버십 (재등장)
- `Nodes/` 폴더 신설 + 2개 .swift 파일 등록
- iOS 타겟의 Sources Build Phase에 추가
- tvOS/macOS 타겟엔 추가하지 않음 (1-1 정책 유지)

---

## 6. 검증 방법 ✅

### 6-1. 정량 검증
```bash
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
  -scheme "GanhoMusic iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```
- 빌드 에러 0, 경고 최소
- `!` 강제 언래핑 0건 (`fatalError`는 면제)
- `Timer` 0건, `print()` 0건, `as!` 0건, `fileprivate` 0건
- `update()` 안 `addChild()` 호출 0건
- 4개 신규 파일이 SwiftFileList에 등록됨 (1-1 패턴 검증)

### 6-2. 시각 검증 (시뮬레이터)
`⌘R` 후:
- (a) 화면 중앙에 민트색 박스(16×20pt) 1개 — PlayerNode
- (b) 우하단에 4방향 D-Pad (반투명, 알파 0.3)
- (c) 시뮬레이터에서는 **마우스 드래그**로 D-Pad 영역 안에서 ▲/▼/◀/▶ 누른 상태 유지
- (d) 누르고 있는 동안 PlayerNode가 해당 방향으로 이동
- (e) 손 떼면 PlayerNode 정지
- (f) 카메라가 PlayerNode를 따라가서 박스는 늘 화면 중앙
- (g) corner 마커(1-2)가 PlayerNode 이동에 따라 화면 안팎으로 흐름
- (h) D-Pad는 카메라 자식이므로 PlayerNode가 아무리 멀리 가도 우하단 고정
- (i) 가로 모드 강제 (Phase 0)

### 6-3. 회귀 (1-2 합격 자산)
- `GameConfig.gameDuration / tileSize / mapColumns / mapRows / playerBaseSpeed / mapWidth / mapHeight` 그대로
- `GameState`, `PhysicsCategory`, `ColorTokens` 0바이트 변경
- `cameraNode` follow 동작 그대로 (`cameraNode.position = player.position`)
- `worldNode` 구조 그대로 (이름·계층·자식 등록 패턴)
- `gameState = .playing` 전환 그대로
- `setupBackground()` `.ganhoBgDeep` 그대로

---

## 7. 사용자 결정 필요 사항 (학습 노트 단계)

Planner 호출 전 사용자가 골라야 진행 가능한 결정 4건:

### 결정 ① · 1-2 corner 마커(분홍 4개) — **유지 vs 제거**
- **유지**: 카메라 follow 시각 증거가 그대로. 1-3에선 PlayerNode가 자유롭게 움직이니 D-Pad로 모서리까지 가보는 재미.
- **제거**: 화면이 깔끔. PlayerNode + D-Pad만으로도 카메라 동작이 충분히 보임.
- 추천: **유지** (1-3 입력 동작의 가시성에 도움. 1-4 맵 경계 시각화 시 어차피 다른 방식으로 대체될 임시물).

### 결정 ② · 1-1의 "GanhoMusic" 라벨 — **유지 vs 제거**
- **유지**: 월드 중앙에 그대로. PlayerNode가 중앙 지날 때 라벨에 박스 겹침.
- **제거**: 1-1·1-2의 임시 안내였으니 게임다워지는 1-3에서 정리.
- 추천: **제거**. 1-3부터는 라벨이 의미 없음. corner 마커와 PlayerNode/D-Pad가 시각 단서로 충분.

### 결정 ③ · D-Pad 4방향 단일 vs 8방향 동시
- **4방향 단일 (한 번에 한 손가락 한 방향)**: 단순. ▲ → ▶ 슬라이드로 방향 전환. 대각선 안 됨.
- **8방향 동시**: ▲+▶ 동시로 우상향. 손가락 두 개 또는 영역 분할 필요. 코드 복잡도 +50%.
- 추천: **4방향 단일**. GDD §7-1도 4방향 명시. 8방향이 정말 필요한지는 플레이 후 결정.

### 결정 ④ · D-Pad 노드를 별도 클래스로 분리 vs GameScene 안에 inline
- **분리 (`DPadNode.swift`)**: 학습 노트 §3 의존성 방향 깔끔. Phase 5 스킬 버튼 패턴 재사용.
- **inline (GameScene 안 함수)**: 새 파일 0건. pbxproj 멤버십 함정 회피.
- 추천: **분리**. 1-1 pbxproj 함정은 어차피 PlayerNode 신설로 한 번 겪을 거고, 두 파일을 한 번에 등록하면 비용이 거의 같음. 클래스 분리의 학습 가치가 더 큼.

---

## 8. SPEC에 들어갈 핵심 제약 (Planner에게 전달)

- **변경 유형**: 게임플레이 (드디어 사용자 입력이 게임을 바꾼다)
- **게임 경험 의도**:
  > "D-Pad를 누르고 있는 동안 김간호(민트색 박스)가 그 방향으로 움직인다. 카메라는 김간호를 따라가고, D-Pad는 우하단 고정. 손을 떼면 멈춘다. 즉, 게임이 처음으로 게임답게 반응한다."
- **Sprint 범위 계약**:
  - **IN**: `Nodes/PlayerNode.swift` 신규 + `Nodes/DPadNode.swift` 신규 + `GameScene.swift` 수정 + `Config/GameConfig.swift` 상수 추가 + `project.pbxproj` 멤버십 4종 등록 (4 파일 + pbxproj 1개)
  - **OUT**: 맵 경계 충돌, 카메라 클램핑, `SKPhysicsBody`, 픽셀 아트 텍스처, 햅틱, 사운드, 스킬 버튼, 음표/적/HUD/타이머, 8방향 동시 입력
- **준수 룰**:
  - `!` 강제 언래핑 0건 (`fatalError`는 `init?(coder:)`에서만 허용)
  - `Timer` 0건, `print()` 0건, `as!` 0건, `fileprivate` 0건
  - `MARK: -` 섹션 사용
  - `update()` 안 `addChild()` 호출 0건
  - PlayerNode 이동은 dt 보간만 (SKAction 금지)
  - DPadNode → PlayerNode 직접 참조 금지 (GameScene 경유)
  - `private(set)` / `final` / `private` 적극 사용
  - 매직 넘버 0건 (전부 GameConfig)
- **회귀 보존 (1-2 합격 자산 + 1-1 자산)**:
  - GameConfig 1-2 추가 5상수 그대로
  - 1-1 자산 변경 0건
  - cameraNode follow + worldNode 구조 그대로

---

## 9. 회고 (작업 후 채움) 📝

### 9-1. 막혔던 것
**하네스 자체에선 없었음.** 1-1에서 한 번 겪은 `PBXFileSystemSynchronizedRootGroup` 함정이 두 번째 등장이라 매끄럽게 통과 — prefix `A1C0F1`을 그대로 따라 일련번호만 `0005`/`0006`/`0007`로 늘렸고, `.bak` 백업 + `plutil -lint` + 빌드 검증 3단계 모두 1차 통과.

> **인사이트**: 1-1에서 *완전히* 정리해두지 않고 SELF_CHECK §알려진 제약에 메모만 남겼던 게 두 번째 작업 시간을 크게 절약. "다음에 또 만날 함정"을 미리 메모하는 습관이 성과로 연결됨.

#### ⚠️ 9-1-bis. 시뮬레이터 실행 시점에 발견된 버그 (핫픽스)
**증상**: iPhone 17 시뮬레이터에서 D-Pad가 화면 아래로 잘림 — ▲ 버튼만 가장자리에 살짝 보이고 나머지 3개는 안 보임.

**원인 분석 (수치)**:
- iPhone 17 가로 viewport ≈ 852×393pt
- GameScene size = 1024×768pt (`scaleMode = .aspectFill`)
- `.aspectFill`은 비율 유지하며 화면을 *완전히 덮는* 모드. 비율 차이로 가로는 ±512 다 보이지만 세로는 **±236까지만** 보임 (393/0.832/2 = 236)
- D-Pad 우하단 위치 `(+422, -294)`에서 **세로 -294는 -236 밖** → 화면 아래로 잘려 나감

**수정**: 한 줄 변경 — `scaleMode`를 `.aspectFill` → `.resizeFill`로.
- `.resizeFill`: scene size가 view bounds에 자동 매칭 → 모든 cameraNode 자식 좌표가 실제 화면 픽셀과 일치
- worldNode 자식(PlayerNode/corner 마커)은 맵 절대 좌표라 영향 없음
- 모든 디바이스에서 동일하게 동작 (보너스: iPhone 16/17 Pro Max에서도 깨끗)

**왜 SPEC 단계에서 못 잡았나**:
- SPEC §주의사항 "좌표계 두 개 동시 사용"은 좌표계 *혼동* 가능성만 적었지, **`scaleMode`가 viewport 가시 영역을 잘라낼 수 있다**는 사실은 누락. Planner도 Generator도 `scene.size`를 viewport와 동일시해서 (+(size.width/2 - margin), -(size.height/2 - margin))이 화면 안에 들어올 거라 가정.
- 단순 빌드 검증으로는 발견 불가 — 시뮬레이터 시각 검증에서만 드러남.

**다음 Phase 적용 메모**:
- HUD(Phase 2) 라벨 위치 산출도 viewport 기준이어야 함. `.resizeFill`로 바꿨으니 같은 패턴(`size.width/2 - margin`) 그대로 쓰면 됨.
- 카메라 클램핑(Phase 1-4)에서 viewport half-size 계산 시 `view.bounds` 또는 `size`(`.resizeFill` 후엔 동일) 사용 가능.

**교훈**: SpriteKit `scaleMode`의 4가지 모드 중 cameraNode 자식 UI는 거의 항상 `.resizeFill`이 정답. `.aspectFill`은 *고정 해상도 게임*(레트로 픽셀 게임 등)에 적합한데, 이 프로젝트는 화면 풀스크린 + UI 오버레이 모델이라 부적합.

### 9-2. Spring과 다르네 싶었던 것
1. **SKSpriteNode 상속 = 도메인 + 행동 캡슐화**: PlayerNode가 `SKSpriteNode`를 상속하고 `update(deltaTime:)`이라는 자기 갱신 메서드를 들고 다닌다. Spring의 anemic domain model(Order는 데이터만, OrderService가 동작)과 달리, 게임은 rich domain model(Order가 자기 totalPrice를 계산)에 가까움.
2. **`final class` 강제 의의**: Java는 `final class`가 흔치 않은데, Swift는 클래스 기본이 상속 가능이라 명시적으로 `final` 선언이 권장됨. 가상 디스패치 비용 제거 + 상속 의도 표명. PlayerNode/DPadNode 둘 다 `final`.
3. **`required init?(coder:)` + `fatalError` 패턴**: SKSpriteNode/SKNode 상속 시 NSCoding 호환을 위해 강제로 따라오는 보일러플레이트. `fatalError`는 강제 언래핑(`!`)과 다른 카테고리 — "이 코드는 도달 불가" 의도 표명. 룰북에서 면제 처리.
4. **`private(set) var` 한 줄 캡슐화**: Java는 `private field` + `public getter`로 두 줄 + 메서드 정의. Swift는 한 줄로 같은 의미 표현. DPadNode의 `currentDirection`이 정석.
5. **좌표계 두 개 동시 사용**: PlayerNode는 worldNode 자식 → 월드 절대 좌표 (320, 200) = 맵 중앙. DPadNode는 cameraNode 자식 → 화면 상대 좌표 (+422, -294) = 우하단. 같은 좌표(320, 200)가 다른 의미를 가짐. Spring의 JPA Entity vs DTO 두 컨텍스트 분리와 비슷.
6. **`isUserInteractionEnabled` 기본값 차이**: SKScene은 true, SKNode/SKSpriteNode는 false. DPadNode가 SKNode 상속이라 명시적 활성화 필요 — 가장 흔한 D-Pad 안 눌리는 버그 원인.
7. **DPadNode의 의존성 0건 원칙**: DPadNode는 PlayerNode를 모르고 GameScene을 모름. "지금 어느 방향 누르고 있나"만 외부에 노출. GameScene이 매 프레임 `player.currentDirection = dpad.currentDirection` 한 줄로 위임. Spring의 `OrderController` → `OrderService` → `Order` 단방향 의존 패턴과 동일. 양방향 참조나 콜백/델리게이트가 없는 게 핵심.
8. **import 최소화**: PlayerNode/DPadNode 모두 `import SpriteKit`만. UIKit/Foundation은 transitively. GameConfig는 같은 모듈이라 import 불필요. Java처럼 `import` 줄이 길지 않음.

### 9-3. 다음 작업으로 이월된 결정
1. **카메라 클램핑** (Phase 1-4 핵심 작업): 현재 PlayerNode가 맵 바깥(예: x < 0 또는 x > 640)으로 자유롭게 나갈 수 있고, 카메라도 따라가 검은 배경이 화면에 보임. `cameraNode.position`을 맵 안쪽으로 clamp + PlayerNode.position도 맵 경계 안으로 clamp.
2. **DPadNode deadzone 미적용**: `|dx| >= |dy|` 단순 판정이라 손가락이 정확히 (0,0)에 있어도 좌우로 인식. 정밀 입력 필요해지면 `if abs(x) < deadzone && abs(y) < deadzone { .zero }` 추가.
3. **8방향 동시 입력**: 4방향 단일로 충분한지 플레이 후 평가.
4. **햅틱 피드백** (Phase 4): D-Pad 누를 때 `UIImpactFeedbackGenerator.impactOccurred()` 한 줄 추가하면 즉각적으로 손맛 향상. 폴리싱 단계에 넣음.
5. **D-Pad 위치 사용자 조절**: 왼손잡이를 위해 D-Pad를 좌하단으로 옮기는 옵션 — 후속 Phase에서 설정 화면(Phase 3)과 함께.
6. **PlayerNode 픽셀 아트 텍스처** (Phase 4): 현재 16×20 민트 박스. 픽셀 아트 + 4방향 idle/step1/step2 애니메이션은 Phase 4 일괄 작업.
7. **Systems/InputSystem 분리 가능성**: components.md는 InputSystem 별도 분리를 권고하지만 1-3은 DPadNode 자체가 이미 입력 처리를 포함하므로 분리 미적용. 추후 키보드 입력 / 게임패드 추가 시 InputSystem이 D-Pad와 게임패드를 합산하는 구조로 분리 검토.

### 9-4. 평가 점수 (QA_REPORT.md 기준)
- Swift 패턴 (35%): **10 / 10** — 강제 언래핑·Timer·SKAction·고정값 이동 모두 0건. `final` / `private(set)` / MARK 모범
- 게임 로직 / 의도 충실도 (30%): **10 / 10** — SPEC §기능 1~7 코드 골격 1바이트 일치. dt 보간·입력 위임·상태 가드·카메라 follow 정석
- 성능 / 메모리 안전성 (20%): **10 / 10** — `update()` 안 노드 생성 0건, `weak` 캡처 N/A (클로저 미사용), 빌드 클린
- 기능 완성도 / 빌드 (15%): **9 / 10** — `BUILD SUCCEEDED`, SwiftFileList 등록 OK. P2 권고 1건(GameConfig L52 폐기 안내 주석은 코드 노이즈)
- **가중평균: 9.6 / 10 — 합격**

### 9-5. 사용자가 직접 확인할 것 ✅
시뮬레이터(`⌘R`)에서 10가지 (시각 검증 §6-2 9항목 + (i-2) 라벨 제거):
- (a) 화면 중앙에 작은 민트 박스(16×20pt) — PlayerNode (1-2 임시 박스보다 살짝 작음)
- (b) 우하단에 4방향 D-Pad (반투명 알파 0.3, ganhoPaper 4 버튼 십자 배치)
- (c) D-Pad 영역에서 마우스 드래그(시뮬)로 ▲/▼/◀/▶ 누른 상태 유지 가능
- (d) 누르고 있는 동안 PlayerNode가 해당 방향으로 이동
- (e) 손 떼면 PlayerNode 즉시 정지
- (f) 카메라가 PlayerNode를 따라가서 박스는 늘 화면 중앙
- (g) corner 마커 4개(분홍)가 PlayerNode 이동에 따라 화면 안팎으로 흐름
- (h) D-Pad는 PlayerNode가 아무리 멀리 가도 화면 우하단 고정
- (i) 가로 모드 강제 (Phase 0)
- (i-2) "GanhoMusic" 라벨 사라짐 (사용자 결정 ②)

> **추가 관찰 포인트**: PlayerNode가 맵 바깥(0~640, 0~400 범위 밖)으로 나가면 검은 배경이 보임 — 이게 Phase 1-4에서 카메라 클램핑이 필요한 이유. 1-3에서는 의도된 동작.

---

## 10. 다 읽었다면 다음은?

```
[1] §7 결정 사항 4건 사용자 OK
[2] rm -f SPEC.md SELF_CHECK.md QA_REPORT.md
[3] Planner    → SPEC.md      (위 §8을 입력으로)
[4] Generator  → 4 파일 + pbxproj + SELF_CHECK.md
[5] Evaluator  → QA_REPORT.md
[6] 합격 시 §9 회고 채우고 → 1-4(맵 경계 + 카메라 클램핑)으로
   불합격 시 Generator 재호출 (최대 3회)
```
