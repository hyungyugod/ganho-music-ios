# QA 검수 보고서 — Phase 6-7 · 백그라운드/포그라운드 라이프사이클

## SPEC 기능 검증

| # | 기능 | 검증 결과 |
|---|---|---|
| 1 | `import UIKit` 추가 (`import AVFoundation` 다음 줄) | PASS — L11 AVFoundation → L12 UIKit, "Phase 6-7" 주석 명시 |
| 2 | 헤더 주석에 Phase 6-7 1줄 추가 | PASS — L8 "Phase 6-7 · 백그라운드/포그라운드 라이프사이클 — 홈 버튼/앱 스위처 시 BGM 일시정지/재개" |
| 3 | `shouldResumeOnForeground: Bool = false` 프로퍼티 신설 (`private`) | PASS — L29~L33, `// MARK: - Properties` 영역, `stopWorkItem` 옆 |
| 4 | init에서 6-6 interruption 옵저버 이후 라이프사이클 옵저버 2개 등록 | PASS — interruption 등록 직후 didEnterBackground + willEnterForeground (object: nil) |
| 5 | `handleDidEnterBackground` / `handleWillEnterForeground` 둘 다 `@objc private` | PASS — 두 메서드 모두 마커 적용 |
| 6 | `handleDidEnterBackground`: player guard + isPlaying이면 플래그 true + pause() | PASS — guard let player, if isPlaying, 플래그 true 후 pause() 호출 |
| 7 | `handleWillEnterForeground`: 플래그 guard + true면 false 리셋 후 resume() | PASS — guard shouldResumeOnForeground, false 리셋, resume() |
| 8 | 6-6 무변경 검증 (handleInterruption / pause / resume 시그니처·본문 0줄) | PASS — git diff에서 해당 영역 0줄 변경 |
| 9 | deinit 본문 무변경 (`removeObserver(self)` 한 줄) | PASS — 0줄 변경 |
| 10 | `// MARK: - Lifecycle` 섹션 신설 | PASS — `// MARK: - Interruption` 다음 |

## 빌드 검증

- **결과**: BUILD SUCCEEDED
- **명령**: `xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" -scheme "GanhoMusic iOS" -destination 'generic/platform=iOS Simulator' -configuration Debug build`
- **Swift 컴파일 에러**: 0건
- **Swift 경고**: 0건
- **`UIApplication.*Notification` 심볼 해석**: OK (`import UIKit` 추가로 정상)
- **`@objc selector` 디스패치**: OK

## 회귀 0줄 검증 (`git diff --name-only`)

본 sprint 변경: `BGMPlayer.swift` 단 1개 + 산출물(SPEC/SELF_CHECK/QA_REPORT).

| 카테고리 | 파일 | 변경 |
|---|---|---|
| 씬 | GameScene.swift / TitleScene.swift / ResultScene.swift | 0줄 |
| 매니저 | AudioManager.swift / HapticsManager.swift | 0줄 |
| 매니저 | BGMPlayer.swift | **+49줄, -0줄** (본 sprint) |
| 설정 | GameConfig.swift | 0줄 |
| 노드 | Nodes/ 전체 | 0줄 |
| 시스템 | Systems/ 전체 | 0줄 |
| 저장소 | Repositories/ 전체 | 0줄 |
| 모델 | Models/ 전체 | 0줄 |
| 프로토콜 | Protocols/ 전체 | 0줄 |

→ SPEC §"금지" 항목 100% 준수.

## 정적 패턴 검증

| 항목 | 결과 |
|---|---|
| 강제 언래핑 `!` (코드) | **0건** |
| `Timer.scheduledTimer` | **0건** |
| `DispatchQueue` 신규 사용 | **0건** (6-5 기존 코드만 존재, 본 sprint 추가 없음) |
| 매직 넘버 | **0건** (시간/지연 없음 — SPEC 금지) |
| `private` 캡슐화 (새 프로퍼티+메서드 3개) | 전부 `private` 적용 |
| `@objc` 마커 (selector 디스패치) | 새 메서드 2개 모두 적용 |
| MARK 섹션 구분 | `// MARK: - Lifecycle` 신설 |
| 새 public API | 0건 |

## 상태 머신 매트릭스 정합성 (시나리오 A/B/C/D)

