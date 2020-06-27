#!/bin/bash
# script measurecost <CONTAINER>

if [ -z $1 ]
then
    echo "Syntax: $0 <container>"
    exit 1
fi

#Get container name
CONTAINER=$1
sleep 0.01
#Empty the stats aux file
:> aux
FILE="$CONTAINER-rawresults".csv
:> $FILE

#Obtain max memory usage
##get container's current status
#status="$(docker inspect --format '{{.State.Status}}' $CONTAINER 2>/dev/null)"

oldstatus=x
status=
while [ "$status" = "" ]
do
    status="$(docker inspect --format '{{.State.Status}}' $CONTAINER 2>/dev/null)" 
    if [ "$status" != "$oldstatus" ]
    then
    	echo "init-status ($status)"
	oldstatus=$status
    fi
done

CONTAINERID="$(docker inspect --format '{{.Id}}' $CONTAINER)"

##wait for container to be running
while [ $status != "running" ]
do
    sleep 0.001
    status="$(docker inspect --format '{{.State.Status}}' $CONTAINER)"
    echo "run-status ($status)"
done

echo "$(date --date=$(docker inspect --format='{{.State.StartedAt}}' $CONTAINER) +"%T.%3N"),0" >> $FILE

AWSMEMORY="$(cat /sys/fs/cgroup/memory/docker/$CONTAINERID/memory.limit_in_bytes)"

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

rm aux

if [ -z "$MEMORY" ]
then
    echo "Measurement failed"
    rm $FILE
    exit 1
fi

##print found value
echo "Max memory usage: $MEMORY bytes"

#Obtain runtime in ms
START=$(date --date=$(docker inspect --format='{{.State.StartedAt}}' $CONTAINER) +%s%3N)
STOP=$(date --date=$(docker inspect --format='{{.State.FinishedAt}}' $CONTAINER) +%s%3N)
DURATION=$(($STOP-$START))

echo "$(date --date=$(docker inspect --format='{{.State.FinishedAt}}' $CONTAINER) +"%T.%3N"),0" >> $FILE

echo "Container runtime: $DURATION milliseconds"

DOCKERMEMORY="$(cat /sys/fs/cgroup/memory/docker/memory.limit_in_bytes)"

echo "--- old cost calculation"
if [ "$DOCKERMEMORY" -eq "$AWSMEMORY" ]
then
    ./calculate-aws-cost.sh $CONTAINER 1000000 $DURATION $MEMORY
else
    ./calculate-aws-cost.sh $CONTAINER 1000000 $DURATION $MEMORY false $AWSMEMORY
fi

echo "--- new cost calculation"
python3 calculator/costcalculator.py 1000000 $DURATION $MEMORY False
