#!/bin/bash

echo "4" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio4/direction

while true
do
	if [[ $(pidof -x syncfiles.sh) ]]
	then
		echo "1" > /sys/class/gpio/gpio4/value
	else
		echo "0" > /sys/class/gpio/gpio4/value
	fi
	sleep .5
done
