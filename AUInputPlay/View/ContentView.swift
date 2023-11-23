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
    
    @State private var isAUStarted = false
    
    var body: some View {
        VStack {
            AudioDeviceListView(hostModel: hostModel)
            
            HStack {
                Button {
                    if !isStarted {
                        hostModel.startEngine()
                        hostModel.loadAudioUnit()
                        
                        isAUStarted = true
                        isStarted = true
                    } else {
                        hostModel.stop()
                        
                        isStarted = false
                    }
                    
                    isPlaying = hostModel.isPlaying
                } label: {
                    Text(isStarted ? "Stop" : "Start")
                }
                
                if isStarted {
                    Button {
                        if isPlaying {
                            hostModel.pause()
                        } else {
                            hostModel.start()
                        }
                        
                        isPlaying = hostModel.isPlaying
                    } label: {
                        Text(isPlaying ? "pause" : "play")
                    }
                }
            }
            
            if isAUStarted {
                VStack(alignment: .center) {
                    if let viewController = hostModel.viewModel.viewController {
                        AUViewControllerUI(viewController: viewController)
                            .padding()
                    } else {
                        VStack() {
                            Text("Can't get audio unit")
                                .padding()
                        }
                        .frame(minWidth: 400, minHeight: 200)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView(hostModel: AudioUnitHostModel())
}
