# App Store Connect 등록 자산 초안 — GanhoMusic

> 생성 2026-06-14 · 그대로 복붙해서 채우되 `[확인]` 표시는 네가 게임 실제 사양으로 교정해.
> 번들ID **`com.hyungyu.GanhoMusic`** (iOS 타깃) · 버전 **1.0** · 빌드 **1** · 기본 언어 한국어

---

## 1. 기본 정보

| 필드 | 값 |
|---|---|
| 앱 이름 (30자) | **GanhoMusic** (또는 한글 병기: `GanhoMusic 간호뮤직` [확인]) |
| 부제 (30자) | `45초 픽셀 리듬 액션` |
| 카테고리 | 기본 **게임 > 아케이드** / 보조 **액션** |
| 가격 | 무료 |
| 지원 URL | `https://weak-curler-42e.notion.site/GanhoMusic-Support-37fe5a0eed538182bb50ef234b7d7057` (노션 게시 완료) |
| 마케팅 URL (선택) | 비워도 됨 |

---

## 2. 프로모션 텍스트 (170자, 심사 없이 수시 교체 가능)

```
딱 45초. 음표를 모으고 빌런을 피해 콤보를 쌓으세요. 매일 바뀌는 데일리 모디파이어로 같은 판은 없습니다. 로그인 없이 바로 플레이.
```

## 3. 설명 (한국어)

```
45초. 한 판이면 충분합니다.

음표가 쏟아지는 무대 위에서 빌런의 방해를 피하고, 콤보를 쌓아 최고 점수에 도전하세요.
짧고 강렬한 한 판, 그리고 어김없이 찾아오는 "한 판만 더".

이런 게임이에요
· 45초 한 판 — 출퇴근길, 쉬는 시간에 딱 맞는 호흡
· 픽셀 아트 + 도트 폰트 감성의 무대와 캐릭터
· 개성 다른 플레이 캐릭터와 맞서는 빌런들 [확인: 캐릭터 수/이름]
· 콤보 시스템과 난이도 3종(이지 · 노멀 · 하드)
· 매일 바뀌는 데일리 모디파이어 — 어제와 다른 오늘의 판
· Apple로 로그인하면 점수와 해금이 클라우드에 안전하게 저장
· 로그인 없이 게스트로도 바로 시작

지금, 딱 45초만 써보세요.
```

## 4. 설명 (English)

```
45 seconds. One run is all it takes.

Dodge the villains, catch the notes, and chain combos for a new high score.
A short, sharp run — and that irresistible "just one more."

What's inside
- 45-second runs, perfect for a quick break
- Pixel-art stages and characters with retro dot-font charm
- Distinct playable characters and the villains who get in your way [confirm]
- Combo system and 3 difficulties (Easy / Normal / Hard)
- A daily modifier that reshapes every run
- Sign in with Apple to back up scores and unlocks to the cloud
- Or jump straight in as a guest — no login required

Give it 45 seconds.
```

## 5. 키워드 (쉼표 구분, 100자 이내 — ASC가 자동 카운트)

- **KO**: `리듬,아케이드,음악,픽셀,도트,캐주얼,콤보,점수,한손,중독성,인디게임,레트로`
- **EN**: `rhythm,arcade,music,pixel,retro,casual,combo,score,one-hand,indie,8bit,highscore`

> 팁: 앱 이름·부제에 든 단어는 키워드에서 빼서 자리 아끼기. 띄어쓰기 없이 쉼표만.

---

## 6. 연령 등급 (2026 신설문 기준)

등급 체계 변경됨: **4+ / 9+ / 13+ / 16+ / 18+** (12+·17+ 폐지). 아래처럼 답하면 보통 **9+**:

| 질문 | 권장 답 [확인] |
|---|---|
| 만화 또는 판타지 폭력 | **가끔/약함** (빌런·발사체가 있으면) — 전혀 없으면 없음 → 4+ |
| 사실적 폭력 / 유혈 | 없음 |
| 성적 콘텐츠·나체 | 없음 |
| 욕설·저속 유머 | 없음 |
| 도박(모의 포함) | 없음 |
| 약물·음주·흡연 | 없음 |
| 사용자 간 자유 대화/메시지 | 없음 (리더보드는 대화 아님) |
| 무제한 웹 접근 | 없음 |
| AI 챗봇/생성형 노출 빈도 | 없음 |

> 폭력 표현이 정말 미미하면 "없음"으로 4+도 가능. 빌런을 때리거나 맞는 연출이 있으면 9+가 안전.

---

## 7. 개인정보(App Privacy) 답안 — 매니페스트와 1:1 일치

먼저 "Data Used to Track You" = **없음**, "Data Not Linked to You" = 없음.
"Data Linked to You" 에 아래 4종 (전부 용도 **App Functionality**, 추적 안 함):

| 데이터 | ASC 분류 | 용도 |
|---|---|---|
| 사용자 ID | Identifiers → User ID | App Functionality (계정·클라우드 저장) |
| 이름 | Contact Info → Name | App Functionality (프로필 표시) |
| 이메일 주소 | Contact Info → Email Address | App Functionality (계정 식별) |
| 제품 상호작용 | Usage Data → Product Interaction | App Functionality (점수·진행 저장) |

- Privacy Policy URL: `https://weak-curler-42e.notion.site/Privacy-Policy-37de5a0eed53816cbd1ee2cdc2c76e7d`
- (이 4종은 `PrivacyInfo.xcprivacy`에 선언된 것과 동일 — 불일치 없음)

---

## 8. 심사 정보 (App Review Information)

**메모 (한/영 병기 권장)**
```
이 앱은 로그인 없이 전체 플레이가 가능합니다.
시작 화면에서 "게스트로 시작"을 누르면 모든 게임 콘텐츠에 접근할 수 있어, 별도 심사용 계정이 필요하지 않습니다.
"Sign in with Apple"은 점수·해금의 클라우드 백업(선택)에만 사용됩니다.

This app is fully playable without an account. On the start screen, tap "Start as Guest" to access all gameplay — no demo account is needed. Sign in with Apple is optional and only used to back up scores/unlocks.
```
- 연락 정보: 이름/성/전화/이메일(`hyungyugood0129@gmail.com` [확인])
- 데모 계정: **불필요** (게스트 경로 안내로 갈음)

---

## 9. 빌드·버전
- 버전 1.0, 빌드 1 (업로드된 빌드 선택)
- 저작권: `2026 현규` [확인]
- 단, 재업로드할 때마다 빌드 번호(CURRENT_PROJECT_VERSION)는 +1 해야 ASC가 받음

---

## ⚠️ 등록 시 주의
- **번들ID는 반드시 `com.hyungyu.GanhoMusic` 선택** — 프로젝트에 `com.hg.GanhoMusic`(tvOS·macOS용)도 있으니 헷갈리지 말 것
- 스크린샷: iPhone 6.9″ **1320×2868**, iPad 13″ **2064×2752** (가로 게임이라 가로로, 알파채널 없이)
