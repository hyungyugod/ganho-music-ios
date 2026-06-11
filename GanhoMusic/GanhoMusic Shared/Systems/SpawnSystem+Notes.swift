//
//  SpawnSystem+Notes.swift
//  GanhoMusic Shared
//
//  R8 §B③ — SpawnSystem.swift(397줄) 분할: Note Spawn 섹션 (Phase 2-3 / Sprint 10 Phase I /
//  R7 §F4 자기 재예약 체인·중반 피크 실효 캡·패턴 스폰·열린 위치 산출).
//  코드 이동만 — 로직/시그니처 0 변경. 본체 의존 멤버는 본체에서 private → internal
//  (scene/worldNode/registry/noteProvider/progressProvider/comboProvider/noteSpawnTick —
//  각 선언부 주석 명기).
//

import SpriteKit

extension SpawnSystem {

    // MARK: - Note Spawn (Phase 2-3 / Sprint 10 Phase I / R7 §F4 — 사이클별 실효 간격 재계산)
    /// R7 — 구 repeatForever(고정 간격) → 자기 재예약 체인. 매 사이클 시작 시점의 콤보로 실효
    /// 간격을 재계산 — 콤보 하락 시 다음 사이클부터 자연 복귀 (ProfessorNode.scheduleNextThrow
    /// 재귀 예약 전례 동형, Timer 금지). 같은 노드(scene)·같은 키("spawnNotes") 유지 —
    /// stop() 정지·일시정지 시맨틱 기존과 동일 (SPEC §F4 보존 계약).
    func startNoteSpawnLoop() {
        scheduleNextNoteSpawn()
    }

