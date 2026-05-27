# QA 검수 보고서

## SPEC 기능 검증
- [PASS] 기능 1: F/청진기 발사 전 경고선이 유지되며, `EnemyNode`는 텔레그래프 시점의 `pendingShotAngles`를 실제 발사에 재사용한다.
- [PASS] 기능 2: Enemy/StoneGuard/Professor 접근 위험 링은 init에서 1회 생성되고 `updateDangerWarnings()`에서 alpha/scale/action만 갱신된다.
- [PASS] 기능 3: 투사체/청진기 near-miss pulse, 플레이어 주변 near-miss 링, 피격 순간별 feedback helper가 구현되었다.
- [PASS] 기능 4: 난이도별 경고량은 `GameConfig.warningProfileByDifficulty`와 fallback으로 관리되며 실제 속도/간격/점수 수치는 변경하지 않았다.

## 이전 QA 개선 지시 확인
- [PASS] 1) 플레이어 주변 near-miss 경고 노드 연결: `PlayerNearMissWarningNode`가 추가되고 `PlayerNode.updateNearMissWarning(...)`를 통해 연결됨.
- [PASS] 2) `DangerWarningProfile` 숫자 리터럴을 `GameConfig`로 이동: `DangerWarningProfile`은 값 타입 필드만 보유하고 수치는 `GameConfig`에 위치함.
- [PASS] 3) `GameScene+DangerWarnings.swift` 분리 및 `GameScene.swift` 300줄 미만: `GameScene.swift` 282줄.
- [PASS] 4) telegraph blink 액션 키 상수화: `EnemyTelegraphNode`, `ProfessorTelegraphNode` 모두 `GameConfig.telegraphBlinkActionKey` 사용.

## 빌드 검증
- 결과: SKIP
- 비고: 필수 명령의 `platform=iOS Simulator,name=iPhone 15` 대상이 현재 환경에 없어 실행 불가. 사용 가능한 시뮬레이터 목록에 iPhone 15가 없음.
- 보조 확인: `generic/platform=iOS Simulator` 빌드는 `BUILD SUCCEEDED`.

## 검수 기준 비고
- 요청 경로 `.Codex/agents/evaluation_criteria.md`는 존재하지 않아 동일 기준 파일인 `.claude/agents/evaluation_criteria.md`를 참고했다.
- 이전 dirty baseline으로 보이는 결과 화면/콤보/컬렉션 관련 변경은 감점에서 제외했다.

## 검수 결과 요약

| 등급 | 건수 |
|---|---:|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## P0 — 치명적 이슈
없음.

## P1 — 중요 이슈
없음.

## P2 — 권장 사항
없음.

## 통과 항목
- 강제 언래핑 신규 위험 패턴 없음. 검색 결과의 `!`는 부정 연산자 또는 문자열이다.
- 이번 스프린트 변경 범위에서 `Timer`/`DispatchQueue` 사용 없음. `BGMPlayer.swift`의 `DispatchQueue`는 기존 baseline으로 판단했다.
- contact callback에서 직접 즉시 삭제하지 않고 `deferRemoveAfterContact` 또는 contact 외부 SKAction 경로를 사용한다.
- `worldNode.enumerateChildNodes`는 `"projectile"`과 `"stethoscope"`로 제한되어 전체 child 순회가 아니다.
- 신규 파일은 `Nodes/`, `Models/`, `GameScene+DangerWarnings.swift` extension 구조로 분리되었고 Xcode project sources에 등록되었다.
- `GameScene.swift`는 282줄로 300줄 기준을 만족한다.
- 매혹된 F는 `GameScene+DangerWarnings.swift`의 플레이어 near-miss 거리 집계에서 제외되어 보상 상태 projectile이 위험 링을 켜지 않는다.

---

## 채점

**항목별 점수**:
- Swift 패턴 일관성: 8.2/10
- 게임 로직 완성도: 8.2/10
- 성능 & 안정성: 8.2/10
- 기능 완성도: 8.3/10
- **가중 점수**: 8.2/10

## 최종 판정: 합격

**구체적 개선 지시**:
없음.
