# 04 · Phase 1-4 · 월드 경계 + 카메라 클램핑

> **이번 작업의 한 줄**: PlayerNode가 맵 바깥(검은 영역)으로 못 나가게 막고, 카메라도 맵 가장자리에서 멈추게 한다 — Phase 1의 마지막 매듭.
> 비유: 2D 게임에서 "벽이 있다"를 처음으로 가르치는 단계. Spring으로 치면 도메인 객체에 *유효성 제약(@Min/@Max)*을 다는 일.

---

## 1. 한눈 요약

```
Phase 1-3 (지금)                           Phase 1-4 (이번 작업)
┌──────────────────────┐                  ┌──────────────────────┐
│■■■■■ 검은영역 ■■■■■■│                  │┃─── 맵 끝 ───┃   │
│■  ┌─ map ─┐  ■■■■■  │                  │┃ ┌─ map ─┐ ┃       │
│■  │  □    │  ■■■■■  │       ──→        │┃ │  ▣ □ ▣ │ ┃ ← player가
│■  │       │  ■■■■■  │                  │┃ │       │ ┃   벽에 막힘
│■  └───────┘  ■■■■■  │                  │┃ └───────┘ ┃   카메라도 정지
│  ┐ player가  ■■■■■  │                  │┃           ┃       │
│  └ 자유낙하  [▲]    │                  │           [▲]      │
│  카메라도 따라감     │                  │  카메라가 양 끝에  │
└──────────────────────┘                  └──────────────────────┘
```

**핵심 변화 두 가지**:
1. **PlayerNode 클램프** — 위치를 맵 안쪽으로 강제. 맵 바깥으로 나가려 해도 가장자리에서 멈춤.
2. **카메라 클램프** — 카메라가 player를 따라가다가 맵 끝에 도달하면 더 이상 안 따라감. 그 순간부터 player는 화면 중앙이 아닌 *가장자리* 쪽으로 움직이는 것처럼 보임 (**플레이 감각의 결정적 변화**).

---

## 2. 무엇을, 왜?

### 무엇을 만드나
| 만드는 것 | 한 줄 설명 | 비유 |
|---|---|---|
| `PlayerNode.update(deltaTime:)` 클램프 한 블록 | dt 이동 후 position을 맵 경계 안으로 강제 | `@Max` validation |
| `GameScene.update(_:)` 카메라 클램프 한 블록 | `cameraNode.position = player.position`을 viewport 가시 범위 안으로 강제 | View 레이어의 안전 경계 |

### 왜 지금?
1. **1-3에서 게임이 "사용자 입력에 반응"하기 시작했지만**, 입력으로 player가 맵 밖 검은 영역까지 자유롭게 나간다. 이건 게임이 아니라 *공허*. 경계가 있어야 "공간"이 정의됨.
2. **카메라 클램핑은 "맵 끝"을 시각적으로 알려주는 핵심 신호**. 카메라가 멈추면서 player가 화면 중앙을 벗어나기 시작 = 사용자가 "벽에 가까워졌네" 직감으로 인식.
3. **Phase 2(음표/적/HUD)에 들어가기 전 Phase 1의 종결 매듭**. 1-1(Config) → 1-2(World+Camera) → 1-3(Player+Input) → **1-4(Bounds)**까지가 이동 시스템 한 묶음. Phase 2부터 위에 음표 수집·점수·타이머가 얹힘.

### 무엇을 하지 않나
| 안 하는 것 | 미루는 곳 | 이유 |
|---|---|---|
| `SKPhysicsBody` 부착 / 물리 충돌 | Phase 2 | 음표 수집/적 충돌과 함께 도입. 1-4는 단순 좌표 클램프로 충분 |
| 맵 중앙 기둥(easy 맵 §6) | Phase 2 또는 별도 맵 SPEC | 외곽 경계만 1-4 |
| hard 맵 (모서리 방 4개 + 내부 기둥) | Phase 2 이후 | 1-4는 외곽 경계만 |
| 카메라 lerp 보간 (부드러운 follow) | 필요 시 1-4 이후 | 직접 클램프만으로 게임 감각 검증 우선 |
| 벽 충돌 시 햅틱/사운드 피드백 | Phase 4 | 폴리싱 단계 |
| 벽 충돌 시 색 변경 / shake | Phase 4 또는 안 함 | 단순 클램프로 충분 |
| corner 마커 정리 | Phase 2(맵 타일 도입 시) | 1-4까지는 시각 검증 도구로 유지 |

