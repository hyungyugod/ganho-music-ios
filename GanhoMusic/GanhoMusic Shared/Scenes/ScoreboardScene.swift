//
//  ScoreboardScene.swift
//  GanhoMusic Shared
//
//  R5 재구축 — 픽셀 테이블 (03_UI §8). BaseMenuScene 상속 + NightShiftBackdrop.
//  R6 §F5 — [기록]/[업적] 탭 + 총 별 칩. 별 표시 소스 = MetaProgressRepository 저장 셀.
//  탭 전환 시 비활성 뷰는 *제거 후 재구성* — alpha=0/isHidden 좀비 금지 (R5 원칙).
//  저장·갱신 0건 — 모든 repository는 읽기 전용. 계정 스코프(.scoped)는 super.init 전 let 할당.
//

import SpriteKit
import UIKit

/// 캐릭터·난이도별 최고점수 + 별 테이블 / 업적 16종 씬. ResultScene [기록]으로 진입, 뒤로 = 복귀.
final class ScoreboardScene: BaseMenuScene {

    // MARK: - Tab (R6 §F5)
    enum Tab {
        case records
        case achievements
    }

    // MARK: - Properties
    /// 직전 게임이 신기록을 갱신한 (캐릭터, 난이도) 셀 — gold ★ 마커 1개. nil이면 미표시.
    let lastUpdatedKey: (CharacterID, Difficulty)?   // +Table 공유 — R4 분할 전례
    /// 뒤로 탭 시 복귀할 ResultScene 재생성 컨텍스트. nil이면 StartScene 폴백.
    private let returnContext: ResultReturnContext?
    private var isTransitioning = false
    /// 현재 활성 탭. 전환 시 비활성 뷰 노드는 전부 제거 (좀비 0). factory가 initialTab으로 1회 set.
    fileprivate(set) var activeTab: Tab = .records

    /// 계정 스코프 키를 읽어야 누적이 보임 — init에서 `.scoped` (GameScene과 동일 키).
    let perDiffRepo: PerDifficultyScoreRepository   // +Table 공유
    private let statsRepo = StatisticsRepository()
    private let graduationRepo: GraduationRepository
    /// R6 — 별 셀·업적 읽기 전용 소스 (+Table/+Achievements 공유).
    let metaRepo: MetaProgressRepository
    /// R7 §F9 — 씬 소유 햅틱 (ResultScene 전례 동형). 버튼 uiTap SFX는 PixelButtonNode 내장.
    private let haptics = HapticsManager()

    /// 테이블 골격 — 패널 1장, 셀 라벨/스프라이트는 패널 로컬 좌표 (리사이즈 시 재배치 불필요).
    var tablePanel: PixelPanelNode?   // +Table이 setupTable에서 설정
    /// R6 — 업적 패널 (+Achievements가 설정). 기록 탭에서는 nil (노드 자체 부재).
    var achievementPanel: PixelPanelNode?
    private var backButton: PixelButtonNode?
    private var playsChip: PixelChipNode?
    private var diplomaChip: PixelChipNode?
    private var totalStarsChip: PixelChipNode?
    private var recordsTabButton: PixelButtonNode?
    private var achievementsTabButton: PixelButtonNode?

    // MARK: - Factory
    /// R6 — initialTab 기본 인자 (기존 호출부 호환). 스크린샷 자동화의 업적 탭 직행에도 사용.
    class func newScoreboardScene(
        lastUpdatedKey: (CharacterID, Difficulty)? = nil,
        returnContext: ResultReturnContext? = nil,
        initialTab: Tab = .records
    ) -> ScoreboardScene {
        let scene = ScoreboardScene(
            size: CGSize(width: 1024, height: 768),
            lastUpdatedKey: lastUpdatedKey,
            returnContext: returnContext
        )
        scene.activeTab = initialTab
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
        self.metaRepo = MetaProgressRepository.scoped(scope: scope)
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        setupNightShiftBackdrop()
        switch activeTab {   // initialTab 직행 지원 — 기본 .records (기존 동작 동일)
        case .records:
            setupTable()
        case .achievements:
            setupAchievementsView()
        }
        setupBackButton()
        setupTabBar()
        setupStatChips()
        layoutAll()
        runStaggeredAppear(
            [tablePanel, achievementPanel, playsChip, diplomaChip, totalStarsChip].compactMap { $0 }
        )
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard tablePanel != nil || achievementPanel != nil else { return }   // didMove 이전 가드
        cancelStaggeredAppear()
        rebuildNightShiftBackdrop()
        layoutAll()
    }

    // MARK: - Tab Bar (R6 §F5 — PixelButton 재사용, 활성 = secondary / 비활성 = ghost)
    private func setupTabBar() {
        // 전환 시 스타일 갱신을 위해 *재생성* — PixelButtonNode는 불변 스타일 (좀비 0).
        recordsTabButton?.removeFromParent()
        achievementsTabButton?.removeFromParent()
        let records = PixelButtonNode(
            title: UILayout.R6.scoreboardRecordsTabText,
            variant: activeTab == .records ? .secondary : .ghost,
            size: UILayout.R6.scoreboardTabButtonSize,
            haptics: haptics   // R7 §F9 — 탭 전환도 uiTap 햅틱 동행 (권장 2종)
        )
        records.onTap = { [weak self] in self?.switchTab(to: .records) }
        let achievements = PixelButtonNode(
            title: UILayout.R6.scoreboardAchievementsTabText,
            variant: activeTab == .achievements ? .secondary : .ghost,
            size: UILayout.R6.scoreboardTabButtonSize,
            haptics: haptics   // R7 §F9
        )
        achievements.onTap = { [weak self] in self?.switchTab(to: .achievements) }
        [records, achievements].forEach { button in
            button.zPosition = ZOrder.Layer.hud
            addChild(button)
        }
        recordsTabButton = records
        achievementsTabButton = achievements
    }

