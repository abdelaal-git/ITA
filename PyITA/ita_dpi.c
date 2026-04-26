#include <svdpi.h>
#include <Python.h>
#include <numpy/arrayobject.h>

extern "C" void ita_reference_model(
    const int* input_data,  int input_size,
    const int* weight_data, int weight_size,
    const int* bias_data,   int bias_size,
    int S, int P, int E, int F, int H,
    int N, int M, int WI, int WO,
    int* output_data, int output_size)
{
    if (!Py_IsInitialized()) {
        Py_Initialize();
        import_array();
    }

    PyObject* pName = PyUnicode_DecodeFSDefault("PyITA.run_reference_model");
    PyObject* pModule = PyImport_Import(pName);
    Py_DECREF(pName);

    if (pModule == NULL) { PyErr_Print(); return; }

    PyObject* pFunc = PyObject_GetAttrString(pModule, "run_reference_model");
    if (!pFunc || !PyCallable_Check(pFunc)) {
        PyErr_Print();
        Py_DECREF(pModule);
        return;
    }

    npy_intp d_in[1] = {input_size};
    npy_intp d_w[1]  = {weight_size};
    npy_intp d_b[1]  = {bias_size};

    PyObject* np_in = PyArray_SimpleNewFromData(1, d_in, NPY_INT32, (void*)input_data);
    PyObject* np_w  = PyArray_SimpleNewFromData(1, d_w,  NPY_INT32, (void*)weight_data);
    PyObject* np_b  = PyArray_SimpleNewFromData(1, d_b,  NPY_INT32, (void*)bias_data);

    PyObject* args = PyTuple_Pack(12,
        np_in, np_w, np_b,
        PyLong_FromLong(S), PyLong_FromLong(P), PyLong_FromLong(E),
        PyLong_FromLong(F), PyLong_FromLong(H),
        PyLong_FromLong(N), PyLong_FromLong(M),
        PyLong_FromLong(WI), PyLong_FromLong(WO));

    PyObject* result = PyObject_CallObject(pFunc, args);

    Py_DECREF(args); Py_DECREF(np_in); Py_DECREF(np_w); Py_DECREF(np_b);

    if (result == NULL) {
        PyErr_Print();
        Py_DECREF(pFunc); Py_DECREF(pModule);
        return;
    }

    PyArrayObject* np_res = (PyArrayObject*)result;
    int* res_data = (int*)PyArray_DATA(np_res);
    int len = PyArray_DIM(np_res, 0);

    for (int i = 0; i < output_size && i < len; i++) {
        output_data[i] = res_data[i];
    }

    Py_DECREF(result);
    Py_DECREF(pFunc);
    Py_DECREF(pModule);
}