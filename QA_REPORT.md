# QA 검수 보고서 — Phase 7-4 졸업장 시스템

## SPEC 기능 검증

| # | 기능 | 결과 |
|---|---|---|
| 1 | GameConfig Diploma 섹션 22 상수 | PASS — L568-624, MARK 포함, 기존 미접촉 |
| 2 | PerDifficultyScoreRepository | PASS — JSON `[String:[String:Int]]`, rawValue 키, try? graceful |
| 3 | GraduationRepository | PASS — ISO8601 .withInternetDateTime, 멱등 가드 |
| 4 | GameScene.isGraduated 헬퍼 | PASS — Difficulty.allCases 순회, ?? Int.max 폴백 |
| 5 | DiplomaOverlayNode 자가 소멸 11호 | PASS — SelfDismissingNode 채택, 2중 안전망 dismiss |
| 6 | GameScene.endGame 5줄 + factory 2인자 | PASS — HighScoreRepository 병행 유지 |
| 7 | ResultScene factory default 인자 | PASS — 회귀 0 |
| 8 | pbxproj 4지점 등록 | PASS — iOS 타겟만, tvOS/macOS 빈 채 |

## 원본 텍스트 검증 (game.js 단일 진실 원천)

| 항목 | 원본 (L75-95) | 구현 | 결과 |
|---|---|---|---|
| title_en | "CERTIFICATE OF GRADUATION" | DiplomaOverlayNode L65 | 일치 |
| title_ko | "실습 수료 증서" | L66 | 일치 |
| body1 template | "다사다난한 실습을 마치고 {NAME}는 드디어 졸업하였다." | L67 | 일치 (치환 후) |
| body2 | "이제 세상이라는 악보 위에 마음껏 노래를 부르며 자유롭게 살 것이다." | L71 | 일치 |
| issuer | "hgfolio · 김간호는 음악박사" | L72 | 일치 (가운뎃점 U+00B7) |
| TARGET_SCORE | { easy:60, normal:50, hard:30 } | GameConfig.swift:572-574 | 일치 |
| {NAME} 치환 | `replacingOccurrences(of: "{NAME}", with: characterName)` | DiplomaOverlayNode | 일치 |

## 빌드 검증
- **BUILD SUCCEEDED**
- Swift 경고/에러 0건

## 정적 검사
- 강제 언래핑 / `try!` / `as!` — 0건
- Timer / DispatchQueue — 0건
- 매직 넘버 — 0건 (DiplomaOverlayNode 모든 수치 GameConfig.diploma* 참조)
- 옵셔널 처리 — guard let / if let / `??` 폴백

## 회귀 0 영역 git diff 0줄
- HighScoreRepository / StatisticsRepository / CharacterPreferenceRepository / DifficultyPreferenceRepository
- HUDNode / 자가 소멸 10호까지 / 모든 캐릭터·적·노트·F·DPad·카드 노드
- ContactRouter / ScoreSystem / SpawnSystem / CameraShake
- BGMPlayer / AudioManager / HapticsManager
- ColorTokens / PhysicsCategory / GameState
- CharacterID / Difficulty / GameStats / Protocols / Errors
- TitleScene / GameScene+Setup
- iOS·tvOS·macOS 진입점

수정된 Swift 파일은 4개 (GameConfig / GameScene / ResultScene + 신규 3)만.

## SPEC 주의사항 12개 모두 준수
ISO8601 / try? graceful / enum→rawValue 직렬화 / 멱등 record / 빈 onDismiss / 점수 두 저장소 병행 / Date 영원 동일 / factory default / parent=scene + (midX,midY) / diplomaTapFontSize 별도 / SelfDismissingNode 마커 / encode 실패 graceful

## SPEC 금지 6개 모두 준수
졸업장 다시 보기 미구현 / 이미지 저장 미구현 / TitleScene 뱃지 미구현 / 매트릭스 시각화 미구현 / HighScoreRepository 병행 유지 / 캐릭터 픽셀 아바타 없음

## P0 / P1 / P2: **0 / 0 / 0 건**

## 채점
- Swift 패턴 일관성: **10/10** (35%)
- 게임 로직 완성도: **10/10** (30%)
- 성능 & 안정성: **10/10** (20%)
- 기능 완성도: **10/10** (15%)

**가중 점수: 10.0 / 10.0**

## 최종 판정: **합격**

구체적 개선 지시: 없음. 원본 텍스트 한 글자 오차 0, 멱등 가드("일시 영원 동일") 코드 레벨 강제, factory default 인자 회귀 0 자연 차단.
