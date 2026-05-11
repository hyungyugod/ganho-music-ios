# 31 · Phase 4-R · 자가 소멸 노드 protocol 추출 — *Rule of three 도달* 🪞

> **이번 작업 한 줄**: 4-3 비행기 / 4-4 오버레이 / 4-5 폭탄 세 노드가 모두 *SKAction.sequence 마지막 단계 = removeFromParent*. 세 번 반복된 패턴을 `protocol SelfDismissingNode`로 추출 — *기능 변화 0, 의도만 코드로*.

---

## 1. 왜?

3 노드(AirplaneNode / AirforceOverlayNode / BombFlashNode)가 모두 *같은 패턴*:
- 외부 메서드 호출 시 자기 SKAction.sequence 자동 시작
- sequence 마지막 단계가 *removeFromParent*
- 호출자는 인스턴스 생성·부착만, 정리는 자가

**Rule of three**: 같은 패턴이 *세 번* 반복되면 *추출* 신호. 두 번까지는 *복사가 추상화보다 싸지만*, 세 번부터는 *추상화가 명시*가 됨.

> Spring 비유: 같은 fire-and-forget 패턴이 *세 서비스*에 등장 → `interface FireAndForgetService` 추출. *행위는 다르되 *역할*은 같다*.

---

## 2. Spring 비유 ⭐

| SpriteKit | Spring | 한 줄 설명 |
|---|---|---|
| `protocol SelfDismissingNode` | `interface FireAndForget` | *역할*을 코드로 |
| Marker protocol (메서드 0개) | Marker interface `Serializable` | *분류*용 — 메서드는 없지만 *카테고리*를 명시 |
| `final class AirplaneNode: SKSpriteNode, SelfDismissingNode` | `class X extends Y implements Z` | 클래스 1 + 프로토콜 다수 |
| `protocol P: SKNode` | `interface P<T extends SKNode>` | 채택 대상 *제약* (Swift 5 class-constrained protocol) |

**핵심**: 본 sprint는 *행동을 통일하지 않는다*. 각 노드는 *자기 메서드(crossScreen/showAndDismiss/flash)를 그대로 유지*. protocol은 *오직 분류*. 미래에 *공통 동작*이 필요해질 때 protocol extension으로 확장 가능.

---

## 3. 새로 배운 것 (Swift) ⭐

### 3-1. **`protocol` 키워드 — Swift의 interface**

```swift
protocol SelfDismissingNode: SKNode {}
```

Swift `protocol`:
- Java `interface`와 *역할*은 같음
- 메서드 시그니처, 프로퍼티 요구사항 정의 가능
- *기본 구현*(extension) 제공 가능 — Swift 고유
- 본 sprint는 *마커*(메서드 0개)

> Spring 비유: `@Service` 클래스가 `@FunctionalInterface Runnable` 구현. Swift는 *protocol*이 같은 자리.

### 3-2. **Class-constrained Protocol — `protocol P: SKNode`**

```swift
protocol SelfDismissingNode: SKNode {}
```

`: SKNode`의 의미:
- *SKNode 또는 그 자손 클래스만이* 이 protocol을 채택 가능
- struct, enum, 다른 protocol 채택 *불가*
- 컴파일러가 강제 — 컴파일 타임 안전

비교: `protocol P: AnyObject`는 *클래스만* (특정 클래스 무관). `protocol P: SKNode`는 *SKNode 후손만*.

> Spring 비유: `interface MyBean<T extends ApplicationContext>`. 채택 대상 *제약*을 컴파일러가 검증.

### 3-3. **Marker Protocol — 메서드 0개의 의미**

```swift
protocol SelfDismissingNode: SKNode {}  // ← 본문 {} 비어 있음
```

**왜 비어 있나?**
- 3 노드의 *시작 메서드 시그니처가 다름*:
  - AirplaneNode: `crossScreen(sceneWidth:atY:)`
  - AirforceOverlayNode: `showAndDismiss()`
  - BombFlashNode: `flash(sceneSize:)`
- 통일하면 *호출 측 변경 필요* — OoS 위반
- 통일 *불필요* — 호출자는 각 노드 *특정* 메서드를 부름

**그럼 무슨 가치?**
- *문서화* — "이 노드는 자가 소멸한다"를 *코드 자체*에 명시
- *분류* — 미래에 `as? SelfDismissingNode`로 *모든 자가 소멸 노드*를 식별 가능
- *공통 확장 자리* — 미래에 `extension SelfDismissingNode { ... }`로 *기본 동작*을 추가할 수 있는 *컨테이너*

