# QA 검수 보고서 — Phase 6-9 · F 피격 카메라 셰이크 + 빨간 화면 플래시

## SPEC 기능 검증

| # | 기능 | 결과 |
|---|---|---|
| 1 | GameConfig 상수 7개 추가 | PASS — `Config/GameConfig.swift:285-303`에 `// MARK: - Hit Feedback (Phase 6-9)` 섹션 + 7개 상수, 모든 상수 한국어 doc comment로 trade-off 명시 |
| 2 | CameraShakeAction enum 네임스페이스 | PASS — `enum CameraShakeAction { static func make() -> SKAction }` case 없음, 인스턴스화 차단 |
| 3 | HitFlashNode 자가 소멸 5호 | PASS — `final class HitFlashNode: SKSpriteNode, SelfDismissingNode`, `flash(sceneSize:)`가 `sequence([fadeIn, fadeOut, removeFromParent])` |
| 4 | GameScene 콜백 확장 | PASS — `GameScene.swift:204-216`, 호출 순서 `cameraNode.run(shake) → addChild(flash) → flash.flash() → endGame()` 고정, 헤더 주석 1줄 추가 |
| 5 | pbxproj 8지점 등록 | PASS — PBXBuildFile×2, PBXFileReference×2, Group children×2, Sources phase×2 = 8지점. UUID 029/030, 충돌 0 |

## 빌드 검증

- **결과**: BUILD SUCCEEDED
- **명령**: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- **컴파일 에러**: 0
- **컴파일 경고**: 0

## 회귀 0줄 검증 (`git diff`)

`git diff --stat HEAD` 결과:
- **수정**: `Config/GameConfig.swift` +20, `GameScene.swift` +13/-1, `project.pbxproj` +8
- **신규**: `Systems/CameraShakeAction.swift` (48줄), `Nodes/HitFlashNode.swift` (46줄)

**0줄 미접촉 (20개 파일 일괄 검증)**:
- 매니저: AudioManager / HapticsManager / BGMPlayer
- 시스템: ScoreSystem / ContactRouter (시그니처 0줄, 콜백 등록 측만 변경) / SpawnSystem
- 씬: TitleScene / ResultScene
- 노드: SparkleEffectNode / BombFlashNode / PlayerNode / EnemyNode / NoteNode / ProjectileNode / HUDNode / CharacterCardNode / AirplaneNode / AirforceOverlayNode
- 인프라: SelfDismissingNode / ColorTokens

→ SPEC §금지 항목 100% 준수.

## count=6 누적 변위 검산

| step | dx | 누적 |
|---|---|---|
| 0 (+amp) | +8 | +8 |
| i=1 (홀, −2amp) | −16 | −8 |
| i=2 (짝, +2amp) | +16 | +8 |
| i=3 (홀, −2amp) | −16 | −8 |
| i=4 (짝, +2amp) | +16 | +8 |
| i=5 (홀, −2amp) | −16 | **−8** |
| 복귀 (count%2==0 → +amp) | +8 | **0 ✓** |

총 스텝 7, 총 시간 0.28초. 셰이크 후 카메라 원위치 100% 보장.

## 정적 패턴 검증

| 항목 | 결과 |
|---|---|
| 강제 언래핑 `!` (코드) | **0건** (신규 2파일 grep, `fatalError("init(coder:)...")`는 SpriteKit 표준 패턴) |
| `Timer.scheduledTimer` | **0건** |
| `DispatchQueue` 신규 사용 | **0건** |
| 매직 넘버 | **0건** (모든 수치 GameConfig 경유, 산술 표현식 인덱스만 raw) |
| `private` 캡슐화 | 적용 (HitFlashNode 내부 메서드, CameraShakeAction은 namespace) |
| MARK 섹션 구분 | 신설 (`// MARK: - Hit Feedback (Phase 6-9)`, `// MARK: - Make`, `// MARK: - Init`, `// MARK: - Flash`) |
| 새 public API | HitFlashNode/CameraShakeAction만 — SPEC 허용 |
| 새 ColorTokens | **0건** (ganhoBloodAccent 재사용) |
| 새 PhysicsCategory | **0건** |
| 새 효과음/햅틱 | **0건** (haptics.heavy() 그대로 활용) |
| update 안 addChild | **0건** (이벤트 기반 콜백) |
| `[weak self] + guard let self` | 적용 (`GameScene.swift:204-205`) |

## 검증 시나리오 (a)~(i) 정적 추적

