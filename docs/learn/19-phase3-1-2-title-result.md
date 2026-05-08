# 19 · Phase 3-1+2 · 타이틀 화면 + 게임오버 화면 — 씬 전환 🎬

> **이번 작업 한 줄**: 게임 한 판이 끝나면 멈추기만 하던 흐름을 **타이틀 → 게임 → (게임오버 화면) → 타이틀** 사이클로 만든다.

---

## 1. 왜?

지금까지 만든 게임은 켜자마자 게임 화면이 뜨고, 45초가 지나면 화면이 그대로 멈춘다. 다시 하려면 앱을 종료하고 다시 켜야 한다. 그래서 이번에 두 가지를 한 번에 한다.

1. **첫 화면을 "타이틀"로** — "김간호는 음악박사 / TAP TO START" 같은 시작 화면.
2. **게임이 끝나면 "결과 화면"** — 점수와 함께 "TAP TO RETURN"이 보이고, 화면을 누르면 타이틀로 돌아간다.

> 두 작업을 합친 이유: 결국 둘 다 "**한 화면에서 다른 화면으로 넘어간다**"는 같은 기술(SKView.presentScene)을 쓴다. 한 사이클에 묶으면 학습이 한 번에 끝나고, 흐름도 자연스럽게 닫힌다.

---

## 2. Spring 비유 ⭐

이번에 배우는 핵심 개념을 Spring으로 옮기면:

| SpriteKit | Spring | 한 줄 설명 |
|---|---|---|
| `SKScene` | `@Controller` 클래스 | 한 화면 = 한 컨트롤러 |
| `SKView.presentScene(scene)` | `return "view-name"` (ModelAndView) | "이제 이 화면 보여줘" |
| `SKTransition.fade(...)` | `redirect:` 후 페이드 효과 | 화면 바뀔 때 시각 효과 |
| `touchesBegan` | `@PostMapping` 핸들러 | 사용자 입력 받는 진입점 |
| 새 `SKScene` 인스턴스 | 새 컨트롤러 호출 | 완전 새 상태 (이전 화면 메모리 해제) |

**핵심**: 우리 게임의 한 사이클은 "**컨트롤러(Title)에서 → 다른 컨트롤러(Game)로 → 끝나면 다시 Title로**" 이동하는 웹 페이지 흐름과 똑같다. 다만 페이지 전환 효과(페이드)를 SpriteKit이 직접 지원해 준다.

---

## 3. 새로 배운 것 (Swift/SpriteKit) ⭐

### 3-1. **씬 인스턴스를 새로 만들면 상태가 깨끗해진다**

```swift
// GameScene 안에서 게임이 끝났을 때
let titleScene = TitleScene.newTitleScene()
view?.presentScene(titleScene, transition: .fade(withDuration: 0.4))
```

`TitleScene.newTitleScene()`은 *완전히 새 객체*. 이전 GameScene이 갖고 있던 점수·콤보·적·투사체·타이머 모두 메모리에서 사라진다. **자바 객체를 새로 `new`** 하는 것과 똑같다. "리셋 버튼"을 따로 만들 필요가 없다 — 새로 만들면 끝.

### 3-2. **`SKTransition` — 화면 전환 효과**

```swift
let fade = SKTransition.fade(withDuration: 0.4)
view?.presentScene(newScene, transition: fade)
```

검은 페이드, 좌우 슬라이드, 도어 와이프 등 여러 종류가 있다. 우리는 **페이드**(가장 무난)를 쓴다.

> Spring으로 치면 "redirect 후 0.4초간 회색 박스가 가운데서 페이드되는 CSS 트랜지션" 같은 것을 한 줄로 끝낸다.

### 3-3. **`touchesBegan` — 화면을 손가락으로 두드렸을 때**

```swift
override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    // 한 번이라도 손가락이 닿으면 게임 씬으로
}
```

**Spring 비유**: `@PostMapping("/start") public String start(){ ... }` — 클라이언트가 폼 제출하면 호출되는 핸들러. SpriteKit에서는 *씬 전체가 받는 클릭 이벤트*다.

> 주의: `GameScene`에서는 D-Pad가 이미 `touchesBegan`을 자기 영역에서만 처리한다. **게임오버 상태일 때만** 씬 전체가 탭을 받아 타이틀로 가도록 `gameState`로 가드해야 한다.

### 3-4. **결과 오버레이 = `cameraNode` 자식**