> Spring 비유: Java `Serializable`. 메서드 0개지만 *런타임 분류*. 마커가 *프레임워크 약속*을 표현.

### 3-4. **Class + Protocol 다중 채택**

```swift
final class AirplaneNode: SKSpriteNode, SelfDismissingNode {
    // 본문 그대로 (변경 0)
}
```

Swift 채택 규칙:
- *상속 클래스는 1개만* (SKSpriteNode)
- *protocol은 여러 개 가능* (콤마로 나열)
- 클래스가 *반드시 먼저*, protocol은 *뒤*

> Java: `class X extends Y implements A, B, C`. Swift는 `class X: Y, A, B, C` — *상속/채택 구분 없이 콤마*. 컴파일러가 *첫 번째*를 상속으로 해석.

### 3-5. **Rule of three — 추출 시점**

| 등장 횟수 | 권장 행동 |
|---|---|
| 1 | *복사*. 추상화는 너무 일러 (사용 사례 부족) |
| 2 | *복사*. 패턴 인식만, 추출은 여전히 일러 (변형 가능성) |
| 3 | **추출**. 패턴이 *안정화*됨. 미래 4번째에도 *재사용 가능* |

본 sprint:
- 1번째: AirplaneNode (4-3)
- 2번째: AirforceOverlayNode (4-4) — 패턴 인식
- 3번째: BombFlashNode (4-5) — **추출 신호**
- 4번째: ?? (미래) — 추출 protocol 재사용 가능

> "Rule of three"는 *Martin Fowler 리팩터링*에서 온 휴리스틱. 너무 빠른 추상화는 *반례에 깨지기 쉬움*, 너무 늦은 추상화는 *복사 누적*.

### 3-6. **순수 리팩터 sprint — 기능 변화 0**

본 sprint = **purely refactor**. Phase 2-10/2-11/2-12와 같은 *순수 리팩터* 시리즈.

검증 기준:
- *코드 의미*는 같음
- *빌드 결과*는 동일
- *런타임 행동*은 동일
- *호출 측*은 한 줄도 안 건드림

이런 sprint는 *기능 추가가 아닌 의도 표현*이 가치. *동작*은 안 바꾸지만 *코드가 무엇을 의미하는지*가 더 분명해짐.

> Spring 비유: 큰 클래스를 여러 작은 클래스로 쪼개는 PR — *기능 같음, 의도 명료*. 코드 리뷰에서 *변화의 의도*가 잘 보임.

### 3-7. **`Protocols/` 디렉터리 — 새 구조**

```
GanhoMusic Shared/
├── Config/        ← 상수
├── Errors/        ← 에러 enum
├── Managers/      ← 싱글톤
├── Models/        ← 값 객체
├── Nodes/         ← 시각 객체
├── Protocols/     ← *본 sprint 신설* ← interface 자리
├── Repositories/  ← 외부 데이터
├── Scenes/        ← 화면
└── Systems/       ← 도메인 로직
```

`Protocols/`는 *interface 자리*. Spring `interfaces/`처럼 *역할 정의*. 모든 protocol을 한 곳에 모아 *프로젝트의 *역할 지도*를 명확*.

> Spring 비유: `interfaces/` 또는 `contracts/` 디렉터리. 클래스보다 *역할 정의*가 더 안정적.

---

## 4. 무엇을 만드나?

### 새 파일 (1개)
| 파일 | 역할 |
|---|---|
| `Protocols/SelfDismissingNode.swift` | Marker protocol 정의 + 문서 코멘트 |

### 새 디렉터리 (1개)
- `Protocols/` 신설 (현재 디렉터리 9개 → 10개)

### 고치는 파일 (3개 + pbxproj)
| 파일 | 변경 |
|---|---|
| `Nodes/AirplaneNode.swift` | 클래스 선언 줄: `: SKSpriteNode` → `: SKSpriteNode, SelfDismissingNode` (1글자 + protocol 명) |
| `Nodes/AirforceOverlayNode.swift` | 클래스 선언 줄: `: SKNode` → `: SKNode, SelfDismissingNode` |
| `Nodes/BombFlashNode.swift` | 클래스 선언 줄: `: SKSpriteNode` → `: SKSpriteNode, SelfDismissingNode` |
| pbxproj | SelfDismissingNode.swift 4곳 등록 (식별자 0021). Protocols 그룹도 신설 |

