# Sprint 3 - Character Unlock and Rough Selection

## 목표

캐릭터 선택 화면에서 화면 좌우를 러프하게 눌러도 캐릭터가 넘어가게 한다. 동시에 캐릭터 해금 구조를 복구한다. 잠긴 캐릭터는 검정 실루엣으로만 보이고 선택/시작이 불가능해야 한다. 이 진행도는 로그인한 계정마다 달라야 한다.

## 현재 상태

- `CharacterSelectScene`은 `CharacterID.allCases` 전체를 rail에 표시하고 모두 선택 가능하게 저장한다.
- `selectCharacter(at:animated:)`는 index만 clamp하고 lock 여부는 보지 않는다.
- `transitionToNext()`는 현재 선택 캐릭터를 저장하고 다음 화면으로 이동한다.
- `GraduationRepository`는 캐릭터별 졸업 여부를 UserDefaults 전역 key(`graduations`)로 저장한다.
- `PerDifficultyScoreRepository`도 캐릭터 x 난이도 점수를 저장하지만 현재 계정별 namespace가 없다.
- `CloudProgressSnapshot`은 graduations와 perDifficultyScores를 Firestore에 저장할 수 있지만, 읽기/복원 흐름은 아직 없다.
- `CharacterPortraitNode`는 전신 프리뷰를 보여주지만 locked silhouette 모드는 없다.

## 변경 의도

캐릭터 홈은 "내 계정의 진행도"를 보여주는 화면이어야 한다. 모든 캐릭터가 처음부터 열려 있으면 업적/기록/해금의 의미가 사라진다. 계정별로 진행도가 분리되어야 Apple 계정 로그인 가치도 생긴다.

## 해금 규칙 제안

1차 규칙은 순차 해금이다.

| 캐릭터 | 상태/해금 조건 |
|---|---|
| 김간호 | 기본 해금 |
| 정간호 | 김간호 졸업 후 해금 |
| 건간호 | 정간호 졸업 후 해금 |
| 임간호 | 건간호 졸업 후 해금 |
| 이간호 | 임간호 졸업 후 해금 |

여기서 "졸업"은 현재 코드의 `GameScene.isGraduated` 기준을 유지한다. 즉 해당 캐릭터가 하/중/상 모든 목표 점수를 넘으면 `GraduationRepository.record(characterID:)`가 기록된다.

이 규칙이 너무 빡빡하면 후속 튜닝에서 "하 난이도 목표 달성 시 다음 캐릭터 해금"으로 낮출 수 있다. 이번 계획의 기본값은 기존 졸업장 시스템을 재사용하는 것이다.

## 계정별 진행도 설계

### 핵심 문제

현재 저장소 key가 전역이면 게스트/Apple/다른 Apple 계정의 졸업 기록이 섞인다. 잠금 해제를 계정별로 만들려면 최소한 다음 저장소가 계정 scope를 알아야 한다.

- `GraduationRepository`
- `PerDifficultyScoreRepository`
- `CharacterPreferenceRepository`

선택적으로 다음도 계정별이어야 자연스럽다.

- `HighScoreRepository`
- `StatisticsRepository`

하지만 이 Sprint의 필수 목표는 "해금/선택 가능 여부가 계정별"인 것이다. 점수/통계 전체 계정 분리는 범위를 키우므로, 1차 구현은 unlock 판단에 쓰이는 저장소를 우선 scope한다.

### 권장 구조

신규 값 객체:

```swift
struct AccountProgressScope {
    let uid: String
    let isAnonymous: Bool

    var storageSuffix: String {
        return isAnonymous ? "guest.\(uid)" : "user.\(uid)"
    }
}
```

신규 helper:

```swift
enum AccountProgressScopeProvider {
    static func current(authProfile: AuthProfileSnapshot?) -> AccountProgressScope
}
```

fallback:

- AuthProfile이 있으면 `uid` 사용.
- AuthProfile이 nil이면 `local` 또는 `guest-local` scope를 사용.

Repository 변경 방식:

- 기존 initializer에 `key:`가 있으므로, 새 factory/helper로 scoped key를 만들어 주입한다.
- 예:
  - `graduations.user.<uid>`
  - `perDifficultyScores.user.<uid>`
  - `characterPreference.user.<uid>`

장점:

- 기존 저장소 포맷을 깨지 않는다.
- account scope만 key suffix로 분리한다.
- 구현이 큰 repository rewrite 없이 가능하다.

### Cloud sync 읽기 보강

Apple 계정마다 다른 구조를 제대로 만들려면 "저장"뿐 아니라 "읽기"가 필요하다.

Sprint 3에서 권장하는 최소 cloud read:

