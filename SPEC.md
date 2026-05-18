# SPEC.md — Phase 7-1: 난이도 3단계 시스템(하/중/상)

## 개요
지금까지 게임은 *easy 1개 고정*으로만 돌고 있었다. 이번 sprint는 사용자가 TitleScene에서 **하/중/상 카드 1장**을 선택해 같은 게임 코드가 *다른 속도/빈도/음표 TTL*로 돌아가도록 한다. GDD §5 표가 단일 진실 원천(single source of truth)이며, 본 sprint의 모든 수치 차등은 그 표에서 직접 끌어온다.

## 변경 유형
**혼합** (게임플레이 수치 차등 + UI 카드 신설 + 영구 저장 + ResultScene 라벨)

Evaluator는 "Swift 패턴 일관성 35% + 게임 로직 30% + 성능/안정성 20% + 기능 완성도 15%"의 4축 가중 평가를 그대로 적용한다.

## 게임 경험 의도
"선택할 수 있는 자유"는 짧은 책임감을 만든다 — 내가 *상*을 골랐기에 빨라진 수간호사도 내 탓이고, *하*를 골랐기에 여유로운 음표 무한 TTL도 내 보상이다. 하/중/상은 *난이도 명칭*이 아니라 *같은 게임의 세 가지 톤*임을 텍스트로 가르치지 않고도 첫 5초 안에 체감하게 한다. 카드 색만 바뀌어도 사용자는 "이 게임은 내가 조절 가능하구나"를 학습한다.

## Sprint 범위 계약

### 허용 (이 변경 없으면 난이도 카드 선택 시 게임 수치가 안 바뀜 → YES)
1. `Models/Difficulty.swift` 신규 — enum + 부속 속성(displayName/storageKey/color/subtitle).
2. `Repositories/DifficultyPreferenceRepository.swift` 신규 — CharacterPreferenceRepository 동형 패턴.
3. `Config/GameConfig.swift` 수정 — 난이도별 차등 튜닝 표(dict) 추가 + 기존 *단일 상수*는 *easy 기준값으로 유지*(호환).
4. `Scenes/TitleScene.swift` 수정 — 난이도 카드 3장(DifficultyCardNode) 가로 배치 + 선택 핸들러 + 영구 저장 복원.
5. `Nodes/DifficultyCardNode.swift` 신규 — CharacterCardNode와 동형 컨테이너(SKNode 기반).
6. `GameScene.swift` 수정 — `init`에 `difficulty: Difficulty` 추가 + factory 시그니처 확장 + `apply(difficulty:)` 노드/시스템 호출.
7. `Nodes/PlayerNode.swift` 수정 — `apply(_ difficulty:)` 메서드 + `baseSpeedStart/End` 보간식 도입.
8. `Nodes/EnemyNode.swift` 수정 — `apply(_ difficulty:)` 메서드 + base/max 속도를 *인스턴스 프로퍼티*로 외부화.
9. `Systems/SpawnSystem.swift` 수정 — `apply(_ difficulty:)` 메서드 + noteMaxConcurrent/noteLifetime/projectileMaxConcurrent/burstCount/fireInterval(시작/끝) 모두 *인스턴스 프로퍼티*로 외부화.
10. `Nodes/NoteNode.swift` 수정 — 자가 소멸 SKAction(`SKAction.sequence([wait, fade, remove])`) 부착 메서드 추가. `.infinity` 또는 sentinel로 *easy 무한 TTL* 분기 처리.
11. `Scenes/ResultScene.swift` 수정 — 난이도 라벨 1줄 추가.
12. `pbxproj` — 신규 3개 .swift 파일(Difficulty / DifficultyPreferenceRepository / DifficultyCardNode) 등록.

### 금지 (이 변경 없어도 난이도 카드 작동 → NO, 다음 sprint로)
- **이교수 NPC** — 모델/노드 자체 미구현. *.hard 선택해도 이교수 등장 0건*. **다음 sprint 7-2(또는 별도)에서 처리**.
- **hard 맵** — 맵 변형 자체 미구현. *.normal/.hard 선택해도 easy 맵(중앙 기둥 1개) 그대로 사용*. GDD §5 "맵 종류" 컬럼은 다음 sprint.
- **석조무사 등장 여부 분기** — GDD §5는 normal까지 등장/hard 미등장이지만, 본 sprint는 *전 난이도에서 석조무사 등장 그대로* 둔다(회귀 0 우선). StoneGuardNode 코드 미접촉.
- **목표 점수 (60/50/30)** — 졸업장 sprint 직전에 적용. 본 sprint는 ResultScene 표기에만 *선택적* 활용 가능(권장: 표기도 생략).
- **인트로/경고/중간 컷씬 분기** — 컷씬 시스템 자체 미구현. 본 sprint 범위 외.
- **목표 점수 달성 추적, 졸업장** — 별도 sprint.

