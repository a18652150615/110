#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

// ============================================================
// 可配置参数
// ============================================================
static CGFloat g_hotSize = 80;          // 热区边长
static BOOL g_showDebug = YES;         // 是否显示红色热区标记

// ============================================================
static BOOL g_crashed = NO;
static UIWindow *g_mainWin = nil;
static UIWindow *g_pinWin = nil;
static UIWindow *g_debugWin = nil;

@interface SPSafe : NSObject
+ (UIWindowScene *)scene;
+ (void)showDebugArea;
+ (void)show;
+ (void)pin;
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

+ (void)showDebugArea {
    @try {
        if (!g_showDebug) return;
        if (g_debugWin) return;

        UIWindowScene *sc = [self scene];
        if (!sc) return;

        CGRect sb = [UIScreen mainScreen].bounds;
        CGRect frame = CGRectMake(0, sb.size.height - g_hotSize, g_hotSize, g_hotSize);

        UIWindow *dw = [[UIWindow alloc] initWithWindowScene:sc];
        dw.frame = frame;
        dw.windowLevel = 999;
        dw.backgroundColor = [UIColor colorWithRed:1.0 green:0 blue:0 alpha:0.25];
        dw.layer.borderColor = [UIColor redColor].CGColor;
        dw.layer.borderWidth = 2.0;
        dw.userInteractionEnabled = NO;

        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, g_hotSize, 30)];
        lbl.text = @"触";
        lbl.textColor = [UIColor redColor];
        lbl.font = [UIFont boldSystemFontOfSize:14];
        lbl.textAlignment = NSTextAlignmentCenter;
        [dw addSubview:lbl];

        g_debugWin = dw;
        dw.hidden = NO;
    } @catch (NSException *e) {}
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

            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, 250, 20)];
            lbl.text = @"分屏小窗 - 点右侧/底部收起";
            lbl.textColor = [UIColor darkGrayColor];
            lbl.font = [UIFont systemFontOfSize:13];
            [top addSubview:lbl];

            UIView *rightBar = [[UIView alloc] initWithFrame:CGRectMake(w-20, 44, 20, h-64)];
            rightBar.backgroundColor = [UIColor grayColor];
            [win addSubview:rightBar];

            UIView *bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, h-20, w, 20)];
            bottomBar.backgroundColor = [UIColor grayColor];
            [win addSubview:bottomBar];

            UIView *drag = [[UIView alloc] initWithFrame:CGRectMake(w-30, h-30, 30, 30)];
            drag.backgroundColor = [UIColor systemBlueColor];
            drag.layer.cornerRadius = 6;
            [win addSubview:drag];

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

            if (p.x < g_hotSize && p.y > sb.size.height - g_hotSize) {
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [SPSafe showDebugArea];
        });
    } @catch (NSException *e) {}
}
