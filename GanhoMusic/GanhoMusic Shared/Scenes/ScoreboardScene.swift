//
//  ScoreboardScene.swift
//  GanhoMusic Shared
//
//  Sprint 7 Phase D · 캐릭터·난이도별 최고점수 매트릭스 화면
//
//  ResultScene "📊 기록 보기" GlassPill 탭 시 진입하는 신규 씬.
//  5(캐릭터)×3(난이도) = 15셀 매트릭스로 PerDifficultyScoreRepository.best를 그대로 표시.
//  직전 게임이 신기록을 갱신한 셀에 ★ 마커 1개 부착(lastUpdatedKey).
//
//  탭 정책: 좌상단 "← 결과로" GlassPill 1탭 → 새 ResultScene 인스턴스 fade 복귀.
//  졸업장 재표시 차단을 위해 복귀 ResultScene은 `isNewGraduation: false` / `graduatedAt: nil`로 강제 생성.
//  returnContext가 nil이면 StartScene으로 폴백.
//
//  저장·갱신 0건 — 모든 repository는 *읽기 전용*으로만 호출.
//

import SpriteKit
import UIKit

/// 캐릭터·난이도별 최고점수 매트릭스 씬. ResultScene의 "기록 보기" 탭으로만 진입.
/// 노드 트리는 didMove에서 한 번에 구성하고, 좌표는 layoutAll()에서 재계산(didChangeSize 흡수).
/// repository 인스턴스는 기존 다른 씬과 동일하게 매 씬 new(UserDefaults 기반 stateless).
final class ScoreboardScene: SKScene {

    // MARK: - Properties

    /// 직전 게임이 신기록을 갱신한 (캐릭터, 난이도) 쌍. nil이면 ★ 미표시.
    /// ResultScene이 inferredCharacterID + difficulty + isNewBest로 산출해 전달.
    private let lastUpdatedKey: (CharacterID, Difficulty)?
    /// 백 버튼 탭 시 복귀할 ResultScene 재생성 컨텍스트. nil이면 StartScene 폴백.
    private let returnContext: ResultReturnContext?
    /// 중복 전환 차단.
    private var isTransitioning = false

    /// PerDifficulty 최고점수 — 매트릭스 셀 값 소스. UserDefaults 기반 stateless.
    /// GameScene과 동일한 계정 스코프 키를 읽어야 누적이 보이므로 init에서 `.scoped`로 생성한다.
    private let perDiffRepo: PerDifficultyScoreRepository
    /// 누적 플레이 통계 — 하단 stat 라벨 소스. GameScene도 unscoped라 그대로 둔다(PLAYS/TOTAL 회귀 방지).
    private let statsRepo = StatisticsRepository()
    /// 졸업 일시 사전 — 하단 stat 라벨의 졸업장 개수 소스. count = current.keys 수.
    /// GameScene과 동일한 계정 스코프 키를 읽어야 졸업장이 보이므로 init에서 `.scoped`로 생성한다.
    private let graduationRepo: GraduationRepository

    // 자식 노드 — didMove에서 부착, layoutAll에서 좌표만 갱신.

    /// 좌상단 "← 결과로" GlassPill — touchesBegan hit-test 대상.
    private var backButton: GlassPillNode?
    /// 우상단 "캐릭터별 기록" DarkContextChip — 시각만.
    private var breadcrumbChip: DarkContextChipNode?
    /// 헤더 액센트 라인.
    private let accentLine = AccentLineNode()
    /// 타이틀 "기록 보기" (Jua 30pt).
    private let titleLabel = SKLabelNode(text: UILayout.scoreboardTitleText)
    /// 부제 (Gowun Dodum 12pt).
    private let subtitleLabel = SKLabelNode(text: UILayout.scoreboardSubtitleText)
    /// 매트릭스 컨테이너 — 열 헤더 + 행 헤더 + 15 셀 + ★ 마커 자식.
    private let matrixContainer = SKNode()
    /// 하단 stat 라벨 (총 플레이 N회 · 졸업장 N장 보유).
    private let statLabel = SKLabelNode(text: "")

    // MARK: - Factory

