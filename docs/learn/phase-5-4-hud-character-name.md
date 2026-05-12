# Phase 5-4 — HUD 우상단에 캐릭터 이름 띄우기

## 이번에 만든 것

게임 화면 *우측 위*에 내가 고른 캐릭터 이름(예: "정간호")이 작게 떠 있게 만들었어요. 카드에서 누구를 골랐는지 잊지 않게요.

좌측 위에는 이미 점수(🎵 0), 시간(⏱ 00:45), 콤보(🔥 0) 세 개가 있었어요. 거기에 **오른쪽 위 모서리**에 이름표 하나를 더 붙인 거예요.

```
┌──────────────────────────────────┐
│ 🎵 0                     정간호 │   ← 이름표가 여기 새로 생김
│ ⏱ 00:45                          │
│ 🔥 0                             │
│                                  │
│           [게임 화면]            │
│                                  │
└──────────────────────────────────┘
```

---

## 핵심 4가지 (Spring 비유)

### 1. setter injection — 따로 떨어진 작은 주입구를 만들기

Spring에서 객체에 데이터를 넣는 방법은 여러 가지인데, 그 중 하나가 **setter injection**이에요.

```java
// Spring 스타일
@Service
class HudService {
    private String characterName;

    public void setCharacterName(String name) {   // 주입구 1
        this.characterName = name;
    }

    public void update(int score, int time) {     // 매 프레임 호출 2
        // ...
    }
}
```

**서로 다른 두 가지 책임을 두 함수로 분리**한 거예요:
- `setCharacterName`: *한 번만* 들어오는 데이터 (캐릭터 이름)
- `update`: *매 프레임* 들어오는 데이터 (점수, 시간)

Swift에서도 똑같이 했어요.

```swift
final class HUDNode: SKNode {
    // 매 프레임 호출 — 점수/시간/콤보가 계속 바뀌니까
    func update(score: Int, remainingTime: TimeInterval, combo: Int) { ... }

    // 한 번만 호출 — 캐릭터 이름은 게임 중 안 바뀌니까
    func setCharacterName(_ name: String) {
        nameLabel.text = name
    }
}
```

**왜 합치지 않았을까?** `update`에 `name:` 매개변수를 추가하면 게임이 매 프레임 60번씩 똑같은 이름 문자열을 다시 넣게 돼요. 낭비예요. 또 `update`를 부르는 쪽(GameScene)도 매번 캐릭터 이름을 같이 들고 다녀야 해서 코드가 더러워져요.

Spring에서도 마찬가지 — 의존성 주입은 객체 만들 때 *딱 한 번*, 비즈니스 로직 호출은 *매번 따로*. 둘을 합치지 않는 게 규칙이에요.

---

### 2. application.yml — 숫자는 한 곳에만 적기

Spring 프로젝트 짜본 적 있다면 `application.yml`에 숫자를 적어둔 적 있을 거예요.

```yaml
# application.yml
hud:
  character-name-offset-x: 760    # 이름표가 오른쪽으로 얼마나 떨어져야 하는지
```

```java
// 코드에서는 이름만 부르고 숫자는 안 적음
@Value("${hud.character-name-offset-x}")
private int offsetX;
```

Swift에서도 똑같이 했어요. `GameConfig`라는 곳에 숫자를 다 모아두고, 코드에서는 *이름*만 불러요.

```swift
// GameConfig.swift — 숫자 보관소
enum GameConfig {
    static let hudCharacterNameOffsetX: CGFloat = 760
}

// HUDNode.swift — 숫자 안 적고 이름만 사용
nameLabel.position = CGPoint(x: GameConfig.hudCharacterNameOffsetX, y: 0)
//                                        ^ 760이라는 숫자 직접 안 씀
```

**왜 이러냐면**, 나중에 "어? 너무 오른쪽으로 갔네, 700으로 줄이자" 싶을 때 **딱 한 줄만** 고치면 돼요. 코드 곳곳에 `760`이 흩어져 있으면 grep으로 찾아다녀야 하고, 빠뜨리기도 쉬워요.

이걸 **매직 넘버 금지**라고 불러요. 의미 모를 숫자가 코드에 박혀있는 걸 금지하는 규칙이에요.

---

### 3. Thymeleaf fragment — 라벨 4개를 한 묶음으로 포장

Spring + Thymeleaf로 웹 만들 때, 머리·꼬리·메뉴 같은 *재사용되는 화면 조각*을 `fragment`로 빼놓고 필요한 페이지에서 `include`만 했어요.

```html
<!-- hud.html -->
<div th:fragment="hud">
  <span class="score">점수: 0</span>
  <span class="time">시간: 45</span>
  <span class="combo">콤보: 0</span>
  <span class="name">정간호</span>
</div>
```

```html
<!-- game.html에서 -->
<div th:replace="hud :: hud"></div>   <!-- 한 줄로 끝 -->
```

`HUDNode`도 정확히 똑같은 *재사용 조각*이에요. 점수·시간·콤보·이름 네 개 라벨을 묶어둔 한 덩어리.

