# 07 · Phase 2-2 · 중앙 기둥 + SKPhysicsBody 첫 도입

> **이번 작업의 한 줄**: 1-1에서 만들어두고 한 번도 안 쓴 *물리 시스템*(`SKPhysicsBody`)을 처음으로 켜고, 맵 한가운데 *기둥*을 세워 박스가 부딪힘.
> 비유: 지금까지 박스가 *유령*처럼 통과하던 구조 → **드디어 몸이 생긴다**.

---

## 1. 한눈 요약

```
지금 (Phase 2-1)                          이번 작업 (Phase 2-2)
┌────────────────────────┐                ┌────────────────────────┐
│ ━━━━━━━━━━━━━━━━━━     │                │ ━━━━━━━━━━━━━━━━━━     │
│ ┃                  ┃    │                │ ┃                  ┃    │
│ ┃    [□]            ┃    │      ──→       │ ┃    ┌──┐          ┃    │
│ ┃   (자유 이동)     ┃    │                │ ┃   │██│ ←중앙기둥 ┃    │
│ ┃                  ┃    │                │ ┃   └──┘            ┃    │
│ ━━━━━━━━━━━━━━━━━━     │                │ ┃ [□] 박스가 부딪힘 ┃    │
│                         │                │ ━━━━━━━━━━━━━━━━━━     │
│ 박스가 벽과 기둥 통과   │                │ 진짜 충돌 — 못 지나감  │
└────────────────────────┘                └────────────────────────┘
        유령 박스                                  몸 있는 박스
```

**핵심 변화 두 가지**:
1. **물리 엔진 ON** — `SKPhysicsBody` 도입. 1-1에서 만들어둔 `PhysicsCategory` 비트마스크가 *드디어* 활성화.
2. **중앙 기둥** — GDD §6 easy 맵 명세("외곽 벽 + 중앙 기둥 1개, 2×4타일"). 박스가 통과 못 함.

**부수 변화**: PlayerNode의 이동 방식이 *position 직접 변경* → *velocity(속도) 기반*으로 진화. PhysicsBody의 정석 사용. 1-4의 *자체 클램프*는 PhysicsBody가 외곽 벽도 막아주므로 제거.

---

## 2. 무엇을, 왜?

### 무엇을 만드나
| 변경 | 한 줄 설명 |
|---|---|
| `physicsWorld.gravity = .zero` | 씬 전체 중력 제거. 박스가 떨어지지 않게 |
| PlayerNode `physicsBody` 부착 | dynamic body, velocity 기반 이동, 회전 안 함 |
| PlayerNode update 본문 재작성 | `position +=` 제거 → `physicsBody.velocity =` 한 줄로 |
| PlayerNode 자체 클램프 4줄 제거 | PhysicsBody가 외곽 벽 막아주므로 중복 제거 |
| 외곽 벽 4개 PhysicsBody 부착 | static body, 박스가 못 지나감 |
| 중앙 기둥 신설 + PhysicsBody | 2×4 tile = 40×80pt, 맵 정중앙 |

### 왜 지금?
1. **GDD §6 easy 맵 명세 완성**. "외곽 벽 + 중앙 기둥 1개"가 easy 맵의 정의. 2-1에서 외곽 벽 시각만 했는데, 진짜 *공간*이 되려면 부딪힘이 필요.
2. **PhysicsCategory가 1-1부터 잠자고 있었음**. 1-1에서 `static let player: UInt32 = 0b0001` 등 5개 비트마스크 정의 — 이번에 *드디어* 활성화. 1-1 자산이 *진짜로* 쓰이는 순간.
3. **Phase 2-3(음표 수집)·2-6(적 충돌) 전 기반 작업**. 음표/적도 PhysicsBody로 충돌 감지. 그 인프라를 2-2에서 깔아야 후속 sub-phase가 자연스러움.
4. **velocity 기반 이동의 정석 학습**. SpriteKit 액션 게임은 거의 다 velocity 기반. 1-3~1-4의 position 직접 변경은 *학습용 단순 패턴*이었고 이제 정석으로 전환할 때.

