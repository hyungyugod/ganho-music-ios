# 자체 점검

전략: Case A — 이유: QA 가중 점수 6.9로 기존 구현 방향을 유지하되 3회차 남은 P1 2건을 정밀 반영

## SPEC 기능 체크
- [x] Sprint 1 Result Navigation: 빈 공간 탭 fallback 제거, `메인으로` 버튼 추가, 하단 4버튼 레이아웃 적용
- [x] Sprint 2 Apple Login Hardening: Apple controller strong retain, 12초 timeout, continuation 단일 resume, 취소/timeout/실패 idle 복구
- [x] Sprint 3 Character Unlock And Rough Selection: 계정 scoped unlock 저장소, 순차 해금, locked silhouette, locked start 차단, 좌/우 rough tap, cloud progress max/earliest merge 구현
- [x] Sprint 4 Remove Midgame Interruptions: `GameConfig.enableMidGameCutscenes = false`와 mid cutscene 가드 적용
- [x] Sprint 5 Compact Map And Motion Tuning: runtime cell 25pt, 800x500 map, player speed 0.9 multiplier 적용
- [x] Sprint 6 Hospital Map Readability: 바닥/벽 색 대비 교체, wall tile 대비 유지, 충돌 없는 병실 props 8개 추가

## QA 개선 지시 반영
- [x] Airforce flow: `.cutscene` 전환과 `CutsceneOverlayNode` 호출 제거, `AirforceOverlayNode` 기반 non-blocking overlay로 복구
- [x] Apple auth ownership: `appleAuthorizationFlowID` guard와 owner-only clear를 추가해 중복 요청이 기존 continuation/controller/timeout을 정리하지 못하게 변경
- [x] Local fallback progress: auth profile nil + local fallback에서 기존 global score/graduation/preference를 scoped local key로 1회 merge
- [x] Hospital props placement: MapNode 좌표/크기 리터럴을 `GameConfig.hospitalPropPlacements`와 `hospitalPropSize(for:)`로 이동
- [x] Ingame palette: floor/wall 색상을 docs/assets.md 16색 팔레트 내 값으로 재선정
- [x] Non-blocking feedback toast: body/projectile/stethoscope/toilet/charm 피드백을 `ToastLabelNode.spawn(...)`로 복구, gameState 전환 없음
- [x] Charm toast constant: `매혹!` 문자열을 `GameConfig.charmStudentToastText`로 분리
- [x] Hospital prop palette: `.ganhoScrubMint`를 `.ganhoIngameRewardMint`로 교체해 docs/assets.md 16색 팔레트 내 토큰만 사용

## Swift 패턴 준수
- 강제 언래핑 미사용: 준수
- guard let 옵셔널 처리: 준수
- MARK 섹션 구분: 준수
- GameConfig 상수 사용: 준수
- weak self 캡처: 준수

## SpriteKit 패턴 준수
- didMove(to:)에서 초기화: 준수
- dt 기반 이동: 준수
- SKAction 스폰 패턴: 준수
- 충돌 후 노드 즉시 삭제 없음: 준수
- HUD 노드 분리: 준수

## 빌드 상태
- 예상 빌드 에러: 없음 (`xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -configuration Debug -destination "generic/platform=iOS Simulator" build` 성공)
- 주의 필요 경고: AppIntents.framework dependency 없음으로 metadata extraction skipped 경고가 남음. AppIntents 미사용 타겟의 fallback warning으로 빌드 성공에 영향 없으며, 이번 Generator 범위에서는 build setting을 건드리지 않고 잔여 경고로 명시
- diff 검사: `git diff --check` 통과

## 범위 외 미구현 항목
- HighScoreRepository/StatisticsRepository 전체 계정 분리: SPEC 범위 외라 미구현
- macOS/tvOS 템플릿 수정: iOS 타겟만 정식 대상이라 미수정
- QA_REPORT.md 수정: Generator 역할 범위 밖이라 미수정

## 필수 연동 변경
- GameScene 결과 저장 경로를 account-scoped PerDifficultyScoreRepository/GraduationRepository로 초기화
- ResultScene retry fallback preference를 현재 account scope로 조회
- Cloud pending flush progress snapshot도 unlock용 scoped repository 기준으로 저장
- CharacterSelectScene local fallback 진입 시 기존 global progress를 scoped local key로 1회 병합
