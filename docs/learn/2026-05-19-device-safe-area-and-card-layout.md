# 2026-05-19 — 디바이스 안전영역(SafeArea) + 카드 자동 배치 학습 노트

## 한 줄 요약

휴대폰마다 화면 모서리(노치/홈인디케이터)가 다른데, **화면 전체 크기를 직접 바꾸지 말고, 노드 위치만 안전한 위치로 옮기자**.

---

## 1. SafeArea가 뭐길래

### 휴대폰 모서리 = 위험지대

요즘 아이폰은 화면 꼭대기에 **카메라가 박힌 검은 띠(노치)** 와 화면 아래쪽에 **홈인디케이터(흰 막대)** 가 있다.

만약 우리가 "시작" 버튼을 화면 정확히 아래쪽 끝에 두면 → 홈인디케이터에 가려서 안 보인다.

그래서 iOS는 친절하게 **"이 영역은 안전해요"** 라고 알려준다. 이게 **SafeArea**.

```
┌─────────────────┐
│ ▓▓ 노치 ▓▓     │ ← 여긴 위험 (카메라)
├─────────────────┤
│                 │
│   safeArea      │ ← 여기 안에만 두면 안전
│                 │
├─────────────────┤
│ ▓ 홈바 ▓       │ ← 여긴 위험 (홈인디케이터)
└─────────────────┘
```

### Spring 비유

Spring Boot에서 `@ConfigurationProperties`나 `Environment.getProperty("server.port")`로 환경에 따라 자동으로 값을 받아오는 거랑 비슷하다.

- 개발 환경: 포트 8080
- 운영 환경: 포트 443

코드는 그대로 두고 **환경(Environment)** 이 알아서 값을 넣어준다.

SafeArea도 마찬가지:
- iPhone SE: safeArea.bottom = 0
- iPhone 17 Pro: safeArea.bottom = 21 (홈바 영역)

코드는 `view.safeAreaInsets.bottom`만 읽으면 알아서 디바이스에 맞춰 값이 들어온다.

---

## 2. 왜 SKView를 직접 안 만지는지

### 2026-05 무한재귀 사고 기록

옛날에 "잘림이 발생하니까 SKView 크기를 직접 줄이자"고 했던 적이 있다.

```swift
// ❌ 절대 하지 마세요
override func viewSafeAreaInsetsDidChange() {
    skView.frame = ...  // ← 여기가 폭탄
}
```

문제는 이거다:
1. SafeArea가 바뀌면 → `viewSafeAreaInsetsDidChange()` 호출됨
2. 거기서 frame을 바꾸면 → 다시 SafeArea가 재계산됨
3. 다시 1번 호출됨 → **무한 재귀** → **앱이 흰 화면으로 죽음**

### 올바른 접근

화면 전체 크기는 **iOS가 알아서 관리하게 두고**, 우리는 노드 위치만 SafeArea 안쪽으로 옮긴다.

```swift
// ✅ 좋음 — 노드 위치만 SafeArea를 피하도록
let safe = SceneSafeArea.insets(for: self)
startButton.position = CGPoint(
    x: frame.midX,
    y: frame.minY + safe.bottom + 64  // ← 홈바 위 64pt에 안전하게
)
```

### Spring 비유

Spring에서 톰캣 포트를 직접 바꾸려고 `ServletContext`를 만지면 톰캣이 죽는다. 대신 `application.properties`에서 `server.port=8080` 같이 설정만 한다.

iOS도 똑같다. SKView는 iOS에 맡기고, **우리는 노드 좌표만** 만진다.

---

## 3. 동적 카드 spacing — 디바이스에 맞춰 알아서 늘어남

### 문제

5장의 캐릭터 카드를 화면에 늘어놓는데:
- iPhone SE (좁음): 카드 간격이 너무 넓으면 카드가 화면 밖으로 나간다
- iPhone Pro Max (넓음): 카드 간격이 너무 좁으면 다닥다닥 붙어 보기 흉하다

### 해결: 화면 폭에 비례해서 자동 계산

```swift
// 사용 가능한 폭 = 화면 폭 - 좌우 SafeArea - 좌우 마진
let usable = frame.width - safe.left - safe.right - 2 * 20

// 카드 5장 자체 폭을 빼고, 남는 공간을 4개 간격에 골고루
let rawSpacing = (usable - 76 * 5) / 4

// 너무 좁아지지도, 너무 넓어지지도 않게 clamp
let spacing = min(56, max(28, rawSpacing))
```

### Spring 비유

Spring의 `@Value("${card.spacing:#{T(java.lang.Math).min(56, T(java.lang.Math).max(28, ...))}}")` 같은 거다. 환경에 따라 자동으로 적절한 값이 들어가고, 너무 크거나 작으면 한계로 잘라낸다(clamp).

- 좁은 화면: spacing = 28 (최소 보장)
- 넓은 화면: spacing = 56 (최대 한도)
- 보통 화면: 그 사이 값으로 자동 계산

---

## 4. 디바이스 대응 한 줄 요약

> **"휴대폰 모양은 iOS에게 맡기고, 노드 위치만 SafeArea 안쪽으로 옮긴다."**

- SKView frame은 **절대 만지지 말 것** (무한재귀 사고 기록)
- 각 SKScene이 `view.safeAreaInsets`를 **읽어서** 노드 좌표에 반영
- 카드 같은 반복 요소는 **화면 폭 비례 + clamp** 로 자동 배치

---

## 5. 이번에 만든 헬퍼

`SceneSafeArea.swift`:

```swift
enum SceneSafeArea {
    static func insets(for scene: SKScene) -> UIEdgeInsets {
        return scene.view?.safeAreaInsets ?? .zero
    }
}
```

엄청 짧다. 하지만 이게 **유일한 SafeArea 읽기 통로**라서:
- 강제 언래핑 없음 (`?? .zero`로 안전 폴백)
- view가 아직 부착 안 됐을 때도 크래시 0
- 모든 씬이 동일한 방식으로 SafeArea를 읽음 → 일관성

### Spring 비유

Spring의 `@Component`로 등록한 `EnvironmentReader` 같은 유틸 클래스다. "환경 변수는 무조건 이 클래스를 거쳐서 읽어라"는 규칙 하나로 일관성을 만든다.
