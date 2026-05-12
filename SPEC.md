# Phase 6-1 — HapticsManager (진동 피드백) — Phase 6 첫 진입

## 개요
게임 손맛을 강화하기 위해 시스템 햅틱(`UIImpactFeedbackGenerator`)을 도입한다. 노트 수집 = light, 게임오버 = heavy 2종만. 외부 에셋 0, 트리거 지점은 GameScene 2곳(`onNoteCollected` 콜백 + `endGame()`)뿐. Phase 6의 첫 진입이자 **Manager 패턴(Spring `@Service` 빈 비유)의 첫 등장** — Phase 5 동안 굳어진 Repository 패턴(영속 책임)과 대비되는 *부수효과(side-effect) 책임*을 학습한다.

## 변경 유형
**게임플레이 + UX 폴리싱** — 게임 로직 자체는 트리거 호출 2지점 추가만(상태/스코어 무변경). 플레이어 체감은 폴리싱(촉각 피드백). 시각 변화 0.

## 게임 경험 의도
1. **음표 수집 손맛**: 매 수집마다 가벼운 톡 — "내가 제대로 먹었구나"를 시각 점수 갱신 *이전*에 손끝으로 먼저 알게 한다. 콤보 윈도우 내 연속 수집 시 톡톡톡 리듬감.
2. **게임오버 무게감**: 시간 만료/적 접촉/F 피격 — 어느 경로든 묵직한 한 방. ResultScene fade transition 직전에 *끝났다*는 명확한 신호.
3. 시뮬레이터/햅틱 미지원 디바이스에서는 UIKit이 자동 noop 처리 → 시각/로직은 동일하게 작동.

## Sprint 범위 계약

### 허용
- `Managers/HapticsManager.swift` 신설
- `GameScene.swift` 프로퍼티 1줄(`let haptics = HapticsManager()`) + `configureContactRouter()` 안 1줄(`haptics.light()`) + `endGame()` 안 1줄(`haptics.heavy()`)
- `project.pbxproj` 5곳(BuildFile + FileReference + 신규 PBXGroup Managers + 루트 mainGroup children + Sources phase)

### 금지 (위반 시 P0)
- 사운드(AVFoundation) / medium·rigid·soft 햅틱 / 콤보 마일스톤 햅틱 / 이스터에그 햅틱 / DI mock / 음소거 옵션 / Repository 영속 저장
- `GameScene.swift`의 다른 부분 (init / factory / didMove / didChangeSize / layoutDPad / layoutHUD / update / triggerAirforceEasterEgg / configureContactRouter의 다른 4 콜백 / endGame의 멱등 가드 외 부분) 변경
- `GameScene+Setup.swift` 변경
- `Systems/ContactRouter.swift` / `Systems/ScoreSystem.swift` / `Systems/SpawnSystem.swift` 변경
- 모든 `Nodes/*` 변경
- `Scenes/TitleScene.swift` / `Scenes/ResultScene.swift` 변경
- `Models/CharacterID.swift` / `Models/GameStats.swift` 변경
- `Repositories/*` 3개 변경
- `Protocols/` 변경
- `Config/*` 4개 변경 (특히 `GameConfig` — 햅틱 강도는 enum case로 충분)
- macOS / tvOS Sources phase / Test 코드

### 판단 기준
"이 변경이 없으면 '음표 수집 시 라이트 햅틱 + 게임오버 시 헤비 햅틱이 트리거된다'가 동작하는가?" → NO만 In Scope.

## 4 핵심 결정 포인트

### 결정 1 — Managers PBXGroup 신설
디스크에 `GanhoMusic Shared/Managers/`가 이미 존재(README.md만), pbxproj엔 미등록. 신규 PBXGroup `Managers` 신설.
- 폴더-그룹 1:1 매핑 원칙 (spritekit-rules §11)
- `AudioManager` 등 후속 작업이 같은 그룹에 추가될 거라 지금 만드는 게 합리적
- pbxproj 5곳 편집 (5-6 대비 +1곳)

### 결정 2 — import 정책
**`import UIKit`만 1줄.** `UIImpactFeedbackGenerator`는 UIKit 소속, UIKit이 Foundation 추이 import.

### 결정 3 — prepare() 시점
**init 1회 + 매 트리거 직후 재호출.**
- init: 첫 트리거 지연 최소화
- impactOccurred 직후: 다음 트리거 대비 워밍 유지 (연속 수집 끊김 방지)

### 결정 4 — endGame 안 호출 위치
**멱등 가드 직후, `gameState = .gameOver` 다음 줄.**
- 가드를 통과한 첫 호출만 트리거 → 중복 방지
- spawn 정지/velocity 정지보다 햅틱이 먼저면 즉각성↑

## 변경 범위

### 추가할 파일
- `GanhoMusic Shared/Managers/HapticsManager.swift`

### 수정할 파일
- `GanhoMusic Shared/GameScene.swift` (3줄 추가)
- `GanhoMusic.xcodeproj/project.pbxproj` (5곳 추가)

## 기능 상세

### 기능 1: HapticsManager 클래스

