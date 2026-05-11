# 27 · Phase 4-4 · "나와라 박병장!" — AIRFORCE 호출 오버레이 📢

> **이번 작업 한 줄**: 4-3에서 비행기 한 마리가 슝~ 지나갔다. 본 sprint는 *그 비행기가 *왜* 나타났는지*를 설명하는 텍스트 오버레이 — **"나와라 박병장!"** — 를 화면 중앙에 1.5초간 띄운 뒤 페이드아웃시킨다. 비행기와 *동시*에 나타나서 *동시에* 사라짐. 박병장 = AIRFORCE 호출의 마스코트.

---

## 1. 왜?

GDD §7-7에서 AIRFORCE 이스터에그의 전체 시퀀스는:
1. 오버레이 *"나와라 박병장!"* (호출)
2. 비행기 (호출에 응답하여 등장)
3. 폭탄 (오버레이 닫힘 후 화면 플래시)
4. 수간호사 5초 도주

4-3에서 (2) 비행기까지만 구현했다. 본 sprint는 (1) 오버레이를 추가 — *비행기가 왜 등장하는지* 의미가 비로소 생긴다. (3)(4)는 추후 sprint로 분리.

> Spring으로 치면: 4-3에서 `@PostMapping("/airforce")`의 응답(비행기)을 만들었고, 4-4에서 *요청 토스트*("나와라 박병장!")를 화면에 띄움. 사용자에게 "지금 무슨 일이?"를 명시.

---

## 2. Spring 비유 ⭐

| SpriteKit | Spring | 한 줄 설명 |
|---|---|---|
| `AirforceOverlayNode` (신규) | 토스트 메시지 컴포넌트 | "잠깐 떴다 사라짐" |
| `SKLabelNode` "나와라 박병장!" | 토스트 텍스트 라벨 | 한 줄 메시지 |
| `SKAction.sequence([wait, fadeOut, removeFromParent])` | `setTimeout → 자동 dismiss` | "시간 지나면 알아서 사라짐" |
| `triggerAirforceEasterEgg()` 본문 확장 | `@EventListener` 본문 안에서 *두 효과 동시 발사* | 비행기 + 오버레이 |
| `zPosition = 200` | CSS `z-index: 999` | 가장 위에 띄움 |

**핵심**: 본 sprint는 *4-3의 메서드를 약간 확장*. 외부 호출 측(ContactRouter / StoneGuardNode / PhysicsCategory)은 한 줄도 안 건드림. 4-3과 동일한 *외과 수술적* 변경.

---

## 3. 새로 배운 것 (Swift/SpriteKit) ⭐

### 3-1. **`SKLabelNode` — SpriteKit의 텍스트 노드**

```swift
let label = SKLabelNode(text: "나와라 박병장!")
label.fontSize = 28
label.fontColor = .ganhoYellowF
label.verticalAlignmentMode = .center
label.horizontalAlignmentMode = .center
```

SpriteKit에서 *텍스트를 표시하는 유일한 표준 노드*. HUD에서 점수/시간/콤보 표시할 때도 같은 노드 사용.

**정렬 모드 (anchor)**:
- `verticalAlignmentMode = .center` → 라벨 *중심점*이 position에 정렬
- `.baseline`(기본)이면 텍스트 *밑선*이 position → 화면 중앙 배치할 때 어색

> Spring 비유: HTML `<span>` 같은 거. *블록 박스*가 아니라 *텍스트만*. 폰트·정렬 속성만 갖춤.

### 3-2. **여러 SKAction을 한 노드에 묶는 `sequence` 패턴 확장**

4-3 AirplaneNode는 `[move, removeFromParent]`였다. 4-4 오버레이는 *대기 + 페이드 + 제거*:

```swift
let wait    = SKAction.wait(forDuration: 1.5)
let fadeOut = SKAction.fadeOut(withDuration: 0.3)
let cleanup = SKAction.removeFromParent()
run(.sequence([wait, fadeOut, cleanup]))
```

3단 시퀀스 — 라벨이 1.5초 떠 있다가 → 0.3초간 사라지다가 → 자기 제거. *총 1.8초 후 완전 제거*.

