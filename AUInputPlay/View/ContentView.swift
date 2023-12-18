//
//  ContentView.swift
//  AUInputPlay
//
//  Created by habi on 11/23/23.
//

import AudioToolbox
import SwiftUI

struct ContentView: View {
    @ObservedObject private var hostModel: AudioUnitHostModel
    
    @ObservedObject private var gainParam: ObservableAUParameter
    
    @State private var isStarted = false
    @State private var isPlaying = false
    
    init(hostModel: AudioUnitHostModel) {
        self.hostModel = hostModel
        
        let globalGroup = hostModel.observableAUParameterGroup!.global
        
        gainParam = globalGroup.gain
    }
    
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
            
            ParameterSlider(param: gainParam)
        }
        .padding()
    }
}

#Preview {
    ContentView(hostModel: AudioUnitHostModel())
}