### 분리의 정당성
큰 sprint 1개를 회귀 위험 낮은 작은 sprint 여러 개로 쪼개야 빠른 사이클 가능. 본 sprint는 *수치 분기 + UI 1행* 두 축만 — 회귀 영역이 좁다. 한 번에 다 묶으면 회귀 영역이 *15+ 파일*로 폭증해 1차 합격 확률 급감.

### 판단 기준
"이 변경 없으면 난이도 카드 선택 시 게임 수치가 안 바뀌는가" → **YES만 허용**.

---

## Difficulty enum 정의 (의사 코드)

```swift
// Models/Difficulty.swift (신규)
import UIKit

/// 3 난이도 식별자. raw String — case 이름이 그대로 raw value("easy", "normal", "hard").
/// CaseIterable 채택으로 `.allCases` 자동 생성 — TitleScene이 3 카드 일괄 생성에 사용.
enum Difficulty: String, CaseIterable {
    case easy, normal, hard

    var displayName: String {
        switch self {
        case .easy:   return "하"
        case .normal: return "중"
        case .hard:   return "상"
        }
    }

    var subtitle: String {
        switch self {
        case .easy:   return "여유로운 실습"
        case .normal: return "긴장의 병동"
        case .hard:   return "이교수의 청진기"
        }
    }

    var color: UIColor {
        switch self {
        case .easy:   return .ganhoMint
        case .normal: return .ganhoYellowF
        case .hard:   return .ganhoBloodAccent
        }
    }
}
```

### 케이스 × 4 부속 속성 1:1 매핑 표
| case | rawValue (저장키) | displayName | subtitle | color (기존 토큰 재사용) |
|---|---|---|---|---|
| `.easy`   | `"easy"`   | "하" | "여유로운 실습"       | `.ganhoMint` |
| `.normal` | `"normal"` | "중" | "긴장의 병동"         | `.ganhoYellowF` |
| `.hard`   | `"hard"`   | "상" | "이교수의 청진기"     | `.ganhoBloodAccent` |

---

## GameConfig 차등 메서드 설계안 — 두 옵션 비교

현재 `GameConfig`는 **단일 상수** 구조(`static let noteMaxConcurrent: Int = 5` 등).

### 옵션 A — 함수 분기 (`func(for: Difficulty) -> T`)
- 장점: 호출부가 `GameConfig.noteMaxConcurrent(for: difficulty)`로 명시적.
- 단점: 12~14개 함수 추가 → GameConfig 비대. 기존 호출처 모두 변경. **회귀 영역 ↑**.

### 옵션 B — 튜닝 표(dict 리터럴) + 노드/시스템 자기 적용 ← **권장**
- 장점: 응집도 ↑. 기존 단일 상수가 *easy 기준값으로 유지* → apply(_:) 누락 시에도 graceful fallback. 새 호출처는 dict 1회 lookup만, 기존 호출처 0건 변경.
- 단점: 노드/시스템에 새 프로퍼티 4~6개 추가됨.
- Spring 비유: `@ConfigurationProperties` 동형.

### 권장: **옵션 B** 채택
1. **회귀 0 보장**: 기존 `GameConfig.playerBaseSpeed` 등 단일 상수 그대로 살아남음 → apply 누락 시 easy 동작 자연 fallback.
2. **CharacterID.playerSpeedMultiplier 패턴 답습**: 5-3에서 검증된 패턴.
3. **테스트 친화**: dict lookup + `?? default` 으로 nil 안전.

---

## 변경 파일 목록 + 라인 컨텍스트

