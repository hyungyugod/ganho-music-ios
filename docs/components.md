# 컴포넌트 목록 — GanhoMusic iOS (R8 전면 재작성)

그랜드 리팩토링 v3 완료 시점(R8)의 실제 파일·역할 인벤토리.
Generator가 새 기능 추가 전 반드시 읽고 현재 상태를 파악한다.

**선행 참조**: `refactor/00_MASTER_PLAN.md`(비전·불변 조건) · `docs/debug-flags.md`(DEBUG 분기) ·
`docs/swift-rules.md`·`spritekit-rules.md`(금지 패턴) · `refactor/R8_FINAL_AUDIT.md`(최종 감사).

**플랫폼 정책**: iOS 타겟만 정식 지원. `GanhoMusic tvOS/`·`GanhoMusic macOS/`는 템플릿 잔여물 — 수정 금지.
**등록 정책**: Shared 소스는 pbxproj **명시 등록** (fileSystemSynchronizedGroups 아님) — 신규 .swift는 4곳(BuildFile/FileReference/Group/SourcesPhase) 등록 필수.

---

## 1. 루트 오케스트레이터 — GameScene + 확장 파일

| 파일 | 역할 |
|---|---|
| `GameScene.swift` | 본체 — 프로퍼티·init/factory·didMove·update() 파이프라인 골격 (300줄 가드) |
| `GameScene+UpdatePipeline.swift` | R8 분할 — 파이프라인 단계 함수(input/player/AI/effects/HUD)·tension 폴링·마일스톤 배너 |
| `GameScene+Setup.swift` | didMove 셋업 ① — 배경/월드/맵/풀·레지스트리/디렉터/플레이어/카메라/D-Pad/HUD/적 |
| `GameScene+SetupActors.swift` | R8 분할 ② — 이교수·스킬/달리기 버튼·HUD 스킬 슬롯·일시정지 버튼 셋업/레이아웃 |
| `GameScene+DailyModifiers.swift` | R8 분할 ③ — R6 일일 모디파이어 배선 + 박병장 데뷔 연출 |
| `GameScene+GameState.swift` | 일시정지(v3 PixelDialog)·메인 이탈·endGame(저장 5종+메타 기록+Result 전환) |
| `GameScene+Contact.swift` | ContactRouter 콜백 — 수집/피격/매혹/변기 |
| `GameScene+NearMiss.swift` | R7/R8 — near-miss 폴링 (히트박스 가장자리 10px 셸, projectiles 슬롯 전속) |
| `GameScene+Camera.swift` | CameraDirector 위임 — follow/클램프 |
| `GameScene+Countdown.swift` | 3·2·1·GO + dim |
| `GameScene+Cutscene.swift` | 인트로/빌런/mid 컷씬 흐름 + DEBUG SKIP/AUTO_PAUSE 분기 |
| `GameScene+DangerWarnings.swift` | 위험 경고 시각 폴링 (거리 기반 alpha/펄스) |
| `GameScene+EasterEgg.swift` | AIRFORCE 이스터에그 시퀀스 |
| `GameScene+Feedback.swift` | 수집/피격/텔레그래프 피드백 (히트스톱·셰이크·SFX·햅틱 합성) |
| `GameScene+Layout.swift` | 화면 고정 UI 레이아웃 (didChangeSize 멱등) |
| `GameScene+MovementInput.swift` | D-Pad 입력 스무딩 + DEBUG 데모 오토파일럿 |
| `GameScene+Transition.swift` | 씬 전환 헬퍼 |

## 2. Scenes/ — 메뉴·결과 (전부 v3 "Night Shift")

| 파일 | 역할 |
|---|---|
| `BaseMenuScene.swift` | 공통 — NightShift 배경·staggered 등장·safe inset·compact scale |
| `SceneRouter.swift` | push/픽셀 디졸브 전환 단일 진입점 |
| `StartScene.swift` (+`+Auth`) | 로비 — 로고(R8: 칩 겹침 클램프)·히어로·프로필/일일 칩·로그인 다이얼로그. Firebase 인증 상태 머신 |
| `CharacterSelectScene.swift` (+`+Layout`/`+Account`/`+Overlays`) | 캐러셀 선택 — R8 일러스트 카드. 좌측 풀바디 프리뷰(픽셀 유지)·계정/클라우드 |
| `SkillBriefingScene.swift` | 작전 브리핑 — 일러스트 카드(플립 인) + 스킬 패널 |
| `DifficultySelectScene.swift` | 난이도 3카드 (Palette.difficulty 토큰) |
| `ResultScene.swift` (+`+Build`/`+Reveal`/`+MetaCelebration`) | 보상의 무대 — 도장→카운트업→별→XP→칩→버튼 시퀀스 + 해금 배너/업적 토스트 |
| `ScoreboardScene.swift` (+`+Table`/`+Achievements`) | 기록 테이블 + 업적 16종 탭 |
| `PixelKitGalleryScene.swift` | DEBUG — v3 컴포넌트 갤러리 |

