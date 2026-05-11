# 25 · Phase 4-2 · 석조무사 — "닿았다!"를 *느낄 수 있게* 만들기 👋

> **이번 작업 한 줄**: 4-1에서 *지나갈 수 있는 그림자*였던 석조무사를 *닿으면 알아채는 노드*로 바꾼다. 시각은 그대로, 게임 효과도 그대로 — **"접촉을 들을 귀"만 다는 sprint**. 다음 sprint(4-3)의 이스터에그가 들어올 자리를 *콜백 빈 칸*으로 미리 깔아둔다.

---

## 1. 왜?

4-1에서 석조무사가 사각형 동선을 따라 무한 순찰을 시작했다. 그런데 *플레이어가 그 위로 걸어가도* 아무 일이 일어나지 않는다. 왜? — 4-1 SPEC OoS에 **"PhysicsBody 부착 금지"**가 명시돼 있었다.

석조무사를 닿으면 반응하는 NPC로 만들려면 두 가지가 필요하다:
1. **귀** — "닿았다"를 SpriteKit이 알려주게 하는 장치 (= `SKPhysicsBody` + `contactTestBitMask`)
2. **메모리에 적힌 호출 번호** — 누구한테 알려야 하는지 (= `PhysicsCategory.stoneGuard` 비트)

이 sprint는 *귀와 번호만 단다*. 무엇을 할지(=이스터에그)는 4-3으로 미룬다.

> Spring으로 치면: "REST 컨트롤러 메서드만 정의하고 서비스는 다음 PR로". `@PostMapping("/airforce")`는 등록되지만 내부는 `// TODO: implement`. 라우팅까지 갈 길 닦아두고, 비즈니스는 다음 사이클.

---

## 2. Spring 비유 ⭐

| SpriteKit | Spring | 한 줄 설명 |
|---|---|---|
| `SKPhysicsBody` 부착 | `@RequestMapping` 어노테이션 | "이 노드 / 메서드는 이벤트를 받을 자격이 있다" |
| `categoryBitMask = .stoneGuard` | URL path (`/stoneguard`) | "내 정체는 이거다" |
| `contactTestBitMask = .player` | request filter | "이 종류 요청만 알려줘" |
| `collisionBitMask = 0` | (없음) | "물리적으론 막지 않음 — 그냥 알림만" |
| `ContactRouter.didBegin` | `DispatcherServlet` | 들어온 충돌을 정체별 분기 |
| `onStoneGuardContact` 콜백 | `@Service` 메서드 reference | 분기 후 호출할 비즈니스 로직 |
| GameScene의 빈 stub 콜백 | `// TODO: implement` 메서드 본문 | 다음 sprint에서 채울 자리 |

**핵심**: 본 sprint는 *라우팅·분기까지의 골격*만. 비즈니스 본체는 다음 sprint.

> Spring 출신이 가장 익숙한 단계 — 컨트롤러·서비스·매퍼 시그니처만 먼저 그려두고 본체는 나중에 채우는 흔한 작업.

---

## 3. 새로 배운 것 (Swift/SpriteKit) ⭐

### 3-1. **PhysicsBody의 3가지 비트마스크**

이 셋의 차이를 헷갈리면 게임이 안 굴러간다.

| 비트마스크 | 한 줄 의미 | 비유 |
|---|---|---|
| `categoryBitMask` | "내 정체는 X" | 명찰 |
| `collisionBitMask` | "물리적으로 부딪힐 상대 = X, Y" | 벽으로 막을 상대 |
| `contactTestBitMask` | "닿으면 알려줄 상대 = X" | "닿으면 내 폰으로 문자 보내" |

석조무사의 답:
- `categoryBitMask = .stoneGuard` (나는 석조무사다)
- `collisionBitMask = 0` (아무도 막지 않는다 — *통과 가능*하게)
- `contactTestBitMask = .player` (player가 닿으면 알려줘)

> **왜 collision = 0?**
> 4-3 이스터에그는 *플레이어가 석조무사를 통과*해야 발동되는 시나리오. 막아버리면 플레이어가 부딪혀서 튕겨나가 — 의도와 다름.

### 3-2. **`PhysicsCategory`에 새 비트 추가하는 법**

```swift
struct PhysicsCategory {
    static let none:       UInt32 = 0
    static let player:     UInt32 = 0b0001       // 1
    static let note:       UInt32 = 0b0010       // 2
    static let enemy:      UInt32 = 0b0100       // 4
    static let wall:       UInt32 = 0b1000       // 8
    static let projectile: UInt32 = 0b10000      // 16
    static let stoneGuard: UInt32 = 0b100000     // 32  ← Phase 4-2 신설
}
```

