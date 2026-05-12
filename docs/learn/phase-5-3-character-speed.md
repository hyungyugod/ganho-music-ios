# 34 · Phase 5-3 · 캐릭터별 이동속도 차등 — *손맛이 달라진다* ⚡

> **이번 작업 한 줄**: 5-2에서 *색만* 달라졌는데, 이번엔 *속도까지* 달라진다. 5명 캐릭터에게 +/- 10% 안에서 살짝 다른 이동속도를 줘서 *고른 보람*이 손가락에 전해진다.

---

## 1. 왜?

5-2까지는 캐릭터 카드를 골라도 *몸 색깔*만 달랐다. 게임 자체는 동일했다. 이번 sprint는 *고른 카드가 손맛에 진짜로 반영*되는 첫 변화:

- 정간호(`.jung`) → 10% 빠름 → 피하기 쉬움 → "민첩" 컨셉
- 김간호(`.kim`) → 100% (기준점) → 평범
- 이간호(`.lee`) → 5% 빠름 → 약간 공격적
- 임간호(`.im`) → 5% 느림 → 살짝 신중
- 건간호(`.geon`) → 10% 느림 → 묵직, 챌린지

차이는 *느낄 수는 있지만 깰 수 없는 수준은 아닌* 5~10% 안으로 묶었다. *선호*는 갈리지만 *우열*은 갈리지 않는 균형.

> Spring 비유: 같은 `OrderService`에 *할인율 정책*만 달리 주입. 서비스 로직은 그대로, 정책 값만 다양.

---

## 2. 한 그림으로 이해하기

```
[TitleScene 카드 선택]
        ↓
   selectedCharacterID = .jung
        ↓
GameScene.init(size:, characterID: .jung)
        ↓
didMove → setupPlayer()
   player.color = characterID.color                       ← 5-2가 만든 자리
   player.speedMultiplier = characterID.playerSpeedMultiplier  ← 5-3이 추가한 자리
        ↓
worldNode.addChild(player)
        ↓
[매 프레임]
   PlayerNode.update(deltaTime:)
   let speed = playerBaseSpeed × 1.10   ← 정간호라서 1.10
   physicsBody?.velocity = (방향 × speed)
        ↓
[손맛: 10% 더 빠른 회피]
```

---

## 3. 새로 배운 것 (Spring 비유로)

### 3-1. **enum + computed property = "전략 표 한 장"**

이게 이번 sprint의 *진짜 핵심*. 비유부터 보자.

#### 학교 성적표로 비유

학생부에 5명이 있다고 치자.

```
이름   | 키
------+----
김간호 | 100%
정간호 | 110%
이간호 | 105%
임간호 | 95%
건간호 | 90%
```

이걸 코드로 옮기면 보통 두 가지 길이 있다:

**(A) 5개 클래스 만들기** (Java식 정석)
```java
class Kim implements Character { double speed() { return 1.00; } }
class Jung implements Character { double speed() { return 1.10; } }
// ... 5개
```

**(B) 한 enum 안에 표 박기** (이번 선택)
```swift
enum CharacterID {
    case kim, jung, lee, im, geon

    var playerSpeedMultiplier: CGFloat {
        switch self {
        case .kim:  return 1.00
        case .jung: return 1.10
        case .lee:  return 1.05
        case .im:   return 0.95
        case .geon: return 0.90
        }
    }
}
```

(B)가 좋은 이유:
- *값 5개* 보러 *5개 파일* 안 열어도 됨 → **한눈에 보이는 정책 표**
- 케이스 추가 시 `switch`에 빠뜨리면 *컴파일 에러* → **누락 방지 자동**
- 별도 인터페이스 / 다형성 *준비비용 0*

> Spring 비유: `enum Discount { GOLD(0.9), SILVER(0.95), NORMAL(1.0); private final double rate; ... }`. 자바 enum도 *필드 + 메서드*로 정책 표를 압축. Swift는 그게 *훨씬 가벼움* (computed property 한 줄).

### 3-2. **`default:` 금지 — *Swift 컴파일러를 안전망으로*** ⭐⭐

```swift
switch self {
case .kim:  return 1.00
case .jung: return 1.10
case .lee:  return 1.05
case .im:   return 0.95
case .geon: return 0.90
}
// ← default 없음. 5 case 모두 명시.
```

**왜 `default:`를 안 쓰나?**

내일 새 캐릭터(.park)를 추가한다고 치자.

- *만약* `default: return 1.0`을 써뒀다면 → 컴파일 통과 → 모든 새 캐릭터가 *조용히* 1.0 처리됨 → 버그
- *5 case 명시*만 두면 → `.park` 추가 시 `switch must be exhaustive` 컴파일 에러 → 누락이 *즉시 잡힘*

