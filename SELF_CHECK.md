# 자체 점검 — Phase 6-9 (F 피격 카메라 셰이크 + 빨간 플래시)

## 1. SPEC 기능 5개 구현 확인

| # | 기능 | 구현 위치 | 상태 |
|---|---|---|---|
| 1 | GameConfig 상수 7개 추가 (`// MARK: - Hit Feedback (Phase 6-9)`) | `Config/GameConfig.swift` 끝 | OK — `cameraShakeAmplitude`/`cameraShakeStepCount`/`cameraShakeStepDuration`/`hitFlashPeakAlpha`/`hitFlashFadeInDuration`/`hitFlashFadeOutDuration`/`hitFlashZPosition` 7개 정확히 추가 |
| 2 | CameraShakeAction (enum 네임스페이스 + static func make()) | `Systems/CameraShakeAction.swift` 신설 | OK — case 없는 enum, `static func make() -> SKAction` 1개. amp/dur/count GameConfig 경유 |
| 3 | HitFlashNode (SKSpriteNode + SelfDismissingNode, 자가 소멸 5호) | `Nodes/HitFlashNode.swift` 신설 | OK — `final class HitFlashNode: SKSpriteNode, SelfDismissingNode`. `flash(sceneSize:)` 메서드 fadeIn→fadeOut→removeFromParent |
| 4 | GameScene `onProjectileHitPlayer` 콜백 5줄로 확장 + 헤더 주석 1줄 | `GameScene.swift` | OK — `guard let self` + 셰이크/flash/endGame 순서 고정. 헤더 `Phase 6-9 · 피격 카메라 셰이크 + 빨간 플래시 (시각 폴리싱)` 1줄 추가 |
| 5 | pbxproj 8지점 등록 (2파일 × 4지점) | `GanhoMusic.xcodeproj/project.pbxproj` | OK — PBXBuildFile 2, PBXFileReference 2, Group children 2 (Nodes+Systems), Sources phase 2 = 총 8지점 |

## 2. 빌드 결과

- **BUILD SUCCEEDED** (확인됨)
- 경고: **0개** — `xcodebuild ... 2>&1 | grep -iE "warning:|error:"` 출력 비어 있음 (Metadata extraction skipped는 빌드 시스템 노이즈로 무관)
- 새 파일 2개 모두 Sources phase에 등록 확인

## 3. 회귀 0줄 강제 항목 (git status 검증)

```
modified:   GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift     ← SPEC 허용
modified:   GanhoMusic/GanhoMusic Shared/GameScene.swift             ← SPEC 허용
modified:   GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj          ← SPEC 허용
새 파일:    GanhoMusic/GanhoMusic Shared/Nodes/HitFlashNode.swift    ← SPEC 허용
새 파일:    GanhoMusic/GanhoMusic Shared/Systems/CameraShakeAction.swift  ← SPEC 허용
```

**미접촉 (회귀 0줄 확인)**:
- `Managers/AudioManager.swift`, `Managers/HapticsManager.swift`, `Managers/BGMPlayer.swift` — 0줄
- `Systems/ScoreSystem.swift`, `Systems/ContactRouter.swift`, `Systems/SpawnSystem.swift` — 0줄 (ContactRouter 시그니처 변경 0)
- `Scenes/TitleScene.swift`, `Scenes/ResultScene.swift` — 0줄
- `Repositories/HighScoreRepository.swift`, `Repositories/StatisticsRepository.swift`, `Repositories/CharacterPreferenceRepository.swift` — 0줄
- `Models/GameStats.swift`, `Models/CharacterID.swift` — 0줄
- `Protocols/SelfDismissingNode.swift` — 0줄 (marker protocol 그대로 채택)
- `Config/ColorTokens.swift`, `Config/PhysicsCategory.swift`, `Config/GameState.swift` — 0줄
- 기존 Nodes (NoteNode/PlayerNode/EnemyNode/ProjectileNode/HUDNode/CharacterCardNode/AirplaneNode/BombFlashNode/AirforceOverlayNode/SparkleEffectNode/StoneGuardNode/DPadNode) — 0줄

