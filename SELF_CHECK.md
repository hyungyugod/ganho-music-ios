# 자체 점검 — Phase 5-6 selectedCharacterID 영구 저장

## 1. 변경 파일 목록

### 신규 파일 (1개)
- `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/affectionate-elion-d0363a/GanhoMusic/GanhoMusic Shared/Repositories/CharacterPreferenceRepository.swift` — 3번째 Repository (HighScore/Statistics와 동형)

### 수정 파일 (3개)
- `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/affectionate-elion-d0363a/GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift` — `characterPreferenceUserDefaultsKey` 상수 1줄 + 섹션 MARK
- `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/affectionate-elion-d0363a/GanhoMusic/GanhoMusic Shared/Scenes/TitleScene.swift` — `preferenceRepo` 프로퍼티 1줄 + `didMove` 1줄 + `select(_:)` 1줄 (총 3줄)
- `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/affectionate-elion-d0363a/GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj` — 4 엔트리 등록

### 학습 노트 (1개)
- `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/affectionate-elion-d0363a/docs/learn/phase-5-6-character-preference-repo.md` — 중학생 톤 + Spring 비유 5가지

---

## 2. SPEC In Scope 충족 확인

| 항목 | 상태 | 비고 |
|---|---|---|
| Repository 신설 (`CharacterPreferenceRepository`) | ✓ | HighScoreRepository와 동형 구조 (DI init / current getter / save 메서드) |
| GameConfig 상수 1줄 | ✓ | `characterPreferenceUserDefaultsKey: String = "selectedCharacterID"` |
| TitleScene 3 지점 | ✓ | (a) 프로퍼티 (b) didMove에서 setupCharacterCards 직전 복원 (c) select(_:) 안 save |
| pbxproj 4 엔트리 | ✓ | PBXBuildFile / PBXFileReference / Repositories children / Sources 빌드 페이즈 |

---

## 3. Out of Scope 위반 0건 검증

| 금지 파일 | 변경 줄 수 |
|---|---|
| Models/CharacterID.swift | 0줄 ✓ |
| GameScene.swift | 0줄 ✓ |
| GameScene+Setup.swift | 0줄 ✓ |
| PlayerNode | 0줄 ✓ |
| HUDNode | 0줄 ✓ |
| CharacterCardNode | 0줄 ✓ |
| ColorTokens | 0줄 ✓ |
| HighScoreRepository | 0줄 ✓ |
| StatisticsRepository | 0줄 ✓ |
| 시스템 (ContactRouter/SpawnSystem/ScoreSystem) | 0줄 ✓ |
| ResultScene | 0줄 ✓ |
| Models/GameStats.swift | 0줄 ✓ |
| Protocols/ | 0줄 ✓ |

TitleScene 다른 부분 회귀 검증:
- `bestLabel` / `playsLabel` / `promptLabel` 변경 0줄 ✓
- `startPromptBlink` 변경 0줄 ✓
- `touchesBegan` 본체 변경 0줄 ✓
- 카드 setup / 카드 layout 변경 0줄 ✓
- `isTransitioning` 로직 변경 0줄 ✓
- `selectedCharacterID: CharacterID = .kim` 기본값 *유지* ✓ (안전망)

---

## 4. pbxproj 4 엔트리 실제 라인 번호

`grep -n "CharacterPreferenceRepository" project.pbxproj` 결과:

| # | 섹션 | 라인 | 내용 |
|---|---|---|---|
| 1 | PBXBuildFile | **28** | `A1C0F1B00000000000000024 /* CharacterPreferenceRepository.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1C0F1A00000000000000024 /* CharacterPreferenceRepository.swift */; };` |
| 2 | PBXFileReference | **57** | `A1C0F1A00000000000000024 /* CharacterPreferenceRepository.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CharacterPreferenceRepository.swift; sourceTree = "<group>"; };` |
| 3 | Repositories PBXGroup | **235** | `A1C0F1A00000000000000024 /* CharacterPreferenceRepository.swift */,` (StatisticsRepository 라인 232 다음) |
| 4 | Sources 빌드 페이즈 | **446** | `A1C0F1B00000000000000024 /* CharacterPreferenceRepository.swift in Sources */,` (StatisticsRepository in Sources 라인 442 다음) |

### ID 충돌 검증
- 작업 전 `grep "0000000000000024"` → "0024 is FREE" 확인 (미사용)
- 마지막 사용 ID = 0023 (CharacterCardNode). 다음 hex = 0024 → 정확히 적용.
- FileReference prefix `A1C0F1A0...` / BuildFile prefix `A1C0F1B0...` 기존 컨벤션 준수.

---

## 5. 빌드 결과

```
$ xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
             -scheme "GanhoMusic iOS" \
             -destination 'generic/platform=iOS Simulator' \
             -configuration Debug build
```

- **BUILD SUCCEEDED** ✓
- `grep -E "warning:|error:" | grep -v "AppIntents"` → **0줄** ✓
- AppIntents 경고는 프로젝트 무관 (Apple 시스템 메타데이터 추출 도구가 던지는 메시지)

---

## 6. 검증 시나리오 정적 추적