**규칙**: 반드시 **2의 거듭제곱**(1, 2, 4, 8, 16, 32, 64, ...). 왜? — OR 연산으로 "여러 비트 동시 검사"를 하려면 자리가 겹치지 않아야 한다.

> Java로 치면 `EnumSet`의 비트 인코딩과 동치. `0b100000`은 *6번째 자리만 1* — 다른 카테고리와 절대 겹치지 않음.

### 3-3. **`isDynamic` — 정적 vs 동적 PhysicsBody**

| 값 | 의미 | 누가 위치를 정함? |
|---|---|---|
| `true` (동적) | velocity 기반 자유 이동 | SpriteKit 물리 엔진(velocity → position) |
| `false` (정적) | 위치 변경은 외부가 직접 함 | 코드(SKAction.move 등) |

석조무사는 `SKAction.move(to:duration:)`로 *위치를 직접 갱신*한다 → **`isDynamic = false`가 자연**. velocity 같은 건 안 쓰니까.

> 비유: "동적"은 떠다니는 풍선(바람대로), "정적"은 손에 들고 옮기는 카드(내가 직접). 석조무사는 정해진 궤도를 *손으로 옮기는* 카드에 가까움.

### 3-4. **`collisionBitMask = 0`인데 어떻게 contact만 받나?**

SpriteKit은 충돌을 두 단계로 본다:
1. **collision** (물리 응답) — 부딪혀서 *튕겨나갈지 / 막을지*
2. **contact** (알림) — *닿았다는 사실*만 알려줄지

둘은 **독립적**이다. 그래서:
- `collisionBitMask = 0` → 튕기지도 막지도 않음 (= 통과 가능)
- `contactTestBitMask = .player` → 닿으면 `didBegin`은 호출됨

이 조합 = **"통과는 자유지만, 통과 사실은 보고됨"**. 4-3 이스터에그의 정확한 무대.

> Spring으로 치면: 미들웨어를 *지나가게는 두지만* 요청 정보는 로그로 남기는 것. 차단 ≠ 관찰.

### 3-5. **`ContactRouter` 콜백 패턴의 확장**

2-11에서 도입한 패턴이 그대로 늘어난다:

```swift
// ContactRouter.swift
var onStoneGuardContact: () -> Void = {}  // ← 새 콜백

func didBegin(_ contact: SKPhysicsContact) {
    let categories = ...
    if categories & PhysicsCategory.enemy != 0 { onEnemyHit(); return }
    if categories & PhysicsCategory.projectile != 0 { ...; return }
    if categories & PhysicsCategory.stoneGuard != 0 { onStoneGuardContact(); return }  // ← 새 분기
    if categories & PhysicsCategory.note != 0 { ... }
}
```

이 패턴의 *진짜 가치*는 **GameScene이 ContactRouter 내부를 모름**:
- ContactRouter는 분기만
- GameScene은 *콜백 본체*만
- 둘이 *인터페이스(콜백 변수)*로만 만남 → 한쪽 수정해도 다른 쪽 영향 없음

> Spring의 `@EventListener` 패턴과 같음. 이벤트 발행자(ContactRouter)와 구독자(GameScene)가 이벤트 이름으로만 만남.

### 3-6. **빈 stub 콜백의 의미**

```swift
// GameScene.swift — configureContactRouter()
contactRouter.onStoneGuardContact = { [weak self] in
    // Phase 4-2 — stub. 4-3에서 이스터에그 트리거 본체가 들어옴.
}
```

이건 **무위 코드가 아니라 *계약*이다**:
- ContactRouter는 *반드시 누군가 콜백을 등록*했다고 가정 — 미등록 = 크래시 위험
- 본 sprint는 *분기까지의 골격*이 동작함을 검증할 책임
- 다음 sprint는 *본체 채우기*만 — *시그니처 변경 없음*

> Spring으로 치면 `@Service` 메서드 body를 `throw UnsupportedOperationException();`로 두는 게 아니라 **빈 본문**으로 두는 것. 호출은 정상이고, *결과만 0*.

---

## 4. 무엇을 만드나?

### 새 파일
**없음** — 이번엔 추가 노드/시스템 없음.

