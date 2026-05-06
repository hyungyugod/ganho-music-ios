# 09 · Phase 2-4 · HUD: 점수 라벨 + 45초 타이머

> **이번 작업의 한 줄**: 좌상단에 *점수*와 *남은 시간* 라벨이 뜨고, 45초가 다 되면 게임이 *멈춘다*.
> 비유: 운동회 점수판이 처음으로 *전광판*에 켜진다 — 그동안은 선생님이 머릿속으로만 세고 있었음.

---

## 1. 한눈 요약

```
지금 (Phase 2-3)                         이번 작업 (Phase 2-4)
┌────────────────────────┐              ┌────────────────────────┐
│ ━━━━━━━━━━━━━━━━━━     │              │ 🎵 0   ⏱ 00:45         │ ← HUD (좌상단)
│ ┃   ♪    ♪        ┃    │              │ ━━━━━━━━━━━━━━━━━━     │
│ ┃    ┌──┐    ♪    ┃    │      ──→     │ ┃   ♪    ♪        ┃    │
│ ┃    │██│         ┃    │              │ ┃    ┌──┐    ♪    ┃    │
│ ┃ ♪  └──┘     ♪   ┃    │              │ ┃    │██│  (45초 후 정지) │
│ ┃   [□] 닿으면 ♪→0 ┃   │              │ ┃ ♪  └──┘     ♪   ┃    │
│ ━━━━━━━━━━━━━━━━━━     │              │ ━━━━━━━━━━━━━━━━━━     │
│ 점수 *내부 변수*       │              │ 점수 *눈에 보임* + 타이머│
└────────────────────────┘              └────────────────────────┘
       *수집해도 피드백 0*                    *루프 완결*
```

**핵심 변화 세 가지**:
1. **HUDNode 신설** — `cameraNode` 자식 컨테이너 (점수 라벨 + 시간 라벨 묶음). 카메라 좌표계라 *항상 화면 좌상단 고정*.
2. **45초 카운트다운** — `update(_:)`에서 `remainingTime -= dt`. 0 도달 시 `gameState = .gameOver` + spawn 정지 + player 정지.
3. **`GameState.gameOver` 활성화** — 1-1에서 정의만 해둔 4번째 case가 *처음으로* 사용됨.

**부수 변화**: 2-3에서 *내부 카운트만*이던 `score`가 매 프레임 라벨에 반영. `setupDPad` 다음 setup 함수가 하나 늘어남(`setupHUD`).

---

## 2. 무엇을, 왜?

### 무엇을 만드나
| 변경 | 한 줄 설명 |
|---|---|
| `Nodes/HUDNode.swift` 신설 | `final class HUDNode: SKNode`. 점수/시간 라벨 2개 묶음. `update(score:remainingTime:)`로 외부 갱신 |
| `GameConfig` 상수 4개 추가 | `hudFontSize`, `hudMarginX`, `hudMarginY`, `hudAlpha` |
| `GameScene` 변경 | (a) `private let hud = HUDNode()`, (b) `private var remainingTime: TimeInterval = GameConfig.gameDuration`, (c) `setupHUD()` 신설 → didMove에서 호출, (d) `update(_:)`에서 `remainingTime` 카운트다운 + `hud.update(...)` 호출, (e) `endGame()` 신설 (gameState 전환 + spawn 정지 + player 정지) |

### 왜 지금?
1. **2-3에서 *수집은 됐지만 보상이 안 보임***. 박스가 음표 닿으면 ♪가 사라지는데 *왜 사라졌는지* 시각 신호가 없음. HUD 점수가 *그 신호*. 게임 루프(행동 → 결과)가 처음으로 **완결**.
2. **Phase 2-5(콤보) 진입 *전*에 점수 *시각화*가 와야 함**. 콤보는 "수집 시 +2" 같은 *변형 보상*인데, 기본 보상이 안 보이면 변형이 의미 없음. 점수 표시가 콤보의 *전제*.
3. **Phase 2-6(적 NPC + 게임오버) 진입 *전*에 타이머가 와야 함**. 적이 도입되면 "F 맞으면 즉시 게임오버" 룰이 들어오는데, 이미 시간 기반 종료가 있어야 *게임오버 핸들링 패턴*이 정착됨.
4. **`GameState.gameOver` 자산 활성화**. 1-1부터 5단계 sleep. 이번이 *첫 활성*.

