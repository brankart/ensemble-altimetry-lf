#!/bin/bash
#SBATCH --job-name=diagcorr
#SBATCH -e diagcorr.e%j
#SBATCH -o diagcorr.o%j
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:45:00            # Temps d’exécution maximum demande (HH:MM:SS)
#SBATCH --exclusive
#SBATCH -A egi@cpu
#SBATCH --hint=nomultithread
#SBATCH --qos=qos_cpu-dev

. ./param.bash

cd $wdir

# Ensemble size
ens_size="0030"

# Grid point of reference location A
i="231"
j="121"

# Grid point of reference location B
i="198"
j="111"

cat > corr.cfg <<EOF
SSH $i $j 1 156 1
EOF

# Compute correlation with respect to reference location
# for the prior ensemble
$sesam -mode corr -inxbas RED_1_ENS${ens_size}.cpak.bas -outvar RED1ENScorr#.nc -incfg corr.cfg
# for the localizing ensemble (with large scale patterns)
$sesam -mode corr -inxbas RED_2_ENS${ens_size}.cpak.bas -outvar RED2ENScorr#.nc -incfg corr.cfg

# Localizing correlation 2nd Schur power
$sesam -mode oper -invar RED2ENScorr#.nc -invarref RED2ENScorr#.nc -outvar RED2ENScorr2#.nc -typeoper x
# Localizing correlation 4th Schur power
$sesam -mode oper -invar RED2ENScorr2#.nc -invarref RED2ENScorr2#.nc -outvar RED2ENScorr4#.nc -typeoper x
# Localizing correlation 6th Schur power
$sesam -mode oper -invar RED2ENScorr4#.nc -invarref RED2ENScorr2#.nc -outvar RED2ENScorr6#.nc -typeoper x

# Correlation for the localized prior ensemble
$sesam -mode oper -invar RED2ENScorr6#.nc -invarref RED1ENScorr#.nc -outvar AUGENS-$i-$j-corr6#.nc -typeoper x

