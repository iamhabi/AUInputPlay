//
//  AUInputPlayExtensionAudioUnit.h
//  AUInputPlayExtension
//
//  Created by habi on 11/23/23.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface AUInputPlayExtensionAudioUnit : AUAudioUnit
- (void)setupParameterTree:(AUParameterTree *)parameterTree;
@end
