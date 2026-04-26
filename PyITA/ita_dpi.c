#include <svdpi.h>
#include <stdio.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

// Simple DPI function that reads golden reference from a file
// This avoids Python embedding issues with VCS
void ita_reference_model(
    const int* input_data,  int input_size,
    const int* weight_data, int weight_size,
    const int* bias_data,   int bias_size,
    int S, int P, int E, int F, int H,
    int N, int M, int WI, int WO,
    int* output_data, int output_size);

void ita_reference_model(
    const int* input_data,  int input_size,
    const int* weight_data, int weight_size,
    const int* bias_data,   int bias_size,
    int S, int P, int E, int F, int H,
    int N, int M, int WI, int WO,
    int* output_data, int output_size)
{
    printf("DPI: ita_reference_model called - S=%d, P=%d, E=%d, F=%d, H=%d\n", S, P, E, F, H);
    printf("DPI: input_size=%d, output_size=%d\n", input_size, output_size);
    
    // Try to read golden output from file first
    FILE* fp = fopen("golden_output.bin", "rb");
    if (fp != NULL) {
        size_t read_size = fread(output_data, sizeof(int), output_size, fp);
        fclose(fp);
        if (read_size == (size_t)output_size) {
            printf("DPI: Loaded golden output from file (%zu words)\n", read_size);
            return;
        }
        printf("DPI: File read returned %zu words, expected %d\n", read_size, output_size);
    }
    
    // Fallback: Simple computation for verification
    // This is a placeholder - replace with actual golden model computation
    // For now, just copy input to output with a simple transform
    printf("DPI: Using fallback computation (input -> output)\n");
    
    int min_size = (input_size < output_size) ? input_size : output_size;
    for (int i = 0; i < output_size; i++) {
        if (i < min_size) {
            // Simple: just pass input through (for now)
            output_data[i] = input_data[i];
        } else {
            output_data[i] = 0;
        }
    }
    
    printf("DPI: Completed\n");
}

#ifdef __cplusplus
}
#endif