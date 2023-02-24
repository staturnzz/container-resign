ARCHS = armv7
TARGET := iphone::10.3:9.0

include $(THEOS)/makefiles/common.mk

TOOL_NAME = container-resign

container-resign_FILES = main.m
container-resign_CFLAGS = -fobjc-arc
container-resign_CODESIGN_FLAGS = -Sentitlements.plist
container-resign_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk
