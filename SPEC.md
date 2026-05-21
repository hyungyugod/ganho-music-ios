# Sprint 10 Phase J — HUD · iOS 이펙트 픽셀 톤 변환 (마지막 Phase)

## 1. 개요
인게임 HUD/오버레이/이펙트의 모든 시각 톤을 v2 카툰(Jua-Regular + 코랄/네이비) → **8-bit 픽셀 톤(Menlo-Bold + 픽셀 옐로/페이퍼화이트)** 으로 일관 변환. Phase A~I로 인게임 본체가 픽셀화된 상태에서, 마지막으로 UI/이펙트 레이어를 통일해 시각 분기(메뉴=카툰 / 인게임=픽셀)를 완성.

## 2. 변경 유형
**비주얼** (픽셀 톤 변환 — 게임 로직/AI/물리/스폰/충돌 0건 변경)

## 3. 게임 경험 의도
메뉴 부드러운 카툰 UI → 인게임 진입 시 8-bit HUD/팝업/카운트다운으로 톤 통째 전환. 점수 +1·콤보 ×3·GO! 모든 텍스트 픽셀 폰트, sparkle 1×1 사각 픽셀, 5초 긴박감 픽셀 비네트로 패미컴 절체절명 환기.

## 4. Sprint 범위 계약

**허용**: HUDNode/HUDSkillSlotNode/ComboPopupNode/ComboBreakNode/ScorePopupNode/SparkleEffectNode/CountdownNode/HitFlashNode/BombFlashNode 폰트·색·외곽선·입자 모양 교체. GameConfig 픽셀 톤 상수 추가. TensionVignetteNode 신규.

**금지**: SPEC 외 새 이펙트/HUD 슬롯, SKAction 본문 변경, 외부 API 시그니처 변경.

## 5. 사용자 의사결정 7건 (§3 그대로)

| # | 항목 | 결정 |
|---|---|---|
| 1 | 카메라 follow 유지, 맵 32×20 | |
| 2 | 박병장 유지 + 비행기/폭탄/5초 도주 | |
| 3 | EnemyNode 자식 시각 제거 | |
| 4 | iOS 고유 이펙트 픽셀 톤 변환 유지 | |
| 5 | BGM/SE 유지 | |
| 6 | dpad 유지 | |
| 7 | 캐릭터 5명 byte-equal | |

Phase J 특히 #4 적용.

## 6. 픽셀 톤 단일 정책

### 폰트
- 인게임: `GameConfig.fontPixel = "Menlo-Bold"` (Phase G/H 사용)
- 메뉴: fontDisplay = "Jua-Regular" 유지

### 색 팔레트

| 토큰 | hex | 용도 |
|---|---|---|
| ganhoPixelHudYellow | #FFD23F | HUD 라벨/COMBO hot/GO!/×10 |
| ganhoPixelHudWhite | #FFFCE0 | HUD 값/3·2·1/+1 점수 |
| ganhoPixelHudCoral | #FF6E5A | TIME 경고/쿨다운 링 |
| ganhoPixelComboGold | #FFC830 | 콤보 ×3 |
| ganhoPixelComboRed | #E0463A | 콤보 ×5·×20 + ComboBreak |
| ganhoPixelOutlineBlack | #0F1118 | 픽셀 텍스트 외곽선 |
| ganhoPixelHitRed | #C8281A | HitFlash 풀스크린 |
| ganhoPixelTensionEdge | #FF3D2E | 5초 비네트 |

### zPosition
모든 노드 기존 zPosition 상수 0줄 변경. 톤만 swap.

## 7. 변경 범위

### 수정 (9개)
- GameConfig.swift: 픽셀 톤 상수 신규 (추가만)
- HUDNode.swift: HUDSlotNode 라벨/값 fontName + fontColor 픽셀 톤 swap
- HUDSkillSlotNode.swift: fontName + 링 stroke READY=옐로/쿨다운=코랄
- ComboPopupNode.swift: fontDisplay → fontPixel, color(for:) 픽셀 팔레트
- ComboBreakNode.swift: fontPixel + ganhoPixelComboRed + 외곽선
- ScorePopupNode.swift: fontPixel + color(for:) 픽셀 톤
- SparkleEffectNode.swift: context 분기, .ingame 픽셀 입자 / .menu 원형 유지
- CountdownNode.swift: context 분기, 3·2·1 픽셀화이트 / GO! 픽셀옐로
- HitFlashNode.swift: ganhoPixelHitRed + blendMode .add

### 신규 (1개)
- TensionVignetteNode.swift: 5초 긴박감 픽셀 비네트

### 검증만 (0줄)
- BombFlashNode.swift (Phase G 적용 완료)

