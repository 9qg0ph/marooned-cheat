TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = 不服来通关

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DragonCheat

DragonCheat_FILES = DragonCheat.m
DragonCheat_CFLAGS = -fobjc-arc
DragonCheat_FRAMEWORKS = UIKit Foundation
DragonCheat_LIBRARIES = sqlite3

include $(THEOS_MAKE_PATH)/tweak.mk
