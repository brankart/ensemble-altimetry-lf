#!/bin/bash
#SBATCH --job-name=extractlf
#SBATCH -e extractlf.e%j
#SBATCH -o extractlf.o%j
#SBATCH --ntasks=57
#SBATCH --time=01:00:00            # Temps d’exécution maximum demande (HH:MM:SS)
#SBATCH -A egi@cpu
#SBATCH --hint=nomultithread
#SBATCH --qos=qos_cpu-dev

# Required modules
module purge
module load intel-mpi
module load python/3.10.4

# Name of model ensemble simulation
expt="ENS04"

# Directories
tmpdir="$SCRATCH/Nemo-med_tmp"
outdir="$SCRATCH/Nemo-med_tmp"

# Parameters
member0="1"         # first member to extract
member1="30"        # last member to extract
listvar="sossheig"  # list of variables to extract
vardim="2"          # dimension of variables
ntim="60"           # output frequency in days (unless monthly)
nblocks="1"         # number of blocks to consider at once (if not MPI)
comp_tag="lf"       # tag of component
output_frequency="monthly"

if [ $output_frequency = "monthly" ] ; then
  ntim="-1" # integer tag for monthly output
fi

if [ $comp_tag  = "lf" ] ; then
  lanczos_window="923"  # 2.5 year      -> comp_tag = "lf"
elif [ $comp_tag  = "ac" ] ; then
  lanczos_window="61"   # 2 months      -> comp_tag = "ac"
elif [ $comp_tag  = "hf" ] ; then
  lanczos_window="0"    # no filtering  -> comp_tag = "hf"
else
  echo "Bad component tag"
  exit
fi

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
    for ifile in $outdir/${tag}${expt}_1d_*_gridTsurf_.nc ; do
      list_files="$list_files $ifile"
    done

    # Extract low frequency files
    # With MPI
    srun python extract_lf.py --variable_name $var --variable_dim $vardim --lat_index_start $ilat0 --lat_index_end $ilat1 --lon_index_start $ilon0 --lon_index_end $ilon1 --window_size $lanczos_window --num_timesteps $ntim --use_mpi --output_file $ofile $list_files

    # Extract low frequency files
    # Without MPI
    #python extract_lf.py --variable_name $var --variable_dim $vardim --lat_index_start $ilat0 --lat_index_end $ilat1 --lon_index_start $ilon0 --lon_index_end $ilon1 --window_size $lanczos_window --num_timesteps $ntim --num_blocks $nblocks --output_file $ofile $list_files

    let imember=$imember+1
  done
done

date
