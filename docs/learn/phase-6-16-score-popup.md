# Phase 6-16 학습 노트 — +1 / +2 점수 플로팅 텍스트

## 오늘 만든 것

음표를 먹을 때, 음표가 사라진 그 자리에 작은 글씨가 떠올랐다가 위로 스르륵 올라가면서 사라져요.

- 평범하게 먹으면: 흰색 **+1**
- 콤보 3개 이상에서 먹으면: 황금색 **+2**

이렇게 색깔만으로 *"아! 콤보 쌓이면 점수가 2배가 되네!"* 하고 자연스럽게 알게 되는 거예요. 누가 "콤보 3부터 2배입니다" 라고 설명 안 해도 황금색 +2 보면 그냥 알게 돼요.

## 자가 소멸 노드 9호 — 패턴 답습의 끝판

지금까지 만든 자가 소멸 노드 8형제가 있어요:

| 번호 | 이름 | 무슨 일을 하나 |
|---|---|---|
| 1호 | AirplaneNode | 비행기 날아가기 |
| 2호 | AirforceOverlayNode | 화면 가득 차는 폭격 효과 |
| 3호 | BombFlashNode | 폭탄 터지는 섬광 |
| 4호 | HitFlashNode | 피격당하면 화면 빨갛게 |
| 5호 | SparkleEffectNode | 음표 먹을 때 반짝이 8방향 |
| 6호 | ComboPopupNode | "COMBO 5!" 같은 마일스톤 텍스트 |
| 7호 | ComboBreakNode | 콤보 끊겼을 때 "BREAK" |
| 8호 | CountdownNode | 게임 시작 전 "3, 2, 1, GO!" |
| **9호** | **ScorePopupNode** | **오늘 만든 +1 / +2 텍스트** |

### 자가 소멸 노드란?

> "스스로 태어나서 잠깐 보이다가 스스로 사라지는 노드"

코드에서 누가 `removeFromParent()` 호출 안 해줘도, 자기가 만들어진 순간에 *0.6초 후에 알아서 사라지는 액션*을 자기 자신에게 걸어놓고 시작해요. 그래서 호출한 쪽 코드가 깔끔해져요.

**Spring 비유** — `@Async` + `@Scheduled(fixedDelay)` 같은 거예요. 호출하는 메서드는 그냥 *"띄워!"* 한 줄만 부르고 잊어버리면, 뒤에서 알아서 자기 인생 살다가 죽는 거.

```swift
ScorePopupNode.spawn(at: 위치, gainedPoints: 점수, parent: 부모)
// 끝. 이후 누가 정리 안 해도 0.6초 후 자동 소멸
```

## 정적 팩토리 + private init 패턴

이번에 처음으로 적용한 *진화*가 있어요. 다른 8호제는 외부에서 `init()` 직접 부르고 → `addChild` 따로 부르고 → `animate()` 따로 부르는 식이었는데, 이번엔 한 줄에 다 묶었어요.

```swift
// 외부에서 보는 입구는 딱 하나
static func spawn(at position: CGPoint, gainedPoints: Int, parent: SKNode) {
    let node = ScorePopupNode(gainedPoints: gainedPoints)  // private init
    node.position = ...
    parent.addChild(node)
    node.animate()                                          // private animate
}

private init(gainedPoints: Int) { ... }                     // 외부 직접 호출 금지
private func animate() { ... }                               // 외부 직접 호출 금지
```

**왜 이렇게?**
- 외부가 *"위치 안 줬어!"* 같은 실수를 못 하게 막아요. spawn 한 길로만 들어와야 하니까.
- 호출하는 쪽 코드도 1줄로 끝나서 깔끔해요.

**Spring 비유** — Builder 패턴 + private 생성자. 외부에서 `new User()`를 못 하고 `User.builder().name(...).build()`만 쓰게 만드는 거랑 똑같아요. *입구를 좁히면 실수가 줄어든다*.

## SKAction.group vs SKAction.sequence

이번에 *3개의 애니메이션을 동시에* 실행했어요:
1. 위로 올라가기 (moveBy +40)
2. 점점 투명해지기 (fadeOut)
3. 점점 커지기 (scale 0.8 → 1.0)

이걸 *같이* 돌려야 자연스러워요. 위로 올라가는 게 끝난 다음 사라지면 어색하니까.

```swift
let group = SKAction.group([moveUp, fadeOut, scaleUp])  // 동시 진행
let cleanup = SKAction.removeFromParent()
run(.sequence([group, cleanup]))                         // 순서: group 끝나면 cleanup
```

| SKAction | 의미 |
|---|---|
| `group` | 안의 액션들을 *동시에* 실행 (가장 긴 거 끝날 때까지 기다림) |
| `sequence` | 안의 액션들을 *순서대로* 실행 |

**Spring 비유** — `CompletableFuture.allOf(...)` 가 group이고, `CompletableFuture.thenCompose(...)` 가 sequence예요. 또는 단순히 *병렬 vs 순차*.

## 매직 넘버 0개 정책

새로 추가한 숫자 7개를 전부 `GameConfig.swift`에 등록했어요.

