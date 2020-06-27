#!/bin/bash
# syntax: measure-image-multiple.sh <CONTAINERIMAGE> <NUMBEROFTESTS> (must be non-interactive!)

if [ -z "$2" -o -z "$1" ]
then
    echo "Syntax: $0 <noninteractive-containerimage> <numberoftests>"
    exit 1
fi

#Get container name
IMAGE=$1
autoname=autostats$$

#Create file with the container name
FILE="$autoname-results".dat
:> $FILE

for i in `seq 1 $2`;
do
    (docker run --name $autoname $IMAGE & ./stats.sh $autoname); docker rm $autoname
done  
