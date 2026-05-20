# CLAUDE.md — GanhoMusic iOS

iOS 게임 앱 "김간호는 음악박사 Mobile Edition".
Swift + SpriteKit + SwiftUI. Xcode 프로젝트. GitHub Pages 웹 게임을 영감 삼아 모바일용으로 재설계.

## 프로젝트 구조

```
ganho-music-ios/
├── GanhoMusic/                          ← Xcode 프로젝트 루트
│   ├── GanhoMusic.xcodeproj/
│   └── GanhoMusic/                      ← 소스 파일
│       ├── GanhoMusic iOS/              ← iOS 타겟
│       │   ├── AppDelegate.swift
│       │   ├── GameViewController.swift ← SpriteKit 진입점
│       │   └── SceneDelegate.swift
│       └── GanhoMusic Shared/           ← 공용 게임 로직
│           ├── GameScene.swift          ← 메인 게임 씬 (핵심)
│           ├── GameScene.sks
│           └── Assets.xcassets/
├── .claude/
│   └── agents/
│       ├── planner.md
│       ├── generator.md
│       ├── evaluator.md
│       └── evaluation_criteria.md
├── docs/
│   ├── swift-rules.md
│   ├── spritekit-rules.md
│   └── components.md
└── CLAUDE.md
```

## 개발 환경

- Xcode 26.x / Swift 5.x
- 타겟: iPhone 전용, iOS 16.0+
- 화면: Landscape (가로) 전용
- 빌드: `⌘R` (시뮬레이터), 실기기는 Wi-Fi 페어링

## 핵심 파일

| 파일 | 역할 |
|---|---|
| `GanhoMusic Shared/GameScene.swift` | SpriteKit 메인 게임 씬. 게임 루프·오브젝트·충돌 전부 여기 |
| `GanhoMusic iOS/GameViewController.swift` | SKView에 씬을 올리는 iOS 진입점 |
| `GanhoMusic iOS/AppDelegate.swift` | 앱 생명주기 |

## 레퍼런스 문서

`docs/` 폴더 — 에이전트가 작업 전 반드시 읽는다:

- `docs/swift-rules.md` — Swift 코딩 컨벤션, 네이밍, 패턴
- `docs/spritekit-rules.md` — SpriteKit 노드/씬/물리/액션 패턴
- `docs/components.md` — 구현된 컴포넌트 목록, 작업 체크리스트

---

## 하네스: 기능 변경 파이프라인

사용자가 **기능 변경/추가**를 요청하면, 아래 3-Agent 파이프라인을 자동 실행합니다.
(단순 질문, 개념 설명, 코드 리뷰 등은 하네스 없이 직접 처리)

```
[사용자 요청]
      ↓
 ① Planner    → SPEC.md
      ↓
 ② Generator  → Swift 파일 수정 + SELF_CHECK.md
      ↓
 ③ Evaluator  → QA_REPORT.md
      ↓
 ④ 판정: 합격 → 완료 / 불합격 → ②로 (최대 3회)
```

### 단계 0: 이전 산출물 초기화 (필수)

Planner 호출 **전에** 반드시 삭제:
```bash
rm -f SPEC.md SELF_CHECK.md QA_REPORT.md
```

### 단계 1: Planner 호출

subagent_type: `planner`

```
.claude/agents/evaluation_criteria.md 파일을 읽고 참고하라.
docs/swift-rules.md, docs/spritekit-rules.md, docs/components.md를 읽어라.
GanhoMusic/GanhoMusic/GanhoMusic\ Shared/GameScene.swift를 읽어 현재 게임 상태를 파악하라.

사용자 요청: [사용자 프롬프트]

SPEC.md에 반드시 포함:
1. 변경 유형: 게임플레이 / 비주얼 / 혼합
2. 게임 경험 의도 (2~3문장)
3. Sprint 범위 계약

결과를 SPEC.md로 저장하라.
```

### 단계 2: Generator 호출

subagent_type: `generator`

최초:
```
SPEC.md를 읽고 Swift 코드를 구현하라. 완료 후 SELF_CHECK.md를 작성하라.
```

재실행(2회차+):
```
SPEC.md와 QA_REPORT.md를 읽어라.
QA 피드백의 "구체적 개선 지시"를 모두 반영하라.
완료 후 SELF_CHECK.md를 업데이트하라.
```

### 단계 3: Evaluator 호출

subagent_type: `evaluator`

```
SPEC.md, SELF_CHECK.md, docs/swift-rules.md, docs/spritekit-rules.md,
evaluation_criteria.md를 읽어라.
수정된 Swift 파일들을 읽고 채점하라.
결과를 QA_REPORT.md로 저장하라.
```

### 단계 4: 판정

