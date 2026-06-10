//
//  GameplayTuning.swift
//  GanhoMusic Shared
//
//  R0 — 구 god-config(분할 전 단일 Config) 분해: 이동·스폰·AI·스킬·콤보·난이도·맵 좌표 수치 + 좌표 헬퍼.
//  값은 분할 전과 byte-equal — R0는 위치 이동만 (행동 불변).
//

import Foundation
import CoreGraphics

/// 게임플레이 튜닝 상수 네임스페이스 — 이동·스폰·AI·스킬·콤보·난이도·맵 좌표.
/// case 없는 enum: 인스턴스화 차단 (왜: 전역 상수의 단일 진실 원천 유지, 오용 방지).
enum GameplayTuning {
    // MARK: - Time
    /// 한 판 길이 (초). GDD §1
    static let gameDuration: TimeInterval = 45

    // MARK: - Original Map (Sprint 10 Phase B — 원본 1:1 정합)
    // 단일 진실 원천: docs/ORIGINAL_GAME_ANALYSIS.md L14~L24 §0 (game.js L62~L74).
    // 원본 웹게임 좌표계를 byte-equal로 iOS에 이식하기 위한 8개 상수.
    // 산식: TILE_PT(20) × SCALE(2) = CELL_PT(40) → world(1280×800).
    /// 원본 맵 가로 타일 수(원본 동일). game.js L18.
    static let originalMapTileWidth: Int = 32
    /// 원본 맵 세로 타일 수(원본 동일). game.js L19.
    static let originalMapTileHeight: Int = 20
    /// 시각상 한 셀 크기 (pt) = TILE_PT(20) × SCALE(2) = 40. game.js L17 TILE × L101/L713 SCALE.
    static let originalMapCellSize: CGFloat = 40.0
    /// 월드 가로 전체 크기 (pt) = CELL_PT × MAP_W = 40 × 32 = 1280.
    static let originalMapWorldWidth: CGFloat = originalMapCellSize * CGFloat(originalMapTileWidth)
    /// 월드 세로 전체 크기 (pt) = CELL_PT × MAP_H = 40 × 20 = 800.
    static let originalMapWorldHeight: CGFloat = originalMapCellSize * CGFloat(originalMapTileHeight)

    // MARK: - World
    /// Runtime compact 셀 크기. 원본 좌표 해석 상수와 분리해 실제 월드만 압축한다.
    static let compactMapCellSize: CGFloat = 25.0
    /// 타일 1칸 크기 (pt). 호출자는 원본 좌표 상수가 아니라 runtime compact 셀만 참조한다.
    static let tileSize: CGFloat = compactMapCellSize
    /// Runtime 맵 가로 타일 수. Compact map은 32열을 유지한다.
    static let mapColumns: Int = originalMapTileWidth
    /// Runtime 맵 세로 타일 수. Compact map은 20행을 유지한다.
    static let mapRows: Int = originalMapTileHeight
    /// 맵 전체 가로 폭 (pt). 25 × 32 = 800.
    static let mapWidth: CGFloat = tileSize * CGFloat(mapColumns)
    /// 맵 전체 세로 높이 (pt). 25 × 20 = 500.
    static let mapHeight: CGFloat = tileSize * CGFloat(mapRows)

    /// 원본 좌표를 runtime compact 좌표로 변환하는 비율.
    static var mapRuntimeScale: CGFloat {
        return tileSize / originalMapCellSize
    }

    /// 원본 pt 좌표를 runtime compact 맵 좌표로 축소한다.
    static func scaledMapPoint(x: CGFloat, y: CGFloat) -> CGPoint {
        return CGPoint(x: x * mapRuntimeScale, y: y * mapRuntimeScale)
    }

    /// Runtime compact 셀 단위 좌표를 pt 좌표로 변환한다.
    static func cellPoint(x: CGFloat, y: CGFloat) -> CGPoint {
        return CGPoint(x: x * tileSize, y: y * tileSize)
    }

    /// Runtime compact 셀 중심 좌표.
    static func tileCenter(col: Int, row: Int) -> CGPoint {
        return cellPoint(x: CGFloat(col) + 0.5, y: CGFloat(row) + 0.5)
    }

    // MARK: - Player (Phase 1-3 정식)
    /// 플레이어 기본 속도 (pt/s). easy 난이도 기준점.
    static let playerBaseSpeed: CGFloat = 140
    /// 실기기 compact map에서 체감 속도를 살짝 낮추는 runtime 배율.
    static let playerSpeedRuntimeMultiplier: CGFloat = 0.9
    /// 기본 걷기 속도 배율. 달리기를 누르지 않을 때 적용된다.
    static let playerWalkSpeedScale: CGFloat = 0.72
    /// 달리기 속도 배율. 기존 체감 속도를 보존한다.
    static let playerRunSpeedScale: CGFloat = 1.0
    /// 플레이어 박스 가로 (pt). GDD §7-1 김간호 16×20.
    static let playerWidth: CGFloat = 16
    /// 플레이어 박스 세로 (pt). GDD §7-1 김간호 16×20.
    static let playerHeight: CGFloat = 20
    /// 벽 슬라이드 충돌 조회 rect를 안쪽으로 줄이는 값. 모서리 접촉 과검출을 줄인다.
    static let playerWallQueryInset: CGFloat = 1
    /// 이미 벽과 겹친 상태에서 tangent 이동을 허용할 때 overlap score 악화 허용치.
    static let playerWallSlideOverlapTolerance: CGFloat = 0.5
    /// 벽 겹침 복구 시 rect 바깥으로 살짝 밀어내는 여백.
    static let playerWallRecoveryPadding: CGFloat = 0.5
    /// 벽 겹침 복구 1회당 최대 보정 거리. 깊은 겹침에서도 순간 스냅을 작게 나눈다.
    static let playerWallRecoveryMaxCorrection: CGFloat = 8
    /// 벽 겹침 복구 반복 상한. 코너에서 여러 벽이 겹칠 수 있어 소량 반복한다.
    static let playerWallRecoveryMaxIterations: Int = 4
    /// 복구 후보 점수 비교용 epsilon. 부동소수점 동률 흔들림을 막는다.
    static let playerWallRecoveryScoreEpsilon: CGFloat = 0.01

    // MARK: - D-Pad (Phase 1-3)
    /// D-Pad 단일 버튼 한 변 (pt). Apple HIG 권장 최소 터치 타깃 44pt.
    static let dpadButtonSize: CGFloat = 44
    /// D-Pad 전체 알파 (반투명). 게임 위에 떠 있는 느낌.
    /// Phase 2-7 hotfix — 0.5 → 0.7. 어두운 배경에서 사용자가 *터치 위치 인지* 가능.
    static let dpadAlpha: CGFloat = 0.7
    /// D-Pad 좌측 가장자리에서의 안쪽 마진 (pt). cameraNode 자식 좌표계 기준.
    static let dpadMarginX: CGFloat = 90
    /// D-Pad 하단 가장자리에서의 안쪽 마진 (pt).
    static let dpadMarginY: CGFloat = 90
    /// 아날로그 D-Pad가 입력으로 인정하는 최대 thumb 반경.
    static let dpadAnalogMaxRadius: CGFloat = 58
    /// 아날로그 D-Pad 중심 데드존 반경.
    static let dpadAnalogDeadzoneRadius: CGFloat = 8
    /// D-Pad가 터치를 받는 전체 원형 반경.
    static let dpadTouchRadius: CGFloat = 76
    /// 아날로그 D-Pad thumb 반경.
    static let dpadThumbRadius: CGFloat = 18
    /// 아날로그 D-Pad thumb 알파.
    static let dpadThumbAlpha: CGFloat = 0.82
    /// 보간 결과를 0으로 스냅하는 임계값.
    static let dpadInputSnapEpsilon: CGFloat = 0.02
    /// 한 축이 다른 축보다 이 배수 이상 우세하면 작은 축을 제거한다.
    static let dpadAxisSnapDominanceRatio: CGFloat = 1.35

