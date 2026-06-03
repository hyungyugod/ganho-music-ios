# D-Pad 첫 반응 강화 및 입력 축 보정

## 개요
D-Pad를 눌렀을 때 첫 이동 프레임이 늦게 느껴지는 문제를 줄이고, 손가락이 살짝 비뚤어져도 의도한 가로/세로 축으로 안정적으로 움직이도록 입력 벡터를 보정한다. 플레이어 기본 속도, 달리기 버튼, 회피 보상, 자동 달리기 등은 변경하지 않고 조작 입력 해석 계층만 좁게 수정한다.

## 변경 유형
게임플레이

## 게임 경험 의도
플레이어가 D-Pad를 누르는 즉시 캐릭터가 반응해 "버튼을 눌렀는데 밀린다"는 감각을 줄인다. 동시에 오른쪽으로 가려는데 위아래로 새거나, 위로 가려는데 좌우로 흐르는 미세 입력 오차를 줄여 회피 판단이 더 명확하게 느껴지게 한다. 속도 자체를 올리지 않기 때문에 기존 난이도와 맵 밸런스는 유지한다.

## Sprint 범위 계약
- **허용**: SPEC 기능의 정상 동작에 필수적인 최소 연동 변경
- **금지**: 자동 달리기, `playerBaseSpeed`/난이도별 속도/`playerWalkSpeedScale`/`playerRunSpeedScale` 상향, 회피 보상, 신규 보상 UI, 신규 햅틱/사운드, 맵/적/투사체 밸런스 변경
- **판단 기준**: "이 변경이 없으면 D-Pad 첫 반응 강화 또는 입력 축 보정이 제대로 동작하지 않는가?" -> YES면 허용, NO면 금지

## 변경 범위

### 수정할 파일
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`: D-Pad 입력 보정용 상수 추가
- `GanhoMusic/GanhoMusic Shared/Nodes/DPadNode.swift`: 터치 벡터를 축 보정한 뒤 `currentDirection`에 반영
- `GanhoMusic/GanhoMusic Shared/GameScene+MovementInput.swift`: 정지 상태에서 첫 비-제로 입력이 들어올 때 초기 반응 보강

### 추가할 파일 (있는 경우)
- 없음

## 기능 상세

### 기능 1: D-Pad 첫 반응 강화
- 설명: `smoothedMoveDirection`이 `.zero`인 상태에서 `dpad.currentDirection`이 처음 비-제로가 되는 프레임에만 더 높은 보간 응답과 최소 입력 크기를 적용한다. 이후 프레임은 기존 `dpadInputTurnResponse`, 입력 해제는 기존 `dpadInputReleaseResponse` 흐름을 유지한다.
- 구현 위치: `GameScene+MovementInput.swift` `// MARK: - Movement Input`
- 핵심 코드 구조:
  ```swift
  func updateSmoothedMovementInput(deltaTime dt: TimeInterval) {
      let target = dpad.currentDirection
      let isStartingInput = smoothedMoveDirection == .zero && target != .zero
      let response: CGFloat
      let adjustedTarget: CGVector

      if target == .zero {
          response = GameConfig.dpadInputReleaseResponse
          adjustedTarget = .zero
      } else if isStartingInput {
          response = GameConfig.dpadInputInitialResponse
          adjustedTarget = initialBoostedVector(from: target)
      } else {
          response = GameConfig.dpadInputTurnResponse
          adjustedTarget = target
      }

      smoothedMoveDirection = interpolatedVector(
          from: smoothedMoveDirection,
          to: adjustedTarget,
          response: response,
          dt: dt
      )
      player.currentDirection = smoothedMoveDirection
  }

  private func initialBoostedVector(from target: CGVector) -> CGVector {
      let length = hypot(target.dx, target.dy)
      guard length >= GameConfig.dpadInputSnapEpsilon else { return .zero }
      let magnitude = max(length, GameConfig.dpadInputInitialMagnitude)
      return CGVector(
          dx: target.dx / length * magnitude,
          dy: target.dy / length * magnitude
      )
  }
  ```
- `GameConfig.swift` 추가 상수:
  ```swift
  /// 정지 상태에서 첫 D-Pad 입력이 들어왔을 때 쓰는 보간 응답값.
  static let dpadInputInitialResponse: CGFloat = 36
  /// 첫 입력 프레임에 보장할 최소 입력 크기. 최고 속도는 올리지 않고 출발 지연만 줄인다.
  static let dpadInputInitialMagnitude: CGFloat = 0.55
  ```

