# 자체 점검 — Phase 6-3 AVAudioPlayer 폴백 인프라

전략: Case A — 1회차 신규 구현. SPEC.md 설계가 매우 구체적이라 1:1 충실 반영.

---

## 1. 변경 파일 목록 (Swift 1 + 문서 2 = 3개)

| # | 절대경로 | 종류 | 변경 요약 |
|---|---|---|---|
| 1 | `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/affectionate-elion-d0363a/GanhoMusic/GanhoMusic Shared/Managers/AudioManager.swift` | Swift 수정 | `import AVFoundation` 추가, 헤더에 Phase 6-3 라인, `SFX.fileName` computed property 추가 (systemSoundID 위), `// MARK: - Players Cache` + `// MARK: - Init` 신설, `play(_:)` 폴백 분기 |
| 2 | `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/affectionate-elion-d0363a/GanhoMusic/GanhoMusic Shared/Resources/README.md` | 문서 수정 | `Sounds/` 행 갱신 (Phase 6-3 인프라 메모) + 신규 H2 "Sounds/ — 자작 효과음 활성화 절차" 추가 |
| 3 | `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/affectionate-elion-d0363a/GanhoMusic/GanhoMusic Shared/Resources/Sounds/README.md` | 문서 신규 | 빈 디렉터리 표식 + 3줄 가이드 + 상위 README 링크 |

### git status 검증
```
$ git status --short
 M "GanhoMusic Shared/Managers/AudioManager.swift"
 M "GanhoMusic Shared/Resources/README.md"
 M SPEC.md                                              ← Planner 산출물 (Generator 변경 아님)
?? "GanhoMusic Shared/Resources/Sounds/"                ← 신규 폴더 (README.md 1개 포함)
```

Generator 책임 변경: AudioManager.swift(+45) + Resources/README.md(+40) + Sounds/README.md(신규) = **3개**.

### Swift diff 요약 (AudioManager.swift)

```swift
// 헤더에 6-3 라인 1줄 추가
//  Phase 6-3 · AVAudioPlayer 폴백 인프라 (자작 음원 추가 시 자동 활성화)

// import 1줄 추가 (AudioToolbox는 폴백 경로용으로 유지)
import AVFoundation
import AudioToolbox

// SFX에 fileName computed property 추가 (systemSoundID 위, default 없음)
var fileName: String? {
    switch self {
    case .noteCollected: return "note"
    case .gameOver:      return "gameover"
    }
}

// 새 MARK 섹션 2개
// MARK: - Players Cache
private var players: [SFX: AVAudioPlayer] = [:]

// MARK: - Init
init() {
    try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [])
    let allCases: [SFX] = [.noteCollected, .gameOver]
    for sfx in allCases {
        guard let name = sfx.fileName,
              let url = Bundle.main.url(forResource: name, withExtension: "wav") else { continue }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { continue }
        player.prepareToPlay()
        players[sfx] = player
    }
}

// play(_:) 본문 폴백 분기
func play(_ sfx: SFX) {
    if let player = players[sfx] {
        player.currentTime = 0
        player.play()
        return
    }
    AudioServicesPlaySystemSound(sfx.systemSoundID)
}
```

---

## 2. SPEC In Scope 4항목 충족

| # | SPEC 기능 | 구현 상태 | 위치 |
|---|---|---|---|
| 1 | `import AVFoundation` 추가 (AudioToolbox 유지) | 충족 | AudioManager.swift L9-10 |
| 2 | `SFX.fileName` computed property (옵셔널, default 없음) | 충족 | AudioManager.swift L23-29 (systemSoundID 바로 위) |
| 3 | Init + Players Cache (`.ambient` setCategory + Bundle 순회) | 충족 | AudioManager.swift L46-72 |
| 4 | `play(_:)` 폴백 분기 (캐시 히트 → AVAudioPlayer / 미스 → systemSoundID) | 충족 | AudioManager.swift L79-85 |

문서 작업:
- Resources/README.md 표 `Sounds/` 행을 "6-3 인프라 설치 완료" 메모로 갱신
- Resources/README.md "## Sounds/ — 자작 효과음 활성화 절차" H2 섹션 신설 (.wav PCM 16bit 44.1kHz 권장 포맷, note.wav/gameover.wav 파일명 고정, Xcode drag-drop 절차 + "Copy items if needed" ✓ / "Add to targets: GanhoMusic iOS" ✓ 체크박스 명시, 부분 활성화 동작)
- Resources/Sounds/README.md 신규 (3줄 가이드 + 상위 README 참조 링크)

---

