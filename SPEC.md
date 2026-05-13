# Phase 6-9 — F 투사체 피격 시 카메라 셰이크 + 화면 빨간 깜빡임

## 개요
F 투사체에 맞으면 화면이 짧게 흔들리고 빨간색이 잠깐 깜빡인다. Phase 6-1에서 이미 발화하는 `haptics.heavy()` 진동 위에 *시각 임팩트* 두 채널을 더해 피격의 물리적 충격감을 3채널(진동+셰이크+플래시)로 전달한다. Phase 6-8 sparkle(긍정)의 대척점에 위치하는 *부정 피드백*.

## 변경 유형
**폴리싱 / 시각 임팩트 / 부정 피드백** (game-design + visual 혼합 평가 기준)

## 게임 경험 의도
- 수간호사한테 F 학점을 맞으면 머리가 한 번 *띵*하고 흔들리는 느낌. 시야가 빨갛게 잠깐 물든다. 진동(이미 있음) + 흔들림 + 빨간 플래시 = "맞았다"를 몸·눈·시각으로 동시에 인지.
- Phase 6-8 sparkle(노트 수집 → 흰빛 8방향 방사)와 *디자인 대칭*. 긍정=별이 퍼짐 / 부정=화면이 흔들리고 빨갛게 물듦. 같은 패턴(자가 소멸 노드)을 정반대 톤에 적용해 시청각 어휘를 확장.
- 학생 비유: 평소 노트 차곡차곡 모으다 갑자기 수간호사한테 *F!* 맞으면 정신이 번쩍 나는 그 순간. 게임오버 transition으로 *컷*되기 전 마지막 0.3초가 가장 강렬한 인상이 됨.

## Sprint 범위 계약

### 허용
- 새 파일 `Nodes/HitFlashNode.swift` 신설 (자가 소멸 5호 — SparkleEffectNode/BombFlashNode 패턴 답습)
- 새 파일 `Systems/CameraShakeAction.swift` 신설 (SKAction 헬퍼 — `enum CameraShakeAction` 네임스페이스에 `static func make(...) -> SKAction`)
- `GameConfig.swift`에 셰이크/플래시 상수 추가 (`// MARK: - Hit Feedback (Phase 6-9)`)
- `GameScene.swift`의 `configureContactRouter()` 안 `onProjectileHitPlayer` 콜백에 트리거 추가 (셰이크 1줄 + 플래시 부착 3줄)
- 헤더 주석에 `Phase 6-9 · 피격 카메라 셰이크 + 빨간 플래시 (시각 폴리싱)` 1줄 추가
- `project.pbxproj`에 두 새 파일 등록 (SparkleEffectNode 등록 형식 답습)

### 금지
- `BombFlashNode` 변경 (AIRFORCE 전용 — 폭탄 누런 섬광 vs F 빨간 셰이크는 톤이 다름. 별도 sprint에서 추출 검토)
- 새 효과음/햅틱 추가 (6-1 `haptics.heavy()` 그대로 활용 — 이미 `endGame()` 안에서 발화 중)
- `endGame()` 호출 순서/로직 변경 (멱등 가드, presentScene 등 손대지 않음)
- 새 `PhysicsCategory` 추가 (충돌 분기는 ContactRouter 그대로)
- 새 ColorTokens 추가 (`UIColor.ganhoBloodAccent` 재사용 — assets.md에 "피격 플래시"로 *이미 정의*)
- `BGMPlayer`/`AudioManager`/`HapticsManager` 변경
- `ResultScene`, `ScoreSystem`, `EnemyNode`, `ProjectileNode` 변경
- `update()` 안에 새 로직 추가 (셰이크는 액션 1회로 끝나므로 update 불필요)

### 판단 기준
"이 변경이 없으면 SPEC 기능(피격 시 화면 흔들림 + 빨간 깜빡임)이 동작하지 않는가?" → YES면 허용, NO면 금지.

---

## 변경 범위

