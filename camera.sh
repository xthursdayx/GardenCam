#!/bin/bash
#
# Add an entry to crontab to run regularly.
# Example: Update /etc/crontab to run camera.sh as root every 10 minutes between 1pm and 7am	
# */10 13-23,0-6 * * * sh /home/pi/gardencam/camera.sh 2>&1
#
COMPDATE=$(date +"%Y-%m-%d_%H%M")
HUMNDATE=$(date +"%Y-%m-%d %T")
#
LOGFILE=/home/pi/logs/camera.log
#
mailreceiver=[YourEmailAddress]@gmail.com
topic="GardenCam Error!"
message="GardenCam has reported an error at $HUMNDATE"
#
echo "**************************" >> $LOGFILE 2>&1
echo "$HUMNDATE" >> $LOGFILE 2>&1
#
if raspistill -md 4 -q 75 -hf -vf -o /home/pi/gardencam/images/$COMPDATE.jpg; then
   echo "IMAGE CAPTURE SUCCESSFUL" >> $LOGFILE 2>&1
else
   echo "IMAGE CAPTURE UNSUCCESSFUL" >> $LOGFILE 2>&1
   cd /home/pi/
   echo $message > message.txt
   mutt -e "set crypt_use_gpgme=no" -s "${topic}" ${mailreceiver} < message.txt && rm message.txt
fi
