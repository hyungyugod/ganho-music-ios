# 26 · Phase 4-3 · AIRFORCE 이스터에그 — *비행기가 한 번 지나간다* ✈️

> **이번 작업 한 줄**: 4-2에서 만들어둔 *빈 그릇*(onStoneGuardContact stub)에 *드디어 무언가*를 담는다. 플레이어가 석조무사를 처음 통과하는 순간 비행기가 화면 위를 좌→우로 가로질러 *한 번* 지나간다. 게임 로직(점수/HUD/적/게임오버)은 *전혀* 건드리지 않는 *순수 시각 이스터에그*.

---

## 1. 왜?

게임 자전적 배경(간호 실습 중 작곡)을 농담스럽게 표현한 *AIRFORCE 이스터에그*는 GDD §7-6의 깜짝 연출 — "정해진 길만 걷는 무사를 슬쩍 통과하니 하늘 위로 비행기가 지나간다". 발견 시점이 1회뿐이어서 *플레이어가 우연히 마주칠 때* 더 임팩트 있다.

4-2에서 *감지 골격*까지 깔아두었기에 본 sprint는 **stub 본체만 채운다**:
- `onStoneGuardContact = {}` → `onStoneGuardContact = { 비행기 띄움 }`
- ContactRouter / PhysicsBody / PhysicsCategory / setupStoneGuard / GameConfig stoneGuard 상수 — 한 줄도 안 건드림.

> Spring으로 치면: 4-2에서 `@PostMapping("/airforce")` 핸들러 등록만 했고, 4-3에서 *서비스 메서드 본문*을 채운다. 컨트롤러 시그니처는 그대로.

---

## 2. Spring 비유 ⭐

| SpriteKit | Spring | 한 줄 설명 |
|---|---|---|
| `airforceTriggered: Bool` 플래그 | `AtomicBoolean` 1회 가드 | "이미 발동했으면 다시 안 함" |
| `AirplaneNode` (신규) | DTO + `@Service` | "한 번만 살아 움직이고 자동 소멸" |
| `crossScreen(width:y:)` 메서드 | `@Async public void run()` | "외부에서 호출되면 자기 일 끝낸 후 자가 종료" |
| `SKAction.removeFromParent()` | 메서드 끝 = 가비지 컬렉션 후보 | "끝났으면 사라져 — 누가 명시적으로 안 지워도 됨" |
| `cameraNode.addChild(plane)` | `@Component` 등록 | "씬 트리에 한 번만 부착" |

**핵심**: 본 sprint는 *호출 측 변경 0*. ContactRouter의 콜백 시그니처도, PhysicsBody 설정도, setup 메서드도 그대로. **트리거 본체 안에서만 새 노드가 생성·삭제**된다.

---

## 3. 새로 배운 것 (Swift/SpriteKit) ⭐

### 3-1. **1회 한정 이벤트 가드 — `Bool` 플래그 패턴**

```swift
private var airforceTriggered = false

private func triggerAirforceEasterEgg() {
    if airforceTriggered { return }
    airforceTriggered = true
    // ... 비행기 띄우기 ...
}
```

**왜 `Bool`?** 가장 단순. 게임 1판은 새 GameScene 인스턴스라 자동 리셋. 별도 reset 메서드 불필요.

> Spring 비유: `private final AtomicBoolean fired = new AtomicBoolean(false); if (fired.compareAndSet(false, true)) { ... }` 와 동치. Swift는 게임 루프가 *단일 스레드*라 `AtomicBoolean` 같은 동시성 가드 불필요.

### 3-2. **cameraNode 자식 vs worldNode 자식**

| 부착 위치 | 좌표계 (0,0) | 카메라 이동 시 |
|---|---|---|
| `worldNode.addChild` | 맵 좌표 (절대) | 카메라가 따라가면 같이 흘러감 |
| `cameraNode.addChild` | 화면 좌표 (중앙) | 카메라와 함께 이동 — *화면 고정* |

비행기는 *"화면 위에 떠 있다"*는 느낌이라 **cameraNode 자식**이 자연. HUD/D-Pad와 같은 트리.

> 비유: 워크 워크하는 player를 따라가는 카메라가 *드론 시점*이라면, 비행기는 *드론 위로 더 높이 떠서 같이 움직이는 또 다른 드론*. 화면 고정 좌표계가 맞음.

### 3-3. **`SKAction.move(to:duration:)` vs `move(by:duration:)`**

| 함수 | 의미 | 적합 |
|---|---|---|
| `move(to: point, duration:)` | 절대 좌표로 이동 | 시작점 알면 깔끔 |
| `move(by: vector, duration:)` | 상대 거리만큼 이동 | 시작점 모를 때 |

