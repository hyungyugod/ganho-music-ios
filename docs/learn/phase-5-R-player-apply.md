# Phase 5-R — PlayerNode.apply(_:) 단일 진입점 리팩터

## 한 줄로 요약

"같은 일을 시키는 두 줄을 한 줄로 묶었다." 코드 동작은 0% 바뀌었고, 코드 모양만 더 깔끔해졌다.

## 무슨 일이 있었나

직전(5-2, 5-3)에 우리는 PlayerNode에게 두 가지를 외부에서 직접 시켰다.

```swift
// Before (5-3 종결)
player.color = characterID.color                       // 5-2에서 추가
player.speedMultiplier = characterID.playerSpeedMultiplier   // 5-3에서 추가
```

5-R에서는 이 두 줄을 PlayerNode 자신의 메서드 안으로 옮겼다.

```swift
// After (5-R)
player.apply(characterID)   // 한 줄
```

그리고 PlayerNode 안에 새 메서드를 만들었다.

```swift
func apply(_ characterID: CharacterID) {
    color = characterID.color
    speedMultiplier = characterID.playerSpeedMultiplier
}
```

**중요**: 두 setter 자체는 그대로 살아있다. 위치만 PlayerNode 내부로 이사했을 뿐. 그래서 게임 동작이 1%도 안 바뀐다.

## 왜 이렇게 했나 — 4가지 학습 포인트

### 1. Tell-Don't-Ask (시키지 말고 말하라)

식당에 가서 김치찌개를 시키는 두 방법을 생각해보자.

- **나쁜 방법 (Ask)**: 주방에 들어가서 "냄비에 김치 넣어주세요. 그리고 돼지고기도 넣어주세요. 마지막에 두부도 넣어주세요." (직접 지시 3개)
- **좋은 방법 (Tell)**: "김치찌개 한 그릇이요!" (한 마디로 위임)

손님은 김치찌개를 어떻게 만드는지 알 필요가 없다. 주방의 일이다.

- **Before**: GameScene이 PlayerNode의 부엌에 들어가서 직접 색을 칠하고 속도도 직접 바꿨다.
- **After**: GameScene은 "너 이 캐릭터야"라고 말만 한다. PlayerNode가 알아서 자기 색과 속도를 바꾼다.

### 2. Facade 메서드 (간판 메서드)

Spring에서 자주 보는 패턴이다.

```java
// Before — Controller가 Service의 내부 setter를 직접 호출
userService.setRole(role);
userService.setQuota(quota);

// After — Service가 facade 메서드 하나를 노출, Controller는 위임만
userService.applyProfile(profile);   // 안에서 setRole + setQuota
```

`apply(_:)`은 PlayerNode의 facade 메서드다. "안에서 어떤 일이 벌어지는지"는 PlayerNode만 알면 된다. 외부는 간판만 보고 호출.

### 3. OCP (Open/Closed Principle, 열림-닫힘 원칙)

"확장에는 열려있고, 수정에는 닫혀있다."

- **확장에 열림**: 5-5에서 만약 캐릭터별로 새 setter(예: `attackPower`)가 추가된다고 가정하자. `apply(_:)` 본문 안에 줄 하나만 더 추가하면 끝.
  ```swift
  func apply(_ characterID: CharacterID) {
      color = characterID.color
      speedMultiplier = characterID.playerSpeedMultiplier
      attackPower = characterID.attackPower   // 새 줄 추가
  }
  ```
- **수정에 닫힘**: GameScene+Setup의 `setupPlayer()`는 한 글자도 바꿀 필요가 없다. `player.apply(characterID)` 그대로.

Spring으로 비유하면: 새 컬럼이 DB에 추가되어도 Controller 코드는 안 바꾸고 Service 안의 `applyProfile`만 확장하는 것과 같다.

### 4. 정보 은닉 (Information Hiding)

PlayerNode가 어떤 내부 속성들을 가지고 있는지, 그것들이 캐릭터별로 어떻게 달라지는지 — 이건 **PlayerNode만의 비밀**이어야 한다.

- **Before**: GameScene은 PlayerNode가 `color`라는 속성과 `speedMultiplier`라는 속성을 둘 다 가지고 있다는 사실을 알아야 했다. (지식 누설)
- **After**: GameScene은 "PlayerNode에 apply라는 메서드가 있구나" 이거 하나만 알면 된다. 내부 속성 목록은 PlayerNode가 알아서 관리.

Spring으로 비유하면: Controller가 Entity의 `@Column` 필드 이름을 일일이 알 필요 없고, `entity.update(dto)` 한 줄로 끝내는 패턴.

## Phase 4-R과의 연결고리

기억나는가? 4-R에서 우리는 자가 소멸 패턴(self-dismiss)을 `SelfDismissingNode` 프로토콜로 추출했다.

| Phase | 추출 대상 | 추출 결과 |
|---|---|---|
| 4-R | 3개 노드의 공통 *자가 소멸* | `SelfDismissingNode` 프로토콜 |
| 5-R | 2개 setter의 공통 *캐릭터 적용* | `apply(_:)` 메서드 |

둘 다 **"기능은 그대로, 구조만 정돈"**이라는 동일한 DNA. 리팩터의 핵심은 "동작은 안 바뀌고, 코드는 더 좋아진다"이다.

## Swift 문법 한 가지 — 외부 레이블 `_`

```swift
func apply(_ characterID: CharacterID) {
    //     ^ 이 언더스코어가 핵심
}
```

Swift는 함수 인자에 두 가지 이름을 줄 수 있다.

```swift
func greet(to person: String) { ... }
greet(to: "Alice")   // 호출 시 "to:" 레이블 필수
```

`_`를 외부 레이블에 쓰면 **호출 시 레이블 생략**이 된다.

```swift
func apply(_ characterID: CharacterID) { ... }
player.apply(characterID)   // "_:" 안 쓰고 바로 값 전달
```

왜 이렇게 했나? `player.apply(characterID:)` 같은 표기는 어색하다. `player.apply(characterID)` 쪽이 자연스러운 영어 문장("apply this character")에 가깝다. Swift 표준 라이브러리도 `Array.append(_:)` 같은 패턴을 쓴다.

## 무엇을 배웠나

1. **리팩터는 "두려운 게 아니라 자주 해야 하는 일"** — 동작이 안 바뀐다는 보장만 있으면 코드 구조 정돈은 항상 옳다.
2. **위임이 직접 조작보다 낫다** — "너의 X를 바꿔, Y도 바꿔" 보다 "너 이거 적용해"가 더 적은 결합도.
3. **메서드 하나로 미래의 확장 비용을 줄인다** — 5-5에서 setter가 늘어나도 호출 측은 0줄 수정.
4. **OCP는 결과가 아니라 도구다** — `apply(_:)` 같은 facade를 미리 만들어두면, 나중에 OCP를 "자연스럽게" 충족한다.

## 다음에 만날 패턴

- **5-5+**: 캐릭터별 스킬이 추가되면 `apply` 본문에 줄이 늘어날 것. 그래도 호출 측은 그대로.
- **언젠가의 Builder 패턴**: 인자가 더 늘어나면 `CharacterIdentity` 같은 DTO를 만들어서 `apply(identity)`로 받게 될 수도 있다. 하지만 그건 그때 가서 결정.

리팩터는 작게, 자주, 안전하게.
