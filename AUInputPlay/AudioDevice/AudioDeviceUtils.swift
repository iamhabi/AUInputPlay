//
//  AudioDeviceUtils.swift
//  AUInputPlay
//
//  Created by habi on 11/23/23.
//

import Foundation
import CoreAudio

class AudioDeviceUtils {
    private static let deviceStateChangeQueue = DispatchQueue(label: "com.example.apple-samplecode.AudioObjectChangeListenerBlock")
    
    public static func createAudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector,
        mScope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
        mElement: AudioObjectPropertyElement = kAudioObjectPropertyElementMain
    ) -> AudioObjectPropertyAddress {
        return AudioObjectPropertyAddress(
            mSelector: mSelector,
            mScope: mScope,
            mElement: mElement
        )
    }
    
    public static func getData(
        AudioDeviceID audioDeviceID: AudioDeviceID,
        Address propAddress: AudioObjectPropertyAddress,
        DataSize ioDataSize: UInt32,
        Data outData: UnsafeMutableRawPointer
    ) -> OSStatus {
        var address = propAddress
        var dataSize = ioDataSize
        
        return AudioObjectGetPropertyData(
            audioDeviceID,
            &address,
            0,
            nil,
            &dataSize,
            outData
        )
    }
    
    public static func setListener(
        mSelector: AudioObjectPropertySelector,
        DispatchQueue inDispatchQueue: dispatch_queue_t = deviceStateChangeQueue,
        listener: @escaping () -> Void
    ) {
        var address = createAudioObjectPropertyAddress(mSelector: mSelector)
        
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            inDispatchQueue,
            { (_: UInt32, _: UnsafePointer<AudioObjectPropertyAddress>) in
                listener()
            }
        )
    }
}
