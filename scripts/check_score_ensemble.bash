#!/bin/bash
#SBATCH --job-name=checkscore
#SBATCH -e checkscore.e%j
#SBATCH -o checkscore.o%j
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=10:00:00            # Temps d’exécution maximum demande (HH:MM:SS)
#SBATCH --exclusive
#SBATCH -A egi@cpu
#SBATCH --hint=nomultithread
##SBATCH --qos=qos_cpu-dev
#SBATCH --qos=qos_cpu-t3

. ./param.bash

cd $wdir

# These are specific settings
# used for the experiments described in the paper
expt="test_subB3g"
expt="test_subA3g"
expt_ref="test_all3g"
scenario_verif="subA"
scenario_verif="subB"
upd_size="0100"

# Ensemble to verify
ensdir="${expt_ref}SMPENS${upd_size}"
diagensdir="${expt}SMPENS${upd_size}"

# Observations used as verification data
obsname="Obs_${scenario_verif}/obs"

# Partition file (here one single global domain)
rm -f rmspart.cpak
$sesam -mode oper -invar zero.cpak -outvar rmspart.cpak -typeoper cst_1.0

rm -f ${diagensdir}_ens_crps.txt
rm -f ${diagensdir}_ens_rcrv.txt

# Compute rank histogram of each member of the updated ensemble in partially updated  ensemble
let member=1
while [ $member -le ${upd_size} ] ; do
  membertag4=`echo $member | awk '{printf("%04d", $1)}'`

  # Compute rank histogram
  rm -f tmprank*.cobs
  $sesam  -mode rank -invar ${ensdir}.nc.bas/vct#$membertag4.nc \
          -inxbasref ${diagensdir}.nc.bas -outvar tmprank.cpak > ${diagensdir}_ens_rank_histogram_$membertag4.txt
  rm -f tmprank*.cobs

  # Compute crps score
  $sesam -mode scor -inxbas ${diagensdir}.nc.bas -invar ${ensdir}.nc.bas/vct#$membertag4.nc \
         -typeoper crps -inpartvar rmspart.cpak | head -4 | tail -1 >> ${diagensdir}_ens_crps.txt

  # Compute rcrv score
  $sesam -mode scor -inxbas ${diagensdir}.nc.bas -invar ${ensdir}.nc.bas/vct#$membertag4.nc \
         -typeoper rcrv -inpartvar rmspart.cpak | head -4 | tail -1 >> ${diagensdir}_ens_rcrv.txt

  let member=$member+1
done

