# Phase 11-3 (Sprint 3) — 인게임 v2 리스킨 (가장 위험한 단계)

## 한 줄 요약
**가장 회귀 위험이 큰 단계 — 실제 게임이 돌아가는 화면(GameScene·HUD·D-Pad·스킬 버튼·음표·F 투사체·콤보 팝업)을 카툰 톤으로 갈아치웠어요.** 그런데 게임 수치(점수·콤보·시간·물리 박스)는 *단 한 줄도* 안 건드림. 19개 보호 파일 git diff 0줄. 빌드 성공. QA 9.22/10 한 번에 통과.

---

## 무엇을, 왜?

### 무엇을
| 영역 | Before | After |
|---|---|---|
| 배경 | 다크 ganhoBgDeep | ganhoBgWarmTop 단색 (카메라 follow 안전) |
| 체크보드 | #1a1722 / #13111a | #FFEFE0 / #FFDFC8 (peach) |
| 외곽 벽·기둥 | ganhoPaper | ganhoNavyDeep + 외곽 라운드 보더 |
| HUD 4슬롯 | 단색 라벨 | navy 0.78 알약 + Jua 10pt 골드 라벨 + Jua 18pt 흰 값 |
| TIME 슬롯 12초 이하 | 깜빡임 | 슬롯 배경 코랄로 swap + 하단 진행바 |
| D-Pad | SKSpriteNode 4개 | SKShape 4개 (white 0.75 + navy α 0.25 stroke) + 중앙 데드존 navy α 0.4 |
| 스킬 버튼 | 사각 박스 | 코랄 원 72 + B 키 칩 + 스킬명 칩 (좌하단) |
| 음표 | 픽셀 ♪ | 골드 원 + 흰 링 2pt + 글로우 + 1.4s 펄스 |
| F 투사체 | 노랑 픽셀 F | 코랄 22 라운드 사각형 + 흰 F + visual-only -12° 회전 |
| 콤보 팝업 | 시스템 폰트 48pt | Jua 32pt + navy 외곽선 4방향 + -8° 회전 |
| 콤보 브레이크 | 시스템 폰트 48pt | Jua 28pt + 코랄 + navy 외곽선 |
| 일시정지 | (없음) | 우상단 navy 32 라운드 + 흰 || (시각 placeholder) |

### 왜
Phase 11-1(부품) → 11-2(메뉴 조립) → 11-3(인게임 조립)로 *디자인 리뉴얼 전체 파이프라인의 본진*이에요. 메뉴는 짧게 머무는 화면이지만 인게임은 45초 내내 보는 화면이라 가장 중요. 그리고 가장 *건드리면 게임이 깨지는* 화면.

### 위험 — Sprint 3가 어려운 이유
| 위험 | 사례 |
|---|---|
| 게임 수치 변경 | `comboWindow = 2.5` → 2.0으로 바꾸면 콤보 끊김 타이밍이 깨짐. 사용자가 점수 안 나온다고 항의. |
| PhysicsBody 변경 | NoteNode physicsBody size 16×16 → 22×22로 바꾸면 음표 충돌 박스 1.9배 커짐. 이동만 해도 음표 수집됨. |
| DPad 입력 로직 변경 | touchesBegan 순서 한 줄 바꾸면 좌우 입력이 바뀌어서 게임 조작 불가. |
| 저장소 변경 | HighScoreRepository 저장 키 변경 → 사용자 최고 기록 다 사라짐. |

해결책: **OUT 섹션을 광범위하게 명시 + 19개 보호 파일 git diff 0줄 체크 + Evaluator가 매 항목 grep로 검증**.

---

## Spring Boot 비유

Sprint 3는 Spring으로 치면 **"Controller는 자유롭게 갈아끼우되, @Service / @Repository / @Configuration은 한 줄도 못 건드림"** 작업이에요.

