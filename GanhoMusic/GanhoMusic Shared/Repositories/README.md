# Repositories/

**Spring 대응**: `mappers/` (MyBatis)
**역할**: 외부 데이터 접근 — UserDefaults (로컬 저장), Supabase (서버, Phase 7+)

Spring `mappers/` 와 동일한 자리. 차이점:
- MyBatis XML/어노테이션이 아니라 **Swift 메서드 안에 직접** 데이터 접근 코드 작성
- 서버 호출은 `async/await` (Spring `CompletableFuture` 와 비슷하지만 더 간결)

## 향후 들어올 파일

| 파일 | Phase | 역할 |
|---|---|---|
| `ScoreRepository.swift` | 3 | UserDefaults 최고 점수 저장 / 조회 |
| `LeaderboardRepository.swift` | 7 | Supabase 서버 점수 업/다운로드 |

## 설계 원칙

- 외부 시스템(UserDefaults, Supabase)에 대한 의존성을 이 폴더에 격리한다.
- 도메인 로직(Systems)은 Repository를 직접 참조하지 않고 **추상(protocol)** 통해 호출 — 테스트 가능성 확보.

## 관련 문서

- `docs/architecture-mapping.md` §2-3 — Mappers → Repositories 변환 룰
- `docs/BACKEND.md` — Supabase 연동 (Phase 7)
