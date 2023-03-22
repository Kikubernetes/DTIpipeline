#!/bin/bash

date
#TBSS_1 prepocessing
tbss_1_preproc map/*FA.nii.gz

#TBSS_2 registration
tbss_2_reg -T

#TBSS_3 skelton making
tbss_3_postreg -T

#TBSS_4 skelton projection
tbss_4_prestats 0.2

date