    // (placeholderBoxSize, placeholderBoxAutoSpeed는 1-2 임시값 → 1-3에서 제거)

    // MARK: - Note (Phase 2-3)
    /// 음표 한 변 길이 (pt). GDD §7-2 음표 스프라이트.
    static let noteSize: CGFloat = 32   // Sprint 10.5 Phase B — 16 → 32 (2x 정수 스케일). 캐릭터 32×40pt 대비 80% 크기. PhysicsBody는 16 유지(NoteNode init 분리)
    /// 음표 스폰 주기 (초). GDD §5 easy.
    static let noteSpawnInterval: TimeInterval = 1.5
    /// 동시에 떠 있을 수 있는 음표 최대 개수. GDD §5 easy.
    static let noteMaxConcurrent: Int = 5
    /// 음표/변기 스폰 후보 위치 재시도 횟수. 실패 시 해당 스폰 tick은 noop.
    static let spawnPositionMaxAttempts: Int = 12
    /// 음표/변기 수집 hitbox 반경. NoteNode physicsBody 16×16, ToiletNode physicsBody 16×16 기준.
    static let spawnCollectibleHalfExtent: CGFloat = 8

    // MARK: - Combo (Phase 2-5)
    /// 콤보 윈도우 (초). 마지막 수집 후 이 시간 이내 재수집 안 하면 콤보 0. GDD §8.
    static let comboWindow: TimeInterval = 2.5
    /// 콤보 점수 보너스 임계. 이 값 이상부터 점수 ×2. GDD §8.
    static let comboBonusThreshold: Int = 3
    /// 음표 1개 수집 시 가산 점수 (기본). GDD §8.
    static let scorePerNote: Int = 1
    /// 콤보 보너스 발동 시 음표 1개당 가산 점수. GDD §8.
    static let scorePerNoteCombo: Int = 2

    // MARK: - Enemy (Phase 2-6)
    /// 수간호사 박스 가로 (pt). GDD §7-4 16×20.
    static let enemyWidth: CGFloat = 16
    /// 수간호사 박스 세로 (pt). GDD §7-4 16×20.
    static let enemyHeight: CGFloat = 20

    // MARK: - Projectile (Phase 2-7)
    /// F 투사체 한 변 (pt). GDD §7-5 16×16.
    static let projectileSize: CGFloat = 16
    /// F 발사 주기 시작값 (초). GDD §5 easy 시작값. Phase 2-9에서 IntervalEnd(2.0)까지 선형 보간.
    static let projectileFireInterval: TimeInterval = 3.5
    /// F 발사 주기 끝값 (초). 게임 종료 시점 도달값. GDD §5 easy.
    /// Phase 2-9 — 시간 보간으로 projectileFireInterval(3.5)에서 이 값(2.0)까지 선형 감소.
    static let projectileFireIntervalEnd: TimeInterval = 2.0
    /// 동시에 떠 있을 수 있는 F 최대 수. GDD §5 easy.
    static let projectileMaxConcurrent: Int = 2

    // MARK: - Stone Guard (Phase 4-1)
    /// 석조무사 박스 가로 (pt). GDD §7-6 — 수간호사와 동일 16×20.
    static let stoneGuardWidth: CGFloat = 16
    /// 석조무사 박스 세로 (pt). GDD §7-6 16×20.
    static let stoneGuardHeight: CGFloat = 20
    /// 석조무사 패트롤 속도 (pt/s). GDD §7-6 — 시간 보간 없음(단일 상수).
    static let stoneGuardSpeed: CGFloat = 55
    /// Sprint 10 Phase F — 패트롤 SKAction 키. selectInitialWaypoint 재시작 시 removeAction(forKey:) 멱등 처리.
    static let stoneGuardPatrolActionKey: String = "stoneGuardPatrol"
    /// 석조무사 4 waypoint(시계방향: 좌하 → 우하 → 우상 → 좌상).
    /// Sprint 10 Phase F — 원본 game.js L3221~L3274 byte-equal 재정합.
    /// 옛 200/760·100/380 4점 폐기 → 원본 80/540·80/300 4점 직접 사용.
    /// Sprint 5 — 원본 pt 좌표 경로를 runtime compact 맵으로 축소.
    /// 시계방향: 좌하(80,80) → 우하(540,80) → 우상(540,300) → 좌상(80,300).
    static let stoneGuardWaypoints: [CGPoint] = [
        scaledMapPoint(x: 80,  y: 80),    // 좌하 — 원본 leftX=80, topY=80
        scaledMapPoint(x: 540, y: 80),    // 우하 — 원본 rightX=540
        scaledMapPoint(x: 540, y: 300),   // 우상 — 원본 bottomY=300
        scaledMapPoint(x: 80,  y: 300)    // 좌상
    ]

    // MARK: - Airforce Easter Egg (Phase 4-3)
    /// Phase 4-6 — 수간호사 도주 모드 지속 시간 (초). GDD §7-7 명시 5초.
    /// trigger 시점에 enemy.startFleeing(duration:)에 전달. 만료 후 자동 추적 재개.
    static let enemyFleeDuration: TimeInterval = 5.0

    // MARK: - Danger Warning Sprint
    static let projectileWarningLineWidth: CGFloat = 3
    static let projectileWarningLinePulseMinRatio: CGFloat = 0.45
    static let projectileWarningLinePulseHalfDuration: TimeInterval = 0.08
    static let projectileWarningLinePulseActionKey: String = "projectileWarningLinePulse"
    static let telegraphBlinkActionKey: String = "telegraphBlink"
    static let projectileNearMissPulseActionKey: String = "projectileNearMissPulse"
    static let projectileNearMissPulseScale: CGFloat = 1.22
    static let projectileNearMissPulseHalfDuration: TimeInterval = 0.08
    static let stethoscopeNearMissPulseActionKey: String = "stethoscopeNearMissPulse"
    static let stethoscopeNearMissPulseScale: CGFloat = 1.18
    static let stethoscopeNearMissPulseHalfDuration: TimeInterval = 0.09
    static let enemyDangerRingRadius: CGFloat = 28
    static let enemyDangerRingLineWidth: CGFloat = 2
    static let enemyDangerRingFillAlpha: CGFloat = 0.08
    static let enemyDangerRingMinAlpha: CGFloat = 0.16
    static let enemyDangerRingAlphaRange: CGFloat = 0.56
    static let enemyDangerRingPulseThreshold: CGFloat = 0.62
    static let enemyDangerRingPulseScale: CGFloat = 1.18
    static let enemyDangerRingPulseHalfDuration: TimeInterval = 0.16
    static let enemyDangerRingPulseActionKey: String = "enemyDangerRingPulse"
    static let playerNearMissRingRadius: CGFloat = 34
    static let playerNearMissRingLineWidth: CGFloat = 3
    static let playerNearMissRingMinAlpha: CGFloat = 0.18
    static let playerNearMissRingAlphaRange: CGFloat = 0.50
    static let playerNearMissRingPulseScale: CGFloat = 1.16
    static let playerNearMissRingPulseHalfDuration: TimeInterval = 0.10
    static let playerNearMissRingPulseActionKey: String = "playerNearMissRingPulse"
    static let warningProfileEasyTelegraphLineLength: CGFloat = 210
    static let warningProfileNormalTelegraphLineLength: CGFloat = 180
    static let warningProfileHardTelegraphLineLength: CGFloat = 150
    static let warningProfileEasyTelegraphLineAlpha: CGFloat = 0.58
    static let warningProfileNormalTelegraphLineAlpha: CGFloat = 0.46
    static let warningProfileHardTelegraphLineAlpha: CGFloat = 0.34
    static let warningProfileEasyEnemyStartDistance: CGFloat = 92
    static let warningProfileNormalEnemyStartDistance: CGFloat = 78
    static let warningProfileHardEnemyStartDistance: CGFloat = 64
    static let warningProfileEasyEnemyCriticalDistance: CGFloat = 34
    static let warningProfileNormalEnemyCriticalDistance: CGFloat = 30
    static let warningProfileHardEnemyCriticalDistance: CGFloat = 26
    static let warningProfileEasyProjectileNearMissRadius: CGFloat = 58
    static let warningProfileNormalProjectileNearMissRadius: CGFloat = 48
    static let warningProfileHardProjectileNearMissRadius: CGFloat = 40
    static let warningProfileEasyProfessorRingAlphaMultiplier: CGFloat = 0.55
    static let warningProfileNormalProfessorRingAlphaMultiplier: CGFloat = 0.45
    static let warningProfileHardProfessorRingAlphaMultiplier: CGFloat = 0.35
    static let bodyHitToastText: String = "접촉 위험!"
    static let projectileHitToastText: String = "F 명중!"
    static let warningProfileFallback = DangerWarningProfile(
        telegraphLineLength: warningProfileEasyTelegraphLineLength,
        telegraphLineAlpha: warningProfileEasyTelegraphLineAlpha,
        showAllBurstLines: true,
        enemyWarningStartDistance: warningProfileEasyEnemyStartDistance,
        enemyWarningCriticalDistance: warningProfileEasyEnemyCriticalDistance,
        projectileNearMissRadius: warningProfileEasyProjectileNearMissRadius,
        professorRingAlphaMultiplier: warningProfileEasyProfessorRingAlphaMultiplier
    )
    static let warningProfileByDifficulty: [Difficulty: DangerWarningProfile] = [
        .easy: warningProfileFallback,
        .normal: DangerWarningProfile(
            telegraphLineLength: warningProfileNormalTelegraphLineLength,
            telegraphLineAlpha: warningProfileNormalTelegraphLineAlpha,
            showAllBurstLines: true,
            enemyWarningStartDistance: warningProfileNormalEnemyStartDistance,
            enemyWarningCriticalDistance: warningProfileNormalEnemyCriticalDistance,
            projectileNearMissRadius: warningProfileNormalProjectileNearMissRadius,
            professorRingAlphaMultiplier: warningProfileNormalProfessorRingAlphaMultiplier
        ),
        .hard: DangerWarningProfile(
            telegraphLineLength: warningProfileHardTelegraphLineLength,
            telegraphLineAlpha: warningProfileHardTelegraphLineAlpha,
            showAllBurstLines: false,
            enemyWarningStartDistance: warningProfileHardEnemyStartDistance,
            enemyWarningCriticalDistance: warningProfileHardEnemyCriticalDistance,
            projectileNearMissRadius: warningProfileHardProjectileNearMissRadius,
            professorRingAlphaMultiplier: warningProfileHardProfessorRingAlphaMultiplier
        )
    ]

