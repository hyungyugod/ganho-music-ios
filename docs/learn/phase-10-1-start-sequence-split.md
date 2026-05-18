# Phase 10-1 학습 노트 — 시작 시퀀스 4단계 분리

## 1. 한 줄 요약

게임 시작 전에 보이던 한 화면(타이틀)이 너무 빽빽해서, **난이도 → 캐릭터 → 스킬 → 경고**의 4개 화면으로 쪼갰어요. 한 화면당 하나만 결정하면 되니까 머리가 안 복잡해집니다.

## 2. 이게 왜 필요한가? — 게임 디자인 의도

원래 타이틀 화면은 이런 모습이었어요:

- 제목 "김간호는 음악박사"
- 최고기록 / 플레이 횟수
- 캐릭터 카드 5장 (가로 일렬)
- 난이도 카드 3장 (가로 일렬)
- "TAP TO START" 안내

가로 화면 한 곳에 정보가 너무 많아서 **눈이 어디부터 봐야 할지 모르겠는** 상태였어요. 그래서 다음처럼 나눴습니다.

```
StartScene          → 난이도만 고른다 (3장)
CharacterSelectScene → 캐릭터만 고른다 (5장 + 짧은 태그)
SkillExplanationScene → 그 캐릭터 스킬을 *읽는다* (큰 아바타 + 설명)
GameScene 안의 경고 컷씬 → "조심해" 경고 (적이 누구인지 알린다)
```

이렇게 하면 화면 하나하나가 **한 가지 일에만 집중**해서 보기 편해져요.

## 3. 핵심 개념 5가지 (Spring 비유)

### 3.1 SKScene 분할 = 컨트롤러 분할

원래 `TitleScene.swift` 안에 캐릭터 5장 + 난이도 3장 + 라벨 4개 + 터치 처리가 다 들어 있었어요. 마치 Spring에서 `/title` 하나의 컨트롤러 메서드 안에 **회원가입 + 로그인 + 메인 페이지** 로직을 다 욱여넣은 거랑 똑같아요.

**Spring 비유**:
```java
@Controller
public class TitleController {
    @GetMapping("/title")
    public String all(/* 모든 파라미터 */) {
        // 30가지 분기 처리...
    }
}
```

이걸 깔끔하게:
```java
@Controller class StartController       { @GetMapping("/start") ... }
@Controller class CharacterController   { @GetMapping("/character") ... }
@Controller class SkillController       { @GetMapping("/skill") ... }
```

Swift/SpriteKit에서도 똑같이 `StartScene` / `CharacterSelectScene` / `SkillExplanationScene` 3개 씬으로 쪼갰습니다. 각 씬은 자기 일만 알아요.

### 3.2 init 인자 = 컨트롤러 PathVariable

씬 사이를 넘어갈 때 데이터(난이도, 캐릭터)를 전달해야 합니다. Spring이라면 URL path variable로 전달하죠:

```java
@GetMapping("/character/{difficulty}")
public String selectCharacter(@PathVariable Difficulty difficulty) { ... }
```

Swift에서는 **init 인자**로 전달합니다:
```swift
private init(size: CGSize, difficulty: Difficulty) {
    self.difficulty = difficulty
    super.init(size: size)
}

class func newCharacterSelectScene(difficulty: Difficulty) -> CharacterSelectScene { ... }
```

여기서 중요한 게 `self.difficulty`를 `let`(상수)으로 만들었다는 점이에요. 한 번 받으면 **씬이 살아있는 동안 바꿀 수 없어요**. Spring의 `@PathVariable`처럼 요청 안에서 변하지 않는 입력값이죠.

### 3.3 카드 외부 라벨 — "건드리지 않고 옆에 둔다"

요구사항 중 하나가 "CharacterCardNode 내부를 바꾸지 마라"였어요. 카드 *안에* 태그 글자를 넣고 싶었지만, 카드를 수정하면 다른 곳에서 쓰는 카드도 영향을 받거든요.

**Spring 비유**: 이미 다른 서비스 5곳에서 쓰는 `UserDTO`를 바꾸기 무서워서, 새 정보를 별도 `UserTagDTO`로 만들어서 응답에 같이 끼워 보내는 거예요.

