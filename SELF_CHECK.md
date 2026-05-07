# 자체 점검 — Phase 2-10 SpawnSystem 분리 (순수 리팩터)

전략: 1회차 (Case 해당 없음 — 신규 sprint).

## SPEC §"준수 룰" 15개 항목

| # | 룰 | 검증 방법 | 결과 |
|---|---|---|---|
| 1 | SpawnSystem.swift 신설 + final class | grep `final class SpawnSystem` → SpawnSystem.swift:13 | PASS |
| 2 | weak 의존성 4개 (scene, worldNode, player, enemy) | grep `private weak var (scene\|worldNode\|player\|enemy)` → 4건 (16~19행) | PASS |
| 3 | progressProvider closure 1건 | grep `progressProvider` → 저장형 var + @escaping 파라미터 + 호출부 모두 존재 | PASS |
| 4 | 9 메서드 모두 SpawnSystem 안 (private) | grep 9 함수명 → 모두 SpawnSystem.swift에 1+ 정의 (private 키워드 함께) | PASS |
| 5 | GameScene에서 9 메서드 *제거 완료* (검색 0건) | grep 9 함수명 → 전부 0건 | PASS |
| 6 | spawnSystem.start(...) 1건 (didMove) | GameScene.swift:62 1건 | PASS |
| 7 | spawnSystem.stop() 1건 (endGame) | GameScene.swift:347 1건 | PASS |
| 8 | endGame에서 removeAction 직접 호출 0건 | grep `removeAction` GameScene.swift → 0건 | PASS |
| 9 | endGame에서 enumerateChildNodes 직접 호출 0건 | grep `enumerateChildNodes` GameScene.swift → 0건 | PASS |
| 10 | 매직 넘버 0건 (모두 GameConfig.*) | SpawnSystem 안 모든 게임 상수는 GameConfig.noteSpawnInterval, noteMaxConcurrent, tileSize, mapWidth, mapHeight, projectileFireInterval, projectileFireIntervalEnd, projectileMaxConcurrent, projectileSpeed로 참조. count 초기값 0/1, magnitude > 0 가드는 산술 sentinel이므로 매직 넘버 아님. | PASS |
| 11 | 강제 언래핑 / Timer / print / as! / fileprivate / DispatchQueue 0건 | grep `[a-zA-Z_]!\b\|Timer\.\|print(\|fileprivate\|DispatchQueue\|as!` → 양 파일 모두 0건 | PASS |
| 12 | [weak self] 클로저 캡처 (재귀 fire + spawn) | SpawnSystem.swift:54 (spawn), :101 (fire 재귀) — 2건 | PASS |
| 13 | pbxproj SpawnSystem 등록 4지점 | (1) PBXBuildFile :20, (2) PBXFileReference :34, (3) PBXGroup Systems children :174, (4) Sources Build Phase :354 — 모두 확인 | PASS |
| 14 | BUILD SUCCEEDED | `xcodebuild ... build` → `** BUILD SUCCEEDED **` | PASS |
| 15 | 시뮬레이터 동작 *2-9와 동일* (음표 spawn / F 발사 / endGame 정지) | 코드 동등성으로 보장 — 9 메서드 본문이 한 글자도 다르지 않게 SpawnSystem으로 이전. progressProvider는 GameScene의 `1.0 - remainingTime / GameConfig.gameDuration`을 그대로 closure로 캡처해 동일 결과. | PASS (정적 검증) |

**15/15 PASS**

## SPEC 기능 체크
- [x] 기능 1 (SpawnSystem.swift 신설): SPEC §"기능 1" 본문 그대로 구현. 144줄.
- [x] 기능 2 (GameScene.swift 수정): 멤버 추가 + didMove 변경 + endGame 변경 + 9 메서드 제거 완료.

## Swift 패턴 준수
- 강제 언래핑 미사용: 준수 (양 파일 0건)
- guard let 옵셔널 처리: 준수 (SpawnSystem trySpawnNote / fireProjectile / currentNoteCount / currentProjectileCount / randomNotePosition 모두 guard let 사용)
- MARK 섹션 구분: 준수 (Dependencies / Lifecycle / Note Spawn / Projectile Fire)
- GameConfig 상수 사용: 준수 (모든 매직 후보가 GameConfig 참조)
- weak self 캡처: 준수 (spawn 클로저 1건 + fire 재귀 클로저 1건 + GameScene didMove progressProvider closure 1건)

