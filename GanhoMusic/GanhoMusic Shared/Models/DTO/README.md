# Models/DTO/

**역할**: 서버(Supabase) 통신용 DTO 전용 폴더 (Phase 7+)

도메인 모델과 분리해 서버 스키마 변경의 영향을 격리한다.

## 향후 들어올 파일

| 파일 | 역할 |
|---|---|
| `ScoreDTO.swift` | scores 테이블 매핑 |
| `ProfileDTO.swift` | profiles 테이블 매핑 |
| `LeaderboardEntryDTO.swift` | leaderboard 뷰 매핑 |

## 컨벤션

- 모든 DTO는 `Codable` 채택
- 서버 필드명이 snake_case면 `CodingKeys` 로 매핑
- 도메인 모델로 변환하는 `toDomain()` 메서드 권장
