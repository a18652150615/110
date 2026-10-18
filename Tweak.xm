#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

// ============================================================
// 绝对安全版 v2：修复编译错误
// ============================================================

static BOOL g_crashed = NO;
static UIWindow *g_mainWin = nil;
static UIWindow *g_pinWin = nil;

@interface SPSafe : NSObject
+ (UIWindowScene *)scene;
+ (void)show;
+ (void)pin;
+ (void)unpin;
@end

@implementation SPSafe

+ (UIWindowScene *)scene {
    @try {
        for (UIWindowScene *s in [UIApplication sharedApplication].connectedScenes.allObjects) {
            if ([s isKindOfClass:[UIWindowScene class]] &&
                s.activationState == UISceneActivationStateForegroundActive) {
                return s;
            }
        }
    } @catch (NSException *e) {}
    return nil;
}

+ (void)show {
    @try {
        if (g_crashed) return;
        if (g_mainWin && !g_mainWin.hidden) return;

        UIWindowScene *sc = [self scene];
        if (!sc) { g_crashed = YES; return; }

        CGRect sb = [UIScreen mainScreen].bounds;
        CGFloat w = sb.size.width * 0.45;
        CGFloat h = sb.size.height * 0.6;

        if (!g_mainWin) {
            UIWindow *win = [[UIWindow alloc] initWithWindowScene:sc];
            win.frame = CGRectMake(0, sb.size.height - h, w, h);
            win.windowLevel = 1000;
            win.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
            win.layer.cornerRadius = 16;

            UIView *top = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 44)];
            top.backgroundColor = [UIColor lightGrayColor];
            [win addSubview:top];

            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, 200, 20)];
            lbl.text = @"分屏小窗";
            lbl.textColor = [UIColor darkGrayColor];
            [top addSubview:lbl];

            // 右侧条 - 点击收起
            UIView *right = [[UIView alloc] initWithFrame:CGRectMake(w-20, 44, 20, h-64)];
            right.backgroundColor = [UIColor grayColor];
            [win addSubview:right];

            // 底部条 - 点击收起
            UIView *bottom = [[UIView alloc] initWithFrame:CGRectMake(0, h-20, w, 20)];
            bottom.backgroundColor = [UIColor grayColor];
            [win addSubview:bottom];

            g_mainWin = win;
        }

        g_mainWin.hidden = NO;

        if (g_pinWin) {
            g_pinWin.hidden = YES;
            g_pinWin = nil;
        }
    } @catch (NSException *e) {
        g_crashed = YES;
    }
}

+ (void)pin {
    @try {
        if (g_crashed) return;

        UIWindowScene *sc = [self scene];
        if (!sc) { g_crashed = YES; return; }

        CGRect sb = [UIScreen mainScreen].bounds;

        if (!g_pinWin) {
            CGRect pf = CGRectMake(sb.size.width - 32, 200, 32, 80);
            UIWindow *pw = [[UIWindow alloc] initWithWindowScene:sc];
            pw.frame = pf;
            pw.windowLevel = 1001;
            pw.backgroundColor = [UIColor clearColor];

            UIView *pv = [[UIView alloc] initWithFrame:pf];
            pv.backgroundColor = [UIColor systemBlueColor];
            pv.layer.cornerRadius = 8;
            [pw addSubview:pv];

            g_pinWin = pw;
        }
        g_pinWin.hidden = NO;
        g_mainWin.hidden = YES;
    } @catch (NSException *e) {
        g_crashed = YES;
    }
}

+ (void)unpin {
    @try {
        g_pinWin.hidden = YES;
        g_pinWin = nil;
        g_mainWin.hidden = NO;
    } @catch (NSException *e) {}
}

@end

%hook SpringBoard

- (void)sendEvent:(UIEvent *)event {
    %orig;

    if (g_crashed) return;

    @autoreleasepool {
        @try {
            NSSet *touches = [event allTouches];
            if (touches.count != 1) return;

            UITouch *t = [touches anyObject];
            if (t.phase != UITouchPhaseBegan) return;

            UIView *v = t.view;
            if (!v || !v.window) return;

            CGPoint p = [t locationInView:v.window];
            CGRect sb = [UIScreen mainScreen].bounds;

            // 左下角 50x50
            if (p.x < 50 && p.y > sb.size.height - 50) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SPSafe show];
                });
            }
        } @catch (NSException *e) {}
    }
}

%end

%ctor {
    @try {
        NSLog(@"[SplitScreen] loaded safe");
    } @catch (NSException *e) {}
}