**핵심**: `SKAction.wait`이 "아무것도 안 하고 시간만 흐름"을 표현. CSS `animation-delay`와 비슷.

> Spring 비유: 토스트 라이브러리의 `duration: 1500ms`. 시간만 흘려보내고 다음 동작 트리거.

### 3-3. **`SKAction.fadeOut(withDuration:)` — 알파 자동 보간**

```swift
let fadeOut = SKAction.fadeOut(withDuration: 0.3)
```

이 한 줄이 의미:
- 노드의 `alpha`를 *현재 값 → 0*으로 0.3초에 걸쳐 자동 보간
- 매 프레임 직접 `alpha -= 0.033` 같은 코드 *불필요*
- 보간은 SpriteKit이 자동 (linear)

> Spring 비유: 한 줄로 *transition* 정의. 매 프레임 RxJS observable 만들 필요 없음.

### 3-4. **동시 발화 — 한 메서드 안에 두 노드 부착**

```swift
private func triggerAirforceEasterEgg() {
    if airforceTriggered { return }
    airforceTriggered = true
    
    // 효과 1: 비행기 (4-3 그대로)
    let plane = AirplaneNode()
    cameraNode.addChild(plane)
    plane.crossScreen(...)
    
    // 효과 2: 오버레이 (4-4 신규)
    let overlay = AirforceOverlayNode()
    cameraNode.addChild(overlay)
    overlay.showAndDismiss()
}
```

두 노드는 *서로 모른다*. 각자 자기 SKAction을 가지고 자기 일을 함. 메서드는 *두 효과를 동시에 발사*만 함.

> Spring 비유: `@EventListener` 메서드 본문에 두 `applicationEventPublisher.publishEvent(...)` 호출. 둘이 *동시*에 fire-and-forget.

### 3-5. **자가 소멸 노드 패턴 — *반복 학습***

| sprint | 노드 | sequence |
|---|---|---|
| 4-3 | AirplaneNode | `[move, removeFromParent]` |
| 4-4 | AirforceOverlayNode | `[wait, fadeOut, removeFromParent]` |

같은 패턴 — *시작 → 효과 → 자기 제거*. **두 번 반복하면 protocol 후보**.

```swift
// 미래의 protocol (지금은 OoS)
protocol SelfDismissingNode {
    func runDismissalSequence()
}
```

지금은 *두 번 했으니 패턴 인식*까지만. 추출은 *세 번째 등장 시*.

> "Rule of three" — 세 번 반복되면 추출. 두 번까지는 *복사가 추상화보다 싸다*.

### 3-6. **zPosition 200의 의미**

| zPosition | 누구 |
|---|---|
| **200** | **AirforceOverlayNode** ← *가장 위, 잠깐 표시* |
| 100 | HUD (점수·시간·콤보 라벨) |
| 50 | AirplaneNode (이스터에그 비행기) |
| 5 | Player, Enemy, StoneGuard, Note, Projectile |
| 0 (기본) | 벽, 기둥, 배경 |

오버레이는 *HUD를 덮어도 됨* — "지금 특별한 일이 일어나고 있다"를 강조. *1.5초만* 떴다 사라지니 게임 진행 방해 X.

### 3-7. **`triggerAirforceEasterEgg()` 본문 확장 — 메서드 분리 vs 한 메서드 안에서?**

선택지:
- (A) `triggerAirforceEasterEgg()` 본문에 비행기 + 오버레이 *동시 등장* — 한 메서드
- (B) `triggerAirforceEasterEgg()`에서 *오버레이*만 등장, *비행기*는 별도 `showAirplane()` 메서드 — 분리

본 sprint = **(A)**. 이유:
- 이스터에그는 *하나의 이벤트* (메서드 이름 그대로)
- 분리하면 *호출 순서 의존성*이 생김 → 복잡도 ↑
- 다음 sprint(폭탄·도주)도 이 메서드 안에 자연스럽게 추가

