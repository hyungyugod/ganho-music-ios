# Phase 9-6 — 화캉스 보너스(변기) 시스템

## 한 줄 요약

12초마다 15% 확률로 맵에 변기 1개가 튀어나오고, 만지면 음표 2개 먹은 만큼 점수와 콤보가 한꺼번에 오르는 *희소한 보너스 기회*를 추가했어요.

## 왜 만들었어요?

게임이 *음표 줍기 음표 줍기 음표 줍기*만 반복되면 지루해져요. 그래서 가끔 *깜짝 보너스*가 나타나면 "지금 갈까? 말까?"하고 고민하게 되거든요. 그 고민이 게임의 리듬을 만들어요.

변기로 정한 이유? "화장실 바캉스" 줄임말 = "화캉스". 간호 실습 중 화장실에서 잠깐 쉬던 작은 농담을 게임에 박았어요.

## 자전적 배경

저는 간호 실습할 때 너무 힘들어서 화장실에 5초씩 도망가곤 했어요. 그게 *바캉스*였어요. 게임 캐릭터(김간호)에게도 똑같이 그 작은 휴식을 선물한 거예요. 게임이 단순한 점수 게임이 아니라 *제 일기장*인 이유.

## 기술 구조 (Spring Boot 비교)

### 1. 새 충돌 카테고리 — Spring의 새 도메인 추가

`PhysicsCategory.bonus = 64`를 추가했어요. 기존 `player(1)`, `note(2)`, `enemy(4)` 같은 비트들 옆에 *7번째* 비트로 자리 잡았어요.

Spring으로 치면:
```java
// 기존
@Entity class Note {}
@Entity class Enemy {}

// 추가
@Entity class Bonus {}  // 새 도메인
```

기존 클래스는 *하나도* 안 건드렸어요. 옆에 새로 하나 추가만 했죠.

### 2. ToiletNode — 새 컴포넌트

변기 노드 자체에요. 픽셀 아트로 그려진 16×16 도자기 모양. PixelSpriteRenderer라는 이미 있는 도구를 *재활용*해서 만들었어요.

```swift
let texture = PixelSpriteRenderer.texture(
    from: PixelSprite.toiletData(),   // 변기 모양 데이터
    palette: PixelPalette.toiletPalette  // 색깔 매핑
)
```

Spring 비유: 이미 있는 `JpaRepository`를 그대로 쓰고, 새 엔티티에 맞는 인터페이스만 정의하는 패턴.

### 3. SpawnSystem — 새 메서드 4개 *추가만*

기존 `start()` 메서드는 *건드리지 않고* 끝에 한 줄만 더했어요:
```swift
startToiletSpawnLoop()  // ← 추가
```

기존 음표 스폰 로직은 그대로. Spring으로 치면 `@PostConstruct` 메서드에 코드 한 줄 추가하는 정도. 회귀 위험 0.

### 4. ContactRouter — 콜백 추가 + 분기 추가

이건 Spring의 `@RestController`의 라우팅 매핑을 추가하는 것과 똑같아요:

```swift
// 기존
if categories & PhysicsCategory.enemy != 0 { onEnemyHit() }
if categories & PhysicsCategory.note != 0 { handleNoteContact() }

// 추가
if categories & PhysicsCategory.bonus != 0 { handleBonusContact() }  // ← 새 분기
```

`@GetMapping("/notes")` 옆에 `@GetMapping("/toilets")` 추가한 거랑 똑같아요.

### 5. ScoreSystem.recordToiletBonus — *이미 있는 메서드 재활용*

이게 가장 우아한 부분이에요. *점수 +2, 콤보 +2*를 직접 구현하지 않았어요:

```swift
func recordToiletBonus(at now: TimeInterval) {
    recordNoteHit(at: now)  // 한 번 호출 → 점수+1, 콤보+1
    recordNoteHit(at: now)  // 또 호출 → 점수+1, 콤보+1
}
```

