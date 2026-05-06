# Spring(clonebose) → Swift/SpriteKit(GanhoMusic) 아키텍처 매핑

이 문서는 **Spring/Java로 일하던 사람이 Swift/SpriteKit을 처음 만질 때 멘탈 모델 전환 비용을 최소화**하기 위한 학습 가이드다.
GanhoMusic의 폴더 구조는 의도적으로 clonebose와 비슷하게 짜여 있다. 단, **Swift 고유 패턴(struct, protocol, extension, optional)** 은 그대로 유지한다.

**선행 참조**:
- `docs/spritekit-rules.md` §11 — 실제 디렉터리 구조 정의
- `docs/swift-rules.md` — Swift 코딩 컨벤션
- `clonebose/src/main/java/com/clonebose/bose/` — 비교용 원본

---

## 1. 한눈에 보는 매핑 표

| clonebose (Spring) | GanhoMusic (SpriteKit) | 역할의 본질 | 비고 |
|---|---|---|---|
| `controllers/` | `Scenes/` | "흐름 지휘자" | HTTP 요청 → 사용자 입력 |
| `services/` | `Systems/` | "도메인 로직" | 비즈니스 규칙 → 게임 규칙 |
| `services/impl/` | (생략 또는 protocol+struct) | 인터페이스 분리 | Swift는 작을 때 단일 클래스 |
| `mappers/` (MyBatis) | `Repositories/` | "외부 데이터 접근" | DB → UserDefaults/Supabase |
| `models/` | `Models/` | "값 객체" | class → struct로 |
| `managers/` | `Managers/` | "공통 보조" | 이메일/파일 → 사운드/햅틱 |
| `config/` | `Config/` | "설정·상수" | Bean → enum static let |
| `schedulers/` | (Systems 내부 흡수) | 주기 작업 | `@Scheduled` → `SKAction.repeatForever` |
| `exceptions/` | `Errors/` (얇게) | 예외 타입 | `Exception` → `enum: Error` |
| `interceptors/` | (필요 시 SwiftUI/UIKit AppDelegate에) | 횡단 관심사 | 게임에선 거의 안 씀 |
| `resources/templates/` | `Resources/` (.sks, Assets.xcassets) | 정적 자산 | HTML → SKS / 이미지 |
| **(Spring에 없음)** | **`Nodes/`** | "살아있는 시각 객체" | 게임 고유 |

---

## 2. 폴더별 변환 룰 (코드 예시)

### 2-1. Controllers → Scenes

**Spring 원본 (`ProductController.java`)**
```java
@Controller
public class ProductController {
    @Autowired private ProductService productService;
    
    @GetMapping("/products/{id}")
    public String detail(@PathVariable Long id, Model model) {
        Product p = productService.findById(id);
        model.addAttribute("product", p);
        return "products/detail";
    }
}
```

**Swift 변환 (`Scenes/GameScene.swift`)**
```swift
class GameScene: SKScene {
    // Spring의 @Autowired에 해당 — 이니셜라이저 주입 또는 직접 보유
    private let scoreSystem = ScoreSystem()
    private let spawnSystem = SpawnSystem()
    
    // @GetMapping에 해당 — "사용자가 화면을 터치했을 때"
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        spawnSystem.handleTap(at: location)
    }
}
```

**핵심 차이**:
- 라우팅 = 메서드 시그니처 (`touchesBegan`, `update`)
- 모델 바인딩 = 직접 Node 속성 갱신
- 뷰 이름 반환 없음 — Scene 자체가 뷰

### 2-2. Services → Systems

**Spring 원본**
```java
public interface ProductService {
    Product findById(Long id);
}

@Service
public class ProductServiceImpl implements ProductService {
    @Autowired private ProductMapper mapper;
    public Product findById(Long id) { return mapper.selectById(id); }
}
```

**Swift 변환 — 작을 때 (단일 클래스)**
```swift
final class ScoreSystem {
    private let repository = ScoreRepository()
    private(set) var current: Int = 0
    private(set) var combo: Int = 1
    
    func add(noteValue: Int, onBeat: Bool) {
        let bonus = onBeat ? 5 : 0
        current += (noteValue + bonus) * combo
        combo = onBeat ? combo + 1 : 1
    }
    
    func saveBestIfHigher() {
        repository.saveBest(score: current)
    }
}
```

**Swift 변환 — 클 때 또는 테스트 필요할 때 (protocol 도입)**
```swift
protocol ScoreSystemProtocol {
    var current: Int { get }
    func add(noteValue: Int, onBeat: Bool)
}

final class ScoreSystem: ScoreSystemProtocol { ... }

// 테스트용 가짜
final class MockScoreSystem: ScoreSystemProtocol { ... }
```

**핵심 차이**:
- Spring은 DI 위해 interface 거의 강제. Swift는 **필요할 때만**.
- `final` 키워드 권장 — 상속 차단으로 컴파일러 최적화.
- `private(set)` — Java의 "public getter, private setter" 한 줄로 처리.

### 2-3. Mappers → Repositories

**Spring 원본 (`ProductMapper.java`)**
```java
@Mapper
public interface ProductMapper {
    Product selectById(@Param("id") Long id);
}
```

