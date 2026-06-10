//
//  SceneRouter.swift
//  GanhoMusic Shared
//
//  R3 — 씬 전환 단일 진입점 (03_UI §9). SKTransition 생성은 *이 파일에서만* (R3 합격 게이트).
//  fade 전폐 → 진행 방향 push(앞으로=좌로 밀기 / 뒤로=우로 밀기) + 인게임 진입만 픽셀 디졸브.
//  push 커브 easeInOutQuad는 SKTransition 한계로 미적용 — duration 0.35만 준수 (SPEC 불일치 기록 10).
//  모든 route에서 전환 SFX 1회 (ChiptuneSynth.Voice.sceneTransition).
//

import SpriteKit

/// 씬 전환 라우터. case 없는 enum — 인스턴스화 차단 (상태 없음).
enum SceneRouter {

    /// 전환 의미 — 호출부는 방향 의미만 선언, 시각 스타일은 라우터가 단일 결정.
    enum Route {
        /// 플로우 전진 — 새 씬이 우→좌로 밀고 들어옴.
        case forward
        /// 플로우 역행(뒤로/그만두기/복귀) — 새 씬이 좌→우로 밀고 들어옴.
        case backward
        /// 인게임 진입 — 전환 없이 제시 후 픽셀 디졸브 인트로 (8px 체커 0.4s).
        case intoGame
    }

    /// 단일 제시 API. 씬 생성·선행 로직(저장/exit 애니)은 호출측 책임 — 여기선 전환만.
    static func present(_ scene: SKScene, on view: SKView, route: Route) {
        ChiptuneSynth.shared.play(.sceneTransition)
        switch route {
        case .forward:
            view.presentScene(scene, transition: pushTransition(direction: .left))
        case .backward:
            view.presentScene(scene, transition: pushTransition(direction: .right))
        case .intoGame:
            view.presentScene(scene)
            // presentScene 직후 didMove 완료 — cameraNode 등 호스트가 준비된 상태.
            (scene as? PixelDissolveReceiving)?.runPixelDissolveIntro()
        }
    }

    private static func pushTransition(direction: SKTransitionDirection) -> SKTransition {
        return SKTransition.push(with: direction,
                                 duration: FeelTuning.Motion.sceneTransition)
    }
}

// MARK: - PixelDissolveReceiving (03_UI §9 — 인게임 진입 디졸브)

/// 픽셀 디졸브 인트로 수신 씬. intoGame 라우트가 채택 씬에만 커버를 씌운다.
/// R3 채택: GameScene (GameScene+Transition.swift).
protocol PixelDissolveReceiving: SKScene {
    /// 디졸브 커버를 부착할 호스트 — 카메라 follow 씬은 cameraNode (씬 직부착 시 화면 밖 이탈).
    var pixelDissolveHostNode: SKNode { get }
}

extension PixelDissolveReceiving {
    /// 8px 블록 체커가 0.4s에 걸쳐 걷히며 새 씬이 드러남. 완료 시 커버 removeFromParent — 잔존 0.
    func runPixelDissolveIntro() {
        let host = pixelDissolveHostNode
        // 멱등 — 재진입 시 잔존 커버 제거 (좀비 차단).
        host.childNode(withName: PixelDissolve.coverName)?.removeFromParent()
        // 카메라 scale ≤ 1.0(iPad 0.62~1.0 클램프) — scene.size 커버가 화면 전체를 항상 덮는다.
        let cover = PixelDissolve.makeCover(size: size)
        host.addChild(cover)
        PixelDissolve.run(on: cover)
    }
}

// MARK: - PixelDissolve (구현 — 블록별 노드 격자 금지: 풀스크린 1장 + SKShader)

/// 디졸브 커버 빌더. 풀스크린 스프라이트 1장 + 셰이더 u_progress 진행 —
/// 노드 격자(수천 노드)·매 프레임 텍스처 생성 금지 제약의 충족 방식 (SPEC 기능 6).
private enum PixelDissolve {

    static let coverName = "r3PixelDissolveCover"
    private static let progressUniformName = "u_progress"
    private static let gridUniformName = "u_grid"
    private static let coverColorUniformName = "u_cover"
    /// 디졸브 진행 액션 키.
    private static let actionKey = "r3PixelDissolveProgress"

    /// 셰이더는 1회 컴파일 캐시 — 게임 진입마다 재컴파일 스톨 방지.
    /// 블록별 의사난수 임계 < u_progress 가 되는 순간 해당 8px 블록이 투명해진다.
    private static let shader: SKShader = {
        let source = """
        void main() {
            vec2 block = floor(v_tex_coord * u_grid);
            float threshold = fract(sin(dot(block, vec2(12.9898, 78.233))) * 43758.5453);
            float visible = step(u_progress, threshold);
            gl_FragColor = vec4(u_cover * visible, visible);
        }
        """
        let shader = SKShader(source: source)
        shader.uniforms = [
            SKUniform(name: progressUniformName, float: 0),
            SKUniform(name: gridUniformName, vectorFloat2: vector_float2(1, 1)),
            SKUniform(name: coverColorUniformName, vectorFloat3: ink900Vector())
        ]
        return shader
    }()

    /// ink900 토큰 → 셰이더 vec3 (hex 직접 사용 금지 — Palette 경유).
    private static func ink900Vector() -> vector_float3 {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        Palette.ink900.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return vector_float3(Float(red), Float(green), Float(blue))
    }

    /// 커버 생성 — 동시 디졸브는 1개뿐(단일 SKView)이라 공유 셰이더에 격자/진행만 재설정.
    static func makeCover(size: CGSize) -> SKSpriteNode {
        let cover = SKSpriteNode(color: Palette.ink900, size: size)
        cover.name = coverName
        cover.zPosition = ZOrder.Layer.transition
        cover.position = .zero
        shader.uniformNamed(gridUniformName)?.vectorFloat2Value = vector_float2(
            Float(size.width / UILayout.v3DissolveBlockSide),
            Float(size.height / UILayout.v3DissolveBlockSide)
        )
        shader.uniformNamed(progressUniformName)?.floatValue = 0
        cover.shader = shader
        return cover
    }

    /// 진행 0→1 (Motion.pixelDissolve 0.4s) 후 removeFromParent — 잔존 0 보장.
    static func run(on cover: SKSpriteNode) {
        let duration = FeelTuning.Motion.pixelDissolve
        let progress = SKAction.customAction(withDuration: duration) { _, elapsed in
            // 셰이더 uniform 1개 갱신만 — 노드·텍스처 생성 0 (매 프레임 텍스처 생성 금지 준수).
            let value = Float(min(max(elapsed / CGFloat(duration), 0), 1))
            shader.uniformNamed(progressUniformName)?.floatValue = value
        }
        cover.run(SKAction.sequence([progress, SKAction.removeFromParent()]),
                  withKey: actionKey)
    }
}
