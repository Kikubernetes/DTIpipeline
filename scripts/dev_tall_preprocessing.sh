#!/bin/bash

# This script is to preprocess DWI data for later processing. 
# Denoise, degibbs, topup and eddy, correct b1 field bias, and make mask.
# Start after first.sh in the working directory containing "nifti_data" directory.

# get ImageID and change directory
ImageID=$(basename $FPATH)
cd $FPATH

# make directory and copy all DWI nifti data 
mkdir DWI
cd nifti_data
list=$( ls *AP.bval | sed 's/.bval//g' ; ls *PA.bval | sed 's/.bval//g' )
for f in $list; do
    cp $f.nii ../DWI
    done
find ./nifti_data -name *dMRI* -exec cp {} ./DWI \;

# merge files (This part is ontributed by Dr.Nemoto)
cd ../DWI
fslmerge -a DWI.nii.gz $(ls *AP.nii; ls *PA.nii)
paste -d " " $(ls *AP.bval; ls *PA.bval) > DWI.bval
paste -d " " $(ls *AP.bvec; ls *PA.bvec) > DWI.bvec

# make a list to clearly indicate the order 
echo "Files are merged in this order" > filelist.txt
( ls *AP.bval ; ls *PA.bval )  >> filelist.txt
( ls *AP.bvec ; ls *PA.bvec )  >> filelist.txt
( ls *AP.nii  ; ls *PA.bval )  >> filelist.txt

echo "${list} was merged to DWI.nii.gz"

# convert to mif
mrconvert DWI.nii.gz SR_dwi.mif -fslgrad DWI.bvec DWI.bval -datatype float32

# denoise and degibbs
dwidenoise SR_dwi.mif SR_dwi_den.mif -noise SR_dwi_noise.mif
mrdegibbs SR_dwi_den.mif SR_dwi_den_unr.mif -axes 0,1

# getting TotalReadoutTime from json file
json=$(echo $list | awk '{ print $1 }')
TotalReadoutTime=`cat ../nifti_data/${json}.json | grep TotalReadoutTime | cut -d: -f2 | tr -d ','`

# dwifslpreproc topup & eddy
echo "TOPUP started at $(date)" | tee -a $FPATH/timelog.txt
dwifslpreproc all_DWIs.mif SR_dwi_den_unr_preproc.mif -pe_dir AP -rpe_all -eddy_options " --slm=linear" -readout_time $TotalReadoutTime
echo "eddy finished at $(date)" | tee -a $FPATH/timelog.txt

# correct b1 field bias
dwibiascorrect ants SR_dwi_den_unr_preproc.mif SR_dwi_den_unr_preproc_unbiased.mif -bias SR_bias.mif

# make mask for dtifit and convert to nifti 
dwi2mask SR_dwi_den_unr_preproc_unbiased.mif SR_mask_den_unr_preproc_unb.nii.gz
mrconvert SR_dwi_den_unr_preproc_unbiased.mif SR_dwi_den_unr_preproc_unbiased.nii.gz -export_grad_fsl SR.bvec SR.bval

cd ..
exit

