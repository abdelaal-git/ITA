#include <svdpi.h>
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

void ita_reference_model(
    const int* input_data,  int input_size,
    const int* weight_data, int weight_size,
    const int* bias_data,   int bias_size,
    int S, int P, int E, int F, int H,
    int N, int M, int WI, int WO,
    int* output_data, int output_size);

#ifdef __cplusplus
}
#endif

void ita_reference_model(
    const int* input_data,  int input_size,
    const int* weight_data, int weight_size,
    const int* bias_data,   int bias_size,
    int S, int P, int E, int F, int H,
    int N, int M, int WI, int WO,
    int* output_data, int output_size)
{
    printf("DPI: ita_reference_model called! S=%d E=%d H=%d in=%d out=%d\n", 
           S, E, H, input_size, output_size);

    // Simple test pattern: output = input * 2
    for (int i = 0; i < output_size; i++) {
        int val = (i < input_size) ? input_data[i] * 2 : 0;
        output_data[i] = val;
    }

    printf("DPI: Filled output with test pattern (input*2)\n");
}