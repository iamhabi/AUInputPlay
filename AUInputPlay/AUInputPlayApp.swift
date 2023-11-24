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
    @ObservedObject var hostModel: AudioUnitHostModel = AudioUnitHostModel()

    var body: some Scene {
        MenuBarExtra("AUIP") {
            ContentView(hostModel: hostModel)
        }
    }
}
