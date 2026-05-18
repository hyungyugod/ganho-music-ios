# Phase 7-4 — 졸업장 시스템

## 개요
선택한 캐릭터로 easy/normal/hard 3난이도 모두에서 목표 점수(60/50/30)를 달성하면 ResultScene 진입 직후 황금 톤 졸업장(`DiplomaOverlayNode`)이 자동 표시된다. 졸업 일시는 캐릭터별로 *최초 1회만* 영속 저장되고 이후 기록 갱신 시에도 일시가 유지된다. 본 sprint는 캐릭터×난이도 매트릭스 저장소, 졸업 일시 저장소, 졸업장 노드(자가 소멸 11호) 세 신규 파일을 추가하고 GameScene.endGame과 ResultScene factory에 최소 5줄 연동을 추가한다.

## 변경 유형
**게임플레이 + UI 혼합**

## 게임 경험 의도
5캐릭터 × 3난이도 = 15 챌린지를 한 캐릭터로 완주한 사용자에게 *명시적 보상*과 *최초 일시 기록*으로 그 순간을 영구히 박제한다. 황금 톤 졸업장은 *서사적 마침표* — "다사다난한 실습을 마치고 졸업하였다"는 자전적 텍스트로 사용자의 간호 실습 자전 경험과 시간축을 잇는다.

## Sprint 범위 계약

### 허용
1. `GameConfig`에 졸업장 상수 ~14개 추가
2. `Repositories/PerDifficultyScoreRepository.swift` 신규 — 매트릭스 저장
3. `Repositories/GraduationRepository.swift` 신규 — 졸업 일시 저장
4. `Nodes/DiplomaOverlayNode.swift` 신규 — 자가 소멸 11호 (CutsceneOverlayNode 10호 동형)
5. `GameScene.endGame()` 확장 — 매트릭스 record + 졸업 판정 + ResultScene factory 인자 변경
6. `ResultScene` factory 시그니처에 `isNewGraduation: Bool = false`, `graduatedAt: Date? = nil` 추가 + setupLabels 끝에서 자동 표시
7. `pbxproj` 신규 3 파일 등록

### 금지
1. "졸업장 다시 보기" 버튼 — 다음 sprint
2. 졸업장 이미지 저장(UIImageWriteToSavedPhotosAlbum) — 다음 sprint
3. TitleScene 캐릭터 카드 졸업 뱃지 — 다음 sprint
4. 5×3 매트릭스 시각화 — 다음 sprint
5. HighScoreRepository 제거/마이그레이션 — 병행 유지
6. 캐릭터 픽셀 아바타를 졸업장에 그리기 — 텍스트 라벨만

### 판단 기준
"이 변경이 없으면 신규 졸업 자동 표시가 동작하지 않는가?" → YES만 허용.

## 변경 범위

### 수정
- `Config/GameConfig.swift` — `// MARK: - Diploma (Phase 7-4)` 섹션 + 상수 ~15개
- `GameScene.swift` — endGame() 끝부분 5줄 추가 + `isGraduated` static 헬퍼 추가 + 프로퍼티 2개
- `Scenes/ResultScene.swift` — factory/init 시그니처 2 인자 추가 + 프로퍼티 2개 + setupLabels 끝 자동 호출 + presentDiploma 메서드
- `GanhoMusic.xcodeproj/project.pbxproj` — 신규 3 파일 등록

### 신규
- `Repositories/PerDifficultyScoreRepository.swift`
- `Repositories/GraduationRepository.swift`
- `Nodes/DiplomaOverlayNode.swift`

---

## 기능 1: GameConfig 신규 상수

```swift
// MARK: - Diploma (Phase 7-4)
static let targetScoreByDifficulty: [Difficulty: Int] = [
    .easy: 60, .normal: 50, .hard: 30
]
static let perDifficultyScoreUserDefaultsKey: String = "perDifficultyScores"
static let graduationUserDefaultsKey: String = "graduations"
static let diplomaBackgroundAlpha: CGFloat = 0.92
static let diplomaZPosition: CGFloat = 300
static let diplomaFadeInDuration: TimeInterval = 0.4
static let diplomaFadeOutDuration: TimeInterval = 0.35
static let diplomaTitleEnFontSize: CGFloat = 26
static let diplomaTitleKoFontSize: CGFloat = 30
static let diplomaBodyFontSize: CGFloat = 18
static let diplomaIssuerFontSize: CGFloat = 14
static let diplomaDateFontSize: CGFloat = 14
static let diplomaTapFontSize: CGFloat = 14
static let diplomaTitleEnOffsetY: CGFloat = 150
static let diplomaTitleKoOffsetY: CGFloat = 110
static let diplomaBody1OffsetY: CGFloat = 30
static let diplomaBody2OffsetY: CGFloat = -10
static let diplomaIssuerOffsetY: CGFloat = -110
static let diplomaDateOffsetY: CGFloat = -110
static let diplomaTapLabelAlpha: CGFloat = 0.7
static let diplomaTapOffsetY: CGFloat = -160
static let diplomaBodyWidthRatio: CGFloat = 0.7
```

