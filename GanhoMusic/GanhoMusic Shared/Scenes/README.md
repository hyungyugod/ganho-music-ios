# Scenes/

**Spring 대응**: `controllers/`
**역할**: 사용자 입력 → 시스템(Systems) 위임 → 씬 전환

게임 흐름의 지휘자. 비즈니스 로직을 직접 구현하지 않고, Systems와 Nodes에 메시지를 전달한다.

## 향후 들어올 파일

| 파일 | Phase | 역할 |
|---|---|---|
| `GameScene.swift` | 1 (현재 `Shared/` 직속에 있음, Xcode 그룹 이동 필요) | 메인 게임 루프 |
| `TitleScene.swift` | 3 | 타이틀 화면 |
| `GameOverScene.swift` | 3 | 결과 화면 |
| `LeaderboardScene.swift` | 7 | 리더보드 |

## 관련 문서

- `docs/spritekit-rules.md` §11 — 디렉터리 구조
- `docs/architecture-mapping.md` §2-1 — Controllers → Scenes 변환 룰