- **합격** → 완료 보고
- **조건부/불합격** → Generator 재호출:
  - 6.0+: Case A — 같은 방향, 개선 지시 정밀 적용
  - 5.0~5.9: Case B — 낮은 점수 영역 접근법 재검토
  - 5.0 미만: Case C — 완전 방향 전환
- 최대 **3회** 반복

### 완료 보고 형식

```
## 하네스 실행 완료

**변경 내용**: [한 줄 요약]
**QA 반복**: X회
**최종 점수**: Swift패턴 X/10, 게임로직 X/10, 성능 X/10, 기능완성도 X/10 (가중 X.X/10)
```

### 주의사항

- **단계 0 필수**: Planner 전 산출물 파일 삭제
- **SPEC.md 검증**: Generator 전 파일 존재 확인. 없으면 직접 작성
- **QA_REPORT.md 검증**: Evaluator 후 파일 존재 확인
- Generator ≠ Evaluator — 반드시 다른 서브에이전트로 호출

---

## 디자인 리뉴얼 모드 (v2 디자인 시스템 적용)

사용자가 다음 트리거 중 하나를 말하면 **디자인 리뉴얼 모드** 진입:
- "디자인 리뉴얼 진행해줘"
- "리뉴얼 진행해줘"
- "다음 Sprint 진행해줘"
- "Sprint N 진행해줘" (특정 Sprint 지정)

이 모드는 위의 기본 하네스 파이프라인을 그대로 활용하되, **상태 추적 + 자동 Sprint 식별**이 추가됩니다.

### 자동 실행 절차

**0. 상태 확인 (필수 첫 단계)**

`DESIGN_RENEWAL_STATE.md` 파일을 읽어 다음을 파악:
- 현재 진행 중인 Sprint 번호
- 완료된 Sprint 목록
- 마지막 Evaluator 점수 / 시도 횟수

상태 파일이 없으면 **Sprint 1부터 시작** (DESIGN_RENEWAL_REQUEST.md §12 진행 순서 따름).

**1. 다음 Sprint 결정**

- 현재 Sprint가 "✅ 합격" → 다음 Sprint로 진행
- 현재 Sprint가 "❌ 불합격" → 같은 Sprint 재실행 (시도 횟수 +1)
- 3회 시도 초과 → 사용자에게 보고 후 중단
- 사용자가 "Sprint N" 명시 → 해당 Sprint 강제 실행

Sprint 4 (PNG)는 `mockups/svg-exports/` 폴더가 비어있으면 스킵 (자산 대기 상태).

**2. 하네스 호출 (기본 하네스 §단계 0~4 그대로)**

단계 0: `rm -f SPEC.md SELF_CHECK.md QA_REPORT.md`

단계 1: Planner 호출 — 프롬프트는 `DESIGN_RENEWAL_REQUEST.md §10` 의 Sprint 1 예시를 기반으로 다음을 추가:
```
디자인 시스템·화면 사양은 DESIGN_RENEWAL_REQUEST.md를 읽어라.
시각 레퍼런스는 mockups/[화면].html 파일을 브라우저에서 시각 확인할 것.
캐릭터 SVG 시안은 mockups/svg-exports/*.svg를 참고하라.

현재 Sprint: N
범위: DESIGN_RENEWAL_REQUEST.md §9 Sprint N 항목 그대로 따를 것.
변경 금지: DESIGN_RENEWAL_REQUEST.md §6 항목 절대 건드리지 말 것.
합격 기준: DESIGN_RENEWAL_REQUEST.md §11 적용.
```

단계 2~3: Generator → Evaluator (기본 하네스 동일)

단계 4: 판정 (기본 하네스 동일)

**3. 상태 갱신**

각 Sprint 완료 후 `DESIGN_RENEWAL_STATE.md`를 다음과 같이 갱신:
- 해당 Sprint 행의 상태 → "✅ 합격" (또는 "❌ 불합격")
- 점수·시도 횟수·완료 일자 기록
- 다음 Sprint 행의 상태 → "⏳ 대기"
- 진행 로그 섹션에 한 줄 요약 추가

**4. 사용자 보고 형식**

```
## Sprint N 완료 (디자인 리뉴얼)

- 변경 내용: [한 줄 요약]
- 수정 파일: [N개]
- QA 반복: X회
- 최종 점수: [상세]
- 다음 Sprint: N+1 ([Sprint 이름]) — 또는 "🎉 모든 Sprint 완료"
```

### 참고 문서 (디자인 리뉴얼 모드 전용)

