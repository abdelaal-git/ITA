import numpy as np
import sys
import os
import struct

# Add paths for safety
sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from softmax import fastSoftmax, realSoftmax, streamingPartialSoftmax
from gelu import gelu_requantize, i_gelu_requantized, get_i_gelu_constants, get_i_gelu_requantized_constants
from util import (generate_matrix_mem, pack_8b_to_word, pack_array_8b_to_word, pack_hex_24b, pack_multihead_8b_to_word,
                   pack_multihead_24b_to_word, random_shuffled_tensor, requantize, split_matrix, to_hex, write_matrix,
                   write_matrix_mem, write_matrix_mem_hex, write_vector_mem_hex, get_almost_symmetric_scaling_factor,
                   error_MAEP)


def requantize_array(x, eps_mult, right_shift, add):
    """Requantize tensor with given parameters."""
    # Scale by eps_mult
    x_scaled = x.astype(np.int32) * eps_mult.astype(np.int32)
    # Right shift
    x_shifted = x_scaled >> right_shift
    # Add offset
    x_requant = x_shifted + add
    return x_requant.astype(np.int8)


def compute_transformer_from_files():
    """
    Read input files written by DPI and compute the full Transformer forward pass.
    """
    # Read config file
    config = {}
    with open("dpi_config.txt", "r") as f:
        for line in f:
            line = line.strip()
            if "=" in line:
                key, val = line.split("=", 1)
                config[key.strip()] = int(val.strip())
    
    S = config["S"]
    P = config["P"]
    E = config["E"]
    F = config["F"]
    H = config["H"]
    N = config["N"]
    M = config["M"]
    WI = config["WI"]
    WO = config["WO"]
    input_size = config["input_size"]
    weight_size = config["weight_size"]
    bias_size = config["bias_size"]
    output_size = config["output_size"]
    
    print(f"[Python] Reading config: S={S}, P={P}, E={E}, F={F}, H={H}")
    
    # Read input data
    with open("dpi_input.bin", "rb") as f:
        input_data = np.frombuffer(f.read(), dtype=np.int32)
    
    # Read weight data
    with open("dpi_weight.bin", "rb") as f:
        weight_data = np.frombuffer(f.read(), dtype=np.int32)
    
    # Read bias data
    with open("dpi_bias.bin", "rb") as f:
        bias_data = np.frombuffer(f.read(), dtype=np.int32)
    
    print(f"[Python] Read data: input={len(input_data)}, weight={len(weight_data)}, bias={len(bias_data)}")
    
    # Reshape input to (S, E)
    X = input_data.reshape((H, S, E)).astype(np.float32)
    input_arr = input_data.reshape((S, E)).astype(np.float32)
    
    # Calculate weight sizes
    wq_size = H * E * P
    wk_size = H * E * P
    wv_size = H * E * P
    wo_size = H * P * E
    wff_size = E * F
    wff2_size = F * E
    
    # Calculate bias sizes
    bq_size = H * P
    bk_size = H * P
    bv_size = H * P
    bo_size = H * E
    bff_size = F
    bff2_size = E
    
    # Parse weights
    idx = 0
    Wq = weight_data[idx:idx + wq_size].reshape((H, E, P))
    idx += wq_size
    Wk = weight_data[idx:idx + wk_size].reshape((H, E, P))
    idx += wk_size
    Wv = weight_data[idx:idx + wv_size].reshape((H, E, P))
    idx += wv_size
    Wo = weight_data[idx:idx + wo_size].reshape((H, P, E))
    idx += wo_size
    Wff = weight_data[idx:idx + wff_size].reshape((E, F))
    idx += wff_size
    Wff2 = weight_data[idx:idx + wff2_size].reshape((F, E))
    
    # Parse biases
    idx = 0
    Bq = bias_data[idx:idx + bq_size].reshape((H, P))
    idx += bq_size
    Bk = bias_data[idx:idx + bk_size].reshape((H, P))
    idx += bk_size
    Bv = bias_data[idx:idx + bv_size].reshape((H, P))
    idx += bv_size
    Bo = bias_data[idx:idx + bo_size].reshape((H, E))
    idx += bo_size
    Bff = bias_data[idx:idx + bff_size].reshape((F,))
    idx += bff_size
    Bff2 = bias_data[idx:idx + bff2_size].reshape((E,))
    
    print(f"[Python] Weights parsed: Wq={Wq.shape}, Wk={Wk.shape}, Wv={Wv.shape}")
    print(f"[Python] Weights parsed: Wo={Wo.shape}, Wff={Wff.shape}, Wff2={Wff2.shape}")
    
    # =============================================================
    # Read Requantization Parameters from config (from SV)
    # =============================================================
    requant_eps_mult = np.zeros((7, H), dtype=np.uint8)
    requant_right_shift = np.zeros((7, H), dtype=np.uint8)
    requant_add = np.zeros((7, H), dtype=np.int8)

    requant_eps_mult_ffn = np.zeros((2, 1), dtype=np.uint8)
    requant_right_shift_ffn = np.zeros((2, 1), dtype=np.uint8)
    requant_add_ffn = np.zeros((2, 1), dtype=np.int8)

    for key in config:
        if key.startswith("eps_mult["):
            parts = key.replace("eps_mult[", "").replace("]", "").split("[")
            i = int(parts[0])
            h = int(parts[1]) if len(parts) > 1 else 0
            requant_eps_mult[i, h] = config[key]
        elif key.startswith("right_shift["):
            parts = key.replace("right_shift[", "").replace("]", "").split("[")
            i = int(parts[0])
            h = int(parts[1]) if len(parts) > 1 else 0
            requant_right_shift[i, h] = config[key]
        elif key.startswith("add["):
            parts = key.replace("add[", "").replace("]", "").split("[")
            i = int(parts[0])
            h = int(parts[1]) if len(parts) > 1 else 0
            requant_add[i, h] = config[key]
        elif key.startswith("eps_mult_ffn["):
            i = int(key.split("[")[1].split("]")[0])
            requant_eps_mult_ffn[i, 0] = config[key]
        elif key.startswith("right_shift_ffn["):
            i = int(key.split("[")[1].split("]")[0])
            requant_right_shift_ffn[i, 0] = config[key]
        elif key.startswith("add_ffn["):
            i = int(key.split("[")[1].split("]")[0])
            requant_add_ffn[i, 0] = config[key]
    
    # GELU constants
    CLIP_LO = -4
    D = 2**20
    gelu_eps_mult, _ = get_almost_symmetric_scaling_factor(CLIP_LO, n_bits=8)
    q_1, q_b, q_c, _, _, _, gelu_rqs_mul, gelu_rqs_shift, gelu_rqs_add, S_out = get_i_gelu_requantized_constants(
        gelu_eps_mult, D)
    
    # ===== STEP 1: Q = input @ Wq + Bq =====
    print("[Python] Step 1: Computing Q = input @ Wq + Bq")
    Q = np.matmul(X, Wq.transpose(0, 2, 1)) + Bq
    Q = np.clip(Q, -2**(WO-1), 2**(WO-1)-1)
    print (f"[Python] Q shape: {Q.shape}")
    Q_requant = requantize_array(Q, requant_eps_mult[0], requant_right_shift[0], requant_add[0])
    print (f"[Python] Q_requant shape: {Q_requant.shape}")
    # ===== STEP 2: K = input @ Wk + Bk =====
    print("[Python] Step 2: Computing K = input @ Wk + Bk")
    K = np.matmul(X, Wk.transpose(0, 2, 1)) + Bk
    K = np.clip(K, -2**(WO-1), 2**(WO-1)-1)
    
    print (f"[Python] K shape: {K.shape}")
    K_requant = requantize_array(K, requant_eps_mult[1], requant_right_shift[1], requant_add[1])
    print (f"[Python] K_requant shape: {K_requant.shape}")
    
    # ===== STEP 3: V = input @ Wv + Bv =====
    print("[Python] Step 3: Computing V = input @ Wv + Bv")
    V = np.matmul(X, Wv.transpose(0, 2, 1)) + Bv 
    V = np.clip(V, -2**(WO-1), 2**(WO-1)-1)
    print (f"[Python] V shape: {V.shape}")
    V_requant = requantize_array(V, requant_eps_mult[2], requant_right_shift[2], requant_add[2])
    print (f"[Python] V_requant shape: {V_requant.shape}")
    
    # ===== STEP 4: A = Q @ K^T =====
    print("[Python] Step 4: Computing A = Q @ K^T")
    A = np.array([np.matmul(Q_requant[h], np.transpose(K_requant[h]), dtype=np.int32) for h in range(H)])
    A = np.clip(A, -2**(WO-1), 2**(WO-1)-1)
    print (f"[Python] A shape: {A.shape}")
    A_requant = requantize_array(A, requant_eps_mult[3], requant_right_shift[3], requant_add[3])
    
    # ===== STEP 4b: Softmax =====
    print("[Python] Step 4b: Computing Softmax")
    if A_requant.ndim == 2:
        A_requant = A_requant.reshape(H, S, S)
    print (f"[Python] A_requant shape: {A_requant.shape}")
    A_real_softmax = realSoftmax(A_requant)
    A_partial_softmax = streamingPartialSoftmax(A_requant)
    
    # ===== STEP 5: O = A_soft @ V =====
    print("[Python] Step 5: Computing O = A_soft @ V")
    O_soft = np.array([
        np.matmul(A_partial_softmax[h].astype(np.uint8), V_requant[h], dtype=np.int32)
        for h in range(H)
    ])
    O_soft = np.clip(O_soft, -2**(WO-1), 2**(WO-1)-1)
    O_soft_requant = requantize_array(O_soft, requant_eps_mult[4], requant_right_shift[4], requant_add[4])
    
    # ===== STEP 6: Out = O @ Wo + Bo =====
    print("[Python] Step 6: Computing Out = O @ Wo + Bo")
    Out_soft = np.array([np.matmul(O_soft_requant[h], Wo[h], dtype=np.int32) for h in range(H)])
    Out_soft = np.clip(Out_soft, -2**(WO-1), 2**(WO-1)-1)
    for h in range(H):
        Out_soft[h] += Bo[h]
    Out_soft_requant = requantize_array(Out_soft, requant_eps_mult[5], requant_right_shift[5], requant_add[5])
    
    # ===== STEP 7: Sum heads =====
    print("[Python] Step 7: Summing heads")
    Out_soft_sum = np.sum(Out_soft_requant, axis=0, dtype=np.int32)
    Out_soft_sum_requant = requantize_array(Out_soft_sum, requant_eps_mult[6], requant_right_shift[6], requant_add[6])
    
    # ===== FEEDFORWARD: FF = input @ Wff + Bff =====
    print("[Python] FFN Step 1: Computing FF = input @ Wff + Bff")
    FF = np.matmul(input_arr, Wff)
    FF += Bff
    FF = np.clip(FF, -2**(WO-1), 2**(WO-1)-1)
    FF_requant = requantize_array(FF, requant_eps_mult_ffn[0], requant_right_shift_ffn[0], requant_add_ffn[0])
    
    # ===== FEEDFORWARD: GELU activation =====
    print("[Python] FFN Step 2: GELU activation")
    vectorized_gelu = np.vectorize(i_gelu_requantized)
    FF_gelu = vectorized_gelu(FF_requant, q_1, q_b, q_c, gelu_rqs_mul, gelu_rqs_shift, gelu_rqs_add)
    FF_gelu = np.clip(FF_gelu, -2**(WO-1), 2**(WO-1)-1)
    
    # ===== FEEDFORWARD: FF2 = FF @ Wff2 + Bff2 =====
    print("[Python] FFN Step 3: Computing FF2 = FF @ Wff2 + Bff2")
    FF2 = np.matmul(FF_gelu, Wff2, dtype=np.int32)
    FF2 += Bff2
    FF2 = np.clip(FF2, -2**(WO-1), 2**(WO-1)-1)
    FF2_requant = requantize_array(FF2, requant_eps_mult_ffn[1], requant_right_shift_ffn[1], requant_add_ffn[1])
    
    # ===== FINAL OUTPUT: Out + FF2 =====
    print("[Python] Final: Computing output = Out + FF2")
    output = Out_soft_sum_requant + FF2_requant
    output = np.clip(output, -2**(WO-1), 2**(WO-1)-1)
    
    # Flatten to (S * E)
    output_flat = output.flatten().astype(np.int32)
    
    print(f"[Python] Output shape: {output.shape}, flattened: {output_flat.shape}")
    
    # Pad or truncate to expected size
    if len(output_flat) < output_size:
        output_flat = np.pad(output_flat, (0, output_size - len(output_flat)), mode='constant')
    elif len(output_flat) > output_size:
        output_flat = output_flat[:output_size]
    
    # Write binary file
    output_file = "golden_output.bin"
    with open(output_file, 'wb') as f:
        f.write(output_flat.tobytes())
    
    print(f"[Python] SUCCESS: Wrote {len(output_flat)} values to {output_file}")
    
    return output_flat.tolist()


