//
//  GameConfig.swift
//  GanhoMusic Shared
//
//  Phase 1-1 · Config Bootstrap
//  Phase 1-2 · World 파생값 + Placeholder 상수 추가
//  Phase 1-3 · Player / D-Pad 상수 정식 진입 + 1-2 임시값 정리
//

import Foundation
import CoreGraphics

/// 게임 전역 상수 네임스페이스. case 없는 enum으로 인스턴스화 차단.
enum GameConfig {

    // MARK: - Time
    /// 한 판 길이 (초). GDD §1
    static let gameDuration: TimeInterval = 45

    // MARK: - World
    /// 타일 1칸 크기 (pt). GDD §6
    static let tileSize: CGFloat = 20
    /// 맵 가로 타일 수. Phase 1-5: 32 → 48 (드론 카메라 + 모바일 viewport 대응)
    static let mapColumns: Int = 48
    /// 맵 세로 타일 수. Phase 1-5: 20 → 24
    static let mapRows: Int = 24
    /// 맵 전체 가로 폭 (pt). tileSize × mapColumns = 960. (자동 갱신)
    static let mapWidth: CGFloat = tileSize * CGFloat(mapColumns)
    /// 맵 전체 세로 높이 (pt). tileSize × mapRows = 480. (자동 갱신)
    static let mapHeight: CGFloat = tileSize * CGFloat(mapRows)
    /// 4 모서리 검증 마커 한 변 길이 (pt). 1-2/1-3 공용.
    static let cornerMarkerSize: CGFloat = 16

    // MARK: - Player (Phase 1-3 정식)
    /// 플레이어 기본 속도 (pt/s). easy 난이도 기준점.
    static let playerBaseSpeed: CGFloat = 140
    /// 플레이어 박스 가로 (pt). GDD §7-1 김간호 16×20.
    static let playerWidth: CGFloat = 16
    /// 플레이어 박스 세로 (pt). GDD §7-1 김간호 16×20.
    static let playerHeight: CGFloat = 20

    // MARK: - D-Pad (Phase 1-3)
    /// D-Pad 단일 버튼 한 변 (pt). Apple HIG 권장 최소 터치 타깃 44pt.
    static let dpadButtonSize: CGFloat = 44
    /// D-Pad 전체 알파 (반투명). 게임 위에 떠 있는 느낌.
    /// Phase 2-7 hotfix — 0.5 → 0.7. 어두운 배경에서 사용자가 *터치 위치 인지* 가능.
    static let dpadAlpha: CGFloat = 0.7
    /// D-Pad 우측 가장자리에서의 안쪽 마진 (pt). cameraNode 자식 좌표계 기준.
    static let dpadMarginX: CGFloat = 90
    /// D-Pad 하단 가장자리에서의 안쪽 마진 (pt).
    static let dpadMarginY: CGFloat = 90

    // (placeholderBoxSize, placeholderBoxAutoSpeed는 1-2 임시값 → 1-3에서 제거)

    // MARK: - Note (Phase 2-3)
    /// 음표 한 변 길이 (pt). GDD §7-2 음표 스프라이트.
    static let noteSize: CGFloat = 16
    /// 음표 스폰 주기 (초). GDD §5 easy.
    static let noteSpawnInterval: TimeInterval = 1.5
    /// 동시에 떠 있을 수 있는 음표 최대 개수. GDD §5 easy.
    static let noteMaxConcurrent: Int = 5

    // MARK: - HUD (Phase 2-4)
    /// HUD 라벨 폰트 크기 (pt). 시스템 폰트 기준.
    static let hudFontSize: CGFloat = 18
    /// HUD 좌측 가장자리 안쪽 마진 (pt).
    static let hudMarginX: CGFloat = 24
    /// HUD 상단 가장자리 안쪽 마진 (pt).
    static let hudMarginY: CGFloat = 24
    /// HUD 알파 (반투명, 가독성 우선). D-Pad 0.3보다 큼.
    static let hudAlpha: CGFloat = 0.85

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
    /// 적 기본 속도 (pt/s). easy 난이도 시작값. GDD §5 obsBaseSpeed.
    /// Phase 2-8에서 시간 보간(→110)이 들어옴 — 본 sprint는 단일 상수.
    static let enemyBaseSpeed: CGFloat = 60
    /// 수간호사 박스 가로 (pt). GDD §7-4 16×20.
    static let enemyWidth: CGFloat = 16
    /// 수간호사 박스 세로 (pt). GDD §7-4 16×20.
    static let enemyHeight: CGFloat = 20

    // MARK: - Projectile (Phase 2-7)
    /// F 투사체 한 변 (pt). GDD §7-5 16×16.
    static let projectileSize: CGFloat = 16
    /// F 투사체 속도 (pt/s). 추적 적(60)보다 빠름 — 회피 시 빠른 이동 필요.
    static let projectileSpeed: CGFloat = 160
    /// F 발사 주기 (초). GDD §5 easy 시작값. Phase 2-8에서 보간(→2.0초).
    static let projectileFireInterval: TimeInterval = 3.5
    /// 동시에 떠 있을 수 있는 F 최대 수. GDD §5 easy.
    static let projectileMaxConcurrent: Int = 2
}
