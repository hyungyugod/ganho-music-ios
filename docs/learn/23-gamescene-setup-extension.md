# 23 · GameScene Setup 분리 — Swift `extension` 패턴 🧹

> **이번 작업 한 줄**: GameScene의 setup/add 메서드 9개를 별도 파일(`GameScene+Setup.swift`)로 옮긴다. 클래스는 *그대로 한 클래스*, 다만 *코드를 두 파일에 나눠 적기*. **기능 변화 0**의 순수 리팩터.

---

## 1. 왜?

Phase 3-5 종결 시점에 GameScene이 **340줄**이 됐다. SpriteKit 룰(`docs/spritekit-rules.md` §11)은 **300줄 이상이면 분리 신호**라고 적어 둔다. Phase 4(추가 NPC)에 들어가면 또 수십 줄이 늘 텐데, 들어가기 *전에* 한 번 정리하면 다음 sprint들이 깨끗하다.

지난 Phase 2-10/11/12에서는 **시스템 분리**(SpawnSystem, ContactRouter, ScoreSystem)로 줄였지만, 이번엔 **Swift 고유 문법** — `extension`을 처음 써본다.

---

## 2. Spring 비유 ⭐

| Swift | Spring/Java | 한 줄 설명 |
|---|---|---|
| `extension GameScene { ... }` | (Java에는 직접 대응 X) | 같은 클래스를 *여러 파일에 나눠* 정의 |
| `class GameScene` (본체) | 컨트롤러 본체 | 핵심 로직(생명주기·게임 루프) |
| `extension GameScene` (Setup) | (Java라면) `GameSceneSetup` 헬퍼 클래스 + `@Autowired` | "초기화 책임"만 묶은 별도 파일 |
| `private` 멤버 접근 | (Java) `default` 가시성 + 같은 패키지 | extension은 *같은 클래스*라 private 멤버 자유 접근 |

**핵심**: Swift `extension`은 *같은 클래스 안*. Java에는 없는 문법. **Kotlin partial class** 또는 **C# partial class**와 같은 개념. 한 클래스를 *논리적 그룹별로 다른 파일에 적기*.

> Spring으로 치면 "한 컨트롤러를 *진짜 한 클래스*로 두지만, 메서드 정의만 다른 파일로 나눠 적는" 행위. Java에선 안 되니 헬퍼 클래스 + DI로 우회하지만, Swift는 *언어 차원에서 직접 지원*.

---

## 3. 새로 배운 것 (Swift) ⭐

### 3-1. **`extension` 기본**

```swift
// 파일 A: GameScene.swift
class GameScene: SKScene {
    private let player = PlayerNode()

    override func didMove(to view: SKView) {
        setupPlayer()    // 다른 파일에 정의된 메서드 호출
    }
}

// 파일 B: GameScene+Setup.swift
extension GameScene {
    func setupPlayer() {
        player.position = ...   // private 프로퍼티 자유 접근
        addChild(player)
    }
}
```

**같은 클래스**. 컴파일러가 두 파일을 합쳐서 한 GameScene 클래스로 만든다.

### 3-2. **파일명 컨벤션 — `Type+Feature.swift`**

```
GameScene.swift          ← 본체 (생명주기, update, endGame)
GameScene+Setup.swift    ← Setup 메서드 모음
```

- `+` 기호로 *어떤 책임을 추가했는지* 표시
- Apple/Swift 커뮤니티 표준 컨벤션
- Xcode 네비게이터에서 `GameScene` 옆에 자연 정렬

> Spring으로 치면 패키지 안에 `GameSceneController.java` + `GameSceneControllerSetup.java`로 두는 것과 비슷한 *가독성용 분할*.

### 3-3. **private 멤버 접근 — `extension`은 같은 클래스**

```swift
class GameScene: SKScene {
    private let worldNode = SKNode()    // private!
}

extension GameScene {
    func setupWorld() {
        addChild(worldNode)    // ✅ 접근 가능 — 같은 클래스니까
    }
}
```

