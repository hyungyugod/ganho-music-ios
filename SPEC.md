# SPEC.md — Phase 6-11: 콤보 마일스톤 도달 시 사운드 + 햅틱 (3감각 완성)

## 개요
Phase 6-10에서 콤보 마일스톤(3/5/10/20) 도달 시 화면 중앙 텍스트 팝업을 시각 단독으로 마무리했다. 이번 6-11은 동일 순간에 **사운드(AudioManager)**와 **햅틱(HapticsManager)**을 추가해 시각/청각/촉각 3감각이 동시 발화하는 환호 완성 sprint. 노트 수집(6-1/6-2)과 게임오버(6-1/6-2)에 이어 **세 번째 멀티모달 이벤트** — 멀티모달 패턴의 굳히기.

## 변경 유형
**혼합** — 표면적으로는 사운드/햅틱 추가지만, "콤보 마일스톤 도달"이라는 게임플레이 이벤트의 *피드백 채널 확장*이라 게임플레이 톤 변화를 수반한다. 비주얼-only(6-10) 결과물에 청각/촉각 트리거 2채널이 같은 게이트(`triggeredComboMilestones` 멱등성 가드) 안쪽에 들어간다. → Evaluator는 게임플레이 + 비주얼 양쪽 기준을 함께 본다.

## 게임 경험 의도
플레이어가 콤보 5를 달성한 순간 화면 중앙에 분홍 "x5"가 떠오를 뿐 아니라, 손끝에 짧은 "톡!" 진동이 오고 귀에 가벼운 "딩!" 효과음이 들린다. 콤보 20을 달성하는 클라이맥스 순간엔 묵직한 "툭!"과 함께 빨간 "x20"이 폭발하듯 떠오른다. **시각만으로는 "잘하고 있어!"가 조용하지만, 3감각이 동시 발화하면 환호로 변한다** — 자전적 곡 클라이맥스의 *육체적 체감*. 마일스톤 등급이 올라갈수록 강도가 점진적으로 강해져, 플레이어가 자신의 성취가 *커지고 있다*는 신호를 글자 없이도 인지한다.

## Sprint 범위 계약
- **허용**:
  - `GameConfig` 하단에 콤보 마일스톤 사운드/햅틱 매핑 상수 추가
  - `AudioManager.SFX`에 마일스톤 사운드 케이스 2개 추가 (light/heavy 톤)
  - `HapticsManager`에 `medium()` 메서드 1개 추가 (light/heavy 사이 중간 톤)
  - `GameScene.configureContactRouter()` 내부 콤보 마일스톤 분기 안쪽에 사운드/햅틱 호출 2줄 추가
  - 마일스톤 → 사운드/햅틱 매핑을 결정하는 helper 또는 switch 분기 (GameScene 또는 ComboPopupNode 내부)
- **금지**:
  - ComboPopupNode 시각 코드 (라벨/애니메이션/색상) 변경
  - ScoreSystem / ContactRouter / SpawnSystem / HUDNode / BGMPlayer / Repositories / Models / Protocols / 기존 Nodes / Scenes / ColorTokens / TitleScene / ResultScene 변경
  - `GameConfig.comboMilestones` 배열 자체 변경 (3/5/10/20 그대로 유지)
  - 새 SKAction / SKNode 노드 생성 (사운드/햅틱은 매니저 호출만)
  - `triggeredComboMilestones` Set의 멱등성 가드 *위치 또는 의미* 변경 — 가드 안쪽에서만 사운드/햅틱 발화
  - BGM 페이드 인/아웃 / 인터럽션 / 라이프사이클 로직 변경
- **판단 기준**: "이 변경이 없으면 마일스톤 도달 시 3감각 동시 발화가 안 되는가?" → YES면 허용, NO면 금지.

---

## 마일스톤별 사운드/햅틱 강도 매핑 결정 표