본 sprint는 *시작점·끝점 모두 GameScene이 계산*(scene.size 의존) → `move(to:)` 사용.

### 3-4. **SKAction.sequence([move, removeFromParent]) — 자가 소멸 노드**

```swift
let cross = SKAction.move(to: endPos, duration: 2.0)
let cleanup = SKAction.removeFromParent()
node.run(.sequence([cross, cleanup]))
```

이 sequence가 끝나면:
1. 노드 위치가 endPos에 도달
2. *자기 자신을 부모에서 제거*
3. ARC 해제 → 메모리에서 사라짐

**별도 GC/제거 코드 0**. 트리거 → 발동 → 자동 정리 = *fire-and-forget*.

> Spring 비유: `@Async`로 던진 후 결과를 안 받는 메서드. 호출자는 *호출 사실만* 안다. 노드는 자기 일을 끝내고 *조용히 사라짐*.

### 3-5. **scene.size 의존 노드의 SKAction 시작 시점**

StoneGuardNode는 init에서 SKAction 자동 시작 (waypoint가 *맵 절대 좌표 상수*라 가능).
AirplaneNode는 *scene.size 의존*(시작/끝이 화면 좌우 바깥) → init에서 SKAction 시작 불가.

해결 패턴 — 메서드 분리:
```swift
final class AirplaneNode: SKSpriteNode {
    init() { ... 색/크기/zPosition만 ... }
    
    /// 부모에 addChild 직후 호출. scene.size 의존이라 init에서 못 함.
    func crossScreen(sceneWidth: CGFloat, atY y: CGFloat) {
        // 시작/끝 위치 계산 + SKAction.run
    }
}
```

GameScene이 `addChild → crossScreen` 2단계로 호출.

> 이 패턴은 *프레임워크 콜백 의존*. JS의 `componentDidMount`와 비슷 — *언제 가능한지*가 외부 조건에 묶임.

### 3-6. **zPosition 50의 의미**

| zPosition | 누구 |
|---|---|
| 100 | HUD (화면 항상 위) |
| **50** | **AirplaneNode (이스터에그, 일시적)** |
| 5 | Player, Enemy, StoneGuard, Note, Projectile |
| 0 (기본) | 벽, 기둥, 배경 노드 |

비행기는 일반 노드(5)보다 위, HUD(100)보다 아래. 점수 라벨을 가리면 안 되니까. *공중에 떠 있는* 느낌과도 일치.

### 3-7. **stub 본체 → 실제 본체 변경 시 [weak self] 도입**

4-2 stub: `{ }` (self 미사용)
4-3 본체: `{ [weak self] in self?.triggerAirforceEasterEgg() }`

캡처를 새로 추가했지만 **콜백 시그니처 `() -> Void`는 그대로**. 호출 측(ContactRouter)은 한 줄도 안 건드림. 4-2에서 미리 *콜백 변수*로 분리해둔 덕에 가능.

> Spring 비유: 4-2에서 `@Service AirforceService = NoopAirforceService()` 등록만, 4-3에서 `RealAirforceService` 구현 추가 + 등록 교체 (호출 측 `controller.service.run()`은 그대로).

---

## 4. 무엇을 만드나?

### 새 파일 (1개)
| 파일 | 역할 |
|---|---|
| `Nodes/AirplaneNode.swift` | SKSpriteNode 상속. 색/크기/zPosition 부여 + `crossScreen(sceneWidth:atY:)` 메서드로 가로지르기 + 자가 소멸 |

### 고치는 파일 (3개 + pbxproj)
| 파일 | 변경 |
|---|---|
| `Config/GameConfig.swift` | `// MARK: - Airforce Easter Egg (Phase 4-3)` 섹션 + 4상수 (가로/세로/duration/상단 오프셋) |
| `GameScene.swift` | `airforceTriggered: Bool = false` 1줄 + `triggerAirforceEasterEgg()` 메서드 신설 + onStoneGuardContact stub 본체 교체 |
| `GameScene.swift` 헤더 MARK 1줄 추가 | 변경 이력 누적 |
| pbxproj | AirplaneNode.swift 4곳 등록 (PBXBuildFile / PBXFileReference / Nodes 그룹 / iOS Sources phase). 식별자 0018. |

> ❌ **건드리지 않는 파일** (회귀 위험 0):
> ContactRouter, PhysicsCategory, StoneGuardNode, GameScene+Setup, EnemyNode, PlayerNode, NoteNode, ProjectileNode, HUDNode, DPadNode, ColorTokens, TitleScene, ResultScene, Repository 전부.

### 한 그림으로

