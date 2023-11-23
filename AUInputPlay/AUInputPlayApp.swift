//
//  AUInputPlayApp.swift
//  AUInputPlay
//
//  Created by habi on 11/23/23.
//

import CoreMIDI
import SwiftUI

@main
struct AUInputPlayApp: App {
    @ObservedObject private var hostModel = AudioUnitHostModel()

    var body: some Scene {
        WindowGroup {
            ContentView(hostModel: hostModel)
        }
    }
}