**조건**: 두 파일이 *같은 모듈* 안. 본 프로젝트는 GanhoMusic Shared 모듈이라 OK.

> Spring/Java로 치면: 같은 패키지의 `default` 가시성과 비슷한 자유. 단 *진짜 같은 클래스*라 더 자유. private 멤버까지 OK.

### 3-4. **무엇을 옮길지 — "초기화 책임" 한 묶음**

이번에 옮길 9개:
```
setupBackground()     // 배경색
setupWorld()          // 월드 노드 + 호출
  addOuterWalls()     // 외곽 벽 4개
  addCentralPillar()  // 중앙 기둥
setupPlayer()         // 플레이어 위치
setupCamera()         // 카메라
setupDPad()           // D-Pad 부착
setupHUD()            // HUD 부착
setupEnemy()          // 적 위치
```

**공통 의도**: *씬 진입 시 1회 호출되어 노드 트리를 짓는다*. didMove에서만 호출. 한 묶음.

남는 것 (본체):
- 생명주기 (didMove, didChangeSize)
- layout* (viewport 변할 때 위치 재계산 — *지속적 호출*)
- update (게임 루프)
- ContactRouter 콜백 등록
- endGame

> Spring으로 치면: "초기화 빈"과 "런타임 핸들러"의 분리.

### 3-5. **기능 변화 0의 *순수 리팩터***

이번 작업의 핵심 약속: **코드 결과는 한 줄도 안 바뀐다.** 사용자 입장에서는 시뮬레이터 실행 결과가 *완전 동일*. 바뀌는 건 *파일 구조*뿐.

> Spring으로 치면 "기능 회귀 없이 패키지 구조만 정리"하는 PR. 가장 안전한 리팩터의 형태.

---

## 4. 무엇을 만드나?

### 새 파일 (1개)
| 파일 | 내용 |
|---|---|
| `GameScene+Setup.swift` | `extension GameScene { setupBackground / setupWorld / addOuterWalls / addCentralPillar / setupPlayer / setupCamera / setupDPad / setupHUD / setupEnemy }` 9개 메서드 이전 |

### 고치는 파일 (1개)
| 파일 | 변경 |
|---|---|
| `GameScene.swift` | 위 9개 메서드 *제거* (본체는 시그니처만 남기지 않고 통째 삭제, extension에서 정의) + 파일 헤더 주석에 분리 사실 1줄 추가 |

### Xcode pbxproj
- `GameScene+Setup.swift` 등록 (Shared 그룹·iOS 타겟 Sources phase). 기존 패턴(`A1C0F1A0..0016` / `A1C0F1B0..0016` 식별자) 답습.

### 한 그림으로

```
[기존]
GameScene.swift (340줄)
  ├ Properties / Factory / Lifecycle
  ├ Setup × 9     ← 이번에 분리
  ├ Update / ContactRouter
  └ endGame

[새]
GameScene.swift (≈250줄)
  ├ Properties / Factory / Lifecycle
  ├ Update / ContactRouter
  └ endGame

GameScene+Setup.swift (≈100줄)
  └ extension GameScene
      └ Setup × 9
```

---

## 5. 직접 확인할 것

⌘R 후:

| # | 시나리오 | 봐야 할 것 |
|---|---|---|
| (a) | 앱 시작 → 타이틀 | 평소처럼 정상 (시각 변화 X) |
| (b) | 게임 시작, 한 판 플레이 | 모든 기능 정상 (player/enemy/D-Pad/HUD/벽/기둥/음표/F) |
| (c) | 게임오버 | ResultScene 정상 |
| (d) | 결과 → 타이틀 → 다시 게임 | 새 GameScene 인스턴스가 setup 9개 호출, 정상 작동 |
| (e) | 시뮬레이터 회전(viewport 변경) | layoutDPad/layoutHUD 정상 (본체에 그대로) |

