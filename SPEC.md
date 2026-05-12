# Phase 5-6 — selectedCharacterID 영구 저장 (CharacterPreferenceRepository)

## 개요
현재 `TitleScene.selectedCharacterID`는 매 앱 실행마다 하드코딩 기본값 `.kim`으로 초기화되어, 사용자는 카드 5장 중 매번 다시 자기 캐릭터를 골라야 한다. Phase 5-6은 마지막 선택을 UserDefaults에 영구 저장하는 `CharacterPreferenceRepository`를 신설하여, 앱을 종료/재실행해도 직전 선택이 자동 복원되도록 한다. 이미 두 번 등장한 Repository 패턴(`HighScoreRepository`/`StatisticsRepository`)을 *세 번째* 그대로 적용 — Spring의 `@Repository`처럼 영속 계층을 단일 클래스에 캡슐화한다.

## 변경 유형
**게임플레이 + UX** — 게임 규칙은 그대로지만, 사용자 환경설정의 영속성을 통해 진입 경험을 개선한다.

## 게임 경험 의도
"내가 좋아하는 간호사를 한 번 고르면, 다음 번에도 게임은 그 간호사를 기억한다." 매 앱 실행마다 카드를 다시 누르는 마찰을 제거하여, 사용자의 캐릭터 정체성을 게임이 인정하는 작은 의례를 만든다. 영속성은 보이지 않는 곳에서 일어나야 한다 — UI 추가 없이, 단지 "기본 선택"이 마지막 선택으로 바뀐다.

## Sprint 범위 계약

### 허용
- `Repositories/CharacterPreferenceRepository.swift` 신규 생성 (3번째 Repository — 기존 2개와 동형)
- `Config/GameConfig.swift`에 `characterPreferenceUserDefaultsKey` 상수 1줄 추가
- `Scenes/TitleScene.swift`에 (a) `private let preferenceRepo` 프로퍼티 추가 (b) `didMove(to:)`에서 `setupCharacterCards()` 호출 *직전*에 `selectedCharacterID = preferenceRepo.current` 복원 (c) `select(_:)` 함수 내부에서 변경 직후 `preferenceRepo.save(id)` 호출
- `project.pbxproj`에 신규 .swift 파일 4곳 엔트리 등록 (PBXBuildFile 1개 + PBXFileReference 1개 + Repositories 그룹 children 1개 + Sources 빌드 페이즈 1개)

### 금지 (위반 시 P0)
- `Models/CharacterID.swift` 변경 — enum이 이미 `String` raw value를 가져 추가 변환 불필요
- `GameScene.swift` / `GameScene+Setup.swift` 변경
- `PlayerNode` / `HUDNode` / `CharacterCardNode` 변경
- `ColorTokens` 변경
- `HighScoreRepository` / `StatisticsRepository` 변경 (0줄)
- 시스템 (`ContactRouter` / `SpawnSystem` / `ScoreSystem`) 변경
- `ResultScene` 변경 (5-7 이후 sprint)
- `Models/GameStats.swift` 변경
- `Protocols/` 변경
- TitleScene의 다른 부분: `bestLabel` / `playsLabel` / `promptLabel` / `startPromptBlink` / `touchesBegan` 본체 / 카드 setup / 카드 layout / `isTransitioning` 로직 변경
- macOS / tvOS / Test 코드

### 판단 기준
"이 변경이 없으면 '앱 종료 후 재진입 시 마지막에 선택한 캐릭터가 카드에 선택 상태로 표시되며 GameScene 진입 시 그대로 사용된다'가 동작하는가?" → NO만 In Scope.

## 핵심 결정 포인트

### 1. Fallback 정책 — `.kim` 반환
- 저장값이 없거나(첫 실행) 잘못된 raw value면 `.kim` 반환. `CharacterID(rawValue:)`가 `Optional<CharacterID>`를 반환 → `?? .kim`로 폴백.
- **사유**: `.kim`은 5-1 도입 시점부터 기본 캐릭터. graceful degradation 원칙. Spring `@Value("${...:kim}")`의 default 부분과 동일.

### 2. Save 호출 시점 — `select(_:)` 내부 (단일 진입점)
- `select(_:)` 함수 내부, `selectedCharacterID = id` 직후 `preferenceRepo.save(id)` 호출.
- **사유**: `select(_:)`는 모든 카드 선택 변경의 단일 진입점. Spring `@Transactional` 단위와 동일.
- **부작용 평가**: 매 탭마다 `UserDefaults.set` 1회. UserDefaults 내부 비동기 flush로 응답성 저하 없음.

### 3. Load 호출 시점 — `didMove(to:)` 안, `setupCharacterCards()` *직전*
- `didMove(to:)` 본문 순서:
  ```
  backgroundColor = .ganhoBgDeep
  setupLabels()
  selectedCharacterID = preferenceRepo.current   // ← 신규 1줄
  setupCharacterCards()
  startPromptBlink()
  ```
