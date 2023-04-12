#!/bin/bash

# 他のスクリプトの実行時間を測り、timelogに記録します。
# Measure the execution time of other scripts and record it in the timelog.
# Written by Kiku at 20230412.

# define a function to record timelog
timespent() {
    spentsec=$((finishsec-startsec))
    spenttime=$(date --date @$spentsec "+%T" -u)
    if [[ $spentsec -ge 86400 ]]; then
        days=$((spentsec/86400))
        echo "Time spent was $days day(s) and $spenttime" | tee -a timelog.txt
    else 
        echo "Time spent was $spenttime" | tee -a timelog.txt
    fi
    echo " " >> timelog.txt
}

# record start time
echo "$1 started at $(date)"  | tee timelog.txt
startsec=$(date +%s)

$1

# record finish time and spent time
finishsec=$(date +%s)
echo "$1 finished at $(date)"  | tee -a timelog.txt
timespent