### 수정할 파일
- `GanhoMusic Shared/GameScene.swift`: `configureContactRouter()` 안 `onProjectileHitPlayer` 콜백에 셰이크 1줄 + HitFlashNode 부착 3줄 추가, 헤더 주석 1줄
- `GanhoMusic Shared/Config/GameConfig.swift`: `// MARK: - Hit Feedback (Phase 6-9)` 섹션 추가 (셰이크 3 상수 + 플래시 4 상수)
- `GanhoMusic.xcodeproj/project.pbxproj`: 새 파일 2개 등록

### 추가할 파일
- `GanhoMusic Shared/Systems/CameraShakeAction.swift`: 카메라 셰이크용 `SKAction` 빌더 enum 네임스페이스
- `GanhoMusic Shared/Nodes/HitFlashNode.swift`: 화면 전체 빨간 플래시 자가 소멸 노드. `SelfDismissingNode` 채택 (자가 소멸 5호)

---

## 핵심 결정 포인트 (사전 확정)

### a. 카메라 노드 존재 여부
**확정**: GameScene에 `let cameraNode = SKCameraNode()` 이미 존재. `self.camera = cameraNode`로 attach됨. **카메라 노드에 SKAction.sequence 적용 — worldNode 대안 채택 안 함.** 카메라가 흔들리면 worldNode 자식(player/enemy/note) + HUD/D-Pad(cameraNode 자식)가 *함께* 흔들려 화면 전체가 진동하는 효과.

### b. 셰이크 알고리즘
**확정**: 단순 SKAction.sequence — 좌→우→좌→우 진폭 보간 반복. sin파 random 떨림이 아닌 *예측 가능한 직선 이동*. 마지막 단계는 반드시 *원위치 복귀* 액션.

```
moveBy(+amp, 0, dur=stepDur)
moveBy(-2*amp, 0, dur=stepDur)
moveBy(+2*amp, 0, dur=stepDur)
... (cameraShakeStepCount회 반복)
moveBy(±amp, 0, dur=stepDur)  ← 원위치 복귀 (count 짝/홀에 따라 부호 결정)
```

수동 검산 (count=6):
```
i=0: +amp   (누적 +amp)
i=1: -2amp  (누적 -amp)
i=2: +2amp  (누적 +amp)
i=3: -2amp  (누적 -amp)
i=4: +2amp  (누적 +amp)
i=5: -2amp  (누적 -amp)
복귀:+amp   (누적   0) ✓
```

일반화: count 짝수 → 누적 -amp → 복귀 +amp / count 홀수 → 복귀 -amp.

### c. 플래시 노드
**확정**: 화면 전체 덮는 빨간 SKSpriteNode. cameraNode 자식으로 부착 → scene.size로 풀스크린 → fadeIn → fadeOut → 자가 제거. **BombFlashNode와 거의 같은 구조이지만 색·타이밍·zPosition이 달라 별도 클래스로 분리.** 공통 추출(BaseFlashNode)은 Rule of three(3개 등장) 시점까지 보류.

### d. 트리거 지점
**확정**: `configureContactRouter()` 안 `onProjectileHitPlayer` 클로저. 시각 효과 → 상태 전환 *순서*:

```swift
contactRouter.onProjectileHitPlayer = { [weak self] in
    guard let self = self else { return }
    self.cameraNode.run(CameraShakeAction.make())     // 신규
    let flash = HitFlashNode()                          // 신규
    self.cameraNode.addChild(flash)                     // 신규
    flash.flash(sceneSize: self.size)                   // 신규
    self.endGame()
}
```

**중요 — 호출 순서 고정**:
1. 셰이크/플래시 트리거가 `endGame()` *이전*에 들어가야 함
2. 이유: endGame 호출 순간 `gameState = .gameOver`로 전환 → 다음 프레임부터 `update()` early return → 카메라 follow 정지 → 셰이크 액션이 단독으로 cameraNode.position 변경. 셰이크 액션 자체는 *별개 큐*라 endGame과 무관하게 진행.
3. **트리거를 endGame 안으로 옮기지 말 것**: 시간 만료 endGame에서도 빨간 플래시가 떠 *의미 혼동*. 피격 전용 피드백은 피격 콜백에서만.

