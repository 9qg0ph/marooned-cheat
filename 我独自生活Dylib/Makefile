ARCHS = arm64
TARGET = iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = WoduziCheat
WoduziCheat_FILES = WoduziCheat.m
WoduziCheat_CFLAGS = -fobjc-arc
WoduziCheat_FRAMEWORKS = Foundation UIKit

include $(THEOS)/makefiles/library.mk

after-install::
	install.exec "killall -9 SpringBoard"