    /// ResultScene "📊 기록 보기" 탭에서 호출되는 진입점. 인자 모두 default → StartScene 진입 가능.
    /// 시그니처는 SPEC §OQ-1·OQ-3에 맞춤 — lastUpdatedKey 튜플 + returnContext 옵셔널 9-인자 봉투.
    class func newScoreboardScene(
        lastUpdatedKey: (CharacterID, Difficulty)? = nil,
        returnContext: ResultReturnContext? = nil
    ) -> ScoreboardScene {
        let scene = ScoreboardScene(
            size: CGSize(width: 1024, height: 768),
            lastUpdatedKey: lastUpdatedKey,
            returnContext: returnContext
        )
        scene.scaleMode = .resizeFill
        return scene
    }

    // MARK: - Init

    /// 두 컨텍스트 모두 `let` — super.init 전에 저장. 외부에서는 newScoreboardScene 팩토리 사용.
    /// perDiffRepo·graduationRepo도 `let` stored property이므로 GameScene.swift 118~123행과 동일하게
    /// 계정 스코프(.scoped)로 super.init **이전**에 할당한다 — 저장(GameScene)과 같은 키를 읽어 누적을 노출.
    private init(
        size: CGSize,
        lastUpdatedKey: (CharacterID, Difficulty)?,
        returnContext: ResultReturnContext?
    ) {
        self.lastUpdatedKey = lastUpdatedKey
        self.returnContext = returnContext
        let scope = AccountProgressScopeProvider.current(
            authProfile: AuthProfileRepository().current
        )
        self.perDiffRepo = PerDifficultyScoreRepository.scoped(scope: scope)
        self.graduationRepo = GraduationRepository.scoped(scope: scope)
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        setupSolidBackground()
        setupHeader()
        setupBackButton()
        setupBreadcrumbChip()
        setupMatrix()
        setupStatLabel()
        layoutAll()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutAll()
    }

    // MARK: - Setup

    private func setupSolidBackground() {
        backgroundColor = Palette.menuSolidBackgroundColor
    }

    /// 헤더 — AccentLine + 타이틀 + 부제.
    private func setupHeader() {
        accentLine.zPosition = 5
        addChild(accentLine)

        titleLabel.fontName = Typography.fontDisplay
        titleLabel.fontSize = UILayout.scoreboardTitleFontSize
        titleLabel.fontColor = .ganhoNavyDeep
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.zPosition = 6
        titleLabel.name = "scoreboardTitle"
        addChild(titleLabel)

        subtitleLabel.fontName = Typography.fontBody
        subtitleLabel.fontSize = UILayout.scoreboardSubtitleFontSize
        subtitleLabel.fontColor = .ganhoNavyMuted
        subtitleLabel.horizontalAlignmentMode = .center
        subtitleLabel.verticalAlignmentMode = .center
        subtitleLabel.zPosition = 6
        subtitleLabel.name = "scoreboardSubtitle"
        addChild(subtitleLabel)
    }

    /// 좌상단 "← 결과로" GlassPill.
    private func setupBackButton() {
        let pill = GlassPillNode(
            text: UILayout.scoreboardBackButtonText,
            size: CGSize(
                width: UILayout.scoreboardBackButtonWidth,
                height: UILayout.scoreboardBackButtonHeight
            )
        )
        pill.zPosition = 100
        pill.name = "scoreboardBackButton"
        backButton = pill
        addChild(pill)
    }

    /// 우상단 "캐릭터별 기록" DarkContextChip — 브레드크럼.
    private func setupBreadcrumbChip() {
        let chip = DarkContextChipNode(
            label: UILayout.scoreboardBreadcrumbText,
            badge: nil
        )
        chip.zPosition = 100
        chip.name = "scoreboardBreadcrumb"
        breadcrumbChip = chip
        addChild(chip)
    }

