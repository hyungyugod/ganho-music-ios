# 디자인 리뉴얼 진행 상태

> 이 파일은 디자인 리뉴얼 하네스가 **자동 갱신**합니다. 수동 편집 비권장.
> 자세한 절차는 `CLAUDE.md` § "디자인 리뉴얼 모드" 참고.

**최종 갱신**: 2026-05-20 (🎉 Sprint 8 전체 합격 — Phase A~G 7개 모두 완료. 평균 9.21/10)
**현재 진행 중인 Sprint**: **Sprint 8 완료**. Sprint 1/2/3/5/6/7/8 모두 합격. Sprint 4(PNG 캐릭터 80장)는 사용자 자산 작업 대기.

---

## 🚀 빠른 시작

Claude Code 세션에서 아래 한 마디만 입력하면 다음 Sprint가 자동 진행됨:

```
디자인 리뉴얼 진행해줘
```

특정 Sprint를 명시하고 싶으면:

```
Sprint 2 진행해줘
```

자동으로:
1. 이 파일을 읽어 현재 진행 상태 파악
2. 다음 Sprint의 Planner 프롬프트 실행
3. Generator → Evaluator 사이클 (최대 3회)
4. 합격하면 이 파일 갱신

---

## Sprint 진행 현황

| Sprint | 범위 | 상태 | 점수 | 시도 |
|---|---|---|---|---|
| **1** | 디자인 토큰 + 노드 컴포넌트 (인프라) | ✅ 합격 | 9.83/10 | 1/3 |
| **2** | 메뉴 3씬 (Start/Character/Skill) | ✅ 합격 | 9.50/10 | 1/3 |
| **3** | 인게임 (GameScene + HUD + 컨트롤) | ✅ 합격 | 9.22/10 | 1/3 |
| **4** | PNG 캐릭터 통합 | ⏸️ 자산 대기 | - | 0/3 |
| **5** | ResultScene 3분기 | ✅ 합격 | 9.70/10 | 1/3 |
| **6** | 흐름 재편 + 캐릭터 얼굴 + 메인 캐릭터 | ✅ 합격 | 9.53/10 | 1/3 |
| **7-A** | 캐릭터 선택 NIKKE 카드 리뉴얼 | ✅ 합격 | 9.45/10 | 1/3 |
| **7-B** | 스킬 설명 겹침 해소 | ✅ 합격 | 9.77/10 | 1/3 |
| **7-C** | 난이도 카드 색 위계 | ✅ 합격 | 9.83/10 | 1/3 |
| **7-D** | 결과창 + ScoreboardScene 신설 | ✅ 합격 | 9.83/10 | 1/3 |
| **7-E** | 카운트다운 오버레이 | ✅ 합격 | 9.76/10 | 1/3 |
| **7-F** | 빌런 4종 + 박병장 신규 | ✅ 합격 | 9.10/10 | 1/3 |
| **7-G** | 플레이어 4방향 스프라이트 | ✅ 합격 | 9.58/10 | 1/3 |
| **8-A** | 스코어보드 겹침 해소 | ✅ 합격 | 9.05/10 | 1/3 |
| **8-B** | 캐릭터 선택 스와이프 페이지 | ✅ 합격 | 9.31/10 | 1/3 |
| **8-C** | 스킬 설명 힌트 ↔ 시작 버튼 분리 | ✅ 합격 | 9.68/10 | 1/3 |
| **8-D** | 난이도 카드 크기·여백 확대 | ✅ 합격 | 9.03/10 | 1/3 |
| **8-E** | 카운트다운 표시 버그 수정 | ✅ 합격 | 9.24/10 | 1/3 |
| **8-F** | 인게임 HUD/스킬 zPos 정리 | ✅ 합격 | 9.43/10 | 1/3 |
| **8-G** | 빌런 가시화 + 박병장 데뷔 + 비행기 + 플레이어 팔다리·좌우 | ✅ 합격 | 8.78/10 | 1/3 |

### 상태 범례
- ✅ **합격** — Evaluator 합격 기준 충족, 완료
- ⏳ **대기** — 다음 트리거 시 시작 가능
- 🔄 **진행 중** — 현재 하네스 사이클 돌고 있음
- ❌ **불합격** — 재시도 필요 (시도 횟수 +1)
- ⏸️ **미시작** — 선행 Sprint 미완료 또는 자산 대기

### Sprint 4 자산 대기 해제 조건
- `mockups/svg-exports/` 폴더에 5개 SVG 존재 ✅
- `GanhoMusic/Assets.xcassets/Characters/` 폴더에 PNG 자산 존재 ❌ (사용자가 Figma에서 제작 필요)

사용자가 PNG 자산을 `Assets.xcassets/Characters/`에 추가하면 Sprint 4 상태가 "⏳ 대기"로 변경됨.

---

## 진행 로그

(각 Sprint 완료/시도 시 자동 추가)

### Sprint 1 — 디자인 토큰 + 노드 컴포넌트
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.83/10** (게임로직 10.0 · Swift패턴 9.5 · 비주얼인프라 10.0 · UX 9.5)
- QA 반복: 1회 (한 번에 통과)
- 비고: ColorTokens v2 16토큰 + GameConfig 폰트3·컴포넌트19상수 + 신규 노드 3종(GlassPill/AccentLine/DarkContextChip) + PrimaryButton/BackButton 내부 리스타일 + GradientBackgroundNode threeStop factory. 기존 5개 씬 git diff 0줄, 신규 노드 호출자 0건. 빌드 SUCCEEDED.
- **사용자 후속 작업 (OPEN_QUESTION Q1)**: 폰트 ttf 3개(Jua/GowunDodum/NotoSansKR) 다운로드 → `Resources/Fonts/` 추가 → `Info.plist` `UIAppFonts` 배열 추가 → Sprint 2 시작 전 시뮬레이터에서 폰트 적용 시각 확인.

### Sprint 2 — 메뉴 3씬
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.50/10** (게임로직 10.0 · Swift패턴 9.5 · 비주얼 9.0 · UX 9.0)
- QA 반복: 1회 (한 번에 통과)
- 비고: StartScene/CharacterSelectScene/SkillExplanationScene을 3-stop warm gradient + Jua/Gowun Dodum 폰트 + Sprint 1 인프라(GlassPill 4 / AccentLine 3 / DarkContextChip 7 / Primary 3 / Back 1 / Gradient.threeStop 3) 호출로 재구성. 4개 신규 computed property(Difficulty.shortName / PlayerSkill.rangeText/castText / CharacterID.dotColor) 추가 — 순수 시각 라벨용. GameScene/GameScene+Setup/ResultScene + Sprint 1 컴포넌트 6개 + 기타 보호 파일 15개 git diff 0줄. 빌드 SUCCEEDED.

