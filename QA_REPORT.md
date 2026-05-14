# QA 검수 보고서 — Phase 6-12 콤보 끊김 피드백 (시각 + 햅틱)

## SPEC 기능 검증

- [PASS] **기능 1 — ComboBreakNode 신규 (자가 소멸 7호)**: `Nodes/ComboBreakNode.swift:16` `final class ComboBreakNode: SKNode, SelfDismissingNode` 채택 확인. `init(brokenCombo:)` → `animate()` 3단계 사용법(ComboPopupNode와 동형). `SKAction.group([moveDown, fadeOut, scaleDown])` + `sequence + removeFromParent()` 자가 소멸 패턴(line 50~52). self 미사용으로 `[weak self]` 캡처 0건(line 43~53). PhysicsBody 부착 0.
- [PASS] **기능 2 — GameConfig 상수 6개**: `Config/GameConfig.swift:323~337` "Combo Break (Phase 6-12)" MARK 섹션에 `comboBreakThreshold(10)`, `comboBreakFontSize(48)`, `comboBreakFallDistance(60)`, `comboBreakDuration(1.0)`, `comboBreakEndScale(0.7)`, `comboBreakZPosition(140)` 6개 추가. comboPopup 상수 바로 아래 위치 — 대칭 가독성 OK.
- [PASS] **기능 3-1 — Properties 2개**: `GameScene.swift:86~87` `lastComboValue: Int = 0`, `triggeredComboBreaks: Set<Int> = []`. `triggeredComboMilestones`(line 80) 바로 아래 배치.
- [PASS] **기능 3-2 — update() 폴링**: `GameScene.swift:210~218` hud.update 직후, gameOver 가드(line 179) 안쪽. `lastComboValue >= 10 && currentCombo == 0` 검사 후 `triggerComboBreak`. `lastComboValue` 갱신은 **폴링 후**(line 218) — SPEC §"폴링 타이밍 함정" 그대로 준수.
- [PASS] **기능 3-3 — F 피격 분기**: `GameScene.swift:242` `self.checkAndTriggerComboBreak()`가 `self.endGame()`(line 243) 직전에 호출됨. `[weak self]` 캡처 안에서 `guard let self`(line 230) 후 사용 → 안전.
- [PASS] **기능 3-4 — helper 2개**: `GameScene.swift:311~338` MARK "Combo Break Feedback (Phase 6-12)" 신설. `triggerComboBreak(brokenAt:)`(공통 발화 + 멱등 가드 + haptics.heavy + ComboBreakNode 발화) + `checkAndTriggerComboBreak()`(피격 경로 진입점). DRY OK.
- [PASS] **기능 4 — pbxproj UUID 0032 4지점 등록**: `project.pbxproj:43`(PBXBuildFile) / `:80`(PBXFileReference) / `:223`(PBXGroup Nodes) / `:494`(PBXSourcesBuildPhase). 모두 ComboPopupNode(0031) 패턴과 1:1 대칭. UUID 충돌 0건.

## 빌드 검증

- **명령**: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- **결과**: `** BUILD SUCCEEDED **`
- **컴파일 에러**: 없음
- **경고**: 없음
- **비고**: pbxproj 4지점 등록이 완전 — `Cannot find type 'ComboBreakNode' in scope` 에러 없음. iPhone 17 시뮬레이터(iOS 26.4 SDK) 정상 빌드.

## Sprint 회귀 0 보장 영역 22개 미접촉 검증

`git diff HEAD --stat` 결과:
```
GanhoMusic Shared/Config/GameConfig.swift  | +16
GanhoMusic Shared/GameScene.swift          | +50
GanhoMusic.xcodeproj/project.pbxproj       | +4
(Nodes/ComboBreakNode.swift — untracked, 신규 67줄)
```
**수정 3 + 신규 1 = 4파일 외 0건**.

`git diff HEAD` 직접 검증한 22개 영역 (모두 0줄 변경):

