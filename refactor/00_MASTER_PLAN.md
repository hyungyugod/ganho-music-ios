# 00_MASTER_PLAN — 그랜드 리팩토링 v3 "Night Shift"

> 단일 진실 원천. 이 문서가 DESIGN_RENEWAL_REQUEST.md(v2)·SPRINT_N_REQUEST.md와 충돌하면 **이 문서 계열(refactor/)이 우선**한다.
> 본 설계서의 파일:라인 인용이 실제 코드와 다르면 **코드가 진실**이며, Planner는 차이를 SPEC.md에 기록한다.

---

## 1. 비전

**"김간호는 음악박사"를 앱스토어 프리미엄 무료게임 수준으로 끌어올린다.**

| 순위 | 목표 | 정의 |
|---|---|---|
| 1 | 재미·중독성·엔진 부드러움 | 60fps 안정, 히트스톱·파티클·카메라 연출 완비, 메타 진행 시스템으로 "한 판 더" 루프 완성 |
| 2 | UI 전면 리뉴얼 | 모던 레트로 픽셀 디자인 시스템 v3로 메뉴·인게임 시각 언어 통일. 카툰/픽셀 충돌 해소 |
| 3 | 교과서적 코드 | god-config 해체, dead code 0, 중복 0, 의존 방향 단방향, 오브젝트 풀·레지스트리 도입 |

### 확정된 사용자 의사결정 (2026-06-10)

1. **아트 방향: 프리미엄 픽셀 통일** — 인게임 픽셀 유지·고급화 + 메뉴도 모던 레트로 픽셀 톤으로 전면 재구축. v2 카툰(코랄·파스텔·크림) 메뉴는 폐기.
2. **게임플레이: 메타 풀패키지** — 코어 45초 룰 유지 + 별·레벨·언락·일일 도전·업적·점진 난이도 추가.
3. **UI 기술: SpriteKit 재구축** — SwiftUI 전환 없음. 기존 하네스·규칙 체계 그대로 활용.

### v2 보호 조항 해제 (중요)

CLAUDE.md의 v2 시절 조항 "CharacterFaceNode·NurseAvatarNode 본체 보호(git diff 0줄)"는 **v3에서 해제**된다. 두 노드는 R4에서 픽셀 포트레이트로 **대체 후 삭제**된다. 단, 인게임 `PixelSprite.swift`/`PixelPalette.swift`의 **원본 16×20 캐릭터 데이터는 byte-equal 유지**(신규 스프라이트 추가는 허용).

---

## 2. 문서 맵

| 문서 | 내용 | 주 사용 Phase |
|---|---|---|
| `refactor/00_MASTER_PLAN.md` | 비전·Phase 로드맵·합격 기준·불변 조건 | 전체 |
| `refactor/01_CODE_ARCHITECTURE.md` | 타겟 구조·GameConfig 분할·삭제 목록·패턴 | R0·R1 중심 |
| `refactor/02_GAME_FEEL.md` | 엔진·juice·사운드·햅틱·메타 시스템 수치 명세 | R1·R2·R6·R7 |
| `refactor/03_UI_DESIGN_SYSTEM.md` | 디자인 시스템 v3·컴포넌트·화면별 사양·모션 | R3·R4·R5 |
| `refactor/AGENT_PROMPT.md` | 실행 에이전트용 마스터 프롬프트 사본 | — |
| `REFACTOR_STATE.md` (루트) | Phase 진행 상태 (하네스가 자동 갱신) | 전체 |

기존 문서 중 계승: `docs/swift-rules.md`, `docs/spritekit-rules.md`(금지 패턴 전부 유효), `docs/GDD.md`(게임 룰), `docs/ORIGINAL_GAME_ANALYSIS.md`(원본 수치 근거).

---

## 3. Phase 로드맵 (R0~R8, 순차 실행)

각 Phase는 독립적으로 빌드 가능·검증 가능해야 한다. 1 Phase = 1 하네스 사이클(Planner→Generator→Evaluator).

