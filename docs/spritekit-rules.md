# SpriteKit 패턴 규칙 — GanhoMusic iOS

SpriteKit 사용 시 지켜야 할 패턴. Generator와 Evaluator 공용.

---

## 1. 씬 생명주기

```
앱 시작
  └─ GameViewController.viewDidLoad()
       └─ SKView에 GameScene 로드
            └─ GameScene.sceneDidLoad()   ← 씬 파일 로드 직후 1회
            └─ GameScene.didMove(to:)     ← 씬이 뷰에 표시될 때 1회 (여기서 게임 초기화)
                 └─ update() 루프 시작    ← 매 프레임
```

**초기화는 `didMove(to:)`에서 한다.** `sceneDidLoad`는 SKS 파일 로드 직후라 뷰가 없을 수 있음.

```swift
override func didMove(to view: SKView) {
    setupPhysics()
    setupPlayer()
    setupHUD()
    setupControls()
}
```

---

## 2. 노드 계층 구조

```
GameScene (SKScene)
├── worldNode (SKNode)          ← 카메라 따라가는 게임 오브젝트 묶음
│   ├── PlayerNode (SKSpriteNode)
│   ├── noteNodes [SKSpriteNode]
│   └── enemyNode (SKSpriteNode)
└── hudNode (SKNode)            ← 항상 화면에 고정되는 UI
    ├── scoreLabel (SKLabelNode)
    └── timerLabel (SKLabelNode)
```

HUD는 카메라나 씬 좌표계에 종속되면 안 됨. 별도 노드로 분리.

---

## 3. 물리 충돌 설정

```swift
// ✅ 카테고리 비트마스크 — 2의 거듭제곱으로 정의
struct PhysicsCategory {
    static let none:    UInt32 = 0
    static let player:  UInt32 = 0b0001  // 1
    static let note:    UInt32 = 0b0010  // 2
    static let enemy:   UInt32 = 0b0100  // 4
    static let obstacle:UInt32 = 0b1000  // 8
}

// ✅ 물리 바디 설정 예시
player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
player.physicsBody?.categoryBitMask = PhysicsCategory.player
player.physicsBody?.contactTestBitMask = PhysicsCategory.note | PhysicsCategory.enemy
player.physicsBody?.collisionBitMask = PhysicsCategory.obstacle
player.physicsBody?.isDynamic = true
player.physicsBody?.affectedByGravity = false  // 탑뷰 게임은 중력 끔
```

```swift
// ✅ 충돌 델리게이트 등록
physicsWorld.contactDelegate = self

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let bodies = (contact.bodyA, contact.bodyB)
        // 순서 보장 안 됨 — 정렬 후 처리
        handleContact(bodies)
    }
}
```

---

## 4. 액션 패턴

```swift
// ✅ 반복 스폰 — Timer 대신 SKAction 사용
let spawnAction = SKAction.sequence([
    SKAction.run { [weak self] in self?.spawnNote() },
    SKAction.wait(forDuration: 1.5)
])
run(SKAction.repeatForever(spawnAction), withKey: "spawning")

// ✅ 액션 키로 관리 — 나중에 멈추거나 교체 가능
removeAction(forKey: "spawning")

// ✅ 노드 이동
let move = SKAction.move(to: target, duration: 0.3)
let fade = SKAction.fadeOut(withDuration: 0.2)
let remove = SKAction.removeFromParent()
node.run(SKAction.sequence([move, fade, remove]))
```

---

## 5. 게임 루프 패턴

```swift
private var lastUpdateTime: TimeInterval = 0

override func update(_ currentTime: TimeInterval) {
    // 첫 프레임 처리
    if lastUpdateTime == 0 { lastUpdateTime = currentTime }
    let dt = currentTime - lastUpdateTime  // delta time (초)
    lastUpdateTime = currentTime

    // 게임 상태 체크
    guard gameState == .playing else { return }

    // 프레임별 업데이트
    updateTimer(dt: dt)
    updateEnemy(dt: dt)
}
```

`dt` (delta time) 기반으로 이동량을 계산해야 프레임레이트와 무관하게 일정한 속도가 나옴.
```swift
// ✅ dt 기반 이동
player.position.x += speed * CGFloat(dt)

// ❌ 고정값 이동 — 60fps/120fps에서 속도가 달라짐
player.position.x += 5
```

