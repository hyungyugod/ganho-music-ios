# App Store 재제출 — App Review 회신 문구

리젝(Submission ID: ca468e05-a724-4d97-91cc-511da0bafbba, Guideline 4 - Design, iPad)에 대한 회신.
App Store Connect → 해당 버전 → "App Review와 대화"(Reply)에 **영문**으로 붙여넣는다.
새 빌드(1.0, build 2) 업로드 + iPad 스크린샷 추가 후 재제출.

---

## ▶ 붙여넣을 영문 회신 (Apple용)

Hello,

Thank you for the detailed feedback regarding Guideline 4 (Design) and the iPad layout.

We have reworked the app's layout system to be fully aspect‑ratio aware. The previous build used iPhone‑tuned proportions that did not adapt to the iPad's wider, squarer screen, which left the interface small, off‑center, and surrounded by empty space. In the new build (1.0, build 2):

• All menu screens (character select, skill briefing, difficulty select, results) now scale and reflow to fill the iPad display, with content vertically centered and balanced.
• Primary action buttons and the two‑column screens are now centered to the content area — the earlier right‑side shift has been removed.
• Dialogs are sized proportionally to the surrounding iPad UI.
• These changes are iPad‑specific; the iPhone layout is unchanged.

We verified the new layout across iPad sizes (11" and 13") and have uploaded updated iPad screenshots. The app supports guest play, so no sign‑in is required to evaluate gameplay.

Please let us know if anything else is needed. Thank you for your time.

---

## ▶ 같은 내용 국문 (사용자 이해용 — 제출하지 않음)

안녕하세요. Guideline 4(디자인) — iPad 레이아웃 피드백 감사합니다.

레이아웃 시스템을 화면 종횡비를 인식하도록 전면 재작업했습니다. 이전 빌드는 iPhone 비율 기준이라 iPad의 넓고 정사각형에 가까운 화면에 맞지 않아 UI가 작게·중앙에서 벗어나 떠 보였습니다. 새 빌드(1.0, build 2)에서:
- 모든 메뉴 화면(캐릭터 선택·스킬 브리핑·난이도·결과)이 iPad 화면을 채우도록 스케일·세로 중앙 정렬됩니다.
- 주요 버튼과 2컬럼 화면이 콘텐츠 중앙으로 정렬됩니다(기존 우측 쏠림 제거).
- 다이얼로그도 iPad UI에 비례해 커집니다.
- iPad 전용 변경이며 iPhone 레이아웃은 그대로입니다.
- iPad 11"·13"에서 확인했고, iPad 스크린샷도 새로 올렸습니다. 게스트 플레이가 가능해 로그인 없이 평가 가능합니다.

---

## 체크리스트 (재제출 전)

1. [ ] Xcode에서 **빌드 번호 1 → 2** 올리기 (General → Identity, 또는 Archive 시).
2. [ ] **Archive → Validate → Distribute (App Store Connect 업로드)**.
3. [ ] ASC에서 새 빌드(1.0, build 2) 선택.
4. [ ] **iPad 13" 스크린샷 5장 업로드** (`appstore-shots/ipad-13/`), iPhone 6.9"도 최신본으로 (`appstore-shots/iphone-6.9/`).
5. [ ] 위 영문 회신을 App Review 대화에 작성.
6. [ ] **재제출(Submit for Review)**.
7. (권장) 실기기 iPad에서 4개 화면 가로 배치 눈으로 1회 확인.
