# Sprint 7 Phase D — "점수가 주인공 + 기록 보기 신설"

> 결과창에서 점수·BEST·캐릭터·난이도가 한 자리에 몰려 헷갈리던 걸 정리하고, 새 ScoreboardScene으로 5×3 기록 매트릭스를 띄운 이야기.

---

## 1. 무엇이 문제였어?

결과 화면에 정보가 *너무 많이* 한 자리에 몰려 있었어:

- 화면 중앙: **♪ 0** (점수 + 음표가 한 글자처럼 붙어 있음)
- 점수 위: SCORE 라벨
- 점수 아래: BEST 0 (작은 글씨)
- 우상단: 캐릭터·난이도 라벨

5개 정보가 가까이 모여 있으니 시선이 "어디부터 봐야 하지?" 망설였지. 점수가 주인공이 되어야 하는데 ♪랑 SCORE 라벨이 점수를 가려.

또 캐릭터·난이도별 *내 최고 기록*을 보고 싶어도 진입점이 없었어. "내가 김간호 하 난이도에서는 몇 점이지?" 같은 호기심을 풀 수 없었지.

---

## 2. 어떻게 고쳤어?

**점수 주변에 정보 5종을 *영역*으로 분리**했어:

```
┌────────────────────────────────────────────┐
│   [김간호 · 하]   ← 캐릭터·난이도 (헤더 위)│
│      실습 종료    ← 타이틀                 │
│                                            │
│   ♪  142  🏆 BEST 200    ← 한 줄에 좌·중·우│
│       SCORE                                │
│                                            │
│   ─────────────────                        │
│   N회  N장                                  │
│                                            │
│ [📊 기록 보기] [공유 2]    [다시 시작 ▶]   │
└────────────────────────────────────────────┘
```

- **♪ 24pt** (작게) → 점수 좌측 옆에 부속
- **점수 64pt** → 시각 주인공 (가운데)
- **🏆 BEST GlassPill** → 점수 우측 옆
- **SCORE 라벨** → 점수 아래
- **캐릭터·난이도 칩** → 타이틀 위로 끌어올림
- **📊 기록 보기 신규 칩** → 공유 칩 좌측 (신규 진입점)

그리고 "📊 기록 보기" 탭하면 **신규 ScoreboardScene**으로 가서 5명 × 3난이도 = 15셀 매트릭스를 보여줘.

---

## 3. 신규 ScoreboardScene — 15셀 매트릭스

```
              하        중        상
김간호    🌸  142       98        —
정간호    🌿   —        76       120
건간호    🌙   88       —         —
임간호    ⚡  200★      150       60   ← 직전 게임 신기록 셀
이간호    💧  120       95        —

           총 플레이 38회 · 졸업장 4장 보유
```

- **15셀**: `PerDifficultyScoreRepository.current[character][difficulty]`에서 점수 읽기
- **빈 셀 "—"**: 점수 0인 셀 (아직 안 한 조합)
- **★ 마커**: 직전 게임에서 신기록 갱신한 (캐릭터, 난이도) 셀에만
- **하단 stat**: `StatisticsRepository.current.playCount` + `GraduationRepository.current.count`

데이터를 *읽기만* 해. 저장·갱신 0건. DB 영향 0.

---

## 4. 핵심 패턴 1 — bestLabel 시각만 차단 + 노드 보존

**기존 BEST 라벨**(`bestLabel: SKLabelNode`)을 새 BEST GlassPill로 *시각만* 대체했어. 노드 자체는 그대로 두고 `alpha = 0`:

```swift
// configureBestLabelV2 안 마지막에 추가
bestLabel.alpha = 0   // 시각만 차단, 노드 트리 보존
```

왜? 기존에 `startBestLabelGoldBlink` 같은 *액션*이 이 라벨에 부착되어 있어. 노드를 *지우면* 액션이 자식 노드를 잃고 *깨질* 수 있어. alpha=0이면 액션은 정상 동작하지만 *보이지 않을* 뿐.

Spring 비유: `@Component`를 `@ConditionalOnProperty(enabled=false)`로 비활성화. 빈은 등록되어 있지만 외부에서 호출 안 됨. 안전.

---

## 5. 핵심 패턴 2 — ResultReturnContext struct로 9-인자 복귀

ScoreboardScene → ResultScene 복귀 시 *새 ResultScene 인스턴스*를 만들어야 해. 9개 인자(점수, BEST, 신기록 플래그, stats, 캐릭터 이름, 난이도, 졸업장 플래그, 졸업 날짜)를 *모두* 가지고 있어야 init 가능.

선택지:
- **옵션 A (채택)**: 9 인자를 `ResultReturnContext` struct로 묶어서 ScoreboardScene에 통째로 전달. 복귀 시 그대로 다시 init.
- 옵션 B: ScoreboardScene이 init 인자 9개를 받음 (시그니처 너무 복잡)
- 옵션 C: SKScene push/pop (SpriteKit 표준 아님)

```swift
struct ResultReturnContext {
    let finalScore: Int
    let bestScore: Int
    let isNewBest: Bool
    let stats: GameStats
    let characterName: String
    let difficulty: Difficulty
    let isNewGraduation: Bool
    let graduatedAt: Date?
}
```

복귀 시 *졸업장 재표시 차단*:
```swift
ResultScene.newResultScene(
    /* 8개 인자 */,
    isNewGraduation: false,    // ← 강제 false
    graduatedAt: nil           // ← 강제 nil
)
```

이미 한 번 본 졸업장을 또 띄우면 *불쾌*. 명시적으로 차단.

