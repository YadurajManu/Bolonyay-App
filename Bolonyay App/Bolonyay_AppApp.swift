//
//  Bolonyay_AppApp.swift
//  Bolonyay App
//
//  Created by Yaduraj Singh on 06/06/25.
//

import SwiftUI
import FirebaseCore

@main
struct BoloNyayApp: App {
    @StateObject private var localizationManager = LocalizationManager()
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .environmentObject(localizationManager)
        }
    }
}
