# Phase 4-2 (A) — 석조무사 접촉 감지 골격

## 개요
4-1에서 도입된 StoneGuardNode를 *접촉 감지 가능한 NPC*로 승격한다. PhysicsBody 부착 + PhysicsCategory 비트 신설 + ContactRouter 분기 추가 + GameScene stub 콜백 등록으로 "라우팅 골격"만 완성한다. 이스터에그 효과 본체는 다음 sprint(4-3)에서 *시그니처 변경 없이* 빈 본문만 채워 추가한다.

## 변경 유형
**게임플레이** — 새 PhysicsCategory 비트와 PhysicsBody·contact 분기 도입. 시각·점수·HUD 변화는 0.

## 게임 경험 의도
플레이어가 석조무사 위를 걸어가도 시각·점수·HUD에는 *변화가 없어 보인다*. 그러나 내부적으로는 SpriteKit이 "접촉했다"를 감지해 ContactRouter가 stoneGuard 분기로 라우팅하고, GameScene이 등록한 *빈 콜백*까지 호출이 도달한다. 학습 노트 §3-5/§3-6의 "그릇만 먼저 만든다" 원칙 — 본 sprint는 *감지 경로*만 완성하고, *효과*는 다음 sprint의 자리로 남겨둔다.

## Sprint 범위 계약

### In Scope (모두 필수)

1. **`Config/PhysicsCategory.swift`** (+1줄)
   - `static let stoneGuard: UInt32 = 0b100000` (= 32) 추가.
   - `projectile = 0b10000` 다음 줄에 삽입.
   - 기존 비트(none/player/note/enemy/wall/projectile) 변경 절대 금지.

2. **`Nodes/StoneGuardNode.swift`** (+~12줄)
   - 파일 헤더에 Phase 4-2 라인 1줄 추가.
   - `init()` 내부, `super.init` 다음·`startPatrol()` 호출 *직전*에 SKPhysicsBody 부착 블록 삽입.
   - 본문: `rectangleOf: size` / `isDynamic = false` / `allowsRotation = false` / `friction = 0` / `restitution = 0` / `linearDamping = 0` / `categoryBitMask = .stoneGuard` / `collisionBitMask = 0` / `contactTestBitMask = .player`.
   - 기존 `// physicsBody = nil (기본값). 본 sprint OoS — 4-2에서 도입.` 주석은 *제거*하거나 4-2에서 도입했음을 알리는 형태로 갱신.

3. **`Systems/ContactRouter.swift`** (+~5줄)
   - `// MARK: - Callbacks` 섹션에 `var onStoneGuardContact: () -> Void = {}` 1줄 추가 (위치: `onEnemyHit` 바로 다음).
   - `didBegin(_:)` 내부 분기: `enemy` 다음, `projectile` 직전에 stoneGuard 3줄 분기 삽입.
   - 최종 분기 순서: `enemy → stoneGuard → projectile → note`.

4. **`GameScene.swift`** (+~4줄)
   - 파일 헤더 MARK 주석 1줄 추가:
     `//  Phase 4-2 · StoneGuardNode PhysicsBody 부착 + ContactRouter onStoneGuardContact stub`
   - `configureContactRouter()` 본문 끝에 `contactRouter.onStoneGuardContact` 콜백 등록 추가 (`[weak self] in` + TODO 주석 1줄).
   - 그 외 메서드/프로퍼티 일체 변경 금지.

### Out of Scope (모두 금지, 위반 시 P0)

- `GameScene+Setup.swift` 전 영역 — `setupStoneGuard()` 포함 한 줄도 안 건드림.
- `GameConfig` 변경 (stoneGuard 상수는 4-1 그대로).
- pbxproj 변경 (신규 파일 0건).
- waypoint 좌표/패트롤 속도/방향/크기 변경.
- 다른 노드 변경 (Player/Enemy/Note/Projectile/HUD/DPad).
- 다른 시스템 변경 (SpawnSystem/ScoreSystem).
- TitleScene/ResultScene 변경.
- 새 ColorTokens 토큰 신설.
- `update()` 게임 루프 변경.
- `endGame()` / `configureContactRouter()` 외 GameScene 메서드 변경.
- 이스터에그 효과(오버레이/비행기/폭탄/수간호사 도주) — 4-3.
- 콘솔 `print` / `NSLog` 추가. stub 콜백 본문은 *완전히* 비어있어야 하며 TODO 주석 1줄만 허용.
- macOS/tvOS Sources phase 변경.
- Test 코드 추가.