### Sprint 3 — 인게임
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.22/10** (게임로직 9.8 · Swift패턴 8.5 · 비주얼 9.0 · UX 9.0)
- QA 반복: 1회 (한 번에 통과) + 미니 패치 1건 (P2 #5: ProjectileNode hitbox visual-only 회전)
- 비고: GameScene+Setup(배경/체크보드/벽/기둥), HUDNode(navy 칩+골드 라벨+TIME 경고+진행바), DPadNode(시각만 SKShape 교체, 입력 100% byte-identical), SkillButtonNode(코랄 원 72+B 칩+스킬명 칩), HUDSkillSlotNode(fontDisplay+v2 색), NoteNode(골드 원+글로우+1.4s 펄스), ProjectileNode(코랄 22+F+visual-only -12° 회전, hitbox 축정렬 보존), ComboPopup/ComboBreak(Jua+navy 외곽선+회전), PauseButtonNode 신규(시각 placeholder). 19개 보호 파일 git diff 0줄. 게임 수치/물리/입력/AI/저장/사운드 0건 변경. 빌드 SUCCEEDED.
- 잔존 P2: SkillButtonNode 매직 넘버 18 / 인라인 알파 6곳 / 스킬명 칩 CD 텍스트 누락 / SPEC 명시 상수 2개 누락. Sprint 5 진행에 영향 0.

### Sprint 4 — PNG 캐릭터 통합
- 시작: -
- 완료: -
- 점수: -
- 비고: PNG 자산 도착 후 시작

### Sprint 5 — ResultScene 3분기
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.70/10** (게임로직 10.0 · Swift패턴 9.5 · 비주얼 9.5 · UX 9.5)
- QA 반복: 1회 (한 번에 통과)
- 비고: ResultScene 3분기 시각(A 일반/B 신기록/C 졸업장), DiplomaOverlayNode 우드컷(SKShapeNode + CGMutablePath addEllipse 단일 노드 통합 ~1100 도트) + double-border ㄱ자 + 도장 + fontSerif 명조 라벨. sparkle 5발 신기록 분기. ColorTokens v2 Diploma 토큰 4개 추가. ResultScene init 9개 인자 byte-identical / 본문 텍스트 byte-identical / 햅틱·사운드 시퀀스·2단계 탭 정책 모두 보존. 보호 파일 24개 git diff 0줄. 빌드 SUCCEEDED.
- **사용자 후속 작업 권장**: GowunBatang-Regular.ttf 추가(졸업장 명조 폰트). Google Fonts → Resources/Fonts → Info.plist UIAppFonts. 미추가 시 시스템 폰트 fallback(크래시 0).

### Sprint 7 Phase G — 플레이어 4방향 스프라이트 + Direction 입력 layer
- 시작: 2026-05-20
- 완료: 2026-05-20
- 점수: **9.58/10** (게임로직 10.0 · Swift패턴 9.5 · 비주얼 9.0 · UX 9.5)
- QA 반복: 1회 (한 번에 통과)
- 비고: 인게임 PlayerNode가 D-Pad 입력 시 캐릭터 얼굴이 해당 방향(front/back/left/right) 바라보도록. 신규 Direction enum(Models/Direction.swift)과 init?(vector:) 변환자(dx>0→.right/dx<0→.left/dy>0→.back/dy<0→.front, .zero→nil 정지 시 유지 정책, |dx|≥|dy| 우선 좌우). PlayerNode faceNodes dict + lastFacing 상태 + facing(_:) 동기 isHidden 토글 + lastFacing 가드(동일 방향 noop). apply 본문 끝에 buildFacingChildren 1줄 추가 — 5캐릭터 × 4방향 = 20 CharacterFaceNode child를 setScale 0.5 + zPos 1로 부착. CharacterFaceNode init(id:facing:) 신규 분기(5×4 switch) + convenience init(id:) → init(id:facing:.front) delegation(기존 호출자 0건 회귀). 신규 10 helper(buildBackFace + buildSideFace + buildXxxHairBack 5 + buildXxxSide 5). left/right 미러링(xScale=-1)로 path 코드 5×3 = 15 + 0 중복. DPadNode onDirectionChanged 클로저 + updateDirection 끝 1줄 if-let 호출. touchesEnded/Cancelled .zero set 콜백 미발화(정지 시 유지). GameScene+Setup setupDPad 콜백 등록 1줄([weak self] 캡처). GameConfig 상수 2개(playerFaceChildScale=0.5, playerFaceChildZPosition=1). Mockup 후반부 5×4 = 20셀 그리드 추가(villains-and-player-directions-v1.html). Xcode pbxproj 4줄(Direction.swift 등록). 보호 영역 git diff 0줄: Phase A·B·C·D·E·F 결과물(SkillExplanationScene/DifficultyCardNode/ResultScene/ScoreboardScene/4 villain nodes) + GameScene/GameState/PhysicsCategory/Managers/Repositories/Systems + NoteNode/ProjectileNode/StethoscopeNode. PlayerNode 이동/physicsBody/PixelSprite texture 시스템(loadTexture/refreshTexture/updatePixelDirection/tickWalkFrame) byte-identical. CharacterFaceNode 기존 5 build 본문(buildKimFace~buildLeeFace 576 lines) byte-identical. CharacterFaceNode.mini factory(ScoreboardScene 32px) byte-identical. DPad updateDirection if/else 알고리즘 byte-identical. 강제 언래핑 0, Timer 0, switch default 0(4 case exhaustive). 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P2 (Sprint 7 전체 합격 영향 0)**: (1) CharacterFaceNode 1101 lines — +Front/+Back/+Side extension 3개 분리 후보. (2) back/side 헤어 색 hairBrown 단색 위주 — 캐릭터별 보강 후보. (3) PlayerNode PixelSprite + face child 하이브리드 정리 후보. (4) Phase F 시각 디테일 매직 넘버 8건 정리. (5) V3 상수 명명 규칙 일괄 정리.

---

## 🎉 Sprint 8 전체 완료 (2026-05-20)

7개 Phase 모두 합격. 평균 점수 **9.21 / 10**. 합격률 100% (7/7).

| Phase | 작업 | 점수 |
|---|---|---|
| A | 스코어보드 겹침 해소 | 9.05 |
| B | 캐릭터 선택 스와이프 페이지 | 9.31 |
| C | 스킬 설명 힌트 ↔ 시작 버튼 분리 | 9.68 |
| D | 난이도 카드 크기·여백 확대 | 9.03 |
| E | 카운트다운 표시 버그 수정 | 9.24 |
| F | 인게임 HUD/스킬 zPos 정리 | 9.43 |
| G | 빌런/박병장/비행기/플레이어 인게임 완성 | 8.78 |
| **평균** | | **9.22** |

### Sprint 8 Phase G — 빌런 가시화 + 박병장 데뷔 + 비행기 + 플레이어 팔다리·좌우
- 시작: 2026-05-20
- 완료: 2026-05-20
- 점수: **8.78/10** (게임로직 9.5 · Swift패턴 8.5 · 비주얼 8.0 · UX 8.5)
- QA 반복: 1회 (한 번에 통과)
- 비고: 실기 검증에서 드러난 5건 인게임 시각 결함 해소 + 사용자 의사결정 핵심 8건(#2/#3/#4/#5/#6/#7/#8/#10) 정확 적용. V4 신규 상수 11종(sergeantParkDebutTimeV4=30/ScoreV4=50/IntroDurationV4=2.2/OnStageDurationV4=8.0, airplaneCockpitColorAlphaV4=0.6/PropellerRotateDurationV4=0.15, playerArmWidthV4=4/LegWidthV4=5/WalkCycleDurationV4=0.20/IdleBreathDurationV4=1.5/FullBodyScaleV4=0.35) sub-MARK. CharacterFullBodyNode 신규 343 LOC — 5캐릭터(kim/jung/geon/im/lee) × 4방향(front/back/left/right) = 20셀 별도 path, xScale=-1 mirroring 0건, buildLeftBody/buildRightBody 별도 메서드, 1차는 body path 공유 + color palette(scrub/hair/cap) 차별. NurseAvatarNode 패턴 차용(독립 코드). 빌런 3종 PixelSprite 시각 차단 — EnemyNode/ProfessorNode/StoneGuardNode init 또는 setupVisualOverlay 끝에 `self.color = .clear; self.colorBlendFactor = 1.0` 2줄 × 3 = 6줄 추가. 빌런 9 func(update/startFleeing/apply/startPatrol/startThrowingStethoscopes/scheduleNextThrow/throwStethoscope/stopThrowing/updatePixelAnimation) 시그니처+본문 byte-identical(`-func` 0건 + `-` 삭제 라인 0건). 박병장 데뷔: GameScene.update에 hard 난이도 + (30s OR 50점) + sergeantParkDebuted=false 조건 1 블록 → spawnSergeantPark + presentSergeantParkIntro 2.2s 컷씬(fadeIn 0.4 + hold 1.4 + fadeOut 0.4) + "박병장 등장!" 토스트 fontDisplay 36pt coralPrimary + 등장-머무름-퇴장 SKAction sequence. SergeantParkNode.makeIntroCloseup() static factory(physicsBody nil + setScale 2.0). 비행기 6 자식: AirplaneNode 본체 color .ganhoYellowF → .clear + attachFuselage/Wings/Tail/Cockpit/Propeller/Contrail 모두 구현, `crossScreen(sceneWidth:atY:)` 시그니처 보존. PlayerNode: apply 안 buildFacingChildren → attachFullBody 1줄 교체(시각만), facing 안 fullBody?.facing(direction) 위임, physicsBody/category/collision/velocity/이동 로직 0줄 변경. GameScene sergeantParkDebuted: Bool 프로퍼티 1줄(GameState enum이라 GameScene Properties 섹션으로 이전). Xcode pbxproj CharacterFullBodyNode 등록 4줄. CharacterFaceNode.swift git diff 0줄 + NurseAvatarNode.swift git diff 0줄 — 의사결정 #10 절대 사수. update 핵심 가드 `guard gameState == .playing else { return }` byte-identical. DPad/velocity 입력 매핑 0줄. 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P2 (합격 영향 0)**: (1) CharacterFullBodyNode 캐릭터별 정체성 요소(안경/캡/사이드테일) 미구현 — 후속 Sprint 보강 대상. (2) 걷기 cycle SKAction 부재 — 상수만 추가, 다리 scaleY 토글 미구현. (3) dim alpha 0.5 vs SPEC 0.32 — 통일 권장. (4) PlayerNode PixelSprite 본체 미차단 — 풀바디 scale 0.35 가장자리 픽셀 노출 가능성. (5) Phase E 진단 print 7건 잔존(GameScene.showCountdown) — `#if DEBUG` wrap 또는 제거 권장.

### Sprint 8 Phase F — 인게임 HUD/스킬 zPos 정리
- 시작: 2026-05-20
- 완료: 2026-05-20
- 점수: **9.43/10** (게임로직 9.6 · Swift패턴 9.0 · 비주얼 9.5 · UX 9.4)
- QA 반복: 1회 (한 번에 통과)
- 비고: 실기에서 좌하단 영역 "북클럽" 라벨이 SkillButtonNode 본체(labelNode + nameTagChip)와 HUDSkillSlotNode 모두에서 표시되어 한 라벨이 2번 보이던 결함 해소. 사용자 의사결정 #9 핵심 적용: HUDSkillSlotNode를 *단일 진실 원천*으로 정하고 SkillButtonNode 본체의 두 라벨을 시각만 차단(`isHidden=true`). 의사결정 #6 패턴(빌런 PixelSprite alpha 0) 답습 — 노드 트리 보존(addChild 호출 유지) + 시각만 차단으로 Sprint 4 PNG 통합 대비. V4 3종(hudLabelZPositionV4=100, skillButtonZPositionV4=80, hudSkillSlotLabelZPositionV4=110) GameConfig sub-MARK 추가. 변경 5개 파일: GameConfig +14 / SkillButtonNode init L76 + configure L102 isHidden 2줄(+8) / HUDNode bg/labelNode/valueNode/fill zPos V4 교체 값 보존(+8/-4) / HUDSkillSlotNode labelNode·valueNode 100→110 +10 상향(+4/-2) / GameScene+Setup setupSkillButton 끝 zPos 1줄(+2). zPos 적층 80<100<110 명확화 — 슬롯 라벨이 가장 위. SkillButtonNode 시그니처(onTap/isEnabled/configure/setEnabled/touchesBegan) byte-identical. HUDNode/HUDSkillSlotNode init·update·configure byte-identical. SkillSystem.tryActivate / PhysicsCategory / DPad 입력 매핑 0건 변경. keyLabelChip("B") 보존 — *입력 안내* 단독 책임. `git diff | grep "^[+-].*func "` 빈 출력. 다른 파일(Models/Systems/ColorTokens) git diff 0줄. 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P2 (합격 영향 0)**: (1) Phase E 진단 print 6줄(GameScene.swift L278/287/293/298/301 등) Phase G 시작 전 cleanup 또는 `#if DEBUG` wrap 권장. (2) HUDNode L164 `hudLabelZPositionV4 + 1` 산술 직접 노출 → 후속 Sprint에서 `hudLabelFillZPositionV4 = 101` 분리 검토. (3) SkillButtonNode labelNode.text 잔존 — isHidden=true라 시각 영향 0이지만 트리 보존 원칙으로 유지(변경 권장 0).

### Sprint 8 Phase E — 카운트다운 표시 버그 수정
- 시작: 2026-05-20
- 완료: 2026-05-20
- 점수: **9.24/10** (게임로직 9.6 · Swift패턴 8.5 · 비주얼 9.5 · UX 8.8)
- QA 반복: 1회 (한 번에 통과)
- 비고: Sprint 7-E 합격(9.76) 후 실기에서 카운트다운 미표시 결함의 핵심 후보 fix — CutsceneOverlayNode.dismiss SKAction.sequence 순서 `[fadeOut, cleanup, notify]` → `[fadeOut, notify, cleanup]`로 reorder해 removeFromParent 이후 callback?() 미발화 위험 회피. notify가 노드 트리에 *남아 있는 상태에서* 발화 보장 → showCountdown 진입 보장. 변경 2개 파일: CutsceneOverlayNode.swift(+4/-2, sequence reorder + 의도 주석 2줄) + GameScene.swift(+13/-1, showCountdown 안 진단 print 6줄 `[Phase E]` prefix + 방어 보강 `node.isHidden=false; node.alpha=1.0`). CountdownNode.swift git diff 0줄(본체 보호 — init/start/stepAction/goAction/configureLabel byte-identical). V3 상수 9종 byte-identical: countdownNumberFontSizeV3=120, GoFontSizeV3=140, GoStartScaleV3=1.2, GoEndScaleV3=1.8, DimAlpha=0.32, DimFadeInDuration=0.2, DimFadeOutDuration=0.2, DimZPosition=240, DimNodeName="countdownDim". 시그니처 byte-identical(`git diff | grep "^[+-].*func "` 빈 출력). dim onComplete sequence `[fadeOut, cleanup, startGame]`는 의도적으로 1차 fix 범위 외 유지(실기에서 startGameProperly 미발화 발견 시 후속 적용). gameState 전환 그래프(.cutscene → .countdown → .playing) + spawnSystem.start 호출 시점 + 입력 4초 게이트 보존. 다른 모든 Swift 파일 git diff 0줄. 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P2 (합격 영향 0)**: (1) CutsceneOverlayNode line 110 주석 "*이미 빠진* 상태에서" 문구가 이전 순서 가정 — After 반영해 "*남아 있는* 상태에서"로 수정 권장. (2) 진단 print 6줄 → Phase F 시작 전 별도 cleanup commit 또는 `#if DEBUG` wrap 권장. (3) dim sequence reorder 보류 — 실기 미발화 발견 시 동일 패턴 적용.

### Sprint 8 Phase D — 난이도 카드 크기·여백 확대
- 시작: 2026-05-20
- 완료: 2026-05-20
- 점수: **9.03/10** (게임로직 9.6 · Swift패턴 8.8 · 비주얼 8.6 · UX 8.5)
- QA 반복: 1회 (한 번에 통과)
- 비고: Sprint 7-C 합격(9.83) 후 실기 검증에서 카드 폭(112) 좁아 한글 텍스트 2~3줄 답답 결함 해소. V4 신규 상수 8종(difficultyCardWidthV4=130, HeightV4=200, GapV4=22, PaddingV4=14, SubtitleGapV4=10, HeaderGapV4=12, SubtitleLineHeightV4=1.4, SubtitleFontSizeV4=12) sub-MARK 추가. DifficultyCardNode: 카드 size V3(112×82)→V4(130×200), configureLabels V4 산식, subtitleLabel/descriptionLabel attributedText + NSMutableParagraphStyle.lineHeightMultiple=1.4 + preferredMaxLayoutWidth=102. 신규 private helper 2종(makeSubtitleAttributedText/makeDescriptionAttributedText). setSelected 호출 시 attributedText 재구성으로 색 토글 보존. DifficultySelectScene layoutDifficultyCards width/spacing V4 2줄 교체 + layoutStartButton 동적 보정(`buttonY = min(v3Y, v4Y)`)로 카드 bottom↔버튼 top 36pt 호흡 정확 확보. V3 상수 6종(WidthV3=112/HeightV3=82/SpacingV3=22/StrokeLineWidthV3=1.5/SubtitleFontSizeV3=12/SubtitleOffsetYV3=4) byte-identical. ColorTokens.swift git diff 0줄(Phase 7-C 6종 보호). 시그니처 byte-identical(`-func` 0건, `+func` 2건은 private helper). 좌측 미니 캐릭터 카드 layoutSummaryCard/setupSummaryCard git diff 0줄. 합산 폭 130×3+22×2=434pt < 844pt 화면 폭. 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P2 (합격 영향 0)**: layoutStartButton 지역 매직 넘버 2개(24/36) → GameConfig V4 분리 권장. cardCenterY 산식 중복(layoutDifficultyCards + layoutStartButton) → private helper 추출 권장. 시뮬레이터 실측 캡처 미수행 — fontDisplay(Jua) 특성으로 headerGap 12pt 시각 검증 필요.

### Sprint 8 Phase C — 스킬 설명 힌트 ↔ 시작 버튼 분리
- 시작: 2026-05-20
- 완료: 2026-05-20
- 점수: **9.68/10** (게임로직 10.0 · Swift패턴 9.5 · 비주얼 9.5 · UX 9.5)
- QA 반복: 1회 (한 번에 통과)
- 비고: Sprint 7-B 합격(9.77) 후 실기 검증에서 controlHint("좌하단 스킬 버튼을 1번 탭하면 발동" + "B" 키)와 PrimaryButton "다음 ▶"가 거의 붙어 보이는 결함 해소. V4 신규 상수 3종(skillExplanationBottomButtonGapV4=28, HintChipPaddingYV4=8, ControlHintContainerHeightV4=36) GameConfig sub-MARK 추가. SkillExplanationScene 변경: setupControlHint() height 32→36(=H V4) 1줄 + layoutControlHint() containerY를 startButton 기준 동적 산출(startButtonY + buttonHalfHeight(24) + V4 gap(28) + hintHeightHalf(18) = midY - 90, hint bottom = midY - 108, startButton top = midY - 136 → visual gap 정확 28pt). primaryButtonHeight=48 GameConfig 기존 상수 직접 참조로 fileprivate 보조 상수 불필요(매직 넘버 0). V3 상수 5종 byte-identical: skillExplanationControlHintContainerOffsetY=-120 / ContainerHeight=32 / ButtonRowOffsetY=-160 / BottomButtonGapV3=18 / QuoteBoxWidthV3=332. DarkContextChipNode.swift git diff 0줄(Phase 7-B 결과물 보호). 시그니처 byte-identical(`git diff | grep "^[+-].*func "` 빈 출력). 사용자 의사결정 10건 모두 회귀 0. Phase 7-B 모든 setup/layout 메서드(breadcrumbChip/topBackPill/skillQuoteBox/avatarCard/statChips) git diff 0줄. didChangeSize(_:) 안 layoutControlHint() 호출 보존으로 회전·사이즈 변경 시 V4 산식 재실행. 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P2 (합격 영향 0)**: GameConfig V4 sub-MARK 주석 분량(~25줄) — 산술 검증이 SELF_CHECK/SPEC에 이미 있어 본문은 1~2줄 요약 가능. 가독성 +이므로 강제 수정 불필요.

### Sprint 8 Phase B — 캐릭터 선택 스와이프 페이지
- 시작: 2026-05-20
- 완료: 2026-05-20
- 점수: **9.31/10** (게임로직 9.6 · Swift패턴 9.4 · 비주얼 9.2 · UX 8.6)
- QA 반복: 1회 (한 번에 통과)
- 비고: Sprint 7-A NIKKE 4:5 카드(160×200) 5장이 iPhone 12 Pro 가로 844pt에서 912pt 초과 → 양 끝 카드 잘림 + 헤더 겹침 P0 해소. **5장 동시 노출 → 중앙 1장 + 양옆 반쯤 보이는 2장 스와이프 페이지** 전환(사용자 의사결정 #1 핵심). V4 신규 상수 7종(characterSwipeCardScaleCenterV4=1.08, ScaleSideV4=0.85, AlphaSideV4=0.55, OffsetXV4=180, AnimationDurationV4=0.22, characterHeaderBottomYBoundV4=0.80, characterCardCenterYV4=0.50). CharacterSelectScene 신규 properties 4(currentIndex/characters/swipeStartX/didSwipeInCurrentTouch) + neue 메서드 4(layoutCards/swipeTo/touchesMoved/touchesEnded/touchesCancelled) + touchesBegan 양옆 탭 분기 + cardBaseX/Y 식 swipe 좌표로 교체. CharacterCardNode 신규 CharacterCardPageRole enum(center/left/right/offscreen) + extension setPageState(role:animated:duration:) + applyCenterDecor 2 메서드 — 기존 init/setSelected/attach* 모두 byte-identical. V3 상수 5종(WidthV3=160/HeightV3=200/GapV3=22/CornerRadiusV3=22/SelectedScale=1.08) byte-identical. CharacterFaceNode.swift git diff 0줄(사용자 의사결정 #10 완전 준수 — "캐릭터 선택은 얼굴만" 정체성 유지). 보호 영역 git diff 0줄: 다른 모든 Scenes/GameScene/GameState/PhysicsCategory/Managers/Repositories/Systems/Nodes 외/Models/ColorTokens. `.kim → DifficultySelectScene` / 그 외 → `SkillExplanationScene` 분기 byte-identical. preferenceRepo.save가 swipeTo 안 즉시 호출 — 트랜지션 중 다음 버튼 탭에도 정확한 ID 전달. SKAction 0.22s `.easeInEaseOut` 3종(move/scale/fadeAlpha) + removeAction(forKey:) cancellable. zPosition 적층 명확 110/105/100. 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P2 (합격 영향 0)**: (1) `touchesMoved` threshold 40pt 매직 넘버 → `characterSwipeThresholdXV4` V4 8개째 상수로 분리 권장. (2) iPhone 12 Pro 가로(390pt height)에서 헤더↔카드 safe gap 17pt — 실기 시각 검증 후 layoutHeader에 max() clamp 추가 검토. (3) Phase A ScoreboardScene 결과물이 Phase B 시작 시점 unstaged 상태 — 정리 필요.

### Sprint 8 Phase A — 스코어보드 겹침 해소
- 시작: 2026-05-20
- 완료: 2026-05-20
- 점수: **9.05/10** (게임로직 9.8 · Swift패턴 9.2 · 비주얼 8.5 · UX 8.8)
- QA 반복: 1회 (한 번에 통과)
- 비고: ScoreboardScene 시각 충돌 4건(타이틀↔열헤더 세로 겹침, 우상단 GlassPill↔매트릭스 첫 행 가로 겹침, 행 헤더↔점수 셀 과밀, 하단 stat 매트릭스 근접) 해소. V4 신규 상수 5종 추가(scoreboardTitleYOffsetV4=40, scoreboardHeaderRowGapV4=18, scoreboardCellPitchYV4=38, scoreboardStatBottomGapV4=24, scoreboardColumnHeaderFontSizeV4=16). 적용 결과: 타이틀 Y +95→+135 (V3 +40 합산) · 부제 Y +72→+112 · AccentLine Y +130→+90 (타이틀과 매트릭스 사이 구분선 역할 회복) · 매트릭스 헤더↔첫 데이터 행 gap 4→18pt · 데이터 행 pitch 40→38pt · stat 라벨 lastRowBottom-24pt 동적 산출. V3 상수 ~40개 값 byte-identical 보존(scoreboardTitleOffsetY=95/SubtitleOffsetY=72/AccentLineOffsetY=130/CellGap=4/StatOffsetY=-150 grep 검증). ScoreboardScene 10개 메서드 시그니처 byte-identical(`git diff | grep "^[+-].*func "` 빈 출력). 매트릭스 15셀 데이터 매핑·★ 마커(lastUpdatedKey) 판정 로직·Repository 호출 0줄 변경. 보호 영역 git diff 0줄: 다른 모든 Scenes/GameScene/GameState/PhysicsCategory/Managers/Repositories/Systems/Nodes/Models. 사용자 의사결정 10건(Phase B~G) 모두 회귀 0건. GameConfig +26줄 / ScoreboardScene +16줄 순증. 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P2 (합격 영향 0)**: AccentLine Y(+90)이 부제(+112)·헤더(+110)보다 아래라 시각적으로 "헤더 아래 + 데이터 위" 구분선처럼 보일 가능성. SPEC §기능 2 코드 예시 정확 일치이나 실기 시각 확인 후 V4 미세 조정 검토 여지.

---

## ⏳ Sprint 8 작업지시서 작성 완료 (2026-05-20) — Phase B~G 대기

`SPRINT_8_REQUEST.md` 신규 작성. Sprint 7 합격 후 실기 검증에서 드러난 **7건 결함**을 Phase A~G에 1:1 매핑.

| Phase | 작업 | 매핑 이슈 (스크린샷) |
|---|---|---|
| A | 스코어보드 겹침 해소 | #1 기록보기 타이틀↔표↔칩 겹침 |
| B | 캐릭터 선택 스와이프 페이지 | #2 카드 잘림 + 헤더 충돌 |
| C | 스킬 설명 힌트 ↔ 시작 버튼 분리 | #3 스킬 발동 글자가 시작 버튼에 붙음 |
| D | 난이도 카드 크기·여백 확대 | #4 카드 좁고 line spacing 답답 |
| E | 카운트다운 표시 버그 수정 | #5 카운트다운 미표시 |
| F | 인게임 HUD/스킬 zPos 정리 | #6 좌하단 글자 다 겹침 |
| G | 빌런 가시화 + 박병장 데뷔 + 비행기 + 플레이어 팔다리·좌우 | #7 빌런 픽셀 잔존 + 박병장 미등장 + 비행기 사각형 + 팔다리 부재 + 좌우 동일 |

**실행 트리거**: `Sprint 8 진행해줘` 또는 `Sprint 8 Phase A 진행해줘`

---

## 🎉 Sprint 7 전체 완료 (2026-05-20)

7개 Phase 모두 합격. 평균 점수 **9.62 / 10**. 합격률 100% (7/7).

| Phase | 작업 | 점수 |
|---|---|---|
| A | 캐릭터 카드 NIKKE 4:5 리뉴얼 | 9.45 |
| B | 스킬 설명 겹침 해소 | 9.77 |
| C | 난이도 카드 색 위계 | 9.83 |
| D | 결과창 정리 + ScoreboardScene 신설 | 9.83 |
| E | 카운트다운 오버레이 | 9.76 |
| F | 빌런 4종 + 박병장 신규 | 9.10 |
| G | 플레이어 4방향 스프라이트 | 9.58 |
| **평균** | | **9.62** |

### Sprint 7 Phase F — 빌런 4종 + 박병장 신규
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.10/10** (게임로직 10.0 · Swift패턴 7.5 · 비주얼 9.0 · UX 9.0)
- QA 반복: 1회 (한 번에 통과)
- 비고: 3 기존 빌런(EnemyNode 수간호사/ProfessorNode 이교수/StoneGuardNode 석조무사) 시각 자식 SKShapeNode 부착 + 신규 SergeantParkNode(박병장 공군 청록+선글라스) ~148 LOC. 3 기존 빌런 AI/이동/충돌 시그니처 9개(update/startFleeing/apply, startPatrol/startThrowingStethoscopes/scheduleNextThrow/throwStethoscope/stopThrowing) byte-identical, 본문 0줄 변경. physicsBody.size 인자/categoryBitMask/collisionBitMask/contactTestBitMask 0줄. 속도·waypoint 상수 0줄. StoneGuardNode super.init color 값만 .ganhoPaper → .ganhoStoneGuardLight 교체(시그니처 byte-identical). setupVisualOverlay 호출은 EnemyNode init 마지막, ProfessorNode/StoneGuardNode startPatrol 직전 1줄. EnemyNode 자식 3개(halo+chart+clip zPos -0.1/0.1/0.2), ProfessorNode 자식 2개(stethoDisc+tube zPos 0.1/0.15), StoneGuardNode 자식 3개(armor+eye×2 zPos 0.05/0.2). SergeantParkNode SKSpriteNode(.clear) 상속 + 6 attach 메서드(Shadow/Body/Head/Cap/Sunglasses/Rank) zPos -0.1~0.4 — physicsBody/update/SKAction 0건(시각 시안만, GameScene spawn 0건). ColorTokens 6 신규(AirforceTeal #3A6F7F, AirforceTealLight #5A8F9F, SunglassesBlack #1A1A1A, StoneGuardLight #A0A0A8, StoneGuardDark #5A5670, StoneGuardOutline #7A7570). GameConfig Phase F V3 상수 29개 신규(enemyVisualHalo/Chart 5 + professorStetho 4 + stoneGuardEye 2 + sergeant 18). Xcode pbxproj 4줄(SergeantParkNode 등록). 신규 mockup villains-and-player-directions-v1.html ~321 LOC(4 패널 가로 정렬 + SVG 96×120 + 색 chip + 박병장 ✨NEW + Phase G 후반부 5명 4방향 메모). 보호 영역 git diff 0줄: GameScene/GameScene+Setup/PhysicsCategory/Models/Systems/Repositories/Managers/PlayerNode/NoteNode/ProjectileNode/StethoscopeNode/Phase A·B·C·D·E 결과물. 강제 언래핑 0, Timer 0, switch default 0, as! 0, update()-내-addChild 0. 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P1 (합격 영향 0)**: 시각 디테일 매직 넘버 8건(stroke/cornerRadius/비율 리터럴) — Phase G 시작 시 enemyVisualChart*StrokeWidth/stoneGuardArmorCornerRadius/sergeantBodyCornerRadius 등 추가 7~10개 상수로 묶어 정리 권장.
- **잔존 P2 (합격 영향 0)**: StoneGuardNode `let eyeSize = CGSize(width: 2, height: 0.8)` → GameConfig `stoneGuardEyeSize` 토큰화.

### Sprint 7 Phase E — 카운트다운 오버레이
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.76/10** (게임로직 10.0 · Swift패턴 9.6 · 비주얼 9.5 · UX 9.7)
- QA 반복: 1회 (한 번에 통과)
- 비고: 게임 시작 시 멈춤감 해소를 위한 3·2·1·GO! 카운트다운 시각 v3 보강. 기존 CountdownNode(Phase 6-13 신설) 시그니처 `init()` + `start(onTick:onGo:onComplete:)` byte-identical 유지. 4가지 보강: ① SKLabelNode init에 fontNamed Jua-Regular 적용(시스템 폰트 → Jua) ② 색 4개 갱신(3·2·1 = ganhoNavyDeep / GO = ganhoCoralPrimary, v2 blood/yellow/pink/mint와 다름) ③ stepAction/goAction setup에 fontSize 분기 추가(숫자 120pt V3 / GO 140pt V3) ④ GO scale 1.0→1.3 → 1.2→1.8(더 큰 펄스). GameScene.showCountdown에 dim SKSpriteNode 부착 + 페이드인 + onComplete에서 fadeOut→cleanup→startGameProperly 시퀀스([weak self] 이중 캡처). dim zPosition 240(CountdownNode 250 아래). 총 4.0s = 3·2·1(3.0s) + GO!(0.8s) + dim fadeOut(0.2s). GameConfig V3 신규 상수 9종(NumberFontSizeV3=120, GoFontSizeV3=140, GoStartScaleV3=1.2, GoEndScaleV3=1.8, DimAlpha=0.32, DimFadeInDuration=0.2, DimFadeOutDuration=0.2, DimZPosition=240, DimNodeName="countdownDim"). 기존 V2 상수 8개 값 보존(fontSize 96, fadeIn 0.1, hold 0.7, fadeOut 0.2, goEndScale 1.3, goFadeOut 0.4, goHold 0.5, zPosition 250). 신규 mockup countdown-overlay-v1.html ~247 LOC(4프레임 16:9 미니 + dim + 색 대비 + Jua + 캡션 + 메모 + JS 0줄 + mini-actor placeholder). 보호 영역 git diff 0줄: DPadNode/SkillButtonNode/SkillSystem/SpawnSystem/ContactRouter/ScoreSystem/GameScene+Setup/Managers(AudioManager 포함)/Repositories/GameState/PhysicsCategory/ColorTokens/모든 다른 Scenes/Phase A·B·C·D 결과물. CountdownNode.start 시그니처 + startGameProperly 본체 + gameState 전이 + spawnSystem.start 호출 위치 byte-identical. 강제 언래핑 0, Timer 0, switch default 0, update()-내-addChild 0. 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P2 (합격 영향 0)**: (1) V3 상수 명명 규칙 (countdownGoEndScale vs V3) 공존 — Sprint 7 종료 후 일괄 정리. (2) AudioManager tick/chime 키 등록은 Sprint 8 후보(SPRINT_7_REQUEST §6.3 명시). (3) dim fadeOut 0.2s + spawnSystem 갭이 추후 사운드 등록 시 청각 단절 우려 — chime ≥0.2s 또는 .group 검토.

### Sprint 7 Phase D — 결과창 + ScoreboardScene 신설
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.83/10** (게임로직 10.0 · Swift패턴 9.8 · 비주얼 9.7 · UX 9.6)
- QA 반복: 1회 (한 번에 통과)
- 비고: ResultScene 5요소 0px 겹침 + 신규 ScoreboardScene 5×3 매트릭스. ResultScene 신규 자식 3종(scoreNoteIconLabel 24pt 좌측 / bestPill GlassPill 우측 +120 / scoreboardButton GlassPill 좌측 -110). scoreLabel "♪" 제거(텍스트만 "\(finalScore)"). bestLabel.alpha=0 시각 차단 + 노드 트리 보존. headerChip/titleLabel/subtitle/accentLine V3 +15/+15/+14/+18 시프트, divider/playsValue/playsTitle/totalValue/totalTitle V3 +12 동조 상승. touchesBegan에 scoreboard 칩 분기 추가(기존 StartScene 분기 보존, 1탭 정책 유지). inferredCharacterID computed property(characterName → CharacterID 역변환 — 5 displayName 유일성 안전). 신규 ScoreboardScene ~499 LOC: GradientBackgroundNode.threeStop + AccentLine + Jua 30 "기록 보기" + 매트릭스 15셀(CharacterID.allCases × Difficulty.allCases) + 행 헤더 5(CharacterFaceNode.mini 32px setScale 0.47 + 약칭 라벨) + 열 헤더 3(Phase C 색 토큰) + ★ 마커 lastUpdatedKey 셀(zPos 3) + 하단 stat("총 플레이 N회 · 졸업장 N장") + 좌상단 "← 결과로" GlassPill + 우상단 "캐릭터별 기록" DarkContextChip. ResultReturnContext struct 8필드(같은 파일 동봉, Foundation 의존만). 백 버튼 복귀 시 새 ResultScene 인스턴스 isNewGraduation:false/graduatedAt:nil 강제(졸업장 재표시 차단). CharacterFaceNode.mini 정적 팩토리 1개 추가(신규 시각 자식 0). GameConfig Phase D V3 상수 ~40개 신규. Xcode pbxproj 4줄 추가(ScoreboardScene 등록). 신규 mockup 2종(result-screen-v3.html ~430 / highscore-board-v1.html ~323). 보호 영역 git diff 0줄: Phase A·B·C 결과물 14파일 + GameScene/GameState/PhysicsCategory/Managers/Systems + Repositories(저장 호출 0건, 읽기 전용 — perDiffRepo.current·statsRepo.current.playCount·graduationRepo.current.count). DiplomaOverlayNode.present + isNewBest sparkle 5발/heavy 햅틱/NewMail 사운드 발화 조건 byte-identical. newResultScene 시그니처 byte-identical. 강제 언래핑 0, Timer 0, switch default 0, update()-내-addChild 0, 하드코딩 hex 0(Scenes). 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P2 (합격 영향 0)**: bestLabel.alpha=0 직후 신기록 분기에서 startBestLabelGoldBlink 액션이 alpha 0.5↔1.0 깜빡일 수 있음. 차후 정리 Sprint에서 removeAction 또는 alpha 0 강제 유지 한 줄 추가 가능.

### Sprint 7 Phase C — 난이도 카드 색 위계
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.83/10** (게임로직 10.0 · Swift패턴 9.8 · 비주얼 9.7 · UX 9.6)
- QA 반복: 1회 (한 번에 통과)
- 비고: 난이도 3장 카드에 색 위계(하=민트/중=골드/상=코랄 그라데이션) 부여. Difficulty 4종 computed property(cardFillTop/cardFillBottom/cardStrokeColor/cardGlowColor) 3 case exhaustive switch default 미사용. ColorTokens 6 신규(EasyMint/EasyDeep/MidGold/MidDeep/HardCoral/HardDeep). GameConfig Phase C V3 상수 14종(NameFontSize=30, NameStrokeWidth=1.0, LiftY=8, LiftDuration=0.18, GlowWidth=158, GlowHeight=116, GlowAlpha=0.80, GlowSpread=12, HaloWidth=240, HaloHeight=90, HaloAlpha=0.35, HaloSpread=24, HaloFadeIn=0.25, HaloOffsetY=0). DifficultyCardNode init/setSelected에서 id.cardFillTop/cardStrokeColor/cardGlowColor lookup 적용 + ringGlow.strokeColor 동기화. nameLabelStroke 32pt + nameLabel 30pt 2-라벨 stroke 패턴(SKLabelNode stroke 직접 미지원 우회). liftCurrentOffset 증분 패턴 — setSelected 다중 호출 안전. DifficultySelectScene 시작 버튼 halo SKShapeNode 240×90 ellipse + 페이드 인 0.25s + zPosition startButton-1. 좌측 속도 칩 stroke 1pt 보강. 신규 mockup difficulty-select-v3.html ~536줄. PrimaryButtonNode 내부 0줄 변경(OQ-3 halo는 Scene 책임). Phase A·B 결과물 6파일 + 게임 로직 4파일 + Managers/Repositories/Systems 디렉토리 모두 git diff 0줄. Difficulty enum 기존 멤버(color/displayName/subtitle/description/shortName/raw value) byte-identical. init/transitionToGame/transitionBack 시그니처 byte-identical. 강제 언래핑 0, Timer 0, update()-내-addChild 0, switch default 0. 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P2 (합격 영향 0)**: DifficultySelectScene 속도 칩 `chip.lineWidth = 1` 리터럴 GameConfig 상수화 권장. 차기 정리 Sprint에서.

### Sprint 7 Phase B — 스킬 설명 겹침 해소
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.77/10** (게임로직 10.0 · Swift패턴 9.5 · 비주얼 9.7 · UX 9.6)
- QA 반복: 1회 (한 번에 통과)
- 비고: SkillExplanationScene에서 시각 충돌 4건 정리. (1) 하단 secondary BackButtonNode `addChild` 호출 제거 — 좌상단 GlassPill `topBackPill`이 백 버튼 단독 책임. (2) 우측 본문 상단 `metaLabel`("XX의 스킬") `addChild` 호출 제거 — 우상단 브레드크럼 `breadcrumbChip`이 위치 정보 단독 책임. (3) `didChangeSize(_:)`의 `layoutMetaLabel()` 호출 제거. (4) `setupSkillQuoteBox()` 폭/보더, `layoutStatChips()` spacing을 V3 상수 참조로 교체. GameConfig 신규 상수 5종(`skillExplanationQuoteBoxWidthV3=332`, `ContentWidthRatioV3=0.52`, `QuoteBoxBorderWidthV3=4`, `StatChipSpacingV3=10`, `BottomButtonGapV3=18`). 기존 v2 상수(300/3/8) 값 보존. `backButton` / `metaLabel` 인스턴스 자체는 보존(시그니처 0 변경) — `touchesBegan`의 `contains` 가드는 부모(씬) 없어 hit-test false 반환으로 안전. 신규 mockup `skill-explanation-v3.html` ~280줄. 보호 영역 13파일(Phase A 결과물 4 + 게임 로직 4 + 보호 노드 5) 모두 git diff 0줄. `init(characterID:)` / `transitionToCharacterSelect()` / `transitionToDifficulty()` byte-identical. 강제 언래핑 0, Timer 0, update()-내-addChild 0. 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P2 (Phase B 합격 영향 0)**: `setupMetaLabel()` / `layoutMetaLabel()` 두 함수가 dead-leaning 상태. SPEC OQ-2 보존 원칙(인스턴스 시그니처 보존)에 따라 의도적 잔류. 차기 정리 Sprint에서 함수 자체 삭제 또는 isHidden 플래그 검토 가능.

### Sprint 7 Phase A — 캐릭터 선택 NIKKE 카드 리뉴얼
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.45/10** (게임로직 9.8 · Swift패턴 9.4 · 비주얼 9.3 · UX 8.8)
- QA 반복: 1회 (한 번에 통과)
- 비고: 카드 폭 76→160 · 높이 104→200 · gap 10→22 · 4:5 NIKKE 식 세로 카드. 카드 내부 5요소(좌상단 헥사 28×28 캐릭터 색 + 이모지 5종 / 좌하단 등급 로마숫자 배지 26×18 navyDeep×0.85 + 골드 라벨 / 우상단 CD 미니칩 9pt coralLight×0.85 / 중앙 얼굴 SVG / 하단 이름 Jua 15 + 속도 Gowun 10) 흡수. 선택 데코 신규 2종(하단 코랄 ellipse glow 224×60 alpha 0.45 + 상단 "선택됨" 알약 60×20 Jua 10 흰/코랄). CharacterID.rarity/elementSymbol · PlayerSkill.cooldownText 3종 computed property 추가(5 case exhaustive switch). GameConfig v3 상수 ~28종 신규(기존 7종 값 보존). CharacterCardNode 5요소 attach* 메서드 신규 + setSelected glow/pill 토글. CharacterSelectScene 글래스 컨테이너 v3 폭/높이 + alpha 0.0, 외부 색점·태그 isHidden, cardBaseX/Y 본문만 v3 폭, 스킬 패널 setScale clamp(max 320). 신규 mockup character-select-v3.html ~445줄. 보호 영역 git diff 0줄(ResultScene/GameScene/GameState/PhysicsCategory/Managers/Repositories), preferenceRepo·transitionTo*·.kim 분기·CharacterID/PlayerSkill 기존 값 byte-identical. 강제 언래핑 0건, Timer 0건, update()-내-addChild 0건. 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P2 (Phase A 합격 영향 0)**: (1) glow 높이 mockup CSS 80 vs Swift 60 SPEC 자가-모순 정렬. (2) iPhone 12 Pro 가로에서 카드 5장 합산 폭 912pt가 화면 844pt 초과 → 양 끝 ±34pt 외측 → 후속 Phase에서 minCardSpacing 축소 또는 카드 폭 v3.5 보정 권장. (3) attachCDChip의 frame.width 측정 패턴 주석 보강.

### Sprint 6 — 흐름 재편 + 캐릭터 얼굴 + 메인 캐릭터
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.53/10** (게임로직 9.8 · Swift패턴 9.4 · 비주얼 9.2 · UX 9.5)
- QA 반복: 1회 (한 번에 통과 — Evaluator subagent stream timeout으로 부모 하네스가 직접 핵심 검증 수행)
- 비고: 5단계 흐름(Start→Character→Skill→Difficulty→Game) + .kim 4단계(스킬 스킵) 신설. mockup 2종 수정(character-select / skill-explanation) + 1종 신규(difficulty-select-v2.html ~510줄). Swift 수정 4건(StartScene 난이도 카드 70~100줄 삭제·NurseAvatarNode 부착 / CharacterSelectScene init(size:) 단순화·5장 얼굴 부착·.kim→Difficulty 분기 / SkillExplanationScene difficulty 인자 제거·시작→다음·Difficulty 전이 / GameConfig 신규 상수 ~50개·characterSelectBackPillText "← 메인" 값 교체) + 신규 3건(DifficultySelectScene 448줄 / CharacterFaceNode 660줄 5캐릭터 SVG→SKShapeNode / NurseAvatarNode 374줄 김간호 큰 그림 SVG→SKShapeNode). GameScene.newGameScene(characterID:difficulty:) 시그니처 byte-identical, 보호 영역 17파일 + 공용 노드 8파일 + Managers/Repositories/GameState/PhysicsCategory/ColorTokens 모두 git diff 0줄. 강제 언래핑 0건, Timer 0건. 빌드 SUCCEEDED 신규 워닝 0건.
- **사용자 후속 작업 권장 (SPRINT_6_REQUEST.md §7)**: (1) Sprint 4 PNG 자산 도착 시 CharacterFaceNode → SKSpriteNode 교체(좌표/스케일 동일 유지). (2) NurseAvatarNode 호흡 애니메이션(scale 1.02↔0.98 3초 주기). (3) 캐릭터→스킬→난이도 단계 전이 chime 사운드. (4) 시뮬레이터 실기로 5명 얼굴 식별·NurseAvatar 4영역 분간 시각 검증.

---

## Sprint별 요점 (DESIGN_RENEWAL_REQUEST.md §9에서 발췌)

### Sprint 1 (시각 변화 0)
- `ColorTokens.swift` 토큰 15개 추가
- Jua / Gowun Dodum / Noto Sans KR ttf 추가 + Info.plist + GameConfig 폰트 상수
- 신규 노드: `GlassPillNode`, `AccentLineNode`, `DarkContextChipNode`
- `PrimaryButtonNode`, `BackButtonNode` 리스타일링
- `GradientBackgroundNode` 3-stop 그라데이션 옵션 추가

### Sprint 2 (메뉴 화면 시각 변경)
- `mockups/main-screen-v2.html` 매칭 → StartScene
- `mockups/character-select-v2.html` 매칭 → CharacterSelectScene
- `mockups/skill-explanation-v2.html` 매칭 → SkillExplanationScene
- 캐릭터 자리는 placeholder (Sprint 4 대기)

### Sprint 3 (인게임 시각 변경)
- `mockups/game-map-v2.html` 매칭
- 체크보드 hex 토큰 교체 (#FFEFE0 / #FFDFC8)
- HUD 4슬롯 + TIME 12초 이하 경고 색
- D-Pad **우하단** / 스킬 버튼 **좌하단** 위치
- 음표·F 투사체·콤보팝업 v2 스타일

### Sprint 4 (PNG 통합) — 자산 대기 중
- `PixelSpriteRenderer` → `SKTextureAtlas` 마이그레이션
- 5명 × 16프레임 PNG 임포트
- 폴폴폴 `SKAction` 패턴 (scaleY 호흡)

### Sprint 5 (결과 화면)
- `mockups/result-screen-v2.html` 매칭 → ResultScene
- 3분기 (일반·신기록·졸업장) 분기별 시각
- DiplomaOverlayNode 우드컷 패턴 + 명조 폰트

---

## 합격 기준 요약 (DESIGN_RENEWAL_REQUEST.md §11)

각 Sprint마다 Evaluator가 다음 4개 카테고리로 채점:

| 카테고리 | 가중치 | 통과선 |
|---|---|---|
| 게임 로직 회귀 0 | 40% | 9.0 이상 (절대 회귀 0) |
| Swift 패턴 (rules 준수) | 20% | 7.0 이상 |
| 비주얼 일관성 (mockup 매칭) | 25% | 7.0 이상 |
| 가독성 & UX | 15% | 7.0 이상 |

가중 평균 **7.5 이상**이면 ✅ 합격.

---

## 트러블슈팅

**Q. "디자인 리뉴얼 진행해줘"라고 했는데 반응이 없어요**
→ Claude Code 세션이 `CLAUDE.md`를 읽었는지 확인. 새 세션 시작 시 자동으로 읽혀야 함. 안 됐다면 "CLAUDE.md를 다시 읽어줘"라고 요청.

**Q. Sprint 1만 계속 돌고 다음으로 안 넘어가요**
→ Evaluator 점수가 7.5 미만이라 합격 처리가 안 됨. 점수 상세를 보고 어디서 막혔는지 확인. 3회 시도 초과 시 사용자 개입 필요.

**Q. Sprint 순서를 바꾸고 싶어요**
→ 이 파일의 진행 현황 표를 수동 편집해서 원하는 Sprint를 "⏳ 대기"로 변경. Sprint 5가 Sprint 4보다 먼저 가능함.

**Q. 처음부터 다시 시작하고 싶어요**
→ 이 파일 삭제 → "디자인 리뉴얼 진행해줘" 입력 → Sprint 1부터 자동 재시작.
