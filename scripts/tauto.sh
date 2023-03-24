#!/bin/bash

# This script is to process DICOM data to xtract with gpu and cuda10.2.
# Prepare DICOM files in the directory named "ImageID" and set it the working directory.
# In short, the command is like this: cd scripts; ./tauto.sh.
# You will be asked "Enter the path to your dicom folder >".
# Please enter the path to your dicom folder. ex) ~/imagedata/sub001
# Output will be in the same folder and dicom files will be put into the folder named "org_data".

# このスクリプトは、gpuとcuda10.2を使ってDICOMデータからXTRACTおよびXSTATまでの処理を行います。
# 被験者ID名（例えばsub001）のディレクトリにDICOMファイルを用意して下さい。
# 位相エンコード方向のみ異なるb0を含んだペア（２セット以上）があることを前提としています。
# このスクリプトが入っている"scripts"ディレクトリに移動して以下のコマンドを打つと処理を開始します。 ./tauto.sh.
# "Enter the path to your dicom folder >".と聞かれるので、被験者ディレクトリのパスを入力してください。ex) ~/imagedata/sub001
# 結果は同じ被験者ディレクトリ内に出力され、dicomファイルはその中の "org_data "というフォルダにまとめられます。

# get path to dicom folder
read -p "Enter the path to your dicom folder > " FPATH
export FPATH

# dicom to nifti 
./tfirst.sh
echo "tfirst finished at $(date)"  | tee $FPATH/timelog.txt

# denoise, degibbs, topup, eddy, biasfieldcorrection, and make mask
./tall_preprocessing.sh
echo "tall_preprocessing finished at $(date)" > $FPATH/timelog.txt

# prepare files for TBSS
./tpreTBSS.sh
echo "tpreTBSS finished at $(date)"  | tee -a $FPATH/timelog.txt

# To run TBSS, remove # from the line below.
# TBSSを実施するときは下の行のコメントを外して下さい
#./TBSS.sh

# run bedpostx_gpu
./bedpostx_gpu.sh
echo "bedpostx_gpu finished at $(date)"  | tee -a $FPATH/timelog.txt

# make warp for registration
./tmakingwarps.sh
echo "tmakingwarps finished at $(date)"  | tee -a $FPATH/timelog.txt

# run xtract_gpu and tractography of major tracts
./xtract_gpu.sh
echo "xtract finished at $(date)"  | tee -a $FPATH/timelog.txt

# run xstats and get statistic value for drawn tracts
./xstat.sh
echo "xstats finished at $(date)"  | tee -a $FPATH/timelog.txt
echo "DTIpipeline finished. Now you can run xview in the subject directory and check the tractography. Statistics is in DWI/XTRACT_output/stats.csv."
