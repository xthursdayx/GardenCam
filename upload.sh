#!/bin/bash
#
LOGFILE=/home/pi/logs/upload.log
#
echo "**************************" >> $LOGFILE 2>&1
echo "$(date "+%Y-%m-%d %T")" >> $LOGFILE 2>&1
#
echo "UPLOADING GARDENCAM IMAGE FILES" >> $LOGFILE 2>&1
#
#if sudo cp -R /home/pi/gardencam/images /home/pi/DRIVE/share/; then
if sudo rsync -trv /home/pi/gardencam/images/*.jpg /home/pi/DRIVE/share/images/; then
   echo "UPLOAD SUCCESSFUL" >> $LOGFILE 2>&1
#
   if rm -rf /home/pi/gardencam/images/*; then
   echo "OLD IMAGE FILES DELETED" >> $LOGFILE 2>&1
   else
   echo "ERROR DELETING IMAGE FILES" >> $LOGFILE 2>&1
   fi
#
   if rm -rf /home/pi/logs/camera.log; then
   echo "CAMERA LOG RESET" >> $LOGFILE 2>&1
   touch /home/pi/logs/camera.log
   else
   echo "ERROR CLEARING CAMERA LOG" >> $LOGFILE 2>&1
   fi
#
else
   echo "UPLOAD UNSUCCESSFUL" >> $LOGFILE 2>&1
fi