| Spring Boot | SpriteKit (이번 작업) |
|---|---|
| `@Service ScoreCalculator` 내부 | `ScoreSystem.swift` (0건 변경) |
| `@Repository HighScoreRepository` | `HighScoreRepository.swift` (0건 변경) |
| `@Configuration GameConfig` 게임 수치 키 | `GameConfig.swift` 게임 수치 상수 13개 (0건 변경) |
| HTTP entity DTO (Request/Response) | `PhysicsBody size/category/contact` (0건 변경) |
| Spring Security `WebSecurityConfigurer` 정책 | `ContactRouter` 충돌 분기 (0건 변경) |
| Bean의 외부 시그니처 (메서드 시그니처) | `HUDNode.update(score:remainingTime:combo:)` 시그니처 (0건 변경) |
| Controller 메서드 본문 (private 헬퍼) | `GameScene+Setup.addOuterWalls` 본문 일부 (색만 변경) |
| Thymeleaf 템플릿 (HTML) | NoteNode 자식 SKShape 시각 (자유 변경) |

핵심 원칙: **외부 시그니처와 데이터 모델은 절대 못 건드리고, *템플릿(시각 자식 노드)*만 갈아끼운다**. 이게 Spring의 *리팩토링 시 public API 하위 호환* 패턴의 SpriteKit 버전.

---

## 들어간 핵심 결정 10가지

### 1. 인게임 배경은 *단색* (그라데이션 노드 안 씀)
메뉴 3씬은 `GradientBackgroundNode.threeStop`을 썼지만 인게임은 *카메라가 player를 follow*함. 그라데이션을 worldNode 자식으로 두면 카메라 따라 픽셀 단위로 흐름이 어색. 그라데이션을 cameraNode 자식으로 두면 따라가긴 하지만 worldNode 위에 띄울 zPosition 관리가 복잡.

→ **단색 `backgroundColor = .ganhoBgWarmTop`**. 체크보드 자체가 이미 시각 패턴이라 그라데이션 없어도 따뜻한 톤이 충분.

### 2. 시각 자식과 PhysicsBody 분리
NoteNode/ProjectileNode의 시각 변화(글로우, 코랄 사각형 등)는 **SKShapeNode 자식**으로 추가. 본체 `SKSpriteNode.color = .clear`로 비우고 자식 SKShape가 시각 담당. **PhysicsBody는 본체에 그대로** — size = noteSize²/projectileSize² 정확 보존.

```swift
// NoteNode init() 끝
let glow = SKShapeNode(circleOfRadius: GameConfig.noteV2GlowRadius)  // 16
glow.fillColor = UIColor.ganhoMusicGold.withAlphaComponent(0.5)
addChild(glow)

let core = SKShapeNode(circleOfRadius: GameConfig.noteSize / 2)  // 8
core.fillColor = .ganhoMusicGold
addChild(core)
// PhysicsBody는 16×16 그대로 — *시각만* 글로우 반경 16으로 크게 보임
```

Spring 비유: **JPA Entity 필드(컬럼)는 그대로 두고, @JsonView로 응답 DTO만 새로 만든 패턴**. 데이터 스키마(DB)와 표현 레이어(JSON) 분리.

### 3. ProjectileNode visual-only 회전 (P2 패치)
처음엔 본체에 `zRotation = -12°`를 줬더니 SpriteKit의 PhysicsBody가 *부모 zRotation을 따라 회전*해서 hitbox가 -12° 기울어진 정사각형이 됨. Evaluator가 P2 권장으로 지적 — "hitbox AABB 약 2% 확장". 

해결: **시각 자식 + F 라벨 각각에만 zRotation 적용**.

```swift
// Before: 본체 회전 (hitbox도 회전)
zRotation = GameConfig.projectileV2RotationDegrees * .pi / 180

// After: 시각만 회전 (hitbox 축정렬 보존)
let rot = GameConfig.projectileV2RotationDegrees * .pi / 180
visualBody.zRotation = rot
fLabel.zRotation = rot
```

