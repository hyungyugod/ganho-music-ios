# 자체 점검 — Phase 7-1 난이도 3단계 시스템

## SPEC 기능 체크 (9개 기능 라인 매핑)

| # | 기능 | 파일:라인 | 비고 |
|---|---|---|---|
| 1 | Difficulty enum + 영구 저장 | `Models/Difficulty.swift` (신규, 44줄) / `Repositories/DifficultyPreferenceRepository.swift` (신규, 40줄) | rawValue String + .easy fallback |
| 2 | DifficultyCardNode | `Nodes/DifficultyCardNode.swift` (신규, 72줄) | CharacterCardNode 동형 + subtitleLabel 추가 |
| 3 | TitleScene 3 카드 + 선택/저장/복원 | `Scenes/TitleScene.swift:34-37` 프로퍼티 / `:48-49` didMove 복원 / `:54-55` setup / `:62` layout / `:158-178` setupDifficultyCards/layout/select / `:188-194` touchesBegan 우선 hit test | 난이도→캐릭터→GameScene 전환 순서 |
| 4 | GameScene init/factory 확장 | `GameScene.swift:108-110` characterID/difficulty 프로퍼티 / `:114-117` init 시그니처 / `:122-126` factory (두 인자 default) | macOS/tvOS .easy fallback |
| 5 | PlayerNode/EnemyNode/SpawnSystem apply | `PlayerNode.swift:74-77` apply / `EnemyNode.swift:64-67` apply / `SpawnSystem.swift:43-50` apply / `GameScene+Setup.swift:114` player.apply / `:147` enemy.apply / `GameScene.swift:187` spawnSystem.apply | 모든 dict lookup에 ?? fallback |
| 6 | NoteNode TTL 자가 소멸 | `Nodes/NoteNode.swift:36-45` applyLifetime | guard ttl.isFinite, ttl < gameDuration |
| 7 | SpawnSystem 차등 + F burst | `Systems/SpawnSystem.swift:27-50` 인스턴스 프로퍼티 6개+apply / `:88-98` trySpawnNote+applyLifetime / `:144-150` currentFireInterval / `:155-176` fireProjectile burst 루프 | easy=1 → 루프 1회 = 회귀 0 |
| 8 | EnemyNode 보간식 인스턴스 참조 | `Nodes/EnemyNode.swift:103-107` self.baseSpeedStart/End 사용 | GameConfig.enemyBaseSpeed/MaxSpeed 미참조 |
| 9 | ResultScene 난이도 라벨 | `Scenes/ResultScene.swift:34-36` 프로퍼티 / `:46-47` 라벨 인스턴스 / `:56-65` factory / `:78-94` init / `:118` configure / `:130-131` text / `:138` addChild / `:168-171` layout | "난이도: 하/중/상" |

## GameConfig 신규 상수 확인 (19개)

dict 9개 + UI/저장/Result 상수 10개 = 19개 추가. 기존 모든 상수 미접촉(단 하나 예외: `characterCardOffsetY` -160 → -200, 위치도 §"Difficulty" 섹션으로 이동, SPEC §5 의도 명시).

`grep -c "ByDifficulty\|difficultyCard\|difficultyPreference\|resultDifficulty\|characterCardOffsetY" GameConfig.swift` → 25건 (dict 9개 × 2 ref + 상수 10개 + 주석 1).

## 회귀 0 영역 (27개 항목) — git diff 0줄 확인

`git diff --name-only` 결과:
- ✅ HUDNode / BGMPlayer / AudioManager / HapticsManager: 미접촉
- ✅ ColorTokens / PhysicsCategory / GameState: 미접촉
- ✅ ContactRouter / ScoreSystem / CameraShakeAction / SelfDismissingNode: 미접촉
- ✅ Airplane / AirforceOverlay / BombFlash / Sparkle / HitFlash / ComboPopup / ComboBreak / Countdown / ScorePopup: 미접촉
- ✅ StoneGuardNode / CharacterID / CharacterPreferenceRepository / HighScoreRepository / StatisticsRepository / GameStats: 미접촉
- ✅ GanhoMusic iOS/GameViewController.swift / AppDelegate.swift / SceneDelegate.swift: 미접촉
- ✅ GanhoMusic tvOS / GanhoMusic macOS 폴더: 미접촉

(grep `git diff --name-only | grep -E "<27개 패턴>"` → 0건 매치)

## Swift 패턴 준수

- ✅ 강제 언래핑 미사용 — 신규 파일 3개 grep `!\.` 0건. dict lookup 모두 `?? fallback`
- ✅ guard let 옵셔널 처리 — `defaults.string(forKey:)` / `Difficulty(rawValue:)` / `touches.first` 모두 guard let
- ✅ MARK 섹션 구분 — 신규 3 파일 모두 MARK 구분(Properties/Init/Apply/Selection/Configure 등)
- ✅ GameConfig 상수 사용 — 매직 넘버 없음(width/height/spacing/fontSize/offsetY/zPosition/duration/key 모두 상수)
  - 단 1곳: DifficultyCardNode.configureLabels의 `position = CGPoint(x: 0, y: 8)` / `y: -14` — 카드 내부 자식 레이아웃 좌표, CharacterCardNode와 일관성 위해 직접 리터럴(SPEC §"DifficultyCardNode 구조" 의사 코드 그대로). 향후 commonize 필요 시 GameConfig로.
