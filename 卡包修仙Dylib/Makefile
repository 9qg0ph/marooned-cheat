ARCHS = arm64
TARGET = iphone:clang:14.5:12.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = KabaoCheat

KabaoCheat_FILES = KabaoCheat.m
KabaoCheat_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore
KabaoCheat_LDFLAGS = -dynamiclib

include $(THEOS)/makefiles/library.mk