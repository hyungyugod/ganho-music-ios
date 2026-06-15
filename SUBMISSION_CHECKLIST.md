# GanhoMusic — App Store 출시 체크리스트

> 생성 2026-06-14 · 번들ID `com.hyungyu.GanhoMusic` · 백엔드 Firebase(Auth+Firestore) · iOS 16+ · Landscape 전용
> 진행 순서: Phase 0(출고 전 점검) → 1(실기기) → 2(Xcode) → 3(App Store Connect) → 4(TestFlight·제출)

---

## ⚠️ Phase 0 — 출고 전 점검 (여기서 막히면 뒤가 다 헛수고)

- [x] **앱 레벨 `PrivacyInfo.xcprivacy`** — ✅ 이미 존재·정확. `GanhoMusic iOS/PrivacyInfo.xcprivacy`에 UserDefaults(`CA92.1`) + 수집 4종(UserID·Name·Email·ProductInteraction, 전부 Linked·비추적·AppFunctionality) 선언됨. 프로젝트가 Xcode 16 동기화 그룹이라 pbxproj 개별 등록 없이 **빌드 자동 포함**(예외 목록엔 Info.plist만 제외). → 추가 작업 불필요. ITMS-91053 위험 해소.
- [ ] **Apple Developer Program 가입 활성** — 미가입이면 이게 0순위. $99/년, 본인확인 검증에 최대 24~48h(가끔 며칠). 업로드·앱등록 전부 이거 없으면 불가.
- [ ] **Xcode 26 + iOS 26 SDK로 빌드** — 2026-04-28부터 구버전 Xcode 빌드는 자동 반려. (iPadOS 26 테스트했으니 이미 26일 가능성 높음 — 확인만)
- [ ] **App ID 등록 + Sign in with Apple capability ON** — `com.hyungyu.GanhoMusic`, Apple 로그인 entitlement 포함(로그인 테스트됐으면 이미 됨 — 확인만)
- [x] **수출규정(암호화)** — `ITSAppUsesNonExemptEncryption=false` 이미 Info.plist에 설정됨 → 업로드 시 암호화 질문 자동 스킵, ASC에서 서류 요구 안 함. ✅ 처리 완료

---

## Phase 1 — 실기기 최종 플레이 (1~2세션)

출처: `refactor/R8_FINAL_AUDIT.md §7` (시뮬 미검증 항목) + R8 이관 기록

- [ ] **Apple 연동 라운드트립** — 로그인 → 로그아웃 → 재로그인 → (재설치) 머지: Firestore 실 네트워크 왕복으로 점수·해금 보존되는지
- [ ] **CoreHaptics 체감** — uiTap / nearMiss(0.3) / gameOver / heavy 패턴 강도 + **일시정지 버튼 이중 발화 0**
- [ ] **fps 실측** — gameHardRush 45초 풀런을 Instruments(Time Profiler / Core Animation)로 (시뮬 60.0은 신뢰 한계)
- [ ] **mirrorWard / fullSpirit 일일 모디파이어** — 해당 날짜·시드에서 실제 발동 확인
- [ ] **일러스트 `.linear` 스케일 품질** — Retina 3x 실패널에서 시야각·해상도
- [ ] **Landscape 양방향** — 좌/우 회전 전환 + 노치 safe area
- [ ] **BGM/SFX 청감** — 플레이스홀더 톤 확정(자작곡 m4a 드롭인 여부 결정)
- [ ] **컷씬 카피 톤** + 결과/해금 배너·일시정지 등장 모션 육안

---

## Phase 2 — Xcode 아카이브 → 업로드 (한 번)

