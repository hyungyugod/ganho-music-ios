# 자체 점검 — Phase 7-4 졸업장 시스템

전략: 1회차 — SPEC.md 충실 구현.

## git status / git diff --stat

```
On branch claude/confident-mendeleev-5df868
Changes not staged for commit:
	modified:   GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift
	modified:   GanhoMusic/GanhoMusic Shared/GameScene.swift
	modified:   GanhoMusic/GanhoMusic Shared/Scenes/ResultScene.swift
	modified:   GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj

Untracked files:
	GanhoMusic/GanhoMusic Shared/Nodes/DiplomaOverlayNode.swift
	GanhoMusic/GanhoMusic Shared/Repositories/GraduationRepository.swift
	GanhoMusic/GanhoMusic Shared/Repositories/PerDifficultyScoreRepository.swift
```

```
GanhoMusic Shared/Config/GameConfig.swift      |  57 +++ (Diploma 섹션 22 상수 + MARK)
GanhoMusic Shared/GameScene.swift              |  38 +- (prop 2개 + endGame 5줄 + isGraduated 헬퍼)
GanhoMusic Shared/Scenes/ResultScene.swift     |  47 +- (prop 2 + factory/init 2인자 + setup 3줄 + presentDiploma)
GanhoMusic.xcodeproj/project.pbxproj           |  12 +  (BuildFile×3 + FileRef×3 + 그룹 children×3 + Sources iOS×3)
```

신규 파일 line counts:
- PerDifficultyScoreRepository.swift — 86 lines
- GraduationRepository.swift — 85 lines
- DiplomaOverlayNode.swift — 211 lines

## SPEC §"기능 상세" 라인 매핑

### 기능 1: GameConfig 신규 상수 22개
- `GanhoMusic Shared/Config/GameConfig.swift:568-625` — `// MARK: - Diploma (Phase 7-4)` 섹션
- 상수 22개: targetScoreByDifficulty / perDifficultyScoreUserDefaultsKey / graduationUserDefaultsKey / diplomaBackgroundAlpha / diplomaZPosition / diplomaFadeInDuration / diplomaFadeOutDuration / diplomaTitleEnFontSize / diplomaTitleKoFontSize / diplomaBodyFontSize / diplomaIssuerFontSize / diplomaDateFontSize / diplomaTapFontSize / diplomaTitleEnOffsetY / diplomaTitleKoOffsetY / diplomaBody1OffsetY / diplomaBody2OffsetY / diplomaIssuerOffsetY / diplomaDateOffsetY / diplomaTapLabelAlpha / diplomaTapOffsetY / diplomaBodyWidthRatio
- 기존 상수 미접촉 (cutsceneTapLabelAlpha 567 라인 뒤에 append)

### 기능 2: PerDifficultyScoreRepository
- `GanhoMusic Shared/Repositories/PerDifficultyScoreRepository.swift` — 신규 86줄
- `current: [CharacterID: [Difficulty: Int]]` — guard let × 2 + try? + for/guard 2중 변환
- `best(characterID:difficulty:) -> Int` — `?? 0` 폴백
- `record(characterID:difficulty:score:) -> Bool` — `score > prior` 엄격 비교, try? + false 반환

### 기능 3: GraduationRepository
- `GanhoMusic Shared/Repositories/GraduationRepository.swift` — 신규 85줄
- ISO8601DateFormatter 인스턴스 멤버 캐싱
- `current: [CharacterID: Date]` — guard let × 2 + for/guard
- `graduatedAt(characterID:) -> Date?`
- `record(characterID:date:) -> Bool` — **멱등**: `if dict[id] != nil { return false }`

### 기능 4: GameScene.isGraduated 헬퍼
- `GanhoMusic Shared/GameScene.swift:574-586` — `// MARK: - Graduation (Phase 7-4)` 섹션
- private static func — 인스턴스 미접근
- `Difficulty.allCases` 순회 + 미달 시 즉시 false return + 폴백 `?? Int.max`