| 마일스톤 | 시각 (6-10 기존) | **햅틱 (신규)** | **사운드 (신규)** | 강도 의미 |
|---|---|---|---|---|
| x3 (첫 환호) | `.ganhoPaper` 흰빛 | `light()` (재사용) | `.comboMilestoneSoft` (1057 Tink — 노트와 동일 톤) | 가벼운 환호 — 노트 수집(light/Tink)과 유사한 톤. 첫 마일스톤 → *조용한 인정* |
| x5 (정착) | `.ganhoPinkNote` 분홍 | `light()` (재사용) | `.comboMilestoneSoft` (1057 Tink) | 가벼운 환호 유지 — 너무 빠르게 강도 올리면 클라이맥스 헛김 |
| x10 (황금기) | `.ganhoYellowF` 황금 | `medium()` (신규) | `.comboMilestoneStrong` (1025 NewMail 또는 1115 — 좀 더 묵직한 메탈릭) | 중간 강도 — 황금기 진입의 신호 |
| x20 (클라이맥스) | `.ganhoBloodAccent` 빨강 | `heavy()` (재사용) | `.comboMilestoneStrong` (1025) | 묵직한 환호 — gameOver(heavy/Boop)와 같은 무게지만 톤은 긍정 |

**결정 근거**:
- **광역 그룹화 (2-2-2 매핑)**: x3/x5 → light+soft, x10 → medium+strong, x20 → heavy+strong. 4 마일스톤 × 2 채널 = 8 상수가 아니라, 강도 2~3 단계로 그룹화해 인지 부담 감소.
- **light/heavy 재사용**: HapticsManager는 light/heavy 이미 존재 → light/heavy를 *재사용*하고 `medium()` 1개만 신규 추가. 4 마일스톤마다 별개 강도 만들면 과잉.
- **시스템 사운드 ID 1025/1057 선정**: 1057(Tink)은 noteCollected와 동일 → x3/x5는 노트 수집의 *연장선*임을 청각으로 전달. 1025(NewMail)는 더 묵직한 알림 톤 → x10/x20은 *별개 사건*임을 표현. gameOver(1073 Boop)와는 다른 톤이어야 환호 vs 종료가 혼동 안 됨.
- **6-10 색상 등급(흰→분홍→황금→빨강)과 정합**: 시각이 4단계 차등인데 햅틱/사운드는 2~3단계. 시각이 *세밀*하고 청각/촉각이 *광역*인 건 인간 지각 특성 일치 (색은 미세 구분 가능, 진동/소리는 거친 카테고리).

---

## AudioManager / HapticsManager 기존 API 호출 vs 신규 API 추가 결정

### AudioManager — **신규 SFX 케이스 2개 추가** (기존 API 시그니처 유지)
- 기존 `SFX.noteCollected` / `SFX.gameOver`를 재사용하지 *않는다*. 이유:
  - 노트 수집 = 자주 발생(초당 ~1회), 마일스톤 = 한 판에 ~4회. 청각 차별화 필요 — 사용자가 "이번 건 *마일스톤*"임을 즉시 인지해야 함.
  - 시스템 사운드 ID만 다른 새 케이스라 enum 확장 비용 최소.
- 추가할 케이스:
  ```swift
  enum SFX {
      case noteCollected
      case gameOver
      case comboMilestoneSoft      // 신규 — x3 / x5
      case comboMilestoneStrong    // 신규 — x10 / x20
  }
  ```
- `fileName` / `systemSoundID` switch 양쪽에 케이스 매핑 추가 (exhaustive switch 유지 — `default` 금지). `fileName`은 `nil` 또는 `"combosoft"` / `"combostrong"` 둘 다 가능하지만 본 sprint는 음원 파일 부재를 가정 → `nil` 반환 → systemSoundID 폴백 경로로 자연 처리. 이후 sprint에서 자작 음원 추가 시 fileName만 갈아끼우면 됨(OCP).
- `play(_:)` 메서드 시그니처 미변경 — 호출부에서 `audio.play(.comboMilestoneSoft)`처럼 자연 확장.
- `init`의 `allCases` 배열은 `[.noteCollected, .gameOver, .comboMilestoneSoft, .comboMilestoneStrong]`로 확장 (Bundle 로딩 실패는 graceful — fileName nil이면 `for` 루프에서 자동 continue, 회귀 0).