### 고치는 파일 (4개 + pbxproj 변경 0)
| 파일 | 변경 |
|---|---|
| `Config/PhysicsCategory.swift` | `stoneGuard: UInt32 = 0b100000` 1줄 추가 |
| `Nodes/StoneGuardNode.swift` | init에 PhysicsBody 부착 블록 추가 (EnemyNode 패턴 답습, collision=0) |
| `Systems/ContactRouter.swift` | `onStoneGuardContact` 콜백 변수 1개 + didBegin 분기 3줄 |
| `GameScene.swift` | `configureContactRouter()`에 stub 콜백 등록 3줄 (TODO 주석 포함) |

### Xcode pbxproj
- **변경 없음** — 새 파일 0건.

### 한 그림으로

```
[변경 전 — Phase 4-1]
  Player ────→ StoneGuard 통과 ────→ (아무 일도 없음)
                physicsBody=nil

[변경 후 — Phase 4-2]
  Player ────→ StoneGuard 통과 ────→ SKPhysicsBody 감지
                physicsBody=있음                    ↓
                collision=0(막지 않음)      contactTest=.player
                                                    ↓
                                          ContactRouter.didBegin
                                                    ↓
                                          onStoneGuardContact()
                                                    ↓
                                          GameScene stub 콜백 — 본체 비어있음
                                                    (= 4-3에서 채움)
```

---

## 5. 직접 확인할 것

⌘R 후:

| # | 시나리오 | 봐야 할 것 |
|---|---|---|
| (a) | 게임 시작 | 4-1과 동일 — 석조무사 박스가 사각 동선 시계방향 순회 |
| (b) | 플레이어가 석조무사 위로 걸어감 | **그대로 통과** (시각상 차이 0) |
| (c) | 통과 시 점수·콤보·HUD | 변화 0 (이번 sprint 의도) |
| (d) | 통과 시 콘솔 출력 | (콘솔 로그 명시 안 함 — Generator 판단) |
| (e) | enemy/projectile/note 접촉 | 4-1과 100% 동일 (회귀 0) |
| (f) | 한 판 전체 플레이 → 게임오버 | 4-1과 100% 동일 (회귀 0) |
| (g) | 결과 화면 → 다시 플레이 | 4-1과 100% 동일 (회귀 0) |

> **핵심**: 사용자 입장에서 **시각·게임플레이 변화 0**. 변화는 *코드 내부의 감지 능력*만. 4-3에서 이 감지가 *비로소 효과로 발화*한다.

---

## 6. 사용자 결정 (이미 합의)

| 결정 | 선택 | 왜 |
|---|---|---|
| 본 sprint 범위 | PhysicsBody + 비트 + ContactRouter 분기 + stub 콜백 | "감지까지만, 효과는 다음 sprint" 분리 |
| `collisionBitMask` | **0** (아무도 막지 않음) | 4-3 이스터에그는 통과형 — 막으면 시나리오 깨짐 |
| `contactTestBitMask` | **.player** | 본 sprint는 player와 닿는 경우만 검사 |
| `isDynamic` | Generator 판단 (Planner SPEC에서 명시) | SKAction.move 기반이라 false 자연스러움 |
| stub 콜백 본체 | 빈 `{}` 또는 TODO 주석 | 4-3 시그니처 변경 없이 본체만 추가 |
| OoS — 다른 노드 변경 | **금지** | 회귀 위험. Player/Enemy/Note/Projectile 한 줄도 안 건드림 |
| OoS — 이스터에그 효과 | **금지** | 다음 sprint(4-3) |

---

## 7. 회고

### 7-1. 막혔던 것

**없음.** 한 사이클(QA 1회)에 **만점 합격(10.0/10)**. P0/P1/P2 0건.

본 sprint의 의도가 *분리 그 자체*였기에 변경이 의도적으로 작고(+25 / -1줄) 명확했다 — Generator/Evaluator 모두 1회 통과.

### 7-2. 새로 배운 것

