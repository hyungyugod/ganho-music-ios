# 자체 점검 — Phase 6-12 콤보 끊김 피드백 (시각 + 햅틱)

## SPEC 기능 체크

- [x] **기능 1 — ComboBreakNode 신규 (자가 소멸 7호)**: `Nodes/ComboBreakNode.swift` 새 파일 67줄. `SKNode + SelfDismissingNode` 채택, `SKLabelNode` 자식 1개, `init(brokenCombo: Int)` → `animate()` 3단계 사용법, `group(moveBy(-y) + fadeOut + scale(0.7))` + `removeFromParent()` 자가 소멸. `ganhoCrimsonNurse` 색 재사용(ColorTokens 추가 0).
- [x] **기능 2 — GameConfig 상수 6개 추가**: `Combo Break (Phase 6-12)` MARK 섹션 신설. `comboBreakThreshold(10)`, `comboBreakFontSize(48)`, `comboBreakFallDistance(60)`, `comboBreakDuration(1.0)`, `comboBreakEndScale(0.7)`, `comboBreakZPosition(140)`. ComboPopup 상수 바로 아래 위치 — 대칭 가독성.
- [x] **기능 3-1 — Properties 2개 추가**: `lastComboValue: Int = 0` + `triggeredComboBreaks: Set<Int> = []` — `triggeredComboMilestones` 바로 아래 배치(6-11 가드와 시각적 인접, 의미적 분리).
- [x] **기능 3-2 — update() 폴링 5줄 추가**: `hud.update(...)` 직후 6번 step. `lastComboValue >= 10 && currentCombo == 0` 검사 후 `triggerComboBreak(brokenAt:)` 호출 + `lastComboValue` 갱신. SPEC §"폴링 타이밍 함정" 준수.
- [x] **기능 3-3 — onProjectileHitPlayer 1줄 추가**: `flash.flash(...)` 다음, `self.endGame()` *직전* `self.checkAndTriggerComboBreak()` 1줄. SPEC D6 그대로 따름.
- [x] **기능 3-4 — helper 2개 신설**: `Combo Break Feedback (Phase 6-12)` MARK 섹션. `triggerComboBreak(brokenAt:)` (멱등 가드 + haptics.heavy + ComboBreakNode 발화) + `checkAndTriggerComboBreak()` (피격 경로 진입점). 두 경로 모두 `triggerComboBreak`로 수렴 — DRY.
- [x] **기능 3-5 — 헤더 주석 1줄 추가**: `Phase 6-12 · 콤보 10+ 끊김 시 화면 중앙 BREAK 팝업 + heavy 햅틱 (실망 2감각, 사운드 제외)`.
- [x] **기능 4 — pbxproj 4지점 등록 (UUID 0032)**: ComboPopupNode(0031) 패턴 그대로 답습. PBXBuildFile(line 43) / PBXFileReference(line 80) / PBXGroup `Nodes` (line 223) / PBXSourcesBuildPhase (line 494) 모두 등록.

## 파일별 변경 라인 수

| 파일 | 변경 | 라인 수 |
|---|---|---|
| `Nodes/ComboBreakNode.swift` | **신규** | 67줄 (헤더 6 + import 1 + 클래스 60) |
| `Config/GameConfig.swift` | 수정 | +16줄 (MARK 1 + 상수 6 + 주석 9) |
| `GameScene.swift` | 수정 | +50줄 (헤더 1 + Properties 6 + update 8 + onProjectileHitPlayer 2 + helper 섹션 33) |
| `GanhoMusic.xcodeproj/project.pbxproj` | 수정 | +4줄 (4지점 각 1줄) |

## Swift 패턴 준수

- **강제 언래핑 미사용**: 준수. `!` 0건. `cameraNode`, `scoreSystem`은 let 비옵셔널이라 unwrap 불필요. `self.view` 부분은 기존 `endGame()`이 이미 `guard let view`로 처리(미접촉).
- **guard let 옵셔널 처리**: 준수. 신규 코드에 옵셔널 도입 없음 — Set/Int/scoreSystem.combo 모두 비옵셔널.
- **MARK 섹션 구분**: 준수. `GameConfig`에 `// MARK: - Combo Break (Phase 6-12)` 신설. `GameScene`에 `// MARK: - Combo Break Feedback (Phase 6-12)` 신설 (Combo Milestone Feedback 아래, Easter Egg 위).
- **GameConfig 상수 사용**: 준수. 매직 넘버 0건 — `comboBreakThreshold/FontSize/FallDistance/Duration/EndScale/ZPosition` 6개 전부 GameConfig 경유.
- **weak self 캡처**: 준수. 기존 `onProjectileHitPlayer = { [weak self] in ... }` 캡처 유지 — `self.checkAndTriggerComboBreak()` 호출도 같은 캡처 안에서 사용. `ComboBreakNode.animate()`는 self 미사용 → 캡처 불필요(SPEC §"Swift 패턴" 명시).

## SpriteKit 패턴 준수