### HapticsManager — **medium() 메서드 1개 신규 + light/heavy 재사용**
- 기존 `light()` / `heavy()` 그대로 유지.
- `medium()` 신규 추가:
  ```swift
  private let mediumGenerator: UIImpactFeedbackGenerator
  // init: mediumGenerator = UIImpactFeedbackGenerator(style: .medium); mediumGenerator.prepare()
  func medium() {
      mediumGenerator.impactOccurred()
      mediumGenerator.prepare()
  }
  ```
- `UIImpactFeedbackGenerator.FeedbackStyle.medium`은 light/heavy 사이 강도 — Apple 표준이라 별도 튜닝 불필요.
- `prepare()` 캐시 워밍 패턴(6-1 학습 노트)을 동일하게 적용 — init에서 1회 + medium() 호출 직후마다.

**결정 근거**: HapticsManager는 light/medium/heavy 3단계가 *완성형* 매핑. AudioManager는 케이스 enum이라 SFX 늘리는 게 자연. 두 매니저의 *확장 방식*이 다른 건 각자의 인터페이스 모양이 다르기 때문(enum-driven vs method-driven). 일관성보다 *자연스러움* 우선.

---

## 멱등성 — `triggeredComboMilestones` Set과의 관계

**핵심 원칙**: 사운드/햅틱은 **반드시** 6-10에서 검증된 멱등성 가드 *안쪽*에서 발화. 가드 밖에서 호출하면 한 판에 콤보 3을 여러 번 도달할 때마다 "딩!" 진동이 반복돼 시각 팝업과 *비대칭*이 발생.

### 6-10 패턴 재사용
```swift
// 현재 (6-10):
let currentCombo = self.scoreSystem.combo
if GameConfig.comboMilestones.contains(currentCombo),
   !self.triggeredComboMilestones.contains(currentCombo) {
    self.triggeredComboMilestones.insert(currentCombo)
    let popup = ComboPopupNode(milestone: currentCombo)
    self.cameraNode.addChild(popup)
    popup.animate()
}

// 6-11 후 (가드 안쪽에 2줄 추가):
let currentCombo = self.scoreSystem.combo
if GameConfig.comboMilestones.contains(currentCombo),
   !self.triggeredComboMilestones.contains(currentCombo) {
    self.triggeredComboMilestones.insert(currentCombo)
    // 신규 — 시각보다 먼저 (촉각 → 청각 → 시각 순서)
    self.haptics.medium()                  // helper로 마일스톤 → light/medium/heavy 분기
    self.audio.play(.comboMilestoneSoft)   // helper로 마일스톤 → soft/strong 분기
    // 기존 시각 (6-10):
    let popup = ComboPopupNode(milestone: currentCombo)
    self.cameraNode.addChild(popup)
    popup.animate()
}
```

### 자동 리셋 신뢰
- `triggeredComboMilestones: Set<Int> = []`는 GameScene 새 인스턴스에서 빈 Set로 자동 초기화 (6-10 학습 노트 §"자동 리셋의 우아함" 참조).
- 사운드/햅틱은 *상태 없음* — 호출하면 즉시 발화 후 사라짐 (side-effect). 별도 리셋 코드 필요 0.
- `endGame()`이나 `didMove(to:)`에 추가 정리 로직 **추가 금지** — 인스턴스 라이프사이클 신뢰가 6-10의 결정. 6-11도 같은 결정을 유지해야 패턴 일관성.