### Xcode 그룹
- 새 PBXGroup `Protocols` 신설 (Nodes 그룹과 동일 패턴)

### 한 그림으로

```
[Before — 4-7까지]

  AirplaneNode    : SKSpriteNode    {  ...crossScreen(...)    }
  AirforceOverlay : SKNode          {  ...showAndDismiss()    }
  BombFlashNode   : SKSpriteNode    {  ...flash(...)          }

  (세 노드가 *같은 패턴*인데 *공통 분류 없음*)

[After — 4-R]

  protocol SelfDismissingNode: SKNode {}

  AirplaneNode    : SKSpriteNode, SelfDismissingNode  {  ...crossScreen(...)    }
  AirforceOverlay : SKNode,        SelfDismissingNode  {  ...showAndDismiss()    }
  BombFlashNode   : SKSpriteNode, SelfDismissingNode  {  ...flash(...)          }

  (이제 세 노드가 *같은 카테고리* — 코드가 *역할*을 명시)
```

### Out of Scope

- protocol에 메서드 정의 (marker로 유지)
- protocol extension 추가 (기본 구현)
- 3 노드의 *시작 메서드 통일* (호출 측 변경 필요해짐)
- 3 노드 *본문* 변경 (선언 라인만 1글자)
- GameScene 변경 (호출 측 0줄)
- 다른 노드(Player/Enemy/Stone 등) 변경
- 기능 동작 변경

---

## 5. 직접 확인할 것

⌘R 후:

| # | 시나리오 | 봐야 할 것 |
|---|---|---|
| (a) | 게임 시작 | 4-7과 동일 — 기능 변화 0 |
| (b) | Player가 석조무사 첫 통과 | AIRFORCE 이스터에그 5단계 모두 정상 (비행기/오버레이/폭탄/도주/F 재스폰) |
| (c) | 한 판 종료 → 결과 화면 | 4-7과 동일 |
| (d) | 빌드 | BUILD SUCCEEDED, 경고 0건 |

> **핵심**: 사용자 입장에서 *변화 0*. 모든 변화는 *코드 의도*에서만.

---

## 6. 사용자 결정 (이미 합의)

| 결정 | 선택 | 왜 |
|---|---|---|
| 본 sprint 범위 | marker protocol 추출만 | 메서드 통일은 호출 측 변경 필요 — 별도 sprint |
| protocol 위치 | `Protocols/` 새 디렉터리 | Spring `interfaces/` 패턴 답습. 미래 protocol 늘면 모이는 자리 |
| protocol 제약 | `: SKNode` (class-constrained) | struct/enum 채택 차단 — *SKNode 후손만* |
| 채택 노드 | Airplane / AirforceOverlay / BombFlash 3개 | Rule of three 도달한 세 노드 |
| 시작 메서드 통일 | **금지** (각자 유지) | 매개변수가 다름. 통일은 호출 측 변경 필요 |
| 본문 변경 | **금지** (선언 라인만 1글자) | 순수 리팩터 — 기능 변화 0 |
| GameScene 변경 | **금지** | 호출 측 0줄 |
| 새 디렉터리 | Protocols/ 신설 | 프로젝트 구조 진화 |

---

## 7. 회고

### 7-1. 막혔던 것

**없음.** 한 사이클 만점 합격(10.0/10). 순수 리팩터의 핵심인 *기능 변화 0* 검증 완벽 통과.

### 7-2. 새로 배운 것

1. **Swift `protocol` 키워드 첫 도입** — Java `interface`와 *역할 같음*. 메서드 시그니처와 *기본 구현*(extension) 정의 가능. 본 sprint는 마커.
2. **Class-constrained protocol `: SKNode`** — *SKNode 또는 그 자손 클래스만* 채택 가능. struct/enum 차단. 컴파일러 강제. Swift 5의 *protocol-typed inheritance*.
3. **Marker protocol — 메서드 0개의 의미** — Java `Serializable`처럼 *분류용*. 호출자가 *런타임 카테고리 식별* 또는 *미래 protocol extension 자리*로 사용.
4. **다중 채택 문법** — `final class X: SuperClass, ProtoA, ProtoB`. 클래스 1개 상속 + protocol 다수. 콤마+공백 1개 정확.
5. **Rule of three 추출 시점** — Martin Fowler. 1회는 복사, 2회도 복사(변형 가능성), 3회부터 추출. 본 sprint는 정확히 3번째 도달.
6. **`Protocols/` 새 디렉터리** — 프로젝트 구조 진화. Spring `interfaces/` 답습. 미래 protocol이 늘면 모이는 자리.
7. **순수 리팩터 sprint의 가치** — *기능 변화 0*이지만 *코드 의도*가 명료해짐. PR 리뷰에서 *변화의 의도*가 잘 보임.
8. **콤마+공백 1개 패치의 *임팩트*** — 3 줄(파일당 1줄, 총 3줄) 변경으로 *코드의 *역할 지도*가 완성*. 리팩터의 효율 ↑.