### e. 멱등성
**확정**: 현재 F 1발 → 즉시 endGame → ResultScene 전환. 같은 GameScene 인스턴스에서 두 번째 onProjectileHitPlayer 호출은 endGame 멱등 가드에서 차단(시각 효과는 두 번 발화 가능하지만 같은 프레임이라 시각적 차이 0). 본 sprint는 *시각 효과 자체*의 멱등 가드 없음 — endGame에 위임.

### f. zPosition
**확정**: `hitFlashZPosition = 200` (HUD 100 위, BombFlash 250 아래). HUD 위에 두는 이유: 점수가 가려질 만큼 *임팩트* 강조. 0.3초만 떠 있으므로 점수 가려도 게임플레이 방해 없음. BombFlash(250)보다 낮은 건 *AIRFORCE 폭탄이 더 큰 사건*이라는 위계.

---

## 기능 상세

### 기능 1: GameConfig — Hit Feedback 상수 추가

**구현 위치**: `Config/GameConfig.swift` 끝에 `// MARK: - Hit Feedback (Phase 6-9)` 섹션 추가

```swift
// MARK: - Hit Feedback (Phase 6-9)
/// 카메라 셰이크 진폭 (pt). 좌우 한 방향 이동량. 6~10pt 범위에서 8 채택.
/// 너무 크면 어지러움, 너무 작으면 안 보임. 학생 머리 *띵* 흔들림.
static let cameraShakeAmplitude: CGFloat = 8
/// 카메라 좌우 흔들림 반복 횟수. 6회 → 좌·우·좌·우·좌·우 (마지막 원위치 별도).
/// 총 모션 = stepDuration × (count + 1).
static let cameraShakeStepCount: Int = 6
/// 카메라 셰이크 한 스텝 길이 (초). 6 × 0.04 + 0.04 = 0.28초 ≈ haptics.heavy 체감 길이.
static let cameraShakeStepDuration: TimeInterval = 0.04
/// 피격 플래시 alpha 피크 (0~1). 0.55 = 반투명 빨강 — 시야 차단 방지, *맞았다* 명확.
static let hitFlashPeakAlpha: CGFloat = 0.55
/// 피격 플래시 fadeIn 길이 (초). 빠르게 등장 — *번쩍* 임팩트.
static let hitFlashFadeInDuration: TimeInterval = 0.05
/// 피격 플래시 fadeOut 길이 (초). 천천히 사라짐 — *잔상* 효과.
/// 총 노출 = fadeIn(0.05) + fadeOut(0.25) = 0.30초 ≈ 셰이크(0.28) 동기.
static let hitFlashFadeOutDuration: TimeInterval = 0.25
/// 피격 플래시 zPosition. HUD(100) 위, BombFlash(250) 아래.
/// 점수 라벨을 잠깐 덮어 임팩트 강조 — 0.3초만 가려지므로 게임플레이 무방해.
static let hitFlashZPosition: CGFloat = 200
```

---

### 기능 2: CameraShakeAction — SKAction 빌더 enum 네임스페이스

**구현 위치**: 새 파일 `Systems/CameraShakeAction.swift`