- `CloudProgressRepository.fetchProgress(uid:) async throws -> CloudProgressSnapshot?`
- `CloudSaveCoordinator.syncProgressForCurrentUser() async`
- Apple 로그인 성공 후 CharacterSelect 진입 전 또는 CharacterSelect didMove에서 sync 시도.
- cloud progress가 있으면 scoped local 저장소에 merge.
- merge 정책:
  - per difficulty score: max
  - graduation date: 더 이른 날짜 우선
  - selected character: 현재 unlocked면 cloud/local 중 최신값, 아니면 first unlocked로 보정

단, Firestore read가 지연되어도 캐릭터 홈은 로컬 캐시로 먼저 뜨고, sync 완료 후 refresh한다.

## 캐릭터 unlock 모델

신규 모델 후보:

```swift
struct CharacterUnlockState {
    let characterID: CharacterID
    let isUnlocked: Bool
    let unlockRequirementText: String?
}
```

신규 helper 후보:

```swift
enum CharacterUnlockRules {
    static func states(graduations: [CharacterID: Date]) -> [CharacterUnlockState]
    static func isUnlocked(_ id: CharacterID, graduations: [CharacterID: Date]) -> Bool
    static func previousCharacter(for id: CharacterID) -> CharacterID?
    static func nextCharacter(after id: CharacterID) -> CharacterID?
}
```

특징:

- unlock 여부는 저장하지 않고 graduation 상태에서 계산한다.
- 저장 데이터가 중복되지 않는다.
- 순차 규칙 변경 시 helper만 바꾸면 된다.

## UI/UX 설계

### 러프 좌우 탭

터치 우선순위는 버튼 오작동을 막기 위해 유지한다.

1. back pill
2. home menu section
3. rail/arrow
4. start button
5. rough side zones

rough side zone:

- 캐릭터 stage frame 기준 좌측 35%를 누르면 이전 unlocked 캐릭터.
- stage frame 기준 우측 35%를 누르면 다음 unlocked 캐릭터.
- 또는 화면 전체 좌/우 side band를 쓰되, 우측 profile/detail panel 영역은 제외한다.

권장 1차:

- `characterStageFrame` 안의 좌/우 영역을 먼저 지원한다.
- 사용자가 "화면 우측/좌측"이라고 했으므로 stage 바깥도 지원하되, UI 버튼 hit-test 이후에만 처리한다.

### 잠긴 캐릭터 표시

캐릭터 stage:

- full body를 검정 실루엣으로 표시.
- 이름 대신 `???` 또는 캐릭터 이름 + 자물쇠 중 하나를 선택.
- 스킬/속도 chip은 숨기거나 `해금 필요`로 표시.
- start button은 비활성/숨김.

rail:

- locked rail cell은 어두운 fill, 낮은 alpha.
- label은 `?` 또는 lock icon text.
- rail tap은 선택을 막거나, 선택은 허용하되 start는 막는 방식 중 하나를 택해야 한다.

권장:

- locked 캐릭터도 "미리보기"는 가능하게 하되 선택 상태는 locked preview로 표시한다.
- `startButton`은 disabled.
- preference 저장은 unlocked 캐릭터일 때만 한다.

이유:

- 사용자가 실루엣을 볼 수 있어 해금 목표가 보인다.
- 잠긴 캐릭터를 아예 건너뛰면 "순차 해금 구조"가 덜 명확하다.

### 선택/시작 정책

- rough left/right는 locked 캐릭터도 이동 가능하게 하여 실루엣 preview를 보여준다.
- `transitionToNext()`는 `guard isSelectedCharacterUnlocked`로 차단한다.
- rail tap도 locked preview로 이동은 가능하다.
- 현재 계정의 saved preference가 locked라면 didMove에서 first unlocked로 보정한다.

### 해금 보상 표시

신규 졸업으로 다음 캐릭터가 열리면 결과 화면에 작게 표시하는 것을 권장한다.

- `정간호 해금!`
- 또는 `새 캐릭터가 열렸어요`

이건 Sprint 3의 필수는 아니지만 해금 구조 이해에 도움이 된다. 범위가 커지면 후속 Sprint로 뺀다.

## 구현 단계

### Phase A - Account progress scope

- `AccountProgressScope`와 provider 추가.
- `CharacterSelectScene`에서 scoped repositories를 만들도록 변경.
- `GameScene`에서 result 저장 시에도 같은 scope를 사용하도록 변경한다.
- `CharacterPreferenceRepository` current가 locked이면 first unlocked로 보정.

### Phase B - Unlock rule

- `CharacterUnlockRules` 추가.
- `CharacterHomeSnapshot`에 unlock states 추가.
- `ProfileSummaryPanelNode` 또는 `AchievementStripNode`에서 unlock progress를 표시할 수 있게 한다.

### Phase C - CharacterSelectScene state 변경