## 8. 기능 1 — HUDNode

```swift
labelNode = SKLabelNode(fontNamed: GameConfig.fontPixel)
labelNode.fontColor = .ganhoPixelHudYellow
valueNode = SKLabelNode(fontNamed: GameConfig.fontPixel)
valueNode.fontColor = .ganhoPixelHudWhite
// setWarn: ganhoCoralShadow → ganhoPixelHudCoral
```

외부 API(update/setCharacterName/startTensionBlink/stopTensionBlink) 시그니처 0줄.

## 9. 기능 2 — HUDSkillSlotNode

fontName 픽셀. ringNode.strokeColor ganhoMusicGold(0.3) → ganhoPixelHudYellow(0.3). ringFillNode READY .ganhoMusicGold → .ganhoPixelHudYellow. 쿨다운 .ganhoCoralPrimary → .ganhoPixelHudCoral. valueNode READY 색도 픽셀 옐로. 4상태 분기/configure/oncePerGame/alpha 보간 0줄.

## 10. 기능 3 — ComboPopupNode

fontDisplay → fontPixel. addOutline navy → ganhoPixelOutlineBlack. color(for:) 매핑:
- 3 → ganhoPixelComboGold
- 5 → ganhoPixelComboRed
- 10 → ganhoPixelHudYellow
- 20 → ganhoPixelComboRed

animate SKAction 0줄, zRotation -8° 유지.

## 11. 기능 4 — ComboBreakNode

fontPixel + .ganhoPixelComboRed + 외곽선 .ganhoPixelOutlineBlack. animate 0줄.

## 12. 기능 5 — ScorePopupNode

fontNamed: fontPixel. color(for:):
- scorePerNote → ganhoPixelHudWhite
- scorePerNoteCombo → ganhoPixelHudYellow

spawn 정적 팩토리 시그니처 0줄.

## 13. 기능 6 — SparkleEffectNode (context 분기)

```swift
enum SparkleContext { case ingame, menu }

init(context: SparkleContext = .ingame) {
    super.init()
    self.context = context
    buildParticles()
}

private func buildParticles() {
    for _ in 0..<GameConfig.sparkleParticleCount {
        let particle: SKNode
        switch context {
        case .ingame:
            particle = SKSpriteNode(color: .ganhoPixelHudWhite,
                                    size: CGSize(width: GameConfig.sparklePixelSize,
                                                 height: GameConfig.sparklePixelSize))
        case .menu:
            let shape = SKShapeNode(circleOfRadius: GameConfig.sparkleParticleRadius)
            shape.fillColor = .white
            shape.strokeColor = .clear
            particle = shape
        }
        particle.position = .zero
        addChild(particle)
    }
}
```

호출부:
- GameScene.swift L567/L657 → `.ingame`
- ResultScene.swift L788 → `.menu`

emit SKAction 0줄.

## 14. 기능 7 — CountdownNode (context 분기)

```swift
enum CountdownContext { case ingame, menu }
override init() { self.init(context: .ingame) }   // 호환성
init(context: CountdownContext) {
    let fontName = (context == .ingame) ? GameConfig.fontPixel : GameConfig.fontDisplay
    self.label = SKLabelNode(fontNamed: fontName)
    ...
}
// 3·2·1: .ganhoPixelHudWhite (vs .ganhoNavyDeep 메뉴)
// GO!: .ganhoPixelHudYellow (vs .ganhoCoralPrimary 메뉴)
```

SKAction sequence/fadeIn/fadeOut/hold/scaleUp 0줄.

## 15. 기능 8 — HitFlashNode

```swift
super.init(texture: nil, color: .ganhoPixelHitRed, size: .zero)
blendMode = .add
```

peakAlpha 0.6 → 0.5 조정 허용 (시뮬레이터 검증 후). SKAction 0줄.

## 16. 기능 9 — TensionVignetteNode 신규

```swift
final class TensionVignetteNode: SKNode {
    init(sceneSize: CGSize) {
        super.init()
        name = "tensionVignette"
        zPosition = GameConfig.tensionVignetteZPosition   // 110 (HUD 100~101 위, countdown 250 아래)
        let thickness = GameConfig.tensionVignetteThickness   // 8pt
        // 상/하/좌/우 4 SKSpriteNode 가장자리 inset
        // 색 ganhoPixelTensionEdge, alpha 0.6
        // 4 자식 모두 SKAction.repeatForever blink (fadeAlpha 0.3 ↔ 0.7, 0.5s)
    }
    required init?(coder: NSCoder) { fatalError() }
}
```

GameScene에서 `startTensionBlink` 호출 직후 attach, `stopTensionBlink`에서 removeFromParent. cameraNode 자식.

