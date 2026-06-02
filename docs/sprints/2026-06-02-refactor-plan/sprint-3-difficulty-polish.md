# Sprint 3 - Difficulty Select Polish

## 목표

난이도 선택 화면에서 시작 버튼 주변의 큰 원형 halo를 제거하고, 좌측 캐릭터 전신 이미지가 눌려 보이는 문제를 해결한다.

## 현재 상태 요약

- `DifficultySelectScene`은 `startButtonHalo`라는 ellipse node를 시작 버튼 뒤에 추가한다.
- 좌측 캐릭터 요약은 `summaryFace: SKSpriteNode`에 `80x80` 크기를 강제로 적용한다.
- 전신 캐릭터 텍스처는 원본 비율이 있는데 정사각형 크기 때문에 압축되어 보일 수 있다.

## 범위

포함:
- `startButtonHalo` 제거.
- 캐릭터 요약 이미지 aspect fit 적용.
- 좌측 요약 카드, 우측 난이도 카드, 시작 버튼 간격 재점검.

제외:
- 난이도 카드 색상/문구 전면 변경.
- 캐릭터 홈 화면 변경.
- 게임 난이도 수치 변경.

## 구현 계획

1. Halo 제거
   - `startButtonHalo` 프로퍼티와 setup/layout 로직 제거 또는 alpha 0 처리.
   - 사용하지 않는 GameConfig halo 상수는 바로 삭제하지 않고, 다른 코드 참조 여부를 확인한다.

2. 캐릭터 비율 보정
   - `summaryFace`에 고정 `80x80` 대신 max bounds를 두고 texture size 비율로 계산한다.
   - PNG가 없고 PixelSprite fallback일 때도 동일한 max bounds를 적용한다.

3. 레이아웃 조정
   - 좌측 summary 카드 안에서 이름 badge, 전신, 스킬, 속도 chip의 y 간격을 재산정한다.
   - 시작 버튼과 summary/card bottom 사이 최소 gap을 유지한다.

## 예상 수정 파일

- `GanhoMusic/GanhoMusic Shared/Scenes/DifficultySelectScene.swift`
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`

## 수용 기준

- 시작 버튼 뒤 큰 원이 보이지 않는다.
- 캐릭터 전신이 세로/가로로 눌려 보이지 않는다.
- 시작 버튼, 난이도 카드, 캐릭터 카드가 겹치지 않는다.
- 선택 난이도 저장과 게임 진입 로직은 그대로 동작한다.

## 리스크

- halo 제거 후 시작 버튼이 시각적으로 약해질 수 있다. 필요하면 버튼 자체 그림자/색 대비만 미세 조정한다.
- 이미지 비율 보정으로 카드 내부 여백이 달라질 수 있으므로 작은 화면에서 재검증한다.
