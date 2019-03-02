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
6. Find the Raspberry Pi's IP address using the command `sudo nmap -sP 192.168.1.1/24`
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
2. Now update, upgrade and reboot the Pi: `sudo apt-get update -y`, `sudo apt-get upgrade -y`, `sudo reboot`

At this point I would recommend setting up a static IP for your GardenCam. You can do this through DHCP within the Pi, but I found it easier to just create a static IP through my router (running AsusWRT Merlin).

#### Saving energy

In order to save energy it is possible to turn off the Pi Zero's onboard ACT LED, Bluetooth, and HDMI port. Turning off the LED will also ensure that it does not disturb your plants night cycle. 

##### Disable the ACT LED

Raspberry Pi Zero's values are opposite those on most Raspberry Pis, and it only has one LED, led0 (labeled 'ACT' on the board). The LED defaults to on (brightness 0), and turns off (brightness 1) to indicate disk activity.

Add the following lines to your Pi's `/boot/config.txt` file and reboot:
```
# Disable ACT LED
dtparam=act_led_trigger=none
dtparam=act_led_activelow=on
start_x=1
gpu_mem=128
```

##### Disable Bluetooth

Edit the file `/etc/rc.local` and add the following lines above exit 0:
```
# Disable Bluetooth
dtoverlay=pi3-disable-bt
```

##### Disable HDMI at boot

Edit /etc/rc.local and add the following lines above exit 0:
```
# Disable HDMI
/usr/bin/tvservice -o
```

add hdmi_blanking setting to your /boot/config.txt I found the follwing settings here:
hdmi_blanking=0: HDMI Output will be blank when DPMS is triggered
hdmi_blanking=1: HDMI Output will be disabled when DPMS is triggered
hdmi_blanking=2: HDMI Output will be disabled on boot and can be enabled using the above listed commands.
But the official documentation does not mention hdmi_blanking=2 only the following 2 settings:
0   HDMI Output will blank instead of being disabled
1   HDMI Output will be disabled rather than just blanking
I think hdmi_blanking=1 should do what you want.


### Mount Network Drive

https://www.codedonut.com/raspberry-pi/mount-network-share-raspberry-pi/

At boot
https://thepihut.com/blogs/raspberry-pi-tutorials/26871940-connecting-to-network-storage-at-boot

### Set up Time-Lapse script

chmod +x camera.sh

# Setup crontab
Edit your crontab by by running `crontab -e` and adding the following to the end of the file:
```
# run flask web server @ 10.0.0.1:5000
@reboot python /home/pi/raspberry-pi-timelapse-camera/raspberry-pi-server/app.py

# take a picture every 1 min
* * * * * /home/pi/raspberry-pi-timelapse-camera/raspberry-pi-code/app.py
```

### Set up Automatic upload script

### Set up Watchdog to deal with crashes

https://quantixed.org/2018/12/04/experiment-zero-using-a-raspberry-pi-zero-camera/

set up a watchdog to monitor for crashes and then reboot the Pi if/when it happens. 

Install watchdog

````
sudo modprobe bcm2835_wdt
sudo nano /etc/modules
````

Add the line “bcm2835_wdt” and save the file

Next I installed the watchdog daemon

Install the watchdog daemon

````
sudo apt-get install watchdog chkconfig
chkconfig watchdog on
sudo update-rc.d watchdog defaults
sudo /etc/init.d/watchdog start
````
Configure the watchdog daemon
```
sudo nano /etc/watchdog.conf
```
Uncomment two lines from this file:
1. watchdog-device = /dev/watchdog
2. the line that had max-load-1 in it
Save the watchdog.conf file.


And enable/start it with:           
sudo systemctl enable watchdog
sudo systemctl start watchdog.service

sudo service watchdog start

### Set up Auto-mailer to report reboot

