# Phase 6-10 — 콤보 마일스톤 텍스트 팝업 (자가 소멸 6호)

## 개요

콤보 X3 / X5 / X10 / X20 도달 시 화면 중앙에 "x3" 텍스트가 떠올라 1초간 fly-up + 페이드아웃 후 자가 제거되는 폴리싱. 현재 HUD 콤보 라벨은 조용히 숫자만 올라가는데, 마일스톤마다 *시각적 환호*를 추가해 "잘하고 있어!" 격려 신호를 명확히 전달한다. 6-8/6-9에서 다진 자가 소멸 노드 패턴(4호 Sparkle, 5호 HitFlash)을 답습한 **6호** 적용.

## 변경 유형

**폴리싱 / 시각 임팩트 / 긍정 강조** — 게임 로직(점수 계산, 충돌, 스폰)에 일체 손대지 않는 *순수 시각 보강*. SPEC 4항목 모두에서 회귀 0 보장.

## 게임 경험 의도

새벽 작곡 자전적 톤에서, 콤보 누적은 *곡이 클라이맥스로 가는 과정* 그 자체다. 단조롭게 증가하던 콤보 라벨에 마일스톤 도달 시 큰 텍스트가 떠올라 *별빛처럼 위로 흩어지듯* 사라지면, 플레이어는 "내 연주가 한 단계 올라갔다"는 보상감을 받는다. 색을 마일스톤 등급별로 차등(흰→분홍→황금→빨강)해 *시각적 위계*로 클라이맥스 곡선을 표현한다.

---

## Sprint 범위 계약

### 허용 (SPEC 정상 동작 필수 최소 연동)

- `Nodes/ComboPopupNode.swift` 신설 — 자가 소멸 6호 (SelfDismissingNode 채택)
- `Config/GameConfig.swift`에 콤보 팝업 상수 6개 추가
- `GameScene.swift`의 `onNoteCollected` 클로저에 마일스톤 검사 3~5줄 추가 (콤보 *읽기*만, ScoreSystem 미변경)
- `GameScene.swift` 클래스 프로퍼티 `triggeredComboMilestones: Set<Int>` 1개 신설 (멱등성 보장)
- 헤더 주석에 Phase 6-10 1줄 추가
- `GanhoMusic.xcodeproj/project.pbxproj` 4지점 등록 (HitFlashNode 패턴 답습)

### 금지 (Sprint 범위 외)

- ScoreSystem 시그니처/내부 변경 — 콜백 추가, 마일스톤 추적 옮기기 등 일체 금지
- HUDNode 변경 — comboLabel 색 바꾸기, 폰트 키우기 등 일체 금지
- ContactRouter 시그니처 변경
- AudioManager/HapticsManager/BGMPlayer 호출 추가 — *시각 only*. 사운드/햅틱은 6-11 이후 별도 sprint
- Sparkle/HitFlash/BombFlash 노드 수정
- 마일스톤 배열 외 X4/X7 등 별도 분기 추가
- 콤보 *떨어졌다가* 다시 올라갈 때 재발화 (멱등성 위반)
- "콤보!" "GREAT!" 등 SPEC 외 텍스트 추가

### 판단 기준

"이 변경 없이 콤보 마일스톤 팝업이 정상 동작하는가?" → NO면 허용, YES면 금지.

---

## 핵심 결정 포인트

### a. 콤보 변경 감지 메커니즘: **옵션 B (폴링) 채택**

ScoreSystem은 현재 콤보 변경 시 콜백이 *없다*. 두 가지 선택지:

- **옵션 A (콜백)**: ScoreSystem에 `onComboReached: (Int) -> Void` 클로저 추가, `recordNoteHit`에서 콤보 갱신 후 호출.
- **옵션 B (폴링)**: `onNoteCollected` 클로저(GameScene) 내부에서 `scoreSystem.recordNoteHit(...)` 직후 `scoreSystem.combo` 값을 읽어 마일스톤 검사.

**채택: 옵션 B** — 회귀 위험 0. ScoreSystem 코드 변경 없음. `onNoteCollected`는 *수집 시점*마다 1회 호출되므로 콤보 갱신 직후 동일 트랜잭션에서 검사 가능. ScoreSystem의 단일 책임(상태 + 점수 계산)을 보존.

