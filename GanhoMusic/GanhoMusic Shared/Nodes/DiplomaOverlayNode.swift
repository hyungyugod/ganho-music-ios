//
//  DiplomaOverlayNode.swift
//  GanhoMusic Shared
//
//  Phase 7-4 · 졸업장 오버레이 (자가 소멸 노드 11호) — 15 챌린지 완주 후 ResultScene에서 자동 표시
//

import SpriteKit

/// 모든 난이도(easy/normal/hard) 목표 점수를 달성한 *최초* 순간 ResultScene에서 자동 표시되는
/// 황금 톤 졸업장 오버레이. PhysicsBody 부착 0 — 순수 시각.
///
/// 자가 소멸 노드 패턴 답습 (AirplaneNode / AirforceOverlayNode / BombFlashNode / SparkleEffectNode /
/// HitFlashNode / ComboPopupNode / ComboBreakNode / CountdownNode / ScorePopupNode / CutsceneOverlayNode) —
/// 자가 소멸 노드 *11호*.
///
/// **CutsceneOverlayNode 10호의 동형 변형**: 두 노드 모두 *터치 트리거*(touchesBegan → dismiss)
/// 패턴이고 private init + 정적 팩토리 + 7개 라벨 구성. 차이는 *톤* — 컷씬은 어두운 검정(이야기 시작),
/// 졸업장은 황금 노랑(서사 마침표). 두 노드 모두 사용자의 *호흡*에 맞춘 진행 — 시간 압박 0.
///
/// 외부 진입점은 정적 팩토리 `present(characterName:graduatedAt:parent:sceneSize:anchor:onDismiss:)` 1개.
/// init은 private — position 설정 누락 / isUserInteractionEnabled 미설정 같은 실수를 컴파일 타임에 차단.
///
/// **parent = ResultScene 자체** (cameraNode 없음). anchor = `(frame.midX, frame.midY)` 화면 중앙.
/// ResultScene은 cameraNode가 없으므로 GameScene용 CutsceneOverlayNode(cameraNode 자식)와 부착 방식 다름.
///
/// **dismiss 후 ResultScene 그대로** — onDismiss 빈 클로저. 졸업장 닫힘 → 결과 화면 노출 → 탭 → TitleScene
/// 의 *두 단계 탭* 정책 (졸업장 닫기 1탭 + TitleScene 복귀 1탭).
///
/// Spring 비유: `@PostMapping` 컨트롤러의 응답 페이지 — 비즈니스 로직 완료 직후 *증서를 발급*하고
/// 사용자의 confirmation 1회로 dispose.
final class DiplomaOverlayNode: SKNode, SelfDismissingNode {

    // MARK: - Properties
    /// 황금 톤 배경(.ganhoYellowF 0.92 alpha). 화면 전체 덮어 ResultScene 시각 분리. sceneSize와 동일 크기.
    private let background: SKSpriteNode
    /// 영문 제목 "CERTIFICATE OF GRADUATION". 한글 제목보다 살짝 작아 *부제* 톤.
    private let titleEnLabel: SKLabelNode
    /// 한글 제목 "실습 수료 증서". 주인공 — 폰트 30.
    private let titleKoLabel: SKLabelNode
    /// 본문 1 — "다사다난한 실습을 마치고 {NAME}는 드디어 졸업하였다." (캐릭터 이름 치환).
    private let body1Label: SKLabelNode
    /// 본문 2 — "이제 세상이라는 악보 위에 마음껏 노래를 부르며 자유롭게 살 것이다."
    private let body2Label: SKLabelNode
    /// 발급자 "hgfolio · 김간호는 음악박사". 우측 정렬, 작은 부속 정보.
    private let issuerLabel: SKLabelNode
    /// 일시 "yyyy-MM-dd". 좌측 정렬, issuer와 같은 y로 한 줄 좌우 배치.
    private let dateLabel: SKLabelNode
    /// "TAP TO CONTINUE" 안내 라벨. 반투명(0.7) 부속 안내. cutscene과 같은 톤.
    private let tapLabel: SKLabelNode
    /// 탭 1회로 호출되는 외부 콜백. dismiss 첫 줄에서 *캡처 후 nil 토글*하여 다중 탭 차단.
    /// [weak self] 캡처는 *외부 책임* — 본 노드 내부는 nil 토글로만 안전 확보.
    private var onDismiss: (() -> Void)?

