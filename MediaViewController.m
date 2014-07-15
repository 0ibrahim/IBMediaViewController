//
//  MediaViewController.m
//  NaatApp
//
//  Created by Ibrahim Sheikh on 11/09/2013.
//  Copyright (c) 2013 Ibrahim Sheikh. All rights reserved.
//

#import "MediaViewController.h"
#import "Naat.h"

@interface MediaViewController (){
    float mRestoreAfterScrubbingRate;
	BOOL seekToZeroBeforePlay;
	id mTimeObserver;
    BOOL repeatMode;
    BOOL shuffleMode;
    NSMutableArray *shuffleNaats;
}

@end

@implementation MediaViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self readyPlayer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)readyPlayer
{
    self.playing = NO;
    self.playButton.enabled = NO;
    //set up slider and label for seek
    
    NSError *error;
    if (self.currentSound){
        AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:self.currentSound.url];
        NSLog(@"%d - stats", mediaPlayer.currentItem.status);
        NSLog(@"%@", self.currentSound.url);
        [self.mScrubber setUserInteractionEnabled:YES];
        [mediaPlayer replaceCurrentItemWithPlayerItem:item];
        [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        NSLog(@"%d - stats", mediaPlayer.currentItem.status);
    } else{
        mediaPlayer = [[AVPlayer alloc] init];
        [self.mScrubber setUserInteractionEnabled:NO];
    }
    mediaPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    NSLog(@"%d - stats", mediaPlayer.currentItem.status);
    if (mediaPlayer == nil)
		NSLog(@"%@", error);
    
    [self.mScrubber setValue:0.0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[mediaPlayer currentItem]];
    
    NSLog(@"%d - stats", mediaPlayer.currentItem.status);
    
    NSLog(@"%d - sound.identifier", [(Sound *)self.currentSound identifier]);
}

- (IBAction)volumeSlider:(UISlider *)sender {

    MPMusicPlayerController *appMusic = [MPMusicPlayerController applicationMusicPlayer];
    appMusic.volume = sender.value;
}

- (void)setCurrentSound:(Sound *)currentSound
{
    _currentSound = currentSound;
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    appDelegate.bottomViewControllerNaat.label.text = currentSound.name;
    appDelegate.bottomViewControllerRadio.label.text = currentSound.name;
    [self readyPlayer];
}

- (IBAction)repeat:(UIButton *)sender {
    [self performSelector:@selector(doHighlight:) withObject:sender afterDelay:0];
}

