 #!/bin/bash
#
# Small script to automatically send an email with the GardenCam reboots
#
##
mailreceiver=YourEmailAddress@gmail.com
today=$(date)
my_pi="GardenCam has rebooted!"
message="Your Pi has rebooted at $today"
echo $message > message.txt
mutt -e "set crypt_use_gpgme=no" -s "${my_pi}" ${mailreceiver} < message.txt && rm message.txt