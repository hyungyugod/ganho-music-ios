# QA 검수 보고서 — iPhone Landscape 잘림 해소 + 캐릭터 카드 분리감 강화 + 얼굴 SVG 동기화

## SPEC 기능 검증

- **PASS** 기능 1 — `SceneSafeArea` 헬퍼 (`Config/SceneSafeArea.swift:21-27`): `enum SceneSafeArea` + `?? .zero` 안전 폴백. import UIKit 명시. SPEC 코드 구조와 1:1 일치. 위치는 SPEC가 `Utilities/`였으나 `Config/`로 이동 — SELF_CHECK에서 정당화(synchronized root group 인식 불가 → 빌드 가능성 위해 필수 연동 변경). 호출처 무영향.
- **PASS** 기능 2 — `GameViewController.viewSafeAreaInsetsDidChange()` (`GameViewController.swift:65-73`): `// MARK: - SafeArea Policy` 섹션 신설 + super 호출 + 정책 주석. 본문에 frame 조작 0건. SKView frame 미터치 절대 원칙 준수.
- **PASS** 기능 3 — GameConfig 상수: 신규 7개(`adaptiveBottomMargin=24`, `adaptiveTopMargin=16`, `adaptiveHorizontalMargin=20`, `startButtonBottomInset=64`, `resultButtonBottomInset=56`, `characterSelectMinCardSpacing=28`, `characterSelectMaxCardSpacing=56`) 모두 추가 (line 1799-1816). 갱신 6개(`characterCardWidth=76`, `characterCardHeight=104`, `characterFaceScale=0.82`, `characterCardGlassWidth=156`, `characterCardGlassHeight=204`, `characterSelectCardZigzagOffsetV3=6`) 모두 정확. 보존 상수(`startSceneStartButtonOffsetY=-180`, `resultButtonOffsetYV2=-180`, `characterSelectCardSpacingV3=22`) 값 유지.
- **PASS** 기능 4 — `StartScene.layoutStartButton()` (`StartScene.swift:238-245`): `frame.minY + safe.bottom + GameConfig.startButtonBottomInset` 식으로 교체.
- **PASS** 기능 5 — `ResultScene.layoutLabels()` (`ResultScene.swift:537-549`): shareButton/restartButton만 safe area 식으로 교체. 다른 라벨은 frame.midY 기반 유지.
- **PASS (조건부)** 기능 6 — `CharacterSelectScene` 동적 spacing (`CharacterSelectScene.swift:380-399`): usable 폭 계산 + min/max clamp 패턴 SPEC 그대로. **단 매직 넘버 잔존(P1 §1)**.
- **PASS** 기능 7 — CharacterFaceNode 재이식: 5명 모두 `// 기준 SVG: ...` 주석 추가. jung 완전 재작성(핑크 캡 + 안경 + 땀방울). geon 완전 재작성(어두운 머리 + 위 tuft + 큰 둥근 눈 + 흰 highlight). im 부분 재이식(수염 제거 + 큰 둥근 눈). lee 부분 재이식(강아지귀 제거 + side curls + 닫힌 눈). kim 변경 0(주석만).

## 빌드 검증

- **결과**: BUILD SUCCEEDED (iPhone 17 Pro 시뮬레이터, Debug)
- **추가**: BUILD SUCCEEDED (iPhone 17 Pro Max 시뮬레이터, Debug)
- iPhone SE 시뮬레이터 미설치(skip). 회귀 위험 낮음(동적 min clamp 28pt 작동 보장).
- 컴파일 에러 0건.

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 1건 |
| P2 권장 | 2건 |

## P0 — 치명적 이슈

없음.

## P1 — 중요 이슈

### 1. layoutConfirmButton / layoutSkillInfoChip 매직 넘버 3건 (SPEC 합격 기준 위반)

- **파일**: `GanhoMusic Shared/Scenes/CharacterSelectScene.swift:328, 355, 358`
- **위반 규칙**: SPEC §합격 기준 §빌드/패턴 "매직 넘버 0건 — 모든 새 좌표가 GameConfig 상수 참조".
- **현재 코드**:
  ```swift
  // line 328 (layoutConfirmButton)
  y: frame.minY + safe.bottom + GameConfig.adaptiveBottomMargin + 40
  // line 355 (layoutSkillInfoChip)
  let confirmY = frame.minY + safe.bottom + GameConfig.adaptiveBottomMargin + 40
  // line 358
  y: confirmY + 36
  ```
- **수정 제안**: GameConfig에 두 상수 추가 후 참조.
  ```swift
  static let characterSelectConfirmButtonBottomInset: CGFloat = 40
  static let characterSelectSkillInfoChipAbove: CGFloat = 36
  ```
  + layoutSkillInfoChip에서 `confirmButton.position.y` 직접 참조로 DRY 회복.

## P2 — 권장 사항

### 1. layoutSkillInfoChip이 layoutConfirmButton의 식을 중복 계산 (DRY 위반)
`CharacterSelectScene.swift:352-360`. `confirmButton.position.y` 참조로 단순화.

