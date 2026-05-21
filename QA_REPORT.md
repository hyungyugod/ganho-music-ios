# QA 검수 보고서 — Sprint 10 Phase J (마지막 Phase)

## 1. SPEC §8~§17 기능 검증

| 항목 | SPEC 위치 | 결과 | 근거 |
|---|---|---|---|
| HUDNode fontPixel + 라벨=옐로/값=화이트/TIME 경고=코랄 + 콤보 hot 픽셀 옐로 | §8 | PASS | HUDNode.swift L140/142(fontPixel), L182(labelNode.fontColor=ganhoPixelHudYellow), L194(valueNode=ganhoPixelHudWhite), L233(ganhoPixelHudCoral), L65(comboSlot ≥3 ganhoPixelHudYellow) |
| HUDNode 외부 API 시그니처 0줄 | §8 | PASS | update/setCharacterName/startTensionBlink/stopTensionBlink 시그니처 보존 |
| HUDSkillSlotNode fontPixel + 링 옐로/코랄 + READY 옐로 | §9 | PASS | HUDSkillSlotNode.swift L29/31(fontPixel), L53(ringNode ganhoPixelHudYellow α0.3), L131-134(READY ganhoPixelHudYellow), L141(쿨다운 ganhoPixelHudCoral) |
| HUDSkillSlotNode configure/oncePerGame/alpha 0줄 | §9 | PASS | 시그니처 0건 변경 |
| ComboPopupNode fontPixel + 외곽선 픽셀 + color(for:) 매핑 | §10 | PASS | ComboPopupNode.swift L28(fontPixel), L87/90(outline fontPixel + ganhoPixelOutlineBlack), L103-110(3→ComboGold, 5→ComboRed, 10→HudYellow, 20→ComboRed) |
| ComboPopupNode animate SKAction 본문 0줄, zRotation -8° 유지 | §10 | PASS | L51-61 SKAction 본문 byte-equal, L39 zRotation -8° 유지 |
| ComboBreakNode fontPixel + ganhoPixelComboRed + 외곽선 | §11 | PASS | ComboBreakNode.swift L27(fontPixel), L67(ganhoPixelComboRed), L85/88(outline fontPixel + ganhoPixelOutlineBlack) |
| ComboBreakNode animate 0줄 | §11 | PASS | L48-58 SKAction 본문 byte-equal |
| ScorePopupNode fontPixel + color(for:) 픽셀 | §12 | PASS | ScorePopupNode.swift L43(fontPixel), L108-114(scorePerNote→ganhoPixelHudWhite, scorePerNoteCombo→ganhoPixelHudYellow) |
| ScorePopupNode spawn 정적 팩토리 시그니처 0줄 | §12 | PASS | static spawn(at:gainedPoints:parent:) 시그니처 보존 |
| SparkleContext enum + buildParticles 분기 + GameScene 2곳/ResultScene 1곳 명시 | §13 | PASS | SparkleEffectNode.swift L23-28(enum), L54-76(분기), GameScene L577/L668(`.ingame`), ResultScene L789(`.menu`) |
| SparkleEffectNode emit SKAction 0줄 | §13 | PASS | L82-99 SKAction 본문 byte-equal |
| CountdownContext enum + init(context:) + convenience init() | §14 | PASS | CountdownNode.swift L24-29(enum), L42-44(override convenience init), L47-56(신규 init), L49(fontName 분기), L78(tickColor 분기), L118(goColor 분기) |
| CountdownNode SKAction sequence/fadeIn/fadeOut/hold/scaleUp 0줄 | §14 | PASS | L106-110, L130-138 SKAction 본문 byte-equal |
| HitFlashNode ganhoPixelHitRed + blendMode .add | §15 | PASS | HitFlashNode.swift L24(ganhoPixelHitRed), L28(blendMode .add) |
| TensionVignetteNode 신규 (4변 inset + 깜빡임 + 110 zPos) | §16 | PASS | TensionVignetteNode.swift L23-101 — init(sceneSize:) + 4 SKSpriteNode + repeatForever fadeAlpha 0.3↔0.7 |
| GameScene startTensionBlink 부근 attach + stopTensionBlink 부근 detach | §16 | PASS | GameScene.swift L437-443(tensionStarted 가드 후 attach), L894-895(removeFromParent + nil 토글) |
| GameConfig fontPixel + sparklePixelSize + tensionVignette* 6+ 상수 | §17 | PASS | GameConfig.swift L2747(fontPixel), L2750(sparklePixelSize=3), L2752(thickness=8), L2755(zPos=110), L2757(EdgeAlpha=0.6), L2760(BlinkHalfPeriod=0.5), L2762/2764(BlinkAlphaMin/Max — SPEC 외 보강 2개 허용) |
| ColorTokens 픽셀 팔레트 8색 (§6 표) | §17 | PASS | ColorTokens.swift L331-348 — 8색 모두 hex byte-equal |