### 판단 기준
"이 변경이 없으면 '플레이어가 석조무사를 통과하면 `ContactRouter.onStoneGuardContact`가 호출된다'가 동작하는가?" → **NO**일 때만 In Scope.

## 변경 범위

### 수정할 파일 (4개)
- `GanhoMusic/GanhoMusic Shared/Config/PhysicsCategory.swift` (+1줄)
- `GanhoMusic/GanhoMusic Shared/Nodes/StoneGuardNode.swift` (+~12줄)
- `GanhoMusic/GanhoMusic Shared/Systems/ContactRouter.swift` (+~5줄)
- `GanhoMusic/GanhoMusic Shared/GameScene.swift` (+~4줄: 헤더 1줄 + configureContactRouter 본문 3줄)

### 추가할 파일
없음.

### pbxproj
변경 없음.

## 기능 상세

### 기능 1: PhysicsCategory에 stoneGuard 비트 신설
- 설명: 석조무사 PhysicsBody가 자기 정체를 비트마스크로 선언할 수 있도록 비트 하나를 새로 할당한다. 2의 거듭제곱 규칙 준수(32 = `0b100000`).
- 구현 위치: `Config/PhysicsCategory.swift` — `projectile` 줄 다음.
- 최종 형태:
  ```swift
  struct PhysicsCategory {
      static let none:       UInt32 = 0
      static let player:     UInt32 = 0b0001    // 1
      static let note:       UInt32 = 0b0010    // 2
      static let enemy:      UInt32 = 0b0100    // 4
      static let wall:       UInt32 = 0b1000    // 8
      static let projectile: UInt32 = 0b10000   // 16  ← Phase 2-7 신설
      static let stoneGuard: UInt32 = 0b100000  // 32  ← Phase 4-2 신설
  }
  ```

### 기능 2: StoneGuardNode에 PhysicsBody 부착 (통과형)
- 설명: 정적 사각 PhysicsBody를 부착하되, `collisionBitMask = 0`으로 두어 *물리적으로는 막지 않고* `contactTestBitMask = .player`로 *접촉 사실만 보고*한다. 학습 노트 §3-1/§3-3/§3-4의 핵심 패턴.
- 구현 위치: `Nodes/StoneGuardNode.swift` — `init()` 내부, `super.init(...)` 다음·`startPatrol()` 호출 *직전*. EnemyNode 패턴 답습(`let body = SKPhysicsBody(rectangleOf: size); ... ; physicsBody = body`).
- `isDynamic = false` 근거: StoneGuard는 `SKAction.move(to:duration:)`로 위치를 직접 갱신 (velocity 미사용) — 동적 body로 두면 patrol 액션과 물리 엔진이 충돌해 위치가 뜯어진다.
- 파일 헤더 추가 라인:
  ```
  //  Phase 4-2 · PhysicsBody 부착 (collision=0 통과형, contactTest=.player)
  ```
- 최종 init 형태:
  ```swift
  init() {
      let size = CGSize(
          width:  GameConfig.stoneGuardWidth,
          height: GameConfig.stoneGuardHeight
      )
      super.init(texture: nil, color: .ganhoPaper, size: size)
      name = "stoneGuard"
      zPosition = 5

      // Phase 4-2 — PhysicsBody 부착. EnemyNode 패턴 답습하되 collision=0(통과형).
      // patrol은 SKAction.move 기반 → isDynamic=false (velocity 미사용).
      let body = SKPhysicsBody(rectangleOf: size)
      body.isDynamic           = false
      body.allowsRotation      = false
      body.friction            = 0
      body.restitution         = 0
      body.linearDamping       = 0
      body.categoryBitMask     = PhysicsCategory.stoneGuard
      body.collisionBitMask    = 0                            // 통과형 — 아무도 막지 않음
      body.contactTestBitMask  = PhysicsCategory.player       // player와 닿으면 알림
      physicsBody = body

      startPatrol()
  }
  ```