---

## 6. 레이블 (HUD 텍스트)

```swift
// ✅ SKLabelNode 기본 설정
let scoreLabel = SKLabelNode(fontNamed: "DungGeunMo")  // 픽셀 폰트
scoreLabel.fontSize = 24
scoreLabel.fontColor = .white
scoreLabel.horizontalAlignmentMode = .left
scoreLabel.verticalAlignmentMode = .top
scoreLabel.position = CGPoint(x: 20, y: frame.maxY - 20)
addChild(scoreLabel)

// ✅ 업데이트
scoreLabel.text = "Score: \(score)"
```

---

## 7. 씬 전환

```swift
// ✅ 씬 전환 — 결과 화면으로
let gameOver = GameOverScene(size: size)
gameOver.scaleMode = .aspectFill
let transition = SKTransition.fade(withDuration: 0.5)
view?.presentScene(gameOver, transition: transition)
```

---

## 8. 성능 규칙

- **텍스처 아틀라스**: 스프라이트 여러 개는 `SKTextureAtlas`로 묶어 드로우콜 줄이기
- **노드 재사용**: 자주 생성/삭제되는 오브젝트(음표 등)는 오브젝트 풀 패턴 고려
- **물리 바디 단순화**: 복잡한 폴리곤보다 `rectangleOf`/`circleOfRadius` 우선
- **`update()` 최소화**: 매 프레임 실행되므로 무거운 연산(배열 정렬 등) 넣지 말 것
- **타겟 FPS**: 60fps 유지. Xcode 디버그 통계로 확인.

---

## 9. 좌표계 주의사항

SpriteKit은 **좌하단이 (0,0)** — UIKit(좌상단)과 반대.

```
(0, height) ──────── (width, height)
     │                      │
     │      GameScene        │
     │                      │
  (0, 0) ──────────── (width, 0)
```

```swift
// 화면 중앙
let center = CGPoint(x: frame.midX, y: frame.midY)

// 화면 상단 (HUD 위치)
let top = CGPoint(x: frame.midX, y: frame.maxY - 40)
```

---

## 10. 금지 패턴

| 금지 | 이유 | 대안 |
|---|---|---|
| `SKScene` 안에서 `UIKit` 직접 사용 | 좌표계 충돌 | SKNode 기반 UI 또는 오버레이 분리 |
| 물리 델리게이트에서 노드 즉시 삭제 | 크래시 | `defer` 또는 다음 프레임에 삭제 |
| `update()` 안에 `addChild()` 반복 | 성능 저하 | 스폰은 액션으로 분리 |
| 텍스처 매 프레임 생성 | 메모리 누수 | 전역 캐시 또는 `SKTextureAtlas` |

---

## 11. 파일 분리 전략

**원칙: 1 파일 = 1 클래스.** `GameScene.swift` 가 300줄을 넘으면 분리 신호.
**Spring(clonebose) 폴더명을 의도적으로 차용**한다 (자세한 매핑은 `architecture-mapping.md` 참조).

### 권장 디렉터리 구조 (Phase 2 진입 전 정착)

