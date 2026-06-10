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
| `Sounds/` | R2부터 효과음은 ChiptuneSynth가 프로시저럴 생성 — 효과음 `.wav` 불필요 | BGM(`bgm.m4a`)만 파일 기반 (아래 BGM 절차 참조). |
| `Sprites.spriteatlas/` | 4 | 텍스처 아틀라스 (`Assets.xcassets/` 안) |

## 이동 절차 (Xcode에서)

1. Xcode 열기 → 좌측 네비게이터에서 `Assets.xcassets` 우클릭
2. "Show in Finder" 로 실제 위치 확인
3. Xcode 네비게이터에서 `Resources` 그룹 위로 **드래그** (Finder가 아닌 Xcode 안에서)
4. 다이얼로그에서 "Create groups" 선택 (Create folder references X)
5. 빌드(⌘R) 로 검증 — 깨지면 `presentScene(named:)` 호출에서 경로 명시 필요할 수 있음

## 효과음 — R2부터 ChiptuneSynth 프로시저럴 생성

R2에서 효과음은 `Managers/ChiptuneSynth.swift`가 **시작 시 전부 사전 렌더(PCM 버퍼)**해 재생한다.
외부 `.wav` 에셋·iOS 시스템 사운드 폴백 경로는 전폐 — 효과음 파일 추가 불필요.
voice 표(콤보 반음 상승 포함)는 `refactor/02_GAME_FEEL.md` §6 참조.

## Sounds/ — 자작 BGM 활성화 절차 (Phase 6-4)

Phase 6-4에서 `BGMPlayer`에 AVAudioPlayer 기반 BGM 인프라가 설치되어 있다.
음원 파일이 Bundle에 있으면 게임 진입 시 무한 루프 재생, 없으면 noop.

### 권장 포맷 (효과음과 다름 — 압축 포맷 사용)
- 확장자: `.m4a` (AAC 압축, iOS 네이티브)
- 길이: 30~60초 (무한 루프되므로 짧고 깔끔한 루프 권장)
- 채널: 스테레오 OK
- 루프 포인트: 시작/끝이 자연스럽게 이어지도록 페이드아웃 제거

### 파일명 (고정)
| 파일명 | 역할 |
|---|---|
| `bgm.m4a` | 게임 진입 시 재생, 게임오버 시 정지 |

### AVAudioSession 카테고리 차이
- 음원 부재: `.ambient` 그대로 (6-3 정책)
- bgm.m4a 추가 후: `.playback` + `.mixWithOthers` 덮어쓰기 → 무음모드 무시 + Apple Music과 동시 재생

### Xcode 추가 절차
효과음과 동일. `Resources/Sounds/`에 drag-drop, Copy items if needed ✓, Add to targets: GanhoMusic iOS ✓.

### 부분 활성화 동작
- `bgm.m4a` 있음 → BGM 재생 (단 `FeelTuning.isBGMEnabled=false`인 동안은 미재생 정책)
- 없음 → BGM 무음. 효과음은 파일 유무와 무관하게 항상 ChiptuneSynth (R2)

## 관련 문서

- `docs/assets.md` — 컬러·폰트·사운드 정책
