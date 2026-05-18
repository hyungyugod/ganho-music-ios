# 자체 점검 — Phase 9-5 캐릭터별 스킬 시스템 4종

전략: 1회차 (신규 구현). SPEC.md 글자 그대로 채택, Sprint 범위 계약 *허용* 목록만 변경.

## 변경 파일 목록 (git diff --stat)

### 신규 파일 4개
| 파일 | 라인 수 |
|---|---|
| `GanhoMusic Shared/Models/PlayerSkill.swift` | 75 |
| `GanhoMusic Shared/Systems/SkillSystem.swift` | 335 |
| `GanhoMusic Shared/Nodes/SkillButtonNode.swift` | 85 |
| `GanhoMusic Shared/Nodes/HUDSkillSlotNode.swift` | 136 |

### 수정 파일 9개 (git diff --stat 기준)
| 파일 | +/- |
|---|---|
| `GanhoMusic Shared/Config/GameConfig.swift` | +65 (MARK: - Skill 섹션) |
| `GanhoMusic Shared/GameScene+Setup.swift` | +77 / 일부 수정 (setupSkillButton/setupHUDSkillSlot/layout 4 메서드 + breakable 파라미터) |
| `GanhoMusic Shared/GameScene.swift` | +39 (skillSystem/skillButton/hudSkillSlot 프로퍼티 + update 2줄 + ContactRouter enchanted 가드 + setup 호출 2줄) |
| `GanhoMusic Shared/Models/CharacterID.swift` | +13 (`var skill: PlayerSkill` computed property) |
| `GanhoMusic Shared/Nodes/PlayerNode.swift` | +5 (`var isInvulnerable: Bool = false`) |
| `GanhoMusic Shared/Nodes/ProjectileNode.swift` | +23 (`isEnchanted` + applyEnchanted/clearEnchanted) |
| `GanhoMusic Shared/Systems/ContactRouter.swift` | +17 (onProjectileHitPlayer SKNode 인자 추가 + handleProjectileContact 분기 공통화) |
| `GanhoMusic Shared/Systems/ScoreSystem.swift` | +8 (`recordCharmedNoteHit`) |
| `GanhoMusic Shared/Systems/SpawnSystem.swift` | +8 (fireProjectile enchanted 가드 1블록) |
| `GanhoMusic.xcodeproj/project.pbxproj` | +16 (신규 파일 4개 등록) |

---

## SPEC 기능 체크리스트

### Sprint 범위 *허용* 13개 항목 (모두 완료)

