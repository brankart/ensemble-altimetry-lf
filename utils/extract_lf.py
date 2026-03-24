import argparse
import netCDF4 as nc
import numpy as np
from scipy.signal import lfilter, windows
import time

# Global variable for output indices
output_indices = []

def get_lanczos_window(window_size):
    """Generate a Lanczos window of the specified size."""
    half_n = (window_size - 1) / 2
    n = np.arange(window_size)
    return np.sinc((n - half_n) / half_n) * np.sinc((n - half_n) / half_n / 2)

def extract_time_series(netcdf_files, variable_name, variable_dim, lat_index_start, lat_index_end, lon_index_start, lon_index_end):
    """
    Extracts a contiguous block of time series from a series of successive 4D NetCDF files based on provided indices.
    
    Args:
    netcdf_files (list): List of paths to the NetCDF files.
    variable_name (str): Name of the variable in the NetCDF file.
    variable_dim (int): Dimension of variable in the NetCDF file (2 or 3).
    lat_index_start (int): Starting index of the latitude coordinate.
    lat_index_end (int): Ending index of the latitude coordinate.
    lon_index_start (int): Starting index of the longitude coordinate.
    lon_index_end (int): Ending index of the longitude coordinate.
    
    Returns:
    tuple: A tuple containing time values and corresponding time series.
    """
    time_values = []
    time_series = []

    for netcdf_file in netcdf_files:
        # Open the NetCDF file
        nc_data = nc.Dataset(netcdf_file, 'r')

        # Extract time values
        time_values.extend(nc_data.variables['time_counter'][:])

        # Extract time series based on provided indices
        if variable_dim==2:
          time_series.extend(nc_data.variables[variable_name][:, lat_index_start-1:lat_index_end, lon_index_start-1:lon_index_end])
        elif variable_dim==3:
          time_series.extend(nc_data.variables[variable_name][:, :, lat_index_start-1:lat_index_end, lon_index_start-1:lon_index_end])
        else:
          raise ValueError("Bad variable dimension in extract_time_series.")


        # Close the NetCDF file
        nc_data.close()

    return np.array(time_values), np.array(time_series)

