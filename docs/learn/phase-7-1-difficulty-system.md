# Phase 7-1 학습 노트 — 난이도 3단계 시스템 (하/중/상)

## 오늘 만든 것

시작 화면에 **"하"**, **"중"**, **"상"** 카드 3장이 생겼어요.
- **하**: 여유로운 실습 (민트색) — 음표 안 사라짐, 수간호사 느릿
- **중**: 긴장의 병동 (노란색) — 음표 3.5초 후 사라짐, F 동시 3발
- **상**: 이교수의 청진기 (빨간색) — 음표 2.8초, F 동시 4발, 수간호사 무시무시

탭하면 카드가 *반짝 커지고* 다른 카드는 *살짝 어두워져요*. 한 번 고른 난이도는 *앱을 꺼도 기억돼요*.

## "단일 진실 원천"이라는 사고

GDD §5의 표가 **단일 진실 원천(single source of truth)** 이에요. 코드에 들어간 숫자는 *전부 이 표에서 가져온 것* 이고, 표가 바뀌면 코드도 한 군데(GameConfig)만 고치면 돼요.

**Spring 비유** — `application-easy.yml`, `application-normal.yml`, `application-hard.yml` 같은 profile별 설정 파일과 똑같은 발상. 게임에선 *enum dict*로 표현했어요.

```swift
static let enemySpeedStartByDifficulty: [Difficulty: CGFloat] = [
    .easy: 60, .normal: 170, .hard: 200
]
```

이 한 줄이 GDD 표의 한 행(수간호사 속도 시작값)을 그대로 옮긴 거예요. 표를 보면 코드를 알고, 코드를 보면 표를 알게 만들었어요.

## 두 가지 설계 옵션이 있었어요

**옵션 A**: GameConfig에 함수를 만들어요.
```swift
static func noteMaxConcurrent(for d: Difficulty) -> Int { ... }
```
- 부르는 쪽: `GameConfig.noteMaxConcurrent(for: difficulty)`
- 단점: 기존 코드(`GameConfig.noteMaxConcurrent`로 직접 부르던 자리)를 *전부* 고쳐야 해요. **회귀 위험 ↑**.

**옵션 B (채택)**: 노드/시스템이 *자기 수치를 자기가 가진다*.
```swift
class SpawnSystem {
    private var noteMax: Int = GameConfig.noteMaxConcurrent  // default = easy
    func apply(_ difficulty: Difficulty) {
        noteMax = GameConfig.noteMaxConcurrentByDifficulty[difficulty] ?? noteMax
    }
}
```
- 부르는 쪽: 그냥 `self.noteMax`
- 장점: **기존 코드 하나도 안 고쳐도 됨** — apply를 부르지 않으면 그대로 easy 수치로 동작.

**Spring 비유** — 옵션 A는 *static utility 메서드*, 옵션 B는 *@ConfigurationProperties로 받은 빈*. Spring에서도 *빈을 주입받아 객체가 자기 설정을 가지는 게* 더 깔끔하잖아요. 같은 이유.

## "graceful fallback"이라는 안전망

dict에서 값을 꺼낼 때 *없는 키*를 넣으면 nil이 와요. Swift는 그걸 컴파일 타임에 다 잡아주는데, 우리는 추가 안전망을 깔았어요:

```swift
noteMax = GameConfig.noteMaxConcurrentByDifficulty[difficulty] ?? noteMax
                                                                  ^^^^^^^
                                              "dict에 없으면 기존 값(easy) 유지"
```

만약 누가 미래에 *.veryHard* 같은 케이스를 enum에 추가했는데 dict에 빠뜨려도 게임이 멈추지 않고 *easy 수치로 자연 폴백* 해요.

**Spring 비유** — `@Value("${some.key:defaultValue}")` 처럼 *기본값을 명시*하는 거랑 똑같아요. *null이 들어와도 죽지 않게 만들기*.

## "회귀 0"을 자연 차단하는 6가지 메커니즘

큰 sprint일수록 *기존 동작을 망가뜨릴* 위험이 커요. 이번엔 6중 안전망:

