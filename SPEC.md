# Phase 6-2 — AudioManager (시스템 사운드 효과음)

## 개요
Phase 6-1에서 도입한 `HapticsManager` 패턴을 *두 번째 적용*하여 **사운드 손맛**을 추가한다. 외부 음원 에셋이 0건이므로 `AudioToolbox`의 `AudioServicesPlaySystemSound`를 이용해 iOS 내장 시스템 사운드 2종을 발화한다. 햅틱과 동일한 2지점(노트 수집 / 게임오버)에서 트리거하여 멀티모달(촉각+청각) 피드백을 완성한다.

## 변경 유형
**게임플레이 + UX 폴리싱** (햅틱과 동급, 게임 규칙 변화는 0건이지만 플레이어가 인식하는 피드백 채널이 늘어남)

## 게임 경험 의도
1. 노트 1개를 먹는 순간, 손가락에는 `light` 톡(햅틱) + 귀에는 짧은 "틱"(시스템 사운드 1057 Tink) — 동일 사건이 두 감각으로 동시에 도착하여 "수집했다"라는 확신이 강해진다.
2. 게임오버 순간엔 `heavy` 둔탁한 충격 + 묵직한 "두웅"(시스템 사운드 1073 Boop) — 종료의 무게감이 멀티모달로 증폭된다.
3. BGM/자작 음원이 등장하기 전(별도 sprint)에도, 작은 시스템 사운드만으로 "살아있는 게임"의 첫 인상을 만든다.

## Sprint 범위 계약

### 허용
- `Managers/AudioManager.swift` 신설 (enum SFX + computed `systemSoundID` + `play(_:)`)
- `GameScene.swift` 시스템 섹션에 `let audio = AudioManager()` 1줄
- `GameScene.swift` `onNoteCollected` 콜백 안에 `self.audio.play(.noteCollected)` 1줄
- `GameScene.swift` `endGame()` 안 멱등 가드 통과 직후 `audio.play(.gameOver)` 1줄
- `project.pbxproj` 4곳 등록 (BuildFile / FileReference / Managers PBXGroup children / iOS Sources phase)

### 금지 (위반 시 P0)
- AVAudioPlayer / BGM / 음원 에셋 도입
- 음소거 옵션 / Repository 영속화
- SFX 케이스 추가(`.combo`, `.airforce`, `.tap` 등)
- `GameConfig` 새 상수 (시스템 사운드 ID는 enum 내부 — 예외 명문화)
- `HapticsManager` 변경
- `GameScene.swift`의 다른 부분 변경 (init/factory/didMove/update/triggerAirforceEasterEgg/configureContactRouter의 다른 4 콜백/endGame의 멱등 가드+state 전환 외 부분)
- `GameScene+Setup` / `TitleScene` / `ResultScene` / Nodes / Systems / Repositories / Models / Protocols / Config 변경
- macOS / tvOS / Test 코드

### 판단 기준
"이 변경이 없으면 *음표 수집 시 시스템 사운드 + 게임오버 시 다른 시스템 사운드가 발화된다*가 동작하는가?" → NO만 In Scope.

## 5 핵심 결정 포인트

### 결정 1 — 시스템 사운드 ID 2개 확정
| SFX 케이스 | 시스템 사운드 ID | 이름 | 사유 |
|---|---|---|---|
| `.noteCollected` | **1057** | Tink | 매우 짧음(~80ms), 밝은 메탈릭. 음표(♪) 이미지와 결, 연속 발화 누적 피로 적음. |
| `.gameOver` | **1073** | Boop | 묵직한 종료감, ~200ms로 게임오버의 짧은 정지에 맞음. |

### 결정 2 — enum SFX vs 단순 메서드
**enum 전략 채택.** Phase 5-3 `CharacterID.playerSpeedMultiplier`의 switch self → computed property 패턴 재활용. 호출부가 `audio.play(.noteCollected)`로 의도 응축. 향후 콤보/이스터에그 추가 시 케이스 1줄 + switch 1줄만 늘면 됨(OCP).

### 결정 3 — 햅틱과의 트리거 순서
**햅틱 → 사운드** (한 프레임 내라 실제 체감 차이 0이지만 의미상 순서 고정).
- 햅틱: 하드웨어 진동(즉각·물리적)
- 사운드: OS 오디오 큐 경유(논리적 지연 1~2ms)
- 코드 가독성: 촉각 → 청각 흐름이 자연스러움

### 결정 4 — pbxproj 작업 명세 (4곳)
ID `...0026` 사용 (HapticsManager `...0025` 다음). grep 충돌 0건 확인 후 진행.

