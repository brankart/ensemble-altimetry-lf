#!/bin/bash
#SBATCH --job-name=extractlf
#SBATCH -e extractlf.e%j
#SBATCH -o extractlf.o%j
#SBATCH --ntasks=1
#SBATCH --time=02:00:00            # Temps d’exécution maximum demande (HH:MM:SS)
#SBATCH -A egi@cpu
#SBATCH --hint=nomultithread
#SBATCH --qos=qos_cpu-dev

# Required modules
module purge
module load intel-mpi
module load python/3.10.4

# Recombine low-frequency files if filtering was parallelized with MPI

# Model ensemble experiment
expt="ENS04"

# Parameters
tmpdir="$SCRATCH/Nemo-med_tmp"
member0="1"
member1="30"
listvar="sossheig"
vardim="2"
nblocks="57"
comp_tag="lf"       # tag of component

# Indices defining area to extract from input data
# Note: maxlon=567, maxlat=264
ilon0="1"
ilat0="1"
ilon1="567"
ilat1="264"

date

# Loop on variables
for var in $listvar ; do
  let imember=$member0
  while [ $imember -le $member1 ] ; do
    tag=`echo ${imember} | awk '{printf("%03d", $1)}'`
    echo "Extracting member: $tag"

    ofile="$tmpdir/${tag}${expt}_${var}_${comp_tag}.nc"
    rm -f $ofile

    list_files=""
    for ifile in $tmpdir/${tag}${expt}_1d_*_gridTsurf_.nc ; do
      list_files="$list_files $ifile"
    done

    # Recombine multiple input files
    python extract_lf_recomb.py --variable_name $var --variable_dim $vardim --lon_index_start $ilon0 --lon_index_end $ilon1 --num_blocks $nblocks --output_file $ofile $list_files

    let imember=$imember+1
  done
done

date