Spring으로 치면 새 서비스 메서드 안에서 *기존 서비스 메서드를 2번 호출*하는 패턴. 트랜잭션도, 검증 로직도, 마일스톤 분기도 *모두 기존 로직이 자동으로 발화*해요. 새 코드 0줄, 재활용 100%.

## SpriteKit 핵심 패턴

### 1. SKAction 12초 루프 — Timer 절대 금지

iOS의 `Timer` 클래스는 SpriteKit 씬이 일시정지될 때 *멈추지 않아요*. 게임을 멈춰도 변기가 계속 튀어나오면 큰일이죠.

```swift
let wait = SKAction.wait(forDuration: 12)
let roll = SKAction.run { self?.tryRollAndSpawnToilet() }
let loop = SKAction.repeatForever(.sequence([wait, roll]))
scene?.run(loop, withKey: "spawnToilets")
```

씬이 일시정지되면 SKAction도 자연스럽게 멈춰요. 마치 Spring의 `@Scheduled`가 컨테이너 종료 시 자동으로 멈추는 것처럼.

### 2. 즉시 removeFromParent 금지

물리 충돌이 발생한 *바로 그 순간*에 노드를 트리에서 빼면 SpriteKit이 흔들려요. (`didBegin`이 노드 정보를 *사용하는 중*에 빼버리면 nil 참조)

해결: `SKAction.removeFromParent()`를 사용하면 *다음 프레임*에 안전하게 제거됩니다.

```swift
// 위험
toilet.removeFromParent()

// 안전
toilet.run(.removeFromParent())
```

Spring으로 치면 트랜잭션 안에서 즉시 commit하지 않고 `@TransactionalEventListener(AFTER_COMMIT)`로 미루는 패턴.

### 3. weak self 캡처

클로저(Spring의 람다)가 객체를 *강하게* 붙잡으면 메모리에서 객체가 영원히 안 사라져요. 그래서 `[weak self]`로 *느슨하게* 잡아요.

```swift
contactRouter.onToiletCollected = { [weak self] toilet in
    guard let self = self else { return }  // self가 사라졌으면 그냥 빠짐
    // ... 작업 ...
}
```

## 회귀 방지 (Sprint 범위 계약 준수)

Phase 9-1 ~ 9-5에서 만든 코드를 *0줄* 안 건드렸어요. 다음 7가지 추가만 했어요:
1. PhysicsCategory.bonus (1줄)
2. GameConfig 새 섹션 2개 (Toilet + Toast)
3. ColorTokens 3개 색
4. PixelSprite.toiletData (확장 메서드)
5. PixelPalette.toiletPalette (확장)
6. ToiletNode, ToastLabelNode (신규 파일 2개)
7. SpawnSystem/ContactRouter/ScoreSystem/PlayerNode/GameScene 콜백 *추가만*

기존 시그니처는 다 보존했어요. Spring으로 치면 *기존 API 엔드포인트는 그대로*, 새 엔드포인트만 추가한 거예요.

## 매직 넘버 정책 (=마법의 숫자)

코드에 `12`, `0.15`, `8` 같은 숫자를 직접 박으면 나중에 *이게 뭐였더라* 하게 돼요. 그래서 모든 숫자는 GameConfig에 *이름*을 붙여서 보관해요.

```swift
// 나쁜 예
let wait = SKAction.wait(forDuration: 12)

// 좋은 예
let wait = SKAction.wait(forDuration: GameConfig.toiletSpawnInterval)
```

Spring의 `application.yml`이랑 똑같은 정신. 설정은 *한 곳*에.

## 빌드 결과

```
** BUILD SUCCEEDED **
```

iPhone 17 시뮬레이터 Debug 빌드 통과. 신규 파일 2개가 Xcode 프로젝트에 정상 등록되었어요.

## 다음 Phase

9-7과 9-8이 남았어요. 변기 정도가 마지막 *깜짝 요소*인지, 더 큰 게임 시스템(예: 미니 보스, 새 맵)이 추가될지는 추후 결정.
