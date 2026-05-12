# 자체 점검 — Phase 6-4 BGMPlayer (배경음악 인프라)

## 1. 변경 파일 목록 (신규 1 + 수정 3 = 4개)

| 파일 | 종류 | diff 요약 |
|---|---|---|
| `GanhoMusic/GanhoMusic Shared/Managers/BGMPlayer.swift` | 신규 | 58줄 — `final class BGMPlayer`, `init()`(Bundle 로딩 → .playback+.mixWithOthers → numberOfLoops=-1 + prepareToPlay), `play()/stop()` |
| `GanhoMusic/GanhoMusic Shared/GameScene.swift` | 수정 | +4 / -0 — 헤더 1줄 + 시스템 `let bgm` 1줄 + `bgm.play()` 1줄 + `bgm.stop()` 1줄 |
| `GanhoMusic/GanhoMusic Shared/Resources/README.md` | 수정 | +28 / -0 — `## Sounds/ — 자작 BGM 활성화 절차 (Phase 6-4)` H2 단락 1개 추가, 기존 효과음 섹션 0줄 변경 |
| `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj` | 수정 | +4 / -0 — PBXBuildFile 1줄 + PBXFileReference 1줄 + Managers PBXGroup children 1줄 + iOS Sources phase 1줄 |

git diff --stat 출력:
```
GanhoMusic/GanhoMusic Shared/GameScene.swift     |   4 +
GanhoMusic/GanhoMusic Shared/Resources/README.md |  28 ++
GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj  |   4 +
```
(SPEC.md / SELF_CHECK.md / QA_REPORT.md는 하네스 산출물, 코드 변경에서 제외.)

## 2. SPEC In Scope 7항목 충족

| # | 항목 | 충족 | 위치 |
|---|---|---|---|
| 1 | BGMPlayer 클래스 신설 | ✅ | `Managers/BGMPlayer.swift` 신규 |
| 2 | GameScene 시스템 섹션 `let bgm = BGMPlayer()` | ✅ | `audio` 다음 줄 (line 65) |
| 3 | GameScene didMove `bgm.play()` | ✅ | `gameState = .playing` 직후 (line 119) |
| 4 | GameScene endGame `bgm.stop()` | ✅ | `audio.play(.gameOver)` 직후, `spawnSystem.stop()` 이전 (line 256) |
| 5 | GameScene 헤더 1줄 (Phase 6-4 라벨) | ✅ | Phase 6-2 라벨 다음 줄 (line 32) |
| 6 | pbxproj 4곳 등록 | ✅ | PBXBuildFile/PBXFileReference/Managers group/iOS Sources phase 각 1줄 |
| 7 | Resources/README.md BGM H2 단락 | ✅ | "관련 문서" 직전에 28줄 추가, 효과음 섹션 무손상 |

## 3. Out of Scope 위반 0건 (정적 검증)

- `AudioManager.swift` 변경: **0줄** (git diff에 미등장)
- `HapticsManager.swift` 변경: **0줄**
- `GameConfig.swift` 변경: **0줄** — 새 상수 0. `"bgm"`/`"m4a"`/`-1`은 모두 BGMPlayer 내부 1회 등장 신호값 (Apple 표준 numberOfLoops = -1).
- 강제 언래핑 (`!`) 사용 횟수: **0회** — 모두 `guard let` 패턴 (`guard let url`, `guard let p`, `guard let player` × 2).
- 페이드 인/아웃: 코드 무 (SKAction.fadeIn/fadeOut 0건).
- 볼륨 조절 / 음소거 옵션: 코드 무 (`player.volume = ...` 0건).
- Repository 영속화: 코드 무 (UserDefaults / BGMRepository 0).
- TitleScene/ResultScene BGM 호출: 코드 무 (해당 파일 변경 0).
- 새 SFX 케이스: `AudioManager.SFX` enum 변경 0.
- `setActive(true)` 명시 호출: **0회** (의도적 미호출 — 카테고리 설정만으로 시스템 자동 활성화).
- BGM delegate / 재생 완료 콜백 (`AVAudioPlayerDelegate`): 0.
- `print` 디버그: 0줄.
- `Resources/Sounds/README.md`: **변경 0** (효과음 전용 유지).
- macOS / tvOS / Test 코드: 미접촉. macOS/tvOS Sources phase 비어있는 그대로 (Phase 6-2 이래 정책 유지).
- `GameScene+Setup` / `TitleScene` / `ResultScene` / Nodes / Systems / Repositories / Models / Protocols: 변경 0.

## 4. pbxproj 4 엔트리 실제 추가 컨텍스트

