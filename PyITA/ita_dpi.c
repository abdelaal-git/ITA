#include <svdpi.h>
#include <Python.h>
#include <numpy/arrayobject.h>

// DPI function to call Python ITA reference model
extern "C" void ita_reference_model(const int* input_data, const int* weight_data, const int* bias_data, int input_size, int weight_size, int bias_size, int* output_data, int output_size) {
    // Initialize Python if not already done
    if (!Py_IsInitialized()) {
        Py_Initialize();
        import_array();
    }
    // Import the ITA module
    PyObject* pName = PyUnicode_DecodeFSDefault("PyITA.ITA");
    PyObject* pModule = PyImport_Import(pName);
    Py_DECREF(pName);
    if (pModule == NULL) {
        PyErr_Print();
        return;
    }
    // Get the reference function (assume function: run_reference_model)
    PyObject* pFunc = PyObject_GetAttrString(pModule, "run_reference_model");
    if (!pFunc || !PyCallable_Check(pFunc)) {
        PyErr_Print();
        Py_XDECREF(pFunc);
        Py_DECREF(pModule);
        return;
    }
    // Convert C arrays to numpy arrays
    npy_intp dims_input[1] = {input_size};
    npy_intp dims_weight[1] = {weight_size};
    npy_intp dims_bias[1] = {bias_size};
    PyObject* np_input = PyArray_SimpleNewFromData(1, dims_input, NPY_INT32, (void*)input_data);
    PyObject* np_weight = PyArray_SimpleNewFromData(1, dims_weight, NPY_INT32, (void*)weight_data);
    PyObject* np_bias = PyArray_SimpleNewFromData(1, dims_bias, NPY_INT32, (void*)bias_data);
    // Call the Python function
    PyObject* args = PyTuple_Pack(3, np_input, np_weight, np_bias);
    PyObject* result = PyObject_CallObject(pFunc, args);
    Py_DECREF(args);
    Py_DECREF(np_input);
    Py_DECREF(np_weight);
    Py_DECREF(np_bias);
    if (result == NULL) {
        PyErr_Print();
        Py_XDECREF(pFunc);
        Py_DECREF(pModule);
        return;
    }
    // Convert result numpy array to C array
    PyArrayObject* np_result = (PyArrayObject*)result;
    int* result_data = (int*)PyArray_DATA(np_result);
    for (int i = 0; i < output_size; ++i) {
        output_data[i] = result_data[i];
    }
    Py_DECREF(result);
    Py_XDECREF(pFunc);
    Py_DECREF(pModule);
}
