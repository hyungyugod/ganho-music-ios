# Sprint 6 - Hospital Map Readability

## 목표

게임 중 장애물과 배경이 색감상 헷갈리는 문제를 해결한다. 장애물은 배경과 더 강하게 분리하고, 맵 전체는 병실/병동 느낌이 나도록 색감과 주변 인테리어를 다시 잡는다.

## 현재 상태

- 바닥은 `ingameFloorAHex = #494E78`, `ingameFloorBHex = #2C2E4A` 기반이다.
- 벽/장애물은 `ingameWallFillHex = #1A1B2E`와 highlight/shadow를 쓴다.
- 전체가 어두운 청보라 계열이라, 실기기에서 장애물/바닥/배경이 섞여 보일 수 있다.
- `addCheckerboardFloor()`는 tileSize 기준 checkerboard 바닥을 만든다.
- `WallTileNode`는 fill/highlight/shadow/outline을 가진 단일 벽 타일이다.
- 맵에는 아직 "병실"을 읽게 하는 주변 props가 거의 없다.

## 변경 의도

장애물은 플레이 중 즉시 읽혀야 한다. 배경은 병실 분위기를 주되 충돌체처럼 보이면 안 된다. 병실 인테리어는 시각적 장소감만 주고, 플레이어 경로/충돌/스폰에는 영향을 주지 않는 것이 1차 목표다.

## 시각 방향

### 팔레트 1차 제안

| 역할 | 후보 색 | 의도 |
|---|---|---|
| 바닥 A | `#E7F0F2` | 병동 타일, 밝고 차분한 청회색 |
| 바닥 B | `#D4E2E6` | checker 차이만 약하게 |
| 장애물 fill | `#2F5D68` | 바닥과 명확히 분리되는 딥 병원 teal |
| 장애물 highlight | `#6FA8A7` | 상단 광원 |
| 장애물 shadow | `#17343C` | 하단 그림자 |
| 침대/가구 rail | `#A8B8C0` | 비충돌 병실 소품 |
| 커튼 | `#8FD0C5` | 병실 느낌, 낮은 채도 |
| 의료 포인트 | `#FF6E5A` | 위험/주의 포인트 제한 사용 |

주의:

- 바닥이 너무 밝아지면 캐릭터/노트가 더 잘 보이지만, 전체 UI 톤이 메뉴와 달라질 수 있다.
- 장애물은 바닥보다 어둡고 outline이 있어야 한다.
- 위험 오브젝트(F, 수간호사)는 기존 red/yellow 계열이 유지되어야 한다.

### 병실 인테리어 구성

비충돌 visual props 후보:

- 병실 침대 2~4개: 맵 외곽 또는 방 구석에 배치.
- 커튼 레일/파티션: 벽 근처 장식.
- 수납장/카트: 작은 사각형 props.
- 바닥 타일 라인: checkerboard보다 병동 타일처럼 보이게 thin line.
- 간호 스테이션 느낌의 데스크: 중앙 장애물 근처가 아닌 외곽.

1차 구현에서는 충돌 없는 props만 둔다.

이유:

- 새 충돌체를 추가하면 스폰/길찾기/난이도가 같이 흔들린다.
- 사용자는 "장애물들은 그대로" 흐름을 앞서 원했고, 이번에도 핵심은 색감과 인테리어다.

## 구현 범위

### Phase A - 색 토큰 교체

- `GameConfig.ingameFloorAHex`
- `GameConfig.ingameFloorBHex`
- `GameConfig.ingameWallFillHex`
- `GameConfig.ingameWallHighlightHex`
- `GameConfig.ingameWallShadowHex`

`ColorTokens`는 이미 GameConfig hex를 읽으므로 hex 변경만으로 대부분 반영된다.

### Phase B - WallTileNode 시각 강화

- wall fill을 더 distinct하게 한다.
- outline은 유지하되 너무 두껍지 않게 한다.
- wall top highlight와 bottom shadow의 대비를 높인다.
- 필요하면 wall tile 안에 병동 파티션 느낌의 작은 중앙 line을 추가한다.

주의:

- `WallTileNode.physicsBody`는 변경하지 않는다.
- zPosition 정책은 유지한다.

