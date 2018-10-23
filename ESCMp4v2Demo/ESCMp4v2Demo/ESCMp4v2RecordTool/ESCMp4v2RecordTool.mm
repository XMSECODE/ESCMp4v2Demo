//
//  ESCMp4v2Tool.m
//  ESCMp4v2Demo
//
//  Created by xiang on 2018/6/23.
//  Copyright © 2018年 xiang. All rights reserved.
//

#import "ESCMp4v2RecordTool.h"
#import "CMp4Encoder.h"

@interface ESCMp4v2RecordTool ()

@property(nonatomic,copy)NSString *fileName;

@property(nonatomic,assign)CMp4Encoder* mp4Encoder;

@property(nonatomic,assign)NSInteger audioFormat;

@property(nonatomic,assign)BOOL getPPSData;

@property(nonatomic,assign)BOOL getSPSData;

@property(nonatomic,assign)NSInteger videoFrameIndex;

@property(nonatomic,strong)NSData* ppsData;

@property(nonatomic,strong)NSData* spsData;

@property(nonatomic,assign)unsigned char* cPPSData;

@property(nonatomic,assign)int ppsDataLength;

@property(nonatomic,assign)unsigned char* cSPSData;

@property(nonatomic,assign)int spsLength;

@end

@implementation ESCMp4v2RecordTool

- (void)startRecordWithFilePath:(NSString *)filePath
                          Width:(NSInteger)width
                         height:(NSInteger)height
                      frameRate:(NSInteger)frameRate
                    audioFormat:(NSInteger)audioFormat
                audioSampleRate:(NSInteger)audioSampleRate
                   audioChannel:(int)audioChannel
             audioBitsPerSample:(int)audioBitsPerSample {
    const char *cFilePath = [filePath UTF8String];
    if (_mp4Encoder){
        delete _mp4Encoder;
    }
    _mp4Encoder = new CMp4Encoder((char*)cFilePath, (int)width, (int)height, (int)frameRate, (int)10000 / frameRate, (unsigned int)audioFormat, (unsigned int)audioSampleRate, audioChannel, audioBitsPerSample);
    self.audioFormat = audioFormat;
    self.fileName = filePath;
}

- (void)addVideoData:(NSData *)videoData {
    BYTE *frameBuf = (BYTE *)[videoData bytes];
    unsigned int length   = (unsigned int)[videoData length];
    if (_mp4Encoder) {
//        _mp4Encoder->WriteVideoTrack(frameBuf, length, &_cPPSData, &_ppsDataLength, &_cSPSData, &_spsLength);
//        int WriteVideoTrack(BYTE*,int);
        _mp4Encoder->WriteVideoTrack(frameBuf, length);

    }
//    NSLog(@"ppsdata === %d",self.ppsDataLength);
//    if (self.ppsDataLength > 0) {
//        if (self.getPPSData == NO) {
//            self.getPPSData = YES;
//            NSLog(@"获取到pps数据");
//            _mp4Encoder->WriteH264PPS(self.cPPSData, self.ppsDataLength);
//        }
//
//    }
//    if (self.spsLength > 0) {
//        if (self.getSPSData == NO) {
//            self.getSPSData = YES;
//            NSLog(@"获取到sps数据");
//            _mp4Encoder->WriteH264SPS(self.cSPSData, self.spsLength);
//        }
//    }
}

- (void)addAudioData:(NSData *)audioData timestamp:(NSInteger)timestamp {
    BYTE *frameBuf = (BYTE *)[audioData bytes];
    unsigned int length   = (unsigned int)[audioData length];
    if (_mp4Encoder) {
        _mp4Encoder->WriteAudioTrack(frameBuf,length,(unsigned int)timestamp);
    }
}

- (void)stopRecord {
    if (_mp4Encoder) {
        _mp4Encoder->CloseMp4Encoder();
        delete _mp4Encoder;
        _mp4Encoder = NULL;
    }
}

