# QA 검수 보고서 — Phase 6-4 BGMPlayer

## SPEC 기능 검증

- [PASS] **기능 1 — BGMPlayer 클래스 신설**: `Managers/BGMPlayer.swift` 58줄, `final class BGMPlayer` + `import AVFoundation` + `private var player: AVAudioPlayer?` + init 4단계(Bundle URL → AVAudioPlayer 생성 → AVAudioSession `.playback`+`.mixWithOthers` 덮어쓰기 → `numberOfLoops = -1` + `prepareToPlay()`) + `play()/stop()` 모두 SPEC 시그니처와 줄 단위로 일치.
- [PASS] **기능 2 — GameScene 시스템 섹션 1줄**: `GameScene.swift:66` `let bgm = BGMPlayer()`, `audio` 다음 줄 정확 — `let audio` → `let bgm` 순서로 카테고리 덮어쓰기 의존성도 보존.
- [PASS] **기능 3 — didMove `bgm.play()`**: `GameScene.swift:120` `gameState = .playing` 직후 1줄 — SPEC 결정 3과 정확 일치.
- [PASS] **기능 4 — endGame `bgm.stop()`**: `GameScene.swift:258` `audio.play(.gameOver)` 직후, `spawnSystem.stop()` 이전, 멱등 가드(`if gameState == .gameOver { return }`) 안쪽 — 1회 보장 위치.
- [PASS] **기능 5 — GameScene 헤더 1줄**: `GameScene.swift:32` `Phase 6-4 · BGMPlayer 신설 + 게임 시작/종료 시 BGM 재생/정지` Phase 6-2 라벨 다음 줄.
- [PASS] **기능 6 — pbxproj 4지점 등록**: PBXBuildFile(L31) / PBXFileReference(L63) / Managers PBXGroup children(L271) / iOS Sources phase(L474) — 정확히 4건, ID `A1C0F1B0...0027` / `A1C0F1A0...0027` 충돌 0, 신규 PBXGroup 0, macOS·tvOS Sources phase 빈 채로 유지.
- [PASS] **기능 7 — Resources/README.md BGM H2 단락**: +28줄, "관련 문서" 섹션 *바로 앞*에 신설, 기존 효과음 섹션 0줄 변경.

## 빌드 검증

- **결과**: ✅ **BUILD SUCCEEDED**
- **명령**: `xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" -scheme "GanhoMusic iOS" -destination 'generic/platform=iOS Simulator' -configuration Debug build`
- **에러**: 0
- **경고** (AppIntents 무관 잡음 제외): 0줄 — `grep -E "warning:|error:" | grep -v "AppIntents"` 결과 빈 출력.
- **BGMPlayer.swift** iOS Sources phase 등록 확인됨 (pbxproj line 474).

## 회귀 검증 (변경 0줄 강제 항목)

| 파일 / 경로 | `git diff` 라인 | 결과 |
|---|---:|---|
| `Managers/AudioManager.swift` | 0 | ✅ |
| `Managers/HapticsManager.swift` | 0 | ✅ |
| `GameScene+Setup.swift` | 0 | ✅ |
| `Scenes/TitleScene.swift` | 0 | ✅ |
| `Scenes/ResultScene.swift` | 0 | ✅ |
| `Nodes/` 전체 | 0 | ✅ |
| `Systems/` 전체 | 0 | ✅ |
| `Repositories/` 전체 | 0 | ✅ |
| `Models/` 전체 | 0 | ✅ |
| `Protocols/` 전체 | 0 | ✅ |
| `Config/` 전체 (GameConfig 포함) | 0 | ✅ — 새 상수 0, 매직 넘버 신설 0 |
| `Resources/Sounds/README.md` | 0 | ✅ — 효과음 전용 유지 |

## 특별 검증

