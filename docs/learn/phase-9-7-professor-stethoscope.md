# Phase 9-7 학습 노트 — 이교수 + 청진기 (상 난이도 전용)

## 1. 한 줄 요약

상 난이도(.hard)에서만 등장하는 두 번째 적 "이교수"를 추가했어요. 이교수는 청진기를 던지는데, 맞으면 죽지는 않고 **2초간 못 움직이게** 됩니다.

## 2. 이게 왜 필요한가? — 게임 디자인 의도

기존 상 난이도는 "수간호사 F가 더 많이 날아오는" 정도였어요. 이번에 두 번째 위협을 더해서, **두 곳을 동시에 신경 써야 하는** 부담을 만들었습니다.

- 청진기에 맞아도 죽지는 않습니다 (게임오버 X)
- 대신 2초간 멈춥니다 → 그 사이 수간호사 F가 날아오면 그대로 한 방
- "공포의 사슬" 톤 — 한 번의 실수가 다른 실수로 연쇄

## 3. 핵심 개념 5가지 (Spring 비유)

### 3.1 새 PhysicsCategory 비트 추가

```swift
static let stethoscope: UInt32 = 0b10000000  // 128
```

**Spring 비유**: 새 도메인 이벤트 타입을 추가하는 거예요. 기존 `enemy`/`projectile`/`note`는 그대로 두고, **청진기 전용 라우팅 키**를 하나 더 만든 셈입니다.

비트 마스크가 뭐냐면 — 각 위치 1자리에 다른 의미를 부여하는 거예요:
- `0b00000001` = 1 = 플레이어
- `0b00000010` = 2 = 음표
- ...
- `0b10000000` = 128 = 청진기

이렇게 하면 `OR(|)` 연산으로 여러 카테고리를 한 번에 표현할 수 있어요. 예를 들어 청진기는 "플레이어"랑 "벽"이랑 부딪힐 때 알려달라고 하면:
```swift
body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.wall
```

### 3.2 통과형 NPC — physicsBody 없음

이교수는 **physicsBody를 안 붙였어요**. 왜냐하면:
- 이교수가 직접 플레이어를 막거나 때릴 필요 없음
- 위협은 청진기(별개 노드)가 담당
- 4 waypoint 순찰만 하면 되니까 `SKAction.move`로 충분

```swift
// ProfessorNode.init() — physicsBody 부착 코드 없음
super.init(texture: initialTexture, color: .clear, size: visualSize)
name = "professor"
zPosition = 5
// physicsBody 미부착 — *통과형* NPC
startPatrol()
```

**Spring 비유**: REST 컨트롤러가 직접 DB를 안 만지고, **서비스에 위임**하는 패턴이에요. 이교수는 "순찰 + 명령 발사"만, 실제 위협은 청진기가 담당.

### 3.3 isFrozen 가드 — 최상단 early return

PlayerNode.update()에서 동결 가드는 **함수 맨 위**에 둡니다:

```swift
func update(deltaTime: TimeInterval) {
    if isFrozen {
        physicsBody?.velocity = .zero
        return  // ← 여기서 끝. 아래 코드는 안 봄.
    }
    // 기존 이동 로직 (이건 frozen 아닐 때만 실행)
    let speed = baseSpeedStart * speedMultiplier
    physicsBody?.velocity = CGVector(...)
}
```

**Spring 비유**: Controller에 `@PreAuthorize` 어노테이션 같은 거예요. 메서드 진입 직후 권한 체크해서 안 맞으면 **즉시 끊어내는** 가드 패턴.

왜 최상단이냐면 — 아래 코드가 실수로 velocity를 다시 set하면 동결이 풀려버려요. **early return**이 가장 안전합니다.

### 3.4 무적 우선 정책 — freeze는 무적 중에 무시

```swift
func freeze(duration: TimeInterval) {
    if isFrozen { return }         // 이미 동결 중이면 무시 (누적 X)
    if isInvulnerable { return }   // 무적 중이면 무시 (이간호 텔레포트)
    isFrozen = true
    ...
}
```

이건 우선순위 규칙이에요:
1. **무적 (isInvulnerable)** ← 최강. 청진기 맞아도 freeze 안 됨.
2. **동결 (isFrozen)** ← 2초 고정. 연사 맞아도 시간 누적 X.
3. **게임오버** ← F 한 발이면 끝.

**Spring 비유**: `@Order(1)`, `@Order(2)`로 Aspect 순서 매기는 거랑 비슷해요. 우선 처리할 사례를 먼저 가드해서 빠져나가는 패턴.

### 3.5 SKAction.run으로 1프레임 지연 제거