### 기능 5: DiplomaOverlayNode (자가 소멸 11호)
- `GanhoMusic Shared/Nodes/DiplomaOverlayNode.swift` — 신규 211줄
- `final class DiplomaOverlayNode: SKNode, SelfDismissingNode` (마커 채택)
- private init + 정적 팩토리 `present(...)` 1개
- 7 라벨: titleEnLabel / titleKoLabel / body1Label / body2Label / issuerLabel / dateLabel / tapLabel
- 색상: 배경 `.ganhoYellowF` 0.92 alpha + 글자 `.black` — ColorTokens 신규 0건
- touchesBegan → dismiss + fadeOut + removeFromParent + notify callback
- 다중 탭 차단: `isUserInteractionEnabled = false` + `onDismiss = nil` 2중 안전망
- onDismiss `[weak self]` 캡처는 *외부 책임* (CutsceneOverlayNode 답습 — notify는 self 미사용)

### 기능 6: GameScene.endGame() 확장
- `GanhoMusic Shared/GameScene.swift:533-553` — 매트릭스 record + 졸업 판정 + ResultScene factory 인자 2개 추가
- prop 2개: `GameScene.swift:72-73` — `perDiffRepo` / `graduationRepo`
- 신규 5줄(SPEC 그대로): perDiffRepo.record / var isNewGraduation / if isGraduated → graduationRepo.record / let graduatedAt
- ResultScene.newResultScene 인자 2개 추가: isNewGraduation / graduatedAt

### 기능 7: ResultScene 변경
- prop 2개: `Scenes/ResultScene.swift:39-43` — `isNewGraduation: Bool` / `graduatedAt: Date?`
- factory: `ResultScene.swift:62-85` — `isNewGraduation: Bool = false, graduatedAt: Date? = nil` default 인자
- init: `ResultScene.swift:91-116` — 9개 인자, self 저장
- setupLabels 끝: `ResultScene.swift:159-162` — `if isNewGraduation, let graduatedAt = graduatedAt { presentDiploma(at:) }`
- `presentDiploma(at:)`: `ResultScene.swift:289-298` — DiplomaOverlayNode.present(parent: self, anchor: midX/midY, onDismiss: {})

### 기능 8: pbxproj 등록
- PBXBuildFile (3): `project.pbxproj:50-52` — A1C0F1B...039/040/041
- PBXFileReference (3): `project.pbxproj:93-95` — A1C0F1A...039/040/041
- PBXGroup Nodes children: `project.pbxproj:240` — DiplomaOverlayNode 1줄 추가
- PBXGroup Repositories children: `project.pbxproj:275-276` — PerDifficulty/Graduation 2줄 추가
- PBXSourcesBuildPhase iOS (3): `project.pbxproj:519-521` — 3 파일 라인 추가
- tvOS/macOS Sources: 빈 채 유지 (회귀 0)

## 회귀 0 영역 grep 결과

모두 `git diff <file> | wc -l` = **0줄**:

```
Repositories:
  HighScoreRepository.swift                 — 0줄
  StatisticsRepository.swift                — 0줄
  CharacterPreferenceRepository.swift       — 0줄
  DifficultyPreferenceRepository.swift      — 0줄

자가 소멸 노드 10개 (1~10호, 11호 외):
  AirplaneNode.swift                        — 0줄
  AirforceOverlayNode.swift                 — 0줄
  BombFlashNode.swift                       — 0줄
  SparkleEffectNode.swift                   — 0줄
  HitFlashNode.swift                        — 0줄
  ComboPopupNode.swift                      — 0줄
  ComboBreakNode.swift                      — 0줄
  CountdownNode.swift                       — 0줄
  ScorePopupNode.swift                      — 0줄
  CutsceneOverlayNode.swift                 — 0줄

기타 노드:
  HUDNode.swift / PlayerNode.swift / EnemyNode.swift / StoneGuardNode.swift /
  NoteNode.swift / ProjectileNode.swift / DPadNode.swift /
  CharacterCardNode.swift / DifficultyCardNode.swift — 모두 0줄

시스템:
  ContactRouter.swift / ScoreSystem.swift / SpawnSystem.swift / CameraShakeAction.swift — 모두 0줄

매니저:
  BGMPlayer.swift / AudioManager.swift / HapticsManager.swift — 모두 0줄

Config / Model / Protocol:
  ColorTokens.swift / PhysicsCategory.swift / GameState.swift — 모두 0줄
  CharacterID.swift / Difficulty.swift / GameStats.swift — 모두 0줄
  SelfDismissingNode.swift — 0줄

기타:
  TitleScene.swift — 0줄
  GameScene+Setup.swift — 0줄
  iOS·tvOS·macOS 플랫폼 진입점 — 0줄 (pbxproj tvOS/macOS Sources 빈 채 유지)
```