    /// 매트릭스 구성 — 열 헤더 3개 + 행 헤더 5개 + 15 셀 + ★ 마커 (해당 셀에만).
    /// matrixContainer는 frame.midY + scoreboardMatrixOffsetY를 기준으로 자식 좌표 결정.
    /// 자식 좌표는 *매트릭스 컨테이너 안 로컬*이 아니라 *씬 좌표*로 직접 계산해 부착.
    private func setupMatrix() {
        matrixContainer.zPosition = 5
        matrixContainer.name = "scoreboardMatrix"
        addChild(matrixContainer)

        let matrix = perDiffRepo.current
        let characters = CharacterID.allCases
        let difficulties = Difficulty.allCases

        // 열 헤더 3개 — 난이도별 색 토큰(Phase C cardFillBottom).
        for (col, diff) in difficulties.enumerated() {
            let label = SKLabelNode(fontNamed: Typography.fontDisplay)
            label.text = diff.displayName
            label.fontSize = UILayout.scoreboardColumnHeaderFontSize
            label.fontColor = diff.cardStrokeColor
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.zPosition = 6
            label.name = "scoreboardColHeader_\(diff.rawValue)"
            label.position = columnHeaderPosition(col: col)
            matrixContainer.addChild(label)
        }

        // 행 헤더 5개 — 미니 얼굴 + 약칭(이름 첫 글자).
        // R4 §F-7 — 24×24 픽셀 포트레이트 (기존 mini 표시 폭 ~32pt 유지, 위치 함수 그대로).
        for (row, charID) in characters.enumerated() {
            let face = SKSpriteNode(texture: PixelPortraitSprite.texture(for: charID))
            face.size = CGSize(width: UILayout.R4.scoreboardPortraitSide,
                               height: UILayout.R4.scoreboardPortraitSide)
            face.zPosition = 6
            face.position = rowHeaderFacePosition(row: row)
            matrixContainer.addChild(face)

            let nameLabel = SKLabelNode(fontNamed: Typography.fontDisplay)
            // displayName 첫 글자(1자) — "김", "정", "건", "임", "이".
            nameLabel.text = String(charID.displayName.prefix(1))
            nameLabel.fontSize = UILayout.scoreboardRowHeaderShortNameFontSize
            nameLabel.fontColor = .ganhoNavyDeep
            nameLabel.horizontalAlignmentMode = .center
            nameLabel.verticalAlignmentMode = .center
            nameLabel.zPosition = 6
            nameLabel.name = "scoreboardRowHeaderName_\(charID.rawValue)"
            nameLabel.position = rowHeaderNamePosition(row: row)
            matrixContainer.addChild(nameLabel)
        }

        // 15 셀 — 점수 또는 "—" 회색.
        for (row, charID) in characters.enumerated() {
            for (col, diff) in difficulties.enumerated() {
                let score = matrix[charID]?[diff] ?? 0
                let cellLabel = SKLabelNode()
                if score > 0 {
                    cellLabel.text = "\(score)"
                    cellLabel.fontName = Typography.fontDisplay
                    cellLabel.fontSize = UILayout.scoreboardCellScoreFontSize
                    cellLabel.fontColor = .ganhoNavyDeep
                    cellLabel.alpha = 1.0
                } else {
                    cellLabel.text = UILayout.scoreboardCellEmptyText
                    cellLabel.fontName = Typography.fontBody
                    cellLabel.fontSize = UILayout.scoreboardCellEmptyFontSize
                    cellLabel.fontColor = .ganhoNavyMuted
                    cellLabel.alpha = UILayout.scoreboardCellEmptyAlpha
                }
                cellLabel.horizontalAlignmentMode = .center
                cellLabel.verticalAlignmentMode = .center
                cellLabel.zPosition = 2
                cellLabel.name = "scoreboardCell_\(charID.rawValue)_\(diff.rawValue)"
                cellLabel.position = cellPosition(row: row, col: col)
                matrixContainer.addChild(cellLabel)
            }
        }

        // ★ 마커 — lastUpdatedKey 셀 1개에만. 셀 텍스트 위(zPosition 3).
        if let key = lastUpdatedKey,
           let row = characters.firstIndex(of: key.0),
           let col = difficulties.firstIndex(of: key.1) {
            let star = SKLabelNode(fontNamed: Typography.fontDisplay)
            star.text = UILayout.scoreboardStarMarkerText
            star.fontSize = UILayout.scoreboardStarMarkerFontSize
            star.fontColor = .ganhoMusicGold
            star.horizontalAlignmentMode = .center
            star.verticalAlignmentMode = .center
            star.zPosition = 3
            star.name = "scoreboardStarMarker"
            let cellPos = cellPosition(row: row, col: col)
            star.position = CGPoint(
                x: cellPos.x + UILayout.scoreboardStarMarkerOffsetX,
                y: cellPos.y + UILayout.scoreboardStarMarkerOffsetY
            )
            matrixContainer.addChild(star)
        }
    }

    /// 하단 stat 라벨 — 총 플레이 N회 · 졸업장 N장 보유.
    private func setupStatLabel() {
        let plays = statsRepo.current.playCount
        let diplomas = graduationRepo.current.count
        statLabel.text = "총 플레이 \(plays)회 · 졸업장 \(diplomas)장 보유"
        statLabel.fontName = Typography.fontBody
        statLabel.fontSize = UILayout.scoreboardStatFontSize
        statLabel.fontColor = .ganhoNavyMuted
        statLabel.horizontalAlignmentMode = .center
        statLabel.verticalAlignmentMode = .center
        statLabel.zPosition = 6
        statLabel.name = "scoreboardStat"
        addChild(statLabel)
    }