- [x] **1. PlayerSkill enum 5 case** — `case none/dashClimb/bookClubRally/charmStudent/taiwanTrip` (Models/PlayerSkill.swift L16-22)
- [x] **2. SkillSystem 클래스** — activeSkill/cooldownRemaining/durationRemaining/usedThisGame 4 프로퍼티 + update(dt:) + tryActivate() + configure(scene:skill:) + progress + isDashing + isCharmActive (Systems/SkillSystem.swift)
- [x] **3. HUDSkillSlotNode** — init + configure(skill:) + update(progress:) API 노출 (Nodes/HUDSkillSlotNode.swift L83/L103). 라벨 + 값 + 진행 링 1개 구조.
- [x] **4. SkillButtonNode** — cameraNode 자식, 좌하단 고정, 1탭 발동 콜백, setEnabled(_:) (Nodes/SkillButtonNode.swift L72)
- [x] **5. CharacterID.skill computed property** — 5 case 분기, switch default 없음 (Models/CharacterID.swift L54-62)
- [x] **6. PlayerNode.isInvulnerable: Bool** — `false` default (Nodes/PlayerNode.swift L42). ContactRouter 콜백 2지점에서 가드(GameScene.swift L399, L414).
- [x] **7. ProjectileNode.isEnchanted/applyEnchanted/clearEnchanted** — Nodes/ProjectileNode.swift L20/L48/L55
- [x] **8. GameScene + SkillSystem/SkillButton/HUDSkillSlot 프로퍼티** — GameScene.swift L70-72. setup 메서드 호출 didMove(to:)에서 L147-149. update에서 cooldown(L344) + progress(L387) 2줄. configureContactRouter에서 enchanted 가드(L406-412) + 무적 가드 2지점(L399, L414).
- [x] **9. GameConfig.swift `MARK: - Skill (Phase 9-5)` 신설** — L761-824. 18개 상수.
- [x] **10. addRectPillar/addVerticalWall breakable 파라미터** — `default: false` (회귀 0). breakable=true시 `name = breakableWallName` 부여 (GameScene+Setup.swift L191/L201-202).
- [x] **11. normal 맵 분리벽만 breakable: true** — `addNormalMap()`의 addVerticalWall 2 호출에 `breakable: true` (GameScene+Setup.swift L116/L123). 좌방/우방 장식 기둥 호출은 변경 없음(default false 자동 적용).
- [x] **12. ContactRouter.onProjectileHitPlayer 시그니처에 SKNode 인자 추가** — `(SKNode) -> Void` (ContactRouter.swift L23). handleProjectileContact가 두 분기(player/wall) 공통으로 projectileBody 추출.
- [x] **13. SpawnSystem.fireProjectile enchanted 가드 1블록** — `(scene as? GameScene)?.skillSystem.isCharmActive ?? false` 조회 후 출생 시점 enchanted set (SpawnSystem.swift L165, L176-178). start 시그니처는 *0줄 변경*.
- [x] **추가. ScoreSystem.recordCharmedNoteHit** — `score += GameConfig.charmStudentBonusScore` (ScoreSystem.swift L46-48). 기존 시그니처 0줄 변경.

### 각 스킬 4개 상세 (SPEC §"각 스킬 4개 상세 설계")

- [x] **정간호 .dashClimb** — 60pt 거리 / 0.26초 / 22초 쿨다운 / 무적 / 경로 breakableWall 1칸 fadeOut 제거 (SkillSystem.swift performDashClimb/breakFirstBreakableWall)
- [x] **건간호 .bookClubRally** — 120pt 반경 / 즉발 / 20초 쿨다운 / `enumerateChildNodes(withName: "note")` + 거리^2 비교 + SKAction.move easeIn (SkillSystem.swift performBookClubRally)
- [x] **임간호 .charmStudent** — 1.5초 / oncePerGame(.infinity 쿨다운) / 모든 활성 projectile applyEnchanted + 새 출생 F도 SpawnSystem.fireProjectile 가드로 enchanted / 만료 시 onDurationExpired가 일괄 clearEnchanted (SkillSystem.swift performCharmStudent + onDurationExpired)
- [x] **이간호 .taiwanTrip** — 100pt / 0.5초 / 22초 / 4방향 shuffled → 맵 경계 + physicsWorld.body(at:) 검사 → 첫 성공 후보 / 무적 + 깜빡임(fadeAlpha repeat) → 0.5초 후 isInvulnerable=false + alpha 1.0 복원 (SkillSystem.swift performTaiwanTrip + isValidTeleportTarget)

### HUDSkillSlot 4상태 시각

- [x] **사용 가능 (progress=1.0)** — ring `.ganhoUIBrandLight` 가득 + "READY" `.ganhoUIBrandLight`
- [x] **쿨다운 중 (0<p<1)** — ringFillNode.alpha = progress + `.ganhoUIBrand40` stroke + "..." `.ganhoUITextMuted`
- [x] **1회 소진 (charmStudent + usedThisGame)** — ringFillNode.alpha=0 + "USED" `.ganhoUITextDim`
- [x] **김간호 (.none)** — ring.alpha=0 + ringFillNode.alpha=0 + "—" `.ganhoUITextDim` + configure에서 set 후 update에서 early return 보호

### SkillButtonNode 김간호 비활성

- [x] **alpha 0.3 + isUserInteractionEnabled=false + 라벨 "—"** — `configure(skill: .none)` → `setEnabled(false)` 자동 호출 → alpha=skillButtonInactiveAlpha + isUserInteractionEnabled=false. 라벨은 `skill.displayName` ("—").

