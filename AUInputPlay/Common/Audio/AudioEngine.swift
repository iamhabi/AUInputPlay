//
//  AudioEngine.swift
//  AUInputPlay
//
//  Created by habi on 11/23/23.
//

import Foundation
import CoreAudioKit
import AVFoundation

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Wraps and Audio Unit extension and provides helper functions.
extension AVAudioUnit {

    var wantsAudioInput: Bool {
        let componentType = self.auAudioUnit.componentDescription.componentType
        return componentType == kAudioUnitType_MusicEffect || componentType == kAudioUnitType_Effect
    }
    
    static fileprivate func findComponent(type: String, subType: String, manufacturer: String) -> AVAudioUnitComponent? {
        // Make a component description matching any Audio Unit of the selected component type.
        let description = AudioComponentDescription(componentType: type.fourCharCode!,
                                                    componentSubType: subType.fourCharCode!,
                                                    componentManufacturer: manufacturer.fourCharCode!,
                                                    componentFlags: 0,
                                                    componentFlagsMask: 0)
        return AVAudioUnitComponentManager.shared().components(matching: description).first
    }
    
    fileprivate func loadAudioUnitViewController(completion: @escaping (ViewController?) -> Void) {
        auAudioUnit.requestViewController { [weak self] viewController in
            DispatchQueue.main.async {
                if #available(macOS 13.0, iOS 16.0, *) {
                    if let self = self, viewController == nil {
                            let genericViewController = AUGenericViewController()
                            genericViewController.auAudioUnit = self.auAudioUnit
                            completion(genericViewController)
                            return
                    }
                }
                completion(viewController)
            }
        }
    }
}

/// Manages the interaction with the AudioToolbox and AVFoundation frameworks.
public class AudioEngine {
    private let stateChangeQueue = DispatchQueue(label: "com.example.apple-samplecode.StateChangeQueue")
    private let deviceStateChangeQueue = DispatchQueue(label: "com.example.apple-samplecode.AudioObjectChangeListenerBlock")
    
    // Playback engine.
    private let engine = AVAudioEngine()
    
    private var avAudioUnit: AVAudioUnit?
    
    // Whether we are playing.
    public var isPlaying: Bool {
        get {
            engine.isRunning
        }
    }
    private var isEngineIntialized: Bool = false
    
    private var aggregateDeviceId: AudioDeviceID = 0
    private let aggregateDeviceName: String = "IOPlayThrough"
    private let aggregateDeviceUID: String = "581023647"
    
    public var inputDevice: AudioDevice?
    
    init() {
        addDevicesChangeListener()
        addDefaultIODeviceChangeListener()
        
        destroyDeviceIfAlreadyExist()
    }
    
    func initComponent(type: String, subType: String, manufacturer: String, completion: @escaping (Result<Bool, Error>, NSViewController?) -> Void) {
        guard let component = AVAudioUnit.findComponent(type: type, subType: subType, manufacturer: manufacturer) else {
            print("Failed to find component with type: \(type), subtype: \(subType), manufacturer: \(manufacturer))" )
            
            return
        }
        
        AVAudioUnit.instantiate(with: component.audioComponentDescription,
                                options: AudioComponentInstantiationOptions.loadOutOfProcess) { avAudioUnit, error in
            
            guard let audioUnit = avAudioUnit, error == nil else {
                completion(.failure(error!), nil)
                return
            }
            
            self.avAudioUnit = audioUnit
            
            // Load view controller and call completion handler
            audioUnit.loadAudioUnitViewController { viewController in
                completion(.success(true), viewController)
            }
        }
    }
    
    // MARK: Initialize audio engine
    
    private func initEngine() {
        guard let avAudioUnit = self.avAudioUnit else {
            return
        }
        
        let inputFormat = engine.inputNode.inputFormat(forBus: 0)
        
        if inputFormat.sampleRate == 0
            || inputFormat.channelCount == 0 {
            return
        }
        
        engine.attach(avAudioUnit)
        
        engine.connect(engine.inputNode, to: avAudioUnit, format: inputFormat)
        engine.connect(avAudioUnit, to: engine.mainMixerNode, format: inputFormat)
        
        isEngineIntialized = true
    }
    
