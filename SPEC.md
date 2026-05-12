# Phase 6-3 — AVAudioPlayer 인프라 + 시스템 사운드 graceful 폴백

## 개요
Phase 6-2의 `AudioServicesPlaySystemSound` 위에 `AVAudioPlayer` 레이어를 한 겹 얹는다. Bundle에 자작 음원(`note.wav` / `gameover.wav`)이 있으면 AVAudioPlayer 경로로 재생, 없으면 기존 시스템 사운드 경로로 자동 폴백. 사용자가 FL Studio로 효과음을 만들어 Xcode에 추가하기만 하면 코드 변경 없이 다음 빌드부터 활성화된다.

## 변경 유형
**인프라 (AVFoundation 도입)** — 게임 체감 변화는 현재 빌드에서 0 (음원 파일이 없어 시스템 사운드 폴백 그대로). 사용자 자작 음원 추가 시점부터 효과음 톤이 시스템 → 자작으로 자동 전환.

## 게임 경험 의도
1. 인프라 학습 — AVFoundation / AVAudioSession / Bundle 리소스 로딩 패턴의 첫 등장. Spring `@Resource` + `ResourceLoader` 비유로 이해.
2. 회귀 0 — 음원 부재 상태에서도 6-2 시스템 사운드 동작이 1:1 보존.
3. 미래 활성화 경로 사전 설치 — 사용자가 자작 효과음을 Resources/Sounds/에 떨어뜨리는 순간 게임 톤이 "한 사람이 만든 것"으로 즉시 격상.

## Sprint 범위 계약

### 허용
- `AudioManager.swift` 단일 파일 확장
- `Resources/README.md` 갱신 + 신규 `Resources/Sounds/README.md`
- GameScene.swift의 `audio.play(...)` 두 호출은 **시그니처/순서/위치 모두 무변경**

### 금지 (위반 시 P0)
- BGM 도입
- `HapticsManager` 변경
- `GameScene` / `GameScene+Setup` / `TitleScene` / `ResultScene` 변경
- 모든 Nodes / Systems / Repositories / Models / Protocols / Config 변경
- 음원 파일 *실제 추가* (사용자 별도 작업)
- pbxproj 변경
- 새 SFX 케이스 추가 (콤보/AIRFORCE는 별도 sprint)
- `SFX.systemSoundID` 변경 (그대로 — 폴백 경로)
- AVAudioSession `.playback` 사용
- AVAudioPlayer delegate 사용
- 강제 언래핑
- `GameConfig` 새 상수
- `CaseIterable` 채택 (enum 본체 변경 회피)
- macOS / tvOS / Test 코드

### 판단 기준
"이 변경이 없으면 'Bundle에 자작 음원이 있을 때 AVAudioPlayer로 재생, 없으면 시스템 사운드로 폴백' 동작이 성립하는가?" → NO만 In Scope.

## 7 핵심 결정 포인트

| # | 결정 | 확정 답 | 근거 |
|---|---|---|---|
| 1 | AVAudioSession 카테고리 | `.ambient` | 효과음 정책 — 무음 모드 따름, 다른 앱 사운드 안 끊음. `.playback`은 BGM sprint. |
| 2 | 파일 확장자 | `.wav` 고정 | PCM 무압축, 100~500ms 효과음에 디코딩 비용 ~0. |
| 3 | AVAudioPlayer 캐시 시점 | `init()` 1회 + `prepareToPlay()` | 첫 호출 시 디코딩 지연 차단. lazy는 첫 음표 충돌 프레임에 hiccup 위험. |
| 4 | 연속 재생 처리 | `currentTime = 0; play()` | 같은 효과음 1프레임 내 다중 호출 시 항상 처음부터. |
| 5 | AudioSession 활성화 | `setCategory(.ambient)`만, `setActive(true)` 미호출 | `.ambient`는 자동 활성화. 실패는 `try?`로 graceful. |
| 6 | `fileName` 미일치 케이스 | `var fileName: String?` 옵셔널 | nil이면 시스템 사운드만. 향후 시스템 사운드 전용 SFX 대비. |
| 7 | Resources/Sounds/ 폴더 | README만 신규 (빈 폴더 표식) | Xcode 그룹은 drag-drop 시 자동 생성. |