```swift
//
//  CameraShakeAction.swift
//  GanhoMusic Shared
//
//  Phase 6-9 · 카메라 셰이크 SKAction 빌더 (피격 시각 임팩트)
//

import SpriteKit

/// 카메라(또는 임의 SKNode)에 적용 가능한 좌우 셰이크 SKAction을 만들어주는
/// 순수 팩토리 네임스페이스. case 없는 enum으로 인스턴스화 차단.
/// Spring 비유: 정적 빌더 — 상태 없음, side-effect 없음, 입력 없이 SKAction 1개 반환.
/// 사용: cameraNode.run(CameraShakeAction.make())
enum CameraShakeAction {

    // MARK: - Make
    /// 좌→우→좌→우 직선 이동을 cameraShakeStepCount회 반복 후 *원위치 복귀*.
    /// 진폭은 GameConfig.cameraShakeAmplitude, 스텝당 길이는 cameraShakeStepDuration.
    /// 마지막 복귀 단계는 누적 변위 0이 되도록 부호 결정 (count 짝/홀).
    /// 학생 비유: 머리를 좌·우·좌·우·좌·우 흔든 뒤 정면으로 *딱* 복귀.
    static func make() -> SKAction {
        let amp = GameConfig.cameraShakeAmplitude
        let dur = GameConfig.cameraShakeStepDuration
        let count = GameConfig.cameraShakeStepCount

        // 첫 이동(+amp), 그 후 (count-1)회 ±2amp 토글, 마지막 ±amp로 원위치.
        var steps: [SKAction] = []
        steps.append(SKAction.moveBy(x: +amp, y: 0, duration: dur))
        for i in 1..<count {
            let dx: CGFloat = (i % 2 == 0) ? +2 * amp : -2 * amp
            steps.append(SKAction.moveBy(x: dx, y: 0, duration: dur))
        }
        // 원위치 복귀: count 짝수면 누적 -amp → 복귀 +amp / 홀수면 누적 +amp → 복귀 -amp.
        let returnDx: CGFloat = (count % 2 == 0) ? +amp : -amp
        steps.append(SKAction.moveBy(x: returnDx, y: 0, duration: dur))
        return SKAction.sequence(steps)
    }
}
```

---

### 기능 3: HitFlashNode — 빨간 풀스크린 자가 소멸 노드

**구현 위치**: 새 파일 `Nodes/HitFlashNode.swift`

```swift
//
//  HitFlashNode.swift
//  GanhoMusic Shared
//
//  Phase 6-9 · F 피격 시 화면 빨간 풀스크린 플래시 + 자가 소멸
//

import SpriteKit

/// F 투사체 피격 시 화면 전체를 빨갛게 덮는 자가 소멸 플래시.
/// PhysicsBody 부착 0 — 순수 시각. BombFlashNode 패턴 답습이나 색·타이밍·zPosition 차이로
/// 별도 클래스. 공통 추출(BaseFlashNode)은 Rule of three(3개 등장) 시점까지 보류.
/// Spring 비유: 같은 인터페이스(SelfDismissingNode)를 따르는 두 번째 구현체 —
/// BombFlashNode가 누런 폭탄 잔상이라면 HitFlashNode는 붉은 피격 잔상.
final class HitFlashNode: SKSpriteNode, SelfDismissingNode {

    // MARK: - Init
    init() {
        // ColorTokens.ganhoBloodAccent — assets.md에 "피격 플래시" 용도로 이미 정의됨(재사용).
        super.init(texture: nil, color: .ganhoBloodAccent, size: .zero)
        name = "hitFlash"
        zPosition = GameConfig.hitFlashZPosition
        alpha = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Flash
    /// 부모(cameraNode)에 addChild 직후 호출. scene.size로 풀스크린 크기 부여 →
    /// fadeIn(빠름) → fadeOut(느림, peakAlpha부터) → 자가 제거.
    /// peakAlpha 미만으로 페이드 — 시야 완전 차단 방지(플레이어가 상황 인지 가능).
    /// self 미사용 — [weak self] 캡처 불필요.
    func flash(sceneSize: CGSize) {
        size = sceneSize
        position = .zero
        let fadeIn = SKAction.fadeAlpha(to: GameConfig.hitFlashPeakAlpha,
                                        duration: GameConfig.hitFlashFadeInDuration)
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.hitFlashFadeOutDuration)
        let cleanup = SKAction.removeFromParent()
        run(.sequence([fadeIn, fadeOut, cleanup]))
    }
}
```

**BombFlashNode와의 차이 표**:

| 항목 | BombFlashNode | HitFlashNode |
|---|---|---|
| 색 | `.ganhoPaper` (누런 흰빛) | `.ganhoBloodAccent` (붉은) |
| 시작 지연 | `wait(2.1)` 후 점등 | 즉시 점등 |
| fadeIn 최대 alpha | 1.0 (완전 차단) | `peakAlpha=0.55` (반투명) |
| zPosition | 250 | 200 |
| 트리거 이벤트 | AIRFORCE 이스터에그 | F 투사체 피격 |
| fadeIn 길이 | 0.07 | 0.05 |
| fadeOut 길이 | 0.35 | 0.25 |

