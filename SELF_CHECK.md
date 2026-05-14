# 자체 점검 — Phase 6-11 (콤보 마일스톤 햅틱/사운드 추가, 3감각 완성)

## SPEC 기능 체크

- [x] **기능 1: AudioManager.SFX 케이스 2개 추가** — `comboMilestoneSoft` (Tink 1057), `comboMilestoneStrong` (NewMail 1025) 신규. `fileName` switch는 둘 다 `nil` 반환 → systemSoundID 폴백 경로 자연 사용. `init`의 `allCases` 배열도 4개로 확장.
- [x] **기능 2: HapticsManager.medium() 추가** — `mediumGenerator` 프로퍼티 1개 + `init` 워밍 1줄 + `medium()` 메서드 1개. light/heavy와 100% 동형(`impactOccurred` 후 `prepare()`).
- [x] **기능 3: GameScene helper `playComboMilestoneFeedback(for:)`** — GameScene private 메서드로 추가 (옵션 A 채택). switch 4-way: 3/5 → light+Soft, 10 → medium+Soft, 20 → heavy+Strong, default → light+Soft (graceful fallback, 미래 마일스톤 안전망). `// MARK: - Combo Milestone Feedback (Phase 6-11)` 섹션 신설, `// MARK: - Easter Egg` 직전 위치.
- [x] **기능 4: GameScene 콜백 가드 안쪽 통합** — `configureContactRouter().onNoteCollected` 클로저 내 마일스톤 가드 안쪽에 `self.playComboMilestoneFeedback(for: currentCombo)` 1줄 prepend. 6-10의 시각 코드(ComboPopupNode 생성/addChild/animate) 3줄은 위치/순서 그대로 유지 — 호출 순서: 촉각→청각→시각.
- [x] **헤더 주석**: GameScene.swift 상단에 `//  Phase 6-11 · 콤보 마일스톤 도달 시 햅틱/사운드 동시 발화 (3감각 완성)` 한 줄 추가.

## 수정한 파일 (3개) + 각 변경 라인 수

| 파일 | +라인 | -라인 | 비고 |
|---|---|---|---|
| `GanhoMusic Shared/GameScene.swift` | 34 | 0 | 헤더 주석 1줄 + 가드 안쪽 helper 호출(+주석) 5줄 + helper 메서드 28줄 |
| `GanhoMusic Shared/Managers/AudioManager.swift` | 15 | 7 | 헤더 주석 1줄 + SFX 케이스 2개 + fileName/systemSoundID 매핑 4지점 + `allCases` 배열 1지점 |
| `GanhoMusic Shared/Managers/HapticsManager.swift` | 14 | 2 | 헤더 주석 1줄 + 헤더 doc-comment 1줄 + `mediumGenerator` 프로퍼티 1개 + init 2줄 + `medium()` 메서드 7줄 |

**GameConfig.swift 미변경** — SPEC §"기능 3"에서 결정 옵션 A(helper를 GameScene 내부)를 채택했으므로 GameConfig는 0건 수정. SPEC §"수정할 파일" 목록에 GameConfig가 있었지만 본문 §"기능 3" 결정의 결과로 자연 미수정 — SPEC 본문 결정과 일관.

## Sprint 회귀 0 보장 영역 — 20개 영역 미접촉 확인

`git diff --name-only`로 변경된 파일 목록을 직접 검사한 결과:

| # | 영역 | 미접촉 확인 |
|---|---|---|
| 1 | `ScoreSystem` | OK — `Systems/` 변경 0건 |
| 2 | `ContactRouter` | OK — `Systems/` 변경 0건 |
| 3 | `SpawnSystem` | OK — `Systems/` 변경 0건 |
| 4 | `CameraShakeAction` | OK — `Systems/` 변경 0건 |
| 5 | `HUDNode` | OK — `Nodes/` 변경 0건 |
| 6 | `BGMPlayer` | OK — `Managers/BGMPlayer.swift` 변경 0건 |
| 7 | `HighScoreRepository` | OK — `Repositories/` 변경 0건 |
| 8 | `StatisticsRepository` | OK — `Repositories/` 변경 0건 |
| 9 | `CharacterPreferenceRepository` | OK — `Repositories/` 변경 0건 |
| 10 | `Models` (GameStats, CharacterID) | OK — `Models/` 변경 0건 |
| 11 | `Protocols` (SelfDismissingNode) | OK — `Protocols/` 변경 0건 |
| 12 | `PlayerNode` / `EnemyNode` / `NoteNode` / `ProjectileNode` / `StoneGuardNode` / `DPadNode` / `AirplaneNode` / `AirforceOverlayNode` / `BombFlashNode` / `HitFlashNode` / `SparkleEffectNode` / `CharacterCardNode` | OK — `Nodes/` 변경 0건 |
| 13 | `ComboPopupNode` (시각 코드 — 라벨/애니메이션/색상) | OK — `Nodes/ComboPopupNode.swift` 변경 0건 |
| 14 | `TitleScene` | OK — `Scenes/` 변경 0건 |
| 15 | `ResultScene` | OK — `Scenes/` 변경 0건 |
| 16 | `ColorTokens` | OK — `Config/` 변경 0건 |
| 17 | `GameConfig` (특히 `comboMilestones` 배열) | OK — `Config/` 변경 0건 |
| 18 | `PhysicsCategory` / `GameState` | OK — `Config/` 변경 0건 |
| 19 | `GameScene+Setup.swift` (setup/add 9개 메서드) | OK — 변경 0건 |
| 20 | `project.pbxproj` (새 파일 0건이라 등록 변경 없음) | OK — `*.pbxproj` 변경 0건 |

검증 명령:
```
git diff --name-only -- 'GanhoMusic/GanhoMusic Shared/Systems/' \
                        'GanhoMusic/GanhoMusic Shared/Repositories/' \
                        'GanhoMusic/GanhoMusic Shared/Models/' \
                        'GanhoMusic/GanhoMusic Shared/Protocols/' \
                        'GanhoMusic/GanhoMusic Shared/Nodes/' \
                        'GanhoMusic/GanhoMusic Shared/Scenes/' \
                        'GanhoMusic/GanhoMusic Shared/Config/' \
                        'GanhoMusic/GanhoMusic Shared/Managers/BGMPlayer.swift'
→ 출력 0줄 (빈 결과)

git diff --name-only -- '*.pbxproj'
→ 출력 0줄 (빈 결과)
```

## `triggeredComboMilestones` Set 미변경 확인

GameScene.swift 내 grep 결과 — 4지점 모두 6-10 패턴 그대로:
- Line 79 — 선언: `private var triggeredComboMilestones: Set<Int> = []`
- Line 244 — 가드 조건: `!self.triggeredComboMilestones.contains(currentCombo)`
- Line 245 — 가드 통과 시 insert: `self.triggeredComboMilestones.insert(currentCombo)`
- Line 248 — 신규 추가된 주석에서 변수명 언급 (멱등성 신뢰 설명)

**Set의 위치/의미/리셋 정책 변경 0건.** `endGame()`이나 `didMove(to:)`에 `removeAll()` 추가 없음 — 6-10의 "자동 리셋의 우아함"(GameScene 인스턴스 라이프사이클 신뢰) 정책 유지.

## `default` 절 미포함 확인 (AudioManager의 두 switch)

`grep -n "default:" "Managers/AudioManager.swift"` → 출력 0줄.
- `SFX.fileName` switch: 4 케이스 exhaustive. default 없음.
- `SFX.systemSoundID` switch: 4 케이스 exhaustive. default 없음.

새 SFX 케이스 추가 시 컴파일러가 매핑 강제 — 6-2의 "매직 넘버 정책의 미묘함" 정책 유지.

(참고: GameScene의 `playComboMilestoneFeedback(for:)` switch에는 `default` 포함 — Int 타입이라 exhaustive 불가능하고, SPEC §"기능 3"에서 graceful fallback 안전망으로 의도적 포함이 명시됨. 6-10 `ComboPopupNode.color(for:)`와 동일 정책.)

## Swift 패턴 준수

