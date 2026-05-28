import Foundation

struct ArchivedGame: Codable {
    let state: GameState
    let config: GameConfig
    let timestamp: Date
}

enum ArchiveLoadError: LocalizedError {
    case noData
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .noData: return "没有找到存档数据"
        case .decodingFailed(let detail): return "存档数据已损坏: \(detail)"
        }
    }
}

struct GameArchiver {
    private static let saveKey = "savedGame"

    static func save(state: GameState, config: GameConfig) {
        let archive = ArchivedGame(state: state, config: config, timestamp: Date())
        do {
            let data = try JSONEncoder().encode(archive)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            #if DEBUG
            print("[GameArchiver] save failed: \(error)")
            #endif
        }
    }

    static func load() -> ArchivedGame? {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return nil }
        return try? JSONDecoder().decode(ArchivedGame.self, from: data)
    }

    static func loadResult() -> Result<ArchivedGame, ArchiveLoadError> {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            return .failure(.noData)
        }
        do {
            let archived = try JSONDecoder().decode(ArchivedGame.self, from: data)
            return .success(archived)
        } catch {
            return .failure(.decodingFailed(error.localizedDescription))
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: saveKey)
    }

    static var hasSavedGame: Bool {
        UserDefaults.standard.data(forKey: saveKey) != nil
    }
}
