# 자체 점검 — iPhone Landscape 잘림 해소 + 캐릭터 카드 분리감 강화 + 얼굴 SVG 동기화

전략: Case A (최초 시도) — SPEC 직접 적용.

## SPEC 기능 체크

- [x] **기능 1**: `SceneSafeArea` 헬퍼 신설 — `Config/SceneSafeArea.swift`로 신설 (SPEC는 `Utilities/`였으나 PBXFileSystemSynchronizedRootGroup이 새 폴더를 인식하지 않아 위치 변경 — 자세한 내용은 §pbxproj 등록 참조). 코드 내용은 SPEC 그대로(`view.safeAreaInsets ?? .zero`).
- [x] **기능 2**: `GameViewController.viewSafeAreaInsetsDidChange()` override — super 호출 + 정책 주석. SPEC §기능2 그대로.
- [x] **기능 3**: `GameConfig` 신규 상수 7개 + 기존 6개 값 갱신:
  - 신규: `adaptiveBottomMargin=24`, `adaptiveTopMargin=16`, `adaptiveHorizontalMargin=20`, `startButtonBottomInset=64`, `resultButtonBottomInset=56`, `characterSelectMinCardSpacing=28`, `characterSelectMaxCardSpacing=56`
  - 갱신: `characterCardWidth: 48→76`, `characterCardHeight: 60→104`, `characterFaceScale: 0.55→0.82`, `characterCardGlassWidth: 110→156`, `characterCardGlassHeight: 140→204`, `characterSelectCardZigzagOffsetV3: 8→6`
  - 주의: 기존 `characterCardGlassWidth/Height` 코드값은 110/140이었고 SPEC 표에는 124/166이었으나 SPEC가 명시한 최종 값 156/204로 갱신
- [x] **기능 4**: `StartScene.layoutStartButton()` safeArea 회피로 교체.
- [x] **기능 5**: `ResultScene.layoutLabels()` 끝부분 shareButton/restartButton 두 줄 safeArea 기반 교체. 다른 라벨 위치는 0건 변경.
- [x] **기능 6**: `CharacterSelectScene`:
  - `cardBaseX(for:)` 동적 spacing 계산 (usable 폭 비례 + min/max clamp) 적용
  - `layoutConfirmButton()` y좌표 `frame.minY + safe.bottom + adaptiveBottomMargin + 40`으로 교체
  - `layoutSkillInfoChip()` y좌표 = confirmY + 36 (상대 좌표)으로 교체
  - 카드 하단 충돌 검산: 카드 하단 ≈ `frame.midY + 88`, confirm 버튼은 `frame.minY + safe.bottom + 64`(약 frame.midY 아래)로 충돌 없음
