# Phase 5-R — PlayerNode 단일 진입점 리팩터 (apply(_:))

## 개요
Phase 5-2(color)와 5-3(speedMultiplier)을 거치며 `GameScene+Setup.setupPlayer()` 안에 캐릭터 관련 setter 두 줄이 흩어졌다. 5-5+ 진입 전에 PlayerNode 자체에 단일 진입점 `apply(_ characterID:)`을 신설하여, "캐릭터 정체성을 한 번에 받아 내부에서 적용"하는 책임을 PlayerNode로 이관한다. 기능 변화 0, 구조만 정리하는 순수 리팩터.

## 변경 유형
**리팩터 (순수)** — 게임플레이/비주얼 동작 변화 0. 컴파일러 출력·런타임 행동 100% 동일. 같은 두 setter를 호출 위치만 PlayerNode 내부로 옮긴다.

## 게임 경험 의도
플레이어 입장에서 **체감 변화 0**. 색·속도·이동·충돌 모두 5-3과 한 픽셀/한 프레임도 다르지 않다. 이 sprint는 코드 구조 학습만이 목적이며, 사용자가 5명 캐릭터를 골라 플레이할 때 보이는 결과는 직전 커밋과 완전히 동일하다.

## Sprint 범위 계약
- **허용**: PlayerNode에 `apply(_ characterID: CharacterID)` 메서드 신설 + `setupPlayer()` 두 줄을 단일 호출로 교체. 헤더 주석 한 줄(Phase 5-R 표기) 추가.
- **금지**: SPEC In Scope 외 모든 변경 (CharacterID/GameScene 본문/TitleScene/HUDNode/GameConfig/ColorTokens/다른 Node·System·Repository).
- **판단 기준**: "이 변경이 없으면 `setupPlayer()`가 더 이상 캐릭터 setter 2줄을 직접 알지 않게 된다는 결과가 동작하는가?" → NO인 변경만 In Scope. YES인 변경(예: CharacterID 새 프로퍼티, GameConfig 새 상수)은 전부 P0 위반.

## 변경 범위

### 수정할 파일
- `GanhoMusic/GanhoMusic Shared/Nodes/PlayerNode.swift`:
  - 헤더 주석에 `Phase 5-R` 한 줄 추가
  - `// MARK: - Apply` 섹션 신설 + `func apply(_ characterID: CharacterID)` 메서드 추가 (본문 정확히 2줄)
- `GanhoMusic/GanhoMusic Shared/GameScene+Setup.swift` (`setupPlayer()` 함수만):
  - `player.color = characterID.color` + `player.speedMultiplier = characterID.playerSpeedMultiplier` 두 줄을 `player.apply(characterID)` 한 줄로 교체
  - 호출 위치 유지: `player.position = ...` 다음, `worldNode.addChild(player)` 이전

### 추가할 파일
없음.

## 기능 상세