    // MARK: - Difficulty (Phase 7-1 → Sprint 10 Phase I)
    /// 난이도별 플레이어 시작 속도 (pt/s). 원본 game.js L101~L105 DIFFICULTY.baseSpeed × SCALE(2).
    /// Sprint 10 Phase I — 140/160/160 → 280/320/320으로 ×2 SCALE 보정 (원본 1:1).
    /// 단일 진실 원천: docs/ORIGINAL_GAME_ANALYSIS.md L938~L951.
    /// PlayerNode.apply(difficulty)가 baseSpeedStart에 set — apply 누락 시 playerBaseSpeed로 fallback.
    static let playerSpeedStartByDifficulty: [Difficulty: CGFloat] = [
        .easy: 280, .normal: 320, .hard: 320
    ]
    /// R2 — 플레이어 속도 곡선 종속 배율. baseSpeedEnd = baseSpeedStart × 1.15 (02_GAME_FEEL §5).
    /// 구 playerSpeedEndByDifficulty(420/500/500 — 원본 maxSpeed × SCALE 2, Sprint 10 Phase I)는
    /// 종속 +50%로 02 명세 ×1.15를 크게 초과해 dict 자체를 본 배율로 대체 (dead 상수 잔존 금지).
    /// 원본 420/500/500 재도입은 R7 페이싱 재조정에서 사용자 승인 후 검토 (SPEC §문서-코드 불일치 3).
    static let playerSpeedEndMultiplier: CGFloat = 1.15
    /// 난이도별 동시 음표 최대 수. Sprint tuning — 화면에 목표가 더 자주 보이도록 전체 밀도 상향.
    static let noteMaxConcurrentByDifficulty: [Difficulty: Int] = [
        .easy: 10, .normal: 9, .hard: 9
    ]
    /// 난이도별 음표 TTL (초). easy = `.infinity` → applyLifetime 가드로 자가 소멸 미부착 → 기존 동작 정확 보존.
    /// normal/hard만 자가 소멸 SKAction 부착(주의사항 2).
    static let noteLifetimeByDifficulty: [Difficulty: TimeInterval] = [
        .easy: .infinity, .normal: 4.0, .hard: 3.4
    ]
    /// 난이도별 F 동시 최대 수. easy(2)는 기존 projectileMaxConcurrent와 동일.
    static let projectileMaxConcurrentByDifficulty: [Difficulty: Int] = [
        .easy: 4, .normal: 15, .hard: 22
    ]
    /// 난이도별 F 동시 burst 발사 수. Sprint tuning — 회피 압박을 키우기 위해 각 발사 묶음을 상향.
    static let projectileBurstCountByDifficulty: [Difficulty: Int] = [
        .easy: 3, .normal: 6, .hard: 8
    ]
    /// 난이도별 F 발사 주기 시작값 (초). Sprint tuning — 첫 압박 도달 시간을 앞당긴다.
    static let projectileFireIntervalStartByDifficulty: [Difficulty: TimeInterval] = [
        .easy: 1.9, .normal: 1.30, .hard: 1.05
    ]
    /// 난이도별 F 발사 주기 끝값 (초). Sprint tuning — 후반부 탄막 템포를 더 빠르게 만든다.
    static let projectileFireIntervalEndByDifficulty: [Difficulty: TimeInterval] = [
        .easy: 1.2, .normal: 0.68, .hard: 0.48
    ]
    /// 난이도별 F 벽 통과 정책. normal·hard가 벽 contact 없이 수명으로 정리한다.
    static let projectilePassesWallsByDifficulty: [Difficulty: Bool] = [
        .easy: false, .normal: true, .hard: true
    ]
    /// 난이도별 F 자동 수명. hard 벽 통과 시 누적 방지를 위해 필수다.
    static let projectileLifetimeByDifficulty: [Difficulty: TimeInterval] = [
        .easy: 3.0, .normal: 3.2, .hard: 3.4
    ]
    static let projectileLifetimeFallback: TimeInterval = 3.0
    static let projectileLifetimeActionKey: String = "projectileLifetime"

    // MARK: - Sprint 10 Phase I — 원본 수치 봉인 (game.js L101~L105 1:1)
    /// 난이도별 스턴 지속 시간 (초). 원본 DIFFICULTY.stun(ms) ÷ 1000. easy=0.4 / normal=0.7 / hard=0.7.
    /// 단일 진실 원천: docs/ORIGINAL_GAME_ANALYSIS.md L938~L951.
    /// 본 Phase는 *상수 추가만* — 적용 위치(스턴 적용 사이트)는 후속 Phase에서 사용 (위험 2).
    static let stunDurationByDifficulty: [Difficulty: TimeInterval] = [
        .easy: 0.4, .normal: 0.7, .hard: 0.7
    ]
    /// 난이도별 음표 spawn 주기 (초). Sprint tuning — F 압박 증가와 함께 수집 목표도 더 풍성하게 만든다.
    /// SpawnSystem.apply(difficulty)가 인스턴스 프로퍼티 noteSpawnInterval에 set.
    /// 원본은 frame-fill(매 프레임 즉시 보충), iOS는 timer 차등 — OQ-C 후속 정밀화 보류.
    static let noteSpawnIntervalByDifficulty: [Difficulty: TimeInterval] = [
        .easy: 0.5, .normal: 0.34, .hard: 0.28
    ]
    static let notePatternEverySpawn: Int = 5
    static let notePatternSize: Int = 4
    static let notePatternSpacing: CGFloat = 48

