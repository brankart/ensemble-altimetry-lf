# Description of the shell scripts

The scripts use SESAM and NCO tools to perform operations on the data.
Files and directories containing intermediate data have standardized names defined in the scripts,
which depend on the name of the experiment defined in the parameters.
Parallelization and batch directives in the scripts may need to be adjusted to the system.

Each script performs one task on the data. They must be run successively to perform the ensemble analysis.
They come in 5 categories:

### Prepare configuration (grid, mask, ...)

 * <i>param.bash</i>: Define all parameters of the experiment.

 * <i>prepare_config.bash</i>: Prepare SESAM configuration: mask and parameter files.

### Prepare input data for the inversion problem

 * <i>prepare_prior_ensemble.bash</i>: Extract region and time window from NEMO ensemble.

 * <i>prepare_obs_database.bash</i>: Subsample observation database for region and time window.

 * <i>prepare_obs.bash</i>: Extract observations and compute observation operator.

 * <i>prepare_obs_oestd.bash</i>: Define observation error stanadard deviation.

 * <i>draw_loc_sample.bash</i>: Prepare covariance localization for MCMC sampler.

### Sample the posterior ensemble

 * <i>prepro_reduce.bash</i>: Center-reduce the prior ensemble and the observations.

 * <i>update_mcmc_gpu.bash</i>: Apply MCMC sampler to sample the posterior probability distribution (conditioned to observations).

 * <i>postpro_reduce.bash</i>: Un-center and un-reduce the MCMC sample, compute sample mean and std.

### Diagnose the posterior ensemble

 * <i>diag_correlation.bash</i>: Diagnose prior correlation structure, with localization.

 * <i>check_score_global.bash</i>: Compute probabilistic scores (rank histogram, CRPS, RCRV) using independent observations as reference.

 * <i>check_score_ensemble.bash</i>: Compute probabilistic scores (rank histogram, CRPS, RCRV) using another ensemble as reference.