def apply_lanczos_filter(time_values, time_series, window_size, num_timesteps):
    """
    Applies a Lanczos filter in time and subsamples the time series over a reduced number of timesteps.
    
    Args:
    time_values (ndarray): Array of time values.
    time_series (ndarray): Array of time series values.
    window_size (int): Size of window used in Lanczos filter
    num_timesteps (int): Number of timesteps between subsamples.
    
    Returns:
    tuple: A tuple containing filtered time values and corresponding filtered time series.
    """
    global output_indices

    # Generate the Lanczos window
    if window_size>0:
      lanczos_window = get_lanczos_window(window_size)
      #lanczos_window = windows.lanczos(window_size)                     # python 3.11.5 

      # Normalize the window to have unity gain
      lanczos_window /= np.sum(lanczos_window)

      # Apply Lanczos filter in time
      filtered_time_series = lfilter(lanczos_window, 1.0, time_series, axis=0)
    else:
      filtered_time_series = time_series

    # Subsample the filtered time series
    # (with compensation for phase delay in lfilter)
    if num_timesteps == -1:
      subsampled_time_series = filtered_time_series[output_indices+window_size//2]
      subsampled_time_values = time_values[output_indices]
    else:
      subsampled_time_series = filtered_time_series[window_size::num_timesteps]
      subsampled_time_values = time_values[(window_size+1)//2:-window_size//2:num_timesteps]

    return subsampled_time_values, subsampled_time_series

def save_to_netcdf(filename, time_values, time_series, variable_name, variable_dim):
    """
    Saves time values and time series to a NetCDF file.
    
    Args:
    filename (str): Name of the NetCDF file to save.
    time_values (ndarray): Array of time values.
    time_series (ndarray): Array of time series values.
    variable_name (str): Name of the variable.
    variable_dim (int): dimension of the variable.
    """
    with nc.Dataset(filename, 'w', format='NETCDF4') as nc_file:
        # Create dimensions
        nc_file.createDimension('time', len(time_values))
        if variable_dim==2:
          nc_file.createDimension('lat', time_series.shape[1])
          nc_file.createDimension('lon', time_series.shape[2])
        elif variable_dim==3:
          nc_file.createDimension('depth', time_series.shape[1])
          nc_file.createDimension('lat', time_series.shape[2])
          nc_file.createDimension('lon', time_series.shape[3])

        # Create variables
        time_var = nc_file.createVariable('time', 'f8', ('time',))
        if variable_dim==3:
          depth_var = nc_file.createVariable('depth', 'f4', ('depth',))
        lat_var = nc_file.createVariable('lat', 'f4', ('lat',))
        lon_var = nc_file.createVariable('lon', 'f4', ('lon',))
        if variable_dim==2:
          variable_var = nc_file.createVariable(variable_name, 'f4', ('time', 'lat', 'lon',))
        elif variable_dim==3:
          variable_var = nc_file.createVariable(variable_name, 'f4', ('time', 'depth', 'lat', 'lon',))

        # Write data to variables
        time_var[:] = time_values
        variable_var[:] = time_series
        if variable_dim==2:
          lat_var[:] = np.arange(time_series.shape[1])
          lon_var[:] = np.arange(time_series.shape[2])
        elif variable_dim==3:
          depth_var[:] = np.arange(time_series.shape[1])
          lat_var[:] = np.arange(time_series.shape[2])
          lon_var[:] = np.arange(time_series.shape[3])

def get_monthly_time_indices(start_date,end_date,input_freq,window_size):
    """
    Get mid-month indices of time series

    Args:
    start_date: initial date (YYYY-MM-DD)
    end_date: final date (YYYY-MM-DD)
    input_freq: frequency in input files (in days)
    window_size: size of filtering window (to eliminate extra indices)
    """
    import pandas as pd

    # Create a daily time series
    #start_date = "1979-07-01"
    date_range = pd.date_range(start=start_date, end=end_date, freq='D')

    # Calculate the indices for mid-month days
    indices = []

    for year in range(date_range[0].year, date_range[-1].year + 1):
        for month in range(1, 13):
            # Get all dates for the current month
            month_dates = date_range[(date_range.month == month) & (date_range.year == year)]
        
            # Only proceed if there are enough dates in this month (handles series end)
            days_in_month = len(month_dates)
            if days_in_month == 31:
                mid_month_index = date_range.get_loc(month_dates[14])
                indices.append(mid_month_index)
            elif days_in_month == 30:
                mid_month_index = date_range.get_loc(month_dates[14])
                indices.append(mid_month_index)
                #mid_month_index1 = date_range.get_loc(month_dates[16])
                #mid_month_index0 = date_range.get_loc(month_dates[15])
                #indices.append((mid_month_index0+mid_month_index1)/2)
            elif days_in_month == 29:
                mid_month_index = date_range.get_loc(month_dates[13])
                indices.append(mid_month_index)
            elif days_in_month == 28:
                mid_month_index = date_range.get_loc(month_dates[13])
                indices.append(mid_month_index)
            else:
                print("Warning: short month:",month,"/",year)

    # Keep only indices inside the relevant window after filtering
    # (window_size+1)//2:-window_size//2
    indices_array = np.array(indices)
    start = ((window_size+1)//2) * input_freq
    end = len(date_range) - (window_size//2) * input_freq
    mid_month_indices = indices_array[(indices_array >= start) & (indices_array < end)]

    if input_freq>1:
       mid_month_indices = np.round((mid_month_indices-input_freq//2)/input_freq).astype(int)
    # mid_month_indices now contains the indices of mid-month days in the time series
    print("mid_month_indices",mid_month_indices)

    return mid_month_indices

if __name__ == "__main__":
    import re
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description='Extract time series from a series of NetCDF files, apply Lanczos filter, and save to NetCDF file.')
    parser.add_argument('netcdf_files', nargs='+', type=str, help='List of paths to the NetCDF files')
    parser.add_argument('--variable_name', type=str, required=True, help='Name of the variable in the NetCDF file')
    parser.add_argument('--variable_dim', type=int, required=True, help='Dimension of the variable in the NetCDF file')
    parser.add_argument('--lat_index_start', type=int, required=True, help='Starting index of the latitude coordinate')
    parser.add_argument('--lat_index_end', type=int, required=True, help='Ending index of the latitude coordinate')
    parser.add_argument('--lon_index_start', type=int, required=True, help='Starting index of the longitude coordinate')
    parser.add_argument('--lon_index_end', type=int, required=True, help='Ending index of the longitude coordinate')
    parser.add_argument('--window_size', type=int, required=True, help='Size of window used in Lanczos filter')
    parser.add_argument('--num_timesteps', type=int, required=True, help='Number of timesteps between subsamples')
    parser.add_argument('--num_blocks', type=int, required=False, help='Number of longitude blocks (by processor if MPI)')
    parser.add_argument('--use_mpi', action='store_true', help='Use MPI parallelization')
    parser.add_argument('--output_file', type=str, required=True, help='Name of the output NetCDF file')
    args = parser.parse_args()

    # Set default number of blocks
    if args.num_blocks is None:
       args.num_blocks = 1

    # Get information from MPI
    if args.use_mpi:
       from mpi4py import MPI
       mpicomm = MPI.COMM_WORLD
       mpirank = mpicomm.Get_rank()
       mpisize = mpicomm.Get_size()
    else:
       mpirank = 0
       mpisize = 1

    # Get monthly indices in timeseries in case of daily outputs
    if args.num_timesteps==-1:
       # Find frequecny of outputs in first file name in YYYYMMDD format
       match = re.search(r'_(\d+)d_',args.netcdf_files[0])
       if match:
           # Extract the digits and convert to an integer
           input_freq = int(match.group(1))
           print("Input frequency in days:", input_freq)
       else:
           print("No frequency tag found in the input filenames")
           print("Frequency set to 1 day")
           input_freq = 1

       # Find start date in first file name in YYYYMMDD format
       matches = re.findall(r'_(\d{8})',args.netcdf_files[0])
       if matches:
           # Extract the date string in YYYYMMDD format
           date_str = matches[0]
           # Format the date as YYYY-MM-DD
           start_date = f"{date_str[:4]}-{date_str[4:6]}-{date_str[6:]}"
           print("Start date:", start_date)
       else:
           print("No date found in the input filenames")
           exit()

       # Find end date in last file name in YYYYMMDD format
       matches = re.findall(r'_(\d{8})',args.netcdf_files[-1])
       if matches:
           # Extract the date string in YYYYMMDD format
           date_str = matches[-1]
           # Format the date as YYYY-MM-DD
           end_date = f"{date_str[:4]}-{date_str[4:6]}-{date_str[6:]}"
           print("End date:", end_date)
       else:
           print("No date found in the input filenames")
           exit()

       output_indices=get_monthly_time_indices(start_date,end_date,input_freq,args.window_size)
    else:
       if args.window_size==0:
           print("Inappropriate window parameter")
           exit()

    # Initial execution time
    time_start = time.time()

    # Perform extraction by blocks of longitudes
    if args.use_mpi:
       # total block to be extracted by current processors
       mpiblocksize = 1 + (args.lon_index_end - args.lon_index_start)//mpisize
       lon0 = args.lon_index_start + mpirank*mpiblocksize
       lon1 = min(lon0 + mpiblocksize - 1,args.lon_index_end)
       # further subdivide it in smaller blocks
       blocksize = 1 + (mpiblocksize-1)//args.num_blocks
    else:
       # total block to be extracted by the single processor
       lon0 = args.lon_index_start
       lon1 = args.lon_index_end
       # subdivide it in smaller blocks
       blocksize = 1 + (lon1-lon0)//args.num_blocks

    #print('blocksize',blocksize,mpirank)

    for lon_block0 in range(lon0, lon1+1, blocksize):
       lon_block1 = min(lon_block0+blocksize-1,lon1)

       print('indices',lon_block0, lon_block1, mpirank)

       # Extract time series
       time_values, time_series = extract_time_series(args.netcdf_files, args.variable_name, args.variable_dim, args.lat_index_start, args.lat_index_end, lon_block0, lon_block1)
    
       # Apply Lanczos filter and subsample
       subsampled_time_values, subsampled_time_series = apply_lanczos_filter(time_values, time_series, args.window_size, args.num_timesteps)

       # Concatenate blocks
       if lon_block0==lon0:
          all_subsampled_time_series = subsampled_time_series
       else:
          all_subsampled_time_series = np.concatenate((all_subsampled_time_series,subsampled_time_series), axis=-1)

       print('time:',time.time()-time_start,', proc:',mpirank)

    # Save to NetCDF file
    if args.use_mpi:
       args.output_file = args.output_file+f'{mpirank:0>4}'

    save_to_netcdf(args.output_file, subsampled_time_values, all_subsampled_time_series, args.variable_name, args.variable_dim)
