# 자체 점검 — Phase 6-6 · AVAudioSession Interruption 처리

## 0. 한 줄 요약
BGMPlayer.swift 단 1개 파일에 NotificationCenter 옵저버 등록/해제와 began/ended 분기 처리를 추가. 외부 인터페이스(`play()` / `stop()`)는 0줄 변경. 회귀 0.

---

## 1. SPEC 기능 6개 구현 확인 표

| # | SPEC 기능 | 구현 상태 | 위치 (BGMPlayer.swift) |
|---|---|---|---|
| 1 | 옵저버 라이프사이클 — init↔deinit 매칭 | 구현 완료 | `init()` L54-63 `addObserver`, `deinit` L66-73 `removeObserver(self)` |
| 2 | Interruption Handler — userInfo 디스패치 | 구현 완료 | `handleInterruption(_:)` L125-145, `@objc private` 어노테이션 + `@unknown default` 포함 |
| 3 | private pause() — 즉시 일시정지 | 구현 완료 | `pause()` L158-162, `isFadingOut` 가드 포함 |
| 4 | private resume() — 페이드 인 재시작 | 구현 완료 | `resume()` L168-170, `play()` 1줄 호출만 (DRY) |
| 5 | 교차 시나리오 정합성 (페이드 중/정상 재생 중/페이드 아웃 중/음원 없음) | 정적 추적 통과 | 아래 §5 검증 시나리오 참조 |
| 6 | AVAudioSession 카테고리 변경 0 | 준수 | 6-4의 `.playback + .mixWithOthers` 코드 0줄 변경 (L42-44) |

---

## 2. 빌드 결과

```
xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" \
  -scheme "GanhoMusic iOS" \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug build
```

- 결과: **BUILD SUCCEEDED**
- 컴파일 에러: **0**
- 컴파일 경고: **0** (grep 검증 — `warning:` / `error:` 출력 없음)
- `note: Using stub executor library with Swift entry point.`만 표준 출력 (정상)
- `note: Metadata extraction skipped. No AppIntents.framework dependency found.` (정상)

---

## 3. 회귀 0줄 강제 항목 (git diff 기반)

`git status --short` + 본 sprint 작업 전후 비교:

| 파일 | 본 sprint 변경 | SPEC 계약 |
|---|---|---|
| `GanhoMusic Shared/Scenes/GameScene.swift` | **0줄** | 준수 |
| `GanhoMusic Shared/Managers/AudioManager.swift` | **0줄** | 준수 |
| `GanhoMusic Shared/Managers/HapticsManager.swift` | **0줄** | 준수 |
| `GanhoMusic Shared/Config/GameConfig.swift` | **0줄** (`git status`의 변경분은 Phase 6-5 미커밋 잔여물 — bgmFadeInDuration/bgmFadeOutDuration 상수, 본 sprint에서 건드리지 않음) | 준수 |
| `GanhoMusic Shared/Scenes/TitleScene.swift` | **0줄** | 준수 |
| `GanhoMusic Shared/Scenes/ResultScene.swift` | **0줄** | 준수 |
| `GanhoMusic Shared/Nodes/*` | **0줄** | 준수 |
| `GanhoMusic Shared/Systems/*` | **0줄** | 준수 |
| `GanhoMusic Shared/Repositories/*` | **0줄** | 준수 |
| `GanhoMusic Shared/Models/*` | **0줄** | 준수 |
| `GanhoMusic Shared/Protocols/*` | **0줄** | 준수 |

본 sprint에서 *유일하게* 수정한 파일: `GanhoMusic Shared/Managers/BGMPlayer.swift`.

### 신규 파일: 없음
SPEC §변경 범위 / 추가할 파일 = "없음"과 일치.

---

## 4. 특별 검증 (코드 라인 직접 확인)

| 검증 항목 | 결과 | 근거 |
|---|---|---|
| `@objc` 어노테이션 부착 (selector 디스패치 대상) | 준수 | L125 `@objc private func handleInterruption(_ notification: Notification)` |
| `private` 키워드 (좁은 인터페이스, 외부 노출 0) | 준수 | `handleInterruption` (L125), `pause` (L158), `resume` (L168) 모두 `private` |
| `isFadingOut` 가드 in `pause()` | 준수 | L160 `if isFadingOut { return }` — 페이드 아웃 도중 인터럽션 시 stopWorkItem과의 충돌 회피 |
| `@unknown default` 처리 (forward-compat) | 준수 | L141-143 `@unknown default: break` |
| 강제 언래핑 (`!`) 사용 | **0개** | `as? UInt` 옵셔널 캐스팅 + `guard let` 체이닝만 사용 (L126-128, L136-137) |
| `[weak self]` 캡처 | 자동 | selector 방식의 `addObserver`는 옵저버를 약참조하므로 명시 `[weak]` 불필요 (SPEC §기능1 주의 사항 일치). stop() 내부의 DispatchWorkItem `[weak self]`는 6-5 기존 코드 보존 |
| `removeObserver(self)` in `deinit` | 준수 | L72 `NotificationCenter.default.removeObserver(self)` |
| `setActive(true)` / 카테고리 재설정 | **0** | 카테고리는 6-4 정책 그대로 (L42-44), Interruption 처리 중 카테고리 손대지 않음 |
| 외부 인터페이스 추가 | **0** | `internal func` 신규 없음. 신규 4개 메서드(deinit, handleInterruption, pause, resume) 모두 private 또는 deinit |
| GameConfig 신규 상수 추가 | **0** | 인터럽션은 즉시 처리 → 상수 불필요 (SPEC §금지 일치) |

