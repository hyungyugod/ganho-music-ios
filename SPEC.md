# SPEC.md — Phase 10-2 · StartScene 모던 리스킨 (병동의 새벽 톤)

## 개요
앱 첫 진입 StartScene이 현재 회색 박스 + 시스템 폰트의 *완성도 낮은* 인상이라 게임의 첫 톤이 약하다. **게임플레이를 일절 건드리지 않고**, 배경 그라데이션 + 떠다니는 음표 파티클 + 제목 글로우 + 카드 spring/링 글로우 인터랙션 + 버튼 pulse + 전환 잔향 5채널 비주얼 리스킨을 가한다. 무드는 **'병동의 새벽 — 청록(teal) + 살구(coral/apricot)'** — 어두운 야간 병동 위에 작곡의 살구빛이 떠오르는 톤.

## 변경 유형
**비주얼** — 게임플레이 변경 0건. 난이도 선택 흐름·repo save·씬 전환 대상·hit test 우선순위·라벨 위치(레이아웃) 모두 동일. 시각 레이어만 신설/덮어쓰기.

## 게임 경험 의도
플레이어가 앱을 켜자마자 "이거 정성 들인 게임이구나"를 1초 안에 인지하게 한다. 어두운 새벽 병동(딥블루→틸 그라데이션) 위로 살구색 음표 ♪가 천천히 떠오르고, 제목이 부드럽게 빛난다. 난이도를 탭하면 *spring 반동 + 살구 링 글로우*로 "아 눌렀다"는 즉각 쾌감을 받고, 시작 버튼은 *심호흡하듯* pulse 한다. 씬을 떠날 때는 카드들이 살짝 위로 슬라이드하며 다음 씬과 연결감을 만든다.

## Sprint 범위 계약 — Phase 10-2

- **허용**:
  - StartScene 내부 비주얼 노드 추가 (그라데이션 배경, 음표 파티클, 제목 글로우)
  - DifficultyCardNode `setSelected(_:)` 시 spring scale + 링 글로우 추가 (호출 시그니처 불변)
  - GameConfig 신규 상수 *추가*만 (Phase 10-2 MARK 섹션 신설)
  - ColorTokens teal/coral accent 토큰 *추가*만
  - 씬 전환 시 카드 슬라이드업 + fade 길이 미세 조정 (sceneTransitionDuration 불변, 자체 신규 상수 사용)
  - SKAction.repeatForever pulse (시작 버튼)

- **금지**:
  - CharacterSelectScene·SkillExplanationScene·GameScene·ResultScene 비주얼 변경
  - 난이도 선택 결과/저장 시점/씬 전환 대상 변경
  - 기존 GameConfig 상수 *값 변경* (신규 추가만 허용)
  - 기존 ColorTokens 변경 (신규 추가만 허용)
  - StoryBoxNode·PrimaryButtonNode 내부 구조 변경 (StartScene이 *외부에서* pulse만 부착)
  - SPEC에 없는 사운드/햅틱/BGM 추가
  - 새 게임 메커닉·점수 보너스·이스터에그
  - 강제 언래핑(`!`), Timer, 매직 넘버, 매 프레임 addChild

- **판단 기준**: "이 변경이 없으면 SPEC의 비주얼 리스킨이 제대로 동작하지 않는가?" → YES만 허용.

## 불변 계약 (게임플레이 0건 변경)

| 항목 | 변경 여부 |
|---|---|
| `selectDifficulty(_:)` 호출 시점/저장 동작 | 불변 |
| `transitionToNext()`의 `CharacterSelectScene.newCharacterSelectScene(difficulty:)` 호출 | 불변 |
| `isTransitioning` 가드 | 불변 |
| 카드 hit test 우선순위 (난이도 카드 → 시작 버튼) | 불변 |
| `HighScoreRepository().current` / `StatisticsRepository().current.playCount` 읽기 시점 | 불변 |
| 카드 *위치*(layoutDifficultyCards 좌표 계산식) | 불변 |
| `selectedDifficulty: Difficulty = .easy` 기본값 + `difficultyRepo.current` 복원 | 불변 |

## 색상 토큰 정의 (ColorTokens.swift 신규)

