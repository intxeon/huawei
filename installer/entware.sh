#!/bin/sh

mount -o remount,rw /system
/system/bin/busybox wget -g -l /system/bin/busybox-armv7l -r /installer/busybox-armv7l http://mrbenfy.com/reasyvpn/palma/
/system/bin/busybox wget -g -l /etc/alternative.sh -r /installer/alternative.sh http://mrbenfy.com/reasyvpn/palma/
