# R8 최종 감사 보고서 — 그랜드 리팩토링 v3 "Night Shift" 종결

측정 환경: Xcode 26.x / iPhone 17 시뮬레이터(iOS 26.5) / Debug 빌드(`showsNodeCount`/`showsFPS`/FrameStats).
측정일 2026-06-11. 전 측정은 모든 R8 코드 변경 완료 *후* 실행 (측정치 무효화 방지 — SPEC §작업 우선순위).

---

## §1. 금지 패턴 분류표 (grep 전수 — R8 합격 게이트)

| 패턴 | 측정 방법 | 결과 | 처분 |
|---|---|---|---|
| `as!` | grep 전수 (Shared+iOS) | **0건** | — |
| `try!` | grep 전수 | **0건** | — |
| `Timer.scheduledTimer` | grep 전수 | **0건** | — |
| `DispatchQueue.asyncAfter` (게임 내) | grep 전수 | **0건** (주석 언급 5건뿐 — "금지" 명기 주석) | — |
| 강제 언래핑 postfix `!` | 정규식 `[\w\)\]]!(?![=!])` + 주석/fatalError 제외 수동 분류 | **0건** — 매칭 18건 전부 한국어 문자열 리터럴 내 느낌표("아슬!"·"졸업!" 등) | 신규 유입 0 |
| `fatalError` | 참고 — 45파일, 전부 `required init?(coder:)` 관례 (강제 언래핑 아님) | 허용 관례 | — |
| enum switch `default:` | grep `default:` 전수 | **enum 0건** | 아래 예외 분류표 |
| 비-DEBUG `print(` | `#if DEBUG` 깊이 추적 스크립트 전수 | **0건** (8개 print 전부 #if DEBUG 내 — NearMiss×2/ResultScene+Reveal/ResultScene/ObjectPool/Typography×2/MetaMigrationSelfTest(파일 전체 DEBUG)) | DEBUG 격리 print 허용 해석 — docs/debug-flags.md §3 명문화 (불일치 #6 해소) |
| 매직넘버 신규 유입 (R8 diff 한정) | diff 자체 검수 | **0건** — 신규 수치 전부 `UILayout.R8`/`FeelTuning.R8`/`ZOrder.pauseDialogZPosition` 경유 (구조적 `/2`·`max(0,…)` 제외) | — |

### switch `default:` 허용 예외 분류 (구조적 필수 — 각 위치 사유 주석 봉인 완료)

| 위치 | 매칭 대상 | 사유 |
|---|---|---|
| `SpawnSystem+Notes.swift` (구 SpawnSystem L267) | `Int % 3` | 비유한 Int 도메인 — exhaustive 불가 |
| `ComboPopupNode.swift` text(for:)/color(for:) 2곳 | `Int` 마일스톤 | 동상 (미래 마일스톤 graceful fallback) |
| `ScorePopupNode.swift` text/color 2곳 | `Int` 가산점 | 동상 |
| `FirebaseAuthManager.swift` appleAuthError | `AuthErrorCode` (ObjC non-frozen) | 컴파일러 exhaustive 보장 불가 |
| 비대상 명기 | Dictionary `default:` subscript 13곳 (MetaProgressRepository 등) · `@unknown default` (BGMPlayer L175) | 문법상 switch-default 아님 / Swift 권장 패턴 |

## §2. 성능 감사 표 — 12씬 노드 수·fps

| # | 씬 | 노드 수 | fps | 게이트 | 스크린샷 |
|---|---|---|---|---|---|
| 1 | start | 56 | 60.0 | 메뉴 ≤250 ✅ | r8-start.png |
| 2 | characterSelect (일러스트 반영) | 124 | 60.0 | ✅ | r8-characterSelect.png |
| 3 | skillBriefing | 88 | 60.0 | ✅ | r8-skillBriefing.png |
| 4 | difficultySelect | 103 | 60.0 | ✅ | r8-difficultySelect.png |
| 5 | gameEasy 평시 (자동주행, 콤보 24) | 218 (FrameStats 228) | 60.0 | 인게임 ≤300 ✅ | r8-gameEasy.png |
| 6 | gameHardRush 최악 (음표 러시·콤보 6·F 다수) | 272 (FrameStats 281, 사망 연출 순간 275) | 60.0 | ✅ | r8-gameHardRush.png |
| 7 | 일시정지 중 (gameEasy+AUTO_PAUSE) | 230 | 60.0 | 보고 항목 — ≤300이라 P2 불요 (동결 중 fps 무관) | r8-pause.png |
| 8 | resultSuccess | 118 | 60.0 | ✅ | r8-resultSuccess.png |
| 9 | resultDaily | 126 | 60.0 | ✅ | r8-resultDaily.png |
| 10 | resultUnlock | 122 | 60.0 | ✅ | r8-resultUnlock.png |
| 11 | scoreboard | 108 | 60.0 | ✅ | r8-scoreboard.png |
| 12 | scoreboardAchievements | 126 | 60.0 | ✅ | r8-scoreboardAchievements.png |

- 메뉴 최대 126 ≤ 250 / 인게임 최대 281 ≤ 300. fps는 시뮬레이터 측정 한계 인정 — 전 씬 60.0 표기.
- 보조: r8-gameEasy-combo.png (T5 — 콤보 칩 10 + 게이지 + x10 KEEP, 노드 218/228).

## §3. 300줄 전수 표

### 처리 (이관 5파일 → 분할 후 전부 ≤300, wc -l 실측)

| 구 파일 (실측) | 분할 결과 |
|---|---|
| HUDNode.swift 447줄¹ (1파일 2클래스) | HUDNode 161 / **신규** HUDSlotNode 183 / **신규** HUDSlotNode+Display 134 |
| GameScene+Setup.swift 625줄 | +Setup 295 / **신규** +SetupActors 171 / **신규** +DailyModifiers 190 |
| GameScene.swift 502줄 (R7 기록 522 — 불일치 #4, 실측 502 확정) | GameScene 300 / **신규** +UpdatePipeline 215 |
| SpawnSystem.swift 397줄 | SpawnSystem 237 / **신규** +Notes 183 |
| ResultScene+Reveal.swift 304줄 | +Reveal 292 (xpSnapshot → 기존 +Build 이동, +Build 98 — 신규 파일 0) |

¹ SPEC 기재 474줄은 planner 시점 추정 — generator 실측 447 (HUDNode ≈157 + HUDSlotNode ≈290). 분할 방식은 SPEC 지시(2파일) 그대로.

- 전부 **행동 불변 코드 이동만**. 유일 변형 = private→internal 접근 완화 (각 선언부 주석 명기): GameScene 3종(lastComboValue/lastRemainingTimeSecond/lastSentTensionRate — stored라 본체 잔존) + 파이프라인 함수 6종, SpawnSystem 7종(scene/worldNode/registry/noteProvider/progressProvider/comboProvider/noteSpawnTick) + startNoteSpawnLoop/randomOpenMapPosition, HUDSlotNode 6종(backgroundChip/valueNode/timeBarFill/comboGaugeBg/comboGaugeFill/isComboGaugeBlinking).
- update()/touchesBegan 등 @objc override는 전부 본체 잔존 (주의사항 5 — extension override 신규 확산 0).

### 잔존 300 초과 (의도적 보존 — 행동 리스크 / 범위 계약상 분할 금지)

| 파일 | 줄 | 보존 사유 |
|---|---|---|
| Config/GameplayTuning.swift | 807 | Config 상수 파일 예외 (로직 0) + R8 diff 0 게이트 대상 |
| Systems/SkillSystem.swift | 742 | 스킬 4종 상태 머신 — 분할 = 행동 리스크, SPEC 명시 보존 |
| Nodes/PlayerNode.swift | 699 | 이동/wall-slide/픽셀 애니 응집 — 행동 리스크 |
| Config/UILayout.swift | 675 | Config 상수 예외 |
| Models/PixelSprite.swift | 565 | 불변 데이터 (byte-equal 조건 4) |
| Nodes/EnemyNode.swift | 527 | 패트롤/텔레그래프 상태 머신 — 행동 리스크 |
| Managers/FirebaseAuthManager.swift | 504 | 불변 조건 1 (무접촉 — R8은 사유 주석 2줄만) |
| Config/FeelTuning.swift | 468 | Config 상수 예외 |
| Nodes/DiplomaOverlayNode.swift | 374 / Config/ColorTokens.swift 344 / Repositories/CloudProgressRepository.swift 315 | 연출 응집 / Config 예외 / 클라우드 무접촉 |
| Scenes/StartScene.swift | **309** | R8 §C-2-사 겹침 보정 비용으로 295→309 (+14). 추가 분할은 범위 계약 금지(이관 5파일 한정) — **후속 이관 후보 등재** |
| Scenes/CharacterSelectScene.swift | 300 / Nodes/ProfessorNode.swift 302 | 경계치 — CharacterSelect는 R8 수정 후 300 정확, Professor는 기존 302 보존 |

## §4. 삭제 심볼 목록 + grep 0 증빙 (전수 재실측 — 기록 불신 원칙, 주의사항 6)

전 심볼 bare 이름 grep (주석 제외, Shared+iOS): **60종 전부 0건** (SELF_CHECK §T7 표와 동일 측정).

| 분류 | 삭제 심볼 | 비고 |
|---|---|---|
| 컴포넌트 | `PrimaryButtonNode.swift` 파일 + pbxproj 4항목 | 일시정지 v3 재구축 후 참조 0 실증 |
| UILayout primaryButton* 11종 | TextHorizontalPadding/ArrowReservedWidth/Width/Height/FontSize/ShadowOffsetY/ShadowBlurRadius/ArrowRadius/ArrowInsetX/ArrowCircleAlpha/ArrowLabelFontSize | |
| UILayout 기타 12종 | adaptive{Bottom,Top,Horizontal}Margin · authManageButton{Text,BusyText} · backButton{Width,Height,FontSize}(최상위 구 토큰) · profileAvatarFrame{CornerRadius,LineWidth,FillAlpha,StrokeAlpha} | R4.backButtonSize는 별개 현역 |
| UILayout+R4 2종 | cardPortraitSide · cardPortraitOffsetY | 일러스트 교체로 참조 0 도달 후 삭제 (SPEC §2-b) |
| ColorTokens 5색 | ganhoDifficulty{EasyMint,MidGold,MidDeep,HardCoral,HardDeep} | **EasyDeep 보존** — RunButtonNode L28·L97 현역 (불일치 #2 실증) |
| FeelTuning 10종 | newBest* 9종(BlinkActionKey 포함 — 불일치 #3 "9종" 확정) + sparkleParticleRadius | |
| SparkleEffectNode | `.menu` case + 분기 | 단일 case enum 잔존 (switch exhaustive 유지) |
| ZOrder 13종 | newBest · resultShareToast · characterHomeCharacter · profileAvatar{Frame,Content} · accountMenu{Dim,Panel,Label,Button} · profileDetail{Dim,Panel,Label,Button} ZPosition | countdown 3종(countdownZPosition/NodeZPosition/DimZPosition)은 **전부 실사용 — 보존** (CountdownNode L60 / GameScene+Countdown L15·L23) |
| GameScene 프로퍼티 3종 | pauseOverlay · pauseResumeButton · pauseMenuButton → `pauseDialog` 1종 대체 | |
| FeelTuning.R7 1종 | nearMissBonusRadius(22) → nearMissEdgeBand(10) 대체 | 산정 근거 주석 봉인 |

**리네임 2종 (값 byte-불변)**: `glassPillFillAlpha`(0.94) → `profileNameEditFieldFillAlpha` / `overlayButtonDisabledAlpha`(0.48) → `profileNameEditDisabledAlpha` — 선언 + GameViewController 호출부 3곳(L591/L630/L786 상당) 동시 갱신. UserDefaults 키 아님.

**보존 결정 (0참조여도 비삭제)**: `ZOrder.Layer.collectibles` — v3 적층 11층 설계 계약 구성 요소 (부분 삭제 시 층 의미 붕괴, 주석 봉인). `darkContextChip*` 9종 — DarkContextChipNode 현역. 범위 외 0참조 후보(storyBox* 4종·hospitalProp 치수 일부·summaryMetric* 7종·characterHome 잔존 카피·uiRadius 계열 등)는 SPEC §C-2 목록 외 — 미처분, 후속 감사 후보로 기록만.

**부재 확인**: `resultPanel*` — 선언 자체 부재 (R5에서 이미 삭제 — 불일치 #7 확정, Typography 주석 언급 1건뿐).

## §5. v2 컴포넌트 처분 결정표

| 컴포넌트 | 결정 | 근거 |
|---|---|---|
| PrimaryButtonNode | **삭제** | 마지막 섬(일시정지)이 PixelDialogNode+PixelButtonNode로 재구축 — LoginChoiceDialog 전례 동형 |
| DarkContextChipNode | **보존** | 인게임 SkillButton/RunButton 스킬명 칩 현역 — 헤더에 보존 근거 주석 (§C-2-마) |
| SkillButtonNode / RunButtonNode | **보존** | 인게임 현역 — SPEC 범위 금지 명시 |
| HUDNode/HUDSlotNode (v2 시각) | **보존 + 위생 분할** | 인게임 HUD 현역 — R8은 1파일 2클래스만 해소 |
| PixelPortraitSprite (24×24) | **보존 (삭제 금지)** | Start 프로필 칩 아이콘·Scoreboard 행 헤더·일러스트 로드 실패 폴백 현역 (스크린샷 r8-start/r8-scoreboard에 가시) |

## §6. 문서-코드 불일치 정리 (#1~#7 — 코드가 진실)

| # | 기록 | 실측 확정 | 처분 |
|---|---|---|---|
| 1 | REFACTOR_STATE "BOOT_SCENE 9종" | **14종** | docs/debug-flags.md가 진실 원천 |
| 2 | R5 이관 "ganhoDifficulty* 6색 0참조" | **5색만 0참조** (EasyDeep = RunButtonNode 현역) | 5색 삭제·1색 보존 |
| 3 | R5 이관 "newBest* 8종" | **9종** (BlinkActionKey 포함) | 9종 삭제 |
| 4 | R7 기록 "GameScene 522줄" | **502줄** (generator wc -l) | 502 기준 분할 |
| 5 | 02_GAME_FEEL §8 "22px" | 히트박스 가장자리 **10px 셸**로 갱신 (5판 실측 발화 0건 폐기 사유 동반) | 설계서 L140 교체 완료 |
| 6 | swift-rules "print 잔류 금지" vs DEBUG print | **DEBUG 격리 print 허용** 해석 확정 | debug-flags.md §3 명문화 |
| 7 | R5 이관 "UILayout resultPanel*" | **선언 부재** (R5에서 이미 삭제) | 본 보고서에 부재 기록 |
| +8 (R8 신규 발견) | SPEC "HUDNode 474줄(HUDSlotNode 317)" | **447줄(HUDSlotNode ≈290)** | 분할 방식은 SPEC 지시 유지 |
| +9 (R8 신규 발견) | SPEC AUTO_PAUSE 제안값 3.0s | 카운트다운(≈4.2s) 중 발화 → `.playing` 가드 영구 차단 — **8.0s 보정** (시뮬 실측) | FeelTuning.R8 주석 봉인 |

## §7. 실기기 체크리스트 (기록만 — 시뮬 미검증 정직 표기)

| 항목 | 시뮬 상태 | 실기기 확인 필요 |
|---|---|---|
| fps 프로파일 (gameHardRush 45초 풀런) | 시뮬 60.0 고정 표기 — 신뢰 한계 | Instruments(Time Profiler/Core Animation)로 실측 |
| CoreHaptics 체감 (uiTap/nearMiss 0.3/gameOver/heavy) | **시뮬 발화 불가 — 미측정** | 패턴 강도·이중 발화 0(일시정지 버튼) 체감 확인 |
| mirrorWard/fullSpirit 일일 모디파이어 체감 | 코드 경로만 검증(R6) — 당일 시드 한정이라 시뮬 미재현 | 해당 날짜·시드에서 플레이 확인 |
| 클라우드 머지 실 Firestore 왕복 | 시뮬은 로컬 우선 경로만 — **실 네트워크 미검증** | Apple 로그인 + 재설치 머지 시나리오 |
| 일러스트 .linear 스케일 품질 (Retina 3x 실패널) | 시뮬 스크린샷 양호 | 실기기 시야각·해상도 확인 |
| Landscape 양방향 회전·노치 safe area | 시뮬 단일 방향만 캡처 | 좌/우 Landscape 전환 확인 |

## §8. 불변 조건 6항 검증 결과

| # | 조건 | 검증 | 결과 |
|---|---|---|---|
| 1 | Firebase 인증·클라우드 공개 API 시그니처 | git diff — FirebaseAuthManager **주석 2줄만**(§1 default 사유 봉인, SPEC §8-a 지시), CloudSaveCoordinator/Repository diff 0 | ✅ |
| 2 | UserDefaults 키 불변 | StorageKeys.swift **diff 0** + 신규 UserDefaults 키 0 (리네임 2종은 코드 상수명) | ✅ |
| 3 | 게임 골격 (5캐릭터·4빌런·45초·난이도 3종·스킬 4종) | GameplayTuning.swift **diff 0** — 게임플레이 수치 무변경. near-miss는 판정 기하만(보상·물리 무변경) | ✅ |
| 4 | PixelSprite/PixelPalette byte-equal | 두 파일 + PixelPortraitSprite/PixelHeroSprite **diff 0** | ✅ |
| 5 | 번들 ID·서명·Info.plist·iOS 16+·Landscape | pbxproj diff = 소스 파일 등록/제거만 (설정 키 무접촉), Info.plist diff 0 | ✅ |
| 6 | 금지 패턴 전부 유효 | §1 전수 표 — 전 항목 0건 | ✅ |

영속 회귀(T9): 앱 다회 재실행에 걸쳐 별 3/45·총 플레이 7회·kim 하 120점 ★★★·Lv.2 칭호 유지 (r8-scoreboard.png / r8-start.png).

---

**최종 판정: R8 게이트(금지 패턴 grep 전체 0건 + 최종 감사 보고서) 충족. 그랜드 리팩토링 v3 R0~R8 파이프라인 종결 — 출하 잔여 리스크는 §7 실기기 체크리스트로 이관.**