| # | 영역 | 결과 |
|---|---|---|
| 1 | ScoreSystem | OK — 시그니처/콜백 변경 0건 (옵션 B 폴링 답습) |
| 2 | ContactRouter | OK — 콜백 등록 위치(GameScene)에서만 1줄 추가, 본체 미접촉 |
| 3 | SpawnSystem | OK |
| 4 | HUDNode | OK — `comboLabel` 미접촉 ("정보 채널 vs 임팩트 채널" 분리 원칙) |
| 5 | BGMPlayer | OK |
| 6 | AudioManager | OK — **SFX enum 케이스 추가 0건** (사운드 제외 정책 준수) |
| 7 | Repositories (HighScore/Statistics/CharacterPreference) | OK |
| 8 | Models (GameStats/CharacterID) | OK |
| 9 | Protocols (SelfDismissingNode) | OK — 채택만 추가, protocol 본체 미접촉 |
| 10 | PlayerNode | OK |
| 11 | EnemyNode | OK |
| 12 | NoteNode | OK |
| 13 | ProjectileNode | OK |
| 14 | StoneGuardNode | OK |
| 15 | DPadNode | OK |
| 16 | AirplaneNode | OK |
| 17 | AirforceOverlayNode | OK |
| 18 | BombFlashNode | OK |
| 19 | HitFlashNode | OK |
| 20 | SparkleEffectNode | OK |
| 21 | CharacterCardNode | OK |
| 22 | **ComboPopupNode** | OK — 6-10 산출물 0줄 변경 |
| 보너스 | TitleScene / ResultScene | OK |
| 보너스 | ColorTokens | OK — `ganhoCrimsonNurse` 재사용, 새 색 추가 0 |
| 보너스 | `triggeredComboMilestones` Set | OK — 의미·위치·리셋 정책 미접촉, 신규 Set는 완전 분리 |
| 보너스 | CameraShakeAction | OK |

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## P0 — 치명적 이슈

**없음.**

- 강제 언래핑(`!`) — `ComboBreakNode.swift` 0건. `GameScene.swift` 추가 라인 0건. `[weak self]` 캡처 후 `guard let self`(line 230)로 안전 unwrap만 사용.
- 물리 충돌 델리게이트 내 노드 즉시 삭제 — 없음. `ComboBreakNode`는 PhysicsBody 0 → 충돌 콜백 미진입. `removeFromParent`는 `SKAction.sequence` 마지막 단계로 *프레임 끝*에 실행.
- 빌드 에러 — 없음 (BUILD SUCCEEDED).
- 클로저 순환 참조 — 없음. `onProjectileHitPlayer` 클로저는 기존 `[weak self]` 캡처 유지(line 229).

## P1 — 중요 이슈

**없음.**

- `Timer` / `DispatchQueue` 사용 — 없음. `SKAction` 기반.
- 매직 넘버 — 없음. 6개 상수 모두 `GameConfig` 경유 (`comboBreakThreshold/FontSize/FallDistance/Duration/EndScale/ZPosition`).
- `guard let` / `if let` 옵셔널 처리 — 신규 코드에 옵셔널 도입 0건 (Set / Int / scoreSystem.combo 모두 비옵셔널).
- `MARK:` 섹션 구분 — `GameConfig`에 `// MARK: - Combo Break (Phase 6-12)`, `GameScene`에 `// MARK: - Combo Break Feedback (Phase 6-12)`, `ComboBreakNode`에 `MARK: - Properties / Init / Animate / Configure` 4섹션.
- 함수 단일 책임 — `triggerComboBreak`(공통 발화 + 멱등 가드), `checkAndTriggerComboBreak`(피격 경로 진입점) 분리. helper 한 함수 = 한 역할.

## P2 — 권장 사항

**없음.**

