#!/bin/bash

period=10
time=0

pingFile=( messages/pingSpro.txt messages/pingRls1.txt messages/pingRls2.txt messages/pingRls3.txt messages/pingZrdn1.txt messages/pingZrdn2.txt messages/pingZrdn3.txt )
logFile=( logs/spro.txt logs/rls1.txt logs/rls2.txt logs/rls3.txt logs/zrdn1.txt logs/zrdn2.txt logs/zrdn3.txt )
messFile=( messages/spro.txt messages/rls1.txt messages/rls2.txt messages/rls3.txt messages/zrdn1.txt messages/zrdn2.txt messages/zrdn2.txt )
objectName=( "СПРО" "РЛС1" "РЛС2" "РЛС3" "ЗРДН1" "ЗРДН2" "ЗРДН3" )
status=( 0 0 0 0 0 0 0 )
N_spro=( 0 0 0 0 0 0 0 )
: >$pingFile
: >$logFile


pingStatus=$period
mainLog=logs/mainLog.txt
tempNewData=temp/tempNewDataSpro
: >$mainLog

getTime() {
    time=$(date +"%d.%m %H:%M:%S")
}

printLog() {
    echo $1 >> $2
    echo $1 >> $mainLog
}

while :
do
    if [ $pingStatus -ge $period ]; then
        pingStatus=0
        echo "ping" > $pingFile
    elif [ $pingStatus -ge 3 ]; then
        if [ "$(cat $pingFile)" == "live" ]; then
            if [[ $status == 0 ]]
            then
                getTime
                printLog "$time $objectName работоспособность восстановлена" $logFile
            fi
            status=1

            currSize=$(cat $messFile | wc -l)
            if [[ $currSize -gt $N_spro ]]
            then
                cat $messFile | tail -n $(expr $currSize - $N_spro) > $tempNewData
                while read line
                do
                    getTime
                    printLog "$time $objectName $line" $logFile
                done < $tempNewData
                N_spro=$currSize
            fi
        else
            if [[ $status == 1 ]]
            then
                getTime
                printLog "$time $objectName не работает" $logFile
            fi
            status=0
        fi
    fi


    ((pingStatus++))
    sleep 0.5
done