    // MARK: - Layout

    /// 모든 자식 좌표를 frame.midX/midY 기준으로 재배치. didMove + didChangeSize 공용.
    /// 매트릭스 안 셀/헤더 좌표는 cellPosition/rowHeader/colHeader 헬퍼가 frame 기준으로 직접 산출하므로
    /// 매트릭스 컨테이너의 position은 .zero(또는 무관)로 두고 자식 노드들의 position만 갱신한다.
    private func layoutAll() {
        let centerX = scoreboardSafeCenterX()

        // V4 — 타이틀 zone(타이틀·부제)을 +40pt 상향해 매트릭스 zone과 분리.
        // AccentLine은 V3 위치(+130)에서 -40 = +90으로 내려 *타이틀 아래 + 헤더 위* 시각 구분선 역할.
        accentLine.position = CGPoint(
            x: centerX,
            y: frame.midY + UILayout.scoreboardAccentLineOffsetY
                          - UILayout.scoreboardTitleYOffset
        )
        titleLabel.position = CGPoint(
            x: centerX,
            y: frame.midY + UILayout.scoreboardTitleOffsetY
                          + UILayout.scoreboardTitleYOffset
        )
        subtitleLabel.position = CGPoint(
            x: centerX,
            y: frame.midY + UILayout.scoreboardSubtitleOffsetY
                          + UILayout.scoreboardTitleYOffset
        )

        // 백 버튼 / 브레드크럼 — safe area를 흡수해 노치/Dynamic Island 회피.
        let safe = scoreboardSafeInsets()
        let topY = frame.maxY - safe.top - UILayout.scoreboardBackButtonInsetY
        let leftX = frame.minX + safe.left + UILayout.scoreboardBackButtonInsetX
        backButton?.position = CGPoint(
            x: leftX + UILayout.scoreboardBackButtonWidth / 2,
            y: topY
        )
        let rightInsetX = frame.maxX - safe.right - UILayout.scoreboardBreadcrumbInsetX
        breadcrumbChip?.position = CGPoint(
            x: rightInsetX - (breadcrumbChip?.calculateAccumulatedFrame().width ?? 0) / 2,
            y: topY
        )

        // V4 → V6 — stat 라벨을 매트릭스 마지막 행 bottom으로부터 40pt 아래에 동적 배치.
        // V3/V4 상수(scoreboardStatOffsetY=-150 / scoreboardStatBottomGapV4=24)는 byte-identical 보존.
        // V6에서 24pt → 40pt 확대로 매트릭스↔stat 묶음 시각 분리 강화.
        let lastRowCenterY = dataRowCenterY(row: UILayout.scoreboardMatrixRowCount - 1)
        let lastRowBottomY = lastRowCenterY - UILayout.scoreboardCellHeight / 2
        statLabel.position = CGPoint(
            x: centerX,
            y: lastRowBottomY - UILayout.scoreboardStatBottomGap
        )

        // 매트릭스 자식 좌표 재계산 — 헬퍼 함수가 frame.midX/midY를 직접 참조하므로
        // matrixContainer 자체 위치는 .zero로 두고 자식만 갱신.
        matrixContainer.position = .zero
        relayoutMatrixChildren()
    }