게임오버 후 띄울 "GAME OVER / 점수 / TAP TO RETURN" 패널은 `worldNode`가 아니라 `cameraNode`의 자식이어야 한다. **HUD나 D-Pad와 똑같은 이유** — 카메라가 어디 있든 *화면 정중앙에 고정*되어야 하기 때문.

```swift
cameraNode.addChild(gameOverOverlay)
```

> Spring으로 치면 "전역 모달 — 어느 페이지든 공통으로 떠 있는 레이어"다.

### 3-5. **씬 진입점은 어디?**

`GameViewController.viewDidLoad()`에서 첫 씬을 결정한다. 지금까지는 `GameScene.newGameScene()`이었지만, 이제 `TitleScene.newTitleScene()`으로 바꾼다.

```swift
// GameViewController.swift
let scene = TitleScene.newTitleScene()  // ← 여기 한 줄만 바뀜
skView.presentScene(scene)
```

> Spring으로 치면 `application.properties`의 `server.servlet.context-path` 또는 첫 진입 라우터를 바꾸는 것.

---

## 4. 무엇을 만드나?

### 새 파일 (3개)

| 파일 | 역할 |
|---|---|
| `Scenes/TitleScene.swift` | 첫 화면. 제목 + "TAP TO START". 탭 시 GameScene 전환 |
| `Nodes/GameOverOverlayNode.swift` | 반투명 패널 + "GAME OVER" + 점수 + "TAP TO RETURN" |
| (학습 노트) `docs/learn/19-phase3-1-2-title-result.md` | 이 문서 |

### 고치는 파일 (3개)

| 파일 | 변경 |
|---|---|
| `GameScene.swift` | `endGame()`에서 오버레이 페이드인 + `touchesBegan`에서 (게임오버 상태일 때) TitleScene 전환 |
| `GanhoMusic iOS/GameViewController.swift` | 첫 씬을 `TitleScene.newTitleScene()`으로 |
| `Config/GameConfig.swift` | `sceneTransitionDuration`, 오버레이 알파, 타이틀 폰트 크기 등 상수 |

### 한 그림으로

```
[앱 시작]
   ↓
TitleScene  ──(탭)──→  GameScene  ──(시간 만료/적 접촉/F 피격)──→  endGame()
   ↑                                                            │
   │                                                            ↓
   │                                            GameOverOverlay 페이드인
   │                                                            │
   │                                                            ↓
   └──────────(전체 화면 탭)─────────────────  TitleScene 전환
```

---

## 5. 직접 확인할 것

⌘R 후:

| # | 시나리오 | 봐야 할 것 |
|---|---|---|
| (a) | 앱 시작 직후 | "김간호는 음악박사 / TAP TO START" 타이틀 화면이 뜬다 |
| (b) | 타이틀 화면 탭 | 페이드와 함께 게임 화면(GameScene)으로 |
| (c) | 게임 도중 D-Pad 동작 | 평소처럼 정상 (D-Pad가 탭을 먼저 가로챔) |
| (d) | 시간 만료 (45초 대기) | "GAME OVER / 🎵 N / TAP TO RETURN" 오버레이가 페이드인 |
| (e) | 게임 도중 적 접촉 | 위와 동일 (게임오버 발생 경로 무관) |
| (f) | 게임 도중 F 피격 | 위와 동일 |
| (g) | 오버레이가 떠 있을 때 화면 탭 | 페이드와 함께 타이틀로 복귀 |
| (h) | 타이틀에서 다시 탭 | 새 GameScene (점수 0, 타이머 45초로 리셋) |

---

## 6. 사용자 결정 (이미 합의)

| 결정 | 선택 | 왜 |
|---|---|---|
| 통합 단위 | 3-1 + 3-2 한 사이클 | 같은 기술(SKView.presentScene)을 두 번 쓰는 셈이라 묶음 |
| 게임오버 후 흐름 | **B안** — 오버레이 → 탭 → 타이틀 → 탭 → 게임 | 씬 전환이 일관, 코드 결합 ↓ |
| 전환 효과 | `SKTransition.fade(0.4)` | 가장 무난, 학습 부담 ↓ |
| 첫 씬 | TitleScene | 게임 진입을 명시적으로 |

---

## 7. 회고

### 7-1. 막혔던 것

**Xcode 프로젝트 자동 동기화의 함정.** 첫 빌드 때 `cannot find 'GameOverOverlayNode' in scope` 에러가 떴다. 알고 보니 이 프로젝트는 `PBXFileSystemSynchronizedRootGroup`을 쓰지만, **기존 Shared 파일들은 모두 `PBXBuildFile` + `PBXSourcesBuildPhase`에 명시 등록**돼 있었다 — 자동 동기화만으론 신규 파일을 인식 못 함. 신설 2파일을 pbxproj에 명시 등록(PBXBuildFile/FileRef/그룹/Sources phase 4곳)한 뒤 통과.

