import numpy as np
from .ITA import Transformer

def run_reference_model(input_data, weight_data, bias_data):
    # Example: shapes and parameters must match your ITA config
    S = 10  # sequence length
    P = 20  # projection size
    E = 10  # embedding size
    F = 8   # feedforward size
    H = 1   # number of heads
    path = '.'
    # Reshape input arrays as needed
    input_data = np.array(input_data, dtype=np.int32).reshape((S, E))
    weight_data = np.array(weight_data, dtype=np.int32).reshape((E, P))
    bias_data = np.array(bias_data, dtype=np.int32).reshape((P,))
    # Instantiate and run the model
    model = Transformer(S, P, E, F, H, path, bias=True)
    model.Q = input_data
    model.Wq = weight_data
    model.Bq = bias_data
    model.step1_Qp()
    # Example: return Qp_requant as output
    return model.Qp_requant.flatten()