**핵심 코드 구조**:
```swift
//
//  HapticsManager.swift
//  GanhoMusic Shared
//
//  Phase 6-1 · 시스템 햅틱 피드백 캡슐화 (Manager 패턴 첫 등장)
//

import UIKit

/// 시스템 햅틱 발생기를 캡슐화한 매니저.
/// - light(): 노트 수집 등 가벼운 긍정 피드백
/// - heavy(): 게임오버 등 묵직한 종료 피드백
/// 시뮬레이터/햅틱 미지원 디바이스에서는 UIKit이 자동 noop 처리.
/// Spring 비유: side-effect 책임을 가진 @Service 빈. Repository(영속 책임)와 대비.
final class HapticsManager {

    // MARK: - Properties
    private let lightGenerator: UIImpactFeedbackGenerator
    private let heavyGenerator: UIImpactFeedbackGenerator

    // MARK: - Init
    init() {
        lightGenerator = UIImpactFeedbackGenerator(style: .light)
        heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
        // 첫 트리거 지연 최소화를 위해 미리 워밍
        lightGenerator.prepare()
        heavyGenerator.prepare()
    }

    // MARK: - Triggers
    /// 가벼운 톡. 노트 수집 시 호출. 직후 prepare()로 다음 호출 대비.
    func light() {
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    /// 묵직한 한 방. 게임오버 시 호출. 직후 prepare()로 다음 호출 대비.
    func heavy() {
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }
}
```

### 기능 2: GameScene 프로퍼티 추가

**위치**: 시스템 섹션 (`scoreSystem` / `highScoreRepo` / `statsRepo` 뒤).
```swift
let haptics = HapticsManager()   // Phase 6-1 — 손맛 강화 (Manager 패턴 첫 등장)
```

### 기능 3: 노트 수집 시 light 햅틱

**위치**: `configureContactRouter()` 안 `onNoteCollected` 콜백, `scoreSystem.recordNoteHit` *직후*, `note.run(.removeFromParent())` *직전*.

```swift
contactRouter.onNoteCollected = { [weak self] note in
    guard let self = self else { return }
    self.scoreSystem.recordNoteHit(at: self.lastUpdateTime)
    self.haptics.light()   // Phase 6-1 — 수집 손맛
    note.run(.removeFromParent())
}
```

### 기능 4: 게임오버 시 heavy 햅틱

**위치**: `endGame()` 안, `gameState = .gameOver` *다음 줄*, `spawnSystem.stop()` *이전*.

```swift
private func endGame() {
    if gameState == .gameOver { return }
    gameState = .gameOver
    haptics.heavy()   // Phase 6-1 — 종료 무게감 (가드 통과 1회만)
    spawnSystem.stop()
    // ... 이하 기존 코드 그대로
}
```

## pbxproj 작업 명세 (5곳)

기존 ID 패턴:
- PBXBuildFile: `A1C0F1B0...001X` 시리즈 (최근 `...0024` CharacterPreferenceRepository)
- PBXFileReference: `A1C0F1A0...001X` 시리즈 (최근 `...0024`)
- PBXGroup: 그룹별로 다른 prefix

**신규 ID 제안 (충돌 방지 grep 필수)**:
- BuildFile: `A1C0F1B00000000000000025`
- FileReference: `A1C0F1A00000000000000025`
- Managers PBXGroup: `A1C0F2000000000000000017`

Generator는 작업 전 grep으로 미사용 확인. hit 발생 시 +1 재확인.

### 편집 5곳

**(1) PBXBuildFile section** (CharacterPreferenceRepository 줄 뒤):
```
A1C0F1B00000000000000025 /* HapticsManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1C0F1A00000000000000025 /* HapticsManager.swift */; };
```

**(2) PBXFileReference section** (CharacterPreferenceRepository 줄 뒤):
```
A1C0F1A00000000000000025 /* HapticsManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = HapticsManager.swift; sourceTree = "<group>"; };
```

**(3) 신규 PBXGroup `Managers`** (Protocols 그룹 직후):
```
A1C0F2000000000000000017 /* Managers */ = {
    isa = PBXGroup;
    children = (
        A1C0F1A00000000000000025 /* HapticsManager.swift */,
    );
    name = Managers;
    path = "GanhoMusic Shared/Managers";
    sourceTree = "<group>";
};
```

**(4) 루트 mainGroup children에 Managers 추가** (Protocols 뒤, GanhoMusic iOS 앞):
```
A1C0F1F00000000000000016 /* Protocols */,
A1C0F2000000000000000017 /* Managers */,   ← 신규 줄
C75D462B2FA627C20016BB86 /* GanhoMusic iOS */,
```

**(5) iOS PBXSourcesBuildPhase files 목록에 추가** (CharacterCardNode.swift 또는 마지막 줄 뒤):
```
A1C0F1B00000000000000025 /* HapticsManager.swift in Sources */,
```
**주의**: macOS/tvOS Sources phase는 비어있는 그대로 — iOS 타겟만 정식 지원.

