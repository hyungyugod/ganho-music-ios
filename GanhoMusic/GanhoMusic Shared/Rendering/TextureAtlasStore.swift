//
//  TextureAtlasStore.swift
//  GanhoMusic Shared
//
//  R1 · 인게임 텍스처의 유일한 생성·캐시 지점.
//  설계서: refactor/01_CODE_ARCHITECTURE.md §9.
//

import SpriteKit
import UIKit

/// 인게임 캐릭터·아이템·환경 텍스처의 단일 생성·캐시 지점.
/// 왜: 노드별 static 캐시 5벌(PlayerNode 2 + Enemy/Professor/StoneGuard 각 1)이 같은 패턴의
/// 복붙으로 드리프트 위험이었고, 음표/F/A/청진기는 init마다 매번 렌더돼 풀 예열 시 N회 렌더 낭비.
/// 캐시는 static — 씬 재시작에도 워밍 유지(기존 노드별 static 캐시와 동일 시맨틱).
/// 캐릭터·아이템의 실제 픽셀 렌더는 기존 PixelSpriteRenderer에 그대로 위임(렌더 로직 무수정 —
/// 같은 입력 → 같은 image → 결과 byte-equal). 모든 텍스처 filteringMode = .nearest 일괄
/// (PixelSpriteRenderer 경유분은 그쪽이 보장, 본 파일 신규 렌더 2종은 명시 적용).
/// ⚠️ 빌런 3종 캐시는 분리 유지 — 팔레트/픽셀 데이터가 달라 공유 절대 금지.
enum TextureAtlasStore {

    // MARK: - Player Characters (5종 × 4방향 × 3프레임)
    private static var characterCache: [CharacterID: [PixelDirection: [PixelFrame: SKTexture]]] = [:]

    /// 플레이어 캐릭터 텍스처. 구 PlayerNode.textureCache(idle 5×4)와 walkTextureCache(5×4×3)를
    /// 단일 3차원 캐시로 통합 — idle 전용 조회는 frame: .idle로 흡수(같은 입력 → 같은 렌더 결과).
    static func characterTexture(id: CharacterID,
                                 direction: PixelDirection,
                                 frame: PixelFrame) -> SKTexture {
        if let cached = characterCache[id]?[direction]?[frame] { return cached }
        let texture = PixelSpriteRenderer.texture(
            from: PixelSprite.data(for: id, direction: direction, frame: frame),
            palette: PixelPalette.palette(for: id)
        )
        characterCache[id, default: [:]][direction, default: [:]][frame] = texture
        return texture
    }

    // MARK: - Villains (수간호사 / 이교수 / 석조무사)
    private static var nurseChiefCache: [PixelDirection: [PixelFrame: SKTexture]] = [:]
    private static var professorCache: [PixelDirection: [PixelFrame: SKTexture]] = [:]
    private static var stoneGuardCache: [PixelDirection: [PixelFrame: SKTexture]] = [:]

    /// 수간호사 텍스처 — 구 EnemyNode.textureCache 흡수. 4방향 × 3프레임 = 최대 12종 lazy.
    static func nurseChiefTexture(direction: PixelDirection, frame: PixelFrame) -> SKTexture {
        if let cached = nurseChiefCache[direction]?[frame] { return cached }
        let texture = PixelSpriteRenderer.texture(
            from: PixelSprite.nurseChiefData(direction: direction, frame: frame),
            palette: PixelPalette.chiefPalette
        )
        nurseChiefCache[direction, default: [:]][frame] = texture
        return texture
    }

    /// 이교수 텍스처 — 구 ProfessorNode.textureCache 흡수.
    static func professorTexture(direction: PixelDirection, frame: PixelFrame) -> SKTexture {
        if let cached = professorCache[direction]?[frame] { return cached }
        let texture = PixelSpriteRenderer.texture(
            from: PixelSprite.professorData(direction: direction, frame: frame),
            palette: PixelPalette.professorPalette
        )
        professorCache[direction, default: [:]][frame] = texture
        return texture
    }