### Spring 비유
- `triggeredComboMilestones` = `idempotency-key` 헤더로 같은 요청을 중복 처리하지 않는 결제 API.
- 가드 안쪽에 *부수효과 호출 N개*를 두는 건 결제 성공 시 (1) DB 기록 + (2) 이메일 발송 + (3) SMS 발송 + (4) 푸시 알림 — 모두 *같은 트랜잭션 안쪽*에서 발화하는 것과 동형. 트랜잭션 밖이면 중복 위험.

---

## ComboPopupNode와의 호출 순서 결정

**채택 순서**: `haptics.medium()` → `audio.play(.comboMilestoneSoft)` → `popup.animate()` (시각이 *마지막*)

### 근거
1. **6-1/6-2 패턴 답습**: 노트 수집에서도 `haptics.light()` → `audio.play(.noteCollected)` → (시각: sparkle.emit()) 순서. 6-2 학습 노트 §"코드 순서: 햅틱 → 사운드 (의미상)"에서 "촉각(즉각·물리적) → 청각(논리적·살짝 지연) → 시각" 규칙 확립됨.
2. **인간 지각 시간축**:
   - 촉각: 0~10ms (가장 즉각, 신체 표면)
   - 청각: ~30ms (음파 전달)
   - 시각: 60ms+ (망막 → 시각 피질, SKAction 1프레임)
   - 코드 순서가 *체감 순서*와 일치하면 한 사건이 일관된 임팩트로 도달.
3. **한 프레임 내 동시성**: 셋 다 한 `update()` 사이클 안 (1/60초)이라 사람은 차이 못 느낌. 그래도 *약속*을 굳히는 게 미래의 일관성.
4. **6-10 시각 코드는 마지막에 위치** — 6-11이 가드 안쪽에 *prepend*하는 형태로 추가되어 기존 시각 흐름 보존 (회귀 0).

### Spring 비유
- 한 이벤트에 다중 listener가 등록된 경우 `@Order` 어노테이션으로 실행 순서 지정 — 우리도 코드 라인 순서가 곧 실행 순서.
- 촉각 listener (`@Order(1)`) → 청각 listener (`@Order(2)`) → 시각 listener (`@Order(3)`).

---

## 변경 범위

### 수정할 파일
- `GanhoMusic/GanhoMusic Shared/Managers/AudioManager.swift` — `SFX` enum에 `.comboMilestoneSoft` / `.comboMilestoneStrong` 케이스 2개 + `fileName`/`systemSoundID` switch 매핑 + `init` 내 `allCases` 배열 확장.
- `GanhoMusic/GanhoMusic Shared/Managers/HapticsManager.swift` — `mediumGenerator` 프로퍼티 1개 + `init` 워밍 1줄 + `medium()` 메서드 1개 추가.
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift` — `// MARK: - Combo Milestone Feedback (Phase 6-11)` 섹션 신설, 마일스톤 → 햅틱/사운드 매핑 상수 또는 helper 결정에 필요한 enum/배열 추가 (아래 §"기능 상세" 참조).
- `GanhoMusic/GanhoMusic Shared/GameScene.swift` — `configureContactRouter()` 내 `onNoteCollected` 콜백 안쪽의 마일스톤 분기에 햅틱/사운드 호출 2줄 추가. 헤더 주석에 `// Phase 6-11 ...` 한 줄 추가.

### 추가할 파일
- **없음**. 모든 변경은 기존 4개 파일 안쪽 확장. 매니저 패턴(6-1/6-2)이 *확장에 열려 있고* 변경에 닫혀 있는(OCP) 형태로 설계되어 있어 enum case + 메서드 추가만으로 충분.

---

## 기능 상세

