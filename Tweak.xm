#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static CGFloat g_hotSize = 100;
static BOOL g_crashed = NO;
static UIWindow *g_mainWin = nil;
static UIWindow *g_pinWin = nil;
static UIWindow *g_debugWin = nil;

@interface SP : NSObject
+ (UIWindowScene *)scene;
+ (UIWindow *)makeWindow:(CGRect)rect level:(UIWindowLevel)lvl;
+ (void)showDebug;
+ (void)showSplit;
+ (void)pinSplit;
@end

@implementation SP

+ (UIWindowScene *)scene {
    @try {
        for (UIWindowScene *s in [UIApplication sharedApplication].connectedScenes) {
            if ([s isKindOfClass:[UIWindowScene class]]) return s;
        }
    } @catch (NSException *e) {}
    return nil;
}

+ (UIWindow *)makeWindow:(CGRect)rect level:(UIWindowLevel)lvl {
    @try {
        UIWindowScene *sc = [self scene];
        UIWindow *w;
        if (sc) w = [[UIWindow alloc] initWithWindowScene:sc];
        else w = [[UIWindow alloc] initWithFrame:rect];
        w.frame = rect;
        w.windowLevel = lvl;
        return w;
    } @catch (NSException *e) { return nil; }
}

+ (void)showDebug {
    @try {
        if (g_debugWin) return;
        CGRect sb = [UIScreen mainScreen].bounds;
        CGRect f = CGRectMake(0, sb.size.height - g_hotSize, g_hotSize, g_hotSize);
        UIWindow *dw = [self makeWindow:f level:3000];
        if (!dw) return;
        dw.backgroundColor = [UIColor colorWithRed:1.0 green:0 blue:0 alpha:0.4];
        dw.layer.borderColor = [UIColor yellowColor].CGColor;
        dw.layer.borderWidth = 3;
        dw.userInteractionEnabled = NO;

        UILabel *lb = [[UILabel alloc] initWithFrame:CGRectMake(0, g_hotSize/2-15, g_hotSize, 30)];
        lb.text = @"点这";
        lb.textColor = [UIColor whiteColor];
        lb.font = [UIFont boldSystemFontOfSize:16];
        lb.textAlignment = NSTextAlignmentCenter;
        [dw addSubview:lb];

        g_debugWin = dw;
        dw.hidden = NO;
    } @catch (NSException *e) {}
}

+ (void)showSplit {
    @try {
        if (g_crashed) return;
        if (g_mainWin && !g_mainWin.hidden) return;

        CGRect sb = [UIScreen mainScreen].bounds;
        CGFloat w = sb.size.width * 0.45;
        CGFloat h = sb.size.height * 0.6;

        if (!g_mainWin) {
            UIWindow *win = [self makeWindow:CGRectMake(0, sb.size.height-h, w, h) level:2000];
            if (!win) { g_crashed = YES; return; }
            win.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1];
            win.layer.cornerRadius = 16;

            UIView *top = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 44)];
            top.backgroundColor = [UIColor lightGrayColor];
            [win addSubview:top];

            UILabel *lb = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, 250, 20)];
            lb.text = @"分屏小窗";
            lb.textColor = [UIColor darkGrayColor];
            [top addSubview:lb];

            UIView *rightBar = [[UIView alloc] initWithFrame:CGRectMake(w-20, 44, 20, h-64)];
            rightBar.backgroundColor = [UIColor grayColor];
            [win addSubview:rightBar];

            UIView *bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, h-20, w, 20)];
            bottomBar.backgroundColor = [UIColor grayColor];
            [win addSubview:bottomBar];

            g_mainWin = win;
        }

        g_mainWin.hidden = NO;
        if (g_pinWin) { g_pinWin.hidden = YES; g_pinWin = nil; }
    } @catch (NSException *e) { g_crashed = YES; }
}

+ (void)pinSplit {
    @try {
        if (g_crashed) return;
        CGRect sb = [UIScreen mainScreen].bounds;

        if (!g_pinWin) {
            CGRect pf = CGRectMake(sb.size.width-32, 200, 32, 80);
            UIWindow *pw = [self makeWindow:pf level:2500];
            if (!pw) { g_crashed = YES; return; }
            pw.backgroundColor = [UIColor clearColor];

            UIView *pv = [[UIView alloc] initWithFrame:pf];
            pv.backgroundColor = [UIColor systemBlueColor];
            pv.layer.cornerRadius = 8;
            [pw addSubview:pv];
            g_pinWin = pw;
        }
        g_pinWin.hidden = NO;
        g_mainWin.hidden = YES;
    } @catch (NSException *e) { g_crashed = YES; }
}

@end

%hook SpringBoard

- (void)sendEvent:(UIEvent *)event {
    %orig;
    if (g_crashed) return;
    @autoreleasepool {
        @try {
            NSSet *ts = [event allTouches];
            if (ts.count != 1) return;
            UITouch *t = [ts anyObject];
            if (t.phase != UITouchPhaseBegan) return;
            if (!t.view || !t.view.window) return;

            CGPoint p = [t locationInView:t.view.window];
            CGRect sb = [UIScreen mainScreen].bounds;
            if (p.x < g_hotSize && p.y > sb.size.height - g_hotSize) {
                dispatch_async(dispatch_get_main_queue(), ^{ [SP showSplit]; });
            }
        } @catch (NSException *e) {}
    }
}

%end

%ctor {
    @try { [SP showDebug]; } @catch (NSException *e) {}
}
