THEOS_DEVICE_IP = 192.168.1.100
ARCHS = arm64
TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MaroonedCheat

MaroonedCheat_FILES = Tweak.x
MaroonedCheat_CFLAGS = -fobjc-arc
MaroonedCheat_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