### 신규
| 파일 | 역할 |
|---|---|
| `GanhoMusic Shared/Models/Difficulty.swift` | enum + 4 부속 속성 |
| `GanhoMusic Shared/Repositories/DifficultyPreferenceRepository.swift` | UserDefaults 영구 저장 (CharacterPreferenceRepository 동형) |
| `GanhoMusic Shared/Nodes/DifficultyCardNode.swift` | SKNode 컨테이너 + 배경 색 사각형 + 한글 라벨 + 부제 라벨 + 선택 알파/scale 토글 (CharacterCardNode 동형) |

### 수정
| 파일 | 변경 위치(라인 힌트) | 변경 내용 |
|---|---|---|
| `Config/GameConfig.swift` | §"Note"(L56~62), §"Enemy"(L88~97), §"Projectile"(L99~110), §"Player"(L36~41) 인접 | 차등 dict 9개 + UI/저장 키 상수 8개 추가. 기존 단일 상수 미접촉. |
| `Scenes/TitleScene.swift` | L27 properties / L42 didMove / L120 setup / L159 touchesBegan | 신규 프로퍼티 3개. didMove에 복원 + setup. touchesBegan에 난이도 hit test 우선 분기. newGameScene 호출에 `difficulty:` 인자. |
| `GameScene.swift` | L102~121 init/factory / setupPlayer/setupEnemy / startGameProperly | `let difficulty: Difficulty` + init/factory 시그니처 확장 + 노드/시스템 `apply(difficulty)` 호출 3줄. |
| `Nodes/PlayerNode.swift` | properties / apply 인접 | `baseSpeedStart/End` 인스턴스 프로퍼티 + `apply(_ difficulty:)` 메서드. update에서 `baseSpeedStart × speedMultiplier`. |
| `Nodes/EnemyNode.swift` | init / update 보간식 | `baseSpeedStart/End` 인스턴스 프로퍼티 + `apply(_ difficulty:)` 메서드. update 보간식이 GameConfig → self 참조로 변경. |
| `Systems/SpawnSystem.swift` | dependencies / trySpawnNote / fireProjectile | 인스턴스 프로퍼티 6개 + `apply(_ difficulty:)`. trySpawnNote에서 `note.applyLifetime(noteLifetime)`. fireProjectile에 burst 루프(easy=1로 회귀 0). |
| `Nodes/NoteNode.swift` | init 인접 | `applyLifetime(_ ttl:)` 메서드 신규. 가드: `ttl.isFinite, ttl < gameDuration`. 통과 시 wait+fade+remove 시퀀스. |
| `Scenes/ResultScene.swift` | properties / init / setupLabels / layoutLabels | `difficulty` 프로퍼티 + 라벨 1개 추가. newResultScene factory에 `difficulty:` 인자. |
| `pbxproj` | — | 신규 3 파일 등록(`xcode-import-guide.md` 답습). |

---

## TitleScene 카드 배치 안

### 현재 TitleScene 레이아웃 (L85~145)
```
frame.midY +80 : titleLabel ("김간호는 음악박사")
frame.midY +20 : bestLabel
frame.midY -20 : playsLabel
frame.midY -80 : promptLabel ("TAP TO START")
frame.midY -160: 5 캐릭터 카드 (가로 일렬)
```

### 권장 배치 — 캐릭터 카드 *위쪽*에 별도 행
```
frame.midY +80 : titleLabel
frame.midY +20 : bestLabel
frame.midY -20 : playsLabel
frame.midY -80 : promptLabel
frame.midY -120: 난이도 카드 3장 (하/중/상) ← 신규
frame.midY -200: 5 캐릭터 카드 (-160 → -200으로 한 칸 더 내림)
```

`characterCardOffsetY` 현재 -160 → -200으로 조정. 신규 `difficultyCardOffsetY: -120`.

### DifficultyCardNode 구조 (CharacterCardNode 동형)
```swift
final class DifficultyCardNode: SKNode {
    let id: Difficulty
    private let background: SKSpriteNode
    private let nameLabel: SKLabelNode
    private let subtitleLabel: SKLabelNode

    init(id: Difficulty) {
        self.id = id
        background = SKSpriteNode(color: id.color,
            size: CGSize(width: GameConfig.difficultyCardWidth,
                         height: GameConfig.difficultyCardHeight))
        nameLabel = SKLabelNode(text: id.displayName)
        subtitleLabel = SKLabelNode(text: id.subtitle)
        super.init()
        name = "difficultyCard_\(id.rawValue)"
        zPosition = 100
        addChild(background)
        configureLabels()
        addChild(nameLabel)
        addChild(subtitleLabel)
    }

    func setSelected(_ selected: Bool) {
        alpha = selected ? 1.0 : GameConfig.characterCardDeselectedAlpha
        let target = selected ? GameConfig.characterCardSelectedScale : 1.0
        removeAction(forKey: "cardScale")
        run(SKAction.scale(to: target, duration: GameConfig.characterCardScaleDuration), withKey: "cardScale")
    }
}
```