| Phase | 이름 | 핵심 산출 | 의존 |
|---|---|---|---|
| **R0** | 기반 정리 (행동 불변) | dead code·좀비 노드 제거, GameConfig 분할, 버전 suffix 상수 정리, 중복 로직 프로토콜 추출 | — |
| **R1** | 엔진 코어 | EntityRegistry, 오브젝트 풀 3종, 바닥 타일 단일화, 텍스처 아틀라스, update 파이프라인 명시화 | R0 |
| **R2** | 게임필 (juice) | 히트스톱, 카메라 v2, SKEmitterNode 파티클 6종, 트윈 라이브러리, 칩튠 SFX 신스, 햅틱 v2, 플레이어 속도 곡선 활성화 | R1 |
| **R3** | 디자인 시스템 v3 인프라 | Palette/Typography/Spacing/ZOrder 토큰, Pixel 컴포넌트 키트 6종, SceneRouter 전환 통일 | R0 |
| **R4** | 메뉴 씬 재구축 | Start·CharacterSelect·SkillBriefing·DifficultySelect 전면 재구축, SVG 노드 폐기 | R3 |
| **R5** | 결과·기록·프로필 재구축 | ResultScene 제로 재작성(별·XP 연출 포함), Scoreboard, 계정 오버레이 픽셀화 | R3, R4 |
| **R6** | 메타 시스템 | 별·레벨(XP)·캐릭터 언락 개편·일일 도전·업적 20종·MetaProgressRepository | R5 |
| **R7** | 페이싱·콘텐츠 튜닝 | 웨이브 페이싱, near-miss 보너스, 콤보 게이지 가시화, 난이도 곡선 재조정. (스트레치: 엔드리스 모드) | R2, R6 |
| **R8** | 통합 QA·릴리즈 준비 | 성능 감사, 패턴 grep 감사, 전 씬 스크린샷, 문서 갱신(components.md 등) | 전체 |

권장 순서: R0 → R1 → R2 → R3 → R4 → R5 → R6 → R7 → R8.
R3는 R1·R2와 병렬 가능하지만, 단일 에이전트 순차 실행을 기본으로 한다.

---

## 4. Phase별 합격 기준 (Evaluator 5축)

채점: **패턴 준수 20% / 기능 완성도 30% / 성능 20% / 시각 품질 20% / 안정성 10%** — 가중 7.5 이상 합격, 최대 3회 재시도.

Phase별 정량 게이트(미충족 시 해당 축 6점 이하):

- **R0**: 빌드 성공. `GameConfig.swift` 단일 파일 소멸(분할 완료). 버전 suffix 상수(`V4`·`V7`·`V9`·`V12` 등) grep 0건. 01_CODE_ARCHITECTURE §6 삭제 목록 전부 처리. 전 씬 진입 스모크 통과(기능 회귀 0).
- **R1**: `update()` 경로 내 `enumerateChildNodes` 0건. 인게임 평시 노드 수 ≤300 (측정치 SELF_CHECK에 보고). 바닥 타일 노드 640→1. 풀에서 재사용 확인 로그.
- **R2**: 02_GAME_FEEL §2~§6 체크리스트 항목별 구현 + 명세 수치 일치. 히트스톱 디버그 토글 존재.
- **R3**: 토큰 파일 4종 + Pixel 컴포넌트 6종 컴파일·단독 렌더 확인. 03_UI §2~§4 수치 일치.
- **R4**: 4개 씬 신규 레이아웃 완성. `CharacterFaceNode`·`NurseAvatarNode` 참조 0건 후 파일 삭제. v2 카툰 토큰 참조 0건. 씬별 스크린샷 `visual-qa/refactor-r4/` 저장.
- **R5**: ResultScene 라인 수 ≤600(현 1,477). alpha=0/isHidden 좀비 노드 0개. 별·XP 연출 03_UI §7 일치.
- **R6**: 02_GAME_FEEL §7 수치 일치. 앱 재시작 후 메타 데이터 영속 확인. **기존 최고기록·졸업 데이터 마이그레이션 보존**(손실 시 P0).
- **R7**: 02_GAME_FEEL §8 튜닝 표 일치. near-miss 판정 동작.
- **R8**: 금지 패턴 grep 전체 0건(강제 언래핑·Timer·asyncAfter·매직넘버 신규 유입). 최종 감사 보고서.

