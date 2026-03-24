import argparse
import xarray as xr

# Define the function to parse command-line arguments
def parse_args():
    parser = argparse.ArgumentParser(description="Concatenate NetCDF files along a single dimension")
    parser.add_argument(
        '-i', '--input', 
        required=True, 
        help='Input NetCDF file'
    )
    parser.add_argument(
        '-o', '--output', 
        required=True, 
        help='Output NetCDF file'
    )
    parser.add_argument(
        '-v', '--variables',
        nargs='+',
        required=True,
        help='List of variables to include in the output file'
    )
    parser.add_argument(
        '-lonmin',
        type=float,
        required=True, 
        help='Minimum longitude'
    )
    parser.add_argument(
        '-lonmax',
        type=float,
        required=True, 
        help='Maximum longitude'
    )
    parser.add_argument(
        '-latmin',
        type=float,
        required=True, 
        help='Minimum longitude'
    )
    parser.add_argument(
        '-latmax',
        type=float,
        required=True, 
        help='Maximum longitude'
    )
    return parser.parse_args()

# Main function
def main():
    args = parse_args()
    
    input_file = args.input
    output_file = args.output
    variables_to_include = args.variables
    lonmin = args.lonmin
    lonmax = args.lonmax
    latmin = args.latmin
    latmax = args.latmax

    # Open and concatenate the NetCDF files along the specified dimension
    ds = xr.open_dataset(input_file)

    # Correct longitude to be in -180, 180
    if 'longitude' in ds:
        ds['longitude'] = xr.where(ds['longitude'] > 180, ds['longitude'] - 360, ds['longitude'])

    # Correct longitude to be in -180, 180
    if 'latitude' in ds:
        ds['latitude'] = xr.where(ds['latitude'] > 180, ds['latitude'] - 0, ds['latitude'])

    # Select data
    condition = (ds['longitude'] > lonmin) & (ds['longitude'] < lonmax) & (ds['latitude'] > latmin) & (ds['latitude'] < latmax)
    selected_data = ds.where(condition, drop=True)

    # Compute adt from sla and mdt
    if 'mdt' in ds and 'sla_filtered' in selected_data:
        selected_data['adt'] = selected_data['mdt'] + selected_data['sla_filtered']

    # Select the variables to include in the output file
    selected_var = selected_data[variables_to_include]

    # Save the selected data to a new NetCDF file
    selected_var.to_netcdf(output_file)
    print(f"Extracted data saved to {output_file}")

# Run the main function
if __name__ == "__main__":
    main()
