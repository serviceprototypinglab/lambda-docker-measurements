#!/bin/bash
# script measurecost <CONTAINER>

if [ -z $1 ]
then
    echo "Syntax: $0 <container>"
    exit 1
fi

#Get container name
CONTAINER=$1
sleep 0.1
#Empty the stats aux file
:> aux
FILE="$CONTAINER-rawresults".csv
:> $FILE

#Obtain max memory usage
##get container's current status
status="$(docker inspect --format '{{.State.Status}}' $CONTAINER 2>/dev/null)"

while [ "$status" = "" ]
do
    status="$(docker inspect --format '{{.State.Status}}' $CONTAINER 2>/dev/null)" 
done

CONTAINERID="$(docker inspect --format '{{.Id}}' $CONTAINER)"

##wait for container to be running
while [ $status != "running" ]
do
    sleep 0.001
    status="$(docker inspect --format '{{.State.Status}}' $CONTAINER)"
done

##loop: while the container is running, get the current memory usage into the aux file
while [ $status != "exited" ]
do
    sleep 0.001
    ##mem="$(docker stats --no-stream --format "{{.MemUsage}}" $CONTAINER)"
    mem="$(cat /sys/fs/cgroup/memory/docker/$CONTAINERID/memory.usage_in_bytes)"
    echo $mem >> aux
    echo "$(date +"%T.%3N"),$mem" >> $FILE
    status="$(docker inspect --format '{{.State.Status}}' $CONTAINER)"
done

##sort memory usage file and get the highest value
MEMORY=$(sort -k 1 -h aux | tail -n 1)

##print found value
echo "Max memory usage: $MEMORY bytes"

#Obtain runtime in ms
START=$(date --date=$(docker inspect --format='{{.State.StartedAt}}' $CONTAINER) +%s%3N)
STOP=$(date --date=$(docker inspect --format='{{.State.FinishedAt}}' $CONTAINER) +%s%3N)
DURATION=$(($STOP-$START))
echo "Container runtime: $DURATION milliseconds"

./calculate-aws-cost.sh $CONTAINER 1000000 $DURATION $MEMORY 
