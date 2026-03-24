#!/bin/bash

. ./param.bash

cd $wdir

# Prepare empty output directory
rm -fr ${ensdir}.nc.bas ; mkdir ${ensdir}.nc.bas

# Loop on ensemble member
let member=${mem0}
while [ $member -le ${mem1} ] ; do
  membertag3=`echo $member | awk '{printf("%03d", $1)}'`
  membertag4=`echo $member | awk '{printf("%04d", $1)}'`

  # Loop on variables
  for var in ${varlist} ; do

    # Name of input model file
    ifile="${datadir}/${membertag3}${model_expt}_${var}_lf.nc"
    # Name of file for ensemble member
    ofile="${ensdir}.nc.bas/vct_${var}_${membertag4}.nc"

    # Extract region from model file
    ncks -d x,${imin},${imax} -d y,${jmin},${jmax} \
         -d time_counter,${tmin},${tmax} \
         -v time_counter,nav_lon,nav_lat,${var} ${ifile} ${ofile}

  done

  let member=$member+1
done

