# Phase 10-2 — 첫 화면 예쁘게 바꾸기 (병동의 새벽 톤)

## 한 줄 요약
**앱 켰을 때 첫 화면(StartScene)을 "회색 박스+글씨"에서 "그라데이션+떠다니는 음표+빛나는 제목"으로 업그레이드했어요.** 게임 동작은 한 줄도 안 바꿨어요. 단지 "보이는 모습"만 화장한 거예요.

---

## 왜 했어요?

플레이어가 앱을 켜자마자 보는 첫 화면이에요. 이게 후지면 "아 이 게임 별로네" 하고 첫인상이 망가져요. 마치 식당 가서 메뉴판이 종이 한 장에 매직으로 쓴 것 같으면 음식도 못 미더운 거랑 똑같아요.

기존엔 그냥 검정 배경에 흰 글씨, 회색 박스, 시스템 폰트뿐이었어요. 모던 게임은 보통 4가지를 더 입혀요:
1. **분위기 있는 배경** (그라데이션, 파티클)
2. **글로우/빛 효과** (제목이 살짝 빛남)
3. **인터랙션 반응** (눌렀을 때 튕기는 느낌)
4. **부드러운 전환** (씬 바뀔 때 자연스러운 연결)

이번에 이 4개를 다 넣었어요.

---

## Spring Boot 비유

이번 작업은 Spring Boot로 치면 **"비즈니스 로직(Service/Repository)은 그대로, 뷰 템플릿(Thymeleaf/JSP)만 CSS 새로 입힌 것"** 과 똑같아요.

| Spring Boot | SpriteKit (이번 작업) |
|---|---|
| `@Service` 비즈니스 로직 | `selectDifficulty()`, `transitionToNext()` — **건드림 0** |
| `@Repository` 저장소 | `DifficultyPreferenceRepository.save()` — **건드림 0** |
| 뷰 템플릿 HTML 구조 | `setupLabels()`, `layoutDifficultyCards()` — **레이아웃 좌표 그대로** |
| CSS 색상 변수 | `ColorTokens.swift` (teal/coral 토큰 **추가만**) |
| CSS 애니메이션 | `SKAction` (pulse, fade, spring) |
| `<div class="card">` | `DifficultyCardNode` (시그니처 그대로, 안에 효과만 추가) |

핵심은 **"공개 API는 못 바꾼다"** 예요. Spring에서 컨트롤러 메서드 시그니처 바꾸면 프론트 다 깨지듯, 여기선 `DifficultyCardNode.init(id:)` / `setSelected(_:)` 시그니처를 바꾸면 `StartScene`이 호출하는 코드를 죄다 고쳐야 해요. 그래서 시그니처는 못 잠그고 **내부만** 새로 만들었어요.

---

## 들어간 5가지 효과

### 1. 그라데이션 배경
검정 단색 → **위는 진한 남색, 아래는 청록색**으로 부드럽게 변하는 배경.

마치 새벽 5시 병동 창밖처럼요. 게임 정체성("병동에서 작곡")과 어울려요.

**구현 방법**: `GradientBackgroundNode.swift` 새 파일을 만들었어요.
- `UIGraphicsImageRenderer`로 그라데이션 이미지를 **딱 한 번** 그려요.
- 그 이미지를 `SKTexture`로 만들어서 `SKSpriteNode`에 입혀요.
- Spring으로 치면 **@PostConstruct에서 캐싱된 빈** 같은 거예요. 매번 다시 그리면 GPU가 죽으니까요.

```swift
// 한 번만 텍스처 생성 → 화면에 깔기
private static func makeGradientTexture(...) -> SKTexture {
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { ctx in
        // CGGradient로 위→아래 색 그리기
    }
    return SKTexture(image: image)
}
```

### 2. 떠다니는 음표 파티클
화면 아래에서 ♪/♫/♩ 살구색 음표가 천천히 위로 떠올라요. 게임 정체성("음악")과 어울리는 장식이에요.

