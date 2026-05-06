# Managers/

**Spring 대응**: `managers/`
**역할**: 공통 보조 — 사운드, 햅틱, 분석 (싱글톤 패턴)

Spring `managers/` 와 의미상 동일. 차이점:
- Spring `@Component` 어노테이션 없음 → **`static let shared` 싱글톤 패턴**으로 직접 표현
- `private init()` 으로 외부 인스턴스화 차단

## 향후 들어올 파일

| 파일 | Phase | 역할 |
|---|---|---|
| `AudioManager.swift` | 4 | BGM (`AVAudioPlayer`) + 효과음 (`SKAction.playSoundFileNamed`) |
| `HapticsManager.swift` | 4 | iPhone 햅틱 피드백 (`UIImpactFeedbackGenerator`) |
| `AnalyticsManager.swift` | 4+ | 이벤트 로깅 (선택) |
| `SupabaseManager.swift` | 7 | Supabase 클라이언트 보유 |

## 싱글톤 사용 원칙

- 앱 전체에서 1개만 존재해야 하는 자원 (오디오 엔진, 네트워크 클라이언트)
- 도메인 로직(Systems)에서 무분별하게 참조하지 말고, 가능하면 의존성 주입으로

## 관련 문서

- `docs/architecture-mapping.md` §2-5 — Managers 변환 룰
- `docs/assets.md` §4 — 사운드 정책
