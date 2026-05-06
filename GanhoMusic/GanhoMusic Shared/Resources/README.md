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
| `Sounds/` | 4 | BGM (`.m4a`), 효과음 (`.caf`) |
| `Sprites.spriteatlas/` | 4 | 텍스처 아틀라스 (`Assets.xcassets/` 안) |

## 이동 절차 (Xcode에서)

1. Xcode 열기 → 좌측 네비게이터에서 `Assets.xcassets` 우클릭
2. "Show in Finder" 로 실제 위치 확인
3. Xcode 네비게이터에서 `Resources` 그룹 위로 **드래그** (Finder가 아닌 Xcode 안에서)
4. 다이얼로그에서 "Create groups" 선택 (Create folder references X)
5. 빌드(⌘R) 로 검증 — 깨지면 `presentScene(named:)` 호출에서 경로 명시 필요할 수 있음

## 관련 문서

- `docs/assets.md` — 컬러·폰트·사운드 정책