**Spring 비유**:
- 옵션 A = `@EventListener(ApplicationEvent)` — 이벤트 발행자(ScoreSystem)가 발행 책임을 짐
- 옵션 B = 호출자가 메서드 호출 직후 상태 폴링 — 컨트롤러가 서비스 호출 결과 보고 분기 (가장 간단)

옵션 B는 "이미 일어난 일을 매 호출마다 확인" 패턴. 콜백보다 결합도 낮고 ScoreSystem 단위 테스트도 안 깨짐.

### b. 마일스톤 정책: **[3, 5, 10, 20] 4단계 + 멱등성 보장 (한 판 내 1회만)**

- 배열: `GameConfig.comboMilestones: [Int] = [3, 5, 10, 20]`
- 멱등성: `triggeredComboMilestones: Set<Int>` 프로퍼티로 *이미 트리거된 마일스톤*을 기억 → 콤보가 3 → 4 → 콤보 윈도우 만료로 0 → 다시 3 도달해도 X3 재발화 **안 함**
- 한 판 종료 시 `triggeredComboMilestones`는 *새 GameScene 인스턴스 생성* 시 빈 Set로 자동 리셋

**근거**:
- 콤보 라벨 자체가 매번 증가/리셋을 보여줌(HUD). 팝업까지 매번 떠오르면 *시각 노이즈*. 마일스톤은 *특별*해야 한다.
- 자전적 톤: 곡의 클라이맥스는 한 곡에 한 번. 같은 클라이맥스를 두 번 치지 않는다.

**Spring 비유**: idempotency-key 기반 결제 중복 방지. 같은 마일스톤 key에 대해 한 판(=1 GameScene 인스턴스) 안에서 1회만 처리.

### c. 팝업 텍스트 & 폰트

- 텍스트 포맷: `"x\(milestone)"` (예: `"x3"`, `"x10"`)
- 폰트: SKLabelNode 시스템 폰트 (`SKLabelNode(text:)` 기본). 둥근모꼴 폰트는 아직 프로젝트에 임포트되지 않은 상태(별도 sprint).
- 폰트 크기: `GameConfig.comboPopupFontSize: CGFloat = 48` (HUD 18보다 크고 GAME OVER 32과 비슷 — 임팩트 강조)
- 텍스트 정렬: 중앙 (`horizontalAlignmentMode = .center`, `verticalAlignmentMode = .center`)

### d. 표시 위치: **cameraNode 자식 (화면 중앙)**

- 부착 위치: `cameraNode.addChild(popup)` — 카메라 follow 무관 *항상 화면 중앙*
- 좌표: `position = .zero` (cameraNode 자식 좌표계는 (0,0)=화면 중앙)

**근거**:
- 마일스톤은 *특별*해야 함. 노트 위치 부착(worldNode) 시 카메라 이동/노트 위치 산만함으로 임팩트 분산.
- AirforceOverlayNode 패턴 답습 → 일관성.

**트레이드오프 수용**: 화면 중앙 일부 가림(1초). 플레이어가 잠시 못 보지만 마일스톤 = *큰 보상 순간*이라 게임플레이 방해보다 환호 효과가 크다.

### e. 애니메이션: SKAction.group 동시 액션 + sequence 정리

```swift
let moveUp  = SKAction.moveBy(x: 0, y: comboPopupFlyUpDistance, duration: comboPopupDuration)
let fadeOut = SKAction.fadeOut(withDuration: comboPopupDuration)
let scaleUp = SKAction.scale(to: comboPopupEndScale, duration: comboPopupDuration)
let group   = SKAction.group([moveUp, fadeOut, scaleUp])
let cleanup = SKAction.removeFromParent()
run(.sequence([group, cleanup]))
```

- fly-up 거리: `comboPopupFlyUpDistance: CGFloat = 80` (위로 떠오름 — 별이 올라가는 느낌)
- 총 길이: `comboPopupDuration: TimeInterval = 1.0` (sparkle 0.5보다 길게 — 마일스톤은 1초 머묾이 적정)
- 끝 스케일: `comboPopupEndScale: CGFloat = 1.4` (커지면서 사라짐 — 별이 *터지듯*)

