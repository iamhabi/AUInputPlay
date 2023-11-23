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
    public var isPlaying: Bool = false
    
    private var aggregateDeviceId: AudioDeviceID = 0
    private let aggregateDeviceName: String = "IOPlayThrough"
    private let aggregateDeviceUID: String = "581023647"
    
    public var inputDevice: AudioDevice?
    
    init() {
//        self.addDevicesChangeListener()
//        self.addDefaultIODeviceChangeListener()
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
        
        engine.attach(avAudioUnit)
        
        engine.connect(engine.inputNode, to: avAudioUnit, format: inputFormat)
        engine.connect(avAudioUnit, to: engine.mainMixerNode, format: inputFormat)
    }
    
    public func startEngine() {
        createAggregateDevice()
        
        setAggregateDevice()
        
        initEngine()
        
        start()
    }
    
    private func restartEngine() {
        self.stop()
        
        self.initEngine()
    }
    
    public func setAggregateDevice() {
        do {
            try self.engine.inputNode.auAudioUnit.setDeviceID(aggregateDeviceId)
            try self.engine.outputNode.auAudioUnit.setDeviceID(aggregateDeviceId)
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
    
    private func addDevicesChangeListener() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            deviceStateChangeQueue,
            { (_: UInt32, _: UnsafePointer<AudioObjectPropertyAddress>) in
                self.restartEngine()
            }
        )
    }
    
    private func addDefaultIODeviceChangeListener() {
        var inputDeviceAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var outputDeviceAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &inputDeviceAddress,
            deviceStateChangeQueue,
            { (_: UInt32, _: UnsafePointer<AudioObjectPropertyAddress>) in
                self.restartEngine()
            }
        )
        
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &outputDeviceAddress,
            deviceStateChangeQueue,
            { (_: UInt32, _: UnsafePointer<AudioObjectPropertyAddress>) in
                self.restartEngine()
            }
        )
    }
    
    // MARK: Playback State
    
    public func start() {
        if !self.isPlaying {
            self.startPlayingInternal()
        }
    }
    
    public func pause() {
        if self.isPlaying {
            pausePlayingInternal()
        }
    }
    
    public func stop() {
        if self.isPlaying {
            self.stopPlayingInternal()
        }
    }
    
    private func startPlayingInternal() {
        do {
            try stateChangeQueue.sync {
                engine.prepare()
                try engine.start()
            }
            
            isPlaying = true
            
            print("engine start")
        } catch {
            print("engine start error:\(error)")
        }
    }
    
    private func pausePlayingInternal() {
        stateChangeQueue.sync {
            engine.pause()
        }
        
        isPlaying = false
        
        print("engine pause")
    }
    
    private func stopPlayingInternal() {
        stateChangeQueue.sync {
            engine.stop()
        }
        
        isPlaying = false
        
        print("engine stop")
    }
}