### 무엇을 하지 않나
| 안 하는 것 | 미루는 곳 |
|---|---|
| 콤보 라벨 / 콤보 시스템 (점수 ×2) | Phase 2-5 |
| 사운드 (음표 수집 시 음계) | Phase 6 |
| Best 라벨 (이번 세션 최고) | Phase 3 (UserDefaults와 함께) |
| 적 NPC / F 투사체 / 게임오버 화면 | Phase 2-6 + Phase 3 |
| 일시정지 (`.paused` 활성) | Phase 3 |
| 픽셀 폰트 / 폰트 색 토큰 추가 | Phase 6 (시스템 폰트로 MVP) |
| 시간 10초 이하 빨간색 강조 (GDD §2) | 이번엔 *단일 색* — 강조는 폴리싱 |
| 게임오버 시 라벨 깜빡임/페이드 효과 | Phase 3 (게임오버 화면과 함께) |

---

## 3. Spring 비유 🌱

### 3-1. HUDNode = `@RestController` (값 *노출*만)
| 레이어 | 본 작업 위치 | Spring |
|---|---|---|
| Service (값 보유) | `GameScene.score`, `GameScene.remainingTime` | `@Service` 내부 상태 |
| Controller (노출) | `HUDNode` SKLabelNode 2개 | `@RestController.getScore()` |
| 호출 | `hud.update(score:remainingTime:)` | API 응답 직렬화 |

HUDNode는 *상태를 보유하지 않고* `update(...)` 메서드로 값을 *받아서 표시*만 함. View-only. Spring의 *DTO + 직렬화 레이어*에 가까움.

### 3-2. `update(_:)` 카운트다운 = `@Scheduled(fixedDelay=16ms)` 안 시간 차감
```swift
remainingTime = max(0, remainingTime - dt)
if remainingTime <= 0 { endGame() }
```
Spring으로 치면 매 프레임(약 16ms) 호출되는 *스케줄러* 안에서 `Duration` 차감 → 0 도달 시 *이벤트 발행* + *상태 전환*. SpriteKit의 게임 루프는 본질적으로 *60Hz 타이머*.

### 3-3. `gameState = .gameOver` = "도메인 상태 전환 + 사이드 이펙트 일괄"
```swift
private func endGame() {
    gameState = .gameOver
    removeAction(forKey: "spawnNotes")     // 사이드 이펙트 1
    player.currentDirection = .zero        // 사이드 이펙트 2
    player.physicsBody?.velocity = .zero   // 사이드 이펙트 3
}
```
Spring DDD에서 `Order.cancel()` 호출 시 → status 변경 + 환불 발행 + 재고 복구를 *한 메서드 안*에서 일관 처리하는 패턴. 상태와 사이드 이펙트가 *흩어지면* 디버깅 지옥이라, 한 곳에 모음.

---

## 4. Swift / SpriteKit 학습 포인트 📘

### 4-1. `SKLabelNode` 기본 + 정렬 모드
```swift
let label = SKLabelNode(text: "🎵 0")
label.fontSize = GameConfig.hudFontSize
label.fontColor = .ganhoPaper
label.alpha = GameConfig.hudAlpha
label.horizontalAlignmentMode = .left   // ⭐ 좌상단 정렬에 필수
label.verticalAlignmentMode   = .top    // ⭐ 라벨의 *상단*이 anchor
label.zPosition = 100                   // 게임 노드보다 위
```

**왜 정렬 모드 명시?** 기본값은 `horizontal=.center`, `vertical=.baseline`이라 라벨의 *글자 정중앙*이 anchor. 좌상단에 *고정*하려면 `.left + .top`. 안 그러면 점수가 0→9999로 변할 때 *글자 폭만큼* 위치가 흔들림.

**함정**: `verticalAlignmentMode`의 `.top`은 라벨 *글자 상단*이 anchor. *baseline*과 헷갈리지 말 것. SwiftUI `.top`과 의미 같음.

### 4-2. `cameraNode` 자식 좌표계 = 화면 좌표계
```swift
// (0, 0)이 화면 정중앙. +x 우, +y 상.
// scene.size = 1024 × 768
// 좌상단 = (-halfW + margin, +halfH - margin)
let halfW = size.width  / 2
let halfH = size.height / 2
hud.position = CGPoint(
    x: -(halfW - GameConfig.hudMarginX),
    y: +(halfH - GameConfig.hudMarginY)
)
cameraNode.addChild(hud)
```

D-Pad가 *우하단*이면 HUD는 *좌상단* — 같은 카메라 좌표계, 부호만 다름. Phase 1-3 D-Pad 셋업과 *대칭* 패턴. 1-3 학습이 그대로 재활용.