- 기존 `// physicsBody = nil (기본값). 본 sprint OoS — 4-2에서 도입.` 줄은 *삭제* (또는 위 블록 주석으로 대체됨).

### 기능 3: ContactRouter에 stoneGuard 분기 + 콜백 변수 추가
- 설명: 콜백 변수 1개 신설 + `didBegin` 내부 분기 1개 추가. 기존 enemy/projectile/note 분기는 한 줄도 손대지 않는다.
- 구현 위치: `Systems/ContactRouter.swift`.
- 콜백 변수 (`// MARK: - Callbacks` 섹션, `onEnemyHit` 다음):
  ```swift
  /// player ↔ stoneGuard 접촉 시. Phase 4-2 — stub. 본체는 4-3에서.
  var onStoneGuardContact: () -> Void = {}
  ```
- `didBegin(_:)` 최종 분기 순서:
  ```swift
  func didBegin(_ contact: SKPhysicsContact) {
      let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

      if categories & PhysicsCategory.enemy != 0 {
          onEnemyHit()
          return
      }
      if categories & PhysicsCategory.stoneGuard != 0 {     // ← 신설 분기
          onStoneGuardContact()
          return
      }
      if categories & PhysicsCategory.projectile != 0 {
          handleProjectileContact(contact)
          return
      }
      if categories & PhysicsCategory.note != 0 {
          handleNoteContact(contact)
      }
  }
  ```
- 분기 순서 근거: enemy는 player가 즉시 게임오버되는 최상위 우선순위. stoneGuard는 enemy 다음, projectile/note보다 우선 — 학습 노트 §3-5 예시와 일치. enemy/projectile/note는 카테고리가 서로 배타적이라 이전 순서 변경의 부작용 없음.

### 기능 4: GameScene에 stub 콜백 등록
- 설명: `configureContactRouter()` 본문 끝에 `onStoneGuardContact`를 빈 클로저로 등록. 본 sprint의 *효과 0* 정책 — 본문은 TODO 주석 1줄만.
- 구현 위치: `GameScene.swift` 두 곳.
  - 파일 헤더 MARK 주석(기존 `Phase 4-1` 줄 다음):
    ```
    //  Phase 4-2 · StoneGuardNode PhysicsBody 부착 + ContactRouter onStoneGuardContact stub
    ```
  - `configureContactRouter()` 본문 *끝*(`onNoteCollected` 등록 다음):
    ```swift
    contactRouter.onStoneGuardContact = {
        // Phase 4-2 — stub. 4-3에서 이스터에그 트리거 본체가 들어옴.
    }
    ```
- 캡처 정책: 본 sprint stub은 self 미사용 — `[weak self]` 생략. 4-3 시 self를 사용할 경우 그때 `[weak self] in`을 도입(시그니처가 아닌 *클로저 캡처*만 추가, 외부 호출자/등록자 시그니처는 그대로 유지). 본 sprint 빈 본문에 `[weak self]`만 두면 Xcode가 *unused capture* 경고를 띄울 수 있어 OoS의 "경고 0건" 위반 위험 → 빈 캡처로 시작.

## 검증 시나리오 (학습 노트 §5 표 정확 매핑 + 정적 검증 방법)

| # | 시나리오 | 기대 결과 | 정적 검증 방법 |
|---|---|---|---|
| (a) | 게임 시작 직후 | 4-1과 동일 — 석조무사 박스(.ganhoPaper)가 (200,100)에서 시계방향 사각 순환 | `StoneGuardNode.startPatrol()` 본문 / `setupStoneGuard()` / `stoneGuardWaypoints` 모두 *미변경* 확인 |
| (b) | 플레이어가 석조무사 위로 걸어감 | 시각상 그대로 통과 (튕김·정지 0) | `collisionBitMask = 0` 확인. `isDynamic = false` 확인. 다른 노드의 `collisionBitMask`에 `.stoneGuard` 미포함 확인 |
| (c) | 통과 시 점수·콤보·HUD | 변화 0 | `onStoneGuardContact` stub 본문에 `scoreSystem` / `hud` / `endGame` 호출 0건 확인. TODO 주석 외 코드 0줄 |
| (d) | 통과 시 콘솔 출력 | 변화 0 (요구 사항 명시 없음) | 추가된 4개 파일 어디에도 `print` / `NSLog` / `debugPrint` 0건 (Grep) |
| (e) | enemy/projectile/note 접촉 | 4-1과 100% 동일 (회귀 0) | `ContactRouter.didBegin`의 enemy/projectile/note 분기 본문 *미변경* 확인. `handleProjectileContact` / `handleNoteContact` 함수 *미변경* 확인 |
| (f) | 한 판 전체 → 게임오버 | 4-1과 100% 동일 | `endGame()` 본문 *미변경* / `SpawnSystem.stop` / ResultScene presentation flow *미변경* 확인 |
| (g) | 결과 화면 → 다시 플레이 | 4-1과 100% 동일 | TitleScene/ResultScene 0줄 변경 확인 (Grep `TitleScene` `ResultScene`) |
| (h) | 빌드 SUCCEEDED + 경고 0건 | 빌드 클린 | 강제 언래핑·매직 넘버·미사용 변수 0건. PhysicsCategory 상수만 사용 |

