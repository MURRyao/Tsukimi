//
//  TsukimiApp.swift
//  Tsukimi
//
//  Created by dmitry on 23.05.2026.
//

import SwiftUI

@main
struct TsukimiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            TsukimiSettingsView(settings: AppServices.shared.settings)
        }
    }
}