### 4-3. `dt` 카운트다운 (Timer 금지 룰 준수)
```swift
override func update(_ currentTime: TimeInterval) {
    // ... lastUpdateTime → dt 계산 ...
    guard gameState == .playing else { return }

    remainingTime = max(0, remainingTime - dt)
    if remainingTime <= 0 {
        endGame()
        return
    }
    // ... 나머지 (player.update, hud.update, cameraNode.position) ...
}
```

**왜 `max(0, ...)`?** 한 프레임이 dt 0.05초 정도 튀어 *음수*로 떨어지면 라벨 표시가 어색. 클램프로 안전.

**함정**: `remainingTime <= 0` 검사를 *카운트다운 직후*가 아니라 *update 끝*에서 하면, 그 프레임에 spawn/player.update가 *한 번 더* 돌아 마지막 음표가 게임오버 후에 생성될 수 있음. *카운트다운 직후 즉시 검사 + early return*이 안전.

### 4-4. `String(format: "%02d", n)` — 시간 포매팅
```swift
let seconds = max(0, Int(ceil(remainingTime)))
timeLabel.text = String(format: "⏱ 00:%02d", seconds)
```

`%02d` = 자릿수 2, 부족 시 0 채움. Java `String.format("%02d", n)`와 동일. Swift는 `Foundation` import 필요 (이미 SpriteKit 통해 들어옴).

**왜 `ceil`?** 44.7초 남았는데 라벨이 "44"로 표시되면 어색 (사용자는 "45"로 시작했는데 *처음부터 1초 사라짐*처럼 보임). `ceil`로 *올림*하면 시작 직후 "45" 1초간 보이고 자연스러움.

### 4-5. `removeAction(forKey:)` — 스폰 루프 *정확히* 정지
```swift
removeAction(forKey: "spawnNotes")
```

2-3에서 `withKey: "spawnNotes"`로 등록한 액션을 *키로 정확히* 제거. `removeAllActions()`도 가능하지만 *다른 액션*도 정지 → 부작용. 키 정책의 가치가 *바로 여기*에서 발휘됨.

**Spring 비유**: `@Scheduled` 빈을 ID로 stop하는 것 ↔ 모든 스케줄러 일괄 stop. 정밀도 차이.

### 4-6. `physicsBody?.velocity = .zero` + `currentDirection = .zero` 둘 다 정지
```swift
player.currentDirection = .zero        // 입력 의도 초기화
player.physicsBody?.velocity = .zero   // 현재 운동 즉시 정지
```

**왜 둘 다?** PlayerNode `update(deltaTime:)`이 매 프레임 `velocity = currentDirection * speed`로 *덮어씀*. `currentDirection`만 0으로 두면 다음 프레임에 자동으로 velocity=0이 되지만, *그 프레임까지의 잔여 속도*는 게임오버 후 한 프레임 동안 박스가 더 미끄러짐. 두 줄로 *즉시 정지*.

**함정**: `gameState == .gameOver`라 update 안 `guard`에 걸려 더 이상 갱신 안 되지만, *현재 프레임*의 잔여 운동량은 그대로 → physicsBody.velocity 직접 0 부여로 *시각적 정지* 보장.

### 4-7. `final class HUDNode: SKNode` — *컨테이너* 패턴
```swift
final class HUDNode: SKNode {
    private let scoreLabel: SKLabelNode
    private let timeLabel:  SKLabelNode

    override init() {
        scoreLabel = SKLabelNode(text: "🎵 0")
        timeLabel  = SKLabelNode(text: "⏱ 00:45")
        super.init()
        configure(scoreLabel)
        configure(timeLabel)
        // 자기 좌표계 (0,0) 기준 두 라벨 배치
        scoreLabel.position = CGPoint(x: 0, y: 0)
        timeLabel.position  = CGPoint(x: 0, y: -GameConfig.hudFontSize * 1.4)
        addChild(scoreLabel)
        addChild(timeLabel)
    }
    func update(score: Int, remainingTime: TimeInterval) { /* ... */ }
    private func configure(_ label: SKLabelNode) { /* fontSize, color, alpha, alignment, zPosition */ }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
```

`SKNode`(*시각 자체는 없음*)가 라벨 2개를 묶음. 외부에선 `hud.position`만 정해주면 *상대 위치는 내부에서 처리*. Phase 1-3의 DPadNode 패턴과 동일.

**Spring 비유**: `@Component HUDController { ScoreLabel score; TimeLabel time; }` — 컴포지션. PlayerNode/NoteNode가 *하나의 시각*이라면 HUDNode는 *여러 시각의 묶음*.

