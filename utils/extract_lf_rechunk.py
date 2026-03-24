import argparse
from netCDF4 import Dataset

def rechunk(src_file, dst_file):
    """
    Rechunk NetCDF file
    
    Args:
    src_file (list): input file
    dst_file (list): output file
    
    """

    with Dataset(src_file, 'r') as src:
        with Dataset(dst_file, 'w', format='NETCDF4') as dst:

            # Copy dimensions
            dim_sizes = {}
            for name, dim in src.dimensions.items():
                size = len(dim)
                dst.createDimension(name, size)
                dim_sizes[name] = size  # Store dimension sizes for chunking

            # Copy variables
            for name, var in src.variables.items():
                fill_value = var._FillValue if "_FillValue" in var.__dict__ else None
                var_attrs = {k: v for k, v in var.__dict__.items() if k != "_FillValue"}

                # Dynamically determine chunk sizes based on dimensions
                var_dims = var.dimensions
                chunk_sizes = []

                for dim in var_dims:
                    #print("Dim: ",dim,var_dims,dim_sizes[dim])
                    if dim == 'time_counter':  # time should be chunked with size 1
                        chunk_sizes.append(1)
                    elif dim == 'deptht':      # depth should also have chunk size 1
                        chunk_sizes.append(1)
                    else:
                        # Use the full dimension size for the X and Y (2D) or other dimensions
                        chunk_sizes.append(dim_sizes[dim])

                #print("Variable: ",name," Chunksize: ",chunk_sizes)

                # Create variable with optimized chunking
                dst_var = dst.createVariable(
                    name, var.datatype, var_dims,
                    fill_value=fill_value, chunksizes=tuple(chunk_sizes)
                )

                # Copy attributes
                dst_var.setncatts(var_attrs)

                # Copy data
                dst_var[:] = var[:]

    return

if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description='Rechunk NetCDF file for efficient access.')
    parser.add_argument('--input_file', type=str, required=True, help='Name of the input NetCDF file')
    parser.add_argument('--output_file', type=str, required=True, help='Name of the output NetCDF file')
    args = parser.parse_args()

    rechunk(args.input_file, args.output_file)