### 무엇을 하지 않나
| 안 하는 것 | 미루는 곳 |
|---|---|
| 음표(NoteNode) | Phase 2-3 |
| 음표 스폰 시스템 | Phase 2-3 |
| 충돌 *알림*(`contactTestBitMask`) | Phase 2-3 (음표 수집과 함께) |
| `SKPhysicsContactDelegate` 채택 | Phase 2-3 |
| HUD / 점수 / 타이머 | Phase 2-5 |
| 적 NPC | Phase 2-6 |
| hard 맵 (모서리 방 4개) | Phase 4 |
| 햅틱 / 사운드 | Phase 4 |
| 카메라 lerp | 필요 시 후속 |

---

## 3. Spring 비유 🌱

### 3-1. PhysicsBody = "도메인에 *물리 법칙* 부착"
지금까지:
- 1-3: PlayerNode는 *데이터*만 (위치 + 방향)
- 1-4: 자체 *유효성 검증*(클램프) 추가

이번 작업:
- 2-2: PlayerNode에 *물리 인터랙션*(질량, 충돌 응답) 부착

Spring으로 치면 `Order` 도메인에 `@Validated` 추가하는 것 → 더 나아가 `@Constraint` 같은 *생명 주기 인터셉터*까지 부착하는 단계. 도메인이 *수동적 데이터*에서 *능동적 객체*로 진화.

### 3-2. velocity 기반 이동 = "*상태* 통제 → *의도* 통제"
| | 1-3/1-4 (지금) | 2-2 (이번) |
|---|---|---|
| 코드 | `position += dt * speed * dir` | `velocity = speed * dir` |
| 의미 | "매 프레임 *위치*를 이만큼 옮겨라" | "이 *속도*로 가고 싶다" |
| 책임 | 코드가 위치 통제 | 물리 엔진이 위치 통제 |
| 충돌 | 코드가 직접 처리 (자체 클램프) | 엔진이 자동 처리 |

Spring으로 치면 *명령형 (imperative)* → *선언형 (declarative)* 전환. JPA `entityManager.persist()` 직접 호출 vs `@Transactional`로 *트랜잭션 의도*만 표명.

### 3-3. PhysicsCategory = "*권한 비트마스크*"
1-1에서 정의:
```swift
struct PhysicsCategory {
    static let player: UInt32 = 0b0001
    static let note:   UInt32 = 0b0010
    static let enemy:  UInt32 = 0b0100
    static let wall:   UInt32 = 0b1000
}
```

이번에 *처음으로* 사용:
```swift
player.physicsBody?.categoryBitMask    = PhysicsCategory.player
player.physicsBody?.collisionBitMask   = PhysicsCategory.wall    // 벽이 막음
player.physicsBody?.contactTestBitMask = 0                       // 알림은 Phase 2-3
```

Spring Security `GrantedAuthority`의 비트 버전 — 각 노드가 *어떤 종류*인지(`category`) + *어떤 종류와 충돌할지*(`collision`) 비트로 표현.

---

## 4. Swift / SpriteKit 학습 포인트 📘

### 4-1. `SKPhysicsBody` 3종류
```swift
// (a) rectangle — 직사각형 영역
SKPhysicsBody(rectangleOf: CGSize(width: 16, height: 20))

// (b) circle — 원형 영역
SKPhysicsBody(circleOfRadius: 10)

// (c) edge — 외곽선만 (속이 비어있음, 벽/경계용)
SKPhysicsBody(edgeLoopFrom: CGRect(...))
```

이번에 쓸 건 **(a) rectangle** — player(16×20), 벽(가변), 중앙 기둥(40×80) 모두 직사각형. circle/edge는 미사용.

### 4-2. `isDynamic` — 누가 움직이나
```swift
playerBody.isDynamic = true   // 물리 엔진이 위치 통제 (충돌·중력 등 영향 받음)
wallBody.isDynamic   = false  // 코드가 위치 통제, 다른 dynamic body가 부딪히면 막음
```

| 종류 | isDynamic | 비유 |
|---|---|---|
| **player** | true | 자유 의지 가진 사람 |
| **wall/기둥** | false | 단단한 벽 (안 움직임, 부딪힘 받기만 함) |

