# Systems/

**Spring 대응**: `services/` (+ `schedulers/` 흡수)
**역할**: 게임 도메인 로직 — 점수 계산, 스폰, 비트 동기, 입력 해석

Spring `services/` 와 의미상 동일. 차이점:
- 작을 때는 `protocol + 단일 클래스` 가 아닌 **단일 클래스만**으로 시작 (Spring의 `interface + impl` 강제 분리는 Swift에서 보통 과함)
- Phase 7(테스트 도입) 이후 protocol 분리

`schedulers/` 는 별도 폴더가 아닌 **각 시스템 안에서 `SKAction.repeatForever`** 로 구현.

## 향후 들어올 파일

| 파일 | Phase | 역할 |
|---|---|---|
| `InputSystem.swift` | 1 | 스와이프 / 터치 입력 해석 |
| `SpawnSystem.swift` | 2 | 음표·적·투사체 스폰 |
| `ScoreSystem.swift` | 2 | 점수·콤보·등급·Shield 계산 |
| `BeatSystem.swift` | 2 | BPM 동기화 / On-Beat 판정 |

## 관련 문서

- `docs/spritekit-rules.md` §4 (액션 패턴)
- `docs/architecture-mapping.md` §2-2 — Services → Systems 변환 룰
- `docs/architecture-mapping.md` §2-7 — schedulers 흡수 패턴