```
GanhoMusic Shared/
├── Scenes/                       ← Spring controllers/ 대응 — 입력→로직 위임
│   ├── GameScene.swift           메인 게임 루프만 보유
│   ├── TitleScene.swift          Phase 3
│   └── GameOverScene.swift       Phase 3
│
├── Nodes/                        ← 게임 고유 (Spring에 없음) — 살아있는 시각 객체
│   ├── PlayerNode.swift          김간호 캐릭터
│   ├── NoteNode.swift            음표 ♪
│   ├── EnemyNode.swift           수간호사 NPC
│   ├── ProjectileNode.swift      F 투사체
│   └── HUDNode.swift             점수/타이머/콤보 표시
│
├── Systems/                      ← Spring services/ 대응 — 게임 도메인 로직
│   ├── SpawnSystem.swift         음표/적 스폰 (schedulers/ 흡수)
│   ├── ScoreSystem.swift         점수·콤보·등급 계산
│   ├── BeatSystem.swift          BPM 동기화 / On-Beat 판정
│   └── InputSystem.swift         스와이프 / 터치 입력 해석
│
├── Repositories/                 ← Spring mappers/ 대응 — 외부 데이터 접근
│   ├── ScoreRepository.swift     UserDefaults 최고 점수 (Phase 3)
│   └── LeaderboardRepository.swift  Supabase 리더보드 (Phase 7)
│
├── Models/                       ← Spring models/ 대응 — 값 객체 (struct 우선)
│   ├── Score.swift               점수 + 등급 + 날짜
│   ├── BeatTiming.swift          비트 타이밍 데이터
│   └── DTO/                      서버 통신용 (Phase 7)
│       └── ScoreDTO.swift
│
├── Managers/                     ← Spring managers/ 대응 — 공통 보조 (싱글톤)
│   ├── AudioManager.swift        BGM / 효과음
│   ├── HapticsManager.swift      iPhone 햅틱
│   └── AnalyticsManager.swift    이벤트 로깅 (Phase 4+)
│
├── Config/                       ← Spring config/ 대응 — 설정·상수
│   ├── GameConfig.swift          상수 enum (게임 시간, BPM 등)
│   ├── PhysicsCategory.swift     비트마스크 정의
│   ├── GameState.swift           상태 enum
│   └── ColorTokens.swift         UIColor extension (assets.md §1)
│
├── Errors/                       ← Spring exceptions/ 대응 — 얇게
│   └── GameError.swift           enum: Error
│
└── Resources/                    ← Spring resources/ 대응 — 정적 자산
    ├── GameScene.sks             SpriteKit 씬 파일 (templates/ 대응)
    ├── Actions.sks               공용 액션
    └── Assets.xcassets/          이미지·컬러·아이콘 (static/ 대응)
        ├── Sprites.spriteatlas/  텍스처 아틀라스
        └── Colors/               16색 팔레트 (assets.md §1)
```

### Spring → SpriteKit 폴더 대응표

| Spring 폴더 | 본 프로젝트 폴더 | 비고 |
|---|---|---|
| `controllers/` | `Scenes/` | 사용자 입력 처리 |
| `services/` | `Systems/` | 게임 도메인 로직 |
| `mappers/` | `Repositories/` | 외부 데이터 접근 |
| `models/` | `Models/` | 값 객체 (struct) |
| `managers/` | `Managers/` | 공통 보조 |
| `config/` | `Config/` | 상수 / 설정 |
| `exceptions/` | `Errors/` | enum: Error |
| `schedulers/` | (Systems 내부 흡수) | SKAction 으로 |
| `interceptors/` | (게임에선 거의 미사용) | |
| `resources/` | `Resources/` | 씬·이미지·사운드 |
| (없음) | `Nodes/` | 게임 고유 — 살아있는 시각 객체 |

### 분리 판단 기준

| 신호 | 조치 |
|---|---|
| 파일이 300줄 초과 | 가장 무거운 책임을 별도 파일로 분리 |
| 한 함수가 60줄 초과 | 의미 단위로 쪼개고 호출 |
| 같은 매직 넘버가 3곳 이상 | `GameConfig` 로 이동 |
| 새 SKNode 서브클래스 등장 | 즉시 `Nodes/` 로 분리 |
| 시스템 레벨 로직 (스폰/점수/입력) 등장 | `Systems/` 로 분리 |

### Scene과 Node/System의 책임 경계

`GameScene.swift` 는 다음만 보유:
1. 씬 생명주기 (`didMove`, `update`)
2. 게임 상태 (`gameState: GameState`)
3. 자식 노드/시스템 인스턴스 보유 + 메시지 전달

게임 *로직*은 무조건 Node 또는 System으로. `GameScene` 은 오케스트레이터일 뿐.

```swift
// ✅ 좋음 — GameScene은 위임만
override func update(_ currentTime: TimeInterval) {
    let dt = deltaTime(currentTime)
    guard gameState == .playing else { return }
    spawnSystem.update(dt: dt)
    beatSystem.update(currentTime: currentTime)
    hud.update(score: scoreSystem.current)
}

// ❌ 나쁨 — GameScene이 모든 걸 직접 함
override func update(_ currentTime: TimeInterval) {
    // 200줄짜리 게임 루프
}
```
