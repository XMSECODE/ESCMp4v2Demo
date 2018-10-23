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
                audioSampleRate:(NSInteger)audioSampleRate
                   audioChannel:(int)audioChannel
             audioBitsPerSample:(int)audioBitsPerSample;

- (void)addVideoData:(NSData *)videoData;

- (void)addAudioData:(NSData *)audioData timestamp:(NSInteger)timestamp;

- (void)stopRecord;

/**
 H264文件转MP4
 */
+ (BOOL)H264ToMp4WithH264FilePath:(NSString *)h264FilePath mp4FilePath:(NSString *)mp4FilePath width:(int)width height:(int)height frameRate:(int)frameRate;

/**
 H264文件和AAC文件转MP4
 */
+ (BOOL)H264AndAACToMp4WithH264FilePath:(NSString *)h264FilePath aacFilePath:(NSString *)aacFilePath  mp4FilePath:(NSString *)mp4FilePath width:(int)width height:(int)height frameRate:(int)frameRate audioSampleRate:(NSInteger)audioSampleRate;

@end