### 기능 1: AudioManager.SFX 케이스 2개 추가
- **설명**: 마일스톤 사운드를 노트 수집/게임오버와 분리. 클라이맥스 마일스톤(x10/x20)은 더 묵직한 톤.
- **구현 위치**: `Managers/AudioManager.swift` — `enum SFX` 본체 + `init`의 `allCases` 배열.
- **핵심 코드 구조**:
  ```swift
  enum SFX {
      case noteCollected
      case gameOver
      case comboMilestoneSoft     // Phase 6-11 — x3 / x5 (가벼운 환호)
      case comboMilestoneStrong   // Phase 6-11 — x10 / x20 (묵직한 환호)

      var fileName: String? {
          switch self {
          case .noteCollected:        return "note"
          case .gameOver:             return "gameover"
          case .comboMilestoneSoft:   return nil   // 음원 부재 — systemSoundID 폴백
          case .comboMilestoneStrong: return nil
          }
          // exhaustive switch — default 없음 (6-2 학습 노트 §"enum + computed property" 정책)
      }

      var systemSoundID: SystemSoundID {
          switch self {
          case .noteCollected:        return 1057  // Tink — 짧고 밝은 메탈릭 (기존)
          case .gameOver:             return 1073  // Boop — 묵직한 종료감 (기존)
          case .comboMilestoneSoft:   return 1057  // Tink — 노트 수집과 동일 (연장선 톤)
          case .comboMilestoneStrong: return 1025  // NewMail — 묵직하지만 긍정 (gameOver 1073과 차별)
          }
      }
  }

  // init 내 allCases 배열 확장:
  let allCases: [SFX] = [.noteCollected, .gameOver, .comboMilestoneSoft, .comboMilestoneStrong]
  ```
- **주의**: `default` 절 금지 (Phase 6-2 학습 노트 §"매직 넘버 정책" 정책 — 새 케이스 누락을 컴파일러가 강제 검출). 시스템 사운드 ID(1025, 1057, 1073)는 Apple 도메인 상수이므로 GameConfig가 아닌 enum 내부에 유지 (6-2 학습 노트 §"매직 넘버 정책의 미묘함").

### 기능 2: HapticsManager.medium() 추가
- **설명**: light/heavy 사이 중간 강도 햅틱. x10 마일스톤 전용.
- **구현 위치**: `Managers/HapticsManager.swift`.
- **핵심 코드 구조**:
  ```swift
  final class HapticsManager {
      // MARK: - Properties
      private let lightGenerator: UIImpactFeedbackGenerator
      private let mediumGenerator: UIImpactFeedbackGenerator   // Phase 6-11 신규
      private let heavyGenerator: UIImpactFeedbackGenerator

      // MARK: - Init
      init() {
          lightGenerator  = UIImpactFeedbackGenerator(style: .light)
          mediumGenerator = UIImpactFeedbackGenerator(style: .medium)   // Phase 6-11
          heavyGenerator  = UIImpactFeedbackGenerator(style: .heavy)
          lightGenerator.prepare()
          mediumGenerator.prepare()   // Phase 6-11 — 캐시 워밍 동일 패턴
          heavyGenerator.prepare()
      }

      // MARK: - Triggers
      func light() { lightGenerator.impactOccurred();  lightGenerator.prepare() }
      /// Phase 6-11 — 콤보 마일스톤 x10(황금기) 전용 중간 강도.
      func medium() { mediumGenerator.impactOccurred(); mediumGenerator.prepare() }
      func heavy() { heavyGenerator.impactOccurred();  heavyGenerator.prepare() }
  }
  ```
- **주의**: 시뮬레이터는 햅틱 미지원이라 UIKit이 자동 noop — 빌드/실행 어느 환경에서도 크래시 없음 (Phase 6-1 학습 노트 §"시뮬레이터에서 시험하면?"). `prepare()` 호출 패턴은 light/heavy와 100% 동형.

