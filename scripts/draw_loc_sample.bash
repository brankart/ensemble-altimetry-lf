#!/bin/bash
#SBATCH --job-name=drawsample
#SBATCH -e drawsample.e%j
#SBATCH -o drawsample.o%j
#SBATCH --ntasks=240
#SBATCH --ntasks-per-node=40
#SBATCH --time=02:00:00            # Temps d’exécution maximum demande (HH:MM:SS)
#SBATCH -A egi@cpu
#SBATCH --hint=nomultithread
#SBATCH --qos=qos_cpu-dev

module purge
module load intel-all/19.0.4
module load hdf5/1.8.21-mpi
module load netcdf/4.7.2-mpi
module load netcdf-fortran/4.5.2-mpi
module load netcdf-cxx4/4.3.1-mpi

. ./param.bash

cd $wdir

# Name of dierctory for the localizing ensemble (with large scale patterns)
odirbas="RED_2_ENS${ens_size}.cpak.bas"
odirbastag="RED_2_ENS${ens_size}-${loc_dir_tag}.cpak.bas"

# Prepare modified sesamlist by adding localization scales
cp sesamlist sesamlist_loc
echo "LOC_TIME_SCALE=$loc_time_scale" >> sesamlist_loc
echo "LOC_RADIUS_IN_DEG=$loc_radius"  >> sesamlist_loc

# Check with just one example (for testing before doing it for the full ensemble)
#srun $sesam -mode spct -invar zero.cpak -outvar zran#.nc -typeoper R_${loc_lmax} -config sesamlist_loc

# Sample ensemble of random fields with required spectrum
rm -fr ${odirbas} ; mkdir ${odirbas}
srun $sesam -mode spct -inxbas ${odirbas} -outxbas ${odirbas} -typeoper R_${loc_lmax} -config sesamlist_loc

# Rename directory according to localization parameters
rm -fr ${odirbastag}
mv ${odirbas} ${odirbastag}
ln -sf ${odirbastag} ${odirbas}

# Remove temporary sesamlist
rm -f sesamlist_loc
