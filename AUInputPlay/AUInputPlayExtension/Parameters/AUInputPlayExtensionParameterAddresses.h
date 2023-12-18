//
//  AUInputPlayExtensionParameterAddresses.h
//  AUInputPlayExtension
//
//  Created by habi on 11/23/23.
//

#pragma once

#include <AudioToolbox/AUParameters.h>

#ifdef __cplusplus
namespace AUInputPlayExtensionParameterAddress {
#endif

typedef NS_ENUM(AUParameterAddress, AUInputPlayExtensionParameterAddress) {
    gain = 0
};

#ifdef __cplusplus
}
#endif
