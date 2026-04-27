import numpy as np
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))

from softmax import streamingPartialSoftmax
from gelu import i_gelu_requantized, get_i_gelu_requantized_constants
from util import get_almost_symmetric_scaling_factor


def write_debug_bin(name: str, data):
    """Write array to debug file"""
    arr = np.asarray(data).astype(np.int32).flatten()
    with open(f"golden_{name}.bin", "wb") as f:
        f.write(arr.tobytes())
    print(f"[Python] Saved debug: golden_{name}.bin  shape={data.shape if hasattr(data,'shape') else len(arr)}")
    write_debug_txt(name, data)


def requantize_scalar(x, eps_mult=1, right_shift=8, add=0):
    x = x.astype(np.int32)
    x = (x * eps_mult) >> right_shift
    x = x + add
    return np.clip(x, -128, 127).astype(np.int8)

def write_debug_txt(name: str, data, comment=""):
    """Write human-readable text file"""
    arr = np.asarray(data).astype(np.int32).flatten()
    with open(f"golden_{name}.txt", "w") as f:
        f.write(f"// {comment} - shape={data.shape if hasattr(data,'shape') else arr.shape} - {len(arr)} elements\n")
        for i, val in enumerate(arr):
            if i % 8 == 0:
                f.write("\n")
            f.write(f"{val:08x} ")          # hex
            # f.write(f"{val:10d} ")        # uncomment for decimal
    print(f"[Python] Saved readable: golden_{name}.txt")