### 기능 2: 입력 축 보정
- 설명: D-Pad 터치가 한 축으로 충분히 우세하면 작은 반대 축 성분을 0으로 스냅한다. 예를 들어 오른쪽 입력에서 위쪽 성분이 작게 섞이면 `currentDirection`을 `(strength, 0)`에 가깝게 만들고, 실제 대각선 의도가 분명한 입력은 기존처럼 대각 벡터를 유지한다.
- 구현 위치: `DPadNode.swift` `// MARK: - Direction Resolution`
- 핵심 코드 구조:
  ```swift
  private func updateDirection(forTouchLocation location: CGPoint) {
      let distance = hypot(location.x, location.y)
      guard distance >= GameConfig.dpadAnalogDeadzoneRadius else {
          currentDirection = .zero
          updateThumb(position: .zero)
          applyPressedState(for: nil)
          return
      }

      let clampedDistance = min(distance, GameConfig.dpadAnalogMaxRadius)
      let range = GameConfig.dpadAnalogMaxRadius - GameConfig.dpadAnalogDeadzoneRadius
      let unit = CGVector(dx: location.x / distance, dy: location.y / distance)
      let strength = min(
          1,
          (clampedDistance - GameConfig.dpadAnalogDeadzoneRadius) / range
      )
      let correctedUnit = axisCorrectedUnitVector(from: unit)

      currentDirection = CGVector(
          dx: correctedUnit.dx * strength,
          dy: correctedUnit.dy * strength
      )

      // thumb는 손가락 위치 피드백이므로 raw unit 기준으로 유지한다.
      updateThumb(position: CGPoint(
          x: unit.dx * clampedDistance,
          y: unit.dy * clampedDistance
      ))

      if let direction = Direction(vector: currentDirection) {
          applyPressedState(for: direction)
          onDirectionChanged?(direction)
      } else {
          applyPressedState(for: nil)
      }
  }

  private func axisCorrectedUnitVector(from unit: CGVector) -> CGVector {
      let absDx = abs(unit.dx)
      let absDy = abs(unit.dy)
      let ratio = GameConfig.dpadAxisSnapDominanceRatio

      if absDx >= absDy * ratio {
          return CGVector(dx: unit.dx >= 0 ? 1 : -1, dy: 0)
      }
      if absDy >= absDx * ratio {
          return CGVector(dx: 0, dy: unit.dy >= 0 ? 1 : -1)
      }
      return unit
  }
  ```
- `GameConfig.swift` 추가 상수:
  ```swift
  /// 한 축이 다른 축보다 이 배수 이상 우세하면 작은 축을 제거한다.
  static let dpadAxisSnapDominanceRatio: CGFloat = 1.35
  ```

### 기능 3: 기존 이동 속도와 달리기 정책 보존
- 설명: 이번 변경은 입력 벡터의 해석과 보간만 다룬다. `PlayerNode.update(deltaTime:)`의 속도 산식, `RunButtonNode`, 캐릭터별 `speedMultiplier`, 난이도별 속도 상수는 수정하지 않는다.
- 구현 위치: 수정 없음, Generator 확인 항목
- 핵심 코드 구조:
  ```swift
  // 변경 금지: PlayerNode.update(deltaTime:)
  let movementModeScale = isRunning
      ? GameConfig.playerRunSpeedScale
      : GameConfig.playerWalkSpeedScale
  let speed = baseSpeedStart * speedMultiplier * movementModeScale
  physicsBody?.velocity = CGVector(
      dx: currentDirection.dx * speed,
      dy: currentDirection.dy * speed
  )
  ```

## 주의사항
- `DPadNode`는 `PlayerNode`를 직접 알지 않는 현재 구조를 유지한다. 방향 콜백은 기존처럼 `GameScene+Setup.swift`의 `dpad.onDirectionChanged`에서 `player.facing(_:)`만 호출한다.
- 첫 반응 강화는 정지 -> 입력 시작 순간에만 적용한다. 입력 유지 중 지속적으로 magnitude floor를 걸면 아날로그 감도가 사라질 수 있으므로 금지한다.
- 축 보정은 `currentDirection`에만 적용하고, `thumbNode` 위치는 실제 손가락 위치 기준으로 유지한다. 그래야 조작 UI 피드백이 터치 위치와 어긋나지 않는다.
- `Direction(vector:)`는 수정하지 않는다. 보정된 `currentDirection`을 넘기면 기존 4방향 facing 규칙이 그대로 동작한다.
- `Timer`, `DispatchQueue.main.asyncAfter`, 강제 언래핑(`!`)을 추가하지 않는다.
- 새 수치는 반드시 `GameConfig` 상수로 둔다. `DPadNode`나 `GameScene+MovementInput` 내부에 숫자를 직접 하드코딩하지 않는다.
- `resetMovementInput()`, pause/resume, freeze/dash 가드 경로는 그대로 유지한다. 이 경로들이 `smoothedMoveDirection = .zero`로 되돌리기 때문에 다음 실제 입력에서 첫 반응 강화가 자연스럽게 다시 적용된다.
