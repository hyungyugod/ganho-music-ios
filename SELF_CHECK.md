# 자체 점검 — Phase 6-16 ScorePopupNode (+1 / +2 플로팅 텍스트)

## 변경 파일 목록

### git status (변경 파일 영역만)
```
modified:   GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift
modified:   GanhoMusic/GanhoMusic Shared/GameScene.swift
modified:   GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj

Untracked files:
GanhoMusic/GanhoMusic Shared/Nodes/ScorePopupNode.swift
```

### git diff --stat (코드 영역만)
```
GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift      |  21 +
GanhoMusic/GanhoMusic Shared/GameScene.swift              |   7 +
GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj           |   4 +
```
+ 신규 파일 `GanhoMusic Shared/Nodes/ScorePopupNode.swift` (109줄).

**총 코드 변경: +132 / -0 (회귀 0)** + pbxproj 4줄.

## 신규 파일 / 수정 파일 / 회귀 0 영역

### 신규 파일 (1개)
- `GanhoMusic Shared/Nodes/ScorePopupNode.swift` — 자가 소멸 노드 9호. SelfDismissingNode 채택, 정적 팩토리 `spawn(at:gainedPoints:parent:)` 유일 진입점.

### 수정 파일 (3개, *최소 변경*)
- `GanhoMusic Shared/Config/GameConfig.swift` — 파일 맨 아래 `// MARK: - Score Popup (Phase 6-16)` 섹션 신설, 신규 상수 7개 추가 (기존 상수 0건 변경).
- `GanhoMusic Shared/GameScene.swift` — `onNoteCollected` 클로저 안 sparkle.emit() 직후 / 콤보 마일스톤 가드 직전에 6줄 추가 (gainedPoints 산출 + ScorePopupNode.spawn 호출). 다른 라인 미접촉.
- `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj` — 신규 .swift 파일 등록을 위한 4지점에 각 1줄 추가 (PBXBuildFile / PBXFileReference / PBXGroup Nodes children / PBXSourcesBuildPhase iOS 타겟).

### 회귀 0 영역 (절대 미접촉 — SPEC 요구사항)
다음 파일은 **단 한 글자도 수정되지 않음** (git status로 확인):
- `ScoreSystem.swift` ✓ (시그니처/내부 로직 완전 미접촉, recordNoteHit return value 변경 0)
- `ContactRouter.swift` ✓ (onNoteCollected 콜백 타입 미변경)
- `HUDNode.swift` ✓
- `BGMPlayer.swift` ✓
- `AudioManager.swift` ✓ (신규 사운드 case 0)
- `HapticsManager.swift` ✓ (신규 햅틱 호출 0)
- `ColorTokens.swift` ✓ (신규 색상 0)
- 자가 소멸 노드 8호 전체:
  - `SparkleEffectNode.swift` ✓
  - `ComboPopupNode.swift` ✓
  - `ComboBreakNode.swift` ✓
  - `CountdownNode.swift` ✓
  - `HitFlashNode.swift` ✓
  - `BombFlashNode.swift` ✓
  - `AirplaneNode.swift` ✓
  - `AirforceOverlayNode.swift` ✓
- `TitleScene.swift` ✓
- `ResultScene.swift` ✓
- pbxproj는 iOS 타겟 빌드 단계에만 등록 — `C75D46362FA627C20016BB86` (tvOS) / `C75D46462FA627C20016BB86` (macOS) Sources 단계는 **빈 files() 그대로** ✓

## SPEC §"기능 상세" 각 항목별 구현 라인 매핑

### 기능 1: ScorePopupNode (자가 소멸 노드 9호)
**파일**: `GanhoMusic Shared/Nodes/ScorePopupNode.swift` (신규)