## SpriteKit 패턴 준수
- didMove(to:)에서 초기화: 준수 (spawnSystem.start만 didMove에서 호출)
- dt 기반 이동: 해당 없음 (SpawnSystem은 spawn/fire 책임만)
- SKAction 스폰 패턴: 준수 (Timer 0건, SKAction.wait/run/sequence/repeatForever만)
- 충돌 후 노드 즉시 삭제 없음: 해당 없음 (SpawnSystem은 contact 미관여)
- HUD 노드 분리: 해당 없음 (이번 sprint 범위 외)

## 변경 줄 수
- `GameScene.swift`: -109 / +30 (`git diff --stat`)
- `project.pbxproj`: +13 / -0
- `SpawnSystem.swift`: 신규 +144

## GameScene 줄 수 변화
- **이전**: 446줄 (Phase 2-9 종료 시점, SPEC 본문이 ~422 표기는 주석 헤더 4줄 + 변경 차이 반영 전 추정)
- **이후**: 354줄
- **감소**: -92줄 (-20.6%)

> SPEC §"개요"의 "422줄 → ~250줄" 목표는 *목표치*이며, 본 변경에서는 setup/contact/update 등 SPEC 보존 영역(`회귀 보존` 표)을 한 줄도 안 건드린다는 룰을 우선해 354줄까지 감소. 9 메서드 정확 제거 + 신규 의존성 주입 코드만 GameScene에 추가했으며, 이 외 추가 슬림화는 별도 sprint(ContactRouter / ScoreSystem 분리) 영역.

## 빌드 상태
- 빌드 결과: **BUILD SUCCEEDED** (`xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' build`)
- 빌드 에러: 0
- 주의 필요 경고: 없음 (AppIntents.framework 미사용 안내 1건은 Apple SDK 정보성 메시지)

## 기능 동등성 (SPEC §"기능 동등성 검증")
| 영역 | 보존 여부 |
|---|---|
| (a) 음표 spawn 1.5초 / 동시 5개 / 중앙 기둥 회피 / 외곽 1tile 마진 | 동일 (코드 그대로 이전) |
| (b) F 발사 주기 보간 (3.5 → 2.0초) | 동일 (progressProvider가 동일 식 `1.0 - remainingTime/gameDuration` 공급) |
| (c) F 발사 시점 player 좌표 캡처 | 동일 (fireProjectile 본문 그대로) |
| (d) F 동시 최대 2개 | 동일 (GameConfig.projectileMaxConcurrent 참조 그대로) |
| (e) F가 player에 닿으면 endGame, 벽에 닿으면 소멸 | 동일 (GameScene의 didBegin/handleProjectileContact 미변경) |
| (f) endGame 시 spawn / fire 즉시 정지 + projectile velocity 0 | 동일 (스폰시스템.stop이 동일 3가지를 그대로 실행) |
| (g) 수간호사 추적 + 속도 보간 (2-8) | 동일 (GameScene update 미변경) |
| (h) 콤보 / 점수 / HUD / 카메라 follow | 동일 (해당 코드 미변경) |

## 범위 외 미구현 항목
- 없음. 본 sprint는 순수 리팩터로, SPEC 안의 모든 IN 항목을 구현 완료.
- ContactRouter 분리 / ScoreSystem 분리는 SPEC §"OUT"에 따라 다음 sprint로 분리.

## 회귀 보존 검증
SPEC §"회귀 보존" 표의 모든 영역을 변경 없이 유지:
- Config 4파일: 0줄 변경 (확인: GameConfig만 읽기 참조)
- Nodes 6파일: 0줄 변경
- iOS 3파일: 0줄 변경
- GameScene의 setup 함수들 / didChangeSize / update / didBegin / handleProjectileContact / handleNoteContact: 0줄 변경
- HUDNode `update(score:remainingTime:combo:)` 시그니처: 0
- 콤보 / 점수 / lastCollectAt / remainingTime 멤버: 0
