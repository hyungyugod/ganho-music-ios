# QA 검수 보고서 — Phase 9-6 변기 보너스 시스템

## SPEC 기능 검증

| # | 기능 | 결과 | 파일:라인 |
|---|---|---|---|
| 1 | ToiletNode 16×16 + bonus 카테고리 + 8s lifetime SKAction | PASS | `Nodes/ToiletNode.swift:18-60` |
| 2 | applyLifetime — wait→fadeOut→removeFromParent sequence withKey | PASS | `Nodes/ToiletNode.swift:54-59` |
| 3 | PixelSpriteRenderer + toiletData() + toiletPalette 사용 | PASS | `Nodes/ToiletNode.swift:26-29`, `Models/PixelSprite.swift:364-388`, `Models/PixelPalette.swift:116-120` |
| 4 | ToastLabelNode SelfDismissingNode 채택 + private init + 정적 spawn 팩토리 | PASS | `Nodes/ToastLabelNode.swift:21,31,52` |
| 5 | ToastLabelNode animate — moveBy/fadeOut/scale group + removeFromParent | PASS | `Nodes/ToastLabelNode.swift:66-76` |
| 6 | ToastLabelNode setScale + 모든 수치 GameConfig 경유 | PASS | `Nodes/ToastLabelNode.swift:38,67-73,82-85` |
| 7 | SpawnSystem.start 끝에 startToiletSpawnLoop 1줄 | PASS | `Systems/SpawnSystem.swift:68` |
| 8 | SpawnSystem.stop에 removeAction(forKey:"spawnToilets") 1줄 | PASS | `Systems/SpawnSystem.swift:75` |
| 9 | SpawnSystem 4개 신규 메서드 | PASS | `Systems/SpawnSystem.swift:204-248` |
| 10 | 단일성 가드 *확률 판정 앞* 위치 | PASS | `Systems/SpawnSystem.swift:218-219` |
| 11 | Bernoulli 단일 시도(CGFloat.random < 0.15) | PASS | `Systems/SpawnSystem.swift:219` |
| 12 | ContactRouter.onToiletCollected: (SKNode) -> Void 콜백 | PASS | `Systems/ContactRouter.swift:31` |
| 13 | didBegin bonus 분기 + handleBonusContact | PASS | `Systems/ContactRouter.swift:51-54, 97-103` |
| 14 | 기존 4개 콜백 시그니처 0줄 변경 | PASS | `Systems/ContactRouter.swift:17-27` |
| 15 | ScoreSystem.recordToiletBonus — recordNoteHit 2회 호출 | PASS | `Systems/ScoreSystem.swift:57-60` |
| 16 | PhysicsCategory.bonus = 0b1000000 — 기존 6비트 충돌 없음 | PASS | `Config/PhysicsCategory.swift:20` |
| 17 | PlayerNode.contactTestBitMask에 .bonus OR | PASS | `Nodes/PlayerNode.swift:89` |
| 18 | PixelSprite.toiletData() + PixelPalette.toiletPalette | PASS | `Models/PixelSprite.swift:354-388`, `Models/PixelPalette.swift:109-121` |
| 19 | ColorTokens 3개 (ganhoToiletBowl/Seat/Accent) | PASS | `Config/ColorTokens.swift:187-198` |
| 20 | GameConfig MARK 섹션 2개 | PASS | `Config/GameConfig.swift:826,853` |
| 21 | GameScene.configureContactRouter — onToiletCollected 본문 | PASS | `GameScene.swift:474-522` |
| 22 | 콜백 — recordToiletBonus + medium 햅틱 + noteCollected 사운드 + Sparkle + Toast + ScorePopup×2 fan-out + 마일스톤 가드 + toilet.run(.removeFromParent()) | PASS | `GameScene.swift:478-521` |
| 23 | 즉시 removeFromParent 금지 (SKAction 패턴) | PASS | `GameScene.swift:521` |
| 24 | weak self 캡처 — SKAction.run / onToiletCollected | PASS | `Systems/SpawnSystem.swift:206`, `GameScene.swift:474` |

### 회귀 방지

| 영역 | 결과 |
|---|---|
| Phase 9-5 SkillSystem/HUDSkillSlot/SkillButton/PlayerSkill | PASS |
| Phase 9-4 normalMap/체크보드 | PASS |
| HUD 4슬롯 (HUDNode/layoutHUD) | PASS |
| DPad / 카메라 follow | PASS |
| SpawnSystem 기존 시그니처 | PASS (*추가만*) |
| ContactRouter 기존 콜백 4개 | PASS |

## 빌드 검증

- 결과: **BUILD SUCCEEDED**
- 명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- 경고: 신규 코드 0건

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## 통과 항목

- **강제 언래핑 0건** — guard let / ?? 패턴.
- **Timer/DispatchQueue 0건** — 신규 코드는 모두 SKAction.repeatForever.
- **매직 넘버 0건** — 신규 파일 리터럴 grep 0건. GameConfig 단일 진실 원천.
- **MARK 섹션 일관성** — Properties/Init/Spawn/Animate/Configure 분할.
- **SelfDismissingNode 채택** — ToastLabelNode 자가 소멸 노드 패턴.
- **PhysicsCategory 비트 분리** — bonus=64, 기존 6개와 겹침 0.
- **단일성 가드 *확률 앞*** — 놓친 기회 0 / 체감 확률 정확.
- **ScoreSystem 응축 패턴** — recordToiletBonus가 단일 진입점 2회 호출, 직접 score/combo set 0건.
- **즉시 removeFromParent 회피** — `toilet.run(.removeFromParent())` SKAction 패턴.
- **weak self 일관** — SKAction.run/콜백 모두 [weak self].
- **PixelSpriteRenderer 재사용** — Phase 8-1 인프라 정확 답습.
- **노드 트리 부착** — ToiletNode → worldNode z=4, ToastLabelNode → worldNode z=50.

## 항목별 점수

| 항목 | 가중치 | 점수 | 코멘트 |
|---|---|---|---|
| Swift 패턴 일관성 | 35% | 10/10 | guard let / weak self / MARK / GameConfig 100% / private init 팩토리 / 강제 언래핑 0 |
| 게임 로직 완성도 | 30% | 10/10 | SKAction repeatForever / Bernoulli 단일 시도 / 단일성 가드 확률 앞 / ContactRouter 분기 결정성 / ScoreSystem 단일 진입점 응축 |
| 성능 & 안정성 | 20% | 10/10 | SKAction removeFromParent / static physicsBody / BUILD SUCCEEDED / 신규 경고 0 |
| 기능 완성도 | 15% | 10/10 | GDD §7-3 표 1:1 — 24개 항목 전수 PASS |

## 가중 평균

(10 × 0.35) + (10 × 0.30) + (10 × 0.20) + (10 × 0.15) = **10.0 / 10**

## 최종 판정: **합격**

## 시각적 확인 사항

1. **변기 픽셀 외형**: 16×16 (상단 4행 padding 포함 16×20 텍스처 vertical squish 0.8배).
2. **첫 12초 변기 0개**: SKAction.sequence([wait(12), roll]) — 의도된 톤.
3. **fadeOut 도중 수집**: lifetime fadeOut 0.3s 진행 중 player 접촉 시 toilet 안전 제거.
4. **콤보 2증가 마일스톤 건너뜀**: combo 2→4 점프 시 milestone 3 멱등 Set 미통과로 발화 안 함.
5. **fan-out ±8pt ScorePopup 겹침**: 텍스트 겹침 확인.
