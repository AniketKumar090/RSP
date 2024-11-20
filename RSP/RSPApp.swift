//
//  RSPApp.swift
//  RSP
//
//  Created by Aniket Kumar on 23/07/24.
//

import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var gameID = UUID()
}


@main
struct RSPApp: App {
    @StateObject var appState = AppState.shared
    var body: some Scene {
        WindowGroup {
            SplashScreen().id(appState.gameID)
        }
    }
}
