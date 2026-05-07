# 자체 점검 — Phase 2-12 ScoreSystem 분리

전략: Case A (1회차) — SPEC 본문 그대로 적용. 리팩터 sprint, 기능 변화 0.

## SPEC §"준수 룰" 15개 검증

| # | 룰 | 검증 결과 |
|---|---|---|
| 1 | ScoreSystem.swift 신설 + final class | **PASS** — `Systems/ScoreSystem.swift:12` `final class ScoreSystem` |
| 2 | private(set) score / combo + private lastCollectAt | **PASS** — `ScoreSystem.swift:16,18` `private(set) var`, `:20` `private var lastCollectAt` |
| 3 | recordNoteHit(at:) 메서드 | **PASS** — `ScoreSystem.swift:25` `func recordNoteHit(at now: TimeInterval)` |
| 4 | tickComboExpiry(currentTime:) 메서드 | **PASS** — `ScoreSystem.swift:36` `func tickComboExpiry(currentTime: TimeInterval)` |
| 5 | reset() 메서드 | **PASS** — `ScoreSystem.swift:43` `func reset()` |
| 6 | GameScene에서 score / combo / lastCollectAt 멤버 *제거* | **PASS** — `private var (score|combo|lastCollectAt)` 0건 |
| 7 | GameScene에 `private let scoreSystem = ScoreSystem()` 추가 | **PASS** — `GameScene.swift:43` |
| 8 | update에서 scoreSystem.tickComboExpiry 호출 1건 | **PASS** — `GameScene.swift:261` (정확히 1건) |
| 9 | onNoteCollected 콜백 본문이 *3줄로 단순화* | **PASS** — `GameScene.swift:296~300` `guard let self` + `recordNoteHit(at:)` + `note.run` 3줄 |
| 10 | hud.update 호출 시 scoreSystem.score / scoreSystem.combo 사용 | **PASS** — `GameScene.swift:279` (update), `:313` (endGame) 모두 `scoreSystem.score` 사용 |
| 11 | endGame의 hud.update에 `combo: 0` 인자 *그대로* | **PASS** — `GameScene.swift:313` `combo: 0` 시각 강제 0 유지 |
| 12 | 매직 넘버 0건 | **PASS** — ScoreSystem 내 모든 산식 상수는 GameConfig 참조 (`comboWindow`, `comboBonusThreshold`, `scorePerNote`, `scorePerNoteCombo`). `0`/`1` 리터럴은 SPEC 본문 그대로 이전된 콤보 가드/증가 sentinel — 원본 GameScene 코드와 동일. |
| 13 | 강제 언래핑 / Timer / print / as! / fileprivate / DispatchQueue 0건 | **PASS** — ScoreSystem.swift 0건 검출 |
| 14 | pbxproj ScoreSystem 등록 4지점 | **PASS** — `grep -c "ScoreSystem" project.pbxproj = 4` (PBXBuildFile / PBXFileReference / Systems group children / Sources build phase) |
| 15 | BUILD SUCCEEDED | **PASS** — `xcodebuild ... -destination 'platform=iOS Simulator,name=iPhone 17' build` → `** BUILD SUCCEEDED **` |

## GameScene 줄 수 변화

- **이전 (2-11)**: 324 줄
- **이후 (2-12)**: 315 줄
- **차이**: -9 줄 (멤버 3개 제거 + 콤보 만료 가드 4줄 → 1줄 + onNoteCollected 본문 9줄 → 3줄, 단 멤버/메서드 추가/주석 +수 보정)

## Swift 패턴 준수

- 강제 언래핑 미사용: 준수 (ScoreSystem 0건, GameScene 변경부 0건)
- guard let 옵셔널 처리: 준수 (`onNoteCollected`의 `guard let self`)
- MARK 섹션 구분: 준수 (`// MARK: - State`, `// MARK: - Mutations`)
- GameConfig 상수 사용: 준수 (`.comboWindow`, `.comboBonusThreshold`, `.scorePerNote`, `.scorePerNoteCombo`)
- weak self 캡처: 준수 (`onNoteCollected`의 `[weak self]` 유지)

## SpriteKit 패턴 준수

- didMove(to:)에서 초기화: 준수 (변경 없음)
- dt 기반 이동: 해당 없음 (리팩터 외 영역)
- SKAction 스폰 패턴: 해당 없음
- 충돌 후 노드 즉시 삭제 없음: 준수 (`note.run(.removeFromParent())` 액션 사용 — 기존과 동일)
- HUD 노드 분리: 준수 (변경 없음)

## 회귀 보존 검증

| 영역 | 상태 |
|---|---|
| Config 4 파일 | 변경 0 |
| Nodes 6 파일 | 변경 0 |
| Systems/SpawnSystem.swift / ContactRouter.swift | 변경 0 |
| iOS 3 파일 | 변경 0 |
| GameScene 의 setup* / didChangeSize / endGame (HUD 라인 외) | 변경 0 |
| HUDNode `update(score:remainingTime:combo:)` 시그니처 | 변경 0 |
| 콤보 산식 (`isInWindow ? combo + 1 : 1`) | ScoreSystem.recordNoteHit으로 *그대로 이전* |
| 점수 산식 (`combo >= comboBonusThreshold ? scorePerNoteCombo : scorePerNote`) | ScoreSystem.recordNoteHit으로 *그대로 이전* |

## 빌드 상태

- 빌드 결과: `** BUILD SUCCEEDED **`
- 예상 빌드 에러: 없음
- 주의 필요 경고: 없음 (BUILD SUCCEEDED 라인 직전까지 warning 없음)

## 범위 외 미구현 항목

- 없음 — SPEC IN 항목(신설 1 / 수정 1 / pbxproj 1) 정확히 일치. OUT 항목(다른 파일 변경) 0건.
- `reset()` 메서드는 신설했으나 본 sprint에서 호출 안 함 — SPEC §주의사항 "Phase 3 게임 재시작에서 사용 예정"에 따라 의도된 미사용.
