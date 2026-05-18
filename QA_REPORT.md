# QA 검수 보고서 — Phase 9-7 (이교수 + 청진기)

## SPEC 기능 검증

| # | 기능 | 결과 | 위치 |
|---|---|---|---|
| 1 | ProfessorNode 16×20 + physicsBody 미부착 + 4 waypoint 순찰 | PASS | `Nodes/ProfessorNode.swift:42-82` |
| 2 | startThrowingStethoscopes 시그니처 | PASS | `Nodes/ProfessorNode.swift:91-98` |
| 3 | scheduleNextThrow 재귀 SKAction + "professorThrow" key | PASS | `Nodes/ProfessorNode.swift:103-111` |
| 4 | throwStethoscope: 4가드 + 단위 벡터 × speed + max 4 가드 | PASS | `Nodes/ProfessorNode.swift:128-145` |
| 5 | stopThrowing(worldNode:) — removeAction + velocity 0 | PASS | `Nodes/ProfessorNode.swift:158-163` |
| 6 | updatePixelAnimation(deltaTime:) | PASS | `Nodes/ProfessorNode.swift:170-214` |
| 7 | StethoscopeNode 18×18 + isDynamic + allowsRotation=false | PASS | `Nodes/StethoscopeNode.swift:33-42` |
| 8 | category=stethoscope, contactTest=player\|wall, collision=0 | PASS | `Nodes/StethoscopeNode.swift:39-41` |
| 9 | SKAction.rotate repeatForever 0.5초 | PASS | `Nodes/StethoscopeNode.swift:46` |
| 10 | PlayerNode.isFrozen private(set) | PASS | `Nodes/PlayerNode.swift:48` |
| 11 | freeze(duration:) — 2중 가드 + 깜빡임 + restore | PASS | `Nodes/PlayerNode.swift:155-173` |
| 12 | update(deltaTime:) 최상단 isFrozen early return + 시그니처 보존 | PASS | `Nodes/PlayerNode.swift:129-144` |
| 13 | var professor: ProfessorNode? Optional | PASS | `GameScene.swift:67` |
| 14 | update D-Pad 가드 (!isDashing && !isFrozen) | PASS | `GameScene.swift:380-384` |
| 15 | professor?.updatePixelAnimation(deltaTime: dt) | PASS | `GameScene.swift:409` |
| 16 | 인트로 onDismiss hard 분기 → showProfessorWarningCutscene | PASS | `GameScene.swift:210-216` |
| 17 | showProfessorWarningCutscene → .countdown 전환 | PASS | `GameScene.swift:225-237` |
| 18 | configureContactRouter onStethoscopeHitPlayer/Wall 콜백 | PASS | `GameScene.swift:513-533` |
| 19 | endGame professor?.stopThrowing | PASS | `GameScene.swift:687` |
| 20 | setupProfessor — hard 가드 + waypoint[0] + weak self | PASS | `GameScene+Setup.swift:353-370` |
| 21 | didMove 호출 (setupStoneGuard 다음) | PASS | `GameScene.swift:151` |
| 22 | ContactRouter onStethoscopeHitPlayer/Wall 콜백 2개 | PASS | `Systems/ContactRouter.swift:35,38` |
| 23 | didBegin stethoscope 분기 + handleStethoscopeContact | PASS | `Systems/ContactRouter.swift:58-61, 122-136` |
| 24 | PhysicsCategory.stethoscope = 0b10000000 (128) | PASS | `Config/PhysicsCategory.swift:21` |
| 25 | PixelSprite.professorData 16×20 4방향 3프레임 | PASS | `Models/PixelSprite.swift:390-467` |
| 26 | PixelPalette.professorPalette 별도 dict | PASS | `Models/PixelPalette.swift:123-141` |
| 27 | GameConfig 3 MARK 섹션 (Professor / Stethoscope / Player Freeze) | PASS | `Config/GameConfig.swift:875, 902, 921` |
| 28 | ColorTokens 4개 신규 | PASS | `Config/ColorTokens.swift:208-217` |
| 29 | 회귀 방지 — 보호 영역 7개 0줄 변경 | PASS | git diff 검증 |
| 30 | 매직 넘버 0 / 강제 언래핑 0 / Timer 0 / weak self 5개소 | PASS | grep 검증 |
| 31 | 빌드 BUILD SUCCEEDED 경고 0 | PASS | iPhone 17 Sim Debug |

