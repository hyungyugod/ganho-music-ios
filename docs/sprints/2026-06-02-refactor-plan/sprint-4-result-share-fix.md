# Sprint 4 - Result Share Fix

## 목표

결과 화면의 `공유/자랑하기` 버튼이 실기기에서 안정적으로 작동하게 한다. 공유 메시지와 결과 화면 이미지를 함께 전달하되, 이미지 렌더링 실패 시 텍스트 공유만으로도 시트가 떠야 한다.

## 현재 상태 요약

- `ResultScene.swift`는 `UIActivityViewController`를 직접 생성해 `root.present(activity, animated: true)`를 호출한다.
- `resultShareImage(from:)`는 `UIGraphicsImageRenderer`와 `view.drawHierarchy`를 사용한다.
- `root.presentedViewController == nil` 조건 때문에 이미 표시 중인 view controller가 있으면 조용히 return한다.
- 공유 실패 상태를 사용자에게 알려주는 UI가 없다.

## 범위

포함:
- top-most presenter 탐색 안정화.
- 공유 이미지 생성 실패 시 fallback 텍스트 공유.
- iPad/popover anchor 안정화.
- 중복 탭 방지.
- 실패 시 짧은 피드백 표시.

제외:
- SNS별 커스텀 공유.
- 서버 업로드 이미지 생성.
- 결과 화면 디자인 변경.

## 구현 계획

1. Presenter 안정화
   - iOS 전용 helper를 만든다.
   - `view.window?.rootViewController`에서 시작해 `presentedViewController`를 따라 top-most를 찾는다.
   - 이미 `UIActivityViewController`가 떠 있으면 중복 표시하지 않는다.

2. 공유 item 구성
   - 기본 item은 항상 `shareMessage()`.
   - 이미지 생성 성공 시 image 추가.
   - 이미지 생성 실패해도 activity sheet는 표시한다.

3. 이미지 생성 방식 점검
   - 1차 후보: 기존 `UIGraphicsImageRenderer` 유지 + `afterScreenUpdates: false`.
   - 2차 후보: `SKView.texture(from:)`를 사용해 scene/node를 texture로 뜬 뒤 `UIImage`로 변환.
   - 구현 시 더 안정적인 방식을 선택한다.

4. 피드백
   - presenter를 찾지 못하면 `ToastLabelNode` 또는 간단한 SKLabel feedback을 띄운다.
   - 공유 버튼 중복 탭은 `isShareSheetPresenting` 같은 플래그로 막는다.

## 예상 수정 파일

- `GanhoMusic/GanhoMusic Shared/Scenes/ResultScene.swift`
- 필요 시 `GanhoMusic/GanhoMusic Shared/Nodes/ToastLabelNode.swift` 재사용

## 수용 기준

- 결과 화면에서 `공유`와 `자랑하기` 모두 탭 반응이 있다.
- 실기기에서 activity sheet가 표시된다.
- 신기록/일반 기록 모두 메시지가 올바르다.
- 이미지 생성 실패 시에도 텍스트 공유 시트는 뜬다.
- 공유 취소 후 다시 버튼을 누를 수 있다.

## 리스크

- `UIActivityViewController`는 iOS 환경 의존이 크다. 시뮬레이터와 실기기에서 모두 확인해야 한다.
- SKView 캡처는 타이밍에 따라 비어 보일 수 있다. 이미지 fallback 정책을 반드시 둔다.
