#!/bin/bash

FPATH=~/prac
timespent() {
    echo "$1 started at $(date)"  | tee $FPATH/timelog.txt
    startsec=$(date +%s)
    eval ./$1
    finishsec=$(date +%s)
    echo "$1 finished at $(date)"  | tee -a $FPATH/timelog.txt

    spentsec=$((finishsec-startsec))
    # Support for both linux and mac date commands (i.e., GNU and BSD date)
    spenttime=$(date --date @$spentsec "+%T" -u 2> /dev/null) # for linux
    if [[ $? != 0 ]]; then
        spenttime=$(date -u -r $spentsec +"%T") # for mac
    fi

    if [[ $spentsec -ge 86400 ]]; then
        days=$((spentsec/86400))
        echo "Time spent was $days day(s) and $spenttime" | tee -a $FPATH/timelog.txt
    else 
        echo "Time spent was $spenttime" | tee -a $FPATH/timelog.txt
    fi
    echo " " >> $FPATH/timelog.txt
}

timespent sleep.sh
echo $startsec
echo $finishsec
echo $spentsec
echo $spenttime