**구현 방법**: `MusicNoteEmitterNode.swift` 새 파일.
- `SKAction.repeatForever`로 0.5초마다 음표 한 개씩 뿌려요.
- **상한 가드**: 화면에 음표가 동시에 15개를 넘으면 더 안 뿌려요. 안 그러면 폰이 뜨거워져요.
- 음표는 8초 동안 위로 올라가다가 `fadeOut` → 자기 자신 `removeFromParent`. 메모리 청소까지 알아서 해요.

```swift
private func spawnOneNote() {
    guard activeCount < GameConfig.musicNoteEmitterMaxConcurrent else { return }
    // ... 음표 1개 생성 + 위로 이동 + 사라짐 ...
    activeCount += 1
}
```

Spring으로 치면 **Bounded Queue로 처리량 제한하는 것** 같아요. 무한정 만들면 시스템이 터지니까.

### 3. 제목 글로우 (빛남)
"김간호는 음악박사" 제목 뒤에 청록색 빛이 살짝 번져요. 평면 → 입체로 한 단계 점프.

**구현 방법**: `GlowingTitleNode.swift` 새 파일.
- 같은 글씨를 **두 번** 그려요. 뒤쪽 글씨는 청록색에 `CIGaussianBlur` 필터로 흐리게 → "빛 번짐" 효과.
- 앞쪽 글씨는 원래 색(흰색). 합치면 "글씨에서 빛이 나오는" 것처럼 보여요.
- **성능 트릭**: `shouldRasterize = true` — 블러를 매 프레임 다시 계산하지 말고 **한 번 계산한 결과를 캐싱**하라는 거예요. Spring의 `@Cacheable`이랑 똑같은 발상.

### 4. 난이도 카드 spring 반동 + 링 글로우
난이도 카드(쉬움/중간/어려움) 탭하면:
- 카드가 1.0 → **1.12** (살짝 더 커짐, 반동) → **1.08** (정착)로 튕겨요.
- 동시에 카드 외곽에 살구색 빛 링이 부드럽게 켜져요.

**왜?** "아 눌렀다"는 즉각 쾌감을 주려고요. 그냥 색만 바뀌면 밋밋한데, 살짝 튕기면 "오 반응한다"는 느낌이 와요. 모던 게임의 표준 패턴이에요.

```swift
// SKAction.sequence로 2단 액션
let overshoot = SKAction.scale(to: 1.12, duration: 0.18)
overshoot.timingMode = .easeOut
let settle = SKAction.scale(to: 1.08, duration: 0.12)
settle.timingMode = .easeInEaseOut
run(SKAction.sequence([overshoot, settle]))
```

이건 **CSS의 `cubic-bezier` + `keyframes`** 와 같은 개념이에요.

### 5. 시작 버튼 pulse + 씬 전환 슬라이드
- **시작 버튼**이 0.98 ↔ 1.02 크기로 천천히 숨 쉬듯 움직여요 (`repeatForever`).
- **씬 전환할 때** 카드들이 살짝 위로 슬라이드 + 페이드아웃 → 그 다음에 다음 씬으로 넘어가요. 화면이 "떠나간다"는 느낌.

Spring으로 치면 **인터셉터에서 응답 직전에 후처리 효과를 끼우는 것** 같아요.

---

## 색상 토큰 시스템

`ColorTokens.swift`에 3개 토큰을 **추가**했어요 (기존 토큰 변경은 0건):

```swift
static let ganhoAccentTeal     = UIColor(hex: "#5BD7CF")  // 청록 — 그라데이션, 제목 글로우
static let ganhoAccentTealDeep = UIColor(hex: "#1E3A4C")  // 딥블루 — 그라데이션 상단
static let ganhoAccentCoral    = UIColor(hex: "#FFB59A")  // 살구 — 음표, 링 글로우
```

Spring으로 치면 **`application.yml`에 새 프로퍼티를 추가**한 거예요. 기존 프로퍼티 값은 안 건드리고 새 키만 추가. 그래서 기존 코드 영향 0.

---

## 매직 넘버 추방

수치는 **하나도** 코드에 직접 안 박았어요. 전부 `GameConfig.swift`에 상수로 정의:

