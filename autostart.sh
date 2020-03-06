#!/bin/sh

FILE=/home/pi/Desktop/raspberry_mqtt_server/server.sh

AUTOSTART='/etc/init.d/autostart_'$(basename $FILE .sh)'.sh'
if [ ! -f $AUTOSTART ]; then
    echo lxterminal -e $FILE | sudo tee $AUTOSTART
    sudo chmod a+x $AUTOSTART
    sudo update-rc.d $(basename $AUTOSTART) defaults
fi