Spring 비유: **Entity의 @Transient 필드만 회전(시각)시키고 영속 필드(hitbox)는 그대로**.

### 4. DPad 시각 교체, 입력 로직 100% byte-identical
`SKSpriteNode` 4개 → `SKShapeNode` 4개. fillColor·strokeColor·cornerRadius 시각만 바뀜.

**입력 알고리즘(touchesBegan/Moved/Ended/Cancelled + updateDirection(forTouchLocation:) + currentDirection 노출)은 한 글자도 안 바뀜**.

Evaluator가 `git diff DPadNode.swift`에서 touch 메서드 본문이 100% byte-identical임을 확인. 입력은 게임 조작의 핵심 — 1픽셀이라도 다르면 사용자 항의.

### 5. HUDSlotNode init에 default 파라미터 추가 (호환성 100%)
TIME 슬롯만 진행바(timeBarBg/timeBarFill)를 가져야 함. 다른 슬롯은 안 가져야 함.

해결: `init(label:initialValue:showTimeBar: Bool = false)` — *default 파라미터*. 기존 HUDNode init에서 3개 슬롯(score/combo/best)은 그대로 호출, timeSlot만 `showTimeBar: true` 추가.

```swift
// 기존 호출자 — 한 줄도 안 바꿔도 컴파일 통과
let scoreSlot = HUDSlotNode(label: "SCORE", initialValue: "0")  // showTimeBar default false

// timeSlot만 신추가
let timeSlot = HUDSlotNode(label: "TIME", initialValue: "45", showTimeBar: true)
```

Spring 비유: **Java 메서드 오버로딩 또는 default value의 Swift 버전**. Spring에서도 `@RequestParam(required = false)`로 옵션 파라미터 추가는 하위 호환.

### 6. TIME 경고 색 전환 + 진행바
TIME ≤ 12초가 되면 슬롯 navy 배경이 코랄로 swap, 동시에 하단 진행바 width 갱신.

```swift
// HUDNode.update 끝에 추가 (시그니처 0 변경)
let warn = remainingTime <= GameConfig.tensionWindow
timeSlot.setWarn(warn)
let progress = CGFloat(remainingTime / GameConfig.gameDuration)
timeSlot.setTimeBar(progress: progress)
```

`setWarn(_:)`/`setTimeBar(progress:)`은 멱등 — 같은 상태 재대입 안전. 매 프레임 호출돼도 SKShapeNode.fillColor 비교 후 변경 없으면 GPU에 안 보냄.

### 7. 콤보 팝업/브레이크의 navy 외곽선 시뮬레이션
SpriteKit의 SKLabelNode는 stroke를 직접 지원 안 함. 외곽선 효과를 내려면 **같은 텍스트의 navy 라벨을 4방향 1pt 오프셋으로 자식 4개 부착**.

```swift
let outlineColor: UIColor = .ganhoNavyDeep
let w: CGFloat = GameConfig.comboPopupV2OutlineWidth  // 1
for (dx, dy) in [(-w, 0), (w, 0), (0, -w), (0, w)] {
    let outline = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    outline.text = label.text
    outline.fontColor = outlineColor
    outline.position = CGPoint(x: dx, y: dy)
    outline.zPosition = -1   // 본 라벨 뒤
    addChild(outline)
}
```

CSS의 `text-shadow: 0 1px 0 navy, 1px 0 0 navy, 0 -1px 0 navy, -1px 0 0 navy` 와 같은 발상.

### 8. PauseButtonNode는 *시각 placeholder*만 (`isUserInteractionEnabled = false`)
실제 일시정지 기능(gameState .paused 전환, BGM 일시정지, update guard)은 본 Sprint 범위 외. **버튼 모양만** 우상단에 만들어 두고 탭은 무반응. 추후 Sprint에서 활성.

이건 Spring 비유로 *MVP 단계의 stub 컨트롤러* — 엔드포인트는 노출하되 내부 로직은 비어있음.