1. **GameScene init이 default 인자** — `newGameScene(characterID: .kim, difficulty: .easy)`. macOS/tvOS 코드가 *하나도 안 고쳐졌는데도* 컴파일 통과.
2. **GameConfig 기존 단일 상수 보존** — `playerBaseSpeed=140` 그대로 살아있음. apply 부르지 않은 자리는 자동으로 easy.
3. **dict[.easy] == 기존 단일 상수** — 27개 값이 한 셀씩 검증됨. easy 선택 시 *기존 게임과 완전히 동일*.
4. **NoteNode TTL의 `.infinity` 가드** — easy는 `.infinity`라 wait+fade+remove 시퀀스가 *아예 안 붙음*. 기존 동작 그대로.
5. **F burst 루프 easy=1** — `for _ in 0..<1`은 그냥 1번 = 기존 1발 발사와 똑같음.
6. **카드 hit test 우선순위** — 난이도 카드 → 캐릭터 카드 → 게임 시작. 매치되면 즉시 `return` 으로 다른 처리 차단.

**Spring 비유** — *Backwards compatibility*. 기존 API 호출자가 *아무것도 모르고도 그대로 동작*하도록 새 기능을 추가하는 방식. 큰 시스템에서 가장 중요한 기술이에요.

## "스프린트 범위 계약" — 큰 sprint 쪼개기

원래 GDD §5 표에는 *맵 종류*, *이교수 등장*, *목표 점수* 같은 항목도 있어요. 그런데 이번 sprint에선 *명시적으로* 제외했어요:

- ❌ 이교수 NPC (NPC 자체가 미구현)
- ❌ hard 맵 (맵 자체가 미구현)
- ❌ 석조무사 등장 분기
- ❌ 목표 점수
- ❌ 컷씬

왜? 한 번에 다 묶으면 변경 파일이 *15+개*로 폭증해서 *1차 합격 확률이 급감*해요. 차라리:

1. 이번 sprint: 난이도 3단계 + 수치 차등 (변경 파일 13개)
2. 다음 sprint: hard 맵 1개
3. 그 다음 sprint: 이교수 NPC

이렇게 *작은 합격*을 여러 번 쌓는 게 *큰 불합격* 1번보다 빨라요.

**Spring 비유** — 큰 PR 1개 vs 작은 PR 5개. 작은 PR이 리뷰도 빠르고 머지도 빠르고 롤백도 쉬워요. 같은 원리.

## 영구 저장 패턴 답습 — Repository 3호

이미 캐릭터 영구 저장(`CharacterPreferenceRepository`)이 있어서, 그걸 *완전 동형*으로 베꼈어요. 이름만 다르고 구조 동일:

```swift
final class DifficultyPreferenceRepository {
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    var current: Difficulty {
        let raw = defaults.string(forKey: GameConfig.difficultyPreferenceUserDefaultsKey) ?? ""
        return Difficulty(rawValue: raw) ?? .easy
    }

    func save(_ id: Difficulty) {
        defaults.set(id.rawValue, forKey: GameConfig.difficultyPreferenceUserDefaultsKey)
    }
}
```

**Spring 비유** — Spring Data JPA의 `Repository<Entity, ID>` 인터페이스 패턴. 한번 만들어두면 *다음 도메인은 베끼기만 해도* 작동.

## SpriteKit "자가 소멸" 패턴이 NoteNode에도 도착

이전 sprint들에서 만든 *자가 소멸 노드 9형제* 패턴을 NoteNode에도 적용했어요. 일반 음표는 *영원히 살지만*, 난이도가 hard면 *2.8초 후에 알아서 사라져요*.

```swift
func applyLifetime(_ ttl: TimeInterval) {
    guard ttl.isFinite, ttl < GameConfig.gameDuration else { return }  // easy 자연 noop
    let wait = SKAction.wait(forDuration: ttl)
    let fade = SKAction.fadeOut(withDuration: 0.2)
    let remove = SKAction.removeFromParent()
    run(.sequence([wait, fade, remove]), withKey: "noteLifetime")
}
```

`.infinity` 같이 *말도 안 되는 값*이 들어오면 `isFinite` 가드로 *아무 일도 안 일어남*. 안전한 추가.

## TitleScene UI 한 줄 더

기존에 캐릭터 카드 5장이 한 줄에 있었어요. 거기 *위쪽*에 난이도 카드 3장을 추가했어요. 캐릭터 카드의 y 좌표를 -160 → -200으로 한 칸 내려서 공간을 만들었어요.

```
+80 : 제목
+20 : BEST
-20 : PLAYS
-80 : TAP TO START
-120: [하] [중] [상]      ← 신규
-200: [김간호][이임간][황간][..][..]
```

이 한 줄 변경(`characterCardOffsetY: -160 → -200`)이 *난이도 카드의 자리*를 만든 거예요.

## 오늘의 한 줄

> *"같은 게임을 세 가지 톤으로 들려주기 — 카드 한 장 선택이 27개 수치를 바꾼다"*
