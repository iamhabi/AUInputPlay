//
//  AudioDeviceFinder.swift
//  AUInputPlay
//
//  Created by habi on 11/23/23.
//

import Foundation
import CoreAudio

class AudioDeviceFinder {
    public static func getOutputDevices() -> [AudioDevice] {
        var list = [AudioDevice]()
        let devices = getAllDevices()
        
        for device in devices {
            if device.hasOutput
                && !isAggregateDevice(AudioDeviceID: device.audioDeviceID) {
                list.append(device)
            }
        }
        
        return list
    }
    
    public static func getInputDevices() -> [AudioDevice] {
        var list = [AudioDevice]()
        let devices = getAllDevices()
        
        for device in devices {
            if device.hasInput
                && !isAggregateDevice(AudioDeviceID: device.audioDeviceID) {
                list.append(device)
            }
        }
        
        return list
    }
    
    public static func getDefaultOutputDevice() -> AudioDevice {
        var defaultOutputDeviceID = kAudioDeviceUnknown
        var defaultOutputDeviceIDSize = UInt32(MemoryLayout.size(ofValue: defaultOutputDeviceID))
        
        var getDefaultOutputDevicePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &getDefaultOutputDevicePropertyAddress,
            0,
            nil,
            &defaultOutputDeviceIDSize,
            &defaultOutputDeviceID
        )
         
        return AudioDevice(deviceID: defaultOutputDeviceID)
    }
    
    public static func getDefaultInputDevice() -> AudioDevice {
        var defaultInputDeviceID = kAudioDeviceUnknown
        var defaultInputDeviceIDSize = UInt32(MemoryLayout.size(ofValue: defaultInputDeviceID))
        
        var defaultInputDeviceAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &defaultInputDeviceAddress,
            0,
            nil,
            &defaultInputDeviceIDSize,
            &defaultInputDeviceID
        )
        
        return AudioDevice(deviceID: defaultInputDeviceID)
    }
    
    public static func getIODevices() -> [AudioDevice] {
        var list = [AudioDevice]()
        let devices = getAllDevices()
        
        for device in devices {
            if device.hasInput && device.hasOutput {
                list.append(device)
            }
        }
        
        return list
    }
    
    public static func getAllDevices() -> [AudioDevice] {
        var list = [AudioDevice]()
        
        var propsize: UInt32 = 0

        var address: AudioObjectPropertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDevices),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain)
        )
        
        let addressSize: UInt32 = UInt32(MemoryLayout<AudioObjectPropertyAddress>.size)

        if AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            addressSize,
            nil,
            &propsize
        ) != 0 {
            return list
        }

        let audioDeviceCount = Int(propsize / UInt32(MemoryLayout<AudioDeviceID>.size))
        var audioDeviceIDs = [AudioDeviceID]()
        
        for _ in 0..<audioDeviceCount {
            audioDeviceIDs.append(AudioDeviceID())
        }

        if AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propsize,
            &audioDeviceIDs
        ) != 0 {
            return list
        }

        for i in 0..<audioDeviceCount {
            list.append(AudioDevice(deviceID: audioDeviceIDs[i]))
        }
        
        return list
    }
    
    public static func isAggregateDevice(AudioDeviceID audioDeviceID: AudioDeviceID) -> Bool {
        let address = AudioDeviceUtils.createAudioObjectPropertyAddress(mSelector: kAudioDevicePropertyTransportType)
        
        var deviceType: AudioDevicePropertyID = 0
        
        let propSize: UInt32 = UInt32(MemoryLayout<AudioDevicePropertyID>.size)
        
        if AudioDeviceUtils.getData(
            AudioDeviceID: audioDeviceID,
            Address: address,
            DataSize: propSize,
            Data: &deviceType
        ) != 0 {
            return false
        }
        
        return deviceType == kAudioDeviceTransportTypeAggregate
    }
}