### 기능 3: GameScene — 마일스톤 피드백 매핑 helper
- **설명**: 마일스톤 값(3/5/10/20) → 햅틱 단계 + 사운드 케이스 매핑을 GameScene 분기 길이를 줄이는 helper로 표현.
- **구현 위치**: `Scenes/GameScene.swift` 내 private 메서드 (ComboPopupNode.color(for:) 패턴 대칭).
- **핵심 코드 구조**:
  ```swift
  // GameScene 안 private 메서드로 두는 게 가장 단순 (6-10의 ComboPopupNode.color(for:) static 패턴 답습)
  private func playComboMilestoneFeedback(for milestone: Int) {
      switch milestone {
      case 3, 5:
          haptics.light()
          audio.play(.comboMilestoneSoft)
      case 10:
          haptics.medium()
          audio.play(.comboMilestoneSoft)
      case 20:
          haptics.heavy()
          audio.play(.comboMilestoneStrong)
      default:
          haptics.light()   // graceful fallback — 미래 마일스톤 대비 (6-10 색상 매핑과 동일 정책)
          audio.play(.comboMilestoneSoft)
      }
  }
  ```

- **결정**: GameConfig가 아닌 GameScene 내부 helper로 둔다. 이유:
  1. ComboPopupNode의 `color(for:)` 정적 메서드와 *위치/형태 대칭* — 한 곳은 시각 매핑, 한 곳은 피드백 매핑.
  2. GameScene private 메서드로 두면 콤보 콜백 안쪽이 1줄(`self.playComboMilestoneFeedback(for: currentCombo)`)로 깨끗.
  3. 매핑 변경 시 한 곳만 수정.
  4. GameConfig는 *수치 상수* 보관소 — *제어 흐름*은 가능한 노출 안 시키는 게 6-10까지의 결정.

- **주의**: `default` 절은 6-10 `color(for:)`와 마찬가지로 **graceful fallback** 의도로 포함 (미래 마일스톤 추가 대비 + 만약 `comboMilestones` 배열에 새 값을 넣었는데 switch를 안 업데이트한 경우 크래시 방지). 단, `comboMilestones` 배열 자체는 이번 sprint에서 변경 금지 → default는 안전망일 뿐 실행 경로 아님.

### 기능 4: GameScene 콜백 가드 안쪽 통합
- **설명**: 6-10이 만든 멱등성 가드 안쪽에 햅틱/사운드 호출을 시각 *앞*에 prepend.
- **구현 위치**: `Scenes/GameScene.swift` — `configureContactRouter()` 내 `contactRouter.onNoteCollected` 클로저.
- **핵심 코드 구조**:
  ```swift
  // 기존 (6-10 산출물):
  let currentCombo = self.scoreSystem.combo
  if GameConfig.comboMilestones.contains(currentCombo),
     !self.triggeredComboMilestones.contains(currentCombo) {
      self.triggeredComboMilestones.insert(currentCombo)
      let popup = ComboPopupNode(milestone: currentCombo)
      self.cameraNode.addChild(popup)
      popup.animate()
  }

  // 6-11 후:
  let currentCombo = self.scoreSystem.combo
  if GameConfig.comboMilestones.contains(currentCombo),
     !self.triggeredComboMilestones.contains(currentCombo) {
      self.triggeredComboMilestones.insert(currentCombo)
      // Phase 6-11 — 가드 안쪽에서 3감각 동시 발화. 촉각→청각→시각 순서.
      // 회귀 0: 6-10의 시각 코드는 마지막 그대로, 앞에 1줄 prepend.
      self.playComboMilestoneFeedback(for: currentCombo)
      let popup = ComboPopupNode(milestone: currentCombo)
      self.cameraNode.addChild(popup)
      popup.animate()
  }
  ```
- **헤더 주석 추가**: `GameScene.swift` 상단 Phase 주석 목록에 한 줄 추가:
  ```
  //  Phase 6-11 · 콤보 마일스톤 도달 시 햅틱/사운드 동시 발화 (3감각 완성)
  ```
- **주의**:
  - `[weak self]` 캡처 유지 (기존 클로저 시그니처 변경 0).
  - `self.haptics.medium()` 호출은 시뮬레이터에서 noop이라 빌드/실행 모두 안전.
  - `endGame()` 내부의 `haptics.heavy()` / `audio.play(.gameOver)`와 *간섭 없음* — 노트 수집 콜백 안쪽이라 gameOver와 별개 경로.
  - 콤보 마일스톤 발화 직후 같은 클로저 안에서 `note.run(.removeFromParent())` 라인이 이미 존재 — 시각 코드 *뒤*에 위치 → 6-11 변경이 노트 제거 순서에 영향 0.

