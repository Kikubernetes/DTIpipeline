#!/bin/bash
# This program is to convert DICOM to NIFTI and make directory for original data and nifti data.
# Written and modified by Kikuko on 20230321.
# Please start in the directory containing DICOM data.

# get ImageID and change directory
ImageID=$(basename $FPATH)
cd $FPATH

# remove space from deirectory name (use replace-space-underscore.sh by kytk)
for i in $(seq $(find . -type d | awk -F/ '{ print NF }' | sort | tail -1))
            do
                find . -maxdepth $i -name '* *' | \
                while read line
                do newline=$(echo $line | sed 's/ /_/g')
                    echo $newline
                    mv "$line" $newline
                done
            done
            echo "Replace finished!"

# dcm2niix and name files after its folder
mkdir ../nifti_data_${ImageID}
for f in $(ls); do
    dcm2niix -f %f -o ../nifti_data_${ImageID} $f
    done

# mkdir & move file
mkdir org_data
mv * org_data 2>/dev/null
mv ../nifti_data_${ImageID} ./nifti_data

exit

