#!/bin/bash

# This script is to run TBSS.

read -p "Enter the path to your subjects directory > " SPATH

# check if $SPATH exists
if [[ ! -d $SPATH ]];then
    echo "$SPATH does not exist."
    exit 1
fi

# prpare files
cd $SPATH
mkdir TBSS
find $SPATH -name "*FA.nii.gz" TBSS
cd TBSS

#TBSS_1 prepocessing
tbss_1_preproc *FA.nii.gz

#TBSS_2 registration
tbss_2_reg -T

#TBSS_3 skelton making
tbss_3_postreg -T

#TBSS_4 skelton projection
tbss_4_prestats 0.2






