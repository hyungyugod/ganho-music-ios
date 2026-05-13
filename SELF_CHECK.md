# 자체 점검 — Phase 6-7

전략: 1회차 신규 — SPEC.md 그대로 적용. 단일 파일(BGMPlayer.swift) 49줄 추가, 회귀 0줄.

---

## 1. SPEC 기능 6개 구현 확인 표

| # | 기능 | 구현 위치 | 구현 여부 | 비고 |
|---|---|---|---|---|
| 1 | `import UIKit` 추가 | `BGMPlayer.swift` L12 | ✅ | `import AVFoundation` 다음 줄, `// Phase 6-7` 주석 포함 |
| 1' | 헤더 주석에 Phase 6-7 라인 | `BGMPlayer.swift` L8 | ✅ | "백그라운드/포그라운드 라이프사이클 — 홈 버튼/앱 스위처 시 BGM 일시정지/재개" |
| 2 | `shouldResumeOnForeground` 플래그 | `BGMPlayer.swift` L29~L33 | ✅ | `private var ... = false`, Properties 섹션 (`stopWorkItem` 다음) |
| 3 | init에 옵저버 2개 등록 | `BGMPlayer.swift` L71~L88 | ✅ | 6-6 interruption 등록 직후, `didEnterBackground` + `willEnterForeground`, object: nil |
| 4 | `handleDidEnterBackground(_:)` | `BGMPlayer.swift` L197~L209 | ✅ | `@objc private`, guard `player` → `isPlaying`이면 플래그 true + pause() |
| 5 | `handleWillEnterForeground(_:)` | `BGMPlayer.swift` L211~L219 | ✅ | `@objc private`, 플래그 guard → false 리셋 → resume() |
| 6 | `deinit` 변경 없음 | `BGMPlayer.swift` L96~L98 | ✅ | `removeObserver(self)` 한 줄 그대로 (0줄 변경) |
| 6' | `// MARK: - Lifecycle` 신설 | `BGMPlayer.swift` L197 | ✅ | `// MARK: - Interruption`(`resume()`) 다음 |

---

## 2. 빌드 결과

```
xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" \
           -scheme "GanhoMusic iOS" \
           -destination 'generic/platform=iOS Simulator' \
           -configuration Debug build
```

- 결과: **`** BUILD SUCCEEDED **`**
- Swift 경고: **0건**
- 컴파일 에러: **0건**
- `import UIKit` 추가 후 `UIApplication.didEnterBackgroundNotification` / `willEnterForegroundNotification` 심볼 해석 OK
- `@objc` 메서드 selector(`#selector(handleDidEnterBackground(_:))`, `#selector(handleWillEnterForeground(_:))`) 디스패치 가능
- known warning(`appintentsmetadataprocessor: No AppIntents.framework dependency found`)은 프로젝트 기존 노이즈 (BGMPlayer와 무관)

---

## 3. 회귀 0줄 강제 항목 — `git diff --name-only` 확인

`git diff --name-only`에서 SPEC.md/SELF_CHECK.md/QA_REPORT.md/BGMPlayer.swift를 제외하고 **빈 결과** 확인됨.

| 카테고리 | 파일 | git diff 결과 |
|---|---|---|
| 씬 | `GameScene.swift` | **0줄 변경** |
| 씬 | `TitleScene.swift` | **0줄 변경** |
| 씬 | `ResultScene.swift` | **0줄 변경** |
| 매니저 | `AudioManager.swift` | **0줄 변경** |
| 매니저 | `HapticsManager.swift` | **0줄 변경** |
| 매니저 | `BGMPlayer.swift` | **+49줄, -0줄 (이번 sprint 대상)** |
| 설정 | `GameConfig.swift` | **0줄 변경** |
| 노드 | `Nodes/` 전체 | **0줄 변경** |
| 시스템 | `Systems/` 전체 | **0줄 변경** |
| 저장소 | `Repositories/` 전체 | **0줄 변경** |
| 모델 | `Models/` 전체 | **0줄 변경** |
| 프로토콜 | `Protocols/` 전체 | **0줄 변경** |

명령어 검증:
```bash
$ git diff --name-only | grep -v "SPEC.md\|QA_REPORT.md\|SELF_CHECK.md\|BGMPlayer.swift"
(empty — no other files changed)
```

---

## 4. 특별 검증

### 4-1. `import UIKit` 추가됨
- L11: `import AVFoundation`
- L12: `import UIKit  // Phase 6-7 — UIApplication.*Notification 사용`
- 둘 다 정확한 위치, AVFoundation 다음 줄.

### 4-2. `@objc` 메서드 2개 추가됨
- L202: `@objc private func handleDidEnterBackground(_ notification: Notification)`
- L215: `@objc private func handleWillEnterForeground(_ notification: Notification)`
- 둘 다 `@objc` 마커 + `Notification` 단일 파라미터 + `_` 외부 라벨 생략. 6-6 `handleInterruption(_:)`과 동일 시그니처 패턴.