> **핵심**: 시나리오 (a)~(e) 결과가 Phase 3-5 끝났을 때와 *완전 동일*해야 함. 한 픽셀이라도 다르면 회귀 발생 — 즉시 롤백.

---

## 6. 사용자 결정 (이미 합의)

| 결정 | 선택 | 왜 |
|---|---|---|
| 분리 방식 | **Swift `extension`** | 같은 클래스로 유지, private 멤버 자유 접근, Apple 커뮤니티 표준 |
| 파일명 | **`GameScene+Setup.swift`** | `+` 컨벤션 (Type+Feature) |
| 옮길 범위 | **A1 — setup/add 9개** | 한 책임("씬 짓기") 묶음. layout은 본체 |
| 기능 변화 | **0** (순수 리팩터) | 회귀 위험 ↓, 다음 sprint 토대 |

---

## 7. 회고

### 7-1. 막혔던 것 — *Swift `private`의 진짜 의미를 잘못 알고 있었다* ⚠️

**SPEC을 쓸 때 가정한 것**: "extension은 *같은 클래스*이므로 같은 모듈이면 `private` 멤버에 자유 접근".

**실제 Swift 규칙**: `private`은 **같은 파일 + 같은 타입** 한정. 다른 파일의 `extension`은 *같은 모듈*이어도 `private` 멤버 접근 *불가*.

빌드 첫 시도에 컴파일 에러 9건 발생. Generator가 정정:
- 본체 `private let worldNode/cameraNode/player/enemy/dpad/hud/...` → `let worldNode/...` (internal 기본)
- 신설 9개 메서드 `private func` → `func` (internal 기본)

**왜 이렇게 헷갈렸나?** Java/Kotlin에서 `private`은 *같은 클래스* 한정인데, Swift는 *같은 파일* 한정이다. 이 차이를 모르면 SPEC을 잘못 쓸 수 있다.

### 7-2. 새로 배운 것 ⭐

#### 7-2-1. **Swift 접근 제어 5단계**

| 키워드 | 가시 범위 | 한 줄 |
|---|---|---|
| `private` | **같은 파일 + 같은 타입** | "이 파일·이 타입 안에서만" |
| `fileprivate` | 같은 파일 (타입 무관) | "이 파일 안에서만" |
| `internal` (기본) | 같은 모듈 | "이 앱·이 라이브러리 안에서만" |
| `public` | 다른 모듈에서도 사용 가능 | "라이브러리 사용자도 보임" |
| `open` | 다른 모듈에서 상속/오버라이드까지 가능 | "확장도 허용" |

**핵심 함정**: `private`은 *같은 파일*이라 다른 파일의 extension에서 못 쓴다. *Java의 `private`이 같은 클래스라면*, **Swift의 `private`은 같은 파일 + 같은 타입**. 더 빡빡한 셈.

> Spring/Java로 치면: Swift `private` ≈ Java `private` + *같은 .java 파일* 추가 조건. Java 한 파일에 한 클래스라 자연스럽지만, Swift는 *partial class처럼 한 클래스를 여러 파일에 나눠 적기* 때문에 file 경계가 의미를 가짐.

#### 7-2-2. **`extension`의 정확한 정의**

`extension Type { ... }`은 *같은 클래스*에 메서드/프로퍼티 추가. 단:
- *같은 모듈* 안이면 어디서든 `extension` 가능
- *다른 모듈*이어도 `public`/`open` 멤버는 `extension`으로 확장 가능
- 하지만 **`private`/`fileprivate` 멤버는 *그 파일* 안에서만** 보인다 — 같은 클래스 extension이라도 다른 파일이면 못 본다

#### 7-2-3. **`private extension` 패턴 (대안)**

```swift
private extension GameScene {
    func setupBackground() { ... }   // 이 파일 외부에서 호출 불가
}
```

