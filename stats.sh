#! /bin/bash
# script measurecost <CONTAINER>
#Get container name
CONTAINER=$1
sleep 0.1
#Empty the stats aux file
echo "" > aux
#Obtain max memory usage
##get container's current status
status="$(docker inspect --format '{{.State.Status}}' $CONTAINER)"
echo "$status"
##wait for container to be running
while [ $status != "running" ]
do
    sleep 0.1
    status="$(docker inspect --format '{{.State.Status}}' $CONTAINER)"
    echo "$status"
done
echo "$status"
##loop: while the container is running, get the current memory usage into the aux file
while [ $status != "exited" ]
do
    sleep 0.1
    docker stats --no-stream --format "{{.MemUsage}}" $CONTAINER >> aux
    status="$(docker inspect --format '{{.State.Status}}' $CONTAINER)"
done
##sort memory usage file and get the highest value
MEMORY=$(sort -k 1 -h aux | tail -n 1)
##print found value
echo 'max memory usage:' "$MEMORY"
#Obtain runtime in ms
START=$(date --date=$(docker inspect --format='{{.State.StartedAt}}' $CONTAINER) +%s%3N)
STOP=$(date --date=$(docker inspect --format='{{.State.FinishedAt}}' $CONTAINER) +%s%3N)
echo 'container runtime:' $(($STOP-$START)) milliseconds