- (void)doHighlight:(UIButton*)b {
    if (repeatMode == NO){
        repeatMode = YES;
        [b setHighlighted:YES];
        
        if (shuffleMode) {
            [self.shuffleButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
    } else if (repeatMode == YES){
        repeatMode = NO;
        [b setHighlighted:NO];
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    DetailViewController *detailViewController = appDelegate.detailViewController;
    UITableView *tableView = detailViewController.tableView;
    if (repeatMode == YES && shuffleMode == NO){
        [p seekToTime:kCMTimeZero];
    } else if (repeatMode == NO && shuffleMode == YES){
        if ([shuffleNaats count] == 0){
            shuffleNaats = [NSMutableArray arrayWithArray:detailViewController.naats];
            [shuffleNaats removeObjectIdenticalTo:self.currentSound];
        }
        // choose random element and play
        int rand = arc4random() % shuffleNaats.count;
        self.currentSound = shuffleNaats[rand];
        
        [shuffleNaats removeObjectAtIndex:rand];
        
        
        NSIndexPath *currentPath = [tableView indexPathForSelectedRow];
        
        int currentIndex = currentPath.row;
        int change = rand - currentIndex;
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:currentIndex + change inSection:currentPath.section];
        [tableView selectRowAtIndexPath:newIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        [detailViewController.tableView.delegate tableView:tableView didSelectRowAtIndexPath:newIndexPath];
        
    }
    else if (repeatMode == NO && shuffleMode == NO){
        [p seekToTime:kCMTimeZero];
        [mediaPlayer pause];
        [_playButton setImage:[UIImage imageNamed:@"play_icon.1.png"] forState:UIControlStateNormal];
        _playing = NO;
    }
}

- (IBAction)shuffle:(UIButton *)sender {
    [self performSelector:@selector(doHighlightShuffle:) withObject:sender afterDelay:0];
}

- (void)doHighlightShuffle:(UIButton*)b {
    if (shuffleMode == NO){
        shuffleMode = YES;
        [b setHighlighted:YES];
        if (repeatMode){
            [self.repeatButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
        // shuffle logic
        NSUInteger currentId = self.currentSound.identifier;
        AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
        DetailViewController *detailViewController = appDelegate.detailViewController;
        shuffleNaats = [NSMutableArray arrayWithArray:detailViewController.naats];
        
        if (currentId) {
            //remove current naat
            for (Naat *naat in shuffleNaats) {
                if (currentId == naat.identifier){
                    [shuffleNaats removeObject:naat];
                    break;
                }
            }
        }
        
    } else if (shuffleMode == YES){
        shuffleMode = NO;
        [b setHighlighted:NO];
        if (shuffleNaats){
            [shuffleNaats removeAllObjects];
        }
        
    }
}

- (IBAction)previous:(id)sender {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    DetailViewController *detailViewController = appDelegate.detailViewController;
    UITableView *tableView = detailViewController.tableView;
    
    NSIndexPath *currentPath = [tableView indexPathForSelectedRow];
    int currentIndex = currentPath.row;
    if (currentIndex == 0){
        //do nothing
    }
    else{
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:currentPath.row - 1 inSection:currentPath.section];
        [tableView selectRowAtIndexPath:newIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        [detailViewController.tableView.delegate tableView:tableView didSelectRowAtIndexPath:newIndexPath];
    }
}

- (IBAction)playPause:(id)sender {
    
    if (YES == seekToZeroBeforePlay)
	{
		seekToZeroBeforePlay = NO;
		[mediaPlayer seekToTime:kCMTimeZero];
	}
    
    if(_playing == NO){
        [mediaPlayer play];
        [_playButton setImage:[UIImage imageNamed:@"pause_icon.png"] forState:UIControlStateNormal];
        _playing = YES;
    }else {
        [mediaPlayer pause];
        [_playButton setImage:[UIImage imageNamed:@"play_icon.1.png"] forState:UIControlStateNormal];
        _playing = NO;
    }
    
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    BottomViewControllerNaat *bottomViewControllerNaat = appDelegate.bottomViewControllerNaat;
    [bottomViewControllerNaat syncButton];
    
    BottomViewControllerRadio *bottomViewControllerRadio = appDelegate.bottomViewControllerRadio;
    [bottomViewControllerRadio syncButton];
}

- (IBAction)next:(id)sender {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    DetailViewController *detailViewController = appDelegate.detailViewController;
    UITableView *tableView = detailViewController.tableView;
    NSMutableArray *naats = detailViewController.naats;
    
    NSIndexPath *currentPath = [tableView indexPathForSelectedRow];
    int currentIndex = currentPath.row;
    if (currentIndex == naats.count - 1){
        // do nothing
    }
    else{
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:currentPath.row + 1 inSection:currentPath.section];
        [tableView selectRowAtIndexPath:newIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        [detailViewController.tableView.delegate tableView:tableView didSelectRowAtIndexPath:newIndexPath];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (object == mediaPlayer.currentItem && [keyPath isEqualToString:@"status"]){
        
        if (mediaPlayer.currentItem.status == AVPlayerItemStatusReadyToPlay){
            self.playButton.enabled = YES;
            [self playPause:self.playButton];
            [self initScrubberTimer];
            NSLog(@"%d - stats", mediaPlayer.currentItem.status);
        }
        else if (mediaPlayer.currentItem.status == AVPlayerItemStatusFailed) {
            NSLog(@"%@", mediaPlayer.currentItem);
            NSLog(@"%d- status", mediaPlayer.currentItem.status);
            NSLog(@"Something went wrong!");
        }
    }
}

/* ---------------------------------------------------------
 **  Methods to handle manipulation of the movie scrubber control
 ** ------------------------------------------------------- */

/* Requests invocation of a given block during media playback to update the movie scrubber control. */
-(void)initScrubberTimer
{
	double interval = .1f;
	
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration))
	{
		return;
	}
	double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration))
	{
		CGFloat width = CGRectGetWidth([self.mScrubber bounds]);
		interval = 0.5f * duration / width;
	}
    
    //update maxLabel
    int minutes = duration/60;
    int seconds = duration - (minutes*60);
    if (seconds<10){
        self.maxLabel.text = [NSString stringWithFormat:@"%i:0%i ", minutes, seconds];
    } else{
        self.maxLabel.text = [NSString stringWithFormat:@"%i:%i ", minutes, seconds];
    }
    

    
    __weak typeof(self) weakSelf = self;
//    __weak typeof(mediaPlayer) weakMediaPlayer = mediaPlayer;
    
	/* Update the scrubber during normal playback. */
	mTimeObserver = [mediaPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                                queue:NULL /* If you pass NULL, the main queue is used. */
                                                          usingBlock:^(CMTime time){
                                                              [weakSelf syncScrubber];
                                                          }
                     ];
    //add events
    [_mScrubber addTarget:self action:@selector(endScrubbing:) forControlEvents:( UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
}

/* Set the scrubber based on the player current time. */
- (void)syncScrubber
{
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration))
	{
		_mScrubber.minimumValue = 0.0;
		return;
	}
    
	double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration))
	{
		float minValue = [self.mScrubber minimumValue];
		float maxValue = [self.mScrubber maximumValue];
		double time = CMTimeGetSeconds([mediaPlayer currentTime]);
        int minutes = time/60;
        int seconds = time - (minutes*60);
        
        if (seconds<10){
            self.playedLabel.text = [NSString stringWithFormat:@"%i:0%i ", minutes, seconds];
        } else{
            self.playedLabel.text = [NSString stringWithFormat:@"%i:%i ", minutes, seconds];
        }
		[self.mScrubber setValue:(maxValue - minValue) * time / duration + minValue];
	}
}

