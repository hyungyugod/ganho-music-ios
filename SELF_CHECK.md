# 자체 점검 — Phase 5-7 ResultScene 캐릭터 이름 표시 (Phase 5 종결)

## 1. 변경 파일 목록 (정확히 3개) + diff 요약

### (1) `GanhoMusic/GanhoMusic Shared/Scenes/ResultScene.swift`
- 헤더 주석 1줄 추가: `Phase 5-7 · 캐릭터 이름 라벨 추가 (init 6번째 인자 characterName)`
- `private let characterName: String` stored property 추가 (stats 다음)
- `private let characterLabel = SKLabelNode(text: "")` 라벨 1개 추가 (statsLabel 다음, promptLabel 이전)
- `class func newResultScene(...)` 시그니처에 `characterName: String` 마지막 인자 추가 + 내부 init 호출에 전달
- `private init(...)` 시그니처에 `characterName: String` 마지막 인자 추가 + `super.init(size:)` *이전*에 `self.characterName = characterName` 저장
- `setupLabels()`:
  - `configureLabel(characterLabel, fontSize: GameConfig.resultCharacterFontSize)` 1줄 추가 (statsLabel 다음, promptLabel 이전)
  - `characterLabel.text = "🎮 \(characterName)"` 1줄 추가
  - `addChild(characterLabel)` 1줄 추가 (statsLabel 다음, promptLabel 이전)
- `layoutLabels()`: `characterLabel.position = CGPoint(x: frame.midX, y: frame.midY + GameConfig.resultCharacterOffsetY)` 1블록 추가 (statsLabel 다음, promptLabel 이전)
- `configureLabel` 주석 한 토큰 갱신: "5개 라벨" → "6개 라벨"

### (2) `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`
- 파일 마지막에 `// MARK: - Result Character (Phase 5-7)` 섹션 신설
- `static let resultCharacterFontSize: CGFloat = 22` (SPEC docstring 그대로)
- `static let resultCharacterOffsetY: CGFloat = 115` (SPEC docstring 그대로)

### (3) `GanhoMusic/GanhoMusic Shared/GameScene.swift`
- `endGame()` 내부 `ResultScene.newResultScene(...)` 호출에 마지막 인자 `characterName: characterID.displayName` 1줄 추가
- **endGame 외 0줄 변경** — init / newGameScene / didMove / update / configureContactRouter / triggerAirforceEasterEgg / layoutDPad / layoutHUD / characterID 프로퍼티 모두 그대로.

---

## 2. SPEC In Scope 충족

### ResultScene 6 변경점
- [x] 헤더 주석 1줄 추가
- [x] `characterName: String` stored property
- [x] `characterLabel` 라벨 1개
- [x] `class func newResultScene` 6번째 인자
- [x] `private init` 6번째 인자 (super.init 이전 저장)
- [x] `setupLabels()` 갱신 (configureLabel 6 호출, text 합성, addChild 6개)
- [x] `layoutLabels()` 갱신 (6번째 라벨 position)

### GameConfig 2 상수
- [x] `resultCharacterFontSize: CGFloat = 22`
- [x] `resultCharacterOffsetY: CGFloat = 115`
- [x] SPEC docstring 보존 (`Phase 5-7 — ... best(22)와 동급` / `title(+80) 위쪽 +115`)
- [x] 신규 `// MARK: - Result Character (Phase 5-7)` 섹션

### GameScene endGame 1줄
- [x] `ResultScene.newResultScene(...)` 호출에 `characterName: characterID.displayName` 1줄 추가
- [x] endGame 외 0줄 변경

---

## 3. Out of Scope 위반 0건

다음 항목 모두 **0줄 변경** 확인:

- [x] `CharacterID.swift` — 미변경
- [x] `HUDNode.swift` / `PlayerNode.swift` / `CharacterCardNode.swift` — 미변경
- [x] `TitleScene.swift` — 미변경
- [x] `GameScene.swift`의 init / class func newGameScene / didMove / update / configureContactRouter / triggerAirforceEasterEgg / layoutDPad / layoutHUD / characterID 프로퍼티 선언 — 모두 미변경 (endGame 내 1줄만 변경)
- [x] `GameScene+Setup.swift` — 미변경
- [x] `ColorTokens.swift` — 미변경
- [x] 시스템 (`ContactRouter` / `SpawnSystem` / `ScoreSystem`) — 미변경
- [x] Repository (`HighScore` / `Statistics` / `CharacterPreference`) — 미변경
- [x] `Models/GameStats.swift` — 미변경
- [x] `Protocols/` — 미변경
- [x] 라벨 색 차등 없음 — `configureLabel`로 6라벨 모두 `.ganhoPaper` 동일 색
- [x] 폰트 굵기 / outline / shadow 시각 강화 없음 — `configureLabel` 공통 스타일만
- [x] CharacterID enum 자체 ResultScene 주입 없음 — `String`만 (HUDNode 5-4와 동형성)
- [x] 새 노드(border, decoration) 추가 없음 — `characterLabel` 1개만
- [x] 영구 저장 / Repository 신설 없음
- [x] macOS / tvOS / pbxproj / Test 코드 변경 없음
- [x] 5라벨 균등 40 간격 유지 — title(+80) / score(+40) / best(0) / stats(-40) / prompt(-80) 모두 기존 그대로, characterLabel만 +115에 신규

