#include <svdpi.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

// Helper functions - WO is passed as parameter
static inline int32_t clip_int32(int32_t val, int wo) {
    int32_t max_val = (1 << (wo - 1)) - 1;
    int32_t min_val = -(1 << (wo - 1));
    if (val > max_val) return max_val;
    if (val < min_val) return min_val;
    return val;
}

static inline int8_t clip_int8(int8_t val) {
    if (val > 127) return 127;
    if (val < -128) return -128;
    return val;
}

// Requantize function
static void requantize_array(int32_t* input, int8_t* output, int size,
                             uint8_t eps_mult, uint8_t right_shift, int8_t add) {
    for (int i = 0; i < size; i++) {
        int32_t scaled = (int32_t)input[i] * (int32_t)eps_mult;
        int32_t shifted = scaled >> right_shift;
        int32_t result = shifted + (int32_t)add;
        output[i] = clip_int8((int8_t)result);
    }
}

// Simplified GELU approximation
static int8_t gelu_approx(int8_t x) {
    int32_t x32 = (int32_t)x;
    int32_t abs_x = (x32 >= 0) ? x32 : -x32;
    int32_t result = (abs_x > 127) ? 127 : x32;
    return clip_int8((int8_t)result);
}

// Softmax approximation
static void softmax_int8(int8_t* input, int8_t* output, int size) {
    int8_t max_val = input[0];
    for (int i = 1; i < size; i++) {
        if (input[i] > max_val) max_val = input[i];
    }
    
    int32_t sum = 0;
    for (int i = 0; i < size; i++) {
        int32_t diff = (int32_t)input[i] - (int32_t)max_val;
        if (diff < -10) diff = -10;
        int32_t exp_val = (diff >= 0) ? (256 << diff) : (256 >> (-diff));
        sum += exp_val;
    }
    
    for (int i = 0; i < size; i++) {
        int32_t diff = (int32_t)input[i] - (int32_t)max_val;
        if (diff < -10) diff = -10;
        int32_t exp_val = (diff >= 0) ? (256 << diff) : (256 >> (-diff));
        int32_t prob = (exp_val * 255) / (sum > 0 ? sum : 1);
        output[i] = clip_int8((int8_t)(prob - 128));
    }
}