---

## 3. Spring 비유 🌱

### 3-1. PlayerNode 클램프 = 도메인 자체 validation
```swift
// PlayerNode.update(deltaTime:) 안
position.x += currentDirection.dx * speed * dt
position.y += currentDirection.dy * speed * dt

// ↓ 이동 후 자기 자신 위치를 유효 범위로 강제
let halfW = size.width / 2
let halfH = size.height / 2
position.x = max(halfW, min(GameConfig.mapWidth  - halfW, position.x))
position.y = max(halfH, min(GameConfig.mapHeight - halfH, position.y))
```

Spring으로 치면:
```java
public class Order {
    private int quantity;
    public void increase(int delta) {
        this.quantity += delta;
        // 도메인 스스로 유효 범위로 강제
        this.quantity = Math.max(0, Math.min(MAX_QUANTITY, this.quantity));
    }
}
```

도메인이 *자기 상태의 유효성*을 책임진다. 외부(GameScene)가 "야 너 위치 깎아"라고 명령하지 않음. 이게 응집도(cohesion). 결합도(coupling)는 GameConfig 하나만 읽음 — 이미 있는 의존성이라 추가 비용 0.

### 3-2. 카메라 클램프 = View 레이어 안전 경계
```swift
// GameScene.update(_:) 안
cameraNode.position = player.position   // 1-2 follow 그대로
// ↓ 화면 가장자리 안전 경계 강제
cameraNode.position.x = clampedCameraX(for: player.position.x)
cameraNode.position.y = clampedCameraY(for: player.position.y)
```

Spring으로 치면 — `Order` 도메인이 가진 ±1000 같은 값을 **응답 DTO로 변환할 때** 표시 가능 범위(예: 화면에 보일 자릿수 ±999)로 한 번 더 깎는 것. 도메인은 이미 깨끗하지만 *보여주는 측면*에서 또 다른 제약이 있음.

여기선 player.position이 이미 맵 안인데도, **viewport보다 맵이 작으면** 또는 player가 맵 가장자리에 있을 때 카메라가 따라가면 검은 영역이 화면에 들어옴 → 카메라를 따로 클램프해야 함.

---

## 4. Swift / SpriteKit 학습 포인트 📘

### 4-1. `max(min(...))` = 클램프 관용구
```swift
let clamped = max(lower, min(upper, value))
//   value가 lower보다 작으면 lower로
//   value가 upper보다 크면 upper로
//   그 사이면 value 그대로
```

수학적으로 `clamp(value, lower, upper)`. Swift 표준 라이브러리는 `clamp(_:to:)`가 *없어서* `max(min(...))`를 합성. (Swift 5.9에 `clamped(to:)`가 있긴 하지만 ClosedRange 한정.)

### 4-2. SKSpriteNode의 `size`는 노드 자체 크기
```swift
class PlayerNode: SKSpriteNode { ... }

// PlayerNode 안에서:
self.size.width   // 16 (super.init(size:)로 설정한 값)
self.size.height  // 20

// 절반 = 노드 중심에서 가장자리까지의 거리
let halfW = size.width / 2   // 8
let halfH = size.height / 2  // 10
```

노드 position은 *노드 중심*을 가리킴 (anchorPoint 기본값 0.5, 0.5). 노드 가장자리가 맵 가장자리에 닿으려면 **center가 (halfW, halfH) ~ (mapWidth - halfW, mapHeight - halfH) 범위**여야 함. 이 산수가 클램프 식의 근간.

### 4-3. 카메라 클램프의 핵심: viewport > map vs viewport < map
실제 iPhone 17 가로:
- viewport ≈ 852 × 393 (Phase 1-3 핫픽스 후 `.resizeFill`로 scene size = view size)
- 맵: 640 × 400

**가로**: viewport(852) > map(640) → 맵 전체가 화면에 들어감 + 양옆 검은 영역. 카메라를 *맵 중앙*(320)에 고정해야 깔끔.
**세로**: viewport(393) < map(400) → 맵이 살짝 더 큼. 일반 클램프 식으로 OK.