**Spring 비유**: `CompletableFuture.allOf(moveTask, fadeTask, scaleTask)` — 3개의 비동기 작업이 *동시* 진행되고 모두 끝났을 때 cleanup 실행.

### f. 색상: 마일스톤별 차등 (ColorTokens 활용)

| 마일스톤 | 색 토큰 | HEX | 의도 |
|---|---|---|---|
| x3 | `.ganhoPaper` | `#F4F1DE` | 흰빛 — 첫 도달, 깔끔한 환호 |
| x5 | `.ganhoPinkNote` | `#F6A6B2` | 분홍 — 음표 본체 색, 음악과 동기 |
| x10 | `.ganhoYellowF` | `#FFD23F` | 황금 — 노트의 황금기 |
| x20 | `.ganhoBloodAccent` | `#D8315B` | 빨강 — 클라이맥스, 강렬함 |

**색 결정 위치**: ComboPopupNode 내부에 `private static func color(for milestone: Int) -> UIColor` 함수로 매핑. 기본값 `.ganhoPaper` (마일스톤 미일치 시 graceful fallback — 미래 마일스톤 추가 대비).

**ColorTokens 변경 0건**: 모두 기존 토큰 재사용.

> **Generator 주의**: 색 토큰 이름은 ColorTokens.swift 실제 정의와 일치해야 함. 위 이름이 다르면 가까운 토큰으로 매핑(예: `.ganhoYellowF` 없으면 `.ganhoMustard` 또는 노란 계열).

### g. 자가 소멸 6호 패턴

`ComboPopupNode: SKNode, SelfDismissingNode` 채택. 5호 HitFlashNode 패턴 답습 — 외부 호출자가 `addChild` 직후 `animate()` 호출. 메모리 정리는 노드 본인.

---

## 변경 범위

### 추가할 파일 (1개)

- **`Nodes/ComboPopupNode.swift`** — 자가 소멸 6호

### 수정할 파일 (3개)

#### 1. `Config/GameConfig.swift`
`// MARK: - Combo Popup (Phase 6-10)` 섹션 + 6개 상수

#### 2. `GameScene.swift`
- 헤더 주석 1줄
- Properties: `triggeredComboMilestones: Set<Int>` 1개
- `onNoteCollected` 클로저: 마일스톤 검사 5줄 (`sparkle.emit()` 이후, `note.removeFromParent()` 이전)

#### 3. `GanhoMusic.xcodeproj/project.pbxproj`
- 4지점 등록 (식별자 `0031`)

---

## 기능 상세

### 기능 1: ComboPopupNode 신설

