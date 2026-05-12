# Phase 5-5 — 카드 선택할 때 살짝 커지게 만들기

## 이번에 만든 것

타이틀 화면 아래쪽에 캐릭터 카드 5장이 있어요. 지금까지는 누른 카드만 **또렷하게**(alpha 1.0) 보이고, 안 누른 카드는 **흐릿하게**(alpha 0.5) 보였어요.

여기에 한 가지 효과를 더 얹었어요. 누른 카드 한 장만 **1.08배 크기로 살짝 부풀어 오르게** 한 거예요. 그것도 *즉시* 변하는 게 아니라 **0.10초 동안 부드럽게** 커져요.

```
누르기 전:                       탭한 순간 (0.10초 동안):
┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐         ┌──┐ ┌──┐ ╔══╗ ┌──┐ ┌──┐
│김 │ │박 │ │정 │ │수 │ │우 │   →   │김 │ │박 │ ║정║ │수 │ │우 │
└──┘ └──┘ └──┘ └──┘ └──┘         └──┘ └──┘ ╚══╝ └──┘ └──┘
 ↑                                            ↑
 김간호 = 또렷 + 1.08배                       정간호 = 또렷 + 1.08배 (부드럽게 부풀어 오름)
                                              김간호 = 흐릿 + 1.0배 (부드럽게 줄어듦)
```

탭하자마자 색깔(alpha)은 즉시 또렷해지지만 모양(scale)은 0.10초에 걸쳐 부풀어 올라요. 두 변화가 동시에 *즉시* 일어나는 것보다 **부드럽고 살아있는 느낌**이 나요.

---

## 핵심 4가지 (Spring 비유)

### 1. `xScale` / `yScale`는 빈(@Component)에 달린 상태 필드

`CharacterCardNode`는 Spring의 `@Component` 빈 하나라고 생각하면 돼요. 그 빈에는 *상태 필드*가 여러 개 달려 있어요.

```java
// Spring 비유
@Component
class CharacterCardNode {
    private float xScale = 1.0f;   // 가로 배율 (기본 1.0)
    private float yScale = 1.0f;   // 세로 배율 (기본 1.0)
    private float alpha  = 1.0f;   // 투명도   (기본 1.0)

    public void setScale(float s) {
        this.xScale = s;
        this.yScale = s;
    }
}
```

SpriteKit의 `SKNode`도 이거랑 똑같아요. `xScale`, `yScale`, `alpha`는 노드의 **현재 상태**예요. `setScale(1.08)`을 부르면 *그 빈의 두 필드*가 1.08로 바뀌고, 화면이 다음 프레임을 그릴 때 1.08배 크기로 그려져요.

그리고 자식 노드(배경 사각형 + 이름 라벨)는 부모의 scale을 **자동으로 따라가요**. 부모가 1.08배면 자식도 1.08배. 이건 Spring에서 부모 빈이 자식 빈에 ApplicationContext를 *주입*해주는 것처럼, SpriteKit은 부모의 `xScale`을 *자식 그리기 단계에서 자동 적용*해줘요.

---

### 2. `SKAction.scale(to:duration:)`는 @Async 메서드

상태를 *즉시* 바꾸는 것과 *시간을 두고 천천히* 바꾸는 건 완전히 달라요.

```java
// (A) 즉시 — Spring의 일반 setter
card.setScale(1.08f);   // 한 프레임 안에 끝남, "딱!" 하고 바뀜

// (B) 천천히 — Spring의 @Async 메서드
@Async
public CompletableFuture<Void> scaleTo(float target, long durationMs) {
    // 백그라운드 스레드에서 시간을 두고 단계적으로 변화
}
card.scaleTo(1.08f, 100);   // 호출은 즉시 끝나지만 0.10초 동안 부드럽게 보간
```

SpriteKit의 `SKAction.scale(to:duration:)`이 바로 **(B)**예요. 이 코드를 보세요:

```swift
run(
    SKAction.scale(to: targetScale, duration: GameConfig.characterCardScaleDuration),
    withKey: "cardScale"
)
```

`run(_:)`은 호출하자마자 *즉시 리턴*해요. 진짜 변환 작업은 SpriteKit의 **액션 큐**에서 다음 프레임부터 0.10초에 걸쳐 일어나요. Spring `@Async`가 작업을 백그라운드 스레드 풀에 넘기고 메인 스레드는 바로 다음 라인으로 가는 것과 똑같아요.

그래서 `setSelected(true)` 함수 자체는 한 줄도 기다리지 않고 끝나요. 0.10초의 부드러운 보간은 SpriteKit 엔진이 알아서 처리해요.

---

### 3. `removeAction(forKey:)` + `run(_:withKey:)` = @Scheduled 키 취소-재등록

여기서 *위험한 상황* 하나가 있어요. 사용자가 같은 카드를 빠르게 3번 연타하면 어떻게 될까요?

```
탭 1: setSelected(true) 호출 → 액션 A (1.0 → 1.08, 0.10s) 등록
탭 2 (0.03초 후): 또 setSelected(true) → 액션 B 등록
탭 3 (0.06초 후): 또 setSelected(true) → 액션 C 등록
```

키 관리 없이 그냥 `run(action)`만 부르면, 액션 A와 B와 C가 **모두 살아남아** 동시에 실행돼요. 그러면 scale 값이 어디로 갈지 알 수 없게 흔들려요.

