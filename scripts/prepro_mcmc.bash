#!/bin/bash
#
# Compute observation equivalent of multiscale input ensemble

. ./param.bash

cd $wdir

# Basename of observation file
obsname="Obs_${scenario_used}/obs"

# Name of input ensemble directories
idir1="RED_1_ENS${ens_size}.cpak.bas"
idir2="RED_2_ENS${ens_size}.cpak.bas"
# Name of output directories for the observation equivalent
idir1obs="RED_1_ENS${ens_size}.cobs.bas"
idir2obs="RED_2_ENS${ens_size}.cobs.bas"

# Perform the extraction
rm -fr $idir1obs ; mkdir $idir1obs
$sesam -mode intf -inobas $idir1 -outobas $idir1obs -configobs ${obsname}#.cobs
rm -fr $idir2obs ; mkdir $idir2obs
$sesam -mode intf -inobas $idir2 -outobas $idir2obs -configobs ${obsname}#.cobs

# Do the same for the bias ensembles
if [ $adapt_bias = 'true' ] ; then
  idir1m="RED_1M_ENS${ens_size}.cpak.bas"
  idir2m="RED_2M_ENS${ens_size}.cpak.bas"
  idir1mobs="RED_1M_ENS${ens_size}.cobs.bas"
  idir2mobs="RED_2M_ENS${ens_size}.cobs.bas"

  rm -fr $idir1mobs ; mkdir $idir1mobs
  $sesam -mode intf -inobas $idir1m -outobas $idir1mobs -configobs ${obsname}#.cobs
  rm -fr $idir2mobs ; mkdir $idir2mobs
  $sesam -mode intf -inobas $idir2m -outobas $idir2mobs -configobs ${obsname}#.cobs
fi

# Do the same for the inflation factor ensemble (A: spread)
if [ $adapt_spread = 'true' ] ; then
  idir1m="RED_1A_ENS${ens_size}.cpak.bas"
  idir2m="RED_2A_ENS${ens_size}.cpak.bas"
  idir1mobs="RED_1A_ENS${ens_size}.cobs.bas"
  idir2mobs="RED_2A_ENS${ens_size}.cobs.bas"

  rm -fr $idir1mobs ; mkdir $idir1mobs
  $sesam -mode intf -inobas $idir1m -outobas $idir1mobs -configobs ${obsname}#.cobs
  rm -fr $idir2mobs ; mkdir $idir2mobs
  $sesam -mode intf -inobas $idir2m -outobas $idir2mobs -configobs ${obsname}#.cobs
fi

# Do the same for the inflation factor ensemble (B: oestd)
if [ $adapt_oestd = 'true' ] ; then
  idir1m="RED_1B_ENS${ens_size}.cpak.bas"
  idir2m="RED_2B_ENS${ens_size}.cpak.bas"
  idir1mobs="RED_1B_ENS${ens_size}.cobs.bas"
  idir2mobs="RED_2B_ENS${ens_size}.cobs.bas"

  rm -fr $idir1mobs ; mkdir $idir1mobs
  $sesam -mode intf -inobas $idir1m -outobas $idir1mobs -configobs ${obsname}#.cobs
  rm -fr $idir2mobs ; mkdir $idir2mobs
  $sesam -mode intf -inobas $idir2m -outobas $idir2mobs -configobs ${obsname}#.cobs
fi

