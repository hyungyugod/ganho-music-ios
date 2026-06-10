# CLAUDE.md — GanhoMusic iOS

@AGENTS.md

## Claude Code 전용 보충

- 하네스 서브에이전트: `.claude/agents/`의 `planner` / `generator` / `evaluator`. AGENTS.md의 파이프라인 절차에 따라 Task 도구(subagent_type)로 호출한다. generator와 evaluator를 같은 세션에서 겸하지 말 것.
- 산출물 게이트: 각 단계 후 SPEC.md / SELF_CHECK.md / QA_REPORT.md 파일 존재를 확인하고 다음 단계로 진행. 없으면 해당 에이전트를 재호출.
- 대규모 Phase(R4·R5·G급)는 plan mode로 먼저 계획을 검토한 뒤 실행을 권장.
- 같은 문제로 2회 연속 실패하면 컨텍스트를 비우고(`/clear`) 더 구체적인 프롬프트로 재시작하는 편이 낫다.
- 경로 공백 주의: `GanhoMusic/GanhoMusic Shared/...`는 쉘에서 반드시 따옴표로 감싼다.
