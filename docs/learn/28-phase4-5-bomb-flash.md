# 28 · Phase 4-5 · 폭탄 화면 플래시 — *번쩍!* 💥

> **이번 작업 한 줄**: 4-4 오버레이가 사라진 0.3초 뒤, 화면 전체가 0.42초 동안 누런 섬광으로 번쩍한다. GDD §7-7의 "폭탄" 단계 — *비행기가 떨어뜨린 폭탄의 빛*을 표현. 게임 로직 변화는 여전히 0 (시각만).

---

## 1. 왜?

GDD §7-7 AIRFORCE 이스터에그 시퀀스:
1. ✅ 오버레이 "나와라 박병장!" (4-4)
2. ✅ 비행기 좌→우 (4-3)
3. ⬜ **폭탄 화면 플래시** ← 본 sprint
4. ⬜ 수간호사 5초 도주 (4-6)
5. ⬜ 수간호사 복귀 후 F 재스폰 (4-7)

오버레이가 *호출*, 비행기가 *응답*, **폭탄이 *실행***. 시퀀스의 클라이맥스 — 화면이 한 번 번쩍이며 *무언가 일어났다*는 느낌을 전달.

> Spring 비유: 4-3·4-4가 *요청·로그*였다면, 4-5는 *실제 효과*. 다만 그 효과가 *게임 로직*이 아닌 *시각 임팩트*. 부가 작용(side effect)이 *비주얼*에만 머무는 단계.

---

## 2. Spring 비유 ⭐

| SpriteKit | Spring | 한 줄 설명 |
|---|---|---|
| `BombFlashNode` (신규) | 이벤트 후 사후 처리 컴포넌트 | "트리거 후 일정 시간 뒤 발화" |
| `SKAction.wait(2.1)` | `@Scheduled(initialDelay=2100ms, fixedDelay=0)` | "2.1초 후에 한 번 실행" |
| `SKAction.fadeIn(0.07) → fadeOut(0.35)` | 빠른 페이드 인 → 느린 페이드 아웃 | "빛이 갑자기 났다가 천천히 사라짐" |
| `풀스크린 SKSpriteNode` | 모달 백드롭 | "화면 전체를 덮음" |
| `cameraNode.addChild(flash)` | 화면 고정 좌표계 | "카메라 따라가도 항상 화면 전체" |

**핵심**: 본 sprint도 *호출 측 변경 0*. AirplaneNode·AirforceOverlayNode·ContactRouter 등 한 줄도 안 건드림. `triggerAirforceEasterEgg()` 본문에 *세 번째 효과 3줄*만 추가.

---

## 3. 새로 배운 것 (Swift/SpriteKit) ⭐

### 3-1. **`SKAction.fadeIn(withDuration:)` — 알파 0→1 보간**

```swift
let fadeIn = SKAction.fadeIn(withDuration: 0.07)
```

`fadeOut`의 정확한 반대 — 알파를 *현재 값 → 1*로 자동 보간. 노드 초기 알파가 0이어야 자연스러운 *나타남* 효과.

> Spring 비유: CSS `transition: opacity 0.07s; opacity: 1;`. SpriteKit이 매 프레임 보간.

### 3-2. **풀스크린 사각형 = `SKSpriteNode(color:size:)` + cameraNode 자식**

```swift
let flash = SKSpriteNode(color: .ganhoPaper, size: CGSize(width: sceneW, height: sceneH))
flash.alpha = 0
flash.zPosition = 250
cameraNode.addChild(flash)
```

cameraNode 자식 좌표계 (0,0) = 화면 중앙 → 풀스크린 사각형의 *중심*이 (0,0)이면 *화면 전체*를 정확히 덮음.

`size`는 *scene.size 의존*이라 AirplaneNode 패턴 답습 — init에서 자동 크기 잡지 않고 외부가 `flash(sceneSize:)` 메서드 호출 시 크기 부여.

> Spring 비유: 컴포넌트 width/height가 *부모 크기 의존*인 경우 — props로 받기. SpriteKit도 동일.

### 3-3. **`SKAction.wait + fadeIn + wait + fadeOut + removeFromParent` 5단 시퀀스**

```swift
let sequence: [SKAction] = [
    .wait(forDuration: 2.1),    // 오버레이 닫힘(1.8) + 300ms = 2.1
    .fadeIn(withDuration: 0.07),
    .wait(forDuration: 0.0),    // 또는 생략 — fadeIn 끝나면 바로 fadeOut
    .fadeOut(withDuration: 0.35),
    .removeFromParent()
]
run(.sequence(sequence))
```

