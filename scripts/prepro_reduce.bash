#!/bin/bash
#SBATCH --job-name=prepro
#SBATCH -e reduce.e%j
#SBATCH -o reduce.o%j
#SBATCH --time=02:00:00
#SBATCH -A egi@cpu
##SBATCH --partition=prepost
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --exclusive
#SBATCH --hint=nomultithread
#SBATCH --qos=qos_cpu-dev

. ./param.bash

# Center-reduce prior ensemble
./prepro_reduce_ens.bash

# Center-reduce observation
./prepro_reduce_obs.bash

# Compute observation equivalent of all ensembles
./prepro_mcmc.bash