---

### 기능 4: GameScene — `onProjectileHitPlayer` 콜백 확장

**변경 전**:
```swift
contactRouter.onProjectileHitPlayer = { [weak self] in
    self?.endGame()
}
```

**변경 후 (Phase 6-9)**:
```swift
contactRouter.onProjectileHitPlayer = { [weak self] in
    guard let self = self else { return }
    // Phase 6-9 — 시각 임팩트 2채널: 카메라 셰이크 + 빨간 플래시.
    // haptics.heavy() (6-1) + audio.play(.gameOver) (6-2) + BGM stop (6-4)은
    // endGame() 내부에서 이미 발화 — 3채널 멀티모달 피격 피드백 완성.
    // 시각 효과 → 상태 전환 순서: 피격 콜백에서 시각만 일으키고,
    // gameOver 상태 전환은 endGame이 전담(책임 분리).
    self.cameraNode.run(CameraShakeAction.make())
    let flash = HitFlashNode()
    self.cameraNode.addChild(flash)
    flash.flash(sceneSize: self.size)
    self.endGame()
}
```

**Generator 유연성**: 실제 onProjectileHitPlayer 클로저 이름이 다를 수 있음. GameScene.swift를 읽고 정확히 매칭 — F 투사체 피격 콜백 1지점.

---

### 기능 5: project.pbxproj 등록

새 파일 2개를 SparkleEffectNode 등록 라인 4곳 형식으로 추가:

1. **HitFlashNode.swift** (Nodes 그룹)
   - PBXBuildFile
   - PBXFileReference
   - Nodes 그룹 children
   - Sources build phase

2. **CameraShakeAction.swift** (Systems 그룹)
   - PBXBuildFile
   - PBXFileReference
   - Systems 그룹 children (없으면 신규 생성하지 말고 Sources 그룹에 자유 배치)
   - Sources build phase

**UUID**: 기존 패턴(`A1C0F1Axxxxxxxxxxxxxxxxxx`, `A1C0F1Bxxxxxxxxxxxxxxxxxx`) 답습. 충돌 안 나는 새 hex 2쌍 생성.

---

## 검증 시나리오

### (a) 빌드
- `xcodebuild ... build` → BUILD SUCCEEDED, 경고 0
- 새 파일 2개 Sources phase에 등록 확인

### (b) F 피격 시 3채널 동시 발화
- 시뮬레이터에서 F 맞춤 → 진동(heavy) + 화면 흔들림 + 빨간 깜빡임 동시
- 콘솔 print 없이 육안 확인

### (c) 카메라 원위치 정확
- 셰이크 직후 카메라 X 좌표 = 셰이크 직전 X 좌표(±0.01pt)
- 누적 변위 0 보장 (count=6 수동 검산 통과)

### (d) 메모리 누수 0
- HitFlashNode `removeFromParent` 자가 호출
- ResultScene 전환 시 GameScene → cameraNode → flash 자식 ARC 자동 해제
- CameraShakeAction은 노드 아님 — SKAction 반환만, 누수 가능성 없음

### (e) ResultScene 전환 안전
- presentScene fade(0.4초)가 셰이크(0.28초) + 플래시(0.30초)를 덮음
- 크래시 위험 0

### (f) 시간 만료 endGame은 영향 없음
- 시간 만료는 update 내 endGame 직접 호출
- onProjectileHitPlayer 콜백 우회 → 시각 효과 미발화
- *피격 전용* 피드백 책임 분리 보존

### (g) enemy 접촉 endGame도 영향 없음
- onEnemyHit 콜백은 그대로 self?.endGame() — 시각 효과 미발화
- 수간호사 직접 접촉 vs F 투사체 피격 디자인 분리

### (h) 회귀 0줄
- AudioManager / HapticsManager / BGMPlayer / ScoreSystem / ContactRouter 시그니처 / SpawnSystem
- TitleScene / ResultScene / 기존 Nodes (NoteNode/Player/Enemy/Projectile/HUD/Card/Airplane/Bomb/AirforceOverlay/Sparkle)
- Repositories / Models / Protocols 모두 0줄

