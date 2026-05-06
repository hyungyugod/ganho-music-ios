# Models/

**Spring 대응**: `models/`
**역할**: 값 객체 (Value Object)

Spring `models/` 와 의미상 동일. 차이점:
- **`class` 가 아닌 `struct`** 가 기본 (Swift는 값 타입 우선)
- Lombok 불필요 — 프로퍼티 자동 게터/세터, `Codable` 한 줄로 JSON 직렬화
- 불변 우선 — `let` 기본, 변경 필요할 때만 `var`

## 향후 들어올 파일

| 파일 | Phase | 역할 |
|---|---|---|
| `Score.swift` | 3 | 점수 + 등급 + 날짜 |
| `BeatTiming.swift` | 2 | 비트 타이밍 데이터 |
| `Grade.swift` | 3 | S/A/B/C 등급 enum |
| `DTO/ScoreDTO.swift` | 7 | 서버 통신용 DTO |
| `DTO/ProfileDTO.swift` | 7 | Apple Sign In 사용자 정보 |

## DTO 분리 원칙

도메인 모델(`Score`)과 서버 통신용 DTO(`ScoreDTO`)는 **분리**한다.
- 도메인 모델은 게임 내부에서만 쓰는 의미를 표현
- DTO는 서버 스키마를 그대로 따름 (snake_case 필드명 등)
- Repository에서 변환 책임

## 관련 문서

- `docs/swift-rules.md` §2 — struct vs class 선택 원칙
- `docs/architecture-mapping.md` §2-4 — Models 변환 룰