---

## GameScene init 시그니처 변경 — 영향 분석

### 현재 호출처
| 파일 | 라인 | 호출 |
|---|---|---|
| `GanhoMusic iOS/GameViewController.swift` | L27 | `TitleScene.newTitleScene()` ← GameScene 안 만듦. **영향 없음**. |
| `Scenes/TitleScene.swift` | L173 | `GameScene.newGameScene(characterID:)` ← **유일한 직접 호출** |
| `GanhoMusic macOS/GameViewController.swift` | L17 | `GameScene.newGameScene()` ← 미지원 타깃. default 인자로 자동 호환. |
| `GanhoMusic tvOS/GameViewController.swift` | L17 | `GameScene.newGameScene()` ← 동일. |

### 회귀 0 보장
1. `newGameScene(characterID: .kim, difficulty: .easy)` — **두 인자 모두 default**.
2. iOS의 TitleScene 호출 1군데만 `difficulty: selectedDifficulty` 추가.
3. macOS/tvOS(공식 미지원)는 기존 코드 그대로 컴파일 통과.

```swift
// TitleScene.touchesBegan
let gameScene = GameScene.newGameScene(
    characterID: selectedCharacterID,
    difficulty: selectedDifficulty   // ← 추가
)
```

---

## GameConfig 신규 상수 — GDD §5 표 1:1 매핑

### GDD §5 원본 표 (인용)
| 항목 | 하(easy) | 중(normal) | 상(hard) |
|---|---|---|---|
| 플레이어 속도 | 140→210 px/s | 160→250 px/s | 160→250 px/s |
| 동시 음표 수 | 5개 | 4개 | 4개 |
| 음표 TTL | 무한 | 3.5초 | 2.8초 |
| 수간호사 속도 | 60→110 px/s | 170→290 px/s | 200→340 px/s |
| F 최대 동시 수 | 2개 | 10개 | 14개 |
| 동시 F 투척 수 | 1개 | 3개 | 4개 |
| F 투척 주기 | 3.5→2.0초 | 1.0→0.35초 | 0.8→0.25초 |

### dict 리터럴 의사 코드
```swift
// MARK: - Difficulty (Phase 7-1)
static let playerSpeedStartByDifficulty: [Difficulty: CGFloat] = [
    .easy: 140, .normal: 160, .hard: 160
]
static let playerSpeedEndByDifficulty: [Difficulty: CGFloat] = [
    .easy: 210, .normal: 250, .hard: 250
]
static let enemySpeedStartByDifficulty: [Difficulty: CGFloat] = [
    .easy: 60, .normal: 170, .hard: 200
]
static let enemySpeedEndByDifficulty: [Difficulty: CGFloat] = [
    .easy: 110, .normal: 290, .hard: 340
]
static let noteMaxConcurrentByDifficulty: [Difficulty: Int] = [
    .easy: 5, .normal: 4, .hard: 4
]
static let noteLifetimeByDifficulty: [Difficulty: TimeInterval] = [
    .easy: .infinity, .normal: 3.5, .hard: 2.8
]
static let projectileMaxConcurrentByDifficulty: [Difficulty: Int] = [
    .easy: 2, .normal: 10, .hard: 14
]
static let projectileBurstCountByDifficulty: [Difficulty: Int] = [
    .easy: 1, .normal: 3, .hard: 4
]
static let projectileFireIntervalStartByDifficulty: [Difficulty: TimeInterval] = [
    .easy: 3.5, .normal: 1.0, .hard: 0.8
]
static let projectileFireIntervalEndByDifficulty: [Difficulty: TimeInterval] = [
    .easy: 2.0, .normal: 0.35, .hard: 0.25
]

// UI / 저장 / Result 신규 상수
static let difficultyCardWidth: CGFloat = 80
static let difficultyCardHeight: CGFloat = 56
static let difficultyCardSpacing: CGFloat = 16
static let difficultyCardOffsetY: CGFloat = -120
static let difficultyCardFontSize: CGFloat = 20
static let difficultyCardSubtitleFontSize: CGFloat = 10
static let characterCardOffsetY: CGFloat = -200   // 기존 -160 → -200
static let difficultyPreferenceUserDefaultsKey: String = "selectedDifficulty"
static let resultDifficultyOffsetY: CGFloat = 155
static let resultDifficultyFontSize: CGFloat = 18
```

