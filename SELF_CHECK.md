# 자체 점검 — Phase 6-2 AudioManager (시스템 사운드 효과음)

전략: Case A — 이유: 1회차. SPEC §기능1 코드 그대로 + 정확히 3줄 GameScene 패치 + pbxproj 4지점.

---

## 1. 변경 파일 목록 (신규 1 + 수정 2 = 3개)

### 신규 (1개)
| 파일 | 라인 수 | 핵심 |
|---|---|---|
| `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/affectionate-elion-d0363a/GanhoMusic/GanhoMusic Shared/Managers/AudioManager.swift` | 39 | `import AudioToolbox`, `final class AudioManager`, `enum SFX { noteCollected, gameOver }`, computed `systemSoundID` (1057/1073), `func play(_:)` |

### 수정 (2개)

#### A. `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/affectionate-elion-d0363a/GanhoMusic/GanhoMusic Shared/GameScene.swift` (+4줄)
```diff
+ //  Phase 6-2 · AudioManager 신설 + 노트 수집/게임오버 사운드 트리거 2지점
  let haptics = HapticsManager()              // Phase 6-1 — 손맛 강화 (Manager 패턴 첫 등장)
+ let audio   = AudioManager()                // Phase 6-2 — 사운드 손맛 (Manager 패턴 두 번째 적용)

  self.haptics.light()   // Phase 6-1 — 수집 손맛
+ self.audio.play(.noteCollected)   // Phase 6-2 — 수집 사운드 (햅틱 → 사운드 순서)
  note.run(.removeFromParent())

  haptics.heavy()   // Phase 6-1 — 종료 무게감 (가드 통과 1회만)
+ audio.play(.gameOver)   // Phase 6-2 — heavy 직후, spawnSystem.stop() 전
  spawnSystem.stop()
```
`git diff --stat`: `GameScene.swift | 4 +` (헤더 주석 1 + 시스템 프로퍼티 1 + 노트 수집 1 + 게임오버 1).

#### B. `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/affectionate-elion-d0363a/GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj` (+4줄)
정확히 4지점 (PBXBuildFile / PBXFileReference / Managers PBXGroup children / iOS Sources phase).
macOS/tvOS Sources phase는 0줄 변경 (의도된 비대칭 — SPEC §결정 4 명시).

---

## 2. SPEC In Scope 4항목 충족

- [x] **AudioManager.swift 신설** — `import AudioToolbox`, `final class`, `enum SFX { noteCollected, gameOver }`, computed `systemSoundID: SystemSoundID` (1057 Tink / 1073 Boop), `func play(_ sfx: SFX)` — SPEC §기능1 코드 100% 일치.
- [x] **`let audio = AudioManager()` 1줄** — Properties 시스템 섹션, `let haptics` 다음 줄 (GameScene.swift line 63).
- [x] **`self.audio.play(.noteCollected)` 1줄** — `onNoteCollected` 콜백 안, `self.haptics.light()` 다음 줄 (햅틱 → 사운드 순서, SPEC §결정 3 준수).
- [x] **`audio.play(.gameOver)` 1줄** — `endGame()` 안, 멱등 가드 통과 후 `haptics.heavy()` 다음 줄, `spawnSystem.stop()` 전.

---

## 3. Out of Scope 위반 0건

- [x] **AVAudioPlayer / BGM / 음원 에셋 0건** — `import AudioToolbox`만 사용. 시스템 사운드 API만.
- [x] **음소거 옵션 / Repository 영속화 0건** — AudioManager에 상태 0건.
- [x] **SFX 케이스 2개로 고정** — `.combo`, `.airforce`, `.tap` 추가 0건. 미래 확장은 SPEC §결정 2의 OCP 약속만.
- [x] **GameConfig 새 상수 0건** — 1057/1073은 SFX enum 내부 switch에 직접 (SPEC §결정 5 정책).
- [x] **HapticsManager.swift 0줄 변경** — 6-1 그대로 보존.
- [x] **SFX switch에 `default:` 0개** — exhaustive 두 케이스만. `// exhaustive switch — default 없음...` 주석으로 의도 명시.
- [x] **GameScene 다른 부분 0줄** — init/factory/didMove/didChangeSize/layoutDPad/layoutHUD/update/configureContactRouter의 다른 4 콜백/triggerAirforceEasterEgg/endGame의 멱등 가드+state 전환 외 부분 frozen. `git diff` 정확히 4줄 추가.
- [x] **GameScene+Setup / TitleScene / ResultScene / 모든 Node / 모든 System / 모든 Repository / CharacterID / GameStats / ColorTokens / GameConfig / Protocols 0줄 변경**.
- [x] **macOS / tvOS / Test 0줄 변경** — pbxproj iOS Sources phase에만 1줄. macOS/tvOS Sources phase는 빈 채로 유지.