| SPEC 요구사항 | 구현 위치 (파일:라인) |
|---|---|
| SelfDismissingNode 채택 | `ScorePopupNode.swift:33` (`final class ScorePopupNode: SKNode, SelfDismissingNode`) |
| label 자식 노드 1개 | `ScorePopupNode.swift:37, 47` (private let label / addChild(label)) |
| 정적 팩토리 `spawn(at:gainedPoints:parent:)` 단일 진입점 | `ScorePopupNode.swift:62~69` |
| 시작 위치 (x, y + scorePopupStartOffsetY) | `ScorePopupNode.swift:65~66` (CGPoint x/y + GameConfig.scorePopupStartOffsetY) |
| 위로 +40pt 이동 (scorePopupFlyUpDistance) | `ScorePopupNode.swift:76~78` (SKAction.moveBy) |
| 알파 1→0 페이드아웃 | `ScorePopupNode.swift:79` (SKAction.fadeOut) |
| 스케일 0.8→1.0 부풀어 오름 | `ScorePopupNode.swift:43, 80~81` (setScale 시작값 + SKAction.scale 끝값) |
| 0.6초 후 removeFromParent (자가 소멸) | `ScorePopupNode.swift:82~84` (SKAction.sequence([group, cleanup])) |
| zPosition 50 | `ScorePopupNode.swift:41` (zPosition = GameConfig.scorePopupZPosition) |
| fontSize 28pt | `ScorePopupNode.swift:91` (label.fontSize = GameConfig.scorePopupFontSize) |
| fontName 미지정 (다른 자가 소멸 노드 일관) | `ScorePopupNode.swift:36, 91~95` (SKLabelNode 기본 init + fontName 라인 없음) |
| +1 → .ganhoPaper / +2 → .ganhoYellowF / default → .ganhoPaper | `ScorePopupNode.swift:101~107` (private static func color(for:)) |
| `[weak self]` 캡처 불필요 (self 미사용) | `ScorePopupNode.swift:74~84` (animate 안 self 미사용) |
| PhysicsBody 0건 | `ScorePopupNode.swift` 전체 (physicsBody 키워드 0번 등장) |
| private init — 외부 spawn factory 강제 | `ScorePopupNode.swift:39` (private init(gainedPoints:)) |

### 기능 2: GameScene onNoteCollected ScorePopupNode 스폰 호출
**파일**: `GanhoMusic Shared/GameScene.swift`

| SPEC 요구사항 | 구현 위치 (파일:라인) |
|---|---|
| sparkle.emit() 직후, 콤보 마일스톤 가드 직전 | `GameScene.swift:341~349` (sparkle.emit()은 341, 콤보 마일스톤 주석은 349) |
| sparkleOrigin 좌표 재사용 (안전한 캡처) | `GameScene.swift:348` (ScorePopupNode.spawn(at: sparkleOrigin, ...)) |
| `recordNoteHit` *후* combo 폴링 (옵션 B) | `GameScene.swift:345` (self.scoreSystem.combo는 331줄 recordNoteHit 이후 시점) |
| comboBonusThreshold 분기로 gainedPoints 산출 | `GameScene.swift:345~347` (삼항 연산자 combo >= GameConfig.comboBonusThreshold ? scorePerNoteCombo : scorePerNote) |
| worldNode 부모 (sparkle과 동일 좌표계) | `GameScene.swift:348` (parent: self.worldNode) |

### GameConfig 신규 상수 7개
**파일**: `GanhoMusic Shared/Config/GameConfig.swift:397~417` (`// MARK: - Score Popup (Phase 6-16)` 섹션)

| 상수명 | 값 | 라인 |
|---|---|---|
| `scorePopupFontSize` | 28 | 400 |
| `scorePopupStartOffsetY` | 12 | 403 |
| `scorePopupFlyUpDistance` | 40 | 406 |
| `scorePopupDuration` | 0.6 | 409 |
| `scorePopupStartScale` | 0.8 | 411 |
| `scorePopupEndScale` | 1.0 | 413 |
| `scorePopupZPosition` | 50 | 416 |

기존 상수 **0건 변경**, 신규 7개 정확히 추가.

## 빌드 결과

### 빌드 명령
```
cd <worktree>
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
  -target "GanhoMusic iOS" \
  -sdk iphonesimulator26.5 \
  -configuration Debug \
  EXCLUDED_SOURCE_FILE_NAMES="Main.storyboard" \
  build
```

### 빌드 환경 주의 — `-destination` 사용 불가 이유
요청된 `-destination "platform=iOS Simulator,name=iPhone 17"`을 시도했으나, 본 환경의 Xcode가
`"Supported platforms for the buildables in the current scheme is empty"` 오류와 함께
`iOS 26.5 is not installed. Please download and install the platform from Xcode > Settings > Components`를 보고함.
시뮬레이터 iOS Runtime은 26.4 (`com.apple.CoreSimulator.SimRuntime.iOS-26-4`)이고 SDK는 26.5만 설치되어 있어
*destination resolver*가 미설치 platform으로 분기. 코드와 무관한 환경 이슈.

또한 `Main.storyboard` 컴파일도 동일한 환경 사유로 ibtool이 `iOS 26.5 Platform Not Installed`를 보고 —
`EXCLUDED_SOURCE_FILE_NAMES="Main.storyboard"`로 우회. **Swift 코드 컴파일은 본 빌드에서 검증 완료** (clean 빌드 후 ScorePopupNode가 x86_64 + arm64 두 아키텍처 모두 정상 컴파일됨).