**Swift 변환 (`Repositories/ScoreRepository.swift`)**
```swift
final class ScoreRepository {
    private let defaults = UserDefaults.standard
    private enum Key {
        static let bestScore = "ganho.bestScore"
        static let bestDate  = "ganho.bestDate"
    }
    
    func loadBest() -> Int {
        defaults.integer(forKey: Key.bestScore)
    }
    
    func saveBest(score: Int) {
        guard score > loadBest() else { return }
        defaults.set(score, forKey: Key.bestScore)
        defaults.set(Date(), forKey: Key.bestDate)
    }
}
```

**Phase 7 (Supabase 연동) 시 변환**
```swift
// supabase-swift SDK 사용
final class ScoreRepository {
    private let client: SupabaseClient
    
    func uploadBest(score: Int) async throws {
        try await client.from("scores").insert(["score": score]).execute()
    }
}
```

**핵심 차이**:
- MyBatis는 SQL을 XML/어노테이션에. Swift는 **메서드 안에 직접**.
- 비동기는 `async/await` — Java의 `CompletableFuture` 와 흡사하지만 더 깔끔.

### 2-4. Models → Models (가장 중요한 변환)

**Spring 원본 (`Product.java`)**
```java
@Data  // Lombok
@Entity
public class Product {
    @Id private Long id;
    private String name;
    private int price;
}
```

**Swift 변환 (`Models/Score.swift`)**
```swift
struct Score: Codable, Equatable {
    let value: Int
    let combo: Int
    let date: Date
    let grade: Grade
    
    enum Grade: String, Codable {
        case s, a, b, c
        
        static func from(value: Int) -> Grade {
            switch value {
            case 800...:    return .s
            case 500..<800: return .a
            case 200..<500: return .b
            default:        return .c
            }
        }
    }
}
```

**핵심 차이 4가지**:
1. **`class` → `struct`**: Swift는 값 타입 기본. 복사 시 깊은 복사 → 동시성 안전.
2. **Lombok `@Data` 불필요**: Swift는 프로퍼티 자동 게터/세터. `Codable` 한 줄로 JSON 직렬화.
3. **`enum` 이 강력**: Java enum과 달리 Swift enum은 메서드, 연관값(associated value), 패턴 매칭 가능.
4. **불변 기본**: `let` 우선, 변경 필요할 때만 `var`. Java의 `final` 일일이 안 붙여도 됨.

### 2-5. Managers → Managers (이름 그대로)

**Spring 원본 (`EmailManager.java`)**
```java
@Component
public class EmailManager {
    public void send(String to, String subject) { ... }
}
```

**Swift 변환 (`Managers/AudioManager.swift`)**
```swift
final class AudioManager {
    static let shared = AudioManager()  // 싱글톤 (Spring @Component 효과)
    private init() {}                   // 외부 인스턴스화 차단
    
    private var bgmPlayer: AVAudioPlayer?
    
    func playBGM(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "m4a") else { return }
        bgmPlayer = try? AVAudioPlayer(contentsOf: url)
        bgmPlayer?.numberOfLoops = -1
        bgmPlayer?.play()
    }
}
```

**핵심 차이**:
- Spring `@Component` = **싱글톤 + DI 등록**. Swift는 직접 `static let shared` 패턴.
- 어노테이션 없음 — 명시적 코드로 표현.

### 2-6. Config → Config

**Spring 원본**
```java
@Configuration
public class MyWebConfig implements WebMvcConfigurer { ... }

// application.yml
server:
  port: 8080
```

**Swift 변환 (`Config/GameConfig.swift`)**
```swift
enum GameConfig {
    static let gameDuration: TimeInterval = 45
    static let bpm: Double = 120
    static let onBeatToleranceMs: Double = 150
    static let noteValue: Int = 10
    static let playerSpeed: CGFloat = 200
    static let tileSize: CGFloat = 20
    static let initialShield: Int = 1
    static let shieldRefillEvery: Int = 30  // 음표 30개당 보호막 +1
}
```

**핵심 차이**:
- Spring은 **외부 파일(yml)** + Java config 클래스. Swift는 **enum + static let** 한 곳.
- `enum` 을 namespace로 씀 (case가 없는 enum은 인스턴스화 불가 → 상수 그릇으로 안전).

### 2-7. Schedulers는 사라진다

**Spring 원본 (`CleanupScheduler.java`)**
```java
@Scheduled(cron = "0 0 * * * *")
public void cleanup() { ... }
```

**Swift 변환 — 별도 폴더 없이 시스템 안에서**
```swift
// Systems/SpawnSystem.swift
final class SpawnSystem {
    func start(in scene: SKScene) {
        let spawn = SKAction.run { [weak self] in self?.spawnNote() }
        let wait = SKAction.wait(forDuration: 0.5)  // 120 BPM
        let loop = SKAction.repeatForever(.sequence([spawn, wait]))
        scene.run(loop, withKey: "spawn")
    }
    
    func stop(from scene: SKScene) {
        scene.removeAction(forKey: "spawn")
    }
}
```

