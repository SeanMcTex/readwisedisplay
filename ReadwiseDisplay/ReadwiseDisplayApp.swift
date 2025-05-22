//
//  ReadwiseDisplayApp.swift
//  ReadwiseDisplay
//
//  Created by Sean Mc Mains on 5/21/25.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct ReadwiseDisplayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, minHeight: 300)
        }
        Settings {
            SettingsView()
                .frame(minWidth: 300, idealWidth: 400, minHeight: 200, idealHeight: 250)
        }
    }
}
