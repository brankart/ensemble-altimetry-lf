#!/bin/bash

# Parameter file used for the SSH experiment of the paper

# standard SESAM executable
sesam="sesam_mpi"
# GPU SESAM executable
sesam_gpu="sesam_gpu"

# prior ensemble size
ens_size="0030"

# name of directories
model_expt="ENS04"
sdir="$HOME/Posydonie/Run"
wdir="$WORK/Posydonie/Sesam_Med"
datadir="$SCRATCH/Nemo-med_data"
obsdir="$SCRATCH/Obs_dir"
model_grid="$STORE/Nemo-med/Data/CONFIG/coordinates_MED12.nc"
ensdir="ENS${ens_size}"

# range of ensemble members from ensemble model simulation
mem0="1"
mem1="30"

# define list of variables
varlist="sossheig"

# define region and time span
imin="50"
imax="566"
jmin="0"
jmax="263"
tmin="147"
tmax="458"

# time span for bias ensemble
tmin_ac="281" 
tmax_ac="292"
nyears="26"

# Define observation database (no need to extract all of them at once)
satlist="tp j1 j2 j3"   # List of satellite missions to extract (! h2a is for h2ag !)
satlist="e1 e1g tpn"    # List of satellite missions to extract (! h2a is for h2ag !)
satlist="e2"            # List of satellite missions to extract (! h2a is for h2ag !)
satlist="j1n j1g g2"    # List of satellite missions to extract (! h2a is for h2ag !)
satlist="en"            # List of satellite missions to extract (! h2a is for h2ag !)
satlist="enn"           # List of satellite missions to extract (! h2a is for h2ag !)
satlist="j2g j2n"       # List of satellite missions to extract (! h2a is for h2ag !)
satlist="al alg"        # List of satellite missions to extract (! h2a is for h2ag !)
satlist="c2n h2ag"      # List of satellite missions to extract (! h2a is for h2ag !)
satlist="h2a h2b"       # List of satellite missions to extract (! h2a is for h2ag !)
satlist="s3b s3a"       # List of satellite missions to extract (! h2a is for h2ag !)
satlist="c2"            # List of satellite missions to extract (! h2a is for h2ag !)
# Geographical limits of database (to avoid having big files)
dbslonmin="-10"
dbslonmax="36"
dbslatmin="30"
dbslatmax="46"

# Define observation scenario
obs_satlist="tp j1 j2 j3 tpn e1 e1g e2 g2 j1n j1g en enn j2n j2g c2 al alg h2a h2ag s3a"
scenario="all"
oestd="0.05"   # observation error standard deviation

# Covariance localization parameters
loc_lmax="200"              # Maximum degree of spherical harmonics in localizing ensemble
loc_time_scale="1080."      # Localization time scale (in days) ! multiplied by sqrt(mult=6)
loc_radius="1.3"            # Localization radius (in degree)   ! multiplied by sqrt(mult=6)
loc_dir_tag="200-108-1300"  # Tag in directory name

# Use zero background mean rather than ensemble mean
# Use constant background error variance rather than ensemble variance
use_zero_mean="false"
use_cst_bestd="true"
bestd="0.04"  # background error standard deviation

# Parameterization of prior statistics on bias
adapt_bias="true"
adapt_bias_method="spec"
bmestd="2.0"  # background error standard deviation for bias (factor to bestd)
ensdir_bias="ENS-M-$ens_size"
nmonths=`echo $nyears | awk '{printf("%04d", $1*12)}'`
bias_annual_cycle="false"   # Localization file is constant in time (false) or not (true)

loc_time_scale_bias="1."    # Localization time scale (in days) ! multiplied by sqrt(mult=6)
loc_radius_bias="1.0"       # Localization radius (in degree)   ! multiplied by sqrt(mult=6)
loc_dir_tag_bias="200-1-1000"    # Tag in directory name

# Parameterization of prior statistics on spread
adapt_spread="true"
adapt_spread_std="0.3"
mcmc_adap_ratio="0."        # Number of dof for each observation (inverse) -> weight od adap
loc_time_scale_spread="1."  # Localization time scale (in days) ! multiplied by sqrt(mult=6)
loc_radius_spread="2.0"     # Localization radius (in degree)   ! multiplied by sqrt(mult=6)
loc_dir_tag_spread="200-1-2000"    # Tag in directory name

# Parameterization of prior statistics on observation error
adapt_oestd="true"
adapt_oestd_std="1.0"
loc_time_scale_oestd="1."   # Localization time scale (in days) ! multiplied by sqrt(mult=6)
loc_radius_oestd="2.0"      # Localization radius (in degree)   ! multiplied by sqrt(mult=6)
loc_dir_tag_oestd="200-1-2000"    # Tag in directory name

# MCMC sampler parameters
expt="test_all3g"         # Name of the experiment
scenario_used="all"       # Name of the observation scenario to use
upd_size="0100"           # Updated ensemble size
niter="30000"             # Number of iterations

scal_mult_1="1"           # Multiplicity of 1st scale
scal_mult_2="6"           # Multiplicity of 2nd scale

oestd_inflation="1."      # Observation error inflation factor

# Score parameters
diagensdir="${expt}SMPENS${upd_size}"
scenario_verif="indep"    # Name of the observation scenario to use for validation