def generate_golden_binary(input_data, weight_data, bias_data,
                           S=64, P=64, E=64, F=64, H=1,
                           N=16, M=64, WI=8, WO=26):
    """
    Legacy function for standalone testing.
    Generate golden output and save to binary file for DPI consumption.
    """
    try:
        print(f"[Python] Generating golden output: S={S}, P={P}, E={E}, F={F}, H={H}")
        
        # Compute the full transformer
        output = compute_transformer_from_files()
        
        output_arr = np.array(output, dtype=np.int32)
        
        # Pad or truncate to expected size (S * E)
        expected_size = S * E
        if len(output_arr) < expected_size:
            output_arr = np.pad(output_arr, (0, expected_size - len(output_arr)), mode='constant')
        elif len(output_arr) > expected_size:
            output_arr = output_arr[:expected_size]
        
        # Write binary file
        output_file = "golden_output.bin"
        with open(output_file, 'wb') as f:
            f.write(output_arr.tobytes())
        
        print(f"[Python] SUCCESS: Wrote {len(output_arr)} values to {output_file}")
        return output_arr.tolist()
        
    except Exception as e:
        print(f"[Python] ERROR: {e}")
        import traceback
        traceback.print_exc()
        # Return zeros as fallback
        return [0] * (S * E)


def run_reference_model(input_data, weight_data, bias_data,
                        S=64, P=64, E=64, F=64, H=1,
                        N=16, M=64, WI=8, WO=26):
    """
    Entry point for DPI call - generates golden output.
    This version reads from files to avoid large DPI array transfers.
    """
    return generate_golden_binary(
        input_data, weight_data, bias_data,
        S, P, E, F, H, N, M, WI, WO
    )


# Allow standalone execution for testing
if __name__ == "__main__":
    # Check if input files exist
    if os.path.exists("dpi_config.txt") and os.path.exists("dpi_input.bin"):
        print("[Python] Running in file-based mode")
        compute_transformer_from_files()
    else:
        # Test with simple data
        print("[Python] Running in standalone test mode")
        test_input = [i for i in range(64)]
        test_weight = [i for i in range(64)]
        test_bias = [0] * 64
        
        result = run_reference_model(test_input, test_weight, test_bias, S=8, P=8, E=8, F=8, H=1)
        print(f"Standalone test returned {len(result)} values")
