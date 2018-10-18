# XHAVPlayer
AVPlayer 实践篇。
因为一直没有一个专门做视频的项目来具体真正实践AVPlayer这块知识，算是拾补遗漏的知识吧，我想也可以给还没入门的你做一个好的开始。

#AVPlayer的组成？

AVPlayer:控制播放器的播放,暂停,播放速度 
AVURLAsset : AVAsset 的一个子类,使用 URL 进行实例化,实例化对象包换 URL 对应视频资源的所有信息。 
AVPlayerItem:管理资源对象,提供播放数据源 
AVPlayerLayer:负责显示视频,如果没有添加该类,只有声音没有画面 
然后再加上一些通知，就足够做一个可以用的简单播放器了。

#如何搞一个能看得的见摸得着的播放器？
通过构造可以看出需要  AVPlayerLayer AVPlayer  AVPlayerItem 这三个相互结合才能看到。
```
    self.avPlayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    UIView *bgView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 300)];
    bgView.backgroundColor = [UIColor blueColor];
    [self.view addSubview:bgView];
    
    [bgView.layer addSublayer:self.avPlayer];
    self.avPlayer.frame = bgView.bounds;
    
    AVPlayerItem *item = [[AVPlayerItem alloc]initWithURL:[NSURL    URLWithString:@"http://flv3.bn.netease.com/videolib3/1604/14/LSwHa2712/SD/LSwHa2712-mobile.mp4"]];
    self.currentItem = item;
    [self.player replaceCurrentItemWithPlayerItem:self.currentItem];

-(AVPlayer *)player{
    if (!_player) {
        _player = [[AVPlayer alloc]init];
    }
    return _player;
}
```
#视频播放器能看得见了，但是怎么控制呢？
##status 
可以根据这个状态来控制播放器的播放。
```
    [self.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{ 
if ([object isKindOfClass:[AVPlayerItem class]]) { 
if ([keyPath isEqualToString:@"status"]) { 
switch (_playerItem.status) { 
case AVPlayerItemStatusReadyToPlay:   
//推荐将视频播放放在这里 
[self play]; 
break; 
case AVPlayerItemStatusUnknown: 
NSLog(@"AVPlayerItemStatusUnknown"); 
break; 
case AVPlayerItemStatusFailed: 
NSLog(@"AVPlayerItemStatusFailed") 
break; 
default: 
break; 
} 
} 
}
```
##CMTime
这个是视频相关的信息，如视频的总时间，视频的当前播放时间 都与这个有关。
```
typedef struct{ 
CMTimeValue value; // 帧数 
CMTimeScale timescale; // 帧率(影片每秒有几帧) 
CMTimeFlags flags; 
CMTimeEpoch epoch; 
} CMTime; 
```
我们在项目中，总是会有一种需求那就是获取当前的播放时间，这个其实很好办，系统有个回调函数
```
- (id)addPeriodicTimeObserverForInterval:(CMTime)interval queue:(nullable dispatch_queue_t)queue usingBlock:(void (^)(CMTime time))block; 

方法名如其意, “添加周期时间观察者” ,参数1 interal 为CMTime 类型的,参数2 queue为串行队列,如果传入NULL就是默认主线程,参数3 为CMTime 的block类型。
简而言之就是,每隔一段时间后执行 block。
比如:我们把interval设置成CMTimeMake(1, 10),在block里面刷新label,就是一秒钟刷新10次。
```
```
[self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:nil usingBlock:^(CMTime time) { 

AVPlayerItem *item = WeakSelf.playerItem; 
NSInteger currentTime = item.currentTime.value/item.currentTime.timescale; 
NSLog(@"当前播放时间:%ld",currentTime); 
}]; 
```
##缓存相关
loadedTimeRange 缓存时间 
获取视频的缓存情况我们需要监听playerItem的loadedTimeRanges属性 KVO,这样我们可以通过获取的数值来实现相关的ui。
```
[self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil]; 

if ([keyPath isEqualToString:@"loadedTimeRanges"]){ 
NSArray *array = _playerItem.loadedTimeRanges; 
CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围 
float startSeconds = CMTimeGetSeconds(timeRange.start); 
float durationSeconds = CMTimeGetSeconds(timeRange.duration); 
NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度 
NSLog(@"当前缓冲时间:%f",totalBuffer); 
} 
```
##playbackBufferEmpty 
监听playbackBufferEmpty我们可以获取当缓存不够,视频加载不出来的情况:


[self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil]; 

在KVO回调里:


if ([keyPath isEqualToString:@"playbackBufferEmpty"]) { 

//some code show loading 
} 

##playbackLikelyToKeepUp 

playbackLikelyToKeepUp和playbackBufferEmpty是一对,用于监听缓存足够播放的状态
[self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil]; 
/* ... */ 
if([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) { 
//由于 AVPlayer 缓存不足就会自动暂停,所以缓存充足了需要手动播放,才能继续播放 
[_player play]; 
} 

#项目中可能会遇到的问题。

项目中肯定会遇到滑动滑块的需求吧！滑动滑块来改变时间改变播放 
```
    [self.slideView addTarget:self action:@selector(SliderEndChangeValue:) forControlEvents:UIControlEventValueChanged];
    [self.slideView addTarget:self action:@selector(startSlider) forControlEvents:UIControlEventTouchDown];
    [self.slideView addTarget:self action:@selector(endSlider) forControlEvents:UIControlEventTouchUpInside];
```
```
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
```
