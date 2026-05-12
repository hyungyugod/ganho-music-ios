# Phase 6-4 — BGMPlayer (배경음악 인프라)

## 개요
자작 BGM 파일(`bgm.m4a`)이 Bundle에 존재하면 게임 중 무한 루프로 재생하고, 없으면 noop. Phase 6-3 `AudioManager`의 graceful fallback 패턴을 그대로 답습하되, BGM 전용 `AVAudioSession` 카테고리(`.playback` + `.mixWithOthers`)를 음원이 있을 때에만 덮어쓴다. 본 sprint는 인프라 신설이라 체감 변화는 0이며, 사용자가 FL Studio로 만든 BGM 파일을 `Resources/Sounds/bgm.m4a`로 드롭하는 순간 다음 빌드부터 자동 활성화된다.

## 변경 유형
**인프라** (AVAudioSession 정책 분리). 음원 부재 시 6-3 `.ambient` 정책 그대로 유지 → 회귀 0.

## 게임 경험 의도
사용자가 게임을 시작하면 자기가 작곡한 BGM이 무한 루프로 흐르고, 게임이 끝나면 멈춘다 — 김간호 세계관의 "병동에서 작곡하던 새벽"을 직접 들려주는 것이 이 sprint의 종착지다. 음원 파일 1개만 끼우면 다음 빌드부터 그 경험이 완성된다. 효과음과의 충돌(.ambient vs .playback)을 미리 정리해, BGM 도입 시 효과음이 죽는 사고를 막는다.

## Sprint 범위 계약

### 허용
- `Managers/BGMPlayer.swift` 신설
- `GameScene.swift` 4지점 추가 (헤더 1 + 시스템 1 + didMove 1 + endGame 1)
- `project.pbxproj` 4곳 등록
- `Resources/README.md`에 BGM 가이드 단락 추가

### 금지 (위반 시 P0)
- 페이드 인/아웃 (별도 sprint)
- 볼륨 조절 / 음소거 옵션 / Repository 영속화
- TitleScene/ResultScene BGM (별도 sprint)
- `AudioManager` 변경 (6-3 그대로)
- `HapticsManager` 변경
- 새 SFX 케이스 추가
- `GameScene` 다른 부분 변경 (init/factory/update/triggerAirforceEasterEgg/configureContactRouter/layout*/endGame 멱등 가드+state 전환+haptics/audio 호출 외 부분)
- `GameScene+Setup` / `TitleScene` / `ResultScene` 변경
- 모든 Nodes / Systems / Repositories / Models / Protocols / Config 변경 (GameConfig 새 상수 0)
- 음원 파일 *실제 추가* (사용자 작업)
- BGM delegate / 재생 완료 콜백
- `setActive(true)` 명시 호출
- 강제 언래핑
- `Resources/Sounds/README.md` 변경 (그 파일은 효과음 전용)
- macOS / tvOS / Test 코드

### 판단 기준
"이 변경이 없으면 'Bundle에 bgm.m4a가 있을 때 게임 중 무한 루프 BGM 재생, 없으면 회귀 0'이 동작하는가?" → NO만 In Scope.

## 7 핵심 결정 포인트

### 결정 1. 파일명/확장자 — `bgm.m4a` 확정
BGM은 효과음과 달리 길고 압축이 절실. m4a(AAC)는 iOS 네이티브 디코더라 추가 라이브러리 0, 30~60초 루프가 ~500KB 안쪽. 효과음(wav)과 확장자를 다르게 둬서 의도(길이/압축 정책)가 파일명만으로 드러남.

### 결정 2. AVAudioSession 카테고리 정책
- **음원 부재**: 카테고리 변경 0. 6-3 `.ambient` 유지 → 회귀 0.
- **음원 존재**: `.playback` + `.mixWithOthers`로 덮어쓰기. `AudioManager.init()`이 `BGMPlayer.init()`보다 *먼저* 호출되므로 BGM 정책이 *나중에 덮어쓰는* 구조. 효과음도 같은 컨텍스트에서 발화(사용자가 BGM 듣고 싶으면 효과음도 듣고 싶을 것).

### 결정 3. didMove 호출 위치 — `gameState = .playing` 직후
무거운 setup 중 디코딩 끼임 회피. `.playing` 직후가 "게임 루프 시작 = BGM 시작"으로 의미적 일치.