---

## 5. 산출물 (예정)

### 새로 만드는 파일
| 파일 | 내용 |
|---|---|
| `Nodes/HUDNode.swift` | `final class HUDNode: SKNode` + 라벨 2개 + `update(score:remainingTime:)` (~50 LOC) |

### 수정하는 파일
| 파일 | 변경 |
|---|---|
| `Config/GameConfig.swift` | HUD 상수 4개 추가: `hudFontSize`(18), `hudMarginX`(24), `hudMarginY`(24), `hudAlpha`(0.85). 새 MARK `// MARK: - HUD (Phase 2-4)` |
| `GanhoMusic Shared/GameScene.swift` | (a) `private let hud = HUDNode()`, (b) `private var remainingTime: TimeInterval = GameConfig.gameDuration`, (c) `setupHUD()` 신설 + didMove에서 호출, (d) `update(_:)` 카운트다운 + hud 갱신, (e) `endGame()` 신설 |

### 절대 손대지 않는 파일
- `Nodes/PlayerNode.swift`, `Nodes/DPadNode.swift`, `Nodes/NoteNode.swift` (전부 0바이트 변경)
- `Config/PhysicsCategory.swift`, `Config/GameState.swift`, `Config/ColorTokens.swift` (0바이트 — `GameState.gameOver`는 *기존 case* 그대로 활용)
- `iOS/AppDelegate.swift`, `SceneDelegate.swift`, `GameViewController.swift` (0바이트)

### Xcode 멤버십
**필수 연동 변경 가능성**: 2-3 회고 §9-1 — 디스크 저장만으로 빌드 자동 포함되지 않을 수 있음. *시도 후 fallback* 정책: HUDNode.swift 디스크 저장 → 빌드 시도 → 실패 시 `project.pbxproj`에 *PBXBuildFile + PBXFileReference + Sources files* 3줄만 추가. PBXGroup/다른 노드 중복 등록 금지.

---

## 6. 검증 방법 ✅

### 6-1. 정량 검증
```bash
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
  -scheme "GanhoMusic iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```
- 빌드 에러 0, 경고 0
- `class HUDNode` 정의 1건
- `SKLabelNode` 등장 ≥ 2건 (HUDNode init)
- `gameState = .gameOver` 1건 (`endGame` 안)
- `removeAction(forKey: "spawnNotes")` 1건
- `Timer` / `print()` / `as!` / `fileprivate` / 강제 언래핑 `!` 0건 (`fatalError`/네임드 옵셔널 캐스트 면제)
- 매직 넘버 0건 — 18/24/0.85/45는 모두 GameConfig 상수 (45는 기존 `gameDuration`)
- `update(_:)` 안 `addChild()` 0건

### 6-2. 시각 검증 (사용자 시뮬레이터)
`⌘R` 후:
- (a) 시작 직후 좌상단에 **🎵 0** + **⏱ 00:45** 두 줄 라벨 보임
- (b) 음표에 닿을 때마다 좌상단 점수가 **+1**씩 오름
- (c) 시간이 줄어들어 **⏱ 00:01** → **⏱ 00:00** 도달 후 박스가 멈춤
- (d) 게임오버 후 음표 *추가 스폰 0*. 남은 음표는 그대로 떠 있음 (제거는 OUT)
- (e) 게임오버 후 D-Pad 눌러도 박스 안 움직임 (`gameState != .playing` 가드)
- (f) HUD가 카메라 따라 이동(=화면 고정). 박스가 맵 끝으로 가도 좌상단 그대로
- (g) 박스/벽/기둥/음표/D-Pad는 2-3 그대로

### 6-3. 회귀 (1-5 + 2-1 + 2-2 + 2-3 + 핫픽스)
- PlayerNode/DPadNode/NoteNode 0바이트 변경
- Config 3 파일 (PhysicsCategory/GameState/ColorTokens) 0바이트 변경 — `GameState.gameOver`는 *기존 case 활성화*만이라 파일 변경 불필요
- iOS 3 파일 / project.pbxproj — 후자는 HUDNode 신규 등록 *3줄 한정* 허용 (2-3 회고 정책)
- 1-3 핫픽스 / 1-5 카메라 follow / 2-1 외곽 벽 / 2-2 중앙 기둥 + gravity / 2-3 spawn loop + didBegin 그대로

---

## 7. 사용자 결정 필요 사항

