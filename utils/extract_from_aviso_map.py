import numpy as np
from netCDF4 import Dataset
#from scipy.interpolate import RegularGridInterpolator
from scipy.interpolate import RectBivariateSpline
import pyensdam as edam

# Interpolate data from input grid to output grid
def interpolate_data(issh,ilon,ilat,olon,olat):

  #interpolator = RegularGridInterpolator((ilat,ilon), issh, method='cubic', bounds_error=False)
  interpolator = RectBivariateSpline(ilat, ilon, issh)

  #ossh = interpolator((olat, olon))
  ossh = interpolator(olat, olon, grid=False)

  return ossh

# Read input grid from grid file
def read_input_grid(grid_file):
  # Open NetCDF file
  ncfil_file = Dataset(grid_file, 'r')
  ncfil_lon = ncfil_file.variables['longitude']
  ncfil_lat = ncfil_file.variables['latitude']
  ncfil_tim = ncfil_file.variables['time']

  # Read grid arrays
  ilon = ncfil_lon[:]
  ilat = ncfil_lat[:]
  itim = ncfil_tim[:]

  # Close NetCDF file
  ncfil_file.close()

  return ilon,ilat,itim

# Read output grid from grid file
def read_output_grid(grid_file):
  # Open NetCDF file
  ncfil_file = Dataset(grid_file, 'r')
  ncfil_lon = ncfil_file.variables['nav_lon']
  ncfil_lat = ncfil_file.variables['nav_lat']

  # Read grid arrays
  olon = ncfil_lon[:]
  olat = ncfil_lat[:]

  # Close NetCDF file
  ncfil_file.close()

  return olon,olat

# Read output mask from mask file
def read_output_mask(mask_file):
  # Open NetCDF file
  ncfil_file = Dataset(mask_file, 'r')
  ncfil_mask = ncfil_file.variables['sossheig']

  # Read array
  omask = ncfil_mask[0]

  # Close NetCDF file
  ncfil_file.close()

  return omask

# Read input data from input file
def read_input_data(infile):
  # Open NetCDF file
  ncfil_file = Dataset(infile, 'r')
  ncfil_data = ncfil_file.variables['adt']

  # Read array
  issh = ncfil_data[0]

  # Close NetCDF file
  ncfil_file.close()

  return issh

# Write output data from grid file
def write_output_data(outfile,ossh,itim):
  # Open NetCDF file
  ncfil_file = Dataset(outfile, 'r+')
  ncfil_data = ncfil_file.variables['sossheig']
  ncfil_time = ncfil_file.variables['time_counter']

  # Read grid arrays
  ncfil_data[0] = ossh
  ncfil_time[0] = itim

  # Close NetCDF file
  ncfil_file.close()

  return

if __name__ == "__main__":
  import argparse

  # Parse command-line arguments
  parser = argparse.ArgumentParser(prog='extract_from_aviso_map',description='Extract region from Aviso mappped file')
  parser.add_argument('-i',      '--input_file',       type=str,   required=True,  help='name of input file with perturbations')
  parser.add_argument('-grid',   '--grid_file',        type=str,   required=True,  help='name of output grid file')
  parser.add_argument('-o',      '--output_file',      type=str,   required=True,  help='name of (existing) output file')
  parser.add_argument('-mask',   '--mask_file',        type=str,   required=False, help='name of mask file')
  args = parser.parse_args()

  # Read input grid (1d)
  ilon, ilat, itim = read_input_grid(args.input_file)

  # Read output grid (2d)
  olon, olat = read_output_grid(args.grid_file)

  # Read output mask (2d)
  omask = read_output_mask(args.mask_file)
  omask = omask.filled(-9999.)

  # Read input data
  issh = read_input_data(args.input_file)
  issh = issh.filled(-9999.)

  # Unmask input data
  edam.interpolation.unmask_spval = -9999.
  edam.interpolation.unmask_max = 1000
  edam.interpolation.unmask_window = 5
  edam.interpolation.unmask2D(issh)

  # Interpolate on output grid
  ossh = interpolate_data(issh,ilon,ilat,olon,olat)

  # Remask output data
  maskval = -9999.
  ossh[np.where(omask==maskval)] = 1.e20

  # Write output data
  write_output_data(args.output_file,ossh,itim)