## 변경 범위

### 수정할 파일
- `GanhoMusic Shared/Managers/AudioManager.swift`
- `GanhoMusic Shared/Resources/README.md`

### 추가할 파일
- `GanhoMusic Shared/Resources/Sounds/README.md`

## 기능 상세

### 기능 1: `import AVFoundation` 추가
```swift
import AVFoundation
import AudioToolbox   // Phase 6-2 폴백 경로 — 그대로 유지
```

### 기능 2: `SFX.fileName` computed property
**위치**: `enum SFX` 내부, `systemSoundID` 바로 위.

```swift
/// Bundle에 실제 음원 파일이 있을 때만 AVAudioPlayer 경로로 재생.
/// nil이면 systemSoundID 폴백만 사용. 확장자는 .wav로 고정.
var fileName: String? {
    switch self {
    case .noteCollected: return "note"
    case .gameOver:      return "gameover"
    }
}
```

### 기능 3: 플레이어 캐시 + AVAudioSession 설정 (init)
**위치**: `final class AudioManager` 내부, `// MARK: - SFX` 아래 / `// MARK: - Play` 위.

```swift
// MARK: - Players Cache
/// init 시점에 1회 채워지는 AVAudioPlayer 캐시. play 시 O(1) 조회.
/// Bundle에 음원 파일이 없는 SFX 케이스는 키 자체가 없음 → play에서 폴백 분기.
private var players: [SFX: AVAudioPlayer] = [:]

// MARK: - Init
/// AVAudioSession을 .ambient로 1회 설정하고, SFX 전 케이스에 대해 Bundle 음원 로딩을 시도한다.
/// 실패는 전부 graceful — 어떤 단계가 실패해도 systemSoundID 폴백 경로는 항상 살아 있다.
init() {
    // 1) AudioSession 카테고리 — .ambient: 무음모드 따름, 다른 앱 사운드 안 끊음 (효과음 정책).
    //    setActive(true)는 호출 안 함 — .ambient는 시스템이 자동 활성화. try?로 graceful.
    try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [])

    // 2) SFX 전 케이스 순회 — fileName이 있고 Bundle에 실제 .wav가 있을 때만 캐시 채움.
    //    파일이 없으면 폴백 경로로 자연 전환 (예외 무시).
    let allCases: [SFX] = [.noteCollected, .gameOver]
    for sfx in allCases {
        guard let name = sfx.fileName,
              let url = Bundle.main.url(forResource: name, withExtension: "wav") else { continue }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { continue }
        player.prepareToPlay()
        players[sfx] = player
    }
}
```

### 기능 4: `play(_:)` 폴백 분기
**위치**: 기존 `func play(_:)` 본문 교체.

```swift
// MARK: - Play
/// 캐시 히트 → AVAudioPlayer (자작 음원). 미스 → AudioServicesPlaySystemSound (Phase 6-2 폴백).
/// 동일 SFX의 1프레임 내 연속 호출은 currentTime=0 리셋 후 재시작.
func play(_ sfx: SFX) {
    if let player = players[sfx] {
        player.currentTime = 0
        player.play()
        return
    }
    AudioServicesPlaySystemSound(sfx.systemSoundID)
}
```

### 기능 5: Resources/README.md 갱신
- "향후 들어올 자산" 표의 `Sounds/` 행을 Phase 6-3 컨텍스트로 갱신
- 신규 H2 섹션 "## Sounds/ — 자작 효과음 활성화 절차" 추가
  - 권장 포맷: `.wav` (PCM 16bit 44.1kHz), 길이 100~500ms
  - 파일명 고정: `note.wav`, `gameover.wav`
  - Xcode UI 절차: 좌측 네비게이터 `Resources/Sounds/` 그룹 위로 drag → "Copy items if needed" ✓ → "Add to targets: GanhoMusic iOS" ✓
  - 빌드 후 자동 활성화. 미추가 시 시스템 사운드 폴백 그대로.

### 기능 6: Resources/Sounds/README.md 신규
- 빈 디렉터리 표식 + 빠른 가이드 (3줄 이내)
- 상세 가이드는 상위 `Resources/README.md` 참조

