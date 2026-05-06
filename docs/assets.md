# 에셋 / 미감 가이드 — GanhoMusic iOS

이 문서는 시각·청각 자산의 **사람이 결정해야 하는 영역**을 정의한다.
AI(클로드코드)에게 위임하지 않는다 — 이 게임의 차별화는 미감에서 나오기 때문.

원칙:
1. 색·폰트·사운드의 **결정은 사람**, 코드 반영은 AI.
2. 픽셀 한 칸도 톤이 일관되어야 한다.
3. 모자란 자산은 placeholder 도형으로 두되, 색상 토큰만큼은 첫날부터 고정.

---

## 1. 컬러 팔레트 (16색 고정)

게임 전반에 이 16색만 쓴다. 그라데이션 / 알파 보간 금지 (픽셀 톤 보존).

| 토큰 | HEX | 용도 |
|---|---|---|
| `bgDeep` | `#1A1B2E` | 배경 (어두운 야간 병동) |
| `bgMid` | `#2C2E4A` | 배경 패턴, 그림자 |
| `bgLight` | `#494E78` | 바닥 타일 |
| `inkBlack` | `#0F0F1A` | 외곽선 |
| `paperWhite` | `#F4F1DE` | 김간호 가운 / HUD 텍스트 |
| `mintHair` | `#7DCFB6` | 김간호 머리띠 / 음표 보조 |
| `pinkNote` | `#F6A6B2` | 음표 본체 ♪ |
| `crimsonNurse` | `#A4243B` | 수간호사 가운 |
| `bloodAccent` | `#D8315B` | 수간호사 강조 / 피격 플래시 |
| `yellowF` | `#FFD23F` | F 투사체 |
| `goldRank` | `#E0B872` | S 등급 강조 / 콤보 4× 이상 |
| `greenOk` | `#6BBF59` | 콤보 정상 / 비트 라인 |
| `cyanBeat` | `#3DA9FC` | 박자 강박 표시 / Shield 보유 |
| `purpleCombo` | `#8E5BFF` | 콤보 8× 이상 |
| `dimGray` | `#6C6C7A` | 비활성 텍스트 |
| `softShadow` | `#000000` (40% alpha) | 그림자 (예외적으로 알파 허용) |

**Swift 적용:**

```swift
// Assets.xcassets에 Color Set으로 등록 후
extension UIColor {
    static let ganhoBgDeep = UIColor(named: "bgDeep") ?? .black
    static let ganhoPaper  = UIColor(named: "paperWhite") ?? .white
    // ...
}
```

`UIColor(red:green:blue:)` 직접 생성 금지 — Color Set 통해서만.

---

## 2. 폰트

**픽셀 폰트 1종으로 통일:**

- **둥근모꼴 (DungGeunMo)** — 무료, 한국어 픽셀 폰트의 표준.
  - 출처: <https://cactus.tistory.com/193>
  - 라이선스: 자유 사용 가능 (저작자 표기 권장)
  - 임포트: `Fonts/DungGeunMo.ttf` 추가 + `Info.plist` 의 `UIAppFonts` 등록

**SwiftUI 보조 시 폰트:**
- `SF Pro` 시스템 폰트 — 메뉴 / 설정 화면 등 SwiftUI 영역에서만.
- 게임 씬 내부는 무조건 둥근모꼴.

**사이즈 토큰:**

| 용도 | 크기 |
|---|---|
| HUD 점수 / 타이머 | 24pt |
| 콤보 표시 | 32pt |
| 게임 오버 큰 텍스트 | 48pt |
| 보조 카피 | 18pt |

---

## 3. 스프라이트 / 픽셀 아트

**그리드:**
- 기준 타일: **20×20 px**
- 김간호 / 수간호사: 16×24 px (세로 긴 캐릭터)
- 음표: 12×16 px
- F 투사체: 16×16 px

**제작 도구 (현규 본인 결정):**
- 1순위: **Aseprite** (유료, 픽셀 아트 표준)
- 2순위: **Pixilart** (무료 웹 에디터)
- 3순위: 임시는 SKShapeNode 도형으로 placeholder

**아트 패스 우선순위:**

1. Phase 1~2 동안은 **단색 도형 placeholder** 사용 (위 컬러 토큰 적용).
2. Phase 4 폴리싱에서 픽셀 아트로 일괄 교체.
3. 교체 시점에는 모든 스프라이트가 동일 작가(현규) 손에서 나와야 톤 일관성 유지.

**임포트:**
- `GanhoMusic Shared/Assets.xcassets/Sprites.spriteatlas/` 에 묶어 텍스처 아틀라스로 관리 (드로우콜 절약).

---

## 4. 사운드 정책

**현규 본인 작곡 활용:**
- BGM은 FL Studio로 직접 제작 → `.m4a` 또는 `.caf` 변환.
- 본인 음원 발매 활동(현재 진행 중)과 시너지. 게임 사운드트랙 = 별도 콘텐츠 자산.

**효과음 우선순위:**

| 이벤트 | 사운드 | 비고 |
|---|---|---|
| 음표 수집 (On Beat) | 짧은 멜로딕 핑 (밝음) | 비트와 동기 |
| 음표 수집 (Off Beat) | 짧은 더블 핑 (둔탁) | On Beat와 구분 |
| 콤보 갱신 | 상승 글리산도 | 1회/콤보 |
| 피격 (Shield 흡수) | 둔탁한 "쿵" | 너무 길지 않게 |
| 게임 오버 | 슬라이드 다운 + "수간호사한테 걸렸다" 보이스(선택) | |
| 메뉴 선택 | 짧은 클릭 | UI 공통 |

**BGM:**
- 메뉴 / 게임 / 결과 화면 각 1곡 (총 3곡 목표).
- 게임 BGM은 **120 BPM 고정** (난이도 곡선 §3과 동기화).
- 길이 1분 루프, 끝 페이드아웃 제거하여 끊김 없이 반복.

**무료 대체 라이브러리 (제작 전 임시):**
- <https://freesound.org> (CC0 / CC-BY)
- <https://kenney.nl/assets/category:Audio> (CC0)
- 라이선스 표기는 `docs/assets.md` 하단 "사용 자산" 섹션에 누적 기록.

**기술적 처리:**
- 효과음: `SKAction.playSoundFileNamed("note.caf", waitForCompletion: false)`
- BGM: `AVAudioPlayer` (씬 전환에도 끊김 없도록 `AppDelegate` 보유)
- 동시 재생 한도 8개. 그 이상은 큐로 묶거나 무시.

---

## 5. 햅틱 / 진동 정책

iPhone 한정. iPad / 시뮬레이터 미지원 분기 처리.

| 이벤트 | 햅틱 |
|---|---|
| 음표 On Beat | Light Impact |
| 콤보 갱신 (4× 이상) | Medium Impact |
| 피격 | Heavy Impact |
| 게임 오버 | Notification(error) |
| 메뉴 선택 | Selection |

```swift
import UIKit
let generator = UIImpactFeedbackGenerator(style: .light)
generator.prepare()
generator.impactOccurred()
```

설정에서 OFF 옵션 제공 (Phase 3+).

---

## 6. 사용 자산 누적 기록

(자산을 추가할 때마다 여기에 누적. 라이선스 추적용.)

| 자산 | 종류 | 출처 | 라이선스 | 추가일 |
|---|---|---|---|---|
| (없음) | — | — | — | — |

---

## 7. 한 줄 결론

> **컬러 16색·폰트 1종·BPM 1개.** 이 세 가지만 첫날 고정해도 게임이 "한 사람이 만든 것" 처럼 보인다.