### Phase C - Hospital decor node 추가

신규 노드 후보:

- `HospitalPropNode`
- 또는 `HospitalDecorNode`

권장: `HospitalPropNode`.

역할:

- bed, curtain, cabinet, cart 같은 visual-only node를 만든다.
- physicsBody 없음.
- `MapNode` 또는 `GameScene+Setup`에서 배치한다.

예상 API:

```swift
enum HospitalPropKind {
    case bed
    case curtain
    case cabinet
    case cart
}

final class HospitalPropNode: SKNode {
    init(kind: HospitalPropKind, size: CGSize)
}
```

### Phase D - decor 배치

배치 원칙:

- 외곽 벽 안쪽 1~2타일 근처.
- player start, enemy waypoint, main corridors와 겹치지 않음.
- zPosition은 floor보다 위, wall보다 아래 또는 visual 성격에 따라 wall 아래.
- 충돌체가 없으므로 오브젝트처럼 오해되지 않게 alpha/색을 조절한다.

배치 후보:

| 위치 | 소품 |
|---|---|
| 좌상 room 근처 | 침대 + 커튼 |
| 우상 room 근처 | 침대 + 수납장 |
| 좌하/우하 room 근처 | 카트/파티션 |
| 외곽 벽 근처 | 얇은 의료 라인/간호 스테이션 표시 |

### Phase E - 바닥을 병동 타일처럼 조정

현재 checkerboard는 1셀마다 색이 바뀐다. 병실 타일은 너무 촘촘한 checker보다 얕은 grid가 자연스럽다.

선택지:

1. checkerboard 색만 병동 팔레트로 교체.
2. checkerboard 유지 + 4타일마다 약한 grid line 추가.
3. checkerboard를 큰 2x2 tile pattern으로 변경.

권장: 1차는 1번, 시각이 부족하면 2번.

성능:

- 현재 floor tile은 `mapColumns x mapRows = 640`개다.
- grid line 추가는 노드 수가 늘 수 있으니 최소화한다.

## 예상 수정 파일

- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`
- `GanhoMusic/GanhoMusic Shared/Config/ColorTokens.swift` 확인 대상
- `GanhoMusic/GanhoMusic Shared/Nodes/WallTileNode.swift`
- `GanhoMusic/GanhoMusic Shared/Nodes/HospitalPropNode.swift` 신규 후보
- `GanhoMusic/GanhoMusic Shared/Nodes/MapNode.swift` 또는 `GanhoMusic/GanhoMusic Shared/GameScene+Setup.swift`
- `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj` 신규 파일 추가 시

## 보존할 것

- 장애물 충돌 패턴.
- `WallTileNode` physicsBody 정책.
- 노트/변기/적 스폰 로직.
- 카메라/월드 좌표계.
- 인게임 HUD 가독성.

## 수용 기준

- 장애물과 바닥이 한눈에 구분된다.
- 맵이 병실/병동처럼 읽힌다.
- 병실 props는 충돌/스폰을 방해하지 않는다.
- 노트, F 투사체, 플레이어, 적이 배경에 묻히지 않는다.
- easy/normal/hard 모두 맵 진입과 기본 플레이가 가능하다.
- 색이 한 계열로만 뭉쳐 보이지 않는다.

## 리스크와 대응

- 리스크: 바닥을 밝게 만들면 기존 어두운 게임 톤이 약해질 수 있다.
  - 대응: obstacle과 danger 오브젝트를 어둡고 선명하게 두고, HUD는 기존 픽셀 톤을 유지한다.
- 리스크: decor가 장애물처럼 보여 플레이어가 피하려 할 수 있다.
  - 대응: decor는 낮은 alpha, rounded/soft tone, no outline 또는 얇은 outline으로 처리한다.
- 리스크: node 수 증가로 성능이 떨어질 수 있다.
  - 대응: props 수를 10개 이하로 시작하고, floor grid 추가는 보류한다.
- 리스크: hospital props가 wall/room pattern과 겹쳐 지저분해질 수 있다.
  - 대응: MapNode 배치표를 만들어 타일 단위로 고정 배치한다.

