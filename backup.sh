#!/bin/bash
#
# Add an entry to crontab to run regularly.
# Example: Update /etc/crontab to run backup.sh as root every Sunday morning at 7:30am
# 30 7 * * 0 sh /home/pi/scripts/backup.sh
# ========================================================================

# Set up variables
SUBDIR=gardencam_backups
MOUNTPOINT=~/DRIVE/share
DIR=$MOUNTPOINT/$SUBDIR
DATE=$(date +"%Y-%m-%d_%H%M")
LOGFILE="$DIR/logs/backup_${DATE}.log"
RETENTIONPERIOD=8 # days to keep old backups
POSTPROCESS=0 # 1 to use a postProcessSucess function after successfull backup
GZIP=0 # whether to gzip the backup or not

# Setting up echo fonts
red='\e[0;31m'
green='\e[0;32m'
cyan='\e[0;36m'
yellow='\e[1;33m'
purple='\e[0;35m'
NC='\e[0m' #No Color
bold=`tput bold`
normal=`tput sgr0`

# Define functions
function stopServices {
	echo -e "${purple}${bold}Stopping services before backup${NC}${normal}" | tee -a $LOGFILE
    sudo service avahi-daemon stop
    sudo service cron stop
    sudo service sendmail stop
    sudo service ssh stop
}

function startServices {
	echo -e "${purple}${bold}Starting the stopped services${NC}${normal}" | tee -a $LOGFILE
    sudo service avahi-daemon start
    sudo service cron start
    sudo service sendmail start
    sudo service ssh start
}

# Function which tries to mount MOUNTPOINT
function mountMountPoint {
    # mount all drives in fstab (that means MOUNTPOINT needs an entry there)
    mount -a
}

function postProcessSucess {
	# Update Packages and Kernel
	echo -e "${yellow}Update Packages and Kernel${NC}${normal}" | tee -a $LOGFILE
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get autoclean

    echo -e "${yellow}Update Raspberry Pi Firmware${NC}${normal}" | tee -a $LOGFILE
    sudo rpi-update
    sudo ldconfig

    # Reboot now
    echo -e "${yellow}Reboot now ...${NC}${normal}" | tee -a $LOGFILE
    sudo reboot
}

# =====================================================================

# Check if mount point is mounted, if not quit!
if ! mountpoint -q "$MOUNTPOINT" ; then
    echo -e "${yellow}${bold}Destination is not mounted; attempting to mount ... ${NC}${normal}"
    mountMountPoint
    if ! mountpoint -q "$MOUNTPOINT" ; then
        echo -e "${red}${bold} Unable to mount $MOUNTPOINT; Aborting! ${NC}${normal}"
        exit 1
    fi
    echo -e "${green}${bold}Mounted $MOUNTPOINT; Continuing backup${NC}${normal}"
fi

# Check if backup directory exists
if [ ! -d "$DIR" ];
   then
      mkdir $DIR
	  echo -e "${yellow}${bold}Backup directory $DIR didn't exist, I created it${NC}${normal}"  | tee -a $LOGFILE
fi

echo -e "${green}${bold}Starting GardenCam backup process!${NC}${normal}" | tee -a $LOGFILE
echo "____ BACKUP ON $(date +%Y/%m/%d_%H:%M:%S)" | tee -a $LOGFILE
echo ""

# First check if pv package is installed, if not, install it first
PACKAGESTATUS=`dpkg -s pv | grep Status`;

if [[ $PACKAGESTATUS == S* ]]
   then
      echo -e "${cyan}${bold}Package 'pv' is installed${NC}${normal}" | tee -a $LOGFILE
      echo ""
   else
      echo -e "${yellow}${bold}Package 'pv' is NOT installed${NC}${normal}" | tee -a $DIR/backup.log
      echo -e "${yellow}${bold}Installing package 'pv' + 'pv dialog'. Please wait...${NC}${normal}" | tee -a $LOGFILE
      echo ""
      sudo apt-get -y install pv && sudo apt-get -y install pv dialog
fi

# Create a filename with datestamp for our current backup
OFILE="$DIR/backup_$(hostname)_${DATE}.img"

# First sync disks
sync; sync

# Shut down some services before starting backup process
stopServices

# Begin the backup process, should take about 45 minutes hour from 8Gb SD card to HDD
echo -e "${green}${bold}Backing up SD card to img file on network drive${NC}${normal}" | tee -a $LOGFILE
SDSIZE=`sudo blockdev --getsize64 /dev/mmcblk0`;
if [ $GZIP = 1 ];
	then
		echo -e "${green}Gzipping backup${NC}${normal}"
		OFILE=$OFILE.gz # append gz at file
        sudo pv -tpreb /dev/mmcblk0 -s $SDSIZE | dd  bs=1M conv=sync,noerror iflag=fullblock | gzip > $OFILE
	else
		echo -e "${green}No backup compression${NC}${normal}"
		sudo pv -tpreb /dev/mmcblk0 -s $SDSIZE | dd of=$OFILE bs=1M conv=sync,noerror iflag=fullblock
fi

# Wait for DD to finish and catch result
BACKUP_SUCCESS=$?

# Start services again that where shutdown before backup process
startServices

# If command has completed successfully, delete previous backups and exit
if [ $BACKUP_SUCCESS =  0 ];
then
      echo -e "${green}${bold}GardenCam backup process completed! FILE: $OFILE${NC}${normal}" | tee -a $LOGFILE
      echo -e "${yellow}Removing backups older than $RETENTIONPERIOD days${NC}" | tee -a $DIR/backup.log
      sudo find $DIR -maxdepth 1 -name "*.img" -o -name "*.gz" -mtime +$RETENTIONPERIOD -exec rm {} \;
      echo -e "${cyan}If any backups older than $RETENTIONPERIOD days were found, they were deleted${NC}" | tee -a $LOGFILE

 
 	  if [ $POSTPROCESS = 1 ] ;
	  then
			postProcessSucess
	  fi
	  exit 0
else 
    # Else remove attempted backup file
     echo -e "${red}${bold}Backup failed!${NC}${normal}" | tee -a $LOGFILE
     sudo rm -f $OFILE
     echo -e "${purple}Last backups on Network Drive:${NC}" | tee -a $LOGFILE
     sudo find $DIR -maxdepth 1 -name "*.img" -exec ls {} \;
     exit 1
fi
