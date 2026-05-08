# 20 · Phase 3-3 · 결과 화면을 별도 씬으로 — ResultScene 🏁

> **이번 작업 한 줄**: 게임이 끝나면 같은 화면 위에 *모달처럼 떠 있던* 결과 패널을 **독립된 씬**으로 분리한다. 점수는 *생성자(init)*로 다음 씬에 넘긴다.

---

## 1. 왜?

지난 sprint(3-1+2)에서는 게임이 끝나면 `GameOverOverlayNode`(=반투명 패널)가 *같은 GameScene 위에* 떠올랐다. 이 방식은 빠르게 만들 수 있어서 좋았지만, 한 GameScene이 두 가지 책임을 동시에 진다.

1. 게임 진행 (player·enemy·spawn·점수)
2. 결과 표시 (오버레이 노드 + 입력 가드)

두 책임이 한 클래스 안에 섞여 있으면, 한 쪽을 고칠 때 다른 쪽이 영향을 받기 쉽다.

> Spring으로 치면, 한 컨트롤러에 `/play` 핸들러와 `/result` 핸들러가 같이 들어 있는 상태. **각자 다른 컨트롤러로 분리**하면 코드가 한결 깔끔해진다. 이번 sprint가 그 분리.

---

## 2. Spring 비유 ⭐

| SpriteKit | Spring | 한 줄 설명 |
|---|---|---|
| `ResultScene.newResultScene(score: 12)` | `redirect:/result?score=12` | 다음 화면(컨트롤러)에 데이터 전달하며 이동 |
| 씬의 `init(score:)` | 컨트롤러 메서드 인자 또는 `@RequestParam` | 새 컨트롤러가 데이터를 *생성 시* 받음 |
| 이전 GameScene이 ARC 해제 | 이전 요청 컨텍스트 종료 | 응답 끝나면 컨트롤러 인스턴스 사라짐 |
| `GameOverOverlayNode` 폐기 | 페이지 안 모달 → 별도 페이지로 승격 | 모달이었던 것을 풀스크린 페이지로 |

**핵심**: 한 씬이 한 화면을 책임진다. 데이터가 필요하면 *생성자에 명시적으로 넣어 주는 것*이 관용구.

---

## 3. 새로 배운 것 (Swift/SpriteKit) ⭐

### 3-1. **씬 간 데이터 전달 = init 주입**

```swift
// GameScene 안에서 게임이 끝났을 때
let resultScene = ResultScene.newResultScene(score: scoreSystem.score)
view?.presentScene(resultScene, transition: .fade(...))
```

```swift
// ResultScene
final class ResultScene: SKScene {
    private let finalScore: Int    // ← 생성 시 받음, 이후 변경 불가

    private init(size: CGSize, score: Int) {
        self.finalScore = score
        super.init(size: size)
        self.scaleMode = .resizeFill
    }

    class func newResultScene(score: Int) -> ResultScene {
        return ResultScene(size: CGSize(width: 1024, height: 768), score: score)
    }
}
```

**왜 init 주입이 좋은가?**
- 점수가 *불변* (`let`) → 표시 도중 누가 바꿀 일 없음
- 씬 생성 시점에 *반드시 점수가 있다*는 보장 → 옵셔널 처리/누락 분기 불필요
- 외부에서 `resultScene.score = 999`로 *조작 불가*

> Spring으로 치면 `@RequiredArgsConstructor` + `final` 필드. 또는 final field를 받는 생성자. 객체 *불변성* 확보.

### 3-2. **`required init?(coder:)`의 의미**

```swift
required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
}
```

이 줄은 "Storyboard나 .sks에서 자동 복원할 때 호출되는 생성자"다. 우리는 코드로만 씬을 만드므로 *호출되면 안 됨* → `fatalError`로 명시. **Swift가 강제로 요구**하는 boilerplate이지만, "이건 코드로만 쓰는 클래스"라는 표시 역할도 한다.

> Spring으로 치면 "JPA가 요구하는 protected 기본 생성자". 직접 호출 금지지만 형식상 존재해야 함.

### 3-3. **`SKTransition.fade`만으로 결과 페이드인 효과 흡수**

지난 sprint에는 오버레이가 *0.3초 페이드인*하는 SKAction을 직접 돌렸다. 이번엔 그게 **필요 없다** — `SKTransition.fade(withDuration: 0.4)`가 두 씬 사이에 검은 페이드를 자동으로 끼워 주기 때문.

```swift
// 지난 sprint (오버레이 방식)
gameOverOverlay.fadeIn(duration: 0.3)   // SKAction 직접 실행

// 이번 sprint (씬 분리 방식)
view?.presentScene(resultScene, transition: .fade(withDuration: 0.4))
// → 검은 페이드가 두 씬 사이에 자동 삽입
```

