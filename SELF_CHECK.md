# 자체 점검 — Phase 4-1 석조무사 NPC

전략: Case A (1회차) — SPEC 준수형 신규 구현.

## SPEC In Scope 항목 체크

- [x] **기능 1**: `Nodes/StoneGuardNode.swift` 신설
  - `final class StoneGuardNode: SKSpriteNode`
  - `init()` 색상 `.ganhoPaper`, name "stoneGuard", zPosition 5
  - `physicsBody` 부착 안 함 (기본 nil)
  - `required init?(coder:)` fatalError
  - `private func startPatrol()` — waypoints 순회, hypot으로 거리 계산, dist/speed로 duration 계산, `SKAction.repeatForever(.sequence(moves))` 실행
- [x] **기능 2**: `GameConfig.swift` `// MARK: - Stone Guard (Phase 4-1)` 섹션 + 신규 5상수 (Statistics 다음, 파일 끝)
  - `stoneGuardWidth: CGFloat = 16`
  - `stoneGuardHeight: CGFloat = 20`
  - `stoneGuardSpeed: CGFloat = 55`
  - `stoneGuardWaypoints: [CGPoint]` (4개 좌표, 시계방향)
  - 모든 상수에 `///` 퀵헬프 주석
- [x] **기능 3**: `GameScene+Setup.swift`에 `setupStoneGuard()` 추가 (extension 맨 끝, setupEnemy 다음)
- [x] **기능 4**: `GameScene.swift` 본체 변경
  - 헤더 코멘트에 Phase 4-1 1줄 추가
  - Properties에 `let stoneGuard = StoneGuardNode()` 1줄 (enemy 다음)
  - `didMove(to:)`에 `setupStoneGuard()` 호출 1줄 (setupEnemy 다음)
  - update / contactRouter / endGame 등 손대지 않음
- [x] **기능 5**: pbxproj 4곳 등록 (식별자 0017, 충돌 검증 완료)
  - PBXBuildFile (line 28)
  - PBXFileReference (line 50)
  - Nodes 그룹 children (line 185, 그룹 식별자 `A1C0F1570000000000000007`)
  - iOS PBXSourcesBuildPhase (line 416)
  - tvOS/macOS Sources phase 미수정

## 신설/수정 파일 목록 + 줄 수

| 종류 | 파일 | 줄 수 |
|---|---|---|
| 신설 | `GanhoMusic Shared/Nodes/StoneGuardNode.swift` | 52 |
| 수정 | `GanhoMusic Shared/Config/GameConfig.swift` | 192 (+17) |
| 수정 | `GanhoMusic Shared/GameScene+Setup.swift` | 154 (+8) |
| 수정 | `GanhoMusic Shared/GameScene.swift` | 212 (+3) |
| 수정 | `GanhoMusic.xcodeproj/project.pbxproj` | (+4 항목) |

## Swift 패턴 준수

- 강제 언래핑 미사용: 준수 (StoneGuardNode 내 `!` 사용 0건)
- guard let / if let 옵셔널 처리: 해당 없음 (옵셔널 변수 없음)
- MARK 섹션 구분: 준수 (`// MARK: - Init`, `// MARK: - Patrol`)
- GameConfig 상수 사용: 준수 (width/height/speed/waypoints 모두 GameConfig 경유)
- weak self 캡처: 해당 없음 (클로저 미사용 — SKAction.move/sequence/repeatForever만 사용)
- `final class`: 준수
- `required init?(coder:)` fatalError: 준수
- 매직 넘버 0: 준수 (좌표/속도/크기 모두 GameConfig)
- 한국어 변수명 0: 준수 (변수명 영어, 주석만 한국어)

## SpriteKit 패턴 준수

- 초기화는 `didMove(to:)`에서: 준수 (setupStoneGuard 호출 위치)
- dt 기반 이동: 준수 (SKAction이 자동 dt 처리, update() 미사용)
- SKAction 스폰 패턴: 해당 없음 (이번 sprint는 spawn 미수정)
- Timer/DispatchQueue 0: 준수
- `physicsBody` 부착 0: 준수 (SPEC OoS — 4-2에서 도입)
- 노드 즉시 삭제 0: 해당 없음 (충돌 처리 없음)
- HUD 노드 분리: 해당 없음 (worldNode 자식)
- zPosition 명시: 준수 (5 — EnemyNode와 동일)
- 카테고리 비트마스크 PhysicsCategory 미수정: 준수
- ColorTokens 미수정: 준수 (`.ganhoPaper` 재사용)

