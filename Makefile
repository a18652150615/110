ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:16.0
INSTALL_TARGET_PROJECT_ONLY = 1
THEOS_PACKAGE_SCHEME = rootless

TWEAK_NAME = SplitScreenTweak
SplitScreenTweak_FILES = Tweak.xm
SplitScreenTweak_FRAMEWORKS = UIKit Foundation QuartzCore
SplitScreenTweak_PRIVATE_FRAMEWORKS = FrontBoardServices SpringBoardServices

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	killall -9 SpringBoard
