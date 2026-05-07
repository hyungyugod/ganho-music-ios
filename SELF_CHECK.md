# 자체 점검 — Phase 2-11 ContactRouter 분리

## SPEC §"준수 룰" 14개 PASS/FAIL

| # | 룰 | 결과 | 검증 |
|---|---|---|---|
| 1 | ContactRouter.swift 신설 + final class + NSObject + SKPhysicsContactDelegate | PASS | `Systems/ContactRouter.swift:13` `final class ContactRouter: NSObject, SKPhysicsContactDelegate` |
| 2 | 콜백 4개 (onEnemyHit / onProjectileHitPlayer / onProjectileHitWall / onNoteCollected) | PASS | ContactRouter.swift:17/19/21/23 — 4개 모두 존재, 기본값 `{}` 또는 `{ _ in }` |
| 3 | didBegin 분기 우선순위 enemy → projectile → note | PASS | ContactRouter.swift:26~39 — SPEC 본문과 동일 |
| 4 | handleProjectileContact / handleNoteContact 본문 — 기존 GameScene과 동등 | PASS | ContactRouter.swift:42~70 — SPEC 본문 그대로 (note 추출 + projectile 분기 로직 동일) |
| 5 | GameScene에서 SKPhysicsContactDelegate 채택 *제거* | PASS | `grep SKPhysicsContactDelegate GameScene.swift` → 0건 |
| 6 | GameScene에서 didBegin / handleProjectileContact / handleNoteContact *제거* | PASS | `grep -E "func didBegin\|func handleProjectileContact\|func handleNoteContact" GameScene.swift` → 0건 |
| 7 | configureContactRouter 신설 + didMove에서 호출 1건 | PASS | GameScene.swift:63 호출 + 289 정의 |
| 8 | physicsWorld.contactDelegate = contactRouter | PASS | GameScene.swift:64 |
| 9 | 콜백 등록 4건 + [weak self] 캡처 (3건 — onProjectileHitWall은 self 미사용) | PASS | GameScene.swift:290/293/299 = 3건 [weak self], onProjectileHitWall(296)은 node만 사용 |
| 10 | 콤보/점수 로직 onNoteCollected 안에 *기존 그대로* | PASS | GameScene.swift:299~309 — lastUpdateTime / combo / lastCollectAt / comboWindow / comboBonusThreshold / scorePerNote / scorePerNoteCombo 모두 보존, 기존 `now`/`isInWindow` 식별자 동일 |
| 11 | 매직 넘버 0건 | PASS | ContactRouter는 `!= 0` 비트마스크 비교만 (PhysicsCategory.* 사용), GameScene 신설 부분도 GameConfig.* 만 사용 |
| 12 | 강제 언래핑 / Timer / print / as! / fileprivate / DispatchQueue 0건 | PASS | grep 결과: ContactRouter.swift는 `!= 0`만 매치 (force-unwrap 아님), GameScene 신설 부분 0건. `guard let node = projectileBody.node` / `guard let node = noteBody?.node` / `guard let self = self`로 모두 안전 처리 |
| 13 | pbxproj ContactRouter 등록 4지점 | PASS | grep 4 hits: PBXBuildFile(L21), PBXFileReference(L36), Systems group child(L177), Sources build phase(L358) |
| 14 | BUILD SUCCEEDED | PASS | `xcodebuild ... build` → `** BUILD SUCCEEDED **` (iPhone 17 simulator) |

## GameScene 줄 수 변화
- **354 → 324** (30줄 감소: didBegin 본문 18줄 + handleProjectileContact 13줄 + handleNoteContact 21줄 = 52줄 제거 → configureContactRouter 22줄 추가 = 순감 30줄. 헤더에 Phase 2-11 라인 1줄 추가, 클래스 주석 1줄 변경, contactRouter 멤버 1줄 추가, didMove에 configureContactRouter 호출 1줄 추가, contactDelegate 한 줄 변경)

## Swift 패턴 준수
- 강제 언래핑 미사용: 준수 (ContactRouter `guard let node = projectileBody.node`, `guard let node = noteBody?.node` 사용)
- guard let 옵셔널 처리: 준수
- MARK 섹션 구분: 준수 (`MARK: - Callbacks`, `MARK: - SKPhysicsContactDelegate`, `MARK: - Private`, GameScene는 `MARK: - Contact Router` 신설 + `MARK: - End` 보존)
- GameConfig 상수 사용: 준수 (콤보/점수 로직 모두 GameConfig.* 만 참조)
- weak self 캡처: 준수 (3건, onProjectileHitWall은 self 미사용으로 의도적 제외 + 주석 명시)

## SpriteKit 패턴 준수
- didMove(to:)에서 초기화: 준수 (configureContactRouter 호출이 didMove 안 한 줄)
- dt 기반 이동: 해당 없음 (리팩터)
- SKAction 스폰 패턴: 해당 없음 (리팩터)
- 충돌 후 노드 즉시 삭제 없음: 준수 (`note.run(.removeFromParent())` / `node.run(.removeFromParent())` — 액션 위임)
- HUD 노드 분리: 해당 없음 (리팩터)

## 회귀 보존 확인
- Config 4 파일: 변경 0
- Nodes 6 파일: 변경 0
- Systems/SpawnSystem.swift: 변경 0
- iOS 3 파일: 변경 0
- GameScene의 setup* / didChangeSize / update / endGame: 변경 0
- HUDNode `update(score:remainingTime:combo:)` 시그니처: 변경 0
- 콤보/점수 멤버 (combo / score / lastCollectAt): 위치 / 타입 / 초기값 모두 동일

## 빌드 상태
- 예상 빌드 에러: 없음 (`** BUILD SUCCEEDED **`)
- 주의 필요 경고: 없음 (Metadata extraction skipped 경고는 AppIntents 미사용 무관 경고, 기존부터 있음)

## 범위 외 미구현 항목
- 없음. SPEC §"Sprint 범위 계약"의 IN 3개 (신설 1, 수정 1, pbxproj 1) 모두 처리, OUT 항목 (콤보/점수 분리, 다른 노드/Config/iOS 변경) 0건.
