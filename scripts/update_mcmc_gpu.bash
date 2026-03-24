#!/bin/bash
#SBATCH --job-name=mcmcsampler
#SBATCH -e mcmcsampler.e%j
#SBATCH -o mcmcsampler.o%j
#SBATCH -C v100-16g
#SBATCH --nodes=12
##SBATCH --nodes=10
##SBATCH --nodes=5
#SBATCH --ntasks-per-node=4
##SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:4
##SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=1
#SBATCH --hint=nomultithread
#SBATCH --time=02:00:00
#SBATCH -A egi@v100
##SBATCH --qos=qos_gpu-dev

# Load modules with GPU compiler
module purge
module load nvidia-compilers/24.3
module load cuda/12.2.0  # not needed before, worked with cuda/12.4.1
module load openmpi/4.0.5-cuda
module load netcdf-fortran/4.5.3-mpi-cuda
#module load hdf5/1.14.5-mpi-cuda
module load hdf5/1.12.0-mpi-cuda

. ./param.bash

cd $wdir

date

# Update sesamlist with MCMC parameters
cp sesamlist sesamlist_mcmc
echo "MCMC_ADAP_TYPE=0"                         >> sesamlist_mcmc
echo "MCMC_SCALE_MULTIPLICITY-1=${scal_mult_1}" >> sesamlist_mcmc
echo "MCMC_SCALE_MULTIPLICITY-2=${scal_mult_2}" >> sesamlist_mcmc
echo "MCMC_CONTROL_PRINT=1000"                  >> sesamlist_mcmc
echo "MCMC_CONVERGENCE_CHECK=1000"              >> sesamlist_mcmc
echo "OESTD_INFLATION=${oestd_inflation}"       >> sesamlist_mcmc
echo "MCMC_ADAP_RATIO=${mcmc_adap_ratio}"       >> sesamlist_mcmc

if [ $adapt_oestd = 'true' ] ; then
  echo "MCMC_ADAP_TYPE=3"                       >> sesamlist_mcmc
elif [ $adapt_spread = 'true' ] ; then
  echo "MCMC_ADAP_TYPE=2"                       >> sesamlist_mcmc
elif [ $adapt_bias = 'true' ] ; then
  echo "MCMC_ADAP_TYPE=1"                       >> sesamlist_mcmc
fi

# Name of output directories
odir="RED_@_${expt}SMPENS${upd_size}.cpak.bas"
odirobs="RED_@_${expt}SMPENS${upd_size}.cobs.bas"
odir1="RED_1_${expt}SMPENS${upd_size}.cpak.bas"
odirobs1="RED_1_${expt}SMPENS${upd_size}.cobs.bas"

# Prepare output directories
rm -fr ${odir1} ; mkdir ${odir1}
rm -fr ${odirobs1} ; mkdir ${odirobs1}

if [ $adapt_bias = 'true' ] ; then
  odir1m="RED_1M_${expt}SMPENS${upd_size}.cpak.bas"
  rm -fr ${odir1m} ; mkdir ${odir1m}
fi

if [ $adapt_spread = 'true' ] ; then
  odir1m="RED_1A_${expt}SMPENS${upd_size}.cpak.bas"
  rm -fr ${odir1m} ; mkdir ${odir1m}
fi

if [ $adapt_oestd = 'true' ] ; then
  odir1m="RED_1B_${expt}SMPENS${upd_size}.cpak.bas"
  rm -fr ${odir1m} ; mkdir ${odir1m}
fi

# Save parameter file in output directory
cp $sdir/param.bash $odir1

# Apply MCMC sampler
srun /gpfslocalsup/pub/idrtools/bind_gpu.sh \
    $sesam_gpu -mode mcmc -inxbas RED_@_ENS${ens_size}.cpak.bas -outxbas ${odir} -iterate $niter \
          -inobs redobs#.cobs -configobs redobs#.cobs -oestd redobs_oestd#.cobs \
          -inobas RED_@_ENS${ens_size}.cobs.bas -outobas ${odirobs} \
          -config sesamlist_mcmc

date