    /// 석조무사 텍스처 — 구 StoneGuardNode.textureCache 흡수.
    static func stoneGuardTexture(direction: PixelDirection, frame: PixelFrame) -> SKTexture {
        if let cached = stoneGuardCache[direction]?[frame] { return cached }
        let texture = PixelSpriteRenderer.texture(
            from: PixelSprite.stoneGuardData(direction: direction, frame: frame),
            palette: PixelPalette.stoneGuardPalette
        )
        stoneGuardCache[direction, default: [:]][frame] = texture
        return texture
    }

    // MARK: - Items (음표 / A — 구 init마다 반복 렌더분의 캐시화)
    // R2 — F/청진기 단품 캐시는 베이크 캐시(fProjectileBakedCache 외 2종)로 대체.
    private static var noteCache: SKTexture?
    private static var aItemCache: SKTexture?

    /// 음표 베이크 텍스처 한 변(pt) — halo 스트로크 바깥끝(반경 + lineWidth/2)이 정확히 담기는 크기.
    /// NoteNode sprite size와 베이크 캔버스가 이 단일 식을 공유해 크기 드리프트를 차단한다.
    /// (본체 noteSize 32pt·sparkle 바깥끝 ~10.1pt 모두 halo 바깥끝 반경 19pt 안 — halo가 최대 범위.)
    static var noteBakedSideLength: CGFloat {
        return (UILayout.noteReadableHaloRadius + UILayout.ingameObjectHaloLineWidth / 2) * 2
    }

    /// 음표 텍스처 — R1 2회차: 본체 16×16 픽셀아트 + 가독성 halo/sparkle(구 NoteNode 자식 2종,
    /// 액션이 전혀 없는 정적 셰이프)을 1장에 베이크 — 음표당 3→1노드(평시 노드 ≤300 게이트),
    /// 풀 예열 16회가 1회 렌더로 수렴.
    /// 시각 보존: 그리기 순서 = 구 zPosition 순(halo −1 → 본체 0 → sparkle +2), 색·알파·좌표·
    /// 반경 전부 구 자식과 동일 상수. UIKit y-down → sparkle의 SpriteKit (+x,+y) 오프셋은
    /// (cx+off, cy−off)로 매핑. 본체는 PixelSpriteRenderer.notePixelTexture()(무수정 — byte-equal)
    /// 결과를 interpolation .none으로 noteSize(32pt)에 확대 — SpriteKit .nearest 확대와 동일 픽셀 블록.
    static func noteTexture() -> SKTexture {
        if let cached = noteCache { return cached }
        let side = noteBakedSideLength
        let center = side / 2
        let haloRadius = UILayout.noteReadableHaloRadius
        let bodySide = GameplayTuning.noteSize
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            // 1) halo (구 자식 zPosition −1) — SKShapeNode 렌더 순서와 동일: fill 먼저, stroke가 위.
            let haloRect = CGRect(x: center - haloRadius, y: center - haloRadius,
                                  width: haloRadius * 2, height: haloRadius * 2)
            UIColor.ganhoIngameRewardMint
                .withAlphaComponent(UILayout.ingameObjectHaloAlpha * UILayout.ingameHalfAlphaMultiplier)
                .setFill()
            cg.fillEllipse(in: haloRect)
            UIColor.ganhoIngameReward
                .withAlphaComponent(UILayout.noteReadableHaloAlpha)
                .setStroke()
            cg.setLineWidth(UILayout.ingameObjectHaloLineWidth)
            cg.strokeEllipse(in: haloRect)
            // 2) 본체 픽셀아트 (구 zPosition 0) — 보간 끔 = .nearest 정수 2× 확대와 동일 픽셀 블록.
            cg.interpolationQuality = .none
            let bodyImage = UIImage(cgImage: PixelSpriteRenderer.notePixelTexture().cgImage())
            bodyImage.draw(in: CGRect(x: center - bodySide / 2, y: center - bodySide / 2,
                                      width: bodySide, height: bodySide))
            // 3) sparkle (구 자식 zPosition +2) — 우상단 흰 점.
            let sparkleRadius = UILayout.noteReadableSparkleRadius
            let sparkleOffset = haloRadius * UILayout.noteReadableSparkleOffsetRatio
            UIColor.ganhoPixelHudWhite.setFill()
            cg.fillEllipse(in: CGRect(x: center + sparkleOffset - sparkleRadius,
                                      y: center - sparkleOffset - sparkleRadius,
                                      width: sparkleRadius * 2,
                                      height: sparkleRadius * 2))
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        noteCache = texture
        return texture
    }

