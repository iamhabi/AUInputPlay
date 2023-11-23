//
//  AUInputPlayExtensionMainView.swift
//  AUInputPlayExtension
//
//  Created by habi on 11/23/23.
//

import SwiftUI

struct AUInputPlayExtensionMainView: View {
    var parameterTree: ObservableAUParameterGroup
    
    var body: some View {
        ParameterSlider(param: parameterTree.global.gain)
    }
}
