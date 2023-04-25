#!/bin/bash
targetsDir=/tmp/GenTargets/Targets/
destroyDir=/tmp/GenTargets/Destroy/
sproFile=temp/spro.txt
lastTargetsFile=temp/lastTargetsSpro.txt
temp=temp/tempFileSpro.txt
attack=temp/attackSpro.txt
destroyDirContent=temp/destroyDirContentSpro.txt

log=messages/spro.txt
pingFile=messages/pingSpro.txt

sproX=3250000
sproY=3350000
sproR=3100000

rockets=10
printNoRockets=1

get_speed() {
	speed=`echo "sqrt(($1-$3)^2+($2-$4)^2)" | bc`
}

: >$sproFile
: >$lastTargetsFile
: >$temp
: >$attack
: >$destroyDirContent
: >$log
while :
do
	sleep 0.5
	if [[ $(cat $pingFile) == "ping" ]]
	then
		echo "live" > $pingFile
	fi
	ls $destroyDir > $destroyDirContent
	for fileName in $(ls -t $targetsDir | head -30 2>/dev/null)
	do
		foundFile=`grep $fileName $lastTargetsFile 2>/dev/null`
		targetID=${fileName:12:6}

		if [[ $foundFile != "" ]]
		then
			continue
		fi
		
		echo $fileName >> $lastTargetsFile
		coords=`cat ${targetsDir}$fileName 2>/dev/null`
		X_with_letter=`expr match "$coords" '\(X[0-9]*\)'`
		X=${X_with_letter:1}
		Y_with_letter=`expr match "$coords" '.*\(Y[0-9]*\)'`
		Y=${Y_with_letter:1}

		get_speed $sproX $sproY $X $Y
		if (( $speed < $sproR ))
		then
			lastInfo=$(grep $targetID $sproFile)
			if [[ $lastInfo == "" ]]
			then
				echo "$targetID 0 0 $X $Y" >> $sproFile
				continue
			fi
			isSecond=$(grep "$targetID 0 0" $sproFile)
			lastX=`echo $lastInfo | cut -f 4 -d " "`
			lastY=`echo $lastInfo | cut -f 5 -d " "`
			sed "/$targetID/d" $sproFile > $temp
			cat $temp > $sproFile
			echo "$targetID $lastX $lastY $X $Y " >> $sproFile
			get_speed $lastX $lastY $X $Y
			if (( $speed >= 8000 ))
			then
				alreadyAttacked=`grep $targetID $destroyDirContent 2>/dev/null`
				if [[ $alreadyAttacked == "" ]]
				then
					foundAttackedTarget=`grep $targetID $attack`
					if [[ $foundAttackedTarget == "" ]]
					then
						if [[ $isSecond != "" ]]
						then
							echo "Обнаружена цель ID:$targetID с координатами $X $Y" >> $log
						fi
					else
						echo "Промах по цели ID:$targetID" >> $log
					fi
					if [[ $rockets > 0 ]]
					then
						let rockets=$rockets-1
						echo "Стрельба по цели ID:$targetID" >> $log
						if [[ $foundAttackedTarget == "" ]]
						then
							echo "$targetID" >> $attack
						fi
						: >$destroyDir$targetID
					elif [[ $printNoRockets == 1 ]]
					then
						echo "Противоракеты в СПРО закончились" >> $log
						printNoRockets=0
					fi
				fi
			fi
		fi
	done
	for targ in $(cat $attack)
	do
		ls -t $targetsDir | head -30 > $temp 2>/dev/null
		foundAttackedTarget=`grep $targ $temp 2>/dev/null`
		if [[ $foundAttackedTarget == "" ]]
		then
			echo "Цель ID:$targ уничтожена" >> $log
			sed "/$targ/d" $attack > $temp
			cat $temp > $attack
		fi
	done
done