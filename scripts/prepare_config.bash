#!/bin/bash

. ./param.bash

cd $wdir

# Get sesamlist
cp -p ${sdir}/sesamlist .

# Get mask
for var in ${varlist} ; do
  cp -p ${ensdir}.nc.bas/vct_${var}_0001.nc mask.nc
done

# Edit time in mask (from seconds since 1949-12-01 to days from 1950-01-01)
ncap2 -O -s "time_counter=time_counter/86400-31" mask.nc tmpmask.nc
mv tmpmask.nc mask.nc

# Put correct grid in mask file
ncks -d x,${imin},${imax} -d y,${jmin},${jmax} \
     -v nav_lon,nav_lat ${model_grid} grid_tmp.nc
ncks -A -v nav_lon,nav_lat grid_tmp.nc mask.nc
rm -f grid_tmp.nc

# Zero file
rm -f zero.cpak
$sesam -mode oper -invar ${ensdir}.nc.bas/vct#0001.nc -outvar zero.cpak -typeoper cst_0.0