---

## 주의사항

- **시뮬레이터 검증 한계**: 햅틱은 시뮬레이터에서 noop. 사운드는 시뮬레이터에서도 재생됨 (시스템 사운드는 macOS 사운드 채널로 출력). 빌드 통과 + 콤보 마일스톤 도달 시 콘솔 에러 0 + 사운드 재생 확인까지가 Generator의 검증 범위. 실기기 햅틱 확인은 사용자 몫.
- **6-2의 정책 일관성 유지**:
  - 시스템 사운드 ID는 GameConfig에 *넣지 않는다* (Apple 도메인 상수). 6-2 학습 노트 §"매직 넘버 정책의 미묘함" 참조.
  - `default` 절 없는 exhaustive switch 유지 — 새 SFX 케이스 추가 시 컴파일러가 강제로 매핑 추가 요구.
- **사운드 ID 1025(NewMail) 검증**: 1000~1500 범위 안전. 만약 1025가 짧지 않거나 환호 톤과 안 맞으면 Generator는 1112(Anticipate) / 1117(BeginRecording) / 1325(Tweet 알림) 등 대안 시도 가능 — 단 SFX 케이스 분리(soft/strong) 구조는 유지.
- **`triggeredComboMilestones` Set는 절대 건드리지 않는다**: 6-10에서 이미 한 판 인스턴스 라이프사이클로 자동 리셋되도록 설계됨. `endGame()`에 `removeAll()` 추가 금지 (6-10 학습 노트 §"자동 리셋의 우아함").
- **AudioManager 카테고리(.ambient) 유지**: BGMPlayer의 .playback 카테고리는 BGM 음원 로딩 *성공* 시에만 덮어쓰는 구조(6-4). AudioManager init이 .ambient를 시도하는 건 .playback 덮어쓰기 *전* 호출 순서일 수 있음 — `GameScene.let audio = AudioManager(); let bgm = BGMPlayer()` 초기화 순서 상 audio가 먼저라 .ambient 후 .playback이 덮음. 회귀 0 유지.
- **CaseIterable 미채택 정책 유지**: 6-2의 결정 — enum 본체에 `CaseIterable` 채택 안 함, init의 명시 배열로 모든 케이스 나열. 새 케이스 추가 시 init의 `allCases` 배열에 *수동* 추가 의무. Generator가 빠뜨리면 Bundle 로딩 시도가 안 됨(폴백 경로만 동작) — 실제 음원 추가 시점에 발견 가능한 소프트 실수.
- **빌드 에러 가능성**:
  - `UIImpactFeedbackGenerator(style: .medium)`은 iOS 10+ 표준 API — iOS 16+ 타겟이라 안전.
  - HapticsManager에 import UIKit이 이미 있음 — 추가 import 0.
  - AudioManager의 systemSoundID는 SystemSoundID(UInt32) 타입 — 1025 정수 리터럴 자동 변환 OK.
- **pbxproj 미변경**: 기존 4개 파일 *수정*만 — 새 파일 0건이므로 project.pbxproj 변경 0건. Phase 6-10에서 pbxproj 4지점 등록한 ComboPopupNode와 다른 결.
- **Sprint 회귀 0 보장 영역** (이 sprint가 절대 건드리면 안 되는 곳): ScoreSystem / ContactRouter / SpawnSystem / HUDNode / BGMPlayer / Repositories / Models / Protocols / 기존 Nodes (PlayerNode/EnemyNode/NoteNode 등) / 기존 Scenes (TitleScene/ResultScene) / ColorTokens / SelfDismissingNode / ComboPopupNode 시각 코드 — **20개 영역 미접촉 검증 필수**.