    /// didChangeSize 등으로 frame이 바뀌면 매트릭스 셀/헤더 위치도 다시 계산해 부착.
    /// 새로 만드는 대신 기존 자식의 position만 갱신해 재할당 비용 0.
    private func relayoutMatrixChildren() {
        let characters = CharacterID.allCases
        let difficulties = Difficulty.allCases

        for (col, diff) in difficulties.enumerated() {
            let name = "scoreboardColHeader_\(diff.rawValue)"
            if let node = matrixContainer.childNode(withName: name) {
                node.position = columnHeaderPosition(col: col)
            }
        }
        for (row, charID) in characters.enumerated() {
            if let face = matrixContainer.childNode(withName: "miniFace_\(charID.rawValue)") {
                face.position = rowHeaderFacePosition(row: row)
            }
            if let label = matrixContainer.childNode(withName: "scoreboardRowHeaderName_\(charID.rawValue)") {
                label.position = rowHeaderNamePosition(row: row)
            }
        }
        for (row, charID) in characters.enumerated() {
            for (col, diff) in difficulties.enumerated() {
                let name = "scoreboardCell_\(charID.rawValue)_\(diff.rawValue)"
                if let node = matrixContainer.childNode(withName: name) {
                    node.position = cellPosition(row: row, col: col)
                }
            }
        }
        // ★ 마커 — lastUpdatedKey 셀의 우상단 오프셋 재계산.
        if let key = lastUpdatedKey,
           let row = CharacterID.allCases.firstIndex(of: key.0),
           let col = Difficulty.allCases.firstIndex(of: key.1),
           let star = matrixContainer.childNode(withName: "scoreboardStarMarker") {
            let cellPos = cellPosition(row: row, col: col)
            star.position = CGPoint(
                x: cellPos.x + UILayout.scoreboardStarMarkerOffsetX,
                y: cellPos.y + UILayout.scoreboardStarMarkerOffsetY
            )
        }
    }

    // MARK: - Cell coordinate helpers

    /// 매트릭스 총 폭 — 행 헤더 폭 + 3 셀 폭 + 2 간격.
    private var matrixTotalWidth: CGFloat {
        return UILayout.scoreboardRowHeaderWidth
            + CGFloat(UILayout.scoreboardMatrixColumnCount) * UILayout.scoreboardCellWidth
            + CGFloat(UILayout.scoreboardMatrixColumnCount - 1) * UILayout.scoreboardCellGap
    }

    /// 매트릭스 총 높이 — 열 헤더 행 + 5 데이터 행 + 5 간격.
    private var matrixTotalHeight: CGFloat {
        return UILayout.scoreboardCellHeight
            + CGFloat(UILayout.scoreboardMatrixRowCount) * UILayout.scoreboardCellHeight
            + CGFloat(UILayout.scoreboardMatrixRowCount) * UILayout.scoreboardCellGap
    }

    /// 매트릭스 좌상단 (시각 기준 origin) 의 씬 좌표.
    private var matrixOriginX: CGFloat {
        return scoreboardSafeCenterX() - matrixTotalWidth / 2
    }
    private var matrixOriginTopY: CGFloat {
        // V6 — 매트릭스 zone -30pt 시프트. 부제(midY+112)와 열 헤더(midY+110) 겹침 해소.
        // V3 scoreboardMatrixOffsetY(+10)는 byte-identical 보존 — 사용처만 V6 토큰으로 교체.
        return frame.midY + UILayout.scoreboardMatrixOffsetY + matrixTotalHeight / 2
    }

    /// 열 헤더 (col = 0..2) 중심 좌표. 매트릭스 최상단 row(헤더 row).
    private func columnHeaderPosition(col: Int) -> CGPoint {
        let cellX = matrixOriginX + UILayout.scoreboardRowHeaderWidth
            + CGFloat(col) * (UILayout.scoreboardCellWidth + UILayout.scoreboardCellGap)
            + UILayout.scoreboardCellWidth / 2
        let headerY = matrixOriginTopY - UILayout.scoreboardCellHeight / 2
        return CGPoint(x: cellX, y: headerY)
    }

    /// 행 헤더의 미니 얼굴 중심 좌표.
    /// V6 — face↔name 거리 V3 22pt → 32pt 확대. V3 토큰 값은 byte-identical 보존, 참조만 V6로 교체.
    private func rowHeaderFacePosition(row: Int) -> CGPoint {
        let faceX = matrixOriginX + UILayout.scoreboardRowHeaderWidth / 2
            - UILayout.scoreboardRowHeaderShortNameOffsetX / 2
        let faceY = dataRowCenterY(row: row)
        return CGPoint(x: faceX, y: faceY)
    }

    /// 행 헤더의 약칭(이름 첫 글자) 라벨 중심 좌표.
    /// V6 — face↔name 거리 V3 22pt → 32pt 확대. V3 토큰 값은 byte-identical 보존, 참조만 V6로 교체.
    private func rowHeaderNamePosition(row: Int) -> CGPoint {
        let nameX = matrixOriginX + UILayout.scoreboardRowHeaderWidth / 2
            + UILayout.scoreboardRowHeaderShortNameOffsetX / 2
        let nameY = dataRowCenterY(row: row)
        return CGPoint(x: nameX, y: nameY)
    }