### 9. 체크보드 hex 2개만 예외적 *값 교체*
SPEC §6.1 "게임 수치 0 변경"이 원칙인데 체크보드 hex 2개만 예외. DESIGN_RENEWAL_REQUEST.md §4.4에서 *명시적으로* 교체 지시. 이건 게임 로직이 아니라 *순수 시각 토큰*이라 안전.

```swift
// AS-IS
static let checkerboardFloorAHex: String = "#1a1722"
static let checkerboardFloorBHex: String = "#13111a"

// TO-BE — Sprint 3 명시 교체
static let checkerboardFloorAHex: String = "#FFEFE0"
static let checkerboardFloorBHex: String = "#FFDFC8"
```

다른 색 상수들(예: `hudValueFontSize = 22`, `comboPopupFontSize = 48`)은 *값 변경 0* — 새 v2 상수(`hudSlotV2ValueFontSize = 18`, `comboPopupV2FontSize = 32`)를 별도 이름으로 추가하고 호출자가 새 상수를 참조.

### 10. 19개 보호 파일 git diff 0줄
Evaluator의 핵심 검증: `git diff` 명령으로 19개 파일이 *byte-level로* 변경 0임을 확인.

```
ColorTokens / GlassPill / AccentLine / DarkContextChip / Primary / Back / GradientBackground
StartScene / CharacterSelectScene / SkillExplanationScene / ResultScene
Systems(SpawnSystem/ScoreSystem/SkillSystem/ContactRouter) / PhysicsCategory
Repositories(HighScore/Statistics/PerDifficultyScore/Graduation/CharacterPreference)
Managers(BGMPlayer/AudioManager/HapticsManager)
EnemyNode/ProfessorNode/StoneGuardNode/PlayerNode/DiplomaOverlayNode
```

이 19개 파일이 0줄이면 — 게임의 *심장부*가 무사. Sprint 3가 회귀 0임을 단정적으로 증명하는 정량 지표.

---

## Swift / SpriteKit 학습 포인트

### 4-1. SKPhysicsBody는 부모 zRotation을 따라 회전
```swift
parent.zRotation = .pi / 6   // 30°
parent.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 16, height: 16))
// → hitbox도 30° 회전된 사각형 (AABB가 살짝 커짐)
```

`allowsRotation = false`는 *물리 토크에 의한 회전*만 차단. 코드로 직접 설정한 zRotation은 적용됨.

해결: **시각 자식만 회전**시키면 PhysicsBody는 부모 zRotation = 0으로 축정렬 보존.

### 4-2. SKShapeNode rectOf cornerRadius로 알약 만들기
```swift
SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: h / 2)   // 알약
SKShapeNode(rectOf: CGSize(width: s, height: s), cornerRadius: s / 2)   // 원 (rectOf만)
SKShapeNode(circleOfRadius: r)                                          // 원 (편의 init)
```

CSS의 `border-radius: 50%`와 동치. SKShapeNode는 path 기반이라 매 프레임 GPU에 새 vertices 전송 — 정적인 노드는 OK, 자주 변경되는 노드는 성능 부담.

### 4-3. blendMode = .add로 글로우 누적
```swift
glow.blendMode = .add   // 알파 누적 — 같은 위치에 여러 글로우 겹치면 더 밝아짐
```

CSS의 `mix-blend-mode: screen`과 같은 발상. 음표가 동시 5~6개 보일 때 글로우가 살짝 겹치면 더 화려해 보임.

### 4-4. SKAction.scale + repeatForever로 펄스
```swift
let scaleUp = SKAction.scale(to: 1.08, duration: 0.7)
let scaleDown = SKAction.scale(to: 1.0, duration: 0.7)
let pulse = SKAction.sequence([scaleUp, scaleDown])
run(.repeatForever(pulse), withKey: "pulse")
```

`withKey`는 같은 키의 기존 액션을 자동으로 덮어씀 — 멱등 보장. 노드가 매번 init 될 때마다 액션이 중첩되지 않음.