1. **`isDynamic = false` + `collisionBitMask = 0` 조합** — "SKAction.move로 위치 직접 갱신 + 아무도 막지 않으면서 알림만 받기"의 정확한 조합. velocity 기반 EnemyNode(`isDynamic = true`)와 명확히 갈라지는 지점.
2. **양방향 통과 = 한쪽만 collision=0이면 충분** — Player/Enemy/Projectile의 `collisionBitMask`에 `.stoneGuard`가 *원래 없으므로* 자동으로 양방향 통과. 다른 노드 한 줄도 안 건드림.
3. **`isDynamic = false`도 contact는 받는다** — "두 body 중 *최소 한 쪽이라도 dynamic*"이면 SpriteKit이 `didBegin`을 호출. Player가 dynamic이라 보장.
4. **stub 콜백 = *시그니처 확정 sprint*** — 빈 클로저 `{ }` + TODO 주석만으로 4-3의 *호출 측 변경 0*을 미리 확보. Spring의 "@Service 메서드 시그니처만 먼저" 패턴과 1:1.
5. **`[weak self]` 캡처는 *self를 쓸 때*만** — 본 sprint stub은 self 미사용이라 `[weak self]` 생략. 미사용 캡처가 *경고*로 잡힐 수 있어 OoS "경고 0건" 위반 위험. 4-3에서 self를 쓰게 되면 그때 캡처 도입 = *클로저 캡처만 추가*, 외부 호출자/등록자 시그니처는 그대로.
6. **ContactRouter 분기 순서 = 우선순위** — `enemy → stoneGuard → projectile → note` 순. enemy가 stoneGuard 앞에 있어야 동시 접촉 시 게임오버 누락이 안 생긴다.
7. **새 PhysicsCategory 비트 = 2의 거듭제곱 + 다음 자리** — projectile(`0b10000` = 16) 다음은 `0b100000` = 32. OR 조합이 깨지지 않게.
8. **헤더 주석 정책** — Phase 4-1처럼 새 phase 라인을 *append* 만(기존 라인 변경 0). 파일별 변경 이력이 헤더에 그대로 누적되어 git 없이도 추적 가능.

> Spring으로 치면: `@RequestMapping` 라우팅·`@EventListener` 구독 정의는 **메서드 본체 없이도 운영 가능한 최소 단위** — 본 sprint는 그 골격까지만, 본체는 다음 PR.

### 7-3. 다음으로 미룬 것

- **4-3 (AIRFORCE 이스터에그)**: stub 콜백 본체 채우기 — 오버레이 + 비행기 + 폭탄 + 수간호사 5초 공포 도주. *호출 측(ContactRouter, PhysicsBody) 변경 0*이 핵심.
- **4-4 (박병장/이교주)**: 추가 NPC. 4-1 패트롤 패턴 또는 4-2 통과형 트리거 패턴 중 선택.
- **`protocol Enemy` 추출**: NPC 종류가 늘어나면 공통 인터페이스 도입.

### 7-4. 평가 점수

- **가중평균: 10.0 / 10 — 만점 합격** 🎉
- 항목별: Swift 패턴 10 / 게임 로직 10 / 성능·안정성 10 / 기능 완성도 10
- P0 0건, P1 0건, P2 0건
- 빌드: BUILD SUCCEEDED, 경고 0건
- diff: +25 / -1 (Swift 4 파일)

### 7-5. 핵심 가치 — *그릇만 먼저*

| 보존된 것 | 변경 0건 |
|---|---|
| `GameScene+Setup.swift` (setupStoneGuard 포함) | ✅ |
| `GameConfig.swift` (stoneGuard 4상수 포함) | ✅ |
| Player/Enemy/Note/Projectile/HUD/DPad | ✅ |
| TitleScene/ResultScene | ✅ |
| Repository / Stats / ScoreSystem / SpawnSystem | ✅ |
| ContactRouter 기존 분기 4개(enemy/projectile-player/projectile-wall/note) | ✅ |
| pbxproj | ✅ |
| `update()` 게임 루프 | ✅ |
| `endGame()` 본문 | ✅ |
| ColorTokens | ✅ |

**추가된 것**:
- PhysicsCategory.stoneGuard 비트 1줄
- StoneGuardNode init의 PhysicsBody 블록(~13줄)
- ContactRouter 콜백 변수 1개 + didBegin 분기 3줄
- GameScene 헤더 1줄 + configureContactRouter stub 3줄

이 *외과 수술적 변경*이 가능했던 이유 = **호출 측은 *콜백 시그니처*로만 의존**. 4-3에서 본체 채울 때도 *콜백 시그니처는 그대로* → 호출 측 변경 0 보장.

---

## 8. 다음 작업

```
[1] 시뮬레이터에서 §5 (a)~(g) 확인 (특히 통과 시 회귀 0 검증)
[2] 다음 sprint: Phase 4-3 (AIRFORCE 이스터에그 — stub 콜백 본체 채우기)
```

> **이번 sprint 본질**: 효과를 *덧붙이는* 게 아니라 *그릇을 미리 만드는* sprint. 그릇이 비어있으면 게임 변화는 0이지만, 4-3에서 효과가 *그릇 안에 그대로* 들어간다. *분리해서 작게* 만드는 훈련.