- [x] **기능 7**: `CharacterFaceNode` SVG 재이식:
  - **kim**: 변경 0 (SVG 시각 형태와 일치) — 주석만 추가 `// 기준 SVG: kim.svg (v1)`
  - **jung**: **완전 재작성** — 핑크 러닝캡(#FF8E80) + 짙은 코랄 챙(#C44A3D) + 흰색 로고 원 + 둥근 안경(원형 + 흰빛) + 결연한 눈썹 + 땀방울(#9BCDF0) + 태양에 그을린 볼터치(#E87B6A). 스파이크 머리/곡괭이/헤드밴드 모두 제거.
  - **geon**: **완전 재작성** — 단순 어두운 머리(#1F1410) + 위 머리 한 점 tuft + 큰 둥근 검은 눈(타원 9×12) + 흰 highlight + 작은 미소. 안경/책 제거.
  - **im**: **부분 재이식** — 수염 제거 + 고양이눈→큰 둥근 눈 교체(타원 10×13) + 가운데 가르마 V자 path 갱신. 긴머리/작은 고양이귀/분홍 코는 유지.
  - **lee**: **부분 재이식** — 강아지귀 제거 + 동그란 눈→닫힌 눈 path 교체 + 혀 제거 + side curls + curl detail dots 4개 + 앞머리 텍스처 점 추가.
  - 각 빌드 함수 시작에 `// 기준 SVG: mockups/svg-exports/<id>.svg (vN)` 주석 1줄 추가.
- [x] **학습 노트**: `docs/learn/2026-05-19-device-safe-area-and-card-layout.md` 작성 — Spring Boot 비유 + 중학생 수준 4섹션.

## 빌드 검증 결과

```bash
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**결과**: `** BUILD SUCCEEDED **` ✅

- 경고: Resources/Fonts/*.ttf duplicate build file 3건 — 기존 경고, 본 작업과 무관
- 미사용 raw color tokens (`pickHandle`, `pickHead`, `bandDot`, `bookCover`)이 코드에 남아 있으나 컴파일 에러 없음 — 향후 호환을 위해 보존

## 수정한 파일 목록 + 라인 수

| 파일 | 변경 유형 | 라인 수(대략) |
|---|---|---|
| `GanhoMusic/GanhoMusic Shared/Config/SceneSafeArea.swift` | **신규** | 27 |
| `GanhoMusic/GanhoMusic iOS/GameViewController.swift` | 추가 (1 메서드) | +10 |
| `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift` | 갱신 + 신규 24행 | +30 |
| `GanhoMusic/GanhoMusic Shared/Scenes/StartScene.swift` | layoutStartButton만 | +9 |
| `GanhoMusic/GanhoMusic Shared/Scenes/ResultScene.swift` | layoutLabels 끝 4줄 | +5 |
| `GanhoMusic/GanhoMusic Shared/Scenes/CharacterSelectScene.swift` | 3 메서드 | +30 |
| `GanhoMusic/GanhoMusic Shared/Nodes/CharacterFaceNode.swift` | 4 빌드함수 재작성, kim 주석 | ±300 |
| `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj` | SceneSafeArea 명시 등록 | +4 |
| `docs/learn/2026-05-19-device-safe-area-and-card-layout.md` | **신규 학습 노트** | 130 |

## CharacterFaceNode 재이식 캐릭터 목록

- ✅ **kim** — 변경 0 (시각 일치 확인). 주석만 추가.
- ✅ **jung** — 완전 재작성 (핑크 캡 + 안경 + 땀방울).
- ✅ **geon** — 완전 재작성 (큰 둥근 눈 + tuft).
- ✅ **im** — 부분 재이식 (수염 제거 + 큰 눈 + 가르마).
- ✅ **lee** — 부분 재이식 (강아지귀 제거 + 닫힌 눈 + side curls).

## Xcode pbxproj 등록 결과

**자동 등록 실패 → 수동 등록 완료.**

### 발견 사항

이 프로젝트는 `PBXFileSystemSynchronizedRootGroup`(Xcode 16 자동 동기화)을 쓰지만, 동시에 `PBXGroup`(명시 등록)도 함께 쓴다. 새 폴더(`Utilities/`)를 만들었을 때 동기화 그룹이 **자동 인식하지 못해** 빌드에 누락됐다.

### 해결

1. SceneSafeArea.swift를 `Utilities/` → `Config/`로 이동 (Config는 PBXGroup으로 명시 등록되어 있음).
2. `project.pbxproj`에 4 entry 수동 추가:
   - PBXBuildFile (id `A1C0F1B00000000000000073`)
   - PBXFileReference (id `A1C0F1A00000000000000073`)
   - PBXGroup `Config` children에 추가
   - PBXSourcesBuildPhase iOS 타겟에 추가
3. clean build → `BUILD SUCCEEDED`.

### SPEC 외 변경 사유

SPEC §변경 범위는 `Utilities/SceneSafeArea.swift` 신규를 명시했으나, 실제 빌드를 위해 `Config/SceneSafeArea.swift`로 위치 변경. **이 변경이 없으면 SPEC 기능이 동작하지 않는다** (빌드 자체가 실패하면 SceneSafeArea 호출이 컴파일되지 않음) → 필수 연동 변경으로 판단.

## Swift 패턴 준수

- 강제 언래핑 미사용: ✅ (`?? .zero`로 폴백, 모두 `guard let`/`if let`)
- guard let 옵셔널 처리: ✅
- MARK 섹션 구분: ✅ (`// MARK: - Adaptive Layout`, `// MARK: - SafeArea Policy` 추가)
- GameConfig 상수 사용: ✅ (모든 새 좌표가 GameConfig 상수 참조)
- weak self 캡처: ✅ (해당 시 — 본 작업은 클로저 캡처가 거의 없음)

## SpriteKit 패턴 준수

- `didChangeSize(_:)` → `layoutXxx()` 재호출 보존: ✅ (StartScene/ResultScene/CharacterSelectScene 모두)
- scaleMode `.resizeFill` 보존: ✅
- 초기화는 `didMove(to:)`에 보존: ✅
- SKView frame **건드림 0건**: ✅ (GameViewController는 super 호출만)
- 충돌 후 노드 즉시 삭제 없음: ✅ (본 작업은 물리 충돌 영역 무관)

## 빌드 상태

- 빌드: **SUCCEEDED** (iPhone 17 Pro 시뮬레이터)
- 빌드 에러: **없음**
- 주의 필요 경고: Fonts duplicate build file 3건 — 본 작업 무관, 기존 상태

## 알려진 제약 / 다음 단계

1. **CharacterFaceNode 시각 검증 필요**: 코드로 그린 SVG가 카드(76×104) 안에 자연스럽게 들어가는지 시뮬레이터에서 확인 권장. 좌표 스케일이 작은 좌표계(±32~±44)이므로 큰 비율 문제는 없을 것.
2. **미사용 raw color tokens**: jung 재작성으로 `pickHandle`, `pickHead`, `bandDot`이 미사용 상태. geon 재작성으로 `bookCover`도 미사용. 향후 호환을 위해 보존 — Swift 컴파일러는 `private static let` 미사용에 에러를 내지 않음.
3. **SceneSafeArea 위치**: SPEC는 `Utilities/`였으나 `Config/`로 변경됨. SPEC 외 변경이지만 빌드 가능성 위해 필수. 호출 측은 동일하므로 사용처 회귀 0.
4. **iPhone SE 빌드 미검증**: SPEC §검증 절차는 SE/17 Pro/Pro Max 3종을 요구했으나 본 검증은 iPhone 17 Pro만 빌드 성공 확인. SE/Pro Max는 시뮬레이터 미설치 가능성 — 실제 시각 검증은 별도 진행.

## 범위 외 미구현 항목

- 없음. SPEC 7개 기능 + 학습 노트 모두 구현 완료.
- 단, SceneSafeArea 위치(Utilities → Config)는 SPEC 위반이나 빌드 가능성 위해 필수 변경.

---

## 2차 갱신 (QA 피드백 반영)

전략: Case A (가중 8.6/10 합격) — 같은 방향 유지, QA §P1 §1 정밀 적용.

### 변경 파일 (2개만)

| 파일 | 변경 |
|---|---|
| `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift` | `characterSelectConfirmButtonBottomInset=40`, `characterSelectSkillInfoChipAbove=36` 신규 추가 (Adaptive Layout 섹션 끝) |
| `GanhoMusic/GanhoMusic Shared/Scenes/CharacterSelectScene.swift` | `layoutConfirmButton()` `+40` → 신규 상수 참조 / `layoutSkillInfoChip()` 중복 계산 제거(`confirmButton.position.y + 상수` 직접 참조 — DRY 회복) |

### 매직 넘버 0건 달성 확인

QA가 지적한 3건 모두 해소:
- `CharacterSelectScene.swift:328` `+ 40` → `+ GameConfig.characterSelectConfirmButtonBottomInset`
- `CharacterSelectScene.swift:355` `let confirmY = ... + 40` → **식 자체 제거**, `confirmButton.position.y` 참조로 교체
- `CharacterSelectScene.swift:358` `confirmY + 36` → `confirmButton.position.y + GameConfig.characterSelectSkillInfoChipAbove`

→ `layoutConfirmButton`/`layoutSkillInfoChip` 두 함수 안의 모든 좌표 리터럴이 `GameConfig` 상수로 토큰화.

### 호출 순서 검증 결과 (confirmButton.position 보장)

- **didMove(to:)** line 84-85: `setupConfirmButton()`(내부에서 `layoutConfirmButton()` 호출) → `rebuildSkillInfoPanel(for:)`(내부에서 `layoutSkillInfoChip()` 호출). 안전.
- **didChangeSize(_:)** line 98-99: `layoutConfirmButton()` → `layoutSkillInfoChip()`. 안전.
- **선택 변경 경로** line 424: `rebuildSkillInfoPanel(for:)` 단독 호출. didMove 이후에만 호출 가능하므로 `setupConfirmButton`을 이미 거친 상태 — `confirmButton.position`이 보장됨. 안전.
- `confirmButton`은 옵셔널이 아님(line 48 `private let confirmButton = PrimaryButtonNode(...)`). nil-safe 가드 불필요.

### 빌드 결과

```bash
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**결과**: `** BUILD SUCCEEDED **` ✅

- 컴파일 에러 0건
- 경고: 기존 Fonts duplicate 3건만 (본 작업 무관)

### 회귀 위험 평가 (다른 영역 변경 0건 확인)

- SceneSafeArea.swift: 미터치
- GameViewController.swift: 미터치
- StartScene.swift: 미터치
- ResultScene.swift: 미터치
- CharacterFaceNode.swift: 미터치
- CharacterSelectScene의 다른 함수(`cardBaseX`/`cardBaseY`/`setupConfirmButton`/`rebuildSkillInfoPanel` 등): 미터치

QA가 P2로 명시한 §2(geon 너스캡)는 본 사이클 변경 보류.

### P2 §1 (DRY 위반) 동시 해소

QA §P2 §1이 `layoutSkillInfoChip`의 중복 계산을 지적했고, 이번 P1 수정 패턴(`confirmButton.position.y` 직접 참조)이 같은 식을 자연스럽게 제거하여 P2 §1도 함께 해소됨.
