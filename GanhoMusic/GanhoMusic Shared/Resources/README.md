# Resources/

**Spring 대응**: `resources/` (templates/ + static/)
**역할**: 정적 자산 — `.sks` 씬 파일, `Assets.xcassets`, 폰트, 사운드 파일

## 현재 상황

기존 자산은 아직 `GanhoMusic Shared/` **직속**에 있다:

```
GanhoMusic Shared/
├── Actions.sks          ← 옮길 후보
├── GameScene.sks        ← 옮길 후보
├── Assets.xcassets/     ← 옮길 후보
└── Resources/           (이 폴더, 현재 비어있음)
```

**Xcode 그룹 이동은 .pbxproj 파일을 건드리므로 클로드코드 또는 Xcode에서 직접** 수행한다.

## 향후 들어올 자산

| 자산 | Phase | 비고 |
|---|---|---|
| `GameScene.sks` | (이동) | 기존 |
| `Actions.sks` | (이동) | 기존 |
| `Assets.xcassets/` | (이동) | 기존 |
| `Fonts/DungGeunMo.ttf` | 4 | `Info.plist` `UIAppFonts` 등록 필요 |
| `Sounds/` | 6-3 인프라 설치 완료 | 효과음 `.wav` (`note.wav`, `gameover.wav`). 파일 추가 시 AudioManager가 자동 활성화 — 없으면 시스템 사운드 폴백. BGM은 별도 sprint. |
| `Sprites.spriteatlas/` | 4 | 텍스처 아틀라스 (`Assets.xcassets/` 안) |

## 이동 절차 (Xcode에서)

1. Xcode 열기 → 좌측 네비게이터에서 `Assets.xcassets` 우클릭
2. "Show in Finder" 로 실제 위치 확인
3. Xcode 네비게이터에서 `Resources` 그룹 위로 **드래그** (Finder가 아닌 Xcode 안에서)
4. 다이얼로그에서 "Create groups" 선택 (Create folder references X)
5. 빌드(⌘R) 로 검증 — 깨지면 `presentScene(named:)` 호출에서 경로 명시 필요할 수 있음

## Sounds/ — 자작 효과음 활성화 절차

Phase 6-3에서 `AudioManager`에 **AVAudioPlayer 폴백 인프라가 설치되어 있다**.
음원 파일이 Bundle에 있으면 AVAudioPlayer 경로로 재생, 없으면 시스템 사운드(Tink/Boop)로 자동 폴백.
**코드 변경 없이** 파일 추가만으로 다음 빌드부터 자작 음원이 적용된다.

### 권장 포맷

- **확장자**: `.wav` (PCM 무압축)
- **샘플레이트 / 비트**: 44.1kHz / 16bit
- **길이**: 100~500ms (효과음용)
- **채널**: 모노 권장 (스테레오도 동작)

### 파일명 (고정)

| 파일명 | SFX 매핑 | 트리거 |
|---|---|---|
| `note.wav` | `.noteCollected` | 음표 수집 |
| `gameover.wav` | `.gameOver` | 게임 종료 |

> 파일명은 `AudioManager.SFX.fileName` computed property에 하드코딩되어 있다. 변경 시 코드도 함께 수정.

### Xcode 추가 절차

1. Finder에서 `note.wav` (또는 `gameover.wav`) 준비
2. Xcode 좌측 네비게이터에서 `GanhoMusic Shared/Resources/Sounds/` 그룹 위로 **drag-drop**
3. 다이얼로그 옵션:
   - ✓ **Copy items if needed** (체크) — 파일을 프로젝트 내부로 복사
   - **Added folders**: `Create groups` 선택
   - ✓ **Add to targets**: `GanhoMusic iOS` (체크)
4. ⌘B 빌드 → 시뮬레이터에서 게임플레이 시 자작 음원으로 자동 전환 확인

### 부분 활성화 동작

- `note.wav`만 추가 → 음표 수집은 자작 음원, 게임오버는 시스템 사운드 (Boop)
- 두 파일 모두 추가 → 모두 자작 음원
- 둘 다 없음 → Phase 6-2 동작 (Tink / Boop) 그대로

## 관련 문서

- `docs/assets.md` — 컬러·폰트·사운드 정책
