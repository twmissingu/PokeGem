//
//  PokeGemApp.swift
//  PokeGem
//
//  Splendor (璀璨宝石) board game for iOS
//  Modernized with SwiftUI, iOS 17+, MVVM architecture
//

import SwiftUI

@main
struct PokeGemApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
        }
    }
}