### 결정 ① · HUDNode 분리 vs GameScene 인라인
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. `Nodes/HUDNode.swift` 분리** ⭐ | 라벨 2개 묶음 + 향후 콤보/베스트 추가 자리 | ⭐ — 응집도 ↑, 1-3 DPadNode 패턴 일관 |
| B. GameScene 안 라벨 2개 | 파일 1개 절약 | GameScene 비대화, 후속 라벨 추가 시 분리 비용 |

**왜 A?** PlayerNode·DPadNode·NoteNode가 모두 `Nodes/` 분리 — HUD도 같은 위치가 일관. 콤보/베스트 라벨 추가 시 HUDNode 안 한 줄로 끝.

### 결정 ② · HUD 위치
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. 좌상단** ⭐ | 게임 시야 방해 최소. GDD §2 좌상단 모형 일치. D-Pad(우하단)와 *대각 대칭* | ⭐ — GDD 일치 |
| B. 상단 중앙 | 게임 캐릭터가 화면 중앙이라 *수직 시선* 충돌 가능 | 시야 방해 |
| C. 우상단 | D-Pad 우하단과 *세로 충돌* 가능 (가로 모드라 안 부딪히지만) | 일관성 ↓ |

**왜 A?** GDD §2 화면 모형의 좌상단 HUD 정책 그대로. D-Pad가 우하단이라 *대각 대칭*이 시각적으로 안정.

### 결정 ③ · 라벨 텍스트 형식
| 옵션 | 예시 | 추천 |
|---|---|---|
| **A. 이모지 + 숫자** ⭐ | `🎵 12`, `⏱ 00:32` | ⭐ — GDD §2 모형 일치 / 의미 즉각 인지 |
| B. 영문 텍스트 | `Score: 12`, `Time: 32s` | 가독성 OK이나 GDD 모형과 거리 |
| C. 한글 텍스트 | `점수 12`, `시간 32` | 글자 폭 큼, 가로 좁아짐 |

**왜 A?** GDD §2의 ASCII 화면 모형이 이미 `🎵 12점`, `⏱ 00:42` 표기. 시스템 폰트가 이모지 자동 렌더링 — 별도 폰트 자산 불필요. MVP에 이상적.

### 결정 ④ · HUD 알파
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. 0.85** ⭐ | 살짝 비치되 *가독성 우선*. D-Pad(0.3)와 톤 분리 (UI 계층 명확) | ⭐ — GDD §2 "반투명" 정책 + 가독성 |
| B. 1.0 (불투명) | 가장 또렷. 그러나 게임 위에 *떠 있다*는 느낌 약함 | UI vs 월드 분리 약함 |
| C. 0.5 | 분위기는 좋으나 점수 글자가 *읽기 힘듦* | 가독성 ↓ |

**왜 A?** D-Pad는 *조작 보조*라 0.3으로 게임 시야 우선. HUD는 *읽혀야* 하므로 0.85. *동일한 반투명 의도*지만 *역할에 따른 차등*.

### 결정 ⑤ · 게임오버 시 동작 범위
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. 단순 정지** ⭐ | gameState = .gameOver + spawn 정지 + player 정지. 화면은 그대로 (게임오버 화면은 Phase 3) | ⭐ — 1 SPEC = 1 sub-feature |
| B. + 화면 페이드 / 라벨 강조 | 시각 폴리싱 추가 | Phase 3 게임오버 화면과 함께 |
| C. + 음표 일괄 제거 | "게임 끝났으니 정리" 느낌 | 정리 의도가 모호 (점수는 그대로?) |

**왜 A?** 본 작업 sub-feature는 *시간 만료 처리*. 게임오버 *화면*과 *시각 효과*는 Phase 3에서 묶어 처리하는 게 응집도 ↑.

### 결정 ⑥ · 폰트
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. 시스템 폰트 (default)** ⭐ | `SKLabelNode(text:)` 단순 init. 이모지 자동 렌더링. 글자 깔끔 | ⭐ — MVP, 픽셀 폰트는 Phase 6 |
| B. 픽셀 폰트 (e.g., Pixelify) | 게임 톤 일관성 ↑ | Asset Catalog 폰트 추가 + GDD §13 픽셀 아트 단계 (Phase 6) |

**왜 A?** GDD §18 MVP "스프라이트 색깔 사각형" 정책 = 폰트도 시스템 폰트. 폴리싱 단계에서 일괄 교체.

### 결정 ⑦ · 시간 포매팅 정밀도
| 옵션 | 표시 | 추천 |
|---|---|---|
| **A. `00:SS` (분:초)** ⭐ | `00:45` → `00:00` | ⭐ — GDD §2 모형 일치 |
| B. `SS` (초만) | `45` → `0` | 짧지만 GDD와 거리 |
| C. `SS.f` (소수) | `45.0` → `0.0` | 정밀도 과잉 |

