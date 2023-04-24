#!/bin/bash
targetsDir=/tmp/GenTargets/Targets/
destroyDir=/tmp/GenTargets/Destroy/
sproFile=temp/spro.txt
lastTargetsFile=temp/lastTargetsSpro.txt
temp=temp/tempFileSpro.txt
attack=temp/attackSpro.txt
destroyDirContent=temp/destroyDirContentSpro

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
while :
do
	sleep 0.5
	ls $DestroyDir > $destroyDirContent
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
					#echo "$targetID x1=$lastX y1=$lastY x2=$X y2=$Y spd=$speed"
					foundAttackedTarget=`grep $targetID $attack`
					if [[ $foundAttackedTarget == "" ]]
					then
						echo "Обнаружена цель ID:$targetID с координатами $X $Y"
					else
						echo "Промах по цели ID:$targetID"
					fi
					if [[ $rockets > 0 ]]
					then
						let rockets=$rockets-1
						echo "Стрельба по цели ID:$targetID"
						if [[ $foundAttackedTarget == "" ]]
						then
							echo "$targetID" >> $attack
						fi
						: >$destroyDir$targetID
					elif [[ $printNoRockets == 1 ]]
					then
						echo "Противоракеты в СПРО закончились"
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
			echo "Цель ID:$targ уничтожена"
			sed "/$targ/d" $attack > $temp
			cat $temp > $attack
		fi
	done
done