**왜 폴더가 사라지는가**: SpriteKit에서 "주기 실행"은 행위지 위치가 아님. 해당 시스템이 자기 스케줄을 보유.

### 2-8. Nodes — Spring에는 없는 게임 고유 영역 ⭐

**개념**: Spring 멘탈 모델로 보면 **"Model + View + Controller가 한 클래스에 응축된 살아있는 객체"**.

**예시 (`Nodes/PlayerNode.swift`)**
```swift
final class PlayerNode: SKSpriteNode {
    // 데이터 (Model 역할)
    private(set) var hp: Int = 1
    private(set) var shield: Int = GameConfig.initialShield
    
    // 시각 (View 역할) — SKSpriteNode 상속으로 자동
    
    // 행위 (Controller 일부) — 자기 자신을 어떻게 갱신하는가
    func takeDamage() {
        if shield > 0 {
            shield -= 1
            playShieldBreakAnimation()
        } else {
            hp = 0
            playDeathAnimation()
        }
    }
    
    private func playShieldBreakAnimation() {
        let flash = SKAction.sequence([
            .colorize(with: .ganhoYellowF, colorBlendFactor: 1, duration: 0.05),
            .colorize(withColorBlendFactor: 0, duration: 0.1)
        ])
        run(flash)
    }
}
```

**Spring 사람이 헷갈리는 지점**:
- "Controller가 데이터를 들고 있어도 돼?" → 게임에서는 **OK**. 단, "도메인 규칙(점수 산정 등)" 은 Systems로 빼야 함.
- 판단 기준: **자기 자신의 시각/물리 상태** = Node 안에. **여러 객체에 걸친 규칙** = System으로.

---

## 3. Swift 고유 패턴 — Java에서는 못 봤을 것들

### 3-1. Optional (널 안전성)

```swift
// Java: String name = product.getName();  // null이면 NPE
// Swift:
let name: String? = product.name           // String 또는 nil
guard let unwrapped = name else { return }  // nil이면 조기 탈출
```

**Spring의 `Optional<T>` 와 비슷하지만, 언어 레벨에 박혀있어 강제됨.** `!` 강제 언래핑은 본 프로젝트에서 금지 (`swift-rules.md` §3, §9).

### 3-2. Extension (Java에는 없음)

기존 타입에 메서드 추가 — Spring의 AOP·decorator 비슷한 효과를 정적으로.

```swift
extension UIColor {
    static let ganhoPaper = UIColor(named: "paperWhite") ?? .white
    static let ganhoMint  = UIColor(named: "mintHair")   ?? .cyan
}

// 사용
playerNode.color = .ganhoMint
```

### 3-3. Protocol-oriented programming

Java는 인터페이스 + 구현 클래스. Swift는 **프로토콜에 기본 구현까지 줄 수 있음**.

```swift
protocol Killable {
    var hp: Int { get set }
    func takeDamage(_ amount: Int)
}

extension Killable {
    func takeDamage(_ amount: Int) {  // 기본 구현
        hp = max(0, hp - amount)
    }
}

final class EnemyNode: SKSpriteNode, Killable {
    var hp: Int = 3
    // takeDamage는 기본 구현 사용
}
```

### 3-4. enum with associated values

Java enum은 상수 모음. Swift enum은 **사실상 합타입(sum type)**.

```swift
enum GameEvent {
    case noteCollected(value: Int, onBeat: Bool)
    case shieldUsed
    case playerDied(at: CGPoint)
    case timeExpired(finalScore: Int)
}

// 패턴 매칭
switch event {
case .noteCollected(let value, let onBeat):
    scoreSystem.add(noteValue: value, onBeat: onBeat)
case .shieldUsed:
    audio.play(.shieldBreak)
case .playerDied(let position):
    showGameOver(at: position)
case .timeExpired(let final):
    repository.saveBest(score: final)
}
```

### 3-5. Closure + capture list

Java 람다와 비슷하지만 **메모리 캡처 명시 필수**.

```swift
SKAction.run { [weak self] in    // self를 약하게 캡처 (메모리 누수 방지)
    self?.spawnNote()
}
```

`[weak self]` 안 쓰면 경고 → 본 프로젝트에서 P0 (`evaluation_criteria.md`).

---

## 4. 학습 우선순위 (3주 학습 플랜)

| 주차 | 학습 영역 | clonebose 대조 |
|---|---|---|
| 1주차 | struct vs class, optional, enum | Java DTO vs Swift struct |
| 2주차 | protocol, extension, generics | Java interface + 제네릭 비교 |
| 3주차 | closure, async/await, Result | Spring `@Async`, `CompletableFuture` 비교 |

각 주차마다 **velog 1편 + 카드뉴스 1장** — 학습이 콘텐츠 자산이 되도록.

---

## 5. 한 줄 결론

> **clonebose의 폴더 이름을 그대로 가져왔다. 단, Swift 고유 문법(struct, protocol, extension, optional, closure)은 익숙해질 때까지 한 줄도 양보하지 않는다.**
> 폴더 = 익숙함 / 코드 = 새로움 — 인지 부하의 절반은 이름으로 줄이고, 나머지 절반은 패턴으로 익힌다.
