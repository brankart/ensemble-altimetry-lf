#!/bin/bash
#SBATCH --job-name=prepareobs
#SBATCH -e prepareobs.e%j
#SBATCH -o prepareobs.o%j
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=2:00:00            # Temps d’exécution maximum demande (HH:MM:SS)
#SBATCH --exclusive
#SBATCH -A egi@cpu
#SBATCH --hint=nomultithread
#SBATCH --qos=qos_cpu-dev

. ./param.bash

module load python

cd $wdir

# Prepare output directory
if [ ! -d Obs_dbs ] ; then
  mkdir Obs_dbs
fi

# Loop on satellite missions
for sat in $satlist ; do

  satnam=$sat

  # Name of output file
  sat_tag="_${sat}_"
  obsfile="Obs_dbs/obs${sat_tag}.ncdbs"

  # Loop on days
  let day=1
  for ifile in `ls ${obsdir}/${satnam}/` ; do
    day4=`echo $day | awk '{printf("%04d", $1)}'`

    echo "Day: $day4, File: $ifile"
    ofile="tmpdbs${day4}.nc"

    # Extract observations from datafile
    if [ ! -f ${ofile} ] ; then
      python $sdir/dbs_extract.py -i ${obsdir}/${satnam}/${ifile} -o ${ofile} -v time longitude latitude adt -lonmin $dbslonmin -lonmax $dbslonmax -latmin $dbslatmin -latmax $dbslatmax
    fi

    let day=$day+1
    #if [ $day4 = '0005' ] ; then break ; fi
  done

  # Concatenate days in one single file
  rm -f ${obsfile}
  python $sdir/dbs_concatenate.py -i tmpdbs????.nc -o ${obsfile} -d time
  rm -f tmpdbs????.nc

done