---

## 기능 상세

### 기능 1: Difficulty enum + 영구 저장
- 파일: `Models/Difficulty.swift`, `Repositories/DifficultyPreferenceRepository.swift`
- CharacterID + CharacterPreferenceRepository 동형 패턴 답습.
- 기본값 `.easy`. UserDefaults 키 `selectedDifficulty`. raw String 직렬화.

### 기능 2: DifficultyCardNode
- 파일: `Nodes/DifficultyCardNode.swift`
- CharacterCardNode 동형 — 배경 SKSpriteNode + nameLabel + subtitleLabel(추가) + setSelected 토글.
- subtitleLabel은 nameLabel 아래 -14pt.

### 기능 3: TitleScene 3 카드 + 선택/저장/복원
- MARK `// MARK: - Difficulty Cards` 신규 섹션.
- `selectedDifficulty` 프로퍼티 + `difficultyCards: [DifficultyCardNode]` + `difficultyRepo`.
- didMove에서 `selectedDifficulty = difficultyRepo.current`.
- touchesBegan: 캐릭터 카드 hit test *이전*에 난이도 카드 우선 분기.

### 기능 4: GameScene init + factory 시그니처 확장
- 두 인자 모두 default, 회귀 0.

### 기능 5: PlayerNode/EnemyNode/SpawnSystem `apply(_ difficulty:)` 도입
- 각 노드/시스템이 자기 수치를 자기가 결정.
- GameScene+Setup.swift `setupPlayer`/`setupEnemy`에서 1줄씩 추가.
- `startGameProperly` 진입부에 `spawnSystem.apply(difficulty)` 1줄.

### 기능 6: NoteNode TTL 자가 소멸
- `applyLifetime(_ ttl:)` 신규 메서드.
- 가드: `guard ttl.isFinite, ttl < GameConfig.gameDuration else { return }`.
- 통과 시 `SKAction.sequence([wait, fade, remove])` 부착 (withKey: "noteLifetime").

### 기능 7: SpawnSystem 차등 적용 + F burst 도입
- 인스턴스 프로퍼티 6개 (default = 기존 단일 상수값).
- `fireProjectile()`에 `for _ in 0..<projectileBurstCount` 루프. 각 발마다 `currentProjectileCount < projectileMax` 가드.
- easy=1 → 루프 1회 = 기존과 동일. **회귀 0**.

### 기능 8: EnemyNode 보간식이 인스턴스 프로퍼티 참조
- `update`의 `GameConfig.enemyBaseSpeed/MaxSpeed` → `self.baseSpeedStart/End`.

### 기능 9: ResultScene 난이도 라벨
- `difficultyLabel.text = "난이도: \(difficulty.displayName)"`.
- GameScene.endGame()에서 newResultScene 호출에 `difficulty:` 인자 추가.

---

## 회귀 0 자연 차단 메커니즘

1. **GameScene init 호출처 1군데**: `TitleScene.swift:173` 단 1곳만 인자 1개 추가.
2. **macOS/tvOS GameViewController** (미지원, 수정 금지): default 인자로 자동 호환.
3. **기존 GameConfig 단일 상수 보존**: `playerBaseSpeed=140`, `enemyBaseSpeed=60`, `noteMaxConcurrent=5` 등 *easy 기준값으로 유지*. apply(_:) 누락 시에도 기본 동작은 *현재 easy와 정확히 동일*.
4. **NoteNode TTL**: easy = `.infinity` → applyLifetime 분기로 noop → 기존 동작과 동일.
5. **F burst**: easy = 1 → 루프 1회 = 기존 1발 루프와 동일.
6. **카드 hit test 우선순위**: 난이도 카드 → 캐릭터 카드 → GameScene 전환. 카드 영역 외 탭은 기존 동작.

