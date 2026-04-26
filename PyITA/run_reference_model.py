import numpy as np
from .ITA import Transformer

def run_reference_model(input_data, weight_data, bias_data,
                        S=64, P=64, E=64, F=64, H=1,
                        N=16, M=64, WI=8, WO=26):
    try:
        input_data = np.array(input_data, dtype=np.int32).reshape((S, E))
        # ... your model setup ...

        model = Transformer(S=S, P=P, E=E, F=F, H=H, path='.', bias=True)
        # Populate inputs (you may need better weight unpacking later)
        model.Q = np.pad(input_data, ((0, model.S_ITA - S), (0, model.E_ITA - E)))

        model.step1_Qp()
        model.step2_Kp()
        model.step3_Vp()
        model.step4_QK(no_partial_softmax=False)
        model.step5_AV()
        model.step6_O()
        model.step7_Osum()
        model.feedforward_layer()
        model.test_activations()

        golden = model.Out_soft_sum_requant[:, :S, :E].flatten().astype(np.int32)
        print(f"Python golden model success: returned {len(golden)} values")
        return golden.tolist()

    except Exception as e:
        print(f"ERROR in Python golden model: {e}")
        import traceback
        traceback.print_exc()
        return [0] * (S * E)   # return zeros instead of crashing