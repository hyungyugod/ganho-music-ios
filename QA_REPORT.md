# QA 검수 보고서 — Phase 8-5 HUD 디자인 동일화 (상단 가로 4슬롯)

## SPEC 기능 검증

- [PASS] **기능 1 — GameConfig HUD 신규 상수 6개**
  `Config/GameConfig.swift` L701-710 `// MARK: - HUD Layout (Phase 8-5)` 블록에 `hudTopMargin: 28`, `hudSlotSpacing: 80`, `hudValueFontSize: 22`, `hudLabelFontSize: 10`, `hudSlotInnerGap: 4`, `hudLabelLetterSpacing: 2` 전부 존재. 원본 `.game-hud__label`(10px) / `.game-hud__value`(22px) 1:1 매핑 주석 부착.

- [PASS] **기능 2 — HUDNode 가로 4슬롯 재구성**
  `Nodes/HUDNode.swift` 전부 재작성:
  - 4 SKNode 자식: `timeSlot`(x=-120) / `scoreSlot`(x=-40) / `comboSlot`(x=+40) / `nameSlot`(x=+120), spacing = 80 (L36-39).
  - `HUDSlotNode` 신규 클래스 **같은 파일** 정의 (L92-168) — pbxproj 변경 0.
  - 슬롯 1개 = `SKNode` + `labelNode`(위 10pt `.ganhoUITextDim`, L109-117) + `valueNode`(아래 22pt `.ganhoUIText`, L121-129) 2단 구조.
  - 라벨 텍스트: `TIME` / `SCORE` / `COMBO` / `PLAYER` 영문 대문자만 (이모지 0).
  - 콤보 hot: `combo >= 3 ? .ganhoUIBrandLight : .ganhoUIText` (L60).
  - tensionBlink: `timeSlot.startBlink(color: .ganhoUIBrandLight)` (L77).

- [PASS] **기능 3 — GameScene.layoutHUD 위치 변경**
  `GameScene.swift` L275-284: 좌상단 `(-(halfW - hudMarginX), +(halfH - hudMarginY))` → 상단 중앙 `(0, +(halfH - hudTopMargin))`. `halfW` 변수 제거(미사용), `halfH`만 유지. 단 1 메서드 내부 변경, 호출자 전부 무수정.

## 빌드 검증