```swift
// GameScene에서는 이 한 줄이면 4개 라벨이 한꺼번에 화면에 붙음
cameraNode.addChild(hud)
```

그러고 나서 데이터만 1번 주입해주면 끝.

```swift
cameraNode.addChild(hud)                                  // 라벨 4개 통째로 부착
hud.setCharacterName(characterID.displayName)             // 이름 주입
layoutHUD()                                               // 위치 정리
```

**왜 좋냐면**, 나중에 "HUD에 라벨 하나 더 추가하자" 싶을 때 *HUDNode 안만* 고치면 돼요. 외부(GameScene)는 한 줄도 안 바꿔요. 캡슐화의 힘이에요.

---

### 4. Optional 빈 객체 — 조용히 비어있기

Spring에서 `findById`가 null을 반환하면 NPE(NullPointerException)가 터질 위험이 있어요. 그래서 `Optional<T>`로 감싸서, 호출자가 안전하게 처리하게 만들었어요.

```java
public Optional<User> findById(Long id) { ... }   // null 대신 Optional.empty()
```

이번에 `nameLabel`도 비슷한 방어 코드를 넣었어요. 초기값을 **빈 문자열 `""`**로 줬어요.

```swift
nameLabel = SKLabelNode(text: "")   // 초기값 = 빈 문자열
```

이렇게 하면 `setCharacterName(...)`을 *깜빡 안 부르고 넘어가도* 라벨이 크래시하지 않아요. **그냥 안 보일 뿐**이에요.

- 정상 경로: `setCharacterName("정간호")` 호출 → "정간호" 떠오름
- 실수 경로: 호출 빠뜨림 → 라벨은 빈 칸으로 조용히 있음. 게임은 멀쩡히 돌아감

이걸 **graceful degradation**(점잖게 망가짐)이라고 해요. 한 부분이 실수로 빠져도 전체가 무너지지 않는 코딩 자세예요.

만약 초기값 없이 `var nameLabel: SKLabelNode?` 같은 옵셔널로 만들었다면 코드 곳곳에 `if let nameLabel = nameLabel { ... }` 검사가 필요했을 거예요. 빈 문자열로 시작하면 그런 검사가 한 줄도 필요 없어요. 더 깔끔해요.

---

## 추가로 배운 작은 것 — SKLabelNode 정렬

SKLabelNode(이름표 만드는 클래스)는 텍스트를 어디 기준으로 정렬할지 두 개 모드가 있어요.

```swift
nameLabel.horizontalAlignmentMode = .right   // 가로 정렬: 오른쪽 끝 기준
nameLabel.verticalAlignmentMode = .top       // 세로 정렬: 위쪽 끝 기준
```

이렇게 하면 라벨의 *우상단 모서리*가 `position`에 딱 맞춰져요.

**왜 `.right`로 했냐면**, 캐릭터 이름이 짧기도 하고("이간호"=3글자) 길기도 한데("수간호사"=4글자), `.right` 정렬이면 **오른쪽 끝선이 항상 같은 위치**라서 화면 우측 가장자리에 깔끔하게 붙어요. 만약 `.left`였다면 짧은 이름은 안쪽으로 들어가 보였을 거예요.

기존 점수·시간·콤보 라벨은 화면 *좌측*에 붙어 있어서 `.left` 정렬을 썼어요. 그건 `configure(_:)`라는 공통 스타일 함수에 박혀 있어요. 그래서 이름 라벨은 그 함수를 *부르지 않고* 직접 `.right`로 설정했어요. 공통 함수에 손을 대면 기존 3개 라벨이 흐트러지니까요.

```swift
// 점수/시간/콤보는 공통 함수 호출 → .left/.top
configure(scoreLabel)
configure(timeLabel)
configure(comboLabel)

// 이름은 직접 설정 → .right/.top
nameLabel.horizontalAlignmentMode = .right
nameLabel.verticalAlignmentMode = .top
```

**기존 코드를 안 건드리면서 새 기능을 더하는 게 핵심**이에요. 이걸 **개방-폐쇄 원칙**(OCP, Open-Closed Principle)이라고 해요. 확장에는 열려있고 수정에는 닫혀있어야 한다는 그 규칙.

---

## 정리 — 4가지 핵심 단어

1. **setter injection (setter 주입)** — 한 번만 들어오는 데이터는 별도 함수로
2. **application.yml (설정 분리)** — 숫자는 GameConfig 한 곳에만
3. **fragment (재사용 조각)** — HUDNode가 라벨 4개를 통째로 포장
4. **graceful degradation (점잖게 망가짐)** — 빈 문자열 기본값으로 크래시 방지

이 4가지가 Spring에서 자주 쓰는 패턴이고, 이번 sprint에서 Swift/SpriteKit에 그대로 적용했어요. 언어만 다를 뿐 *생각하는 방식*은 똑같아요. 한 번 익숙해지면 어느 언어로 가도 같은 무기를 쓸 수 있어요.
