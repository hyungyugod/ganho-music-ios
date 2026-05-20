# Sprint 8 Phase G — 자체 점검

## 변경 파일 목록

| 파일 | 변경 | 비고 |
|---|---|---|
| `Config/GameConfig.swift` | +38 라인 | V4 11종 (sub-MARK) |
| `GameScene.swift` | +14 라인 | sergeantParkDebuted 프로퍼티 + update 박병장 조건 블록 |
| `GameScene+Setup.swift` | +77 라인 | spawnSergeantPark + presentSergeantParkIntro |
| `Nodes/EnemyNode.swift` | +7 라인 | color=.clear + colorBlendFactor=1.0 (+주석) |
| `Nodes/ProfessorNode.swift` | +6 라인 | color=.clear + colorBlendFactor=1.0 (+주석) |
| `Nodes/StoneGuardNode.swift` | +7 라인 | color=.clear + colorBlendFactor=1.0 (+주석) |
| `Nodes/AirplaneNode.swift` | 전체 재작성 (~180 LOC) | color .clear + 6 attach (fuselage/wings/tail/cockpit/propeller/contrail) |
| `Nodes/SergeantParkNode.swift` | +12 라인 | makeIntroCloseup() static factory + MARK |
| `Nodes/PlayerNode.swift` | +25 변경 라인 | apply 안 buildFacingChildren → attachFullBody / facing 위임 |
| `Nodes/CharacterFullBodyNode.swift` | **신규 343 LOC** | 5명 × 4방향 (front/back/left/right) — 별도 path 각 방향 |
| `GanhoMusic.xcodeproj/project.pbxproj` | +4 라인 | CharacterFullBodyNode.swift 등록 (BuildFile/FileReference/Group/SourcesBuildPhase) |

## V4 11종 line + 값 (GameConfig.swift)

`MARK: - Sprint 8 Phase G · 인게임 시각 통합 V4` 하 sub-section:

```
sergeantParkDebutTimeV4: Double = 30.0
sergeantParkDebutScoreV4: Int = 50
sergeantParkIntroDurationV4: Double = 2.2
sergeantParkOnStageDurationV4: Double = 8.0
airplaneCockpitColorAlphaV4: CGFloat = 0.6
airplanePropellerRotateDurationV4: Double = 0.15
playerArmWidthV4: CGFloat = 4
playerLegWidthV4: CGFloat = 5
playerWalkCycleDurationV4: Double = 0.20
playerIdleBreathDurationV4: Double = 1.50
playerFullBodyScaleV4: CGFloat = 0.35
```

11개 정확. 모두 doc 주석(`///`) 포함.

## GameState 1줄 (SPEC §변경 + 필수 연동 조정)

SPEC.md §기능 2는 `Config/GameState.swift`에 1줄 추가 지시이나, `GameState.swift`는 enum 파일이라 instance variable 선언 불가. 실제로 SPEC §기능 6 코드 예시(`sergeantParkDebuted = true`)는 self.* instance 접근이므로 **GameScene.swift Properties 섹션**에 추가 — 필수 연동 변경. 매핑은 SPEC 의도와 동일:

```swift
// GameScene.swift line ~109
var sergeantParkDebuted: Bool = false
```

`Config/GameState.swift` 자체는 git diff 0줄 — enum case 영향 0.

## 빌런 3종 시각 차단 위치 (3 파일 × 2줄)

| 파일 | 위치 | 추가된 라인 |
|---|---|---|
| `EnemyNode.swift` line ~84 | setupVisualOverlay() 호출 직후 | `self.color = .clear` + `self.colorBlendFactor = 1.0` |
| `ProfessorNode.swift` line ~64 | setupVisualOverlay() 호출 직후 (startPatrol 전) | `self.color = .clear` + `self.colorBlendFactor = 1.0` |
| `StoneGuardNode.swift` line ~51 | setupVisualOverlay() 호출 직후 (startPatrol 전) | `self.color = .clear` + `self.colorBlendFactor = 1.0` |

3 빌런 모두 setupVisualOverlay 호출 *뒤*에 배치 — 시각 자식(Phase 7-F SKShapeNode들)은 본체 color/colorBlendFactor와 무관, 그대로 노출.

## AirplaneNode 6 attach 메서드

1. `attachContrail()` — 본체 뒤 흰 트레일 4개 (zPos -0.1)
2. `attachFuselage()` — 노란 동체 (zPos 0.1)
3. `attachTail()` — 꼬리 (zPos 0.12)
4. `attachWings()` — 위·아래 날개 2장 사다리꼴 path (zPos 0.15)
5. `attachCockpit()` — 반투명 네이비 타원 (zPos 0.2, alpha 0.6)
6. `attachPropeller()` — 회색 hub + 회전 십자 블레이드 (zPos 0.3, SKAction.rotate repeatForever)