**왜 A?** GDD §2 `⏱ 00:42` 표기 그대로. 향후 분 단위(>60초) 게임 모드 도입 시 같은 형식 재활용.

### 결정 ⑧ · `score` 업데이트 방식
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. 매 프레임 `hud.update(score:, remainingTime:)`** ⭐ | update(_:)에서 둘 다 한 번에. 단순 | ⭐ — 60Hz 갱신은 SKLabelNode 비용 무시 |
| B. `score didSet` 콜백 + 시간만 매 프레임 | 점수는 변경 시만 갱신 | 두 경로 = 분기 ↑ |

**왜 A?** SKLabelNode 텍스트 변경은 GPU 비용 무시 (5개 음표 풀 60Hz도 가벼움). 단순 update 한 곳이 디버깅 편함.

---

## 8. SPEC에 들어갈 핵심 제약 (Planner에게 전달)

- **변경 유형**: 비주얼 + 게임플레이 (HUD 시각화 + 시간 만료 → 게임오버 전환)
- **게임 경험 의도**:
  > "좌상단에 점수와 남은 시간이 *보인다*. 음표 수집할 때마다 점수가 오르고, 45초가 다 되면 박스가 멈추고 음표 추가 스폰이 멎는다. 1-1에서 정의해둔 GameState.gameOver가 처음으로 활성화. 게임이 *공간*에서 *세션*이 된다."
- **Sprint 범위 계약**:
  - **IN**: HUDNode 신설(`Nodes/HUDNode.swift`). GameConfig HUD 상수 4개 추가. GameScene `hud` + `remainingTime` + `setupHUD` + `endGame` + `update(_:)` 카운트다운 로직. 총 **신설 1 파일 + 수정 2 파일**.
  - **OUT**: 콤보 / 사운드 / Best 라벨 / 게임오버 화면 / 픽셀 폰트 / 일시정지 / 적 NPC / 시간 10초 이하 빨간색 강조 / 게임오버 시 음표 일괄 제거.
- **준수 룰**:
  - `!` 0건 (`fatalError` 면제, 네임드 옵셔널 캐스트 0건)
  - `Timer` / `print()` / `as!` / `fileprivate` / `DispatchQueue.main.asyncAfter` 0건
  - `update(_:)` 안 `addChild()` 0건
  - 매직 넘버 0건 — 18/24/0.85는 GameConfig, 45는 `gameDuration` 재활용
  - HUDNode `final class` + `private` 라벨 + `addChild` *init 안*에서만
  - SKLabelNode `horizontalAlignmentMode = .left` + `verticalAlignmentMode = .top` 명시
  - SKLabelNode `zPosition = 100` 명시 (게임 노드 위)
  - `removeAction(forKey: "spawnNotes")` (2-3 키 정책 활용)
  - `endGame()` 안에서 player `currentDirection = .zero` + `physicsBody?.velocity = .zero` *둘 다*
- **회귀 보존 (1-5 + 2-1 + 2-2 + 2-3 + 핫픽스)**:
  - PlayerNode / DPadNode / NoteNode / Config 3 파일 / iOS 3 파일 모두 0바이트
  - project.pbxproj는 HUDNode 신규 *3줄만* 추가 허용 (PBXBuildFile / PBXFileReference / Sources files). PBXGroup 추가 또는 기존 등록 변경 0건
  - 1-3 핫픽스 / 1-5 카메라 follow / 2-1 외곽 벽 / 2-2 gravity + 기둥 / 2-3 spawn + didBegin 모두 그대로

---

## 9. 회고 (작업 후 채움) 📝

### 9-1. 막혔던 것
**Generator의 *시도 후 fallback* 정책이 깔끔하게 작동.** 2-3 회고 §9-1에서 이월한 정책("디스크 저장 → 빌드 시도 → 실패 시 3줄만 추가")을 SPEC §Xcode 멤버십에 정식 명시한 결과, 1차 빌드 0줄 시도 → `cannot find 'HUDNode' in scope` 실패 → fallback 3줄 추가 → 2차 BUILD SUCCEEDED. 2-3에서 23줄 과변경했던 P1을 2-4에서는 0건으로 회복. **SPEC에 정책을 *문서화*하면 Generator가 정확히 따라옴.**

