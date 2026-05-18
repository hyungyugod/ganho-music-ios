# 자체 점검 — Phase 8-5 HUD 디자인 동일화 (상단 가로 4슬롯)

## SPEC 기능 체크
- [x] **기능 1 — GameConfig 신규 상수 6개** (`Config/GameConfig.swift` L702-710):
  - `hudTopMargin: 28`, `hudSlotSpacing: 80`, `hudValueFontSize: 22`,
    `hudLabelFontSize: 10`, `hudSlotInnerGap: 4`, `hudLabelLetterSpacing: 2`
  - `// MARK: - HUD Layout (Phase 8-5)` 섹션으로 묶음 — 원본 .game-hud(L232-289) 1:1 매핑 주석 부착.
- [x] **기능 2 — HUDNode 가로 슬롯 재구성** (`Nodes/HUDNode.swift` 전부 교체):
  - 기존 `scoreLabel/timeLabel/comboLabel/nameLabel` 4 `SKLabelNode` 폐기 → `timeSlot/scoreSlot/comboSlot/nameSlot` 4 `HUDSlotNode` 자식.
  - `HUDSlotNode` 신규 클래스를 **같은 파일** 내부에 정의 (`pbxproj` 변경 0).
  - 슬롯 1개 = `SKNode` + `labelNode`(위 10pt `.ganhoUITextDim`) + `valueNode`(아래 22pt `.ganhoUIText`) 2단 구조.
  - 가로 배치: `timeSlot x=-spacing*1.5`, `scoreSlot x=-spacing*0.5`, `comboSlot x=+spacing*0.5`, `nameSlot x=+spacing*1.5` (spacing=80pt → 양옆 ±120pt).
  - 라벨 텍스트: `TIME` / `SCORE` / `COMBO` / `PLAYER` 영문 대문자 (이모지 🎵 ⏱ 🔥 전부 제거).
  - 콤보 3+ 시 `valueNode.fontColor = .ganhoUIBrandLight`, 3 미만 = `.ganhoUIText`.
  - `tensionBlink`는 `timeSlot.valueNode`에 적용, 색 `.ganhoUIBrandLight` (Phase 6-14의 `.ganhoBloodAccent` → 원본 톤 교체).
- [x] **기능 3 — GameScene.layoutHUD 위치 변경** (`GameScene.swift` L276-285):
  - 좌상단 `(-(halfW - hudMarginX), +(halfH - hudMarginY))` → 상단 중앙 `(0, +(halfH - hudTopMargin))`.
  - 단 1 메서드 내부 변경 — `halfW` 변수 제거(미사용), `halfH`만 유지.

## HUDNode 외부 인터페이스 4개 시그니처 보존 (회귀 0)

| 메서드 | 시그니처 | 호출 위치 | 상태 |
|---|---|---|---|
| `update(score:remainingTime:combo:)` | `(Int, TimeInterval, Int) -> Void` | `GameScene.swift:359`, `:542` | 보존 |
| `setCharacterName(_:)` | `(String) -> Void` | `GameScene+Setup.swift:246` | 보존 |
| `startTensionBlink()` | `() -> Void` | `GameScene.swift:311` | 보존 |
| `stopTensionBlink()` | `() -> Void` | `GameScene.swift:537` | 보존 |

외부 호출자 4건 모두 *코드 변경 없이* 그대로 컴파일·동작. 빌드 검증 통과.

## Swift 패턴 준수
- 강제 언래핑 미사용: **준수** (모든 옵셔널 `guard let`/`if let`/`?.` 경유)
- `guard let` 옵셔널 처리: **준수**
- `MARK:` 섹션 구분: **준수** — HUDNode에 `// MARK: - Properties / Init / Update / Character Name / Tension`, HUDSlotNode에 `// MARK: - Properties / Init / Setters / Tension Blink`
- `GameConfig` 상수 사용: **준수** — 매직 넘버 0, 폰트/위치/간격/색 모두 토큰 경유
- `weak self` 캡처: **준수** — `HUDSlotNode.startBlink`의 `SKAction.run` 클로저 2개 모두 `[weak self]`

## SpriteKit 패턴 준수
- `didMove(to:)`에서 초기화: **N/A** (HUDNode는 `init()` / GameScene 호출자 동일)
- `dt` 기반 이동: **N/A**
- `SKAction` 스폰 패턴: **준수** (`Timer` 미사용, `SKAction.sequence` + `repeatForever` + `withKey`)
- 충돌 후 노드 즉시 삭제 없음: **N/A**
- HUD 노드 분리: **준수** — HUDNode는 `cameraNode` 자식으로 화면 고정, 게임 월드와 무관
- 액션 키 멱등성: **준수** — `tensionBlinkActionKey` 재사용으로 SpriteKit 자동 교체

## 회귀 0 영역 확인

- [x] `TitleScene` 미접촉 (`Scenes/TitleScene.swift` diff 0)
- [x] `ResultScene` 미접촉 (`Scenes/ResultScene.swift` diff 0)
- [x] `GameScene+Setup.swift` 미접촉 (호출자만 동일 시그니처로 사용)
- [x] `GameScene.swift`는 `layoutHUD` 한 메서드 *내부*만 변경 (다른 메서드 무수정)
- [x] 컷씬·졸업장·캐릭터·적·노트·F·DPad·카드 노드 미접촉
- [x] PixelSprite/Palette/Renderer / PlayerNode / EnemyNode 미접촉
- [x] Systems/Managers/Repositories/Models/Protocols 미접촉
- [x] PhysicsCategory / GameState 미접촉
- [x] ColorTokens 미접촉 — Phase 8-3 토큰(`.ganhoUIText`, `.ganhoUITextDim`, `.ganhoUIBrandLight`) 재사용만
- [x] iOS·tvOS·macOS 진입점 미접촉
- [x] **신규 파일 0개**, **pbxproj 변경 0건** (HUDSlotNode가 HUDNode.swift 같은 파일 안에 정의)

## 화면 안전성 검증

- `hudSlotSpacing × 4 = 320pt` 가로 폭, 중앙 ±160pt.
- 시뮬레이터 가장 작은 landscape 폭(iPhone 16:9 ~568pt에서도 ±160 = 320pt < 568pt) 안전.
- iPhone 17 Pro Max landscape(956pt) ±160 충분 여유.

## 빌드 상태
- `xcodebuild iPhone 17 (OS 26.5) Debug build` → **BUILD SUCCEEDED**
- 컴파일 에러: **0건**
- 컴파일 경고: **0건** (`grep -iE "warning:|error:"` 결과 비어 있음)
- `appintentsmetadataprocessor`의 `No AppIntents.framework dependency` 안내는 빌드 결과와 무관(앱이 AppIntents 미사용 — 정상).

## 범위 외 미구현 항목

- `GameConfig.hudFontSize`(18), `hudMarginX`(24), `hudMarginY`(24), `hudCharacterNameOffsetX`(760), `hudAlpha`(0.85) — Phase 2-4/5-4 잔재 상수.
  - 현 HUDNode가 직접 사용 안 함. SPEC 주의사항 7 — 본 sprint는 *유지* (안전, 다음 sprint 정리).
- 콤보 `SKAction` bump 애니메이션 — SPEC 금지 §5 (다음 sprint).
- `letter-spacing 2px` — `SKLabelNode` 미지원, `hudLabelLetterSpacing` 상수만 기록(주석으로 명시).