| 파일 | 역할 |
|---|---|
| `DESIGN_RENEWAL_REQUEST.md` | 디자인 시스템·화면별 사양·합격 기준 (단일 진실 원천) |
| `DESIGN_RENEWAL_STATE.md` | Sprint 진행 상태 (하네스가 자동 갱신) |
| `SPRINT_6_REQUEST.md` | Sprint 6 작업지시서 (흐름 재편) |
| `SPRINT_7_REQUEST.md` | Sprint 7 작업지시서 (7 Phase 통합 — 카드·카운트다운·빌런·하이스코어) |
| `SPRINT_8_REQUEST.md` | Sprint 8 작업지시서 (7 Phase 통합 — 겹침 해소·카운트다운 가시화·박병장 데뷔·플레이어 팔다리) |
| `mockups/*.html` | 13개 시각 레퍼런스 — v2 6개 + v3 4개 + 신규 3개 (highscore-board / countdown-overlay / villains-and-player-directions) |
| `mockups/svg-exports/*.svg` | 5명 캐릭터 시안 (Sprint 4용) |
| `FIGMA_IMPORT_GUIDE.md` | PNG 자산 제작 가이드 (사용자용) |

---

## 디자인 리뉴얼 모드 — Sprint 7 Phase 모드 (확장)

Sprint 7은 단일 사이클이 아니라 **Phase A~G 7단계 순차 실행**이다. 트리거 `Sprint 7 진행해줘`가 들어오면 일반 디자인 리뉴얼 모드 위에 다음 절차가 추가된다.

### Phase 자동 실행 절차

**1. SPRINT_7_REQUEST.md 읽기 (필수 첫 단계)**

- §1 Phase 구조 표에서 7개 Phase 목록 확인
- `DESIGN_RENEWAL_STATE.md` Sprint 7 진행 로그에서 합격 Phase 확인 (없으면 Phase A부터)

**2. 다음 Phase 결정**

- 직전 Phase가 "✅ 합격" → 다음 Phase
- 직전 Phase가 "❌ 불합격" → 같은 Phase 재실행 (최대 3회)
- 사용자가 `Sprint 7 Phase X 진행해줘` 명시 → 해당 Phase 강제 실행

**3. Phase별 하네스 호출 (기본 하네스 §단계 0~4 그대로)**

단계 0: `rm -f SPEC.md SELF_CHECK.md QA_REPORT.md`

단계 1: Planner 프롬프트에 다음을 추가:
```
SPRINT_7_REQUEST.md를 읽어라. Sprint 7 작업지시서의 §[해당 Phase 섹션]을 그대로 따를 것.
관련 mockup HTML(mockups/[해당 파일].html)을 브라우저에서 시각 확인하라.
변경 금지 항목과 합격 기준을 SPEC.md에 그대로 복사하라.

현재 Phase: [A~G 중 하나]
범위: SPRINT_7_REQUEST.md §[해당 섹션] 그대로
```

단계 2~3: Generator → Evaluator (기본 하네스 동일)

단계 4: 판정 (기본 하네스 동일)

**4. Phase 합격 처리 — 상태 갱신**

- 가중 평균 7.5 이상 → DESIGN_RENEWAL_STATE.md "Sprint 7 — 진행 로그"에 `- Phase X ✅ 합격 (점수 X.X/10, 시도 X회)` 한 줄 추가
- 다음 Phase 자동 진행 (Phase G까지 완료 시 Sprint 7 전체 합격 처리)

**5. 사용자 보고 형식 (Phase 단위)**

```
## Sprint 7 Phase X 완료

- Phase: [A/B/C/D/E/F/G] — [이름]
- 변경 내용: [한 줄 요약]
- 수정 파일: [N개]
- QA 반복: X회
- 최종 점수: [상세]
- 다음 Phase: [X+1] 또는 "🎉 Sprint 7 전체 완료"
```

### Phase 의존성

A→B→C→D→E→F→G 순차 실행이 권장. Phase D는 Phase A·B·C 합격 후 실행 권장 (결과창 톤이 메뉴 톤과 일치해야 하므로). 사용자가 명시적으로 다른 순서를 요청하면 그것을 따른다.

### 사용자 의사결정 (사전 확정 — 2026-05-19)

Sprint 7 Planner는 다음 결정을 SPEC.md에 그대로 반영해야 한다:

1. **캐릭터 카드 디자인**: NIKKE는 구조만 차용 (세로 카드/등급 배지/속성 헥사 아이콘/CD 칩/속도 칩), 톤은 현재 코랄·피치 카툰 유지
2. **신규 빌런 박병장**: 공군 병장 + 선글라스 컨셉 (공군 청록 `#3A6F7F` + 항공 캡 + 골드 날개 휘장 + 검은 선글라스 + 골드 v자 2줄 계급장 + 가슴 PARK 명찰)
3. **하이스코어 화면 진입점**: 결과창의 "📊 기록 보기" 칩만 (메인·미니칩 진입은 Sprint 7 외 후속 작업)