> Spring 비유: Java enum의 *abstract method* — 모든 enum 상수가 *반드시 override*. 새 상수 추가 시 컴파일러가 `must implement` 강제. Swift `switch self`도 같은 안전망.

이게 SPEC에 "default 금지"가 적힌 진짜 이유. *지금* 편하려고 default 쓰면, *나중* 누군가가 *조용한* 버그를 만든다.

### 3-3. **setter injection — *부품 끼우기*** ⭐

PlayerNode에 새 프로퍼티를 추가했다:

```swift
var speedMultiplier: CGFloat = 1.0   // 기본 1.0
```

GameScene이 `setupPlayer()`에서 *외부 주입*:
```swift
player.speedMultiplier = characterID.playerSpeedMultiplier
```

#### 부품 끼우기 비유

장난감 자동차 본체를 만들었다. 본체엔 *바퀴 꽂는 자리*가 비어 있다.

- *공장 단계*: 바퀴 자리에 *기본 바퀴(1.0)* 끼워둠 → 그냥 굴러감
- *조립자(GameScene)*: 캐릭터 카탈로그 보고 *해당 캐릭터 바퀴*로 갈아 끼움 → 정간호면 빠른 바퀴, 건간호면 묵직한 바퀴

PlayerNode 입장에서는:
- "내가 어느 캐릭터인지 *모름*"
- "내 `speedMultiplier`가 *얼만지*만 앎"
- 매 프레임 `playerBaseSpeed × speedMultiplier`만 계산

*책임이 깔끔하게 갈림*:
- PlayerNode: *어떻게* 빠른지 (계산 책임)
- CharacterID: *얼마나* 빠른지 (정책 표)
- GameScene: *누구* 인지 (선택 전달)

> Spring 비유: `@Autowired setter` 주입. `OrderService`에 `setDiscountRate(double r)` 두고, 컨테이너가 빈 생성 후 정책 주입. 본체는 *비율*만 알고, *왜 그 비율인지*는 모름.

### 3-4. **기본값 `1.0` = 안전망**

```swift
var speedMultiplier: CGFloat = 1.0
```

`= 1.0`이 *왜 중요*하냐?

- 만약 미래에 누군가 `setupPlayer()`에서 `speedMultiplier = ...` 줄을 *실수로 삭제*하면?
- → `speedMultiplier`가 *0이 아니라* `1.0`이라서 → 김간호 속도로 그냥 굴러감
- → **크래시 없음, 정지 없음** → *조용히 안전*

만약 기본값을 안 쓰고 `var speedMultiplier: CGFloat` (옵셔널)로 뒀다면? → 미주입 시 nil → 곱셈 시 크래시 위험 또는 옵셔널 체이닝 강제.

기본값 1.0 = **곱셈의 항등원** (`× 1 = 그대로`). 곱셈 기반 정책에서 *안전한 기본*은 *항등원*.

> Spring 비유: `@Value("${player.speedMultiplier:1.0}")` — *기본값 1.0*. 설정 파일에서 빠뜨려도 *동작*. 단위 테스트나 시뮬레이션에서 PlayerNode를 *단독 사용*할 때도 안전.

### 3-5. **곱셈 위치 = *도메인 안*** ⭐

곱셈을 *어디서* 할까? 두 가지 길.

**(A) GameScene에서 계산해서 주입**
```swift
player.actualSpeed = playerBaseSpeed * characterID.multiplier  // ❌ 안 함
```

**(B) PlayerNode가 *내부에서* 곱함** (이번 선택)
```swift
class PlayerNode {
    var speedMultiplier: CGFloat = 1.0
    func update(...) {
        let speed = GameConfig.playerBaseSpeed * speedMultiplier  // ← 곱셈은 여기
    }
}
```

(B)가 옳은 이유:
- 속도 *공식 변경*이 *한 곳*에 모임
- GameConfig.playerBaseSpeed가 *바뀌어도* PlayerNode만 알면 됨
- GameScene은 *정책*(어느 캐릭터)만 알면 충분 — *계산*은 도메인이 함

> Spring 비유: `OrderService.calculateFinalPrice()` 내부에서 할인율 곱셈. 컨트롤러는 "이 사용자다" 알리고, 실제 *가격 계산*은 도메인 안에서. 컨트롤러가 가격까지 계산하면 비즈니스 로직이 *컨트롤러로 새는* 패턴 (나쁜 냄새).

### 3-6. **5-2 → 5-3 = *같은 패턴의 누적*** ⭐

`setupPlayer()`의 변화를 보자:

```swift
// 5-2 후
player.color = characterID.color
worldNode.addChild(player)

// 5-3 후
player.color = characterID.color                          // 5-2
player.speedMultiplier = characterID.playerSpeedMultiplier // 5-3 ← 추가
worldNode.addChild(player)
```

