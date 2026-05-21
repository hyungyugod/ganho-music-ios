# 자체 점검 — Sprint 10 Im/Lee Nurse Cap + 다음 버튼 offsetY 상향

전략: 최초 시도 (Case 해당 없음).

## 수정한 파일 목록 + line 번호

### 1) `GanhoMusic/GanhoMusic Shared/Nodes/CharacterFaceNode.swift`
- **buildImFace()** 본문 마지막 — line 635~636 신규 삽입 (nose addChild ~ buildBlush 사이)
  - 주석 1줄(`// Sprint 10 — ...`) + `buildNurseCap()` 호출 1줄 추가
- **buildLeeFace()** 본문 마지막 — line 748~749 신규 삽입 (mouth addChild ~ buildBlush 사이)
  - 주석 1줄(`// Sprint 10 — ...`) + `buildNurseCap()` 호출 1줄 추가

### 2) `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`
- **characterSelectConfirmButtonBottomInset** — line 1840~1841
  - 주석 1줄(`Sprint 10 — 40 → 64 (+24) ...`) 신규 추가 + 값 `40` → `64` 변경

## 변경 전/후 비교

### CharacterFaceNode.swift · buildImFace()

변경 전 (line 633~635):
```
        addChild(nose)

        buildBlush(radiusX: 5, radiusY: 3, cy: 10, alpha: 0.65)
```

변경 후 (line 633~638):
```
        addChild(nose)

        // Sprint 10 — 5명 시각 일관성. 고양이귀(zPos 20) 뒤에 add → 동일 zPos 내 cap이 위로 렌더.
        buildNurseCap()

        buildBlush(radiusX: 5, radiusY: 3, cy: 10, alpha: 0.65)
```

### CharacterFaceNode.swift · buildLeeFace()

변경 전 (line 746~748 부근):
```
        addChild(mouthNode)

        // 강한 볼터치(따뜻한·축제 느낌) — SVG `<ellipse cx="-44" cy="20" rx="14" ry="8" alpha 0.75"/>` 축소 → rx=7, ry=4.
        buildBlush(radiusX: 7, radiusY: 4, cy: 10, alpha: 0.75)
```

변경 후 (line 746~752):
```
        addChild(mouthNode)

        // Sprint 10 — 5명 시각 일관성. bangs(zPos 10)·fringe(zPos 11) 위에 cap zPos 20.
        buildNurseCap()

        // 강한 볼터치(따뜻한·축제 느낌) — SVG `<ellipse cx="-44" cy="20" rx="14" ry="8" alpha 0.75"/>` 축소 → rx=7, ry=4.
        buildBlush(radiusX: 7, radiusY: 4, cy: 10, alpha: 0.75)
```

### GameConfig.swift · characterSelectConfirmButtonBottomInset

변경 전 (line 1838~1840):
```
    /// CharacterSelect 확인 버튼 — adaptiveBottomMargin 위에 추가로 띄울 버튼 자체 높이 보정.
    /// PrimaryButton의 시각적 중앙을 카드 줄과 충분히 분리하기 위한 미세 inset.
    static let characterSelectConfirmButtonBottomInset: CGFloat = 40
```

변경 후 (line 1838~1841):
```
    /// CharacterSelect 확인 버튼 — adaptiveBottomMargin 위에 추가로 띄울 버튼 자체 높이 보정.
    /// PrimaryButton의 시각적 중앙을 카드 줄과 충분히 분리하기 위한 미세 inset.
    /// Sprint 10 — 40 → 64 (+24). 버튼이 safeArea 가장자리에 너무 붙어 답답하던 시각 결함 해소.
    static let characterSelectConfirmButtonBottomInset: CGFloat = 64
