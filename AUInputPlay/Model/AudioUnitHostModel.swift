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

    /// The model providing information about the current Audio Unit
    @Published private(set) var viewModel = AudioUnitViewModel()

    var isPlaying: Bool {
        audioEngine.isPlaying
    }

    /// Audio Component Description
    let type: String
    let subType: String
    let manufacturer: String

    init(type: String = "aufx", subType: String = "auip", manufacturer: String = "AUIP") {
        self.type = type
        self.subType = subType
        self.manufacturer = manufacturer
        
        loadAudioUnit()
    }

    public func loadAudioUnit() {
        audioEngine.initComponent(type: type,
                                 subType: subType,
                                 manufacturer: manufacturer) { [self] result, viewController in
            switch result {
            case .success(_):
                self.viewModel = AudioUnitViewModel(viewController: viewController)
            case .failure(_):
                self.viewModel = AudioUnitViewModel(viewController: nil)
            }
        }
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
