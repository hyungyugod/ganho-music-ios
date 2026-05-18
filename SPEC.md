# Phase 7-3 — 인트로 컷씬 (자가 소멸 노드 10호)

## 개요
게임 시작 시 카운트다운 *전에* "어느 한적한 병동의 오후" 인트로 컷씬 오버레이를 띄운다. 난이도별 분기 텍스트(`{NAME}` 토큰 치환)와 "TAP TO CONTINUE" 안내를 보여주고, 화면 어디든 탭하면 자가 소멸 후 기존 카운트다운 흐름을 시작한다. 원본 웹 게임 `CUTSCENES.intro` (game.js L200-209) 텍스트를 단일 진실 원천으로 차용.

## 변경 유형
**게임플레이 + UI (혼합)** — 컷씬은 *경험 흐름* 자체를 바꿈. 게임 진입 직후 첫 화면이 카운트다운(액션)이 아니라 *서사*(스토리)가 된다.

## 게임 경험 의도
이 게임은 *간호 실습 중 작곡한* 사용자 자전 경험의 음악 게임이다. 첫 화면에 "어느 한적한 병동의 오후"라는 *장소와 시간*을 명시함으로써 — 점수/속도 게임이 아니라 *이야기를 가진 일상의 한 컷*임을 알린다. 카운트다운 직전 1.5~3초의 *호흡 정지*는 플레이어에게 "이 게임이 무엇에 관한 것인지" 인지할 시간을 준다. 난이도별 텍스트 분기는 게임 난이도를 *수치 차이*가 아니라 *내러티브 분기*("수간호사 순찰" → "이교수 청진기")로 체감시키는 장치다.

## Sprint 범위 계약

### 허용
- `Nodes/CutsceneOverlayNode.swift` 신규 1 파일 (자가 소멸 노드 10호)
- `Config/GameState.swift`에 `case cutscene` 1줄 추가
- `GameScene.swift` `didMove(to:)` 흐름 1줄 교체 (`showCountdown()` → `showIntroCutscene()`)
- `GameScene.swift`에 `showIntroCutscene()` private 메서드 신설
- `GameConfig.swift`에 컷씬 상수 ~10개 추가
- `pbxproj` 신규 파일 1개 등록

### 금지
- mid1/mid2/introStoneGuard/introProfessor 컷씬 (다음 sprint들)
- 컷씬 중복 표시 방지 Set (다음 sprint)
- 기존 CountdownNode 코드/타이밍 변경
- TitleScene / ResultScene 변경
- 새 ColorTokens / 새 사운드 / 새 햅틱

### 판단 기준
"이 변경 없으면 인트로 컷씬이 동작하지 않는가?" → YES만 허용.

## 변경 범위

### 수정
- `Config/GameState.swift` — `case cutscene` 1줄 추가
- `Config/GameConfig.swift` — `// MARK: - Cutscene (Phase 7-3)` 섹션 + 상수 10개
- `GameScene.swift` — didMove 끝부분 2줄 (`gameState = .cutscene` + `showIntroCutscene()`), `showIntroCutscene()` 메서드 신설
- `GanhoMusic.xcodeproj/project.pbxproj` — 신규 파일 등록

### 신규
- `Nodes/CutsceneOverlayNode.swift` — 자가 소멸 노드 10호. ScorePopupNode 패턴 + 터치 트리거.

---

## 기능 상세

### 기능 1: GameState `.cutscene` case 신설

```swift
// GameState.swift
enum GameState {
    case waiting
    case cutscene   // Phase 7-3 — 인트로 컷씬 표시 중. 탭 1회로 .countdown 전환.
    case countdown
    case playing
    case paused
    case gameOver
}
```

### 기능 2: CutsceneOverlayNode 신설 (자가 소멸 노드 10호)

