#!/bin/bash
# This script does dtifit preprocessed images and makes FA iamges, then prepare directories for further processing like TBSS, bedpostx, FMRIB_to_FA etc.
# After preprocessing.sh, please start in the working directory named "Image ID" containing DWI directory which has following files:
#	SR_dwi_den_unr_preproc_unbiased.nii.gz
#	SR_mask_den_unr_preproc_unb.nii.gz
#	SR.bval
#	SR.bvec

ImageID=${PWD##*/}
date

# dtifit
echo "Now fitting the images..."
cd DWI
dtifit --bvals=SR.bval --bvecs=SR.bvec --data=SR_dwi_den_unr_preproc_unbiased.nii.gz --mask=SR_mask_den_unr_preproc_unb.nii.gz --out=SR
date

# prepare files for later processing
cd ..
mkdir map
mv ./DWI/*.nii.gz ./map
#cp ./map/SR_FA.nii.gz ~/SR/TBSS/"$ImageID"_FA.nii.gz
#cp ./map/SR_MD.nii.gz ~/SR/MD/"$ImageID"_FA.nii.gz
#cp ./map/SR_L1.nii.gz ~/SR/L1/"$ImageID"_FA.nii.gz
#cp ./map/SR_V1.nii.gz ~/SR/V1/"$ImageID"_FA.nii.gz
mv ./map/SR_dwi_den_unr_preproc_unbiased.nii.gz ./DWI
mv ./map/SR_mask_den_unr_preproc_unb.nii.gz ./DWI
mv ./map/DWI.nii.gz ./DWI
mv ./map/DWI_PA.nii.gz ./DWI
#prepare files for reg_FMRIB_toFA
#mkdir -p ~/SR/FMRIB_to_FA/$ImageID/map
#cp ./map/SR_FA.nii.gz ~/SR/FMRIB_to_FA/$ImageID/map/FA.nii.gz