    // MARK: - Init (private — present factory에서만 호출)
    /// 캐릭터 이름 + 졸업 일시 + sceneSize를 받아 8-자식 노드 구성 (background + 7 labels).
    /// `private init` — 외부 호출자가 *반드시* `present` 정적 팩토리를 거치도록 강제 (CutsceneOverlayNode 10호 답습).
    /// 색상 설계: 배경 = `.ganhoYellowF` 0.92 alpha (황금 종이), 글자 = `.black` (검정 잉크) — *증서* 톤.
    /// ColorTokens 신규 토큰 0건 — 기존 토큰 재사용.
    private init(characterName: String, graduatedAt: Date, sceneSize: CGSize) {
        self.background = SKSpriteNode(
            color: UIColor.ganhoYellowF.withAlphaComponent(GameConfig.diplomaBackgroundAlpha),
            size: sceneSize
        )
        self.titleEnLabel = SKLabelNode(text: "CERTIFICATE OF GRADUATION")
        self.titleKoLabel = SKLabelNode(text: "실습 수료 증서")
        let body1Template = "다사다난한 실습을 마치고 {NAME}는 드디어 졸업하였다."
        self.body1Label = SKLabelNode(
            text: body1Template.replacingOccurrences(of: "{NAME}", with: characterName)
        )
        self.body2Label = SKLabelNode(text: "이제 세상이라는 악보 위에 마음껏 노래를 부르며 자유롭게 살 것이다.")
        self.issuerLabel = SKLabelNode(text: "hgfolio · 김간호는 음악박사")
        // 표시용 DateFormatter — ISO8601(저장 형식)을 사람 가독 "yyyy-MM-dd"로 변환.
        // init 1회만 사용하므로 로컬 변수로 — 인스턴스 멤버 캐싱 불필요.
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd"
        self.dateLabel = SKLabelNode(text: displayFormatter.string(from: graduatedAt))
        self.tapLabel = SKLabelNode(text: "TAP TO CONTINUE")
        super.init()
        name = "diplomaOverlay"
        zPosition = GameConfig.diplomaZPosition
        // 자기 자신이 touchesBegan을 받기 위해 true 필수 — CutsceneOverlayNode 답습.
        isUserInteractionEnabled = true
        configureBackground()
        configureLabels(sceneSize: sceneSize)
        // 글자색 일괄 적용 — 황금 배경 위 검정 글자 = 증서 톤. ColorTokens 신규 0건.
        for label in [titleEnLabel, titleKoLabel, body1Label, body2Label, issuerLabel, dateLabel, tapLabel] {
            label.fontColor = .black
        }
        addChild(background)
        addChild(titleEnLabel)
        addChild(titleKoLabel)
        addChild(body1Label)
        addChild(body2Label)
        addChild(issuerLabel)
        addChild(dateLabel)
        addChild(tapLabel)
        // 시작 alpha 0 — present 직후 fadeIn으로 부드럽게 등장.
        alpha = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Present (static factory — 외부 유일 진입점)
    /// 졸업장을 부모(ResultScene 권장)에 부착하고 fadeIn 발화. onDismiss는 탭 1회 후 호출.
    /// - Parameters:
    ///   - characterName: 본문 1 `{NAME}` 토큰에 치환될 캐릭터 한국어 이름.
    ///   - graduatedAt: 졸업 일시. dateLabel에 "yyyy-MM-dd" 형식으로 표시.
    ///   - parent: 부착 부모. ResultScene 자체 전달 — cameraNode 없음.
    ///   - sceneSize: 배경 크기/본문 폭 계산 기준. 호출부 `self.size` 전달.
    ///   - anchor: 노드 자체의 position. `(frame.midX, frame.midY)` = ResultScene 화면 중앙.
    ///   - onDismiss: 탭 1회 후 fadeOut 종료 시 호출. *빈 클로저 권장* (두 단계 탭 정책).
    static func present(
        characterName: String,
        graduatedAt: Date,
        parent: SKNode,
        sceneSize: CGSize,
        anchor: CGPoint,
        onDismiss: @escaping () -> Void
    ) {
        let node = DiplomaOverlayNode(
            characterName: characterName,
            graduatedAt: graduatedAt,
            sceneSize: sceneSize
        )
        node.onDismiss = onDismiss
        node.position = anchor
        parent.addChild(node)
        // fadeIn — 등장 보간. CutsceneOverlayNode 답습.
        node.run(SKAction.fadeIn(withDuration: GameConfig.diplomaFadeInDuration))
    }

    // MARK: - Touch Trigger
    /// 화면 어디든 탭하면 dismiss. background 가 sceneSize 전체를 덮으므로 노드 좌표계 전 영역 터치 수신.
    /// CutsceneOverlayNode 10호와 완전 동형 — *사용자 호흡* 트리거 (시간 트리거 아님).
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismiss()
    }

