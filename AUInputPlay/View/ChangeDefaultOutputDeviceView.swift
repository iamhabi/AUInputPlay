//
//  ChangeDefaultOutputDeviceView.swift
//  AUInputPlay
//
//  Created by habi on 11/24/23.
//

import SwiftUI
import CoreAudioKit

struct ChangeDefaultOutputDeviceView: View {
    @ObservedObject var hostModel: AudioUnitHostModel
    
    @ObservedObject private var outputDeviceViewModel: AudioDeviceViewModel
    
    init(hostModel: AudioUnitHostModel) {
        self.hostModel = hostModel
        self.outputDeviceViewModel = AudioDeviceViewModel()
        
        updateDefaultOutputDevice()
        
        addDefaultOutputDeviceChangeListener()
        addDevicesChangeListener()
    }
    
    var body: some View {
        HStack {
            Picker("Default Output Device", selection: $outputDeviceViewModel.currentIndex) {
                ForEach(
                    Array(zip(outputDeviceViewModel.list.indices, outputDeviceViewModel.list)),
                    id: \.0
                ) { index, device in
                    if let name = device.name {
                        Text(name).tag(index)
                    }
                }
            }
            .pickerStyle(.menu)
            .onChange(of: outputDeviceViewModel.currentIndex) { _, index in
                let selectedDevice = outputDeviceViewModel.list[index]
                
                print(selectedDevice)
            }
        }
    }
    
    private func updateDefaultOutputDevice() {
        let defaultOutputDevice = AudioDeviceFinder.getDefaultOutputDevice()
        let outputDevices = AudioDeviceFinder.getOutputDevices()

        let outputIndex = outputDevices.firstIndex(where: {$0.audioDeviceID == defaultOutputDevice.audioDeviceID}) ?? 0

        outputDeviceViewModel.list = outputDevices
        outputDeviceViewModel.currentIndex = outputIndex
    }
    
    private func addDefaultOutputDeviceChangeListener() {
        AudioDeviceUtils.setListener(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            listener: {
                updateDefaultOutputDevice()
            }
        )
    }
    
    private func addDevicesChangeListener() {
        AudioDeviceUtils.setListener(
            mSelector: kAudioHardwarePropertyDevices,
            DispatchQueue: DispatchQueue.main,
            listener: {
                updateDefaultOutputDevice()
            }
        )
    }
}

#Preview {
    ChangeDefaultOutputDeviceView(
        hostModel: AudioUnitHostModel()
    )
}