HUDNode.startTensionBlink/stopTensionBlink 시그니처 0줄. GameScene가 비네트 attach/detach 2~3줄만 추가.

## 17. GameConfig 신규 상수

```swift
// Sprint 10 Phase J
static let fontPixel: String = "Menlo-Bold"
static let sparklePixelSize: CGFloat = 3
static let tensionVignetteThickness: CGFloat = 8
static let tensionVignetteZPosition: CGFloat = 110
static let tensionVignetteEdgeAlpha: CGFloat = 0.6
static let tensionVignetteBlinkHalfPeriod: TimeInterval = 0.5
```

ColorTokens 또는 GameConfig 픽셀 팔레트 enum에 색 8개 추가 (§6 표).

## 18. 변경 금지 (git diff 0줄)

- PixelSprite/PixelPalette/PixelSpriteRenderer 본체
- GameScene+Setup.swift (게임 루프/스폰/충돌/맵/AI) — 단, 비네트 attach/detach 2~3줄만 GameScene.swift에 추가
- ContactRouter, SergeantParkNode, AirplaneNode 본체
- 5종 컷씬 노드 (IntroCutsceneNode/MidCutsceneNode/IntroVillainCutsceneNode/CutsceneOverlayNode/CutsceneTexts)
- BombFlashNode (Phase G 완료)
- 메뉴 6 씬 + 메뉴 노드 14 (단, ResultScene SparkleEffectNode 호출부 `.menu` 인자 명시 1줄만 예외)
- Phase A~I 산물

## 19. 합격 기준

1. 인게임 모든 텍스트 Menlo-Bold (HUD 4슬롯 + 스킬 슬롯 + 콤보 팝업/브레이크 + 점수 팝업 + 카운트다운)
2. 메뉴 UI Jua-Regular + 코랄/네이비 카툰 그대로
3. HUD 색: 라벨=픽셀옐로, 값=픽셀화이트, TIME 경고=픽셀코랄
4. sparkle 인게임 8 × 3pt 사각 / ResultScene 신기록 원형 유지
5. 카운트다운 3·2·1 픽셀화이트, GO! 픽셀옐로
6. 5초 긴박감 TIME 깜빡임 + 픽셀 비네트 동시 활성, 정확 detach
7. HitFlash 픽셀톤 빨강 + .add
8. Phase A~I 산물 + 메뉴 6+14 git diff 0줄 (ResultScene 1줄 예외)
9. 가중 평균 7.5 이상

## 20. 평가 5축

| 축 | 가중 | 합격선 |
|---|---|---|
| Swift/SpriteKit 패턴 | 20% | 7.0 |
| 원본 1:1 일치도 | 30% | 7.5 |
| 성능 | 15% | 7.0 |
| 시각 일관성 | 20% | 7.5 |
| 기능 완성도 | 15% | 8.0 |

가중 평균 7.5 이상 → 합격 → **Sprint 10 전체 완료**.

## 21. 잠재 위험 / OQ

- **OQ-1** HUD 폰트 자릿수: Menlo-Bold가 Jua-Regular보다 폭 넓을 수 있음. SCORE/COMBO 3자리 시 알약 폭 초과 검증. 초과 시 신규 hudSlotPixelValueFontSize 추가.
- **OQ-2** SparkleEffectNode context 누락: ResultScene `.menu` 명시 누락 시 신기록 픽셀 입자로 톤 충돌. 호출부 grep + 명시 필수.
- **OQ-3** CountdownNode context: 현재 호출 1곳(인게임)만, 기본값 `.ingame`으로 호환.
- **OQ-4** 비네트 SRP: HUD startTensionBlink는 timeSlot 깜빡임만, 비네트는 별도 노드. GameScene가 두 책임 순차 호출.
- **OQ-5** BombFlashNode 검증: Phase G 완료, Phase J 0줄.
- **OQ-6** HitFlashNode .add 합성: 기존 peakAlpha 0.6 + .add 너무 밝을 위험. 0.6 → 0.5 1줄 조정 허용.

## 22. 관련 파일

- Nodes/HUDNode.swift, HUDSkillSlotNode.swift, ComboPopupNode.swift, ComboBreakNode.swift, ScorePopupNode.swift, SparkleEffectNode.swift, CountdownNode.swift, HitFlashNode.swift, TensionVignetteNode.swift(신규), BombFlashNode.swift(0줄)
- Config/GameConfig.swift, ColorTokens.swift
- GameScene.swift (비네트 attach/detach 2~3줄)
- Scenes/ResultScene.swift (SparkleEffectNode 호출부 1줄)
