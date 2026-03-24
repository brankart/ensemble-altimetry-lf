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

    #print("series:",filtered_time_series.tolist())
    #print("values:",time_values.tolist())

    print("size series:",filtered_time_series.size)
    print("size values:",time_values.size)

    # Subsample the filtered time series
    # (with compensation for phase delay in lfilter)
    if num_timesteps == -1:
      subsampled_time_series = filtered_time_series[output_indices+window_size//2]
      subsampled_time_values = time_values[output_indices]
    else:
      subsampled_time_series = filtered_time_series[window_size::num_timesteps]
      subsampled_time_values = time_values[(window_size+1)//2:-window_size//2:num_timesteps]

    print("subsampled_time_series",subsampled_time_series)
    print("subsampled_time_values",subsampled_time_values)

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

    # Initial execution time
    time_start = time.time()

    start = 15705.
    size = 10000
    step = 1.

    # Format the date as YYYY-MM-DD
    # start_date = f"{date_str[:4]}-{date_str[4:6]}-{date_str[6:]}"
    start_date = "1993-01-01"
    end_date = "2012-12-31"

    input_freq = 1
    window_size = 923
    num_timesteps = -1

    # Get monthly indices in timeseries in case of daily outputs
    output_indices=get_monthly_time_indices(start_date,end_date,input_freq,window_size)

    # Generate the arrays
    time_values = np.arange(start, start + size * step, step)
    time_series = np.arange(start, start + size * step, step)

    # Apply Lanczos filter and subsample
    subsampled_time_values, subsampled_time_series = apply_lanczos_filter(time_values, time_series, window_size, num_timesteps)

    # Print execution time
    print('time:',time.time()-time_start)
