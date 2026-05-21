//
//  MapNode.swift
//  GanhoMusic Shared
//
//  Sprint 10 Phase B · 맵 좌표 그릇 단일 진실 원천.
//  worldNode 자식으로 부착되어 1280×800 pt 좌표계를 표현한다(원본 32×20 타일 × 40pt 셀).
//  Phase B는 *빈 컨테이너* 단계 — buildWalls 후크는 Phase C가 채운다.
//  존재 이유:
//   1) Phase A 픽셀 시각(32×40pt) ↔ Phase B 셀(40pt) 정합 검증의 단일 좌표계 진입점.
//   2) Phase C 빌런/벽 좌표가 GameScene이 아닌 *맵 자체*에 종속됨을 표명(Spring 비유: 도메인 객체).
//

import SpriteKit

/// 원본 1:1 맵 컨테이너. worldNode 자식 SKNode — physicsBody 0(좌표 그릇 전용).
/// Phase B 책임: 1) zPosition 적층 안정화, 2) 타일↔월드 좌표 변환 헬퍼, 3) Phase C 후크.
/// 게임 로직 미접근(Spring 비유: domain model — read-only 좌표 헬퍼만 노출).
final class MapNode: SKNode {

    // MARK: - Lifecycle
    /// SKNode 기본 init 위에서 name/zPosition만 set. addChild 0건(Phase C 책임).
    override init() {
        super.init()
        name = "mapNode"
        zPosition = GameConfig.mapNodeZPosition   // -50: 체크보드(-100) 위, 외곽 벽(0) 아래.
    }

    /// 코더 init은 사용하지 않음 — SKS 파일이 아닌 코드 부착 전용 노드.
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Coordinate Helpers
    /// (col, row) 타일 인덱스를 셀 *중심점* 월드 좌표로 변환.
    /// Phase C 빌런/벽 스폰의 단일 좌표 진입점이 될 예정 — 본 Phase B는 정의만, 호출은 0건.
    /// 산식: (col + 0.5) × CELL_PT, (row + 0.5) × CELL_PT — anchorPoint .center 기준 정합.
    func tileCoordinate(col: Int, row: Int) -> CGPoint {
        let cell = GameConfig.originalMapCellSize
        return CGPoint(
            x: (CGFloat(col) + 0.5) * cell,
            y: (CGFloat(row) + 0.5) * cell
        )
    }

    /// 월드 전체 크기 (pt). Phase C/카메라 클램프에서 단일 진실 원천으로 참조 가능.
    /// 본 Phase B 시점에서는 GameScene.updateCameraFollow가 GameConfig 상수를 직접 참조하지만,
    /// 추후 MapNode가 동적 크기를 갖게 되면 이 메서드로 일원화한다.
    func worldSize() -> CGSize {
        return CGSize(
            width:  GameConfig.originalMapWorldWidth,
            height: GameConfig.originalMapWorldHeight
        )
    }

    // MARK: - Phase C Wall Builder
    /// 난이도별 벽 데이터 + WallTileNode 자식 부착의 단일 진입점.
    /// 원본 game.js buildMap(L262~L313)의 byte-equal 이식 — easy/normal/hard 3종.
    /// DIFFICULTY 매핑(ORIGINAL_GAME_ANALYSIS L44~L49): normal → 'hard' 공유 → switch에서 .hard와 같은 본문.
    /// switch default 미사용 — Difficulty 3 case exhaustive로 컴파일 가드 보장(주의사항 6).
    func buildWalls(difficulty: Difficulty) {
        buildOuterWall()
        switch difficulty {
        case .easy:
            buildEasyInterior()
        case .normal, .hard:
            buildHardInterior()
        }
    }

    /// 32×20 맵의 가장자리 1셀 둘레 — 원본 game.js L264~L265.
    /// 가로(top/bottom)는 전 col(0..lastCol), 세로(left/right)는 1..lastRow-1로 중복 0(OQ-3).
    private func buildOuterWall() {
        let lastCol = GameConfig.originalMapTileWidth  - 1
        let lastRow = GameConfig.originalMapTileHeight - 1
        for col in 0...lastCol {
            attachWallTile(col: col, row: 0)
            attachWallTile(col: col, row: lastRow)
        }
        for row in 1..<lastRow {
            attachWallTile(col: 0,       row: row)
            attachWallTile(col: lastCol, row: row)
        }
    }

