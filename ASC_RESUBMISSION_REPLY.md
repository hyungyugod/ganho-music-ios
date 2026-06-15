# App Store 재제출 — App Review 회신 문구

리젝(Submission ID: ca468e05-a724-4d97-91cc-511da0bafbba, Guideline 4 - Design, iPad)에 대한 회신.
App Store Connect → 해당 버전 → "App Review와 대화"(Reply)에 **영문**으로 붙여넣는다.
현재 진행 중인 제출(build 2) **취소** → **새 빌드(1.0, build 3)** 업로드 후 재제출.
(build 3 = 메뉴 종횡비 대응 + iPad 인게임 카메라 화면 채우기까지 반영. 빌드 번호는 이미 코드에 3으로 올려둠.)

---

## ▶ 붙여넣을 영문 회신 (Apple용)

Hello,

Thank you for the detailed feedback regarding Guideline 4 (Design) and the iPad layout.

We have reworked the app's layout system to be fully aspect‑ratio aware. The previous build used iPhone‑tuned proportions that did not adapt to the iPad's wider, squarer screen, which left the interface small, off‑center, and surrounded by empty space. In the new build (1.0, build 3):

• All menu screens (character select, skill briefing, difficulty select, results) now scale and reflow to fill the iPad display, with content vertically centered and balanced.
• Primary action buttons and the two‑column screens are now centered to the content area — the earlier right‑side shift has been removed.
• The in‑game screen now fills the iPad display edge‑to‑edge (the camera scales to cover the larger iPad screens instead of leaving empty borders).
• Dialogs are sized proportionally to the surrounding iPad UI.
• These changes are iPad‑specific; the iPhone layout is unchanged.

We verified the new layout across iPad sizes (11" and 13") and have uploaded updated iPad screenshots. The app supports guest play, so no sign‑in is required to evaluate gameplay.

Please let us know if anything else is needed. Thank you for your time.

---

## ▶ 같은 내용 국문 (사용자 이해용 — 제출하지 않음)

안녕하세요. Guideline 4(디자인) — iPad 레이아웃 피드백 감사합니다.

레이아웃 시스템을 화면 종횡비를 인식하도록 전면 재작업했습니다. 이전 빌드는 iPhone 비율 기준이라 iPad의 넓고 정사각형에 가까운 화면에 맞지 않아 UI가 작게·중앙에서 벗어나 떠 보였습니다. 새 빌드(1.0, build 3)에서:
- 모든 메뉴 화면(캐릭터 선택·스킬 브리핑·난이도·결과)이 iPad 화면을 채우도록 스케일·세로 중앙 정렬됩니다.
- 주요 버튼과 2컬럼 화면이 콘텐츠 중앙으로 정렬됩니다(기존 우측 쏠림 제거).
- 인게임 화면도 iPad 큰 화면을 가장자리까지 채웁니다(카메라가 화면을 덮도록 줌 — 기존 빈 여백 제거).
- 다이얼로그도 iPad UI에 비례해 커집니다.
- iPad 전용 변경이며 iPhone 레이아웃은 그대로입니다.
- iPad 11"·13"에서 확인했습니다. 게스트 플레이가 가능해 로그인 없이 평가 가능합니다.

---

## 체크리스트 (재제출 전)

1. [ ] **현재 진행 중인 심사 취소** — ASC 버전 페이지에서 제출 철회(또는 빌드 제거). "심사 대기" 상태면 바로 취소 가능.
2. [ ] 빌드 번호는 **이미 코드에 3으로 반영됨**(Xcode General 탭 Build = 3 확인만).
3. [ ] **Archive → Validate → Distribute (App Store Connect 업로드)** — 기기 선택 "Any iOS Device (arm64)".
4. [ ] ASC에서 새 빌드 **1.0 (3)** 선택.
5. [ ] **스크린샷** — 이미 올린 iPad 13" 10장·iPhone 6.9" 5장은 버전에 그대로 남아 재업로드 불필요(인게임 컷도 수정 후 실제와 일치). 교체 원하면 `appstore-shots/`로.
6. [ ] 위 영문 회신을 App Review 대화에 작성.
7. [ ] **재제출(Submit for Review)**.
8. (권장) 실기기 iPad에서 메뉴 4화면 + 인게임 가로 채움 눈으로 1회 확인.
