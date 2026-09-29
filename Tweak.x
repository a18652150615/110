#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static void handleOpenJBURL(NSURL *url) {
    if (!url) return;
    if (![url.scheme isEqualToString:@"openjb"]) return;
    
    NSString *bundleId = nil;
    NSURLComponents *comp = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    for(NSURLQueryItem *item in comp.queryItems){
        if([item.name isEqualToString:@"bundle"]){
            bundleId = item.value;
            break;
        }
    }
    if(!bundleId || bundleId.length == 0) return;
    
    Class TOManager = NSClassFromString(@"TOManager");
    if (!TOManager) return;
    id instance = [TOManager performSelector:@selector(sharedManager)];
    if([instance respondsToSelector:@selector(openAppWithBundleID:)]){
        [instance performSelector:@selector(openAppWithBundleID:) withObject:bundleId];
    }
}

%hook UIApplication
- (BOOL)openURL:(NSURL *)url options:(id)options completionHandler:(void (^)(BOOL))handler
{
    handleOpenJBURL(url);
    return %orig;
}
%end