### 4-3. `private` 키워드 적용됨
- 새 프로퍼티: `private var shouldResumeOnForeground: Bool = false` ✅
- 새 메서드 2개: 둘 다 `@objc private func` ✅
- **새 public/internal API 노출 0** — SPEC "금지" 항목 준수.

### 4-4. 6-6 코드 무변경 확인 (`git diff`로 검증)
diff 출력에서 6-6 코드(L120~L195 영역)는 추가 라인 0, 삭제 라인 0:
- `handleInterruption(_:)` (L150~L170): **시그니처/본문 0줄 변경**
- `pause()` (L183~L187): **시그니처/본문 0줄 변경**
- `resume()` (L193~L195): **시그니처/본문 0줄 변경**

6-7은 이들을 **소비만** 함 (`pause()`를 `handleDidEnterBackground`에서, `resume()`을 `handleWillEnterForeground`에서 호출).

### 4-5. `deinit` 본문 무변경 확인
- L96~L98:
  ```swift
  deinit {
      NotificationCenter.default.removeObserver(self)
  }
  ```
- `removeObserver(self)` 한 줄이 self가 등록한 *모든* 옵저버(6-6의 interruption + 6-7의 didBackground + willForeground = 3개)를 일괄 해제.
- SPEC "추가 코드 0줄" 계약 준수.

### 4-6. `shouldResumeOnForeground` 상태 머신 매트릭스 정합성

| 상황 | 시점 | 코드상 분기 | 플래그 결과 | 매트릭스 일치 |
|---|---|---|---|---|
| 초기화 직후 | `init` 끝 | L33 기본값 `= false` | false | ✅ |
| 게임 미진입 + 백그라운드 | `handleDidEnterBackground` | L203 `guard let player`(통과) → L204 `if player.isPlaying`(false) → noop | false 유지 | ✅ |
| 게임 중 BGM 재생 + 백그라운드 | `handleDidEnterBackground` | L204 if 통과 → L205 `true` 세팅 + L206 `pause()` | **true** | ✅ |
| gameOver 후 + 백그라운드 | `handleDidEnterBackground` | L204 if 미통과 (isPlaying false, 페이드 아웃 이미 끝남) | false 유지 | ✅ |
| 음원 부재 + 백그라운드 | `handleDidEnterBackground` | L203 guard 실패 → 즉시 return | false 유지 | ✅ |
| 포그라운드 복귀, 플래그 true | `handleWillEnterForeground` | L216 guard 통과 → L217 `false`로 리셋 → L218 `resume()` | **false 리셋** + 재생 | ✅ |
| 포그라운드 복귀, 플래그 false | `handleWillEnterForeground` | L216 guard 실패 → 즉시 return | false 유지, noop | ✅ |
| 통화 pause 상태 + 백그라운드 | `handleDidEnterBackground` | L204 if 미통과 (6-6 pause 이미 호출돼서 isPlaying false) | false 유지 | ✅ |

→ SPEC §"shouldResumeOnForeground 상태 관리 매트릭스" 9행 전체와 코드 분기 1:1 일치.

### 4-7. 강제 언래핑 0
- `guard let player = player else { return }` (L203) — 옵셔널 안전 처리
- `guard shouldResumeOnForeground else { return }` (L216) — Bool guard, 언래핑 아님
- 새 코드 49줄 전체에서 `!` 강제 언래핑 **0건**

---

## 5. 검증 시나리오 (a)~(i) 정적 추적

### (a) 빌드 — ✅
- `xcodebuild ... build` → BUILD SUCCEEDED, 경고 0
- `import UIKit` L12에 명시적으로 추가

### (b) 음원 부재 폴백 (회귀 0) — ✅
- `init` L40: `guard let url = Bundle.main.url(...) else { return }`
- 음원 없으면 `return` → 옵저버 등록 코드(L65~L88) **자체에 도달 안 함**
- 따라서 `handleDidEnterBackground` / `handleWillEnterForeground` 콜백 등록 안 됨 → 호출 자체 안 일어남
- player = nil 상태에서 만에 하나 호출되더라도 `handleDidEnterBackground` L203 guard로 noop

### (c) 6-6 코드 무변경 검증 — ✅ (위 4-4 참조)
- `handleInterruption(_:)` / `pause()` / `resume()` 시그니처·본문 0줄 변경

### (d) 백그라운드 진입 — 재생 중일 때 — ✅
- `player.isPlaying == true` 상태에서 `UIApplication.didEnterBackgroundNotification` 발행
- `handleDidEnterBackground` 호출됨 → L203 guard 통과 → L204 `if player.isPlaying`(true) 통과
- L205: `shouldResumeOnForeground = true` 세팅
- L206: `pause()` 호출 → `player.pause()` 실행 (6-6 코드 그대로 사용, isFadingOut false 가정)

