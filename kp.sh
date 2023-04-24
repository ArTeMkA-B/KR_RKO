#!/bin/bash


sproStatus=1
pingStatus=45
pingFile=temp/pingSpro
logFileSpro=logs/spro
logFileRls1=logs/rls1
logFileZrdn1=logs/zrdn1

: >$pingFile
: >$logFileSpro
: >$logFileRls1
: >$logFileZrdn1

$(spro.sh 1>$logFileSpro &)
$(rls1.sh 1>$logFileRls1 &)
$(zrdn1.sh 1>$logFileZrdn1 &)



while :
do
    sleep 0.5

    if [ $pingStatus -ge 45 ]; then
        pingStatus=0
        echo "ping" > $pingFile
    elif [ $pingStatus -ge 2 ]; then
        if [ "$(cat $pingFile)" == "live" ]; then
            sproStatus=1
        else 
            sproStatus=0
        fi

    fi

    




    ((pingStatus++))
done