# 자체 점검 — Sprint 10 Phase J (마지막)

전략: Case A — Phase J 1회차. SPEC §6~§17 byte-equal 적용.

## 1. 변경/신규 파일 LOC delta

| 파일 | 변경 유형 | LOC delta (대략) |
|---|---|---|
| Config/ColorTokens.swift | 픽셀 톤 8색 추가 | +33 |
| Config/GameConfig.swift | 픽셀 톤 상수 7개 추가 | +24 |
| Nodes/HUDNode.swift | fontPixel + 픽셀 색 swap (외부 API 0줄) | ~10 변경 |
| Nodes/HUDSkillSlotNode.swift | fontPixel + 픽셀 색 swap | ~12 변경 |
| Nodes/ComboPopupNode.swift | fontPixel + 외곽선 픽셀 + color(for:) 픽셀 | ~10 변경 |
| Nodes/ComboBreakNode.swift | fontPixel + 외곽선 픽셀 + color 픽셀 | ~6 변경 |
| Nodes/ScorePopupNode.swift | fontPixel + color(for:) 픽셀 | ~6 변경 |
| Nodes/SparkleEffectNode.swift | SparkleContext enum + 분기 buildParticles | +24 (재작성) |
| Nodes/CountdownNode.swift | CountdownContext enum + convenience init + 색 분기 | +18 |
| Nodes/HitFlashNode.swift | ganhoPixelHitRed + blendMode .add | +2 변경 |
| Nodes/TensionVignetteNode.swift | 신규 | +101 |
| GameScene.swift | sparkle .ingame 2곳 + vignette attach/detach 5줄 + tensionVignette 프로퍼티 5줄 | +13 |
| Scenes/ResultScene.swift | sparkle .menu 1줄 (1줄 예외 허용) | +2 변경 |
| project.pbxproj | TensionVignetteNode 4 entries | +4 |

총 신규 1개 (TensionVignetteNode), 수정 12개. 모든 외부 API 시그니처 byte-equal.

## 2. SPEC §6~§17 항목 ✓/✗

| 항목 | SPEC 위치 | 결과 |
|---|---|---|
| 픽셀 톤 단일 정책 (폰트/색 팔레트) | §6 | ✓ fontPixel + 8색 추가 |
| HUDNode 픽셀 swap (라벨=옐로, 값=화이트, TIME 경고=코랄) | §8 | ✓ |
| HUDNode 외부 API (update/setCharacterName/startTensionBlink/stopTensionBlink) 시그니처 0줄 | §8 | ✓ |
| HUDSkillSlotNode fontPixel + 링 옐로/코랄 + READY 옐로 | §9 | ✓ |
| HUDSkillSlotNode configure/oncePerGame/alpha 0줄 | §9 | ✓ |
| ComboPopupNode fontPixel + 외곽선 픽셀 + color(for:) 매핑 | §10 | ✓ (3→ComboGold, 5→ComboRed, 10→HudYellow, 20→ComboRed) |
| ComboPopupNode animate SKAction 0줄, zRotation -8° 유지 | §10 | ✓ |
| ComboBreakNode fontPixel + ganhoPixelComboRed + 외곽선 | §11 | ✓ |
| ComboBreakNode animate 0줄 | §11 | ✓ |
| ScorePopupNode fontPixel + color(for:) 픽셀 | §12 | ✓ (scorePerNote→HudWhite, scorePerNoteCombo→HudYellow) |
| ScorePopupNode spawn 정적 팩토리 시그니처 0줄 | §12 | ✓ |
| SparkleContext enum + init(context:) + buildParticles 분기 | §13 | ✓ |
| GameScene SparkleEffectNode 호출 2곳 `.ingame` | §13 | ✓ |
| ResultScene SparkleEffectNode 호출 `.menu` | §13 | ✓ |
| SparkleEffectNode emit SKAction 0줄 | §13 | ✓ |
| CountdownContext enum + init(context:) + 색 분기 | §14 | ✓ |
| CountdownNode override init() → convenience init(context:.ingame) 호환 | §14 | ✓ |
| CountdownNode SKAction sequence/fadeIn/fadeOut/hold/scaleUp 0줄 | §14 | ✓ |
| HitFlashNode ganhoPixelHitRed + blendMode .add | §15 | ✓ |
| HitFlashNode peakAlpha 조정 | §15 | (현재 0.55 유지 — SPEC §15 "0.6 → 0.5 허용"이나 기존이 이미 0.55) |
| TensionVignetteNode 신규 (4변 inset + 깜빡임 + 110 zPos) | §16 | ✓ |
| GameScene startTensionBlink 부근 attach + stopTensionBlink 부근 detach | §16 | ✓ (5줄 추가) |
| GameConfig fontPixel + sparklePixelSize + tensionVignette* 6 상수 | §17 | ✓ (실 7 상수 — 추가 BlinkAlphaMin/Max 2개 포함, BlinkHalfPeriod 1개) |
| ColorTokens 픽셀 팔레트 8색 (§6 표) | §17 | ✓ |

