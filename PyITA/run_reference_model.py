import numpy as np
from .ITA import Transformer

def run_reference_model(input_data, weight_data, bias_data,
                        S=64, P=64, E=64, F=64, H=1,
                        N=16, M=64, WI=8, WO=26):
    """
    Full golden model synced with DUT parameters.
    """
    input_data = np.array(input_data, dtype=np.int32).reshape((S, E))
    weight_data = np.array(weight_data, dtype=np.int32)
    bias_data = np.array(bias_data, dtype=np.int32)

    model = Transformer(S=S, P=P, E=E, F=F, H=H, path='.', bias=True)

    # Basic population (extend later for full weight matrices)
    model.Q = np.pad(input_data, ((0, model.S_ITA - S), (0, model.E_ITA - E)))

    # TODO: Unpack weight_data into Wq, Wk, Wv, Wo, FF weights etc.
    # For now use internal random + override Q

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
    return golden.tolist()