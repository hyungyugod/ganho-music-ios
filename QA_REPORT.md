# QA 검수 보고서 — Phase 9-5 캐릭터별 스킬 시스템 4종

## SPEC 기능 검증

| # | 기능 | 결과 | 근거 (파일:라인) |
|---|---|---|---|
| 1 | PlayerSkill enum 5 case + 4 computed property exhaustive | PASS | `Models/PlayerSkill.swift:16-22, 29-37, 42-50, 53-61, 65-73` — switch default 0건 |
| 2 | CharacterID.skill 5 case 분기 (default 미사용) | PASS | `Models/CharacterID.swift:54-62` |
| 3 | SkillSystem.update(dt:) — cooldown/duration 차감 | PASS | `Systems/SkillSystem.swift:58-78` — `max(0, -dt)` 안전 가드 |
| 4 | SkillSystem.tryActivate 3중 가드 (none/cooldown/oncePerGame) | PASS | `Systems/SkillSystem.swift:83-86` |
| 5 | SkillSystem.progress 4 분기 (.none=1.0 / charm used=0 / 일반=1-cd/total) | PASS | `Systems/SkillSystem.swift:113-129` |
| 6 | isDashing / isCharmActive 정확 반환 | PASS | `Systems/SkillSystem.swift:133-141` — activeSkill 비교 + durationRemaining > 0 |
| 7 | weak self / weak scene / weak player 캡처 | PASS | `Systems/SkillSystem.swift:37 (scene), 183 (player), 313 (player)`, `GameScene+Setup.swift:354` |
| 8 | SkillButtonNode 32pt + onTap 콜백 + setEnabled 알파 토글 | PASS | `Nodes/SkillButtonNode.swift:31, 21, 72-76` |
| 9 | HUDSkillSlotNode configure(skill:) + update(progress:) 4상태 | PASS | `Nodes/HUDSkillSlotNode.swift:83-98, 103-134` |
| 10 | PlayerNode.isInvulnerable: Bool = false | PASS | `Nodes/PlayerNode.swift:42` |
| 11 | ContactRouter onEnemyHit / onProjectileHitPlayer 무적 가드 2지점 | PASS | `GameScene.swift:399, 414` |
| 12 | ProjectileNode.isEnchanted / applyEnchanted / clearEnchanted | PASS | `Nodes/ProjectileNode.swift:20, 48-51, 55-58` |
| 13 | ContactRouter.onProjectileHitPlayer 시그니처 (SKNode) -> Void | PASS | `Systems/ContactRouter.swift:23, 51-67` — handleProjectileContact 공통화 |
| 14 | SpawnSystem.fireProjectile — GameScene 캐스팅 + applyEnchanted | PASS | `Systems/SpawnSystem.swift:165, 176-178` — start 시그니처 보존 |
| 15 | ScoreSystem.recordCharmedNoteHit 추가 (시그니처 보존) | PASS | `Systems/ScoreSystem.swift:46-48` |
| 16 | GameConfig MARK: - Skill 18개 상수 | PASS | `Config/GameConfig.swift:761-824` |
| 17 | breakable 파라미터 (addRectPillar/addVerticalWall, default false) | PASS | `GameScene+Setup.swift:170, 179, 191, 201-203` |
| 18 | normal 맵 분리벽 2 호출만 breakable: true | PASS | `GameScene+Setup.swift:116, 123` — 장식 기둥(125-133)은 default 유지 |
| 19 | 외곽 벽 / hard 맵 / addCheckerboardFloor — 0줄 변경 | PASS | `GameScene+Setup.swift:42-102, 215-267, 140-166` (breakable 호출 없음) |
| 20 | 카메라 follow / Player·Enemy 픽셀 아트 / DPad — 0줄 변경 | PASS | `GameScene.swift:365`, `PlayerNode.swift:124-128`, DPadNode 미접촉 |
| 21 | HUD 4슬롯 (HUDNode, layoutHUD) — 0줄 변경 | PASS | `GameScene.swift:285-291` |
| 22 | normalMap* 좌표 (Phase 9-4) — 0줄 변경 | PASS | GameConfig.swift normal 섹션 미접촉 |

## 빌드 검증

- 결과: **BUILD SUCCEEDED**
- 명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- 경고: 0건 (Swift 컴파일러 경고 출력 없음)

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## 통과 항목

