#!/bin/bash
#syntax: calculate-aws-cost.sh <NREQUESTS> <DURATION> <MEMORY> [FREE]
# NREQUESTS is the number of requests to calculate the cost on
# DURATION is the duration of the function (in ms)
# MEMORY is the total memory in bytes allocated to the function. It will be rounded up to the nearest AWS value available
# FREE is a boolean indicating whether to consider the free AWS requests and computation time or not. By default is false

# Ceiling division function
ceildiv() {
    echo $((($1+$2-1)/$2));
}

#Set container arguments
NREQUESTS=$1
DURATION=$2
MEMORY="$(ceildiv $3 1000000)"

if [ -z $4 ]
then
    FREE=false
else
    FREE=$4
fi

#Set AWS values
AWS_REQUESTS="$(ceildiv $NREQUESTS 1000000)"
AWS_DURATION="$(ceildiv $DURATION 100)"

aux_mem=$(($MEMORY-128))
if [ "$aux_mem" -gt "0" ]
then
    aws_mult="$(ceildiv $aux_mem 64)"
else
    aws_mult=0
fi

AWS_MEMORY=$((128+$aws_mult*64))

while read mem freeseconds invocation freerequests compute
do
    if [ "$mem" = "$AWS_MEMORY" ]
    then
        FREE_TIER_SECONDS=$freeseconds
        COSTCOMPUTE=$invocation
        FREE_REQUESTS=$freerequests
        COSTINVOCATION=$compute
        break
    fi
done < aws_data/costs.dat

#Calculate cost
if [ "$FREE" = true ]
then
    # Calculate the cost with free requests and computation time
    aux_duration=$(bc <<< $AWS_DURATION*$AWS_REQUESTS*1000000-$FREE_TIER_SECONDS*10)
    aux_requests=$(($AWS_REQUESTS-$FREE_REQUESTS))
    
    AWS_COST=$(bc <<< $aux_duration*$COSTCOMPUTE+$aux_requests*$COSTINVOCATION)
else
    # Calculate the cost without free requests and computation time
    AWS_COST=$(bc <<< $AWS_DURATION*$AWS_REQUESTS*1000000*$COSTCOMPUTE+$AWS_REQUESTS*$COSTINVOCATION)
fi

#Print results
echo "The total cost for AWS Lambda for $AWS_REQUESTS million requests per month would be $`printf "%.2f" $AWS_COST`"

#Calculate waste
DURATION_WASTE=$(($AWS_DURATION*100-$DURATION))
MEMORY_WASTE="$(($AWS_MEMORY-$MEMORY))"

echo "$DURATION_WASTE milliseconds of computation time are being wasted."
echo "$MEMORY_WASTE MB of memory are being wasted"
