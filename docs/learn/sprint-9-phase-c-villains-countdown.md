# Sprint 9 Phase C — 빌런 시각 키우고 카운트다운 또렷이 보이게

## 한 줄 요약
빌런 3종(수간호사·이교수·석조무사)의 *얼굴 부분*을 1.4배 키워서 잘 보이게 하고, 게임 시작 직전의 "3·2·1·GO!" 카운트다운이 화면 정중앙에 안 빠지고 뜨도록 명시적으로 위치·층을 고정한 작업이야.

## 왜 했어?

### 문제 1 — 빌런이 너무 작아서 안 보임
지난 작업(Sprint 8 Phase G)에서 빌런 본체의 색을 투명(`color = .clear`)으로 바꿔서, 본체는 안 보이고 **자식 노드만 보이는 구조**가 됐어. 그런데 그 자식 노드(외곽 후광, 차트, 코랄 클립, 청진기, 갑옷 등)가 너무 작아서 시뮬레이터에서 빌런 식별이 잘 안 됐어. 회피·전략 판단을 하려면 24pt 이상은 보여야 해.

### 문제 2 — "3·2·1·GO!" 카운트다운이 가끔 안 보임
화면 시작 직전 카운트다운이 *발화*는 하는데(로그는 찍힘) 화면에 *그려지지 않는* 경우가 있었어. 카메라 좌표계 정중앙에 안 붙거나, 다른 노드한테 가려지거나, dim(어두운 막)이 너무 진해서 숫자가 안 보였어.

## 어떻게 풀었어?

### 1. 빌런 시각 자식만 1.4배 키우기 — DI(의존성 주입) 비유

DI(의존성 주입)는 *본체에 영향 주지 않고 끼워넣는 방식*이야. 본체 코드(생성자/AI/이동)는 그대로 두고, **`setupVisualOverlay()` 끝에 신규 메서드 한 줄만 끼워넣어** 자식들을 일괄 setScale 처리했어.

```swift
// EnemyNode.swift (수간호사)
private func setupVisualOverlay() {
    attachHalo()        // 외곽 후광
    attachChart()       // 차트 (클립보드)
    attachClip()        // 코랄 클립
    applyVisualScaleV9() // ← Sprint 9 Phase C 신규
}

private func applyVisualScaleV9() {
    for child in children {
        child.setScale(GameConfig.enemyVisualScaleV9)  // 1.4
    }
}
```

**왜 본체 size를 안 키우고 자식만 키웠어?**
- 본체 `SKSpriteNode.size` ≒ Spring의 `@Column(nullable=false)` 컬럼. 이걸 키우면 **`physicsBody`(충돌 영역)도 같이 커져서 게임이 깨져**. hitbox가 커지면 다른 오브젝트랑 부딪히는 거리가 달라지니까.
- 자식의 `setScale()`은 **transform(좌표 변환)만 변경**. 본체 size·physicsBody 무관. 마치 Spring의 `@Transient` 필드처럼 — DB에는 안 들어가고 표현용으로만 쓰는 거야.

같은 패턴을 이교수(ProfessorNode), 석조무사(StoneGuardNode)에도 적용했어. 3 빌런 모두 똑같이 1.4배.

### 2. 카운트다운 표시 명시 set — "기본값을 믿지 마라"

Spring 부트에서 `application.yml`에 값을 안 적어도 기본값으로 동작하지? 그것처럼 SpriteKit도 `position`은 기본 `.zero`고 `isHidden`은 기본 `false`야. 하지만 **이전 씬 잔존 상태나 외부 set 가능성** 때문에 명시적으로 4가지를 다시 set해서 안정성을 높였어.

```swift
let node = CountdownNode()
node.position = .zero                                 // 카메라 정중앙
node.zPosition = GameConfig.countdownNodeZPositionV9  // 300 — 모든 UI 위
node.isHidden = false                                 // 숨김 해제
node.alpha = 1.0                                      // 완전 불투명
cameraNode.addChild(node)
```

- `zPosition 250 → 300`: HitFlash(200)·HUD 위에 올라가서 카운트다운이 다른 노드에 절대 안 가려져.
- `dim alpha 0.32 → 0.22`: 어두운 막을 조금 더 투명하게 → 숫자(`coralPrimary`/`navyDeep`)가 더 또렷이 읽혀.
- `dim zPos 240 → 290`: dim도 같이 위로 올려서 CountdownNode(300) 바로 아래 깔리게.