```diff
@@ PBXBuildFile section (line 30~31) @@
 A1C0F1B00000000000000026 /* AudioManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1C0F1A00000000000000026 /* AudioManager.swift */; };
+A1C0F1B00000000000000027 /* BGMPlayer.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1C0F1A00000000000000027 /* BGMPlayer.swift */; };

@@ PBXFileReference section (line 61~62) @@
 A1C0F1A00000000000000026 /* AudioManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AudioManager.swift; sourceTree = "<group>"; };
+A1C0F1A00000000000000027 /* BGMPlayer.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = BGMPlayer.swift; sourceTree = "<group>"; };

@@ Managers PBXGroup children (line 268~269) @@
 A1C0F1A00000000000000025 /* HapticsManager.swift */,
 A1C0F1A00000000000000026 /* AudioManager.swift */,
+A1C0F1A00000000000000027 /* BGMPlayer.swift */,

@@ iOS Sources build phase (line 470~471) @@
 A1C0F1B00000000000000025 /* HapticsManager.swift in Sources */,
 A1C0F1B00000000000000026 /* AudioManager.swift in Sources */,
+A1C0F1B00000000000000027 /* BGMPlayer.swift in Sources */,
```

- 작업 전 `grep "A1C0F1A00000000000000027"` 0건, `grep "A1C0F1B00000000000000027"` 0건, `grep "BGMPlayer"` 0건 검증 완료 → 충돌 없음, 권장 ID 그대로 사용.
- 신규 PBXGroup 추가 0 (Managers 그룹 이미 존재).
- macOS / tvOS Sources phase 비어있는 그대로 — 두 phase 모두 미접촉.

## 5. 빌드 결과

```
xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" \
  -scheme "GanhoMusic iOS" \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug build
```

- **결과**: `** BUILD SUCCEEDED **`
- **에러**: 0
- **경고** (`grep -E "warning:|error:" | grep -v "AppIntents"`): **0줄**
- AppIntents 경고("Metadata extraction skipped. No AppIntents.framework dependency found")는 Phase 1-1부터 존재한 무관 경고 — 본 sprint와 무관.
- BGMPlayer.swift Sources 빌드 페이즈 등록 확인 (위 pbxproj diff 4번째 hunk).

## 6. 검증 시나리오 (a)~(h) 정적 추적

### (a) 빌드 — ✅
BUILD SUCCEEDED + warning/error 0건. BGMPlayer.swift Sources phase 등록 (pbxproj diff 4번째 hunk).

### (b) 음원 부재 폴백 — ✅ (정적)
`BGMPlayer.init()` line 27: `guard let url = Bundle.main.url(forResource: "bgm", withExtension: "m4a") else { return }` → 현재 `bgm.m4a` 없음 (Resources/Sounds/ 디렉터리 확인) → 첫 guard 실패 → `player = nil`. `try?` AVAudioSession 호출 *이전*에 return하므로 카테고리 변경 0 → AudioManager `.ambient` 정책 유지. `play()/stop()` 모두 `guard let player = player else { return }`로 noop.

### (c) 6-3 회귀 — ✅
- `git diff` 확인: `GanhoMusic/GanhoMusic Shared/Managers/AudioManager.swift` 변경 0줄.
- 효과음 트리거 위치 (`onNoteCollected`의 `audio.play(.noteCollected)` line 209, `endGame`의 `audio.play(.gameOver)` line 254) 그대로.
- 음원 부재 시 카테고리 `.ambient` 유지 (위 (b) 참조).

### (d) Phase 1~5 회귀 — ✅
- 이동/수집/점수/HUD/적/F: `update(_:)` line 154~189 무손상 (변경 0줄).
- 게임오버: `endGame()` 본문은 멱등 가드 + state 전환 + haptics/audio/bgm/spawnSystem.stop/velocity 0 + HUD 갱신 + ResultScene transition — 기존 순서에서 `bgm.stop()` 1줄만 삽입. 다른 line 미접촉.
- ResultScene transition: line 277의 `view.presentScene(resultScene, transition: ...)` 그대로.
- 캐릭터 선택/AIRFORCE: `triggerAirforceEasterEgg()` line 226~242 무손상.
- endGame 멱등 가드: `if gameState == .gameOver { return }` line 251 그대로 — `bgm.stop()`은 가드 *안쪽*에 위치 (line 256).

### (e) 멱등 가드 — ✅
시간만료(`update`에서 `remainingTime <= 0` → `endGame()`) + F 피격(`contactRouter.onProjectileHitPlayer` → `endGame()`) 동시 발생 시:
- 첫 호출: `gameState == .playing` → 가드 통과 → `gameState = .gameOver` → haptics → audio.play → `bgm.stop()` → spawnSystem.stop ...
- 둘째 호출: `gameState == .gameOver` → `return` → `bgm.stop()` 미도달.
→ `bgm.stop()` 1회 보장. `audio.play(.gameOver)`와 동일 보장.

