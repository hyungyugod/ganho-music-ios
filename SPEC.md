# Phase 9-4 — 체크보드 바닥 + 난이도별 맵 구조 확장

## 개요

현재 게임 월드는 단색 배경(`.ganhoBgDeep`) 위에 외곽 벽 4개 + 난이도별 내부 벽(easy: 중앙 기둥 1개 / normal·hard: 동일한 hard 맵)만 배치되어 있다. 본 Phase는 (1) 체크보드 바닥 격자를 worldNode 안에 1회 빌드하여 시각 정체성을 코럴 톤으로 통일하고, (2) `Difficulty.normal`에 "방 2개 + 복도" 전용 맵을 신설해 hard와 차별화한다. 결과적으로 3 난이도가 시각·구조 양면에서 모두 다른 정체성을 갖게 된다.

## 변경 유형

**비주얼 + 게임플레이 혼합** — 체크보드는 순수 비주얼(physicsBody 0), 난이도별 맵 분기는 게임플레이 변경(normal 맵 신설 → physicsBody 추가 + 스폰/이동 영역 변동).

## 게임 경험 의도

웹 원본의 코럴 톤 카드 패널 미감을 게임 월드 바닥까지 확장해 *"같은 게임을 계속 보고 있다"*는 일관된 감각을 준다. 또 normal 난이도가 더 이상 hard의 복제가 아니라 *방 두 개를 오가는 동선*이라는 자기만의 톤을 갖게 하여, 사용자가 "중 = 살짝 어려운 하"가 아니라 "중 = 다른 결의 도전"으로 인지하도록 한다.

## Sprint 범위 계약

- **허용 변경**
  - `GameScene+Setup.swift`의 `setupBackground()` / `setupMap()` 내부 동작
  - `GameConfig.swift`에 체크보드 토큰 hex/zPosition 상수 + Normal Map 좌표 상수 추가
  - `GameScene+Setup.swift`에 normal 전용 빌더 `addNormalMap()` + 체크보드 빌더 `addCheckerboardFloor()` 메서드 추가
  - `setupMap()`의 switch 분기: `.normal`을 `addHardMap()`에서 떼어내 `addNormalMap()`으로 연결
- **금지 변경**
  - Player/Enemy/StoneGuard/Note/Projectile 노드 0줄 수정
  - HUD/TitleScene/ResultScene/Repository 0줄 수정
  - 카메라 follow 로직 (`update()` 안 cameraNode.position 라인) 변경 금지
  - `addOuterWalls()` / `addCentralPillar()` / `addHardMap()` / 헬퍼(`addRectPillar`, `addHorizontalWall`, `addVerticalWall`) 0줄 변경 — Phase 7-2 회귀 0 보장
  - SpawnSystem의 `randomNotePosition()` 수정 금지 — 본 sprint는 normal 맵 벽과 정확한 회피 미보장(다음 sprint 보강)
  - `setupPlayer()` / `setupEnemy()` / `setupStoneGuard()` 위치 변경 금지
- **판단 기준**: "이 변경이 없으면 체크보드 또는 normal 맵 분기가 동작하지 않는가?" → YES만 허용.

## 변경 범위

### 수정할 파일

- `GanhoMusic Shared/GameScene+Setup.swift`
  - `setupWorld()`: `addChild(worldNode)` 직후 `addCheckerboardFloor()` 호출 추가
  - `setupMap()`: switch 분기 수정 — `.normal` case를 `addNormalMap()`으로 연결
  - 새 메서드 `addNormalMap()` 1개 추가 (extension 내부)
  - 새 메서드 `addCheckerboardFloor()` 1개 추가 (private, 자식 노드 1개를 worldNode에 부착)

- `GanhoMusic Shared/Config/GameConfig.swift`
  - "MARK: - Checkerboard Floor (Phase 9-4)" 섹션 추가
  - "MARK: - Normal Map (Phase 9-4)" 섹션 추가

### 추가할 파일

- 없음. 새 파일을 만들면 Xcode 프로젝트 .pbxproj 수정이 필요해 빌드 리스크 ↑. **모든 신규 코드는 기존 파일에 추가**한다.

## 기능 상세

### 기능 1: 체크보드 바닥

- **설명**: 맵 전체(48×24 타일 = 960×480pt)에 두 색이 시장 패턴으로 교차되는 정사각형 바닥. SKNode 한 컨테이너 안에 1152개(48×24) SKSpriteNode 자식으로 구성 — *한 번만 빌드*되고 이후 추가 노드 생성/삭제 0건.