**SPEC 기능 19개 항목 모두 PASS**.

## 2. 픽셀 톤 일관성 — 메뉴 카툰 vs 인게임 픽셀 분리

| 영역 | 톤 | 검증 |
|---|---|---|
| 인게임 HUD 4슬롯 (TIME/SCORE/COMBO/PLAYER) | Menlo-Bold + 픽셀 옐로/화이트/코랄 | PASS — HUDNode swap 완료 |
| 인게임 스킬 슬롯 | Menlo-Bold + 픽셀 옐로/코랄 | PASS — HUDSkillSlotNode swap 완료 |
| 인게임 콤보 마일스톤 팝업 | Menlo-Bold + 픽셀 4색 + 외곽선 블랙 | PASS — ComboPopupNode L103-110 |
| 인게임 콤보 끊김 팝업 | Menlo-Bold + 픽셀 컴보 레드 + 외곽선 | PASS — ComboBreakNode |
| 인게임 +1/+2 점수 팝업 | Menlo-Bold + 픽셀 화이트/옐로 | PASS — ScorePopupNode |
| 인게임 sparkle (음표/변기 보너스) | 3×3pt 정사각 페이퍼 화이트 | PASS — GameScene `.ingame` 2곳 |
| 인게임 카운트다운 3·2·1·GO! | Menlo-Bold + 픽셀 화이트/옐로 | PASS — CountdownNode `.ingame` |
| 인게임 HitFlash 풀스크린 | 픽셀 진홍 #C8281A + .add | PASS — HitFlashNode |
| 인게임 5초 비네트 4변 깜빡임 | 픽셀 형광 코랄 #FF3D2E | PASS — TensionVignetteNode |
| 메뉴 SparkleEffect (ResultScene 신기록) | 원형 + 순백(카툰) | PASS — `.menu` 명시 1줄 |
| 메뉴 6 씬 (Start/CharacterSelect/Difficulty/Skill/Scoreboard/Result) | Jua-Regular + 코랄/네이비 | PASS — ResultScene 1줄 예외 외 git diff 0줄 |
| 메뉴 노드 14 (CharacterFace/Card/NurseAvatar/PrimaryButton 등) | v2 카툰 | PASS — git diff 0줄 |

**픽셀↔카툰 시각 분리 완전 확립**. 메뉴 진입 시 부드러운 카툰 톤 그대로, 인게임 진입 즉시 8-bit 톤 통째 전환.

## 3. 변경 금지 (git diff 0줄 / Phase J 한정)

| 영역 | 결과 | 비고 |
|---|---|---|
| PixelSprite/PixelPalette/PixelSpriteRenderer 본체 | PASS | Phase J 세션에서 본체 미수정. working tree의 누적 diff는 Phase A~I 산물 |
| GameScene+Setup.swift | PASS | Phase J 세션에서 미수정 (게임 루프/스폰/충돌). GameScene.swift만 5줄(비네트 attach/detach) 추가 — SPEC §18 명시 허용 |
| ContactRouter / SergeantParkNode / AirplaneNode | PASS | Phase J 세션에서 미수정 |
| BombFlashNode | PASS | Phase G에서 적용 완료, Phase J 0줄 |
| 5종 컷씬 노드 (IntroCutsceneNode/MidCutsceneNode/IntroVillainCutsceneNode/CutsceneOverlayNode/CutsceneTexts) | PASS | Phase J 0줄 |
| 메뉴 6 씬 (StartScene/CharacterSelectScene/SkillExplanationScene/DifficultySelectScene/ScoreboardScene/ResultScene) | PASS | ResultScene 1줄 예외 (sparkle `.menu`) — SPEC §18 명시. 그 외 메뉴 5씬 Phase J 0줄 |
| 메뉴 노드 14 | PASS | Phase J 0줄 |
| Phase A~I 산물 | PASS | Phase J 세션에서 미수정 |

**변경 금지 위반 0건**. ResultScene 1줄 예외도 SPEC §18 "ResultScene SparkleEffectNode 호출부 `.menu` 인자 명시 1줄만 예외" 명시 그대로 적용. `git diff` 확인 시 해당 라인은:

```
+            // Sprint 10 Phase J — .menu 명시. 메뉴 v2 카툰 톤(원형 순백) 유지 — 인게임 픽셀 톤과 분리.
+            let sparkle = SparkleEffectNode(context: .menu)
```

## 4. AI 슬롭 패턴 / Swift·SpriteKit 규칙

