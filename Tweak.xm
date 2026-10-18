#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#define kPrefBundle @"com.yourname.splitscreentweak.prefs"

// 全局配置
@interface SPSplitScreenManager : NSObject
@property (nonatomic, assign) BOOL tweakEnabled;
@property (nonatomic, assign) NSInteger triggerCorner;
@property (nonatomic, assign) NSInteger splitRatio;
@property (nonatomic, strong) NSMutableArray *floatingWindows;
@property (nonatomic, strong) UIWindow *splitWindow;
+ (instancetype)sharedInstance;
- (void)loadPrefs;
- (void)showSplitScreenAtPoint:(CGPoint)point;
- (void)dismissSplitScreen;
- (void)pinSplitScreenToSide;
@end

static SPSplitScreenManager *manager = nil;

@implementation SPSplitScreenManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SPSplitScreenManager alloc] init];
        manager.floatingWindows = [NSMutableArray array];
    });
    return manager;
}

- (void)loadPrefs {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kPrefBundle];
    self.tweakEnabled = [defaults boolForKey:@"tweakEnabled"];
    self.triggerCorner = [defaults integerForKey:@"triggerCorner"];
    self.splitRatio = [defaults integerForKey:@"splitRatio"];
    if (![defaults boolForKey:@"tweakEnabled"]) {
        self.tweakEnabled = YES;
        self.triggerCorner = 0;
        self.splitRatio = 0;
    }
}

- (CGFloat)ratioForType:(NSInteger)type {
    switch (type) {
        case 1: return 16.0/9.0;
        case 2: return 5.0/3.0;
        case 3: return 4.0/3.0;
        case 4: return 1.0;
        default: return 0.45;
    }
}

- (void)showSplitScreenAtPoint:(CGPoint)point {
    if (!self.tweakEnabled) return;

    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat width = screenBounds.size.width * [self ratioForType:self.splitRatio];
    CGFloat height = screenBounds.size.height * 0.6;

    self.splitWindow = [[UIWindow alloc] initWithFrame:CGRectMake(
        screenBounds.size.width - width,
        screenBounds.size.height - height,
        width,
        height
    )];
    self.splitWindow.windowLevel = UIWindowLevelAlert + 1;
    self.splitWindow.backgroundColor = [UIColor systemBackgroundColor];
    self.splitWindow.layer.cornerRadius = 16;
    self.splitWindow.layer.masksToBounds = YES;

    UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.splitWindow.bounds.size.width, 40)];
    topBar.backgroundColor = [UIColor tertiarySystemBackgroundColor];
    UITapGestureRecognizer *topTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTopTap)];
    [topBar addGestureRecognizer:topTap];
    [self.splitWindow addSubview:topBar];

    UIView *leftEdge = [[UIView alloc] initWithFrame:CGRectMake(0, 40, 20, self.splitWindow.bounds.size.height-40)];
    UITapGestureRecognizer *leftTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleEdgeTap)];
    [leftEdge addGestureRecognizer:leftTap];
    [self.splitWindow addSubview:leftEdge];

    UIView *bottomEdge = [[UIView alloc] initWithFrame:CGRectMake(0, self.splitWindow.bounds.size.height-20, self.splitWindow.bounds.size.width, 20)];
    UITapGestureRecognizer *bottomTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleEdgeTap)];
    [bottomEdge addGestureRecognizer:bottomTap];
    [self.splitWindow addSubview:bottomEdge];

    UIView *resizeHandle = [[UIView alloc] initWithFrame:CGRectMake(self.splitWindow.bounds.size.width-30, self.splitWindow.bounds.size.height-30, 30, 30)];
    UIPanGestureRecognizer *resizePan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleResizePan:)];
    [resizeHandle addGestureRecognizer:resizePan];
    [self.splitWindow addSubview:resizeHandle];

    [self.splitWindow makeKeyAndVisible];
}

- (void)handleTopTap {
    [UIView animateWithDuration:0.3 animations:^{
        self.splitWindow.frame = [UIScreen mainScreen].bounds;
    }];
}

- (void)handleEdgeTap {
    [self pinSplitScreenToSide];
}

- (void)dismissSplitScreen {
    [self.splitWindow setHidden:YES];
    self.splitWindow = nil;
}

- (void)pinSplitScreenToSide {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGRect pinFrame = CGRectMake(screenBounds.size.width - 30, 200, 30, 80);

    UIWindow *pinWindow = [[UIWindow alloc] initWithFrame:pinFrame];
    pinWindow.windowLevel = UIWindowLevelAlert + 2;
    pinWindow.backgroundColor = [UIColor clearColor];

    UIView *pinView = [[UIView alloc] initWithFrame:pinFrame];
    pinView.backgroundColor = [UIColor systemBlueColor];
    pinView.layer.cornerRadius = 8;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(restoreFromPin:)];
    [pinView addGestureRecognizer:tap];

    [pinWindow addSubview:pinView];
    [pinWindow makeKeyAndVisible];

    [self.floatingWindows addObject:pinWindow];
    [self.splitWindow setHidden:YES];
}

- (void)restoreFromPin:(UITapGestureRecognizer *)tap {
    [tap.view.superview removeFromSuperview];
    [self.floatingWindows removeObject:tap.view.superview];
    [self.splitWindow setHidden:NO];
}

- (void)handleResizePan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.splitWindow];
    CGRect frame = self.splitWindow.frame;
    frame.size.width = MAX(200, frame.size.width + translation.x);
    frame.size.height = MAX(300, frame.size.height + translation.y);
    frame.origin.x = [UIScreen mainScreen].bounds.size.width - frame.size.width;
    frame.origin.y = [UIScreen mainScreen].bounds.size.height - frame.size.height;
    self.splitWindow.frame = frame;
    [pan setTranslation:CGPointZero inView:self.splitWindow];
}

@end

// Hook SpringBoard 触摸事件
%hook SpringBoard

- (void)sendEvent:(UIEvent *)event {
    %orig;

    NSSet *touches = [event allTouches];
    if (touches.count != 1) return;

    UITouch *touch = [touches anyObject];
    if (touch.phase != UITouchPhaseBegan) return;

    UIView *view = (UIView *)touch.view;
    if (!view) return;

    CGPoint point = [touch locationInView:view.window];
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat edgeSize = 60;

    SPSplitScreenManager *mgr = [SPSplitScreenManager sharedInstance];
    [mgr loadPrefs];

    BOOL leftBottom = CGRectContainsPoint(CGRectMake(0, screenBounds.size.height-edgeSize, edgeSize, edgeSize), point);
    BOOL rightBottom = CGRectContainsPoint(CGRectMake(screenBounds.size.width-edgeSize, screenBounds.size.height-edgeSize, edgeSize, edgeSize), point);

    if ((mgr.triggerCorner == 0 && leftBottom) ||
        (mgr.triggerCorner == 1 && rightBottom) ||
        (mgr.triggerCorner == 2 && (leftBottom || rightBottom))) {
        [mgr showSplitScreenAtPoint:point];
    }
}

%end

%ctor {
    [[SPSplitScreenManager sharedInstance] loadPrefs];
}
