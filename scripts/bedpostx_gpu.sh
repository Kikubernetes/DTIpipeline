#!/bin/bash
# This script is for bedpostx_gpu.
# After preTBSS.sh, please start in the working directory named "Image ID".
# Check that following files exist in DWI directory:
# 	SR_dwi_den_unr_preproc_unbiased.mif
#	SR_dwi_den_unr_preproc_unbiased.nii.gz
#	SR.bvec
#	SR.bval

date
cd DWI

# making mask for bedpostx
dwiextract SR_dwi_den_unr_preproc_unbiased.mif - -bzero | mrmath - mean SR_temp_b0.mif -axis 3
mrconvert SR_temp_b0.mif SR_temp_b0.nii.gz
bet SR_temp_b0.nii.gz nodif_brain -f 0.3 -R -m
rm -rf SR_temp_b0.nii.gz SR_temp_b0.mif

# arranging files for bedpostx
mkdir ./Tractography
cp SR_dwi_den_unr_preproc_unbiased.nii.gz ./Tractography/data.nii.gz
cp nodif_brain_mask.nii.gz ./Tractography/nodif_brain_mask.nii.gz
cp SR.bvec ./Tractography/bvecs
cp SR.bval ./Tractography/bvals


# datacheck and perform bedpostx_gpu
bedpostx_datacheck Tractography
echo "bedpostx started at $(date)"
bedpostx_gpu Tractography
cd ..