    // MARK: - Wall Tile (Runtime Compact)
    /// 벽 셀 노드 이름. enumerate/디버그 검색용. breakableWallName("breakableWall")과 분리.
    static let wallTileNodeName: String = "wallTile"

    // MARK: - Easy Map (Sprint 10 Phase C — 원본 game.js L267~L271)
    // 중앙 2×4 픽셀 기둥 1개 — 원본 좌표 m[r][c]=1 r∈[8..11], c∈[15..16].
    // iosRow = 19 - origR로 변환(MapNode.convertOrigRowToIOS).

    /// Easy 중앙 기둥 시작 원본 행(r=8).
    static let easyMapCenterPillarOrigRStart: Int = 8
    /// Easy 중앙 기둥 끝 원본 행(r=11).
    static let easyMapCenterPillarOrigREnd:   Int = 11
    /// Easy 중앙 기둥 시작 열(c=15).
    static let easyMapCenterPillarColStart:   Int = 15
    /// Easy 중앙 기둥 끝 열(c=16).
    static let easyMapCenterPillarColEnd:     Int = 16

    // MARK: - Hard Map (Sprint 10 Phase C — 원본 game.js L288~L309)
    // 4 모서리 방 + 중앙 기둥 4개. 모든 좌표는 *원본* 기준(origR) — iOS 변환은 MapNode가 담당.
    // 옛 wide-map 좌표 상수는 제거 — 호출자(GameScene+Setup)도 함께 정리.

    // 좌상 방 — m[5][4..9]=1 + m[2..5][9]=1 (문 m[3][9]=0)
    /// 가로벽 행(r=5).
    static let hardMapRoomTopLeftHWallOrigR:      Int = 5
    static let hardMapRoomTopLeftHWallColStart:   Int = 4
    static let hardMapRoomTopLeftHWallColEnd:     Int = 9
    /// 세로벽 열(c=9).
    static let hardMapRoomTopLeftVWallCol:        Int = 9
    static let hardMapRoomTopLeftVWallOrigRStart: Int = 2
    static let hardMapRoomTopLeftVWallOrigREnd:   Int = 5
    /// 문 행(r=3) — 세로벽에서 1칸 건너뜀.
    static let hardMapRoomTopLeftDoorOrigR:       Int = 3

    // 우상 방 — m[5][22..27]=1 + m[2..5][22]=1 (문 m[3][22]=0)
    static let hardMapRoomTopRightHWallOrigR:      Int = 5
    static let hardMapRoomTopRightHWallColStart:   Int = 22
    static let hardMapRoomTopRightHWallColEnd:     Int = 27
    static let hardMapRoomTopRightVWallCol:        Int = 22
    static let hardMapRoomTopRightVWallOrigRStart: Int = 2
    static let hardMapRoomTopRightVWallOrigREnd:   Int = 5
    static let hardMapRoomTopRightDoorOrigR:       Int = 3

    // 좌하 방 — m[14][4..9]=1 + m[14..17][9]=1 (문 m[16][9]=0)
    static let hardMapRoomBottomLeftHWallOrigR:      Int = 14
    static let hardMapRoomBottomLeftHWallColStart:   Int = 4
    static let hardMapRoomBottomLeftHWallColEnd:     Int = 9
    static let hardMapRoomBottomLeftVWallCol:        Int = 9
    static let hardMapRoomBottomLeftVWallOrigRStart: Int = 14
    static let hardMapRoomBottomLeftVWallOrigREnd:   Int = 17
    static let hardMapRoomBottomLeftDoorOrigR:       Int = 16

    // 우하 방 — m[14][22..27]=1 + m[14..17][22]=1 (문 m[16][22]=0)
    static let hardMapRoomBottomRightHWallOrigR:      Int = 14
    static let hardMapRoomBottomRightHWallColStart:   Int = 22
    static let hardMapRoomBottomRightHWallColEnd:     Int = 27
    static let hardMapRoomBottomRightVWallCol:        Int = 22
    static let hardMapRoomBottomRightVWallOrigRStart: Int = 14
    static let hardMapRoomBottomRightVWallOrigREnd:   Int = 17
    static let hardMapRoomBottomRightDoorOrigR:       Int = 16

    // 중앙 기둥 4개 (원본 game.js)
    // 중앙-좌: m[9..10][12]=1 (1×2 세로)
    static let hardMapCenterLeftPillarCol:         Int = 12
    static let hardMapCenterLeftPillarOrigRStart:  Int = 9
    static let hardMapCenterLeftPillarOrigREnd:    Int = 10
    // 중앙-우: m[9..10][19]=1 (1×2 세로)
    static let hardMapCenterRightPillarCol:        Int = 19
    static let hardMapCenterRightPillarOrigRStart: Int = 9
    static let hardMapCenterRightPillarOrigREnd:   Int = 10
    // 중앙-상: m[7][15..16]=1 (2×1 가로)
    static let hardMapCenterTopPillarColStart:     Int = 15
    static let hardMapCenterTopPillarColEnd:       Int = 16
    static let hardMapCenterTopPillarOrigR:        Int = 7
    // 중앙-하: m[12][15..16]=1 (2×1 가로)
    static let hardMapCenterBottomPillarColStart:  Int = 15
    static let hardMapCenterBottomPillarColEnd:    Int = 16
    static let hardMapCenterBottomPillarOrigR:     Int = 12

    // MARK: - Diploma (Phase 7-4)
    /// 난이도별 졸업 목표 점수. 캐릭터 × 난이도 매트릭스에서 이 점수 이상 달성하면 그 난이도 "통과".
    /// 난이도가 올라갈수록 목표 점수도 함께 올라가도록 정렬한다.
    /// 실제 체감 난이도는 F 밀도/발사 주기/음표 TTL이 담당하고, 이 값은 결과 화면의 "졸업 기준"을 담당한다.
    /// `[Difficulty: Int]` dict — Difficulty enum이 단일 진실 원천. 추가 난이도 시 dict 한 줄만 늘리면 됨.
    static let targetScoreByDifficulty: [Difficulty: Int] = [
        .easy: 70, .normal: 50, .hard: 40   // 화면 라벨 하=70 / 중=50 / 상=40 (easy↔hard 역전, normal 유지)
    ]
    /// 난이도 dict 조회 실패 시 안전 기본 졸업 목표(강제 언래핑 회피). normal과 동일 값.
    static let targetScoreByDifficultyFallback: Int = 50
    /// 다음 캐릭터 해금에 필요한 이전 캐릭터의 단일 난이도 최고점.
    static let characterUnlockRequiredScore: Int = 25
    /// 캐릭터 홈 잠김 설명 문구.
    static let characterUnlockRequirementText: String = "이전 캐릭터로 25점 달성"
    /// Sprint 2 — 결과 화면 목표 근접 판정 비율. target의 80% 이상이면 "거의 왔다".
    static let goalNearRatio: Double = 0.8