1. [x] **공유 스킴** — ✅ 내가 `GanhoMusic iOS.xcscheme`를 xcshareddata에 생성(Archive=Release 고정). Xcode 열어서 Manage Schemes에 `GanhoMusic iOS`가 Shared로 보이는지 확인만 하면 됨
2. [ ] **Edit Scheme > Archive** → Build Configuration = **Release** 확인
3. [ ] 상단 디바이스 타깃을 **Any iOS Device (arm64)** 로 변경 (시뮬레이터면 Archive 비활성)
4. [ ] **Product > Archive** → 끝나면 Organizer 자동 오픈
5. [ ] Organizer에서 아카이브 선택 → **Validate App** → 통과(서명·프로비저닝·매니페스트 사전 검사)
6. [ ] **Distribute App** → **App Store Connect** → **Upload**
7. [ ] 업로드 후 처리 대기(15~60분) → ASC의 TestFlight 탭에 빌드 표시되면 OK

---

## Phase 3 — App Store Connect 설정

### 앱 등록
- [ ] My Apps → **+** → New App: 플랫폼 iOS / 이름 / 기본 언어 한국어 / 번들ID `com.hyungyu.GanhoMusic` 선택 / SKU 임의

### 스크린샷 (유니버설 → iPhone+iPad 둘 다 필수)
| 기기 | 픽셀(세로 기준) | 비고 |
|---|---|---|
| iPhone 6.9" | **1320 × 2868** | 가로 게임이면 2868×1320 가로로 |
| iPad 13" | **2064 × 2752** | 가로면 2752×2064 |

PNG/JPEG · RGB · **알파 채널 없음** · 픽셀 정확(±1 안 됨) · 각 1~10장. QA 캡처는 `/tmp/ipad-qa/` 구도 참고.

### 메타데이터
- [ ] 설명 / 프로모션 텍스트 / **키워드(쉼표구분 100자)** / 지원 URL
- [ ] 카테고리: 게임 > 아케이드(또는 액션)
- [ ] 가격: 무료

### 연령 등급 (2026 신설문)
- [ ] 새 설문 작성 — 등급 체계 변경됨: **4+ / 9+ / 13+ / 16+ / 18+** (12+·17+ 폐지). 만화/판타지 폭력(빌런·발사체) 빈도 답에 따라 보통 **9+**.

### 개인정보 (App Privacy)
- [ ] Privacy Policy URL: `https://weak-curler-42e.notion.site/Privacy-Policy-37de5a0eed53816cbd1ee2cdc2c76e7d`
- [ ] 라벨 4종 매핑:

| 수집 데이터 | ASC 분류 | 용도 | 연결/추적 |
|---|---|---|---|
| 사용자 ID | Identifiers > User ID | App Functionality | 사용자 연결(Linked) · 추적 아님 |
| 이름 | Contact Info > Name | App Functionality | Linked · 추적 아님 |
| 이메일 | Contact Info > Email Address | App Functionality | Linked · 추적 아님 |
| 제품 상호작용 | Usage Data > Product Interaction | App Functionality / Analytics | Linked · 추적 아님 |

### 빌드·심사 정보
- [ ] 업로드된 빌드 선택 / 저작권(예: 2026 현규)
- [ ] **심사 메모**: "로그인 없이 게스트 플레이 가능 — 시작 화면에서 '게스트로 시작' 선택" (계정 없이 검수 가능하도록)

---

## Phase 4 — TestFlight 확인 → 제출

- [ ] TestFlight로 **본인 기기 1회 설치·실행** (스토어용 빌드가 실기기에서 정상 기동하는지 최종 확인)
- [ ] App Store 버전에서 **"심사를 위해 제출"**
- [ ] 심사 대기 — 2026 기준 보통 24~48h

---

## 자주 막히는 포인트
- **ITMS-91053 메일**: 매니페스트는 이미 정상이라 안 올 가능성 높음. 그래도 오면 동기화 그룹 예외 목록에 PrivacyInfo가 빠졌는지 확인 후 빌드번호 올려 재업로드
- **스크린샷 거부**: 픽셀이 1px라도 어긋나면 거부 → 정확 규격으로 다시
- **빌드 미표시**: 업로드 직후 안 보여도 정상, 처리에 최대 1시간
- **누락 컴플라이언스**: 암호화는 이미 false로 해결됨 — 그 외 "Missing Compliance"가 뜨면 빌드 옆에서 직접 응답
