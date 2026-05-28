import Foundation

/// Player avatar options
enum PlayerAvatar: String, Codable, CaseIterable {
    case ash = "avatar_ash"
    case misty = "avatar_misty"
    case brock = "avatar_brock"
    case teamRocket = "avatar_team_rocket"
    case jessie = "avatar_jessie"
    case james = "avatar_james"
    case gary = "avatar_gary"
    case oak = "avatar_oak"
    
    /// Display name
    var displayName: String {
        switch self {
        case .ash: return "小智"
        case .misty: return "小霞"
        case .brock: return "小刚"
        case .teamRocket: return "火箭队"
        case .jessie: return "武藏"
        case .james: return "小次郎"
        case .gary: return "小茂"
        case .oak: return "大木博士"
        }
    }
    
    /// Asset name
    var assetName: String {
        return rawValue
    }
    
    /// Get avatar for human player (randomly selected)
    static func humanAvatar() -> PlayerAvatar {
        return .ash
    }
    
    /// Get avatar for robot player based on difficulty
    static func robotAvatar(difficulty: AIDifficulty) -> PlayerAvatar {
        switch difficulty {
        case .easy:
            return .jessie
        case .normal:
            return .james
        case .hard:
            return .teamRocket
        }
    }

    /// Randomly select unique avatars for AI players, excluding the human player's avatar
    static func randomAvatars(count: Int, excluding: [PlayerAvatar] = []) -> [PlayerAvatar] {
        var pool = allCases.filter { !excluding.contains($0) }
        pool.shuffle()
        return Array(pool.prefix(count))
    }
}