추가 회귀 검증:
- `GameScene+Setup.swift` 파일은 한 줄도 변경되지 않음 → `setupStoneGuard()` 본문(`waypoints[0]` 위치 부여 + worldNode addChild) 그대로.
- `GameConfig.swift`는 한 줄도 변경되지 않음 → stoneGuard 상수 4개(width/height/speed/waypoints) 그대로.
- pbxproj는 한 줄도 변경되지 않음 → 신규 파일 0건.

## 학습 가치 (Spring 비유 포함)
- **PhysicsBody 3비트마스크 패턴**: `category`(명찰 / URL path), `collision`(차단 / 미들웨어 차단), `contactTest`(알림 / @EventListener 구독) — 셋의 *독립성*을 명확히 학습.
- **collision=0 통과형 노드 패턴**: 첫 도입 — 4-3 이스터에그가 *통과 시나리오*임을 코드 레벨에서 미리 표현.
- **ContactRouter 분기 순서 결정**: 게임오버 우선순위(enemy > stoneGuard > projectile/note) 명시. 새 분기를 *어디에 끼울지*가 유지보수 첫 의사결정.
- **stub 콜백 = 시그니처 확정 분리 sprint**: 다음 sprint의 *코드 변경량을 최소화*하는 패턴 — Spring의 "@Service 메서드만 먼저 정의" 분리와 1:1 대응.

## 주의사항

1. **stub 콜백 본문 = 완전히 비어있어야 함**
   - 학습 노트 §3-6 그대로 *효과 0*. `print` 1줄도 금지.
   - 빈 클로저 `{ }` + TODO 주석 1줄. 다음 sprint에서 본체를 채울 때 *호출 측 시그니처 변경 0*.

2. **분기 순서 신중**: stoneGuard 분기를 enemy *앞에* 두면 enemy↔stoneGuard 동시 접촉 시(이론상 불가능하지만) 게임오버 누락. 반드시 enemy *다음*.

3. **`collisionBitMask = 0`은 양방향 정책 확인 필요 없음**: 다른 노드(Player/Enemy/Projectile)의 `collisionBitMask`에 `.stoneGuard`가 *원래 없음*. 따라서 그쪽도 자연스럽게 stoneGuard를 통과. 양방향 수정 0건.

4. **`isDynamic = false`인데 contact 받는가? — YES**: SpriteKit은 두 body 중 *최소 한 쪽이라도 dynamic*이면 contact 알림 호출. Player가 dynamic이므로 stoneGuard가 static이어도 `didBegin` 호출 보장. EnemyNode와 다른 점(stoneGuard는 SKAction.move 기반 → static이 맞음).

5. **`physicsBody = body`는 init 안에서만**: SpriteKit은 노드가 씬에 추가된 *후* body를 설정해도 동작은 하지만, EnemyNode/Player 패턴(init 안 설정) 유지로 일관성 확보.

6. **stoneGuard 비트(`0b100000`)는 *4-1 GameConfig 4개 상수와 별도 파일*에서 관리됨**: GameConfig 변경 0 / PhysicsCategory만 변경 1줄 — OoS 경계 정확.

7. **빌드 경고 0건 목표**: 미사용 캡처 경고, 미사용 변수 경고, unused result 경고 모두 0건. stub 클로저에 *불필요한 캡처*나 빈 변수 일체 금지.