## 기능 2: PerDifficultyScoreRepository

UserDefaults JSON `[String: [String: Int]]` 직렬화. `CharacterID.rawValue × Difficulty.rawValue → Int`.

```swift
final class PerDifficultyScoreRepository {
    private let key: String
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard,
         key: String = GameConfig.perDifficultyScoreUserDefaultsKey) {
        self.defaults = defaults
        self.key = key
    }

    var current: [CharacterID: [Difficulty: Int]] {
        guard let data = defaults.data(forKey: key) else { return [:] }
        guard let raw = try? JSONDecoder().decode([String: [String: Int]].self, from: data) else { return [:] }
        var result: [CharacterID: [Difficulty: Int]] = [:]
        for (charRaw, inner) in raw {
            guard let charID = CharacterID(rawValue: charRaw) else { continue }
            var bucket: [Difficulty: Int] = [:]
            for (diffRaw, score) in inner {
                guard let diff = Difficulty(rawValue: diffRaw) else { continue }
                bucket[diff] = score
            }
            result[charID] = bucket
        }
        return result
    }

    func best(characterID: CharacterID, difficulty: Difficulty) -> Int {
        return current[characterID]?[difficulty] ?? 0
    }

    @discardableResult
    func record(characterID: CharacterID, difficulty: Difficulty, score: Int) -> Bool {
        var matrix = current
        let prior = matrix[characterID]?[difficulty] ?? 0
        guard score > prior else { return false }
        var bucket = matrix[characterID] ?? [:]
        bucket[difficulty] = score
        matrix[characterID] = bucket
        var raw: [String: [String: Int]] = [:]
        for (charID, inner) in matrix {
            var innerRaw: [String: Int] = [:]
            for (diff, s) in inner {
                innerRaw[diff.rawValue] = s
            }
            raw[charID.rawValue] = innerRaw
        }
        guard let data = try? JSONEncoder().encode(raw) else { return false }
        defaults.set(data, forKey: key)
        return true
    }
}
```

## 기능 3: GraduationRepository

UserDefaults JSON `[String: String]` (CharacterID.rawValue → ISO8601 Date string). record는 *이미 있으면 false* — 최초 졸업만 true.

```swift
final class GraduationRepository {
    private let key: String
    private let defaults: UserDefaults
    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    init(defaults: UserDefaults = .standard,
         key: String = GameConfig.graduationUserDefaultsKey) {
        self.defaults = defaults
        self.key = key
    }

    var current: [CharacterID: Date] {
        guard let data = defaults.data(forKey: key) else { return [:] }
        guard let raw = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        var result: [CharacterID: Date] = [:]
        for (charRaw, isoStr) in raw {
            guard let charID = CharacterID(rawValue: charRaw) else { continue }
            guard let date = isoFormatter.date(from: isoStr) else { continue }
            result[charID] = date
        }
        return result
    }

    func graduatedAt(characterID: CharacterID) -> Date? {
        return current[characterID]
    }

    @discardableResult
    func record(characterID: CharacterID, date: Date) -> Bool {
        var dict = current
        if dict[characterID] != nil { return false }
        dict[characterID] = date
        var raw: [String: String] = [:]
        for (charID, d) in dict {
            raw[charID.rawValue] = isoFormatter.string(from: d)
        }
        guard let data = try? JSONEncoder().encode(raw) else { return false }
        defaults.set(data, forKey: key)
        return true
    }
}
```

## 기능 4: GameScene.isGraduated 헬퍼

```swift
private static func isGraduated(characterID: CharacterID,
                                scores repo: PerDifficultyScoreRepository) -> Bool {
    let targets = GameConfig.targetScoreByDifficulty
    for difficulty in Difficulty.allCases {
        let target = targets[difficulty] ?? Int.max
        if repo.best(characterID: characterID, difficulty: difficulty) < target {
            return false
        }
    }
    return true
}
```

## 기능 5: DiplomaOverlayNode (자가 소멸 11호)

CutsceneOverlayNode 10호 동형. 황금 톤 배경 + 검정 글자 = 증서 톤. 7개 라벨: 영문 제목, 한글 제목, 본문 1, 본문 2, 발급, 일시, TAP 안내.

