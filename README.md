# GardenCam

This repository contains the process and scripts that I used to create a Raspberry Pi-based time-lapse camera for my indoor garden.

## Motivation

I wanted to document all of this for replicability.

## Screenshots

Include demo screenshot.

## Getting Started

These instructions will help you to get a version of this project up and running on your local machine.

### Prerequisites

#### Hardware

Raspberry Pi Zero W 
PiCamera v2.1 module
Pi Zero Camera connector cable
32GB SanDisk Extreme MicroSD card
2A 5v power adapter

#### Setting Up Your Raspberry Pi Zero

1. Write [Raspbian Strech Lite](https://www.raspberrypi.org/downloads/raspbian/) to your MicroSD card by your preferred means (I use [Etcher](https://etcher.io) on Mac)
2. Open boot volume on Mac
3. Create an ssh file to [tell the Pi to enable SSH](https://www.raspberrypi.org/documentation/remote-access/ssh/) when it boots up by default: `sudo touch /Volumes/boot/ssh`
4. Create a wpa_supplicant.conf file to tell the Pi to connect to your WiFi network on boot. Create a new file with that title in the boot volume, with the contents below:
```
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=CA

network={
        ssid="YOUR_SSID"
        psk="YOUR_PASSWORD"
        key_mgmt=WPA-PSK
}
```
5. Eject the microSD card, load it into the Raspberry Pi, and plug it in.
6. Find the Raspberry Pi's IP address using the command `sudo nmap -sP 192.168.1.0/24`
7. Once found, log into RPi: ssh pi@[IP-ADDRESS-HERE]//(the default password is raspberry). 

#### Configure your Raspberry Pi Zero

1. Edit Raspberry Pi config: 
	- `sudo raspi-config`
	- Change default password
	- Set a hostname
	- Go to Interfacing Options >> enable camera 
	- Set locale
	- Set timezone
	- Set keyboard country
2. Now update, upgrade and reboot the Pi: `sudo apt-get update -y`, `sudo apt-get upgrade -y`, `sudo reboot`.

At this point I would recommend setting up a static IP for your GardenCam. You can do this through `/etc/network/interfaces` within the Pi, but I found it easier to just create a static IP through my router (running AsusWRT Merlin).

#### Saving Energy

In order to save energy it is possible to turn off the Pi Zero's onboard ACT LED, Bluetooth, and HDMI port. Turning off the LED will also ensure that it does not disturb your plants night cycle. 

##### Disable the ACT LED

Raspberry Pi Zero's values are opposite those on most Raspberry Pis, and it only has one LED, led0 (labeled 'ACT' on the board). The LED defaults to on (brightness 0), and turns off (brightness 1) to indicate disk activity.

Add the following lines to `/boot/config.txt`:
```
# Disable ACT LED
dtparam=act_led_trigger=none
dtparam=act_led_activelow=on
start_x=1
gpu_mem=128
```

##### Disable Bluetooth

Edit `/etc/rc.local` and add the following lines above exit 0:
```
# Disable Bluetooth
dtoverlay=pi3-disable-bt
```

##### Disable HDMI at Boot

Edit `/etc/rc.local` and add the following lines above exit 0:
```
# Disable HDMI
/usr/bin/tvservice -o
```

Add this hdmi_blanking setting to `/boot/config.txt`:
```
hdmi_blanking=1
```

#### Mount Network Drive

Create a folder in your Raspberry Pi's home directory to mount the network drive in.
```
cd ~
sudo mkdir NAS
cd NAS
sudo mkdir share
cd ..
```

We will enable Raspbian's ability to 'lock' files when they are being accessed by someone in order to protect them from corruption. You do this by enabling the 'rpcbind' service, which is not on by default:
```
sudo update-rc.d rpcbind enable
```

Now we will mount the network drive to the newly created share directory. Make sure that you have the login creditionals that you use to access your NAS or server. If you're using an external harddrive attached via USB to your router the creditionals will be your normal gateway login username and password. Run the following commands to mount the drive:
```
sudo mount -t cifs -o username=YourUsername,password=YourPassword //SERVERNAME/DIRECTORY NAS/share
```
Make sure to change all of the variables: YourUsername, YourPassword, SERVERNAME, and DIRECTORY as appropriate. Your username and password will be the creditionals you use to log in to your NAS or networked computer. You can replace "SERVERNAME" with the name or IP address of your NAS or networked computer.

Check that this worked by browsing the mount point on your Pi:
```
cd /home/pi/NAS/share
ls
```
If you see whatever files exist in the shared directory on your NAS or server then it worked. 

##### Make Raspberry Pi Automount Network Drive on Boot

Run the following command to edit the /etc/fstab file:
```
sudo nano /etc/fstab
```
Navigate to the bottom of the file and add this (changing the variables as appropriate):
```
//SERVERNAME/Directory /home/pi/NAS/share cifs username=YourUsername,password=YourPassword 0 0
```
As usual with nano, press Ctrl+X to exit, responding 'Y' to whether you want to save, and press 'Return', and your share should now automount at boot.

### Set up Camera and Upload Scripts

Create directory to store images
```
cd ~
sudo mkdir /home/pi/gardencam
cd garden cam
sudo mkdir /images
```
Download the camera script and make it executable. 
```
sudo wget -O /home/pi/camera.sh https://raw.githubusercontent.com/xthursdayx/GardenCam/raw/master/camera.sh

sudo chmod +x /home/pi/gardencam/camera.sh
```

Edit the the `raspistill` settings in the script to reflect your desired photo qualities: `sudo nano camera.sh`. For more information check out the [Camera Module documentation](https://www.raspberrypi.org/documentation/raspbian/applications/camera.md) on raspberrypi.org. By default the script uses the settings `raspistill -md 4 -q 75 -hf -vf -o /home/pi/gardencam/images/$COMPDATE.jpg` which means that raspistill captures in resolution mode (-md) 4 or 1640x1232, 75% quality (-q), flips the image both horizontally (-hf) and vertically (-vf), and outputs (-o) to the listed file location. 

Create logs directory and camera log.
```
cd ~
sudo mkdir /home/pi/logs
sudo touch /home/pi/logs/camera.log
```

#### Set up crontab to run camera.sh

Edit the Pi's crontab by running `sudo crontab -e` and add the following to the end of the file:
```
# take a picture every 10 mins during light cycle (13:00-7:00)
*/10 13-23,0-6 * * * sh /home/pi/gardencam/camera.sh 2>&1
```

#### Set up automatic upload script

Download the upload script and make it executable. 
```
sudo wget -O /home/pi/upload.sh https://raw.githubusercontent.com/xthursdayx/GardenCam/raw/master/upload.sh

sudo chmod +x /home/pi/upload.sh
```
Create upload log.
```
sudo touch /home/pi/logs/upload.log
```

Edit crontab `sudo crontab -e` and add these lines to the end of the file:
```
# Upload all new images to network drive daily at end of light cycle
5 7 * * * sh /home/pi/upload.sh
```

### Set up Watchdog to Deal with Crashes

If you have a longer-term time-lapse project in mind, you need to defend against a crash that will stop the Pi from taking pictures. Otherwise, the Pi could go offline and you wouldn’t know until you tried to log in and check on it or noticed that there were no new images.

Watchdog can monitor for crashes and then reboot the Pi if/when they happen. The bcm2708_wdog seems to work for other Raspberry Pis, but the bcm2835_wdt module is the one that works with Raspberry Pi Zero.

First, install watchdog:
````
sudo modprobe bcm2835_wdt
sudo nano /etc/modules
````
Add the line “bcm2835_wdt” and save the file. (You can also run the command `echo "bcm2708_wdog" | sudo tee -a /etc/modules` to add this line without opening the modules file.)

Next, install the watchdog daemon:
````
sudo apt-get install watchdog chkconfig
sudo update-rc.d watchdog defaults
````
Configure the watchdog daemon:
```
sudo nano /etc/watchdog.conf
```
Uncomment the following two lines from this file:

1. watchdog-device = /dev/watchdog
2. the line that has `max-load-1` in it.
Save watchdog.conf and exit.

Enable and start the watchdog with:           
```
chkconfig watchdog on
sudo /etc/init.d/watchdog start
```

### Set up Auto-mailer to Report Crashes and Camera Failures

First download and edit the mailer script:
```
sudo wget -O /home/pi/mail_report.sh https://raw.githubusercontent.com/xthursdayx/GardenCam/raw/master/mail_report.sh
```
Edit the script (`sudo nano mail_report.sh`) and change the variable `YourEmailAddress@gmail.com` to reflect your desired email address. 

Save the file and make it executable using: `sudo chmod +x /home/pi/mail_report.sh`

Now install sendmail and mutt so the Raspberry Pi can send emails:
```
sudo apt-get install sendmail-bin
sudo apt-get install sensible-mda
apt-get install mutt
```
Setup mutt using a file called .muttrc. You can download a template for gmail accounts here:
```
cd ~
sudo wget -O https://raw.githubusercontent.com/xthursdayx/GardenCam/raw/master/muttrc-gmail.txt
sudo mv muttrc-gmail.txt .muttrc
```

Edit the first six uncommented lines of the .muttrc file to match your gmail account info: `sudo nano .muttrc`

```
# basic .muttrc for use with Gmail
# Change the following six lines to match your Gmail account details
set imap_user = "username@gmail.com"
set imap_pass = ""
set smtp_url = "smtps://username@smtp.gmail.com:465/"
set smtp_pass = ""
set from = "username@gmail.com"
set realname = "Firstname Lastname"
#
```

Place a copy of .muttrc in the /root folder:
```
sudo cp /home/pi/.muttrc /root
```

Edit cron to send the mail at each reboot `sudo crontab -e` and add the following lines:
```
# Send mail 60 seconds after reboot to allow time for wifi to connect
@reboot sleep 60 && sh /home/pi/mail_report.sh
```

Run `sudo ./mail_report.sh` to test the script first to see if you get a mail.

## Generating Time-Lapse Videos - JPEG > MP4

I use ffmpeg to generate time-lapse videos from the sequence of images collected by the GardenCam Pi. It is possible to do this on the Pi itself, but the server that hosts the uploaded images has much more processing power than the Raspberry Pi Zero, so I prefer to run ffmpeg there. I have written a script that prunes any images taken during the dark cycle (there should be none, but just in case), and then compiles the remaining images into an .mp4 timelapse video. The scrip will compile the video from all of the jpeg images located in your selected image directory, so you can decide whether to compile all images or a subset by moving some images out of this directory. It is also possible to designate a subset of images to compile through ffmpeg directly using the option `-pattern_type sequence` and the string `%0Nd`, which specifies the position of the characters representing a sequential number in each filename matched by the pattern. However I haven't needed to use this function so far. You can learn more bout this [here](https://www.ffmpeg.org/ffmpeg-all.html#toc-image2-1) 

The script uses the following ffmpeg settings:
```
ffmpeg -v error -r 18 -pattern_type glob -i '*.jpg' -c:v libx264 timelapse_$COMPDATE.mp4
```
What that means is that ffmpeg will run:
* `-v error` # log level, will show all errors, including ones which can be recovered from. 
* `-r 18` # output frame rate = 18 frames/second of video
* `-pattern_type glob -i '*.jpg'` # using all jpg files in the current directory
* `-c:v libx254` # using the libx264 video codec

## Additional Scripts

I wrote a script to automate the process of updating and upgrading the the Pi's OS, applications and firmware. 

You can download it and make it executable using these commands:
```
sudo wget -O /home/pi/update.sh https://raw.githubusercontent.com/xthursdayx/GardenCam/raw/master/update.sh

sudo chmod +x /home/pi/update.sh
```

I am also working on a script to automatically back up my Pi GardenCam once a week, using @aweijnitz's Raspberry Pi Backup script as a foundation. 

The work-in-progress can be downloaded using:
```
sudo wget -O /home/pi/backup.sh https://raw.githubusercontent.com/xthursdayx/GardenCam/raw/master/backup.sh

sudo chmod +x /home/pi/backup.sh
```

## Author

* [xthursdayx](https://github.com/xthursdayx)

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Jeff Geerling's Blog was invaluable in setting up this camera
	- <https://www.jeffgeerling.com/blog/2017/raspberry-pi-zero-w-headless-time-lapse-camera>
	- <https://www.jeffgeerling.com/blogs/jeff-geerling/controlling-pwr-act-leds-raspberry-pi>
* These blogs were useful in figuring out how to set up Watchdog, auto-reboot and mail notifications:
	- <https://ictoblog.nl/raspberry-pi/raspberry-pi-auto-reset-with-mail-notification>
	- <https://ictoblog.nl/raspberry-pi/daily-sma-bluetooth-report-via-e-mail>
	- <http://blog.ricardoarturocabral.com/2013/01/auto-reboot-hung-raspberry-pi-using-on.html>
	- <https://pi.gadgetoid.com/article/who-watches-the-watcher>
	- <https://www.domoticz.com/wiki/Setting_up_the_raspberry_pi_watchdog>
	- <https://quantixed.org/2018/12/04/experiment-zero-using-a-raspberry-pi-zero-camera/>
* These posts helped me attach my server as a local drive:
	- <https://www.codedonut.com/raspberry-pi/mount-network-share-raspberry-pi/>
	- <https://thepihut.com/blogs/raspberry-pi-tutorials/26871940-connecting-to-network-storage-at-boot>
* Backup script credits go to: @aweijnitz 's [pi_backup project](https://github.com/aweijnitz/pi_backup) which draws from:
	- <http://raspberrypi.stackexchange.com/questions/5427/can-a-raspberry-pi-be-used-to-create-a-backup-of-itself> and
	- <http://www.raspberrypi.org/phpBB3/viewtopic.php?p=136912>
* And of course all of the documentation at <https://www.raspberrypi.org>.