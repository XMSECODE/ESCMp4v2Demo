//
//  ViewController.m
//  ESCRecordMP4Demo
//
//  Created by xiang on 2018/6/23.
//  Copyright © 2018年 xiang. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "ESCMp4v2RecordTool.h"

#define NAL_SLICE_IDR 5


typedef struct _NaluUnit
{
    int type; //IDR or INTER：note：SequenceHeader is IDR too
    int size; //note: don't contain startCode
    unsigned char *data; //note: don't contain startCode
} NaluUnit;

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>

@property(nonatomic,strong)AVCaptureSession* captureSession;

@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;

@property(nonatomic,strong)AVCaptureAudioDataOutput *audioDataOutput;

@property(nonatomic,strong)dispatch_queue_t videoAndAudioDataOutputQueue;

@property(nonatomic,assign)BOOL isRecording;

@property(nonatomic,strong)NSDateFormatter* dateFormatter;

@property(nonatomic,strong)ESCMp4v2RecordTool* mp4v2RecordTool;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self writMP4ForH264];
    
}

- (void)writMP4ForH264 {
    
    NSString *h264FilePath = [[NSBundle mainBundle] pathForResource:@"video3.h264" ofType:nil];
    
    NSString *mp4FilePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    mp4FilePath = [NSString stringWithFormat:@"%@/videot.mp4",mp4FilePath];
    
    int width = 1280;
    int height = 720;
    int frameRate = 25;
    
    [ESCMp4v2RecordTool H264ToMp4:h264FilePath mp4FilePath:mp4FilePath width:width height:height frameRate:frameRate];
}

@end
