#!/bin/bash
# syntax: measure-image.sh <CONTAINERIMAGE> (must be non-interactive!)

if [ -z $1 ]
then
    echo "Syntax: $0 <noninteractive-containerimage>"
    exit 1
fi

#Get container name
IMAGE=$1
autoname=autostats$$

(docker run --name $autoname $IMAGE & ./stats.sh $autoname); docker rm $autoname
