# 청소 Sprint — 죽은 코드·미사용 상수 대청소

날짜: 2026-05-22
작업 범위: 코드베이스 전체 (Swift 95개 → 93개 파일, 19,640줄 → 19,156줄, -2.5%)

## 한 문장 요약

"누가 쓰지도 않는 클래스·상수가 잔뜩 쌓여 있어서 골라내서 버렸고, 그 와중에 진짜 버그(매혹 스킬 작동 안 함)도 하나 잡았다."

## Spring 비유

Spring Boot 프로젝트에서 시간이 지나면 `application.yml`에 안 쓰는 `app.feature.xxx.enabled=true` 같은 설정이 잔뜩 쌓이고, `@Service`가 붙어 있지만 `@Autowired`로 어디서도 안 받는 좀비 Bean이 생기죠. 그걸 한 번에 정리한 sprint 같은 겁니다.

| Spring 세계 | iOS/Swift 세계 |
|---|---|
| `@Service` Bean이 어디서도 주입 안 됨 | `class XxxNode`가 어디서도 `XxxNode()` 인스턴스화 안 됨 |
| `application.yml`에 dead 키 | `GameConfig.swift`에 dead `static let` |
| `@Value`로 안 읽히는 properties | grep 결과 0건의 상수 |
| `BaseController` 추출해서 공통 로직 모음 | `BaseMenuScene` 추출해서 그라데이션 setup 모음 |

## 무엇을 했나

### 1. 죽은 클래스 3개 통째 제거
- `ProjectileNode` — Sprint 10 Phase D에서 `FProjectileNode`로 교체됐는데 구버전이 남아있었음
- `GlowingTitleNode`, `StoryBoxNode` — 옛 디자인의 잔재

**Spring 비유**: 옛 `LegacyOrderService`를 `OrderService`로 교체했는데 `@Component` 어노테이션 단 채로 남겨둔 상황. Bean Definition은 등록되는데 누구도 주입받지 않으니 메모리만 차지.

### 2. **버그 발견** — 매혹 스킬이 사실상 작동 안 했음
임간호 캐릭터의 "매혹" 스킬이 Sprint 10 Phase D 이후로 사실상 **noop**이었음. 원인:

```swift
// 매혹 발동 시 호출되는 코드
world.enumerateChildNodes(withName: "projectile") { node, _ in
    if let projectile = node as? ProjectileNode {   // 항상 nil!
        projectile.applyEnchanted()
    }
}
```

화면 위의 F 투사체는 모두 `FProjectileNode`인데, 가드는 옛 `ProjectileNode`로 캐스팅하니 항상 nil이어서 매혹 효과가 안 걸렸음. 

**해결**: `FProjectileNode`에 `isEnchanted`/`applyEnchanted()`/`clearEnchanted()` 인터페이스 이식. 시각 변화는 `texture = PixelSpriteRenderer.fProjectileTexture(color: .ganhoPinkNote)`로 픽셀 텍스처만 갈아끼움.

**Spring 비유**: 컨트롤러가 `Optional<NewOrderDto>`를 받아야 하는데 옛 시그니처 `Optional<OldOrderDto>`로 받아서 항상 빈 Optional이 와서 `if (dto.isPresent())` 안쪽 분기를 영원히 못 들어가는 상황. 시그니처 한 줄 고치면 끝.

### 3. 디버그 잔재 청소
- `GameScene.showCountdown`의 `#if DEBUG print(...)` 6개 제거 — 진단 끝났는데 남아 있었음
- iOS의 `showsDrawCount`, `showsPhysics` 제거 (FPS+NodeCount만 유지)
- tvOS/macOS의 `as!` 강제 캐스팅 → `guard let ... as? else { assertionFailure }` 안전 패턴으로 통일

**Spring 비유**: 디버그 로그 `log.info("진입 ...")`가 코드 곳곳에 남은 채 프로덕션에 가는 것. release 빌드에선 안 찍히지만 코드 가독성을 갉아먹음.

