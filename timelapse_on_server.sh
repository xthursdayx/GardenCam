#!/usr/bin/env bash
#
COMPDATE=$(date +"%Y-%m-%d_%H%M")
RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color
IMAGE_DIR='LOCATION/OF/IMAGES' # image directory
VID_DIR='/LOCATION/OF/VIDEO/OUTPUT' # video directory
ffmpeg_DIR='/LOCATION/WHERE/FFMPEG/IS/LOCATED' # ffmpeg directory

echo "********************************"
echo " "
echo "BEGINNING TIMELAPSE SCRIPT"
echo " "

# Move to the location of the images.
cd $IMAGE_DIR

# Images taken during the night-cycle are dark and are usually less than 1.5 MB. This will erase them.
echo " "
echo "PRUNING DARK IMAGES"
echo " "
if find . -name "*.jpg" -size -1000k -delete; then
	echo -e "${GREEN}PRUNING SUCCESSFUL${NC}"
	echo " "
else
	echo -e "${RED}PRUNING ERROR${NC}"
	echo " "
fi

# Compile time lapse video from remaining images. 
echo " "
echo "GENERATING TIMELAPSE VIDEO"
echo " "
if ${ffmpeg_DIR}ffmpeg -v error -framerate 18 -pattern_type glob -i '*.jpg' -c:v libx264 timelapse_$COMPDATE.mp4; then
	echo " "
	echo -e "${GREEN}VIDEO GENERATION SUCCESSFUL${NC}"
	echo " "
else
	echo " "
	echo -e "${RED}VIDEO GENERATION UNSUCCESSFUL${NC}"
	echo " "
fi

# Move final video output to videos directory.
find . -name "*.mp4" -maxdepth 1 -exec mv {} $VID_DIR \;
echo " "

echo " "
echo "TIMELAPSE SCRIPT COMPLETE"
echo " "
echo "********************************"

#finish
exit 0;