    // MARK: - Pixel Sprite (Phase 8-1)
    /// 16×20 픽셀 스프라이트의 점(pt) 단위 확대 배율. 화면에서 32×40pt로 보이도록 2배 확대.
    /// physicsBody 크기(playerWidth/playerHeight)는 *그대로* — 게임 hitbox 회귀 0.
    /// 시각만 커지므로 카메라 follow / 충돌 / 맵 경계 영향 0.
    static let pixelSpriteScale: CGFloat = 2
    /// 걷기 애니메이션의 step1↔step2 교차 주기 (초). 0.18 = 1초당 ~5.5회 교차 — *총총* 보행 톤.
    /// 너무 짧으면 후드득 떨림, 너무 길면 *멈춤*처럼 보임. 픽셀 retro 게임 평균 보행 주기.
    /// 적/빌런(EnemyNode·StoneGuardNode·ProfessorNode) 공유 — 이 값을 바꾸면 그들 보행 속도까지 변한다.
    static let pixelWalkFrameInterval: TimeInterval = 0.18
    /// 플레이어 전용 step1↔step2 교차 주기 (초). 0.11 = 1초당 ~9회 교차 — 적/빌런(0.18)보다 또렷이 빠른
    /// 직접 조작 보행 톤. 전역 pixelWalkFrameInterval과 분리해 적/빌런 보행 속도에 영향 0.
    static let playerWalkFrameInterval: TimeInterval = 0.11
    /// R0 — 4방향 산출 velocity 임계값 (pt/s). 분리형(A: Player/Enemy) 노드가 사용.
    /// 기존 인라인 리터럴 0.1의 상수화 — 값 변경 0 (physics 미세 잔존 velocity의 시각 흔들림 방지 가드).
    static let pixelDirectionVelocityThreshold: CGFloat = 0.1
    /// R0 — 4방향 산출 position-delta 임계값 (pt/frame). 통합형(B: Professor/StoneGuard) 노드가 사용.
    /// 기존 인라인 리터럴 0.01의 상수화 — 값 변경 0.
    static let pixelDirectionPositionDeltaThreshold: CGFloat = 0.01

    // MARK: - Checkerboard Floor (Phase 9-4)
    /// 체크보드 컨테이너 노드 이름. 디버깅/탐색용 식별자 — 호출부 리터럴 노출 금지.
    static let checkerboardContainerName: String = "checkerboardFloor"

    // MARK: - Normal Map (Sprint 10 Phase C — DIFFICULTY 매핑상 hard 공유)
    // 원본 game.js L102~L104: DIFFICULTY = { easy, normal: 'hard', hard }.
    // normal 난이도는 hard 빌더를 그대로 호출 — 별도 좌표 상수 0(MapNode.buildWalls가 switch에서 .hard와 같은 케이스로 위임).
    // 옛 wide-map 좌표 상수는 제거 — 호출자(GameScene+Setup) 함께 정리.

    // MARK: - Skill (Phase 9-5)
    /// 캐릭터별 스킬 시스템. SkillSystem이 호출, HUDSkillSlotNode가 시각화.
    /// 4 스킬(정/건/임/이) + 김간호는 *스킬 없음*(정공법 정체성).

    // 공통 — SkillButtonNode (우하단 1탭 발동)
    /// R2 — 스킬 버튼 입력 버퍼 (초). 쿨다운 잔여 ≤ 이 값일 때의 탭을 보관했다가
    /// 쿨다운 0 도달 프레임에 1회 자동 발동 (02_GAME_FEEL §5 — 쿨다운 종료 직전 입력 허용).
    static let skillInputBufferWindow: TimeInterval = 0.1
    /// 스킬 버튼 반지름 (pt). D-Pad 한 변(44)과 시각 균형.
    static let skillButtonRadius: CGFloat = 32
    /// 버튼 우측 가장자리에서의 안쪽 마진 (pt). cameraNode 자식 좌표계 기준.
    /// 좌하단 D-Pad와 대칭 — 두 손가락 자연 위치.
    static let skillButtonMarginX: CGFloat = 72
    /// 버튼 하단 가장자리에서의 안쪽 마진 (pt). D-Pad와 동일 높이로 정렬.
    static let skillButtonMarginY: CGFloat = 90
    /// 김간호 비활성 알파. dpadAlpha(0.7)보다 낮아 "비활성" 시그널 강조.
    static let skillButtonInactiveAlpha: CGFloat = 0.3
    /// 활성 알파. dpadAlpha(0.7)보다 살짝 높아 *눌러야 할 버튼*임 강조.
    static let skillButtonActiveAlpha: CGFloat = 0.85
    /// HUDSkillSlotNode가 SkillButtonNode 중심에서 위로 얼마나 떨어진 곳에 배치되는가 (pt).
    /// 32(반지름) + 12(링 반지름) + 6(여백) ≈ 50.
    static let hudSkillSlotOffsetY: CGFloat = 50

    // 정간호 — 암벽등반 돌진 (.dashClimb)
    /// 돌진 이동 거리 (pt). 4 tile.
    static let dashClimbDistance: CGFloat = tileSize * 4
    /// 돌진 지속 시간 (초). 돌진 중 isInvulnerable.
    static let dashClimbDuration: TimeInterval = 0.22
    /// 돌진 쿨다운 (초). 22초.
    static let dashClimbCooldown: TimeInterval = 22
    static let dashClimbActionKey: String = "dashClimbMove"
    static let dashClimbProjectileClearHalfWidth: CGFloat = tileSize
    static let dashClimbImpactRadius: CGFloat = tileSize * 1.8
    static let dashClimbLandingSearchSteps: Int = 10
    /// 돌진 경로(corridor) 음표 흡수 폭 (pt). F 제거 폭(tileSize)보다 약간 넓게 — "지나가며 빨아들임".
    static let dashClimbCollectHalfWidth: CGFloat = tileSize * 1.4
    /// 착지 주변 F 원형 정화 반경 (pt). corridor 밖까지 정리 — 착지 안전 확보.
    static let dashClimbLandingPurgeRadius: CGFloat = tileSize * 2.0
    /// 착지 후 무적 추가 유지 시간 (초). 돌진 종료 직후 죽음 방지용 짧은 여유.
    static let dashClimbLandingInvulnerableExtra: TimeInterval = 0.35
    /// 돌진 corridor 안 breakable 벽 매칭 폭 (pt). 플레이어 폭 기준 — 지나가는 통로의 벽만 부숨.
    /// 음표 흡수(dashClimbCollectHalfWidth)보다 좁게 — 옆 칸 벽 과잉 파괴 방지.
    static let dashClimbWallBreakHalfWidth: CGFloat = playerWidth
    /// 부서지는 벽 fadeOut 시간 (초). 시각적 "부서지는" 톤 — physics는 그 전에 즉시 nil 처리.
    static let dashClimbWallBreakFadeDuration: TimeInterval = 0.15

    // 건간호 — 북클럽 소집 (.bookClubRally)
    /// 끌어오기 반경 (pt). 8 tile.
    static let bookClubRallyRadius: CGFloat = tileSize * 8
    /// 끌어오기 SKAction.move duration (초). easeIn 곡선과 함께 *자연스러운 가속*.
    static let bookClubRallyMoveDuration: TimeInterval = 0.28
    /// 북클럽 쿨다운 (초). 20초.
    static let bookClubRallyCooldown: TimeInterval = 20
    static let bookClubRallyPullActionKey: String = "bookClubRallyPull"
    static let bookClubRallySparkleActionKey: String = "bookClubRallySparkle"
    /// 2겹 충격파 바깥 링 반경 비율. 안쪽(radius) 대비 0.6배 안쪽 링 — "안전지대 폭발" 다층 톤.
    static let bookClubRallyOuterRingRatio: CGFloat = 0.6

    // 임간호 — 나는야 모범생 (.charmStudent, 게임당 1회)
    /// 매혹 지속 시간 (초). 수간호사 발사 주기보다 길게 잡아 최소 1회 이상 A 투척을 체감하게 한다.
    static let charmStudentDuration: TimeInterval = 4.0
    /// 매혹된 노트 수집 시 보너스 점수. scorePerNoteCombo(2)의 2배 = 4점.
    static let charmStudentBonusScore: Int = 4
    static let charmStudentToastText: String = "매혹!"
    /// 매혹 발동 시각 링 반경 (pt). 3 tile — 전역 매혹의 무게감을 player 발밑에서 시작.
    static let charmStudentRingRadius: CGFloat = tileSize * 3
    /// 매혹 2겹 링 바깥 비율. 안쪽(charmStudentRingRadius) 대비 1.5배 — 하트펄스 톤 2겹.
    static let charmStudentOuterRingRatio: CGFloat = 1.5

