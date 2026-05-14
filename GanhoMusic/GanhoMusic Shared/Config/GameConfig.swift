//
//  GameConfig.swift
//  GanhoMusic Shared
//
//  Phase 1-1 · Config Bootstrap
//  Phase 1-2 · World 파생값 + Placeholder 상수 추가
//  Phase 1-3 · Player / D-Pad 상수 정식 진입 + 1-2 임시값 정리
//  Phase 5-4 · HUD 우상단 캐릭터 이름 라벨 (단일 setter 주입)
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
    /// Phase 5-4 — HUD 우상단 캐릭터 이름 라벨의 x 위치 (HUDNode 좌상단 anchor 기준 오른쪽 offset, pt).
    /// landscape 1024-width 기본 캔버스 가정. 라벨 자체는 .right/.top 정렬이라 이 좌표가 라벨의 우상단 점.
    static let hudCharacterNameOffsetX: CGFloat = 760

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
    /// 적 최대 속도 (pt/s). 게임 종료 시점 도달값. GDD §5 obsMaxSpeed.
    /// Phase 2-8 — 시간 보간으로 enemyBaseSpeed(60)에서 이 값(110)까지 선형 증가.
    static let enemyMaxSpeed: CGFloat = 110
    /// 수간호사 박스 가로 (pt). GDD §7-4 16×20.
    static let enemyWidth: CGFloat = 16
    /// 수간호사 박스 세로 (pt). GDD §7-4 16×20.
    static let enemyHeight: CGFloat = 20

    // MARK: - Projectile (Phase 2-7)
    /// F 투사체 한 변 (pt). GDD §7-5 16×16.
    static let projectileSize: CGFloat = 16
    /// F 투사체 속도 (pt/s). 추적 적(60)보다 빠름 — 회피 시 빠른 이동 필요.
    static let projectileSpeed: CGFloat = 160
    /// F 발사 주기 시작값 (초). GDD §5 easy 시작값. Phase 2-9에서 IntervalEnd(2.0)까지 선형 보간.
    static let projectileFireInterval: TimeInterval = 3.5
    /// F 발사 주기 끝값 (초). 게임 종료 시점 도달값. GDD §5 easy.
    /// Phase 2-9 — 시간 보간으로 projectileFireInterval(3.5)에서 이 값(2.0)까지 선형 감소.
    static let projectileFireIntervalEnd: TimeInterval = 2.0
    /// 동시에 떠 있을 수 있는 F 최대 수. GDD §5 easy.
    static let projectileMaxConcurrent: Int = 2

    // MARK: - Scene Transition (Phase 3-1+2)
    /// 씬 전환 fade 길이 (초). TitleScene ↔ GameScene 양방향 공용.
    static let sceneTransitionDuration: TimeInterval = 0.4

    // MARK: - Title Scene (Phase 3-1+2)
    /// 타이틀 메인 라벨 폰트 크기 (pt). "김간호는 음악박사".
    static let titleFontSize: CGFloat = 36
    /// 타이틀 안내 라벨 폰트 크기 (pt). "TAP TO START".
    static let titlePromptFontSize: CGFloat = 18
    /// 타이틀 메인 라벨 y 오프셋 (pt). 화면 중심 기준 위쪽.
    /// Phase 3-4 — bestLabel(중앙)이 끼면서 40 → 60으로 위로 이동(시각 균형).
    /// Phase 3-5 — playsLabel(-20) 신설로 60 → 80, 라벨 4개 간격 40pt 균등.
    static let titleLabelOffsetY: CGFloat = 80
    /// 타이틀 안내 라벨 y 오프셋 (pt). 화면 중심 기준 아래쪽.
    /// Phase 3-4 — bestLabel(중앙) 신설로 -40 → -60.
    /// Phase 3-5 — playsLabel(-20)과 간격 확보 위해 -60 → -80.
    static let titlePromptOffsetY: CGFloat = -80
    /// 타이틀 안내 라벨 깜빡임 알파 최저값.
    static let titlePromptBlinkMinAlpha: CGFloat = 0.3
    /// 타이틀 안내 라벨 깜빡임 한 사이클(in/out 각각) 길이 (초).
    static let titlePromptBlinkDuration: TimeInterval = 0.6

    // MARK: - Result Scene (Phase 3-3)
    /// ResultScene "GAME OVER" 라벨 폰트 크기 (pt).
    static let resultTitleFontSize: CGFloat = 32
    /// ResultScene 점수 라벨 폰트 크기 (pt).
    static let resultScoreFontSize: CGFloat = 24
    /// ResultScene "TAP TO RETURN" 라벨 폰트 크기 (pt).
    static let resultPromptFontSize: CGFloat = 16
    /// ResultScene GAME OVER 라벨 y 오프셋. frame.midY 기준 위쪽.
    /// Phase 3-4 — bestLabel(-20)이 끼면서 40 → 60으로 더 위로.
    /// Phase 3-5 — statsLabel(-40) 신설로 5라벨 균등 배치 위해 60 → 80.
    static let resultTitleOffsetY: CGFloat = 80
    /// ResultScene 점수 라벨 y 오프셋. 화면 중앙 살짝 위.
    /// Phase 3-4 — bestLabel과 충돌 회피하려 0 → 20.
    /// Phase 3-5 — 5라벨 균등 배치 위해 20 → 40.
    static let resultScoreOffsetY: CGFloat = 40
    /// ResultScene 안내 라벨 y 오프셋. frame.midY 기준 아래쪽.
    /// Phase 3-4 — bestLabel(-20)과 간격 확보 위해 -50 → -60.
    /// Phase 3-5 — statsLabel(-40)과 간격 확보 위해 -60 → -80.
    static let resultPromptOffsetY: CGFloat = -80

    // MARK: - High Score (Phase 3-4)
    /// UserDefaults에 최고 점수를 저장할 키. 호출부에 리터럴 노출 금지 — 단 1회만 정의.
    static let highScoreUserDefaultsKey: String = "highScore"
    /// ResultScene BEST 라벨 폰트 크기 (pt). 점수 라벨(24)보다 작고 안내 라벨(16)보다 큼.
    static let resultBestFontSize: CGFloat = 22
    /// ResultScene BEST 라벨 y 오프셋. score(+20)와 prompt(-60) 사이 가운데.
    /// Phase 3-5 — score(+40)/statsLabel(-40) 사이 가운데로 -20 → 0.
    static let resultBestOffsetY: CGFloat = 0
    /// TitleScene BEST 라벨 폰트 크기 (pt). prompt(18)와 동급.
    static let titleBestFontSize: CGFloat = 18
    /// TitleScene BEST 라벨 y 오프셋. title(+60)과 prompt(-60)의 정중앙.
    /// Phase 3-5 — title(+80)/playsLabel(-20) 사이 균등 배치 위해 0 → 20.
    static let titleBestOffsetY: CGFloat = 20

    // MARK: - Statistics (Phase 3-5)
    /// UserDefaults에 누적 통계(GameStats)를 JSON Data로 저장할 키. 호출부에 리터럴 노출 금지.
    static let statisticsUserDefaultsKey: String = "statistics"
    /// ResultScene PLAYS/TOTAL 라벨 폰트 크기 (pt). prompt(16)와 동급으로 보조 정보 톤.
    static let resultStatsFontSize: CGFloat = 16
    /// ResultScene PLAYS/TOTAL 라벨 y 오프셋. best(0)와 prompt(-80) 사이 균등 배치(-40).
    static let resultStatsOffsetY: CGFloat = -40
    /// TitleScene PLAYS 라벨 폰트 크기 (pt). prompt(18)와 best(18) 동급보다 살짝 작게.
    static let titlePlaysFontSize: CGFloat = 16
    /// TitleScene PLAYS 라벨 y 오프셋. best(+20)와 prompt(-80) 사이 균등 배치(-20).
    static let titlePlaysOffsetY: CGFloat = -20

    // MARK: - Stone Guard (Phase 4-1)
    /// 석조무사 박스 가로 (pt). GDD §7-6 — 수간호사와 동일 16×20.
    static let stoneGuardWidth: CGFloat = 16
    /// 석조무사 박스 세로 (pt). GDD §7-6 16×20.
    static let stoneGuardHeight: CGFloat = 20
    /// 석조무사 패트롤 속도 (pt/s). GDD §7-6 — 시간 보간 없음(단일 상수).
    static let stoneGuardSpeed: CGFloat = 55
    /// 석조무사 4 waypoint(시계방향: 좌하 → 우하 → 우상 → 좌상).
    /// 맵 960×480, 중앙 기둥 (480, 240±40) 회피.
    /// 한 바퀴 둘레 = 1680pt → 1680/55 ≈ 30.5초.
    static let stoneGuardWaypoints: [CGPoint] = [
        CGPoint(x: 200, y: 100),   // 좌하 — 시작 위치
        CGPoint(x: 760, y: 100),   // 우하
        CGPoint(x: 760, y: 380),   // 우상
        CGPoint(x: 200, y: 380)    // 좌상
    ]

    // MARK: - Airforce Easter Egg (Phase 4-3)
    /// 비행기 가로 (pt). 가로로 긴 막대형.
    static let airplaneWidth: CGFloat = 32
    /// 비행기 세로 (pt). 가로형 비율.
    static let airplaneHeight: CGFloat = 16
    /// 비행기 좌→우 가로지르기 duration (초). 너무 빠르면 못 보고, 너무 느리면 게임 방해.
    static let airplaneCrossDuration: TimeInterval = 2.0
    /// 화면 상단에서 비행기 y 위치까지의 거리 (pt). cameraNode 자식 좌표계: y = +(halfH - 60).
    static let airplaneTopOffset: CGFloat = 60
    /// "나와라 박병장!" 오버레이 폰트 크기 (pt). HUD(18)보다 크고 화면 중앙 가독성 우선.
    static let airforceOverlayFontSize: CGFloat = 28
    /// "나와라 박병장!" 오버레이 표시 시간 (초). 페이드아웃 시작 전 또렷이 떠 있는 구간.
    static let airforceOverlayDisplayDuration: TimeInterval = 1.5
    /// "나와라 박병장!" 오버레이 페이드아웃 길이 (초). alpha 1 → 0 보간 시간.
    /// 총 수명 = displayDuration(1.5) + fadeOutDuration(0.3) = 1.8초.
    static let airforceOverlayFadeOutDuration: TimeInterval = 0.3
    /// 폭탄 화면 플래시 시작 지연 (초). 오버레이 닫힘(1.5+0.3=1.8) + 300ms = 2.1.
    /// trigger 시점 t=0 기준. 수동 검증: airforceOverlayDisplayDuration + airforceOverlayFadeOutDuration + 0.3.
    static let bombFlashDelay: TimeInterval = 2.1
    /// 폭탄 화면 플래시 fadeIn 길이 (초). alpha 0 → 1 빠른 보간 — *번쩍* 임팩트.
    static let bombFlashFadeInDuration: TimeInterval = 0.07
    /// 폭탄 화면 플래시 fadeOut 길이 (초). alpha 1 → 0 느린 보간 — *잔상* 효과.
    /// 총 표시 길이 = fadeIn(0.07) + fadeOut(0.35) = 0.42초.
    static let bombFlashFadeOutDuration: TimeInterval = 0.35
    /// Phase 4-6 — 수간호사 도주 모드 지속 시간 (초). GDD §7-7 명시 5초.
    /// trigger 시점에 enemy.startFleeing(duration:)에 전달. 만료 후 자동 추적 재개.
    static let enemyFleeDuration: TimeInterval = 5.0

    // MARK: - Character Card (Phase 5-1)
    /// 캐릭터 선택 카드 1장 가로 (pt). 5장 일렬 + 화면 폭에 맞춰 작게.
    static let characterCardWidth: CGFloat = 48
    /// 캐릭터 선택 카드 1장 세로 (pt). 가로보다 살짝 큼.
    static let characterCardHeight: CGFloat = 60
    /// 카드 사이 간격 (pt). 5장 일렬 — 전체 폭 = 5×48 + 4×10 = 280.
    static let characterCardSpacing: CGFloat = 10
    /// 카드 이름 라벨 폰트 크기 (pt). 카드 폭(48) 안에 한국어 3자 들어가야 함.
    static let characterCardFontSize: CGFloat = 12
    /// 카드 줄 y 오프셋 (pt). frame.midY 기준 아래쪽. promptLabel(-80)보다 더 아래.
    static let characterCardOffsetY: CGFloat = -160
    /// 선택되지 않은 카드 알파. 선택 카드(1.0)와 시각 대비.
    static let characterCardDeselectedAlpha: CGFloat = 0.5
    /// Phase 5-5 — 선택된 카드 확대 배율. 1.0 기본에서 1.08배. 인접 카드 spacing(10pt)와 검증:
    /// 48 × 1.08 = 51.84 → 측면 +1.92 → 갭 8.08pt 유지(겹침 없음).
    static let characterCardSelectedScale: CGFloat = 1.08
    /// Phase 5-5 — 선택/해제 시 scale 보간 시간 (초). 탭 응답성 고려 짧게.
    /// promptLabel 깜빡임(0.6)과 달리 1회 트랜지션 — repeatForever 아님.
    static let characterCardScaleDuration: TimeInterval = 0.10

    // MARK: - Character Preference (Phase 5-6)
    /// Phase 5-6 — UserDefaults에 마지막 캐릭터 선택을 raw String으로 저장할 키.
    /// 호출부에 리터럴 노출 금지 — CharacterPreferenceRepository만 사용.
    static let characterPreferenceUserDefaultsKey: String = "selectedCharacterID"

    // MARK: - Result Character (Phase 5-7)
    /// Phase 5-7 — ResultScene 캐릭터 이름 라벨 폰트 크기 (pt). best(22)와 동급.
    /// title(32) > character(22) = best(22) > score(24)... 위계 — title 강조 유지.
    static let resultCharacterFontSize: CGFloat = 22
    /// Phase 5-7 — ResultScene 캐릭터 라벨 y 오프셋. title(+80) 위쪽에 배치.
    /// 5라벨 균등 40 간격(+80/+40/0/-40/-80) 깨지 않게 *위로* 35pt 추가.
    /// "정간호 / GAME OVER / 🎵 N / BEST / PLAYS / TAP" 위→아래 흐름.
    static let resultCharacterOffsetY: CGFloat = 115

    // MARK: - BGM Fade (Phase 6-5)
    /// Phase 6-5 — BGM 페이드 인 길이 (초). play() 호출 시 volume 0 → 1.0 보간.
    /// 첫 음표 스폰 주기(1.5)와 자연 동기화되도록 1.5초 채택.
    static let bgmFadeInDuration: TimeInterval = 1.5
    /// Phase 6-5 — BGM 페이드 아웃 길이 (초). stop() 호출 시 현재 volume → 0 보간.
    /// ResultScene 전환 페이드(0.4)보다 길어 두 페이드가 겹치며 끝나도록 1.0초.
    static let bgmFadeOutDuration: TimeInterval = 1.0

    // MARK: - Sparkle Effect (Phase 6-8)
    /// 음표 수집 시 방사되는 sparkle 파편 개수. 8방향 균등 방사 — 정팔각형.
    /// 4면 너무 빈약, 16면 시각 노이즈. 8이 균형점. GDD: 음악=별 미학.
    static let sparkleParticleCount: Int = 8
    /// sparkle 파편 1개의 반지름 (pt). 음표 한 변(16)의 1/8 = 2.0pt. 작은 별빛 입자 톤.
    static let sparkleParticleRadius: CGFloat = 2.0
    /// sparkle 방사 거리 (pt). 노트 중심에서 파편이 도달하는 최대 거리.
    /// 음표 한 변(16)의 ~1.5배 = 24pt. 너무 멀면 인접 음표와 겹침, 가까우면 임팩트 약함.
    static let sparkleSpawnDistance: CGFloat = 24
    /// sparkle 페이드/이동 액션 총 길이 (초). group 액션 묶음의 duration.
    /// 너무 길면 다음 음표 수집과 겹쳐 시각 노이즈. 0.5초가 *반짝*의 적정선.
    static let sparkleFadeDuration: TimeInterval = 0.5
    /// sparkle 파편 zPosition. HUD(100) 아래, Player/Note(0~5) 위 — 노트가 사라진 자리에서 위로 떠오르는 느낌.
    static let sparkleZPosition: CGFloat = 30
    /// sparkle 파편의 끝 스케일. 0.0이면 한 점으로 수렴(별빛 꺼짐), 1.0이면 동일 크기 유지.
    /// 0.2면 페이드아웃 + 살짝 축소 — 별이 멀어지는 느낌.
    static let sparkleEndScale: CGFloat = 0.2

    // MARK: - Hit Feedback (Phase 6-9)
    /// 카메라 셰이크 진폭 (pt). 좌우 한 방향 이동량. 6~10pt 범위에서 8 채택.
    /// 너무 크면 어지러움, 너무 작으면 안 보임. 학생 머리 *띵* 흔들림.
    static let cameraShakeAmplitude: CGFloat = 8
    /// 카메라 좌우 흔들림 반복 횟수. 6회 → 좌·우·좌·우·좌·우 (마지막 원위치 별도).
    /// 총 모션 = stepDuration × (count + 1).
    static let cameraShakeStepCount: Int = 6
    /// 카메라 셰이크 한 스텝 길이 (초). 6 × 0.04 + 0.04 = 0.28초 ≈ haptics.heavy 체감 길이.
    static let cameraShakeStepDuration: TimeInterval = 0.04
    /// 피격 플래시 alpha 피크 (0~1). 0.55 = 반투명 빨강 — 시야 차단 방지, *맞았다* 명확.
    static let hitFlashPeakAlpha: CGFloat = 0.55
    /// 피격 플래시 fadeIn 길이 (초). 빠르게 등장 — *번쩍* 임팩트.
    static let hitFlashFadeInDuration: TimeInterval = 0.05
    /// 피격 플래시 fadeOut 길이 (초). 천천히 사라짐 — *잔상* 효과.
    /// 총 노출 = fadeIn(0.05) + fadeOut(0.25) = 0.30초 ≈ 셰이크(0.28) 동기.
    static let hitFlashFadeOutDuration: TimeInterval = 0.25
    /// 피격 플래시 zPosition. HUD(100) 위, BombFlash(250) 아래.
    /// 점수 라벨을 잠깐 덮어 임팩트 강조 — 0.3초만 가려지므로 게임플레이 무방해.
    static let hitFlashZPosition: CGFloat = 200

    // MARK: - Combo Popup (Phase 6-10)
    /// 콤보 마일스톤 발화 임계값 목록. 한 판 내 같은 마일스톤은 1회만 발화(멱등).
    /// 3 = 첫 환호 / 5 = 정착 / 10 = 황금기 / 20 = 클라이맥스. 자전적 곡 클라이맥스 모델.
    static let comboMilestones: [Int] = [3, 5, 10, 20]
    /// 콤보 팝업 텍스트 폰트 크기 (pt). HUD(18)의 ~2.7배 — *임팩트 강조*.
    static let comboPopupFontSize: CGFloat = 48
    /// 콤보 팝업이 위로 떠오르는 거리 (pt). 별이 하늘로 올라가는 톤.
    static let comboPopupFlyUpDistance: CGFloat = 80
    /// 팝업 1회 표시 총 길이 (초). group 액션(move + fade + scale) 묶음 duration.
    /// sparkle(0.5)보다 길고 airforceOverlay(1.5)보다 짧음 — 마일스톤 강조와 게임플레이 방해의 균형점.
    static let comboPopupDuration: TimeInterval = 1.0
    /// 팝업 끝 스케일. 1.0 시작 → 1.4 끝 = 페이드아웃과 동시에 *별이 터지듯* 확대.
    /// SparkleEndScale(0.2 축소)과 반대 — 마일스톤은 *확산*되는 느낌, sparkle은 *수렴*되는 입자.
    static let comboPopupEndScale: CGFloat = 1.4
    /// 팝업 zPosition. HUD(100) 위 — 라벨을 잠깐 덮어 임팩트.
    /// HitFlash(200) 아래 — 피격 플래시는 더 우선(생존 직결).
    static let comboPopupZPosition: CGFloat = 150

    // MARK: - Combo Break (Phase 6-12)
    /// 콤보 끊김 시 BREAK 시각 발화 임계값. 이 값 이상의 콤보에서 0으로 떨어졌을 때만 발화.
    /// 1→0, 2→0은 평범한 흐름이라 무시. 10 = 콤보 마일스톤 "황금기" 톤과 일치 — 손실감이 *체감*되는 지점.
    static let comboBreakThreshold: Int = 10
    /// BREAK 라벨 폰트 크기 (pt). comboPopupFontSize(48)와 동일 — 환호/실망 시각 강도 대칭.
    static let comboBreakFontSize: CGFloat = 48
    /// BREAK가 아래로 떨어지는 거리 (pt). comboPopupFlyUpDistance(80)보다 짧음 — *떨어짐*은 짧고 단호.
    static let comboBreakFallDistance: CGFloat = 60
    /// BREAK 1회 표시 총 길이 (초). comboPopupDuration(1.0)과 동일 — 환호/실망 시간축 대칭.
    static let comboBreakDuration: TimeInterval = 1.0
    /// BREAK 끝 스케일. 1.0 시작 → 0.7 끝. comboPopupEndScale(1.4 확대)와 반대 — 실망은 *축소*(수축의 톤).
    static let comboBreakEndScale: CGFloat = 0.7
    /// BREAK zPosition. comboPopupZPosition(150) 아래 — 환호 위에 끊김이 덮이지 않도록.
    /// HUD(100) 위는 유지 — 임팩트 강조. HitFlash(200) 아래.
    static let comboBreakZPosition: CGFloat = 140

    // MARK: - Countdown (Phase 6-13)
    /// 카운트다운 숫자/GO! 폰트 크기 (pt). comboPopup(48)의 2배 — 화면 중앙 단독 강조.
    static let countdownFontSize: CGFloat = 96
    /// 한 단계(3/2/1/GO!) fadeIn 길이 (초). 빠르게 등장.
    static let countdownFadeInDuration: TimeInterval = 0.1
    /// 한 단계 *holding* 길이 (초). 또렷이 보이는 구간.
    static let countdownHoldDuration: TimeInterval = 0.7
    /// 한 단계 fadeOut 길이 (초). 다음 단계 등장 전 사라짐.
    static let countdownFadeOutDuration: TimeInterval = 0.2
    /// GO! 단계의 scale 펄스 끝값. 1.0 → 1.3 확대 → 페이드아웃과 동시 종료.
    static let countdownGoEndScale: CGFloat = 1.3
    /// GO! 단계 fadeOut 길이 (초). 일반 단계보다 살짝 길게 — 시작의 잔향.
    static let countdownGoFadeOutDuration: TimeInterval = 0.4
    /// GO! holding 길이 (초). 일반(0.7)보다 짧게 — 스케일 펄스 + 빠른 페이드아웃이 시간 채움.
    static let countdownGoHoldDuration: TimeInterval = 0.5
    /// CountdownNode zPosition. HitFlash(200) 위, BombFlash(250)와 동급/이하.
    /// 카운트다운 동안 어떤 UI도 덮는다 — 게임이 아직 시작 안 했으므로.
    static let countdownZPosition: CGFloat = 250

    // MARK: - Tension (Phase 6-14)
    /// 5초 긴박감 발화 시작 임계값 (초). remainingTime이 이 값 이하로 떨어지면 폴링 진입.
    /// 6-13 카운트다운(출발의 개봉감)과 시간 대칭 — 시작·끝의 톤이 짝을 이룬다.
    static let tensionWindow: TimeInterval = 5.0
    /// BGM rate 시작값 (1.0 = 원본). AVAudioPlayer.rate 타입에 맞춰 Float.
    static let tensionRateBase: Float = 1.0
    /// BGM rate 최대값 (1.15 = 영상 빨리감기 톤, 피치 포함). 0.5~2.0 권장 범위 중 안전.
    /// 1.15는 *체감되지만 곡 식별성 유지* 균형점 — Float 타입(AVAudioPlayer.rate 일치).
    static let tensionRateMax: Float = 1.15
    /// 깜빡임 한 색 머무는 길이 (초). 총 1초 주기 = 빨강 0.5 + 원색 0.5.
    /// 매초 정수 변화(5→4→3→2→1)와 *심박* 톤이 자연 동기.
    static let tensionBlinkHalfPeriod: TimeInterval = 0.5
    /// HUDNode timeLabel 깜빡임 SKAction 키. 중복 호출 시 자동 교체(멱등) 보장.
    /// withKey로 부착하면 SpriteKit이 같은 키의 이전 액션을 자동 제거 → 자연 멱등.
    static let tensionBlinkActionKey: String = "tensionBlink"
}
