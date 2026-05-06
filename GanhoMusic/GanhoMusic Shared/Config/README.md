# Config/

**Spring 대응**: `config/` + `application.yml`
**역할**: 설정·상수 — 게임 시간, BPM, 비트마스크, 색상 토큰, 상태 enum

Spring `config/` 와 의미상 동일. 차이점:
- Spring은 **외부 yml + Java config 클래스** 분리. Swift는 **`enum + static let`** 한 곳
- `enum` 을 namespace로 사용 (case가 없는 enum은 인스턴스화 불가 → 안전한 상수 그릇)

## 향후 들어올 파일

| 파일 | Phase | 역할 |
|---|---|---|
| `GameConfig.swift` | 1 | 게임 상수 (`gameDuration`, `bpm`, `playerSpeed` 등) |
| `PhysicsCategory.swift` | 1 | 비트마스크 정의 (`player`, `note`, `enemy`, `obstacle`) |
| `GameState.swift` | 1 | 상태 enum (`waiting`, `playing`, `paused`, `gameOver`) |
| `ColorTokens.swift` | 1 | `UIColor` extension — 16색 팔레트 (assets.md §1) |

## 설계 원칙

- **매직 넘버 금지** (`swift-rules.md` §7) — 모든 숫자 리터럴은 이 폴더로
- 동일 매직 넘버가 3곳 이상 등장 = 즉시 `GameConfig` 로 이동

## 관련 문서

- `docs/swift-rules.md` §7 — 상수 관리 원칙
- `docs/architecture-mapping.md` §2-6 — Config 변환 룰
- `docs/assets.md` §1 — 16색 팔레트 (ColorTokens 매핑)
