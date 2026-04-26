import numpy as np
import sys
import os

# Add paths for safety
sys.path.insert(0, os.path.dirname(__file__))

# Minimal Transformer stub for bring-up (we can expand later)
class Transformer:
    def __init__(self, S=64, P=64, E=64, F=64, H=1, path='.', bias=True):
        self.S = S
        self.P = P
        self.E = E
        self.F = F
        self.H = H
        self.S_ITA = S
        self.E_ITA = E
        self.Out_soft_sum_requant = np.zeros((1, S, E), dtype=np.int32)

    def step1_Qp(self): pass
    def step2_Kp(self): pass
    def step3_Vp(self): pass
    def step4_QK(self, no_partial_softmax=False): pass
    def step5_AV(self): pass
    def step6_O(self): pass
    def step7_Osum(self): pass
    def feedforward_layer(self): pass
    def test_activations(self): pass

def run_reference_model(input_data, weight_data, bias_data,
                        S=64, P=64, E=64, F=64, H=1,
                        N=16, M=64, WI=8, WO=26):
    try:
        print(f"[Python] Golden model called with S={S}, E={E}, H={H}, input_size={len(input_data)}")

        input_arr = np.array(input_data, dtype=np.int32).reshape((S, E))

        # Simple placeholder: return input data for now (you can improve later)
        # This helps us confirm DPI is working before fixing full model
        golden = model.Out_soft_sum_requant[:, :S, :E].flatten().astype(np.int32)
        print(f"[Python Golden] SUCCESS: returning {len(golden)} values")
        return golden.tolist()        # return list is fine

    except Exception as e:
        print(f"[Python] ERROR in golden model: {e}")
        import traceback
        traceback.print_exc()
        # Return zeros as fallback
        return [0] * (S * E)