# 2026-05-27 · 게임플레이 마감 다듬기

이번 작업 한 줄: 게임 도중 멈춤/복귀, 매혹 시각 피드백, 결과 공유, 졸업 목표 점수를 플레이어가 이해하기 쉽게 정리했다.

## 2026-05-27 추가 검토 · 중독성 루프와 시퀀스 정리

현재 게임의 반복 동기는 이미 4개 축으로 구성되어 있다.

1. 45초 짧은 판: 실패해도 부담이 작고, 결과 직후 재도전 명분이 생긴다.
2. 콤보 사다리: x3, x5, x7, x10, x20이 점수 상승과 피드백을 만든다.
3. 난이도별 졸업 목표: 하/중/상 목표 점수가 결과 화면의 장기 목표가 된다.
4. 캐릭터별 스킬: 같은 맵과 규칙을 다른 해법으로 다시 플레이하게 만든다.

이번 추가 수정은 이 루프의 가장 큰 마찰이던 결과 화면 재도전을 다듬었다. 기존에는 `다시 시작` 버튼이 보여도 실제 터치 처리는 공유/기록 보기를 제외한 모든 탭을 StartScene으로 보냈다. 그래서 한 판 끝난 뒤 `시작 → 캐릭터 → 스킬 → 난이도 → 컷씬 → 카운트다운`을 다시 거쳐야 했다. 이제 `다시 시작` 버튼은 같은 캐릭터와 같은 난이도로 `GameScene`을 바로 띄운다. 플레이어 입장에서는 "아, 6점만 더 하면 되는데"라는 감정이 식기 전에 바로 다음 판으로 들어간다.

정리된 권장 시퀀스:

```text
Start
  -> Character Select
  -> Skill Explanation(김간호는 스킵)
  -> Difficulty Select
  -> Intro / Danger Cutscene
  -> Countdown
  -> 45s Gameplay
  -> Result
       -> Retry: 같은 캐릭터 + 같은 난이도 즉시 재도전
       -> Scoreboard: 기록 확인 후 결과로 복귀
       -> Share: 결과 이미지/문구 공유
       -> Background tap: Start 복귀
```

후속으로 더 키우면 좋은 중독성 포인트:

- 결과 화면에 "최고 기록까지 N점"과 "목표까지 N점"을 분리해서 보여주기. 현재 목표 점수는 명확하지만, 최고 기록 추격 감정은 BEST pill에만 묻혀 있다.
- 플레이 중 10초 단위로 "목표까지 N점"을 아주 작게 토스트 처리하기. 단, HUD를 복잡하게 만들지 말고 수집 직후에만 짧게 보여주는 편이 좋다.
- 콤보 20 달성 후에는 단순 MAX 표시보다 "이번 판 보너스 미션 완료" 같은 1회 보상을 결과 화면에 연결하기.
- 컷씬은 최초 경험에서는 매력이고, 재도전에서는 마찰이 된다. 즉시 재도전 경로에서는 컷씬 스킵 여부를 별도 정책으로 검토할 수 있다.

## 큰 그림

SpriteKit 게임은 Spring Boot 웹앱처럼 "컨트롤러 → 서비스 → 도메인"이 딱 나뉘지는 않지만, 이 프로젝트는 비슷한 역할 분리를 유지하려고 한다.

| Swift 파일 | Spring으로 비유 | 이번 역할 |
| --- | --- | --- |
| `GameScene+GameState.swift` | Controller의 화면 상태 분기 | pause, resume, main menu, game over 흐름 |
| `DPadNode.swift` | 입력 DTO/컴포넌트 | 방향 입력을 저장하고 UI 눌림 상태 표시 |
| `SkillSystem.swift` | Service | 캐릭터별 스킬 발동 로직 |
| `EnemyNode.swift` | Domain 객체 | 수간호사의 이동, 발사, 매혹 시각 상태 |
| `ResultScene.swift` | 결과 페이지 Controller/View | 점수 결과, 버튼, 공유 시트 |
| `GameConfig.swift` | `application.yml` + constants | 난이도/점수/쿨다운 숫자 관리 |

## 1. 일시정지 중 입력 차단

문제: 일시정지 화면은 뜨지만, 손가락이 D-pad 위에 남아 있으면 재개 직후 입력 상태가 이어질 수 있다.

해결:

- `DPadNode.resetDirection()` 추가
- pause 진입 시 D-pad와 스킬 버튼의 `isUserInteractionEnabled` 값을 저장
- pause 중에는 둘 다 비활성화
- resume 시 저장했던 값을 복원

Spring으로 치면 모달이 떠 있는 동안 뒤쪽 Controller handler로 요청이 흘러가지 않게 필터에서 막는 느낌이다.

## 2. 결과 공유를 실제 공유 기능답게 만들기

문제: 공유 버튼은 있었지만 텍스트만 공유했다.

해결:

- `ResultScene`에서 iOS `UIActivityViewController` 사용
- 공유 문장 + 현재 결과 화면 캡처 이미지를 같이 전달
- 공유 시트가 이미 떠 있으면 중복 present를 막음

Swift 포인트:

```swift
var items: [Any] = [shareMessage()]
if let image = resultShareImage(from: view) {
    items.append(image)
}
```

`[Any]`는 Java의 `List<Object>`에 가깝다. 텍스트와 이미지를 한 배열에 같이 담기 위해 쓴다.

## 3. 매혹이 눈에 보이게 만들기

문제: 매혹 효과는 코드상 동작해도 플레이어 입장에서는 "눌렀나?" 싶은 순간이 있었다.

해결:

- 수간호사 얼굴에 하트눈 표시
- 수간호사 주변에 A 아이템 색 오라 표시
- 발동 순간 `매혹!` 토스트 표시

구조:

- `SkillSystem.performCharmStudent()`는 스킬 발동과 기존 F 변환 담당
- `EnemyNode.updateCharmVisual(isActive:)`는 매 프레임 상태 변화에 따라 시각만 담당

서비스가 상태를 만들고, 도메인/뷰 객체가 자기 모습을 바꾸는 구조다.

## 4. 졸업 목표 점수 정렬

기존:

```swift
.easy: 60, .normal: 50, .hard: 30
```

변경:

```swift
.easy: 60, .normal: 75, .hard: 90
```

실제 난이도는 F 밀도, 발사 속도, 음표 생존 시간으로 이미 올라간다. 목표 점수는 결과 화면에서 플레이어가 보는 "졸업 기준"이라서, 어려울수록 높은 숫자가 더 직관적이다.

## 읽는 순서

처음 Swift를 공부할 때는 아래 순서로 보면 좋다.

1. `GameConfig.swift`에서 숫자 정책을 본다.
2. `GameScene+GameState.swift`에서 화면 흐름을 본다.
3. `SkillSystem.swift`에서 스킬 발동 조건과 효과를 본다.
4. `EnemyNode.swift`에서 매혹 시각 효과를 본다.
5. `ResultScene.swift`에서 결과 화면과 공유 버튼 처리를 본다.

이 순서가 Spring 개발자가 익숙한 "설정 → Controller 흐름 → Service 로직 → Domain 상태 → View 응답"에 가장 가깝다.