### 3. 진단 print를 `#if DEBUG`로 감싸기 — release 빌드에서는 사라지게

`print("[Phase E] ...")` 같은 진단 로그는 Sprint 8 Phase E에서 디버깅용으로 6줄 박았어. 디버그 빌드에선 유용하지만 **출시(release) 빌드에선 콘솔을 더럽히고 약간의 성능 손해**가 있어.

Spring에서 `@Profile("dev")` 어노테이션으로 "개발 환경에서만 빈을 만든다"는 거 알지? Swift도 똑같이 `#if DEBUG ... #endif`로 감싸면 **release 빌드에서는 컴파일 자체가 안 됨** — 코드가 사라져.

```swift
#if DEBUG
print("[Phase E] showCountdown invoked at gameState=\(gameState)")
#endif
```

6개 print 전부 이렇게 감쌌어.

## 매직 넘버는 모두 GameConfig에

1.4, 300, 290, 0.22 — 이 숫자들을 코드에 직접 안 쓰고 전부 `GameConfig` 상수로 빼놨어. Spring의 `@Value("${...}")`처럼 한 곳에서 관리. 6종 신규:

```swift
static let enemyVisualScaleV9: CGFloat = 1.4         // 수간호사 자식 scale
static let professorVisualScaleV9: CGFloat = 1.4     // 이교수 자식 scale
static let stoneGuardVisualScaleV9: CGFloat = 1.4    // 석조무사 자식 scale
static let countdownNodeZPositionV9: CGFloat = 300   // 카운트다운 노드 층
static let countdownDimZPositionV9: CGFloat = 290    // 어두운 막 층
static let countdownDimAlphaV9: CGFloat = 0.22       // 어두운 막 진하기
```

값을 다시 조절하고 싶을 때 코드 한 곳만 바꾸면 돼. **변경 비용이 1줄**.

## 절대 안 건드린 것들

- Sprint 8 Phase G에서 박았던 `self.color = .clear; self.colorBlendFactor = 1.0` 2줄(빌런 3종 각각 보존). 이게 사라지면 본체 픽셀이 다시 나타나서 시각 자식과 겹쳐서 지저분해져.
- `CountdownNode.swift` 본체. git diff 0줄. 우린 *바깥에서 외부 set로 덮어쓰기*만 했어. 본체 init의 `zPosition = 250`도 그대로 — 바로 직후에 300으로 덮어쓰니까 결과는 300.
- `physicsBody`, `categoryBitMask`, `contactTestBitMask` — 충돌 정책 한 줄도 안 바꿈. hitbox 회귀 0.
- `PlayerNode` 전체.

## Spring 비유 정리표

| Swift/SpriteKit 개념 | Spring 부트 비유 |
|---|---|
| `child.setScale()` (transform) | `@Transient` 필드 — DB 무영향 표시용 |
| `SKSpriteNode.size` | `@Column(nullable=false)` 핵심 컬럼 |
| `physicsBody` size | DB 인덱스 — 잘못 바꾸면 모든 쿼리(충돌)가 깨짐 |
| `GameConfig.enemyVisualScaleV9 = 1.4` | `application.yml`의 `enemy.visual.scale=1.4` |
| `#if DEBUG ... #endif` | `@Profile("dev")` — 환경별 코드 분리 |
| 본체 노드 보호(CountdownNode) | `final class` + 시그니처 안 깨고 호출부만 수정 |
| `setupVisualOverlay()` 끝에 `applyVisualScaleV9()` 한 줄 추가 | DI 컨테이너에 빈 하나 더 등록 — 기존 빈 무영향 |

## 빌드 결과
`xcodebuild ... build` → **BUILD SUCCEEDED**.

## 다음 Phase에서 기억할 것
- 빌런 자식 1.4배는 *시각만*이라는 점. AI/이동 튜닝이 필요하면 자식 scale이 아니라 GameConfig의 속도·거리 상수로.
- 카운트다운 zPos 300은 HitFlash(200)·HUD(100) 위. 새 UI 노드 추가 시 zPos 300 이하로 두면 카운트다운에 안 가려져.
- `#if DEBUG` wrap은 진단 print 표준 패턴 — 새 진단 로그 추가 시 무조건 wrap.