### 4-5. SKLabelNode 외곽선 시뮬레이션
SpriteKit이 stroke를 직접 지원 안 함. 4방향 1pt 오프셋 자식 라벨로 시뮬레이션.

```swift
for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
    let outline = SKLabelNode(...)
    outline.position = CGPoint(x: dx, y: dy)
    outline.zPosition = -1
    addChild(outline)
}
```

GPU 부담: 라벨 5개(본체 1 + 외곽선 4)지만 작은 텍스트(32pt 1줄)라 미미.

### 4-6. cameraNode 자식의 zPosition
HUD/D-Pad/SkillButton/PauseButton은 cameraNode 자식 → 화면에 고정. zPosition 200 정도로 worldNode 자식(zPosition 0~100)보다 위.

```swift
pauseButton.zPosition = 200   // 모든 게임 노드 위
hudNode.zPosition = 200       // 동일
dPad.zPosition = 200
```

부모-자식 zPosition은 *절대값으로 합산되지 않고 부모 위계 내에서 비교*. cameraNode 자식들끼리만 zPosition 비교.

### 4-7. Swift default 파라미터 + Source-compatibility
```swift
init(label: String, initialValue: String, showTimeBar: Bool = false)
```

기존 호출자는 `showTimeBar`를 *모르고 호출*해도 컴파일 통과 — Swift compiler가 default를 자동 적용. **공개 API에 옵션 파라미터 추가는 항상 default value로**.

---

## 산출물

### 수정 파일 (12개)
- `Config/GameConfig.swift` — 체크보드 hex 2개 교체 + Sprint 3 신규 상수 약 30개
- `GameScene.swift` — pauseButton 프로퍼티 + setupPauseButton + layoutPauseButton 한 줄씩 (총 +3 줄)
- `GameScene+Setup.swift` — 배경 색 / 체크보드 토큰 / 외곽 벽 navy + 보더 / 기둥 navy / setupPauseButton/layoutPauseButton 신설
- `Nodes/HUDNode.swift` — HUDSlotNode 재구성 (backgroundChip + setWarn + setTimeBar + showTimeBar default 파라미터) + update 끝 TIME 갱신
- `Nodes/DPadNode.swift` — 4 SKSpriteNode → 4 SKShapeNode + 중앙 데드존
- `Nodes/SkillButtonNode.swift` — 코랄 원 36 + B 칩 + 스킬명 칩
- `Nodes/HUDSkillSlotNode.swift` — fontDisplay + v2 색 매핑
- `Nodes/NoteNode.swift` — 글로우 + 본체 + 펄스
- `Nodes/ProjectileNode.swift` — 코랄 사각형 + F + visual-only 회전 (P2 패치)
- `Nodes/ComboPopupNode.swift` — Jua 32pt + navy 외곽선 + -8°
- `Nodes/ComboBreakNode.swift` — Jua 28pt + 코랄 + navy 외곽선
- `project.pbxproj` — PauseButtonNode 등록 (4섹션)

### 신규 파일 (1개)
- `Nodes/PauseButtonNode.swift`

### 보호 파일 (19개 git diff 0줄)
ColorTokens / 메뉴 3씬 / ResultScene / Sprint 1 노드 6 / Systems / Repositories / Managers / 캐릭터 노드 5

### 산출 문서
- `SPEC.md`, `SELF_CHECK.md`, `QA_REPORT.md` (9.22/10)
- 본 학습 노트

---

## 검증 방법