## 검증 시나리오

| # | 시나리오 | 기대 결과 |
|---|---|---|
| (a) | 빌드 — 음원 파일 0개 상태 | BUILD SUCCEEDED. AVFoundation 자동 링크. 경고 0~사소. |
| (b) | 폴백 동작 — 시뮬레이터 노트/게임오버 | 6-2와 동일한 Tink/Boop 시스템 사운드. AVAudioPlayer 캐시는 비어 있고 play가 systemSoundID 분기로 흐름. |
| (c) | 6-2 회귀 0 | GameScene.swift 변경 0건. audio.play 두 호출 그대로. |
| (d) | GameScene API 무변경 | `func play(_ sfx: SFX)` 시그니처 동일. 호출부 컴파일 차이 0. |
| (e) | 강제 언래핑 0 | AudioManager.swift 전체 `!` grep 0건. try? / guard let / 옵셔널 체이닝만. |
| (f) | AudioSession 카테고리 | `.ambient` (mode `.default`, options 빈 셋). `.playback` 0건. setActive(true) 0건. |
| (g) | Resources README | 두 README 모두 자작 음원 추가 절차 자명. drag-drop 체크박스 명시. |
| (h) | 미래 활성화 경로 | 사용자가 note.wav 1개만 추가 → 음표 수집만 자작 음원, 게임오버는 시스템 사운드. 부분 활성화 정상. |

## 학습 가치

### AVFoundation 첫 등장 — Spring 비유

| Swift / iOS | Spring / Java |
|---|---|
| `import AVFoundation` | `import org.springframework.core.io.*` |
| `AVAudioSession.setCategory(.ambient)` | 앱 전체 오디오 정책 설정. Spring `@Configuration` 빈 등록 정책과 동일 위계. |
| `Bundle.main.url(forResource: "note", withExtension: "wav")` | `ResourceLoader.getResource("classpath:sounds/note.wav")` |
| `AVAudioPlayer(contentsOf: url)` | `new AudioInputStream(resource.getInputStream())` |
| `players: [SFX: AVAudioPlayer]` 캐시 | Spring `@Cacheable` 패턴 — init 워밍 후 매번 재사용 |
| `try? ... else continue` | `try { ... } catch (Exception ignored) { continue; }` graceful degradation |

### graceful fallback 패턴
- "이상적 경로"(AVAudioPlayer)가 실패해도 "보장 경로"(systemSoundID)가 항상 살아 있다.
- Spring `@CircuitBreaker(fallbackMethod = ...)`와 발상이 같음 — 다만 여기서는 *부재*가 폴백 트리거.

### 캐시 전략 — eager vs lazy
- 채택: eager (init 1회). 첫 호출 지연 회피.
- lazy 거부: 첫 호출 시 디코딩 → 16ms 예산 깨고 끊김 발생 위험.

### "변경 0건"의 의미
- GameScene의 `audio.play(...)` 두 호출이 변경되지 않는다는 사실 자체가 *추상화의 성공*. Phase 6-2에서 시그니처를 신중히 정해둔 덕. Spring `@Service` 인터페이스 안정성과 동일.

## 주의사항

- **`import AudioToolbox` 유지 필수**: 폴백 경로의 `AudioServicesPlaySystemSound` 심볼.
- **`try?` 우선**: `try!` / do-catch 부적합. 시뮬레이터/특정 디바이스에서 setCategory 실패 사례 있음.
- **`prepareToPlay()` 누락 금지**: 첫 `play()` 시 디코딩 비용이 메인 스레드에 발생 가능.
- **`currentTime = 0` 위치**: `play()` 호출 *전*.
- **`setActive(true)` 호출 금지**: `.ambient`는 자동 활성화.
- **`CaseIterable` 채택 회피**: enum 본체 변경 회피. 명시적 `[SFX]` 배열 사용.
- **새 SFX 케이스 추가 금지**: 콤보/AIRFORCE는 별도 sprint.
- **음원 파일 *실제 추가* 금지**: 본 sprint는 인프라까지.
- **AVAudioPlayer는 stored property로 강참조 유지**: `players` 딕셔너리가 그 역할. 로컬 변수면 ARC 즉시 해제 → 재생 중단.
