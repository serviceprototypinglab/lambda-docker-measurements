#!/bin/bash
# syntax: download-sample-image.sh <size in mb>

if [ -z "$1" ]
then
    echo "Syntax: $0 <size in mb>"
    exit 1
fi

case $1 in
    1)
        curl -O https://u.cubeupload.com/q7nRis.jpg
        ;;
    2)
        curl -O https://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74393/world.topo.200407.3x5400x2700.jpg
        ;;
    5)
        curl -O https://upload.wikimedia.org/wikipedia/commons/2/26/Dresden_Garnisonkirche_gp.jpg
        ;;
    *)
        echo "No sample image of that size"
        ;;
esac