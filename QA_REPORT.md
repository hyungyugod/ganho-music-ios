# QA 검수 보고서 — Phase 5-6 selectedCharacterID 영구 저장

## SPEC 기능 검증

| 기능 | 결과 | 비고 |
|---|---|---|
| `CharacterPreferenceRepository` 신규 (3번째 Repository) | PASS | HighScoreRepository(40줄)/StatisticsRepository(44줄)와 동형(41줄). `init(defaults:key:)` DI · `var current: CharacterID` · `func save(_:)` 시그니처 정확 |
| `GameConfig.characterPreferenceUserDefaultsKey` 상수 | PASS | line 248, `"selectedCharacterID"`. 호출부 리터럴 노출 0 |
| TitleScene 프로퍼티 `preferenceRepo` (line 31) | PASS | `private let` 1회 생성, 씬 생명주기 보장 |
| `didMove`에 setupCharacterCards 직전 복원 (line 45→46) | PASS | 첫 프레임에 정확한 카드가 selected scale/alpha로 표시되는 순서 |
| `select(_:)` 안 save (line 149→150→151) | PASS | `selectedCharacterID = id` 직후, for 루프 직전 — 단일 트랜잭션 단위 |
| pbxproj 4 엔트리 등록 | PASS | 라인 28(PBXBuildFile) / 57(PBXFileReference) / 235(Repositories children) / 446(Sources phase). ID `A1C0F1A0...0024` / `A1C0F1B0...0024` 충돌 0 |

## 빌드 검증

- 결과: `** BUILD SUCCEEDED **`
- iOS Simulator generic destination, Debug 구성
- swift compile error 0, warning 0
- `Cannot find 'CharacterPreferenceRepository' in scope` 미발생 — pbxproj 4곳 등록 효과

## pbxproj 4 엔트리 정밀 검증

```
28:  A1C0F1B00000000000000024 /* CharacterPreferenceRepository.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1C0F1A00000000000000024 ... };
57:  A1C0F1A00000000000000024 /* CharacterPreferenceRepository.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CharacterPreferenceRepository.swift; sourceTree = "<group>"; };
235: A1C0F1A00000000000000024 /* CharacterPreferenceRepository.swift */,   (Repositories PBXGroup children)
446: A1C0F1B00000000000000024 /* CharacterPreferenceRepository.swift in Sources */,   (Sources build phase)
```
- 정확히 4개 라인 ✓
- FileRef prefix `A1C0F1A0...` / BuildFile prefix `A1C0F1B0...` 기존 컨벤션 준수
- ID 충돌 0 (grep `A1C0F1[AB]00000000000000(23|24|25)` → 0024만 등장)

## 회귀 검증 (Out of Scope 0줄)

5-6 sprint에서 0줄 변경 확인:

| 파일 | 5-6 sprint 변경 | 비고 |
|---|---|---|
| `Models/CharacterID.swift` | 0줄 | enum String raw value 자동 사용 |
| `GameScene.swift` / `GameScene+Setup.swift` | 0줄 | |
| `Nodes/PlayerNode.swift` / `HUDNode.swift` | 0줄 | |
| `Nodes/CharacterCardNode.swift` | 5-5 누적분 12줄만, 5-6 추가 0줄 | 평가 제외 대상 |
| `Config/ColorTokens.swift` | 0줄 | |
| `Repositories/HighScoreRepository.swift` | 0줄 | |
| `Repositories/StatisticsRepository.swift` | 0줄 | |
| `Scenes/ResultScene.swift` | 0줄 | |
| `Systems/*` (ContactRouter/SpawnSystem/ScoreSystem) | 0줄 | |
| `Protocols/*` | 0줄 | |
| `Models/GameStats.swift` | 0줄 | |

TitleScene 내부 회귀 회피:
- `bestLabel`/`playsLabel`/`promptLabel` 출력 경로 변경 0 ✓
- `startPromptBlink` SKAction 변경 0 ✓
- `touchesBegan` 본체 (line 159-176) — 카드 hit-test 분기·GameScene 전환 분기 모두 5-1 그대로, 5-6에서 0줄 ✓
- 카드 setup/layout (line 120-145) 변경 0 ✓
- `isTransitioning` 더블 탭 방지 (line 170) 변경 0 ✓
- `selectedCharacterID: CharacterID = .kim` 기본값 (line 27) 유지 — 안전망 ✓

