# 위험 경고 개선

## 개요
맞기 전 위험을 더 빨리 알아차리고 피할 수 있도록 투사체 궤적, 적 접근, 피격 직전, 실제 피격 순간의 시각 언어를 분리한다. 점수 산식, 발사 간격, 속도, 콤보, 보상 수치는 유지하고 `GameConfig` 기반 경고 표시 상수와 SpriteKit 노드 연출만 추가한다.

## 변경 유형
혼합 — 위험 인지와 회피 판단을 돕는 게임플레이 피드백 + 시각 개선

## 게임 경험 의도
플레이어가 “갑자기 맞았다”가 아니라 “방금 위험을 봤고, 피하려다 맞았다/피했다”라고 느끼게 만든다. F와 청진기, 적 본체 접촉 위험을 각각 다른 경고로 읽게 하여 45초 회피 루프의 재미를 살린다. 난이도가 올라갈수록 경고가 완전히 사라지는 것이 아니라 표시 시간/강도/정보량이 줄어드는 방향으로 긴장감을 만든다.

## Sprint 범위 계약
- **허용**: SPEC 기능의 정상 동작에 필수적인 최소 연동 변경
- **금지**: SPEC에 없는 독립적인 새 기능/효과 추가
- **판단 기준**: "이 변경이 없으면 SPEC 기능이 제대로 동작하지 않는가?" → YES면 허용, NO면 금지
- **이번 Sprint에서 금지**: 점수 산식 변경, 음표/보너스 보상 변경, 투사체 속도 변경, 투사체 발사 주기 변경, 적 패트롤 waypoint/속도 변경, 새 적/새 아이템 추가

## 변경 범위