    /// Easy 내부 — 중앙 2×4 픽셀 기둥 1개 (game.js L267~L271).
    /// 원본 좌표 m[r][c]=1 r∈[8..11], c∈[15..16] → iosRow = 19 - origR로 변환.
    private func buildEasyInterior() {
        for origR in GameConfig.easyMapCenterPillarOrigRStart...GameConfig.easyMapCenterPillarOrigREnd {
            for col in GameConfig.easyMapCenterPillarColStart...GameConfig.easyMapCenterPillarColEnd {
                attachWallTile(col: col, row: convertOrigRowToIOS(origR))
            }
        }
    }

    /// Hard 내부 — 4 모서리 방 + 중앙 기둥 4개 (game.js L288~L309).
    /// 좌상/우상/좌하/우하 방은 각각 가로벽 + 세로벽(문 1칸 분기) 조합.
    /// 중앙 기둥은 좌(1×2 세로) / 우(1×2 세로) / 상(2×1 가로) / 하(2×1 가로).
    private func buildHardInterior() {
        // 좌상 방 — m[5][4..9]=1 + m[2..5][9]=1 (문 m[3][9]=0)
        buildRoom(hWallOrigR:      GameConfig.hardMapRoomTopLeftHWallOrigR,
                  hWallColStart:   GameConfig.hardMapRoomTopLeftHWallColStart,
                  hWallColEnd:     GameConfig.hardMapRoomTopLeftHWallColEnd,
                  vWallCol:        GameConfig.hardMapRoomTopLeftVWallCol,
                  vWallOrigRStart: GameConfig.hardMapRoomTopLeftVWallOrigRStart,
                  vWallOrigREnd:   GameConfig.hardMapRoomTopLeftVWallOrigREnd,
                  doorOrigR:       GameConfig.hardMapRoomTopLeftDoorOrigR)

        // 우상 방 — m[5][22..27]=1 + m[2..5][22]=1 (문 m[3][22]=0)
        buildRoom(hWallOrigR:      GameConfig.hardMapRoomTopRightHWallOrigR,
                  hWallColStart:   GameConfig.hardMapRoomTopRightHWallColStart,
                  hWallColEnd:     GameConfig.hardMapRoomTopRightHWallColEnd,
                  vWallCol:        GameConfig.hardMapRoomTopRightVWallCol,
                  vWallOrigRStart: GameConfig.hardMapRoomTopRightVWallOrigRStart,
                  vWallOrigREnd:   GameConfig.hardMapRoomTopRightVWallOrigREnd,
                  doorOrigR:       GameConfig.hardMapRoomTopRightDoorOrigR)

        // 좌하 방 — m[14][4..9]=1 + m[14..17][9]=1 (문 m[16][9]=0)
        buildRoom(hWallOrigR:      GameConfig.hardMapRoomBottomLeftHWallOrigR,
                  hWallColStart:   GameConfig.hardMapRoomBottomLeftHWallColStart,
                  hWallColEnd:     GameConfig.hardMapRoomBottomLeftHWallColEnd,
                  vWallCol:        GameConfig.hardMapRoomBottomLeftVWallCol,
                  vWallOrigRStart: GameConfig.hardMapRoomBottomLeftVWallOrigRStart,
                  vWallOrigREnd:   GameConfig.hardMapRoomBottomLeftVWallOrigREnd,
                  doorOrigR:       GameConfig.hardMapRoomBottomLeftDoorOrigR)

        // 우하 방 — m[14][22..27]=1 + m[14..17][22]=1 (문 m[16][22]=0)
        buildRoom(hWallOrigR:      GameConfig.hardMapRoomBottomRightHWallOrigR,
                  hWallColStart:   GameConfig.hardMapRoomBottomRightHWallColStart,
                  hWallColEnd:     GameConfig.hardMapRoomBottomRightHWallColEnd,
                  vWallCol:        GameConfig.hardMapRoomBottomRightVWallCol,
                  vWallOrigRStart: GameConfig.hardMapRoomBottomRightVWallOrigRStart,
                  vWallOrigREnd:   GameConfig.hardMapRoomBottomRightVWallOrigREnd,
                  doorOrigR:       GameConfig.hardMapRoomBottomRightDoorOrigR)

        // 중앙-좌 기둥 — m[9..10][12]=1 (1×2 세로)
        attachPillarRect(colStart:   GameConfig.hardMapCenterLeftPillarCol,
                         colEnd:     GameConfig.hardMapCenterLeftPillarCol,
                         origRStart: GameConfig.hardMapCenterLeftPillarOrigRStart,
                         origREnd:   GameConfig.hardMapCenterLeftPillarOrigREnd)

        // 중앙-우 기둥 — m[9..10][19]=1 (1×2 세로)
        attachPillarRect(colStart:   GameConfig.hardMapCenterRightPillarCol,
                         colEnd:     GameConfig.hardMapCenterRightPillarCol,
                         origRStart: GameConfig.hardMapCenterRightPillarOrigRStart,
                         origREnd:   GameConfig.hardMapCenterRightPillarOrigREnd)

        // 중앙-상 기둥 — m[7][15..16]=1 (2×1 가로)
        attachPillarRect(colStart:   GameConfig.hardMapCenterTopPillarColStart,
                         colEnd:     GameConfig.hardMapCenterTopPillarColEnd,
                         origRStart: GameConfig.hardMapCenterTopPillarOrigR,
                         origREnd:   GameConfig.hardMapCenterTopPillarOrigR)

        // 중앙-하 기둥 — m[12][15..16]=1 (2×1 가로)
        attachPillarRect(colStart:   GameConfig.hardMapCenterBottomPillarColStart,
                         colEnd:     GameConfig.hardMapCenterBottomPillarColEnd,
                         origRStart: GameConfig.hardMapCenterBottomPillarOrigR,
                         origREnd:   GameConfig.hardMapCenterBottomPillarOrigR)
    }