// Full Transformer computation in C
static void compute_transformer_c(
    const int* input_data, int input_size,
    const int* weight_data, int weight_size,
    const int* bias_data, int bias_size,
    int S, int P, int E, int F, int H, int WO,
    int* output_data, int output_size)
{
    printf("DPI: Computing full Transformer model in C (WO=%d)\n", WO);
    
    // Calculate sizes
    int wq_size = H * E * P;
    int wk_size = H * E * P;
    int wv_size = H * E * P;
    int wo_size = H * P * E;
    int wff_size = E * F;
    int wff2_size = F * E;
    
    int bq_size = H * P;
    int bk_size = H * P;
    int bv_size = H * P;
    int bo_size = H * E;
    int bff_size = F;
    int bff2_size = E;
    
    // Parse weights
    int idx = 0;
    const int* Wq = &weight_data[idx]; idx += wq_size;
    const int* Wk = &weight_data[idx]; idx += wk_size;
    const int* Wv = &weight_data[idx]; idx += wv_size;
    const int* Wo = &weight_data[idx]; idx += wo_size;
    const int* Wff = &weight_data[idx]; idx += wff_size;
    const int* Wff2 = &weight_data[idx];
    
    // Parse biases
    idx = 0;
    const int* Bq = &bias_data[idx]; idx += bq_size;
    const int* Bk = &bias_data[idx]; idx += bk_size;
    const int* Bv = &bias_data[idx]; idx += bv_size;
    const int* Bo = &bias_data[idx]; idx += bo_size;
    const int* Bff = &bias_data[idx]; idx += bff_size;
    const int* Bff2 = &bias_data[idx];
    
    // Requantization parameters
    uint8_t eps_mult = 100;
    uint8_t right_shift = 5;
    int8_t add = 0;
    
    // Working buffers
    int32_t* Q = (int32_t*)malloc(H * S * P * sizeof(int32_t));
    int32_t* K = (int32_t*)malloc(H * S * P * sizeof(int32_t));
    int32_t* V = (int32_t*)malloc(H * S * P * sizeof(int32_t));
    int8_t* Q_requant = (int8_t*)malloc(H * S * P * sizeof(int8_t));
    int8_t* K_requant = (int8_t*)malloc(H * S * P * sizeof(int8_t));
    int8_t* V_requant = (int8_t*)malloc(H * S * P * sizeof(int8_t));
    int32_t* A = (int32_t*)malloc(H * S * S * sizeof(int32_t));
    int8_t* A_requant = (int8_t*)malloc(H * S * S * sizeof(int8_t));
    int8_t* A_softmax = (int8_t*)malloc(H * S * S * sizeof(int8_t));
    int32_t* O_soft = (int32_t*)malloc(H * S * P * sizeof(int32_t));
    int8_t* O_soft_requant = (int8_t*)malloc(H * S * P * sizeof(int8_t));
    int32_t* Out = (int32_t*)malloc(H * S * E * sizeof(int32_t));
    int8_t* Out_requant = (int8_t*)malloc(H * S * E * sizeof(int8_t));
    int32_t* Out_sum = (int32_t*)malloc(S * E * sizeof(int32_t));
    int8_t* Out_sum_requant = (int8_t*)malloc(S * E * sizeof(int8_t));
    int32_t* FF = (int32_t*)malloc(S * F * sizeof(int32_t));
    int8_t* FF_requant = (int8_t*)malloc(S * F * sizeof(int8_t));
    int8_t* FF_gelu = (int8_t*)malloc(S * F * sizeof(int8_t));
    int32_t* FF2 = (int32_t*)malloc(S * E * sizeof(int32_t));
    int8_t* FF2_requant = (int8_t*)malloc(S * E * sizeof(int8_t));
    int32_t* final_output = (int32_t*)malloc(S * E * sizeof(int32_t));
    
    if (!Q || !K || !V || !Q_requant || !K_requant || !V_requant ||
        !A || !A_requant || !A_softmax || !O_soft || !O_soft_requant ||
        !Out || !Out_requant || !Out_sum || !Out_sum_requant ||
        !FF || !FF_requant || !FF_gelu || !FF2 || !FF2_requant || !final_output) {
        printf("DPI: ERROR - Memory allocation failed\n");
        goto cleanup;
    }
    
    // ===== STEP 1: Q = input @ Wq + Bq =====
    printf("DPI: Step 1 - Computing Q = input @ Wq + Bq\n");
    for (int h = 0; h < H; h++) {
        for (int s = 0; s < S; s++) {
            for (int p = 0; p < P; p++) {
                int64_t sum = 0;
                for (int e = 0; e < E; e++) {
                    sum += (int64_t)input_data[s * E + e] * (int64_t)Wq[h * E * P + e * P + p];
                }
                Q[h * S * P + s * P + p] = clip_int32((int32_t)(sum + Bq[h * P + p]), WO);
            }
        }
    }
    requantize_array(Q, Q_requant, H * S * P, eps_mult, right_shift, add);
    
    // ===== STEP 2: K = input @ Wk + Bk =====
    printf("DPI: Step 2 - Computing K = input @ Wk + Bk\n");
    for (int h = 0; h < H; h++) {
        for (int s = 0; s < S; s++) {
            for (int p = 0; p < P; p++) {
                int64_t sum = 0;
                for (int e = 0; e < E; e++) {
                    sum += (int64_t)input_data[s * E + e] * (int64_t)Wk[h * E * P + e * P + p];
                }
                K[h * S * P + s * P + p] = clip_int32((int32_t)(sum + Bk[h * P + p]), WO);
            }
        }
    }
    requantize_array(K, K_requant, H * S * P, eps_mult, right_shift, add);
    
    // ===== STEP 3: V = input @ Wv + Bv =====
    printf("DPI: Step 3 - Computing V = input @ Wv + Bv\n");
    for (int h = 0; h < H; h++) {
        for (int s = 0; s < S; s++) {
            for (int p = 0; p < P; p++) {
                int64_t sum = 0;
                for (int e = 0; e < E; e++) {
                    sum += (int64_t)input_data[s * E + e] * (int64_t)Wv[h * E * P + e * P + p];
                }
                V[h * S * P + s * P + p] = clip_int32((int32_t)(sum + Bv[h * P + p]), WO);
            }
        }
    }
    requantize_array(V, V_requant, H * S * P, eps_mult, right_shift, add);
    
    // ===== STEP 4: A = Q @ K^T =====
    printf("DPI: Step 4 - Computing A = Q @ K^T\n");
    for (int h = 0; h < H; h++) {
        for (int s = 0; s < S; s++) {
            for (int s2 = 0; s2 < S; s2++) {
                int64_t sum = 0;
                for (int p = 0; p < P; p++) {
                    sum += (int64_t)Q_requant[h * S * P + s * P + p] * (int64_t)K_requant[h * S * P + s2 * P + p];
                }
                A[h * S * S + s * S + s2] = clip_int32((int32_t)sum, WO);
            }
        }
    }
    requantize_array(A, A_requant, H * S * S, eps_mult, right_shift, add);
    
    // ===== STEP 4b: Softmax =====
    printf("DPI: Step 4b - Computing Softmax\n");
    for (int h = 0; h < H; h++) {
        softmax_int8(&A_requant[h * S * S], &A_softmax[h * S * S], S);
    }
    
    // ===== STEP 5: O = A_soft @ V =====
    printf("DPI: Step 5 - Computing O = A_soft @ V\n");
    for (int h = 0; h < H; h++) {
        for (int s = 0; s < S; s++) {
            for (int p = 0; p < P; p++) {
                int64_t sum = 0;
                for (int s2 = 0; s2 < S; s2++) {
                    sum += (int64_t)A_softmax[h * S * S + s * S + s2] * (int64_t)V_requant[h * S * P + s2 * P + p];
                }
                O_soft[h * S * P + s * P + p] = clip_int32((int32_t)sum, WO);
            }
        }
    }
    requantize_array(O_soft, O_soft_requant, H * S * P, eps_mult, right_shift, add);
    
    // ===== STEP 6: Out = O @ Wo + Bo =====
    printf("DPI: Step 6 - Computing Out = O @ Wo + Bo\n");
    for (int h = 0; h < H; h++) {
        for (int s = 0; s < S; s++) {
            for (int e = 0; e < E; e++) {
                int64_t sum = 0;
                for (int p = 0; p < P; p++) {
                    sum += (int64_t)O_soft_requant[h * S * P + s * P + p] * (int64_t)Wo[h * P * E + p * E + e];
                }
                Out[h * S * E + s * E + e] = clip_int32((int32_t)(sum + Bo[h * E + e]), WO);
            }
        }
    }
    requantize_array(Out, Out_requant, H * S * E, eps_mult, right_shift, add);
    
    // ===== STEP 7: Sum heads =====
    printf("DPI: Step 7 - Summing heads\n");
    for (int s = 0; s < S; s++) {
        for (int e = 0; e < E; e++) {
            int32_t sum = 0;
            for (int h = 0; h < H; h++) {
                sum += Out_requant[h * S * E + s * E + e];
            }
            Out_sum[s * E + e] = clip_int32(sum, WO);
        }
    }
    requantize_array(Out_sum, Out_sum_requant, S * E, eps_mult, right_shift, add);
    
    // ===== FEEDFORWARD: FF = input @ Wff + Bff =====
    printf("DPI: FFN Step 1 - Computing FF = input @ Wff + Bff\n");
    for (int s = 0; s < S; s++) {
        for (int f = 0; f < F; f++) {
            int64_t sum = 0;
            for (int e = 0; e < E; e++) {
                sum += (int64_t)input_data[s * E + e] * (int64_t)Wff[e * F + f];
            }
            FF[s * F + f] = clip_int32((int32_t)(sum + Bff[f]), WO);
        }
    }
    requantize_array(FF, FF_requant, S * F, eps_mult, right_shift, add);
    
    // ===== FEEDFORWARD: GELU activation =====
    printf("DPI: FFN Step 2 - GELU activation\n");
    for (int s = 0; s < S; s++) {
        for (int f = 0; f < F; f++) {
            FF_gelu[s * F + f] = gelu_approx(FF_requant[s * F + f]);
        }
    }
    
    // ===== FEEDFORWARD: FF2 = FF @ Wff2 + Bff2 =====
    printf("DPI: FFN Step 3 - Computing FF2 = FF @ Wff2 + Bff2\n");
    for (int s = 0; s < S; s++) {
        for (int e = 0; e < E; e++) {
            int64_t sum = 0;
            for (int f = 0; f < F; f++) {
                sum += (int64_t)FF_gelu[s * F + f] * (int64_t)Wff2[f * E + e];
            }
            FF2[s * E + e] = clip_int32((int32_t)(sum + Bff2[e]), WO);
        }
    }
    requantize_array(FF2, FF2_requant, S * E, eps_mult, right_shift, add);
    
    // ===== FINAL OUTPUT: Out + FF2 =====
    printf("DPI: Final - Computing output = Out + FF2\n");
    for (int s = 0; s < S; s++) {
        for (int e = 0; e < E; e++) {
            int32_t sum = (int32_t)Out_sum_requant[s * E + e] + (int32_t)FF2_requant[s * E + e];
            final_output[s * E + e] = clip_int32(sum, WO);
        }
    }
    
    // Copy to output
    int out_idx = 0;
    for (int s = 0; s < S; s++) {
        for (int e = 0; e < E; e++) {
            if (out_idx < output_size) {
                output_data[out_idx++] = final_output[s * E + e];
            }
        }
    }
    
    // Pad with zeros if needed
    while (out_idx < output_size) {
        output_data[out_idx++] = 0;
    }
    
    printf("DPI: Completed full Transformer computation\n");
    
cleanup:
    free(Q); free(K); free(V);
    free(Q_requant); free(K_requant); free(V_requant);
    free(A); free(A_requant); free(A_softmax);
    free(O_soft); free(O_soft_requant);
    free(Out); free(Out_requant);
    free(Out_sum); free(Out_sum_requant);
    free(FF); free(FF_requant); free(FF_gelu);
    free(FF2); free(FF2_requant); free(final_output);
}

