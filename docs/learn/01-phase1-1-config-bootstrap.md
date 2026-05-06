# 01 · Phase 1-1 · 게임 만들기 전 "작업장 정리"

> **이번 작업은 게임 로직을 한 줄도 만들지 않는다.**
> 비유하면, 가구 만들기 전에 작업대 위에 자·연필·끌·페인트통을 가지런히 놓는 단계.

---

## 1. 한눈 요약

```
지금 (Hello World 템플릿)              이번 작업 후
┌──────────────────────┐             ┌──────────────────────┐
│  Hello, World!       │             │                      │
│  (회전하는 박스 + 터치 │      ──→    │     GanhoMusic       │  ← 자리표시 라벨만
│   하면 도형 생기는    │             │                      │
│   샘플 코드)          │             │   (검은 배경, 가로)  │
└──────────────────────┘             └──────────────────────┘
       ❌ 게임 코드 아님                ✅ 빈 캔버스 = 출발선
```

**+ 보이지 않는 곳에서**: 앞으로 모든 게임 코드가 import 해서 쓸 **공용 정의 4종**(상수·상태·물리 카테고리·색상)을 미리 만들어 둔다.

---

## 2. 무엇을, 왜?

### 무엇을 만드나
| 만드는 것 | 한 줄 설명 | 비유 |
|---|---|---|
| `GameConfig` | 게임 시간(45초), 플레이어 속도, 타일 크기 같은 **상수 모음** | "설정 파일" |
| `GameState` | 게임이 지금 `대기/플레이/일시정지/종료` 중 어떤 상태인지 표현 | "신호등" |
| `PhysicsCategory` | 충돌 시스템에서 "이건 플레이어/이건 음표/이건 적/이건 벽" 구분용 비트마스크 | "출입증 종류" |
| `ColorTokens` | 코드에서 색을 쓸 때 `UIColor.brandCoral`처럼 의미로 부르게 해주는 색상 사전 | "회사 브랜드 컬러 가이드" |
| 빈 `GameScene` | Hello World 템플릿 코드를 걷어내고 **검은 배경 + 라벨 1개**만 남김 | "빈 컨트롤러" |

### 왜 지금?
- 이 4종은 **앞으로 만들 모든 파일이 의존**한다. 먼저 깔아놓지 않으면 PlayerNode·NoteNode마다 매직 넘버가 박힌다.
- Spring으로 치면, 비즈니스 코드 짜기 전에 `application.yml`·`Constants.java`·도메인 enum을 먼저 정의하는 것과 같다.
- 빈 GameScene으로 교체하는 건, **Xcode가 만들어준 샘플 코드를 지워야 우리 코드를 깨끗하게 시작**할 수 있어서.

---

## 3. Spring 비유 🌱

| 이번에 만드는 것 | Spring/Java 세계 |
|---|---|
| `Config/GameConfig.swift` | `application.yml` + `@Value` 주입되는 상수들. 또는 `final class GameConstants` |
| `Config/GameState.swift` | 도메인 상태 enum. 예: `OrderStatus { PENDING, PAID, SHIPPED }` |
| `Config/PhysicsCategory.swift` | 직접 대응 없음. **비트마스크 권한** 같은 것 (Spring Security `GrantedAuthority`의 비트 버전) |
| `Config/ColorTokens.swift` | 백엔드엔 없는 개념. 프론트의 design token (CSS 변수) 가까움 |
| 빈 `GameScene` | `@RestController` 클래스를 만들고 `@RequestMapping`만 잡아둔 빈 컨트롤러 |

**핵심 원칙**: `Config/`는 의존성이 **나가지 않는** 가장 안쪽 레이어. 누구나 import 하지만 자기는 누구도 모른다. Spring의 `config/` 패키지와 동일한 위치다.

---

## 4. Swift 학습 포인트 📘

