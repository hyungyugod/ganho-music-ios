# 개선 백로그 — v3 "Night Shift" 완료 후 전면 검토 (2026-06-11)

> v3 R0~R8 전 Phase 합격 직후, "게임이 더 발전하기 위한" 개선 기회를 4영역(코드 위생·게임플레이·UX·메타)
> 병렬 탐색으로 수집하고, 헤드라인급 주장은 오케스트레이터가 코드로 직접 검증한 결과.
> 우선순위 티어는 **유저 체감 → 게임성 → 리텐션 → 코드 기반** 순. 규모: S(반나절) / M(1~2일) / L(Phase급).

## 검증 노트 (에이전트 보고 중 직접 확인한 것)

- ✅ **백그라운드 복귀 무방비**: `GanhoMusic iOS/SceneDelegate.swift:33` — `sceneWillResignActive` 빈 템플릿 확인.
- ✅ **매혹 게임당 1회**: `Models/PlayerSkill.swift:47` cooldown `.infinity` + `oncePerGame` 확인 (의도된 설계 — 밸런스 재검토 대상).
- ✅ **엔드리스 모드 미구현**: 코드 0건, `refactor/02_GAME_FEEL.md:143`에 스펙만 존재 (별 30 해금·10s마다 발사 간격 ×0.93·피격 시 종료·별도 리더보드 셀).
- ✅ **설정 토글 부재**: Managers/ 전역에 isMuted/hapticEnabled류 0건.
- ✅ **로컬 알림 0건**: UNUserNotificationCenter 참조 없음.
- ❌ **기각 — "다시하기가 캐릭터 선택 강제"**: `ResultScene.swift:217` transitionToRetry()는 같은 캐릭터·난이도로 GameScene 직행. 이미 최적 동선.
- ⚠️ **정정 — PrivacyInfo.xcprivacy는 존재** (`GanhoMusic iOS/`): 매니페스트는 있고, 인앱 정책/크레딧 *링크*만 없음.

---

## 유저 요청 6건 — R9/R10 배정 확정 (2026-06-11)

> 사용자 직접 요청 항목. 오케스트레이터가 각 항목의 현재 코드 상태를 조사·진단한 결과를 포함하므로,
> Phase 실행 시 planner는 이 섹션을 SPEC의 1차 입력으로 사용한다.

### U1. Apple 로그인 "잠시 후 다시 시도" 튕김 — R9 · **P1 최우선** · 규모 M

**증상**: Apple 시트에서 인증을 완료해도 로그인 다이얼로그가 "잠시 후 다시 시도"(`UILayout.loginChoiceFailureText`)로 복귀.

**진단 (원인 2중 — 오케스트레이터 코드 추적 완료)**:
1. **소비된 1회용 토큰 재사용 (주원인 — 재로그인 유저 구조적 100% 재현)**
   - `GanhoMusic iOS/AppDelegate.swift:21` ensureLaunchSession() → 익명 세션이 기동 시 항상 존재
   - `Managers/FirebaseAuthManager.swift:275` signInOrLinkAppleCredential — currentUser.isAnonymous라 항상 link() 먼저
   - 해당 Apple ID가 과거 다른 Firebase 계정에 연동돼 있으면 link()가 `credentialAlreadyInUse` 실패 → L282에서 **원본 credential을 그대로** signIn() 재시도
   - Apple ID 토큰은 1회용 — link() 시도가 서버에서 이미 소비 → 재사용 signIn()은 `missingOrInvalidNonce`(17094, "Duplicate credential received") 거절
   - `AuthErrorMapper`(L464)에 missingOrInvalidNonce 미매핑 → nil 반환 → `StartScene+Auth.swift:198` `.none` 케이스 → "잠시 후 다시 시도"
2. **12초 타임아웃 레이스 (부원인)**: `Config/StorageKeys.swift:55` authAppleRequestTimeout = 12.0 — 최초 연동 동선(이메일 공유 선택·이름 편집·암호 입력)은 12초를 쉽게 초과. 타임아웃이 continuation을 실패로 종료해도 Apple 시트는 계속 떠 있어, 유저가 뒤늦게 인증을 완료해도 결과가 버려짐(`finishAppleAuthorization` L376 — continuation nil no-op).