분기 식:
```swift
let halfW = size.width / 2
if GameConfig.mapWidth >= size.width {
    // viewport가 더 좁음 → 일반 클램프
    cameraNode.position.x = max(halfW, min(GameConfig.mapWidth - halfW, player.position.x))
} else {
    // viewport가 더 넓음 → 맵 중앙 고정
    cameraNode.position.x = GameConfig.mapWidth / 2
}
```

조건 분기를 빼먹으면 iPhone 17 가로에서 `min(640 - 426, ...) = min(214, ...)` ≤ `max(426, ...)` → max가 항상 이김 → 카메라가 화면 좌측에 박힘. 흔한 함정.

### 4-4. 도메인 vs 씬 — 책임 분리
- **PlayerNode**: 자기 위치가 맵 안에 있는지를 *책임*. 맵 정보(`GameConfig.mapWidth/Height`) + 자기 size로 자기 클램프.
- **GameScene**: viewport 정보(`size`)를 *알고 있음*. 카메라가 viewport에서 잘리지 않도록 클램프.

PlayerNode가 viewport를 알면 안 됨 — 그건 화면(View)의 책임. 분리하지 않으면 Phase 5에서 캐릭터별 PlayerNode 다양화할 때 모든 파생 클래스가 viewport 의존이 박혀버림.