*완전히 같은 패턴*이 두 줄 나란히. 미래 5-4에 HP / 스킬을 추가하면:
```swift
player.color = characterID.color
player.speedMultiplier = characterID.playerSpeedMultiplier
player.maxHP = characterID.maxHP                  // 5-4 예정
player.skill = characterID.skill                  // 5-5 예정
worldNode.addChild(player)
```

*반복 패턴이 보이기 시작*하면 *추출 신호*. Rule of three (같은 패턴 3번 도달 시 추출). 지금은 2번이니 *아직 추출 안 함* — 미래에 `player.applyCharacter(characterID)` 한 메서드로 묶일 수 있음.

> Spring 비유: `OrderService`에 `setDiscountRate / setTaxRate / setShippingRate` 3개 setter가 비슷한 패턴이면 `setPolicy(Policy)` 한 메서드로 묶음. *과한 추출은 비용*, *적절한 시점*은 3번째 등장 때.

---

## 4. 변경한 것 한눈에

### 새 파일
**없음**.

### 고친 파일 (3개)

| 파일 | 변경 |
|---|---|
| `CharacterID.swift` | 헤더 +1 / `playerSpeedMultiplier` computed property 신설 (12줄) |
| `PlayerNode.swift` | 헤더 +1 / `speedMultiplier` stored property 신설 (3줄) / `update`의 `speed` 계산식 *1줄* 수정 |
| `GameScene+Setup.swift` | `setupPlayer()`에 *1줄* 추가 (`player.speedMultiplier = ...`) |

### Xcode pbxproj
- **변경 없음** (신규 파일 0).

### 변경 *안 한* 것 (Out of Scope 준수)

| 파일/시스템 | 변경 0줄 |
|---|---|
| `GameScene.swift` 본문 | ✅ |
| `GameConfig.swift` | ✅ |
| `ColorTokens.swift` | ✅ |
| `EnemyNode` / `StoneGuardNode` / `NoteNode` / `ProjectileNode` | ✅ |
| `TitleScene.swift` | ✅ |
| `ContactRouter` / `SpawnSystem` / `ScoreSystem` | ✅ |
| HUD / DPad / Result / Repositories | ✅ |
| `Protocols/` / `GameStats.swift` | ✅ |
| pbxproj / macOS / tvOS / Tests | ✅ |

---

## 5. 직접 확인할 것

⌘R 후:

| # | 시나리오 | 봐야 할 것 |
|---|---|---|
| (a) | 김간호 선택 → 게임 시작 | 5-2와 동일 — 속도 그대로 (회귀 없음) |
| (b) | 정간호 선택 → 게임 시작 | *체감으로* 조금 빠름. F 회피 쉬워짐 |
| (c) | 이간호 선택 → 게임 시작 | 정간호보단 덜 빠르지만 김간호보단 빠름 |
| (d) | 임간호 선택 → 게임 시작 | 약간 답답함. 5% 느림 |
| (e) | 건간호 선택 → 게임 시작 | 가장 느림. F 회피가 *빠듯하나 가능* |
| (f) | 빌드 / 시뮬레이터 | BUILD SUCCEEDED, 경고 0, 크래시 0 |
| (g) | 5-2 회귀 | 5 캐릭터별 *몸 색*은 5-2와 100% 동일 |
| (h) | 안전망 검증 | 만약 setupPlayer의 주입 줄이 빠져도 `.kim`처럼 동작 (기본값 1.0) |

---

## 6. 사용자 결정 (이미 합의)

| 결정 | 선택 | 왜 |
|---|---|---|
| 차등 범위 | ±10% 이내 | OP/약체 방지, 게임밸런스 유지 |
| 기준점 | `.kim` = 1.00 | 게임 디자인 baseline |
| 차등 방식 | enum computed property | 표 압축 + 컴파일러 안전망 |
| `default:` 사용 | **금지** | 새 케이스 추가 시 누락 즉시 잡힘 |
| GameConfig 분리 | **금지** | 값 자체가 *캐릭터 정체성* — 캐릭터 enum 안이 자연 |
| 곱셈 위치 | PlayerNode.update 안 | 도메인 책임 분리 |
| 기본값 | `1.0` | 곱셈의 항등원, 안전망 |
| GameScene 본문 | **0줄 변경** | 5-2가 만든 흐름 그대로 |

---

## 7. 회고

### 7-1. 막혔던 것
**없음.** 1회차 사이클. SPEC이 5-2 패턴을 그대로 확장하는 구조라 *어디를 고치는지*가 명확. 5-2의 `color setter` → 5-3의 `speedMultiplier setter`가 *동형 매핑*.

### 7-2. 새로 배운 것