- **결과**: BUILD SUCCEEDED
- **명령**: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'generic/platform=iOS Simulator' -configuration Debug build`
- **컴파일 에러**: 0건
- **컴파일 경고**: 0건 (`grep -iE "warning:|error:"` 결과 비어 있음. `appintentsmetadataprocessor`의 `No AppIntents.framework dependency` 안내는 앱이 AppIntents 미사용이라 무관)

## 엄격 검증 항목 11개 결과

| # | 항목 | 결과 | 증거 |
|---|---|---|---|
| 1 | HUDNode 외부 인터페이스 4개 보존 | PASS | `update(score:remainingTime:combo:)`(L55), `setCharacterName(_:)`(L67), `startTensionBlink()`(L76), `stopTensionBlink()`(L82) 시그니처 동일. 호출자 5건(`GameScene.swift:311/359/537/542`, `GameScene+Setup.swift:246`) 무수정 컴파일 통과 |
| 2 | 상단 가로 4슬롯 구조 (timeSlot/scoreSlot/comboSlot/nameSlot, x ±120/±40, spacing 80) | PASS | `HUDNode.swift` L20-23 프로퍼티, L36-39 위치 — `-spacing*1.5=-120`, `-spacing*0.5=-40`, `+spacing*0.5=+40`, `+spacing*1.5=+120` |
| 3 | HUDSlotNode 신규 클래스 같은 파일 안 — pbxproj 변경 0 | PASS | `HUDNode.swift` L92-168 `final class HUDSlotNode: SKNode` 같은 파일 정의. `git diff HEAD -- "GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj" \| wc -l` = 0 |
| 4 | 라벨 토큰 (labelNode 10pt `.ganhoUITextDim` / valueNode 22pt `.ganhoUIText` / 콤보 3+ `.ganhoUIBrandLight`) | PASS | L109-110, L121-122 토큰 정확. L60 콤보 분기 정확 |
| 5 | tensionBlink 색 `.ganhoUIBrandLight` 적용, startBlink/stopBlink 동작 | PASS | `startTensionBlink` L77 `timeSlot.startBlink(color: .ganhoUIBrandLight)`. `HUDSlotNode.startBlink` L154-160 SKAction sequence + `repeatForever` + `tensionBlinkActionKey`. `stopBlink` L164-167 removeAction + 복원 |
| 6 | GameScene layoutHUD 위치 `(0, +halfH - hudTopMargin)` | PASS | `GameScene.swift` L277-284 정확히 일치 |
| 7 | 이모지 제거 (🎵 / ⏱ / 🔥 없음) | PASS | `grep -nE "🎵\|⏱\|🔥" HUDNode.swift` 결과 비어 있음 |
| 8 | 회귀 0 영역 git diff 0줄 | PASS | TitleScene/ResultScene/GameScene+Setup diff = 0. pbxproj diff = 0. 변경 파일 = Config/HUDNode/GameScene 3개만 (GameScene는 layoutHUD 1메서드 6라인) |
| 9 | 빌드 BUILD SUCCEEDED, 경고 0 | PASS | 위 §빌드 검증 |
| 10 | 정적 검사 (강제 언래핑 / Timer / DispatchQueue / 매직 넘버 0건) | PASS | `grep` 결과 모두 0. 모든 숫자는 `GameConfig.hudSlotSpacing` 등 토큰 경유 (L35, L109, L116, L121, L128) |
| 11 | 콤보 3+ 토큰 갈아 끼움 (`combo >= 3 ? .ganhoUIBrandLight : .ganhoUIText`) | PASS | L60 정확 일치 |

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## 통과 항목

- **Swift 패턴**: `guard let`/`if let` 옵셔널 처리, MARK 6개 섹션(Properties / Init / Update / Character Name / Tension / HUDSlotNode 내부 Properties / Init / Setters / Tension Blink), 함수 단일 책임(setValue/setValueColor/startBlink/stopBlink 1책임), 모든 숫자 GameConfig 토큰 경유.
- **SpriteKit 패턴**: HUD가 `cameraNode` 자식으로 화면 고정 (게임 월드와 분리), `SKAction.sequence`+`repeatForever`+`withKey` 스폰 패턴, `Timer`/`DispatchQueue` 미사용, `tensionBlinkActionKey` 멱등성 보존.
- **성능 & 안정성**: 강제 언래핑 0건, `SKAction.run` 클로저 2개 모두 `[weak self]` 캡처(L155-156), `update()` 내 `addChild()` 반복 0(매 프레임 호출은 `setValue` 텍스트 갱신만), 빌드 클린.
- **게임 디자인 정합성**: 원본 `.game-hud` (game.css L232-289) 1:1 시각 이식 — 라벨 10px text-dim / 값 22px text / 콤보 3+ brand-light / warning brand-light 모두 정확. 톤 = 코럴(Phase 8-3 토큰) 일관.
- **Sprint 범위 준수**: 신규 파일 0개, pbxproj 변경 0건, 회귀 0 영역(`TitleScene`/`ResultScene`/`GameScene+Setup`/Systems/Managers/Repositories/Models/ColorTokens/PixelSprite/PlayerNode/EnemyNode/iOS·tvOS·macOS 진입점) 모두 미접촉.

## 화면 안전성

- `hudSlotSpacing × 4 = 320pt` 가로 폭, 중앙 ±160pt.
- iPhone 16:9 ~568pt landscape에서 ±160 < 568/2=284 — 안전.
- iPhone 17 Pro Max landscape(956pt) 충분 여유.

---

## 채점

**항목별 점수**:
- Swift 패턴 일관성: 10/10 → MARK 6개·매직 넘버 0·`[weak self]`·함수 단일 책임 모두 모범
- 게임 로직 완성도: 10/10 → SKAction 멱등 패턴·HUD 화면 고정·외부 인터페이스 4개 시그니처 보존
- 성능 & 안정성: 10/10 → 강제 언래핑 0·weak self 캡처·빌드 클린·매 프레임 노드 생성 0
- 기능 완성도: 10/10 → SPEC 기능 3개 + 엄격 검증 11항목 전부 PASS

**가중 점수 계산**: (10×0.35) + (10×0.30) + (10×0.20) + (10×0.15) = 3.5 + 3.0 + 2.0 + 1.5 = **10.0 / 10.0**

## 최종 판정: **합격**

**자가 검증**: "내가 관대하게 본 것은 아닌가?"
- 강제 언래핑 / Timer / DispatchQueue / 매직 넘버 / 이모지 / pbxproj 변경 / 신규 파일 / 회귀 영역 변경 / 빌드 실패 / 빌드 경고 — 10개 자동 감점 트리거 *모두 0*.
- 외부 인터페이스 시그니처 4개 *완전 보존* (호출자 5건 무수정 컴파일 통과).
- 원본 CSS L232-289 토큰 mapping이 자릿수까지 정확 (label 10/value 22/spacing 80/letter-spacing 2).
- 변경 파일 3개·변경 라인 ~210줄 모두 SPEC 허용 범위. SPEC 금지 §1(tensionBlink 코드 변경) 위반 의심: `startTensionBlink`/`stopTensionBlink` 메서드 시그니처/액션 키/주기 모두 동일하고 *색만 갈아 끼움* — 금지 §1의 "색만 갈아 끼움" 조건 정확 충족, 위반 아님.

**구체적 개선 지시**: 없음 (다음 sprint 후보 — `hudFontSize/hudMarginX/hudMarginY/hudCharacterNameOffsetX/hudAlpha` 미사용 상수 정리, 콤보 SKAction bump 애니메이션 도입, `letter-spacing` 대응 위해 attributed string 검토).
