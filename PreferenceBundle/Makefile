ARCHS = arm64 arm64e
TARGET = iphone:clang:16.0:16.0
INSTALL_TARGET_PROJECT_ONLY = 1
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SPSplitScreenPrefs
SPSplitScreenPrefs_FILES = SPSettingsController.m
SPSplitScreenPrefs_INSTALL_PATH = /Library/PreferenceBundles
SPSplitScreenPrefs_FRAMEWORKS = UIKit Foundation
SPSplitScreenPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk
