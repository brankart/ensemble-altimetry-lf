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

# Generate observation error std file (with _oestd suffix)
rm -f ${obsname}_oestd*.cobs
$sesam -mode oper -inobs ${obsname}#.cobs -outobs ${obsname}_oestd#.cobs \
                  -configobs ${obsname}#.cobs -typeoper cst_$oestd