## 빌드 상태

- 빌드 명령:
  ```
  xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
             -scheme "GanhoMusic iOS" \
             -destination 'platform=iOS Simulator,name=iPhone 17' build
  ```
- 결과: **`** BUILD SUCCEEDED **`**
- 에러: **0건**
- 경고: **0건** (`grep -E "(warning|error):"` 출력 없음 — `Metadata extraction skipped`는 AppIntents 무관 노이즈, 사용자 코드 무관)

## 검증 시나리오 정적 검증

| # | 시나리오 | 정적 검증 결과 |
|---|---|---|
| (a) | 게임 시작 직후 | setupStoneGuard()가 (200,100) 부여 → init 시점 startPatrol이 첫 .move(to: (760,100))로 진입 → `.ganhoPaper` 16×20 박스가 우측으로 이동 시작 ✓ |
| (b) | 약 10초 (560pt / 55 ≈ 10.18s) | 첫 변(좌하→우하) 거리 560pt, 55pt/s → ~10.18초에 (760,100) 도달 → 두 번째 .move((760,380))로 위쪽 이동 시작 ✓ |
| (c) | 약 15초 (10.18 + 280/55 ≈ 15.27s) | 두 번째 변(우하→우상) 거리 280pt, 55pt/s → ~5.09초 추가 → ~15.27초에 (760,380) 도달 → 좌측 이동 시작 ✓ |
| (d) | 약 25초 (15.27 + 560/55 ≈ 25.45s) | 세 번째 변(우상→좌상) 거리 560pt → ~10.18초 추가 → ~25.45초에 (200,380) 도달 → 아래쪽 이동 시작 ✓ |
| (e) | 약 30~31초 (25.45 + 280/55 ≈ 30.55s) | 네 번째 변(좌상→좌하) 거리 280pt → ~5.09초 추가 → ~30.55초에 (200,100) 복귀 → repeatForever로 두 번째 바퀴 시작 ✓ |
| (f) | 플레이어가 같은 위치 | physicsBody = nil → SKPhysicsContact 미발생 → ContactRouter didBegin 분기 0 → 그대로 통과 ✓ |
| (g) | 카메라 follow | stoneGuard는 worldNode 자식 → cameraNode가 player.position 추종 시 worldNode 좌표계가 viewport 안에서 흘러감 → 시각적 follow ✓ |
| (h) | 게임오버 | endGame()이 presentScene → GameScene ARC 해제 → 자식 트리(stoneGuard 포함) 함께 해제 → SKAction 자동 정리 ✓ (endGame 코드 손대지 않음 — SPEC 명시) |

### waypoint 좌표 검증 (정적)

- 모든 waypoint x ∈ [200, 760], y ∈ [100, 380] → 외곽 벽(0~960, 0~480) 내부 ✓
- 중앙 기둥 영역 x ∈ [460, 500], y ∈ [200, 280]:
  - 가로 변 (y=100, y=380) — 기둥 y 범위와 미접근 ✓
  - 세로 변 (x=200, x=760) — 기둥 x 범위와 미접근 ✓
- 한 바퀴 둘레: 560+280+560+280 = 1680pt → 1680/55 ≈ 30.55초 ✓ (SPEC 30.5초 일치)

### pbxproj 식별자 0017 충돌 검증

```
$ grep -c "0000000000000017" project.pbxproj
4
$ grep -n "0017" project.pbxproj
28:  PBXBuildFile (StoneGuardNode.swift in Sources)
50:  PBXFileReference (StoneGuardNode.swift)
185: Nodes 그룹 children
416: iOS PBXSourcesBuildPhase
```
4곳 모두 의도된 위치, 다른 식별자 영역과 충돌 없음.

## 범위 외 미구현 항목

없음 — SPEC In Scope 5개 항목 100% 구현, OoS 항목(physicsBody, PhysicsCategory.stoneGuard, 접촉 효과, 다른 NPC, 새 ColorTokens, tvOS/macOS Sources, update 게임 루프 변경, 기존 시스템 수정) 일절 손대지 않음.
