# 17 · Phase 2-11 · 충돌 처리 분리 — ContactRouter 🚦

> **이번 작업 한 줄**: GameScene에 있던 *충돌 처리 3개 함수*(`didBegin` / `handleProjectileContact` / `handleNoteContact`)를 별도 파일(`ContactRouter.swift`)로 옮긴다. **기능은 똑같고**, 코드 정리만.

---

## 1. 왜 또 정리?

저번(2-10) 정리로 GameScene 446줄 → 354줄. 더 줄여야 *깔끔*. 다음 분리 후보는 **충돌 처리**.

```
GameScene.swift (354줄, 현재)
├─ 게임 루프 / 셋업 함수들
├─ 충돌 처리 3 함수 (didBegin, handleProjectileContact, handleNoteContact)  ← 이번 분리 대상
├─ endGame
└─ ...
```

**비유**: 식당에서 *주문 받기 + 요리 + 서빙 + 계산*을 한 사람이 다 하던 걸, *주문 직원*만 따로 두는 느낌. 충돌이 일어나면 "어디로 보낼지"는 *주문 직원(ContactRouter)*이 결정.

---

## 2. 콜백(Callback)이란?

이번 sprint의 핵심 패턴.

> **"무슨 일 생기면 *이걸* 호출해줘"** 라고 미리 약속해 둔 함수.

### 2-1. 일상 비유
온라인 쇼핑:
- 주문할 때: "배송 시작되면 *문자 보내줘*" (콜백 등록)
- 배송 시작: 시스템이 *문자 함수*를 호출 (콜백 실행)

게임에서:
- GameScene이 ContactRouter에게: "수간호사랑 닿으면 *endGame() 호출해줘*" (콜백 등록)
- 충돌 발생: ContactRouter가 *endGame 콜백*을 실행 (콜백 실행)

### 2-2. 코드로 보면
```swift
// ContactRouter 안
var onEnemyHit: () -> Void = {}    // 빈 콜백 (기본값)

// 충돌 났을 때
onEnemyHit()    // 등록된 함수 호출

// GameScene에서 콜백 등록
contactRouter.onEnemyHit = { [weak self] in
    self?.endGame()
}
```

### 2-3. 왜 콜백을 쓰나?
**ContactRouter가 GameScene을 *직접 모르게*** 만들기 위해.

- 직접 호출: ContactRouter가 GameScene을 알아야 함 → *결합 ↑*
- 콜백 호출: ContactRouter는 *함수 모양*만 알면 됨 → *결합 ↓*

ContactRouter는 게임이 어떻게 끝나는지(endGame 내부)는 *전혀 몰라도* 됨. *호출만* 함.

**Spring 비유**: `EventListener` 패턴. 이벤트 발행자가 누가 듣는지 모르고 *이벤트만* 발행. 듣는 쪽이 *콜백*으로 처리.

---

## 3. 무엇을 옮기나?

GameScene에서 ContactRouter로 이전:

| 함수 | 역할 |
|---|---|
| `didBegin` | 충돌 발생 시 SpriteKit이 호출. 분기 |
| `handleProjectileContact` | F가 player 또는 벽과 충돌 시 처리 |
| `handleNoteContact` | 음표 수집 처리 (콤보/점수) |

GameScene에는 **콜백 등록 코드만** 남음.

---

## 4. 새로 배운 것

### 4-1. **`SKPhysicsContactDelegate` 위임 이전**
> 충돌 알림을 *누가 받을 것이냐*가 핵심.

이전:
```swift
class GameScene: SKScene, SKPhysicsContactDelegate { ... }
physicsWorld.contactDelegate = self    // GameScene이 받음
```

이후:
```swift
class GameScene: SKScene { ... }    // delegate 채택 안 함
final class ContactRouter: NSObject, SKPhysicsContactDelegate { ... }
physicsWorld.contactDelegate = contactRouter    // ContactRouter가 받음
```

**왜 NSObject 상속?** `SKPhysicsContactDelegate`는 *Objective-C 프로토콜*. Swift 클래스가 채택하려면 *NSObject 상속*이 필요. (역사적 이유)

### 4-2. **콜백을 변수로 저장**
```swift
final class ContactRouter: NSObject, SKPhysicsContactDelegate {
    var onEnemyHit: () -> Void = {}
    var onProjectileHitPlayer: () -> Void = {}
    var onProjectileHitWall: (SKNode) -> Void = { _ in }
    var onNoteCollected: (SKNode) -> Void = { _ in }
    // ...
}
```