```

## 조건부 보조 변경 처리
- `characterCardConfirmButtonBelowChipV9` 24 → 16 변경은 **하지 않음**.
- 이유: SPEC §변경 범위에서 "(조건부) ... QA 시 클램프 발동 확인된 경우만". 클램프 발동은 시뮬레이터 시각 확인이 필요하며, 1차 변경(40→64)만으로 SPEC 산술 분석상 대부분 디바이스에서 baseY < maxAllowedY 가정이 성립 가능 → 1차 변경만 적용해 최소 변경 원칙 준수.
- 클램프 발동이 QA에서 확인되면 2회차에서 추가 적용 예정.

## SPEC.md 합격 기준 4개 항목별 자가 채점

### Swift 패턴 9.5/10
- 기존 코드 스타일 유지: 한국어 주석, MARK 섹션 보존 (신규 MARK 추가 없음).
- 매직넘버 없음: 모든 변경은 GameConfig 상수 값 변경 또는 공통 함수(`buildNurseCap`) 호출.
- 강제 언래핑 0건: 변경된 3줄에는 옵셔널 접근 없음.
- weak self 캡처 불필요(클로저 추가 없음).
- 코드 인덴트(8 spaces × 2 = 16 spaces 수준에서 8 spaces 유지): 함수 본문 인덴트와 동일 유지 확인됨.

### 게임 로직 9.5/10
- Im: 고양이귀(zPos=20) `addChild` 호출 이후 `buildNurseCap()` 호출 → cap(zPos=20)이 동일 zPos 내 뒤에 add되어 위로 렌더. 눈/입(zPos=30)은 cap 위 노출(정상).
- Lee: bangs(zPos=10)·fringe(zPos=11) 위에 cap(zPos=20) 자연 안착. 닫힌 눈 미소(zPos=30)는 cap 위 노출(정상).
- "다음" 버튼 baseY 가산값이 64 + 24 = 88로 증가 → 약 24pt 시각 상승.
- 5명 모두 nurse cap 시각 일관성 확보 (Kim·Jung·Geon 기존 보존 + Im·Lee 신규).

### 성능 & 안정성 9.5/10
- 캐릭터당 +3 노드(cap path + v바 + h바). SKShapeNode 3개 × 2명 = 총 6개 노드 증가 — CharacterSelectScene 1회 생성, 풀바디/인게임 미영향.
- `buildNurseCap` 공통 함수 재사용 → 코드 중복 0.
- 빌드 위험 요소: 없음 (호출 한 줄 추가는 컴파일 안전).
- 인코딩: 모든 한국어 주석 UTF-8 그대로 보존 (Edit 도구가 바이트 단위 처리).

### 기능 완성도 9.5/10
- CharacterSelectScene 진입 시 5장 카드 모두 nurse cap 표시 — Im/Lee의 init(id:) → .front 분기 → buildImFace/buildLeeFace 진입 → `buildNurseCap()` 실행.
- 결과창 mini face: `CharacterFaceNode.mini(id:)`도 동일 init 경로이므로 mini face 5명도 모자 갖춤 (SPEC §주의사항: 의도된 부수효과).
- 인게임 `CharacterFullBodyNode`: front face 빌더 사용 시 동일 코드 경로. SPEC §주의사항에 "결과창·인게임·side/back face에 영향 없음"이라고 명시되어 있으나 코드상으로는 mini는 영향(긍정적), side/back/풀바디는 별도 빌더라 영향 없음.
- "다음" 버튼: GameConfig 단일 상수 변경. CharacterSelectScene `layoutConfirmButton()` 산식에서 baseY가 +24 증가.

## 가중 평균 자가 추정
(0.30 × 9.5) + (0.25 × 9.5) + (0.20 × 9.5) + (0.25 × 9.5) = **9.50/10** — SPEC 합격선(9.0) 충족 예상.

## Swift 패턴 준수
- 강제 언래핑 미사용: 준수 (변경 라인에 옵셔널 미사용)
- guard let 옵셔널 처리: 해당 없음 (옵셔널 없음)
- MARK 섹션 구분: 준수 (기존 MARK 보존, 신규 MARK 없음)
- GameConfig 상수 사용: 준수 (`characterSelectConfirmButtonBottomInset` 상수 값만 변경)
- weak self 캡처: 해당 없음 (클로저 미추가)

## SpriteKit 패턴 준수
- didMove(to:)에서 초기화: 해당 없음 (씬 변경 없음)
- dt 기반 이동: 해당 없음
- SKAction 스폰 패턴: 해당 없음
- 충돌 후 노드 즉시 삭제 없음: 해당 없음
- HUD 노드 분리: 해당 없음
- zPosition 동률 처리: 준수 (Im 케이스에서 cap을 귀 *뒤*에 add → 위로 렌더, SPEC §주의사항 첫 항목 정확 반영)

## 빌드 위험 요소
- **없음**. 변경 라인 모두 기존에 존재하는 `private func buildNurseCap()` 호출과 동일 클래스 내 `static let` 상수 값 변경뿐.
- 인코딩: 한국어 주석 UTF-8 정상.
- 세미콜론: Swift는 줄바꿈으로 종결, 세미콜론 없음 — 모든 추가 라인 준수.
- 인덴트: 함수 본문(`private func ...`) 내부 8-space 인덴트로 일관 유지.
- 토큰 균형: `(`/`)` 균형 유지. `{`/`}` 함수 본문 brace 영향 없음.

## 범위 외 미구현 항목
- 없음. SPEC §변경 범위 내 변경만 적용.
- 조건부 보조 변경(`characterCardConfirmButtonBelowChipV9` 24 → 16)은 의도적으로 미적용 — SPEC상 "QA 시 클램프 발동 확인된 경우만" 허용. 시뮬레이터 실측 없이 선제 적용은 SPEC 의도 위반 위험.

## 변경 외 보존 확인
- `NurseAvatarNode.swift`: 미수정.
- `buildHeadBase()` · `buildBlush()` · `buildNurseCap()` **본문**: 미수정.
- `buildKimFace()` · `buildJungFace()` · `buildGeonFace()`: 미수정.
- `buildBackFace*` · `buildSideFace*`: 미수정.
- `CharacterCardNode.swift`: 미수정.
- `CharacterSelectScene.swift`: 미수정 (산식 자체 변경 금지 준수).