```swift
// MARK: - Score Popup (Phase 6-16)
static let scorePopupFontSize: CGFloat = 28
static let scorePopupStartOffsetY: CGFloat = 12
static let scorePopupFlyUpDistance: CGFloat = 40
static let scorePopupDuration: TimeInterval = 0.6
static let scorePopupStartScale: CGFloat = 0.8
static let scorePopupEndScale: CGFloat = 1.0
static let scorePopupZPosition: CGFloat = 50
```

**왜?** 나중에 *"+2 글씨가 너무 작아!"* 싶을 때 GameConfig 한 군데만 고치면 돼요. 코드 사방을 뒤지지 않아도 되는 거예요.

**Spring 비유** — `application.yml`에 외부 설정 빼놓는 거. *기준값은 한 곳에서만 산다*.

## "회귀 0" 자연 차단 — Phase 6-15에서 배운 것

지난번에 NEW BEST! 폴리싱 만들 때 `isNewBest` 분기 *진입 자체*를 막아서 회귀 0을 자연스럽게 만들었어요. 이번에도 똑같이:

- ScorePopupNode 스폰은 **"음표 먹는 순간"** 단 한 군데에서만 일어나요
- 다른 경로 (F 피격, 적 접촉, 시간 끝남, 콤보 끊김 등) 어디서도 호출 안 됨
- 만약 음표를 안 먹으면? → 자동으로 노드 0개 생성 → 화면 변화 0 → 회귀 위험 0

**Spring 비유** — `@Transactional`이 *해당 메서드 진입했을 때만* 트랜잭션을 시작하는 것과 비슷해요. *입구를 좁히면 출구도 좁아진다*.

## 부모 노드 선택 — worldNode vs cameraNode

게임 화면에는 두 종류 좌표계가 있어요:

| 부모 | 누가 자식? | 카메라 따라가나? |
|---|---|---|
| `worldNode` | 플레이어, 음표, 적, 맵 타일 | YES — 같이 따라감 |
| `cameraNode` | HUD, 카운트다운, 콤보 마일스톤 | NO — 화면에 고정 |

**ScorePopupNode는 어디 붙여야 할까?**

→ **worldNode**. 왜냐하면 *"음표가 사라진 그 자리"* 에서 떠야 하니까. 만약 cameraNode에 붙이면 *화면 중앙 부근* 어딘가에 떠버려서 의미가 망가져요.

이건 sparkle(반짝이)이 이미 worldNode 자식이었던 패턴 그대로 따라간 거예요.

**Spring 비유** — `@SessionScope` vs `@RequestScope` 같은 거. *어디에 속하느냐*가 *어떻게 보이느냐*를 결정해요.

## ScoreSystem 시그니처 미접촉 — "옵션 B 폴링"

여기서 한 고민이 있었어요:

> 음표를 먹을 때 +1을 줄지 +2를 줄지 어떻게 알지?

가장 직관적인 방법은 `ScoreSystem.recordNoteHit()`가 *가산된 점수*를 return 하게 바꾸는 거예요. 근데 그러면:
- ScoreSystem.swift 수정 → 회귀 영역 침범
- 기존 호출부도 같이 바꿔야 함
- "회귀 0" 목표 깨짐

그래서 **옵션 B 폴링**을 채택했어요:

```swift
self.scoreSystem.recordNoteHit(at: now)              // 점수 가산 (Void return)
let gainedPoints = self.scoreSystem.combo >= GameConfig.comboBonusThreshold
    ? GameConfig.scorePerNoteCombo                   // 콤보 3+ → +2
    : GameConfig.scorePerNote                        // 그 외 → +1
```

`recordNoteHit` 호출 *후*에 `combo` 값이 이미 갱신되어 있으니까, 호출하는 쪽에서 *같은 조건식*을 한 번 더 평가해도 *같은 답*이 나와요. ScoreSystem은 한 줄도 안 바꾸고도 결과를 얻은 거예요.

**Spring 비유** — DTO에 빠진 필드를 *서비스 메서드 시그니처 바꾸지 말고*, 같은 트랜잭션에서 한 번 더 조회하는 거랑 비슷. *기존 인터페이스를 안 깨면서 새 정보 얻기*.

## 색 의미 매핑 — graceful fallback

색깔을 정할 때 *switch* 를 썼는데, default 케이스를 둬서 *모르는 점수가 와도 안 죽게* 했어요.

```swift
private static func color(for gainedPoints: Int) -> UIColor {
    switch gainedPoints {
    case GameConfig.scorePerNote:      return .ganhoPaper   // +1 흰색
    case GameConfig.scorePerNoteCombo: return .ganhoYellowF // +2 황금
    default:                            return .ganhoPaper   // 안전망
    }
}
```

미래에 *+3 보너스* 같은 새 점수 시스템이 생겨도 *빨갛게 터지는 일* 없이 그냥 흰색으로 떠요. **무너지지 않는 방어선**.

**Spring 비유** — `Optional.orElse(defaultValue)` 같은 거. *값이 없을 때 어떻게 할지를 미리 적어두면 안전하다*.

## 오늘의 한 줄

> *"음표 자리에 +1 / +2가 작게 떠오르는 0.6초가, 콤보 시스템 전체를 설명한다"*