---

## 영구 저장 동작
- **첫 실행**: `DifficultyPreferenceRepository.current` → `.easy`.
- **사용자가 hard 선택**: `select(_ id:)` 안에서 `difficultyRepo.save(.hard)` 즉시 디스크 반영.
- **앱 재시작**: didMove → 복원 → 카드 hit test 결과가 `.hard`로 복원되어 hard로 시작.

---

## 주의사항 (8개)

1. **PlayerNode.apply(difficulty:) ↔ apply(_ characterID:) 호출 순서**.
   - 5-3의 `apply(_ characterID:)`는 `speedMultiplier`를 set.
   - 본 sprint의 `apply(_ difficulty:)`는 `baseSpeedStart/End`를 set.
   - 둘은 *서로 다른 프로퍼티*를 set하므로 순서 무관. 일관성을 위해 **`apply(characterID)` 먼저, `apply(difficulty)` 나중**으로 통일.

2. **noteLifetime의 `.infinity` 처리 정책**.
   - `SKAction.wait(forDuration: .infinity)`는 *유효하지 않은 행동*.
   - **정책**: `applyLifetime`에서 `guard ttl.isFinite, ttl < gameDuration else { return }` — easy = 기존 동작 정확 보존.

3. **SpawnSystem hard-coded 상수 → 인스턴스 프로퍼티 주입**.
   - 현재 SpawnSystem 라인 5곳에서 `GameConfig.X` 직접 참조.
   - 변환 후 모두 `self.X` 인스턴스 프로퍼티 참조. **default = GameConfig 기존 단일 상수**.

4. **F burst SpawnSystem.fireProjectile 라인 검토**.
   - `for _ in 0..<projectileBurstCount { ... 기존 1발 코드 ... }`로 감싸기.
   - **각 발마다 `currentProjectileCount() < projectileMax` 가드** — 동시 max 초과 시 즉시 break/return.
   - easy=1 → 루프 1회 = 기존과 동일. 회귀 0.

5. **dict subscript Optional 반환 — fallback 필수**.
   - 모든 lookup에 `?? GameConfig.기존단일상수` fallback.
   - **강제 언래핑 `!` 금지** (Swift 규칙 9).

6. **DifficultyCardNode와 CharacterCardNode 코드 중복 — 본 sprint는 허용**.
   - 공통 부모 추출(BaseCardNode) 유혹 — **금지**: Sprint 범위 위반. 중복 허용, 리팩터는 별도 sprint.

7. **PlayerNode 속도 보간 미적용 (본 sprint는 *시작값만*)**.
   - GDD §5는 플레이어 속도도 시간 보간이지만, PlayerNode는 현재 진행률 미보유.
   - **본 sprint 정책**: `baseSpeedStart`만 적용. `baseSpeedEnd`는 GameConfig에 미리 추가하되 *읽지 않음*.
   - 보강 sprint에 명시.

8. **TitleScene 카드 layout 충돌 점검**.
   - `characterCardOffsetY` -160 → -200. 라벨 5개(title/best/plays/prompt) y는 +80/+20/-20/-80 그대로.
   - 신규 -120 행에 난이도 카드 3장(80×56). prompt(-80) 하단과 카드 상단(-92) 간격 12pt 안전.
   - 1024×768 landscape 가정. 카드 가로 총합 272pt = 폭의 27%.

---

## 빌드 가능성 체크리스트
- [ ] 3 신규 파일 pbxproj 등록.
- [ ] macOS/tvOS GameViewController 미수정.
- [ ] `Difficulty.allCases.count == 3` — CaseIterable 자동 보장.
- [ ] dict 리터럴이 3 케이스 모두 명시.
- [ ] `NoteNode.applyLifetime` 가드로 easy 무한 TTL 자연 noop.
- [ ] PlayerNode 속도 = `baseSpeedStart × speedMultiplier`.
- [ ] EnemyNode 속도 = `self.baseSpeedStart + (self.baseSpeedEnd - self.baseSpeedStart) × speedT`.
- [ ] SpawnSystem burst 루프 안에 max 가드 매 발 검사.
- [ ] TitleScene touchesBegan 우선순위: 난이도 → 캐릭터 → GameScene 전환.