---

## 5. 전 Phase 공통 불변 조건 (위반 = P0)

1. **Firebase 인증·클라우드 저장 동작 보존** — `FirebaseAuthManager`, `CloudSaveCoordinator`, Repository들의 공개 API 시그니처 유지. 내부 정리는 R0에서 허용.
2. **기존 사용자 데이터 무손실** — UserDefaults 키 변경 금지(키 목록은 R0 Planner가 추출해 SPEC에 고정). 스키마 추가만 허용.
3. **게임 골격 유지** — 5캐릭터(kim/jung/geon/im/lee)·4빌런·45초·난이도 3종(목표 70/50/40 — `GameplayTuning.targetScoreByDifficulty`가 진실, 구 기재 60/50/30은 R8 감사 문서-코드 불일치 #10으로 정정)·스킬 4종 메커니즘. 수치 튜닝은 02_GAME_FEEL 명세 범위 내에서만.
4. **인게임 원본 픽셀 데이터** — `PixelSprite.swift`·`PixelPalette.swift`의 기존 16×20 데이터 byte-equal. 신규 데이터 추가는 허용.
5. **빌드 설정** — 번들 ID·서명·Info.plist 권한·iOS 16.0+·Landscape 전용 불변.
6. **docs/swift-rules.md·spritekit-rules.md 금지 패턴** 전부 유효 (강제 언래핑·Timer.scheduledTimer·DispatchQueue.asyncAfter(게임 내)·as!·switch default·매직넘버·update 내 addChild 반복·델리게이트 내 즉시 removeFromParent·매 프레임 텍스처 생성).

---

## 6. 실행 프로토콜 (하네스 연동)

AGENTS.md(CLAUDE.md가 import)의 "그랜드 리팩토링 모드" 절차를 따른다. 요약:

```
트리거: "리팩토링 진행해줘" / "Sprint R[N] 진행해줘"
0. REFACTOR_STATE.md 읽기 → 다음 Phase 결정
1. rm -f SPEC.md SELF_CHECK.md QA_REPORT.md
2. Planner: refactor/00 + 해당 Phase의 주 설계서(§2 문서 맵) + 현재 코드 → SPEC.md
   - 본 문서 §5 불변 조건을 SPEC.md에 그대로 복사
   - 해당 Phase 합격 게이트(§4)를 SPEC.md에 그대로 복사
3. Generator: 구현 + SELF_CHECK.md (정량 게이트 측정치 포함)
4. Evaluator: 5축 채점 + xcodebuild 검증 → QA_REPORT.md
5. 합격 → REFACTOR_STATE.md 갱신 + 다음 Phase / 불합격 → 재시도 (최대 3회)
```

빌드 검증: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' build` (기존 QA와 동일 대상).

### 커밋 규율

- Phase당 1커밋 이상, 메시지 형식: `[R{N}] {요약}` (예: `[R0] GameConfig 7분할 + dead code 412줄 제거`)
- Phase 시작 전 working tree clean 확인. 불합격 재시도는 같은 브랜치에서 수정 커밋.

---

## 7. 리스크와 대응

| 리스크 | 대응 |
|---|---|
| R4에서 메뉴 전면 교체 중 회귀 | R3 컴포넌트를 먼저 완성·검증 후 R4 진입. 씬 단위로 커밋 분리 |
| 메타 데이터 마이그레이션 실패 | R6 합격 게이트에 "기존 기록 보존" P0 명시. 마이그레이션 단위 테스트 작성 |
| 픽셀 폰트 미확보 | 03_UI §3의 폰트 확보 절차(다운로드/검증/fallback 체인) 선행. 미확보 시에도 빌드·실행 가능해야 함 |
| Phase 범위 폭주 | SPEC.md의 "Sprint 범위 계약" 관행 유지. 스트레치 골(엔드리스 등)은 명시된 것 외 금지 |
| 시뮬레이터로 fps 검증 한계 | 성능 축은 코드 검수(풀링·캐싱·노드 수) 중심으로 채점. 실기기 프로파일은 R8 체크리스트에 기록만 |
