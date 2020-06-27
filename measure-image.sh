#!/bin/bash
# syntax: measure-image.sh <CONTAINERIMAGE> (must be non-interactive!) [<UHULLFILE.json>]

if [ -z "$1" ]
then
    echo "Syntax: $0 <noninteractive-containerimage> [<uhullfile.json>]"
    exit 1
fi

#Get container name
IMAGE=$1
autoname=autostats$$
UHULL=$2

(docker run --name $autoname $IMAGE & ./stats.sh $autoname $UHULL); docker rm $autoname
