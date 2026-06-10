# Config/

**Spring 대응**: `config/` + `application.yml`
**역할**: 설정·상수 — 게임 수치, 연출 수치, 레이아웃, 색, 폰트, z-순서, 저장 키

Spring `config/` 와 의미상 동일. 차이점:
- Spring은 **외부 yml + Java config 클래스** 분리. Swift는 **`enum + static let`** 한 곳
- `enum` 을 namespace로 사용 (case가 없는 enum은 인스턴스화 불가 → 안전한 상수 그릇)

## 파일 구성 (R0 — 구 GameConfig 3,869줄을 도메인 7파일로 분할)

| 파일 | 역할 |
|---|---|
| `GameplayTuning.swift` | 이동·스폰·AI·스킬·콤보·난이도·맵 좌표 수치 + 좌표 헬퍼 4종 |
| `FeelTuning.swift` | 셰이크·플래시·팝업·페이드·카운트다운·텐션 등 연출 수치 + 연출 문구·SKAction 키 |
| `UILayout.swift` | 패널·카드·버튼·여백·오버레이 레이아웃 + 컴포넌트 국소 폰트크기·UI 문구 |
| `Palette.swift` | 색 hex 문자열 + UIColor 인스턴스 상수 (R3에서 v3 토큰으로 대체 예정) |
| `Typography.swift` | 전역 폰트 이름(`fontDisplay`/`fontBody`/`fontNumeric` 등) + `labelMinimumScale` |
| `ZOrder.swift` | zPosition 상수 전부 — 시각 적층 순서의 단일 진실 원천 |
| `StorageKeys.swift` | UserDefaults 키 + Firestore 컬렉션명 (**문자열 절대 불변**) + Auth 정책 수치 |
| `PhysicsCategory.swift` | 비트마스크 정의 (`player`, `note`, `enemy`, `obstacle`) |
| `GameState.swift` | 상태 enum (`waiting`, `playing`, `paused`, `gameOver`) |
| `ColorTokens.swift` | `UIColor` extension — 팔레트 토큰 (R3에서 Palette로 통합 예정) |
| `DeviceLayoutProfile.swift` / `SceneSafeArea.swift` | 디바이스별 레이아웃 프로파일·세이프에리어 헬퍼 |

## 설계 원칙

- **매직 넘버 금지** (`swift-rules.md` §7) — 모든 숫자 리터럴은 이 폴더로
- 동일 매직 넘버가 3곳 이상 등장 = 즉시 해당 도메인 파일로 이동
- **UserDefaults/Firestore 키는 예외 없이 `StorageKeys`** — 호출부 리터럴 노출 금지
- 상수 파일은 300줄 규칙 예외 (1파일 1도메인 책임 충족, 로직 0줄 — 순수 함수만 허용)

## 관련 문서

- `docs/swift-rules.md` §7 — 상수 관리 원칙
- `refactor/01_CODE_ARCHITECTURE.md` — R0 분할 설계
- `docs/assets.md` §1 — 16색 팔레트 (ColorTokens 매핑)