### 기능 1: PlayerNode.apply(_:) — 단일 진입점 메서드 신설
- **설명**: `CharacterID`를 받아 PlayerNode가 *스스로* 자기 외형(color)과 이동 능력(speedMultiplier)을 적용한다. 외부(GameScene)는 "어떤 캐릭터인지"만 전달하고, "그것을 어떻게 적용하는지"는 알지 않는다 (Tell-Don't-Ask).
- **구현 위치**: `PlayerNode.swift`, 새 `// MARK: - Apply` 섹션. 위치는 `// MARK: - Update` 바로 위 (의미 흐름: Init → Apply → Update).
- **시그니처 고정**: `func apply(_ characterID: CharacterID)` — 단일 인자, 외부 레이블 생략(`_`). `apply(color:speed:)` 분해 금지, `apply()` no-arg 금지, 반환값 없음.
- **본문 정확히 2줄** (추가 로직·로깅·검증·side effect 0건):
  ```swift
  // MARK: - Apply
  /// Phase 5-R — 캐릭터 정체성 단일 진입점.
  /// 외부(GameScene+Setup)는 setter를 직접 알지 않고 CharacterID 하나만 넘긴다.
  /// 기능 변화 0 — 5-2(color) + 5-3(speedMultiplier) 두 setter를 *내부에서 그대로* 호출.
  func apply(_ characterID: CharacterID) {
      color = characterID.color
      speedMultiplier = characterID.playerSpeedMultiplier
  }
  ```
- **self 표기**: `color = ...` / `speedMultiplier = ...` (self 생략) 권장 — Swift 관용 표기, 메서드 내부에서 명확. 한 메서드 안에서 표기 통일.

### 기능 2: setupPlayer() — 두 setter를 단일 호출로 교체
- **설명**: `GameScene+Setup.swift`의 `setupPlayer()`에서 `player.color = ...`와 `player.speedMultiplier = ...` 두 줄을 한 줄로 통합.
- **구현 위치**: `GameScene+Setup.swift` 내 `setupPlayer()` 함수.
- **교체 패턴**:
  ```swift
  // ── Before (현재, 5-3 종결 시점) ────────────────────────────────
  func setupPlayer() {
      player.position = CGPoint(
          x: GameConfig.mapWidth  / 4,
          y: GameConfig.mapHeight / 2
      )
      player.color = characterID.color   // Phase 5-2
      player.speedMultiplier = characterID.playerSpeedMultiplier   // Phase 5-3
      worldNode.addChild(player)
  }

  // ── After (5-R) ─────────────────────────────────────────────────
  func setupPlayer() {
      player.position = CGPoint(
          x: GameConfig.mapWidth  / 4,
          y: GameConfig.mapHeight / 2
      )
      player.apply(characterID)   // Phase 5-R — 5-2(color) + 5-3(speedMultiplier) 단일 진입점으로 통합
      worldNode.addChild(player)
  }
  ```
- **유지 사항**:
  - `player.position = ...` 위치 동일 (맨 위)
  - `worldNode.addChild(player)` 위치 동일 (맨 아래)
  - 5-2/5-3 흐름 주석은 `apply` 호출 1줄 옆 주석으로 통합 (정보 손실 0)

### 기능 3: PlayerNode 헤더 주석 갱신
- **설명**: 파일 헤더에 Phase 5-R 한 줄 추가 (5-3 기록 그대로 유지하면서 5-R 적층).
- **구현 위치**: `PlayerNode.swift` 파일 최상단 주석.
- **추가 라인**: `//  Phase 5-R · CharacterID 단일 진입점 메서드 apply(_:) 추출 (순수 리팩터)`
- **유지**: 기존 1-3 / 2-2 / 5-3 라인 그대로.

## 회귀 보장 (5 캐릭터 시나리오)

빌드 + 시뮬레이터 실행 후 아래 모든 조합이 직전 커밋(5-3 종결)과 **정확히 동일하게** 동작해야 한다:

| # | 시나리오 | 기대 결과 (5-3과 동일) |
|---|---|---|
| (a) | TitleScene → `.kim` 선택 | Player 몸체 = `.ganhoPaper`, 속도 배율 = 1.00 |
| (b) | TitleScene → `.jung` 선택 | Player 몸체 = `.ganhoMint`, 속도 배율 = 1.10 |
| (c) | TitleScene → `.geon` 선택 | Player 몸체 = `.ganhoPinkNote`, 속도 배율 = 0.90 |
| (d) | TitleScene → `.im` 선택 | Player 몸체 = `.ganhoYellowF`, 속도 배율 = 0.95 |
| (e) | TitleScene → `.lee` 선택 | Player 몸체 = `.ganhoBloodAccent`, 속도 배율 = 1.05 |

추가 검증:
- Xcode 빌드 에러 0 / 경고 증가 0
- D-Pad 4방향 이동, 외곽 벽/중앙 기둥 충돌, 음표 수집, 수간호사/F 피격 게임오버, AIRFORCE 이스터에그 모두 5-3과 동일
- HUD 우상단 캐릭터 이름(5-4) — 본 sprint 무관, 그대로 표시
- `didMove(to:)` 호출 순서: `setupPlayer()`가 그대로 호출 (변화 없음)

## 학습 가치 — Tell-Don't-Ask · 정보 은닉 · 응집

### Tell-Don't-Ask 원칙
- **Before (5-3)**: GameScene+Setup이 PlayerNode에게 *물어보고 직접 조작*함 — "너의 `color`를 이걸로 바꿔, 너의 `speedMultiplier`를 이걸로 바꿔" (2번 명령).
- **After (5-R)**: GameScene+Setup이 PlayerNode에게 *말함* — "너 이 캐릭터야, 알아서 적용해" (1번 위임). PlayerNode가 자기 내부 상태를 어떻게 갱신하는지는 외부가 알 필요 없음.

### 정보 은닉 (Information Hiding)
- 외부는 "어떤 setter들이 캐릭터별로 다른가"를 더 이상 알 필요가 없다. 캐릭터 적용 *방식*은 PlayerNode의 사적 영역.
- 5-5+에서 캐릭터별 setter가 더 늘어나도 외부 호출부는 *불변* — `player.apply(characterID)` 1줄 그대로.

### 응집 (Cohesion)
- "캐릭터 정체성을 PlayerNode에 적용하는 책임"이 한 메서드 한 곳에 모인다. 흩어져 있던 두 setter가 한 호출 안에 묶이며, 누락·순서 버그 가능성이 구조적으로 사라진다.

### Spring 비유 (사용자 멘탈 모델)
- Spring `@Service` 클래스에서 setter 두 번 호출 대신 **facade 메서드** 하나로 모으는 리팩터와 동일:
  ```java
  // Before — controller가 service의 내부 setter를 직접 호출
  userService.setRole(role);
  userService.setQuota(quota);

  // After — service가 단일 진입점 facade 메서드를 노출, controller는 위임만
  userService.applyProfile(profile);   // 안에서 setRole + setQuota
  ```
- **DTO 단일 진입점**: 컨트롤러가 `request.getName()`, `request.getEmail()`을 각각 꺼내 도메인 객체에 set하지 않고, `domain.applyFrom(request)` 1줄로 위임하는 패턴.
- **OCP (Open/Closed)**: 5-5에서 새 캐릭터별 setter가 추가돼도 *호출 측 코드는 변경 없이* PlayerNode 안의 `apply` 본문만 확장 — OCP가 자연스럽게 충족된다.

### Phase 4-R과의 공통 결 (전례)
- Phase 4-R: 3 노드의 공통 *자가 소멸* 패턴을 `SelfDismissingNode` protocol로 추출 → "공통 구조를 한 곳에 모음".
- Phase 5-R: 2 setter의 공통 *캐릭터 적용* 패턴을 `apply(_:)` 메서드로 추출 → "공통 구조를 한 곳에 모음".
- 둘 다 **기능 변화 0, 구조 정리**라는 동일한 리팩터 DNA.

## 주의사항

### 컴파일 / 타입 안전
- `apply(_ characterID: CharacterID)`에서 `CharacterID`를 참조하려면 `PlayerNode.swift`는 `Models/CharacterID.swift`와 동일 타겟에 속해야 한다. `CharacterID.swift`가 `GanhoMusic Shared`에 있고 PlayerNode도 같은 타겟이므로 추가 import 불필요.
- `CharacterID`는 `import UIKit`을 쓰고, `PlayerNode`는 `import SpriteKit`을 쓴다. SpriteKit이 UIKit을 추이적으로 끌어오므로 PlayerNode에서 `UIColor` 타입 사용에 문제 없음.

### 기능 변화 0 보존 — 절대 금지 사항
- `apply` 본문에 정렬 변경 금지 (현재 5-3은 `color` 먼저, `speedMultiplier` 나중 — 그대로 유지). 둘 다 독립 setter라 순서는 결과에 영향 없지만, "변화 0" 약속 차원에서 순서까지 보존.
- `apply` 본문에 `guard`·`if`·로그·디버그 출력·`SKAction` 등 추가 0건.
- `setupPlayer()`의 `player.position` 계산식·`worldNode.addChild` 위치 일체 불변.

### Out of Scope 재확인 (위반 시 P0)
- `CharacterID.swift` 한 글자도 수정 금지 — color/playerSpeedMultiplier/displayName 그대로.
- `GameScene.swift` 본문(init / factory / didMove / update / configureContactRouter / triggerAirforceEasterEgg / endGame) 한 글자도 수정 금지.
- `TitleScene.swift`, `HUDNode.swift`, `GameConfig.swift`, `ColorTokens.swift`, `EnemyNode`, `StoneGuardNode`, `SpawnSystem`, `ContactRouter`, `ScoreSystem`, Repository류 일체 미접촉.
- PlayerNode 내 다른 부분 (Properties / Init / Update / physicsBody 설정) 일체 미접촉.
- pbxproj 변경 0 — 파일 추가/삭제 없음.
- 테스트 코드, macOS/tvOS 타겟 미접촉.

### SpriteKit 특수 고려
- `color` 프로퍼티는 `SKSpriteNode`가 제공하는 dynamic 속성이라 setter 호출 즉시 다음 프레임에 화면 반영. `setupPlayer()` 호출 시점(didMove 안, 첫 렌더 전)이라 첫 프레임부터 정상 색.
- `speedMultiplier`는 `update(deltaTime:)`에서 매 프레임 곱셈 적용 — set 시점이 첫 update 전이라 첫 입력부터 정상 속도.
- 본 리팩터는 두 setter 모두 `worldNode.addChild(player)` *이전* 호출하므로 SKPhysics/SKScene이 player의 최종 상태를 보고 등록 — 5-3과 동일한 타이밍 보장.

### 평가 기준 정합성
- Swift 규칙: `guard let` 불필요(옵셔널 없음), 매직 넘버 0, MARK 섹션 추가, 함수 단일 책임 — 모두 충족.
- SpriteKit 규칙: 초기화 흐름(didMove → setupPlayer → apply) 그대로, dt 기반 이동 영향 0, 액션·물리 미접촉.
- AI 슬롭 패턴(강제 언래핑·Timer·매직 넘버·고정값 이동·SPEC 외 기능) 0건 — 본 sprint는 신규 로직 추가가 없어 슬롭 발생 여지 자체가 거의 없다.