```
[Player가 StoneGuard 통과]
        ↓
ContactRouter.didBegin → stoneGuard 분기 → onStoneGuardContact()
        ↓
GameScene.triggerAirforceEasterEgg()
        ↓
  airforceTriggered 가드 (1회만)
        ↓
  let plane = AirplaneNode()
  cameraNode.addChild(plane)
  plane.crossScreen(sceneWidth: size.width, atY: 상단 좌표)
        ↓
  AirplaneNode 내부:
    1. 시작 위치 = (-halfW - planeW, y)  ← 화면 좌측 바깥
    2. 끝 위치   = (+halfW + planeW, y)  ← 화면 우측 바깥
    3. SKAction.sequence([.move(to: 끝, duration: 2.0), .removeFromParent()])
        ↓
  2초 후 비행기 자동 제거, 메모리 해제
        ↓
  airforceTriggered = true (재발동 안 함)
```

### 비행기 시각 사양 (잠정)
- 색: `.ganhoYellowF` (F 투사체와 동일 — *주의 환기* 색)
- 크기: 32×16 (가로로 긴 막대형)
- 속도: 1500pt(화면 + 여유)을 2.0초에 = 750pt/s
- y 위치: 화면 상단에서 60pt 아래

> 픽셀 아트 텍스처는 *Phase 6*. 본 sprint는 단색 박스.

---

## 5. 직접 확인할 것

⌘R 후:

| # | 시나리오 | 봐야 할 것 |
|---|---|---|
| (a) | 게임 시작, 석조무사 미접촉 | 비행기 0건 (4-2와 동일) |
| (b) | Player가 석조무사를 통과 | **화면 위쪽 좌→우로 노란 막대(비행기) 한 번 지나감 (~2초)** |
| (c) | 비행기 지나간 후 다시 석조무사 통과 | 비행기 재등장 0 (1회 한정) |
| (d) | 비행기 지나갈 때 점수·HUD | 변화 0 (시각만) |
| (e) | 비행기 지나갈 때 player·enemy·F | 그대로 (영향 0) |
| (f) | 비행기 지나갈 때 카메라 follow | 카메라가 player 따라가도 비행기는 *화면 고정* (cameraNode 자식) |
| (g) | 게임오버 (시간 만료 / enemy·F 피격) | 평소대로 ResultScene 전환. 비행기 잔존하면 ARC 해제로 함께 소멸 |
| (h) | 재시작 후 다시 발견 시도 | 새 GameScene → airforceTriggered = false → 다시 1회 발동 가능 |

> **핵심**: 비행기는 *비주얼만*. 게임의 균형이 흔들리지 않아야 — 4-2 의도 그대로.

---

## 6. 사용자 결정 (이미 합의)

| 결정 | 선택 | 왜 |
|---|---|---|
| 본 sprint 범위 | 비행기 가로지르기 1회 | 폭탄/도주/오버레이는 추후 sprint로 분리 (1 sub-feature 원칙) |
| 부착 위치 | **cameraNode 자식** | 화면 고정 좌표계 — 카메라 이동 시에도 자연스러움 |
| 색 | `.ganhoYellowF` | 기존 ColorTokens 재사용. 노란색이 *주의 환기* 시각 |
| 가로지르기 방향 | **좌→우** | 게임 진행 방향(좌하단 → 우하단 → ...)과 일치 |
| duration | 2.0초 | 너무 빠르면 못 보고, 너무 느리면 게임에 방해 |
| 1회 한정 | **YES** | "이스터에그" — 발견은 한 번만 |
| 재시작 시 리셋 | **자동** | 새 GameScene 인스턴스 → 플래그 자동 false |
| OoS — 폭탄·도주·오버레이 | **금지** | 다음 sprint |

---

## 7. 회고

### 7-1. 막혔던 것

**없음.** 한 사이클(QA 1회)에 **만점 합격(10.0/10)**. P0/P1/P2 0건.

4-2에서 *그릇*(`onStoneGuardContact` 콜백 + ContactRouter 분기 + PhysicsBody)을 미리 만들어둔 덕에 본 sprint는 *호출 측 변경 0* — 신규 노드 1개 + GameScene 12줄 + GameConfig 8줄 + pbxproj 4줄로 끝.

### 7-2. 새로 배운 것