**수정 방향**:
- (필수) link 실패 catch에서 `(error as NSError).userInfo[AuthErrorUserInfoUpdatedCredentialKey] as? AuthCredential` 추출 → 그 credential로 signIn (Firebase 공식 패턴)
- (필수) authAppleRequestTimeout 12 → 60s + 타임아웃 발화 시 iOS 16+ `controller.cancel()`로 시트 동반 철회
- (권장) AuthErrorMapper에 `.missingOrInvalidNonce`·`.networkError` 매핑 추가(전용 카피)
- 불변 조건 1 준수: FirebaseAuthManager **공개 API 시그니처 무변경** (수정은 private 경로 한정)
- **검증 시나리오**: 실기기 "Apple 연동 → 로그아웃 → 재연동" — 정확히 이 경로가 깨지는 지점

### U2. 프로필에서 기록·업적 진입 — R9 · 규모 M
- 현재: 기록/업적은 Result→Scoreboard [기록] 버튼으로만 접근. 프로필 다이얼로그(ProfileDetailOverlayNode)에는 이름 편집·로그아웃·탈퇴뿐.
- 제안: 프로필 다이얼로그에 [기록]·[업적] 버튼 행 추가 → ScoreboardScene을 **초기 탭 파라미터**와 함께 present(팩토리 인자 추가 — 기존 lastUpdatedKey 패턴 동형). 복귀는 backward 라우트.

### U3. 로그아웃·회원탈퇴 버튼 축소 — R9 · 규모 S
- 현재: `ProfileDetailOverlayNode+Content.swift:36·42` — signOut=secondary, **탈퇴=primary coral(가장 강한 시각 위계)**. 파괴적 액션이 제일 눈에 띄는 역설.
- 제안: 두 버튼을 compact 높이 + ghost/secondary 위계로 강등하고 다이얼로그 최하단 배치. U2의 [기록]/[업적]이 주 위계를 차지.

### U4. D-Pad 조작감 — R10 · 규모 M
- 현재 (`Nodes/DPadNode.swift` + `Config/GameplayTuning.swift:96-117`): 터치 반경 76 / 아날로그 최대 58 / 데드존 8 / 썸 노브 18 / 축 스냅 우세비 1.35(가로·세로 스냅 콘 ±36.5°, 사이 구간은 raw 대각).
- 요청 매핑 (수치는 ±20% 룰 내 generator 재량):
  - "범위가 작다·시원시원하게" → dpadTouchRadius 76→~88, dpadAnalogMaxRadius 58→~66
  - "대강 오른쪽이면 오른쪽으로" → dpadAxisSnapDominanceRatio 1.35→~1.15 (스냅 콘 ±41° 확대)
  - "가운데 원 살짝 크게" → dpadThumbRadius 18→~22 (버튼·링 시각 비례 동반 검토)
  - "더 부드러워도" → 방향 벡터 급변 시 짧은 스무딩(~80ms lerp) 또는 PlayerNode 가감속 보간 — 판정·속도 상한 불변 전제
- 주의: Direction(vector:) 4방향 facing 매핑·이동 속도 곡선 불변.

### U5. 박병장 데뷔 연출 강화 — R10 · 규모 M
- 현재 (`GameScene+DailyModifiers.swift:91-159`): 줌 펄스 0.97/0.5s + 2.2s 인라인 컷씬(dim·클로즈업·토스트) + heavy 햅틱 2회 + 우→중앙 진입 1.2s·8s 체류·좌 퇴장.
- 강화 후보 (기존 시스템 재사용 원칙): CameraDirector 방향성 킥+셰이크 / BombFlashNode 패턴 화면 플래시 / EffectDirector 충격파·스파크 파티클(동시 캡 8 준수) / ChiptuneSynth 전용 데뷔 스팅어 Voice(init 사전 렌더 규칙) / 진입 보행 발걸음 미니 셰이크 / 토스트 스탬프 등장(easeOutBack).
- 제약: 컷씬 2.2s 타이밍·completion 계약 보존, hard 최악 281노드 → 파티클 풀링 필수, 런타임 텍스처 생성 0.