> Spring 비유: `class X extends Y implements Serializable`을 처음 도입한 순간. *실행 동작*은 동일하지만 *코드의 *역할 표현*이 더 풍부*해짐.

### 7-3. 다음으로 미룬 것

- **`protocol SelfDismissingNode` extension** — 공통 동작(예: 페이드아웃 헬퍼)이 *3번째 노드에 등장*하면 추출 (Rule of three 재적용).
- **EnemyNode 상태 머신 enum 승격** — 현재 Bool isFleeing. *세 번째 모드*(stunned/poisoned 등) 등장 시.
- **Phase 5: 캐릭터 선택 + 능동 스킬** — GDD §1, 다음 페이즈.
- **Phase 4-Z: 이교주 NPC** — 난이도 시스템 도입 후.
- **사운드 효과** — Phase 6.

### 7-4. 평가 점수

- **가중평균: 10.0 / 10 — 만점 합격** 🎉
- 항목별: Swift 패턴 10 / 게임 로직 10 / 성능·안정성 10 / 기능 완성도 10
- P0/P1/P2 0건
- 빌드: BUILD SUCCEEDED, 경고 0건
- diff: 신설 1파일(18줄) + 수정 3 노드 각 1줄 + pbxproj 5곳

### 7-5. 핵심 가치 — *기능 변화 0, 의도 명료 +1*

**기능 변화 0 보장**:
- 3 노드 *본문* 한 줄도 변경 안 함 (선언 줄에 콤마+protocol명만 추가)
- GameScene / GameScene+Setup / 다른 노드 / 시스템 / 씬 / Config / ColorTokens / 모두 0줄
- 빌드 SUCCEEDED + 경고 0 + 게임플레이 4-7과 *완전 동일*

**의도 명료 +1**:
- 3 노드가 *같은 카테고리*임을 protocol로 명시
- 미래 4번째 자가 소멸 노드 등장 시 *즉시 분류 가능*
- 미래 *공통 동작*(예: 페이드 헬퍼, 자가 검증 메타) 추가 *자리 마련*
- *Protocols/* 디렉터리 신설 — 프로젝트가 *역할 정의*를 따로 모으는 단계로 진화

**6 + 1 sprint 누적 정리**:
- Phase 4 = 4-1(StoneGuard) + 4-2~4-7(AIRFORCE) + 4-R(이번 리팩터)
- 자가 소멸 노드 *패턴 인식 → 추출 → 분류*까지 한 묶음
- Phase 4 *명실상부 종결*. 다음은 Phase 5(캐릭터 선택) 또는 별도 진로.

> Spring 비유: 한 도메인 기능(이스터에그) 6 PR 출시 후 *마지막 정돈 PR* — 클래스들을 인터페이스로 묶음. *역할 지도* 완성으로 Phase 5의 새 기능이 *기존 구조 안에서* 자연스럽게 자리 잡을 준비 완료.

---

## 8. 다음 작업

```
[1] 빌드 SUCCEEDED 확인 (기능 변화 0)
[2] 다음 sprint 후보:
    - Phase 5-1: 캐릭터 선택 골격 (TitleScene + 5 캐릭터, GDD §1)
    - Phase 4-Z: 이교주 NPC (난이도 시스템 도입 후)
    - 별도 리팩터: EnemyNode 상태 머신 enum 승격 (현재 Bool, 미래 3+ 모드)
```

> **이번 sprint 본질**: 6 sprint 누적 패턴(자가 소멸 노드)을 *코드 안에서 명시*. 마커 protocol은 *지금은 비어있지만 *언제든 확장 가능*한 구조. Phase 4 종결 후 Phase 5로의 자연 진입 직전 코드 정돈.