- `() -> Void`: 인자 없고 반환 없는 함수
- `(SKNode) -> Void`: SKNode 1개 받고 반환 없는 함수
- 기본값 `{}` 또는 `{ _ in }`: 빈 함수. 콜백 등록 안 됐어도 *크래시 안 남*

### 4-3. **`[weak self]` — 콜백 안에서**
```swift
contactRouter.onEnemyHit = { [weak self] in
    self?.endGame()
}
```

콜백이 GameScene을 *강하게* 잡으면 메모리 누수. `[weak self]`로 약한 참조.

### 4-4. **콤보/점수 로직은 그대로 GameScene에**
이번 sprint는 *충돌 분기*만 분리. **콤보/점수는 다음 sprint(ScoreSystem)**에서.

콜백 안에서 GameScene의 콤보/점수 멤버 직접 갱신:
```swift
contactRouter.onNoteCollected = { [weak self] note in
    guard let self = self else { return }
    // 콤보/점수 갱신 (기존 로직 그대로)
    self.combo = ...
    self.score += ...
    note.run(.removeFromParent())
}
```

이렇게 *책임을 한 번에 다 옮기지 않고* 점진 — 안전.

---

## 5. 새로 만든 것

### 새 파일
- `Systems/ContactRouter.swift` — `final class ContactRouter: NSObject, SKPhysicsContactDelegate`. 콜백 4개 + didBegin / handleProjectileContact / handleNoteContact

### 고친 파일
- `GameScene.swift`:
  - `: SKPhysicsContactDelegate` 채택 제거
  - 충돌 처리 3 함수 *제거*
  - `private let contactRouter = ContactRouter()` 멤버 추가
  - didMove에서 콜백 등록 + `physicsWorld.contactDelegate = contactRouter`

### Xcode pbxproj
- ContactRouter.swift 등록

---

## 6. 직접 확인할 것

⌘R 후 — *2-10과 똑같이 동작*해야 함:

| # | 봐야 할 것 |
|---|---|
| (a) | 음표 수집 시 점수/콤보 정상 |
| (b) | 수간호사와 닿으면 게임 종료 |
| (c) | F 맞으면 게임 종료 |
| (d) | F가 벽 닿으면 소멸 |
| (e) | 음표 spawn / F 발사 / 카메라 follow 모두 그대로 |
| (f) | 게임 종료 시 모든 액션 정지 |

**기능 변화 0**.

---

## 7. 사용자 결정 (모두 추천대로)

| 결정 | 선택 | 왜 |
|---|---|---|
| 분리 단위 | ContactRouter 1개 | 충돌 분기만 묶음 |
| 콜백 패턴 | 변수에 함수 저장 | 결합도 ↓ |
| 콤보/점수 로직 | GameScene에 *그대로* | 다음 sprint(ScoreSystem)에서 분리 |
| NSObject 상속 | 필수 (Obj-C 프로토콜 채택) | Swift 한계 |

---

## 8. 회고

### 8-1. 막혔던 것
**없음.** 만점 10/10. 콤보 로직 라인별 동등성까지 검증 완료.

### 8-2. 새로 배운 것
1. **콜백 변수 패턴** — 함수를 변수에 저장. 매번 다른 동작 등록 가능.
2. **NSObject 상속의 이유** — Obj-C 프로토콜(SKPhysicsContactDelegate) 채택 시 필수.
3. **delegate 위임 이전** — physicsWorld.contactDelegate를 GameScene → ContactRouter로 변경. SpriteKit이 *어떤 객체*든 didBegin만 호출.
4. **점진 분리** — 한 sprint에 *모든 책임*을 분리하지 않음. 콤보 로직은 다음 sprint(ScoreSystem).
5. **`{ _ in }` 빈 함수** — 인자 받지만 무시하는 기본값. 콜백 등록 안 됐을 때 크래시 방지.

### 8-3. 다음으로 미룬 것
- **Phase 2-12 — ScoreSystem 분리** (다음 sprint).

### 8-4. 평가 점수
- **가중평균: 10.0 / 10 — 합격** (시리즈 만점 추가)

---

## 9. 다음 작업

```
[1] 시뮬레이터에서 §6 (a)~(f) 확인
[2] 다음 sprint: ScoreSystem 분리 (Phase 2-12)
```

> **이번 sprint 본질**: *충돌 분기*를 외부로. 콤보 같은 *상태 로직*은 다음 sprint에서. 점진 분리 = 안전.
