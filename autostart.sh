#!/bin/sh

FILE=/home/pi/Desktop/server.sh

AUTOSTART='/etc/init.d/autostart_'$(basename $FILE .sh)'.sh'
if [ ! -f $AUTOSTART ]; then
    echo $FILE | sudo tee $AUTOSTART
    sudo chmod 755 $AUTOSTART
    sudo update-rc.d $(basename $AUTOSTART) defaults
fi