// Main DPI function
void ita_reference_model(
    const int* input_data,  int input_size,
    const int* weight_data, int weight_size,
    const int* bias_data,   int bias_size,
    int S, int P, int E, int F, int H,
    int N, int M, int WI, int WO,
    int* output_data, int output_size)
{
    printf("DPI: ita_reference_model called - S=%d, P=%d, E=%d, F=%d, H=%d\n", S, P, E, F, H);
    printf("DPI: input_size=%d, weight_size=%d, bias_size=%d, output_size=%d\n", 
           input_size, weight_size, bias_size, output_size);
    
    // First, write inputs to files for Python to use
    FILE* fp_input = fopen("dpi_input.bin", "wb");
    FILE* fp_weight = fopen("dpi_weight.bin", "wb");
    FILE* fp_bias = fopen("dpi_bias.bin", "wb");
    
    if (fp_input && fp_weight && fp_bias) {
        fwrite(input_data, sizeof(int), input_size, fp_input);
        fwrite(weight_data, sizeof(int), weight_size, fp_weight);
        fwrite(bias_data, sizeof(int), bias_size, fp_bias);
        fclose(fp_input);
        fclose(fp_weight);
        fclose(fp_bias);
        printf("DPI: Wrote input files\n");
    }
    
    // Write config file
    FILE* fp_config = fopen("dpi_config.txt", "w");
    if (fp_config) {
        fprintf(fp_config, "S=%d\n", S);
        fprintf(fp_config, "P=%d\n", P);
        fprintf(fp_config, "E=%d\n", E);
        fprintf(fp_config, "F=%d\n", F);
        fprintf(fp_config, "H=%d\n", H);
        fprintf(fp_config, "N=%d\n", N);
        fprintf(fp_config, "M=%d\n", M);
        fprintf(fp_config, "WI=%d\n", WI);
        fprintf(fp_config, "WO=%d\n", WO);
        fprintf(fp_config, "input_size=%d\n", input_size);
        fprintf(fp_config, "weight_size=%d\n", weight_size);
        fprintf(fp_config, "bias_size=%d\n", bias_size);
        fprintf(fp_config, "output_size=%d\n", output_size);
        fclose(fp_config);
        printf("DPI: Wrote config file\n");
    }
    
    // Try to read golden output from file (generated by Python)
    FILE* fp_output = fopen("golden_output.bin", "rb");
    if (fp_output != NULL) {
        size_t read_size = fread(output_data, sizeof(int), output_size, fp_output);
        fclose(fp_output);
        if (read_size == (size_t)output_size) {
            printf("DPI: Loaded golden output from file (%zu words)\n", read_size);
            return;
        }
        printf("DPI: File read returned %zu words, expected %d\n", read_size, output_size);
    }
    
    // If no golden file, compute the model inline in C
    printf("DPI: No golden file found, computing model inline in C...\n");
    compute_transformer_c(
        input_data, input_size,
        weight_data, weight_size,
        bias_data, bias_size,
        S, P, E, F, H, WO,
        output_data, output_size);
    
    printf("DPI: Completed\n");
}

#ifdef __cplusplus
}
#endif