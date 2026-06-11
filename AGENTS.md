# AGENTS.md — GanhoMusic iOS

iOS 게임 "김간호는 음악박사 Mobile Edition". Swift 5.x + SpriteKit, Xcode 26.x.
45초 탑뷰 아케이드: 간호 실습생이 수간호사를 피해 음표를 모은다. 5캐릭터(스킬 4종)·4빌런·난이도 3종.

> 이 파일이 에이전트 지침의 **단일 진실 원천**이다. CLAUDE.md는 이 파일을 import하는 브리지다.
> 2026-06-10 이전의 완료된 Sprint 모드(v2 디자인 리뉴얼, Sprint 6~10)는 `docs/archive/CLAUDE_v2_legacy_2026-06-10.md` 참조.

## 프로젝트 구조

```
ganho-music-ios/
├── GanhoMusic/GanhoMusic.xcodeproj
├── GanhoMusic/GanhoMusic Shared/        ← 소스 (경로에 공백 있음 — 쉘에서 따옴표 필수)
│   ├── GameScene.swift + GameScene+*.swift   (인게임 오케스트레이터 + 11개 확장)
│   ├── Scenes/ Systems/ Nodes/ Models/ Config/ Managers/ Repositories/ Rendering(예정)/
│   └── Resources/Fonts/
├── GanhoMusic/GanhoMusic iOS/           ← iOS 타겟 (GameViewController 진입점)
├── refactor/                            ← 그랜드 리팩토링 v3 설계서 (현재 활성 작업)
├── docs/                                ← 규칙·분석 문서
├── REFACTOR_STATE.md                    ← v3 진행 상태
└── .claude/agents/                      ← planner / generator / evaluator
```

## 빌드·검증 명령

```bash
# 빌드 검증 (Evaluator 필수 실행)
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build 2>&1 | tail -40
```

- 타겟: iPhone 전용, iOS 16.0+, Landscape 전용
- 테스트 타겟 없음 (R6에서 마이그레이션 테스트 1파일 신설 예정)

## 핵심 규칙 (위반 시 P0/P1)

상세는 `docs/swift-rules.md` · `docs/spritekit-rules.md`. 요약:

- 강제 언래핑 `!`, `as!`, `Timer.scheduledTimer`, 게임 내 `DispatchQueue.asyncAfter`, `switch default` 금지
- 매직 넘버 금지 — `Config/` 도메인 상수만 (분할 전 한시적으로 `GameConfig`)
- `update()` 내 `addChild()` 반복 금지, 충돌 델리게이트 내 즉시 `removeFromParent()` 금지, 매 프레임 텍스처 생성 금지
- 클로저 `[weak self]` 필수, 1파일 1클래스, 300줄 초과 시 분리
- 노드를 alpha=0으로 숨겨 유지하는 좀비 패턴 금지 — 불용 노드는 삭제

## 불변 조건 (모든 작업 공통, 위반 = P0)

1. Firebase 인증·클라우드 저장 동작 보존 (공개 API 시그니처 유지)
2. UserDefaults 기존 키 문자열 불변 — 사용자 데이터 무손실
3. 게임 골격: 5캐릭터·4빌런·45초·난이도 3종(목표 70/50/40 — `GameplayTuning.targetScoreByDifficulty`가 진실)·스킬 4종
4. `PixelSprite.swift`·`PixelPalette.swift` 기존 16×20 데이터 byte-equal (신규 추가만 허용)
5. 번들 ID·서명·Info.plist 권한 불변

---

## 하네스: 3-에이전트 파이프라인

기능 변경/추가/리팩토링 요청 시 자동 실행. (단순 질문·코드 리뷰는 직접 처리)

```
요청 → ① planner → SPEC.md → ② generator → 코드 + SELF_CHECK.md
     → ③ evaluator → QA_REPORT.md → 판정 (합격 / 불합격→②, 최대 3회)
```

