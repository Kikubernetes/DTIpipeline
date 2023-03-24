#!/bin/bash

# This script is to preprocess DWI data for later processing. Denoise, degibbs, topup(if possible) and eddy, correct b1 field bias, and make mask.
# Start after first.sh in the working directory containing "nifti_data" directory.

# get ImageID and change directory
ImageID=$(basename $FPATH)
cd $FPATH

# make directory and copy all DWI nifti data
mkdir -p DWI/{Pos,Neg}
find ./nifti_data -name \*dMRI*_AP.* -exec cp {} ./DWI/Pos \;
find ./nifti_data -name \*dMRI*_PA.* -exec cp {} ./DWI/Neg \;

cd DWI/Pos

# make list
ls *.bval | sed 's/.bval//g' > Poslist.txt

# merge Pos files
list=$(cat Poslist.txt)
paste -d " " ${list}.bval > DWI.bval
paste -d " " ${list}.bvec > DWI.bvec
fslmerge -t DWI.nii.gz ${list}.nii

echo "${list}.nii was merged to DWI.nii.gz"
mv DWI* ..
cd ..

cd Neg

# make list
ls *.bval | sed 's/.bval//g' > Neglist.txt

# merge Neg files
list=$(cat Neglist.txt)
paste -d " " ${list}.bval > DWI_PA.bval
paste -d " " ${list}.bvec > DWI_PA.bvec
fslmerge -t DWI_PA.nii.gz ${list}.nii

echo "${list}.nii was merged to DWI_PA.nii.gz"
mv DWI* ..
cd ..

# convert to mif
mrconvert DWI.nii.gz SR_dwi.mif -fslgrad DWI.bvec DWI.bval -datatype float32
mrconvert DWI_PA.nii.gz SR_PA_dwi.mif -fslgrad DWI_PA.bvec DWI_PA.bval -datatype float32

# denoise and degibbs
dwidenoise SR_dwi.mif SR_dwi_den.mif -noise SR_dwi_noise.mif
mrdegibbs SR_dwi_den.mif SR_dwi_den_unr.mif -axes 0,1
dwidenoise SR_PA_dwi.mif SR_PA_dwi_den.mif -noise SR_PA_dwi_noise.mif
mrdegibbs SR_PA_dwi_den.mif SR_PA_dwi_den_unr.mif -axes 0,1

# making b0_pair for topup
	#dwiextract SR_dwi_den_unr.mif - -bzero | mrmath - mean SR_mean_b0_AP.mif -axis 3
	#mrconvert DWI_PA.nii.gz temp01.mif -fslgrad DWI_PA.bvec DWI_PA.bval -datatype float32
	#dwiextract temp01.mif - -bzero | mrmath - mean SR_mean_b0_PA.mif -axis 3
	#mrcat SR_mean_b0_AP.mif SR_mean_b0_PA.mif -axis 3 SR_b0_pair.mif
	#rm temp01.mif

# no-PA version
#if [ ! -e DWI_PA.nii ]; then
	#dwiextract SR_dwi_den_unr.mif - -bzero | mrmath - mean SR_mean_b0_AP.mif -axis 3
#fi

# getting TotalReadoutTime from json file
json=$(echo $list | awk '{ print $1 }')
TotalReadoutTime=`cat ../nifti_data/${json}.json | grep TotalReadoutTime | cut -d: -f2 | tr -d ','`

# dwifslpreproc topup & eddy
echo "TOPUP started at $(date)"
mrcat SR_dwi_den_unr.mif SR_PA_dwi_den_unr.mif all_DWIs.mif -axis 3
dwifslpreproc all_DWIs.mif SR_dwi_den_unr_preproc.mif -pe_dir AP -rpe_all -eddy_options " --slm=linear" -readout_time $TotalReadoutTime
echo "eddy finished at $(date)"

# correct b1 field bias
dwibiascorrect ants SR_dwi_den_unr_preproc.mif SR_dwi_den_unr_preproc_unbiased.mif -bias SR_bias.mif

# make mask for dtifit and convert to nifti 
dwi2mask SR_dwi_den_unr_preproc_unbiased.mif SR_mask_den_unr_preproc_unb.nii.gz
mrconvert SR_dwi_den_unr_preproc_unbiased.mif SR_dwi_den_unr_preproc_unbiased.nii.gz -export_grad_fsl SR.bvec SR.bval

cd ..
exit

