#!/bin/bash
#syntax: calculate-aws-cost.sh <CONTAINER> <NREQUESTS> <DURATION> <MEMORY> [FREE]
# CONTAINER is the name of the container
# NREQUESTS is the number of requests to calculate the cost on
# DURATION is the duration of the function (in ms)
# MEMORY is the total memory in bytes allocated to the function. It will be rounded up to the nearest AWS value available
# FREE is a boolean indicating whether to consider the free AWS requests and computation time or not. By default is false

# Ceiling division function
ceildiv() {
    echo $((($1+$2-1)/$2));
}

#Set container arguments
NREQUESTS=$2
DURATION=$3
MEMORY="$(ceildiv $4 1000000)"

if [ -z $5 ]
then
    FREE=false
else
    FREE=$5
fi

#Set AWS values
#AWS_REQUESTS="$(ceildiv $NREQUESTS 1000000)" Counts only per million of requests
AWS_REQUESTS=$(bc <<< $NREQUESTS/1000000)
AWS_DURATION="$(ceildiv $DURATION 100)"

aux_mem=$(($MEMORY-128))
if [ "$aux_mem" -gt "0" ]
then
    aws_mult="$(ceildiv $aux_mem 64)"
else
    aws_mult=0
fi

AWS_MEMORY=$((128+$aws_mult*64))

while read mem freeseconds compute freerequests invocation
do
    if [ "$mem" = "$AWS_MEMORY" ]
    then
        FREE_TIER_SECONDS=$freeseconds
        COSTCOMPUTE=$compute
        NET_COSTCOMPUTE=$(bc -l <<< "$compute*$MEMORY/$AWS_MEMORY")
        FREE_REQUESTS=$freerequests
        COSTINVOCATION=$invocation
        break
    fi
done < aws_data/costs.dat

#Calculate cost
if [ "$FREE" = true ]
then
    # Calculate the cost with free requests and computation time
    aux_duration=$(bc <<< $AWS_DURATION*$AWS_REQUESTS*1000000-$FREE_TIER_SECONDS*10)
    aux_requests=$(($AWS_REQUESTS-$FREE_REQUESTS))
    aux_net_duration=$(bc <<< $DURATION*$AWS_REQUESTS*10000-$FREE_TIER_SECONDS*10)
    
    AWS_COST=$(bc <<< $aux_duration*$COSTCOMPUTE+$aux_requests*$COSTINVOCATION)
    AWS_NETCOST=$(bc <<< $aux_net_duration*$NET_COSTCOMPUTE+$aux_requests*$COSTINVOCATION)
else
    # Calculate the cost without free requests and computation time
    AWS_COST=$(bc <<< $AWS_DURATION*$AWS_REQUESTS*1000000*$COSTCOMPUTE+$AWS_REQUESTS*$COSTINVOCATION)
    AWS_NETCOST=$(bc <<< $DURATION*$AWS_REQUESTS*10000*$NET_COSTCOMPUTE+$AWS_REQUESTS*$COSTINVOCATION)
fi

OVERHEAD_COST=$(bc <<< $AWS_COST-$AWS_NETCOST)

#Print results
echo "The total cost for AWS Lambda for $AWS_REQUESTS million requests per month would be $`printf "%.2f" $AWS_COST`"
echo "The net cost would be $`printf "%.2f" $AWS_NETCOST`, and the overhead cost $`printf "%.2f" $OVERHEAD_COST`"

#Calculate waste
DURATION_WASTE=$(($AWS_DURATION*100-$DURATION))
MEMORY_WASTE="$(($AWS_MEMORY-$MEMORY))"

echo "$DURATION_WASTE milliseconds of computation time are being wasted."
echo "$MEMORY_WASTE MB of memory are being wasted"

#Write results into a file
FILE="$1-results".dat
#Time(ms)    Memory(MB)    AWS Time(ms)    AWS Memory(ms)    AWS Cost($)    Net cost($)    Overhead cost($)
echo "$DURATION $MEMORY $AWS_DURATION   $AWS_MEMORY $AWS_COST    $AWS_NETCOST    $OVERHEAD_COST" >> $FILE
