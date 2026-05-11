# 33 · Phase 5-2 · 선택 캐릭터 색이 게임에 반영 — *드디어 보인다* 🎨

> **이번 작업 한 줄**: 5-1에서 *고를 수 있는 카드*만 만들었는데, 지금은 선택한 결과가 *실제 게임에 반영*되는 첫 sprint — 게임 시작 시 PlayerNode 색이 *선택한 캐릭터 색*으로 바뀐다.

---

## 1. 왜?

5-1에서 5 카드를 골랐지만 *결과는 무시*됐다(`PlayerNode.color = .ganhoMint` 고정). 본 sprint는 그 *전달과 적용*을 추가:
- TitleScene → GameScene 전환 시 `selectedCharacterID` *전달*
- GameScene이 받아 *PlayerNode 색*에 즉시 반영

게임 로직 변경은 *시각 한 줄*만. 스킬·외형·게임밸런스는 5-3 이후.

> Spring 비유: 컨트롤러가 *선택 정보를 서비스 init에 주입*. 컴포넌트 한 곳에서만 색이 바뀜.

---

## 2. Spring 비유 ⭐

| SpriteKit | Spring | 한 줄 설명 |
|---|---|---|
| `init(size: CGSize, characterID: CharacterID)` | `public X(Y y, Z z) {}` | *Constructor injection* — 객체 생성 시 의존성 주입 |
| `newGameScene(characterID: = .kim)` | `@Value("${...:kim}")` default | *기본값* 있는 매개변수 |
| `let characterID` (immutable) | `private final CharacterID id` | *한 번 정해지면 안 바뀜* |
| `player.color = characterID.color` | DI 후 *즉시 사용* | 받은 값을 한 곳에 반영 |

**핵심**: *주입*은 *호출자가 결정한 값*을 *수신자가 받는 패턴*. 5-1에서는 GameScene이 *전혀 몰랐고*, 5-2에서는 *처음으로* 호출자(TitleScene) 의도를 안다.

---

## 3. 새로 배운 것 (Swift) ⭐

### 3-1. **Swift Init 주입 — `init(size:characterID:)`**

```swift
class GameScene: SKScene {
    let characterID: CharacterID
    
    init(size: CGSize, characterID: CharacterID) {
        self.characterID = characterID
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
```

- `let characterID` — *immutable*. init 후 변경 불가
- `init` 본문에 `self.characterID = characterID` *먼저*, 그 다음 `super.init` (Swift 규칙: stored property 먼저)
- `required init?(coder:)`는 SKScene 표준 — `.sks` 파일 로드 시 호출되지만 본 게임은 미사용 → `fatalError`

> Spring 비유: `@Autowired public GameScene(CharacterID id)`. Swift는 *직접* 호출되는 init이라 *컨테이너* 없이 자체 주입.

### 3-2. **Default Parameter `= .kim` — 호환성**

```swift
class func newGameScene(characterID: CharacterID = .kim) -> GameScene {
    let scene = GameScene(size: CGSize(...), characterID: characterID)
    ...
}
```

- `= .kim` — 기본값 명시
- *호출자가 인자를 주지 않으면* `.kim` 자동 사용
- ResultScene → TitleScene → 다음 게임 시 *예전 호출 코드*가 *그대로 컴파일됨*

> Spring 비유: `@Value("${character.id:kim}")`. 미지정 시 기본값. 점진적 마이그레이션 가능.

### 3-3. **`SKSpriteNode.color` setter — 캡슐화 트레이드오프**

```swift
// GameScene+Setup.swift
func setupPlayer() {
    player.position = ...
    player.color = characterID.color   // ← 5-2 신규 1줄
    worldNode.addChild(player)
}
```

선택 옵션:
- (A) `player.color = ...` 직접 set — *외부에서 접근*, 캡슐화 약간 양보
- (B) `player.setCharacter(_:)` 메서드 추가 — 캡슐화 강화, PlayerNode 변경

본 sprint는 **(A)** 선택 — *작은 변경 우선*. 미래 *스킬*까지 들어가면 (B)로 *승격* 가능 (Rule of three 도달 시).

> Spring 비유: DTO 필드를 *직접 set*하느냐 *setter 메서드*를 거치느냐. 단순 색 변경은 직접 set이 자연.

### 3-4. **`SKSpriteNode.color` 변경 = 자동 재드로*** 

```swift
let player = SKSpriteNode(color: .ganhoMint, size: ...)
player.color = .ganhoBloodAccent  // ← 즉시 빨강으로
```

`color`는 SpriteKit 표준 property — *setter 호출 즉시 화면 반영*. 별도 `setNeedsDisplay()` 같은 호출 불필요.

> 비유: SwiftUI `@State` 변경 시 *자동 view 갱신*. SpriteKit도 *물리/시각이 자동*.

### 3-5. **GameScene 호출 측 변경 *최소화***

