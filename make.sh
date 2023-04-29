#!/bin/bash

# CC65_HOME=..
# DEBUG=yes

SDK_PATH="../orix-sdk"
PROGNAME="$(basename `pwd`)"

make configure && make clean

START_ADDR=0x0800 make

if [ $? -eq 0 ]
then
	mv build/bin/${PROGNAME} build/bin/${PROGNAME}-0800

	START_ADDR=0x0900 make

	if [ $? -eq 0 ]
	then
		mv build/bin/${PROGNAME} build/bin/${PROGNAME}-0900

		python3 ${SDK_PATH}/bin/relocbin.py3 -2 -o build/bin/${PROGNAME} build/bin/${PROGNAME}-0800 build/bin/${PROGNAME}-0900

		if [ $? -eq 0 ]
		then
			rm build/bin/${PROGNAME}-0800 build/bin/${PROGNAME}-0900
		fi
	fi
fi

