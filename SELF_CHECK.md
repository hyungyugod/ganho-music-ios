# SELF_CHECK.md

## 구현 요약

- `DangerWarningProfile`을 추가해 easy/normal/hard별 경고선 길이, 투명도, 근접 경고 거리, near-miss 반경을 분리했다.
- 2회차 QA 피드백에 따라 `DangerWarningProfile` 내부 난이도별 숫자 리터럴을 제거하고, 모든 경고 수치를 `GameConfig` 상수/딕셔너리로 이동했다.
- 수간호사 F 텔레그래프에서 실제 발사 각도를 미리 확정하고, 같은 각도를 발사에 재사용해 경고선과 실제 투사체 방향이 어긋나지 않게 했다.
- 이교수 청진기 텔레그래프에도 단일 궤적 경고선을 붙이고, 난이도 프로필을 setup 시 주입했다.
- 수간호사, 석조무사, 이교수에 거리 기반 위험 링을 추가했다. 링은 init에서 1회 생성하고 `GameScene.update`에서 alpha/pulse만 갱신한다.
- F/청진기 near-miss 펄스를 추가해 피격 전 위험과 실제 피격 피드백을 분리했다.
- `PlayerNearMissWarningNode`를 추가해 투사체/청진기 중 가장 가까운 위험이 near-miss 반경 안에 들어오면 플레이어 주변 링도 함께 pulse한다.
- 위험 경고 갱신을 `GameScene+DangerWarnings.swift`로 분리해 `GameScene.swift`를 282줄로 낮췄다.
- 텔레그래프 blink 액션 키를 `GameConfig.telegraphBlinkActionKey`로 상수화했다.
- 실제 접촉/피격 피드백을 `GameScene+Feedback.swift` helper로 분리하고 contact callback에서는 helper를 호출하도록 정리했다.
- 새 Swift 파일 5개를 Xcode project sources에 등록했다.

## 변경하지 않은 범위

- 점수, 콤보, 졸업/결과 화면 계산은 변경하지 않았다.
- F/청진기 속도, 발사 간격, burst 수, 적 패트롤 좌표/속도는 변경하지 않았다.
- 새 적/새 아이템/새 보상 루프는 추가하지 않았다.

## 자체 점검

- 경고선은 텔레그래프 노드 자식으로 붙고 텔레그래프 제거 시 함께 제거된다.
- 근접 링과 near-miss 펄스는 매 프레임 새 노드를 만들지 않는다.
- hard 난이도는 경고선 정보량과 거리 경고를 더 절제하고, easy는 더 길고 명확하게 보이도록 설정했다.
- `StoneGuardNode.updatePixelAnimation(deltaTime:)`도 게임 루프에 연결해 기존 SKAction 패트롤 시각 프레임이 갱신되도록 했다.
- `GameScene.swift` 라인 수 확인: 282줄.
- 최종 QA에서 지적된 매혹 F near-miss 거리 집계 문제를 수정해, `isEnchanted == true`인 F는 플레이어 위험 링 계산에서 제외했다.

## 빌드

- `xcodebuild -project 'GanhoMusic/GanhoMusic.xcodeproj' -scheme 'GanhoMusic iOS' -destination 'generic/platform=iOS Simulator' build`
- 결과: 성공
- 참고: 기존 AppIntents metadata extraction warning은 계속 존재한다.
