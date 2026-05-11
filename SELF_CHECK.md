# 자체 점검 — Phase 4-2 석조무사 접촉 감지 골격

전략: 신규 sprint (1회차) — Case 판정 없음. SPEC 그대로 적용.

## 파일별 변경 줄 수

| 파일 | 변경 | 실제 |
|---|---|---|
| `Config/PhysicsCategory.swift` | +1줄 | +1줄 (stoneGuard = 0b100000) |
| `Nodes/StoneGuardNode.swift` | +~12줄 | +14줄 / -1줄 (헤더 1줄 + PhysicsBody 블록 13줄, 기존 nil 주석 1줄 삭제) |
| `Systems/ContactRouter.swift` | +~5줄 | +6줄 (콜백 변수 1줄 + 분기 3줄 + 주석 1줄 + 공백 1줄) |
| `GameScene.swift` | +~4줄 | +4줄 (헤더 MARK 1줄 + onStoneGuardContact 등록 3줄) |

`git diff --stat` 합계: 4개 파일 (Swift), +25 / -1 줄. SPEC 예상 범위(+~22줄)와 일치.

## SPEC 기능 체크

- [x] **기능 1**: PhysicsCategory.stoneGuard = 0b100000 (32) — projectile 다음 줄에 삽입. 기존 비트 미변경.
- [x] **기능 2**: StoneGuardNode init 내 `super.init` 다음·`startPatrol()` 직전에 PhysicsBody 부착. `isDynamic=false`, `collisionBitMask=0`, `contactTestBitMask=.player`. 기존 `physicsBody = nil` 주석 삭제. 파일 헤더에 Phase 4-2 라인 1줄 추가.
- [x] **기능 3**: `onStoneGuardContact: () -> Void = {}` 콜백 신설 (`onEnemyHit` 다음). `didBegin` 분기 순서 `enemy → stoneGuard → projectile → note`.
- [x] **기능 4**: GameScene 헤더 MARK 1줄 추가. `configureContactRouter()` 본문 끝에 stub 클로저 등록 (TODO 주석 1줄만, `[weak self]` 생략 — 미사용 캡처 경고 회피).

## OoS 미위반 자가 점검 (체크리스트)

- [x] `GameScene+Setup.swift` 한 줄도 변경 없음 — `git status` working tree clean 확인
- [x] `GameConfig.swift` 한 줄도 변경 없음 — stoneGuard 4개 상수(width/height/speed/waypoints) 그대로
- [x] pbxproj 변경 0건 (신규 파일 0건)
- [x] waypoint 좌표/패트롤 속도/방향/크기 미변경 — `GameConfig.stoneGuardWaypoints` 미변경, `startPatrol()` 본문 미변경
- [x] 다른 노드(Player/Enemy/Note/Projectile/HUD/DPad) 변경 0건
- [x] 다른 시스템(SpawnSystem/ScoreSystem) 변경 0건
- [x] TitleScene/ResultScene 변경 0건
- [x] 새 ColorTokens 토큰 신설 0건
- [x] `update()` 게임 루프 변경 0건
- [x] `endGame()` 본문 변경 0건
- [x] `configureContactRouter()` 외 GameScene 메서드 변경 0건
- [x] 이스터에그 효과(오버레이/비행기/폭탄/도주) 구현 0건 — stub 본문 TODO 주석만
- [x] `print` / `NSLog` / `debugPrint` 0건 — `grep` 결과 `no matches`
- [x] macOS/tvOS Sources phase 변경 0건
- [x] Test 코드 추가 0건

## Swift 패턴 준수

- 강제 언래핑 미사용: 준수 (4개 파일 어디에도 `!` 없음)
- guard let 옵셔널 처리: 준수 (해당 변경분에 옵셔널 없음 — stub 콜백 본문 비어있음)
- MARK 섹션 구분: 준수 (`// MARK: - Callbacks` 섹션 안에 새 변수 삽입)
- GameConfig 상수 사용: 준수 — PhysicsBody size는 `GameConfig.stoneGuardWidth/Height` 그대로, `categoryBitMask`/`contactTestBitMask`는 `PhysicsCategory.stoneGuard`/`.player` 사용. 매직 넘버 0
- weak self 캡처: 의도적 생략 — stub 본문 self 미사용. `[weak self]`만 두면 *unused capture* 경고 위험 (SPEC 명시)

## SpriteKit 패턴 준수