Swift에서는 이렇게 했어요:
```swift
// 카드는 그대로 둔다
let card = CharacterCardNode(id: id)
addChild(card)

// 같은 좌표 + 아래쪽 -45pt에 *별도* SKLabelNode 추가
let label = SKLabelNode(text: id.tag)
label.position = CGPoint(x: card.position.x, y: card.position.y - 45)
addChild(label)
```

카드 코드는 한 줄도 안 건드렸지만, 화면상으로는 카드 아래에 태그가 붙어 보입니다.

### 3.4 PixelSpriteRenderer 재사용 = 같은 함수, 큰 출력

스킬 설명 화면에서 큰 아바타(120×150 픽셀)를 보여줘야 했어요. 게임 안에서는 작은 16×20 픽셀로 그리던 캐릭터를 그대로 **7.5배 확대**해서 표시한 거예요.

```swift
// 게임 안 PlayerNode와 똑같은 코드:
let frame = PixelSprite.data(for: characterID, direction: .down, frame: .idle)
let palette = PixelPalette.palette(for: characterID)
let texture = PixelSpriteRenderer.texture(from: frame, palette: palette)

// 차이점은 SKSpriteNode.size만 키운다:
self.avatarSprite = SKSpriteNode(texture: texture)
self.avatarSprite.size = CGSize(width: 120, height: 150)  // 게임 안 16×20 → 120×150
```

**Spring 비유**: 같은 `UserService.findById(id)`를 호출하지만, 한 곳에서는 작은 카드용 DTO로, 다른 곳에서는 상세 페이지용 큰 DTO로 변환해서 쓰는 거예요. **데이터 소스(서비스 메서드)는 하나**, 표현만 다르게.

확대해도 픽셀이 흐려지지 않는 비밀은 `filteringMode = .nearest`에 있어요. 보통은 부드럽게 흐리는데(`.linear`), 픽셀 아트는 **계단 모양** 그대로 보존해야 하니까 `.nearest`로 둔 거죠.

### 3.5 컷씬 재사용 — 같은 그릇에 다른 음식

석조무사 경고 컷씬을 새로 만들 때, **새 노드 클래스를 만들지 않고** 기존 `CutsceneOverlayNode.present(title:body:...)`를 그대로 호출했어요.

```swift
// 기존 (Phase 9-7): 이교수 경고 (상 난이도)
CutsceneOverlayNode.present(
    title: GameConfig.professorWarningTitle,  // "경고 · 이교수 출현"
    body: GameConfig.professorWarningBody,
    ...
)

// 신규 (Phase 10-1d): 석조무사 경고 (하/중 난이도)
CutsceneOverlayNode.present(
    title: GameConfig.stoneGuardWarningTitle,  // "경고 · 석조무사 출현"
    body: GameConfig.stoneGuardWarningBody,
    ...
)
```

**Spring 비유**: 똑같은 `NotificationService.send(title, body)` 메서드를 호출하면서 텍스트만 바꿔 보내는 거예요. 알림 시스템 자체는 한 번 만들면 끝, 새 알림이 필요할 때마다 텍스트 상수만 추가하면 됩니다.

이런 식으로 코드 안 늘리고 기능만 늘리는 걸 **재사용**이라고 부르는데, 이번 sprint에서 새 노드 0개 추가하고 컷씬을 새로 띄울 수 있었어요.

## 4. 흐름도 — 사용자가 게임 시작하기까지

```
앱 시작
  ↓
[StartScene]
  - 난이도 선택 (하/중/상)
  - "시작" 버튼 탭
  ↓
[CharacterSelectScene]
  - 5명 중 한 명 선택
  - "이 친구로 시작" 탭
  ↓ 김간호(.kim)면 ──────→ [GameScene] 직진 (스킬 없음)
  ↓
[SkillExplanationScene]
  - 큰 아바타 + 스킬명 + 설명 + 조작 안내
  - "시작" 탭
  ↓
[GameScene]
  ↓
인트로 컷씬 (첫 진입만, hasSeenIntro=false일 때)
  ↓
경고 컷씬 (매 판)
  - 하/중: 석조무사 경고
  - 상: 이교수 경고
  ↓
3-2-1-GO! 카운트다운
  ↓
실제 게임 시작
```

