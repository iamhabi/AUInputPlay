//
//  ContentView.swift
//  AUInputPlay
//
//  Created by habi on 11/23/23.
//

import AudioToolbox
import SwiftUI

struct ContentView: View {
    @ObservedObject var hostModel: AudioUnitHostModel
    
    @State private var isStarted = false
    @State private var isPlaying = false
    
    var body: some View {
        VStack {
            ChangeDefaultOutputDeviceView(hostModel: hostModel)
            
            Divider()
            
            AudioDeviceListView(hostModel: hostModel)
            
            HStack {
                Button {
                    if !isStarted {
                        hostModel.startEngine()
                        
                        isStarted = true
                    } else {
                        hostModel.stop()
                        hostModel.destroyAggregateDevice()
                        
                        isStarted = false
                    }
                    
                    isPlaying = hostModel.isPlaying
                } label: {
                    Text(isStarted ? "Stop" : "Start")
                }
            }
            
            if let viewController = hostModel.viewModel.viewController {
                AUViewControllerUI(viewController: viewController)
                    .padding()
            } else {
                Text("Can't get audio unit")
                    .padding()
            }
        }
        .padding()
    }
}

#Preview {
    ContentView(hostModel: AudioUnitHostModel())
}