## 3. 변경 금지 git diff 0줄 검증

본 세션(Phase J)에서 손댄 파일 추적:
- PixelSprite.swift / PixelPalette.swift / PixelSpriteRenderer.swift 본체: 0줄 ✓
- GameScene+Setup.swift: 0줄 ✓ (게임 루프/스폰 게임플레이 책임)
- ContactRouter.swift: 0줄 ✓
- SergeantParkNode.swift / AirplaneNode.swift / BombFlashNode.swift: 0줄 ✓
- IntroCutsceneNode/MidCutsceneNode/IntroVillainCutsceneNode/CutsceneOverlayNode/CutsceneTexts: 0줄 ✓
- 메뉴 6 씬(StartScene/CharacterSelectScene/SkillExplanationScene/DifficultySelectScene/ScoreboardScene/ResultScene): ResultScene만 1줄 예외(SPEC §18 명시), 그 외 0줄 ✓
- 메뉴 노드 14(CharacterFaceNode/NurseAvatarNode/CharacterCardNode/DifficultyCardNode/PrimaryButtonNode/BackButtonNode/...): 0줄 ✓
- Phase A~I 산물: 0줄 ✓

## 4. 픽셀 톤 색 hex 8개 + 폰트 Menlo-Bold 검증

| 토큰 | hex | SPEC §6 일치 |
|---|---|---|
| ganhoPixelHudYellow | #FFD23F | ✓ |
| ganhoPixelHudWhite | #FFFCE0 | ✓ |
| ganhoPixelHudCoral | #FF6E5A | ✓ |
| ganhoPixelComboGold | #FFC830 | ✓ |
| ganhoPixelComboRed | #E0463A | ✓ |
| ganhoPixelOutlineBlack | #0F1118 | ✓ |
| ganhoPixelHitRed | #C8281A | ✓ |
| ganhoPixelTensionEdge | #FF3D2E | ✓ |

`GameConfig.fontPixel = "Menlo-Bold"` byte-equal SPEC §17 ✓.

## 5. SparkleEffect/Countdown context 분기 검증

**SparkleContext**:
- `.ingame` (기본값) → SKSpriteNode `sparklePixelSize × sparklePixelSize` (3×3pt) + ganhoPixelHudWhite
- `.menu` → SKShapeNode `sparkleParticleRadius` 원형(반지름 2pt) + .white (메뉴 카툰 유지)
- GameScene 음표 수집 / 변기 보너스: `.ingame` 명시 ✓
- ResultScene 신기록 burst: `.menu` 명시 ✓
- switch에 default 없음 (SPEC §4 금지 위반 0) — case 두 개로 exhaustive ✓

**CountdownContext**:
- `.ingame` (GameScene 호출 — `CountdownNode()` 기본 → convenience init이 `.ingame` 위임) → fontPixel + 3·2·1 픽셀 화이트 + GO! 픽셀 옐로
- `.menu` (현재 호출 0, 호환성 보존) → fontDisplay + 3·2·1 navyDeep + GO! coralPrimary
- override init() → convenience init 자동 위임으로 GameScene 호출부 0줄 변경 ✓
- switch default 0 — `==` 비교 분기로 안전 ✓

메뉴 카툰 톤 보존: 메뉴 6 씬은 모두 fontDisplay/ganhoCoral*/ganhoNavy* 그대로. ResultScene SparkleEffectNode 호출만 `.menu` 인자 추가 (1줄 — SPEC §18 예외).

## 6. 빌드 결과

```
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
...
** BUILD SUCCEEDED **
```

경고: 폰트 ttf 3개 중복 빌드 경고만 발생(기존 경고, Phase J 무관). 신규 Swift 경고 0.

## 7. 5축 자체 평가