- 강제 언래핑 미사용: 준수 (`!` 신규 도입 0건)
- guard let 옵셔널 처리: 준수 (`onProjectileHitPlayer` / `onNoteCollected` 등 기존 `guard let self` 그대로 유지)
- MARK 섹션 구분: 준수 (`// MARK: - Combo Milestone Feedback (Phase 6-11)` 신설)
- GameConfig 상수 사용: N/A — 본 sprint는 GameConfig 미수정. 시스템 사운드 ID(1025)는 SPEC §"주의사항"에 따라 Apple 도메인 상수라 AudioManager.SFX enum 내부에 유지(6-2 정책 일관).
- weak self 캡처: 준수 — 기존 `[weak self]` 클로저 시그니처 변경 0건. `playComboMilestoneFeedback` 호출은 `self.` 명시(이미 weak self가 unwrap된 클로저 안).
- 네이밍 (lowerCamelCase): 준수 — `comboMilestoneSoft` / `comboMilestoneStrong` / `mediumGenerator` / `medium()` / `playComboMilestoneFeedback`
- 한국어 변수명 미사용 / 주석은 한국어 허용: 준수
- 함수 작은 단위 분리: 준수 — helper `playComboMilestoneFeedback` 28줄 단일 책임(마일스톤→피드백 분기)

## SpriteKit 패턴 준수

- `didMove(to:)`에서 초기화: 준수 (변경 0건)
- dt 기반 이동: N/A (이번 sprint 이동 로직 미접촉)
- SKAction 스폰 패턴: N/A (스폰 미접촉)
- 충돌 후 노드 즉시 삭제 없음: 준수 — 기존 `note.run(.removeFromParent())` 패턴(SKAction 경유) 그대로 유지. helper는 부수효과(haptic/audio)만 호출, SKNode 추가/삭제 0건.
- HUD 노드 분리: 준수 (HUDNode 변경 0건)
- 새 SKAction / SKNode 노드 생성 0건: 준수 (SPEC §"금지" 항목 — 사운드/햅틱은 매니저 호출만)

## 빌드 상태

명령:
```
cd "GanhoMusic" && xcodebuild -project GanhoMusic.xcodeproj \
  -scheme "GanhoMusic iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug build
```

결과: **BUILD SUCCEEDED**
- 예상 빌드 에러: **없음** — `** BUILD SUCCEEDED **` 확인.
- 주의 필요 경고: **없음** — `grep -E "(warning:|error:)"` → 컴파일 경고 0건 (`note: Building targets...` 두 줄만 출력, 이건 빌드 정보 메시지).

(주: 기본 `iPhone 15` 시뮬레이터는 환경에 없어 `iPhone 17`로 대체 — 시뮬레이터 명만 다를 뿐 iOS 16+ 빌드 검증은 동일.)

## 호출 순서 검증 (촉각 → 청각 → 시각)

`playComboMilestoneFeedback(for:)` 내부 — 각 case에서:
```
haptics.{light|medium|heavy}()   // 1단계 촉각
audio.play(.combo*)               // 2단계 청각
```
가드 안쪽 호출 순서 — `onNoteCollected` 클로저:
```
self.playComboMilestoneFeedback(for: currentCombo)  // 1+2단계 (촉각/청각)
let popup = ComboPopupNode(milestone: currentCombo)
self.cameraNode.addChild(popup)
popup.animate()                                       // 3단계 시각
```
인간 지각 시간축(촉각 0~10ms → 청각 ~30ms → 시각 60ms+)과 코드 라인 순서 일치. 6-2 학습 노트 §"코드 순서: 햅틱 → 사운드" 정책 답습.

## 범위 외 미구현 항목

- **없음.** SPEC §"Sprint 범위 계약"의 "허용" 6개 항목 중 5개를 구현(허용 1번 — `GameConfig` 하단 상수 추가 — 은 §"기능 3" 결정에 따라 helper를 GameScene에 두며 미사용). "금지" 항목 모두 준수.
- 헤더 주석에 BGMPlayer 관련 Phase 6-5/6-6/6-7 라인은 처음부터 GameScene 헤더에 없었으므로 6-10 라인 바로 뒤에 6-11을 자연 추가.
- `print()` 디버그 코드 도입 0건.

## 필수 연동 변경

- **없음.** 4개 영역(헤더 주석, 가드 안쪽 prepend, helper 메서드, 매니저 API 확장)은 모두 SPEC §"기능 1~4"의 직접 항목. SPEC 범위 외 변경 0건.