---

## 디자인 리뉴얼 모드 — Sprint 8 Phase 모드 (확장)

Sprint 8도 Sprint 7과 동일한 **Phase A~G 7단계 순차 실행** 구조다. 트리거 `Sprint 8 진행해줘`가 들어오면 일반 디자인 리뉴얼 모드 위에 다음 절차가 추가된다.

### Phase 자동 실행 절차

**1. SPRINT_8_REQUEST.md 읽기 (필수 첫 단계)**

- §1 Phase 구조 표에서 7개 Phase 목록 확인
- `DESIGN_RENEWAL_STATE.md` Sprint 8 행에서 합격/대기 Phase 확인 (없으면 Phase A부터)

**2. 다음 Phase 결정**

- 직전 Phase가 "✅ 합격" → 다음 Phase
- 직전 Phase가 "❌ 불합격" → 같은 Phase 재실행 (최대 3회)
- 사용자가 `Sprint 8 Phase X 진행해줘` 명시 → 해당 Phase 강제 실행

**3. Phase별 하네스 호출 (기본 하네스 §단계 0~4 그대로)**

단계 0: `rm -f SPEC.md SELF_CHECK.md QA_REPORT.md`

단계 1: Planner 프롬프트에 다음을 추가:
```
SPRINT_8_REQUEST.md를 읽어라. Sprint 8 작업지시서의 §[해당 Phase 섹션]을 그대로 따를 것.
관련 mockup HTML(mockups/[해당 파일].html)을 브라우저에서 시각 확인하라.
변경 금지 항목과 합격 기준을 SPEC.md에 그대로 복사하라.

현재 Phase: [A~G 중 하나]
범위: SPRINT_8_REQUEST.md §[해당 섹션] 그대로
사용자 의사결정 7건은 SPRINT_8_REQUEST.md §14를 SPEC.md에 그대로 복사할 것.
```

단계 2~3: Generator → Evaluator (기본 하네스 동일)

단계 4: 판정 (기본 하네스 동일)

**4. Phase 합격 처리 — 상태 갱신**

- 가중 평균 7.5 이상 → DESIGN_RENEWAL_STATE.md "Sprint 8" 행을 "✅ 합격"으로 갱신 + 진행 로그에 상세 한 줄 추가
- 다음 Phase 자동 진행 (Phase G까지 완료 시 Sprint 8 전체 합격 처리)

**5. 사용자 보고 형식 (Phase 단위)**

```
## Sprint 8 Phase X 완료

- Phase: [A/B/C/D/E/F/G] — [이름]
- 매핑 이슈: 사용자 지적 #[번호] ([스크린샷])
- 변경 내용: [한 줄 요약]
- 수정 파일: [N개]
- QA 반복: X회
- 최종 점수: [상세]
- 다음 Phase: [X+1] 또는 "🎉 Sprint 8 전체 완료"
```

### Phase 의존성

A→B→C→D 메뉴 4씬 정리 → E 인게임 시작 시퀀스 → F HUD/스킬 zPos → G 인게임 시각 통합 순차 실행 권장. Phase G가 가장 무거우므로 (LOC ~600) 마지막 배치. 사용자가 명시적으로 다른 순서를 요청하면 그것을 따른다.

### 사용자 의사결정 (사전 확정 — 2026-05-20)

Sprint 8 Planner는 SPRINT_8_REQUEST.md §14의 10개 결정 사항을 SPEC.md에 그대로 복사 — 요약:

1. **캐릭터 선택**: 스와이프 페이지 (중앙 1장 + 양옆 반쯤)
2. **캐릭터 시각 2계층**: 선택=얼굴만(CharacterFaceNode) · 인게임=풀바디(CharacterFullBodyNode 신규)
3. **풀바디 마스터 레퍼런스**: NurseAvatarNode SVG path·zPosition 순서 차용 (5명 × 4방향 = 20셀)
4. **박병장 등장 트리거**: hard 난이도에서 30초 OR 50점 중 더 빠른 쪽 1회
5. **박병장 컷씬 길이**: 2.2초 (얼굴 클로즈업 + 토스트)
6. **빌런 PixelSprite**: 노드 보존 + alpha 0으로 시각만 차단
7. **PlayerNode 좌우**: CharacterFullBodyNode 내 left/right 별도 path (mirroring 금지)
8. **비행기 자식**: fuselage / wings / tail / cockpit / propeller (+ contrail 옵션)
9. **HUD 좌하단 중복 라벨**: SkillButtonNode 본체 스킬 이름 라벨 제거, HUDSkillSlotNode가 단일 진실 원천
10. **CharacterFaceNode·NurseAvatarNode 본체 보호**: git diff 0줄 유지