| 항목 | 결과 |
|---|---|
| `import AVFoundation` | ✅ line 8 |
| `final class BGMPlayer` | ✅ line 14 |
| `private var player: AVAudioPlayer?` | ✅ line 18 |
| init 4단계 순서 (URL → AVAudioPlayer → setCategory → numberOfLoops+prepareToPlay) | ✅ L25→L28→L34→L39-40 — guard 실패 시 setCategory 미도달 (회귀 0의 핵심) |
| `setActive(true)` 호출 횟수 | 0건 (주석으로만 의도 명시 — line 33) |
| `try?` 사용 / `try!` 사용 / `do-catch` 사용 | `try?` 2건 (L28, L34) / `try!` 0 / `do-catch` 0 ✅ |
| 강제 언래핑 `!` | 0건 (`!=`만 grep noise — 실제 unwrap 0) ✅ |
| `play()` 가드 — `guard let player` + `isPlaying` 분기 | ✅ L47-48 |
| `stop()` 가드 — `guard let player` | ✅ L54 |
| `print` 디버그 | 0건 ✅ |
| GameScene 시스템 섹션 위치 (`audio` 다음) | ✅ L66 (L65 audio 바로 다음) |
| `bgm.play()` 위치 (`gameState = .playing` 직후) | ✅ L120 (L119 다음) |
| `bgm.stop()` 위치 (`audio.play(.gameOver)` 직후, `spawnSystem.stop()` 이전, 멱등 가드 안쪽) | ✅ L258 (L257 audio.play 다음, L259 spawnSystem.stop 이전, L254 가드 안쪽) |
| `grep "BGMPlayer" project.pbxproj` 결과 | 정확히 4건 ✅ |
| `grep "0000027" project.pbxproj` 결과 | 정확히 4건 (모두 BGMPlayer) ✅ |
| 신규 PBXGroup 추가 | 0건 ✅ (Managers 기존 그룹에 children 1줄만 추가) |
| macOS / tvOS Sources phase | 빈 채로 유지 ✅ (`files = ( );`) |

## 검증 시나리오 (a)~(h) 정적 추적

| # | 시나리오 | 결과 |
|---|---|---|
| (a) | 빌드 — `BUILD SUCCEEDED`, warning/error 0 | ✅ |
| (b) | 음원 부재 폴백 — `bgm.m4a` 없음 → `guard let url` 실패 → `player = nil`, setCategory 미호출 → `.ambient` 유지 | ✅ |
| (c) | 6-3 회귀 — AudioManager 0줄, 효과음 트리거 위치 그대로, 카테고리 `.ambient` 유지 | ✅ |
| (d) | Phase 1~5 회귀 — `update`/`endGame`/`triggerAirforceEasterEgg`/HUD/ResultScene transition 모두 무손상 | ✅ |
| (e) | 멱등 가드 — `bgm.stop()`이 가드 *안쪽*에 위치 → 시간만료+F피격 동시 발생 시 1회 보장 | ✅ |
| (f) | 재시작 — `let bgm = BGMPlayer()`는 stored property → 매 GameScene 인스턴스마다 새 인스턴스, ARC가 이전 인스턴스 해제 | ✅ |
| (g) | `mixWithOthers` 옵션 — `options: [.mixWithOthers]` 코드 포함 (L35) | ✅ |
| (h) | 새 SFX 영향 — note/gameover.wav 추가는 AudioManager 경로, BGMPlayer는 무관(URL 없음 → `.ambient` 유지); bgm.m4a 추가는 BGMPlayer만 활성화하고 시스템 사운드는 별도 경로로 정상 발화 | ✅ |

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0 |
| P1 중요 | 0 |
| P2 권장 | 0 |

P0/P1/P2 모든 등급에서 발견된 이슈 0건.

## 통과 항목 — 특히 강조