### U6. 박병장×석조무사 "오랜 친구" 스토리 씬 — R10 · 규모 M
- 인프라 기존재: CutsceneOverlayNode + 정적 팩토리 3종(Intro/IntroVillain/Mid) + CutsceneTexts 단일 진실 원천 — 신규 씬은 이 패턴 동형으로.
- 제안: ① 데뷔 컷씬을 우정 서사 버전으로 확장(석조무사 동시 재맵 시 분기) 그리고/또는 ② 데뷔 후 박병장이 석조무사 곁을 지날 때 1회 상호 인사 연출(말풍선·스파크) — 발화 1회 플래그는 기존 데뷔 플래그 패턴 동형.
- 카피는 게임 정체성(자전적 유머 톤) 보존 — SPEC에 카피 초안을 포함하고 **사용자 검수 권장 포인트**로 표기.

---

## Tier 1 — 출시 기본기 (유저가 5분 안에 체감하는 구멍)

| # | 항목 | 근거 | 제안 | 규모 |
|---|---|---|---|---|
| 1 | **사운드·햅틱 설정 토글 부재** | ChiptuneSynth/BGMPlayer/HapticsManager 전부 전역 on/off 없음. iOS 물리 음량 버튼이 유일한 수단 | 설정 다이얼로그(PixelDialog 재사용): 효과음/BGM/햅틱 토글 3종. StorageKeys 신규 키 3개 + 각 Manager에 enabled 게이트 1줄씩. Start 우상단 + 일시정지 메뉴 양쪽 진입 | M |
| 2 | **전화·알림 복귀 시 기습** | SceneDelegate.swift:33 빈 스텁. SpriteKit이 렌더링은 자동 정지하지만 복귀 즉시 재개 → 반응 시간 0으로 피격 | sceneWillResignActive → 인게임 .playing이면 기존 v3 일시정지 경로 호출(다이얼로그 완비라 배선만). NotificationCenter 1회 구독 | S |
| 3 | **첫 판 조작 온보딩 부재** | 인트로 컷씬은 스토리 텍스트만(GameScene+Cutscene). D-Pad·스킬 버튼 안내 0 | 최초 1판 한정(UserDefaults 플래그) 시작 3초 힌트 오버레이: D-Pad 화살표 펄스 + "드래그로 이동" / 스킬 버튼 글로우 + 한 줄. 자동 소멸 | M |
| 4 | **개인정보처리방침·크레딧 진입점 없음** | Firebase Auth/Firestore 사용 — App Store 심사 시 정책 URL 필수. 폰트(Galmuri 등) 라이선스 표기처도 없음 | #1 설정 다이얼로그에 [개인정보처리방침]·[크레딧] 행 추가(SFSafariViewController). xcprivacy 내용물 최신화 검수 동반 | S~M |

## Tier 2 — 게임플레이 심화 (게임이 "재밌어지는" 것)

