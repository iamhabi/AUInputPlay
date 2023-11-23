//
//  AudioDeviceListView.swift
//  AUInputPlay
//
//  Created by habi on 11/23/23.
//


import SwiftUI
import CoreAudioKit

struct AudioDeviceListView: View {
    @ObservedObject var hostModel: AudioUnitHostModel
    
    @ObservedObject private var inputDeviceViewModel: AudioDeviceViewModel
    
    init(hostModel: AudioUnitHostModel) {
        self.hostModel = hostModel
        
        inputDeviceViewModel = AudioDeviceViewModel()
        
        inputDeviceViewModel.list = AudioDeviceFinder.getInputDevices()
        
        let defaultInputDevice = AudioDeviceFinder.getDefaultInputDevice()
        
        let index = inputDeviceViewModel.list.firstIndex(where: {$0.audioDeviceID == defaultInputDevice.audioDeviceID}) ?? 0
        
        inputDeviceViewModel.currentIndex = index
        
        self.addDevicesChangeListener()
    }
    
    var body: some View {
        HStack {
            Picker("Input Device", selection: $inputDeviceViewModel.currentIndex) {
                ForEach(
                    Array(zip(inputDeviceViewModel.list.indices, inputDeviceViewModel.list)),
                    id: \.0
                ) { index, device in
                    if let name = device.name {
                        Text(name).tag(index)
                    }
                }
            }
            .pickerStyle(.menu)
            .onChange(of: inputDeviceViewModel.currentIndex) { _, index in
                let selectedDevice = inputDeviceViewModel.list[index]
                
                print("Selected device \(String(describing: selectedDevice.name))")
                
                hostModel.setInputDevice(AudioDevice: selectedDevice)
            }
        }
    }
    
    private func addDevicesChangeListener() {
        AudioDeviceUtils.setListener(
            mSelector: kAudioHardwarePropertyDevices,
            DispatchQueue: DispatchQueue.main,
            listener: {
                print("List change")
                
//                let inputDevices = AudioDeviceFinder.getInputDevices()
//
//                let inputIndex = inputDeviceViewModel.list.firstIndex(where: {$0.audioDeviceID == audioEngine.inputDevice?.audioDeviceID}) ?? 0
//
//                print("input index \(inputIndex)")
//
//                inputDeviceViewModel.list = inputDevices
//
//                inputDeviceViewModel.currentIndex = inputIndex
            }
        )
    }
}

#Preview {
    AudioDeviceListView(hostModel: AudioUnitHostModel())
}