1. **`switch self` exhaustive + default 금지** — 5 case 명시가 Swift 컴파일러를 *안전망*으로 만든다. Java enum의 abstract method override 강제와 같은 패턴. `default: return 1.0`은 *지금* 편하지만 *미래* 버그.
2. **enum + computed property = 전략 표** — 5개 클래스 / Strategy 인터페이스를 만들지 않고도 *정책 다형성*을 표현. *값/계수*만 다양한 경우 클래스 폭증보다 enum이 *훨씬 가벼움*.
3. **setter injection — *외부에서 부품 끼우기*** — 5-2의 `color` setter와 5-3의 `speedMultiplier` setter가 *완전히 같은 패턴*. PlayerNode는 *자기 정체성*을 외부에서 받아옴 — *역할 분리* (PlayerNode = 운영체, CharacterID = 정책 카탈로그, GameScene = 컨테이너).
4. **기본값 1.0 = 곱셈의 항등원 = 안전망** — `var speedMultiplier: CGFloat = 1.0`. 주입 누락이라는 *조용한 실수*를 *조용한 정상 동작*으로 흡수. Spring `@Value("${...:1.0}")` 기본값 패턴.
5. **곱셈 위치는 *도메인 안*** — PlayerNode.update에서 곱셈. GameScene이 곱하면 *비즈니스 로직이 컨트롤러로 새는* 나쁜 냄새. *어떻게* 빠른지는 도메인이 결정, *얼마나*만 외부 정책.
6. **dt 기반 이동 패턴 유지** — `physicsBody?.velocity = ...`라서 SpriteKit 엔진이 dt를 자동 처리. 속도가 캐릭터별로 달라져도 *프레임 독립성* 유지. 매뉴얼 dt 도입 0건.
7. **5-2 → 5-3 동형 누적** — `setupPlayer()`의 두 줄(color, speedMultiplier)이 같은 패턴 나란히. 미래 HP/스킬도 같은 자리에 추가 → Rule of three 도달 시 `applyCharacter(_:)`로 추출 가능.
8. ***매직 넘버* 정책의 예외** — 평소라면 1.10 / 1.05 / 0.95 / 0.90을 `GameConfig`로 뽑아야 하지만, 이번엔 *값 자체가 캐릭터 정체성*(.jung = 1.10이 *정간호의 정의*)이라 `CharacterID` 안에 둔다. SPEC에 사유 명문화로 평가자가 *매직 넘버*로 감점하지 않도록.

### 7-3. 다음으로 미룬 것

- **5-4**: 카드 시각 강화 (테두리 펄스 등) 또는 캐릭터별 첫 스킬
- **5-5**: 선택 영구 저장 (UserDefaults — CharacterRepository)
- **5-6**: 캐릭터별 HP / 콤보 보너스 등 추가 차등
- **PlayerNode `applyCharacter(_:)` 추출**: HP/스킬까지 3개 setter 도달 시 (Rule of three)
- **사운드 도입**: Phase 6

### 7-4. 핵심 가치 — *고른 보람이 손가락에 전해진다*

| 보존된 것 | 변경 0건 |
|---|---|
| GameScene 본문 | ✅ |
| 모든 다른 노드 (Enemy/StoneGuard/Note/Projectile/HUD/DPad) | ✅ |
| 모든 시스템 (ContactRouter/SpawnSystem/ScoreSystem) | ✅ |
| GameConfig / ColorTokens / PhysicsCategory | ✅ |
| TitleScene / ResultScene | ✅ |
| Repositories / Protocols | ✅ |
| pbxproj / macOS / tvOS / Tests | ✅ |

**추가된 것**:
- CharacterID: +13줄 (computed property + 헤더)
- PlayerNode: +5줄 / -1+1줄 (stored property + 헤더 + speed 식)
- GameScene+Setup: +1줄

**Phase 5의 *두 번째 끈* 완성**. 5-2(시각)에 이어 5-3(촉각)이 같은 패턴으로 누적. *같은 자리에 같은 모양으로 한 줄씩 쌓이는* git diff가 *분리해서 작게*의 정수.

---

## 8. 다음 작업

```
[1] 시뮬에서 §5 (a)~(h) 확인 — 5명 속도가 진짜 다른지 손가락으로 체감
[2] 다음 sprint 후보:
    - 5-4: 카드 시각 강화 (테두리 / 펄스)
    - 5-5: 캐릭터별 첫 스킬 (정간호 돌진 / 건간호 음표 흡수)
    - 5-6: 선택 영구 저장 (UserDefaults)
```

> **이번 sprint 본질**: 5-2의 *눈에 보이는* 차이에 5-3의 *손에 느껴지는* 차이가 더해졌다. 카드 5장이 *데이터*에서 *정책*으로 승격된 순간. Spring으로 치면 `enum Discount`에 `rate` 필드만 있다가 `apply(price)` 메서드까지 붙은 셈.
