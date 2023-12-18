//
//  AUIPAudioUnit.h
//  AUInputPlay
//
//  Created by habi on 12/18/23.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface AUIPAudioUnit : AUAudioUnit
- (void)setupParameterTree:(AUParameterTree *)parameterTree;
@end