### (i) Phase 1~6 회귀
- 이동/수집/점수/HUD/적/F/게임오버/ResultScene/캐릭터선택/AIRFORCE/사운드/햅틱/BGM/Interruption/Lifecycle/sparkle 모두 정상

---

## 학습 가치

### 1. SKCameraNode 활용 — UIKit ViewController 비유
이미 `cameraNode`가 있고 player를 follow 중. *그 카메라에 SKAction을 직접 run*하는 게 셰이크의 핵심.

UIKit 비유: `UIView.animate`로 `transform.translate`를 흔드는 것 ≈ SpriteKit에서 cameraNode에 `moveBy`.

> **Spring 비유**: ViewController가 view 전체를 흔드는 게 아니라 *Camera가* 흔든다 — SpriteKit은 View ↔ Camera 분리(MVVM의 View ↔ ViewModel과 흡사). 카메라가 뷰포트의 *대리인* 역할.

### 2. 셰이크 알고리즘의 단순성
sin파 random 떨림은 *생물학적*으로 자연스럽지만, *직선 sequence*는 *예측 가능 + 디버깅 쉬움 + 코드 짧음*. 학습 단계에선 random보다 sequence가 압도적으로 유리.

> **Spring 비유**: 단순 fixed-rate scheduler vs cron expression — 본 sprint는 fixed-rate. 단순함이 학습 단계에서 가치 ↑.

random 셰이크는 Phase 7+ 폴리싱에서 검토.

### 3. 부정 피드백 vs 긍정 피드백의 디자인 대칭

| | 긍정 (6-8 sparkle) | 부정 (6-9 hit) |
|---|---|---|
| 색 | 흰빛 (별빛) | 빨강 (혈색) |
| 방향 | 노트에서 *밖으로* 방사 | 화면 전체 *덮음* |
| 시간 | 0.5초 (여운) | 0.30초 (즉발) |
| 위치 | worldNode (월드 좌표) | cameraNode (화면 좌표) |
| 이벤트 | 음표 수집 (반복) | F 피격 (1회) |
| 햅틱 | light (6-1) | heavy (6-1, 기존) |

같은 *자가 소멸 노드* 패턴을 정반대 의미에 적용하는 게 *코드 어휘 재사용*의 진수.

### 4. 화면 좌표 vs 월드 좌표
- worldNode 자식(SparkleEffectNode) = *월드 좌표* — 카메라가 움직이면 같이 움직임
- cameraNode 자식(HitFlashNode) = *화면 좌표* — 카메라가 흔들리면 같이 흔들림 + 화면에 고정

본 sprint에서 HitFlashNode를 cameraNode에 두는 이유: 플래시는 *화면을 덮는* 효과이므로 월드와 무관. 카메라 셰이크와 *함께 흔들림* → 흔들림이 더 강하게 체감됨 (영리한 부작용).

> **Spring 비유**: HTTP request scope vs application scope — 본 sprint에선 "화면(=session)에 묶인 노드" vs "세상(=global state)에 묶인 노드".

### 5. HapticsManager + 시각 임팩트 = 멀티모달 피격 피드백 5채널

게임오버 0.3초 동안 *동시* 발화하는 채널:
- haptics.heavy() (6-1) — 진동
- audio.play(.gameOver) (6-2) — 청각 (효과음)
- bgm.stop() (6-4) — 청각 (정지)
- cameraNode.run(shake) (6-9) — 운동감
- HitFlashNode (6-9) — 시각

5채널이 endGame 멱등 가드 안쪽에서 *동시* 발화 — 게임오버 0.3초가 게임의 *가장 풍부한 감각 입력 순간*. 폴리싱의 정체.

> **Spring 비유**: `@TransactionalEventListener`에 등록된 다중 리스너가 한 이벤트(피격)에 *동시* 반응 — 알림 + 로그 + 메트릭 + ... 채널 분리.

### 6. enum 네임스페이스로 정적 팩토리 만들기
`CameraShakeAction`은 case 없는 enum. 인스턴스화 차단 + `static func`만 노출. Swift에서 *namespace* 역할.

