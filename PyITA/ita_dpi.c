#include <svdpi.h>
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

void ita_reference_model(
    const svLogicVecVal* input_data,  int input_size,
    const svLogicVecVal* weight_data, int weight_size,
    const svLogicVecVal* bias_data,   int bias_size,
    int S, int P, int E, int F, int H,
    int N, int M, int WI, int WO,
    svLogicVecVal* output_data, int output_size);

#ifdef __cplusplus
}
#endif

// ===================================================================
// Minimal Implementation - No Python (for debugging)
// ===================================================================
void ita_reference_model(
    const svLogicVecVal* input_data,  int input_size,
    const svLogicVecVal* weight_data, int weight_size,
    const svLogicVecVal* bias_data,   int bias_size,
    int S, int P, int E, int F, int H,
    int N, int M, int WI, int WO,
    svLogicVecVal* output_data, int output_size)
{
    printf("DPI: ita_reference_model called! S=%d E=%d H=%d output_size=%d\n", 
           S, E, H, output_size);

    // Simple test pattern: output = input * 2 (to verify data flow)
    for (int i = 0; i < output_size; i++) {
        int val = (i < input_size) ? (input_data[i].aval * 2) : 0;
        output_data[i].aval = val;
        output_data[i].bval = 0;   // Clear X/Z
    }

    printf("DPI: Filled output with test pattern (input*2)\n");
}