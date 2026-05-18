//
//  GraduationRepository.swift
//  GanhoMusic Shared
//
//  Phase 7-4 · 캐릭터별 최초 졸업 일시 영속 저장소 (졸업장 시스템용)
//

import Foundation

/// 캐릭터별 *최초* 졸업 일시를 UserDefaults에 영구 저장하는 영속 계층.
/// UserDefaults JSON `[String: String]` 직렬화 — 키 = CharacterID.rawValue, 값 = ISO8601 Date 문자열.
///
/// ISO8601 형식 채택 이유: `.deferredToDate`(Codable Date 기본)가 로케일/타임존 의존이고
/// 디버그 시 epoch 숫자만 보여서 가독성이 0인 반면, ISO8601은 *사람이 읽을 수 있고* 로케일 안전.
/// 표시용 yyyy-MM-dd 변환은 DiplomaOverlayNode가 DateFormatter로 별도 처리.
///
/// **record 멱등 정책**: 이미 졸업한 캐릭터는 false 반환 → 일시 *영원 동일*.
/// 이후 갱신 점수가 들어와도 일시는 *최초 졸업 순간* 그대로 보존 — Phase 7-4의 핵심 요구.
/// "한 번 졸업한 사람의 일시는 영원히 같다" (자전적 의미 보존).
///
/// HighScoreRepository.record(score) > current 패턴과 *완전 분리* — 점수는 갱신, 일시는 불변.
///
/// init에 `defaults`/`key`를 기본값으로 받아 DI 허용. 단일 스레드(메인) 호출 가정 → 락/큐 없음.
///
/// Spring 비유: `@Column(updatable=false)` — 최초 INSERT 후 UPDATE 무시. 비즈니스 규칙으로 멱등 강제.
final class GraduationRepository {

    // MARK: - Properties
    private let key: String
    private let defaults: UserDefaults
    /// ISO8601 인코더/디코더. `.withInternetDateTime` = "yyyy-MM-ddTHH:mm:ssZ" 형식 (RFC 3339).
    /// init 1회 생성 후 재사용 — DateFormatter 류는 초기화 비용이 커서 인스턴스 멤버로 캐싱.
    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    // MARK: - Init
    init(defaults: UserDefaults = .standard,
         key: String = GameConfig.graduationUserDefaultsKey) {
        self.defaults = defaults
        self.key = key
    }

    // MARK: - Read
    /// 디스크에 저장된 졸업 일시 전체. 키가 없거나 디코딩 실패 시 빈 dict로 graceful 폴백.
    /// rawValue → CharacterID 역변환 실패 / ISO8601 파싱 실패는 *해당 셀만* 무시(graceful).
    var current: [CharacterID: Date] {
        guard let data = defaults.data(forKey: key) else { return [:] }
        guard let raw = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        var result: [CharacterID: Date] = [:]
        for (charRaw, isoStr) in raw {
            guard let charID = CharacterID(rawValue: charRaw) else { continue }
            guard let date = isoFormatter.date(from: isoStr) else { continue }
            result[charID] = date
        }
        return result
    }

    /// 특정 캐릭터의 졸업 일시. 미졸업 시 nil 반환.
    /// ResultScene.presentDiploma의 `if let graduatedAt` 가드와 짝.
    func graduatedAt(characterID: CharacterID) -> Date? {
        return current[characterID]
    }

    // MARK: - Write
    /// 최초 졸업 기록. 이미 졸업한 캐릭터는 *false* 반환(멱등 — 일시 영원 동일).
    /// 인코딩 실패 시 false — GameScene.endGame의 isNewGraduation false → 졸업장 미표시 (graceful).
    /// "이미 졸업 시 false" 정책은 ResultScene의 *최초 1회만 자동 표시* 정책과 짝 — 매 게임 표시 0.
    @discardableResult
    func record(characterID: CharacterID, date: Date) -> Bool {
        var dict = current
        if dict[characterID] != nil { return false }
        dict[characterID] = date
        // enum → rawValue + Date → ISO8601 직렬화.
        var raw: [String: String] = [:]
        for (charID, d) in dict {
            raw[charID.rawValue] = isoFormatter.string(from: d)
        }
        guard let data = try? JSONEncoder().encode(raw) else { return false }
        defaults.set(data, forKey: key)
        return true
    }
}