> **Spring 비유**: `@Component`가 아닌 `@UtilityClass`(Lombok) 혹은 static factory 메서드만 가진 final class. 상태 없는 순수 함수 집합.

### 7. Rule of Three — "두 번까지는 별개"
HitFlashNode와 BombFlashNode가 *비슷하지만 다른* 풀스크린 플래시. 공통 추출(BaseFlashNode protocol/superclass)을 *지금* 하지 않음. **Rule of Three** — 같은 패턴이 *3개* 등장하면 그때 추출.

> **Spring 비유**: 두 개의 비슷한 컨트롤러 메서드를 미리 abstract 컨트롤러로 묶지 말 것. 세 번째 등장 시 *진짜 공통점*이 드러남. premature abstraction 회피.

---

## 주의사항

### 시뮬레이터 동작
- **시뮬레이터 햅틱 noop**: 시각 효과는 *반드시* 시뮬레이터에서도 확인 가능 — 햅틱과 달리 셰이크/플래시는 노드 액션이라 모든 환경에서 작동.

### 카메라 follow와 셰이크 간섭
- 검증 시나리오 (c) 참조
- 호출 순서가 *셰이크 → flash → endGame*인 점이 *핵심* — 절대 순서 바꾸지 말 것
- `endGame()` 먼저 호출 시 update의 cameraNode.position 덮어쓰기가 *그 한 프레임* 안에 셰이크 첫 스텝을 잠식 가능 → 순서 고정

### GameScene+Setup.swift 미수정
본 sprint는 GameScene 본체의 *콜백 1개*만 확장. setup 로직 미접촉.

### 빌드 에러 가능성
- `CameraShakeAction` enum 네임스페이스 — `CameraShakeAction.make()` 호출 형태 정확히
- `HitFlashNode`가 `SelfDismissingNode` 채택 — 프로토콜이 marker라 추가 메서드 구현 불필요
- pbxproj UUID 충돌 시 빌드 실패 — 기존 UUID와 *정확히* 다른 hex 사용
- `ganhoBloodAccent` 토큰 존재 확인 — ColorTokens.swift에서 확인 후 재사용

### Swift / SpriteKit 규칙 준수
- 강제 언래핑 `!` 0건 (`guard let self = self else { return }` 적용)
- 매직 넘버 0건 (모든 수치 GameConfig 상수화)
- `Timer` 미사용 (SKAction.sequence만)
- update 안 addChild 0건 (콜백 안 addChild는 *이벤트 기반*이라 매 프레임 아님)
- weak self 캡처 적용 (`onProjectileHitPlayer = { [weak self] in ... }`)

### Sprint 범위 위반 자가 점검
SPEC에 *없는* "셰이크 강도를 콤보 수에 비례", "플래시 색을 콤보 등급별로 변경" 등 추가 *금지*. 이번 sprint는 셰이크 1가지 + 플래시 1가지로 충분.

---

## Generator 체크리스트

- [ ] `Config/GameConfig.swift` 끝에 Hit Feedback 섹션 + 상수 7개 추가
- [ ] `Systems/CameraShakeAction.swift` 신설 — enum 네임스페이스, static func make()
- [ ] `Nodes/HitFlashNode.swift` 신설 — SelfDismissingNode 채택, SKSpriteNode 상속
- [ ] HitFlashNode.flash(sceneSize:) 메서드 sequence([fadeIn, fadeOut, removeFromParent])
- [ ] CameraShakeAction.make() 마지막 복귀 단계 누적 변위 0 검산 통과
- [ ] `GameScene.swift` onProjectileHitPlayer 콜백 5줄로 확장 (셰이크 → flash 부착 → endGame 순서)
- [ ] 헤더 주석 1줄 추가
- [ ] pbxproj 4지점 × 2파일 = 8지점 등록 (UUID 충돌 0)
- [ ] 빌드 BUILD SUCCEEDED + 경고 0
- [ ] 회귀 0줄 (검증 시나리오 (h) 항목 git diff 통과)
- [ ] 강제 언래핑 0, 매직 넘버 0, Timer 0