**5단 시퀀스의 의미**:
1. 트리거부터 *2.1초 대기* (오버레이 페이드 끝 + 300ms)
2. 0.07초에 걸쳐 *반짝 나타남*
3. (선택) 잠시 유지
4. 0.35초에 걸쳐 *천천히 사라짐*
5. 자기 제거

총 *0.07 + 0.35 = 0.42초* 동안 화면을 덮음 — GDD §7-7 "420ms" 정확.

> 자가 소멸 노드 패턴 **3번째 등장** — 비행기 / 오버레이 / 폭탄. **Rule of three 도달**. 다음 sprint(또는 별도)에서 `protocol SelfDismissingNode` 추출 후보.

### 3-4. **`SKAction.fadeIn(0.07) → fadeOut(0.35)` 비대칭 시간**

같은 페이드라도:
- 빠른 in (0.07s) = *번쩍* 임팩트
- 느린 out (0.35s) = *잔상* 효과

비대칭이 *폭발의 자연스러운 시각*. 대칭(둘 다 0.21s)이면 *부드러운 펄스*에 가까워 임팩트 ↓.

> 비유: 카메라 플래시가 빛날 때도 *번쩍 켜졌다가 천천히 어두워짐*. 사진 노출의 자연 곡선.

### 3-5. **zPosition 계층 — 250 (모든 노드 위)**

| zPosition | 누구 |
|---|---|
| **250** | **BombFlashNode (4-5, *최상위 일시*)** |
| 200 | AirforceOverlayNode (1.8s만 존재) |
| 100 | HUD |
| 50 | AirplaneNode (비행기, 2.0s만 존재) |
| 5 | Player, Enemy, StoneGuard, Note, Projectile |
| 0 | 벽·기둥·배경 |

폭탄 = *순간적*으로 *모든 것 위*. 0.42초만 존재하므로 HUD를 잠시 덮어도 OK. 시간상 오버레이(1.8s 끝남)와 안 겹침이지만 zPosition은 안전마진.

### 3-6. **`SKAction.fadeOut` 다음에 `removeFromParent` 의미**

```swift
.fadeOut(withDuration: 0.35),
.removeFromParent()
```

fadeOut이 *완료*되면(alpha = 0) 그 다음 액션 실행 — 즉 *완전히 투명해진 후* 자기 제거. 시각상 차이 없지만 *메모리 정리*는 명시적.

> 만약 fadeOut만 두고 removeFromParent 생략하면? — 노드는 *씬 트리에 계속 남음* (alpha 0이라 안 보이지만). 메모리 누수 가능성 ↑. **항상 removeFromParent로 마무리**.

### 3-7. **Rule of three 도달 — `protocol SelfDismissingNode` 추출 신호**

| sprint | 노드 | sequence |
|---|---|---|
| 4-3 | AirplaneNode | `[move, removeFromParent]` |
| 4-4 | AirforceOverlayNode | `[wait, fadeOut, removeFromParent]` |
| **4-5** | **BombFlashNode** | **`[wait, fadeIn, fadeOut, removeFromParent]`** |

**공통 패턴**:
- 외부에서 메서드 호출 시 SKAction.sequence 자동 시작
- sequence 마지막은 `removeFromParent`
- self 미사용 → `[weak self]` 캡처 없음

**그러나 본 sprint는 추출 X**. 추출은 *별도 리팩터 sprint*로 분리. 이유:
- 본 sprint는 *기능 추가*에 집중
- 추출은 *기존 3 노드 모두 변경* — OoS 위반 위험
- *추출 자체*를 1 sub-feature로 다음에 별도 진행

> 추출 시 protocol 시그니처 후보:
> ```swift
> protocol SelfDismissingNode: AnyObject {
>     // 메서드 이름이 노드마다 다름 (crossScreen / showAndDismiss / flash)
>     // → protocol 추출 시 통일 필요 — *별도 결정*
> }
> ```

---

## 4. 무엇을 만드나?

### 새 파일 (1개)
| 파일 | 역할 |
|---|---|
| `Nodes/BombFlashNode.swift` | SKSpriteNode 풀스크린 사각형 + `flash(sceneSize:)` 메서드로 5단 SKAction 시퀀스 자가 소멸 |

### 고치는 파일 (3개 + pbxproj)
| 파일 | 변경 |
|---|---|
| `Config/GameConfig.swift` | Airforce 섹션에 4상수 추가 (bombFlashDelay / bombFlashFadeInDuration / bombFlashFadeOutDuration / bombFlashAlpha) |
| `GameScene.swift` | 헤더 MARK 1줄 + `triggerAirforceEasterEgg()` 본문 끝에 폭탄 3줄 + doc 1줄 |
| pbxproj | BombFlashNode.swift 4곳 등록 (식별자 0020) |

> ❌ **건드리지 않는 파일**: AirplaneNode, AirforceOverlayNode, ContactRouter, PhysicsCategory, StoneGuardNode, GameScene+Setup, 기타 모든 노드/씬/시스템.

### 한 그림으로

```
[Player가 StoneGuard 첫 통과]
        ↓
trigger 시작 (t=0)
        ├── 비행기 (t=0~2.0s)        — 4-3
        ├── 오버레이 (t=0~1.8s)      — 4-4
        └── 폭탄 (t=2.1~2.52s)        ← 4-5 신규
            ↓
        풀스크린 사각형 (.ganhoPaper, alpha=0, zPosition=250)
            ↓
        SKAction.sequence:
          wait(2.1) → fadeIn(0.07) → fadeOut(0.35) → removeFromParent
            ↓
        총 2.52초 후 완전 제거 (메모리 정리)
```

### 시간선 (밀리초)

| 시점 | 이벤트 |
|---|---|
| 0 | trigger 시작 — 비행기 출발, 오버레이 표시 |
| 1500 | 오버레이 페이드아웃 시작 |
| 1800 | 오버레이 완전 사라짐 |
| 2000 | 비행기 화면 밖 도착 |
| **2100** | **폭탄 fadeIn 시작 (오버레이 닫힘 후 300ms)** |
| 2170 | 폭탄 alpha=1 (완전한 빛) |
| 2520 | 폭탄 alpha=0, 노드 제거 |

---

## 5. 직접 확인할 것

⌘R 후:

| # | 시나리오 | 봐야 할 것 |
|---|---|---|
| (a) | 게임 시작, 석조무사 미접촉 | 폭탄 0건 (4-4까지와 동일) |
| (b) | Player가 석조무사 첫 통과 | 비행기 + 오버레이 동시 등장 (4-3, 4-4 그대로) |
| (c) | ~1.8초 후 | 오버레이 사라짐. 폭탄은 *아직 안 등장* (300ms 대기 중) |
| (d) | ~2.1초 후 | **화면 전체가 누런 빛으로 *번쩍*** (fadeIn 0.07s) |
| (e) | ~2.5초 후 | 폭탄 완전 사라짐 |
| (f) | 폭탄 표시 중 게임 | player 이동 / D-Pad / 점수 / HUD 모두 정상 (게임 안 멈춤) |
| (g) | 폭탄 표시 중 적/F | enemy 추적 / F 발사 정상 진행 |
| (h) | 재통과 시 | 비행기·오버레이·폭탄 모두 0 (1회 한정, airforceTriggered 가드) |
| (i) | 게임오버 시 폭탄 잔존 | ResultScene 전환 시 cameraNode 자식 폭탄도 ARC 자동 해제 |

> **핵심**: 사용자는 *AIRFORCE 시퀀스의 3/5 단계*까지 본다. 다음 sprint(4-6, 4-7)에서 수간호사 도주 + F 재스폰으로 시퀀스 완성.

---

## 6. 사용자 결정 (이미 합의)

| 결정 | 선택 | 왜 |
|---|---|---|
| 본 sprint 범위 | 폭탄 시각 플래시만 | 도주·F 재스폰은 다음 sprint 분리 |
| 색 | `.ganhoPaper` (누런 종이색) | ColorTokens 신설 정책 유지. 0.07s fadeIn에서 *흰 빛*과 유사한 인지 |
| 부착 위치 | `cameraNode` 자식 | 화면 고정 좌표계 — 카메라 이동 시에도 화면 전체 덮음 |
| zPosition | 250 | 모든 노드 위 (HUD 100, 오버레이 200 위) — 안전마진 |
| 시간 | 2.1s delay → 0.07 fadeIn → 0.35 fadeOut | GDD §7-7 정확: 오버레이 닫힘(1.8) + 300ms = 2.1, 420ms 표시 = 0.07 + 0.35 |
| 1회 한정 | YES (4-3 가드 그대로) | airforceTriggered 그대로 |
| OoS — 도주·F 재스폰 | 금지 | 다음 sprint |
| OoS — AirplaneNode·AirforceOverlayNode 변경 | 금지 | 4-3, 4-4 그대로 |

---

## 7. 회고

### 7-1. 막혔던 것

**없음.** 한 사이클 만점 합격(10.0/10). P0/P1/P2 0건.

### 7-2. 새로 배운 것