```swift
//
//  ComboPopupNode.swift
//  GanhoMusic Shared
//
//  Phase 6-10 · 콤보 마일스톤 도달 시 화면 중앙 텍스트 팝업 + 자가 소멸 (시각 폴리싱)
//

import SpriteKit

/// 콤보 마일스톤(3/5/10/20) 도달 시 화면 중앙에 떠오르는 자가 소멸 텍스트.
/// PhysicsBody 부착 0 — 순수 시각. cameraNode 자식으로 화면 중앙 고정.
/// SparkleEffectNode / HitFlashNode 패턴 답습 — 자가 소멸 노드 6회차.
/// Spring 비유: HTTP 상태 코드 색상 매핑 — 마일스톤 등급별 시각적 위계.
final class ComboPopupNode: SKNode, SelfDismissingNode {

    // MARK: - Properties
    private let label: SKLabelNode

    // MARK: - Init
    /// 마일스톤 값(3/5/10/20 등)을 받아 텍스트와 색을 결정.
    init(milestone: Int) {
        self.label = SKLabelNode(text: "x\(milestone)")
        super.init()
        name = "comboPopup"
        zPosition = GameConfig.comboPopupZPosition
        configureLabel(color: Self.color(for: milestone))
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Animate
    /// 부모(cameraNode)에 addChild 직후 호출. 1초간 fly-up + fadeOut + scale → 자가 제거.
    /// SKAction.group은 [move, fade, scale] 3개를 *동시* 실행 — CompletableFuture.allOf 패턴.
    /// self 미사용 — [weak self] 캡처 불필요.
    func animate() {
        let moveUp  = SKAction.moveBy(x: 0,
                                       y: GameConfig.comboPopupFlyUpDistance,
                                       duration: GameConfig.comboPopupDuration)
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.comboPopupDuration)
        let scaleUp = SKAction.scale(to: GameConfig.comboPopupEndScale,
                                      duration: GameConfig.comboPopupDuration)
        let group   = SKAction.group([moveUp, fadeOut, scaleUp])
        let cleanup = SKAction.removeFromParent()
        run(.sequence([group, cleanup]))
    }

    // MARK: - Configure
    /// 라벨 스타일 — 마일스톤 색상, 중앙 정렬. cameraNode 자식 (0,0) = 화면 중앙.
    private func configureLabel(color: UIColor) {
        label.fontSize = GameConfig.comboPopupFontSize
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
    }

    // MARK: - Color Mapping
    /// 마일스톤 값 → ColorTokens 매핑. 미일치 시 기본 .ganhoPaper로 graceful fallback.
    /// 색은 등급이 올라갈수록 강렬해진다 (HTTP 상태 코드 색상 위계와 동형).
    private static func color(for milestone: Int) -> UIColor {
        switch milestone {
        case 3:  return .ganhoPaper        // 흰빛 — 첫 도달
        case 5:  return .ganhoPinkNote     // 분홍 — 음악 본체 색
        case 10: return .ganhoYellowF      // 황금 — 노트의 황금기
        case 20: return .ganhoBloodAccent  // 빨강 — 클라이맥스
        default: return .ganhoPaper        // 미래 마일스톤 대비
        }
    }
}
```

> **색 토큰 미존재 대응**: `.ganhoYellowF`가 ColorTokens.swift에 없으면 가장 가까운 노란/황금 톤(예: `.ganhoMustard`) 사용. Generator가 ColorTokens.swift 확인 후 결정.

### 기능 2: GameConfig 상수 6개

```swift
// MARK: - Combo Popup (Phase 6-10)
/// 콤보 마일스톤 발화 임계값 목록. 한 판 내 같은 마일스톤은 1회만 발화(멱등).
/// 3 = 첫 환호 / 5 = 정착 / 10 = 황금기 / 20 = 클라이맥스. 자전적 곡 클라이맥스 모델.
static let comboMilestones: [Int] = [3, 5, 10, 20]
/// 콤보 팝업 텍스트 폰트 크기 (pt). HUD(18)의 ~2.7배 — *임팩트 강조*.
static let comboPopupFontSize: CGFloat = 48
/// 콤보 팝업이 위로 떠오르는 거리 (pt). 별이 하늘로 올라가는 톤.
static let comboPopupFlyUpDistance: CGFloat = 80
/// 팝업 1회 표시 총 길이 (초). group 액션(move + fade + scale) 묶음 duration.
/// sparkle(0.5)보다 길고 airforceOverlay(1.5)보다 짧음 — 마일스톤 강조와 게임플레이 방해의 균형점.
static let comboPopupDuration: TimeInterval = 1.0
/// 팝업 끝 스케일. 1.0 시작 → 1.4 끝 = 페이드아웃과 동시에 *별이 터지듯* 확대.
/// SparkleEndScale(0.2 축소)과 반대 — 마일스톤은 *확산*되는 느낌, sparkle은 *수렴*되는 입자.
static let comboPopupEndScale: CGFloat = 1.4
/// 팝업 zPosition. HUD(100) 위 — 라벨을 잠깐 덮어 임팩트.
/// HitFlash(200) 아래 — 피격 플래시는 더 우선(생존 직결).
static let comboPopupZPosition: CGFloat = 150
```

### 기능 3: GameScene 마일스톤 검사 클로저

`onNoteCollected` 클로저 안, `sparkle.emit()` 이후 `note.removeFromParent()` 이전에 5줄 삽입:

