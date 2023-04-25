#!/bin/bash
targetsDir=/tmp/GenTargets/Targets/
destroyDir=/tmp/GenTargets/Destroy/
zrdnFile=temp/zrdn1.txt
lastTargetsFile=temp/lastTargetsZrdn1.txt
temp=temp/tempFileZrdn1.txt
attack=temp/attackZrdn1.txt
destroyDirContent=temp/destroyDirContentZrdn1

zrdnX=6400000
zrdnY=3600000
zrdnR=600000

rockets=20
printNoRockets=1

get_speed() {
	speed=`echo "sqrt(($1-$3)^2+($2-$4)^2)" | bc`
}

: >$zrdnFile
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

		get_speed $zrdnX $zrdnY $X $Y
		if (( $speed < $zrdnR ))
		then
			lastInfo=$(grep $targetID $zrdnFile)
			if [[ $lastInfo == "" ]]
			then
				echo "$targetID 0 0 $X $Y" >> $zrdnFile
				continue
			fi
			isSecond=$(grep "$targetID 0 0" $zrdnFile)
			lastX=`echo $lastInfo | cut -f 4 -d " "`
			lastY=`echo $lastInfo | cut -f 5 -d " "`
			sed "/$targetID/d" $zrdnFile > $temp
			cat $temp > $zrdnFile
			echo "$targetID $lastX $lastY $X $Y " >> $zrdnFile
			get_speed $lastX $lastY $X $Y
			if (( $speed < 1000 ))
			then
				if (( $speed >= 250 ))
				then
					targetName="Крылатая ракета"
				else
					targetName="Самолёт"
				fi
				alreadyAttacked=`grep $targetID $destroyDirContent 2>/dev/null`
				if [[ $alreadyAttacked == "" ]]
				then
					foundAttackedTarget=`grep $targetID $attack`
					if [[ $foundAttackedTarget == "" ]]
					then
						if [[ $isSecond != "" ]]
						then
							echo "Обнаружена цель $targetName ID:$targetID с координатами $X $Y"
						fi
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
						echo "Противоракеты в ЗРДН закончились"
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