---

## 5. 검증 시나리오 (a)~(i) 정적 추적

### (a) 빌드
- BUILD SUCCEEDED, 경고 0. §2에서 확인 완료.

### (b) 음원 부재 폴백 (회귀 0)
- `bgm.m4a` 없음 → L33 `guard let url ... else { return }` 또는 L36 `guard let p ... else { return }`에서 init이 조기 종료
- L58-63의 `addObserver` 호출 도달 X (조기 return 이후 코드)
- 가령 옵저버가 등록되어도 `pause()` L159 `guard let player ... else { return }`와 `play()` L79 `guard let player ... else { return }`이 noop 보장
- **결론**: 6-3/6-4/6-5와 동일하게 player == nil 경로에서 모든 사운드 동작 noop

### (c) 6-5 회귀 — play()/stop() 본문 0줄 변경 확인
- `play()` L78-93: 6-5 그대로
- `stop()` L97-118: 6-5 그대로
- `isFadingOut` / `stopWorkItem` 패턴 그대로
- `GameConfig.bgmFadeInDuration` / `GameConfig.bgmFadeOutDuration` 호출 그대로

### (d) 인터럽션 began 동작
- 시스템이 `interruptionNotification` 발행 (typeValue=1, .began)
- L125 `handleInterruption(_:)` 진입 → L126-128 guard 통과 → L131 `case .began:` → L133 `pause()` 호출
- L158 `pause()` 진입 → L159 player 가드 통과 → L160 `isFadingOut=false`이므로 가드 통과 → L161 `player.pause()` 실행
- **결과**: BGM 즉시 정지, 재생 위치 currentTime 보존

### (e) 인터럽션 ended + shouldResume 동작
- 시스템이 `interruptionNotification` 발행 (typeValue=0, options.shouldResume=true)
- L134 `case .ended:` → L136 optionsValue guard → L137 `InterruptionOptions(rawValue:)` 생성 → L138 `options.contains(.shouldResume)` true → L139 `resume()` 호출
- L168 `resume()` → L169 `play()` 호출
- `play()` L79 player 가드 통과 → L80 `player.isPlaying` false (방금 pause 됨) → L84-86 stopWorkItem 정리 → L90 `volume=0` → L91 `player.play()` → L92 `setVolume(1.0, fadeDuration: 1.5)` 페이드 인 시작
- **결과**: 1.5초 페이드 인으로 BGM 복귀

### (f) 인터럽션 ended without shouldResume
- L136 옵셔널 가드 통과 → L138 `options.contains(.shouldResume)` **false** → L139 미실행
- `resume()` 호출 0
- **결과**: BGM 멈춘 상태 유지 (시스템 의도 존중)

### (g) 페이드 아웃 도중 began
- 게임 종료 직후 `stop()` 호출 → L100 `isFadingOut=true` 세팅 → 페이드 아웃 진행 중
- 인터럽션 `.began` 도달 → L133 `pause()` 호출
- L158 `pause()` 진입 → L159 player 가드 통과 → L160 `isFadingOut=true`이므로 `return`
- `player.pause()` 미호출 → stopWorkItem이 예정대로 L109 `player.stop()` 실행
- **결과**: 페이드 아웃 자연 완료, 충돌 없음

### (h) deinit 옵저버 해제
- BGMPlayer 인스턴스 ARC 해제 시점 → L71 `deinit` 진입 → L72 `removeObserver(self)` 실행
- NotificationCenter에서 self 등록 모두 제거 → dangling observer / 누수 없음

### (i) Phase 1~5 회귀
- GameScene.swift 0줄 변경 → 이동/수집/점수/HUD/적/F/게임오버 모두 그대로
- ResultScene.swift 0줄 변경 → 결과 화면/캐릭터 표시 그대로
- TitleScene.swift / 캐릭터 선택 / AIRFORCE 정책 0줄 변경
- AudioManager / HapticsManager 0줄 변경 → SFX/햅틱 그대로

---

## 6. Swift 패턴 준수

- 강제 언래핑 미사용: **준수** (L126-128, L136-137 옵셔널 가드)
- guard let 옵셔널 처리: **준수** (handleInterruption userInfo 파싱, pause player 가드)
- MARK 섹션 구분: **준수** (`// MARK: - Init`, `// MARK: - Deinit` 신설, `// MARK: - Interruption` 신설)
- GameConfig 상수 사용: **해당 없음** (인터럽션은 즉시 처리 = 튜닝 값 없음, SPEC 정책 일치)
- weak self 캡처: **자동** (selector 방식 addObserver는 옵저버 약참조)

## 7. SpriteKit 패턴 준수

- didMove(to:)에서 초기화: 해당 없음 (BGMPlayer는 SKNode가 아닌 Manager)
- dt 기반 이동: 해당 없음
- SKAction 스폰 패턴: 해당 없음 (Manager에선 SKAction 사용 불가)
- 충돌 후 노드 즉시 삭제 없음: 해당 없음
- HUD 노드 분리: 해당 없음

## 8. 범위 외 미구현 항목

**없음**. SPEC의 §허용 항목 6개 전부 구현. §금지 항목 전부 준수:
- GameScene 변경 0줄
- AudioManager / HapticsManager 변경 0
- public 인터페이스 변경 0 (`play()`/`stop()` 그대로)
- 새 GameConfig 상수 추가 0
- AVAudioSession 카테고리 변경 0
- 게임 일시정지 UI 신설 0
- 백그라운드 라이프사이클 옵저버 0
- 새 SFX / 음원 추가 0