### Swift 단독 typecheck (전체 소스 트리)
환경 무관 검증으로 swiftc 단독 typecheck 수행:
```
find "GanhoMusic/GanhoMusic Shared" "GanhoMusic/GanhoMusic iOS" -name "*.swift" -print0 |
  xargs -0 xcrun -sdk iphonesimulator26.5 swiftc -typecheck \
    -target arm64-apple-ios16.6-simulator -sdk "$SDK_PATH"
```
**결과: 표준 출력 0줄, 에러 0건, 경고 0건.**

### xcodebuild 출력 마지막 30줄 발췌
```
AppIntentsSSUTraining (in target 'GanhoMusic iOS' from project 'GanhoMusic')
    ...
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsnltrainingprocessor
    ...
2026-05-18 09:30:16.557 appintentsnltrainingprocessor[4197:48017] Parsing options for appintentsnltrainingprocessor
2026-05-18 09:30:16.558 appintentsnltrainingprocessor[4197:48017] Starting AppIntents SSU YAML Generation
2026-05-18 09:30:16.558 appintentsnltrainingprocessor[4197:48017] No AppShortcuts found - Skipping.

CodeSign /Users/hg/.../build/Debug-iphonesimulator/GanhoMusic.app (in target 'GanhoMusic iOS' from project 'GanhoMusic')
    Signing Identity:     "Sign to Run Locally"
    /usr/bin/codesign --force --sign - --timestamp=none --generate-entitlement-der ...

RegisterExecutionPolicyException ...
    builtin-RegisterExecutionPolicyException ...

Validate ...
    builtin-validationUtility ... -shallow-bundle -infoplist-subpath Info.plist

Touch /Users/hg/.../build/Debug-iphonesimulator/GanhoMusic.app
    /usr/bin/touch -c ...

warning: ONLY_ACTIVE_ARCH=YES requested with multiple ARCHS and no active architecture could be computed; building for all applicable architectures (in target 'GanhoMusic iOS' from project 'GanhoMusic')
** BUILD SUCCEEDED **
```

### ScorePopupNode 컴파일 확인 (clean build log에서 발췌)
```
SwiftCompile normal x86_64 Compiling\ ComboBreakNode.swift,\ CountdownNode.swift,\ ScorePopupNode.swift,...
SwiftCompile normal x86_64 .../Nodes/ScorePopupNode.swift
SwiftCompile normal arm64  Compiling\ ComboBreakNode.swift,\ CountdownNode.swift,\ ScorePopupNode.swift,...
SwiftCompile normal arm64  .../Nodes/ScorePopupNode.swift
SwiftDriverJobDiscovery normal x86_64 Compiling ComboBreakNode.swift, CountdownNode.swift, ScorePopupNode.swift, GeneratedAssetSymbols.swift
SwiftDriverJobDiscovery normal arm64  Compiling ComboBreakNode.swift, CountdownNode.swift, ScorePopupNode.swift, GeneratedAssetSymbols.swift
```
ScorePopupNode가 **x86_64 + arm64 두 아키텍처 모두 컴파일 성공**.

### 경고 분석
빌드 로그 전체 grep `error:|warning:` 결과 (storyboard 환경 메시지 제외):
- `warning: ONLY_ACTIVE_ARCH=YES requested with multiple ARCHS ...` — 본 변경과 무관 (xcodebuild의 `-arch` 미지정 사용자 경고)
- `appintentsmetadataprocessor[...] warning: Metadata extraction skipped. No AppIntents.framework dependency found.` — 본 변경과 무관 (이전 phase부터 존재. AppIntents 미사용 프로젝트라 정상)

**Swift 컴파일 에러 0, Swift 컴파일 경고 0**. 본 sprint가 도입한 신규 경고 **0건**.

## 매직 넘버 / 강제 언래핑 / Timer / DispatchQueue 0건 grep 결과

### 매직 넘버 0건
```
$ grep -nE "[^[:alnum:]_][0-9]+\.[0-9]+|[^[:alnum:]_][0-9]+[^[:alnum:]_.]" \
    "GanhoMusic/GanhoMusic Shared/Nodes/ScorePopupNode.swift" \
    | grep -v "//\|0,\|0)\|.zero\|init?"
(빈 출력)
```
ScorePopupNode 안 숫자 리터럴 0건. **모든 수치는 GameConfig 상수 참조** (scorePopupFontSize, scorePopupStartOffsetY, scorePopupFlyUpDistance, scorePopupDuration, scorePopupStartScale, scorePopupEndScale, scorePopupZPosition 7개 + scorePerNote / scorePerNoteCombo 2개 = 총 9개 상수). GameScene 변경 영역도 GameConfig 상수만 참조.

