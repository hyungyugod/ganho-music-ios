# Phase 8-2 학습 노트 — 수간호사 픽셀 아트 이식

## 오늘 만든 것

게임 안에서 *핏빛 사각형*이었던 수간호사가 **백발 + 안경 + 간호사 캡 픽셀 아트**가 됐어요.

```
....KKKKKKKK....      ← 간호사 캡 상단
...KKKKXXKKKK...      ← 캡 + 코럴 십자
..KkkkkkkkkkkK..      ← 캡 밑단 음영
..HHSSSSSSSSHH..      ← 이마 + 백발
..hSGGSSSSGGSh..      ← 안경테
..hSGgSSSSgGSh..      ← 안경 렌즈
..hSSNSSSSNSSh..      ← 눈 밑 주름
..hSSSSMMSSSSh..      ← 입
..hhSSNNNNSSHh..      ← 팔자 + 턱선
...UUUUUUUUUU...      ← 흰 간호사복
..UUUUVCCVUUUU..      ← 옷깃 + 코럴 십자
```

4방향 회전 + 걷기 애니메이션. 김간호 + 4명 캐릭터에 이어 수간호사도 *원본 픽셀과 정확히 동일*. 게임 안 화면이 *진짜 게임처럼* 보여요.

## "인프라 재사용"의 진짜 가치

Phase 8-1에서 만든 도구 3개:
- `PixelSprite` (데이터)
- `PixelPalette` (색)
- `PixelSpriteRenderer` (그리기 엔진)

이번 sprint에서 **PixelSpriteRenderer는 한 줄도 안 바꿨어요**. PixelSprite와 PixelPalette는 *확장(extension)*만. EnemyNode는 PlayerNode 패턴을 *복붙* 수준으로 답습.

```swift
// PlayerNode가 했던 것
private var pixelDirection: PixelDirection = .down
private var pixelFrame: PixelFrame = .idle
private var frameAccumulator: TimeInterval = 0

func updatePixelDirection(_ velocity: CGVector) { ... }
func tickWalkFrame(deltaTime: TimeInterval, isMoving: Bool) { ... }
private func refreshTexture() { ... }

// EnemyNode가 하는 것 — 거의 동일
private var pixelDirection: PixelDirection = .down
private var pixelFrame: PixelFrame = .idle
private var frameAccumulator: TimeInterval = 0

func updatePixelDirection(_ velocity: CGVector) { ... }
func tickWalkFrame(deltaTime: TimeInterval, isMoving: Bool) { ... }
private func refreshTexture() { ... }
```

차이는 *texture를 만들 때 쓰는 데이터*뿐:
- PlayerNode: `PixelSprite.data(for: currentCharacterID, ...)`
- EnemyNode: `PixelSprite.nurseChiefData(...)`

**Spring 비유** — `JpaRepository<User, Long>` 와 `JpaRepository<Order, Long>`. 도메인만 바뀌고 *인프라 코드는 한 줄도 안 바뀜*. 추상화의 보상.

## EnemyNode는 *자기 update에서 자기 처리*

PlayerNode는 GameScene이 매 update에서 호출해줘요:
```swift
// GameScene.update
player.updatePixelDirection(player.physicsBody?.velocity ?? .zero)
player.tickWalkFrame(deltaTime: dt, isMoving: ...)
```

EnemyNode는 *자기가 알아서* 합니다. 왜냐면 EnemyNode는 *원래* GameScene에서 `enemy.update(deltaTime:targetPosition:speedT:)` 형태로 호출되고 있었거든요. 그 안에서 픽셀 갱신을 함께 처리:

```swift
// EnemyNode.update 내부
func update(deltaTime: TimeInterval, targetPosition: CGPoint, speedT: CGFloat) {
    // ... 기존 추적 로직 ...
    let velocity = physicsBody?.velocity ?? .zero
    updatePixelDirection(velocity)
    tickWalkFrame(deltaTime: deltaTime, isMoving: hypot(velocity.dx, velocity.dy) > 1.0)
}
```

**GameScene 코드 변경 0줄**. EnemyNode가 자기 책임을 가져갔어요.

**Spring 비유** — *Tell, Don't Ask*. 호출자가 *값을 물어보고 처리*하는 게 아니라 *객체에게 하라고 시키는* 패턴. EnemyNode는 자기 픽셀이 자기 책임.

## "유니크 키 14개" 함정

원본 game.js에는 *15개 키*가 정의돼 있어요:
- S/N/H/h/K/k/X/G/g/U/V/C/P/B/M

근데 `P`(하의)와 `U`(흰 간호사복)이 *같은 hex 값* (#f4f0ee). 이유: 수간호사는 *위아래 모두 흰 간호사복*이라 분리 의미 없음. game.js가 `'P': '#f4f0ee', 'U': '#f4f0ee'` 같은 *명목상 중복*을 둔 거예요.

우리는 `U` 하나로 통일. *진짜 의미 있는 키는 14개*. SPEC도 14키로 명시.

**Spring 비유** — DTO에서 *동일 값을 가진 두 필드*를 *하나의 필드*로 합치는 정규화. 데이터의 *진짜 차원*을 파악하는 게 중요.

## 회귀 0의 끝판

이번 sprint:
- 변경 4 파일: PixelSprite (+ 70줄), PixelPalette (+30줄), ColorTokens (+50줄), EnemyNode (+60줄)
- 다른 *30+ 파일*은 git diff **0줄**

특히 *GameScene 0줄* 이 중요. Phase 8-1에서는 GameScene에 PlayerNode 픽셀 갱신을 위해 4줄 추가했어요. Phase 8-2에서는 EnemyNode가 *자기 처리* 라 GameScene에 *한 줄도 더 안 추가*. 더 깔끔.

**physicsBody / collisionBitMask / contactTestBitMask 정책 완전 보존**. 적이 시각적으로 32×40 픽셀 아트로 보여도 *충돌 판정 hitbox는 원래 크기 그대로*. 게임 로직 회귀 0.

**Spring 비유** — *Decorator Pattern*. 원본 객체의 *동작은 그대로*, 외관만 감싸서 새로운 시각 부여. 객체 책임은 분리.

## 다음에 남은 것

picel sprite 인프라는 이제 완성:
- ✅ PlayerNode 5캐릭터 (Phase 8-1)
- ✅ EnemyNode 수간호사 (Phase 8-2)
- 남음: StoneGuard 픽셀, F 투사체, 음표 디테일, throwArm 모션, 캐릭터 카드 아바타

같은 인프라(PixelSprite + PixelPalette + PixelSpriteRenderer)로 *모두* 가능. 데이터만 game.js에서 가져오면 *코드는 30분 안*에 끝나요.

## 오늘의 한 줄

> *"인프라를 한 번 잘 만들어두면, 다음 캐릭터는 *데이터만 추가*하면 끝 — PixelSpriteRenderer 0줄 변경, GameScene 0줄 변경의 보상."*