- **사유**: `setupCharacterCards()`가 내부 루프에서 `card.setSelected(id == selectedCharacterID)` 호출 → 카드 생성 *시점*에 selectedCharacterID가 정확해야 첫 프레임부터 올바른 카드가 selected scale/alpha로 표시됨.

### 4. pbxproj 처리 — Generator가 수동 등록 필수
- 이 프로젝트는 **명시적 pbxproj 등록 방식**을 사용 (기존 Repository 파일들이 모두 4곳에 명시 등록됨).
- Generator는 다음 4곳에 엔트리 추가:
  1. `PBXBuildFile` 섹션
  2. `PBXFileReference` 섹션
  3. `Repositories` PBXGroup children
  4. Sources 빌드 페이즈
- **ID 충돌 방지**: 작업 직전 `grep "A1C0F1.0000000000000023" project.pbxproj`로 마지막 사용 ID 확인 후 +1 (16진수 다음값) 부여. 권장 새 ID: `A1C0F1A00000000000000024` (FileReference), `A1C0F1B00000000000000024` (BuildFile).
- 누락 시 `Cannot find 'CharacterPreferenceRepository' in scope` 컴파일 에러 → P0.

## 변경 범위

### 추가할 파일
- `GanhoMusic/GanhoMusic Shared/Repositories/CharacterPreferenceRepository.swift`

### 수정할 파일
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift` — 상수 1줄
- `GanhoMusic/GanhoMusic Shared/Scenes/TitleScene.swift` — 프로퍼티 + 2지점 호출
- `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj` — 4 엔트리

## 기능 상세

### 기능 1: `CharacterPreferenceRepository` 신규 클래스

**핵심 코드 구조**:
```swift
//
//  CharacterPreferenceRepository.swift
//  GanhoMusic Shared
//
//  Phase 5-6 · 캐릭터 선택 영구 저장 (UserDefaults 캡슐화)
//

import Foundation

/// 마지막으로 선택한 캐릭터(CharacterID)를 UserDefaults에 raw String으로 영구 저장.
/// 키 문자열은 GameConfig.characterPreferenceUserDefaultsKey로 단일화.
/// init에 defaults/key를 기본값으로 받아 DI를 허용 — prod는 CharacterPreferenceRepository(),
/// 테스트는 별도 suite 주입 가능. 단일 스레드(메인) 호출 가정 → 락/큐 없음.
/// 패턴: HighScoreRepository / StatisticsRepository와 동형 (3번째 Repository).
final class CharacterPreferenceRepository {

    // MARK: - Properties
    private let key: String
    private let defaults: UserDefaults

    // MARK: - Init
    init(defaults: UserDefaults = .standard,
         key: String = GameConfig.characterPreferenceUserDefaultsKey) {
        self.defaults = defaults
        self.key = key
    }

    // MARK: - Read
    /// 저장된 캐릭터 선택. 키가 없거나(첫 실행) 잘못된 raw value면 .kim 폴백.
    var current: CharacterID {
        guard let raw = defaults.string(forKey: key) else { return .kim }
        return CharacterID(rawValue: raw) ?? .kim
    }

    // MARK: - Write
    /// 캐릭터 선택을 저장. rawValue(String)로 직렬화.
    /// 호출부는 select(_:) 단일 진입점 — Spring @Transactional 단위와 동일.
    func save(_ id: CharacterID) {
        defaults.set(id.rawValue, forKey: key)
    }
}
```

### 기능 2: GameConfig 상수 1줄 추가

**위치**: `// MARK: - Character Card` 섹션 끝 (마지막 character 관련 상수 다음). 또는 `statisticsUserDefaultsKey` 다음 줄도 허용.

**핵심 코드**:
```swift
/// Phase 5-6 — UserDefaults에 마지막 캐릭터 선택을 raw String으로 저장할 키.
/// 호출부에 리터럴 노출 금지 — CharacterPreferenceRepository만 사용.
static let characterPreferenceUserDefaultsKey: String = "selectedCharacterID"
```

### 기능 3: TitleScene 3 지점 수정

**3-a. 프로퍼티 추가** (Properties 섹션, `characterCards` 다음 줄):
```swift
/// Phase 5-6 — 캐릭터 선택 영속 계층. didMove에서 .current로 복원, select(_:)에서 save 호출.
private let preferenceRepo = CharacterPreferenceRepository()
```

**3-b. `didMove(to:)` 안 1줄 삽입**:
```swift
override func didMove(to view: SKView) {
    backgroundColor = .ganhoBgDeep
    setupLabels()
    selectedCharacterID = preferenceRepo.current   // Phase 5-6 — 마지막 선택 복원 (없으면 .kim)
    setupCharacterCards()
    startPromptBlink()
}
```

**3-c. `select(_:)` 안 1줄 삽입**:
```swift
private func select(_ id: CharacterID) {
    selectedCharacterID = id
    preferenceRepo.save(id)   // Phase 5-6 — 선택 변경 즉시 디스크 반영
    for card in characterCards {
        card.setSelected(card.id == id)
    }
}
```

### 기능 4: pbxproj 4 지점 등록