### 강제 언래핑 (!) 0건
```
$ grep -n "!" "GanhoMusic/GanhoMusic Shared/Nodes/ScorePopupNode.swift" | grep -v "//" | grep -v "!= "
(빈 출력)
```
ScorePopupNode 안 `!` 0개. GameScene 신규 라인도 옵셔널 미사용.

### Timer 0건
```
$ grep -rn "Timer\." \
    "GanhoMusic/GanhoMusic Shared/Nodes/ScorePopupNode.swift" \
    "GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift"
(빈 출력)
```
변경 파일 전체에 `Timer` 0건. **SKAction.wait/sequence만 사용** (ComboPopupNode 완전 답습 패턴).

### DispatchQueue 0건
```
$ grep -rn "DispatchQueue" \
    "GanhoMusic/GanhoMusic Shared/Nodes/ScorePopupNode.swift" \
    "GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift"
(빈 출력)
```
변경 파일 전체에 `DispatchQueue` 0건. 비동기/지연은 모두 SKAction으로 처리.

## SPEC.md "주의사항" 8개 항목 각각 어떻게 준수했는지 줄별 확인

SPEC §"주의사항" 8개 항목 (각 항목 → 구현 결과):

1. **부모 선택: ScorePopupNode는 반드시 worldNode에 부착** ✓
   - 구현 라인: `GameScene.swift:348` — `ScorePopupNode.spawn(at: sparkleOrigin, gainedPoints: gainedPoints, parent: self.worldNode)`
   - `cameraNode` (HUD/콤보팝업 부모)가 아닌 `worldNode` 전달 — sparkle과 동일 부모로 카메라 follow 자연 동기.

2. **좌표 캡처 순서: sparkleOrigin 재사용** ✓
   - 구현 라인: `GameScene.swift:337` (sparkleOrigin 캡처) → `GameScene.swift:348` (재사용)
   - `note.position`을 새로 읽는 코드 없음. 이미 안전하게 캡처된 sparkleOrigin만 사용 — note.removeFromParent() 후에도 안전.

3. **gainedPoints 산출 시점: recordNoteHit 호출 후 평가** ✓
   - `GameScene.swift:331` (recordNoteHit) → `GameScene.swift:345~347` (combo 폴링 + 점수 분기)
   - 호출부에서 14줄 뒤에 combo 평가 — *post-recordNoteHit* 상태 자동 보장.

4. **새 ColorTokens 0: ganhoPaper / ganhoYellowF만 사용** ✓
   - 구현 라인: `ScorePopupNode.swift:103~106`
   - `ganhoWhite` 등 존재하지 않는 토큰 미참조. ColorTokens.swift는 **읽기만**, 쓰기 0건 (회귀 0).

5. **SKLabelNode fontName 미지정 (자가 소멸 노드 일관)** ✓
   - 구현 라인: `ScorePopupNode.swift:36` (SKLabelNode(text: "+\(gainedPoints)")) — fontName 인자 미전달
   - `configureLabel`(89~95줄)에서도 fontName 설정 라인 없음 → 시스템 기본 폰트 사용 (ComboPopupNode / ComboBreakNode / CountdownNode와 동일 정책).

6. **pbxproj 4지점 등록 + iOS 타겟에만, tvOS/macOS 미접촉** ✓
   - 4지점 모두 등록 (grep으로 4건 확인):
     - 라인 45: `PBXBuildFile` — `A1C0F1B00000000000000034 /* ScorePopupNode.swift in Sources */`
     - 라인 84: `PBXFileReference` — `A1C0F1A00000000000000034 /* ScorePopupNode.swift */`
     - 라인 229: `PBXGroup` Nodes children — CountdownNode 다음 줄
     - 라인 502: `PBXSourcesBuildPhase` (iOS 타겟 `C75D46252FA627C20016BB86`) — CountdownNode 다음 줄
   - tvOS 타겟 `C75D46362FA627C20016BB86` Sources files() 영역 → **빈 채로 유지** (라인 504~508)
   - macOS 타겟 `C75D46462FA627C20016BB86` Sources files() 영역 → **빈 채로 유지** (라인 511~515)
   - UUID 패턴 `...0034`로 기존 31/32/33(ComboPopup/ComboBreak/Countdown) 다음 슬롯 정확히 사용.