### (a) 5 캐릭터 각각 저장/복원
- `select(.jung)` → `selectedCharacterID = .jung` → `preferenceRepo.save(.jung)` → `defaults.set("jung", forKey: "selectedCharacterID")` ✓
- 재실행 시 `didMove` → `preferenceRepo.current` → `defaults.string(forKey:"selectedCharacterID")` = `"jung"` → `CharacterID(rawValue:"jung")` = `.jung` → `setupCharacterCards()`에서 `card.setSelected(card.id == .jung)` ✓
- 5 case (kim/jung/geon/im/lee) 모두 동일 경로 — enum String rawValue 자동 변환 ✓

### (b) 첫 실행 (UserDefaults 키 없음)
- `defaults.string(forKey:"selectedCharacterID")` → `nil` → `guard let` 분기 → `return .kim` ✓
- `selectedCharacterID: CharacterID = .kim` 프로퍼티 기본값과 일치 — 이중 안전망 ✓

### (c) 잘못된 raw value graceful degradation
- 누군가 `defaults.set("ganho", forKey:"selectedCharacterID")` 했다면 → `defaults.string` = `"ganho"` (non-nil) → `CharacterID(rawValue:"ganho")` = `nil` (CharacterID에 ganho 없음) → `?? .kim` → `.kim` ✓
- 크래시 없음. fatalError 없음. 강제 언래핑 없음 ✓

### (d) GameScene 진입 시 복원된 선택 사용
- `select(.jung)` 한 뒤 앱 종료/재실행 → `didMove`에서 `selectedCharacterID = .jung` 복원 → 카드 외 영역 탭 → `GameScene.newGameScene(characterID: .jung)` 호출 → PlayerNode 색 민트/속도 1.10x (Phase 5-2/5-3 결과물) ✓

### (e) 빌드 클린 (pbxproj 누락 회귀 — 핵심)
- 4 엔트리 모두 등록 → 컴파일 에러 0개, 경고 0개 ✓
- "Cannot find 'CharacterPreferenceRepository' in scope" 미발생 (4곳 등록 효과)
- pbxproj 4곳 라인 번호 28/57/235/446 모두 검증

### (f) TitleScene 다른 라벨 회귀 없음
- `bestLabel` 출력 경로 (line 61-62): `HighScoreRepository().current` 변경 0줄 ✓
- `playsLabel` 출력 경로 (line 64-65): `StatisticsRepository().current.playCount` 변경 0줄 ✓
- `promptLabel` 깜빡임 (`startPromptBlink`): `fadeOut`/`fadeIn` SKAction.repeatForever 변경 0줄 ✓
- 카드 5장 layout (`layoutCharacterCards`): startX 계산식 변경 0줄 ✓
- `isTransitioning` 더블 enter 방지: `guard !isTransitioning` 변경 0줄 ✓

### (g) 단일 진입점 검증 (핵심 — `select(_:)`만 디스크 I/O)
- 카드 영역 탭: `touchesBegan` → `card.contains(location)` true → `select(card.id)` 호출 → 함수 안 `preferenceRepo.save(id)` 1회 호출 → `return` (조기 종료) → GameScene 전환 안 함 ✓
- 카드 외 영역 탭: `touchesBegan` → for 루프 모두 miss → `guard !isTransitioning` 통과 → `GameScene.newGameScene(...)` 호출. **`select(_:)` 호출되지 않음** → `preferenceRepo.save` 호출 0회 → 디스크 I/O 없음 ✓
- 결론: `select(_:)`가 **유일한 save 진입점** — Spring `@Transactional` 단위처럼 작동 ✓

---

## 7. Swift/SpriteKit 패턴 준수

- **강제 언래핑 미사용**: `guard let raw = defaults.string(...)`로 nil-check, `?? .kim` 폴백 ✓
- **매직 넘버 미사용**: `"selectedCharacterID"` 리터럴은 `GameConfig.characterPreferenceUserDefaultsKey` 1곳에만 ✓
- **MARK 섹션 구분**: `// MARK: - Properties / Init / Read / Write` 4섹션 (HighScore/Statistics와 동형) ✓
- **`final class`**: Repository 상속 차단 ✓
- **DI 가능 init**: `init(defaults: UserDefaults = .standard, key: String = ...)` 기본값으로 prod/test 분기 ✓
- **단일 스레드 가정**: 메인(SpriteKit) 호출만 — 락 없음, 캐싱 없음 ✓
- **Timer 미사용**: 본 sprint는 시간 기반 동작 없음 (해당 없음) ✓
- **클로저 미사용**: `[weak self]` 캡처 필요 없음 (해당 없음) ✓

---

## 8. 학습 노트 작성

`/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/affectionate-elion-d0363a/docs/learn/phase-5-6-character-preference-repo.md`

- 중학생 수준 표현 (전문용어 최소화) ✓
- Spring 비유 5가지: `@Repository` 3번째 등장 / `@Value` default / `@Transactional` 단위 / `@Enumerated(EnumType.STRING)` / 직렬화 전략 비교 표 ✓
- before/after 박스 다이어그램 + 표 ✓
- "한 줄 요약" 마무리 — 작은 친절함 뒤의 책임 분리 ✓

---

## 결론

- SPEC In Scope 4 항목 100% 충족
- Out of Scope 13 카테고리 0줄 변경 (회귀 위험 없음)
- BUILD SUCCEEDED + 경고 0 + 에러 0
- pbxproj 4곳 라인 번호 검증 (28/57/235/446)
- 검증 시나리오 (a)~(g) 정적 추적 모두 통과
- 학습 노트 톤/형식/Spring 비유 5가지 확보