> Spring으로 치면 "각 페이지마다 fadeIn JS를 따로 쓰던 걸, 라우터 전환 효과 한 줄로 통일"한 셈.

### 3-4. **씬을 새로 만들면 게임 화면이 ARC로 자동 해제**

GameScene에서 ResultScene으로 넘어가는 순간, GameScene 인스턴스는 *어디에도 강한 참조가 없는 상태*가 된다. SpriteKit의 SKView는 한 번에 한 씬만 보유하므로, 새 씬을 `presentScene`하면 이전 씬은 ARC로 메모리 해제된다.

→ player/enemy/spawn timer/contact router 모두 자동으로 정리. **별도 cleanup 코드 불필요.**

> Spring으로 치면 "요청이 끝나면 RequestScope 빈이 자동 소멸"하는 것. 직접 destroy 호출 안 해도 됨.

### 3-5. **노드 *폐기*는 패턴 진화의 자연스러운 결과**

`GameOverOverlayNode`는 지난 sprint의 핵심 컴포넌트였지만, 이번엔 *완전히 삭제*한다. 이게 나쁜 일이 아니다 — **한 단계 더 좋은 추상화(씬 분리)로 이전했기 때문**에 더 이상 필요 없는 것뿐.

> Spring으로 치면 "한 컨트롤러 안에 ModalView 컴포넌트로 두던 걸, 별도 페이지로 승격"하면서 ModalView 클래스를 지우는 것. 코드가 줄어드는 게 아니라 *책임이 옳은 자리로* 이동했을 뿐.

---

## 4. 무엇을 만드나?

### 새 파일 (1개)
| 파일 | 역할 |
|---|---|
| `Scenes/ResultScene.swift` | "GAME OVER / 🎵 점수 / TAP TO RETURN" 표시 + 탭 시 TitleScene 전환. 점수는 `init(score:)` 주입 |

### 삭제 파일 (1개)
| 파일 | 이유 |
|---|---|
| `Nodes/GameOverOverlayNode.swift` | 결과 표시 책임이 ResultScene으로 이전 → 더 이상 사용 안 됨 |

### 고치는 파일 (3개)
| 파일 | 변경 |
|---|---|
| `GameScene.swift` | `gameOverOverlay` 프로퍼티/setup/touchesBegan/`gameOverAt` 가드 모두 제거. `endGame()` 끝에서 ResultScene으로 즉시 fade transition |
| `Config/GameConfig.swift` | `gameOverPanelAlpha`/`gameOverFadeInDuration`/`gameOverTapGuardDuration`/`gameOverTitleFontSize`/`gameOverScoreFontSize`/`gameOverPromptFontSize` 등 *오버레이 전용* 상수 → ResultScene 폰트 상수로 재정리 (이름 변경 또는 그대로 재사용) |
| `GanhoMusic.xcodeproj/project.pbxproj` | ResultScene 등록 + GameOverOverlayNode 제거 (PBXBuildFile/FileRef/Group/Sources 4곳) |

### 한 그림으로

```
[기존 (3-1+2)]
TitleScene  ──→  GameScene  ──(endGame)──→  같은 씬에 오버레이 페이드인  ──(탭)──→  TitleScene

[새 (3-3)]
TitleScene  ──→  GameScene  ──(endGame)──→  ResultScene (fade transition)  ──(탭)──→  TitleScene
                                              ↑
                                         init(score:)로 점수 주입
```

---

## 5. 직접 확인할 것

⌘R 후:

| # | 시나리오 | 봐야 할 것 |
|---|---|---|
| (a) | 앱 시작 | 타이틀 화면 (3-1+2와 동일) |
| (b) | 타이틀 탭 → 게임 | 페이드 후 GameScene |
| (c) | 게임 도중 D-Pad | 평소처럼 정상 |
| (d) | 시간 만료 | 검은 페이드 후 ResultScene 등장. "GAME OVER / 🎵 N / TAP TO RETURN" |
| (e) | 적 접촉 | 동일 (ResultScene) |
| (f) | F 피격 | 동일 (ResultScene) |
| (g) | ResultScene 화면 탭 | 페이드 후 TitleScene |
| (h) | 타이틀에서 다시 탭 | 새 GameScene (점수 0) |
| (i) | 점수 인계 정확성 | 게임 중 음표 5개 모았으면 ResultScene 점수 = 5 |

---

## 6. 사용자 결정 (이미 합의)

| 결정 | 선택 | 왜 |
|---|---|---|
| 오버레이 노드 처리 | **A안 — 완전 폐기** | 씬 분리의 본질은 "한 씬 = 한 책임". 노드를 남기면 어정쩡 |
| 점수 전달 방식 | **init 주입** (`newResultScene(score:)`) | 불변성 보장, 옵셔널 처리 불필요 |
| 전환 효과 | `SKTransition.fade(0.4)` | 3-1+2와 동일. 일관성 |
| 검은 페이드가 결과 페이드인 대체 | **OK** | 추가 SKAction 없이 transition 효과만으로 자연스러움 |

