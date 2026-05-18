# Phase 7-4 학습 노트 — 졸업장 시스템

## 오늘 만든 것

한 캐릭터로 **하/중/상 3난이도를 모두 클리어**하면 게임 종료 화면에 *황금색 졸업장*이 자동으로 뜹니다:

```
       CERTIFICATE OF GRADUATION
             실습 수료 증서

  다사다난한 실습을 마치고 김간호는 드디어 졸업하였다.
  이제 세상이라는 악보 위에 마음껏 노래를 부르며
  자유롭게 살 것이다.

2026-05-18                hgfolio · 김간호는 음악박사
              TAP TO CONTINUE
```

목표 점수: **하 60점 / 중 50점 / 상 30점** (원본 웹 게임 그대로).
졸업 일시는 *최초 1회만 저장*되고 그 후엔 영원히 동일.

## 두 가지 점수 저장소가 *동시에* 살아 있어요

기존 `HighScoreRepository`는 *전체 최고 점수 1개* 만 저장해요.

```swift
// 기존 — 단일 점수
let score = scoreSystem.score
let isNewBest = highScoreRepo.record(score)
let bestScore = highScoreRepo.current
```

졸업장에는 *캐릭터별·난이도별 9개 점수*가 필요해요. 그래서 **새 저장소** 를 추가했어요:

```swift
// 신규 — 매트릭스 (CharacterID × Difficulty)
perDiffRepo.record(characterID: characterID, difficulty: difficulty, score: score)
```

**중요: 둘 다 동시에 호출**. 기존 저장소를 *없애지 않고* 새 저장소를 *옆에* 추가. 이래서 단일 점수를 쓰는 다른 곳(TitleScene BEST 라벨 등)이 그대로 동작 — **회귀 0**.

**Spring 비유** — 새 기능이 필요할 때 *기존 Service를 수정*하지 말고 *새 Service를 별도로 만들고 둘 다 호출*. Strangler Fig 패턴.

## JSON 직렬화 — enum 키 처리 함정

Swift의 `Dictionary` 는 `[Difficulty: Int]` 같은 enum 키를 *자체적으로는* 지원해요. 그런데 `JSONEncoder`로 인코딩하면 *Array 형식*이 돼요:

```json
[".easy", 60, ".normal", 50, ...]
```

사람이 읽기도 어렵고, 다른 시스템과 호환도 어렵죠. 그래서 *수동 변환*을 했어요:

```swift
// 저장 직전: enum → rawValue (String) 변환
var raw: [String: [String: Int]] = [:]
for (charID, inner) in matrix {
    var innerRaw: [String: Int] = [:]
    for (diff, s) in inner {
        innerRaw[diff.rawValue] = s   // .easy → "easy"
    }
    raw[charID.rawValue] = innerRaw   // .kim → "kim"
}
let data = try JSONEncoder().encode(raw)
```

저장된 JSON:
```json
{
  "kim": {"easy": 62, "normal": 55, "hard": 35},
  "jung": {"easy": 30}
}
```

훨씬 *사람이 읽을 수 있는* 형식. 디버그할 때 UserDefaults 덤프로 바로 이해 가능.

**Spring 비유** — JPA Entity에서 enum 필드를 `@Enumerated(EnumType.STRING)`으로 저장하는 것과 동일. DB 컬럼에 `"EASY"` 같은 사람이 읽을 수 있는 값을 박아두는 정책.

## ISO8601 Date — 로케일·타임존 안전

졸업 일시를 어떻게 저장할까? 후보:

| 방식 | 예시 | 문제 |
|---|---|---|
| TimeInterval (Double) | `676800000.0` | 사람이 못 읽음. 디버그 어려움. |
| 로컬 String | `2026/05/18 오후 3:42:11` | 로케일 따라 다름. 다른 폰으로 옮기면 깨짐. |
| **ISO8601** | `2026-05-18T15:42:11Z` | UTC 기준. 어디서 읽어도 동일. |

ISO8601 채택. Apple 권장이고 `ISO8601DateFormatter`가 표준 지원:

```swift
let isoFormatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f
}()
```

*저장*은 ISO8601, *표시*는 `DateFormatter("yyyy-MM-dd")` 로 별도. 저장과 표시를 분리.

**Spring 비유** — `@JsonFormat(shape = STRING, pattern = "yyyy-MM-dd'T'HH:mm:ssXXX")` — REST API JSON에서 Date를 ISO8601로 직렬화하는 표준. 같은 발상.

## "멱등성" — 한 번 졸업하면 영원히 동일한 일시

여기서 *핵심* 정책이 있어요:

> **한 번 졸업한 캐릭터는 다시 졸업 조건을 만족해도 일시가 갱신되지 않는다.**

코드 한 줄에 박혀 있어요:

```swift
func record(characterID: CharacterID, date: Date) -> Bool {
    var dict = current
    if dict[characterID] != nil { return false }   // ← 이 한 줄
    dict[characterID] = date
    // ... 저장 ...
    return true
}
```

이미 졸업한 캐릭터의 entry가 있으면 즉시 false 반환. *디스크 미변경*. *기존 일시 보존*.

왜 이렇게? 졸업의 의미는 *그 순간*이에요. 다시 깬다고 졸업 일시가 갱신되면 "내가 언제 졸업했지?"의 답이 매번 바뀜. *최초의 그날*이 영원히 박제되어야 의미가 있어요.