    /// 탭 전환 — 비활성 뷰 *제거 후* 활성 뷰 재구성 (alpha=0/isHidden 게이트 금지).
    func switchTab(to tab: Tab) {
        guard tab != activeTab else { return }
        activeTab = tab
        tablePanel?.removeFromParent()
        tablePanel = nil
        achievementPanel?.removeFromParent()
        achievementPanel = nil
        switch tab {
        case .records:
            setupTable()
        case .achievements:
            setupAchievementsView()
        }
        setupTabBar()
        layoutAll()
    }

    // MARK: - Chrome (뒤로 ghost + 하단 stat 칩 — 브레드크럼 칩 폐지, 03_UI §6-5)
    private func setupBackButton() {
        // R7 §F9 — haptics 주입 (ResultScene+Build 전례 동형). 무주입이던 R5 잔여분 보충.
        let back = PixelButtonNode(title: UILayout.R4.selectBackButtonText,
                                   variant: .ghost,
                                   size: UILayout.R4.backButtonSize,
                                   haptics: haptics)
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
        // R6 §F5 — 총 별 칩 "★ {n}/45" (언락 진행 가시화 — 최대 45 = 15셀 × ★3).
        let maxStars = CharacterID.allCases.count * Difficulty.allCases.count
            * MetaProgression.maxStarsPerCell
        let starsChip = PixelChipNode(
            text: "\(UILayout.R6.scoreboardTotalStarsPrefix)\(metaRepo.totalStars)"
                + "\(UILayout.R6.scoreboardTotalStarsJoiner)\(maxStars)",
            style: .accent(Palette.gold)
        )
        [playsChip, diplomaChip, starsChip].forEach { chip in
            chip.zPosition = ZOrder.Layer.hud
            addChild(chip)
        }
        self.playsChip = playsChip
        self.diplomaChip = diplomaChip
        self.totalStarsChip = starsChip
    }

    // MARK: - Layout (didMove + didChangeSize + 탭 전환 공용 — 셀은 패널 로컬이라 패널만 이동)
    private func layoutAll() {
        let safe = menuSafeInsets()
        let scale = menuCompactScale()
        let centerX = frame.minX + safe.left + (size.width - safe.left - safe.right) / 2
        let panelPosition = CGPoint(
            x: centerX.rounded(),
            y: (frame.midY + UILayout.R5.scoreboardPanelCenterYOffset * scale).rounded()
        )
        tablePanel?.setScale(scale)
        tablePanel?.position = panelPosition
        achievementPanel?.setScale(scale)
        achievementPanel?.position = panelPosition

        backButton?.setScale(scale)
        backButton?.position = CGPoint(
            x: (frame.minX + safe.left + UILayout.v3ScreenEdgeInset
                + UILayout.R4.backButtonSize.width * scale / 2).rounded(),
            y: topBarY().rounded()
        )

        // 탭 버튼 2개 — top bar 행 중앙 (뒤로 버튼·stat 칩과 비겹침).
        if let records = recordsTabButton, let achievements = achievementsTabButton {
            let gap = UILayout.R6.scoreboardTabButtonGap * scale
            let buttonWidth = UILayout.R6.scoreboardTabButtonSize.width * scale
            let tabY = topBarY().rounded()
            records.setScale(scale)
            achievements.setScale(scale)
            records.position = CGPoint(x: (centerX - buttonWidth / 2 - gap / 2).rounded(), y: tabY)
            achievements.position = CGPoint(x: (centerX + buttonWidth / 2 + gap / 2).rounded(), y: tabY)
        }

        // stat 칩 3개 — 우상단 top bar 행 (뒤로 버튼 반대편, 패널과 비겹침). 우→좌 적층.
        if let plays = playsChip, let diploma = diplomaChip, let stars = totalStarsChip {
            let chipY = topBarY().rounded()
            let gap = UILayout.R5.scoreboardStatChipGap * scale
            var rightEdge = frame.maxX - safe.right - UILayout.v3ScreenEdgeInset
            for chip in [diploma, plays, stars] {
                chip.setScale(scale)
                chip.position = CGPoint(
                    x: (rightEdge - chip.chipSize.width * scale / 2).rounded(),
                    y: chipY
                )
                rightEdge -= chip.chipSize.width * scale + gap
            }
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
                graduatedAt: nil,
                runMeta: ctx.runMetaForReturn   // R6 — verdict 정합 보존 + 1회성 칩만 소거
            )
        } else {
            nextScene = StartScene.newStartScene()
        }
        SceneRouter.present(nextScene, on: view, route: .backward)
    }
}