- **단계 0 (필수)**: `rm -f SPEC.md SELF_CHECK.md QA_REPORT.md`
- 에이전트 간 통신은 **파일로만** (SPEC/SELF_CHECK/QA_REPORT). 산출물 저장 확인 후 다음 단계.
- generator와 evaluator는 반드시 **서로 다른 서브에이전트**로 호출 (자기 평가 금지).
- 재시도 전략: 가중 6.0+ = Case A(같은 방향 정밀 수정) / 5.0~5.9 = Case B(접근 재검토) / 5.0 미만 = Case C(방향 전환).
- 채점 기준: `.claude/agents/evaluation_criteria.md` (작업 유형별 루브릭 포함).
- 3회 불합격 시 중단하고 사용자에게 보고.

### 완료 보고 형식

```
## 하네스 실행 완료
**변경 내용**: [한 줄] / **QA 반복**: X회 / **최종 점수**: [축별 + 가중 X.X/10]
```

---

## 현재 활성 작업: 그랜드 리팩토링 모드 — v3 "Night Shift"

트리거: "리팩토링 진행해줘" / "Sprint R[N] 진행해줘" / "R[N] 진행해줘"

전체 게임을 프리미엄 픽셀 톤으로 통일하고 엔진·게임필·메타 시스템·코드 구조를 재구축하는 R0~R8 파이프라인.
**단일 진실 원천: `refactor/` 설계서 4종** — 다른 문서와 충돌 시 refactor/ 우선.

| 문서 | 내용 |
|---|---|
| `refactor/00_MASTER_PLAN.md` | 비전·로드맵·합격 게이트·불변 조건 (최상위) |
| `refactor/01_CODE_ARCHITECTURE.md` | R0·R1: 타겟 구조·GameConfig 분할·삭제 목록 |
| `refactor/02_GAME_FEEL.md` | R2·R6·R7: 히트스톱·파티클·사운드·햅틱·메타 수치 |
| `refactor/03_UI_DESIGN_SYSTEM.md` | R3·R4·R5: 디자인 시스템 v3·컴포넌트·화면 사양 |

### 절차

1. **상태 확인**: `REFACTOR_STATE.md` 읽기 → 다음 Phase 결정 (R0→R8 순차. 직전 ✅면 다음, ❌면 재시도 최대 3회, 사용자 R[N] 명시 시 강제 실행)
2. **하네스 사이클** (위 파이프라인 그대로). Planner 프롬프트에 추가:
   ```
   refactor/00_MASTER_PLAN.md를 읽어라.
   현재 Phase의 주 설계서를 읽어라 (위 표 참조).
   00_MASTER_PLAN §5 불변 조건과 §4 해당 Phase 합격 게이트를 SPEC.md에 그대로 복사하라.
   설계서의 코드 인용이 실제 코드와 다르면 코드가 진실 — 차이를 SPEC.md에 기록하라.
   현재 Phase: R[N] / 범위: 00_MASTER_PLAN §3 로드맵 R[N] 행 + 주 설계서 해당 섹션
   ```
3. **채점**: 5축 — 패턴 20% / 기능 30% / 성능 20% / 시각 20% / 안정성 10%. 가중 7.5+ 합격. SELF_CHECK에 정량 게이트 측정치 필수.
4. **상태 갱신**: REFACTOR_STATE.md 해당 Phase 행 + 진행 로그 갱신. 커밋 `[R{N}] 요약`.

### 보고 형식 (Phase 단위)

```
## 리팩토링 R{N} 완료 — {Phase 이름}
- 변경 내용: [한 줄] / 수정 n·신규 m·삭제 k 파일
- 정량 게이트: [측정치] / QA 반복: X회 / 최종 점수: [5축 + 가중]
- 다음 Phase: R{N+1} 또는 "🎉 전체 완료"
```

### v2 조항 갱신

- v2의 "CharacterFaceNode·NurseAvatarNode 보호"는 **해제** (R4에서 픽셀 포트레이트로 대체 후 삭제).
- 인게임 픽셀 데이터 byte-equal 원칙은 계속 유효.

---

## 세션 시작 리추얼 (모든 작업 세션 공통)

1. `git status` + `git log --oneline -5` — 작업 트리 상태 확인
2. 진행 중 작업이면 상태 파일(`REFACTOR_STATE.md`) 확인
3. 작업은 한 번에 한 단위(1 Phase / 1 기능)만 — 완료 시 깨끗한 상태로 커밋 + 상태 기록 후 종료
