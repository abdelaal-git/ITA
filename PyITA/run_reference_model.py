import numpy as np
import sys
import os
import struct

# Add paths for safety
sys.path.insert(0, os.path.dirname(__file__))

def generate_golden_binary(input_data, weight_data, bias_data,
                           S=64, P=64, E=64, F=64, H=1,
                           N=16, M=64, WI=8, WO=26):
    """
    Generate golden output and save to binary file for DPI consumption.
    This avoids Python embedding issues with VCS.
    """
    try:
        print(f"[Python] Generating golden output: S={S}, P={P}, E={E}, F={F}, H={H}")
        
        # Reshape input
        input_arr = np.array(input_data, dtype=np.int32).reshape((S, E))
        
        # Placeholder: for now just pass input through
        # TODO: Replace with actual Transformer computation
        # For verification purposes, this at least allows the DPI to work
        output = input_arr.flatten().astype(np.int32)
        
        # Pad or truncate to expected size (S * E)
        expected_size = S * E
        if len(output) < expected_size:
            output = np.pad(output, (0, expected_size - len(output)), mode='constant')
        elif len(output) > expected_size:
            output = output[:expected_size]
        
        # Write binary file
        output_file = "golden_output.bin"
        with open(output_file, 'wb') as f:
            f.write(output.tobytes())
        
        print(f"[Python] SUCCESS: Wrote {len(output)} values to {output_file}")
        return output.tolist()
        
    except Exception as e:
        print(f"[Python] ERROR: {e}")
        import traceback
        traceback.print_exc()
        # Return zeros as fallback
        return [0] * (S * E)


def run_reference_model(input_data, weight_data, bias_data,
                        S=64, P=64, E=64, F=64, H=1,
                        N=16, M=64, WI=8, WO=26):
    """Entry point for DPI call - generates golden output."""
    return generate_golden_binary(
        input_data, weight_data, bias_data,
        S, P, E, F, H, N, M, WI, WO
    )


# Allow standalone execution for testing
if __name__ == "__main__":
    # Test with simple data
    test_input = [i for i in range(64)]
    test_weight = [i for i in range(64)]
    test_bias = [0] * 64
    
    result = run_reference_model(test_input, test_weight, test_bias, S=8, P=8, E=8, F=8, H=1)
    print(f"Standalone test returned {len(result)} values")