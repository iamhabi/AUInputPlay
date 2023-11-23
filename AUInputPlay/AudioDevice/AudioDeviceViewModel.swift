//
//  AudioDeviceViewModel.swift
//  AUInputPlay
//
//  Created by habi on 11/23/23.
//

import Foundation

class AudioDeviceViewModel: ObservableObject {
    @Published var list: [AudioDevice] = []
    @Published var currentIndex: Int = 0
}