### 결정 4. endGame 호출 위치 — `audio.play(.gameOver)` 직후 (멱등 가드 안쪽)
순서: haptics → audio.play(.gameOver) → **bgm.stop()** → spawnSystem.stop(). 멱등 가드 안쪽이라 1회 보장.

### 결정 5. 재시작 시 처리 — 별도 처리 불필요
새 GameScene 진입 시 새 BGMPlayer 인스턴스 → 매 진입마다 0초부터. 이전 인스턴스는 ARC 해제.

### 결정 6. `mixWithOthers` 옵션 — 포함
사용자가 Apple Music과 공존. 음악박사 게임이 다른 음악을 강제 차단하면 무례.

### 결정 7. `stop` vs `pause` — `stop()` 채택
의미적 명확성. 매 진입마다 새 인스턴스라 차이 없음. pause는 향후 일시정지 sprint에서 별도.

## 변경 범위

### 추가할 파일
- `GanhoMusic Shared/Managers/BGMPlayer.swift`

### 수정할 파일
- `GanhoMusic Shared/GameScene.swift` (4지점 추가만)
- `GanhoMusic Shared/Resources/README.md` (BGM 단락 추가)
- `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj` (4곳 등록)

## 기능 상세

### 기능 1: BGMPlayer 클래스 신설

```swift
//
//  BGMPlayer.swift
//  GanhoMusic Shared
//
//  Phase 6-4 · 자작 BGM 무한 루프 재생 인프라 (graceful fallback)
//

import AVFoundation

/// 배경음악 재생을 캡슐화한 매니저. Bundle에 bgm.m4a가 있을 때만 활성화.
/// 없으면 player = nil, 모든 메서드 noop. AudioManager(.ambient)와의 카테고리 분리도
/// 음원 존재 여부를 트리거로 함 — 음원 없으면 .ambient 유지(회귀 0).
/// Spring 비유: AudioManager / HapticsManager와 동급의 @Service 빈.
final class BGMPlayer {

    // MARK: - Properties
    /// Bundle에 음원이 있을 때만 채워짐. nil이면 play/stop 모두 noop.
    private var player: AVAudioPlayer?

    // MARK: - Init
    /// bgm.m4a 로딩 시도 → 성공 시 카테고리 .playback + .mixWithOthers로 덮어쓰기 + 무한 루프 설정.
    /// 실패는 전부 graceful (try?) — 어떤 단계가 실패해도 6-3 .ambient 정책이 살아 회귀 0.
    init() {
        // 1) Bundle 음원 탐색. 없으면 player = nil로 끝 — 카테고리 변경 안 함.
        guard let url = Bundle.main.url(forResource: "bgm", withExtension: "m4a") else { return }

        // 2) AVAudioPlayer 생성 시도. 디코딩 실패도 graceful.
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return }

        // 3) 음원 로딩 성공한 *이후에만* 카테고리를 BGM 정책으로 덮어쓴다.
        //    - .playback: 무음모드 무시, 백그라운드 가능
        //    - .mixWithOthers: Apple Music 등 다른 앱 사운드와 동시 재생 허용
        //    - setActive(true) 명시 호출 안 함 — 시스템 자동 처리
        try? AVAudioSession.sharedInstance().setCategory(
            .playback, mode: .default, options: [.mixWithOthers]
        )

        // 4) 무한 루프 + prepareToPlay로 첫 play 지연 최소화.
        p.numberOfLoops = -1
        p.prepareToPlay()
        player = p
    }

    // MARK: - Control
    /// player가 있고 재생 중이 아니면 play. 이미 재생 중이면 noop(중복 호출 안전).
    func play() {
        guard let player = player else { return }
        if player.isPlaying { return }
        player.play()
    }

    /// player가 있으면 stop. 없으면 noop. stop은 재생 위치를 0으로 리셋.
    func stop() {
        guard let player = player else { return }
        player.stop()
    }
}
```

### 기능 2: GameScene 시스템 섹션 1줄

**위치**: `audio` 다음 줄.

```swift
let haptics = HapticsManager()              // Phase 6-1
let audio   = AudioManager()                // Phase 6-2
let bgm     = BGMPlayer()                   // Phase 6-4 — 자작 BGM 무한 루프 (음원 부재 시 noop)
```