> Spring으로 치면 "새 클래스 만들었는데 `@Component` 스캔 패키지에 안 잡혀서 빈 등록 안 된" 상황. **자동 스캔이 있어도, 기존 코드가 명시 등록을 쓰고 있으면 새 파일도 똑같이 명시 등록**해야 한다.

### 7-2. 새로 배운 것

1. **`SKView.presentScene(_:transition:)`** — 한 줄로 화면이 바뀐다. 새 씬 인스턴스 생성 → `view?.presentScene(scene, transition: fade)`. ARC가 이전 씬을 자동 해제 → "리셋" 메서드 따로 만들 필요 없음.
2. **`SKTransition.fade(withDuration:)`** — 검은 페이드. 두 씬 모두 같은 `.ganhoBgDeep` 배경이라 자연스럽게 이어짐. Spring의 redirect + CSS 트랜지션을 한 줄로 끝내는 셈.
3. **`touchesBegan`의 gameState 가드** — 같은 메서드가 *상태별로 다른 일*을 하도록 분기. `.gameOver`일 때만 타이틀로, 그 외엔 무동작. D-Pad는 자기 영역 터치를 먼저 가로채므로 충돌 없음.
4. **DPad 비활성화 한 줄의 중요성** — `dpad.isUserInteractionEnabled = false`를 endGame에 넣지 않으면, 게임오버 후 D-Pad 영역을 탭할 때 GameScene.touchesBegan이 호출되지 않아 타이틀로 복귀가 안 됨. **이벤트가 어디서 가로채지는지** 의식하는 습관 필요.
5. **멱등 가드(`if gameState == .gameOver { return }`)** — 적 접촉 + 시간 만료가 동시에 일어나면 endGame이 두 번 호출돼 fadeIn이 두 번 실행되며 깜빡일 수 있음. 첫 줄 가드로 한 번만 동작 보장.
6. **`gameOverTapGuardDuration`** — `lastUpdateTime - gameOverAt >= 0.4`로 페이드인 도중 탭을 무시. update가 멈추지 않고 매 프레임 lastUpdateTime을 갱신하기 때문에 Timer 없이도 시간 비교 가능.
7. **카메라 자식 노드의 좌표계** — `cameraNode` 자식의 (0,0)은 화면 정중앙. HUD가 좌상단, D-Pad가 우하단인 것과 달리 게임오버 오버레이는 정중앙(0,0)에 라벨 배치.

### 7-3. 다음으로 미룬 것

- **3-3**: ResultScene을 별도 씬으로 분리 (지금은 오버레이로 처리). 점수/콤보를 새 씬에 인계.
- **3-4**: 최고 점수 저장 — UserDefaults로 영구 보존 + ResultScene/TitleScene에 표시.
- **3-5**: 전적 통계 (플레이 횟수/누적 점수) — Codable + JSON 저장.

### 7-4. 평가 점수

- **가중평균: 9.675 / 10 — 합격**
- 항목별: Swift 패턴 9.5 / 게임 로직 9.5 / 성능·안정성 10 / 기능 완성도 10
- P0 치명 0건, P1 중요 0건, P2 권장 2건 (감점 사유 아님)
- 빌드: BUILD SUCCEEDED, 경고 0건 (iPhone 17 Simulator)

### 7-5. P2 권장 사항 (다음 sprint 청소 거리)

1. **TitleScene 일관성** — `setupBackground()` 메서드로 분리하면 GameScene과 패턴 통일.
2. **`GameOverOverlayNode`의 `import UIKit`** — `SKColor.black.withAlphaComponent`로 바꾸면 향후 macOS 타깃 호환 가능. 단 본 sprint는 iOS 전용이라 보류.

---

## 8. 다음 작업

```
[1] 시뮬레이터에서 §5 (a)~(h) 확인
[2] 다음 sprint: Phase 3-3 (ResultScene 분리) 또는 3-4 (UserDefaults)
```

> **이번 sprint 본질**: SpriteKit의 *씬 전환*을 처음 다룬다. 한 화면 안의 노드 조작에서 → 화면 단위 흐름으로 시야가 넓어지는 단계. Spring 컨트롤러 사이의 `redirect:`와 똑같이, 한 줄(`presentScene`)로 화면이 바뀐다.