### 4-3. `categoryBitMask` vs `collisionBitMask` vs `contactTestBitMask`
```swift
playerBody.categoryBitMask    = PhysicsCategory.player    // "나는 player다"
playerBody.collisionBitMask   = PhysicsCategory.wall      // "벽이랑 부딪히면 *막혀라*"
playerBody.contactTestBitMask = PhysicsCategory.note      // "음표랑 닿으면 *알려달라*" (Phase 2-3)
```

| 비트마스크 | 의미 | 예시 |
|---|---|---|
| `category` | "나의 정체" | "나는 player" |
| `collision` | "물리적 막힘" | "벽 만나면 멈춤" |
| `contactTest` | "충돌 알림" | "음표 닿으면 *알림* 받음 (수집 처리용)" |

**이번 작업**: collision만 (벽 ↔ player). contactTest는 Phase 2-3.

### 4-4. velocity 기반 이동
```swift
// 1-3/1-4 (지금)
position.x += currentDirection.dx * speed * dt   // 위치를 직접 갱신

// 2-2 (이번)
physicsBody?.velocity = CGVector(
    dx: currentDirection.dx * speed,
    dy: currentDirection.dy * speed
)
// → 물리 엔진이 매 프레임 자동으로 position += velocity * dt 적용
```

dt 곱하기가 사라짐 — 엔진이 알아서. 충돌 시 엔진이 자동으로 velocity = 0 처리. 코드가 깔끔해짐.

> **주의**: dt가 사라진 게 아니라 *코드에서 사라진* 것. 엔진 내부에서 dt 사용. 결과는 1-3 패턴과 같은 60pt/s.

### 4-5. `physicsWorld.gravity = .zero`
SpriteKit 기본 gravity = `(0, -9.8)` (지구 중력). 그대로 두면 박스가 *바닥으로 떨어짐*. 탑다운 게임은 중력 0:
```swift
// GameScene.didMove(to:) 안 한 줄
physicsWorld.gravity = .zero
```

여러 노드의 `affectedByGravity = false`보다 *씬 한 줄*이 깔끔.

### 4-6. `allowsRotation` — 박스가 데굴데굴 안 굴러가게
```swift
playerBody.allowsRotation = false
```

기본은 true → 부딪히면 박스가 회전. 캐릭터 게임에선 보통 false (똑바로 서있음). 안 끄면 벽에 부딪힐 때마다 캐릭터가 빙글빙글.

### 4-7. `friction` / `restitution` / `linearDamping`
```swift
playerBody.friction       = 0   // 마찰 (벽에 비비면 느려짐) — 0이면 미끄러움
playerBody.restitution    = 0   // 탄성 (벽에 부딪힐 때 튕김) — 0이면 안 튕김
playerBody.linearDamping  = 0   // 공기 저항 (안 누르면 천천히 멈춤) — 0이면 즉시 정지 안 함
```

GanhoMusic은 *D-Pad 떼면 즉시 정지* 원함 → `currentDirection = .zero`이면 `velocity = .zero`로 직접 설정. damping에 의존 X. 셋 다 0이 안전.

### 4-8. 1-4 자체 클램프 *제거*의 의미
1-4에서:
```swift
position.x = max(halfW, min(GameConfig.mapWidth  - halfW, position.x))
position.y = max(halfH, min(GameConfig.mapHeight - halfH, position.y))
```

이 4줄이 외곽 벽 PhysicsBody 도입으로 *중복*. PhysicsBody가 외곽 벽도 막음. 중복 제거 = 단일 책임.

> **단**: PhysicsBody가 빠른 이동 시 *터널링*(한 프레임에 벽을 통과) 가능성. player 60pt/s + dt 0.0167s ≈ 1pt/프레임 ≪ 벽 두께 20pt. 터널링 가능성 매우 낮음.

### 4-9. PlayerNode `init` 안에서 PhysicsBody 부착
```swift
init() {
    let size = CGSize(width: GameConfig.playerWidth, height: GameConfig.playerHeight)
    super.init(texture: nil, color: .ganhoMint, size: size)
    name = "player"

    // PhysicsBody 부착 (Phase 2-2)
    let body = SKPhysicsBody(rectangleOf: size)
    body.isDynamic           = true
    body.allowsRotation      = false
    body.friction            = 0
    body.restitution         = 0
    body.linearDamping       = 0
    body.categoryBitMask     = PhysicsCategory.player
    body.collisionBitMask    = PhysicsCategory.wall
    body.contactTestBitMask  = 0   // Phase 2-3에서 .note 추가
    physicsBody = body
}
```

