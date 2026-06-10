//
//  FrameStats.swift
//  GanhoMusic Shared
//
//  R1 · DEBUG 전용 프레임 타임/노드 수 측정 라벨. 릴리즈 빌드에 코드·노드 0.
//  설계서: refactor/02_GAME_FEEL.md §1.
//

#if DEBUG
import SpriteKit

/// 좌상단 미니 진단 라벨 — 1초 평균 frame time + 씬 전체 노드 수(재귀 자손 카운트).
/// 왜: R1 "평시 노드 ≤300" 게이트와 R2 juice 작업의 프레임 예산을 기기에서 직접 검증하기 위함.
/// 파일 전체가 #if DEBUG 격리 — 릴리즈에 심볼/노드 0. 노드 수 재귀 카운트와 라벨 텍스트 갱신은
/// 1초 1회만(매 프레임 재귀 순회·텍스트 재생성 금지 규칙 준수).
final class FrameStats: SKLabelNode {

    /// 켜고 끄는 단일 스위치(컴파일 토글). false면 GameScene이 attach 자체를 건너뛴다.
    static let isEnabled: Bool = true

    // MARK: - DEBUG 전용 내부 상수
    // Config/ 오염 방지를 위해 파일 내 응집 — 릴리즈 미포함 수치를 라이브 Config에 두지 않는다.
    private static let refreshInterval: TimeInterval = 1.0
    private static let labelFontSize: CGFloat = 10
    private static let screenMarginX: CGFloat = 8
    /// HUD(좌상단 4슬롯) 바로 아래에 깔리도록 충분히 내린 상단 마진.
    private static let screenMarginY: CGFloat = 64
    private static let statsZPosition: CGFloat = 999

    // MARK: - State
    private var frameCount: Int = 0
    private var windowStartTime: TimeInterval = 0

    // MARK: - Lifecycle
    override init() {
        super.init()
        fontName = Typography.fontPixel
        fontSize = Self.labelFontSize
        fontColor = .ganhoPixelHudWhite
        horizontalAlignmentMode = .left
        verticalAlignmentMode = .top
        zPosition = Self.statsZPosition
        text = "--"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout
    /// cameraNode 자식 좌표계(중앙 0,0) 기준 좌상단 배치. attach 시 1회 호출.
    func place(in sceneSize: CGSize) {
        position = CGPoint(
            x: -(sceneSize.width / 2) + Self.screenMarginX,
            y: +(sceneSize.height / 2) - Self.screenMarginY
        )
    }

    // MARK: - Tick
    /// GameScene.update 말미에서 매 프레임 호출. 누적만 하고, 라벨 갱신/노드 카운트는 1초 1회.
    func tick(currentTime: TimeInterval) {
        if windowStartTime == 0 {
            windowStartTime = currentTime
            frameCount = 0
            return
        }
        frameCount += 1
        let elapsed = currentTime - windowStartTime
        guard elapsed >= Self.refreshInterval, frameCount > 0 else { return }
        let averageMs = elapsed / Double(frameCount) * 1000.0
        let nodeCount = scene.map { Self.countNodes(in: $0) } ?? 0
        text = String(format: "%.1fms · %d nodes", averageMs, nodeCount)
        windowStartTime = currentTime
        frameCount = 0
    }

    /// 재귀 자손 카운트(자기 포함). 1초 1회만 호출됨 — 매 프레임 호출 금지.
    private static func countNodes(in root: SKNode) -> Int {
        var count = 1
        for child in root.children {
            count += countNodes(in: child)
        }
        return count
    }
}
#endif