    /// 데이터 셀 (row = 0..4, col = 0..2) 중심 좌표.
    private func cellPosition(row: Int, col: Int) -> CGPoint {
        let cellX = matrixOriginX + UILayout.scoreboardRowHeaderWidth
            + CGFloat(col) * (UILayout.scoreboardCellWidth + UILayout.scoreboardCellGap)
            + UILayout.scoreboardCellWidth / 2
        let cellY = dataRowCenterY(row: row)
        return CGPoint(x: cellX, y: cellY)
    }

    /// row(0~4)의 셀 중심 y. 열 헤더 행 아래에서 시작.
    /// V4 — 헤더↔본문 gap을 scoreboardCellGap(4pt) → scoreboardHeaderRowGapV4(18pt)로 확장하고,
    /// 행 사이 pitch를 (cellHeight+cellGap=40pt) → scoreboardCellPitchYV4(38pt)로 균형화.
    /// 시그니처(`row: Int -> CGFloat`)는 byte-identical 보존 — 본문 안 상수만 V4 토큰으로 교체.
    private func dataRowCenterY(row: Int) -> CGFloat {
        let firstDataRowTop = matrixOriginTopY
            - UILayout.scoreboardCellHeight
            - UILayout.scoreboardHeaderRowGap
        return firstDataRowTop - UILayout.scoreboardCellHeight / 2
            - CGFloat(row) * UILayout.scoreboardCellPitchY
    }

    private func scoreboardSafeInsets() -> UIEdgeInsets {
        let profile = DeviceLayoutProfile.resolve(for: self)
        return SceneSafeArea.contentInsets(
            for: self,
            maxContentWidth: profile.scoreboardMaxContentWidth
        )
    }

    private func scoreboardSafeCenterX() -> CGFloat {
        let safe = scoreboardSafeInsets()
        let availableWidth = size.width - safe.left - safe.right
        return frame.minX + safe.left + availableWidth / 2
    }

    // MARK: - Touch

    /// "← 결과로" GlassPill 탭 → ResultScene 새 인스턴스(졸업장 재진입 차단) 또는 StartScene.
    /// 중복 탭은 isTransitioning으로 차단. 그 외 영역 탭은 무시(1탭 정책).
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning, let view = self.view, let touch = touches.first else { return }
        let location = touch.location(in: self)
        guard let back = backButton, back.contains(location) else { return }
        isTransitioning = true
        returnToResultOrStart(view: view)
    }

    /// returnContext가 있으면 ResultScene 새 인스턴스로 복귀(`isNewGraduation: false` 강제 →
    /// 졸업장 재표시 차단, sparkle 재발화는 isNewBest 분기 그대로 — Generator는 *추가 차단 0*).
    /// returnContext가 nil이면 StartScene으로 폴백.
    /// fade 길이는 sceneTransitionDuration(0.4)으로 ResultScene → ScoreboardScene과 대칭.
    private func returnToResultOrStart(view: SKView) {
        let nextScene: SKScene
        if let ctx = returnContext {
            nextScene = ResultScene.newResultScene(
                score: ctx.finalScore,
                bestScore: ctx.bestScore,
                isNewBest: ctx.isNewBest,
                stats: ctx.stats,
                characterName: ctx.characterName,
                difficulty: ctx.difficulty,
                isNewGraduation: false,   // SPEC §주의사항 3 — 졸업장 재표시 차단
                graduatedAt: nil          // SPEC §주의사항 3 — Date도 nil로 강제
            )
        } else {
            nextScene = StartScene.newStartScene()
        }
        SceneRouter.present(nextScene, on: view, route: .backward)
    }
}

// MARK: - ResultReturnContext

/// ResultScene → ScoreboardScene → ResultScene 라운드트립용 9-인자 값 봉투.
/// init/newResultScene 9-인자 시그니처를 *그대로 보존*하기 위해 모든 인자를 한 묶음으로 전달.
/// `isNewGraduation` / `graduatedAt`은 ScoreboardScene 측에서 *false / nil 로 강제 덮어쓰기*되어
/// 졸업장 재표시 차단(SPEC §주의사항 3).
/// Foundation 의존만 — SpriteKit 의존 0(import 불필요). 같은 파일 안에 정의해
/// ScoreboardScene과 컴파일 단위·생명주기를 함께 유지.
struct ResultReturnContext {
    let finalScore: Int
    let bestScore: Int
    let isNewBest: Bool
    let stats: GameStats
    let characterName: String
    let difficulty: Difficulty
    let isNewGraduation: Bool
    let graduatedAt: Date?
}