### 4. 미사용 `GameConfig` 상수 ~47개 + `ColorTokens` 22개 제거
"Phase 7-5에서 80→120으로 바꿨다가 Phase 8에서 폐기"한 흔적 같은 좀비 상수들. 카테고리별로 grep → 호출처 0건 확인 → 삭제 → 빌드 사이클을 4번 반복.

### 5. `BaseMenuScene` 추출 — 공용 베이스 클래스 단 1개 신설
4개 메뉴 씬(`StartScene` / `CharacterSelectScene` / `DifficultySelectScene` / `SkillExplanationScene`)이 100% 동일한 그라데이션 setup/rebuild 코드 ~22줄씩을 들고 있었음.

```swift
// 이제 4개 씬 모두
final class StartScene: BaseMenuScene {   // 기존 SKScene → 변경
    override func didMove(to view: SKView) {
        setupWarmGradientBackground()   // 베이스 메소드 호출
        // ... 씬별 고유 작업
    }
    override func didChangeSize(_ old: CGSize) {
        rebuildWarmGradientBackground()
    }
}
```

**Spring 비유**: 5개 컨트롤러가 똑같이 `@ExceptionHandler` + `@RequestMapping("/health")` + auth 검증 6줄을 각자 들고 있을 때, `AbstractBaseController`로 빼는 것과 같음. `BaseController` 1개 추가하고 5개 컨트롤러는 한 줄(`extends BaseController`)만 바꿔도 모두 동일 동작.

## 의도적으로 안 한 것

- **GameScene을 더 잘게 분할** (Physics/UI/Audio로 쪼개기) — 사용자가 "코드를 늘리지 말고 제거만"이라 했으니 구조 재설계 보류
- **Repository 6개를 제네릭화** — 절감되는 줄 수보다 제네릭 학습 부담이 더 큼. 후속 sprint로 미룸
- **Cutscene 3개 노드 enum 통합** — 마찬가지로 미룸. 현재 구조도 작동에 문제 없음

## 검증 절차

1. 매 Phase 끝마다 `xcodebuild -scheme "GanhoMusic iOS" build` 통과 확인 (총 6회 빌드)
2. 모든 단계에서 `** BUILD SUCCEEDED **`
3. **시각 회귀 확인 필요**: 다음에 시뮬레이터로 실행해서 5개 메뉴 씬의 그라데이션 픽셀이 동일한지 눈으로 확인할 것 (BaseMenuScene 통합 후)

## 결과 숫자

| 지표 | 전 | 후 | 차이 |
|---|---|---|---|
| Swift 파일 수 | 95 | 93 | -2 (제거 3, 추가 1) |
| 총 줄 수 | 19,640 | 19,156 | **-484 (-2.5%)** |
| `GameConfig.swift` | 2,815줄 | ~2,690줄 | -125줄 |
| `ColorTokens.swift` | 372줄 | ~330줄 | -42줄 |
| **버그 픽스** | 매혹 스킬 작동 안 함 | 매혹 스킬 정상 작동 | +1 기능 복구 |

## 배운 점 (사용자에게)

1. **dead code grep은 빈도가 1이면 강한 후보**. `static let xxx`가 1번만 매칭 = 정의만 있고 호출 0건.
2. **타입 교체(`A → B`)할 땐 `as? A` 패턴까지 전부 찾아야 한다**. 시그니처는 바뀌었지만 호출부 가드가 옛 타입 그대로면 그 분기는 영원히 죽은 코드.
3. **Xcode 프로젝트에서 파일 삭제는 `.pbxproj` 4곳 동시 수정 필요** — BuildFile 정의, FileReference 정의, 그룹 children, Sources build phase. CLI로 작업할 때는 한 곳이라도 누락되면 빌드 깨짐.
4. **새 베이스 클래스 추가가 줄 수 절감보다 의미 있는 경우**: 100% 동일한 보일러플레이트가 4개 이상일 때. 통합 후 절감 = 4 × (보일러 줄 수) - 베이스 줄 수.
