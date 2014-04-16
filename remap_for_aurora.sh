#!/bin/bash

set -evx

infile=$1
varname=$2

infile_start=${infile/.nc/}

remap_target_coarse=${CENTER}/SNAP/low_res_target_aurora_nc3.nc
remap_target_fine=${CENTER}/SNAP/high_res_target_aurora_nc3.nc
region="-d x,1055934.,1169934. -d y,1085595.,1215595."

# ncks -O $region ${infile} cropped.nc

# cdo -f nc -remapcon,${remap_target_coarse} cropped.nc  ${infile_start}_coarse.nc
# ncks -A -v x,y ${remap_target_coarse}  ${infile_start}_coarse.nc

# cdo -f nc  -remapbil,${remap_target_fine} cropped.nc  ${infile_start}_fine.nc
# ncks -A -v x,y ${remap_target_fine}  ${infile_start}_fine.nc

for y in     ${infile_start}_fine.nc ; do  #  ${infile_start}_coarse.nc
    start=${y/.nc/}
#    cdo -splityear $y  ${start}_
    for x in ${start}_????.nc ; do
	echo $x
	cdo -splitmon $x ${x/.nc/_} 
    done
    for x in ${start}_????_??.nc ; do 
	ncks -A -v x,y ${y} $x
	nc_to_ascii -v $varname  $x 
    done
done 