위 "핵심 결정 4번"에서 명시한 4 라인을 정확한 위치에 삽입. Generator는 작업 직전 `Grep`으로 ID 충돌 확인.

## 검증 시나리오

### (a) 5 캐릭터 각각 저장/복원
- 시뮬레이터: 김 선택 → 강제 종료/재실행 → 김 카드 selected ✓
- 정/건/임/이 동일 절차로 5번 모두 검증

### (b) 첫 실행 (UserDefaults 키 없음)
- 시뮬레이터 reset → 첫 실행 시 김 카드 selected (graceful) ✓

### (c) 잘못된 raw value graceful degradation
- `UserDefaults.set("ganho", forKey: "selectedCharacterID")` 후 재실행 → 크래시 없이 김 선택 ✓

### (d) GameScene 진입 시 복원된 선택 사용
- 정 선택 → 재실행 → 정 카드 selected → 빈 곳 탭 → `newGameScene(characterID: .jung)` → PlayerNode 색 민트/속도 1.10x ✓

### (e) 빌드 클린 (pbxproj 누락 회귀)
- 빌드 → 컴파일 에러 0개, 경고 0개 ✓
- pbxproj 4곳 등록 확인

### (f) TitleScene 다른 라벨 회귀 없음
- `bestLabel` / `playsLabel` / `promptLabel` / 카드 5장 layout / `isTransitioning` 더블 탭 방지 모두 그대로 ✓

### (g) 단일 진입점 검증
- 카드 영역 탭 시: `select(card.id)` → `preferenceRepo.save` 호출
- 카드 외 영역 탭 시: `select()` 호출되지 *않음* → 디스크 I/O 0 → GameScene 전환만 ✓

## 학습 가치

### Repository 패턴 정합 (3번째 등장)
이 sprint의 핵심 학습은 **같은 패턴을 세 번째로 그대로 적용하는 경험**이다.
- `HighScoreRepository` (Phase 3-4) — `Int` 값
- `StatisticsRepository` (Phase 3-5) — `Codable struct GameStats` (JSON Data)
- `CharacterPreferenceRepository` (Phase 5-6) — `enum CharacterID` (raw String)

세 클래스 모두 동일 구조: `init(defaults:key:)` DI / `var current: T { get }` 읽기 / `func save(...)` 쓰기.

### Spring 비유 (Spring Boot 출신자 친화)
- **`@Repository`**: 영속 계층을 단일 클래스에 캡슐화. 호출부는 UserDefaults를 *모른다* → 저장소가 Core Data로 바뀌어도 호출부 0줄.
- **`@Value("${key:default}")`**: `current` getter의 `?? .kim` fallback = Spring property default 문법.
- **`@Transactional` 단위**: `select(_:)` 함수 1회 호출 = 1 트랜잭션 (메모리 + 디스크). 단일 진입점에 묶어두면 누락/중복 위험이 사라짐.
- **`enum.rawValue` ↔ `@Enumerated(EnumType.STRING)`**: enum과 String 자동 변환.

### 직렬화 전략 비교 (3 Repository 차이)
| Repository | 타입 | 직렬화 | 실패 시 fallback |
|---|---|---|---|
| HighScore | `Int` | `defaults.integer(forKey:)` | 0 (Apple 보장) |
| Statistics | `struct: Codable` | JSON Data | `GameStats()` |
| **CharacterPreference** | `enum: String` | rawValue String | `.kim` |

저장 대상의 형태에 가장 단순한 직렬화를 선택하는 원칙.

## 주의사항

### 기존 코드와 충돌 가능성
- `selectedCharacterID: CharacterID = .kim` 기본값은 *유지* (안전망).
- `preferenceRepo`를 `private let`으로 선언 → 씬 생명주기 동안 1회만 생성.

### SpriteKit 특성상 주의
- `didMove(to:)` 코드 순서가 중요: `setupLabels()` → 복원 → `setupCharacterCards()` 순. 순서 바뀌면 첫 프레임에 잘못된 카드 selected.

### 빌드 에러 가능성
- **pbxproj 등록 누락 시 P0**: Generator는 4곳 등록 후 SELF_CHECK에 명시.
- **ID 충돌**: 새 ID는 grep으로 미사용 확인 후 부여.

### Generator 체크리스트
1. [ ] `CharacterPreferenceRepository.swift` 신규 생성 (HighScore와 동형)
2. [ ] `GameConfig.characterPreferenceUserDefaultsKey = "selectedCharacterID"` 1줄
3. [ ] TitleScene 프로퍼티 `preferenceRepo` 추가
4. [ ] `didMove`에 `setupCharacterCards()` 직전 복원 1줄
5. [ ] `select(_:)`에 `preferenceRepo.save(id)` 1줄
6. [ ] `project.pbxproj` 4곳 등록
7. [ ] `selectedCharacterID = .kim` 기본값 *유지*
8. [ ] Out of Scope 파일 0줄
9. [ ] 강제 언래핑 0
10. [ ] 매직 넘버 0 (UserDefaults 키는 GameConfig 경유)
