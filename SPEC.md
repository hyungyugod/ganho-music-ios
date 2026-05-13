# Phase 6-8 — 음표 수집 시 sparkle 파티클 효과

## 개요
현재 음표를 먹으면 점수가 오르고 효과음(`audio.play(.noteCollected)`) + 햅틱(`haptics.light()`)만 나오고 시각 변화는 0이다. Phase 6-8은 음표 수집 순간에 8방향으로 튀어나오는 작은 sparkle 파편(SKShapeNode 원형)을 음표 위치에 spawn 시켜 *수집 만족감 + 음악=별의 미학*을 시각적으로 완성한다. Phase 6-1~6-7의 사운드/햅틱/BGM 시리즈에 이어 첫 *시각 폴리싱* sprint.

## 변경 유형
**폴리싱 / 시각 임팩트** (Evaluator는 비주얼 트랙으로 채점 — 게임 로직/점수 계산 영향 0, 새 SKShapeNode 도형 패턴 + SKAction.group 학습이 핵심)

## 게임 경험 의도
사용자가 새벽 병동에서 작곡한 BGM이 깔린 가운데, 음표를 먹는 순간이 *별이 터지는 순간*처럼 느껴져야 한다. 8개의 작은 흰빛 파편이 8방향으로 퍼지며 0.5초 안에 사라지는 — 짧지만 또렷한 *반짝*. "음악 = 별"이라는 자전적 미학(밤하늘 같은 어두운 BG #1A1B2E 위에 분홍 음표가 별처럼 떠 있던 화면)을 한 단계 더 끌어올린다. 한 행동(=음표 수집)에 햅틱(6-1) + 사운드(6-2) + sparkle(6-8) 3채널 멀티모달 피드백을 완성하는 마지막 퍼즐.

## Sprint 범위 계약

### 허용 (필수 연동 변경만)
- 새 파일 `Nodes/SparkleEffectNode.swift` 신설 (SelfDismissingNode protocol 채택)
- `Config/GameConfig.swift`에 `// MARK: - Sparkle Effect (Phase 6-8)` 섹션 신설 + 6개 상수 추가
- `GameScene.swift`의 `configureContactRouter()` 안 `onNoteCollected` 클로저에 sparkle spawn 5줄 추가 (note 위치를 worldNode 좌표로 캡처해 sparkle 부착)
- 파일 상단 주석에 `Phase 6-8 · 음표 수집 시 sparkle 8방향 방사 (시각 폴리싱)` 한 줄 추가
- `GanhoMusic.xcodeproj/project.pbxproj`에 `SparkleEffectNode.swift` 4지점 등록 (PBXBuildFile, PBXFileReference, Nodes 그룹 children, Sources build phase)

### 금지 (Sprint 범위 위반 시 자동 감점)
- 외부 SKEmitterNode / `.sks` 파티클 파일 사용 — **코드만**으로 SKShapeNode 사용
- `GameScene` / `ContactRouter` / `ScoreSystem` / `SpawnSystem`의 *시그니처/책임 경계* 변경
- 새 PhysicsCategory 추가, sparkle에 PhysicsBody 부착 (파티클은 충돌 0)
- 새 효과음 / 햅틱 / BGM 트리거 추가 (이번은 *시각만*)
- `HighScoreRepository` / `StatisticsRepository` / `CharacterPreferenceRepository` / `BGMPlayer` / `AudioManager` / `HapticsManager` 변경
- 새 GameScene 진입점 / 새 Scene 신설 / 캐릭터 시스템 변경
- 매직 넘버 하드코딩 (모든 상수는 GameConfig 경유)
- 강제 언래핑 `!` / `Timer` 사용 / `update()` 안 `addChild()` 호출
- ColorTokens.swift에 새 색 추가 (기존 토큰 또는 `SKColor.white` 사용 — 흰빛 파편)

### 판단 기준
> "이 변경이 없으면 sparkle이 음표 위치에서 안 보이는가?" → YES면 허용, NO면 금지.

---

## 변경 범위

### 수정할 파일
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`
  - `// MARK: - Sparkle Effect (Phase 6-8)` 섹션 신설, 상수 6개 추가
- `GanhoMusic/GanhoMusic Shared/GameScene.swift`
  - `configureContactRouter()` 내 `contactRouter.onNoteCollected` 클로저에 sparkle spawn 코드 3~5줄 추가 (note 위치 캡처 → SparkleEffectNode 생성 → worldNode에 addChild → emit 호출)
  - 파일 상단 주석에 `Phase 6-8 · 음표 수집 시 sparkle 8방향 방사 (시각 폴리싱)` 한 줄 추가
- `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj`
  - SparkleEffectNode.swift 4지점 등록 (BombFlashNode.swift 등록 패턴 답습)

### 추가할 파일
- `GanhoMusic/GanhoMusic Shared/Nodes/SparkleEffectNode.swift`
  - SKNode 컨테이너. 자식으로 8개의 SKShapeNode 원형 파편. SelfDismissingNode 채택.

---

## 기능 상세

### 기능 1: GameConfig 상수 6개 추가

**구현 위치**: `Config/GameConfig.swift` 파일 맨 아래 (`bgmFadeOutDuration` 다음)

```swift
// MARK: - Sparkle Effect (Phase 6-8)
/// 음표 수집 시 방사되는 sparkle 파편 개수. 8방향 균등 방사 — 정팔각형.
/// 4면 너무 빈약, 16면 시각 노이즈. 8이 균형점. GDD: 음악=별 미학.
static let sparkleParticleCount: Int = 8
/// sparkle 파편 1개의 반지름 (pt). 음표 한 변(16)의 1/8 = 2.0pt. 작은 별빛 입자 톤.
static let sparkleParticleRadius: CGFloat = 2.0
/// sparkle 방사 거리 (pt). 노트 중심에서 파편이 도달하는 최대 거리.
/// 음표 한 변(16)의 ~1.5배 = 24pt. 너무 멀면 인접 음표와 겹침, 가까우면 임팩트 약함.
static let sparkleSpawnDistance: CGFloat = 24
/// sparkle 페이드/이동 액션 총 길이 (초). group 액션 묶음의 duration.
/// 너무 길면 다음 음표 수집과 겹쳐 시각 노이즈. 0.5초가 *반짝*의 적정선.
static let sparkleFadeDuration: TimeInterval = 0.5
/// sparkle 파편 zPosition. HUD(100) 아래, Player/Note(0~5) 위 — 노트가 사라진 자리에서 위로 떠오르는 느낌.
static let sparkleZPosition: CGFloat = 30
/// sparkle 파편의 끝 스케일. 0.0이면 한 점으로 수렴(별빛 꺼짐), 1.0이면 동일 크기 유지.
/// 0.2면 페이드아웃 + 살짝 축소 — 별이 멀어지는 느낌.
static let sparkleEndScale: CGFloat = 0.2
```

**주의**: 매직 넘버 노출 0건. 모든 SparkleEffectNode 내부 수치는 이 상수만 참조.

---

### 기능 2: SparkleEffectNode 신설 (자가 소멸 노드 4호)

**구현 위치**: 새 파일 `Nodes/SparkleEffectNode.swift`

**책임**:
- SKNode 컨테이너 (자식으로 SKShapeNode 8개를 보유)
- emit() 호출 시 각 파편을 8방향(45° 간격)으로 동시에 이동 + 페이드아웃 + 스케일 다운
- SKAction.group([move, fadeOut, scale])로 *동시 진행* → group 끝나면 컨테이너 자가 제거

**Spring 비유**: `@TransactionalEventListener` 다중 listener — 한 이벤트(= 음표 수집)에 햅틱/사운드/sparkle 3개 listener가 *동시*에 반응. SKAction.group이 바로 동시 실행 컨테이너.

**핵심 코드 구조**:

```swift
//
//  SparkleEffectNode.swift
//  GanhoMusic Shared
//
//  Phase 6-8 · 음표 수집 시 sparkle 8방향 방사 + 자가 소멸 (시각 폴리싱)
//

import SpriteKit

/// 음표 수집 시 노트 위치에서 8방향으로 방사되는 sparkle 파편 컨테이너.
/// PhysicsBody 부착 0 — 순수 시각. SKAction.group(이동 + 페이드 + 스케일)을
/// 8개 자식 SKShapeNode에 *동시* 실행 → 0.5초 후 컨테이너 자가 제거.
/// AirplaneNode / AirforceOverlayNode / BombFlashNode 패턴 답습 — 자가 소멸 노드 4회차.
/// Spring 비유: @TransactionalEventListener 다중 listener — 한 이벤트(노트 수집)에
/// 햅틱(6-1) + 사운드(6-2) + sparkle(6-8) 3채널 멀티모달 반응.
final class SparkleEffectNode: SKNode, SelfDismissingNode {

    // MARK: - Init
    override init() {
        super.init()
        name = "sparkle"
        zPosition = GameConfig.sparkleZPosition
        buildParticles()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Particles
    /// 8개의 SKShapeNode 원형 파편을 자식으로 부착. 모두 (0,0)에서 출발.
    /// 색은 기존 ColorTokens 또는 SKColor.white — 어두운 BG 위 별빛 톤. 새 ColorTokens 추가 금지.
    private func buildParticles() {
        for _ in 0..<GameConfig.sparkleParticleCount {
            let particle = SKShapeNode(circleOfRadius: GameConfig.sparkleParticleRadius)
            particle.fillColor = .white               // 또는 .ganhoPaper 등 기존 토큰
            particle.strokeColor = .clear             // 외곽선 없음 — 순수 별빛
            particle.position = .zero
            addChild(particle)
        }
    }

    // MARK: - Emit
    /// 부모(worldNode)에 addChild 직후 호출. 각 파편에 8방향 SKAction.group를 *동시*에 run.
    /// group 액션은 [move, fadeOut, scale]을 *동시* 진행 — Spring의 CompletableFuture.allOf와 유사.
    /// 마지막 .removeFromParent()는 컨테이너(self)가 자가 제거.
    func emit() {
        let angleStep = (2 * CGFloat.pi) / CGFloat(GameConfig.sparkleParticleCount)
        for (index, child) in children.enumerated() {
            let angle = angleStep * CGFloat(index)
            let dx = cos(angle) * GameConfig.sparkleSpawnDistance
            let dy = sin(angle) * GameConfig.sparkleSpawnDistance
            let move  = SKAction.moveBy(x: dx, y: dy, duration: GameConfig.sparkleFadeDuration)
            let fade  = SKAction.fadeOut(withDuration: GameConfig.sparkleFadeDuration)
            let scale = SKAction.scale(to: GameConfig.sparkleEndScale,
                                       duration: GameConfig.sparkleFadeDuration)
            child.run(.group([move, fade, scale]))
        }
        // 컨테이너 자가 제거: group 길이만큼 대기 후 removeFromParent.
        // child 액션과 동일한 sparkleFadeDuration으로 묶어 정확한 타이밍 보장.
        let wait    = SKAction.wait(forDuration: GameConfig.sparkleFadeDuration)
        let cleanup = SKAction.removeFromParent()
        run(.sequence([wait, cleanup]))
    }
}
```

**SelfDismissingNode 채택 이유**:
- 기존 4-R protocol(AirplaneNode/AirforceOverlayNode/BombFlashNode 마커)과 일관성
- 미래에 protocol extension으로 *공통 동작*(예: didEmit 콜백)을 추가 가능

---

### 기능 3: GameScene에서 sparkle spawn 트리거

**구현 위치**: `GameScene.swift` → `configureContactRouter()` 메서드 내 `contactRouter.onNoteCollected` 클로저

**개념적 변경 후 (Generator가 실제 코드와 매칭)**:
```swift
contactRouter.onNoteCollected = { [weak self] note in
    guard let self = self else { return }
    self.scoreSystem.recordNoteHit(at: self.lastUpdateTime)
    self.haptics.light()
    self.audio.play(.noteCollected)
    // Phase 6-8 — note 위치에서 sparkle 8방향 방사. note는 worldNode 자식이므로
    // worldNode 좌표계 위치를 캡처해 같은 worldNode에 sparkle을 부착.
    // note.position을 *먼저* 캡처 — note.removeFromParent() 후엔 노드가 트리에서 빠짐.
    let sparkleOrigin = note.position
    let sparkle = SparkleEffectNode()
    sparkle.position = sparkleOrigin
    self.worldNode.addChild(sparkle)
    sparkle.emit()
    note.run(.removeFromParent())
}
```

**주의 — note 좌표 캡처 타이밍**:
1. `note.position`은 *worldNode 자식*의 좌표 (note의 parent가 worldNode이므로 worldNode 좌표계 기준값)
2. `.removeFromParent()` 실행 *전에* position을 캡처해야 함 — 제거 후엔 parent가 nil이라 좌표 보장 X
3. sparkle도 같은 worldNode에 add → 같은 좌표계 → 카메라 follow / 월드 스크롤과 함께 자연스럽게 따라감

**Generator 유연성**: 실제 onNoteCollected 클로저의 정확한 형태(파라미터 이름, 메서드명)는 GameScene.swift를 읽고 매칭. sparkle 5줄을 *기존 동작 직후, note.removeFromParent() 직전*에 삽입.

**멱등성**:
- onNoteCollected는 한 노트당 1회만 호출(ContactRouter의 didBegin)
- 이미 sparkle 8개 동시 add → 같은 음표에 두 번 sparkle 안 만들어짐
- note.removeFromParent()까지 같은 클로저 안에서 처리 — race 0

---

### 기능 4: pbxproj 4지점 등록

**구현 위치**: `GanhoMusic.xcodeproj/project.pbxproj`

BombFlashNode.swift 등록 패턴을 그대로 답습:

1. **PBXBuildFile 섹션**:
   ```
   <NEW_UUID_BUILD> /* SparkleEffectNode.swift in Sources */ = {isa = PBXBuildFile; fileRef = <NEW_UUID_FILE> /* SparkleEffectNode.swift */; };
   ```

2. **PBXFileReference 섹션**:
   ```
   <NEW_UUID_FILE> /* SparkleEffectNode.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SparkleEffectNode.swift; sourceTree = "<group>"; };
   ```

3. **Nodes 그룹 children**: SparkleEffectNode.swift 항목 추가

4. **Sources build phase**: SparkleEffectNode.swift in Sources 항목 추가

UUID는 BombFlashNode 패턴 따라 새 24자리 hex 생성. Generator는 BombFlashNode 4지점 등록을 grep해서 패턴을 그대로 복제하면 됨.

---

## 검증 시나리오

### (a) 빌드
- `xcodebuild ... build` → BUILD SUCCEEDED, 경고 0
- SparkleEffectNode.swift Sources phase에 등록 확인

### (b) 음표 수집 시각 효과
- 음표 수집 → 그 자리에 8개 흰빛 파편이 8방향으로 펼쳐짐 → 0.5초 안에 페이드아웃 + 축소
- 카메라 follow 시 sparkle도 worldNode 자식이라 함께 이동

### (c) 회귀 검증
- ScoreSystem: 점수/콤보 계산 영향 0
- ContactRouter: onNoteCollected 시그니처 동일, 본문만 5줄 추가
- SpawnSystem: 스폰 주기 영향 0
- AudioManager / HapticsManager / BGMPlayer: 변경 0줄
- 다른 Nodes (Player/Enemy/Projectile/HUD/Card/Airplane/Bomb/AirforceOverlay): 변경 0줄
- Phase 1~6 회귀: 이동/수집/점수/HUD/적/F/게임오버/ResultScene/캐릭터선택/AIRFORCE/사운드/햅틱/BGM 페이드/Interruption/Lifecycle 모두 정상

### (d) 멱등성/메모리
- 음표 1개당 sparkle 1회 (clontactRouter didBegin 1회 보장)
- sparkle 컨테이너 자가 제거 sequence([wait 0.5s, removeFromParent])
- ARC 자동 해제, 메모리 누수 0

### (e) 성능 (60fps 유지)
- 음표 수집 빈도 ~1~2/sec
- 동시 sparkle 컨테이너 최대 ~3~4 = 24~32 SKShapeNode
- SKShapeNode 도형은 GPU 친화적 경량, 60fps 영향 무시 가능

### (f) 음원 부재 / 기타 환경 회귀
- BGMPlayer 음원 부재 시 sparkle 동작에 영향 0 (독립)
- 시뮬레이터에서도 정상 동작 (SKShapeNode는 GPU 텍스처 안 필요)

---

## 학습 가치

### 1. SKAction.group vs sequence
- **group**: 여러 액션이 *동시*에 진행. 끝나는 시점은 가장 긴 액션이 끝날 때.
- **sequence**: 액션이 *차례로* 진행. 총 길이는 각 액션 합산.
- sparkle 1개 파편은 이동 + 페이드 + 스케일이 *동시* → group
- 컨테이너 자가 제거는 wait → removeFromParent *차례* → sequence

> **Spring 비유**:
> - group = `CompletableFuture.allOf(...)` — 여러 비동기 작업 동시 진행, 모두 완료 시점 대기
> - sequence = `CompletableFuture.thenCompose(...)` — 앞 작업 끝나야 다음 시작

### 2. SKShapeNode의 경량성
- SKSpriteNode는 텍스처 이미지 필요 — GPU 텍스처 캐시 점유
- SKShapeNode는 도형(원/사각형/path)만으로 GPU 친화적 렌더링
- 짧게 사라지는 파티클(0.5초)에 적합 — 텍스처 안 만들고 코드만으로 임팩트
- "별빛 입자"라는 추상 개념을 *가장 단순한 도형*인 원 8개로 표현 — 미니멀리즘

> **Spring 비유**: `@RestController`가 String 1줄 응답하는 것 vs 큰 JSON 객체 응답. 텍스처 안 필요한 단순 도형은 *가벼운 응답*과 비슷.

### 3. SelfDismissingNode 패턴의 확장 — 4호 노드
- Phase 4-R에서 SelfDismissingNode protocol 추출됨 (AirplaneNode/AirforceOverlayNode/BombFlashNode)
- 4호 노드 SparkleEffectNode가 같은 패턴 채택
- 공통 책임: "한 번 등장 → 액션 수행 → 자가 제거". 호출자는 add만 하면 됨, 정리는 노드 본인
- **노드 책임 분산 패턴의 누적** — 점점 더 많은 효과 노드가 이 패턴으로 통일됨

> **Spring 비유**: `@Async` 메서드가 호출자에게 Future 안 돌려주고 자체 종료. fire-and-forget. 호출자는 부담 0.
> 또는 자가 정리하는 임시 빈 — `@Scope(value = "request", proxyMode = ScopedProxyMode.TARGET_CLASS)`처럼 요청 끝나면 자동 정리.

### 4. 멀티모달 피드백 3채널 완성
| 채널 | Phase | 메서드 |
|---|---|---|
| 햅틱 | 6-1 | `haptics.light()` |
| 사운드 | 6-2 | `audio.play(.noteCollected)` |
| **시각** | **6-8** | **`sparkle.emit()`** |

한 행동(음표 수집)에 3채널이 *동시*에 반응 — 게임 피드백의 완전체. 사용자 인지 가속:
- 햅틱: 손끝으로 "맞췄다" 확인
- 사운드: 귀로 "줍힘" 확인
- 시각: 눈으로 "별이 터졌다" 확인

> **Spring 비유**: `@TransactionalEventListener`에 등록된 다중 리스너가 한 트랜잭션 이벤트에 *동시* 반응 — 알림 발송, 로그 기록, 메트릭 수집 등 채널 분리. 6-8은 그 3번째 채널(시각) 등록.

### 5. 좌표계 캡처 타이밍의 미묘함
```swift
let sparkleOrigin = note.position  // ← 먼저 캡처
// ...
note.run(.removeFromParent())      // ← 그 후 제거
```
순서가 바뀌면 `note.position`이 *의도와 다른 값*을 반환할 수 있음 — note가 parent에서 빠진 후엔 좌표 의미 불명확.

> **Spring 비유**: DB 트랜잭션 안에서 값을 *읽어둔 후* 커밋/롤백. 또는 `Optional.map { ... }` 안에서 값 처리 후 *바깥에서* 변경. 자료 수명에 대한 정확한 의식.

### 6. 음악 = 별의 미학 — 자전적 게임 정체성 완성
- 사용자가 새벽 병동에서 작곡한 BGM (6-4에서 인프라 완성)
- 어두운 BG(#1A1B2E) 위 분홍 음표 — 밤하늘 별
- 음표 수집 시 *별이 터지는* sparkle (6-8)
- → 게임 정체성의 시각적 완성. "병동에서 작곡하던 새벽, 별빛 같은 음악이 잠시 반짝이고 사라졌다"는 자전적 톤이 사용자에게 직접 전달

학생 비유: "노래방에서 곡을 부르고 박수받는 순간 → 박수 소리 + 진동 + 마이크 조명 깜빡임이 동시. 만약 박수만 있고 조명이 없으면 뭔가 허전해요. 조명이 sparkle 역할."

---

## 주의사항

### SpriteKit 특성
- **SKShapeNode의 가벼움**: 텍스처 없이 원/사각형 등 도형만으로 만들어 텍스처 캐시 부담 0. circleOfRadius는 GPU 친화적 경량 노드. *별빛 입자 8개 × 0.5초만 살아있음*이라 60fps에 거의 부담 없음.
- **SKAction.group vs sequence**: group은 *동시*에, sequence는 *차례로*. sparkle은 이동 + 페이드 + 스케일이 *동시* 진행되어야 하므로 group. 컨테이너 자가 제거는 wait + removeFromParent의 sequence.
- **부모 좌표계 일관성**: note는 worldNode 자식이므로 note.position도 worldNode 기준. sparkle도 worldNode에 add → 같은 좌표계 → 카메라 follow 시 sparkle도 같이 이동.
- **note 제거 순서**: `note.position` 캡처 → sparkle add → note.removeFromParent(). 순서 바뀌면 좌표 lost.

### 회귀 안전성
- **ScoreSystem 영향 0**: recordNoteHit 호출 위치/인자 동일. score/combo 계산 변경 0.
- **ContactRouter 영향 0**: onNoteCollected 시그니처 동일. 콜백 본문만 5줄 추가.
- **SpawnSystem 영향 0**: 음표 스폰 주기/개수 변경 0. noteMaxConcurrent와 무관.
- **성능**: sparkle 1회당 8 SKShapeNode + 8 SKAction = 16 객체. 음표 수집 빈도 ~1~2/sec. 동시 sparkle 컨테이너 최대 ~3~4 = 24~32 노드 → 60fps 유지 가능.
- **메모리**: 각 sparkle 0.5초 후 자가 제거 → 누적 0. ARC가 자동 해제.

### Swift / SpriteKit 규칙 준수
- 강제 언래핑 `!` 0건
- `guard let self = self else { return }` 패턴 유지
- `[weak self]` 캡처 유지
- Timer 미사용 — SKAction만
- 매직 넘버 0건 — GameConfig 상수 6개 신설
- 한국어 변수명 0건. 주석은 한국어 OK.

### 빌드 에러 가능성
- pbxproj UUID 충돌: BombFlashNode 등 기존 UUID와 안 겹치는 새 24자리 hex 사용
- `import SpriteKit` 누락: SparkleEffectNode.swift 맨 위 명시
- `SKColor` vs `UIColor`: SpriteKit 코드는 import SpriteKit 시 SKColor 사용. iOS에서 UIColor == SKColor.

---

## Generator 체크리스트 (구현 후 자체 검증)

- [ ] `Config/GameConfig.swift` 맨 아래 Sparkle Effect 섹션 6개 상수 추가
- [ ] `Nodes/SparkleEffectNode.swift` 신설 — SelfDismissingNode 채택, SKNode 상속, 8개 SKShapeNode 자식
- [ ] `buildParticles()`는 init 시점에만 호출 — update 안 addChild 0건
- [ ] `emit()` 안 SKAction.group([move, fade, scale]) 패턴 정확히 적용
- [ ] 컨테이너 자가 제거 sequence([wait, removeFromParent]) 적용
- [ ] `GameScene.swift` onNoteCollected 클로저에 sparkle spawn 5줄 추가, `note.position` 캡처를 `.removeFromParent()` *이전*에 수행
- [ ] sparkle은 `self.worldNode`에 addChild (cameraNode 아님 — note와 같은 좌표계)
- [ ] pbxproj 4지점 등록 (BombFlashNode 패턴 grep으로 확인)
- [ ] 강제 언래핑 `!` 0건
- [ ] Timer 0건, SKAction만 사용
- [ ] 매직 넘버 0건 (모든 수치는 GameConfig 경유)
- [ ] `[weak self]` 캡처 유지
- [ ] 새 색/효과음/햅틱/PhysicsCategory 추가 0건
- [ ] GameScene / ContactRouter / ScoreSystem / SpawnSystem 시그니처 변경 0건
- [ ] 빌드 클린 + 시뮬레이터에서 음표 수집 시 흰빛 8방향 sparkle 확인