이번 변경:
- GameScene: init 추가 + `let characterID` 프로퍼티
- newGameScene factory: 인자 추가 (default)
- TitleScene: `newGameScene(characterID: selectedCharacterID)` 호출
- GameScene+Setup.setupPlayer: 1줄 추가

*그 외 모든 파일 0줄*. PlayerNode/EnemyNode/모든 노드/모든 시스템 변경 0. *분리해서 작게* 정책 유지.

---

## 4. 무엇을 만드나?

### 새 파일
**없음**.

### 고치는 파일 (3개)
| 파일 | 변경 |
|---|---|
| `GameScene.swift` | 헤더 1 + `let characterID: CharacterID` 프로퍼티 + `init(size:characterID:)` + `required init?(coder:)` + newGameScene 시그니처 확장 (default `= .kim`) |
| `GameScene+Setup.swift` | `setupPlayer()` 본문에 `player.color = characterID.color` 1줄 |
| `Scenes/TitleScene.swift` | `touchesBegan`의 `GameScene.newGameScene()` 호출에 `characterID: selectedCharacterID` 인자 추가 |

### Xcode pbxproj
- **변경 없음** — 신규 파일 0건.

### 한 그림으로

```
[TitleScene 카드 선택]
        ↓
   selectedCharacterID = .lee  (이간호)
        ↓
[화면 외 영역 탭]
        ↓
GameScene.newGameScene(characterID: .lee)
        ↓
GameScene.init(size:, characterID: .lee)
   self.characterID = .lee
        ↓
didMove → setupPlayer()
   player.color = .ganhoBloodAccent  ← 이간호 색
        ↓
[게임 화면에 *빨간* 김간호(이간호) 등장]
```

---

## 5. 직접 확인할 것

⌘R 후:

| # | 시나리오 | 봐야 할 것 |
|---|---|---|
| (a) | 게임 첫 진입 (기본 kim 선택) | 5-1과 동일 — PlayerNode 색 `.ganhoPaper` (가운 흰색) |
| (b) | 이간호 카드 탭 → 화면 외 영역 탭 | GameScene 진입 시 PlayerNode가 *빨강* `.ganhoBloodAccent` |
| (c) | 정간호 카드 탭 → 시작 | PlayerNode 민트 `.ganhoMint` |
| (d) | 임간호 카드 탭 → 시작 | PlayerNode 노랑 `.ganhoYellowF` |
| (e) | 건간호 카드 탭 → 시작 | PlayerNode 분홍 `.ganhoPinkNote` |
| (f) | 게임 종료 → 재시작 | TitleScene 복귀 → kim 다시 기본 (영구 저장 X) |
| (g) | AIRFORCE 이스터에그 | 정상 동작 (캐릭터와 무관) |

> **핵심**: 시뮬레이터에서 *눈에 보이는 첫 변화*. 5-1까지는 코드 골격만, 5-2부터 *결과가 화면에*.

---

## 6. 사용자 결정 (이미 합의)

| 결정 | 선택 | 왜 |
|---|---|---|
| 본 sprint 범위 | 전달 + PlayerNode 색 적용 | "한 단계"의 시뮬 가시적 결과 보장 |
| 색 변경 방식 | `player.color = ...` 직접 set | 작은 변경 우선. PlayerNode 0줄 변경 |
| init 패턴 | `init(size:characterID:)` 확장 | Constructor injection 표준 |
| 기본값 | `.kim` (default) | 호환성 유지 |
| 영구 저장 | **X** | 매 진입 kim 리셋. UserDefaults는 별도 sprint |
| 스킬·외형 (가운 등) | **금지** | 5-3 이후 |
| `let` vs `var` | `let` (immutable) | 한 판 안에서 변경 없음 |

---

## 7. 회고

### 7-1. 막혔던 것

**없음.** 한 사이클 합격(가중 9.7/10). P0/P1/P2 0건. 가중 9.5/9.5/10/10 — Swift 패턴/게임 로직에서 *0.5씩 미세 감점*은 명시되지 않음(P 등급 0건). 합격 기준 6.0 충분 통과.

### 7-2. 새로 배운 것