### 4-1. `enum`을 case 없이 → "네임스페이스"로 사용
Java에서 상수 모음은 보통 이렇게:
```java
public final class GameConstants {
    private GameConstants() {}        // 인스턴스화 막기
    public static final double GAME_DURATION = 45.0;
}
```

Swift는 case 없는 `enum`이 같은 일을 더 깔끔하게:
```swift
enum GameConfig {
    static let gameDuration: TimeInterval = 45
    static let playerSpeed: CGFloat = 200
}
// 사용
let t = GameConfig.gameDuration
```

case가 없으니 인스턴스 생성 자체가 **불가능**. 자바의 `private constructor` 트릭을 컴파일러가 강제한다.

### 4-2. `enum`은 Java enum + sealed class
```swift
enum GameState {
    case waiting
    case playing
    case paused
    case gameOver
}
```

여기까진 Java enum과 거의 같다. Swift만의 강점은 **associated value**:
```swift
case error(String)            // 에러 메시지 같이 들고 다님
case loading(progress: Double)
```

이건 Kotlin sealed class에 가깝고, Java에선 못 한다.

### 4-3. `struct` (값 타입) vs `class` (참조 타입)
```swift
struct PhysicsCategory {              // 인스턴스 안 만들고 정적 멤버만 쓸 거지만
    static let player: UInt32 = 0b0001
    static let note:   UInt32 = 0b0010
    static let enemy:  UInt32 = 0b0100
    static let wall:   UInt32 = 0b1000
}
```

원칙: 데이터만 담는 작은 객체는 `struct`(값 복사). 정체성·생명주기가 있는 객체는 `class`(참조). Java 14+ `record`가 `struct`와 비슷.
- `SKNode`를 상속하는 우리 `PlayerNode`·`NoteNode`는 SpriteKit 요구상 무조건 `class`.
- 점수·좌표 같은 값 객체는 `struct` 기본.

### 4-4. `extension`으로 기존 타입에 정적 멤버 추가
```swift
import UIKit

extension UIColor {
    static let brandCoral = UIColor(red: 0.77, green: 0.52, blue: 0.48, alpha: 1.0)
    static let floorDark  = UIColor(red: 0.10, green: 0.09, blue: 0.14, alpha: 1.0)
}

// 사용
view.backgroundColor = .brandCoral
```

내가 만들지 않은 `UIColor`에 멤버를 **외부에서** 추가했다. Java에는 없음. Kotlin extension function이 비슷.

### 4-5. 비트마스크 = 충돌 권한
```swift
0b0001  // player
0b0010  // note
0b0100  // enemy
0b1000  // wall
```

물리 충돌 설정 시 "**이 노드는 player고, note·enemy랑만 충돌 검사하고, wall과는 물리적으로 막힌다**"를 비트 OR로 표현:
```swift
player.physicsBody?.categoryBitMask    = PhysicsCategory.player
player.physicsBody?.contactTestBitMask = PhysicsCategory.note | PhysicsCategory.enemy
player.physicsBody?.collisionBitMask   = PhysicsCategory.wall
```

겹치면 안 되니 `0b0001`, `0b0010`, `0b0100`처럼 **2의 거듭제곱**으로만 정의한다.

### 4-6. `// MARK: -` 는 Xcode 네비게이터용 헤더
```swift
// MARK: - Properties
// MARK: - Lifecycle
// MARK: - Setup
```

파일이 길어지면 Xcode 좌측 점프 메뉴에 굵게 표시되어 점프 가능. Java IDE의 `// region/endregion` 정도.

### 4-7. SpriteKit 좌표계 = 좌하단 (0, 0)
UIKit은 좌상단 (0,0). SpriteKit은 수학 좌표계(좌하단). 헷갈리는 부분이라 빈 씬부터 인지하고 시작.
```
(0, height) ──── (width, height)
     │                │
  (0, 0) ──────── (width, 0)
```

---

## 5. 산출물 (예정)