### 기능 3: didMove(to:) 1줄

**위치**: `gameState = .playing` *직후*.

```swift
gameState = .playing // playing 전환 후에야 update가 동작
bgm.play()           // Phase 6-4 — playing 전환 직후 BGM 시작 (음원 없으면 noop)
```

### 기능 4: endGame() 1줄

**위치**: `audio.play(.gameOver)` *직후*, `spawnSystem.stop()` *이전*.

```swift
if gameState == .gameOver { return }
gameState = .gameOver
haptics.heavy()
audio.play(.gameOver)
bgm.stop()           // Phase 6-4 — gameOver 사운드와 동시에 BGM 정지 (멱등 가드 안쪽 = 1회 보장)
spawnSystem.stop()
```

### 기능 5: GameScene 헤더 1줄

```swift
//  Phase 6-2 · AudioManager 신설 + 노트 수집/게임오버 사운드 트리거 2지점
//  Phase 6-4 · BGMPlayer 신설 + 게임 시작/종료 시 BGM 재생/정지
//
```

### 기능 6: pbxproj 4곳 등록

권장 ID: `A1C0F1B00000000000000027` (PBXBuildFile) / `A1C0F1A00000000000000027` (PBXFileReference). 충돌 grep 0건 확인.

| # | section | 추가 위치 | 추가 라인 |
|---|---|---|---|
| 1 | PBXBuildFile | line 30 (AudioManager 다음) | `A1C0F1B00000000000000027 /* BGMPlayer.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1C0F1A00000000000000027 /* BGMPlayer.swift */; };` |
| 2 | PBXFileReference | line 61 (AudioManager 다음) | `A1C0F1A00000000000000027 /* BGMPlayer.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = BGMPlayer.swift; sourceTree = "<group>"; };` |
| 3 | Managers PBXGroup children | line 268 (AudioManager 다음) | `A1C0F1A00000000000000027 /* BGMPlayer.swift */,` |
| 4 | iOS Sources phase | line 470 (AudioManager 다음) | `A1C0F1B00000000000000027 /* BGMPlayer.swift in Sources */,` |

> Managers PBXGroup이 이미 있으므로 신규 그룹 0 — children에 1줄 추가만. macOS/tvOS Sources phase는 비어있는 그대로.

### 기능 7: Resources/README.md BGM 단락 추가

기존 "Sounds/ — 자작 효과음 활성화 절차" 섹션 *아래*에 신규 H2 단락 추가:

```markdown
## Sounds/ — 자작 BGM 활성화 절차 (Phase 6-4)

Phase 6-4에서 `BGMPlayer`에 AVAudioPlayer 기반 BGM 인프라가 설치되어 있다.
음원 파일이 Bundle에 있으면 게임 진입 시 무한 루프 재생, 없으면 noop.

### 권장 포맷 (효과음과 다름 — 압축 포맷 사용)
- 확장자: `.m4a` (AAC 압축, iOS 네이티브)
- 길이: 30~60초 (무한 루프되므로 짧고 깔끔한 루프 권장)
- 채널: 스테레오 OK
- 루프 포인트: 시작/끝이 자연스럽게 이어지도록 페이드아웃 제거

### 파일명 (고정)
| 파일명 | 역할 |
|---|---|
| `bgm.m4a` | 게임 진입 시 재생, 게임오버 시 정지 |

### AVAudioSession 카테고리 차이
- 음원 부재: `.ambient` 그대로 (6-3 정책)
- bgm.m4a 추가 후: `.playback` + `.mixWithOthers` 덮어쓰기 → 무음모드 무시 + Apple Music과 동시 재생

### Xcode 추가 절차
효과음과 동일. `Resources/Sounds/`에 drag-drop, Copy items if needed ✓, Add to targets: GanhoMusic iOS ✓.

### 부분 활성화 동작
- `bgm.m4a`만 → BGM 자작, 효과음 시스템 사운드
- `note.wav` + `gameover.wav` + `bgm.m4a` 모두 → 완전 자작 사운드
- 셋 다 없음 → 시스템 사운드만, BGM 무음
```

## 검증 시나리오

### (a) 빌드
- `⌘B` → 에러 0 / 경고 0
- BGMPlayer.swift Sources 빌드 페이즈 등록 확인