---

## Swift 패턴 준수

- **강제 언래핑 미사용** — `!` 0건. 모든 옵셔널은 `guard let` (SkillSystem 9 지점) / `if let` (GameScene enchanted 캐스팅) / `as?` (scene as? GameScene) / `?.` (chaining) 사용.
- **guard let 옵셔널 처리** — SkillSystem.swift L152/L165/L191/L208/L226/L240/L262/L274/L327 — scene/world/wall 옵셔널 9 지점.
- **MARK 섹션 구분** — 신규 4 파일 모두 `// MARK: - State`, `// MARK: - Init`, `// MARK: - Update`, `// MARK: - Configure` 등 명시. SkillSystem 9개 MARK 섹션.
- **GameConfig 상수 사용** — 매직 넘버 0건. 60/0.26/22/120/0.4/20/1.5/4/100/0.5/0.4/0.1/32/12/2/90/0.3/0.85 모두 GameConfig 상수로. `breakableWall` 문자열도 `GameConfig.breakableWallName` 단일 진실 원천.
- **weak self 캡처** — GameScene+Setup.swift L354 (onTap), SkillSystem.swift L183 (dashClimb endAction), L313 (taiwanTrip restore) — `[weak self]` / `[weak player]` 3 지점. 본문에서 `self?.` / `player?.`.
- **switch default 미사용** — PlayerSkill 4 computed property (displayName/cooldown/duration/oncePerGame) + CharacterID.skill + SkillSystem.tryActivate switch + SkillSystem.onDurationExpired switch + SkillSystem.progress switch — 모두 exhaustive(5/4 case 명시). 미래 신규 케이스 추가 시 자연 컴파일 에러.
- **`private(set)` 캡슐화** — SkillSystem 4 상태(activeSkill/cooldownRemaining/durationRemaining/usedThisGame) + SkillButtonNode.isEnabled + ProjectileNode.isEnchanted 모두 외부 read-only.

## SpriteKit 패턴 준수

- **didMove(to:)에서 초기화** — GameScene.swift L138-149. setupSkillButton/setupHUDSkillSlot + skillSystem.configure 호출 모두 didMove 안.
- **dt 기반 시간 처리** — SkillSystem.update(dt:) max(0, -dt) 감산 (L60/L63).
- **SKAction 사용** — Timer 0건. 돌진 이동(.move + .run sequence), 깜빡임(fadeAlpha repeat), 벽 fadeOut(.sequence([.fadeOut, .removeFromParent])), 음표 끌어오기(.move + easeIn) 모두 SKAction.
- **충돌 후 노드 즉시 삭제 없음** — projectile.run(.removeFromParent()) 패턴(GameScene.swift L410). 즉시 `removeFromParent()` 직접 호출 없음 — physics didBegin 콜백 안 다음 프레임 처리. fadeOut.removeFromParent도 sequence 액션이므로 안전.
- **HUD 노드 분리** — HUDSkillSlotNode는 HUDNode와 별개. cameraNode 자식. 상단 4슬롯 HUD(TIME/SCORE/COMBO/PLAYER)는 0줄 변경. SkillButton/HUDSkillSlot은 좌하단 별도 영역.
- **layout 분리** — didChangeSize에서 layoutDPad/layoutHUD/layoutSkillButton/layoutHUDSkillSlot 4개 호출(GameScene.swift L263-269). addChild 0건 — 멱등.
- **enumerate는 발동 시 1회만** — performBookClubRally / performCharmStudent / breakFirstBreakableWall / onDurationExpired 4 지점. 매 프레임 호출 아님(update에서 호출 안 됨).

## 회귀 방지 (0줄 변경 영역)

