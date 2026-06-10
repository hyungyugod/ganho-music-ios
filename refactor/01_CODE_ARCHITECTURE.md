# 01_CODE_ARCHITECTURE — 코드 재구조화 설계서 (R0·R1 중심)

> 목표: "게임 개발 교과서" 수준의 구조. 의존 방향 단방향, 1파일 1책임, 설정은 도메인별 분리, 런타임 할당 최소화.
> 인용된 파일:라인이 현재 코드와 다르면 코드가 진실. Planner는 차이를 SPEC.md에 기록.

---

## 1. 현재 진단 (분석 근거 요약)

| 문제 | 근거 | 처방 |
|---|---|---|
| god-config | `Config/GameConfig.swift` 3,869줄. 게임 수치+UI 레이아웃+직렬화 키+에셋명+버전 변형값 혼재 | §3 도메인 7분할 |
| 버전 suffix 누적 | `skillButtonZPositionV4`, `resultWidePanelHeightV12` 등 | §4 suffix 박멸 규칙 |
| dead code | `SpawnSystem.projectileBurstCount` 외 2개(L39~ 주석 "호출처 0이지만 즉시 삭제 X — 후속 정리 sprint에서" ← 그 후속 정리가 바로 R0), `PlayerNode.baseSpeedEnd`(L53 정의·L171 대입, update 미사용), `CharacterFullBodyNode.swift`(L5 "사용처 제거됨 — 파일 삭제 후보"), `EnemyNode.isFleeing` 부분 구현 | §6 삭제 목록 |
| 좀비 노드 | ResultScene L324-336 legacy 라벨 7종 addChild 후 alpha=0/isHidden 차단. 씬 전체 30+ 노드 | R5에서 재작성으로 박멸 |
| 중복 4벌 | `updatePixelDirection`+`tickWalkFrame`+`refreshTexture`+static textureCache가 PlayerNode·EnemyNode·ProfessorNode·StoneGuardNode에 복붙 | §5 프로토콜 추출 |
| 매 프레임 전체 순회 | `GameScene+DangerWarnings.swift` L32-46 `enumerateChildNodes` ×2/frame, `currentNoteCount()` 등 카운트 패턴 다수 | §7 EntityRegistry |
| 풀링 없음 | 음표·투사체·이펙트 모두 생성/파괴 반복 | §8 ObjectPool |
| 바닥 640노드 | `GameScene+Setup.swift` L45-71, 32×20 SKSpriteNode | §9 단일 텍스처화 |
| 물리 하이브리드 | position 직접 수정 + `physicsBody?.velocity = .zero` 매 프레임 리셋 (PlayerNode L317) | 유지하되 §10에 의도 문서화 |

---

## 2. 타겟 폴더 구조 (R0 완료 시점)

