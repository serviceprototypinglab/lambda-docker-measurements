#!/bin/bash
# syntax: measure-image-hull.sh True(default)|False # indicating whether shuffling should be used

if [ "$1" != "False" ]
then
	fn[1]=q7nRis.jpg
	fn[2]=world.topo.200407.3x5400x2700.jpg
fi
fn[5]=Dresden_Garnisonkirche_gp.jpg

for num in 1 2 5
do
	if [ ! -f ref-data/${fn[$num]} ]
	then
		cd ref-data
		./download-sample-image.sh $num
		cd ..
	fi
done

for i in `seq 1 20`
do
	pic=`printf "%s\n" ${fn[@]} | shuf | head -1`
	echo $pic

	cp ref-data/$pic ref-data/sample.jpg
	./measure-image.sh "-v $PWD/ref-data:/d/ futils/resize sample.jpg 50%"
	rm ref-data/sample.jpg
done
