//
//  CutsceneOverlayNode.swift
//  GanhoMusic Shared
//
//  Phase 7-3 · 인트로 컷씬 오버레이 (자가 소멸 노드 10호) — 게임 시작 직전 "어느 한적한 병동의 오후" 서사
//

import SpriteKit

/// 게임 시작 직전 화면 전체를 덮는 *서사형* 컷씬 오버레이.
/// PhysicsBody 부착 0 — 순수 시각. cameraNode 자식으로 화면 중앙 (0,0) 고정.
/// 자가 소멸 노드 패턴 답습 (AirplaneNode / AirforceOverlayNode / BombFlashNode / SparkleEffectNode /
/// HitFlashNode / ComboPopupNode / ComboBreakNode / CountdownNode / ScorePopupNode) —
/// 자가 소멸 노드 *10호*.
///
/// 자가 소멸 패턴의 *변형*: 기존 1~9호는 *시간 트리거*(SKAction.wait 후 자동 소멸)지만,
/// 본 노드는 *터치 트리거*(touchesBegan → dismiss). 시간 압박 없이 *사용자의 호흡*에 맞춘 서사 진행 —
/// 컷씬의 의도(이야기 인지 시간 보장)와 트리거 방식이 일치.
///
/// 외부 진입점은 정적 팩토리 `present(title:body:parent:sceneSize:onDismiss:)` 1개.
/// init은 private — 사용자 실수(position 설정 누락, isUserInteractionEnabled 미설정 등)를
/// *컴파일 타임에* 차단 (ScorePopupNode 9호 답습 패턴).
///
/// Spring 비유: Spring MVC의 interceptor preHandle — 본 비즈니스 로직(게임 시작) *직전*에 끼어들어
/// 사용자 인지 시간을 확보하고, 한 번의 응답(탭) 후 자기 자신을 disposable로 정리한다.
final class CutsceneOverlayNode: SKNode, SelfDismissingNode {

    // MARK: - Properties
    /// 반투명 검정 배경. 화면 전체 덮어 게임 월드 시각 분리. sceneSize와 동일 크기.
    private let background: SKSpriteNode
    /// 제목 라벨("어느 한적한 병동의 오후"). 본문 위쪽 (+cutsceneTitleOffsetY) 고정.
    private let titleLabel: SKLabelNode
    /// 본문 라벨(난이도별 분기 텍스트). 화면 중앙(0,0)에서 자동 줄바꿈 표시.
    private let bodyLabel: SKLabelNode
    /// "TAP TO CONTINUE" 안내 라벨. 본문 아래쪽 (-cutsceneTapOffsetY) 반투명 부속 안내.
    private let tapLabel: SKLabelNode
    /// 탭 1회로 호출되는 외부 콜백. dismiss 첫 줄에서 *캡처 후 nil 토글*하여 다중 탭 차단.
    /// [weak self] 캡처는 *외부 책임* — 본 노드 내부는 nil 토글로만 안전 확보.
    private var onDismiss: (() -> Void)?

    // MARK: - Init (private — present factory에서만 호출)
    /// 제목/본문 텍스트와 sceneSize를 받아 4-자식 노드 구성.
    /// `private init` — 외부 호출자가 *반드시* `present` 정적 팩토리를 거치도록 강제 →
    /// position 설정 누락 / isUserInteractionEnabled 미설정 같은 사용자 실수를
    /// 컴파일 타임에 차단 (ScorePopupNode 9호 패턴 답습).
    private init(title: String, body: String, sceneSize: CGSize) {
        self.background = SKSpriteNode(
            color: UIColor.black.withAlphaComponent(GameConfig.cutsceneBackgroundAlpha),
            size: sceneSize
        )
        self.titleLabel = SKLabelNode(text: title)
        self.bodyLabel = SKLabelNode(text: body)
        self.tapLabel = SKLabelNode(text: "TAP TO CONTINUE")
        super.init()
        name = "cutsceneOverlay"
        zPosition = GameConfig.cutsceneZPosition
        // 자기 자신이 touchesBegan을 받기 위해 true 필수 — SKNode 기본은 false.
        // 미설정 시 터치가 부모(cameraNode → scene)로 전파되어 컷씬 dismiss 트리거 누락.
        isUserInteractionEnabled = true
        configureBackground(sceneSize: sceneSize)
        configureTitleLabel()
        configureBodyLabel(sceneSize: sceneSize)
        configureTapLabel()
        addChild(background)
        addChild(titleLabel)
        addChild(bodyLabel)
        addChild(tapLabel)
        // 시작 alpha 0 — present 직후 fadeIn으로 부드럽게 등장.
        alpha = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Present (static factory — 외부 유일 진입점)
    /// 컷씬을 부모(cameraNode 권장)에 부착하고 fadeIn 발화. onDismiss는 탭 1회 후 호출.
    /// - Parameters:
    ///   - title: 제목 라벨 텍스트 (예: "어느 한적한 병동의 오후").
    ///   - body: 본문 라벨 텍스트. iOS 11+ 자동 줄바꿈 — `{NAME}` 등 토큰은 호출부에서 미리 치환.
    ///   - parent: 부착 부모. cameraNode 전달 권장 — 화면 중앙 고정 + 카메라 follow와 독립.
    ///   - sceneSize: 배경 크기/본문 폭 계산 기준. 호출부 `self.size` 전달.
    ///   - onDismiss: 탭 1회 후 fadeOut 종료 시 호출. [weak self] 캡처는 호출부 책임.
    static func present(
        title: String,
        body: String,
        parent: SKNode,
        sceneSize: CGSize,
        onDismiss: @escaping () -> Void
    ) {
        let node = CutsceneOverlayNode(title: title, body: body, sceneSize: sceneSize)
        node.onDismiss = onDismiss
        parent.addChild(node)
        // fadeIn — 등장 보간. ScorePopupNode·CountdownNode와 동형 자가 소멸 패턴.
        node.run(SKAction.fadeIn(withDuration: GameConfig.cutsceneFadeInDuration))
    }

    // MARK: - Touch Trigger
    /// 화면 어디든 탭하면 dismiss. 자기 자신이 isUserInteractionEnabled = true이고
    /// background 가 sceneSize 전체를 덮으므로 cameraNode 자식 좌표계 전 영역 터치 수신.
    /// 자가 소멸 1~9호와 달리 *시간 트리거*가 아닌 *사용자 트리거* — 컷씬 의도 반영.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismiss()
    }

