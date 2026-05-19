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
| `mockups/*.html` | 6개 시각 레퍼런스 (브라우저에서 확인) |
| `mockups/svg-exports/*.svg` | 5명 캐릭터 시안 (Sprint 4용) |
| `FIGMA_IMPORT_GUIDE.md` | PNG 자산 제작 가이드 (사용자용) |