### (f) 재시작 — ✅
- ResultScene → TitleScene → `GameScene.newGameScene(characterID:)` factory (line 87) → 새 `GameScene` 인스턴스.
- `let bgm = BGMPlayer()`는 stored property 초기화 시점에 새 인스턴스 생성 (line 65).
- 매 진입마다 새 AVAudioPlayer → 0초부터 재생.
- 이전 GameScene의 BGMPlayer는 GameScene ARC 해제 시 함께 해제 → 이전 AVAudioPlayer도 dealloc.
- `stop()`은 재생 위치 0 리셋이지만, 어차피 새 인스턴스라 무관.

### (g) mixWithOthers — ✅ (코드 옵션 포함 확인)
BGMPlayer.swift line 36~38:
```swift
try? AVAudioSession.sharedInstance().setCategory(
    .playback, mode: .default, options: [.mixWithOthers]
)
```
`.mixWithOthers` 옵션 포함됨. 실사용 검증(Apple Music + 게임 동시 재생)은 사용자 음원 추가 후 수동.

### (h) 새 SFX 영향 — ✅
- `note.wav` / `gameover.wav`만 추가: AudioManager가 자동 활성화 (Phase 6-3 그대로). BGMPlayer는 `bgm` URL 없음 → 첫 guard 실패 → 카테고리 `.ambient` 유지.
- `bgm.m4a`만 추가: BGMPlayer 활성화 → 카테고리 `.playback` + `.mixWithOthers`로 덮어쓰기. 효과음은 `AudioManager.SystemFallback` 경로(Tink/Boop) 사용. iOS의 카테고리는 시스템 단위 정책 — `.playback`이 켜져 있어도 시스템 사운드는 그대로 재생.
- 셋 다: 완전 자작 사운드 경로. AudioManager가 AVAudioPlayer 경로로 효과음 재생, BGMPlayer가 무한 루프 BGM 재생.

## 7. docs/learn/phase-6-4-bgm-player.md 학습 노트

**작성 완료**: `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/affectionate-elion-d0363a/docs/learn/phase-6-4-bgm-player.md`

중학생 수준 표현 + Spring 비유 포함. 다룬 주제:

1. **한 줄 요약** — "준비실을 또 하나 차렸어요. 파일 한 개만 떨어뜨리면 음악이 흘러요."
2. **graceful fallback의 의미** — 비기술적 워크플로(FL Studio 작곡) ↔ 기술적 빌드(코드) 분리. `@ConditionalOnResource` 비유.
3. **Manager 3연타 (6-1/6-2/6-4)** — final class side-effect 책임 분리. GameScene = `@Controller`, Manager = `@Service`. OCP의 살아있는 예시("새 Manager 추가 시 추가만 일어남").
4. **AVAudioSession 카테고리 정책** — `.ambient` vs `.playback`, `.mixWithOthers` 옵션. `@Transactional(propagation = ...)` 외부 시스템 협상 정책 비유. **"음원 있을 때만 덮어쓰기"** 트릭(회귀 0의 핵심).
5. **BGM vs 효과음 라이프사이클** — 효과음은 `@EventListener`(단발), BGM은 `@Scheduled`(장기 데몬). 명시적 stop 필수.
6. **멱등 가드 안쪽 배치 이유** — 동시 종료 이벤트에서도 `bgm.stop()` 1회 보장.
7. **재시작 시 ARC 자동 청소** — 매 진입마다 새 인스턴스, 이전 BGMPlayer는 ARC가 해제.
8. **pbxproj 4지점의 의미** — Maven pom.xml과 비교한 Xcode 프로젝트 등록 구조.
9. **빌드 검증 결과** — 음원 없는 지금 상태(체감 6-3 그대로) vs 음원 추가 시 자동 활성화 흐름 둘 다 정적 추적.

## 결론

- ✅ SPEC In Scope 7항목 모두 구현
- ✅ Out of Scope 위반 0건 (AudioManager / HapticsManager / GameConfig / Resources/Sounds/README.md 모두 변경 0줄)
- ✅ 강제 언래핑 0회
- ✅ pbxproj 4지점 정확히 추가, ID 충돌 0건
- ✅ BUILD SUCCEEDED, warning/error 0줄
- ✅ 검증 시나리오 (a)~(h) 모두 정적 추적 통과
- ✅ 학습 노트 작성 완료 (중학생 수준 + Spring 비유)