> **추가 인사이트**: HUDNode의 `path`를 다른 형제와 달리 절대 경로(`"GanhoMusic Shared/Nodes/HUDNode.swift"`)로 명시한 점은 PBXGroup 변경 회피의 *직접적 산물*. 형제 노드는 부모 그룹 path 상속이라 짧은 파일명만 적힘 — HUDNode는 그룹에 등록 안 되니까 절대 경로 필요. **3줄 정책의 자연스러운 결과**.

### 9-2. Spring과 다르네 싶었던 것
1. **`SKNode`는 *시각이 없는 컨테이너***: HUDNode는 SKNode 상속이라 자체 그림 0. 라벨 2개 묶음 좌표 제어용. Java로 치면 `JPanel`(레이아웃 컨테이너) 같은 위치 — 자기는 안 보이고 자식 배치만.
2. **`horizontalAlignmentMode`/`verticalAlignmentMode` *명시*가 핵심**: 기본값(`center`/`baseline`)은 글자 정중앙이 anchor라 점수가 0→9999로 변할 때 *글자 폭만큼* 위치가 흔들림. CSS `text-align: left` + `vertical-align: top`과 의미 같지만 Swift는 *명시 안 하면 기본값으로 헷갈림 유발*. **모든 SKLabelNode는 정렬 모드 즉시 명시** 룰화.
3. **`configure(_:)` 헬퍼로 두 라벨 DRY**: Java에서도 흔하지만 Swift에서 inout-style 설정은 *함수 호출 한 번*이 가장 깔끔. 두 라벨에 동일 스타일 적용 → 한 줄 변경으로 모두 갱신. Spring `@Configurable` post-processing과 비슷.
4. **`endGame()`이 *상태 전환 + 사이드 이펙트 일괄***: `gameState = .gameOver` + spawn 정지 + player 정지 둘 다 + HUD 0초 마무리 = 5줄 한 메서드. Spring DDD의 `Order.cancel()` 한 메서드 안에 status 변경 + 환불 발행 + 재고 복구 일관 처리하는 패턴과 동일. *흩어지면 디버깅 지옥*.
5. **`removeAction(forKey: "spawnNotes")` 키 정책의 진가**: 2-3에서 키를 *왜 등록하는지* 모호했는데 2-4에서 endGame 때 spawn만 정확히 정지 = `removeAllActions()` 부작용 회피. **인프라 등록은 *나중에 정확히 끄기 위한* 보험.** Spring `@Scheduled` 빈을 ID로 stop하는 것과 동치.
6. **player 정지가 *둘 다* 필요**: `currentDirection = .zero`는 *다음 프레임* 의도, `physicsBody?.velocity = .zero`는 *현재 프레임* 잔여 운동량. update guard에 걸려도 *현 프레임 운동량*은 그대로라 한 프레임 더 미끄러짐 → 두 줄로 즉시 정지. **의도 vs 상태**의 분리가 또 등장.
7. **`String(format: "⏱ 00:%02d", seconds)` Foundation 의존**: SpriteKit transitively import → 별도 import 불필요. Java `String.format("%02d", n)`과 동일한 의미. `%02d` = 자릿수 2 + 0 채움.
8. **`ceil` 사용 이유**: 44.7초 남았을 때 라벨 "44"면 사용자가 "처음부터 1초 사라졌다" 느낌. `ceil`로 *올림*하면 시작 직후 "45" 1초간 보이고 자연스러움. *수학적 정확*보다 *체감 자연스러움*이 우선. UX 관점 산수.
9. **`update(_:)` 안 카운트다운 *위치*가 핵심**: `guard gameState == .playing` 직후 + early return = 게임오버 그 프레임에 player/spawn 동작 0. *update 끝*에서 검사하면 마지막 프레임 player가 한 번 더 움직임 → 시각 부자연. **early return은 프레임 단위 결정의 도구**.