| # | 시나리오 | 결과 |
|---|---|---|
| (a) | 빌드 BUILD SUCCEEDED, 경고 0 | PASS |
| (b) | F 피격 시 3채널 동시 (haptics.heavy + shake + flash) | PASS (트리거 순서 코드 확인) |
| (c) | 카메라 원위치 정확 | PASS (count=6 검산 0) |
| (d) | 메모리 누수 0 | PASS (HitFlashNode self-removeFromParent, SKAction 노드 아님) |
| (e) | ResultScene 전환 안전 | PASS (transition fade 0.4 > shake 0.28 / flash 0.30) |
| (f) | 시간 만료 endGame 영향 없음 | PASS (콜백 우회) |
| (g) | enemy 접촉 endGame 영향 없음 | PASS (onEnemyHit 미변경) |
| (h) | 회귀 0줄 | PASS (위 §회귀 검증) |
| (i) | Phase 1~6 회귀 정상 | PASS (관련 시스템 0줄) |

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | **0건** |
| P1 중요 | **0건** |
| P2 권장 | **0건** |

## 통과 항목 (강점)

- **트리거 순서 고정**: `cameraNode.run(shake) → addChild(flash) → flash.flash() → endGame()` — 셰이크/플래시 발화 후에야 endGame이 `.gameOver` 전환 → update가 다음 프레임부터 early return → 카메라 follow가 셰이크 잠식 안 함.
- **count=6 누적 변위 0**: 셰이크 후 카메라 원위치 수학적 보장. 부호 로직 일반화(count 짝/홀).
- **자가 소멸 5호**: SparkleEffectNode → BombFlashNode → AirplaneNode → AirforceOverlayNode → HitFlashNode. SelfDismissingNode marker protocol 패턴 누적.
- **부정/긍정 피드백 디자인 대칭**: 6-8 sparkle(긍정, 흰빛, 월드 좌표, 0.5s) ↔ 6-9 hit(부정, 빨강, 화면 좌표, 0.30s). 같은 자가 소멸 패턴을 정반대 의미에 적용.
- **Rule of Three 준수**: HitFlashNode가 BombFlashNode와 비슷하지만 색·타이밍·zPosition·트리거가 달라 별도 클래스. 공통 추출(BaseFlashNode)은 3번째 등장 시점까지 보류 — premature abstraction 회피.
- **enum 네임스페이스 패턴**: CameraShakeAction은 case 없는 enum + static func — Swift 관용 idiom. 인스턴스화 차단.
- **ColorTokens 재사용**: `.ganhoBloodAccent`(HEX #D8315B)가 assets.md에 "피격 플래시"로 이미 정의됨. 새 색 추가 0.
- **endGame 멱등성 신뢰 위임**: 시각 효과 자체에 멱등 가드 안 둠. endGame의 `.gameOver` 가드에 위임 — 책임 분리.

## 채점

| 항목 | 점수 | 코멘트 |
|---|---:|---|
| Swift 패턴 일관성 (35%) | **10/10** | enum 네임스페이스, MARK, 매직 넘버 0, 강제 언래핑 0, weak self+guard let, 단일 책임, doc comment 한국어 trade-off 명시 |
| 게임 로직 완성도 (30%) | **10/10** | 트리거 순서 고정, count=6 검산 0, 자가 소멸 5호 패턴 일관성, cameraNode/worldNode 책임 분리, Rule of Three 준수 |
| 성능 & 안정성 (20%) | **10/10** | BUILD SUCCEEDED + 경고 0, weak self 적용, removeFromParent 자가 호출, flash() 내 self 미캡처, ResultScene 전환 안전 |
| 기능 완성도 (15%) | **10/10** | SPEC 기능 5개 전부 구현, 회귀 0줄 20파일 검증, pbxproj 8지점 정확, UUID 충돌 0 |

**가중 점수**: (10×0.35) + (10×0.30) + (10×0.20) + (10×0.15) = **10.0 / 10**

## 최종 판정: ✅ **합격**

**개선 지시**: 없음.

본 sprint는 SPEC 1회차에 그대로 구현하면서:
1. 자가 소멸 5호 패턴 누적으로 코드베이스 규범화
2. 5채널 멀티모달 피격 피드백(haptics.heavy + audio.gameOver + bgm.stop + shake + flash) 동시 발화 완성
3. count=6 누적 변위 0 수학적 보장으로 카메라 follow 안전
4. Rule of Three에 따라 BombFlashNode/HitFlashNode 공통 추출 보류 — premature abstraction 회피
5. 회귀 0줄 (20파일 검증) — SPEC §금지 항목 100% 준수

게임오버 0.3초가 게임에서 가장 풍부한 감각 입력 순간이 됨. Phase 6의 *시각 폴리싱 시리즈* 두 번째(6-8 긍정 / 6-9 부정)로 디자인 대칭 완성.