- 변수명 — `lastComboValue`, `triggeredComboBreaks`, `brokenValue`, `brokenCombo` 모두 의미 명확.
- 주석 품질 — *왜* 위주(폴링 타이밍 함정 / endGame 직전 강제 발화 이유 / 환호와의 의도적 비대칭). Spring 비유 포함(line 15 "4xx 에러 응답").
- 함수/파일 줄 수 — `ComboBreakNode.swift` 67줄, `GameScene.swift` 변경 후도 402줄(여전히 분리 신호 임계 300 초과지만 본 sprint는 *기능 sprint*라 분리는 별도 sprint 영역, P2도 아님).

## 통과 항목

### Swift 패턴
- 강제 언래핑 0건 (신규 + 수정 모두).
- `[weak self]` 캡처 유지 (`onProjectileHitPlayer`), 신규 `ComboBreakNode.animate()`는 self 미사용으로 캡처 불필요.
- 매직 넘버 0건 (상수 6개 GameConfig 경유).
- MARK 섹션 추가 OK.
- 한국어 변수명 0건. 네이밍 일관성 OK.

### SpriteKit 패턴
- `didMove(to:)` 초기화 미접촉 (씬 초기화 변경 없음).
- `dt` 기반 이동 — `SKAction.moveBy + duration` 사용(line 44~46), SKAction이 내부적으로 dt 처리.
- 스폰 패턴 — `update()` 안 `addChild`는 *조건부 1회*(임계값 + Set 가드 통과 시), 매 프레임 X.
- 충돌 후 노드 즉시 삭제 없음 — `removeFromParent`는 sequence 마지막 단계.
- HUD 분리 — `hud.comboLabel` 미접촉. ComboBreakNode는 cameraNode 자식, zPosition 140 (HUD 100 위, ComboPopup 150 아래) — 위계 일관.

### 게임 로직
- `GameState` enum 미접촉 — playing/gameOver 전환 로직 그대로.
- 폴링 타이밍 정확 — `hud.update` 직후, `gameOver` 가드 안쪽.
- `lastComboValue` 갱신 시점 = 폴링 *후*(line 218) → 1프레임 지연 방지.
- F 피격 분기 — endGame 직전(line 242→243) → gameOver 전환 전 마지막 발화 기회 확보.
- 두 호출 경로(update 폴링 / F 피격)가 같은 helper `triggerComboBreak`로 수렴 → DRY + 같은 값 2회 발화 방지(Set.contains 가드).
- 6-11 `triggeredComboMilestones` Set은 *읽지도 쓰지도* 않음 → 환호/실망 가드 완전 분리.

### 멱등성
- `triggeredComboBreaks.contains(brokenValue)` 가드 → 같은 끊김 값 한 판 1회만 발화.
- F 피격 + 폴링이 같은 프레임에 발생할 가능성 0이지만, 만약 발생해도 Set 가드로 중복 차단.
- 새 게임 시작 시 GameScene 인스턴스 새로 생성 → 두 Set 자동 빈 리셋(별도 reset 코드 0).

### Sprint 범위 계약
- SPEC 외 독립 기능 추가 0건.
- ColorTokens 추가 0건 (`.ganhoCrimsonNurse` 재사용).
- AudioManager.SFX 케이스 추가 0건 (사운드 제외 정책 준수).
- HUD 깜빡임 추가 0건 (책임 분리 원칙).
- 22개 회귀 0 영역 + 보너스 4개 모두 0줄 변경 확인.

### ComboPopupNode와의 대칭 설계 검증
| 항목 | ComboPopupNode | ComboBreakNode |
|---|---|---|
| 부모 | cameraNode | cameraNode (동일) ✓ |
| zPosition | 150 | 140 (환호 아래) ✓ |
| 이동 방향 | +y (위로 80) | -y (아래로 60) ✓ |
| Scale | 1.0 → 1.4 (확대) | 1.0 → 0.7 (축소) ✓ |
| Duration | 1.0초 | 1.0초 (동일) ✓ |
| 텍스트 | "x{milestone}" | "x{brokenCombo} BREAK" ✓ |
| 색 | 등급별 4색 | 단일 .ganhoCrimsonNurse ✓ |

