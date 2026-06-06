# Internal Review - 2026-06-02 Device Feedback Plan

## 검토 결론

스프린트 분해는 적절하다. 작은 회귀성 수정(Result, mid interruption)과 큰 구조 변경(Apple auth, account-scoped unlock, map tuning, hospital readability)을 분리했다. 특히 Sprint 3은 데이터 scope와 UI lock state가 함께 얽혀 있으므로 단독 대형 스프린트로 유지해야 한다.

## 요구사항 매핑

| 사용자 피드백 | 대응 Sprint | 검토 |
|---|---|---|
| 결과화면 메인 버튼 없음, 빈 공간 누르면 메인 이동 | Sprint 1 | 명시 버튼 추가 + fallback tap 제거로 해결 가능 |
| Apple 로그인이 busy에서 멈춤 | Sprint 2 | controller retain + timeout + UI recovery 필요 |
| 캐릭터 선택 좌우 러프 탭 | Sprint 3 | 버튼 hit-test 이후 side zone 처리 |
| 캐릭터 순차 해금, locked 실루엣, 계정별 구조 | Sprint 3 | 가장 큰 변경. account scope/cloud read까지 포함해야 함 |
| 결과화면 NEW BEST 위치 애매 | Sprint 1 | 결과 레이아웃과 같이 처리 |
| 장애물/배경 색 혼동, 병실 분위기 | Sprint 6 | visual-only props와 색 토큰 변경으로 분리 |
| 맵 더 축소, 이동속도 살짝 하향 | Sprint 5 | tileSize와 speed multiplier를 같이 조정 |
| 게임 중간 멘트 제거 | Sprint 4 | mid1/mid2만 비활성화하는 것이 정확 |

## 의존성 검토

- Sprint 1은 독립적이다.
- Sprint 2는 Sprint 3 전에 하는 것이 좋다. 계정별 진행도는 auth profile 안정성이 선행되어야 한다.
- Sprint 3은 Sprint 2 이후에 해야 한다. Apple login이 불안정하면 "계정별" QA가 어렵다.
- Sprint 4는 독립적이지만 Sprint 5/6 플레이 테스트 전에 적용하면 테스트 노이즈가 줄어든다.
- Sprint 5는 Sprint 6 전에 하는 것이 좋다. 최종 맵 크기에 맞춰 병실 props 위치를 잡아야 한다.
- Sprint 6은 visual-only 중심으로 유지하면 Sprint 5 밸런스에 영향을 덜 준다.

## 큰 리스크

### 1. 계정별 진행도 범위

사용자는 "로그인한 계정마다 다른 구조"라고 말했다. 단순히 unlock만 scoped로 두면 high score/stat이 섞여 보일 수 있다. 하지만 모든 저장소를 한 번에 account-scoped로 바꾸면 migration 리스크가 커진다.

권장 판정:

- Sprint 3의 필수 범위는 unlock 판단 저장소 scoped.
- high score/stat 전체 계정 분리는 선택 범위로 SPEC에서 다시 결정한다.
- Apple 계정의 cloud progress read는 포함하는 쪽이 맞다. 저장만 있고 읽기가 없으면 "계정마다 다른" 느낌이 불완전하다.

### 2. Apple login 외부 설정

코드상 controller 생명주기 문제가 의심되지만, Apple Developer/Firebase provider 설정 문제일 가능성도 있다. 코드 수정 후에도 실패할 수 있으므로 Sprint 2 QA에 외부 설정 확인 항목을 포함해야 한다.

### 3. 맵 축소와 난이도 상승

tileSize 25 + speed 90%는 합리적인 1차값이지만, 맵 축소는 적/투사체 밀도를 올린다. Sprint 5는 반드시 easy/normal/hard 모두 1판 진입 테스트가 필요하다.

### 4. 병실 props의 시각 오해

decor가 충돌체처럼 보이면 플레이어가 헷갈린다. Sprint 6은 "병실 느낌"보다 "장애물과 배경의 구분"을 우선한다.

## 범위 조정 제안

구현 중 시간이 부족하면:

1. Sprint 1은 반드시 완료한다. 결과 화면 오작동은 UX 회귀가 크다.
2. Sprint 2는 controller retain + timeout만 먼저 완료해도 효과가 크다.
3. Sprint 3은 최소 버전과 확장 버전을 나눈다.
   - 최소: local account-scoped unlock + silhouette + rough tap.
   - 확장: Firestore progress read/merge.
4. Sprint 5는 tileSize 25와 speed multiplier만 먼저 적용하고, 추가 스폰 튜닝은 QA 피드백 후 한다.
5. Sprint 6은 색 대비를 먼저 고치고, 병실 props는 다음 iteration으로 넘겨도 된다.

## 최종 승인 상태

계획서는 구현 착수 가능한 수준이다. 다만 Sprint 3은 SPEC 작성 시 다음 두 가지를 사용자/작업자 기준으로 다시 고정해야 한다.

- 다음 캐릭터 해금 조건: "이전 캐릭터 졸업"으로 할지, "이전 캐릭터 하 난이도 목표 달성"으로 완화할지.
- 계정별 진행도 범위: unlock만 우선인지, high score/stat까지 함께 분리할지.

