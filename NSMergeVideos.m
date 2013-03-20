#import "AVCamCaptureManager.h"
#import "AVCamRecorder.h"
#import <AVFoundation/AVFoundation.h>

- (void)MergeAndSave
{
  AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
   
   NSMutableArray *arrayInstruction = [[NSMutableArray alloc] init];
   
	AVMutableVideoCompositionInstruction * MainInstruction =
	[AVMutableVideoCompositionInstruction videoCompositionInstruction];
   AVMutableCompositionTrack *audioTrack;
   if(self.isSoundOn==YES)
		audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
											preferredTrackID:kCMPersistentTrackID_Invalid];
	
	CMTime duration = kCMTimeZero;
	for(int i=0;i<=self.numberOfFile;i++)
		{
			AVAsset *currentAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@%d%@", NSTemporaryDirectory(), @"Movie",i,@".mov"]]];
			//VIDEO TRACK
			AVMutableCompositionTrack *currentTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
			[currentTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, currentAsset.duration) ofTrack:[[currentAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:duration error:nil];
		if(self.isSoundOn==YES)
			[audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, currentAsset.duration) ofTrack:[[currentAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:duration error:nil];
		//FIXING ORIENTATION//
		AVMutableVideoCompositionLayerInstruction *currentAssetLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:currentTrack];
		AVAssetTrack *currentAssetTrack = [[currentAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
		UIImageOrientation currentAssetOrientation  = UIImageOrientationUp;
		BOOL  isCurrentAssetPortrait  = NO;
		CGAffineTransform currentTransform = currentAssetTrack.preferredTransform;
		if(currentTransform.a == 0 && currentTransform.b == 1.0 && currentTransform.c == -1.0 && currentTransform.d == 0)  {currentAssetOrientation= UIImageOrientationRight; isCurrentAssetPortrait = YES;}
		if(currentTransform.a == 0 && currentTransform.b == -1.0 && currentTransform.c == 1.0 && currentTransform.d == 0)  {currentAssetOrientation =  UIImageOrientationLeft; isCurrentAssetPortrait = YES;}
		if(currentTransform.a == 1.0 && currentTransform.b == 0 && currentTransform.c == 0 && currentTransform.d == 1.0)   {currentAssetOrientation =  UIImageOrientationUp;}
		if(currentTransform.a == -1.0 && currentTransform.b == 0 && currentTransform.c == 0 && currentTransform.d == -1.0) {currentAssetOrientation = UIImageOrientationDown;}
		CGFloat FirstAssetScaleToFitRatio = 320.0/currentAssetTrack.naturalSize.width;
		if(isCurrentAssetPortrait){
			FirstAssetScaleToFitRatio = 320.0/currentAssetTrack.naturalSize.height;
			CGAffineTransform FirstAssetScaleFactor = CGAffineTransformMakeScale(FirstAssetScaleToFitRatio,FirstAssetScaleToFitRatio);
			[currentAssetLayerInstruction setTransform:CGAffineTransformConcat(currentAssetTrack.preferredTransform, FirstAssetScaleFactor) atTime:duration];
		}else{
			CGAffineTransform FirstAssetScaleFactor = CGAffineTransformMakeScale(FirstAssetScaleToFitRatio,FirstAssetScaleToFitRatio);
			[currentAssetLayerInstruction setTransform:CGAffineTransformConcat(CGAffineTransformConcat(currentAssetTrack.preferredTransform, FirstAssetScaleFactor),CGAffineTransformMakeTranslation(0, 160.0)) atTime:duration];
		}
		duration=CMTimeAdd(duration, currentAsset.duration);
		[currentAssetLayerInstruction setOpacity:0.0 atTime:duration];
			[arrayInstruction addObject:currentAssetLayerInstruction];
		//duration=CMTimeAdd(duration, currentAsset.duration);
			NSLog(@"%lld", duration.value/duration.timescale);
		}
		MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, duration);
		MainInstruction.layerInstructions = arrayInstruction;
		AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
		MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
		MainCompositionInst.frameDuration = CMTimeMake(1, 30);
		MainCompositionInst.renderSize = CGSizeMake(320.0, 480.0);
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"mergeVideo-%d.mov",arc4random() % 1000]];
		
		NSURL *url = [NSURL fileURLWithPath:myPathDocs];
		
		NSString *quality = AVAssetExportPresetHighestQuality;
		if(self.isHighQuality==NO)
		quality = AVAssetExportPresetMediumQuality;
		AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:quality];
		exporter.outputURL=url;
		exporter.outputFileType = AVFileTypeQuickTimeMovie;
		exporter.videoComposition = MainCompositionInst;
		exporter.shouldOptimizeForNetworkUse = YES;
		[exporter exportAsynchronouslyWithCompletionHandler:^
		 {
		 switch (exporter.status)
			 {
				 case AVAssetExportSessionStatusCompleted:
				 {
					 NSFileManager *FM = [[NSFileManager alloc] init];
					 NSArray *files = [FM contentsOfDirectoryAtPath:NSTemporaryDirectory() error:nil];
					 for(NSString *file in files)
						 {
						 	NSString *pathTemporaryPath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file];
						 	[FM removeItemAtPath:pathTemporaryPath error:nil];
						 }
				 [[self captureManager].session stopRunning];
				 [[self captureManager] stopRecording];
				 NSMutableDictionary *usInfo=[NSMutableDictionary dictionary];
				 [usInfo setObject:myPathDocs forKey:@"path"];
				 [usInfo setObject:[NSNumber numberWithInt:0] forKey:@"type"];
				 [usInfo setObject:@"1" forKey:@"Testimonials.isPostController"];
				 [[NSNotificationCenter defaultCenter] postNotificationName:@"Testimonials.onAddPostView" object:nil userInfo:usInfo];
				 	NSLog(@"Completed exporting!");
				 }
				 break;
				 case AVAssetExportSessionStatusFailed:
				 NSLog(@"Failed:%@", exporter.error.description);
				 break;
				 case AVAssetExportSessionStatusCancelled:
				 NSLog(@"Canceled:%@", exporter.error);
				 break;
				 case AVAssetExportSessionStatusExporting:
				 NSLog(@"Exporting!");
				 break;
				 case AVAssetExportSessionStatusWaiting:
				 NSLog(@"Waiting");
				 break;
				 default:
				 break;
			 }
		 }];
}