SPEC §D4 대칭 표와 완전 일치.

---

## 채점

**항목별 점수**:
- **Swift 패턴 일관성**: 10/10 → 강제 언래핑 0건, 매직 넘버 0건, MARK 4섹션 추가, `[weak self]` 캡처 정확, 한국어 변수명 0건. AI 슬롭 패턴 0건.
- **게임 로직 완성도**: 10/10 → 폴링 타이밍 함정(lastComboValue 갱신을 폴링 *후*에)을 정확히 처리, F 피격 분기를 endGame 직전에 배치(gameOver 전환 후 update 차단 문제 해결), 두 경로가 공통 helper로 수렴 (DRY), 멱등 가드 Set 분리 완전.
- **성능 & 안정성**: 10/10 → 빌드 클린 통과, 크래시 원인 0건, 노드 자가 소멸(SKAction.sequence removeFromParent), PhysicsBody 0건으로 물리 콜백 충돌 가능성 차단, weak self 캡처 유지.
- **기능 완성도**: 10/10 → SPEC 4개 기능 모두 구현 완료(ComboBreakNode + GameConfig 6상수 + GameScene 폴링/helper/F 피격 분기 + pbxproj 4지점). 22개 회귀 0 영역 미접촉 100%, 사운드 제외 정책 + 색 재사용 + HUD 미접촉 정책 100% 준수.

**가중 점수 계산**:
- (10 × 0.35) + (10 × 0.30) + (10 × 0.20) + (10 × 0.15) = 3.5 + 3.0 + 2.0 + 1.5 = **10.0 / 10.0**

**관대 검증** (8.0+ 자기 점검):
- 강제 언래핑 1건이라도? → 검색 0건 확인.
- 매직 넘버 1건이라도? → 6개 상수 모두 GameConfig 경유 확인.
- 회귀 영역 1줄이라도 변경? → `git diff HEAD` 4파일 외 0건 확인.
- SPEC 외 변경 1건? → ComboBreakNode 신규 / GameConfig 6상수 / GameScene 폴링·helper·F분기 / pbxproj 4지점 — 모두 SPEC 명시 항목.
- 폴링 1프레임 지연 가능성? → `lastComboValue` 갱신이 폴링 *후*인 line 218에서 검증.
- F 피격 시 endGame 후 폴링 못 잡는 함정? → `checkAndTriggerComboBreak`(line 242)가 `endGame`(line 243) *전*에 실행되어 함정 회피.
- 두 Set의 상호 영향? → 코드 위치 분리(환호: line 265~266 / 실망: line 318~319), 한 줄도 겹치지 않음.

엄격 재검토 결과 감점 사유 발견 0건. 점수 유지.

## 최종 판정: **합격**

**가중 점수**: **10.0 / 10.0**

**구체적 개선 지시**: 없음. 본 sprint 산출물은 SPEC 100% 구현 + 회귀 0 + 빌드 클린 + Swift/SpriteKit 패턴 100% 준수. 

**다음 sprint 여지 (P2 미만 — 본 sprint 합격 무관)**:
1. `GameScene.swift` 402줄 — 분리 임계 300 초과. 6-10/6-11/6-12 피드백 로직(`playComboMilestoneFeedback`, `triggerComboBreak`, `checkAndTriggerComboBreak`)을 `ComboFeedbackSystem.swift`로 추출하는 별도 리팩터 sprint 검토 가능. 본 sprint는 *기능* sprint라 영역 외.
2. 콤보 끊김 사운드 추가 — SPEC D3 "다음 sprint 여지" 명시. enum case 1 + helper 1줄로 OCP 확장 가능.
3. ComboPopupNode와 ComboBreakNode 두 노드의 공통 골격(SKLabelNode + cameraNode 부모 + animate()) 추출 검토 — 단 2회차 재사용으로 *Rule of Three* 임계 1회 부족, 자가 소멸 8호 노드가 같은 패턴이면 그 시점 추출이 자연.
