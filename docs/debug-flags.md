# DEBUG 부팅 분기 · 환경변수 — 단일 진실 원천 (R8)

> **전부 `#if DEBUG` 격리 — 릴리즈 빌드 경로 0.** 릴리즈에서 부팅은 `StartScene` 단일.
> 읽는 위치는 환경변수마다 1곳 — 아래 표가 정확한 소비 지점이다.
> (REFACTOR_STATE의 "GANHO_BOOT_SCENE 9종" 기록은 구식 — 실측 **14종**, 본 문서가 진실.)

## 1. 환경변수 5종 + GANHO_BOOT_SCENE

| 환경변수 | 읽는 위치 | 효과 |
|---|---|---|
| `GANHO_BOOT_SCENE={값}` | `GameViewController.debugBootScene(named:)` | 아래 14값 씬 직행 (스크린샷·QA 자동화). 미해당 문자열은 StartScene 폴백 |
| `PIXELKIT_GALLERY=1` | `GameViewController.viewDidLoad` | PixelKit 컴포넌트 갤러리 씬 부팅 (BOOT_SCENE보다 우선) |
| `GANHO_META_SELFTEST=1` | `GameViewController.viewDidLoad` | 메타 마이그레이션 자가검증 T1~T8 실행 (격리 UserDefaults suite — 실 데이터 무접촉). 콘솔 `[MetaMigrationSelfTest] PASS 8/8` 후 평소 부팅 계속 |
| `GANHO_SKIP_CUTSCENE=1` | `GameScene+Cutscene.resetCutsceneStateAndShowIntro` | 인트로/빌런 컷씬 생략 → 즉시 카운트다운 (simctl 탭 주입 불가 우회) |
| `GANHO_DEMO_AUTOPILOT=1` | `GameScene+MovementInput` (DemoAutopilot, input 단계) | 자동 주행 — 최근접 음표 추적 + 투사체 스침 회피 (콤보 게이지·near-miss 캡처 전용. 게임 수치·판정 0 변경 — 입력 대체만) |
| `GANHO_AUTO_PAUSE=1` (R8 신설) | `GameScene+Cutscene.resetCutsceneStateAndShowIntro` | 진입 8.0s 후 `presentPauseMenu()` 자동 발화 (T6 일시정지 스크린샷 전용 — 카운트다운 ≈4.2s 경과 보정값). **`GANHO_SKIP_CUTSCENE=1` 조합 필수** — `.playing` 가드가 안전망 |

### 조합 예시

```bash
# 인게임 자동 주행 (near-miss·콤보 게이지·페이싱 검증)
# 주의: simctl은 SIMCTL_CHILD_ 프리픽스 환경변수만 자식 프로세스로 전달 (R8 실측 — --setenv 미동작)
SIMCTL_CHILD_GANHO_BOOT_SCENE=gameEasy SIMCTL_CHILD_GANHO_SKIP_CUTSCENE=1 \
SIMCTL_CHILD_GANHO_DEMO_AUTOPILOT=1 xcrun simctl launch booted com.hyungyu.GanhoMusic

# 일시정지 v3 스크린샷 (게임 시작 후 자동 일시정지 — 카운트다운 포함 8초 후 발화)
SIMCTL_CHILD_GANHO_BOOT_SCENE=gameEasy SIMCTL_CHILD_GANHO_SKIP_CUTSCENE=1 \
SIMCTL_CHILD_GANHO_AUTO_PAUSE=1 xcrun simctl launch booted com.hyungyu.GanhoMusic
```

## 2. GANHO_BOOT_SCENE 14값 (GameViewController.debugBootScene)

| 값 | 직행 씬 | 픽스처 | 용도 |
|---|---|---|---|
| `characterSelect` | CharacterSelectScene | 실 데이터 | 선택창 캐러셀·일러스트·잠금 상태 |
| `skillBriefing` | SkillBriefingScene | jung 고정 | 브리핑 카드(플립 인)·패널 |
| `difficultySelect` | DifficultySelectScene | kim 고정 | 난이도 3카드 |
| `startLogin` | StartScene | openLoginChoiceOnEntry=true | 로그인 다이얼로그 |
| `resultSuccess` | ResultScene | 87점/신기록/kim/normal | 성공 연출 시퀀스 |
| `resultFail` | ResultScene | 41점/jung/normal | 유급 verdict·부족 칩 |
| `scoreboard` | ScoreboardScene | 실 데이터 | 기록 테이블 |
| `scoreboardAchievements` | ScoreboardScene | initialTab=.achievements | 업적 탭 |
| `gameHardRush` | GameScene | kim/hard/noteRush | 최악 노드 수·fps 측정 |
| `gameLightsOut` | GameScene | kim/normal/lightsOut | 소등 비네트 시각 확인 |
| `resultDaily` | ResultScene | 일일 최초 클리어+업적 2종 픽스처 | 일일 클리어 칩·업적 칩 |
| `resultUnlock` | ResultScene | geon 해금+업적 2종 픽스처 | 해금 배너·업적 토스트 연출 |
| `gameEasy` | GameScene | kim/easy/모디파이어 nil | 일반 판 (AUTOPILOT/AUTO_PAUSE 조합 베이스) |
| `characterSelectProfile` | CharacterSelectScene | openProfileOnEntry=true | 프로필 다이얼로그 직행 |

## 3. DEBUG print 정책 (swift-rules 해석 확정 — R8)

`docs/swift-rules.md`의 "print 잔류 금지"는 **릴리즈 경로 기준**이다. `#if DEBUG`로 격리된
print는 허용 — QA 게이트의 콘솔 증빙(`[NearMiss]`·`[FrameStats]`·`[MetaMigrationSelfTest]`·
`[ResultScene]`·`[ObjectPool]`·`[Typography.V3]`)이 이 채널을 쓴다 (문서-코드 불일치 #6 해소).
R8 전수 감사 결과 비-DEBUG print 0건 (R8_FINAL_AUDIT §1).

## 4. 기타 DEBUG 전용 장치

| 장치 | 위치 | 효과 |
|---|---|---|
| `FrameStats` | `Core/FrameStats.swift` + GameScene+Setup | 좌상단 프레임/노드 진단 라벨 (`FrameStats.isEnabled` 코드 토글) |
| `showsFPS` / `showsNodeCount` | GameViewController.viewDidLoad | SKView 우하단 시스템 진단 (성능 표 측정 채널) |
| `MetaProgression.debugAuditAlignment()` | ResultScene.didMove | 별 임계/verdict 정합 자가검증 assert |
| PixelButtonNode 섀도 정합 assert | PixelButtonNode.init | v3 눌림 토큰 정합 위반 시 즉시 중단 |
