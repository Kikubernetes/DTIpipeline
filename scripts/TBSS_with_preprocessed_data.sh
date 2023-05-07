#!/bin/bash

# define usage()
usage()
    {
        cat << EOF
このスクリプトはHCPpipelineによるDiffusion Preprocessing後にTBSSを実施します。
一般的なDiffusion Preprocessing後のディレクトリ構造に従ってファイルが配置されていることを前提としています。
初めに被験者ディレクトリの親ディレクトリのパスを聞かれますので、指示に従って入力してください。
TBSSを行う被験者リストを提示し、TBSSを実施するかどうか聞かれます。
間違いがあればnoを入力し、スクリプトを編集するかディレクトリの構造を変更してください。

This script performs TBSS after Diffusion Preprocessing with HCPpipeline.
It assumes that the files are located according to the general directory structure after Diffusion Preprocessing.
You will first be asked for the path of the parent of subjects directory.
You will be presented with a list of subjects for TBSS and asked if you wish to perform TBSS.
Enter no if it is not correct, edit the script or change the directory structure.

EOF
    }

if [[ $1 =~ -*h ]]; then
usage
exit 0
fi

# get path to parent of subjects directory

read -p "Enter the path to parent of subjects directory > " PPATH

# check if $PPATH exists
if [[ ! -d $PPATH ]];then
    echo "$PPATH does not exist."
    exit 1
fi

# check if TBSS_sublist exists
if [[ -d $PPATH/TBSS_sublist ]];then
    echo "TBSS_sublist already exists. It will be renamed as TBSS_sublist_older."
    mv TBSS_sublist TBSS_sublist_older_"$(date +%Y_%m_%d_%H_%M_%S)"
fi

# check if subject(s) are correct
echo "TBSS will be run for the following subject(s). "
ls -p $PPATH | grep / | sed 's@/@@' | tee $PPATH/TBSS_sublist
#find $PPATH -name "*FA.nii.gz" | awk -F"/" '{ print $7 }' | sort | uniq | tee $PPATH/TBSS_sublist

while true; do

    read -p "Do you want to run TBSS?(yes/no): " answer

      case "$answer" in 
	    [Yy]*)
            echo -e "Starting TBSS... \n"
            break
		    ;;
	    [Nn]*)
		    echo -e "TBSS wasn't performed. Please prepare subjects directory and restart, \
            or edit the field after awk according to your file path. \n"
		    exit
  		    ;;
	    *)
		    echo -e "Type yes or no.\n"
		    ;;
      esac

done

# prpare files
cd $PPATH

# check if TBSS directory exists
if [[ -d $PPATH/TBSS ]];then
    echo "TBSS directory already exists. It will be renamed as TBSS_older."
    mv TBSS TBSS_older_"$(date +%Y_%m_%d_%H_%M_%S)"
fi

# make TBSS directory and prepare files
mkdir TBSS
echo "Now copying files."

for sub in $(cat TBSS_sublist); do
    cd $sub
    mkdir map
    find $PPATH -wholename "*$sub*FA.nii.gz"  -exec cp {} $PPATH/TBSS/${sub}_FA.nii.gz \; 2> /dev/null
done

cd TBSS

#TBSS_1 prepocessing
tbss_1_preproc *FA.nii.gz

#TBSS_2 registration
tbss_2_reg -T

#TBSS_3 skelton making
tbss_3_postreg -T

#TBSS_4 skelton projection
tbss_4_prestats 0.2






