#!/bin/bash

# This script is to run mrtrix3 ismrm_tutorial automatically after DTI_pipeline and recon-all.
# For more details see this page: https://mrtrix3-dev.readthedocs.io/en/latest/quantitative_structural_connectivity/ismrm_hcp_tutorial.html

# Necessary data are as follows:

# Diffusion preprocessed files. 
 # bvals
 # bvecs
 # data.nii.gz
 # nodif_brain_mask.nii.gz
# Structural preprocessed files. 
 # aparc+aseg.nii.gz
 # T1w_acpc_dc_restore_brain.nii.gz

# These files are gathered automatically after DTIpipeline and recon-all.

# !!!Caution!!! Note that about total 100G of disk will be used after tckgen of 100M. 
# Take care of your disk space.

read -p "Enter the path to subject direcory of DTIpipeline > " DPATH
read -p "Enter the fsid > " FSID

# check if $DPATH exists
if [[ ! -d $DPATH ]];then
    echo "$DPATH does not exist. Please check the path."
    exit 1
fi
if [[ ! -d $SUBJECTS_DIR/$FSID ]];then
    echo "$SUBJECTS_DIR/$FSID does not exist. Please check the path."
    exit 1
fi

# make directory and copy files
mkdir $DPATH/ISMRM
cp $DPATH/DWI/Tractography/* $DPATH/ISMRM
echo "freesurfer's subjects directory is $SUBJECTS_DIR."
cp $SUBJECTS_DIR/$FSID/mri/{aparc+aseg.mgz,rawavg.mgz,brain.mgz} $DPATH/ISMRM
cd $DPATH/ISMRM

# transform .mgz files into native space and into .nii.gz.
# brain.mgz を rawavg.mgz にあわせる
# 出力は brain2rawavg.mgz
mri_vol2vol --mov brain.mgz \
--targ rawavg.mgz \
--regheader --no-save-reg \
--o brain2rawavg.mgz

# aparc+aseg.mgz を rawavg.mgz にあわせる
# 出力ファイルは aparc+aseg2rawavg.mgz
mri_label2vol --seg aparc+aseg.mgz \
--temp rawavg.mgz \
--o aparc+aseg2rawavg.mgz \
--regheader aparc+aseg.mgz

# convert to nifti
# nii.gz形式に変換する
mri_convert brain2rawavg.mgz T1w_acpc_dc_restore_brain.nii.gz
mri_convert aparc+aseg2rawavg.mgz aparc+aseg.nii.gz

# copy lookup tables from Freesurfer and Mrtrix3
# lookup tableが変換に必要なのでFreesurferとMRtrix3のディレクトリからコピーする
cp $FREESURFER_HOME/FreeSurferColorLUT.txt .
cp /usr/local/mrtrix3/share/mrtrix3/labelconvert/fs_default.txt .

# check files
if [[ ! -e FreeSurferColorLUT.txt ]];then
    echo "FreeSurferColorLUT.txt does not exist. Please check the path."
    exit 1
fi
if [[ ! -e fs_default.txt ]];then
    echo "fs_default.txt does not exist. Please check the path."
    exit 1
fi

# Now that you have all the necessary files, run the commands as described in the tutorial
# 必要なファイルが揃ったので、後はチュートリアルの通りにコマンドを実行する
echo "tractography started at $(date)"  | tee $DPATH/ISMRM/timelog.txt
5ttgen fsl T1w_acpc_dc_restore_brain.nii.gz 5TT.mif -premasked
5tt2vis 5TT.mif vis.mif
labelconvert aparc+aseg.nii.gz FreeSurferColorLUT.txt fs_default.txt nodes.mif
labelsgmfix nodes.mif T1w_acpc_dc_restore_brain.nii.gz fs_default.txt nodes_fixSGM.mif -premasked
mrconvert data.nii.gz DWI.mif -fslgrad bvecs bvals -datatype float32 -strides 0,0,0,1
dwiextract DWI.mif - -bzero | mrmath - mean meanb0.mif -axis 3
dwi2response msmt_5tt DWI.mif 5TT.mif RF_WM.txt RF_GM.txt RF_CSF.txt -voxels RF_voxels.mif
dwi2fod msmt_csd DWI.mif RF_WM.txt WM_FODs.mif RF_GM.txt GM.mif RF_CSF.txt CSF.mif -mask nodif_brain_mask.nii.gz
mrconvert WM_FODs.mif - -coord 3 0 | mrcat CSF.mif GM.mif - tissueRGB.mif -axis 3
tckgen WM_FODs.mif 100M.tck -act 5TT.mif -backtrack -crop_at_gmwmi -seed_dynamic WM_FODs.mif -maxlength 250 -select 100M -cutoff 0.06
tcksift 100M.tck WM_FODs.mif 10M_SIFT.tck -act 5TT.mif -term_number 10M
tck2connectome 10M_SIFT.tck nodes_fixSGM.mif connectome.csv
echo "tractography finished at $(date)"  | tee -a $DPATH/ISMRM/timelog.txt

# The commands for checking images are as follows
# 画像確認のためのコマンドは以下の通り（CPUをtckgenにまわすため最後にまとめて実行）
# mrview vis.mif &
# mrview meanb0.mif -overlay.load RF_voxels.mif -overlay.opacity 0.5 &
# mrview tissueRGB.mif -odf.load_sh WM_FODs.mif &
# mrview nodes_fixSGM.mif -connectome.init nodes_fixSGM.mif -connectome.load connectome.csv &