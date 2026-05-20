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
    /// Phase 7-5 — 80 → 120. 난이도 카드(+80)를 titleLabel 아래/bestLabel 위에 두기 위해 titleLabel을 위로 이동.
    static let titleLabelOffsetY: CGFloat = 120
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
    /// Phase 9-8 — 사용자 요청 시퀀스 "오버레이 2.4초 유지" 정합화: 1.5 → 2.1.
    /// 총 수명 = displayDuration(2.1) + fadeOutDuration(0.3) = 2.4초.
    static let airforceOverlayDisplayDuration: TimeInterval = 2.1
    /// "나와라 박병장!" 오버레이 페이드아웃 길이 (초). alpha 1 → 0 보간 시간.
    /// 총 수명 = displayDuration(2.1) + fadeOutDuration(0.3) = 2.4초.
    static let airforceOverlayFadeOutDuration: TimeInterval = 0.3
    /// Phase 9-8 — 비행기 등장 지연(trigger 시점 t=0 기준).
    /// 오버레이 완전 소멸 = displayDuration(2.1) + fadeOutDuration(0.3) = 2.4초.
    /// 이 시점에 비행기가 화면 좌측에서 등장 → 우측까지 airplaneCrossDuration(2.0)초 가로지름.
    static let airplaneDelayAfterOverlay: TimeInterval = 2.4
    /// 폭탄 화면 플래시 시작 지연 (초). trigger 시점 t=0 기준.
    /// Phase 9-8 — 사용자 요청 시퀀스 정합화: 2.1 → 3.4.
    /// 비행기 중앙 도달 시점 = airplaneDelayAfterOverlay(2.4) + airplaneCrossDuration(2.0)/2 = 3.4초.
    static let bombFlashDelay: TimeInterval = 3.4
    /// 폭탄 화면 플래시 fadeIn 길이 (초). alpha 0 → 1 빠른 보간 — *번쩍* 임팩트.
    static let bombFlashFadeInDuration: TimeInterval = 0.07
    /// 폭탄 화면 플래시 fadeOut 길이 (초). alpha 1 → 0 느린 보간 — *잔상* 효과.
    /// 총 표시 길이 = fadeIn(0.07) + fadeOut(0.35) = 0.42초.
    static let bombFlashFadeOutDuration: TimeInterval = 0.35
    /// Phase 4-6 — 수간호사 도주 모드 지속 시간 (초). GDD §7-7 명시 5초.
    /// trigger 시점에 enemy.startFleeing(duration:)에 전달. 만료 후 자동 추적 재개.
    static let enemyFleeDuration: TimeInterval = 5.0

    // MARK: - Character Card (Phase 5-1)
    /// 캐릭터 선택 카드 1장 가로 (pt). Sprint 7+ — 48 → 76 (1.58×).
    /// 카드를 키워 5장 간 분리감 강화. 글래스 컨테이너/얼굴 스케일과 동기 확대.
    static let characterCardWidth: CGFloat = 76
    /// 캐릭터 선택 카드 1장 세로 (pt). Sprint 7+ — 60 → 104 (1.73×).
    /// 세로 비율을 더 키워 친구 카드 느낌. 가로 76 × 세로 104 = 1:1.37.
    static let characterCardHeight: CGFloat = 104
    /// 카드 사이 간격 (pt). 5장 일렬 — 전체 폭 = 5×48 + 4×10 = 280.
    static let characterCardSpacing: CGFloat = 10
    /// 카드 이름 라벨 폰트 크기 (pt). 카드 폭(48) 안에 한국어 3자 들어가야 함.
    static let characterCardFontSize: CGFloat = 12
    // Phase 7-1 — characterCardOffsetY는 §"Difficulty"(파일 하단)로 이동 — 값 -160 → -200으로 난이도 행 신설에 맞춰 한 칸 더 내림.
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

    // MARK: - Countdown V3 (Sprint 7 Phase E)
    /// V3 카운트다운 숫자(3·2·1) 폰트 크기 (pt). V2 96 → 120 — 화면 중앙 단독 강조 + v3 위계 강화.
    static let countdownNumberFontSizeV3: CGFloat = 120
    /// V3 GO! 폰트 크기 (pt). 숫자(120)보다 큼 — "출발의 폭발" 톤, 마지막 단계 임팩트.
    static let countdownGoFontSizeV3: CGFloat = 140
    /// V3 GO! scale 시작값. V2 1.0 → 1.2 — 등장부터 임팩트.
    static let countdownGoStartScaleV3: CGFloat = 1.2
    /// V3 GO! scale 끝값. V2 1.3 → 1.8 — 더 큰 펄스 (시작의 잔향).
    static let countdownGoEndScaleV3: CGFloat = 1.8
    /// V3 dim 오버레이 알파 (navyDeep × 0.32). 게임 월드는 보이되 "아직 시작 전" 시각화.
    static let countdownDimAlpha: CGFloat = 0.32
    /// V3 dim 페이드인 길이 (초). 카운트다운 등장과 동기 — 0.2s 자연 어두워짐.
    static let countdownDimFadeInDuration: TimeInterval = 0.2
    /// V3 dim 페이드아웃 길이 (초). GO! 종료 직후 0.2s 자연 밝아짐 → startGameProperly 진입.
    static let countdownDimFadeOutDuration: TimeInterval = 0.2
    /// V3 dim zPosition. 240 — CountdownNode(250) 아래, HUD/Combo/HitFlash 위.
    /// 카운트다운 숫자가 dim 위에 또렷이 보이도록 zPosition 분리.
    static let countdownDimZPosition: CGFloat = 240
    /// V3 dim 노드 name — 디버그/회귀 검증/명시적 lookup용.
    static let countdownDimNodeName: String = "countdownDim"

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

    // MARK: - New Best (Phase 6-15)
    /// 화면 중앙 "NEW BEST!" 폰트 크기 (pt). resultScoreFontSize(24)보다 큼, countdownFontSize(96)보단 작음.
    static let newBestFontSize: CGFloat = 56
    /// frame.midY 기준 NewBest! 라벨 Y 오프셋. 0 = 정중앙. bestLabel과 같은 y지만 zPosition으로 위에 겹침.
    static let newBestOffsetY: CGFloat = 0
    /// NewBest! 라벨 zPosition. comboPopupZPosition(150)과 동급 — ResultScene 기본 z=0 위.
    static let newBestZPosition: CGFloat = 150
    /// ResultScene 진입 후 NewBest! 발화까지 지연 (초). fade transition(0.4s) 끝나고 score 인지 후 등장.
    static let newBestRevealDelay: TimeInterval = 0.3
    /// NewBest! fade-in 길이 (초).
    static let newBestFadeInDuration: TimeInterval = 0.3
    /// NewBest! scale pulse 한 사이클 총 길이 (초). up(0.4) + down(0.4) = 0.8.
    static let newBestScalePulseDuration: TimeInterval = 0.8
    /// NewBest! scale pulse 정점 스케일 (1.0 → 1.2 → 1.0).
    static let newBestEndScalePeak: CGFloat = 1.2
    /// bestLabel 황금 깜빡임 최소 alpha. 1.0 ↔ 0.5 사이 보간.
    static let newBestBlinkMinAlpha: CGFloat = 0.5
    /// bestLabel 황금 깜빡임 한 색 머무는 시간 (초). tensionBlinkHalfPeriod(0.5)와 동일.
    static let newBestBlinkHalfPeriod: TimeInterval = 0.5
    /// bestLabel 황금 깜빡임 SKAction 키. 같은 키 재호출 시 자동 교체로 자연 멱등.
    static let newBestBlinkActionKey: String = "newBestBlink"

    // MARK: - Score Popup (Phase 6-16)
    /// 노트 수집 자리에 뜨는 "+1"/"+2" 라벨 폰트 크기 (pt).
    /// HUD(18)보다 크고 ComboPopup(48)보다 작음 — *지역* 강조 톤.
    static let scorePopupFontSize: CGFloat = 28
    /// 노트 수집 좌표에서 시작 y 오프셋 (pt). 노트 본체(16pt) 위쪽 살짝 —
    /// 노트가 사라지는 픽셀과 텍스트 첫 프레임이 겹치지 않게 12pt 위에서 시작.
    static let scorePopupStartOffsetY: CGFloat = 12
    /// "+1"/"+2"가 위로 떠오르는 총 거리 (pt). ComboPopup(80)의 절반 — *지역* 시그널은 작게.
    /// sparkleSpawnDistance(24)보다 길어 sparkle 입자와 텍스트가 시각 분리.
    static let scorePopupFlyUpDistance: CGFloat = 40
    /// 1회 표시 총 길이 (초). sparkle(0.5)보다 살짝 길어 사라지는 시점 비동기 —
    /// 시각 노이즈 분리. comboPopup(1.0)보다 짧음 — *지역* 톤.
    static let scorePopupDuration: TimeInterval = 0.6
    /// 시작 scale. 1.0보다 작게 시작해 *부풀어 오르는* 톤. ComboPopup(1.0 시작)과 차별화.
    static let scorePopupStartScale: CGFloat = 0.8
    /// 끝 scale. ComboPopup(1.4 확대)보다 약함 — *지역* 시그널 절제 톤.
    static let scorePopupEndScale: CGFloat = 1.0
    /// "+1"/"+2" 라벨 zPosition. sparkle(30) 위, HUD(100) 아래 —
    /// 노트 사라진 픽셀 위에 떠 있되 HUD 점수/타이머는 안 가림.
    static let scorePopupZPosition: CGFloat = 50

    // MARK: - Difficulty (Phase 7-1)
    /// 난이도별 플레이어 시작 속도 (pt/s). GDD §5 표. easy(140)는 기존 playerBaseSpeed와 동일 —
    /// apply 누락 시 graceful fallback. PlayerNode가 자기 baseSpeedStart에 set.
    static let playerSpeedStartByDifficulty: [Difficulty: CGFloat] = [
        .easy: 140, .normal: 160, .hard: 160
    ]
    /// 난이도별 플레이어 끝 속도 (pt/s). 본 sprint는 *보간 미적용* — 미리 추가만(주의사항 7).
    /// 다음 보강 sprint에서 PlayerNode.update가 진행률 ↑ 시 baseSpeedEnd까지 보간.
    static let playerSpeedEndByDifficulty: [Difficulty: CGFloat] = [
        .easy: 210, .normal: 250, .hard: 250
    ]
    /// 난이도별 적 시작 속도 (pt/s). easy(60)는 기존 enemyBaseSpeed와 동일 — 회귀 0 보장.
    static let enemySpeedStartByDifficulty: [Difficulty: CGFloat] = [
        .easy: 60, .normal: 170, .hard: 200
    ]
    /// 난이도별 적 끝 속도 (pt/s). easy(110)는 기존 enemyMaxSpeed와 동일 — 회귀 0 보장.
    static let enemySpeedEndByDifficulty: [Difficulty: CGFloat] = [
        .easy: 110, .normal: 290, .hard: 340
    ]
    /// 난이도별 동시 음표 최대 수. easy(5)는 기존 noteMaxConcurrent와 동일 — 회귀 0 보장.
    static let noteMaxConcurrentByDifficulty: [Difficulty: Int] = [
        .easy: 5, .normal: 4, .hard: 4
    ]
    /// 난이도별 음표 TTL (초). easy = `.infinity` → applyLifetime 가드로 자가 소멸 미부착 → 기존 동작 정확 보존.
    /// normal/hard만 자가 소멸 SKAction 부착(주의사항 2).
    static let noteLifetimeByDifficulty: [Difficulty: TimeInterval] = [
        .easy: .infinity, .normal: 3.5, .hard: 2.8
    ]
    /// 난이도별 F 동시 최대 수. easy(2)는 기존 projectileMaxConcurrent와 동일.
    static let projectileMaxConcurrentByDifficulty: [Difficulty: Int] = [
        .easy: 2, .normal: 10, .hard: 14
    ]
    /// 난이도별 F 동시 burst 발사 수. easy=1 → 기존 1발 루프와 동일 → 회귀 0 (주의사항 4).
    static let projectileBurstCountByDifficulty: [Difficulty: Int] = [
        .easy: 1, .normal: 3, .hard: 4
    ]
    /// 난이도별 F 발사 주기 시작값 (초). easy(3.5)는 기존 projectileFireInterval와 동일.
    static let projectileFireIntervalStartByDifficulty: [Difficulty: TimeInterval] = [
        .easy: 3.5, .normal: 1.0, .hard: 0.8
    ]
    /// 난이도별 F 발사 주기 끝값 (초). easy(2.0)는 기존 projectileFireIntervalEnd와 동일.
    static let projectileFireIntervalEndByDifficulty: [Difficulty: TimeInterval] = [
        .easy: 2.0, .normal: 0.35, .hard: 0.25
    ]

    /// 난이도 카드 1장 가로 (pt). 3장 일렬 — 더 큼직(80 vs 캐릭터카드 48) — 화면 상위 인터랙션.
    static let difficultyCardWidth: CGFloat = 80
    /// 난이도 카드 1장 세로 (pt). 이름 + 부제 두 라벨이 들어가야 해서 캐릭터카드(60)보다 약간 작은 56.
    static let difficultyCardHeight: CGFloat = 56
    /// 난이도 카드 사이 간격 (pt). 3장 일렬 — 전체 폭 = 3×80 + 2×16 = 272pt.
    static let difficultyCardSpacing: CGFloat = 16
    /// 난이도 카드 줄 y 오프셋 (pt). frame.midY 기준.
    /// Phase 7-1 — -120(promptLabel 하단). Phase 7-5 — +80으로 *상단 이동* — titleLabel(+120) 아래 / bestLabel(+20) 위.
    /// 작은 화면(640pt)에서 5장 캐릭터 카드 + 3장 난이도 카드를 *위/아래*로 분리해 절단 회피.
    static let difficultyCardOffsetY: CGFloat = 80
    /// 난이도 카드 이름 라벨 폰트 크기 (pt). "하/중/상" 한 글자 강조 — 캐릭터카드(12)보다 크게.
    static let difficultyCardFontSize: CGFloat = 20
    /// 난이도 카드 부제 라벨 폰트 크기 (pt). 한국어 5~7자가 80pt 폭 안에 들어가야 함.
    static let difficultyCardSubtitleFontSize: CGFloat = 10
    /// 캐릭터 카드 줄 y 오프셋 (pt) — Phase 7-1 — 난이도 행(-120) 신설로 -160 → -200으로 한 칸 더 내림.
    /// Phase 7-5 — 난이도 카드가 상단(+80)으로 이동 → -200 → -160 *되돌림*. 작은 화면(640pt) 절단 회피.
    static let characterCardOffsetY: CGFloat = -160
    /// UserDefaults에 마지막 난이도 선택을 raw String으로 저장할 키.
    /// 호출부에 리터럴 노출 금지 — DifficultyPreferenceRepository만 사용.
    static let difficultyPreferenceUserDefaultsKey: String = "selectedDifficulty"
    /// ResultScene 난이도 라벨 y 오프셋 (pt). characterLabel(115) 더 위쪽 — "난이도: 상" / "🎮 김간호" / "GAME OVER" 톤.
    static let resultDifficultyOffsetY: CGFloat = 155
    /// ResultScene 난이도 라벨 폰트 크기 (pt). resultStats(16)와 동급 — 보조 정보 톤.
    static let resultDifficultyFontSize: CGFloat = 18

    // MARK: - Hard Map (Phase 7-2)
    // 좌상 방
    static let hardMapTopLeftRoomHWallCStart:  Int = 4
    static let hardMapTopLeftRoomHWallCEnd:    Int = 9
    static let hardMapTopLeftRoomHWallR:       Int = 18
    static let hardMapTopLeftRoomVWallC:       Int = 9
    static let hardMapTopLeftRoomVWallRStart:  Int = 18
    static let hardMapTopLeftRoomVWallREnd:    Int = 21
    static let hardMapTopLeftRoomDoorR:        Int = 20

    // 우상 방
    static let hardMapTopRightRoomHWallCStart: Int = 38
    static let hardMapTopRightRoomHWallCEnd:   Int = 43
    static let hardMapTopRightRoomHWallR:      Int = 18
    static let hardMapTopRightRoomVWallC:      Int = 38
    static let hardMapTopRightRoomVWallRStart: Int = 18
    static let hardMapTopRightRoomVWallREnd:   Int = 21
    static let hardMapTopRightRoomDoorR:       Int = 20

    // 좌하 방
    static let hardMapBottomLeftRoomHWallCStart: Int = 4
    static let hardMapBottomLeftRoomHWallCEnd:   Int = 9
    static let hardMapBottomLeftRoomHWallR:      Int = 5
    static let hardMapBottomLeftRoomVWallC:      Int = 9
    static let hardMapBottomLeftRoomVWallRStart: Int = 2
    static let hardMapBottomLeftRoomVWallREnd:   Int = 5
    static let hardMapBottomLeftRoomDoorR:       Int = 3

    // 우하 방
    static let hardMapBottomRightRoomHWallCStart: Int = 38
    static let hardMapBottomRightRoomHWallCEnd:   Int = 43
    static let hardMapBottomRightRoomHWallR:      Int = 5
    static let hardMapBottomRightRoomVWallC:      Int = 38
    static let hardMapBottomRightRoomVWallRStart: Int = 2
    static let hardMapBottomRightRoomVWallREnd:   Int = 5
    static let hardMapBottomRightRoomDoorR:       Int = 3

    // 중앙 기둥
    static let hardMapCenterLeftPillarC:        Int = 17
    static let hardMapCenterLeftPillarRStart:   Int = 11
    static let hardMapCenterLeftPillarREnd:     Int = 12
    static let hardMapCenterRightPillarC:       Int = 30
    static let hardMapCenterRightPillarRStart:  Int = 11
    static let hardMapCenterRightPillarREnd:    Int = 12
    static let hardMapCenterTopPillarCStart:    Int = 23
    static let hardMapCenterTopPillarCEnd:      Int = 24
    static let hardMapCenterTopPillarR:         Int = 15
    static let hardMapCenterBottomPillarCStart: Int = 23
    static let hardMapCenterBottomPillarCEnd:   Int = 24
    static let hardMapCenterBottomPillarR:      Int = 8

    // MARK: - Cutscene (Phase 7-3)
    /// 컷씬 배경 SKSpriteNode 알파(반투명 검정). 0.85 = 게임 월드를 *흐릿하게* 보여주며 텍스트 가독성 확보.
    /// 1.0(완전 차단)이면 *전환*의 시각 연속성이 끊기고, 0.5 이하면 본문 라벨 가독성 ↓.
    static let cutsceneBackgroundAlpha: CGFloat = 0.85
    /// 컷씬 제목 라벨 폰트 크기 (pt). resultScoreFontSize(24)보다 살짝 큼 — *장*의 톤.
    /// countdownFontSize(96)·comboPopupFontSize(48)보단 작음 — 본문이 주인공인 컷씬에서 제목은 헤더 정도.
    static let cutsceneTitleFontSize: CGFloat = 26
    /// 컷씬 본문 라벨 폰트 크기 (pt). 한국어 가독성 + 화면 가로 70% 폭에 2~3줄 줄바꿈 균형.
    /// HUD(18)와 제목(26) 중간 — 본문은 *말하는 목소리*의 톤.
    static let cutsceneBodyFontSize: CGFloat = 20
    /// 컷씬 TAP 라벨 폰트 크기 (pt). titlePromptFontSize(18)보다 살짝 작아 *부속 안내*임을 시각 위계로 전달.
    static let cutsceneTapFontSize: CGFloat = 16
    /// 컷씬 제목 라벨 y 오프셋 (pt). cameraNode 자식 좌표계 (0,0) = 화면 중앙 기준 위쪽.
    /// 본문(0)·TAP(-120)과 시각 위계 + 본문 줄바꿈 공간 확보.
    static let cutsceneTitleOffsetY: CGFloat = 100
    /// 컷씬 TAP 라벨 y 오프셋 (pt). 화면 중앙 기준 아래쪽 — 본문(0)과 안전 간격 확보.
    static let cutsceneTapOffsetY: CGFloat = -120
    /// 컷씬 본문 자동 줄바꿈 최대 폭 비율 (scene.width × ratio). 0.7 = 양 가장자리 15% 여백 확보.
    /// 너무 좁으면 줄 수 ↑(스크롤 느낌), 너무 넓으면 가독성 ↓(끝까지 시선 이동 부담).
    static let cutsceneBodyWidthRatio: CGFloat = 0.7
    /// 컷씬 노드 zPosition. countdownZPosition(250)·bombFlashZPosition 위 — 컷씬 동안 어떤 UI도 덮는다.
    /// 게임이 아직 시작 안 했으므로 그 어떤 게임 노드보다 우선.
    static let cutsceneZPosition: CGFloat = 300
    /// 컷씬 fadeIn 길이 (초). present 직후 alpha 0 → 1 보간.
    /// 너무 짧으면 *팝업* 느낌, 너무 길면 답답함. countdownFadeInDuration(0.1)보다 길어 *문이 열리는* 톤.
    static let cutsceneFadeInDuration: TimeInterval = 0.25
    /// 컷씬 fadeOut 길이 (초). dismiss 시 alpha 1 → 0 보간 + 트리 제거.
    /// fadeIn(0.25)보다 살짝 길어 *떠나가는 잔향* 톤. sceneTransitionDuration(0.4)과 동급.
    static let cutsceneFadeOutDuration: TimeInterval = 0.3
    /// 컷씬 TAP 라벨 alpha. 0.7 = 본문·제목(1.0)과 시각 위계 + *깜빡임 없이도* 부속 안내임이 전달.
    /// dpadAlpha(0.7)와 동급 — *조작 안내 톤*과 일관.
    static let cutsceneTapLabelAlpha: CGFloat = 0.7
    /// Phase 7-5 — 인트로 컷씬 1회 노출 가드 UserDefaults 키.
    /// bool 기본값 false(Apple 보장) → 최초 사용자에게는 자동 컷씬 표시. dismiss 콜백에서 true set 후 이후 영구 스킵.
    /// 신규 키 — 기존 키와 충돌 0.
    static let hasSeenIntroCutsceneUserDefaultsKey: String = "hasSeenIntroCutscene"

    // MARK: - Diploma (Phase 7-4)
    /// 난이도별 졸업 목표 점수. 캐릭터 × 난이도 매트릭스에서 이 점수 이상 달성하면 그 난이도 "통과".
    /// easy 60 > normal 50 > hard 30 — 어려운 난이도일수록 목표는 낮지만 *달성 자체가 어려운* 균형.
    /// `[Difficulty: Int]` dict — Difficulty enum이 단일 진실 원천. 추가 난이도 시 dict 한 줄만 늘리면 됨.
    static let targetScoreByDifficulty: [Difficulty: Int] = [
        .easy: 60, .normal: 50, .hard: 30
    ]
    /// PerDifficultyScoreRepository가 사용하는 UserDefaults 키.
    /// `highScoreUserDefaultsKey`(단일 최고점)와 분리 — 두 저장소 병행 운영.
    static let perDifficultyScoreUserDefaultsKey: String = "perDifficultyScores"
    /// GraduationRepository가 사용하는 UserDefaults 키. 캐릭터별 최초 졸업 일시 저장.
    /// 신규 키 — 기존 키와 충돌 0.
    static let graduationUserDefaultsKey: String = "graduations"
    /// 졸업장 배경(.ganhoYellowF) 반투명 alpha. 0.92 = 거의 불투명이지만 살짝 비침으로 *증서 종이* 톤.
    /// cutsceneBackgroundAlpha(어두운 톤)와 의도적으로 다른 값 — 증서의 *밝고 견고한* 인상.
    static let diplomaBackgroundAlpha: CGFloat = 0.92
    /// 졸업장 zPosition. cutsceneZPosition(300)과 동급 — newBestZPosition(150) 위로 자연 겹침.
    /// 그 어떤 게임 UI도 덮음(이미 게임 종료 후 ResultScene 위라 충돌 없음).
    static let diplomaZPosition: CGFloat = 300
    /// 졸업장 fadeIn 길이 (초). 0.4 = sceneTransitionDuration과 동급 — *문이 열리는* 톤.
    /// cutsceneFadeInDuration(0.25)보다 살짝 길어 *증서가 천천히 펼쳐지는* 인상.
    static let diplomaFadeInDuration: TimeInterval = 0.4
    /// 졸업장 fadeOut 길이 (초). 0.35 = fadeIn(0.4)과 거의 같지만 살짝 빨라 *잔향 짧게*.
    static let diplomaFadeOutDuration: TimeInterval = 0.35
    /// 영문 제목 "CERTIFICATE OF GRADUATION" 폰트 크기. 한글(30)보다 살짝 작아 *부제* 느낌.
    static let diplomaTitleEnFontSize: CGFloat = 26
    /// 한글 제목 "실습 수료 증서" 폰트 크기. 30 — *주인공*. 본문(18)보다 명확히 큼.
    static let diplomaTitleKoFontSize: CGFloat = 30
    /// 본문 라벨(2줄) 폰트 크기. 18 — HUD(18)와 동급. 자동 줄바꿈으로 폭에 맞춤.
    static let diplomaBodyFontSize: CGFloat = 18
    /// 발급자 라벨("hgfolio · 김간호는 음악박사") 폰트 크기. 작은 부속 정보.
    static let diplomaIssuerFontSize: CGFloat = 14
    /// 일시 라벨("yyyy-MM-dd") 폰트 크기. issuer(14)와 동급 — 한 줄에 좌우 배치.
    static let diplomaDateFontSize: CGFloat = 14
    /// "TAP TO CONTINUE" 안내 라벨 폰트 크기. 14 — diplomaTapFontSize 별도(작은 안내문 톤).
    /// cutsceneTapFontSize(16)와 다른 값 — 졸업장 톤에 맞춰 더 차분.
    static let diplomaTapFontSize: CGFloat = 14
    /// 영문 제목 y 오프셋. +150 — 화면 중앙 기준 위쪽. 한글(110)과 40 간격.
    static let diplomaTitleEnOffsetY: CGFloat = 150
    /// 한글 제목 y 오프셋. +110. 영문(150)과 본문(30) 사이.
    static let diplomaTitleKoOffsetY: CGFloat = 110
    /// 본문 1 y 오프셋. +30 — 화면 중앙 약간 위.
    static let diplomaBody1OffsetY: CGFloat = 30
    /// 본문 2 y 오프셋. -10 — 화면 중앙 약간 아래. 본문1(30)과 40 간격으로 2줄 자연 배치.
    static let diplomaBody2OffsetY: CGFloat = -10
    /// 발급자 라벨 y 오프셋. -110 — 본문 아래 충분한 간격. 우측 정렬.
    static let diplomaIssuerOffsetY: CGFloat = -110
    /// 일시 라벨 y 오프셋. -110 — 발급자와 같은 y, 좌측 정렬. 한 줄에 좌우 배치.
    static let diplomaDateOffsetY: CGFloat = -110
    /// TAP 라벨 alpha. 0.7 = cutsceneTapLabelAlpha와 동급 — *조작 안내 톤* 일관.
    static let diplomaTapLabelAlpha: CGFloat = 0.7
    /// TAP 라벨 y 오프셋. -160 — 발급자/일시(-110) 아래 충분한 간격.
    static let diplomaTapOffsetY: CGFloat = -160
    /// 본문 자동 줄바꿈 최대 폭 비율 (scene.width × ratio). 0.7 = cutsceneBodyWidthRatio와 동급.
    /// 양 가장자리 15% 여백 — 한국어 본문이 폭 안에 자연 줄바꿈.
    static let diplomaBodyWidthRatio: CGFloat = 0.7

    // MARK: - Pixel Sprite (Phase 8-1)
    /// 16×20 픽셀 스프라이트의 점(pt) 단위 확대 배율. 화면에서 32×40pt로 보이도록 2배 확대.
    /// physicsBody 크기(playerWidth/playerHeight)는 *그대로* — 게임 hitbox 회귀 0.
    /// 시각만 커지므로 카메라 follow / 충돌 / 맵 경계 영향 0.
    static let pixelSpriteScale: CGFloat = 2
    /// 걷기 애니메이션의 step1↔step2 교차 주기 (초). 0.18 = 1초당 ~5.5회 교차 — *총총* 보행 톤.
    /// 너무 짧으면 후드득 떨림, 너무 길면 *멈춤*처럼 보임. 픽셀 retro 게임 평균 보행 주기.
    static let pixelWalkFrameInterval: TimeInterval = 0.18

    // MARK: - Game UI Tokens (Phase 8-3)
    /// 원본 game.css 패널/카드 layout 상수 1:1 매핑.
    /// 디자인 단일 진실 원천 = style.css(L3-46) + game.css(L335-740).

    /// --radius 10px — 일반 카드/패널 코너
    static let uiRadius: CGFloat = 10
    /// --radius-sm 6px — 작은 카드 코너
    static let uiRadiusSm: CGFloat = 6
    /// 캡슐 코너 반경 — border-radius: 999px (난이도 버튼)
    static let uiRadiusPill: CGFloat = 999
    /// 일반 패널 max-width 360px
    static let uiPanelMaxWidth: CGFloat = 360
    /// character 패널 max-width 480px (.game-overlay__panel--character)
    static let uiPanelCharacterMaxWidth: CGFloat = 480
    /// 패널 좌우 padding (pt)
    static let uiPanelPaddingH: CGFloat = 20
    /// 패널 상하 padding (pt)
    static let uiPanelPaddingV: CGFloat = 22
    /// 패널 안 요소 사이 gap (pt)
    static let uiPanelGap: CGFloat = 14
    /// 제목 텍스트 font-size 22px
    static let uiTitleFontSize: CGFloat = 22
    /// 본문 텍스트 font-size 12px
    static let uiBodyFontSize: CGFloat = 12
    /// 보조 hint 텍스트 font-size 11px
    static let uiHintFontSize: CGFloat = 11
    /// HUD 값 font-size 22px (큰 숫자/점수)
    static let uiHudValueFontSize: CGFloat = 22
    /// HUD 라벨 font-size 10px (작은 캡션)
    static let uiHudLabelFontSize: CGFloat = 10
    /// 카드 이름 font-size 12px
    static let uiCardNameFontSize: CGFloat = 12
    /// 카드 태그(부제) font-size 10px
    static let uiCardTagFontSize: CGFloat = 10
    /// 카드 BEST 라벨 font-size 10px
    static let uiCardBestFontSize: CGFloat = 10
    /// 패널/카드 보더 line-width 1px
    static let uiPanelLineWidth: CGFloat = 1

    // MARK: - Result Scene UI (Phase 8-4)
    /// 원본 #overlayEnd .game-overlay__panel--end (game.css L877-906) 1:1 매핑.
    /// 반투명 검정 배경(.ganhoUIOverlayBg) + 가운데 380 너비 카드 패널(.ganhoUIBgCard) + 점수 40pt 코럴 serif.
    /// 라벨 위치는 *기존 유지*, 시각 토큰만 갈아 끼움(Phase 8-4 SPEC).

    /// 카드 패널 max-width — 원본 380px
    static let resultPanelMaxWidth: CGFloat = 380
    /// 카드 패널 height (pt) — 모바일 풀스크린 비율에 맞춰. 라벨 6개(+155 ~ -80)가 패널 안에 들어가도록 560.
    static let resultPanelHeight: CGFloat = 560
    /// 카드 패널 padding (pt) — 원본 padding 16 18 (좌우)
    static let resultPanelPadding: CGFloat = 18
    /// 점수 숫자 font-size — 원본 40px serif (모바일 32). 큰 점수 라벨 (.score-num)
    static let resultScoreNumFontSize: CGFloat = 40
    /// 점수 라벨 font-size — 원본 14px text-muted (.game-overlay__score)
    static let resultScoreLabelFontSize: CGFloat = 14
    /// 베스트 record font-size — 원본 12px brand (.game-overlay__record)
    static let resultRecordFontSize: CGFloat = 12
    /// 통계 라벨 font-size — 원본 11px upper case (.game-overlay__stats li label)
    static let resultStatsLabelFontSize: CGFloat = 11
    /// 통계 값 font-size — 원본 16px tabular (.game-overlay__stats li b, end-scope 15)
    static let resultStatsValueFontSize: CGFloat = 16

    // MARK: - HUD Layout (Phase 8-5)
    /// 원본 .game-hud (game.css L232-289) 상단 가로 슬롯 배치 1:1 매핑.
    /// 좌상단 세로 스택 → 상단 중앙 가로 4슬롯(TIME / SCORE / COMBO / PLAYER) 재구성.
    static let hudTopMargin: CGFloat = 28           // 화면 상단에서 hud anchor 거리
    static let hudSlotSpacing: CGFloat = 80         // 슬롯 4개 간격 (수평)
    static let hudValueFontSize: CGFloat = 22       // 원본 .game-hud__value 22px
    static let hudLabelFontSize: CGFloat = 10       // 원본 .game-hud__label 10px
    static let hudSlotInnerGap: CGFloat = 4         // 라벨 ↔ 값 세로 간격
    static let hudLabelLetterSpacing: CGFloat = 2   // 원본 letter-spacing 2px (SKLabelNode 미지원, 기록만)

    // MARK: - Checkerboard Floor (Phase 9-4)
    /// 체크보드 바닥 — 1152개(48×24) SKSpriteNode를 컨테이너 한 개에 묶어 worldNode에 부착.
    /// physicsBody 0 부착(시각 전용). setupWorld()에서 1회만 빌드 → update() 안 호출 금지.

    /// 체크보드 floorA hex(피치 밝은 칸) — Sprint 3 v2: 웜 피치 톤. 메뉴 그라데이션과 자연 연속.
    /// (was #1a1722 다크 차콜 — Sprint 3에서 v2 디자인 시스템 통합)
    static let checkerboardFloorAHex: String = "#FFEFE0"
    /// 체크보드 floorB hex(피치 어두운 칸) — Sprint 3 v2: 살짝 더 짙은 피치 톤.
    /// (was #13111a 다크 차콜 — Sprint 3에서 v2 디자인 시스템 통합)
    static let checkerboardFloorBHex: String = "#FFDFC8"
    /// 체크보드 컨테이너 zPosition. 외곽 벽/기둥(0)·Player/Enemy/StoneGuard(5) 아래.
    /// 음수 zPosition도 SpriteKit 정상 동작 — 시각 깊이 분리.
    static let checkerboardZPosition: CGFloat = -100
    /// 체크보드 컨테이너 노드 이름. 디버깅/탐색용 식별자 — 호출부 리터럴 노출 금지.
    static let checkerboardContainerName: String = "checkerboardFloor"

    // MARK: - Normal Map (Phase 9-4)
    /// normal 맵 — 좌·우 두 방 + 중앙 세로 분리벽 + 가운데 r=11~12 문 + 좌·우 장식 기둥.
    /// 좌표계: 맵 48×24 타일, tileSize=20pt, 원점 좌하단.

    /// 중앙 세로 분리벽 컬럼(c=23) — 맵 가로 정중앙 부근.
    static let normalMapDividerC: Int = 23
    /// 분리벽 윗 절반 시작 행. 문(r=11,12) 위쪽 구간.
    static let normalMapDividerUpperRStart: Int = 2
    /// 분리벽 윗 절반 끝 행. r=10까지 — r=11,12는 문으로 비워둠.
    static let normalMapDividerUpperREnd: Int = 10
    /// 분리벽 아랫 절반 시작 행. r=13부터 — r=11,12 문 아래.
    static let normalMapDividerLowerRStart: Int = 13
    /// 분리벽 아랫 절반 끝 행. r=21까지 — 외곽 벽(r=23) 안쪽 두 칸 여유.
    static let normalMapDividerLowerREnd: Int = 21
    /// 좌방 장식 기둥 시작 컬럼.
    static let normalMapLeftPillarCStart: Int = 10
    /// 좌방 장식 기둥 끝 컬럼. 2×2 타일 — (c=10..11, r=11..12).
    static let normalMapLeftPillarCEnd: Int = 11
    /// 좌방 장식 기둥 시작 행.
    static let normalMapLeftPillarRStart: Int = 11
    /// 좌방 장식 기둥 끝 행.
    static let normalMapLeftPillarREnd: Int = 12
    /// 우방 장식 기둥 시작 컬럼. 좌우 거울 대칭(mirroredC = 47 - leftC).
    static let normalMapRightPillarCStart: Int = 36
    /// 우방 장식 기둥 끝 컬럼.
    static let normalMapRightPillarCEnd: Int = 37
    /// 우방 장식 기둥 시작 행.
    static let normalMapRightPillarRStart: Int = 11
    /// 우방 장식 기둥 끝 행.
    static let normalMapRightPillarREnd: Int = 12
    /// addVerticalWall(doorR:)에 전달할 sentinel — 문 없음(전체 벽).
    /// 음수 -1이라 `r != -1`이 모든 양의 r에서 true → 모든 칸 벽으로 채워짐.
    static let normalMapNoDoorSentinel: Int = -1

    // MARK: - Skill (Phase 9-5)
    /// 캐릭터별 스킬 시스템. SkillSystem이 호출, HUDSkillSlotNode가 시각화.
    /// 4 스킬(정/건/임/이) + 김간호는 *스킬 없음*(정공법 정체성).

    // 공통 — SkillButtonNode (좌하단 1탭 발동)
    /// 스킬 버튼 반지름 (pt). D-Pad 한 변(44)과 시각 균형.
    static let skillButtonRadius: CGFloat = 32
    /// 버튼 우측 가장자리에서의 안쪽 마진 (pt). cameraNode 자식 좌표계 기준.
    /// D-Pad(dpadMarginX=90)와 대칭 — 두 손가락 자연 위치.
    static let skillButtonMarginX: CGFloat = 90
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
    /// 돌진 이동 거리 (pt). 3 tile = 60pt.
    static let dashClimbDistance: CGFloat = 60
    /// 돌진 지속 시간 (초). 돌진 중 isInvulnerable.
    static let dashClimbDuration: TimeInterval = 0.26
    /// 돌진 쿨다운 (초). 22초.
    static let dashClimbCooldown: TimeInterval = 22

    // 건간호 — 북클럽 소집 (.bookClubRally)
    /// 끌어오기 반경 (pt). 6 tile = 120pt 안의 노트만 대상.
    static let bookClubRallyRadius: CGFloat = 120
    /// 끌어오기 SKAction.move duration (초). easeIn 곡선과 함께 *자연스러운 가속*.
    static let bookClubRallyMoveDuration: TimeInterval = 0.4
    /// 북클럽 쿨다운 (초). 20초.
    static let bookClubRallyCooldown: TimeInterval = 20

    // 임간호 — 나는야 모범생 (.charmStudent, 게임당 1회)
    /// 매혹 지속 시간 (초). 이 시간 동안 F가 enchanted 상태.
    static let charmStudentDuration: TimeInterval = 1.5
    /// 매혹된 노트 수집 시 보너스 점수. scorePerNoteCombo(2)의 2배 = 4점.
    static let charmStudentBonusScore: Int = 4

    // 이간호 — 대만여행 / 텔레포트 (.taiwanTrip)
    /// 텔레포트 거리 (pt). 5 tile = 100pt.
    static let taiwanTripJumpDistance: CGFloat = 100
    /// 텔레포트 직후 무적 지속 시간 (초). 깜빡임 액션도 같은 시간.
    static let taiwanTripInvulnerableDuration: TimeInterval = 0.5
    /// 텔레포트 쿨다운 (초). 22초.
    static let taiwanTripCooldown: TimeInterval = 22
    /// 무적 깜빡임 시 최소 알파.
    static let taiwanTripFlashAlpha: CGFloat = 0.4
    /// 깜빡임 한 단계 길이 (초). 0.1 = 0.5초 동안 5회 깜빡임 (1.0 ↔ 0.4).
    static let taiwanTripFlashHalfPeriod: TimeInterval = 0.1

    // HUDSkillSlotNode
    /// 쿨다운 진행 링의 반지름 (pt). 작은 인디케이터.
    static let hudSkillSlotRingRadius: CGFloat = 12
    /// 링의 라인 두께 (pt).
    static let hudSkillSlotRingLineWidth: CGFloat = 2

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
    /// 변기 zPosition. note(0) 위, player/enemy/stoneGuard(5) 아래 — 4. SPEC.md §노드 트리 부착.
    static let toiletZPosition: CGFloat = 4
    /// 변기 ScorePopup fan-out 가로 offset (pt). 좌·우 ±8 = 음표 2개 동시 수집 시각 시그널.
    /// note 한 변(16)의 절반 — 두 라벨이 겹치지 않으면서 *동시 수집* 의미 전달.
    static let toiletScorePopupFanOutX: CGFloat = 8

    // MARK: - Toast Label (Phase 9-6)
    /// "화캉스 보너스!" 0.9초 토스트 — ScorePopupNode 패턴 답습 + 텍스트 길이만 다름.

    /// 변기 수집 시 표시 텍스트. 호출부 리터럴 노출 금지 — 단일 진실 원천.
    static let toiletToastText: String = "화캉스 보너스!"
    /// 토스트 1회 표시 총 길이 (초). group(move+fade+scale) duration. GDD §7-3.
    /// scorePopupDuration(0.6)보다 길고 comboPopupDuration(1.0)보다 짧음 — *임팩트 강조* 톤.
    static let toastDuration: TimeInterval = 0.9
    /// 토스트 텍스트 폰트 크기 (pt). scorePopupFontSize(28)과 comboPopupFontSize(48)의 중간 —
    /// *국지 시그널보다 강하고 글로벌 마일스톤보단 약함*.
    static let toastFontSize: CGFloat = 24
    /// 토스트 시작 y 오프셋 (pt). 변기 중심에서 위쪽 +16pt — 변기 본체와 텍스트 픽셀 겹침 방지.
    static let toastStartOffsetY: CGFloat = 16
    /// 토스트가 위로 떠오르는 총 거리 (pt). scorePopupFlyUpDistance(40)와 동일 — *지역* 시그널 톤 통일.
    static let toastFlyUpDistance: CGFloat = 40
    /// 토스트 시작 scale. scorePopupStartScale(0.8)과 동일 — *부풀어 오르는* 톤 디자인 통일.
    static let toastStartScale: CGFloat = 0.8
    /// 토스트 끝 scale. scorePopupEndScale(1.0)보다 살짝 큰 1.1 — *임팩트 강조* (확산 톤).
    static let toastEndScale: CGFloat = 1.1
    /// 토스트 zPosition. scorePopupZPosition(50)과 동급 — *지역* 시그널 군집 통일.
    static let toastZPosition: CGFloat = 50

    // MARK: - Professor (Phase 9-7)
    /// 이교수(ProfessorNode) — 상 난이도 전용 두 번째 적 NPC. 4 waypoint 순찰 + 청진기 투척.
    /// 수간호사(EnemyNode 추적 AI)와 석조무사(StoneGuardNode 패트롤) 사이의 중간형 — *순찰 + 원거리 공격*.

    /// 이교수 박스 가로 (pt). 수간호사/김간호와 동일 16×20.
    static let professorWidth: CGFloat = 16
    /// 이교수 박스 세로 (pt). 수간호사/김간호와 동일 16×20.
    static let professorHeight: CGFloat = 20
    /// 이교수 패트롤 속도 (pt/s). 석조무사(55)와 수간호사 base(60) 사이.
    /// 한 바퀴 둘레 = 2×(640-320) + 2×(280-200) = 640 + 160 = 800pt → 800/70 ≈ 11.4초.
    static let professorSpeed: CGFloat = 70
    /// 이교수 4 waypoint(시계방향: 좌하 → 우하 → 우상 → 좌상). 맵 중앙 영역 순찰.
    /// 석조무사와 동일 정책(시계방향 직사각형) — 외곽 벽/중앙 장애물 회피.
    static let professorWaypoints: [CGPoint] = [
        CGPoint(x: 320, y: 200),  // 좌하 — 시작 위치
        CGPoint(x: 640, y: 200),  // 우하
        CGPoint(x: 640, y: 280),  // 우상
        CGPoint(x: 320, y: 280)   // 좌상
    ]
    /// 청진기 발사 SKAction 키. stopThrowing/scheduleNextThrow가 공유 → endGame에서 removeAction(forKey:) 일괄 정지.
    /// 호출부 리터럴 노출 금지 — 단일 진실 원천.
    static let professorThrowActionKey: String = "professorThrow"
    /// 경고 컷씬 제목. 호출부 리터럴 노출 금지.
    static let professorWarningTitle: String = "경고 · 이교수 출현"
    /// 경고 컷씬 본문. GDD §10 + 사용자 요청 결합.
    static let professorWarningBody: String = "학교에서 나온 깐깐한 이교수가 청진기를 들고 순찰을 돕니다! 맞으면 잠시 움직일 수 없게 됩니다. 피하세요."

    // MARK: - Stethoscope (Phase 9-7)
    /// 청진기 투사체 — ProjectileNode(F)와 분리된 별도 PhysicsCategory.stethoscope 사용.
    /// 적중 시 즉시 게임오버가 아닌 *2초 정지* — F와 정체성 분리.

    /// 청진기 한 변 (pt). projectile(16)/note(16)보다 살짝 크게 — *위협 시그널* 강조.
    static let stethoscopeSize: CGFloat = 18
    /// 청진기 속도 (pt/s). projectile(160)보다 빠름 — 회피 난이도 상승.
    static let stethoscopeSpeed: CGFloat = 220
    /// 발사 주기 시작값 (초). 게임 시작 시점 도달값. 게임 진행률 0 → 2.5초.
    static let stethoscopeThrowIntervalStart: TimeInterval = 2.5
    /// 발사 주기 끝값 (초). 게임 종료 시점 도달값. 게임 진행률 1 → 1.4초.
    static let stethoscopeThrowIntervalEnd: TimeInterval = 1.4
    /// 동시에 떠 있을 수 있는 청진기 최대 수. F(2~4)와 별도 — 4발까지 동시 가능.
    static let stethoscopeMaxConcurrent: Int = 4
    /// 청진기 회전 1회전 길이 (초). 시각 회전 SKAction.rotate — 충돌 박스 무관 (allowsRotation=false).
    static let stethoscopeRotationDuration: TimeInterval = 0.5
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

    // MARK: - Start Scene (Phase 10-1a)
    /// 게임 톤 소개 본문 — 스토리 박스 본문. GDD §1·§3 정착 텍스트.
    /// 호출부 리터럴 노출 금지 — 단일 진실 원천.
    static let startSceneStoryText: String =
        "실습 중 마음에 떠오른 멜로디를 45초 안에 모아 보세요. 수간호사 눈을 피하는 게 핵심."
    /// 부제 라벨 폰트 크기 (pt). titleFontSize(36)과 titlePromptFontSize(18) 사이.
    static let startSceneSubtitleFontSize: CGFloat = 16
    /// 부제 라벨 y 오프셋. titleLabelOffsetY(120) 바로 아래에 위치.
    static let startSceneSubtitleOffsetY: CGFloat = 80
    /// 상단 BEST/PLAYS 라인 y 오프셋. 패널 위쪽 상단 라인.
    static let startSceneBestPlaysTopMargin: CGFloat = 180
    /// BEST/PLAYS 라벨 좌우 간격 (pt). frame.midX 기준 ±값으로 가로 2개 배치.
    static let startSceneBestPlaysSpacing: CGFloat = 80
    /// 스토리 박스 y 오프셋. 패널 정중앙(부제 아래/난이도 위).
    static let startSceneStoryBoxOffsetY: CGFloat = 0
    /// 시작 버튼 y 오프셋. 패널 하단(난이도 카드 +80 아래쪽으로 충분히 떨어진 위치).
    static let startSceneStartButtonOffsetY: CGFloat = -180

    /// 스토리 박스 가로 (pt). uiPanelCharacterMaxWidth(480)보다 살짝 좁아 패널 안 내부 여백 확보.
    static let storyBoxWidth: CGFloat = 440
    /// 스토리 박스 세로 (pt). 한국어 본문 2~3줄 자동 줄바꿈에 충분한 높이.
    static let storyBoxHeight: CGFloat = 80
    /// 스토리 박스 본문 폰트 크기 (pt). cutsceneBodyFontSize(20)보다 작음 — 박스 안 톤.
    static let storyBoxFontSize: CGFloat = 14
    /// 스토리 박스 좌우 패딩 (pt). preferredMaxLayoutWidth = boxWidth - padding×2.
    static let storyBoxHorizontalPadding: CGFloat = 16

    /// 주요 버튼 가로 (pt). 한국어 2~5자 + 여백.
    static let primaryButtonWidth: CGFloat = 160
    /// 주요 버튼 세로 (pt). cornerRadius = height/2로 캡슐.
    static let primaryButtonHeight: CGFloat = 48
    /// 주요 버튼 폰트 크기 (pt).
    static let primaryButtonFontSize: CGFloat = 18
    /// 보조(뒤로) 버튼 가로 (pt). 주요 버튼보다 살짝 좁음 — 시각 위계.
    static let backButtonWidth: CGFloat = 140
    /// 보조 버튼 세로 (pt).
    static let backButtonHeight: CGFloat = 40
    /// 보조 버튼 폰트 크기 (pt). 주요(18)보다 작음.
    static let backButtonFontSize: CGFloat = 14

    // MARK: - Character Select Scene (Phase 10-1b)
    /// 화면 헤더 텍스트 — "함께할 친구를 골라요". 호출부 리터럴 노출 금지.
    static let characterSelectHeaderText: String = "함께할 친구를 골라요"
    /// 헤더 폰트 크기 (pt). titleFontSize(36)보다 작음 — 부분 화면 헤더 톤.
    static let characterSelectHeaderFontSize: CGFloat = 22
    /// 헤더 y 오프셋. 패널 상단 부근.
    static let characterSelectHeaderOffsetY: CGFloat = 140
    /// 캐릭터 카드 행 y 오프셋. 헤더 아래 적당한 간격.
    static let characterSelectCardOffsetY: CGFloat = 30
    /// 태그 라벨 폰트 크기 (pt). characterCardWidth(48) 안에 1~5자 작은 태그.
    static let characterSelectTagFontSize: CGFloat = 10
    /// 태그 라벨 y 오프셋 (카드 *외부*, 카드 위치 기준). 카드 아래쪽 -45pt.
    static let characterSelectTagOffsetY: CGFloat = -45
    /// 버튼 행 y 오프셋. 카드 아래 충분한 간격.
    static let characterSelectButtonRowOffsetY: CGFloat = -160
    /// 두 버튼 좌우 간격 (pt). frame.midX 기준 ±(spacing/2).
    static let characterSelectButtonSpacing: CGFloat = 200

    // MARK: - Skill Explanation Scene (Phase 10-1c)
    /// 화면 헤더 텍스트 — "스킬을 익혀요". 호출부 리터럴 노출 금지.
    static let skillExplanationHeaderText: String = "스킬을 익혀요"
    /// 헤더 폰트 크기 (pt). characterSelectHeaderFontSize(22)와 동급 — 시각 일관성.
    static let skillExplanationHeaderFontSize: CGFloat = 22
    /// 헤더 y 오프셋.
    static let skillExplanationHeaderOffsetY: CGFloat = 140
    /// 큰 아바타 가로 (pt). PixelSpriteRenderer 16×20 픽셀 텍스처를 7.5배 확대 표현.
    static let skillExplanationAvatarWidth: CGFloat = 120
    /// 큰 아바타 세로 (pt). 픽셀 비율 유지(16:20 ≈ 4:5).
    static let skillExplanationAvatarHeight: CGFloat = 150
    /// 아바타 x 오프셋. frame.midX 기준 왼쪽.
    static let skillExplanationAvatarOffsetX: CGFloat = -160
    /// 아바타 y 오프셋. 화면 중앙 살짝 위.
    static let skillExplanationAvatarOffsetY: CGFloat = 20
    /// 스킬명 라벨 폰트 크기 (pt). 큰 강조 — *주인공* 정보.
    static let skillExplanationSkillNameFontSize: CGFloat = 28
    /// 스킬명 x 오프셋. 아바타 옆 오른쪽 영역.
    static let skillExplanationSkillNameOffsetX: CGFloat = 80
    /// 스킬명 y 오프셋. 스토리 박스 위쪽.
    static let skillExplanationSkillNameOffsetY: CGFloat = 80
    /// 스킬 설명 박스 x 오프셋. 스킬명과 동일 — 우측 정렬.
    static let skillExplanationStoryBoxOffsetX: CGFloat = 80
    /// 스킬 설명 박스 y 오프셋. 스킬명 아래.
    static let skillExplanationStoryBoxOffsetY: CGFloat = 0
    /// 조작 안내 라벨 폰트 크기 (pt). 부속 정보 톤.
    static let skillExplanationControlHintFontSize: CGFloat = 12
    /// 조작 안내 텍스트 — 호출부 리터럴 노출 금지.
    static let skillExplanationControlHintText: String = "좌하단 스킬 버튼을 1번 탭하면 발동"
    /// 조작 안내 y 오프셋. 스토리 박스 바로 아래.
    static let skillExplanationControlHintOffsetY: CGFloat = -60
    /// 버튼 행 y 오프셋. 패널 하단.
    static let skillExplanationButtonRowOffsetY: CGFloat = -160

    // MARK: - Stone Guard Warning Cutscene (Phase 10-1d)
    /// easy/normal 난이도 인트로 컷씬 직후 발화되는 *석조무사 경고* 컷씬 제목.
    /// hard의 professorWarningTitle과 시그니처 동형 — CutsceneOverlayNode 재사용.
    static let stoneGuardWarningTitle: String = "경고 · 석조무사 출현"
    /// 석조무사 경고 본문. GDD §10 + 사용자 요청 결합.
    /// 호출부 리터럴 노출 금지 — 단일 진실 원천.
    static let stoneGuardWarningBody: String =
        "수간호사의 충실한 부하 석조무사가 출현합니다! 마주치면 잡혀갑니다. 절대 만나지 마세요."

    // MARK: - Start Scene Visual (Phase 10-2 · 병동의 새벽 톤)
    /// StartScene 비주얼 리스킨. 그라데이션 배경 + 음표 파티클 + 제목 글로우 + 카드 spring + 버튼 pulse + 전환 잔향.
    /// 본 섹션은 *추가만* — 기존 GameConfig 상수 변경 0건.

    /// 그라데이션 배경 zPosition. overlayBackground(-10)보다 아래.
    static let startSceneGradientZPosition: CGFloat = -20
    /// 음표 파티클 zPosition. overlayBackground(-10)보다 위, overlayPanel(-5)보다 아래.
    /// 패널 위로 음표가 *튀어나오지 않게* 의도적 후방 배치.
    static let startSceneMusicNoteZPosition: CGFloat = -15

    /// 음표 파티클 동시 표시 상한. 성능 가드.
    static let musicNoteEmitterMaxConcurrent: Int = 15
    /// 음표 스폰 주기 (초). 너무 잦으면 산만, 너무 적으면 휑함.
    static let musicNoteEmitterSpawnInterval: TimeInterval = 0.5
    /// 음표 글리프 폰트 크기 (pt). 살짝 큰 18pt — 시각 인지성 + 우아함.
    static let musicNoteEmitterFontSize: CGFloat = 18
    /// 음표 한 개가 화면 하단 → 상단 통과까지 걸리는 시간 (초). 8s — 느릿한 부유감.
    static let musicNoteEmitterRiseDuration: TimeInterval = 8.0
    /// 음표 fade-in 시간 (초).
    static let musicNoteEmitterFadeInDuration: TimeInterval = 0.5
    /// 음표 fade-out 시간 (초). 상승 종료 직전.
    static let musicNoteEmitterFadeOutDuration: TimeInterval = 1.0
    /// 음표 최대 알파. 0.7 — 배경 위에 *떠 있는* 톤.
    static let musicNoteEmitterMaxAlpha: CGFloat = 0.7
    /// 음표 초기 y 위치 (씬 하단 기준 offset, pt). 화면 아래에서 시작해 자연스럽게 등장.
    static let musicNoteEmitterStartYOffset: CGFloat = -20
    /// 음표 상승 종료 y 마진 (씬 상단 위로 추가 이동량, pt).
    static let musicNoteEmitterRiseEndYMargin: CGFloat = 40
    /// 음표 좌우 흔들림 범위 (절대값, pt). 자연스러운 부유 표현.
    static let musicNoteEmitterDriftRange: CGFloat = 30

    /// 제목 글로우 SKEffectNode CIGaussianBlur 반경 (pt).
    static let titleGlowBlurRadius: CGFloat = 8.0

    /// 난이도 카드 선택 시 spring overshoot scale. 1.12 → settle 1.08.
    static let difficultyCardSpringOvershootScale: CGFloat = 1.12
    /// spring phase 1 (overshoot)까지 걸리는 시간 (초). easeOut.
    static let difficultyCardSpringPhase1Duration: TimeInterval = 0.18
    /// spring phase 2 (settle)까지 걸리는 시간 (초). easeInEaseOut.
    static let difficultyCardSpringPhase2Duration: TimeInterval = 0.12

    /// 난이도 카드 살구 링 글로우 패딩 (pt). 카드 외곽보다 살짝 큰 capsule.
    static let difficultyCardRingGlowPadding: CGFloat = 10
    /// 링 글로우 stroke 두께 (pt).
    static let difficultyCardRingGlowLineWidth: CGFloat = 2
    /// 링 글로우 glow 폭 (pt). SKShapeNode glowWidth.
    static let difficultyCardRingGlowWidth: CGFloat = 6
    /// 링 글로우 fade-in 시간 (초). 선택 시 자연스러운 빛 띄움.
    static let difficultyCardRingGlowFadeInDuration: TimeInterval = 0.2
    /// 링 글로우 fade-out 시간 (초). 해제 시 빠른 정리.
    static let difficultyCardRingGlowFadeOutDuration: TimeInterval = 0.1

    /// 시작 버튼 pulse 최소 scale. 호흡 들이마시는 톤.
    static let startButtonPulseScaleMin: CGFloat = 0.98
    /// 시작 버튼 pulse 최대 scale. 호흡 내쉬는 톤.
    static let startButtonPulseScaleMax: CGFloat = 1.02
    /// 시작 버튼 pulse 반주기 (초). 1.0초 × 2 = 2초 1주기 — 심호흡 리듬.
    static let startButtonPulseHalfDuration: TimeInterval = 1.0

    /// 씬 전환 시 카드/스토리/버튼 슬라이드업 거리 (pt). 살짝만 — 연결감 위주.
    static let startSceneExitSlideDistance: CGFloat = 30
    /// 슬라이드업 + fadeOut 지속시간 (초). presentScene 전 prelude.
    static let startSceneExitSlideDuration: TimeInterval = 0.2

    // MARK: - Typography (Sprint 1 · v2 Design System)
    // DESIGN_RENEWAL_REQUEST.md §3.2 폰트 시스템.
    // ttf 파일 실제 임포트는 사용자 후속 작업(Xcode add to target + Info.plist UIAppFonts).
    // 본 상수는 *이름만* 정의 — SKLabelNode(fontNamed:)는 ttf 미존재 시 시스템 폰트로 자동 fallback,
    // 컴파일 및 런타임 모두 깨지지 않음.

    /// Display 폰트 — 타이틀·UI 강조 (Jua-Regular). 모든 타이틀, 버튼 텍스트, HUD 값.
    static let fontDisplay: String = "Jua-Regular"
    /// Body 폰트 — 본문·설명 (GowunDodum-Regular). 태그라인, 스킬 설명, 카드 부제.
    static let fontBody: String = "GowunDodum-Regular"
    /// Numeric 폰트 — 수치 표시 (NotoSansKR-Bold). 점수·시간 등 정렬 필요한 숫자.
    static let fontNumeric: String = "NotoSansKR-Bold"

    // MARK: - v2 Components (Sprint 1)

    /// GlassPillNode 배경 화이트 α. DESIGN_RENEWAL_REQUEST.md §3.3.B = 0.55.
    static let glassPillFillAlpha: CGFloat = 0.55
    /// GlassPillNode stroke α — 살짝의 외곽선.
    static let glassPillStrokeAlpha: CGFloat = 0.25
    /// GlassPillNode 가우시안 블러 반경. §3.3.B = radius 12.
    static let glassPillBlurRadius: CGFloat = 12
    /// GlassPillNode 라벨 폰트 크기.
    static let glassPillFontSize: CGFloat = 14

    /// AccentLineNode 가로 길이(pt). §3.3.C = 32.
    static let accentLineWidth: CGFloat = 32
    /// AccentLineNode 두께(pt). §3.3.C = 3.
    static let accentLineHeight: CGFloat = 3

    /// DarkContextChipNode 배경 navy α. §3.3.D = 0.92.
    static let darkContextChipBgAlpha: CGFloat = 0.92
    /// DarkContextChipNode 라벨 폰트 크기.
    static let darkContextChipLabelFontSize: CGFloat = 13
    /// DarkContextChipNode 뱃지 폰트 크기. 더 작음.
    static let darkContextChipBadgeFontSize: CGFloat = 11
    /// DarkContextChipNode 가로 패딩(pt) — 라벨 양옆 여백.
    static let darkContextChipHorizontalPadding: CGFloat = 14
    /// DarkContextChipNode 세로 높이(pt).
    static let darkContextChipHeight: CGFloat = 28
    /// DarkContextChipNode 라벨-뱃지 간 가로 간격(pt).
    static let darkContextChipBadgeSpacing: CGFloat = 8
    /// DarkContextChipNode 뱃지 내부 가로 패딩(pt) — 뱃지 라벨 양옆 여백.
    static let darkContextChipBadgeHorizontalPadding: CGFloat = 12
    /// DarkContextChipNode 뱃지 세로 inset(pt) — 칩 높이 - inset = 뱃지 높이.
    static let darkContextChipBadgeVerticalInset: CGFloat = 8

    /// PrimaryButtonNode v2 그림자 y 오프셋(pt) — 음수면 아래쪽. §3.3.A = 6 → -6.
    static let primaryButtonShadowOffsetY: CGFloat = -6
    /// PrimaryButtonNode v2 그림자 blur(pt).
    static let primaryButtonShadowBlurRadius: CGFloat = 12
    /// PrimaryButtonNode v2 우측 화살표 원 반경(pt).
    static let primaryButtonArrowRadius: CGFloat = 12
    /// PrimaryButtonNode v2 우측 화살표 우측 마진(pt) — 배경 우측 끝에서 안쪽 거리.
    static let primaryButtonArrowInsetX: CGFloat = 22
    /// PrimaryButtonNode v2 우측 화살표 원 화이트 α — 살짝 반투명한 동그라미.
    static let primaryButtonArrowCircleAlpha: CGFloat = 0.25
    /// PrimaryButtonNode v2 우측 화살표 라벨 폰트 크기(pt).
    static let primaryButtonArrowLabelFontSize: CGFloat = 14

    // MARK: - Sprint 2 · StartScene v2 Layout
    // DESIGN_RENEWAL_REQUEST.md §4.1 + mockups/main-screen-v2.html.
    // 본 섹션은 *추가만* — 기존 startScene* 상수(Phase 10-1a/10-2)는 미사용 상태가 되어도 *유지*.

    /// StartScene 타이틀 1행("김간호는") 폰트 크기(pt). §4.1 = 44pt navyDeep.
    static let startSceneTitleLine1FontSize: CGFloat = 44
    /// StartScene 타이틀 2행("음악박사 ♪") 폰트 크기(pt). §4.1 = 56pt coralPrimary.
    static let startSceneTitleLine2FontSize: CGFloat = 56
    /// StartScene 태그라인 폰트 크기(pt). Gowun Dodum body 톤.
    static let startSceneTaglineFontSize: CGFloat = 13
    /// StartScene 태그라인 자동 줄바꿈 폭(pt). preferredMaxLayoutWidth.
    static let startSceneTaglineMaxWidth: CGFloat = 240
    /// StartScene 타이틀 블록 우측 마진(pt). frame.maxX - margin이 우측 정렬 기준.
    static let startSceneTitleBlockRightMargin: CGFloat = 64
    /// StartScene 타이틀 블록 y 오프셋(pt). frame.midY + offset.
    static let startSceneTitleBlockOffsetY: CGFloat = 60
    /// StartScene 2행 사이 줄간 y 간격(pt). titleLine1 → titleLine2.
    static let startSceneTitleLineSpacing: CGFloat = 58
    /// StartScene AccentLine 타이틀 블록 위 y 오프셋(pt). 타이틀1 위 +24.
    static let startSceneAccentLineAboveTitleOffset: CGFloat = 36
    /// StartScene 태그라인 타이틀2 아래 y 오프셋(pt).
    static let startSceneTaglineBelowTitleOffset: CGFloat = -48

    /// StartScene BEST/PLAYS 알약 폭(pt). §4.1 = 96.
    static let startSceneStatPillWidth: CGFloat = 96
    /// StartScene BEST/PLAYS 알약 높이(pt).
    static let startSceneStatPillHeight: CGFloat = 28
    /// StartScene 알약 좌우 마진(pt). frame.minX/maxX 기준 안쪽 거리.
    static let startSceneStatPillSideMargin: CGFloat = 60
    /// StartScene 알약 상단 마진(pt). frame.maxY 기준 아래쪽 거리.
    static let startSceneStatPillTopMargin: CGFloat = 30

    // MARK: - Sprint 2 · CharacterSelectScene v2 Layout
    // DESIGN_RENEWAL_REQUEST.md §4.2 + mockups/character-select-v2.html.

    /// 헤더 부제(Gowun Dodum) 폰트 크기(pt). §4.2 = 12pt navyMuted.
    static let characterSelectHeaderSubFontSize: CGFloat = 12
    /// 헤더 부제 텍스트.
    static let characterSelectHeaderSubText: String = "친구마다 다른 스킬과 이동속도를 가져요"
    /// 헤더 부제 y 오프셋(pt). headerLabel 아래 -22.
    static let characterSelectHeaderSubOffsetY: CGFloat = -22
    /// 헤더 AccentLine y 오프셋(pt). headerLabel 위 +24.
    static let characterSelectAccentLineOffsetY: CGFloat = 24

    /// 뒤로 GlassPill 텍스트.
    /// Sprint 6 — 흐름 재편: 캐릭터 선택의 직전 단계가 StartScene(메인)으로 바뀜.
    /// 난이도 결정은 5단계 흐름의 *마지막*(DifficultySelectScene)으로 이동했으므로
    /// "← 난이도 다시"가 의미적으로 깨진다 — 텍스트만 "← 메인"으로 교체. 상수 이름 보존.
    static let characterSelectBackPillText: String = "← 메인"
    /// 뒤로 GlassPill 폭(pt).
    static let characterSelectBackPillWidth: CGFloat = 120
    /// 뒤로 GlassPill 높이(pt).
    static let characterSelectBackPillHeight: CGFloat = 28
    /// 난이도 칩 본 라벨 텍스트.
    static let characterSelectDifficultyChipLabel: String = "현재 난이도"
    /// Top bar 좌우 마진(pt). frame.minX/maxX 기준.
    static let characterSelectTopBarMarginX: CGFloat = 40
    /// Top bar 상단 마진(pt). frame.maxY 기준 아래쪽 거리.
    static let characterSelectTopBarMarginY: CGFloat = 30

    /// 카드 외곽 글래스 컨테이너 폭(pt). Sprint 7+ — 110 → 156 (카드 확대에 동기).
    /// characterCardWidth(76) + 좌우 inset 40 = 156. 카드 위 글래스 띠 두께 보존.
    static let characterCardGlassWidth: CGFloat = 156
    /// 카드 외곽 글래스 컨테이너 높이(pt). Sprint 7+ — 140 → 204 (카드 확대에 동기).
    /// characterCardHeight(104) + 상하 inset 100 = 204. 라벨/태그 공간 확보.
    static let characterCardGlassHeight: CGFloat = 204
    /// 카드 외곽 글래스 cornerRadius(pt).
    static let characterCardGlassCornerRadius: CGFloat = 18
    /// 카드 외곽 글래스 fill 알파(흰색).
    static let characterCardGlassFillAlpha: CGFloat = 0.65
    /// 카드 우상단 색 점 반지름(pt). §4.2 = 4 (지름 8).
    static let characterCardColorDotRadius: CGFloat = 4
    /// 카드 색 점 카드 외곽으로부터 우측 inset(pt).
    static let characterCardColorDotInsetX: CGFloat = 14
    /// 카드 색 점 카드 외곽으로부터 상단 inset(pt).
    static let characterCardColorDotInsetY: CGFloat = 14
    /// 카드 외곽 글래스 선택 시 scale.
    static let characterCardGlassSelectedScale: CGFloat = 1.08
    /// 카드 외곽 글래스 선택 시 y 오프셋(pt). 살짝 위로 떠오름.
    static let characterCardGlassSelectedYOffset: CGFloat = 12
    /// 카드 외곽 글래스 선택 시 stroke 두께(pt).
    static let characterCardGlassSelectedStrokeWidth: CGFloat = 2
    /// 카드 외곽 글래스 scale 액션 duration(초).
    static let characterCardGlassScaleDuration: TimeInterval = 0.18

    /// 하단 스킬 정보 칩 y 오프셋(pt). frame.midY 기준.
    static let characterSelectSkillInfoOffsetY: CGFloat = -100
    /// confirm 버튼 y 오프셋(pt). frame.midY 기준.
    static let characterSelectConfirmButtonOffsetY: CGFloat = -180

    // MARK: - Sprint 2 · SkillExplanationScene v2 Layout
    // DESIGN_RENEWAL_REQUEST.md §4.3 + mockups/skill-explanation-v2.html.

    /// 헤더 부제 텍스트.
    static let skillExplanationHeaderSubText: String = "한 번만 익히면 충분해요. 바로 시작할 수 있어요"
    /// 헤더 부제 폰트 크기(pt).
    static let skillExplanationHeaderSubFontSize: CGFloat = 12
    /// 헤더 AccentLine y 오프셋(pt). headerLabel 위 +24.
    static let skillExplanationAccentLineOffsetY: CGFloat = 24
    /// 헤더 부제 y 오프셋(pt). headerLabel 아래 -22.
    static let skillExplanationHeaderSubOffsetY: CGFloat = -22

    /// Top bar 뒤로 GlassPill 텍스트.
    static let skillExplanationBackPillText: String = "← 캐릭터 다시"
    /// Top bar 뒤로 GlassPill 폭(pt).
    static let skillExplanationBackPillWidth: CGFloat = 130
    /// Top bar 뒤로 GlassPill 높이(pt).
    static let skillExplanationBackPillHeight: CGFloat = 28
    /// Top bar 브레드크럼 칩 뱃지 텍스트("스킬").
    static let skillExplanationBreadcrumbBadge: String = "스킬"
    /// Top bar 좌우 마진(pt).
    static let skillExplanationTopBarMarginX: CGFloat = 40
    /// Top bar 상단 마진(pt).
    static let skillExplanationTopBarMarginY: CGFloat = 30

    /// 좌측 아바타 글래스 카드 폭(pt). §4.3 = 180.
    static let skillExplanationAvatarCardWidth: CGFloat = 180
    /// 좌측 아바타 글래스 카드 높이(pt).
    static let skillExplanationAvatarCardHeight: CGFloat = 200
    /// 좌측 아바타 글래스 카드 cornerRadius(pt).
    static let skillExplanationAvatarCardCornerRadius: CGFloat = 24
    /// 아바타 카드 fill 알파.
    static let skillExplanationAvatarCardFillAlpha: CGFloat = 0.85
    /// 아바타 카드 stroke 알파(코랄).
    static let skillExplanationAvatarCardStrokeAlpha: CGFloat = 0.3
    /// 아바타 카드 stroke 두께(pt).
    static let skillExplanationAvatarCardStrokeWidth: CGFloat = 2
    /// 아바타 카드 x 오프셋(pt). frame.midX 기준 좌측.
    static let skillExplanationAvatarCardOffsetX: CGFloat = -180
    /// 아바타 카드 y 오프셋(pt). frame.midY 기준.
    static let skillExplanationAvatarCardOffsetY: CGFloat = 0
    /// 아바타 이름 뱃지(코랄 알약) y 오프셋(pt). 카드 안 상단.
    static let skillExplanationAvatarNameBadgeOffsetY: CGFloat = 90
    /// 아바타 이름 뱃지 폰트 크기(pt).
    static let skillExplanationAvatarNameBadgeFontSize: CGFloat = 12
    /// 아바타 이름 뱃지 폭(pt).
    static let skillExplanationAvatarNameBadgeWidth: CGFloat = 80
    /// 아바타 이름 뱃지 높이(pt).
    static let skillExplanationAvatarNameBadgeHeight: CGFloat = 24
    /// 아바타 role 라벨 y 오프셋(pt). 카드 아래.
    static let skillExplanationAvatarRoleOffsetY: CGFloat = -110
    /// 아바타 role 라벨 폰트 크기(pt).
    static let skillExplanationAvatarRoleFontSize: CGFloat = 11
    /// 아바타 속도 칩 y 오프셋(pt). role 아래.
    static let skillExplanationAvatarSpeedChipOffsetY: CGFloat = -130

    /// 우측 메타 라벨(코랄, Gowun Dodum) 폰트 크기(pt).
    static let skillExplanationMetaLabelFontSize: CGFloat = 11
    /// 우측 메타 라벨 x 오프셋(pt). frame.midX 기준 우측.
    static let skillExplanationMetaLabelOffsetX: CGFloat = 80
    /// 우측 메타 라벨 y 오프셋(pt). skillNameLabel 위.
    static let skillExplanationMetaLabelOffsetY: CGFloat = 120

    /// 인용 박스 폭(pt). §4.3.
    static let skillExplanationQuoteBoxWidth: CGFloat = 300
    /// 인용 박스 높이(pt).
    static let skillExplanationQuoteBoxHeight: CGFloat = 80
    /// 인용 박스 cornerRadius(pt).
    static let skillExplanationQuoteBoxCornerRadius: CGFloat = 14
    /// 인용 박스 fill 알파(흰색).
    static let skillExplanationQuoteBoxFillAlpha: CGFloat = 0.55
    /// 인용 박스 좌측 코랄 보더 두께(pt).
    static let skillExplanationQuoteBoxBorderWidth: CGFloat = 3
    /// 인용 박스 본문 폰트 크기(pt).
    static let skillExplanationQuoteBoxFontSize: CGFloat = 14
    /// 인용 박스 본문 좌우 패딩(pt). preferredMaxLayoutWidth = boxWidth - padding*2.
    static let skillExplanationQuoteBoxHorizontalPadding: CGFloat = 28
    /// 인용 박스 y 오프셋(pt). frame.midY 기준.
    static let skillExplanationQuoteBoxOffsetY: CGFloat = 0

    /// 우측 메타 칩 가로 간격(pt). 3개 사이.
    static let skillExplanationStatChipSpacing: CGFloat = 8
    /// 우측 메타 칩 행 y 오프셋(pt). frame.midY 기준.
    static let skillExplanationStatChipRowOffsetY: CGFloat = -60

    /// 컨트롤 힌트 컨테이너 폭(pt).
    static let skillExplanationControlHintContainerWidth: CGFloat = 280
    /// 컨트롤 힌트 컨테이너 높이(pt).
    static let skillExplanationControlHintContainerHeight: CGFloat = 32
    /// 컨트롤 힌트 컨테이너 fill 알파(navy).
    static let skillExplanationControlHintContainerFillAlpha: CGFloat = 0.92
    /// 컨트롤 힌트 "B" 키 원 반지름(pt).
    static let skillExplanationControlHintKeyCircleRadius: CGFloat = 11
    /// 컨트롤 힌트 "B" 라벨 폰트 크기(pt).
    static let skillExplanationControlHintKeyFontSize: CGFloat = 12
    /// 컨트롤 힌트 본 라벨 폰트 크기(pt).
    static let skillExplanationControlHintLabelFontSize: CGFloat = 12
    /// 컨트롤 힌트 컨테이너 내부 좌우 패딩(pt).
    static let skillExplanationControlHintHorizontalPadding: CGFloat = 14
    /// 컨트롤 힌트 "B" 원 ~ 라벨 간격(pt).
    static let skillExplanationControlHintKeySpacing: CGFloat = 10
    /// 컨트롤 힌트 컨테이너 y 오프셋(pt). frame.midY 기준.
    static let skillExplanationControlHintContainerOffsetY: CGFloat = -120

    // MARK: - Sprint 3 · v2 Game Visual
    // DESIGN_RENEWAL_REQUEST.md §4.4 + mockups/game-map-v2.html.
    // 본 섹션은 *추가만* — 기존 hudValueFontSize / comboPopupFontSize / hudLabelFontSize 등
    // Phase 8-5 / 6-10 / 6-12 상수는 *유지*. v2 상수가 별도 이름으로 공존.

    // HUD 슬롯 칩 (Sprint 3)
    /// HUD 슬롯 navy 알약 배경 알파.
    static let hudSlotBgAlpha: CGFloat = 0.78
    /// HUD 슬롯 알약 cornerRadius(pt).
    static let hudSlotCornerRadius: CGFloat = 14
    /// HUD 슬롯 폭(pt).
    static let hudSlotWidth: CGFloat = 78
    /// HUD 슬롯 높이(pt).
    static let hudSlotHeight: CGFloat = 44
    /// HUD 슬롯 v2 라벨 폰트 크기(pt). 기존 hudLabelFontSize(10)와 동일 수치이지만 분리.
    static let hudSlotV2LabelFontSize: CGFloat = 10
    /// HUD 슬롯 v2 값 폰트 크기(pt). 기존 hudValueFontSize(22)에서 18로 축소(v2 톤).
    static let hudSlotV2ValueFontSize: CGFloat = 18
    /// TIME 슬롯 12초(또는 tensionWindow) 이하 진입 시 코랄 경고 배경 알파.
    static let hudSlotWarnBgAlpha: CGFloat = 0.85
    /// TIME 슬롯 진행바 두께(pt).
    static let hudTimeBarHeight: CGFloat = 3
    /// TIME 슬롯 진행바와 값 사이 세로 간격(pt).
    static let hudTimeBarTopGap: CGFloat = 3
    /// TIME 슬롯 진행바 배경 알파(흰색 위).
    static let hudTimeBarBgAlpha: CGFloat = 0.18

    // D-Pad v2 (Sprint 3)
    /// 중앙 데드존 SKShapeNode 한 변 길이(pt).
    static let dpadCenterDeadzoneSize: CGFloat = 32
    /// 중앙 데드존 navy 알파.
    static let dpadCenterDeadzoneAlpha: CGFloat = 0.4
    /// 중앙 데드존 cornerRadius(pt).
    static let dpadCenterDeadzoneCornerRadius: CGFloat = 6
    /// D-Pad 4 버튼 white 채움 알파.
    static let dpadButtonFillAlpha: CGFloat = 0.75
    /// D-Pad 4 버튼 navy 외곽선 알파.
    static let dpadButtonStrokeAlpha: CGFloat = 0.25
    /// D-Pad 4 버튼 cornerRadius(pt).
    static let dpadButtonCornerRadius: CGFloat = 10
    /// D-Pad 4 버튼 외곽선 두께(pt).
    static let dpadButtonStrokeLineWidth: CGFloat = 2

    // Skill Button v2 (Sprint 3)
    /// 스킬 버튼 v2 반지름(pt). 기존 skillButtonRadius(32)에서 36으로 확대.
    static let skillButtonV2Radius: CGFloat = 36
    /// 스킬 버튼 v2 외곽선 두께(pt).
    static let skillButtonV2StrokeWidth: CGFloat = 3
    /// 스킬 버튼 우상단 "B" 키 칩 본체로부터의 offset(pt).
    static let skillButtonV2KeyLabelOffset: CGFloat = 28
    /// 스킬 버튼 아래 스킬명 칩 y 오프셋(pt). 본체 아래쪽.
    static let skillButtonNameChipOffsetY: CGFloat = -52
    /// 스킬 버튼 키 라벨 텍스트.
    static let skillButtonKeyText: String = "B"

    // Pause Button v2 (Sprint 3 — 시각 placeholder)
    /// 일시정지 버튼 본체 한 변(pt).
    static let pauseButtonSize: CGFloat = 32
    /// 일시정지 버튼 cornerRadius(pt).
    static let pauseButtonCornerRadius: CGFloat = 10
    /// 일시정지 버튼 navy 배경 알파.
    static let pauseButtonBgAlpha: CGFloat = 0.78
    /// 일시정지 버튼 흰 || 두 줄 폭(pt).
    static let pauseButtonBarWidth: CGFloat = 4
    /// 일시정지 버튼 흰 || 두 줄 높이(pt).
    static let pauseButtonBarHeight: CGFloat = 14
    /// 일시정지 버튼 두 줄 사이 간격(pt).
    static let pauseButtonBarGap: CGFloat = 2
    /// 일시정지 버튼 우상단 우측 마진(pt). cameraNode 자식 좌표계 기준.
    static let pauseButtonMarginX: CGFloat = 28
    /// 일시정지 버튼 상단 마진(pt).
    static let pauseButtonMarginY: CGFloat = 18

    // Note v2 (Sprint 3)
    /// 음표 글로우 반지름(pt). 본체(noteSize/2=8) 위 골드 글로우.
    static let noteV2GlowRadius: CGFloat = 16
    /// 음표 글로우 알파.
    static let noteV2GlowAlpha: CGFloat = 0.5
    /// 음표 흰 링 두께(pt).
    static let noteV2RingLineWidth: CGFloat = 2
    /// 음표 펄스 1주기 지속(초). scaleUp + scaleDown 합.
    static let noteV2PulseDuration: TimeInterval = 1.4
    /// 음표 펄스 최대 scale.
    static let noteV2PulseScale: CGFloat = 1.08
    /// 음표 펄스 SKAction 키 — 멱등 부착.
    static let noteV2PulseActionKey: String = "noteV2Pulse"

    // Projectile v2 (Sprint 3)
    /// F 투사체 시각 자식 한 변(pt). PhysicsBody size(projectileSize=16)와 *분리*.
    static let projectileV2VisualSize: CGFloat = 22
    /// F 투사체 시각 자식 cornerRadius(pt).
    static let projectileV2CornerRadius: CGFloat = 6
    /// F 투사체 회전 각도(degree). 살짝 비스듬.
    static let projectileV2RotationDegrees: CGFloat = -12
    /// F 투사체 라벨 텍스트.
    static let projectileV2LabelText: String = "F"
    /// F 투사체 라벨 폰트 크기(pt).
    static let projectileV2LabelFontSize: CGFloat = 14

    // ComboPopup / ComboBreak v2 (Sprint 3)
    /// ComboPopup v2 라벨 폰트 크기(pt). 기존 comboPopupFontSize(48)와 분리 — *새 상수 추가*만.
    static let comboPopupV2FontSize: CGFloat = 32
    /// ComboBreak v2 라벨 폰트 크기(pt). 기존 comboBreakFontSize(48)와 분리.
    static let comboBreakV2FontSize: CGFloat = 28
    /// ComboPopup/ComboBreak navy 외곽선 1pt 오프셋 두께(pt). 4방향 자식 4개로 시뮬레이션.
    static let comboPopupV2OutlineWidth: CGFloat = 1
    /// ComboPopup v2 회전 각도(degree).
    static let comboPopupV2RotationDegrees: CGFloat = -8

    // Outer Wall Border (Sprint 3)
    /// 외곽 보더 SKShapeNode 외곽선 두께(pt).
    static let outerWallBorderLineWidth: CGFloat = 3
    /// 외곽 보더 SKShapeNode cornerRadius(pt).
    static let outerWallBorderCornerRadius: CGFloat = 18

    // MARK: - Sprint 5 · ResultScene v2 Layout
    // DESIGN_RENEWAL_REQUEST.md §4.5 + mockups/result-screen-v2.html.
    // Sprint 5는 *추가만* — Phase 8-4 resultPanel* 상수는 *유지*. v2 상수가 별도 이름으로 공존.

    /// 명조 폰트 — 졸업장 한·영 제목 + 본문 (GowunBatang-Regular).
    /// ttf 미존재 시 SKLabelNode가 시스템 폰트로 자동 fallback — 컴파일/런타임 모두 안전.
    static let fontSerif: String = "GowunBatang-Regular"

    // ResultScene v2 카드 패널
    /// 결과 카드 v2 cornerRadius(pt). mockup border-radius: 22.
    static let resultCardCornerRadiusV2: CGFloat = 22

    // ResultScene v2 라벨 오프셋
    /// AccentLine y 오프셋. frame.midY 기준.
    static let resultAccentLineOffsetYV2: CGFloat = 130
    /// 헤더 DarkContextChip y 오프셋.
    static let resultHeaderChipOffsetYV2: CGFloat = 100
    /// 타이틀("실습 종료" / "✨ NEW BEST! ✨") y 오프셋.
    static let resultTitleOffsetYV2: CGFloat = 70
    /// 타이틀 폰트 크기(pt). mockup .title-game-over = 30.
    static let resultTitleFontSizeV2: CGFloat = 30
    /// 부제 라벨 y 오프셋.
    static let resultSubtitleOffsetYV2: CGFloat = 44
    /// 부제 폰트 크기(pt). mockup .title-row .sub = 12.
    static let resultSubtitleFontSizeV2: CGFloat = 12
    /// 점수 라벨 y 오프셋.
    static let resultScoreOffsetYV2: CGFloat = -2
    /// 점수 숫자 폰트 크기(pt). mockup .score-num = 64.
    static let resultScoreNumFontSizeV2: CGFloat = 64
    /// 점수 부제("SCORE" / "NEW SCORE") y 오프셋.
    static let resultScoreSubOffsetYV2: CGFloat = -32
    /// BEST 칩 y 오프셋.
    static let resultBestOffsetYV2: CGFloat = -60
    /// BEST 칩 폰트 크기(pt). mockup .best-row = 13.
    static let resultBestFontSizeV2: CGFloat = 13
    /// divider y 오프셋.
    static let resultDividerOffsetYV2: CGFloat = -90
    /// divider 폭 비율(카드 폭 대비). mockup width: 60%.
    static let resultDividerWidthRatioV2: CGFloat = 0.6
    /// stat 값(PLAYS/TOTAL 숫자) 폰트 크기(pt). mockup .stat-num = 14.
    static let resultStatValueFontSizeV2: CGFloat = 14
    /// stat 타이틀("PLAYS"/"TOTAL") 폰트 크기(pt). mockup .stats-row = 11.
    static let resultStatTitleFontSizeV2: CGFloat = 11
    /// stat 값 y 오프셋.
    static let resultStatValueOffsetYV2: CGFloat = -110
    /// stat 타이틀 y 오프셋.
    static let resultStatTitleOffsetYV2: CGFloat = -124
    /// stat 두 그룹(PLAYS/TOTAL) 가로 간격(중앙 기준 ± offset, pt).
    static let resultStatGroupSpacingXV2: CGFloat = 50
    /// 버튼(공유 + 다시시작) y 오프셋.
    static let resultButtonOffsetYV2: CGFloat = -180
    /// 공유 GlassPill 폭(pt).
    static let resultShareButtonWidthV2: CGFloat = 100
    /// 공유 GlassPill 높이(pt).
    static let resultShareButtonHeightV2: CGFloat = 36
    /// 공유 GlassPill 중앙 기준 x 오프셋.
    static let resultShareButtonXOffsetV2: CGFloat = -70
    /// 다시시작 PrimaryButton 중앙 기준 x 오프셋.
    static let resultRestartButtonXOffsetV2: CGFloat = 80

    // ResultScene v2 sparkle 5발 좌표
    /// 신기록 시 카드 주변에 emit되는 SparkleEffectNode 5개의 (frame.midX, frame.midY) 기준 오프셋.
    /// mockup VARIANT B의 sparkle s1~s5 위치를 카드 중심 기준으로 환산.
    static let resultSparklePositionsV2: [CGPoint] = [
        CGPoint(x: -150, y:  60),
        CGPoint(x:  130, y:  40),
        CGPoint(x: -110, y: -40),
        CGPoint(x:  140, y: -60),
        CGPoint(x: -180, y:   0)
    ]

    // Diploma v2 (우드컷)
    /// 종이 카드 폭(pt). mockup .diploma width: 520.
    static let diplomaPaperWidthV2: CGFloat = 520
    /// 종이 카드 높이(pt).
    static let diplomaPaperHeightV2: CGFloat = 320
    /// 종이 카드 cornerRadius(pt).
    static let diplomaPaperCornerRadiusV2: CGFloat = 8
    /// 종이 카드 더블 보더 두께(pt). mockup border: 4px double.
    static let diplomaPaperBorderLineWidthV2: CGFloat = 4
    /// 종이 카드 회전 각도(degree). mockup transform: rotate(-2deg).
    static let diplomaPaperRotationDegreesV2: CGFloat = -2
    /// 우드컷 도트 격자 간격(pt). 12pt 간격 = 약 1100개 도트 누적.
    static let diplomaDotStepV2: CGFloat = 12
    /// 우드컷 도트 반지름(pt).
    static let diplomaDotRadiusV2: CGFloat = 1.0
    /// 우드컷 도트 색 alpha. mockup repeating-linear-gradient 톤 모사.
    static let diplomaDotAlphaV2: CGFloat = 0.4
    /// 우드컷 도트 색 hex. mockup #FFEDC6 (종이 농염).
    static let diplomaDotHexV2: String = "#FFEDC6"
    /// 코너 데코 ㄱ자 한 변 길이(pt). mockup ::before/::after width: 30.
    static let diplomaCornerDecoSizeV2: CGFloat = 30
    /// 코너 데코 종이 가장자리로부터 안쪽 inset(pt). mockup top/left: 6.
    static let diplomaCornerDecoInsetV2: CGFloat = 6
    /// 코너 데코 strokeColor 두께(pt). mockup border: 3px double.
    static let diplomaCornerDecoLineWidthV2: CGFloat = 3
    /// 도장 원 반지름(pt). mockup .diploma-stamp width/height 56 → r=28.
    static let diplomaStampRadiusV2: CGFloat = 28
    /// 도장 strokeColor 두께(pt). mockup border: 2px.
    static let diplomaStampLineWidthV2: CGFloat = 2
    /// 도장 회전 각도(degree). mockup transform: rotate(-12deg).
    static let diplomaStampRotationDegreesV2: CGFloat = -12
    /// 도장 라벨 텍스트.
    static let diplomaStampLabelText: String = "김간호\n음악대학"
    /// 도장 라벨 폰트 크기(pt). mockup font-size: 9.
    static let diplomaStampLabelFontSizeV2: CGFloat = 9
    /// 도장 fill 반투명 alpha. mockup background: rgba(255,232,232,0.4).
    static let diplomaStampFillAlphaV2: CGFloat = 0.4
    /// 도장 종이 카드 우하단 x 오프셋(pt). 종이 중심 기준 + 거리.
    static let diplomaStampOffsetXV2: CGFloat = 180
    /// 도장 종이 카드 우하단 y 오프셋(pt). 종이 중심 기준 - 거리.
    static let diplomaStampOffsetYV2: CGFloat = -100
    /// 종이 카드 zPosition(노드 좌표계 내부). background(0) 위 + 도트 패턴(0.7) 아래.
    static let diplomaPaperZPositionV2: CGFloat = 0.5
    /// 도트 패턴 zPosition. paperCard(0.5) 위 + 라벨(1) 아래.
    static let diplomaDotsZPositionV2: CGFloat = 0.7
    /// 코너 데코 zPosition. 도트 패턴(0.7) 위 + 라벨(1) 아래.
    static let diplomaCornerDecoZPositionV2: CGFloat = 0.8
    /// 도장 zPosition. 라벨(1) 위.
    static let diplomaStampZPositionV2: CGFloat = 1.2

    // MARK: - Sprint 6 · 흐름 재편 + 캐릭터 얼굴 + 메인 캐릭터
    // SPRINT_6_REQUEST.md §2~3 + SPEC.md "기능 상세" 1~7.
    // 본 섹션은 *추가만* — 기존 상수 hex/값 0건 변경 (characterSelectBackPillText 1줄만 위에서 값 교체).
    // 흐름: Start → Character → (Skill) → Difficulty → Game. .kim은 Skill 스킵.

    // MARK: NurseAvatarNode (StartScene 좌측 김간호 큰 그림)
    /// 김간호 큰 그림 전체 scale. mockup viewBox(-150 -160 300 360) 기준 width 240px 정도.
    /// 본 노드 내부 좌표는 SVG에서 그대로 코드화 → 외부에서 xScale/yScale로 최종 크기 미세 조정.
    static let nurseAvatarScale: CGFloat = 0.7
    /// StartScene에서 NurseAvatarNode 좌측 6% 위치 — frame.minX 기준 +offset.
    static let nurseAvatarOffsetX: CGFloat = 180
    /// StartScene에서 NurseAvatarNode 바닥 정렬 — frame.midY 기준 +offset(음수: 아래로).
    static let nurseAvatarOffsetY: CGFloat = -40
    /// zPosition — 배경(-20/-15)·타이틀(0~5)·시작버튼(100) 사이의 8 — 시작버튼과 음표보다 아래.
    static let nurseAvatarZPosition: CGFloat = 8
    /// 외곽선(stroke) 라인 두께. SVG `stroke-width="4"`를 그대로 옮긴 값.
    static let nurseAvatarOutlineWidth: CGFloat = 4
    /// 헤드폰 밴드 라인 두께. SVG `stroke-width="10"`.
    static let nurseAvatarHeadphoneBandWidth: CGFloat = 10
    /// 팔 라인 두께(피부톤). SVG `stroke-width="20"`.
    static let nurseAvatarArmWidth: CGFloat = 20

    // MARK: CharacterFaceNode (CharacterSelectScene 5장 카드 위 얼굴)
    /// 카드 안에서 얼굴 차지 비율 — Sprint 7+ — 0.55 → 0.82 (카드 확대에 동기).
    /// 카드(76×104)와 글래스(156×204) 확대에 맞춰 얼굴도 키워 시인성 강화.
    static let characterFaceScale: CGFloat = 0.82
    /// 카드 중심에서 얼굴 y 오프셋 — 라벨(이름·태그)과 겹치지 않도록 +6~+10. (OPEN_QUESTION OQ-1)
    static let characterFaceOffsetYWithinCard: CGFloat = 8
    /// 5장 카드 위 얼굴 노드의 zPosition. 글래스 컨테이너(90) < 카드(100) < CharacterFaceNode(105) < 색 점/태그(110).
    static let characterFaceZPosition: CGFloat = 105
    /// 얼굴 베이스 머리 타원 가로 반지름.
    static let characterFaceHeadRadiusX: CGFloat = 32
    /// 얼굴 베이스 머리 타원 세로 반지름.
    static let characterFaceHeadRadiusY: CGFloat = 34
    /// 얼굴 외곽선 두께. mockup `stroke-width="2.5"`.
    static let characterFaceOutlineWidth: CGFloat = 2.5
    /// 얼굴 부속(눈/입/볼) stroke 두께. mockup `stroke-width="2"~"3"` 평균.
    static let characterFaceDetailLineWidth: CGFloat = 2.5

    // MARK: DifficultySelectScene (신규 5단계 흐름 마지막)
    /// 헤더 텍스트.
    static let difficultySelectHeaderText: String = "난이도를 골라요"
    /// 헤더 폰트 크기(pt). characterSelect/skillExplanation 헤더(22)와 동급 톤.
    static let difficultySelectHeaderFontSize: CGFloat = 26
    /// 헤더 y offset — frame.midY 기준.
    static let difficultySelectHeaderOffsetY: CGFloat = 140
    /// 헤더 부제 텍스트.
    static let difficultySelectHeaderSubText: String = "한 번만 정해두면 충분해요"
    /// 헤더 부제 폰트 크기(pt).
    static let difficultySelectHeaderSubFontSize: CGFloat = 12
    /// 헤더 부제 y offset — 헤더 라벨 기준.
    static let difficultySelectHeaderSubOffsetY: CGFloat = -22
    /// 헤더 위 AccentLine y offset.
    static let difficultySelectAccentLineOffsetY: CGFloat = 24

    // 백버튼 (스킬 다시 또는 캐릭터 다시 — characterID에 따라 분기)
    /// 스킬 보유 캐릭터(.jung/.geon/.im/.lee) 백버튼 텍스트.
    static let difficultySelectBackPillTextSkill: String = "← 스킬 다시"
    /// 김간호(.kim) 백버튼 텍스트 — 스킬 화면을 스킵했으므로 직전이 캐릭터 선택.
    static let difficultySelectBackPillTextCharacter: String = "← 캐릭터 다시"
    /// 백 GlassPill 폭.
    static let difficultySelectBackPillWidth: CGFloat = 130
    /// 백 GlassPill 높이.
    static let difficultySelectBackPillHeight: CGFloat = 28

    // 브레드크럼 칩
    /// 브레드크럼 칩 라벨 — 캐릭터 · 스킬 + [난이도] 뱃지.
    /// 김간호는 스킬 화면을 스킵했지만 시각 일관성을 위해 라벨 텍스트 그대로 유지.
    static let difficultySelectBreadcrumbLabel: String = "캐릭터 · 스킬"
    /// 브레드크럼 칩 뱃지 — 코랄 뱃지에 표시되는 "현재 위치".
    static let difficultySelectBreadcrumbBadge: String = "난이도"

    // 상단 바 margin
    static let difficultySelectTopBarMarginX: CGFloat = 40
    static let difficultySelectTopBarMarginY: CGFloat = 30

    // 좌측 캐릭터 요약 카드
    /// 좌측 요약 카드 폭(pt).
    static let difficultySelectSummaryCardWidth: CGFloat = 200
    /// 좌측 요약 카드 높이(pt).
    static let difficultySelectSummaryCardHeight: CGFloat = 260
    /// 좌측 요약 카드 cornerRadius(pt).
    static let difficultySelectSummaryCardCornerRadius: CGFloat = 22
    /// 좌측 요약 카드 배경 fill alpha(흰색).
    static let difficultySelectSummaryCardFillAlpha: CGFloat = 0.85
    /// 좌측 요약 카드 stroke alpha(코랄).
    static let difficultySelectSummaryCardStrokeAlpha: CGFloat = 0.3
    /// 좌측 요약 카드 stroke 두께.
    static let difficultySelectSummaryCardStrokeWidth: CGFloat = 2
    /// 좌측 요약 카드 x 위치 offset(frame.midX 기준 음수 → 좌측).
    static let difficultySelectSummaryCardOffsetX: CGFloat = -220
    /// 좌측 요약 카드 y 위치 offset(frame.midY 기준).
    static let difficultySelectSummaryCardOffsetY: CGFloat = -10

    /// 요약 카드 안 이름 뱃지 폭(pt).
    static let difficultySelectSummaryNameBadgeWidth: CGFloat = 90
    /// 요약 카드 안 이름 뱃지 높이(pt).
    static let difficultySelectSummaryNameBadgeHeight: CGFloat = 24
    /// 요약 카드 안 이름 뱃지 폰트 크기(pt).
    static let difficultySelectSummaryNameBadgeFontSize: CGFloat = 12
    /// 요약 카드 중심에서 이름 뱃지 y offset(상단으로 +).
    static let difficultySelectSummaryNameBadgeOffsetY: CGFloat = 110
    /// 요약 카드 안 미니 아바타(CharacterFaceNode) scale.
    static let difficultySelectSummaryFaceScale: CGFloat = 0.65
    /// 요약 카드 중심에서 미니 아바타 y offset.
    static let difficultySelectSummaryFaceOffsetY: CGFloat = 30
    /// 요약 카드 안 스킬명 라벨 폰트 크기(pt).
    static let difficultySelectSummarySkillFontSize: CGFloat = 14
    /// 요약 카드 중심에서 스킬명 라벨 y offset(하단으로 -).
    static let difficultySelectSummarySkillOffsetY: CGFloat = -50
    /// 요약 카드 "스킬 없음" 라벨(김간호용).
    static let difficultySelectSummarySkillNoneText: String = "스킬 없음"
    /// 요약 카드 안 속도 칩 폭(pt).
    static let difficultySelectSummarySpeedChipWidth: CGFloat = 100
    /// 요약 카드 안 속도 칩 높이(pt).
    static let difficultySelectSummarySpeedChipHeight: CGFloat = 22
    /// 요약 카드 안 속도 칩 폰트 크기(pt).
    static let difficultySelectSummarySpeedChipFontSize: CGFloat = 11
    /// 요약 카드 안 속도 칩 fill alpha(민트 톤).
    static let difficultySelectSummarySpeedChipFillAlpha: CGFloat = 0.4
    /// 요약 카드 중심에서 속도 칩 y offset.
    static let difficultySelectSummarySpeedChipOffsetY: CGFloat = -80

    // 우측 난이도 3장
    /// 우측 난이도 3장 그룹의 중심 x offset(frame.midX 기준).
    static let difficultySelectDifficultyRowOffsetX: CGFloat = 110
    /// 우측 난이도 3장 그룹의 중심 y offset(frame.midY 기준).
    static let difficultySelectDifficultyRowOffsetY: CGFloat = -10

    // 시작 버튼
    /// 시작 버튼 y offset(frame.midY 기준, 음수 → 아래).
    static let difficultySelectStartButtonOffsetY: CGFloat = -160
    /// 시작 버튼 텍스트.
    static let difficultySelectStartButtonText: String = "시작"

    // MARK: - Sprint 7 · 잘림 해소 + 카드 시인성 강화 (Visual-3)
    //
    // SafeArea 마운트(GameViewController)로 4개 메뉴 씬 가장자리 잘림 해소 +
    // DifficultyCardNode 1.4배 확장 + descriptionLabel 추가 + 미선택 시각 강화 +
    // CharacterSelectScene 카드 여백 확대 + 지그재그 y 오프셋.
    //
    // 모든 신규 상수는 `*V3` 접미사. 기존 상수는 값 변경 없음(다른 사용처 회귀 방지).

    // --- DifficultyCardNode v3 ---
    /// Sprint 7 — v3 카드 폭(112pt). 기존 difficultyCardWidth(80) 대비 1.4배.
    static let difficultyCardWidthV3: CGFloat = 112
    /// Sprint 7 — v3 카드 높이(82pt). 3행 라벨(name + subtitle + description) 수용.
    static let difficultyCardHeightV3: CGFloat = 82
    /// Sprint 7 — v3 카드 코너 반경(20pt). 캡슐 → 둥근 사각형 톤. height/2(41)보다 작아 카드 인상.
    static let difficultyCardCornerRadiusV3: CGFloat = 20
    /// Sprint 7 — v3 카드 spacing(22pt). 기존 16 대비 +6.
    static let difficultyCardSpacingV3: CGFloat = 22
    /// Sprint 7 — v3 카드 stroke 두께(1.5pt).
    static let difficultyCardStrokeLineWidthV3: CGFloat = 1.5

    /// Sprint 7 — v3 미선택 카드 알파(0.78). 기존 characterCardDeselectedAlpha(0.5) 대비 +0.28
    /// — 흐림 해소 핵심 수치.
    static let difficultyCardDeselectedAlphaV3: CGFloat = 0.78
    /// Sprint 7 — v3 미선택 fill alpha — id.color × 0.08. 살짝 깔리는 톤.
    static let difficultyCardDeselectedFillAlphaV3: CGFloat = 0.08
    /// Sprint 7 — v3 미선택 stroke alpha — id.color × 0.4. 미선택도 색 대비 명확.
    static let difficultyCardDeselectedStrokeAlphaV3: CGFloat = 0.4
    /// Sprint 7 — v3 선택 fill alpha — id.color × 0.2. 기존 Phase 8-3 값 유지.
    static let difficultyCardSelectedFillAlphaV3: CGFloat = 0.2

    /// Sprint 7 — v3 nameLabel 폰트 크기(22pt). 기존 20 대비 +2.
    static let difficultyCardNameFontSizeV3: CGFloat = 22
    /// Sprint 7 — v3 subtitleLabel 폰트 크기(12pt). 기존 10 대비 +2.
    static let difficultyCardSubtitleFontSizeV3: CGFloat = 12
    /// Sprint 7 — v3 descriptionLabel 폰트 크기(10pt). 한 줄 풀이.
    static let difficultyCardDescriptionFontSizeV3: CGFloat = 10
    /// Sprint 7 — v3 description 라벨 최대 폭(카드 폭 - 좌우 16pt 패딩 = 96pt).
    /// numberOfLines = 0 + preferredMaxLayoutWidth에 사용.
    static let difficultyCardDescriptionMaxWidthV3: CGFloat = 96

    /// Sprint 7 — v3 nameLabel y offset (+24 — 카드 상단).
    static let difficultyCardNameOffsetYV3: CGFloat = 24
    /// Sprint 7 — v3 subtitleLabel y offset (+4 — 카드 중간 살짝 위).
    static let difficultyCardSubtitleOffsetYV3: CGFloat = 4
    /// Sprint 7 — v3 descriptionLabel y offset (-20 — 카드 하단).
    static let difficultyCardDescriptionOffsetYV3: CGFloat = -20

    // --- DifficultySelectScene v3 ---
    /// Sprint 7 — v3 좌측 summary 카드 offsetX(-260). 기존 -220 대비 -40 좌측 추가 이동
    /// — 우측 3장 카드가 112×3+22×2=380pt로 커지면서 시각 균형 보정.
    static let difficultySelectSummaryCardOffsetXV3: CGFloat = -260

    // --- CharacterSelectScene v3 ---
    /// Sprint 7 — v3 캐릭터 카드 간 spacing(22pt). 기존 characterCardSpacing(10) 대비 +12
    /// — 흩어진 인상. 카드 cardBaseX 계산에만 사용.
    static let characterSelectCardSpacingV3: CGFloat = 22
    /// Sprint 7 — v3 카드별 y 미세 오프셋 절대값. Sprint 7+ — 8 → 6 (카드 확대로 절댓값은 줄임).
    /// 지그재그 패턴 — 홀수 인덱스(0/2/4)는 +6, 짝수 인덱스(1/3)는 -6 식으로 호출부에서 부호 결정.
    static let characterSelectCardZigzagOffsetV3: CGFloat = 6

    // MARK: - Adaptive Layout (Sprint 7+ · 디바이스 대응 · iPhone SE ~ Pro Max)
    /// 화면 하단 안전 마진 — safeArea.bottom 위에 추가로 띄울 여백.
    /// SceneSafeArea.insets(for:).bottom + adaptiveBottomMargin = 노드 y 최소값.
    static let adaptiveBottomMargin: CGFloat = 24
    /// 화면 상단 안전 마진 — safeArea.top 아래에 추가로 띄울 여백.
    static let adaptiveTopMargin: CGFloat = 16
    /// 화면 좌우 안전 마진(노치/Dynamic Island 영역 회피).
    /// Landscape에서 노치가 한쪽(또는 양쪽)을 침범 — 카드 spacing 계산의 입력값.
    static let adaptiveHorizontalMargin: CGFloat = 20
    /// StartScene 시작 버튼 — 화면 하단(safeArea.bottom) 기준 안쪽 거리.
    /// frame.minY + safe.bottom + startButtonBottomInset = startButton.y.
    static let startButtonBottomInset: CGFloat = 64
    /// ResultScene 두 버튼(공유/다시시작) — 화면 하단(safeArea.bottom) 기준 안쪽 거리.
    /// frame.minY + safe.bottom + resultButtonBottomInset = button.y.
    static let resultButtonBottomInset: CGFloat = 56
    /// CharacterSelect 카드 spacing 최소값(28pt) — 가장 좁은 디바이스(iPhone SE) 보장.
    /// 카드 76 × 5장 + 28 × 4 spacing = 492pt — SE 가로(667pt safeArea 후) 안에 안전 수용.
    static let characterSelectMinCardSpacing: CGFloat = 28
    /// CharacterSelect 카드 spacing 최대값(56pt) — Pro Max에서 과도하게 벌어지지 않도록 clamp.
    /// 카드 76 × 5장 + 56 × 4 spacing = 604pt — Pro Max 가로(900+pt)에서 자연 균형.
    static let characterSelectMaxCardSpacing: CGFloat = 56
    /// CharacterSelect 확인 버튼 — adaptiveBottomMargin 위에 추가로 띄울 버튼 자체 높이 보정.
    /// PrimaryButton의 시각적 중앙을 카드 줄과 충분히 분리하기 위한 미세 inset.
    static let characterSelectConfirmButtonBottomInset: CGFloat = 40
    /// CharacterSelect 스킬 정보 칩 — 확인 버튼 위쪽 상대 간격.
    static let characterSelectSkillInfoChipAbove: CGFloat = 36

    // MARK: - Sprint 7 Phase A · CharacterCard v3 (NIKKE 4:5)
    //
    // 카드 폭 160 / 높이 200 / cornerRadius 22 / gap 22 — NIKKE 식 세로 4:5 카드.
    // 카드 내부에 5요소(속성 헥사·등급 배지·CD 미니칩·얼굴·이름+속도)를 위계 있게 배치.
    // 선택 상태는 v2 scale 1.08 + 코랄 stroke에 *하단 코랄 radial glow + 상단 "선택됨" 알약* 추가.
    //
    // 모든 신규 상수는 `*V3` 접미사 또는 v3 의도값. 기존 v2 상수(characterCardWidth 76,
    // characterCardHeight 104, characterCardGlassWidth 156, characterCardGlassHeight 204,
    // characterCardSelectedScale 1.08, characterCardScaleDuration 0.10)는 값 변경 0.

    /// v3 카드 폭(160pt). 기존 characterCardWidth(76) 대비 +84. 4:5 세로 비율 carrier.
    static let characterCardWidthV3: CGFloat = 160
    /// v3 카드 높이(200pt). 폭 160 × 1.25 = 200 → 4:5 비율.
    static let characterCardHeightV3: CGFloat = 200
    /// v3 카드 사이 gap(22pt). 기존 characterCardSpacing(10) 대비 +12. 겹침 0 보장.
    static let characterCardGapV3: CGFloat = 22
    /// v3 카드 cornerRadius(22pt). NIKKE 식 부드러운 둥금.
    static let characterCardCornerRadiusV3: CGFloat = 22

    // --- 속성 헥사 아이콘 (좌상단) ---
    /// 헥사 outer radius(원에 외접) — 14pt → 28pt 헥사 폭.
    static let characterCardElementHexRadius: CGFloat = 14
    /// 헥사 stroke(흰색 1.5pt) — 카드 배경(반투명 화이트)과 분리.
    static let characterCardElementHexStrokeWidth: CGFloat = 1.5
    /// 카드 좌상단 코너 inset (x, y) — 헥사 중심 좌표 계산에 사용.
    static let characterCardElementHexInsetX: CGFloat = 18
    static let characterCardElementHexInsetY: CGFloat = 18
    /// 헥사 안 이모지 폰트 크기(pt). 헥사 폭 28의 약 57% — 시각 균형.
    static let characterCardElementSymbolFontSize: CGFloat = 16

    // --- 등급 로마숫자 배지 (좌하단) ---
    /// 배지 크기(26×18pt) — Jua 11pt 한 자리 로마숫자 수용.
    static let characterCardRarityBadgeWidth: CGFloat = 26
    static let characterCardRarityBadgeHeight: CGFloat = 18
    /// 배지 cornerRadius(8pt) — 부드럽지만 사각.
    static let characterCardRarityBadgeCornerRadius: CGFloat = 8
    /// 배지 fill alpha — navyDeep × 0.85.
    static let characterCardRarityBadgeFillAlpha: CGFloat = 0.85
    /// 카드 좌하단 코너 inset (x, y) — 배지 중심 좌표.
    static let characterCardRarityBadgeInsetX: CGFloat = 22
    static let characterCardRarityBadgeInsetY: CGFloat = 22
    /// 배지 라벨 폰트 크기(pt).
    static let characterCardRarityBadgeFontSize: CGFloat = 11

    // --- CD 미니칩 (우상단) ---
    /// 칩 높이(16pt) — 자동 폭(라벨 너비 + padding).
    static let characterCardCDChipHeight: CGFloat = 16
    /// 칩 좌우 패딩(8pt).
    static let characterCardCDChipHorizontalPadding: CGFloat = 8
    /// 칩 fill — coralLight × 0.85.
    static let characterCardCDChipFillAlpha: CGFloat = 0.85
    /// 칩 라벨 폰트 크기(pt).
    static let characterCardCDChipFontSize: CGFloat = 9
    /// 카드 우상단 코너 inset (x, y).
    static let characterCardCDChipInsetX: CGFloat = 16
    static let characterCardCDChipInsetY: CGFloat = 18

    // --- 이름 + 속도 (하단) ---
    /// 이름 라벨 폰트 크기(pt). Jua, navyDeep.
    static let characterCardNameFontSizeV3: CGFloat = 15
    /// 이름 라벨 y offset (카드 하단 기준 + 28).
    static let characterCardNameOffsetYV3: CGFloat = 28
    /// 속도 칩 라벨 폰트 크기(pt). Gowun Dodum, scrubMint.
    static let characterCardSpeedFontSizeV3: CGFloat = 10
    /// 속도 칩 y offset (카드 하단 기준 + 12 — 이름 아래).
    static let characterCardSpeedOffsetYV3: CGFloat = 12

    // --- 선택 상태 강화 (Phase A) ---
    /// 카드 하단 코랄 radial glow 노드 폭(카드 폭 × 1.4 = 224pt).
    static let characterCardSelectedGlowWidth: CGFloat = 224
    /// 코랄 glow 높이(60pt).
    static let characterCardSelectedGlowHeight: CGFloat = 60
    /// 코랄 glow y offset (카드 하단 기준 -12 — 카드 아래로 살짝 새어 나옴).
    static let characterCardSelectedGlowOffsetY: CGFloat = -12
    /// 코랄 glow 알파(0.45).
    static let characterCardSelectedGlowAlpha: CGFloat = 0.45

    /// "선택됨" 알약 폭(60pt) / 높이(20pt). Jua 10pt 흰색 "선택됨" 수용.
    static let characterCardSelectedPillWidth: CGFloat = 60
    static let characterCardSelectedPillHeight: CGFloat = 20
    /// 알약 라벨 폰트 크기(pt).
    static let characterCardSelectedPillFontSize: CGFloat = 10
    /// 알약 텍스트.
    static let characterCardSelectedPillText: String = "선택됨"
    /// 알약 y offset (카드 상단 기준 +14 — 카드 위로 솟음).
    static let characterCardSelectedPillOffsetY: CGFloat = 14

    // --- 스킬 패널 폭 축소 (Phase A) ---
    /// 하단 스킬 정보 칩 최대 폭(320pt). v2 무한 → v3 320 clamp.
    /// 5장 카드 총 폭(160×5 + 22×4 = 888pt)과 시각적 분리.
    static let characterSelectSkillInfoMaxWidth: CGFloat = 320

    // MARK: - Sprint 7 Phase B · Skill Explanation v3 (겹침 해소 + 호흡)
    // SPRINT_7_REQUEST.md §3.2 — 본문 폭 47%→52%, 인용 보더 3px→4px,
    // 메타칩 gap 8→10, 버튼 gap 12→18. 기존 v2 상수는 값 유지(회귀 0).

    /// 우측 본문(인용 박스) 가로폭(pt) — v2 300pt(≈47%) → v3 332pt(≈52%).
    static let skillExplanationQuoteBoxWidthV3: CGFloat = 332

    /// 콘텐츠 영역 비율 (참조용) — 우측 본문 폭 계산 근거.
    static let skillExplanationContentWidthRatioV3: CGFloat = 0.52

    /// 인용 박스 좌측 코랄 보더 굵기(pt) — v2 3 → v3 4.
    static let skillExplanationQuoteBoxBorderWidthV3: CGFloat = 4

    /// 메타 칩 3개(CD/범위/발동) 사이 간격(pt) — v2 8 → v3 10.
    static let skillExplanationStatChipSpacingV3: CGFloat = 10

    /// 하단 백·시작 버튼 사이 간격(pt) — v2 12 → v3 18.
    /// Phase B에서 백 버튼이 화면에서 제거되므로 실제 사용 빈도는 낮으나
    /// 향후 정책 변경 시 참조용으로 보존.
    static let skillExplanationBottomButtonGapV3: CGFloat = 18

    // MARK: - Sprint 7 Phase C · Difficulty hierarchy v3
    //
    // 난이도 3장 카드에 *색 위계*를 부여하고 선택 카드를 시선 자석으로 만든다.
    // 카드 헤더 22pt → 30pt + 카드별 stroke 외곽선 / 선택 시 +8pt 상승 + radial glow /
    // 시작 버튼 뒤 halo SKShape 부착.
    //
    // 모든 신규 상수는 `*PhaseC` 또는 명시적 의도값 접미사. 기존 V3 상수
    // (difficultyCardDeselectedAlphaV3, DeselectedFillAlphaV3, DeselectedStrokeAlphaV3,
    // SelectedFillAlphaV3, StrokeLineWidthV3, NameFontSizeV3 등)는 값 변경 0.

    /// Phase C — 카드 헤더(이름 라벨) 폰트 크기(30pt). 기존 V3 22pt → +8.
    /// nameLabelStroke / nameLabel 2개 라벨로 stroke 외곽선 표현.
    static let difficultyCardNameFontSizePhaseC: CGFloat = 30
    /// Phase C — 카드 헤더 stroke 굵기(1pt). nameLabelStroke 폰트 = 30 + 1×2 = 32pt
    /// 베이스 라벨로 stroke 효과 근사. SKLabelNode는 stroke 직접 미지원.
    static let difficultyCardNameStrokeWidthPhaseC: CGFloat = 1.0

    /// Phase C — 선택 카드 상승 거리(+8pt). mockup `transform: translateY(-8px)` 대응.
    /// 미세 상승 — *시선 자석* 효과의 핵심 수치. liftCurrentOffset 증분 추적으로 누적 방지.
    static let difficultyCardSelectedLiftY: CGFloat = 8
    /// Phase C — 선택 카드 상승 액션 지속 시간(0.18s). spring overshoot phase1과 동일 톤.
    static let difficultyCardSelectedLiftDuration: TimeInterval = 0.18

    /// Phase C — 선택 카드 뒤 radial glow 폭(158pt). 카드 폭 112 대비 ×1.41.
    /// mockup .diff-card::before 158 × 116.
    static let difficultyCardSelectedGlowWidthPhaseC: CGFloat = 158
    /// Phase C — 선택 카드 뒤 radial glow 높이(116pt). 카드 높이 82 대비 ×1.41.
    static let difficultyCardSelectedGlowHeightPhaseC: CGFloat = 116
    /// Phase C — 선택 카드 뒤 radial glow alpha(0.80). 시선 자석 강도.
    static let difficultyCardSelectedGlowAlphaPhaseC: CGFloat = 0.80
    /// Phase C — 선택 카드 뒤 radial glow spread(12pt). SKShapeNode.glowWidth로 근사 —
    /// 진정한 Gaussian blur는 SpriteKit 미지원, mockup `filter: blur(20px)` 근사 보정.
    static let difficultyCardSelectedGlowSpreadPhaseC: CGFloat = 12

    /// Phase C — 시작 버튼 뒤 halo 폭(240pt). PrimaryButton 폭 대비 +여백.
    static let difficultySelectStartButtonHaloWidth: CGFloat = 240
    /// Phase C — 시작 버튼 뒤 halo 높이(90pt).
    static let difficultySelectStartButtonHaloHeight: CGFloat = 90
    /// Phase C — 시작 버튼 halo 알파(0.35). mockup `box-shadow … rgba(255,107,91,0.35)` 톤.
    static let difficultySelectStartButtonHaloAlpha: CGFloat = 0.35
    /// Phase C — 시작 버튼 halo spread(24pt). glowWidth 근사 — mockup `filter: blur(24px)`.
    static let difficultySelectStartButtonHaloSpread: CGFloat = 24
    /// Phase C — 시작 버튼 halo 페이드 인 지속 시간(0.25s). 화면 진입 후 자연스러운 등장.
    static let difficultySelectStartButtonHaloFadeInDuration: TimeInterval = 0.25
    /// Phase C — 시작 버튼 halo y offset (0pt — 버튼 정중앙 뒤). 별도 보정 필요 시 사용.
    static let difficultySelectStartButtonHaloOffsetY: CGFloat = 0

    // MARK: - Sprint 7 Phase D · ResultScene v3 + ScoreboardScene
    //
    // 결과창 시각 정보 5요소(♪·점수·SCORE 라벨·BEST 칩·캐릭터/난이도)가 같은 좌표 근처에
    // 몰리던 V2 문제를 해소. V3는 점수가 시각 주인공이 되도록 ♪를 24pt로 줄이고,
    // SCORE 라벨을 점수 아래로, BEST를 점수 우측 GlassPill로 분리하며, headerChip은
    // 타이틀 위로 끌어올린다. "📊 기록 보기" GlassPill 신규로 ScoreboardScene 진입.
    //
    // V2 상수는 *모두 보존* — bestLabel/scoreSubLabel/divider/playsValueLabel 등 노드 트리는
    // alpha=0 차단으로 살아 있고, 좌표 시프트만 V3 상수로 한다.

    // ResultScene V3 — 점수 좌측 ♪ 아이콘 (scoreLabel과 분리)
    /// scoreLabel("♪ 0")의 ♪를 제거 → 좌측 별도 라벨 24pt 부착. 점수가 시각 주인공.
    static let resultScoreNoteIconFontSizeV3: CGFloat = 24
    /// scoreLabel.position.x 기준 ♪ 라벨 x 오프셋(좌측 -60). 점수 중심에서 살짝 좌측.
    static let resultScoreNoteIconOffsetXV3: CGFloat = -60
    /// ♪ 라벨 y는 scoreLabel.position.y와 동일. V3는 scoreLabel y(-2)에 정렬.
    static let resultScoreRowOffsetYV3: CGFloat = -2

    // ResultScene V3 — BEST GlassPill (bestLabel 시각 대체)
    /// BEST GlassPill 폭(120pt). "🏆 BEST 999" / "★ NEW BEST!" 두 텍스트 모두 수용.
    static let resultBestPillWidthV3: CGFloat = 120
    /// BEST GlassPill 높이(28pt). 점수 옆에 nestled.
    static let resultBestPillHeightV3: CGFloat = 28
    /// BEST GlassPill 중앙 x 오프셋(+120pt — scoreLabel 우측). frame.midX 기준.
    static let resultBestPillOffsetXV3: CGFloat = 120

    // ResultScene V3 — headerChip · title · subtitle · accentLine 위로 올림
    /// headerChip y 오프셋(+115pt — V2의 +100보다 위). 타이틀 위쪽으로 끌어올림.
    static let resultHeaderChipOffsetYV3: CGFloat = 115
    /// 타이틀 y 오프셋(+85pt — V2의 +70보다 위). headerChip이 위로 올라가니 따라 올라감.
    static let resultTitleOffsetYV3: CGFloat = 85
    /// 부제 y 오프셋(+58pt — V2의 +44보다 위). 타이틀과 함께 위로.
    static let resultSubtitleOffsetYV3: CGFloat = 58
    /// AccentLine y 오프셋(+148pt — V2의 +130보다 위). headerChip 위 강조.
    static let resultAccentLineOffsetYV3: CGFloat = 148

    // ResultScene V3 — SCORE 라벨 점수 아래로
    /// SCORE 부제 y 오프셋(-44pt — V2의 -32보다 아래). 점수 라벨 아래로 떨어뜨림.
    static let resultScoreSubOffsetYV3: CGFloat = -44

    // ResultScene V3 — divider · stat 라벨 위로 끌어올림 (bestLabel V2 자리 채움)
    /// divider y 오프셋(-78pt — V2의 -90보다 위). bestLabel V2 자리(-60) 비워 위로.
    static let resultDividerOffsetYV3: CGFloat = -78
    /// stat 값(PLAYS/TOTAL 숫자) y 오프셋(-98pt — V2의 -110보다 위).
    static let resultStatValueOffsetYV3: CGFloat = -98
    /// stat 타이틀(PLAYS/TOTAL 텍스트) y 오프셋(-112pt — V2의 -124보다 위).
    static let resultStatTitleOffsetYV3: CGFloat = -112

    // ResultScene V3 — Scoreboard 진입 GlassPill ("📊 기록 보기")
    /// 기록 보기 GlassPill 폭(110pt). shareButton(100) + 미세 여유 — 본문 4글자.
    static let resultScoreboardButtonWidthV3: CGFloat = 110
    /// shareButton 중심 x 기준 좌측 오프셋(-110pt). 공유 칩 좌측에 배치.
    static let resultScoreboardButtonOffsetXFromShareV3: CGFloat = -110
    /// 기록 보기 GlassPill 텍스트. 이모지 + 한글 4자.
    static let resultScoreboardButtonText: String = "📊 기록 보기"

    // ResultScene V3 — BEST GlassPill 텍스트 분기
    /// 일반 분기 BEST 칩 텍스트 prefix("🏆 BEST"). 뒤에 ` \(bestScore)` 합성.
    static let resultBestPillTextNormalV3: String = "🏆 BEST"
    /// 신기록 분기 BEST 칩 텍스트("★ NEW BEST!"). 깜빡임은 기존 bestLabel(alpha=0)이 담당.
    static let resultBestPillTextNewV3: String = "★ NEW BEST!"

    // ScoreboardScene — 15셀 매트릭스 기본
    /// 매트릭스 가로 셀 수(3 = 하/중/상).
    static let scoreboardMatrixColumnCount: Int = 3
    /// 매트릭스 세로 셀 수(5 = 5 캐릭터).
    static let scoreboardMatrixRowCount: Int = 5
    /// 셀 폭(80pt). 3자리 숫자 + 미세 여유.
    static let scoreboardCellWidth: CGFloat = 80
    /// 셀 높이(36pt). Jua 18pt + 패딩.
    static let scoreboardCellHeight: CGFloat = 36
    /// 셀 사이 가로/세로 간격(4pt). mockup grid-gap.
    static let scoreboardCellGap: CGFloat = 4
    /// 행 헤더 폭(60pt). mini face(32px) + 약칭(1자).
    static let scoreboardRowHeaderWidth: CGFloat = 60
    /// 매트릭스 전체의 frame.midY 기준 y 오프셋(+10pt). 헤더 아래 자연 배치.
    static let scoreboardMatrixOffsetY: CGFloat = 10

    // ScoreboardScene — 미니 얼굴 (CharacterFaceNode.mini)
    /// 행 헤더 미니 얼굴 setScale 배율(0.47 ≈ 32/68 — CharacterFaceNode 기본 ~68 → ~32pt).
    static let scoreboardMiniFaceScale: CGFloat = 0.47

    // ScoreboardScene — 셀 라벨 폰트
    /// 셀 점수 폰트 크기(Jua 18pt navy).
    static let scoreboardCellScoreFontSize: CGFloat = 18
    /// 빈 셀 "—" 폰트 크기(Gowun Dodum 14pt 회색).
    static let scoreboardCellEmptyFontSize: CGFloat = 14
    /// 빈 셀 텍스트("—" em dash).
    static let scoreboardCellEmptyText: String = "—"
    /// 빈 셀 alpha(0.4 — 회색 톤).
    static let scoreboardCellEmptyAlpha: CGFloat = 0.4

    // ScoreboardScene — 헤더 라벨
    /// 열 헤더(하/중/상) 폰트 크기.
    static let scoreboardColumnHeaderFontSize: CGFloat = 15
    /// 행 헤더 약칭(1자) 폰트 크기.
    static let scoreboardRowHeaderShortNameFontSize: CGFloat = 13
    /// 행 헤더 약칭 x 오프셋(미니 얼굴 우측 +22pt).
    static let scoreboardRowHeaderShortNameOffsetX: CGFloat = 22

    // ScoreboardScene — ★ 마커
    /// ★ 텍스트.
    static let scoreboardStarMarkerText: String = "★"
    /// ★ 폰트 크기(12pt).
    static let scoreboardStarMarkerFontSize: CGFloat = 12
    /// ★ 셀 중심 기준 x 오프셋(+28pt — 셀 우상단).
    static let scoreboardStarMarkerOffsetX: CGFloat = 28
    /// ★ 셀 중심 기준 y 오프셋(+12pt — 셀 우상단).
    static let scoreboardStarMarkerOffsetY: CGFloat = 12

    // ScoreboardScene — 헤더 + stat + 백 버튼
    /// 타이틀 y 오프셋(+95pt — frame.midY 기준 위쪽).
    static let scoreboardTitleOffsetY: CGFloat = 95
    /// 타이틀 폰트 크기(Jua 30pt — 결과창 타이틀과 동급).
    static let scoreboardTitleFontSize: CGFloat = 30
    /// 부제 y 오프셋(+72pt).
    static let scoreboardSubtitleOffsetY: CGFloat = 72
    /// 부제 폰트 크기(Gowun Dodum 12pt).
    static let scoreboardSubtitleFontSize: CGFloat = 12
    /// 부제 텍스트.
    static let scoreboardSubtitleText: String = "캐릭터·난이도별 최고점수"
    /// 타이틀 텍스트.
    static let scoreboardTitleText: String = "기록 보기"
    /// AccentLine y 오프셋(+130pt — 타이틀 위쪽 강조).
    static let scoreboardAccentLineOffsetY: CGFloat = 130

    /// 백 버튼 GlassPill 폭(110pt).
    static let scoreboardBackButtonWidth: CGFloat = 110
    /// 백 버튼 GlassPill 높이(36pt).
    static let scoreboardBackButtonHeight: CGFloat = 36
    /// 백 버튼 텍스트("← 결과로").
    static let scoreboardBackButtonText: String = "← 결과로"
    /// 백 버튼 좌측 inset(safeArea 추가 +20pt).
    static let scoreboardBackButtonInsetX: CGFloat = 20
    /// 백 버튼 상단 inset(safeArea 추가 +32pt — 화면 상단에서 떨어뜨림).
    static let scoreboardBackButtonInsetY: CGFloat = 32

    /// 브레드크럼 DarkContextChip 우측 inset.
    static let scoreboardBreadcrumbInsetX: CGFloat = 20
    /// 브레드크럼 상단 inset.
    static let scoreboardBreadcrumbInsetY: CGFloat = 32
    /// 브레드크럼 라벨 텍스트.
    static let scoreboardBreadcrumbText: String = "캐릭터별 기록"

    /// stat 라벨 frame.midY 기준 y 오프셋(-150pt — 매트릭스 아래).
    static let scoreboardStatOffsetY: CGFloat = -150
    /// stat 라벨 폰트 크기(Gowun Dodum 12pt).
    static let scoreboardStatFontSize: CGFloat = 12

    // MARK: - Sprint 8 — Layout V4 (겹침 해소 + 카드 확대)
    //
    // Phase A — Scoreboard zone 분리(타이틀 zone / 매트릭스 zone / stat zone).
    // V3 상수(~40개)는 byte-identical 보존. V4 상수는 *덧셈/교체* 형태로만 사용.

    // Phase A — Scoreboard
    /// 타이틀 zone을 매트릭스 zone과 분리하기 위한 추가 상향 오프셋(+40pt).
    /// 타이틀·부제 y 좌표에 더해, 우상단 GlassPill·매트릭스 첫 행과의 0px 겹침 보장.
    static let scoreboardTitleYOffsetV4: CGFloat = 40

    /// 열 헤더(하/중/상) ↔ 매트릭스 첫 데이터 행 사이 추가 gap(18pt).
    /// V3의 scoreboardCellGap(4pt)이 너무 좁아 헤더와 본문이 한 덩어리로 보이던 문제 해소.
    static let scoreboardHeaderRowGapV4: CGFloat = 18

    /// 데이터 행 사이 vertical pitch(38pt). 행 사이 호흡 확보.
    /// V3의 (cellHeight 36 + cellGap 4) = 40pt 대비 -2pt — 행 간격을 조금 좁혀 매트릭스 총 높이 감소.
    static let scoreboardCellPitchYV4: CGFloat = 38

    /// 매트릭스 bottom ↔ stat 라벨 사이 최소 gap(24pt).
    /// "총 플레이 N회 · 졸업장 N장 보유" 라벨이 별도 정보 layer로 인식되도록 분리.
    static let scoreboardStatBottomGapV4: CGFloat = 24

    /// 열 헤더(하/중/상) 폰트 크기 V4(16pt). V3(15pt)에서 1pt 상향.
    /// 매트릭스 zone 헤더 시각 무게를 데이터 셀(18pt)과 균형화. cellWidth(80) 안에 안전.
    static let scoreboardColumnHeaderFontSizeV4: CGFloat = 16

    // MARK: - Sprint 8 Phase B · Character Select 스와이프 페이지 V4
    //
    // 5장 카드 동시 노출(폭 912pt > 화면 844pt) → 중앙 1장 + 양옆 반쯤 보이는 2장으로 전환.
    // V3 카드 폭(160) / 높이(200) / cornerRadius(22) 등 시각 토큰은 byte-identical 보존.
    // 본 V4 상수는 *위치/scale/alpha 산출식*에만 사용.

    /// 중앙(center) 카드 scale — Phase 7-A characterCardSelectedScale(1.08)와 동일 톤.
    static let characterSwipeCardScaleCenterV4: CGFloat = 1.08
    /// 양옆(side, ±1) 카드 scale — 시선 분산 차단용 축소.
    static let characterSwipeCardScaleSideV4: CGFloat = 0.85
    /// 양옆 카드 alpha — 반쯤 보이는 시각.
    static let characterSwipeCardAlphaSideV4: CGFloat = 0.55
    /// 인접 카드 사이 x 간격(180pt) — center↔side 거리. 양옆 카드 절반이 화면 안에 들어오도록.
    static let characterSwipeOffsetXV4: CGFloat = 180
    /// 스와이프 트랜지션 SKAction 지속 시간(0.22s) — 부드럽지만 즉각.
    static let characterSwipeAnimationDurationV4: TimeInterval = 0.22
    /// 헤더 영역 하단 Y bound (scene.height 비율) — 헤더는 이 비율 *위*에만 존재.
    static let characterHeaderBottomYBoundV4: CGFloat = 0.80
    /// 중앙 카드 Y 중심 (scene.height 비율). 헤더와 40pt safe gap 보장.
    static let characterCardCenterYV4: CGFloat = 0.50

    // MARK: - Sprint 8 Phase C · Skill Explanation 힌트↔버튼 분리 V4
    //
    // Sprint 7-B(`bottomButtonGapV3=18`) 시각 gap이 실측 좁음 — controlHint container와
    // PrimaryButton "다음 ▶"이 거의 붙어 보여 두 요소가 한 덩어리로 인식되던 결함 해소.
    // V4는 controlHint container를 startButton top 위로 28pt 띄우고, container 내부
    // vertical padding을 6→8pt로 확장(height 32→36)해 두 요소 사이 명확한 호흡 확보.
    //
    // V3 상수(skillExplanationControlHintContainerOffsetY=-120,
    //         skillExplanationControlHintContainerHeight=32,
    //         skillExplanationButtonRowOffsetY=-160,
    //         skillExplanationBottomButtonGapV3=18) 모두 byte-identical 보존.
    // 적용 위치: SkillExplanationScene.setupControlHint(height) + layoutControlHint(containerY 동적 산출).
    //
    // 산술 검증 — primaryButtonHeight=48 → halfHeight=24.
    //   startButtonY  = frame.midY + skillExplanationButtonRowOffsetY            // midY - 160
    //   startButtonTop = startButtonY + 24                                       // midY - 136
    //   containerY    = startButtonTop + bottomButtonGapV4(28) + height/2(18)    // midY -  90
    //   containerBottom = containerY - 18                                        // midY - 108
    //   visual gap    = containerBottom - startButtonTop = (-108) - (-136) = 28pt ✅

    /// controlHint container bottom ↔ startButton top visual gap(28pt).
    /// V3 0pt(붙어 보임) → V4 28pt 분리. layoutControlHint() 안 containerY 산출에 사용.
    static let skillExplanationBottomButtonGapV4: CGFloat = 28

    /// controlHint container 내부 vertical padding(8pt). V3 6pt → V4 8pt(+2pt).
    /// 참조용 — 실제 적용은 container height(skillExplanationControlHintContainerHeightV4)로 표현.
    static let skillExplanationHintChipPaddingYV4: CGFloat = 8

    /// controlHint container 신규 height(36pt). V3 32pt + padding 4pt 확장 반영.
    /// setupControlHint() containerSize.height에 사용. V3 상수는 byte-identical 보존.
    static let skillExplanationControlHintContainerHeightV4: CGFloat = 36

    // MARK: - Sprint 8 Phase D · Difficulty Card V4
    //
    // V3 카드(112×82) 좁아 한글 텍스트 2~3줄 줄바꿈 답답 → V4 130×200 + line height 1.4.
    // V3 색 위계(EasyMint/MidGold/HardCoral)는 byte-identical 보존.
    // 적용 위치: DifficultyCardNode(카드 본체 size + 내부 layout) + DifficultySelectScene.layoutDifficultyCards
    // (width/spacing 교체). V3 상수(difficultyCardWidthV3=112, HeightV3=82, SpacingV3=22,
    //  SubtitleFontSizeV3=12, SubtitleOffsetYV3=4, StrokeLineWidthV3=1.5)는 byte-identical 보존 —
    // 사용처만 V4로 교체.

    /// Phase D 카드 폭(130pt). V3=112.
    static let difficultyCardWidthV4: CGFloat = 130
    /// Phase D 카드 높이(200pt). V3=82.
    static let difficultyCardHeightV4: CGFloat = 200
    /// Phase D 카드 사이 spacing(22pt). V3 SpacingV3와 동일 — V4 알리아스.
    static let difficultyCardGapV4: CGFloat = 22
    /// Phase D 카드 내부 top/bottom padding(14pt). V3는 명시 상수 없음(8pt 추정).
    static let difficultyCardPaddingV4: CGFloat = 14
    /// Phase D 부제 ↔ 보조 라벨 사이 vertical gap(10pt). V3=4pt(SubtitleOffsetYV3).
    static let difficultyCardSubtitleGapV4: CGFloat = 10
    /// Phase D 헤더(하/중/상) ↔ 부제 사이 gap(12pt). V3=6pt 추정.
    static let difficultyCardHeaderGapV4: CGFloat = 12
    /// Phase D 보조 라벨 line height multiplier(1.4). V3=1.15. attributedString paragraphStyle 사용.
    static let difficultyCardSubtitleLineHeightV4: CGFloat = 1.4
    /// Phase D 보조 라벨 fontSize(12pt). V3=12pt와 동일 — V4 알리아스(명시화).
    static let difficultyCardSubtitleFontSizeV4: CGFloat = 12

    // MARK: - Sprint 7 Phase F · Villain Visual V3
    //
    // 4종 빌런 시각 강화 V3 상수 묶음. **모든 좌표/크기는 부모 SKSpriteNode 중심(0,0) 기준**이며
    // zPosition은 부모 zPosition 5 기준의 *상대 오프셋*(0.1~0.4)이다.
    // 매직 넘버 0 원칙: setupVisualOverlay 함수 안에서는 본 상수만 참조.
    //
    // **Hitbox 보존 계약**: 본 상수는 *시각 자식 노드*에만 쓰인다.
    // physicsBody.size 인자는 기존 GameConfig.enemyWidth/Height 등을 그대로 사용 — *0줄 변경*.

    // ── EnemyNode (수간호사) — 외곽 헬로 + 차트 + 클립 ──────────────
    /// 외곽 헬로 SKShape 가로(22pt). 픽셀 텍스처(32×40) 살짝 안쪽의 부드러운 light bloom 표현.
    static let enemyVisualHaloWidth: CGFloat  = 22
    /// 외곽 헬로 SKShape 세로(28pt).
    static let enemyVisualHaloHeight: CGFloat = 28
    /// 외곽 헬로 alpha(0.18) — 픽셀 텍스처를 가리지 않는 *살짝 보이는* 정도.
    static let enemyVisualHaloAlpha: CGFloat  = 0.18
    /// 차트(클립보드) SKShape 크기 6×8pt — 픽셀 텍스처 옆구리에 작게 부착.
    static let enemyVisualChartSize = CGSize(width: 6, height: 8)
    /// 차트 위치 오프셋 — 우측 옆구리(x +10, y -2)에 작게 표시.
    static let enemyVisualChartOffset = CGPoint(x: 10, y: -2)

    // ── ProfessorNode (이교수) — 청진기 mini disc + 튜브 ──────────
    /// 청진기 mini disc 반지름(2.2pt). 좌측 옆구리에 작게 부착.
    /// **StethoscopeNode 투사체와 완전 무관 — 액세서리 시각만**.
    static let professorStethoIconRadius: CGFloat = 2.2
    /// 청진기 disc 위치 오프셋 — 좌측 옆구리(x -11, y -6).
    static let professorStethoIconOffset = CGPoint(x: -11, y: -6)
    /// 청진기 튜브 가로(1.2pt) — 얇은 코랄 선.
    static let professorStethoTubeWidth: CGFloat  = 1.2
    /// 청진기 튜브 세로(6pt) — disc 위로 짧게 올라감.
    static let professorStethoTubeHeight: CGFloat = 6

    // ── StoneGuardNode (석조무사) — 사각 갑옷 + 일자눈 ────────────
    /// 일자눈 좌우 대칭 x 오프셋(±4pt). attachEyes에서 leftEye = -x, rightEye = +x.
    static let stoneGuardEyeOffsetX: CGFloat = 4
    /// 일자눈 y 오프셋(+5pt) — 중심 약간 위쪽에 위치.
    static let stoneGuardEyeOffsetY: CGFloat = 5

    // ── SergeantParkNode (박병장) — 신규 빌런 시각 시안 ───────────
    /// 박병장 시각 크기 기본 가로(16pt). EnemyNode/PlayerNode 패턴 동형 — pixelSpriteScale로 2배 확대.
    static let sergeantParkWidth: CGFloat  = 16
    /// 박병장 시각 크기 기본 세로(20pt).
    static let sergeantParkHeight: CGFloat = 20

    /// 발 밑 ellipse 그림자 크기(18×4pt).
    static let sergeantShadowSize = CGSize(width: 18, height: 4)
    /// 그림자 y 오프셋(-18pt) — 발 밑.
    static let sergeantShadowOffsetY: CGFloat = -18

    /// 군복 몸통 사각형 크기(18×14pt).
    static let sergeantBodySize = CGSize(width: 18, height: 14)
    /// 군복 몸통 y 오프셋(-6pt) — 머리 아래.
    static let sergeantBodyOffsetY: CGFloat = -6

    /// 살구색 얼굴 반지름(6pt).
    static let sergeantHeadRadius: CGFloat   = 6
    /// 얼굴 y 오프셋(+6pt) — 몸통 위.
    static let sergeantHeadOffsetY: CGFloat  = 6

    /// 항공 캡 크라운(둥근 모자 윗부분) 크기(16×6pt).
    static let sergeantCapCrownSize = CGSize(width: 16, height: 6)
    /// 캡 크라운 y 오프셋(+13pt) — 머리 위.
    static let sergeantCapCrownOffsetY: CGFloat = 13
    /// 캡 차양(앞창) 크기(18×2pt).
    static let sergeantCapVisorSize = CGSize(width: 18, height: 2)
    /// 캡 차양 y 오프셋(+9pt) — 크라운 아래, 얼굴 위.
    static let sergeantCapVisorOffsetY: CGFloat = 9

    /// 선글라스 가로 직사각형 크기(11×3pt) — 눈 영역 전체 덮음.
    static let sergeantSunglassesSize = CGSize(width: 11, height: 3)
    /// 선글라스 y 오프셋(+5pt) — 얼굴 중심 약간 위.
    static let sergeantSunglassesOffsetY: CGFloat = 5

    /// 우측 어깨 v자 chevron 개수(2개 — 병장 계급장).
    static let sergeantRankChevronCount: Int = 2
    /// chevron x 오프셋(+6pt) — 우측 어깨.
    static let sergeantRankOffsetX: CGFloat  = 6
    /// chevron y 오프셋(-1pt) — 몸통 위쪽 어깨 위치.
    static let sergeantRankOffsetY: CGFloat  = -1
    /// chevron 사이 y 간격(+3pt) — 2개가 위아래로 살짝 띄움.
    static let sergeantRankChevronGap: CGFloat = 3
    /// 단일 chevron(v자) 폭(5pt).
    static let sergeantChevronWidth: CGFloat = 5
    /// 단일 chevron 높이(2.5pt) — v자 꼭짓점 깊이.
    static let sergeantChevronHeight: CGFloat = 2.5
    /// chevron 선 굵기(1.0pt) — 골드 stroke.
    static let sergeantChevronLineWidth: CGFloat = 1.0

    // MARK: - Sprint 7 Phase G · Player Facing (4방향 child)
    //
    // PlayerNode가 4 CharacterFaceNode child를 미리 부착해두고 isHidden 토글로 즉시 전환.
    // CharacterFaceNode 본래 좌표계(±50)와 PlayerNode 시각 크기(32×40)의 정합용.

    /// PlayerNode 4 CharacterFaceNode child의 scale (0.5).
    /// CharacterFaceNode head ellipse는 ±32~±34 좌표계 → 0.5 → ±16~±17pt 폭, player visual 32×40과 자연 정합.
    static let playerFaceChildScale: CGFloat = 0.5
    /// PlayerNode 자체 텍스처(zPos 0) 위에 face child를 얹기 위한 작은 양수 zPosition.
    static let playerFaceChildZPosition: CGFloat = 1

    // MARK: - Sprint 8 Phase F · HUD zPos V4
    //
    // 좌하단 영역 시각 적층 명확화: HUDSkillSlotNode 라벨 > HUD 일반 라벨 > SkillButton 본체.
    // 슬롯 라벨이 가장 위(110) — 스킬 이름·CD 단일 진실 원천.
    // HUD 일반 라벨(100) — 점수/타이머/콤보 등.
    // SkillButton 본체(80) — 좌하단 큰 코랄 원, "B" 칩만 노출.

    /// HUD 일반 라벨 zPosition(100). HUDNode 점수/타이머/콤보 라벨에 적용.
    static let hudLabelZPositionV4: CGFloat = 100
    /// SkillButtonNode 본체 zPosition(80). HUDSkillSlotNode(110)·HUD 라벨(100) 아래.
    static let skillButtonZPositionV4: CGFloat = 80
    /// HUDSkillSlotNode 슬롯 라벨 zPosition(110). 스킬 이름/CD 단일 진실 원천 — 가장 위.
    static let hudSkillSlotLabelZPositionV4: CGFloat = 110

    // MARK: - Sprint 8 Phase G · 인게임 시각 통합 V4
    //
    // 박병장 hard 난이도 데뷔(30s OR 50점) + 2.2s 컷씬 + 8s 등장.
    // 비행기 6 자식(fuselage/wings/tail/cockpit/propeller/contrail) 시각 — 노란 사각형 → 비행기 형상.
    // 플레이어 풀바디(CharacterFullBodyNode) — D-Pad 입력 시 팔다리 보이는 캐릭터.
    // physicsBody/AI/이동 *0줄 변경* — 시각 layer만 강화.

    // 박병장 데뷔
    /// 박병장 hard 난이도 데뷔 트리거 시간(30s). score 기준과 OR.
    static let sergeantParkDebutTimeV4: Double = 30.0
    /// 박병장 hard 난이도 데뷔 트리거 점수(50pt). time 기준과 OR.
    static let sergeantParkDebutScoreV4: Int = 50
    /// 박병장 데뷔 컷씬 총 길이(2.2s).
    static let sergeantParkIntroDurationV4: Double = 2.2
    /// 박병장 등장 후 화면 머무는 시간(8.0s).
    static let sergeantParkOnStageDurationV4: Double = 8.0

    // 비행기 시각
    /// 비행기 조종석 알파(0.6). attachCockpit에서 ganhoNavyDeep × alpha.
    static let airplaneCockpitColorAlphaV4: CGFloat = 0.6
    /// 비행기 프로펠러 1회전 시간(0.15s). SKAction.rotate × repeatForever.
    static let airplanePropellerRotateDurationV4: Double = 0.15

    // 플레이어 풀바디
    /// 플레이어 팔 폭(4pt). CharacterFullBodyNode arm rect.
    static let playerArmWidthV4: CGFloat = 4
    /// 플레이어 다리 폭(5pt). CharacterFullBodyNode leg rect.
    static let playerLegWidthV4: CGFloat = 5
    /// 걷기 다리 cycle 1회 시간(0.20s). 현재는 idle/breath만 — 후속 보강 대상.
    static let playerWalkCycleDurationV4: Double = 0.20
    /// 정지 호흡 cycle(1.50s). 몸통 scaleY 1.0 ↔ 1.02.
    static let playerIdleBreathDurationV4: Double = 1.50
    /// CharacterFullBodyNode → PlayerNode hitbox fit scale(0.35).
    /// CharacterFullBodyNode 자체 좌표계(약 ±60pt) × 0.35 ≈ PlayerNode 시각(32×40pt) 정합.
    static let playerFullBodyScaleV4: CGFloat = 0.35
}
