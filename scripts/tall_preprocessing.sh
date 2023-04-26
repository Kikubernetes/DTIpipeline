#!/bin/bash

# This script is to preprocess DWI data for later processing. 
# Denoise, degibbs, topup and eddy, correct b1 field bias, and make mask.
# Start after first.sh in the working directory containing "nifti_data" directory.
# Version20230417

# get ImageID and change directory
cd $FPATH

# make directory and copy all DWI nifti data 
cd nifti_data
list=$( ls *AP.bval | sed 's/.bval//g' ; ls *PA.bval | sed 's/.bval//g' )

# merge files (This part is ontributed by Dr.Nemoto)
fslmerge -a DWI.nii.gz $list
paste -d " " $(ls *AP.bval; ls *PA.bval) > DWI.bval
paste -d " " $(ls *AP.bvec; ls *PA.bvec) > DWI.bvec

# make a list to clearly indicate the order 
echo "Files are merged in this order." > $FPATH/dMRI_list.txt
echo "Bvals:" >> $FPATH/dMRI_list.txt
( ls *AP.bval ; ls *PA.bval )  >> $FPATH/dMRI_list.txt
echo "Bvecs:" >> $FPATH/dMRI_list.txt
( ls *AP.bvec ; ls *PA.bvec )  >> $FPATH/dMRI_list.txt
echo "Image Files are merged in this order." | tee -a $FPATH/dMRI_list.txt
echo "$list" | tee -a $FPATH/dMRI_list.txt

# make DWI directory and move files
mkdir ../DWI && mv DWI.nii.gz DWI.bval DWI.bvec ../DWI/ && cd ../DWI

# convert to mif
mrconvert DWI.nii.gz SR_dwi.mif -fslgrad DWI.bvec DWI.bval -datatype float32

# denoise and degibbs
dwidenoise SR_dwi.mif SR_dwi_den.mif -noise SR_dwi_noise.mif
mrdegibbs SR_dwi_den.mif SR_dwi_den_unr.mif -axes 0,1

# getting TotalReadoutTime from json file
json=$(echo $list | awk '{ print $1 }')
TotalReadoutTime=`cat ../nifti_data/${json}.json | grep TotalReadoutTime | cut -d: -f2 | tr -d ','`

echo "TOPUP started at $(date)" | tee -a $FPATH/timelog.txt
# dwifslpreproc topup & eddy (if your FSL is later than 6.0.6)
dwifslpreproc SR_dwi_den_unr.mif SR_dwi_den_unr_preproc.mif \
-pe_dir AP -rpe_all \
-topup_options " --nthr=8" \
-eddy_options " --slm=linear" \
-readout_time $TotalReadoutTime
# dwifslpreproc topup & eddy (if your FSL is earlier than 6.0.5)
#dwifslpreproc SR_dwi_den_unr.mif SR_dwi_den_unr_preproc.mif \
#pe_dir AP -rpe_all \
#-eddy_options " --slm=linear" \
#-readout_time $TotalReadoutTime
echo "eddy finished at $(date)" | tee -a $FPATH/timelog.txt

# correct b1 field bias
dwibiascorrect ants SR_dwi_den_unr_preproc.mif SR_dwi_den_unr_preproc_unbiased.mif -bias SR_bias.mif

# make mask for dtifit and convert to nifti 
dwi2mask SR_dwi_den_unr_preproc_unbiased.mif SR_mask_den_unr_preproc_unb.nii.gz
mrconvert SR_dwi_den_unr_preproc_unbiased.mif SR_dwi_den_unr_preproc_unbiased.nii.gz -export_grad_fsl SR.bvec SR.bval

cd ..
exit