| # | 항목 | 근거 | 제안 | 규모 |
|---|---|---|---|---|
| 5 | **스킬 4종 효율 편차** | 돌진(정간호): 회피+경로 음표 흡수+F 정화+무적 0.22s+착지 연장 0.35s를 22s 쿨로 전부 / 매혹: 게임당 1회 영구 소진(PlayerSkill.swift:47) | (a) 매혹을 쿨다운제(18~20s)로 전환하거나 1회 가치 증폭(지속 4→8s 등) (b) 돌진 무적 0.22→0.15s 검토(착지 연장은 보존). activationCount 데이터로 발동 빈도 실측 후 결정 권장 | M |
| 6 | **수간호사 패트롤 단조** | nurseChiefWaypointsByDifficulty — 난이도별 좌표 동일, 속도만 차이. 완전 예측 가능한 4점 시계방향 순환 | 난이도별 루트 분화(easy 사각 / normal 8자 / hard 사각+대각 혼합) 또는 N초마다 순회 방향 반전. 이교수 8자 패턴 코드 재사용 가능 | M |
| 7 | **목표 달성 순간 무신호** | 70/50/40 도달해도 연출 0 → 잔여 시간 "그냥 더 모으기". 45초 곡선의 마지막 동기 공백 | 달성 순간: 화면 플래시+"목표 달성!" 토스트+햅틱 1회(이미 있는 토스트/플래시 패턴 재사용). 선택: 잔여 시간 점수 ×1.5 보너스 배율 | S~M |
| 8 | **음표 수집 미니 히트스톱** | 가장 빈번한 행위(초당 1회+)에 히트스톱 0 — 파티클+햅틱뿐. 변기는 0.03s 있음 | FeelTuning에 noteCollect 0.015s 추가(지각 임계 ~30ms 절반). 콤보 마일스톤 히트스톱과 longer-wins 합성은 기존 로직 그대로 | S |
| 9 | **결과창 숨은 통계** | comboBreaks·toiletsCollected 기록되나(ScoreSystem) 결과창 미표시 — 업적 판정 전용 | 결과창에 칩 2종 추가("끊김 n회"·"변기 n개"). 별 행 아래 가로 배치 | S~M |
| 10 | **초반 10초 압박 공백** | easy 첫 발사 3.5s + 가속은 10s부터(FeelTuning+R7 pacedFireProgress) — "준비 단계" 톤 | waveFirstPressureElapsed 10→5s 또는 난이도별 초기 발사 간격 -15~20%(±20% 룰 내). R7 페이싱 철학과 정합 확인 필수 | S |
| 11 | **near-miss 기준 안내 부재** | 가장자리 10px 셸 판정이 UI 어디에도 설명 없음 — 발화해도 유저가 원리 모름 | 스킬 브리핑 씬에 1줄("F를 아슬하게 스치면 콤보 연장!") 또는 온보딩(#3)에 통합 | S |

## Tier 3 — 리텐션·메타 (계속 돌아오게)

| # | 항목 | 근거 | 제안 | 규모 |
|---|---|---|---|---|
| 12 | **엔드게임 공백 — 엔드리스 모드** | 별 45/45 이후 목표 0. 02_GAME_FEEL.md:143에 스펙 기존재(별 30 해금·45초 후 계속·10s마다 발사 간격 ×0.93·피격 시 종료·별도 기록 셀) — 코드만 없음 | 설계서 스펙 그대로 구현. 신규 모드 1개가 45별 그라인드 전체에 의미 부여 — 리텐션 개선 기대 최대 항목 | L |
| 13 | **일일 도전 streak 부재** | 클리어 보너스 min(3, earned×2) 1회성. 연속 출석 개념 0 | dailyStreak 카운터(어제 dayKey 클리어 여부로 +1/리셋) + 7일 달성 보너스. 클라우드 머지는 max | S |
| 14 | **로컬 알림 0건** | 재방문 트리거 전무 — 자발적 방문에만 의존 | 일일 도전 리셋 알림 1종(옵트인, 설정 #1에 토글 동거). UNUserNotificationCenter 최소 구현 | S~M |
| 15 | **리더보드 전무** | GKLeaderboard 0건. Firebase에 점수 저장하면서 비교 기능 없음 | Game Center 연동(하이스코어 + 엔드리스 거리). Firebase 자체 랭킹보다 구현·운영 비용 낮음 | L |
| 16 | **누적 통계 미노출** | playCount·totalScore 외 10+종이 기록만 되고 안 보임 | Scoreboard 3번째 탭 [통계]: 총 판수·누적 음표·평균 점수·난이도별 승률 | M |
| 17 | **숨은 업적 여지** | 16종 전부 달성 후 목표 없음 | 비밀 업적 3~4종(콤보 30·변기 누적 10·streak 7·노스킬 hard 졸업 등 — #13과 연계) | S~M |

## Tier 4 — 코드 기반 (개발 속도 보호)

| # | 항목 | 근거 | 제안 | 규모 |
|---|---|---|---|---|
| 18 | **순수 로직 단위 테스트 부재** | 검증 수단이 MetaMigrationSelfTest(DEBUG 1파일)뿐. ScoreSystem·MetaProgression·AchievementEvaluator는 의존성 없는 순수 로직 | R6에서 pbxproj 위험으로 기각했던 테스트 타겟 결정 재검토. 대안: 셀프테스트 파일 패턴 확장(GANHO_*_SELFTEST) — 이미 검증된 방식 | L |
| 19 | **캐릭터/난이도 enum 확장 비용** | 6번째 캐릭터 = switch 11곳 + 별 15→18셀 + UI 그리드 + 클라우드 스키마 검토 | 지금 결정만: "5캐릭터 고정 선언"(타 차원 확장 집중) vs "데이터 구동 전환"(L). 콘텐츠 로드맵에 따라 택1 | 결정 S / 전환 L |
| 20 | **씬별 텍스처 캐시 분산** | CharacterSelect 등이 로컬 캐시 보유 — R1 TextureAtlasStore 일원화 원칙과 불일치 | 정적 캐시 또는 TextureAtlasStore 확장으로 통합 | M |
| 21 | **ObjectPool 재사용 자식 노드 잔존 가능성** | resetForReuse가 본체 상태만 복구 — 자식(텔레그래프 등) 명시 제거 미확인 | resetForReuse에 removeAllChildren() 또는 DEBUG assert로 검증 먼저 | S |
| 22 | **ColorTokens init(hex:) silent fallback** | 잘못된 hex → 조용히 검은색 | DEBUG assert 추가(조기 발견) | S |
| 23 | **StartScene 309줄 + 칩 생성 중복** | R8 이관 기록 기존재. refreshProfileChip/refreshDailyChallengeChip 40% 중복 | +Layout 분리 시 공통 칩 빌더 추출 동반 | S |
| 24 | **update 경로 미세 최적화** | 음표 자석 매 프레임 전 음표 순회 등. 단 현재 281노드/60fps로 여유 | 성능 문제 실측 전까지 보류 — 필요 시 자석 2~4프레임 양자화 | M(보류) |

## 보류 — 의사결정 필요

- **로컬라이제이션**: 전 텍스트 한글 하드코딩(200+ 추정, Localizable.strings 없음). 글로벌 출시 의향이 있어야만 가치 있는 L급 작업 — **의향 결정이 선행**.
- **색약 대응**: 난이도(mint/gold/coral)·verdict(mint/coral)가 색 의존. 텍스트 라벨이 이미 병기되어 있어 심각도는 낮음 — 여유 시 아이콘 보강.
- **iPad 레이아웃 최적화**: iPhone 우선 정책과 상충 — 현행 유지 권장.

## 확정 패키징 (2026-06-11 사용자 지시 반영 — 유저 요청 6건 통합)

| Phase | 이름 | 구성 | 비고 |
|---|---|---|---|
| **R9** | 계정·시스템 기본기 | **U1 Apple 로그인 픽스(P1 최우선)** · U2 프로필 기록/업적 진입 · U3 로그아웃/탈퇴 버튼 강등 · #1 설정(사운드/햅틱) · #2 백그라운드 자동 일시정지 · #3 첫 판 온보딩 · #4 정책/크레딧 링크 | 전부 "게임 밖"(메뉴·계정·시스템). U1부터 착수 |
| **R10** | 조작감·연출·스토리 | U4 D-Pad 조작감 · U5 박병장 데뷔 강화 · U6 우정 스토리 씬 (+여유 시 #8 음표 미니 히트스톱 동승) | 전부 "게임 안"(입력·연출·콘텐츠) |
| R11 | 게임필 2차 | #5 스킬 밸런스 · #6 수간호사 패턴 · #7 목표 달성 연출 · #9 결과창 통계 · #10 초반 페이싱 · #11 near-miss 안내 | activationCount 실측 선행 권장 |
| R12 | 리텐션 | #12 엔드리스(주력) · #13 streak · #14 알림 · #17 숨은 업적 | 02_GAME_FEEL.md:143 스펙 기존재 |
| R13 | 기반 | #18 테스트 전략 · #19 확장성 결정 · Tier 4 잔여 | — |

- 하네스 실행 시 planner 주 설계서 = **이 문서**(유저 요청 §U1~U6 + 해당 Tier 표). `refactor/00_MASTER_PLAN.md` §5 불변 조건은 그대로 적용.
- 채점·재시도·보고 형식은 AGENTS.md 하네스 절차 그대로.