```
GanhoMusic Shared/
├── Core/                       ← 게임 무관 유틸 (어디에도 의존 안 함)
│   ├── ObjectPool.swift            (제네릭 풀, R1)
│   ├── EntityRegistry.swift        (R1)
│   ├── Tween.swift                 (타이밍 커브, R2)
│   ├── SeededRandom.swift          (일일 도전용, R6)
│   └── FrameStats.swift            (DEBUG 프레임 측정, R1)
├── Config/                     ← 상수만. 로직 금지
│   ├── GameplayTuning.swift        (이동·스폰·AI·스킬·콤보·난이도 수치)
│   ├── FeelTuning.swift            (히트스톱·셰이크·파티클·햅틱·SFX 수치, R2)
│   ├── MetaTuning.swift            (별·XP·언락·일일도전 수치, R6)
│   ├── UILayout.swift              (씬·노드 레이아웃 상수)
│   ├── Palette.swift               (v3 색 토큰 — 기존 ColorTokens 대체)
│   ├── Typography.swift            (폰트·타입 스케일)
│   ├── ZOrder.swift                (전역 zPosition 레이어 표)
│   ├── PhysicsCategory.swift       (기존 유지)
│   ├── StorageKeys.swift           (UserDefaults·클라우드 키 — 기존 키 문자열 불변)
│   └── AssetNames.swift            (에셋·사운드 이름)
├── Models/                     ← 순수 데이터 (기존 유지 + 정리)
├── Rendering/
│   ├── PixelSpriteRenderer.swift   (기존 이동)
│   ├── PixelSprite.swift           (기존 이동, 데이터 byte-equal)
│   ├── PixelPalette.swift          (기존 이동, 데이터 byte-equal)
│   └── TextureAtlasStore.swift     (R1 — 모든 텍스처 단일 진입점)
├── Systems/                    ← 게임 로직 (Scene이 소유, Node를 조작)
│   ├── SpawnSystem.swift / SkillSystem.swift / ScoreSystem.swift / ContactRouter.swift (기존)
│   ├── CameraDirector.swift        (R2 — 셰이크·줌·킥 통합)
│   ├── HitstopController.swift     (R2)
│   ├── EffectDirector.swift        (R2 — 파티클·플래시·팝업 발주 창구)
│   └── MetaProgressSystem.swift    (R6)
├── Audio/
│   ├── AudioManager.swift / BGMPlayer.swift (기존 이동)
│   └── ChiptuneSynth.swift         (R2 — 프로시저럴 SFX)
├── Haptics/
│   └── HapticsManager.swift        (기존 이동, R2에서 CoreHaptics 확장)
├── Nodes/
│   ├── Gameplay/                   (Player·Enemy·Professor·StoneGuard·SergeantPark·Note·AItem·FProjectile·Map·Airplane…)
│   ├── HUD/                        (HUDNode·HUDSkillSlotNode·DPadNode·ComboGaugeNode(R7)…)
│   ├── UI/                         (R3 Pixel 컴포넌트 키트 + 기존 버튼·칩 대체)
│   └── Effects/                    (Sparkle·HitFlash·ScorePopup·MilestoneBanner… → R2에서 풀링 대응)
├── Scenes/                     ← 오케스트레이터만. 로직은 Systems로
│   ├── BaseMenuScene.swift / StartScene.swift / CharacterSelectScene.swift
│   ├── SkillBriefingScene.swift    (구 SkillExplanationScene, R4 개명)
│   ├── DifficultySelectScene.swift / GameScene.swift(+확장들) / ResultScene.swift / ScoreboardScene.swift
│   └── SceneRouter.swift           (R3 — 전환 단일 창구)
├── Managers/                   (FirebaseAuthManager·CloudSaveCoordinator — 공개 API 불변)
├── Repositories/               (기존 + MetaProgressRepository(R6))
├── Protocols/ Errors/          (기존)
```

**의존 방향(강제)**: `Scenes → Systems → Nodes → Models/Rendering → Core`, `Config는 모두가 참조 가능, Config는 아무것도 참조 금지(UIColor·CGFloat 등 프레임워크 타입 제외)`. 역방향 import가 필요해 보이면 프로토콜/클로저 주입으로 해결 (기존 `progressProvider: () -> Double` 패턴 계승).

Xcode 프로젝트는 폴더 이동을 반영해야 한다. 그룹 구조 변경이 과대 작업이면 R0에서는 **파일 분할·삭제·신규 생성을 우선**하고 물리 폴더 이동은 최소화해도 된다(단, 신규 파일은 반드시 타겟 구조 위치에).

---

## 3. GameConfig 분할 명세 (R0 핵심 작업)

`enum GameConfig` 3,869줄 → §2의 Config 파일들로 분배. 매핑 규칙:

| 현재 상수 성격 | 이동처 |
|---|---|
| 이동 속도·dpad·스폰 간격·발사 간격·burst·콤보 임계·목표 점수·스킬 쿨다운/범위 | `GameplayTuning` |
| 씬 전환 시간·셰이크·팝업 폰트 크기 등 연출 수치 | `FeelTuning` |
| 패널 폭·여백·버튼 크기·safe area 보정 등 레이아웃 | `UILayout` |
| 색 참조(`menuSolidBackgroundColor` 등) | `Palette` (R3 전까지는 임시로 기존 값 유지) |
| `fontDisplay`·`fontBody`·`fontNumeric`·폰트 크기 | `Typography` |
| zPosition 상수 전부 | `ZOrder` |
| UserDefaults 키 문자열 | `StorageKeys` — **문자열 값 절대 불변** |
| 에셋·사운드 파일명 | `AssetNames` |

