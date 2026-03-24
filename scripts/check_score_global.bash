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
expt="test_subA3g"
expt="test_subB3g"
expt_ref="test_all3g"
scenario_verif="subB"
scenario_verif="subA"
upd_size="0100"

# Ensemble to verify
diagensdir="${expt}SMPENS${upd_size}"

# Observations used as verification data
obsname="Obs_${scenario_verif}/obs"

rm -fr PERT${diagensdir}.cobs.bas ; mkdir PERT${diagensdir}.cobs.bas

# Perturb input ensemble with observation error
let member=1
while [ $member -le ${upd_size} ] ; do
  membertag4=`echo $member | awk '{printf("%04d", $1)}'`

  echo "Add perturbation to member: $membertag4"

  # Generate zero mean Gaussian noise 
  rm -fr tmpgnoise*.cobs
  $sesam -mode oper -inobs ${obsname}_oestd#.cobs -configobs ${obsname}#.cobs \
	            -outobs tmpgnoise1#.cobs -typeoper gnoise_$oestd
  # Multiply by estimated beta factor
  $sesam -mode oper -inobs tmpgnoise1#.cobs -configobs ${obsname}#.cobs -typeoper x \
	            -inobsref ${expt_ref}-B-SMPENS${upd_size}expmean#.nc \
	            -outobs tmpgnoise2#.cobs
  # Add noise to ensemble member
  $sesam -mode oper -inobs tmpgnoise2#.cobs -configobs ${obsname}#.cobs -typeoper + \
	            -inobsref ${diagensdir}.nc.bas/vct#${membertag4}.nc \
	            -outobs PERT${diagensdir}.cobs.bas/vct#${membertag4}.cobs
  rm -fr tmpgnoise*.cobs
      
  let member=$member+1
done

# Compute rank histogram
rm -f tmprank*.cobs
$sesam  -mode rank -inobs ${obsname}#.cobs -configobs ${obsname}#.cobs \
        -inobasref PERT${diagensdir}.cobs.bas -outobs tmprank#.cobs > ${diagensdir}_rank_histogram.txt
rm -f tmprank*.cobs

# Partition file (here one single global domain)
rm -f rmspart.cpak
$sesam -mode oper -invar zero.cpak -outvar rmspart.cpak -typeoper cst_1.0

# Compute crps score
$sesam -mode scor -inobas PERT${diagensdir}.cobs.bas -inobs ${obsname}#.cobs \
       -configobs ${obsname}#.cobs -typeoper crps -inpartvar rmspart.cpak > ${diagensdir}_crps.txt

# Compute rcrv score
$sesam -mode scor -inobas PERT${diagensdir}.cobs.bas -inobs ${obsname}#.cobs \
       -configobs ${obsname}#.cobs -typeoper rcrv -inpartvar rmspart.cpak > ${diagensdir}_rcrv.txt

#rm -fr PERT${diagensdir}.cobs.bas
