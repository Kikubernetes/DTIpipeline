#!/bin/bash

# Get XTRACT statistics.
# Run in the subject directory after dtifit and XTRACT.
# Directories are supposed to be as follows:
#.
#├── DWI
#│   ├── DTI.bedpostX
#│   ├── XTRACT_output
#│   ...
#├── map
#│   ├── SR_FA.nii.gz
#│   ├── SR_MD.nii.gz
#│  ...

ImageID=$(basename $FPATH)
cd $FPATH

xtract_stats -d map/SR_ -xtract DWI/XTRACT_output -w DWI/DTI.bedpostX/xfms/standard2diff_warp  -r map/SR_FA

exit