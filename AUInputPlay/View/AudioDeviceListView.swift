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
        
        var inputDevice: AudioDevice
        if let currenInputDevice = hostModel.getInputDevice() {
            inputDevice = currenInputDevice
        } else {
            inputDevice = AudioDeviceFinder.getDefaultInputDevice()
        }
        
        let inputDevices = AudioDeviceFinder.getInputDevices()

        let inputIndex = inputDevices.firstIndex(where: {$0.audioDeviceID == inputDevice.audioDeviceID}) ?? 0

        inputDeviceViewModel.list = inputDevices
        inputDeviceViewModel.currentIndex = inputIndex
        
        if hostModel.getInputDevice() == nil {
            hostModel.setInputDevice(AudioDevice: inputDevice)
        }
        
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
                guard let inputDevice = hostModel.getInputDevice() else {
                    return
                }
                let inputDevices = AudioDeviceFinder.getInputDevices()

                let inputIndex = inputDevices.firstIndex(where: {$0.audioDeviceID == inputDevice.audioDeviceID}) ?? 0

                inputDeviceViewModel.list = inputDevices
                inputDeviceViewModel.currentIndex = inputIndex
            }
        )
    }
}

#Preview {
    AudioDeviceListView(hostModel: AudioUnitHostModel())
}