## 빌드 검증

- **결과**: **BUILD SUCCEEDED**
- **명령**: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- **경고**: 0건

## 이슈 카운트

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## 통과 항목

### Swift 패턴 (35%)
- 강제 언래핑 0건. `physicsBody?.velocity` 옵셔널 체이닝.
- guard let / if let 4건, weak self 5개소.
- MARK 섹션 완비, GameConfig 상수 16건.
- 함수 단일 책임 — ProfessorNode 메서드별 역할 분리.

### 게임 로직 (30%)
- SKAction 패턴 — scheduleNextThrow 재귀, Timer 0.
- PhysicsCategory.stethoscope=128 단독 비트.
- didBegin 즉시 제거 0 — `node.run(.removeFromParent())` SKAction.
- 무적 > 동결 > 게임오버 우선순위 — 이중 안전망 (freeze 안 + 호출부 둘 다 가드).
- GameState 흐름 — 인트로 → 이교수 경고 → 카운트다운 (hard만).

### 성능 & 안정성 (20%)
- Optional chain — easy/normal noop 자연.
- weak worldRef — 메모리 누수 0.
- removeAction 멱등 — stopThrowing 두 번 호출 안전.
- endGame 정리 — 청진기 발사 루프 + 활성 청진기 정지.
- texture 재생성 변화 순간에만 (needsRefresh 플래그).

### 기능 완성도 (15%)
- SPEC §허용 14항목 전부 / §금지 6항목 전부 미접촉.
- hard 외 등장 0 — professor=nil, 컷씬 미표시.
- freeze 재호출 noop — 2초 고정.
- 빌드 SUCCEEDED 경고 0.

## 회귀 방지 검증

| 보호 영역 | 변경 라인 |
|---|---|
| EnemyNode.swift | 0줄 |
| StoneGuardNode.swift | 0줄 |
| SpawnSystem.swift | 0줄 |
| ScoreSystem.swift | 0줄 |
| SkillSystem.swift | 0줄 |
| ToiletNode.swift | 0줄 |
| ProjectileNode.swift | 0줄 |
| HUD 노드들 | 0줄 |
| CutsceneOverlayNode | 0줄 (재사용만) |
| ToastLabelNode | 0줄 (재사용만) |

## 채점

| 항목 | 가중치 | 점수 |
|---|---|---|
| Swift 패턴 일관성 | 35% | 10/10 |
| 게임 로직 완성도 | 30% | 10/10 |
| 성능 & 안정성 | 20% | 10/10 |
| 기능 완성도 | 15% | 10/10 |

**가중 점수**: 10.0 × 0.35 + 10.0 × 0.30 + 10.0 × 0.20 + 10.0 × 0.15 = **10.0 / 10**

## 최종 판정: **합격**

## 시각적 확인 사항

1. 이교수 픽셀 아트 시각 (회색 머리 + 안경 + 콧수염 + 흰 셔츠 + 검은 바지)
2. 순찰 경로 (320,200) → (640,200) → (640,280) → (320,280) 시계방향 11.4초 1바퀴
3. 청진기 회전 0.5초 1회전 톤 적정성
4. freeze 깜빡임 alpha 1.0 ↔ 0.4 2초 동안 5회 톤
5. 인트로 → 이교수 경고 → 카운트다운 3단계 흐름
6. 무적 + freeze 충돌 — 정간호 돌진/이간호 텔레포트 중 청진기 명중 freeze 0초
7. endGame 후 청진기 추가 발사 0
