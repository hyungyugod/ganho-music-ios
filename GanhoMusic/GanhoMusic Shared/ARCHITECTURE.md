# GanhoMusic Shared/ — 아키텍처 인덱스

이 폴더는 iOS / tvOS / macOS 타겟이 공유하는 게임 로직 영역.
**Spring(clonebose) 폴더 명을 의도적으로 차용**하여 멘탈 모델 전환 비용을 줄임.

## 디렉터리 한눈에

| 폴더 | Spring 대응 | 역할 | 자세히 |
|---|---|---|---|
| `Scenes/` | `controllers/` | 입력 → 시스템 위임 | [Scenes/README](Scenes/README.md) |
| `Nodes/` | (게임 고유) | 살아있는 시각 객체 | [Nodes/README](Nodes/README.md) |
| `Systems/` | `services/` (+ `schedulers/`) | 게임 도메인 로직 | [Systems/README](Systems/README.md) |
| `Repositories/` | `mappers/` | 외부 데이터 접근 | [Repositories/README](Repositories/README.md) |
| `Models/` | `models/` | 값 객체 (struct) | [Models/README](Models/README.md) |
| `Managers/` | `managers/` | 공통 보조 (싱글톤) | [Managers/README](Managers/README.md) |
| `Config/` | `config/` | 설정·상수 | [Config/README](Config/README.md) |
| `Errors/` | `exceptions/` (얇게) | enum: Error | [Errors/README](Errors/README.md) |
| `Resources/` | `resources/` | .sks, 이미지, 폰트, 사운드 | [Resources/README](Resources/README.md) |

## 의존성 방향 (반드시 준수)

```
Scenes/        ──→ Systems/ ──→ Repositories/ ──→ (외부)
   │              │
   ├──→ Nodes/   │
   │              ├──→ Models/
   ├──→ Managers/ ←──┘
   │
   └──→ Config/  (어디서나 참조 가능)
```

**금지**:
- `Repositories/` → `Scenes/` 또는 `Systems/` (역방향 의존)
- `Models/` → 다른 폴더 (Models는 데이터만 — 의존성 없음이 원칙)
- `Config/` → 다른 폴더 (상수만)

## 자세한 매핑·변환 룰

- `docs/architecture-mapping.md` — Spring → Swift/SpriteKit 변환 룰 (코드 예시 포함)
- `docs/spritekit-rules.md` §11 — 권장 디렉터리 구조 + 분리 판단 기준
