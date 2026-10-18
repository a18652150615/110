#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>

@interface SPSettingsController : PSListController
@end

@implementation SPSettingsController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlist:@"SPSettingsRoot" inBundle:[NSBundle bundleForClass:[self class]]];
    }
    return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [super setPreferenceValue:value specifier:specifier];
    // 通知SpringBoard刷新配置
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), 
        CFSTR("com.yourname.splitscreentweak.prefsChanged"), 
        NULL, NULL, true);
}

@end