`init` 안에서 PhysicsBody 셋업 = 노드 *생성과 함께* 물리 속성 결정. Spring `@PostConstruct` 비슷한 위치.

---

## 5. 산출물 (예정)

### 새로 만드는 파일
**없음.** (중앙 기둥은 GameScene 안 함수로, PhysicsBody는 PlayerNode `init` 안에서.)

### 수정하는 파일
| 파일 | 변경 |
|---|---|
| `Nodes/PlayerNode.swift` | (1) `init` 안 PhysicsBody 부착 블록 추가, (2) `update(deltaTime:)` 본문 재작성 (position 직접 변경 → velocity 설정), (3) 1-4 자체 클램프 4줄 제거 |
| `GanhoMusic Shared/GameScene.swift` | (1) `didMove(to:)` 끝에 `physicsWorld.gravity = .zero` 한 줄 추가, (2) `addOuterWalls()` 안 4 벽 모두 PhysicsBody 부착, (3) `addCentralPillar()` 신설 + `setupWorld()`에서 호출 |

### 절대 손대지 않는 파일
- `Nodes/DPadNode.swift` (0바이트)
- `Config/GameConfig.swift` (PhysicsBody 산수에 기존 `playerWidth/Height`, `mapWidth/Height`, `tileSize` 재활용 — 새 상수 0건)
- `Config/GameState.swift`, `PhysicsCategory.swift`(*드디어 활성화* — 0바이트), `ColorTokens.swift` (0바이트)
- `iOS/AppDelegate.swift`, `SceneDelegate.swift`, `GameViewController.swift` (0바이트)
- `project.pbxproj` (0바이트)

### Xcode 멤버십
**필요 없음.**

---

## 6. 검증 방법 ✅

### 6-1. 정량 검증
```bash
xcodebuild ... build
```
- 빌드 에러 0, 경고 0
- `physicsBody` 등장 (PlayerNode init + 외곽 벽 + 중앙 기둥)
- `physicsWorld.gravity` 등장 1건
- `PhysicsCategory.player` / `.wall` 등장 ≥ 1건씩
- `position.x = max(halfW` 같은 1-4 자체 클램프 식 0건 (제거 검증)
- `position.x +=` 0건 (velocity 전환 검증) — `update(deltaTime:)` 내
- `Timer` / `print()` / `as!` / `fileprivate` / SKAction 0건

### 6-2. 시각 검증 (사용자 시뮬레이터)
`⌘R` 후:
- (a) 맵 중앙에 **2×4 tile 기둥** (40×80pt, `.ganhoPaper` 색) 보임
- (b) 박스가 기둥에 닿으면 **부딪혀 멈춤** — 통과 안 됨
- (c) 박스가 외곽 벽에도 진짜로 부딪힘 (1-4 자체 클램프와 시각 차이 거의 없지만 *물리 엔진이 막는* 감각)
- (d) D-Pad 떼면 박스 즉시 정지 (linearDamping = 0 + currentDirection = .zero)
- (e) 박스가 벽/기둥에 부딪혀도 **회전 안 함** (allowsRotation = false)
- (f) 박스가 벽/기둥에 부딪혀도 **튕기지 않음** (restitution = 0)
- (g) 카메라가 박스 정중앙 follow (1-5 그대로)
- (h) D-Pad 우하단 고정 (1-3 그대로)

### 6-3. 회귀 (1-5 + 2-1 합격 자산 + 핫픽스)
- DPadNode 0바이트
- GameConfig 0바이트
- Config/GameState/PhysicsCategory/ColorTokens 0바이트 (PhysicsCategory는 *내용*은 같지만 *드디어 import* 됨)
- iOS 3 파일 + project.pbxproj 0바이트
- 1-3 핫픽스 `scaleMode = .resizeFill` 그대로
- 1-5 카메라 drone follow `cameraNode.position = player.position` 그대로
- 2-1 외곽 벽 4개 시각 표현 그대로 (PhysicsBody 부착이 추가될 뿐 size/position/color 동일)

---

## 7. 사용자 결정 필요 사항

