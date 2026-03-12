# Ensemble estimation of the low-frequency component of ocean dynamic height from satellite altimetry

This repository provide a collection of shell scripts to produce
an ensemble estimation (2D+time) of the low-frequency component of ocean dynamic height
combining model and observation data.
In the application, the model data comes from an ensemble simulation
of the Mediterranean Sea at a 1/12° resolution,
and the observations from all available altimetric missions between 1993 an 2018.

### Software required

These scripts make use of the SESAM toolbox (https://github.com/brankart/sesam),
which requires the EnsDAM (https://github.com/brankart/ensdam)
and FlowSampler (https://github.com/brankart/flowsampler) libraries.
The installation of these software also requires
a FORTRAN-90 compiler and the NetCDF library (with f90 support).

The scripts also make use of the NCO NetCDF operators.

### Scripts

The scripts can be used to perform the following operations
(see the README file in the script directory for more details):
 * prepare configuration (grid, mask, ...);
 * prepare prior ensemble (unconstrained by observations);
 * prepare altimetric observations;
 * sample the posterior ensemble (conditioned to observations, using an MCMC sampler);
 * diagnose the posterior ensemble (probabilistic scores).

### Input data

The scripts use the following datasets:

* an ensemble model simulation for the Mediterrean Sea at a 1/12° resolution, as produced by Héron et al. (2026).

* along-track altimetric data (L3 product). This corresponds to the tag SEALEVEL\_GLO\_PHY\_L3\_MY\_008\_062 in the CMEMS catalog (https://marine.copernicus.eu/). These data are used as observations to constrain the prior ensemble simulation.

The scripts assume that these data are provided as archives (.tar) of daily files. For instance, the Jason-3 mission should be in a file 'j3.tar' with files like './j3/dt\_global\_j3\_phy\_l3\_20201231\_20210603.nc'.

* mapped altimetric data (L4 product). This corresponds to the tag SEALEVEL\_GLO\_PHY\_L4\_MY\_008\_047 in the CMEMS catalog (https://marine.copernicus.eu/). These data are used as comparison data.

The scripts assume that these data are provided as daily files like 'dt\_global\_allsat\_phy\_l4\_20201231\_20210726.nc'. Instead of these data, the scripts can also generate the prior ensemble by sampling random fields with a specified spectrum in the basis of the spherical harmonics.

### Parameters

The paremeters are specified in the script 'param.bash', which is sourced in all other scripts so that they all see the same parameters. The parameters include:
 * directory settings;
 * grid and mask configuration;
 * observation parameters (mission, time window, observation error,...);
 * multiscale prior ensemble parameters (size, localization scale,...);
 * MCMC sampler parameters (sample size, number of iterations, localization,...);
 * diagnostic parameters.

### Output data

The output is an ensemble of possible solutions (in 2D+time) for the low-frequency dynamic topography of the Mediterranean Sea.
