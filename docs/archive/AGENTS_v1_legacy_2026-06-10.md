# AGENTS.md — GanhoMusic iOS

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
├── .Codex/
│   └── agents/
│       ├── planner.md
│       ├── generator.md
│       ├── evaluator.md
│       └── evaluation_criteria.md
├── docs/
│   ├── swift-rules.md
│   ├── spritekit-rules.md
│   └── components.md
└── AGENTS.md
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
.Codex/agents/evaluation_criteria.md 파일을 읽고 참고하라.
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
