//
//  ReadwiseDisplayApp.swift
//  ReadwiseDisplay
//
//  Created by Sean Mc Mains on 5/21/25.
//

import SwiftUI

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
#endif

@main
struct ReadwiseDisplayApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                #if os(macOS)
                .frame(minWidth: 400, minHeight: 300)
                #endif
        }
        #if os(macOS)
        Settings {
            SettingsView()
                .frame(minWidth: 300, idealWidth: 400, minHeight: 200, idealHeight: 250)
        }
        #endif
    }
}