### 4-5. 맵 dimension < viewport 분기는 *일시적*인가?
이번 게임 맵은 GDD에 640×400으로 고정 명시. iPhone 17 가로(852×393)에서 가로는 맵 < viewport, 세로는 맵 > viewport. **현재 디바이스 한정 임시 분기 같지만 사실 영구 분기**:
- 작은 디바이스(iPhone SE 4.7" 가로) — viewport ≈ 667×375 → 가로 맵 > viewport, 세로 맵 > viewport 
- 큰 디바이스(iPad mini 가로) — viewport ≈ 1024×768 → 가로 맵 < viewport, 세로 맵 < viewport (양쪽 다 검은 띠)
- iPhone 17 Pro Max — 더 큼

분기는 *디바이스마다 동작이 달라지는* 자연스러운 결과. 영구 코드.

---

## 5. 산출물 (예정)

### 새로 만드는 파일
**없음.** (변경이 PlayerNode/GameScene 함수 본문 수준 — 새 파일 가치 없음. pbxproj 안 건드림.)

### 수정하는 파일
| 파일 | 변경 |
|---|---|
| `Nodes/PlayerNode.swift` | `update(deltaTime:)` 끝에 자체 클램프 4줄 추가 |
| `GanhoMusic Shared/GameScene.swift` | `update(_:)` 끝의 `cameraNode.position = player.position`을 카메라 클램프 블록으로 교체 |

### 절대 손대지 않는 파일
- 1-3 신설된 `Nodes/DPadNode.swift` (입력 처리 — 클램프와 무관)
- `Config/GameConfig.swift` (`mapWidth`/`mapHeight` 이미 1-2에서 정의됨, 추가 상수 0개)
- 1-1/1-2/1-3 합격 자산 전부

### Xcode 멤버십
**필요 없음.** 새 .swift 파일 0건 → `project.pbxproj` 0바이트 변경.

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
- `!` 강제 언래핑 0건 (`fatalError` 면제)
- `Timer` / `print()` / `as!` / `fileprivate` / `SKPhysicsBody` / `physicsWorld` / `SKAction` 0건
- `update()` 안 `addChild()` 0건

### 6-2. 시각 검증 (시뮬레이터)
`⌘R` 후 사용자 직접 확인:
- (a) PlayerNode가 맵 좌측(x=0)으로 가려고 하면 **x=8(halfW)에서 멈춤** — 더 누르고 있어도 안 움직임
- (b) 우/위/아래도 동일하게 가장자리에서 멈춤 (`mapWidth - halfW`, `mapHeight - halfH`)
- (c) PlayerNode가 맵 가장자리 근처로 가면 **카메라가 더 이상 안 따라감** — 박스가 화면 중앙에서 가장자리로 미끄러져 보임
- (d) 카메라 정지 위치: 가로는 viewport > map이라 맵 중앙(320) 고정 → 박스가 가로 양 끝(8 또는 632)에 있어도 카메라는 320에 정지 → 박스가 화면 중앙에서 가로로 ±300 정도 떨어진 위치에 보임
- (e) 세로는 viewport(~393) < map(400)이라 일반 클램프 — 박스가 위/아래 끝에 가까워지면 카메라가 잠깐 더 따라가다가 정지
- (f) 검은 영역(맵 바깥) 사라짐 — 가로는 항상 맵 양옆 검은 띠가 viewport 채울 정도로 보이지만 박스는 그쪽으로 나가지 못함
- (g) D-Pad는 여전히 화면 우하단 고정 (1-3 동작 그대로)
- (h) corner 마커 4개도 그대로 (1-2 잔존)

### 6-3. 회귀 (1-3 합격 자산 + 핫픽스 보존)
- DPadNode 0바이트 변경
- GameConfig 0바이트 변경 (`mapWidth/Height` 이미 1-2 자산이라 추가 없음)
- 1-3 핫픽스 `scaleMode = .resizeFill` 그대로
- 1-3 노드 트리 구조 그대로 (PlayerNode/DPadNode/worldNode/cameraNode 4 인스턴스 그대로)
- `cameraNode.position = player.position` 한 줄은 *함수 본문 안에 카메라 클램프 추가*된 형태로 발전 — 의미는 보존

---

## 7. 사용자 결정 필요 사항 (학습 노트 단계)

### 결정 ① · PlayerNode 클램프 위치 — 자체 vs 외부
- **자체 (PlayerNode 안)**: 응집도 ↑. PlayerNode → GameConfig 의존만 추가 (이미 있음). 외부에서 매번 챙길 필요 없음.
- **외부 (GameScene 안)**: PlayerNode를 단순 도메인으로 유지. GameScene이 모든 정책 통제.
- 추천: **자체**. 도메인이 자기 유효성 책임 — Spring `Order.increase()` 패턴.

### 결정 ② · 카메라 클램프 — 맵이 viewport보다 작을 때 처리
- **맵 중앙 고정**: 맵이 viewport 가운데 정렬 → 좌우(또는 상하) 검은 띠 균등.
- **player 그대로 따라가기**: player 위치 그대로. 검은 띠가 한쪽으로 쏠림.
- 추천: **맵 중앙 고정**. 시각적으로 안정. iPhone 17 가로에서 가로축이 이 케이스.

### 결정 ③ · 카메라 lerp 보간
- **직접 추종 (1-3 그대로)**: 클램프만 1-4 본질. 부드러움은 별도 안건.
- **lerp 도입**: `cameraNode.position = lerp(camera.position, player.position, 0.1)` 같은 가중평균.
- 추천: **직접 추종**. 1-4 스코프 단순화. 사용자 체감으로 멀미 느껴지면 별도 SPEC.

### 결정 ④ · 벽 충돌 시 시각/햅틱 피드백
- **없음**: 단순 정지만.
- **시각/햅틱**: 진동, 색 변경, shake 등.
- 추천: **없음**. Phase 4 폴리싱과 함께. 1-4는 동작 정확성만.

---

## 8. SPEC에 들어갈 핵심 제약 (Planner에게 전달)

- **변경 유형**: 게임플레이 (입력 후 상태 검증)
- **게임 경험 의도**:
  > "PlayerNode가 맵 바깥으로 못 나간다. 맵 가장자리에 가까워지면 카메라가 멈추고 player가 화면 중앙을 벗어나기 시작한다. 즉, 게임이 처음으로 '공간'을 가진다."
- **Sprint 범위 계약**:
  - **IN**: PlayerNode `update(deltaTime:)` 안 자체 클램프 4줄 + GameScene `update(_:)` 안 카메라 클램프 블록 (분기 포함). 새 파일 0건. GameConfig 변경 0건.
  - **OUT**: SKPhysicsBody, 물리 충돌, 맵 내부 기둥/벽, hard 맵, lerp 보간, 햅틱, 시각 피드백, 8방향 동시 입력, 음표/적/HUD/타이머
- **준수 룰**:
  - `!` 0건 (`fatalError` 면제)
  - `Timer` / `print()` / `as!` / `fileprivate` / SKAction / SKPhysicsBody / physicsWorld 0건
  - `update()` 안 `addChild()` 0건
  - 매직 넘버 0건 — 클램프 식은 GameConfig.mapWidth/Height + self.size로만
  - PlayerNode 클램프는 PlayerNode 안에서만, 카메라 클램프는 GameScene 안에서만 (책임 분리)
- **회귀 보존 (1-3 합격 자산 + 핫픽스)**:
  - DPadNode 0바이트
  - GameConfig 0바이트
  - 1-3 핫픽스 `scaleMode = .resizeFill` 그대로
  - 노드 트리 4 인스턴스 그대로
  - 카메라 follow 핵심 한 줄(`cameraNode.position = player.position`)은 *함수 안에 클램프 블록과 함께* 보존

---

## 9. 회고 (작업 후 채움) 📝

### 9-1. 막혔던 것
**없었음.** Phase 1-4는 1-4 단위 중 가장 작았다 — PlayerNode 4줄 + GameScene 헬퍼 1개. 빌드 1차 통과, 회귀 보존 9개 파일 모두 mtime + size 0바이트, P0 위반 0. 1-3에서 핫픽스로 `scaleMode = .resizeFill`을 미리 잡아둔 덕에 viewport size 산출이 자연스러웠다 — 만약 1-3 핫픽스 없이 1-4를 진행했다면 카메라 클램프 식의 `size.width`가 1024로 동작해 화면 잘림이 더 심해졌을 것.

### 9-2. Spring과 다르네 싶었던 것
1. **`max(min(...))` 합성 = clamp 관용구**: Swift 5.9+에 `clamped(to:)`가 있긴 하지만 ClosedRange 한정. Java `Math.max(0, Math.min(MAX, x))` 그대로 옮겨와도 자연. 표준 라이브러리에 *clamp 함수가 없는* 게 의외였다.
2. **헬퍼 함수의 *순수 함수* 표명**: `clampedCameraPosition(forPlayerAt:) -> CGPoint`는 외부 상태를 안 건드리고 입력 → 출력만. Spring `Service` 메서드 중 stateless 한 것과 같음. 테스트 가능성이 그냥 높아짐 — Mock 없이 입력값 넣고 출력 비교만 하면 됨.
3. **`size`의 두 의미**: PlayerNode 안 `size`(자기 SKSpriteNode 크기) vs GameScene 안 `size`(SKScene viewport 크기). 같은 토큰이지만 인스턴스에 따라 다른 값. Spring 도메인에서 `User.name` vs `Repository.name` 같은 명명 충돌과 비슷한데, *프로퍼티 이름*에 컨텍스트가 없는 게 SpriteKit의 구식 API 잔재.
4. **viewport vs map 분기는 영구 코드**: "iPhone 17만 임시 처리"가 아니라, *모든 디바이스에서 디바이스마다 동작이 다르게* 결정되는 자연 분기. SE/iPhone 16/17 Pro Max/iPad 모두 다른 케이스를 탐. 한 번 짜놓으면 모든 디바이스 자동 호환.
5. **도메인 vs 씬 책임 분리의 의미**: PlayerNode는 viewport를 모름(맵 정보만 안다). GameScene은 viewport를 안다. 이 분리가 깨지면 Phase 5에서 캐릭터 5명 다양화할 때 모든 PlayerNode 파생 클래스가 viewport 의존이 박힘. **지금 한 줄 더 쓰는 게 미래의 5배 일을 막음**.
6. **`>=` 빼먹으면 카메라가 한쪽에 박힘**: `min(640 - 426, ...)` ≤ `max(426, ...)` → max가 항상 이김. 학습 노트 §4-3에서 미리 짚어둔 함정이 SPEC §주의사항에도 적혀 Generator가 정확히 회피.
7. **클램프 순서 (이동 → 검증)**: 검증 → 이동 순이면 한 프레임 늦어짐. 한 함수 안에서도 *명령형 순서*가 의미를 결정. Spring `@Transactional` 안 트랜잭션 경계에서 비슷한 사고.
8. **Phase 1-4의 작은 변경 = Phase 1의 큰 종결**: 코드는 4줄 + 헬퍼 1개지만 게임 감각이 결정적으로 바뀜 — "공간이 있다"가 처음으로 시각화됨. *변경량 ≠ 의미량*.

### 9-3. 다음 작업으로 이월된 결정 (Phase 2 진입 시)
1. **`SKPhysicsBody` 도입**: Phase 2에서 음표(노트) 수집/적과의 충돌 처리 위해 PlayerNode에 PhysicsBody 부착. 동시에 `physicsWorld.contactDelegate = self` + `SKPhysicsContactDelegate` 채택. 1-4 클램프 식은 그대로 두되, 충돌 처리는 별도 시스템.
2. **맵 타일 도입 (Phase 2 또는 별도 SPEC)**: GDD §6 easy 맵(외곽 벽 + 중앙 기둥) / hard 맵(모서리 방 4개 + 중앙). 1-4 corner 마커는 맵 타일 도입 시 정리.
3. **HUD 라벨 (Phase 2)**: 점수/타이머/콤보 라벨 — `cameraNode` 자식으로 추가. D-Pad 우하단 자리 정책과 충돌 없게 좌상/우상 영역 사용.
4. **음표 스폰 시스템 (Phase 2)**: `Systems/SpawnSystem.swift` 신규 — `Systems/` 폴더 첫 진입이라 1-1 패턴 `PBXFileSystemSynchronizedRootGroup` 멤버십 등록 재현 필요. 1-3에서 사용한 ID 일련번호 다음(`0008` 이후).
5. **카메라 lerp 보간 시점 검토**: 1-4까지 직접 추종 유지. 음표/적이 추가되면 player가 빠르게 가속/방향 전환할 가능성 — 그때 멀미 체감되면 lerp 도입.
6. **PlayerNode 픽셀 아트 텍스처 (Phase 4)**: 현재 16×20 민트 박스. 픽셀 아트 + 4방향 idle/step1/step2 애니메이션은 Phase 4 일괄 작업.
7. **벽 충돌 햅틱 (Phase 4)**: 1-4는 클램프만. 벽에 부딪힐 때 진동/사운드는 Phase 4 폴리싱.

### 9-4. 평가 점수 (QA_REPORT.md 기준)
- Swift 패턴 (35%): **10 / 10** — `final`/`private(set)`/`max(min)` 관용구/MARK/헬퍼 분리 모범
- 게임 로직 (30%): **10 / 10** — SPEC §기능 1~2 코드 골격 1바이트 일치, dt 이동 → 클램프 → 카메라 분기 정석
- 성능 (20%): **10 / 10** — `update()` 안 노드 생성 0, 헬퍼는 순수 함수, 빌드 클린
- 기능 완성도 (15%): **9 / 10** — `BUILD SUCCEEDED`, P0 위반 0. 시각 검증은 사용자 시뮬 실행으로만 최종 확정 가능 (0.25 보수 차감)
- **가중평균: 9.6 / 10 — 합격**

### 9-5. 사용자가 직접 확인할 것 ✅
시뮬레이터 `⌘R` 후 8가지:
- (a) PlayerNode가 맵 좌측(x→0)으로 갔을 때 **x = 8(halfW)에서 멈춤** — 더 누르고 있어도 안 움직임
- (b) 우/위/아래도 동일하게 가장자리에서 멈춤 (x=632, y=10, y=390)
- (c) 박스가 맵 가장자리 근처로 가면 **카메라가 더 이상 안 따라감** — 박스가 화면 중앙을 벗어나 가장자리로 미끄러져 보임 (Phase 1-4의 결정적 시각 증거)
- (d) 가로: viewport(852) > map(640)이라 **카메라가 항상 mapWidth/2=320에 고정**. 박스 가로 위치와 무관하게 카메라는 320. 박스가 가로 양 끝(8 또는 632)에 가도 화면 중앙에서 ±300쯤 떨어져 보임
- (e) 세로: viewport(393) < map(400)이라 일반 클램프. 박스가 세로 끝 가까워지면 카메라가 잠깐 더 따라가다 정지
- (f) **검은 영역 밖으로 박스가 나가지 못함** — 1-3에서 가능했던 우주 공간 이동이 사라짐
- (g) D-Pad는 우하단 고정 (1-3 동작 회귀)
- (h) corner 마커 4개 그대로 (1-2 잔존)

---

## 10. 다 읽었다면 다음은?

```
[1] §7 결정 사항 4건 사용자 OK
[2] rm -f SPEC.md SELF_CHECK.md QA_REPORT.md
[3] Planner   → SPEC.md     (위 §8을 입력으로)
[4] Generator → PlayerNode/GameScene 수정 + SELF_CHECK.md
[5] Evaluator → QA_REPORT.md
[6] 합격 시 §9 회고 채우고 → 🎉 Phase 1 종결, Phase 2 (음표 + 적 + HUD)로
   불합격 시 Generator 재호출 (최대 3회)
```

> Phase 1을 끝내면 "MVP의 절반"에 도달. Phase 2까지 가면 "플레이 가능한 게임".
