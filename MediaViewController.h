//
//  MediaViewController.h
//  NaatApp
//
//  Created by Ibrahim Sheikh on 11/09/2013.
//  Copyright (c) 2013 Ibrahim Sheikh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CoreMedia/CoreMedia.h>

#import "AppDelegate.h"
#import "ViewController.h"
#import "DetailViewController.h"
#import "Artist.h"
#import "Sound.h"

@interface MediaViewController : UIViewController
{
    AVPlayer *mediaPlayer;
}
@property (weak, nonatomic) IBOutlet UILabel *playedLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxLabel;
@property (weak, nonatomic) IBOutlet UISlider *mScrubber;

@property BOOL playing;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *repeatButton;
@property (weak, nonatomic) IBOutlet UIButton *shuffleButton;

@property (strong, nonatomic) Sound *currentSound;

- (void)readyPlayer;
- (void)pause;
- (IBAction)volumeSlider:(UISlider *)sender;
- (IBAction)repeat:(id)sender;
- (IBAction)shuffle:(id)sender;
- (IBAction)previous:(id)sender;
- (IBAction)playPause:(id)sender;
- (IBAction)next:(id)sender;


@end