- **didMove(to:)에서 초기화**: N/A (씬 초기화 변경 없음).
- **dt 기반 이동**: 준수. `ComboBreakNode.animate()`는 `SKAction.moveBy + duration` 사용 (SKAction 내부 dt 자동 처리).
- **SKAction 스폰 패턴**: 준수. `update()`에서 `addChild`는 *조건부 1회* (콤보 10+→0 임계만), 매 프레임 X. `triggerComboBreak`도 Set.contains 가드로 한 판 1회 보장.
- **충돌 후 노드 즉시 삭제 없음**: 준수. ComboBreakNode는 PhysicsBody 부착 0 — 충돌 콜백 미진입. `removeFromParent()`는 `SKAction.sequence` 마지막 단계로 *프레임 끝*에 실행.
- **HUD 노드 분리**: 준수. `hud.comboLabel` 미접촉. ComboBreakNode는 `cameraNode` 자식 (HUD `cameraNode` 자식과 다른 인스턴스). zPosition 140 — HUD(100) 위, ComboPopup(150) 아래.

## 빌드 상태

- **빌드 명령**: `xcodebuild -project GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination "platform=iOS Simulator,name=iPhone 17" -configuration Debug build`
- **결과**: **BUILD SUCCEEDED**
- **예상 빌드 에러**: 없음
- **주의 필요 경고**: 없음

## pbxproj 4지점 UUID 0032 등록 확인

```
43:  A1C0F1B00000000000000032 /* ComboBreakNode.swift in Sources */ = ... // PBXBuildFile
80:  A1C0F1A00000000000000032 /* ComboBreakNode.swift */ = ...            // PBXFileReference
223:        A1C0F1A00000000000000032 /* ComboBreakNode.swift */,          // PBXGroup (Nodes)
494:        A1C0F1B00000000000000032 /* ComboBreakNode.swift in Sources */, // PBXSourcesBuildPhase
```
ComboPopupNode(0031) 4지점과 1:1 대응. UUID 충돌 0건.

## Sprint 회귀 0 보장 영역 22개 미접촉 확인

git diff로 검증 — 신규 1 + 수정 3 (Config / GameScene / pbxproj) 외에 **단 한 줄도 변경 없음**:

| 영역 | 미접촉 |
|---|---|
| 1. ScoreSystem | OK — 시그니처/콜백 변경 0건 (옵션 B 폴링 정책 답습) |
| 2. ContactRouter | OK — 콜백 등록 위치(GameScene)에서만 1줄 추가, ContactRouter 본체 미접촉 |
| 3. SpawnSystem | OK |
| 4. HUDNode | OK — `comboLabel` 미접촉 ("정보 채널 vs 임팩트 채널" 분리 원칙) |
| 5. BGMPlayer | OK |
| 6. AudioManager | OK — **SFX enum 케이스 추가 0건** (사운드 제외 정책 준수) |
| 7. Repositories (HighScore/Statistics/CharacterPreference) | OK |
| 8. Models (Score/GameStats/CharacterID 등) | OK |
| 9. Protocols (SelfDismissingNode) | OK — 채택만 추가, protocol 본체 미접촉 |
| 10. PlayerNode | OK |
| 11. EnemyNode | OK |
| 12. NoteNode | OK |
| 13. ProjectileNode | OK |
| 14. StoneGuardNode | OK |
| 15. DPadNode | OK |
| 16. AirplaneNode | OK |
| 17. AirforceOverlayNode | OK |
| 18. BombFlashNode | OK |
| 19. HitFlashNode | OK |
| 20. SparkleEffectNode | OK |
| 21. CharacterCardNode | OK |
| 22. **ComboPopupNode** | OK — 6-10 산출물 0줄 변경 (대칭 신설만) |
| (보너스) TitleScene / ResultScene | OK |
| (보너스) ColorTokens | OK — `ganhoCrimsonNurse` 재사용, 새 색 추가 0 |
| (보너스) `triggeredComboMilestones` Set | OK — 의미/위치/리셋 정책 미접촉, 신규 Set는 *완전 분리* |
| (보너스) CameraShakeAction | OK |

## 멱등 가드 분리 확인 (6-11 vs 6-12)

```swift
// 6-11 (환호 가드, Properties)
private var triggeredComboMilestones: Set<Int> = []

// 6-12 (실망 가드, Properties — 신규)
private var lastComboValue: Int = 0
private var triggeredComboBreaks: Set<Int> = []
```

- 두 Set는 *물리적*으로 다른 메모리, *의미적*으로 독립 이벤트(환호/실망).
- 코드 위치: 환호 가드는 `onNoteCollected` 클로저 안 / 실망 가드는 `update()` 끝 + `onProjectileHitPlayer` 안.
- 한 줄도 겹치지 않음. 상호 영향 0.

## HUD comboLabel 미접촉 확인

`HUDNode.swift` 변경 0건. `hud.update(score:remainingTime:combo:)` 시그니처 변경 0건. 끊김 시각은 *별도 임팩트 노드* (ComboBreakNode)로 분리 — "정보 채널 vs 임팩트 채널" 책임 분리 원칙(6-10 학습 노트) 답습.

## AudioManager.SFX 케이스 추가 0건 확인

`Managers/AudioManager.swift` 변경 0건. `audio.play(.comboMilestoneSoft/.comboMilestoneStrong)` 호출은 6-11 기존 코드 — 본 sprint에서 미접촉. 끊김 사운드는 *의도적 제외* (SPEC D3 — 환호와의 비대칭, 다음 sprint 여지).

## 전략적 방향 판단

1회차 — Case 판정 미적용.

## 범위 외 미구현 항목

없음. SPEC 항목 100% 구현. SPEC 외 변경 0건.