`git diff --stat`: GameConfig +20, GameScene +12/-1 — 최소 변경.

## 4. 특별 검증

| 항목 | 결과 |
|---|---|
| 강제 언래핑 `!` 0건 | OK — `guard let self = self else { return }` 적용. fatalError(coder)는 SpriteKit 관용 패턴(BombFlashNode 답습) |
| `Timer` 0건, SKAction만 사용 | OK — CameraShakeAction은 `SKAction.sequence([moveBy ...])`만, HitFlashNode는 `SKAction.sequence([fadeIn, fadeOut, removeFromParent])`만 |
| 매직 넘버 0건 (모든 수치 GameConfig 경유) | OK — amp/dur/count/peakAlpha/fadeIn/fadeOut/zPosition 7개 모두 GameConfig.swift 상수 |
| HitFlashNode가 SelfDismissingNode 채택 | OK — `final class HitFlashNode: SKSpriteNode, SelfDismissingNode` — 자가 소멸 5호 |
| CameraShakeAction이 enum 네임스페이스 + static func make() | OK — `enum CameraShakeAction { static func make() -> SKAction { ... } }`. case 0개로 인스턴스화 차단 |
| 트리거 순서 고정 (셰이크 → flash 부착/발화 → endGame) | OK — 정확히: `cameraNode.run(shake)` → `cameraNode.addChild(flash)` → `flash.flash(sceneSize:)` → `endGame()` 순서 |
| 새 ColorTokens 추가 0 (`ganhoBloodAccent` 재사용) | OK — ColorTokens.swift 0줄 변경. HitFlashNode init이 `.ganhoBloodAccent` 재사용 |
| 새 효과음/햅틱/PhysicsCategory 0 | OK — AudioManager/HapticsManager/PhysicsCategory 미접촉 |
| `update()` 안 `addChild` 0건 | OK — flash 부착은 콜백 안 (`onProjectileHitPlayer` 클로저), update 미접촉 |
| `[weak self]` 캡처 유지 | OK — 콜백 `{ [weak self] in guard let self = self else { return } ... }` 패턴 정확히 유지 |

## 5. 검증 시나리오 정적 추적

### (a) 빌드
- `xcodebuild ... build` → BUILD SUCCEEDED, 경고 0
- 새 파일 2개 Sources phase 등록 확인 (`A1C0F1B00000000000000029`, `A1C0F1B00000000000000030`)

### (b) F 피격 시 5채널 동시 발화 정적 추적
콜백 진입 시점:
1. `cameraNode.run(CameraShakeAction.make())` → 카메라 셰이크 (6-9 시각 운동감)
2. `HitFlashNode()` + `addChild(flash)` + `flash.flash(sceneSize:)` → 빨간 플래시 (6-9 시각)
3. `self.endGame()` → 내부에서:
   - `haptics.heavy()` (6-1, 진동)
   - `audio.play(.gameOver)` (6-2, 효과음)
   - `bgm.stop()` (6-4, BGM 정지)
   - `spawnSystem.stop()`, velocity=.zero 정리
   - `presentScene(resultScene, transition: .fade(0.4))` 전환

→ 5채널(진동+효과음+BGM정지+셰이크+플래시) 모두 멱등 가드 안쪽에서 1회만 발화. SPEC §1.5 학습 가치 충족.

### (c) 카메라 원위치 정확 (count=6 수동 검산 표 — 6.항 참조)
- 누적 변위 0 → 셰이크 후 cameraNode.position.x == 시작 x ±0.01pt

### (d) 메모리 누수 0
- HitFlashNode `removeFromParent` 자가 호출 (sequence 마지막 단계)
- CameraShakeAction은 SKAction 반환만 — 노드 0, 누수 0
- `[weak self]` 캡처로 GameScene 참조 사이클 없음
- ResultScene 전환 시 GameScene → cameraNode → flash 자식 ARC 자동 해제

