#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

// ============================================================
// 稳定版：仅左下角呼出，避免与Open冲突
// ============================================================

@interface SPSplitScreenManager : NSObject
@property (nonatomic, strong) NSMutableArray *floatingWindows;
@property (nonatomic, strong) UIWindow *splitWindow;
@property (nonatomic, strong) UIWindow *pinWindow;
@property (nonatomic, assign) BOOL hasShown;
+ (instancetype)sharedInstance;
- (UIWindowScene *)mainScene;
- (void)showSplitScreen;
- (void)dismissSplitScreen;
- (void)pinSplitScreen;
@end

static SPSplitScreenManager *g_mgr = nil;

@implementation SPSplitScreenManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_mgr = [[self alloc] init];
        g_mgr.floatingWindows = [NSMutableArray array];
        g_mgr.hasShown = NO;
    });
    return g_mgr;
}

- (UIWindowScene *)mainScene {
    @try {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes.allObjects) {
            if ([scene isKindOfClass:[UIWindowScene class]] &&
                scene.activationState == UISceneActivationStateForegroundActive) {
                return scene;
            }
        }
    } @catch (NSException *e) {}
    return nil;
}

- (void)showSplitScreen {
    @try {
        if (self.splitWindow) return;
        if (self.hasShown) return;

        UIWindowScene *scene = [self mainScene];
        if (!scene) return;

        CGRect screenBounds = [UIScreen mainScreen].bounds;
        CGFloat width = screenBounds.size.width * 0.45;  // 默认45%比例
        CGFloat height = screenBounds.size.height * 0.6;

        UIWindow *win = [[UIWindow alloc] initWithWindowScene:scene];
        win.frame = CGRectMake(0, screenBounds.size.height - height, width, height);
        win.windowLevel = UIWindowLevelAlert + 1;
        win.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
        win.layer.cornerRadius = 16;
        win.layer.masksToBounds = YES;

        // 顶部条 - 点击全屏
        UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 44)];
        topBar.backgroundColor = [UIColor lightGrayColor];
        UITapGestureRecognizer *topTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTopTap)];
        [topBar addGestureRecognizer:topTap];
        [win addSubview:topBar];

        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, 200, 20)];
        lbl.text = @"分屏小窗 · 点顶部全屏";
        lbl.textColor = [UIColor darkGrayColor];
        lbl.font = [UIFont systemFontOfSize:14];
        [topBar addSubview:lbl];

        // 右侧条 - 点击收起
        UIView *rightBar = [[UIView alloc] initWithFrame:CGRectMake(width-20, 44, 20, height-64)];
        UITapGestureRecognizer *rightTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onEdgeTap)];
        [rightBar addGestureRecognizer:rightTap];
        [win addSubview:rightBar];

        // 底部条 - 点击收起
        UIView *bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, height-20, width, 20)];
        UITapGestureRecognizer *bottomTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onEdgeTap)];
        [bottomBar addGestureRecognizer:bottomTap];
        [win addSubview:bottomBar];

        // 右下角拖动 - 调整大小
        UIView *dragHandle = [[UIView alloc] initWithFrame:CGRectMake(width-30, height-30, 30, 30)];
        dragHandle.backgroundColor = [UIColor systemBlueColor];
        dragHandle.layer.cornerRadius = 6;
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onResizePan:)];
        [dragHandle addGestureRecognizer:pan];
        [win addSubview:dragHandle];

        self.splitWindow = win;
        win.hidden = NO;
        self.hasShown = YES;

        NSLog(@"[SplitScreen] Window shown OK");
    } @catch (NSException *e) {
        NSLog(@"[SplitScreen] show error: %@", e);
        self.splitWindow = nil;
    }
}

- (void)onTopTap {
    @try {
        [UIView animateWithDuration:0.3 animations:^{
            self.splitWindow.frame = [UIScreen mainScreen].bounds;
        }];
    } @catch (NSException *e) {}
}

- (void)onEdgeTap {
    @try {
        [self pinSplitScreen];
    } @catch (NSException *e) {}
}

- (void)pinSplitScreen {
    @try {
        if (!self.splitWindow) return;

        CGRect screenBounds = [UIScreen mainScreen].bounds;
        UIWindowScene *scene = [self mainScene];
        if (!scene) return;

        self.splitWindow.hidden = YES;

        // 图钉挂在屏幕右侧
        CGRect pinFrame = CGRectMake(screenBounds.size.width - 32, 200, 32, 80);
        UIWindow *pinWin = [[UIWindow alloc] initWithWindowScene:scene];
        pinWin.frame = pinFrame;
        pinWin.windowLevel = UIWindowLevelAlert + 2;
        pinWin.backgroundColor = [UIColor clearColor];

        UIView *pinView = [[UIView alloc] initWithFrame:pinFrame];
        pinView.backgroundColor = [UIColor systemBlueColor];
        pinView.layer.cornerRadius = 8;

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onPinTap:)];
        [pinView addGestureRecognizer:tap];
        [pinWin addSubview:pinView];

        self.pinWindow = pinWin;
        pinWin.hidden = NO;
    } @catch (NSException *e) {
        NSLog(@"[SplitScreen] pin error: %@", e);
    }
}

- (void)onPinTap:(UITapGestureRecognizer *)tap {
    @try {
        self.pinWindow.hidden = YES;
        self.pinWindow = nil;
        self.splitWindow.hidden = NO;
    } @catch (NSException *e) {}
}

- (void)onResizePan:(UIPanGestureRecognizer *)pan {
    @try {
        if (!self.splitWindow) return;
        CGPoint t = [pan translationInView:self.splitWindow];
        CGRect f = self.splitWindow.frame;
        f.size.width = MAX(200, f.size.width + t.x);
        f.size.height = MAX(300, f.size.height + t.y);
        f.origin.x = 0;
        f.origin.y = [UIScreen mainScreen].bounds.size.height - f.size.height;
        self.splitWindow.frame = f;
        [pan setTranslation:CGPointZero inView:self.splitWindow];
    } @catch (NSException *e) {}
}

- (void)dismissSplitScreen {
    @try {
        [self.splitWindow removeFromSuperview];
        self.splitWindow = nil;
        self.hasShown = NO;
    } @catch (NSException *e) {}
}

@end

// ============================================================
// Hook 触摸事件 - 只识别左下角
// ============================================================
%hook SpringBoard

- (void)finishLaunchingWithOptions:(NSDictionary *)opts {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @try {
            NSLog(@"[SplitScreen] Ready - LeftCorner only");
        } @catch (NSException *e) {}
    });
}

- (void)sendEvent:(UIEvent *)event {
    %orig;

    @autoreleasepool {
        @try {
            NSSet *touches = [event allTouches];
            if (touches.count != 1) return;

            UITouch *touch = [touches anyObject];
            if (touch.phase != UITouchPhaseBegan) return;

            UIView *view = touch.view;
            if (!view) return;

            UIWindow *win = view.window;
            if (!win) return;

            CGPoint p = [touch locationInView:win];
            CGRect sb = [UIScreen mainScreen].bounds;
            CGFloat edge = 50;

            // 只判断左下角热区
            BOOL leftBottom = CGRectContainsPoint(
                CGRectMake(0, sb.size.height - edge, edge, edge), p);

            if (leftBottom) {
                SPSplitScreenManager *mgr = [SPSplitScreenManager sharedInstance];
                [mgr performSelectorOnMainThread:@selector(showSplitScreen)
                                      withObject:nil waitUntilDone:NO];
            }
        } @catch (NSException *e) {
            // 吞掉所有异常，绝不崩溃
        }
    }
}

%end