```swift
final class DiplomaOverlayNode: SKNode, SelfDismissingNode {
    private let background: SKSpriteNode
    private let titleEnLabel: SKLabelNode
    private let titleKoLabel: SKLabelNode
    private let body1Label: SKLabelNode
    private let body2Label: SKLabelNode
    private let issuerLabel: SKLabelNode
    private let dateLabel: SKLabelNode
    private let tapLabel: SKLabelNode
    private var onDismiss: (() -> Void)?

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
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd"
        self.dateLabel = SKLabelNode(text: displayFormatter.string(from: graduatedAt))
        self.tapLabel = SKLabelNode(text: "TAP TO CONTINUE")
        super.init()
        name = "diplomaOverlay"
        zPosition = GameConfig.diplomaZPosition
        isUserInteractionEnabled = true
        configureBackground()
        configureLabels(sceneSize: sceneSize)
        for label in [titleEnLabel, titleKoLabel, body1Label, body2Label, issuerLabel, dateLabel, tapLabel] {
            label.fontColor = .black
        }
        addChild(background)
        addChild(titleEnLabel); addChild(titleKoLabel)
        addChild(body1Label); addChild(body2Label)
        addChild(issuerLabel); addChild(dateLabel)
        addChild(tapLabel)
        alpha = 0
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    static func present(characterName: String, graduatedAt: Date,
                        parent: SKNode, sceneSize: CGSize, anchor: CGPoint,
                        onDismiss: @escaping () -> Void) {
        let node = DiplomaOverlayNode(characterName: characterName,
                                       graduatedAt: graduatedAt, sceneSize: sceneSize)
        node.onDismiss = onDismiss
        node.position = anchor
        parent.addChild(node)
        node.run(SKAction.fadeIn(withDuration: GameConfig.diplomaFadeInDuration))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismiss()
    }

    private func dismiss() {
        isUserInteractionEnabled = false
        let callback = onDismiss
        onDismiss = nil
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.diplomaFadeOutDuration)
        let cleanup = SKAction.removeFromParent()
        let notify = SKAction.run { callback?() }
        run(.sequence([fadeOut, cleanup, notify]))
    }

    private func configureBackground() {
        background.position = .zero
        background.zPosition = 0
    }

    private func configureLabels(sceneSize: CGSize) {
        let halfBodyWidth = sceneSize.width * GameConfig.diplomaBodyWidthRatio / 2
        titleEnLabel.fontSize = GameConfig.diplomaTitleEnFontSize
        titleEnLabel.position = CGPoint(x: 0, y: GameConfig.diplomaTitleEnOffsetY)
        titleKoLabel.fontSize = GameConfig.diplomaTitleKoFontSize
        titleKoLabel.position = CGPoint(x: 0, y: GameConfig.diplomaTitleKoOffsetY)
        body1Label.fontSize = GameConfig.diplomaBodyFontSize
        body1Label.position = CGPoint(x: 0, y: GameConfig.diplomaBody1OffsetY)
        body1Label.numberOfLines = 0
        body1Label.preferredMaxLayoutWidth = sceneSize.width * GameConfig.diplomaBodyWidthRatio
        body2Label.fontSize = GameConfig.diplomaBodyFontSize
        body2Label.position = CGPoint(x: 0, y: GameConfig.diplomaBody2OffsetY)
        body2Label.numberOfLines = 0
        body2Label.preferredMaxLayoutWidth = sceneSize.width * GameConfig.diplomaBodyWidthRatio
        issuerLabel.fontSize = GameConfig.diplomaIssuerFontSize
        issuerLabel.horizontalAlignmentMode = .right
        issuerLabel.position = CGPoint(x: +halfBodyWidth, y: GameConfig.diplomaIssuerOffsetY)
        dateLabel.fontSize = GameConfig.diplomaDateFontSize
        dateLabel.horizontalAlignmentMode = .left
        dateLabel.position = CGPoint(x: -halfBodyWidth, y: GameConfig.diplomaDateOffsetY)
        tapLabel.fontSize = GameConfig.diplomaTapFontSize
        tapLabel.alpha = GameConfig.diplomaTapLabelAlpha
        tapLabel.position = CGPoint(x: 0, y: GameConfig.diplomaTapOffsetY)
        for label in [titleEnLabel, titleKoLabel, body1Label, body2Label, tapLabel] {
            label.horizontalAlignmentMode = .center
        }
        for label in [titleEnLabel, titleKoLabel, body1Label, body2Label, issuerLabel, dateLabel, tapLabel] {
            label.verticalAlignmentMode = .center
            label.zPosition = 1
        }
    }
}
```

## 기능 6: GameScene.endGame() 확장