> *단일 책임 원칙* vs *응집도*. 이스터에그라는 *하나의 단위 행위*는 한 메서드로 응집하는 게 자연. 분리는 *각 효과가 독립 트리거 가능*해질 때.

---

## 4. 무엇을 만드나?

### 새 파일 (1개)
| 파일 | 역할 |
|---|---|
| `Nodes/AirforceOverlayNode.swift` | SKNode 컨테이너 + 자식 SKLabelNode("나와라 박병장!"). `showAndDismiss()` 메서드로 wait + fadeOut + removeFromParent 자가 소멸 |

### 고치는 파일 (3개 + pbxproj)
| 파일 | 변경 |
|---|---|
| `Config/GameConfig.swift` | Airforce Easter Egg 섹션에 3상수 추가 (overlayFontSize / overlayDisplayDuration / overlayFadeOutDuration) |
| `GameScene.swift` | `triggerAirforceEasterEgg()` 본문에 오버레이 2~3줄 추가. 헤더 MARK 1줄 |
| pbxproj | AirforceOverlayNode.swift 4곳 등록 (식별자 0019) |

> ❌ **건드리지 않는 파일**: AirplaneNode, ContactRouter, PhysicsCategory, StoneGuardNode, GameScene+Setup, 기타 모든 노드/씬/시스템.

### 한 그림으로

```
[Player가 StoneGuard 처음 통과]
        ↓
ContactRouter.didBegin → stoneGuard 분기 → onStoneGuardContact()
        ↓
GameScene.triggerAirforceEasterEgg()
        ↓
  airforceTriggered 가드 → true
        ↓
  ┌─────────────────────────┐
  │ (효과 1: 비행기 — 4-3 그대로)
  │   let plane = AirplaneNode()
  │   cameraNode.addChild(plane)
  │   plane.crossScreen(...)  → 2초간 좌→우, 자가 제거
  └─────────────────────────┘
        ↓ (동시)
  ┌─────────────────────────┐
  │ (효과 2: 오버레이 — 4-4 신규)
  │   let overlay = AirforceOverlayNode()
  │   cameraNode.addChild(overlay)
  │   overlay.showAndDismiss()  → 1.5초 표시 + 0.3초 페이드 + 자가 제거
  └─────────────────────────┘
        ↓
  airforceTriggered = true (재발동 안 함)
```

### 오버레이 시각 사양 (잠정)
- 텍스트: **"나와라 박병장!"**
- 색: `.ganhoYellowF` (비행기와 동일 — 시각 일관성)
- 폰트 크기: 28pt
- 위치: 화면 정중앙 (cameraNode 자식 좌표 (0,0))
- zPosition: 200
- 표시 시간: 1.5초
- 페이드아웃: 0.3초
- 총 수명: 1.8초

---

## 5. 직접 확인할 것

⌘R 후:

| # | 시나리오 | 봐야 할 것 |
|---|---|---|
| (a) | 게임 시작, 석조무사 미접촉 | 오버레이 0건 (4-3과 동일) |
| (b) | Player가 석조무사 첫 통과 | 화면 정중앙에 **"나와라 박병장!"** 노란 텍스트 표시 + 비행기 동시 좌→우 |
| (c) | ~1.5초 후 | 오버레이 페이드아웃 시작 |
| (d) | ~1.8초 후 | 오버레이 완전 사라짐. 비행기도 우측 바깥으로 (4-3 흐름 그대로) |
| (e) | 재통과 시 | 오버레이·비행기 모두 0 (1회 한정) |
| (f) | 오버레이 표시 중 점수·HUD | 영향 0 — 게임 진행 그대로. 콤보·점수도 정상 |
| (g) | 오버레이 표시 중 D-Pad | D-Pad 입력 정상 — 플레이어 계속 움직임 |
| (h) | 게임오버 시 오버레이 잔존 | ResultScene 전환 시 GameScene 트리 ARC 해제로 자동 정리 |

> **핵심**: 오버레이는 *알림*이지 *게임 일시정지*가 아님. 게임 흐름 유지 + 시각 메시지만 추가.

---

## 6. 사용자 결정 (이미 합의)

