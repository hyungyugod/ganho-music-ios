# 2026-06-02 Refactor Sprint Plan

실기기 테스트에서 나온 큰 변경 요청을 하루 작업 단위로 나눈 계획서다. 이 폴더는 구현 전 검토용이며, 사용자가 특정 스프린트 실행을 지시하면 해당 문서를 SPEC 작성의 기준으로 삼는다.

## 문서 목록

| Sprint | 문서 | 목적 |
|---|---|---|
| 1 | `sprint-1-start-login-overlay.md` | 첫 화면을 단순화하고 로그인 선택 오버레이를 만든다. |
| 2 | `sprint-2-character-account-home.md` | 캐릭터 선택 화면을 계정 홈/로비 화면으로 전면 재설계한다. |
| 3 | `sprint-3-difficulty-polish.md` | 난이도 선택 화면의 시작 버튼 halo와 캐릭터 비율 문제를 정리한다. |
| 4 | `sprint-4-result-share-fix.md` | 결과 화면의 공유/자랑하기 기능을 실기기에서 안정화한다. |
| 5 | `sprint-5-compact-map-rescale.md` | 장애물 패턴은 유지하면서 맵을 화면 크기에 가깝게 파격 축소한다. |

## 실행 원칙

- 사용자가 "Sprint N 진행해줘"라고 말하면 해당 Sprint 문서를 읽고 AGENTS 하네스 절차를 실행한다.
- 구현 스프린트 시작 전에는 반드시 `SPEC.md`, `SELF_CHECK.md`, `QA_REPORT.md`를 삭제한다.
- 현재 저장소에는 `.Codex/agents`가 없고 `.claude/agents`와 `.codex/agents/*.toml`이 존재한다. 실제 하네스 호출 시 사용 가능한 에이전트/도구를 먼저 확인한다.
- 스프린트 간 의존성은 1 -> 2 -> 3 -> 4 -> 5 순서를 기본으로 한다. 단, Sprint 4는 결과 화면 공유만 다루므로 Sprint 1/2와 병렬 검토 가능하다.
- 기능 추가가 아닌 계획 문서 작성 단계에서는 Swift 코드를 수정하지 않는다.

## 공통 품질 기준

- Swift: 강제 언래핑 금지, `guard let`/`if let`, `MARK:` 구분, `GameConfig` 상수화.
- SpriteKit: `didMove(to:)` 초기화, HUD/월드/카메라 좌표계 분리, `update()` 내 노드 생성 금지.
- UI: iPhone landscape safe area 기준으로 텍스트 겹침, 잘림, 과밀 배치를 먼저 막는다.
- 데이터: UserDefaults 저장소와 Firebase/Auth 흐름은 기존 저장 포맷을 깨지 않는다.
- 검증: 가능하면 iPhone landscape 시뮬레이터 빌드, 터치 플로우, 결과 화면, 맵 플레이 1판을 확인한다.

## 오늘의 큰 방향

첫 화면은 더 조용하게 만들고, 인증 선택은 명확한 오버레이로 분리한다. 캐릭터 선택 화면은 단순 카드 선택 화면이 아니라 플레이어의 "계정 홈"이 되도록 재디자인한다. 난이도/공유/맵은 각각 독립 위험이 있으므로 후속 스프린트에서 작게 닫는다.
