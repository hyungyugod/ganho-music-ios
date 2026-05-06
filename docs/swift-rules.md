# Swift 코딩 규칙 — GanhoMusic iOS

Generator와 Evaluator가 공유하는 Swift 작성 기준.

---

## 1. 네이밍

| 대상 | 규칙 | 예시 |
|---|---|---|
| 타입 (class/struct/enum) | UpperCamelCase | `GameState`, `PlayerNode` |
| 함수/변수/프로퍼티 | lowerCamelCase | `spawnNote()`, `currentScore` |
| 상수 (전역) | lowerCamelCase | `let tileSize: CGFloat = 20` |
| enum case | lowerCamelCase | `.playing`, `.gameOver` |
| 파일명 | 타입명과 일치 | `PlayerNode.swift` |

- 한국어 변수명 금지. 주석은 한국어 허용.
- 약어는 전부 대문자: `urlString` ❌ → `urlString` ✅, `playerID` ✅

---

## 2. 타입 선택 원칙

```swift
// ✅ 값 타입이 기본 — 게임 오브젝트 데이터는 struct
struct NoteData {
    let position: CGPoint
    let value: Int
}

// ✅ SKNode 서브클래스는 class (SpriteKit 요구사항)
class PlayerNode: SKSpriteNode { ... }

// ✅ 게임 상태는 enum
enum GameState {
    case waiting
    case playing
    case paused
    case gameOver
}
```

---

## 3. 옵셔널 처리

```swift
// ❌ 강제 언래핑 금지 (크래시 원인)
let node = childNode(withName: "player")!

// ✅ guard let — 함수 초반 조기 탈출
guard let player = childNode(withName: "player") as? PlayerNode else { return }

// ✅ if let — 지역 사용
if let label = scoreLabel {
    label.text = "\(score)"
}

// ✅ ?? — 기본값 제공
let name = node.name ?? "unknown"
```

---

## 4. 함수 작성

```swift
// ✅ 기능 단위로 작게 분리
func spawnNote() {
    let note = NoteNode()
    note.position = randomPosition()
    addChild(note)
}

// ✅ 파라미터 레이블 명확하게
func move(player: PlayerNode, to direction: Direction) { ... }

// ❌ 함수 하나에 너무 많은 역할 금지
func doEverything() { /* 100줄짜리 함수 */ }
```

---

## 5. 클래스/씬 구조 순서

SpriteKit 씬 파일 내부 코드 순서:

```swift
class GameScene: SKScene {

    // MARK: - Properties (프로퍼티)
    var score = 0
    var gameState: GameState = .waiting
    private var player: PlayerNode?

    // MARK: - Lifecycle (씬 생명주기)
    override func sceneDidLoad() { ... }
    override func didMove(to view: SKView) { ... }

    // MARK: - Setup (초기화)
    func setupPlayer() { ... }
    func setupHUD() { ... }

    // MARK: - Game Loop (게임 루프)
    override func update(_ currentTime: TimeInterval) { ... }

    // MARK: - Spawn (오브젝트 생성)
    func spawnNote() { ... }
    func spawnEnemy() { ... }

    // MARK: - Touch (터치 입력)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { ... }

    // MARK: - Collision (충돌 처리)
    // SKPhysicsContactDelegate 메서드

    // MARK: - Game State (상태 전환)
    func startGame() { ... }
    func endGame() { ... }
    func pauseGame() { ... }
}
```

---

## 6. 메모리 관리

```swift
// ✅ 클로저에서 self 캡처 시 weak 사용
SKAction.run { [weak self] in
    self?.spawnNote()
}

// ✅ 노드 제거 시 액션도 함께 제거
node.removeAllActions()
node.removeFromParent()

// ❌ 타이머 방치 금지 — 씬 종료 시 반드시 무효화
// Timer.scheduledTimer 대신 SKAction.repeat 사용
```

---

## 7. 상수 관리

```swift
// ✅ 매직 넘버 금지 — enum 또는 struct Constants로 분리
enum GameConfig {
    static let gameDuration: TimeInterval = 45
    static let noteValue = 10
    static let playerSpeed: CGFloat = 200
    static let tileSize: CGFloat = 20
}

// 사용
let duration = GameConfig.gameDuration
```

---

## 8. 주석 규칙

```swift
// MARK: - 섹션 구분 (Xcode 네비게이터에 표시됨)

/// 함수/타입 설명 (퀵헬프에 표시)
/// - Parameter direction: 이동 방향
/// - Returns: 이동 성공 여부
func move(to direction: Direction) -> Bool { ... }

// 인라인 주석: 왜 이렇게 했는지 설명 (무엇인지 X)
// SpriteKit physics body는 씬에 추가된 후 설정해야 함
```

---

## 9. 금지 패턴

| 금지 | 대안 |
|---|---|
| `!` 강제 언래핑 | `guard let` / `if let` |
| `Timer.scheduledTimer` | `SKAction.wait(forDuration:)` |
| `DispatchQueue.main.asyncAfter` (게임 내) | `SKAction.sequence` |
| 전역 변수 남용 | 씬 프로퍼티로 관리 |
| `print()` 디버그 코드 잔류 | 완성 전 제거 |
| 하드코딩 색상 `UIColor(red:green:blue:)` | `UIColor.systemRed` 등 시맨틱 컬러 |