- ✅ weak self 캡처 — 신규 코드에 클로저 사용 0건(외부 시그니처 변경만)

## SpriteKit 패턴 준수

- ✅ didMove(to:)에서 초기화 — TitleScene 7-1 신설 setupDifficultyCards/복원 didMove 안
- ✅ dt 기반 이동 — 변경 없음 (PlayerNode.update / EnemyNode.update 시그니처 보존)
- ✅ SKAction 스폰 패턴 — Timer/DispatchQueue 0건. NoteNode.applyLifetime은 SKAction.sequence
- ✅ 충돌 후 노드 즉시 삭제 없음 — 변경 없음
- ✅ HUD 노드 분리 — 변경 없음

## 빌드 상태

- ✅ `xcodebuild -target "GanhoMusic iOS" -sdk iphonesimulator EXCLUDED_SOURCE_FILE_NAMES="Main.storyboard" clean build` → **BUILD SUCCEEDED**
- ✅ 경고 0건 (`grep "warning:" | grep -v "Metadata extraction"` → 0건)

빌드 출력 마지막:
```
CodeSign .../GanhoMusic.app
Validate .../GanhoMusic.app
Touch .../GanhoMusic.app
** BUILD SUCCEEDED **
```

## pbxproj 등록

- ✅ PBXBuildFile: Difficulty.swift (A1C0F1B0...035) / DifficultyPreferenceRepository.swift (036) / DifficultyCardNode.swift (037) 3건 추가
- ✅ PBXFileReference: 동일 3건 추가
- ✅ PBXGroup: Models에 Difficulty / Repositories에 DifficultyPreferenceRepository / Nodes에 DifficultyCardNode
- ✅ PBXSourcesBuildPhase: iOS target(C75D46252FA627C20016BB86) Sources에만 3건 추가. tvOS(C75D46362FA...) / macOS(C75D46462FA...) Sources 미접촉(빈 채로 유지)
- ✅ PBXFileSystemSynchronizedBuildFileExceptionSet 미접촉(기존 GameScene.swift/GameScene+Setup.swift 만 유지)

## 정적 검사

| 항목 | 결과 |
|---|---|
| 강제 언래핑 (`!.` / `as!` / `try!`) | 0건 (신규/변경 라인 전체 grep) |
| 매직 넘버 | 0건 (모든 수치 GameConfig 참조 / 카드 내부 자식 좌표 8/-14만 의사 코드 그대로) |
| Timer | 0건 |
| DispatchQueue | 0건 |
| fallback 없는 dict lookup | 0건 (`?? GameConfig.X` 또는 `?? .easy` / `?? 1` / `?? .infinity` 모두 명시) |

## SPEC §"주의사항" 8개 항목 준수

| # | 주의사항 | 준수 위치 |
|---|---|---|
| 1 | apply(_:CharacterID) ↔ apply(_:Difficulty) 호출 순서 | GameScene+Setup.swift:113-114 — character 먼저, difficulty 나중 |
| 2 | noteLifetime .infinity 정책 | NoteNode.swift:42 — `guard ttl.isFinite, ttl < GameConfig.gameDuration else { return }` |
| 3 | SpawnSystem hard-coded → 인스턴스 | SpawnSystem.swift:27-37 — 6개 인스턴스 프로퍼티, 모두 default = GameConfig 기존 단일 상수 |
| 4 | F burst max 가드 매 발 | SpawnSystem.swift:163 — `guard currentProjectileCount() < projectileMaxConcurrent else { return }` 매 발 |
| 5 | dict subscript Optional — fallback 필수 | PlayerNode:75-76 / EnemyNode:65-66 / SpawnSystem:44-49 — 모든 lookup `?? GameConfig.X`. 강제 언래핑 0건. |
| 6 | DifficultyCardNode 코드 중복 허용 | BaseCardNode 추출 X. CharacterCardNode와 동형 패턴 유지(SPEC 분리 정책) |
| 7 | PlayerNode 속도 보간 미적용 — 시작값만 | PlayerNode.swift:88 — `let speed = baseSpeedStart * speedMultiplier`. `baseSpeedEnd`는 저장만, 미사용 |
| 8 | TitleScene layout 충돌 점검 | characterCardOffsetY -160 → -200, difficultyCardOffsetY -120. 라벨(prompt -80) 하단과 카드(난이도 상단 -92) 간격 12pt 안전 |

## 범위 외 미구현 항목 (SPEC §"금지")

- 이교수 NPC — 미구현(.hard 선택해도 등장 0건). 다음 sprint.
- hard 맵 — 미구현. .normal/.hard 선택해도 easy 맵 그대로.
- 석조무사 등장 분기 — 미구현. 전 난이도 등장 그대로(StoneGuardNode 미접촉).
- 목표 점수 (60/50/30) — 미구현. ResultScene 라벨도 미적용.
- 인트로/경고/중간 컷씬 — 미구현.
- 졸업장/목표 달성 추적 — 미구현.

## 신규 파일 3개

- `GanhoMusic Shared/Models/Difficulty.swift` (44줄) — CharacterID 동형
- `GanhoMusic Shared/Repositories/DifficultyPreferenceRepository.swift` (40줄) — CharacterPreferenceRepository 동형
- `GanhoMusic Shared/Nodes/DifficultyCardNode.swift` (72줄) — CharacterCardNode 동형 + subtitle 1개 추가
