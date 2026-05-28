//
//  PlayerAvatarTests.swift
//  PokeGemTests
//
//  Unit tests for PlayerAvatar enum
//

import Testing
@testable import PokeGem

struct PlayerAvatarTests {

    // MARK: - Display Names

    @Test("ash display name is correct")
    func ashName() {
        #expect(PlayerAvatar.ash.displayName == "小智")
    }

    @Test("misty display name is correct")
    func mistyName() {
        #expect(PlayerAvatar.misty.displayName == "小霞")
    }

    @Test("brock display name is correct")
    func brockName() {
        #expect(PlayerAvatar.brock.displayName == "小刚")
    }

    @Test("teamRocket display name is correct")
    func teamRocketName() {
        #expect(PlayerAvatar.teamRocket.displayName == "火箭队")
    }

    @Test("jessie display name is correct")
    func jessieName() {
        #expect(PlayerAvatar.jessie.displayName == "武藏")
    }

    @Test("james display name is correct")
    func jamesName() {
        #expect(PlayerAvatar.james.displayName == "小次郎")
    }

    @Test("gary display name is correct")
    func garyName() {
        #expect(PlayerAvatar.gary.displayName == "小茂")
    }

    @Test("oak display name is correct")
    func oakName() {
        #expect(PlayerAvatar.oak.displayName == "大木博士")
    }

    // MARK: - Asset Names

    @Test("assetName matches raw value")
    func assetNameMatches() {
        #expect(PlayerAvatar.ash.assetName == "avatar_ash")
        #expect(PlayerAvatar.misty.assetName == "avatar_misty")
    }

    // MARK: - Static Helpers

    @Test("humanAvatar returns ash")
    func humanAvatar() {
        #expect(PlayerAvatar.humanAvatar() == .ash)
    }

    @Test("robotAvatar easy returns jessie")
    func robotAvatarEasy() {
        #expect(PlayerAvatar.robotAvatar(difficulty: .easy) == .jessie)
    }

    @Test("robotAvatar normal returns james")
    func robotAvatarNormal() {
        #expect(PlayerAvatar.robotAvatar(difficulty: .normal) == .james)
    }

    @Test("robotAvatar hard returns teamRocket")
    func robotAvatarHard() {
        #expect(PlayerAvatar.robotAvatar(difficulty: .hard) == .teamRocket)
    }

    // MARK: - Random Avatars

    @Test("randomAvatars returns requested count")
    func randomAvatarsCount() {
        let avatars = PlayerAvatar.randomAvatars(count: 3)
        #expect(avatars.count == 3)
    }

    @Test("randomAvatars returns unique avatars")
    func randomAvatarsUnique() {
        let avatars = PlayerAvatar.randomAvatars(count: 5)
        #expect(Set(avatars).count == 5)
    }

    @Test("randomAvatars excludes specified avatar")
    func randomAvatarsExcludes() {
        let avatars = PlayerAvatar.randomAvatars(count: 8, excluding: [.ash])
        #expect(!avatars.contains(.ash))
    }

    @Test("randomAvatars excludes multiple")
    func randomAvatarsExcludesMultiple() {
        let avatars = PlayerAvatar.randomAvatars(count: 7, excluding: [.ash, .misty])
        #expect(!avatars.contains(.ash))
        #expect(!avatars.contains(.misty))
    }

    @Test("randomAvatars count cannot exceed available pool")
    func randomAvatarsMaxPool() {
        let avatars = PlayerAvatar.randomAvatars(count: 20, excluding: [.ash])
        // Only 7 remain after excluding ash
        #expect(avatars.count == 7)
    }

    // MARK: - CaseIterable

    @Test("allCases has 8 avatars")
    func allCasesCount() {
        #expect(PlayerAvatar.allCases.count == 8)
    }
}