    // MARK: - Dismiss
    /// 다중 탭 방지 + 콜백 1회 발화 + fadeOut + removeFromParent를 한 묶음으로 처리.
    /// 첫 줄에서 isUserInteractionEnabled = false 토글 — 페이드아웃 중 추가 탭이 들어와도
    /// touchesBegan 미발화. onDismiss = nil 캡처는 *콜백 1회만* 발화 보장의 2중 안전망.
    /// SKAction.run notify는 fadeOut 후 실행 — 노드 트리에서 *이미 빠진* 상태에서 게임 시동 보장.
    private func dismiss() {
        // 다중 탭 차단 — 페이드아웃 중 한 번 더 탭해도 무시.
        isUserInteractionEnabled = false
        // 콜백 1회 캡처 후 nil 토글 — onDismiss 중복 호출 차단(2중 안전망).
        let callback = onDismiss
        onDismiss = nil
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.cutsceneFadeOutDuration)
        // notify는 self 미사용 — [weak self] 불필요. CountdownNode.start 패턴 답습.
        let notify = SKAction.run { callback?() }
        let cleanup = SKAction.removeFromParent()
        // Sprint 8 Phase E — notify를 cleanup 전에 둔다. SKAction.sequence 안 removeFromParent
        // 이후 액션이 미발화될 위험을 회피해 onDismiss 콜백이 *반드시* 호출되도록 보장.
        run(.sequence([fadeOut, notify, cleanup]))
    }

    // MARK: - Configure (private)
    /// 배경 — sceneSize 전체 덮음. SKSpriteNode anchorPoint 기본 (0.5, 0.5) →
    /// position .zero (화면 중앙) 이면 화면 전 영역 덮음.
    private func configureBackground(sceneSize: CGSize) {
        background.position = .zero
        background.zPosition = 0   // 본 노드 좌표계 내부 z — 라벨이 배경 위에 보이도록 0.
    }

    /// 제목 라벨 — 화면 중앙 위쪽 +cutsceneTitleOffsetY, 흰빛(.ganhoPaper) 강조.
    /// 라벨은 본 노드 좌표계 (0, +offset)에 부착 → cameraNode 부착 시 화면 중앙 위쪽.
    private func configureTitleLabel() {
        titleLabel.fontSize = GameConfig.cutsceneTitleFontSize
        titleLabel.fontColor = .ganhoPaper
        titleLabel.verticalAlignmentMode = .center
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: GameConfig.cutsceneTitleOffsetY)
        titleLabel.zPosition = 1   // 배경(0) 위.
    }

    /// 본문 라벨 — 화면 중앙(0,0), 자동 줄바꿈. iOS 11+에서 numberOfLines = 0 + preferredMaxLayoutWidth 조합으로
    /// 한국어 본문이 폭 안에 들어가도록 자동 줄바꿈된다.
    /// 폭 = sceneSize.width × cutsceneBodyWidthRatio(0.7) — 양 가장자리 15% 여백.
    private func configureBodyLabel(sceneSize: CGSize) {
        bodyLabel.fontSize = GameConfig.cutsceneBodyFontSize
        bodyLabel.fontColor = .ganhoPaper
        bodyLabel.verticalAlignmentMode = .center
        bodyLabel.horizontalAlignmentMode = .center
        bodyLabel.position = .zero
        bodyLabel.zPosition = 1
        // iOS 11+ 자동 줄바꿈. numberOfLines = 0 → 줄 수 제한 없음 + preferredMaxLayoutWidth 기반 wrap.
        bodyLabel.numberOfLines = 0
        bodyLabel.preferredMaxLayoutWidth = sceneSize.width * GameConfig.cutsceneBodyWidthRatio
    }

    /// TAP 라벨 — 본문 아래쪽 -cutsceneTapOffsetY, 부속 안내 톤(alpha 0.7).
    /// titlePromptBlink(0.6초 깜빡임)과 달리 *정적 표시* — 컷씬 본문 가독성 우선(시각 노이즈 ↓).
    private func configureTapLabel() {
        tapLabel.fontSize = GameConfig.cutsceneTapFontSize
        tapLabel.fontColor = .ganhoPaper
        tapLabel.verticalAlignmentMode = .center
        tapLabel.horizontalAlignmentMode = .center
        tapLabel.position = CGPoint(x: 0, y: GameConfig.cutsceneTapOffsetY)
        tapLabel.zPosition = 1
        // 부속 안내 — 제목/본문(1.0) 대비 시각 위계.
        tapLabel.alpha = GameConfig.cutsceneTapLabelAlpha
    }
}