```swift
// 기존 코드 유지:
let score = scoreSystem.score
let isNewBest = highScoreRepo.record(score)
let bestScore = highScoreRepo.current
statsRepo.recordPlay(score: score)
let stats = statsRepo.current

// Phase 7-4 신규:
perDiffRepo.record(characterID: characterID, difficulty: difficulty, score: score)
var isNewGraduation = false
if GameScene.isGraduated(characterID: characterID, scores: perDiffRepo) {
    isNewGraduation = graduationRepo.record(characterID: characterID, date: Date())
}
let graduatedAt = graduationRepo.graduatedAt(characterID: characterID)

let resultScene = ResultScene.newResultScene(
    score: score, bestScore: bestScore, isNewBest: isNewBest, stats: stats,
    characterName: characterID.displayName,
    difficulty: difficulty,
    isNewGraduation: isNewGraduation,
    graduatedAt: graduatedAt
)
view.presentScene(resultScene, transition: .fade(withDuration: GameConfig.sceneTransitionDuration))
```

프로퍼티 2개 추가 (GameScene 클래스):
```swift
let perDiffRepo = PerDifficultyScoreRepository()
let graduationRepo = GraduationRepository()
```

## 기능 7: ResultScene 변경

프로퍼티:
```swift
private let isNewGraduation: Bool
private let graduatedAt: Date?
```

factory:
```swift
class func newResultScene(
    score: Int, bestScore: Int, isNewBest: Bool, stats: GameStats,
    characterName: String, difficulty: Difficulty,
    isNewGraduation: Bool = false, graduatedAt: Date? = nil
) -> ResultScene { ... }
```

setupLabels 끝부분:
```swift
if isNewBest {
    configureNewBestLabel()
    scheduleNewBestReveal()
}
// Phase 7-4
if isNewGraduation, let graduatedAt = graduatedAt {
    presentDiploma(at: graduatedAt)
}
```

presentDiploma:
```swift
private func presentDiploma(at graduatedAt: Date) {
    DiplomaOverlayNode.present(
        characterName: characterName,
        graduatedAt: graduatedAt,
        parent: self,
        sceneSize: size,
        anchor: CGPoint(x: frame.midX, y: frame.midY),
        onDismiss: {}
    )
}
```

## 기능 8: pbxproj 등록

CutsceneOverlayNode 등록 패턴 답습. PBXBuildFile / PBXFileReference / 그룹 children / Sources build phase 4지점. tvOS/macOS Sources 빈 채.

---

## 회귀 0 자연 차단

1. **HighScoreRepository 병행 유지** — 단일 점수 사용처 무영향
2. **ResultScene factory default 인자** — 미명시 시 졸업장 미발화
3. **DiplomaOverlayNode 자가 소멸** — ARC 정리. ResultScene 흐름 영향 0
4. **GraduationRepository.record 멱등** — 이미 졸업 시 false → 매번 표시 안 함
5. **graduatedAt nil 가드** — `if isNewGraduation, let graduatedAt`
6. **신규 UserDefaults 키** — 기존 키와 충돌 0
7. **DiplomaOverlayNode zPosition 300** — NewBest 라벨(150) 위 자연 겹침

## 영구 저장 정책
- JSON 직렬화 (JSONEncoder/JSONDecoder + Data)
- ISO8601 Date 형식 (로케일 안전, UTC)
- 표시용: DateFormatter("yyyy-MM-dd")
- 마이그레이션 미적용 (신규 키는 빈 dict 시작)

## 주의사항

1. **ISO8601 Date** — `.deferredToDate` 대신 `ISO8601DateFormatter` 사용. 디버그 가능 + 로케일 안전.
2. **UserDefaults JSON 패턴** — StatisticsRepository 답습. `try?`로 graceful 실패.
3. **enum → rawValue 직렬화** — `[String: [String: Int]]` 중간 변환. 강제 언래핑 0.
4. **신규 vs 기존 졸업** — `record` false 반환 = 이미 졸업 → 매번 미표시.
5. **dismiss 후 ResultScene 그대로** — onDismiss 빈 클로저. 두 단계 탭 정책.
6. **점수 두 군데 저장** — UserDefaults atomic 보장. 트랜잭션 분리 가능.
7. **Date 영속화** — 일시 보존이 핵심. 한 번 졸업한 사람의 일시 영원 동일.
8. **factory default 인자** — 회귀 0 보장.
9. **parent = scene 자체** — cameraNode 없음. anchor = `(frame.midX, frame.midY)` 화면 중앙.
10. **diplomaTapFontSize 별도** — 작은 안내문 톤.
11. **SelfDismissingNode marker** — 미래 protocol extension 호환.
12. **GraduationRepository encode 실패 graceful** — false 반환 → isNewGraduation false → 졸업장 미표시.
