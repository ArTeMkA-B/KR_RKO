#!/bin/bash
targetsDir=/tmp/GenTargets/Targets/
rlsFile=/tmp/rls1.txt
lastTargetsFile=/tmp/lastTargets.txt
temp=/tmp/tempFile.txt

rlsX=9000000
rlsY=6000000
maxDist=3000000
azimyt=225
povorot=60

sproX=3250000
sproY=3350000
sproR=1100000

alpha1=`echo "(450-$azimyt-$povorot)%360" | bc`
alpha2=`echo "(450-$azimyt+$povorot)%360" | bc`
#echo $alpha1 $alpha2

get_speed() {
	speed=`echo "sqrt(($1-$3)^2+($2-$4)^2)" | bc`
}

get_to_sector() {
	in_sector=0
	get_speed $1 $2 $3 $4
	if (( $speed <= $maxDist ))
	then
		tempX=`echo "$3-$1" | bc`
		tempY=`echo "$4-$2" | bc`
		phi=`echo "scale=4; a($tempY/$tempX) * 180 / 3.141592653" | bc -l`

		if [ "$tempX" -gt 0 ] && [ "$tempY" -lt 0 ]
		then
			phi=`echo "$phi+360" | bc -l`
		elif [ "$tempX" -lt 0 ]
		then
			phi=`echo "$phi+180" | bc -l`
		fi
		#echo $1 $2 $3 $4 $phi $alpha1 $alpha2
		
		if (( $alpha1 < $alpha2 ))
		then
			if (( `echo "$phi>$alpha1" | bc -l` )) && (( `echo "$phi<$alpha2" | bc -l` ))
			then
				in_sector=1
			fi
		else
			if (( `echo "$phi>$alpha2" | bc -l` )) || (( `echo "$phi<$alpha1" | bc -l` ))
			then
				in_sector=1
			fi
		fi
	fi
}

get_to_spro() {
	in_spro=0
	get_speed $sproX $sproY $1 $2
	d1=$speed
	get_speed $sproX $sproY $3 $4
	d2=$speed
	if (( $d2 < $d1 ))
	then
		k=`echo "($4-$2)/($3-$1)" | bc -l`
		b=`echo "$2- $k*$1" | bc -l`
		d=`echo "(- $k*$sproX+$sproY- $b)/(sqrt($k*$k+1))" | bc -l`
		d=`echo ${d#-}`
		if (( `echo "$d<$sproR" | bc -l` ))
		then
			in_spro=1
		fi
	fi
}

: >$rlsFile
: >$lastTargetsFile
: >$temp
while :
do
	sleep 0.5
	for fileName in $(ls -t $targetsDir | head -30 2>/dev/null)
	do
		foundFile=`grep $fileName $lastTargetsFile 2>/dev/null`
		if [[ $foundFile != "" ]]
		then
			continue
		fi
		echo $fileName >> $lastTargetsFile
		coords=`cat ${targetsDir}$fileName 2>/dev/null`
		targetID=${fileName:12:6}
		X_with_letter=`expr match "$coords" '\(X[0-9]*\)'`
		X=${X_with_letter:1}
		Y_with_letter=`expr match "$coords" '.*\(Y[0-9]*\)'`
		Y=${Y_with_letter:1}

		get_to_sector $rlsX $rlsY $X $Y
		if (( $in_sector == 1 ))
		then
			lastInfo=$(grep $targetID $rlsFile)
			if [[ $lastInfo == "" ]]
			then
				echo "$targetID 0 0 $X $Y" >> $rlsFile
				continue
			fi

			firstPart=$(grep "$targetID 0 0" $rlsFile)
			if [[ $firstPart == "" ]]
			then
				continue
			fi

			lastX=`echo $lastInfo | cut -f 4 -d " "`
			lastY=`echo $lastInfo | cut -f 5 -d " "`
			sed "/$targetID/d" $rlsFile > $temp
			cat $temp > $rlsFile
			echo "$targetID $lastX $lastY $X $Y " >> $rlsFile
			get_speed $lastX $lastY $X $Y
			#if (( $speed >= 8000 ))
			#then
			#targetName="ББ БР"
			#elif (( $speed >= 250))
			#then
			#targetName="Крылатая ракета"
			#else
			#targetName="Самолёт"
			#fi
			if (( $speed >= 8000 ))
			then
				#echo "$targetID x1=$lastX y1=$lastY x2=$X y2=$Y spd=$speed"
				echo "Обнаружена цель ID:$targetID с координатами $X $Y"
				get_to_spro $lastX $lastY $X $Y
				if (( $in_spro == 1 ))
				then
					echo "Цель ID:$targetID движется в направлении СПРО"
				fi
			fi
		fi
	done
done