//
//  AUInputPlayApp.swift
//  AUInputPlay
//
//  Created by habi on 11/23/23.
//

import CoreMIDI
import SwiftUI

@main
class AUInputPlayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @ObservedObject var hostModel: AudioUnitHostModel = AudioUnitHostModel()
    
    required init() {
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { _ in
            self.hostModel.stop()
            self.hostModel.destroyAggregateDevice()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(hostModel: hostModel)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
