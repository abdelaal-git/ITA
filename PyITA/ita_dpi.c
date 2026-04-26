#include <svdpi.h>
#include <Python.h>
#include <numpy/arrayobject.h>

// Use proper C linkage (no "C++" extern syntax)
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

void ita_reference_model(
    const svLogicVecVal* input_data,  int input_size,
    const svLogicVecVal* weight_data, int weight_size,
    const svLogicVecVal* bias_data,   int bias_size,
    int S, int P, int E, int F, int H,
    int N, int M, int WI, int WO,
    svLogicVecVal* output_data, int output_size)
{
    if (!Py_IsInitialized()) {
        Py_Initialize();
        import_array();
    }

    PyObject* pName = PyUnicode_DecodeFSDefault("run_reference_model");
    PyObject* pModule = PyImport_Import(pName);
    Py_DECREF(pName);

    if (pModule == NULL) {
        PyErr_Print();
        return;
    }

    PyObject* pFunc = PyObject_GetAttrString(pModule, "run_reference_model");
    if (!pFunc || !PyCallable_Check(pFunc)) {
        PyErr_Print();
        Py_DECREF(pModule);
        return;
    }

    // Simple conversion from svLogicVecVal to int (for now)
    int* in_data  = (int*)malloc(input_size * sizeof(int));
    int* w_data   = (int*)malloc(weight_size * sizeof(int));
    int* b_data   = (int*)malloc(bias_size * sizeof(int));
    int* out_data = (int*)malloc(output_size * sizeof(int));

    for (int i = 0; i < input_size; i++)  in_data[i] = input_data[i].aval;
    for (int i = 0; i < weight_size; i++) w_data[i]  = weight_data[i].aval;
    for (int i = 0; i < bias_size; i++)   b_data[i]  = bias_data[i].aval;

    // Build arguments
    npy_intp dims_in[1] = {input_size};
    npy_intp dims_w[1]  = {weight_size};
    npy_intp dims_b[1]  = {bias_size};

    PyObject* np_in = PyArray_SimpleNewFromData(1, dims_in, NPY_INT32, in_data);
    PyObject* np_w  = PyArray_SimpleNewFromData(1, dims_w,  NPY_INT32, w_data);
    PyObject* np_b  = PyArray_SimpleNewFromData(1, dims_b,  NPY_INT32, b_data);

    PyObject* args = PyTuple_Pack(12, np_in, np_w, np_b,
                                  PyLong_FromLong(S), PyLong_FromLong(P),
                                  PyLong_FromLong(E), PyLong_FromLong(F),
                                  PyLong_FromLong(H), PyLong_FromLong(N),
                                  PyLong_FromLong(M), PyLong_FromLong(WI),
                                  PyLong_FromLong(WO));

    PyObject* result = PyObject_CallObject(pFunc, args);

    // Copy result back
    if (result) {
        PyArrayObject* np_res = (PyArrayObject*)result;
        int* res_ptr = (int*)PyArray_DATA(np_res);
        int len = PyArray_DIM(np_res, 0);
        for (int i = 0; i < output_size && i < len; i++) {
            output_data[i].aval = res_ptr[i];
            output_data[i].bval = 0;
        }
        Py_DECREF(result);
    }

    // Cleanup
    free(in_data); free(w_data); free(b_data); free(out_data);
    Py_DECREF(args);
    Py_DECREF(np_in); Py_DECREF(np_w); Py_DECREF(np_b);
    Py_DECREF(pFunc);
    Py_DECREF(pModule);
}