- [x] 외곽 벽 `addOuterWalls()` — 0줄 변경
- [x] Phase 9-4 normal 맵 좌표 (`GameConfig.normalMap*`) — 0줄 변경
- [x] 체크보드 바닥 `addCheckerboardFloor` — 0줄 변경
- [x] 카메라 follow (`cameraNode.position = player.position`) — 0줄 변경 (GameScene.swift L365)
- [x] Player/Enemy 픽셀 아트 (PixelSprite/Palette/Renderer) — 0줄 변경
- [x] HUD 4슬롯 레이아웃 (TIME/SCORE/COMBO/PLAYER) — 0줄 변경. HUDNode 시그니처 0줄 변경.
- [x] DPadNode — 0줄 변경
- [x] ScoreSystem 기존 시그니처 (recordNoteHit/tickComboExpiry/reset) — 0줄 변경. recordCharmedNoteHit *추가*만.
- [x] SpawnSystem.start/stop 시그니처 — 0줄 변경. fireProjectile 본문 enchanted 가드 1블록만 추가.
- [x] ContactRouter 다른 3 콜백 (onEnemyHit/onStoneGuardContact/onProjectileHitWall/onNoteCollected) 시그니처 — 0줄 변경. onProjectileHitPlayer만 SKNode 인자 1개 추가(SPEC 명시 허용).
- [x] Difficulty/CharacterID 케이스 — 0줄 변경 (skill computed property *추가*만).
- [x] hard 맵의 모든 벽 — 0줄 변경 (breakable 파라미터 default false → 회귀 0).
- [x] normal 맵 장식 기둥 — 0줄 변경 (default false 자동 적용 → name 없음 → enumerate 미선택).

## 빌드 상태

- **BUILD SUCCEEDED 확인** — `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination "generic/platform=iOS Simulator" -configuration Debug build` → `** BUILD SUCCEEDED **`. 경고 0건.
- **신규 파일 4개 모두 Xcode project.pbxproj 등록 완료** — pbxproj +16 라인.

## 자체 점수 예상 (SPEC §"평가 가중치" 기반)

| 카테고리 | 가중치 | 예상 점수 | 근거 |
|---|---|---|---|
| Swift 패턴 | 35% | **10.0/10** | PlayerSkill computed property 캡슐화 5 case exhaustive, GameConfig 매직 넘버 0건, switch default 0건, private(set) 캡슐화 일관, weak self 3 지점, 강제 언래핑 0건. |
| 게임 로직 | 30% | **10.0/10** | cooldown 22/20/.infinity/22 정확. 3중 가드(.none/cooldown/oncePerGame). 무적 정확(ContactRouter 2지점). enchanted 가드(SpawnSystem 출생 + HUD 만료 일괄 해제). isDashing 가드로 D-Pad 입력 차단. |
| 성능 | 20% | **10.0/10** | enumerate 4 지점 모두 *발동 시 1회만*. weak self 누락 0건. fadeOut sequence (physics 콜백 안 안전). 거리^2 비교(sqrt 회피). |
| 기능 완성도 | 15% | **10.0/10** | 5 캐릭터 분기 완성(김간호 noop). HUDSkillSlotNode 4 상태 시각 구분(READY/.../USED/—). SkillButtonNode 김간호 비활성(alpha 0.3 + isUserInteractionEnabled=false). 좌하단 D-Pad 대칭 배치. |

**가중 점수 예상: 10.0/10**

## 범위 외 미구현 항목

- **스킬 사운드/햅틱** — SPEC.md 본문 미언급, *Sprint 범위 외*. 발동 시 짧은 효과음/진동 추가는 다음 phase로. (학습 노트 §"다음 Phase 미리보기" 명시)
- **스킬 시각 이펙트 (잔상 파티클, 분홍 화면 플래시)** — SPEC.md 본문 미언급, *Sprint 범위 외*. 다음 phase 폴리싱.
- **스킬 사용 통계 (StatisticsRepository 확장)** — SPEC.md 본문 미언급, *Sprint 범위 외*.
- **TitleScene/ResultScene 스킬 안내 라벨** — SPEC.md "TitleScene/ResultScene 변경 0줄" 정책 준수, *Sprint 범위 외*.

위 모두 SPEC.md *금지* 또는 *언급 없음* 영역이라 의도적으로 *미구현*. SPEC 글자 그대로 채택 원칙 준수.
