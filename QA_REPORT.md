# QA 검수 보고서 — Phase 6-3 (AVAudioPlayer 폴백 인프라)

## SPEC 기능 검증

- [PASS] **기능 1 — `import AVFoundation` 추가**
  - `AudioManager.swift:9-10` — `import AVFoundation` + `import AudioToolbox` 둘 다 유지 (폴백 경로 심볼 보존). SPEC §주의사항 1 충족.
- [PASS] **기능 2 — `SFX.fileName` computed property (옵셔널, exhaustive)**
  - `AudioManager.swift:25-31` — `var fileName: String?` switch에 `default` 없음. `.noteCollected → "note"`, `.gameOver → "gameover"`. `systemSoundID` 바로 위 배치(SPEC 위치 지시 1:1).
- [PASS] **기능 3 — Init + Players Cache**
  - `AudioManager.swift:48` — `private var players: [SFX: AVAudioPlayer] = [:]` stored property로 강참조 유지 (ARC 즉시 해제 방지, SPEC §주의사항 최하단 충족).
  - `AudioManager.swift:53-69` — `init()`:
    - `setCategory(.ambient, mode: .default, options: [])` (`try?`)
    - `let allCases: [SFX] = [.noteCollected, .gameOver]` — CaseIterable 미채택, 명시 배열
    - SFX 순회: `guard let name = sfx.fileName, let url = Bundle.main.url(...)` → `try? AVAudioPlayer(contentsOf:)` → `prepareToPlay()` → cache 채움
    - 모든 실패가 `continue`로 graceful degradation
- [PASS] **기능 4 — `play(_:)` 폴백 분기**
  - `AudioManager.swift:76-83` — `if let player = players[sfx]` 캐시 히트 시 `currentTime = 0; play()`. 미스 시 `AudioServicesPlaySystemSound(sfx.systemSoundID)`. 호출 시그니처 `func play(_ sfx: SFX)` 무변경.
- [PASS] **기능 5 — Resources/README.md 갱신**
  - `Resources/README.md:28` — "향후 들어올 자산" 표 `Sounds/` 행: "Phase 6-3 인프라 설치 완료" 메모로 갱신. AudioManager 자동 활성화/폴백 명시.
  - `Resources/README.md:39-75` — 신규 H2 "## Sounds/ — 자작 효과음 활성화 절차": 권장 포맷(.wav PCM 16bit 44.1kHz), 파일명 고정 표(`note.wav`, `gameover.wav`), Xcode drag-drop 절차에 "Copy items if needed" ✓ / "Add to targets: GanhoMusic iOS" ✓ 체크박스 명시, 부분 활성화 동작까지 서술.
- [PASS] **기능 6 — Resources/Sounds/README.md 신규**
  - `Resources/Sounds/README.md:1-7` — 빈 디렉터리 표식 + 3줄 가이드 + 상위 README 앵커 링크(`../README.md#sounds--자작-효과음-활성화-절차`).

## 빌드 검증