```swift
// Phase 6-10 — 콤보 마일스톤 도달 시 화면 중앙 텍스트 팝업 1회 발화 (멱등성)
let currentCombo = self.scoreSystem.combo
if GameConfig.comboMilestones.contains(currentCombo),
   !self.triggeredComboMilestones.contains(currentCombo) {
    self.triggeredComboMilestones.insert(currentCombo)
    let popup = ComboPopupNode(milestone: currentCombo)
    self.cameraNode.addChild(popup)
    popup.animate()
}
```

> **Generator 유연성**: `scoreSystem.combo` 프로퍼티 이름이 다르면 실제 ScoreSystem.swift 확인 후 매칭. `currentCombo`가 *수집 직후 갱신된 값*이어야 함.

### 기능 4: triggeredComboMilestones 프로퍼티

GameScene Properties 섹션에 추가:

```swift
// Phase 6-10 — 한 판 내 이미 발화된 콤보 마일스톤 추적. 멱등성 보장.
// GameScene 인스턴스는 한 판 = 1개 → 새 게임 시작 시 빈 Set로 자동 리셋.
private var triggeredComboMilestones: Set<Int> = []
```

**리셋 처리 미필요 근거**: GameScene은 한 판당 새 인스턴스. `endGame()`에 `removeAll()` 추가하면 *과잉 안전망*이며 SPEC 범위 외.

### 기능 5: pbxproj 4지점 등록

HitFlashNode 등록 패턴 답습:
1. PBXBuildFile 섹션
2. PBXFileReference 섹션
3. Nodes 그룹 children
4. Sources build phase

식별자: `A1C0F1A00000000000000031` / `A1C0F1B00000000000000031` (0030 다음). 충돌 확인 후 부여.

> **참고**: Nodes/ 폴더가 PBXFileSystemSynchronizedRootGroup이면 자동 등록될 수 있음. 그러나 HitFlashNode가 명시 등록되어 있으면 동일 패턴 답습.

---

## 회귀 안전성

| 영역 | 변경 | 회귀 위험 |
|---|---|---|
| ScoreSystem | 0건 (콤보 *읽기*만) | 0 |
| ContactRouter 시그니처 | 0건 | 0 |
| HUDNode | 0건 (별도 노드) | 0 |
| HapticsManager / AudioManager / BGMPlayer | 0건 | 0 |
| Sparkle / HitFlash / BombFlash | 0건 | 0 |
| EnemyNode / PlayerNode / NoteNode | 0건 | 0 |
| GameScene `update()` / `endGame()` | 0건 | 0 |
| GameConfig | 추가만, 기존 수정 0 | 0 |
| PhysicsCategory | 0건 | 0 |

---

## 검증 시나리오

| # | 시나리오 | 기대 결과 |
|---|---|---|
| a | 음표 2개 연속 수집 (콤보 2) | 팝업 미발화 |
| b | 음표 3개 연속 수집 (콤보 3 도달) | `.ganhoPaper` "x3" 팝업, 1초 후 사라짐 |
| c | 음표 5개 연속 수집 (콤보 5) | `.ganhoPinkNote` "x5" 팝업, "x3"은 재발화 X |
| d | 콤보 10 → 윈도우 만료 → 다시 3 도달 | "x3" 재발화 X (멱등성 보장) |
| e | 마일스톤 도달과 피격(F) 동시 | 팝업 + HitFlash + 셰이크 모두 작동, ResultScene 전환 시 자동 정리 |
| f | 새 게임 시작 | `triggeredComboMilestones` 빈 Set, 다시 처음부터 발화 가능 |
| g | 콤보 50까지 도달 | 마일스톤 4단계 모두 1회씩 발화 후 추가 발화 0 |
| h | 빌드 | BUILD SUCCEEDED, 경고 0 |

---

## 학습 가치

### 1. 폴링 vs 콜백 — 옵션 A vs B 선택의 의미
- 옵션 A (콜백) = `@EventListener` — 결합도 ↑, 확장성 ↑
- 옵션 B (폴링) = 컨트롤러가 서비스 호출 직후 상태 조회 — 결합도 ↓, 단순함 ↑

이번엔 옵션 B 채택. 한 곳에서만 듣는다면 폴링이 단순.