- `selectedCharacterID`, `currentIndex`는 유지.
- `isSelectedCharacterUnlocked` computed property 추가.
- `selectCharacter(at:animated:)`는 locked/unlocked 모두 preview 가능하게 하되 preference 저장은 unlocked일 때만.
- `transitionToNext()`는 locked면 short feedback만 주고 return.

### Phase D - Silhouette rendering

- `CharacterPortraitNode`에 `setLocked(_:)` 또는 `update(characterID:isLocked:)` 추가.
- 구현 방법:
  - texture 기반이면 `color = .black`, `colorBlendFactor = 1`, `alpha = 0.78`.
  - fallback node도 같은 alpha/black overlay 적용.
- lock badge를 CharacterSelectScene stage에 추가할지, PortraitNode 내부에 둘지 결정한다.
  - 권장: CharacterSelectScene stage label이 lock text를 담당하고, PortraitNode는 silhouette만 담당.

### Phase E - Rough side tap

- `handleRoughCharacterSideTap(at:) -> Bool` 추가.
- hit-test 순서 마지막에 배치한다.
- 이전/다음 이동은 `selectCharacter(at:)` 대신 `selectAdjacentCharacter(direction:)` helper로 통일한다.
- locked preview 허용 정책이면 단순 index 이동.
- locked를 건너뛰는 정책이면 next unlocked index를 찾는다.

### Phase F - Cloud sync read

- `CloudProgressRepository`에 summary read 추가.
- `CloudSaveCoordinator.syncProgressForCurrentUser()` 추가.
- `StartScene` Apple success 이후 또는 `CharacterSelectScene.didMove`에서 비동기 sync 후 refresh.
- sync 실패 시 로컬 캐시로 계속 사용하고 status만 조용히 남긴다.

## 예상 수정 파일

- `GanhoMusic/GanhoMusic Shared/Scenes/CharacterSelectScene.swift`
- `GanhoMusic/GanhoMusic Shared/Nodes/CharacterPortraitNode.swift`
- `GanhoMusic/GanhoMusic Shared/Nodes/AchievementStripNode.swift`
- `GanhoMusic/GanhoMusic Shared/Nodes/RecordSummaryPanelNode.swift`
- `GanhoMusic/GanhoMusic Shared/Models/CharacterHomeSnapshot.swift`
- `GanhoMusic/GanhoMusic Shared/Models/CharacterUnlockState.swift` 신규 후보
- `GanhoMusic/GanhoMusic Shared/Models/AccountProgressScope.swift` 신규 후보
- `GanhoMusic/GanhoMusic Shared/Repositories/GraduationRepository.swift`
- `GanhoMusic/GanhoMusic Shared/Repositories/PerDifficultyScoreRepository.swift`
- `GanhoMusic/GanhoMusic Shared/Repositories/CharacterPreferenceRepository.swift`
- `GanhoMusic/GanhoMusic Shared/Repositories/CloudProgressRepository.swift`
- `GanhoMusic/GanhoMusic Shared/Managers/CloudSaveCoordinator.swift`
- `GanhoMusic/GanhoMusic Shared/GameScene+GameState.swift`
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`
- `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj` 신규 파일 추가 시

## 보존할 것

- `CharacterSelectScene.newCharacterSelectScene()` 시그니처.
- 김간호는 기본 해금.
- 기존 졸업장 판정의 목표 점수 기준.
- 기존 스킬 설명/난이도 선택 흐름.
- 게스트 플레이 가능성.

## 수용 기준

- 화면 좌측/우측을 러프하게 눌러 캐릭터 preview가 넘어간다.
- 잠긴 캐릭터는 검정 실루엣으로 보인다.
- 잠긴 캐릭터로 게임을 시작할 수 없다.
- unlock 조건이 충족된 캐릭터는 선택/시작 가능하다.
- 계정 A와 계정 B의 unlock 상태가 섞이지 않는다.
- Apple 로그인 후 해당 계정의 cloud 진행도가 있으면 반영된다.
- saved preference가 locked인 경우 첫 unlocked 캐릭터로 보정된다.

## 리스크와 대응

- 리스크: 계정별 저장소 scope 변경이 기존 로컬 진행도와 충돌할 수 있다.
  - 대응: 첫 실행 시 기존 전역 저장소는 guest/local scope로만 migrate하고, Apple scope에는 자동 복사하지 않는다.
- 리스크: cloud read가 느리면 홈 UI가 늦게 갱신된다.
  - 대응: 로컬 캐시 우선, sync 후 refresh.
- 리스크: locked preview 허용이 "선택 가능"처럼 보일 수 있다.
  - 대응: start button disabled, lock badge, requirement text를 명확히 한다.
- 리스크: 졸업 기준이 너무 빡빡해 해금이 거의 안 될 수 있다.
  - 대응: 이번 Sprint는 기존 졸업 시스템 복구로 한정하고, 목표 점수/조건 완화는 별도 밸런스 작업으로 둔다.