### 2. geon 빌드 함수에 buildNurseCap() 호출 잔존
`CharacterFaceNode.swift:450`. SPEC §기능7 표에 너스캡 명시 없음. 시뮬레이터에서 SVG와 1:1 시각 비교 후 제거 여부 판단.

## 통과 항목

- SceneSafeArea 안전 폴백 패턴(`?? .zero`)
- GameViewController SKView frame 미터치 (2026-05 사고 회피 준수)
- GameConfig 상수 추가/갱신/보존 정책 정확
- StartScene/ResultScene safeArea 회피 패턴
- CharacterSelectScene 동적 spacing (28~56pt clamp)
- CharacterFaceNode 5명 재이식 (jung/geon 완전, im/lee 부분, kim 변경 0)
- 강제 언래핑 / Timer / DispatchQueue / as! / try! 모두 0건
- MARK 섹션 + 의도 주석 풍부
- pbxproj 변경 — SceneSafeArea 등록 4 entry만
- 회귀 방지 — GameScene/DifficultySelectScene/SkillExplanationScene/PlayerNode/CharacterID/CharacterCardNode 변경 0건
- iPhone 17 Pro + iPhone 17 Pro Max 빌드 모두 SUCCEEDED
- 학습 노트 작성 (`docs/learn/2026-05-19-device-safe-area-and-card-layout.md`)

## 회귀 위험 평가

- GameScene/PlayerNode/DifficultySelectScene/SkillExplanationScene 미수정 → 게임플레이 회귀 0
- CharacterCardNode 내부 미수정 → 외부 GameConfig 치수만 흡수 → 자동 확대 작동
- CharacterID 미수정 → 5명 식별 회귀 0
- alpha=0 라벨 보호 가드 보존(ResultScene)
- 보존 상수 정책 유지(`startSceneStartButtonOffsetY` 등)

## 사용자 시각 검증 권장 항목

1. iPhone 17 Pro Landscape: StartScene "시작" 버튼 잘림 X / CharacterSelect 5장 분리감 / ResultScene 두 버튼 잘림 X
2. iPhone 17 Pro Max: 카드 spacing이 56pt clamp 작동
3. iPhone SE: 카드 5장이 화면 폭 안에 들어가는가 (28pt 최소 보장)
4. SVG 1:1 시각 비교: jung 핑크 캡 / geon 위 tuft + 큰 눈 (너스캡 검토) / im 큰 눈 + 수염 없음 / lee 강아지귀 없음 + 닫힌 눈
5. 회전 테스트: didChangeSize → layoutXxx 재호출 작동(safeArea 재반영)

## 채점

- Swift 패턴 일관성: **7.5/10** (강제 언래핑 0, MARK·주석 우수, 매직 넘버 3건)
- 게임 로직 완성도(SpriteKit): **9.0/10** (didChangeSize 보존, frame 미터치, safeArea 일관성)
- 성능 & 안정성: **9.5/10** (양쪽 디바이스 빌드 SUCCEEDED, 안전 폴백)
- 기능 완성도: **9.0/10** (SPEC 7개 + 학습 노트 모두 구현)

**가중 점수**: (7.5×0.35) + (9.0×0.30) + (9.5×0.20) + (9.0×0.15) = **8.6/10**

## 최종 판정: **합격** (7.0 이상)

### 2회차 정밀 적용 결과 (Generator 재실행 후)

- P1 §1 매직 넘버 3건 토큰화 — **완료**
  - `GameConfig.swift:1819,1821`에 `characterSelectConfirmButtonBottomInset = 40`, `characterSelectSkillInfoChipAbove = 36` 추가
  - `CharacterSelectScene.swift:329` `layoutConfirmButton()` → 상수 참조
  - `CharacterSelectScene.swift:361` `layoutSkillInfoChip()` → `confirmButton.position.y` 직접 참조 (DRY 회복, P2 §1 동시 해소)
  - grep 검증: `+ 40`, `+ 36` 리터럴 0건
- 빌드: BUILD SUCCEEDED (iPhone 17 Pro)
- 회귀: SceneSafeArea/GameViewController/StartScene/ResultScene/CharacterFaceNode 변경 0건 / cardBaseX·cardBaseY 변경 0건

### 2회차 갱신 후 점수

- Swift 패턴 일관성: **9.0/10** (매직 넘버 0건 달성)
- 게임 로직(SpriteKit): **9.5/10** (DRY 회복, layoutSkillInfoChip이 confirm 좌표 직접 참조)
- 성능 & 안정성: 9.5/10 (변동 없음)
- 기능 완성도: 9.0/10 (P2 §2 geon 너스캡은 사용자 시각 검증 대기)

**최종 가중 점수**: (9.0×0.35) + (9.5×0.30) + (9.5×0.20) + (9.0×0.15) = **9.25/10**

### 남은 권고 (이번 작업 외 별도 결정)

- **P2 §2 geon 너스캡** — `CharacterFaceNode.swift:450` `buildNurseCap()` 호출 유지 여부는 사용자가 시뮬레이터에서 `mockups/svg-exports/geon.svg`와 1:1 시각 비교 후 결정. 본 사이클 변경 보류.