### 결정 ① · PlayerNode 이동 방식
| 옵션 | 코드 | 추천 |
|---|---|---|
| A. position 직접 (1-4 유지) | `position.x += dt * speed * dx` | PhysicsBody와 충돌 효과 어색 |
| **B. velocity 기반** ⭐ | `physicsBody?.velocity = CGVector(...)` | ⭐ — PhysicsBody 정석, 충돌 자동 |

**왜 B?** PhysicsBody 도입 = 물리 엔진에게 *위치 통제* 위임. position 직접 변경은 엔진과 충돌. velocity는 정석.

### 결정 ② · 1-4 자체 클램프 처리
| 옵션 | 결과 | 추천 |
|---|---|---|
| A. 유지 (안전망) | PhysicsBody + 자체 클램프 = 이중 안전 | 코드 중복 |
| **B. 제거** ⭐ | PhysicsBody가 외곽 벽 막음 | ⭐ — 단일 책임, 코드 깔끔 |

**왜 B?** 외곽 벽 PhysicsBody가 같은 일을 함. 60pt/s + dt 0.017 ≈ 1pt/프레임이라 터널링 가능성 매우 낮음.

### 결정 ③ · 외곽 벽 PhysicsBody 부착 여부
| 옵션 | 결과 | 추천 |
|---|---|---|
| A. 안 부착 | player 자체 클램프(1-4) 유지 필요. 시각만 | 결정 ②와 충돌 |
| **B. 부착** ⭐ | 정석 충돌. 1-4 자체 클램프 제거 가능 | ⭐ — 일관성 |

**왜 B?** 결정 ①·②와 한 묶음. PhysicsBody 도입 = 정석으로 가는 게 학습 가치 ↑.

### 결정 ④ · 중앙 기둥 크기/위치
| 옵션 | 값 | 추천 |
|---|---|---|
| **A. GDD §6 명세** ⭐ | 2×4 tile = 40×80pt, 맵 정중앙 (480, 240) | ⭐ — 명세 따름 |
| B. 다른 값 | 사용자 디자인 | GDD 갱신 필요 |

**왜 A?** GDD §6에 명시. 변경하려면 GDD 동기화 부담.

### 결정 ⑤ · 중앙 기둥 색
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. `.ganhoPaper`** ⭐ | 외곽 벽과 같은 톤 — *벽이라는 정체성* 통일 | ⭐ — 1-1 자산 보존 |
| B. 다른 색 | ColorTokens 변경 또는 새 토큰 | 회귀 |

**왜 A?** "벽 = `.ganhoPaper`" 일관성. 후속 hard 맵 추가 벽도 같은 톤 자연스러움.

---

## 8. SPEC에 들어갈 핵심 제약 (Planner에게 전달)

- **변경 유형**: 게임플레이 + 비주얼 (물리 엔진 활성화 + 중앙 기둥 시각화)
- **게임 경험 의도**:
  > "박스가 *유령*이 아니라 *몸을 가진* 캐릭터로 진화한다. 중앙에 기둥이 생겨 박스가 통과 못 함. 벽도 진짜로 막힘. 1-1에서 만들어둔 PhysicsCategory가 처음으로 활성화된다."
- **Sprint 범위 계약**:
  - **IN**: PlayerNode `init` PhysicsBody 부착 + `update(deltaTime:)` velocity 전환 + 자체 클램프 제거. GameScene `didMove` gravity = .zero + `addOuterWalls` PhysicsBody 부착 + `addCentralPillar` 신설. 정확히 2 파일 수정.
  - **OUT**: NoteNode/SpawnSystem/EnemyNode/ProjectileNode/HUD/타이머/contactTestBitMask/SKPhysicsContactDelegate (Phase 2-3 이후). hard 맵 (Phase 4). 햅틱/사운드 (Phase 4).
- **준수 룰**:
  - `!` 0건 (`fatalError` 면제)
  - `Timer` / `print()` / `as!` / `fileprivate` / SKAction 0건
  - `update()` 안 `addChild()` 0건
  - 매직 넘버 0건 — 기둥 산수는 `GameConfig.tileSize` + 자명 산술(`2`/`4`/`/2`)
  - PlayerNode `update(deltaTime:)` 본문은 *velocity 설정 한 줄*이 핵심 (1-3/1-4 패턴 폐기)
  - PhysicsCategory.note / .enemy 도입 0건 (Phase 2-3 이후)
  - contactTestBitMask 모두 0 (Phase 2-3에서 .note 추가)