+ (BOOL)H264ToMp4WithH264FilePath:(NSString *)h264FilePath mp4FilePath:(NSString *)mp4FilePath width:(int)width height:(int)height frameRate:(int)frameRate{
    
    NSData *h264Data = [NSData dataWithContentsOfFile:h264FilePath];
    
    ESCMp4v2RecordTool *mp4v2Tool = [[ESCMp4v2RecordTool alloc] init];
    [mp4v2Tool startRecordWithFilePath:mp4FilePath Width:width height:height frameRate:frameRate audioFormat:0 audioSampleRate:0 audioChannel:0 audioBitsPerSample:0];
    
    uint8_t *videoData = (uint8_t*)[h264Data bytes];
    
    int j = 0;
    int lastJ = 0;
    void *pbuff = malloc(1080 * 2046 * 3 * 4);
    while (j < h264Data.length ) {
        if (videoData[j] == 0x00 &&
            videoData[j + 1] == 0x00 &&
            videoData[j + 2] == 0x00 &&
            videoData[j + 3] == 0x01) {
            if (j > 0) {
                int frame_size = j - lastJ;
                memcpy(pbuff, &videoData[lastJ], frame_size);
                NSData *buff = [NSData dataWithBytes:pbuff length:frame_size];
                lastJ = j;
                [mp4v2Tool addVideoData:buff];
            }else if (j == h264Data.length - 1) {
                int frame_size = j - lastJ;
                memcpy(pbuff, &videoData[lastJ], frame_size);
                NSData *buff = [NSData dataWithBytes:pbuff length:frame_size];
                lastJ = j;
                [mp4v2Tool addVideoData:buff];
            }
        }
        j++;
    }
    free(pbuff);
    NSLog(@"完成");
    [mp4v2Tool stopRecord];
    return YES;
}

/**
 H264文件和AAC文件转MP4
 */
+ (BOOL)H264AndAACToMp4WithH264FilePath:(NSString *)h264FilePath aacFilePath:(NSString *)aacFilePath  mp4FilePath:(NSString *)mp4FilePath width:(int)width height:(int)height frameRate:(int)frameRate audioSampleRate:(NSInteger)audioSampleRate {
    
    
    NSData *h264Data = [NSData dataWithContentsOfFile:h264FilePath];
    NSData *aacData = [NSData dataWithContentsOfFile:aacFilePath];
    
    ESCMp4v2RecordTool *mp4v2Tool = [[ESCMp4v2RecordTool alloc] init];
    [mp4v2Tool startRecordWithFilePath:mp4FilePath Width:width height:height frameRate:frameRate audioFormat:WAVE_FORMAT_AAC audioSampleRate:audioSampleRate audioChannel:1 audioBitsPerSample:16];
    
    uint8_t *videoData = (uint8_t*)[h264Data bytes];
    
    int j = 0;
    int lastJ = 0;
    void *pbuff = malloc(1080 * 2016 * 3 * 4);
    while (j < h264Data.length ) {
        if (videoData[j] == 0x00 &&
            videoData[j + 1] == 0x00 &&
            videoData[j + 2] == 0x00 &&
            videoData[j + 3] == 0x01) {
            if (j > 0) {
                int frame_size = j - lastJ;
                memcpy(pbuff, &videoData[lastJ], frame_size);
                NSData *buff = [NSData dataWithBytes:pbuff length:frame_size];
                lastJ = j;
                [mp4v2Tool addVideoData:buff];
            }else if (j == h264Data.length - 1) {
                int frame_size = j - lastJ;
                memcpy(pbuff, &videoData[lastJ], frame_size);
                NSData *buff = [NSData dataWithBytes:pbuff length:frame_size];
                lastJ = j;
                [mp4v2Tool addVideoData:buff];
            }
        }
        j++;
    }
    
    uint8_t *voiceData = (uint8_t*)[aacData bytes];
    j = 0;
    lastJ = 0;
    while (j < aacData.length) {
        //44100
        //2
        //2
        //fff1 5080 3c
        if (voiceData[j] == 0xff &&
            voiceData[j + 1] == 0xf1 &&
            voiceData[j + 2] == 0x6c) {
            if (j > 0) {
                int frame_size = j - lastJ;
                memcpy(pbuff, &voiceData[lastJ], frame_size);
                NSData *buff = [NSData dataWithBytes:pbuff length:frame_size];
//                NSLog(@"%@",buff);
                lastJ = j;
                [mp4v2Tool addAudioData:buff timestamp:0];
            }
        }
        j++;
    }
    free(pbuff);
    NSLog(@"完成");
    [mp4v2Tool stopRecord];
    return YES;
    
    
    
    return YES;
}

@end