1. **Swift init 본문 순서 — *stored property → super.init*** — `self.characterID = characterID` 먼저, `super.init(size: size)` 다음. Swift Phase 1 init 규칙. Java/Kotlin에서는 `super()`가 먼저지만 Swift는 *반대*. 컴파일러가 엄격히 강제.
2. **`required init?(coder:)` 의무화** — override init이나 designated init을 새로 추가하면 NSCoding 표준 init도 *반드시* 정의. SKScene은 `.sks` 파일 로드 가능성이 있으므로 `fatalError("init(coder:) has not been implemented")`로 둠.
3. **Default parameter `= .kim`** — `newGameScene(characterID: CharacterID = .kim)`. 호출자가 인자를 깜빡해도 컴파일 통과. macOS/tvOS GameViewController가 *기존 코드 그대로* `newGameScene()` 호출 — *호환성 자동 유지*.
4. **`let` immutable property** — 한 판 안에서 캐릭터 변경 불가. Java `private final` 대응. *불변*이 안전성을 보장하는 패턴.
5. **SKSpriteNode `color` setter 즉시 재드로우** — `player.color = X` 한 줄로 끝. 별도 `setNeedsDisplay()` 같은 호출 없음. SwiftUI `@State` 변경 자동 view 갱신과 직관 동일.
6. **Constructor injection (Spring → Swift)** — `init(size:characterID:)`는 Spring `public X(Y y)` 생성자 주입의 Swift 대응. *컨테이너* 없이 *직접* 호출되는 차이만.
7. **캡슐화 트레이드오프** — `player.color = ...` 직접 set vs `player.setCharacter(_:)` 메서드. *작은 변경 우선* 결정. Rule of three 도달 전까지 단순 set이 *복사가 추상화보다 싸다*.
8. **시뮬레이터에서 *눈에 보이는 첫 변화*** — 9 sprint 동안 코드 구조만 정돈했는데, 5-2에서 *사용자가 색을 골라 게임에 반영*되는 결과를 *육안* 확인 가능. 학습 동기 유지에 중요.

> Spring 비유: 두 sprint(5-1, 5-2)에 걸쳐 *DTO → Controller → Service → View*까지 데이터가 흐르는 첫 패스. 5-1은 *DTO와 Controller 준비*, 5-2는 *Service와 View 연결*.

### 7-3. 다음으로 미룬 것

- **5-3**: 카드 시각 강화 (테두리 / 펄스)
- **5-4**: 선택 영구 저장 (UserDefaults — CharacterRepository)
- **5-5**: 첫 스킬 도입 (정간호 돌진 또는 건간호 음표 흡수)
- **PlayerNode 메서드 추출**: `setCharacter(_:)` (Rule of three 도달 시)
- **EnemyNode 상태 enum 승격**: 세 번째 모드 등장 시
- **사운드** Phase 6

### 7-4. 평가 점수

- **가중평균: 9.7 / 10 — 합격** ✅
- 항목별: Swift 9.5 / 게임 로직 9.5 / 성능·안정성 10 / 기능 완성도 10
- P0/P1/P2 0건
- 빌드: BUILD SUCCEEDED, 경고 0건
- diff: 3 파일 (GameScene ~10줄 / GameScene+Setup +1 / TitleScene +1/-1)

### 7-5. 핵심 가치 — *눈에 보이는 첫 결과 + 호환성 자동 유지*

| 보존된 것 | 변경 0건 |
|---|---|
| PlayerNode 본문 (`color`는 SKSpriteNode 표준) | ✅ |
| CharacterID enum (5-1 그대로) | ✅ |
| 모든 다른 노드 (Enemy/StoneGuard/Note/Projectile/HUD/DPad/Airplane/AirforceOverlay/BombFlash/CharacterCard) | ✅ |
| ColorTokens / PhysicsCategory / GameConfig | ✅ |
| Protocols/SelfDismissingNode (4-R) | ✅ |
| Systems (ContactRouter/SpawnSystem/ScoreSystem) | ✅ |
| Repositories | ✅ |
| ResultScene | ✅ |
| GameScene의 didMove/update/endGame/configureContactRouter/triggerAirforceEasterEgg | ✅ |
| TitleScene의 카드 setup/layout/hit test/select 메서드 | ✅ |
| GameScene+Setup의 다른 setup 메서드 | ✅ |
| pbxproj / macOS / tvOS Sources phase | ✅ |

**추가된 것**:
- GameScene: 헤더 1 + 프로퍼티 1 + init 4 + required init 3 + factory 시그니처 (~10줄)
- GameScene+Setup: +1 (player.color)
- TitleScene: +1/-1 (호출 변경)

**Phase 5의 *첫 끈* 완성**. 5-1(UI 골격) → 5-2(결과 반영)로 *분리해서 작게*의 의도가 *완벽한 가시적 결과*로 연결. macOS/tvOS GameViewController가 *코드 0줄 변경*으로도 호환 — Swift default parameter의 *호환성 보장* 패턴 입증.

---

## 8. 다음 작업

```
[1] 시뮬에서 §5 (a)~(g) 확인 — 5명 색이 PlayerNode에 적용되는지
[2] 다음 sprint 후보:
    - 5-3: 카드 시각 강화 (테두리 / 펄스)
    - 5-4: 선택 영구 저장 (UserDefaults — CharacterRepository)
    - 5-5: 첫 스킬 도입 (정간호 돌진 또는 건간호 음표 흡수)
```

> **이번 sprint 본질**: 5-1의 *UI 골격*에 *실제 효과*가 연결되는 첫 매듭. Spring `@Autowired` constructor injection 같은 *주입 패턴*이 SpriteKit init에 자연스럽게 옮겨짐.
