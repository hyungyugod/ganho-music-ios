# 2026-06-02 Device Feedback Sprint Plan

실기기 테스트에서 나온 두 번째 대형 피드백 묶음의 구현 전 계획서다. 구현은 아직 하지 않았고, 사용자가 "Sprint N 진행해줘"라고 지시하면 해당 문서를 기준으로 AGENTS 하네스의 SPEC을 작성한다.

## 문서 목록

| Sprint | 문서 | 목적 |
|---|---|---|
| 1 | `sprint-1-result-navigation.md` | 결과 화면의 의도치 않은 빈 공간 복귀를 제거하고 명시적인 메인 버튼을 만든다. |
| 2 | `sprint-2-apple-login-hardening.md` | Apple 로그인 busy 상태가 풀리지 않는 문제를 진단/수정한다. |
| 3 | `sprint-3-character-unlock-and-rough-selection.md` | 러프한 좌우 탭 전환과 계정별 순차 캐릭터 해금/실루엣 잠금 상태를 구현한다. |
| 4 | `sprint-4-remove-midgame-interruptions.md` | 게임 중간에 플레이를 끊는 mid 컷씬/멘트를 제거한다. |
| 5 | `sprint-5-compact-map-motion-tuning.md` | 맵을 한 번 더 줄이고 이동 속도를 살짝 낮춰 조작감을 맞춘다. |
| 6 | `sprint-6-hospital-map-readability.md` | 장애물/바닥 색 대비를 높이고 병실 느낌의 인테리어를 추가한다. |
| Review | `internal-review.md` | 스프린트 분해, 의존성, 리스크를 내부 검토한 기록. |

## 실행 순서

권장 순서는 1 -> 2 -> 3 -> 4 -> 5 -> 6이다.

- Sprint 1은 결과 화면 터치 회귀를 바로 막는 안전 작업이다.
- Sprint 2가 안정되어야 Sprint 3의 "계정별" 진행도 기준이 신뢰 가능하다.
- Sprint 3은 가장 큰 데이터/UX 변경이다. 구현 전 SPEC에서 계정 진행도 범위를 다시 확인한다.
- Sprint 4는 작지만 플레이 흐름에 직접 영향을 준다. Sprint 5/6 전에 적용하면 플레이 테스트가 쉬워진다.
- Sprint 5는 월드 크기와 이동 속도라 밸런스 영향이 크다.
- Sprint 6은 최종 맵 크기를 기준으로 시각 밀도와 병실 인테리어를 맞춘다.

## 공통 구현 원칙

- 구현 스프린트 시작 전 `SPEC.md`, `SELF_CHECK.md`, `QA_REPORT.md`를 삭제한다.
- 코드 수정 시 `docs/swift-rules.md`, `docs/spritekit-rules.md`, `docs/components.md`를 다시 읽는다.
- 현재 작업트리에는 AppIcon, `.claude/worktrees`, 일부 GameScene extension, Xcode `xcuserdata` 등 별도 변경이 남아 있다. 구현/커밋 시 해당 변경은 섞지 않는다.
- 저장소는 iOS 타겟을 정식 대상으로 본다. tvOS/macOS 템플릿 잔여물은 수정하지 않는다.
- SpriteKit UI는 safe area 기준으로 배치하고, 빈 공간 터치가 중요한 화면 전환을 일으키지 않게 한다.
- 데이터 저장소는 계정 전환 시 다른 계정 진행도가 섞이지 않도록 key scope를 명확히 둔다.
- 맵/이동 튜닝은 easy/normal/hard 모두 최소 1판 진입 가능한지 확인한다.

## 현재 코드 기준 주요 발견

- `ResultScene.touchesBegan`은 share/restart/scoreboard가 아닌 모든 빈 공간 탭을 `StartScene` 전환으로 처리한다. 이것이 의도치 않은 메인 복귀 원인이다.
- `ResultScene`에는 `restartButton`, `shareButton`, `scoreboardButton`은 있지만 명시적인 `mainButton`이 없다.
- `FirebaseAuthManager.signInWithApple`은 busy 상태에서 continuation이 끝나지 않으면 UI가 계속 "Apple 확인 중" 상태로 남는다. `ASAuthorizationController`를 강하게 보관하지 않고 있고, timeout/failure feedback도 부족하다.
- `CharacterSelectScene`은 rail/화살표/스와이프만 전환한다. 화면 좌우를 러프하게 누르는 전환 hit zone은 없다.
- `CharacterSelectScene.selectCharacter`는 모든 캐릭터를 선택 가능하게 저장한다. 해금/잠금 필터가 없다.
- `GraduationRepository`, `PerDifficultyScoreRepository`, `CharacterPreferenceRepository`는 현재 기본적으로 전역 UserDefaults key를 사용한다. 계정별 진행도와 분리하려면 scope가 필요하다.
- 중간 멘트는 `GameScene+Cutscene.triggerMidCutsceneIfNeeded()`의 mid1/mid2가 `.cutscene` 상태로 게임을 멈추는 구조다.
- 현재 compact map은 `tileSize = 28`, `mapWidth = 896`, `mapHeight = 560`이다. 사용자는 여기서 더 줄이고 이동속도도 조금 낮추길 원한다.
- 현재 인게임 바닥/벽 팔레트는 어두운 청보라 계열 중심이라 장애물과 배경이 섞여 보일 수 있다.

## 검증 기준

- `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -configuration Debug build`
- 가능한 경우 실기기에서 다음 흐름을 직접 확인한다:
  - 시작 -> 게스트/Apple -> 캐릭터 홈
  - locked/unlocked 캐릭터 전환
  - 1판 종료 -> 결과 화면 버튼별 동작
  - 중간 멘트 없이 45초 진행
  - compact map에서 벽/스폰/카메라 이상 여부

