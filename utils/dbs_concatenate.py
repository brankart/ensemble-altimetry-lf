import argparse
import xarray as xr

# Define the function to parse command-line arguments
def parse_args():
    parser = argparse.ArgumentParser(description="Concatenate NetCDF files along a single dimension")
    parser.add_argument(
        '-i', '--input', 
        nargs='+', 
        required=True, 
        help='List of input NetCDF files to concatenate'
    )
    parser.add_argument(
        '-o', '--output', 
        required=True, 
        help='Output NetCDF file'
    )
    parser.add_argument(
        '-d', '--dimension', 
        required=True, 
        help='Dimension to concatenate along'
    )
    return parser.parse_args()

# Main function
def main():
    args = parse_args()
    
    input_files = args.input
    output_file = args.output
    concat_dim = args.dimension

    # Open and concatenate the NetCDF files along the specified dimension
    ds = xr.open_mfdataset(input_files, concat_dim=concat_dim, combine='nested')

    # Ensure the original data types are preserved
    # for var_name, var in ds.variables.items():
    #    if 'dtype' in var.encoding:
    #       ds[var_name] = ds[var_name].astype(var.encoding['dtype'])

    # Save the concatenated data to a new NetCDF file
    ds.to_netcdf(output_file)
    print(f"Concatenated data saved to {output_file}")

# Run the main function
if __name__ == "__main__":
    main()