- 결과: **BUILD SUCCEEDED**
- 명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'generic/platform=iOS Simulator' -configuration Debug build`
- 경고/에러: **0건** (`grep -E "warning:|error:"` 0줄)
- 비고: AVFoundation 자동 링크 정상. AudioToolbox 그대로 링크. arm64 + x86_64 universal binary 정상 생성.

## 회귀 검증 (0줄 변경 보장)

`git diff HEAD -- <path> | wc -l` 결과 전부 **0**:

| 파일/디렉터리 | diff 라인 |
|---|---|
| `Managers/HapticsManager.swift` | 0 |
| `GameScene.swift` | 0 |
| `GameScene+Setup.swift` | 0 |
| `Scenes/TitleScene.swift` | 0 |
| `Scenes/ResultScene.swift` | 0 |
| `Nodes/` 전체 | 0 |
| `Systems/` 전체 | 0 |
| `Repositories/` 전체 | 0 |
| `Models/` 전체 | 0 |
| `Protocols/` 전체 | 0 |
| `Config/` 전체 | 0 |
| `project.pbxproj` | 0 |

→ Sprint 범위 계약 완전 준수. `audio.play(.noteCollected)` (`GameScene.swift:209`) / `audio.play(.gameOver)` (`GameScene.swift:254`) 호출부 시그니처·순서·위치 무변경.

## 특별 검증 결과

| 항목 | 결과 |
|---|---|
| `import AVFoundation` + `import AudioToolbox` 둘 다 유지 | PASS (L9-10) |
| `SFX.fileName` switch에 `default` 없음 (exhaustive) | PASS |
| `private var players: [SFX: AVAudioPlayer]` stored property | PASS (L48) |
| `init()`에서 `setCategory(.ambient, ...)` (`try?`) | PASS (L56) |
| `.playback` 사용 | 0건 |
| `setActive(true)` 호출 | 0건 (주석 1건은 부정 설명) |
| `CaseIterable` 채택 | 0건 (명시 배열 `let allCases: [SFX] = [...]`) |
| `try!` / do-catch 사용 | 0건 |
| 강제 언래핑(`!`) | 0건 (`!=` 및 주석 제외) |
| `prepareToPlay()` 호출 | PASS (L66) |
| `currentTime = 0` 위치 (`play()` 전) | PASS (L78 → L79) |
| `AudioServicesPlaySystemSound` 폴백 | PASS (L82) |
| AVAudioPlayer delegate 사용 | 0건 |
| pbxproj 변경 | 0건 |

## 검증 시나리오 (a)~(h) 정적 추적

| # | 시나리오 | 정적 결과 |
|---|---|---|
| (a) | 빌드 — 음원 0개 | BUILD SUCCEEDED. AVFoundation 자동 링크. 경고/에러 0. |
| (b) | 시뮬레이터 폴백 | `players` 빈 딕셔너리 → `if let` 실패 → `AudioServicesPlaySystemSound(1057/1073)` (Tink/Boop) 발화 — 6-2 동작 보존. |
| (c) | 6-2 회귀 0 | GameScene.swift diff 0줄. 호출부 무변경. |
| (d) | GameScene API 무변경 | `func play(_ sfx: SFX)` 시그니처 동일. 호출부 컴파일 차이 0. |
| (e) | 강제 언래핑 0 | `grep '!'`에서 의미 있는 `!` 0건. |
| (f) | AudioSession 카테고리 | `.ambient` (mode `.default`, options `[]`). `.playback` 0, `setActive(true)` 0. |
| (g) | Resources README | 표 갱신 + 신규 H2 절차 명확. drag-drop 체크박스 명시. |
| (h) | 미래 부분 활성화 | for 루프가 SFX별 독립 처리 (`guard let ... else continue`) → 한 케이스 실패가 다른 케이스 영향 0. note.wav만 추가 시 노트만 자작, 게임오버는 시스템 사운드 유지. |

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0 |
| P1 중요 | 0 |
| P2 권장 | 0 |

## P0 — 치명적 이슈
없음.

## P1 — 중요 이슈
없음.

## P2 — 권장 사항
없음. SPEC 설계가 매우 구체적이었고 Generator가 1:1 충실 반영. 추가 권장사항 없음.

## 통과 항목

- **SPEC §주의사항 9개 전부 충족**: AudioToolbox 유지 / `try?` 우선 / `prepareToPlay()` 호출 / `currentTime = 0` 위치 정확 / `setActive(true)` 미호출 / `CaseIterable` 미채택 / 새 SFX 케이스 0 / 음원 파일 실제 추가 0 / stored property 강참조.
- **Swift 패턴**: 강제 언래핑 0, `guard let`/`if let` 옵셔널 처리, `final class`, MARK 4섹션 (`SFX`, `Players Cache`, `Init`, `Play`), `try?` 사용, exhaustive switch (default 없음).
- **응집도**: SFX의 `fileName`과 `systemSoundID`가 enum 내부에 모여 1:1 매핑이 한눈에 보임. computed property로 외부 의존성 노출 없음.
- **추상화 안정성**: `audio.play(...)` 두 호출이 한 글자도 안 바뀐 채 폴백 인프라 도입 — Phase 6-2 시그니처 설계의 의도가 회수됨.
- **graceful degradation 2단계**: AudioSession 설정 실패 (`try?`) + 파일 로딩 실패 (`guard let ... continue`) 모두 폴백 경로(시스템 사운드)로 자연 전환.
- **문서 정합성**: Resources/README의 자산 표가 Phase 6-3 컨텍스트로 갱신됨. Sounds/README는 상위 앵커 링크로 단일 진실 출처 유지.
- **회귀 0**: 보호 대상 12개 경로 모두 diff 0줄. pbxproj 무변경 → Xcode 그룹 자동 인식 경로(폴더 ref 미사용 환경에서 README는 빌드에 무영향).

---

## 채점

**항목별 점수**:
- Swift 패턴 일관성: **10/10** → 강제 언래핑 0, exhaustive switch (default 없음), MARK 4섹션, `try?`만 사용, `final class`, `private` 가시성, 옵셔널 처리 완벽.
- 게임 로직 완성도: **10/10** → Manager 패턴 일관 적용 (HapticsManager와 동급 @Service). SFX enum 응집도 보존. `play(_:)` 시그니처 무변경으로 호출부 안정성 유지.
- 성능 & 안정성: **10/10** → eager 캐시 워밍(`prepareToPlay()`)으로 첫 호출 hiccup 차단. stored property로 ARC 안전. 빌드 클린(경고 0). `.ambient` 카테고리로 다른 앱 사운드 비파괴.
- 기능 완성도: **10/10** → SPEC 기능 1~6 모두 구현. 검증 시나리오 (a)~(h) 전부 정적 추적 PASS. Out of Scope 위반 0건. 회귀 보호 12경로 모두 0줄.

**가중 점수**: 10.0 × 0.35 + 10.0 × 0.30 + 10.0 × 0.20 + 10.0 × 0.15 = **10.0 / 10.0**

## 최종 판정: **합격**

**구체적 개선 지시**: 없음.

추가 코멘트:
- 자랑할 만한 점 — `audio.play(.noteCollected)` / `audio.play(.gameOver)` 두 호출이 단 한 글자도 안 바뀐 채 시스템 사운드 → AVAudioPlayer 분기 인프라가 깔끔히 들어갔다. 이는 Phase 6-2에서 `play(_ sfx: SFX)` 시그니처를 신중히 정한 효과가 Phase 6-3에서 정확히 보상받은 것. Spring `@Service` 인터페이스 안정성의 교과서적 사례.
- 다음 sprint 후보 (본 sprint 범위 외, 참고용)
  1. 사용자가 `note.wav` / `gameover.wav` 자작 음원을 Bundle에 추가 → 동작 검증 sprint
  2. 콤보/AIRFORCE 등 새 SFX 케이스 추가 sprint
  3. BGM sprint (`.playback` 카테고리, `setActive(true)`, AVAudioPlayer 별도 라이프사이클 관리)
