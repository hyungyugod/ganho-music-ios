//
//  ScoreboardScene+Table.swift
//  GanhoMusic Shared
//
//  R5 — 15셀 픽셀 테이블 구축 (03_UI §8). 셀은 패널 로컬 좌표 — 리사이즈 시 재배치 불필요.
//

import SpriteKit
import UIKit

extension ScoreboardScene {

    /// 패널 내부 적층 — 면(1)·헤더(2) 위 그리드 콘텐츠(3). PixelDialogNode content=3 컨벤션 동형.
    private enum GridZ {
        static let content: CGFloat = 3
    }

    // MARK: - Table (15셀 그리드)
    func setupTable() {
        let panel = PixelPanelNode(size: UILayout.R5.scoreboardPanelSize,
                                   title: UILayout.scoreboardTitleText,
                                   accent: Palette.gold)
        panel.zPosition = ZOrder.Layer.hud
        tablePanel = panel
        addChild(panel)

        let matrix = perDiffRepo.current
        // R6 §F5 — 별 표시 소스를 저장 셀(ratchet 기록)로 교체: 일일 2배 적립이 반영되어
        // 점수→별 단조 파생과 다를 수 있음 — 의도된 보상 시맨틱 (별은 "기록"이지 파생이 아님).
        let starCells = metaRepo.starCells
        // 열 헤더 — 난이도명, Palette.difficulty(d) 액센트 (v2 난이도 카드 lookup 사용 0).
        for (col, diff) in Difficulty.allCases.enumerated() {
            let header = makeLabel(text: diff.displayName,
                                   token: Typography.V3.h2,
                                   color: Palette.difficulty(diff))
            header.position = CGPoint(x: columnCenterX(col), y: headerRowY)
            panel.addChild(header)
        }
        // 행 헤더 — 24×24 포트레이트(정수 배율 .nearest) + 이름.
        for (row, charID) in CharacterID.allCases.enumerated() {
            addRowHeader(row: row, charID: charID, to: panel)
        }
        // 15 데이터 셀 — 최고점 + 별 / 미기록 "—".
        for (row, charID) in CharacterID.allCases.enumerated() {
            for (col, diff) in Difficulty.allCases.enumerated() {
                let best = matrix[charID]?[diff] ?? 0
                addCell(best: best,
                        recordedStars: starCells[charID]?[diff] ?? 0,
                        center: CGPoint(x: columnCenterX(col), y: rowCenterY(row)),
                        to: panel)
            }
        }
        addRecentMarkerIfNeeded(to: panel)
    }

    private func addRowHeader(row: Int, charID: CharacterID, to panel: PixelPanelNode) {
        let rowY = rowCenterY(row)
        let side = UILayout.R5.scoreboardPortraitSide
        let portrait = SKSpriteNode(texture: PixelPortraitSprite.texture(for: charID))
        portrait.size = CGSize(width: side, height: side)
        portrait.zPosition = GridZ.content
        portrait.position = CGPoint(x: (gridOriginX + side / 2 + UILayout.Space.s8).rounded(),
                                    y: rowY)
        panel.addChild(portrait)

        let name = makeLabel(text: charID.displayName,
                             token: Typography.V3.caption,
                             color: Palette.textHi)
        name.horizontalAlignmentMode = .left
        name.position = CGPoint(
            x: (portrait.position.x + side / 2 + UILayout.R5.scoreboardPortraitNameGap).rounded(),
            y: rowY
        )
        panel.addChild(name)
    }

