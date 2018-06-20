//
//  ViewController.m
//  RPScreenRecorder
//
//  Created by Rhythmic Fistman on 20/6/18.
//  Copyright © 2018 Rhythmic Fistman. All rights reserved.
//

// https://stackoverflow.com/questions/50935432/rpscreenrecorder-startcapturewithhandler-not-returning-microphone-sound-in-samp

#import "ViewController.h"
#import <ReplayKit/ReplayKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@property (nonatomic) AVAssetWriter *writer;
@property (nonatomic) AVAssetWriterInput *input;
@property BOOL encounteredFirstBuffer;
@property BOOL writing;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
    NSURL *fileUrl = [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0] URLByAppendingPathComponent:@"output.m4a"];
    [NSFileManager.defaultManager removeItemAtURL:fileUrl error:nil];
    
    NSError *error;
    self.writer = [[AVAssetWriter alloc] initWithURL:fileUrl fileType:AVFileTypeAppleM4A error:&error];
    if (!self.writer) {
        NSLog(@"writer: %@", error);
        abort();
    }
    
    AudioChannelLayout acl = { 0 };
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    self.input = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:@{ AVFormatIDKey: @(kAudioFormatMPEG4AAC), AVSampleRateKey: @(44100),  AVChannelLayoutKey: [NSData dataWithBytes: &acl length: sizeof( acl ) ], AVEncoderBitRateKey: @(64000)}];
    
    [self.writer addInput:self.input];
    [self.writer startWriting];
    
    RPScreenRecorder *recorder = [RPScreenRecorder sharedRecorder];

    recorder.microphoneEnabled = YES;
    
    [self performSelector:@selector(stop) withObject:nil afterDelay:6];
    
    self.writing = YES;
    
    [recorder startCaptureWithHandler:^(CMSampleBufferRef sampleBuffer, RPSampleBufferType bufferType, NSError* error) {
        NSLog(@"Capture %@, %li, %@", sampleBuffer, (long)bufferType, error);
        
        // BAD racy
        if (RPSampleBufferTypeAudioMic == bufferType && self.writing) {
            if(!self.encounteredFirstBuffer) {
                [self.writer startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                self.encounteredFirstBuffer = YES;
            }
            [self.input appendSampleBuffer:sampleBuffer];
        }
    } completionHandler:^(NSError* error) {
        NSLog(@"startCapture: %@", error);
    }];
    recorder.microphoneEnabled = YES;

}

- (void)stop {
    self.writing = NO;
    [self.writer finishWritingWithCompletionHandler:^{
        NSLog(@"finish...!");
    }];
}

@end