분할 후 `GameConfig.swift`는 **삭제**한다. 과도기 호환용 `typealias`나 재export는 금지 — 호출부를 전부 갱신한다(전역 치환 가능: `GameConfig.` → 해당 도메인).

## 4. 버전 suffix 박멸 규칙

1. 같은 의미의 `xxxV4`/`xxxV7`/`xxxV12` 중 **현재 코드가 실제 참조하는 최신값만** 남긴다.
2. 남긴 상수는 suffix를 떼고 base 이름으로 개명 (`resultWidePanelHeightV12` → `resultWidePanelHeight`).
3. 참조 0건인 구버전 상수는 삭제.
4. 검증: `grep -rnE "V[0-9]+\b" --include="*.swift"` 결과에서 버전 suffix 상수 0건 (R0 합격 게이트).

## 5. 캐릭터 스프라이트 공통화 (R0)

PlayerNode·EnemyNode·ProfessorNode·StoneGuardNode 4벌 복붙 로직을 추출:

```swift
/// 16×20 픽셀 캐릭터의 4방향 + 걷기 프레임 공통 구현
protocol PixelCharacterAnimating: AnyObject {
    var spriteSheetID: String { get }          // 텍스처 캐시 키 prefix
    var facingDirection: Direction { get set }
    var walkFrameIndex: Int { get set }
}
extension PixelCharacterAnimating where Self: SKSpriteNode {
    func refreshPixelTexture() { ... }          // TextureAtlasStore에서 조회
    func tickWalkFrame(dt: TimeInterval) { ... }
}
```

각 노드의 static 텍스처 캐시 4벌은 R1의 `TextureAtlasStore` 단일 캐시로 통합한다 (R0에서는 프로토콜 추출까지, 캐시 통합은 R1).

## 6. 삭제 목록 (R0에서 전부 처리, 처리 결과를 SELF_CHECK에 표로 보고)

| 대상 | 조치 |
|---|---|
| `SpawnSystem`의 `projectileBurstCount`·`projectileFireIntervalStart`·`projectileFireIntervalEnd` | 삭제 (주석에 "호출처 0" 명시됨) |
| `CharacterFullBodyNode.swift` | 삭제 (L5 "사용처 제거됨 — 파일 삭제 후보") |
| `PlayerNode.baseSpeedEnd` | **삭제 금지** — R2에서 속도 곡선으로 활성화 예정. R0에서는 `// R2에서 활성화` 주석만 |
| `EnemyNode.isFleeing` 부분 구현 | 박병장 도주(5초)와 실연동 여부 확인 → 사용 중이면 유지, 미사용이면 삭제 (Planner 판단, SPEC에 명기) |
| ResultScene legacy 라벨 7종(`titleLabel`·`statsLabel` 등 alpha=0 차단분) | R0에서 노드·참조 삭제 (씬 전면 재작성은 R5) |
| `ColorTokens.swift` 미사용 세대 토큰 (다크 계열 `ganhoUIBg` 등 중 참조 0건) | 참조 0건만 삭제. 파일 자체는 R3에서 `Palette.swift`로 대체 |
| `GradientBackgroundNode` | 참조 0건이면 삭제 (R3 배경은 신규 구현) |
| `.codex/` 폴더, 루트 `SPEC.md`·`SELF_CHECK.md`·`QA_REPORT.md` 잔존물 | 하네스 산출물은 .gitignore 등재 확인만 (삭제는 하네스 단계 0이 수행) |

## 7. EntityRegistry (R1)

매 프레임 `enumerateChildNodes(withName:)` 순회를 O(1) 캐시로 대체:

