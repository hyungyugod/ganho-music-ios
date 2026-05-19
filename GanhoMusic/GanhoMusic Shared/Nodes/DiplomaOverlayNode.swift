//
//  DiplomaOverlayNode.swift
//  GanhoMusic Shared
//
//  Phase 7-4 · 졸업장 오버레이 (자가 소멸 노드 11호) — 15 챌린지 완주 후 ResultScene에서 자동 표시
//  Sprint 5 · 우드컷 종이 카드 + 도트 패턴 + 더블 보더 + 코너 데코 + 도장 + 명조 폰트
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
/// **dismiss 후 ResultScene 그대로** — onDismiss 빈 클로저. 졸업장 닫힘 → 결과 화면 노출 → 탭 → StartScene
/// 의 *두 단계 탭* 정책 (졸업장 닫기 1탭 + StartScene 복귀 1탭).
///
/// Spring 비유: `@PostMapping` 컨트롤러의 응답 페이지 — 비즈니스 로직 완료 직후 *증서를 발급*하고
/// 사용자의 confirmation 1회로 dispose.
///
/// Sprint 5 — 우드컷 종이 카드(520×320 회전 -2°) + 도트 패턴(1100개 단일 path) + ㄱ자 코너 데코 +
/// 우하단 도장 + 명조 폰트(GowunBatang-Regular). 본문 텍스트·dismiss 시퀀스·present 시그니처는 *0건 변경*.
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

    // Sprint 5 — 우드컷 종이 카드 자식 노드들
    /// 종이 카드 본체 SKShapeNode(520×320, cornerRadius=8, fill=ganhoDiplomaPaper, stroke=ganhoDiplomaBorder, lineWidth=4, -2° 회전).
    private let paperCard: SKShapeNode
    /// 우드컷 도트 패턴(단일 SKShapeNode + CGMutablePath addEllipse 1100개 누적 — 노드 1개 통합으로 성능 안전).
    private let dotsPattern: SKShapeNode
    /// 좌상단 ㄱ자 코너 데코.
    private let topLeftBorder: SKShapeNode
    /// 우하단 ㄱ자 코너 데코.
    private let bottomRightBorder: SKShapeNode
    /// 우하단 도장 원(반지름 28, stroke=coralShadow, -12° 회전).
    private let stamp: SKShapeNode
    /// 도장 라벨 "김간호\n음악대학" (Jua 9pt, coralShadow).
    private let stampLabel: SKLabelNode

    // MARK: - Init (private — present factory에서만 호출)
    /// 캐릭터 이름 + 졸업 일시 + sceneSize를 받아 자식 노드 구성 (background + paperCard + 우드컷 + 라벨 7개 + 도장).
    /// `private init` — 외부 호출자가 *반드시* `present` 정적 팩토리를 거치도록 강제 (CutsceneOverlayNode 10호 답습).
    /// 본문 텍스트는 *Phase 7-4 시점 그대로* — Sprint 5는 시각만 추가, 본문 문자열 0건 변경.
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

        // Sprint 5 — 우드컷 자식들 init.
        self.paperCard = SKShapeNode()
        self.dotsPattern = SKShapeNode()
        self.topLeftBorder = SKShapeNode()
        self.bottomRightBorder = SKShapeNode()
        self.stamp = SKShapeNode(circleOfRadius: GameConfig.diplomaStampRadiusV2)
        self.stampLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)

        super.init()
        name = "diplomaOverlay"
        zPosition = GameConfig.diplomaZPosition
        // 자기 자신이 touchesBegan을 받기 위해 true 필수 — CutsceneOverlayNode 답습.
        isUserInteractionEnabled = true
        configureBackground()
        configureLabels(sceneSize: sceneSize)
        // Sprint 5 — 글자색을 명조 톤 분기. titleEn/issuer/date/tap = TextMuted, titleKo/body1/body2 = TextDeep.
        // 모든 라벨 fontName은 명조(GowunBatang-Regular)로 교체 — ttf 부재 시 시스템 fallback.
        for label in [titleEnLabel, issuerLabel, dateLabel, tapLabel] {
            label.fontColor = .ganhoDiplomaTextMuted
            label.fontName = GameConfig.fontSerif
        }
        for label in [titleKoLabel, body1Label, body2Label] {
            label.fontColor = .ganhoDiplomaTextDeep
            label.fontName = GameConfig.fontSerif
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
    /// Sprint 5 — 황금 배경 위에 우드컷 종이 카드 + 도트 패턴 + 코너 데코 + 도장을 부착.
    private func configureBackground() {
        background.position = .zero
        background.zPosition = 0   // 본 노드 좌표계 내부 z — 라벨이 배경 위에 보이도록 0.

        // Sprint 5 우드컷 시각 빌드 — 순서는 z 누적 흐름.
        buildPaperCard()
        buildDotsPattern()
        buildCornerDeco()
        buildStamp()
    }

    /// Sprint 5 — 종이 카드 본체. ganhoDiplomaPaper 채움 + ganhoDiplomaBorder stroke(lineWidth=4) + -2° 회전.
    /// CGPath roundedRect로 cornerRadius=8 라운드.
    private func buildPaperCard() {
        let halfW = GameConfig.diplomaPaperWidthV2 / 2
        let halfH = GameConfig.diplomaPaperHeightV2 / 2
        paperCard.path = CGPath(
            roundedRect: CGRect(
                x: -halfW,
                y: -halfH,
                width: GameConfig.diplomaPaperWidthV2,
                height: GameConfig.diplomaPaperHeightV2
            ),
            cornerWidth: GameConfig.diplomaPaperCornerRadiusV2,
            cornerHeight: GameConfig.diplomaPaperCornerRadiusV2,
            transform: nil
        )
        paperCard.fillColor = .ganhoDiplomaPaper
        paperCard.strokeColor = .ganhoDiplomaBorder
        paperCard.lineWidth = GameConfig.diplomaPaperBorderLineWidthV2
        // mockup transform: rotate(-2deg) — degree → radian.
        paperCard.zRotation = GameConfig.diplomaPaperRotationDegreesV2 * .pi / 180
        paperCard.zPosition = GameConfig.diplomaPaperZPositionV2
        addChild(paperCard)
    }

    /// Sprint 5 — 우드컷 도트 패턴. 단일 SKShapeNode + CGMutablePath addEllipse 누적(노드 1개 통합).
    /// 12pt 격자 × 520×320 → 약 1100개 도트가 한 path에 누적되어 SpriteKit 드로우콜 1회로 처리.
    /// 종이 카드와 동일 -2° 회전으로 통째로 함께 기울어짐.
    private func buildDotsPattern() {
        let cardW = GameConfig.diplomaPaperWidthV2
        let cardH = GameConfig.diplomaPaperHeightV2
        let step = GameConfig.diplomaDotStepV2
        let radius = GameConfig.diplomaDotRadiusV2

        let path = CGMutablePath()
        var x = -cardW / 2 + step
        while x < cardW / 2 {
            var y = -cardH / 2 + step
            while y < cardH / 2 {
                path.addEllipse(in: CGRect(
                    x: x - radius,
                    y: y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                y += step
            }
            x += step
        }
        dotsPattern.path = path
        dotsPattern.fillColor = UIColor(hex: GameConfig.diplomaDotHexV2)
            .withAlphaComponent(GameConfig.diplomaDotAlphaV2)
        dotsPattern.strokeColor = .clear
        dotsPattern.lineWidth = 0
        dotsPattern.zRotation = GameConfig.diplomaPaperRotationDegreesV2 * .pi / 180
        dotsPattern.zPosition = GameConfig.diplomaDotsZPositionV2
        addChild(dotsPattern)
    }

    /// Sprint 5 — 좌상단·우하단 ㄱ자 코너 데코. 두 SKShapeNode 부착(각자 CGMutablePath addLines 2변).
    /// strokeColor=ganhoDiplomaBorder, lineWidth=3. 종이와 같은 -2° 회전.
    private func buildCornerDeco() {
        let cornerSize = GameConfig.diplomaCornerDecoSizeV2
        let inset = GameConfig.diplomaCornerDecoInsetV2
        let halfW = GameConfig.diplomaPaperWidthV2 / 2
        let halfH = GameConfig.diplomaPaperHeightV2 / 2

        // 좌상단: ㄱ자 (왼쪽 변 ↓ + 위쪽 변 →) — paperCard 좌상단 모서리 안쪽 inset만큼 들어감.
        let tlPath = CGMutablePath()
        let tlOriginX = -halfW + inset
        let tlOriginY = halfH - inset
        tlPath.move(to: CGPoint(x: tlOriginX, y: tlOriginY - cornerSize))
        tlPath.addLine(to: CGPoint(x: tlOriginX, y: tlOriginY))
        tlPath.addLine(to: CGPoint(x: tlOriginX + cornerSize, y: tlOriginY))
        topLeftBorder.path = tlPath
        topLeftBorder.strokeColor = .ganhoDiplomaBorder
        topLeftBorder.fillColor = .clear
        topLeftBorder.lineWidth = GameConfig.diplomaCornerDecoLineWidthV2
        topLeftBorder.zRotation = GameConfig.diplomaPaperRotationDegreesV2 * .pi / 180
        topLeftBorder.zPosition = GameConfig.diplomaCornerDecoZPositionV2
        addChild(topLeftBorder)

        // 우하단: ㄴ자 (오른쪽 변 ↑ + 아래쪽 변 ←).
        let brPath = CGMutablePath()
        let brOriginX = halfW - inset
        let brOriginY = -halfH + inset
        brPath.move(to: CGPoint(x: brOriginX, y: brOriginY + cornerSize))
        brPath.addLine(to: CGPoint(x: brOriginX, y: brOriginY))
        brPath.addLine(to: CGPoint(x: brOriginX - cornerSize, y: brOriginY))
        bottomRightBorder.path = brPath
        bottomRightBorder.strokeColor = .ganhoDiplomaBorder
        bottomRightBorder.fillColor = .clear
        bottomRightBorder.lineWidth = GameConfig.diplomaCornerDecoLineWidthV2
        bottomRightBorder.zRotation = GameConfig.diplomaPaperRotationDegreesV2 * .pi / 180
        bottomRightBorder.zPosition = GameConfig.diplomaCornerDecoZPositionV2
        addChild(bottomRightBorder)
    }

    /// Sprint 5 — 우하단 도장(원 r=28 + 라벨 "김간호\n음악대학"). -12° 회전.
    /// strokeColor=coralShadow, fillColor=반투명 pink. 도장과 라벨이 같은 회전·위치로 묶임.
    private func buildStamp() {
        stamp.strokeColor = .ganhoCoralShadow
        stamp.fillColor = UIColor.ganhoCoralLight
            .withAlphaComponent(GameConfig.diplomaStampFillAlphaV2)
        stamp.lineWidth = GameConfig.diplomaStampLineWidthV2
        stamp.position = CGPoint(
            x: GameConfig.diplomaStampOffsetXV2,
            y: GameConfig.diplomaStampOffsetYV2
        )
        stamp.zRotation = GameConfig.diplomaStampRotationDegreesV2 * .pi / 180
        stamp.zPosition = GameConfig.diplomaStampZPositionV2
        addChild(stamp)

        stampLabel.text = GameConfig.diplomaStampLabelText
        stampLabel.fontSize = GameConfig.diplomaStampLabelFontSizeV2
        stampLabel.fontColor = .ganhoCoralShadow
        stampLabel.numberOfLines = 0
        stampLabel.horizontalAlignmentMode = .center
        stampLabel.verticalAlignmentMode = .center
        stampLabel.position = .zero
        stampLabel.zPosition = 1
        stamp.addChild(stampLabel)
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