## 3. Nodes/UI/ — v3 디자인 시스템 컴포넌트 9종

| 컴포넌트 | 역할 |
|---|---|
| `PixelPanelNode` | ink800 면 + 2px 보더 + 하드섀도 + 헤더 슬롯 |
| `PixelButtonNode` | 3변형(primary/secondary/ghost) — 자체 터치·uiTap SFX·햅틱 주입 |
| `PixelChipNode` | info/locked/accent 칩 + 아이콘 슬롯 |
| `PixelProgressBarNode` | 세그먼트 XP/진행 바 |
| `PixelCardNode` | 카드 베이스 — 선택 보더+글로우+scale 1.04 |
| `PixelCharacterCardNode` | R8 — 카툰 일러스트(.linear) + 시그니처 백드롭 + idle 부유 + 잠금 실루엣 |
| `PixelDialogNode` | 딤+패널 다이얼로그 — R8부터 일시정지도 이 컴포넌트 |
| `LoginChoiceDialogNode` | 게스트/Apple/취소 — StartScene 소비 |
| `NightShiftBackdropNode` | 스타필드 + 심전도 배경 |

## 4. Nodes/ — 인게임 노드

| 분류 | 파일 |
|---|---|
| 액터 | `PlayerNode` · `EnemyNode`(수간호사) · `StoneGuardNode` · `ProfessorNode` · `SergeantParkNode` |
| 투사체·수집물 | `FProjectileNode` · `StethoscopeNode` · `NoteNode` · `ToiletNode` · `AItemNode` |
| 입력·HUD | `DPadNode` · `SkillButtonNode` · `RunButtonNode` · `HUDNode` · `HUDSlotNode`(+`+Display` — R8 분리) · `HUDSkillSlotNode` · `PauseButtonNode` |
| 연출(자가 소멸) | `SparkleEffectNode`(R8: .ingame 단일) · `ScorePopupNode` · `ComboPopupNode` · `ComboBreakNode` · `MilestoneBannerNode` · `ToastLabelNode` · `HitFlashNode` · `BombFlashNode` · `WalkDustNode` · `CountdownNode` · `TensionVignetteNode` |
| 경고 | `EnemyProximityWarningNode` · `EnemyTelegraphNode` · `ProfessorTelegraphNode` · `ProjectileWarningLineNode` · `PlayerNearMissWarningNode` |
| 컷씬·오버레이 | `IntroCutsceneNode` · `IntroVillainCutsceneNode` · `MidCutsceneNode` · `CutsceneOverlayNode` · `DiplomaOverlayNode` · `AirforceOverlayNode` · `AirplaneNode` |
| 계정·프로필 | `AccountMenuOverlayNode` · `ProfileDetailOverlayNode`(+`+Content`) · `ProfileAvatarViewNode` |
| 맵 | `MapNode` · `WallTileNode` · `HospitalPropNode` |
| 렌더 | `PixelSpriteRenderer` |

### v2 잔존 처분 (R8 확정)

| 컴포넌트 | 처분 | 근거 |
|---|---|---|
| `PrimaryButtonNode` | **삭제** | 마지막 소비처(일시정지)가 v3 PixelDialog로 재구축 — 참조 0 실증 |
| `DarkContextChipNode` | **보존** | 인게임 SkillButton/RunButton 스킬명 칩 현역 — v3 재구축 비대상 (헤더 주석 봉인) |
| `HUDNode`/`HUDSlotNode` | 보존 (v2 시각) | 인게임 HUD 현역 — R8은 1파일 2클래스만 해소 |

## 5. Systems/ — 게임 로직