- didMove(to:)에서 초기화: 해당 없음 (didMove 미변경)
- dt 기반 이동: 해당 없음 (StoneGuard는 SKAction.move 기반 — Phase 4-1 그대로)
- SKAction 스폰 패턴: 해당 없음 (스폰 미변경)
- 충돌 후 노드 즉시 삭제 없음: 준수 (stub 본문 비어있음 → removeFromParent 호출 자체가 없음)
- HUD 노드 분리: 해당 없음 (HUD 미변경)
- PhysicsBody 3비트마스크 패턴: 준수 — category(.stoneGuard) / collision(0, 통과) / contactTest(.player, 알림) 셋 독립 명시
- 양방향 collision 정책: 안전 — 다른 노드 `collisionBitMask`에 `.stoneGuard` 미포함 (Player=.wall, Enemy=.wall, Note=0, Projectile=0). 양방향 수정 0건으로 통과 보장

## 빌드 상태

- `xcodebuild ... build` **BUILD SUCCEEDED**
- 경고: 0건 (`grep -E "warning:|error:"` 결과 빈 출력)
- 에러: 0건

## 검증 시나리오 (a)~(h) 정적 검증 결과

| # | 시나리오 | 정적 검증 결과 |
|---|---|---|
| (a) | 시작 직후 4-1과 동일 패트롤 | PASS — `startPatrol()` 본문 미변경, `setupStoneGuard()` 미변경, `stoneGuardWaypoints` 미변경 (grep 확인) |
| (b) | 플레이어 통과 시 튕김·정지 0 | PASS — `collisionBitMask = 0`(stoneGuard), `isDynamic = false`. Player/Enemy/Note/Projectile 어디에도 `.stoneGuard` 미포함 (grep 확인) |
| (c) | 통과 시 점수·콤보·HUD 변화 0 | PASS — `onStoneGuardContact` 본문은 TODO 주석 1줄만. `scoreSystem`/`hud`/`endGame` 호출 0건 |
| (d) | 통과 시 콘솔 출력 0 | PASS — 4개 변경 파일에 `print`/`NSLog`/`debugPrint` 0건 (grep 결과 `no matches`) |
| (e) | enemy/projectile/note 접촉 회귀 0 | PASS — `didBegin` 기존 enemy/projectile/note 분기 본문 미변경. `handleProjectileContact`/`handleNoteContact` 함수 미변경. stoneGuard 분기는 enemy 다음·projectile 앞에 삽입만 됨 |
| (f) | 한 판 → 게임오버 회귀 0 | PASS — `endGame()` 본문 미변경, `SpawnSystem.stop` 미호출 변경, ResultScene presentation flow 미변경 |
| (g) | 결과 화면 → 다시 플레이 회귀 0 | PASS — TitleScene/ResultScene 0줄 변경 (working tree clean 확인) |
| (h) | 빌드 SUCCEEDED + 경고 0 | PASS — xcodebuild BUILD SUCCEEDED, 경고/에러 0건 |

## 분기 순서 검증

`ContactRouter.didBegin` 최종 분기 순서:
1. `enemy` (게임오버 최우선)
2. `stoneGuard` (신설 — enemy 다음, projectile/note 앞)
3. `projectile`
4. `note`

근거: enemy↔stoneGuard 동시 접촉 시(이론상 불가능) 게임오버 누락 방지. enemy/projectile/note 카테고리는 서로 배타적이라 순서 변경의 부작용 없음.

## 캡처 정책 검증

stub 콜백은 `[weak self]` 생략:
```swift
contactRouter.onStoneGuardContact = {
    // Phase 4-2 — stub. 4-3에서 이스터에그 트리거 본체가 들어옴.
}
```
- self 미사용 → 캡처할 게 없음 → `[weak self]` 생략이 정확
- 빈 캡처 리스트만 두면 Xcode가 *unused capture* 경고를 띄울 수 있음 → SPEC 주의사항 7 "경고 0건" 충족
- 4-3에서 self를 사용할 때 `[weak self] in`을 추가 (호출 측 시그니처 미변경)

## 범위 외 미구현 항목

- 이스터에그 효과 본체 (오버레이/비행기/폭탄/수간호사 도주): **의도적 미구현** — SPEC 명시대로 4-3에서 본체 추가. stub 콜백 시그니처는 본 sprint에서 확정 완료.
- 그 외 SPEC 범위 외 변경 0건.