### 9-3. 다음 작업으로 이월된 결정 (Phase 2-5 / 2-6 / 2-7 진입 시)
1. **콤보 시스템 (Phase 2-5)**: GDD §8 — 마지막 수집 후 2.5초 이내 재수집 안 하면 초기화. `lastCollectAt: TimeInterval?` 변수 + `update`에서 시간 체크. 콤보 3+ 시 `score += 2`. HUDNode에 `comboLabel: SKLabelNode` 추가 (`🔥 3`).
2. **콤보 시각화**: 콤보 0/1/2는 안 보임. 3+ 시 등장 + 살짝 강조 (alpha pulse 가능) — Phase 2-5 OR 폴리싱 단계.
3. **시간 ≤ 10초 빨간색 강조 (GDD §2)**: HUDNode `update(score:remainingTime:)` 안에서 `timeLabel.fontColor = remainingTime <= 10 ? .ganhoPinkNote : .ganhoPaper` 같은 단순 분기. 색 토큰은 기존 자산 활용. Phase 2-5 또는 Phase 2-7(폴리싱) 후보.
4. **수간호사 적 + F 투사체 (Phase 2-6)**: EnemyNode + ProjectileNode 신설. PhysicsCategory.enemy 활성화. didBegin이 .note / .enemy / .projectile 3가지 분기로 → switch 또는 분리 함수 필요. F 피격 시 `endGame()` 재호출.
5. **게임오버 화면 (Phase 2-7 또는 Phase 3)**: 현재 `endGame()`은 *내부 상태만* 변경, 화면은 그대로. 게임오버 텍스트/리트라이 버튼은 별도 SKNode 오버레이 또는 SwiftUI `.fullScreenCover`. UserDefaults 베스트 기록과 함께 묶어 Phase 3에서 일괄.
6. **Best 라벨 (Phase 3)**: `UserDefaults`에 베스트 점수 저장 + HUDNode에 `bestLabel` 추가. 게임오버 시 `score > best`이면 갱신 표시.
7. **사운드 (Phase 6)**: 음표 수집 시 C장조 스케일, 게임오버 시 효과음. AVAudioEngine 또는 `SKAction.playSoundFileNamed`.
8. **시간 만료 *전 5초/10초 카운트* 경고음** (선택): GDD §8 정의 안 됨. 추후 폴리싱 후보.
9. **`gameState = .paused` 활성** (Phase 3): 일시정지 버튼 추가 시 `removeAction(forKey: "spawnNotes")` 가 아닌 `isPaused = true` 패턴으로 — `SKAction`은 `isPaused` 동안 자동 정지.
10. **HUDNode 확장 자리**: 콤보/베스트/스킬 라벨이 추가될 때 `Nodes/HUDNode.swift` 한 곳에서 라벨 N개 묶음 패턴이 그대로 확장. 외부에선 `hud.update(score:remainingTime:combo:best:)` 시그니처만 늘어남. *컨테이너 패턴의 자연스러운 진화*.

### 9-4. 평가 점수 (QA_REPORT.md 기준)
- Swift 패턴 (35%): **9.5 / 10** — MARK 섹션 4개 신설 / configure 헬퍼 DRY / 모든 매직 넘버 GameConfig화 / `fatalError`만 1건(면제)
- 게임 로직 (30%): **9.5 / 10** — dt 기반 카운트다운 / early return / GameState 단일 전환점 / removeAction 키 정책
- 성능 (20%): **9.5 / 10** — BUILD SUCCEEDED / 강제 언래핑 0건 / [weak self] 보존 / update() 안 addChild 0건
- 기능 완성도 (15%): **10 / 10** — SPEC 1~6 정확히 구현 / OUT 0건 위반 / 회귀 9/9 보존 / pbxproj 3줄 한정 충족
- **가중평균: 9.6 / 10 — 합격** (1회차 통과, 2-3 9.18 대비 +0.42 회복)

### 9-5. 사용자가 직접 확인할 것 ✅
시뮬레이터 `⌘R` 후 7가지:
- (a) 시작 직후 좌상단에 🎵 0 + ⏱ 00:45 보임
- (b) 음표 수집 시 점수 +1 갱신
- (c) 시간이 줄어들어 00:00 도달 시 박스 멈춤
- (d) 게임오버 후 음표 추가 스폰 0
- (e) 게임오버 후 D-Pad 무반응
- (f) HUD가 카메라 follow와 무관하게 *항상 좌상단*
- (g) 박스/벽/기둥/음표/D-Pad는 2-3 그대로

---

## 10. 다 읽었다면 다음은?

```
[1] §7 결정 8건 사용자 OK (모두 추천대로 가는지)
[2] rm -f SPEC.md SELF_CHECK.md QA_REPORT.md
[3] Planner   → SPEC.md
[4] Generator → HUDNode 신설 + GameConfig/GameScene 수정 + SELF_CHECK.md
[5] Evaluator → QA_REPORT.md
[6] 합격 시 §9 회고 채우고 → Phase 2-5(콤보 + 점수 ×2) 또는 Phase 2-6(적 + 게임오버 화면)으로
```

> **2-4 본질**: 게임 세션이 *시작과 끝*을 가짐. 점수가 *눈에 보이는* 보상이 됨. 콤보·적·게임오버 화면이 모두 이 위에 올라감.
