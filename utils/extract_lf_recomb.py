import argparse
import netCDF4 as nc
import numpy as np

def extract_block(netcdf_file, variable_name, variable_dim):
    """
    Extracts a contiguous block of time series from a series of successive 4D NetCDF files based on provided indices.
    
    Args:
    netcdf_file (list): NetCDF file with block to extract.
    variable_name (str): Name of the variable in the NetCDF file.
    variable_dim (int): Dimension of variable in the NetCDF file (2 or 3).
    
    Returns:
    block: extrcated block of data
    """
    # Open the NetCDF file
    nc_data = nc.Dataset(netcdf_file, 'r')

    # Extract time series based on provided indices
    if variable_dim==2:
      block = nc_data.variables[variable_name][:, :, :]
    elif variable_dim==3:
      block = nc_data.variables[variable_name][:, :, :, :]
    else:
      raise ValueError("Bad variable dimension in extract_time_series.")

    # Close the NetCDF file
    nc_data.close()

    return block

def open_netcdf(filename, fileglob, variable_name, variable_dim, longitude_size):
    """
    Open and initialize output NetCDF file
    
    Args:
    filename (str): Name of the NetCDF file to save.
    fileglob (list): Global reference NetCDF file
    variable_name (str): Name of the variable.
    variable_dim (int): dimension of the variable.
    longitude_size (int) : global size of longitude dimension.
    """
    nc_file = nc.Dataset(filename, 'w', format='NETCDF4')
    nc_file_ref = nc.Dataset(filename+'0000', 'r', format='NETCDF4')
    nc_file_glo = nc.Dataset(fileglob, 'r', format='NETCDF4')

    # Create dimensions
    nc_file.createDimension('time_counter', nc_file_ref.dimensions['time'].size)
    if variable_dim==2:
      nc_file.createDimension('y', nc_file_ref.dimensions['lat'].size)
      nc_file.createDimension('x', longitude_size)
    elif variable_dim==3:
      nc_file.createDimension('deptht', nc_file_ref.dimensions['depth'].size)
      nc_file.createDimension('y', nc_file_ref.dimensions['lat'].size)
      nc_file.createDimension('x', None)

    # Create variables
    time_var = nc_file.createVariable('time_counter', 'f8', ('time_counter',))
    if variable_dim==3:
      depth_var = nc_file.createVariable('deptht', 'f4', ('deptht',))
    lat_var = nc_file.createVariable('nav_lat', 'f4', ('y','x',))
    lon_var = nc_file.createVariable('nav_lon', 'f4', ('y','x',))
    if variable_dim==2:
      variable_var = nc_file.createVariable(variable_name, 'f4', ('time_counter', 'y', 'x',),fill_value=1.e+20)
    elif variable_dim==3:
      variable_var = nc_file.createVariable(variable_name, 'f4', ('time_counter', 'deptht', 'y', 'x',),fill_value=1.e+20)

    variable_var.setncattr('missing_value', 1.e+20)

    # Fill coordinates values
    time_var[:] = nc_file_ref.variables['time'][:]
    lat_var[:,:] = nc_file_glo.variables['nav_lat'][:,:]
    lon_var[:,:] = nc_file_glo.variables['nav_lon'][:,:]
    if variable_dim==3:
      depth_var[:] = nc_file_glo.variables['deptht'][:]

    return nc_file

def save_block(nc_file, variable_name, variable_dim, lon_index_start, lon_index_end, block):
    """
    Saves block and time series to a NetCDF file.
    
    Args:
    nc_file : NetCDF dataset
    variable_name (str): Name of the variable.
    variable_dim (int): dimension of the variable.
    lon_index_start (int): Starting index of the longitude coordinate.
    lon_index_end (int): Ending index of the longitude coordinate.
    block: block of data to write.
    """
    # Write block in file
    if variable_dim==2:
      nc_file.variables[variable_name][:, :, lon_index_start-1:lon_index_end] = block
    elif variable_dim==3:
      for lonblock in range(lon_index_end-lon_index_start+1):
        lon = lon_index_start-1+lonblock
        nc_file.variables[variable_name][:, :, :, lon] = block[:,:,:,lonblock]

if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description='Extract time series from a series of NetCDF files, apply Lanczos filter, and save to NetCDF file.')
    parser.add_argument('netcdf_files', nargs='+', type=str, help='List of paths to the NetCDF files')
    parser.add_argument('--variable_name', type=str, required=True, help='Name of the variable in the NetCDF file')
    parser.add_argument('--variable_dim', type=int, required=True, help='Dimension of the variable in the NetCDF file')
    parser.add_argument('--lon_index_start', type=int, required=True, help='Starting index of the longitude coordinate')
    parser.add_argument('--lon_index_end', type=int, required=True, help='Ending index of the longitude coordinate')
    parser.add_argument('--num_blocks', type=int, required=True, help='Number of longitue blocks (by processor if MPI)')
    parser.add_argument('--output_file', type=str, required=True, help='Name of the output NetCDF file')
    args = parser.parse_args()

    # Number of blocks
    mpisize = args.num_blocks
    # Block size
    mpiblocksize = 1 + (args.lon_index_end - args.lon_index_start)//mpisize

    # Initialize output NetCDF file
    ofile = args.output_file
    longitude_size = args.lon_index_end - args.lon_index_start + 1
    fileglob = args.netcdf_files[0]
    nc_file = open_netcdf(ofile, fileglob, args.variable_name, args.variable_dim, longitude_size)

    # Loop on blocks, read and write blocks of longitudes
    for mpirank in range(mpisize):

       lon0 = args.lon_index_start + mpirank*mpiblocksize
       lon1 = min(lon0 + mpiblocksize - 1,args.lon_index_end)

       print('Block:',mpirank,lon0,lon1)

       # Extract block
       ifile = args.output_file+f'{mpirank:0>4}'
       block = extract_block(ifile, args.variable_name, args.variable_dim)

       # Save block
       save_block(nc_file, args.variable_name, args.variable_dim, lon0, lon1, block)

    # Close the NetCDF file
    nc_file.close()