### (b) 음원 부재 폴백
- `bgm.m4a` 없음 → BGM 무음, 효과음(Tink/Boop) 정상
- `BGMPlayer.init()` 첫 guard 실패 → player = nil → 카테고리 변경 0 → `.ambient` 유지

### (c) 6-3 회귀
- AudioManager.swift 변경 0 (git diff)
- 효과음 트리거 그대로 동작
- 카테고리 `.ambient` 유지

### (d) Phase 1~5 회귀
- 이동/수집/점수/HUD/적/F/게임오버/ResultScene/캐릭터 선택/AIRFORCE 모두 정상
- endGame 멱등 가드와 ResultScene transition 미접촉

### (e) 멱등 가드
- 시간만료 + F 피격 동시 발생 시 `bgm.stop()` 1회만 호출 (가드 안쪽)
- `audio.play(.gameOver)`와 함께 1회만 실행

### (f) 재시작
- ResultScene → TitleScene → 새 GameScene → BGM 0초부터 재시작
- 이전 BGMPlayer ARC 해제 → 새 인스턴스가 새 AVAudioPlayer 로딩

### (g) mixWithOthers (음원 추가 후 사용자 수동 검증)
- Apple Music 재생 중 → 게임 진입 → 음악 안 끊김 + BGM 겹쳐 재생
- 본 sprint에선 코드에 `.mixWithOthers` 옵션 포함됨만 확인

### (h) 새 SFX 영향
- `note.wav` / `gameover.wav`만 추가 → AudioManager 활성화, BGMPlayer 무관. 카테고리 `.ambient` 유지
- `bgm.m4a`만 추가 → BGM 자작, 효과음 시스템. 카테고리 `.playback`

## 학습 가치

### BGM vs 효과음 라이프사이클
- **효과음**: fire-and-forget. `play()` 후 자가 종료. → Spring `@EventListener` 1회 이벤트.
- **BGM**: 장기 라이프사이클. 무한 루프 + 명시적 stop 필요. → Spring `@Scheduled` 장기 데몬 빈.

### AVAudioSession 카테고리 정책의 본질
- iOS는 시스템 단위 오디오 정책. 카테고리는 앱의 의도 선언.
- `.ambient`: 무음모드 따름, 다른 앱 안 끊음 (효과음 정책)
- `.playback`: 무음모드 무시, 백그라운드 가능 (BGM/음악 앱 정책)
- `.mixWithOthers`: 공존 모드
- → Spring 비유: `@Transactional(propagation = REQUIRES_NEW)` vs `SUPPORTS` 같은 외부 시스템 협상 정책

### Manager 패턴 3연타
6-1 HapticsManager / 6-2 AudioManager / 6-4 BGMPlayer — 셋 다 side-effect 책임 final class. Spring `@Service` 패턴. GameScene은 오케스트레이터로서 인스턴스 3개를 `let`으로 보유하고 트리거 지점에서 호출만. 새 Manager 추가 시 GameScene은 *추가만* 일어남(OCP).

### graceful fallback의 가치
"파일 없으면 noop, 있으면 활성화" 패턴 = 비기술적 워크플로(FL Studio drag-drop)와 기술적 빌드(코드 변경 0) 분리. Spring `@ConditionalOnResource` 비유.

## 주의사항

- **`setActive(true)` 명시 호출 금지**: 카테고리 설정만으로 시스템이 자동 활성화.
- **카테고리 덮어쓰기 순서 의존성**: GameScene의 `let audio` → `let bgm` 순서 유지. Swift는 위에서 아래로 init 실행. bgm이 *나중에* 카테고리를 덮어씀.
- **pbxproj 들여쓰기**: 기존 항목 탭 사용. 스페이스 섞이면 디프 노이즈.
- **macOS / tvOS Sources phase 비어있는 그대로**: iOS 타겟만 등록.
- **강제 언래핑 0**: `guard let url`, `guard let p`, `guard let player` 패턴.
- **Resources/Sounds/README.md 미변경**: 효과음 전용. BGM 안내는 상위 `Resources/README.md`에만.
- **GameConfig 새 상수 0**: `"bgm"` / `"m4a"` / `-1` 모두 매직 넘버 아님 (1곳 등장 / Apple 표준 신호).
- **`print` 디버그 금지**: silent fallback이 본 sprint 정체성.