### (e) ResultScene 전환 안전
- 셰이크(0.04 × 7 = 0.28초) + 플래시(0.05 + 0.25 = 0.30초) 모두 ResultScene fade(0.4초) 안에 종료
- presentScene 호출은 endGame 마지막 줄 — 시각 효과는 *부모(cameraNode)와 함께 해제* 또는 자가 제거. 크래시 위험 0

### (f) 시간 만료 endGame — 시각 효과 미발화
- 시간 만료는 GameScene `update()` 안 `endGame()` 직접 호출 (line 169 부근)
- onProjectileHitPlayer 콜백 우회 → 셰이크/플래시 발화 0
- *피격 전용* 피드백 책임 분리 보존

### (g) enemy 직접 접촉 endGame — 시각 효과 미발화
- `contactRouter.onEnemyHit = { [weak self] in self?.endGame() }` 그대로 (변경 0줄)
- 셰이크/플래시 발화 0 — F 투사체 피격과 디자인 분리

### (h) 회귀 0줄 (위 §3에서 git status로 검증 완료)

### (i) Phase 1~6 회귀
- 이동/수집/점수/HUD/적/F/게임오버/ResultScene/캐릭터선택/AIRFORCE/사운드/햅틱/BGM/Interruption/Lifecycle/sparkle 모두 미접촉
- BombFlashNode (Phase 4-5)와 HitFlashNode 별개 클래스 — AIRFORCE 폭탄은 그대로 누런 톤
- SparkleEffectNode (Phase 6-8)와 HitFlashNode 별개 — 음표 수집 sparkle은 worldNode, HitFlash는 cameraNode

## 6. count=6 누적 변위 0 수동 검산

`cameraShakeStepCount = 6` 기준 CameraShakeAction.make() 시퀀스:

| step (i) | dx 부호 식 | dx | 누적 변위 |
|---|---|---|---|
| 0 (첫 이동) | +amp | +8 | +8 |
| 1 | i=1 홀수 → -2amp | -16 | -8 |
| 2 | i=2 짝수 → +2amp | +16 | +8 |
| 3 | i=3 홀수 → -2amp | -16 | -8 |
| 4 | i=4 짝수 → +2amp | +16 | +8 |
| 5 | i=5 홀수 → -2amp | -16 | **-8** |
| 복귀 | count=6 짝수 → +amp | +8 | **0** ✓ |

총 스텝 수: 7 (count + 1). 총 시간: 7 × 0.04 = 0.28초.

코드:
```swift
steps.append(SKAction.moveBy(x: +amp, y: 0, duration: dur))                                  // step 0
for i in 1..<count {                                                                          // i=1..5
    let dx: CGFloat = (i % 2 == 0) ? +2 * amp : -2 * amp                                      // 짝수=+2amp, 홀수=-2amp
    steps.append(SKAction.moveBy(x: dx, y: 0, duration: dur))
}
let returnDx: CGFloat = (count % 2 == 0) ? +amp : -amp                                        // 6 짝수 → +amp
steps.append(SKAction.moveBy(x: returnDx, y: 0, duration: dur))
```

**검산 통과** — 누적 변위 0, 시작점 정확 복귀.

추가 검증 (count=5 홀수 case, 향후 튜닝 대비):
- step 0: +8 (+8)
- i=1: -16 (-8)
- i=2: +16 (+8)
- i=3: -16 (-8)
- i=4: +16 (+8)
- 복귀: count=5 홀수 → -amp = -8 (0) ✓

홀수 case도 누적 변위 0 보장 — 일반화 식 정확.

## 7. 범위 외 미구현 항목

없음. SPEC "Sprint 범위 계약 — 금지" 항목 모두 미접촉:
- BombFlashNode 변경 0
- 새 효과음/햅틱 0
- endGame 호출 순서/로직 변경 0
- 새 PhysicsCategory 0
- 새 ColorTokens 0
- BGMPlayer/AudioManager/HapticsManager 변경 0
- ResultScene/ScoreSystem/EnemyNode/ProjectileNode 변경 0
- update 안 새 로직 0
