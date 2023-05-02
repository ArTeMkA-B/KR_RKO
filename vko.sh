elements=( "kp" "rls1" "rls2" "rls3" "spro" "zrdn1" "zrdn2" "zrdn3" )

if [ "$1" == "start" ]
then
    if [ "$2" == "all" ]
    then
        for ((i=0; i<8; i++))
        do
            ./${elements[$i]}.sh & 2>/dev/null
        done
    else
        for ((i=0;i<8;i++))
        do
            if [ "$2" == ${elements[$i]} ]
            then
                ./${elements[$i]}.sh & 2>/dev/null
                break
            fi
        done
    fi
elif [ "$1" == "stop" ]
then
    if [ "$2" == "all" ]
    then
        for ((i=0; i<8; i++))
        do
            kill -9 $(ps aux | grep "${elements[$i]}" | grep -v "grep" | tr -s ' ' | cut -d ' ' -f 2) &>/dev/null
        done
    else
        for ((i=0;i<8;i++))
        do
            if [ "$2" == ${elements[$i]} ]
            then
                kill -9 $(ps aux | grep "${elements[$i]}" | grep -v "grep" | tr -s ' ' | cut -d ' ' -f 2) &>/dev/null
                break
            fi
        done
    fi
else
    echo "Введен недопустимый параметр"
fi