### 시나리오 A — 통화 → 백그라운드 (6-7 noop 유지)
```
t=0  interruption(.began) → handleInterruption → pause() → isPlaying=false
t=0+ didEnterBackground → guard 통과 → if isPlaying(FALSE) → noop, 플래그 false 유지
t=N  willEnterForeground → guard(FALSE) → 즉시 return
t=N  interruption(.ended .shouldResume) → resume() ← 6-6 단독 책임
```
→ **이중 재생 0**. 6-7이 끼어들지 않음. PASS.

### 시나리오 B — 단순 홈 → 복귀 (6-7 단독 작동)
```
t=0  isPlaying=true 상태 + 홈 → handleDidEnterBackground
     · 플래그 true + pause()
t=N  willEnterForeground → 플래그 true → false 리셋 → resume()
     · play() → 페이드 인 1.5s
```
→ 깔끔한 단일 페어. PASS.

### 시나리오 C — 페이드 아웃 중 백그라운드
```
t=0.5 페이드 아웃 중, isPlaying=true → handleDidEnterBackground
      · 플래그 true 세팅 + pause() 호출 → pause() 내부 isFadingOut 가드로 noop
t=N   willEnterForeground → 플래그 true → resume() = play() → 페이드 인
```
→ SPEC §시나리오 C에서 "정상" 동작 명시. PASS.

### 시나리오 D — 통화 중 백그라운드 → 복귀 (6-6 단독 책임)
```
t=0  interruption(.began) → pause() → isPlaying=false
t=0+ didEnterBackground → isPlaying false → noop, 플래그 false 유지
t=N  willEnterForeground → 플래그 false → noop
t=N  interruption(.ended) → resume() ← 6-6 단독
```
→ 6-7 가만히 있음. PASS.

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | **0건** |
| P1 중요 | **0건** |
| P2 권장 | **0건** |

## 통과 항목 (강점)

- 강제 언래핑 0, 매직 넘버 0, Timer 0, DispatchQueue 신규 사용 0
- 새 public API 0 (전부 private)
- 6-6 코드(handleInterruption / pause / resume / deinit) 시그니처·본문 0줄 변경
- 회귀 0줄 (BGMPlayer.swift 단일 파일)
- `// MARK: - Lifecycle` 섹션 신설로 코드 구조화 명료
- 강한 순환 참조 없음 (selector 방식, 클로저 미사용 → `[weak self]` 불필요)
- 상태 머신 매트릭스 ↔ 코드 분기 1:1 일치
- 옵저버 3개 일괄 해제 (`removeObserver(self)` 단일 호출) — 선언적 자원 관리

## 채점

| 항목 | 점수 | 코멘트 |
|---|---:|---|
| Swift 패턴 일관성 (35%) | **10/10** | guard let, MARK, private, @objc 마커, final class, weak self 의식 모두 만점 |
| 게임 로직 완성도 (30%) | **10/10** | 라이프사이클 옵저버 페어 정합성, 상태 머신 매트릭스 ↔ 코드 분기 1:1, 6-6과의 협력(시나리오 A/D 비충돌) 완벽 |
| 성능 & 안정성 (20%) | **10/10** | 강제 언래핑 0, deinit removeObserver 보존, 페이드 아웃 중 가드(시나리오 C), 음원 부재 시 graceful 폴백 |
| 기능 완성도 (15%) | **10/10** | SPEC 6개 기능 전부 구현, 회귀 0줄, 빌드 경고 0건, BUILD SUCCEEDED |

**가중 점수**: (10×0.35) + (10×0.30) + (10×0.20) + (10×0.15) = **10.0 / 10**

## 최종 판정: ✅ **합격**

**개선 지시**: 없음.

본 sprint는 SPEC.md를 1회차에 그대로 구현하면서:
1. 6-6 코드를 한 줄도 건드리지 않고 *소비만* 함 (DRY 우아함)
2. 상태 머신 플래그 1개 + 옵저버 2개 추가만으로 시나리오 A/B/C/D 전부 깔끔히 흡수
3. `removeObserver(self)` 벌크 API를 통해 deinit 본문 0줄 변경이라는 선언적 자원 관리 실현
4. 회귀 0줄을 git diff로 객관 입증

Phase 6-7의 핵심 의도("시스템과 사용자에게 양보하는 good citizen BGMPlayer")가 코드 구조에 그대로 반영됨. 8단계 sprint 누적 결과로 BGMPlayer가 5중 가드 매트릭스(isFadingOut, stopWorkItem.cancel, pause-isFadingOut 가드, play-isPlaying 가드, shouldResumeOnForeground)를 갖춘 견고한 매니저로 완성.
