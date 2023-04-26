#!/bin/bash

if [[ $1 == h ]]; then
cat << EOF
This script is to process DICOM data to XTRACT with gpu and cuda10.2.
Prepare DICOM files in the directory named "ImageID" and set it the working directory.
It is assumed that there are pair(s) (one or more sets) containing b0(s) that differ only in phase encoding direction.
In short, the command is like this: cd path_to_DTIpipeline/scripts; ./tauto.sh
You will be asked to "Enter the path to your dicom folder >".
Please enter the path to your dicom folder. ex) ~/imagedata/sub001
Output will be in the same folder and dicom files will be put into the folder named "org_data".
FSL 6.0.6 or later is assumed; if you are using 6.0.5 or earlier, edit tall_preprocessing and comment out 
FSL6.0.6 (using the --nthr option) and uncomment FSL6.0.5 (It will take longer but will do topup without multithreading).

このスクリプトは、gpuとcuda10.2を使ってDICOMデータからXTRACTおよびXSTATまでの処理を行います。
被験者ID名（例えばsub001）のディレクトリにDICOMファイルを用意して下さい。
位相エンコード方向のみ異なるb0を含んだdMRI画像のペア（1セット以上）があることを前提としています。
このスクリプトが入っている"scripts"ディレクトリに移動して以下のコマンドを打つと処理を開始します。 ./tauto.sh
"Enter the path to your dicom folder >".と聞かれるので、被験者ディレクトリのパスを入力してください。ex) ~/imagedata/sub001
結果は同じ被験者ディレクトリ内に出力され、dicomファイルはその中の "org_data "というフォルダにまとめられます。
FSL 6.0.6以降を前提としています。6.0.5以前のバージョンをお使いの場合はtall_preprocessingを編集し、
FSL 6.0.6（—-nthrオプションを使用）をコメントアウトしてFSL 6.0.5のコメントを外してください。
時間がかかりますがマルチスレッドを使わずにtopupを行います。
EOF
exit 0
fi

# get path to dicom folder
read -p "Enter the path to your dicom folder > " FPATH
ImageID=$(basename $FPATH)
export FPATH
export ImageID


# check if $FPATH exists
if [[ ! -d $FPATH ]];then
    echo "$FPATH does not exist."
    exit 1
fi

# define a function to record timelog of each process

timespent() {
    echo "$1 started at $(date)"  | tee -a $FPATH/timelog.txt
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


# If timelog already exists in ImagepPath, change its name.
if [[ -f $FPATH/timelog.txt ]]; then
    mv $FPATH/timelog.txt $FPATH/timelog.txt_older_"$(date +%Y_%m_%d_%H_%M_%S)"
fi

# record start time
allstartsec=$(date +%s)
echo "Processing started at $(date)"  | tee $FPATH/timelog.txt
echo " " >> $FPATH/timelog.txt

# dicom to nifti 
timespent tfirst.sh

# denoise, degibbs, topup, eddy, biasfieldcorrection, and make mask
timespent tall_preprocessing.sh

# prepare files for TBSS
timespent tpreTBSS.sh

# To run TBSS, remove # from the line below.
# TBSSを実施するときは下の行のコメントを外して下さい
timespent TBSS.sh

# run bedpostx_gpu
timespent bedpostx_gpu.sh

# make warp for registration
timespent tmakingwarps.sh

# run xtract_gpu and tractography of major tracts
timespent xtract_gpu.sh

# run xstats and get statistic value for drawn tracts
timespent xstat.sh

# record finish time
allfinishsec=$(date +%s)
echo "Processing finished at $(date)"  | tee -a $FPATH/timelog.txt
echo "DTIpipeline finished. To check the tractography, copy "xview" script into the subject directory, \
change directories and run xview. Statistics is in DWI/XTRACT_output/stats.csv."
totaltimespent() {
    spentsec=$((allfinishsec-allstartsec))

    # Support for both linux and mac date commands (i.e., GNU and BSD date)
    spenttime=$(date --date @$spentsec "+%T" -u 2> /dev/null) # for linux
    if [[ $? != 0 ]]; then
        spenttime=$(date -u -r $spentsec +"%T") # for mac
    fi
    # processing maybe over 1day
    if [[ $spentsec -ge 86400 ]]; then
        days=$((spentsec/86400))
        echo "Total time spent was $days day(s) and $spenttime" | tee -a $FPATH/timelog.txt
    else 
        echo "Total time spent was $spenttime" | tee -a $FPATH/timelog.txt
    fi
    echo " " >> $FPATH/timelog.txt
}
totaltimespent