    /// 셀 — 최고점(textHi) + 별 행(gold ★ 채움 / textLo ☆ 윤곽 — 윤곽도 시각 정보, 좀비 아님).
    /// R6 — 별은 호출부가 저장 셀 값을 주입 (점수 파생 아님 — 일일 2배 적립 반영).
    private func addCell(best: Int, recordedStars: Int,
                         center: CGPoint, to panel: PixelPanelNode) {
        guard best > 0 || recordedStars > 0 else {
            let empty = makeLabel(text: UILayout.R5.scoreboardEmptyCellText,
                                  token: Typography.V3.body,
                                  color: Palette.textLo)
            empty.position = center
            panel.addChild(empty)
            return
        }
        let score = makeLabel(text: "\(best)",
                              token: Typography.V3.body,
                              color: Palette.textHi)
        score.position = CGPoint(x: center.x,
                                 y: center.y + UILayout.R5.scoreboardCellScoreOffsetY)
        panel.addChild(score)

        let stars = min(max(recordedStars, 0), MetaProgression.maxStarsPerCell)
        let filled = makeLabel(
            text: String(repeating: UILayout.R5.starFilledText, count: stars),
            token: Typography.V3.caption,
            color: Palette.gold
        )
        let empty = makeLabel(
            text: String(repeating: UILayout.R5.starEmptyText,
                         count: MetaProgression.maxStarsPerCell - stars),
            token: Typography.V3.caption,
            color: Palette.textLo
        )
        filled.horizontalAlignmentMode = .left
        empty.horizontalAlignmentMode = .left
        let starY = center.y + UILayout.R5.scoreboardCellStarOffsetY
        let totalWidth = filled.frame.width + empty.frame.width
        filled.position = CGPoint(x: (center.x - totalWidth / 2).rounded(), y: starY)
        empty.position = CGPoint(x: (center.x - totalWidth / 2 + filled.frame.width).rounded(),
                                 y: starY)
        panel.addChild(filled)
        panel.addChild(empty)
    }

    /// ★ 직전 신기록 마커 — lastUpdatedKey 셀 1개 (gold), 셀 우상단.
    private func addRecentMarkerIfNeeded(to panel: PixelPanelNode) {
        guard let key = lastUpdatedKey,
              let row = CharacterID.allCases.firstIndex(of: key.0),
              let col = Difficulty.allCases.firstIndex(of: key.1) else { return }
        let marker = makeLabel(text: UILayout.R5.starFilledText,
                               token: Typography.V3.caption,
                               color: Palette.gold)
        marker.position = CGPoint(
            x: columnCenterX(col) + UILayout.R5.scoreboardMarkerOffset.x,
            y: rowCenterY(row) + UILayout.R5.scoreboardMarkerOffset.y
        )
        panel.addChild(marker)
    }

    // MARK: - Grid coordinates (패널 로컬)
    /// 그리드 콘텐츠 좌측 끝 x — 행 헤더 폭 + 3열이 패널 중앙에 오도록.
    private var gridOriginX: CGFloat {
        let contentWidth = UILayout.R5.scoreboardRowHeaderWidth
            + CGFloat(Difficulty.allCases.count) * UILayout.R5.scoreboardColumnWidth
        return -contentWidth / 2
    }

    private var headerRowY: CGFloat {
        return UILayout.R5.scoreboardPanelSize.height / 2 - UILayout.R5.scoreboardGridTopInset
    }

    private func columnCenterX(_ col: Int) -> CGFloat {
        return (gridOriginX + UILayout.R5.scoreboardRowHeaderWidth
                + CGFloat(col) * UILayout.R5.scoreboardColumnWidth
                + UILayout.R5.scoreboardColumnWidth / 2).rounded()
    }

    private func rowCenterY(_ row: Int) -> CGFloat {
        return (headerRowY - UILayout.R5.scoreboardRowHeight * CGFloat(row + 1)).rounded()
    }

    /// 그리드 콘텐츠 공용 라벨 — 패널 면(z=1) 위에 보이도록 GridZ.content 기본 적용.
    private func makeLabel(text: String,
                           token: Typography.V3.Token,
                           color: UIColor) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: token.fontName)
        label.text = text
        label.fontSize = token.size
        label.fontColor = color
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = GridZ.content
        return label
    }
}