## 검증 시나리오 (a)~(g) 정적 추적

### (a) 5 캐릭터 각각 저장/복원
- `select(.jung)` → `selectedCharacterID = .jung` → `preferenceRepo.save(.jung)` → `defaults.set("jung", forKey: ...)`
- 재실행 시 `didMove` → `preferenceRepo.current` → `defaults.string` = `"jung"` → `CharacterID(rawValue:"jung")` = `.jung`
- 5 case 모두 동일 String rawValue 경로 ✓

### (b) 첫 실행 (UserDefaults 키 없음) — graceful
- `defaults.string(forKey: ...)` → `nil`
- `guard let raw = ...` 분기 실패 → `return .kim`
- 프로퍼티 기본값과 일치 — 이중 안전망 ✓

### (c) 잘못된 raw value graceful degradation
- `defaults.set("ganho", forKey: ...)` 후 → `defaults.string` = `"ganho"` non-nil
- `CharacterID(rawValue:"ganho")` = `nil` → `?? .kim` 폴백 → `.kim` 반환
- 크래시 0, fatalError 0, 강제 언래핑 0 ✓

### (d) GameScene 진입 시 복원된 선택 사용
- 재실행 시 `selectedCharacterID = .jung` 복원 → 빈 곳 탭 → `GameScene.newGameScene(characterID: .jung)` → 5-2/5-3 색·속도 정상 ✓

### (e) 빌드 클린
- BUILD SUCCEEDED, error 0, warning 0 ✓

### (f) TitleScene 다른 라벨 회귀 없음
- bestLabel / playsLabel / promptLabel / 카드 layout / isTransitioning 변경 0 ✓

### (g) 단일 진입점 검증 — 핵심
- 카드 영역 탭: `select(card.id)` → `preferenceRepo.save` 1회 → `return` → GameScene 전환 안 함 ✓
- 카드 외 영역 탭: 모두 miss → `GameScene.newGameScene(...)` 호출. **`select(_:)` 미호출** → save 미호출 → 디스크 I/O 0 ✓
- grep `preferenceRepo` → save는 line 150 한 곳뿐 ✓

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0 |
| P1 중요 | 0 |
| P2 권장 | 0 |

## 통과 항목

- Repository 패턴 정합 (3번째 등장, HighScore/Statistics와 100% 동형)
- MARK 4섹션 (Properties / Init / Read / Write)
- 강제 언래핑 0 (`guard let raw` 패턴)
- 매직 넘버 0 (GameConfig 상수 경유)
- graceful degradation 2단계 (`guard let` + `?? .kim`)
- DI 가능 init (`defaults`/`key` 기본값)
- 단일 진입점 (`select(_:)` 1곳에서만 save)
- 순서 정합 (setupLabels → 복원 → setupCharacterCards)
- Out of Scope 위반 0 (13 카테고리)
- Timer/DispatchQueue 0
- 빌드 클린 (error/warning 0)
- pbxproj 4곳 정확 등록 (ID 충돌 0)

## 채점

| 항목 | 점수 | 코멘트 |
|---|---|---|
| Swift 패턴 일관성 (35%) | **10/10** | Repository 3번째 동형, MARK 4섹션, guard let, DI init, 매직 넘버 0 — 빈틈 없음 |
| 게임 로직 완성도 (30%) | **10/10** | 복원 위치/저장 위치 모두 SPEC 명세대로. 단일 진입점 보장 |
| 성능 & 안정성 (20%) | **10/10** | 빌드 클린, fallback 2단계, 디스크 I/O는 사용자 카드 탭 시 1회만 |
| 기능 완성도 (15%) | **10/10** | In Scope 4 항목 100% 충족, Out of Scope 0건 위반, pbxproj 4곳 정확 |

**가중 점수 = 10.0 / 10.0**

## 최종 판정: **합격 (10.0 / 10.0)**

본 sprint는 5-6 목표(영구 저장)를 SPEC의 *지정 위치*에서 *지정 패턴*으로 정확히 구현했다. Repository 패턴 3번째 등장이 명세대로 동형 구조를 유지하고, 단일 진입점·이중 graceful fallback·pbxproj 4곳 등록·빌드 클린이 모두 달성되었다. 추가 개선 지시 없음.
