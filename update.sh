#!/bin/bash
LOGFILE=/home/pi/logs/update.log
echo "**************************" >> $LOGFILE 2>&1
echo "$(date "+%Y-%m-%d %T")" >> $LOGFILE 2>&1
echo "UPDATING SYSTEM SOFTWARE - UPDATE" >> $LOGFILE 2>&1
sudo apt-get update --yes
echo "UPGRADING SYSTEM SOFTWARE - UPGRADE" >> $LOGFILE 2>&1
sudo apt-get upgrade --yes
echo "UPGRADING SYSTEM SOFTWARE - DISTRIBUTION" >> $LOGFILE 2>&1
sudo apt –y dist-upgrade
echo "REMOVING OBSOLETE DEPENDENCIES" >> $LOGFILE 2>&1
sudo apt-get autoremove --yes
echo "REMOVING OBSOLETE FILES" >> $LOGFILE 2>&1
sudo apt-get autoclean
if cat $LOGFILE|grep -i reboot
then
echo "SYSTEM REBOOT REQUIRED">> $LOGFILE 2>&1
sudo reboot
else
echo "NO REBOOT REQUIRED" >> $LOGFILE 2>&1
fi