1. **graceful fallback 4단 가드 구조의 우아함**: `guard let url` → `guard let p` → `try?` setCategory → numberOfLoops/prepareToPlay. URL이 없으면 setCategory를 *건드리지도 않아* `.ambient`가 그대로 살아남는 설계 — Phase 6-3과의 회귀 0 약속이 *코드 구조* 자체에 박혀 있다. 주석으로 "음원 로딩 성공한 *이후에만*" 의도를 명시한 것도 훌륭하다.
2. **카테고리 덮어쓰기 순서 의존성**: GameScene의 `let audio` → `let bgm` 순서가 Swift stored property 초기화 순서로 보존됨. AudioManager가 먼저 `.ambient`를 깔고, BGMPlayer가 (음원 있을 때만) `.playback`+`.mixWithOthers`로 덮어쓰는 — 이 *순서 자체*가 정책의 일부.
3. **멱등 가드 안쪽 배치**: `bgm.stop()`이 `if gameState == .gameOver { return }` 안쪽에 있어 동시 종료 이벤트(시간만료+F피격)에서도 1회 호출 보장. `audio.play(.gameOver)`와 같은 보호 영역.
4. **GameScene 정확히 4줄 변경**: 헤더 1 + 시스템 1 + didMove 1 + endGame 1 = 4줄. `git diff --numstat`이 `4 0`으로 정확. SPEC의 "4지점" 약속 완벽 준수.
5. **pbxproj 4 엔트리 정밀 삽입**: PBXBuildFile / PBXFileReference / Managers PBXGroup children / iOS Sources phase — 모두 AudioManager(`...0026`) 바로 다음 줄에 `...0027`로 일관되게 배치. 신규 PBXGroup 0, macOS/tvOS Sources phase 빈 채로 유지.
6. **GameConfig 0 변경**: `"bgm"` / `"m4a"` / `-1` 모두 1회 등장하는 신호값(Apple 표준 numberOfLoops 컨벤션) — 매직 넘버로 GameConfig로 옮길 가치 없음. 판단이 정확.
7. **Out of Scope 금지 항목 완벽 회피**: 페이드 인/아웃 / 볼륨 / 음소거 / Repository / TitleScene·ResultScene BGM / 새 SFX 케이스 / `setActive(true)` / delegate / `print` / 강제 언래핑 — 모두 0건.

---

## 채점

| 항목 | 점수 | 코멘트 |
|---|---:|---|
| Swift 패턴 일관성 (35%) | **10/10** | `final class`, `import AVFoundation`, MARK 섹션, 한국어 주석 + 영문 식별자, `guard let` 옵셔널 처리, `try?` graceful, 강제 언래핑 0, `print` 0, 매직 넘버 0(신호값 1회 등장만). |
| 게임 로직 완성도 (30%) | **10/10** | didMove 위치(`.playing` 직후), endGame 위치(audio 직후·spawnSystem 이전·가드 안쪽), `numberOfLoops = -1` + `prepareToPlay`, `isPlaying` 가드로 중복 play 안전, `stop()`이 재생 위치 0 리셋(재시작 의미 일치). |
| 성능 & 안정성 (20%) | **10/10** | `prepareToPlay`로 첫 play 지연 최소화, 강제 언래핑 0(크래시 면역), ARC가 GameScene 해제 시 BGMPlayer 자동 해제(메모리 누수 0), BUILD SUCCEEDED + warning/error 0. |
| 기능 완성도 (15%) | **10/10** | SPEC In Scope 7항목 전원 구현, Out of Scope 위반 0, 검증 시나리오 (a)~(h) 전원 통과, 회귀 검증 0줄 항목 12개 전원 통과. |

**가중 점수**: (10×0.35) + (10×0.30) + (10×0.20) + (10×0.15) = **10.0 / 10**

## 최종 판정: ✅ **합격**

**관대 검토 — "이 정도면 괜찮지 않나?" 자문**:
- BGMPlayer 58줄을 다시 한 줄씩 읽었음. line 25/28의 guard 순서, line 34의 setCategory 위치, line 39의 numberOfLoops=-1, line 47-48의 isPlaying 가드 — 어느 한 곳도 P2조차 잡을 빈틈이 없음.
- GameScene 4줄 변경의 *위치*: 헤더 L32 (Phase 6-2 다음), 시스템 L66 (audio 다음), didMove L120 (.playing 직후), endGame L258 (audio.play 직후·spawnSystem.stop 이전·가드 안쪽) — 모두 SPEC 명시 위치와 1:1.
- pbxproj 4지점: ID 0027 충돌 0, AudioManager(0026) 바로 다음 줄에 일관 배치, 신규 PBXGroup 0, 빈 phase 유지 — 4 hunk diff가 외과수술처럼 깔끔.
- 회귀 검증: 변경 0줄 약속 12개 파일/디렉터리 모두 `git diff` 0줄 통과.
- 빌드 클린, 정적 검사 클린, SPEC 정합 클린, 회귀 클린 — 만점을 깎을 근거를 찾지 못함.

**구체적 개선 지시**: 없음. 합격 그대로 머지 가능.