### 2. 멱등성과 마일스톤 추적
`Set<Int>`로 *이미 본 마일스톤*을 기억. Spring idempotency-key, Redis SETNX와 같은 사고방식.

학생 비유: 출석부에 한 번 체크하면 두 번 체크 안 함.

### 3. 자가 소멸 6호 — 패턴 누적 가치
1호 Airplane → 2호 AirforceOverlay → 3호 BombFlash → 4호 Sparkle → 5호 HitFlash → **6호 ComboPopup**.

같은 *생애주기 패턴*을 6회 답습. 호출자는 `addChild → 메서드 호출` 두 줄로 끝.

### 4. SKAction.group의 동시 액션
`sequence` = 순차 (`chainedFuture.thenCompose`) / `group` = 병렬 (`CompletableFuture.allOf`).

ComboPopup은 group으로 "위로 이동 + 페이드 + 확대" 3채널을 *같은 1초 동안 동시* 진행.

### 5. 시각 위계 — 마일스톤 등급별 색 차등
HTTP 상태 코드 색상 비유와 동형:
- 2xx 흰색 / 3xx 분홍 / 4xx 노랑 / 5xx 빨강

색이 *등급*을 1초 안에 전달. 텍스트는 *읽어야* 알지만, 색은 *느낀다*. 인지 비용 차이.

### 6. HUD 라벨 vs 팝업 — 정보 vs 임팩트 분리
- HUD comboLabel = *지속 정보* (read API)
- ComboPopupNode = *일회성 임팩트* (event listener)

두 채널 분리 — HUD에 임팩트 섞으면 평소 *조용*해야 할 정보가 시끄러워짐.

---

## 주의사항

### 빌드 에러 가능성
- pbxproj 식별자 0031 충돌 확인
- SelfDismissingNode 채택 시 별도 import 불필요(같은 모듈)
- `.ganhoYellowF` 등 색 토큰 이름이 실제 ColorTokens.swift와 일치 확인

### SpriteKit 특성
- `SKLabelNode(text:)` 기본 생성자 = 시스템 폰트. 둥근모꼴 도입은 별도 sprint.
- alpha/scale 기본값 1.0 → 별도 초기화 불필요

### Swift 규칙
- 강제 언래핑 0
- 매직 넘버 0 (모든 수치 GameConfig)
- `[weak self]` + `guard let self` (기존 onNoteCollected 패턴 유지)

### Sprint 범위 위반 자동 감점 위험
Generator가 다음 추가 시 SPEC 위반:
- 콤보 팝업 사운드/햅틱 — 별도 sprint
- ScoreSystem onComboReached 콜백 — 옵션 B 채택과 모순
- HUDNode 변경 — 금지 명시
- 마일스톤 배열 외 추가
- 색 차등 정책 위반

---

## Generator 체크리스트

- [ ] `Nodes/ComboPopupNode.swift` 신설 — SelfDismissingNode 채택
- [ ] `Config/GameConfig.swift` 끝에 Combo Popup 섹션 + 상수 6개
- [ ] `GameScene.swift` Properties `triggeredComboMilestones: Set<Int> = []` 추가
- [ ] `GameScene.swift` onNoteCollected 클로저에 마일스톤 검사 5줄 (sparkle.emit() 이후, note.removeFromParent() 이전)
- [ ] 헤더 주석 1줄 추가
- [ ] pbxproj 4지점 등록 (UUID 0031, 충돌 0)
- [ ] 빌드 BUILD SUCCEEDED + 경고 0
- [ ] 회귀 0줄 git diff (ScoreSystem/HUDNode/AudioManager/HapticsManager/BGMPlayer/Sparkle/HitFlash/BombFlash/Player/Enemy/Note/Projectile/Repositories/Models/Protocols/ContactRouter/SpawnSystem 등)
- [ ] 강제 언래핑 0, 매직 넘버 0, Timer 0
- [ ] [weak self] + guard let self 패턴 유지
- [ ] ColorTokens.swift 변경 0 (색 토큰 재사용)
- [ ] 새 효과음/햅틱/PhysicsCategory 0