    // 이간호 — 대만여행 / 텔레포트 (.taiwanTrip)
    /// 레거시 값. V2 대만여행은 고정 거리 대신 현재 위치의 반대 대각선 안전 지점으로 이동한다.
    static let taiwanTripJumpDistance: CGFloat = 100
    /// 반대 대각선 코너가 벽일 때 주변 몇 타일까지 빈 위치를 찾을지.
    static let taiwanTripFallbackSearchRings: Int = 8
    /// 텔레포트 쿨다운 (초). 22초.
    static let taiwanTripCooldown: TimeInterval = 22
    /// 무적 깜빡임 시 최소 알파.
    static let taiwanTripFlashAlpha: CGFloat = 0.4
    /// 깜빡임 한 단계 길이 (초). 0.1 = 0.5초 동안 5회 깜빡임 (1.0 ↔ 0.4).
    static let taiwanTripFlashHalfPeriod: TimeInterval = 0.1
    static let taiwanTripDepartureRingRadius: CGFloat = tileSize * 2
    static let taiwanTripLandingPurgeRadius: CGFloat = tileSize * 4
    static let taiwanTripBlinkActionKey: String = "taiwanTripBlink"
    static let taiwanTripInvulnerableActionKey: String = "taiwanTripInvulnerable"
    /// 착지 주변 음표 흡수 반경 (pt). 착지 정화 반경(taiwanTripLandingPurgeRadius)과 정렬한 4 tile.
    static let taiwanTripCollectRadius: CGFloat = tileSize * 4
    /// 출발 지점 F 정화 반경 (pt). 출발 링 반경(taiwanTripDepartureRingRadius)과 정렬한 2 tile.
    static let taiwanTripDeparturePurgeRadius: CGFloat = tileSize * 2
    /// 연장된 무적/깜빡임 길이 (초). 레거시 taiwanTripInvulnerableDuration(1.0)을 대체하는 V2 값.
    /// applyTaiwanTripBlink의 totalDuration과 PlayerSkill.duration(.taiwanTrip) *둘 다* 이 상수를 참조 —
    /// 두 곳이 다른 값을 보면 progress·무적·깜빡임 종료가 어긋난다. 레거시 1.0 상수는 값 보존(미참조).
    static let taiwanTripInvulnerableDuration: TimeInterval = 1.6

    // 식별자 (벽 파괴 enumerate 대상)
    /// breakable 벽의 노드 이름. SkillSystem의 dashClimb이 enumerate 시 사용.
    /// 호출부 리터럴 노출 금지 — 단일 진실 원천.
    static let breakableWallName: String = "breakableWall"

    // MARK: - Toilet Bonus (Phase 9-6)
    /// 변기 보너스 — 12초마다 15% 확률 단일 스폰 + 8초 자동 소멸 + 음표 2개 효과 + "화캉스 보너스!" 토스트.
    /// Bernoulli 단일 시도 모델: 매 12초 사이클마다 1회 판정 (확률 누적 없음). 평균 스폰 간격 ≈ 80초.

    /// 변기 픽셀 한 변 (pt). 음표(16) / projectile(16)과 동급 — 시각 균형.
    /// 노드 visual 크기. 텍스처 자체는 PixelSpriteRenderer 표준 16×20 (상단 4행 transparent padding) →
    /// SKSpriteNode가 16×16으로 표시 시 살짝 vertical squish — 픽셀 retro 톤에 자연 흡수.
    static let toiletSize: CGFloat = 16
    /// 변기 스폰 사이클 길이 (초). 매 사이클마다 1회 확률 판정. GDD §7-3.
    static let toiletSpawnInterval: TimeInterval = 12.0
    /// 변기 스폰 1회 판정 성공 확률 (0..1). 매 사이클 단일 Bernoulli — 확률 누적 없음.
    /// 평균 스폰 간격 = toiletSpawnInterval / toiletSpawnProbability ≈ 80초. GDD §7-3.
    static let toiletSpawnProbability: CGFloat = 0.15
    /// 변기 자동 소멸까지의 미수집 lifetime (초). 8초 후 fadeOut + removeFromParent. GDD §7-3.
    static let toiletLifetime: TimeInterval = 8.0
    /// 변기 자동 소멸 직전 fadeOut 액션 길이 (초). 0.3 = sparkleFadeDuration(0.5)의 60% —
    /// *사라지는 잔향*은 짧고 단호. 노트 lifetime 끝 fadeOut과 디자인 통일.
    static let toiletFadeOutDuration: TimeInterval = 0.3
    /// 동시에 존재 가능한 변기 최대 수. 1 = 단일성 정책 (SPEC.md §스폰 모델 결정).
    /// 화면 어수선함 차단 + 체감 확률 정확(여러 개 동시 출현 시 *희소함* 톤 상실).
    static let toiletMaxConcurrent: Int = 1
    /// 변기 ScorePopup fan-out 가로 offset (pt). 좌·우 ±8 = 음표 2개 동시 수집 시각 시그널.
    /// note 한 변(16)의 절반 — 두 라벨이 겹치지 않으면서 *동시 수집* 의미 전달.
    static let toiletScorePopupFanOutX: CGFloat = 8

    // MARK: - Professor (Phase 9-7)
    /// 이교수(ProfessorNode) — 상 난이도 전용 두 번째 적 NPC. 4 waypoint 순찰 + 청진기 투척.
    /// 수간호사(EnemyNode 추적 AI)와 석조무사(StoneGuardNode 패트롤) 사이의 중간형 — *순찰 + 원거리 공격*.

    /// 이교수 박스 가로 (pt). 수간호사/김간호와 동일 16×20.
    static let professorWidth: CGFloat = 16
    /// 이교수 박스 세로 (pt). 수간호사/김간호와 동일 16×20.
    static let professorHeight: CGFloat = 20
    /// 이교수 패트롤 속도 (pt/s). Hard 전용 압박은 유지하되 F와 겹칠 때의 회피 불가능 구간을 줄인다.
    static let professorSpeed: CGFloat = 60
    /// Sprint 10 Phase F — 원본 game.js L109~L115/L2983~L3019 byte-equal 8자(figure-8) 4점 순환.
    /// 옛 시계방향 직사각형(320/640 × 200/280) 폐기 → 원본 8자 좌표 직접 사용.
    /// Sprint 5 — 원본 pt 좌표 경로를 runtime compact 맵으로 축소.
    /// 8자 순서: 좌하(120,100) → 우상(520,280) → 우하(520,100) → 좌상(120,280) → (loop).
    static let professorWaypoints: [CGPoint] = [
        scaledMapPoint(x: 120, y: 100),   // 시작점 — 좌하
        scaledMapPoint(x: 520, y: 280),   // 대각선 우상 (8자 첫 교차 후)
        scaledMapPoint(x: 520, y: 100),   // 우하
        scaledMapPoint(x: 120, y: 280)    // 좌상 (8자 두 번째 교차)
    ]
    /// 청진기 발사 SKAction 키. stopThrowing/scheduleNextThrow가 공유 → endGame에서 removeAction(forKey:) 일괄 정지.
    /// 호출부 리터럴 노출 금지 — 단일 진실 원천.
    static let professorThrowActionKey: String = "professorThrow"
    /// Sprint 10 Phase F — 패트롤 SKAction 키. selectInitialWaypoint가 재시작 시 removeAction(forKey:)로 멱등 처리.
    /// throw 키와 분리 — 패트롤/투척 정책 독립 정지·재시작 가능.
    static let professorPatrolActionKey: String = "professorPatrol"
    /// 경고 컷씬 제목. 호출부 리터럴 노출 금지.
    static let professorWarningTitle: String = "경고 · 이교수 출현"
    /// 경고 컷씬 본문. GDD §10 + 사용자 요청 결합.
    static let professorWarningBody: String = "학교에서 나온 깐깐한 이교수가 청진기를 들고 순찰을 돕니다! 맞으면 잠시 움직일 수 없게 됩니다. 피하세요."

    // MARK: - Stethoscope (Phase 9-7)
    /// 청진기 투사체 — FProjectileNode(F)와 분리된 별도 PhysicsCategory.stethoscope 사용.
    /// 적중 시 즉시 게임오버가 아닌 *2초 정지* — F와 정체성 분리.