Spring 비유: 페이지 이동 시 SessionScope DTO를 모델에 담아서 다음 화면이 그대로 받아 쓰는 패턴. 9개 필드를 묶는 게 깔끔.

---

## 6. 핵심 패턴 3 — CharacterID 역변환 헬퍼

ResultScene init은 `characterName: String`만 받지 `CharacterID`는 안 받아(시그니처 변경 금지). 그런데 ★ 마커를 부착할 셀 좌표 계산에는 *CharacterID enum*이 필요해.

해결: *역변환 헬퍼* 추가.

```swift
private var inferredCharacterID: CharacterID? {
    CharacterID.allCases.first { $0.displayName == characterName }
}
```

5명 displayName이 모두 다르니까("김간호"/"정간호"/"건간호"/"임간호"/"이간호") *유일성* 보장. 안전.

비유: DB의 `name` 컬럼으로 `id`를 찾는 SELECT. 인덱스 없는 lookup이지만 5건뿐이라 비용 무시 가능.

---

## 7. 핵심 패턴 4 — CharacterFaceNode.mini 32px 팩토리

ScoreboardScene 좌측 행 헤더에 5명 미니 얼굴을 띄워야 했어. 기존 CharacterFaceNode는 *큰 사이즈*(약 68pt). 작게 만드는 방법은?

**옵션 A (채택)**: setScale로 축소. 신규 코드 0줄.

```swift
static func mini(id: CharacterID) -> CharacterFaceNode {
    let face = CharacterFaceNode(id: id)
    face.setScale(GameConfig.scoreboardMiniFaceScale)  // 0.47 (32/68)
    face.name = "miniFace_\(id.rawValue)"
    return face
}
```

- 5명 build* 메서드 100% 재사용
- 신규 path/시각 자식 0
- *축소된 결과*만 다르게 보임

Spring 비유: Wrapper 패턴. 기존 컴포넌트를 *어떤 데코레이터*로 감싸서 다른 모습으로 제공.

---

## 8. Repositories는 *읽기만* — 저장 호출 0건

ScoreboardScene이 데이터를 화면에 그릴 때 3개 Repository를 *읽기만* 해:

```swift
let best = perDiffRepo.current[character]?[difficulty]  // 읽기
let plays = statsRepo.current.playCount                  // 읽기
let graduations = graduationRepo.current.count           // 읽기
```

`record/save/update` 같은 *저장* 함수는 **0건 호출**. grep으로 검증:

```bash
$ grep -E "perDiffRepo.(record|save)|statsRepo.(record|save)|graduationRepo.(record|save)" ScoreboardScene.swift
# 결과 0건
```

이게 *디자인 리뉴얼 모드*의 핵심 원칙 — 시각 작업이 데이터 레이어를 *오염*하지 않음. DB 마이그레이션 비유: 읽기 전용 view 만들기. 원본 테이블은 보존.

---

## 9. Xcode pbxproj 등록

신규 Swift 파일(ScoreboardScene.swift)은 *Xcode 프로젝트 파일*(`project.pbxproj`)에 4줄 정도 등록해야 컴파일됨:

- `PBXBuildFile` 1줄
- `PBXFileReference` 1줄
- `PBXGroup` (Scenes 그룹) 안 children에 1줄
- `PBXSourcesBuildPhase` (Sources) 안 files에 1줄

이 단계가 빠지면 Generator가 만든 파일이 *디스크에는 있는데 빌드에서 빠지는* 망령 상태가 돼. Generator가 pbxproj까지 정확히 편집한 게 합격의 핵심.

Spring 비유: 새 controller 클래스를 만들었는데 `@ComponentScan` 경로에 빠져 있어 빈 등록 안 되는 상황. *위치*가 맞아야 컴파일러/런타임이 찾음.

---

## 10. 잔존 P2 — `bestLabel` 깜빡임

`bestLabel.alpha = 0`을 설정했지만, 신기록 분기 시 부착된 `startBestLabelGoldBlink` 액션이 *계속* 작동해. alpha를 0.5↔1.0로 무한 fade. 시각상 0.5~0 깜빡이는 *흐릿한* 효과가 안 보이는 위치(점수 아래 -60pt — 새 위치에서는 비어있음)에서 깜빡이고 있어.

차후 정리 후보:
```swift
bestLabel.removeAction(forKey: GameConfig.newBestBlinkActionKey)
```
한 줄 추가하면 깜빡임 중단. 또는 alpha 0 강제 유지. SPEC §주의사항 1에서 의도적 보존을 선택했고 합격 영향 없음.

---

## 11. 다음(Phase E)은 뭐야?

**카운트다운 오버레이 — 게임 시작 시 3·2·1·GO!**

현재 게임은 시작 후 1~2초간 *멈춘 듯 보이는* 시간이 있어. 입력은 막혀 있는데 시각 피드백 0. "고장 났나?" 느낌.

Phase E에서 GameScene 시작 시 `CountdownNode`를 보강해서:
- 0~1초: "3" 표시 (scale 1.0 → 1.4 + fade)
- 1~2초: "2"
- 2~3초: "1"
- 3~3.8초: "GO!" (코랄, scale 1.2 → 1.8)
- 3.8~4.0초: dim 페이드 아웃, 입력 활성화

총 4초. 영화 시작 전 카운트다운처럼 *준비 시간*을 시각화. 게임 루프·물리·점수 계산은 *0건* 건드림. 입력 게이트만 카운트다운 종료 시점과 일치.

변경 LOC ~100 예상. Phase D보다 훨씬 작은 작업.