1. **fire-and-forget 노드** — `SKAction.sequence([move, removeFromParent])`로 노드가 *자기 시작·자기 끝*. 호출자는 인스턴스 만들고 부착만 하면 됨. GC 신경 X.
2. **scene.size 의존 노드의 SKAction 시작 시점** — `init`에서 자동 시작 가능 여부는 *좌표 의존*에 달렸음. waypoint가 절대 좌표면 init OK(StoneGuardNode), scene.size 비례면 외부 호출 필요(AirplaneNode).
3. **cameraNode 자식 = 화면 고정 좌표계** — worldNode 자식이었으면 player 이동 시 비행기도 같이 흘러가 어색. HUD/DPad와 같은 트리.
4. **1회 한정 가드 Bool 플래그** — 게임 1판 = 새 GameScene 인스턴스라 자동 리셋. 별도 reset 메서드 *불필요*. Swift는 단일 스레드 게임 루프라 `AtomicBoolean` 같은 동시성 장치도 *불필요*.
5. **`[weak self]` 캡처는 *self를 쓸 때*만** — 4-2 stub은 self 미사용이라 캡처 생략, 4-3 본체에서 self 사용하므로 캡처 도입. 4-2에서 미리 캡처를 두지 않은 것이 *경고 0건*에 기여.
6. **zPosition 계층 설계** — 100(HUD) > 50(이스터에그 일시 노드) > 5(일반 게임 노드) > 0(벽·기둥). 처음으로 *중간 계층*(50)을 도입. HUD를 가리지 않으면서 일반 노드 위에 보임.
7. **GameScene 메서드 캡슐화 — `private`** — `triggerAirforceEasterEgg`와 `airforceTriggered` 모두 private. extension 파일(GameScene+Setup.swift)에서도 접근 *불필요*. 가장 좁은 범위로 시작.
8. **stub → 본체 교체 시 코드 변경 통계** — ContactRouter 0줄, PhysicsCategory 0줄, StoneGuardNode 0줄, GameScene+Setup 0줄. 변경 측은 *오직 GameScene 본체*. 4-2의 분리가 4-3의 *외과 수술적 변경*을 가능케 함.

> Spring 비유: 4-2에서 `@Service AirforceService = NoopAirforceService()` 등록만, 4-3에서 `RealAirforceService` 구현 추가. 컨트롤러·매퍼는 한 줄도 변경 없이 비즈니스만 진화.

### 7-3. 다음으로 미룬 것

- **이스터에그 확장**: 폭탄(BombNode) / 수간호사 5초 도주 모드 / 오버레이 / 사운드 효과 — 별도 sprint(4-3+/4-5)로.
- **4-4 (박병장 / 이교주)**: 추가 NPC. 패트롤 또는 통과형 트리거 중 선택.
- **AirplaneNode 픽셀 아트 텍스처**: Phase 6 (assets).
- **`protocol Enemy`**: NPC 종류가 늘어나면 공통점을 protocol로.

### 7-4. 평가 점수

- **가중평균: 10.0 / 10 — 만점 합격** 🎉
- 항목별: Swift 패턴 10 / 게임 로직 10 / 성능·안정성 10 / 기능 완성도 10
- P0 0건, P1 0건, P2 0건
- 빌드: BUILD SUCCEEDED, 경고 0건
- diff: 신규 1파일 + 수정 3파일 (Swift 2 + pbxproj 1)

### 7-5. 핵심 가치 — *수술실*

| 보존된 것 | 변경 0건 |
|---|---|
| `ContactRouter.swift` (콜백 시그니처·분기) | ✅ |
| `PhysicsCategory.swift` (.airplane 같은 새 비트 0) | ✅ |
| `StoneGuardNode.swift` (4-2 그대로) | ✅ |
| `GameScene+Setup.swift` (setupStoneGuard 그대로) | ✅ |
| 기존 GameConfig 상수 (stoneGuard 4상수 포함) | ✅ |
| Player/Enemy/Note/Projectile/HUD/DPad | ✅ |
| TitleScene/ResultScene | ✅ |
| `update()` / `endGame()` 게임 루프 | ✅ |
| ColorTokens (.ganhoYellowF 재사용) | ✅ |
| macOS / tvOS Sources phase | ✅ |

**추가된 것**:
- AirplaneNode.swift 신규 (49줄)
- GameConfig.swift Airforce 섹션 (8줄)
- GameScene.swift 헤더 1줄 + 프로퍼티 3줄 + Easter Egg 메서드 8줄 + stub 본체 교체 (3줄)
- pbxproj 4곳 (4줄)

이 *외과 수술적 변경*이 가능했던 이유 = **4-2에서 콜백 시그니처를 미리 확정**해뒀기 때문. *분리해서 작게* 만드는 훈련의 진가는 *다음 sprint의 작업량*에서 드러난다.

---

## 8. 다음 작업

```
[1] 시뮬레이터에서 §5 (a)~(h) 확인 (특히 (b): "와 비행기다!" 한 번)
[2] 다음 sprint: Phase 4-4 (박병장 또는 이교주 등 추가 NPC)
   또는 Phase 4-3+: 이스터에그 확장 (폭탄 / 수간호사 도주)
```

> **이번 sprint 본질**: *호출 측 변경 0*으로 새 효과 추가. 4-2의 *그릇 분리*가 본 sprint의 *작업량 최소화*를 정확히 실현. 한 번의 분리가 다음 sprint를 *수술실*로 만든다.
