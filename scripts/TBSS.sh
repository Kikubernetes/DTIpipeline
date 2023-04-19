#!/bin/bash

# This script run TBSS

ImageID=$(basename $FPATH)

cd $FPATH
if [[ ! -d ../TBSS ]]; then
    mkdir ../TBSS
fi

cp map/*FA.nii.gz ../TBSS/${ImageID}_FA.nii.gz

#TBSS_1 prepocessing
cd ../TBSS
tbss_1_preproc *FA.nii.gz

#TBSS_2 registration
tbss_2_reg -T

#TBSS_3 skelton making
tbss_3_postreg -T

#TBSS_4 skelton projection
tbss_4_prestats 0.2

exit