---

## 4. pbxproj 4 엔트리 실제 추가 라인 컨텍스트

`grep -n "AudioManager" project.pbxproj` 결과 정확히 4건:

```
30: 		A1C0F1B00000000000000026 /* AudioManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1C0F1A00000000000000026 /* AudioManager.swift */; };
61: 		A1C0F1A00000000000000026 /* AudioManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AudioManager.swift; sourceTree = "<group>"; };
268: 				A1C0F1A00000000000000026 /* AudioManager.swift */,
470: 				A1C0F1B00000000000000026 /* AudioManager.swift in Sources */,
```

각각:
- **(a) Line 30 PBXBuildFile**: HapticsManager(line 29) 바로 다음, 동일 패턴.
- **(b) Line 61 PBXFileReference**: HapticsManager(line 59) 다음 (CharacterPreferenceRepository 라인 60 사이 정렬 — 원래 순서 유지).
- **(c) Line 268 Managers PBXGroup children**: HapticsManager(line 267) 다음. Managers 그룹은 6-1에서 이미 생성됨 — 신규 그룹 추가 0건.
- **(d) Line 470 iOS Sources build phase**: HapticsManager(line 469) 다음.

**충돌 검사**: 작업 전 `grep "A1C0F1A00000000000000026\|A1C0F1B00000000000000026"` → 0건 (HapticsManager `...0025` 다음 hex로 안전).

**비대칭 확인**: macOS Sources phase / tvOS Sources phase는 빈 채로 유지 (HapticsManager도 동일 — Manager 시리즈는 iOS 전용 정책).

---

## 5. 빌드 결과

```
** BUILD SUCCEEDED **
```

- 명령: `xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" -scheme "GanhoMusic iOS" -destination 'generic/platform=iOS Simulator' -configuration Debug build`
- `grep -E "warning:|error:" | grep -v "AppIntents"` → **0줄**
- AppIntents `Metadata extraction skipped` 경고는 본 sprint 무관 (Xcode 26.x 환경 잡음).
- arm64 + x86_64 universal binary 정상 생성, Codesign OK.

---

## 6. 검증 시나리오 (a)~(h) 정적 추적

### (a) 빌드 검증 — 컴파일 ✓
- `SystemSoundID` 타입 인식 ✓ (AudioToolbox 자동 link).
- exhaustive switch ✓ (`default` 없음 → 두 케이스 모두 명시).
- final class ✓.

### (b) 노트 수집 사운드 — 정적 흐름 추적 ✓
1. PhysicsBody 접촉 → `ContactRouter.didBegin(_:)`
2. `onNoteCollected` 클로저 발화 (GameScene.configureContactRouter 등록)
3. `[weak self]` 가드 → `scoreSystem.recordNoteHit(...)` → `haptics.light()` → **`audio.play(.noteCollected)`** → `note.run(.removeFromParent())`
4. `AudioServicesPlaySystemSound(1057)` → iOS Tink 발화. 1초 내 3회 연속도 비동기 큐로 누락 없음.

### (c) 게임오버 사운드 3경로 ✓
세 경로 모두 `endGame()` 한 곳으로 수렴 — 멱등 가드 통과 후 1회만 발화:
- **시간 만료**: `update()` → `remainingTime <= 0` → `endGame()`
- **적 접촉**: `onEnemyHit` → `endGame()`
- **F 피격**: `onProjectileHitPlayer` → `endGame()`

`endGame()` 안 흐름: `if gameState == .gameOver { return }` (멱등) → `gameState = .gameOver` → `haptics.heavy()` → **`audio.play(.gameOver)`** → `spawnSystem.stop()` → ...

→ Boop 1회 보장.

### (d) 실기기 동작 (정적 명세) ✓
- 무음 모드 ON: `AudioServicesPlaySystemSound`는 차단됨 (Apple 정책 — 본 sprint 의도된 동작).
- 무음 모드 OFF: 정상 발화.
- 햅틱은 무음 모드와 독립 — 동기화 어긋남 위험 정적으로 확인.