| 구역 | 라인 근처 | 추가 라인 |
|---|---|---|
| (a) PBXBuildFile | 30 (HapticsManager 다음) | `A1C0F1B00000000000000026 /* AudioManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1C0F1A00000000000000026 /* AudioManager.swift */; };` |
| (b) PBXFileReference | 60 (HapticsManager 다음) | `A1C0F1A00000000000000026 /* AudioManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AudioManager.swift; sourceTree = "<group>"; };` |
| (c) Managers PBXGroup children | 266 (HapticsManager 다음) | `A1C0F1A00000000000000026 /* AudioManager.swift */,` |
| (d) iOS Sources build phase | 467 (HapticsManager 다음) | `A1C0F1B00000000000000026 /* AudioManager.swift in Sources */,` |

**검증**: 작업 후 `grep "AudioManager" project.pbxproj` → 정확히 4건. macOS/tvOS Sources phase는 빈 채로 유지.

### 결정 5 — 시스템 사운드 매직 넘버 정책
**`1057`/`1073`은 GameConfig로 분리하지 않고 enum 내부 switch에 직접 둔다.** 사유:
1. Apple 시스템 상수라는 외부 도메인 값 — 게임 튜닝 파라미터와 성질이 다름
2. 사용처가 단일(SFX 케이스 1:1) — GameConfig 분리 시 간접 참조만 늘어남
3. enum이 이미 명명 컨테이너 — `SFX.noteCollected.systemSoundID`로 의미 충분
4. swift-rules §7 매직 넘버 정책은 게임 튜닝 상수 대상, 외부 API 상수는 자기 도메인 타입 내부 권장

## 변경 범위

### 추가할 파일
- `GanhoMusic/GanhoMusic Shared/Managers/AudioManager.swift`

### 수정할 파일
- `GanhoMusic/GanhoMusic Shared/GameScene.swift` (3줄)
- `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj` (4지점)

## 기능 상세

### 기능 1: AudioManager 신규 파일

```swift
//
//  AudioManager.swift
//  GanhoMusic Shared
//
//  Phase 6-2 · 시스템 사운드 효과음 캡슐화 (Manager 패턴 두 번째 적용)
//

import AudioToolbox

/// iOS 시스템 사운드를 캡슐화한 매니저. AVAudioPlayer / 외부 음원 도입 전 임시 보강.
/// Phase 5-3 CharacterID.playerSpeedMultiplier의 enum + computed property 전략을 재사용.
/// Spring 비유: HapticsManager와 동급 @Service 빈. 둘 다 side-effect 책임을 가진다.
final class AudioManager {

    // MARK: - SFX
    /// 게임 내 효과음 종류. 향후 콤보/이스터에그 등 케이스 추가 시 systemSoundID switch만 늘리면 됨(OCP).
    enum SFX {
        case noteCollected   // 노트 수집 — 짧고 밝은 톤
        case gameOver        // 게임 종료 — 묵직한 종료감

        /// Apple 내장 시스템 사운드 ID. 1000~1500 범위가 안전.
        /// GameConfig로 분리하지 않는 이유: Apple 시스템 상수라는 외부 도메인 값이며,
        /// SFX 케이스와 1:1 매핑이므로 enum 내부에 두는 게 응집도 높음.
        var systemSoundID: SystemSoundID {
            switch self {
            case .noteCollected: return 1057   // Tink — 짧고 밝은 메탈릭
            case .gameOver:      return 1073   // Boop — 묵직한 종료감
            }
            // exhaustive switch — default 없음. 케이스 추가 시 컴파일러가 강제로 매핑 추가 요구.
        }
    }

    // MARK: - Play
    /// 시스템 사운드는 즉시 발화 — HapticsManager의 prepare() 워밍 불필요.
    /// AudioServicesPlaySystemSound는 thread-safe하며 비동기로 사운드 큐에 push.
    func play(_ sfx: SFX) {
        AudioServicesPlaySystemSound(sfx.systemSoundID)
    }
}
```

### 기능 2: GameScene에 audio 시스템 1줄 추가

**위치**: Properties 시스템 섹션, `let haptics = HapticsManager()` 다음 줄.

```swift
let haptics = HapticsManager()              // Phase 6-1 — 손맛 강화 (Manager 패턴 첫 등장)
let audio   = AudioManager()                // Phase 6-2 — 사운드 손맛 (Manager 패턴 두 번째 적용)
```

### 기능 3: 노트 수집 시 사운드 트리거

**위치**: `onNoteCollected` 콜백 안, `self.haptics.light()` 다음 줄.

```swift
contactRouter.onNoteCollected = { [weak self] note in
    guard let self = self else { return }
    self.scoreSystem.recordNoteHit(at: self.lastUpdateTime)
    self.haptics.light()                  // Phase 6-1 — 수집 손맛
    self.audio.play(.noteCollected)       // Phase 6-2 — 수집 사운드 (햅틱 → 사운드 순서)
    note.run(.removeFromParent())
}
```