---

## 7. 회고

### 7-1. 막혔던 것

**없음.** 한 사이클(QA 1회)에 9.83/10 합격. P0/P1 이슈 0건.

지난 sprint(3-1+2)에서 pbxproj 명시 등록 패턴을 익혀 둔 덕에 이번 ResultScene 추가 + GameOverOverlayNode 제거 8곳 작업이 한 번에 통과. **앞 sprint의 막힘이 이번 sprint의 매끄러움이 되는** 학습 곡선을 체감.

### 7-2. 새로 배운 것

1. **`private init` + `class func newScene(score:)` 팩토리 패턴** — 외부에서 직접 생성자 못 부르게 막고, 이름 있는 팩토리 메서드로만 생성 강제. Swift 관용구.
2. **`required init?(coder:)`은 `fatalError`로 명시** — Storyboard/.sks 자동 복원 경로를 명시적으로 *차단*. "이 클래스는 코드로만 만든다"는 표시.
3. **`let finalScore: Int`로 점수 불변** — init 주입 후 변경 불가. 표시 도중 변조 가능성 0. **Spring의 `final` 필드 + `@RequiredArgsConstructor` 패턴**과 동일.
4. **씬 분리 = 한 씬 = 한 책임** — GameScene이 더 이상 "결과 표시"를 알지 않음. 354→325줄 (-29줄). 코드가 줄어든 게 아니라 *책임이 옳은 자리로 이동*.
5. **검은 페이드(SKTransition.fade)가 페이드인 SKAction을 흡수** — 오버레이 0.3초 페이드인 SKAction이 사라져도 사용자 체감 자연스러움. *시각 효과의 책임 위치*를 한 단계 위(transition)로 끌어올림.
6. **삭제도 진화** — 지난 sprint 핵심 컴포넌트(`GameOverOverlayNode`)를 이번 sprint에서 폐기. 패턴이 더 좋은 추상화로 이전되면 옛 패턴은 지워야 함. dead code 잔존 0.
7. **상수 이름 변경 + 값 유지** — `gameOver*FontSize` → `result*FontSize`. 의미가 바뀌면 이름도 바꿔야 grep/이해가 정확. 값 자체는 변경 없으니 시각적 회귀 0.

### 7-3. 다음으로 미룬 것

- **3-4**: 최고 점수 저장 — UserDefaults로 영구 보존 + ResultScene/TitleScene에 표시
- **3-5**: 전적 통계 (플레이 횟수/누적 점수) — Codable + JSON 저장
- **P2 권장사항**: ResultScene.configureLabel의 `label.alpha = GameConfig.hudAlpha`가 TitleScene과 다름. 다음 sprint에서 라벨 알파 정책 통일 검토 (감점 사유 아님).

### 7-4. 평가 점수

- **가중평균: 9.83 / 10 — 합격**
- 항목별: Swift 패턴 9.5 / 게임 로직 10 / 성능·안정성 10 / 기능 완성도 10
- P0 치명 0건, P1 중요 0건, P2 권장 1건 (라벨 알파)
- 빌드: BUILD SUCCEEDED, 경고 0건 (iPhone 17 Simulator)

### 7-5. 코드 라인 변화

| 파일 | 변화 |
|---|---|
| `GameScene.swift` | 354 → 325줄 (-29) |
| `GameConfig.swift` | 147 → 139줄 (-8) |
| `Scenes/ResultScene.swift` | 0 → 104줄 (+104) |
| `Nodes/GameOverOverlayNode.swift` | 92 → 0줄 (-92, 파일 삭제) |
| **합계** | **-25줄** (+ 책임 분리) |

**핵심 가치**: 코드 줄 수가 거의 비슷하지만 *책임 경계*가 명확해졌다. 다음 sprint(3-4 UserDefaults)에서 **점수만 ResultScene으로 흐르는 패턴**을 그대로 확장하여 *최고 점수*도 같은 init 주입 경로로 흐르게 할 수 있음.

---

## 8. 다음 작업

```
[1] 시뮬레이터에서 §5 (a)~(i) 확인
[2] 다음 sprint: Phase 3-4 (UserDefaults — 최고 점수)
```

> **이번 sprint 본질**: "한 씬 = 한 책임"의 첫 실천. 모달 패턴(같은 씬 위에 띄움) → 페이지 전환 패턴(독립 씬). 그리고 *씬 간 데이터 전달*을 init 주입이라는 Swift 관용구로 처음 배운다. 이 패턴은 다음 sprint(UserDefaults 결과)에서도 그대로 쓰일 토대.