### (e) 포그라운드 복귀 — 플래그 true — ✅
- `shouldResumeOnForeground == true` 상태에서 `UIApplication.willEnterForegroundNotification` 발행
- `handleWillEnterForeground` 호출됨 → L216 guard 통과
- L217: `shouldResumeOnForeground = false` 리셋
- L218: `resume()` 호출 → `play()` → 페이드 인 1.5s (6-5 코드 그대로)

### (f) 시나리오 A — 통화 → 백그라운드 → 통화 끝 → 복귀 (6-6/6-7 비충돌) — ✅

추적:
```
t=0    전화 → interruption(.began) → handleInterruption → pause()
        · player.pause() 실행 → isPlaying=false
t=0+   백그라운드 진입 → handleDidEnterBackground
        · guard player(통과) → if player.isPlaying(FALSE — 방금 pause됨) → noop
        · 플래그 false 유지
t=N    포그라운드 복귀 → handleWillEnterForeground
        · guard shouldResumeOnForeground(FALSE) → 즉시 return
        · 6-7이 resume 안 부름
t=N    interruption(.ended .shouldResume) → handleInterruption → resume()
        · 6-6이 단독 resume 책임
```
→ **이중 재생 0**, 6-6/6-7 깔끔하게 분담.

### (g) deinit 무변경 — ✅
- L96~L98: `removeObserver(self)` 한 줄
- self가 등록한 옵저버 3개(interruption + didBackground + willForeground) 모두 일괄 해제

### (h) 회귀 0줄 — ✅ (위 §3 표 참조)
- GameScene/AudioManager/HapticsManager/GameConfig/TitleScene/ResultScene/Nodes/Systems/Repositories/Models/Protocols 전부 0줄

### (i) Phase 1~6 회귀 — ✅ (정적 추적)
- 이동/수집/점수/HUD/적/F/게임오버/ResultScene/캐릭터 선택/AIRFORCE: GameScene/Nodes/Systems 전부 0줄 → 영향 없음
- 페이드 인/아웃 (6-5): `play()`/`stop()` 0줄 변경 → 영향 없음
- Interruption (6-6): `handleInterruption(_:)`/`pause()`/`resume()` 0줄 변경 → 영향 없음
- AudioManager (.ambient 정책): 0줄 변경 → 영향 없음

---

## 6. Swift / SpriteKit 패턴 준수

### Swift 패턴
- 강제 언래핑 미사용: ✅ (위 §4-7)
- guard let 옵셔널 처리: ✅ (L203 `guard let player`)
- MARK 섹션 구분: ✅ (`// MARK: - Lifecycle` 신설)
- GameConfig 상수 사용: 해당 없음 (이번 sprint는 시간/지연 없음, SPEC `금지` 항목)
- weak self 캡처: 해당 없음 (selector 방식, 클로저 사용 안 함)
- `private` 캡슐화: ✅ (프로퍼티 + 메서드 둘 다)
- `final class`: ✅ (기존 유지)
- `@objc` 명시: ✅ (selector 디스패치 필수)

### SpriteKit 패턴
- 본 sprint는 매니저 클래스(SKNode 아님)라 SpriteKit 패턴 항목 대부분 해당 없음:
  - didMove(to:)에서 초기화: 해당 없음 (BGMPlayer는 SKScene 아님)
  - dt 기반 이동: 해당 없음
  - SKAction 스폰: 해당 없음
  - 충돌 후 노드 삭제: 해당 없음
  - HUD 노드 분리: 해당 없음
- Timer 금지: ✅ (Timer 사용 안 함, NotificationCenter selector 방식)

---

## 7. 범위 외 미구현 항목

- 없음. SPEC.md "허용" 6항목 전부 구현, "금지" 항목 전부 미실행.
- 시나리오 C(페이드 아웃 중 백그라운드)의 "버그가 아니라 정상" 동작은 SPEC §"시나리오 C"에서 명시한 대로 본 sprint 범위 *밖*의 후속 정책 조정 대상으로 남김.

---

## 최종 요약

- **변경 파일**: `BGMPlayer.swift` 단 1개
- **추가 라인**: +49줄 (헤더 1 + import 1 + 프로퍼티 5 + init 옵저버 18 + Lifecycle 섹션 24)
- **변경 라인**: 0 (기존 코드 한 줄도 수정 안 함)
- **삭제 라인**: 0
- **빌드**: BUILD SUCCEEDED, 경고 0
- **회귀 0줄**: GameScene/AudioManager/HapticsManager/GameConfig/TitleScene/ResultScene/Nodes/Systems/Repositories/Models/Protocols 전체 0줄
- **6-6 보존**: handleInterruption/pause/resume/deinit 0줄 변경
- **강제 언래핑**: 0
- **새 public API**: 0 (전부 private)
