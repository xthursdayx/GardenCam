# GardenCam

This repository contains the process and scripts that I used to create a Raspberry Pi-based time-lapse camera for my indoor garden.

## Motivation

I wanted to document all of this for replicability.

## Screenshots

Include demo screenshot.

## Getting Started

These instructions will help you to get a version of this project up and running on your local machine.

### Prerequisites

### Hardware

Raspberry Pi Zero W 
PiCamera v2.1 module
Pi Zero Camera connector cable
32GB SanDisk Extreme MicroSD card
CanaHut 2A 5v power adapter

### Setting Up Your Raspberry Pi

1. Write [Raspbian Strech Lite](https://www.raspberrypi.org/downloads/raspbian/) to your MicroSD card by your preferred means (I use [Etcher](https://etcher.io) on Mac)
2. Open boot volume on Mac
3. Create an ssh file to [tell the Pi to enable SSH](https://www.raspberrypi.org/documentation/remote-access/ssh/) when it boots up by default: `touch /Volumes/boot/ssh`
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
5. Eject the microSD card, load into the Raspberry Pi, and plug RPi in.
6. Find the IP address the RPi is using using sudo nmap -sP 192.168.1.1/24
7. Log into RPi: ssh pi@[IP-ADDRESS-HERE]//(the default password is raspberry). 
8. Configure RPi: 
	- `sudo raspi-config`
	- Change default password
	- Set a hostname
	- Go to Interfacing Options >> enable camera 
	- Set locale
	- Set timezone
	- Set keyboard country
9. Now update, upgrade and reboot the RPi: `sudo apt-get update`, `sudo apt-get upgrade`, `sudo reboot`

At this point I would recommend setting up a static IP for your GardenCam. You can do this through DHCP within the RPi, but I found it easier to just create this static IP through my router (running AsusWRT Merlin)

### Saving energy

Disable the ACT LED
dtparam=act_led_trigger=none
dtparam=act_led_activelow=on
start_x=1
gpu_mem=128

Disable Bluetooth
dtoverlay=pi3-disable-bt

### Mount Network Drive

### Set up Time-Lapse script

# Setup crontab
Edit your crontab by by running `crontab -e` and adding the following to the end of the file:
```
# run flask web server @ 10.0.0.1:5000
@reboot python /home/pi/raspberry-pi-timelapse-camera/raspberry-pi-server/app.py

# take a picture every 1 min
* * * * * /home/pi/raspberry-pi-timelapse-camera/raspberry-pi-code/app.py
```

### Set up Automatic upload script

### Set up Watchdog and Auto-mailer


## Author

* **[xthursdayx]**(https://github.com/xthursdayx)

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE.md](LICENSE.md) file for details

GNU GPLv3 © [xthursdayx]()

## Acknowledgments

* [Jeff Geerling's Blog was invaluable in setting up this camera](https://www.jeffgeerling.com/blog/2017/raspberry-pi-zero-w-headless-time-lapse-camera)