- **구현 위치**: `GameScene+Setup.swift` extension의 private `addCheckerboardFloor()` 메서드.

- **색상 (코럴 톤 조화)**
  - **floorA (밝은 차콜)**: `#1a1722` — `ganhoUIBgCard`(#17151e α=0.82)와 동일 패밀리의 *살짝 밝은* 매트 차콜. 카드 패널 톤과 자연 연속.
  - **floorB (어두운 차콜)**: `#13111a` — `ganhoUIBgDark`(#09080f)보다 살짝 밝지만 floorA보다 어두운 중간값.

- **타일 크기**: `GameConfig.tileSize`(20pt) 그대로 재사용.

- **z-order**:
  - 체크보드 컨테이너: `zPosition = -100` (`GameConfig.checkerboardZPosition`)
  - 외곽 벽 / 기둥: zPosition 0 (변경 X)
  - Player/Enemy/StoneGuard: zPosition 5 (변경 X)

- **한 번만 빌드** (성능 핵심)
  - `setupWorld()`에서 *1회만* `addCheckerboardFloor()` 호출
  - `update()` 안에서 절대 호출 금지
  - 각 타일에 `physicsBody = nil` (시각 전용)

### 기능 2: easy 맵 — 중앙 기둥 1개 (체크보드 위)

- **설명**: 현재 `addCentralPillar()` 그대로 유지. 체크보드만 추가되어 시각이 갱신됨. **코드 변경 0**.

### 기능 3: normal 맵 — 방 2개 + 복도

- **설명**: 맵을 좌·우 두 방으로 나누는 *중앙 세로 벽*과 그 벽의 *중간 한 칸 문(door)*으로 복도를 구성. 좌·우 방 안에 작은 장식 기둥 각 1개.

- **좌표계 (맵 48×24 타일, tileSize=20pt, 원점 좌하단)**

  - **중앙 세로 분리벽**: c=23, r=2..21
  - **분리벽의 문(door)**: r=11~12 (2칸 연속 문 — 플레이어 통과 보장)
    - `addVerticalWall(c: 23, rStart: 2, rEnd: 10, doorR: -1)` (윗 절반)
    - `addVerticalWall(c: 23, rStart: 13, rEnd: 21, doorR: -1)` (아랫 절반)
    - 가운데 r=11,12 빈 칸이 자연스럽게 문 역할

  - **좌방 장식 기둥**: cStart=10, cEnd=11, rStart=11, rEnd=12 (2×2 타일)
  - **우방 장식 기둥**: cStart=36, cEnd=37, rStart=11, rEnd=12 (2×2 타일, 좌우 거울 대칭)

  - **GameConfig 상수 신설**

    ```swift
    // MARK: - Normal Map (Phase 9-4)
    static let normalMapDividerC: Int = 23
    static let normalMapDividerUpperRStart: Int = 2
    static let normalMapDividerUpperREnd: Int = 10
    static let normalMapDividerLowerRStart: Int = 13
    static let normalMapDividerLowerREnd: Int = 21
    static let normalMapLeftPillarCStart: Int = 10
    static let normalMapLeftPillarCEnd: Int = 11
    static let normalMapLeftPillarRStart: Int = 11
    static let normalMapLeftPillarREnd: Int = 12
    static let normalMapRightPillarCStart: Int = 36
    static let normalMapRightPillarCEnd: Int = 37
    static let normalMapRightPillarRStart: Int = 11
    static let normalMapRightPillarREnd: Int = 12
    static let normalMapNoDoorSentinel: Int = -1
    ```

- **참고: `addVerticalWall` 시그니처 재확인**

  음수 `doorR=-1` 전달 시 `r != -1`은 모든 양의 r에 대해 true → 모든 칸이 벽으로 채워짐 (의도와 정확 일치, 코드 0줄 변경).

### 기능 4: hard 맵 — 변경 없음

- 현재 `addHardMap()` 그대로 유지. switch 분기에서 `.hard`만 단독 case로 분리 — 결과는 동일하나 의도 명확.

- **변경 전**

  ```swift
  case .easy:           addCentralPillar()
  case .normal, .hard:  addHardMap()
  ```

- **변경 후**

  ```swift
  case .easy:   addCentralPillar()
  case .normal: addNormalMap()
  case .hard:   addHardMap()
  ```

- switch에 `default` 미사용 — Phase 7-2 패턴 답습.

### 기능 5: setupBackground 정책

- **변경 없음**. `backgroundColor = .ganhoBgDeep` 유지. 이유:
  1. 체크보드는 worldNode 자식 → 카메라가 맵 경계 밖으로 살짝 비추는 *틈 픽셀*을 배경색이 덮음 (graceful fallback)
  2. ResultScene/TitleScene이 같은 `.ganhoBgDeep`를 쓰므로 *씬 전환 시 동일 배경*이 자연 연속

## 회귀 방지

- **Phase 9-1~9-3 (Title/HUD/Result 디자인 동일화) 0줄 변경**
- **Phase 8-1~8-5 (픽셀 아트/HUD 4슬롯) 0줄 변경**
- **카메라 follow 0줄 변경**: GameScene.swift `update()` 안 `cameraNode.position = player.position` 라인 보존.
- **외곽 벽/기존 hard 맵 코드 0줄 변경**: `addOuterWalls()` / `addCentralPillar()` / `addHardMap()` / `addRectPillar` / `addHorizontalWall` / `addVerticalWall` 모두 read-only.
- **easy 회귀**: 체크보드 추가가 *유일한* 시각 변화.
- **hard 회귀**: switch case 분리만 발생, hard 호출 경로는 결과 동일.
- **SpawnSystem 회피 로직**: 본 sprint 의도적 수용 — note는 *벽 위에 떠 있을 뿐* 플레이어 통과 차단 X.

## 매직 넘버 정책

- 체크보드 두 색은 **hex 문자열 상수**로 `GameConfig.swift`에 정의.
- zPosition, 컨테이너 name, 모든 normal 맵 타일 좌표는 *전부* `GameConfig.swift`의 새 MARK 섹션에 상수화.
- 호출부(`GameScene+Setup.swift`)에는 리터럴 0건 등장 — Phase 7-2 패턴 답습.

## 평가 가중치 — 점수 잃기 쉬운 지점

### Swift 패턴 일관성 (35%)
- 1152개 SKSpriteNode 생성 루프에 매직 넘버(48, 24) 직접 등장 시 감점 → `GameConfig.mapColumns / mapRows` 참조 필수.
- hex 문자열을 호출부에 리터럴로 두면 감점 → 반드시 `GameConfig.checkerboardFloorAHex` 경유.

### 게임 로직 완성도 (30%)
- 체크보드 빌드는 `setupWorld()` 안에서 1회만 실행 — `update()` 안 호출 금지.
- 음수 doorR (`-1`) 호출이 graceful noop인지 Evaluator 검증.
- normal 분기가 enum 패턴 매칭으로 자연 분기되는지 확인 (default 미사용).

### 성능 & 안정성 (20%)
- 1152개 노드가 한 번에 worldNode에 들어가도 60fps 유지.
- 체크보드 컨테이너 name 부착 (`GameConfig.checkerboardContainerName`).
- physicsBody 0 부착 — 반드시 *시각 전용*.
- 강제 언래핑 0건.

### 기능 완성도 (15%)
- 체크보드가 모든 난이도(easy/normal/hard)에서 *동일하게* 보여야 함.
- normal 맵 분리벽 가운데에 *실제로 통과 가능한 문 2칸*이 비어야 함.

## 주의사항

1. **체크보드 z-order 검증**: 음수 zPosition도 SpriteKit 정상 동작.
2. **컬러 색차 검증**: `#1a1722` vs `#13111a` — 두 색 구분 가능성 시각 검증.
3. **doorR=-1 sentinel**: 가독성을 위해 `GameConfig.normalMapNoDoorSentinel: Int = -1` 상수 사용.
4. **빌드 에러 가능성**:
   - `addRectPillar` / `addVerticalWall`은 `private` → `addNormalMap()`이 *같은 파일* extension 안에 있어야 접근 가능.
   - `UIColor(hex:)`는 ColorTokens.swift에 이미 존재.

---

**핵심 파일 경로**
- `GanhoMusic/GanhoMusic Shared/GameScene+Setup.swift`
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`
- `GanhoMusic/GanhoMusic Shared/GameScene.swift` (참조만, 0줄 변경)
- `GanhoMusic/GanhoMusic Shared/Config/ColorTokens.swift` (UIColor(hex:) 헬퍼만 사용, 0줄 변경)
