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
    
    public var icon: CFURL? {
        get {
            getIcon()
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

        var propSize: UInt32 = UInt32(MemoryLayout<CFString?>.size)
        
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

        var propSize: UInt32 = UInt32(MemoryLayout<CFString?>.size)
        
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
        let propSize: UInt32 = UInt32(MemoryLayout<CFString?>.size)
        
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
        let address: AudioObjectPropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var name: CFString? = nil
        let propSize: UInt32 = UInt32(MemoryLayout<CFString?>.size)
        
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
    
    private func getManufacturer() -> String? {
        let address: AudioObjectPropertyAddress = AudioDeviceUtils.createAudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceManufacturerCFString
        )

        var manufacturer: CFString? = nil
        let propSize: UInt32 = UInt32(MemoryLayout<CFString?>.size)
        
        if AudioDeviceUtils.getData(
            AudioDeviceID: self.audioDeviceID,
            Address: address,
            DataSize: propSize,
            Data: &manufacturer
        ) != 0 {
            return nil
        }

        return manufacturer as String?
    }
    
    private func getIcon() -> CFURL? {
        let address: AudioObjectPropertyAddress = AudioDeviceUtils.createAudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyIcon
        )
        
        var iconURL: CFURL? = nil
        let propSize: UInt32 = UInt32(MemoryLayout<CFURL?>.size)
        
        if AudioDeviceUtils.getData(
            AudioDeviceID: self.audioDeviceID,
            Address: address,
            DataSize: propSize,
            Data: &iconURL
        ) != 0 {
            return nil
        }

        return iconURL
    }
}