    /// A 아이템 12×12 (분홍).
    static func aItemTexture() -> SKTexture {
        if let cached = aItemCache { return cached }
        let texture = PixelSpriteRenderer.aItemTexture(color: Palette.aItemColor)
        aItemCache = texture
        return texture
    }

    // R2 베이크(F/청진기 가독성 통합·파티클 텍셀·걷기 먼지·병원 소품)는 TextureAtlasStore+R2.swift —
    // 본 파일 300줄 분리 규칙 준수. 캐시는 그 파일의 file-private 보관소(R2BakeCache)가 담당.

    // MARK: - Environment (R1 신규 — 바닥 1노드화 + 벽 타일 베이크)
    private static var checkerboardFloorCache: SKTexture?
    private static var wallTileCache: SKTexture?

    /// 체커보드 바닥 — 32×20px(1픽셀=1타일) 1회 렌더, sprite가 800×500pt로 .nearest 확대.
    /// 구 640노드 루프의 시각과 동일: ganhoIngameFloorA/B 2색, (c+r) 홀짝 교차.
    /// UIKit은 y가 아래로 증가 — 이미지 행을 SpriteKit row(아래가 0)로 뒤집어 패턴 보존.
    static func checkerboardFloorTexture() -> SKTexture {
        if let cached = checkerboardFloorCache { return cached }
        let columns = GameplayTuning.mapColumns
        let rows = GameplayTuning.mapRows
        let floorA = UIColor.ganhoIngameFloorA
        let floorB = UIColor.ganhoIngameFloorB
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: columns, height: rows))
        let image = renderer.image { ctx in
            for imageRow in 0..<rows {
                let spriteKitRow = rows - 1 - imageRow
                for column in 0..<columns {
                    let color = ((column + spriteKitRow) % 2 == 0) ? floorA : floorB
                    color.setFill()
                    ctx.fill(CGRect(x: column, y: imageRow, width: 1, height: 1))
                }
            }
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        checkerboardFloorCache = texture
        return texture
    }

    /// 벽 타일 25×25pt 베이크 — 본체 채움 + 하단 그림자 띠 + 상단 하이라이트 띠 + 검정 테두리.
    /// 구 WallTileNode 자식 3종(shadow/topLine/outline) 시각을 텍스처 1장으로 전 타일 공유 —
    /// 타일당 4노드 → 1노드 (R1 평시 노드 ≤300 게이트의 핵심).
    /// 허용 오차(SPEC): SKShapeNode stroke가 타일 경계 밖으로 나가던 절반(~1px)이 베이크 시
    /// 클립됨 — 인접 타일이 맞붙어(각자 안쪽 1px씩 = 2px 검정 경계) 시각 영향 무시 가능.
    static func wallTileTexture() -> SKTexture {
        if let cached = wallTileCache { return cached }
        let side = GameplayTuning.tileSize
        let size = CGSize(width: side, height: side)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            // 1) 본체 단색 채움 — 구 WallTileNode 본체 color.
            UIColor.ganhoIngameWallFill.setFill()
            cg.fill(CGRect(origin: .zero, size: size))
            // 2) 하단 그림자 띠 — 구 shadow 자식 (SpriteKit 하단 = UIKit 하단행).
            UIColor.ganhoIngameWallShadow.setFill()
            cg.fill(CGRect(x: 0,
                           y: side - UILayout.wallTileShadowHeight,
                           width: side,
                           height: UILayout.wallTileShadowHeight))
            // 3) 상단 하이라이트 띠 — 구 topLine 자식.
            UIColor.ganhoIngameWallHighlight.setFill()
            cg.fill(CGRect(x: 0, y: 0, width: side, height: UILayout.wallTileHighlightHeight))
            // 4) 검정 테두리 — 구 outline 자식 (stroke 중심이 경계라 안쪽 절반만 남음, 허용 오차).
            UIColor.ganhoPixelOutlineBlack.setStroke()
            cg.stroke(CGRect(origin: .zero, size: size), width: UILayout.ingameWallStrokeWidth)
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        wallTileCache = texture
        return texture
    }
}
