#!/bin/bash

. ./param.bash

cd $wdir

# Convert input ensemble to cpak
rm -fr ${ensdir}.cpak.bas ; mkdir ${ensdir}.cpak.bas
$sesam -mode intf -inxbas ${ensdir}.nc.bas -outxbas ${ensdir}.cpak.bas

# Make list of members of prior ensemble
rm -f list.cfg
echo $ens_size > list.cfg
let member=1
while [ $member -le ${ens_size} ] ; do
  membertag4=`echo $member | awk '{printf("%04d", $1)}'`
  ifile="${ensdir}.cpak.bas/vct${membertag4}.cpak"
  echo $ifile >> list.cfg
  let member=$member+1
done

# Compute ensemble mean and standard deviation
rm -f ${ensdir}std*.nc ${ensdir}mean*.nc
rm -f ${ensdir}std.cpak ${ensdir}mean.cpak
$sesam -mode oper -incfg list.cfg -outvar ${ensdir}std#.nc -typeoper std
$sesam -mode intf -invar ${ensdir}std#.nc -outvar ${ensdir}std.cpak
$sesam -mode oper -incfg list.cfg -outvar ${ensdir}mean#.nc -typeoper mean
$sesam -mode intf -invar ${ensdir}mean#.nc -outvar ${ensdir}mean.cpak
rm -f list.cfg

rm -fr RED_1_${ensdir}.cpak.bas ; mkdir RED_1_${ensdir}.cpak.bas

# Center-reduce prior ensemble
let member=1
while [ $member -le ${ens_size} ] ; do
  membertag4=`echo $member | awk '{printf("%04d", $1)}'`
  ifile="${ensdir}.cpak.bas/vct${membertag4}.cpak"
  ofile="RED_1_${ensdir}.cpak.bas/vct${membertag4}.cpak"

  rm -f tmpred.cpak
  $sesam -mode oper -invar $ifile -invarref ${ensdir}mean#.nc -outvar tmpred.cpak -typeoper -
  $sesam -mode oper -invar tmpred.cpak -invarref ${ensdir}std#.nc -outvar $ofile -typeoper /
  rm -f tmpred.cpak

  let member=$member+1
done

# Center-reduce prior ensemble for bias
if [ $adapt_bias = 'true' ] ; then

  # If we use the native model ensemble variance (not in the paper)
  if [ $adapt_bias_method = 'model' ] ; then

    # Convert input ensemble to cpak
    rm -fr ${ensdir_bias}.cpak.bas ; mkdir ${ensdir_bias}.cpak.bas
    $sesam -mode intf -inxbas ${ensdir_bias}.nc.bas -outxbas ${ensdir_bias}.cpak.bas

    # Compute ensemble mean and standard deviation
    rm -f list.cfg
    echo $ens_size > list.cfg
    let member=1
    while [ $member -le ${ens_size} ] ; do
      membertag4=`echo $member | awk '{printf("%04d", $1)}'`
      ifile="${ensdir_bias}.cpak.bas/vct${membertag4}.cpak"
      echo $ifile >> list.cfg
      let member=$member+1
    done

    rm -f ${ensdir_bias}std*.nc ${ensdir_bias}mean*.nc
    $sesam -mode oper -incfg list.cfg -outvar ${ensdir_bias}std#.nc -typeoper std
    $sesam -mode intf -invar ${ensdir_bias}std#.nc -outvar ${ensdir_bias}std.cpak
    $sesam -mode oper -incfg list.cfg -outvar ${ensdir_bias}mean#.nc -typeoper mean
    $sesam -mode intf -invar ${ensdir_bias}mean#.nc -outvar ${ensdir_bias}mean.cpak
    rm -f list.cfg

    # Center-reduce input ensemble for bias
    rm -fr RED_1M_${ensdir}.cpak.bas ; mkdir RED_1M_${ensdir}.cpak.bas

    let member=1
    while [ $member -le ${ens_size} ] ; do
      membertag4=`echo $member | awk '{printf("%04d", $1)}'`
      ifile="${ensdir_bias}.cpak.bas/vct${membertag4}.cpak"
      ofile="RED_1M_${ensdir}.cpak.bas/vct${membertag4}.cpak"

      rm -f tmpred.cpak tmpred1.cpak
      $sesam -mode oper -invar $ifile -invarref ${ensdir_bias}mean#.nc -outvar tmpred.cpak -typeoper -
      if [ $use_cst_bestd = 'true' ] ; then
        $sesam -mode oper -invar tmpred.cpak -invarref ${ensdir_bias}std#.nc -outvar tmpred1.cpak -typeoper /
        $sesam -mode oper -invar tmpred1.cpak -outvar $ofile -typeoper x_${bmestd}
      else
        $sesam -mode oper -invar tmpred.cpak -invarref ${ensdir}std#.nc -outvar $ofile -typeoper /
      fi
      rm -f tmpred.cpak tmpred1.cpak

      let member=$member+1
    done

  # If we use the specified prior ensemble variance (as in the paper)
  elif [ $adapt_bias_method = 'spec' ] ; then

    # Center-reduce input ensemble for bias
    rm -fr RED_1M_${ensdir}.cpak.bas ; mkdir RED_1M_${ensdir}.cpak.bas

    let member=1
    while [ $member -le ${ens_size} ] ; do
      membertag4=`echo $member | awk '{printf("%04d", $1)}'`
      ifile="RED_2M_${ensdir}.cpak.bas/vct${membertag4}.cpak"
      ofile="RED_1M_${ensdir}.cpak.bas/vct${membertag4}.cpak"

      $sesam -mode oper -invar $ifile -outvar $ofile -typeoper x_$bmestd

      let member=$member+1
    done

  fi

fi

# Reduce input ensemble for spread
if [ $adapt_spread = 'true' ] ; then

  rm -fr RED_1A_${ensdir}.cpak.bas ; mkdir RED_1A_${ensdir}.cpak.bas

  let member=1
  while [ $member -le ${ens_size} ] ; do
    membertag4=`echo $member | awk '{printf("%04d", $1)}'`
    ifile="RED_2A_${ensdir}.cpak.bas/vct${membertag4}.cpak"
    ofile="RED_1A_${ensdir}.cpak.bas/vct${membertag4}.cpak"

    $sesam -mode oper -invar $ifile -outvar $ofile -typeoper x_$adapt_spread_std

    let member=$member+1
  done

fi

# Reduce input ensemble for oestd
if [ $adapt_oestd = 'true' ] ; then

  rm -fr RED_1B_${ensdir}.cpak.bas ; mkdir RED_1B_${ensdir}.cpak.bas

  let member=1
  while [ $member -le ${ens_size} ] ; do
    membertag4=`echo $member | awk '{printf("%04d", $1)}'`
    ifile="RED_2B_${ensdir}.cpak.bas/vct${membertag4}.cpak"
    ofile="RED_1B_${ensdir}.cpak.bas/vct${membertag4}.cpak"

    $sesam -mode oper -invar $ifile -outvar $ofile -typeoper x_$adapt_oestd_std

    let member=$member+1
  done

fi