- **회귀 보존 (1-5 + 2-1 + 핫픽스)**:
  - DPadNode / GameConfig / Config 4파일 / iOS 3 파일 / project.pbxproj 0바이트
  - 1-3 핫픽스 `scaleMode = .resizeFill` 그대로
  - 1-5 카메라 drone follow 그대로
  - 2-1 외곽 벽 4개 size/position/color 그대로 (PhysicsBody 부착만 추가)

---

## 9. 회고 (작업 후 채움) 📝

### 9-1. 막혔던 것
**없었음.** SPEC 코드 골격이 명확해서 Generator가 1바이트 단위로 옮김. 1차 빌드 통과, P0 위반 0, 회귀 9파일 mtime + size 동결. SKPhysicsBody 첫 도입이라 변경량은 작지 않았는데(PhysicsBody 6건 부착) 함정 0개.

> **인사이트**: 학습 노트 §4(Swift/SpriteKit 학습 포인트)에서 PhysicsBody 속성 9개를 *모두* 짚어둔 게 SPEC에도 그대로 반영 → Generator가 빠뜨릴 게 없었음. 사용자에게 던지는 §4가 곧 SPEC 입력이 됨.

### 9-2. Spring과 다르네 싶었던 것
1. **PhysicsBody의 3 비트마스크 차이가 헷갈림**: `category`(나의 정체) / `collision`(막힘) / `contactTest`(알림) — Spring `@Authority`/`@Permission` 비유로 정리하니 명확. *이번 작업에선 collision만, contactTest는 Phase 2-3*로 단계 분리한 게 학습에 도움.
2. **velocity 기반 = 의도 표명, position 기반 = 직접 통제**: Spring `@Transactional` 선언형 vs `entityManager.persist()` 명령형 차이. 1-3/1-4의 명령형에서 2-2의 선언형으로 *언어 자체가 바뀌는* 느낌.
3. **`physicsWorld.gravity = .zero` 한 줄로 씬 전체 적용**: 노드별 `affectedByGravity = false` 안 해도 됨. Spring `@Configuration` 한 곳에서 모든 빈에 영향 주는 패턴과 비슷.
4. **PhysicsBody 모든 속성 *명시* 패턴**: 기본값 의존 안 하고 friction/restitution/linearDamping 모두 명시 = 향후 디버깅 시 "어디서 어떤 값?" 즉시 식별. Spring `application.yml`에 모든 키를 명시하는 보수적 스타일과 같음.
5. **`update(deltaTime:)` 매개변수 *미사용*인데 *시그니처 보존***: 외부 호출부(`player.update(deltaTime: dt)`) 깨지면 안 되므로 이름 그대로. Swift 컴파일러는 라벨 사용 시 미사용 경고 0 — Java로 치면 `@SuppressWarnings("unused")` 자리에 *암묵적* 처리.
6. **1-1 `PhysicsCategory`가 *드디어* 활성화**: 1-1부터 1-5까지 5단계 sleep 상태였던 자산. 미리 정의해둔 비트마스크가 *처음 import* 됨. 인프라를 먼저 깔고 나중에 활성화하는 패턴은 Spring `@ConfigurationProperties` 방식과 비슷.
7. **외곽 벽 PhysicsBody는 `WallSpec` 루프 *안*에서 부착**: 함수 4번 호출이 아니라 루프 1회. 코드 중복 0. 1-2/2-1의 루프 패턴이 더 깊어진 형태.
8. **PlayerNode `init` 안에서 PhysicsBody 부착**: `super.init` 후, 다른 속성(name, currentDirection)과 같은 위치. `@PostConstruct` 비슷한 의도 — 노드 *생성과 함께* 물리 속성 결정.