| 파일 | 역할 |
|---|---|
| `SpawnSystem.swift` (+`+Notes` — R8 분리) | 음표(자기 재예약 체인·실효 캡·패턴)·변기 스폰. F 발사는 EnemyNode 소관 |
| `ContactRouter.swift` | physics 충돌 분기 (델리게이트 내 즉시 제거 금지 — 지연 회수) |
| `ScoreSystem.swift` | 점수·콤보 윈도우·near-miss 연장 파생값 |
| `SkillSystem.swift` | 스킬 4종 상태 머신 (≈720줄 — R8 의도적 보존, 감사 보고서 §3) |
| `HitstopController.swift` | 히트스톱 — speed/isPaused 소유권 |
| `CameraDirector.swift` | 보간 추적·셰이크·줌 펄스·킥 |
| `EffectDirector.swift` | 파티클 6종 — 풀링·캡·우선순위 |
| `AchievementEvaluator.swift` | 업적 16종 판정 (RunSummary 입력) |

## 6. Config/ — 도메인 상수 (매직 넘버 0의 단일 진실 원천)

| 파일 | 도메인 |
|---|---|
| `GameplayTuning.swift` | 게임 수치 (속도/스폰/점수/히트박스) — **R8 diff 0 게이트** |
| `FeelTuning.swift` (+R2/R3/R4/R5/R7/R8) | 연출 타이밍·강도. R3=Motion 토큰, R8=일러스트 부유·AUTO_PAUSE |
| `UILayout.swift` (+R4/R5/R6/R7/R8) | 레이아웃·카피. R8=일러스트 카드·일시정지 v3·로고 클램프 |
| `Palette.swift` / `ColorTokens.swift` | v3 잉크/액센트 토큰 + 레거시 픽셀 팔레트 |
| `Typography.swift` | V3 폰트 토큰 (Galmuri 후보 해석) |
| `ZOrder.swift` | 적층 — v3 Layer 11층 + 레거시 z |
| `MetaTuning.swift` / `MetaProgression.swift` | 메타 수치·별 임계·레벨 곡선 |
| `StorageKeys.swift` | UserDefaults 키 — **불변 조건 2 (변경 금지)** |
| `GameState.swift` / `PhysicsCategory.swift` | 상태 enum·물리 비트마스크 |
| `SceneSafeArea.swift` / `DeviceLayoutProfile.swift` | safe area·디바이스 프로파일 |

## 7. Core/ · Rendering/ · Managers/ · Repositories/ · Models/ · Debug/

| 디렉토리 | 파일 (역할) |
|---|---|
| Core/ | `EntityRegistry`(동적 엔티티 캐시) · `ObjectPool`(풀 4종+먼지) · `Tween`(곡선) · `SeededRandom`(splitmix64) · `FrameStats`(DEBUG 진단) |
| Rendering/ | `TextureAtlasStore`(+`+R2`/`+Props`) — 사전 베이크 텍스처 캐시 (매 프레임 생성 0) |
| Managers/ | `FirebaseAuthManager`(공개 API 불변 — 불변 조건 1) · `CloudSaveCoordinator` · `HapticsManager`(CoreHaptics v2) · `ChiptuneSynth`(SFX) · `BGMPlayer` |
| Repositories/ | HighScore/Statistics/PerDifficultyScore/Graduation/CharacterPreference/DifficultyPreference/AuthProfile/ProfileAvatar/CloudProgress/PendingCloudScore/`MetaProgressRepository`(+`+Cloud`) |
| Models/ | CharacterID·Difficulty·PlayerSkill·CharacterUnlockRules/State·GameStats·RunSummary·DailyChallenge·AchievementID·CloudScoreRecord·CloudProgressSnapshot·CutsceneTexts·`PixelSprite`/`PixelPalette`/`PixelPortraitSprite`/`PixelHeroSprite`(**byte-equal 불변 — 조건 4**) 외 |
| Protocols/ | `PixelCharacterAnimating` · `SelfDismissingNode` |
| Debug/ | `MetaMigrationSelfTest` (전체 #if DEBUG — env 구동) |
| Errors/ | `AuthError` |

## 8. 자산

- `Assets.xcassets/Characters/` — R8 일러스트 5종 `{kim,jung,geon,im,lee}_down_idle_1` (96×144pt, .linear 로드).
- `Resources/Fonts/` — Galmuri 계열 + GowunDodum. `Resources/Sounds/` — BGM 슬롯 (재생 OFF — FeelTuning.isBGMEnabled).
- 인게임 픽셀은 전부 코드 데이터(PixelSprite 등) → `TextureAtlasStore` 런타임 베이크.