| 결정 | 선택 | 왜 |
|---|---|---|
| 본 sprint 범위 | "나와라 박병장!" 오버레이만 | 폭탄·도주는 다음 sprint 분리 (1 sub-feature 원칙) |
| 사용자 입력 | **없음** (자동 페이드) | "확인 버튼"(GDD)은 게임 일시정지 필요 → 큰 변경. 자동 페이드가 단순·자연 |
| 비행기와의 관계 | **동시** 등장·소멸 | 분리하면 *호출 순서 의존성* 발생. 응집도 ↑ |
| 부착 위치 | `cameraNode` 자식 | 화면 고정 좌표계 (HUD/비행기와 동일 트리) |
| 색 | `.ganhoYellowF` | 비행기와 통일 — 시각 일관성. 새 토큰 0 |
| 폰트 크기 | 28pt | HUD(20pt)보다 크고 화면 한가운데 잘 보임 |
| 표시 + 페이드 시간 | 1.5 + 0.3초 | 비행기(2.0초)와 비슷한 수명 — 둘이 함께 사라짐 |
| zPosition | 200 | HUD(100)보다 위 — 강조 |
| 1회 한정 | **YES** (4-3 가드 그대로) | 4-3의 airforceTriggered 그대로 |
| OoS — 폭탄·도주 | 금지 | 다음 sprint |
| OoS — AirplaneNode 변경 | 금지 | 4-3 그대로 |

---

## 7. 회고

### 7-1. 막혔던 것

**없음.** 한 사이클(QA 1회)에 **만점 합격(10.0/10)**. P0/P1/P2 0건.

자가 소멸 노드 패턴의 *두 번째 답습*이라 본 sprint의 어려움이 거의 0. Generator/Evaluator 1회 통과.

### 7-2. 새로 배운 것

1. **SKLabelNode 중앙 정렬** — `verticalAlignmentMode = .center` + `horizontalAlignmentMode = .center`로 라벨 *중심점*을 position에 anchor. `.baseline`(기본)은 텍스트 *밑선* anchor라 화면 정중앙 배치 시 어색.
2. **`SKAction.wait + fadeOut + removeFromParent` 3단 시퀀스** — 토스트 패턴 표준. wait은 "아무것도 안 하고 시간만 흐름", fadeOut은 alpha 1→0 자동 보간, removeFromParent는 자기 제거.
3. **자가 소멸 노드 패턴 두 번째 적용** — AirplaneNode `[move, removeFromParent]` → AirforceOverlayNode `[wait, fadeOut, removeFromParent]`. 둘 다 *fire-and-forget*. **Rule of three 인식 단계** — 세 번째 등장 시 `protocol SelfDismissingNode` 추출 후보.
4. **호출 측 변경 0 패턴 3 sprint 연속** — 4-2(stub 분리) → 4-3(stub 본체 채움) → 4-4(본체 확장). ContactRouter/PhysicsCategory/StoneGuardNode/GameScene+Setup 한 줄도 안 건드린 sprint 3개.
5. **`triggerAirforceEasterEgg()` 본문 *확장* vs 분리** — 이스터에그는 *단일 이벤트* → 한 메서드 본문 안에 *두 효과 동시 발사*. 분리는 *각 효과가 독립 트리거 가능*해질 때만.
6. **`zPosition = 200`** — HUD(100) 위 / AirplaneNode(50)보다도 위. 1.8초만 존재하므로 HUD를 잠시 덮어도 OK.
7. **색 토큰 재사용 (.ganhoYellowF)** — 비행기와 통일. 새 ColorTokens 신설 0. 시각 일관성 + 브랜드 일관성.
8. **SKNode 컨테이너 + 자식 SKLabelNode 패턴** — HUDNode와 동일. *부모는 좌표·zPosition·name*, *자식 라벨은 폰트·정렬·텍스트*. 책임 분리.
9. **`[weak self]` 캡처 정확** — `showAndDismiss()`는 self 미사용 → 캡처 생략. self 사용 시에만 캡처. 미사용 캡처 = 컴파일러 경고 위험.
10. **GameConfig 섹션 합류 vs 신설** — Airforce 섹션이 이미 있어(4-3) 새 MARK 신설 X. *같은 도메인은 같은 섹션*.

