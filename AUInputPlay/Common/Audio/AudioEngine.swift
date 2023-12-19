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
    private let aggregateDeviceName: String = "AUIP Aggregate Device"
    private let aggregateDeviceUID: String = "581023647"
    
    public var inputDevice: AudioDevice?
    
    init() {
        addDevicesChangeListener()
        addDefaultIODeviceChangeListener()
        
        destroyDeviceIfAlreadyExist()
    }
    
    func initComponent(description: AudioComponentDescription) -> ObservableAUParameterGroup? {
        guard let component = AVAudioUnitComponentManager.shared().components(matching: description).first else {
            return nil
        }
        
        var observableAUParemterGroup: ObservableAUParameterGroup? = nil
        
        AVAudioUnit.instantiate(
            with: component.audioComponentDescription,
            options: AudioComponentInstantiationOptions.loadOutOfProcess
        ) { avAudioUnit, error in
            guard let audioUnit = avAudioUnit, error == nil else {
                return
            }
            
            self.avAudioUnit = audioUnit
            
            guard let auInputPlayAudioUnit = audioUnit.auAudioUnit as? AUIPAudioUnit else {
                return
            }
            
            auInputPlayAudioUnit.setupParameterTree(AUIPParameterSpecs.createAUParameterTree())
            
            observableAUParemterGroup = auInputPlayAudioUnit.observableParameterTree
        }
        
        return observableAUParemterGroup
    }
    
    // MARK: Initialize audio engine
    
    private func initEngine() {
        guard let avAudioUnit = self.avAudioUnit else {
            return
        }
        
        engine.attach(avAudioUnit)
        
        let format = createAudioFormat()
        
        engine.connect(engine.inputNode, to: avAudioUnit, format: format)
        engine.connect(avAudioUnit, to: engine.mainMixerNode, format: format)
        
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
    
    private func createAudioFormat() -> AVAudioFormat? {
        guard let sampleRate = inputDevice?.sampleRate,
              let channelCount = inputDevice?.inputChannelCount else {
            return nil
        }
        
        let inputFormat = engine.inputNode.inputFormat(forBus: 0)
        
        var audioChannelBitmap = AudioChannelBitmap()
        
        for i in 0..<channelCount {
            let value: UInt32 = UInt32(pow(2.0, Double(i)))
            audioChannelBitmap.insert(AudioChannelBitmap(rawValue: value))
        }
        
        var audioChannelLayout = AudioChannelLayout(
            mChannelLayoutTag: kAudioChannelLayoutTag_UseChannelBitmap,
            mChannelBitmap: audioChannelBitmap,
            mNumberChannelDescriptions: 0,
            mChannelDescriptions: AudioChannelDescription()
        )
        
        return AVAudioFormat(
            commonFormat: inputFormat.commonFormat,
            sampleRate: sampleRate,
            interleaved: inputFormat.isInterleaved,
            channelLayout: AVAudioChannelLayout(layout: &audioChannelLayout)
        )
    }
    
    public func setAggregateDevice() {
        do {
            try engine.inputNode.auAudioUnit.setDeviceID(aggregateDeviceId)
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
        
        let subDevices: [[String: Any]] = [
            [kAudioSubDeviceUIDKey: inputDeviceUID],
            [kAudioSubDeviceUIDKey: outputDeviceUID]
        ]
        
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
    
    public func destroyAggregateDevice() {
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