    private func scheduleNextNoteSpawn() {
        let wait = SKAction.wait(forDuration: currentNoteSpawnInterval())
        let cycle = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.trySpawnNote()
            self.scheduleNextNoteSpawn()
        }
        scene?.run(.sequence([wait, cycle]), withKey: "spawnNotes")
    }

    /// R7 §F4 리스크 가속 — combo ≥ 7(comboBonusThresholdHigh 재사용, 신규 임계 금지) 동안
    /// 실효 간격 = noteSpawnInterval(noteRush ÷1.5 기반영 값) × 0.85.
    /// combo < 7이면 noteSpawnInterval 그대로 — 일반 판 스폰 간격 byte-동일 (회귀 0 게이트).
    private func currentNoteSpawnInterval() -> TimeInterval {
        guard comboProvider() >= GameplayTuning.comboBonusThresholdHigh else {
            return noteSpawnInterval
        }
        return noteSpawnInterval * FeelTuning.R7.comboRushSpawnIntervalScale
    }

    /// R7 §F1-② 중반 피크 — elapsed ≥ 25s부터 동시 음표 *실효 캡* +1 (스폰 틱당 발수 증가 아님).
    /// progressProvider(0~1) × gameDuration = elapsed 환산 — SpawnSystem은 시계 비소유.
    /// elapsed < 25s면 noteMaxConcurrent 그대로 — 일반 판 캡 byte-동일 (회귀 0 게이트).
    private func effectiveNoteCap() -> Int {
        let elapsed = progressProvider() * GameplayTuning.gameDuration
        guard elapsed >= FeelTuning.R7.waveMidPeakElapsed else { return noteMaxConcurrent }
        return noteMaxConcurrent + FeelTuning.R7.midPeakNoteCapBonus
    }

    /// 한 사이클당 1회 호출. 동시 음표 수 미만일 때만 1개 spawn.
    /// Phase 7-1 — 인스턴스 프로퍼티 참조 + addChild 직후 applyLifetime 호출.
    /// easy(.infinity)는 applyLifetime 가드로 noop → 기존 동작 정확 보존.
    /// R7 §F1-② — 캡 가드를 실효 캡(effectiveNoteCap) 기준으로 일관 적용.
    private func trySpawnNote() {
        guard let world = worldNode else { return }
        noteSpawnTick += 1
        if noteSpawnTick % GameplayTuning.notePatternEverySpawn == 0,
           trySpawnNotePattern(in: world) {
            return
        }
        guard currentNoteCount() < effectiveNoteCap() else { return }
        guard let position = randomNotePosition() else { return }
        spawnNote(at: position, in: world)
    }

    /// 활성 음표 수 — R1: registry 캐시 조회 (구 worldNode enumerate 카운트 대체).
    private func currentNoteCount() -> Int {
        return registry?.notes.count ?? 0
    }

    /// 외곽 벽과 수집 hitbox가 겹치지 않는 열린 위치. 중앙 기둥/벽 내부 후보는 제한 횟수 안에서 재시도한다.
    private func randomNotePosition() -> CGPoint? {
        return randomOpenMapPosition(halfExtent: GameplayTuning.spawnCollectibleHalfExtent)
    }

    func randomOpenMapPosition(halfExtent: CGFloat) -> CGPoint? {
        let margin = GameplayTuning.tileSize + halfExtent
        let minX = margin
        let maxX = GameplayTuning.mapWidth - margin
        let minY = margin
        let maxY = GameplayTuning.mapHeight - margin
        guard maxX >= minX, maxY >= minY else { return nil }

        for _ in 0..<GameplayTuning.spawnPositionMaxAttempts {
            let point = CGPoint(
                x: CGFloat.random(in: minX ... maxX),
                y: CGFloat.random(in: minY ... maxY)
            )
            guard isAwayFromCenterPillar(point) else { continue }
            guard isOpenSpawnPoint(point, halfExtent: halfExtent) else { continue }
            return point
        }

        return nil
    }

    private func isAwayFromCenterPillar(_ point: CGPoint) -> Bool {
        let cx = GameplayTuning.mapWidth / 2
        let cy = GameplayTuning.mapHeight / 2
        return abs(point.x - cx) + abs(point.y - cy) >= GameplayTuning.tileSize * 3
    }

    private func isOpenSpawnPoint(_ point: CGPoint, halfExtent: CGFloat) -> Bool {
        let margin = GameplayTuning.tileSize + halfExtent
        guard point.x >= margin, point.x <= GameplayTuning.mapWidth - margin else { return false }
        guard point.y >= margin, point.y <= GameplayTuning.mapHeight - margin else { return false }

        for sample in spawnCollisionSamples(center: point, halfExtent: halfExtent) {
            if hasWallBody(at: sample) {
                return false
            }
        }
        return true
    }

    private func spawnCollisionSamples(center: CGPoint, halfExtent: CGFloat) -> [CGPoint] {
        return [
            center,
            CGPoint(x: center.x - halfExtent, y: center.y - halfExtent),
            CGPoint(x: center.x + halfExtent, y: center.y - halfExtent),
            CGPoint(x: center.x - halfExtent, y: center.y + halfExtent),
            CGPoint(x: center.x + halfExtent, y: center.y + halfExtent)
        ]
    }

    private func hasWallBody(at point: CGPoint) -> Bool {
        guard let scene = scene else { return false }
        if let body = scene.physicsWorld.body(at: point),
           (body.categoryBitMask & PhysicsCategory.wall) != 0 {
            return true
        }
        return false
    }

    /// R7 §F1-② — 패턴 가드도 실효 캡 기준 (trySpawnNote의 단일 캡 가드와 일관 적용).
    private func trySpawnNotePattern(in world: SKNode) -> Bool {
        guard currentNoteCount() <= effectiveNoteCap() - GameplayTuning.notePatternSize else { return false }
        guard let origin = randomNotePosition() else { return false }
        let spacing = GameplayTuning.notePatternSpacing
        let rawOffsets: [CGPoint]
        switch (noteSpawnTick / GameplayTuning.notePatternEverySpawn) % 3 {
        case 0:
            rawOffsets = [-1.5, -0.5, 0.5, 1.5].map { CGPoint(x: $0 * spacing, y: 0) }
        case 1:
            rawOffsets = [-1.5, -0.5, 0.5, 1.5].map { CGPoint(x: $0 * spacing, y: $0 * spacing * 0.55) }
        // Int(% 3) 매칭 — 컴파일러가 나머지 도메인을 못 보는 구조적 필수 default (R8 감사 분류 ②).
        default:
            rawOffsets = [
                CGPoint(x: -spacing, y: 0),
                CGPoint(x: 0, y: spacing * 0.72),
                CGPoint(x: spacing, y: 0),
                CGPoint(x: 0, y: -spacing * 0.72)
            ]
        }
        for offset in rawOffsets {
            let position = clampedNotePosition(CGPoint(x: origin.x + offset.x, y: origin.y + offset.y))
            guard isOpenSpawnPoint(position, halfExtent: GameplayTuning.spawnCollectibleHalfExtent) else { continue }
            spawnNote(at: position, in: world)
        }
        return true
    }

    /// R1 — 풀+레지스트리 경유 실체화: provider가 obtain→register, 본 시설이 addChild.
    /// TTL은 addChild 직후 매 spawn마다 재부착 — 재사용 노드도 신품과 동일 수명 정책.
    private func spawnNote(at position: CGPoint, in world: SKNode) {
        let note = noteProvider()
        note.position = position
        world.addChild(note)
        note.applyLifetime(noteLifetime)
    }

    private func clampedNotePosition(_ point: CGPoint) -> CGPoint {
        let margin = GameplayTuning.tileSize + GameplayTuning.spawnCollectibleHalfExtent
        return CGPoint(
            x: min(max(point.x, margin), GameplayTuning.mapWidth - margin),
            y: min(max(point.y, margin), GameplayTuning.mapHeight - margin)
        )
    }
}
