#!/bin/bash
#SBATCH --job-name=prepareobs
#SBATCH -e prepareobs.e%j
#SBATCH -o prepareobs.o%j
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=02:00:00            # Temps d’exécution maximum demande (HH:MM:SS)
#SBATCH --exclusive
#SBATCH -A egi@cpu
#SBATCH --hint=nomultithread
#SBATCH --qos=qos_cpu-dev

. ./param.bash

cd $wdir

# Prepare output directory
if [ ! -d Obs_${scenario} ] ; then
  mkdir Obs_${scenario}
fi

# Basename of observation files
obsname="Obs_${scenario}/obs"

# Prepare customized sesamlist
# (with observation extraction bounds)
# None in this case... Extraction was done before.
cp sesamlist sesamlist_obs

# Loop on satellite missions
for sat in $obs_satlist ; do

  # Name of input file
  sat_tag="_${sat}_"
  dbsfile="Obs_dbs/obs${sat_tag}.ncdbs"

  if [ $sat = "h2ag" ] ; then
    sat_tag="_h2ag"
  else
    sat_tag="_${sat}_"
  fi

  # Generate observation file
  rm -f ${obsname}${sat_tag}.cobs
  $sesam -mode obsv -indbs ${dbsfile} -outobs ${obsname}#.cobs -affectobs $sat_tag -config sesamlist_obs

done

# Check extraction of observations
sesam  -mode obsv -inobs ${obsname}#.cobs -configobs ${obsname}#.cobs -outdta ${obsname}.cdta