## 빌드 결과 (마지막 20줄 발췌)

```
CodeSign /Users/hg/.../GanhoMusic.app (in target 'GanhoMusic iOS' from project 'GanhoMusic')
    /usr/bin/codesign --force --sign - --timestamp=none --generate-entitlement-der ...

RegisterExecutionPolicyException ...
    builtin-RegisterExecutionPolicyException ...

Validate ...
    builtin-validationUtility ... -validate-for-store -shallow-bundle -infoplist-subpath Info.plist

Touch ...
    /usr/bin/touch -c .../GanhoMusic.app

** BUILD SUCCEEDED **
```

명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -target "GanhoMusic iOS" -sdk iphonesimulator EXCLUDED_SOURCE_FILE_NAMES="Main.storyboard" clean build`

- **BUILD SUCCEEDED**
- **경고 0건** (`grep -iE 'warning:|error:' <build_log> | grep -v 'Metadata extraction skipped'` → 빈 출력)
- AppIntents의 `Metadata extraction skipped`는 정보성 메시지 (warning 아님, 본 프로젝트 비관련)

## 정적 검사

신규 3 파일 (PerDifficultyScoreRepository / GraduationRepository / DiplomaOverlayNode) + 수정 부분(diff):

| 검사 항목 | 결과 |
|---|---|
| 강제 언래핑 `!.` | **0건** (grep none) |
| `try!` | **0건** |
| `as!` | **0건** |
| `Timer(` | **0건** |
| `DispatchQueue` | **0건** |
| 매직 넘버 (DiplomaOverlayNode 1.0 알파 캐스팅 등 GameConfig 외) | **0건** |
| `[weak self]` 누락 (notify 클로저는 self 미사용 → 불필요, CutsceneOverlayNode 답습) | 준수 |

## SPEC §"주의사항" 12개 준수 여부

1. **ISO8601 Date**: `ISO8601DateFormatter` + `.withInternetDateTime` — 준수
2. **UserDefaults JSON 패턴**: StatisticsRepository 답습, `try?` graceful — 준수
3. **enum → rawValue 직렬화**: `[String: [String: Int]]` 중간 변환, 강제 언래핑 0 — 준수
4. **신규 vs 기존 졸업**: `record` false 반환 = 이미 졸업 → 매번 미표시 — 준수 (GraduationRepository.swift `if dict[id] != nil { return false }`)
5. **dismiss 후 ResultScene 그대로**: `onDismiss: {}` 빈 클로저 — 준수 (ResultScene.presentDiploma)
6. **점수 두 군데 저장**: UserDefaults atomic, 트랜잭션 분리 가능 — 준수 (HighScoreRepository + PerDifficultyScoreRepository 병행)
7. **Date 영속화**: `record` 멱등으로 *최초 일시 영원 동일* — 준수
8. **factory default 인자**: `isNewGraduation: Bool = false, graduatedAt: Date? = nil` — 준수
9. **parent = scene 자체**: cameraNode 없음, anchor = `(frame.midX, frame.midY)` — 준수 (ResultScene.presentDiploma)
10. **diplomaTapFontSize 별도**: 14 (cutsceneTapFontSize 16과 다른 값) — 준수
11. **SelfDismissingNode marker**: `final class DiplomaOverlayNode: SKNode, SelfDismissingNode` 채택 — 준수
12. **GraduationRepository encode 실패 graceful**: `guard let data = try? JSONEncoder().encode(raw) else { return false }` — 준수

## SPEC 기능 체크

- [x] 기능 1 (GameConfig 22 상수): MARK 섹션 + 22개 정확 추가, 기존 미접촉
- [x] 기능 2 (PerDifficultyScoreRepository): 86줄 신규, 의사 코드 그대로, 강제 언래핑 0
- [x] 기능 3 (GraduationRepository): 85줄 신규, ISO8601 직렬화, record 멱등
- [x] 기능 4 (isGraduated 헬퍼): GameScene private static, Difficulty.allCases 순회
- [x] 기능 5 (DiplomaOverlayNode): 211줄 신규, SelfDismissingNode 채택, 7라벨, private init + 정적 팩토리, ColorTokens 신규 0건
- [x] 기능 6 (GameScene.endGame 확장): prop 2 + 신규 5줄 + factory 인자 2개
- [x] 기능 7 (ResultScene 변경): prop 2 + factory default 2 + init 2 + setup 3줄 + presentDiploma
- [x] 기능 8 (pbxproj 등록): BuildFile 3 + FileRef 3 + 그룹 children 3 + Sources iOS 3, tvOS/macOS 빈 채

## Swift 패턴 준수

- 강제 언래핑 미사용: **준수** (grep `!.` 0건 신규 3 파일)
- guard let 옵셔널 처리: **준수** (current 메서드 모두 guard let × 2)
- MARK 섹션 구분: **준수** (Properties / Init / Read / Write / Configure 등)
- GameConfig 상수 사용: **준수** (DiplomaOverlayNode 모든 수치 GameConfig.diploma* 참조)
- weak self 캡처: **준수** (DiplomaOverlayNode notify 클로저는 self 미사용 → 불필요, CutsceneOverlayNode 답습 정책)

## SpriteKit 패턴 준수

- 정적 팩토리 + private init: **준수** (DiplomaOverlayNode CutsceneOverlayNode 10호 답습)
- 자가 소멸 SKAction.sequence(fadeOut + removeFromParent + notify): **준수**
- SKAction 기반 (Timer 미사용): **준수**
- HUD/cameraNode 좌표계 — DiplomaOverlayNode는 parent = ResultScene 자체 + anchor 명시: **준수**
- SelfDismissingNode 마커 채택 (자가 소멸 11호): **준수**

## 빌드 상태

- **빌드 에러**: 없음 (BUILD SUCCEEDED)
- **경고**: 0건
- AppIntents Metadata extraction skipped는 시스템 정보 메시지 (warning 아님)

## 범위 외 미구현 항목 (SPEC §"금지" 모두 준수)

- "졸업장 다시 보기" 버튼 — 미구현 (SPEC 금지, 다음 sprint)
- 졸업장 이미지 저장(UIImageWriteToSavedPhotosAlbum) — 미구현 (SPEC 금지)
- TitleScene 캐릭터 카드 졸업 뱃지 — 미구현 (SPEC 금지)
- 5×3 매트릭스 시각화 — 미구현 (SPEC 금지)
- HighScoreRepository 제거/마이그레이션 — 미실시 (SPEC 금지, 병행 유지)
- 캐릭터 픽셀 아바타를 졸업장에 그리기 — 미구현 (SPEC 금지, 텍스트 라벨만)

## 필수 연동 변경 (SPEC 외 최소)

없음 — SPEC.md "기능 1~8"의 변경 범위만 정확히 적용.

## 회귀 0 자연 차단 메커니즘 검증

1. **HighScoreRepository 병행 유지** — diff 0줄
2. **ResultScene factory default 인자** — `isNewGraduation: Bool = false, graduatedAt: Date? = nil` 명시
3. **DiplomaOverlayNode 자가 소멸** — SKAction.sequence에 removeFromParent 포함
4. **GraduationRepository.record 멱등** — `if dict[id] != nil { return false }` 첫 줄 가드
5. **graduatedAt nil 가드** — `if isNewGraduation, let graduatedAt = graduatedAt`
6. **신규 UserDefaults 키** — `perDifficultyScores` / `graduations` (기존 키 충돌 0)
7. **DiplomaOverlayNode zPosition 300** — newBestZPosition(150) 위 자연 겹침
