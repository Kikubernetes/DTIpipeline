#!/bin/bash
# This script does dtifit preprocessed images and makes FA iamges, then prepare directories for further processing like TBSS, bedpostx, FMRIB_to_FA etc.
# After preprocessing.sh, please start in the working directory named "Image ID" containing DWI directory which has following files:
#	SR_dwi_den_unr_preproc_unbiased.nii.gz
#	SR_mask_den_unr_preproc_unb.nii.gz
#	SR.bval
#	SR.bvec

ImageID=$(basename $FPATH)
cd $FPATH

# dtifit
echo "Now fitting the images..."
cd DWI
dtifit --bvals=SR.bval --bvecs=SR.bvec --data=SR_dwi_den_unr_preproc_unbiased.nii.gz --mask=SR_mask_den_unr_preproc_unb.nii.gz --out=SR

# prepare files for later processing
cd ..
mkdir map
mv ./DWI/SR_??.nii.gz map/

#prepare files for reg_FMRIB_toFA
#mkdir -p ~/SR/FMRIB_to_FA/$ImageID/map
#cp ./map/SR_FA.nii.gz ~/SR/FMRIB_to_FA/$ImageID/map/FA.nii.gz

exit

