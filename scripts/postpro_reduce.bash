#!/bin/bash
#

. ./param.bash

cd $wdir

# Name output of directories for updated ensemble
# (posterior ensemble for state, for bias, and for inflation factors)
smpensdir="${expt}SMPENS${upd_size}"
smpensdirb="${expt}-M-SMPENS${upd_size}"
smpensdir1="${expt}-A-SMPENS${upd_size}"
smpensdir2="${expt}-B-SMPENS${upd_size}"

# Create directories if needed
rm -fr $smpensdir.nc.bas ; mkdir $smpensdir.nc.bas
if [ $adapt_bias = 'true' ] ; then
  rm -fr $smpensdirb.nc.bas ; mkdir $smpensdirb.nc.bas
fi
if [ $adapt_spread = 'true' ] ; then
  rm -fr $smpensdir1.nc.bas ; mkdir $smpensdir1.nc.bas
fi
if [ $adapt_oestd = 'true' ] ; then
  rm -fr $smpensdir2.nc.bas ; mkdir $smpensdir2.nc.bas
fi

# Uncenter-unreduce posterior ensemble
# by looping on ensemble member index
let member=1
while [ $member -le ${upd_size} ] ; do
  membertag4=`echo $member | awk '{printf("%04d", $1)}'`

  # Name of input files for current member index
  ifile="RED_1_${smpensdir}.cpak.bas/vct${membertag4}.cpak"
  bfile="RED_1M_${smpensdir}.cpak.bas/vct${membertag4}.cpak"
  ifile1="RED_1A_${smpensdir}.cpak.bas/vct${membertag4}.cpak"
  ifile2="RED_1B_${smpensdir}.cpak.bas/vct${membertag4}.cpak"

  # Name of output files for current member index
  ofile="${smpensdir}.nc.bas/vct#${membertag4}.nc"
  obfile="${smpensdirb}.nc.bas/vct#${membertag4}.nc"
  ofile1="${smpensdir1}.nc.bas/vct#${membertag4}.nc"
  ofile2="${smpensdir2}.nc.bas/vct#${membertag4}.nc"

  if [ $adapt_spread = 'true' ] ; then
    $sesam -mode intf -invar $ifile1 -outvar $ofile1
  fi

  if [ $adapt_oestd = 'true' ] ; then
    $sesam -mode intf -invar $ifile2 -outvar $ofile2
  fi

  # Deal with estimated bias
  rm -f tmpred0.cpak
  if [ $adapt_bias = 'true' ] ; then
    # Output bias file with correct scaling
    if [ $use_cst_bestd = 'true' ] ; then
      $sesam -mode oper -invar $bfile -outvar $obfile -typeoper x_${bestd}
    else
      $sesam -mode oper -invar $bfile -invarref ${ensdir}std.cpak -outvar $obfile -typeoper x
    fi

    # Add bias file (not rescaled) to state
    $sesam -mode oper -invar $ifile -invarref $bfile -outvar tmpred0.cpak -typeoper -
    ifile0="tmpred0.cpak"
  else
    ifile0=$ifile
  fi

  # Rescale by prior ensemble standard deviation
  rm -f tmpred1.cpak
  if [ $use_cst_bestd = 'true' ] ; then
    $sesam -mode oper -invar $ifile0 -outvar tmpred1.cpak -typeoper x_${bestd}
  else
    $sesam -mode oper -invar $ifile0 -invarref ${ensdir}std.cpak -outvar tmpred1.cpak -typeoper x
  fi

  # Add the prior ensemble mean
  if [ $use_zero_mean = 'true' ] ; then
    $sesam -mode intf -invar tmpred1.cpak -outvar $ofile
  else
    $sesam -mode oper -invar tmpred1.cpak -invarref ${ensdir}mean.cpak -outvar $ofile -typeoper +
  fi
  rm -f tmpred1.cpak tmpred0.cpak

  let member=$member+1
done

# Prepare list of members of the posterior ensemble
rm -f list.cfg
echo $upd_size > list.cfg
let member=1
while [ $member -le ${upd_size} ] ; do
  membertag4=`echo $member | awk '{printf("%04d", $1)}'`
  ifile="${smpensdir}.nc.bas/vct#${membertag4}.nc"
  echo $ifile >> list.cfg
  let member=$member+1
done

# Compute mean and standard deviation of posterior ensemble
rm -f ${smpensdir}std*.nc
rm -f ${smpensdir}mean*.nc
$sesam -mode oper -incfg list.cfg -outvar ${smpensdir}std#.nc -typeoper std
$sesam -mode oper -incfg list.cfg -outvar ${smpensdir}mean#.nc -typeoper mean
rm -f list.cfg