- 반투명 검정 배경 SKSpriteNode + 제목/본문/TAP SKLabelNode 4-자식
- cameraNode 자식 부착 (화면 중앙 고정)
- private init + 정적 팩토리 `present(title:body:parent:sceneSize:onDismiss:)`
- 자기 `touchesBegan` 처리 → dismiss → fadeOut → removeFromParent → onDismiss 콜백
- isUserInteractionEnabled = true (init), dismiss 시 false 토글 (다중 탭 방지)

핵심 구조:
```swift
final class CutsceneOverlayNode: SKNode, SelfDismissingNode {
    private let background: SKSpriteNode
    private let titleLabel: SKLabelNode
    private let bodyLabel: SKLabelNode
    private let tapLabel: SKLabelNode
    private var onDismiss: (() -> Void)?

    private init(title: String, body: String, sceneSize: CGSize) {
        self.background = SKSpriteNode(color: UIColor.black.withAlphaComponent(GameConfig.cutsceneBackgroundAlpha),
                                        size: sceneSize)
        self.titleLabel = SKLabelNode(text: title)
        self.bodyLabel = SKLabelNode(text: body)
        self.tapLabel = SKLabelNode(text: "TAP TO CONTINUE")
        super.init()
        name = "cutsceneOverlay"
        zPosition = GameConfig.cutsceneZPosition
        isUserInteractionEnabled = true
        // configure...
        addChild(background); addChild(titleLabel); addChild(bodyLabel); addChild(tapLabel)
        alpha = 0
    }

    required init?(coder: NSCoder) { fatalError(...) }

    static func present(title: String, body: String, parent: SKNode,
                        sceneSize: CGSize, onDismiss: @escaping () -> Void) {
        let node = CutsceneOverlayNode(title: title, body: body, sceneSize: sceneSize)
        node.onDismiss = onDismiss
        parent.addChild(node)
        node.run(SKAction.fadeIn(withDuration: GameConfig.cutsceneFadeInDuration))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismiss()
    }

    private func dismiss() {
        isUserInteractionEnabled = false  // 다중 탭 방지
        let callback = onDismiss
        onDismiss = nil
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.cutsceneFadeOutDuration)
        let cleanup = SKAction.removeFromParent()
        let notify = SKAction.run { callback?() }
        run(.sequence([fadeOut, cleanup, notify]))
    }

    // configureBackground/TitleLabel/BodyLabel/TapLabel ...
    // BodyLabel: numberOfLines = 0, preferredMaxLayoutWidth = sceneSize.width * GameConfig.cutsceneBodyWidthRatio
}
```

### 기능 3: GameScene didMove 흐름 변경 + showIntroCutscene()

현재 (Phase 6-13 시점):
```swift
gameState = .countdown
showCountdown()
```

신규 (Phase 7-3):
```swift
gameState = .cutscene
showIntroCutscene()
```

`showIntroCutscene()` 메서드:
```swift
// MARK: - Cutscene (Phase 7-3)
private func showIntroCutscene() {
    let title = "어느 한적한 병동의 오후"
    let template: String
    switch difficulty {
    case .easy, .normal:
        template = "수간호사가 순찰을 돈다. 그 틈을 타, {NAME}는 주머니 속 작곡 노트를 슬쩍 꺼낸다… 음표를 모으자."
    case .hard:
        template = "학교에서 나온 깐깐한 이교수가 오늘따라 청진기를 휘두른다. 날아오는 청진기를 피하며 음표를 모으자. 수간호사는 언제나 그렇듯 순찰을 돈다."
    }
    let body = template.replacingOccurrences(of: "{NAME}", with: characterID.displayName)
    CutsceneOverlayNode.present(
        title: title,
        body: body,
        parent: cameraNode,
        sceneSize: size,
        onDismiss: { [weak self] in
            guard let self = self else { return }
            self.gameState = .countdown
            self.showCountdown()
        }
    )
}
```

### 기능 4: GameConfig 컷씬 상수 신설