> Spring 비유: 4-2에서 컨트롤러 핸들러 분리, 4-3에서 핸들러 본문(서비스 호출), 4-4에서 *추가 서비스 호출*. 컨트롤러·시그니처 변경 0, 본문만 확장.

### 7-3. 다음으로 미룬 것

- **4-5: 폭탄 화면 플래시** — GDD §7-7 "오버레이 닫힘 후 300ms → 화면 플래시 420ms". SKShapeNode/SKSpriteNode 풀스크린 + SKAction.fadeIn → fadeOut.
- **4-6: 수간호사 5초 도주 모드** — GDD §7-7 "5초간 공포 도주 (플레이어 반대 방향)". EnemyNode에 mode 추가 + GameScene 타이머.
- **4-Z: 이교주 NPC** — GDD §7-8. *상 난이도 시스템* 도입 후. 청진기 투사체, 동결 효과.
- **`protocol SelfDismissingNode`** — *세 번째* 자가 소멸 노드 등장 시 추출 (Rule of three).
- **사운드 효과** — Phase 6.

### 7-4. 평가 점수

- **가중평균: 10.0 / 10 — 만점 합격** 🎉
- 항목별: Swift 패턴 10 / 게임 로직 10 / 성능·안정성 10 / 기능 완성도 10
- P0 0건, P1 0건, P2 0건
- 빌드: BUILD SUCCEEDED, 경고 0건
- diff: 신규 1파일(56줄) + 수정 3파일(GameConfig +7 / GameScene +6 / pbxproj +4)

### 7-5. 핵심 가치 — *호출 측 변경 0 정책의 정착*

| 보존된 것 | 변경 0건 |
|---|---|
| `AirplaneNode.swift` (4-3 그대로) | ✅ |
| `ContactRouter.swift` | ✅ |
| `PhysicsCategory.swift` | ✅ |
| `StoneGuardNode.swift` | ✅ |
| `GameScene+Setup.swift` | ✅ |
| 기존 GameConfig 상수 (airplane 4상수 포함) | ✅ |
| Player/Enemy/Note/Projectile/HUD/DPad | ✅ |
| TitleScene/ResultScene | ✅ |
| `update()` / `endGame()` 게임 루프 | ✅ |
| ColorTokens (.ganhoYellowF 재사용) | ✅ |
| macOS / tvOS Sources phase | ✅ |
| `airforceTriggered` 가드 위치 | ✅ |

**추가된 것**:
- AirforceOverlayNode.swift 신규 (56줄)
- GameConfig.swift Airforce 섹션 끝 3상수 (~7줄)
- GameScene.swift 헤더 1줄 + doc 2줄 + 본문 3줄 (~6줄)
- pbxproj 4곳 (4줄)

**4-2 → 4-3 → 4-4 sprint 3개 연속 *호출 측 변경 0***. *분리해서 작게* 정책이 *습관*으로 정착하는 단계. 5-Z(이교주, 박병장 비행기 등)에서도 같은 패턴이 가능할 가능성 ↑.

---

## 8. 다음 작업

```
[1] 시뮬레이터에서 §5 (a)~(h) 확인 (특히 (b): "나와라 박병장!" 한 번)
[2] 다음 sprint 후보:
    - Phase 4-5: 폭탄 화면 플래시 (GDD §7-7)
    - Phase 4-6: 수간호사 5초 도주 모드 (GDD §7-7)
    - Phase 4-Z: 이교수 NPC (난이도 시스템 도입 후)
```

> **이번 sprint 본질**: *AirplaneNode 패턴(자가 소멸 SKAction.sequence)*을 *두 번째 노드(AirforceOverlayNode)*에 답습. 두 번 했으니 *protocol 추출 후보*로 인식됨 — Rule of three. 또한 *호출 측 변경 0* 정책이 4-2 → 4-3 → 4-4로 *세 sprint 연속* 유지 — *분리해서 작게* 만드는 훈련의 진가가 안정화되는 단계.
