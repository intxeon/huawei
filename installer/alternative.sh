#!/bin/sh

ENT=entware

status() {
  INST=INSTALLED
  [ -d /online/opt ] || INST="NOT $INST"
  ENB=ENABLED
  [ -n "$(awk '/alternative.sh start/ {print $0}' /system/etc/autorun.sh)" ] || ENB="NOT $ENB"
  ST=STARTED
  [ -d /opt ] || ST="NOT $ST"
}

enable() {
  if [ -n "$(awk '/alternative.sh start/ {print $0}' /system/etc/autorun.sh)" ]; then
    echo "entware already enabled"
  else
    mount -o remount,rw /system
    echo "/system/etc/alternative.sh start" >> /system/etc/autorun.sh
    echo "entware enabled"
  fi
}

disable() {
  if [ -z "$(awk '/alternative.sh start/ {print $0}' /system/etc/autorun.sh)" ]; then
    echo "entware already disabled"
  else
    mount -o remount,rw /system
    sed -i '/alternative.sh start/d' /system/etc/autorun.sh
    echo "entware disabled"
  fi
}

start() {
  [ -d /opt ] || ln -s /online/opt /opt
  /opt/etc/init.d/rc.unslung start
}

stop() {
  if [ -f /opt/etc/init.d/rc.unslung ]; then
    /opt/etc/init.d/rc.unslung stop
  fi
}

remove() {
  disable
  echo -n "Are you sure you want to delete the entire /online/opt directory (Y/n)? "
  read -rs -n 1 key
  echo ""
  [ "$key" != 'Y' ] && exit
  rm -r /online/opt
  echo "/online/opt was removed."
}

install() {
  echo "Info: Checking for prerequisites and creating folders..."

  if [ -d /online/opt ]
  then
      echo "Warning: Folder /online/opt exists!"
      echo -n "Continue (Y/n)? "
      read -rs -n 1 key
      echo ""
      if [ "$key" != 'Y' ]; then
        exit
      fi
  fi     
  mkdir -p /online/opt
  [ -d /opt ] || ln -s /online/opt /opt
  # no need to create many folders. entware-opt package creates most
  for folder in bin etc lib/opkg tmp var/lock
  do
    if [ -d "/opt/$folder" ]
    then
      echo "Warning: Folder /opt/$folder exists!"
      echo "Warning: If something goes wrong please clean /opt folder and try again."
    else
      mkdir -p /opt/$folder
    fi
  done

  busybox ln -sf /system/bin/busybox-armv7l /bin/wget

  echo "Info: Opkg package manager deployment..."
  DLOADER="ld-linux.so.3"
URL=http://mrbenfy.com/reasyvpn/palma/armv7sf-k3.2/installer/
  wget $URL/opkg.old -O /opt/bin/opkg
  chmod 755 /opt/bin/opkg
  wget $URL/opkg.conf -O /opt/etc/opkg.conf
  wget $URL/ld-2.27.so -O /opt/lib/ld-2.27.so
  wget $URL/libc-2.27.so -O /opt/lib/libc-2.27.so
  wget $URL/libgcc_s.so.1 -O /opt/lib/libgcc_s.so.1
  wget $URL/libpthread-2.27.so -O /opt/lib/libpthread-2.27.so
  cd /opt/lib
  chmod 755 ld-2.27.so
  ln -s ld-2.27.so $DLOADER
  ln -s libc-2.27.so libc.so.6
  ln -s libpthread-2.27.so libpthread.so.0

  unset LD_LIBRARY_PATH
  unset LD_PRELOAD

  echo "Info: Basic packages installation..."
  /opt/bin/opkg update
  /opt/bin/opkg install busybox
  /opt/bin/opkg install entware-opt

  # Fix for multiuser environment
  chmod 777 /opt/tmp

  # now copy default files - it is an alternative installation
  mv /opt/etc/passwd.1 /opt/etc/passwd
  mv /opt/etc/group.1 /opt/etc/group
  mv /opt/etc/shells.1 /opt/etc/shells

  if [ -f /etc/localtime ]
  then
      ln -sf /etc/localtime /opt/etc/localtime
  fi

  enable
  echo "src/gz reasy http://mrbenfy.com/reasyvpn/palma/repo/" >> /opt/etc/opkg.conf
  export PATH=/opt/sbin:/opt/bin:$PATH
  opkg update
  opkg install huawei-base

  echo ""
  echo "Info: Congratulations!"
  echo "Info: If there are no errors above then Entware was successfully initialized."
  echo ""
  echo "This is an alternative Entware installation. We recomend to install and setup Entware version of ssh server"
  echo "and use it instead of a firmware supplied one. You can install dropbear or openssh as an ssh server"
  echo ""
  echo -n "Now you must reboot your system. Do it now (Y/n)? "
  read -rs -n 1 key
  echo ""
  [ "$key" != 'Y' ] && exit
  reboot
}


case "$1" in
	status)
    status
		echo -e "$INST\n$ENB\n$ST"
    ;;
	enable)
		enable
		;;
	start)
		start
		;;
	stop)
		stop
		;;
	disable)
		disable
		;;
	install)
    install
    ;;
  remove)
    remove
    ;;
	*)
		echo "Usage: alternative.sh start|stop|enable|disable|install|remove|status"
		;;
esac
