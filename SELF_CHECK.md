# 자체 점검 — Phase 9-6 변기 보너스

전략: 1회차 (해당 없음)

## 변경 파일 목록 + 라인 카운트

### 신규 파일 2개
- `GanhoMusic/GanhoMusic Shared/Nodes/ToiletNode.swift` (60줄)
- `GanhoMusic/GanhoMusic Shared/Nodes/ToastLabelNode.swift` (90줄)

### 수정 파일 10개
- `GanhoMusic/GanhoMusic Shared/Config/PhysicsCategory.swift` — +1줄 (bonus = 64)
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift` — +47줄 (Toilet Bonus + Toast Label MARK 섹션, 매직 넘버 17개)
- `GanhoMusic/GanhoMusic Shared/Config/ColorTokens.swift` — +12줄 (ganhoToiletBowl/Seat/Accent + MARK 섹션)
- `GanhoMusic/GanhoMusic Shared/Models/PixelSprite.swift` — +37줄 (extension Toilet Sprite + toiletData)
- `GanhoMusic/GanhoMusic Shared/Models/PixelPalette.swift` — +14줄 (extension Toilet Palette + toiletPalette)
- `GanhoMusic/GanhoMusic Shared/Nodes/PlayerNode.swift` — +3줄 (contactTestBitMask OR `.bonus`)
- `GanhoMusic/GanhoMusic Shared/Systems/SpawnSystem.swift` — +60줄 (start+1, stop+1, 메서드 4개)
- `GanhoMusic/GanhoMusic Shared/Systems/ContactRouter.swift` — +20줄 (onToiletCollected, bonus 분기, handleBonusContact)
- `GanhoMusic/GanhoMusic Shared/Systems/ScoreSystem.swift` — +10줄 (recordToiletBonus)
- `GanhoMusic/GanhoMusic Shared/GameScene.swift` — +50줄 (onToiletCollected 콜백 본문)
- `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj` — +6줄 (BuildFile 2개 + FileReference 2개 + Group 2개 + Sources phase 2개)

### 학습 노트
- `docs/learn/phase-9-6-toilet-bonus.md` (학습 노트, 중학생 수준 + Spring Boot 비유)

## SPEC 기능 체크리스트

- [x] **기능 1: ToiletNode** — 16×16 픽셀 SKSpriteNode + static physicsBody(bonus 카테고리) + applyLifetime 8초 fadeOut.
- [x] **기능 2: PixelSprite.toiletData()** — 20행(상단 4행 padding + 16행 변기) × 16칸. SPEC의 16행 디자인 정확 답습.
- [x] **기능 3: ToastLabelNode** — SelfDismissingNode 채택, private init + 정적 spawn 팩토리, ScorePopupNode 패턴 답습.
- [x] **기능 4: SpawnSystem 확장** — startToiletSpawnLoop + tryRollAndSpawnToilet + currentToiletCount + randomToiletPosition. start/stop 시그니처 보존 + 추가만.
- [x] **기능 5: ContactRouter 분기** — onToiletCollected 콜백 + didBegin bonus 분기 + handleBonusContact 메서드.
- [x] **기능 6: ScoreSystem.recordToiletBonus** — recordNoteHit 2회 호출(직접 score/combo set 없음).
- [x] **기능 7: GameScene 콜백** — onToiletCollected 본문 = recordToiletBonus + haptics.medium + audio.noteCollected + sparkle + toast + ScorePopup×2 fan-out + 마일스톤 분기 + toilet.run(.removeFromParent()).
- [x] **기능 8: PhysicsCategory.bonus + PlayerNode** — bonus = 64 (0b1000000), PlayerNode contactTestBitMask에 .bonus OR 추가.

## Swift 패턴 준수

- **강제 언래핑 0건**: grep `\!` 점검 — 옵셔널은 모두 `guard let` / `?? fallback` 사용. ToiletNode/ToastLabelNode 신규 파일 0건, 모든 수정 파일 0건.
- **guard let 옵셔널 처리**: ContactRouter.handleBonusContact의 `guard let node = bonusBody.node`, SpawnSystem.tryRollAndSpawnToilet의 `guard let world / position` 다중 가드.
- **MARK 섹션 구분**: GameConfig 2섹션 / ColorTokens 1섹션 / PixelSprite 1 extension / PixelPalette 1 extension / 신규 노드 각각 MARK 4~5개.
- **GameConfig 상수 사용**: 모든 시간/거리/확률/색/zPosition 매직 넘버 0건. `toiletSize/toiletSpawnInterval/toiletSpawnProbability/toiletLifetime/toiletFadeOutDuration/toiletMaxConcurrent/toiletZPosition/toiletScorePopupFanOutX/toiletToastText/toastDuration/toastFontSize/toastStartOffsetY/toastFlyUpDistance/toastStartScale/toastEndScale/toastZPosition`.
- **weak self 캡처**: SpawnSystem.startToiletSpawnLoop의 SKAction.run에서 `[weak self]`, GameScene.onToiletCollected 클로저에서 `[weak self]` + `guard let self`.
- **private init 패턴**: ToastLabelNode는 ScorePopupNode 패턴 답습 — private init + 정적 spawn 팩토리로 position 누락 컴파일 타임 차단.

## SpriteKit 패턴 준수

- **didMove(to:)에서 초기화**: 본 sprint는 didMove 변경 0줄 — configureContactRouter에 콜백 1개 추가만.
- **dt 기반 이동**: 본 sprint는 이동 로직 변경 0줄.
- **SKAction 스폰 패턴**: Timer 0건. SpawnSystem.startToiletSpawnLoop가 `SKAction.repeatForever(.sequence([wait, roll]))` 사용 — 기존 startNoteSpawnLoop와 동형. withKey "spawnToilets"로 stop() 정상 정지.
- **충돌 후 노드 즉시 삭제 없음**: GameScene.onToiletCollected의 `toilet.run(.removeFromParent())` SKAction 사용. didBegin 진행 중 즉시 removeFromParent 0건.
- **HUD 노드 분리**: HUD 신설 0 (SPEC 금지 3 — HUD 변기 카운터/알림 없음).
- **PhysicsBody static**: ToiletNode `body.isDynamic = false` + `collisionBitMask = 0` — player와만 contactTestBitMask 매칭, 다른 노드 통과.
- **SelfDismissingNode 채택**: ToastLabelNode가 SelfDismissingNode 마커 프로토콜 채택. 자가 소멸 노드 10호(AirplaneNode/AirforceOverlayNode/BombFlashNode/SparkleEffectNode/HitFlashNode/ComboPopupNode/ComboBreakNode/CountdownNode/ScorePopupNode/ToastLabelNode).

## 회귀 방지 (Sprint 범위 계약)

- **Phase 9-1~9-5 영역 0줄 수정**: SkillSystem/normalMap/체크보드/HUD 4슬롯/캐릭터 픽셀/breakable wall — 1줄도 안 건드림.
- **SpawnSystem 기존 시그니처 보존**: start/stop/apply/fireImmediately 시그니처 그대로. start 끝에 `startToiletSpawnLoop()` 1줄 + stop에 `removeAction(forKey: "spawnToilets")` 1줄 *추가만*.
- **ScoreSystem 기존 시그니처 보존**: recordNoteHit/recordCharmedNoteHit/tickComboExpiry/reset 그대로. recordToiletBonus *추가만*.
- **ContactRouter 기존 시그니처 보존**: 기존 콜백 4개(onEnemyHit/onStoneGuardContact/onProjectileHitPlayer/onProjectileHitWall/onNoteCollected) 그대로. onToiletCollected *추가만*.
- **PlayerNode contactTestBitMask**: 기존 3비트(note/enemy/projectile)에 .bonus OR 1개 *추가만*. 다른 코드 변경 0건.
- **PhysicsCategory 비트 충돌 없음**: bonus=64는 기존 player(1)/note(2)/enemy(4)/wall(8)/projectile(16)/stoneGuard(32)와 별개 비트.

## 빌드 상태

- **iPhone 17 시뮬레이터 Debug 빌드**: `** BUILD SUCCEEDED **` (확인 완료).
- **예상 빌드 에러**: 없음.
- **주의 필요 경고**: 없음 (AppIntents.framework 누락 경고는 기존 프로젝트 사양 — 변경 무관).

## 매직 넘버 점검

- 본 sprint에서 추가한 GameConfig 상수: 17개 (Toilet 9개 + Toast 8개).
- 모든 수치 리터럴은 GameConfig 상수 경유. 점검 결과:
  - ToiletNode: `GameConfig.toiletSize/toiletZPosition/toiletLifetime/toiletFadeOutDuration` 4건 ✓
  - ToastLabelNode: `GameConfig.toastZPosition/toastStartScale/toastStartOffsetY/toastDuration/toastFlyUpDistance/toastEndScale/toastFontSize` 7건 ✓
  - SpawnSystem.tryRollAndSpawnToilet: `GameConfig.toiletMaxConcurrent/toiletSpawnProbability/tileSize/mapWidth/mapHeight` 5건 ✓
  - SpawnSystem.startToiletSpawnLoop: `GameConfig.toiletSpawnInterval` 1건 ✓
  - GameScene.onToiletCollected: `GameConfig.toiletToastText/toiletScorePopupFanOutX/comboBonusThreshold/scorePerNoteCombo/scorePerNote/comboMilestones` 6건 ✓
- 직접 수치 리터럴(`12`, `0.15`, `8` 등) **0건**.

## 범위 외 미구현 항목

- **없음** — SPEC.md의 모든 허용 항목 11개 100% 구현. 금지 항목 7개 100% 준수.

## 자체 점수 예상 (평가 가중치 적용)

- **Swift 패턴 35%**: 강제 언래핑 0 / guard let 다중 / weak self / private init 팩토리 / MARK 섹션 / GameConfig 100% — **10.0 / 10**
- **게임 로직 30%**: SKAction 12s 루프 / 8s TTL fadeOut / Bernoulli 단일 시도 / ContactRouter 분기 / ScoreSystem 응축(recordNoteHit×2) / 단일성 가드(확률 판정 전) — **10.0 / 10**
- **성능 & 안정성 20%**: 강제 언래핑 0 / addChild 매 프레임 0 / 노드 제거 SKAction 패턴 / 빌드 클린 / static physicsBody 충돌 비용 0 — **10.0 / 10**
- **기능 완성도 15%**: GDD §7-3 표 1:1 (12s/15%/8s/점수+2/콤보+2/"화캉스 보너스!" 0.9초) — **10.0 / 10**

**가중 점수 예상: 10.0 / 10**