7. **spawn static factory 내부에서 private init 호출** ✓
   - 구현 라인: `ScorePopupNode.swift:39` (`private init(gainedPoints: Int)`)
   - 구현 라인: `ScorePopupNode.swift:62~69` (외부 호출자가 사용할 수 있는 유일 진입점은 `static func spawn`)
   - 외부에서 `ScorePopupNode()`나 `ScorePopupNode(gainedPoints:)` 직접 호출은 *컴파일 타임에 차단* (private init).

8. **animate를 private으로** ✓
   - 구현 라인: `ScorePopupNode.swift:74` (`private func animate()`)
   - spawn 정적 팩토리에서만 내부 호출 (`ScorePopupNode.swift:68` — `node.animate()`).
   - ComboPopupNode는 외부에서 `popup.animate()`로 호출하는 패턴이지만, 본 노드는 *정적 팩토리 일체형*으로 한 단계 더 캡슐화 (패턴 진화 9호).

---

## SPEC 기능 체크 (요약)

- [x] **기능 1 — ScorePopupNode 자가 소멸 노드 9호**: 신규 파일 `Nodes/ScorePopupNode.swift` 109줄. SelfDismissingNode 채택, private init + 정적 팩토리 spawn 단일 진입점, group(move + fade + scale) → sequence(group, removeFromParent) ComboPopupNode 완전 답습, color(for:) pure function.
- [x] **기능 2 — GameScene onNoteCollected 스폰 호출 6줄 추가**: sparkle.emit() 직후 / 콤보 마일스톤 가드 직전 위치, sparkleOrigin 재사용, recordNoteHit 후 combo 폴링으로 gainedPoints 산출, worldNode 부모.

## Swift 패턴 준수

- 강제 언래핑 미사용: **준수** (`!` 0건 검증)
- guard let 옵셔널 처리: **준수** (옵셔널 미사용 — 신규 코드)
- MARK 섹션 구분: **준수** (`// MARK: - Properties / Init / Spawn / Animate / Configure / Color Mapping`)
- GameConfig 상수 사용: **준수** (매직 넘버 0건, 모든 수치 GameConfig 참조)
- weak self 캡처: **해당 없음** (animate 클로저 내 self 미사용 — ComboPopupNode와 동일)
- private 접근 제어: **준수** (init / animate / configureLabel / color(for:) 전부 private)
- final class: **준수** (`final class ScorePopupNode`)

## SpriteKit 패턴 준수

- didMove(to:)에서 초기화: **해당 없음** (자가 소멸 노드 — spawn 시 즉시 동작)
- dt 기반 이동: **해당 없음** (SKAction 보간 사용)
- SKAction 스폰 패턴: **준수** (sequence + group, fire-and-forget)
- 충돌 후 노드 즉시 삭제 없음: **준수** (자가 소멸은 SKAction.removeFromParent 마지막 단계로 안전 — 물리 충돌 콜백 직접 노드 삭제 0건)
- HUD 노드 분리: **준수** (HUDNode 미접촉, ScorePopupNode는 worldNode 자식 별도 노드)
- PhysicsBody 0건: **준수** (physicsBody 키워드 0번 등장)
- 자가 소멸 노드 패턴 답습: **준수** (8호 노드들과 동일 SKAction.sequence([group, removeFromParent]) 구조)

## 빌드 상태

- 예상 빌드 에러: **없음** (Swift 코드 컴파일 0 에러 0 경고, clean build BUILD SUCCEEDED).
- 주의 필요 경고: **없음** (본 sprint가 도입한 신규 경고 0건. 빌드 로그의 ONLY_ACTIVE_ARCH / AppIntents 경고는 본 변경과 무관한 환경/프로젝트 사전 메시지).
- 환경 이슈: ibtool storyboard 컴파일이 iOS 26.5 platform 미설치로 실패하지만 **Swift 코드와 무관** (storyboard 변경 0건). Xcode IDE에서 빌드 시 정상 작동 예상.

## 범위 외 미구현 항목

**없음.** SPEC.md "허용" 범위 4건 모두 구현 완료, "금지" 범위 7건 모두 0건 위반:

- ScoreSystem 시그니처/내부 로직 변경 → **0건** (회귀 0 영역으로 확정)
- sparkle / 콤보 마일스톤 / 콤보 BREAK / 카메라 셰이크 / HUD / BGM / Haptics / Audio API 신규 호출/수정 → **0건**
- 신규 사운드 case / 신규 햅틱 호출 / 신규 ColorTokens 색상 → **0건**
- SPEC에 없는 별개 시각 효과 (파티클, 진동 등) → **0건**
- .xcassets, Info.plist, Asset Catalog 신규 항목 → **0건**

**판단 기준 "이 변경이 없으면 +1/+2 텍스트가 노트 수집 자리에 안 뜨는가?" → YES인 변경만 수행함.**