    private func reinitEngine() {
        if !isEngineIntialized {
            return
        }
        
        stop()
        
        setAggregateDevice()
        
        initEngine()
        
        start()
    }
    
    public func startEngine() {
        createAggregateDevice()
        
        setAggregateDevice()
        
        initEngine()
        
        start()
    }
    
    private func restartEngine() {
        if !isEngineIntialized {
            return
        }
        
        stop()
        
        destroyAggregateDevice()
        
        startEngine()
    }
    
    public func setAggregateDevice() {
        do {
            try engine.inputNode.auAudioUnit.setDeviceID(aggregateDeviceId)
            try engine.outputNode.auAudioUnit.setDeviceID(aggregateDeviceId)
        } catch {
            print("Fail to set input device")
        }
    }
    
    public func createAggregateDevice() {
        let defaultOutputDevice = AudioDeviceFinder.getDefaultOutputDevice()
        
        guard let inputDeviceUID = self.inputDevice?.uid,
              let outputDeviceUID = defaultOutputDevice.uid else {
            return
        }
        
        var subDevices: [[String: Any]] = [
            [kAudioSubDeviceUIDKey: inputDeviceUID]
        ]
        
        if inputDeviceUID != outputDeviceUID {
            subDevices.append([kAudioSubDeviceUIDKey: outputDeviceUID])
        }
        
        let desc: [String: Any] = [
            kAudioAggregateDeviceNameKey: aggregateDeviceName,
            kAudioAggregateDeviceUIDKey: aggregateDeviceUID,
            kAudioAggregateDeviceSubDeviceListKey: subDevices,
            kAudioAggregateDeviceMasterSubDeviceKey: inputDeviceUID,
            kAudioAggregateDeviceClockDeviceKey: inputDeviceUID
        ]
        
        if AudioHardwareCreateAggregateDevice(desc as CFDictionary, &aggregateDeviceId) != 0 {
            destroyAggregateDevice()
            
            return
        }
    }
    
    public func destroyAggregateDevice()  {
        AudioHardwareDestroyAggregateDevice(aggregateDeviceId)
    }
    
    private func destroyDeviceIfAlreadyExist() {
        let allDevices = AudioDeviceFinder.getAllDevices()
        
        if let auipDevice = allDevices.first(where: {$0.name == aggregateDeviceName}) {
            AudioHardwareDestroyAggregateDevice(auipDevice.audioDeviceID)
        }
    }
    
    private func addDevicesChangeListener() {
        AudioDeviceUtils.setListener(
            mSelector: kAudioHardwarePropertyDevices,
            listener: {
                self.reinitEngine()
            }
        )
    }
    
    private func addDefaultIODeviceChangeListener() {
        AudioDeviceUtils.setListener(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            listener: {
                self.reinitEngine()
            }
        )
        
        AudioDeviceUtils.setListener(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            listener: {
                self.restartEngine()
            }
        )
    }
    
    // MARK: Playback State
    
    public func start() {
        if !isPlaying {
            startPlayingInternal()
        }
    }
    
    public func pause() {
        if isPlaying {
            pausePlayingInternal()
        }
    }
    
    public func stop() {
        if isPlaying {
            stopPlayingInternal()
        }
    }
    
    private func startPlayingInternal() {
        do {
            try stateChangeQueue.sync {
                engine.prepare()
                try engine.start()
            }
            
            print("engine start")
        } catch {
            print("engine start error:\(error)")
        }
    }
    
    private func pausePlayingInternal() {
        stateChangeQueue.sync {
            engine.pause()
        }
        
        print("engine pause")
    }
    
    private func stopPlayingInternal() {
        stateChangeQueue.sync {
            isEngineIntialized = false
            
            engine.stop()
        }
        
        print("engine stop")
    }
}