### (e) Phase 6-1 회귀 ✓
- `HapticsManager.swift`: `git diff --stat` 0건.
- `haptics.light()` / `haptics.heavy()` 호출 위치 그대로.

### (f) Phase 1~5 회귀 ✓
- `GameScene.swift` 4줄 추가만 — 게임 로직 메서드(update/triggerAirforceEasterEgg/configureContactRouter의 다른 4 콜백) 모두 동일.
- 다른 모든 파일 0줄 변경.

### (g) 동시 발화 타이밍 ✓
- `UIImpactFeedbackGenerator.impactOccurred()`: 즉시 반환 (UIKit 비동기 큐).
- `AudioServicesPlaySystemSound`: 즉시 반환 (CoreAudio 비동기 큐, thread-safe 명문화).
- 두 호출 모두 main thread blocking 0 → 게임 루프 1/60 fps 영향 0.

### (h) 멱등 / 메모리 ✓
- `endGame()` 2회 호출: `if gameState == .gameOver { return }`가 두 번째 호출 가드 → 사운드 1회만.
- `AudioManager` 인스턴스: `let audio = AudioManager()` — GameScene 인스턴스 수명 = AudioManager 수명. ResultScene presentScene 시 GameScene ARC 해제 → AudioManager 자동 해제.
- AudioManager는 상태 0건(`enum SFX`만 보유, stored property 없음) → 누수 위험 0.
- 새 게임 진입: TitleScene → GameScene 새 인스턴스 → 새 AudioManager (자동).

---

## 7. Swift 패턴 준수

- 강제 언래핑 미사용: 준수 (AudioManager 옵셔널 0건).
- guard let 옵셔널 처리: 해당 없음 (옵셔널 미사용).
- MARK 섹션 구분: 준수 (`// MARK: - SFX`, `// MARK: - Play`).
- GameConfig 상수 사용: 해당 없음 (SPEC §결정 5 — 외부 도메인 ID는 enum 내부 예외).
- weak self 캡처: 준수 (AudioManager 자체 클로저 0건. `onNoteCollected` 클로저는 이미 6-1에서 `[weak self]`).
- final class: 준수 (`final class AudioManager` — 상속 의도 없음 명시).
- enum exhaustive: 준수 (`default:` 0개. Phase 5-3 `CharacterID.playerSpeedMultiplier` 패턴 동일).

## 8. SpriteKit 패턴 준수

- didMove(to:)에서 초기화: 해당 없음 (AudioManager는 GameScene property로 자동 초기화).
- dt 기반 이동: 해당 없음.
- SKAction 스폰 패턴: 해당 없음.
- 충돌 후 노드 즉시 삭제 없음: 준수 (`note.run(.removeFromParent())` SKAction — 6-1 그대로).
- HUD 노드 분리: 해당 없음.

---

## 9. docs/learn/ 학습 노트

`/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/affectionate-elion-d0363a/docs/learn/phase-6-2-audio-manager.md` 작성 완료.

다룬 주제:
1. **Manager 패턴 두 번째 적용** — `@Service` 빈이 둘로 늘었어요 (EmailService + SmsService 비유).
2. **enum + computed property 재등장** — Phase 5-3 `CharacterID.playerSpeedMultiplier`와 같은 모양 = Java sealed class 안전망.
3. **매직 넘버 정책의 미묘함** — 1057/1073은 외부 도메인 ID라 GameConfig 밖. application.yml vs HTTP 상태코드 비유.
4. **멀티모달 피드백 동기화** — 한 사건이 손가락·눈·귀 세 감각으로 동시 도착 = "살아있는 게임" 첫 인상.
5. **default 절대 금지** — 미래 케이스 추가 시 컴파일러 강제 매핑 안전망.
6. **pbxproj 4지점 작업법** — HapticsManager 패턴 그대로 반복.

중학생 수준 표현, Spring 비유 명시, 전문용어 최소화 (CLAUDE.md MEMORY 정책 준수).

---

## 결론

SPEC §기능1~4 100% 적용. 변경 라인 합계: AudioManager.swift 39 신규 + GameScene.swift 4 + pbxproj 4. 빌드 SUCCEEDED + 경고/에러 0줄 (AppIntents 제외). Out of Scope 위반 0건. 멀티모달 피드백 (촉각+청각) 동기화 완성.