```swift
// MARK: - Cutscene (Phase 7-3)
static let cutsceneBackgroundAlpha: CGFloat = 0.85
static let cutsceneTitleFontSize: CGFloat = 26
static let cutsceneBodyFontSize: CGFloat = 20
static let cutsceneTapFontSize: CGFloat = 16
static let cutsceneTitleOffsetY: CGFloat = 100
static let cutsceneTapOffsetY: CGFloat = -120
static let cutsceneBodyWidthRatio: CGFloat = 0.7
static let cutsceneZPosition: CGFloat = 300
static let cutsceneFadeInDuration: TimeInterval = 0.25
static let cutsceneFadeOutDuration: TimeInterval = 0.3
static let cutsceneTapLabelAlpha: CGFloat = 0.7
```

---

## GameState `.cutscene` 영향 분석

| 파일:라인 | 코드 | `.cutscene` 영향 |
|---|---|---|
| GameScene.swift:149 | `gameState = .countdown` | 변경 — `.cutscene`으로 |
| GameScene.swift:199 | `gameState = .playing` | 무영향 |
| GameScene.swift:242 | `guard gameState == .playing` (update) | **핵심 차단점** — `.cutscene`에서 모든 시스템 정지 |
| GameScene.swift:473 | `if gameState == .gameOver` (endGame) | 무영향 |

grep `switch.*gameState` → **0건**. exhaustive switch 없음. case 추가가 다른 파일 영향 0건.

---

## 회귀 0 자연 차단 메커니즘

1. **update 폴링** — `guard gameState == .playing` 한 줄이 `.cutscene` 차단. 7개 시스템(타이머/이동/카메라/적/콤보/끊김/HUD) 동시 정지.
2. **SpawnSystem.start 미호출** — startGameProperly 내부. 컷씬 dismiss 후에야 도달.
3. **bgm.play 미호출** — 동일. 컷씬 중 *침묵*.
4. **player velocity 0** — didMove 직후 누적 0.
5. **컷씬 노드 cameraNode 자식** — worldNode/HUD와 시각 분리.
6. **EnemyNode/ProjectileSpawn 미실행** — update 차단으로 자동.
7. **ContactRouter 콜백 미발화** — 노드 간 접촉 경로 0.
8. **다중 탭 차단** — isUserInteractionEnabled 토글 + onDismiss nil 캡처.

---

## 영구 저장 동작
**0건**. intro는 매 게임 시작 시 표시. 한 번 본 컷씬 재차 표시 방지는 다음 sprint.

---

## 주의사항

1. **GameState exhaustive switch 0건** — grep 확인. case 추가 안전.
2. **CountdownNode 완전 보존** — dismiss 후 기존 showCountdown() 그대로. 타이밍 변경 0.
3. **자가 소멸 패턴 변형** — SelfDismissingNode marker protocol 채택. 터치 트리거(시간 트리거 아님).
4. **isUserInteractionEnabled 필수 true** — SKNode 기본 false. 미설정 시 touchesBegan 부모로 전파.
5. **다중 탭 방지** — dismiss 첫 줄 isUserInteractionEnabled = false 토글 + onDismiss를 nil로 캡처.
6. **본문 자동 줄바꿈** — iOS 11+ numberOfLines = 0 + preferredMaxLayoutWidth.
7. **폰트 가시성** — 제목 26 / 본문 20 / TAP 16, .ganhoPaper, 배경 .black α=0.85.
8. **showCountdown private 동일 클래스** — 접근 제한자 변경 0.
9. **resize 대응 불필요** — 컷씬 짧은 수명.
10. **pbxproj 등록** — ScorePopupNode 등록 라인 답습 (PBXBuildFile/PBXFileReference/PBXSourcesBuildPhase iOS).
11. **메모리 관리** — onDismiss `[weak self]` 캡처. CountdownNode 패턴 답습.
12. **{NAME} 치환** — `String.replacingOccurrences(of: "{NAME}", with: characterID.displayName)`. easy/normal 본문에 1개 등장.