    /// 청진기 한 변 (pt). projectile(16)/note(16)보다 살짝 크게 — *위협 시그널* 강조.
    static let stethoscopeSize: CGFloat = 18
    /// 청진기 속도 (pt/s). F와 겹칠 때도 보고 피할 수 있도록 Hard 압박을 완화한다.
    static let stethoscopeSpeed: CGFloat = 190
    /// 발사 주기 시작값 (초). 게임 시작 시점 도달값. 게임 진행률 0 → 3.2초.
    static let stethoscopeThrowIntervalStart: TimeInterval = 3.2
    /// 발사 주기 끝값 (초). 게임 종료 시점 도달값. 게임 진행률 1 → 2.1초.
    static let stethoscopeThrowIntervalEnd: TimeInterval = 2.1
    /// 동시에 떠 있을 수 있는 청진기 최대 수. 다발(fanCount) 한 사이클 + 직전 사이클 잔존 여유.
    /// stethoscopeFanCount 이상이어야 throwStethoscope의 사이클 진입 가드를 다발이 통과한다.
    static let stethoscopeMaxConcurrent: Int = 8
    /// 한 발사 사이클에 흩뿌리는 청진기 개수. 플레이어 향 1개(0번) + 나머지 radial 분산.
    static let stethoscopeFanCount: Int = 5
    /// 다발 분산 각도 폭(radian). 2π = 전방위 균등 radial. 값을 좁히면 플레이어 각도 중심 부채꼴.
    static let stethoscopeFanSpreadRadians: CGFloat = .pi * 2
    /// 다발 각 방향 경고선 노출 여부. 공정성 — 모든 방향을 텔레그래프 0.4s 동안 예고.
    static let stethoscopeFanWarningLinesEnabled: Bool = true
    /// 청진기 회전 1회전 길이 (초). 시각 회전 SKAction.rotate — 충돌 박스 무관 (allowsRotation=false).
    /// Sprint 10 Phase E — 원본 game.js L2922~L2960 `now/100 % 2π` 일치(2π × 0.1 ≈ 0.628초).
    static let stethoscopeRotationDuration: TimeInterval = 0.628
    /// "청진기 명중!" 0.9초 토스트 텍스트. 호출부 리터럴 노출 금지.
    static let stethoscopeToastText: String = "청진기 명중!"

    // MARK: - Player Freeze (Phase 9-7)
    /// 플레이어 동결 시스템 — 청진기 피격 시 2초간 이동 입력 차단.
    /// 무적(isInvulnerable) 우선 정책: 무적 중 freeze 호출은 noop.
    /// 재호출 noop: 이미 frozen이면 2초 *고정* — 누적 안 함 (연사 무한 정지 방지).

    /// 동결 지속 시간 (초). 2초 — 수간호사 F 한 발 거리.
    static let playerFreezeDuration: TimeInterval = 2.0
    /// 동결 깜빡임 한 단계 길이 (초). 0.2 = 2초 동안 5회 깜빡임 (1.0 ↔ 0.4).
    /// 무적 깜빡임(taiwanTripFlashHalfPeriod=0.1)의 2배 — 느리고 *무거운* 톤.
    static let frozenBlinkHalfPeriod: TimeInterval = 0.2
    /// 동결 깜빡임 시 최소 알파. 무적과 동일(0.4) — 시각 일관성.
    static let frozenBlinkMinAlpha: CGFloat = 0.4
    /// 동결 SKAction 키. 재호출 가드 + endGame 일괄 정지용 (필요 시).
    /// 호출부 리터럴 노출 금지 — 단일 진실 원천.
    static let playerFreezeActionKey: String = "playerFreeze"

    // MARK: - Sprint 8 Phase G · 인게임 시각 통합 V4
    //
    // 박병장 hard 난이도 데뷔(30s OR 50점) + 2.2s 컷씬 + 8s 등장.
    // 비행기 6 자식(fuselage/wings/tail/cockpit/propeller/contrail) 시각 — 노란 사각형 → 비행기 형상.
    // 플레이어 풀바디(CharacterFullBodyNode) — D-Pad 입력 시 팔다리 보이는 캐릭터.
    // physicsBody/AI/이동 *0줄 변경* — 시각 layer만 강화.

    // 박병장 데뷔
    /// 박병장 hard 난이도 데뷔 트리거 시간(30s). score 기준과 OR.
    static let sergeantParkDebutTime: Double = 30.0
    /// 박병장 hard 난이도 데뷔 트리거 점수(50pt). time 기준과 OR.
    static let sergeantParkDebutScore: Int = 50
    /// 박병장 등장 후 화면 머무는 시간(8.0s).
    static let sergeantParkOnStageDuration: Double = 8.0

    // MARK: - Nurse Chief Patrol (Sprint 10 Phase D)
    // 원본 game.js L2584~L2638 (4지점 사각 순환 패트롤) + L2722~L2743 (텔레그래프) byte-equal.
    // 단일 진실 원천: docs/ORIGINAL_GAME_ANALYSIS.md L443~L500 + SPEC.md §2/§3.
    /// 난이도별 패트롤 4지점 (혹은 easy 2지점). Runtime compact 셀 중심에 정렬한다.
    /// fallback 정책: dict 미스 시 [] → updatePatrol이 velocity=.zero로 정지 (apply 누락 graceful fallback).
    ///
    /// Sprint 10.5 Phase C — 셀 중심 정렬 (120/640 → 140/660).
    ///   원본 leftX=60 → iOS = TILE_PT(20)×3 + TILE_PT/2(10) = 70 × SCALE(2) = 140.
    ///   기존 (120,120)은 SCALE 변환 누락 잔재 — 셀 *모서리* 좌표라 적 body 16×20이
    ///   row 3 셀(y 120-160) 하단 모서리(y=110)에 10pt 클립되어 벽에 끼는 원인이었음.
    ///   새 좌표 (140,140)은 셀 정중앙 → row 3 셀 완전 수용, col 9/22 vWall 도어(BL/BR row 16, TL/TR row 3) 통과 보장.
    /// Sprint 5 — 같은 셀 중심 의미를 runtime tileSize 기준 helper로 유지.
    static let nurseChiefWaypointsByDifficulty: [Difficulty: [CGPoint]] = [
        .easy: [
            cellPoint(x: 3.5, y: 3.5),
            cellPoint(x: 28.5, y: 3.5)
        ],
        .normal: [
            cellPoint(x: 3.5, y: 3.5),
            cellPoint(x: 28.5, y: 16.5),
            cellPoint(x: 28.5, y: 3.5),
            cellPoint(x: 3.5, y: 16.5)
        ],
        .hard: [
            cellPoint(x: 3.5, y: 3.5),
            cellPoint(x: 28.5, y: 3.5),
            cellPoint(x: 28.5, y: 16.5),
            cellPoint(x: 3.5, y: 16.5)
        ]
    ]
    /// 난이도별 패트롤 속도 (pt/s). 모바일 조작 기준으로 Easy 학습 여유와 Hard 압박을 균형 조정.
    static let nurseChiefPatrolSpeedByDifficulty: [Difficulty: CGFloat] = [
        .easy: 70, .normal: 105, .hard: 150
    ]
    /// 패트롤 속도 default. apply 누락 시 EnemyNode 인스턴스 프로퍼티 graceful fallback.
    static let nurseChiefPatrolSpeedDefault: CGFloat = 80
    /// 텔레그래프 지속 시간 (초). 원본 game.js L2728 (TELEGRAPH_DURATION = 0.4) byte-equal.
    static let nurseChiefTelegraphDuration: TimeInterval = 0.4
    /// 텔레그래프 깜빡임 1주기 (초). 원본 game.js L968 (120ms on/off) byte-equal.
    static let nurseChiefTelegraphBlinkInterval: TimeInterval = 0.12
    /// 텔레그래프 ! 표시 y 오프셋 (pt). 원본 -42px × 2, SpriteKit Y↑ → +84.
    static let nurseChiefTelegraphOffsetY: CGFloat = 84
    /// burst 스프레드 step (rad). 원본 game.js L2754 (Math.PI/12) byte-equal — ±15°.
    static let nurseChiefSpreadRadians: CGFloat = .pi / 12
    /// 각 발 jitter (±rad). 원본 game.js L2758 (±0.025) byte-equal.
    static let nurseChiefSpreadJitter: CGFloat = 0.025
    /// 발사 spawn offset — enemy 중심에서 baseAngle 방향으로 24pt 떨어진 곳에서 출현.
    /// 원본 game.js L2762 (12px × 2 = 24pt).
    static let nurseChiefFireStartOffset: CGFloat = 24