### Membership Exception
- HapticsManager는 PBXFileSystemSynchronizedBuildFileExceptionSet에 **추가하지 않는다**. 기존 HighScoreRepository/ScoreSystem 등 명시 등록 파일도 exception에 없는데 정상 빌드 — Xcode 26.x에서 `path` 명시된 PBXGroup에 등록되면 sync 중복이 자동 회피되는 것으로 보임.

## 검증 시나리오

**(a) 빌드 클린**: `⌘B` 에러 0, 경고 0. `Cannot find 'HapticsManager' in scope` 미발생.

**(b) 시뮬레이터 noop**: iPhone 시뮬레이터 실행 → 게임 진행 → 크래시 없음, 콘솔 에러 0. 진동은 시뮬레이터가 무시 (예상 동작).

**(c) 실기기 라이트 햅틱**: 실기기에서 노트 1개 수집 시 가벼운 톡 1회. 연속 수집 시 톡톡톡 (콤보 윈도우 내 끊김 없이).

**(d) 실기기 헤비 햅틱**: 게임오버 3경로 각각 — (i) 45초 만료 (ii) 적 접촉 (iii) F 피격. 셋 모두 묵직한 한 방 1회.

**(e) 멱등 가드 회귀**: F 피격과 적 접촉이 동시 발생 시 heavy 햅틱 *2회 트리거 안 됨*. ResultScene이 1회만 표시됨.

**(f) Phase 4 회귀**: AIRFORCE 이스터에그(StoneGuard 첫 접촉) 발동 시 heavy 햅틱 *트리거 안 됨* (`triggerAirforceEasterEgg`는 endGame 미호출). 비행기/오버레이/폭탄/도주/F 재스폰 모두 Phase 4-7 동작 그대로.

**(g) Phase 5 회귀**: 캐릭터 선택 → 색·속도·HUD 우상단 이름·ResultScene characterName 모두 정상. 노트 수집 시 light 햅틱(캐릭터 무관 동일).

**(h) Out of Scope 회귀**: `git diff`는 `Managers/HapticsManager.swift`(신규) + `GameScene.swift`(3줄) + `project.pbxproj`(5곳)만.

## 학습 가치 (Spring 비유)

| 측면 | Repository (Phase 5에서 3회 등장) | Manager (Phase 6-1 첫 등장) |
|---|---|---|
| Spring 대응 | `@Repository` + Mapper | `@Service` (도메인 외 부수효과) |
| 책임 | 영속화 (UserDefaults 읽기/쓰기) | 부수효과 (햅틱 트리거) |
| 함수 반환 | `current` (Read) / `record` (Write + return) | `light()` / `heavy()` (Void) |
| 호출자 관심 | "데이터가 잘 저장됐나?" | "사용자가 느꼈나?" |
| 폴더 | `Repositories/` | `Managers/` |
| 호출 빈도 | 게임 끝날 때 1회 | 매 노트 수집(빈번) + 게임오버(1회) |
| init 비용 | 거의 0 | `prepare()` 워밍 비용 있음 |
| DI 여지 | 본 sprint 채택 | 본 sprint 미채택 (직접 인스턴스) |

**핵심 인사이트**: Spring `@Service` 빈은 "행위(behavior)"를 캡슐화하고, `@Repository`는 "상태(state)"를 캡슐화한다. HapticsManager는 행위(트리거), HighScoreRepository는 상태(저장된 점수). 둘 다 "GameScene을 얇게 유지"라는 동일 목표를 다른 각도에서 달성.

## 주의사항

1. **강제 언래핑 금지**: `UIImpactFeedbackGenerator` 초기화 실패 안 함 → 옵셔널 처리 불필요. `init?`/`!` 도입 금지.
2. **Timer 금지**: 햅틱 지연이 필요해도 `SKAction.wait`. 본 sprint는 지연 없음.
3. **매직 넘버 금지**: 강도는 `.light` / `.heavy` enum case로 충분. `GameConfig` 새 상수 0.
4. **클로저 self 캡처**: `onNoteCollected`는 이미 `[weak self]` 캡처. `self.haptics.light()` 형태 그대로.
5. **pbxproj 편집 위험**: 텍스트 편집 실수 시 Xcode가 프로젝트를 못 연다. 반드시 ID grep 충돌 확인 + 들여쓰기(탭) 보존 + 콤마/세미콜론 정확.
6. **import**: HapticsManager는 `import UIKit`. GameScene은 `import SpriteKit`(UIKit 추이 import)이라 추가 import 불필요.
7. **macOS/tvOS 타겟**: `UIImpactFeedbackGenerator`는 iOS 전용. macOS/tvOS Sources phase가 비어있어 안전.
8. **GameScene 본체 0줄 영역**: init / required init? / newGameScene / didMove / didChangeSize / layoutDPad / layoutHUD / update / triggerAirforceEasterEgg / endGame의 멱등 가드 외 부분 / configureContactRouter의 onEnemyHit/onProjectileHitPlayer/onProjectileHitWall/onStoneGuardContact 4개 콜백. 만지면 P0.
9. **endGame 안 햅틱 위치 엄수**: `gameState = .gameOver` *직후* 1줄. 그 앞이면 가드 회피로 중복 트리거 위험.