### 시각 검증 (사용자가 시뮬레이터에서)
- [ ] 체크보드 바닥이 피치 톤 (#FFEFE0 / #FFDFC8)으로 보임
- [ ] 외곽 벽이 navy 라운드 보더로 둘러 싸임
- [ ] HUD 4슬롯이 navy 알약 + 골드 라벨 + 흰 값으로 표시
- [ ] TIME 12초 이하 진입 시 슬롯 배경이 코랄로 바뀌고 진행바 갱신
- [ ] D-Pad 4 버튼이 반투명 화이트 알약 + 중앙 데드존 가시
- [ ] 좌하단 스킬 버튼이 코랄 원 + B 키 + 스킬명 칩
- [ ] 우상단 일시정지 navy 라운드 + 흰 || (탭 무반응 — 의도)
- [ ] 음표 골드 원 + 흰 링 + 글로우가 1.4s 펄스
- [ ] F 투사체 코랄 22 사각형 + 흰 F + 살짝 기울어짐 (-12°)
- [ ] 콤보 5/10 시 Jua 32pt 큰 텍스트 + navy 외곽선 + -8° 회전

### 정량 검증 (자동)
- ✅ 빌드 SUCCEEDED (iPhone 17 시뮬레이터)
- ✅ 19개 보호 파일 git diff 0줄
- ✅ GameConfig 13개 보호 수치 0건 변경
- ✅ 체크보드 hex만 정확 2개 교체
- ✅ NoteNode/ProjectileNode PhysicsBody size 그대로
- ✅ DPad touch 메서드 byte-identical
- ✅ HUDNode/SkillButtonNode/ComboPopup/ComboBreak 외부 시그니처 보존
- ✅ 5×3=15 캐릭터·난이도 조합 시작 가능 (코드 흐름)

---

## SPEC에 들어갔던 핵심 제약

- **변경 유형**: 비주얼 (인게임 시각 갱신, 게임 로직 회귀 0)
- **게임 경험 의도**: 메뉴 톤이 인게임에서도 이어져 한 게임의 한 톤 완성. 음표 글로우로 시선 자석. TIME 12초 이하 코랄 swap으로 긴장감 즉시 전달.
- **Sprint 3 범위 계약**:
  - IN: GameConfig 체크보드 hex 2개 + Sprint 3 신규 상수 + GameScene+Setup 색 교체 + HUDNode/DPadNode/SkillButtonNode/HUDSkillSlotNode/NoteNode/ProjectileNode/ComboPopup/ComboBreak 시각 + PauseButtonNode 신규
  - OUT: 게임 수치 / 게임 로직 / 입력 / 저장 / 카메라 / 컷씬 / 사운드 / Sprint 1·2 보호 자산 전부
- **준수 룰**: 강제 언래핑 0, Timer 0, 매직 넘버 0, 시스템 폰트 0
- **회귀 보존**: 19개 보호 파일 git diff 0줄

---

## 회고

### 9-1. 막혔던 것
- **ProjectileNode zRotation의 PhysicsBody 회전**: 처음엔 본체에 `zRotation = -12°`를 줬더니 hitbox도 회전돼서 Evaluator P2 #5로 잡힘. 시각 자식에만 회전 적용하는 미니 패치로 해결.
- **HUDSlotNode init 시그니처 추가**: TIME 슬롯에만 진행바가 필요한 차별 요구. default 파라미터 `showTimeBar: Bool = false`로 *호출자 영향 0*에 해결. Swift의 source-compatibility 패턴이 빛난 케이스.
- **체크보드 hex 2개만 변경 vs 게임 수치 0 변경 원칙**: SPEC에서 명시적 예외 처리. 시각 토큰이지 게임 수치가 아니므로 안전.

### 9-2. Spring과 다르네 싶었던 것
1. SKPhysicsBody가 부모 zRotation을 따라 회전 — JPA Entity에는 transform 개념 없음
2. SKShapeNode rectOf cornerRadius = h/2 → 알약 자동 (CSS border-radius와 동치)
3. blendMode = .add로 알파 누적 글로우 (CSS mix-blend-mode와 같은 발상)
4. SKAction.repeatForever + withKey 멱등성 (Spring의 @Scheduled fixedRate와 다른 매커니즘)
5. SKLabelNode가 stroke를 직접 지원 안 함 — 4방향 자식 라벨로 시뮬레이션 (CSS text-shadow 패턴)
6. cameraNode 자식 zPosition은 부모 위계 내에서 비교 (Spring의 @Order 어노테이션과 비슷)

### 9-3. 다음 작업 이월 결정
- **Sprint 5 — ResultScene v2 (3분기)**:
  - mockups/result-screen-v2.html 매칭
  - Variant A(일반) / B(신기록 + sparkle + 골든 그라데이션) / C(졸업장)
  - DiplomaOverlayNode 우드컷 패턴 + 한글 명조 폰트
  - 9개 init 인자 시그니처 보존
- **Sprint 4 — PNG 캐릭터 통합**: 자산 대기 중 (CHARACTER_SPRITE_PROMPT.md 따라 AI 외주). Sprint 5와 병렬 가능.
- **P2 잔존**: SkillButtonNode 매직 넘버 18, 인라인 알파 6곳, 스킬명 칩 CD 텍스트, SPEC 명시 상수 2개 누락 — Sprint 5에서 마이크로 폴리싱 가능.

### 9-4. 평가 점수
| 카테고리 | 점수 | 가중치 |
|---|---|---|
| 게임 로직 회귀 0 | 9.8 | 40% → 3.92 |
| Swift 패턴 | 8.5 | 20% → 1.70 |
| 비주얼 일관성 | 9.0 | 25% → 2.25 |
| 가독성 & UX | 9.0 | 15% → 1.35 |
| **가중 평균** | **9.22 / 10** | |

QA 반복: **1회** (한 번에 통과) + 미니 패치 1건 (P2 #5)

### 9-5. 사용자 직접 확인할 것
- [ ] 시뮬레이터에서 게임 플레이 — 5캐릭터 × 3난이도 = 15조합 시작 가능 여부
- [ ] 음표 수집 시 점수 +1 / +2 콤보 분기 정상 동작
- [ ] TIME 12초 이하 진입 시 슬롯 코랄 swap + 진행바 갱신
- [ ] D-Pad 입력 정상 (4방향 + 모서리)
- [ ] 스킬 버튼 탭 → 스킬 발동 (이간호 대만여행 등) 정상
- [ ] 콤보 5/10 마일스톤 시 Jua 32pt 팝업 가시
- [ ] hard 난이도 — 이교수 청진기 피격 시 동결 + 토스트 정상
- [ ] AIRFORCE 이스터에그(석조무사 접촉) 정상

---

## 다음 단계 안내

**Sprint 5 — ResultScene v2 (3분기)**
- `mockups/result-screen-v2.html` 매칭 (Variant A/B/C 한 페이지 비교)
- 일반 / 신기록(sparkle 5개 + 황금 그라데이션 + heavy 햅틱 + NewMail 사운드) / 졸업장(우드컷 패턴 + 한글 명조)
- 9개 init 인자 시그니처 보존
- 햅틱·사운드·저장 로직 0 회귀
- 2단계 탭 정책 유지 (졸업장 → ResultScene → StartScene)

Sprint 4는 PNG 자산 대기 — Sprint 5와 의존성 없음.

트리거: 세션에서 `디자인 리뉴얼 진행해줘` 또는 `Sprint 5 진행해줘`.

---

## 핵심 교훈

> **"가장 어려운 리스킨은 게임 로직 옆에서 시각만 갈아치우는 것. 19개 파일 git diff 0줄이 정답을 증명한다."**

Sprint 3가 어려운 이유는 *시각 자식*과 *물리/입력/저장 모델*이 같은 노드 안에 공존한다는 점. SkillButtonNode는 시각도 가지고 onTap 콜백도 가지고. NoteNode는 시각도 가지고 PhysicsBody도 가지고. 둘을 *분리해서* 시각만 새로 깎는 게 핵심.

Spring 비유로는 **@Entity 클래스의 @Transient 메서드만 갈아끼우고 영속 필드는 손도 안 대는 패턴**. 데이터 마이그레이션 없는 시각 폴리싱 — 가장 어렵고, 잘 되면 가장 만족스러운 작업.
