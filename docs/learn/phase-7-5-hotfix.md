# Phase 7-5 학습 노트 — 시뮬레이터 핫픽스 4건

## 오늘 고친 것

시뮬레이터에서 4가지 이상이 있었어요:

1. **카드 잘림** — 작은 화면에서 캐릭터 카드 5장 일부가 화면 밖
2. **컷씬 매번 떠서 짜증** — 게임 시작마다 "병동의 오후" 컷씬 강제
3. **졸업장 위치 어긋남** — 작은 화면에서 졸업장이 화면 가장자리에 붙음
4. **종료화면 터치 경합** — 졸업장 떠있는데 탭하면 TitleScene으로 같이 넘어갈 위험

한 sprint에 묶어서 모두 수정. 변경 *3 파일 40줄*만.

## "값만 바꿔도 동작이 바뀐다" — GameConfig의 힘

Phase 7-1에서 카드 위치를 GameConfig 상수로 빼뒀어요. 그게 오늘 살렸어요. 카드 자체 코드(`DifficultyCardNode`, `CharacterCardNode`)는 *한 줄도 안 건드리고* GameConfig 숫자 3개만 바꿨어요:

```diff
- difficultyCardOffsetY: CGFloat = -120
+ difficultyCardOffsetY: CGFloat = +80

- characterCardOffsetY: CGFloat = -200
+ characterCardOffsetY: CGFloat = -160

+ titleLabelOffsetY: CGFloat = 120 // 신규
```

이 *3개 숫자*로:
- 난이도 카드가 *위쪽*으로 이동 (titleLabel 아래, bestLabel 위)
- 캐릭터 카드가 *원래 자리*(-160)로 복귀
- titleLabel은 *위로 더* 이동해 자리 양보

코드는 *0줄 변경*. 작은 화면에서도 안전한 레이아웃 완성.

**Spring 비유** — `application.yml` 의 값만 바꿔도 빈의 동작이 바뀌는 것. *외부 설정 분리* 의 보상이 오늘 같은 상황. 미래에 *추가 디바이스 대응* 도 GameConfig 하나만 보면 됨.

## "최초 1회만" — UserDefaults bool 플래그

Phase 7-3에서 컷씬을 *매번* 표시하도록 만든 게 사용자에게 너무 강제적이었어요. 수정:

```swift
// didMove 끝부분
let hasSeenIntro = UserDefaults.standard.bool(forKey: GameConfig.hasSeenIntroCutsceneUserDefaultsKey)
if hasSeenIntro {
    gameState = .countdown
    showCountdown()           // 두 번째 이상 — 곧장 카운트다운
} else {
    gameState = .cutscene
    showIntroCutscene()        // 최초 1회만
}

// onDismiss 안
UserDefaults.standard.set(true, forKey: GameConfig.hasSeenIntroCutsceneUserDefaultsKey)
// → 다음 게임부터는 hasSeenIntro = true → 컷씬 스킵
```

**Apple 보장**: `UserDefaults.bool(forKey:)` 는 키가 *없으면* false 반환. 그래서 *첫 사용자*는 자동으로 false → 컷씬 표시 → onDismiss에서 true set → 영원 스킵.

**Spring 비유** — `@Conditional` 으로 *최초 실행 시에만* 빈을 만드는 것. 일종의 *one-shot* 패턴.

## "좌표계가 다른 두 세계" — frame vs size

ResultScene 좌표 문제는 *프레임워크 함정*이에요. SpriteKit에서:

- **`scene.size`** = `(1024, 768)` *고정값* (factory에서 지정)
- **`scene.frame`** = view 크기에 따라 *동적* (iPhone SE = 640×480, iPad = 더 큼)

졸업장의 background는 `scene.size` 기준으로 만들어요(1024×768 SKSpriteNode). 그런데 *위치*를 `frame.midX, frame.midY`로 주면? background는 1024×768 크기인데 위치는 *640×480 중심*에 가요. → 위치 불일치.

```diff
- anchor: CGPoint(x: frame.midX, y: frame.midY),
+ anchor: CGPoint(x: size.width / 2, y: size.height / 2),
```

이제 *크기*와 *위치* 둘 다 `scene.size` 기준. 어떤 디바이스든 동일.

**Spring 비유** — 두 개의 다른 *컨텍스트* (`@RequestScope` vs `@SessionScope`) 에서 같은 빈을 쓰면 안 됨. *기준점 통일*이 필수. SpriteKit의 size/frame도 마찬가지.

## "노드 이름으로 살아 있는지 알기"

졸업장이 떠 있는 동안 ResultScene 자체의 터치도 작동하면 *졸업장 탭이 TitleScene으로 넘어가는* 결과. 해결:

```swift
override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard !isTransitioning else { return }
    // ↓ 신규
    if children.contains(where: { $0.name == "diplomaOverlay" }) { return }
    // 나머지 기존 로직
}
```

졸업장 노드는 자기 init에서 `name = "diplomaOverlay"` 를 박아둬요. ResultScene이 *children 중 그 이름의 노드가 있으면* 자기 터치는 무시.

**Spring 비유** — `@Order` 또는 `@Primary` 처럼 *우선순위*를 명시. 더 *위*에 있는 노드(졸업장)가 살아 있으면 *아래*(ResultScene)는 자기 일 안 함.

## 회귀 0의 마법 — 변경 3 파일

이번 sprint:
- `GameConfig.swift` — 값 3개 + 새 키 1개
- `GameScene.swift` — if/else + UserDefaults set
- `ResultScene.swift` — anchor 변경 + 가드 1줄

다른 *30+ 파일*은 git diff **0줄**. 노드 코드(DifficultyCard, CharacterCard, DiplomaOverlay)는 *값 변경에 따라 자동 재배치*해서 코드 변경 0.

이게 *외부 설정 분리* 의 진짜 가치예요. *내용*과 *설정*이 분리되어 있으면, *설정만 바꿔서* 큰 동작 변경이 가능. 코드 위험 폭증 안 함.

## 오늘의 한 줄

> *"외부 설정 3개와 UserDefaults 플래그 1개로, 4가지 버그가 30+ 파일을 건드리지 않고 자연 차단된다."*
