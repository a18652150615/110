#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

// ============================================================
// 绝对安全版：极简 hook + 延迟创建 + 自动熔断
// ============================================================

static BOOL g_loaded = NO;
static BOOL g_crashed = NO;  // 熔断标志：一旦出错永久不再尝试

@interface SPSafeWindow : NSObject
+ (void)tryShow;
@end

@implementation SPSafeWindow

+ (UIWindowScene *)findScene {
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

+ (void)tryShow {
    @try {
        if (g_crashed) return;
        
        // 已经有窗口就不重复创建
        static UIWindow *s_win = nil;
        static UIWindow *s_pin = nil;
        
        if (s_win && !s_win.hidden) return;
        
        UIWindowScene *scene = [self findScene];
        if (!scene) {
            g_crashed = YES;  // 拿不到 scene，熔断
            return;
        }
        
        CGRect sb = [UIScreen mainScreen].bounds;
        CGFloat w = sb.size.width * 0.45;
        CGFloat h = sb.size.height * 0.6;
        
        if (!s_win) {
            UIWindow *win = [[UIWindow alloc] initWithWindowScene:scene];
            win.frame = CGRectMake(0, sb.size.height - h, w, h);
            win.windowLevel = 1000;  // 不用 UIWindowLevelAlert，用数值更安全
            win.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
            win.layer.cornerRadius = 16;
            
            // 顶部条
            UIView *top = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 44)];
            top.backgroundColor = [UIColor lightGrayColor];
            [win addSubview:top];
            
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, 200, 20)];
            lbl.text = @"分屏小窗";
            lbl.textColor = [UIColor darkGrayColor];
            [top addSubview:lbl];
            
            // 右侧条点击收起
            UIView *right = [[UIView alloc] initWithFrame:CGRectMake(w-20, 44, 20, h-64)];
            right.backgroundColor = [UIColor grayColor];
            [win addSubview:right];
            
            // 底部条点击收起
            UIView *bottom = [[UIView alloc] initWithFrame:CGRectMake(0, h-20, w, 20)];
            bottom.backgroundColor = [UIColor grayColor];
            [win addSubview:bottom];
            
            s_win = win;
        }
        
        s_win.hidden = NO;
        
        // 如果之前的图钉还在，移除
        if (s_pin) {
            s_pin.hidden = YES;
            s_pin = nil;
        }
        
        NSLog(@"[SplitScreen] shown OK");
    } @catch (NSException *e) {
        NSLog(@"[SplitScreen] show crashed: %@", e);
        g_crashed = YES;  // 出错就熔断，不再尝试
    }
}

+ (void)tryPin {
    @try {
        if (g_crashed) return;
        
        static UIWindow *s_win = nil;
        static UIWindow *s_pin = nil;
        
        // 找到之前的窗口（用强引用找）
        // 简单起见：直接创建图钉
        UIWindowScene *scene = [self findScene];
        if (!scene) return;
        
        CGRect sb = [UIScreen mainScreen].bounds;
        
        if (!s_pin) {
            CGRect pf = CGRectMake(sb.size.width - 32, 200, 32, 80);
            UIWindow *pw = [[UIWindow alloc] initWithWindowScene:scene];
            pw.frame = pf;
            pw.windowLevel = 1001;
            pw.backgroundColor = [UIColor clearColor];
            
            UIView *pv = [[UIView alloc] initWithFrame:pf];
            pv.backgroundColor = [UIColor systemBlueColor];
            pv.layer.cornerRadius = 8;
            [pw addSubview:pv];
            
            s_pin = pw;
        }
        s_pin.hidden = NO;
        
        // 隐藏主窗口
        // 找到主窗口
        for (UIWindow *w in [UIApplication sharedApplication].windows) {
            if (w.windowLevel == 1000) {
                w.hidden = YES;
                break;
            }
        }
    } @catch (NSException *e) {
        NSLog(@"[SplitScreen] pin crashed: %@", e);
        g_crashed = YES;
    }
}

@end

// ============================================================
// 极简 hook - 只 hook sendEvent，不 hook 任何启动方法
// ============================================================
%hook SpringBoard

- (void)sendEvent:(UIEvent *)event {
    %orig;
    
    if (g_crashed) {
        // 熔断后什么都不做，直接返回
        return;
    }
    
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
            
            // 左下角 50x50 热区
            if (p.x < 50 && p.y > sb.size.height - 50) {
                // 异步创建窗口，不阻塞事件处理
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SPSafeWindow tryShow];
                });
            }
        } @catch (NSException *e) {
            // 吞掉异常
        }
    }
}

%end

// ============================================================
// 初始化 - 只注册，延迟5秒后才标记就绪
// ============================================================
%ctor {
    @autoreleasepool {
        @try {
            // 不做任何 UI 操作，只是标记已加载
            g_loaded = YES;
            NSLog(@"[SplitScreen] dylib loaded, waiting...");
            
            // 5秒后如果没崩溃，才算真正就绪
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                NSLog(@"[SplitScreen] ready, left corner active");
            });
        } @catch (NSException *e) {}
    }
}
