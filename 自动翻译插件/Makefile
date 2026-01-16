# AutoTranslate Dylib Makefile
# 需要安装 theos 环境

THEOS_DEVICE_IP = 192.168.1.100
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:11.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AutoTranslate

AutoTranslate_FILES = AutoTranslate.m
AutoTranslate_CFLAGS = -fobjc-arc
AutoTranslate_FRAMEWORKS = UIKit Foundation Security
AutoTranslate_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