### 수정할 파일
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`: 위험 경고 표시 시간, 거리, 알파, zPosition, 난이도별 경고 강도 상수 추가
- `GanhoMusic/GanhoMusic Shared/Nodes/EnemyNode.swift`: F 발사 텔레그래프 단계에서 경고선/부채꼴을 생성하고 실제 발사 방향과 맞추는 최소 상태 추가
- `GanhoMusic/GanhoMusic Shared/Nodes/EnemyTelegraphNode.swift`: 기존 `!` 깜빡임은 유지하고 경고선 부착 API만 추가
- `GanhoMusic/GanhoMusic Shared/Nodes/ProfessorNode.swift`: 청진기 텔레그래프 단계에 짧은 경고선을 추가하고 발사 방향과 맞춤
- `GanhoMusic/GanhoMusic Shared/Nodes/ProfessorTelegraphNode.swift`: 기존 `!` 깜빡임 유지, 청진기 경고선 부착 API 추가
- `GanhoMusic/GanhoMusic Shared/Nodes/FProjectileNode.swift`: 피격 직전 상태용 pulse/halo 강화 메서드 추가
- `GanhoMusic/GanhoMusic Shared/Nodes/StethoscopeNode.swift`: 피격 직전 상태용 pulse/halo 강화 메서드 추가
- `GanhoMusic/GanhoMusic Shared/Nodes/EnemyNode.swift`: 적 접근 위험 링 업데이트 진입점 추가
- `GanhoMusic/GanhoMusic Shared/Nodes/StoneGuardNode.swift`: 적 접근 위험 링 업데이트 진입점 추가
- `GanhoMusic/GanhoMusic Shared/Nodes/ProfessorNode.swift`: 적 접근 위험 링 업데이트 진입점 추가
- `GanhoMusic/GanhoMusic Shared/GameScene.swift`: 매 프레임 위험 거리 계산 업데이트 호출 추가
- `GanhoMusic/GanhoMusic Shared/GameScene+Contact.swift`: 피격 순간 연출을 F 즉사/청진기 동결/적 본체 접촉으로 구분
- `GanhoMusic/GanhoMusic Shared/GameScene+Feedback.swift`: 피격 직전/피격 순간 피드백 helper 추가

### 추가할 파일
- `GanhoMusic/GanhoMusic Shared/Nodes/ProjectileWarningLineNode.swift`: F/청진기 발사 전 궤적 경고선 노드
- `GanhoMusic/GanhoMusic Shared/Nodes/EnemyProximityWarningNode.swift`: 적 본체 주변 접근 위험 링 노드
- `GanhoMusic/GanhoMusic Shared/Models/DangerWarningProfile.swift`: 난이도별 경고량을 묶는 값 타입

## 기능 상세

### 기능 1: 투사체/F 경고선 개선
- 설명: 수간호사와 이교수가 발사 전 `!`만 보여주던 상태를 유지하되, 실제 발사 방향을 짧은 픽셀 경고선으로 함께 보여준다. F burst는 발사 수만큼 부채꼴 선을 보여주고, 청진기는 단일 선으로 보여준다.
- 구현 위치: `EnemyNode.swift` `MARK: - Throw State Machine`, `MARK: - Fire`, `ProfessorNode.swift` `MARK: - Throwing`, 새 `ProjectileWarningLineNode.swift`
- 핵심 코드 구조:
  ```swift
  struct DangerWarningProfile {
      let telegraphLineLength: CGFloat
      let telegraphLineAlpha: CGFloat
      let projectileNearMissRadius: CGFloat
      let showAllBurstLines: Bool
  }
  ```
  ```swift
  final class ProjectileWarningLineNode: SKNode {
      init(angles: [CGFloat], length: CGFloat, color: UIColor, alpha: CGFloat) {
          super.init()
          for angle in angles {
              let line = SKShapeNode()
              let path = CGMutablePath()
              path.move(to: .zero)
              path.addLine(to: CGPoint(x: cos(angle) * length, y: sin(angle) * length))
              line.path = path
              line.strokeColor = color
              line.lineWidth = GameConfig.projectileWarningLineWidth
              line.alpha = alpha
              addChild(line)
          }
      }
  }
  ```
  ```swift
  // EnemyNode
  private var pendingShotAngles: [CGFloat] = []

  private func enterTelegraph() {
      throwState = .telegraph
      telegraphRemaining = GameConfig.nurseChiefTelegraphDuration
      pendingShotAngles = makeShotAnglesTowardCurrentTarget()
      let node = EnemyTelegraphNode()
      node.attachWarningLines(angles: visibleAngles(from: pendingShotAngles),
                              profile: GameConfig.warningProfileByDifficulty[difficulty] ?? .easy)
      addChild(node)
      telegraphNode = node
      node.startBlinking()
  }

  private func fireF() {
      let angles = pendingShotAngles.isEmpty ? makeShotAnglesTowardCurrentTarget() : pendingShotAngles
      // 기존 burstCount, speed, spawnPoint, charm 분기는 유지하고 angle만 pending 값을 사용
  }
  ```
- 필수 조건:
  - 경고선과 실제 F 방향이 어긋나지 않도록 `enterTelegraph()`에서 계산한 각도를 `fireF()`가 재사용한다.
  - 이 변경은 발사 속도/개수/간격을 바꾸지 않는다. 조준 시점만 텔레그래프 시작 시점으로 고정하는 것은 경고선 정합을 위한 필수 연동 변경으로 허용한다.
  - `GameConfig.projectileWarningLineWidth`, `projectileWarningLineLengthByDifficulty`, `projectileWarningAlphaByDifficulty`를 사용하고 리터럴 수치를 직접 쓰지 않는다.

### 기능 2: 적 접근 위험 표현
- 설명: 적 본체 접촉 위험은 투사체와 다른 문제이므로 Enemy/StoneGuard/Professor 주변에 거리 기반 위험 링을 표시한다. 플레이어가 가까울수록 링의 알파와 scale pulse가 강해지고, 멀면 숨긴다.
- 구현 위치: 새 `EnemyProximityWarningNode.swift`, `EnemyNode.swift`, `StoneGuardNode.swift`, `ProfessorNode.swift`, `GameScene.swift` `MARK: - Game Loop`
- 핵심 코드 구조:
  ```swift
  final class EnemyProximityWarningNode: SKNode {
      private let ring = SKShapeNode(circleOfRadius: GameConfig.enemyDangerRingRadius)

      func update(distanceToPlayer distance: CGFloat, profile: DangerWarningProfile) {
          let start = profile.enemyWarningStartDistance
          let critical = profile.enemyWarningCriticalDistance
          guard distance <= start else {
              alpha = 0
              removeAction(forKey: GameConfig.enemyDangerRingPulseActionKey)
              return
          }
          let t = max(0, min(1, (start - distance) / (start - critical)))
          alpha = GameConfig.enemyDangerRingMinAlpha + t * GameConfig.enemyDangerRingAlphaRange
          startPulseIfNeeded(critical: t > GameConfig.enemyDangerRingPulseThreshold)
      }
  }
  ```
  ```swift
  // GameScene.update after enemy/professor movement updates
  let profile = GameConfig.warningProfileByDifficulty[difficulty] ?? .easy
  enemy.updateProximityWarning(distanceToPlayer: distance(from: enemy.position, to: player.position),
                               profile: profile)
  if stoneGuard.parent != nil {
      stoneGuard.updateProximityWarning(distanceToPlayer: distance(from: stoneGuard.position, to: player.position),
                                        profile: profile)
  }
  professor?.updateProximityWarning(distanceToPlayer: distance(from: professor.position, to: player.position),
                                    profile: profile)
  ```
- 필수 조건:
  - `StoneGuardNode`는 hard에서 parent가 없으므로 `stoneGuard.parent != nil` 가드 후 업데이트한다.
  - `ProfessorNode`는 물리 body가 없고 접촉 피해가 청진기 중심이므로 링은 hard 난이도 “움직이는 위험원 인지” 수준으로 낮은 알파를 사용한다.
  - `update()` 안에서 새 노드를 반복 생성하지 않는다. 각 적 노드 init 또는 lazy attach에서 1회 생성 후 alpha/scale만 업데이트한다.

### 기능 3: 피격 직전/피격 순간 구분
- 설명: 피격 직전은 플레이어 주변 근접 경고와 투사체 pulse로 표현하고, 실제 피격 순간은 기존 HitFlash/카메라 shake/햅틱을 상황별로 다르게 사용한다. F 즉사는 강한 빨간 플래시, 청진기 동결은 파란/노란 짧은 링 또는 토스트 중심, 적 본체 접촉은 짧은 충돌 스파크로 구분한다.
- 구현 위치: `FProjectileNode.swift`, `StethoscopeNode.swift`, `GameScene.swift`, `GameScene+Contact.swift`, `GameScene+Feedback.swift`
- 핵심 코드 구조:
  ```swift
  // FProjectileNode / StethoscopeNode
  func updateNearMissWarning(distanceToPlayer distance: CGFloat, profile: DangerWarningProfile) {
      guard distance <= profile.projectileNearMissRadius else {
          stopNearMissPulse()
          return
      }
      startNearMissPulse()
  }
  ```
  ```swift
  // GameScene.update
  worldNode.enumerateChildNodes(withName: "projectile") { [weak self] node, _ in
      guard let self = self, let projectile = node as? FProjectileNode else { return }
      let distance = hypot(projectile.position.x - self.player.position.x,
                           projectile.position.y - self.player.position.y)
      projectile.updateNearMissWarning(distanceToPlayer: distance, profile: profile)
  }
  worldNode.enumerateChildNodes(withName: "stethoscope") { [weak self] node, _ in
      guard let self = self, let stethoscope = node as? StethoscopeNode else { return }
      let distance = hypot(stethoscope.position.x - self.player.position.x,
                           stethoscope.position.y - self.player.position.y)
      stethoscope.updateNearMissWarning(distanceToPlayer: distance, profile: profile)
  }
  ```
  ```swift
  // GameScene+Contact
  contactRouter.onEnemyHit = { [weak self] in
      guard let self = self else { return }
      if self.player.isInvulnerable { return }
      self.playBodyHitFeedback()
      self.endGame()
  }

  contactRouter.onProjectileHitPlayer = { [weak self] node in
      guard let self = self else { return }
      // enchanted 분기는 기존 그대로
      if self.player.isInvulnerable { return }
      self.playFatalProjectileHitFeedback()
      self.checkAndTriggerComboBreak()
      self.endGame()
  }

  contactRouter.onStethoscopeHitPlayer = { [weak self] node in
      guard let self = self else { return }
      if self.player.isInvulnerable {
          self.deferRemoveAfterContact(node)
          return
      }
      self.playStethoscopeHitFeedback()
      // 기존 toast -> freeze 직렬화 유지
  }
  ```
- 필수 조건:
  - 피격 직전 경고는 `update()`에서 기존 노드 alpha/scale/action만 제어한다.
  - 실제 피격 순간은 contact callback에서만 실행한다.
  - F 즉사 흐름의 `endGame()` 호출과 청진기 `freeze(duration:)` 흐름은 유지한다.

### 기능 4: 난이도별 경고량 조절
- 설명: Easy는 선명하고 긴 경고, Normal은 중간, Hard는 더 짧고 얇지만 최소한의 방향 정보는 남긴다. 난이도 조절은 경고 표시량만 바꾸며 실제 위험 수치와 점수는 바꾸지 않는다.
- 구현 위치: 새 `DangerWarningProfile.swift`, `GameConfig.swift`, `EnemyNode.apply(_:)` 또는 `GameScene`에서 profile 전달
- 핵심 코드 구조:
  ```swift
  struct DangerWarningProfile {
      let telegraphLineLength: CGFloat
      let telegraphLineAlpha: CGFloat
      let showAllBurstLines: Bool
      let enemyWarningStartDistance: CGFloat
      let enemyWarningCriticalDistance: CGFloat
      let projectileNearMissRadius: CGFloat

      static let easy = DangerWarningProfile(...)
      static let normal = DangerWarningProfile(...)
      static let hard = DangerWarningProfile(...)
  }
  ```
  ```swift
  // GameConfig
  static let warningProfileByDifficulty: [Difficulty: DangerWarningProfile] = [
      .easy: .easy,
      .normal: .normal,
      .hard: .hard
  ]
  ```
- 권장 정책:
  - Easy: F burst 선을 모두 표시, 적 접근 링 시작 거리 넓게, near-miss pulse 반경 넓게
  - Normal: F burst 선 모두 표시하되 알파/길이 감소, 적 접근 링 중간
  - Hard: F burst가 많을 때 중앙/양끝 등 핵심 방향만 표시하거나 알파를 낮춤, 적 접근 링은 critical 근처에서만 강하게 표시
- 필수 조건:
  - 난이도별 `projectileBurstCountByDifficulty`, `projectileFireInterval*`, `obs*Speed*`, `nurseChiefPatrolSpeed*` 값은 변경하지 않는다.
  - 경고 profile lookup은 `?? .easy` fallback을 사용한다.

## 주의사항
- `EnemyNode.enterTelegraph()`에서 경고선 방향을 만들면 `fireF()`도 같은 각도를 써야 한다. 경고와 실제 탄이 다르면 회피 학습이 깨진다.
- `ProfessorNode.throwStethoscope()`는 현재 target을 텔레그래프 시작 시 캡처한다. 경고선도 같은 target 기준으로 만들고 `fireStethoscope(target:world:)`에 동일 target을 전달한다.
- `GameScene.update()`에서 위험 노드를 새로 만들지 말고 이미 존재하는 projectile/enemy child node를 업데이트한다.
- `worldNode.enumerateChildNodes`는 `"projectile"`과 `"stethoscope"`만 대상으로 제한한다. 전체 child 순회나 정렬을 넣지 않는다.
- `StoneGuardNode.updatePixelAnimation(deltaTime:)`는 현재 `GameScene.update`에서 호출되지 않는다. 이번 Sprint에서 접근 링 업데이트를 넣을 때 함께 호출해도 시각 애니메이션 정상화를 위한 필수 연동 변경으로 허용한다.
- `EnemyTelegraphNode.startBlinking()`의 `"blink"` 문자열은 새 상수 `GameConfig.telegraphBlinkActionKey`로 옮기는 것을 권장한다. 단, 기능 구현과 무관한 광범위 리팩터는 하지 않는다.
- 강제 언래핑 금지. profile, professor, world/provider lookup은 `guard let` 또는 `??` fallback으로 처리한다.
- `Timer`, `DispatchQueue.main.asyncAfter` 금지. 모든 지연/펄스는 `SKAction.wait`, `SKAction.sequence`, `SKAction.repeatForever`를 사용한다.
- 새 색상은 기존 `ColorTokens`/`GameConfig` 위험 색상 계열을 우선 사용한다. 임의 `UIColor(red:green:blue:)` 추가는 `GameConfig` 상수 정의 위치에서만 허용한다.
- 피격 순간 feedback helper는 `GameScene+Feedback.swift`에 두고, contact callback은 분기와 호출 순서만 담당하게 유지한다.
