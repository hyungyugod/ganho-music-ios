//
//  ScoreboardScene.swift
//  GanhoMusic Shared
//
//  R5 재구축 — 픽셀 테이블 (03_UI §8). BaseMenuScene 상속 + NightShiftBackdrop.
//  5캐릭터 × 3난이도 15셀: 최고점 + 별 표기(MetaProgression 파생 — 별은 점수에 단조이므로
//  셀 최고점이 곧 최고 별). 테이블 골격은 PixelPanelNode 1장 — 셀별 패널 15장 금지 (노드 절약).
//  저장·갱신 0건 — 모든 repository는 읽기 전용. 계정 스코프(.scoped)는 super.init 전 let 할당.
//  업적 탭은 R6 추가 — R5는 단일 [기록] 뷰만 (비활성 더미 탭 금지 — 죽은 UI = 좀비 원칙).
//

import SpriteKit
import UIKit

/// 캐릭터·난이도별 최고점수 + 별 테이블 씬. ResultScene [기록]으로 진입, 뒤로 = 복귀.
final class ScoreboardScene: BaseMenuScene {

    // MARK: - Properties
    /// 직전 게임이 신기록을 갱신한 (캐릭터, 난이도) 셀 — gold ★ 마커 1개. nil이면 미표시.
    let lastUpdatedKey: (CharacterID, Difficulty)?   // +Table 공유 — R4 분할 전례
    /// 뒤로 탭 시 복귀할 ResultScene 재생성 컨텍스트. nil이면 StartScene 폴백.
    private let returnContext: ResultReturnContext?
    private var isTransitioning = false

    /// 계정 스코프 키를 읽어야 누적이 보임 — init에서 `.scoped` (GameScene과 동일 키).
    let perDiffRepo: PerDifficultyScoreRepository   // +Table 공유
    private let statsRepo = StatisticsRepository()
    private let graduationRepo: GraduationRepository

    /// 테이블 골격 — 패널 1장, 셀 라벨/스프라이트는 패널 로컬 좌표 (리사이즈 시 재배치 불필요).
    var tablePanel: PixelPanelNode?   // +Table이 setupTable에서 설정
    private var backButton: PixelButtonNode?
    private var playsChip: PixelChipNode?
    private var diplomaChip: PixelChipNode?

    // MARK: - Factory
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
        setupNightShiftBackdrop()
        setupTable()
        setupBackButton()
        setupStatChips()
        layoutAll()
        runStaggeredAppear([tablePanel, playsChip, diplomaChip].compactMap { $0 })
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard tablePanel != nil else { return }   // didMove 이전 호출 가드
        cancelStaggeredAppear()
        rebuildNightShiftBackdrop()
        layoutAll()
    }

    // MARK: - Chrome (뒤로 ghost + 하단 stat 칩 2개 — 브레드크럼 칩 폐지, 03_UI §6-5)
    private func setupBackButton() {
        let back = PixelButtonNode(title: UILayout.R4.selectBackButtonText,
                                   variant: .ghost,
                                   size: UILayout.R4.backButtonSize)
        back.onTap = { [weak self] in self?.transitionBack() }
        back.zPosition = ZOrder.Layer.hud
        backButton = back
        addChild(back)
    }

    private func setupStatChips() {
        let plays = statsRepo.current.playCount
        let diplomas = graduationRepo.current.count
        let playsChip = PixelChipNode(
            text: "\(UILayout.R5.scoreboardPlaysPrefix)\(plays)\(UILayout.R5.scoreboardPlaysSuffix)",
            style: .info
        )
        let diplomaChip = PixelChipNode(
            text: "\(UILayout.R5.scoreboardDiplomaPrefix)\(diplomas)\(UILayout.R5.scoreboardDiplomaSuffix)",
            style: .info
        )
        [playsChip, diplomaChip].forEach { chip in
            chip.zPosition = ZOrder.Layer.hud
            addChild(chip)
        }
        self.playsChip = playsChip
        self.diplomaChip = diplomaChip
    }

    // MARK: - Layout (didMove + didChangeSize 공용 — 셀은 패널 로컬이라 패널만 이동)
    private func layoutAll() {
        let safe = menuSafeInsets()
        let scale = menuCompactScale()
        let centerX = frame.minX + safe.left + (size.width - safe.left - safe.right) / 2

        tablePanel?.setScale(scale)
        tablePanel?.position = CGPoint(
            x: centerX.rounded(),
            y: (frame.midY + UILayout.R5.scoreboardPanelCenterYOffset * scale).rounded()
        )

        backButton?.setScale(scale)
        backButton?.position = CGPoint(
            x: (frame.minX + safe.left + UILayout.v3ScreenEdgeInset
                + UILayout.R4.backButtonSize.width * scale / 2).rounded(),
            y: topBarY().rounded()
        )

        // stat 칩 2개 — 우상단 top bar 행 (뒤로 버튼 반대편, 패널과 비겹침).
        if let plays = playsChip, let diploma = diplomaChip {
            let chipY = topBarY().rounded()
            let gap = UILayout.R5.scoreboardStatChipGap * scale
            let rightEdge = frame.maxX - safe.right - UILayout.v3ScreenEdgeInset
            plays.setScale(scale)
            diploma.setScale(scale)
            diploma.position = CGPoint(
                x: (rightEdge - diploma.chipSize.width * scale / 2).rounded(),
                y: chipY
            )
            plays.position = CGPoint(
                x: (rightEdge - diploma.chipSize.width * scale - gap
                    - plays.chipSize.width * scale / 2).rounded(),
                y: chipY
            )
        }
    }

    // MARK: - Transition (뒤로 — returnContext 있으면 ResultScene 재생성, 없으면 StartScene)
    private func transitionBack() {
        guard !isTransitioning, let view = self.view else { return }
        isTransitioning = true
        let nextScene: SKScene
        if let ctx = returnContext {
            nextScene = ResultScene.newResultScene(
                score: ctx.finalScore,
                bestScore: ctx.bestScore,
                isNewBest: ctx.isNewBest,
                stats: ctx.stats,
                characterID: ctx.characterID,
                difficulty: ctx.difficulty,
                maxCombo: ctx.maxCombo,
                notesCollected: ctx.notesCollected,
                isNewGraduation: false,   // 졸업장 재표시 차단 (기존 정책 보존)
                graduatedAt: nil
            )
        } else {
            nextScene = StartScene.newStartScene()
        }
        SceneRouter.present(nextScene, on: view, route: .backward)
    }
}