| 패턴 | 결과 | 검증 |
|---|---|---|
| 강제 언래핑 `!` 남발 | PASS | Phase J 9 파일에서 0건 |
| Timer.scheduledTimer 사용 | PASS | 0건 |
| update() 안에 addChild() | PASS | 0건 — SparkleEffect/Countdown 모두 init/start 시점 addChild |
| 매직 넘버 하드코딩 | PASS | 모든 수치 GameConfig 상수 (sparklePixelSize, tensionVignetteThickness 등) |
| 클로저 self 강한 캡처 | PASS | CountdownNode.stepAction/goAction `[weak self]` 캡처, HUDSlotNode.startBlink `[weak self]` 캡처 |
| switch default 누락 (context enum) | PASS | SparkleContext/CountdownContext 모두 exhaustive 2-case switch — default 0 |
| SKAction 본문 변경 (시간/거리/scale) | PASS | ComboPopup/ComboBreak/ScorePopup/SparkleEffect/Countdown/HitFlash 모두 색/폰트 swap만 발생 |
| MARK 섹션 구분 | PASS | TensionVignetteNode 포함 모든 파일 MARK 적절 사용 |
| guard/if let 옵셔널 처리 | PASS | tensionVignette?.removeFromParent() 옵셔널 체이닝 |

## 5. 빌드 검증

```
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug build
...
** BUILD SUCCEEDED **
```

- 결과: **BUILD SUCCEEDED**
- 신규 Swift 컴파일 에러: 0
- 신규 Swift 경고: 0
- 잔존 경고: 폰트 ttf 3개 중복 빌드 (기존 경고, Phase J 무관 — Resources/Fonts/Jua-Regular.ttf 등이 Copy Bundle Resources 단계에 중복 등록)

## 6. 5축 채점