def compute_transformer_from_files():
    print("[Python] === Starting Transformer Reference Model (Debug Mode) ===")

    # ====================== Config ======================
    config = {}
    with open("dpi_config.txt", "r") as f:
        for line in f:
            if "=" in line:
                key, val = [x.strip() for x in line.split("=", 1)]
                config[key] = int(val)

    S = config.get("S", 64)
    E = config.get("E", 64)
    F = config.get("F", 64)
    H = config.get("H", 1)
    P = config.get("P", E)

    eps_mult    = config.get("eps_mult", 1)
    right_shift = config.get("right_shift", 8)
    add_val     = config.get("add", 0)

    print(f"[Python] Config: S={S} E={E} F={F} H={H} | Requant: mult={eps_mult}, shift={right_shift}, add={add_val}")

    # ====================== Load Data ======================
    input_data  = np.frombuffer(open("dpi_input.bin",  "rb").read(), dtype=np.int32)
    weight_data = np.frombuffer(open("dpi_weight.bin", "rb").read(), dtype=np.int32)
    bias_data   = np.frombuffer(open("dpi_bias.bin",   "rb").read(), dtype=np.int32)

    X = input_data.reshape((S, E)).astype(np.float32)
    print(f"[Python] Input shape: {X.shape}")

    # ====================== Weights & Biases ======================
    idx = 0
    Wq = weight_data[idx:idx+H*E*P].reshape((H, E, P)).astype(np.float32); idx += H*E*P
    Wk = weight_data[idx:idx+H*E*P].reshape((H, E, P)).astype(np.float32); idx += H*E*P
    Wv = weight_data[idx:idx+H*E*P].reshape((H, E, P)).astype(np.float32); idx += H*E*P
    Wo = weight_data[idx:idx+H*P*E].reshape((H, P, E)).astype(np.float32); idx += H*P*E
    Wff  = weight_data[idx:idx+E*F].reshape((E, F)).astype(np.float32); idx += E*F
    Wff2 = weight_data[idx:idx+F*E].reshape((F, E)).astype(np.float32)

    idx = 0
    Bq = bias_data[idx:idx+H*P].reshape((H, P)).astype(np.float32); idx += H*P
    Bk = bias_data[idx:idx+H*P].reshape((H, P)).astype(np.float32); idx += H*P
    Bv = bias_data[idx:idx+H*P].reshape((H, P)).astype(np.float32); idx += H*P
    Bo = bias_data[idx:idx+H*E].reshape((H, E)).astype(np.float32); idx += H*E
    Bff  = bias_data[idx:idx+F].astype(np.float32); idx += F
    Bff2 = bias_data[idx:idx+E].astype(np.float32)

    # ====================== Forward Pass ======================
    print("[Python] Step 1-3: Computing Q, K, V...")
    Q = np.matmul(X, Wq.transpose(0, 2, 1)) + Bq
    K = np.matmul(X, Wk.transpose(0, 2, 1)) + Bk
    V = np.matmul(X, Wv.transpose(0, 2, 1)) + Bv

    write_debug_bin("Q_float", Q)
    write_debug_bin("K_float", K)
    write_debug_bin("V_float", V)

    Qr = requantize_scalar(Q, eps_mult, right_shift, add_val)
    Kr = requantize_scalar(K, eps_mult, right_shift, add_val)
    Vr = requantize_scalar(V, eps_mult, right_shift, add_val)

    write_debug_bin("Q", Qr)
    write_debug_bin("K", Kr)
    write_debug_bin("V", Vr)

    print("[Python] Step 4: Computing A = Q @ K^T")
    A = np.zeros((H, S, S), dtype=np.int32)
    for h in range(H):
        A[h] = np.matmul(Qr[h], Kr[h].T)
    write_debug_bin("A", A)

    Ar = requantize_scalar(A, eps_mult, right_shift, add_val)
    write_debug_bin("A_requant", Ar)

    print("[Python] Step 4b: Softmax")
    A_soft = streamingPartialSoftmax(Ar)
    write_debug_bin("A_soft", A_soft)

    print("[Python] Step 5-7: Attention Output + Head Sum")
    O = np.zeros((H, S, E), dtype=np.int32)
    for h in range(H):
        O[h] = np.matmul(A_soft[h].astype(np.int32), Vr[h])
    Or = requantize_scalar(O, eps_mult, right_shift, add_val)
    write_debug_bin("O", Or)

    Out = np.zeros((H, S, E), dtype=np.int32)
    for h in range(H):
        Out[h] = np.matmul(Or[h], Wo[h]) + Bo[h]
    Outr = requantize_scalar(Out, eps_mult, right_shift, add_val)
    write_debug_bin("Out_per_head", Outr)

    Out_sum = np.sum(Outr, axis=0, dtype=np.int32)
    write_debug_bin("Out_sum", Out_sum)

    # ====================== FFN ======================
    print("[Python] FFN Step 1: FF = X @ Wff + Bff")
    FF = np.matmul(X, Wff) + Bff
    FF_r = requantize_scalar(FF, eps_mult, right_shift, add_val)
    write_debug_bin("FF", FF_r)

    print("[Python] FFN Step 2: GELU")
    CLIP_LO = -4.0
    gelu_eps_mult, _ = get_almost_symmetric_scaling_factor(CLIP_LO, n_bits=8)
    q_1, q_b, q_c, _, _, _, gelu_mul, gelu_shift, gelu_add, _ = \
        get_i_gelu_requantized_constants(gelu_eps_mult, 2**20)

    FF_gelu = np.vectorize(i_gelu_requantized)(FF_r, q_1, q_b, q_c, gelu_mul, gelu_shift, gelu_add)
    write_debug_bin("FF_gelu", FF_gelu)

    print("[Python] FFN Step 3: FF2 = FF_gelu @ Wff2 + Bff2")
    FF2 = np.matmul(FF_gelu, Wff2) + Bff2
    FF2_r = requantize_scalar(FF2, eps_mult, right_shift, add_val)
    write_debug_bin("FF2", FF2_r)

    # ====================== Final Output ======================
    print("[Python] Final: Out_sum + FF2")
    final_out = Out_sum + FF2_r
    final_out = np.clip(final_out, -2**25, 2**25 - 1).astype(np.int32)
    write_debug_bin("final", final_out)

    # Main golden output for UVM comparison
    with open("golden_output.bin", "wb") as f:
        f.write(final_out.flatten().tobytes())

    print(f"[Python] ✅ SUCCESS: Wrote main golden_output.bin ({final_out.size} values)")
    print("[Python] Debug files written for all intermediate layers.")


if __name__ == "__main__":
    if os.path.exists("dpi_config.txt"):
        print("[Python] Running in file-based debug mode")
        compute_transformer_from_files()
    else:
        print("[Python] No dpi_config.txt found.")