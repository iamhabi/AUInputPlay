//
//  AudioDevice.swift
//  AUInputPlay
//
//  Created by habi on 11/23/23.
//

import Foundation
import CoreAudio

public class AudioDevice: Identifiable {
    public var audioDeviceID: AudioDeviceID
    
    public var hasInput: Bool {
        get {
            getHasInput()
        }
    }
    
    public var hasOutput: Bool {
        get {
            getHasOutput()
        }
    }
    
    public var uid: String? {
        get {
            getUID()
        }
    }
    
    public var name: String? {
        get {
            getName()
        }
    }
    
    public var sampleRate: Double? {
        get {
            getSampleRate()
        }
    }
    
    public var inputChannelCount: AVAudioChannelCount? {
        get {
            getInputChannelCount()
        }
    }
    
    init(deviceID: AudioDeviceID) {
        self.audioDeviceID = deviceID
    }
    
    private func getHasInput() -> Bool {
        var address: AudioObjectPropertyAddress = AudioDeviceUtils.createAudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput
        )

        var propSize: UInt32 = MemoryLayout<CFString?>.u_size
        
        if AudioObjectGetPropertyDataSize(
            self.audioDeviceID,
            &address,
            0,
            nil,
            &propSize
        ) != 0 {
            return false
        }

        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity:Int(propSize))
        
        if AudioDeviceUtils.getData(
            AudioDeviceID: self.audioDeviceID,
            Address: address,
            DataSize: propSize,
            Data: bufferList
        ) != 0 {
            return false
        }

        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
        
        for bufferNum in 0..<buffers.count {
            if buffers[bufferNum].mNumberChannels > 0 {
                return true
            }
        }

        return false
    }

    private func getHasOutput() -> Bool {
        var address: AudioObjectPropertyAddress = AudioDeviceUtils.createAudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput
        )

        var propSize: UInt32 = MemoryLayout<CFString?>.u_size
        
        if AudioObjectGetPropertyDataSize(
            self.audioDeviceID,
            &address,
            0,
            nil,
            &propSize
        ) != 0 {
            return false
        }

        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity:Int(propSize))
        
        if AudioDeviceUtils.getData(
            AudioDeviceID: self.audioDeviceID,
            Address: address,
            DataSize: propSize,
            Data: bufferList
        ) != 0 {
            return false
        }

        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
        
        for bufferNum in 0..<buffers.count {
            if buffers[bufferNum].mNumberChannels > 0 {
                return true
            }
        }

        return false
    }

    private func getUID() -> String? {
        let address: AudioObjectPropertyAddress = AudioDeviceUtils.createAudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID
        )

        var uid: CFString? = nil
        let propSize: UInt32 = MemoryLayout<CFString?>.u_size
        
        if AudioDeviceUtils.getData(
            AudioDeviceID: self.audioDeviceID,
            Address: address,
            DataSize: propSize,
            Data: &uid
        ) != 0 {
            return nil
        }

        return uid as String?
    }

    private func getName() -> String? {
        let address: AudioObjectPropertyAddress = AudioDeviceUtils.createAudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString
        )

        var name: CFString? = nil
        let propSize: UInt32 = MemoryLayout<CFString?>.u_size
        
        if AudioDeviceUtils.getData(
            AudioDeviceID: self.audioDeviceID,
            Address: address,
            DataSize: propSize,
            Data: &name
        ) != 0 {
            return nil
        }

        return name as String?
    }
    
    private func getSampleRate() -> Double? {
        let address = AudioDeviceUtils.createAudioObjectPropertyAddress(mSelector: kAudioDevicePropertyActualSampleRate)
        
        var sampleRate: Double = -1
        let propSize: UInt32 = MemoryLayout<Double?>.u_size
        
        if AudioDeviceUtils.getData(
            AudioDeviceID: self.audioDeviceID,
            Address: address,
            DataSize: propSize,
            Data: &sampleRate
        ) != 0 {
            return nil
        }
        
        if sampleRate == -1 {
            return nil
        }
        
        return sampleRate
    }
    
    private func getInputChannelCount() -> AVAudioChannelCount? {
        let address = AudioDeviceUtils.createAudioObjectPropertyAddress(
            mSelector: kAudioStreamPropertyPhysicalFormat,
            mScope: kAudioDevicePropertyScopeInput
        )

        var description: AudioStreamBasicDescription = .init()
        let propSize: UInt32 = MemoryLayout<AudioStreamBasicDescription>.u_size
        
        if AudioDeviceUtils.getData(
            AudioDeviceID: self.audioDeviceID,
            Address: address,
            DataSize: propSize,
            Data: &description
        ) != 0 {
            return nil
        }
        
        return description.mChannelsPerFrame
    }
}

extension MemoryLayout {
    public static var u_size: UInt32 {
        get {
            UInt32(self.size)
        }
    }
}