### 기능 4: 게임오버 시 사운드 트리거

**위치**: `endGame()` 안, `haptics.heavy()` 다음 줄 (멱등 가드 통과 후).

```swift
private func endGame() {
    if gameState == .gameOver { return }   // 멱등 가드
    gameState = .gameOver
    haptics.heavy()                         // Phase 6-1
    audio.play(.gameOver)                   // Phase 6-2 — heavy 직후, spawnSystem.stop() 전
    spawnSystem.stop()
    // ... 이하 기존 코드 그대로
}
```

## 검증 시나리오

### (a) 빌드 검증
- Clean Build → 에러/경고 0건
- exhaustive switch 인식 확인 (default 없음)

### (b) 노트 수집 사운드 — 시뮬레이터
- Mac 스피커로 Tink(짧고 밝음) 발화
- 1초 안에 노트 3개 연속 수집 → 사운드 3회 모두 발화

### (c) 게임오버 사운드 3경로
- 시간 만료 / 적 접촉 / F 피격 모두 Boop 1회 발화
- 멱등 가드 통과 직후라 동시 트리거에도 1회만

### (d) 실기기 검증
- 무음 모드 ON → 시스템 사운드 차단 (Apple 정책 — 의도된 동작)
- 무음 모드 OFF → 정상 발화
- 햅틱 + 사운드 동기화 확인

### (e) Phase 6-1 회귀
- `HapticsManager.swift` 0줄 변경
- 햅틱 트리거 라인 그대로

### (f) Phase 1~5 회귀
- 게임 로직(이동/스폰/수집/추적/F/AIRFORCE) 모두 정상
- TitleScene/ResultScene 정상

### (g) 동시 발화 타이밍
- 같은 프레임 내 haptics.light() → audio.play() 연속 실행
- 두 호출 모두 비동기/즉시 반환 → 게임 루프 블로킹 0

### (h) 멱등 / 메모리
- endGame 2회 호출 시 사운드도 1회
- AudioManager 인스턴스 ARC 자동 해제
- 새 게임 시작 시 새 인스턴스

## 학습 가치

### 1. Manager 패턴 두 번째 적용 — 패턴 내면화
6-1 첫 등장 + 6-2 반복으로 "side-effect = Manager" 멘탈 모델 굳히기. Spring `EmailService` + `SmsService` 둘 다 같은 자리에 같은 형태로 들어간다는 공간적 반복.

### 2. enum + computed property 전략 (Phase 5-3 재활용)
`SFX.noteCollected.systemSoundID`는 `CharacterID.kim.playerSpeedMultiplier`와 같은 모양. 데이터(케이스)와 행동(매핑)의 응집. exhaustive switch는 Java sealed class 안전망.

### 3. 매직 넘버 정책의 미묘함
1057/1073은 Apple 외부 도메인 상수라 GameConfig로 빼면 어색. swift-rules §7은 게임 튜닝 상수가 대상. 외부 시스템 ID/URL/HTTP 코드 등은 자기 도메인 타입 내부에 두는 게 일관.

### 4. 멀티모달 피드백 동기화
촉각(햅틱) + 청각(사운드) 1프레임 내 동기화 = 플레이어 뇌에 "동시" 사건으로 인식. 코드상 순서(촉각 → 청각)는 후속 sprint에서도 의도 보존.

## 주의사항

1. **무음 모드 = OS 정책**: iPhone 무음 스위치는 시스템 사운드도 차단 (Apple 의도). 본 sprint 범위 외. 향후 BGM은 `AVAudioSession.Category.playback`으로 우회 가능.
2. **import**: `import AudioToolbox` 1줄. 조건부 import 불필요.
3. **pbxproj ID 충돌**: 작업 전 `grep "00000000000026"` 0건 확인. 4지점 정확히 삽입.
4. **`final class` 유지**: 상속 의도 없음 명시.
5. **`weak self` 불필요**: AudioManager 자체 클로저 캡처 없음. 기존 `[weak self]` 가드 안쪽이라 별도 처리 불필요.
6. **default 절대 금지**: SFX switch에 default 추가하면 케이스 추가 시 컴파일러가 누락을 잡지 못함. exhaustive 유지가 Phase 5-3 패턴의 핵심.
7. **GameScene 다른 부분 0줄**: init/didMove/update/didChangeSize/layoutDPad/layoutHUD/triggerAirforceEasterEgg/configureContactRouter의 다른 4 콜백/endGame의 멱등 가드+state 전환 외 부분 모두 frozen.
