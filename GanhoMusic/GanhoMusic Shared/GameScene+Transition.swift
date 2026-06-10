//
//  GameScene+Transition.swift
//  GanhoMusic Shared
//
//  R3 — 픽셀 디졸브 인트로 훅 (03_UI §9, SPEC 기능 6).
//  GameScene 본체 415줄 — 300줄 규칙상 본체 추가 금지 → 별도 확장 파일.
//  게임 로직·카운트다운 시퀀스 무변경 (디졸브가 겹쳐 재생). 커버는 0.4s 후 자가 제거 —
//  인게임 평시 노드 수 게이트(≤300)에 일시 +1, 0.4s 내 0 복귀.
//

import SpriteKit

extension GameScene: PixelDissolveReceiving {
    /// 카메라 follow 씬 — 커버는 반드시 cameraNode 자식 (씬 직부착 시 화면 밖 이탈, SPEC 주의사항 4).
    var pixelDissolveHostNode: SKNode {
        return cameraNode
    }
}