| 축 | 자체 점수 | 근거 |
|---|---|---|
| Swift/SpriteKit 패턴 (20%) | 9.5/10 | 강제 언래핑 0, Timer 0, switch default 0, weak self 캡처 보존, MARK 섹션 유지, SKAction 본문 0줄, update()-내-addChild 0 |
| 원본 1:1 일치도 (30%) | 9.0/10 | 본 Phase는 *원본 1:1*보다 *iOS 고유 이펙트 픽셀 톤 변환*(SPEC §3 사용자 결정 #4). 색 hex 8개 SPEC §6 byte-equal |
| 성능 (15%) | 9.0/10 | TensionVignetteNode 4 SKSpriteNode + 4 repeatForever fadeAlpha — 60fps 안전. detach 시 SpriteKit이 자식 액션 자동 정리. 새 텍스처 0. blendMode .add 단발성 0.3s |
| 시각 일관성 (20%) | 9.5/10 | 인게임 HUD/팝업/카운트다운 모두 Menlo-Bold + 픽셀 팔레트로 통일. 메뉴 v2 카툰 톤 git diff 0(ResultScene 1줄 예외 명시) |
| 기능 완성도 (15%) | 9.5/10 | SPEC §8~§17 모든 항목 적용. TensionVignetteNode 신규 + GameScene 비네트 attach/detach 정확 멱등 |

가중 평균: 9.5×0.2 + 9.0×0.3 + 9.0×0.15 + 9.5×0.2 + 9.5×0.15 = 1.9 + 2.7 + 1.35 + 1.9 + 1.425 = **9.275/10** (자체 추정).

## 8. OQ-1~6 처리

| OQ | 항목 | 처리 |
|---|---|---|
| OQ-1 | HUD 폰트 자릿수 (Menlo-Bold > Jua-Regular 폭) | Menlo-Bold 18pt 모노스페이스에서 "9999"(SCORE 4자리) ≈ 40pt, 알약 폭 78pt — 안전 (여유 38pt). TIME "00:45" ≈ 50pt도 안전. **추가 fontSize 상수 신설 불필요** |
| OQ-2 | SparkleEffectNode context 누락 | GameScene 2곳 + ResultScene 1곳 grep 완료, 모두 명시 ✓ |
| OQ-3 | CountdownNode context 호환 | override convenience init() → init(context:.ingame) 자동 위임. GameScene CountdownNode() 호출부 0줄 변경 ✓ |
| OQ-4 | 비네트 SRP | HUD.startTensionBlink는 timeSlot 깜빡임만, TensionVignetteNode는 가장자리만. GameScene이 두 책임 순차 호출 ✓ |
| OQ-5 | BombFlashNode 검증 | Phase G 적용 완료 — git diff 본 Phase J 0줄 ✓ |
| OQ-6 | HitFlashNode .add 합성 | 기존 peakAlpha 0.55 (SPEC §15 "0.6 → 0.5 허용"보다 보수적). .add 추가 시 너무 밝을 우려 없음 — 변경 보류, 향후 시뮬 검증 후 조정 가능 |

## 9. 회귀 우려 5건

1. **메뉴 카툰 톤 보존**: ResultScene 1줄 예외 외 메뉴 6 씬/14 노드 git diff 0줄 — 메뉴 진입 시 v2 톤 그대로 노출 ✓
2. **HUD startTensionBlink/stopTensionBlink 멱등성**: tensionStarted 가드 통과 1회만 attach. stopTensionBlink는 nil 옵셔널 체이닝 + nil 토글 — 중복 호출 안전 ✓
3. **CountdownNode 호출부 호환**: GameScene `CountdownNode()` 기본 init 호출이 convenience init 통해 `.ingame` 위임 — 호출부 변경 0줄 ✓
4. **HitFlashNode blendMode .add 시각 변화**: peakAlpha 0.55 + .add → 시뮬레이터에서 1~2회 시뮬 후 0.5/0.45로 미세 조정 가능. SKAction 본문/시그니처 0줄
5. **TensionVignetteNode 화면 회전**: 현재 init에서 sceneSize 캡처 — 인게임 중 회전 발생 시 4변 위치 불일치 가능. iOS는 Landscape 고정이라 회귀 위험 0. 미래 Portrait 지원 시 재생성 필요

---

## 자체 점검 결과

가중 평균 9.27/10 (자체 추정). SPEC §6~§17 모든 항목 byte-equal 적용. 빌드 SUCCEEDED. 변경 금지 git diff 0줄(ResultScene 1줄 예외 SPEC 명시). Sprint 10 전체 완료 후보.
