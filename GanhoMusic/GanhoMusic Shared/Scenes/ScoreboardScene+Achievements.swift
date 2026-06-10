//
//  ScoreboardScene+Achievements.swift
//  GanhoMusic Shared
//
//  R6 §F5 — 업적 탭 뷰 (R4/R5 extension 분할 전례). R5 주석 "업적 탭은 R6 추가"의 예약 이행.
//  PixelPanel 1장 + 16셀 그리드(2열×8행). 달성 = gold ★ + 이름 + 달성일 /
//  미달성 = 어둡게(☆ textLo) + 조건 문구. 셀당 라벨 3개 × 16 = 48 + 패널 — 노드 ≤250 여유.
//  탭 전환 시 본 패널은 통째로 제거 후 재구성 — alpha=0 좀비 0.
//

import SpriteKit
import UIKit

extension ScoreboardScene {

    /// 패널 내부 적층 — +Table GridZ.content(3) 컨벤션 동형.
    private enum AchievementZ {
        static let content: CGFloat = 3
    }

    // MARK: - Achievements View (16셀 그리드)
    func setupAchievementsView() {
        let panel = PixelPanelNode(size: UILayout.R6.achievementPanelSize,
                                   title: UILayout.R6.scoreboardAchievementsTabText,
                                   accent: Palette.gold)
        panel.zPosition = ZOrder.Layer.hud
        achievementPanel = panel
        addChild(panel)

        // 달성 dict 1회 읽기 + 날짜 포매터 1회 생성 (빌드 시점 — update 경로 0).
        let achieved = metaRepo.achievements
        let formatter = DateFormatter()
        formatter.dateFormat = UILayout.R6.achievementDateFormat
        for (index, id) in AchievementID.allCases.enumerated() {
            addAchievementCell(id: id,
                               achievedAt: achieved[id],
                               index: index,
                               formatter: formatter,
                               to: panel)
        }
    }

    /// 단일 업적 셀 — ★/☆ 아이콘 + 이름 + 보조(달성일 / 조건 문구).
    private func addAchievementCell(id: AchievementID,
                                    achievedAt: Date?,
                                    index: Int,
                                    formatter: DateFormatter,
                                    to panel: PixelPanelNode) {
        let columns = 2
        let column = index % columns
        let row = index / columns
        let cellOriginX = -UILayout.R6.achievementPanelSize.width / 2
            + CGFloat(column) * UILayout.R6.achievementColumnWidth
            + (UILayout.R6.achievementPanelSize.width
               - CGFloat(columns) * UILayout.R6.achievementColumnWidth) / 2
        let cellCenterY = UILayout.R6.achievementPanelSize.height / 2
            - UILayout.R6.achievementGridTopInset
            - CGFloat(row) * UILayout.R6.achievementRowHeight

        let isAchieved = achievedAt != nil
        // 아이콘 — 달성 gold ★ / 미달성 textLo ☆ (윤곽도 시각 정보 — 좀비 아님).
        let icon = makeAchievementLabel(
            text: isAchieved ? UILayout.R5.starFilledText : UILayout.R5.starEmptyText,
            color: isAchieved ? Palette.gold : Palette.textLo
        )
        icon.position = CGPoint(x: (cellOriginX + UILayout.R6.achievementIconInsetX).rounded(),
                                y: cellCenterY.rounded())
        panel.addChild(icon)
        // 이름 — 달성 textHi / 미달성 textLo (어둡게).
        let name = makeAchievementLabel(
            text: id.displayName,
            color: isAchieved ? Palette.textHi : Palette.textLo
        )
        name.horizontalAlignmentMode = .left
        name.position = CGPoint(x: (cellOriginX + UILayout.R6.achievementNameInsetX).rounded(),
                                y: cellCenterY.rounded())
        panel.addChild(name)
        // 보조 — 달성일 / 조건 문구 (우측 정렬).
        let subText: String
        if let achievedAt = achievedAt {
            subText = formatter.string(from: achievedAt)
        } else {
            subText = id.conditionText
        }
        let sub = makeAchievementLabel(text: subText, color: Palette.textLo)
        sub.horizontalAlignmentMode = .right
        sub.position = CGPoint(x: (cellOriginX + UILayout.R6.achievementSubInsetX).rounded(),
                               y: cellCenterY.rounded())
        panel.addChild(sub)
    }

    /// 업적 그리드 공용 라벨 — 패널 면(z=1) 위 (caption 토큰).
    private func makeAchievementLabel(text: String, color: UIColor) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: Typography.V3.caption.fontName)
        label.text = text
        label.fontSize = Typography.V3.caption.size
        label.fontColor = color
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = AchievementZ.content
        return label
    }
}
