//
//  ViewController.m
//  XHAVPlyer
//
//  Created by 信昊 on 2018/10/16.
//  Copyright © 2018年 信昊. All rights reserved.
//

#import "ViewController.h"
#import <AVKit/AVKit.h>
#define SCREEN_WIDTH self.view.bounds.size.width
#define SCREEN_HEIGHT self.view.bounds.size.height
@interface ViewController ()

@property(nonatomic,strong)AVPlayer *player;

@property(nonatomic,strong)AVPlayerLayer *avPlayer;

@property(nonatomic,strong)AVPlayerItem *currentItem;

@property(nonatomic,strong)UISlider *slideView;

@property(nonatomic,strong)UILabel *showLabel;

@property(nonatomic,strong)NSTimer *showTimer;

@property(nonatomic,strong)NSTimer *progressTimer;

@property(nonatomic,strong)UIButton *pasuseBtn;
/* 工具栏展示的时间 */
@property (assign, nonatomic) NSTimeInterval showTime;

@end
//http://flv3.bn.netease.com/videolib3/1604/14/LSwHa2712/SD/LSwHa2712-mobile.mp4
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
    [self blockUI];
    // Do any additional setup after loading the view, typically from a nib.
}
-(void)initUI{
    
    self.avPlayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    
    UIView *bgView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 300)];
    bgView.backgroundColor = [UIColor blueColor];
    [self.view addSubview:bgView];
    
    [bgView.layer addSublayer:self.avPlayer];
    self.avPlayer.frame = bgView.bounds;
    
    AVPlayerItem *item = [[AVPlayerItem alloc]initWithURL:[NSURL URLWithString:@"http://flv3.bn.netease.com/videolib3/1604/14/LSwHa2712/SD/LSwHa2712-mobile.mp4"]];
    self.currentItem = item;
    [self.player replaceCurrentItemWithPlayerItem:self.currentItem];

    
    UISlider *slide = [[UISlider alloc]initWithFrame:CGRectMake(10, 400, 300, 50)];
    [self.view addSubview:slide];
    self.slideView = slide;
    [self.slideView addTarget:self action:@selector(SliderEndChangeValue:) forControlEvents:UIControlEventValueChanged];
    [self.slideView addTarget:self action:@selector(startSlider) forControlEvents:UIControlEventTouchDown];
    [self.slideView addTarget:self action:@selector(endSlider) forControlEvents:UIControlEventTouchUpInside];
    self.slideView.maximumValue = 1;
    self.slideView.minimumValue = 0;
//    self.slideView.
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(10, 450, 300, 30)];
    label.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:label];
    self.showLabel = label;
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"开始" forState:UIControlStateNormal];
    [btn setTitle:@"暂停" forState:UIControlStateSelected];
    [btn setTintColor:[UIColor blueColor]];
    [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.view addSubview:btn];
    self.pasuseBtn = btn;
    self.pasuseBtn.frame = CGRectMake(10, 500, 100, 30);
    [self.pasuseBtn addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    
}
-(void)blockUI{
    [self.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    __weak typeof(self)weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:nil usingBlock:^(CMTime time) {
        
        AVPlayerItem *item = weakSelf.currentItem;
        NSInteger currentTime = item.currentTime.value/item.currentTime.timescale;
        NSLog(@"当前播放时间:%ld",currentTime);
    }];
    [self.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [self.currentItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [self.currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark -- pasusebtn
-(void)click{
    self.pasuseBtn.selected = !self.pasuseBtn.selected;

    if (self.pasuseBtn.selected == YES) {
        [self.player play];
        [self addShowTimer];
        [self addProgressTimer];
    } else {
        [self.player pause];
        [self removeShowTimer];
        [self removeProgressTimer];
     
    }
}
#pragma mark - 观察者对应的方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (AVPlayerItemStatusReadyToPlay == status) {
            NSLog(@"ready");
//            [self.player play];
//            [self removeProgressTimer];
//            [self addProgressTimer];
        } else {
            
            NSLog(@"no");
        }
    }
    if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSArray *array = self.currentItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        NSLog(@"当前缓冲时间:%f",totalBuffer);
 
    }
    if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        
        //some code show loading
        
    }
    if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        
    }
}
#pragma mark -- slidechange
-(void)SliderEndChangeValue:(id)sender{//滑动
    NSLog(@"%lf",self.slideView.value);
    [self removeProgressTimer];
    [self removeShowTimer];
    if (self.slideView.value == 1) {
        self.slideView.value = 0;
    }
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentItem.duration) * self.slideView.value;
    NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
    self.showLabel.text = [self stringWithCurrentTime:currentTime duration:duration];
    [self addShowTimer];
//    [self addProgressTimer];
}
-(void)startSlider{//开始滑动
    [self removeProgressTimer];
}
-(void)endSlider{//停止滑动
    [self addProgressTimer];
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentItem.duration) * self.slideView.value;
    [self.player seekToTime:CMTimeMakeWithSeconds(currentTime, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}
#pragma mark - 定时器操作
- (void)addProgressTimer
{
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateProgressInfo) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.progressTimer forMode:NSRunLoopCommonModes];
}

- (void)removeProgressTimer
{
    [self.progressTimer invalidate];
    self.progressTimer = nil;
}

- (void)updateProgressInfo
{
    // 1.更新时间
    self.showLabel.text = [self timeString];
    
    self.slideView.value = CMTimeGetSeconds(self.player.currentTime) / CMTimeGetSeconds(self.player.currentItem.duration);
    
    if(self.slideView.value == 1)
    {
        self.slideView.value = 0;
        self.slideView.tag = 100;

        self.player = nil;

        [self removeProgressTimer];
        [self removeShowTimer];
        self.showLabel.text = @"00:00/00:00";
        return;
        
    }
    
}
- (void)addShowTimer
{
    self.showTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateShowTime) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.showTimer forMode:NSRunLoopCommonModes];
}
- (void)updateShowTime
{
    self.showTime += 1;
    
    if (self.showTime > 2.0) {
    
        [self removeShowTimer];
        
        self.showTime = 0;
    }
}

- (void)removeShowTimer
{
    [self.showTimer invalidate];
    self.showTimer = nil;
}

- (NSString *)timeString
{
    NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentTime);
    //    if (self.player == nil) {
    //        return @"00:00/00:00";
    //    }
    return [self stringWithCurrentTime:currentTime duration:duration];
}
- (NSString *)stringWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration
{
    //    if (currentTime == duration) {
    //        currentTime = 0;
    //
    ////        self.player.currentTime = currentTime;
    ////        [self updateProgressInfo];
    ////        [self sliderValueChange];
    ////        self.progressSlider.value = 0;
    //        self.playOrPauseBtn.selected = NO;
    //        self.toolView.alpha = 1;
    //
    //        [self removeProgressTimer];
    //        [self removeShowTimer];
    //        self.player = nil;
    //
    //    }
    NSInteger dMin = duration / 60;
    NSInteger dSec = (NSInteger)duration % 60;
    
    NSInteger cMin = currentTime / 60;
    NSInteger cSec = (NSInteger)currentTime % 60;
    
    NSString *durationString = [NSString stringWithFormat:@"%02ld:%02ld", dMin, dSec];
    NSString *currentString = [NSString stringWithFormat:@"%02ld:%02ld", cMin, cSec];
    
    return [NSString stringWithFormat:@"%@/%@", currentString, durationString];
}

-(AVPlayer *)player{
    if (!_player) {
        _player = [[AVPlayer alloc]init];
        
    }
    return _player;
}

@end
