# Nodes/

**Spring 대응**: 없음 (게임 고유)
**역할**: 살아있는 시각 객체 — 데이터(model) + 그림(view) + 자기 행위(controller 일부)가 한 클래스에 응축

Spring 멘탈 모델로 보면 가장 헷갈리는 영역. **자기 자신의 시각/물리 상태**는 Node 안에 두지만, **여러 객체에 걸친 규칙(점수 산정·스폰 등)** 은 Systems로 빼야 한다.

## 향후 들어올 파일

| 파일 | Phase | 역할 |
|---|---|---|
| `PlayerNode.swift` | 1 | 김간호 캐릭터 (이동·HP·Shield) |
| `NoteNode.swift` | 2 | 음표 ♪ |
| `EnemyNode.swift` | 2 | 수간호사 NPC |
| `ProjectileNode.swift` | 2 | F 투사체 |
| `HUDNode.swift` | 2 | 점수/타이머/콤보 표시 |

## 관련 문서

- `docs/spritekit-rules.md` §2 (노드 계층 구조), §11
- `docs/architecture-mapping.md` §2-8 — Nodes는 왜 Spring에 없는가
