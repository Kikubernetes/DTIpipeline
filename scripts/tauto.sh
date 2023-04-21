#!/bin/bash

# This script is to process DICOM data to XTRACT with gpu and cuda10.2.
# Prepare DICOM files in the directory named "ImageID" and set it the working directory.
# It is assumed that there are pair(s) (one or more sets) containing b0(s) that differ only in phase encoding direction.
# In short, the command is like this: cd path_to_DTIpipeline/scripts; ./tauto.sh.
# You will be asked to "Enter the path to your dicom folder >".
# Please enter the path to your dicom folder. ex) ~/imagedata/sub001
# Output will be in the same folder and dicom files will be put into the folder named "org_data".

# このスクリプトは、gpuとcuda10.2を使ってDICOMデータからXTRACTおよびXSTATまでの処理を行います。
# 被験者ID名（例えばsub001）のディレクトリにDICOMファイルを用意して下さい。
# 位相エンコード方向のみ異なるb0を含んだdMRI画像のペア（1セット以上）があることを前提としています。
# このスクリプトが入っている"scripts"ディレクトリに移動して以下のコマンドを打つと処理を開始します。 ./tauto.sh.
# "Enter the path to your dicom folder >".と聞かれるので、被験者ディレクトリのパスを入力してください。ex) ~/imagedata/sub001
# 結果は同じ被験者ディレクトリ内に出力され、dicomファイルはその中の "org_data "というフォルダにまとめられます。

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

# define a function to record timelog
timespent() {
    spentsec=$((finishsec-startsec))
    spenttime=$(date --date @$spentsec "+%T" -u)
    if [[ $spentsec -ge 86400 ]]; then
        days=$((spentsec/86400))
        echo "Time spent was $days day(s) and $spenttime" | tee -a $FPATH/timelog.txt
    else 
        echo "Time spent was $spenttime" | tee -a $FPATH/timelog.txt
    fi
    echo " " >> $FPATH/timelog.txt
}

# If timelog already exists in $ImagepPath, change its name.
if [[ -f $FPATH/timelog.txt ]]; then
    mv $FPATH/timelog.txt $FPATH/timelog.txt_older_"$(date +%Y_%m_%d_%H_%M_%S)"
fi

# record start time
allstartsec=$(date +%s)
echo "Processing started at $(date)"  | tee -a $FPATH/timelog.txt
echo " " >> $FPATH/timelog.txt

# dicom to nifti 
echo "tfirst started at $(date)"  | tee -a $FPATH/timelog.txt
./tfirst.sh
echo "tfirst finished at $(date)"  | tee -a $FPATH/timelog.txt

# denoise, degibbs, topup, eddy, biasfieldcorrection, and make mask
startsec=$(date +%s)
echo "all_preprocessing started at $(date)"  | tee -a $FPATH/timelog.txt
./tall_preprocessing.sh
finishsec=$(date +%s)
echo "all_preprocessing finished at $(date)"  | tee -a $FPATH/timelog.txt
timespent

# prepare files for TBSS
startsec=$(date +%s)
echo "preTBSS started at $(date)"  | tee -a $FPATH/timelog.txt
./tpreTBSS.sh
finishsec=$(date +%s)
echo "preTBSS finished at $(date)"  | tee -a $FPATH/timelog.txt
timespent

# To run TBSS, remove # from the line below.
# TBSSを実施するときは下の行のコメントを外して下さい
#./TBSS.sh

# run bedpostx_gpu
startsec=$(date +%s)
echo "bedpostx_gpu started at $(date)"  | tee -a $FPATH/timelog.txt
./bedpostx_gpu.sh
finishsec=$(date +%s)
echo "bedpostx_gpu finished at $(date)"  | tee -a $FPATH/timelog.txt
timespent

# make warp for registration
startsec=$(date +%s)
echo "makingwarps started at $(date)"  | tee -a $FPATH/timelog.txt
./tmakingwarps.sh
finishsec=$(date +%s)
echo "makingwarps finished at $(date)"  | tee -a $FPATH/timelog.txt
timespent

# run xtract_gpu and tractography of major tracts
startsec=$(date +%s)
echo "xtract_gpu started at $(date)"  | tee -a $FPATH/timelog.txt
./xtract_gpu.sh
finishsec=$(date +%s)
echo "xtract_gpu finished at $(date)"  | tee -a $FPATH/timelog.txt
timespent

# run xstats and get statistic value for drawn tracts
startsec=$(date +%s)
echo "xstat started at $(date)"  | tee -a $FPATH/timelog.txt
./xstat.sh
finishsec=$(date +%s)
echo "xstat finished at $(date)"  | tee -a $FPATH/timelog.txt
timespent

# record finish time
allfinishsec=$(date +%s)
echo "Processing finished at $(date)"  | tee -a $FPATH/timelog.txt
echo "DTIpipeline finished. To check the tractography, copy xview into the subject directory, change directories \
and run xview. Statistics is in DWI/XTRACT_output/stats.csv."
totaltimespent() {
    spentsec=$((allfinishsec-allstartsec))
    spenttime=$(date --date @$spentsec "+%T" -u)
    if [[ $spentsec -ge 86400 ]]; then
        days=$((spentsec/86400))
        echo "Total time spent was $days day(s) and $spenttime" | tee -a $FPATH/timelog.txt
    else 
        echo "Total time spent was $spenttime" | tee -a $FPATH/timelog.txt
    fi
    echo " " >> $FPATH/timelog.txt
}
totaltimespent