/* Set the player current time to match the scrubber position. */
- (IBAction)scrub:(id)sender
{
    if ([sender isKindOfClass:[UISlider class]])
	{
		UISlider* slider = sender;
		
		CMTime playerDuration = [self playerItemDuration];
		if (CMTIME_IS_INVALID(playerDuration)) {
			return;
		}
		
		double duration = CMTimeGetSeconds(playerDuration);
		if (isfinite(duration))
		{
			float minValue = [slider minimumValue];
			float maxValue = [slider maximumValue];
			float value = [slider value];
			
			double time = duration * (value - minValue) / (maxValue - minValue);
			
			[mediaPlayer seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
		}
	}
    _playing = YES;
    [self.playButton sendActionsForControlEvents:UIControlEventTouchUpInside];
}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (void)endScrubbing: (NSNotification *)notification
{
    CMTime playerDuration = [self playerItemDuration];
    double duration = CMTimeGetSeconds(playerDuration);
    if (!mTimeObserver)
	{
		if (CMTIME_IS_INVALID(playerDuration))
		{
			return;
		}
		
		if (isfinite(duration))
		{
			CGFloat width = CGRectGetWidth([self.mScrubber bounds]);
			double tolerance = 0.5f * duration / width;
            
            __weak typeof(self) weakSelf = self;
            
			mTimeObserver = [mediaPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time)
                              {
                                  [weakSelf syncScrubber];
                              }];
		}
	}
    
	if (mRestoreAfterScrubbingRate)
	{
		[mediaPlayer setRate:mRestoreAfterScrubbingRate];
		mRestoreAfterScrubbingRate = 0.f;
	}
    
    float minValue = [self.mScrubber minimumValue];
    float maxValue = [self.mScrubber maximumValue];
    float value = [self.mScrubber value];
    
    double time = duration * (value - minValue) / (maxValue - minValue);
    if (duration >= time) {
        _playing = NO;
        [self.playButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
    
    //play
//    _playing =NO;
//    [self.playButton sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (BOOL)isScrubbing
{
	return mRestoreAfterScrubbingRate != 0.f;
}

-(void)enableScrubber
{
    self.mScrubber.enabled = YES;
}

-(void)disableScrubber
{
    self.mScrubber.enabled = NO;    
}

- (CMTime)playerItemDuration
{
	if (mediaPlayer.currentItem.status == AVPlayerItemStatusReadyToPlay)
	{
        /*
         NOTE:
         Because of the dynamic nature of HTTP Live Streaming Media, the best practice
         for obtaining the duration of an AVPlayerItem object has changed in iOS 4.3.
         Prior to iOS 4.3, you would obtain the duration of a player item by fetching
         the value of the duration property of its associated AVAsset object. However,
         note that for HTTP Live Streaming Media the duration of a player item during
         any particular playback session may differ from the duration of its asset. For
         this reason a new key-value observable duration property has been defined on
         AVPlayerItem.
         
         See the AV Foundation Release Notes for iOS 4.3 for more information.
         */
        
		return([mediaPlayer.currentItem duration]);
	}
	
	return(kCMTimeInvalid);
}

-(void)removePlayerTimeObserver
{
	if (mTimeObserver)
	{
		[mediaPlayer removeTimeObserver:mTimeObserver];
		mTimeObserver = nil;
	}
}

-(void)pause{
    [mediaPlayer pause];
}

//- (void)playerItemDidReachEnd:(NSNotification *)notification
//{
//	/* After the movie has played to its end time, seek back to time zero
//     to play it again. */
//	
//}

@end