didBegin (충돌 콜백) 안에서 노드를 *즉시* 제거하면 SpriteKit이 부서질 수 있어요. 그래서 SKAction을 한 번 통과시킵니다:

```swift
// ❌ 위험 — 충돌 처리 중에 즉시 제거
node.removeFromParent()

// ✅ 안전 — 다음 프레임에 제거 (한 번 더 호흡)
node.run(.removeFromParent())
```

**Spring 비유**: 트랜잭션 진행 중에 같은 엔티티를 삭제하면 ConcurrentModificationException 같은 게 나잖아요? **트랜잭션 끝난 후 후처리로 미루는** 패턴.

## 4. 코드 구조 — 어디서 뭐가 일어나나

```
사용자가 hard 난이도 선택
  ↓
TitleScene → GameScene(difficulty: .hard)
  ↓
GameScene.didMove
  ├─ setupProfessor()  ← .hard일 때만 ProfessorNode 생성
  │   └─ professor.startThrowingStethoscopes(...)  ← SKAction 발사 루프 시작
  ↓
인트로 컷씬 ("어느 한적한 병동의 오후")
  ↓ 탭
인트로 dismiss → onDismiss 안에서 hard 분기
  ↓
이교수 경고 컷씬 ("경고 · 이교수 출현") ← Phase 9-7 신설
  ↓ 탭
카운트다운 3→2→1→GO!
  ↓
게임 시작 (이교수가 2.5초마다 청진기 던지기 시작)
  ↓
청진기가 플레이어에 명중
  ↓
ContactRouter.handleStethoscopeContact (신설 분기)
  ↓
contactRouter.onStethoscopeHitPlayer 콜백
  ├─ haptics.medium()
  ├─ cameraNode.run(CameraShakeAction.make())
  ├─ ToastLabelNode.spawn("청진기 명중!")
  ├─ player.freeze(duration: 2.0)
  └─ node.run(.removeFromParent())
  ↓
2초 동안 player.isFrozen = true → 이동 불가
  ↓ 2초 후
SKAction.run 콜백으로 isFrozen = false 복원
```

## 5. 회귀 방지 — 건드리지 않은 영역

이번 작업은 **상 난이도에서만** 동작합니다. easy/normal 게임은 전혀 영향받지 않아요:
- `setupProfessor()` 함수 첫 줄: `guard difficulty == .hard else { return }`
- `professor` 프로퍼티는 Optional → easy/normal에서는 `nil`
- `professor?.updatePixelAnimation(...)` ← `?`로 nil이면 자연 noop
- `professor?.stopThrowing(...)` ← 마찬가지

**Spring 비유**: 새 feature flag (`@ConditionalOnProperty`) 같은 거예요. 조건에 안 맞으면 빈(Bean) 자체를 안 만드니까, 다른 코드 경로에 영향 0.

## 6. 미리 알았으면 좋았을 함정

### 함정 1: PixelPalette 'P' 키 충돌

공통 팔레트에 `'P'`는 파란 하의(#9ec9e8)인데, 이교수는 **검은 바지**(#1f1a1f)예요. 같은 키 'P'를 다른 색으로 매핑해야 했습니다.

해결: `professorPalette`를 **별도 dict**로 만들면 됨. PixelSpriteRenderer는 호출할 때 단일 dict만 사용하니까 충돌이 안 일어나요.

### 함정 2: 입('M') vs 콧수염

기본 입은 `'M'` 키예요. 콧수염을 위해 또 새 키가 필요한데, `'M'`은 이미 입에 쓰이고 있어요.

해결: **소문자** `'m'`을 콧수염용 키로 분리. Swift Dictionary는 대소문자 구분하니까 안전.

### 함정 3: SKAction.move 기반에서 픽셀 방향 산출

EnemyNode는 `velocity` 부호로 방향을 정해요. 그런데 ProfessorNode는 `SKAction.move`로 움직이니까 velocity가 항상 0이에요!

해결: **이전 프레임 position과 비교**해서 변화량으로 방향 산출:
```swift
let dx = position.x - lastPosition.x
let dy = position.y - lastPosition.y
lastPosition = position
```

## 7. 빌드 검증

```bash
xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" \
  -scheme "GanhoMusic iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug build
```

→ **BUILD SUCCEEDED** ✓

## 8. 정리 — 한 줄로

> 상 난이도에 두 번째 적 "이교수"를 추가했어요. 청진기에 맞으면 2초 동결.
> easy/normal은 코드 0줄 영향. Optional 프로퍼티 + difficulty 가드로 완전 분리.