**Spring 비유** — `@CreatedDate` (생성 시점)와 `@LastModifiedDate` (수정 시점)의 차이. 졸업 일시는 **`@CreatedDate` 부류**. 한 번 정해지면 영원히 안 바뀜.

## "graceful 실패" — 인코딩 실패해도 앱은 안 죽어

JSON 인코딩이 실패하면? `try?` 로 받아서 nil이면 false 반환:

```swift
guard let data = try? JSONEncoder().encode(raw) else { return false }
defaults.set(data, forKey: key)
return true
```

- 인코딩 실패 → false 반환
- false → `isNewGraduation = false`
- ResultScene에서 졸업장 *미표시*
- 앱은 *정상 진행*

다음 판에 다시 시도하면 성공할 수 있어요. *한 번의 실패가 앱 전체를 죽이지 않는다*.

**Spring 비유** — `@Retryable` + `@Recover`. 실패 시 *재시도 가능*하고, 영구 실패해도 *대안 동작*으로 graceful 처리.

## 졸업장 노드도 *자가 소멸 11호*

Phase 6-13(카운트다운), 7-3(컷씬), 그리고 이번 7-4(졸업장) 모두 *비슷한 구조*예요:

| 노드 | 발사 조건 | dismiss 조건 |
|---|---|---|
| 8호 CountdownNode | 시간 (3-2-1-GO! 4초) | 시간 자동 |
| 9호 ScorePopupNode | 음표 수집 | 시간 (0.6초) |
| 10호 CutsceneOverlayNode | 게임 시작 | **터치** |
| 11호 DiplomaOverlayNode | 신규 졸업 | **터치** |

10호와 11호는 *터치 트리거*. 같은 패턴이라 11호는 10호를 *거의 그대로* 베꼈어요. *코드 중복* 같지만, *학습 곡선 0* 이라 일관성 우선.

**Spring 비유** — `JpaRepository` 도메인마다 새로 정의해도 *구조가 동형*. 중복 같지만 *예측 가능성*이 더 큰 가치.

## 졸업 판정 — `Difficulty.allCases` 의 마법

3 난이도 모두 클리어했는지 어떻게 검사할까? `if/else`로 풀어쓸 수도 있지만:

```swift
private static func isGraduated(characterID: CharacterID,
                                scores repo: PerDifficultyScoreRepository) -> Bool {
    let targets = GameConfig.targetScoreByDifficulty
    for difficulty in Difficulty.allCases {
        let target = targets[difficulty] ?? Int.max
        if repo.best(characterID: characterID, difficulty: difficulty) < target {
            return false   // 하나라도 미달이면 즉시 false
        }
    }
    return true   // 전부 통과
}
```

`Difficulty.allCases` 가 *자동으로* `.easy`, `.normal`, `.hard` 3개를 순회. 미래에 `.veryHard` 같은 새 case가 추가되면 *자동으로* 검사 대상에 들어가요. 단, GameConfig.targetScoreByDifficulty에 대응 값이 없으면 `?? Int.max` 폴백으로 *무조건 미달* 처리. 안전.

**Spring 비유** — `EnumSet.allOf(Difficulty.class).stream().allMatch(...)`. enum 자체가 *컬렉션*처럼 동작.

## ResultScene factory의 default 인자 = 회귀 0의 황금카드

기존 호출자는 6개 인자로 ResultScene을 만들고 있었어요:

```swift
ResultScene.newResultScene(score: ..., bestScore: ..., isNewBest: ...,
                           stats: ..., characterName: ..., difficulty: ...)
```

이번에 *2개 인자*를 추가했어요:

```swift
class func newResultScene(
    score: Int, bestScore: Int, isNewBest: Bool, stats: GameStats,
    characterName: String, difficulty: Difficulty,
    isNewGraduation: Bool = false,    // ← default
    graduatedAt: Date? = nil           // ← default
) -> ResultScene { ... }
```

기존 호출자(6개 인자)는 *한 줄도 안 고치고도* 컴파일 통과해요. default 값이 자동으로 채워지니까. macOS/tvOS의 GameViewController 같은 *모바일 외 진입점*도 영향 0.

**Spring 비유** — `@RequestParam(defaultValue = "false")` 처럼 *옵셔널 파라미터*에 기본값을 둬서 backwards-compatible. API 진화의 정석.

## 회귀 0의 최종 검증

이번 sprint 변경 파일:
- 신규 3개: PerDifficultyScoreRepository, GraduationRepository, DiplomaOverlayNode
- 수정 4개: GameConfig (+57줄), GameScene (+15줄), ResultScene (+30줄), pbxproj (+12줄)

다른 *30+ 파일*은 git diff **0줄**. 회귀 위험 차단의 다층 안전망:
1. HighScoreRepository 그대로 (병행 운용)
2. ResultScene factory default 인자 (기존 호출자 영향 0)
3. 신규 UserDefaults 키 (기존 키 충돌 0)
4. DiplomaOverlayNode 자가 소멸 (ARC 정리, ResultScene 흐름 영향 0)
5. GraduationRepository 멱등 (이미 졸업 시 false → 매번 안 뜸)
6. graduatedAt nil 가드 (`if isNewGraduation, let graduatedAt`)

## 오늘의 한 줄

> *"한 번의 졸업이 영원히 그날의 일시로 남는다 — 한 줄 가드 `if dict[id] != nil { return false }` 가 그 의미를 코드 레벨에서 강제한다."*