Mail notification
Login to the Raspberry Pi using SSH
We will first create the bash file to send the mail:
$  cd /home/pi/bin
$ sudo nano mailIP
Add this in the mailIP file:
```
#!/bin/sh
mailreciever=YOURMAIL
today=$(date)
my_ip=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{print $1}'`
my_pi="Blue RaspberryPi has rebooted! "
message="Your Pi has rebooted at $today. Current IP address = $my_ip"
echo $message > message.txt
mutt -s "${my_pi}" ${mailreciever} < message.txt
```
save the file and make it executable using:
sudo chmod 0755 mailIP

Test the mailIP script first to see if you get a mail!

Now we want to make sure that the script gets run when the Raspberry Pi boots. 

Edit /etc/rc.local:
```
$ sudo nano /etc/rc.local
```
Add this above the exit 0 line:

$ sudo /home/pi/bin/mailIP & 

Make sure the rc.local can be executed:

sudo chmod 0755 /etc/rc.local

I had to put a copy of .muttrc in the /root folder for this to work:
$ sudo bash
# cp /home/pi/.muttrc /root

Now we are going to install sendmail and  mutt so we can send the mails
sudo apt-get install sendmail-bin
sudo apt-get install sensible-mda
 apt-get install mutt

We need to setup mutt. This is done using a file called .muttrc
You can download an example from here
# cd /home/pi
# wget http://cache.gawker.com/assets/images/lifehacker/2010/06/muttrc-gmail.txt
# mv muttrc-gmail.txt .muttrc
# nano .muttrc

```
create the file .muttrc with the following content: (vi .muttrc or nano .muttrc)
# basic .muttrc for use with Gmail
# Change the following six lines to match your Gmail account details
set imap_user = "username@gmail.com"
set imap_pass = ""
set smtp_url = "smtps://username@smtp.gmail.com:465/"
set smtp_pass = ""
set from = "username@gmail.com"
set realname = "Firstname Lastname"
#
# # Change the following line to a different editor you prefer.
set editor = 'vim + -c "set textwidth=72" -c "set wrap"'
# Basic config
set folder = "imaps://imap.gmail.com:993"
set spoolfile = "+INBOX"
set imap_check_subscribed=yes
set hostname = gmail.com
set mail_check = 120
set timeout = 300
set imap_keepalive = 300
set postponed = "+[GMail]/Drafts"
set header_cache=~/.mutt/cache/headers
set message_cachedir=~/.mutt/cache/bodies
set certificate_file=~/.mutt/certificates
set move = no
set include
set sort = 'threads'
set sort_aux = 'reverse-last-date-received'
set auto_tag = yes
set pager_index_lines = 10
ignore "Authentication-Results:"
ignore "DomainKey-Signature:"
ignore "DKIM-Signature:"
hdr_order Date From To Cc
alternative_order text/plain text/html *
auto_view text/html
bind editor <Tab> complete-query
bind editor ^T complete
bind editor <space> noop
# # Gmail-style keyboard shortcuts
macro index,pager am "<enter-command>unset trash\n <delete-message>" "Gmail archive message" # different from Gmail, but wanted to keep "y" to show folders.
macro index,pager d "<enter-command>set trash=\"imaps://imap.googlemail.com/[GMail]/Bin\"\n <delete-message>" "Gmail delete message"
macro index,pager gi "<change-folder>=INBOX<enter>" "Go to inbox"
macro index,pager ga "<change-folder>=[Gmail]/All Mail<enter>" "Go to all mail"
macro index,pager gs "<change-folder>=[Gmail]/Starred<enter>" "Go to starred messages"
macro index,pager gd "<change-folder>=[Gmail]/Drafts<enter>" "Go to drafts"
macro index,pager gl "<change-folder>?" "Go to 'Label'" # will take you to a list of all your Labels (similar to viewing folders).
```

edit the first lines to setup your gmail account info

Create a mail script in /home/pi:
cd /home/pi/
sudo nano mailIP
Paste the following (repalce YOURMAIL with full email address of where you want the email sent i.e. fred@hotmail.com):
 #!/bin/sh
 mailreceiver=YOURMAIL
 today=$(date)
 #my_ip=`ifconfig | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{print $1}'`
 my_ip=`wget -q -O - checkip.dyndns.org|sed -e 's/.*Current IP Address: //' -e 's/<.*$//'`
 my_pi="Domoticz RaspberryPi has rebooted! "
 message="Your Pi has rebooted at $today. Current IP address = $my_ip"
 echo $message > message.txt
 mutt -s "${my_pi}" ${mailreceiver} < message.txt && rm message.txt
The commented line fetches the internal ip, example fetches external ip.
Make sure the mailIP can be executed:
sudo chmod +x mailIP
Test the script by running it: 
./mailIP
Setup rc.local to send the mail at each reboot: Edit /etc/rc.local:
sudo nano /etc/rc.local
Add this above the exit 0 line:
sudo /home/pi/mailIP & 
Make sure the rc.local can be executed:
sudo chmod 0755 /etc/rc.local
sudo bash
cp /home/pi/.muttrc /root


Edit the first six lines of the file to match your gmail account info.

Next we will create a daily cronjob to mail you the report
Upload the [mail_report] file to /var/www/smareport
Make sure you edit the mailreceiver and rename the file to remove the .txt!
Upload the [message.txt] file to /var/www/smareport (this one you don’t need to rename!)
# chmod 0754 mail_report
# crontab -e
Add this:
0 21 * * * /var/www/smareport/mail_report >/dev/null 2>&1
Ctrl+X
Yes
Enter
Done!



## Author

* **[xthursdayx]**(https://github.com/xthursdayx)

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Jeff Geerling's Blog was invaluable in setting up this camera
	- <https://www.jeffgeerling.com/blog/2017/raspberry-pi-zero-w-headless-time-lapse-camera>
	- <https://www.jeffgeerling.com/blogs/jeff-geerling/controlling-pwr-act-leds-raspberry-pi>
* These blogs were useful in figuring out how to set up auto-reboot and mail notifications:
	- <https://ictoblog.nl/raspberry-pi/raspberry-pi-auto-reset-with-mail-notification>
	- <https://ictoblog.nl/raspberry-pi/daily-sma-bluetooth-report-via-e-mail>
	- <http://blog.ricardoarturocabral.com/2013/01/auto-reboot-hung-raspberry-pi-using-on.html>
	- <https://pi.gadgetoid.com/article/who-watches-the-watcher>
	- <https://www.domoticz.com/wiki/Setting_up_the_raspberry_pi_watchdog>
* Backup script credits go to: @aweijnitz 's [pi_backup project](https://github.com/aweijnitz/pi_backup) which draws from:
	- <http://raspberrypi.stackexchange.com/questions/5427/can-a-raspberry-pi-be-used-to-create-a-backup-of-itself> and
	- <http://www.raspberrypi.org/phpBB3/viewtopic.php?p=136912>