    // MARK: - Dismiss
    /// 다중 탭 방지 + 콜백 1회 발화 + fadeOut + removeFromParent를 한 묶음으로 처리.
    /// CutsceneOverlayNode.dismiss와 완전 동형. nil 토글 + isUserInteractionEnabled false 2중 안전망.
    private func dismiss() {
        // 다중 탭 차단 — 페이드아웃 중 한 번 더 탭해도 무시.
        isUserInteractionEnabled = false
        // 콜백 1회 캡처 후 nil 토글 — onDismiss 중복 호출 차단(2중 안전망).
        let callback = onDismiss
        onDismiss = nil
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.diplomaFadeOutDuration)
        let cleanup = SKAction.removeFromParent()
        // notify는 self 미사용 — [weak self] 불필요. CutsceneOverlayNode 답습.
        let notify = SKAction.run { callback?() }
        run(.sequence([fadeOut, cleanup, notify]))
    }

    // MARK: - Configure (private)
    /// 배경 — sceneSize 전체 덮음. anchorPoint 기본 (0.5, 0.5) → position .zero (노드 좌표계 중앙) 이면
    /// 노드 전체가 부모 anchor를 중심으로 화면 전 영역 덮음. CutsceneOverlayNode 답습.
    private func configureBackground() {
        background.position = .zero
        background.zPosition = 0   // 본 노드 좌표계 내부 z — 라벨이 배경 위에 보이도록 0.
    }

    /// 7개 라벨의 위치/폰트/정렬을 설정.
    /// 영문 제목(+150) > 한글 제목(+110) > 본문1(+30) > 본문2(-10) > issuer/date(-110, 좌우 분리) > tap(-160).
    /// 본문 2줄은 numberOfLines = 0 + preferredMaxLayoutWidth 조합으로 자동 줄바꿈 (iOS 11+).
    /// issuer/date는 같은 y에 좌측/우측 정렬 — 화면 가로 70% 폭의 양 끝.
    private func configureLabels(sceneSize: CGSize) {
        // 본문 폭의 절반 — issuer(우측)/date(좌측) 배치에 사용.
        let halfBodyWidth = sceneSize.width * GameConfig.diplomaBodyWidthRatio / 2
        // 제목 영문 — 화면 위쪽 +150
        titleEnLabel.fontSize = GameConfig.diplomaTitleEnFontSize
        titleEnLabel.position = CGPoint(x: 0, y: GameConfig.diplomaTitleEnOffsetY)
        // 제목 한글 — 영문 아래 +110
        titleKoLabel.fontSize = GameConfig.diplomaTitleKoFontSize
        titleKoLabel.position = CGPoint(x: 0, y: GameConfig.diplomaTitleKoOffsetY)
        // 본문 1 — 화면 중앙 약간 위 +30, 자동 줄바꿈
        body1Label.fontSize = GameConfig.diplomaBodyFontSize
        body1Label.position = CGPoint(x: 0, y: GameConfig.diplomaBody1OffsetY)
        body1Label.numberOfLines = 0
        body1Label.preferredMaxLayoutWidth = sceneSize.width * GameConfig.diplomaBodyWidthRatio
        // 본문 2 — 화면 중앙 약간 아래 -10, 자동 줄바꿈
        body2Label.fontSize = GameConfig.diplomaBodyFontSize
        body2Label.position = CGPoint(x: 0, y: GameConfig.diplomaBody2OffsetY)
        body2Label.numberOfLines = 0
        body2Label.preferredMaxLayoutWidth = sceneSize.width * GameConfig.diplomaBodyWidthRatio
        // 발급자 — 우측 정렬, y -110
        issuerLabel.fontSize = GameConfig.diplomaIssuerFontSize
        issuerLabel.horizontalAlignmentMode = .right
        issuerLabel.position = CGPoint(x: +halfBodyWidth, y: GameConfig.diplomaIssuerOffsetY)
        // 일시 — 좌측 정렬, y -110 (issuer와 같은 y, 좌우 분리)
        dateLabel.fontSize = GameConfig.diplomaDateFontSize
        dateLabel.horizontalAlignmentMode = .left
        dateLabel.position = CGPoint(x: -halfBodyWidth, y: GameConfig.diplomaDateOffsetY)
        // TAP — 반투명(0.7) 부속 안내, y -160
        tapLabel.fontSize = GameConfig.diplomaTapFontSize
        tapLabel.alpha = GameConfig.diplomaTapLabelAlpha
        tapLabel.position = CGPoint(x: 0, y: GameConfig.diplomaTapOffsetY)
        // 가운데 정렬 라벨 5개 — issuer/date 제외 (좌우 분리 정렬 유지)
        for label in [titleEnLabel, titleKoLabel, body1Label, body2Label, tapLabel] {
            label.horizontalAlignmentMode = .center
        }
        // 공통: 수직 가운데 정렬 + 배경(0) 위로 보이도록 z=1.
        for label in [titleEnLabel, titleKoLabel, body1Label, body2Label, issuerLabel, dateLabel, tapLabel] {
            label.verticalAlignmentMode = .center
            label.zPosition = 1
        }
    }
}
