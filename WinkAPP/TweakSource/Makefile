TARGET := iphone:clang:latest:14.0
ARCHS = arm64
INSTALL_TARGET_PROCESSES = Wink

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = WinkCrack

WinkCrack_FILES = Tweak.x
WinkCrack_CFLAGS = -fobjc-arc
WinkCrack_FRAMEWORKS = UIKit Foundation
WinkCrack_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

include $(THEOS_MAKE_PATH)/library.mk