## 3. Out of Scope 위반 0건

| 금지 항목 | 위반 여부 | 검증 |
|---|---|---|
| BGM 도입 | 0건 | AVAudioPlayer는 효과음만, `.ambient` 카테고리 |
| `HapticsManager` 변경 | 0건 | git status에 없음 |
| GameScene / GameScene+Setup / TitleScene / ResultScene 변경 | 0건 | git status에 없음. `audio.play(...)` 호출 두 줄 무변경 |
| 모든 Nodes / Systems / Repositories / Models / Protocols / Config 변경 | 0건 | git status에 없음 |
| 음원 파일 *실제 추가* | 0건 | README만 생성, .wav 파일 없음 (사용자 별도 작업) |
| pbxproj 변경 | 0건 | git status에 없음 |
| 새 SFX 케이스 추가 | 0건 | `.noteCollected`, `.gameOver` 그대로 |
| `SFX.systemSoundID` 변경 | 0건 | 1057 Tink / 1073 Boop 그대로 |
| AVAudioSession `.playback` 사용 | 0건 | `.ambient`만 (mode `.default`, options `[]`) |
| AVAudioPlayer delegate 사용 | 0건 | delegate 미할당 |
| 강제 언래핑 (`!`) | 0건 | `grep '!' AudioManager.swift` → 0줄 |
| `GameConfig` 새 상수 | 0건 | GameConfig 미수정 |
| `CaseIterable` 채택 | 0건 | 명시 배열 `let allCases: [SFX] = [.noteCollected, .gameOver]` 사용 |
| macOS / tvOS / Test 코드 | 0건 | iOS 타겟만 |
| `setActive(true)` 호출 | 0건 | `.ambient`는 자동 활성화 |
| `try!` / do-catch | 0건 | `try?`만 사용 |

### 강제 언래핑 0건 검증
```
$ grep -n '!' "GanhoMusic Shared/Managers/AudioManager.swift"
(0줄)
```

---

## 4. 빌드 결과

```
$ xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" \
    -scheme "GanhoMusic iOS" \
    -destination 'generic/platform=iOS Simulator' \
    -configuration Debug build 2>&1 | tail -50
...
** BUILD SUCCEEDED **
```

### 경고/에러 검증
```
$ xcodebuild ... 2>&1 | grep -E "warning:|error:" | grep -v "AppIntents"
(0줄)
```

**음원 파일 0개 상태에서 빌드 통과 확인 완료.** AVFoundation은 시스템 프레임워크이므로 별도 링크 설정 없이 자동 연결됨. arm64 + x86_64 universal binary 정상 생성, CodeSign OK.

(AppIntents `Metadata extraction skipped` 경고는 본 sprint 무관 — Xcode 26.x 환경 잡음.)

---

## 5. 검증 시나리오 (a)~(h) 정적 추적

### (a) 빌드 — 음원 파일 0개 상태 → BUILD SUCCEEDED
- AVFoundation 자동 링크. AudioToolbox 그대로 링크. 경고 0줄.
- `init()` 안 `for sfx in allCases` 루프가 Bundle에서 `note.wav` / `gameover.wav`를 찾지만 둘 다 nil → `continue` → `players` 빈 딕셔너리 상태로 init 종료.

### (b) 폴백 동작 — 시뮬레이터 노트/게임오버 → 6-2와 동일 (Tink/Boop)
- `play(.noteCollected)` 호출 → `if let player = players[.noteCollected]`이 nil (캐시 비어있음) → `if let` 실패 → `AudioServicesPlaySystemSound(1057)` 분기로 흐름 → Tink 발화.
- `play(.gameOver)` 동일 흐름 → 1073 Boop 발화.

### (c) 6-2 회귀 0
- GameScene.swift 변경 0건 (git status에 없음).
- `audio.play(.noteCollected)` / `audio.play(.gameOver)` 호출부 시그니처/순서/위치 모두 무변경.

### (d) GameScene API 무변경
- `func play(_ sfx: SFX)` 시그니처 동일 (파라미터 라벨/타입/리턴값 모두 동일).
- 호출부 컴파일 차이 0.

### (e) 강제 언래핑 0
- AudioManager.swift `grep '!'` 0건 (위 §3 검증 참조).
- 모두 `try?` / `guard let` / `if let`로 처리.

### (f) AudioSession 카테고리
- `.ambient` (mode `.default`, options `[]`). 코드 L48 명시.
- `.playback` 0건. `setActive(true)` 0건.

### (g) Resources README
- Resources/README.md: 표의 `Sounds/` 행 갱신 + 신규 H2 "## Sounds/ — 자작 효과음 활성화 절차" 섹션.
- 절차에 Xcode drag-drop 체크박스 명시: "Copy items if needed" ✓, "Add to targets: GanhoMusic iOS" ✓.
- Resources/Sounds/README.md: 신규. 빈 디렉터리 표식 + 상위 README 링크.

### (h) 미래 활성화 경로 — 부분 활성화
- `init()`의 for 루프가 SFX별로 **독립** 처리. 한 케이스 실패가 다른 케이스에 영향 없음.
- 사용자가 `note.wav` 1개만 추가 → `players[.noteCollected]`만 채워짐, `.gameOver`는 키 부재.
- `play(.noteCollected)` → AVAudioPlayer 경로 (자작 음원).
- `play(.gameOver)` → systemSoundID 경로 (Boop).
- 부분 활성화 정상 동작.

---

## 6. 학습 노트

`/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/affectionate-elion-d0363a/docs/learn/phase-6-3-avaudioplayer-fallback.md` 작성 완료.

### 톤 & 내용 체크
- 중학생 수준 표현 (전문용어 최소화, "준비실" 등 일상 비유) — CLAUDE.md MEMORY 정책 준수
- Spring 비유 3개 명시:
  - `@Resource` ↔ `Bundle.main.url(forResource:withExtension:)`
  - `@PostConstruct` + `@Cacheable` ↔ `init()` eager 캐시 워밍
  - `@CircuitBreaker(fallbackMethod=...)` ↔ `if let ... else { fallback }`
- graceful degradation 2단계 안전망 설명:
  - 단계 1: AudioSession 설정 실패 (`try?`)
  - 단계 2: 파일 로딩 실패 (guard let + continue) → 자연 폴백
- eager vs lazy 캐시 선택 이유 (첫 호출 16ms 끊김 방지)
- `.ambient` vs `.playback` 비교표 (효과음 정책 vs BGM 정책)
- `try?` Swift 한 글자 폴백 패턴 (Java `catch (Exception ignored)`와 매핑)
- `CaseIterable` 미채택 의도 설명 (enum 본체 변경 회피 + 명시 의도 노출)
- "audio.play(...) 두 줄 무변경" = 추상화 경계 안정성 강조
- 게임 출신 톤(자전적 경험) 보존 — "사용자가 작곡할 시간이 1시간 생겼다"

---

## 7. Swift / SpriteKit 패턴 준수

### Swift 패턴
- 강제 언래핑 미사용: 준수 (0건)
- guard let / if let 옵셔널 처리: 준수 (`guard let name = sfx.fileName`, `guard let url`, `guard let player`, `if let player = players[sfx]`)
- MARK 섹션 구분: 준수 (`// MARK: - SFX`, `// MARK: - Players Cache`, `// MARK: - Init`, `// MARK: - Play`)
- GameConfig 새 상수: 해당 없음 (SPEC 금지). 모든 상수는 SFX enum 내부 또는 init() 안 명시 배열로.
- weak self 캡처: 해당 없음 (AudioManager 내 클로저 0건)
- final class: 준수 (`final class AudioManager`)
- enum exhaustive switch (default 없음): 준수 (`fileName`, `systemSoundID` 모두 두 케이스 명시)
- `try?` 사용 (try! / do-catch 금지): 준수

### SpriteKit 패턴
- didMove(to:)에서 초기화: 해당 없음 (AudioManager는 GameScene property로 자동 초기화)
- dt 기반 이동: 해당 없음
- SKAction 스폰 패턴: 해당 없음
- 충돌 후 노드 즉시 삭제 없음: 해당 없음 (AudioManager는 노드 미보유)
- HUD 노드 분리: 해당 없음

---

## 결론

SPEC §기능1~6 100% 적용. Swift 변경 1개(AudioManager.swift +45) + 문서 2개(README 갱신 + 신규). 빌드 SUCCEEDED + 경고/에러 0줄 (AppIntents 제외). Out of Scope 위반 0건 (특히 GameScene 0줄 / HapticsManager 0줄 / pbxproj 0줄 / CaseIterable 미채택 / 강제 언래핑 0).

**가장 자랑스러운 점**: `audio.play(.noteCollected)` / `audio.play(.gameOver)` 두 호출이 한 글자도 안 바뀌면서, 시스템 사운드 → AVAudioPlayer로 분기하는 인프라가 깔끔히 들어갔다. 추상화 경계가 잘 잡혀있다는 정적 증거. Phase 6-2에서 시그니처를 신중히 정해둔 효과가 6-3에서 정확히 보상받은 sprint.