---

## 4. 빌드 결과

```
xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" \
  -scheme "GanhoMusic iOS" \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug build
```

- **결과**: `** BUILD SUCCEEDED **`
- **경고/에러** (AppIntents 잡음 제외): **0줄**
  - `xcodebuild ... | grep -E "warning:|error:" | grep -v "AppIntents"` 결과 empty

---

## 5. 검증 시나리오 정적 추적

### (a) 5 캐릭터 전체 표시 정확성
- TitleScene 5장 선택 → GameScene.init(characterID:) → endGame → `characterID.displayName` (CharacterID 5 case 한국어 이름 확정값)
- kim → "🎮 김간호" / jung → "🎮 정간호" / geon → "🎮 건간호" / im → "🎮 임간호" / lee → "🎮 이간호"
- `characterLabel.text = "🎮 \(characterName)"` — 보간 결과 5종 모두 정상

### (b) 빌드 클린
- BUILD SUCCEEDED, 신규 warning/error 0
- ResultScene 시그니처 6인자 확장 + GameScene endGame 호출부 동기화 → 컴파일 일관성 확보

### (c) 5-2 회귀 (constructor injection)
- `GameScene.init(size:characterID:)` 그대로 (0줄 변경)
- `class func newGameScene(characterID:)` 그대로
- TitleScene.didMove의 GameScene 생성 흐름 무영향

### (d) 5-3 회귀 (캐릭터별 속도)
- `PlayerNode.update` 미변경
- `characterID.playerSpeedMultiplier` 호출부 무관 — 5캐릭터 속도 차등 유지

### (e) 5-4 회귀 (HUD 캐릭터 이름)
- `HUDNode.setCharacterName(_ name: String)` 시그니처 미변경
- GameScene+Setup의 호출부 미변경 — 게임 중 HUD 우상단 이름 정상

### (f) 라벨 위치 겹침 / 화면 클리핑
- 1024×768 기준: midY = 384
- characterLabel y = 384 + 115 = 499, 폰트 22 → 라벨 상단 ~510pt (화면 상단 768까지 258pt 여유)
- characterLabel(+115) ↔ titleLabel(+80) 간격 35pt
  - 폰트 절반 합 = 22/2 + 32/2 = 11 + 16 = 27pt
  - 시각적 갭 = 35 - 27 = 8pt → 겹침 없음

### (g) Graceful — characterName 빈 문자열
- `characterName = ""` 강제 주입 시 → `characterLabel.text = "🎮 "` (이모지 + 공백)
- SKLabelNode가 빈 문자열에서 fontColor/fontSize 그대로 적용 — 크래시 없음
- HUDNode 5-4의 동일 graceful 동형

### (h) didChangeSize 회전/리사이즈
- `layoutLabels()` 호출 시 6라벨 모두 `frame.midX/midY` 기준 재계산
- characterLabel.position도 동시 갱신 — 회전 후에도 +115 오프셋 유지

---

## 6. Swift / SpriteKit 패턴 준수

### Swift 패턴
- [x] 강제 언래핑(`!`) 미사용 — `guard let view = self.view` 등 모두 안전 추출
- [x] guard let / if let 옵셔널 처리 — endGame의 `guard let view = self.view` 유지
- [x] MARK 섹션 구분 — Properties / Factory / Init / Lifecycle / Setup / Touch
- [x] GameConfig 상수 사용 — `resultCharacterFontSize` / `resultCharacterOffsetY` 직접 리터럴 없음
- [x] super.init 전 stored property 저장 — `self.characterName = characterName` (Swift two-phase init 규칙)
- [x] init 6인자 = stored property 6개 (1:1 대응) — 의미 모호성 0

### SpriteKit 패턴
- [x] didMove(to:)에서 setupLabels 1회 호출 (자식 추가)
- [x] didChangeSize → layoutLabels (position만 재계산, addChild 없음 — 멱등)
- [x] dt 기반 이동 무관 (ResultScene은 정적 화면)
- [x] 스폰 액션 무관 (정적 라벨)
- [x] 충돌 무관 (ResultScene physics 없음)
- [x] characterLabel은 SKScene 직접 자식 — HUD 분리 패턴과 결 일관

---

## 7. docs/learn 학습 노트

- 파일: `docs/learn/phase-5-7-result-character-name.md` 신규 작성
- 중학생 수준 톤 (Spring 비유 곁들임):
  - **DTO 인자 확장**: Spring `ResultDTO(... String characterName)` 추가 비유
  - **String-only 동형성**: `OrderEntity` vs `String orderNumber` 결합도 차단 비유 (Phase 5-4와 동형)
  - **configureLabel 공통 스타일**: Spring `@Component` 공통 빈 → Swift 공통 함수 비유
  - 추가로 **매직 넘버 금지** (application.yml 비유), **Phase 5 종결 회고**, **검증 시나리오 (a)/(b)/(g) 요약** 포함

---

## 8. 범위 외 미구현 항목

- **없음**.
- SPEC의 In Scope 항목 모두 충족 / Out of Scope 항목 모두 0줄 위반.
