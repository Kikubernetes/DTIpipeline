#!/bin/bash

# This script is to process DICOM data to xtract with gpu and cuda10.2.
# Prepare DICOM files in the working directory named "ImageID" and start in the directory.

#date
../scripts/tfirst.sh
#date
../scripts/tall_preprocessing.sh
#date
../scripts/tpreTBSS.sh
#date
../scripts/TBSS.sh
../scripts/bedpostx_gpu.sh
date
../scripts/tmakingwarps.sh
date
../scripts/xtract_gpu.sh
date
../scripts/xstat.sh