Spring에서 같은 작업이 있어요. `@Scheduled` 작업을 *이름으로 등록*하고, 같은 이름으로 새로 등록할 때 이전 것을 *취소*하는 패턴이에요.

```java
// Spring 비유
class TaskRegistry {
    private Map<String, ScheduledFuture<?>> tasks = new HashMap<>();

    public void register(String key, Runnable task, long delay) {
        // 1단계: 같은 키의 기존 작업 취소
        ScheduledFuture<?> old = tasks.get(key);
        if (old != null) old.cancel(false);

        // 2단계: 새 작업 등록
        ScheduledFuture<?> newTask = scheduler.schedule(task, delay, MS);
        tasks.put(key, newTask);
    }
}
```

SpriteKit이 이걸 그대로 줘요:

```swift
removeAction(forKey: "cardScale")   // 1단계: 같은 키의 기존 액션 취소
run(action, withKey: "cardScale")   // 2단계: 새 액션 등록 (같은 키로)
```

"cardScale"이라는 이름표가 붙은 액션은 **항상 단 1개만** 살아 있게 돼요. 3번 연타해도 마지막 한 번만 실제로 실행되니까, scale 값이 깔끔하게 1.08에 안착해요.

---

### 4. 빈 상태 필드 4 포인트 — alpha는 즉시, scale은 천천히

이번 코드의 핵심 결정 하나. **두 상태를 다른 방식으로 변경**했어요.

```swift
func setSelected(_ selected: Bool) {
    alpha = selected ? 1.0 : GameConfig.characterCardDeselectedAlpha   // ① 즉시
    let targetScale: CGFloat = selected ? GameConfig.characterCardSelectedScale : 1.0
    removeAction(forKey: "cardScale")
    run(
        SKAction.scale(to: targetScale, duration: GameConfig.characterCardScaleDuration),
        withKey: "cardScale"                                            // ② 천천히
    )
}
```

①번 줄(`alpha = ...`)은 일반 setter — **즉시** 변경. ②번 줄(`SKAction.scale`)은 비동기 액션 — **0.10초** 보간.

왜 다르게 했냐면, **둘 다 즉시**면 너무 차갑고 딱딱한 느낌이고, **둘 다 천천히**면 응답이 늦은 느낌이 나요. 한 쪽(색)은 즉시 또렷해져서 "내 탭이 먹혔다"는 응답성을 주고, 다른 쪽(모양)은 천천히 부풀어 올라서 "살아 있다"는 느낌을 줘요.

Spring 빈에 비유하면, 같은 빈의 두 필드를 **다른 트랜잭션 전략**으로 업데이트하는 거예요:

| 필드 | 변경 방식 | Spring 비유 |
|---|---|---|
| `alpha` | 직접 set | 일반 `@Transactional` (즉시 커밋) |
| `xScale`/`yScale` | SKAction 보간 | `@Async` + 점진적 업데이트 |

**4 포인트 정리**:
1. `xScale`/`yScale`/`alpha`는 노드의 **상태 필드** (Spring 빈의 인스턴스 변수).
2. 자식 노드는 부모의 scale을 **자동으로 따라간다** (부모 변환 상속).
3. `SKAction.scale(to:duration:)`은 **@Async 비동기 보간**, `run(_:)`은 즉시 리턴.
4. 같은 키 이름의 액션은 **항상 1개만 살아남게** 관리해야 한다 (`removeAction(forKey:)` → `run(_:withKey:)`).

---

## 매직 넘버 면제 — 1.0은 그냥 둠

`GameConfig`에 상수를 추가할 때 **선택된 쪽 scale(1.08)**만 상수로 만들고, **비선택 쪽 scale(1.0)**은 그냥 리터럴로 뒀어요.

```swift
let targetScale: CGFloat = selected ? GameConfig.characterCardSelectedScale : 1.0
                                                                              ^^^
                                                                              상수 없이 그냥 1.0
```

규칙은 "매직 넘버 금지"지만, **0, 1, -1 같은 자명한 값은 면제**예요. `1.0`은 SpriteKit 노드의 *기본 scale*이고 의미가 자명해요. 반면 `0.5`(흐림)는 *왜 0.5인지* 자명하지 않아서 `characterCardDeselectedAlpha` 상수가 필요했고, `1.08`도 *왜 1.08인지* 자명하지 않아서 `characterCardSelectedScale` 상수가 필요해요.

Spring에서도 비슷해요. 모든 숫자를 `application.yml`에 넣지는 않고, `if (count > 0)` 같은 자명한 비교는 0을 직접 쓰는 거랑 똑같아요.

---

## 정리

| 항목 | 5-1까지 | 5-5 후 |
|---|---|---|
| 선택 카드 alpha | 1.0 | 1.0 (변화 없음) |
| 비선택 카드 alpha | 0.5 | 0.5 (변화 없음) |
| 선택 카드 scale | 1.0 | **1.08 (0.10s 보간)** ← 신규 |
| 비선택 카드 scale | 1.0 | 1.0 (변화 없음) |
| 변경된 메서드 | — | `setSelected(_:)` 본문 4줄 추가 |
| 추가된 상수 | — | `characterCardSelectedScale`, `characterCardScaleDuration` 2개 |

**한 줄 요약**: 카드 선택할 때 알파(즉시)와 scale(0.10초 부드럽게)을 다른 방식으로 같이 변경 — Spring `@Async` + 키 기반 작업 취소 패턴.
