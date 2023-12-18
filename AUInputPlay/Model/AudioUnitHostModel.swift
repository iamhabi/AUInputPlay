//
//  AudioUnitHostModel.swift
//  AUInputPlay
//
//  Created by habi on 11/23/23.
//

import SwiftUI
import CoreMIDI
import AudioToolbox

class AudioUnitHostModel: ObservableObject {
    private let audioEngine = AudioEngine()

    public var isPlaying: Bool {
        audioEngine.isPlaying
    }

    /// Audio Component Description
    private let description: AudioComponentDescription
    
    public var observableAUParameterGroup: ObservableAUParameterGroup?

    init(type: String = "aufx", subType: String = "auip", manufacturer: String = "AUIP") {
        self.description = AudioComponentDescription(
            componentType: type.fourCharCode!,
            componentSubType: subType.fourCharCode!,
            componentManufacturer: manufacturer.fourCharCode!,
            componentFlags: AudioComponentFlags.sandboxSafe.rawValue,
            componentFlagsMask: 1
        )
        
        AUAudioUnit.registerSubclass(
            AUIPAudioUnit.self,
            as: description,
            name: "auip",
            version: UInt32.max
        )
        
        loadAudioUnit()
    }

    public func loadAudioUnit() {
        self.observableAUParameterGroup = audioEngine.initComponent(description: description)
    }
    
    public func destroyAggregateDevice()  {
        audioEngine.destroyAggregateDevice()
    }
    
    public func startEngine() {
        audioEngine.startEngine()
    }
    
    public func start() {
        audioEngine.start()
    }
    
    public func pause() {
        audioEngine.pause()
    }
    
    public func stop() {
        audioEngine.stop()
    }
    
    public func setInputDevice(AudioDevice audioDevice: AudioDevice) {
        audioEngine.inputDevice = audioDevice
    }
    
    public func getInputDevice() -> AudioDevice? {
        return audioEngine.inputDevice
    }
}
