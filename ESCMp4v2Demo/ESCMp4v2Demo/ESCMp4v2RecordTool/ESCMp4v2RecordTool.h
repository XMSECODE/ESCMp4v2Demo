//
//  ESCMp4v2Tool.h
//  ESCMp4v2Demo
//
//  Created by xiang on 2018/6/23.
//  Copyright © 2018年 xiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESCMp4v2RecordTool : NSObject

- (void)startRecordWithFilePath:(NSString *)filePath
                          Width:(NSInteger)width
                         height:(NSInteger)height
                      frameRate:(NSInteger)frameRate
                    audioFormat:(NSInteger)audioFormat
                audioSampleRate:(NSInteger)audioSampleRate;

- (void)addVideoData:(NSData *)videoData;

- (void)addAudioData:(NSData *)audioData timestamp:(NSInteger)timestamp;

- (void)stopRecord;

+ (BOOL)H264ToMp4:(NSString *)h264FilePath mp4FilePath:(NSString *)mp4FilePath width:(int)width height:(int)height frameRate:(int)frameRate;

@end