### 9-3. 다음 작업으로 이월된 결정 (Phase 2-3 진입 시)
1. **NoteNode 신설** (Nodes/NoteNode.swift): 음표 ♪ 노드, SKSpriteNode 상속, PhysicsBody 부착(rectangle 또는 circle, isDynamic=false 또는 true), categoryBitMask=.note, collisionBitMask=0 (player 통과 가능), contactTestBitMask=PhysicsCategory.player (수집 알림).
2. **PlayerNode `contactTestBitMask` 갱신**: 0 → `PhysicsCategory.note` (대칭 처리, 어느 쪽에 두든 동작하지만 *의미*는 player가 음표 닿음 받음).
3. **`SKPhysicsContactDelegate` 채택**: GameScene이 채택. `physicsWorld.contactDelegate = self`. `didBegin(_:)`에서 음표 수집 처리.
4. **음표 스폰 시스템**: `SKAction.repeatForever(sequence([run, wait]))` 패턴. 학습 노트 STYLE.md대로 새 작업 노트 작성.
5. **점수 카운트 변수**: GameScene에 `private var score: Int = 0` 추가. HUD 라벨은 Phase 2-5에서.
6. **음표 색**: `.ganhoPaper`는 벽 전용 → 음표는 `.ganhoMint`(player와 헷갈림) 또는 새 토큰. 결정 사항으로 던지기.
7. **`Systems/` 폴더 진입**: SpawnSystem.swift 신설 시 `PBXFileSystemSynchronizedRootGroup` 함정 (1-1/1-3 패턴) 재현. ID prefix `A1C0F1`, 다음 일련번호 `0008`부터.

### 9-4. 평가 점수 (QA_REPORT.md 기준)
- Swift 패턴 (35%): **10 / 10** — `final` / `private` / MARK / `for` 루프 / PhysicsBody 모든 속성 명시 모두 정석
- 게임 로직 (30%): **10 / 10** — SPEC §기능 1~4 1바이트 일치, 1-3/1-4 패턴 완전 폐기, velocity 전환 정확
- 성능 (20%): **10 / 10** — `update()` 안 노드 생성 0, weak 캡처 N/A, 빌드 클린
- 기능 완성도 (15%): **9 / 10** — `BUILD SUCCEEDED`, P0 위반 0. 시각 검증은 사용자 시뮬 실행으로만 최종 확정 (0.25 보수 차감)
- **가중평균: 9.85 / 10 — 합격 (Phase 1~2 통틀어 최고점)**

### 9-5. 사용자가 직접 확인할 것 ✅
시뮬레이터 `⌘R` 후 8가지:
- (a) 맵 중앙에 **2×4 tile 기둥** (40×80pt, `.ganhoPaper` 색) 보임 ← Phase 2-2 핵심
- (b) 박스가 기둥에 닿으면 **부딪혀 멈춤** — 통과 안 됨 ← 물리 엔진 작동 증거
- (c) 박스가 외곽 벽에도 *진짜로* 부딪힘 (1-4 자체 클램프와 시각 차이 거의 없지만 *물리 엔진이 막는* 감각)
- (d) D-Pad 떼면 박스 **즉시 정지** (linearDamping = 0 + currentDirection = .zero)
- (e) 박스가 벽/기둥 충돌 시 **회전 안 함** (allowsRotation = false)
- (f) 박스가 벽/기둥 충돌 시 **튕기지 않음** (restitution = 0)
- (g) 카메라가 박스 정중앙 follow (1-5 그대로)
- (h) D-Pad 우하단 고정 (1-3 그대로)

> **추가 관찰 포인트**: 박스가 기둥 코너에 비스듬히 부딪힐 때 SpriteKit이 자연스럽게 미끄러지는지. friction = 0이라 *완벽한 미끄럼*. 코너 회피가 자연스러우면 PhysicsBody 정석 사용 성공.

---

## 10. 다 읽었다면 다음은?

```
[1] §7 결정 5건 사용자 OK (모두 추천대로 가는지)
[2] rm -f SPEC.md SELF_CHECK.md QA_REPORT.md
[3] Planner   → SPEC.md
[4] Generator → PlayerNode/GameScene 수정 + SELF_CHECK.md
[5] Evaluator → QA_REPORT.md
[6] 합격 시 §9 회고 채우고 → Phase 2-3 (NoteNode + 음표 스폰)으로
```

> **2-2 본질**: 1-1에서 만들어둔 *물리 인프라*가 처음으로 *작동*. Phase 2-3 이후 모든 충돌(음표/적/투사체)이 이 위에 올라감. 기반 작업.
