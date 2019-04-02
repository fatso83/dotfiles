#!/bin/sh

LOGITECH_MOUSE='/sys/class/input/mouse3'
KINESIS='/sys/bus/usb/devices/3-1.4.1'


# Auto-tune
/usr/sbin/powertop --auto-tune

# Don't turn off my mouse and keyboard, please
DEVICES="$LOGITECH_MOUSE $KINESIS"
for DEVICE in $DEVICES; do
    echo 'auto' > "$DEVICE/power/control";
done

