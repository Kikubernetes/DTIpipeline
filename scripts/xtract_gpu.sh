#!/bin/bash

# This script is to run xtract_gpu.
# Prepare following files in the working directory:
#         DTI.bedpostX/xfms/diff2standard.mat etc.
#         map/SR_FA.nii.gz
# Please start in the working directory named "Image ID".

ImageID=$(basename $FPATH)
cd $FPATH

# copy file and go into DWI
cp map/SR_FA.nii.gz DWI/
cd DWI


# xtract
echo "XTRAXT started at $(date)"
BPX_DIR='DTI.bedpostX'
xtract -bpx $BPX_DIR -out XTRACT_output -species HUMAN -stdwarp $BPX_DIR/xfms/standard2diff_warp $BPX_DIR/xfms/diff2standard_warp -native -gpu
echo "XTRAXT finished at $(date)"

# viewing tracts
#xtract_viewer -dir XTRACT_output -brain SR_FA.nii.gz
cd ..

exit
