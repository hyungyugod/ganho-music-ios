# QA 검수 보고서 — Phase 10-1 시작 시퀀스 4단계 오버레이 분리

## SPEC 기능 검증

| # | 기능 | 결과 | 근거 |
|---|---|---|---|
| 1 | StartScene 신설 — 제목+부제+BEST/PLAYS+스토리박스+난이도 3장+시작 버튼 | PASS | `StartScene.swift:17-236` |
| 1a | isTransitioning 가드 | PASS | `StartScene.swift:21, 206, 226` |
| 1b | setupOverlayPanel 패턴 답습 | PASS | `StartScene.swift:69-89` |
| 1c | touchesBegan 우선순위 (난이도 → 시작) | PASS | `StartScene.swift:205-220` |
| 1d | "어디든 탭" 패턴 제거 | PASS | 무동작 fall-through |
| 2 | CharacterSelectScene — 헤더+5장+태그+뒤로/시작 | PASS | `CharacterSelectScene.swift:17-258` |
| 2a | init(size:difficulty:characterID:) 불변 인자 | PASS | `CharacterSelectScene.swift:48-51` |
| 2b | 김간호 분기 → GameScene 직진 | PASS | `CharacterSelectScene.swift:242-248` |
| 2c | 그 외 → SkillExplanationScene | PASS | `CharacterSelectScene.swift:249-255` exhaustive |
| 2d | 태그 라벨 카드 외부 | PASS | `CharacterSelectScene.swift:145-176` |
| 3 | SkillExplanationScene — 아바타+스킬명+박스+안내+버튼 | PASS | `SkillExplanationScene.swift:17-238` |
| 3a | PixelSpriteRenderer 인프라 재사용 (0 변경) | PASS | `SkillExplanationScene.swift:56-67` |
| 3b | PlayerSkill.fullDescription 사용 | PASS | `SkillExplanationScene.swift:29` |
| 3c | StoryBoxNode 재사용 | PASS | `SkillExplanationScene.swift:28-29` |
| 4 | StoryBoxNode — 자동 줄바꿈 | PASS | `StoryBoxNode.swift:64-67` |
| 5 | PrimaryButtonNode/BackButtonNode — contains hit-test, 색만 다름 | PASS | 캡슐 cornerRadius=height/2 동형 |
| 6 | CharacterID.tag — 5 case exhaustive | PASS | `CharacterID.swift:67-75` |
| 7 | PlayerSkill.fullDescription — 5 case exhaustive | PASS | `PlayerSkill.swift:78-86` |
| 8 | GameScene 분기 (showIntroCutscene + hasSeenIntro + 새 메서드) | PASS | `GameScene.swift:171-182, 217-220, 230-242` |
| 8a | showProfessorWarningCutscene 미러 | PASS | `:230-242` vs `:248-260` |
| 8b | 게임 루프/contact/skill/setup 0줄 변경 | PASS | diff에서 cutscene만 |
| 9 | GameViewController 1줄 (TitleScene → StartScene) | PASS | `:28` |
| 10 | ResultScene 1줄 ("타이틀로" → StartScene) | PASS | `:281` |
| 11 | GameConfig 매직 넘버 0, 상수화 | PASS | `:947-1042` ~30개 |
| 12 | TitleScene.swift 완전 삭제 | PASS | find 0건 |

## 빌드 검증

- **결과**: BUILD SUCCEEDED
- 명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- 경고/에러: 0건

## 회귀 방지 검증

| 영역 | 결과 |
|---|---|
| GameScene 게임플레이 (update/contact/skill/setup) | 0줄 PASS |
| ResultScene 내부 로직 | 0줄 (외부 신호 1줄만 — 필수 연동) PASS |
| CharacterCardNode 내부 | 0줄 PASS |
| DifficultyCardNode 내부 | 0줄 PASS |
| CutsceneOverlayNode | 0줄 PASS |
| PixelSpriteRenderer/PixelSprite/PixelPalette | 0줄 PASS |
| Repositories | 0줄 PASS |
| switch default | 0건 PASS |
| Timer/DispatchQueue | 0건 PASS |
| 강제 언래핑 | 0건 PASS |
| [weak self] 캡처 | 5/5 PASS |
| guard let view = self.view | 5/5 PASS |

## 이슈 카운트

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 2건 (감점 미반영) |

### P2 권장 (선택적 폴리싱)
1. StartScene `_ = characterRepo` unused 흔적 — 향후 sprint에서 프로퍼티 삭제 또는 BEST 옆 캐릭터 안내로 재활용 검토
2. setupOverlayPanel 3씬 중복 — 향후 `OverlayPanelNode` 추출 검토 (현재는 *동형 시각 보장* 의도된 중복)

## 채점

| 항목 | 가중치 | 점수 |
|---|---|---|
| Swift 패턴 일관성 | 30% | 10/10 |
| 게임 로직 완성도 | 25% | 10/10 |
| 성능 & 안정성 | 20% | 10/10 |
| 기능 완성도 | 25% | 10/10 |

**가중 점수**: 10 × 0.30 + 10 × 0.25 + 10 × 0.20 + 10 × 0.25 = **10.0 / 10**

## 최종 판정: 합격

대규모 UI 재설계임에도 회귀 방지 약속(GameScene 게임플레이 0줄, ResultScene 내부 0줄, 인프라 0줄)을 100% 지킴. 새 추상화 3개 + 새 씬 3개 모두 *기존 패턴 답습*. 빌드 클린.

## 시각적 확인 사항

### 단계 1 — 앱 진입 (StartScene)
- 코럴 톤 카드 패널 + 제목 + 부제
- 상단 BEST/PLAYS 갱신
- 스토리 박스 자동 줄바꿈
- 난이도 카드 3장 탭 선택
- "시작" 버튼 코럴 fill

### 단계 2 — CharacterSelect
- 헤더 "함께할 친구를 골라요"
- 5 캐릭터 카드 + 태그 라벨 ("번머리 실습생" 등)
- "← 난이도 다시" / "이 친구로 시작"
- 김간호 → 스킬 씬 스킵 → GameScene 직진
- 정/건/임/이 → SkillExplanationScene

### 단계 3 — SkillExplanation
- 큰 픽셀 아바타 (120×150, nearest filter)
- 스킬명 + 본문 박스 + 조작 안내
- "← 캐릭터 다시" / "시작"

### 단계 4 — GameScene 진입
- 1회차 easy/normal: 인트로 → 석조무사 경고 → 카운트다운
- 1회차 hard: 인트로 → 이교수 경고 → 카운트다운 (기존)
- 2회차+ easy/normal: 인트로 스킵 → 석조무사 경고 → 카운트다운 (매 판 환기)
- 게임 플레이 자체 회귀 0