```swift
static let titleGlowBlurRadius: CGFloat = 8.0
static let musicNoteEmitterMaxConcurrent: Int = 15
static let startButtonPulseScaleMin: CGFloat = 0.98
static let startButtonPulseScaleMax: CGFloat = 1.02
// ... 24개 상수 추가 ...
```

**왜 중요?** 디자이너가 "음표 좀 더 빨리 떠올랐으면 좋겠는데" 하면 `musicNoteEmitterRiseDuration: 8.0 → 5.0` 한 줄만 고치면 끝. 코드 곳곳에 박혀있으면 grep 지옥이에요. Spring의 `@Value("${app.config.something}")` 패턴과 똑같은 발상.

---

## 메모리 누수 예방 — `[weak self]`

모든 `SKAction.run { ... }` 클로저에 `[weak self]`를 붙였어요:

```swift
SKAction.run { [weak self] in
    self?.spawnOneNote()
}
```

**왜?** Swift는 클로저가 자기 바깥 객체(`self`)를 **강하게 붙잡으면** 그 객체가 영영 메모리에서 안 풀려요. Spring으로 치면 **`@Component` 빈끼리 서로 참조해서 GC가 못 지우는 상황**이랑 비슷.

`weak`를 붙이면 "약하게만 잡아라, 그쪽이 사라지면 nil로 쳐라"가 돼서 누수가 안 생겨요. 씬이 사라지면 모든 액션도 깔끔히 같이 사라져요.

---

## 강제 언래핑(`!`) 0건

```swift
// ❌ 이렇게 쓰면 안 됨
let blur = CIFilter(name: "CIGaussianBlur")!

// ✅ 이렇게 옵셔널로 안전하게
if let blur = CIFilter(name: "CIGaussianBlur") {
    blur.setValue(8.0, forKey: "inputRadius")
    glowEffect.filter = blur
}
```

**왜?** 강제 언래핑은 "이거 nil 아닐 거야"하는 도박이에요. nil이면 앱이 즉사. Spring의 `Optional.get()` 대신 `Optional.ifPresent(...)` 쓰는 거랑 같아요.

---

## 결과

- **QA 점수**: Swift패턴 10/10, 게임로직 10/10, 성능 10/10, 기능완성도 10/10 → **가중 10.0/10.0**
- **빌드**: `BUILD SUCCEEDED` (iPhone 17, iOS 26.5)
- **게임플레이 동작 변경**: 0건 (난이도 저장·다음 씬 호출·hit test 우선순위 전부 그대로)
- **QA 반복**: 1회 (한 번에 통과)

---

## 한 단계 더 — 다음에 할 수 있는 것

이번엔 StartScene만 했어요. 같은 패턴을 다음 화면들에도 입힐 수 있어요:
- `CharacterSelectScene` — 캐릭터 카드 5장도 spring + 링 글로우
- `SkillExplanationScene` — 스킬 설명에 더 화려한 등장 애니메이션
- `ResultScene` — 점수 결과에 글로우 + 파티클

신규 `GradientBackgroundNode`, `MusicNoteEmitterNode`, `GlowingTitleNode` 3개는 **재사용 설계**라 다른 씬에서도 그대로 갖다 쓰면 돼요. Spring의 공용 `@Service` 빈처럼요.

---

## 핵심 교훈

> **"비주얼 작업이라도, 게임 로직은 절대 안 건드린다"**

이번 작업의 가장 중요한 원칙이에요. 그라데이션 추가하다가 실수로 `selectDifficulty()` 호출 순서를 바꾸면? 저장이 깨져서 사용자 난이도 설정이 날아갈 수 있어요. 그래서:

1. SPEC에 **"불변 계약" 표**를 만들어서 못 건드릴 항목을 박아두고
2. 시그니처는 **절대** 안 바꾸고
3. 새 효과는 **외부에서 부착**하거나 **신규 노드로 분리**
4. 기존 상수는 **추가만**, 변경 0건

Spring으로 치면 **"리팩토링 시 public API는 무조건 하위 호환"** 의 SpriteKit 버전이에요. 이 원칙을 지키면 비주얼 작업이 게임 로직을 깨뜨릴 일이 0이 돼요.