| 축 | 가중 | 점수 | 가중점 | 근거 |
|---|---|---|---|---|
| Swift/SpriteKit 패턴 | 20% | 9.5 | 1.90 | 강제 언래핑 0, Timer 0, switch default 0, [weak self] 캡처 유지, MARK 구분, SKAction 본문 0줄, update-내-addChild 0, as! 0 |
| 원본 1:1 일치도 | 30% | 9.0 | 2.70 | 본 Phase는 *원본 1:1*보다 *iOS 고유 이펙트 픽셀 톤 변환*(SPEC §3 사용자 결정 #4). 색 hex 8개 SPEC §6 byte-equal, 폰트 Menlo-Bold byte-equal |
| 성능 | 15% | 9.0 | 1.35 | TensionVignetteNode 4 SKSpriteNode + 4 repeatForever fadeAlpha — 60fps 안전. detach 시 SpriteKit이 자식 액션 자동 정리. 새 텍스처 0. HitFlash .add 단발성 0.3s |
| 시각 일관성 | 20% | 9.5 | 1.90 | 인게임 HUD/팝업/카운트다운/이펙트 모두 Menlo-Bold + 픽셀 팔레트 통일. 메뉴 v2 카툰 톤 git diff 0(ResultScene 1줄 예외 SPEC 명시) |
| 기능 완성도 | 15% | 9.5 | 1.425 | SPEC §8~§17 19개 항목 모두 PASS. TensionVignetteNode 신규 + GameScene 비네트 attach/detach 정확 멱등 + 빌드 통과 |

**가중 평균: 1.90 + 2.70 + 1.35 + 1.90 + 1.425 = 9.275 / 10**

## 7. 최종 판정

### Phase J: ✅ 합격 (가중 9.28/10, 합격선 7.5 충족)

5축 모두 합격선 초과 — Swift 패턴 9.5 (>7.0), 원본 1:1 9.0 (>7.5), 성능 9.0 (>7.0), 시각 일관성 9.5 (>7.5), 기능 완성도 9.5 (>8.0).

### Sprint 10 전체 완료 — 🎉 10 Phase 합격

`DESIGN_RENEWAL_STATE.md`의 Sprint 10 진행 로그를 기준으로 각 Phase 점수 추정(SELF_CHECK §1 LOC delta + 본 보고서 가중 평균):

| Phase | 점수 | 비고 |
|---|---|---|
| A — 픽셀 시각 노출 | (이전 합격) | PlayerNode + PixelSpriteRenderer |
| B — 맵 크기·카메라 정합 | (이전 합격) | 32×20 타일 |
| C — 맵 빌더 3종 (벽) | (이전 합격) | easy/normal/hard 맵 |
| D — 수간호사 4지점 + F 투척 | (이전 합격) | NurseAvatarNode 패트롤 |
| E — 음표·F·A·변기·청진기 픽셀 | (이전 합격) | NoteNode/AItem/ToiletNode/Stethoscope |
| F — 이교수·석조무사 픽셀 + AI | (이전 합격) | EnemyNode 자식 제거 + 8자/4지점 |
| G — 박병장 이스터에그 3단계 | (이전 합격) | SergeantPark + Airplane + Bomb |
| H — 컷씬 5종 | (이전 합격) | Intro/Mid/IntroVillain |
| I — 난이도·점수·콤보 수치 | (이전 합격) | GameConfig 원본 표 |
| J — HUD·이펙트 픽셀 톤 | **9.28** | 본 보고서 |

Sprint 10 전체 합격 — **메뉴 카툰 톤 + 인게임 8-bit 톤** 분리 완성, 원본 웹게임 1:1 픽셀 이식 완료.

## 8. 잔존 P1/P2 (Phase J 한정 — 결함 0건)

P0/P1 결함 0건. 아래 2건은 *향후 폴리싱 권장*이며 합격 영향 0.

### P2-1 (권장) — HitFlashNode peakAlpha 시뮬레이터 검증 후 미세 조정 여지
- **파일**: `HitFlashNode.swift:24-28`
- **현재 코드**: `super.init(texture: nil, color: .ganhoPixelHitRed, size: .zero); blendMode = .add`
- **상황**: 기존 `hitFlashPeakAlpha` 0.55 + 신규 `.add` 합성 → 시뮬레이터에서 너무 밝을 수 있음. SPEC §15 OQ-6 "0.6 → 0.5 1줄 조정 허용" 명시.
- **권장**: 시뮬레이터 실측 후 필요 시 `GameConfig.hitFlashPeakAlpha 0.55 → 0.45` 1줄 조정. 본 Phase J에서는 미적용 (보수적 보존).

### P2-2 (권장) — TensionVignetteNode 화면 회전 대응 (현재 미해당)
- **파일**: `TensionVignetteNode.swift:29`
- **현재 코드**: `init(sceneSize: CGSize)` — init 시점 sceneSize 캡처
- **상황**: iOS는 Landscape 고정 → 회귀 위험 0. 미래 Portrait 지원 시 화면 회전 발생하면 4변 위치 불일치 가능.
- **권장**: 필요 시 GameScene.didChangeSize에서 비네트 재생성. 현재 우선순위 낮음.

## 9. 회귀 우려 5건

1. **메뉴 카툰 톤 보존** — ResultScene 1줄 예외 외 메뉴 6 씬/14 노드 git diff 0줄. 메뉴 진입 시 v2 코랄/네이비 톤 그대로 노출. **위험: 매우 낮음**.

2. **HUD startTensionBlink/stopTensionBlink 멱등성** — `tensionStarted` 가드 통과 1회만 비네트 attach. stopTensionBlink는 `tensionVignette?.removeFromParent() + nil 토글` — 중복 호출/0초 만료/F 피격/enemy 접촉 모든 경로에서 안전. **위험: 낮음**.

3. **CountdownNode 호출부 호환** — GameScene `CountdownNode()` 기본 init 호출이 `override convenience init` 통해 `.ingame` 자동 위임. 호출부 변경 0줄. 다만 SelfDismissingNode 프로토콜이 init() 요구사항 가질 경우 차후 검증 필요. **위험: 낮음**.

4. **HitFlashNode blendMode .add + peakAlpha 0.55 시각** — `.add` 가산 합성으로 풀스크린이 기존보다 *더 밝게* 발화 가능. F 피격이 잦은 hard 난이도에서 시각 피로 우려. 0.42s 단발성이라 60fps 안전하나, 사용자 체감 시 SPEC §15 OQ-6의 0.5 조정 옵션 활용. **위험: 중간 (시뮬레이터 실측 권장)**.

5. **TensionVignetteNode + HUD tensionBlink 동기 박자** — 둘 다 0.5s halfPeriod이나 *시작 시점*이 다르면 위상 차로 어색할 수 있음. 현재 두 노드 모두 `tensionStarted` 가드 1회 통과 시 같은 프레임에서 발화 → 위상 동기 자연 보장. SpriteKit `fadeAlpha(to:)`는 absolute target이므로 양쪽 fadeIn/fadeOut 보간이 동일 박자로 진행. **위험: 낮음**.

---

## 종합

Phase J는 **마지막 픽셀 톤 통일 작업**으로, 9개 노드 색·폰트 swap + 1개 신규 노드(TensionVignetteNode) + GameConfig 9 상수 + ColorTokens 8색 추가로 SPEC §6~§17 19개 항목 모두 byte-equal 적용. 빌드 통과, SKAction 본문/외부 API 시그니처 0줄 변경, 메뉴 v2 카툰 톤 보존(ResultScene 1줄 예외만), 변경 금지 영역 git diff 0줄. 

**가중 9.28/10 합격 → Sprint 10 전체 (10 Phase A~J) 합격 → 원본 웹게임 1:1 픽셀 이식 작업 완료**.
