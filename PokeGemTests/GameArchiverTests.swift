import Testing
@testable import PokeGem
import Foundation

@MainActor
struct GameArchiverTests {

    private func cleanup() {
        GameArchiver.clear()
    }

    @Test("loadResult returns noData when no save exists")
    func loadResultNoData() {
        cleanup()
        let result = GameArchiver.loadResult()
        switch result {
        case .success:
            Issue.record("Expected failure, got success")
        case .failure(let error):
            #expect(error is ArchiveLoadError)
            if let archiveError = error as? ArchiveLoadError {
                if case .noData = archiveError {
                    // Expected
                } else {
                    Issue.record("Expected .noData, got \(archiveError)")
                }
            }
        }
        cleanup()
    }

    @Test("loadResult returns success with valid data")
    func loadResultSuccess() {
        cleanup()
        let config = GameConfig(
            humanPlayerAvatar: .ash,
            robotAvatars: [.gary],
            robotDifficulties: [.normal],
            targetScore: 15
        )
        let state = GameEngine.setup(config: config)
        GameArchiver.save(state: state, config: config)

        let result = GameArchiver.loadResult()
        switch result {
        case .success(let archived):
            #expect(archived.config.targetScore == 15)
            #expect(archived.state.players.count == 2)
        case .failure(let error):
            Issue.record("Expected success, got failure: \(error)")
        }
        cleanup()
    }

    @Test("loadResult returns decodingFailed with corrupted data")
    func loadResultCorruptedData() {
        cleanup()
        // Write invalid data directly to UserDefaults
        let invalidData = Data("not valid json".utf8)
        UserDefaults.standard.set(invalidData, forKey: "savedGame")

        let result = GameArchiver.loadResult()
        switch result {
        case .success:
            Issue.record("Expected failure, got success")
        case .failure(let error):
            #expect(error is ArchiveLoadError)
            if let archiveError = error as? ArchiveLoadError {
                if case .decodingFailed = archiveError {
                    // Expected
                } else {
                    Issue.record("Expected .decodingFailed, got \(archiveError)")
                }
            }
        }
        cleanup()
    }

    @Test("load returns nil when no save exists")
    func loadReturnsNil() {
        cleanup()
        let loaded = GameArchiver.load()
        #expect(loaded == nil)
        cleanup()
    }

    @Test("load returns archived game when valid")
    func loadReturnsValidGame() {
        cleanup()
        let config = GameConfig(
            humanPlayerAvatar: .ash,
            robotAvatars: [.gary],
            robotDifficulties: [.normal],
            targetScore: 15
        )
        let state = GameEngine.setup(config: config)
        GameArchiver.save(state: state, config: config)

        let loaded = GameArchiver.load()
        #expect(loaded != nil)
        #expect(loaded?.config.targetScore == 15)
        cleanup()
    }

    @Test("hasSavedGame reflects save state")
    func hasSavedGameState() {
        cleanup()
        #expect(GameArchiver.hasSavedGame == false)

        let config = GameConfig(
            humanPlayerAvatar: .ash,
            robotAvatars: [.gary],
            robotDifficulties: [.normal],
            targetScore: 15
        )
        let state = GameEngine.setup(config: config)
        GameArchiver.save(state: state, config: config)

        #expect(GameArchiver.hasSavedGame == true)
        cleanup()
        #expect(GameArchiver.hasSavedGame == false)
    }

    @Test("clear removes saved game")
    func clearRemovesSave() {
        cleanup()
        let config = GameConfig(
            humanPlayerAvatar: .ash,
            robotAvatars: [.gary],
            robotDifficulties: [.normal],
            targetScore: 15
        )
        let state = GameEngine.setup(config: config)
        GameArchiver.save(state: state, config: config)
        #expect(GameArchiver.hasSavedGame == true)

        GameArchiver.clear()
        #expect(GameArchiver.hasSavedGame == false)
        #expect(GameArchiver.load() == nil)
    }

    @Test("ArchiveLoadError descriptions are non-empty")
    func errorDescriptions() {
        let noData = ArchiveLoadError.noData
        #expect(noData.errorDescription != nil)
        #expect(!noData.errorDescription!.isEmpty)

        let decodingFailed = ArchiveLoadError.decodingFailed("test detail")
        #expect(decodingFailed.errorDescription != nil)
        #expect(decodingFailed.errorDescription!.contains("test detail"))
    }
}