### 새로 만드는 파일
| 파일 | 책임 |
|---|---|
| `GanhoMusic Shared/Config/GameConfig.swift` | 게임 상수 enum (시간·속도·타일 크기 등) |
| `GanhoMusic Shared/Config/GameState.swift` | 게임 상태 enum (waiting/playing/paused/gameOver) |
| `GanhoMusic Shared/Config/PhysicsCategory.swift` | 충돌 비트마스크 struct |
| `GanhoMusic Shared/Config/ColorTokens.swift` | UIColor extension (브랜드/팔레트 색상) |

### 수정하는 파일
| 파일 | 변경 |
|---|---|
| `GanhoMusic Shared/GameScene.swift` | Hello World 템플릿 제거 → 빈 씬으로. `gameState: GameState`, `lastUpdateTime` 프로퍼티만 보유. `didMove(to:)`에서 배경색 + 자리표시 라벨 표시. |

### 절대 손대지 않는 파일
- `GanhoMusic iOS/AppDelegate.swift`, `SceneDelegate.swift`, `GameViewController.swift` — Phase 0에서 검증 끝
- `GanhoMusic tvOS/`, `GanhoMusic macOS/` — 멀티플랫폼 정책상 유지보수 대상 아님

---

## 6. 검증 방법 ✅

```bash
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
  -scheme "GanhoMusic iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build
```

**합격 조건**:
- 빌드 에러 0개, 경고 최소
- 시뮬레이터(`⌘R`)에서 **검은 배경 + "GanhoMusic" 라벨**만 보임
- 가로 모드 강제 (Phase 0 설정 유지)
- Hello World의 회전 박스/터치 도형 효과 ❌ (사라져야 함)

---

## 7. SPEC에 들어갈 핵심 제약 (Planner에게 전달)

- **변경 유형**: 비주얼 (빈 씬)
- **게임 경험 의도**: "프로젝트가 살아 있다"만 보여줌. 인터랙션 없음.
- **Sprint 범위 계약**: 위 산출물 외 파일 만들지 않음. 음표·적·HUD·입력은 건드리지 않음.
- **준수 룰**: `!` 강제 언래핑 0개 / `Timer` 0개 / `print()` 0개 / `MARK: -` 사용
- `update()`는 dt 보간 골격만, `gameState != .playing`이면 즉시 return (본문 비워도 OK)

---

## 8. 회고 (작업 후 채움) 📝

### 8-1. 막혔던 것 — Xcode 16의 "동기화 폴더" 함정 ⚠️
**가장 큰 변수**: Xcode 16+의 `PBXFileSystemSynchronizedRootGroup` (디스크에 파일을 만들면 자동으로 프로젝트가 인식하는 새 기능)이 **하위 폴더(`Config/`)에 만든 .swift 파일은 자동 인식하지 못했다**. 그냥 파일을 만들기만 하면 컴파일 대상에 포함되지 않아 "use of unresolved identifier 'GameConfig'" 같은 에러가 난다.

해결: Generator가 `project.pbxproj`를 직접 편집해 `PBXBuildFile` / `PBXFileReference` / `PBXGroup` / `PBXSourcesBuildPhase` 항목을 4개 추가했다(편집 전 `.bak` 백업도 같이). iOS 타겟에만 등록, tvOS/macOS는 제외.

> **Spring 비유**: Spring Boot의 `@ComponentScan`이 자동으로 클래스를 스캔하지만, 멀티모듈에서 다른 모듈 패키지가 스캔 범위 밖이면 인식 안 되는 것과 비슷. 빌드 시스템에 "이 폴더도 컴파일 대상"이라고 명시해야 한다.

> **Phase 1-2 이후 영향**: `Nodes/`, `Systems/` 등 다음 폴더에 첫 .swift 파일을 추가할 때 이 작업이 매번 필요. Generator가 미리 인지하도록 SPEC에 메모 남길 것.

