//
//  bag_endApp.swift
//  bag-end
//
//  Created by dmitry on 23.05.2026.
//

import SwiftUI

@main
struct bag_endApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            BagEndSettingsView(settings: AppServices.shared.settings)
        }
    }
}
