# QA 검수 보고서

## SPEC 기능 검증
- [PASS] Sprint 1 Result Navigation: `ResultScene.swift:1067`에서 빈 공간 탭 fallback이 noop으로 끝나며, `ResultScene.swift:703`의 `메인으로` 버튼만 StartScene 전환을 담당한다.
- [PASS] Sprint 2 Apple Login Hardening: `FirebaseAuthManager.swift:41`에서 `ASAuthorizationController`를 strong retain하고, `FirebaseAuthManager.swift:264`의 12초 timeout 및 `FirebaseAuthManager.swift:249`의 owner-only clear가 적용됨.
- [PASS] Sprint 3 Character Unlock And Rough Selection: `CharacterSelectScene.swift:590`에서 scoped repository를 구성하고, `CharacterSelectScene.swift:742`에서 locked preview는 허용하되 unlocked일 때만 preference 저장, `CharacterSelectScene.swift:951`에서 locked start를 차단함.
- [PASS] Sprint 4 Remove Midgame Interruptions: `GameConfig.swift:3042`의 `enableMidGameCutscenes = false`와 `GameScene+Cutscene.swift:21` guard로 mid1/mid2 blocking cutscene이 비활성화됨. Airforce/Sergeant 흐름은 `GameScene+EasterEgg.swift:17`과 `GameScene+Setup.swift:258`에서 gameState 전환 없이 비차단으로 유지됨.
- [PASS] Sprint 5 Compact Map And Motion Tuning: `GameConfig.swift:103`의 runtime cell `25.0`, `GameConfig.swift:111`/`113`의 `800x500` map, `PlayerNode.swift:153`의 `0.9` speed multiplier 적용 확인.
- [PASS] Sprint 6 Hospital Map Readability: `GameConfig.swift:2853`~`2861` 색상은 16색 팔레트 값 안에 있고, `HospitalPropNode.swift:58`/`97`의 이전 `.ganhoScrubMint` 사용은 `.ganhoIngameRewardMint`로 교체됨. props는 `MapNode.swift:214`에서 8개만 visual-only로 부착됨.

## 최신 QA_REPORT 남은 지시 반영 확인
- [PASS] 비차단 피드백 토스트 복구: `GameScene+Feedback.swift:59`, `GameScene+Feedback.swift:70`, `GameScene+Contact.swift:76`, `GameScene+Contact.swift:115`, `SkillSystem.swift:263`에서 `ToastLabelNode.spawn(...)` 복구 확인.
- [PASS] `매혹!` 문자열 상수화: `GameConfig.swift:1012`의 `charmStudentToastText` 사용 확인.
- [PASS] hospital prop 팔레트 교체: `HospitalPropNode.swift:58`/`97`이 `.ganhoIngameRewardMint`를 사용하며, 해당 hex는 `GameConfig.swift:2861`의 `#7DCFB6` 팔레트 값임.

## 빌드 검증
- 결과: BUILD SUCCEEDED (fallback destination)
- 지정 명령 결과: `platform=iOS Simulator,name=iPhone 15`는 현재 환경에 없어 destination unavailable.
- 대체 검증: `platform=iOS Simulator,name=iPhone 17,OS=26.5` Debug 빌드에서 `** BUILD SUCCEEDED **` 확인.
- AppIntents warning: 최신 fallback warning 필터 빌드에서는 재현되지 않았으나, 최신 SELF_CHECK/이전 QA에 남은 `Metadata extraction skipped. No AppIntents.framework dependency found.`는 빌드 성공에 영향 없는 P2 잔여 경고로만 분류한다.

## 검수 결과 요약

| 등급 | 건수 |
|---|---:|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 1건 |

## P0 — 치명적 이슈
없음.

## P1 — 중요 이슈
없음.

## P2 — 권장 사항

### 1. AppIntents metadata warning 잔여 관리
- **파일**: `xcodebuild`
- **위반 규칙**: 빌드 경고는 P2 처리
- **현재 코드**: `warning: Metadata extraction skipped. No AppIntents.framework dependency found.`
- **문제 이유**: 컴파일 실패는 아니며 최신 fallback 빌드 성공에 영향도 없지만, 이전 QA/SELF_CHECK 기준 잔여 경고로 추적 대상이다.
- **수정 제안**: AppIntents를 사용하지 않는 의도된 warning이면 release-readiness 문서에 명시하거나, 필요 시 Xcode build setting에서 metadata extraction 경고 조건을 정리한다.

## 통과 항목
- 수정 범위 내 강제 언래핑, `as!`, `try!` 없음.
- 수정 범위 내 `Timer.` / `DispatchQueue` 신규 사용 없음. 인증 timeout은 SPEC 허용대로 Swift concurrency `Task` 사용.
- 주요 `Task`/`SKAction.run`/contact closure는 `[weak self]` 또는 weak 캡처 사용.
- 물리 contact 콜백의 노드 제거는 `GameScene+Contact.swift:145`에서 wait 0 + `.removeFromParent()`로 지연 처리됨.
- 신규 Swift 파일 4개는 `project.pbxproj` Sources에 등록되어 fallback 빌드에서 컴파일됨.
- `GameScene.swift`는 295줄로 300줄 미만 유지.
- `git diff --check` 통과.

---

## 채점

**항목별 점수**:
- Swift 패턴 일관성: 7.6/10
- 게임 로직 완성도: 8.0/10
- 성능 & 안정성: 8.0/10
- 기능 완성도: 8.4/10
- **가중 점수**: 7.9/10

## 최종 판정: 합격

**구체적 개선 지시**:
1. 필수 개선 지시 없음.
2. 권장: AppIntents metadata warning이 다시 표시되면 의도된 잔여 경고로 문서화하거나 build setting에서 정리할 것.