    // MARK: - F/A Projectile Speed (Sprint 10 Phase D)
    // 원본 game.js OBS_BASE_SPEED / OBS_MAX_SPEED — currentObsSpeed = base + (max-base) × curveT.
    // 단일 진실 원천: SPEC.md §4.3 (ORIGINAL_GAME_ANALYSIS.md §6.1).
    // iOS = 원본 px/s × 2.
    /// F/A 발사 시작 속도 (pt/s). 다발 수 완화와 함께 난이도별 회피 가능성을 보정한다.
    static let obsBaseSpeedByDifficulty: [Difficulty: CGFloat] = [
        .easy: 120, .normal: 220, .hard: 280
    ]
    /// F/A 발사 끝 속도 (pt/s). curveT=1 도달 시.
    static let obsMaxSpeedByDifficulty: [Difficulty: CGFloat] = [
        .easy: 200, .normal: 360, .hard: 460
    ]

    // MARK: - F Projectile Visual (Sprint 10 Phase D)
    // 원본 12×12 픽셀 매트릭스. PhysicsBody 16×16 hitbox 유지.
    /// F/A 픽셀 매트릭스 한 변 셀 수 (12). 원본 game.js drawF / drawAItem.
    static let fProjectileMatrixSize: Int = 12
    /// F/A 시각 출력 크기 (pt). 12셀 → 24pt 화면 픽셀 (×2 픽셀 톤).
    static let fProjectileVisualSize: CGFloat = 24
    /// F/A physicsBody 한 변 (pt). 원본 hitbox 16×16 보존.
    static let fProjectileSize: CGFloat = 16

    // MARK: - Combo 3-tier (Sprint 10 Phase E)
    // 원본 game.js L811~L817 / L1048~L1052 — combo>=7 +4, >=5 +3, >=3 +2, else +1.
    // 기존 comboBonusThreshold(3) + scorePerNoteCombo(2)는 보존 — 새 Mid/High 상수만 추가.
    /// 콤보 점수 중간 임계. combo >= 5 → 3점 가산. 원본 L1049 (gain=3).
    static let comboBonusThresholdMid: Int = 5
    /// 콤보 점수 최고 임계. combo >= 7 → 4점 가산. 원본 L1048 (gain=4).
    static let comboBonusThresholdHigh: Int = 7
    /// 콤보 mid 발동 시 가산 점수 (3점). 원본 일치.
    static let scorePerNoteComboMid: Int = 3
    /// 콤보 high 발동 시 가산 점수 (4점). 원본 일치.
    static let scorePerNoteComboHigh: Int = 4

    // MARK: - Note Bob (Sprint 10 Phase E)
    // 음표 ±2.4px y bob 0.7초 주기. 인스턴스 phase 랜덤 — 동시 스폰 시 모든 음표 동조 방지.
    /// 음표 bob 진폭 (pt). ±이 값. 원본 톤 압축 — 빠르고 가벼운 *떠 있음* 시그널.
    static let noteBobAmplitude: CGFloat = 2.4
    /// 음표 bob 1주기 길이 (초). 0.7초 = 빠른 톤. SKAction sequence(up+down) 합.
    static let noteBobDuration: TimeInterval = 0.7

    // MARK: - Stethoscope Pixel (Sprint 10 Phase E)
    // 원본 game.js L2922~L2960 drawStethoscope 14×8 매트릭스 → iOS 28×16 (×2).
    // 기존 stethoscopeSize(18)는 보존 — physicsBody 호환 위해 별도 width/height 상수 신설.
    /// 청진기 시각 가로 (pt). 원본 14셀 × 2 = 28. PhysicsBody size와 분리.
    static let stethoscopeWidth: CGFloat = 28
    /// 청진기 시각 세로 (pt). 원본 8셀 × 2 = 16.
    static let stethoscopeHeight: CGFloat = 16

    // MARK: - Professor Sprint 10 Phase F (이교수 텔레그래프 + 청진기 직렬화)
    // 원본 game.js L3084~L3106 청진기 텔레그래프 + L4060~L4084 명중 직렬화 byte-equal.
    // EnemyNode 텔레그래프(0.4s) 정책과 동형 — 단일 진실 원천 일관.

    /// 이교수 청진기 발사 직전 "!" 텔레그래프 표시 시간 (초). 원본 0.4s 일치.
    /// nurseChiefTelegraphDuration(0.4)과 동일 값 — 정책 일관성.
    static let professorTelegraphDuration: TimeInterval = 0.4
    /// 이교수 머리 위 텔레그래프 라벨 y 오프셋 (pt). 픽셀 본체(40pt 높이) 위 살짝 떠 있도록.
    /// 시각 자식 제거 후 head 영역이 픽셀 본체 상단 부근(y ≈ +14) — 그 위에 "!" 표시.
    static let professorTelegraphOffsetY: CGFloat = 14
    /// 이교수 등장 후 첫 청진기 투척까지의 대기 시간 (초).
    /// 플레이어가 새 빌런을 인지·학습할 충분한 시간 제공.
    static let professorInitialThrowDelay: TimeInterval = 3.5
    /// 청진기 발사 시 spawnPoint를 이교수 본체에서 단위벡터 방향으로 밀어내는 거리 (pt).
    /// 원본 L3094 chief + unitVec × 12px — 본체와 충돌해 즉시 사라지는 버그 방지.
    static let stethoscopeFireStartOffset: CGFloat = 12

    // MARK: - Stethoscope Hit Serialization (Sprint 10 Phase F)
    // 원본 game.js L4060~L4084 청진기 명중 시 토스트 1s → freeze 2s 직렬화.

    /// 청진기 명중 시 "청진기 명중!" 토스트 노출 시간 (초). 1.0s.
    /// 토스트 종료 후 freeze 시작 — 두 시퀀스 직렬 연결.
    static let stethoscopeToastDuration: TimeInterval = 1.0

    // MARK: - Sprint 10 Phase G · Airforce Easter Egg Pixel Tone
    /// 수간호사 도주 속도 (pt/s). 원본 fleeSpeed 180 byte-equal.
    /// startFleeing 본문이 단위벡터에 곱해 velocity 부여.
    static let enemyFleeSpeed: CGFloat = 180

    // MARK: - Object Pool (R1)
    // 풀 예열 수치 — 설계서 01_CODE_ARCHITECTURE §8 그대로(변경 금지).
    // 예열은 GameScene.didMove 직후 1회 — 첫 스폰 웨이브의 노드 생성 스파이크 제거.

    /// F 투사체 풀 예열 수. hard 동시 캡(22)의 절반 수준 — 초반 부족분은 lazy 생성으로 흡수.
    static let projectilePoolPreheatCount: Int = 12
    /// 음표 풀 예열 수. 동시 캡 + 패턴 스폰(4발 묶음) 여유분.
    static let notePoolPreheatCount: Int = 16
    /// 청진기 풀 예열 수. hard 전용 — fan 1사이클 분량 커버.
    static let stethoscopePoolPreheatCount: Int = 6
    /// 점수 팝업 풀 예열 수. 변기 보너스(동시 2장) + 연속 수집 잔상 여유분.
    static let scorePopupPoolPreheatCount: Int = 8
}