각 화면 좌상단에는 "← 다시 가기" 버튼이 있어서, 잘못 골랐을 때 한 단계 뒤로 갈 수 있어요.

## 5. 이번에 처음 등장한 SpriteKit 패턴

### 5.1 numberOfLines + preferredMaxLayoutWidth

스토리 박스 안에 긴 한국어 문장을 넣을 때, 자동 줄바꿈이 필요했어요. iOS 11+ 부터는 SKLabelNode가 자동 줄바꿈을 지원합니다.

```swift
bodyLabel.numberOfLines = 0  // 줄 수 무제한
bodyLabel.preferredMaxLayoutWidth = 400  // 이 폭을 넘으면 줄바꿈
```

**두 줄을 다 설정해야** 작동합니다. 한 줄만 빼먹으면 줄바꿈 안 됨.

### 5.2 isTransitioning 가드

씬 전환 중에 사용자가 또 탭하면 같은 씬을 두 번 띄우는 버그가 생길 수 있어요. 그래서 모든 씬에 `isTransitioning` 플래그를 둡니다.

```swift
private var isTransitioning = false

override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard !isTransitioning else { return }  // 이미 전환 중이면 무시
    // ... 전환 시작 직전에:
    isTransitioning = true
    view.presentScene(nextScene, transition: fade)
}
```

씬은 ARC가 정리하니까 `false`로 다시 돌릴 필요 없어요. 새 씬은 새 인스턴스(`isTransitioning = false`)로 시작합니다.

### 5.3 guard let view = self.view

`SKScene.view`는 옵셔널이에요(`SKView?`). 강제 언래핑(`!`)을 쓰면 크래시 위험. 항상 guard let:

```swift
guard let view = self.view else { return }
view.presentScene(nextScene, transition: fade)
```

`self.view`가 `nil`인 시나리오는 드물지만(씬이 SKView에 부착되기 전 상태), 0.0001% 확률 크래시도 막아야 해요.

## 6. .pbxproj 수정 — Xcode 프로젝트에 새 파일 등록

새 Swift 파일을 만들기만 하면 안 됩니다. **Xcode 프로젝트 파일(`.pbxproj`)에도 등록**해야 컴파일 대상에 포함돼요.

`.pbxproj`는 4개 섹션이 있는데, 새 파일 1개당 4곳 다 추가해야 합니다:

1. **PBXBuildFile** — "이 파일을 빌드해라" 선언
2. **PBXFileReference** — "이 파일이 디스크 어디 있는지" 선언
3. **PBXGroup** — "Xcode 좌측 트리에서 어느 폴더 아래" 선언
4. **PBXSourcesBuildPhase** — "어느 타겟이 이 파일을 컴파일하는지" 선언

이번에 새 파일 6개를 추가하고 TitleScene 1개를 제거했으니, **(6 추가 + 1 제거) × 4 위치 = 28 줄** 변경이 필요했어요. 빌드 한 번 통과시키는 데 가장 손이 많이 가는 부분이었습니다.

**Spring 비유**: 새 클래스를 만들기만 하면 안 되고, `pom.xml` / `build.gradle`에 의존성 등록도 해야 컴파일 대상이 되는 것과 비슷해요. 다만 Swift는 의존성이 아니라 *파일 자체*를 일일이 등록한다는 차이가 있죠.

## 7. 다음 단계

이번 sprint로 **타이틀 진입 → 게임 시작**까지의 흐름이 4단계로 깔끔해졌어요. 다음 Phase는:

- **Phase 10-2**: 결과 화면 분리 — 점수 / 베스트 / 통계를 카드로 쪼개기?
- **Phase 10-3**: HUD 재구성 — 현재 한 줄짜리 정보를 1줄로?

GDD §3 화면 흐름 시리즈가 끝나면, 다음은 게임 *안* 의 시각 다듬기로 들어갑니다.