    /// 4 모서리 방의 공통 빌더 — 가로벽 1행 + 세로벽(문 1칸 분기).
    /// 통짜로 만들지 않고 1셀씩 부착 — 통합 PhysicsBody가 문을 막아 플레이어 입장 불가가 되는 회귀 회피.
    /// 좌표는 모두 원본 game.js 기준 origR로 받고 본 메서드 내부에서 iosRow로 변환.
    private func buildRoom(hWallOrigR: Int,
                           hWallColStart: Int, hWallColEnd: Int,
                           vWallCol: Int,
                           vWallOrigRStart: Int, vWallOrigREnd: Int,
                           doorOrigR: Int) {
        // 가로벽 1행
        for col in hWallColStart...hWallColEnd {
            attachWallTile(col: col, row: convertOrigRowToIOS(hWallOrigR))
        }
        // 세로벽 — door 1칸은 *건너뜀* (원본 m[doorR][c]=0)
        for origR in vWallOrigRStart...vWallOrigREnd where origR != doorOrigR {
            attachWallTile(col: vWallCol, row: convertOrigRowToIOS(origR))
        }
    }

    /// 직사각형 영역 [colStart..colEnd] × [origRStart..origREnd]를 1셀씩 부착.
    /// 옛 addRectPillar는 SKSpriteNode 1개 + 통합 PhysicsBody였지만, Phase C는 1셀=40pt 격자 정합 우선 — 셀 단위 분리.
    private func attachPillarRect(colStart: Int, colEnd: Int,
                                  origRStart: Int, origREnd: Int) {
        for origR in origRStart...origREnd {
            for col in colStart...colEnd {
                attachWallTile(col: col, row: convertOrigRowToIOS(origR))
            }
        }
    }

    /// 단일 (col, row) 셀에 WallTileNode 1개 부착 — 모든 빌더의 최종 진입점.
    /// position은 tileCoordinate(col:row:) 셀 중심점 사용 — anchorPoint .center 기본값과 자연 정합.
    private func attachWallTile(col: Int, row: Int) {
        let tile = WallTileNode()
        tile.position = tileCoordinate(col: col, row: row)
        addChild(tile)
    }

    /// 원본 좌표계(Y↓, r=0이 맵 상단) → iOS SpriteKit(Y↑) 변환.
    /// iosRow = MAP_H - 1 - origR (주의사항 1).
    private func convertOrigRowToIOS(_ origR: Int) -> Int {
        return GameConfig.originalMapTileHeight - 1 - origR
    }
}
