#!/bin/bash

fn=Dresden_Garnisonkirche_gp.jpg

if [ ! -f ref-data/$fn ]
then
	cd ref-data
	./download-sample-image.sh 5
	cd ..
fi

for i in `seq 1 10`
do
	cp ref-data/$fn ref-data/sample.jpg
	./measure-image.sh "-v $PWD/ref-data:/d/ futils/resize sample.jpg 50%"
	rm ref-data/sample.jpg
done
