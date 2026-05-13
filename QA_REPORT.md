# QA 검수 보고서 — Phase 6-6 · AVAudioSession Interruption 처리

## SPEC 기능 검증

| # | 기능 | 결과 | 근거 (BGMPlayer.swift) |
|---|---|---|---|
| 1 | 옵저버 라이프사이클 (init↔deinit 매칭) | PASS | L58-63 `addObserver` (player=p 이후), L71-73 `deinit { removeObserver(self) }` |
| 2 | Interruption Handler — userInfo 디스패치 | PASS | L125-145, `@objc private`, `@unknown default` 포함 |
| 3 | private pause() — 즉시 일시정지 | PASS | L158-162, `isFadingOut` 가드 포함, 페이드 없이 `player.pause()` |
| 4 | private resume() — 페이드 인 재시작 | PASS | L168-170, `play()` 단일 호출 (6-5 fadeIn 재사용, DRY) |
| 5 | 교차 시나리오 정합성 | PASS | 페이드 인 중/정상 재생 중/페이드 아웃 중/음원 없음 모두 정적 추적 통과 |
| 6 | AVAudioSession 카테고리 변경 0 | PASS | L42-44 6-4 정책 (`.playback + .mixWithOthers`) 그대로 |

## 빌드 검증

- 결과: **BUILD SUCCEEDED**
- 컴파일 에러: 0
- 컴파일 경고: 0 (`grep "warning:|error:"` 0건)
- 빌드 명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'generic/platform=iOS Simulator' -configuration Debug build`

## 회귀 0줄 검증 (git diff, Phase 6-6 sprint 기준)

| 파일 | Phase 6-6 sprint 변경 | 결과 |
|---|---|---|
| `Scenes/GameScene.swift` | 0줄 | PASS |
| `Managers/AudioManager.swift` | 0줄 | PASS |
| `Managers/HapticsManager.swift` | 0줄 | PASS |
| `Config/GameConfig.swift` | 0줄 (sprint 기준) | PASS — 현재 작업트리의 diff 8줄(`bgmFadeInDuration`/`bgmFadeOutDuration`)은 Phase 6-5 미커밋 잔여물. BGMPlayer L92/L103에서 이미 사용 중이며, 본 sprint에서 신규 추가/수정 없음 |
| `Scenes/TitleScene.swift` | 0줄 | PASS |
| `Scenes/ResultScene.swift` | 0줄 | PASS |
| `Nodes/*` `Systems/*` `Repositories/*` `Models/*` `Protocols/*` | 0줄 | PASS |

본 sprint sole Swift edit: `Managers/BGMPlayer.swift`. SPEC §변경 범위 일치.

## 핵심 사항 12개 검증 매트릭스

| # | 검증 항목 | 결과 | 근거 |
|---|---|---|---|
| 1 | addObserver가 `player = p` *이후* (L52 이후) | PASS | L52 → L58-63. 두 guard let(L33, L36) 통과한 *이후*에만 옵저버 등록. 음원 부재 시 등록 0 |
| 2 | deinit에서 removeObserver(self) | PASS | L71-73 |
| 3 | handleInterruption에 `@objc` | PASS | L125 `@objc private func` |
| 4 | selector 시그니처 매칭 | PASS | L60 `#selector(handleInterruption(_:))` ↔ L125 `func handleInterruption(_ notification: Notification)` 일치 |
| 5 | began→pause(), ended+shouldResume→resume() | PASS | L131-133, L134-140 |
| 6 | `@unknown default` 처리 | PASS | L141-143 |
| 7 | pause()/resume() private | PASS | L158, L168 모두 `private func` |
| 8 | pause()에 isFadingOut 가드 | PASS | L160 `if isFadingOut { return }` (페이드 아웃 도중 stopWorkItem과 충돌 방어) |
| 9 | resume()이 play() 호출만 (DRY) | PASS | L168-170 단일 `play()` 호출, 페이드 인 코드 중복 없음 |
| 10 | userInfo `as? UInt` 가드, 강제 언래핑 0 | PASS | L127-128, L136 옵셔널 가드. `grep "!" | grep -v "!="` 0건 |
| 11 | 빌드 BUILD SUCCEEDED + 경고 0 | PASS | 위 §빌드 검증 |
| 12 | 회귀 0줄 git diff | PASS | 위 §회귀 0줄 검증 |

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## 통과 항목 (강점)

- **라이프사이클 매칭의 정확성**: `addObserver`가 `player = p` 직후(L52→L58)에 위치 — 음원 부재 시 옵저버 등록 자체가 일어나지 않아 NotificationCenter 오염 0. 동시에 selector 방식의 약참조 + 명시 `removeObserver(self)` 이중 안전망.
- **DRY의 우아함**: `resume()`이 단순히 `play()`를 호출만 함 (L168-170, 3줄). 6-5의 `play()` 내부 가드(`isPlaying` 체크, `stopWorkItem.cancel()`, `isFadingOut = false`)가 인터럽션 재진입 시나리오를 그대로 흡수. 별도 페이드 인 코드 작성 0.
- **isFadingOut 가드의 통찰**: `pause()` L160의 가드가 페이드 아웃 중 `stopWorkItem` 예약된 상태에서 인터럽션 도달 시 `player.pause()` 와 `player.stop()` 의 충돌을 막음. SPEC §기능3 정책("이미 끝나는 중인 음악은 그냥 끝나게 둔다") 정확 반영.
- **Forward-compat**: `@unknown default` (L141)로 Apple이 향후 InterruptionType 케이스 추가 시 컴파일러 경고 확보.
- **강제 언래핑 0**: userInfo 파싱 전체가 `guard let` + `as? UInt` 체이닝(L126-128, L136). 크래시 표면적 0.
- **좁은 인터페이스 유지**: 외부 노출 메서드는 6-5와 동일하게 `play()` / `stop()` 두 개. 신규 4개(deinit + handleInterruption + pause + resume) 전부 private / deinit. AudioManager / HapticsManager 호출 코드에 영향 0.
- **음원 부재 폴백 무결**: bgm.m4a 없으면 L33/L36 두 guard에서 init이 조기 종료 → L58 addObserver 도달 X → pause/resume도 player guard에 막혀 noop. 6-3/6-4/6-5 그대로 동작.
- **MARK 섹션 구분**: `// MARK: - Deinit`, `// MARK: - Interruption` 신설 — Xcode 네비게이터 가독성 유지.

## 채점

| 항목 | 점수 | 코멘트 |
|---|---:|---|
| Swift 패턴 일관성 (35%) | **10/10** | guard let 일관 사용, 강제 언래핑 0, `private` 키워드 정확 적용, `@objc`/`@unknown default` 표준 패턴, MARK 섹션, 매직 넘버 0 |
| 게임 로직 완성도 (30%) | **10/10** | 인터럽션 매트릭스(began/ended+shouldResume/ended w/o resume/페이드 아웃 도중 began) 4개 시나리오 전부 정합. 6-5 페이드 인/아웃과의 상태 머신 충돌 없음 |
| 성능 & 안정성 (20%) | **10/10** | deinit에서 옵저버 정확히 1회 해제, 음원 부재 시 옵저버 미등록, dangling observer / 누수 0 |
| 기능 완성도 (15%) | **10/10** | SPEC 6개 기능 모두 구현, §금지 8개 항목 전부 준수, 빌드 클린 |

**가중 점수**: (10×0.35) + (10×0.30) + (10×0.20) + (10×0.15) = **10.0 / 10**

## 최종 판정: ✅ **합격**

**개선 지시**: 없음.

이번 sprint는 "시스템과 다투지 않는 앱"이라는 SPEC §게임 경험 의도를 코드 레벨에서 정확히 구현했다. NotificationCenter 옵저버 라이프사이클(init↔deinit)의 정확한 매칭, DRY 원칙(resume()이 play()를 그대로 부름), 좁은 인터페이스 유지(외부 노출 메서드 0개 추가), 그리고 페이드 아웃 도중 인터럽션이라는 희귀 시나리오까지 `isFadingOut` 가드로 정확히 처리한 점이 특히 우수하다. Phase 6 Manager 패턴 4연타의 흐름을 그대로 유지하며 회귀 0으로 마무리.