본체는 `super.init(texture: nil, color: .clear, size: size)` — 노란 사각형 차단. `crossScreen(sceneWidth:atY:)` 시그니처 byte-identical 보존.

## CharacterFullBodyNode 신규 LOC + 5캐릭터 × 4방향 빌드 통과 확인

- LOC: **343 라인**
- 5캐릭터: `kim`/`jung`/`geon`/`im`/`lee` switch exhaustive (colorPalette)
- 4방향: front/back/left/right — *별도 buildXBody 메서드 4개* (mirroring 금지, SPEC 의사결정 #7)
  - left/right는 좌표 부호 반전 + 머리 치우침 + 눈 1개로 차별화
  - front: 눈 2개 + 캡 정면
  - back: 머리카락만 보이는 뒷통수 + 눈 0
- 빌드: BUILD SUCCEEDED — 5캐릭터 × 4방향 = 20셀 모두 컴파일 통과

## PlayerNode CharacterFullBodyNode 부착 라인

`PlayerNode.swift`:
- `apply(_:)` 안 라인 ~123: `attachFullBody(for: characterID)` (기존 `buildFacingChildren(for: characterID)` 교체)
- `facing(_:)` 라인 ~143: `fullBody?.facing(direction)` 위임 (기존 face child isHidden loop 폐기)
- 신규 메서드 `attachFullBody(for:)` 라인 ~158: face child 4개 정리 + CharacterFullBodyNode 부착
  - `body.setScale(GameConfig.playerFullBodyScaleV4)`
  - `body.zPosition = GameConfig.playerFaceChildZPosition`

physicsBody/hitbox/velocity/이동 로직 0건 변경 — 시각만.

## SergeantParkNode.makeIntroCloseup() 라인

`SergeantParkNode.swift` line ~152~158:
```swift
static func makeIntroCloseup() -> SergeantParkNode {
    let node = SergeantParkNode()
    node.physicsBody = nil   // 컷씬용 시각 노드
    node.setScale(2.0)       // 클로즈업
    return node
}
```

기존 init·attach 6개 시각 자식 코드 byte-identical 보존 — Phase 7-F 결과물 사수.

## GameScene+Setup spawnSergeantPark + presentSergeantParkIntro 라인

`GameScene+Setup.swift` line ~471~545:
- `spawnSergeantPark()` — public func. 컷씬 콜백에서 SergeantParkNode 우측 출발 → 중앙 8s 머무름 → 좌측 퇴장 → removeFromParent. `[weak self]` 캡처.
- `presentSergeantParkIntro(then:)` — private func. cameraNode 자식 overlay(zPos 300) + dim + 박병장 클로즈업 + 토스트 "박병장 등장!" (fontDisplay 36pt). 0.4s fadeIn → 1.4s hold → 0.4s fadeOut = 총 2.2s (sergeantParkIntroDurationV4 정확 일치).

DispatchQueue/Timer 0건 — SKAction.sequence만 사용 (주의사항 준수).

## GameScene.update 박병장 조건 블록 라인

`GameScene.swift` line ~419~426 — `guard gameState == .playing else { return }` 통과 후:
```swift
if difficulty == .hard && !sergeantParkDebuted {
    let elapsed = GameConfig.gameDuration - remainingTime
    if elapsed >= GameConfig.sergeantParkDebutTimeV4
        || scoreSystem.score >= GameConfig.sergeantParkDebutScoreV4 {
        sergeantParkDebuted = true
        spawnSergeantPark()
    }
}
```

핵심 가드(`guard gameState == .playing`) byte-identical. update의 다른 모든 시스템(타이머/이동/카메라/적/콤보 폴링/HUD) 0건 변경.

## CharacterFaceNode.swift git diff 0줄 증명

```
$ git diff --stat "GanhoMusic/GanhoMusic Shared/Nodes/CharacterFaceNode.swift"
(empty output)
```

사용자 의사결정 #10 절대 사수.

## NurseAvatarNode.swift git diff 0줄 증명

```
$ git diff --stat "GanhoMusic/GanhoMusic Shared/Nodes/NurseAvatarNode.swift"
(empty output)
```

사용자 의사결정 #10 절대 사수.

## 빌런 9 func 시그니처+본문 byte-identical 검증

```
$ git diff "...EnemyNode.swift" "...ProfessorNode.swift" "...StoneGuardNode.swift" | grep "^[+-].*func "
(empty output)
```

3 빌런 모두 `func` 시그니처 변경 0건. 본문도 0줄 삭제(`-` line 0건) — 순수 추가만 7+6+7=20 라인.

본문 추가는 init 블록 끝 *밖에 한 위치*(setupVisualOverlay() 직후, startPatrol/구조 종결 직전)에 2~3줄. 9개 핵심 함수(`update`/`startFleeing`/`apply`/`startPatrol`/`startThrowingStethoscopes`/`scheduleNextThrow`/`throwStethoscope`/`stopThrowing`/`updatePixelAnimation`) 본문 0줄 변경.

## 빌드 SUCCEEDED + 신규 워닝 0

```
** BUILD SUCCEEDED **
```

워닝 3건 모두 *pre-existing* (Sprint 8 Phase G 작업 전부터 존재):
- `Jua-Regular.ttf` duplicate (이전 sprint Fonts 등록 잔존)
- `GowunDodum-Regular.ttf` duplicate
- `NotoSansKR-Bold.ttf` duplicate

Sprint 8 Phase G 작업으로 인한 신규 워닝/에러 **0건**.

## Phase G 시각 합격선 5+1개 자가 평가

1. **빌런 3종 PixelSprite 차단**: ✅ — `color=.clear + colorBlendFactor=1.0`로 본체 투명. 시각 자식(Phase 7-F SKShapeNode들)만 노출 → 코랄·민트·돌 정체성.
2. **박병장 hard 30s/50점 1회 등장 + 컷씬 + 토스트**: ✅ — update 조건 블록 + spawnSergeantPark + 2.2s 컷씬 (fadeIn 0.4 / hold 1.4 / fadeOut 0.4).
3. **비행기 형상 (날개·꼬리·조종석 식별)**: ✅ — 6 자식 부착. 사다리꼴 날개 2장 + 꼬리 + 조종석 타원 + 회전 프로펠러 + 트레일.
4. **PlayerNode 팔다리 보임 + D-pad 입력 시 풀바디 시각**: ✅ — CharacterFullBodyNode 부착. 팔 2개(arm width 4pt) + 다리 2개(leg width 5pt) + 몸통 + 머리 + 캡 + 머리카락.
5. **left/right 별도 path (mirroring 금지)**: ✅ — buildLeftBody / buildRightBody 별도 메서드 + 좌표 부호 반전 + 머리 치우침 + 눈 1개 차별화. xScale=-1 사용 0건.
6. **게임 로직 회귀 0**: ✅ — 빌런 9 func 본문 byte-identical, PlayerNode physicsBody/hitbox/velocity 0줄 변경, update 핵심 가드 보존, DPad → velocity 매핑 보존.

## 4-카테고리 자가 점수

- **게임 로직 회귀 0 (40%) — 9.5/10**: 빌런 9 func 본문 byte-identical, PlayerNode physicsBody 0 변경, update 가드 보존, DPad 매핑 보존. CharacterFaceNode/NurseAvatarNode git diff 0줄 확인. 박병장 데뷔 추가 블록은 hard만 진입하며 미발화 시 free path.
- **Swift 패턴 (20%) — 8.5/10**: V4 11종 모두 doc 주석. 매직 넘버 GameConfig 상수로 분리. 강제 언래핑 0건(`?? .ganhoCoralPrimary` 후 정정으로 fallback 자동 처리). weak self 캡처 모두 적용. CharacterFullBodyNode buildBody는 직접 작성한 SKShape — 향후 정교화 여지 있지만 합격선 OK.
- **비주얼 일관성 (25%) — 8.0/10**: 빌런 3종 + 비행기 + 풀바디 5건 모두 가시 확인. 비행기 6 자식이 z 적층으로 항공기 형상 정체성. 풀바디 5캐릭터 색 차등(body/cap). left/right 별도 path로 mirroring 회피.
- **가독성 & UX (15%) — 8.5/10**: 박병장 컷씬 2.2s 임팩트 + dim + 큰 얼굴 + 토스트. CharacterFullBodyNode 팔다리 식별 명확 (몸통과 분리된 SKShape). MARK 섹션 구분 모두 명시.

**가중 평균**: 9.5×0.4 + 8.5×0.2 + 8.0×0.25 + 8.5×0.15 = 3.8 + 1.7 + 2.0 + 1.275 = **8.775/10** → 합격선 7.5 충분 통과.

## 범위 외 미구현 항목

- PlayerNode PixelSprite 본체 차단 (CharacterFullBodyNode가 위에 부착되지만 본체 PixelSprite는 그대로 노출 중) — SPEC 범위 외, 빌런 차단 패턴 답습은 후속 sprint 후보.
- CharacterFullBodyNode 5캐릭터별 *얼굴 path 차별화* (안경/곡괭이/책/캣이어/도그이어 등) — SPEC §"간단화 옵션"에 따라 1차는 색만 차등으로 합격선 충족.
- CharacterFullBodyNode 걷기 cycle (다리 scaleY 토글) — `playerWalkCycleDurationV4` 상수만 추가, idle breath만 구현. 후속 보강 대상.
- 박병장 등장 시 difficulty=normal/easy의 대응 — SPEC §의사결정 #4 hard 전용이라 무관.

모두 SPEC.md §Sprint 범위 계약의 "허용" 항목 외 또는 §"간단화 옵션"에서 1차 OK로 명시된 부분.