1. **`SKAction.fadeIn(withDuration:)` — `fadeOut`의 정확한 반대** — alpha를 *현재→1*로 자동 보간. 초기 alpha=0이어야 *나타남* 효과.
2. **`SKAction.sequence([wait, fadeIn, fadeOut, removeFromParent])` 4단 시퀀스** — *대기 + 깜빡임 + 정리* 토스트 패턴 확장. 자가 소멸 패턴 *3회차*.
3. **비대칭 fadeIn/fadeOut (0.07s vs 0.35s)** — 빠른 in + 느린 out = *번쩍 + 잔상*. 폭발/플래시의 자연스러운 시각 곡선.
4. **풀스크린 사각형의 size init 전략** — `super.init(... size: .zero)`로 시작, 외부 메서드에서 sceneSize 주입. AirplaneNode 패턴 답습 (scene.size 의존).
5. **alpha=0 초기화 의무** — 안 두면 fadeIn 첫 프레임에 *이미 가시* → "번쩍" 효과 사라짐.
6. **zPosition 250 = *모든 노드 위***. 0.42초만 존재 → HUD/오버레이 잠시 덮어도 OK.
7. **Rule of three 도달 — protocol 추출 *후보 인식*만**. 본 sprint는 *추출 X* — 별도 리팩터 sprint로 분리(기능 추가 sprint와 추출 sprint를 *섞지 않음*).
8. **`.ganhoPaper` 색 재사용** — fadeIn 0.07초로 빠르게 번쩍이면 누런 색도 *흰 빛*과 유사한 인지. ColorTokens 신설 정책 유지.
9. **`bombFlashDelay = 2.1` 합산 검증** — 1.5(overlayDisplay) + 0.3(overlayFadeOut) + 0.3(GDD 명시 갭) = 2.1. 기존 상수 변경 금지이므로 *수동 합산만* 일치시킴.

> Spring 비유: 같은 fire-and-forget 패턴이 *세 서비스*에 등장 → 인터페이스 추출 시그널. 그러나 *추출은 별도 PR*에서.

### 7-3. 다음으로 미룬 것

- **4-6: 수간호사 5초 도주 모드** — `EnemyNode` 확장 또는 GameScene 타이머. GDD §7-7 4단계.
- **4-7: 수간호사 복귀 후 F 재스폰** — `SpawnSystem` 확장. GDD §7-7 5단계.
- **`protocol SelfDismissingNode` 추출** — 3 노드 공통 인터페이스 정의 (별도 리팩터 sprint).
- **사운드 효과** — Phase 6.

### 7-4. 평가 점수

- **가중평균: 10.0 / 10 — 만점 합격** 🎉
- 항목별: Swift 패턴 10 / 게임 로직 10 / 성능·안정성 10 / 기능 완성도 10
- P0/P1/P2 0건
- 빌드: BUILD SUCCEEDED, 경고 0건
- diff: 신규 1파일(44줄) + 수정 3파일(GameConfig +6 / GameScene +5 / pbxproj +4)

### 7-5. 핵심 가치 — *호출 측 변경 0 정책 4 sprint 연속*

| 보존된 것 | 변경 0건 |
|---|---|
| AirplaneNode / AirforceOverlayNode (4-3, 4-4 그대로) | ✅ |
| ContactRouter / PhysicsCategory / StoneGuardNode | ✅ |
| GameScene+Setup | ✅ |
| 기존 GameConfig 상수 (airplane 4 + airforceOverlay 3 + 그 외) | ✅ |
| 기존 trigger 본문 7줄 (가드 2 + 비행기 4 + 오버레이 3) | ✅ |
| Player/Enemy/Note/Projectile/HUD/DPad | ✅ |
| TitleScene/ResultScene/ColorTokens | ✅ |
| `update()` / `endGame()` / `airforceTriggered` 가드 위치 | ✅ |
| macOS/tvOS Sources phase | ✅ |

**4-2 → 4-3 → 4-4 → 4-5 sprint 4 연속 호출 측 변경 0**. 본 sprint도 *외과 수술적*. 정책이 *체화*되는 단계 — 다음 sprint에서 *수간호사 EnemyNode 변경*이 불가피한 4-6은 새로운 도전(EnemyNode 변경은 OoS 정책에 *없었던* 첫 변경 영역).

---

## 8. 다음 작업

```
[1] 시뮬레이터에서 §5 (a)~(i) 확인 (특히 (d): "번쩍!")
[2] 다음 sprint: Phase 4-6 (수간호사 5초 도주 모드)
```

> **이번 sprint 본질**: *자가 소멸 노드 패턴 3회차*. Rule of three 도달 — 다음 별도 리팩터 sprint에서 `protocol SelfDismissingNode` 추출 후보 인식. 또한 *호출 측 변경 0 정책*이 4-2 → 4-3 → 4-4 → 4-5 **4 sprint 연속**.
