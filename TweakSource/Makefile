TARGET := iphone:clang:latest:14.0
ARCHS = arm64
INSTALL_TARGET_PROCESSES = Wink

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WinkCrack

WinkCrack_FILES = Tweak.x
WinkCrack_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
