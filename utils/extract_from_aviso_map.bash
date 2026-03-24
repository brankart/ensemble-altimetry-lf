#!/bin/bash
#SBATCH --job-name=extractlf
#SBATCH -e extractlf.e%j
#SBATCH -o extractlf.o%j
#SBATCH --ntasks=1
###SBATCH --time=00:30:00            # Temps d’exécution maximum demande (HH:MM:SS)
#SBATCH --time=15:00:00            # Temps d’exécution maximum demande (HH:MM:SS)
#SBATCH -A egi@cpu
#SBATCH --hint=nomultithread
###SBATCH --qos=qos_cpu-dev
#SBATCH --qos=qos_cpu-t3

# Required modules
module purge
module load intel-all/19.0.4
module load intel-mpi
module load python/3.10.4

. ./param.bash

# Working directory
wdir="$SCRATCH/Nemo-med_obs"

cd $wdir

# Directory with global maps
global_aviso_maps_dir="/gpfsstore/rech/egi/commun/Aviso/mapped"
maskfile="mask.nc"


# Loop on global maps
for ifile in $global_aviso_maps_dir/*.nc ; do

  echo "extracting from: $ifile"
  date=$( echo $ifile | cut -d'_' -f6)

  ofile="aviso_adt_med_$date.nc"

  if [ ! -f $ofile ] ; then
    cp mask.nc $ofile
    # Interpolate on model grid
    python $sdir/extract_from_aviso_map.py -i $ifile -grid $maskfile -mask $maskfile -o $ofile
    date
  fi

done