- **강제 언래핑 0건** — 옵셔널 강제 언래핑 0건. 모든 옵셔널은 `guard let` / `if let` / `as?` / `??` 처리.
- **Timer / DispatchQueue 0건** — `SKAction.move`/`sequence`/`fadeAlpha`/`repeat` 사용.
- **GameConfig 매직 넘버 0건** — 60/0.26/22/120/0.4/20/1.5/4/100/0.5/0.4/0.1/32/12/2/90/0.3/0.85 모두 상수화.
- **weak 참조 3지점** — `SkillSystem.scene` (weak), `SkillButtonNode.onTap` 클로저, SkillSystem 내부 SKAction 클로저.
- **switch exhaustive (default 미사용)** — 7곳 모두 5 case 명시.
- **private(set) 캡슐화** — SkillSystem 4 상태 + SkillButtonNode.isEnabled + ProjectileNode.isEnchanted 모두 외부 read-only.
- **SpriteKit 패턴 준수** — didMove 초기화, update에서 SkillSystem 위임 2줄, didChangeSize layout 4 메서드.
- **enumerate는 발동 시 1회만** — 4지점 모두 update 안 호출 0건.
- **회귀 방지 완벽** — `addOuterWalls`/`addCentralPillar`/`addHardMap`/`addCheckerboardFloor` 모두 breakable 미전달 → default false → enumerate 대상 0.
- **3중 가드** — tryActivate가 `.none` / cooldown / oncePerGame 순으로 차단.
- **무적 가드 2지점** — `onEnemyHit` + `onProjectileHitPlayer` 일관 패턴.
- **scene 캐스팅 옵셔널 체이닝** — `(scene as? GameScene)?.skillSystem.isCharmActive ?? false` graceful fallback.

## 채점

| 항목 | 가중치 | 점수 | 코멘트 |
|---|---|---|---|
| Swift 패턴 일관성 | 35% | **10/10** | 강제 언래핑 0, 매직 넘버 0, switch default 0, MARK 섹션 정연, private(set) 일관 |
| 게임 로직 완성도 | 30% | **10/10** | dt 기반 cooldown, 3중 가드, 무적 2지점 가드, enchanted SpawnSystem/만료 양방향 처리 |
| 성능 & 안정성 | 20% | **10/10** | enumerate 발동 1회, weak 3지점, fadeOut sequence(physics-safe), 거리^2 비교 |
| 기능 완성도 | 15% | **10/10** | 5 캐릭터 분기 + 김간호 noop, HUDSkillSlot 4상태, SkillButton 비활성 |

**가중 점수 = 10.0 × 0.35 + 10.0 × 0.30 + 10.0 × 0.20 + 10.0 × 0.15 = 10.0 / 10**

## 최종 판정: **합격**

(7.0+ 기준선 대비 +3.0 여유 / P0·P1·P2 0건 / BUILD SUCCEEDED / 회귀 영역 22개 항목 모두 PASS)

## 시각적 확인 사항

각 캐릭터로 게임 시작 후 좌하단 SkillButton 1탭:

1. **김간호 (.none)** — SkillButton alpha 0.3 + 라벨 "—" + 터치 무반응. HUDSkillSlot 링 미표시 + value "—" dim.
2. **정간호 (.dashClimb)** — D-Pad 방향으로 60pt 즉시 돌진. 0.26초 무적. normal 맵 중앙 분리벽(c=23) 1칸 fadeOut. 외곽 벽/장식 기둥/easy 중앙 기둥 무파괴. 22초 후 재발동.
3. **건간호 (.bookClubRally)** — 반경 120pt 안 음표가 0.4초 easeIn으로 player에게 흡수. F는 끌려오지 않음. 20초 후 재발동.
4. **임간호 (.charmStudent)** — 게임당 1회. 발동 즉시 모든 F가 노란색→분홍 변경. 1.5초 동안 새 F도 분홍 출생. 분홍 F 접촉 시 점수 +4. HUDSkillSlot value "USED" dim 영구.
5. **이간호 (.taiwanTrip)** — 4방향 중 첫 유효 후보로 100pt 즉시 텔레포트. 0.5초 무적 + alpha 깜빡임. 22초 후 재발동.

**HUD 좌하단 슬롯**: 발동 후 ring이 progress 비율로 채워짐 (0→1). value "..."(쿨다운) → "READY"(완료) 전환.

**회귀 검증**: 좌상단 4슬롯 HUD(TIME/SCORE/COMBO/PLAYER) 변동 0. 우하단 D-Pad 변동 0. 카메라 follow 정확. 픽셀 캐릭터/걷기 애니메이션 정상.