원본 톤 ganhoUIBrand(#c4847a, 코럴)와 충돌 회피 위해 *액센트* 패밀리로 별도 네이밍.

| 토큰 | Hex | 용도 |
|---|---|---|
| `ganhoAccentTeal` | `#5BD7CF` | 그라데이션 하단 + 제목 글로우 외곽 |
| `ganhoAccentTealDeep` | `#1E3A4C` | 그라데이션 상단 (딥블루-틸 중간 톤) |
| `ganhoAccentCoral` | `#FFB59A` | 음표 파티클 본체 + 선택 카드 링 글로우 + BEST/PLAYS 액센트 |

> Hex 선택 근거: teal `#5BD7CF`는 ganhoMint(#7DCFB6, 머리띠)와 다른 *더 시원하고 채도 높은* 청록 — 야간 새벽 톤. coral `#FFB59A`는 ganhoUIBrand(#c4847a, 어두운 코럴)보다 *밝고 따뜻한* 살구색 — 떠오르는 멜로디 톤. 두 색은 보색 관계로 그라데이션 위 음표가 또렷이 떠오름.

## 변경 범위

### 수정할 파일

1. **`GanhoMusic Shared/Scenes/StartScene.swift`** — 비주얼 5채널 추가
   - 그라데이션 배경 노드(zPos -20) 추가
   - 떠다니는 음표 파티클 컨테이너(zPos -15) 추가
   - 제목 글로우 SKEffectNode 래핑
   - 시작 버튼 pulse 액션 부착
   - 씬 전환 시 카드 슬라이드업 시퀀스

2. **`GanhoMusic Shared/Config/GameConfig.swift`** — 신규 MARK 섹션 추가 (기존 상수 변경 0건)
   - `// MARK: - Start Scene Visual (Phase 10-2)` 섹션 신설

3. **`GanhoMusic Shared/Config/ColorTokens.swift`** — 신규 MARK 섹션 추가 (기존 토큰 변경 0건)
   - `// MARK: - Accent (Phase 10-2)` 섹션 신설
   - `ganhoAccentTeal`, `ganhoAccentTealDeep`, `ganhoAccentCoral` 3개 토큰

4. **`GanhoMusic Shared/Nodes/DifficultyCardNode.swift`** — `setSelected(_:)` 확장
   - 기존 alpha + scale 동작 유지
   - **추가**: spring bounce scale (overshoot 1.12 → 정착 1.08) — 선택 시만
   - **추가**: 살구 링 글로우 SKShapeNode 자식 — 선택 시 fade-in, 해제 시 즉시 alpha 0
   - `id`, `setSelected(_:)` 호출 시그니처 불변 — 호출부 변경 0

### 추가할 파일 (신규)

5. **`GanhoMusic Shared/Nodes/GradientBackgroundNode.swift`** — 재사용성 명확 (향후 다른 씬에서도 활용 가능)
   - SKSpriteNode 서브클래스. CGGradient + UIGraphicsImageRenderer로 1회 생성 → 텍스처 캐싱
   - init(size: CGSize, topColor: UIColor, bottomColor: UIColor)

6. **`GanhoMusic Shared/Nodes/MusicNoteEmitterNode.swift`** — 떠다니는 음표 파티클 컨테이너
   - SKNode 서브클래스. 내부에서 SKAction.repeatForever로 음표 SKLabelNode 스폰
   - 동시 표시 상한 GameConfig.musicNoteEmitterMaxConcurrent로 가드
   - 자식이 화면 위로 fade-out하면 자가 removeFromParent

7. **`GanhoMusic Shared/Nodes/GlowingTitleNode.swift`** — 제목 + 글로우 컨테이너 (재사용 가치 명확 — ResultScene/CharacterSelect도 향후 사용 가능)
   - SKNode 서브클래스. 자식: SKEffectNode(CIGaussianBlur 적용한 라벨 사본 — 글로우 레이어) + 본 SKLabelNode
   - `shouldRasterize = true`로 성능 가드

## 기능 상세

### 기능 1: 그라데이션 배경

- **설명**: 단색 `.ganhoBgDeep` 대신 세로 그라데이션 노드를 zPosition -20에 깔아 새벽 톤 표현
- **구현 위치**:
  - `Nodes/GradientBackgroundNode.swift` (신규)
  - `Scenes/StartScene.swift`의 `setupOverlayPanel()` *직전*에 `setupGradientBackground()` 신설
- **핵심 코드 구조**:

```swift
// Nodes/GradientBackgroundNode.swift
final class GradientBackgroundNode: SKSpriteNode {
    init(size: CGSize, topColor: UIColor, bottomColor: UIColor) {
        let texture = Self.makeGradientTexture(size: size, top: topColor, bottom: bottomColor)
        super.init(texture: texture, color: .clear, size: size)
        zPosition = GameConfig.startSceneGradientZPosition
        name = "gradientBackground"
    }

    private static func makeGradientTexture(size: CGSize, top: UIColor, bottom: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let colors = [top.cgColor, bottom.cgColor] as CFArray
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0.0, 1.0]
            ) else { return }
            cgCtx.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: size.height),
                end: CGPoint(x: 0, y: 0),
                options: []
            )
        }
        return SKTexture(image: image)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }
}
```

- **주의**: `backgroundColor = .ganhoBgDeep`은 유지 — 그라데이션 노드 로딩 전 1프레임 fallback 톤. 그라데이션이 위에 zPos -20으로 덮음.

### 기능 2: 떠다니는 음표 파티클

- **설명**: 화면 하단에서 살구색 ♪/♫ 음표가 천천히 위로 떠오르며 fade-out. 동시 표시 상한 가드.
- **구현 위치**:
  - `Nodes/MusicNoteEmitterNode.swift` (신규)
  - `Scenes/StartScene.swift`의 `setupOverlayPanel()` *다음*에 `setupMusicNoteEmitter()` 신설
- **핵심 코드 구조**:

```swift
final class MusicNoteEmitterNode: SKNode {
    private let sceneSize: CGSize
    private var activeCount: Int = 0

    init(sceneSize: CGSize) {
        self.sceneSize = sceneSize
        super.init()
        name = "musicNoteEmitter"
        zPosition = GameConfig.startSceneMusicNoteZPosition
        startEmitting()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    private func startEmitting() {
        let spawnAction = SKAction.sequence([
            SKAction.run { [weak self] in self?.spawnOneNote() },
            SKAction.wait(forDuration: GameConfig.musicNoteEmitterSpawnInterval)
        ])
        run(SKAction.repeatForever(spawnAction), withKey: "musicNoteSpawn")
    }

    private func spawnOneNote() {
        guard activeCount < GameConfig.musicNoteEmitterMaxConcurrent else { return }
        let glyphs = ["♪", "♫", "♩"]
        let label = SKLabelNode(text: glyphs.randomElement() ?? "♪")
        label.fontSize = GameConfig.musicNoteEmitterFontSize
        label.fontColor = .ganhoAccentCoral
        label.alpha = 0
        let startX = CGFloat.random(in: 0...sceneSize.width)
        label.position = CGPoint(x: startX, y: -20)
        addChild(label)
        activeCount += 1

        let rise = SKAction.moveBy(
            x: CGFloat.random(in: -30...30),
            y: sceneSize.height + 40,
            duration: GameConfig.musicNoteEmitterRiseDuration
        )
        let fadeIn = SKAction.fadeAlpha(to: 0.7, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let cleanup = SKAction.run { [weak self] in
            self?.activeCount = max(0, (self?.activeCount ?? 0) - 1)
        }
        let remove = SKAction.removeFromParent()
        label.run(SKAction.sequence([
            fadeIn,
            SKAction.group([rise, SKAction.sequence([
                SKAction.wait(forDuration: GameConfig.musicNoteEmitterRiseDuration - 1.0),
                fadeOut
            ])]),
            cleanup,
            remove
        ]))
    }

    func stopEmitting() {
        removeAction(forKey: "musicNoteSpawn")
    }
}
```

- **성능 가드**: `musicNoteEmitterMaxConcurrent = 15` 상한. `weak self` 캡처. 자가 removeFromParent.

### 기능 3: 제목 글로우

- **설명**: 기존 `titleLabel: SKLabelNode(text: "김간호는 음악박사")`를 *글로우 컨테이너로 래핑*. 글로우는 SKEffectNode + CIGaussianBlur로 표현. shouldRasterize=true로 성능 가드.
- **구현 위치**:
  - `Nodes/GlowingTitleNode.swift` (신규)
  - `Scenes/StartScene.swift`의 `setupLabels()` 내부 — titleLabel 단독 addChild 대신 GlowingTitleNode로 래핑
- **핵심 코드 구조**:

```swift
final class GlowingTitleNode: SKNode {
    let mainLabel: SKLabelNode
    private let glowEffect: SKEffectNode

    init(text: String, fontSize: CGFloat, glowColor: UIColor) {
        mainLabel = SKLabelNode(text: text)
        mainLabel.fontSize = fontSize
        mainLabel.fontColor = .ganhoPaper
        mainLabel.horizontalAlignmentMode = .center
        mainLabel.verticalAlignmentMode = .center

        let glowLabel = SKLabelNode(text: text)
        glowLabel.fontSize = fontSize
        glowLabel.fontColor = glowColor
        glowLabel.horizontalAlignmentMode = .center
        glowLabel.verticalAlignmentMode = .center

        glowEffect = SKEffectNode()
        if let blur = CIFilter(name: "CIGaussianBlur") {
            blur.setValue(GameConfig.titleGlowBlurRadius, forKey: "inputRadius")
            glowEffect.filter = blur
        }
        glowEffect.shouldRasterize = true
        glowEffect.shouldEnableEffects = true
        glowEffect.zPosition = -1
        glowEffect.addChild(glowLabel)

        super.init()
        name = "glowingTitle"
        addChild(glowEffect)
        addChild(mainLabel)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }
}
```

- **주의**: `titleLabel` 프로퍼티는 유지 가능 (또는 GlowingTitleNode로 교체) — Generator 판단. **단, layoutLabels()의 좌표 계산식은 *불변***. 좌표는 GlowingTitleNode에 적용.

### 기능 4: BEST/PLAYS 살구색 액센트

- **설명**: `bestLabel`/`playsLabel`의 `fontColor`를 `.ganhoPaper` → `.ganhoAccentCoral`로 변경.
- **구현 위치**: `Scenes/StartScene.swift` → `setupLabels()` 내부 색상 변경 2줄
- **주의**: subtitleLabel의 `.ganhoUITextMuted`는 유지 — 부제는 *조용한 톤*.

### 기능 5: 난이도 카드 spring + 링 글로우

- **설명**: 현재 `setSelected(_:)`은 단순 alpha+scale 1.08. 여기에 *spring overshoot* + 살구 링 글로우 추가.
- **구현 위치**: `Nodes/DifficultyCardNode.swift` → `setSelected(_:)` 내부 확장 + 신규 자식 `ringGlow: SKShapeNode` 프로퍼티 추가
- **핵심 코드 구조**:

```swift
// DifficultyCardNode.swift
private let ringGlow: SKShapeNode   // 신규

// init(id:) 내부:
let ringSize = CGSize(
    width: GameConfig.difficultyCardWidth + GameConfig.difficultyCardRingGlowPadding,
    height: GameConfig.difficultyCardHeight + GameConfig.difficultyCardRingGlowPadding
)
ringGlow = SKShapeNode(rectOf: ringSize, cornerRadius: ringSize.height / 2)
ringGlow.fillColor = .clear
ringGlow.strokeColor = .ganhoAccentCoral
ringGlow.lineWidth = GameConfig.difficultyCardRingGlowLineWidth
ringGlow.alpha = 0
ringGlow.zPosition = -1
ringGlow.glowWidth = GameConfig.difficultyCardRingGlowWidth

// setSelected(_:) 확장:
removeAction(forKey: "cardScale")
if selected {
    let overshoot = SKAction.scale(
        to: GameConfig.difficultyCardSpringOvershootScale,
        duration: GameConfig.difficultyCardSpringPhase1Duration
    )
    overshoot.timingMode = .easeOut
    let settle = SKAction.scale(
        to: GameConfig.characterCardSelectedScale,
        duration: GameConfig.difficultyCardSpringPhase2Duration
    )
    settle.timingMode = .easeInEaseOut
    run(SKAction.sequence([overshoot, settle]), withKey: "cardScale")
} else {
    run(SKAction.scale(to: 1.0, duration: GameConfig.characterCardScaleDuration),
        withKey: "cardScale")
}

ringGlow.removeAction(forKey: "ringFade")
let target: CGFloat = selected ? 1.0 : 0.0
let duration = selected
    ? GameConfig.difficultyCardRingGlowFadeInDuration
    : GameConfig.difficultyCardRingGlowFadeOutDuration
ringGlow.run(SKAction.fadeAlpha(to: target, duration: duration), withKey: "ringFade")
```

- **불변 계약**: `init(id:)` 시그니처·`setSelected(_:)` 시그니처·`id` 프로퍼티 접근성 모두 불변. StartScene의 호출 코드 변경 0줄.

### 기능 6: 시작 버튼 pulse

- **설명**: PrimaryButtonNode의 *외부에서* StartScene이 pulse 액션을 부착. PrimaryButtonNode 자체는 수정 0.
- **구현 위치**: `Scenes/StartScene.swift` → `setupStartButton()` 내부에 pulse 부착
- **핵심 코드 구조**:

```swift
private func attachStartButtonPulse() {
    let down = SKAction.scale(to: GameConfig.startButtonPulseScaleMin, duration: GameConfig.startButtonPulseHalfDuration)
    down.timingMode = .easeInEaseOut
    let up = SKAction.scale(to: GameConfig.startButtonPulseScaleMax, duration: GameConfig.startButtonPulseHalfDuration)
    up.timingMode = .easeInEaseOut
    let pulse = SKAction.sequence([down, up])
    startButton.run(SKAction.repeatForever(pulse), withKey: "startButtonPulse")
}
```

- **주의**: 씬 전환 시 `removeAction(forKey: "startButtonPulse")`로 정리.

### 기능 7: 씬 전환 시 카드 슬라이드업 + 연결감 fade

- **설명**: `transitionToNext()`에서 *바로* presentScene 호출 대신, 카드/스토리박스/시작버튼을 살짝 위로 슬라이드 + fadeOut 후 presentScene.
- **구현 위치**: `Scenes/StartScene.swift` → `transitionToNext()` 수정
- **핵심 코드 구조**:

```swift
private func transitionToNext() {
    guard let view = self.view else { return }
    isTransitioning = true

    let slideUp = SKAction.moveBy(
        x: 0,
        y: GameConfig.startSceneExitSlideDistance,
        duration: GameConfig.startSceneExitSlideDuration
    )
    slideUp.timingMode = .easeIn
    let fadeOut = SKAction.fadeOut(withDuration: GameConfig.startSceneExitSlideDuration)
    let exit = SKAction.group([slideUp, fadeOut])

    for card in difficultyCards { card.run(exit) }
    storyBox.run(exit)
    startButton.removeAction(forKey: "startButtonPulse")
    startButton.run(exit)

    let wait = SKAction.wait(forDuration: GameConfig.startSceneExitSlideDuration)
    run(SKAction.sequence([wait, SKAction.run { [weak self] in
        guard let self = self else { return }
        let nextScene = CharacterSelectScene.newCharacterSelectScene(
            difficulty: self.selectedDifficulty
        )
        let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
        view.presentScene(nextScene, transition: fade)
    }]))

    _ = characterRepo
}
```

- **불변 계약**: `CharacterSelectScene.newCharacterSelectScene(difficulty:)` 호출·`sceneTransitionDuration` 사용 불변. 슬라이드 시간은 *추가*된 prelude.

## GameConfig 신규 상수 (Phase 10-2 MARK 섹션)

```swift
// MARK: - Start Scene Visual (Phase 10-2)
static let startSceneGradientZPosition: CGFloat = -20
static let startSceneMusicNoteZPosition: CGFloat = -15

static let musicNoteEmitterMaxConcurrent: Int = 15
static let musicNoteEmitterSpawnInterval: TimeInterval = 0.5
static let musicNoteEmitterFontSize: CGFloat = 18
static let musicNoteEmitterRiseDuration: TimeInterval = 8.0

static let titleGlowBlurRadius: CGFloat = 8.0

static let difficultyCardSpringOvershootScale: CGFloat = 1.12
static let difficultyCardSpringPhase1Duration: TimeInterval = 0.18
static let difficultyCardSpringPhase2Duration: TimeInterval = 0.12

static let difficultyCardRingGlowPadding: CGFloat = 10
static let difficultyCardRingGlowLineWidth: CGFloat = 2
static let difficultyCardRingGlowWidth: CGFloat = 6
static let difficultyCardRingGlowFadeInDuration: TimeInterval = 0.2
static let difficultyCardRingGlowFadeOutDuration: TimeInterval = 0.1

static let startButtonPulseScaleMin: CGFloat = 0.98
static let startButtonPulseScaleMax: CGFloat = 1.02
static let startButtonPulseHalfDuration: TimeInterval = 1.0

static let startSceneExitSlideDistance: CGFloat = 30
static let startSceneExitSlideDuration: TimeInterval = 0.2
```

## ColorTokens 신규 상수

```swift
// MARK: - Accent (Phase 10-2 · 병동의 새벽 톤)
static let ganhoAccentTeal = UIColor(hex: "#5BD7CF")
static let ganhoAccentTealDeep = UIColor(hex: "#1E3A4C")
static let ganhoAccentCoral = UIColor(hex: "#FFB59A")
```

> `UIColor(hex:)` 헬퍼 extension은 *이미 존재* — 재활용.

## 성능 가드

- **음표 파티클 동시 상한**: `musicNoteEmitterMaxConcurrent = 15`. 스폰 함수 진입부에서 `activeCount` 체크 후 조기 반환.
- **그라데이션 텍스처**: didMove에서 1회만 생성. 매 프레임 재생성 0.
- **제목 글로우 SKEffectNode**: `shouldRasterize = true` 필수.
- **pulse/fade 액션**: 모두 `withKey:` 부여 → 씬 전환 시 정리.
- **클로저 캡처**: 모든 `SKAction.run { ... }`에서 `[weak self]` 적용.
- **타겟 FPS**: 60fps 유지.

## 주의사항

- **`addChild` 순서**: `setupGradientBackground` → `setupOverlayPanel` → `setupMusicNoteEmitter` → `setupLabels` → `setupDifficultyCards` → `setupStoryBox` → `setupStartButton` 순서.
- **didChangeSize 대응**: 그라데이션 텍스처 재생성. 음표 emitter도 sceneSize 의존 → 재생성.
- **CIGaussianBlur 옵셔널**: `CIFilter(name:)` 옵셔널 처리 필수. 강제 언래핑 금지.
- **GameConfig 상수 삽입 위치**: 파일 끝 `}` 직전, 기존 MARK 섹션 뒤. 기존 상수 *변경 0건* — 추가만.
- **ColorTokens 삽입 위치**: 마지막 토큰 뒤, `extension UIColor` 닫는 `}` 직전.

## 검증 체크리스트 (Generator가 구현 완료 후 SELF_CHECK.md에 기록)

- [ ] StartScene 외 다른 씬(.swift) 파일 수정 0건
- [ ] GameScene·CharacterSelectScene·SkillExplanationScene 변경 0건
- [ ] GameConfig 기존 상수 *값 변경* 0건 (신규 MARK 섹션만 추가)
- [ ] ColorTokens 기존 토큰 변경 0건
- [ ] DifficultyCardNode `init(id:)` / `setSelected(_:)` 시그니처 불변
- [ ] StartScene의 `selectDifficulty(_:)` / `transitionToNext()`의 *게임플레이 동작* 불변 (저장 시점·다음 씬·난이도 전달)
- [ ] 강제 언래핑 `!` 사용 0건
- [ ] `Timer.scheduledTimer` 사용 0건 — 모두 SKAction
- [ ] 매직 넘버 0건 — 모두 GameConfig 상수
- [ ] 클로저 `[weak self]` 캡처 적용
- [ ] 음표 동시 상한 가드 작동 (`activeCount < musicNoteEmitterMaxConcurrent`)
- [ ] SKEffectNode `shouldRasterize = true` 적용
- [ ] 빌드 에러 0건, 콘솔 경고 최소화
- [ ] 시뮬레이터에서 60fps 유지 확인 (디버그 통계)