이러면 *extension 자체를 file-private*로 좁힐 수 있다. 다만 본 sprint에서는 *본체 didMove(다른 파일)에서 호출*해야 하므로 적용 불가. 본체와 같은 파일에 setup이 있을 때만 의미 있는 패턴.

#### 7-2-4. **synchronized folder + membershipExceptions**

Xcode 16+의 `PBXFileSystemSynchronizedRootGroup` — 폴더 안의 *모든 .swift*가 자동으로 빌드 대상. 단, *명시적으로 제외*하려면 `membershipExceptions` 목록에 등록. GameScene.swift처럼 *iOS/tvOS/macOS 타겟별로 다른 가시성*을 가지려면 그 목록을 활용.

`+` 문자가 든 파일명은 plist 식별자 규약상 *unquoted 금지* → `"GameScene+Setup.swift"`처럼 따옴표 필수.

#### 7-2-5. **순수 리팩터의 정의 = byte-for-byte 보존**

이번 sprint의 약속 = "코드 결과 한 줄도 안 바뀐다." Evaluator가 *baseline diff*로 검증한 결과:
- 9개 메서드 본문 byte-for-byte 일치
- 차이 = `private` → `func` 1단계 완화 + `layoutDPad`/`layoutHUD` 본체 잔존 (SPEC 명시)

이런 *극도로 보수적인* 변경은 회귀 위험을 0에 수렴시킨다.

### 7-3. 다음으로 미룬 것

- **Phase 4 진입**: 추가 NPC (석조무사·이교수·박병장 비행기) — AI 패트롤, 이벤트 트리거
- **저장소 통합** (옵션 C): HighScore + Stats 단일 모델로 흡수 + 마이그레이션
- **`private extension` 패턴**: 후속 sprint에서 가시성 축소 전략 검토 (P2 권고)

### 7-4. 평가 점수

- **가중평균: 9.65 / 10 — 합격**
- 항목별: Swift 패턴 9 / 게임 로직 10 / 성능·안정성 10 / 기능 완성도 10
- P0 0건, P1 0건, P2 2건 (헤더 주석 사실 오류 — 즉시 정정 완료 / `private extension` 패턴 — 별도 sprint 권고)
- 빌드: BUILD SUCCEEDED, 경고 0건

### 7-5. 코드 라인 변화

| 파일 | 변화 |
|---|---|
| `GameScene.swift` | 340 → 209줄 (**-131, -38%**) |
| `GameScene+Setup.swift` (신설) | 0 → 145줄 |
| 합계 | 340 → 354줄 (+14, 헤더 주석 추가분) |

**가치**: 절대 줄 수는 비슷하지만 *책임 분리* 명확화. 본체는 게임 루프와 종료에 집중, extension은 초기화에 집중. spritekit-rules §11(300줄 가이드) 회복.

### 7-6. 의외의 부산물 — SPEC의 가정 오류 학습

SPEC을 *완벽하게* 쓰는 건 사실상 불가. Generator가 빌드로 가정 오류를 발견하면 *합리적 정정*하는 게 정상 흐름. 본 sprint에서 그 첫 사례를 경험. **하네스가 안전망이 되어 SPEC 오류를 감지·정정·문서화**한 셈.

---

## 8. 다음 작업

```
[1] 시뮬레이터에서 §5 (a)~(e) 확인 (회귀 0)
[2] 다음 sprint: Phase 4 진입
```

> **이번 sprint 본질**: Swift `extension`이라는 *언어 고유 문법* 첫 등장. 한 클래스를 여러 파일로 *나눠 적기*가 언어 차원에서 지원된다. Java에는 없는 이 문법은 *책임이 늘어나는 핵심 클래스*를 깔끔하게 분할하는 가장 자연스러운 도구. Phase 2-10/11/12의 시스템 분리(별도 클래스)와는 결이 다른 *같은 클래스 내 분할*.
