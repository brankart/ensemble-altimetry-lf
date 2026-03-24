#!/bin/bash

. ./param.bash

cd $wdir

# Basename of observation file
obsname="Obs_${scenario_used}/obs"

# Center-reduce observation
rm -f tmpred*.cobs
if [ $use_zero_mean = 'true' ] ; then
  $sesam -mode intf -inobs ${obsname}#.cobs -configobs ${obsname}#.cobs -outobs tmpred#.cobs
else
  $sesam -mode oper -inobs ${obsname}#.cobs -configobs ${obsname}#.cobs -inobsref ${ensdir}mean#.nc -outobs tmpred#.cobs -typeoper -
fi

rm -f redobs*.cobs
if [ $use_cst_bestd = 'true' ] ; then
  $sesam -mode oper -inobs tmpred#.cobs -configobs ${obsname}#.cobs -outobs redobs#.cobs -typeoper /_${bestd}
else
  $sesam -mode oper -inobs tmpred#.cobs -configobs ${obsname}#.cobs -inobsref ${ensdir}std#.nc -outobs redobs#.cobs -typeoper /
fi
rm -f tmpred*.cobs

# Reduce observation error
rm -f redobs_oestd*.cobs
if [ $use_cst_bestd = 'true' ] ; then
  $sesam -mode oper -inobs ${obsname}_oestd#.cobs -configobs ${obsname}#.cobs -outobs redobs_oestd#.cobs -typeoper /_${bestd}
else
  $sesam -mode oper -inobs ${obsname}_oestd#.cobs -configobs ${obsname}#.cobs -inobsref ${ensdir}std#.nc -outobs redobs_oestd#.cobs -typeoper /
fi