### 8-2. Spring과 다르네 싶었던 것
1. **`enum`이 네임스페이스 역할**: Java에선 `final class Constants { private constructor }` 보일러플레이트가 필요한데, Swift는 `enum GameConfig {}` 한 줄이면 끝. 컴파일러가 인스턴스화를 원천 차단.
2. **`extension`으로 남의 타입 확장**: Apple이 만든 `UIColor`에 내가 정적 멤버를 추가했다. Java에선 utility class 만들어서 우회해야 하는 일.
3. **`UInt32` 비트마스크가 1급 시민**: Spring 백엔드에선 비트 권한 시스템을 거의 안 쓰는데, SpriteKit에선 충돌 카테고리에 비트마스크가 표준. `0b0001` 리터럴이 가독성 좋음.
4. **`SKScene`은 자기 인스턴스를 생성하는 `class func`을 갖는다** (`newGameScene()`): Spring의 정적 팩토리 메서드 패턴과 같지만, SpriteKit에선 씬 로딩 관습으로 굳어진 패턴.
5. **`_ = dt`로 unused 경고 회피**: Java에서 `@SuppressWarnings("unused")` 자리에 Swift는 `_ = variable`. 변수를 의도적으로 "버린다"는 신호.

### 8-3. 다음 작업으로 이월된 결정
1. **Xcode 동기화 그룹 등록**: 1-2에서 `Nodes/` 폴더 첫 파일 추가 시 동일 패턴 필요 — SPEC에 미리 명시할 것
2. **`GameScene.sks` 활용 여부**: 현재 빈 sks 파일 잔존. Phase 1-2에서 코드로만 갈지 sks로 갈지 결정
3. **Asset Catalog 16색 Color Set 등록**: `ColorTokens`의 RGB fallback이 dead code 되는 시점에 정리
4. **`Menlo-Bold` 임시 폰트 → 둥근모꼴 픽셀 폰트 교체**: Phase 4 일괄 작업
5. **`.xcodeproj/project.pbxproj.bak` 백업 파일** 정리 여부 — 빌드 무영향이지만 깔끔하게 가려면 삭제

### 8-4. 평가 점수 (QA_REPORT.md 기준)
- Swift 패턴: **10 / 10** (강제 언래핑·Timer·print·abort·fileprivate 모두 0건)
- 게임 로직 / 의도 충실도: **9 / 10** (SPEC §기능 1~5와 1바이트 단위 일치)
- 성능 / 메모리 안전성: **10 / 10** (누수 위험 0, 빌드 경고 0)
- 기능 완성도 / 빌드: **9 / 10** (`BUILD SUCCEEDED`, 시각 확인은 사용자 수동)
- **가중평균: 9.6 / 10 — 합격**

### 8-5. 사용자가 직접 확인할 것 ✅
시뮬레이터(`⌘R`)에서 5가지:
- (a) 검은 배경 (`#1A1B2E` 톤) — `ganhoBgDeep` 색
- (b) 화면 중앙에 "GanhoMusic" 라벨 1개
- (c) 회전하는 둥근 사각형 ❌
- (d) 화면 터치 시 도형 생성 ❌
- (e) 가로 모드 강제 (Phase 0 설정 유지)

---

## 9. 이 문서를 다 읽었다면 다음은?

작업 설명서는 여기까지. 사용자가 OK 하면 Claude가 하네스를 굴린다:

```
[1] rm -f SPEC.md SELF_CHECK.md QA_REPORT.md
[2] Planner    → SPEC.md      (위 §7을 입력으로)
[3] Generator  → 4 Config + 빈 GameScene + SELF_CHECK.md
[4] Evaluator  → QA_REPORT.md
[5] 합격 시 §8 회고 채우기 / 불합격 시 [3] 재실행
```

작업 끝나면 코드와 함께 §4 Swift 학습 포인트를 다시 읽으며 공부하면 된다.
