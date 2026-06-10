# Managers/

**Spring 대응**: `managers/`
**역할**: 공통 보조 — 사운드, 햅틱, 분석 (싱글톤 패턴)

Spring `managers/` 와 의미상 동일. 차이점:
- Spring `@Component` 어노테이션 없음 → **`static let shared` 싱글톤 패턴**으로 직접 표현
- `private init()` 으로 외부 인스턴스화 차단

## 현재 파일

| 파일 | Phase | 역할 |
|---|---|---|
| `ChiptuneSynth.swift` | R2 | 프로시저럴 8비트 SFX — AVAudioEngine + 사전 렌더 PCM 버퍼 (구 AudioManager 시스템 사운드 전폐) |
| `HapticsManager.swift` | 4 / R2 | CoreHaptics v2 패턴 + `UIImpactFeedbackGenerator` 폴백 |
| `BGMPlayer.swift` | 6-4 | 자작 BGM 무한 루프 (음원 부재 시 noop) |
| `CloudSaveCoordinator.swift` / `FirebaseAuthManager.swift` | 7+ | 클라우드 저장 / 인증 |

## 싱글톤 사용 원칙

- 앱 전체에서 1개만 존재해야 하는 자원 (오디오 엔진, 네트워크 클라이언트)
- 도메인 로직(Systems)에서 무분별하게 참조하지 말고, 가능하면 의존성 주입으로

## 관련 문서

- `docs/architecture-mapping.md` §2-5 — Managers 변환 룰
- `docs/assets.md` §4 — 사운드 정책