```swift
final class EntityRegistry {
    private(set) var projectiles: [FProjectileNode] = []
    private(set) var notes: [NoteNode] = []
    private(set) var stethoscopes: [StethoscopeNode] = []
    func register(_ node: SKNode) { ... }      // spawn 시
    func unregister(_ node: SKNode) { ... }    // 회수 시
    func compact() { ... }                      // isAlive == false 정리, 프레임당 1회
}
```

- 소유: GameScene이 1개 생성, SpawnSystem·DangerWarnings·SkillSystem에 주입.
- 규칙: **spawn/recycle 경로는 반드시 Registry를 경유** (직접 addChild 금지 — SpawnSystem 내부로 한정).
- `currentNoteCount()` 등 카운트 함수는 전부 `registry.notes.count`로 대체. R1 합격 게이트: update 경로 `enumerateChildNodes` 0건.

## 8. ObjectPool (R1)

```swift
final class ObjectPool<T: SKNode & Poolable> {
    func obtain() -> T          // 없으면 factory 생성
    func recycle(_ node: T)     // removeFromParent + reset() + 보관
}
protocol Poolable: AnyObject { func resetForReuse() }
```

풀 대상(최소): `FProjectileNode`(예열 12), `NoteNode`(예열 16), `StethoscopeNode`(예열 6), `ScorePopupNode`(예열 8), R2 파티클 이펙트 노드들. 예열은 씬 `didMove` 직후 1회. `SKAction.wait + removeFromParent` 자기 파괴 패턴은 풀 대상 노드에서 **회수 콜백으로 교체**.

## 9. 바닥·텍스처 (R1)

- 체커보드 640개 `SKSpriteNode` → **1장의 사전 렌더 텍스처**(UIGraphicsImageRenderer로 32×20 체커보드를 1회 그려 SKSpriteNode 1개) 또는 `SKTileMapNode`. 전자 권장(코드 단순).
- `TextureAtlasStore`: 캐릭터·아이템·이펙트 텍스처의 유일한 생성·캐시 지점. `SKTexture(filteringMode: .nearest)` 일괄 적용. 기존 4벌 static 캐시 제거.
- BGM `setRate` 매 프레임 호출 (GameScene.swift L227) → 값 변화 시에만 호출하도록 가드.

## 10. 명시 문서화할 기존 의도 (변경하지 말 것)

- 플레이어 이동: position 직접 수정 + velocity 매 프레임 0 리셋 — 정밀 wall-slide를 위한 의도된 하이브리드. 주석으로 근거 문서화.
- 모든 동적 노드 `collisionBitMask = 0` + contactTest만 사용 — 성능 의도. 유지.
- ProfessorNode 벽 통과(physicsBody 없음) — 위협 설계 의도. 유지.

## 11. 코딩 규칙 (기존 계승 + 추가)

기존 `docs/swift-rules.md`·`docs/spritekit-rules.md` 전부 유효. 추가:

1. 파일 300줄 초과 시 분리 (기존 규칙 재확인 — ResultScene·CharacterSelectScene 위반 중).
2. `// MARK: -` 섹션 필수: Properties / Lifecycle / Layout / Actions / Private.
3. 상수는 호출부에서 `GameplayTuning.enemyPatrolSpeed`처럼 도메인이 읽히게.
4. 신규 public 타입에 문서 주석(`///`) 필수 — "왜"를 적는다 (무엇은 코드가 말함).
5. 좀비 패턴 금지: **노드를 숨겨서 유지하지 말고 삭제**한다. A/B 비교가 필요하면 git이 한다.
6. 디버그 전용 코드는 `#if DEBUG`로 격리 (FrameStats, 히트스톱 토글 등).

## 12. 테스트·검증 전략

- 유닛 테스트 타겟이 없으므로 신설은 R6에서만 (마이그레이션 검증용 최소 1파일 — `MetaMigrationTests`).
- 그 외 Phase는 하네스 Evaluator의 빌드 검증 + grep 감사 + 정량 게이트(노드 수·LOC·참조 0건)로 대체.
- 스모크 절차(R0·R4·R5 필수): 시뮬레이터에서 Start→캐릭터→난이도→게임 45초→결과→기록→홈 1회 주행, 콘솔 에러 0건.
